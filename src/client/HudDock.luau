-- The single on-screen action bar. Every persistent HUD button (Menu, Shop,
-- Upgrades, Plaza) registers here instead of parenting its own loose button to
-- PlayerGui, so the screen stays uncluttered and the buttons share one look.
--
-- Each caller LocalScript does:
--   local HudDock = require(script.Parent.HudDock)
--   local entry = HudDock.register({ id = "shop", label = "SHOP", icon = "🛒",
--       order = 20, accent = HudDock.Theme.Basil, onActivate = function() ... end })
--   entry.setActive(true)   -- highlight while that panel is open
--
-- HudDock.makePanel(title, size) returns a themed modal shell so panels match
-- the dock without each script re-deriving the palette.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Theme = {
	Wood = Color3.fromRGB(54, 37, 26),
	WoodDark = Color3.fromRGB(36, 24, 17),
	WoodLight = Color3.fromRGB(82, 56, 40),
	Parchment = Color3.fromRGB(238, 226, 195),
	ParchmentDim = Color3.fromRGB(214, 198, 162),
	InkBrown = Color3.fromRGB(58, 43, 24),
	Tomato = Color3.fromRGB(202, 74, 56),
	Basil = Color3.fromRGB(101, 156, 76),
	Butter = Color3.fromRGB(242, 191, 84),
	TextLight = Color3.fromRGB(255, 248, 235),
	TitleFont = Enum.Font.FredokaOne,
	BodyFont = Enum.Font.Gotham,
	BodyBoldFont = Enum.Font.GothamBold,
}

local HOVER_TWEEN = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

----------------------------------------------------------------
-- Dock shell
----------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "HudDockGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 8
gui.Parent = playerGui

local dock = Instance.new("Frame")
dock.Name = "Dock"
dock.AnchorPoint = Vector2.new(0.5, 1)
dock.Position = UDim2.new(0.5, 0, 1, -14)
dock.AutomaticSize = Enum.AutomaticSize.X
dock.Size = UDim2.new(0, 0, 0, 66)
dock.BackgroundColor3 = Theme.Wood
dock.BorderSizePixel = 0
dock.Parent = gui

local dockCorner = Instance.new("UICorner")
dockCorner.CornerRadius = UDim.new(0, 18)
dockCorner.Parent = dock

local dockGradient = Instance.new("UIGradient")
dockGradient.Rotation = 90
dockGradient.Color = ColorSequence.new(Theme.WoodLight, Theme.WoodDark)
dockGradient.Parent = dock

local dockStroke = Instance.new("UIStroke")
dockStroke.Color = Theme.WoodDark
dockStroke.Thickness = 2
dockStroke.Parent = dock

local dockPadding = Instance.new("UIPadding")
dockPadding.PaddingLeft = UDim.new(0, 10)
dockPadding.PaddingRight = UDim.new(0, 10)
dockPadding.PaddingTop = UDim.new(0, 8)
dockPadding.PaddingBottom = UDim.new(0, 8)
dockPadding.Parent = dock

local dockLayout = Instance.new("UIListLayout")
dockLayout.FillDirection = Enum.FillDirection.Horizontal
dockLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
dockLayout.VerticalAlignment = Enum.VerticalAlignment.Center
dockLayout.SortOrder = Enum.SortOrder.LayoutOrder
dockLayout.Padding = UDim.new(0, 8)
dockLayout.Parent = dock

-- Keep the whole bar comfortably on-screen on small / narrow displays.
local dockScale = Instance.new("UIScale")
dockScale.Parent = dock

local function fitDock()
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local needed = dock.AbsoluteSize.X / math.max(dockScale.Scale, 0.01)
	local maxWidth = viewport.X - 24
	local target = math.clamp(maxWidth / math.max(needed, 1), 0.62, 1)
	if math.abs(target - dockScale.Scale) > 0.005 then
		dockScale.Scale = target
	end
end

----------------------------------------------------------------
-- Button registration
----------------------------------------------------------------

local Dock = {}
Dock.Theme = Theme

local entries = {}

-- Close every open panel except the one that just opened, so the dock behaves
-- like a single menu rather than a pile of independent toggles.
function Dock.closeOthers(exceptId: string)
	for id, entry in pairs(entries) do
		if id ~= exceptId and entry.close then
			entry.close()
		end
	end
end

