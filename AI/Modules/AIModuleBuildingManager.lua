AIModuleBuildingManager = AIModule:new()

local function dismantleTrick(o)
    o.dismantleSubscriberIndex = subscribe_ExecuteOnTurn(GetTurn() + o.dismantleInterval, function()
        dismantleTrick(o)
    end)

    logger.msgLog("Dismantling...")
    if (GET_NUM_PEOPLE(o.ai:getTribe()) >= o.dismantleStopOnPopulationOver) then
        return
    end

    local myTribe = o.ai:getTribe()
    local maxBuildingsThatCanBeDismantled = math.min(o.dismantleMaxNumberOfHuts, 
                                        math.floor((util.getMaxPopulationOfTribe(myTribe) - getPlayer(myTribe).NumPeople)/3))

    if (maxBuildingsThatCanBeDismantled <= 0) then
        return
    end

    -- Get small huts
    local huts = {}
    ProcessGlobalSpecialList(myTribe, BUILDINGLIST, function(thing)
        -- We only dismantle small huts, not being dismantled, with a low "new brave time", and low upgrade time
        if (thing.Model == M_BUILDING_TEPEE and not util.isMarkedAsDismantle(thing) 
                and thing.u.Bldg.SproggingCount < 700 and thing.u.Bldg.UpgradeCount < 700) then
            local dwellers = thing.u.Bldg.Dwellers
            -- We only dismantle huts which already have a brave
            for k, v in pairs(dwellers) do
                local person = v:get()
                if (person ~= nil and person.Model == M_PERSON_BRAVE) then
                    table.insert(huts, {hut = thing, brave = person})

                    maxBuildingsThatCanBeDismantled = maxBuildingsThatCanBeDismantled -1
                    if (maxBuildingsThatCanBeDismantled <= 0) then
                        return false
                    end
                end
            end
        end

        return true
    end)
    
    -- Dismantle all found huts
    for k, v in pairs(huts) do
        util.markBuildingToDismantle(v.hut, true)
        util.sendPersonToDismantle(v.brave, v.hut)
        -- Rebuild after 5 secs (enough time for them to have been taken down a layer)
        subscribe_ExecuteOnTurn(GetTurn() + 70, function()
            -- Check, in case it was fully dismantled by accident
            if (v.hut ~= nil and v.hut.u.Bldg ~= nil) then
                util.markBuildingToDismantle(v.hut, false) -- Unmark as dismantle
                util.sendPersonToBuild(v.brave, v.hut) --- TODO: do this for all builders of the shape
            end
        end)
        logger.msgLog("a hut")
        log("Start "..GetTurn())
    end

end

local function selectTree(treeIndex, treeThings, bravesSentToThatTree)
    local candidateTree = treeThings[treeIndex]
    if (candidateTree == nil) then
        return nil, treeIndex, 0 -- We reached the last tree
    end

    local woodOnTree = treeThings[treeIndex].u.Scenery.ResourceRemaining - 100 * bravesSentToThatTree
    if (woodOnTree >= 200) then
        return candidateTree, treeIndex, bravesSentToThatTree + 1
    end

    -- Less wood, then, call again but for the next tree
    return selectTree(treeIndex + 1, treeThings, 0)
end

-- Handlers for when plans are placed
local function OnPlacedPlanHandler_DoNothing(o ,plan)
end

local function OnPlacedPlanHandler_HarvestAndSendPeople(o, plan)
    local numBraves = o.peoplePerPlanArray[plan.u.Shape.BldgModel] or o.fallBackPeoplePerPlan

    local braves = o.ai.populationManager:getIdlePeople(numBraves, M_PERSON_BRAVE)
    local treeThings = nil
    if (o.harvestBeforeBuilding) then
        treeThings = o.ai.treeManager:getTreesWithWoodInArea(200, plan.Pos.D3, 10000)
    end

    local treeIndex = 1
    local treeThing = nil
    local bravesSentToThatTree = 0
    for i = 1, #braves, 1 do
        treeThing, treeIndex, bravesSentToThatTree = selectTree(treeIndex, treeThings, bravesSentToThatTree)
        util.sendPersonToBuild(braves[i], plan, treeThing)
        if (treeThing ~= nil) then
            o.ai.treeManager:reduceWoodOfTree(treeThing, 100) -- We will cut down 1 wood from that tree
        end
    end
