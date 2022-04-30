AIModulePopulateDrumTowers = AIModule:new()

function AIModulePopulateDrumTowers:new(o, ai, personModel)
    local o = o or AIModule:new()
    setmetatable(o, self)
    self.__index = self

    o.ai = ai
    o.personModel = personModel or M_PERSON_SUPER_WARRIOR -- FWs will fill empty towers
    o.maxRepopulationPerIteration = 15 -- Maximun number of towers to repopulate per iteration
    o.interval = 720

    o:enable()
    return o
end

-- From Kosjak, ty <3
function AIModulePopulateDrumTowers:PopulateDrumTowers()
    logger.msgLog("Called")
    local tribe = self.ai:getTribe()

    -- Get Idle/InHut FWs
    local populationManager = self.ai:getModule(AI_MODULE_POPULATION_MANAGER_ID)
    local t_firewarriors = populationManager:getIdlePeople(self.maxRepopulationPerIteration, self.personModel)

    -- Get Empty Towers
    local t_empty_towers = {}
    ProcessGlobalSpecialList(tribe, BUILDINGLIST, function(b)
        if (b.Model == M_BUILDING_DRUM_TOWER) then
            if (b.State == S_BUILDING_STAND) then
                if (b.u.Bldg.Dwellers[0]:isNull()) then
                    table.insert(t_empty_towers, b)
                end
            end
        end
        return true
    end)

    -- We dont shuffle FWs cause the first ones in the list are the ones that were idle (the others where perhaps in huts)
    t_empty_towers = util.shuffle(t_empty_towers)
    
    for i, tower in pairs(t_empty_towers) do
        if (#t_firewarriors <= 0) then
            break -- No more FW, we stop
        end

        util.gotoBuilding(t_firewarriors[1], tower)
        table.remove(t_firewarriors, 1)
    end
end

local function caller(o)
    o:PopulateDrumTowers()
    o.subscriptionIndex = subscribe_ExecuteOnTurn(GetTurn() + o.interval, function ()
        caller(o)
    end)
end

function AIModulePopulateDrumTowers:enable()
    if (self.isEnabled) then
        return
    end
    self:setEnabled(true)
    self.subscriptionIndex = subscribe_ExecuteOnTurn(GetTurn() + 100, function (thing)
        caller(self)
    end)
end

function AIModulePopulateDrumTowers:disable()
    if (not self.isEnabled) then
        return
    end
    self:setEnabled(false)
    unsubscribe_ExecuteOnTurn(self.subscriptionIndex)
end