local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ShopCatalog = require(ReplicatedStorage.Data.ShopCatalog)
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local teleportToPlaza = remotes:WaitForChild("TeleportToPlaza")
local notifyRemote = remotes:FindFirstChild("Notify")

----------------------------------------------------------------
-- Top bar buttons (Shop / Plaza), placed next to the wallet
----------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "ShopPlazaGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = playerGui

local function makeTopBarButton(name, text, xOffset, color)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.AnchorPoint = Vector2.new(1, 0)
	btn.Position = UDim2.new(1, xOffset, 0, 90)
	btn.Size = UDim2.new(0, 110, 0, 50)
	btn.BackgroundColor3 = color
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextScaled = true
	btn.Text = text
	btn.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = btn

	return btn
end

local shopButton = makeTopBarButton("ShopButton", "SHOP", -16, Color3.fromRGB(60, 170, 90))
local plazaButton = makeTopBarButton("PlazaButton", "PLAZA", -142, Color3.fromRGB(60, 120, 200))

----------------------------------------------------------------
-- Plaza teleport button
----------------------------------------------------------------

local plazaDebounce = false
plazaButton.MouseButton1Click:Connect(function()
	if plazaDebounce then return end
	plazaDebounce = true
	teleportToPlaza:FireServer()
	task.wait(1)
	plazaDebounce = false
end)

----------------------------------------------------------------
-- Shop panel
----------------------------------------------------------------

local shopFrame = Instance.new("Frame")
shopFrame.Name = "ShopFrame"
shopFrame.AnchorPoint = Vector2.new(0.5, 0.5)
shopFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
shopFrame.Size = UDim2.new(0, 460, 0, 520)
shopFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
shopFrame.BorderSizePixel = 0
shopFrame.Visible = false
shopFrame.Parent = gui

