-- Graybox construction kit for the hub garden - a calm, lush park around the
-- six plots. Deliberately shares nothing visual with CityKit: soft greens,
-- warm stone, water and wood instead of brick, neon and asphalt.
--
-- Convention: a factory's `cf` sits on the ground (walk surface Y that the
-- caller passes as the Y of `cf`); props build upward from there.

local BuildKit = require(script.Parent.BuildKit)

local ParkKit = {}
ParkKit.part = BuildKit.part
ParkKit.light = BuildKit.light

local Palette = {
	LawnLight = Color3.fromRGB(128, 178, 96),
	LawnDark = Color3.fromRGB(100, 152, 78),
	PathStone = Color3.fromRGB(210, 196, 172),
	PathEdge = Color3.fromRGB(176, 160, 136),
	Gravel = Color3.fromRGB(200, 192, 178),
	Soil = Color3.fromRGB(92, 66, 48),
	Water = Color3.fromRGB(104, 174, 200),
	Wood = Color3.fromRGB(156, 116, 78),
	WoodDark = Color3.fromRGB(116, 84, 56),
	Stone = Color3.fromRGB(182, 178, 170),
	StoneDark = Color3.fromRGB(146, 142, 134),
	Hedge = Color3.fromRGB(80, 128, 66),
	LeafLight = Color3.fromRGB(122, 180, 92),
	LeafMid = Color3.fromRGB(98, 158, 78),
	LeafDark = Color3.fromRGB(76, 130, 66),
	Blossom = Color3.fromRGB(246, 194, 214),
	LampGlow = Color3.fromRGB(255, 226, 172),
	RoofTile = Color3.fromRGB(158, 102, 84),
	Iron = Color3.fromRGB(70, 72, 74),
}
ParkKit.Palette = Palette

local FLOWERS = {
	Color3.fromRGB(246, 152, 182),
	Color3.fromRGB(250, 214, 112),
	Color3.fromRGB(246, 242, 230),
	Color3.fromRGB(198, 172, 236),
	Color3.fromRGB(228, 112, 112),
	Color3.fromRGB(248, 170, 98),
}
local LEAVES = { Palette.LeafLight, Palette.LeafMid, Palette.LeafDark }

local function rand(rng, a, b)
	return a + (b - a) * rng:NextNumber()
