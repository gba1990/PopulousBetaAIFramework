LookAheadBuilder = AIModule:new()

function LookAheadBuilder:new(numMaxBuildingsToCheckAround, onlyCheckAroundHuts, checkAroundCoR)
    local o = AIModule:new()
    setmetatable(o, self)
    self.__index = self

    o.numMaxBuildingsToCheckAround = numMaxBuildingsToCheckAround or 20

    if (onlyCheckAroundHuts == nil) then onlyCheckAroundHuts = true end
    o.onlyCheckAroundHuts = onlyCheckAroundHuts

    if (checkAroundCoR == nil) then checkAroundCoR = false end
    o.checkAroundCoR = checkAroundCoR

    o.interval = 128
    
    return o
end

local function getRandomBuildings(owner, num)
    local result = {}
    ProcessGlobalSpecialList(owner, BUILDINGLIST, function(thing)
        if (thing ~= nil and thing.State == S_BUILDING_STAND) then
            table.insert(result, thing)
        end
        return true
    end)
    return result
end

local function getRandomHuts(owner, num)
    local result = {}
    ProcessGlobalSpecialList(owner, BUILDINGLIST, function(thing)
        if (thing ~= nil and thing.State == S_BUILDING_STAND and 
                (thing.Model == M_BUILDING_TEPEE or 
                thing.Model == M_BUILDING_TEPEE_2 or 
                thing.Model == M_BUILDING_TEPEE_3)
                ) then
            table.insert(result, thing)
        end
        return true
    end)
    return result
end

function LookAheadBuilder:process()
    local bldgs = {}
    local tribe = self.ai:getTribe()
    if (self.onlyCheckAroundHuts) then
        bldgs = getRandomHuts(tribe, self.numMaxBuildingsToCheckAround)
    else
        bldgs = getRandomBuildings(tribe, self.numMaxBuildingsToCheckAround)
    end

    -- Add CoR If needed
    -- TODO

    -- Search Positions around buildings
    local candidates = {}
    for k, build in pairs(bldgs) do
        -- We only take the points that are closest to the hut (thats what the radius does)
        util.addAll(candidates, util.getHutBuildableMapElementsAroundBuilding(build, 4))
    end

    -- Change from me to map_idx and delete duplicates (the change is done so the deletion can be done)
    candidates = functional.map2(function (me)
        local c2 = Coord2D.new()
        map_ptr_to_world_coord2d(me, c2)
        return world_coord2d_to_map_idx(c2)
    end, candidates)
    candidates = util.eliminateDuplicates(candidates)

    -- Rank the positions (lower rank is best)
    local ranking = {}
    for k, mapidx in pairs(candidates) do
        -- For each mapidx, get the number of buildable spots that will be unbuildable if we place a hut there
        local center = Coord2D.new()
        map_idx_to_world_coord2d(mapidx, center)
        local interruptedPositions = util.getHutBuildableMapElementsAtPosition(center, 3*512, tribe)

        table.insert(ranking, {coordinates = center, map_idx = mapidx, rank = #interruptedPositions})
    end

    table.sort(ranking, function(a,b) return a.rank < b.rank end)

    -- Build according to the rank on every possible space
    for k, entry in pairs(ranking) do
        util.placePlan(entry.coordinates, M_BUILDING_TEPEE, tribe, nil)
    end
end

local function intervalCaller(o)
    o:process()
    o.subscriberIndex = subscribe_ExecuteOnTurn(GetTurn() + o.interval, function()
        intervalCaller(o)
    end)
end

function LookAheadBuilder:enable()
    if (self.isEnabled) then
        return
    end
    self:setEnabled(true)

    intervalCaller(self)
end

function LookAheadBuilder:disable()
    if (not self.isEnabled) then
        return
    end
    self:setEnabled(false)

    unsubscribe_ExecuteOnTurn(self.subscriberIndex)
end
