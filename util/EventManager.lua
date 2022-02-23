--[[
    Events are only fired onced. So, if you have two OnTurn() only one will work.
    This module is a work arround to that:

    The function you want to execute is "subscribed" to the method (subscribe_OnTurn(myFunc)),
    and when OnTurn() gets executed in here, it will call your method.

    It does not guarantee the order in which the functions are called,
    but priorities can be implemented if needed.

    Remember not to write another event function somewhere else, as they override each other.


    Avaliable hooks:
        OnCreateThing, -- TODO
        OnFrame, -
        OnKeyDown,-
        OnKeyUp, -
        OnTurn, -
        OnReload,-- TODO
        OnChat,-- TODO
        OnPacket,-- TODO
        OnImGuiFrame,-- TODO
        OnSave,-- TODO
        OnLoad,-- TODO
        OnTrigger-- TODO
]]

-- Common thing
local function _processSubscribers(_table, ...)
    for k,v in pairs(_table) do
        v(...)
    end
end

local function _processExecuteOnTurn(currentTurn, _table)
    for k,v in pairs(_table) do
        local entry = v
        if (entry.turn <= currentTurn) then
            entry.func()
            _table[k] = nil
        end
    end
end

-- Indexes that return each subscribe
local indexes = {}
indexes["OnTurn"] = 0
indexes["ExecuteOnTurn"] = 0
indexes["OnThing"] = 0
indexes["OnRegenerate"] = 0
indexes["OnKeyDown"] = 0
indexes["OnKeyUp"] = 0
indexes["OnMouse"] = 0
indexes["OnChat"] = 0
indexes["OnFrame"] = 0
indexes["OnPlayerHintDisplay"] = 0
indexes["OnPlayerSpell"] = 0
indexes["OnDamage"] = 0

-- Essential
local _OnTurn_Subscribed = {}
local _ExecuteOnTurn_Subscribed = {}
function OnTurn()
    _processExecuteOnTurn(GetTurn(), _ExecuteOnTurn_Subscribed)
    _processSubscribers(_OnTurn_Subscribed)

end

local _OnThing_Subscribed = {}
function OnThing(event) -- TODO: rename to OnCreateThing
    _processSubscribers(_OnThing_Subscribed, event)
end

local _OnRegenerate_Subscribed = {}
function OnRegenerate(event)
    _processSubscribers(_OnRegenerate_Subscribed, event)
end

-- Input
local _OnKeyDown_Subscribed = {}
function OnKeyDown(event)
    _processSubscribers(_OnKeyDown_Subscribed, event)
end

local _OnKeyUp_Subscribed = {}
function OnKeyUp(event)
    _processSubscribers(_OnKeyUp_Subscribed, event)
end

local _OnMouse_Subscribed = {}
function OnMouse(event)
    _processSubscribers(_OnMouse_Subscribed, event)
    return false
end

local _OnChat_Subscribed = {}
function OnChat(message)
    _processSubscribers(_OnChat_Subscribed, message)
end

-- Serialization
local _OnSave_Subscribed = {}
local _OnLoad_Subscribed = {}
-- Sound
local _OnSoundPlay_Subscribed = {}
local _OnSoundStop_Subscribed = {}
-- Drawing
local _OnFrame_Subscribed = {}
function OnFrame()
    _processSubscribers(_OnFrame_Subscribed)
end

local _OnPreSpriteFrame_Subscribed = {}
local _OnSpriteFrame_Subscribed = {}
-- other
local _OnPlayerHintDisplay_Subscribed = {}
function OnPlayerHintDisplay(hint)
    _processSubscribers(_OnPlayerHintDisplay_Subscribed, hint)
end

local _OnPlayerSpell_Subscribed = {}
function OnPlayerSpell(thing)
    _processSubscribers(_OnPlayerSpell_Subscribed, thing)
end

local _OnDamage_Subscribed = {}
function OnDamage(event)
    _processSubscribers(_OnDamage_Subscribed, event)
end

local _OnDeinit_Subscribed = {}
local _OnLoadPalTables_Subscribed = {}


--[[
    Public methods
    
    For each event there is a subscribe and a unsubscribe.
    The subscribe returns an identifier for the added event.
    That identifier can be fed into the unsubscribe to remove the event.
]]

local function updateIndex(key)
    local idx = indexes[key]
    indexes[key] = idx + 1
    return "E"..idx
end
    
-- Essential
function subscribe_OnTurn(func)
    local index = updateIndex("OnTurn")
    _OnTurn_Subscribed[index] = func
    return index
end
function unsubscribe_OnTurn(idx)
    _OnTurn_Subscribed[idx] = nil
end

function subscribe_ExecuteOnTurn(_turn, _func)
    local index = updateIndex("ExecuteOnTurn")
    _ExecuteOnTurn_Subscribed[index] = {turn = _turn, func = _func }
    return index
end
function unsubscribe_ExecuteOnTurn(idx)
    _ExecuteOnTurn_Subscribed[idx] = nil
end

-- TODO: add index to these other methods
-- Drawing
subscribe_OnFrame = function(func)
    table.insert(_OnFrame_Subscribed, func)
end