AIModule = {}

function AIModule:new(o, ai)
    local o = o or {}
    setmetatable(o, self)
    self.__index = self
    
    o.ai = ai
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