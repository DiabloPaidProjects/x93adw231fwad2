# NEMESIS

A **mobile-first** Roblox/Luau UI library for script executors — rounded rectangular window, tab sidebar with icons, group boxes, optional two-column layout, a full color picker, smooth tweened transitions, and broad executor compatibility. Inspired by Rayfield, Obsidian, neverlose-ui, and syde.

```lua
local NEMESIS = loadstring(game:HttpGet("https://raw.githubusercontent.com/DiabloPaidProjects/NEMESIS/main/source.lua"))()
```

## Features

- 🪟 **Structured layout** — rounded rectangular window, left tab sidebar (icon + text, active highlight), right content panel.
- 🧱 **Group boxes & two columns** — `Tab.GroupBox(title)` containers and an optional `columns = 2` layout.
- 🎨 **Full color picker** — pop-out panel: saturation/value square, hue slider, alpha slider, editable HEX + percentage.
- 🖼️ **Icons** — Lucide names (`icon = "home"`) or raw asset IDs.
- 🔎 **Search** — topbar search filters the active tab.
- 📱 **Mobile / touch support** — responsive scaling, touch-drag, and a floating reopen button on phones.
- ✨ **Rayfield-style elements & animations** — 45px rows with a subtle stroke, sliding recoloring toggles, sliders with a draggable handle, smooth dropdown expand + arrow spin, button click-flash, focus-tinted inputs/keybinds — all on Rayfield's Exponential easing (open/minimize/tab-switch/color-panel/notify included).
- 🔌 **Executor-friendly** — `gethui` → `protect_gui` → `CoreGui` → `PlayerGui` parenting fallback; every executor global is feature-detected and `pcall`-guarded, so it degrades instead of erroring.
- 🧩 **Components** — Section, Button, Toggle, Slider, Dropdown (single + multi), Input, Keybind, ColorPicker, Label, Paragraph + notifications.

## Quick start

```lua
local NEMESIS = loadstring(game:HttpGet("https://raw.githubusercontent.com/DiabloPaidProjects/NEMESIS/main/source.lua"))()

local Win = NEMESIS.Window({ title = "NEMESIS", subtitle = "by you" })
local Tab = Win.Tab("Main")

Tab.Section("Combat")
Tab.Toggle({ text = "Auto Farm", default = false, flag = "autofarm", callback = function(on)
    print("Auto farm:", on)
end })

NEMESIS.Notify({ title = "Loaded", content = "NEMESIS ready", duration = 4 })
```

See [`example.lua`](example.lua) for a full demo of every component.

## API

The API is **dot-style** — call methods with `.` (not `:`). Option tables use lowercase keys; the callback key is always `callback`.

### `NEMESIS.Window(options)` → `Win`

| Option | Type | Default | Description |
|---|---|---|---|
| `title` | string | `"NEMESIS"` | Window title. |
| `subtitle` | string? | — | Small text under the title. |
| `accent` | Color3? | purple | Accent color for highlights, toggles, sliders. |
| `toggleKey` | KeyCode? | `RightShift` | Key to hide/show the window. |
| `width` | number? | `660` | Window width (px, before scaling). |
| `height` | number? | `440` | Window height (px, before scaling). |

Returns `Win` with: `Win.Tab(name, iconOrOpts?)`, `Win.Toggle(force?)` (minimize/restore), `Win.Destroy()`, `Win.Notify(...)`, `Win.Instance`. The topbar has search, minimize, and close buttons; the whole menu drags by its title bar.

### `Win.Tab(name, iconOrOpts?)` → `Tab`

Adds a sidebar tab and returns a `Tab`. The second argument is either an **icon** (Lucide name / asset ID) or an **options table**:

```lua
Win.Tab("Main", "home")                       -- lucide name
Win.Tab("Config", 4483362458)                 -- asset id
Win.Tab("Visuals", { icon = "eye", columns = 2 })  -- two-column content
```

