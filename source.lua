--[[
	NEMESIS UI Library  (v1.1)
	A mobile-first Roblox/Luau UI library for script executors.

	Load:
		local NEMESIS = loadstring(game:HttpGet("https://raw.githubusercontent.com/DiabloPaidProjects/NEMESIS/main/source.lua"))()

	v1.1 highlights:
		- Rectangular, fully-rounded window with a smooth minimize animation
		- Sidebar tabs with icons (Lucide names or asset IDs) + active highlight
		- GroupBox containers and optional two-column content layout
		- Full pop-out color picker (SV square, hue, alpha, editable HEX)
		- Topbar search that filters the active tab
		- Broad executor compatibility + mobile/touch support

	API (dot-style):
		local Win = NEMESIS.Window({ title = "NEMESIS" })
		local Tab = Win.Tab("Main", { icon = "home" })
		local Box = Tab.GroupBox("Combat")
		Box.Toggle({ text = "Auto Farm", default = false, flag = "autofarm", callback = function(v) end })
]]

local NEMESIS = {}
NEMESIS.Flags = {}
NEMESIS.Version = "1.2.0"

----------------------------------------------------------------------
-- Services (cloneref-safe)
----------------------------------------------------------------------
local function getService(name)
	local ok, svc = pcall(function()
		return game:GetService(name)
	end)
	if ok and svc then
		if type(cloneref) == "function" then
			local ok2, c = pcall(cloneref, svc)
			if ok2 and c then
				return c
			end
		end
		return svc
	end
	return nil
end

local TweenService = getService("TweenService")
local UserInputService = getService("UserInputService")
local Players = getService("Players")
local CoreGui = getService("CoreGui")

----------------------------------------------------------------------
-- Executor compatibility
----------------------------------------------------------------------
local function localPlayer()
	return Players and Players.LocalPlayer
end

local function getGuiParent()
	if type(gethui) == "function" then
		local ok, h = pcall(gethui)
		if ok and h then return h end
	end
	if type(get_hidden_gui) == "function" then
		local ok, h = pcall(get_hidden_gui)
		if ok and h then return h end
	end
	if CoreGui then
		return CoreGui
	end
	local lp = localPlayer()
	if lp then
		return lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui")
	end
	return nil
end

local function protectGui(gui)
	pcall(function()
		if syn and syn.protect_gui then
			syn.protect_gui(gui)
		elseif type(protectgui) == "function" then
			protectgui(gui)
		end
	end)
end

local function setClipboard(text)
	for _, fn in ipairs({ setclipboard, toclipboard, set_clipboard }) do
		if type(fn) == "function" then
			pcall(fn, text)
			return true
		end
	end
	return false
end

----------------------------------------------------------------------
-- Icons (Lucide names via Rayfield's icon map, or raw asset IDs)
----------------------------------------------------------------------
local ICON_URL = "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/icons.lua"
local iconMap = nil -- nil = not tried, false = failed, table = loaded

local function loadIconMap()
	if iconMap ~= nil then
		return iconMap
	end
	iconMap = false
	if type(loadstring) == "function" then
		pcall(function()
			local src = game:HttpGet(ICON_URL)
			local fn = loadstring(src)
			if type(fn) == "function" then
				local ok, map = pcall(fn)
				if ok and type(map) == "table" then
					iconMap = map
				end
			end
		end)
	end
	return iconMap
end

local function resolveIcon(icon)
	if not icon or icon == 0 or icon == "" then
		return nil
	end
	if type(icon) == "number" then
		return { Image = "rbxassetid://" .. icon }
	end
	if type(icon) == "string" then
		if string.match(icon, "^%d+$") then
			return { Image = "rbxassetid://" .. icon }
		end
		if string.find(icon, "rbxassetid://") == 1 or string.sub(icon, 1, 4) == "http" then
			return { Image = icon }
		end
		local map = loadIconMap()
		if type(map) == "table" then
			local sized = map["48px"] or map
			local entry = sized and sized[string.lower(icon)]
			if entry then
				return {
					Image = "rbxassetid://" .. entry[1],
					ImageRectSize = Vector2.new(entry[2][1], entry[2][2]),
					ImageRectOffset = Vector2.new(entry[3][1], entry[3][2]),
				}
			end
		end
	end
	return nil
end

local function applyIcon(image, spec)
	if not spec or not spec.Image then
		image.Image = ""
		image.Visible = false
		return false
	end
	image.Image = spec.Image
	if spec.ImageRectSize then
		image.ImageRectSize = spec.ImageRectSize
	end
	if spec.ImageRectOffset then
		image.ImageRectOffset = spec.ImageRectOffset
	end
	image.Visible = true
	return true
end

----------------------------------------------------------------------
-- Instance helpers
----------------------------------------------------------------------
local function Create(class, props, children)
	local inst = Instance.new(class)
	if props then
		for k, v in pairs(props) do
			if k ~= "Parent" then
				inst[k] = v
			end
		end
	end
	if children then
		for _, c in ipairs(children) do
			c.Parent = inst
		end
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

local function corner(rad)
	return Create("UICorner", { CornerRadius = UDim.new(0, rad or 8) })
end

local function stroke(color, thickness, transparency)
	return Create("UIStroke", {
		Color = color or Color3.fromRGB(45, 45, 58),
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function padding(all)
	return Create("UIPadding", {
		PaddingTop = UDim.new(0, all),
		PaddingBottom = UDim.new(0, all),
		PaddingLeft = UDim.new(0, all),
		PaddingRight = UDim.new(0, all),
	})
end

local function tagSearch(frame, text)
	pcall(function()
		frame:SetAttribute("NemesisSearch", tostring(text or ""))
	end)
end

----------------------------------------------------------------------
-- Theme
----------------------------------------------------------------------
local THEME = {
	Background = Color3.fromRGB(18, 18, 24),
	Sidebar = Color3.fromRGB(23, 23, 31),
	Topbar = Color3.fromRGB(22, 22, 30),
	Element = Color3.fromRGB(30, 30, 40),
	ElementHover = Color3.fromRGB(38, 38, 50),
	Group = Color3.fromRGB(26, 26, 35),
	Stroke = Color3.fromRGB(45, 45, 58),
	ElementStroke = Color3.fromRGB(50, 50, 62),
	Text = Color3.fromRGB(235, 235, 240),
	SubText = Color3.fromRGB(150, 150, 165),
	Accent = Color3.fromRGB(140, 90, 255),
	ToggleOff = Color3.fromRGB(100, 100, 110),
	Knob = Color3.fromRGB(240, 240, 245),
}

local FONT = Enum.Font.Gotham
local FONT_MED = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

----------------------------------------------------------------------
-- Gradient helpers
----------------------------------------------------------------------
local function numSeq(a, b)
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, a),
		NumberSequenceKeypoint.new(1, b),
	})
