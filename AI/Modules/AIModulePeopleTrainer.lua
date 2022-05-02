AIModulePeopleTrainer = AIModule:new()

function AIModulePeopleTrainer:new()
    local o = AIModule:new()
    setmetatable(o, self)
    self.__index = self

    o.maxTrainsPerIteration = 6 -- Maximun number of people sent to train per iteration
    o.interval = 512
    -- If we have < 20 braves, the iteration will stop. (No training will happen)
    o.iterationStopCondition = function() return PLAYERS_PEOPLE_OF_TYPE(o.ai:getTribe(), M_PERSON_BRAVE) < 20 end

    -- Determines chance of brave being trained to that type. Idealy, they should add up to 100
    -- if we have no demand of that follower type, this chance is overrided to 0%
    -- If all chances are 0, the iteration stops, as it is interpreted we have enough troopsof all types
    o.troopPrioritiesPercentage = {}
    o.troopPrioritiesPercentage[M_PERSON_SPY] = 10
    o.troopPrioritiesPercentage[M_PERSON_WARRIOR] = 30
    o.troopPrioritiesPercentage[M_PERSON_RELIGIOUS] = 30
    o.troopPrioritiesPercentage[M_PERSON_SUPER_WARRIOR] = 30

    -- A pairing to known where to train each kind of follower
    o.trainPairs = {}
    o.trainPairs[M_PERSON_SPY] = M_BUILDING_SPY_TRAIN
    o.trainPairs[M_PERSON_WARRIOR] = M_BUILDING_WARRIOR_TRAIN
    o.trainPairs[M_PERSON_RELIGIOUS] = M_BUILDING_TEMPLE
    o.trainPairs[M_PERSON_SUPER_WARRIOR] = M_BUILDING_SUPER_TRAIN

    return o
end

local function determineAmountOfTrainsPerModel(tribe)
    local amountsPerModel = {}
    -- Number of preffered specilists: bounded [0, inf)
    amountsPerModel[M_PERSON_SPY] = math.max(0, READ_CP_ATTRIB(tribe, ATTR_PREF_SPY_PEOPLE) - PLAYERS_PEOPLE_OF_TYPE(tribe, M_PERSON_SPY))
    amountsPerModel[M_PERSON_WARRIOR] = math.max(0, READ_CP_ATTRIB(tribe, ATTR_PREF_WARRIOR_PEOPLE) - PLAYERS_PEOPLE_OF_TYPE(tribe, M_PERSON_WARRIOR))
    amountsPerModel[M_PERSON_RELIGIOUS] = math.max(0, READ_CP_ATTRIB(tribe, ATTR_PREF_RELIGIOUS_PEOPLE) - PLAYERS_PEOPLE_OF_TYPE(tribe, M_PERSON_RELIGIOUS))
    amountsPerModel[M_PERSON_SUPER_WARRIOR] = math.max(0, READ_CP_ATTRIB(tribe, ATTR_PREF_SUPER_WARRIOR_PEOPLE) - PLAYERS_PEOPLE_OF_TYPE(tribe, M_PERSON_SUPER_WARRIOR))

    -- Now, if we have no train hut, we set to 0 too
    amountsPerModel[M_PERSON_SPY] = amountsPerModel[M_PERSON_SPY] * math.min(1, PLAYERS_BUILDING_OF_TYPE(tribe, M_BUILDING_SPY_TRAIN))
    amountsPerModel[M_PERSON_WARRIOR] = amountsPerModel[M_PERSON_WARRIOR] * math.min(1, PLAYERS_BUILDING_OF_TYPE(tribe, M_BUILDING_WARRIOR_TRAIN))
    amountsPerModel[M_PERSON_RELIGIOUS] = amountsPerModel[M_PERSON_RELIGIOUS] * math.min(1, PLAYERS_BUILDING_OF_TYPE(tribe, M_BUILDING_TEMPLE))
    amountsPerModel[M_PERSON_SUPER_WARRIOR] = amountsPerModel[M_PERSON_SUPER_WARRIOR] * math.min(1, PLAYERS_BUILDING_OF_TYPE(tribe, M_BUILDING_SUPER_TRAIN))

    -- We dont take into account the people that are already training, which may lead into higher amounts of followers of that type, or many braves being trained
    return amountsPerModel
end

