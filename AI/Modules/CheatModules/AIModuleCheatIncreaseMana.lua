AIModuleCheatIncreaseMana = AIModule:new() -- Cannot instantiate AIModuleIntervalCheat here, gave an error for no parameters were given

function AIModuleCheatIncreaseMana:new(increasePercentage)
    local o = AIModuleIntervalCheat:new()
    setmetatable(o, self)
    self.__index = self

    o.increasePercentage = increasePercentage or 10 -- By default, AI will get 10% more mana
    o.interval = 4 -- Mana is updated/given every 4 turns

    return o
end

function AIModuleCheatIncreaseMana:doCheat()
    local p = getPlayer(self.ai:getTribe())
    self.increaseAmount = math.floor(self.increasePercentage/100 * p.LastManaIncr)
    GIVE_MANA_TO_PLAYER(self.ai:getTribe(), self.increaseAmount)
end