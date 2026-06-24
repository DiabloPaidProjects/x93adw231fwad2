--[[
	NEMESIS v2.0 — example / demo
	Reproduces the desktop CS2 cheat-menu mockup 1:1 (Combat ▸ Aimbot ▸ General).
	Run in your executor. Press RightShift to hide/show (floating "N" on mobile),
	Ctrl+K to focus search, drag the dotted bottom-right grip to resize.
]]

local NEMESIS = loadstring(game:HttpGet("https://raw.githubusercontent.com/DiabloPaidProjects/NEMESIS/main/source.lua"))()

local Win = NEMESIS.Window({
	title = "NEMESIS",
	accent = Color3.fromRGB(140, 90, 255),
	game = "NEMESIS",
	configs = { "HvH", "Legit", "Rage", "Default" },
	toggleKey = Enum.KeyCode.RightShift,
	onSave = function() NEMESIS.Notify({ title = "Config", content = "Saved current config", duration = 2 }) end,
	onConfig = function(name) NEMESIS.Notify({ title = "Config", content = "Loaded: " .. name, duration = 2 }) end,
})

--====================================================================
-- COMBAT
--====================================================================
local Combat = Win.Tab("Combat")

-- AIMBOT group ------------------------------------------------------
local Aimbot = Combat.Group("AIMBOT")
local General = Aimbot.Page("General", { icon = "crosshair", dot = true })
local Targeting = Aimbot.Page("Targeting", { icon = "target" })
local Accuracy = Aimbot.Page("Accuracy", { icon = "crosshair" })
local AimAdvanced = Aimbot.Page("Advanced", { icon = "sliders-horizontal" })
local AimFilters = Aimbot.Page("Filters", { icon = "filter" })

-- General page: GENERAL / HITBOX / SMOOTH (matches the mockup) ------
local gen = General.Section("GENERAL")
gen.Toggle({ text = "Enable", default = true, flag = "aim_enable" })
gen.Dropdown({ text = "Weapon Group", options = { "Rifles", "Pistols", "SMGs", "Snipers", "Heavy" }, default = "Rifles", flag = "aim_wg" })
gen.Dropdown({ text = "Fire Mode", options = { "On Key", "Always" }, default = "On Key", flag = "aim_fire" })
gen.Keybind({ text = "Keybind", default = "MOUSE5", mode = "Hold", flag = "aim_key" })
gen.Toggle({ text = "Enable in Air", default = false, flag = "aim_air" })

local hitbox = General.Section("HITBOX")
hitbox.Dropdown({ text = "Hitbox", options = { "Head", "Neck", "Chest", "Stomach", "Pelvis" }, default = "Head", flag = "hb_box" })
hitbox.Toggle({ text = "Multi-Point", default = true, flag = "hb_multi" })
hitbox.Slider({ text = "Point Scale", min = 0, max = 1, default = 0.65, increment = 0.01, flag = "hb_scale" })
hitbox.Dropdown({ text = "Priority", options = { "Head > Chest", "Chest > Head", "Head Only", "Closest" }, default = "Head > Chest", flag = "hb_prio" })
hitbox.Dropdown({ text = "Auto Fire", options = { "On Key", "Always", "Off" }, default = "On Key", flag = "hb_autofire" })
hitbox.Toggle({ text = "Silent Aim", default = true, flag = "hb_silent" })

local smooth = General.Section("SMOOTH")
smooth.Slider({ text = "Smooth", min = 0, max = 10, default = 3.5, increment = 0.1, flag = "sm_amount" })
smooth.Dropdown({ text = "Smooth Type", options = { "Linear", "Exponential", "Adaptive" }, default = "Exponential", flag = "sm_type" })
smooth.Slider({ text = "FOV", min = 0, max = 20, default = 2.5, increment = 0.1, flag = "sm_fov" })

