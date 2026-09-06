local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local RarityRoller = require(ServerScriptService.Modules.RarityRoller)
local PlotUtils = require(ServerScriptService.Modules.PlotUtils)
local Upgrades = require(ServerScriptService.Modules.Upgrades)
local Economy = require(ServerScriptService.Modules.Economy)
local FoodStandBuilder = require(ServerScriptService.Modules.FoodStandBuilder)

local FoodStands = require(ReplicatedStorage.Data.FoodStands)
local FoodsFolder = ReplicatedStorage.Data.Foods
local RevealFood = ReplicatedStorage.Remotes:WaitForChild("RevealFood")
local Notify = ReplicatedStorage.Remotes:WaitForChild("Notify")

local plotsFolder = Workspace:WaitForChild("Plots")
local spawnedFolder = Workspace:WaitForChild("SpawnedFood")
local newYork = Workspace:WaitForChild("Destinations"):WaitForChild("NewYork")
local arrivalPoint = newYork:WaitForChild("ArrivalPoint")

-- NewYorkGround: centre Y -10, height 20, so its top face (where carts sit) is Y 0.
local GROUND_Y = 0

local ORDER_COOLDOWN = 1.5 -- seconds between orders, per player (across all stands)
local MAX_ACTIVE_FOOD = 5 -- un-eaten food a player may have out at once
local FOOD_DESPAWN_TIME = 90 -- an ignored food part cleans itself up after this

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

local function spawnFoodModel(player, foodData, rarity, variant, foodSpawnPoint)
	local shape = foodData.Model

	local food = Instance.new("Part")
	food.Name = "Food_" .. foodData.Name
	food.Size = shape.Size
	food.Anchored = true
	food.CanCollide = false
	food.Material = (rarity == "Epic" or rarity == "Legendary" or rarity == "Secret")
		and Enum.Material.Neon
		or Enum.Material.SmoothPlastic
	food.Color = variant.Color
	if shape.Shape then
		food.Shape = shape.Shape
	end

	local placeCFrame = CFrame.new(foodSpawnPoint.Position)
	if shape.Tilt then
		placeCFrame = placeCFrame * shape.Tilt
	end
	food.CFrame = placeCFrame

	food:SetAttribute("FoodName", foodData.Name)
	food:SetAttribute("Rarity", rarity)
	food:SetAttribute("DisplayName", variant.DisplayName)
	food:SetAttribute("BaseBites", foodData.BaseBites)
	food:SetAttribute("BitesRemaining", foodData.BaseBites)
	food:SetAttribute("ValueMultiplier", variant.ValueMultiplier)
	food:SetAttribute("OwnerUserId", player.UserId)
	food:SetAttribute("BaseSize", food.Size)
	food:SetAttribute("BaseRestaurantValue", foodData.BaseRestaurantValue)

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

local function handleOrder(player, foodData, foodSpawnPoint)
	local now = os.clock()
	if lastOrderClock[player] and now - lastOrderClock[player] < ORDER_COOLDOWN then
		return
	end

	if countActiveFood(player.UserId) >= MAX_ACTIVE_FOOD then
		Notify:FireClient(player, "Serve or finish your food before ordering more!", Color3.fromRGB(255, 180, 120))
		return
	end

	if Economy.Get(player) < foodData.Price then
		Notify:FireClient(player, "Not enough money - that costs $" .. foodData.Price .. ".", Color3.fromRGB(255, 120, 120))
		return
	end

	lastOrderClock[player] = now
	Economy.Add(player, -foodData.Price)

	local plot = PlotUtils.getPlotForPlayer(plotsFolder, player)
	local luckBonus = plot and Upgrades.GetLuckBonus(plot) or 0
	local rarity, chance = RarityRoller.Roll(luckBonus)
	local variant = foodData.Variants[rarity]

	spawnFoodModel(player, foodData, rarity, variant, foodSpawnPoint)

	RevealFood:FireClient(player, {
		FoodName = foodData.Label or foodData.Name,
		Rarity = rarity,
		Chance = chance,
		DisplayName = variant.DisplayName,
		Color = variant.Color,
	})
end

-- Resolves one catalog entry to (foodData, orderPrompt, foodSpawnPoint),
-- grayboxing a cart for entries that aren't already in the .rbxl.
local function resolveStand(entry)
	local foodData = require(FoodsFolder:WaitForChild(entry.Food))

	if entry.Existing then
		local model = newYork:WaitForChild(entry.Existing)
		local orderPrompt = model:WaitForChild("OrderPoint"):WaitForChild("OrderPrompt")
		local foodSpawnPoint = model:WaitForChild("FoodSpawnPoint")
		return foodData, orderPrompt, foodSpawnPoint
	end

	local baseCFrame = CFrame.new(
		arrivalPoint.Position.X + (entry.OffsetX or 0),
		GROUND_Y,
		arrivalPoint.Position.Z + (entry.OffsetZ or 0)
	)
	local cart = FoodStandBuilder.Build(
		newYork,
		entry.StandName or entry.Food,
		entry.Tint or Color3.fromRGB(180, 180, 180),
		baseCFrame
	)
	return foodData, cart.OrderPoint.OrderPrompt, cart.FoodSpawnPoint
end

for _, entry in ipairs(FoodStands) do
	local foodData, orderPrompt, foodSpawnPoint = resolveStand(entry)
	orderPrompt.Triggered:Connect(function(player)
		handleOrder(player, foodData, foodSpawnPoint)
	end)
end

Players.PlayerRemoving:Connect(function(player)
	lastOrderClock[player] = nil
end)
