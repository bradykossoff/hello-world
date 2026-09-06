local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlotUtils = require(ServerScriptService.Modules.PlotUtils)
local Upgrades = require(ServerScriptService.Modules.Upgrades)
local Foods = ReplicatedStorage.Data.Foods
local Notify = ReplicatedStorage.Remotes:WaitForChild("Notify")

local plotsFolder = Workspace:WaitForChild("Plots")

-- The menu book is opened directly from the persistent UI now (no
-- physical kiosk in the plaza) - these two remotes are all this script
-- needs; the client finds its own plot to populate the panel.
local remotes = ReplicatedStorage.Remotes
local AddFoodToMenu = remotes:WaitForChild("AddFoodToMenu")
local RemoveMenuItem = remotes:WaitForChild("RemoveMenuItem")

local function addToMenu(plot, tool)
	local menu = plot:FindFirstChild("Menu")
	if not menu then return end

	local menuItem = Instance.new("Folder")
	menuItem.Name = "MenuItem"
	menuItem:SetAttribute("FoodName", tool:GetAttribute("FoodName"))
	menuItem:SetAttribute("Rarity", tool:GetAttribute("Rarity"))
	menuItem:SetAttribute("DisplayName", tool:GetAttribute("DisplayName"))
	menuItem:SetAttribute("ValueMultiplier", tool:GetAttribute("ValueMultiplier"))
	menuItem:SetAttribute("BaseRestaurantValue", tool:GetAttribute("BaseRestaurantValue"))
	menuItem.Parent = menu

	plot:SetAttribute("MenuCount", #menu:GetChildren())
end

-- Reverse of addToMenu: rebuilds a carryable Tool from a saved menu item,
-- looking up the food's rarity-variant color/material from its FoodData
-- module (menu items don't store color themselves) so it looks the same as
-- when it was originally eaten.
local function toolFromMenuItem(menuItem)
	local foodName = menuItem:GetAttribute("FoodName")
	local rarity = menuItem:GetAttribute("Rarity")
	local displayName = menuItem:GetAttribute("DisplayName") or foodName or "Food Item"

	local color = Color3.fromRGB(200, 200, 200)
	local material = Enum.Material.SmoothPlastic

	local foodModule = foodName and Foods:FindFirstChild(foodName)
	if foodModule then
		local ok, foodData = pcall(require, foodModule)
		if ok and foodData.Variants and rarity and foodData.Variants[rarity] then
			color = foodData.Variants[rarity].Color or color
			if rarity == "Epic" or rarity == "Legendary" or rarity == "Secret" then
				material = Enum.Material.Neon
			end
		end
	end

	local tool = Instance.new("Tool")
	tool.Name = displayName
	tool.RequiresHandle = true
	tool.CanBeDropped = false

	tool:SetAttribute("FoodName", foodName)
	tool:SetAttribute("Rarity", rarity)
	tool:SetAttribute("DisplayName", displayName)
	tool:SetAttribute("ValueMultiplier", menuItem:GetAttribute("ValueMultiplier"))
	tool:SetAttribute("BaseRestaurantValue", menuItem:GetAttribute("BaseRestaurantValue"))

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 0.3, 1)
	handle.Shape = Enum.PartType.Cylinder
	handle.Color = color
	handle.Material = material
	handle.CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(90))
	handle.Parent = tool

	return tool
end

AddFoodToMenu.OnServerEvent:Connect(function(player, tool)
	if typeof(tool) ~= "Instance" or not tool:IsA("Tool") or not tool:GetAttribute("FoodName") then
		return
	end

	local backpack = player:FindFirstChild("Backpack")
	local character = player.Character
	local ownsTool = (backpack and tool:IsDescendantOf(backpack)) or (character and tool:IsDescendantOf(character))
	if not ownsTool then
		return
	end

	local plot = PlotUtils.getPlotForPlayer(plotsFolder, player)
	if not plot then
		Notify:FireClient(player, "You need your own restaurant plot first!", Color3.fromRGB(255, 120, 120))
		return
	end

	local menu = plot:FindFirstChild("Menu")
	local maxSlots = Upgrades.GetMaxMenuSlots(plot)
	if menu and #menu:GetChildren() >= maxSlots then
		Notify:FireClient(player, "Your menu is full (" .. maxSlots .. " slots) - remove something first!", Color3.fromRGB(255, 180, 120))
		return
	end

	local displayName = tool:GetAttribute("DisplayName") or tool.Name
	addToMenu(plot, tool)
	tool:Destroy()

	Notify:FireClient(player, "Added " .. displayName .. " to your menu!", Color3.fromRGB(140, 230, 140))
end)

RemoveMenuItem.OnServerEvent:Connect(function(player, menuItem)
	if typeof(menuItem) ~= "Instance" or menuItem.Name ~= "MenuItem" then
		return
	end

	local plot = PlotUtils.getPlotForPlayer(plotsFolder, player)
	if not plot then
		return
	end

	local menu = plot:FindFirstChild("Menu")
	if not menu or menuItem.Parent ~= menu then
		return -- not this player's own menu item
	end

	local backpack = player:FindFirstChild("Backpack")
	if not backpack then
		return
	end

	local displayName = menuItem:GetAttribute("DisplayName") or "item"
	local tool = toolFromMenuItem(menuItem)
	tool.Parent = backpack

	menuItem:Destroy()
	plot:SetAttribute("MenuCount", #menu:GetChildren())

	Notify:FireClient(player, "Removed " .. displayName .. " - it's back in your backpack!", Color3.fromRGB(140, 230, 140))
end)
