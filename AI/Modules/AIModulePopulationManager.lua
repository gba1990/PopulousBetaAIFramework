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
    o.people = initialiseTable()

    ProcessGlobalSpecialList(o.ai:getTribe(), 0, function(thing)
        if (thing.Type == T_PERSON and thing.Model >= M_PERSON_BRAVE and thing.Model <= M_PERSON_SUPER_WARRIOR) then
            table.insert(o.people[thing.Model], thing)
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
    o.people = initialiseTable()
    o.pseudoIdlePeople = initialiseTable()
    o.pseudoIdleTimeout = 720

    if (gameTurnForInitialCheck == nil) then
        gameTurnForInitialCheck = 1
    end

    o.checkForIdlePeople = true
    o.checkForIdlePeopleInterval = 12 -- Actually this checks for new people and removes dead ones
    o.checkForIdlePeopleIntervalSubscriptionIndex = subscribe_ExecuteOnTurn(GetTurn() + gameTurnForInitialCheck + o.checkForIdlePeopleInterval, function()
        periodicIdlePeopleChecker(o)
    end)

    -- Start is set to 12 game turns, why? in order not to select FW which are placed on doors of towers or that ppl prepared to patrol
    o.checkForIdlePeopleAtEnable = true
    o.checkForIdlePeopleAtEnableSubscriptionIndex = subscribe_ExecuteOnTurn(GetTurn() + gameTurnForInitialCheck, function()
        ProcessGlobalSpecialList(o.ai:getTribe(), 0, function(thing)
            if (thing.Type == T_PERSON and thing.Model >= M_PERSON_BRAVE and thing.Model <= M_PERSON_SUPER_WARRIOR) then
                table.insert(o.people[thing.Model], thing)
            end
            return true
        end)
    end)

    return o
end

local function getPeopleFromTable(o, t, amount, type, validPersonCheck)
    local result = {}
    local backup = {}

    for i = 1, #t[type], 1 do
        if (amount == 0) then
            break
        end
        
        local thing = t[type][i]
        local check1, checkBackup = validPersonCheck(thing)
        if (check1) then
            table.insert(result, thing)
            amount = amount - 1
        elseif (checkBackup) then
            table.insert(backup, {t = thing, idx = i})
        end
    end
    
    for i = 1, #backup, 1 do
        if (amount == 0) then
            break
        end

        table.insert(result, backup[i].t)
        amount = amount - 1
    end

    for k, v in pairs(result) do
        o:removePersonAsPseudoIdle(v)
    end

    return result
end

function AIModulePopulationManager:getIdlePeople(amount, type)
    return self:getPeople(amount, type, function (thing)
        return thing ~= nil and is_person_available_for_auto_employment(thing) > 0
    end, function (thing)
        -- People marked as pseudoidle have a 33% chance to be selected
        -- (this is to avoid selecting too many people who were doing kinda useful chores)
        local psudoidle = self:isPersonPseudoIdle(thing) and math.random(0,2) == 0
        local inHut = util.isPersonInHut(thing) and math.random(0,1) == 0
        return thing ~= nil and (psudoidle or inHut)
    end)
end

function AIModulePopulationManager:getPeople(amount, type, criteria1, criteria2)
    criteria1 = criteria1 or function (thing)
        return true
    end
    
    criteria2 = criteria2 or function (thing)
        return false
    end

    local result = getPeopleFromTable(self, self.people, amount, type, function(thing)
        return criteria1(thing), criteria2(thing)
    end)

    return result
end

function AIModulePopulationManager:isPersonPseudoIdle(thing)
    if (self.pseudoIdlePeople[thing.Model] == nil) then
        log(string.format("self.pseudoIdlePeople[thing.Model] is %s", self.pseudoIdlePeople[thing.Model]))
        log(string.format("For model %s", thing.Model))
        return false
    end

    for k, v in pairs(self.pseudoIdlePeople[thing.Model]) do --- TODO: bad argument for iterator, table expected got nil (happens when people die?)
        if (v.thingNum == thing.ThingNum and v.timeout > GetTurn()) then
            return true
        end
    end
    return false
end

function AIModulePopulationManager:addPersonAsPseudoIdle(personThing, timeout)
    if (not self:isPersonPseudoIdle(personThing)) then
        timeout = timeout or self.pseudoIdleTimeout
        table.insert(self.pseudoIdlePeople[personThing.Model], {thing = personThing, thingNum = personThing.ThingNum, timeout = GetTurn() + timeout})
    end
end

function AIModulePopulationManager:removePersonAsPseudoIdle(personThing)
    for i = 1, #self.pseudoIdlePeople[personThing.Model], 1 do
        local current = self.pseudoIdlePeople[personThing.Model][i]
        if (current.thingNum == personThing.ThingNum) then
            table.remove(self.pseudoIdlePeople[personThing.Model], i)
            return
        end
    end
end

function AIModulePopulationManager:doNotCheckForIdlePeopleAtEnable()
    self.checkForIdlePeopleAtEnable = false
    unsubscribe_ExecuteOnTurn(self.checkForIdlePeopleAtEnableSubscriptionIndex)
end

function AIModulePopulationManager:enable()
    if (self.isEnabled) then
        return
    end
    self:setEnabled(true)

    if (self.checkForIdlePeopleAtEnable) then
        self.checkForIdlePeopleAtEnableSubscriptionIndex = subscribe_ExecuteOnTurn(GetTurn(), function()
            ProcessGlobalSpecialList(self.ai:getTribe(), 0, function(thing)
                if (thing.Type == T_PERSON and thing.Model >= M_PERSON_BRAVE and thing.Model <= M_PERSON_SUPER_WARRIOR) then
                    table.insert(self.people[thing.Model], thing)
                end
                return true
            end)
        end)
    end
    self.checkForIdlePeopleIntervalSubscriptionIndex = subscribe_ExecuteOnTurn(GetTurn() + self.checkForIdlePeopleInterval, function()
        periodicIdlePeopleChecker(self)
    end)
end

function AIModulePopulationManager:disable()
    if (not self.isEnabled) then
        return
    end
    self:setEnabled(false)
    unsubscribe_ExecuteOnTurn(self.checkForIdlePeopleAtEnableSubscriptionIndex)
    unsubscribe_ExecuteOnTurn(self.checkForIdlePeopleIntervalSubscriptionIndex)
end