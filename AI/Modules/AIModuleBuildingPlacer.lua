AIModuleBuildingPlacer = AIModule:new()

local function buildUpdateInterval(o)
    o.buildDelay = 0
    for i, v in pairs(o.buildingsLocations) do
        o:build(v)
    end

    o.buildCheckIntervalSubscribedIndex = subscribe_ExecuteOnTurn(GetTurn() +o.buildCheckInterval, function()
        buildUpdateInterval(o)
    end)
end

function AIModuleBuildingPlacer:new()
    local o = AIModule:new()
    setmetatable(o, self)
    self.__index = self

    o.buildingsLocations = {}
    o.buildCheckInterval = 64

    return o
end

function AIModuleBuildingPlacer:addBuildPlace(buildPlace)
    table.insert(self.buildingsLocations, buildPlace)
end

function AIModuleBuildingPlacer:removeBuildPlace(buildPlace)
    for k, v in pairs(self.buildingsLocations) do
        if (v == buildPlace) then
            table.remove(self.buildingsLocations, k)
            break
        end
    end
end

function AIModuleBuildingPlacer:build(buildPlace)
    if (buildPlace:canBeBuilt()) then
        subscribe_ExecuteOnTurn(GetTurn() + self.buildDelay, function()
            if (buildPlace:place()) then
                self:removeBuildPlace(buildPlace)
            end
        end)
        self.buildDelay = self.buildDelay + math.random(8, 15)
    end
end


function AIModuleBuildingPlacer:enable()
    if (self.isEnabled) then
        return
    end
    self:setEnabled(true)
    self.buildCheckIntervalSubscribedIndex = subscribe_ExecuteOnTurn(GetTurn() + 36, function() -- Start placing stuff 3 seconds after enabled
        buildUpdateInterval(self)
    end)
end

function AIModuleBuildingPlacer:disable()
    if (not self.isEnabled) then
        return
    end
    self:setEnabled(false)
    unsubscribe_ExecuteOnTurn(self.buildCheckIntervalSubscribedIndex)
end

