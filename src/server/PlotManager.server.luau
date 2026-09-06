local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

local PlotUtils = require(ServerScriptService.Modules.PlotUtils)
local Economy = require(ServerScriptService.Modules.Economy)
local Upgrades = require(ServerScriptService.Modules.Upgrades)
local KitchenBuilder = require(ServerScriptService.Modules.KitchenBuilder)

-- We control spawning ourselves so each player lands at their own plot instead
-- of a random default SpawnLocation.
Players.CharacterAutoLoads = false

-- GetDataStore itself can throw in Studio when the place isn't published and
-- "Studio Access to API Services" isn't enabled. Guard it so the plot system
-- still works during testing; persistence just won't stick until one of those
-- is true.
local restaurantStore
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore("RestaurantData_v2")
	end)
	if ok then
		restaurantStore = result
	else
		warn("DataStore unavailable (expected when testing an unpublished place): " .. tostring(result))
	end
end

local plotsFolder = Workspace:WaitForChild("Plots")

-- Seed money for a brand-new player, enough to stock a few starter pizzas
-- before customers start paying out.
local STARTING_MONEY = 250

-- Tracks each player's CharacterAdded connection so we can tear it down when
-- they lose their plot (leaving, or later: switching plots).
local spawnConnections = {}

local function defaultUpgradeData()
	local data = {}
	for trackName, defaultLevel in pairs(Upgrades.DefaultLevels) do
		data[trackName] = defaultLevel
	end
	return data
end

local function updateBillboard(plot)
	local ownerName = plot:GetAttribute("OwnerName")
	local kitchenStage = plot:GetAttribute("KitchenStage") or 1
	local menuCount = plot:GetAttribute("MenuCount") or 0
	local signPost = plot:FindFirstChild("SignPost")
	if not signPost then return end
	local billboard = signPost:FindFirstChild("Nameplate")
	if not billboard then return end

	local nameLabel = billboard:FindFirstChild("NameLabel")
	local levelLabel = billboard:FindFirstChild("LevelLabel")
	local statLabel = billboard:FindFirstChild("StatLabel")

	if ownerName == nil or ownerName == "" then
		if nameLabel then nameLabel.Text = "Empty Plot" end
		if levelLabel then levelLabel.Text = "" end
		if statLabel then statLabel.Text = "" end
	else
		if nameLabel then nameLabel.Text = ownerName .. "'s Restaurant" end
		if levelLabel then levelLabel.Text = "Stage " .. tostring(kitchenStage) end
		if statLabel then statLabel.Text = "Menu: " .. tostring(menuCount) .. " item" .. (menuCount == 1 and "" or "s") end
	end
end

-- Turns a plot's Menu folder into a plain array of tables for the DataStore.
local function serializeMenu(plot)
	local menu = plot:FindFirstChild("Menu")
	if not menu then return {} end

	local items = {}
	for _, item in ipairs(menu:GetChildren()) do
		table.insert(items, {
			FoodName = item:GetAttribute("FoodName"),
			Rarity = item:GetAttribute("Rarity"),
			DisplayName = item:GetAttribute("DisplayName"),
			ValueMultiplier = item:GetAttribute("ValueMultiplier"),
			BaseRestaurantValue = item:GetAttribute("BaseRestaurantValue"),
		})
	end
	return items
end

