ExpansionPoint = {}

function ExpansionPoint:new(o, startCoordinate, endCoordinate, angleToExpandTowardsFromStartCoordinate)
    local o = o or {}
    setmetatable(o, self)
    self.__index = self

    o.startCoordinate = startCoordinate
    o.endCoordinate = endCoordinate
    o.angle = angleToExpandTowardsFromStartCoordinate
    
    o.castedLBs = 0
    o.numberOfLBs = nil
    o.targetCoordinate = nil
    o._isComplete = false

    return o
end

function ExpansionPoint:isComplete()
    -- If expansion was completed once, it will not be not completed in the future
    if (self._isComplete) then return self._isComplete end

    if (self.targetCoordinate ~= nil) then
        -- Is completed if we connect to the desired location
        self._isComplete = not frameworkMath.isWaterBetweenPoints(self.startCoordinate, self.targetCoordinate, self.angle)
    elseif (self.numberOfLBs ~= nil) then
        -- Is completed if we cast all the required LBs
        self._isComplete = (self.castedLBs == self.numberOfLBs)
    else
        -- Is completed if we casted the only required LB
        self._isComplete = (self.castedLBs > 0)
    end
    return self._isComplete
end

function ExpansionPoint:getNextPoints()
    if (self._isComplete) then return nil, nil end
    
    local start = frameworkMath.furthestInlandPointTowardsAngleAccurate(self.startCoordinate, self.angle)
    local finish = frameworkMath.furthestInlandPointTowardsAngleAccurate(self.endCoordinate, self.angle)

    return start, finish
end