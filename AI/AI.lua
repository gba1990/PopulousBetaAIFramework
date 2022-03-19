AI = {tribe = nil, modules = nil}

function AI:new(o, tribe)
    local o = o or {}
    setmetatable(o, self)
    self.__index = self
    
    o.tribe = tribe
    o.modules = {}

    return o
end

function AI:addModule(id, module)
    self.modules[id] = module
end

function AI:removeModule(id)
    self.modules[id]:disable()
    self.modules[id] = nil
end

function AI:setModule(id, module)
    self:disableModule(id)
    self.modules[id] = module
    self:enableModule(id)
end

function AI:getModule(id)
    return self.modules[id]
end

function AI:enableModule(id)
    local module = self.modules[id]
    if (module ~= nil) then
        module:enable()
    end
end

function AI:disableModule(id)
    local module = self.modules[id]
    if (module ~= nil) then
        module:disable()
    end
end

function AI:disableAI()
    for k, v in pairs(self.modules) do
        if (v ~= nil) then
            v:disable()
        end
    end
end

function AI:getTribe()
    return self.tribe
end