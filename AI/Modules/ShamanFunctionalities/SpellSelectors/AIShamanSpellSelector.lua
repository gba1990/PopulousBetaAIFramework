AIShamanSpellSelector = AIModule:new()

--[[
    TODO: 
        Tornado balloon with shaman on it (except if it contains a shielded follower)
        If person is inside allied hut, dont light
        If person in fight, dont predict (check if the predicted location is exaclty on top cause u may need to do nothing)
        If lightning is going to be inside one of my allies huts, dont predict
        If light is goint into water, dont predict
        If person is patrolling, dont predict light location
]]

function AIShamanSpellSelector:new(o)
    local o = o or AIModule:new()
    setmetatable(o, self)
    self.__index = self
    
    o.aiModuleShaman = nil
    o.isEnabled = false

    o.entryMinimunScore = 20 -- Value that determines what a poor entry is, lower values will make the shaman use more spells (as "less threatening" situations will de defended)
    o.candidateLocations = {}
    o.spellCandidateCheckers = {}
    o.spellCandidateCheckers[M_SPELL_BLAST] = function() o:blastCandidateChecker() end
    o.spellCandidateCheckers[M_SPELL_LIGHTNING_BOLT] = function() o:lightningCandidateChecker() end
    o.spellCandidateCheckers[M_SPELL_WHIRLWIND] = function() o:tornadoCandidateChecker() end
    --o.spellCandidateCheckers[M_SPELL_INSECT_PLAGUE] = function() o:swarmCandidateChecker() end
    --o.spellCandidateCheckers[M_SPELL_HYPNOTISM] = function() o:blastCandidateChecker() end
    --o.spellCandidateCheckers[M_SPELL_FIRESTORM] = function() o:blastCandidateChecker() end
    --o.spellCandidateCheckers[M_SPELL_GHOST_ARMY] = function() o:blastCandidateChecker() end
    --o.spellCandidateCheckers[M_SPELL_ANGEL_OF_DEATH] = function() o:blastCandidateChecker() end
    o.spellCandidateCheckers[M_SPELL_EARTHQUAKE] = function() o:earthquakeCandidateChecker() end
    --o.spellCandidateCheckers[M_SPELL_VOLCANO] = function() o:blastCandidateChecker() end

    o.turnOffset = math.random(1, 12) -- To avoid from all AI to cast at the same time the same spell
    o.turnCheckChance = {}
    o.turnCheckChance[M_SPELL_BLAST] = {chance = 90, interval = 1} -- Every (getTurn() % interval) there is a percent chance to check if blast can be casted
    o.turnCheckChance[M_SPELL_LIGHTNING_BOLT] = {chance = 75, interval = 5}
    o.turnCheckChance[M_SPELL_WHIRLWIND] = {chance = 50, interval = 18}
    o.turnCheckChance[M_SPELL_EARTHQUAKE] = {chance = 50, interval = 22}
    
    o.skipSpells = { -- Which spells we dont consider when casting
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
        M_SPELL_INSECT_PLAGUE
    }

    return o
end

function AIShamanSpellSelector:selectSpell()
    local canShamanCurrentlyCast = getShaman(self.aiModuleShaman.ai:getTribe()) ~= nil and self.aiModuleShaman:nextPossibleCastTurn() <= GetTurn()
    if (not canShamanCurrentlyCast) then
        return nil
    end
   
    -- Execute all the checkers for all spells
    self.candidateLocations = {} -- {spell = nil, coordinates = nil, target = nil, score = nil}
    for i = 1, NUM_SPELL_TYPES , 1 do
        if (not util.tableContains(self.skipSpells, i)) then
            if (self.aiModuleShaman:couldSpellBeCasted(i)) then
                local entry = self.turnCheckChance[i]
                if (math.random(0,99) < entry.chance and (GetTurn() + self.turnOffset) % entry.interval == 0) then
                    self.spellCandidateCheckers[i]()
                end
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
        end
    end

    return bestEntry
end

local function addPositionsAsCandidates(o, entries)
    for k, v in pairs(entries) do
        if (v.score >= o.entryMinimunScore) then -- We wont add poor entries
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

local function isPersonThingValidForSpellCast(thing)
    local result = thing ~= nil
            and thing.State ~= S_PERSON_ELECTROCUTED
            and thing.State ~= S_PERSON_SHAMAN_IN_PRISON
            and thing.State ~= S_PERSON_AOD2_VICTIM
            and thing.State ~= S_PERSON_IN_WHIRLWIND
            and thing.State ~= S_PERSON_DYING
            and thing.State ~= S_PERSON_DROWNING
            and thing.State ~= S_PERSON_BEING_PREACHED
            and thing.Flags2 & TF2_THING_IN_AIR == 0
            and thing.Flags2 & TF2_THING_IS_AN_INVISIBLE_PERSON == 0

    return result
end

