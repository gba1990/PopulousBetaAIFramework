--[[
This code is thought for level 23 inferno of the original levels. It uses the original bullfrog's popscript
but adds the harvesting and dismantling behaviours to the AI therefore, incrementing their AIModulePopulationManager
when compared to their vanilla behaviour.

You need to link in the world editor this script to the level and save with the new format and that would be it.


        Population of the AI at 10 minutes mark with the different AI possible, where, vanilla is without any lua stuff
    Vanilla - With AI without dismantle - With AI and dismantle (every 256) - With AI dismantle (every 180) (three different results)
    36      -    40                     -    43                             -    48 and 45 and 37
    44      -    36                     -    44                             -    43 and 40 and 43
    39      -    40                     -    35                             -    40 and 49 and 50
]]

-- includes the file startPoint.lua to the script (if you dont do this, the framework will not be loaded)
include("_fr/startPoint.lua")

--[[
You can invoke this method with the following:
    
    logArea(entries[1].centre, entries[1].radius, 100)
    logArea(entries[2].centre, entries[2].radius, 80)
    logArea(entries[3].centre, entries[3].radius, 80)
    
In order to display the areas in which red will harvest and look for trees.
Those lines are commented below (lines 68-70), just uncomment them
]]
function logArea(point, radius, resolution)
    logger.pointLog(point)
    for i = 0, 2070, resolution do
        logger.pointLog(frameworkMath.calculatePosition(point, i, radius))
    end
end

-- We create the AI with all the modules. Perhaps in a future version these methods add even more
-- modules and are not the exact moment in which the "experiment" took place.
-- You can use commit 65770690f426366a22c2b0218491011a630cc2dd
local redAI = createAI(TRIBE_RED)
local yellowAI = createAI(TRIBE_YELLOW)
local greenAI = createAI(TRIBE_GREEN)

-- Let the AI use dismantle trick
redAI:setModule("dismantle_trick", AIModuleDismantleTrick:new())
yellowAI:setModule("dismantle_trick", AIModuleDismantleTrick:new())
greenAI:setModule("dismantle_trick", AIModuleDismantleTrick:new())

logger.msgLog("  Script loaded!")
logger.msgLog("At 10 minute mark,")
logger.msgLog("AI's populations will")
logger.msgLog("be displayed here")
logger.msgLog("  The game will automatically pause")

-- Add entries for the treeManager module to search for trees there for each tribe
-- For yellow, it covers the whole crab island, this may be bad as they tend to farm trees far from the 
-- centre as they are first on the tree list. We can reduce this area, or in a future tell them to farm the closest ones first,
-- or to bring wood back to the main drum tower or somewhere else
local entries = {
    {centre = MAP_XZ_2_WORLD_XYZ(8, 10), radius = 5120},
    {centre = MAP_XZ_2_WORLD_XYZ(40, 230), radius = 10000},
    {centre = MAP_XZ_2_WORLD_XYZ(78, 4), radius = 10000},
}
table.insert(redAI:getModule(AI_MODULE_TREE_MANAGER_ID).treeSearchLocations, entries[1])
table.insert(redAI:getModule(AI_MODULE_TREE_MANAGER_ID).treeSearchLocations, entries[2])
table.insert(redAI:getModule(AI_MODULE_TREE_MANAGER_ID).treeSearchLocations, entries[3])

table.insert(yellowAI:getModule(AI_MODULE_TREE_MANAGER_ID).treeSearchLocations, 
            {centre = MAP_XZ_2_WORLD_XYZ(166, 74), radius = 30*512})

table.insert(greenAI:getModule(AI_MODULE_TREE_MANAGER_ID).treeSearchLocations, 
            {centre = MAP_XZ_2_WORLD_XYZ(122, 184), radius = 25*512})


logArea(entries[1].centre, entries[1].radius, 10)
logArea(entries[2].centre, entries[2].radius, 10)
logArea(entries[3].centre, entries[3].radius, 10)


-- After 10 minutes, display on the screen the populations for each tribe
subscribe_ExecuteOnTurn(7200, function()
    gnsi().Flags = gnsi().Flags | GNS_PAUSED -- Pause the game
    logger.msgLog("Red has %s people", GET_NUM_PEOPLE(TRIBE_RED))
    logger.msgLog("Yellow has %s people", GET_NUM_PEOPLE(TRIBE_YELLOW))
    logger.msgLog("Green has %s people", GET_NUM_PEOPLE(TRIBE_GREEN))
end)


--[[
    -- Optional stuff:

    -- Use these builders, so the AI builds more huts
    redAI:setModule("LookAhead", LookAheadBuilder:new(999, false, false))
    yellowAI:setModule("LookAhead", LookAheadBuilder:new(999, false, false))
    greenAI:setModule("LookAhead", LookAheadBuilder:new(999, false, false))

    -- Give red a ton of extra trees to have enough wood for all builds
    for i = 1, 30, 1 do
        createThing(T_SCENERY, M_SCENERY_TREE_1, 0, util.to_coord3D(entries[2].centre), false, false)
        createThing(T_SCENERY, M_SCENERY_TREE_1, 0, util.to_coord3D(entries[3].centre), false, false)
    end

]]