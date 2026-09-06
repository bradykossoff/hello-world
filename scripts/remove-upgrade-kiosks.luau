--!nocheck
-- One-time surgery on eattheworld.rbxl: the upgrade panel is now opened from
-- the on-screen HUD dock (src/client/HudDock + UpgradeUI), so the physical
-- UpgradeKiosk models are dead clutter. This strips them from every plot and
-- from Hub.Kiosks.
--
-- Run once, after committing the .rbxl:  lune run scripts/remove-upgrade-kiosks

local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local PATH = "eattheworld.rbxl"

local game = roblox.deserializePlace(fs.readFile(PATH))
local Workspace = game:GetService("Workspace")

local removed = {}

local function stripKiosk(parent, label)
	if not parent then
		return
	end
	local kiosk = parent:FindFirstChild("UpgradeKiosk")
	while kiosk do
		kiosk:Destroy()
		table.insert(removed, label)
		kiosk = parent:FindFirstChild("UpgradeKiosk")
	end
end

local plotsFolder = Workspace:FindFirstChild("Plots")
if plotsFolder then
	for _, plot in plotsFolder:GetChildren() do
		stripKiosk(plot, plot.Name .. ".UpgradeKiosk")
	end
end

local hub = Workspace:FindFirstChild("Hub")
local kiosks = hub and hub:FindFirstChild("Kiosks")
stripKiosk(kiosks, "Hub.Kiosks.UpgradeKiosk")

if #removed == 0 then
	print("no UpgradeKiosk models found - nothing to do")
	return
end

fs.writeFile(PATH, roblox.serializePlace(game))

print("patched " .. PATH .. ":")
for _, line in removed do
	print("  removed " .. line)
end
