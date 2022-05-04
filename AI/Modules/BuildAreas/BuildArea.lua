BuildArea = AIModule:new()

function BuildArea:new(center, radius)
    local o = AIModule:new()
    setmetatable(o, self)
    self.__index = self
    
    o.center = center
    o.radius = radius

    return o
end

function BuildArea:updateAndProcess()

end