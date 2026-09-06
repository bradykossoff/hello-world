-- Placeholder wallet system. Money lives as a player Attribute (auto-replicates
-- to the client for free, which is what the wallet UI reads), and is persisted
-- by PlotManager alongside restaurant Level.
local Economy = {}

function Economy.Get(player)
	return player:GetAttribute("Money") or 0
end

function Economy.Set(player, amount)
	player:SetAttribute("Money", amount)
end

function Economy.Add(player, amount)
	Economy.Set(player, Economy.Get(player) + amount)
end

return Economy
