AIShamanSpellSelector = AIModule:new()

function AIShamanSpellSelector:new(o)
    local o = o or AIModule:new()
    setmetatable(o, self)
    self.__index = self
    
    o.aiModuleShaman = nil
    o.isEnabled = false

    o.candidateLocations = {}
    o.spellCandidateCheckers = {}
    o.spellCandidateCheckers[M_SPELL_BLAST] = function() o:blastCandidateChecker() end
    o.spellCandidateCheckers[M_SPELL_LIGHTNING_BOLT] = function() o:lightningCandidateChecker() end
    --o.spellCandidateCheckers[M_SPELL_WHIRLWIND] = function() o:tornadoCandidateChecker() end
    --o.spellCandidateCheckers[M_SPELL_INSECT_PLAGUE] = function() o:swarmCandidateChecker() end
    --o.spellCandidateCheckers[M_SPELL_HYPNOTISM] = function() o:blastCandidateChecker() end
    --o.spellCandidateCheckers[M_SPELL_FIRESTORM] = function() o:blastCandidateChecker() end
    --o.spellCandidateCheckers[M_SPELL_GHOST_ARMY] = function() o:blastCandidateChecker() end
    --o.spellCandidateCheckers[M_SPELL_ANGEL_OF_DEATH] = function() o:blastCandidateChecker() end
    --o.spellCandidateCheckers[M_SPELL_EARTHQUAKE] = function() o:earthquakeCandidateChecker() end
    --o.spellCandidateCheckers[M_SPELL_VOLCANO] = function() o:blastCandidateChecker() end

    
    o.skipSpells = {
        M_SPELL_BURN,
        M_SPELL_INVISIBILITY, 
        M_SPELL_EROSION, 
        M_SPELL_SWAMP,
        M_SPELL_HYPNOTISM,
        M_SPELL_LAND_BRIDGE, 
        M_SPELL_FLATTEN, 
        M_SPELL_VOLCANO, 
        M_SPELL_CONVERT_WILD,
        M_SPELL_ARMAGEDDON,
        M_SPELL_SHIELD,
        M_SPELL_BLOODLUST,
        M_SPELL_TELEPORT,
        M_SPELL_VOLCANO,
        M_SPELL_ANGEL_OF_DEATH,
        M_SPELL_GHOST_ARMY,
        M_SPELL_FIRESTORM,
        M_SPELL_WHIRLWIND,
        M_SPELL_EARTHQUAKE,
        M_SPELL_INSECT_PLAGUE
    }

    return o
end

function AIShamanSpellSelector:selectSpell()
    -- result = {spell = nil, coordinates = nil, target = nil, score = nil}
    --logger.msgLog("Selecting spell")

    local canShamanCurrentlyCast = getShaman(self.aiModuleShaman.ai:getTribe()) ~= nil and self.aiModuleShaman:nextPossibleCastTurn() <= GetTurn()
    if (not canShamanCurrentlyCast) then
        --logger.msgLog("Shaman cannot currently cast!")
        return nil
    end
   
    -- Execute all the checkers for all spells
    self.candidateLocations = {} -- {spell = nil, coordinates = nil, target = nil, score = nil}
    for i = 1, NUM_SPELL_TYPES , 1 do
        if (not util.tableContains(self.skipSpells, i)) then
            if (self.aiModuleShaman:couldSpellBeCasted(i)) then
                self.spellCandidateCheckers[i]()
            end
        end
    end

    -- Rank the results and return the best (highest score)
    local bestEntry = nil
    local bestScore = 0
    for k, v in pairs(self.candidateLocations) do
        if (v.score > bestScore) then
            bestEntry = v
            bestScore = v.score
            --logger.msgLog("Spell: %s, Score: %s, ", v.spell, v.score)
        end
    end

    if (bestEntry ~= nil) then
        --logger.msgLog("Best: %s, %s, ", bestEntry.spell, bestEntry.score)
    end
    return bestEntry
end

local function addPositionsAsCandidates(o, entries)
    for k, v in pairs(entries) do
        if (v.score >= 20) then -- We wont add poor entries
            table.insert(o.candidateLocations, v)
        end
    end
end

local function getShamanPositionAndSpellRadius(o, spell)
    local shaman = getShaman(o.aiModuleShaman.ai:getTribe())
    local isInTower = false
    local radius = frameworkMath.calculateSpellRangeFromPosition(shaman.Pos.D3, spell, isInTower)

    return shaman.Pos.D3, radius
end

