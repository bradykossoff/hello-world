--!nocheck
-- Generates the 3 restaurant stage models into src/serverstorage/RestaurantStages/.
-- Run: lune run scripts/build-stages
--
-- Canonical local frame (model is authored as if BuildAnchor is at the origin
-- with identity rotation):
--   +X = out the entrance toward the street      -X = back kitchen wall
--   +Y = up
--    Z = dining-room width; tables spread along it, symmetric about Z = 0
--   origin (Base pivot) = the entrance threshold, at floor-top height (Y = 0)
-- KitchenBuilder pivots this to plot.BuildAnchor.CFrame per plot (left plots
-- keep +X, right plots are yawed 180 so +X becomes world -X).

local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local Instance = roblox.Instance
local CFrame = roblox.CFrame
local Vector3 = roblox.Vector3
local Color3 = roblox.Color3
local Enum = roblox.Enum

local WALL_H = 10

local function c3(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local function mk(class, parent, props)
	local p = Instance.new(class)
	for k, v in props do
		if k == "attrs" then
			for ak, av in v do
				p:SetAttribute(ak, av)
			end
		elseif k == "cf" then
			p.CFrame = v
		elseif k == "pos" then
			p.CFrame = CFrame.new(v)
		else
			(p :: any)[k] = v
		end
	end
	p.Parent = parent
	return p
end

local function box(parent, name, pos, size, color, material, extra)
	local props = {
		Name = name,
		Size = size,
		pos = pos,
		Color = color or c3(160, 160, 160),
		Material = material or Enum.Material.SmoothPlastic,
		Anchored = true,
		CanCollide = true,
	}
	if extra then
		for k, v in extra do
			props[k] = v
		end
	end
	return mk("Part", parent, props)
end

local function marker(parent, name, pos, size, cf)
	return mk("Part", parent, {
		Name = name,
		Size = size,
		cf = cf or CFrame.new(pos),
		Anchored = true,
		CanCollide = false,
		Transparency = 1,
	})
end

----------------------------------------------------------------------
-- stage palettes / silhouettes
----------------------------------------------------------------------

local STAGES = {
	{
		key = "Stage1",
		display = "Cozy Kitchen",
		width = 24,
		depth = 24,
		tables = 2,
		stations = 1,
		roof = "gable",
		pal = {
			floor = c3(196, 170, 140),
			floorMat = Enum.Material.WoodPlanks,
			wall = c3(120, 86, 56),
			wallMat = Enum.Material.Wood,
			trim = c3(92, 62, 40),
			roofA = c3(150, 74, 58),
			roofMat = Enum.Material.Slate,
			accent = c3(210, 180, 110),
			sign = c3(233, 214, 170),
			signText = c3(70, 48, 26),
			glass = c3(190, 220, 225),
		},
	},
	{
		key = "Stage2",
		display = "Bigger Kitchen",
		width = 32,
		depth = 28,
		tables = 3,
		stations = 2,
		roof = "parapet",
		pal = {
			floor = c3(206, 198, 184),
			floorMat = Enum.Material.Marble,
			wall = c3(174, 96, 78),
			wallMat = Enum.Material.Brick,
			upper = c3(238, 228, 208),
			upperMat = Enum.Material.Concrete,
			trim = c3(120, 62, 48),
			roofA = c3(96, 104, 110),
			roofMat = Enum.Material.Metal,
			awningA = c3(58, 138, 132),
			awningB = c3(238, 228, 208),
			accent = c3(74, 160, 152),
			sign = c3(64, 168, 158),
			signText = c3(255, 255, 255),
			glass = c3(176, 214, 220),
			neon = c3(120, 240, 224),
		},
	},
	{
		key = "Stage3",
		display = "Grand Kitchen",
		width = 40,
		depth = 32,
		tables = 4,
		stations = 2,
		roof = "grand",
		pal = {
			floor = c3(60, 54, 66),
			floorMat = Enum.Material.Slate,
			wall = c3(58, 44, 74),
			wallMat = Enum.Material.SmoothPlastic,
			upper = c3(40, 30, 52),
			upperMat = Enum.Material.SmoothPlastic,
			trim = c3(214, 176, 92),
			roofA = c3(30, 22, 40),
			roofMat = Enum.Material.SmoothPlastic,
			accent = c3(224, 182, 96),
			sign = c3(232, 190, 100),
			signText = c3(40, 28, 16),
			glass = c3(150, 210, 224),
			neon = c3(255, 214, 128),
		},
	},
}

----------------------------------------------------------------------
-- table builder
----------------------------------------------------------------------

local function buildTable(parent, index, tx, tz, pal)
	local t = Instance.new("Model")
	t.Name = "Table" .. index

	local top = box(t, "Top", Vector3.new(tx, 3, tz), Vector3.new(4, 0.4, 4), pal.accent, Enum.Material.Wood)
	box(t, "Leg", Vector3.new(tx, 1.4, tz), Vector3.new(0.8, 2.8, 0.8), pal.trim, Enum.Material.Metal)
	t.PrimaryPart = top

	-- plates (cosmetic)
	mk("Part", t, {
		Name = "Plate1", Shape = Enum.PartType.Cylinder, Anchored = true, CanCollide = false,
		Size = Vector3.new(0.15, 1.1, 1.1), Color = c3(245, 245, 240), Material = Enum.Material.SmoothPlastic,
		cf = CFrame.new(tx + 1, 3.3, tz) * CFrame.Angles(0, 0, math.rad(90)),
	})
	mk("Part", t, {
		Name = "Plate2", Shape = Enum.PartType.Cylinder, Anchored = true, CanCollide = false,
		Size = Vector3.new(0.15, 1.1, 1.1), Color = c3(245, 245, 240), Material = Enum.Material.SmoothPlastic,
		cf = CFrame.new(tx - 1, 3.3, tz) * CFrame.Angles(0, 0, math.rad(90)),
	})

	for i, sx in { 2.6, -2.6 } do
		local seat = box(t, "Chair" .. i, Vector3.new(tx + sx, 1.2, tz), Vector3.new(1.6, 1.6, 1.6), pal.wall, Enum.Material.Wood)
		seat:SetAttribute("Occupied", false)
		-- backrest, facing the table
		local back = box(t, "Chair" .. i .. "Back", Vector3.new(tx + sx + (sx > 0 and 0.7 or -0.7), 2.3, tz), Vector3.new(0.3, 1.8, 1.6), pal.wall, Enum.Material.Wood)
		back.CanCollide = false
	end

	local wp = Instance.new("Folder")
	wp.Name = "WalkPath"
	wp.Parent = t
	marker(wp, "Node1", Vector3.new(tx + 5, 1, tz), Vector3.new(1.5, 2, 1.5))
	marker(wp, "Node2", Vector3.new(tx + 3, 1, tz), Vector3.new(1.5, 2, 1.5))

	t.Parent = parent
	return t
end

----------------------------------------------------------------------
-- kitchen station builder
----------------------------------------------------------------------

local function buildStation(parent, index, kx, sz, pal)
	local s = Instance.new("Model")
	s.Name = "Station" .. index

	local counter = box(s, "Counter", Vector3.new(kx, 1.5, sz), Vector3.new(6, 3, 3), pal.trim, Enum.Material.Metal)
	s.PrimaryPart = counter
	-- appliances / detail
	box(s, "Appliance", Vector3.new(kx - 0.5, 3.6, sz), Vector3.new(3, 1.2, 2), c3(210, 210, 214), Enum.Material.Metal).CanCollide = false
	box(s, "Hood", Vector3.new(kx - 0.8, 6.2, sz), Vector3.new(4, 0.6, 3.4), c3(150, 150, 156), Enum.Material.Metal).CanCollide = false

	marker(s, "StandMarker", Vector3.new(kx + 2.6, 1, sz), Vector3.new(2, 4, 2))

	local mount = Instance.new("Attachment")
	mount.Name = "PromptMount"
	mount.CFrame = CFrame.new(0, 1.6, 0)
	mount.Parent = counter

	s.Parent = parent
	return s
end

----------------------------------------------------------------------
-- window (framed opening with glass) on a wall plane
----------------------------------------------------------------------

local function windowOnSide(decor, x, z, sideSign, pal)
	-- side wall runs along X at z = sideSign * width/2; window faces +/-Z
	local frameColor = pal.trim
	local w, h = 4, 3.5
	local y = 4.5
	for _, seg in {
		{ Vector3.new(w + 0.6, 0.4, 0.6), Vector3.new(x, y + h / 2, z) },
		{ Vector3.new(w + 0.6, 0.4, 0.6), Vector3.new(x, y - h / 2, z) },
		{ Vector3.new(0.4, h, 0.6), Vector3.new(x - w / 2, y, z) },
		{ Vector3.new(0.4, h, 0.6), Vector3.new(x + w / 2, y, z) },
	} do
		box(decor, "WinFrame", seg[2], seg[1], frameColor, Enum.Material.Wood).CanCollide = false
	end
	local glass = box(decor, "WinGlass", Vector3.new(x, y, z), Vector3.new(w, h, 0.2), pal.glass, Enum.Material.Glass, { Transparency = 0.55 })
	glass.CanCollide = false
end

----------------------------------------------------------------------
-- one stage
----------------------------------------------------------------------

local function buildStage(cfg)
	local W, D, pal = cfg.width, cfg.depth, cfg.pal
	local halfW = W / 2

	local model = Instance.new("Model")
	model.Name = cfg.key
	model:SetAttribute("TableCount", cfg.tables)
	model:SetAttribute("StageDisplay", cfg.display)

	-- Base: invisible pivot at the entrance threshold
	local base = marker(model, "Base", Vector3.new(0, 0, 0), Vector3.new(3, 1, 3))
	model.PrimaryPart = base

	-- Floors
	box(model, "DiningFloor", Vector3.new(-D / 2, -0.15, 0), Vector3.new(D - 0.4, 0.3, W - 0.4), pal.floor, pal.floorMat)

	-- Entrance marker: LookVector points out the front (+X local)
	marker(model, "EntranceMarker", nil, Vector3.new(8, 6, 1), CFrame.new(0, 3, 0) * CFrame.Angles(0, math.rad(-90), 0))

	-- Aisle spine
	local aisle = Instance.new("Folder")
	aisle.Name = "Aisle"
	aisle.Parent = model
	marker(aisle, "Aisle1", Vector3.new(-4, 1, 0), Vector3.new(3, 2, 3))
	marker(aisle, "Aisle2", Vector3.new(-D * 0.42, 1, 0), Vector3.new(3, 2, 3))

	-- Tables
	local tables = Instance.new("Folder")
	tables.Name = "Tables"
	tables.Parent = model
	local tx = -D * 0.42
	for i = 1, cfg.tables do
		local tz = 8 * (i - (cfg.tables + 1) / 2)
		buildTable(tables, i, tx, tz, pal)
	end

	-- Kitchen stations
	local stations = Instance.new("Folder")
	stations.Name = "KitchenStations"
	stations.Parent = model
	local kx = -D + 3
	if cfg.stations == 1 then
		buildStation(stations, 1, kx, 0, pal)
	else
		buildStation(stations, 1, kx, -6, pal)
		buildStation(stations, 2, kx, 6, pal)
	end
	-- kitchen counter line back-splash
	box(model, "KitchenLine", Vector3.new(kx - 1.2, 2, 0), Vector3.new(2, 4, W - 4), pal.trim, Enum.Material.Metal).CanCollide = false

	-- Sign anchor + facade sign
	local facade = box(model, "Facade", Vector3.new(0, WALL_H + 1.4, 0), Vector3.new(0.6, 3, W - 2), pal.upper or pal.wall, pal.upperMat or pal.wallMat)
	facade.CanCollide = false
	local signMount = Instance.new("Attachment")
	signMount.Name = "SignMount"
	signMount.CFrame = CFrame.new(0.5, 0, 0)
	signMount.Parent = facade

	local signBoard = box(model, "SignBoard", Vector3.new(0.6, WALL_H + 1.4, 0), Vector3.new(0.4, 2.2, math.min(W - 6, 16)),
		pal.sign, pal.neon and Enum.Material.Neon or Enum.Material.SmoothPlastic)
	signBoard.CanCollide = false
	local sg = Instance.new("SurfaceGui")
	sg.Name = "SignGui"
	sg.Face = Enum.NormalId.Front
	sg.Parent = signBoard
	local tl = Instance.new("TextLabel")
	tl.Size = roblox.UDim2.new(1, 0, 1, 0)
	tl.BackgroundTransparency = 1
	tl.Text = string.upper(cfg.display)
	tl.TextScaled = true
	tl.Font = Enum.Font.GothamBlack
	tl.TextColor3 = pal.signText
	tl.Parent = sg

	-- Kiosk reference marker
	marker(model, "KioskMount", Vector3.new(2, 1.5, halfW + 3), Vector3.new(2, 3, 2))

	----------------------------------------------------------------
	-- Decor: walls, roof, posts, windows, props
	----------------------------------------------------------------
	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = model

	-- back + side walls
	box(decor, "BackWall", Vector3.new(-D, WALL_H / 2, 0), Vector3.new(0.6, WALL_H, W), pal.wall, pal.wallMat)
	box(decor, "SideWallL", Vector3.new(-D / 2, WALL_H / 2, -halfW), Vector3.new(D, WALL_H, 0.6), pal.wall, pal.wallMat)
	box(decor, "SideWallR", Vector3.new(-D / 2, WALL_H / 2, halfW), Vector3.new(D, WALL_H, 0.6), pal.wall, pal.wallMat)
	if pal.upper then
		box(decor, "BackWallUpper", Vector3.new(-D, WALL_H + 1.5, 0), Vector3.new(0.6, 3, W), pal.upper, pal.upperMat).CanCollide = false
	end

	-- front knee walls (leave an 8-stud gap centred on Z = 0)
	local kneeLen = (W - 8) / 2
	for _, s in { -1, 1 } do
		box(decor, "KneeWall", Vector3.new(0, 1.5, s * (8 + kneeLen) / 2), Vector3.new(0.6, 3, kneeLen),
			pal.upper and pal.glass or pal.wall, pal.upper and Enum.Material.Glass or pal.wallMat,
			pal.upper and { Transparency = 0.5 } or nil)
	end

	-- corner posts
	for _, cx in { 0, -D } do
		for _, cz in { -halfW, halfW } do
			box(decor, "Post", Vector3.new(cx, WALL_H / 2, cz), Vector3.new(0.9, WALL_H + 0.5, 0.9), pal.trim, Enum.Material.Wood)
		end
	end
	-- top trim plate
	box(decor, "TrimFront", Vector3.new(0, WALL_H + 0.3, 0), Vector3.new(0.8, 0.6, W + 1), pal.trim, Enum.Material.Wood).CanCollide = false
	box(decor, "TrimBack", Vector3.new(-D, WALL_H + 0.3, 0), Vector3.new(0.8, 0.6, W + 1), pal.trim, Enum.Material.Wood).CanCollide = false

	-- windows
	windowOnSide(decor, -D * 0.35, -halfW, -1, pal)
	windowOnSide(decor, -D * 0.7, -halfW, -1, pal)
	windowOnSide(decor, -D * 0.35, halfW, 1, pal)
	windowOnSide(decor, -D * 0.7, halfW, 1, pal)

	-- roof
	if cfg.roof == "gable" then
		local rise = 4
		local slopeLen = math.sqrt((halfW) ^ 2 + rise ^ 2)
		local ang = math.atan(rise / halfW)
		for _, s in { -1, 1 } do
			mk("Part", decor, {
				Name = "RoofPane", Anchored = true, CanCollide = false,
				Size = Vector3.new(D + 3, 0.5, slopeLen + 1),
				Color = pal.roofA, Material = pal.roofMat,
				cf = CFrame.new(-D / 2, WALL_H + rise / 2, s * halfW / 2) * CFrame.Angles(s * ang, 0, 0),
			})
		end
		box(decor, "Ridge", Vector3.new(-D / 2, WALL_H + rise, 0), Vector3.new(D + 3, 0.6, 0.8), pal.trim, Enum.Material.Wood).CanCollide = false
	elseif cfg.roof == "parapet" then
		box(decor, "RoofSlab", Vector3.new(-D / 2, WALL_H + 0.3, 0), Vector3.new(D + 2, 0.6, W + 2), pal.roofA, pal.roofMat).CanCollide = false
		box(decor, "Parapet", Vector3.new(0.2, WALL_H + 2, 0), Vector3.new(0.8, 3.4, W + 2), pal.roofA, pal.roofMat).CanCollide = false
		-- striped awning over the entrance
		local stripes = 8
		local sw = (W - 2) / stripes
		for i = 0, stripes - 1 do
			local z = -halfW + 1 + sw * (i + 0.5)
			box(decor, "Awning", Vector3.new(2, 6.6, z), Vector3.new(4, 0.3, sw), i % 2 == 0 and pal.awningA or pal.awningB, Enum.Material.Fabric, { CanCollide = false })
		end
		box(decor, "AwningLip", Vector3.new(3.9, 6.1, 0), Vector3.new(0.4, 1, W - 2), pal.awningA, Enum.Material.Fabric).CanCollide = false
		-- planters
		for _, s in { -1, 1 } do
			mk("Part", decor, { Name = "Planter", Shape = Enum.PartType.Cylinder, Anchored = true, CanCollide = true,
				Size = Vector3.new(1.6, 2, 2), Color = pal.trim, Material = Enum.Material.Slate,
				cf = CFrame.new(1.5, 1, s * (halfW - 2)) * CFrame.Angles(0, 0, math.rad(90)) })
			mk("Part", decor, { Name = "Shrub", Shape = Enum.PartType.Ball, Anchored = true, CanCollide = false,
				Size = Vector3.new(2.6, 2.6, 2.6), Color = c3(96, 150, 84), Material = Enum.Material.Grass,
				pos = Vector3.new(1.5, 3, s * (halfW - 2)) })
		end
	else -- grand
		box(decor, "RoofSlab", Vector3.new(-D / 2, WALL_H + 0.3, 0), Vector3.new(D + 3, 0.7, W + 3), pal.roofA, pal.roofMat).CanCollide = false
		box(decor, "ParapetTall", Vector3.new(0.4, WALL_H + 3.5, 0), Vector3.new(1.2, 6, W + 3), pal.roofA, pal.roofMat).CanCollide = false
		box(decor, "ParapetCap", Vector3.new(0.4, WALL_H + 6.7, 0), Vector3.new(1.8, 0.6, W + 3.4), pal.trim, Enum.Material.SmoothPlastic).CanCollide = false
		-- emissive sign box on the parapet
		box(decor, "SignHalo", Vector3.new(1.1, WALL_H + 3.6, 0), Vector3.new(0.3, 3, math.min(W - 4, 22)), pal.neon, Enum.Material.Neon).CanCollide = false
		-- outdoor rail
		for _, s in { -1, 1 } do
			box(decor, "Rail", Vector3.new(2.5, 2.4, s * (halfW - 1)), Vector3.new(3, 0.25, 0.25), pal.trim, Enum.Material.Metal).CanCollide = false
			box(decor, "RailPost", Vector3.new(3.9, 1.4, s * (halfW - 1)), Vector3.new(0.25, 2, 0.25), pal.trim, Enum.Material.Metal).CanCollide = false
		end
		-- pendant lights over the dining room
		for i = 1, cfg.tables do
			local tz = 8 * (i - (cfg.tables + 1) / 2)
			box(decor, "Pendant", Vector3.new(-D * 0.42, WALL_H - 1.5, tz), Vector3.new(1, 1, 1), pal.neon, Enum.Material.Neon).CanCollide = false
		end
	end

	-- roof support posts at the open front
	for _, s in { -1, 1 } do
		box(decor, "FrontPost", Vector3.new(0, WALL_H / 2, s * (halfW - 0.5)), Vector3.new(0.8, WALL_H, 0.8), pal.trim, Enum.Material.Wood)
	end

	return model
end

----------------------------------------------------------------------

local outDir = "src/serverstorage/RestaurantStages"
if not fs.isDir("src/serverstorage") then
	fs.writeDir("src/serverstorage")
end
if not fs.isDir(outDir) then
	fs.writeDir(outDir)
end

for _, cfg in STAGES do
	local model = buildStage(cfg)
	local xml = roblox.serializeModel({ model }, true)
	fs.writeFile(outDir .. "/" .. cfg.key .. ".rbxmx", xml)
	local n = #model:GetDescendants()
	print(string.format("%s  (%s)  %d instances  -> %s.rbxmx", cfg.key, cfg.display, n, cfg.key))
end

print("done")
