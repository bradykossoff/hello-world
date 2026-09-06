-- World dressing pass, run by WorldDress.server on server start:
--   * sets a shared bright golden-hour Lighting rig
--   * builds the compact New York street block (road, sidewalks, buildings,
--     shallow skyline, props) around the fixed anchors from eattheworld.rbxl -
--     kept small on purpose: every future destination needs its own space
--   * a lighter cleanup pass over the hub / plaza
--   * game-wide: stops every world BillboardGui from punching through the map
--     and fades it with distance
--
-- Everything generated lives under `<area>.CityDressing` (or NewYork.City) and
-- is wiped + rebuilt each call, so it never fights the hand-built .rbxl content.
--
-- To preview it in Studio WITHOUT playtesting, run this in the command bar:
--   require(game.ServerScriptService.Modules.WorldDress).BuildAll()
-- (the generated models are regenerated on every Play, so tune the numbers
-- in this file rather than hand-editing what it produces.)

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local CityKit = require(ServerScriptService.Modules.CityKit)
local P = CityKit.Palette

local WorldDress = {}

----------------------------------------------------------------
-- Lighting: shared bright golden hour (warm, but clearly lit)
----------------------------------------------------------------

local function applyGoldenHour()
	Lighting.ClockTime = 17.1
	Lighting.GeographicLatitude = 18
	Lighting.Brightness = 3.4
	Lighting.ExposureCompensation = 0.28
	Lighting.Ambient = Color3.fromRGB(132, 126, 132)
	Lighting.OutdoorAmbient = Color3.fromRGB(178, 164, 152)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 206, 156)
	Lighting.ColorShift_Bottom = Color3.fromRGB(158, 168, 196)
	Lighting.EnvironmentDiffuseScale = 0.9
	Lighting.EnvironmentSpecularScale = 0.85
	Lighting.FogEnd = 9000

	-- procedural sky follows ClockTime; a baked daytime skybox would fight it
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if sky then
		sky:Destroy()
	end

	local atmos = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmos.Density = 0.16
	atmos.Offset = 0.1
	atmos.Color = Color3.fromRGB(220, 206, 194)
	atmos.Decay = Color3.fromRGB(150, 140, 155)
	atmos.Glare = 0.08
	atmos.Haze = 0.9
	atmos.Parent = Lighting

	local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
	bloom.Intensity = 0.5
	bloom.Size = 24
	bloom.Threshold = 1.5
	bloom.Parent = Lighting

	local dof = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
	if dof then
		dof.FarIntensity = 0
		dof.NearIntensity = 0
	end

	local sun = Lighting:FindFirstChildOfClass("SunRaysEffect")
	if sun then
		sun.Intensity = 0.08
		sun.Spread = 0.8
	end

	local cc = Lighting:FindFirstChild("CityGrade") or Instance.new("ColorCorrectionEffect")
	cc.Name = "CityGrade"
	cc.Brightness = 0.02
	cc.Contrast = 0.06
	cc.Saturation = 0.14
	cc.TintColor = Color3.fromRGB(255, 246, 236)
	cc.Parent = Lighting
end

----------------------------------------------------------------
-- Shared helpers
----------------------------------------------------------------

local function freshFolder(parent, name)
	local existing = parent:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

local function stripe(parent, cf, size, color, material)
	CityKit.part(parent, {
		Name = "Stripe",
		Size = size,
		CFrame = cf,
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
	})
end

----------------------------------------------------------------
-- New York
----------------------------------------------------------------

-- world frame: ground walk surface Y = 0; area centred near (0, *, 1200).
-- ArrivalPoint (0, 5, 1150), players face +Z. Cart row Z ~1212 faces -Z.
local NY_ROAD_Z = 1190
local NY_NORTH_WALK = 1219 -- centre of north sidewalk (carts sit here)
local NY_SOUTH_WALK = 1161 -- centre of south sidewalk / plaza edge
local NY_NORTH_FACE = 1227 -- street-facing wall of the north building row
local NY_SOUTH_FACE = 1153

