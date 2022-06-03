BuildPlace = {NO_SPECIFIC_PLACE_TURN = -1}

-- Helper
local function _planHasBeenFullyBuiltChecker(buildplace, thing)
    if (buildplace == nil or thing == nil) then
        return
    end

    -- We no longer have a shape => it has been built or or it has been destroyed
    if (thing.u.Shape == nil) then
        local build = nil

        SearchMapCells(SQUARE, 0, 0, 0, world_coord2d_to_map_idx(util.to_coord2D(buildplace.location)), function(me)
            me.MapWhoList:processList(function (t)
                if (t.Type == T_BUILDING and t.owner == buildplace.owner) then
                    build = t
                end
                return true
            end)
            return true
        end)
        
        -- Call methods
        for k, v in pairs(buildplace.childrenDependantOnBuilt) do
            v(buildplace, build)
        end
    else
        subscribe_ExecuteOnTurn(GetTurn() + buildplace.intervalForBuiltCheck, function()
            _planHasBeenFullyBuiltChecker(buildplace, thing)
        end)
    end

end

function BuildPlace:new(o, tribe, dwellingType, location, orientation, gameTurnWhenToPlace, dependencies)
    local o = o or {}
    setmetatable(o, self)
    self.__index = self
    
    self.NO_SPECIFIC_PLACE_TURN = -1
    o.tribe = tribe
    o.dwellingType = dwellingType
    o.location = location
    o.locationAsMapIdx = world_coord2d_to_map_idx(util.to_coord2D(o.location))
    o.orientation = orientation or nil
    o.gameTurnWhenToPlace = gameTurnWhenToPlace or self.NO_SPECIFIC_PLACE_TURN
    o.dependencies = dependencies or {}
    o.childrenDependantOnPlace = {}
    o.childrenDependantOnBuilt = {}
    
    o.hasBeenPlaced = false
    o.intervalForBuiltCheck = 64 -- Game turn interval to check for building built. Set low if you care about accuracy, if you dont, 128 may even be good
    
    -- Subscribe dependencies to parent's onbuild
    for i = 1, #o.dependencies, 1 do
        o.dependencies[i]:onBuiltSubscribe(function(buildplace, plan)
            if (plan == nil) then
                -- Plan was destroyed, or at least, we no longer have a building
                return
            end

            for i = 1, #o.dependencies, 1 do
                if (buildplace == o.dependencies[i]) then
                    table.remove(o.dependencies, i)
                end
            end
        end)
    end

    -- subscribe so onbuild is called after placing
    o:onPlaceSubscribe(function(buildplace, plan)
        _planHasBeenFullyBuiltChecker(buildplace, plan)
    end)

    return o
end

function BuildPlace:onPlaceSubscribe(func)
    table.insert(self.childrenDependantOnPlace, func)
end

function BuildPlace:onBuiltSubscribe(func)
    table.insert(self.childrenDependantOnBuilt, func)
end

function BuildPlace:setHasBeenPlaced(val)
    self.hasBeenPlaced = val
end

function BuildPlace:addDependency(dependency)
    table.insert(self.dependencies, dependency)
end

function BuildPlace:canBeBuilt()
    if (GetTurn() < self.gameTurnWhenToPlace or #self.dependencies > 0 or self.hasBeenPlaced) then return false end

    local placeable = false
    if (self.orientation == nil) then
        for i = 0, 4, 1 do
            placeable = util.canPlayerPlacePlanAtPos(self.locationAsMapIdx, self.dwellingType, i, self.tribe) > 0
            if (placeable) then
                break
            end
        end
    else
        placeable = util.canPlayerPlacePlanAtPos(self.locationAsMapIdx, self.dwellingType, self.orientation, self.tribe) > 0
    end

    return placeable
end

function BuildPlace:place()
    if (not self:canBeBuilt()) then
        return false
    end

    util.placePlan(self.location, self.dwellingType, self.tribe, self.orientation)
    self.hasBeenPlaced = true

    subscribe_ExecuteOnTurn(GetTurn(), function()
        -- Process subsribed to plan placed
        SearchMapCells(SQUARE, 0, 0, 0, world_coord2d_to_map_idx(util.to_coord2D(self.location)), function(me)
            me.MapWhoList:processList(function (t)
                if (t.Type == T_SHAPE and t.owner == self.owner) then
                    -- Call subscribed methods
                    for k, v in pairs(self.childrenDependantOnPlace) do
                        v(self, t)
                    end
                end
                return true
            end)
            return true
        end)
    end)

    return true
end