end
local function pick(rng, t)
	return t[rng:NextInteger(1, #t)]
end

----------------------------------------------------------------
-- Ground
----------------------------------------------------------------

function ParkKit.ground(parent, cf, w, d, color, material)
	return ParkKit.part(parent, {
		Name = "Ground",
		Size = Vector3.new(w, 1, d),
		CFrame = cf * CFrame.new(0, -0.5, 0),
		Color = color or Palette.LawnLight,
		Material = material or Enum.Material.Grass,
	})
end

function ParkKit.path(parent, cf, w, l)
	ParkKit.part(parent, {
		Name = "Path",
		Size = Vector3.new(w, 0.3, l),
		CFrame = cf * CFrame.new(0, 0.12, 0),
		Color = Palette.PathStone,
		Material = Enum.Material.Cobblestone,
	})
	for _, sx in ipairs({ -1, 1 }) do
		ParkKit.part(parent, {
			Name = "PathEdge",
			Size = Vector3.new(0.5, 0.4, l),
			CFrame = cf * CFrame.new(sx * (w / 2 + 0.2), 0.16, 0),
			Color = Palette.PathEdge,
			Material = Enum.Material.Slate,
		})
	end
end

function ParkKit.steppingStones(parent, cf, count, spacing)
	for i = 1, count do
		ParkKit.part(parent, {
			Name = "SteppingStone",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.3, 2.2, 1.8),
			CFrame = cf * CFrame.new(0, 0.1, (i - (count + 1) / 2) * spacing) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Palette.Stone,
			Material = Enum.Material.Slate,
		})
	end
end

----------------------------------------------------------------
-- Planting
----------------------------------------------------------------

-- opts: { seed, height, spread, blossom, lean }
function ParkKit.tree(parent, cf, opts)
	opts = opts or {}
	local rng = Random.new(opts.seed or 1)
	local h = opts.height or rand(rng, 9, 15)
	local spread = opts.spread or h * 0.55
	local m = Instance.new("Model")
	m.Name = "Tree"

	local trunk = ParkKit.part(m, {
		Name = "Trunk",
		Size = Vector3.new(h * 0.14, h, h * 0.14),
		CFrame = cf * CFrame.new(0, h / 2, 0) * CFrame.Angles(math.rad((opts.lean or 0)), 0, 0),
		Color = Palette.Wood,
		Material = Enum.Material.Wood,
	})
	m.PrimaryPart = trunk

	local blobs = rng:NextInteger(3, 5)
	for i = 1, blobs do
		local r = spread * rand(rng, 0.55, 1)
		local off = CFrame.new(
			rand(rng, -spread * 0.5, spread * 0.5),
			h + rand(rng, -h * 0.12, h * 0.22),
			rand(rng, -spread * 0.5, spread * 0.5)
		)
		local blossom = opts.blossom and rng:NextNumber() < 0.4
		ParkKit.part(m, {
			Name = blossom and "Blossom" or "Canopy",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(r, r * 0.9, r),
			CFrame = cf * off,
			Color = blossom and Palette.Blossom or pick(rng, LEAVES),
			Material = Enum.Material.Grass,
		})
	end
	m.Parent = parent
	return m
end

function ParkKit.bush(parent, cf, r, seed)
	local rng = Random.new(seed or 2)
	local m = Instance.new("Model")
	m.Name = "Bush"
	for i = 1, rng:NextInteger(1, 3) do
		ParkKit.part(m, {
			Name = "Leaf",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(r, r * 0.85, r) * rand(rng, 0.7, 1),
			CFrame = cf * CFrame.new(rand(rng, -r * 0.4, r * 0.4), r * 0.4, rand(rng, -r * 0.4, r * 0.4)),
			Color = pick(rng, LEAVES),
			Material = Enum.Material.Grass,
		})
	end
	m.Parent = parent
	return m
end

-- A trimmed hedge run. `cf` is the centre; it extends along local X.
function ParkKit.hedge(parent, cf, length, height)
	height = height or 3
	local m = Instance.new("Model")
	m.Name = "Hedge"
	ParkKit.part(m, {
		Name = "Body",
		Size = Vector3.new(length, height, 2.4),
		CFrame = cf * CFrame.new(0, height / 2, 0),
		Color = Palette.Hedge,
		Material = Enum.Material.Grass,
	})
	for x = -length / 2 + 1.5, length / 2, 3 do
		ParkKit.part(m, {
			Name = "Tuft",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(3, 2, 3),
			CFrame = cf * CFrame.new(x, height, 0),
			Color = Palette.Hedge,
			Material = Enum.Material.Grass,
		})
	end
	m.Parent = parent
	return m
end

-- Soil bed with clumps of flowers. `cf` centre; size along local X / Z.
function ParkKit.flowerBed(parent, cf, w, d, seed)
	local rng = Random.new(seed or 3)
	local m = Instance.new("Model")
	m.Name = "FlowerBed"
	ParkKit.part(m, {
		Name = "Soil",
		Size = Vector3.new(w, 0.5, d),
		CFrame = cf * CFrame.new(0, 0.2, 0),
		Color = Palette.Soil,
		Material = Enum.Material.Ground,
	})
	local clumps = math.clamp(math.floor(w * d / 7), 3, 10)
	for _ = 1, clumps do
		local base = cf * CFrame.new(rand(rng, -w / 2 + 0.6, w / 2 - 0.6), 0.5, rand(rng, -d / 2 + 0.6, d / 2 - 0.6))
		ParkKit.part(m, {
			Name = "Stem",
			Size = Vector3.new(0.5, 1, 0.5),
			CFrame = base * CFrame.new(0, 0.5, 0),
			Color = Palette.LeafDark,
			Material = Enum.Material.Grass,
		})
		local col = pick(rng, FLOWERS)
		for _ = 1, rng:NextInteger(2, 4) do
			ParkKit.part(m, {
				Name = "Bloom",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(0.7, 0.7, 0.7),
				CFrame = base * CFrame.new(rand(rng, -0.4, 0.4), rand(rng, 0.9, 1.4), rand(rng, -0.4, 0.4)),
				Color = col,
				Material = Enum.Material.Neon,
			})
		end
	end
	m.Parent = parent
	return m
end

function ParkKit.planter(parent, cf, seed)
	local m = Instance.new("Model")
	m.Name = "Planter"
	ParkKit.part(m, { Name = "Box", Size = Vector3.new(4, 2, 2.4), CFrame = cf * CFrame.new(0, 1, 0), Color = Palette.Wood, Material = Enum.Material.WoodPlanks })
	ParkKit.part(m, { Name = "Soil", Size = Vector3.new(3.6, 0.4, 2), CFrame = cf * CFrame.new(0, 2, 0), Color = Palette.Soil, Material = Enum.Material.Ground })
	local rng = Random.new(seed or 4)
	for i = -1, 1 do
		ParkKit.part(m, {
			Name = "Bloom",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1.2, 1.2, 1.2),
			CFrame = cf * CFrame.new(i * 1.2, 2.7, 0),
			Color = pick(rng, FLOWERS),
			Material = Enum.Material.Neon,
		})
	end
	m.Parent = parent
	return m
