-- Builds the golden-hour world dressing (New York block, hub pass, Lighting,
-- game-wide sign cleanup) on server start. All the logic lives in the module
-- so it can also be run from the Studio command bar for an Edit-mode preview:
--   require(game.ServerScriptService.Modules.WorldDress).BuildAll()

local ServerScriptService = game:GetService("ServerScriptService")

require(ServerScriptService.Modules.WorldDress).BuildAll()
