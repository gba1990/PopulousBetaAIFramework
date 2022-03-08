handlerFunctions = {}

----- Shaman dodge -----
local function AIShamanDodgeController_Disabled(o)
    
end

-- This approach checks for all shamans to see if there is one that is casting near my shaman
local function AIShamanDodgeController_Default(o)

    local dodgeCheckTurnInterval = 4 -- Every dodgeCheckTurnInterval gameturns, the shaman checks if it needs to dodge (it gives some delay to the dodge as it does not happen on every turn)
    o.dodgeControllerSubscriptionIndex = subscribe_ExecuteOnTurn(GetTurn() + dodgeCheckTurnInterval, function ()
        AIShamanDodgeController_Default(o)
    end)

    local myTribe = o.ai:getTribe()
    local myShaman = getShaman(myTribe)

    -- If shaman is dead nothing to dodge or we have recently dodged
    if (myShaman == nil or o.dodgeIntervalBetweenDodges >= GetTurn() - o.dodgeLastDodgeTurn) then
        return
    end

    -- Handle the dodge
    if (math.random(0, 99) < o.dodgePercentChance) then
        for i = TRIBE_BLUE, TRIBE_ORANGE, 1 do
            local enemyShaman = getShaman(i)
            -- We are allied or enemy hs no shaman -> skip tribe
            if (myTribe == i or are_players_allied(o.ai:getTribe(), i) > 0 or enemyShaman == nil) then
                goto AIShamanDodgeController_Default_skip
            end

            -- Check enemy shaman if they are casting something
            if (util.isShamanCasting(enemyShaman)) then
                -- Check if they are in range for light (we dodge blast & lights)
                local distance = get_world_dist_xz(myShaman.Pos.D2, enemyShaman.Pos.D2)
                local lightRange = frameworkMath.calculateSpellRangeFromPosition(enemyShaman.Pos.D2, M_SPELL_LIGHTNING_BOLT, false) * 1.2 --- TODO: repair range function to remove this extra security range
                if (distance <= lightRange) then
                    -- Perform dodge:

                    -- Find a closeby location
                    local angle = math.random(0, frameworkMath.INGAME_ANGLE_MAX)
                    local heightAtShamanPos = point_altitude(myShaman.Pos.D2.Xpos, myShaman.Pos.D2.Zpos)
                    local moveDistance = 1000 -- How far shaman will dodge
                    local maxHeightDifference = 256 -- How much can the shaman climb
                    local candidateLocations = {} -- Random possible locations
                    for i = 1, 4, 1 do
                        local candidatePoint = frameworkMath.calculatePosition(myShaman.Pos.D2, angle, moveDistance)
                        logger.pointLog(candidatePoint)
                        
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
                        command_person_go_to_coord2d(myShaman, util.to_coord2D(finalPosition))
                        -- And move a bit later, the shaman to its previously intended location
                        subscribe_ExecuteOnTurn(GetTurn() + 12, function()
                            if (currentCommand ~= nil and myShaman ~= nil) then
                                commands.reset_person_cmds(myShaman)
                                add_persons_command(myShaman, currentCommand, 0)
                            end
                        end)
                    end

                    -- Set a dodge delay and finish
                    o.dodgeLastDodgeTurn = GetTurn()
                    return
                end
            end
            
            ::AIShamanDodgeController_Default_skip::
        end
    end
end

-- This approach checks if a casted light/blast is targeted near my shaman (in theory it is more efficient than the AIShamanDodgeController_Default)
local function AIShamanDodgeController_UsingOnCreateThing(o)
    o.dodgeControllerSubscriptionIndex = subscribe_OnCreateThing(function (spell)
        -- First we check if it is a spell and if the dodge % allows us to dodge
        if (spell.Type == T_SPELL and math.random(0, 99) < o.dodgePercentChance) then
            local myTribe = o.ai:getTribe()
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
                    logger.pointLog(candidatePoint)
                    
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
                    command_person_go_to_coord2d(myShaman, util.to_coord2D(finalPosition))
                    -- And move a bit later, the shaman to its previously intended location
                    subscribe_ExecuteOnTurn(GetTurn() + 10, function()
                        if (currentCommand ~= nil and getShaman(myTribe) ~= nil) then
                            commands.reset_person_cmds(myShaman)
                            add_persons_command(myShaman, currentCommand, 0)
                        end
                    end)
                end
                
                -- Set a dodge delay and finish
                o.dodgeLastDodgeTurn = GetTurn()
            end)
        end
    end)