end

----------------------------------------------------------------
-- Water
----------------------------------------------------------------

local function waterPart(parent, name, size, cf)
	return ParkKit.part(parent, {
		Name = name,
		Size = size,
		CFrame = cf,
		Color = Palette.Water,
		Material = Enum.Material.Glass,
		Transparency = 0.3,
		Reflectance = 0.12,
	})
end

function ParkKit.pond(parent, cf, w, d, seed)
	local rng = Random.new(seed or 5)
	local m = Instance.new("Model")
	m.Name = "Pond"
	ParkKit.part(m, { Name = "Bed", Size = Vector3.new(w + 2, 1, d + 2), CFrame = cf * CFrame.new(0, -0.4, 0), Color = Color3.fromRGB(48, 62, 60), Material = Enum.Material.Slate })
	waterPart(m, "Water", Vector3.new(w, 0.6, d), cf * CFrame.new(0, 0.05, 0))
	-- rock rim
	local per = math.floor((w + d) / 2)
	for i = 1, per do
		local a = (i / per) * math.pi * 2
		ParkKit.part(m, {
			Name = "Rock",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(rand(rng, 1.5, 3), rand(rng, 1.2, 2), rand(rng, 1.5, 3)),
			CFrame = cf * CFrame.new(math.cos(a) * (w / 2 + 0.3), 0.2, math.sin(a) * (d / 2 + 0.3)),
			Color = pick(rng, { Palette.Stone, Palette.StoneDark }),
			Material = Enum.Material.Slate,
		})
	end
	-- lily pads + reeds
	for _ = 1, math.max(2, per // 3) do
		local p = cf * CFrame.new(rand(rng, -w / 3, w / 3), 0.35, rand(rng, -d / 3, d / 3))
		ParkKit.part(m, { Name = "LilyPad", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, rand(rng, 1.6, 2.6), rand(rng, 1.6, 2.6)), CFrame = p * CFrame.Angles(0, 0, math.rad(90)), Color = Palette.LeafMid, Material = Enum.Material.Grass })
		if rng:NextNumber() < 0.5 then
			ParkKit.part(m, { Name = "LilyFlower", Shape = Enum.PartType.Ball, Size = Vector3.new(0.8, 0.8, 0.8), CFrame = p * CFrame.new(0, 0.4, 0), Color = Palette.Blossom, Material = Enum.Material.Neon })
		end
	end
	m.Parent = parent
	return m
end