-- Other AIMBOT sub-tabs (lightweight, so the sidebar fully navigates)
local tgt = Targeting.Section("TARGETING")
tgt.Dropdown({ text = "Selection", options = { "FOV", "Distance", "Health", "Damage" }, default = "FOV", flag = "tgt_sel" })
tgt.Slider({ text = "Max FOV", min = 0, max = 360, default = 180, increment = 1, suffix = "°", flag = "tgt_fov" })
tgt.Toggle({ text = "Visible Only", default = true, flag = "tgt_vis" })
tgt.Toggle({ text = "Auto Wall", default = false, flag = "tgt_wall" })

local acc = Accuracy.Section("ACCURACY")
acc.Slider({ text = "Hit Chance", min = 0, max = 100, default = 70, increment = 1, suffix = "%", flag = "acc_hc" })
acc.Slider({ text = "Min Damage", min = 0, max = 100, default = 1, increment = 1, flag = "acc_dmg" })
acc.Toggle({ text = "Auto Scope", default = true, flag = "acc_scope" })
acc.Toggle({ text = "Auto Stop", default = false, flag = "acc_stop" })

local aadv = AimAdvanced.Section("ADVANCED")
aadv.Slider({ text = "Ping Compensation", min = 0, max = 400, default = 120, increment = 5, suffix = " ms", flag = "adv_ping" })
aadv.Toggle({ text = "Prefer Body Aim", default = false, flag = "adv_body" })
aadv.Toggle({ text = "Force Safe Point", default = false, flag = "adv_safe" })

local afil = AimFilters.Section("FILTERS")
afil.Dropdown({ text = "Target Teams", options = { "Enemies", "All", "Allies" }, default = "Enemies", flag = "fil_team" })
afil.Toggle({ text = "Ignore Knife", default = true, flag = "fil_knife" })
afil.Toggle({ text = "Ignore Downed", default = false, flag = "fil_downed" })

-- TRIGGERBOT group --------------------------------------------------
local Trigger = Combat.Group("TRIGGERBOT")
local TrigGeneral = Trigger.Page("General", { icon = "grid-2x2" })
local TrigFilters = Trigger.Page("Filters", { icon = "sliders-horizontal" })
local TrigAdvanced = Trigger.Page("Advanced", { icon = "settings" })

local tg = TrigGeneral.Section("GENERAL")
tg.Toggle({ text = "Enable", default = false, flag = "tb_enable" })
tg.Dropdown({ text = "Mode", options = { "On Key", "Always" }, default = "On Key", flag = "tb_mode" })
tg.Keybind({ text = "Keybind", default = "MOUSE4", mode = "Hold", flag = "tb_key" })
tg.Slider({ text = "Delay", min = 0, max = 300, default = 30, increment = 5, suffix = " ms", flag = "tb_delay" })

local tf = TrigFilters.Section("FILTERS")
tf.Dropdown({ text = "Hitboxes", options = { "Head", "Body", "Head + Body" }, multi = false, default = "Head", flag = "tbf_hb" })
tf.Toggle({ text = "Visible Only", default = true, flag = "tbf_vis" })

local ta = TrigAdvanced.Section("ADVANCED")
ta.Slider({ text = "Hit Chance", min = 0, max = 100, default = 60, increment = 1, suffix = "%", flag = "tba_hc" })
ta.Toggle({ text = "Burst Mode", default = false, flag = "tba_burst" })

-- Standalone sidebar items -----------------------------------------
local Backtrack = Combat.Page("Backtrack", { icon = "zap" })
local bt = Backtrack.Section("BACKTRACK")
bt.Toggle({ text = "Enable", default = true, flag = "bt_enable" })
bt.Slider({ text = "Max Time", min = 0, max = 400, default = 200, increment = 10, suffix = " ms", flag = "bt_time" })
bt.ColorPicker({ text = "Tick Color", default = Color3.fromRGB(140, 90, 255), transparency = 0, flag = "bt_col" })

local AntiAim = Combat.Page("Anti-Aim", { icon = "eye" })
local aa = AntiAim.Section("ANTI-AIM")
aa.Toggle({ text = "Enable", default = false, flag = "aa_enable" })
aa.Dropdown({ text = "Yaw", options = { "Backwards", "Spin", "Jitter", "Sideways" }, default = "Backwards", flag = "aa_yaw" })
aa.Dropdown({ text = "Pitch", options = { "Down", "Up", "Zero" }, default = "Down", flag = "aa_pitch" })

