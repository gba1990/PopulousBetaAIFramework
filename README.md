# PopulousBetaAIFramework

Presents utilities that can be used for your AIs
- EventManager (so any of your scripts can trigger functions on the (for example) OnTurn, eliminating the need to only have one OnTurn, in other words: hook/event subscribing)
- IngameLogger (to display log messages onto the screen, to allow for easier log visualization)
- FrameworkMath (extra math functions)
- Utils (well... more utilities: change Coord3D to 2D, create Coord3D from xyz, clone Coord3D objects...)


## How to use:
- Download or clone the repo
- Place the contents on your PopulousTheBeginning/scripts directory
- Rename the folder from "PopulousBetaAIFramework" to "_fr" (if the name is too long, the world editor may not allow you to link the scripts)
- Link _fr/levels/level2001.lua to one of your levels
- Now, write your level code on level2001.lua (You can copy the code on the file exampleLight.lua as a test, the level must have blue and red shamans. Red shaman will predict your shaman location and cast light there)