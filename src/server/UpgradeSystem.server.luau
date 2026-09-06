local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlotUtils = require(ServerScriptService.Modules.PlotUtils)
local Upgrades = require(ServerScriptService.Modules.Upgrades)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local Notify = remotes:WaitForChild("Notify")
local OpenUpgradePanel = remotes:WaitForChild("OpenUpgradePanel")
local PurchaseUpgrade = remotes:WaitForChild("PurchaseUpgrade")

local plotsFolder = Workspace:WaitForChild("Plots")

for _, plot in ipairs(plotsFolder:GetChildren()) do
	local kiosk = plot:FindFirstChild("UpgradeKiosk")
	if kiosk then
		local prompt = kiosk:FindFirstChild("InteractPoint") and kiosk.InteractPoint:FindFirstChild("UpgradePrompt")
		if prompt then
			prompt.Triggered:Connect(function(player)
				local ownerId = plot:GetAttribute("OwnerUserId")
				if ownerId ~= player.UserId then
					Notify:FireClient(player, "This isn't your restaurant!", Color3.fromRGB(255, 120, 120))
					return
				end
				OpenUpgradePanel:FireClient(player)
			end)
		end
	end
end

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
