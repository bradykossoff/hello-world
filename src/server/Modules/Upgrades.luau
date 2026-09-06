local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local UpgradeCatalog = require(ReplicatedStorage.Data.UpgradeCatalog)
local Economy = require(ServerScriptService.Modules.Economy)
local KitchenBuilder = require(ServerScriptService.Modules.KitchenBuilder)

local Upgrades = {}

-- Attribute/default-level mapping lives in UpgradeCatalog.Meta so the
-- client (which cannot require this server-only module) can read the
-- exact same mapping when displaying the upgrade panel.
local ATTRIBUTE_NAMES = UpgradeCatalog.Meta.AttributeNames
local DEFAULT_LEVELS = UpgradeCatalog.Meta.DefaultLevels

Upgrades.AttributeNames = ATTRIBUTE_NAMES
Upgrades.DefaultLevels = DEFAULT_LEVELS
Upgrades.TrackOrder = UpgradeCatalog.Meta.TrackOrder

function Upgrades.GetLevel(plot, trackName)
	local attr = ATTRIBUTE_NAMES[trackName]
	if not attr then return nil end
	local value = plot:GetAttribute(attr)
	if value == nil then return DEFAULT_LEVELS[trackName] end
	return value
end

-- Cost to go from the current level to the next one. Returns nil if maxed.
function Upgrades.GetCost(trackName, currentLevel)
	local track = UpgradeCatalog[trackName]
	if not track then return nil end

	if trackName == "KitchenStage" then
		if currentLevel >= track.MaxLevel then return nil end
		return track.UpgradeCost[currentLevel]
	end

	if currentLevel >= track.MaxLevel then return nil end
	return math.floor(track.BaseCost * (track.CostGrowth ^ (currentLevel - track.MinLevel)))
end

-- Applies the purchase (deducting money and bumping the level / rebuilding
-- the kitchen as needed). Returns success, message.
function Upgrades.Purchase(player, plot, trackName)
	local track = UpgradeCatalog[trackName]
	local attr = ATTRIBUTE_NAMES[trackName]
	if not track or not attr then
		return false, "Unknown upgrade."
	end

	local currentLevel = Upgrades.GetLevel(plot, trackName)
	local cost = Upgrades.GetCost(trackName, currentLevel)
	if not cost then
		return false, track.DisplayName .. " is already maxed out!"
	end

	if Economy.Get(player) < cost then
		return false, "Not enough money! Need $" .. cost .. "."
	end

	Economy.Add(player, -cost)
	local newLevel = currentLevel + 1

	if trackName == "KitchenStage" then
		KitchenBuilder.SetStage(plot, newLevel) -- also sets the KitchenStage attribute
	else
		plot:SetAttribute(attr, newLevel)
	end

	return true, "Upgraded " .. track.DisplayName .. " to level " .. newLevel .. "!"
end

-- ---- Gameplay-effect getters, centralized here so every system (eating,
-- customers, the rarity roll, the menu kiosk) reads the same formulas. ----

function Upgrades.GetTableCount(plot)
	local stage = Upgrades.GetLevel(plot, "KitchenStage")
	return UpgradeCatalog.KitchenStage.TableCounts[stage] or UpgradeCatalog.KitchenStage.TableCounts[1]
end

function Upgrades.GetEatSpeedMultiplier(plot)
	local track = UpgradeCatalog.KitchenSpeed
	local level = Upgrades.GetLevel(plot, "KitchenSpeed")
	return math.max(track.MinSpeedMultiplier, 1 - (level - 1) * track.SpeedStepPerLevel)
end

function Upgrades.GetLuckBonus(plot)
	local track = UpgradeCatalog.Luck
	local level = Upgrades.GetLevel(plot, "Luck")
	return level * track.LuckPerLevel
end

function Upgrades.GetTipMultiplier(plot)
	local track = UpgradeCatalog.CustomerTips
	local level = Upgrades.GetLevel(plot, "CustomerTips")
	return 1 + level * track.TipPerLevel
end

function Upgrades.GetMaxMenuSlots(plot)
	local track = UpgradeCatalog.MenuSlots
	local level = Upgrades.GetLevel(plot, "MenuSlots")
	return track.BaseSlots + level * track.SlotsPerLevel
end

return Upgrades
