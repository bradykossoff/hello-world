local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local UpgradeCatalog = require(ReplicatedStorage.Data.UpgradeCatalog)
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local OpenUpgradePanel = remotes:WaitForChild("OpenUpgradePanel")
local PurchaseUpgrade = remotes:WaitForChild("PurchaseUpgrade")

local plotsFolder = Workspace:WaitForChild("Plots")

-- Mirrors Upgrades.GetCost server-side (display only - the server is always
-- the source of truth and re-validates every purchase).
local function getDisplayCost(trackName, currentLevel)
	local track = UpgradeCatalog[trackName]
	if trackName == "KitchenStage" then
		if currentLevel >= track.MaxLevel then return nil end
		return track.UpgradeCost[currentLevel]
	end
	if currentLevel >= track.MaxLevel then return nil end
	return math.floor(track.BaseCost * (track.CostGrowth ^ (currentLevel - track.MinLevel)))
end

local function getLevel(plot, trackName)
	local attr = UpgradeCatalog.Meta.AttributeNames[trackName]
	local value = plot:GetAttribute(attr)
	if value == nil then return UpgradeCatalog.Meta.DefaultLevels[trackName] end
	return value
end

local function findMyPlot()
	for _, plot in ipairs(plotsFolder:GetChildren()) do
		if plot:GetAttribute("OwnerUserId") == player.UserId then
			return plot
		end
	end
	return nil
end

----------------------------------------------------------------
-- Panel UI
----------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "UpgradeGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Name = "UpgradeFrame"
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
frame.Size = UDim2.new(0, 480, 0, 460)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
frame.BorderSizePixel = 0
frame.Visible = false
frame.Parent = gui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 14)
frameCorner.Parent = frame

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
titleBar.BorderSizePixel = 0
titleBar.Parent = frame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 14)
titleCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -50, 1, 0)
titleLabel.Position = UDim2.new(0, 16, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "UPGRADES"
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled = true
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

local closeButton = Instance.new("TextButton")
closeButton.AnchorPoint = Vector2.new(1, 0.5)
closeButton.Position = UDim2.new(1, -10, 0.5, 0)
closeButton.Size = UDim2.new(0, 32, 0, 32)
closeButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
closeButton.Text = "X"
closeButton.Font = Enum.Font.GothamBold
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextScaled = true
closeButton.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Position = UDim2.new(0, 12, 0, 62)
scrollFrame.Size = UDim2.new(1, -24, 1, -74)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = frame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scrollFrame

local rows = {}

local function buildRows()
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	table.clear(rows)

	for i, trackName in ipairs(UpgradeCatalog.Meta.TrackOrder) do
		local track = UpgradeCatalog[trackName]

		local row = Instance.new("Frame")
		row.Name = trackName
		row.LayoutOrder = i
		row.Size = UDim2.new(1, 0, 0, 78)
		row.BackgroundColor3 = Color3.fromRGB(38, 38, 46)
		row.BorderSizePixel = 0
		row.Parent = scrollFrame

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 10)
		rowCorner.Parent = row

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.Size = UDim2.new(1, -120, 0, 22)
		nameLabel.Position = UDim2.new(0, 10, 0, 6)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = track.DisplayName .. "  (Lv. ?)"
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextScaled = true
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = row

		local descLabel = Instance.new("TextLabel")
		descLabel.Name = "DescLabel"
		descLabel.Size = UDim2.new(1, -120, 0, 34)
		descLabel.Position = UDim2.new(0, 10, 0, 28)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = track.Description
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextColor3 = Color3.fromRGB(190, 190, 195)
		descLabel.TextWrapped = true
		descLabel.TextScaled = true
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextYAlignment = Enum.TextYAlignment.Top
		descLabel.Parent = row

		local buyButton = Instance.new("TextButton")
		buyButton.Name = "BuyButton"
		buyButton.AnchorPoint = Vector2.new(1, 0.5)
		buyButton.Position = UDim2.new(1, -10, 0.5, 0)
		buyButton.Size = UDim2.new(0, 100, 0, 44)
		buyButton.BackgroundColor3 = Color3.fromRGB(60, 170, 90)
		buyButton.Font = Enum.Font.GothamBlack
		buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		buyButton.TextScaled = true
		buyButton.Text = "$?"
		buyButton.Parent = row

		local buyCorner = Instance.new("UICorner")
		buyCorner.CornerRadius = UDim.new(0, 8)
		buyCorner.Parent = buyButton

		buyButton.MouseButton1Click:Connect(function()
			PurchaseUpgrade:FireServer(trackName)
		end)

		rows[trackName] = { nameLabel = nameLabel, buyButton = buyButton }
	end
end

local function refreshRows()
	local plot = findMyPlot()
	if not plot then return end

	for trackName, row in pairs(rows) do
		local track = UpgradeCatalog[trackName]
		local level = getLevel(plot, trackName)
		local cost = getDisplayCost(trackName, level)

		local levelText
		if trackName == "KitchenStage" then
			levelText = track.Names[level] or ("Lv. " .. level)
		else
			levelText = "Lv. " .. level
		end
		row.nameLabel.Text = track.DisplayName .. "  (" .. levelText .. ")"

		if cost then
			row.buyButton.Text = "$" .. cost
			row.buyButton.BackgroundColor3 = Color3.fromRGB(60, 170, 90)
			row.buyButton.Active = true
		else
			row.buyButton.Text = "MAX"
			row.buyButton.BackgroundColor3 = Color3.fromRGB(90, 90, 100)
			row.buyButton.Active = false
		end
	end
end

buildRows()

local upgradeAttributeNames = {}
for _, attr in pairs(UpgradeCatalog.Meta.AttributeNames) do
	table.insert(upgradeAttributeNames, attr)
end

local boundPlot = nil
local function bindToPlot(plot)
	if boundPlot == plot then return end
	boundPlot = plot
	if not plot then return end
	for _, attr in ipairs(upgradeAttributeNames) do
		plot:GetAttributeChangedSignal(attr):Connect(refreshRows)
	end
	refreshRows()
end

local isOpen = false
local function setOpen(open)
	isOpen = open
	frame.Visible = open
	if open then
		bindToPlot(findMyPlot())
		refreshRows()
	end
end

OpenUpgradePanel.OnClientEvent:Connect(function()
	setOpen(true)
end)

closeButton.MouseButton1Click:Connect(function()
	setOpen(false)
end)
