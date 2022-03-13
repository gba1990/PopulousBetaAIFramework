AIShamanBehaviourDefendArea = AIShamanBehaviour:new()

function AIShamanBehaviourDefendArea:new(o, center, radius)
    local o = o or AIShamanBehaviour:new()
    setmetatable(o, self)
    self.__index = self
    
    o.aiModuleShaman = nil
    o.area = {center = center, radius = radius}

    o.inCombat = false
    o.isPatrolling = false
    o.patrolPoint = nil
    
    o:enable()
    return o
end

local function patrolAtArea(o)
    if (o.isPatrolling == false) then
        -- We will reduce the radius so the shaman is not in the border of the area
        local rad = o.area.radius - (o.area.radius* 0.25)
        o.patrolPoint = util.randomLandPointSurroundedByLandInArea(o.area.center, rad)
        if (o.patrolPoint ~= nil) then
            local shaman = getShaman(o.aiModuleShaman.ai:getTribe())
            local point2 = util.clone_Coord2D(o.patrolPoint)
            util.commandPersonToPatrol(shaman, o.patrolPoint, o.patrolPoint)
        end
        o.isPatrolling = true
    end
end

local function handleBehaviour(o)
    local handleInterval = 36
    local myTribe = o.aiModuleShaman.ai:getTribe()
    local shaman = getShaman(myTribe)

    if (shaman == nil) then
        -- TODO change behaviour to DEAD
        o.subcriberIndex = subscribe_ExecuteOnTurn(GetTurn() + 128, function()
            handleBehaviour(o)
        end)
        return
    end

    -- Locate enemies in area
    local enemiesInArea = util.findPeopleInArea(o.area.center, o.area.radius, function (thing)
        local result = true
            result = result and thing.Type == T_PERSON
            result = result and thing.Owner ~= myTribe
            result = result and are_players_allied(myTribe, thing.Owner) == 0
            result = result and thing.Flags2 & TF2_THING_IS_AN_INVISIBLE_PERSON == 0
        return result
    end)

    if (#enemiesInArea > 0) then
        o.inCombat = true
        handleInterval = 12
        -- Locate closest enemy
        local closestEnemy = enemiesInArea[1]
        local bestDistance = o.area.radius * 2
        for i = 1, #enemiesInArea, 1 do
            local d = get_world_dist_xz(enemiesInArea[i].Pos.D2, shaman.Pos.D2)
            if (d < bestDistance) then
                bestDistance = d
                closestEnemy = enemiesInArea[i]
            end
        end

        -- Get near closest enemy (so it is in range)
        if (bestDistance > frameworkMath.calculateSpellRangeFromPosition(shaman.Pos.D2, M_SPELL_BLAST, false)) then
            o.isPatrolling = false
            command_person_go_to_coord2d(shaman, closestEnemy.Pos.D2)
        end
    else
        o.inCombat = false
        if (not o.isPatrolling) then
            patrolAtArea(o)
        end
    end


    o.subcriberIndex = subscribe_ExecuteOnTurn(GetTurn() + handleInterval, function()
        handleBehaviour(o)
    end)
end

function AIShamanBehaviourDefendArea:enable()
    if (self.isEnabled) then
        return
    end
    self:setEnabled(true)
    self.subcriberIndex = subscribe_ExecuteOnTurn(GetTurn(), function()
        handleBehaviour(self)
    end)
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

function AIShamanBehaviourDefendArea:disable()
    if (not self.isEnabled) then
        return
    end
    self:setEnabled(false)
    unsubscribe_ExecuteOnTurn(self.subcriberIndex)
    unsubscribe_OnTurn(self.shamanCastingSubscriberIndex)
end