| Tab option | Type | Description |
|---|---|---|
| `icon` | string \| number | Lucide name (`"home"`), `"rbxassetid://N"`, or numeric asset ID. Unknown names fall back to text-only. |
| `columns` | `1` \| `2` | `2` = side-by-side group-box columns. Default `1`. |

The first tab created is shown by default.

### `Tab.GroupBox(title, side?)` → `GroupBox`

A titled, bordered container. Returns an object with **the same element creators as `Tab`** (Button/Toggle/Slider/Dropdown/Input/Keybind/ColorPicker/Label/Paragraph/Section). In a `columns = 2` tab, pass `side = "left"|"right"` to force a column (otherwise boxes auto-balance).

```lua
local box = Tab.GroupBox("Combat")
box.Toggle({ text = "Aim Assist", default = false, flag = "aim" })
```

### Components

Components can be created on a `Tab` (full width / left column) **or** on a `GroupBox`. Components that hold a value accept an optional `flag` (mirrored into `NEMESIS.Flags[flag]`) and return a **control** with `.Set(value)` and `.Get()`.

```lua
Tab.Section("Combat")                  -- header / divider

Tab.Button({ text = "Execute", callback = function() end })

local t = Tab.Toggle({ text = "Toggle", default = false, flag = "f1", callback = function(v) end })
t.Set(true); print(t.Get())

Tab.Slider({ text = "Speed", min = 0, max = 100, default = 50, increment = 1, suffix = " st", flag = "f2", callback = function(v) end })

Tab.Dropdown({ text = "Mode", options = {"A","B","C"}, default = "A", flag = "f3", callback = function(v) end })
Tab.Dropdown({ text = "Multi", options = {"x","y","z"}, multi = true, default = {"x"}, flag = "f4", callback = function(list) end })

Tab.Input({ text = "Name", placeholder = "type…", default = "", clearOnFocus = false, flag = "f5", callback = function(text) end })

Tab.Keybind({ text = "Bind", default = Enum.KeyCode.E, mode = "Toggle", flag = "f6", callback = function(state) end })
-- mode: "Toggle" | "Hold" | "Always"

Tab.ColorPicker({ text = "Color", default = Color3.fromRGB(255,0,80), transparency = 0, flag = "f7", callback = function(color, alpha) end })
-- click the swatch → full panel (SV square, hue, alpha slider, editable HEX + %).
-- callback receives (color, transparency). right-click the swatch to copy hex.
-- control extras: cp.Set(color, alpha?), cp.GetAlpha()

local lbl = Tab.Label("plain text"); lbl.Set("new text")
Tab.Paragraph({ title = "Title", content = "longer body text" })
```

**Control methods** (returned by Toggle / Slider / Dropdown / Input / Keybind / ColorPicker / Label):
- `control.Set(value)` — set the value programmatically (fires the callback).
- `control.Get()` — read the current value.
- Dropdown also has `control.SetOptions({...})` and `control.Toggle(force?)`.

### `NEMESIS.Notify(options)`

```lua
NEMESIS.Notify({ title = "Title", content = "Body", duration = 4 })
```

### `NEMESIS.Flags`

Every component with a `flag` writes its current value to `NEMESIS.Flags[flag]`, so you can read all state at once:

```lua
if NEMESIS.Flags.autofarm then ... end
```

> Note: v1 keeps flags **in memory** for the session. Disk-based config saving is planned for a later version.

## Mobile

- The window auto-scales to the device viewport and uses larger touch targets on phones.
- The title bar is drag-movable with both mouse and touch.
- On touch devices a draggable floating **N** button appears to hide/show the menu (the keyboard `toggleKey` still works on desktop).
- Honors device safe-area insets (notches) where supported.

## Executor compatibility

NEMESIS targets the common executor surface and never hard-errors on a missing API:
- **GUI parent:** `gethui()` → `get_hidden_gui()` → `syn.protect_gui` + `CoreGui` → `PlayerGui`.
- **Clipboard:** `setclipboard` / `toclipboard` (color hex copy) — optional.
- No file or HTTP dependency at runtime, so it loads even on minimal executors.

## License

[MIT](LICENSE)
