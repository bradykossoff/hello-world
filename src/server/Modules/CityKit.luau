-- Graybox construction kit for the golden-hour New York look. Everything here is
-- anchored, deterministic, and grouped under a Model the caller owns, so a scene
-- can be cleared and rebuilt on every server start.
--
-- Conventions: a "front" CFrame's -Z faces the street / the viewer. Ground walk
-- surface is Y = 0 unless the caller passes a different base.
--
-- Low-level part/light/sign helpers live in BuildKit and are re-exported here so
-- existing callers keep working; the hub garden uses ParkKit for its own props.

local BuildKit = require(script.Parent.BuildKit)

local CityKit = {}

CityKit.part = BuildKit.part
CityKit.light = BuildKit.light
CityKit.polishBillboard = BuildKit.polishBillboard
CityKit.surfaceSign = BuildKit.surfaceSign

local Palette = {
	Asphalt = Color3.fromRGB(58, 58, 66),
	Sidewalk = Color3.fromRGB(170, 166, 170),
	SidewalkJoint = Color3.fromRGB(128, 124, 130),
	Curb = Color3.fromRGB(120, 116, 122),
	LineYellow = Color3.fromRGB(238, 198, 84),
	LineWhite = Color3.fromRGB(222, 222, 226),

	BrickRed = Color3.fromRGB(168, 92, 78),
	BrickTan = Color3.fromRGB(206, 180, 146),
	Limestone = Color3.fromRGB(214, 208, 196),
	Concrete = Color3.fromRGB(150, 148, 156),
	DarkFacade = Color3.fromRGB(120, 116, 132),

	WindowWarm = Color3.fromRGB(255, 224, 168),
	WindowCool = Color3.fromRGB(196, 216, 255),
	WindowDark = Color3.fromRGB(96, 110, 132),
	Glass = Color3.fromRGB(120, 158, 182),

	SkylineNear = Color3.fromRGB(120, 118, 150),
	SkylineFar = Color3.fromRGB(150, 150, 176),

	NeonPink = Color3.fromRGB(255, 92, 170),
	NeonCyan = Color3.fromRGB(96, 232, 245),
	NeonAmber = Color3.fromRGB(255, 168, 72),
	NeonGreen = Color3.fromRGB(122, 255, 150),
	NeonRed = Color3.fromRGB(255, 84, 84),

	LampWarm = Color3.fromRGB(255, 198, 138),
	SubwayGreen = Color3.fromRGB(38, 116, 68),
	TaxiYellow = Color3.fromRGB(250, 200, 40),
	Steel = Color3.fromRGB(120, 122, 130),
	Metal = Color3.fromRGB(96, 98, 108),
}
CityKit.Palette = Palette

local NEONS = { Palette.NeonPink, Palette.NeonCyan, Palette.NeonAmber, Palette.NeonGreen }

local function rand(rng, a, b)
	return a + (b - a) * rng:NextNumber()
end

----------------------------------------------------------------
-- Buildings
----------------------------------------------------------------

local FACADES = { Palette.BrickRed, Palette.BrickTan, Palette.Limestone, Palette.Concrete, Palette.DarkFacade }
local SHOPS = {
	{ "DELI", Palette.NeonAmber }, { "BODEGA", Palette.NeonGreen }, { "BAR", Palette.NeonPink },
	{ "LAUNDRY", Palette.NeonCyan }, { "BOOKS", Palette.NeonAmber }, { "24 HR", Palette.NeonPink },
	{ "COFFEE", Palette.NeonAmber }, { "BARBER", Palette.NeonCyan }, { "RECORDS", Palette.NeonGreen },
	{ "PHARMACY", Palette.NeonRed }, { "PIZZA", Palette.NeonRed }, { "NAILS", Palette.NeonPink },
}