end

local function hueSequence()
	local kp = {}
	for i = 0, 6 do
		table.insert(kp, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)))
	end
	return ColorSequence.new(kp)
end

----------------------------------------------------------------------
-- Tween helpers
----------------------------------------------------------------------
-- Rayfield-style easing: Exponential almost everywhere.
local TI = {
	EXP = TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),   -- hover, fills, flashes
	FAST = TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),  -- toggle, arrows
	TAB = TweenInfo.new(0.7, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),   -- open, tab switch, minimize
	EXPAND = TweenInfo.new(0.45, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), -- dropdown / panels
	POP = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),         -- slider handle grab
}
-- Back-compat aliases (older call sites)
TI.OPEN = TI.TAB
TI.HOVER = TI.EXP
TI.SLIDE = TI.EXPAND
TI.NOTIFY = TI.EXP

local function tween(inst, props, info)
	local t = TweenService:Create(inst, info or TI.SLIDE, props)
	t:Play()
	return t
end

----------------------------------------------------------------------
-- Mobile / scale
----------------------------------------------------------------------
local IS_MOBILE = false
pcall(function()
	IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end)

local function viewportSize()
	local ok, vp = pcall(function()
		return workspace.CurrentCamera.ViewportSize
	end)
	if ok and vp and vp.X and vp.X > 0 then
		return vp
	end
	return Vector2.new(1280, 720)
end

local function computeScale()
	local vp = viewportSize()
	local w = vp.X
	if IS_MOBILE then
		return math.clamp(w / 1000, 0.8, 1.2)
	end
	return math.clamp(w / 1280, 0.8, 1.1)
end

----------------------------------------------------------------------
-- Unified mouse + touch drag
----------------------------------------------------------------------
local function makeDraggable(frame, handle)
	handle = handle or frame
	local dragging = false
	local dragStart, startPos

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

-- generic horizontal drag for sliders / channels (mouse + touch)
local function bindBarDrag(hit, onAlpha)
	local dragging = false
	local function upd(input)
		local rel = math.clamp((input.Position.X - hit.AbsolutePosition.X) / hit.AbsoluteSize.X, 0, 1)
		onAlpha(rel)
	end
	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			upd(input)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			upd(input)
		end
	end)
end

local function bindHover(button, target, base, hover)
	button.MouseEnter:Connect(function()
		tween(target, { BackgroundColor3 = hover }, TI.HOVER)
	end)
	button.MouseLeave:Connect(function()
		tween(target, { BackgroundColor3 = base }, TI.HOVER)
	end)
end

----------------------------------------------------------------------
-- Root ScreenGui + notifications
----------------------------------------------------------------------
local screenGui
local notifyHolder

local function ensureRoot()
	if screenGui and screenGui.Parent then
		return screenGui
	end
	screenGui = Create("ScreenGui", {
		Name = "NEMESIS_" .. tostring(math.random(1000, 9999)),
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 9999,
		IgnoreGuiInset = true,
	})
	pcall(function()
		screenGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	end)
	protectGui(screenGui)
	screenGui.Parent = getGuiParent()

	notifyHolder = Create("Frame", {
		Name = "Notifications",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.new(0, 300, 1, -32),
		BackgroundTransparency = 1,
		Parent = screenGui,
	}, {
		Create("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 10),
		}),
	})
	return screenGui
end

----------------------------------------------------------------------
-- Notifications
----------------------------------------------------------------------
function NEMESIS.Notify(opts)
	opts = opts or {}
	ensureRoot()

	local card = Create("Frame", {
		BackgroundColor3 = THEME.Element,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = notifyHolder,
	}, {
		corner(10),
		stroke(THEME.Stroke, 1, 0.2),
		padding(12),
		Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }),
		Create("TextLabel", {
			Name = "Title",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 18),
			Font = FONT_BOLD,
			Text = tostring(opts.title or "Notification"),
			TextColor3 = THEME.Accent,
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTransparency = 1,
		}),
		Create("TextLabel", {
			Name = "Content",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Font = FONT,
			Text = tostring(opts.content or ""),
			TextColor3 = THEME.Text,
			TextSize = 13,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTransparency = 1,
		}),
	})

	card.BackgroundTransparency = 1
	tween(card, { BackgroundTransparency = 0 }, TI.NOTIFY)
	for _, child in ipairs(card:GetChildren()) do
		if child:IsA("TextLabel") then
			tween(child, { TextTransparency = 0 }, TI.NOTIFY)
		end
	end

	local duration = tonumber(opts.duration) or 4
	task.delay(duration, function()
		if not card or not card.Parent then
			return
		end
		tween(card, { BackgroundTransparency = 1 }, TI.SLIDE)
		for _, child in ipairs(card:GetChildren()) do
			if child:IsA("TextLabel") then
				tween(child, { TextTransparency = 1 }, TI.SLIDE)
			end
		end
		task.delay(0.25, function()
			if card then
				card:Destroy()
			end
		end)
	end)
end

----------------------------------------------------------------------
-- Shared row scaffold
----------------------------------------------------------------------
local function newRow(parent, height)
	return Create("Frame", {
		BackgroundColor3 = THEME.Element,
		Size = UDim2.new(1, 0, 0, height or 44),
		Parent = parent,
	}, {
		corner(6),
		stroke(THEME.ElementStroke, 1, 0.5),
		padding(12),
	})
