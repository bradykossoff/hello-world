return {
	Name = "Pretzel",
	Label = "Pretzel",
	Area = "New York",
	Price = 20,
	BaseRestaurantValue = 10,
	BaseBites = 3,
	Model = {
		Shape = Enum.PartType.Block,
		Size = Vector3.new(2.6, 2.6, 0.8),
	},
	Variants = {
		Common = {
			DisplayName = "Soft Pretzel",
			ValueMultiplier = 1,
			Color = Color3.fromRGB(150, 95, 40),
		},
		Uncommon = {
			DisplayName = "Salted Twist",
			ValueMultiplier = 2,
			Color = Color3.fromRGB(120, 220, 120),
		},
		Rare = {
			DisplayName = "Cinnamon Sugar Pretzel",
			ValueMultiplier = 5,
			Color = Color3.fromRGB(100, 150, 255),
		},
		Epic = {
			DisplayName = "Cheddar-Stuffed Pretzel",
			ValueMultiplier = 12,
			Color = Color3.fromRGB(190, 100, 255),
		},
		Legendary = {
			DisplayName = "Golden Knot",
			ValueMultiplier = 30,
			Color = Color3.fromRGB(255, 200, 40),
		},
		Secret = {
			DisplayName = "Pretzel of the Void",
			ValueMultiplier = 100,
			Color = Color3.fromRGB(160, 60, 255),
		},
	},
}
