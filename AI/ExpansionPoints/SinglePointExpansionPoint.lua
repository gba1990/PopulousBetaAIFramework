SinglePointExpansionPoint = ExpansionPoint:new()

function SinglePointExpansionPoint:new(o, startCoordinate, endCoordinate)
    local o = o or ExpansionPoint:new(nil, startCoordinate, endCoordinate)
    setmetatable(o, self)
    self.__index = self

    o.startCoordinate = startCoordinate
    o.endCoordinate = endCoordinate
    
    o.castedLBs = 0
    o._isComplete = false

    return o
end

function SinglePointExpansionPoint:isComplete()
    if (self._isComplete) then return self._isComplete end

    self._isComplete = (self.castedLBs > 0)

    return self._isComplete
end

function SinglePointExpansionPoint:getNextPoints()
    if (self._isComplete) then return nil, nil end
    
    local start = self.startCoordinate
    local finish = self.endCoordinate

    return start, finish
end