AIModulePopulationManager = AIModule:new()


function AIModulePopulationManager:new(o, ai)
    local o = o or AIModule:new()
    setmetatable(o, self)
    self.__index = self

    o.ai = ai
    o.idlePeople = {}

    o.idlePeople[M_PERSON_BRAVE] = {}
    o.idlePeople[M_PERSON_WARRIOR] = {}
    o.idlePeople[M_PERSON_RELIGIOUS] = {}
    o.idlePeople[M_PERSON_SPY] = {}
    o.idlePeople[M_PERSON_SUPER_WARRIOR] = {}

    o.checkForIdlePeople = true
    o.checkForIdlePeopleInterval = 128

    -- Start is set to 12 game turns, why? in order not to select FW which are placed on doors of towers or that ppl prepared to patrol
    o.checkForIdlePeopleAtEnable = true
    o.checkForIdlePeopleAtEnableSubscriptionIndex = subscribe_ExecuteOnTurn(24, function()
        ProcessGlobalSpecialList(o.ai:getTribe(), 0, function(thing)
            if (thing.Type == T_PERSON and thing.Model >= M_PERSON_BRAVE and thing.Model <= M_PERSON_SUPER_WARRIOR) then
                o:addPersonAsIdle(thing)
            end
            return true
        end)
    end)

    return o
end


function AIModulePopulationManager:getIdlePeople(amount, type)
    local result = {}
    local backup = {}

    for i = #self.idlePeople[type], 1, -1 do
        if (amount == 0) then
            break
        end
        
        local thing = self.idlePeople[type][i]
        if (thing ~= nil) then
            --- TODO do other checks: person is idle or in hut, if on hut, place on backup list to select if no enough idle ppl were found
            table.insert(result, thing)
            table.remove(self.idlePeople[type], i)
            amount = amount - 1
        end
    end

    return result
end

-- TODO
function AIModulePopulationManager:getPeople(amount, type)
    --return self:getIdlePeople(amount, type)
end

function AIModulePopulationManager:addPersonAsIdle(thing)
    table.insert(self.idlePeople[thing.Model], thing)
end

function AIModulePopulationManager:doNotCheckForIdlePeopleAtEnable()
    self.checkForIdlePeopleAtEnable = false
    unsubscribe_ExecuteOnTurn(self.checkForIdlePeopleAtEnableSubscriptionIndex)
end