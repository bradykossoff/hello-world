local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local RarityRoller = require(ServerScriptService.Modules.RarityRoller)
local PlotUtils = require(ServerScriptService.Modules.PlotUtils)
local Upgrades = require(ServerScriptService.Modules.Upgrades)
local Economy = require(ServerScriptService.Modules.Economy)

local plotsFolder = Workspace:WaitForChild("Plots")
local PizzaData = require(ReplicatedStorage.Data.Foods.Pizza)
local RevealFood = ReplicatedStorage.Remotes:WaitForChild("RevealFood")
local Notify = ReplicatedStorage.Remotes:WaitForChild("Notify")

local spawnedFolder = Workspace:WaitForChild("SpawnedFood")

local ORDER_COOLDOWN = 1.5 -- seconds between orders, per player
local MAX_ACTIVE_FOOD = 5 -- un-eaten pizzas a player may have out at once
local FOOD_DESPAWN_TIME = 90 -- an ignored pizza cleans itself up after this

local orderPoint = Workspace:WaitForChild("Destinations"):WaitForChild("NewYork"):WaitForChild("PizzaStand"):WaitForChild("OrderPoint")
local orderPrompt = orderPoint:WaitForChild("OrderPrompt")

local lastOrderClock = {}

local function countActiveFood(userId)
	local count = 0
	for _, food in ipairs(spawnedFolder:GetChildren()) do
		if food:GetAttribute("OwnerUserId") == userId then
			count += 1
		end
	end
	return count
end

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

	task.delay(FOOD_DESPAWN_TIME, function()
		if food.Parent then
			food:Destroy()
		end
	end)
end

orderPrompt.Triggered:Connect(function(player)
	local now = os.clock()
	if lastOrderClock[player] and now - lastOrderClock[player] < ORDER_COOLDOWN then
		return
	end

	if countActiveFood(player.UserId) >= MAX_ACTIVE_FOOD then
		Notify:FireClient(player, "Serve or finish your pizzas before ordering more!", Color3.fromRGB(255, 180, 120))
		return
	end

	if Economy.Get(player) < PizzaData.Price then
		Notify:FireClient(player, "Not enough money - a pizza costs $" .. PizzaData.Price .. ".", Color3.fromRGB(255, 120, 120))
		return
	end

	lastOrderClock[player] = now
	Economy.Add(player, -PizzaData.Price)

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

Players.PlayerRemoving:Connect(function(player)
	lastOrderClock[player] = nil
end)
