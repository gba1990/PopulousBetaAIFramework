AI = {tribe = nil, modules = nil}
--AI.__index = AI

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

function AI:enableModule(id)
    self.modules[id]:enable()
end

function AI:disableAI()
    for k, v in pairs(self.modules) do
        v:disable()
    end
end

function AI:getTribe()
    return self.tribe
end