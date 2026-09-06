local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local HudDock = require(script.Parent:WaitForChild("HudDock"))

local UpgradeCatalog = require(ReplicatedStorage.Data.UpgradeCatalog)
local Foods = ReplicatedStorage.Data.Foods

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local AddFoodToMenu = remotes:WaitForChild("AddFoodToMenu")
local RemoveMenuItem = remotes:WaitForChild("RemoveMenuItem")

local plotsFolder = Workspace:WaitForChild("Plots")

local PAGE_BG = Color3.fromRGB(238, 226, 195)
local PAGE_TEXT = Color3.fromRGB(60, 45, 25)
local SPINE_COLOR = Color3.fromRGB(90, 55, 30)

local function getRarityColor(foodName, rarity)
	local foodModule = foodName and Foods:FindFirstChild(foodName)
	if foodModule then
		local ok, foodData = pcall(require, foodModule)
		if ok and foodData.Variants and rarity and foodData.Variants[rarity] then
			return foodData.Variants[rarity].Color
		end
	end
	return PAGE_TEXT
end

local function findMyPlot()
	for _, plot in ipairs(plotsFolder:GetChildren()) do
		if plot:GetAttribute("OwnerUserId") == player.UserId then
			return plot
		end
	end
	return nil
end

local function getMaxSlots(plot)
	local track = UpgradeCatalog.MenuSlots
	local level = plot:GetAttribute(UpgradeCatalog.Meta.AttributeNames.MenuSlots) or UpgradeCatalog.Meta.DefaultLevels.MenuSlots
	return track.BaseSlots + level * track.SlotsPerLevel
end

local function getFoodTools()
	local tools = {}
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") and item:GetAttribute("FoodName") then
				table.insert(tools, item)
			end
		end
	end
	local character = player.Character
	if character then
		for _, item in ipairs(character:GetChildren()) do
			if item:IsA("Tool") and item:GetAttribute("FoodName") then
				table.insert(tools, item)
			end
		end
	end
	return tools
end

----------------------------------------------------------------
-- Book UI
----------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "MenuBookGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 9
gui.Parent = playerGui

local book = Instance.new("Frame")
book.Name = "Book"
book.AnchorPoint = Vector2.new(0.5, 0.5)
book.Position = UDim2.new(0.5, 0, 0.5, 0)
book.Size = UDim2.new(0, 720, 0, 440)
book.BackgroundColor3 = Color3.fromRGB(60, 40, 25)
book.BorderSizePixel = 0
book.Visible = false
book.Parent = gui

local bookCorner = Instance.new("UICorner")
bookCorner.CornerRadius = UDim.new(0, 16)
bookCorner.Parent = book

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -10, 0, 10)
closeButton.Size = UDim2.new(0, 32, 0, 32)
closeButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
closeButton.Text = "X"
closeButton.Font = Enum.Font.GothamBold
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextScaled = true
closeButton.ZIndex = 5
closeButton.Parent = book

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

local function createPage(name, xPos, title)
	local page = Instance.new("Frame")
	page.Name = name
	page.Position = UDim2.new(0, xPos, 0, 12)
	page.Size = UDim2.new(0, 344, 1, -24)
	page.BackgroundColor3 = PAGE_BG
	page.BorderSizePixel = 0
	page.Parent = book

	local pageCorner = Instance.new("UICorner")
	pageCorner.CornerRadius = UDim.new(0, 10)
	pageCorner.Parent = page

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -16, 0, 34)
	titleLabel.Position = UDim2.new(0, 8, 0, 8)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextColor3 = PAGE_TEXT
	titleLabel.TextScaled = true
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = page

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "List"
	scrollFrame.Position = UDim2.new(0, 8, 0, 48)
	scrollFrame.Size = UDim2.new(1, -16, 1, -56)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.Parent = page

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scrollFrame

	return page, scrollFrame
end

local menuPage, menuList = createPage("MenuPage", 12, "YOUR MENU")

local spine = Instance.new("Frame")
spine.Name = "Spine"
spine.AnchorPoint = Vector2.new(0.5, 0)
spine.Position = UDim2.new(0.5, 0, 0, 12)
spine.Size = UDim2.new(0, 8, 1, -24)
spine.BackgroundColor3 = SPINE_COLOR
spine.BorderSizePixel = 0
spine.ZIndex = 2
spine.Parent = book

local foodPage, foodList = createPage("FoodPage", 364, "YOUR FOOD")