function Dock.register(config: {
	id: string,
	label: string,
	icon: string?,
	order: number?,
	accent: Color3?,
	onActivate: (() -> ())?,
	close: (() -> ())?,
})
	local accent = config.accent or Theme.Butter

	local btn = Instance.new("TextButton")
	btn.Name = config.id
	btn.LayoutOrder = config.order or 100
	btn.AutomaticSize = Enum.AutomaticSize.X
	btn.Size = UDim2.new(0, 0, 1, 0)
	btn.BackgroundColor3 = Theme.Parchment
	btn.AutoButtonColor = false
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.Parent = dock

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = btn

	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.WoodDark
	stroke.Thickness = 2
	stroke.Transparency = 0.4
	stroke.Parent = btn

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 14)
	pad.PaddingRight = UDim.new(0, 14)
	pad.Parent = btn

	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.AutomaticSize = Enum.AutomaticSize.X
	row.Size = UDim2.new(0, 0, 1, 0)
	row.Parent = btn

	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rowLayout.Padding = UDim.new(0, 6)
	rowLayout.Parent = row

	if config.icon and config.icon ~= "" then
		local iconLabel = Instance.new("TextLabel")
		iconLabel.LayoutOrder = 1
		iconLabel.BackgroundTransparency = 1
		iconLabel.AutomaticSize = Enum.AutomaticSize.X
		iconLabel.Size = UDim2.new(0, 0, 1, 0)
		iconLabel.Font = Theme.TitleFont
		iconLabel.Text = config.icon
		iconLabel.TextSize = 22
		iconLabel.TextColor3 = Theme.InkBrown
		iconLabel.Parent = row
	end

	local textLabel = Instance.new("TextLabel")
	textLabel.LayoutOrder = 2
	textLabel.BackgroundTransparency = 1
	textLabel.AutomaticSize = Enum.AutomaticSize.X
	textLabel.Size = UDim2.new(0, 0, 1, 0)
	textLabel.Font = Theme.TitleFont
	textLabel.Text = config.label
	textLabel.TextSize = 20
	textLabel.TextColor3 = Theme.InkBrown
	textLabel.Parent = row

	local active = false
	local hovered = false

	local function repaint()
		local target = Theme.Parchment
		if active then
			target = accent
		elseif hovered then
			target = Theme.Butter
		end
		TweenService:Create(btn, HOVER_TWEEN, { BackgroundColor3 = target }):Play()
		stroke.Transparency = (active or hovered) and 0.1 or 0.4
	end

	btn.MouseEnter:Connect(function()
		hovered = true
		repaint()
	end)
	btn.MouseLeave:Connect(function()
		hovered = false
		repaint()
	end)
	btn.Activated:Connect(function()
		if config.onActivate then
			config.onActivate()
		end
	end)

	task.defer(fitDock)

	local entry = {
		button = btn,
		close = config.close,
		setActive = function(value: boolean)
			active = value
			repaint()
		end,
	}
	entries[config.id] = entry
	return entry
end

----------------------------------------------------------------
-- Shared themed panel shell
----------------------------------------------------------------

function Dock.makePanel(titleText: string, size: UDim2)
	local panelGui = Instance.new("ScreenGui")
	panelGui.Name = titleText:gsub("%s", "") .. "PanelGui"
	panelGui.ResetOnSpawn = false
	panelGui.IgnoreGuiInset = false
	panelGui.DisplayOrder = 9
	panelGui.Enabled = true
	panelGui.Parent = playerGui

	local root = Instance.new("Frame")
	root.Name = "Panel"
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.new(0.5, 0, 0.5, 0)
	root.Size = size
	root.BackgroundColor3 = Theme.Parchment
	root.BorderSizePixel = 0
	root.ClipsDescendants = true
	root.Visible = false
	root.Parent = panelGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = root

	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.WoodDark
	stroke.Thickness = 3
	stroke.Parent = root

	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 48)
	titleBar.BackgroundColor3 = Theme.Wood
	titleBar.BorderSizePixel = 0
	titleBar.Parent = root

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -64, 1, 0)
	titleLabel.Position = UDim2.new(0, 16, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = titleText
	titleLabel.Font = Theme.TitleFont
	titleLabel.TextColor3 = Theme.TextLight
	titleLabel.TextSize = 24
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleBar

	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.AnchorPoint = Vector2.new(1, 0.5)
	closeButton.Position = UDim2.new(1, -10, 0.5, 0)
	closeButton.Size = UDim2.new(0, 32, 0, 32)
	closeButton.BackgroundColor3 = Theme.Tomato
	closeButton.Text = "X"
	closeButton.Font = Theme.BodyBoldFont
	closeButton.TextColor3 = Theme.TextLight
	closeButton.TextSize = 18
	closeButton.Parent = titleBar

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton

	local body = Instance.new("Frame")
	body.Name = "Body"
	body.Position = UDim2.new(0, 12, 0, 58)
	body.Size = UDim2.new(1, -24, 1, -70)
	body.BackgroundTransparency = 1
	body.Parent = root

	local api = {
		root = root,
		body = body,
		gui = panelGui,
		onClose = nil,
	}

	function api:setOpen(open: boolean)
		root.Visible = open
		if open then
			root.Size = UDim2.new(size.X.Scale * 0.92, size.X.Offset * 0.92, size.Y.Scale * 0.92, size.Y.Offset * 0.92)
			TweenService:Create(root, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = size,
			}):Play()
		end
	end

	function api:isOpen(): boolean
		return root.Visible
	end

	closeButton.Activated:Connect(function()
		api:setOpen(false)
		if api.onClose then
			api.onClose()
		end
	end)

	return api
end

dock:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitDock)

local function watchCamera()
	local camera = workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(fitDock)
		fitDock()
	end
end
watchCamera()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
GuiService:GetPropertyChangedSignal("MenuIsOpen"):Connect(fitDock)
task.defer(fitDock)

return Dock
