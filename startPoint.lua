
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
CHEAT_MODULES_PATH = AIMODULES_PATH .. "/" .. "CheatModules"

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
include(UTIL_PATH.."/UtilPThings.lua")
include(UTIL_PATH.."/UtilRefs.lua")
include(UTIL_PATH.."/Utils.lua")
include(UTIL_PATH.."/EventManager.lua")
include(UTIL_PATH.."/IngameLogger.lua")
include(UTIL_PATH.."/FrameworkMath.lua")
include(UTIL_PATH.."/Commands.lua")

-- AI and modules
include(AI_PATH .."/AI.lua")
include(AI_PATH .."/HandlerFunctions.lua")
include(AI_PATH .."/ExpansionPoints/ExpansionPoint.lua")
include(AI_PATH .."/ExpansionPoints/SinglePointExpansionPoint.lua")

include(AIMODULES_PATH .."/AIModule.lua")
include(AIMODULES_PATH .."/AIModuleBuildingPlacer.lua")
include(AIMODULES_PATH .."/AIModulePopulationManager.lua")
include(AIMODULES_PATH .."/AIModuleTreeManager.lua")
include(AIMODULES_PATH .."/AIModuleTreeHarvester.lua")
include(AIMODULES_PATH .."/AIModuleBuildingManager.lua")
include(AIMODULES_PATH .."/AIModuleDismantleTrick.lua")
include(AIMODULES_PATH .."/AIModuleShaman.lua")
include(AIMODULES_PATH .."/AIModulePopulateDrumTowers.lua")
include(AIMODULES_PATH .."/AIModulePeopleTrainer.lua")

include(AIMODULES_PATH .."/BuildAreas/BuildPlace.lua")
include(AIMODULES_PATH .."/BuildAreas/BuildArea.lua")
include(AIMODULES_PATH .."/BuildAreas/DefensiveBuildArea.lua")
include(AIMODULES_PATH .."/BuildAreas/LookAheadBuilder.lua")
include(AIMODULES_PATH .."/BuildAreas/BuildingReplacerBuilder.lua")

-- Shaman
include(SHAMAN_BEHAVIOURS_PATH .."/AIShamanBehaviour.lua")
include(SHAMAN_BEHAVIOURS_PATH .."/AIShamanBehaviourIdle.lua")
include(SHAMAN_BEHAVIOURS_PATH .."/AIShamanBehaviourDodge.lua")
include(SHAMAN_BEHAVIOURS_PATH .."/AIShamanBehaviourSpellCasting.lua")
include(SHAMAN_BEHAVIOURS_PATH .."/AIShamanBehaviourConvert.lua")
include(SHAMAN_BEHAVIOURS_PATH .."/AIShamanBehaviourConvertInArea.lua")
include(SHAMAN_BEHAVIOURS_PATH .."/AIShamanBehaviourDefendArea.lua")
include(SHAMAN_BEHAVIOURS_PATH .."/AIShamanBehaviourExpand.lua")
include(SPELL_MANAGERS_PATH .."/AIShamanSpellManager.lua")
include(SPELL_MANAGERS_PATH .."/AIShamanSpellManagerBucket.lua")
include(SPELL_SELECTORS_PATH .."/AIShamanSpellSelector.lua")

-- Cheat Modules
include(CHEAT_MODULES_PATH .."/AIModuleIntervalCheat.lua")
include(CHEAT_MODULES_PATH .."/AIModuleCheatIncreaseSprog.lua")
include(CHEAT_MODULES_PATH .."/AIModuleCheatIncreaseUpgrade.lua")
include(CHEAT_MODULES_PATH .."/AIModuleCheatIncreaseMana.lua")
include(CHEAT_MODULES_PATH .."/AIModuleCheatGiveMana.lua")
include(CHEAT_MODULES_PATH .."/AIModuleCheatAutoSprog.lua")

-- Other variables
_gsi = gsi()
_sti = scenery_type_info()
_spti = spells_type_info()
_c = constants()

M_SPELL_SWARM = M_SPELL_INSECT_PLAGUE
M_SPELL_TORNADO = M_SPELL_WHIRLWIND
M_SPELL_LIGHTNING = M_SPELL_LIGHTNING_BOLT
M_SPELL_CONVERT = M_SPELL_CONVERT_WILD

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
    local ai = AI:new(tribe)

    ai:setModule(AI_MODULE_BUILDING_PLACER_ID, AIModuleBuildingPlacer:new())
    ai:setModule(AI_MODULE_POPULATION_MANAGER_ID, AIModulePopulationManager:new())
    ai:setModule(AI_MODULE_TREE_MANAGER_ID, AIModuleTreeManager:new())
    ai:setModule("buildingManager", AIModuleBuildingManager:new())
    ai:setModule(AI_MODULE_SHAMAN_MANAGER_ID, AIModuleShaman:new())
    ai:setModule("treeHarvester", AIModuleTreeHarvester:new())

    ai:getModule(AI_MODULE_SHAMAN_MANAGER_ID):setBehaviour("dodge", AIShamanBehaviourDodge:new())
    ai:getModule(AI_MODULE_SHAMAN_MANAGER_ID):setBehaviour("casting", AIShamanBehaviourSpellCasting:new())
    ai:getModule(AI_MODULE_SHAMAN_MANAGER_ID):setBehaviour("core", AIShamanBehaviourIdle:new())

    return ai
end