local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local UpgradeCatalog = require(ReplicatedStorage.Data.UpgradeCatalog)

local KitchenBuilder = {}

local MAX_STAGE = UpgradeCatalog.KitchenStage.MaxLevel

-- Looked up lazily (not at module load) so a missing folder never infinite-
-- yields the require and takes PlotManager down with it.
local function getStagesFolder()
	local folder = ServerStorage:FindFirstChild("RestaurantStages")
	if not folder then
		folder = ServerStorage:WaitForChild("RestaurantStages", 15)
	end
	return folder
end

local function clearOccupied(model)
	local tables = model:FindFirstChild("Tables")
	if not tables then return end
	for _, tbl in ipairs(tables:GetChildren()) do
		for _, chairName in ipairs({ "Chair1", "Chair2" }) do
			local chair = tbl:FindFirstChild(chairName)
			if chair then
				chair:SetAttribute("Occupied", false)
			end
		end
	end
end

-- Swaps the plot's restaurant building to the model for `stage`. Idempotent:
-- calling with the current stage is still a full rebuild, which is how a
-- released plot is reset to a clean Stage 1 for the next owner.
function KitchenBuilder.SetStage(plot, stage)
	stage = math.clamp(math.floor(tonumber(stage) or 1), 1, MAX_STAGE)

	local stagesFolder = getStagesFolder()
	if not stagesFolder then
		warn("KitchenBuilder: ServerStorage.RestaurantStages is missing - is Rojo synced? (check ServerStorage in the Explorer)")
		return
	end

	local master = stagesFolder:FindFirstChild("Stage" .. stage)
	if not master then
		warn(string.format("KitchenBuilder: no master model for stage %d - leaving %s untouched", stage, plot.Name))
		return
	end

	local anchor = plot:FindFirstChild("BuildAnchor")
	if not anchor then
		warn("KitchenBuilder: " .. plot.Name .. " has no BuildAnchor - cannot place restaurant")
		return
	end

	local existing = plot:FindFirstChild("Restaurant")
	if existing then
		existing:Destroy()
	end

	local model = master:Clone()
	model.Name = "Restaurant"

	-- Set the pivot explicitly: the PrimaryPart Ref inside a Rojo-synced model
	-- file doesn't always survive, and without it PivotTo falls back to the
	-- bounding-box centre and drops the building several studs into the floor.
	local base = model:FindFirstChild("Base")
	if base then
		model.PrimaryPart = base
	end

	model:PivotTo(anchor.CFrame)
	model.Parent = plot

	clearOccupied(model)
	plot:SetAttribute("KitchenStage", stage)
end

return KitchenBuilder
