local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RarityTable = require(ReplicatedStorage.Data.RarityTable)

local RarityRoller = {}

-- Server-authoritative weighted roll over the shared rarity table.
--
-- luckBonus (0 = no luck upgrade, 0.08 = one Luck level, etc.) shifts weight
-- away from the most common tier and towards every rarer tier, proportional
-- to each rarer tier's own share of the non-common pool - so luck makes ALL
-- rare-and-above outcomes more likely, not just the rarest one. Common's
-- weight is floored so it never goes fully to zero at very high luck.
function RarityRoller.Roll(luckBonus)
	luckBonus = luckBonus or 0

	local weights = {}
	local commonIndex = 1
	local nonCommonTotal = 0

	for i, tier in ipairs(RarityTable) do
		weights[i] = tier.Chance
		if tier.Name == "Common" then
			commonIndex = i
		else
			nonCommonTotal += tier.Chance
		end
	end

	if luckBonus > 0 and nonCommonTotal > 0 then
		-- Move up to (luckBonus * total weight) points from Common to the
		-- rarer tiers, split proportionally among them. Floor Common at 20%
		-- of its original weight so it's never fully eliminated.
		local totalWeight = weights[commonIndex] + nonCommonTotal
		local maxShift = math.min(weights[commonIndex] * 0.8, luckBonus * totalWeight)

		for i, tier in ipairs(RarityTable) do
			if tier.Name ~= "Common" then
				weights[i] += maxShift * (tier.Chance / nonCommonTotal)
			end
		end
		weights[commonIndex] -= maxShift
	end

	local totalWeight = 0
	for _, w in ipairs(weights) do
		totalWeight += w
	end

	local roll = math.random() * totalWeight
	local cumulative = 0

	for i, tier in ipairs(RarityTable) do
		cumulative += weights[i]
		if roll <= cumulative then
			return tier.Name, tier.Chance
		end
	end

	-- Floating point safety net: fall back to the first (most common) tier
	return RarityTable[1].Name, RarityTable[1].Chance
end

return RarityRoller
