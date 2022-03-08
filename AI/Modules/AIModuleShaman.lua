AIModuleShaman = AIModule:new()

function AIModuleShaman:new(o, ai)
    local o = o or AIModule:new()
    setmetatable(o, self)
    self.__index = self

    o.ai = ai
    o.behaviour = nil
    o.backdoorLocations = nil
    o.expansionLocations = nil

    -- Dodge stuff
    o.dodgeControllerSubscriptionIndex = nil
    o.dodgeLastDodgeTurn = 64 -- Turn when the last dodge took place. Can be used to set a gameturn from when dodges can start to happen (here it is set to 64 so CoR has enough time to be created before first dodge)
    o.dodgePercentChance = 100 -- % of chance to perform a dodge, for example it can increment as the game advances so "ai gets better at dodging" or viceversa
    o.dodgeIntervalBetweenDodges = 15 -- Once a dodge takes place how long before the next (set to at least 12 or so)

    o:enable()

    return o
end

function AIModuleShaman:doDodge()
    handlerFunctions.AIShamanDodgeController.usingOnCreateThing(self)
end

function AIModuleShaman:dontDoDodge()
    unsubscribe_OnCreateThing(self.dodgeControllerSubscriptionIndex)
end

function AIModuleShaman:enable()
    if (self.isEnabled) then
        return
    end
    self:setEnabled(true)
    self:doDodge()
end

function AIModuleShaman:disable()
    if (not self.isEnabled) then
        return
    end
    self:setEnabled(false)
    self:dontDoDodge()
end