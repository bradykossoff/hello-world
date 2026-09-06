local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlotUtils = require(ServerScriptService.Modules.PlotUtils)
local Upgrades = require(ServerScriptService.Modules.Upgrades)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local Notify = remotes:WaitForChild("Notify")
local PurchaseUpgrade = remotes:WaitForChild("PurchaseUpgrade")

local plotsFolder = Workspace:WaitForChild("Plots")

-- The upgrade panel is opened straight from the on-screen HUD dock now (see
-- src/client/UpgradeUI + HudDock) - there is no physical kiosk on the plot.
-- This script just validates purchases; the client only ever sends a track name.
PurchaseUpgrade.OnServerEvent:Connect(function(player, trackName)
	if type(trackName) ~= "string" then return end

	local plot = PlotUtils.getPlotForPlayer(plotsFolder, player)
	if not plot then
		Notify:FireClient(player, "You need your own restaurant plot first!", Color3.fromRGB(255, 120, 120))
		return
	end

	local success, message = Upgrades.Purchase(player, plot, trackName)
	Notify:FireClient(player, message, success and Color3.fromRGB(140, 230, 140) or Color3.fromRGB(255, 180, 120))
end)
