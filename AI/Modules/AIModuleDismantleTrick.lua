AIModuleDismantleTrick = AIModule:new()

function AIModuleDismantleTrick:new()
    local o = AIModule:new()
    setmetatable(o, self)
    self.__index = self

    o.dismantleInterval = 180 -- Every how many turns check for huts to dismantle
    o.dismantleMaxNumberOfHuts = 3 -- Maximun number of huts being dismantled on the same iteration
    o.dismantleStopOnPopulationOver = 700 -- When to stop the dismantle based on population

    o.sproggingCountThreshold = 700 -- Max value of sprog for the hut to be considered (a higher value of sprog will make the hut not feasible for dismantle trick)
    o.upgradeCountThreshold = 700 -- Max value of upgrade for the hut to be considered
    o.modelsToCheckForDismantle = {M_BUILDING_TEPEE} -- Determines which type of hut can be dismantled
    
    return o
end

local function dismantleTrick(o)
    o.dismantleSubscriberIndex = subscribe_ExecuteOnTurn(GetTurn() + o.dismantleInterval, function()
        dismantleTrick(o)
    end)

    if (GET_NUM_PEOPLE(o.ai:getTribe()) >= o.dismantleStopOnPopulationOver) then
        return
    end

    local myTribe = o.ai:getTribe()
    local maxBuildingsThatCanBeDismantled = math.min(o.dismantleMaxNumberOfHuts, 
                                        math.floor((util.getMaxPopulationOfTribe(myTribe) - getPlayer(myTribe).NumPeople)/3))

    if (maxBuildingsThatCanBeDismantled <= 0) then
        return
    end

    local huts = {}
    ProcessGlobalSpecialList(myTribe, BUILDINGLIST, function(thing)

        -- Check if the building is feasible
        if (util.tableContains(o.modelsToCheckForDismantle, thing.Model)
                and thing.State == S_BUILDING_STAND
                and not util.isMarkedAsDismantle(thing) 
                and thing.u.Bldg.SproggingCount < o.sproggingCountThreshold 
                and thing.u.Bldg.UpgradeCount < o.upgradeCountThreshold
            ) then
            
            local dwellers = thing.u.Bldg.Dwellers
            -- We only dismantle huts which already have a brave
            for k, v in pairs(dwellers) do
                local person = v:get()
                if (person ~= nil and person.Model == M_PERSON_BRAVE) then
                    table.insert(huts, {hut = thing, brave = person})

                    maxBuildingsThatCanBeDismantled = maxBuildingsThatCanBeDismantled -1
                    if (maxBuildingsThatCanBeDismantled <= 0) then
                        return false
                    end
                end
            end
        end

        return true
    end)
    
    -- Dismantle all found huts
    for k, v in pairs(huts) do
        util.markBuildingToDismantle(v.hut, true)
        util.sendPersonToDismantle(v.brave, v.hut)
        
        -- Rebuild after 5 secs (enough time for them to have been taken down a layer)
        local subs,turn = nil, GetTurn()
        subs = subscribe_OnTurn(function()
            -- Check, in case it was fully dismantled by accident
            if (v.hut ~= nil and v.hut.u.Bldg ~= nil and v.hut.State == S_BUILDING_UNDER_CONSTRUCTION) then
                local sentSomeone = false
                unsubscribe_OnTurn(subs)
                util.markBuildingToDismantle(v.hut, false) -- Unmark as dismantle
                ProcessGlobalSpecialList(myTribe, 0, function(person)
                    if (util.isPersonDismantlingBuilding(person, v.hut)) then
                        -- Send everyone who is dismantling this building to build it back
                        if (sentSomeone) then
                            commands.reset_person_cmds(person)
                        else
                            util.sendPersonToBuild(person, v.hut)
                            sentSomeone = true
                        end
                    end
                    return true
                end)
            elseif (GetTurn() > turn + 100) then
                 -- It took too long to dismantle, perhaps the building got destroyed or something else
                if (v.hut ~= nil and v.hut.u.Bldg ~= nil) then
                    util.markBuildingToDismantle(v.hut, false)
                end
                unsubscribe_OnTurn(subs)
            end
        end)
    end
end

function AIModuleDismantleTrick:dontDoDismantleTrick()
    unsubscribe_ExecuteOnTurn(self.dismantleSubscriberIndex)
end

function AIModuleDismantleTrick:doDismantleTrick()
    self.dismantleSubscriberIndex = subscribe_ExecuteOnTurn(GetTurn() + self.dismantleInterval, function()
        dismantleTrick(self)
    end)
end

function AIModuleDismantleTrick:enable()
    if (self.isEnabled) then
        return
    end
    self:setEnabled(true)
    self:doDismantleTrick()
end

function AIModuleDismantleTrick:disable()
    if (not self.isEnabled) then
        return
    end
    self:setEnabled(true)
    self:dontDoDismantleTrick()
end
