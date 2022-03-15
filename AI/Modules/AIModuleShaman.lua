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
    o.availableSpells = availableSpells or {} -- The list of spells that AI has unlocked
    o.singleShotSpells = {} -- {spell = , count = } To store shots of spells (can be used to mimic a "charging spell" behaviour)
    o:setSpellManager(AIShamanSpellManagerBucket:new())
    o:setSpellSelector(AIShamanSpellSelector:new())

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

    self.updateSingleShotSpellsSubscriptionIndex = subscribe_OnTrigger(function (t)
        if (t.u.Trigger == nil or t.u.Trigger.TriggeringPlayer ~= self.ai:getTribe()) then
            return
        end
        for i = 0, #t.u.Trigger.EditorThingIdxs-1, 1 do
            local entry = t.u.Trigger.EditorThingIdxs[i]
            local thing = GetThing(entry)
            if (thing ~= nil) then
                local disc = thing.u.Discovery
                if (disc ~= nil and disc.DiscoveryType == 11) then --- TODO It is 11 if it is a spell (should be 1 but it is 11, dunno?)
                    self:giveSingleShotSpell(disc.DiscoveryModel)
                end
            end
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

    unsubscribe_OnTrigger(self.updateSingleShotSpellsSubscriptionIndex)
end

-- Utilities

function AIModuleShaman:castSpell(spell, location)
    local result = self.spellManager:castSpell(spell,location)
    if (result ~= nil) then
        self.lastCastTurn = GetTurn()
        self._nextPossibleCastTurn = self.lastCastTurn + math.random(self.minimunCastInterval, self.maximunCastInterval)
    end
    return result
end

function AIModuleShaman:nextPossibleCastTurn()
    return self._nextPossibleCastTurn
end

function AIModuleShaman:couldSpellBeCasted(spell)
    return self.spellManager:couldSpellBeCasted(spell)
end

function AIModuleShaman:doIHaveSingleShot(spell)
    local result = false
    for k, v in pairs(self.singleShotSpells) do
        if (v.spell == spell) then
            return v.count > 0
        end
    end
    return result
end

function AIModuleShaman:numberOfSingleShot(spell)
    local result = 0
    for k, v in pairs(self.singleShotSpells) do
        if (v.spell == spell) then
            return v.count
        end
    end
    return result
end

function AIModuleShaman:removeSingleShotFromSpell(spell)
    for k, v in pairs(self.singleShotSpells) do
        if (v.spell == spell) then
            v.count = v.count - 1
            break
        end
    end
end

function AIModuleShaman:giveSingleShotSpell(spell)
    for k, v in pairs(self.singleShotSpells) do
        if (v.spell == spell) then
            v.count = v.count + 1
            return
        end
    end
    
    local entry = {spell = spell, count = 1}
    table.insert(self.singleShotSpells, entry)
end