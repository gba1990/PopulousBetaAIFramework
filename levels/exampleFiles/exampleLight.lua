-- includes the file startPoint.lua to the script (if you dont do this, the framework will not be loaded)
include("_fr/startPoint.lua")

-- Your level specific (or tribe specific logic) down here
local function a()
    local sh = getShaman(TRIBE_BLUE)
    local shRed = getShaman(TRIBE_RED)
    local time = 64
    
    -- If both shamans are alive
    if (sh ~= nil and shRed ~= nil) then
        -- calculate the time the light spell will take to reach blue shaman's location
        time = frameworkMath.calculateSpellCastTimeToReachPosition(sh.Pos.D3, shRed.Pos.D3)
        -- predict where blue shaman will be after that time (straight line prediction, no turning/stopping is predicted)
        local position = frameworkMath.calculateThingPositionAfterTime(sh, time)
        
        -- Display a fireball effect on expected location and cast a light there
        logger.pointLog( position )
        createThing(T_SPELL, M_SPELL_LIGHTNING_BOLT, TRIBE_RED, position, false, false)
    end

    -- We execute the function "a" again in time+24 game turns
    subscribe_ExecuteOnTurn(GetTurn() + time + 24, a)
end

a()
