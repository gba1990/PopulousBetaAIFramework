AIShamanBehaviourExpand = AIShamanBehaviour:new()

function AIShamanBehaviourExpand:new(o, expansionPoints)
    local o = o or AIShamanBehaviour:new()
    setmetatable(o, self)
    self.__index = self
    
    o.aiModuleShaman = nil
    o.expansionPoints = expansionPoints or {}
    o.expansionChooseInterval = 12

    -- Determines when an expansion must be interrupted (this function gets executed after casting 1 LB)
    -- Can be used to avoid wasting too much mana at one expansion, or perhaps because LB has bucket cooldown and we dont want the shaman to be idle near water and she is better doing something else
    -- Returns true when interruption must happen
    o.expandInterruptCondition = function() return false end
    
    o.currentExpansion = nil

    o:enable()
    return o
end

local function expand(o, expansionPoint)
    ---- ALGORITHM STRUCTURE
    -- If expansion complete return
    -- Check we can cast LB, else wait until we can
        -- Reach location
            -- Get points where it should be cast
                -- startPoint is as given
                -- endpoint is furthest point towards endpoint which is in range + 200 into the sea (so it is in water but near coast)
            -- Force cast out of range towards angle
                -- Leave some time for the shaman to reach sea border
            -- Cast LB
            -- If casted, update expansionPoint with an extra LB cast
            -- Wait some time
                -- Check for "expandInterruptCondition()"
                -- recursion

    ---- IMPLEMENTATION
    if (expansionPoint:isComplete()) then
        o.currentExpansion = nil
        return
    end

    if (not o.isEnabled) then
        o.currentExpansion = nil
        return
    end

    if (o.currentExpansion ~= expansionPoint) then
        -- We changed objective (weird but ok) we must stop this 
        return
    end

    -- Check we can cast LB, else wait until we can
    local canBeCasted = o.aiModuleShaman:couldSpellBeCasted(M_SPELL_LAND_BRIDGE)
    if (canBeCasted) then
        -- Reach location
        local startPoint, endPoint = expansionPoint:getNextPoints()
        util.commandPersonGoToPoint(getShaman(o.aiModuleShaman.ai:getTribe()), startPoint, 512, function (arrived)
            if (not o.isEnabled) then
                o.currentExpansion = nil
                return
            end

            if (o.currentExpansion ~= expansionPoint) then
                -- We changed objective (weird but ok) we must stop this 
                return
            end
            
            -- If shaman did not arrive call again (if still alive) perhaps she had no time to arrive
            if (not arrived) then
                if (getShaman(o.aiModuleShaman.ai:getTribe()) ~= nil) then
                    expand(o, expansionPoint)
                end
                return
            end
            -- Force cast out of range towards angle (Leave some time for the shaman to reach sea border)
            if (expansionPoint.angle ~= nil) then
                o.castOutOfRangeSubscriptionIndex = util.shamanGotoSpellCastPoint(o.aiModuleShaman.ai:getTribe(), frameworkMath.calculatePosition(startPoint, expansionPoint.angle, 1024))
            end
            
            o.subscriptionIndex = subscribe_ExecuteOnTurn(GetTurn() + 12, function ()
                local tempAngle = frameworkMath.angleBetweenPoints(startPoint, endPoint)
                endPoint = frameworkMath.calculatePosition(getShaman(o.aiModuleShaman.ai:getTribe()).Pos.D3, tempAngle, frameworkMath.calculateSpellRangeFromPosition(getShaman(o.aiModuleShaman.ai:getTribe()).Pos.D3, M_SPELL_LAND_BRIDGE, false))

                local distance = get_world_dist_xyz(util.to_coord3D(endPoint), getShaman(o.aiModuleShaman.ai:getTribe()).Pos.D3)
                commands.reset_person_cmds(getShaman(o.aiModuleShaman.ai:getTribe()))
                local thing = o.aiModuleShaman:castSpell(M_SPELL_LAND_BRIDGE, endPoint)
                if (thing ~= nil) then
                    expansionPoint.castedLBs = expansionPoint.castedLBs + 1
                    if (not o.expandInterruptCondition()) then
                        -- Wait some time so LB rises land
                        o.subscriptionIndex = subscribe_ExecuteOnTurn(GetTurn() + 24, function ()
                            expand(o, expansionPoint)
                        end)
                    else
                        o.currentExpansion = nil
                    end
                end
            end)
        end, 700) -- delta of 700 on commandPersonGoToPoint
    else
        -- Can not cast if no mana / no bucket / shaman dead
        -- It may not be possible to cast cause shaman is casting something else, but... is she under attack? why would she try to expand while under attack?
        o.subscriptionIndex = subscribe_ExecuteOnTurn(GetTurn() + 128, function ()
            expand(o, expansionPoint)
        end)
    end
end

function AIShamanBehaviourExpand:chooseExpansion()
    if (self.currentExpansion == nil) then
        for k, v in pairs(self.expansionPoints) do
            if (not v:isComplete()) then
                self.currentExpansion = v
                expand(self, v)
                break
            end
        end
    end

    self.expansionChooserSubscriptionIndex = subscribe_ExecuteOnTurn(GetTurn() + self.expansionChooseInterval, function ()
        self:chooseExpansion()
    end)
end

function AIShamanBehaviourExpand:enable()
    if (self.isEnabled) then
        return
    end
    self:setEnabled(true)
    self.expansionChooserSubscriptionIndex = subscribe_ExecuteOnTurn(GetTurn() + 12, function ()
        self:chooseExpansion()
    end)
end

function AIShamanBehaviourExpand:disable()
    if (not self.isEnabled) then
        return
    end
    self:setEnabled(false)
    unsubscribe_ExecuteOnTurn(self.subscriptionIndex)
    unsubscribe_ExecuteOnTurn(self.castOutOfRangeSubscriptionIndex)
    unsubscribe_ExecuteOnTurn(self.expansionChooserSubscriptionIndex)
    self.currentExpansion = nil -- This should stop any ongoing expansions in case the unsubscribe dont stop them
end
