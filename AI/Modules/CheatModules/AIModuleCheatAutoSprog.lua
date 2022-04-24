AIModuleCheatAutoSprog = AIModule:new()

function AIModuleCheatAutoSprog:new(o, ai, numberOfBuildings)
    local o = o or AIModuleIntervalCheat:new()
    setmetatable(o, self)
    self.__index = self

    o.ai = ai
    o.affectedModels = {
        M_BUILDING_TEPEE,
        M_BUILDING_TEPEE_2,
        M_BUILDING_TEPEE_3
    }

    o.interval = 128
    o.numberOfBuildings = numberOfBuildings or -1 -- All buildings possible
    o.isBuildingValid = function(t) 
        return t ~= nil 
                and util.tableContains(o.affectedModels, t.Model) 
                and t.u.Bldg ~= nil 
                and t.State == S_BUILDING_STAND
                and t.u.Bldg.SproggingCount > 100 -- So builds that have just sprogged wont do it again
    end

    o:enable()
    return o
end

function AIModuleCheatAutoSprog:doCheat()
    local myTribe = self.ai:getTribe()
    local validThings = {}
    ProcessGlobalSpecialList(myTribe, BUILDINGLIST, function(thing)
        if (self.isBuildingValid(thing)) then
            table.insert(validThings, thing)
        end
        return true
    end)

    local sprogsMade = self.numberOfBuildings
    while (#validThings ~= 0 and sprogsMade ~= 0) do
        -- Select a random build and sprog it
        local thing, idx = util.randomItemFromTable(validThings)
        table.remove(validThings, idx)
        util.hutForceSprog(thing)
        sprogsMade = sprogsMade - 1
    end
end