end

local function OnPlacedPlanHandler_HarvestAndSendPeopleWithPseudoIdleExtraPeople(o, plan)
    local numBraves = o.peoplePerPlanArray[plan.u.Shape.BldgModel] or o.fallBackPeoplePerPlan
    numBraves = numBraves + o.fallBackPeoplePerPlan

    local braves = o.ai.populationManager:getIdlePeople(numBraves, M_PERSON_BRAVE)
    local treeThings = nil
    if (o.harvestBeforeBuilding) then
        treeThings = o.ai.treeManager:getTreesWithWoodInArea(200, plan.Pos.D3, 10000)
    end

    local treeIndex = 1
    local treeThing = nil
    local bravesSentToThatTree = 0
    for i = 1, #braves, 1 do
        treeThing, treeIndex, bravesSentToThatTree = selectTree(treeIndex, treeThings, bravesSentToThatTree)
        util.sendPersonToBuild(braves[i], plan, treeThing)
        if (i > numBraves - o.fallBackPeoplePerPlan) then
            o.ai.populationManager:addPersonAsPseudoIdle(braves[i])
        end
        if (treeThing ~= nil) then
            o.ai.treeManager:reduceWoodOfTree(treeThing, 100) -- We will cut down 1 wood from that tree
        end
    end
end

-- Build "abandoned" plans or broken buildings
local function sendPeopleToEmptyPlans(o)
    local plans = {}
    local previousPlans = o.placedPlans
    for i = 1, #previousPlans, 1 do
        local plan = previousPlans[i]

        -- TODO If the building is not accesible skip
        if (plan.plan == nil or plan.plan.u.Shape == nil) then -- If the plan no longer exists, skip (destroyed or finished building)
            goto continue
        end

        if (plan.gameTurnPlaced + 512 < GetTurn()) then
            local workers = plan.plan.u.Shape.NumWorkers
            if (workers == 0) then
                -- send workers
                local behaviour = o.behaviourPerPlan[plan.plan.u.Shape.BldgModel] or OnPlacedPlanHandler_DoNothing
                behaviour(o, plan.plan)
            else
                -- TODO
                -- Check number of workers required for the plan
                    -- Leave those as workers (remove from pseudoidle)
                    -- Mark the rest as pseudoidle
            end
        end

        table.insert(plans, plan)
        ::continue::
    end
    
    o.placedPlans = plans -- This way we eliminate completed plans and remove innaccesible/destroyed ones
    o.sendPeopleToPlacedPlansSubscriptionIndex2 = subscribe_ExecuteOnTurn(GetTurn() + 512, function()
        sendPeopleToEmptyPlans(o)
    end)
end

