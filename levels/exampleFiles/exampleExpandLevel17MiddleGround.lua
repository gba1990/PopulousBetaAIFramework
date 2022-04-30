-- At this point, multiple LB expansions are not that good, but single LB works correctly
-- This is intended for Blue on Level 17
include("_fr/startPoint.lua")

local tribe = 0 -- Tribe that will perform the expansion
local ai = AI:new(tribe)

-- We define the expansion points
local expansionPoints = {
    -- Points at the back
    ExpansionPoint:new(nil, MAP_XZ_2_WORLD_XYZ(200, 230), MAP_XZ_2_WORLD_XYZ(188,228), 0),
    ExpansionPoint:new(nil, MAP_XZ_2_WORLD_XYZ(188,228), MAP_XZ_2_WORLD_XYZ(178, 220), frameworkMath.degToIngameAngle(300)),
    ExpansionPoint:new(nil, MAP_XZ_2_WORLD_XYZ(180,208), MAP_XZ_2_WORLD_XYZ(178, 198), frameworkMath.degToIngameAngle(270)),
    -- Points at the front
    SinglePointExpansionPoint:new(nil, MAP_XZ_2_WORLD_XYZ(218,152), MAP_XZ_2_WORLD_XYZ(242, 154)),
    SinglePointExpansionPoint:new(nil, MAP_XZ_2_WORLD_XYZ(224,164), MAP_XZ_2_WORLD_XYZ(224, 140)),
    SinglePointExpansionPoint:new(nil, MAP_XZ_2_WORLD_XYZ(230,164), MAP_XZ_2_WORLD_XYZ(232, 140)),
    -- Backdoor
    ExpansionPoint:new(nil, MAP_XZ_2_WORLD_XYZ(180,216), MAP_XZ_2_WORLD_XYZ(180, 212), frameworkMath.degToIngameAngle(270)),
}
expansionPoints[1].numberOfLBs = 3
expansionPoints[2].numberOfLBs = 3
expansionPoints[3].numberOfLBs = 3

expansionPoints[7].targetCoordinate = MAP_XZ_2_WORLD_XYZ(120,216)

local sh = AIModuleShaman:new()
ai:setModule(AI_MODULE_SHAMAN_MANAGER_ID, sh)

subscribe_ExecuteOnTurn(64, function ()
    -- We add the expand behaviour after CoR is made
    ai:getModule(AI_MODULE_SHAMAN_MANAGER_ID):setBehaviour("core", AIShamanBehaviourExpand:new(nil, expansionPoints))
    
    -- You can interrupt after casting a LB with this. For example to avoid LBs draining all the mana, or, because we are under attack
    --ai:getModule(AI_MODULE_SHAMAN_MANAGER_ID).behaviours["core"].expandInterruptCondition = function() return true end
end)

subscribe_OnTurn(function()
    -- We give Spells and remove cooldown
    PThing.GiveShot(tribe, M_SPELL_LAND_BRIDGE, 4)
    sh.spellManager.spellsBucket[M_SPELL_LAND_BRIDGE].shots = 0
end)