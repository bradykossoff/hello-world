-- Shared low-level graybox primitives, used by every scene kit (CityKit for
-- New York, ParkKit for the hub garden). Nothing here has a theme - it just
-- makes anchored parts, lights, and signs.

local BuildKit = {}

function BuildKit.part(parent, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = parent
	return p
end

function BuildKit.light(parentPart, props)
	local l = Instance.new("PointLight")
	l.Brightness = 1.4
	l.Range = 16
	l.Color = Color3.fromRGB(255, 236, 202)
	l.Shadows = false
	for k, v in pairs(props or {}) do
		l[k] = v
	end
	l.Parent = parentPart
	return l
end

-- Fix a floating-text BillboardGui: stop it punching through the world, fade it
-- with distance, and give it a readable backing panel so it reads as signage.
function BuildKit.polishBillboard(bb, maxDistance)
	if not bb:IsA("BillboardGui") then
		return
	end
	bb.AlwaysOnTop = false
	bb.LightInfluence = 0
	bb.MaxDistance = maxDistance or bb:GetAttribute("SignMaxDistance") or 110
	bb.ClipsDescendants = true

	if bb:FindFirstChild("SignBacking") then
		return
	end
	local back = Instance.new("Frame")
	back.Name = "SignBacking"
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Color3.fromRGB(24, 20, 16)
	back.BackgroundTransparency = 0.12
	back.BorderSizePixel = 0
	back.ZIndex = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = back

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 198, 120)
	stroke.Thickness = 2
	stroke.Transparency = 0.15
	stroke.Parent = back

	for _, child in ipairs(bb:GetChildren()) do
		if child:IsA("GuiObject") then
			child.ZIndex = math.max(child.ZIndex, 2)
		end
	end
	back.Parent = bb
end

-- A one-sided sign painted on a face of `host` (a Part). Unlike a BillboardGui
-- it only shows from one direction, so it never floats over the world.
function BuildKit.surfaceSign(host, face, text, textColor, bgColor, font)
	local sg = Instance.new("SurfaceGui")
	sg.Name = "SignFace"
	sg.Face = face
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 48
	sg.LightInfluence = 0
	sg.MaxDistance = 140

	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = bgColor or Color3.fromRGB(12, 10, 16)
	bg.BackgroundTransparency = bgColor and 0 or 1
	bg.BorderSizePixel = 0
	bg.Parent = sg

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(0.92, 0.82)
	label.Position = UDim2.fromScale(0.04, 0.09)
	label.BackgroundTransparency = 1
	label.Font = font or Enum.Font.Bangers
	label.Text = text
	label.TextColor3 = textColor or Color3.fromRGB(255, 240, 220)
	label.TextScaled = true
	label.Parent = bg

	sg.Parent = host
	return sg
end

return BuildKit
