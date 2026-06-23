--[[
	NEMESIS — full element showcase / test script
	Paste this into your executor. It builds EVERY component and variation
	across several tabs so you can try them and report what to improve.

	Tabs:
	  1. Main        — core elements (single column)
	  2. Inputs      — text box, keybinds (all 3 modes), dropdowns
	  3. Colors      — color pickers (opaque + transparency)
	  4. Layout      — two-column group boxes
	  5. Control     — programmatic .Set / .Get + notification tests
]]

local NEMESIS = NEMESIS or loadstring(game:HttpGet("https://raw.githubusercontent.com/DiabloPaidProjects/NEMESIS/main/source.lua"))()

local Win = NEMESIS.Window({
	title = "NEMESIS",
	subtitle = "full test bench",
	accent = Color3.fromRGB(140, 90, 255),
	toggleKey = Enum.KeyCode.RightShift,
	-- width = 700, height = 470,
})

local function notify(t, c, d)
	NEMESIS.Notify({ title = t, content = c, duration = d or 3 })
end

----------------------------------------------------------------------
-- 1) MAIN — core elements, single column
----------------------------------------------------------------------
local Main = Win.Tab("Main", { icon = "home" })

Main.Section("Buttons & Toggles")
Main.Button({ text = "Plain Button", callback = function() notify("Button", "Clicked!", 2) end })
Main.Toggle({ text = "Toggle (off by default)", default = false, flag = "t_off",
	callback = function(v) notify("Toggle", "off-default is now " .. tostring(v), 2) end })
Main.Toggle({ text = "Toggle (on by default)", default = true, flag = "t_on" })

Main.Section("Sliders")
Main.Slider({ text = "Integer 0–250", min = 0, max = 250, default = 100, increment = 1, flag = "s_int" })
Main.Slider({ text = "Percent", min = 0, max = 100, default = 50, increment = 5, suffix = "%", flag = "s_pct" })
Main.Slider({ text = "Degrees", min = 0, max = 360, default = 90, increment = 15, suffix = "\u{00B0}", flag = "s_deg" })

Main.Section("Text")
Main.Label("This is a plain Label — small muted text.")
Main.Paragraph({ title = "Paragraph", content = "A title plus a longer wrapping body of text. Good for notes and instructions inside a tab." })

----------------------------------------------------------------------
-- 2) INPUTS — textbox, keybinds, dropdowns
----------------------------------------------------------------------
local Inputs = Win.Tab("Inputs", { icon = "type" })

Inputs.Section("Text input")
Inputs.Input({ text = "Name", placeholder = "type here...", default = "", clearOnFocus = false, flag = "in_name",
	callback = function(s) notify("Input", "You typed: " .. s, 2) end })
Inputs.Input({ text = "Clears on focus", placeholder = "click me", clearOnFocus = true, flag = "in_clear" })

Inputs.Section("Keybinds (3 modes)")
Inputs.Keybind({ text = "Toggle mode (press E)", default = Enum.KeyCode.E, mode = "Toggle", flag = "kb_toggle",
	callback = function(state) notify("Keybind/Toggle", "state = " .. tostring(state), 1.5) end })
Inputs.Keybind({ text = "Hold mode (hold F)", default = Enum.KeyCode.F, mode = "Hold", flag = "kb_hold",
	callback = function(down) notify("Keybind/Hold", down and "DOWN" or "up", 1) end })
Inputs.Keybind({ text = "Always mode (press G)", default = Enum.KeyCode.G, mode = "Always", flag = "kb_always",
	callback = function() notify("Keybind/Always", "fired", 1) end })

Inputs.Section("Dropdowns")
Inputs.Dropdown({ text = "Single select", options = { "Low", "Medium", "High", "Ultra" }, default = "Medium", flag = "dd_single",
	callback = function(v) notify("Dropdown", "chose " .. tostring(v), 1.5) end })
Inputs.Dropdown({ text = "Multi select", options = { "Players", "NPCs", "Items", "Chests", "Vehicles" },
	multi = true, default = { "Players", "Items" }, flag = "dd_multi",
	callback = function(list) notify("Multi", table.concat(list, ", "), 2) end })

----------------------------------------------------------------------
-- 3) COLORS — full color picker
----------------------------------------------------------------------
local Colors = Win.Tab("Colors", { icon = "palette" })

