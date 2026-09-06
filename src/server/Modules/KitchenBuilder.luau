local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UpgradeCatalog = require(ReplicatedStorage.Data.UpgradeCatalog)

local KitchenBuilder = {}

local LEG_COLOR = Color3.fromRGB(80, 80, 80)
local TOP_COLOR = Color3.fromRGB(180, 130, 90)
local CHAIR_COLOR = Color3.fromRGB(120, 80, 50)

-- Tables are spaced this many studs apart along the building's width axis
-- (world Z here) - matches the original Stage 1 spacing between the two
-- tables. Margins below are additive (not multiplicative) so the building
-- doesn't balloon out of the plot at higher stages.
local TABLE_SPACING = 10
local ROOF_MARGIN = 10
local KITCHEN_MARGIN = 8
local COUNTER_MARGIN = 8

local function createTable(building, index, topCFrame)
	local tbl = Instance.new("Model")
	tbl.Name = "Table" .. index
	tbl.Parent = building

	local top = Instance.new("Part")
	top.Name = "Top"
	top.Size = Vector3.new(4, 0.4, 4)
	top.Anchored = true
	top.Color = TOP_COLOR
	top.Material = Enum.Material.Wood
	top.CFrame = topCFrame
	top.Parent = tbl

	local leg = Instance.new("Part")
	leg.Name = "Leg"
	leg.Size = Vector3.new(1, 2.4, 1)
	leg.Anchored = true
	leg.Color = LEG_COLOR
	leg.Material = Enum.Material.Metal
	leg.CFrame = topCFrame * CFrame.new(0, -1.4, 0)
	leg.Parent = tbl

	-- Chairs sit on either side of the table along the building's local Z
	-- axis (which maps to world X, the "depth"/kitchen-to-entrance axis),
	-- facing each other across the table - matching the original layout.
	for chairIndex, localZOffset in ipairs({ 2.4, -2.4 }) do
		local chair = Instance.new("Part")
		chair.Name = "Chair" .. chairIndex
		chair.Size = Vector3.new(1.6, 1.6, 1.6)
		chair.Anchored = true
		chair.Color = CHAIR_COLOR
		chair.Material = Enum.Material.Wood
		chair.CFrame = topCFrame * CFrame.new(0, -1.8, localZOffset)
		chair.Parent = tbl
	end

	tbl.PrimaryPart = top
	return tbl
end

-- Rebuilds the plot's dining area for the given kitchen stage: widens the
-- Kitchen/Counter/Roof along world Z only (their depth, height, existing
-- tilt and orientation are left completely untouched - only .Position.Z and
-- .Size.X are ever written, both of which are safe to change independently
-- of rotation) and replaces the Table models with the stage's table count.
--
-- Growth is one-sided: it keeps whichever edge of the building is closest to
-- the plot boundary fixed, and only extends into the side of the plot that
-- has more open room, so bigger stages never spill outside the plot.
function KitchenBuilder.SetStage(plot, stage)
	local building = plot:FindFirstChild("Stage1Building")
	if not building then return end

	local tableCount = UpgradeCatalog.KitchenStage.TableCounts[stage]
	if not tableCount then return end

	local kitchen = building:FindFirstChild("Kitchen")
	local counter = building:FindFirstChild("Counter")
	local roof = building:FindFirstChild("Roof")
	local firstTable = building:FindFirstChild("Table1")
	if not (kitchen and counter and roof and firstTable) then return end

	-- All measurements taken directly in world space (not local/rotated
	-- space) since these parts carry orientation (and the roof a slight
	-- tilt) that makes local-axis math error-prone.
	local tableWorldX = firstTable.Top.Position.X
	local tableWorldY = firstTable.Top.Position.Y
	local rotationOnly = firstTable.Top.CFrame - firstTable.Top.Position

	local oldTableCount = 0
	for _, child in ipairs(building:GetChildren()) do
		if child:IsA("Model") and child.Name:match("^Table%d+$") then
			oldTableCount += 1
		end
	end
	if oldTableCount == 0 then oldTableCount = 2 end

	local oldSpread = math.max((oldTableCount - 1) * TABLE_SPACING, TABLE_SPACING)
	local newSpread = math.max((tableCount - 1) * TABLE_SPACING, TABLE_SPACING)

	local oldBuildingCenterZ = kitchen.Position.Z -- kitchen/counter/roof/tables all share this Z today
	local oldRoofHalf = (oldSpread + ROOF_MARGIN) / 2

	-- Figure out which side of the plot (along world Z) has more room, so we
	-- grow the building toward open space instead of into a neighboring plot.
	local growDirection = 1
	local plotFloor = plot:FindFirstChild("PlotFloor")
	if plotFloor then
		local zMin = plotFloor.Position.Z - plotFloor.Size.Z / 2
		local zMax = plotFloor.Position.Z + plotFloor.Size.Z / 2
		local marginNeg = (oldBuildingCenterZ - oldRoofHalf) - zMin
		local marginPos = zMax - (oldBuildingCenterZ + oldRoofHalf)
		growDirection = (marginPos >= marginNeg) and 1 or -1
	end

	local fixedEdgeZ = oldBuildingCenterZ - growDirection * oldRoofHalf
	local newRoofHalf = (newSpread + ROOF_MARGIN) / 2
	local newBuildingCenterZ = fixedEdgeZ + growDirection * newRoofHalf

	kitchen.Size = Vector3.new(newSpread + KITCHEN_MARGIN, kitchen.Size.Y, kitchen.Size.Z)
	kitchen.Position = Vector3.new(kitchen.Position.X, kitchen.Position.Y, newBuildingCenterZ)

	counter.Size = Vector3.new(newSpread + COUNTER_MARGIN, counter.Size.Y, counter.Size.Z)
	counter.Position = Vector3.new(counter.Position.X, counter.Position.Y, newBuildingCenterZ)

	roof.Size = Vector3.new(newSpread + ROOF_MARGIN, roof.Size.Y, roof.Size.Z)
	roof.Position = Vector3.new(roof.Position.X, roof.Position.Y, newBuildingCenterZ)

	for _, child in ipairs(building:GetChildren()) do
		if child:IsA("Model") and child.Name:match("^Table%d+$") then
			child:Destroy()
		end
	end

	for i = 1, tableCount do
		local worldZ = newBuildingCenterZ + TABLE_SPACING * (i - (tableCount + 1) / 2)
		local topCFrame = CFrame.new(tableWorldX, tableWorldY, worldZ) * rotationOnly
		createTable(building, i, topCFrame)
	end

	plot:SetAttribute("KitchenStage", stage)
end

return KitchenBuilder
