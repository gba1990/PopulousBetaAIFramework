--[[
	Ingame logger prints log messages into the actual game screen, so no need to open the debug window is required
]]

import(Module_Defines)
import(Module_DataTypes)
import(Module_Draw)
import(Module_Objects)
import(Module_String)

local msgTimeout = 60 -- 5 seconds by default
local pointTimeout = 16
local pointEffect = M_EFFECT_FIREBALL
local msgDisplayX = 0
local msgDisplayY = 0
local showMouseCoordinates = false
local msgLogArray = {}
local pointsLogArray = {}

local _heightPerCharacter = 25
local _widthPerCharacter = 12
local _font = 1
local _fontColour = 0 -- White == 0
local _displayColour = 1 -- Black == 1
local _consistentMessageTimeoutValue = -2

-- Private methods

local function _largestLineInLog()
    local result = 0
    local length = #(msgLogArray)
    for i = 1, length, 1 do
        local txt = msgLogArray[i].text
        if (#txt > result) then
            result = #txt
        end
    end
    return result
end

local function _removeTimedoutLogs(_table, timeout)
    for i = #(_table), 1, -1 do
        local entry = _table[i]
        if (GetTurn() > entry.timestamp + timeout and entry.timestamp ~= _consistentMessageTimeoutValue) then
            table.remove( _table, i)
        end
    end
end

local function _removeMsgLogsIfTooManyAreDisplayed()
    local _gnsi = gnsi()
    local availableSpace = _gnsi.ScreenH
    local totalNumberOfPossibleMessages = availableSpace / _heightPerCharacter
    local idx = 1

    while(#(msgLogArray) > totalNumberOfPossibleMessages)
    do
        local entry = msgLogArray[idx]
        if (entry.timestamp ~= _consistentMessageTimeoutValue) then -- Keep consistent logs
            table.remove( msgLogArray, idx)
        else
            idx = idx + 1
            if(idx >= #(msgLogArray)) then break end
        end
    end
end

local function _processIngameMsgLog()
    local _gnsi = gnsi()
    local length = #(msgLogArray)
    local scrW, scrH = _gnsi.ScreenW, _gnsi.ScreenH
    local gapBeforeText = 5
    
    DrawBox(msgDisplayX, msgDisplayY, gapBeforeText + _widthPerCharacter * _largestLineInLog(), length * _heightPerCharacter, _displayColour)

    for i = 1, length, 1 do
        local txt = msgLogArray[i].text
        SetFont(_font)
        LbDraw_Text(msgDisplayX + gapBeforeText, msgDisplayY + (i-1)*_heightPerCharacter, txt, _fontColour)
    end

    _removeTimedoutLogs(msgLogArray, msgTimeout)
    _removeMsgLogsIfTooManyAreDisplayed()
end

local function _processIngamePoints()
    local length = #(pointsLogArray)
    for i = 1, length, 1 do
        local coords = pointsLogArray[i].coordinates
        createThing(T_EFFECT, pointsLogArray[i].effect, 0, coords, false, false)
    end
    _removeTimedoutLogs(pointsLogArray, pointTimeout)
end

subscribe_OnFrame(_processIngameMsgLog)
subscribe_OnTurn(_processIngamePoints)

-- Public methods
local function setMessageTimeoutGameturns(timeout)
    msgTimeout = timeout
end

local function setPointsTimeoutGameturns(timeout)
    msgTimeout = timeout
end

local function setPointsEffect(effect)
    pointEffect = effect
end

local function setMsgDisplayLocationInScreen(x, y)
    msgDisplayX = x
    msgDisplayY = y
end

local function setShowMouseCoordinates(bool)
    showMouseCoordinates = bool
end

local function msgLog(msg, ...)
    table.insert(msgLogArray, { timestamp = GetTurn(), text = string.format(msg, ...)})
end

local function pointLog(coord)
    table.insert(pointsLogArray, { timestamp = GetTurn(), coordinates = util.to_coord3D(coord), effect = pointEffect})
end


logger = {}
logger.setMessageTimeoutGameturns = setMessageTimeoutGameturns
logger.setPointsTimeoutGameturns = setPointsTimeoutGameturns
logger.setPointsEffect = setPointsEffect
logger.setMsgDisplayLocationInScreen = setMsgDisplayLocationInScreen
logger.setShowMouseCoordinates = setShowMouseCoordinates
logger.msgLog = msgLog
logger.pointLog = pointLog