-- Every food stand in the New York area, in build order.
--
-- `Food` names a module in ReplicatedStorage.Data.Foods. `Existing` names a
-- stand model already hand-built in eattheworld.rbxl - the vendor wires up
-- its OrderPoint/OrderPrompt/FoodSpawnPoint as-is. Entries without `Existing`
-- are grayboxed at runtime by FoodStandBuilder: `OffsetX`/`OffsetZ` are studs
-- from NewYork.ArrivalPoint (customers arrive facing +Z, so the plaza runs
-- toward +Z and the stands face back toward -Z).
return {
	{
		Food = "Pizza",
		Existing = "PizzaStand",
	},
	{
		Food = "BaconEggCheese",
		StandName = "Bodega Bagel Cart",
		Tint = Color3.fromRGB(210, 170, 120),
		OffsetX = -24,
		OffsetZ = 62,
	},
	{
		Food = "HotDog",
		StandName = "Hot Dog Cart",
		Tint = Color3.fromRGB(190, 60, 55),
		OffsetX = -46,
		OffsetZ = 62,
	},
	{
		Food = "Pretzel",
		StandName = "Street Pretzel Cart",
		Tint = Color3.fromRGB(150, 95, 40),
		OffsetX = 24,
		OffsetZ = 62,
	},
}
