--!nocheck
-- One-time surgery on eattheworld.rbxl for the model-swap kitchen system:
--   * remove the old per-plot Stage1Building (KitchenBuilder now clones a
--     Restaurant model from ServerStorage.RestaurantStages instead)
--   * add plot.BuildAnchor - the CFrame SetStage pivots the stage model to
--   * move each Hub spawn pad to line up with the new entrance
-- Run once: lune run scripts/patch-place  (commit the .rbxl first)

local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local CFrame = roblox.CFrame
local Vector3 = roblox.Vector3
local Instance = roblox.Instance

local PATH = "eattheworld.rbxl"
local ENTRANCE_OFFSET = 15 -- studs from plot-floor centre to the entrance threshold
local SPAWN_OFFSET = 12 -- studs the spawn pad sits out from the entrance

local game = roblox.deserializePlace(fs.readFile(PATH))
local Workspace = game:GetService("Workspace")
local plotsFolder = Workspace:FindFirstChild("Plots")

local changed = {}

for _, plot in plotsFolder:GetChildren() do
	local floor = plot:FindFirstChild("PlotFloor")
	local old = plot:FindFirstChild("Stage1Building")
	if not (floor and old) then
		continue
	end

	-- street direction from the existing entrance marker (+X or -X)
	local em = old:FindFirstChild("EntranceMarker")
	local streetX = 1
	if em then
		streetX = em.CFrame.LookVector.X >= 0 and 1 or -1
	end

	local fc = floor.CFrame.Position
	local anchorPos = Vector3.new(fc.X + streetX * ENTRANCE_OFFSET, 1, fc.Z)
	local anchorCF = CFrame.new(anchorPos)
	if streetX < 0 then
		anchorCF = anchorCF * CFrame.Angles(0, math.pi, 0)
	end

	old:Destroy()

	local anchor = Instance.new("Part")
	anchor.Name = "BuildAnchor"
	anchor.Size = Vector3.new(2, 2, 2)
	anchor.CFrame = anchorCF
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Transparency = 1
	anchor.Parent = plot

	-- spawn pad
	local pads = Workspace:FindFirstChild("Hub")
	pads = pads and pads:FindFirstChild("PlayerSpawnPads")
	local pad = pads and pads:FindFirstChild("SpawnPad_" .. plot.Name)
	if pad then
		pad.CFrame = CFrame.new(anchorPos.X + streetX * SPAWN_OFFSET, 1, anchorPos.Z)
	end

	table.insert(changed, string.format("%s  street %s  BuildAnchor @ (%.0f, 1, %.0f)", plot.Name, streetX > 0 and "+X" or "-X", anchorPos.X, anchorPos.Z))
end

-- Drop the placeholder scripts that got synced in during the initial Rojo
-- setup (Rojo would remove these anyway on the next connect).
local function rm(service, ...)
	local node = game:GetService(service)
	for _, name in { ... } do
		node = node and node:FindFirstChild(name)
	end
	if node then
		node:Destroy()
		table.insert(changed, ("removed placeholder %s.%s"):format(service, table.concat({ ... }, ".")))
	end
end
rm("ReplicatedStorage", "Shared")
rm("ServerScriptService", "Server")
rm("StarterPlayer", "StarterPlayerScripts", "Client")

fs.writeFile(PATH, roblox.serializePlace(game))

print("patched " .. PATH .. ":")
for _, line in changed do
	print("  " .. line)
end
