-- Dumps the geometry of every plot + hub reference points from the place file.
-- Usage: lune run scripts/inspect-plots eattheworld.rbxl

local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local process = require("@lune/process")

local game = roblox.deserializePlace(fs.readFile(process.args[1] or "eattheworld.rbxl"))
local Workspace = game:GetService("Workspace")

local function vec3(vec)
	return string.format("(%.2f, %.2f, %.2f)", vec.X, vec.Y, vec.Z)
end

local function partInfo(p)
	local ok, cf = pcall(function() return p.CFrame end)
	if not ok then return "" end
	local sz = ""
	local oks, s = pcall(function() return p.Size end)
	if oks then sz = "  size=" .. vec3(s) end
	local lv = cf.LookVector
	return string.format("  pos=%s%s  look=%s", vec3(cf.Position), sz, vec3(lv))
end

local function dump(inst, indent)
	local ok = pcall(function() return inst.CFrame end)
	local line = indent .. inst.Name .. " (" .. inst.ClassName .. ")"
	if ok then
		line = line .. partInfo(inst)
	end
	print(line)
	if inst:IsA("Model") then
		local okb, cf, size = pcall(function()
			local c, s = inst:GetBoundingBox()
			return c, s
		end)
		if okb and cf then
			print(indent .. "  [bbox] center=" .. vec3(cf.Position) .. " size=" .. vec3(size))
		end
	end
	for _, child in ipairs(inst:GetChildren()) do
		dump(child, indent .. "  ")
	end
end

local plots = Workspace:FindFirstChild("Plots")
for _, plot in ipairs(plots:GetChildren()) do
	print("\n===== " .. plot.Name .. " =====")
	dump(plot, "")
end

local hub = Workspace:FindFirstChild("Hub")
if hub then
	print("\n===== Hub spawn pads =====")
	for _, d in ipairs(hub:GetDescendants()) do
		if d:IsA("BasePart") and (d.Name:match("Spawn") or d.Name:match("Pad")) then
			print(d.Name .. partInfo(d))
		end
	end
end
