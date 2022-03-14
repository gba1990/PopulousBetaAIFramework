AIShamanBehaviourIdle = AIShamanBehaviour:new()

function AIShamanBehaviourIdle:new(o)
    local o = o or AIShamanBehaviour:new()
    setmetatable(o, self)
    self.__index = self
    
    o.aiModuleShaman = nil

    return o
end
