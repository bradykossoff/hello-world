local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local RarityTable = require(ReplicatedStorage.Data.RarityTable)
local RevealFood = ReplicatedStorage.Remotes:WaitForChild("RevealFood")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local rarityNames = {}
for _, tier in ipairs(RarityTable) do
	table.insert(rarityNames, tier.Name)
end

-- How dramatic the reveal is, scaled by rarity: more cycles + a screen flash for rarer tiers
local DRAMA = {
	Common = { cycles = 3, cycleTime = 0.08, flash = false, holdTime = 0.8 },
	Uncommon = { cycles = 5, cycleTime = 0.09, flash = false, holdTime = 1.0 },
	Rare = { cycles = 8, cycleTime = 0.1, flash = false, holdTime = 1.2 },
	Epic = { cycles = 12, cycleTime = 0.1, flash = true, holdTime = 1.6 },
	Legendary = { cycles = 18, cycleTime = 0.11, flash = true, holdTime = 2.0 },
	Secret = { cycles = 25, cycleTime = 0.12, flash = true, holdTime = 2.5 },
}

local gui = Instance.new("ScreenGui")
gui.Name = "FoodRevealGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 50
gui.Parent = playerGui

local flash = Instance.new("Frame")
flash.Name = "Flash"
flash.Size = UDim2.new(1, 0, 1, 0)
flash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
flash.BackgroundTransparency = 1
flash.ZIndex = 1
flash.Parent = gui

local container = Instance.new("Frame")
container.Name = "Container"
container.AnchorPoint = Vector2.new(0.5, 0.5)
container.Position = UDim2.new(0.5, 0, 0.4, 0)
container.Size = UDim2.new(0, 500, 0, 140)
container.BackgroundTransparency = 1
container.ZIndex = 2
container.Parent = gui

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0.4, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = ""
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextStrokeTransparency = 0
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextScaled = true
titleLabel.ZIndex = 2
titleLabel.Parent = container

local rarityLabel = Instance.new("TextLabel")
rarityLabel.Name = "RarityLabel"
rarityLabel.Size = UDim2.new(1, 0, 0.6, 0)
rarityLabel.Position = UDim2.new(0, 0, 0.4, 0)
rarityLabel.BackgroundTransparency = 1
rarityLabel.Text = ""
rarityLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
rarityLabel.TextStrokeTransparency = 0
rarityLabel.Font = Enum.Font.GothamBlack
rarityLabel.TextScaled = true
rarityLabel.ZIndex = 2
rarityLabel.Parent = container

local revealing = false

RevealFood.OnClientEvent:Connect(function(result)
	if revealing then return end
	revealing = true

	local drama = DRAMA[result.Rarity] or DRAMA.Common

	titleLabel.Text = "Obtaining " .. result.FoodName .. "..."
	rarityLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

	for i = 1, drama.cycles do
		rarityLabel.Text = rarityNames[math.random(1, #rarityNames)]
		task.wait(drama.cycleTime)
	end

	rarityLabel.Text = result.Rarity
	rarityLabel.TextColor3 = result.Color

	if drama.flash then
		flash.BackgroundTransparency = 0.2
		TweenService:Create(flash, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
	end

	if result.Rarity == "Secret" then
		titleLabel.Text = "A player just discovered SECRET " .. result.DisplayName .. "!"
	else
		titleLabel.Text = result.DisplayName
	end

	task.wait(drama.holdTime)

	local fadeTime = 0.5
	TweenService:Create(titleLabel, TweenInfo.new(fadeTime), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	TweenService:Create(rarityLabel, TweenInfo.new(fadeTime), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.wait(fadeTime + 0.1)

	titleLabel.TextTransparency = 0
	titleLabel.TextStrokeTransparency = 0
	rarityLabel.TextTransparency = 0
	rarityLabel.TextStrokeTransparency = 0
	titleLabel.Text = ""
	rarityLabel.Text = ""

	revealing = false
end)
