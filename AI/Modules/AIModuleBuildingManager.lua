AIModuleBuildingManager = AIModule:new()

function AIModuleBuildingManager:new(o, ai, harvestBeforeBuilding)
    local o = o or AIModule:new()
    setmetatable(o, self)
    self.__index = self

    o.ai = ai
    o.harvestBeforeBuilding = harvestBeforeBuilding or true
    o.peoplePerPlan = 2

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

            local braves = self.ai.populationManager:getIdlePeople(self.peoplePerPlan, M_PERSON_BRAVE)
            local treeThing = nil
            if (self.harvestBeforeBuilding) then
                local treeThings = self.ai.treeManager:getTreesWithWoodInArea(300, thing.Pos.D3, 10000)
                treeThing = treeThings[1] -- will be nil of no trees found
            end

            for i = 1, #braves, 1 do
                util.sendPersonToBuild(braves[i], thing, treeThing)
            end
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