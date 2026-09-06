return {
	Name = "HotDog",
	Label = "Hot Dog",
	Area = "New York",
	Price = 30,
	BaseRestaurantValue = 15,
	BaseBites = 4,
	Model = {
		Shape = Enum.PartType.Block,
		Size = Vector3.new(3.6, 1.2, 1.2),
	},
	Variants = {
		Common = {
			DisplayName = "Hot Dog",
			ValueMultiplier = 1,
			Color = Color3.fromRGB(200, 120, 90),
		},
		Uncommon = {
			DisplayName = "Sauerkraut Dog",
			ValueMultiplier = 2,
			Color = Color3.fromRGB(120, 220, 120),
		},
		Rare = {
			DisplayName = "Chili Cheese Dog",
			ValueMultiplier = 5,
			Color = Color3.fromRGB(100, 150, 255),
		},
		Epic = {
			DisplayName = "Coney Island Foot-Long",
			ValueMultiplier = 12,
			Color = Color3.fromRGB(190, 100, 255),
		},
		Legendary = {
			DisplayName = "Golden Frankfurter",
			ValueMultiplier = 30,
			Color = Color3.fromRGB(255, 200, 40),
		},
		Secret = {
			DisplayName = "Galactic Glizzy",
			ValueMultiplier = 100,
			Color = Color3.fromRGB(160, 60, 255),
		},
	},
}