-- cfg = { cf, width, depth, floors, facade?, seed?, storefront?, shop?,
--         fireEscape?, water?, setback? }
function CityKit.building(parent, cfg)
	local rng = Random.new(cfg.seed or 1)
	local width = cfg.width or 32
	local depth = cfg.depth or 26
	local floors = cfg.floors or 6
	local floorH = 6
	local groundH = 11
	local totalH = groundH + (floors - 1) * floorH
	local facade = cfg.facade or FACADES[rng:NextInteger(1, #FACADES)]
	local cf = cfg.cf

	local m = Instance.new("Model")
	m.Name = "Building"

	local shell = CityKit.part(m, {
		Name = "Shell",
		Size = Vector3.new(width, totalH, depth),
		CFrame = cf * CFrame.new(0, totalH / 2, -depth / 2),
		Color = facade,
		Material = Enum.Material.Brick,
	})
	m.PrimaryPart = shell

	-- cornice
	CityKit.part(m, {
		Name = "Cornice",
		Size = Vector3.new(width + 1.4, 1.2, depth + 1.4),
		CFrame = cf * CFrame.new(0, totalH - 0.6, -depth / 2),
		Color = facade:Lerp(Color3.new(0, 0, 0), 0.25),
		Material = Enum.Material.Concrete,
	})

	-- window grid on the street face (-Z of cf, i.e. front of shell at local -0)
	local cols = math.max(2, math.floor(width / 4.2))
	local colGap = width / cols
	local winW = math.min(2.6, colGap * 0.6)
	for f = 1, floors - 1 do
		local y = groundH + (f - 1) * floorH + floorH * 0.5
		-- structural band between floors
		CityKit.part(m, {
			Name = "Band",
			Size = Vector3.new(width + 0.2, 1, 0.4),
			CFrame = cf * CFrame.new(0, groundH + (f - 1) * floorH, 0.05),
			Color = facade:Lerp(Color3.new(1, 1, 1), 0.12),
			Material = Enum.Material.Concrete,
		})
		for c = 1, cols do
			local x = -width / 2 + colGap * (c - 0.5)
			local lit = rng:NextNumber() < 0.55
			CityKit.part(m, {
				Name = lit and "WindowLit" or "Window",
				Size = Vector3.new(winW, 3, 0.3),
				CFrame = cf * CFrame.new(x, y, 0.1),
				Color = lit and (rng:NextNumber() < 0.75 and Palette.WindowWarm or Palette.WindowCool) or Palette.Glass,
				Material = lit and Enum.Material.Neon or Enum.Material.Glass,
			})
		end
	end

	-- storefront
	if cfg.storefront ~= false then
		CityKit.part(m, {
			Name = "StoreGlass",
			Size = Vector3.new(width - 2, groundH - 3, 0.3),
			CFrame = cf * CFrame.new(0, (groundH - 3) / 2 + 1, 0.15),
			Color = Palette.Glass,
			Material = Enum.Material.Glass,
			Reflectance = 0.08,
		})
		CityKit.part(m, {
			Name = "Bulkhead",
			Size = Vector3.new(width, 1.4, 0.5),
			CFrame = cf * CFrame.new(0, 0.7, 0.2),
			Color = Palette.Metal,
			Material = Enum.Material.Metal,
		})
		local shop = cfg.shop or SHOPS[rng:NextInteger(1, #SHOPS)]
		local awning = CityKit.part(m, {
			Name = "Awning",
			Size = Vector3.new(width - 1, 0.4, 3.4),
			CFrame = cf * CFrame.new(0, groundH - 1.5, 1.7) * CFrame.Angles(math.rad(-12), 0, 0),
			Color = shop[2]:Lerp(Color3.new(0, 0, 0), 0.35),
			Material = Enum.Material.Fabric,
		})
		local signBox = CityKit.part(m, {
			Name = "NeonSign",
			Size = Vector3.new(math.min(width - 4, 14), 2.2, 0.4),
			CFrame = cf * CFrame.new(0, groundH + 0.4, 0.5),
			Color = shop[2],
			Material = Enum.Material.Neon,
		})
		CityKit.surfaceSign(signBox, Enum.NormalId.Front, shop[1], Color3.fromRGB(20, 16, 22))
		CityKit.light(awning, { Range = 12, Brightness = 1.1, Color = shop[2]:Lerp(Palette.LampWarm, 0.4) })
	end

	-- fire escape (front face, offset to one side)
	if cfg.fireEscape then
		local fx = -width / 4
		for f = 1, floors - 1 do
			local y = groundH + (f - 1) * floorH + 1
			CityKit.part(m, {
				Name = "FEPlatform",
				Size = Vector3.new(width / 2.4, 0.2, 1.6),
				CFrame = cf * CFrame.new(fx, y, 1),
				Color = Palette.Metal,
				Material = Enum.Material.DiamondPlate,
			})
			CityKit.part(m, {
				Name = "FERail",
				Size = Vector3.new(width / 2.4, 1, 0.1),
				CFrame = cf * CFrame.new(fx, y + 0.6, 1.7),
				Color = Palette.Metal,
				Material = Enum.Material.Metal,
			})
			CityKit.part(m, {
				Name = "FELadder",
				Size = Vector3.new(0.6, floorH, 0.1),
				CFrame = cf * CFrame.new(fx + width / 6, y + floorH / 2, 1),
				Color = Palette.Metal,
				Material = Enum.Material.Metal,
			})
		end
	end

	-- roof clutter
	CityKit.part(m, {
		Name = "RoofDeck",
		Size = Vector3.new(width, 0.6, depth),
		CFrame = cf * CFrame.new(0, totalH + 0.3, -depth / 2),
		Color = Color3.fromRGB(40, 40, 48),
		Material = Enum.Material.Concrete,
	})
	for _ = 1, rng:NextInteger(1, 3) do
		CityKit.part(m, {
			Name = "RoofUnit",
			Size = Vector3.new(rand(rng, 2, 4), rand(rng, 1.5, 3), rand(rng, 2, 4)),
			CFrame = cf * CFrame.new(rand(rng, -width / 3, width / 3), totalH + 1.5, -depth / 2 + rand(rng, -depth / 4, depth / 4)),
			Color = Palette.Metal,
			Material = Enum.Material.CorrodedMetal,
		})
	end
	if cfg.water then
		local ty = totalH + 4
		CityKit.part(m, {
			Name = "WaterTank",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(7, 6, 6),
			CFrame = cf * CFrame.new(width / 4, ty, -depth / 2) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(96, 66, 44),
			Material = Enum.Material.WoodPlanks,
		})
		for _, sx in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				CityKit.part(m, {
					Name = "TankLeg",
					Size = Vector3.new(0.4, 5, 0.4),
					CFrame = cf * CFrame.new(width / 4 + sx * 2, totalH + 2.5, -depth / 2 + sz * 2),
					Color = Palette.Metal,
					Material = Enum.Material.Metal,
				})
			end
		end
	end
	if cfg.setback then
		local sw, sh, sd = width * 0.6, floorH * rng:NextInteger(2, 4), depth * 0.7
		CityKit.part(m, {
			Name = "Setback",
			Size = Vector3.new(sw, sh, sd),
			CFrame = cf * CFrame.new(0, totalH + sh / 2 + 0.6, -depth / 2),
			Color = facade,
			Material = Enum.Material.Brick,
		})
	end

	m.Parent = parent
	return m
end

----------------------------------------------------------------
-- Distant skyline
----------------------------------------------------------------

-- cfg = { origin (CFrame, faces the city), rows, perRow, spanX, rowGap,
--         minH, maxH, seed }
function CityKit.skyline(parent, cfg)
	local rng = Random.new(cfg.seed or 7)
	local m = Instance.new("Model")
	m.Name = "Skyline"

	CityKit.part(m, {
		Name = "SkylineBase",
		Size = Vector3.new(cfg.spanX + 40, 4, cfg.rows * cfg.rowGap + 60),
		CFrame = cfg.origin * CFrame.new(0, -2, -(cfg.rows * cfg.rowGap) / 2),
		Color = Color3.fromRGB(24, 24, 32),
		CanCollide = false,
	})

	for r = 1, cfg.rows do
		local t = (r - 1) / math.max(cfg.rows - 1, 1)
		local color = Palette.SkylineNear:Lerp(Palette.SkylineFar, t)
		for i = 1, cfg.perRow do
			local x = -cfg.spanX / 2 + cfg.spanX * ((i - 0.5) / cfg.perRow) + rand(rng, -6, 6)
			local h = rand(rng, cfg.minH, cfg.maxH) * (0.7 + 0.3 * t)
			local w = rand(rng, 20, 58)
			local d = rand(rng, 20, 46)
			local z = -(r - 1) * cfg.rowGap - rand(rng, 0, cfg.rowGap * 0.3)
			local tower = CityKit.part(m, {
				Name = "Tower",
				Size = Vector3.new(w, h, d),
				CFrame = cfg.origin * CFrame.new(x, h / 2, z),
				Color = color,
				Material = Enum.Material.Concrete,
				CanCollide = false,
				Reflectance = 0.04,
			})
			if rng:NextNumber() < 0.5 then
				CityKit.part(m, {
					Name = "TowerNeon",
					Size = Vector3.new(math.min(w * 0.5, 6), h * rand(rng, 0.3, 0.6), 0.4),
					CFrame = tower.CFrame * CFrame.new(rand(rng, -w / 4, w / 4), rand(rng, -h / 6, h / 4), d / 2 + 0.1),
					Color = NEONS[rng:NextInteger(1, #NEONS)],
					Material = Enum.Material.Neon,
					CanCollide = false,
				})
			end
			if h > cfg.maxH * 0.8 then
				local beacon = CityKit.part(m, {
					Name = "Beacon",
					Shape = Enum.PartType.Ball,
					Size = Vector3.new(1.5, 1.5, 1.5),
					CFrame = tower.CFrame * CFrame.new(0, h / 2 + 0.5, 0),
					Color = Palette.NeonRed,
					Material = Enum.Material.Neon,
					CanCollide = false,
				})
				CityKit.light(beacon, { Color = Palette.NeonRed, Range = 8, Brightness = 2 })
			end
		end
	end

	m.Parent = parent
	return m
end

----------------------------------------------------------------
-- Street props
----------------------------------------------------------------

-- `withLight` defaults true; pass false for filler posts so a long row doesn't
-- stack up dozens of PointLights on lower-end hardware (the Neon lantern + bloom
-- still reads as "lit").
function CityKit.lamppost(parent, cf, withLight)
	local m = Instance.new("Model")
	m.Name = "Lamppost"
	CityKit.part(m, { Name = "Base", Size = Vector3.new(1.2, 0.6, 1.2), CFrame = cf * CFrame.new(0, 0.3, 0), Color = Palette.Metal, Material = Enum.Material.Metal })
	CityKit.part(m, { Name = "Pole", Size = Vector3.new(0.4, 9, 0.4), CFrame = cf * CFrame.new(0, 4.8, 0), Color = Palette.Metal, Material = Enum.Material.Metal })
	CityKit.part(m, { Name = "Arm", Size = Vector3.new(0.35, 0.35, 3), CFrame = cf * CFrame.new(0, 9, -1.3), Color = Palette.Metal, Material = Enum.Material.Metal })
	local head = CityKit.part(m, {
		Name = "Lantern",
		Size = Vector3.new(1.1, 1.6, 1.1),
		CFrame = cf * CFrame.new(0, 8.7, -2.6),
		Color = Palette.LampWarm,
		Material = Enum.Material.Neon,
	})
	if withLight ~= false then
		CityKit.light(head, { Range = 18, Brightness = 1.6 })
	end
	m.Parent = parent
	return m
end

function CityKit.hydrant(parent, cf)
	local m = Instance.new("Model")
	m.Name = "Hydrant"
	CityKit.part(m, { Name = "Body", Size = Vector3.new(0.9, 1.6, 0.9), CFrame = cf * CFrame.new(0, 0.8, 0), Color = Color3.fromRGB(180, 70, 60), Material = Enum.Material.Metal })
	CityKit.part(m, { Name = "Cap", Shape = Enum.PartType.Ball, Size = Vector3.new(0.9, 0.9, 0.9), CFrame = cf * CFrame.new(0, 1.7, 0), Color = Color3.fromRGB(180, 70, 60), Material = Enum.Material.Metal })
	CityKit.part(m, { Name = "Nut", Size = Vector3.new(0.4, 0.4, 1.4), CFrame = cf * CFrame.new(0, 1.1, 0), Color = Color3.fromRGB(150, 55, 48), Material = Enum.Material.Metal })
	m.Parent = parent
	return m
end

function CityKit.trashCan(parent, cf)
	local m = Instance.new("Model")
	m.Name = "TrashCan"
	CityKit.part(m, { Name = "Can", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.4, 1.8, 1.8), CFrame = cf * CFrame.new(0, 1.2, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(40, 70, 52), Material = Enum.Material.DiamondPlate })
	CityKit.part(m, { Name = "Rim", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 2, 2), CFrame = cf * CFrame.new(0, 2.1, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(30, 52, 40), Material = Enum.Material.Metal })
	m.Parent = parent
	return m
end

function CityKit.planter(parent, cf)
	local m = Instance.new("Model")
	m.Name = "Planter"
	CityKit.part(m, { Name = "Box", Size = Vector3.new(3, 1.4, 3), CFrame = cf * CFrame.new(0, 0.7, 0), Color = Palette.Concrete, Material = Enum.Material.Slate })
	CityKit.part(m, { Name = "Shrub", Shape = Enum.PartType.Ball, Size = Vector3.new(3, 2.6, 3), CFrame = cf * CFrame.new(0, 2.4, 0), Color = Color3.fromRGB(58, 92, 54), Material = Enum.Material.Grass })
	m.Parent = parent
	return m
end

function CityKit.bench(parent, cf)
	local m = Instance.new("Model")
	m.Name = "Bench"
	CityKit.part(m, { Name = "Seat", Size = Vector3.new(4, 0.3, 1.4), CFrame = cf * CFrame.new(0, 1.1, 0), Color = Color3.fromRGB(90, 66, 44), Material = Enum.Material.WoodPlanks })
	CityKit.part(m, { Name = "Back", Size = Vector3.new(4, 1.4, 0.3), CFrame = cf * CFrame.new(0, 1.9, -0.55), Color = Color3.fromRGB(90, 66, 44), Material = Enum.Material.WoodPlanks })
	for _, sx in ipairs({ -1.7, 1.7 }) do
		CityKit.part(m, { Name = "Leg", Size = Vector3.new(0.3, 1.1, 1.4), CFrame = cf * CFrame.new(sx, 0.55, 0), Color = Palette.Metal, Material = Enum.Material.Metal })
	end
	m.Parent = parent
	return m
end

function CityKit.trafficLight(parent, cf)
	local m = Instance.new("Model")
	m.Name = "TrafficLight"
	CityKit.part(m, { Name = "Pole", Size = Vector3.new(0.5, 11, 0.5), CFrame = cf * CFrame.new(0, 5.5, 0), Color = Palette.Metal, Material = Enum.Material.Metal })
	CityKit.part(m, { Name = "Arm", Size = Vector3.new(0.4, 0.4, 6), CFrame = cf * CFrame.new(0, 10.5, -3), Color = Palette.Metal, Material = Enum.Material.Metal })
	local housing = CityKit.part(m, { Name = "Housing", Size = Vector3.new(1.2, 3.2, 1.2), CFrame = cf * CFrame.new(0, 9.4, -5.6), Color = Color3.fromRGB(30, 32, 34), Material = Enum.Material.Metal })
	local green = CityKit.part(m, { Name = "Go", Shape = Enum.PartType.Ball, Size = Vector3.new(0.8, 0.8, 0.8), CFrame = housing.CFrame * CFrame.new(0, -1, -0.6), Color = Palette.NeonGreen, Material = Enum.Material.Neon })
	CityKit.light(green, { Color = Palette.NeonGreen, Range = 7, Brightness = 1.2 })
	CityKit.part(m, { Name = "Walk", Size = Vector3.new(1.6, 1.6, 0.6), CFrame = cf * CFrame.new(0, 4.2, -0.4), Color = Palette.NeonAmber, Material = Enum.Material.Neon })
	m.Parent = parent
	return m
end

function CityKit.taxi(parent, cf)
	local m = Instance.new("Model")
	m.Name = "Taxi"
	local body = CityKit.part(m, { Name = "Body", Size = Vector3.new(2.4, 1.6, 5.6), CFrame = cf * CFrame.new(0, 1.5, 0), Color = Palette.TaxiYellow, Material = Enum.Material.SmoothPlastic })
	m.PrimaryPart = body
	CityKit.part(m, { Name = "Cabin", Size = Vector3.new(2.2, 1.3, 2.8), CFrame = cf * CFrame.new(0, 2.7, -0.2), Color = Color3.fromRGB(24, 26, 30), Material = Enum.Material.Glass, Reflectance = 0.1 })
	local medallion = CityKit.part(m, { Name = "Medallion", Size = Vector3.new(1, 0.5, 0.8), CFrame = cf * CFrame.new(0, 3.5, 0), Color = Palette.NeonAmber, Material = Enum.Material.Neon })
	CityKit.light(medallion, { Color = Palette.NeonAmber, Range = 6, Brightness = 0.8 })
	CityKit.part(m, { Name = "TailLight", Size = Vector3.new(2.2, 0.4, 0.3), CFrame = cf * CFrame.new(0, 1.4, 2.85), Color = Palette.NeonRed, Material = Enum.Material.Neon })
	for _, sx in ipairs({ -1.25, 1.25 }) do
		for _, sz in ipairs({ -1.9, 1.9 }) do
			CityKit.part(m, {
				Name = "Wheel",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.5, 1.4, 1.4),
				CFrame = cf * CFrame.new(sx, 0.8, sz) * CFrame.Angles(0, 0, math.rad(90)),
				Color = Color3.fromRGB(24, 24, 26),
				Material = Enum.Material.SmoothPlastic,
			})
		end
	end
	m.Parent = parent
	return m
end

function CityKit.steamVent(parent, cf)
	local m = Instance.new("Model")
	m.Name = "SteamVent"
	CityKit.part(m, { Name = "Manhole", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 3, 3), CFrame = cf * CFrame.new(0, 0.05, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(40, 40, 44), Material = Enum.Material.Metal })
	for i = 0, 2 do
		CityKit.part(m, { Name = "Cone", Size = Vector3.new(0.8, 1.6, 0.8), CFrame = cf * CFrame.new(math.sin(i * 2) * 2, 0.8, math.cos(i * 2) * 2), Color = Color3.fromRGB(230, 120, 40), Material = Enum.Material.SmoothPlastic })
	end
	local emitter = CityKit.part(m, { Name = "Emitter", Size = Vector3.new(1, 1, 1), Transparency = 1, CanCollide = false, CFrame = cf * CFrame.new(0, 1, 0) })
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(220, 220, 225))
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.75),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.Size = NumberSequence.new(3, 9)
	pe.Lifetime = NumberRange.new(3, 5)
	pe.Rate = 8
	pe.Speed = NumberRange.new(3, 6)
	pe.VelocitySpread = 20
	pe.Acceleration = Vector3.new(0, 4, 0)
	pe.LockedToPart = false
	pe.Parent = emitter
	m.Parent = parent
	return m
end

function CityKit.busShelter(parent, cf)
	local m = Instance.new("Model")
	m.Name = "BusShelter"
	CityKit.part(m, { Name = "Roof", Size = Vector3.new(10, 0.4, 4), CFrame = cf * CFrame.new(0, 7, 0), Color = Palette.Metal, Material = Enum.Material.Metal })
	CityKit.part(m, { Name = "BackGlass", Size = Vector3.new(10, 6, 0.2), CFrame = cf * CFrame.new(0, 4, 1.9), Color = Palette.Glass, Material = Enum.Material.Glass, Reflectance = 0.1 })
	for _, sx in ipairs({ -4.8, 4.8 }) do
		CityKit.part(m, { Name = "Post", Size = Vector3.new(0.3, 7, 0.3), CFrame = cf * CFrame.new(sx, 3.5, 0), Color = Palette.Metal, Material = Enum.Material.Metal })
	end
	local ad = CityKit.part(m, { Name = "AdPanel", Size = Vector3.new(2.4, 4, 0.3), CFrame = cf * CFrame.new(4.8, 3.4, 0), Color = Color3.fromRGB(230, 230, 235), Material = Enum.Material.Neon })
	ad.Transparency = 0.05
	CityKit.light(ad, { Color = Color3.fromRGB(210, 220, 255), Range = 8, Brightness = 0.7 })
	CityKit.bench(m, cf * CFrame.new(0, 0, 0.6))
	m.Parent = parent
	return m
end

function CityKit.scaffold(parent, cf, length)
	local m = Instance.new("Model")
	m.Name = "SidewalkShed"
	local h = 10
	for x = -length / 2, length / 2, 6 do
		for _, sz in ipairs({ -1.6, 1.6 }) do
			CityKit.part(m, { Name = "Post", Size = Vector3.new(0.4, h, 0.4), CFrame = cf * CFrame.new(x, h / 2, sz), Color = Palette.Steel, Material = Enum.Material.Metal })
		end
	end
	CityKit.part(m, { Name = "Deck", Size = Vector3.new(length, 0.6, 4), CFrame = cf * CFrame.new(0, h, 0), Color = Color3.fromRGB(120, 96, 64), Material = Enum.Material.WoodPlanks })
	CityKit.part(m, { Name = "Fascia", Size = Vector3.new(length, 1.6, 0.2), CFrame = cf * CFrame.new(0, h - 0.8, -1.9), Color = Color3.fromRGB(70, 110, 170), Material = Enum.Material.SmoothPlastic })
	for x = -length / 2 + 4, length / 2, 8 do
		local clip = CityKit.part(m, { Name = "ClipLight", Size = Vector3.new(0.5, 0.5, 0.5), CFrame = cf * CFrame.new(x, h - 1.4, 1.5), Color = Palette.LampWarm, Material = Enum.Material.Neon })
		if (x + length / 2) % 16 < 8 then
			CityKit.light(clip, { Range = 8, Brightness = 0.9 })
		end
	end
	m.Parent = parent
	return m
end

-- Keeps the caller's existing ReturnPoint / prompt; just dresses the spot.
function CityKit.subwayEntrance(parent, cf)
	local m = Instance.new("Model")
	m.Name = "SubwayEntrance"
	CityKit.part(m, { Name = "Surround", Size = Vector3.new(9, 1, 7), CFrame = cf * CFrame.new(0, 0.5, 0), Color = Palette.Concrete, Material = Enum.Material.Concrete })
	CityKit.part(m, { Name = "Stairwell", Size = Vector3.new(6, 4, 4), CFrame = cf * CFrame.new(0, -1.8, 0), Color = Color3.fromRGB(20, 20, 24), Material = Enum.Material.Slate })
	for _, sx in ipairs({ -3.2, 3.2 }) do
		CityKit.part(m, { Name = "Rail", Size = Vector3.new(0.3, 3.4, 6), CFrame = cf * CFrame.new(sx, 1.7, 0), Color = Palette.SubwayGreen, Material = Enum.Material.Metal })
		local globe = CityKit.part(m, {
			Name = "Globe",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1.4, 1.4, 1.4),
			CFrame = cf * CFrame.new(sx, 4, 3),
			Color = Palette.NeonGreen,
			Material = Enum.Material.Neon,
		})
		CityKit.light(globe, { Color = Palette.NeonGreen, Range = 12, Brightness = 1.3 })
		CityKit.part(m, { Name = "GlobePost", Size = Vector3.new(0.3, 4, 0.3), CFrame = cf * CFrame.new(sx, 2, 3), Color = Palette.SubwayGreen, Material = Enum.Material.Metal })
	end
	local sign = CityKit.part(m, { Name = "Roundel", Size = Vector3.new(3, 3, 0.3), CFrame = cf * CFrame.new(0, 4.4, -3.4), Color = Color3.fromRGB(18, 18, 22), Material = Enum.Material.SmoothPlastic })
	CityKit.surfaceSign(sign, Enum.NormalId.Back, "SUBWAY", Palette.NeonGreen)
	CityKit.surfaceSign(sign, Enum.NormalId.Front, "SUBWAY", Palette.NeonGreen)
	m.Parent = parent
	return m
end

-- Green NYC street-name blades on a corner pole.
function CityKit.bladeSign(parent, cf, names)
	local m = Instance.new("Model")
	m.Name = "StreetSign"
	CityKit.part(m, { Name = "Pole", Size = Vector3.new(0.4, 12, 0.4), CFrame = cf * CFrame.new(0, 6, 0), Color = Palette.Metal, Material = Enum.Material.Metal })
	local blade1 = CityKit.part(m, { Name = "Blade1", Size = Vector3.new(8, 1.6, 0.2), CFrame = cf * CFrame.new(3.6, 11, 0), Color = Palette.SubwayGreen, Material = Enum.Material.SmoothPlastic })
	CityKit.surfaceSign(blade1, Enum.NormalId.Front, names[1] or "BROADWAY", Color3.fromRGB(240, 240, 240))
	CityKit.surfaceSign(blade1, Enum.NormalId.Back, names[1] or "BROADWAY", Color3.fromRGB(240, 240, 240))
	local blade2 = CityKit.part(m, { Name = "Blade2", Size = Vector3.new(0.2, 1.6, 8), CFrame = cf * CFrame.new(0, 9.2, 3.6), Color = Palette.SubwayGreen, Material = Enum.Material.SmoothPlastic })
	CityKit.surfaceSign(blade2, Enum.NormalId.Right, names[2] or "W 42 ST", Color3.fromRGB(240, 240, 240))
	CityKit.surfaceSign(blade2, Enum.NormalId.Left, names[2] or "W 42 ST", Color3.fromRGB(240, 240, 240))
	m.Parent = parent
	return m
end

return CityKit