local function buildNewYork()
	local newYork = Workspace:WaitForChild("Destinations"):WaitForChild("NewYork")
	local city = freshFolder(newYork, "City")

	-- one compact block. Kept small on purpose: every future destination needs
	-- its own pocket of world space, so New York is ~200 x 150 playable with a
	-- shallow skyline backdrop, not a sprawling grid.
	local HALF = 160 -- half-width of the paved surface

	CityKit.part(city, {
		Name = "CityBase",
		Size = Vector3.new(HALF * 2 + 20, 4, 210),
		CFrame = CFrame.new(0, -2.25, 1195),
		Color = Color3.fromRGB(60, 58, 66),
		Material = Enum.Material.Concrete,
	})

	-- road
	CityKit.part(city, {
		Name = "Road",
		Size = Vector3.new(HALF * 2, 0.4, 30),
		CFrame = CFrame.new(0, -0.12, NY_ROAD_Z),
		Color = P.Asphalt,
		Material = Enum.Material.Asphalt,
		Reflectance = 0.03,
	})
	stripe(city, CFrame.new(0, 0.02, NY_ROAD_Z - 0.5), Vector3.new(HALF * 2, 0.06, 0.4), P.LineYellow)
	stripe(city, CFrame.new(0, 0.02, NY_ROAD_Z + 0.5), Vector3.new(HALF * 2, 0.06, 0.4), P.LineYellow)
	for x = -HALF + 10, HALF - 10, 14 do
		stripe(city, CFrame.new(x, 0.02, NY_ROAD_Z - 7), Vector3.new(7, 0.06, 0.4), P.LineWhite)
		stripe(city, CFrame.new(x, 0.02, NY_ROAD_Z + 7), Vector3.new(7, 0.06, 0.4), P.LineWhite)
	end
	for _, cx in ipairs({ -22, 22 }) do
		for z = NY_ROAD_Z - 13, NY_ROAD_Z + 13, 1.6 do
			stripe(city, CFrame.new(cx, 0.02, z), Vector3.new(5, 0.06, 0.8), P.LineWhite)
		end
	end

	-- sidewalks + curbs
	for _, walk in ipairs({
		{ z = NY_NORTH_WALK, curbZ = NY_NORTH_WALK - 7 },
		{ z = NY_SOUTH_WALK, curbZ = NY_SOUTH_WALK + 7 },
	}) do
		CityKit.part(city, {
			Name = "Sidewalk",
			Size = Vector3.new(HALF * 2, 0.5, 16),
			CFrame = CFrame.new(0, -0.25, walk.z),
			Color = P.Sidewalk,
			Material = Enum.Material.Concrete,
		})
		CityKit.part(city, {
			Name = "Curb",
			Size = Vector3.new(HALF * 2, 0.6, 0.8),
			CFrame = CFrame.new(0, 0.1, walk.curbZ),
			Color = P.Curb,
			Material = Enum.Material.Concrete,
		})
		for x = -HALF + 10, HALF - 10, 12 do
			stripe(city, CFrame.new(x, 0.04, walk.z), Vector3.new(0.15, 0.05, 16), P.SidewalkJoint)
		end
	end

	-- north building row (faces the street), alley gap at the centre
	local northRng = Random.new(4021)
	local northX = -80
	local idx = 0
	while northX < 80 do
		idx += 1
		local w = northRng:NextInteger(20, 28)
		if math.abs(northX + w / 2) < 9 then
			northX = 9
		end
		local floors = northRng:NextInteger(3, 6)
		CityKit.building(city, {
			cf = CFrame.new(northX + w / 2, 0, NY_NORTH_FACE) * CFrame.Angles(0, math.pi, 0),
			width = w,
			depth = northRng:NextInteger(14, 20),
			floors = floors,
			seed = 100 + idx,
			fireEscape = northRng:NextNumber() < 0.5,
			water = northRng:NextNumber() < 0.35,
			setback = floors >= 5 and northRng:NextNumber() < 0.5,
		})
		northX += w + northRng:NextInteger(1, 3)
	end

	-- alley behind the gap
	local alley = Instance.new("Model")
	alley.Name = "Alley"
	alley.Parent = city
	CityKit.part(alley, { Name = "AlleyFloor", Size = Vector3.new(12, 0.4, 26), CFrame = CFrame.new(2, -0.15, NY_NORTH_FACE + 14), Color = Color3.fromRGB(70, 68, 74), Material = Enum.Material.Asphalt })
	for _, sx in ipairs({ -6, 10 }) do
		CityKit.part(alley, { Name = "AlleyWall", Size = Vector3.new(1, 30, 26), CFrame = CFrame.new(2 + sx, 15, NY_NORTH_FACE + 14), Color = P.BrickRed:Lerp(Color3.new(0, 0, 0), 0.15), Material = Enum.Material.Brick })
	end
	CityKit.part(alley, { Name = "Dumpster", Size = Vector3.new(5, 3, 3), CFrame = CFrame.new(0, 1.5, NY_NORTH_FACE + 9), Color = Color3.fromRGB(56, 104, 74), Material = Enum.Material.DiamondPlate })
	CityKit.steamVent(alley, CFrame.new(2, 0, NY_NORTH_FACE + 20))

	-- south building row (faces the plaza), centre gap where players arrive
	local southRng = Random.new(9084)
	local southX = -80
	idx = 0
	while southX < 80 do
		idx += 1
		local w = southRng:NextInteger(18, 26)
		if math.abs(southX + w / 2) < 18 then
			southX = 18
		end
		CityKit.building(city, {
			cf = CFrame.new(southX + w / 2, 0, NY_SOUTH_FACE),
			width = w,
			depth = southRng:NextInteger(12, 16),
			floors = southRng:NextInteger(3, 5),
			seed = 300 + idx,
			storefront = southRng:NextNumber() < 0.55,
			fireEscape = southRng:NextNumber() < 0.35,
		})
		southX += w + southRng:NextInteger(1, 3)
	end

	-- corner end-caps that turn the block
	CityKit.building(city, { cf = CFrame.new(-96, 0, 1194) * CFrame.Angles(0, math.rad(90), 0), width = 40, depth = 22, floors = 6, seed = 501, water = true })
	CityKit.building(city, { cf = CFrame.new(96, 0, 1194) * CFrame.Angles(0, math.rad(-90), 0), width = 40, depth = 22, floors = 6, seed = 502, setback = true })

	-- shallow skyline backdrop; deliberately short so it doesn't loom over
	-- neighbouring destinations
	CityKit.skyline(city, { origin = CFrame.new(0, 0, 1250) * CFrame.Angles(0, math.pi, 0), rows = 2, perRow = 7, spanX = 300, rowGap = 30, minH = 55, maxH = 135, seed = 11 })
	CityKit.skyline(city, { origin = CFrame.new(0, 0, 1118), rows = 1, perRow = 6, spanX = 260, rowGap = 26, minH = 45, maxH = 100, seed = 22 })
	CityKit.skyline(city, { origin = CFrame.new(-140, 0, 1195) * CFrame.Angles(0, math.rad(90), 0), rows = 1, perRow = 4, spanX = 180, rowGap = 26, minH = 55, maxH = 120, seed = 33 })
	CityKit.skyline(city, { origin = CFrame.new(140, 0, 1195) * CFrame.Angles(0, math.rad(-90), 0), rows = 1, perRow = 4, spanX = 180, rowGap = 26, minH = 55, maxH = 120, seed = 44 })

	-- props along the sidewalks
	local props = freshFolder(city, "Props")
	local cartXs = { 0, -24, -46, 24 }
	local function nearCart(x)
		for _, cx in ipairs(cartXs) do
			if math.abs(x - cx) < 9 then
				return true
			end
		end
		return false
	end

	local postIdx = 0
	for x = -72, 72, 24 do
		postIdx += 1
		-- south sidewalk (always clear of the carts)
		CityKit.lamppost(props, CFrame.new(x, 0, NY_SOUTH_WALK + 5) * CFrame.Angles(0, math.pi, 0), postIdx % 3 == 1)
		if postIdx % 2 == 0 then
			CityKit.planter(props, CFrame.new(x, 0, NY_SOUTH_WALK - 5))
		end
		-- north sidewalk: skip anything that would collide with a food cart
		if not nearCart(x) then
			CityKit.lamppost(props, CFrame.new(x, 0, NY_NORTH_WALK - 5), postIdx % 3 == 2)
			local roll = postIdx % 3
			local backCf = CFrame.new(x + 5, 0, NY_NORTH_WALK + 5)
			if roll == 0 then
				CityKit.hydrant(props, backCf)
			elseif roll == 1 then
				CityKit.trashCan(props, backCf)
			else
				CityKit.bench(props, CFrame.new(x, 0, NY_NORTH_WALK + 5) * CFrame.Angles(0, math.pi, 0))
			end
		end
	end

	for _, cx in ipairs({ -22, 22 }) do
		CityKit.trafficLight(props, CFrame.new(cx - 4, 0, NY_ROAD_Z - 15))
		CityKit.trafficLight(props, CFrame.new(cx + 4, 0, NY_ROAD_Z + 15) * CFrame.Angles(0, math.pi, 0))
	end

	CityKit.taxi(props, CFrame.new(-44, 0, NY_ROAD_Z + 11) * CFrame.Angles(0, math.rad(90), 0))
	CityKit.taxi(props, CFrame.new(40, 0, NY_ROAD_Z + 11) * CFrame.Angles(0, math.rad(-90), 0))

	CityKit.steamVent(props, CFrame.new(-30, 0, NY_ROAD_Z))
	CityKit.busShelter(props, CFrame.new(-70, 0, NY_NORTH_WALK - 4))
	CityKit.scaffold(props, CFrame.new(58, 0, NY_NORTH_WALK + 2), 24)

	-- landmark + wayfinding
	CityKit.bladeSign(props, CFrame.new(-22, 0, NY_SOUTH_WALK + 6), { "BROADWAY", "W 42 ST" })
	CityKit.subwayEntrance(props, CFrame.new(20, 0, 1162) * CFrame.Angles(0, math.pi, 0))

	-- tidy the hand-built pieces
	local kiosk = newYork:FindFirstChild("ReturnHomeKiosk")
	local pedestal = kiosk and kiosk:FindFirstChild("Pedestal")
	if pedestal then
		pedestal.Color = Color3.fromRGB(28, 30, 34)
		pedestal.Material = Enum.Material.Metal
	end

	local pizza = newYork:FindFirstChild("PizzaStand")
	if pizza then
		local kitchen = pizza:FindFirstChild("Kitchen")
		if kitchen then
			kitchen.Color = P.BrickRed
			kitchen.Material = Enum.Material.Brick
		end
		local roof = pizza:FindFirstChild("Roof")
		if roof then
			roof.Color = Color3.fromRGB(40, 120, 70)
		end
		if not pizza:FindFirstChild("NeonMarquee") then
			local marquee = CityKit.part(pizza, {
				Name = "NeonMarquee",
				Size = Vector3.new(12, 2.4, 0.5),
				CFrame = CFrame.new(0, 8.5, 1207),
				Color = P.NeonRed,
				Material = Enum.Material.Neon,
			})
			CityKit.surfaceSign(marquee, Enum.NormalId.Front, "PIZZA", Color3.fromRGB(20, 16, 20))
			CityKit.light(marquee, { Color = P.NeonRed, Range = 16, Brightness = 1.6 })
		end
	end
