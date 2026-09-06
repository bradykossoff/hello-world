local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CustomerPaid = ReplicatedStorage.Remotes:WaitForChild("CustomerPaid")

local GAIN_COLOR = Color3.fromRGB(140, 230, 140)
local RISE = Vector3.new(0, 3, 0)
local LIFETIME = 1.5

-- Floating "+$" text over a chair when a customer pays. Built on the owner's
-- client only, so it never replicates.
CustomerPaid.OnClientEvent:Connect(function(position, value)
	local anchor = Instance.new("Part")
	anchor.Size = Vector3.new(0.1, 0.1, 0.1)
	anchor.Transparency = 1
	anchor.CanCollide = false
	anchor.Anchored = true
	anchor.CFrame = CFrame.new(position)
	anchor.Parent = workspace

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 100, 0, 40)
	billboard.AlwaysOnTop = true
	billboard.Parent = anchor

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "+$" .. tostring(value)
	label.TextColor3 = GAIN_COLOR
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = billboard

	TweenService:Create(billboard, TweenInfo.new(LIFETIME), { StudsOffset = RISE }):Play()
	TweenService:Create(label, TweenInfo.new(LIFETIME), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()

	task.delay(LIFETIME + 0.1, function()
		anchor:Destroy()
	end)
end)
