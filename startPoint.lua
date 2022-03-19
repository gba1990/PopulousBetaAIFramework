
-- This will be used to localize all the files within, in case some folders need to be changed or something
FRAMEWORK_PATH = "_fr"
UTIL_PATH = FRAMEWORK_PATH .. "/" .. "util"
LEVELS_PATH = FRAMEWORK_PATH .. "/" .. "levels"
WIP_PATH = FRAMEWORK_PATH .. "/" .. "wip"
AI_PATH = FRAMEWORK_PATH .. "/" .. "AI"
AIMODULES_PATH = AI_PATH .. "/" .. "Modules"
SHAMAN_BEHAVIOURS_PATH = AIMODULES_PATH .. "/" .. "ShamanFunctionalities/ShamanBehaviours"
SPELL_MANAGERS_PATH = AIMODULES_PATH .. "/" .. "ShamanFunctionalities/SpellManagers"
SPELL_SELECTORS_PATH = AIMODULES_PATH .. "/" .. "ShamanFunctionalities/SpellSelectors"

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
include(UTIL_PATH.."/Functional.lua")
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
include(AIMODULES_PATH .."/AIModuleTreeHarvester.lua")
include(AIMODULES_PATH .."/AIModuleBuildingManager.lua")
include(AIMODULES_PATH .."/AIModuleDismantleTrick.lua")
include(AIMODULES_PATH .."/AIModuleShaman.lua")

-- Shaman
include(SHAMAN_BEHAVIOURS_PATH .."/AIShamanBehaviour.lua")
include(SHAMAN_BEHAVIOURS_PATH .."/AIShamanBehaviourIdle.lua")
include(SHAMAN_BEHAVIOURS_PATH .."/AIShamanBehaviourDodge.lua")
include(SHAMAN_BEHAVIOURS_PATH .."/AIShamanBehaviourSpellCasting.lua")
include(SHAMAN_BEHAVIOURS_PATH .."/AIShamanBehaviourConvert.lua")
include(SHAMAN_BEHAVIOURS_PATH .."/AIShamanBehaviourDefendArea.lua")
include(SPELL_MANAGERS_PATH .."/AIShamanSpellManager.lua")
include(SPELL_MANAGERS_PATH .."/AIShamanSpellManagerBucket.lua")
include(SPELL_SELECTORS_PATH .."/AIShamanSpellSelector.lua")


-- Other variables
_gsi = gsi()

-- Identifiers of AI modules, in case a module requires another module, to search for it 
AI_MODULE_BUILDING_PLACER_ID = "buildingPlacer"
AI_MODULE_POPULATION_MANAGER_ID = "populationManager"
AI_MODULE_TREE_MANAGER_ID = "treeManager"
AI_MODULE_SHAMAN_MANAGER_ID = "shamanManager"

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
    local shamanManager = AIModuleShaman:new(nil, ai)

    ai:setModule(AI_MODULE_BUILDING_PLACER_ID, buildPlacer)
    ai.buildingPlacer = buildPlacer
    
    ai:setModule(AI_MODULE_POPULATION_MANAGER_ID, populationManager)
    ai.populationManager = populationManager
    
    ai:setModule(AI_MODULE_TREE_MANAGER_ID, treeManager)
    ai.treeManager = treeManager
    
    ai:setModule("buildingManager", buildingManager)
    ai.buildingManager = buildingManager
    
    ai:setModule(AI_MODULE_SHAMAN_MANAGER_ID, shamanManager)
    ai.shamanManager = shamanManager

    ai:setModule("treeHarvester", AIModuleTreeHarvester:new(nil, ai))

    --ai:getModule(AI_MODULE_SHAMAN_MANAGER_ID):setBehaviour("dodge", AIShamanBehaviourDodge:new()) --- TODO enable once it is bug-free
    ai:getModule(AI_MODULE_SHAMAN_MANAGER_ID):setBehaviour("casting", AIShamanBehaviourSpellCasting:new())
    ai:getModule(AI_MODULE_SHAMAN_MANAGER_ID):setBehaviour("core", AIShamanBehaviourIdle:new())

    return ai
end