Colors.Section("Color pickers")
Colors.ColorPicker({ text = "Solid color", default = Color3.fromRGB(255, 0, 80), transparency = 0, flag = "c_solid",
	callback = function(color, alpha) notify("Color", "rgb set (a=" .. tostring(alpha) .. ")", 1.5) end })
Colors.ColorPicker({ text = "With transparency", default = Color3.fromRGB(0, 200, 255), transparency = 0.3, flag = "c_alpha",
	callback = function(color, alpha) print("color", color, "transparency", alpha) end })
Colors.Label("Click a swatch to open the panel: drag the SV square, hue, and alpha. Edit the HEX box. Right-click a swatch to copy hex.")

----------------------------------------------------------------------
-- 4) LAYOUT — two-column group boxes
----------------------------------------------------------------------
local Layout = Win.Tab("Layout", { icon = "layout-grid", columns = 2 })

local combat = Layout.GroupBox("Combat")          -- auto -> left
combat.Toggle({ text = "Aimbot", default = false, flag = "g_aim" })
combat.Slider({ text = "FOV", min = 0, max = 180, default = 120, suffix = "\u{00B0}", flag = "g_fov" })
combat.Dropdown({ text = "Target", options = { "Closest", "Health", "Random" }, default = "Closest", flag = "g_target" })

local visuals = Layout.GroupBox("Visuals", "right")
visuals.Toggle({ text = "ESP", default = true, flag = "g_esp" })
visuals.ColorPicker({ text = "ESP Color", default = Color3.fromRGB(120, 255, 120), flag = "g_color" })
visuals.Keybind({ text = "Toggle ESP", default = Enum.KeyCode.V, mode = "Toggle", flag = "g_espkey" })

local misc = Layout.GroupBox("Misc")              -- auto -> balances to right
misc.Button({ text = "Rejoin", callback = function() notify("Misc", "Rejoin pressed", 2) end })
misc.Toggle({ text = "Anti-AFK", default = false, flag = "g_afk" })

local more = Layout.GroupBox("More")              -- auto -> left
more.Slider({ text = "Volume", min = 0, max = 100, default = 70, suffix = "%", flag = "g_vol" })
more.Input({ text = "Tag", placeholder = "name tag", flag = "g_tag" })

----------------------------------------------------------------------
-- 5) CONTROL — programmatic Set/Get + notifications
----------------------------------------------------------------------
local Control = Win.Tab("Control", { icon = "settings" })

Control.Section("Programmatic updates")
local liveToggle = Control.Toggle({ text = "Controlled toggle", default = false, flag = "ctl_toggle" })
local liveSlider = Control.Slider({ text = "Controlled slider", min = 0, max = 100, default = 0, flag = "ctl_slider" })
local liveDrop = Control.Dropdown({ text = "Controlled dropdown", options = { "A", "B", "C" }, default = "A", flag = "ctl_drop" })

Control.Button({ text = "Set toggle ON", callback = function() liveToggle.Set(true) end })
Control.Button({ text = "Set toggle OFF", callback = function() liveToggle.Set(false) end })
Control.Button({ text = "Set slider = 75", callback = function() liveSlider.Set(75) end })
Control.Button({ text = "Set dropdown = C", callback = function() liveDrop.Set("C") end })
Control.Button({ text = "Read all values", callback = function()
	notify("Get()", "toggle=" .. tostring(liveToggle.Get()) .. " slider=" .. tostring(liveSlider.Get()) .. " drop=" .. tostring(liveDrop.Get()), 4)
end })

Control.Section("Notifications & window")
Control.Button({ text = "Short notify (1.5s)", callback = function() notify("Quick", "gone fast", 1.5) end })
Control.Button({ text = "Long notify (6s)", callback = function() notify("Long", "this one lingers a while so you can read it", 6) end })
Control.Button({ text = "Minimize window", callback = function() Win.Toggle() end })

Control.Section("Flags dump")
Control.Button({ text = "Print NEMESIS.Flags", callback = function()
	for k, v in pairs(NEMESIS.Flags) do print("[flag]", k, "=", v) end
	notify("Flags", "dumped to console (F9 / executor console)", 3)
end })

----------------------------------------------------------------------
notify("NEMESIS", "Test bench loaded — try every tab and tell me what to fix!", 5)
