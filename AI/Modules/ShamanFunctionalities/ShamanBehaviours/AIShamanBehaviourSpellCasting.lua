AIShamanBehaviourSpellCasting = AIShamanBehaviour:new()

function AIShamanBehaviourSpellCasting:new(o)
    local o = o or AIShamanBehaviour:new()
    setmetatable(o, self)
    self.__index = self
    
    o.aiModuleShaman = nil

    o:enable()
    return o
end

function AIShamanBehaviourSpellCasting:enable()
    if (self.isEnabled) then
        return
    end
    self:setEnabled(true)

    self.shamanCastingSubscriberIndex = subscribe_OnTurn(function ()
        -- Cast spells to enemies in range
        if (self.aiModuleShaman.spellSelector ~= nil) then
            local spell = self.aiModuleShaman.spellSelector:selectSpell()
            if (spell ~= nil) then
                local spellT = self.aiModuleShaman:castSpell(spell.spell,spell.coordinates)
                if (spellT ~= nil and spell.target ~= nil) then
                    util.spellTargetThing(spellT, spell.target)
                end
            end
        end
    end)
end

function AIShamanBehaviourSpellCasting:disable()
    if (not self.isEnabled) then
        return
    end
    self:setEnabled(false)

    unsubscribe_OnTurn(self.shamanCastingSubscriberIndex)
end
