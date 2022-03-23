AIModuleShaman = AIModule:new()

function AIModuleShaman:new(o, ai, availableSpells)
    local o = o or AIModule:new()
    setmetatable(o, self)
    self.__index = self

    o.ai = ai
    o.behaviours = {}

    -- Spell manager
    o.castTrackerSubscriptionIndex = nil
    o.minimunCastInterval = 15
    o.maximunCastInterval = 25
    o._nextPossibleCastTurn = 64  -- Cannot cast on the first 64 turns
    o.lastCastTurn = 0
    o:setSpellManager(AIShamanSpellManagerBucket:new())
    o:setSpellSelector(AIShamanSpellSelector:new())
    
    availableSpells = availableSpells or {}
    for k, v in pairs(availableSpells) do
        o:setSpellAvailable(v)
    end

    o:enable()
    return o
end

-- Basic functionalities and events

function AIModuleShaman:setSpellSelector(selector)
    self.spellSelector = selector
    selector.aiModuleShaman = self
end

function AIModuleShaman:setSpellManager(manager)
    if (self.spellManager ~= nil) then
        self.spellManager:disable()
    end
    self.spellManager = manager
    manager.aiModuleShaman = self
    manager:enable()
end

function AIModuleShaman:setBehaviour(id, aiShamanBehaviour)
    if (self.behaviours[id] ~= nil) then
        self.behaviours[id]:disable()
    end
    self.behaviours[id] = aiShamanBehaviour
    if (aiShamanBehaviour ~= nil) then
        aiShamanBehaviour.aiModuleShaman = self
        aiShamanBehaviour:enable()
    end
end

function AIModuleShaman:enable()
    if (self.isEnabled) then
        return
    end
    self:setEnabled(true)
    if (self.spellManager ~= nil) then
        self.spellManager:enable()
    end

    for k, v in pairs(self.behaviours) do
        v:enable()
    end

    self.updateLastCastTurnSubscriptionIndex = subscribe_OnCreateThing(function (thing)
        if (thing.Type == T_SPELL and thing.Owner == self.ai:getTribe()) then
            -- We casted a spell
            self.lastCastTurn = GetTurn()
            self._nextPossibleCastTurn = self.lastCastTurn + math.random(self.minimunCastInterval, self.maximunCastInterval)
        end
    end)
end

function AIModuleShaman:disable()
    if (not self.isEnabled) then
        return
    end
    self:setEnabled(false)
    if (self.spellManager ~= nil) then
        self.spellManager:disable()
    end

    for k, v in pairs(self.behaviours) do
        v:disable()
    end

    unsubscribe_OnCreateThing(self.updateLastCastTurnSubscriptionIndex)
end

-- Utilities

function AIModuleShaman:castSpell(spell, location)
    local result = self.spellManager:castSpell(spell,location)
    if (result ~= nil) then
        -- This will be overriden by the code executed on the OnCreateThing, but we set it here to avoid casting again before the spell goes off
        self.lastCastTurn = GetTurn()
        self._nextPossibleCastTurn = self.lastCastTurn + self.minimunCastInterval
    end
    return result
end

function AIModuleShaman:nextPossibleCastTurn()
    return self._nextPossibleCastTurn
end

function AIModuleShaman:couldSpellBeCasted(spell)
    return self.spellManager:couldSpellBeCasted(spell)
end

function AIModuleShaman:doIHaveSpellAvailable(spell)
    return PThing.SpellAvailable(self.ai:getTribe(), spell)
end

function AIModuleShaman:doIHaveSingleShot(spell)
    return PThing.NumSingleShot(self.ai:getTribe(), spell) > 0
end

function AIModuleShaman:numberOfSingleShot(spell)
    return PThing.NumSingleShot(self.ai:getTribe(), spell)
end

function AIModuleShaman:removeSingleShotFromSpell(spell)
    PThing.GiveShot(self.ai:getTribe(), spell, -1)
end

function AIModuleShaman:giveSingleShotSpell(spell)
    PThing.GiveShot(self.ai:getTribe(), spell, 1)
end

function AIModuleShaman:setSpellAvailable(spell)
    PThing.SpellSet(self.ai:getTribe(), spell, 1, 1)
end