function ParkKit.bridge(parent, cf, span)
	local m = Instance.new("Model")
	m.Name = "Bridge"
	local segs = 5
	for i = 1, segs do
		local t = (i - (segs + 1) / 2) / segs
		local rise = (1 - (t * 2) ^ 2) * 1.6
		ParkKit.part(m, {
			Name = "Plank",
			Size = Vector3.new(6, 0.4, span / segs + 0.4),
			CFrame = cf * CFrame.new(0, 1 + rise, t * span) * CFrame.Angles(math.rad(-t * 26), 0, 0),
			Color = Palette.Wood,
			Material = Enum.Material.WoodPlanks,
		})
	end
	for _, sx in ipairs({ -2.8, 2.8 }) do
		for i = 1, segs do
			local t = (i - (segs + 1) / 2) / segs
			local rise = (1 - (t * 2) ^ 2) * 1.6
			ParkKit.part(m, { Name = "Post", Size = Vector3.new(0.3, 2.2, 0.3), CFrame = cf * CFrame.new(sx, 1.4 + rise, t * span), Color = Palette.WoodDark, Material = Enum.Material.Wood })
		end
		ParkKit.part(m, { Name = "Rail", Size = Vector3.new(0.3, 0.3, span), CFrame = cf * CFrame.new(sx, 3.2, 0), Color = Palette.WoodDark, Material = Enum.Material.Wood })
	end
	m.Parent = parent
	return m
end

function ParkKit.birdbath(parent, cf)
	local m = Instance.new("Model")
	m.Name = "Birdbath"
	ParkKit.part(m, { Name = "Pedestal", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 1.4, 1.4), CFrame = cf * CFrame.new(0, 1.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Palette.Stone, Material = Enum.Material.Marble })
	ParkKit.part(m, { Name = "Bowl", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 3.6, 3.6), CFrame = cf * CFrame.new(0, 3.1, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Palette.Stone, Material = Enum.Material.Marble })
	waterPart(m, "Water", Vector3.new(0.2, 3, 3), cf * CFrame.new(0, 3.35, 0) * CFrame.Angles(0, 0, math.rad(90)))
	m.Parent = parent
	return m
end

function ParkKit.fountain(parent, cf)
	local m = Instance.new("Model")
	m.Name = "Fountain"
	ParkKit.part(m, { Name = "BasinWall", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 16, 16), CFrame = cf * CFrame.new(0, 1, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Palette.Stone, Material = Enum.Material.Marble })
	waterPart(m, "LowerWater", Vector3.new(0.6, 14.5, 14.5), cf * CFrame.new(0, 1.6, 0) * CFrame.Angles(0, 0, math.rad(90)))
	ParkKit.part(m, { Name = "Pedestal", Shape = Enum.PartType.Cylinder, Size = Vector3.new(4, 3, 3), CFrame = cf * CFrame.new(0, 3, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Palette.StoneDark, Material = Enum.Material.Marble })
	ParkKit.part(m, { Name = "UpperBowl", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 7, 7), CFrame = cf * CFrame.new(0, 4.6, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Palette.Stone, Material = Enum.Material.Marble })
	waterPart(m, "UpperWater", Vector3.new(0.5, 6, 6), cf * CFrame.new(0, 5, 0) * CFrame.Angles(0, 0, math.rad(90)))
	local jet = ParkKit.part(m, { Name = "Jet", Size = Vector3.new(0.6, 4, 0.6), Transparency = 0.4, CanCollide = false, CFrame = cf * CFrame.new(0, 7, 0), Color = Color3.fromRGB(228, 244, 250), Material = Enum.Material.Glass })
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(220, 240, 250))
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	pe.Size = NumberSequence.new(0.6, 0.2)
	pe.Lifetime = NumberRange.new(1.2, 1.8)
	pe.Rate = 40
	pe.Speed = NumberRange.new(6, 9)
	pe.SpreadAngle = Vector2.new(16, 16)
	pe.Acceleration = Vector3.new(0, -22, 0)
	pe.Parent = jet
	BuildKit.light(jet, { Color = Color3.fromRGB(200, 226, 240), Range = 16, Brightness = 1 })
	m.Parent = parent
	return m
end

----------------------------------------------------------------
-- Furniture + structures
----------------------------------------------------------------

