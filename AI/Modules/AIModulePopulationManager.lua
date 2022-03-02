AIModulePopulationManager = AIModule:new()

local function initialiseTable()
    local result = {}

    result[M_PERSON_BRAVE] = {}
    result[M_PERSON_WARRIOR] = {}
    result[M_PERSON_RELIGIOUS] = {}
    result[M_PERSON_SPY] = {}
    result[M_PERSON_SUPER_WARRIOR] = {}

    return result
end

local function periodicIdlePeopleChecker(o)
    o.idlePeople = initialiseTable()

    ProcessGlobalSpecialList(o.ai:getTribe(), 0, function(thing)
        if (thing.Type == T_PERSON and thing.Model >= M_PERSON_BRAVE and thing.Model <= M_PERSON_SUPER_WARRIOR and thing.Owner == o.ai:getTribe()) then
            o:addPersonAsIdle(thing)
        end
        return true
    end)

    o.checkForIdlePeopleIntervalSubscriptionIndex = subscribe_ExecuteOnTurn(GetTurn() + o.checkForIdlePeopleInterval, function()
        periodicIdlePeopleChecker(o)
    end)
end

function AIModulePopulationManager:new(o, ai, gameTurnForInitialCheck)
    local o = o or AIModule:new()
    setmetatable(o, self)
    self.__index = self

    o.ai = ai
    o.idlePeople = initialiseTable()

    if (gameTurnForInitialCheck == nil) then
        gameTurnForInitialCheck = 24
    end

    o.checkForIdlePeople = true
    o.checkForIdlePeopleInterval = 128
    o.checkForIdlePeopleIntervalSubscriptionIndex = subscribe_ExecuteOnTurn(GetTurn() + gameTurnForInitialCheck + o.checkForIdlePeopleInterval, function()
        periodicIdlePeopleChecker(o)
    end)

    -- Start is set to 12 game turns, why? in order not to select FW which are placed on doors of towers or that ppl prepared to patrol
    o.checkForIdlePeopleAtEnable = true
    o.checkForIdlePeopleAtEnableSubscriptionIndex = subscribe_ExecuteOnTurn(GetTurn() + gameTurnForInitialCheck, function()
        ProcessGlobalSpecialList(o.ai:getTribe(), 0, function(thing)
            if (thing.Type == T_PERSON and thing.Model >= M_PERSON_BRAVE and thing.Model <= M_PERSON_SUPER_WARRIOR) then
                o:addPersonAsIdle(thing)
            end
            return true
        end)
    end)

    return o
end

local function getPeopleFromTable(t, amount, type, validPersonCheck)
    local result = {}
    local backup = {}

    for i = #t[type], 1, -1 do
        if (amount == 0) then
            break
        end
        
        local thing = t[type][i]
        local check1, checkBackup = validPersonCheck(thing)
        if (check1) then
            table.insert(result, thing)
            table.remove(t[type], i)
            amount = amount - 1
        elseif (checkBackup) then
            table.insert(backup, {t = thing, idx = i})
        end
    end
    
    for i = #backup, 1, -1 do
        if (amount == 0) then
            break
        end

        table.insert(result, backup[i].t)
        table.remove(t[type], backup[i].idx)
        amount = amount - 1
    end

    return result, t -- Returns the table of people and the remaining people which were not chosen
end

function AIModulePopulationManager:getIdlePeople(amount, type)
    return self:getPeople(amount, type, function (thing)
        --- TODO do other checks: person is idle or in hut, if on hut, place on pseudoidle list to select if no enough idle ppl were found
        return thing ~= nil and is_person_available_for_auto_employment(thing) > 0
    end)
end

function AIModulePopulationManager:getPeople(amount, type, criteria1, criteria2)
    criteria1 = criteria1 or function (thing)
        return true
    end
    
    criteria2 = criteria2 or function (thing)
        return false
    end

    local result, t = getPeopleFromTable(self.idlePeople, amount, type, function(thing)
        return criteria1(thing), criteria2(thing)
    end)

    self.idlePeople = t

    return result
end

function AIModulePopulationManager:addPersonAsIdle(thing)
    table.insert(self.idlePeople[thing.Model], thing)
end

function AIModulePopulationManager:doNotCheckForIdlePeopleAtEnable()
    self.checkForIdlePeopleAtEnable = false
    unsubscribe_ExecuteOnTurn(self.checkForIdlePeopleAtEnableSubscriptionIndex)
end