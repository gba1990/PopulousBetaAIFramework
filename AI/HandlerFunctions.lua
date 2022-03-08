handlerFunctions = {}

-- Handlers for when plans are placed
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

handlerFunctions.OnPlacedPlanHandler = {}
handlerFunctions.OnPlacedPlanHandler.doNothing = OnPlacedPlanHandler_DoNothing
handlerFunctions.OnPlacedPlanHandler.harvestAndSendPeople = OnPlacedPlanHandler_HarvestAndSendPeople
handlerFunctions.OnPlacedPlanHandler.harvestAndSendPeopleWithPseudoIdleExtraPeople = OnPlacedPlanHandler_HarvestAndSendPeopleWithPseudoIdleExtraPeople