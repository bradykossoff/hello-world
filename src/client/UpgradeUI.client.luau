local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local HudDock = require(script.Parent:WaitForChild("HudDock"))
local Theme = HudDock.Theme

local UpgradeCatalog = require(ReplicatedStorage.Data.UpgradeCatalog)
local remotes = ReplicatedStorage:WaitForChild("Remotes")
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
-- Panel
----------------------------------------------------------------

local panel = HudDock.makePanel("UPGRADES", UDim2.new(0, 480, 0, 470))

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, 0, 1, 0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.ScrollBarImageColor3 = Theme.Wood
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = panel.body

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scrollFrame

local emptyLabel = Instance.new("TextLabel")
emptyLabel.Size = UDim2.new(1, 0, 1, 0)
emptyLabel.BackgroundTransparency = 1
emptyLabel.Font = Theme.BodyBoldFont
emptyLabel.TextSize = 16
emptyLabel.TextWrapped = true
emptyLabel.TextColor3 = Theme.InkBrown
emptyLabel.Text = "Claim a restaurant plot first —\nthen come back to upgrade it!"
emptyLabel.Visible = false
emptyLabel.Parent = panel.body

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
		row.BackgroundColor3 = Theme.ParchmentDim
		row.BorderSizePixel = 0
		row.Parent = scrollFrame

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 10)
		rowCorner.Parent = row

		local rowStroke = Instance.new("UIStroke")
		rowStroke.Color = Theme.Wood
		rowStroke.Thickness = 1.5
		rowStroke.Transparency = 0.5
		rowStroke.Parent = row

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.Size = UDim2.new(1, -130, 0, 24)
		nameLabel.Position = UDim2.new(0, 12, 0, 8)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = track.DisplayName .. "  (Lv. ?)"
		nameLabel.Font = Theme.TitleFont
		nameLabel.TextSize = 18
		nameLabel.TextColor3 = Theme.InkBrown
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = row

		local descLabel = Instance.new("TextLabel")
		descLabel.Name = "DescLabel"
		descLabel.Size = UDim2.new(1, -130, 0, 38)
		descLabel.Position = UDim2.new(0, 12, 0, 32)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = track.Description
		descLabel.Font = Theme.BodyFont
		descLabel.TextSize = 13
		descLabel.TextColor3 = Color3.fromRGB(96, 78, 54)
		descLabel.TextWrapped = true
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextYAlignment = Enum.TextYAlignment.Top
		descLabel.Parent = row

		local buyButton = Instance.new("TextButton")
		buyButton.Name = "BuyButton"
		buyButton.AnchorPoint = Vector2.new(1, 0.5)
		buyButton.Position = UDim2.new(1, -12, 0.5, 0)
		buyButton.Size = UDim2.new(0, 104, 0, 46)
		buyButton.BackgroundColor3 = Theme.Basil
		buyButton.Font = Theme.TitleFont
		buyButton.TextColor3 = Theme.TextLight
		buyButton.TextSize = 18
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

	emptyLabel.Visible = plot == nil
	scrollFrame.Visible = plot ~= nil
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
			row.buyButton.BackgroundColor3 = Theme.Basil
			row.buyButton.Active = true
		else
			row.buyButton.Text = "MAX"
			row.buyButton.BackgroundColor3 = Theme.Wood
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

local dockEntry
local function setOpen(open)
	if open then
		HudDock.closeOthers("upgrades")
	end
	panel:setOpen(open)
	if dockEntry then
		dockEntry.setActive(open)
	end
	if open then
		bindToPlot(findMyPlot())
		refreshRows()
	end
end

panel.onClose = function()
	if dockEntry then
		dockEntry.setActive(false)
	end
end

dockEntry = HudDock.register({
	id = "upgrades",
	label = "UPGRADES",
	icon = "⬆️",
	order = 30,
	accent = Theme.Butter,
	onActivate = function()
		setOpen(not panel:isOpen())
	end,
	close = function()
		setOpen(false)
	end,
})