end

local function rowLabel(parent, text)
	tagSearch(parent, text)
	return Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -44, 1, 0),
		Font = FONT_MED,
		Text = tostring(text or ""),
		TextColor3 = THEME.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = parent,
	})
end

----------------------------------------------------------------------
-- Element factories: (parent, accent, opts) -> control { Set, Get }
----------------------------------------------------------------------
local Elements = {}

function Elements.Section(parent, accent, title)
	local holder = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 26),
		Parent = parent,
	})
	tagSearch(holder, title)
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Font = FONT_BOLD,
		Text = string.upper(tostring(title or "Section")),
		TextColor3 = THEME.SubText,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Bottom,
		Parent = holder,
	})
	Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = THEME.Stroke,
		BorderSizePixel = 0,
		Parent = holder,
	})
end

function Elements.Label(parent, accent, text)
	local lbl = Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = FONT,
		Text = tostring(text or ""),
		TextColor3 = THEME.SubText,
		TextSize = 13,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent,
	})
	tagSearch(lbl, text)
	return {
		Set = function(v) lbl.Text = tostring(v) end,
		Get = function() return lbl.Text end,
	}
end

function Elements.Paragraph(parent, accent, opts)
	opts = opts or {}
	local holder = Create("Frame", {
		BackgroundColor3 = THEME.Element,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = parent,
	}, {
		corner(8),
		stroke(THEME.Stroke, 1, 0.4),
		padding(10),
		Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
		Create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 18),
			Font = FONT_BOLD,
			Text = tostring(opts.title or "Title"),
			TextColor3 = THEME.Text,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		Create("TextLabel", {
			Name = "Body",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Font = FONT,
			Text = tostring(opts.content or ""),
			TextColor3 = THEME.SubText,
			TextSize = 13,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
	})
	tagSearch(holder, (opts.title or "") .. " " .. (opts.content or ""))
	return {
		Set = function(v) holder:FindFirstChild("Body").Text = tostring(v) end,
	}
end

function Elements.Button(parent, accent, opts)
	opts = opts or {}
	local row = newRow(parent)
	local btn = Create("TextButton", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 20, 1, 0),
		Position = UDim2.new(0, -10, 0, 0),
		Text = "",
		Parent = row,
	})
	rowLabel(row, opts.text)
	local arrow = Create("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 20, 1, 0),
		Font = FONT_BOLD,
		Text = "\u{203A}",
		TextColor3 = accent,
		TextSize = 18,
		Parent = row,
	})
	bindHover(btn, row, THEME.Element, THEME.ElementHover)
	btn.MouseButton1Click:Connect(function()
		-- Rayfield-style click flash: bg -> hover, indicator fades, then revert
		tween(row, { BackgroundColor3 = THEME.ElementHover }, TI.EXP)
		tween(arrow, { TextTransparency = 1 }, TI.EXP)
		task.delay(0.2, function()
			tween(row, { BackgroundColor3 = THEME.Element }, TI.EXP)
			tween(arrow, { TextTransparency = 0 }, TI.EXP)
		end)
		if type(opts.callback) == "function" then
			pcall(opts.callback)
		end
	end)
	return { Instance = row }
end

function Elements.Toggle(parent, accent, opts)
	opts = opts or {}
	local state = opts.default and true or false
	local row = newRow(parent)
	rowLabel(row, opts.text)

	local track = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 44, 0, 22),
		BackgroundColor3 = THEME.Background,
		Parent = row,
	}, { corner(11) })
	local trackStroke = stroke(THEME.ToggleOff, 1.5, 0)
	trackStroke.Parent = track
	local knob = Create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.new(0, 16, 0, 16),
		BackgroundColor3 = THEME.ToggleOff,
		Parent = track,
	}, { corner(8) })
	local click = Create("TextButton", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 20, 1, 0),
		Position = UDim2.new(0, -10, 0, 0),
		Text = "",
		Parent = row,
	})

	local control = {}
	local function render(animate)
		local info = animate and TI.FAST or TweenInfo.new(0)
		local col = state and accent or THEME.ToggleOff
		tween(knob, {
			Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			BackgroundColor3 = col,
		}, info)
		tween(trackStroke, { Color = col }, info)
	end
	function control.Set(v, silent)
		state = v and true or false
		if opts.flag then NEMESIS.Flags[opts.flag] = state end
		render(true)
		if not silent and type(opts.callback) == "function" then
			pcall(opts.callback, state)
		end
	end
	function control.Get() return state end

	bindHover(click, row, THEME.Element, THEME.ElementHover)
	click.MouseButton1Click:Connect(function() control.Set(not state) end)

	if opts.flag then NEMESIS.Flags[opts.flag] = state end
	render(false)
	return control
end

