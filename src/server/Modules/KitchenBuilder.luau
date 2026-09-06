local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local UpgradeCatalog = require(ReplicatedStorage.Data.UpgradeCatalog)

local KitchenBuilder = {}

local MAX_STAGE = UpgradeCatalog.KitchenStage.MaxLevel
local stagesFolder = ServerStorage:WaitForChild("RestaurantStages")

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
	model:PivotTo(anchor.CFrame)
	model.Parent = plot

	clearOccupied(model)
	plot:SetAttribute("KitchenStage", stage)
end

return KitchenBuilder
