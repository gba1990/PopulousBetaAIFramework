BuildingReplacerBuilder = AIModule:new()

-- TODO: program numMaxBuildingsToCheckAround. Make sure after dismantle, the train hut can be placed (make sure there are builds near by)

function BuildingReplacerBuilder:new(numMaxBuildingsToCheckAround, bldg_model)
    local o = AIModule:new()
    setmetatable(o, self)
    self.__index = self

    o.numMaxBuildingsToCheckAround = numMaxBuildingsToCheckAround or 20
    o.bldg_model = bldg_model

    o.maxAcceptableCost = 10 -- A cost of this value of higher will be discarded
    o.isObstacleValid = function(thing) -- Is obstacle something we can replace and dismantle
        return thing ~= nil and thing.Type == T_BUILDING and thing.Owner == o.ai:getTribe() and not util.isMarkedAsDismantle(thing)
    end

    -- How much do each bldg add to the total cost
    o.costs = {}
    o.costs[M_BUILDING_TEPEE] = 1
    o.costs[M_BUILDING_TEPEE_2] = 1.75
    o.costs[M_BUILDING_TEPEE_3] = 2.5
    o.costs[M_BUILDING_DRUM_TOWER] = 4
    o.costs[M_BUILDING_TEMPLE] = 10
    o.costs[M_BUILDING_SPY_TRAIN] = 10
    o.costs[M_BUILDING_WARRIOR_TRAIN] = 10
    o.costs[M_BUILDING_SUPER_TRAIN] = 10
    o.costs[M_BUILDING_BOAT_HUT_1] = 10
    o.costs[M_BUILDING_AIRSHIP_HUT_1] = 10

    return o
end

-- TODO: Move to utils
local function getObstaclesOfMapIndex(idx)
    local result = {}
    local c = Coord2D.new()
    map_idx_to_world_coord2d(idx, c)
    local me = world_coord2d_to_map_ptr(c)
  
    if (not me.ShapeOrBldgIdx:isNull()) then
      table.insert(result, me.ShapeOrBldgIdx:getThingNum())
    end
  
    return result
  end

  local function getObstaclesForBuildingPlacing_Temple(_mapidx, _orient)
    --[[
      Schema:
      
      0 1 2 3 4
        . . .
        . . .
        . . .
        . . .
          .
      0 1 2 3 4
    ]]

    local obstacles = {}

    local mp0 = MapPosXZ.new()
    local mp1 = MapPosXZ.new()
    local mp2 = MapPosXZ.new()
    local mp3 = MapPosXZ.new()
    local mp4 = MapPosXZ.new()
    mp0.Pos = _mapidx
    mp1.Pos = _mapidx
    mp2.Pos = _mapidx
    mp3.Pos = _mapidx
    mp4.Pos = _mapidx

    local all_mp = {}
    all_mp[0] = mp0
    all_mp[1] = mp1
    all_mp[2] = mp2
    all_mp[3] = mp3
    all_mp[4] = mp4

    ------------
    -- To start position
    ------------

    -- Move all to the back
    for i = 0, 1 do
        increment_map_idx_by_orient(mp0, (0 + _orient) % 4)
        increment_map_idx_by_orient(mp1, (0 + _orient) % 4)
        increment_map_idx_by_orient(mp2, (0 + _orient) % 4)
        increment_map_idx_by_orient(mp3, (0 + _orient) % 4)
        increment_map_idx_by_orient(mp4, (0 + _orient) % 4)
    end
    
    -- Move to left or right
    increment_map_idx_by_orient(mp4, (2 + _orient - 1) % 4)
    increment_map_idx_by_orient(mp4, (2 + _orient - 1) % 4)

    increment_map_idx_by_orient(mp3, (2 + _orient - 1) % 4)

    increment_map_idx_by_orient(mp1, (2 + _orient + 1) % 4)
    
    increment_map_idx_by_orient(mp0, (2 + _orient + 1) % 4)
    increment_map_idx_by_orient(mp0, (2 + _orient + 1) % 4)

    for k, v in pairs(all_mp) do
        obstacles = util.addAll(obstacles, getObstaclesOfMapIndex(v.Pos))
    end

    ------------
    -- Traverse the plan shape
    ------------

    for i = 0, 4 do
        increment_map_idx_by_orient(mp0, (2 + _orient - 4) % 4)
        increment_map_idx_by_orient(mp1, (2 + _orient - 4) % 4)
        increment_map_idx_by_orient(mp2, (2 + _orient - 4) % 4)
        increment_map_idx_by_orient(mp3, (2 + _orient - 4) % 4)
        increment_map_idx_by_orient(mp4, (2 + _orient - 4) % 4)

        for k, v in pairs(all_mp) do
            obstacles = util.addAll(obstacles, getObstaclesOfMapIndex(v.Pos))
        end
    end

    return util.eliminateDuplicates(obstacles)
