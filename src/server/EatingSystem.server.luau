local ProximityPromptService = game:GetService("ProximityPromptService")
local ServerScriptService = game:GetService("ServerScriptService")

local Economy = require(ServerScriptService.Modules.Economy)
local Shop = require(ServerScriptService.Modules.Shop)
local Upgrades = require(ServerScriptService.Modules.Upgrades)
local PlotUtils = require(ServerScriptService.Modules.PlotUtils)

local plotsFolder = game:GetService("Workspace"):WaitForChild("Plots")

-- Creates the "bring it back to the restaurant" item: a simple carryable Tool
-- tagged with the food's identity, so a future Menu Editor interaction can
-- read these attributes off whatever's in the player's hand/backpack.
local function grantFoodItem(player, food)
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then return end

	local displayName = food:GetAttribute("DisplayName") or "Food Item"
	local rarity = food:GetAttribute("Rarity") or "Common"

	local tool = Instance.new("Tool")
	tool.Name = displayName
	tool.RequiresHandle = true
	tool.CanBeDropped = false

	tool:SetAttribute("FoodName", food:GetAttribute("FoodName"))
	tool:SetAttribute("Rarity", rarity)
	tool:SetAttribute("DisplayName", displayName)
	tool:SetAttribute("ValueMultiplier", food:GetAttribute("ValueMultiplier"))
	tool:SetAttribute("BaseRestaurantValue", food:GetAttribute("BaseRestaurantValue"))

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 0.3, 1)
	handle.Shape = Enum.PartType.Cylinder
	handle.Color = food.Color
	handle.Material = food.Material
	handle.CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(90))
	handle.Parent = tool

	tool.Parent = backpack
end

-- Generic bite-by-bite consumption: works for ANY food part that follows the
-- same attribute pattern (BitesRemaining/BaseBites/BaseSize + a "BitePrompt"),
-- not just Pizza, so future foods plug into this for free.
ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
	if prompt.Name ~= "BitePrompt" then
		return
	end

	local food = prompt.Parent
	if not food or not food:IsA("BasePart") then
		return
	end

	local ownerUserId = food:GetAttribute("OwnerUserId")
	if ownerUserId and ownerUserId ~= 0 and ownerUserId ~= player.UserId then
		return -- not this player's food
	end

	local bitesRemaining = food:GetAttribute("BitesRemaining")
	local baseBites = food:GetAttribute("BaseBites")
	local baseSize = food:GetAttribute("BaseSize")
	if not bitesRemaining or not baseBites or not baseSize then
		return
	end

	bitesRemaining -= 1

	if bitesRemaining <= 0 then
		local displayName = food:GetAttribute("DisplayName") or food:GetAttribute("FoodName") or "food"
		local rarity = food:GetAttribute("Rarity") or "Common"
		local plot = PlotUtils.getPlotForPlayer(plotsFolder, player)
		local tipMultiplier = plot and Upgrades.GetTipMultiplier(plot) or 1
		local value = (food:GetAttribute("BaseRestaurantValue") or 0) * (food:GetAttribute("ValueMultiplier") or 1) * tipMultiplier * Shop.GetMoneyMultiplier(player)
		value = math.floor(value + 0.5)

		-- Placeholder economy: award money immediately on eating. Once the real
		-- serve-customers loop exists, this is where we'd instead just grant the
		-- item and let the menu/customer system pay out.
		Economy.Add(player, value)
		grantFoodItem(player, food)

		print(player.Name .. " finished eating " .. displayName .. " (" .. rarity .. ") - earned " .. tostring(value) .. ", received 1x " .. displayName .. " item")

		food:Destroy()
		return
	end

	food:SetAttribute("BitesRemaining", bitesRemaining)

	local fraction = bitesRemaining / baseBites
	food.Size = Vector3.new(baseSize.X, baseSize.Y * fraction, baseSize.Z * fraction)
end)