function AIShamanSpellSelector:blastCandidateChecker()
    local newPositions = {}

    local c3, r = getShamanPositionAndSpellRadius(self, M_SPELL_BLAST)
    SearchMapCells(CIRCULAR, 0, 0, math.floor(r/512), world_coord3d_to_map_idx(c3), function(me)
        me.MapWhoList:processList(function(t)
          if (t ~= nil and t.Type == T_PERSON and are_players_allied(t.Owner, self.aiModuleShaman.ai:getTribe()) == 0) then
              if (is_person_on_a_building(t) == 0 and is_person_in_airship(t) == 0 and t.Flags3 & TF3_SHIELD_ACTIVE == 0  and isPersonThingValidForSpellCast(t)) then
                local entry = {
                    spell = M_SPELL_BLAST, 
                    coordinates = t.Pos.D2, 
                    target = t, 
                    score = 10 + frameworkMath.clamp(GetTurn()/(12*60) * 0.5, 0, 10) -- To avoid brave blasting on first 20 mins
                }

                -- Sometimes dont do a direct hit
                if (math.random(1,99) < 50) then
                    if (math.random(1,99) < 50) then
                        local position = frameworkMath.calculateThingPositionAfterTime(t, 6)
                        entry.coordinates = position
                    end
                    entry.target = nil
                end

                if (t.Model == M_PERSON_MEDICINE_MAN) then
                    entry.score = 50 + math.random(5, 10)
                elseif (t.Model == M_PERSON_SUPER_WARRIOR ) then
                    entry.score = 50 + math.random(0, 7)
                elseif (t.Model == M_PERSON_WARRIOR) then
                    entry.score = 30 + math.random(0, 10)
                elseif (t.Model == M_PERSON_RELIGIOUS) then
                    entry.score = 30 + math.random(0, 10) + is_person_preaching(t) * 10
                end

                if (entry.score >= self.entryMinimunScore) then table.insert(newPositions, entry) end
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
                if (t.Type == T_PERSON and t.Flags3 & TF3_SHIELD_ACTIVE == 0 and isPersonThingValidForSpellCast(t)) then
                    
                    local time = frameworkMath.calculateSpellCastTimeToReachPosition(c3, t.Pos.D3)
                    local position = frameworkMath.calculateThingPositionAfterTime(t, time)
                    
                    if (t.Model == M_PERSON_MEDICINE_MAN) then
                        entry.score = 20 + math.random(0, 30)
                        entry.coordinates = position
                        if ((get_world_dist_xyz(t.Pos.D3, c3) > r/2 and math.random(0, 99) < 75) or math.random(0, 99) < 25) then entry.target = nil end
                    elseif (is_person_in_drum_tower(t) == 1) then
                        entry.score = 10 * t.Model
                    else
                        local specialists = functional.filter(function (element)
                            return element ~= nil 
                                    and element.Type == T_PERSON 
                                    and (element.Model == M_PERSON_RELIGIOUS 
                                            or element.Model == M_PERSON_SUPER_WARRIOR 
                                            or element.Model == M_PERSON_MEDICINE_MAN 
                                            or element.Model == M_PERSON_WARRIOR
                                        )
                        end, util.objectListToTable(me.MapWhoList))

                        entry.score = 10 * #specialists
                        entry.coordinates = position
                        entry.target = nil
                    end
                elseif (t.Type == T_BUILDING and t.State == S_BUILDING_STAND) then
                    if (t.Model == M_BUILDING_TEMPLE or t.Model == M_BUILDING_WARRIOR_TRAIN or t.Model == M_BUILDING_SUPER_TRAIN) then
                        entry.score = 30 + math.random(0, 30)
                    end
                end
                if (entry.score >= self.entryMinimunScore) then table.insert(newPositions, entry) end
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

                if (t.Type == T_PERSON and is_person_in_drum_tower(t) == 1 and t.Flags3 & TF3_SHIELD_ACTIVE == 0 and isPersonThingValidForSpellCast(t)) then
                    entry.score = 15 * t.Model
                elseif (t.Type == T_BUILDING and t.State == S_BUILDING_STAND) then
                    entry.score = 25
                    if (t.Model == M_BUILDING_TEMPLE or t.Model == M_BUILDING_WARRIOR_TRAIN or t.Model == M_BUILDING_SUPER_TRAIN) then
                        entry.score = 40 + math.random(0, 20)
                    end
                end
                if (entry.score >= self.entryMinimunScore) then table.insert(newPositions, entry) end
            end
            return true
        end)
        return true
    end)

    addPositionsAsCandidates(self, newPositions)
end

function AIShamanSpellSelector:earthquakeCandidateChecker()
    local newPositions = {}

    local c3, r = getShamanPositionAndSpellRadius(self, M_SPELL_EARTHQUAKE)
    SearchMapCells(CIRCULAR, 0, 0, math.floor(r/512), world_coord3d_to_map_idx(c3), function(me)
        me.MapWhoList:processList(function(t)
            if (t ~= nil and are_players_allied(t.Owner, self.aiModuleShaman.ai:getTribe()) == 0) then
                local entry = {
                    spell = M_SPELL_EARTHQUAKE, 
                    coordinates = t.Pos.D2, 
                    target = t,
                    score = 0
                }
                if (t.Type == T_BUILDING and t.State == S_BUILDING_STAND) then
                    local score = 0
                    SearchMapCells(CIRCULAR, 0, 0, 6, world_coord3d_to_map_idx(t.Pos.D3), function(me)
                        me.MapWhoList:processList(function(t)
                            if (are_players_allied(t.Owner, self.aiModuleShaman.ai:getTribe()) == 1 or t.Owner == TRIBE_NEUTRAL or t.Owner == TRIBE_HOSTBOT) then
                                return true
                            end
                            if (t.Type == T_BUILDING) then
                                score = score + 1
                                if (t.Model == M_BUILDING_TEMPLE or t.Model == M_BUILDING_WARRIOR_TRAIN or t.Model == M_BUILDING_SUPER_TRAIN) then
                                    score = score + 6
                                end
                                if (t.Model == M_BUILDING_DRUM_TOWER) then
                                    score = score + 4
                                end
                                if (t.State == S_BUILDING_UNDER_CONSTRUCTION) then
                                    score = score / 2
                                end
                            elseif (t.Type == T_PERSON) then
                                -- If there is quite a lot of people we may want to EQ too
                                score = score + 0.5
                            end
                            return true
                        end)
                        return true
                    end)
                    entry.score = score
                end
                if (entry.score >= self.entryMinimunScore) then
                    table.insert(newPositions, entry)
                end
            end
            return true
        end)
        return true
    end)

    addPositionsAsCandidates(self, newPositions)
end