end

  local function getObstaclesForBuildingPlacing_FWTrain(_mapidx, _orient)
    --[[
      Schema:
      
      0 1 2 3 4 5
        . . . .
        . . . .
        . . . .
        . . . .
          .
      0 1 2 3 4 5
    ]]

    local obstacles = {}

    local mp0 = MapPosXZ.new()
    local mp1 = MapPosXZ.new()
    local mp2 = MapPosXZ.new()
    local mp3 = MapPosXZ.new()
    local mp4 = MapPosXZ.new()
    local mp5 = MapPosXZ.new()
    mp0.Pos = _mapidx
    mp1.Pos = _mapidx
    mp2.Pos = _mapidx
    mp3.Pos = _mapidx
    mp4.Pos = _mapidx
    mp5.Pos = _mapidx

    local all_mp = {}
    all_mp[0] = mp0
    all_mp[1] = mp1
    all_mp[2] = mp2
    all_mp[3] = mp3
    all_mp[4] = mp4
    all_mp[5] = mp5

    ------------
    -- To start position
    ------------

    -- Move all to the back
    for i = 0, 1 do
        increment_map_idx_by_orient(mp0, (0 + _orient) % 4)
        increment_map_idx_by_orient(mp1, (0 + _orient) % 4)
        increment_map_idx_by_orient(mp2, (0 + _orient) % 4)
        increment_map_idx_by_orient(mp3, (0 + _orient) % 4)
        increment_map_idx_by_orient(mp4, (0 + _orient) % 4)
        increment_map_idx_by_orient(mp5, (0 + _orient) % 4)
    end
    
    -- Move to left or right
    increment_map_idx_by_orient(mp5, (2 + _orient - 1) % 4)
    increment_map_idx_by_orient(mp5, (2 + _orient - 1) % 4)
    increment_map_idx_by_orient(mp5, (2 + _orient - 1) % 4)

    increment_map_idx_by_orient(mp4, (2 + _orient - 1) % 4)
    increment_map_idx_by_orient(mp4, (2 + _orient - 1) % 4)

    increment_map_idx_by_orient(mp3, (2 + _orient - 1) % 4)

    increment_map_idx_by_orient(mp1, (2 + _orient + 1) % 4)
    
    increment_map_idx_by_orient(mp0, (2 + _orient + 1) % 4)
    increment_map_idx_by_orient(mp0, (2 + _orient + 1) % 4)

    for k, v in pairs(all_mp) do
        obstacles = util.addAll(obstacles, getObstaclesOfMapIndex(v.Pos))
    end

    ------------
    -- Traverse the plan shape
    ------------

    for i = 0, 4 do
        increment_map_idx_by_orient(mp0, (2 + _orient - 4) % 4)
        increment_map_idx_by_orient(mp1, (2 + _orient - 4) % 4)
        increment_map_idx_by_orient(mp2, (2 + _orient - 4) % 4)
        increment_map_idx_by_orient(mp3, (2 + _orient - 4) % 4)
        increment_map_idx_by_orient(mp4, (2 + _orient - 4) % 4)
        increment_map_idx_by_orient(mp5, (2 + _orient - 4) % 4)

        for k, v in pairs(all_mp) do
            obstacles = util.addAll(obstacles, getObstaclesOfMapIndex(v.Pos))
        end
    end

    return util.eliminateDuplicates(obstacles)
end

local function getObstaclesForBuildingPlacing_WarrTrain(_mapidx, _orient)
    --[[
      Schema:
    
      0 1 2 3 4
        . . .
        . . .
        . . .
          .
      0 1 2 3 4
    ]]

    local obstacles = {}

    local mp0 = MapPosXZ.new()
    local mp1 = MapPosXZ.new()
    local mp2 = MapPosXZ.new()
    local mp3 = MapPosXZ.new()
    local mp4 = MapPosXZ.new()
    mp0.Pos = _mapidx
    mp1.Pos = _mapidx
    mp2.Pos = _mapidx
    mp3.Pos = _mapidx
    mp4.Pos = _mapidx

    local all_mp = {}
    all_mp[0] = mp0
    all_mp[1] = mp1
    all_mp[2] = mp2
    all_mp[3] = mp3
    all_mp[4] = mp4

    ------------
    -- To start position
    ------------

    -- Move all to the back
    for i = 0, 1 do
        increment_map_idx_by_orient(mp0, (0 + _orient) % 4)
        increment_map_idx_by_orient(mp1, (0 + _orient) % 4)
        increment_map_idx_by_orient(mp2, (0 + _orient) % 4)
        increment_map_idx_by_orient(mp3, (0 + _orient) % 4)
        increment_map_idx_by_orient(mp4, (0 + _orient) % 4)
    end
    -- Move to left or right
    increment_map_idx_by_orient(mp0, (2 + _orient - 1) % 4)
    increment_map_idx_by_orient(mp0, (2 + _orient - 1) % 4)

    increment_map_idx_by_orient(mp1, (2 + _orient - 1) % 4)

    increment_map_idx_by_orient(mp3, (2 + _orient + 1) % 4)

    increment_map_idx_by_orient(mp4, (2 + _orient + 1) % 4)
    increment_map_idx_by_orient(mp4, (2 + _orient + 1) % 4)

    for k, v in pairs(all_mp) do
        obstacles = util.addAll(obstacles, getObstaclesOfMapIndex(v.Pos))
    end

    ------------
    -- Traverse the plan shape
    ------------

    for i = 0, 3 do
        increment_map_idx_by_orient(mp0, (2 + _orient - 4) % 4)
        increment_map_idx_by_orient(mp1, (2 + _orient - 4) % 4)
        increment_map_idx_by_orient(mp2, (2 + _orient - 4) % 4)
        increment_map_idx_by_orient(mp3, (2 + _orient - 4) % 4)
        increment_map_idx_by_orient(mp4, (2 + _orient - 4) % 4)

        for k, v in pairs(all_mp) do
            obstacles = util.addAll(obstacles, getObstaclesOfMapIndex(v.Pos))
        end
    end

    return util.eliminateDuplicates(obstacles)
