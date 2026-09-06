local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer

local HudDock = require(script.Parent:WaitForChild("HudDock"))
local Theme = HudDock.Theme

local ShopCatalog = require(ReplicatedStorage.Data.ShopCatalog)
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local teleportToPlaza = remotes:WaitForChild("TeleportToPlaza")

----------------------------------------------------------------
-- Plaza teleport (dock button, no panel)
----------------------------------------------------------------

local plazaDebounce = false
local function goToPlaza()
	if plazaDebounce then return end
	plazaDebounce = true
	HudDock.closeOthers("plaza")
	teleportToPlaza:FireServer()
	task.wait(1)
	plazaDebounce = false
end

HudDock.register({
	id = "plaza",
	label = "PLAZA",
	icon = "✈️",
	order = 40,
	accent = Color3.fromRGB(96, 150, 196),
	onActivate = goToPlaza,
})

----------------------------------------------------------------
-- Shop panel
----------------------------------------------------------------

local panel = HudDock.makePanel("SHOP", UDim2.new(0, 470, 0, 540))

-- Quick purchase featured section
local featuredFrame = Instance.new("Frame")
featuredFrame.Name = "FeaturedFrame"
featuredFrame.Size = UDim2.new(1, 0, 0, 110)
featuredFrame.BackgroundColor3 = Theme.Wood
featuredFrame.BorderSizePixel = 0
featuredFrame.Parent = panel.body

local featuredCorner = Instance.new("UICorner")
featuredCorner.CornerRadius = UDim.new(0, 12)
featuredCorner.Parent = featuredFrame

local featuredTag = Instance.new("TextLabel")
featuredTag.Size = UDim2.new(1, -16, 0, 22)
featuredTag.Position = UDim2.new(0, 10, 0, 6)
featuredTag.BackgroundTransparency = 1
featuredTag.Text = "TODAY'S SPECIAL"
featuredTag.Font = Theme.TitleFont
featuredTag.TextSize = 16
featuredTag.TextColor3 = Theme.Butter
featuredTag.TextXAlignment = Enum.TextXAlignment.Left
featuredTag.Parent = featuredFrame

local featuredName = Instance.new("TextLabel")
featuredName.Name = "FeaturedName"
featuredName.Size = UDim2.new(1, -16, 0, 24)
featuredName.Position = UDim2.new(0, 10, 0, 30)
featuredName.BackgroundTransparency = 1
featuredName.Text = ""
featuredName.Font = Theme.BodyBoldFont
featuredName.TextSize = 17
featuredName.TextColor3 = Theme.TextLight
featuredName.TextXAlignment = Enum.TextXAlignment.Left
featuredName.Parent = featuredFrame

local featuredDesc = Instance.new("TextLabel")
featuredDesc.Name = "FeaturedDesc"
featuredDesc.Size = UDim2.new(1, -140, 0, 40)
featuredDesc.Position = UDim2.new(0, 10, 0, 56)
featuredDesc.BackgroundTransparency = 1
featuredDesc.Text = ""
featuredDesc.Font = Theme.BodyFont
featuredDesc.TextSize = 13
featuredDesc.TextColor3 = Color3.fromRGB(226, 214, 190)
featuredDesc.TextWrapped = true
featuredDesc.TextXAlignment = Enum.TextXAlignment.Left
featuredDesc.TextYAlignment = Enum.TextYAlignment.Top
featuredDesc.Parent = featuredFrame

local featuredBuyButton = Instance.new("TextButton")
featuredBuyButton.Name = "FeaturedBuyButton"
featuredBuyButton.AnchorPoint = Vector2.new(1, 1)
featuredBuyButton.Position = UDim2.new(1, -8, 1, -8)
featuredBuyButton.Size = UDim2.new(0, 112, 0, 40)
featuredBuyButton.BackgroundColor3 = Theme.Butter
featuredBuyButton.Font = Theme.TitleFont
featuredBuyButton.TextColor3 = Theme.InkBrown
featuredBuyButton.TextSize = 18
featuredBuyButton.Text = "BUY"
featuredBuyButton.Parent = featuredFrame

local featuredBuyCorner = Instance.new("UICorner")
featuredBuyCorner.CornerRadius = UDim.new(0, 8)
featuredBuyCorner.Parent = featuredBuyButton