-- Rebuilds a plot's Menu folder from saved data (used on assignment) and clears
-- it back to empty (used on release, so the next owner starts fresh).
local function restoreMenu(plot, items)
	local menu = plot:FindFirstChild("Menu")
	if not menu then return end

	menu:ClearAllChildren()

	for _, data in ipairs(items or {}) do
		local menuItem = Instance.new("Folder")
		menuItem.Name = "MenuItem"
		menuItem:SetAttribute("FoodName", data.FoodName)
		menuItem:SetAttribute("Rarity", data.Rarity)
		menuItem:SetAttribute("DisplayName", data.DisplayName)
		menuItem:SetAttribute("ValueMultiplier", data.ValueMultiplier)
		menuItem:SetAttribute("BaseRestaurantValue", data.BaseRestaurantValue)
		menuItem.Parent = menu
	end

	plot:SetAttribute("MenuCount", #menu:GetChildren())
end

local function loadPlayerData(userId)
	local defaults = defaultUpgradeData()
	defaults.Money = STARTING_MONEY
	defaults.Menu = {}

	if not restaurantStore then
		return defaults
	end

	local success, data = pcall(function()
		return restaurantStore:GetAsync(tostring(userId))
	end)
	if success and data then
		data.Money = data.Money or 0
		data.Menu = data.Menu or {}
		for trackName, defaultLevel in pairs(Upgrades.DefaultLevels) do
			data[trackName] = data[trackName] or defaultLevel
		end
		return data
	end
	return defaults
end

local function savePlayerData(userId, data)
	if not restaurantStore then
		return
	end
	for attempt = 1, 3 do
		local success, err = pcall(function()
			restaurantStore:SetAsync(tostring(userId), data)
		end)
		if success then
			return
		end
		warn(string.format("Save attempt %d failed for %s: %s", attempt, tostring(userId), tostring(err)))
		if attempt < 3 then
			task.wait(2 ^ attempt)
		end
	end
end

-- Snapshots everything persisted for a player (money, upgrade levels, menu)
-- without touching the plot - used by both autosave and plot release.
local function collectPlayerData(player)
	local plot = PlotUtils.getPlotForPlayer(plotsFolder, player)

	local data = { Money = Economy.Get(player) }
	if plot then
		for trackName in pairs(Upgrades.AttributeNames) do
			data[trackName] = Upgrades.GetLevel(plot, trackName)
		end
		data.Menu = serializeMenu(plot)
	else
		for trackName, level in pairs(defaultUpgradeData()) do
			data[trackName] = level
		end
		data.Menu = {}
	end
	return data
end

local function hookCharacterSpawn(player, plot)
	local old = spawnConnections[player]
	if old then
		old:Disconnect()
		spawnConnections[player] = nil
	end

	local spawnCFrame = PlotUtils.getSpawnCFrame(plot)
	if not spawnCFrame then
		warn("No spawn CFrame for " .. plot.Name .. " - falling back to default spawn")
		return
	end

	spawnConnections[player] = player.CharacterAdded:Connect(function(character)
		local hrp = character:WaitForChild("HumanoidRootPart", 5)
		if hrp then
			hrp.CFrame = spawnCFrame
		end
	end)
end

local function unhookCharacterSpawn(player)
	local conn = spawnConnections[player]
	if conn then
		conn:Disconnect()
		spawnConnections[player] = nil
	end
end

local function assignPlot(player)
	local data = loadPlayerData(player.UserId)
	Economy.Set(player, data.Money)

	local plot = PlotUtils.getFreePlot(plotsFolder)
	if not plot then
		warn("No free plot available for " .. player.Name .. " - need more plots!")
		player:LoadCharacter()
		return
	end

	plot:SetAttribute("OwnerUserId", player.UserId)
	plot:SetAttribute("OwnerName", player.Name)

	for trackName, attrName in pairs(Upgrades.AttributeNames) do
		if trackName ~= "KitchenStage" then
			plot:SetAttribute(attrName, data[trackName])
		end
	end

	-- Rebuild the dining area to match the saved Restaurant Size stage (a
	-- fresh plot is already Stage 1, but a returning player may have saved a
	-- higher stage - this also sets the KitchenStage attribute).
	KitchenBuilder.SetStage(plot, data.KitchenStage or 1)

	restoreMenu(plot, data.Menu)
	updateBillboard(plot)

	hookCharacterSpawn(player, plot)
	player:LoadCharacter()
end

local function releasePlot(player)
	unhookCharacterSpawn(player)

	savePlayerData(player.UserId, collectPlayerData(player))

	local plot = PlotUtils.getPlotForPlayer(plotsFolder, player)
	if plot then
		plot:SetAttribute("OwnerUserId", 0)
		plot:SetAttribute("OwnerName", "")
		for trackName, attrName in pairs(Upgrades.AttributeNames) do
			if trackName ~= "KitchenStage" then
				plot:SetAttribute(attrName, Upgrades.DefaultLevels[trackName])
			end
		end
		KitchenBuilder.SetStage(plot, Upgrades.DefaultLevels.KitchenStage)
		restoreMenu(plot, {})
		updateBillboard(plot)
	end
end

for _, plot in ipairs(plotsFolder:GetChildren()) do
	plot:GetAttributeChangedSignal("OwnerName"):Connect(function() updateBillboard(plot) end)
	plot:GetAttributeChangedSignal("KitchenStage"):Connect(function() updateBillboard(plot) end)
	plot:GetAttributeChangedSignal("MenuCount"):Connect(function() updateBillboard(plot) end)
	updateBillboard(plot)

	-- Give every unclaimed plot a Stage 1 building at boot so the hub isn't
	-- full of empty lots (assignPlot / releasePlot rebuild it from there).
	if (plot:GetAttribute("OwnerUserId") or 0) == 0 then
		KitchenBuilder.SetStage(plot, 1)
	end
end

Players.PlayerAdded:Connect(assignPlot)
Players.PlayerRemoving:Connect(releasePlot)

-- Periodic autosave so a server crash costs at most one interval of progress
-- rather than the whole session.
local AUTOSAVE_INTERVAL = 120

task.spawn(function()
	while true do
		task.wait(AUTOSAVE_INTERVAL)
		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(savePlayerData, player.UserId, collectPlayerData(player))
		end
	end
end)

game:BindToClose(function()
	local players = Players:GetPlayers()
	local pending = #players
	if pending == 0 then
		return
	end

	for _, player in ipairs(players) do
		task.spawn(function()
			releasePlot(player)
			pending -= 1
		end)
	end

	while pending > 0 do
		task.wait()
	end
end)