function Elements.Slider(parent, accent, opts)
	opts = opts or {}
	local min = tonumber(opts.min) or 0
	local max = tonumber(opts.max) or 100
	local increment = tonumber(opts.increment) or 1
	local value = math.clamp(tonumber(opts.default) or min, min, max)
	local suffix = opts.suffix or ""

	local row = newRow(parent, 50)
	tagSearch(row, opts.text)
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -60, 0, 18),
		Font = FONT_MED,
		Text = tostring(opts.text or "Slider"),
		TextColor3 = THEME.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})
	local valueLabel = Create("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, 60, 0, 18),
		Font = FONT_BOLD,
		Text = tostring(value) .. suffix,
		TextColor3 = accent,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = row,
	})
	local bar = Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, -4),
		Size = UDim2.new(1, 0, 0, 6),
		BackgroundColor3 = THEME.Stroke,
		Parent = row,
	}, { corner(3) })
	local fill = Create("Frame", {
		Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
		BackgroundColor3 = accent,
		Parent = bar,
	}, { corner(3) })
	local handle = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
		Size = UDim2.new(0, 12, 0, 12),
		BackgroundColor3 = THEME.Knob,
		ZIndex = 2,
		Parent = bar,
	}, { corner(6), stroke(THEME.ElementStroke, 1, 0.2) })

	local control = {}
	local function setFromAlpha(alpha, fire)
		alpha = math.clamp(alpha, 0, 1)
		local raw = min + (max - min) * alpha
		local stepped = min + math.floor((raw - min) / increment + 0.5) * increment
		value = math.clamp(stepped, min, max)
		local frac = (value - min) / (max - min)
		valueLabel.Text = tostring(value) .. suffix
		tween(fill, { Size = UDim2.new(frac, 0, 1, 0) }, TI.EXP)
		tween(handle, { Position = UDim2.new(frac, 0, 0.5, 0) }, TI.EXP)
		if opts.flag then NEMESIS.Flags[opts.flag] = value end
		if fire and type(opts.callback) == "function" then
			pcall(opts.callback, value)
		end
	end
	function control.Set(v) setFromAlpha(((tonumber(v) or min) - min) / (max - min), true) end
	function control.Get() return value end

	bindBarDrag(bar, function(rel) setFromAlpha(rel, true) end)
	-- handle "pops" on grab (Rayfield Back easing)
	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			tween(handle, { Size = UDim2.new(0, 16, 0, 16) }, TI.POP)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			tween(handle, { Size = UDim2.new(0, 12, 0, 12) }, TI.POP)
		end
	end)

	if opts.flag then NEMESIS.Flags[opts.flag] = value end
	return control
end

function Elements.Dropdown(parent, accent, opts)
	opts = opts or {}
	local options = opts.options or {}
	local multi = opts.multi and true or false
	local selected = {}
	if multi and type(opts.default) == "table" then
		for _, v in ipairs(opts.default) do selected[v] = true end
	end
	local single = (not multi) and opts.default or nil

	local row = newRow(parent)
	rowLabel(row, opts.text)
	local current = Create("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -20, 0.5, 0),
		Size = UDim2.new(0, 120, 1, 0),
		Font = FONT,
		Text = "...",
		TextColor3 = THEME.SubText,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})
	local arrow = Create("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 16, 1, 0),
		Font = FONT_BOLD,
		Text = "\u{25BE}",
		TextColor3 = accent,
		TextSize = 14,
		Parent = row,
	})

	local listHolder = Create("Frame", {
		BackgroundColor3 = THEME.Background,
		Size = UDim2.new(1, 0, 0, 0),
		ClipsDescendants = true,
		Parent = parent,
	}, {
		corner(8),
		stroke(THEME.Stroke, 1, 0.4),
		Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }),
		padding(4),
	})

	local open = false
	local control = {}
	local function listValues()
		local list = {}
		for _, v in ipairs(options) do
			if selected[v] then table.insert(list, v) end
		end
		return list
	end
	local function refreshLabel()
		if multi then
			local parts = listValues()
			current.Text = #parts > 0 and table.concat(parts, ", ") or "None"
		else
			current.Text = single ~= nil and tostring(single) or "None"
		end
	end
	local function fire()
		if opts.flag then NEMESIS.Flags[opts.flag] = multi and listValues() or single end
		if type(opts.callback) == "function" then
			pcall(opts.callback, multi and listValues() or single)
		end
	end

	local optionButtons = {}
	local function rebuildOptions()
		for _, b in ipairs(optionButtons) do b:Destroy() end
		optionButtons = {}
		for _, v in ipairs(options) do
			local ob = Create("TextButton", {
				BackgroundColor3 = THEME.Element,
				Size = UDim2.new(1, 0, 0, 28),
				Font = FONT,
				Text = tostring(v),
				TextColor3 = THEME.Text,
				TextSize = 13,
				AutoButtonColor = false,
				Parent = listHolder,
			}, { corner(6) })
			local function paint()
				local on = multi and selected[v] or (single == v)
				ob.TextColor3 = on and accent or THEME.Text
				ob.BackgroundColor3 = on and THEME.ElementHover or THEME.Element
			end
			paint()
			ob.MouseEnter:Connect(function()
				local on = multi and selected[v] or (single == v)
				if not on then tween(ob, { BackgroundColor3 = THEME.ElementHover }, TI.EXP) end
			end)
			ob.MouseLeave:Connect(function()
				local on = multi and selected[v] or (single == v)
				if not on then tween(ob, { BackgroundColor3 = THEME.Element }, TI.EXP) end
			end)
			ob.MouseButton1Click:Connect(function()
				if multi then selected[v] = not selected[v] else single = v end
				for _, b in ipairs(optionButtons) do
					b.TextColor3 = THEME.Text
					b.BackgroundColor3 = THEME.Element
				end
				paint()
				refreshLabel()
				fire()
				if not multi then control.Toggle(false) end
			end)
			table.insert(optionButtons, ob)
		end
	end

	function control.Toggle(force)
		open = (force == nil) and (not open) or force
		local target = open and math.min(#options, 6) * 30 + 8 or 0
		tween(listHolder, { Size = UDim2.new(1, 0, 0, target) }, TI.EXPAND)
		tween(arrow, { Rotation = open and 180 or 0 }, TI.FAST)
	end
	function control.Set(v)
		if multi then
			selected = {}
			if type(v) == "table" then for _, x in ipairs(v) do selected[x] = true end end
		else
			single = v
		end
		rebuildOptions(); refreshLabel(); fire()
	end
	function control.Get() return multi and listValues() or single end
	function control.SetOptions(newOptions)
		options = newOptions or {}
		rebuildOptions(); refreshLabel()
	end

	local click = Create("TextButton", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 20, 1, 0),
		Position = UDim2.new(0, -10, 0, 0),
		Text = "",
		Parent = row,
	})
	bindHover(click, row, THEME.Element, THEME.ElementHover)
	click.MouseButton1Click:Connect(function() control.Toggle() end)

	rebuildOptions(); refreshLabel()
	if opts.flag then NEMESIS.Flags[opts.flag] = control.Get() end
	return control
end

