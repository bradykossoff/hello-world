-- Dusk-city dressing pass. Runs once on server start:
--   * sets a shared golden-hour / dusk Lighting rig
--   * builds the New York street block (roads, sidewalks, buildings, skyline,
--     props) around the fixed anchors from eattheworld.rbxl
--   * a lighter cleanup pass over the hub / plaza
--   * game-wide: stops every world BillboardGui from punching through the map
--     and fades it with distance
--
-- Everything generated lives under `<area>.CityDressing` (or NewYork.City) and
-- is wiped + rebuilt each start, so it never fights the hand-built .rbxl content.

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

local CityKit = require(ServerScriptService.Modules.CityKit)
local P = CityKit.Palette

----------------------------------------------------------------
-- Lighting: shared dusk
----------------------------------------------------------------

local function applyDuskLighting()
	Lighting.ClockTime = 18.4
	Lighting.GeographicLatitude = 41
	Lighting.Brightness = 2.2
	Lighting.ExposureCompensation = 0.1
	Lighting.Ambient = Color3.fromRGB(56, 52, 68)
	Lighting.OutdoorAmbient = Color3.fromRGB(92, 82, 108)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 158, 104)
	Lighting.ColorShift_Bottom = Color3.fromRGB(78, 84, 128)
	Lighting.EnvironmentDiffuseScale = 0.55
	Lighting.EnvironmentSpecularScale = 0.55
	Lighting.FogEnd = 9000

	-- procedural dusk sky reads the ClockTime; a baked daytime skybox would not
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if sky then
		sky:Destroy()
	end

	local atmos = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmos.Density = 0.34
	atmos.Offset = 0.15
	atmos.Color = Color3.fromRGB(199, 176, 168)
	atmos.Decay = Color3.fromRGB(92, 84, 120)
	atmos.Glare = 0.22
	atmos.Haze = 2.6
	atmos.Parent = Lighting

	local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
	bloom.Intensity = 0.9
	bloom.Size = 20
	bloom.Threshold = 1.0
	bloom.Parent = Lighting

	local dof = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
	if dof then
		dof.FarIntensity = 0.12
		dof.FocusDistance = 45
		dof.InFocusRadius = 70
		dof.NearIntensity = 0
	end

	local sun = Lighting:FindFirstChildOfClass("SunRaysEffect")
	if sun then
		sun.Intensity = 0.11
		sun.Spread = 0.9
	end

	if not Lighting:FindFirstChild("CityGrade") then
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "CityGrade"
		cc.Brightness = 0
		cc.Contrast = 0.1
		cc.Saturation = 0.06
		cc.TintColor = Color3.fromRGB(255, 238, 224)
		cc.Parent = Lighting
	end
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

	-- base slab filling the void beyond the hand-built ground
	CityKit.part(city, {
		Name = "CityBase",
		Size = Vector3.new(680, 4, 380),
		CFrame = CFrame.new(0, -2.25, 1210),
		Color = Color3.fromRGB(22, 22, 28),
		Material = Enum.Material.Concrete,
	})

	-- road
	CityKit.part(city, {
		Name = "Road",
		Size = Vector3.new(680, 0.4, 30),
		CFrame = CFrame.new(0, -0.12, NY_ROAD_Z),
		Color = P.AsphaltWet,
		Material = Enum.Material.Asphalt,
		Reflectance = 0.08,
	})
	stripe(city, CFrame.new(0, 0.02, NY_ROAD_Z - 0.5), Vector3.new(680, 0.06, 0.4), P.LineYellow)
	stripe(city, CFrame.new(0, 0.02, NY_ROAD_Z + 0.5), Vector3.new(680, 0.06, 0.4), P.LineYellow)
	for x = -330, 330, 14 do
		stripe(city, CFrame.new(x, 0.02, NY_ROAD_Z - 7), Vector3.new(7, 0.06, 0.4), P.LineWhite)
		stripe(city, CFrame.new(x, 0.02, NY_ROAD_Z + 7), Vector3.new(7, 0.06, 0.4), P.LineWhite)
	end
	-- crosswalks
	for _, cx in ipairs({ -25, 25 }) do
		for z = NY_ROAD_Z - 13, NY_ROAD_Z + 13, 1.6 do
			stripe(city, CFrame.new(cx, 0.02, z), Vector3.new(5, 0.06, 0.8), P.LineWhite)
		end
	end

	-- sidewalks + curbs
	for _, walk in ipairs({
		{ z = NY_NORTH_WALK, curbZ = NY_NORTH_WALK - 7, curbFace = 1 },
		{ z = NY_SOUTH_WALK, curbZ = NY_SOUTH_WALK + 7, curbFace = -1 },
	}) do
		CityKit.part(city, {
			Name = "Sidewalk",
			Size = Vector3.new(680, 0.5, 16),
			CFrame = CFrame.new(0, -0.25, walk.z),
			Color = P.Sidewalk,
			Material = Enum.Material.Concrete,
		})
		CityKit.part(city, {
			Name = "Curb",
			Size = Vector3.new(680, 0.6, 0.8),
			CFrame = CFrame.new(0, 0.1, walk.curbZ),
			Color = P.Curb,
			Material = Enum.Material.Concrete,
		})
		for x = -330, 330, 12 do
			stripe(city, CFrame.new(x, 0.04, walk.z), Vector3.new(0.15, 0.05, 16), P.SidewalkJoint)
		end
	end

	-- north building row (faces -Z / the street), with an alley gap at the centre
	local northRng = Random.new(4021)
	local northX = -170
	local idx = 0
	while northX < 175 do
		idx += 1
		local w = northRng:NextInteger(30, 44)
		if math.abs(northX + w / 2) < 12 then
			northX = 14 -- leave a 16-wide alley slot around x=0
		end
		local floors = northRng:NextInteger(4, 9)
		CityKit.building(city, {
			cf = CFrame.new(northX + w / 2, 0, NY_NORTH_FACE) * CFrame.Angles(0, math.pi, 0),
			width = w,
			depth = northRng:NextInteger(22, 30),
			floors = floors,
			seed = 100 + idx,
			shop = nil,
			fireEscape = northRng:NextNumber() < 0.5,
			water = northRng:NextNumber() < 0.4,
			setback = floors >= 7 and northRng:NextNumber() < 0.5,
		})
		northX += w + northRng:NextInteger(0, 3)
	end

	-- alley behind the gap
	local alley = Instance.new("Model")
	alley.Name = "Alley"
	alley.Parent = city
	CityKit.part(alley, { Name = "AlleyFloor", Size = Vector3.new(16, 0.4, 40), CFrame = CFrame.new(3, -0.15, NY_NORTH_FACE + 20), Color = Color3.fromRGB(30, 30, 34), Material = Enum.Material.Asphalt })
	for _, sx in ipairs({ -8, 14 }) do
		CityKit.part(alley, { Name = "AlleyWall", Size = Vector3.new(1, 40, 40), CFrame = CFrame.new(3 + sx, 20, NY_NORTH_FACE + 20), Color = P.BrickRed:Lerp(Color3.new(0, 0, 0), 0.3), Material = Enum.Material.Brick })
	end
	CityKit.part(alley, { Name = "Dumpster", Size = Vector3.new(6, 3, 3), CFrame = CFrame.new(0, 1.5, NY_NORTH_FACE + 12), Color = Color3.fromRGB(40, 74, 54), Material = Enum.Material.DiamondPlate })
	local alleyNeon = CityKit.part(alley, { Name = "AlleyNeon", Size = Vector3.new(0.5, 3, 0.5), CFrame = CFrame.new(-4, 8, NY_NORTH_FACE + 6), Color = P.NeonPink, Material = Enum.Material.Neon })
	CityKit.light(alleyNeon, { Color = P.NeonPink, Range = 14, Brightness = 1.4 })
	CityKit.steamVent(alley, CFrame.new(3, 0, NY_NORTH_FACE + 26))

	-- south building row (faces +Z / the plaza), centre gap where players arrive
	local southRng = Random.new(9084)
	local southX = -170
	idx = 0
	while southX < 175 do
		idx += 1
		local w = southRng:NextInteger(28, 40)
		if math.abs(southX + w / 2) < 26 then
			southX = 26
		end
		CityKit.building(city, {
			cf = CFrame.new(southX + w / 2, 0, NY_SOUTH_FACE),
			width = w,
			depth = southRng:NextInteger(18, 24),
			floors = southRng:NextInteger(3, 6),
			seed = 300 + idx,
			storefront = southRng:NextNumber() < 0.6,
			fireEscape = southRng:NextNumber() < 0.4,
			water = southRng:NextNumber() < 0.3,
		})
		southX += w + southRng:NextInteger(1, 4)
	end

	-- corner end-caps
	CityKit.building(city, { cf = CFrame.new(-190, 0, 1195) * CFrame.Angles(0, math.rad(90), 0), width = 60, depth = 30, floors = 8, seed = 501, water = true, setback = true })
	CityKit.building(city, { cf = CFrame.new(190, 0, 1195) * CFrame.Angles(0, math.rad(-90), 0), width = 60, depth = 30, floors = 9, seed = 502, water = true })

	-- distant skyline on all four sides, receding into the haze
	CityKit.skyline(city, { origin = CFrame.new(0, 0, 1268) * CFrame.Angles(0, math.pi, 0), rows = 4, perRow = 10, spanX = 560, rowGap = 36, minH = 80, maxH = 250, seed = 11 })
	CityKit.skyline(city, { origin = CFrame.new(0, 0, 1120), rows = 3, perRow = 9, spanX = 520, rowGap = 34, minH = 60, maxH = 180, seed = 22 })
	CityKit.skyline(city, { origin = CFrame.new(-230, 0, 1200) * CFrame.Angles(0, math.rad(90), 0), rows = 2, perRow = 6, spanX = 340, rowGap = 34, minH = 70, maxH = 200, seed = 33 })
	CityKit.skyline(city, { origin = CFrame.new(230, 0, 1200) * CFrame.Angles(0, math.rad(-90), 0), rows = 2, perRow = 6, spanX = 340, rowGap = 34, minH = 70, maxH = 210, seed = 44 })

	-- props along the sidewalks
	local props = freshFolder(city, "Props")
	local cartXs = { 0, -24, -46, 24 } -- keep clear of the food carts + their prompts
	local function nearCart(x)
		for _, cx in ipairs(cartXs) do
			if math.abs(x - cx) < 8 then
				return true
			end
		end
		return false
	end

	local postIdx = 0
	for x = -153, 153, 34 do
		postIdx += 1
		local lit = postIdx % 2 == 1
		-- north sidewalk: lampposts near the curb, clutter at the back wall
		CityKit.lamppost(props, CFrame.new(x, 0, NY_NORTH_WALK - 5), lit)
		if not nearCart(x) then
			local roll = (x // 34) % 4
			local backCf = CFrame.new(x + 6, 0, NY_NORTH_WALK + 5)
			if roll == 0 then
				CityKit.hydrant(props, backCf)
			elseif roll == 1 then
				CityKit.trashCan(props, backCf)
			elseif roll == 2 then
				CityKit.planter(props, backCf)
			else
				CityKit.bench(props, CFrame.new(x, 0, NY_NORTH_WALK + 5) * CFrame.Angles(0, math.pi, 0))
			end
		end
		-- south sidewalk
		CityKit.lamppost(props, CFrame.new(x, 0, NY_SOUTH_WALK + 5) * CFrame.Angles(0, math.pi, 0), not lit)
		local sroll = (x // 34) % 3
		if sroll == 0 then
			CityKit.planter(props, CFrame.new(x, 0, NY_SOUTH_WALK - 5))
		elseif sroll == 1 then
			CityKit.trashCan(props, CFrame.new(x, 0, NY_SOUTH_WALK - 5))
		end
	end

	for _, cx in ipairs({ -25, 25 }) do
		CityKit.trafficLight(props, CFrame.new(cx - 4, 0, NY_ROAD_Z - 15))
		CityKit.trafficLight(props, CFrame.new(cx + 4, 0, NY_ROAD_Z + 15) * CFrame.Angles(0, math.pi, 0))
	end

	-- parked taxis in the curb lanes
	CityKit.taxi(props, CFrame.new(-64, 0, NY_ROAD_Z + 11) * CFrame.Angles(0, math.rad(90), 0))
	CityKit.taxi(props, CFrame.new(58, 0, NY_ROAD_Z + 11) * CFrame.Angles(0, math.rad(-90), 0))
	CityKit.taxi(props, CFrame.new(12, 0, NY_ROAD_Z - 11) * CFrame.Angles(0, math.rad(90), 0))

	CityKit.steamVent(props, CFrame.new(-40, 0, NY_ROAD_Z))
	CityKit.steamVent(props, CFrame.new(70, 0, NY_ROAD_Z + 3))

	CityKit.busShelter(props, CFrame.new(-90, 0, NY_SOUTH_WALK - 5))
	CityKit.scaffold(props, CFrame.new(120, 0, NY_NORTH_WALK + 2), 40)

	-- landmark + wayfinding
	CityKit.bladeSign(props, CFrame.new(-30, 0, NY_SOUTH_WALK + 6), { "BROADWAY", "W 42 ST" })
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
	recolor("MainRoad", P.AsphaltWet, Enum.Material.Asphalt)
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

----------------------------------------------------------------

applyDuskLighting()
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
