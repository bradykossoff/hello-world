-- Shared, data-driven definition of the restaurant upgrade tracks. Both
-- server (to validate purchases) and client (to display levels/costs)
-- require this directly, since plot attributes already replicate for free.
return {
	KitchenStage = {
		DisplayName = "Restaurant Size",
		Description = "More tables, more customers served at once, and a bigger building.",
		MaxLevel = 3,
		Names = { [1] = "Cozy Kitchen", [2] = "Bigger Kitchen", [3] = "Grand Kitchen" },
		TableCounts = { [1] = 2, [2] = 3, [3] = 4 },
		-- Cost to upgrade FROM this level TO the next one.
		UpgradeCost = { [1] = 500, [2] = 2000 },
	},

	KitchenSpeed = {
		DisplayName = "Kitchen Speed",
		Description = "Customers get served and finish eating faster - more table turnover.",
		MaxLevel = 10,
		BaseCost = 100,
		CostGrowth = 1.5,
		MinLevel = 1,
		SpeedStepPerLevel = 0.1,
		MinSpeedMultiplier = 0.4,
	},

	Luck = {
		DisplayName = "Luck",
		Description = "Better odds of rolling rare, epic, legendary, and secret food.",
		MaxLevel = 10,
		BaseCost = 100,
		CostGrowth = 1.5,
		MinLevel = 0,
		LuckPerLevel = 0.08,
	},

	CustomerTips = {
		DisplayName = "Customer Tips",
		Description = "Customers pay more for every meal.",
		MaxLevel = 10,
		BaseCost = 100,
		CostGrowth = 1.5,
		MinLevel = 0,
		TipPerLevel = 0.05,
	},

	MenuSlots = {
		DisplayName = "Menu Slots",
		Description = "Add more foods to your menu at once.",
		MaxLevel = 5,
		BaseCost = 250,
		CostGrowth = 1.6,
		MinLevel = 0,
		BaseSlots = 3,
		SlotsPerLevel = 1,
	},
	Meta = {
		TrackOrder = { "KitchenStage", "KitchenSpeed", "Luck", "CustomerTips", "MenuSlots" },
		AttributeNames = {
			KitchenStage = "KitchenStage",
			KitchenSpeed = "KitchenSpeedLevel",
			Luck = "LuckLevel",
			CustomerTips = "TipLevel",
			MenuSlots = "MenuSlotLevel",
		},
		DefaultLevels = {
			KitchenStage = 1,
			KitchenSpeed = 1,
			Luck = 0,
			CustomerTips = 0,
			MenuSlots = 0,
		},
	},
}