function Elements.Input(parent, accent, opts)
	opts = opts or {}
	local row = newRow(parent)
	rowLabel(row, opts.text)
	local boxStroke = stroke(THEME.ElementStroke, 1, 0.3)
	local box = Create("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 140, 0, 28),
		BackgroundColor3 = THEME.Background,
		Font = FONT,
		PlaceholderText = tostring(opts.placeholder or "..."),
		Text = tostring(opts.default or ""),
		TextColor3 = THEME.Text,
		PlaceholderColor3 = THEME.SubText,
		TextSize = 13,
		ClearTextOnFocus = opts.clearOnFocus and true or false,
		Parent = row,
	}, { corner(6), boxStroke, padding(6) })

	local control = {}
	function control.Set(v) box.Text = tostring(v) end
	function control.Get() return box.Text end
	box.Focused:Connect(function()
		tween(boxStroke, { Color = accent }, TI.EXP)
	end)
	box.FocusLost:Connect(function()
		tween(boxStroke, { Color = THEME.ElementStroke }, TI.EXP)
		if opts.flag then NEMESIS.Flags[opts.flag] = box.Text end
		if type(opts.callback) == "function" then pcall(opts.callback, box.Text) end
	end)
	if opts.flag then NEMESIS.Flags[opts.flag] = box.Text end
	return control
end

function Elements.Keybind(parent, accent, opts)
	opts = opts or {}
	local mode = opts.mode or "Toggle"
	local key = opts.default
	local row = newRow(parent)
	rowLabel(row, opts.text)

	local kbStroke = stroke(THEME.ElementStroke, 1, 0.3)
	local btn = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 84, 0, 28),
		BackgroundColor3 = THEME.Background,
		Font = FONT_MED,
		Text = key and tostring(key.Name or key) or "None",
		TextColor3 = accent,
		TextSize = 13,
		AutoButtonColor = false,
		Parent = row,
	}, { corner(6), kbStroke })

	local listening = false
	local toggled = false
	local control = {}
	function control.Set(v)
		key = v
		btn.Text = v and tostring(v.Name or v) or "None"
		tween(kbStroke, { Color = THEME.ElementStroke }, TI.EXP)
		if opts.flag then NEMESIS.Flags[opts.flag] = key end
	end
	function control.Get() return key end

	btn.MouseButton1Click:Connect(function()
		listening = true
		btn.Text = "..."
		tween(kbStroke, { Color = accent }, TI.EXP)
	end)
	UserInputService.InputBegan:Connect(function(input, gpe)
		if listening and input.UserInputType == Enum.UserInputType.Keyboard then
			listening = false
			control.Set(input.KeyCode)
			return
		end
		if gpe or listening then return end
		if key and input.KeyCode == key then
			if mode == "Toggle" then
				toggled = not toggled
				if type(opts.callback) == "function" then pcall(opts.callback, toggled) end
			elseif mode == "Hold" then
				if type(opts.callback) == "function" then pcall(opts.callback, true) end
			else
				if type(opts.callback) == "function" then pcall(opts.callback) end
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if mode == "Hold" and key and input.KeyCode == key then
			if type(opts.callback) == "function" then pcall(opts.callback, false) end
		end
	end)

	if opts.flag then NEMESIS.Flags[opts.flag] = key end
	return control
end