-- Class
function AIModuleBuildingManager:new(o, ai, harvestBeforeBuilding)
    local o = o or AIModule:new()
    setmetatable(o, self)
    self.__index = self

    o.ai = ai
    o.harvestBeforeBuilding = harvestBeforeBuilding or true
    o.placedPlans = {} -- {plan, gameTurnPlaced}
    
    o.peoplePerPlanArray = {}
    o.peoplePerPlanArray[M_BUILDING_TEPEE] = 2
    o.peoplePerPlanArray[M_BUILDING_DRUM_TOWER] = 1
    o.peoplePerPlanArray[M_BUILDING_TEMPLE] = 2
    o.peoplePerPlanArray[M_BUILDING_SPY_TRAIN] = 2
    o.peoplePerPlanArray[M_BUILDING_WARRIOR_TRAIN] = 2
    o.peoplePerPlanArray[M_BUILDING_SUPER_TRAIN] = 2
    o.peoplePerPlanArray[M_BUILDING_BOAT_HUT_1] = 2
    o.peoplePerPlanArray[M_BUILDING_AIRSHIP_HUT_1] = 2
    o.fallBackPeoplePerPlan = 2

    o.behaviourPerPlan = {}
    o.behaviourPerPlan[M_BUILDING_TEPEE] = OnPlacedPlanHandler_HarvestAndSendPeopleWithPseudoIdleExtraPeople
    o.behaviourPerPlan[M_BUILDING_DRUM_TOWER] = OnPlacedPlanHandler_HarvestAndSendPeopleWithPseudoIdleExtraPeople
    o.behaviourPerPlan[M_BUILDING_TEMPLE] = OnPlacedPlanHandler_HarvestAndSendPeople
    o.behaviourPerPlan[M_BUILDING_SPY_TRAIN] = OnPlacedPlanHandler_HarvestAndSendPeople
    o.behaviourPerPlan[M_BUILDING_WARRIOR_TRAIN] = OnPlacedPlanHandler_HarvestAndSendPeople
    o.behaviourPerPlan[M_BUILDING_SUPER_TRAIN ] = OnPlacedPlanHandler_HarvestAndSendPeople
    o.behaviourPerPlan[M_BUILDING_BOAT_HUT_1 ] = OnPlacedPlanHandler_HarvestAndSendPeople
    o.behaviourPerPlan[M_BUILDING_AIRSHIP_HUT_1 ] = OnPlacedPlanHandler_HarvestAndSendPeople
    o.fallBackBehaviourPerPlan = OnPlacedPlanHandler_DoNothing
    
    
    o.dismantleInterval = 180
    o.dismantleMaxNumberOfHuts = 3
    o.dismantleStopOnPopulationOver = 700
    
    o:enable()
    return o
end


function AIModuleBuildingManager:dontSendPeopleToPlacedPlans()
    self.sendPeopleToPlacedPlans = false
    unsubscribe_OnCreateThing(self.sendPeopleToPlacedPlansSubscriptionIndex)
    unsubscribe_OnCreateThing(self.sendPeopleToPlacedPlansSubscriptionIndex2)
end

function AIModuleBuildingManager:doSendPeopleToPlacedPlans()
    self.sendPeopleToPlacedPlans = true
    self.sendPeopleToPlacedPlansSubscriptionIndex = subscribe_OnCreateThing(function (thing)
        if (thing.Type == T_SHAPE and thing.Owner == self.ai:getTribe()) then
            table.insert(self.placedPlans, {plan = thing, gameTurnPlaced = GetTurn()})
            if (thing.u.Shape.AttackDamageDelay == 0) then
                -- New building, damaged buildings will be handled at sendPeopleToEmptyPlans
                local behaviour = self.behaviourPerPlan[thing.u.Shape.BldgModel] or OnPlacedPlanHandler_DoNothing
                behaviour(self, thing)
            end
        end
    end)
    self.sendPeopleToPlacedPlansSubscriptionIndex2 = subscribe_ExecuteOnTurn(GetTurn() + 512, function()
        sendPeopleToEmptyPlans(self)
    end)
end

function AIModuleBuildingManager:dontDoDismantleTrick()
    self.doDismantleTrick = false
    unsubscribe_OnCreateThing(self.dismantleSubscriberIndex)
end

function AIModuleBuildingManager:doDismantleTrick()
    self.doDismantleTrick = true
    self.dismantleSubscriberIndex = subscribe_ExecuteOnTurn(GetTurn() + self.dismantleInterval, function()
        dismantleTrick(self)
    end)
end

function AIModuleBuildingManager:enable()
    if (self.isEnabled) then
        return
    end
    self:setEnabled(true)
    self:doSendPeopleToPlacedPlans()
    self:doDismantleTrick()
end

function AIModuleBuildingManager:disable()
    if (not self.isEnabled) then
        return
    end
    self:setEnabled(true)
    self:dontSendPeopleToPlacedPlans()
    self:dontDoDismantleTrick()
end
