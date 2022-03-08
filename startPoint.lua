
-- This will be used to localize all the files within, in case some folders need to be changed or something
FRAMEWORK_PATH = "_fr"
UTIL_PATH = FRAMEWORK_PATH .. "/" .. "util"
LEVELS_PATH = FRAMEWORK_PATH .. "/" .. "levels"
WIP_PATH = FRAMEWORK_PATH .. "/" .. "wip"
AI_PATH = FRAMEWORK_PATH .. "/" .. "AI"
AIMODULES_PATH = AI_PATH .. "/" .. "Modules"

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
include(UTIL_PATH.."/Commands.lua")

-- AI and modules
include(AI_PATH .."/AI.lua")
include(AI_PATH .."/HandlerFunctions.lua")
include(AI_PATH .."/BuildPlace.lua")

include(AIMODULES_PATH .."/AIModule.lua")
include(AIMODULES_PATH .."/AIModuleBuildingPlacer.lua")
include(AIMODULES_PATH .."/AIModulePopulationManager.lua")
include(AIMODULES_PATH .."/AIModuleTreeManager.lua")
include(AIMODULES_PATH .."/AIModuleBuildingManager.lua")
include(AIMODULES_PATH .."/AIModuleShaman.lua")


-- Other variables
_gsi = gsi()

if (math.pow == nil) then
    math.pow = function (x,y)
        return x^y
    end
end

function createAI(tribe)
    local ai = AI:new(nil, tribe)

    local buildPlacer = AIModuleBuildingPlacer:new(nil, ai)
    local populationManager = AIModulePopulationManager:new(nil, ai)
    local treeManager = AIModuleTreeManager:new(nil, ai)
    local buildingManager = AIModuleBuildingManager:new(nil, ai)

    ai:addModule(1, buildPlacer)
    ai.buildingPlacer = buildPlacer
    
    ai:addModule(2, populationManager)
    ai.populationManager = populationManager
    
    ai:addModule(3, treeManager)
    ai.treeManager = treeManager
    
    ai:addModule(4, buildingManager)
    ai.buildingManager = buildingManager

    return ai
end