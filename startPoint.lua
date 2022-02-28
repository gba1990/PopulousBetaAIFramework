
-- This will be used to localize all the files within, in case some folders need to be changed or something
FRAMEWORK_PATH = "_fr"
UTIL_PATH = FRAMEWORK_PATH .. "/" .. "util"
LEVELS_PATH = FRAMEWORK_PATH .. "/" .. "levels"
WIP_PATH = FRAMEWORK_PATH .. "/" .. "wip"

-- To have all modules
import(Module_System)
import(Module_Players)
import(Module_Defines)
import(Module_PopScript)
import(Module_Game)
import(Module_Objects)
import(Module_Map)
import(Module_Math)
import(Module_MapWho)
import(Module_String)
import(Module_ImGui)
import(Module_Draw)
import(Module_System)
import(Module_Globals)
import(Module_Person)
import(Module_Table)
import(Module_DataTypes)
import(Module_Sound)
import(Module_Commands)
import(Module_Level)
import(Module_Shapes)

-- Utils
include(UTIL_PATH.."/Utils.lua")
include(UTIL_PATH.."/EventManager.lua")
include(UTIL_PATH.."/IngameLogger.lua")
include(UTIL_PATH.."/FrameworkMath.lua")

-- Other variables
_gsi = gsi()

if (math.pow == nil) then
    math.pow = function (x,y)
        return x^y
    end
end