end

handlerFunctions.AIShamanDodgeController = {}
handlerFunctions.AIShamanDodgeController.disabled = AIShamanDodgeController_Disabled
handlerFunctions.AIShamanDodgeController.default = AIShamanDodgeController_Default
handlerFunctions.AIShamanDodgeController.usingOnCreateThing = AIShamanDodgeController_UsingOnCreateThing






-- Handlers for when plans are placed
local function selectTree(treeIndex, treeThings, bravesSentToThatTree)
    local candidateTree = treeThings[treeIndex]
    if (candidateTree == nil) then
        return nil, treeIndex, 0 -- We reached the last tree
    end

    local woodOnTree = treeThings[treeIndex].u.Scenery.ResourceRemaining - 100 * bravesSentToThatTree
    if (woodOnTree >= 200) then
        return candidateTree, treeIndex, bravesSentToThatTree + 1
    end

    -- Less wood, then, call again but for the next tree
    return selectTree(treeIndex + 1, treeThings, 0)
end

local function OnPlacedPlanHandler_DoNothing(o ,plan)
end

local function OnPlacedPlanHandler_HarvestAndSendPeople(o, plan)
    local numBraves = o.peoplePerPlanArray[plan.u.Shape.BldgModel] or o.fallBackPeoplePerPlan

    local braves = o.ai.populationManager:getIdlePeople(numBraves, M_PERSON_BRAVE)
    local treeThings = nil
    if (o.harvestBeforeBuilding) then
        treeThings = o.ai.treeManager:getTreesWithWoodInArea(200, plan.Pos.D3, 10000)
    end

    local treeIndex = 1
    local treeThing = nil
    local bravesSentToThatTree = 0
    for i = 1, #braves, 1 do
        treeThing, treeIndex, bravesSentToThatTree = selectTree(treeIndex, treeThings, bravesSentToThatTree)
        util.sendPersonToBuild(braves[i], plan, treeThing)
        if (treeThing ~= nil) then
            o.ai.treeManager:reduceWoodOfTree(treeThing, 100) -- We will cut down 1 wood from that tree
        end
    end
end

local function OnPlacedPlanHandler_HarvestAndSendPeopleWithPseudoIdleExtraPeople(o, plan)
    local numBraves = o.peoplePerPlanArray[plan.u.Shape.BldgModel] or o.fallBackPeoplePerPlan
    numBraves = numBraves + o.fallBackPeoplePerPlan

    local braves = o.ai.populationManager:getIdlePeople(numBraves, M_PERSON_BRAVE)
    local treeThings = nil
    if (o.harvestBeforeBuilding) then
        treeThings = o.ai.treeManager:getTreesWithWoodInArea(200, plan.Pos.D3, 10000)
    end

    local treeIndex = 1
    local treeThing = nil
    local bravesSentToThatTree = 0
    for i = 1, #braves, 1 do
        treeThing, treeIndex, bravesSentToThatTree = selectTree(treeIndex, treeThings, bravesSentToThatTree)
        util.sendPersonToBuild(braves[i], plan, treeThing)
        if (i > numBraves - o.fallBackPeoplePerPlan) then
            o.ai.populationManager:addPersonAsPseudoIdle(braves[i])
        end
        if (treeThing ~= nil) then
            o.ai.treeManager:reduceWoodOfTree(treeThing, 100) -- We will cut down 1 wood from that tree
        end
    end
end

handlerFunctions.OnPlacedPlanHandler = {}
handlerFunctions.OnPlacedPlanHandler.doNothing = OnPlacedPlanHandler_DoNothing
handlerFunctions.OnPlacedPlanHandler.harvestAndSendPeople = OnPlacedPlanHandler_HarvestAndSendPeople
handlerFunctions.OnPlacedPlanHandler.harvestAndSendPeopleWithPseudoIdleExtraPeople = OnPlacedPlanHandler_HarvestAndSendPeopleWithPseudoIdleExtraPeople