function AIShamanSpellSelector:blastCandidateChecker()
    local newPositions = {}

    local c3, r = getShamanPositionAndSpellRadius(self, M_SPELL_BLAST)
    SearchMapCells(CIRCULAR, 0, 0, math.floor(r/512), world_coord3d_to_map_idx(c3), function(me)
        me.MapWhoList:processList(function(t)
          if (t ~= nil and t.Type == T_PERSON and are_players_allied(t.Owner, self.aiModuleShaman.ai:getTribe()) == 0) then
              if (is_person_on_a_building(t) == 0 and t.Flags3 & TF3_SHIELD_ACTIVE == 0 and t.Flags2 & TF2_THING_IS_AN_INVISIBLE_PERSON  == 0 ) then
                local entry = {
                    spell = M_SPELL_BLAST, 
                    coordinates = t.Pos.D2, 
                    target = t, 
                    score = 10 * frameworkMath.clamp(GetTurn()/(12*60) * 0.5, 0, 10)
                }

                if (t.Model == M_PERSON_MEDICINE_MAN) then
                    entry.score = 50 + math.random(5, 10)
                elseif (t.Model == M_PERSON_SUPER_WARRIOR ) then
                    entry.score = 50 + math.random(0, 7)
                elseif (t.Model == M_PERSON_WARRIOR) then
                    entry.score = 30 + math.random(0, 10)
                elseif (t.Model == M_PERSON_RELIGIOUS) then
                    entry.score = 30 + math.random(0, 10) + is_person_preaching(t) * 10
                end

                table.insert(newPositions, entry)
              end
          end
          return true
        end)
        return true
      end)

    addPositionsAsCandidates(self, newPositions)
end

function AIShamanSpellSelector:lightningCandidateChecker()
    local newPositions = {}

    local c3, r = getShamanPositionAndSpellRadius(self, M_SPELL_LIGHTNING_BOLT)
    SearchMapCells(CIRCULAR, 0, 0, math.floor(r/512), world_coord3d_to_map_idx(c3), function(me)
        me.MapWhoList:processList(function(t)
            if (t ~= nil and are_players_allied(t.Owner, self.aiModuleShaman.ai:getTribe()) == 0) then
                local entry = {
                    spell = M_SPELL_LIGHTNING_BOLT, 
                    coordinates = t.Pos.D2, 
                    target = t,
                    score = 0
                }
                if (t.Type == T_PERSON and t.Flags3 & TF3_SHIELD_ACTIVE == 0 and t.Flags2 & TF2_THING_IS_AN_INVISIBLE_PERSON  == 0) then
                    
                    local time = frameworkMath.calculateSpellCastTimeToReachPosition(c3, t.Pos.D3)
                    local position = frameworkMath.calculateThingPositionAfterTime(t, time)
                    if (t.Model == M_PERSON_MEDICINE_MAN) then
                        entry.score = 30 + math.random(0, 30)
                        entry.coordinates = position
                        entry.target = nil
                    elseif (me.MapWhoList:count() > 3) then
                        entry.score = 40
                        entry.coordinates = position
                        entry.target = nil
                    end

                elseif (t.Type == T_BUILDING) then
                    
                    if (t.Model == M_BUILDING_TEMPLE or t.Model == M_BUILDING_WARRIOR_TRAIN or t.Model == M_BUILDING_SUPER_TRAIN) then
                        entry.score = 30 + math.random(0, 30)
                    elseif (t.Model == M_BUILDING_DRUM_TOWER) then
                        local dwellers = t.u.Bldg.Dwellers
                        for k, v in pairs(dwellers) do
                            local person = v:get()
                            if (person ~= nil and person.Model == M_PERSON_FIREWARRIOR) then
                                entry.score = 40 + math.random(0, 30)
                                break
                            end
                        end
                    end

                end
                table.insert(newPositions, entry)
            end
          return true
        end)
        return true
      end)

    addPositionsAsCandidates(self, newPositions)
end

function AIShamanSpellSelector:swarmCandidateChecker()
    local newPositions = {}

    addPositionsAsCandidates(self, newPositions)
end

function AIShamanSpellSelector:tornadoCandidateChecker()
    local newPositions = {}


    local c3, r = getShamanPositionAndSpellRadius(self, M_SPELL_WHIRLWIND)
    SearchMapCells(CIRCULAR, 0, 0, math.floor(r/512), world_coord3d_to_map_idx(c3), function(me)
        me.MapWhoList:processList(function(t)
            if (t ~= nil and are_players_allied(t.Owner, self.aiModuleShaman.ai:getTribe()) == 0) then
                local entry = {
                    spell = M_SPELL_WHIRLWIND, 
                    coordinates = t.Pos.D2, 
                    target = t,
                    score = 0
                }
                if (t.Type == T_BUILDING) then
                    entry.score = 25
                    if (t.Model == M_BUILDING_TEMPLE or t.Model == M_BUILDING_WARRIOR_TRAIN or t.Model == M_BUILDING_SUPER_TRAIN) then
                        entry.score = 40 + math.random(0, 20)
                    elseif (t.Model == M_BUILDING_DRUM_TOWER) then
                        local dwellers = t.u.Bldg.Dwellers
                        for k, v in pairs(dwellers) do
                            local person = v:get()
                            if (person ~= nil and person.Model == M_PERSON_FIREWARRIOR) then
                                entry.score = 40 + math.random(0, 20)
                                break
                            end
                        end
                    end

                end
                table.insert(newPositions, entry)
            end
            return true
        end)
        return true
    end)

    addPositionsAsCandidates(self, newPositions)
end

function AIShamanSpellSelector:earthquakeCandidateChecker()
    local newPositions = {}

    addPositionsAsCandidates(self, newPositions)
end