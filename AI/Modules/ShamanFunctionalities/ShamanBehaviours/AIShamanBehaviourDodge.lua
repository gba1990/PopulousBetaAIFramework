AIShamanBehaviourDodge = AIShamanBehaviour:new()

function AIShamanBehaviourDodge:new(o)
    local o = o or AIShamanBehaviour:new()
    setmetatable(o, self)
    self.__index = self
    
    o.aiModuleShaman = nil

    -- Dodge stuff
    o.dodgeControllerSubscriptionIndex = nil
    o.dodgeLastDodgeTurn = 64 -- Turn when the last dodge took place. Can be used to set a gameturn from when dodges can start to happen (here it is set to 64 so CoR has enough time to be created before first dodge)
    o.dodgePercentChance = 100 -- % of chance to perform a dodge, for example it can increment as the game advances so "ai gets better at dodging" or viceversa
    o.dodgeIntervalBetweenDodges = 15 -- Once a dodge takes place how long before the next (set to at least 12 or so)
    
    
    o:enable()
    return o
end

local function performDodge(o)
    o.dodgeControllerSubscriptionIndex = subscribe_OnCreateThing(function (spell)
        -- First we check if it is a spell and if the dodge % allows us to dodge
        if (spell.Type == T_SPELL and math.random(0, 99) < o.dodgePercentChance) then
            local myTribe = o.aiModuleShaman.ai:getTribe()
            local myShaman = getShaman(myTribe)

            -- If shaman is dead nothing to dodge or we have recently dodged
            if (myShaman == nil or o.dodgeIntervalBetweenDodges >= GetTurn() - o.dodgeLastDodgeTurn) then
                return
            end

            if (not spell.Model == M_SPELL_LIGHTNING_BOLT and not spell.Model == M_SPELL_BLAST) then
                return
            end

            if (are_players_allied(myTribe, spell.Owner) > 0) then
                return
            end

            -- Check distance from target area
            local spellPosition = spell.Pos.D2
            if (get_world_dist_xz(spellPosition, myShaman.Pos.D2) > 600) then
                return
            end

            ------- DODGE -------
            local delay = math.random(2, 6) -- Delay so the ai is not a dodge master
            subscribe_ExecuteOnTurn(GetTurn() + delay, function ()
                -- In case shaman has died, we cannot dodge
                if (getShaman(myTribe) == nil) then
                    return
                end

                -- Find a closeby location
                local angle = math.random(0, frameworkMath.INGAME_ANGLE_MAX)
                local heightAtShamanPos = point_altitude(myShaman.Pos.D2.Xpos, myShaman.Pos.D2.Zpos)
                local moveDistance = 1000 -- How far shaman will dodge
                local maxHeightDifference = 256 -- How much can the shaman climb
                local candidateLocations = {} -- Random possible locations
                for i = 1, 4, 1 do
                    local candidatePoint = frameworkMath.calculatePosition(myShaman.Pos.D2, angle, moveDistance)
                    
                    -- Is candidate feasible? (is point land? is point accesible? is height difference low?)
                    local isSea = is_map_point_sea(util.to_coord2D(candidatePoint)) > 0
                    local isAccesible = true --- TODO, can we pathfind to this point?
                    local heightDifference = heightAtShamanPos - point_altitude(candidatePoint.Xpos, candidatePoint.Zpos)
                    
                    if (not isSea and isAccesible and heightDifference <= maxHeightDifference) then
                        -- Candidate is feasible
                        table.insert(candidateLocations, candidatePoint)
                    end
                    
                    -- Get another angle 90º clockwise
                    angle = frameworkMath.orthogonalAngle(angle)
                end
                
                local finalPosition = util.randomItemFromTable(candidateLocations)
                
                -- Set a move command to this location into the shaman's commands, if finalPosition is nil we couldnt find a location
                if (finalPosition ~= nil) then
                    local currentCommand = get_thing_curr_cmd_list_ptr(myShaman)
                    local idx = 0
                    if (currentCommand ~= nil) then
                        -- We have a command, we increase the index in order not to replace it
                        idx = idx + 1
                    else
                        -- If shaman is idle, dis-idle her
                        commands.reset_person_cmds(myShaman)
                    end
        
                    add_persons_command(myShaman, commands.cmd_goto(finalPosition), idx)
                    set_persons_next_command(myShaman) -- Tell the shaman to swap its current command with that of the dodge

                    -- After some time, delete this action of dodge and complete the original objective
                    subscribe_ExecuteOnTurn(GetTurn() + math.min(10, o.dodgeIntervalBetweenDodges-2), function ()
                        myShaman = getShaman(myTribe)
                        if (myShaman == nil) then
                            return
                        end
        
                        currentCommand = get_thing_curr_cmd_list_ptr(myShaman)
                        -- We check that we have not arrived yet to the dodge location
                        if (currentCommand ~= nil) then
                            local coords = currentCommand.u.TargetCoord
                            if (coords ~= nil and coords.Xpos == finalPosition.Xpos and coords.Zpos == finalPosition.Zpos ) then
                                set_persons_next_command(myShaman)
                                set_persons_command_complete(myShaman, 1)
                                -- This has a weird behaviour, in which the shaman appears to be idle, but is actually completing the previous task 
                            end
                        end
                    end)
                end
                
                -- Set a dodge delay and finish
                o.dodgeLastDodgeTurn = GetTurn()
            end)
        end
    end)
end

function AIShamanBehaviourDodge:enable()
    if (self.isEnabled) then
        return
    end
    self:setEnabled(true)
    performDodge(self)
end

function AIShamanBehaviourDodge:disable()
    if (not self.isEnabled) then
        return
    end
    self:setEnabled(false)
    unsubscribe_OnCreateThing(self.dodgeControllerSubscriptionIndex)
end
