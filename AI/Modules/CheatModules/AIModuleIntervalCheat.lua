AIModuleIntervalCheat = AIModule:new()

function AIModuleIntervalCheat:new(o, ai)
    local o = o or AIModule:new()
    setmetatable(o, self)
    self.__index = self

    o.ai = ai
    o.increaseAmount = 6
    o.interval = 12

    o:enable()
    return o
end

function AIModuleIntervalCheat:doCheat()
    -- Override to perform the cheat here
end

local function interval(o)
    o:doCheat()
    o.subscriberIndex = subscribe_ExecuteOnTurn(GetTurn() + o.interval, function ()
        interval(o)
    end)
end

function AIModuleIntervalCheat:enable()
    if (self.isEnabled) then
        return
    end
    self:setEnabled(true)
    self.subscriberIndex = subscribe_ExecuteOnTurn(GetTurn() + self.interval, function ()
        interval(self)
    end)
end

function AIModuleIntervalCheat:disable()
    if (not self.isEnabled) then
        return
    end
    self:setEnabled(false)
    unsubscribe_ExecuteOnTurn(self.subscriberIndex)
end