local function makeRow(parent, layoutOrder, nameText, nameColor, buttonText, buttonColor, onClick)
	local row = Instance.new("Frame")
	row.Name = "Row" .. tostring(layoutOrder)
	row.LayoutOrder = layoutOrder
	row.Size = UDim2.new(1, 0, 0, 48)
	row.BackgroundColor3 = Color3.fromRGB(255, 250, 235)
	row.BorderSizePixel = 0
	row.Parent = parent

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 8)
	rowCorner.Parent = row

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -80, 1, 0)
	nameLabel.Position = UDim2.new(0, 10, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = nameText
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = nameColor
	nameLabel.TextScaled = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = row

	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.new(1, -8, 0.5, 0)
	button.Size = UDim2.new(0, 66, 0, 34)
	button.BackgroundColor3 = buttonColor
	button.Font = Enum.Font.GothamBlack
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextScaled = true
	button.Text = buttonText
	button.Parent = row

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = button

	if onClick then
		button.MouseButton1Click:Connect(onClick)
	end

	return row
end

local function refresh()
	local plot = findMyPlot()

	for _, child in ipairs(menuList:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	for _, child in ipairs(foodList:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	if not plot then
		makeRow(menuList, 1, "You don't have a restaurant yet!", Color3.fromRGB(150, 140, 120), "", Color3.fromRGB(220, 210, 190), nil)
		return
	end

	local menu = plot:FindFirstChild("Menu")
	local menuItems = menu and menu:GetChildren() or {}
	local maxSlots = getMaxSlots(plot)

	for i = 1, maxSlots do
		local item = menuItems[i]
		if item then
			local rarity = item:GetAttribute("Rarity")
			local color = getRarityColor(item:GetAttribute("FoodName"), rarity)
			makeRow(menuList, i, (item:GetAttribute("DisplayName") or "Food") .. "  [" .. tostring(rarity) .. "]", color, "Remove", Color3.fromRGB(180, 70, 70), function()
				RemoveMenuItem:FireServer(item)
			end)
		else
			makeRow(menuList, i, "Empty Slot", Color3.fromRGB(150, 140, 120), "", Color3.fromRGB(220, 210, 190), nil)
		end
	end

	local foodTools = getFoodTools()
	if #foodTools == 0 then
		makeRow(foodList, 1, "No food in your backpack", Color3.fromRGB(150, 140, 120), "", Color3.fromRGB(220, 210, 190), nil)
	else
		for i, tool in ipairs(foodTools) do
			local rarity = tool:GetAttribute("Rarity")
			local color = getRarityColor(tool:GetAttribute("FoodName"), rarity)
			makeRow(foodList, i, (tool:GetAttribute("DisplayName") or tool.Name) .. "  [" .. tostring(rarity) .. "]", color, "Add", Color3.fromRGB(70, 150, 90), function()
				AddFoodToMenu:FireServer(tool)
			end)
		end
	end
end

local boundPlot = nil
local backpackConn, characterConn, menuConn, menuCountConn

local function disconnectAll()
	if backpackConn then backpackConn:Disconnect() end
	if characterConn then characterConn:Disconnect() end
	if menuConn then menuConn:Disconnect() end
	if menuCountConn then menuCountConn:Disconnect() end
end

local function bindToPlot(plot)
	disconnectAll()
	boundPlot = plot

	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		backpackConn = backpack.ChildAdded:Connect(refresh)
		backpack.ChildRemoved:Connect(refresh)
	end
	if player.Character then
		characterConn = player.Character.ChildAdded:Connect(refresh)
		player.Character.ChildRemoved:Connect(refresh)
	end

	if plot then
		local menu = plot:FindFirstChild("Menu")
		if menu then
			menuConn = menu.ChildAdded:Connect(refresh)
			menu.ChildRemoved:Connect(refresh)
		end
		menuCountConn = plot:GetAttributeChangedSignal("MenuCount"):Connect(refresh)
	end

	refresh()
end

local dockEntry
local isOpen = false
local function setOpen(open)
	isOpen = open
	if open then
		HudDock.closeOthers("menu")
	end
	if dockEntry then
		dockEntry.setActive(open)
	end
	if open then
		book.Visible = true
		book.Size = UDim2.new(0, 0, 0, 0)
		bindToPlot(findMyPlot())
		TweenService:Create(book, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 720, 0, 440),
		}):Play()
	else
		book.Visible = false
	end
end

closeButton.MouseButton1Click:Connect(function()
	setOpen(false)
end)

dockEntry = HudDock.register({
	id = "menu",
	label = "MENU",
	icon = "🍽️",
	order = 10,
	accent = HudDock.Theme.Butter,
	onActivate = function()
		setOpen(not isOpen)
	end,
	close = function()
		setOpen(false)
	end,
})
