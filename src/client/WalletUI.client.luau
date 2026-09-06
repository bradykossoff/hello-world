local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "WalletGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Name = "WalletFrame"
frame.AnchorPoint = Vector2.new(0, 0)
frame.Position = UDim2.new(0, 16, 0, 16)
frame.Size = UDim2.new(0, 180, 0, 50)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
frame.BackgroundTransparency = 0.25
frame.BorderSizePixel = 0
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local icon = Instance.new("TextLabel")
icon.Name = "Icon"
icon.Size = UDim2.new(0, 40, 1, 0)
icon.BackgroundTransparency = 1
icon.Text = "$"
icon.Font = Enum.Font.GothamBlack
icon.TextColor3 = Color3.fromRGB(120, 230, 140)
icon.TextScaled = true
icon.Parent = frame

local moneyLabel = Instance.new("TextLabel")
moneyLabel.Name = "MoneyLabel"
moneyLabel.Position = UDim2.new(0, 40, 0, 0)
moneyLabel.Size = UDim2.new(1, -50, 1, 0)
moneyLabel.BackgroundTransparency = 1
moneyLabel.Text = "0"
moneyLabel.Font = Enum.Font.GothamBold
moneyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
moneyLabel.TextScaled = true
moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
moneyLabel.Parent = frame

local function updateMoney()
	local amount = player:GetAttribute("Money") or 0
	moneyLabel.Text = tostring(amount)
end

player:GetAttributeChangedSignal("Money"):Connect(updateMoney)
updateMoney()
