AIShamanSpellManager = AIModule:new()

function AIShamanSpellManager:new(o)
    local o = o or AIModule:new()
    setmetatable(o, self)
    self.__index = self
    
    o.aiModuleShaman = nil
    o.isEnabled = false

    return o
end

function AIShamanSpellManager:castSpell(spell, location)
    return createThing(T_SPELL, spell, self.aiModuleShaman.ai:getTribe(), util.to_coord3D(location), false, false)
end

function AIShamanSpellManager:couldSpellBeCasted(spell)
    return self.aiModuleShaman:doIHaveSpellAvailable(spell) and self.aiModuleShaman:nextPossibleCastTurn() <= GetTurn()
end

-- Checks
function AIShamanSpellManager:checkCastDistance(spell, location)
    local sh = getShaman(self.aiModuleShaman.ai:getTribe())
    local isShamanInTower = is_person_in_drum_tower(sh) > 0
    local range = frameworkMath.calculateSpellRangeFromPosition(sh.Pos.D2, spell, isShamanInTower)
    local distance = get_world_dist_xz(util.to_coord2D(location), sh.Pos.D2)
    return range >= distance
end

function AIShamanSpellManager:checkCastMana(spell)
    local spellCost = spells_type_info()[spell].Cost
    return getPlayer(self.aiModuleShaman.ai:getTribe()).Mana - spellCost >= 0
end

function AIShamanSpellManager:checkCastShamanStatus()
    return true ---TODO
end

function AIShamanSpellManager:checkCastShamanCooldown()
    return self.aiModuleShaman:nextPossibleCastTurn() <= GetTurn()
end

function AIShamanSpellManager:checkCastSpellAvailable(spell)
    return self.aiModuleShaman:doIHaveSpellAvailable(spell) or self.aiModuleShaman:doIHaveSingleShot(spell)
end