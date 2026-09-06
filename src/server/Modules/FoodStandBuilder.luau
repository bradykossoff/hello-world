-- Graybox street-cart builder for New York food stands. Real art drops in
-- later; for now this stamps out a readable cart whose named children match
-- the hand-built PizzaStand so FoodVendorSystem treats every stand the same:
--   <Cart>/OrderPoint/OrderPrompt   -- ProximityPrompt the player triggers
--   <Cart>/FoodSpawnPoint           -- where the rolled food part appears

local FoodStandBuilder = {}

local function makePart(name, parent, props)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in pairs(props) do
		part[key] = value
	end
	part.Parent = parent
	return part
end

-- `baseCFrame` sits on the ground at the cart's centre, axis-aligned, with
-- -Z as the customer-facing side (that's where OrderPoint/FoodSpawnPoint go).
function FoodStandBuilder.Build(parent, standName, tint, baseCFrame)
	local cart = Instance.new("Model")
	cart.Name = (standName:gsub("%s+", "")) .. "_Stand"

	local body = makePart("Body", cart, {
		Size = Vector3.new(6, 3, 3),
		Color = tint,
		Material = Enum.Material.Metal,
		CFrame = baseCFrame * CFrame.new(0, 1.5, 0),
	})
	cart.PrimaryPart = body

	makePart("Trim", cart, {
		Size = Vector3.new(6.4, 0.5, 3.4),
		Color = Color3.fromRGB(240, 240, 240),
		Material = Enum.Material.SmoothPlastic,
		CFrame = baseCFrame * CFrame.new(0, 3, 0),
	})

	for _, side in ipairs({ -1, 1 }) do
		makePart("Wheel", cart, {
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.6, 2, 2),
			Color = Color3.fromRGB(35, 35, 35),
			Material = Enum.Material.SmoothPlastic,
			-- Cylinder's tube axis is local X by default: leaving it unrotated
			-- points the axle across the cart, so the wheel "rolls" along Z.
			CFrame = baseCFrame * CFrame.new(side * 3, 1, 1),
		})
	end

	makePart("Pole", cart, {
		Size = Vector3.new(0.3, 4, 0.3),
		Color = Color3.fromRGB(120, 120, 120),
		Material = Enum.Material.Metal,
		CFrame = baseCFrame * CFrame.new(0, 5, 0),
	})

	makePart("Umbrella", cart, {
		Size = Vector3.new(8, 0.4, 5),
		Color = tint,
		Material = Enum.Material.Fabric,
		CFrame = baseCFrame * CFrame.new(0, 7, 0),
	})

	local orderPoint = makePart("OrderPoint", cart, {
		Size = Vector3.new(1, 1, 1),
		Transparency = 1,
		CanCollide = false,
		CFrame = baseCFrame * CFrame.new(0, 3, -2),
	})

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "OrderPrompt"
	prompt.ActionText = "Order"
	prompt.ObjectText = standName
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = orderPoint

	makePart("FoodSpawnPoint", cart, {
		Size = Vector3.new(1, 1, 1),
		Transparency = 1,
		CanCollide = false,
		CFrame = baseCFrame * CFrame.new(0, 1, -3.2),
	})

	local signPart = makePart("StandSign", cart, {
		Size = Vector3.new(1, 1, 1),
		Transparency = 1,
		CanCollide = false,
		CFrame = baseCFrame * CFrame.new(0, 8, 0),
	})

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Sign"
	billboard.Size = UDim2.new(0, 220, 0, 50)
	billboard.AlwaysOnTop = true
	billboard.Parent = signPart

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Text = standName
	label.Parent = billboard

	cart.Parent = parent
	return cart
end

return FoodStandBuilder
