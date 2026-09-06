local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local hub = Workspace:WaitForChild("Hub")
local plazaPoint = hub:WaitForChild("PlazaTeleportPoint")

local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("TeleportToPlaza")

remote.OnServerEvent:Connect(function(player)
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Small random offset so multiple players don't stack exactly on top of each other.
	local offset = Vector3.new(math.random(-6, 6), 0, math.random(-6, 6))
	local targetPos = plazaPoint.Position + offset
	hrp.CFrame = CFrame.new(Vector3.new(targetPos.X, plazaPoint.Position.Y + 2, targetPos.Z))
end)