function ParkKit.bench(parent, cf)
	local m = Instance.new("Model")
	m.Name = "GardenBench"
	for i = -1, 1 do
		ParkKit.part(m, { Name = "SeatSlat", Size = Vector3.new(4.4, 0.2, 0.5), CFrame = cf * CFrame.new(0, 1.1, i * 0.55), Color = Palette.Wood, Material = Enum.Material.WoodPlanks })
		ParkKit.part(m, { Name = "BackSlat", Size = Vector3.new(4.4, 0.5, 0.2), CFrame = cf * CFrame.new(0, 1.8 + i * 0.5, -0.7), Color = Palette.Wood, Material = Enum.Material.WoodPlanks })
	end
	for _, sx in ipairs({ -2, 2 }) do
		ParkKit.part(m, { Name = "Leg", Size = Vector3.new(0.25, 1.1, 1.6), CFrame = cf * CFrame.new(sx, 0.55, 0), Color = Palette.Iron, Material = Enum.Material.Metal })
		ParkKit.part(m, { Name = "Arm", Size = Vector3.new(0.25, 0.25, 1.6), CFrame = cf * CFrame.new(sx, 1.75, 0), Color = Palette.Iron, Material = Enum.Material.Metal })
	end
	m.Parent = parent
	return m
end

function ParkKit.picnicTable(parent, cf)
	local m = Instance.new("Model")
	m.Name = "PicnicTable"
	ParkKit.part(m, { Name = "Top", Size = Vector3.new(6, 0.4, 3.2), CFrame = cf * CFrame.new(0, 2.6, 0), Color = Palette.Wood, Material = Enum.Material.WoodPlanks })
	for _, sz in ipairs({ -2.3, 2.3 }) do
		ParkKit.part(m, { Name = "Seat", Size = Vector3.new(6, 0.3, 1.2), CFrame = cf * CFrame.new(0, 1.5, sz), Color = Palette.Wood, Material = Enum.Material.WoodPlanks })
	end
	for _, sx in ipairs({ -2.5, 2.5 }) do
		ParkKit.part(m, { Name = "Leg", Size = Vector3.new(0.4, 3, 5), CFrame = cf * CFrame.new(sx, 1.1, 0) * CFrame.Angles(0, 0, math.rad(sx > 0 and 12 or -12)), Color = Palette.WoodDark, Material = Enum.Material.Wood })
	end
	m.Parent = parent
	return m
end

function ParkKit.lamp(parent, cf)
	local m = Instance.new("Model")
	m.Name = "GardenLamp"
	ParkKit.part(m, { Name = "Base", Size = Vector3.new(1, 0.6, 1), CFrame = cf * CFrame.new(0, 0.3, 0), Color = Palette.Iron, Material = Enum.Material.Metal })
	ParkKit.part(m, { Name = "Post", Size = Vector3.new(0.35, 6, 0.35), CFrame = cf * CFrame.new(0, 3.2, 0), Color = Palette.Iron, Material = Enum.Material.Metal })
	local globe = ParkKit.part(m, {
		Name = "Globe",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(1.4, 1.6, 1.4),
		CFrame = cf * CFrame.new(0, 6.6, 0),
		Color = Palette.LampGlow,
		Material = Enum.Material.Neon,
	})
	ParkKit.part(m, { Name = "Cap", Size = Vector3.new(1, 0.4, 1), CFrame = cf * CFrame.new(0, 7.5, 0), Color = Palette.Iron, Material = Enum.Material.Metal })
	BuildKit.light(globe, { Color = Palette.LampGlow, Range = 18, Brightness = 1.5 })
	m.Parent = parent
	return m
end

-- Warm hanging string of bulbs between two world points.
function ParkKit.stringLights(parent, fromPos, toPos, sag)
	sag = sag or 3
	local m = Instance.new("Model")
	m.Name = "StringLights"
	local steps = 8
	for i = 0, steps do
		local t = i / steps
		local pos = fromPos:Lerp(toPos, t)
		local drop = math.sin(t * math.pi) * sag
		ParkKit.part(m, {
			Name = "Bulb",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(0.5, 0.5, 0.5),
			CFrame = CFrame.new(pos - Vector3.new(0, drop, 0)),
			Color = Palette.LampGlow,
			Material = Enum.Material.Neon,
			CanCollide = false,
		})
	end
	m.Parent = parent
	return m
