--[[
    Requires a red shaman on the map
]]

-- External file that includes the file startPoint.lua to the script
include("_fr/startPoint.lua")

local redAI = AI:new(nil, TRIBE_RED)
local module = AIModuleShaman:new(nil, redAI, {M_SPELL_BLAST})  -- AI has blast as a spell it can charge
redAI:addModule(1, module)
redAI.shamanModule = module

-- We determine the area to defend
local areaC = util.clone_Coord2D(getShaman(TRIBE_RED).Pos.D2)
local areaR = 5000

-- You may want to spawn some firewarriors to check how the red shaman performs against them
-- createThing(T_PERSON, M_PERSON_SUPER_WARRIOR, 0, util.create_Coord3D(0,0,0), false, false)

subscribe_OnTurn(function ()
    -- Give some mana, so the blast battle has some quality
    GIVE_MANA_TO_PLAYER(TRIBE_RED, 100)

    -- Draw the area on which the shaman will defend
    if (GetTurn() % 4 == 0) then
        logger.logCircle(areaC, areaR, 100)
    end
end)

subscribe_ExecuteOnTurn(80, function ()
    redAI.shamanModule:setBehaviour(AIShamanBehaviourDefendArea:new(nil, areaC, areaR)) -- We set the behaviour we want the shaman to have

    redAI.shamanModule:giveSingleShotSpell(M_SPELL_LIGHTNING_BOLT) -- We give two lights to red (as if obtained from a stonehead)
    redAI.shamanModule:giveSingleShotSpell(M_SPELL_LIGHTNING_BOLT)
end)