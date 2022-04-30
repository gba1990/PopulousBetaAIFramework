AIModule = {}

function AIModule:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    
    o.isEnabled = false

    return o
end

function AIModule:setEnabled(value)
    self.isEnabled = value
end

function AIModule:enable()
    self:setEnabled(true)
end

function AIModule:disable()
    self:setEnabled(false)
end