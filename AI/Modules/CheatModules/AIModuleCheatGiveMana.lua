AIModuleCheatGiveMana = AIModule:new() -- Cannot instantiate AIModuleIntervalCheat here, gave an error for no parameters were given

function AIModuleCheatGiveMana:new(o, ai, mana, interval)
    local o = o or AIModuleIntervalCheat:new()
    setmetatable(o, self)
    self.__index = self

    o.ai = ai
    o.increaseAmount = mana or o.increaseAmount
    o.interval = interval or o.interval

    o:enable()
    return o
end

function AIModuleCheatGiveMana:doCheat()
    GIVE_MANA_TO_PLAYER(self.ai:getTribe(), self.increaseAmount)
end