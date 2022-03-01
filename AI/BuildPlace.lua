BuildPlace = {NO_SPECIFIC_PLACE_TURN = nil}

-- Helper
local function _planHasBeenFullyBuiltChecker(buildplace, thing)
    if (buildplace == nil or thing == nil) then
        --logger.msgLog("End: %s", thing)
        --logger.msgLog("End: %s", buildplace)
        return
    end

    -- We no longer have a shape => it has been built
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
        
        --logger.msgLog("Found: %s", build)
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
    
    self.NO_SPECIFIC_PLACE_TURN = nil
    o.tribe = tribe
    o.dwellingType = dwellingType
    o.location = location
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
    local result = #self.dependencies == 0
    result = result and is_map_point_land(util.to_coord2D(self.location)) > 0
    result = result and not self.hasBeenPlaced
    return result
end

function BuildPlace:place()
    if (self.hasBeenPlaced) then
        return
    end

    --logger.msgLog("Placed at (%s, %s)", self.location.Xpos, self.location.Zpos)

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
end