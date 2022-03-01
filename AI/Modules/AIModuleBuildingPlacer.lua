AIModuleBuildingPlacer = AIModule:new()

function AIModuleBuildingPlacer:new(o, ai)
    local o = o or AIModule:new()
    setmetatable(o, self)
    self.__index = self

    o.ai = ai
    o.buildingsLocations = {}

    o.buildCheckInterval = 64
    o.buildCheckIntervalSubscribedIndex = nil
    return o
end

function AIModuleBuildingPlacer:addBuildPlace(buildPlace)
    table.insert(self.buildingsLocations, buildPlace)
end

function AIModuleBuildingPlacer:build(buildPlace)
    if (buildPlace:canBeBuilt()) then
        buildPlace:place()
    end
end

local function buildUpdateInterval(o)
    for i, v in ipairs(o.buildingsLocations) do
        o:build(v)
    end

    o.buildCheckIntervalSubscribedIndex = subscribe_ExecuteOnTurn(GetTurn() +o.buildCheckInterval, function()
        buildUpdateInterval(o)
    end)
end

function AIModuleBuildingPlacer:enable()
    self.buildCheckIntervalSubscribedIndex = subscribe_ExecuteOnTurn(GetTurn() + 36, function() -- Start placing stuff 3 seconds after enabled
        buildUpdateInterval(self)
    end)
end

function AIModuleBuildingPlacer:disable()
    unsubscribe_ExecuteOnTurn(self.buildCheckIntervalSubscribedIndex)
end

