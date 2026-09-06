local PlotUtils = {}

function PlotUtils.getPlotForPlayer(plotsFolder, player)
	for _, plot in ipairs(plotsFolder:GetChildren()) do
		if plot:GetAttribute("OwnerUserId") == player.UserId then
			return plot
		end
	end
	return nil
end

function PlotUtils.getFreePlot(plotsFolder)
	for _, plot in ipairs(plotsFolder:GetChildren()) do
		if plot:GetAttribute("OwnerUserId") == 0 then
			return plot
		end
	end
	return nil
end

-- Spawn point just outside the plot's entrance, facing back toward the kitchen.
function PlotUtils.getSpawnCFrame(plot)
	local building = plot:FindFirstChild("Restaurant")
	local marker = building and building:FindFirstChild("EntranceMarker")
	if not marker then
		return nil
	end

	local outward = marker.CFrame.LookVector
	outward = Vector3.new(outward.X, 0, outward.Z)
	outward = outward.Magnitude > 0.1 and outward.Unit or Vector3.new(0, 0, 1)

	local spawnPos = marker.Position + outward * 10
	spawnPos = Vector3.new(spawnPos.X, 5, spawnPos.Z)

	local lookAtPos = Vector3.new(marker.Position.X, 5, marker.Position.Z)
	return CFrame.lookAt(spawnPos, lookAtPos)
end

return PlotUtils