end

----------------------------------------------------------------
-- Hub / plaza cleanup pass (lighter)
----------------------------------------------------------------

local function dressHub()
	local hub = Workspace:WaitForChild("Hub")
	local dressing = freshFolder(hub, "CityDressing")

	-- warm up the existing surfaces
	local function recolor(name, color, material)
		local part = hub:FindFirstChild(name)
		if part then
			part.Color = color
			if material then
				part.Material = material
			end
		end
	end
	recolor("PlazaFloor", Color3.fromRGB(120, 110, 120), Enum.Material.Cobblestone)
	recolor("MainRoad", P.Asphalt, Enum.Material.Asphalt)
	recolor("PlazaAirportPath", Color3.fromRGB(120, 110, 120), Enum.Material.Cobblestone)
	recolor("AirportFloor", Color3.fromRGB(70, 72, 80), Enum.Material.Concrete)

	-- lampposts down MainRoad (runs Z -145 .. 70, X ~ +-8)
	local hz = 0
	for z = -140, 160, 30 do
		hz += 1
		CityKit.lamppost(dressing, CFrame.new(-10, 1, z), hz % 2 == 1)
		CityKit.lamppost(dressing, CFrame.new(10, 1, z) * CFrame.Angles(0, math.pi, 0), hz % 2 == 0)
	end

	-- plaza perimeter greenery + seating (plaza is 70x70 at (0,0.5,105))
	for _, x in ipairs({ -33, 33 }) do
		for z = 76, 134, 14 do
			CityKit.planter(dressing, CFrame.new(x, 1, z))
		end
	end
	for _, z in ipairs({ 74, 136 }) do
		CityKit.bench(dressing, CFrame.new(-14, 1, z))
		CityKit.bench(dressing, CFrame.new(14, 1, z))
	end

	-- a few storefronts along the far edge so the plaza feels enclosed
	for i, x in ipairs({ -40, 0, 40 }) do
		CityKit.building(dressing, {
			cf = CFrame.new(x, 1, 144),
			width = 32,
			depth = 18,
			floors = 3,
			seed = 700 + i,
		})
	end

	-- string lights across the plaza
	for _, x in ipairs({ -30, 30 }) do
		CityKit.part(dressing, { Name = "BannerPole", Size = Vector3.new(0.5, 16, 0.5), CFrame = CFrame.new(x, 9, 105), Color = P.Metal, Material = Enum.Material.Metal })
	end
	for x = -28, 28, 4 do
		local sag = 3 * math.cos(x / 28 * (math.pi / 2))
		CityKit.part(dressing, {
			Name = "Bulb",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(0.6, 0.6, 0.6),
			CFrame = CFrame.new(x, 15 - (3 - sag), 105),
			Color = P.LampWarm,
			Material = Enum.Material.Neon,
			CanCollide = false,
		})
	end

	-- soft skyline so the hub isn't floating in void either
	CityKit.skyline(dressing, { origin = CFrame.new(0, 1, 230) * CFrame.Angles(0, math.pi, 0), rows = 2, perRow = 8, spanX = 420, rowGap = 34, minH = 45, maxH = 120, seed = 61 })
	CityKit.skyline(dressing, { origin = CFrame.new(0, 1, -210), rows = 2, perRow = 7, spanX = 380, rowGap = 32, minH = 40, maxH = 110, seed = 62 })
