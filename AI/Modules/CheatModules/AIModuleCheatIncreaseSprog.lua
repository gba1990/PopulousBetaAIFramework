AIModuleCheatIncreaseSprog = AIModule:new() -- Cannot instantiate AIModuleIntervalCheat here, gave an error for no parameters were given

function AIModuleCheatIncreaseSprog:new(o, ai)
    local o = o or AIModuleIntervalCheat:new()
    setmetatable(o, self)
    self.__index = self

    o.ai = ai
    o.affectedModels = {
        M_BUILDING_TEPEE,
        M_BUILDING_TEPEE_2,
        M_BUILDING_TEPEE_3
    }

    o.isBuildingValid = function(t) 
        return t ~= nil 
                and util.tableContains(o.affectedModels, t.Model) 
                and t.u.Bldg ~= nil 
                and t.State ~= S_BUILDING_UNDER_CONSTRUCTION 
    end

    o:enable()
    return o
end

function AIModuleCheatIncreaseSprog:doCheat()
    local myTribe = self.ai:getTribe()
    ProcessGlobalSpecialList(myTribe, BUILDINGLIST, function(thing)
        if (self.isBuildingValid(thing)) then
            thing.u.Bldg.SproggingCount = thing.u.Bldg.SproggingCount + self.increaseAmount
        end
        return true
    end)
end