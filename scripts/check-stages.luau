--!nocheck
-- Verifies the generated stage models against the kitchen-design doc §4 contract.
-- Run: lune run scripts/check-stages

local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local dir = "src/serverstorage/RestaurantStages"
local EXPECT_TABLES = { Stage1 = 2, Stage2 = 3, Stage3 = 4 }
local EXPECT_STATIONS = { Stage1 = 1, Stage2 = 2, Stage3 = 2 }

local fails = 0
local function check(cond, msg)
	if not cond then
		fails += 1
		print("  FAIL: " .. msg)
	end
end

for _, file in fs.readDir(dir) do
	local key = file:match("^(.-)%.rbxmx$")
	if not key then continue end
	print("== " .. key .. " ==")
	local model = roblox.deserializeModel(fs.readFile(dir .. "/" .. file))[1]

	check(model.Name == key, "model name is " .. model.Name)
	check(model.PrimaryPart ~= nil and model.PrimaryPart.Name == "Base", "PrimaryPart = Base")

	for _, name in { "Base", "DiningFloor", "EntranceMarker", "Tables", "Aisle", "KitchenStations", "Facade", "KioskMount", "Decor" } do
		check(model:FindFirstChild(name) ~= nil, "has child " .. name)
	end

	local em = model:FindFirstChild("EntranceMarker")
	if em then
		local lv = em.CFrame.LookVector
		check(math.abs(lv.X - 1) < 0.01 and math.abs(lv.Z) < 0.01, string.format("EntranceMarker LookVector ~ +X (got %.2f,%.2f,%.2f)", lv.X, lv.Y, lv.Z))
	end

	local tables = model:FindFirstChild("Tables")
	local n = tables and #tables:GetChildren() or 0
	check(n == EXPECT_TABLES[key], string.format("%d tables (want %d)", n, EXPECT_TABLES[key]))
	if tables then
		for _, t in tables:GetChildren() do
			check(t.PrimaryPart ~= nil and t.PrimaryPart.Name == "Top", t.Name .. " PrimaryPart = Top")
			for _, cn in { "Chair1", "Chair2" } do
				local ch = t:FindFirstChild(cn)
				check(ch ~= nil, t.Name .. " has " .. cn)
				check(ch and ch:GetAttribute("Occupied") == false, t.Name .. "." .. cn .. " Occupied=false")
			end
			local wp = t:FindFirstChild("WalkPath")
			check(wp ~= nil and wp:FindFirstChild("Node1") ~= nil, t.Name .. " has WalkPath/Node1")
		end
	end

	local stations = model:FindFirstChild("KitchenStations")
	local sc = stations and #stations:GetChildren() or 0
	check(sc == EXPECT_STATIONS[key], string.format("%d stations (want %d)", sc, EXPECT_STATIONS[key]))
	if stations then
		for _, s in stations:GetChildren() do
			check(s:FindFirstChild("Counter") ~= nil, s.Name .. " has Counter")
			check(s:FindFirstChild("StandMarker") ~= nil, s.Name .. " has StandMarker")
			local counter = s:FindFirstChild("Counter")
			check(counter and counter:FindFirstChild("PromptMount") ~= nil, s.Name .. " Counter has PromptMount attachment")
		end
	end

	local aisle = model:FindFirstChild("Aisle")
	check(aisle and aisle:FindFirstChild("Aisle1") and aisle:FindFirstChild("Aisle2"), "Aisle1 + Aisle2")

	local facade = model:FindFirstChild("Facade")
	check(facade and facade:FindFirstChild("SignMount") ~= nil, "Facade has SignMount attachment")

	-- footprint sanity from raw part extents
	local minX, maxX, minZ, maxZ, maxY = math.huge, -math.huge, math.huge, -math.huge, -math.huge
	for _, d in model:GetDescendants() do
		local ok, cframe = pcall(function() return d.CFrame end)
		local oks, size = pcall(function() return d.Size end)
		if ok and oks then
			local p, s = cframe.Position, size
			minX = math.min(minX, p.X - s.X / 2); maxX = math.max(maxX, p.X + s.X / 2)
			minZ = math.min(minZ, p.Z - s.Z / 2); maxZ = math.max(maxZ, p.Z + s.Z / 2)
			maxY = math.max(maxY, p.Y + s.Y / 2)
		end
	end
	print(string.format("  extent X[%.1f..%.1f] Z[%.1f..%.1f] topY=%.1f", minX, maxX, minZ, maxZ, maxY))
	check(maxX <= 4.5, "front (+X) decor stays within ~4.5 of the entrance plane")
	check(minX >= -36, "back (-X) within ~36 of the entrance plane")
	check(maxY <= 22, "roof height <= 22")
end

print(fails == 0 and "\nALL CHECKS PASS" or ("\n" .. fails .. " CHECK(S) FAILED"))
if fails > 0 then
	(require("@lune/process")).exit(1)
end