end

function ParkKit.pergola(parent, cf, length)
	local m = Instance.new("Model")
	m.Name = "Pergola"
	for x = -length / 2, length / 2, 5 do
		for _, sz in ipairs({ -2.5, 2.5 }) do
			ParkKit.part(m, { Name = "Post", Size = Vector3.new(0.6, 7, 0.6), CFrame = cf * CFrame.new(x, 3.5, sz), Color = Palette.WoodDark, Material = Enum.Material.Wood })
		end
	end
	for _, sz in ipairs({ -2.5, 2.5 }) do
		ParkKit.part(m, { Name = "Beam", Size = Vector3.new(length + 1, 0.5, 0.5), CFrame = cf * CFrame.new(0, 7.1, sz), Color = Palette.Wood, Material = Enum.Material.Wood })
	end
	for x = -length / 2, length / 2, 2.5 do
		ParkKit.part(m, { Name = "Rafter", Size = Vector3.new(0.4, 0.4, 6.4), CFrame = cf * CFrame.new(x, 7.4, 0), Color = Palette.Wood, Material = Enum.Material.Wood })
		if (x + length / 2) % 5 < 2.5 then
			ParkKit.part(m, { Name = "Vine", Shape = Enum.PartType.Ball, Size = Vector3.new(2, 1.4, 2.4), CFrame = cf * CFrame.new(x, 7.7, 0), Color = Palette.LeafMid, Material = Enum.Material.Grass })
		end
	end
	m.Parent = parent
	return m
end

function ParkKit.gazebo(parent, cf)
	local m = Instance.new("Model")
	m.Name = "Gazebo"
	local r = 6
	ParkKit.part(m, { Name = "Deck", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, r * 2, r * 2), CFrame = cf * CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Palette.Wood, Material = Enum.Material.WoodPlanks })
	for i = 0, 5 do
		local a = math.rad(i * 60)
		local pc = cf * CFrame.new(math.cos(a) * r, 0, math.sin(a) * r)
		ParkKit.part(m, { Name = "Post", Size = Vector3.new(0.5, 8, 0.5), CFrame = pc * CFrame.new(0, 4, 0), Color = Palette.WoodDark, Material = Enum.Material.Wood })
		ParkKit.part(m, { Name = "Rail", Size = Vector3.new(0.4, 1, 0.4), CFrame = pc * CFrame.new(0, 1.4, 0), Color = Palette.WoodDark, Material = Enum.Material.Wood })
		-- roof panel
		ParkKit.part(m, {
			Name = "Roof",
			Size = Vector3.new(r * 1.15, 0.4, 4.6),
			CFrame = cf * CFrame.new(math.cos(a + math.rad(30)) * r * 0.5, 10.4, math.sin(a + math.rad(30)) * r * 0.5)
				* CFrame.Angles(0, -a - math.rad(30), math.rad(34)),
			Color = Palette.RoofTile,
			Material = Enum.Material.Slate,
		})
	end
	local finial = ParkKit.part(m, { Name = "Finial", Shape = Enum.PartType.Ball, Size = Vector3.new(1.4, 1.4, 1.4), CFrame = cf * CFrame.new(0, 12.4, 0), Color = Palette.LampGlow, Material = Enum.Material.Neon })
	BuildKit.light(finial, { Color = Palette.LampGlow, Range = 22, Brightness = 1.4 })
	m.Parent = parent
	return m
end

