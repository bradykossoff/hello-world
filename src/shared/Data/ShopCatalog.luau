-- PLACEHOLDER IDS: none of these are real yet. Real Robux purchases require
-- creating actual Developer Products (for the cash packs) and Game Passes
-- (for the boosts) on the Roblox Creator Dashboard for this experience once
-- it's published, then replacing the ProductId values below with the real
-- ones Roblox assigns. Until then, purchase prompts will fail/no-op.
return {
	{
		Id = "money_small",
		Kind = "DeveloperProduct",
		ProductId = 1000001,
		Name = "$5,000 Cash",
		Description = "A quick boost to your restaurant funds.",
		Icon = "$",
	},
	{
		Id = "money_medium",
		Kind = "DeveloperProduct",
		ProductId = 1000002,
		Name = "$25,000 Cash",
		Description = "A solid cash injection for upgrades.",
		Icon = "$",
	},
	{
		Id = "money_large",
		Kind = "DeveloperProduct",
		ProductId = 1000003,
		Name = "$75,000 Cash",
		Description = "Go big. A major restaurant war chest.",
		Icon = "$",
	},
	{
		Id = "boost_money",
		Kind = "GamePass",
		ProductId = 2000001,
		Name = "2x Money",
		Description = "Permanently doubles all money earned from eating and customers.",
		Icon = "x2",
	},
	{
		Id = "boost_luck",
		Kind = "GamePass",
		ProductId = 2000002,
		Name = "2x Luck",
		Description = "Permanently doubles your rarity luck. (Coming soon - luck system isn't built yet)",
		Icon = "%",
	},
}
