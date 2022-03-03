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
    end
end


-- Class
function AIModuleBuildingManager:new(o, ai, harvestBeforeBuilding)
    local o = o or AIModule:new()
    setmetatable(o, self)
    self.__index = self

    o.ai = ai
    o.harvestBeforeBuilding = harvestBeforeBuilding or true
    
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
    o.behaviourPerPlan[M_BUILDING_TEPEE] = OnPlacedPlanHandler_HarvestAndSendPeople
    o.behaviourPerPlan[M_BUILDING_DRUM_TOWER] = OnPlacedPlanHandler_HarvestAndSendPeople
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
end

function AIModuleBuildingManager:doSendPeopleToPlacedPlans()
    self.sendPeopleToPlacedPlans = true
    self.sendPeopleToPlacedPlansSubscriptionIndex = subscribe_OnCreateThing(function (thing)
        if (thing.Type == T_SHAPE and thing.Owner == self.ai:getTribe()) then
            local behaviour = self.behaviourPerPlan[thing.u.Shape.BldgModel] or OnPlacedPlanHandler_DoNothing
            behaviour(self, thing)
        end
    end)
end

function AIModuleBuildingManager:enable()
    self:setEnabled(true)
    self:doSendPeopleToPlacedPlans()
end

function AIModuleBuildingManager:disable()
    self:setEnabled(true)
    self:dontSendPeopleToPlacedPlans()
end
