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

local SEGMENT_TIME = 0.55 -- seconds per waypoint hop

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
-- chairs, each independently holding one customer.
local function getFreeSeat(plot)
	local building = plot:FindFirstChild("Restaurant")
	local tables = building and building:FindFirstChild("Tables")
	if not tables then
		return nil, nil
	end
	for _, tbl in ipairs(tables:GetChildren()) do
		for _, chairName in ipairs(CHAIR_NAMES) do
			local chair = tbl:FindFirstChild(chairName)
			if chair and not chair:GetAttribute("Occupied") then
				return tbl, chair
			end
		end
	end
	return nil, nil
end

local function getRandomMenuItem(plot)
	local menu = plot:FindFirstChild("Menu")
	if not menu then
		return nil
	end
	local items = menu:GetChildren()
	if #items == 0 then
		return nil
	end
	return items[math.random(1, #items)]
end

local WALK_TWEEN = TweenInfo.new(SEGMENT_TIME, Enum.EasingStyle.Linear)

local function walkTo(customer, toCFrame)
	local tween = TweenService:Create(customer.PrimaryPart, WALK_TWEEN, { CFrame = toCFrame })
	tween:Play()
	return tween
end

local function stillValid(...)
	for _, inst in { ... } do
		if not inst or not inst.Parent then
			return false
		end
	end
	return true
end

-- Waypoint chain from just outside the door to the seat: entrance -> aisle
-- spine -> the table's own approach nodes -> chair. Missing nodes are simply
-- skipped, so a bare graybox still routes (straighter, may clip).
local function buildRoute(building, tbl, chair, entranceMarker)
	local outward = entranceMarker.CFrame.LookVector
	outward = Vector3.new(outward.X, 0, outward.Z)
	outward = outward.Magnitude > 0.1 and outward.Unit or Vector3.new(0, 0, 1)

	local walkY = chair.Position.Y + 0.9
	local flat = function(p)
		return Vector3.new(p.X, walkY, p.Z)
	end

	local points = {
		flat(entranceMarker.Position + outward * 9),
		flat(entranceMarker.Position),
	}

	local aisle = building:FindFirstChild("Aisle")
	if aisle then
		for _, name in ipairs({ "Aisle1", "Aisle2" }) do
			local n = aisle:FindFirstChild(name)
			if n then
				table.insert(points, flat(n.Position))
			end
		end
	end

	local wp = tbl:FindFirstChild("WalkPath")
	if wp then
		for _, name in ipairs({ "Node1", "Node2" }) do
			local n = wp:FindFirstChild(name)
			if n then
				table.insert(points, flat(n.Position))
			end
		end
	end

	local seatPos = chair.Position + Vector3.new(0, 1, 0)
	local facePos = Vector3.new(tbl.Top.Position.X, seatPos.Y, tbl.Top.Position.Z)

	local cframes = {}
	for i, p in ipairs(points) do
		local target = points[i + 1] or seatPos
		local look = Vector3.new(target.X, p.Y, target.Z)
		cframes[i] = (look - p).Magnitude > 0.05 and CFrame.lookAt(p, look) or CFrame.new(p)
	end

	local seatCFrame = CFrame.lookAt(seatPos, facePos)
	return cframes, seatCFrame, seatPos
end

local function getEatTime(plot)
	local speedMultiplier = Upgrades.GetEatSpeedMultiplier(plot)
	local minTime = BASE_EAT_TIME_MIN * speedMultiplier
	local maxTime = BASE_EAT_TIME_MAX * speedMultiplier
	return minTime + math.random() * (maxTime - minTime)
end

-- One customer's full visit. Runs as its own task so every free seat fills
-- concurrently. Guards every step against the Restaurant being swapped out
-- from under it (a Restaurant Size upgrade destroys and replaces the model),
-- and always frees the seat on the way out.
local function runCustomerVisit(plot, tbl, chair, order, ownerUserId)
	local customer

	local ok, err = pcall(function()
		local building = plot:FindFirstChild("Restaurant")
		local entranceMarker = building and building:FindFirstChild("EntranceMarker")
		if not (building and entranceMarker and stillValid(tbl, chair)) then
			return
		end

		local route, seatCFrame, seatPos = buildRoute(building, tbl, chair, entranceMarker)

		customer = createCustomerModel()
		customer.Parent = customersFolder
		customer:PivotTo(route[1])

		for i = 2, #route do
			if not stillValid(customer, chair, building) then
				return
			end
			walkTo(customer, route[i]).Completed:Wait()
		end
		if not stillValid(customer, chair, building) then
			return
		end
		walkTo(customer, seatCFrame).Completed:Wait()

		local payFxPos = seatPos + Vector3.new(0, 3, 0)
		task.wait(getEatTime(plot))
		if not stillValid(customer, building) then
			return
		end

		local player = Players:GetPlayerByUserId(ownerUserId)
		local value = order.BaseRestaurantValue
			* order.ValueMultiplier
			* Upgrades.GetTipMultiplier(plot)
			* (player and Shop.GetMoneyMultiplier(player) or 1)
		value = math.floor(value + 0.5)

		if player then
			Economy.Add(player, value)
			Notify:FireClient(player, "A customer bought " .. order.DisplayName .. " for $" .. tostring(value) .. "!", Color3.fromRGB(140, 230, 140))
			CustomerPaid:FireClient(player, payFxPos, value)
		end

		for i = #route, 1, -1 do
			if not stillValid(customer) then
				return
			end
			walkTo(customer, route[i]).Completed:Wait()
		end
	end)

	if customer then
		customer:Destroy()
	end
	if chair and chair.Parent then
		chair:SetAttribute("Occupied", false)
	end
	if not ok then
		warn("CustomerSystem visit error: " .. tostring(err))
	end
end

-- Per-plot spawner: on a timer, grab a free seat + a menu item and kick off
-- an independent visit for it.
local function runCustomerLoop(plot)
	while true do
		task.wait(math.random(SPAWN_INTERVAL_MIN, SPAWN_INTERVAL_MAX))

		local ownerUserId = plot:GetAttribute("OwnerUserId")
		if ownerUserId and ownerUserId ~= 0 then
			local tbl, chair = getFreeSeat(plot)
			local menuItem = getRandomMenuItem(plot)

			if tbl and chair and menuItem then
				-- Mark occupied synchronously so the next iteration can't grab
				-- the same seat, and snapshot the menu item's values now since
				-- the player can swap it out mid-meal.
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
