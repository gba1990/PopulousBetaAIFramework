AIShamanBehaviourConvertInArea = AIShamanBehaviour:new()

function AIShamanBehaviourConvertInArea:new(center, radius, shamanGoToPoint)
    local o = AIShamanBehaviour:new()
    setmetatable(o, self)
    self.__index = self
    
    o.center = util.to_coord2D(center)
    o.radius = radius
    o.shamanGoToPoint = shamanGoToPoint
    o.aiModuleShaman = nil
    o.wildmenInArea = {}
    o.wildmanConvertInterval = 32
    
    o:enable()
    return o
end

-- From War of the gods
function AIShamanBehaviourConvertInArea:convertWildmen()
    self:checkWildmenInArea()

    local wildmenIndex = 1
    for i = 1, #self.wildmenInArea, 1 do
      if (wildmenIndex <= #self.wildmenInArea) then
        local t = GetThing(self.wildmenInArea[wildmenIndex].ThingNum)
        if (t ~= nil and t.Type == T_PERSON and t.Model == M_PERSON_WILD) then
            local s = getShaman(self.aiModuleShaman.ai:getTribe())
            if (s ~= nil) then
                if(get_world_dist_xyz(t.Pos.D3, s.Pos.D3) <= frameworkMath.calculateSpellRangeFromPosition(s.Pos.D2, M_SPELL_CONVERT_WILD, false)) then
                    self.aiModuleShaman:castSpell(M_SPELL_CONVERT_WILD, t.Pos.D3)
                elseif(get_world_dist_xyz(t.Pos.D3, s.Pos.D3) < 512*16 and get_thing_curr_cmd_list_ptr(s) == nil and self.shamanGoToPoint) then
                    command_person_go_to_coord2d(s, t.Pos.D2)
                end
            end
        else
            table.remove(self.wildmenInArea, wildmenIndex)
        end
        wildmenIndex = wildmenIndex+1
      end
    end
end

function AIShamanBehaviourConvertInArea:checkWildmenInArea()
    self.wildmenInArea = {}
    ProcessGlobalTypeList(T_PERSON, function(t)
        if (t.Model == M_PERSON_WILD and get_world_dist_xz(t.Pos.D2, util.to_coord2D(self.center)) < self.radius) then
            table.insert(self.wildmenInArea, t)
        end
        return true
    end)
end

local function convertNearWildmenInvoker(o)
    o:convertWildmen()
    o.convertingSubscriberIndex = subscribe_ExecuteOnTurn(GetTurn() + o.wildmanConvertInterval, function()
        convertNearWildmenInvoker(o)
    end)
end

function AIShamanBehaviourConvertInArea:enable()
    if (self.isEnabled) then
        return
    end
    self:setEnabled(true)
    self.convertingSubscriberIndex = subscribe_ExecuteOnTurn(GetTurn() + self.wildmanConvertInterval, function()
        convertNearWildmenInvoker(self)
    end)
end

function AIShamanBehaviourConvertInArea:disable()
    if (not self.isEnabled) then
        return
    end
    self:setEnabled(false)
    unsubscribe_ExecuteOnTurn(self.convertingSubscriberIndex)
end