local shopCorner = Instance.new("UICorner")
shopCorner.CornerRadius = UDim.new(0, 14)
shopCorner.Parent = shopFrame

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
titleBar.BorderSizePixel = 0
titleBar.Parent = shopFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 14)
titleCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -50, 1, 0)
titleLabel.Position = UDim2.new(0, 16, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "SHOP"
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled = true
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
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

-- Quick purchase featured section
local featuredFrame = Instance.new("Frame")
featuredFrame.Name = "FeaturedFrame"
featuredFrame.Position = UDim2.new(0, 12, 0, 62)
featuredFrame.Size = UDim2.new(1, -24, 0, 110)
featuredFrame.BackgroundColor3 = Color3.fromRGB(80, 60, 20)
featuredFrame.BorderSizePixel = 0
featuredFrame.Parent = shopFrame

local featuredCorner = Instance.new("UICorner")
featuredCorner.CornerRadius = UDim.new(0, 12)
featuredCorner.Parent = featuredFrame

local featuredTag = Instance.new("TextLabel")
featuredTag.Size = UDim2.new(1, -16, 0, 24)
featuredTag.Position = UDim2.new(0, 8, 0, 4)
featuredTag.BackgroundTransparency = 1
featuredTag.Text = "QUICK PURCHASE"
featuredTag.Font = Enum.Font.GothamBlack
featuredTag.TextColor3 = Color3.fromRGB(255, 210, 90)
featuredTag.TextScaled = true
featuredTag.TextXAlignment = Enum.TextXAlignment.Left
featuredTag.Parent = featuredFrame

local featuredName = Instance.new("TextLabel")
featuredName.Name = "FeaturedName"
featuredName.Size = UDim2.new(1, -16, 0, 26)
featuredName.Position = UDim2.new(0, 8, 0, 28)
featuredName.BackgroundTransparency = 1
featuredName.Text = ""
featuredName.Font = Enum.Font.GothamBold
featuredName.TextColor3 = Color3.fromRGB(255, 255, 255)
featuredName.TextScaled = true
featuredName.TextXAlignment = Enum.TextXAlignment.Left
featuredName.Parent = featuredFrame

local featuredDesc = Instance.new("TextLabel")
featuredDesc.Name = "FeaturedDesc"
featuredDesc.Size = UDim2.new(1, -140, 0, 40)
featuredDesc.Position = UDim2.new(0, 8, 0, 56)
featuredDesc.BackgroundTransparency = 1
featuredDesc.Text = ""
featuredDesc.Font = Enum.Font.Gotham
featuredDesc.TextColor3 = Color3.fromRGB(230, 230, 230)
featuredDesc.TextWrapped = true
featuredDesc.TextScaled = true
featuredDesc.TextXAlignment = Enum.TextXAlignment.Left
featuredDesc.TextYAlignment = Enum.TextYAlignment.Top
featuredDesc.Parent = featuredFrame

local featuredBuyButton = Instance.new("TextButton")
featuredBuyButton.Name = "FeaturedBuyButton"
featuredBuyButton.AnchorPoint = Vector2.new(1, 1)
featuredBuyButton.Position = UDim2.new(1, -8, 1, -8)
featuredBuyButton.Size = UDim2.new(0, 110, 0, 40)
featuredBuyButton.BackgroundColor3 = Color3.fromRGB(255, 190, 40)
featuredBuyButton.Font = Enum.Font.GothamBlack
featuredBuyButton.TextColor3 = Color3.fromRGB(40, 30, 0)
featuredBuyButton.TextScaled = true
featuredBuyButton.Text = "BUY"
featuredBuyButton.Parent = featuredFrame

local featuredBuyCorner = Instance.new("UICorner")
featuredBuyCorner.CornerRadius = UDim.new(0, 8)
featuredBuyCorner.Parent = featuredBuyButton

-- Full catalog scroll list
local listLabel = Instance.new("TextLabel")
listLabel.Size = UDim2.new(1, -24, 0, 24)
listLabel.Position = UDim2.new(0, 12, 0, 182)
listLabel.BackgroundTransparency = 1
listLabel.Text = "ALL ITEMS"
listLabel.Font = Enum.Font.GothamBold
listLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
listLabel.TextScaled = true
listLabel.TextXAlignment = Enum.TextXAlignment.Left
listLabel.Parent = shopFrame

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "CatalogList"
scrollFrame.Position = UDim2.new(0, 12, 0, 210)
scrollFrame.Size = UDim2.new(1, -24, 1, -222)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = shopFrame

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
		row.BackgroundColor3 = Color3.fromRGB(38, 38, 46)
		row.BorderSizePixel = 0
		row.Parent = scrollFrame

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 10)
		rowCorner.Parent = row

		local kindTag = Instance.new("TextLabel")
		kindTag.Size = UDim2.new(0, 90, 0, 18)
		kindTag.Position = UDim2.new(0, 10, 0, 6)
		kindTag.BackgroundTransparency = 1
		kindTag.Text = item.Kind == "GamePass" and "GAME PASS" or "CASH PACK"
		kindTag.Font = Enum.Font.GothamBold
		kindTag.TextColor3 = item.Kind == "GamePass" and Color3.fromRGB(150, 190, 255) or Color3.fromRGB(150, 255, 170)
		kindTag.TextScaled = true
		kindTag.TextXAlignment = Enum.TextXAlignment.Left
		kindTag.Parent = row

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -130, 0, 20)
		nameLabel.Position = UDim2.new(0, 10, 0, 22)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = item.Name
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextScaled = true
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = row

		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(1, -130, 0, 18)
		descLabel.Position = UDim2.new(0, 10, 0, 42)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = item.Description
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextColor3 = Color3.fromRGB(190, 190, 195)
		descLabel.TextScaled = true
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.Parent = row

		local buyButton = Instance.new("TextButton")
		buyButton.AnchorPoint = Vector2.new(1, 0.5)
		buyButton.Position = UDim2.new(1, -10, 0.5, 0)
		buyButton.Size = UDim2.new(0, 90, 0, 40)
		buyButton.BackgroundColor3 = Color3.fromRGB(60, 170, 90)
		buyButton.Font = Enum.Font.GothamBlack
		buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		buyButton.TextScaled = true
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

local shopOpen = false
local function setShopOpen(open)
	shopOpen = open
	shopFrame.Visible = open
	if open then
		rollFeaturedItem()
	end
end

shopButton.MouseButton1Click:Connect(function()
	setShopOpen(not shopOpen)
end)

closeButton.MouseButton1Click:Connect(function()
	setShopOpen(false)
end)
