return {
	Name = "BaconEggCheese",
	Label = "Bacon, Egg & Cheese",
	Area = "New York",
	Price = 40,
	BaseRestaurantValue = 20,
	BaseBites = 5,
	Model = {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2.4, 2.6, 2.6),
		Tilt = CFrame.Angles(0, 0, math.rad(90)),
	},
	Variants = {
		Common = {
			DisplayName = "Bacon Egg & Cheese",
			ValueMultiplier = 1,
			Color = Color3.fromRGB(214, 168, 108),
		},
		Uncommon = {
			DisplayName = "Everything Bagel BEC",
			ValueMultiplier = 2,
			Color = Color3.fromRGB(120, 220, 120),
		},
		Rare = {
			DisplayName = "Taylor Ham, Egg & Cheese",
			ValueMultiplier = 5,
			Color = Color3.fromRGB(100, 150, 255),
		},
		Epic = {
			DisplayName = "Brunch Deluxe BEC",
			ValueMultiplier = 12,
			Color = Color3.fromRGB(190, 100, 255),
		},
		Legendary = {
			DisplayName = "Golden Yolk BEC",
			ValueMultiplier = 30,
			Color = Color3.fromRGB(255, 200, 40),
		},
		Secret = {
			DisplayName = "Bodega Cat's Secret BEC",
			ValueMultiplier = 100,
			Color = Color3.fromRGB(160, 60, 255),
		},
	},
}