-- From Kosjak, ty <3
function AIModulePeopleTrainer:TrainPeopleFromTableAndBuildingModel(t_braves, bldgModel)
    if (#t_braves == 0) then return end
    
    local t_trains = {}
    ProcessGlobalSpecialList(self.ai:getTribe(), BUILDINGLIST, function(t)
        if (t.Model == bldgModel) then
            if (t.u.Bldg.ShapeThingIdx:isNull()) then
                table.insert(t_trains, t)
                return true
            end
        end
        return true
    end)

    if (#t_trains > 0) then
        t_trains = util.shuffle(t_trains) -- If not, the first train gets more people (as perhaps we sometimes only train 1 person)
        local split = math.floor(#t_braves / #t_trains)
        local remainder = #t_braves % #t_trains
        local idx = 1
        for k, t_thing in pairs(t_braves) do
            util.gotoTrain(t_thing, t_trains[idx])
            idx = (idx + 1) % #t_trains
            if (idx == 0) then
                idx = #t_trains
            end
            t_thing = nil
        end
    end
end

function AIModulePeopleTrainer:TrainPeopleFromTable(tableOfPeople, model)
    self:TrainPeopleFromTableAndBuildingModel(tableOfPeople, self.trainPairs[model])
end

function AIModulePeopleTrainer:TrainPeople(amount, model)
    local tribe = self.ai:getTribe()

    -- Get Idle/InHut braves
    local populationManager = self.ai:getModule(AI_MODULE_POPULATION_MANAGER_ID)
    local t_braves = populationManager:getIdlePeople(amount, M_PERSON_BRAVE)

    self:TrainPeopleFromTableAndBuildingModel(t_braves, self.trainPairs[model])
end

function AIModulePeopleTrainer:AutoTrainPeople()
    -- If stop condition is true, we skip iteration
    if (self.iterationStopCondition()) then return end

    local tribe = self.ai:getTribe()

    -- Get Idle/InHut braves
    local populationManager = self.ai:getModule(AI_MODULE_POPULATION_MANAGER_ID)
    local t_braves = populationManager:getIdlePeople(self.maxTrainsPerIteration, M_PERSON_BRAVE)
    
    -- Determine people which are needed for each model, 0 if we have no train bldg for that model
    local amountsPerModel = determineAmountOfTrainsPerModel(tribe)

    -- Which person is sent where
    local result = {}
    result[M_PERSON_SPY] = {}
    result[M_PERSON_WARRIOR] = {}
    result[M_PERSON_RELIGIOUS] = {}
    result[M_PERSON_SUPER_WARRIOR] = {}
    
    local percentages = {}
    percentages[1] = {model = M_PERSON_SPY, chance = self.troopPrioritiesPercentage[M_PERSON_SPY]}
    percentages[2] = {model = M_PERSON_WARRIOR, chance = self.troopPrioritiesPercentage[M_PERSON_WARRIOR]}
    percentages[3] = {model = M_PERSON_RELIGIOUS, chance = self.troopPrioritiesPercentage[M_PERSON_RELIGIOUS]}
    percentages[4] = {model = M_PERSON_SUPER_WARRIOR, chance = self.troopPrioritiesPercentage[M_PERSON_SUPER_WARRIOR]}
    percentages = util.shuffle(percentages)
    
    --- TODO: Sometimes not all braves are sent to train (eg: if spies are not required and are at the end of the percentages list)
    for k, brave in pairs(t_braves) do
        local accumChance = 0
        for k, entry in pairs(percentages) do
            local m = entry.model
            accumChance = accumChance + entry.chance

            if (amountsPerModel[m] > 0 and math.random(0,99) < accumChance) then
                amountsPerModel[m] = amountsPerModel[m] - 1 -- We send a brave to that model
                table.insert(result[m], brave)
                logger.msgLog("Brave to %s", m)
                break -- Next brave please
            end
        end
    end

    -- All clasified -> Send people to the train huts
    for k, v in pairs(self.trainPairs) do
        self:TrainPeopleFromTableAndBuildingModel(result[k], v)
    end
end

local function caller(o)
    o:AutoTrainPeople()
    o.subscriptionIndex = subscribe_ExecuteOnTurn(GetTurn() + o.interval, function ()
        caller(o)
    end)
end

function AIModulePeopleTrainer:enable()
    if (self.isEnabled) then
        return
    end
    self:setEnabled(true)
    self.subscriptionIndex = subscribe_ExecuteOnTurn(GetTurn() + 120, function (thing)
        caller(self)
    end)
end

function AIModulePeopleTrainer:disable()
    if (not self.isEnabled) then
        return
    end
    self:setEnabled(false)
    unsubscribe_ExecuteOnTurn(self.subscriptionIndex)
end