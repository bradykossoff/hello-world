local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Economy = require(ServerScriptService.Modules.Economy)
local Catalog = require(ReplicatedStorage.Data.ShopCatalog)

local Shop = {}

-- How much cash each Developer Product grants, keyed by the catalog item's Id.
local CASH_GRANTS = {
	money_small = 5000,
	money_medium = 25000,
	money_large = 75000,
}

local productIdToItem = {}
for _, item in ipairs(Catalog) do
	if item.Kind == "DeveloperProduct" then
		productIdToItem[item.ProductId] = item
	end
end

-- Grants the purchase and tells Roblox it was fulfilled. With placeholder IDs
-- and an unpublished place this callback never actually fires from a real
-- purchase, but it's wired correctly for when real products exist.
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local item = productIdToItem[receiptInfo.ProductId]
	if not item then
		return Enum.ProductPurchaseDecision.NotProcessed
	end

	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessed
	end

	local grant = CASH_GRANTS[item.Id]
	if grant then
		Economy.Add(player, grant)
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- Wrapped in pcall: placeholder pass IDs and/or an unpublished place make this
-- error rather than return a real answer, so it safely defaults to "not owned".
function Shop.OwnsPass(player, passId)
	if not passId or passId == 0 then
		return false
	end
	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
	end)
	return ok and owns == true
end

function Shop.GetMoneyMultiplier(player)
	for _, item in ipairs(Catalog) do
		if item.Id == "boost_money" then
			if Shop.OwnsPass(player, item.ProductId) then
				return 2
			end
			return 1
		end
	end
	return 1
end

return Shop
