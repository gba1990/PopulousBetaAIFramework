AIShamanBehaviourConvert = AIShamanBehaviour:new()

function AIShamanBehaviourConvert:new(o)
    local o = o or AIShamanBehaviour:new()
    setmetatable(o, self)
    self.__index = self
    
    o.aiModuleShaman = nil
    o.allWildmen = {}
    
    o:enable()
    return o
end

-- From War of the gods
function AIShamanBehaviourConvert:convertNearWildmen()
    local wildmenIndex = 1
    for i = 1, #self.allWildmen, 1 do
      if (wildmenIndex <= #self.allWildmen) then
        local t = GetThing(self.allWildmen[wildmenIndex].ThingNum)
        if (t ~= nil and t.Type == T_PERSON and t.Model == M_PERSON_WILD) then
            local s = getShaman(self.aiModuleShaman.ai:getTribe())
            if (s ~= nil) then
                if(get_world_dist_xyz(t.Pos.D3, s.Pos.D3) <= frameworkMath.calculateSpellRangeFromPosition(s.Pos.D2, M_SPELL_CONVERT_WILD, false)) then
                    self.aiModuleShaman:castSpell(M_SPELL_CONVERT_WILD, t.Pos.D3)
                elseif(get_world_dist_xyz(t.Pos.D3, s.Pos.D3) < 512*16 and get_thing_curr_cmd_list_ptr(s) == nil) then
                    command_person_go_to_coord2d(s, t.Pos.D2)
                end
            end
        else
            table.remove(self.allWildmen, wildmenIndex)
        end
        wildmenIndex = wildmenIndex+1
      end
    end
end

local function convertNearWildmenInvoker(o)
    o:convertNearWildmen()
    o.convertingSubscriberIndex = subscribe_ExecuteOnTurn(GetTurn()+64, function()
        convertNearWildmenInvoker(o)
    end)
end

function AIShamanBehaviourConvert:enable()
    if (self.isEnabled) then
        return
    end
    self:setEnabled(true)
    self.allWildmen = {}
    ProcessGlobalTypeList(T_PERSON, function(t)
        if (t.Model == M_PERSON_WILD) then
            table.insert(self.allWildmen, t)
        end
        return true
    end)
    self.newWildmenSubscriberIndex = subscribe_OnCreateThing(function (t)
        if (t.Type == T_PERSON and t.Model == M_PERSON_WILD) then
            table.insert(self.allWildmen, t)
        end
    end)
    self.convertingSubscriberIndex = subscribe_ExecuteOnTurn(GetTurn()+64, function()
        convertNearWildmenInvoker(self)
    end)
end

function AIShamanBehaviourConvert:disable()
    if (not self.isEnabled) then
        return
    end
    self:setEnabled(false)
    unsubscribe_ExecuteOnTurn(self.convertingSubscriberIndex)
    unsubscribe_OnCreateThing(self.newWildmenSubscriberIndex)
end
