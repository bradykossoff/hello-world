--!strict
-- Extracts every script and the full instance tree from a .rbxl/.rbxlx place file.
-- Usage: lune run scripts/extract eattheworld.rbxl

local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local process = require("@lune/process")

local placePath = process.args[1] or error("pass a place file path")
local outDir = "extracted"

local contents = fs.readFile(placePath)
local game = roblox.deserializePlace(contents)

local SERVICES = {
	"Workspace",
	"ServerScriptService",
	"ServerStorage",
	"ReplicatedStorage",
	"ReplicatedFirst",
	"StarterPlayer",
	"StarterGui",
	"StarterPack",
	"Lighting",
	"SoundService",
	"Teams",
	"Chat",
}

local function ext(inst): string
	if inst.ClassName == "Script" then
		return ".server.luau"
	elseif inst.ClassName == "LocalScript" then
		return ".client.luau"
	else
		return ".luau"
	end
end

local function sanitize(name: string): string
	return (name:gsub('[<>:"/\\|%?%*]', "_"))
end

if fs.isDir(outDir) then
	fs.removeDir(outDir)
end
fs.writeDir(outDir)

local scriptCount = 0
local treeLines = {}

local function isSourceContainer(inst): boolean
	return inst.ClassName == "Script"
		or inst.ClassName == "LocalScript"
		or inst.ClassName == "ModuleScript"
end

local function walk(inst, dir: string, depth: number)
	for _, child in inst:GetChildren() do
		local indent = string.rep("  ", depth)
		local extra = ""
		if isSourceContainer(child) then
			local ok, disabled = pcall(function()
				return child.Disabled
			end)
			if ok and disabled then
				extra ..= " [disabled]"
			end
			local ok2, rc = pcall(function()
				return tostring(child.RunContext)
			end)
			if ok2 and rc and rc ~= "Enum.RunContext.Legacy" then
				extra ..= " [" .. rc .. "]"
			end
		end
		table.insert(treeLines, string.format("%s%s (%s)%s", indent, child.Name, child.ClassName, extra))

		if isSourceContainer(child) then
			local source = ""
			pcall(function()
				source = child.Source
			end)
			local path = dir .. "/" .. sanitize(child.Name) .. ext(child)
			fs.writeFile(path, source)
			scriptCount += 1

			-- a ModuleScript can also be a folder if it has script children
			local hasScriptKids = false
			for _, gc in child:GetChildren() do
				if isSourceContainer(gc) then
					hasScriptKids = true
					break
				end
			end
			if hasScriptKids then
				local sub = dir .. "/" .. sanitize(child.Name)
				fs.writeDir(sub)
				walk(child, sub, depth + 1)
			else
				walk(child, dir, depth + 1)
			end
		else
			-- keep the tree readable: only descend a couple levels into non-script containers
			-- unless they contain scripts somewhere
			local descend = depth < 2
			if not descend then
				for _, d in child:GetDescendants() do
					if isSourceContainer(d) then
						descend = true
						break
					end
				end
			end
			if descend then
				if #child:GetChildren() > 0 then
					local sub = dir .. "/" .. sanitize(child.Name)
					local madeDir = false
					for _, d in child:GetDescendants() do
						if isSourceContainer(d) then
							madeDir = true
							break
						end
					end
					if madeDir then
						fs.writeDir(sub)
						walk(child, sub, depth + 1)
					else
						walk(child, dir, depth + 1)
					end
				end
			end
		end
	end
end

for _, svcName in SERVICES do
	local ok, svc = pcall(function()
		return game:GetService(svcName)
	end)
	if ok and svc and #svc:GetChildren() > 0 then
		table.insert(treeLines, "")
		table.insert(treeLines, "== " .. svcName .. " ==")
		local svcDir = outDir .. "/" .. svcName
		fs.writeDir(svcDir)
		walk(svc, svcDir, 0)
	end
end

fs.writeFile(outDir .. "/PLACE-TREE.txt", table.concat(treeLines, "\n"))
print(string.format("extracted %d scripts", scriptCount))