end

local function getObstaclesForBuildingPlacing(mapIdxOrCoord, bldg_model, orientation)
    if (type(mapIdxOrCoord) ~= "number") then
        mapIdxOrCoord = world_coord2d_to_map_idx(util.to_coord2D(mapIdxOrCoord))
    end

    local t = {}
    t[M_BUILDING_TEPEE] = getObstaclesForBuildingPlacing_WarrTrain
    t[M_BUILDING_SPY_TRAIN] = getObstaclesForBuildingPlacing_WarrTrain
    t[M_BUILDING_SUPER_TRAIN] = getObstaclesForBuildingPlacing_FWTrain
    t[M_BUILDING_TEMPLE] = getObstaclesForBuildingPlacing_Temple
    t[M_BUILDING_WARRIOR_TRAIN] = getObstaclesForBuildingPlacing_WarrTrain
    --t[M_BUILDING_BOAT_HUT_1] = nil -- TODO
    --t[M_BUILDING_AIRSHIP_HUT_1] = nil -- TODO

    return t[bldg_model](mapIdxOrCoord, orientation)
end
------------

local function calculateCost(o, obstacles)
    local cost = 0

    for k, v in pairs(obstacles) do
        local thing = GetThing(v)
        if (o.isObstacleValid(thing)) then
            cost = cost + o.costs[thing.Model]
        else
            -- Not valid place
            cost = o.maxAcceptableCost
            break
        end
    end

    return cost
end

function BuildingReplacerBuilder:run()
    --[[

    - Get locations
    - Calculate where new bldg can be placed at on those locations
    - Get bldgs on plans that interfere
    - Calculate cost of dismantling those bldgs
    - Select lowest cost
    - Dismantle bldgs
    - Place new bldg

    ]]

    local myTribe = self.ai:getTribe()

    -- Get locations
    local locations = {}
    ProcessGlobalSpecialList(myTribe, BUILDINGLIST, function(thing)
        table.insert(locations, thing.Pos.D2)
        return true
    end)

    -- Determine those where building can be placed
    local candidates = {} -- {coord, orient}
    for k, v in pairs(locations) do
        -- For each orient, try to place the building
        for i = 0, 3, 1 do
            if (util.isLandOkForBuilding(v, self.bldg_model, i)) then
                local obstacles = getObstaclesForBuildingPlacing(v, self.bldg_model, i)
                local cost = calculateCost(self, obstacles)

                if (cost < self.maxAcceptableCost) then
                    table.insert(candidates, {
                        coord = v,
                        orient = i,
                        obstacles = obstacles,
                        cost = cost
                    })
                end
            end
        end
    end

    -- Order by cost
    table.sort(candidates, function(a,b) return a.cost < b.cost end)

    -- Select lowest cost to place. Send request to bldg placer and dismantle bldgs
    if (#candidates > 0) then
        local braves = self.ai:getModule(AI_MODULE_POPULATION_MANAGER_ID):getIdlePeople(#candidates[1].obstacles, M_PERSON_BRAVE)
        local idx = 1

        for k, v in pairs(candidates[1].obstacles) do
            local thing = GetThing(v)
            util.markBuildingToDismantle(thing)
            if (#braves >= idx) then
                util.sendPersonToDismantle(braves[idx], thing)
                idx = idx + 1
            end
        end

        local place = BuildPlace:new(nil, myTribe, self.bldg_model, candidates[1].coord, candidates[1].orient)
        self.ai:getModule(AI_MODULE_BUILDING_PLACER_ID):addBuildPlace(place)
    end
end

function BuildingReplacerBuilder:enable()
    if (self.isEnabled) then
        return
    end
    self:setEnabled(true)

    self:run()
end

function BuildingReplacerBuilder:disable()
    if (not self.isEnabled) then
        return
    end
    self:setEnabled(false)
end