----------------------------------------------------------------------
-- Color picker (full pop-out panel: SV square, hue, alpha, HEX)
----------------------------------------------------------------------
function Elements.ColorPicker(parent, accent, opts)
	opts = opts or {}
	local value = opts.default or Color3.fromRGB(255, 255, 255)
	local alpha = tonumber(opts.transparency) or 0 -- 0 = opaque, 1 = clear
	local h, s, v = value:ToHSV()

	local row = newRow(parent)
	rowLabel(row, opts.text)
	local swatch = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 40, 0, 22),
		BackgroundColor3 = value,
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	}, { corner(6), stroke(THEME.Stroke, 1, 0.2) })

	local control = {}
	local panel, svBase, svDot, hueDot, alphaBar, alphaDot, hexBox, pctLabel
	local opened = false

	local function colorNow() return Color3.fromHSV(h, s, v) end
	local function syncUI()
		value = colorNow()
		swatch.BackgroundColor3 = value
		if svBase then svBase.BackgroundColor3 = Color3.fromHSV(h, 1, 1) end
		if svDot then svDot.Position = UDim2.new(s, 0, 1 - v, 0) end
		if hueDot then hueDot.Position = UDim2.new(h, 0, 0.5, 0) end
		if alphaBar then alphaBar.BackgroundColor3 = value end
		if alphaDot then alphaDot.Position = UDim2.new(1 - alpha, 0, 0.5, 0) end
		if hexBox then
			hexBox.Text = string.format("#%02X%02X%02X",
				math.floor(value.R * 255 + 0.5),
				math.floor(value.G * 255 + 0.5),
				math.floor(value.B * 255 + 0.5))
		end
		if pctLabel then pctLabel.Text = tostring(math.floor((1 - alpha) * 100 + 0.5)) .. "%" end
	end
	local function commit()
		if opts.flag then NEMESIS.Flags[opts.flag] = value end
		if type(opts.callback) == "function" then pcall(opts.callback, value, alpha) end
	end

	local function buildPanel()
		panel = Create("Frame", {
			Name = "ColorPanel",
			Size = UDim2.new(0, 230, 0, 250),
			BackgroundColor3 = THEME.Background,
			Visible = false,
			ZIndex = 50,
			Parent = screenGui,
		}, {
			corner(10),
			stroke(THEME.Stroke, 1, 0),
			padding(10),
			Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
		})

		-- SV square
		local sv = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 130),
			BackgroundColor3 = Color3.fromHSV(h, 1, 1),
			Parent = panel,
		}, { corner(6) })
		svBase = sv
		Create("Frame", { -- white -> transparent (saturation)
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.new(1, 1, 1),
			Parent = sv,
		}, { corner(6), Create("UIGradient", { Transparency = numSeq(0, 1) }) })
		Create("Frame", { -- transparent -> black (value)
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.new(0, 0, 0),
			Parent = sv,
		}, { corner(6), Create("UIGradient", { Rotation = 90, Transparency = numSeq(1, 0) }) })
		svDot = Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(s, 0, 1 - v, 0),
			Size = UDim2.new(0, 10, 0, 10),
			BackgroundColor3 = Color3.new(1, 1, 1),
			ZIndex = 52,
			Parent = sv,
		}, { corner(5), stroke(Color3.new(0, 0, 0), 1, 0.3) })
		local svHit = Create("TextButton", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "", ZIndex = 53, Parent = sv })
		do
			local dragging = false
			local function upd(input)
				local rx = math.clamp((input.Position.X - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
				local ry = math.clamp((input.Position.Y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
				s = rx; v = 1 - ry
				syncUI(); commit()
			end
			svHit.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true; upd(input)
				end
			end)
			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then upd(input) end
			end)
		end

		-- hue slider
		local hue = Create("Frame", { Size = UDim2.new(1, 0, 0, 14), Parent = panel }, {
			corner(7),
			Create("UIGradient", { Color = hueSequence() }),
		})
		hueDot = Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(h, 0, 0.5, 0),
			Size = UDim2.new(0, 6, 1, 4),
			BackgroundColor3 = Color3.new(1, 1, 1),
			ZIndex = 52,
			Parent = hue,
		}, { corner(3), stroke(Color3.new(0, 0, 0), 1, 0.3) })
		bindBarDrag(hue, function(rel) h = rel; syncUI(); commit() end)

		-- alpha slider
		alphaBar = Create("Frame", { Size = UDim2.new(1, 0, 0, 14), BackgroundColor3 = value, Parent = panel }, {
			corner(7),
			Create("UIGradient", { Transparency = numSeq(0, 1) }),
		})
		alphaDot = Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(1 - alpha, 0, 0.5, 0),
			Size = UDim2.new(0, 6, 1, 4),
			BackgroundColor3 = Color3.new(1, 1, 1),
			ZIndex = 52,
			Parent = alphaBar,
		}, { corner(3), stroke(Color3.new(0, 0, 0), 1, 0.3) })
		bindBarDrag(alphaBar, function(rel) alpha = 1 - rel; syncUI(); commit() end)

		-- HEX row
		local hexRow = Create("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Parent = panel })
		Create("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.new(0, 36, 1, 0),
			Font = FONT_BOLD, Text = "HEX", TextColor3 = THEME.SubText, TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left, Parent = hexRow,
		})
		hexBox = Create("TextBox", {
			Position = UDim2.new(0, 40, 0, 0), Size = UDim2.new(1, -90, 1, 0),
			BackgroundColor3 = THEME.Element, Font = FONT, Text = "#FFFFFF",
			TextColor3 = THEME.Text, TextSize = 13, Parent = hexRow,
		}, { corner(6), stroke(THEME.Stroke, 1, 0.3), padding(6) })
		pctLabel = Create("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 44, 1, 0),
			BackgroundTransparency = 1, Font = FONT_MED, Text = "100%", TextColor3 = THEME.SubText, TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Right, Parent = hexRow,
		})
		hexBox.FocusLost:Connect(function()
			local hex = string.gsub(hexBox.Text, "#", "")
			if #hex == 6 then
				local r = tonumber(string.sub(hex, 1, 2), 16)
				local g = tonumber(string.sub(hex, 3, 4), 16)
				local b = tonumber(string.sub(hex, 5, 6), 16)
				if r and g and b then
					h, s, v = Color3.fromRGB(r, g, b):ToHSV()
					syncUI(); commit()
					return
				end
			end
			syncUI()
		end)

		syncUI()
	end

	local function openPanel(state)
		if not panel then buildPanel() end
		opened = (state == nil) and (not opened) or state
		if opened then
			-- position next to the swatch
			local ok = pcall(function()
				local p = swatch.AbsolutePosition
				panel.Position = UDim2.fromOffset(p.X - 190, p.Y + 26)
			end)
			if not ok then panel.Position = UDim2.new(0.5, -115, 0.5, -125) end
			panel.Visible = true
			panel.Size = UDim2.new(0, 230, 0, 0)
			tween(panel, { Size = UDim2.new(0, 230, 0, 250) }, TI.EXPAND)
		else
			tween(panel, { Size = UDim2.new(0, 230, 0, 0) }, TI.SLIDE)
			task.delay(0.2, function() if not opened and panel then panel.Visible = false end end)
		end
	end

	swatch.MouseButton1Click:Connect(function() openPanel() end)
	swatch.MouseButton2Click:Connect(function()
		local hex = string.format("#%02X%02X%02X",
			math.floor(value.R * 255 + 0.5), math.floor(value.G * 255 + 0.5), math.floor(value.B * 255 + 0.5))
		if setClipboard(hex) then NEMESIS.Notify({ title = "Copied", content = hex, duration = 2 }) end
	end)

	function control.Set(c, a)
		value = c
		h, s, v = c:ToHSV()
		if a ~= nil then alpha = a end
		swatch.BackgroundColor3 = c
		if panel then syncUI() end
		commit()
	end
	function control.Get() return value end
	function control.GetAlpha() return alpha end

	if opts.flag then NEMESIS.Flags[opts.flag] = value end
	return control
end