-- Full catalog scroll list
local listLabel = Instance.new("TextLabel")
listLabel.Size = UDim2.new(1, 0, 0, 22)
listLabel.Position = UDim2.new(0, 2, 0, 122)
listLabel.BackgroundTransparency = 1
listLabel.Text = "ALL ITEMS"
listLabel.Font = Theme.TitleFont
listLabel.TextSize = 15
listLabel.TextColor3 = Color3.fromRGB(120, 98, 68)
listLabel.TextXAlignment = Enum.TextXAlignment.Left
listLabel.Parent = panel.body

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "CatalogList"
scrollFrame.Position = UDim2.new(0, 0, 0, 148)
scrollFrame.Size = UDim2.new(1, 0, 1, -148)
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

local function promptPurchase(item)
	local ok, err = pcall(function()
		if item.Kind == "DeveloperProduct" then
			MarketplaceService:PromptProductPurchase(player, item.ProductId)
		elseif item.Kind == "GamePass" then
			MarketplaceService:PromptGamePassPurchase(player, item.ProductId)
		end
	end)
	if not ok then
		warn("[Shop] Purchase prompt failed for", item.Id, "-", err)
		-- Placeholder IDs won't resolve to real products/passes until they're
		-- created on the Creator Dashboard and swapped in on the server.
	end
end

local function buildCatalogRows()
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	for i, item in ipairs(ShopCatalog) do
		local row = Instance.new("Frame")
		row.Name = item.Id
		row.LayoutOrder = i
		row.Size = UDim2.new(1, 0, 0, 64)
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

		local kindTag = Instance.new("TextLabel")
		kindTag.Size = UDim2.new(0, 100, 0, 16)
		kindTag.Position = UDim2.new(0, 12, 0, 7)
		kindTag.BackgroundTransparency = 1
		kindTag.Text = item.Kind == "GamePass" and "GAME PASS" or "CASH PACK"
		kindTag.Font = Theme.BodyBoldFont
		kindTag.TextSize = 11
		kindTag.TextColor3 = item.Kind == "GamePass" and Color3.fromRGB(74, 108, 150) or Theme.Basil
		kindTag.TextXAlignment = Enum.TextXAlignment.Left
		kindTag.Parent = row

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -130, 0, 20)
		nameLabel.Position = UDim2.new(0, 12, 0, 22)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = item.Name
		nameLabel.Font = Theme.BodyBoldFont
		nameLabel.TextSize = 15
		nameLabel.TextColor3 = Theme.InkBrown
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = row

		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(1, -130, 0, 16)
		descLabel.Position = UDim2.new(0, 12, 0, 42)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = item.Description
		descLabel.Font = Theme.BodyFont
		descLabel.TextSize = 12
		descLabel.TextColor3 = Color3.fromRGB(96, 78, 54)
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.Parent = row

		local buyButton = Instance.new("TextButton")
		buyButton.AnchorPoint = Vector2.new(1, 0.5)
		buyButton.Position = UDim2.new(1, -12, 0.5, 0)
		buyButton.Size = UDim2.new(0, 92, 0, 42)
		buyButton.BackgroundColor3 = Theme.Basil
		buyButton.Font = Theme.TitleFont
		buyButton.TextColor3 = Theme.TextLight
		buyButton.TextSize = 16
		buyButton.Text = "BUY"
		buyButton.Parent = row

		local buyCorner = Instance.new("UICorner")
		buyCorner.CornerRadius = UDim.new(0, 8)
		buyCorner.Parent = buyButton

		buyButton.MouseButton1Click:Connect(function()
			promptPurchase(item)
		end)
	end
end

local currentFeatured = nil

local function rollFeaturedItem()
	currentFeatured = ShopCatalog[math.random(1, #ShopCatalog)]
	featuredName.Text = currentFeatured.Name
	featuredDesc.Text = currentFeatured.Description .. "  (" .. (currentFeatured.Kind == "GamePass" and "Game Pass" or "Cash Pack") .. ")"
end

featuredBuyButton.MouseButton1Click:Connect(function()
	if currentFeatured then
		promptPurchase(currentFeatured)
	end
end)

buildCatalogRows()

local dockEntry
local function setShopOpen(open)
	if open then
		HudDock.closeOthers("shop")
	end
	panel:setOpen(open)
	if dockEntry then
		dockEntry.setActive(open)
	end
	if open then
		rollFeaturedItem()
	end
end

panel.onClose = function()
	if dockEntry then
		dockEntry.setActive(false)
	end
end

dockEntry = HudDock.register({
	id = "shop",
	label = "SHOP",
	icon = "🛒",
	order = 20,
	accent = Theme.Basil,
	onActivate = function()
		setShopOpen(not panel:isOpen())
	end,
	close = function()
		setShopOpen(false)
	end,
})
