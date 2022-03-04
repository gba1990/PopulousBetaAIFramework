AIModuleBuildingManager = AIModule:new()

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

function AIModuleBuildingManager:enable()
    if (self.isEnabled) then
        return
    end
    self:setEnabled(true)
    self:doSendPeopleToPlacedPlans()
end

function AIModuleBuildingManager:disable()
    if (not self.isEnabled) then
        return
    end
    self:setEnabled(true)
    self:dontSendPeopleToPlacedPlans()
end
