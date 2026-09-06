local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Notify = ReplicatedStorage.Remotes:WaitForChild("Notify")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "NotificationGui"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local label = Instance.new("TextLabel")
label.Name = "ToastLabel"
label.AnchorPoint = Vector2.new(0.5, 1)
label.Position = UDim2.new(0.5, 0, 0.85, 0)
label.Size = UDim2.new(0, 420, 0, 44)
label.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
label.BackgroundTransparency = 1
label.TextTransparency = 1
label.TextStrokeTransparency = 1
label.Font = Enum.Font.GothamBold
label.TextScaled = true
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.Text = ""
label.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = label

local currentTween
local hideThread

local function showToast(text, color)
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)

	if hideThread then
		task.cancel(hideThread)
		hideThread = nil
	end

	label.BackgroundTransparency = 0.2
	label.TextTransparency = 0
	label.TextStrokeTransparency = 0

	hideThread = task.delay(2, function()
		TweenService:Create(label, TweenInfo.new(0.4), {
			BackgroundTransparency = 1,
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		}):Play()
	end)
end

Notify.OnClientEvent:Connect(function(text, color)
	showToast(text, color)
end)
