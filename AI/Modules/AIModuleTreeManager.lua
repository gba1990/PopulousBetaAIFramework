AIModuleTreeManager = AIModule:new()

function AIModuleTreeManager:new(o, ai, treeSearchLocations)
    local o = o or AIModule:new()
    setmetatable(o, self)
    self.__index = self

    o.ai = ai
    o.periodicTreeSearchInterval = 512
    o.periodicHarvestingInterval = 512
    o.maxNumberOfHarvesters = 5
    o.treeSearchLocations = treeSearchLocations or {}
    o.closeByTrees = {}

    o:enable()
    return o
end

local function updateWoodInTree(treeEntry)
    local result = treeEntry

    if (treeEntry.tree == nil) then
        treeEntry.wood = 0
    else
        treeEntry.wood = math.min(treeEntry.wood, treeEntry.tree.u.Scenery.ResourceRemaining)
    end

    return result
end

function AIModuleTreeManager:reduceWoodOfTree(treeThing, amount)
    local allTrees = self.closeByTrees

    for k, v in pairs(allTrees) do
        if (v.tree.ThingNum == treeThing.ThingNum) then
            v.wood = math.max(v.wood - amount, 0)
            return
        end
    end
end

function AIModuleTreeManager:getTreesWithWoodInArea(wood, centre, radius)
    centre = util.to_coord3D(centre)
    local allTrees = self:getTreesWithWood(#self.closeByTrees, wood)
    local result = {}

    for k, v in pairs(allTrees) do
        local isInArea = get_world_dist_xyz(v.Pos.D3, centre) < radius
        if (isInArea) then
            table.insert(result, v)
        end
    end

    table.sort(result, function(a,b) return get_world_dist_xyz(a.Pos.D3, centre) < get_world_dist_xyz(b.Pos.D3, centre) end)
    return result
end

function AIModuleTreeManager:getTreesWithWood(numberOfTrees, wood)
    local result = {}
    for k, v in pairs(self.closeByTrees) do
        v.wood = updateWoodInTree(v).wood
        if (v.wood >= wood) then
            table.insert(result, v.tree)
        end

        if (#result >= numberOfTrees) then
            break
        end
    end
    return result
end

local function searchForTreesInArea(centre, radius)
    local result = {}
    centre = util.to_coord3D(centre)

    ProcessGlobalSpecialList(TRIBE_HOSTBOT, WOODLIST, function(__t)
        if (get_world_dist_xyz(__t.Pos.D3, centre) < radius) then
            table.insert(result, {tree = __t, wood = __t.u.Scenery.ResourceRemaining})
        end
        
        return true
    end)

    return result
end

local function periodicTreeSearch(o)
    local result = {}

    for k, v in pairs(o.treeSearchLocations) do
        local t = searchForTreesInArea(v.centre, v.radius)
        for k, v in pairs(t) do
            table.insert(result, v)
        end
    end

    o.closeByTrees = result

    o.periodicTreeSearchSubscriptionIndex = subscribe_ExecuteOnTurn(GetTurn() + o.periodicTreeSearchInterval, function()
        periodicTreeSearch(o)
    end)
end

function AIModuleTreeManager:dontDoPeriodicTreeSearch()
    self.periodicTreeSearch = false
    unsubscribe_OnCreateThing(self.periodicTreeSearchSubscriptionIndex)
end

function AIModuleTreeManager:doPeriodicTreeSearch()
    self.periodicTreeSearch = true
    self.periodicTreeSearchSubscriptionIndex = subscribe_ExecuteOnTurn(GetTurn(), function (thing)
        periodicTreeSearch(self)
    end)
end

local function periodicTreeHarvesting(o)
    local persons = o.ai.populationManager:getIdlePeople(o.maxNumberOfHarvesters, M_PERSON_BRAVE)
    local sentIdx = 1
    
    for k, v in pairs(o.closeByTrees) do
        v.wood = updateWoodInTree(v).wood
        if (v.wood > 275) then -- 275, not to leave a tree on 1 wood for too long in case it happens
            if (#persons == 0 or sentIdx > #persons) then
                break
            end
            
            commands.reset_person_cmds(persons[sentIdx])
            add_persons_command(persons[sentIdx], commands.cmd_gather_wood(v.tree, false), 0)
            
            sentIdx = sentIdx + 1
            v.wood = v.wood - 100
        end
    end
    
    o.periodicTreeHarvestingSubscriptionIndex = subscribe_ExecuteOnTurn(GetTurn() + o.periodicHarvestingInterval, function()
        periodicTreeHarvesting(o)
    end)
end

function AIModuleTreeManager:dontDoPeriodicTreeHarvesting()
    self.periodicTreeHarvesting = false
    unsubscribe_OnCreateThing(self.periodicTreeHarvestingSubscriptionIndex)
end

function AIModuleTreeManager:doPeriodicTreeHarvesting()
    self.periodicTreeHarvesting = true
    self.periodicTreeHarvestingSubscriptionIndex = subscribe_ExecuteOnTurn(GetTurn() + 12, function (thing)
        periodicTreeHarvesting(self)
    end)
end


function AIModuleTreeManager:enable()
    if (self.isEnabled) then
        return
    end
    self:setEnabled(true)
    self:doPeriodicTreeSearch()
    self:doPeriodicTreeHarvesting()
end

function AIModuleTreeManager:disable()
    if (not self.isEnabled) then
        return
    end
    self:setEnabled(false)
    self:dontDoPeriodicTreeSearch()
    self:dontDoPeriodicTreeHarvesting()
end