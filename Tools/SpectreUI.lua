--[[
    SpectreUI - dark/violet Roblox UI library  (beautified build)
    Window / Sidebar tabs / Search / Sections / Toggle / Dropdown (+Multi) / Slider / Button / Label / Divider / Textbox / Keybind / ColorPicker / Paragraph / Notify / Toast / Dialog / Loading / Config

    local Library = loadstring(readfile("SpectreUI.lua"))()   -- or require(module)
    local Window  = Library:CreateWindow({ Title = "SpectreWare | Anime Astral" })
    local Tab     = Window:CreateTab({ Name = "Main", Icon = "M" })
    local Section = Tab:CreateSection({ Name = "Settings" })
    Section:CreateToggle({ Name = "Example", Default = false, Flag = "ex", Callback = function(v) end })

    Window options : Title, Logo (asset id), Width, Height, ToggleKey (Enum.KeyCode), Theme (table), OnClose
    Tab options    : Name, Icon (text glyph, asset id number / "rbxassetid://..", or an icon name like "lucide:home" / "home")
    Section options: Name, Column (1|2), Collapsible (default true), Collapsed
    Controls       : CreateToggle / CreateDropdown / CreateSlider / CreateButton / CreateLabel / CreateDivider
                     CreateTextbox / CreateKeybind / CreateColorPicker / CreateParagraph
    Every control  : Flag (stores value in Library.Flags[Flag]); returned object has :Set / :Get where it makes sense

    New API (v3)
    - Dropdown   : Multi = true  -> pick many; Default = { "a", "b" }; :Get() returns an array; Callback(array)
    - Textbox    : Name, Default, Placeholder, ClearOnFocus, Numeric, Min, Max, MaxLength, Live, EnterOnly, Callback(value)
    - Keybind    : Name, Default (Enum.KeyCode | "F"), Mode = "Press" | "Hold" | "Toggle", Callback(...), Changed(key)
                   click the button, press a key to bind (Esc = cancel, Backspace/Delete = clear)
    - ColorPicker: Name, Default (Color3), Callback(Color3)   -> :Set(Color3) / :Get()
    - Paragraph  : Title, Content   -> :Set(title, content)
    - Library:SaveConfig(name) / LoadConfig(name) / DeleteConfig(name) / ListConfigs()   (needs writefile support)
    - Library:ExportConfig() -> json string,  Library:ImportConfig(json)   (e.g. for the clipboard)
    - Library:Unload()  destroys every window and clears Flags
    - Config only stores controls that have a Flag.

    New API (v3.1) — all work on mouse and touch
    - Controls   : CreateBadge / CreateProgress / CreateSeparator / CreateKeybindToggle
                   CreateLabel now takes Color, Bold, TextSize; CreateButton takes Color / Gradient / TextColor
    - Window     : SetTitle("Brand | Sub") · GetTab(name) · SetTab(name) · SetSize(w, h) · Center() · Flash(color)
                   Tooltip(frame, "text") · Success/Warning/Error/Info(title, content, dur)
                   Notify({ Title, Content, Duration, Color, Flash })  -> click to dismiss
    - Tab        : SetBadge("3")  -> a count pill on the sidebar tab
    - Library    : Confirm({ Title, Content, Yes, No, OnYes, OnNo })   modal yes/no dialog
                   Banner({ Title, Content, Duration, Color })          top toast, works while closed
                   OnFlag(function(flag, value, prev))                  one handler for every flag change
                   AutoloadConfig(name) / SaveAuto(name)                startup load / quick snapshot
    - Every control returns a table with .Frame, so Window:Tooltip(obj.Frame, "...") works.

    Theme additions (visual build)
    - Theme.Accent2 (gradient partner), Theme.Sheen (highlight), Theme.Glow on/off, Theme.Animate shimmer
    - Rounded 12 window with a soft accent halo, gradient headers, glowing toggles/sliders, gradient active tab.

    Themes (default = Rose / sakura pink)
    - Library:CreateWindow({ Theme = "Rose" | "Violet" | "Cyber" | "Crimson" | "Matrix" })
    - Library:SetTheme("Cyber")      default for windows created afterwards
    - Theme = { Accent = Color3..., Accent2 = ... }   override single colors on top of the default palette
    - Library.Themes.MyTheme = { ...all colors... }   add your own preset

    New API (v3.2)
    - Every control (old + new) now also has:
        :SetVisible(bool) / :IsVisible()        hide or show (works with the search filter)
        :ShowIf("flag" [, value | fn(v, flags)]) / :ShowIf({ "a", "b" }, fn(flags))   conditional visibility
        :SetEnabled(bool) / :Lock() / :Unlock()  dim + block input
        :OnChange(fn(value, prev))               per-control watcher (needs Flag)
        :Reset() / :IsModified()                 back to the value it was created with
        :SetTooltip(text)  or  Tooltip = "..." in the config
        :Destroy()
      A small accent dot appears on a control whose value differs from its default.
    - Right-click (PC) or hold a finger (mobile) on a control: Reset / Copy value / Lock / What is this?
        extra items:  ContextMenu = { { Name = "x", Callback = function(obj) end } }   NoMenu = true to disable
        Library:ShowMenu(items, anchorFrame)   Library.ContextMenu = false to turn it off globally
    - Command palette  Window:OpenPalette()  /  Ctrl+K   (Library.PaletteKey)
        fuzzy search over every control in every tab; toggles flip in place, buttons run, others jump + highlight
        quick set:  "walkspeed = 50"  "esp = on"
        Library:AddCommand({ Name, Desc, Keywords, Callback })     Window:Goto(obj | "flag" | "name")
    - Undo / redo of setting changes (Ctrl+Z / Ctrl+Y)
        Library:Undo() / Redo() / CanUndo() / CanRedo() / GetHistory() / ClearHistory() / Library.History.Max
        Library:Transaction("label", fn)   many changes = one undo step (config loads already are)
    - Library:ResetAll() / GetModified() / Tab:ResetAll() / Section:ResetAll()
    - Library:Snapshot("a") / Restore("a") / Diff("a", "b"|nil)   in-memory profiles, no writefile needed
    - Library:Watch("flag", fn(value, prev))
    - New controls
        CreateSegmented({ Name, Options, Default, Flag, Callback })
        CreateRangeSlider({ Name, Min, Max, Increment, MinGap, Default = { lo, hi }, Flag, Callback(lo, hi) })
        CreateTagInput({ Name, Default, Max, Lower, Flag, Callback(list) })     :Add / :Remove / :Has
        CreateHoldButton({ Name, Duration, Color, Callback })                   hold to confirm
        CreateGraph({ Name, Points, Height, Min, Max, Suffix })                 :Push(n) / :Clear()
        CreateConsole({ Name, Height, MaxLines })                               :Print / :Info / :Warn / :Error / :Clear / :Copy

    Performance / devices (v3.2.1)
    - Library:SetQuality("low" | "high" | "auto")   low power also turns off the decorative background gradients
    - PC: Up / Down + Enter in the command palette, drag the bottom-right corner to resize the window (Resizable = false to disable)
    - Mobile: bigger touch rows in the palette / chips, shorter palette list, long-press menu only on touch devices
    - Right-click hooks only on devices with a mouse; the "modified" dot is created lazily

    Performance
    - On mobile the library auto-enables low power (no shimmer, no halo rings, no open/close
      scale tween, no tab slide) so the UI stays smooth on phones.
    - Override at any time:  Library.Perf.LowPower = true / false   (nil = auto)

    Backdrop FX + smooth motion (v3.3)
    - Animated theme-matched backdrop behind the whole window (aurora wash + drifting particles):
        Rose -> "petals"   Violet -> "orbs"   Cyber -> "grid"   Crimson -> "embers"   Matrix -> "rain"
      Library:CreateWindow({ FX = "rain" })        pick a style for one window
      Library:CreateWindow({ Background = false }) turn it off
      Window:SetBackground("orbs" | false | nil)   change at runtime (nil = theme default)
      Library.Themes.MyTheme = { ..., FX = "orbs" } for custom presets
    - Lite version (fewer particles, one aurora band) in low power / mobile; Library.Perf.Backdrop = false disables it there. Paused while the window is closed (no idle cost).
    - Motion: sine easing for fades / colors, quint for size / position, eased window drag (PC),
      softer open / close / tab-switch, seamless looping tweens instead of re-chained ones.
      Library.Anim.Speed = 1.25  -> every animation 25% slower (0.8 = faster)

    Feedback UI (v3.4)  - every call returns a handle; all work on mouse + touch, PC + mobile
    - Notify  : Window:Notify({ Title, Content, Kind = "Success"|"Warning"|"Error"|"Info", Duration, Icon, Color,
                  Progress = true|false (countdown bar) | 0..1 (determinate), Key (same Key = update in place),
                  Position = "BottomRight"|"TopCenter"|..., OnClick, OnClose(reason), Closable, Merge })
                Duration = 0 / false / math.huge (or Dismiss = false) stays until dismissed. Success/Warning/Error/Info(title, content, dur) still work.
                handle: :Update{...} :SetProgress(n) :Dismiss() :IsAlive() :OnClose(fn)     Window:DismissAll()
                Hover pauses the countdown on PC; identical notifications merge into "x2"; max visible + queue; auto top-right on touch.
    - Toast   : Window:Toast("Saved") / ("Saved", "Success") / ("Saved", 3) / ("Saved", { Kind, Duration, Icon })   small pill, bottom-center
    - Banner  : Library:Banner({ Title, Content, Duration, Color })    top-center
    - Loading : local l = Window:Loading({ Title, Text, Progress })   l:Set(0.5, "text") l:SetText(t) l:Complete(t, secs) l:Fail(t, secs) l:Close()
    - Dialog  : Window:Dialog({ Title, Content, Kind, Buttons = { { Text, Value, Style = "Primary"|"Secondary"|"Danger", Callback, Close } },
                  Input = true|{ Placeholder, Default, MaxLength, Numeric }, Build = function(container, theme, handle) end, Dismissable, OnClose })
                handle: :Close(value) :Update{} :IsOpen() :GetInput() :Wait() -> value, input
                Shortcuts: Confirm({ Title, Content, Yes, No, OnYes, OnNo, Danger })  Alert(title, content)  Prompt({ Title, Placeholder, OnSubmit(text) })
    - Library:Notify / Toast / Banner / Loading / Dialog / Confirm / Alert / Prompt / DismissAll also work with no window yet.
    - Library.NotifyConfig : Position, MaxVisible, Duration, Gap, Margin, Width, Merge, PauseOnHover, Animate
    - Theme   : Library:RegisterTheme(name, tbl) / GetTheme(name?) / ListThemes() / SetStatusColors{ Success = c, ... } / GetStatusColor(kind)
                Window:SetNotifyTheme("Cyber" | tbl | nil)   own palette for that window's notifications + dialogs
    - Anim    : Library.Anim.Tween / Show(obj, { From, Distance, Time, Scale }) / Hide(obj, { To, Destroy }) / Pulse(obj) / Stop(obj)   (+ Speed)
    - Responsive : Library.Responsive.IsTouch / Viewport(win) / Breakpoint(win) -> "phone"|"tablet"|"desktop" / Width(win, max, margin) / Touch(pc, touch) / Scale(n) / OnChange(win, fn)
                   Window:OnResize(fn)
    - Util    : Library.Util.Bag / Dispose / Opt / Debounce / Throttle / Round / FormatNumber / FormatTime / Truncate / Lighten / Darken / ToHex / FromHex / Contrast / Create
    - Fixed   : cards no longer jump when one closes (slot collapses), Duration 0 no longer closes instantly, bad Duration / Title types no longer error,
                stack can no longer grow off screen, notifications sit above dialogs, modal card no longer closes when you tap inside it,
                Confirm overlay tap now counts as "No", Banners no longer overlap, every tween / connection / task is cleaned on close and on Unload.

    Theme manager (v3.5)
    - Window:SetTheme("Aurora" | { Accent = ... }, remember)   recolor the whole window LIVE (no rebuild)
    - Library:RenameTheme("Rose", "Sakura Night")  /  Window:RenameTheme("new name")  -> ok, err   (renames the preset, windows follow)
    - Library:CloneTheme("Rose", "My Pink", { Accent = Color3... })   Library:DeleteTheme(name)  (custom themes only)
    - Window:GetThemeName() / Library.ThemeName / Library:OnThemeChange(function(event, a, b) end)
    - Section:CreateThemeManager({ Name, Flag, Remember = true, Random = true, Delete = true })
                  ready UI: dropdown + rename textbox + Rename / Duplicate / Random / Delete buttons  (Random / Delete = false hides them)
    - Window:CycleTheme(dir, remember) (dir = 1 next / -1 previous)  Window:RandomTheme(remember)  Window:DeleteTheme(name?)  -> ok, err
    - Names, custom themes and the chosen theme are saved to <ConfigFolder>/themes.json (writefile) and restored next launch
      Library:SaveThemes() / LoadThemes()
    - New presets: Aurora, Dracula, Nord, TokyoNight, Mocha, Synthwave, Jade, Gold, Lavender, Candy, Peach
      (plus Midnight, Ocean, Sunset, Mono from before)

    Ready-made tabs (v3.7)
    - Window:CreateThemeTab({ Name, Icon, Text = {..}, Manager = {..}, Maker = false, Effects = false, Keys = false })      -> tab, parts
    - Window:CreateSettingsTab({ Name, Icon, Text = {..}, Sections = { Theme, Hotkeys, Config, Window, History = false } })      -> tab, parts
    - Window:CreateDefaultTabs({ Theme = {..} | false, Settings = {..} | false })                                       -> themeTab, settingsTab
      Text = { key = "..." } renames / translates any label (see README_SpectreUI_Tabs.md for the key list)

    Icons (v3.8)  - icon packs from github.com/Footagesus/Icons (Main-v2)
    - Packs: lucide (default) / solar / craft / geist / sfsymbols / gravity.   "lucide:home"  "solar:settings-bold"  or just "home" (default pack)
    - Works in: Window:CreateTab({ Icon = "lucide:swords" }), Notify / Toast / Dialog / Confirm ({ Icon = "lucide:bell" }),
      and the default Theme / Settings tabs (lucide:palette / lucide:settings).
    - Loaded lazily on first use (6 packs = a few seconds once). If it fails or the name does not exist, the old text glyph is used.
    - Library.IconLib.Default = "solar"      default pack for names without "pack:"
      Library.IconLib.Url = "..."            another copy of Main-v2.lua
      Library:PreloadIcons()                 download now, e.g. before creating the window
      Library:SetIconModule(mod)             reuse a module you already loaded
      Library:AddIcons("mine", { home = 123456 })  ->  Icon = "mine:home"
      Library:ResolveIcon(name) / MakeIcon(desc, color)   raw helpers (ImageLabel with rect offsets)
    - Section / Button:  Tab:CreateSection({ Name = "ESP", Icon = "lucide:eye" })   Section:CreateButton({ Name = "Save", Icon = "lucide:save" })
      (a section with an Icon shows it instead of the accent dot; the button icon sits on the left)
    - Ready-made tabs have icons on every section + button. Change or remove any of them:
        Window:CreateSettingsTab({ Icons = { Theme = "solar:palette-bold", Save = "lucide:download", Delete = false } })
        keys: ThemeSection UISection ConfigSection WindowSection HistorySection RandomButton Palette Save Load Delete SaveAuto Copy Import Center Unload Undo Redo Modified Snapshot Restore
        theme tab keys: ThemeSection MakerSection FxSection CreateButton
    - Built-in glyphs still work: "check" "cross" "spinner" "!" "i" "M" ...

    v2 notes
    - Window is draggable by its header (mouse + touch), clamped to the screen, position kept on resize / rotation.
    - The floating "open" button (shown while the window is closed) is draggable too; a tap still opens the window.
    - Everything is event-driven: no RenderStepped / Heartbeat loops, only TweenService + input events.
      (the header shimmer is a self-chaining tween, not a per-frame loop)
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Library = { Flags = {}, Objects = {}, Windows = {}, ConfigFolder = "SpectreUI/configs", Version = "3.8", _flagCbs = {} }
Library.__index = Library

-- Theme presets. Pick one per window:  Library:CreateWindow({ Theme = "Cyber" })
-- or change the default for every new window:  Library:SetTheme("Crimson")
-- or override single colors:  Library:CreateWindow({ Theme = { Accent = Color3.fromRGB(...) } })
-- Optional extra keys (derived automatically when missing): Top, Deep, Lift, Wash, Knob
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

Library.Themes = {
	Rose = {   -- sakura pink (default)
		Background = rgb(13, 9, 12),   Panel = rgb(20, 14, 18),   Card = rgb(26, 19, 24),   Control = rgb(37, 27, 34),
		Border = rgb(74, 46, 62),      Accent = rgb(244, 114, 182), Accent2 = rgb(251, 146, 190), AccentSoft = rgb(70, 28, 52),
		Sheen = rgb(255, 208, 226),    Text = rgb(253, 242, 248), SubText = rgb(196, 152, 174),
		FX = "petals",
	},
	Violet = {
		Background = rgb(8, 7, 14),    Panel = rgb(14, 12, 23),   Card = rgb(18, 16, 29),   Control = rgb(24, 21, 38),
		Border = rgb(52, 42, 94),      Accent = rgb(139, 92, 246), Accent2 = rgb(217, 70, 239), AccentSoft = rgb(40, 26, 78),
		Sheen = rgb(190, 170, 255),    Text = rgb(240, 238, 250), SubText = rgb(152, 148, 180),
		FX = "orbs",
	},
	Cyber = {
		Background = rgb(6, 10, 16),   Panel = rgb(10, 17, 27),   Card = rgb(13, 22, 35),   Control = rgb(19, 31, 48),
		Border = rgb(30, 78, 110),     Accent = rgb(34, 211, 238), Accent2 = rgb(59, 130, 246), AccentSoft = rgb(10, 46, 70),
		Sheen = rgb(165, 243, 252),    Text = rgb(236, 248, 255), SubText = rgb(140, 170, 190),
		FX = "grid",
	},
	Crimson = {
		Background = rgb(12, 6, 7),    Panel = rgb(20, 10, 12),   Card = rgb(26, 13, 16),   Control = rgb(36, 20, 24),
		Border = rgb(100, 36, 44),     Accent = rgb(239, 68, 68), Accent2 = rgb(249, 115, 22), AccentSoft = rgb(70, 20, 24),
		Sheen = rgb(254, 202, 202),    Text = rgb(254, 242, 242), SubText = rgb(190, 150, 150),
		FX = "embers",
	},
	Matrix = {
		Background = rgb(5, 10, 7),    Panel = rgb(9, 18, 12),    Card = rgb(12, 24, 16),   Control = rgb(18, 34, 24),
		Border = rgb(30, 92, 56),      Accent = rgb(34, 197, 94), Accent2 = rgb(132, 204, 22), AccentSoft = rgb(12, 52, 30),
		Sheen = rgb(187, 247, 208),    Text = rgb(240, 253, 244), SubText = rgb(140, 180, 155),
		FX = "rain",
	},
	Midnight = {   -- deep navy + indigo glass
		Background = rgb(7, 9, 18),    Panel = rgb(12, 15, 28),   Card = rgb(16, 20, 36),   Control = rgb(24, 29, 50),
		Border = rgb(44, 54, 96),      Accent = rgb(99, 102, 241), Accent2 = rgb(56, 189, 248), AccentSoft = rgb(30, 34, 84),
		Sheen = rgb(199, 210, 254),    Text = rgb(238, 242, 255), SubText = rgb(148, 158, 196),
		FX = "orbs",
	},
	Ocean = {
		Background = rgb(5, 12, 16),   Panel = rgb(9, 20, 26),   Card = rgb(12, 27, 34),   Control = rgb(18, 40, 50),
		Border = rgb(28, 74, 90),      Accent = rgb(45, 212, 191), Accent2 = rgb(56, 189, 248), AccentSoft = rgb(10, 52, 60),
		Sheen = rgb(153, 246, 228),    Text = rgb(236, 254, 255), SubText = rgb(136, 178, 188),
		FX = "grid",
	},
	Sunset = {
		Background = rgb(15, 9, 8),    Panel = rgb(24, 14, 12),   Card = rgb(31, 19, 16),   Control = rgb(44, 28, 23),
		Border = rgb(94, 54, 40),      Accent = rgb(251, 146, 60), Accent2 = rgb(244, 63, 94), AccentSoft = rgb(78, 36, 24),
		Sheen = rgb(254, 215, 170),    Text = rgb(255, 247, 237), SubText = rgb(196, 160, 140),
		FX = "embers",
	},
	Mono = {   -- clean graphite, minimal
		Background = rgb(10, 10, 12),  Panel = rgb(17, 17, 20),   Card = rgb(22, 22, 26),   Control = rgb(32, 32, 38),
		Border = rgb(58, 58, 68),      Accent = rgb(228, 228, 237), Accent2 = rgb(161, 161, 178), AccentSoft = rgb(44, 44, 54),
		Sheen = rgb(255, 255, 255),    Text = rgb(244, 244, 248), SubText = rgb(150, 150, 164),
		FX = "orbs",
	},
	-- ===== new presets (v3.5) =====
	Aurora = {   -- mint -> violet northern lights
		Background = rgb(7, 11, 18),   Panel = rgb(12, 18, 28),   Card = rgb(16, 24, 37),   Control = rgb(24, 34, 52),
		Border = rgb(42, 66, 98),      Accent = rgb(110, 231, 183), Accent2 = rgb(167, 139, 250), AccentSoft = rgb(22, 56, 70),
		Sheen = rgb(209, 250, 229),    Text = rgb(240, 253, 250), SubText = rgb(146, 174, 188),
		FX = "orbs",
	},
	Dracula = {   -- purple + hot pink
		Background = rgb(20, 21, 30),  Panel = rgb(27, 28, 40),   Card = rgb(33, 34, 49),   Control = rgb(44, 46, 66),
		Border = rgb(70, 73, 104),     Accent = rgb(189, 147, 249), Accent2 = rgb(255, 121, 198), AccentSoft = rgb(58, 44, 94),
		Sheen = rgb(233, 220, 255),    Text = rgb(248, 248, 242), SubText = rgb(160, 164, 198),
		FX = "orbs",
	},
	Nord = {   -- frosty blue-grey
		Background = rgb(20, 24, 32),  Panel = rgb(27, 32, 43),   Card = rgb(33, 39, 52),   Control = rgb(44, 52, 68),
		Border = rgb(67, 80, 102),     Accent = rgb(136, 192, 208), Accent2 = rgb(129, 161, 193), AccentSoft = rgb(34, 54, 68),
		Sheen = rgb(216, 236, 244),    Text = rgb(236, 239, 244), SubText = rgb(150, 166, 188),
		FX = "grid",
	},
	TokyoNight = {   -- indigo neon city
		Background = rgb(15, 16, 26),  Panel = rgb(22, 24, 38),   Card = rgb(26, 28, 46),   Control = rgb(36, 40, 64),
		Border = rgb(60, 68, 102),     Accent = rgb(122, 162, 247), Accent2 = rgb(187, 154, 247), AccentSoft = rgb(36, 46, 86),
		Sheen = rgb(196, 213, 255),    Text = rgb(214, 222, 255), SubText = rgb(132, 142, 184),
		FX = "orbs",
	},
	Mocha = {   -- warm pastel on espresso dark
		Background = rgb(17, 17, 27),  Panel = rgb(24, 24, 37),   Card = rgb(30, 30, 46),   Control = rgb(42, 43, 62),
		Border = rgb(69, 71, 92),      Accent = rgb(203, 166, 247), Accent2 = rgb(245, 194, 231), AccentSoft = rgb(56, 44, 86),
		Sheen = rgb(240, 220, 255),    Text = rgb(205, 214, 244), SubText = rgb(147, 153, 180),
		FX = "petals",
	},
	Synthwave = {   -- neon pink + electric cyan
		Background = rgb(13, 7, 22),   Panel = rgb(22, 11, 36),   Card = rgb(29, 15, 47),   Control = rgb(42, 22, 68),
		Border = rgb(98, 40, 124),     Accent = rgb(255, 64, 200), Accent2 = rgb(0, 229, 255), AccentSoft = rgb(76, 18, 88),
		Sheen = rgb(255, 190, 240),    Text = rgb(255, 240, 252), SubText = rgb(188, 150, 202),
		FX = "grid",
	},
	Jade = {   -- emerald with a golden glint
		Background = rgb(6, 13, 11),   Panel = rgb(10, 22, 18),   Card = rgb(13, 29, 24),   Control = rgb(20, 43, 35),
		Border = rgb(34, 86, 68),      Accent = rgb(74, 222, 168), Accent2 = rgb(253, 224, 71), AccentSoft = rgb(14, 56, 44),
		Sheen = rgb(209, 250, 232),    Text = rgb(240, 253, 247), SubText = rgb(140, 182, 164),
		FX = "orbs",
	},
	Gold = {   -- royal black & gold
		Background = rgb(12, 10, 7),   Panel = rgb(21, 17, 11),   Card = rgb(28, 23, 15),   Control = rgb(41, 34, 22),
		Border = rgb(98, 80, 36),      Accent = rgb(250, 204, 21), Accent2 = rgb(245, 158, 11), AccentSoft = rgb(76, 58, 16),
		Sheen = rgb(254, 240, 170),    Text = rgb(254, 252, 232), SubText = rgb(196, 182, 142),
		FX = "embers",
	},
	Lavender = {   -- soft dreamy purple
		Background = rgb(12, 10, 18),  Panel = rgb(19, 16, 28),   Card = rgb(25, 21, 38),   Control = rgb(36, 31, 56),
		Border = rgb(76, 64, 114),     Accent = rgb(196, 167, 255), Accent2 = rgb(244, 170, 255), AccentSoft = rgb(54, 42, 90),
		Sheen = rgb(232, 220, 255),    Text = rgb(248, 244, 255), SubText = rgb(172, 162, 202),
		FX = "petals",
	},
	Candy = {   -- cotton-candy sky blue + pink
		Background = rgb(11, 12, 20),  Panel = rgb(17, 19, 31),   Card = rgb(22, 24, 40),   Control = rgb(32, 35, 58),
		Border = rgb(66, 74, 114),     Accent = rgb(125, 211, 252), Accent2 = rgb(249, 168, 212), AccentSoft = rgb(34, 50, 86),
		Sheen = rgb(224, 242, 254),    Text = rgb(244, 248, 255), SubText = rgb(158, 168, 198),
		FX = "petals",
	},
	Peach = {   -- coral peach glow
		Background = rgb(16, 10, 11),  Panel = rgb(26, 16, 17),   Card = rgb(33, 21, 22),   Control = rgb(47, 31, 32),
		Border = rgb(102, 62, 58),     Accent = rgb(253, 164, 175), Accent2 = rgb(253, 186, 116), AccentSoft = rgb(80, 36, 40),
		Sheen = rgb(255, 228, 220),    Text = rgb(255, 245, 242), SubText = rgb(204, 166, 160),
		FX = "petals",
	},
}

local THEME_COMMON = { Font = Enum.Font.GothamMedium, FontBold = Enum.Font.GothamBold, Glow = true, Animate = true }

local function buildTheme(src)
	local T = table.clone(THEME_COMMON)
	for k, v in pairs(Library.Themes.Rose) do T[k] = v end
	for k, v in pairs(src or {}) do T[k] = v end
	if src and src.FX == nil then T.FX = "orbs" end   -- custom presets without FX get the neutral one
	return T
end

-- fills the derived colors the library uses for gradients / hover states
local function deriveTheme(T)
	local black, white = Color3.new(0, 0, 0), Color3.new(1, 1, 1)
	T.Top  = T.Top  or T.Panel:Lerp(T.Accent, 0.06)
	T.Deep = T.Deep or T.Background:Lerp(black, 0.4)
	T.Lift = T.Lift or T.Control:Lerp(T.Accent, 0.12)
	T.Wash = T.Wash or T.AccentSoft:Lerp(T.Accent2, 0.15)
	T.Knob = T.Knob or white:Lerp(T.Accent, 0.04)
	return T
end

Library.Theme = buildTheme(Library.Themes.Rose)

-- Library:SetTheme("Cyber" | { Accent = ... })  -> default for windows created afterwards
function Library:SetTheme(t)
	if type(t) == "string" then t = self.Themes[t] end
	if type(t) ~= "table" then return false end
	self.Theme = buildTheme(t)
	return true
end

local Window, Tab, Section = {}, {}, {}
Window.__index, Tab.__index, Section.__index = Window, Tab, Section

local AY = Enum.AutomaticSize.Y
local AX = Enum.AutomaticSize.X
local ANONE = Enum.AutomaticSize.None
local LEFT = Enum.TextXAlignment.Left
local HEADER_H, SEARCH_H, FOOT_H = 48, 40, 54

local QUINT, QUAD, BACK = Enum.EasingStyle.Quint, Enum.EasingStyle.Quad, Enum.EasingStyle.Back
local SINE, LINEAR = Enum.EasingStyle.Sine, Enum.EasingStyle.Linear
local OUT, IN = Enum.EasingDirection.Out, Enum.EasingDirection.In

------------------------------------------------------------------ performance
-- Mobile killers are: (1) tweens that run forever, (2) large rounded strokes that
-- re-rasterize every frame while the window moves, (3) glow frames redrawn on drag.
-- On a phone (or when forced) the library takes the cheap path: no shimmer, no halo
-- rings, no drag-time stroke animation. Everything still renders, just static.
local IS_MOBILE = UserInputService.TouchEnabled

-- Library.Anim.Speed: global duration multiplier (1.25 = 25% slower / softer, 0.8 = snappier)
Library.Anim = { Speed = 1 }

Library.Perf = {
	-- nil = auto (mobile -> low power), true/false = force. Change at runtime:
	--   Library.Perf.LowPower = false   -- force the pretty path anywhere
	LowPower = nil,
}

local function lowPower()
	local p = Library.Perf.LowPower
	if p ~= nil then return p end
	return IS_MOBILE
end

------------------------------------------------------------------ helpers
local function new(class, props, children)
	local o = Instance.new(class)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then parent = v else o[k] = v end
	end
	for _, c in ipairs(children or {}) do c.Parent = o end
	if parent then o.Parent = parent end
	return o
end

-- a new tween on a property cancels the previous one on that property, so no bookkeeping is needed
-- Default easing is picked from what is being animated: geometry (size / position / rotation / scale)
-- gets the fast-out Quint curve, everything else (colors, transparency) gets Sine, which has no
-- visible "snap" at the start. Durations are floored at 80 ms so press feedback never pops, and
-- scaled by Library.Anim.Speed.
local GEOM = { Size = true, Position = true, Rotation = true, Scale = true, Offset = true, CanvasPosition = true }
local function tween(o, t, props, style, dir)
	if not style then
		style = SINE
		for k in pairs(props) do
			if GEOM[k] then style = QUINT break end
		end
	end
	t = math.max(t * (Library.Anim.Speed or 1), 0.08)
	local tw = TweenService:Create(o, TweenInfo.new(t, style, dir or OUT), props)
	tw:Play()
	return tw
end

local function corner(r) return new("UICorner", { CornerRadius = UDim.new(0, r) }) end

------------------------------------------------------------------ icon packs (Footagesus/Icons Main-v2)
-- Lazy: the pack module (lucide / solar / craft / geist / sfsymbols / gravity) is only downloaded the
-- first time a named icon is used. If the download fails everything falls back to the old text glyphs.
Library.IconLib = { Url = "https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua", Default = "lucide" }

local function iconModule()
	if Library._iconMod ~= nil then return Library._iconMod or nil end
	Library._iconMod = false
	local ok, mod = pcall(function()
		return loadstring(game:HttpGet(Library.IconLib.Url))()
	end)
	if ok and type(mod) == "table" and mod.Icon then
		Library._iconMod = mod
		if mod.SetIconsType then pcall(mod.SetIconsType, Library.IconLib.Default or "lucide") end
	else
		warn("[SpectreUI] icon library could not be loaded: " .. tostring(mod))
	end
	return Library._iconMod or nil
end

-- use a module you already loaded yourself:  Library:SetIconModule(loadstring(game:HttpGet(url))())
function Library:SetIconModule(mod)
	Library._iconMod = type(mod) == "table" and mod or false
	Library._iconCache = {}
end

-- download the pack now (otherwise it happens on first use)
function Library:PreloadIcons() return iconModule() ~= nil end

-- Library:AddIcons("mypack", { home = 123456, ... })  -> then Icon = "mypack:home"
function Library:AddIcons(pack, data)
	local mod = iconModule()
	if mod and mod.AddIcons then Library._iconCache = {} return pcall(mod.AddIcons, pack, data) end
	return false
end

-- "lucide:home", "solar:settings-bold", "home" (default pack) ...
function Library:IsIconName(icon)
	if type(icon) ~= "string" or icon:find("rbxasset", 1, true) then return false end
	if icon:find(":", 1, true) then return true end
	return #icon >= 3 and icon:match("^[%l%d][%l%d%-_%.]+$") ~= nil
end

-- -> { Image, Size, Offset, Parts = { {Image,Size,Offset}, ... } } or nil
function Library:ResolveIcon(name)
	if not Library:IsIconName(name) then return nil end
	Library._iconCache = Library._iconCache or {}
	local c = Library._iconCache[name]
	if c ~= nil then return c or nil end
	local res = false
	local mod = iconModule()
	if mod then
		local ok, r = pcall(mod.Icon, name, nil, true)
		if ok and type(r) == "table" and type(r[1]) == "string" and type(r[2]) == "table" then
			local d = r[2]
			res = { Image = r[1], Size = d.ImageRectSize or Vector2.new(0, 0), Offset = d.ImageRectPosition or Vector2.new(0, 0) }
			if type(d.Parts) == "table" then
				local pack = name:match("^(.-):")
				res.Parts = {}
				for _, p in ipairs(d.Parts) do
					local ok2, pr = pcall(mod.Icon, p, pack, true)
					if ok2 and type(pr) == "table" and type(pr[1]) == "string" and type(pr[2]) == "table" then
						res.Parts[#res.Parts + 1] = { Image = pr[1], Size = pr[2].ImageRectSize or Vector2.new(0, 0), Offset = pr[2].ImageRectPosition or Vector2.new(0, 0) }
					end
				end
			end
		else
			warn("[SpectreUI] icon not found: " .. tostring(name))
		end
	end
	Library._iconCache[name] = res
	return res or nil
end

-- ImageLabel (centered, fills its parent) for a resolved icon; multi-part (duotone) icons get child layers
function Library:MakeIcon(desc, color)
	local img = new("ImageLabel", {
		Name = "IconImg", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1, ImageColor3 = color, ScaleType = Enum.ScaleType.Fit,
		Image = desc.Image, ImageRectSize = desc.Size, ImageRectOffset = desc.Offset,
	})
	if desc.Parts then
		for _, p in ipairs(desc.Parts) do
			new("ImageLabel", {
				Name = "Part", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ImageColor3 = color,
				Image = p.Image, ImageRectSize = p.Size, ImageRectOffset = p.Offset, Parent = img,
			})
		end
	end
	return img
end

local function stroke(color, thickness, transparency)
	return new("UIStroke", {
		Color = color, Thickness = thickness or 1, Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

-- gradient helper: gradient(seq, rotation) or gradient(c1, c2, rotation)
local function gradient(a, b, rot)
	local seq
	if typeof(a) == "ColorSequence" then
		seq, rot = a, b or 0
	else
		seq = ColorSequence.new(a, b)
		rot = rot or 0
	end
	return new("UIGradient", { Color = seq, Rotation = rot })
end

local function cseq(...)
	local pts = {}
	for _, p in ipairs({ ... }) do table.insert(pts, ColorSequenceKeypoint.new(p[1], p[2])) end
	return ColorSequence.new(pts)
end

-- decorative background wash: same as gradient(), but disabled in low power (flat fill = cheaper to draw)
local function wash(seq, rot)
	local g = gradient(seq, rot)
	if lowPower() then g.Enabled = false end
	return g
end

-- fade a gradient out at the ends (used for the sheen sweeps)
local function fadeSeq(peak)
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, peak or 0),
		NumberSequenceKeypoint.new(1, 1),
	})
end

local function padding(l, t, r, b)
	return new("UIPadding", {
		PaddingLeft = UDim.new(0, l), PaddingTop = UDim.new(0, t),
		PaddingRight = UDim.new(0, r), PaddingBottom = UDim.new(0, b),
	})
end

local function list(gap, props)
	local p = { Padding = UDim.new(0, gap), SortOrder = Enum.SortOrder.LayoutOrder }
	for k, v in pairs(props or {}) do p[k] = v end
	return new("UIListLayout", p)
end

local function safe(cb, ...)
	if not cb then return end
	local ok, err = pcall(cb, ...)
	if not ok then warn("[SpectreUI] callback error: " .. tostring(err)) end
end

local function isPress(i)
	return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end

local function v2(p) return Vector2.new(p.X, p.Y) end

local function rowH() return UserInputService.TouchEnabled and 36 or 30 end

-- hover effects only make sense when the last input was NOT a touch
local function usingTouch()
	return UserInputService:GetLastInputType() == Enum.UserInputType.Touch
end

-- run fn once when this specific input (finger / mouse button) ends or is cancelled
local function onEnd(input, fn)
	local c
	c = input.Changed:Connect(function()
		local s = input.UserInputState
		if s == Enum.UserInputState.End or s == Enum.UserInputState.Cancel then
			c:Disconnect()
			fn()
		end
	end)
	return c
end

-- press / release tracking that works for mouse and touch, even if the finger slides off the button
local function bindPress(btn, down, up)
	btn.InputBegan:Connect(function(i)
		if not isPress(i) then return end
		down(i)
		onEnd(i, function() up(i) end)
	end)
end

-- hover (PC only) + press (mouse & touch) feedback. Returns the UIScale used for the press squish.
local function feedback(btn, target, prop, base, hover, press, noScale)
	local sc = (not noScale) and new("UIScale", { Parent = btn }) or nil
	local hovering, pressed = false, false
	local function refresh()
		tween(target, pressed and 0.06 or 0.16, { [prop] = pressed and press or (hovering and hover or base) })
		if sc then tween(sc, pressed and 0.07 or 0.2, { Scale = pressed and 0.97 or 1 }) end
	end
	btn.MouseEnter:Connect(function()
		if usingTouch() then return end
		hovering = true
		refresh()
	end)
	btn.MouseLeave:Connect(function()
		hovering = false
		refresh()
	end)
	bindPress(btn, function()
		pressed = true
		refresh()
	end, function()
		pressed = false
		if usingTouch() then hovering = false end
		refresh()
	end)
	return sc
end

-- brighten a UIStroke on hover/press (for the gradient controls whose fill can't be tweened)
local function strokeFeedback(btn, s, base, hover)
	local hovering = false
	btn.MouseEnter:Connect(function()
		if usingTouch() then return end
		hovering = true
		tween(s, 0.16, { Transparency = hover })
	end)
	btn.MouseLeave:Connect(function()
		hovering = false
		tween(s, 0.18, { Transparency = base })
	end)
	bindPress(btn, function()
		tween(s, 0.06, { Transparency = math.max(0, hover - 0.15) })
	end, function()
		tween(s, 0.18, { Transparency = hovering and hover or base })
	end)
end

local function snap(v, min, max, inc)
	v = min + math.floor((v - min) / inc + 0.5) * inc
	v = math.clamp(v, min, max)
	return math.floor(v * 1e5 + 0.5) / 1e5
end

-- expanding tap ripple. One tween, self-destructs, so it costs a frame for ~0.5s
-- and nothing at all while idle. Skipped in low power.
local function ripple(btn, pos)
	if lowPower() then return end
	local ap, sz = btn.AbsolutePosition, btn.AbsoluteSize
	local base = math.max(sz.X, sz.Y)
	local r = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(pos.X - ap.X, pos.Y - ap.Y),
		Size = UDim2.fromOffset(base * 0.5, base * 0.5),
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.85,
		BorderSizePixel = 0, ZIndex = 0, Parent = btn,
	}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
	tween(r, 0.55, { Size = UDim2.fromOffset(base * 2.6, base * 2.6), BackgroundTransparency = 1 }, QUAD, OUT)
	task.delay(0.55, function() r:Destroy() end)
end

-- ripple only on a real tap: MouseButton1Click does not fire when the finger
-- turned into a scroll, so a scroll gesture leaves no ripple behind.
-- `press` is the state table returned by dragSafePress (nil if not used).
local function clickRipple(btn, press)
	local pos
	btn.InputBegan:Connect(function(i)
		if isPress(i) then pos = i.Position end
	end)
	btn.MouseButton1Click:Connect(function()
		if press and press.moved then return end
		if pos then ripple(btn, pos) end
	end)
end

-- press feedback for a control inside a scrollable list.
-- Shows the pressed state on touch-down, but if the finger turns into a scroll /
-- drag (moved past `thr` px) it cancels and reverts — so no pressed background is
-- left stuck on a tab while the list scrolls under the finger.
-- Returns a state table { moved = bool } that the click handler must consult.
-- NOTE: state lives in a Lua table, never on the Instance (Roblox rejects
-- assigning unknown properties to Instances).
local function dragSafePress(btn, down, up, thr)
	thr = thr or 10
	local state = { moved = false }
	btn.InputBegan:Connect(function(i)
		if not isPress(i) then return end
		local start = v2(i.Position)
		local cancelled = false
		state.moved = false
		down(i)
		local mc
		if i.UserInputType == Enum.UserInputType.Touch then
			mc = UserInputService.InputChanged:Connect(function(m)
				if m ~= i or cancelled then return end
				if (v2(m.Position) - start).Magnitude > thr then
					cancelled = true
					state.moved = true -- remember: this was a scroll, not a tap
					if mc then mc:Disconnect() mc = nil end
					up(true) -- revert the visual, report it was a drag
				end
			end)
		end
		onEnd(i, function()
			if mc then mc:Disconnect() mc = nil end
			if not cancelled then up(false) end
		end)
	end)
	return state
end

-- keep an element (centered by `c`, half-size `half`) fully inside the viewport `vp`
local function clampCenter(vp, half, c)
	local m = 6
	local loX, hiX = half.X + m, vp.X - half.X - m
	local loY, hiY = half.Y + m, vp.Y - half.Y - m
	local x = (loX > hiX) and vp.X / 2 or math.clamp(c.X, loX, hiX)
	local y = (loY > hiY) and vp.Y / 2 or math.clamp(c.Y, loY, hiY)
	return Vector2.new(x, y)
end

-- self-chaining sheen sweep across a frame (no per-frame loop).
-- Skipped entirely in low-power: a perpetual tween keeps the renderer awake and
-- burns battery / frame time on phones for a cosmetic detail.
-- One repeating tween (no Completed -> re-create chain, so no hitch at the loop point),
-- registered in `reg` so the window can pause it while closed.
local function sheen(f, dur, tint, reg)
	if lowPower() then f.Visible = false return end
	f.BackgroundColor3 = tint or Color3.new(1, 1, 1)
	f.Position = UDim2.new(-0.25, 0, 0, 0)
	local tw = TweenService:Create(f, TweenInfo.new(dur, LINEAR, OUT, -1, false, 1.2), { Position = UDim2.new(1.25, 0, 0, 0) })
	tw:Play()
	if reg then table.insert(reg, tw) end
	return tw
end

--[[
    Generic drag handler (mouse + touch).
    - `target` must use AnchorPoint (0.5, 0.5); it is moved with an offset-based Position.
    - Tracks the exact input that started the drag, so a second finger / other input can't hijack or stick it.
    - Ends on input End/Cancel, window focus loss, or state.Stop().
    state fields: Dragging, Moved, Center, Rel (position as fraction of the screen), Threshold, OnStart, OnEnd
]]
local function makeDraggable(gui, handle, target, state)
	local moveC, endC, focusC

	-- Eased follow (PC / high quality only): the window glides toward the pointer instead of
	-- snapping to each mouse event, which hides the jitter of 60 Hz input on 144 Hz displays.
	-- The Heartbeat connection only exists while a drag (+ ~0.25 s of settling) is happening.
	local followC, shown, lastPos
	local function stopFollow()
		if followC then followC:Disconnect() followC = nil end
	end
	local function follow()
		if followC then return end
		-- RenderStepped (not Heartbeat): position is applied right before the frame is drawn,
		-- so the window never lags one frame behind the cursor
		followC = RunService.RenderStepped:Connect(function(dt)
			dt = math.min(dt, 1 / 20) -- a single long frame must not make the window jump
			if not target.Parent or not state.Center or (lastPos and target.Position ~= lastPos) then
				stopFollow() -- destroyed, or something else (Center / _Fit) moved it: let go
				return
			end
			shown = shown:Lerp(state.Center, 1 - math.exp(-dt * 24))
			if (shown - state.Center).Magnitude < 0.25 then
				shown = state.Center
				if not state.Dragging then stopFollow() end
			end
			-- whole pixels only: fractional offsets make the frame / text shimmer while moving
			lastPos = UDim2.fromOffset(math.round(shown.X), math.round(shown.Y))
			target.Position = lastPos
		end)
	end

	local function stop()
		if moveC then moveC:Disconnect() moveC = nil end
		if endC then endC:Disconnect() endC = nil end
		if focusC then focusC:Disconnect() focusC = nil end
		if state.Dragging then
			state.Dragging = false
			local vp = gui.AbsoluteSize
			if state.Center and vp.X > 0 and vp.Y > 0 then
				state.Rel = Vector2.new(state.Center.X / vp.X, state.Center.Y / vp.Y)
			end
			if state.OnEnd then state.OnEnd() end
		end
	end
	state.Stop = stop

	-- glide the target to `c` (center, px) with the same eased follow used while dragging,
	-- so a release-snap never fights the follow loop with a second tween
	state.Glide = function(c)
		local vp = gui.AbsoluteSize
		if not shown or not followC then
			shown = target.AbsolutePosition + target.AbsoluteSize / 2
			lastPos = nil
		end
		state.Center = c
		if vp.X > 0 and vp.Y > 0 then state.Rel = Vector2.new(c.X / vp.X, c.Y / vp.Y) end
		follow()
	end

	handle.InputBegan:Connect(function(i)
		if not isPress(i) then return end
		stop()
		state.Dragging, state.Moved = true, false
		if state.OnStart then state.OnStart() end

		local touch = i.UserInputType == Enum.UserInputType.Touch
		local startPt = v2(i.Position)
		local startC = target.AbsolutePosition + target.AbsoluteSize / 2
		local vpSize, halfSize = gui.AbsoluteSize, target.AbsoluteSize / 2 -- cached for the whole drag
		local thr = state.Threshold or 0
		stopFollow()
		shown, lastPos = startC, nil

		moveC = UserInputService.InputChanged:Connect(function(m)
			if touch then
				if m ~= i then return end
			elseif m.UserInputType ~= Enum.UserInputType.MouseMovement then
				return
			end
			local d = v2(m.Position) - startPt
			if not state.Moved then
				if d.Magnitude <= thr then return end
				state.Moved = true
			end
			local c = clampCenter(vpSize, halfSize, startC + d)
			if c ~= state.Center then
				state.Center = c
				if (touch or lowPower()) and not state.Smooth then
					target.Position = UDim2.fromOffset(c.X, c.Y)
				else
					follow()
				end
			end
		end)
		endC = onEnd(i, stop)
		focusC = UserInputService.WindowFocusReleased:Connect(stop)
	end)
end


--[[
    Resize handle. Dragging `handle` grows / shrinks the window; mx / my choose the axes that follow
    the pointer (1 = follows, 0 = locked). The window's top-left corner stays where it is.
    Size is kept between Cfg.MinWidth / MinHeight (default 700 x 280, so both columns always stay visible) and the screen edge.
    Tracks the exact input that started it, same as makeDraggable.
]]
local function makeResizable(win, handle, mx, my)
	local moveC, endC, focusC
	local function stop()
		if moveC then moveC:Disconnect() moveC = nil end
		if endC then endC:Disconnect() endC = nil end
		if focusC then focusC:Disconnect() focusC = nil end
		if win._resizing then
			win._resizing = false
			local fx = win._resizeFx
			if fx and fx.End then fx.End() end
			local sz = win.Main.AbsoluteSize
			safe(win.Cfg.OnResize, math.floor(sz.X + 0.5), math.floor(sz.Y + 0.5))
		end
	end
	handle.InputBegan:Connect(function(i)
		if not isPress(i) then return end
		stop()
		win:CloseDropdowns()
		win._drag.Stop()
		win._resizing = true
		local fx = win._resizeFx
		if fx and fx.Start then fx.Start() end

		local touch = i.UserInputType == Enum.UserInputType.Touch
		local startPt = v2(i.Position)
		local startSz = win.Main.AbsoluteSize
		local tl = win.Main.AbsolutePosition
		if win.Maximized then win:_SetMaxFlag(false) end

		moveC = UserInputService.InputChanged:Connect(function(m)
			if touch then
				if m ~= i then return end
			elseif m.UserInputType ~= Enum.UserInputType.MouseMovement then
				return
			end
			local vp = win.Gui.AbsoluteSize
			local d = v2(m.Position) - startPt
			local minW = math.min(win.Cfg.MinWidth or 700, vp.X - 16)
			local minH = math.min(win.Cfg.MinHeight or 280, vp.Y - 16)
			local w = math.clamp(startSz.X + d.X * mx, minW, math.max(minW, vp.X - 8 - tl.X))
			local h = math.clamp(startSz.Y + d.Y * my, minH, math.max(minH, vp.Y - 8 - tl.Y))
			win.Cfg.Width, win.Cfg.Height = math.floor(w + 0.5), math.floor(h + 0.5)
			local c = tl + Vector2.new(w, h) / 2
			win._drag.Rel = Vector2.new(c.X / vp.X, c.Y / vp.Y)
			win._drag.Center = c
			win:_Fit()
		end)
		endC = onEnd(i, stop)
		focusC = UserInputService.WindowFocusReleased:Connect(stop)
	end)
	return stop
end


------------------------------------------------------------------ animated backdrop
-- A theme-colored aurora wash plus a few drifting particles, drawn on one clipped layer that
-- sits UNDER the header / sidebar / cards (ZIndex 0), so the glass-like panels let it show through.
-- Cost model: ~25 looping tweens, no per-frame Lua. They are paused while the window is closed
-- and the whole thing is skipped in low power.
local function rnd(a, b) return a + math.random() * (b - a) end
local function nsk(t, v) return NumberSequenceKeypoint.new(t, v) end

local function loopTween(fx, o, dur, props, style, reverse)
	local tw = TweenService:Create(o, TweenInfo.new(dur, style or LINEAR, Enum.EasingDirection.InOut, -1, reverse or false), props)
	tw:Play()
	table.insert(fx.Tweens, tw)
	return tw
end

-- travel from `a` to `b` forever, but start at a random point of the first trip so
-- particles are spread out from the very first frame instead of spawning in a clump
local function travel(fx, o, a, b, dur)
	local f = math.random()
	o.Position = a:Lerp(b, f)
	local first = TweenService:Create(o, TweenInfo.new(math.max(dur * (1 - f), 0.05), LINEAR), { Position = b })
	table.insert(fx.Tweens, first)
	first:Play()
	first.Completed:Connect(function(state)
		if state ~= Enum.PlaybackState.Completed or not o.Parent then return end
		o.Position = a
		loopTween(fx, o, dur, { Position = b })
	end)
end

local function dot(layer, size, color, transp, round)
	return new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(size, round and size or math.max(2, size * 0.62)),
		BackgroundColor3 = color, BackgroundTransparency = transp, BorderSizePixel = 0, Parent = layer,
	}, { new("UICorner", { CornerRadius = UDim.new(round and 0.5 or 0.45, 0) }) })
end

local FX_KINDS = {}

-- lite mode (phones): same look, ~1/3 of the particles and a single aurora band
local function cnt(fx, n) return fx.Lite and math.max(3, n // 3) or n end

-- sakura petals: tumbling, drifting down and sideways
FX_KINDS.petals = function(fx, layer, T)
	for i = 1, cnt(fx, 12) do
		local o = dot(layer, math.random(8, 13), (i % 3 == 0) and T.Sheen or T.Accent2, rnd(0.25, 0.5), false)
		o.Rotation = math.random(0, 360)
		local x = rnd(0.05, 0.95)
		local x2 = math.clamp(x + rnd(-0.14, 0.14), 0.03, 0.97)
		travel(fx, o, UDim2.fromScale(x, -0.06), UDim2.fromScale(x2, 1.06), rnd(12, 19))
		loopTween(fx, o, rnd(3.5, 6.5), { Rotation = o.Rotation + (math.random() < 0.5 and 360 or -360) })
	end
end

-- soft orbs: slow rise with a gentle twinkle
FX_KINDS.orbs = function(fx, layer, T)
	local cols = { T.Accent, T.Accent2, T.Sheen }
	for i = 1, cnt(fx, 14) do
		local o = dot(layer, math.random(4, 8), cols[(i % 3) + 1], rnd(0.3, 0.5), true)
		local x = rnd(0.05, 0.95)
		travel(fx, o, UDim2.fromScale(x, 1.06), UDim2.fromScale(math.clamp(x + rnd(-0.06, 0.06), 0.03, 0.97), -0.06), rnd(15, 26))
		loopTween(fx, o, rnd(1.8, 3.6), { BackgroundTransparency = rnd(0.75, 0.88) }, SINE, true)
	end
end

-- embers: quick, warm, flickering
FX_KINDS.embers = function(fx, layer, T)
	for i = 1, cnt(fx, 16) do
		local o = dot(layer, math.random(3, 5), (i % 4 == 0) and T.Sheen or T.Accent2, rnd(0.2, 0.4), true)
		local x = rnd(0.05, 0.95)
		travel(fx, o, UDim2.fromScale(x, 1.06), UDim2.fromScale(math.clamp(x + rnd(-0.07, 0.07), 0.03, 0.97), -0.06), rnd(6, 11))
		loopTween(fx, o, rnd(0.6, 1.4), { BackgroundTransparency = rnd(0.7, 0.85) }, SINE, true)
	end
end

-- digital rain: thin streaks that fade out at both ends
FX_KINDS.rain = function(fx, layer, T)
	for i = 1, cnt(fx, 14) do
		local h = math.random(18, 38)
		local o = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(1, h), BackgroundColor3 = (i % 4 == 0) and T.Sheen or T.Accent,
			BackgroundTransparency = rnd(0.3, 0.55), BorderSizePixel = 0, Parent = layer,
		}, { new("UIGradient", { Rotation = 90, Transparency = fadeSeq(0) }) })
		local x = rnd(0.04, 0.96)
		travel(fx, o, UDim2.fromScale(x, -0.08), UDim2.fromScale(x, 1.08), rnd(2.6, 5.2))
	end
end

-- cyber grid: faint lattice with a scan beam that sweeps down
FX_KINDS.grid = function(fx, layer, T)
	local function line(vertical, at)
		new("Frame", {
			AnchorPoint = vertical and Vector2.new(0.5, 0) or Vector2.new(0, 0.5),
			Position = vertical and UDim2.fromScale(at, 0) or UDim2.fromScale(0, at),
			Size = vertical and UDim2.new(0, 1, 1, 0) or UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = T.Accent, BackgroundTransparency = 0.94, BorderSizePixel = 0, Parent = layer,
		}, { new("UIGradient", { Rotation = vertical and 90 or 0, Transparency = NumberSequence.new({ nsk(0, 1), nsk(0.5, 0), nsk(1, 1) }) }) })
	end
	for i = 1, 7 do line(true, i / 8) end
	for i = 1, 4 do line(false, i / 5) end
	local beam = new("Frame", {
		Size = UDim2.new(1, 0, 0.24, 0), Position = UDim2.fromScale(0, -0.3), BackgroundColor3 = T.Accent,
		BackgroundTransparency = 0.8, BorderSizePixel = 0, Parent = layer,
	}, { new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ nsk(0, 1), nsk(0.85, 0.4), nsk(1, 1) }) }) })
	local tw = TweenService:Create(beam, TweenInfo.new(4.2, LINEAR, Enum.EasingDirection.Out, -1, false, 1.3), { Position = UDim2.fromScale(0, 1.05) })
	tw:Play()
	table.insert(fx.Tweens, tw)
	-- a few blinking nodes on the lattice
	for i = 1, cnt(fx, 6) do
		local o = dot(layer, 5, (i % 2 == 0) and T.Accent2 or T.Accent, 0.6, true)
		o.Position = UDim2.fromScale(math.random(1, 7) / 8, math.random(1, 4) / 5)
		loopTween(fx, o, rnd(1.2, 2.6), { BackgroundTransparency = 0.95 }, SINE, true)
	end
end

-- aurora band: ONE frame whose gradient offset slides. It carries its own UICorner, so it is
-- clipped to the window's rounded shape for free (a clipped layer alone would leave square corners).
local function aurora(fx, layer, radius, a, b, rot, peak, dur, from, to)
	local g = new("UIGradient", {
		Rotation = rot, Offset = Vector2.new(from, 0),
		Color = cseq({ 0, a }, { 0.5, b }, { 1, a }),
		Transparency = NumberSequence.new({ nsk(0, 1), nsk(0.25, 0.94), nsk(0.5, peak), nsk(0.75, 0.94), nsk(1, 1) }),
	})
	new("Frame", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = layer,
	}, { new("UICorner", { CornerRadius = UDim.new(0, radius) }), g })
	loopTween(fx, g, dur, { Offset = Vector2.new(to, 0) }, SINE, true)
end

-- Window:SetBackground("petals" | "orbs" | "embers" | "rain" | "grid" | false | nil)
-- nil -> theme default, false -> off. `quiet` is used internally at creation time.
function Window:SetBackground(kind, quiet)
	local fx = self.FX
	if not fx then return end
	if kind == nil then kind = self.Theme.FX end
	for _, tw in ipairs(fx.Tweens) do pcall(function() tw:Cancel() end) end
	table.clear(fx.Tweens)
	if fx.Layer then fx.Layer:Destroy() fx.Layer = nil end
	self.FXOn = false

	if not kind then return end
	-- phones get the lite version; Library.Perf.Backdrop = false turns it off there
	if lowPower() and Library.Perf.Backdrop == false then return end
	fx.Lite = lowPower()
	local T = self.Theme
	local layer = new("Frame", {
		Name = "FX", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
		ClipsDescendants = true, ZIndex = 0, Active = false, Parent = self.Main,
	})
	fx.Layer = layer
	self.FXOn = true

	local r = self.Radius or 12
	aurora(fx, layer, r, T.Accent, T.Accent2, 28, 0.72, rnd(9, 12), -0.55, 0.55)
	if not fx.Lite then aurora(fx, layer, r, T.Accent2, T.Accent, -42, 0.8, rnd(13, 17), 0.5, -0.5) end

	local build = FX_KINDS[kind] or FX_KINDS.orbs
	build(fx, layer, T)

	if not self.Visible then self:_FXPause() end
end

-- pause / resume every looping tween (backdrop + header sheen) so a closed window costs nothing
function Window:_FXPause()
	if not self.FX then return end
	for _, tw in ipairs(self.FX.Tweens) do
		if tw.PlaybackState == Enum.PlaybackState.Playing then tw:Pause() end
	end
	local sh = self._sheen
	if sh and sh.PlaybackState == Enum.PlaybackState.Playing then sh:Pause() end
end

function Window:_FXResume()
	if not self.FX then return end
	for _, tw in ipairs(self.FX.Tweens) do
		if tw.PlaybackState == Enum.PlaybackState.Paused then tw:Play() end
	end
	local sh = self._sheen
	if sh and sh.PlaybackState == Enum.PlaybackState.Paused then sh:Play() end
end

------------------------------------------------------------------ window
function Library:CreateWindow(cfg)
	cfg = cfg or {}
	local T = table.clone(self.Theme)
	local ov = cfg.Theme
	if type(ov) == "string" then
		ov = self.Themes[ov]
		if ov then T = buildTheme(ov) end   -- a named preset replaces the whole palette
		ov = nil
	end
	for k, v in pairs(ov or {}) do T[k] = v end
	deriveTheme(T)
	local GLOW = T.Glow ~= false
	local RADIUS = 14

	local win = setmetatable({
		Library = self, Theme = T, Cfg = cfg, Tabs = {}, Conns = {}, Visible = true,
		_drag = {}, _openDrag = { Threshold = 8 }, Maximized = false,
	}, Window)

	local title = cfg.Title or "SpectreUI"
	local brand, sub = title:match("^(.-)%s*|%s*(.+)$")
	brand = brand or title
	win.Brand, win.Sub = brand, sub

	local gui = new("ScreenGui", {
		Name = "SpectreUI", ResetOnSpawn = false, IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
	})
	local ok = pcall(function() gui.Parent = (gethui and gethui()) or CoreGui end)
	if not ok or not gui.Parent then gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end
	win.Gui = gui

	local main = new("Frame", {
		Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = T.Background, BackgroundTransparency = 0.02, BorderSizePixel = 0,
		Active = true, -- sink input so touching / clicking the window never moves the camera
		Parent = gui,
	}, {
		corner(RADIUS),
		stroke(T.Border, 1, 0.1),
		wash(cseq({ 0, T.Top }, { 1, T.Background }), 90),
	})
	win.Main = main
	win.Scale = new("UIScale", { Scale = 1, Parent = main })
	local mainStroke = main:FindFirstChildOfClass("UIStroke")
	win.Radius = RADIUS
	win.FX = { Tweens = {} }
	win:SetBackground(cfg.Background ~= false and (cfg.FX or T.FX) or false, true)

	-- soft accent halo behind the window: two rings that track the window's position / size.
	-- Skipped in low power — repositioning two large rounded strokes every drag frame
	-- is pure re-rasterization cost for a cosmetic glow.
	if GLOW and not lowPower() then
		win.Glow = {}
		for i = 1, 2 do
			local pad = 6 + (i - 1) * 9
			local ring = new("Frame", {
				Name = "Glow" .. i, AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1,
				ZIndex = 0, Parent = gui,
			}, { corner(RADIUS + 6), stroke(T.Accent, 2 + (2 - i), 0.88 + (i - 1) * 0.05) })
			win.Glow[i] = { frame = ring, pad = pad }
		end
		local function sync()
			for _, g in ipairs(win.Glow) do
				g.frame.Position = main.Position
				g.frame.Size = main.Size + UDim2.fromOffset(g.pad, g.pad)
			end
		end
		main:GetPropertyChangedSignal("Position"):Connect(sync)
		main:GetPropertyChangedSignal("Size"):Connect(sync)
		sync()
	end

	-- cheap "fade": a window-colored veil on top of the content, only visible while animating
	win.Veil = new("Frame", {
		Name = "Veil", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Background, BackgroundTransparency = 1,
		BorderSizePixel = 0, ZIndex = 50, Visible = false, Parent = main,
	}, { corner(RADIUS) })

	---------------------------------------------------------- header
	local header = new("Frame", {
		Name = "Header", Size = UDim2.new(1, 0, 0, HEADER_H), BackgroundTransparency = 1, Parent = main,
	})
	-- gradient accent line under the header
	local hline = new("Frame", {
		Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.15, BorderSizePixel = 0, Parent = header,
	}, { gradient(cseq({ 0, T.Accent }, { 0.5, T.Accent2 }, { 1, T.Border }), 0) })
	-- moving sheen along that line (soft highlight that sweeps, faded at both ends)
	local shimmer = new("Frame", {
		Size = UDim2.new(0.22, 0, 0, 1), Position = UDim2.new(-0.25, 0, 0, 0), BackgroundColor3 = T.Sheen,
		BackgroundTransparency = 0, BorderSizePixel = 0, Parent = hline,
	}, { new("UIGradient", { Transparency = fadeSeq(0) }) })
	if T.Animate ~= false then win._sheen = sheen(shimmer, 3.2, T.Sheen) end

	-- header cluster is bounded and clipped so a long brand / subtitle can never
	-- slide under the close button (that was a real overlap on narrow screens)
	local closeW = UserInputService.TouchEnabled and 40 or 34
	local canResize = cfg.Resizable ~= false
	local nBtns = canResize and 3 or 2
	local btnArea = closeW * nBtns + 4 * (nBtns - 1) -- close + hide (+ maximize) buttons
	local left = new("Frame", {
		Size = UDim2.new(1, -(btnArea + 16), 1, 0), BackgroundTransparency = 1, ClipsDescendants = true, Parent = header,
	}, {
		list(8, { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center }),
		padding(14, 0, 0, 0),
	})
	win.Left = left
	if cfg.Logo then
		new("ImageLabel", {
			LayoutOrder = 1, Size = UDim2.fromOffset(26, 26), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit,
			Image = type(cfg.Logo) == "number" and ("rbxassetid://" .. cfg.Logo) or cfg.Logo, Parent = left,
		})
	else
		new("TextLabel", {
			LayoutOrder = 1, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AX, BackgroundTransparency = 1,
			Text = brand:sub(1, 2), Font = Enum.Font.GothamBlack, TextSize = 20, TextColor3 = Color3.new(1, 1, 1), Parent = left,
		}, { gradient(T.Accent, T.Accent2, 0) })
	end
	win.BrandLabel = new("TextLabel", {
		LayoutOrder = 2, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AX, BackgroundTransparency = 1,
		Text = brand, Font = T.FontBold, TextSize = 16, TextColor3 = T.Text, Parent = left,
	})
	if sub then
		win.SubSep = new("Frame", {
			LayoutOrder = 3, Size = UDim2.fromOffset(1, 18), BackgroundColor3 = T.Border, BorderSizePixel = 0, Parent = left,
		})
		win.SubLabel = new("TextLabel", {
			LayoutOrder = 4, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AX, BackgroundTransparency = 1,
			Text = sub, Font = T.Font, TextSize = 14, TextColor3 = T.SubText, Parent = left,
		})
	end

	local close = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(closeW, closeW),
		BackgroundColor3 = T.Control, BackgroundTransparency = 1, Text = "×", Font = T.FontBold, TextSize = 28, TextColor3 = T.SubText,
		AutoButtonColor = false, Parent = header,
	}, { corner(8) })
	local closeScale = new("UIScale", { Parent = close })
	close.MouseEnter:Connect(function()
		if not usingTouch() then
			tween(close, 0.14, { TextColor3 = Color3.fromRGB(255, 120, 120), BackgroundTransparency = 0.4 })
		end
	end)
	close.MouseLeave:Connect(function()
		tween(close, 0.14, { TextColor3 = T.SubText, BackgroundTransparency = 1 })
	end)
	bindPress(close, function()
		tween(closeScale, 0.07, { Scale = 0.88 })
		tween(close, 0.07, { TextColor3 = Color3.fromRGB(255, 120, 120) })
	end, function()
		tween(closeScale, 0.2, { Scale = 1 })
		tween(close, 0.16, { TextColor3 = T.SubText, BackgroundTransparency = 1 })
	end)
	-- X = delete: really destroys the window (use the "–" button next to it to just hide it)
	local confirmOpen = false
	local function deleteNow()
		safe(cfg.OnClose)
		task.defer(function()
			if not win._destroyed then win:Destroy() end
		end)
	end
	close.MouseButton1Click:Connect(function()
		if confirmOpen or win._destroyed then return end
		confirmOpen = true
		local h = win:Confirm({
			Title = cfg.ConfirmTitle or "Delete UI",
			Content = cfg.ConfirmText or "Are you sure you want to delete this UI? This cannot be undone.",
			Kind = "Warning", Danger = true,
			Yes = cfg.ConfirmYes or "Confirm", No = cfg.ConfirmNo or "Cancel",
			OnYes = deleteNow,
			OnClose = function() confirmOpen = false end,
		})
		if not h then -- dialog system unavailable: don't leave the button dead
			confirmOpen = false
			deleteNow()
		end
	end)

	-- hide button ("–"): old close behaviour, hides the window and leaves the floating open button
	do
		local hideB = new("TextButton", {
			Name = "Hide", AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -(8 + (closeW + 4) * (canResize and 2 or 1)), 0.5, 0),
			Size = UDim2.fromOffset(closeW, closeW), BackgroundColor3 = T.Control, BackgroundTransparency = 1,
			Text = "", AutoButtonColor = false, Parent = header,
		}, { corner(8) })
		local hideScale = new("UIScale", { Parent = hideB })
		local bar = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(12, 2),
			BackgroundColor3 = T.SubText, BorderSizePixel = 0, Parent = hideB,
		}, { corner(1) })
		hideB.MouseEnter:Connect(function()
			if not usingTouch() then
				tween(bar, 0.14, { BackgroundColor3 = T.Accent })
				tween(hideB, 0.14, { BackgroundTransparency = 0.4 })
			end
		end)
		hideB.MouseLeave:Connect(function()
			tween(bar, 0.14, { BackgroundColor3 = T.SubText })
			tween(hideB, 0.14, { BackgroundTransparency = 1 })
		end)
		bindPress(hideB, function()
			tween(hideScale, 0.07, { Scale = 0.88 })
		end, function()
			tween(hideScale, 0.2, { Scale = 1 })
			tween(bar, 0.16, { BackgroundColor3 = T.SubText })
			tween(hideB, 0.16, { BackgroundTransparency = 1 })
		end)
		hideB.MouseButton1Click:Connect(function() win:SetVisible(false) end)
	end

	-- maximize / restore button (next to close)
	if canResize then
		local mxb = new("TextButton", {
			Name = "Maximize", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -(8 + closeW + 4), 0.5, 0),
			Size = UDim2.fromOffset(closeW, closeW), BackgroundColor3 = T.Control, BackgroundTransparency = 1,
			Text = "", AutoButtonColor = false, Parent = header,
		}, { corner(8) })
		local mxScale = new("UIScale", { Parent = mxb })
		local function sq(size)
			return new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(size, size),
				BackgroundTransparency = 1, Parent = mxb,
			}, { stroke(T.SubText, 1.6, 0), corner(2) })
		end
		local front, back = sq(12), sq(10)
		back.Visible = false
		local function tint(c)
			for _, f in ipairs({ front, back }) do f:FindFirstChildOfClass("UIStroke").Color = c end
		end
		win._setMaxIcon = function(v)
			back.Visible = v
			front.Size = UDim2.fromOffset(v and 10 or 12, v and 10 or 12)
			front.Position = UDim2.new(0.5, v and -2 or 0, 0.5, v and 2 or 0)
			back.Position = UDim2.new(0.5, 2, 0.5, -2)
		end
		mxb.MouseEnter:Connect(function()
			if not usingTouch() then
				tint(T.Accent)
				tween(mxb, 0.14, { BackgroundTransparency = 0.4 })
			end
		end)
		mxb.MouseLeave:Connect(function()
			tint(T.SubText)
			tween(mxb, 0.16, { BackgroundTransparency = 1 })
		end)
		bindPress(mxb, function()
			tween(mxScale, 0.07, { Scale = 0.88 })
		end, function()
			tween(mxScale, 0.2, { Scale = 1 })
			if usingTouch() then tint(T.SubText); tween(mxb, 0.16, { BackgroundTransparency = 1 }) end
		end)
		mxb.MouseButton1Click:Connect(function() win:SetMaximized(not win.Maximized) end)
	end

	-- drag handle: covers the header EXCEPT the buttons, so pressing a control never starts a drag
	local dragZone = new("Frame", {
		Name = "DragZone", Size = UDim2.new(1, -(btnArea + 14), 1, 0), BackgroundTransparency = 1,
		Active = true, ZIndex = 5, Parent = header,
	})
	-- double-click / double-tap the title bar = maximize / restore
	if canResize then
		local lastTap = 0
		dragZone.InputBegan:Connect(function(i)
			if not isPress(i) then return end
			local now = os.clock()
			if now - lastTap < 0.35 then
				lastTap = 0
				win:SetMaximized(not win.Maximized)
			else
				lastTap = now
			end
		end)
	end
	win._drag.OnStart = function()
		win:CloseDropdowns()
		-- ~25 looping tweens redraw the window every frame; freeze them while it is being moved
		win:_FXPause()
		-- animating the window's outer stroke forces a re-raster of the whole
		-- rounded border every frame; skip it on low power
		if not lowPower() then tween(mainStroke, 0.15, { Color = T.Accent, Transparency = 0.35 }) end
	end
	win._drag.OnEnd = function()
		if win.Visible then win:_FXResume() end
		if not lowPower() then tween(mainStroke, 0.25, { Color = T.Border, Transparency = 0.1 }) end
	end
	makeDraggable(gui, dragZone, main, win._drag)

	---------------------------------------------------------- body / sidebar
	local body = new("Frame", {
		Position = UDim2.fromOffset(0, HEADER_H), Size = UDim2.new(1, 0, 1, -HEADER_H),
		BackgroundTransparency = 1, Parent = main,
	})
	local sidebar = new("Frame", { Size = UDim2.new(0, 164, 1, 0), BackgroundTransparency = 1, Parent = body })
	new("Frame", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = T.Border, BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = sidebar,
	})
	win.Sidebar = sidebar
	win.TabList = new("ScrollingFrame", {
		Size = UDim2.new(1, -1, 1, -FOOT_H), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = AY, ScrollingDirection = Enum.ScrollingDirection.Y,
		ElasticBehavior = Enum.ElasticBehavior.WhenScrollable, Parent = sidebar,
	}, { list(4), padding(10, 12, 10, 8) })

	local footer = new("Frame", {
		Position = UDim2.new(0, 0, 1, -FOOT_H), Size = UDim2.new(1, -1, 0, FOOT_H), BackgroundTransparency = 1, Parent = sidebar,
	}, { padding(16, 0, 8, 0) })
	new("Frame", {
		Position = UDim2.new(0, -6, 0, 0), Size = UDim2.new(1, -4, 0, 1), BackgroundColor3 = T.Border,
		BackgroundTransparency = 0.6, BorderSizePixel = 0, Parent = footer,
	})
	win.FooterBrand = new("TextLabel", {
		Position = UDim2.fromOffset(0, 10), Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = brand,
		Font = T.FontBold, TextSize = 15, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = footer,
	}, { gradient(T.Accent, T.Accent2, 0) })
	if sub then
		win.FooterSub = new("TextLabel", {
			Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = sub,
			Font = T.Font, TextSize = 12, TextColor3 = T.SubText, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = footer,
		})
	end
	win.Footer = footer

	---------------------------------------------------------- content / search
	local content = new("Frame", {
		Position = UDim2.fromOffset(164, 0), Size = UDim2.new(1, -164, 1, 0), BackgroundTransparency = 1, Parent = body,
	})
	win.Content = content
	local searchBar = new("Frame", {
		Position = UDim2.fromOffset(12, 12), Size = UDim2.new(1, -24, 0, SEARCH_H), BackgroundColor3 = T.Control,
		BackgroundTransparency = 0.35, BorderSizePixel = 0, Parent = content,
	}, { corner(12), stroke(T.Border, 1, 0.45) })
	local searchStroke = searchBar:FindFirstChildOfClass("UIStroke")
	-- magnifier drawn from frames (no asset needed)
	local mag = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1, Parent = searchBar,
	})
	new("Frame", {
		Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1, Parent = mag,
	}, { corner(5), stroke(T.Accent, 1.6, 0.15) })
	new("Frame", {
		Position = UDim2.fromOffset(8, 10), Size = UDim2.fromOffset(6, 2), Rotation = 45, BackgroundColor3 = T.Accent,
		BorderSizePixel = 0, Parent = mag,
	})
	win.SearchBox = new("TextBox", {
		Position = UDim2.fromOffset(38, 0), Size = UDim2.new(1, -48, 1, 0), BackgroundTransparency = 1, Text = "",
		PlaceholderText = "Search...", PlaceholderColor3 = T.SubText, TextColor3 = T.Text, Font = T.Font, TextSize = 14,
		TextXAlignment = LEFT, ClearTextOnFocus = false, Parent = searchBar,
	})
	-- keyboard hint chip (PC only), hidden while typing
	if not UserInputService.TouchEnabled then
		local chip = new("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(44, 20),
			BackgroundColor3 = T.Panel, BackgroundTransparency = 0.2, Text = "Ctrl K", Font = T.FontBold, TextSize = 11,
			TextColor3 = T.SubText, Parent = searchBar,
		}, { corner(6), stroke(T.Border, 1, 0.5) })
		win.SearchBox:GetPropertyChangedSignal("Text"):Connect(function() chip.Visible = win.SearchBox.Text == "" end)
	end
	-- debounce: typing a search term fires this on every keystroke, and each pass
	-- walks every section/control and re-runs the two-column relayout — expensive
	-- on a phone. Coalesce bursts into one apply.
	win._searchQ = false
	win.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		if win._searchQ then return end
		win._searchQ = true
		task.delay(0.08, function()
			win._searchQ = false
			win:_ApplySearch()
		end)
	end)
	win.SearchBox.Focused:Connect(function()
		tween(searchStroke, 0.18, { Color = T.Accent, Transparency = 0.05 })
		tween(searchBar, 0.18, { BackgroundTransparency = 0.15 })
	end)
	win.SearchBox.FocusLost:Connect(function()
		tween(searchStroke, 0.22, { Color = T.Border, Transparency = 0.45 })
		tween(searchBar, 0.22, { BackgroundTransparency = 0.35 })
	end)

	win.Pages = new("Frame", {
		Position = UDim2.fromOffset(0, SEARCH_H + 22), Size = UDim2.new(1, 0, 1, -(SEARCH_H + 22) - 8),
		BackgroundTransparency = 1, ClipsDescendants = true, Parent = content,
	})
	-- veil used to fade a page in when switching tabs
	win.PageVeil = new("Frame", {
		Name = "PageVeil", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Background, BackgroundTransparency = 1,
		BorderSizePixel = 0, ZIndex = 20, Visible = false, Parent = win.Pages,
	})

	---------------------------------------------------------- dropdown overlay + floating open button
	win.Overlay = new("TextButton", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
		Visible = false, ZIndex = 60, Parent = gui,
	})
	win.Overlay.MouseButton1Click:Connect(function() win:CloseDropdowns() end)

	---------------------------------------------------------- resize grip (bottom-right corner ONLY)
	if canResize then
		local touch = UserInputService.TouchEnabled
		local gripSize = touch and 36 or 18
		local grip = new("TextButton", {
			Name = "ResizeGrip", AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1),
			Size = UDim2.fromOffset(gripSize, gripSize), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
			Active = true, ZIndex = 30, Parent = main,
		})
		local ticks = {}
		for _, d in ipairs({ 6, 11, 16 }) do
			ticks[#ticks + 1] = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -(d / 2 + 4), 1, -(d / 2 + 4)),
				Size = UDim2.fromOffset(d * 1.25, 2), Rotation = -45, BackgroundColor3 = T.SubText,
				BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 31, Parent = grip,
			}, { corner(1) })
		end
		local function tintTicks(c, tr)
			for _, t in ipairs(ticks) do tween(t, 0.14, { BackgroundColor3 = c, BackgroundTransparency = tr }) end
		end
		grip.MouseEnter:Connect(function() if not usingTouch() then tintTicks(T.Accent, 0) end end)
		grip.MouseLeave:Connect(function() if not win._resizing then tintTicks(T.SubText, 0.35) end end)

		makeResizable(win, grip, 1, 1)
		win._resizeFx = {
			Start = function()
				tintTicks(T.Accent, 0)
				if not lowPower() then tween(mainStroke, 0.15, { Color = T.Accent, Transparency = 0.35 }) end
			end,
			End = function()
				tintTicks(T.SubText, 0.35)
				if not lowPower() then tween(mainStroke, 0.25, { Color = T.Border, Transparency = 0.1 }) end
			end,
		}
	end

	---------------------------------------------------------- floating open button
	-- Bigger tap target on touch, edge-snapping after a drag, fades when idle, hover label on PC.
	local touchUI = UserInputService.TouchEnabled
	local BS = touchUI and 52 or 44 -- button size
	win.OpenSize = BS
	local toggleKey = cfg.ToggleKey or Enum.KeyCode.RightShift
	win.OpenBtn = new("TextButton", {
		Name = "OpenButton", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 12 + BS / 2, 0.5, 0),
		Size = UDim2.fromOffset(BS, BS), BackgroundColor3 = T.Panel, Text = cfg.Logo and "" or brand:sub(1, 2),
		Font = Enum.Font.GothamBlack, TextSize = touchUI and 19 or 17, TextColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false, Visible = false, Active = true, Parent = gui,
	}, { corner(math.floor(BS * 0.3)), stroke(T.Accent, 1.5, 0.2) })
	local ob = win.OpenBtn
	local obStroke = ob:FindFirstChildOfClass("UIStroke")
	local obLogo
	if cfg.Logo then
		obLogo = new("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(BS * 0.58, BS * 0.58),
			BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit,
			Image = type(cfg.Logo) == "number" and ("rbxassetid://" .. cfg.Logo) or cfg.Logo, Parent = ob,
		})
	else
		new("UIGradient", { Color = cseq({ 0, T.Panel }, { 1, T.Lift }), Rotation = 90, Parent = ob })
	end
	win.OpenScale = feedback(ob, ob, "BackgroundColor3", T.Panel, T.Lift, T.AccentSoft)

	-- hover label (PC): "Open SpectreUI  [RightShift]", opens toward the free side of the screen
	local tip
	if not touchUI then
		tip = new("TextLabel", {
			Name = "Tip", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(1, 10, 0.5, 0), Size = UDim2.fromOffset(0, 28),
			AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = T.Panel, BackgroundTransparency = 0.05,
			Text = "Open " .. brand .. "  [" .. toggleKey.Name .. "]", Font = T.FontBold, TextSize = 13,
			TextColor3 = T.Text, Visible = false, ZIndex = 3, Parent = ob,
		}, { corner(8), stroke(T.Border, 1, 0.2), padding(10, 0, 10, 0) })
	end
	local function showTip(on)
		if not tip then return end
		if on and not win._openDrag.Dragging then
			local vp = gui.AbsoluteSize
			local leftSide = ob.AbsolutePosition.X + BS / 2 < vp.X / 2
			tip.AnchorPoint = Vector2.new(leftSide and 0 or 1, 0.5)
			tip.Position = UDim2.new(leftSide and 1 or 0, leftSide and 10 or -10, 0.5, 0)
			tip.Visible = true
		else
			tip.Visible = false
		end
	end

	-- idle fade: dims after a few seconds so it never nags, wakes on touch / hover
	local idleSeq, hoverOpen = 0, false
	local function wake(on)
		local a = on and 0 or 0.5
		tween(ob, 0.25, { TextTransparency = a })
		if obStroke then tween(obStroke, 0.25, { Transparency = on and 0.2 or 0.65 }) end
		if obLogo then tween(obLogo, 0.25, { ImageTransparency = a }) end
		if not on then tween(ob, 0.25, { BackgroundTransparency = 0.4 }) else tween(ob, 0.15, { BackgroundTransparency = 0 }) end
	end
	local function scheduleIdle()
		idleSeq += 1
		local seq = idleSeq
		task.delay(3, function()
			if seq == idleSeq and not win._destroyed and ob.Visible and not hoverOpen and not win._openDrag.Dragging then wake(false) end
		end)
	end
	local function awake()
		idleSeq += 1
		wake(true)
	end
	ob.MouseEnter:Connect(function()
		if usingTouch() then return end
		hoverOpen = true
		awake()
		showTip(true)
	end)
	ob.MouseLeave:Connect(function()
		hoverOpen = false
		showTip(false)
		scheduleIdle()
	end)
	bindPress(ob, function() awake(); showTip(false) end, function() scheduleIdle() end)
	ob:GetPropertyChangedSignal("Visible"):Connect(function()
		if ob.Visible then
			wake(true)
			scheduleIdle()
		else
			showTip(false)
		end
	end)

	-- glow ring around the floating button — skipped in low power (a rounded stroke
	-- that would re-rasterize on every drag frame)
	if not lowPower() then
		win.OpenGlow = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = ob.Position, Size = UDim2.fromOffset(BS + 14, BS + 14),
			BackgroundTransparency = 1, ZIndex = 0, Visible = false, Parent = gui,
		}, { new("UICorner", { CornerRadius = UDim.new(0, math.floor(BS * 0.3) + 7) }), stroke(T.Accent, 2, 0.85) })
		ob:GetPropertyChangedSignal("Position"):Connect(function()
			win.OpenGlow.Position = ob.Position
		end)
		ob:GetPropertyChangedSignal("Visible"):Connect(function()
			win.OpenGlow.Visible = ob.Visible
		end)
	end

	win._openDrag.Threshold = touchUI and 10 or 6
	win._openDrag.Smooth = true -- eased follow on touch too (no stepping at finger-event rate)
	win._openDrag.OnStart = function()
		awake()
		showTip(false)
	end
	-- after a drag the button glides to the nearest side edge (clear of the Roblox top bar on the left)
	win._openDrag.OnEnd = function()
		if win._openDrag.Moved and win._openDrag.Center then
			local vp = gui.AbsoluteSize
			local c = win._openDrag.Center
			local half, m = BS / 2, 10
			local onLeft = c.X < vp.X / 2
			local x = onLeft and (half + m) or (vp.X - half - m)
			local top = (touchUI and onLeft) and 60 or 8
			local y = math.clamp(c.Y, top + half, math.max(top + half, vp.Y - half - m))
			win._openDrag.Glide(Vector2.new(x, y))
		end
		scheduleIdle()
	end
	makeDraggable(gui, ob, ob, win._openDrag)
	ob.MouseButton1Click:Connect(function()
		if win._openDrag.Moved then return end -- it was a drag, not a tap
		win:SetVisible(true)
	end)

	---------------------------------------------------------- toggle key / responsive
	table.insert(win.Conns, UserInputService.InputBegan:Connect(function(i)
		if i.KeyCode == (cfg.ToggleKey or Enum.KeyCode.RightShift) and not UserInputService:GetFocusedTextBox() then win:SetVisible(not win.Visible) end
	end))
	table.insert(win.Conns, gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() win:_Fit() end))
	win:_Fit()

	table.insert(self.Windows, win)
	win:_PlayOpen(true)
	return win
end

function Window:_Fit(animate)
	local vp = self.Gui.AbsoluteSize
	if vp.X <= 0 or vp.Y <= 0 then return end
	local w, h
	if self.Maximized then
		local m = UserInputService.TouchEnabled and 6 or 12
		w, h = math.max(vp.X - m * 2, 200), math.max(vp.Y - m * 2, 160)
	else
		-- floor = MinWidth (default 700) so the two-column layout never collapses; SetSize obeys it too
		local fw = math.min(self.Cfg.MinWidth or 700, vp.X - 16)
		local fh = math.min(self.Cfg.MinHeight or 280, vp.Y - 16)
		w = math.max(math.min(self.Cfg.Width or 820, vp.X - 16), fw)
		h = math.max(math.min(self.Cfg.Height or 540, vp.Y - 16), fh)
	end
	local anim = animate and not lowPower()
	if anim then
		tween(self.Main, 0.3, { Size = UDim2.fromOffset(w, h) })
	else
		self.Main.Size = UDim2.fromOffset(w, h)
	end

	local compact = w < 560
	local sw = compact and 56 or 164
	self.Sidebar.Size = UDim2.new(0, sw, 1, 0)
	self.Content.Position = UDim2.fromOffset(sw, 0)
	self.Content.Size = UDim2.new(1, -sw, 1, 0)
	local twoCol = (w - sw) >= 520

	if compact ~= self.Compact then
		self.Compact = compact
		self.Footer.Visible = not compact
		-- compact: brand text is long, so only the logo glyph is shown in the header
		if self.BrandLabel then self.BrandLabel.Visible = not compact end
		if self.SubLabel then self.SubLabel.Visible = not compact; self.SubSep.Visible = not compact end
		for _, t in ipairs(self.Tabs) do t:_ApplyCompact(compact) end
	end
	if twoCol ~= self.TwoCol then
		self.TwoCol = twoCol
		for _, t in ipairs(self.Tabs) do t:_QueueRelayout() end
	end

	-- keep the (possibly dragged) window and open button on screen after a resize / rotation
	local rel = self.Maximized and Vector2.new(0.5, 0.5) or self._drag.Rel
	if rel then
		local c = clampCenter(vp, Vector2.new(w, h) / 2, Vector2.new(rel.X * vp.X, rel.Y * vp.Y))
		if anim then
			tween(self.Main, 0.3, { Position = UDim2.fromOffset(c.X, c.Y) })
		else
			self.Main.Position = UDim2.fromOffset(c.X, c.Y)
		end
	end
	local orel = self._openDrag.Rel
	if orel then
		local hb = (self.OpenSize or 42) / 2
		local c = clampCenter(vp, Vector2.new(hb, hb), Vector2.new(orel.X * vp.X, orel.Y * vp.Y))
		self.OpenBtn.Position = UDim2.fromOffset(c.X, c.Y)
	end
	if self._nm then self._nm:_RefitSoon() end
end

function Window:CloseDropdowns()
	if self._dd then self._dd:Close() end
end

-- open / close animation: scale + slide + fade (veil). Runs on every platform; on low power it
-- skips the UIScale (that is the expensive part: it re-rasterizes every stroke) and uses
-- slide + fade only, which is cheap.
local SLIDE = 22

function Window:_AnimBase()
	if not self._animBase then self._animBase = self.Main.Position end
	return self._animBase
end

function Window:_AnimDone()
	if self._animBase then self.Main.Position = self._animBase end
	self._animBase = nil
	self.Scale.Scale = 1
end

function Window:_PlayOpen(fresh)
	self._vseq = (self._vseq or 0) + 1
	local seq = self._vseq
	local veil = self.Veil
	local low = lowPower()
	local base = self:_AnimBase()
	if fresh then
		self.Main.Position = base + UDim2.fromOffset(0, SLIDE)
		if not low then self.Scale.Scale = 0.88 end
		veil.BackgroundTransparency = 0
	end
	veil.Visible = true
	self:_FXResume()
	if not low then tween(self.Scale, 0.5, { Scale = 1 }, QUINT, OUT) end
	tween(self.Main, 0.5, { Position = base }, QUINT, OUT)
	tween(veil, 0.38, { BackgroundTransparency = 1 }, SINE, OUT).Completed:Connect(function()
		if self._vseq ~= seq then return end
		veil.Visible = false
		self:_AnimDone()
	end)
end

-- close animation: shrink + slide down + fade, then swap to the floating open button
function Window:_PlayClose()
	self._vseq = (self._vseq or 0) + 1
	local seq = self._vseq
	local veil = self.Veil
	local low = lowPower()
	local base = self:_AnimBase()
	if not veil.Visible then
		veil.BackgroundTransparency = 1
		veil.Visible = true
	end
	if not low then tween(self.Scale, 0.26, { Scale = 0.9 }, QUAD, IN) end
	tween(self.Main, 0.26, { Position = base + UDim2.fromOffset(0, SLIDE) }, QUAD, IN)
	tween(veil, 0.26, { BackgroundTransparency = 0 }, SINE, IN).Completed:Connect(function()
		if self._vseq ~= seq or self.Visible then return end
		veil.Visible = false
		self.Main.Visible = false
		self:_AnimDone()
		self:_FXPause() -- nothing is on screen: stop the looping backdrop tweens
		self.OpenBtn.Visible = true
		self.OpenScale.Scale = 0.6
		tween(self.OpenScale, 0.4, { Scale = 1 }, BACK, OUT)
	end)
end

function Window:SetVisible(v)
	if self.Visible == v then return end
	self.Visible = v
	self:CloseDropdowns()
	self._drag.Stop()
	if v then
		local fresh = not self.Main.Visible
		self._openDrag.Stop()
		self.OpenBtn.Visible = false
		self.Main.Visible = true
		self:_PlayOpen(fresh)
	else
		self:_PlayClose()
	end
end

function Window:Toggle() self:SetVisible(not self.Visible) end

-- maximize (fill the screen with a small margin) / restore the previous size and position
function Window:_SetMaxFlag(v)
	self.Maximized = v and true or false
	if self._setMaxIcon then self._setMaxIcon(self.Maximized) end
end

function Window:SetMaximized(v)
	v = v and true or false
	if self.Maximized == v then return end
	self:CloseDropdowns()
	self._drag.Stop()
	if v then
		self._restore = { W = self.Cfg.Width, H = self.Cfg.Height, Rel = self._drag.Rel }
		local sz = self.Main.AbsoluteSize
		if not self.Cfg.Width then self.Cfg.Width, self._restore.W = sz.X, sz.X end
		if not self.Cfg.Height then self.Cfg.Height, self._restore.H = sz.Y, sz.Y end
	else
		local r = self._restore or {}
		self.Cfg.Width, self.Cfg.Height = r.W, r.H
		self._drag.Rel = r.Rel or Vector2.new(0.5, 0.5)
	end
	self:_SetMaxFlag(v)
	self:_Fit(true)
	safe(self.Cfg.OnMaximize, v)
end

function Window:IsMaximized() return self.Maximized end

-- resize with the same clamping as dragging the grip; width / height in pixels
function Window:Resize(w, h)
	self:_SetMaxFlag(false)
	self:SetSize(w, h)
end

-- update the header / footer title live. Accepts "Brand | Sub" or (brand, sub).
function Window:SetTitle(title, sub)
	if sub == nil and type(title) == "string" then
		local b, s = title:match("^(.-)%s*|%s*(.+)$")
		if b then title, sub = b, s end
	end
	if title ~= nil then
		self.Brand = title
		self.BrandLabel.Text = title
		self.FooterBrand.Text = title
	end
	if sub ~= nil then
		self.Sub = sub
		if self.SubLabel then self.SubLabel.Text = sub end
		if self.FooterSub then self.FooterSub.Text = sub end
	end
end

function Window:GetTab(name)
	for _, t in ipairs(self.Tabs) do
		if t.Name == name then return t end
	end
end

-- select a tab by object or by name
function Window:SetTab(nameOrTab)
	local t = type(nameOrTab) == "string" and self:GetTab(nameOrTab) or nameOrTab
	if t then self:SelectTab(t) end
	return t
end

-- override the auto-fit size. Width / Height nil keeps the current auto value.
function Window:SetSize(w, h)
	self.Cfg.Width = w
	self.Cfg.Height = h
	self:_Fit()
end

function Window:Center()
	local vp = self.Gui.AbsoluteSize
	self.Main.Position = UDim2.fromOffset(vp.X / 2, vp.Y / 2)
	self._drag.Rel = Vector2.new(0.5, 0.5)
end

-- quick attention pulse on the window border (used by Notify too)
function Window:Flash(color)
	local s = self.Main:FindFirstChildOfClass("UIStroke")
	if not s then return end
	color = color or self.Theme.Accent
	local seq = (self._fseq or 0) + 1
	self._fseq = seq
	s.Color = color
	tween(s, 0.18, { Transparency = 0 })
	task.delay(0.5, function()
		if self._fseq ~= seq then return end
		tween(s, 0.6, { Color = self.Theme.Border, Transparency = 0.1 })
	end)
end

function Window:Destroy()
	self._destroyed = true
	if self._nm then pcall(function() self._nm:Destroy() end) end
	self._drag.Stop()
	self._openDrag.Stop()
	if self.FX then for _, tw in ipairs(self.FX.Tweens) do pcall(function() tw:Cancel() end) end end
	if self._sheen then pcall(function() self._sheen:Cancel() end) end
	for _, c in ipairs(self.Conns) do c:Disconnect() end
	self.Gui:Destroy()
	for i, w in ipairs(Library.Windows) do
		if w == self then table.remove(Library.Windows, i) break end
	end
end

function Window:_ApplySearch()
	local tab = self.Active
	if not tab then return end
	local q = self.SearchBox.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
	for _, s in ipairs(tab.Sections) do
		local secMatch = q == "" or s.Name:lower():find(q, 1, true) ~= nil
		local any = false
		for _, c in ipairs(s.Controls) do
			local vis = (secMatch or c.Name:find(q, 1, true) ~= nil) and not c.Hidden
			c.Frame.Visible = vis
			any = any or vis
		end
		s.Frame.Visible = secMatch or any
	end
	tab:_QueueRelayout()
end

-- tab switch: the new page slides in (direction follows tab order) while fading up from the window color
function Window:SelectTab(tab)
	if self.Active == tab then return end
	local T = self.Theme
	self:CloseDropdowns()
	local prev = self.Active
	local dir = 1
	if prev then
		dir = ((table.find(self.Tabs, tab) or 0) > (table.find(self.Tabs, prev) or 0)) and 1 or -1
		prev.Page.Visible = false
		prev:_SetSelected(false)
	end
	self.Active = tab
	tab.Page.Visible = true
	tab:_SetSelected(true)
	self:_ApplySearch()
	tab:_QueueRelayout()

	if prev and not lowPower() then
		self._pseq = (self._pseq or 0) + 1
		local seq = self._pseq
		local pv = self.PageVeil
		pv.BackgroundTransparency = 0.2   -- not fully opaque: the new page eases in instead of popping out of a flat color
		pv.Visible = true
		tab.Page.Position = UDim2.fromOffset(0, 22 * dir)
		tween(tab.Page, 0.45, { Position = UDim2.new() }, QUINT, OUT)
		tween(pv, 0.34, { BackgroundTransparency = 1 }, SINE, OUT).Completed:Connect(function()
			if self._pseq == seq then pv.Visible = false end
		end)
		-- one-shot accent sweep across the top of the new page
		local sweep = new("Frame", {
			Size = UDim2.new(0, 0, 0, 2), Position = UDim2.fromOffset(0, 0), BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0, ZIndex = 21, Parent = tab.Page,
		}, { gradient(cseq({ 0, Color3.new(1, 1, 1) }, { 0.5, T.Accent2 }, { 1, Color3.new(1, 1, 1) }), 0) })
		sweep:FindFirstChildOfClass("UIGradient").Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 0.4),
		})
		tween(sweep, 0.4, { Size = UDim2.new(1, 0, 0, 2) }, QUAD, OUT).Completed:Connect(function()
			tween(sweep, 0.25, { BackgroundTransparency = 1 }, QUAD, IN).Completed:Connect(function() sweep:Destroy() end)
		end)
	end
end

------------------------------------------------------------------ v3.4 : feedback UI
-- Notifications, Toast, Banner, Loading, Dialogs + the helper APIs they are built on
-- (Util, Responsive, Anim, Theme). Everything here is event driven: no Heartbeat loops,
-- every connection / tween / task of a notification lives in a Bag that is cleaned on dispose.
local Workspace = game:GetService("Workspace")

---------------------------------------------------------------- Util API
local Util = {}
Library.Util = Util
Util.Create = new

-- Util.Dispose(x): disconnect / destroy / cancel whatever x is (connection, instance, tween, function, thread, {Destroy|Disconnect|Cancel})
function Util.Dispose(x)
	local t = typeof(x)
	if t == "RBXScriptConnection" then
		x:Disconnect()
	elseif t == "Instance" then
		if x:IsA("TweenBase") then pcall(function() x:Cancel() end) end
		x:Destroy()
	elseif t == "thread" then
		pcall(task.cancel, x)
	elseif t == "function" then
		pcall(x)
	elseif t == "table" then
		if type(x.Destroy) == "function" then pcall(x.Destroy, x)
		elseif type(x.Disconnect) == "function" then pcall(x.Disconnect, x)
		elseif type(x.Cancel) == "function" then pcall(x.Cancel, x) end
	end
end

-- Util.Bag() -> bag   :Add(x) -> x   :Clean()   :Destroy()
-- Items are disposed newest first, so add a tween BEFORE the connection that listens to it.
function Util.Bag()
	local bag = { _items = {}, _dead = false }
	function bag:Add(x)
		if x == nil then return x end
		if self._dead then pcall(Util.Dispose, x) return x end
		table.insert(self._items, x)
		return x
	end
	function bag:Clean()
		local items = self._items
		self._items = {}
		for i = #items, 1, -1 do pcall(Util.Dispose, items[i]) end
	end
	function bag:Destroy()
		self._dead = true
		self:Clean()
	end
	return bag
end

-- Util.Opt(tbl, key, "number"|"string"|"boolean"|"Color3"|..., default, min, max): validated field read
function Util.Opt(t, key, kind, default, lo, hi)
	local v = type(t) == "table" and t[key] or nil
	if v == nil or typeof(v) ~= kind then return default end
	if kind == "number" then
		if v ~= v then return default end
		if lo then v = math.max(v, lo) end
		if hi then v = math.min(v, hi) end
	end
	return v
end

-- Util.Debounce(fn, wait): runs fn once, `wait` seconds after the LAST call
function Util.Debounce(fn, wait)
	local token = 0
	return function(...)
		token = token + 1
		local my, args = token, table.pack(...)
		task.delay(wait or 0.1, function()
			if my == token then safe(fn, table.unpack(args, 1, args.n)) end
		end)
	end
end

-- Util.Throttle(fn, interval): runs fn at most once per interval (first call goes through)
function Util.Throttle(fn, interval)
	local last = -math.huge
	return function(...)
		local now = os.clock()
		if now - last >= (interval or 0.1) then
			last = now
			return fn(...)
		end
	end
end

function Util.Round(n, dp)
	local m = 10 ^ (dp or 0)
	return math.floor(n * m + 0.5) / m
end

-- 1234 -> "1.2K", 3400000 -> "3.4M"
function Util.FormatNumber(n)
	if type(n) ~= "number" or n ~= n then return "0" end
	local a = math.abs(n)
	if a >= 1e9 then return Util.Round(n / 1e9, 1) .. "B" end
	if a >= 1e6 then return Util.Round(n / 1e6, 1) .. "M" end
	if a >= 1e3 then return Util.Round(n / 1e3, 1) .. "K" end
	return tostring(Util.Round(n, 1))
end

-- 65 -> "1:05", 3700 -> "1:01:40"
function Util.FormatTime(sec)
	sec = math.max(0, math.floor(tonumber(sec) or 0))
	local h, m, s = math.floor(sec / 3600), math.floor(sec / 60) % 60, sec % 60
	if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
	return string.format("%d:%02d", m, s)
end

-- UTF-8 safe truncate (Thai / emoji never get cut in the middle of a character)
function Util.Truncate(s, n, tail)
	s = tostring(s)
	local len = utf8.len(s)
	if not len then return #s > n and (s:sub(1, n) .. (tail or "...")) or s end
	if len <= n then return s end
	local cut = utf8.offset(s, n + 1)
	return s:sub(1, (cut or (n + 1)) - 1) .. (tail or "\u{2026}")
end

function Util.Lighten(c, a) return c:Lerp(Color3.new(1, 1, 1), a or 0.3) end
function Util.Darken(c, a) return c:Lerp(Color3.new(0, 0, 0), a or 0.3) end
function Util.ToHex(c)
	return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end
function Util.FromHex(s)
	if type(s) ~= "string" then return nil end
	local h = s:match("^#?(%x%x%x%x%x%x)$")
	if not h then return nil end
	return Color3.fromRGB(tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16))
end
-- black or white, whichever reads better on top of c
function Util.Contrast(c)
	local l = 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
	return l > 0.6 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
end

---------------------------------------------------------------- Responsive API
local Responsive = {}
Library.Responsive = Responsive

function Responsive.IsTouch() return UserInputService.TouchEnabled end

-- Responsive.Viewport(win?) -> Vector2 (the window's gui, or the camera viewport)
function Responsive.Viewport(win)
	local gui = win and win.Gui
	if gui and gui.Parent then
		local s = gui.AbsoluteSize
		if s.X > 0 and s.Y > 0 then return s end
	end
	local cam = Workspace.CurrentCamera
	if cam and cam.ViewportSize.X > 0 then return cam.ViewportSize end
	return Vector2.new(1280, 720)
end

-- "phone" | "tablet" | "desktop"
function Responsive.Breakpoint(win)
	local vp = Responsive.Viewport(win)
	if UserInputService.TouchEnabled then
		return math.min(vp.X, vp.Y) < 500 and "phone" or "tablet"
	end
	return vp.X < 560 and "phone" or "desktop"
end

-- Responsive.Width(win?, max, margin): a width that always fits the screen
function Responsive.Width(win, max, margin)
	local vp = Responsive.Viewport(win)
	margin = margin or 12
	return math.floor(math.clamp(vp.X - margin * 2, 120, max or 320))
end

-- Responsive.Touch(pcValue, touchValue): pick per device
function Responsive.Touch(pc, touch)
	if UserInputService.TouchEnabled then return touch end
	return pc
end

-- Responsive.Scale(n): a size that grows ~15% on touch (comfortable tap targets)
function Responsive.Scale(n)
	return UserInputService.TouchEnabled and math.floor(n * 1.15 + 0.5) or n
end

-- Responsive.OnChange(win, fn(viewport, breakpoint)) -> connection (resize / rotation)
function Responsive.OnChange(win, fn)
	local gui = win and win.Gui
	if not gui then return { Disconnect = function() end } end
	return gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		safe(fn, gui.AbsoluteSize, Responsive.Breakpoint(win))
	end)
end

function Window:OnResize(fn)
	local c = Responsive.OnChange(self, fn)
	table.insert(self.Conns, c)
	return c
end

---------------------------------------------------------------- Animation API
-- Library.Anim.Speed already exists (global duration multiplier). Added:
--   Anim.Tween(obj, time, props, style?, dir?) -> Tween
--   Anim.Show(obj, { From, Distance, Time, Scale, Style }, done?)   fade + slide / pop in
--   Anim.Hide(obj, { To, Distance, Time, Destroy }, done?)          fade + slide out, then Visible=false (or Destroy)
--   Anim.Pulse(obj, amount?)   Anim.Stop(obj)
local Anim = Library.Anim
local animSeq = setmetatable({}, { __mode = "k" })
local animHome = setmetatable({}, { __mode = "k" })

-- scaled tween with optional delay (min 60 ms)
local function tw(o, t, props, style, dir, delay)
	t = math.max(t * (Library.Anim.Speed or 1), 0.06)
	local tweenObj = TweenService:Create(o, TweenInfo.new(t, style or SINE, dir or OUT, 0, false, delay or 0), props)
	tweenObj:Play()
	return tweenObj
end

function Anim.Tween(obj, t, props, style, dir)
	if typeof(obj) ~= "Instance" or type(props) ~= "table" then return nil end
	return tween(obj, t or 0.2, props, style, dir)
end

local DIRS = {
	Left = Vector2.new(-1, 0), Right = Vector2.new(1, 0), Top = Vector2.new(0, -1), Bottom = Vector2.new(0, 1),
	None = Vector2.new(0, 0),
}

local function fadeProp(obj)
	if obj:IsA("CanvasGroup") then return "GroupTransparency" end
	if obj:IsA("GuiObject") then return "BackgroundTransparency" end
end

local function ensureScale(obj)
	local s = obj:FindFirstChild("SpectreScale")
	if not s then s = new("UIScale", { Name = "SpectreScale", Parent = obj }) end
	return s
end

local function homeOf(obj)
	local h = animHome[obj]
	if not h then
		h = { Pos = obj.Position, Fade = obj:IsA("CanvasGroup") and 0 or obj.BackgroundTransparency }
		animHome[obj] = h
	end
	return h
end

function Anim.Show(obj, opts, done)
	if typeof(obj) ~= "Instance" or not obj:IsA("GuiObject") then return nil end
	opts = type(opts) == "table" and opts or {}
	local seq = (animSeq[obj] or 0) + 1
	animSeq[obj] = seq
	local home = homeOf(obj)
	local d = (DIRS[opts.From or "Bottom"] or DIRS.None) * (opts.Distance or 24)
	local t = opts.Time or 0.3
	local fp = fadeProp(obj)
	local fade = fp and home.Fade < 1
	obj.Position = home.Pos + UDim2.fromOffset(d.X, d.Y)
	if fade then obj[fp] = 1 end
	obj.Visible = true
	local sc
	if opts.Scale then
		sc = ensureScale(obj)
		sc.Scale = opts.Scale
	end
	local main = tw(obj, t, { Position = home.Pos }, opts.Style or QUINT, OUT)
	if fade then tw(obj, t * 0.8, { [fp] = home.Fade }, SINE, OUT) end
	if sc then tw(sc, t, { Scale = 1 }, opts.Style or QUINT, OUT) end
	if done then
		main.Completed:Connect(function(st)
			if animSeq[obj] == seq and st == Enum.PlaybackState.Completed then safe(done, obj) end
		end)
	end
	return main
end

function Anim.Hide(obj, opts, done)
	if typeof(obj) ~= "Instance" or not obj:IsA("GuiObject") then return nil end
	opts = type(opts) == "table" and opts or {}
	local seq = (animSeq[obj] or 0) + 1
	animSeq[obj] = seq
	local home = homeOf(obj)
	local d = (DIRS[opts.To or "Bottom"] or DIRS.None) * (opts.Distance or 24)
	local t = opts.Time or 0.2
	local fp = fadeProp(obj)
	local fade = fp and home.Fade < 1
	local sc = opts.Scale and ensureScale(obj)
	local main = tw(obj, t, { Position = home.Pos + UDim2.fromOffset(d.X, d.Y) }, opts.Style or QUAD, IN)
	if fade then tw(obj, t, { [fp] = 1 }, SINE, IN) end
	if sc then tw(sc, t, { Scale = opts.Scale }, QUAD, IN) end
	main.Completed:Connect(function()
		if animSeq[obj] ~= seq then return end
		animHome[obj] = nil
		if opts.Destroy then
			obj:Destroy()
		else
			-- rests at its home state, invisible, ready for the next Show
			obj.Visible = false
			obj.Position = home.Pos
			if fade then obj[fp] = home.Fade end
			if sc then sc.Scale = 1 end
		end
		if done then safe(done, obj) end
	end)
	return main
end

function Anim.Pulse(obj, amount, t)
	if typeof(obj) ~= "Instance" or not obj:IsA("GuiObject") then return end
	local sc = ensureScale(obj)
	local seq = (animSeq[sc] or 0) + 1
	animSeq[sc] = seq
	tw(sc, (t or 0.2) * 0.4, { Scale = 1 + (amount or 0.04) }, QUAD, OUT).Completed:Connect(function()
		if animSeq[sc] == seq then tw(sc, (t or 0.2) * 0.6, { Scale = 1 }, QUAD, OUT) end
	end)
end

-- invalidate pending Show / Hide completion callbacks of obj (a newer tween on the same property wins anyway)
function Anim.Stop(obj)
	if obj then
		animSeq[obj] = (animSeq[obj] or 0) + 1
		animHome[obj] = nil
	end
end

---------------------------------------------------------------- Theme API
-- Library.Kinds = status styles used by notifications / toasts / dialogs (Color nil = theme accent)
Library.Kinds = {
	Success = { Color = rgb(52, 211, 153), Icon = "check" },
	Warning = { Color = rgb(251, 191, 36), Icon = "!" },
	Error   = { Color = rgb(248, 113, 113), Icon = "cross" },
	Info    = { Color = rgb(96, 165, 250), Icon = "i" },
	Loading = { Color = nil, Icon = "spinner" },
}

local THEME_COLOR_KEYS = { "Background", "Panel", "Card", "Control", "Border", "Accent", "Accent2", "AccentSoft", "Sheen", "Text", "SubText" }

-- Library:RegisterTheme("Ocean", { Accent = ..., ... }) -> ok, err   (missing keys fall back to the default palette)
function Library:RegisterTheme(name, theme)
	if type(name) ~= "string" or name == "" or type(theme) ~= "table" then return false, "usage: RegisterTheme(name, table)" end
	for _, k in ipairs(THEME_COLOR_KEYS) do
		if theme[k] ~= nil and typeof(theme[k]) ~= "Color3" then return false, k .. " must be a Color3" end
	end
	self.Themes[name] = theme
	return true
end

-- Library:GetTheme(name?) -> a full, derived copy (nil name = the current default theme)
function Library:GetTheme(name)
	if name == nil then return deriveTheme(table.clone(self.Theme)) end
	local src = self.Themes[name]
	if not src then return nil end
	return deriveTheme(buildTheme(src))
end

function Library:ListThemes()
	local out = {}
	for k in pairs(self.Themes) do table.insert(out, k) end
	table.sort(out)
	return out
end

-- Library:SetStatusColors({ Success = Color3, Warning = ..., Error = ..., Info = ... })
function Library:SetStatusColors(map)
	if type(map) ~= "table" then return false end
	for k, c in pairs(map) do
		if self.Kinds[k] and typeof(c) == "Color3" then self.Kinds[k].Color = c end
	end
	return true
end

function Library:GetStatusColor(kind)
	local k = self.Kinds[kind]
	return k and k.Color
end

---------------------------------------------------------------- notification engine
-- Library.NotifyConfig: global defaults (all optional)
--   Position  "BottomRight" | "TopCenter" | ...   nil = auto (PC bottom-right, touch top-right)
--   MaxVisible, Duration, Gap, Margin, Width, Merge (identical notifications become "x2"), PauseOnHover, Animate
local NotifyCfg = { Position = nil, MaxVisible = nil, Duration = 4, Gap = 8, Margin = nil, Width = nil, Merge = true, PauseOnHover = true, Animate = true }
Library.NotifyConfig = NotifyCfg

local POSITIONS = {
	TopLeft = { 0, 0 }, TopCenter = { 0.5, 0 }, TopRight = { 1, 0 },
	BottomLeft = { 0, 1 }, BottomCenter = { 0.5, 1 }, BottomRight = { 1, 1 },
}
local function normPos(p)
	if type(p) ~= "string" then return nil end
	local k = p:gsub("[%s_%-]", "")
	k = k:lower()
	for name in pairs(POSITIONS) do
		if name:lower() == k then return name end
	end
end

local KIND_ALIAS = {
	success = "Success", ok = "Success", warning = "Warning", warn = "Warning", error = "Error", err = "Error",
	info = "Info", information = "Info", loading = "Loading",
}
local function normKind(k)
	if type(k) ~= "string" then return nil end
	return KIND_ALIAS[k:lower()]
end

local function roleDuration(role)
	if role == "toast" then return 2.4 end
	if role == "banner" then return 5 end
	if role == "loading" then return math.huge end
	return NotifyCfg.Duration or 4
end

-- Duration: number = seconds, 0 / false / math.huge / Dismiss=false = stays until dismissed
local function normDuration(d, dismissFlag, default)
	if dismissFlag == false then return math.huge end
	if d == nil then return default end
	if d == false then return math.huge end
	if type(d) ~= "number" or d ~= d then return default end
	if d <= 0 or d == math.huge then return math.huge end
	return math.clamp(d, 0.4, 3600)
end

local function clip(v, n)
	if v == nil or v == false then return nil end
	v = tostring(v)
	if v == "" then return nil end
	return Util.Truncate(v, n)
end

-- validates a user config into a spec; `base` = previous spec when updating
local function normalize(cfg, role, base)
	if type(cfg) == "string" then cfg = { Content = cfg } end
	if type(cfg) ~= "table" then cfg = {} end
	local s
	if base then
		s = table.clone(base)
	else
		s = {
			Role = role, Duration = roleDuration(role), Countdown = (role == "notify" or role == "banner"),
			Closable = (role ~= "toast"), CloseOnClick = true,
		}
	end
	if cfg.Kind ~= nil or cfg.Type ~= nil then s.Kind = normKind(cfg.Kind ~= nil and cfg.Kind or cfg.Type) end
	if cfg.Title ~= nil then s.Title = clip(cfg.Title, 90) end
	if cfg.Content ~= nil or cfg.Text ~= nil or cfg.Message ~= nil then
		local c = cfg.Content
		if c == nil then c = cfg.Text end
		if c == nil then c = cfg.Message end
		s.Content = clip(c, 500)
	end
	if cfg.Icon ~= nil then
		if cfg.Icon == "auto" then s.Icon = nil
		elseif cfg.Icon == false or type(cfg.Icon) == "string" or type(cfg.Icon) == "number" then s.Icon = cfg.Icon end
	end
	if cfg.Color ~= nil then s.Color = typeof(cfg.Color) == "Color3" and cfg.Color or nil end
	if cfg.Duration ~= nil or cfg.Dismiss ~= nil then
		s.Duration = normDuration(cfg.Duration, cfg.Dismiss, roleDuration(s.Role))
	end
	if cfg.Progress ~= nil then
		local p = cfg.Progress
		if type(p) == "number" and p == p then
			s.Value = math.clamp(p, 0, 1)
		elseif type(p) == "boolean" then
			s.Value = nil
			s.Countdown = p
		end
	end
	if cfg.Position ~= nil then s.Position = normPos(cfg.Position) end
	if cfg.Key ~= nil or cfg.Id ~= nil then
		local k = cfg.Key
		if k == nil then k = cfg.Id end
		s.Key = k ~= nil and tostring(k) or nil
	end
	if type(cfg.Closable) == "boolean" then s.Closable = cfg.Closable end
	if type(cfg.CloseOnClick) == "boolean" then s.CloseOnClick = cfg.CloseOnClick end
	if type(cfg.Merge) == "boolean" then s.Merge = cfg.Merge end
	if cfg.Flash ~= nil then s.Flash = cfg.Flash and true or false end
	if type(cfg.OnClick) == "function" then s.OnClick = cfg.OnClick end
	if type(cfg.OnClose) == "function" then s.OnClose = cfg.OnClose end
	if not base then
		if s.Role ~= "toast" and s.Title == nil then
			s.Title = s.Kind == "Loading" and "Loading" or s.Kind or "Notice"
		end
		if s.Role == "toast" and s.Content == nil then s.Content = s.Title; s.Title = nil end
		if s.Content == nil and s.Title == nil then s.Title = "Notice" end
	end
	return s
end

local function defaultPosition(role)
	local p = normPos(NotifyCfg.Position)
	if p then return p end
	-- touch: corner (top-right), not the middle of the screen where it blocks the view
	if UserInputService.TouchEnabled then return "TopRight" end
	if role == "banner" then return "TopCenter" end
	return role == "toast" and "BottomCenter" or "BottomRight"
end

local function isPersistent(spec) return spec.Duration == math.huge or spec.Value ~= nil end

-- accent colours for a spec
local function styleOf(T, spec)
	local k = spec.Kind and Library.Kinds[spec.Kind]
	local base = (k and k.Color) or spec.Color
	if base then return base, Util.Lighten(base, 0.35) end
	return T.Accent, T.Accent2
end

---------------------------------------------------------------- icons (drawn from frames, no assets)
-- a line segment between two points inside a parent (used for the check / cross glyphs)
local function seg(parent, x1, y1, x2, y2, th, color)
	local dx, dy = x2 - x1, y2 - y1
	return new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2),
		Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy) + th * 0.5, th), Rotation = math.deg(math.atan2(dy, dx)),
		BackgroundColor3 = color, BorderSizePixel = 0, Parent = parent,
	}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
end

-- buildIcon(parent, spec, color, T, size, bag) -> holder frame
local function buildIcon(parent, icon, color, T, size, bag)
	local holder = new("Frame", { Name = "Icon", Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, Parent = parent })
	local u = size / 22
	if icon == "spinner" then
		local ring = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(18 * u, 18 * u),
			BackgroundTransparency = 1, Parent = holder,
		}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
		local st = new("UIStroke", { Color = color, Thickness = 2.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = ring })
		local g = new("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.35, 0.05),
				NumberSequenceKeypoint.new(0.7, 1), NumberSequenceKeypoint.new(1, 1),
			}), Parent = st,
		})
		-- one looping tween; the bag cancels it when the notification is disposed
		local lp = TweenService:Create(g, TweenInfo.new(0.9, LINEAR, OUT, -1), { Rotation = 360 })
		lp:Play()
		if bag then bag:Add(lp) end
		return holder
	end
	-- tinted badge behind the glyph
	new("Frame", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, BackgroundTransparency = 0.82, BorderSizePixel = 0, Parent = holder,
	}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
	if icon == "check" then
		seg(holder, 6.2 * u, 11.6 * u, 9.6 * u, 15 * u, 2 * u, color)
		seg(holder, 9.6 * u, 15 * u, 16.2 * u, 7.6 * u, 2 * u, color)
	elseif icon == "cross" then
		seg(holder, 7.2 * u, 7.2 * u, 14.8 * u, 14.8 * u, 2 * u, color)
		seg(holder, 14.8 * u, 7.2 * u, 7.2 * u, 14.8 * u, 2 * u, color)
	elseif type(icon) == "number" or (type(icon) == "string" and icon:find("rbxasset", 1, true)) then
		new("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.64, 0.64),
			BackgroundTransparency = 1, ImageColor3 = color, ScaleType = Enum.ScaleType.Fit,
			Image = type(icon) == "number" and ("rbxassetid://" .. icon) or icon, Parent = holder,
		})
	elseif Library:IsIconName(icon) and Library:ResolveIcon(icon) then
		local img = Library:MakeIcon(Library:ResolveIcon(icon), color)
		img.Size = UDim2.fromScale(0.64, 0.64)
		img.Parent = holder
	else
		new("TextLabel", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = tostring(icon or "i"):sub(1, 2),
			Font = T.FontBold, TextSize = math.floor(14 * u), TextColor3 = color, Parent = holder,
		})
	end
	return holder
end

---------------------------------------------------------------- manager
local NM = {}
NM.__index = NM

local function mountGui(gui)
	local ok = pcall(function() gui.Parent = (gethui and gethui()) or CoreGui end)
	if not ok or not gui.Parent then
		local lp = Players.LocalPlayer
		gui.Parent = lp and lp:WaitForChild("PlayerGui") or CoreGui
	end
end

-- owner = a Window, or { Headless = true } (Library level calls when no window exists yet)
function NM.new(owner)
	return setmetatable({ Owner = owner, Regions = {}, Dialogs = {}, Bag = Util.Bag(), Seq = 0, Dead = false }, NM)
end

function NM:Theme()
	local o = self.Owner
	if o.Headless then return deriveTheme(table.clone(Library.Theme)) end
	return o._nTheme or o.Theme
end

function NM:_VP()
	local o = self.Owner
	if self.Gui and self.Gui.Parent then
		local s = self.Gui.AbsoluteSize
		if s.X > 0 and s.Y > 0 then return s end
	end
	return Responsive.Viewport(not o.Headless and o or nil)
end

-- the notification layer is its own ScreenGui: above the window and dialogs, safe-area aware
-- (IgnoreGuiInset = false keeps cards out from under the Roblox top bar / phone notch)
function NM:_Gui()
	if self.Gui and self.Gui.Parent then return self.Gui end
	if self.Gui then self:_Reset() end
	local g = new("ScreenGui", {
		Name = "SpectreUI_Notify", ResetOnSpawn = false, IgnoreGuiInset = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 1000,
	})
	local og = self.Owner.Gui
	if og and og.Parent then g.Parent = og.Parent else mountGui(g) end
	self.Gui = g
	self.GuiConn = g:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:_RefitSoon() end)
	return g
end

-- the notification gui vanished (game cleaned it up): drop everything that lived in it
function NM:_Reset()
	for _, r in pairs(self.Regions) do
		for _, e in ipairs(table.clone(r.Items)) do self:_Kill(e, "destroyed") end
		for _, e in ipairs(table.clone(r.Queue)) do self:_Kill(e, "destroyed") end
	end
	self.Regions = {}
	if self.GuiConn then self.GuiConn:Disconnect() self.GuiConn = nil end
	self.Gui = nil
end

function NM:_RefitSoon()
	if self._refit or self.Dead then return end
	self._refit = true
	task.defer(function()
		self._refit = false
		if self.Dead then return end
		for _, r in pairs(self.Regions) do self:_FitRegion(r) end
		for _, d in ipairs(self.Dialogs) do if d.fit then d.fit() end end
	end)
end

function NM:_MaxVisible()
	local m = NotifyCfg.MaxVisible
	if type(m) ~= "number" then m = UserInputService.TouchEnabled and 3 or 5 end
	return math.clamp(math.floor(m), 1, 10)
end

function NM:_FitRegion(r)
	local vp = self:_VP()
	local m = NotifyCfg.Margin
	if type(m) ~= "number" then m = Responsive.Touch(14, 10) end
	local maxW = NotifyCfg.Width
	if type(maxW) ~= "number" then maxW = (r.AX == 0.5) and 360 or Responsive.Touch(320, 300) end
	r.W = math.floor(math.clamp(vp.X - m * 2, 120, maxW))
	r.H = math.max(vp.Y - m * 2, 60)
	r.Gap = type(NotifyCfg.Gap) == "number" and NotifyCfg.Gap or 8
	r.Holder.AnchorPoint = Vector2.new(r.AX, r.AY)
	r.Holder.Position = UDim2.new(r.AX, r.AX == 0 and m or (r.AX == 1 and -m or 0), r.AY, r.AY == 0 and m or -m)
	r.Holder.Size = UDim2.fromOffset(r.W, r.H)
	r.Layout.Padding = UDim.new(0, r.Gap)
	for _, e in ipairs(r.Items) do
		if e.wrap and not e.auto and e.state ~= "dead" then
			e.wrap.Size = UDim2.fromOffset(r.W, e.wrap.Size.Y.Offset)
		end
	end
	self:_Overflow(r)
end

function NM:_Region(pos)
	local r = self.Regions[pos]
	if r and r.Holder.Parent then return r end
	local gui = self:_Gui()
	local ax, ay = POSITIONS[pos][1], POSITIONS[pos][2]
	local holder = new("Frame", { Name = "Region_" .. pos, BackgroundTransparency = 1, Parent = gui })
	local layout = list(8, {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = ax == 0 and Enum.HorizontalAlignment.Left or (ax == 1 and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Center),
		VerticalAlignment = ay == 0 and Enum.VerticalAlignment.Top or Enum.VerticalAlignment.Bottom,
	})
	layout.Parent = holder
	r = { Pos = pos, AX = ax, AY = ay, Holder = holder, Layout = layout, Items = {}, Queue = {}, W = 300, H = 400, Gap = 8 }
	self.Regions[pos] = r
	self:_FitRegion(r)
	return r
end

local function activeCount(r)
	local n = 0
	for _, e in ipairs(r.Items) do
		if e.state ~= "leaving" and e.state ~= "dead" then n = n + 1 end
	end
	return n
end

-- oldest entry that may be removed to make room (never a persistent one: loading / progress / Duration = 0)
local function oldestDismissable(r, except)
	for _, e in ipairs(r.Items) do
		if e ~= except and (e.state == "entering" or e.state == "shown") and not isPersistent(e.spec) then return e end
	end
end

-- too tall for the screen (long texts on a landscape phone): drop the oldest, never the newest
function NM:_Overflow(r)
	for _ = 1, 12 do
		local total, n = 0, 0
		for _, e in ipairs(r.Items) do
			if e.state ~= "leaving" and e.state ~= "dead" and e.h then
				total = total + e.h + r.Gap
				n = n + 1
			end
		end
		if n <= 1 or total - r.Gap <= r.H then return end
		local newest = r.Items[#r.Items]
		local v = oldestDismissable(r, newest)
		if not v then return end
		self:_Dismiss(v, "evicted")
	end
end

function NM:_Pump(r)
	if self.Dead then return end
	while #r.Queue > 0 and activeCount(r) < self:_MaxVisible() do
		local e = table.remove(r.Queue, 1)
		self:_Show(e, r)
	end
end

local function slideDir(r)
	if r.AX == 1 then return "Right" end
	if r.AX == 0 then return "Left" end
	return r.AY == 0 and "Top" or "Bottom"
end

---------------------------------------------------------------- handle
local function deadHandle()
	local h = { Id = 0 }
	local no = function() return false end
	for _, n in ipairs({ "Update", "SetProgress", "Dismiss", "Close", "IsAlive", "OnClose", "Set", "SetText", "Complete", "Fail" }) do h[n] = no end
	return h
end
Library._deadHandle = deadHandle

-- methods work with both h:Method() and h.Method()
local function method(h, fn)
	return function(a, ...)
		if a == h then return fn(...) end
		return fn(a, ...)
	end
end

function NM:_Handle(entry)
	local h = { Id = entry.Id }
	local nm = self
	h.Update = method(h, function(patch)
		if nm:_Update(entry, patch) then return h end
		return false
	end)
	h.SetProgress = method(h, function(v)
		if type(v) ~= "number" then return false end
		return nm:_Update(entry, { Progress = v }) and h or false
	end)
	h.Dismiss = method(h, function(reason) return nm:_Dismiss(entry, type(reason) == "string" and reason or "api") end)
	h.Close = h.Dismiss
	h.IsAlive = method(h, function() return entry.state ~= "dead" and entry.state ~= "leaving" end)
	h.OnClose = method(h, function(fn)
		if type(fn) == "function" then entry.spec.OnClose = fn end
		return h
	end)
	entry.handle = h
	return h
end

---------------------------------------------------------------- build / paint
function NM:_Build(entry)
	local T = self:Theme()
	local spec, r = entry.spec, entry.region
	local ui = {}
	entry.ui = ui
	local toast = spec.Role == "toast"
	entry.auto = toast
	local bag = entry.bag
	local touch = UserInputService.TouchEnabled

	local wrap = new("Frame", {
		Name = "N" .. entry.Id, BackgroundTransparency = 1, LayoutOrder = entry.Id,
		Size = UDim2.fromOffset(toast and 0 or r.W, 0), Parent = r.Holder,
	})
	entry.wrap = wrap
	local dir = slideDir(r)
	local card = new("CanvasGroup", {
		Name = "Card", BackgroundTransparency = 1, GroupTransparency = 1,
		Size = toast and UDim2.fromOffset(0, 0) or UDim2.new(1, 0, 0, 0), AutomaticSize = toast and Enum.AutomaticSize.XY or AY,
		Parent = wrap,
	}, { corner(toast and 16 or 10) })
	ui.Card = card
	if not toast then new("UISizeConstraint", { MinSize = Vector2.new(0, 46), Parent = card }) end

	ui.Bg = new("Frame", { Name = "Bg", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Panel, BackgroundTransparency = 0.03, BorderSizePixel = 0, ZIndex = 1, Parent = card })
	ui.BgGrad = wash(cseq({ 0, T.Top }, { 1, T.Deep }), 90)
	ui.BgGrad.Parent = ui.Bg
	ui.Rim = new("Frame", { Name = "Rim", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2, Parent = card },
		{ corner(toast and 16 or 10), stroke(T.Accent, 2, 0.5) })
	ui.RimStroke = ui.Rim:FindFirstChildOfClass("UIStroke")

	if toast then
		local row = new("Frame", { Name = "Row", Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1, ZIndex = 3, Parent = card },
			{ list(8, { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center }), padding(12, 8, 16, 8) })
		ui.Row = row
		ui.IconSlot = new("Frame", { LayoutOrder = 1, Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1, Parent = row })
		local maxText = math.max(r.W - 12 - 16 - 18 - 8, 60)
		ui.Content = new("TextLabel", {
			LayoutOrder = 2, Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1,
			Font = T.Font, TextSize = 14, TextColor3 = T.Text, TextWrapped = true, TextXAlignment = LEFT, Parent = row,
		}, { new("UISizeConstraint", { MaxSize = Vector2.new(maxText, math.huge) }) })
		ui.MaxText = ui.Content:FindFirstChildOfClass("UISizeConstraint")
	else
		ui.Rail = new("Frame", { Name = "Rail", Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 3, Parent = card },
			{ gradient(T.Accent, T.Accent2, 90) })
		ui.RailGrad = ui.Rail:FindFirstChildOfClass("UIGradient")
		ui.IconSlot = new("Frame", { Name = "IconSlot", Position = UDim2.fromOffset(14, 10), Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1, ZIndex = 3, Parent = card })
		local inner = new("Frame", {
			Name = "Inner", Position = UDim2.fromOffset(46, 0), Size = UDim2.new(1, -(46 + 36), 0, 0), AutomaticSize = AY,
			BackgroundTransparency = 1, ZIndex = 3, Parent = card,
		}, { list(3), padding(0, 11, 0, 13) })
		ui.Title = new("TextLabel", {
			LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Font = T.FontBold, TextSize = 14,
			TextColor3 = T.Text, TextXAlignment = LEFT, TextWrapped = true, Parent = inner,
		})
		ui.Content = new("TextLabel", {
			LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Font = T.Font, TextSize = 13,
			TextColor3 = T.SubText, TextXAlignment = LEFT, TextWrapped = true, Parent = inner,
		})
		-- countdown / progress bar along the bottom edge
		ui.Track = new("Frame", { Name = "Track", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 3),
			BackgroundColor3 = T.Accent, BackgroundTransparency = 0.86, BorderSizePixel = 0, ZIndex = 4, Visible = false, Parent = card })
		ui.Fill = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = ui.Track },
			{ gradient(T.Accent, T.Accent2, 0) })
		ui.FillGrad = ui.Fill:FindFirstChildOfClass("UIGradient")
	end

	-- whole card is one big hit target (comfortable on touch); the x sits above it
	ui.Hit = new("TextButton", { Name = "Hit", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 5, Parent = card })
	bag:Add(ui.Hit.MouseButton1Click:Connect(function()
		local s = entry.spec
		if s.OnClick then safe(s.OnClick, entry.handle) end
		if s.CloseOnClick then self:_Dismiss(entry, "click") end
	end))
	if not toast then
		local cs = touch and 32 or 24
		ui.Close = new("TextButton", {
			Name = "Close", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -4, 0, 4), Size = UDim2.fromOffset(cs, cs),
			BackgroundTransparency = 1, Text = "\u{00D7}", Font = T.FontBold, TextSize = 20, TextColor3 = T.SubText, AutoButtonColor = false, ZIndex = 6, Parent = card,
		})
		bag:Add(ui.Close.MouseButton1Click:Connect(function() self:_Dismiss(entry, "close") end))
		bag:Add(ui.Close.MouseEnter:Connect(function()
			if not usingTouch() then tween(ui.Close, 0.12, { TextColor3 = T.Text }) end
		end))
		bag:Add(ui.Close.MouseLeave:Connect(function() tween(ui.Close, 0.14, { TextColor3 = T.SubText }) end))
	end

	-- hover pauses the countdown (PC); mouse leave resumes. A watchdog resumes it after 12 s regardless.
	if NotifyCfg.PauseOnHover ~= false then
		bag:Add(ui.Hit.MouseEnter:Connect(function()
			if usingTouch() then return end
			self:_Hover(entry, true)
		end))
		bag:Add(ui.Hit.MouseLeave:Connect(function() self:_Hover(entry, false) end))
	end

	self:_Paint(entry)

	-- measure: the wrap follows the card height; the enter animation starts when the first real size arrives
	bag:Add(card:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:_OnSize(entry) end))
	bag:Add(task.delay(0.4, function()
		if entry.state == "entering" and not entry.measured then
			entry.h = entry.h or 64
			entry.w = entry.w or r.W
			entry.measured = true
			self:_Enter(entry)
		end
	end))
	self:_OnSize(entry)
end

-- (re)apply everything a spec controls. Safe to call any number of times.
function NM:_Paint(entry)
	local T = self:Theme()
	local spec, ui = entry.spec, entry.ui
	local accent, accent2 = styleOf(T, spec)
	local toast = spec.Role == "toast"
	ui.RimStroke.Color = accent
	if ui.RailGrad then ui.RailGrad.Color = ColorSequence.new(accent, accent2) end
	if ui.FillGrad then ui.FillGrad.Color = ColorSequence.new(accent, accent2) end
	if ui.Track then ui.Track.BackgroundColor3 = accent end

	local content = spec.Content or ""
	if ui.Title then
		local title = spec.Title or ""
		if entry.count > 1 then title = title .. "  \u{00D7}" .. entry.count end
		if spec.Value ~= nil and spec.Kind == "Loading" then title = title .. "  \u{00B7}  " .. math.floor(spec.Value * 100 + 0.5) .. "%" end
		ui.Title.Text = title
		ui.Title.Visible = title ~= ""
		ui.Content.Text = content
		ui.Content.Visible = content ~= ""
	else
		ui.Content.Text = (entry.count > 1 and (content .. "  \u{00D7}" .. entry.count)) or content
	end
	if ui.Close then ui.Close.Visible = spec.Closable end

	local k = spec.Kind and Library.Kinds[spec.Kind]
	local icon = spec.Icon
	if icon == nil then icon = k and k.Icon or "i" end
	local key = tostring(icon) .. "|" .. tostring(accent)
	if ui.IconKey ~= key then
		ui.IconKey = key
		ui.IconBag = ui.IconBag or Util.Bag()
		ui.IconBag:Clean()
		for _, c in ipairs(ui.IconSlot:GetChildren()) do c:Destroy() end
		ui.IconSlot.Visible = icon ~= false
		if icon ~= false then buildIcon(ui.IconSlot, icon, accent, T, toast and 18 or 22, ui.IconBag) end
	end
	if ui.IconBag and not entry.iconBagAdded then
		entry.iconBagAdded = true
		entry.bag:Add(function() ui.IconBag:Destroy() end)
	end
end

function NM:_OnSize(entry)
	if entry.state == "dead" or not entry.ui then return end
	local sz = entry.ui.Card.AbsoluteSize
	if sz.Y <= 0 then return end
	entry.h, entry.w = sz.Y, sz.X
	if not entry.measured then
		entry.measured = true
		if entry.state == "entering" then self:_Enter(entry) end
	elseif entry.state == "shown" then
		self:_SetWrap(entry, true)
		self:_Overflow(entry.region)
	end
end

function NM:_SetWrap(entry, animate)
	local wrap = entry.wrap
	if not wrap or entry.state == "dead" then return end
	local size = UDim2.fromOffset(entry.auto and entry.w or entry.region.W, entry.h)
	if animate and NotifyCfg.Animate ~= false then
		tw(wrap, 0.18, { Size = size }, QUAD, OUT)
	else
		wrap.Size = size
	end
end

function NM:_Enter(entry)
	if entry.state ~= "entering" then return end
	local r = entry.region
	local fw = entry.auto and entry.w or r.W
	local fin = UDim2.fromOffset(fw, entry.h)
	local anim = NotifyCfg.Animate ~= false
	self:_Overflow(r)
	if not anim then
		entry.wrap.Size = fin
		entry.ui.Card.GroupTransparency = 0
		entry.state = "shown"
		self:_StartTimer(entry)
		return
	end
	local t = lowPower() and 0.2 or 0.32
	entry.wrap.Size = UDim2.fromOffset(fw, 0)
	local grow = tw(entry.wrap, t, { Size = fin }, QUINT, OUT)
	Anim.Show(entry.ui.Card, { From = lowPower() and "None" or slideDir(r), Distance = 36, Time = t })
	entry.bag:Add(grow)
	entry.bag:Add(grow.Completed:Connect(function()
		if entry.state ~= "entering" then return end
		entry.state = "shown"
		self:_SetWrap(entry, false)
		self:_StartTimer(entry)
	end))
	-- failsafe: never stay in "entering"
	entry.bag:Add(task.delay(t + 0.8, function()
		if entry.state == "entering" then
			entry.state = "shown"
			self:_SetWrap(entry, false)
			entry.ui.Card.GroupTransparency = 0
			self:_StartTimer(entry)
		end
	end))
end

---------------------------------------------------------------- timer / hover
function NM:_StopTimer(entry)
	if entry.lifeConn then entry.lifeConn:Disconnect() entry.lifeConn = nil end
	if entry.life then
		pcall(function() entry.life:Cancel() end)
		entry.life = nil
	end
end

-- countdown bar = lifetime. Pausing the tween pauses the dismissal too (no separate task.delay to desync).
function NM:_StartTimer(entry)
	self:_StopTimer(entry)
	if entry.state ~= "shown" then return end
	local spec, ui = entry.spec, entry.ui
	if not ui.Track then
		-- toast: no bar, a plain timed tween on a hidden value is not needed; use the tween on the card's own transparency-free property
		if spec.Duration == math.huge then return end
		local probe = ui.Probe
		if not probe then
			probe = new("Frame", { Name = "Probe", Visible = false, Size = UDim2.fromOffset(1, 1), Parent = ui.Card })
			ui.Probe = probe
		end
		probe.Size = UDim2.fromOffset(1, 1)
		local life = TweenService:Create(probe, TweenInfo.new(spec.Duration, LINEAR), { Size = UDim2.fromOffset(0, 0) })
		entry.life = life
		entry.lifeConn = life.Completed:Connect(function(st)
			if st == Enum.PlaybackState.Completed then self:_Dismiss(entry, "timeout") end
		end)
		life:Play()
		if entry.hovering then life:Pause() end
		return
	end
	if spec.Value ~= nil then
		ui.Track.Visible = true
		tw(ui.Fill, 0.2, { Size = UDim2.fromScale(spec.Value, 1) }, QUAD, OUT)
		return
	end
	if spec.Duration == math.huge then
		ui.Track.Visible = false
		return
	end
	ui.Track.Visible = spec.Countdown and true or false
	ui.Fill.Size = UDim2.fromScale(1, 1)
	local life = TweenService:Create(ui.Fill, TweenInfo.new(spec.Duration, LINEAR), { Size = UDim2.fromScale(0, 1) })
	entry.life = life
	entry.lifeConn = life.Completed:Connect(function(st)
		if st == Enum.PlaybackState.Completed then self:_Dismiss(entry, "timeout") end
	end)
	life:Play()
	if entry.hovering then life:Pause() end
end

function NM:_Hover(entry, on)
	if entry.state == "dead" or entry.state == "leaving" then return end
	entry.hovering = on
	if entry.pauseThread then
		pcall(task.cancel, entry.pauseThread)
		entry.pauseThread = nil
	end
	if on then
		if entry.life then pcall(function() entry.life:Pause() end) end
		if entry.ui.RimStroke then tween(entry.ui.RimStroke, 0.15, { Transparency = 0.1 }) end
		entry.pauseThread = task.delay(12, function()
			entry.pauseThread = nil
			self:_Hover(entry, false)
		end)
	else
		if entry.life then pcall(function() entry.life:Play() end) end
		if entry.ui.RimStroke then tween(entry.ui.RimStroke, 0.2, { Transparency = 0.5 }) end
	end
end

---------------------------------------------------------------- dismiss / kill
-- final cleanup. Idempotent: whatever order tweens, failsafes and API calls arrive in, it runs once.
function NM:_Kill(entry, reason)
	if entry.state == "dead" then return end
	entry.state = "dead"
	self:_StopTimer(entry)
	if entry.pauseThread then pcall(task.cancel, entry.pauseThread) entry.pauseThread = nil end
	entry.bag:Destroy()
	if entry.wrap then
		pcall(function() entry.wrap:Destroy() end)
		entry.wrap = nil
	end
	local r = entry.region
	if r then
		for i, e in ipairs(r.Items) do
			if e == entry then table.remove(r.Items, i) break end
		end
		for i, e in ipairs(r.Queue) do
			if e == entry then table.remove(r.Queue, i) break end
		end
	end
	local cb = entry.spec.OnClose
	entry.ui = nil
	if cb then safe(cb, reason or "api") end
	if r and not self.Dead then
		self:_Pump(r)
	end
end

function NM:_Dismiss(entry, reason)
	local st = entry.state
	if st == "dead" or st == "leaving" then return false end
	if st == "queued" then
		self:_Kill(entry, reason)
		return true
	end
	entry.state = "leaving"
	self:_StopTimer(entry)
	if entry.pauseThread then pcall(task.cancel, entry.pauseThread) entry.pauseThread = nil end
	local wrap, card, r = entry.wrap, entry.ui and entry.ui.Card, entry.region
	if not wrap or not card or NotifyCfg.Animate == false then
		self:_Kill(entry, reason)
		return true
	end
	-- 1) the card slides + fades, 2) the slot collapses so the others glide into place (no jump)
	Anim.Hide(card, { To = lowPower() and "None" or slideDir(r), Distance = 36, Time = 0.2 })
	local collapse = tw(wrap, 0.26, { Size = UDim2.fromOffset(wrap.Size.X.Offset, 0) }, QUAD, IN, 0.08)
	entry.bag:Add(collapse)
	entry.bag:Add(collapse.Completed:Connect(function() self:_Kill(entry, reason) end))
	entry.bag:Add(task.delay(0.9, function() self:_Kill(entry, reason) end)) -- failsafe
	return true
end

function NM:DismissAll(reason)
	for _, r in pairs(self.Regions) do
		for _, e in ipairs(table.clone(r.Queue)) do self:_Dismiss(e, reason or "api") end
		for _, e in ipairs(table.clone(r.Items)) do self:_Dismiss(e, reason or "api") end
	end
end

---------------------------------------------------------------- update / add
function NM:_Update(entry, patch)
	if entry.state == "dead" or entry.state == "leaving" or type(patch) ~= "table" then return false end
	local old = entry.spec
	local spec = normalize(patch, old.Role, old)
	if patch.Position ~= nil and spec.Position ~= old.Position then spec.Position = old.Position end -- a live notification does not move
	entry.spec = spec
	if entry.ui then
		self:_Paint(entry)
		if patch.Duration ~= nil or patch.Dismiss ~= nil or patch.Progress ~= nil or patch.Kind ~= nil then
			self:_StartTimer(entry)
		end
		if entry.ui.Card then Anim.Pulse(entry.ui.Card, 0.03) end
	end
	return true
end

local function sameText(a, b)
	return a.Role == b.Role and a.Kind == b.Kind and a.Title == b.Title and a.Content == b.Content and a.Value == nil and b.Value == nil
end

-- every live / queued entry
function NM:_Each(fn)
	for _, r in pairs(self.Regions) do
		for _, e in ipairs(r.Items) do if fn(e) then return e end end
		for _, e in ipairs(r.Queue) do if fn(e) then return e end end
	end
end

function NM:_Show(entry, r)
	entry.region = r
	entry.state = "entering"
	table.insert(r.Items, entry)
	local ok, err = pcall(self._Build, self, entry)
	if not ok then
		warn("[SpectreUI] notification build failed: " .. tostring(err))
		self:_Kill(entry, "error")
	end
end

-- the one entry point: role = "notify" | "toast" | "banner" | "loading"
function NM:Add(cfg, role)
	if self.Dead then return deadHandle() end
	if type(cfg) == "string" then cfg = { Content = cfg } end
	if type(cfg) ~= "table" then cfg = {} end
	local spec = normalize(cfg, role)

	-- same Key -> update that notification instead of stacking another
	if spec.Key then
		local found = self:_Each(function(e) return e.spec.Key == spec.Key and e.state ~= "leaving" and e.state ~= "dead" end)
		if found then
			self:_Update(found, cfg)
			return found.handle
		end
	end
	-- identical text -> "x2" instead of a wall of duplicates
	if NotifyCfg.Merge ~= false and spec.Merge ~= false and not spec.Key then
		local found = self:_Each(function(e)
			return e.state ~= "leaving" and e.state ~= "dead" and not e.spec.Key and sameText(e.spec, spec)
		end)
		if found then
			found.count = found.count + 1
			if found.ui then
				self:_Paint(found)
				self:_StartTimer(found)
				Anim.Pulse(found.ui.Card, 0.04)
			end
			return found.handle
		end
	end

	local r = self:_Region(spec.Position or defaultPosition(role))
	self.Seq = self.Seq + 1
	local entry = { Id = self.Seq, spec = spec, count = 1, state = "queued", bag = Util.Bag(), region = r }
	local handle = self:_Handle(entry)

	if activeCount(r) >= self:_MaxVisible() then
		local victim = oldestDismissable(r)
		if victim then
			self:_Dismiss(victim, "evicted")
		else
			table.insert(r.Queue, entry)
			return handle
		end
	end
	self:_Show(entry, r)
	if spec.Flash and self.Owner.Flash then
		local T = self:Theme()
		self.Owner:Flash((styleOf(T, spec)))
	end
	return handle
end

function NM:Destroy()
	if self.Dead then return end
	for _, r in pairs(self.Regions) do
		for _, e in ipairs(table.clone(r.Items)) do self:_Kill(e, "destroyed") end
		for _, e in ipairs(table.clone(r.Queue)) do self:_Kill(e, "destroyed") end
	end
	self.Dead = true
	for i = #self.Dialogs, 1, -1 do
		if self.Dialogs[i] and self.Dialogs[i].destroy then self.Dialogs[i].destroy() end
	end
	if self.GuiConn then self.GuiConn:Disconnect() self.GuiConn = nil end
	self.Bag:Destroy()
	if self.Gui then pcall(function() self.Gui:Destroy() end) end
	if self.HostGui then pcall(function() self.HostGui:Destroy() end) end
	self.Regions = {}
end

---------------------------------------------------------------- dialogs
-- nm:Dialog({
--   Title, Content, Kind ("Info"|"Success"|"Warning"|"Error"), Icon, Width,
--   Buttons = { { Text, Value, Style = "Primary"|"Secondary"|"Danger", Callback(handle, input), Close = true, Default = true } },
--   Input = true | { Placeholder, Default, MaxLength, Numeric, AutoFocus },
--   Build = function(container, theme, handle) end,      -- add your own controls
--   Dismissable = true (overlay tap / Esc closes with value nil),
--   OnClose(value, input, reason) })
-- -> handle { Close(value), Update{Title,Content,Kind}, IsOpen(), Wait() -> value, input }
function NM:_DialogGui()
	local o = self.Owner
	if o.Gui and o.Gui.Parent then return o.Gui end
	if self.HostGui and self.HostGui.Parent then return self.HostGui end
	local g = new("ScreenGui", { Name = "SpectreUI_Host", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 998 })
	mountGui(g)
	self.HostGui = g
	return g
end

function NM:Dialog(cfg)
	if self.Dead then return deadHandle() end
	if type(cfg) ~= "table" then cfg = {} end
	local T = self:Theme()
	local gui = self:_DialogGui()
	local touch = UserInputService.TouchEnabled
	local owner = (not self.Owner.Headless) and self.Owner or nil
	local bag = Util.Bag()
	local dlg = { open = true, input = nil }
	local handle = { }
	local kind = normKind(cfg.Kind)
	local accent = (kind and Library.Kinds[kind] and Library.Kinds[kind].Color) or T.Accent
	local accent2 = (kind and Util.Lighten(accent, 0.35)) or T.Accent2
	local dismissable = cfg.Dismissable ~= false
	local depth = #self.Dialogs + 1
	local btnH = touch and 42 or 34
	local result = { value = nil, input = nil, reason = nil }
	local waiters = {}

	local overlay = new("Frame", {
		Name = "Dialog", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
		BorderSizePixel = 0, Active = true, ZIndex = 130 + depth * 2, Parent = gui,
	})
	local outside = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 1, Parent = overlay })
	local W = Responsive.Width(owner, math.floor(Util.Opt(cfg, "Width", "number", 340, 220, 560)), 16)
	local card = new("CanvasGroup", {
		Name = "Card", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(W, 0),
		AutomaticSize = AY, BackgroundTransparency = 1, Active = true, ZIndex = 2, Visible = false, Parent = overlay,
	}, { corner(12) })
	new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Panel, BackgroundTransparency = 0.02, BorderSizePixel = 0, ZIndex = 1, Parent = card },
		{ wash(cseq({ 0, T.Top }, { 1, T.Deep }), 90) })
	new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2, Parent = card }, { corner(12), stroke(accent, 2, 0.45) })
	local col = new("Frame", { Size = UDim2.fromScale(1, 0), AutomaticSize = AY, BackgroundTransparency = 1, ZIndex = 3, Parent = card },
		{ list(12), padding(18, 18, 18, 16) })

	-- header: icon + title
	local head = new("Frame", { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, ZIndex = 3, Parent = col },
		{ list(10, { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center }) })
	local iconSlot = new("Frame", { LayoutOrder = 1, Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 1, ZIndex = 3, Parent = head })
	local titleL = new("TextLabel", {
		LayoutOrder = 2, Size = UDim2.new(1, -34, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Font = T.FontBold, TextSize = 16,
		TextColor3 = T.Text, TextXAlignment = LEFT, TextWrapped = true, ZIndex = 3, Parent = head,
	})

	-- body (scrolls when the screen is too small for it)
	local scroll = new("ScrollingFrame", {
		LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
		ScrollBarImageColor3 = accent, CanvasSize = UDim2.new(), AutomaticCanvasSize = AY, ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 3, Parent = col,
	})
	local body = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, ZIndex = 3, Parent = scroll },
		{ list(10), padding(0, 0, 4, 0) })
	local contentL = new("TextLabel", {
		LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Font = T.Font, TextSize = 14,
		TextColor3 = T.SubText, TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, ZIndex = 3, Parent = body,
	})

	local box
	if cfg.Input then
		local ic = type(cfg.Input) == "table" and cfg.Input or {}
		local fr = new("Frame", { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, btnH), BackgroundColor3 = T.Control, BackgroundTransparency = 0.1, BorderSizePixel = 0, ZIndex = 3, Parent = body },
			{ corner(8), stroke(T.Border, 1, 0.3), padding(10, 0, 10, 0) })
		box = new("TextBox", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = tostring(ic.Default or ""), PlaceholderText = tostring(ic.Placeholder or ""),
			PlaceholderColor3 = T.SubText, TextColor3 = T.Text, Font = T.Font, TextSize = 14, TextXAlignment = LEFT, ClearTextOnFocus = false, ZIndex = 4, Parent = fr,
		})
		local maxLen = type(ic.MaxLength) == "number" and math.floor(ic.MaxLength) or 200
		bag:Add(box:GetPropertyChangedSignal("Text"):Connect(function()
			local t = box.Text
			if ic.Numeric then t = t:gsub("[^%d%.%-]", "") end
			if utf8.len(t) and utf8.len(t) > maxLen then t = Util.Truncate(t, maxLen, "") end
			if t ~= box.Text then box.Text = t end
		end))
		bag:Add(box.Focused:Connect(function() tween(fr:FindFirstChildOfClass("UIStroke"), 0.15, { Color = accent, Transparency = 0.05 }) end))
		bag:Add(box.FocusLost:Connect(function() tween(fr:FindFirstChildOfClass("UIStroke"), 0.2, { Color = T.Border, Transparency = 0.3 }) end))
		dlg.box = box
	end
	local custom
	if type(cfg.Build) == "function" then
		custom = new("Frame", { LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, ZIndex = 3, Parent = body })
	end

	-- buttons
	local buttons = type(cfg.Buttons) == "table" and cfg.Buttons or { { Text = "OK", Style = "Primary", Value = true } }
	local n = math.min(#buttons, 4)
	if n == 0 then buttons = { { Text = "OK", Style = "Primary", Value = true } } n = 1 end
	local vertical = n > 2 or W < 280
	local brow = new("Frame", { LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, ZIndex = 3, Parent = col },
		{ list(8, { FillDirection = vertical and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal }) })
	local btnObjs = {}

	local function finish(value, input, reason)
		if not dlg.open then return end
		dlg.open = false
		result.value, result.input, result.reason = value, input, reason
		for i, d in ipairs(self.Dialogs) do
			if d == dlg then table.remove(self.Dialogs, i) break end
		end
		local anim = NotifyCfg.Animate ~= false and not dlg.instant
		local function cleanup()
			bag:Destroy()
			pcall(function() overlay:Destroy() end)
		end
		if anim then
			tw(overlay, 0.18, { BackgroundTransparency = 1 }, SINE, IN)
			Anim.Hide(card, { To = "Bottom", Distance = 14, Time = 0.16, Scale = 0.97 })
			task.delay(0.22, cleanup)
		else
			cleanup()
		end
		if cfg.OnClose then safe(cfg.OnClose, value, input, reason) end
		for _, co in ipairs(waiters) do task.spawn(co, value, input) end
		waiters = {}
	end
	dlg.destroy = function() dlg.instant = true finish(nil, nil, "destroyed") end

	local function currentInput() return box and box.Text or nil end

	local defaultBtn
	for i = 1, n do
		local b = buttons[i]
		if type(b) == "string" then b = { Text = b } end
		if type(b) ~= "table" then b = { Text = "OK" } end
		local style = b.Style or (i == n and "Primary" or "Secondary")
		local fill = Color3.new(1, 1, 1)
		local btn = new("TextButton", {
			LayoutOrder = (vertical and (n - i + 1)) or i, AutoButtonColor = false, Text = "", BackgroundColor3 = style == "Secondary" and T.Control or fill,
			BackgroundTransparency = style == "Secondary" and 0.1 or 0, ZIndex = 3,
			Size = vertical and UDim2.new(1, 0, 0, btnH) or UDim2.new(1 / n, -math.ceil(8 * (n - 1) / n), 0, btnH), Parent = brow,
		}, { corner(8) })
		if style == "Secondary" then
			btn.BackgroundColor3 = T.Control
			new("UIStroke", { Color = T.Border, Thickness = 1, Transparency = 0.35, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = btn })
			feedback(btn, btn, "BackgroundColor3", T.Control, T.Lift, T.AccentSoft)
		else
			local c1 = style == "Danger" and Library.Kinds.Error.Color or accent
			gradient(c1, style == "Danger" and Util.Lighten(c1, 0.25) or accent2, 0).Parent = btn
			feedback(btn, btn, "BackgroundColor3", fill, Color3.fromRGB(236, 236, 236), Color3.fromRGB(200, 200, 200))
		end
		new("TextLabel", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = tostring(b.Text or "OK"), Font = style == "Secondary" and T.Font or T.FontBold,
			TextSize = 14, TextColor3 = style == "Secondary" and T.SubText or Color3.new(1, 1, 1), TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 4, Parent = btn,
		}, { padding(8, 0, 8, 0) })
		local value = b.Value
		if value == nil then value = b.Text end
		if b.Default or (style ~= "Secondary" and not defaultBtn) then defaultBtn = { btn = btn, b = b, value = value } end
		local function fire()
			if not dlg.open then return end
			if b.Callback then safe(b.Callback, handle, currentInput()) end
			if b.Close ~= false then finish(value, currentInput(), "button") end
		end
		bag:Add(btn.MouseButton1Click:Connect(fire))
		btnObjs[i] = { btn = btn, fire = fire }
	end
	if box then
		bag:Add(box.FocusLost:Connect(function(enter)
			if enter and defaultBtn then
				for _, bo in ipairs(btnObjs) do
					if bo.btn == defaultBtn.btn then bo.fire() end
				end
			end
		end))
	end

	local function setHead()
		titleL.Text = tostring(cfg.Title or "")
		head.Visible = (cfg.Title ~= nil and cfg.Title ~= "") or kind ~= nil or cfg.Icon ~= nil
		contentL.Text = tostring(cfg.Content or "")
		contentL.Visible = cfg.Content ~= nil and cfg.Content ~= ""
		for _, c in ipairs(iconSlot:GetChildren()) do c:Destroy() end
		local icon = cfg.Icon
		if icon == nil and kind then icon = Library.Kinds[kind].Icon end
		iconSlot.Visible = icon ~= nil and icon ~= false
		if iconSlot.Visible then buildIcon(iconSlot, icon, accent, T, 24, nil) end
	end
	setHead()
	if custom then
		local ok, err = pcall(cfg.Build, custom, T, handle)
		if not ok then warn("[SpectreUI] Dialog Build failed: " .. tostring(err)) end
	end

	-- size the scroll area so the whole card always fits the screen (small phones, landscape)
	local pending = false
	local function fit()
		if not dlg.open then return end
		local vp = Responsive.Viewport(owner)
		local used = head.AbsoluteSize.Y + brow.AbsoluteSize.Y + 12 * 2 + 18 + 16
		local avail = math.max(vp.Y - 24 - used, 48)
		local want = math.min(body.AbsoluteSize.Y, avail)
		if want > 0 and math.abs(scroll.Size.Y.Offset - want) > 0.5 then scroll.Size = UDim2.new(1, 0, 0, want) end
		local w = Responsive.Width(owner, math.floor(Util.Opt(cfg, "Width", "number", 340, 220, 560)), 16)
		if card.Size.X.Offset ~= w then card.Size = UDim2.fromOffset(w, 0) end
	end
	dlg.fit = fit
	local function fitSoon()
		if pending then return end
		pending = true
		task.defer(function() pending = false fit() end)
	end
	bag:Add(body:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitSoon))
	bag:Add(head:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitSoon))
	bag:Add(brow:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitSoon))
	bag:Add(gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitSoon))

	-- dismiss: tap outside / Esc (only the top-most dialog reacts)
	local function dismiss(reason)
		if dismissable and dlg.open then finish(nil, currentInput(), reason) end
	end
	bag:Add(outside.MouseButton1Click:Connect(function() dismiss("overlay") end))
	bag:Add(UserInputService.InputBegan:Connect(function(i)
		if i.KeyCode == Enum.KeyCode.Escape and self.Dialogs[#self.Dialogs] == dlg then dismiss("escape") end
	end))

	handle.Close = method(handle, function(value) finish(value, currentInput(), "api") return true end)
	handle.IsOpen = method(handle, function() return dlg.open end)
	handle.IsAlive = handle.IsOpen
	handle.GetInput = method(handle, function() return currentInput() end)
	handle.Update = method(handle, function(patch)
		if not dlg.open or type(patch) ~= "table" then return false end
		if patch.Title ~= nil then cfg.Title = patch.Title end
		if patch.Content ~= nil then cfg.Content = patch.Content end
		if patch.Kind ~= nil then
			kind = normKind(patch.Kind)
			cfg.Kind = patch.Kind
			accent = (kind and Library.Kinds[kind].Color) or T.Accent
		end
		if patch.Icon ~= nil then cfg.Icon = patch.Icon end
		setHead()
		return handle
	end)
	handle.Wait = method(handle, function()
		if not dlg.open then return result.value, result.input end
		table.insert(waiters, coroutine.running())
		return coroutine.yield()
	end)
	handle.Id = depth

	table.insert(self.Dialogs, dlg)
	-- open animation
	if NotifyCfg.Animate ~= false then
		tw(overlay, 0.22, { BackgroundTransparency = 0.5 }, SINE, OUT)
		Anim.Show(card, { From = "Bottom", Distance = 16, Time = 0.28, Scale = 0.96 })
	else
		overlay.BackgroundTransparency = 0.5
		card.Visible = true
		card.GroupTransparency = 0
	end
	if box and not touch and (type(cfg.Input) ~= "table" or cfg.Input.AutoFocus ~= false) then
		bag:Add(task.delay(0.25, function() if dlg.open and box.Parent then box:CaptureFocus() end end))
	end
	return handle
end

function NM:Confirm(cfg)
	if type(cfg) ~= "table" then cfg = {} end
	local choice
	return self:Dialog({
		Title = cfg.Title or "Confirm", Content = cfg.Content, Kind = cfg.Kind, Icon = cfg.Icon, Width = cfg.Width, Dismissable = cfg.Dismissable,
		Buttons = {
			{ Text = cfg.No or "Cancel", Style = "Secondary", Value = false, Callback = function() choice = false end },
			{ Text = cfg.Yes or "Confirm", Style = cfg.Danger and "Danger" or "Primary", Value = true, Callback = function() choice = true end },
		},
		OnClose = function(value, _, reason)
			if value == true then safe(cfg.OnYes) else safe(cfg.OnNo) end
			safe(cfg.OnClose, value == true, reason)
		end,
	})
end

function NM:Alert(cfg)
	if type(cfg) ~= "table" then cfg = {} end
	return self:Dialog({
		Title = cfg.Title or "Notice", Content = cfg.Content, Kind = cfg.Kind, Icon = cfg.Icon, Width = cfg.Width, Dismissable = cfg.Dismissable,
		Buttons = { { Text = cfg.Ok or "OK", Style = "Primary", Value = true } },
		OnClose = function(value, _, reason) safe(cfg.OnClose, value, reason) end,
	})
end

function NM:Prompt(cfg)
	if type(cfg) ~= "table" then cfg = {} end
	return self:Dialog({
		Title = cfg.Title or "Input", Content = cfg.Content, Kind = cfg.Kind, Icon = cfg.Icon, Width = cfg.Width, Dismissable = cfg.Dismissable,
		Input = { Placeholder = cfg.Placeholder, Default = cfg.Default, MaxLength = cfg.MaxLength, Numeric = cfg.Numeric, AutoFocus = cfg.AutoFocus },
		Buttons = {
			{ Text = cfg.No or "Cancel", Style = "Secondary", Value = false },
			{ Text = cfg.Yes or "OK", Style = "Primary", Value = true },
		},
		OnClose = function(value, input, reason)
			if value == true then safe(cfg.OnSubmit, input) else safe(cfg.OnCancel) end
			safe(cfg.OnClose, value == true and input or nil, reason)
		end,
	})
end

---------------------------------------------------------------- loading
-- Window:Loading({ Title, Text, Progress = 0..1 (nil = spinner only), Key, Position })
-- handle: :Set(progress, text) :SetText(text) :Complete(text, seconds) :Fail(text, seconds) :Close()
function NM:Loading(cfg)
	if type(cfg) == "string" then cfg = { Text = cfg } end
	if type(cfg) ~= "table" then cfg = {} end
	local c = table.clone(cfg)
	c.Kind = "Loading"
	c.Title = c.Title or "Loading"
	if c.Text ~= nil and c.Content == nil then c.Content = c.Text end
	c.Duration = false
	c.Closable = c.Closable == true
	if type(c.Progress) ~= "number" then c.Progress = nil end
	local h = self:Add(c, "loading")
	if not h or h.Id == 0 then return h end
	local nm = self
	local base = h
	local entryOf = function() return nm:_Each(function(e) return e.handle == base end) end
	local function patch(p)
		local e = entryOf()
		if not e then return false end
		return nm:_Update(e, p)
	end
	base.Set = method(base, function(progress, text)
		local p = {}
		if type(progress) == "number" then p.Progress = progress elseif progress == false then p.Progress = true end
		if text ~= nil then p.Content = text end
		return patch(p) and base or false
	end)
	base.SetText = method(base, function(text) return patch({ Content = text }) and base or false end)
	base.Complete = method(base, function(text, secs)
		return patch({ Kind = "Success", Title = "Done", Content = text or "", Progress = true, Duration = secs or 2.5, Closable = true }) and base or false
	end)
	base.Fail = method(base, function(text, secs)
		return patch({ Kind = "Error", Title = "Failed", Content = text or "", Progress = true, Duration = secs or 4, Closable = true }) and base or false
	end)
	return base
end

---------------------------------------------------------------- Window API
local function mergeCfg(first, extra, field)
	local cfg = {}
	if type(first) == "table" then
		for k, v in pairs(first) do cfg[k] = v end
	elseif first ~= nil then
		cfg[field or "Content"] = first
	end
	if type(extra) == "table" then
		for k, v in pairs(extra) do cfg[k] = v end
	elseif type(extra) == "string" then
		cfg.Kind = extra
	elseif type(extra) == "number" then
		cfg.Duration = extra
	end
	return cfg
end

function Window:_NM()
	if self._destroyed then return nil end
	if not self._nm or self._nm.Dead then self._nm = NM.new(self) end
	return self._nm
end

local function guarded(label, fn)
	local ok, res = pcall(fn)
	if ok and res then return res end
	if not ok then warn("[SpectreUI] " .. label .. " failed: " .. tostring(res)) end
	return deadHandle()
end

-- Window:Notify({ Title, Content, Kind, Duration, Icon, Color, Progress, Key, Position, OnClick, OnClose, ... }) -> handle
function Window:Notify(cfg)
	return guarded("Notify", function()
		local nm = self:_NM()
		return nm and nm:Add(cfg, "notify")
	end)
end

for kind in pairs({ Success = true, Warning = true, Error = true, Info = true }) do
	Window[kind] = function(self, title, content, dur)
		local cfg
		if type(title) == "table" then
			cfg = table.clone(title)
		else
			cfg = { Title = title, Content = content, Duration = dur }
		end
		cfg.Kind = kind
		return self:Notify(cfg)
	end
end

-- Window:Toast("Saved") / Toast("Saved", "Success") / Toast("Saved", 3) / Toast("Saved", { Kind, Duration, Icon })
function Window:Toast(text, opts)
	return guarded("Toast", function()
		local nm = self:_NM()
		return nm and nm:Add(mergeCfg(text, opts), "toast")
	end)
end

function Window:Banner(cfg)
	return guarded("Banner", function()
		local nm = self:_NM()
		return nm and nm:Add(mergeCfg(cfg, nil, "Title"), "banner")
	end)
end

function Window:Loading(cfg)
	return guarded("Loading", function()
		local nm = self:_NM()
		return nm and nm:Loading(cfg)
	end)
end

function Window:Dialog(cfg) return guarded("Dialog", function() local nm = self:_NM() return nm and nm:Dialog(cfg) end) end
function Window:Confirm(cfg) return guarded("Confirm", function() local nm = self:_NM() return nm and nm:Confirm(cfg) end) end
function Window:Alert(a, b)
	local cfg = type(a) == "table" and a or { Title = a, Content = b }
	return guarded("Alert", function() local nm = self:_NM() return nm and nm:Alert(cfg) end)
end
function Window:Prompt(cfg) return guarded("Prompt", function() local nm = self:_NM() return nm and nm:Prompt(cfg) end) end

-- dismiss every notification (and queued one) of this window
function Window:DismissAll(reason)
	if self._nm then self._nm:DismissAll(reason) end
end

-- own palette for this window's notifications / dialogs: Window:SetNotifyTheme("Cyber") or { Accent = ... }
-- (controls that already exist keep their colours; only what is shown afterwards changes)
function Window:SetNotifyTheme(t)
	if t == nil then
		self._nTheme = nil
		return true
	end
	local src = type(t) == "string" and Library.Themes[t] or t
	if type(src) ~= "table" then return false end
	self._nTheme = deriveTheme(buildTheme(src))
	return true
end

---------------------------------------------------------------- Library API
function Library:_Host()
	local w = self.Windows[#self.Windows]
	if w then return w:_NM() end
	if not self._nm or self._nm.Dead then self._nm = NM.new({ Headless = true }) end
	return self._nm
end

function Library:Notify(cfg) return guarded("Notify", function() return self:_Host():Add(cfg, "notify") end) end
function Library:Toast(text, opts) return guarded("Toast", function() return self:_Host():Add(mergeCfg(text, opts), "toast") end) end
function Library:Banner(cfg) return guarded("Banner", function() return self:_Host():Add(mergeCfg(cfg, nil, "Title"), "banner") end) end
function Library:Loading(cfg) return guarded("Loading", function() return self:_Host():Loading(cfg) end) end
function Library:Dialog(cfg) return guarded("Dialog", function() return self:_Host():Dialog(cfg) end) end
function Library:Confirm(cfg) return guarded("Confirm", function() return self:_Host():Confirm(cfg) end) end
function Library:Alert(a, b)
	local cfg = type(a) == "table" and a or { Title = a, Content = b }
	return guarded("Alert", function() return self:_Host():Alert(cfg) end)
end
function Library:Prompt(cfg) return guarded("Prompt", function() return self:_Host():Prompt(cfg) end) end

function Library:DismissAll(reason)
	for _, w in ipairs(self.Windows) do w:DismissAll(reason) end
	if self._nm then self._nm:DismissAll(reason) end
end

Library._NM = NM


------------------------------------------------------------------ tabs
function Window:CreateTab(cfg)
	if type(cfg) == "string" then cfg = { Name = cfg } end
	cfg = cfg or {}
	local T = self.Theme
	local tab = setmetatable({ Window = self, Name = cfg.Name or "Tab", Sections = {} }, Tab)

	local btn = new("TextButton", {
		LayoutOrder = #self.Tabs + 1, Size = UDim2.new(1, 0, 0, UserInputService.TouchEnabled and 46 or 40),
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, AutoButtonColor = false, Text = "", Parent = self.TabList,
	}, { corner(11), stroke(T.Accent, 1, 1), gradient(T.AccentSoft, T.AccentSoft, 0) })
	tab.Button = btn
	tab.BtnStroke = btn:FindFirstChildOfClass("UIStroke")
	tab.BtnGrad = btn:FindFirstChildOfClass("UIGradient")
	tab.Indicator = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0), Size = UDim2.new(0, 3, 0, 0),
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = btn,
	}, { corner(2), gradient(T.Accent, T.Accent2, 90) })

	local ic = cfg.Icon
	local function wrapIcon(el)
		return new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 26, 0.5, 0), Size = UDim2.fromOffset(24, 24),
			BackgroundTransparency = 1, Parent = btn,
		}, { new("UIScale", { Scale = 1, Name = "IS" }), el })
	end
	local iconDesc = Library:IsIconName(ic) and Library:ResolveIcon(ic) or nil
	if iconDesc then
		tab.Icon = Library:MakeIcon(iconDesc, T.SubText)
	elseif type(ic) == "number" or (type(ic) == "string" and ic:find("^rbxasset")) then
		tab.Icon = new("ImageLabel", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
			Image = type(ic) == "number" and ("rbxassetid://" .. ic) or ic, ImageColor3 = T.SubText,
		})
	else
		tab.Icon = new("TextLabel", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
			Text = (not Library:IsIconName(ic) and ic) or tab.Name:sub(1, 1):upper(), Font = T.FontBold, TextSize = 16, TextColor3 = T.SubText,
		})
	end
	tab.IconWrap = wrapIcon(tab.Icon)
	tab.IconScale = tab.IconWrap:FindFirstChild("IS")
	tab.Label = new("TextLabel", {
		Position = UDim2.fromOffset(46, 0), Size = UDim2.new(1, -52, 1, 0), BackgroundTransparency = 1, Text = tab.Name,
		Font = T.Font, TextSize = 14, TextColor3 = T.SubText, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = btn,
	})
	tab:_ApplyCompact(self.Compact or false)

	-- hover (PC) + press feedback (PC & mobile)
	local sc = new("UIScale", { Parent = btn })
	btn.MouseEnter:Connect(function()
		if usingTouch() or self.Active == tab then return end
		tween(tab.Label, 0.14, { TextColor3 = T.Text })
		tween(btn, 0.14, { BackgroundTransparency = 0.7 })
	end)
	btn.MouseLeave:Connect(function()
		if self.Active ~= tab then
			tween(tab.Label, 0.14, { TextColor3 = T.SubText })
			tween(btn, 0.16, { BackgroundTransparency = 1 })
		end
	end)
	-- dragSafePress: a finger that turns into a scroll no longer leaves the tab
	-- stuck with a visible pressed background (that was the "พื้นหลังขึ้น" bug).
	local press = dragSafePress(btn, function(i)
		tween(sc, 0.07, { Scale = 0.97 })
		if self.Active ~= tab then tween(btn, 0.06, { BackgroundTransparency = 0.5 }) end
	end, function(cancelled)
		tween(sc, 0.2, { Scale = 1 })
		if self.Active ~= tab then tween(btn, 0.16, { BackgroundTransparency = 1 }) end
	end, 12)
	clickRipple(btn, press)
	btn.MouseButton1Click:Connect(function()
		if press.moved then return end -- it was a scroll, not a tap
		self:SelectTab(tab)
	end)

	-- page
	tab.Page = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = self.Pages })
	tab.Scroll = new("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = UserInputService.TouchEnabled and 4 or 3,
		ScrollBarImageColor3 = T.Accent, CanvasSize = UDim2.new(), AutomaticCanvasSize = AY,
		ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.WhenScrollable, Parent = tab.Page,
	}, { padding(0, 0, 0, 8) })
	-- side margins are applied here (12 left + 20 right), NOT with UIPadding: a ScrollingFrame sizes
	-- scale children from the full canvas, so padding alone let the right column overflow the window
	local holder = new("Frame", { Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -32, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Parent = tab.Scroll },
		{ list(12, { FillDirection = Enum.FillDirection.Horizontal }) })
	tab.Cols = {}
	for i = 1, 2 do
		tab.Cols[i] = new("Frame", {
			LayoutOrder = i, Size = UDim2.new(0.5, -6, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Parent = holder,
		}, { list(12) })
	end

	table.insert(self.Tabs, tab)
	if not self.Active then self:SelectTab(tab) end
	return tab
end

function Tab:_ApplyCompact(c)
	self.Label.Visible = not c
	-- the icon now lives inside a wrapper (which carries the select pop), so move the wrapper
	self.IconWrap.Position = c and UDim2.fromScale(0.5, 0.5) or UDim2.new(0, 26, 0.5, 0)
end

function Tab:_SetSelected(sel)
	local T = self.Window.Theme
	tween(self.Button, 0.22, { BackgroundTransparency = sel and 0 or 1 })
	tween(self.BtnStroke, 0.22, { Transparency = sel and 0.3 or 1 })
	tween(self.Indicator, 0.26, { Size = UDim2.new(0, 3, sel and 0.55 or 0, 0) })
	tween(self.Label, 0.22, { TextColor3 = sel and T.Text or T.SubText })
	local prop = self.Icon:IsA("ImageLabel") and "ImageColor3" or "TextColor3"
	local icol = sel and T.Accent or T.SubText
	tween(self.Icon, 0.22, { [prop] = icol })
	for _, part in ipairs(self.Icon:GetChildren()) do
		if part:IsA("ImageLabel") then tween(part, 0.22, { ImageColor3 = icol }) end
	end
	-- gentle icon pop when a tab becomes active (one tween, no loop)
	if sel and self.IconScale and not lowPower() then
		self.IconScale.Scale = 0.7
		tween(self.IconScale, 0.32, { Scale = 1 }, BACK, OUT)
	end
	if self.BtnGrad then
		-- active tab gets a soft violet wash, idle stays flat
		self.BtnGrad.Color = sel
			and cseq({ 0, T.AccentSoft }, { 1, T.Wash })
			or cseq({ 0, T.AccentSoft }, { 1, T.AccentSoft })
	end
end

function Tab:_QueueRelayout()
	if self._rq then return end
	self._rq = true
	task.defer(function()
		self._rq = false
		self:_Relayout()
	end)
end

function Tab:_Relayout()
	local two = self.Window.TwoCol
	local c1, c2 = self.Cols[1], self.Cols[2]
	c2.Visible = two and true or false
	c1.Size = two and UDim2.new(0.5, -6, 0, 0) or UDim2.new(1, 0, 0, 0)
	local h1, h2 = 0, 0
	for i, s in ipairs(self.Sections) do
		local col
		if not two then col = 1
		elseif s.Column then col = s.Column
		else col = (h1 <= h2) and 1 or 2 end
		s.Frame.LayoutOrder = i
		s.Frame.Parent = (col == 1) and c1 or c2
		if s.Frame.Visible then
			if col == 1 then h1 += s.Est + 12 else h2 += s.Est + 12 end
		end
	end
end

------------------------------------------------------------------ sections
function Tab:CreateSection(cfg)
	if type(cfg) == "string" then cfg = { Name = cfg } end
	cfg = cfg or {}
	local T = self.Window.Theme
	local s = setmetatable({
		Tab = self, Window = self.Window, Name = cfg.Name or "Section", Controls = {}, Est = 35 + 20, Column = cfg.Column,
	}, Section)

	s.Frame = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundColor3 = T.Card, BackgroundTransparency = self.Window.FXOn and 0.2 or 0.12,
		BorderSizePixel = 0, Parent = self.Cols[1],
	}, { corner(12), stroke(T.Border, 1, 0.55), list(0, { HorizontalAlignment = Enum.HorizontalAlignment.Center }),
		wash(cseq({ 0, T.Top }, { 1, T.Card }), 90) })

	local collapsible = cfg.Collapsible ~= false
	local head = new("TextButton", {
		LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = T.Control, BackgroundTransparency = 1,
		Text = "", AutoButtonColor = false, Parent = s.Frame,
	}, { corner(12) })
	if collapsible then feedback(head, head, "BackgroundTransparency", 1, 0.85, 0.7, true) end
	-- accent dot before the title (or an icon when Icon = "lucide:..." is given)
	local secIcon = Library:IsIconName(cfg.Icon) and Library:ResolveIcon(cfg.Icon) or nil
	if secIcon then
		local im = Library:MakeIcon(secIcon, T.Accent)
		im.AnchorPoint = Vector2.new(0, 0.5)
		im.Position = UDim2.new(0, 10, 0.5, 0)
		im.Size = UDim2.fromOffset(18, 18)
		im.Parent = head
	else
		new("Frame", {
			AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.fromOffset(6, 6),
			BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = head,
		}, { corner(3), gradient(T.Accent, T.Accent2, 0) })
	end
	new("TextLabel", {
		Position = UDim2.fromOffset(secIcon and 34 or 26, 0), Size = UDim2.new(1, secIcon and -62 or -54, 1, 0), BackgroundTransparency = 1, Text = s.Name,
		Font = T.FontBold, TextSize = 14, TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = head,
	})
	local arrow = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(12, 12),
		BackgroundTransparency = 1, Text = "▼", Font = T.FontBold, TextSize = 10, TextColor3 = T.Accent,
		Visible = collapsible, Parent = head,
	})
	-- gradient hairline under the section header
	new("Frame", {
		LayoutOrder = 2, Size = UDim2.new(1, -24, 0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.55,
		BorderSizePixel = 0, Parent = s.Frame,
	}, { gradient(cseq({ 0, T.Accent }, { 0.6, T.Accent2 }, { 1, T.Border }), 0) })
	s.Body = new("Frame", {
		LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Parent = s.Frame,
	}, { list(8), padding(12, 12, 12, 14) })

	-- smooth collapse / expand: the body's height is tweened, then auto-size takes over again
	function s:SetCollapsed(c, instant)
		c = c and true or false
		local cur = self.Collapsed and true or false
		self.Collapsed = c
		tween(arrow, 0.22, { Rotation = c and -90 or 0 })
		if c == cur then
			self.Body.Visible = not c
			return
		end
		local b = self.Body
		self._cseq = (self._cseq or 0) + 1
		local seq = self._cseq
		if c then
			local h = b.AbsoluteSize.Y
			if instant or h <= 0 or not b.Visible then
				b.Visible = false
				return
			end
			self._bodyH = h
			b.ClipsDescendants = true
			b.AutomaticSize = ANONE
			b.Size = UDim2.new(1, 0, 0, h)
			tween(b, 0.24, { Size = UDim2.new(1, 0, 0, 0) }, QUINT, OUT).Completed:Connect(function()
				if self._cseq == seq then b.Visible = false end
			end)
		else
			b.Visible = true
			local h = self._bodyH
			if instant or not h then
				b.ClipsDescendants = false
				b.AutomaticSize = AY
				b.Size = UDim2.new(1, 0, 0, 0)
				return
			end
			b.ClipsDescendants = true
			b.AutomaticSize = ANONE
			b.Size = UDim2.new(1, 0, 0, 0)
			tween(b, 0.28, { Size = UDim2.new(1, 0, 0, h) }, QUINT, OUT).Completed:Connect(function()
				if self._cseq ~= seq then return end
				b.AutomaticSize = AY
				b.Size = UDim2.new(1, 0, 0, 0)
				b.ClipsDescendants = false
			end)
		end
	end
	if collapsible then
		head.MouseButton1Click:Connect(function() s:SetCollapsed(not s.Collapsed) end)
	end
	if cfg.Collapsed then s:SetCollapsed(true, true) end

	table.insert(self.Sections, s)
	self:_QueueRelayout()
	return s
end

function Section:_Register(frame, name, est)
	table.insert(self.Controls, { Frame = frame, Name = (name or ""):lower() })
	frame.LayoutOrder = #self.Controls
	self.Est += est + 6
	self.Tab:_QueueRelayout()
end

local function setFlag(cfg, v)
	if cfg.Flag then
		local prev = Library.Flags[cfg.Flag]
		Library.Flags[cfg.Flag] = v
		if prev ~= v then
			for _, cb in ipairs(Library._flagCbs) do safe(cb, cfg.Flag, v, prev) end
		end
	end
end

-- controls with a Flag are remembered so configs can be saved / loaded
local function regObj(cfg, obj)
	if cfg.Flag then Library.Objects[cfg.Flag] = obj end
	return obj
end

------------------------------------------------------------------ controls
function Section:CreateLabel(cfg)
	if type(cfg) == "string" then cfg = { Text = cfg } end
	cfg = cfg or {}
	local T = self.Window.Theme
	local l = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Text = cfg.Text or cfg.Name or "",
		Font = cfg.Bold and T.FontBold or T.Font, TextSize = cfg.TextSize or 13, TextColor3 = cfg.Color or T.SubText,
		TextXAlignment = LEFT, TextWrapped = true, Parent = self.Body,
	})
	self:_Register(l, cfg.Text or cfg.Name, 18)
	local obj = { Frame = l }
	function obj:Set(t) l.Text = t end
	-- live recolor, so a status label can turn red/green without rebuilding it
	function obj:SetColor(c) l.TextColor3 = c end
	return obj
end

function Section:CreateDivider()
	local T = self.Window.Theme
	local d = new("Frame", {
		Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.45, BorderSizePixel = 0, Parent = self.Body,
	}, { gradient(cseq({ 0, Color3.new(1, 1, 1) }, { 0.5, T.Accent }, { 1, Color3.new(1, 1, 1) }), 0) })
	d:FindFirstChildOfClass("UIGradient").Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 0.5),
	})
	self:_Register(d, "", 1)
end

-- CreateButton({ Name, Callback, Color, Gradient, TextColor })
-- Color makes a solid accent button; Gradient = {a, b} makes a gradient one.
function Section:CreateButton(cfg)
	local T = self.Window.Theme
	local accent = cfg.Color
	local grad = cfg.Gradient
	local gradLabel
	local b = new("TextButton", {
		Size = UDim2.new(1, 0, 0, rowH()), BackgroundColor3 = grad and Color3.new(1, 1, 1) or (accent or T.Control),
		BackgroundTransparency = 0.1, AutoButtonColor = false,
		Text = cfg.Name or "Button", Font = cfg.Bold and T.FontBold or T.Font, TextSize = 13,
		TextColor3 = cfg.TextColor or T.Text, Parent = self.Body,
	}, { corner(7), stroke(grad and (grad[2] or T.Accent2) or (accent and accent:Lerp(Color3.new(1, 1, 1), 0.3) or T.Border), 1, grad and 0.5 or 0.35) })
	if grad then
		-- gradient needs the frame background visible (transparency stays low, not 1)
		b.BackgroundColor3 = Color3.new(1, 1, 1)
		b.BackgroundTransparency = 0
		new("UIGradient", { Color = ColorSequence.new(grad[1], grad[2] or grad[1]), Parent = b })
		-- UIGradient tints the parent's own text too, so draw the text on a child label instead
		b.Text = ""
		gradLabel = new("TextLabel", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = cfg.Name or "Button",
			Font = cfg.Bold and T.FontBold or T.Font, TextSize = 13, TextColor3 = cfg.TextColor or Color3.new(1, 1, 1), Parent = b,
		})
	end
	local bIcon = Library:IsIconName(cfg.Icon) and Library:ResolveIcon(cfg.Icon) or nil
	if bIcon then
		local im = Library:MakeIcon(bIcon, cfg.TextColor or (grad and Color3.new(1, 1, 1)) or T.Text)
		im.AnchorPoint = Vector2.new(0, 0.5)
		im.Position = UDim2.new(0, 10, 0.5, 0)
		im.Size = UDim2.fromOffset(16, 16)
		im.ZIndex = b.ZIndex + 1
		im.Parent = b
	end
	-- top highlight for depth
	if not grad then
		new("Frame", {
			Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.Sheen, BackgroundTransparency = 0.85, BorderSizePixel = 0, Parent = b,
		}, { corner(1) })
	end
	local bStroke = b:FindFirstChildOfClass("UIStroke")
	if grad or accent then
		strokeFeedback(b, bStroke, grad and 0.5 or 0.3, 0.05)
	else
		feedback(b, b, "BackgroundColor3", T.Control, T.Lift, T.AccentSoft)
		strokeFeedback(b, bStroke, 0.35, 0.05)
	end
	b.MouseButton1Click:Connect(function() safe(cfg.Callback) end)
	clickRipple(b, nil)
	self:_Register(b, cfg.Name, rowH())
	local obj = { Frame = b }
	function obj:SetText(t)
		if gradLabel then gradLabel.Text = t else b.Text = t end
	end
	return obj
end

function Section:CreateToggle(cfg)
	local T = self.Window.Theme
	local h = rowH()
	local value = cfg.Default and true or false
	local ON_POS, OFF_POS = UDim2.new(1, -19, 0.5, 0), UDim2.new(0, 3, 0.5, 0)
	local row = new("TextButton", {
		Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = T.Control, BackgroundTransparency = 1, Text = "",
		AutoButtonColor = false, Parent = self.Body,
	}, { corner(9) })
	feedback(row, row, "BackgroundTransparency", 1, 0.82, 0.62, true)
	new("TextLabel", {
		Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -62, 1, 0), BackgroundTransparency = 1, Text = cfg.Name or "Toggle",
		Font = T.Font, TextSize = 14, TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
	})
	local track = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(42, 22),
		BackgroundColor3 = value and T.Accent or T.Control, BorderSizePixel = 0, Parent = row,
	}, { corner(11), stroke(T.Border, 1, 0.6) })
	local trackGrad = gradient(T.Accent, T.Accent2, 0)
	trackGrad.Parent = track
	trackGrad.Transparency = value and NumberSequence.new(0) or NumberSequence.new(1)
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = value and ON_POS or OFF_POS,
		Size = UDim2.fromOffset(16, 16), BackgroundColor3 = T.Knob, BorderSizePixel = 0, Parent = track,
	}, { corner(8), stroke(T.Accent, 1.5, 0.4) })
	local knobStroke = knob:FindFirstChildOfClass("UIStroke")

	local obj = {}
	function obj:Set(v, silent)
		value = v and true or false
		tween(track, 0.22, { BackgroundColor3 = value and T.Accent or T.Control })
		trackGrad.Transparency = value and NumberSequence.new(0) or NumberSequence.new(1)
		tween(knob, 0.24, { Position = value and ON_POS or OFF_POS })
		tween(knobStroke, 0.22, { Transparency = value and 0 or 0.5 })
		setFlag(cfg, value)
		if not silent then safe(cfg.Callback, value) end
	end
	function obj:Get() return value end
	row.MouseButton1Click:Connect(function() obj:Set(not value) end)
	setFlag(cfg, value)
	self:_Register(row, cfg.Name, h)
	obj.Frame = row
	return regObj(cfg, obj)
end

function Section:CreateSlider(cfg)
	local T = self.Window.Theme
	local tab = self.Tab
	local min, max, inc = cfg.Min or 0, cfg.Max or 100, cfg.Increment or 1
	local value = snap(cfg.Default or min, min, max, inc)
	local suffix = cfg.Suffix or ""
	local touch = UserInputService.TouchEnabled
	local total = touch and 50 or 42
	local knobS, knobBig = touch and 16 or 12, touch and 20 or 15

	local frame = new("Frame", { Size = UDim2.new(1, 0, 0, total), BackgroundTransparency = 1, Parent = self.Body })
	new("TextLabel", {
		Size = UDim2.new(1, -70, 0, 18), BackgroundTransparency = 1, Text = cfg.Name or "Slider", Font = T.Font, TextSize = 14,
		TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
	})
	local valLabel = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(66, 18), BackgroundTransparency = 1,
		Text = tostring(value) .. suffix, Font = T.FontBold, TextSize = 13, TextColor3 = T.Accent, TextXAlignment = Enum.TextXAlignment.Right, Parent = frame,
	})
	local hit = new("TextButton", {
		Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 1, -20), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = frame,
	})
	local track = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(1, 0, 0, 4),
		BackgroundColor3 = T.Control, BorderSizePixel = 0, Parent = hit,
	}, { corner(2) })
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = track },
		{ corner(2), gradient(T.Accent, T.Accent2, 0) })
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(knobS, knobS),
		BackgroundColor3 = T.Knob, BorderSizePixel = 0, ZIndex = 2, Parent = track,
	}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }), stroke(T.Accent, 2, 0) })

	local obj = {}
	local function render(v, animate)
		local a = (max == min) and 0 or (v - min) / (max - min)
		valLabel.Text = tostring(v) .. suffix
		if animate then
			tween(fill, 0.18, { Size = UDim2.fromScale(a, 1) })
			tween(knob, 0.18, { Position = UDim2.fromScale(a, 0.5) })
		else
			fill.Size = UDim2.fromScale(a, 1)
			knob.Position = UDim2.fromScale(a, 0.5)
		end
	end
	function obj:Set(v, silent)
		v = snap(v, min, max, inc)
		local changed = v ~= value
		value = v
		render(v, true)
		setFlag(cfg, v)
		if changed and not silent then safe(cfg.Callback, v) end
	end
	function obj:Get() return value end
	render(value, false)
	setFlag(cfg, value)

	-- dragging updates instantly (no tween) so the knob never lags behind the pointer
	local function fromX(x)
		local a = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		local v = snap(min + (max - min) * a, min, max, inc)
		if v ~= value then
			value = v
			render(v, false)
			setFlag(cfg, v)
			safe(cfg.Callback, v)
		end
	end

	local moveC, endC
	local function stop()
		if moveC then moveC:Disconnect() moveC = nil end
		if endC then endC:Disconnect() endC = nil end
		tab.Scroll.ScrollingEnabled = true
		tween(knob, 0.16, { Size = UDim2.fromOffset(knobS, knobS) })
	end
	hit.InputBegan:Connect(function(i)
		if not isPress(i) then return end
		stop()
		local isTouch = i.UserInputType == Enum.UserInputType.Touch
		tab.Scroll.ScrollingEnabled = false -- the page must not scroll while a slider is held
		tween(knob, 0.12, { Size = UDim2.fromOffset(knobBig, knobBig) })
		fromX(i.Position.X)
		moveC = UserInputService.InputChanged:Connect(function(m)
			if isTouch then
				if m ~= i then return end -- only follow the finger that grabbed the slider
			elseif m.UserInputType ~= Enum.UserInputType.MouseMovement then
				return
			end
			fromX(m.Position.X)
		end)
		endC = onEnd(i, stop)
	end)

	self:_Register(frame, cfg.Name, total)
	obj.Frame = frame
	return regObj(cfg, obj)
end

function Section:CreateDropdown(cfg)
	local T = self.Window.Theme
	local win = self.Window
	local tab = self.Tab
	local touch = UserInputService.TouchEnabled
	local h = rowH()
	local optH = touch and 38 or 30
	local searchH = touch and 42 or 36
	local footH = touch and 46 or 40
	local GAP, PAD = 2, 8
	local options = cfg.Options or {}
	local multi = cfg.Multi and true or false
	local placeholder = cfg.Placeholder or "Select..."
	local value = multi and {} or nil -- multi: set { [option] = true }
	local selText = T.Accent:Lerp(Color3.new(1, 1, 1), 0.55)

	local function isSel(o)
		if multi then return value[o] == true end
		return o == value
	end
	local function selectedList()
		local out = {}
		for _, o in ipairs(options) do
			if value[o] then table.insert(out, o) end
		end
		return out
	end
	-- search box shows automatically with many options (override: Searchable = true / false)
	local function searchOn()
		if cfg.Searchable ~= nil then return cfg.Searchable and true or false end
		return #options > 6
	end
	local function chrome()
		return searchOn() and searchH or 0, multi and footH or 0
	end

	local frame = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Parent = self.Body }, { list(4) })
	if cfg.Name then
		new("TextLabel", {
			LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = cfg.Name, Font = T.Font, TextSize = 14,
			TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
		})
	end
	local btn = new("TextButton", {
		LayoutOrder = 2, Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = T.Control, BackgroundTransparency = 0.1,
		AutoButtonColor = false, Text = "", Parent = frame,
	}, { corner(7), stroke(T.Border, 1, 0.35) })
	local btnStroke = btn:FindFirstChildOfClass("UIStroke")
	feedback(btn, btn, "BackgroundColor3", T.Control, T.Lift, T.AccentSoft)
	local txt = new("TextLabel", {
		Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -32, 1, 0), BackgroundTransparency = 1, Text = placeholder,
		Font = T.Font, TextSize = 13, TextColor3 = T.SubText, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = btn,
	})
	local badge = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -28, 0.5, 0), Size = UDim2.fromOffset(22, 18),
		BackgroundColor3 = T.AccentSoft, BorderSizePixel = 0, Visible = false, Parent = btn,
	}, { corner(9), gradient(T.Accent, T.Accent2, 0) })
	local badgeLbl = new("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "0", Font = T.FontBold, TextSize = 11,
		TextColor3 = Color3.new(1, 1, 1), Parent = badge,
	})
	local arrow = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(12, 12),
		BackgroundTransparency = 1, Text = "▶", Font = T.FontBold, TextSize = 10, TextColor3 = T.Accent, Parent = btn,
	})

	local dd = { IsOpen = false }
	local popup, popupStroke, scroll, searchHolder, searchBox, emptyLbl
	local rows = {}
	local popW, maxH = 190, 240
	local escC

	local function refreshText()
		if multi then
			local out = selectedList()
			if #out == 0 then
				txt.Text, txt.TextColor3 = placeholder, T.SubText
			else
				local names = {}
				for i, o in ipairs(out) do names[i] = tostring(o) end
				txt.Text, txt.TextColor3 = table.concat(names, ", "), T.Text
			end
			local showBadge = #out > 1
			badge.Visible = showBadge
			badgeLbl.Text = tostring(#out)
			txt.Size = UDim2.new(1, showBadge and -62 or -32, 1, 0)
		else
			txt.Text = value ~= nil and tostring(value) or placeholder
			txt.TextColor3 = value ~= nil and T.Text or T.SubText
		end
	end

	local function paint()
		for opt, r in pairs(rows) do
			local sel = isSel(opt)
			tween(r.btn, 0.16, { BackgroundTransparency = sel and 0 or 1 })
			tween(r.bar, 0.16, { BackgroundTransparency = sel and 0 or 1 })
			tween(r.label, 0.16, { TextColor3 = sel and selText or T.Text })
			tween(r.check, 0.16, { TextTransparency = sel and 0 or 1 })
			if multi then
				tween(r.box, 0.16, { BackgroundColor3 = sel and T.Accent or T.Control })
				tween(r.boxStroke, 0.16, { Color = sel and T.Accent or T.Border })
			end
		end
	end

	local function visibleCount()
		local n = 0
		for _, r in pairs(rows) do
			if r.btn.Visible then n = n + 1 end
		end
		return n
	end

	-- resize the popup to the visible rows (clamped to the space available)
	local function fit()
		if not popup then return end
		local top, bot = chrome()
		local n = visibleCount()
		emptyLbl.Visible = n == 0
		local rowsH = math.max(n, 1) * (optH + GAP) + PAD
		local ph = math.clamp(top + bot + rowsH, math.min(top + bot + optH + PAD, maxH), maxH)
		tween(popup, 0.2, { Size = UDim2.fromOffset(popW, ph) })
	end

	local function applyChrome()
		local top, bot = chrome()
		searchHolder.Visible = top > 0
		scroll.Position = UDim2.fromOffset(0, top)
		scroll.Size = UDim2.new(1, 0, 1, -(top + bot))
	end

	local function applyFilter()
		local q = searchBox.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
		for opt, r in pairs(rows) do
			r.btn.Visible = q == "" or tostring(opt):lower():find(q, 1, true) ~= nil
		end
		emptyLbl.Visible = visibleCount() == 0
		if dd.IsOpen then
			fit()
			scroll.CanvasPosition = Vector2.new()
		end
	end

	local function buildOptions()
		for _, r in pairs(rows) do r.btn:Destroy() end
		rows = {}
		for i, opt in ipairs(options) do
			local b = new("TextButton", {
				LayoutOrder = i, Size = UDim2.new(1, 0, 0, optH), BackgroundColor3 = T.AccentSoft, BackgroundTransparency = 1,
				AutoButtonColor = false, Text = "", Parent = scroll,
			}, { corner(6) })
			local bar = new("Frame", {
				AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(0, 3, 0.55, 0),
				BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = b,
			}, { corner(2), gradient(T.Accent, T.Accent2, 90) })
			local lbl = new("TextLabel", {
				Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -44, 1, 0), BackgroundTransparency = 1, Text = tostring(opt),
				Font = T.Font, TextSize = 13, TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = b,
			})
			local r = { btn = b, bar = bar, label = lbl }
			if multi then
				r.box = new("Frame", {
					AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(18, 18),
					BackgroundColor3 = T.Control, BorderSizePixel = 0, Parent = b,
				}, { corner(5), stroke(T.Border, 1, 0) })
				r.boxStroke = r.box:FindFirstChildOfClass("UIStroke")
				r.check = new("TextLabel", {
					Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "✓", Font = T.FontBold, TextSize = 13,
					TextColor3 = Color3.new(1, 1, 1), TextTransparency = 1, Parent = r.box,
				})
			else
				r.check = new("TextLabel", {
					AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(16, 16),
					BackgroundTransparency = 1, Text = "✓", Font = T.FontBold, TextSize = 15, TextColor3 = T.Accent,
					TextTransparency = 1, Parent = b,
				})
			end
			b.MouseEnter:Connect(function()
				if usingTouch() or isSel(opt) then return end
				tween(b, 0.12, { BackgroundTransparency = 0.6 })
			end)
			b.MouseLeave:Connect(function()
				if not isSel(opt) then tween(b, 0.14, { BackgroundTransparency = 1 }) end
			end)
			bindPress(b, function()
				if not isSel(opt) then tween(b, 0.05, { BackgroundTransparency = 0.35 }) end
			end, function()
				if not isSel(opt) then tween(b, 0.16, { BackgroundTransparency = 1 }) end
			end)
			b.MouseButton1Click:Connect(function()
				if multi then
					local cur = selectedList()
					local found = false
					for idx, o in ipairs(cur) do
						if o == opt then table.remove(cur, idx) found = true break end
					end
					if not found then table.insert(cur, opt) end
					dd:Set(cur)
				else
					dd:Set(opt)
					dd:Close()
				end
			end)
			rows[opt] = r
		end
		paint()
	end

	local function build()
		popup = new("Frame", {
			Visible = false, ZIndex = 61, BackgroundColor3 = T.Panel, BorderSizePixel = 0, ClipsDescendants = true,
			Active = true, Parent = win.Gui,
		}, { corner(9), stroke(T.Accent, 1, 0.35),
			wash(cseq({ 0, T.Top }, { 1, T.Panel }), 90) })
		popupStroke = popup:FindFirstChildOfClass("UIStroke")

		searchHolder = new("Frame", { Size = UDim2.new(1, 0, 0, searchH), BackgroundTransparency = 1, Parent = popup }, { padding(6, 6, 6, 2) })
		searchBox = new("TextBox", {
			Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Control, Text = "", PlaceholderText = "Search...",
			PlaceholderColor3 = T.SubText, TextColor3 = T.Text, Font = T.Font, TextSize = 13, TextXAlignment = LEFT,
			ClearTextOnFocus = false, Parent = searchHolder,
		}, { corner(6), stroke(T.Border, 1, 0.4), padding(10, 0, 10, 0) })

		scroll = new("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = touch and 4 or 3,
			ScrollBarImageColor3 = T.Accent, CanvasSize = UDim2.new(), AutomaticCanvasSize = AY,
			ScrollingDirection = Enum.ScrollingDirection.Y, Parent = popup,
		}, { list(GAP), padding(4, 4, 6, 4) })
		emptyLbl = new("TextLabel", {
			LayoutOrder = 0, Size = UDim2.new(1, 0, 0, optH), BackgroundTransparency = 1, Text = "No results", Font = T.Font,
			TextSize = 13, TextColor3 = T.SubText, Visible = false, Parent = scroll,
		})

		if multi then
			new("Frame", {
				AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, -footH), Size = UDim2.new(1, 0, 0, 1),
				BackgroundColor3 = T.Border, BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = popup,
			})
			local footer = new("Frame", {
				AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, footH),
				BackgroundTransparency = 1, Parent = popup,
			}, { padding(6, 5, 6, 6) })
			local clear = new("TextButton", {
				Size = UDim2.new(0.38, -3, 1, 0), BackgroundColor3 = T.Control, AutoButtonColor = false, Text = "Clear",
				Font = T.Font, TextSize = 13, TextColor3 = T.SubText, Parent = footer,
			}, { corner(6) })
			feedback(clear, clear, "BackgroundColor3", T.Control, T.Lift, T.AccentSoft)
			local done = new("TextButton", {
				Position = UDim2.new(0.38, 3, 0, 0), Size = UDim2.new(0.62, -3, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1),
				AutoButtonColor = false, Text = "", Parent = footer,
			}, { corner(6), gradient(T.Accent, T.Accent2, 0), stroke(T.Accent2, 1, 0.6) })
			-- UIGradient tints the parent's own text too (it made "Done" vanish), so the label is a separate child
			new("TextLabel", {
				Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "Done", Font = T.FontBold, TextSize = 13,
				TextColor3 = Color3.new(1, 1, 1), ZIndex = 2, Parent = done,
			})
			strokeFeedback(done, done:FindFirstChildOfClass("UIStroke"), 0.6, 0.15)
			clear.MouseButton1Click:Connect(function() dd:Set({}) end)
			done.MouseButton1Click:Connect(function() dd:Close() end)
		end

		searchBox:GetPropertyChangedSignal("Text"):Connect(applyFilter)
		searchBox.FocusLost:Connect(function(enter)
			if enter and not multi then -- Enter picks the first match
				for _, opt in ipairs(options) do
					local r = rows[opt]
					if r and r.btn.Visible then
						dd:Set(opt)
						dd:Close()
						return
					end
				end
			end
		end)
		buildOptions()
	end

	function dd:Open()
		if self.IsOpen then return end
		win:CloseDropdowns()
		if not popup then build() end
		applyChrome()
		searchBox.Text = ""
		for _, r in pairs(rows) do r.btn.Visible = true end
		emptyLbl.Visible = #options == 0

		local top, bot = chrome()
		local pos, size = btn.AbsolutePosition, btn.AbsoluteSize
		local vp = win.Gui.AbsoluteSize
		local cap = touch and 280 or 240
		local minH = top + bot + optH + PAD
		local want = math.min(top + bot + math.max(#options, 1) * (optH + GAP) + PAD, cap)
		local below = vp.Y - (pos.Y + size.Y + 4) - 8
		local above = pos.Y - 4 - 8
		local down = want <= below or below >= above
		maxH = math.max(math.min(cap, down and below or above), math.min(minH, vp.Y - 16))
		popW = math.min(math.max(size.X, 190), vp.X - 12)
		local x = math.clamp(pos.X, 6, math.max(6, vp.X - popW - 6))

		if not popup.Visible then
			popup.Size = UDim2.fromOffset(popW, 0)
			popup.BackgroundTransparency = 1
			popupStroke.Transparency = 1
		end
		popup.AnchorPoint = Vector2.new(0, down and 0 or 1)
		popup.Position = down and UDim2.fromOffset(x, pos.Y + size.Y + 4) or UDim2.fromOffset(x, pos.Y - 4)
		popup.Visible = true
		win.Overlay.BackgroundColor3 = Color3.new(0, 0, 0)
		win.Overlay.BackgroundTransparency = 1
		win.Overlay.Visible = true
		tween(win.Overlay, 0.2, { BackgroundTransparency = 0.62 }, QUAD, OUT)
		tab.Scroll.ScrollingEnabled = false -- the page behind must not move while the popup is open
		self.IsOpen = true
		win._dd = self

		fit()
		tween(popup, 0.2, { BackgroundTransparency = 0 })
		tween(popupStroke, 0.2, { Transparency = 0.35 })
		tween(arrow, 0.2, { Rotation = 90 })
		tween(btnStroke, 0.2, { Color = T.Accent, Transparency = 0.2 })

		escC = UserInputService.InputBegan:Connect(function(i)
			if i.KeyCode == Enum.KeyCode.Escape then dd:Close() end
		end)

		-- bring the selected row into view
		task.delay(0.03, function()
			if not self.IsOpen then return end
			local idx
			for n, o in ipairs(options) do
				if isSel(o) then idx = n break end
			end
			if idx then scroll.CanvasPosition = Vector2.new(0, math.max(0, (idx - 2) * (optH + GAP))) end
		end)
		-- PC: start typing straight away (not on touch, the keyboard would cover the list)
		if not touch and searchOn() then
			task.delay(0.03, function()
				if self.IsOpen then searchBox:CaptureFocus() end
			end)
		end
	end

	function dd:Close()
		if not self.IsOpen then return end
		self.IsOpen = false
		if win._dd == self then win._dd = nil end
		if escC then escC:Disconnect() escC = nil end
		if searchBox then searchBox:ReleaseFocus() end
		win.Overlay.Visible = false
		tween(win.Overlay, 0.02, { BackgroundTransparency = 1 })
		tab.Scroll.ScrollingEnabled = true
		tween(arrow, 0.18, { Rotation = 0 })
		tween(btnStroke, 0.18, { Color = T.Border, Transparency = 0.35 })
		if popup then
			tween(popupStroke, 0.14, { Transparency = 1 }, QUAD, IN)
			tween(popup, 0.14, { Size = UDim2.fromOffset(popW, 0), BackgroundTransparency = 1 }, QUAD, IN).Completed:Connect(function()
				if not self.IsOpen then popup.Visible = false end
			end)
		end
	end

	function dd:Set(v, silent)
		local out
		if multi then
			value = {}
			if type(v) == "table" then
				for k, x in pairs(v) do
					if x == true then value[k] = true else value[x] = true end -- accepts { "a" } or { a = true }
				end
			end
			out = selectedList()
		else
			value = v
			out = v
		end
		refreshText()
		paint()
		setFlag(cfg, out)
		if not silent then safe(cfg.Callback, out) end
	end
	function dd:Get()
		if multi then return selectedList() end
		return value
	end
	function dd:Refresh(newOptions, keep)
		options = newOptions or {}
		if not keep then
			self:Set(nil, true)
		elseif multi then
			self:Set(selectedList(), true) -- drop selections that no longer exist
		end
		if popup then
			buildOptions()
			applyChrome()
			if self.IsOpen then
				searchBox.Text = ""
				fit()
			end
		end
	end

	btn.MouseButton1Click:Connect(function()
		if dd.IsOpen then dd:Close() else dd:Open() end
	end)

	if cfg.Default ~= nil then
		dd:Set(cfg.Default, true)
	elseif multi then
		dd:Set({}, true)
	end
	setFlag(cfg, dd:Get())
	self:_Register(frame, cfg.Name, h + (cfg.Name and 20 or 0))
	dd.Frame = frame
	return regObj(cfg, dd)
end

------------------------------------------------------------------ new controls (v3)
function Section:CreateParagraph(cfg)
	cfg = cfg or {}
	local T = self.Window.Theme
	local frame = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Parent = self.Body }, { list(2) })
	local title = new("TextLabel", {
		LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Text = cfg.Title or "",
		Font = T.FontBold, TextSize = 14, TextColor3 = T.Text, TextXAlignment = LEFT, TextWrapped = true, Parent = frame,
	})
	local body = new("TextLabel", {
		LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Text = cfg.Content or "",
		Font = T.Font, TextSize = 13, TextColor3 = T.SubText, TextXAlignment = LEFT, TextWrapped = true, Parent = frame,
	})
	self:_Register(frame, cfg.Title, 40)
	local obj = { Frame = frame }
	function obj:Set(t, c)
		if t ~= nil then title.Text = t end
		if c ~= nil then body.Text = c end
	end
	return obj
end

function Section:CreateTextbox(cfg)
	cfg = cfg or {}
	local T = self.Window.Theme
	local h = rowH()
	local value
	if cfg.Numeric then
		value = tonumber(cfg.Default) or cfg.Min or 0
	else
		value = cfg.Default ~= nil and tostring(cfg.Default) or ""
	end

	local frame = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Parent = self.Body }, { list(4) })
	if cfg.Name then
		new("TextLabel", {
			LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = cfg.Name, Font = T.Font, TextSize = 14,
			TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
		})
	end
	local boxFrame = new("Frame", {
		LayoutOrder = 2, Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = T.Control, BackgroundTransparency = 0.1, Parent = frame,
	}, { corner(7), stroke(T.Border, 1, 0.35) })
	local bStroke = boxFrame:FindFirstChildOfClass("UIStroke")
	local box = new("TextBox", {
		Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 1, 0), BackgroundTransparency = 1, Text = tostring(value),
		PlaceholderText = cfg.Placeholder or "", PlaceholderColor3 = T.SubText, ClearTextOnFocus = cfg.ClearOnFocus == true,
		Font = T.Font, TextSize = 13, TextColor3 = T.Text, TextXAlignment = LEFT, ClipsDescendants = true, Parent = boxFrame,
	})

	-- returns true when the text was accepted
	local function apply(v)
		if cfg.Numeric then
			local n = tonumber(v)
			if n == nil then return false end
			if cfg.Min then n = math.max(n, cfg.Min) end
			if cfg.Max then n = math.min(n, cfg.Max) end
			value = n
		else
			v = tostring(v == nil and "" or v)
			if cfg.MaxLength then v = v:sub(1, cfg.MaxLength) end
			value = v
		end
		box.Text = tostring(value)
		return true
	end

	local obj = {}
	function obj:Set(v, silent)
		if not apply(v) then return end
		setFlag(cfg, value)
		if not silent then safe(cfg.Callback, value) end
	end
	function obj:Get() return value end

	box.Focused:Connect(function()
		tween(bStroke, 0.16, { Color = T.Accent, Transparency = 0 })
	end)
	box.FocusLost:Connect(function(enter)
		tween(bStroke, 0.16, { Color = T.Border, Transparency = 0.35 })
		if cfg.EnterOnly and not enter then
			box.Text = tostring(value)
			return
		end
		local old = value
		if not apply(box.Text) then
			box.Text = tostring(value)
			return
		end
		setFlag(cfg, value)
		if value ~= old then safe(cfg.Callback, value) end
	end)
	if cfg.Live and not cfg.Numeric then
		box:GetPropertyChangedSignal("Text"):Connect(function()
			if not box:IsFocused() then return end
			value = box.Text
			setFlag(cfg, value)
			safe(cfg.Callback, value)
		end)
	end

	setFlag(cfg, value)
	self:_Register(frame, cfg.Name, h + (cfg.Name and 20 or 0))
	obj.Frame = frame
	return regObj(cfg, obj)
end

local function toKey(v)
	if typeof(v) == "EnumItem" then return v end
	if type(v) == "string" then
		local ok, k = pcall(function() return Enum.KeyCode[v] end)
		return ok and k or nil
	end
	return nil
end

function Section:CreateKeybind(cfg)
	cfg = cfg or {}
	local T = self.Window.Theme
	local win = self.Window
	local h = rowH()
	local mode = cfg.Mode or "Press"
	local key = toKey(cfg.Default)
	local listening, state = false, false
	local token = {} -- identity so only the keybind being rebound swallows keys

	local row = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, Parent = self.Body })
	new("TextLabel", {
		Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -96, 1, 0), BackgroundTransparency = 1, Text = cfg.Name or "Keybind",
		Font = T.Font, TextSize = 14, TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
	})
	local btn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(80, math.min(h - 6, 24)),
		BackgroundColor3 = T.Control, BackgroundTransparency = 0.1, AutoButtonColor = false, Text = "", Font = T.Font, TextSize = 12,
		TextColor3 = T.Text, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
	}, { corner(6), stroke(T.Border, 1, 0.35), padding(4, 0, 4, 0) })
	feedback(btn, btn, "BackgroundColor3", T.Control, T.Lift, T.AccentSoft)

	local function setListening(v)
		listening = v and true or false
		if listening then
			Library._listening = token -- claim the "listening" slot for this keybind
		elseif Library._listening == token then
			Library._listening = nil
		end
	end
	local function refresh()
		btn.Text = listening and "..." or (key and key.Name or "None")
		tween(btn, 0.14, { TextColor3 = listening and T.Accent or T.Text })
	end
	refresh()

	local obj = {}
	function obj:Set(v, silent)
		key = toKey(v)
		setListening(false)
		state = false
		refresh()
		setFlag(cfg, key)
		if not silent then safe(cfg.Changed, key) end
	end
	function obj:Get() return key end
	function obj:GetState() return state end

	btn.MouseButton1Click:Connect(function()
		setListening(not listening)
		refresh()
	end)

	table.insert(win.Conns, UserInputService.InputBegan:Connect(function(i, gp)
		if listening then
			if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
			if i.KeyCode == Enum.KeyCode.Escape then
				setListening(false)
				refresh()
			elseif i.KeyCode == Enum.KeyCode.Backspace or i.KeyCode == Enum.KeyCode.Delete then
				obj:Set(nil)
			else
				obj:Set(i.KeyCode)
			end
			return
		end
		-- if another keybind is waiting for a key, this one must stay quiet,
		-- otherwise rebinding can fire someone else's callback
		if Library._listening then return end
		if gp or not key or i.KeyCode ~= key then return end
		if mode == "Hold" then
			state = true
			safe(cfg.Callback, true)
		elseif mode == "Toggle" then
			state = not state
			safe(cfg.Callback, state)
		else
			safe(cfg.Callback)
		end
	end))
	table.insert(win.Conns, UserInputService.InputEnded:Connect(function(i)
		if mode == "Hold" and state and key and i.KeyCode == key then
			state = false
			safe(cfg.Callback, false)
		end
	end))

	setFlag(cfg, key)
	self:_Register(row, cfg.Name, h)
	obj.Frame = row
	return regObj(cfg, obj)
end

local function toHex(c)
	return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

local function parseHex(s)
	s = tostring(s):gsub("[#%s]", "")
	if #s == 3 then s = s:gsub(".", function(ch) return ch .. ch end) end
	if #s ~= 6 or not s:match("^%x+$") then return nil end
	return Color3.fromRGB(tonumber(s:sub(1, 2), 16), tonumber(s:sub(3, 4), 16), tonumber(s:sub(5, 6), 16))
end

function Section:CreateColorPicker(cfg)
	cfg = cfg or {}
	local T = self.Window.Theme
	local win, tab = self.Window, self.Tab
	local h = rowH()
	local color = typeof(cfg.Default) == "Color3" and cfg.Default or Color3.fromRGB(255, 255, 255)
	local hue, sat, val = color:ToHSV()

	local row = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, Parent = self.Body })
	new("TextLabel", {
		Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -62, 1, 0), BackgroundTransparency = 1, Text = cfg.Name or "Color",
		Font = T.Font, TextSize = 14, TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
	})
	local swatch = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(38, 20),
		BackgroundColor3 = color, Text = "", AutoButtonColor = false, Parent = row,
	}, { corner(6), stroke(T.Border, 1, 0.2) })
	feedback(swatch, swatch, "BackgroundTransparency", 0, 0.12, 0.25)

	local obj = { IsOpen = false }
	local popup, popupStroke, svBox, svKnob, hueKnob, hexBox

	local function render()
		color = Color3.fromHSV(hue, sat, val)
		swatch.BackgroundColor3 = color
		if popup then
			svBox.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
			svKnob.Position = UDim2.fromScale(sat, 1 - val)
			hueKnob.Position = UDim2.fromScale(hue, 0.5)
			if not hexBox:IsFocused() then hexBox.Text = toHex(color) end
		end
	end
	local function push(silent)
		render()
		setFlag(cfg, color)
		if not silent then safe(cfg.Callback, color) end
	end

	-- press + drag on `hit`, reporting the pointer position (mouse and touch)
	local function dragOn(hit, onMove)
		hit.InputBegan:Connect(function(i)
			if not isPress(i) then return end
			local isTouch = i.UserInputType == Enum.UserInputType.Touch
			onMove(i.Position)
			local mc = UserInputService.InputChanged:Connect(function(m)
				if isTouch then
					if m ~= i then return end
				elseif m.UserInputType ~= Enum.UserInputType.MouseMovement then
					return
				end
				onMove(m.Position)
			end)
			onEnd(i, function() mc:Disconnect() end)
		end)
	end

	local function build()
		popup = new("Frame", {
			Visible = false, ZIndex = 61, Active = true, BackgroundColor3 = T.Panel, BorderSizePixel = 0, ClipsDescendants = true, Parent = win.Gui,
		}, { corner(8), stroke(T.Accent, 1, 0.45),
			wash(cseq({ 0, T.Top }, { 1, T.Panel }), 90) })
		popupStroke = popup:FindFirstChildOfClass("UIStroke")

		-- saturation / value square
		svBox = new("Frame", {
			Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 0, 104), BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
			BorderSizePixel = 0, Parent = popup,
		}, { corner(6) })
		new("Frame", {
			Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = svBox,
		}, { corner(6), new("UIGradient", { Transparency = NumberSequence.new(0, 1) }) })
		new("Frame", {
			Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Parent = svBox,
		}, { corner(6), new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }) })
		svKnob = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 3, Parent = svBox,
		}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }), stroke(Color3.new(1, 1, 1), 2, 0) })
		local svHit = new("TextButton", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 4, Parent = svBox,
		})
		dragOn(svHit, function(p)
			sat = math.clamp((p.X - svBox.AbsolutePosition.X) / math.max(svBox.AbsoluteSize.X, 1), 0, 1)
			val = 1 - math.clamp((p.Y - svBox.AbsolutePosition.Y) / math.max(svBox.AbsoluteSize.Y, 1), 0, 1)
			push()
		end)

		-- hue bar
		local pts = {}
		for n = 0, 6 do table.insert(pts, ColorSequenceKeypoint.new(n / 6, Color3.fromHSV(n / 6, 1, 1))) end
		local hueBar = new("Frame", {
			Position = UDim2.fromOffset(8, 120), Size = UDim2.new(1, -16, 0, 12), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = popup,
		}, { corner(6), new("UIGradient", { Color = ColorSequence.new(pts) }) })
		hueKnob = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(8, 16), BackgroundColor3 = T.Knob, BorderSizePixel = 0, ZIndex = 3, Parent = hueBar,
		}, { corner(3), stroke(T.Accent, 2, 0) })
		local hueHit = new("TextButton", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 4, Parent = hueBar,
		})
		dragOn(hueHit, function(p)
			hue = math.clamp((p.X - hueBar.AbsolutePosition.X) / math.max(hueBar.AbsoluteSize.X, 1), 0, 1)
			push()
		end)

		-- hex input
		local hexFrame = new("Frame", {
			Position = UDim2.fromOffset(8, 140), Size = UDim2.new(1, -16, 0, 24), BackgroundColor3 = T.Control, BackgroundTransparency = 0.1, BorderSizePixel = 0, Parent = popup,
		}, { corner(6), stroke(T.Border, 1, 0.35) })
		hexBox = new("TextBox", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = toHex(color), ClearTextOnFocus = false, Font = T.Font, TextSize = 13,
			TextColor3 = T.Text, Parent = hexFrame,
		})
		hexBox.FocusLost:Connect(function()
			local c = parseHex(hexBox.Text)
			if c then
				hue, sat, val = c:ToHSV()
				push()
			end
			hexBox.Text = toHex(color)
		end)
		render()
	end

	function obj:Open()
		if self.IsOpen then return end
		win:CloseDropdowns()
		if not popup then build() end
		render()
		local pos, size = swatch.AbsolutePosition, swatch.AbsoluteSize
		local vp = win.Gui.AbsoluteSize
		local ph = 172
		local pw = math.min(220, vp.X - 12)
		local below = vp.Y - (pos.Y + size.Y + 3) - 6
		local above = pos.Y - 3 - 6
		local down = ph <= below or below >= above
		ph = math.max(math.min(ph, down and below or above), 60)
		local x = math.clamp(pos.X + size.X - pw, 6, math.max(6, vp.X - pw - 6))

		if not popup.Visible then
			popup.Size = UDim2.fromOffset(pw, 0)
			popup.BackgroundTransparency = 1
			popupStroke.Transparency = 1
		end
		popup.AnchorPoint = Vector2.new(0, down and 0 or 1)
		popup.Position = down and UDim2.fromOffset(x, pos.Y + size.Y + 3) or UDim2.fromOffset(x, pos.Y - 3)
		popup.Visible = true
		win.Overlay.Visible = true
		tab.Scroll.ScrollingEnabled = false
		tween(popup, 0.22, { Size = UDim2.fromOffset(pw, ph), BackgroundTransparency = 0 })
		tween(popupStroke, 0.22, { Transparency = 0.45 })
		self.IsOpen = true
		win._dd = self
	end

	function obj:Close()
		if not self.IsOpen then return end
		self.IsOpen = false
		if win._dd == self then win._dd = nil end
		win.Overlay.Visible = false
		tab.Scroll.ScrollingEnabled = true
		if popup then
			tween(popupStroke, 0.16, { Transparency = 1 }, QUAD, IN)
			tween(popup, 0.16, { Size = UDim2.fromOffset(popup.AbsoluteSize.X, 0), BackgroundTransparency = 1 }, QUAD, IN).Completed:Connect(function()
				if not self.IsOpen then popup.Visible = false end
			end)
		end
	end

	function obj:Set(c, silent)
		if typeof(c) ~= "Color3" then return end
		hue, sat, val = c:ToHSV()
		push(silent)
	end
	function obj:Get() return color end

	swatch.MouseButton1Click:Connect(function()
		if obj.IsOpen then obj:Close() else obj:Open() end
	end)

	setFlag(cfg, color)
	self:_Register(row, cfg.Name, h)
	obj.Frame = row
	return regObj(cfg, obj)
end

------------------------------------------------------------------ extra controls
-- Section:CreateBadge({ Name, Value, Color })  ->  :Set(value) / :SetColor(c)
function Section:CreateBadge(cfg)
	cfg = cfg or {}
	local T = self.Window.Theme
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, rowH()), BackgroundTransparency = 1, Parent = self.Body })
	local lbl = new("TextLabel", {
		Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -92, 1, 0), BackgroundTransparency = 1, Text = cfg.Name or "Status",
		Font = T.Font, TextSize = 14, TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
	})
	local pill = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(72, 20),
		BackgroundColor3 = cfg.Color or T.Accent, BorderSizePixel = 0, Parent = row,
	}, { corner(10), stroke(cfg.Color or T.Accent, 1, 0.55) })
	local pillStroke = pill:FindFirstChildOfClass("UIStroke")
	local val = new("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = tostring(cfg.Value or "ON"),
		Font = T.FontBold, TextSize = 11, TextColor3 = Color3.new(1, 1, 1), TextTruncate = Enum.TextTruncate.AtEnd, Parent = pill,
	}, { padding(6, 0, 6, 0) })
	self:_Register(row, cfg.Name, rowH())
	local obj = { Frame = row }
	function obj:Set(v)
		val.Text = tostring(v)
	end
	function obj:SetColor(c)
		pill.BackgroundColor3 = c
		pillStroke.Color = c
	end
	return obj
end

-- Section:CreateProgress({ Name, Default, Min, Max, Suffix, Color })  ->  :Set(v) / :SetColor(c)
function Section:CreateProgress(cfg)
	cfg = cfg or {}
	local T = self.Window.Theme
	local min, max = cfg.Min or 0, cfg.Max or 100
	local value = math.clamp(cfg.Default or min, min, max)
	local suffix = cfg.Suffix or ""
	local total = UserInputService.TouchEnabled and 50 or 42
	local frame = new("Frame", { Size = UDim2.new(1, 0, 0, total), BackgroundTransparency = 1, Parent = self.Body })
	local nameLbl = new("TextLabel", {
		Size = UDim2.new(1, -70, 0, 18), BackgroundTransparency = 1, Text = cfg.Name or "Progress", Font = T.Font, TextSize = 14,
		TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
	})
	local valLabel = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(66, 18), BackgroundTransparency = 1,
		Text = tostring(value) .. suffix, Font = T.FontBold, TextSize = 13, TextColor3 = T.Accent, TextXAlignment = Enum.TextXAlignment.Right, Parent = frame,
	})
	local track = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0, 32), Size = UDim2.new(1, 0, 0, 8),
		BackgroundColor3 = T.Control, BorderSizePixel = 0, Parent = frame,
	}, { corner(4) })
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = track },
		{ corner(4), gradient(cfg.Color or T.Accent, (cfg.Color or T.Accent2), 0) })
	self:_Register(frame, cfg.Name, total)
	local obj = { Frame = frame }
	-- %d rejects a float in Luau, so format numbers through a safe helper
	local function fmtNum(n)
		if n == math.floor(n) then return tostring(math.floor(n)) end
		return tostring(n)
	end
	local function render(animate)
		local a = (max == min) and 0 or (value - min) / (max - min)
		valLabel.Text = fmtNum(value) .. suffix
		if animate then tween(fill, 0.2, { Size = UDim2.fromScale(a, 1) }) else fill.Size = UDim2.fromScale(a, 1) end
	end
	-- accepts an absolute value (Min..Max) or, when Auto is set, a 0..1 fraction
	function obj:Set(v)
		if cfg.Auto then
			value = math.clamp(v, 0, 1)
			valLabel.Text = fmtNum(math.floor(value * 100 + 0.5)) .. "%"
			tween(fill, 0.2, { Size = UDim2.fromScale(value, 1) })
			return
		end
		value = math.clamp(v, min, max)
		render(true)
	end
	function obj:Get() return value end
	function obj:SetColor(c)
		local g = fill:FindFirstChildOfClass("UIGradient")
		if g then g.Color = ColorSequence.new(c, c:Lerp(Color3.new(1, 1, 1), 0.25)) end
	end
	render(false)
	return regObj(cfg, obj)
end

-- Section:CreateSeparator("Label")  ->  a centered label with hairlines either side
function Section:CreateSeparator(cfg)
	if type(cfg) == "string" then cfg = { Name = cfg } end
	cfg = cfg or {}
	local T = self.Window.Theme
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Parent = self.Body })
	local function hair(anchor, pos)
		return new("Frame", {
			AnchorPoint = Vector2.new(anchor, 0.5), Position = pos, Size = UDim2.new(0.5, -34, 0, 1),
			BackgroundColor3 = T.Border, BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = row,
		})
	end
	hair(0, UDim2.new(0, 0, 0.5, 0))
	hair(1, UDim2.new(1, 0, 0.5, 0))
	new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AX,
		BackgroundTransparency = 1, Text = cfg.Name or "", Font = T.FontBold, TextSize = 11, TextColor3 = T.SubText, Parent = row,
	}, { padding(6, 0, 6, 0) })
	self:_Register(row, cfg.Name, 20)
	return { Frame = row }
end

-- Section:CreateKeybindToggle({ Name, Key, Default, Callback(state) })
-- a keybind and a switch fused into one row: press Key or tap the switch.
function Section:CreateKeybindToggle(cfg)
	cfg = cfg or {}
	local T = self.Window.Theme
	local win = self.Window
	local h = rowH()
	local key = toKey(cfg.Key or cfg.Default)
	local value = cfg.On and true or false

	local row = new("TextButton", {
		Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = T.Control, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = self.Body,
	}, { corner(7) })
	feedback(row, row, "BackgroundTransparency", 1, 0.82, 0.62, true)
	new("TextLabel", {
		Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -140, 1, 0), BackgroundTransparency = 1, Text = cfg.Name or "Toggle Key",
		Font = T.Font, TextSize = 14, TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
	})
	-- clickable key chip
	local keyBtn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -54, 0.5, 0), Size = UDim2.fromOffset(46, math.min(h - 8, 22)),
		BackgroundColor3 = T.Control, BackgroundTransparency = 0.1, AutoButtonColor = false, Text = "", Font = T.FontBold, TextSize = 11,
		TextColor3 = T.Accent, Parent = row,
	}, { corner(6), stroke(T.Border, 1, 0.35) })
	local keyStroke = keyBtn:FindFirstChildOfClass("UIStroke")
	local track = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(38, 20),
		BackgroundColor3 = value and T.Accent or T.Control, BorderSizePixel = 0, Parent = row,
	}, { corner(10) })
	local trackGrad = gradient(T.Accent, T.Accent2, 0)
	trackGrad.Parent = track
	trackGrad.Transparency = value and NumberSequence.new(0) or NumberSequence.new(1)
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = value and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(14, 14), BackgroundColor3 = T.Knob, BorderSizePixel = 0, Parent = track,
	}, { corner(7), stroke(T.Accent, 1.5, 0.4) })

	local listening = false
	local token = {}
	local obj = {}
	local function refreshKey()
		keyBtn.Text = listening and "..." or (key and key.Name or "None")
		tween(keyBtn, 0.14, { TextColor3 = listening and T.Accent or T.Text })
		tween(keyStroke, 0.14, { Color = listening and T.Accent or T.Border })
	end
	refreshKey()
	local function setValue(v, silent)
		value = v and true or false
		tween(track, 0.22, { BackgroundColor3 = value and T.Accent or T.Control })
		trackGrad.Transparency = value and NumberSequence.new(0) or NumberSequence.new(1)
		tween(knob, 0.24, { Position = value and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) })
		setFlag(cfg, value)
		if not silent then safe(cfg.Callback, value) end
	end
	function obj:Set(v, silent) setValue(v, silent) end
	function obj:Get() return value end
	function obj:SetKey(v, silent)
		key = toKey(v)
		refreshKey()
		if not silent then safe(cfg.Changed, key) end
	end
	function obj:GetKey() return key end

	row.MouseButton1Click:Connect(function()
		if listening then return end
		setValue(not value)
	end)
	keyBtn.MouseButton1Click:Connect(function()
		listening = not listening
		if listening then Library._listening = token elseif Library._listening == token then Library._listening = nil end
		refreshKey()
	end)
	table.insert(win.Conns, UserInputService.InputBegan:Connect(function(i, gp)
		if listening then
			if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
			if i.KeyCode == Enum.KeyCode.Escape then
				listening = false
				if Library._listening == token then Library._listening = nil end
				refreshKey()
			elseif i.KeyCode == Enum.KeyCode.Backspace or i.KeyCode == Enum.KeyCode.Delete then
				obj:SetKey(nil)
			else
				obj:SetKey(i.KeyCode)
			end
			return
		end
		if Library._listening then return end
		if gp or not key or i.KeyCode ~= key then return end
		setValue(not value)
	end))

	setFlag(cfg, value)
	self:_Register(row, cfg.Name, h)
	obj.Frame = row
	return regObj(cfg, obj)
end

------------------------------------------------------------------ tooltips
-- attach a hover tooltip to any GUI element: Window:Tooltip(frame, "text")
function Window:Tooltip(target, text)
	if not text or text == "" then return end
	local T = self.Theme
	local tip, measure
	local function show()
		if tip or usingTouch() then return end
		local txt = type(text) == "function" and text() or text
		if not txt or txt == "" then return end
		-- measure off-screen first: Roblox needs a frame to lay out before
		-- AbsoluteSize / TextBounds are valid, so position on the next frame
		measure = new("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.new(0, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.XY,
			Text = txt, Font = T.Font, TextSize = 12, TextColor3 = T.Text, TextWrapped = true,
			Visible = false, Parent = self.Gui,
		})
		tip = new("Frame", {
			BackgroundColor3 = T.Panel, BackgroundTransparency = 0.05, BorderSizePixel = 0, ZIndex = 120, Visible = false, Parent = self.Gui,
		}, { corner(6), stroke(T.Accent, 1, 0.5), padding(10, 6, 10, 6) })
		local l = new("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.new(0, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.XY, Text = txt,
			Font = T.Font, TextSize = 12, TextColor3 = T.Text, TextWrapped = true, Parent = tip,
		})
		task.defer(function()
			if not tip then return end
			local m = measure.AbsoluteSize
			local tw, th = m.X + 20, m.Y + 12
			local pos, size = target.AbsolutePosition, target.AbsoluteSize
			local vp = self.Gui.AbsoluteSize
			tip.Size = UDim2.fromOffset(tw, th)
			local x = math.clamp(pos.X + size.X / 2 - tw / 2, 6, math.max(6, vp.X - tw - 6))
			local y = pos.Y + size.Y + 6
			if y + th > vp.Y - 6 then y = pos.Y - th - 6 end
			tip.Position = UDim2.fromOffset(x, y)
			tip.Visible = true
			tip.BackgroundTransparency = 1
			tween(tip, 0.14, { BackgroundTransparency = 0.05 })
		end)
	end
	local function hide()
		if measure then measure:Destroy() measure = nil end
		if tip then tip:Destroy() tip = nil end
	end
	target.MouseEnter:Connect(show)
	target.MouseLeave:Connect(hide)
	return { Hide = hide }
end

------------------------------------------------------------------ tab badge
function Tab:SetBadge(v)
	local T = self.Window.Theme
	if v == nil or v == false or v == "" then
		if self.Badge then self.Badge.Visible = false end
		return
	end
	if not self.Badge then
		self.Badge = new("Frame", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(18, 16),
			AutomaticSize = AX, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Visible = false, Parent = self.Button,
		}, { corner(8), gradient(T.Accent, T.Accent2, 0), padding(6, 0, 6, 0) })
		self.BadgeLabel = new("TextLabel", {
			Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AX, BackgroundTransparency = 1, Text = "", Font = T.FontBold, TextSize = 10,
			TextColor3 = Color3.new(1, 1, 1), Parent = self.Badge,
		})
	end
	self.BadgeLabel.Text = tostring(v)
	self.Badge.Visible = true
	-- compact mode hides labels, so make room for the badge on the icon
	if self.Label.Visible then
		self.Label.Size = UDim2.new(1, -74, 1, 0)
	end
end

------------------------------------------------------------------ config / misc API
local function encodeValue(v)
	local t = typeof(v)
	if v == nil then return { __t = "none" } end
	if t == "Color3" then
		return { __t = "c3", r = math.floor(v.R * 255 + 0.5), g = math.floor(v.G * 255 + 0.5), b = math.floor(v.B * 255 + 0.5) }
	elseif t == "EnumItem" then
		return { __t = "key", n = v.Name }
	elseif t == "table" then
		local a = {}
		for i, x in ipairs(v) do a[i] = x end
		return { __t = "list", v = a }
	end
	return v
end

local function decodeValue(v)
	if type(v) ~= "table" then return v end
	if v.__t == "c3" then return Color3.fromRGB(v.r or 0, v.g or 0, v.b or 0) end
	if v.__t == "key" then return toKey(v.n) end
	if v.__t == "list" then return v.v or {} end
	return nil -- "none"
end

function Library:ExportConfig()
	local data = {}
	for flag, obj in pairs(self.Objects) do
		local ok, v = pcall(obj.Get, obj)
		if ok then data[flag] = encodeValue(v) end
	end
	return HttpService:JSONEncode(data)
end

-- returns ok, appliedCount | errorMessage
function Library:ImportConfig(json, silent)
	local ok, data = pcall(function() return HttpService:JSONDecode(json) end)
	if not ok or type(data) ~= "table" then return false, "invalid config" end
	local n = 0
	for flag, raw in pairs(data) do
		local obj = self.Objects[flag]
		if obj and obj.Set then
			obj:Set(decodeValue(raw), silent)
			n += 1
		end
	end
	return true, n
end

local function ensureFolder(path)
	local cur
	for part in path:gmatch("[^/\\]+") do
		cur = cur and (cur .. "/" .. part) or part
		if not isfolder(cur) then makefolder(cur) end
	end
end

local function cleanName(name)
	name = tostring(name or ""):gsub("[^%w_%- ]", "")
	return name ~= "" and name or nil
end

local function fsReady()
	return type(writefile) == "function" and type(readfile) == "function" and type(isfolder) == "function" and type(makefolder) == "function"
end

function Library:SaveConfig(name)
	name = cleanName(name)
	if not name then return false, "invalid name" end
	if not fsReady() then return false, "writefile is not supported here" end
	local ok, err = pcall(function()
		ensureFolder(self.ConfigFolder)
		writefile(self.ConfigFolder .. "/" .. name .. ".json", self:ExportConfig())
	end)
	return ok, ok and name or tostring(err)
end

function Library:LoadConfig(name, silent)
	name = cleanName(name)
	if not name then return false, "invalid name" end
	if not fsReady() or type(isfile) ~= "function" then return false, "readfile is not supported here" end
	local path = self.ConfigFolder .. "/" .. name .. ".json"
	if not isfile(path) then return false, "config not found" end
	return self:ImportConfig(readfile(path), silent)
end

function Library:DeleteConfig(name)
	name = cleanName(name)
	if not name then return false, "invalid name" end
	if type(delfile) ~= "function" or type(isfile) ~= "function" then return false, "delfile is not supported here" end
	local path = self.ConfigFolder .. "/" .. name .. ".json"
	if not isfile(path) then return false, "config not found" end
	return pcall(delfile, path)
end

function Library:ListConfigs()
	local out = {}
	if type(listfiles) ~= "function" or type(isfolder) ~= "function" or not isfolder(self.ConfigFolder) then return out end
	for _, f in ipairs(listfiles(self.ConfigFolder)) do
		local n = f:match("([^/\\]+)%.json$")
		if n then table.insert(out, n) end
	end
	table.sort(out)
	return out
end

function Library:Unload()
	if self._nm then pcall(function() self._nm:Destroy() end) self._nm = nil end
	for i = #self.Windows, 1, -1 do self.Windows[i]:Destroy() end
	table.clear(self.Flags)
	table.clear(self.Objects)
end

------------------------------------------------------------------ extra library API
-- Library:OnFlag(function(flag, value, prev)) -> connection (disconnect to stop)
-- fires whenever ANY flag changes, so you can bind a single handler instead of
-- putting a Callback on every control.
function Library:OnFlag(cb)
	table.insert(self._flagCbs, cb)
	local conn = {}
	function conn:Disconnect()
		for i, c in ipairs(Library._flagCbs) do
			if c == cb then table.remove(Library._flagCbs, i) break end
		end
	end
	return conn
end

-- Library:AutoloadConfig(name) -> ok, msg   (loads on startup if the file exists)
function Library:AutoloadConfig(name, silent)
	if type(isfile) ~= "function" or not fsReady() then return false, "no filesystem" end
	local path = self.ConfigFolder .. "/" .. (cleanName(name) or "") .. ".json"
	if not isfile(path) then return false, "not found" end
	return self:LoadConfig(name, silent)
end

-- Library:SaveAuto(name) -> ok, msg   (one call to snapshot the current state)
function Library:SaveAuto(name)
	return self:SaveConfig(name or "auto")
end

------------------------------------------------------------------ v3.2 extras
-- Everything below is additive. It wraps the existing Create* functions, so every
-- control (old and new) gets the same universal methods, the "modified" dot, the
-- right-click / long-press menu and an entry in the command palette.
do
local KC = Enum.KeyCode

Library.Commands = {}
Library._watch = {}
Library._names = {}
Library._snaps = {}
Library.ContextMenu = true   -- right-click / long-press menu on controls (false = off)
Library.MenuHold = 0.55      -- seconds to hold a finger before the menu opens
Library.PaletteKey = KC.K    -- Ctrl + PaletteKey opens the command palette
Library.History = { Max = 100, Merge = 0.6, Hotkeys = true, Toast = true, Undos = {}, Redos = {} }

---------------------------------------------------------------- shared helpers
local function deepEq(a, b)
	if a == b then return true end
	if type(a) ~= "table" or type(b) ~= "table" then return false end
	for k, v in pairs(a) do
		if not deepEq(v, b[k]) then return false end
	end
	for k in pairs(b) do
		if a[k] == nil then return false end
	end
	return true
end

local function cloneVal(v)
	if type(v) ~= "table" then return v end
	local o = {}
	for k, x in pairs(v) do o[k] = cloneVal(x) end
	return o
end

local function fmtVal(v)
	local t = typeof(v)
	local s
	if v == nil then
		s = "\u{2014}"
	elseif t == "boolean" then
		s = v and "ON" or "OFF"
	elseif t == "number" then
		if v == math.floor(v) then
			s = tostring(math.floor(v))
		else
			s = string.format("%.2f", v):gsub("0+$", ""):gsub("%.$", "")
		end
	elseif t == "Color3" then
		s = toHex(v)
	elseif t == "EnumItem" then
		s = v.Name
	elseif t == "table" then
		local parts = {}
		for _, x in ipairs(v) do table.insert(parts, tostring(x)) end
		s = #parts == 0 and "\u{2014}" or table.concat(parts, ", ")
	else
		s = tostring(v)
	end
	if #s > 14 then s = s:sub(1, 13) .. "\u{2026}" end
	return s
end

local function copyValue(win, v)
	local text
	local t = typeof(v)
	if t == "Color3" then
		text = toHex(v)
	elseif t == "EnumItem" then
		text = v.Name
	elseif t == "table" then
		local ok, js = pcall(function() return HttpService:JSONEncode(v) end)
		text = ok and js or tostring(v)
	else
		text = tostring(v)
	end
	if type(setclipboard) == "function" then
		pcall(setclipboard, text)
		win:Notify({ Title = "Copied", Content = text, Kind = "Success", Duration = 1.6 })
	else
		win:Notify({ Title = "Clipboard not supported", Content = text, Kind = "Warning", Duration = 3 })
	end
end

local function activeWindow()
	for i = #Library.Windows, 1, -1 do
		local w = Library.Windows[i]
		if w.Visible then return w end
	end
	return Library.Windows[#Library.Windows]
end

local function isHidden(e)
	return e.Ctl ~= nil and e.Ctl.Hidden == true
end

---------------------------------------------------------------- Library:Watch
-- Library:Watch("flag", function(value, prev)) -> conn (conn:Disconnect())
function Library:Watch(flag, fn)
	local w = self._watch[flag]
	if not w then
		w = {}
		self._watch[flag] = w
	end
	table.insert(w, fn)
	return {
		Disconnect = function()
			local i = table.find(w, fn)
			if i then table.remove(w, i) end
		end,
	}
end

Library:OnFlag(function(flag, v, prev)
	local w = Library._watch[flag]
	if w then
		for _, fn in ipairs(table.clone(w)) do safe(fn, v, prev) end
	end
end)

---------------------------------------------------------------- undo / redo
local function trimStack(list)
	while #list > Library.History.Max do table.remove(list, 1) end
end

Library:OnFlag(function(flag, v, prev)
	if Library._replay then return end
	-- ignore the first setFlag a control does while it is still being built
	if prev == nil or Library.Objects[flag] == nil then return end
	if Library._batch then
		table.insert(Library._batch, { flag = flag, new = cloneVal(v), old = cloneVal(prev) })
		return
	end
	local H = Library.History
	local top = H.Undos[#H.Undos]
	local now = os.clock()
	-- a slider drag fires hundreds of changes: merge them into one history entry
	if top and not top.group and top.flag == flag and now - top.t < H.Merge then
		top.new = cloneVal(v)
		top.t = now
		table.clear(H.Redos)
		return
	end
	table.insert(H.Undos, { flag = flag, new = cloneVal(v), old = cloneVal(prev), t = now })
	trimStack(H.Undos)
	table.clear(H.Redos)
end)

local function applyValue(flag, val)
	local o = Library.Objects[flag]
	if o and o.Set then
		local ok, err = pcall(o.Set, o, cloneVal(val))
		if not ok then warn("[SpectreUI] history apply failed: " .. tostring(err)) end
	end
end

local function entryLabel(e)
	if e.group then return (e.label or "Changes") .. " (" .. #e.items .. ")" end
	return Library._names[e.flag] or tostring(e.flag)
end

local function toast(title, e)
	if not Library.History.Toast then return end
	local w = Library.Windows[#Library.Windows]
	if w then w:Notify({ Title = title, Content = entryLabel(e), Kind = "Info", Duration = 1.6 }) end
end

-- Library:Undo(silent) / Redo(silent) -> ok, entry
function Library:Undo(silent)
	local H = self.History
	local e = table.remove(H.Undos)
	if not e then return false end
	self._replay = true
	if e.group then
		for i = #e.items, 1, -1 do applyValue(e.items[i].flag, e.items[i].old) end
	else
		applyValue(e.flag, e.old)
	end
	self._replay = false
	table.insert(H.Redos, e)
	if not silent then toast("Undo", e) end
	return true, e
end

function Library:Redo(silent)
	local H = self.History
	local e = table.remove(H.Redos)
	if not e then return false end
	self._replay = true
	if e.group then
		for i = 1, #e.items do applyValue(e.items[i].flag, e.items[i].new) end
	else
		applyValue(e.flag, e.new)
	end
	self._replay = false
	table.insert(H.Undos, e)
	if not silent then toast("Redo", e) end
	return true, e
end

function Library:CanUndo() return #self.History.Undos > 0 end
function Library:CanRedo() return #self.History.Redos > 0 end

-- newest first: { "Aimbot FOV", "Load config (12)", ... }
function Library:GetHistory()
	local out = {}
	for i = #self.History.Undos, 1, -1 do table.insert(out, entryLabel(self.History.Undos[i])) end
	return out
end

function Library:ClearHistory()
	table.clear(self.History.Undos)
	table.clear(self.History.Redos)
end

-- Library:Transaction("label", fn): every flag change inside fn becomes ONE undo step
function Library:Transaction(label, fn)
	if self._batch then return fn() end
	self._batch = {}
	local res = table.pack(pcall(fn))
	local items = self._batch
	self._batch = nil
	local order, map = {}, {}
	for _, it in ipairs(items) do
		local m = map[it.flag]
		if m then
			m.new = it.new
		else
			m = { flag = it.flag, old = it.old, new = it.new }
			map[it.flag] = m
			table.insert(order, m)
		end
	end
	local kept = {}
	for _, m in ipairs(order) do
		if not deepEq(m.old, m.new) then table.insert(kept, m) end
	end
	if #kept > 0 then
		local H = self.History
		table.insert(H.Undos, { group = true, label = label or "Batch", items = kept, t = os.clock() })
		trimStack(H.Undos)
		table.clear(H.Redos)
	end
	if not res[1] then error(res[2], 0) end
	return table.unpack(res, 2, res.n)
end

-- config loads become a single undo step
local origImport = Library.ImportConfig
function Library:ImportConfig(json, silent)
	return self:Transaction("Load config", function() return origImport(self, json, silent) end)
end

---------------------------------------------------------------- snapshots / diff
-- Library:Snapshot("name") -> table   in-memory copy of every flag (no writefile needed)
function Library:Snapshot(name)
	local snap = {}
	for flag, o in pairs(self.Objects) do
		if o.Get then
			local ok, v = pcall(o.Get, o)
			if ok then snap[flag] = cloneVal(v) end
		end
	end
	if name then self._snaps[name] = snap end
	return snap
end

-- Library:Restore("name" | snapshotTable) -> ok, appliedCount   (one undo step)
function Library:Restore(src, silent)
	local snap = type(src) == "string" and self._snaps[src] or src
	if type(snap) ~= "table" then return false, "snapshot not found" end
	local n = 0
	self:Transaction("Restore", function()
		for flag, v in pairs(snap) do
			local o = self.Objects[flag]
			if o and o.Set and o.Get then
				local ok, cur = pcall(o.Get, o)
				if ok and not deepEq(cur, v) then
					o:Set(cloneVal(v), silent)
					n += 1
				end
			end
		end
	end)
	return true, n
end

-- Library:Diff(a, b) -> { { Flag, From, To }, ... }   a / b = snapshot name or table, b nil = live state
function Library:Diff(a, b)
	if type(a) == "string" then a = self._snaps[a] end
	a = a or {}
	if b == nil then b = self:Snapshot() elseif type(b) == "string" then b = self._snaps[b] end
	b = b or {}
	local out, seen = {}, {}
	for flag, v in pairs(a) do
		seen[flag] = true
		if not deepEq(v, b[flag]) then table.insert(out, { Flag = flag, From = v, To = b[flag] }) end
	end
	for flag, v in pairs(b) do
		if not seen[flag] and not deepEq(a[flag], v) then table.insert(out, { Flag = flag, From = a[flag], To = v }) end
	end
	table.sort(out, function(x, y) return x.Flag < y.Flag end)
	return out
end

---------------------------------------------------------------- popup menu
function Library:CloseMenu()
	if self._menuGui then
		self._menuGui:Destroy()
		self._menuGui = nil
	end
end

-- Library:ShowMenu({ { Name, Callback, Color, Disabled }, { Separator = true } }, anchorFrame, window)
function Library:ShowMenu(items, anchor, win)
	win = win or self.Windows[#self.Windows]
	if not win or not items or #items == 0 then return end
	self:CloseMenu()
	local T = win.Theme
	local gui = win.Gui
	local vp = gui.AbsoluteSize
	local ROW = UserInputService.TouchEnabled and 38 or 30
	local W = 196
	local h = 12 + (#items - 1) * 2
	for _, it in ipairs(items) do h += it.Separator and 7 or ROW end

	local catcher = new("TextButton", {
		Name = "SpectreMenu", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
		ZIndex = 160, Parent = gui,
	})
	self._menuGui = catcher
	catcher.MouseButton1Click:Connect(function() self:CloseMenu() end)
	catcher.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton2 then self:CloseMenu() end
	end)

	local x, y = vp.X / 2 - W / 2, vp.Y / 2 - h / 2
	if typeof(anchor) == "Instance" then
		local ap, as = anchor.AbsolutePosition, anchor.AbsoluteSize
		x = ap.X + as.X - W - 6
		y = ap.Y + as.Y + 2
		if y + h > vp.Y - 6 then y = ap.Y - h - 2 end
	end
	x = math.clamp(x, 6, math.max(6, vp.X - W - 6))
	y = math.clamp(y, 6, math.max(6, vp.Y - h - 6))

	local menu = new("Frame", {
		Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(W, h), BackgroundColor3 = T.Panel, BackgroundTransparency = 0.02,
		BorderSizePixel = 0, Active = true, Parent = catcher,
	}, { corner(9), stroke(T.Accent, 1, 0.4), list(2), padding(6, 6, 6, 6) })

	for idx, it in ipairs(items) do
		if it.Separator then
			new("Frame", { LayoutOrder = idx, Size = UDim2.new(1, 0, 0, 7), BackgroundTransparency = 1, Parent = menu }, {
				new("Frame", {
					AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(1, 0, 0, 1),
					BackgroundColor3 = T.Border, BackgroundTransparency = 0.5, BorderSizePixel = 0,
				}),
			})
		else
			local dis = it.Disabled and true or false
			local b = new("TextButton", {
				LayoutOrder = idx, Size = UDim2.new(1, 0, 0, ROW), BackgroundColor3 = T.Control, BackgroundTransparency = 1,
				AutoButtonColor = false, Text = it.Name or "Item", Font = T.Font, TextSize = 13,
				TextColor3 = dis and T.SubText or (it.Color or T.Text), TextXAlignment = LEFT, Parent = menu,
			}, { corner(6), padding(10, 0, 8, 0) })
			if not dis then feedback(b, b, "BackgroundTransparency", 1, 0.8, 0.55, true) end
			b.MouseButton1Click:Connect(function()
				if dis then return end
				self:CloseMenu()
				safe(it.Callback, it)
			end)
		end
	end
	return { Close = function() self:CloseMenu() end }
end

---------------------------------------------------------------- reveal / goto
local function reveal(win, e)
	if not win.Visible then win:SetVisible(true) end
	if win.SearchBox and win.SearchBox.Text ~= "" then
		win.SearchBox.Text = ""
		win:_ApplySearch()
	end
	win:SetTab(e.Tab)
	if e.Section.Collapsed then e.Section:SetCollapsed(false, true) end
	e.Tab:_QueueRelayout()
	task.delay(0.15, function()
		if not e.Frame.Parent then return end
		local T = win.Theme
		local sc = e.Tab.Scroll
		local y = e.Frame.AbsolutePosition.Y - sc.AbsolutePosition.Y + sc.CanvasPosition.Y - 28
		tween(sc, 0.3, { CanvasPosition = Vector2.new(0, math.max(0, y)) })
		local hl = new("Frame", {
			Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Accent, BackgroundTransparency = 0.5, BorderSizePixel = 0,
			ZIndex = 8, Parent = e.Frame,
		}, { corner(7) })
		tween(hl, 1.1, { BackgroundTransparency = 1 }, QUAD, OUT).Completed:Connect(function() hl:Destroy() end)
	end)
end

-- Window:Goto(obj | "flag" | "control name") -> bool   switch tab, expand, scroll, highlight
function Window:Goto(target)
	local e
	for _, x in ipairs(self._index or {}) do
		if type(target) == "table" and x.Obj == target then e = x break end
		if type(target) == "string" and (x.Flag == target or x.Name:lower() == target:lower()) then e = x break end
	end
	if e then reveal(self, e) end
	return e ~= nil
end

function Library:Goto(target)
	for i = #self.Windows, 1, -1 do
		if self.Windows[i]:Goto(target) then return true end
	end
	return false
end

---------------------------------------------------------------- command palette
function Library:AddCommand(cfg)
	table.insert(self.Commands, cfg)
	return {
		Remove = function()
			local i = table.find(Library.Commands, cfg)
			if i then table.remove(Library.Commands, i) end
		end,
	}
end

local NOJUMP = { Label = true, Paragraph = true, Separator = true, Badge = true, Progress = true, Graph = true, Console = true }
local ASSIGN = { Slider = true, Toggle = true, KeybindToggle = true, Textbox = true }

local function score(hay, q)
	if q == "" then return 1 end
	local total = 0
	for tok in q:gmatch("%S+") do
		local s = hay:find(tok, 1, true)
		if s then
			total += (s == 1) and 16 or 10
		else
			local pos = 1
			for ch in tok:gmatch(".") do
				local f = hay:find(ch, pos, true)
				if not f then return 0 end
				pos = f + 1
			end
			total += 3
		end
	end
	return total
end

local function scoreEntry(e, q)
	local hay = (e.Name .. " " .. e.SectionName .. " " .. e.TabName .. " " .. e.Kind):lower()
	local s = score(hay, q)
	if s > 0 then s += score(e.Name:lower(), q) * 2 end
	return s
end

local function parseBool(s)
	s = s:lower()
	if s == "on" or s == "true" or s == "1" or s == "yes" then return true end
	if s == "off" or s == "false" or s == "0" or s == "no" then return false end
	return nil
end

local function applyAssign(win, e, av)
	local o, k = e.Obj, e.Kind
	local ok = false
	if k == "Toggle" or k == "KeybindToggle" then
		local b = parseBool(av)
		if b ~= nil then
			o:Set(b)
			ok = true
		end
	elseif k == "Slider" then
		local n = tonumber(av)
		if n then
			o:Set(n)
			ok = true
		end
	elseif k == "Textbox" then
		if e.Cfg.Numeric then
			local n = tonumber(av)
			if n then
				o:Set(n)
				ok = true
			end
		else
			o:Set(av)
			ok = true
		end
	end
	win:Notify({
		Title = e.Name, Content = ok and ("Set to " .. fmtVal(o:Get())) or "Invalid value",
		Kind = ok and "Success" or "Error", Duration = 2,
	})
end

local function pushRecent(win, e)
	win._palRecent = win._palRecent or {}
	local r = table.find(win._palRecent, e)
	if r then table.remove(win._palRecent, r) end
	table.insert(win._palRecent, 1, e)
	while #win._palRecent > 5 do table.remove(win._palRecent) end
end

local function builtinCommands()
	return {
		{ Name = "Undo last change", Desc = "History", Callback = function() Library:Undo() end },
		{ Name = "Redo", Desc = "History", Callback = function() Library:Redo() end },
		{
			Name = "Reset modified settings", Desc = #Library:GetModified() .. " modified",
			Callback = function()
				Library:Confirm({
					Title = "Reset settings?", Content = "Every changed setting goes back to its default. You can undo this.",
					Yes = "Reset", OnYes = function() Library:ResetAll() end,
				})
			end,
		},
	}
end

local function entryItem(win, e, close)
	local function valueText()
		if e.Obj.Get then
			local ok, v = pcall(e.Obj.Get, e.Obj)
			if ok then return fmtVal(v) end
		end
		return e.Kind:upper()
	end
	return {
		title = e.Name, sub = e.TabName .. "  \u{203A}  " .. e.SectionName, chip = valueText(),
		run = function(chip)
			pushRecent(win, e)
			if e.Obj._locked then
				win:Notify({ Title = e.Name, Content = "This control is locked", Kind = "Warning", Duration = 2 })
				return
			end
			if (e.Kind == "Toggle" or e.Kind == "KeybindToggle") and e.Obj.Set and e.Obj.Get then
				e.Obj:Set(not e.Obj:Get())
				if chip then chip.Text = valueText() end
			elseif e.Kind == "Button" then
				close()
				safe(e.Cfg.Callback)
			else
				close()
				reveal(win, e)
			end
		end,
	}
end

local function buildItems(win, raw, close)
	local q = raw:lower():gsub("^%s+", ""):gsub("%s+$", "")
	local out = {}

	-- quick set:  "walkspeed = 50"  /  "esp = on"
	local an, av = raw:match("^%s*(.-)%s*=%s*(.-)%s*$")
	if an and an ~= "" and av and av ~= "" then
		local best, bs = nil, 0
		for _, e in ipairs(win._index or {}) do
			if ASSIGN[e.Kind] and not isHidden(e) then
				local s = scoreEntry(e, an:lower())
				if s > bs then best, bs = e, s end
			end
		end
		if best then
			table.insert(out, {
				title = "Set " .. best.Name .. " = " .. av, sub = best.TabName .. "  \u{203A}  " .. best.SectionName, chip = "SET",
				run = function()
					close()
					applyAssign(win, best, av)
				end,
			})
		end
	end

	local scored = {}
	for idx, e in ipairs(win._index or {}) do
		if not NOJUMP[e.Kind] and not isHidden(e) then
			local s = (q == "") and 1 or scoreEntry(e, q)
			if s > 0 then
				if q == "" and win._palRecent then
					local r = table.find(win._palRecent, e)
					if r then s = 1000 - r end
				end
				table.insert(scored, { s = s, i = idx, e = e })
			end
		end
	end
	local cmds = {}
	for _, c in ipairs(Library.Commands) do table.insert(cmds, c) end
	for _, c in ipairs(builtinCommands()) do table.insert(cmds, c) end
	for idx, c in ipairs(cmds) do
		local nm = (c.Name or ""):lower()
		local hay = nm .. " " .. (c.Desc or ""):lower() .. " " .. (c.Keywords or ""):lower()
		local s = (q == "") and 0.5 or score(hay, q)
		if s > 0 and q ~= "" then s += score(nm, q) * 2 end
		if s > 0 then table.insert(scored, { s = s, i = 10000 + idx, c = c }) end
	end
	table.sort(scored, function(a, b)
		if a.s ~= b.s then return a.s > b.s end
		return a.i < b.i
	end)
	for n = 1, math.min(#scored, lowPower() and 24 or 40) do
		local it = scored[n]
		if it.e then
			table.insert(out, entryItem(win, it.e, close))
		else
			local c = it.c
			table.insert(out, {
				title = c.Name or "Command", sub = c.Desc or "Command", chip = "CMD",
				run = function()
					close()
					safe(c.Callback)
				end,
			})
		end
	end
	return out
end

function Window:ClosePalette()
	local p = self._palette
	if not p then return end
	self._palette = nil
	p.overlay:Destroy()
end

-- Window:OpenPalette(initialText)   Ctrl+K on PC; call it from a button on mobile
function Window:OpenPalette(initial)
	if self._palette then
		self:ClosePalette()
		return
	end
	self:CloseDropdowns()
	Library:CloseMenu()
	local T, gui = self.Theme, self.Gui
	local vp = gui.AbsoluteSize
	local top = (vp.Y < 520) and 8 or 56
	local W = math.min(420, vp.X - 20)
	local H = math.clamp(vp.Y - top - 16, 150, 400)

	local overlay = new("TextButton", {
		Name = "SpectrePalette", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
		Text = "", AutoButtonColor = false, ZIndex = 150, Parent = gui,
	})
	local card = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, top - 10), Size = UDim2.fromOffset(W, H),
		BackgroundColor3 = T.Panel, BackgroundTransparency = 1, BorderSizePixel = 0, Active = true, Parent = overlay,
	}, { corner(12), stroke(T.Accent, 1, 0.35), wash(cseq({ 0, T.Top }, { 1, T.Panel }), 90) })
	local box = new("TextBox", {
		Position = UDim2.fromOffset(12, 10), Size = UDim2.new(1, -24, 0, 36), BackgroundColor3 = T.Control, BackgroundTransparency = 0.1,
		BorderSizePixel = 0, Text = initial or "", PlaceholderText = "Search settings or run a command   (try: speed = 50)",
		PlaceholderColor3 = T.SubText, TextColor3 = T.Text, Font = T.Font, TextSize = 14, TextXAlignment = LEFT,
		ClearTextOnFocus = false, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card,
	}, { corner(8), stroke(T.Border, 1, 0.35), padding(10, 0, 10, 0) })
	local scroll = new("ScrollingFrame", {
		Position = UDim2.fromOffset(8, 54), Size = UDim2.new(1, -16, 1, -62), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 3, ScrollBarImageColor3 = T.Accent, CanvasSize = UDim2.new(), AutomaticCanvasSize = AY,
		ScrollingDirection = Enum.ScrollingDirection.Y, Parent = card,
	}, { list(4) })

	local state = { overlay = overlay, card = card }
	self._palette = state
	local function close()
		if self._palette == state then self:ClosePalette() end
	end
	overlay.MouseButton1Click:Connect(close)

	local rows, current, sel = {}, {}, 1
	local ROWH = UserInputService.TouchEnabled and 46 or 40
	local PADY = (ROWH - 40) / 2
	local function paintSel()
		for i, r in ipairs(rows) do
			local m = r:FindFirstChild("Sel")
			if m then m.Visible = (i == sel) and not UserInputService.TouchEnabled end
		end
	end
	local function makeRow(it, idx)
		local btn = new("TextButton", {
			LayoutOrder = idx, Size = UDim2.new(1, 0, 0, ROWH), BackgroundColor3 = T.Control, BackgroundTransparency = 1,
			Text = "", AutoButtonColor = false, Parent = scroll,
		}, { corner(8) })
		new("Frame", {
			Name = "Sel", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0), Size = UDim2.fromOffset(3, ROWH - 16),
			BackgroundColor3 = T.Accent, BorderSizePixel = 0, Visible = false, Parent = btn,
		}, { corner(2) })
		feedback(btn, btn, "BackgroundTransparency", 1, 0.8, 0.55, true)
		new("TextLabel", {
			Position = UDim2.fromOffset(10, 3 + PADY), Size = UDim2.new(1, -100, 0, 18), BackgroundTransparency = 1, Text = it.title,
			Font = T.FontBold, TextSize = 13, TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = btn,
		})
		new("TextLabel", {
			Position = UDim2.fromOffset(10, 21 + PADY), Size = UDim2.new(1, -100, 0, 14), BackgroundTransparency = 1, Text = it.sub or "",
			Font = T.Font, TextSize = 11, TextColor3 = T.SubText, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = btn,
		})
		local chip = new("TextLabel", {
			Name = "Chip", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(80, 20),
			BackgroundColor3 = T.AccentSoft, BorderSizePixel = 0, Text = it.chip or "", Font = T.FontBold, TextSize = 11,
			TextColor3 = T.Accent, TextTruncate = Enum.TextTruncate.AtEnd, Parent = btn,
		}, { corner(10), padding(6, 0, 6, 0) })
		btn.MouseButton1Click:Connect(function() it.run(chip) end)
		return btn
	end
	local function refresh()
		for _, r in ipairs(rows) do r:Destroy() end
		table.clear(rows)
		current = buildItems(self, box.Text, close)
		for idx, it in ipairs(current) do rows[idx] = makeRow(it, idx) end
		scroll.CanvasPosition = Vector2.zero
		sel = 1
		paintSel()
	end
	-- typing is debounced: one rebuild per burst of keystrokes
	local queued = false
	box:GetPropertyChangedSignal("Text"):Connect(function()
		if queued then return end
		queued = true
		task.delay(0.07, function()
			queued = false
			if self._palette == state then refresh() end
		end)
	end)
	box.FocusLost:Connect(function(enter)
		if enter and current[sel] and rows[sel] then current[sel].run(rows[sel]:FindFirstChild("Chip")) end
	end)
	-- Up / Down (PC): move the selection and keep it in view
	state.Move = function(d)
		if #rows == 0 then return end
		sel = math.clamp(sel + d, 1, #rows)
		paintSel()
		local r = rows[sel]
		local px = math.max(r.AbsoluteSize.Y / ROWH, 0.01)
		local delta = (r.AbsolutePosition.Y - scroll.AbsolutePosition.Y) / px
		local view = scroll.AbsoluteSize.Y / px
		if delta < 0 then
			scroll.CanvasPosition += Vector2.new(0, delta)
		elseif delta + ROWH > view then
			scroll.CanvasPosition += Vector2.new(0, delta + ROWH - view)
		end
	end
	refresh()

	tween(overlay, 0.15, { BackgroundTransparency = 0.55 })
	tween(card, 0.18, { BackgroundTransparency = 0.02, Position = UDim2.new(0.5, 0, 0, top) })
	task.delay(0.04, function()
		if box.Parent then box:CaptureFocus() end
	end)
end

---------------------------------------------------------------- global input
local function ensureInput()
	if Library._inp then return end
	Library._inp = UserInputService.InputBegan:Connect(function(i, gp)
		if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
		if i.KeyCode == KC.Escape then
			Library:CloseMenu()
			for _, w in ipairs(Library.Windows) do
				if w._palette then w:ClosePalette() end
			end
		elseif i.KeyCode == KC.Down or i.KeyCode == KC.Up then
			for _, w in ipairs(Library.Windows) do
				if w._palette and w._palette.Move then w._palette.Move(i.KeyCode == KC.Down and 1 or -1) end
			end
		end
		if gp or Library._listening then return end
		local ctrl = UserInputService:IsKeyDown(KC.LeftControl) or UserInputService:IsKeyDown(KC.RightControl)
		if not ctrl then return end
		local w = activeWindow()
		if not w then return end
		if i.KeyCode == Library.PaletteKey then
			w:OpenPalette()
		elseif Library.History.Hotkeys and w.Visible then
			local shift = UserInputService:IsKeyDown(KC.LeftShift) or UserInputService:IsKeyDown(KC.RightShift)
			if i.KeyCode == KC.Z then
				if shift then Library:Redo() else Library:Undo() end
			elseif i.KeyCode == KC.Y then
				Library:Redo()
			end
		end
	end)
end

-- PC only: grab the corner glyph and drag to resize (Window option Resizable = false to disable)
local function attachResize(win)
	local main, T = win.Main, win.Theme
	local grip = new("TextButton", {
		Name = "ResizeGrip", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -3, 1, -3), Size = UDim2.fromOffset(18, 18),
		BackgroundTransparency = 1, Text = "\u{25E2}", Font = T.FontBold, TextSize = 12, TextColor3 = T.SubText, TextTransparency = 0.45,
		AutoButtonColor = false, ZIndex = 40, Parent = main,
	})
	grip.MouseEnter:Connect(function() tween(grip, 0.12, { TextTransparency = 0, TextColor3 = T.Accent }) end)
	grip.MouseLeave:Connect(function() tween(grip, 0.16, { TextTransparency = 0.45, TextColor3 = T.SubText }) end)
	grip.InputBegan:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		local vp = win.Gui.AbsoluteSize
		local start = i.Position
		local w0, h0 = main.Size.X.Offset, main.Size.Y.Offset
		local tl = main.AbsolutePosition
		local conn
		conn = UserInputService.InputChanged:Connect(function(m)
			if m.UserInputType ~= Enum.UserInputType.MouseMovement then return end
			local d = m.Position - start
			local w = math.max(420, math.min(w0 + d.X, vp.X - 16))
			local h = math.max(300, math.min(h0 + d.Y, vp.Y - 16))
			win.Cfg.Width, win.Cfg.Height = w, h
			-- keep the top-left corner where it is: store the new centre relative to the screen
			win._drag.Rel = Vector2.new((tl.X + w / 2) / vp.X, (tl.Y + h / 2) / vp.Y)
			win:_Fit()
		end)
		onEnd(i, function() conn:Disconnect() end)
	end)
end

local origCreateWindow = Library.CreateWindow
function Library:CreateWindow(cfg)
	ensureInput()
	local win = origCreateWindow(self, cfg)
	win._index = win._index or {}
	if false and not UserInputService.TouchEnabled and (cfg == nil or cfg.Resizable ~= false) then -- legacy duplicate grip disabled (CreateWindow already has the corner grip)
		local ok, err = pcall(attachResize, win)
		if not ok then warn("[SpectreUI] resize grip failed: " .. tostring(err)) end
	end
	return win
end

-- Library:SetQuality("low" | "high" | "auto")   shortcut for Library.Perf.LowPower (applies to windows / controls built afterwards)
function Library:SetQuality(q)
	self.Perf.LowPower = (q == "low") and true or (q == "high") and false or nil
end

local origUnload = Library.Unload
function Library:Unload()
	self:CloseMenu()
	origUnload(self)
	if self._inp then
		self._inp:Disconnect()
		self._inp = nil
	end
	table.clear(self._watch)
	table.clear(self._names)
	self:ClearHistory()
end

---------------------------------------------------------------- new controls
-- Section:CreateSegmented({ Name, Options = { "A", "B", "C" }, Default, Flag, Callback(option) })
-- pill selector, best for 2-5 options.  :Set / :Get / :SetOptions(list, keepValue)
function Section:CreateSegmented(cfg)
	cfg = cfg or {}
	local T = self.Window.Theme
	local touch = UserInputService.TouchEnabled
	local options = cfg.Options or {}
	local value = cfg.Default
	if value == nil then value = options[1] end
	local barH = touch and 34 or 28
	local total = 22 + barH + 2
	local frame = new("Frame", { Size = UDim2.new(1, 0, 0, total), BackgroundTransparency = 1, Parent = self.Body })
	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = cfg.Name or "Mode", Font = T.Font, TextSize = 14,
		TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
	})
	local bar = new("Frame", {
		Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0, barH), BackgroundColor3 = T.Control, BackgroundTransparency = 0.1,
		BorderSizePixel = 0, Parent = frame,
	}, { corner(8), stroke(T.Border, 1, 0.4), padding(3, 3, 3, 3) })
	local holder = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = bar },
		{ list(3, { FillDirection = Enum.FillDirection.Horizontal }) })

	local btns = {}
	local obj = {}
	local function paint()
		for _, b in ipairs(btns) do
			local on = b.opt == value
			tween(b.btn, 0.18, { BackgroundTransparency = on and 0 or 1 })
			tween(b.lbl, 0.18, { TextColor3 = on and Color3.new(1, 1, 1) or T.SubText })
		end
	end
	local function build()
		for _, b in ipairs(btns) do b.btn:Destroy() end
		btns = {}
		local n = math.max(#options, 1)
		for idx, opt in ipairs(options) do
			local b = new("TextButton", {
				LayoutOrder = idx, Size = UDim2.new(1 / n, -(3 * (n - 1)) / n, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 1, AutoButtonColor = false, Text = "", Parent = holder,
			}, { corner(6), gradient(T.Accent, T.Accent2, 0) })
			local lbl = new("TextLabel", {
				Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = tostring(opt), Font = T.Font, TextSize = 13,
				TextColor3 = T.SubText, TextTruncate = Enum.TextTruncate.AtEnd, Parent = b,
			})
			b.MouseButton1Click:Connect(function() obj:Set(opt) end)
			table.insert(btns, { btn = b, lbl = lbl, opt = opt })
		end
		paint()
	end
	function obj:Set(v, silent)
		if table.find(options, v) == nil then return end
		local changed = v ~= value
		value = v
		paint()
		setFlag(cfg, v)
		if changed and not silent then safe(cfg.Callback, v) end
	end
	function obj:Get() return value end
	function obj:SetOptions(list, keep)
		options = list or {}
		if not (keep and table.find(options, value)) then value = options[1] end
		build()
		setFlag(cfg, value)
	end
	build()
	setFlag(cfg, value)
	self:_Register(frame, cfg.Name, total)
	obj.Frame = frame
	return regObj(cfg, obj)
end

-- Section:CreateRangeSlider({ Name, Min, Max, Increment, MinGap, Default = { lo, hi }, Suffix, Flag, Callback(lo, hi) })
-- two knobs on one track.  Flag value / :Get() is { lo, hi }.  :Set({ lo, hi })
function Section:CreateRangeSlider(cfg)
	cfg = cfg or {}
	local T = self.Window.Theme
	local tab = self.Tab
	local min, max, inc = cfg.Min or 0, cfg.Max or 100, cfg.Increment or 1
	local gap = cfg.MinGap or 0
	local suffix = cfg.Suffix or ""
	local d = cfg.Default or { min, max }
	local lo, hi = snap(d[1] or min, min, max, inc), snap(d[2] or max, min, max, inc)
	if lo > hi then lo, hi = hi, lo end
	local touch = UserInputService.TouchEnabled
	local total = touch and 50 or 42
	local knobS, knobBig = touch and 16 or 12, touch and 20 or 15

	local frame = new("Frame", { Size = UDim2.new(1, 0, 0, total), BackgroundTransparency = 1, Parent = self.Body })
	new("TextLabel", {
		Size = UDim2.new(1, -112, 0, 18), BackgroundTransparency = 1, Text = cfg.Name or "Range", Font = T.Font, TextSize = 14,
		TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
	})
	local valLabel = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(108, 18), BackgroundTransparency = 1,
		Text = "", Font = T.FontBold, TextSize = 13, TextColor3 = T.Accent, TextXAlignment = Enum.TextXAlignment.Right, Parent = frame,
	})
	local hit = new("TextButton", {
		Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 1, -20), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = frame,
	})
	local track = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(1, 0, 0, 4),
		BackgroundColor3 = T.Control, BorderSizePixel = 0, Parent = hit,
	}, { corner(2) })
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = track },
		{ corner(2), gradient(T.Accent, T.Accent2, 0) })
	local function mkKnob()
		return new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(knobS, knobS),
			BackgroundColor3 = T.Knob, BorderSizePixel = 0, ZIndex = 2, Parent = track,
		}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }), stroke(T.Accent, 2, 0) })
	end
	local knobLo, knobHi = mkKnob(), mkKnob()

	local function frac(v) return (max == min) and 0 or (v - min) / (max - min) end
	local function render(animate)
		local a, b = frac(lo), frac(hi)
		valLabel.Text = fmtVal(lo) .. " - " .. fmtVal(hi) .. suffix
		local fp, fs = UDim2.fromScale(a, 0), UDim2.fromScale(b - a, 1)
		local kl, kh = UDim2.fromScale(a, 0.5), UDim2.fromScale(b, 0.5)
		if animate then
			tween(fill, 0.18, { Position = fp, Size = fs })
			tween(knobLo, 0.18, { Position = kl })
			tween(knobHi, 0.18, { Position = kh })
		else
			fill.Position, fill.Size, knobLo.Position, knobHi.Position = fp, fs, kl, kh
		end
	end

	local obj = {}
	function obj:Set(v, silent)
		if type(v) ~= "table" then return end
		local a = snap(tonumber(v[1]) or lo, min, max, inc)
		local b = snap(tonumber(v[2]) or hi, min, max, inc)
		if a > b then a, b = b, a end
		local changed = a ~= lo or b ~= hi
		lo, hi = a, b
		render(true)
		setFlag(cfg, { lo, hi })
		if changed and not silent then safe(cfg.Callback, lo, hi) end
	end
	function obj:Get() return { lo, hi } end
	render(false)
	setFlag(cfg, { lo, hi })

	local function fromX(x, which)
		local a = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		local v = snap(min + (max - min) * a, min, max, inc)
		local nl, nh = lo, hi
		if which == "lo" then nl = math.min(v, hi - gap) else nh = math.max(v, lo + gap) end
		nl, nh = math.clamp(nl, min, max), math.clamp(nh, min, max)
		if nl ~= lo or nh ~= hi then
			lo, hi = nl, nh
			render(false)
			setFlag(cfg, { lo, hi })
			safe(cfg.Callback, lo, hi)
		end
	end

	local moveC, endC, grabbed
	local function stop()
		if moveC then moveC:Disconnect() moveC = nil end
		if endC then endC:Disconnect() endC = nil end
		tab.Scroll.ScrollingEnabled = true
		if grabbed then
			tween(grabbed, 0.16, { Size = UDim2.fromOffset(knobS, knobS) })
			grabbed = nil
		end
	end
	hit.InputBegan:Connect(function(i)
		if not isPress(i) then return end
		stop()
		local isTouch = i.UserInputType == Enum.UserInputType.Touch
		local tx, tw = track.AbsolutePosition.X, math.max(track.AbsoluteSize.X, 1)
		local pl, ph = tx + frac(lo) * tw, tx + frac(hi) * tw
		local x = i.Position.X
		local which
		if lo == hi then
			which = (x < pl) and "lo" or "hi"
		else
			which = (math.abs(x - pl) <= math.abs(x - ph)) and "lo" or "hi"
		end
		tab.Scroll.ScrollingEnabled = false
		grabbed = (which == "lo") and knobLo or knobHi
		tween(grabbed, 0.12, { Size = UDim2.fromOffset(knobBig, knobBig) })
		fromX(x, which)
		moveC = UserInputService.InputChanged:Connect(function(m)
			if isTouch then
				if m ~= i then return end
			elseif m.UserInputType ~= Enum.UserInputType.MouseMovement then
				return
			end
			fromX(m.Position.X, which)
		end)
		endC = onEnd(i, stop)
	end)

	self:_Register(frame, cfg.Name, total)
	obj.Frame = frame
	return regObj(cfg, obj)
end

-- Section:CreateTagInput({ Name, Default = { "a" }, Placeholder, Max, Lower, Flag, Callback(list) })
-- type + Enter (or +) to add a chip, tap the x to remove. "a, b, c" adds three.
-- :Add(tag) / :Remove(tag) / :Has(tag) / :Set(list) / :Get() -> array
function Section:CreateTagInput(cfg)
	cfg = cfg or {}
	local T = self.Window.Theme
	local touch = UserInputService.TouchEnabled
	local tags = {}
	local obj = {}
	local function norm(s)
		s = tostring(s):gsub("^%s+", ""):gsub("%s+$", "")
		if cfg.Lower then s = s:lower() end
		return s
	end
	for _, t in ipairs(cfg.Default or {}) do
		local n = norm(t)
		if n ~= "" and not table.find(tags, n) then table.insert(tags, n) end
	end

	local frame = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Parent = self.Body }, { list(6) })
	new("TextLabel", {
		LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = cfg.Name or "Tags", Font = T.Font, TextSize = 14,
		TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
	})
	local inputRow = new("Frame", { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, touch and 34 or 30), BackgroundTransparency = 1, Parent = frame })
	local box = new("TextBox", {
		Size = UDim2.new(1, -40, 1, 0), BackgroundColor3 = T.Control, BackgroundTransparency = 0.1, BorderSizePixel = 0, Text = "",
		PlaceholderText = cfg.Placeholder or "Add and press Enter", PlaceholderColor3 = T.SubText, TextColor3 = T.Text, Font = T.Font,
		TextSize = 13, TextXAlignment = LEFT, ClearTextOnFocus = false, Parent = inputRow,
	}, { corner(7), stroke(T.Border, 1, 0.4), padding(10, 0, 10, 0) })
	local addBtn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 34, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false, Text = "", Parent = inputRow,
	}, { corner(7), gradient(T.Accent, T.Accent2, 0) })
	new("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "+", Font = T.FontBold, TextSize = 18,
		TextColor3 = Color3.new(1, 1, 1), Parent = addBtn,
	})
	local chips = new("Frame", { LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Parent = frame },
		{ list(6, { FillDirection = Enum.FillDirection.Horizontal, Wraps = true }) })

	local function rebuild()
		for _, c in ipairs(chips:GetChildren()) do
			if c:IsA("GuiObject") then c:Destroy() end
		end
		for idx, tag in ipairs(tags) do
			local chip = new("Frame", {
				LayoutOrder = idx, Size = UDim2.new(0, 0, 0, touch and 30 or 24), AutomaticSize = AX, BackgroundColor3 = T.AccentSoft, BorderSizePixel = 0, Parent = chips,
			}, { corner(12), stroke(T.Accent, 1, 0.6),
				list(0, { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center }),
				padding(10, 0, 4, 0) })
			new("TextLabel", {
				LayoutOrder = 1, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AX, BackgroundTransparency = 1, Text = tag, Font = T.Font,
				TextSize = 12, TextColor3 = T.Text, Parent = chip,
			})
			local x = new("TextButton", {
				LayoutOrder = 2, Size = UDim2.fromOffset(touch and 30 or 22, touch and 30 or 22), BackgroundTransparency = 1, Text = "\u{00D7}", Font = T.FontBold,
				TextSize = 14, TextColor3 = T.SubText, AutoButtonColor = false, Parent = chip,
			})
			x.MouseButton1Click:Connect(function() obj:Remove(tag) end)
		end
	end
	local function commit(silent)
		setFlag(cfg, cloneVal(tags))
		rebuild()
		if not silent then safe(cfg.Callback, cloneVal(tags)) end
	end
	function obj:Add(t, silent)
		t = norm(t)
		if t == "" or table.find(tags, t) then return false end
		if cfg.Max and #tags >= cfg.Max then return false end
		table.insert(tags, t)
		commit(silent)
		return true
	end
	function obj:Remove(t, silent)
		local i = table.find(tags, t)
		if not i then return false end
		table.remove(tags, i)
		commit(silent)
		return true
	end
	function obj:Has(t) return table.find(tags, norm(t)) ~= nil end
	function obj:Set(list, silent)
		tags = {}
		for _, t in ipairs(type(list) == "table" and list or {}) do
			local n = norm(t)
			if n ~= "" and not table.find(tags, n) then table.insert(tags, n) end
		end
		commit(silent)
	end
	function obj:Get() return cloneVal(tags) end

	local function submit()
		for part in box.Text:gmatch("[^,]+") do obj:Add(part) end
		box.Text = ""
	end
	box.FocusLost:Connect(function(enter)
		if enter then submit() end
	end)
	addBtn.MouseButton1Click:Connect(submit)

	rebuild()
	setFlag(cfg, cloneVal(tags))
	self:_Register(frame, cfg.Name, 76)
	obj.Frame = frame
	return regObj(cfg, obj)
end

-- Section:CreateHoldButton({ Name, Duration = 1, Color, DoneText, Callback })
-- must be held until the bar fills: safe for dangerous actions (esp. on a touchscreen)
function Section:CreateHoldButton(cfg)
	cfg = cfg or {}
	local T = self.Window.Theme
	local dur = cfg.Duration or 1
	local accent = cfg.Color or Color3.fromRGB(248, 113, 113)
	local h = rowH()
	local b = new("TextButton", {
		Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = T.Control, BackgroundTransparency = 0.1, AutoButtonColor = false, Text = "",
		ClipsDescendants = true, Parent = self.Body,
	}, { corner(7), stroke(accent, 1, 0.5) })
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = b },
		{ corner(7), gradient(accent, accent:Lerp(Color3.new(1, 1, 1), 0.3), 0) })
	local label = new("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = cfg.Name or "Hold to confirm", Font = T.Font, TextSize = 13,
		TextColor3 = T.Text, ZIndex = 2, Parent = b,
	})
	local obj = { Frame = b }
	function obj:SetText(t)
		cfg.Name = t
		label.Text = t
	end

	local tw, holding, seq = nil, false, 0
	local function down()
		holding = true
		seq += 1
		local mine = seq
		if tw then tw:Cancel() end
		fill.Size = UDim2.fromScale(0, 1)
		local t = TweenService:Create(fill, TweenInfo.new(dur, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(1, 1) })
		tw = t
		t.Completed:Connect(function(state)
			if state ~= Enum.PlaybackState.Completed or tw ~= t or not holding then return end
			holding = false
			tw = nil
			label.Text = cfg.DoneText or "Done"
			safe(cfg.Callback)
			task.delay(0.45, function()
				if seq ~= mine then return end
				label.Text = cfg.Name or "Hold to confirm"
				tween(fill, 0.3, { Size = UDim2.fromScale(0, 1) })
			end)
		end)
		t:Play()
	end
	local function up()
		holding = false
		if tw then
			tw:Cancel()
			tw = nil
			tween(fill, 0.14, { Size = UDim2.fromScale(0, 1) }, QUAD, OUT)
		end
	end
	dragSafePress(b, down, function() up() end, 12)

	self:_Register(b, cfg.Name, h)
	return obj
end

-- Section:CreateGraph({ Name, Points = 30, Height = 56, Min, Max, Suffix, Color, Data })
-- live bar graph. :Push(number) shifts left, :Clear(), :SetRange(min, max). Min / Max nil = auto.
function Section:CreateGraph(cfg)
	cfg = cfg or {}
	local T = self.Window.Theme
	local N = math.clamp(cfg.Points or 30, 5, 120)
	local H = cfg.Height or 56
	local color = cfg.Color or T.Accent
	local suffix = cfg.Suffix or ""
	local total = 22 + H + 4
	local frame = new("Frame", { Size = UDim2.new(1, 0, 0, total), BackgroundTransparency = 1, Parent = self.Body })
	new("TextLabel", {
		Size = UDim2.new(1, -90, 0, 18), BackgroundTransparency = 1, Text = cfg.Name or "Graph", Font = T.Font, TextSize = 14,
		TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
	})
	local valLabel = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(86, 18), BackgroundTransparency = 1,
		Text = "", Font = T.FontBold, TextSize = 13, TextColor3 = T.Accent, TextXAlignment = Enum.TextXAlignment.Right, Parent = frame,
	})
	local area = new("Frame", {
		Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0, H), BackgroundColor3 = T.Control, BackgroundTransparency = 0.15,
		BorderSizePixel = 0, ClipsDescendants = true, Parent = frame,
	}, { corner(7), stroke(T.Border, 1, 0.45) })
	local bars, data = {}, {}
	for i = 1, N do
		bars[i] = new("Frame", {
			AnchorPoint = Vector2.new(0, 1), Position = UDim2.new((i - 1) / N, 1, 1, 0), Size = UDim2.new(1 / N, -2, 0, 0),
			BackgroundColor3 = color, BackgroundTransparency = 0.15, BorderSizePixel = 0, Parent = area,
		})
	end
	local function render()
		local lo, hi = cfg.Min, cfg.Max
		if lo == nil or hi == nil then
			local dmin, dmax = math.huge, -math.huge
			for _, v in ipairs(data) do
				dmin = math.min(dmin, v)
				dmax = math.max(dmax, v)
			end
			if dmin == math.huge then dmin, dmax = 0, 1 end
			if lo == nil then lo = math.min(0, dmin) end
			if hi == nil then hi = dmax end
		end
		if hi == lo then hi = lo + 1 end
		local off = N - #data
		for i = 1, N do
			local v = data[i - off]
			local a = v and math.clamp((v - lo) / (hi - lo), 0, 1) or 0
			bars[i].Size = UDim2.new(1 / N, -2, a, v and 2 or 0)
			bars[i].BackgroundColor3 = (i == N and v) and T.Accent2 or color
		end
	end
	local obj = { Frame = frame }
	function obj:Push(v)
		v = tonumber(v) or 0
		table.insert(data, v)
		if #data > N then table.remove(data, 1) end
		valLabel.Text = fmtVal(v) .. suffix
		render()
	end
	function obj:Clear()
		table.clear(data)
		valLabel.Text = ""
		render()
	end
	function obj:SetRange(lo, hi)
		cfg.Min, cfg.Max = lo, hi
		render()
	end
	function obj:Get() return data[#data] end
	for _, v in ipairs(cfg.Data or {}) do obj:Push(v) end
	render()
	self:_Register(frame, cfg.Name, total)
	return obj
end

-- Section:CreateConsole({ Name, Height = 120, MaxLines = 100, Timestamp = true })
-- scrolling log inside the UI.  :Print(text, color) :Info/:Success/:Warn/:Error(text) :Clear() :GetText() :Copy()
function Section:CreateConsole(cfg)
	cfg = cfg or {}
	local T = self.Window.Theme
	local H = cfg.Height or 120
	local maxLines = cfg.MaxLines or 100
	local total = 24 + H + 4
	local frame = new("Frame", { Size = UDim2.new(1, 0, 0, total), BackgroundTransparency = 1, Parent = self.Body })
	new("TextLabel", {
		Size = UDim2.new(1, -64, 0, 20), BackgroundTransparency = 1, Text = cfg.Name or "Console", Font = T.Font, TextSize = 14,
		TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
	})
	local clearBtn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(52, 20), BackgroundColor3 = T.Control,
		BackgroundTransparency = 0.1, AutoButtonColor = false, Text = "Clear", Font = T.Font, TextSize = 11, TextColor3 = T.SubText, Parent = frame,
	}, { corner(6), stroke(T.Border, 1, 0.4) })
	local view = new("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, H), BackgroundColor3 = T.Deep, BackgroundTransparency = 0.1,
		BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = T.Accent, CanvasSize = UDim2.new(), AutomaticCanvasSize = AY,
		ScrollingDirection = Enum.ScrollingDirection.Y, Parent = frame,
	}, { corner(7), stroke(T.Border, 1, 0.45), list(1), padding(8, 6, 8, 6) })

	local lines, order, scrollQueued = {}, 0, false
	local obj = { Frame = frame }
	local COLORS = {
		Info = T.Text, Success = Color3.fromRGB(52, 211, 153), Warn = Color3.fromRGB(251, 191, 36), Error = Color3.fromRGB(248, 113, 113),
	}
	function obj:Print(text, color)
		order += 1
		local stamp = (cfg.Timestamp ~= false) and (os.date("%H:%M:%S") .. "  ") or ""
		local l = new("TextLabel", {
			LayoutOrder = order, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Text = stamp .. tostring(text),
			Font = Enum.Font.Code, TextSize = 12, TextColor3 = color or T.Text, TextXAlignment = LEFT, TextWrapped = true, Parent = view,
		})
		table.insert(lines, l)
		if #lines > maxLines then
			local old = table.remove(lines, 1)
			old:Destroy()
		end
		if not scrollQueued then
			scrollQueued = true
			task.delay(0.03, function()
				scrollQueued = false
				if view.Parent then view.CanvasPosition = Vector2.new(0, 1e6) end
			end)
		end
		return l
	end
	for name, col in pairs(COLORS) do
		obj[name] = function(self, text) return self:Print(text, col) end
	end
	function obj:Clear()
		for _, l in ipairs(lines) do l:Destroy() end
		lines = {}
	end
	function obj:GetText()
		local out = {}
		for _, l in ipairs(lines) do table.insert(out, l.Text) end
		return table.concat(out, "\n")
	end
	function obj:Copy()
		if type(setclipboard) == "function" then
			pcall(setclipboard, self:GetText())
			return true
		end
		return false
	end
	clearBtn.MouseButton1Click:Connect(function() obj:Clear() end)
	self:_Register(frame, cfg.Name, total)
	return obj
end

---------------------------------------------------------------- universal control methods
local NOVALUE = { Progress = true, Badge = true, Label = true, Paragraph = true, Graph = true, Console = true, Separator = true }

local function buildMenuItems(entry)
	local obj, win = entry.Obj, entry.Section.Window
	local items = {}
	if entry.Flag and obj.Get and obj.IsModified then
		table.insert(items, { Name = "Reset to default", Disabled = not obj:IsModified(), Callback = function() obj:Reset() end })
		table.insert(items, { Name = "Copy value", Callback = function()
			local ok, v = pcall(obj.Get, obj)
			if ok then copyValue(win, v) end
		end })
	end
	if obj.SetEnabled then
		table.insert(items, { Name = obj._locked and "Unlock" or "Lock", Callback = function() obj:SetEnabled(obj._locked) end })
	end
	if obj._tipText and obj._tipText ~= "" then
		table.insert(items, { Name = "What is this?", Callback = function()
			win:Notify({ Title = entry.Name, Content = obj._tipText, Kind = "Info", Duration = 5 })
		end })
	end
	local custom = entry.Cfg.ContextMenu
	if type(custom) == "table" and #custom > 0 then
		if #items > 0 then table.insert(items, { Separator = true }) end
		for _, it in ipairs(custom) do
			table.insert(items, {
				Name = it.Name, Color = it.Color, Disabled = it.Disabled,
				Callback = function() safe(it.Callback, obj) end,
			})
		end
	end
	return items
end

local function attachMenu(entry)
	local frame, win = entry.Frame, entry.Section.Window
	local function open()
		if Library.ContextMenu == false then return end
		local items = buildMenuItems(entry)
		if #items > 0 then Library:ShowMenu(items, frame, win) end
	end
	local function hookRight(g)
		g.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton2 then open() end
		end)
	end
	if UserInputService.MouseEnabled then
		hookRight(frame)
		for _, d in ipairs(frame:GetDescendants()) do
			if d:IsA("GuiButton") then hookRight(d) end
		end
	end
	if not UserInputService.TouchEnabled then return end
	-- touch: hold a finger still to open the menu; moving more than 10px (a scroll) cancels it
	frame.InputBegan:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.Touch then return end
		local start = Vector2.new(i.Position.X, i.Position.Y)
		local held = true
		local mc = UserInputService.InputChanged:Connect(function(m)
			if m == i and (Vector2.new(m.Position.X, m.Position.Y) - start).Magnitude > 10 then held = false end
		end)
		onEnd(i, function()
			held = false
			mc:Disconnect()
		end)
		task.delay(Library.MenuHold or 0.55, function()
			if held then
				held = false
				mc:Disconnect()
				open()
			end
		end)
	end)
end

local function decorate(sec, kind, cfg, obj)
	local win = sec.Window
	local T = win.Theme
	local frame = obj.Frame
	if typeof(frame) ~= "Instance" then return end
	obj.Kind = obj.Kind or kind

	local ctl
	for _, c in ipairs(sec.Controls) do
		if c.Frame == frame then ctl = c break end
	end
	local entry = {
		Kind = kind, Name = tostring(cfg.Name or cfg.Title or cfg.Text or kind), Obj = obj, Cfg = cfg, Section = sec, Tab = sec.Tab,
		Frame = frame, Ctl = ctl, Flag = cfg.Flag, SectionName = sec.Name, TabName = sec.Tab.Name,
	}
	win._index = win._index or {}
	table.insert(win._index, entry)
	if cfg.Flag then Library._names[cfg.Flag] = entry.Name end

	local conns = {}
	local function def(name, fn)
		if obj[name] == nil then obj[name] = fn end
	end

	-- default value + "modified" dot + reset
	if cfg.Flag and obj.Get and obj.Set and not NOVALUE[kind] then
		local ok, v = pcall(obj.Get, obj)
		if ok then
			obj._default = cloneVal(v)
			obj._hasDefault = true
		end
		local dot
		table.insert(conns, Library:Watch(cfg.Flag, function(val)
			local on = obj._hasDefault and not deepEq(val, obj._default) or false
			if on and not dot then
				dot = new("Frame", {
					Name = "ModDot", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 1, 0, 14), Size = UDim2.fromOffset(4, 4),
					BackgroundColor3 = T.Accent, BorderSizePixel = 0, ZIndex = 5, Parent = frame,
				}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
			end
			if dot then dot.Visible = on end
		end))
		sec._objs = sec._objs or {}
		table.insert(sec._objs, obj)
	end
	def("IsModified", function(self)
		if not self._hasDefault or not self.Get then return false end
		local ok, cur = pcall(self.Get, self)
		return ok and not deepEq(cur, self._default)
	end)
	def("Reset", function(self, silent)
		if not self._hasDefault then return false end
		self:Set(cloneVal(self._default), silent)
		return true
	end)

	def("OnChange", function(self, fn)
		if not cfg.Flag then
			warn("[SpectreUI] OnChange needs a Flag on '" .. entry.Name .. "'")
			return { Disconnect = function() end }
		end
		local c = Library:Watch(cfg.Flag, fn)
		table.insert(conns, c)
		return c
	end)

	-- show / hide (works together with the search filter)
	def("SetVisible", function(self, v)
		v = v and true or false
		if ctl then ctl.Hidden = not v end
		if sec.Tab == win.Active then
			win:_ApplySearch()
		else
			frame.Visible = v
		end
		sec.Tab:_QueueRelayout()
	end)
	def("IsVisible", function() return not (ctl and ctl.Hidden) end)

	-- ShowIf("flag") / ShowIf("flag", value) / ShowIf("flag", function(v, flags)) / ShowIf({ "a", "b" }, function(flags))
	def("ShowIf", function(self, src, expected)
		if self._showConn then self._showConn.Disconnect() end
		local flags = type(src) == "table" and src or { src }
		local function eval()
			local ok, show = pcall(function()
				if type(expected) == "function" then
					if type(src) == "table" then return expected(Library.Flags) end
					return expected(Library.Flags[flags[1]], Library.Flags)
				elseif expected == nil then
					return Library.Flags[flags[1]]
				end
				return deepEq(Library.Flags[flags[1]], expected)
			end)
			self:SetVisible(ok and show and true or false)
		end
		local cs = {}
		for _, f in ipairs(flags) do table.insert(cs, Library:Watch(f, eval)) end
		self._showConn = { Disconnect = function() for _, c in ipairs(cs) do c:Disconnect() end end }
		table.insert(conns, self._showConn)
		eval()
		return self
	end)

	-- lock: dims the control and swallows input
	def("SetEnabled", function(self, v)
		local locked = not v
		self._locked = locked
		if locked and self.IsOpen and self.Close then pcall(self.Close, self) end
		if locked and not self._lockGui then
			self._lockGui = new("TextButton", {
				Name = "Lock", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Background, BackgroundTransparency = 0.35, Text = "",
				AutoButtonColor = false, Active = true, ZIndex = 20, Visible = false, Parent = frame,
			}, { corner(7) })
		end
		if self._lockGui then self._lockGui.Visible = locked end
	end)
	def("Lock", function(self) self:SetEnabled(false) end)
	def("Unlock", function(self) self:SetEnabled(true) end)
	def("IsEnabled", function(self) return not self._locked end)

	-- tooltip (hover on PC, "What is this?" in the long-press menu on touch)
	def("SetTooltip", function(self, text)
		self._tipText = text
		if not self._tipBound and text and text ~= "" then
			self._tipBound = true
			win:Tooltip(frame, function() return self._tipText end)
		end
	end)
	if cfg.Tooltip then obj:SetTooltip(cfg.Tooltip) end

	def("Destroy", function(self)
		for _, c in ipairs(conns) do c.Disconnect() end
		table.clear(conns)
		for i, c in ipairs(sec.Controls) do
			if c == ctl then table.remove(sec.Controls, i) break end
		end
		for i, c in ipairs(sec.Controls) do c.Frame.LayoutOrder = i end
		local ix = table.find(win._index, entry)
		if ix then table.remove(win._index, ix) end
		if sec._objs then
			local ox = table.find(sec._objs, self)
			if ox then table.remove(sec._objs, ox) end
		end
		if cfg.Flag and Library.Objects[cfg.Flag] == self then
			Library.Objects[cfg.Flag] = nil
			Library.Flags[cfg.Flag] = nil
		end
		frame:Destroy()
		sec.Tab:_QueueRelayout()
	end)

	if (cfg.Flag and obj.Get and not NOVALUE[kind]) or cfg.ContextMenu then
		if not cfg.NoMenu then attachMenu(entry) end
	end
end

for fname, kind in pairs({
	CreateLabel = "Label", CreateButton = "Button", CreateToggle = "Toggle", CreateSlider = "Slider", CreateDropdown = "Dropdown",
	CreateParagraph = "Paragraph", CreateTextbox = "Textbox", CreateKeybind = "Keybind", CreateColorPicker = "ColorPicker",
	CreateBadge = "Badge", CreateProgress = "Progress", CreateSeparator = "Separator", CreateKeybindToggle = "KeybindToggle",
	CreateSegmented = "Segmented", CreateRangeSlider = "RangeSlider", CreateTagInput = "TagInput", CreateHoldButton = "HoldButton",
	CreateGraph = "Graph", CreateConsole = "Console",
}) do
	local orig = Section[fname]
	if orig then
		Section[fname] = function(self, cfg, ...)
			local obj = orig(self, cfg, ...)
			if type(obj) == "table" then
				local ok, err = pcall(decorate, self, kind, type(cfg) == "table" and cfg or { Name = cfg }, obj)
				if not ok then warn("[SpectreUI] decorate(" .. kind .. ") failed: " .. tostring(err)) end
			end
			return obj
		end
	end
end

---------------------------------------------------------------- reset helpers
function Section:ResetAll()
	local n = 0
	Library:Transaction("Reset section", function()
		for _, o in ipairs(self._objs or {}) do
			if o:IsModified() then
				o:Reset()
				n += 1
			end
		end
	end)
	return n
end

function Tab:ResetAll()
	local n = 0
	Library:Transaction("Reset tab", function()
		for _, s in ipairs(self.Sections) do n += s:ResetAll() end
	end)
	return n
end

-- flags whose value differs from the default the control was created with
function Library:GetModified()
	local out = {}
	for flag, o in pairs(self.Objects) do
		if o.IsModified and o:IsModified() then table.insert(out, flag) end
	end
	table.sort(out)
	return out
end

function Library:ResetAll()
	local n = 0
	self:Transaction("Reset all", function()
		for _, flag in ipairs(self:GetModified()) do
			local o = self.Objects[flag]
			if o and o:Reset() then n += 1 end
		end
	end)
	return n
end

end

---------------------------------------------------------------- v3.5  theme manager: rename / live switch / clone / persist
do
local DERIVED = { "Top", "Deep", "Lift", "Wash", "Knob" }
local PRIORITY = { "Accent", "Accent2", "Border", "Background", "Panel", "Card", "Control", "AccentSoft", "Sheen", "SubText", "Text", "Top", "Deep", "Lift", "Wash", "Knob" }
local SAVE_KEYS = { "Background", "Panel", "Card", "Control", "Border", "Accent", "Accent2", "AccentSoft", "Sheen", "Text", "SubText" }
local WHITE = Color3.new(1, 1, 1)

Library.ThemeName = "Rose"
Library._builtin, Library._alias, Library._themeSubs = {}, {}, {}
for k in pairs(Library.Themes) do Library._builtin[k] = true end

local function q255(x) return math.floor(x * 255 + 0.5) end
local function qkey(c) return q255(c.R) * 65536 + q255(c.G) * 256 + q255(c.B) end
local function plain(c) local k = qkey(c) return k == 0 or k == 0xFFFFFF end
local function toHex(c) return string.format("#%02X%02X%02X", q255(c.R), q255(c.G), q255(c.B)) end
local function fromHex(s)
	local r, g, b = tostring(s):match("^#?(%x%x)(%x%x)(%x%x)$")
	if not r then return nil end
	return Color3.fromRGB(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16))
end
local function cleanThemeName(n)
	if type(n) ~= "string" then return nil end
	n = n:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%c", "")
	if n == "" then return nil end
	return n:sub(1, 28)
end

-- events: "rename" (old, new) · "switch" (win, name) · "list" ()
local function fire(ev, a, b)
	for i = #Library._themeSubs, 1, -1 do
		local s = Library._themeSubs[i]
		if s.alive and not s.alive() then
			table.remove(Library._themeSubs, i)
		else
			pcall(s.fn, ev, a, b)
		end
	end
end
-- Library:OnThemeChange(fn(event, a, b)) -> { Disconnect }
function Library:OnThemeChange(fn, alive)
	local s = { fn = fn, alive = alive }
	table.insert(self._themeSubs, s)
	return { Disconnect = function() local i = table.find(Library._themeSubs, s) if i then table.remove(Library._themeSubs, i) end end }
end

------------------------------------------------------------ persistence (needs writefile)
local function themeFile() return Library.ConfigFolder .. "/themes.json" end

function Library:SaveThemes()
	if not fsReady() then return false, "writefile is not supported here" end
	local data = { current = self.ThemeName, renamed = {}, custom = {} }
	for cur, orig in pairs(self._alias) do
		if cur ~= orig then data.renamed[orig] = cur end
	end
	for name, t in pairs(self.Themes) do
		if not self._builtin[name] and not self._alias[name] then
			local o = { FX = t.FX }
			for _, k in ipairs(SAVE_KEYS) do if typeof(t[k]) == "Color3" then o[k] = toHex(t[k]) end end
			data.custom[name] = o
		end
	end
	local ok, err = pcall(function()
		ensureFolder(self.ConfigFolder)
		writefile(themeFile(), HttpService:JSONEncode(data))
	end)
	return ok, ok and true or tostring(err)
end

function Library:LoadThemes(quiet)
	self._themesLoaded = true
	if not fsReady() or type(isfile) ~= "function" then return false end
	local ok, data = pcall(function()
		local p = themeFile()
		if not isfile(p) then return nil end
		return HttpService:JSONDecode(readfile(p))
	end)
	if not ok or type(data) ~= "table" then return false end
	for name, o in pairs(data.custom or {}) do
		if type(name) == "string" and type(o) == "table" and not self.Themes[name] then
			local t = { FX = type(o.FX) == "string" and o.FX or "orbs" }
			for _, k in ipairs(SAVE_KEYS) do
				local c = fromHex(o[k])
				if c then t[k] = c end
			end
			self.Themes[name] = t
		end
	end
	for orig, new in pairs(data.renamed or {}) do
		if self.Themes[orig] and type(new) == "string" and not self.Themes[new] then
			self._silent = true
			self:RenameTheme(orig, new)
			self._silent = nil
		end
	end
	if not self._userSetTheme and type(data.current) == "string" and self.Themes[data.current] then
		self.Theme = buildTheme(self.Themes[data.current])
		self.ThemeName = data.current
	end
	if not quiet then fire("list") end
	return true
end

------------------------------------------------------------ Library: rename / clone / delete
-- Library:RenameTheme("Rose", "Sakura Night") -> ok, err
function Library:RenameTheme(old, new)
	new = cleanThemeName(new)
	if type(old) ~= "string" or not self.Themes[old] then return false, "unknown theme" end
	if not new then return false, "invalid name" end
	if new == old then return true, new end
	if self.Themes[new] then return false, "a theme with that name already exists" end

	self.Themes[new] = self.Themes[old]
	self.Themes[old] = nil
	local orig = self._alias[old] or (self._builtin[old] and old) or nil
	self._alias[old] = nil
	if orig then self._alias[new] = orig end

	if self.ThemeName == old then self.ThemeName = new end
	for _, w in ipairs(self.Windows) do
		if w.ThemeName == old then w.ThemeName = new end
	end
	if not self._silent then
		self:SaveThemes()
		fire("rename", old, new)
		fire("list")
	end
	return true, new
end

-- Library:CloneTheme("Rose", "My Pink", { Accent = Color3.fromRGB(...) }) -> ok, name|err
function Library:CloneTheme(src, newName, overrides)
	local base = self.Themes[src]
	newName = cleanThemeName(newName)
	if not base then return false, "unknown theme" end
	if not newName then return false, "invalid name" end
	if self.Themes[newName] then return false, "a theme with that name already exists" end
	local t = {}
	for k, v in pairs(base) do t[k] = v end
	for k, v in pairs(overrides or {}) do t[k] = v end
	for _, k in ipairs(DERIVED) do if not (overrides and overrides[k]) then t[k] = nil end end
	local ok, err = self:RegisterTheme(newName, t)
	if not ok then return false, err end
	self:SaveThemes()
	fire("list")
	return true, newName
end

-- custom themes only (built-ins can be renamed but not deleted)
function Library:DeleteTheme(name)
	if not self.Themes[name] then return false, "unknown theme" end
	if self._builtin[name] or self._alias[name] then return false, "built-in themes can only be renamed" end
	if self.ThemeName == name then return false, "this theme is the current default" end
	self.Themes[name] = nil
	self:SaveThemes()
	fire("list")
	return true
end

local prevSetTheme = Library.SetTheme
function Library:SetTheme(t)
	local ok = prevSetTheme(self, t)
	if ok then
		self.ThemeName = type(t) == "string" and t or "Custom"
		self._userSetTheme = true
	end
	return ok
end

------------------------------------------------------------ Window: live switch
local function lerpWhiteT(c, base)
	-- is c == base:Lerp(white, t)?  returns t or nil
	local dr, dg, db = 1 - base.R, 1 - base.G, 1 - base.B
	local d, num = dr, c.R - base.R
	if dg > d then d, num = dg, c.G - base.G end
	if db > d then d, num = db, c.B - base.B end
	if d < 0.15 then return nil end
	local t = num / d
	if t < 0.04 or t > 0.96 then return nil end
	if math.abs(base.R + dr * t - c.R) > 0.016 or math.abs(base.G + dg * t - c.G) > 0.016 or math.abs(base.B + db * t - c.B) > 0.016 then return nil end
	return t
end

-- Window:SetTheme("Cyber" | { Accent = ... }, remember)
-- recolors the whole window live (controls, strokes, gradients, glow, backdrop).  remember = true -> default for new windows + saved.
function Window:SetTheme(t, remember)
	local name, src
	if type(t) == "string" then
		src = Library.Themes[t]
		name = t
		if not src then return false, "unknown theme" end
	elseif type(t) == "table" then
		src = {}
		for k, v in pairs(self.Theme) do src[k] = v end
		for _, k in ipairs(DERIVED) do src[k] = nil end
		for k, v in pairs(t) do src[k] = v end
		name = "Custom"
	else
		return false, "usage: SetTheme(name | table)"
	end

	local T = self.Theme
	local nt = deriveTheme(buildTheme(src))
	local map, oldA, oldA2, newA, newA2 = {}, T.Accent, T.Accent2, nt.Accent, nt.Accent2
	for _, k in ipairs(PRIORITY) do
		local o, n = T[k], nt[k]
		if typeof(o) == "Color3" and typeof(n) == "Color3" and not plain(o) then
			local key = qkey(o)
			if map[key] == nil then map[key] = n end
		end
	end

	-- the same table is captured by every control, so mutate it in place
	for k in pairs(T) do T[k] = nil end
	for k, v in pairs(nt) do T[k] = v end

	local function remap(c)
		local n = map[qkey(c)]
		if n then return n end
		if plain(c) then return nil end
		local tt = lerpWhiteT(c, oldA)           -- accent tinted toward white (selected text, hover strokes ...)
		if tt then return newA:Lerp(WHITE, tt) end
		tt = lerpWhiteT(c, oldA2)
		if tt then return newA2:Lerp(WHITE, tt) end
		return nil
	end

	for _, o in ipairs(self.Gui:GetDescendants()) do
		if o:IsA("GuiObject") then
			local n = remap(o.BackgroundColor3) if n then o.BackgroundColor3 = n end
			if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
				n = remap(o.TextColor3) if n then o.TextColor3 = n end
				if o:IsA("TextBox") then n = remap(o.PlaceholderColor3) if n then o.PlaceholderColor3 = n end end
			elseif o:IsA("ImageLabel") or o:IsA("ImageButton") then
				n = remap(o.ImageColor3) if n then o.ImageColor3 = n end
			elseif o:IsA("ScrollingFrame") then
				n = remap(o.ScrollBarImageColor3) if n then o.ScrollBarImageColor3 = n end
			end
		elseif o:IsA("UIStroke") then
			local n = remap(o.Color) if n then o.Color = n end
		elseif o:IsA("UIGradient") then
			local changed, kps = false, {}
			for i, kp in ipairs(o.Color.Keypoints) do
				local n = remap(kp.Value)
				if n then changed = true end
				kps[i] = ColorSequenceKeypoint.new(kp.Time, n or kp.Value)
			end
			if changed then o.Color = ColorSequence.new(kps) end
		end
	end

	if self.FXOn then self:SetBackground(self.Cfg.FX or T.FX, true) end   -- rebuild backdrop with the new colours
	self.ThemeName = name
	pcall(self.Flash, self, T.Accent)
	if remember then
		if type(t) == "string" then Library:SetTheme(t) end
		Library:SaveThemes()
	end
	fire("switch", self, name)
	return true, name
end

function Window:GetThemeName() return self.ThemeName end

-- Window:RenameTheme("My new name") renames the theme this window uses.
-- A "Custom" (table) theme gets registered under the new name first.
function Window:RenameTheme(new)
	local cur = self.ThemeName
	if not Library.Themes[cur] then
		new = cleanThemeName(new)
		if not new then return false, "invalid name" end
		if Library.Themes[new] then return false, "a theme with that name already exists" end
		local snap = {}
		for _, k in ipairs(SAVE_KEYS) do snap[k] = self.Theme[k] end
		snap.FX = self.Theme.FX
		local ok, err = Library:RegisterTheme(new, snap)
		if not ok then return false, err end
		self.ThemeName = new
		Library:SaveThemes()
		fire("list")
		return true, new
	end
	return Library:RenameTheme(cur, new)
end

-- Window:CycleTheme(1) -> next theme in the list, (-1) -> previous.  remember defaults to true.
function Window:CycleTheme(dir, remember)
	local list = Library:ListThemes()
	if #list == 0 then return false, "no themes" end
	local idx = table.find(list, self.ThemeName) or 0
	local n = #list
	local nextName = list[((idx - 1 + (dir or 1)) % n) + 1]
	return self:SetTheme(nextName, remember ~= false)
end

-- Window:RandomTheme() -> picks a different theme at random
function Window:RandomTheme(remember)
	local list, pool = Library:ListThemes(), {}
	for _, n in ipairs(list) do if n ~= self.ThemeName then table.insert(pool, n) end end
	if #pool == 0 then return false, "no other theme" end
	return self:SetTheme(pool[math.random(#pool)], remember ~= false)
end

-- Window:DeleteTheme(name?) -> deletes a custom theme (default: the one in use) after switching to a built-in one
function Window:DeleteTheme(name)
	name = name or self.ThemeName
	if not Library.Themes[name] then return false, "unknown theme" end
	if Library._builtin[name] or Library._alias[name] then return false, "built-in themes can only be renamed" end
	if self.ThemeName == name or Library.ThemeName == name then
		local fallback
		for _, n in ipairs(Library:ListThemes()) do
			if Library._builtin[n] or Library._alias[n] then fallback = n break end
		end
		if not fallback then return false, "no built-in theme to switch to" end
		local ok, err = self:SetTheme(fallback, true)
		if not ok then return false, err end
	end
	return Library:DeleteTheme(name)
end

------------------------------------------------------------ Section: ready-made UI
-- Section:CreateThemeManager({ Name, Flag, Remember = true })
--   dropdown (live switch) · textbox + "Rename" button · "Duplicate" button
function Section:CreateThemeManager(cfg)
	cfg = cfg or {}
	local win = self.Window
	local pending = win.ThemeName
	local dd, tb
	local function toast(msg, kind) pcall(function() win:Toast(msg, kind) end) end

	dd = self:CreateDropdown({
		Name = cfg.Name or "Theme", Options = Library:ListThemes(), Default = win.ThemeName, Flag = cfg.Flag,
		Tooltip = "Switch the colour theme of this window",
		Callback = function(v)
			if type(v) == "string" and v ~= win.ThemeName then
				local ok, err = win:SetTheme(v, cfg.Remember ~= false)
				if not ok then toast(tostring(err), "Error") end
			end
		end,
	})
	tb = self:CreateTextbox({
		Name = cfg.RenameLabel or "Theme name", Default = win.ThemeName, Placeholder = "new theme name", MaxLength = 28,
		Callback = function(v) pending = v end,
	})
	local function sync()
		dd:Refresh(Library:ListThemes(), true)
		dd:Set(win.ThemeName, true)
		tb:Set(win.ThemeName, true)
		pending = win.ThemeName
	end
	self:CreateButton({
		Name = cfg.RenameButton or "Rename theme", Gradient = { win.Theme.Accent, win.Theme.Accent2 }, Bold = true,
		Callback = function()
			local old = win.ThemeName
			local ok, res = win:RenameTheme(pending or tb:Get())
			if ok then
				sync()
				toast("Renamed to \"" .. tostring(res) .. "\"", "Success")
			else
				tb:Set(old, true)
				toast(tostring(res), "Error")
			end
		end,
	})
	self:CreateButton({
		Name = cfg.DuplicateButton or "Duplicate theme",
		Callback = function()
			local base = win.ThemeName
			local name, i = base .. " Copy", 2
			while Library.Themes[name] do name = base .. " Copy " .. i i += 1 end
			local ok, res
			if Library.Themes[base] then
				ok, res = Library:CloneTheme(base, name)
			else
				ok, res = false, "save the theme with a name first"
			end
			if ok then
				win:SetTheme(res, cfg.Remember ~= false)
				sync()
				toast("Created \"" .. res .. "\" - rename it below", "Success")
			else
				toast(tostring(res), "Error")
			end
		end,
	})

	if cfg.Random ~= false then
		self:CreateButton({
			Name = cfg.RandomButton or "Random theme",
			Callback = function()
				local ok, err = win:RandomTheme(cfg.Remember ~= false)
				if not ok then toast(tostring(err), "Error") end
			end,
		})
	end
	if cfg.Delete ~= false then
		self:CreateButton({
			Name = cfg.DeleteButton or "Delete theme", Color = Color3.fromRGB(248, 113, 113),
			Callback = function()
				local name = win.ThemeName
				if Library._builtin[name] or Library._alias[name] or not Library.Themes[name] then
					return toast("Only custom themes can be deleted", "Warning")
				end
				local function doDelete()
					local ok, err = win:DeleteTheme(name)
					if ok then toast("Deleted \"" .. name .. "\"", "Success") else toast(tostring(err), "Error") end
				end
				if type(win.Confirm) == "function" then
					win:Confirm({ Title = "Delete theme", Content = "Delete \"" .. name .. "\"?", Yes = "Delete", No = "Cancel", Danger = true, OnYes = doDelete })
				else
					doDelete()
				end
			end,
		})
	end

	-- keep the dropdown in sync when themes change elsewhere
	Library:OnThemeChange(function(ev)
		if ev == "list" or ev == "rename" or ev == "switch" then sync() end
	end, function() return dd.Frame and dd.Frame.Parent ~= nil end)
	return dd
end

------------------------------------------------------------ Window: ready-made tabs (v3.7)
-- Window:CreateThemeTab(cfg)    -> tab, parts      ready THEME tab
-- Window:CreateSettingsTab(cfg) -> tab, parts      ready SETTINGS tab
-- Window:CreateDefaultTabs({ Theme = {...} | false, Settings = {...} | false }) -> themeTab, settingsTab
--
-- Common cfg : Name, Icon, FlagPrefix (default "ui_"), Text = { key = "override text" }  (translate / rename anything)
-- Theme tab  : Manager = { Random = false, Delete = false, Remember = true, Flag }  Maker = false  Effects = false  Keys = false | { Next, Prev }
--              MakerColors = { Accent, Accent2 }   Tip = false | "text"
-- Settings   : Sections = { Theme = false, Hotkeys = false, Config = false, Window = false, History = false }   (false hides that section)
--              ToggleKeyFlag is FlagPrefix .. "menu_key"
local function tx(L, key, default)
	local v = L and L[key]
	if type(v) == "string" then return v end
	return default
end

function Window:CreateThemeTab(cfg)
	cfg = cfg or {}
	local win = self
	local L = cfg.Text or {}
	local P = cfg.FlagPrefix or "ui_"
	local I = cfg.Icons or {}   -- Icons = { Theme = "lucide:...", Save = false, ... }  (false = no icon)
	local function ico(k, d) local v = I[k] if v == nil then return d end return v or nil end
	local tab = self:CreateTab({ Name = cfg.Name or "THEME", Icon = cfg.Icon or "lucide:palette" })
	local parts = { Tab = tab }

	-- theme dropdown + rename / duplicate / random / delete
	local sec = tab:CreateSection({ Icon = ico("ThemeSection", "lucide:paintbrush"), Name = tx(L, "ThemeSection", "Theme colors"), Column = 1 })
	local m = {}
	for k, v in pairs(cfg.Manager or {}) do m[k] = v end
	m.Name = m.Name or tx(L, "Theme", "Theme")
	m.RenameLabel = m.RenameLabel or tx(L, "RenameLabel", "Theme name")
	m.RenameButton = m.RenameButton or tx(L, "RenameButton", "Rename theme")
	m.DuplicateButton = m.DuplicateButton or tx(L, "DuplicateButton", "Duplicate theme")
	m.RandomButton = m.RandomButton or tx(L, "RandomButton", "Random theme")
	m.DeleteButton = m.DeleteButton or tx(L, "DeleteButton", "Delete theme (custom only)")
	parts.Manager = sec:CreateThemeManager(m)
	parts.ManagerSection = sec
	if cfg.Tip ~= false then
		sec:CreateParagraph({
			Title = tx(L, "TipTitle", "Tip"),
			Content = type(cfg.Tip) == "string" and cfg.Tip or tx(L, "Tip", "Pick a theme from the dropdown - the whole window and the background change instantly. Your choice is remembered."),
		})
	end

	-- build a theme from two picked colours
	if cfg.Maker ~= false then
		local mk = tab:CreateSection({ Icon = ico("MakerSection", "lucide:pipette"), Name = tx(L, "MakerSection", "Create your own theme"), Column = 2 })
		local mc = cfg.MakerColors or {}
		local c1 = mk:CreateColorPicker({ Name = tx(L, "Accent", "Accent color"), Default = mc.Accent or Color3.fromRGB(56, 189, 248) })
		local c2 = mk:CreateColorPicker({ Name = tx(L, "Accent2", "Accent 2 color"), Default = mc.Accent2 or Color3.fromRGB(99, 102, 241) })
		local nm = mk:CreateTextbox({ Name = tx(L, "NewName", "New theme name"), Default = tx(L, "NewNameDefault", "My Theme"),
			Placeholder = tx(L, "NewNamePlaceholder", "name..."), MaxLength = 28 })
		mk:CreateButton({ Icon = ico("CreateButton", "lucide:plus"), Name = tx(L, "CreateButton", "Create + use this theme"), Gradient = { win.Theme.Accent, win.Theme.Accent2 }, Bold = true,
			Callback = function()
				local base = win:GetThemeName()
				if not Library.Themes[base] then base = "Rose" end
				local ok, res = Library:CloneTheme(base, nm:Get(), { Accent = c1:Get(), Accent2 = c2:Get() })
				if ok then
					win:SetTheme(res, true)
					win:Success(tx(L, "ThemeNotifyTitle", "Theme"), tx(L, "Created", "Created") .. " \"" .. res .. "\"", 3)
				else
					win:Error(tx(L, "ThemeNotifyTitle", "Theme"), tostring(res), 3)
				end
			end })
		parts.Maker = { Accent = c1, Accent2 = c2, Name = nm, Section = mk }
	end

	-- backdrop effect / quality / quick-switch keys
	if cfg.Effects ~= false then
		local fx = tab:CreateSection({ Icon = ico("FxSection", "lucide:sparkles"), Name = tx(L, "FxSection", "Background / effects"), Column = 2 })
		local AUTO, OFF = tx(L, "FxAuto", "Follow theme"), tx(L, "FxOff", "Off")
		parts.Background = fx:CreateDropdown({ Name = tx(L, "FxName", "Background effect"),
			Options = { AUTO, "petals", "orbs", "embers", "rain", "grid", OFF }, Default = AUTO, Flag = P .. "bg_fx",
			Callback = function(v)
				if v == OFF then win:SetBackground(false)
				elseif v == AUTO then win:SetBackground(nil)
				elseif v then win:SetBackground(v) end
			end })
		parts.Quality = fx:CreateSegmented({ Name = tx(L, "Quality", "Quality"), Options = { "auto", "low", "high" }, Default = "auto", Flag = P .. "quality",
			Tooltip = tx(L, "QualityTip", "low = no gradients / effects, best for phones"),
			Callback = function(q) Library:SetQuality(q) end })
		if cfg.Keys ~= false then
			local k = type(cfg.Keys) == "table" and cfg.Keys or {}
			parts.NextKey = fx:CreateKeybind({ Name = tx(L, "NextTheme", "Next theme"), Default = k.Next or Enum.KeyCode.F6, Mode = "Press",
				Flag = P .. "theme_next", Callback = function() win:CycleTheme(1) end })
			parts.PrevKey = fx:CreateKeybind({ Name = tx(L, "PrevTheme", "Previous theme"), Default = k.Prev or Enum.KeyCode.F5, Mode = "Press",
				Flag = P .. "theme_prev", Callback = function() win:CycleTheme(-1) end })
		end
		parts.EffectsSection = fx
	end
	return tab, parts
end

function Window:CreateSettingsTab(cfg)
	cfg = cfg or {}
	local win = self
	local L = cfg.Text or {}
	local P = cfg.FlagPrefix or "ui_"
	local I = cfg.Icons or {}   -- Icons = { Theme = "lucide:...", Save = false, ... }  (false = no icon)
	local function ico(k, d) local v = I[k] if v == nil then return d end return v or nil end
	local S = cfg.Sections or {}
	local tab = self:CreateTab({ Name = cfg.Name or "SETTINGS", Icon = cfg.Icon or "lucide:settings" })
	local parts = { Tab = tab }
	local CFG_T = tx(L, "ConfigTitle", "Config")

	-- quick theme switch (the full Theme tab with maker / effects still lives in Window:CreateThemeTab)
	if S.Theme ~= false then
		local th = tab:CreateSection({ Icon = ico("ThemeSection", "lucide:palette"), Name = tx(L, "ThemeSection", "Theme"), Column = 1 })
		local dd = th:CreateDropdown({ Name = tx(L, "Theme", "Theme"), Options = Library:ListThemes(),
			Default = win:GetThemeName(), Flag = P .. "settings_theme",
			Tooltip = tx(L, "ThemeTip", "Switch the colour theme of this window"),
			Callback = function(v)
				if type(v) ~= "string" or v == win:GetThemeName() then return end
				local ok, res = win:SetTheme(v, true)
				if not ok then win:Error(tx(L, "ThemeNotifyTitle", "Theme"), tostring(res), 3) end
			end })
		th:CreateButton({ Icon = ico("RandomButton", "lucide:dices"), Name = tx(L, "RandomButton", "Random theme"), Callback = function()
			local ok, res = win:RandomTheme(true)
			if not ok then win:Error(tx(L, "ThemeNotifyTitle", "Theme"), tostring(res), 3) end
		end })
		-- stay in sync when the theme changes from the Theme tab, a keybind cycle, config load, undo, etc.
		Library:OnThemeChange(function(ev)
			if ev == "list" or ev == "rename" or ev == "switch" then
				dd:Refresh(Library:ListThemes(), true)
				dd:Set(win:GetThemeName(), true)
			end
		end, function() return dd.Frame and dd.Frame.Parent ~= nil end)
		parts.ThemePicker, parts.ThemeSection = dd, th
	end

	-- menu key / palette
	if S.Hotkeys ~= false then
		local ui = tab:CreateSection({ Icon = ico("UISection", "lucide:keyboard"), Name = tx(L, "UISection", "UI / Hotkeys"), Column = 1 })
		local flag = P .. "menu_key"
		parts.MenuKey = ui:CreateKeybind({ Name = tx(L, "MenuKey", "Menu toggle key"), Default = win.Cfg.ToggleKey or Enum.KeyCode.RightShift, Flag = flag,
			Changed = function(k) if k then win.Cfg.ToggleKey = k end end })
		-- also follow config loads / undo (those set the flag silently)
		Library:Watch(flag, function(k) if typeof(k) == "EnumItem" then win.Cfg.ToggleKey = k end end)
		ui:CreateButton({ Icon = ico("Palette", "lucide:search"), Name = tx(L, "Palette", "Search / commands (Ctrl+K)"), Gradient = { win.Theme.Accent, win.Theme.Accent2 },
			Callback = function() win:OpenPalette() end })
		ui:CreateParagraph({ Title = tx(L, "HowTitle", "How to use"),
			Content = tx(L, "HowText", "Click a Keybind and press a key (Esc = cancel, Backspace = clear). Right-click or long-press any control for reset / copy / lock.") })
		parts.UISection = ui
	end

	-- save / load / delete configs
	if S.Config ~= false then
		local cs = tab:CreateSection({ Icon = ico("ConfigSection", "lucide:save"), Name = CFG_T, Column = 2 })
		local name = cs:CreateTextbox({ Name = tx(L, "ConfigName", "Config name"), Default = cfg.DefaultConfig or "default", EnterOnly = false })
		local list = cs:CreateDropdown({ Name = tx(L, "ConfigList", "Saved configs"), Options = Library:ListConfigs() })
		local function refresh(keep) list:Refresh(Library:ListConfigs(), keep) end
		local function pick() return list:Get() or name:Get() end
		cs:CreateButton({ Icon = ico("Save", "lucide:save"), Name = tx(L, "Save", "Save"), Gradient = { win.Theme.Accent, win.Theme.Accent2 }, Bold = true, Callback = function()
			local ok, res = Library:SaveConfig(name:Get())
			if ok then win:Success(CFG_T, tx(L, "Saved", "Saved") .. " " .. tostring(res), 3) else win:Error(CFG_T, tostring(res), 3) end
			refresh(true)
		end })
		cs:CreateButton({ Icon = ico("Load", "lucide:folder-open"), Name = tx(L, "Load", "Load"), Callback = function()
			local ok, res = Library:LoadConfig(pick())
			if ok then win:Success(CFG_T, tx(L, "Loaded", "Loaded"), 3) else win:Error(CFG_T, tostring(res), 3) end
		end })
		cs:CreateButton({ Icon = ico("Delete", "lucide:trash-2"), Name = tx(L, "Delete", "Delete"), Color = Color3.fromRGB(248, 113, 113), Callback = function()
			local n = list:Get()
			if not n then return win:Warning(CFG_T, tx(L, "PickFirst", "Pick a config from the list first"), 3) end
			win:Confirm({ Title = tx(L, "DeleteTitle", "Delete config"), Content = "\"" .. n .. "\" - " .. tx(L, "CannotUndo", "this cannot be undone"),
				Yes = tx(L, "Delete", "Delete"), No = tx(L, "Cancel", "Cancel"), Danger = true,
				OnYes = function()
					local ok, res = Library:DeleteConfig(n)
					if ok then win:Success(CFG_T, tx(L, "Deleted", "Deleted"), 3) else win:Error(CFG_T, tostring(res), 3) end
					refresh()
				end })
		end })
		cs:CreateButton({ Icon = ico("SaveAuto", "lucide:zap"), Name = tx(L, "SaveAuto", "Save as \"auto\" (autoload)"), Callback = function()
			local ok, res = Library:SaveAuto(cfg.AutoName or "auto")
			if ok then win:Success(CFG_T, tx(L, "SavedAuto", "Saved as auto"), 3) else win:Error(CFG_T, tostring(res), 3) end
			refresh(true)
		end })
		cs:CreateButton({ Icon = ico("Copy", "lucide:copy"), Name = tx(L, "Copy", "Copy config (clipboard)"), Callback = function()
			if type(setclipboard) ~= "function" then return win:Warning(CFG_T, tx(L, "NoClipboard", "Clipboard not supported"), 3) end
			pcall(setclipboard, Library:ExportConfig())
			win:Success(CFG_T, tx(L, "Copied", "Copied"), 2)
		end })
		cs:CreateButton({ Icon = ico("Import", "lucide:clipboard-paste"), Name = tx(L, "Import", "Paste config (import)"), Callback = function()
			win:Prompt({ Title = tx(L, "ImportTitle", "Import config"), Placeholder = "{ ... }",
				OnSubmit = function(text)
					local ok, res = Library:ImportConfig(text)
					if ok then win:Success(CFG_T, tx(L, "Applied", "Applied") .. " " .. tostring(res), 3) else win:Error(CFG_T, tostring(res), 3) end
				end })
		end })
		parts.ConfigName, parts.ConfigList, parts.ConfigSection = name, list, cs
	end

	-- window helpers
	if S.Window ~= false then
		local ws = tab:CreateSection({ Icon = ico("WindowSection", "lucide:app-window"), Name = tx(L, "WindowSection", "Window"), Column = 1 })
		ws:CreateButton({ Icon = ico("Center", "lucide:locate-fixed"), Name = tx(L, "Center", "Center window"), Callback = function() win:Center() win:Flash() end })
		ws:CreateButton({ Icon = ico("Unload", "lucide:power"), Name = tx(L, "Unload", "Close UI completely (Unload)"), Color = Color3.fromRGB(248, 113, 113), Callback = function()
			win:Confirm({ Title = tx(L, "UnloadTitle", "Unload UI"), Content = tx(L, "UnloadText", "Close and remove the whole UI?"),
				Yes = tx(L, "Yes", "Unload"), No = tx(L, "Cancel", "Cancel"), Danger = true, OnYes = function() Library:Unload() end })
		end })
		parts.WindowSection = ws
	end

	-- undo / redo / snapshot / reset
	if S.History ~= false then
		local hs = tab:CreateSection({ Icon = ico("HistorySection", "lucide:history"), Name = tx(L, "HistorySection", "Undo / Snapshot"), Column = 2 })
		hs:CreateButton({ Icon = ico("Undo", "lucide:undo-2"), Name = tx(L, "Undo", "Undo (Ctrl+Z)"), Callback = function()
			if not Library:Undo() then win:Warning("Undo", tx(L, "NothingUndo", "Nothing to undo"), 2) end
		end })
		hs:CreateButton({ Icon = ico("Redo", "lucide:redo-2"), Name = tx(L, "Redo", "Redo (Ctrl+Y)"), Callback = function()
			if not Library:Redo() then win:Warning("Redo", tx(L, "NothingRedo", "Nothing to redo"), 2) end
		end })
		hs:CreateButton({ Icon = ico("Modified", "lucide:list-checks"), Name = tx(L, "Modified", "Show changed values"), Callback = function()
			local l = Library:GetModified()
			win:Info(tx(L, "ChangedCount", "Changed") .. " " .. #l, #l > 0 and table.concat(l, ", ") or tx(L, "AllDefault", "Everything is default"), 4)
		end })
		hs:CreateButton({ Icon = ico("Snapshot", "lucide:camera"), Name = tx(L, "Snapshot", "Snapshot now (A)"), Callback = function()
			Library:Snapshot("A")
			win:Success("Snapshot", tx(L, "SnapSaved", "Stored as A"), 2)
		end })
		hs:CreateButton({ Icon = ico("Restore", "lucide:rotate-ccw"), Name = tx(L, "Restore", "Restore snapshot A"), Callback = function()
			local ok, n = Library:Restore("A")
			if ok then win:Success("Restore", tx(L, "Restored", "Restored") .. " " .. n, 3) else win:Error("Restore", tostring(n), 3) end
		end })
		hs:CreateHoldButton({ Name = tx(L, "ResetAll", "Hold to reset everything"), Duration = 1.2, DoneText = tx(L, "ResetDone", "Reset"),
			Callback = function() Library:ResetAll() end })
		parts.HistorySection = hs
	end
	return tab, parts
end

-- Window:CreateDefaultTabs({ Theme = {...}, Settings = {...} })  -> themeTab, settingsTab
-- (put it after your own tabs so THEME / SETTINGS sit at the bottom of the sidebar)
function Window:CreateDefaultTabs(cfg)
	cfg = cfg or {}
	local t, s
	if cfg.Theme ~= false then t = self:CreateThemeTab(type(cfg.Theme) == "table" and cfg.Theme or nil) end
	if cfg.Settings ~= false then s = self:CreateSettingsTab(type(cfg.Settings) == "table" and cfg.Settings or nil) end
	return t, s
end

------------------------------------------------------------ hook window creation
local prevCreate = Library.CreateWindow
function Library:CreateWindow(cfg)
	cfg = cfg or {}
	if not self._themesLoaded then pcall(self.LoadThemes, self, true) end
	local win = prevCreate(self, cfg)
	local t = cfg.Theme
	win.ThemeName = type(t) == "string" and t or (type(t) == "table" and "Custom") or self.ThemeName
	return win
end

Library.Version = "3.8"
end


return Library
