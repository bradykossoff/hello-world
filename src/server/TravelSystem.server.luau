local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

local PlotUtils = require(ServerScriptService.Modules.PlotUtils)

local hub = Workspace:WaitForChild("Hub")
local destinations = Workspace:WaitForChild("Destinations")
local newYork = destinations:WaitForChild("NewYork")
local plotsFolder = Workspace:WaitForChild("Plots")

local travelPrompt = hub:WaitForChild("TravelBoard"):WaitForChild("TravelPoint"):WaitForChild("TravelToNewYorkPrompt")
local returnPrompt = newYork:WaitForChild("ReturnHomeKiosk"):WaitForChild("ReturnPoint"):WaitForChild("ReturnHomePrompt")
local arrivalPoint = newYork:WaitForChild("ArrivalPoint")

local function teleport(player, cframe)
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.CFrame = cframe
	end
end

travelPrompt.Triggered:Connect(function(player)
	teleport(player, arrivalPoint.CFrame)
end)

returnPrompt.Triggered:Connect(function(player)
	local plot = PlotUtils.getPlotForPlayer(plotsFolder, player)
	if plot then
		local spawnCFrame = PlotUtils.getSpawnCFrame(plot)
		if spawnCFrame then
			teleport(player, spawnCFrame)
			return
		end
	end

	-- Fallback: no plot found, use the default spawn
	local defaultSpawn = Workspace:FindFirstChild("SpawnLocation")
	if defaultSpawn then
		teleport(player, defaultSpawn.CFrame + Vector3.new(0, 5, 0))
	end
end)