local Misc = Combat.Page("Misc", { icon = "sliders-horizontal" })
local mc = Misc.Section("MOVEMENT")
mc.Toggle({ text = "Bunny Hop", default = false, flag = "mc_bhop" })
mc.Toggle({ text = "Auto Strafe", default = false, flag = "mc_strafe" })
mc.Slider({ text = "Walk Speed", min = 100, max = 400, default = 250, increment = 5, suffix = "%", flag = "mc_speed" })

--====================================================================
-- VISUALS
--====================================================================
local Visuals = Win.Tab("Visuals")
local Esp = Visuals.Group("PLAYER ESP")
local EspGeneral = Esp.Page("General", { icon = "eye" })
local EspColors = Esp.Page("Colors", { icon = "palette" })

local eg = EspGeneral.Section("BOXES")
eg.Toggle({ text = "Enabled", default = true, flag = "esp_box" })
eg.Dropdown({ text = "Box Type", options = { "2D", "Corner", "Filled" }, default = "Corner", flag = "esp_boxtype" })
eg.Toggle({ text = "Health Bar", default = true, flag = "esp_hp" })
eg.Toggle({ text = "Name", default = true, flag = "esp_name" })

local ec = EspColors.Section("COLORS")
ec.ColorPicker({ text = "Visible", default = Color3.fromRGB(120, 255, 120), transparency = 0, flag = "esp_cvis" })
ec.ColorPicker({ text = "Occluded", default = Color3.fromRGB(255, 80, 80), transparency = 0.2, flag = "esp_cocc" })

local Other = Visuals.Group("WORLD")
local WorldGen = Other.Page("General", { icon = "globe" })
local wv = WorldGen.Section("WORLD")
wv.Toggle({ text = "Full Bright", default = false, flag = "w_bright" })
wv.Slider({ text = "Night Mode", min = 0, max = 100, default = 0, increment = 1, suffix = "%", flag = "w_night" })

--====================================================================
-- PLAYER / WORLD / CONFIG (stubbed so every top tab navigates)
--====================================================================
local Player = Win.Tab("Player")
local PlayerMain = Player.Group("PLAYER").Page("Movement", { icon = "person-standing" })
local pm = PlayerMain.Section("MOVEMENT")
pm.Slider({ text = "Walk Speed", min = 16, max = 500, default = 16, increment = 1, flag = "p_speed" })
pm.Slider({ text = "Jump Power", min = 50, max = 500, default = 50, increment = 5, flag = "p_jump" })
pm.Toggle({ text = "No Clip", default = false, flag = "p_noclip" })

local World = Win.Tab("World")
local WorldMain = World.Group("WORLD").Page("Environment", { icon = "globe" })
local wm = WorldMain.Section("ENVIRONMENT")
wm.Slider({ text = "Time of Day", min = 0, max = 24, default = 14, increment = 1, suffix = "h", flag = "wo_time" })
wm.Toggle({ text = "Remove Fog", default = false, flag = "wo_fog" })

local Config = Win.Tab("Config")
local ConfigMain = Config.Page("Settings", { icon = "settings" })
local cs = ConfigMain.Section("INTERFACE")
cs.Keybind({ text = "Menu Key", default = Enum.KeyCode.RightShift, mode = "Toggle", flag = "cfg_menukey" })
cs.ColorPicker({ text = "Accent", default = Color3.fromRGB(140, 90, 255), transparency = 0, flag = "cfg_accent" })
cs.Input({ text = "Config Name", placeholder = "my-config", flag = "cfg_name" })
cs.Button({ text = "Save Config", button = "Save", callback = function()
	NEMESIS.Notify({ title = "Config", content = "Saved", duration = 2 })
end })

local about = ConfigMain.Section("ABOUT")
about.Paragraph({ title = "NEMESIS v2.0", content = "Desktop cheat-menu layout: top tabs, grouped sidebar, collapsible sections, live FPS. Right-click a color swatch to copy its hex." })

NEMESIS.Notify({ title = "NEMESIS", content = "Loaded — Combat ▸ Aimbot ▸ General", duration = 5 })
