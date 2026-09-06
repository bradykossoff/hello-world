local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ServerScriptService.Modules.Economy)
local Shop = require(ServerScriptService.Modules.Shop)
local Upgrades = require(ServerScriptService.Modules.Upgrades)
local Notify = ReplicatedStorage.Remotes:WaitForChild("Notify")
local CustomerPaid = ReplicatedStorage.Remotes:WaitForChild("CustomerPaid")

local plotsFolder = Workspace:WaitForChild("Plots")
local customersFolder = Workspace:WaitForChild("Customers")

local SPAWN_INTERVAL_MIN = 5
local SPAWN_INTERVAL_MAX = 9

-- Eating duration at Kitchen Speed level 1 (see Upgrades.GetEatSpeedMultiplier
-- for how higher levels shrink this). Deliberately long relative to the spawn
-- interval so that with multiple seats per plot, new customers reliably
-- arrive and sit down while others are still eating.
local BASE_EAT_TIME_MIN = 14
local BASE_EAT_TIME_MAX = 20

local WALK_DURATION = 3

local CHAIR_NAMES = { "Chair1", "Chair2" }

local CUSTOMER_COLORS = {
	Color3.fromRGB(240, 180, 150),
	Color3.fromRGB(200, 150, 220),
	Color3.fromRGB(150, 200, 240),
	Color3.fromRGB(240, 220, 140),
	Color3.fromRGB(180, 220, 150),
}

local function createCustomerModel()
	local model = Instance.new("Model")
	model.Name = "Customer"

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2.5, 1)
	torso.Anchored = true
	torso.CanCollide = false
	torso.Color = CUSTOMER_COLORS[math.random(1, #CUSTOMER_COLORS)]
	torso.Material = Enum.Material.SmoothPlastic
	torso.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.3, 1.3, 1.3)
	head.Anchored = false
	head.Massless = true
	head.CanCollide = false
	head.Color = Color3.fromRGB(255, 213, 170)
	head.Material = Enum.Material.SmoothPlastic
	head.CFrame = torso.CFrame * CFrame.new(0, 1.9, 0)
	head.Parent = model

	-- Head rides the anchored torso by weld, so a single CFrame tween on the
	-- torso moves the whole customer.
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = torso
	weld.Part1 = head
	weld.Parent = torso

	model.PrimaryPart = torso
	return model
end

-- Seats (not whole tables) are the unit of capacity: each table has two
-- chairs, and each chair can independently hold one customer. The number of
-- tables itself comes from the plot's Restaurant Size (KitchenStage) upgrade.
local function getFreeSeat(plot)
	local building = plot:FindFirstChild("Stage1Building")
	if not building then return nil, nil end

	local tableCount = Upgrades.GetTableCount(plot)
	for i = 1, tableCount do
		local tbl = building:FindFirstChild("Table" .. i)
		if tbl then
			for _, chairName in ipairs(CHAIR_NAMES) do
				local chair = tbl:FindFirstChild(chairName)
				if chair and not chair:GetAttribute("Occupied") then
					return tbl, chair
				end
			end
		end
	end
	return nil, nil
end

local function getRandomMenuItem(plot)
	local menu = plot:FindFirstChild("Menu")
	if not menu then return nil end
	local items = menu:GetChildren()
	if #items == 0 then return nil end
	return items[math.random(1, #items)]
end

local WALK_TWEEN = TweenInfo.new(WALK_DURATION, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

-- One engine-interpolated tween on the anchored torso per leg of the trip,
-- instead of ~60 replicated PivotTo steps.
local function walkTo(customer, toCFrame)
	local tween = TweenService:Create(customer.PrimaryPart, WALK_TWEEN, { CFrame = toCFrame })
	tween:Play()
	return tween
end

local function getEatTime(plot)
	local speedMultiplier = Upgrades.GetEatSpeedMultiplier(plot)
	local minTime = BASE_EAT_TIME_MIN * speedMultiplier
	local maxTime = BASE_EAT_TIME_MAX * speedMultiplier
	return minTime + math.random() * (maxTime - minTime)
end

-- One customer's full visit: walk in, sit, eat, pay, walk out. Runs as its own
-- task so every free seat can be filled by a different customer at the same
-- time, instead of the whole plot waiting on one guest.
local function runCustomerVisit(plot, tbl, chair, order, ownerUserId)
	local building = plot.Stage1Building
	local entranceMarker = building:FindFirstChild("EntranceMarker")

	if not entranceMarker then
		chair:SetAttribute("Occupied", false)
		return
	end

	local outward = entranceMarker.CFrame.LookVector
	outward = Vector3.new(outward.X, 0, outward.Z).Unit
	local spawnPos = entranceMarker.Position + outward * 8

	local seatPos = chair.Position + Vector3.new(0, 1.2, 0)
	local tableTopPos = tbl.Top.Position

	local spawnCFrame = CFrame.lookAt(spawnPos, chair.Position)
	local seatCFrame = CFrame.lookAt(seatPos, Vector3.new(tableTopPos.X, seatPos.Y, tableTopPos.Z))

	local customer = createCustomerModel()
	customer.Parent = customersFolder
	customer:PivotTo(spawnCFrame)

	walkTo(customer, seatCFrame).Completed:Wait()

	task.wait(getEatTime(plot))

	local displayName = order.DisplayName
	local player = Players:GetPlayerByUserId(ownerUserId)
	local baseValue = order.BaseRestaurantValue * order.ValueMultiplier
	local value = baseValue * Upgrades.GetTipMultiplier(plot) * (player and Shop.GetMoneyMultiplier(player) or 1)
	value = math.floor(value + 0.5)

	if player then
		Economy.Add(player, value)
		Notify:FireClient(player, "A customer bought " .. displayName .. " for $" .. tostring(value) .. "!", Color3.fromRGB(140, 230, 140))
		CustomerPaid:FireClient(player, chair.Position + Vector3.new(0, 4, 0), value)
	end

	walkTo(customer, spawnCFrame).Completed:Wait()
	customer:Destroy()

	chair:SetAttribute("Occupied", false)
end

-- Per-plot spawner: periodically checks for a free seat (across all of the
-- plot's current tables) and, if one exists, kicks off an independent visit
-- task for it rather than waiting on that visit to finish.
local function runCustomerLoop(plot)
	while true do
		task.wait(math.random(SPAWN_INTERVAL_MIN, SPAWN_INTERVAL_MAX))

		local ownerUserId = plot:GetAttribute("OwnerUserId")
		if ownerUserId and ownerUserId ~= 0 then
			local tbl, chair = getFreeSeat(plot)
			local menuItem = getRandomMenuItem(plot)

			if tbl and chair and menuItem then
				-- Mark occupied immediately (synchronously) so the next loop
				-- iteration can't also grab this same seat. Snapshot the menu
				-- item's values now, since the player can swap it out while the
				-- customer is still eating.
				chair:SetAttribute("Occupied", true)
				local order = {
					DisplayName = menuItem:GetAttribute("DisplayName") or "food",
					BaseRestaurantValue = menuItem:GetAttribute("BaseRestaurantValue") or 0,
					ValueMultiplier = menuItem:GetAttribute("ValueMultiplier") or 1,
				}
				task.spawn(runCustomerVisit, plot, tbl, chair, order, ownerUserId)
			end
		end
	end
end

for _, plot in ipairs(plotsFolder:GetChildren()) do
	task.spawn(runCustomerLoop, plot)
end