-- Plot entry arch with a hanging number board. `cf` faces the way in (-Z of cf
-- points at the approaching player).
function ParkKit.plotArch(parent, cf, label, seed)
	local m = Instance.new("Model")
	m.Name = "PlotArch"
	for _, sx in ipairs({ -3.2, 3.2 }) do
		ParkKit.part(m, { Name = "Post", Size = Vector3.new(0.7, 7, 0.7), CFrame = cf * CFrame.new(sx, 3.5, 0), Color = Palette.WoodDark, Material = Enum.Material.Wood })
	end
	-- gentle arch from three angled beams
	for i, seg in ipairs({ -1, 0, 1 }) do
		local ang = seg * math.rad(22)
		ParkKit.part(m, {
			Name = "ArchBeam",
			Size = Vector3.new(3.2, 0.5, 0.6),
			CFrame = cf * CFrame.new(seg * 2.4, 7 + (1 - math.abs(seg)) * 0.7, 0) * CFrame.Angles(0, 0, ang),
			Color = Palette.Wood,
			Material = Enum.Material.Wood,
		})
	end
	local board = ParkKit.part(m, {
		Name = "NumberBoard",
		Size = Vector3.new(3, 2, 0.3),
		CFrame = cf * CFrame.new(0, 5.6, 0),
		Color = Color3.fromRGB(244, 234, 210),
		Material = Enum.Material.WoodPlanks,
	})
	BuildKit.surfaceSign(board, Enum.NormalId.Front, label, Palette.WoodDark, Color3.fromRGB(244, 234, 210), Enum.Font.GothamBold)
	BuildKit.surfaceSign(board, Enum.NormalId.Back, label, Palette.WoodDark, Color3.fromRGB(244, 234, 210), Enum.Font.GothamBold)
	-- climbing roses up the posts
	local rng = Random.new(seed or 6)
	for _, sx in ipairs({ -3.2, 3.2 }) do
		for y = 1.5, 6.5, 1.6 do
			ParkKit.part(m, {
				Name = "Rose",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(1.3, 1.3, 1.3),
				CFrame = cf * CFrame.new(sx + rand(rng, -0.4, 0.4), y, rand(rng, -0.4, 0.4)),
				Color = rng:NextNumber() < 0.5 and Palette.LeafMid or Palette.Blossom,
				Material = Enum.Material.Grass,
			})
		end
	end
	m.Parent = parent
	return m
end

----------------------------------------------------------------
-- Landform
----------------------------------------------------------------

-- A low grassy mound. Only the top ~h shows; the rest is buried.
function ParkKit.berm(parent, cf, w, d, h)
	return ParkKit.part(parent, {
		Name = "Berm",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(w, h * 2.2, d),
		CFrame = cf * CFrame.new(0, -h * 0.15, 0),
		Color = Palette.LawnDark,
		Material = Enum.Material.Grass,
		CanCollide = false,
	})
end

-- A row of simple trees fading into the distance. `originCf` faces the park;
-- the row runs along local X, receding along local -Z over `rows`.
function ParkKit.treeline(parent, originCf, span, perRow, rows, seed)
	local rng = Random.new(seed or 7)
	local m = Instance.new("Model")
	m.Name = "Treeline"
	for r = 1, rows do
		local t = (r - 1) / math.max(rows - 1, 1)
		local col = Palette.LeafDark:Lerp(Color3.fromRGB(120, 140, 150), t * 0.6)
		for i = 1, perRow do
			local x = -span / 2 + span * ((i - 0.5) / perRow) + rand(rng, -6, 6)
			local z = -(r - 1) * 22 - rand(rng, 0, 12)
			local h = rand(rng, 14, 30) * (1 - t * 0.3)
			ParkKit.part(m, { Name = "FarTrunk", Size = Vector3.new(h * 0.12, h, h * 0.12), CFrame = originCf * CFrame.new(x, h / 2, z), Color = Palette.WoodDark, Material = Enum.Material.Wood, CanCollide = false })
			ParkKit.part(m, {
				Name = "FarCanopy",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(h * 0.9, h * 0.8, h * 0.9),
				CFrame = originCf * CFrame.new(x, h, z),
				Color = col,
				Material = Enum.Material.Grass,
				CanCollide = false,
			})
		end
	end
	m.Parent = parent
	return m
end

function ParkKit.hill(parent, cf, w, d, h)
	return ParkKit.part(parent, {
		Name = "Hill",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(w, h * 2, d),
		CFrame = cf * CFrame.new(0, -h * 0.2, 0),
		Color = Palette.LawnDark:Lerp(Color3.fromRGB(120, 140, 150), 0.3),
		Material = Enum.Material.Grass,
		CanCollide = false,
	})
end

return ParkKit
