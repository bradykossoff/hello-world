local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local RarityRoller = require(ServerScriptService.Modules.RarityRoller)
local PlotUtils = require(ServerScriptService.Modules.PlotUtils)
local Upgrades = require(ServerScriptService.Modules.Upgrades)

local plotsFolder = Workspace:WaitForChild("Plots")
local PizzaData = require(ReplicatedStorage.Data.Foods.Pizza)
local RevealFood = ReplicatedStorage.Remotes:WaitForChild("RevealFood")

local spawnedFolder = Workspace:WaitForChild("SpawnedFood")

local orderPoint = Workspace:WaitForChild("Destinations"):WaitForChild("NewYork"):WaitForChild("PizzaStand"):WaitForChild("OrderPoint")
local orderPrompt = orderPoint:WaitForChild("OrderPrompt")

local function spawnFoodModel(player, rarity, variant)
	local foodSpawnPoint = orderPoint.Parent:FindFirstChild("FoodSpawnPoint")
	if not foodSpawnPoint then return end

	local food = Instance.new("Part")
	food.Name = "Food_Pizza"
	food.Size = Vector3.new(0.6, 3, 3) -- thickness x diameter x diameter, rotated below to lie flat
	food.Anchored = true
	food.CanCollide = false
	food.Material = (rarity == "Epic" or rarity == "Legendary" or rarity == "Secret") and Enum.Material.Neon or Enum.Material.SmoothPlastic
	food.Color = variant.Color
	food.Shape = Enum.PartType.Cylinder

	local placePos = foodSpawnPoint.Position
	food.CFrame = CFrame.new(placePos) * CFrame.Angles(0, 0, math.rad(90))

	food:SetAttribute("FoodName", PizzaData.Name)
	food:SetAttribute("Rarity", rarity)
	food:SetAttribute("DisplayName", variant.DisplayName)
	food:SetAttribute("BaseBites", PizzaData.BaseBites)
	food:SetAttribute("BitesRemaining", PizzaData.BaseBites)
	food:SetAttribute("ValueMultiplier", variant.ValueMultiplier)
	food:SetAttribute("OwnerUserId", player.UserId)
	food:SetAttribute("BaseSize", food.Size)
	food:SetAttribute("BaseRestaurantValue", PizzaData.BaseRestaurantValue)

	local bitePrompt = Instance.new("ProximityPrompt")
	bitePrompt.Name = "BitePrompt"
	bitePrompt.ActionText = "Bite"
	bitePrompt.ObjectText = variant.DisplayName
	bitePrompt.HoldDuration = 0
	bitePrompt.MaxActivationDistance = 8
	bitePrompt.Parent = food

	food.Parent = spawnedFolder
end

orderPrompt.Triggered:Connect(function(player)
	local plot = PlotUtils.getPlotForPlayer(plotsFolder, player)
	local luckBonus = plot and Upgrades.GetLuckBonus(plot) or 0
	local rarity, chance = RarityRoller.Roll(luckBonus)
	local variant = PizzaData.Variants[rarity]

	spawnFoodModel(player, rarity, variant)

	RevealFood:FireClient(player, {
		FoodName = PizzaData.Name,
		Rarity = rarity,
		Chance = chance,
		DisplayName = variant.DisplayName,
		Color = variant.Color,
	})
end)
