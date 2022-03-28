AIModuleTreeHarvester = AIModule:new()

--[[
    Requires the modules:
        AI_MODULE_POPULATION_MANAGER_ID
        AI_MODULE_TREE_MANAGER_ID
]]
function AIModuleTreeHarvester:new(o, ai)
    local o = o or AIModule:new()
    setmetatable(o, self)
    self.__index = self

    o.ai = ai
    o.periodicHarvestingInterval = 512
    o.maxNumberOfHarvesters = 5

    o:enable()
    return o
end

local function periodicTreeHarvesting(o)
    local populationManager = o.ai:getModule(AI_MODULE_POPULATION_MANAGER_ID)
    local treeManager = o.ai:getModule(AI_MODULE_TREE_MANAGER_ID)

    local persons = populationManager:getIdlePeople(o.maxNumberOfHarvesters, M_PERSON_BRAVE)
    treeManager:updateWoodValues()

    local sentIdx = 1
    for k, v in pairs(treeManager.closeByTrees) do
        if (v.wood > 275) then -- 275, not to leave a tree on 1 wood for too long in case it happens
            if (#persons == 0 or sentIdx > #persons) then
                break
            end
            
            populationManager:addPersonAsPseudoIdle(persons[sentIdx]) -- So this fella can be interrupted if needed
            commands.reset_person_cmds(persons[sentIdx])
            add_persons_command(persons[sentIdx], commands.cmd_gather_wood(v.tree, false), 0)
            
            sentIdx = sentIdx + 1
            treeManager:reduceWoodOfTree(v.tree, 100)
        end
    end
    
    o.periodicTreeHarvestingSubscriptionIndex = subscribe_ExecuteOnTurn(GetTurn() + o.periodicHarvestingInterval, function()
        periodicTreeHarvesting(o)
    end)
end

function AIModuleTreeHarvester:dontDoPeriodicTreeHarvesting()
    self.periodicTreeHarvesting = false
    unsubscribe_ExecuteOnTurn(self.periodicTreeHarvestingSubscriptionIndex)
end

function AIModuleTreeHarvester:doPeriodicTreeHarvesting()
    self.periodicTreeHarvesting = true
    self.periodicTreeHarvestingSubscriptionIndex = subscribe_ExecuteOnTurn(GetTurn() + 12, function (thing)
        periodicTreeHarvesting(self)
    end)
end

function AIModuleTreeHarvester:enable()
    if (self.isEnabled) then
        return
    end
    self:setEnabled(true)
    self:doPeriodicTreeHarvesting()
end

function AIModuleTreeHarvester:disable()
    if (not self.isEnabled) then
        return
    end
    self:setEnabled(false)
    self:dontDoPeriodicTreeHarvesting()
end