AIShamanBehaviourDuel = AIShamanBehaviour:new()

function AIShamanBehaviourDuel:new(o)
    local o = o or AIShamanBehaviour:new()
    setmetatable(o, self)
    self.__index = self
    
    o.aiModuleShaman = nil
    
    o:enable()
    return o
end