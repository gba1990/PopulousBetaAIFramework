AIShamanBehaviour = AIModule:new()

function AIShamanBehaviour:new(o)
    local o = o or AIModule:new()
    setmetatable(o, self)
    self.__index = self
    
    o.aiModuleShaman = nil
    o.isEnabled = false

    return o
end