end

----------------------------------------------------------------
-- Plots: one warm light each so restaurants read at dusk
----------------------------------------------------------------

local function lightPlots()
	local plots = Workspace:WaitForChild("Plots")
	for _, plot in ipairs(plots:GetChildren()) do
		local anchor = plot:FindFirstChild("BuildAnchor")
		if anchor and not anchor:FindFirstChild("PlotWarmLight") then
			local l = Instance.new("PointLight")
			l.Name = "PlotWarmLight"
			l.Color = P.LampWarm
			l.Brightness = 1.6
			l.Range = 34
			l.Shadows = false
			l.Parent = anchor
		end
	end
end

----------------------------------------------------------------
-- Game-wide: tame every world BillboardGui
----------------------------------------------------------------

local function distanceFor(bb)
	local host = bb.Parent
	if host and (host.Name == "WelcomeSign" or host.Name == "PlazaSign" or host.Name == "AirportSign") then
		return 420
	end
	return 120
end

local function tameBillboards()
	for _, d in ipairs(Workspace:GetDescendants()) do
		if d:IsA("BillboardGui") then
			CityKit.polishBillboard(d, distanceFor(d))
		end
	end
	-- keep new signs (runtime-spawned food carts, etc.) in line - only while
	-- the game is actually running, never as a dangling Edit-mode connection
	if RunService:IsRunning() then
		Workspace.DescendantAdded:Connect(function(d)
			if d:IsA("BillboardGui") then
				task.defer(function()
					if d.Parent then
						CityKit.polishBillboard(d, distanceFor(d))
					end
				end)
			end
		end)
	end
end

----------------------------------------------------------------

WorldDress.ApplyLighting = applyGoldenHour
WorldDress.BuildNewYork = buildNewYork
WorldDress.DressHub = dressHub
WorldDress.LightPlots = lightPlots
WorldDress.TameBillboards = tameBillboards

function WorldDress.BuildAll()
	applyGoldenHour()
	tameBillboards()

	local ok, err = pcall(buildNewYork)
	if not ok then
		warn("[WorldDress] New York build failed: " .. tostring(err))
	end

	ok, err = pcall(dressHub)
	if not ok then
		warn("[WorldDress] Hub dressing failed: " .. tostring(err))
	end

	pcall(lightPlots)
end

return WorldDress