----------------------------------------------------------------------
-- Window
----------------------------------------------------------------------
function NEMESIS.Window(opts)
	opts = opts or {}
	local accent = opts.accent or THEME.Accent
	ensureRoot()

	local scale = computeScale()
	local W = opts.width or (IS_MOBILE and 520 or 660)
	local H = opts.height or (IS_MOBILE and 360 or 440)
	local TOPBAR_H = 46
	local SIDEBAR_W = IS_MOBILE and 130 or 150

	local root = Create("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, W, 0, H),
		BackgroundColor3 = THEME.Background,
		ClipsDescendants = true,
		Parent = screenGui,
	}, {
		Create("UIScale", { Scale = scale }),
		corner(14),
		stroke(THEME.Stroke, 1.5, 0),
	})

	-- topbar
	local topbar = Create("Frame", {
		Size = UDim2.new(1, 0, 0, TOPBAR_H),
		BackgroundColor3 = THEME.Topbar,
		BorderSizePixel = 0,
		Parent = root,
	})
	Create("Frame", {
		Position = UDim2.new(0, 0, 1, -1),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = THEME.Stroke,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		Parent = topbar,
	})
	local titleLabel = Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 16, 0, 0),
		Size = UDim2.new(1, -140, 1, 0),
		Font = FONT_BOLD,
		Text = tostring(opts.title or "NEMESIS"),
		TextColor3 = THEME.Text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = topbar,
	})
	if opts.subtitle then
		titleLabel.Size = UDim2.new(1, -140, 1, 0)
		titleLabel.TextYAlignment = Enum.TextYAlignment.Center
		Create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 16, 0, 0),
			Size = UDim2.new(1, -140, 1, -8),
			Font = FONT,
			Text = "          " .. tostring(opts.subtitle),
			TextColor3 = THEME.SubText,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Bottom,
			Parent = topbar,
		})
	end
	makeDraggable(root, topbar)

	local function topButton(symbol, offset)
		local b = Create("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, offset, 0.5, 0),
			Size = UDim2.new(0, 28, 0, 28),
			BackgroundTransparency = 1,
			Font = FONT_BOLD,
			Text = symbol,
			TextColor3 = THEME.SubText,
			TextSize = 18,
			Parent = topbar,
		})
		b.MouseEnter:Connect(function() tween(b, { TextColor3 = accent }, TI.HOVER) end)
		b.MouseLeave:Connect(function() tween(b, { TextColor3 = THEME.SubText }, TI.HOVER) end)
		return b
	end

	local closeBtn = topButton("\u{2715}", -10)
	local minBtn = topButton("\u{2013}", -42)
	local searchBtn = topButton("\u{1F50D}", -74)

	-- search field (expands from the topbar)
	local searchBox = Create("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -100, 0.5, 0),
		Size = UDim2.new(0, 0, 0, 28),
		BackgroundColor3 = THEME.Element,
		Font = FONT,
		PlaceholderText = "Search...",
		Text = "",
		TextColor3 = THEME.Text,
		PlaceholderColor3 = THEME.SubText,
		TextSize = 13,
		Visible = false,
		ClearTextOnFocus = false,
		Parent = topbar,
	}, { corner(6), stroke(THEME.Stroke, 1, 0.3), padding(6) })

	-- body
	local body = Create("Frame", {
		Position = UDim2.new(0, 0, 0, TOPBAR_H),
		Size = UDim2.new(1, 0, 1, -TOPBAR_H),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = root,
	})
	local sidebar = Create("ScrollingFrame", {
		Size = UDim2.new(0, SIDEBAR_W, 1, 0),
		BackgroundColor3 = THEME.Sidebar,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = body,
	}, {
		padding(8),
		Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	Create("Frame", {
		Position = UDim2.new(0, SIDEBAR_W, 0, 0),
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = THEME.Stroke,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		Parent = body,
	})
	local content = Create("Frame", {
		Position = UDim2.new(0, SIDEBAR_W + 1, 0, 0),
		Size = UDim2.new(1, -(SIDEBAR_W + 1), 1, 0),
		BackgroundTransparency = 1,
		Parent = body,
	})

	-- open animation
	root.Size = UDim2.new(0, W, 0, 0)
	tween(root, { Size = UDim2.new(0, W, 0, H) }, TI.OPEN)

	local Win = {}
	local tabs = {}
	local activePage

	local function runSearch(text)
		if not activePage then return end
		text = string.lower(text or "")
		for _, d in ipairs(activePage:GetDescendants()) do
			local ok, tag = pcall(function() return d:GetAttribute("NemesisSearch") end)
			if ok and tag ~= nil then
				d.Visible = (text == "") or (string.find(string.lower(tag), text, 1, true) ~= nil)
			end
		end
	end

	local searchOpen = false
	searchBtn.MouseButton1Click:Connect(function()
		searchOpen = not searchOpen
		searchBox.Visible = true
		tween(searchBox, { Size = UDim2.new(0, searchOpen and 150 or 0, 0, 28) }, TI.SLIDE)
		if not searchOpen then
			searchBox.Text = ""
			runSearch("")
			task.delay(0.2, function() if not searchOpen then searchBox.Visible = false end end)
		end
	end)
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		runSearch(searchBox.Text)
	end)

	local function showPage(page, entry)
		if activePage == page then return end
		for _, t in ipairs(tabs) do
			tween(t.button, { BackgroundColor3 = THEME.Sidebar }, TI.HOVER)
			tween(t.label, { TextColor3 = THEME.SubText }, TI.HOVER)
			if t.icon then tween(t.icon, { ImageColor3 = THEME.SubText }, TI.HOVER) end
			t.page.Visible = false
		end
		page.Visible = true
		page.Position = UDim2.new(0, 14, 0, 0)
		tween(page, { Position = UDim2.new(0, 0, 0, 0) }, TI.TAB)
		tween(entry.button, { BackgroundColor3 = THEME.Element }, TI.HOVER)
		tween(entry.label, { TextColor3 = accent }, TI.HOVER)
		if entry.icon then tween(entry.icon, { ImageColor3 = accent }, TI.HOVER) end
		activePage = page
		if searchOpen then runSearch(searchBox.Text) end
	end

	function Win.Tab(name, arg)
		local icon, columns
		if type(arg) == "table" then icon = arg.icon; columns = arg.columns else icon = arg end
		columns = (columns == 2) and 2 or 1

		local tabBtn = Create("TextButton", {
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundColor3 = THEME.Sidebar,
			AutoButtonColor = false,
			Text = "",
			Parent = sidebar,
		}, { corner(8) })
		local iconImg = Create("ImageLabel", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 8, 0.5, 0),
			Size = UDim2.new(0, 18, 0, 18),
			ImageColor3 = THEME.SubText,
			Parent = tabBtn,
		})
		local hasIcon = applyIcon(iconImg, resolveIcon(icon))
		local txt = Create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, hasIcon and 32 or 12, 0, 0),
			Size = UDim2.new(1, hasIcon and -36 or -16, 1, 0),
			Font = FONT_MED,
			Text = tostring(name or "Tab"),
			TextColor3 = THEME.SubText,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = tabBtn,
		})

		local page = Create("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = THEME.Stroke,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = false,
			Parent = content,
		}, { padding(12) })

		local leftCol, rightCol, defaultParent
		if columns == 2 then
			local holder = Create("Frame", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Parent = page,
			}, {
				Create("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, 10),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
			})
			local function col()
				return Create("Frame", {
					Size = UDim2.new(0.5, -5, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					Parent = holder,
				}, { Create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }) })
			end
			leftCol = col()
			rightCol = col()
			defaultParent = leftCol
		else
			Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })
			defaultParent = page
		end

		local entry = { button = tabBtn, page = page, label = txt, icon = hasIcon and iconImg or nil }
		table.insert(tabs, entry)
		tabBtn.MouseButton1Click:Connect(function() showPage(page, entry) end)

		local Tab = {}
		local function bindTab(elName)
			return function(a) return Elements[elName](defaultParent, accent, a) end
		end
		Tab.Button = bindTab("Button")
		Tab.Toggle = bindTab("Toggle")
		Tab.Slider = bindTab("Slider")
		Tab.Dropdown = bindTab("Dropdown")
		Tab.Input = bindTab("Input")
		Tab.Keybind = bindTab("Keybind")
		Tab.ColorPicker = bindTab("ColorPicker")
		Tab.Paragraph = bindTab("Paragraph")
		Tab.Label = function(text) return Elements.Label(defaultParent, accent, text) end
		Tab.Section = function(title) Elements.Section(defaultParent, accent, title); return Tab end

		local leftCount, rightCount = 0, 0
		function Tab.GroupBox(title, side)
			local boxParent = defaultParent
			if columns == 2 then
				if side == "left" then
					boxParent = leftCol
				elseif side == "right" then
					boxParent = rightCol
				elseif leftCount <= rightCount then
					boxParent = leftCol; leftCount = leftCount + 1
				else
					boxParent = rightCol; rightCount = rightCount + 1
				end
			end

			local box = Create("Frame", {
				BackgroundColor3 = THEME.Group,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Parent = boxParent,
			}, {
				corner(10),
				stroke(THEME.Stroke, 1, 0.2),
				padding(10),
				Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
			})
			tagSearch(box, title)
			Create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 18),
				Font = FONT_BOLD,
				Text = tostring(title or "Group"),
				TextColor3 = accent,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = box,
			})
			Create("Frame", {
				Size = UDim2.new(1, 0, 0, 1),
				BackgroundColor3 = THEME.Stroke,
				BorderSizePixel = 0,
				Parent = box,
			})

			local G = {}
			local function bindBox(elName)
				return function(a) return Elements[elName](box, accent, a) end
			end
			G.Button = bindBox("Button")
			G.Toggle = bindBox("Toggle")
			G.Slider = bindBox("Slider")
			G.Dropdown = bindBox("Dropdown")
			G.Input = bindBox("Input")
			G.Keybind = bindBox("Keybind")
			G.ColorPicker = bindBox("ColorPicker")
			G.Paragraph = bindBox("Paragraph")
			G.Label = function(text) return Elements.Label(box, accent, text) end
			G.Section = function(t) Elements.Section(box, accent, t); return G end
			return G
		end

		if #tabs == 1 then showPage(page, entry) end
		return Tab
	end

	-- minimize / restore (smooth)
	local minimized = false
	local function setMinimized(m)
		minimized = m
		if m then
			tween(root, { Size = UDim2.new(0, W, 0, TOPBAR_H) }, TI.OPEN)
			minBtn.Text = "\u{002B}"
		else
			tween(root, { Size = UDim2.new(0, W, 0, H) }, TI.OPEN)
			minBtn.Text = "\u{2013}"
		end
	end
	function Win.Toggle(force)
		setMinimized((force == nil) and (not minimized) or (not force))
	end
	minBtn.MouseButton1Click:Connect(function() setMinimized(not minimized) end)

	function Win.Destroy()
		tween(root, { Size = UDim2.new(0, W, 0, 0) }, TI.SLIDE)
		task.delay(0.25, function() if root then root:Destroy() end end)
	end
	closeBtn.MouseButton1Click:Connect(function() Win.Destroy() end)

	-- toggle-key (desktop) + floating reopen button (mobile)
	local hidden = false
	local function setHidden(hide)
		hidden = hide
		if hide then
			tween(root, { Size = UDim2.new(0, W, 0, 0) }, TI.SLIDE)
			task.delay(0.2, function() if hidden then root.Visible = false end end)
		else
			root.Visible = true
			minimized = false
			tween(root, { Size = UDim2.new(0, W, 0, H) }, TI.OPEN)
		end
	end
	local toggleKey = opts.toggleKey or Enum.KeyCode.RightShift
	UserInputService.InputBegan:Connect(function(input, gpe)
		if not gpe and input.KeyCode == toggleKey then setHidden(not hidden) end
	end)

	if IS_MOBILE then
		local fab = Create("TextButton", {
			Name = "Reopen",
			Position = UDim2.new(0, 12, 0, 12),
			Size = UDim2.new(0, 44, 0, 44),
			BackgroundColor3 = accent,
			Font = FONT_BOLD,
			Text = "N",
			TextColor3 = THEME.Text,
			TextSize = 20,
			Parent = screenGui,
		}, { corner(22), stroke(THEME.Stroke, 1, 0.4) })
		makeDraggable(fab, fab)
		fab.MouseButton1Click:Connect(function() setHidden(not hidden) end)
	end

	Win.Instance = root
	Win.Notify = NEMESIS.Notify
	return Win
end

----------------------------------------------------------------------
return NEMESIS
