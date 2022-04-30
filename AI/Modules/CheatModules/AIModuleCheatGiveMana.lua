AIModuleCheatGiveMana = AIModule:new() -- Cannot instantiate AIModuleIntervalCheat here, gave an error for no parameters were given

function AIModuleCheatGiveMana:new(mana, interval)
    local o = AIModuleIntervalCheat:new()
    setmetatable(o, self)
    self.__index = self

    o.increaseAmount = mana or o.increaseAmount
    o.interval = interval or o.interval

    return o
end

function AIModuleCheatGiveMana:doCheat()
    GIVE_MANA_TO_PLAYER(self.ai:getTribe(), self.increaseAmount)
end