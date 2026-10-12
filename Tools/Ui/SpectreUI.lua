--[[
    SpectreUI - dark/violet Roblox UI library  (beautified build)
    Window / Sidebar tabs / Search / Sections / Toggle / Dropdown (+Multi) / Slider / Button / Label / Divider / Textbox / Keybind / ColorPicker / Paragraph / Notify / Toast / Dialog / Loading / Config

    local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/SpectreWareZ/SpectreWare/refs/heads/main/Tools/Ui/SpectreUI.lua"))()   -- or require(module)
    local Window  = Library:CreateWindow({ Title = "SpectreWare | Anime Astral" })
    local Tab     = Window:CreateTab({ Name = "Main", Icon = "M" })
    local Section = Tab:CreateSection({ Name = "Settings" })
    Section:CreateToggle({ Name = "Example", Default = false, Flag = "ex", Callback = function(v) end })

    Window options : Title, Transparency (0..1, background see-through), Logo (asset id / "rbxassetid://.."), LogoSize (26 or {w,h}), LogoColor (Color3), LogoCorner (px), OpenLogoScale (0.58, floating button), Width, Height, ToggleKey (Enum.KeyCode), Theme (table), OnClose
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

    New API (v3.5)
    - Tab lock   : Window:CreateTab({ Name = "VIP", Locked = true, LockReason = "Premium only", OnLockedClick = fn(tab) })
                   Tab:Lock(reason) / Tab:Unlock() / Tab:SetLocked(bool, reason) / Tab:IsLocked() / Tab:SetLockReason(text)
                   Window:LockTab(nameOrTab, reason) / UnlockTab(nameOrTab) / IsTabLocked(nameOrTab)
                   A locked tab shows a padlock, is dimmed and cannot be opened (click, SetTab, palette).
                   If it was the open tab the window jumps to the first unlocked tab.  LockedNotify = false  -> no toast.
    - Dropdown images : options can carry a picture, in every Dropdown (single + Multi)
                   Options = { { Name = "Sword", Image = 123456 }, { Name = "Bow", Image = "rbxassetid://789" }, "Plain text" }
                   or  Images = { Sword = 123456, Bow = "lucide:target", Red = Color3.fromRGB(255,0,0) }
                   Image = asset id | "rbxassetid://.." | https url | "lucide:name" icon | Color3 swatch.   ImageSize = 40 (optional)
                   The selected option's picture is shown on the closed dropdown too.  Callback / Get() still return the Name.
                   dd:Refresh(options, keep, imagesTable)   dd:SetImage(optionName, image)

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

    Fonts
    - Library:CreateWindow({ Font = "Nunito" })     font chosen when the window is created (name | Enum.Font | { Font, Bold })
    - Window:SetFont("Ubuntu" | Enum.Font.Code | { Font = Enum.Font.X, Bold = Enum.Font.Y }, remember)
                  changes the font of the WHOLE window live, like Window:SetTheme  -> ok, name | err
    - Window:GetFontName() / Window:CycleFont(dir, remember) / Library:SetFont(font)   (Library:SetFont = default for windows created later)
    - Library:RegisterFont("Mine", Enum.Font.Ubuntu, Enum.Font.Ubuntu)   Library:ListFonts()   Library.Fonts = the presets
    - Section:CreateFontPicker({ Name, Flag, Remember = true })   ready dropdown (the Theme tab already contains it: CreateThemeTab({ Fonts = false }) hides it)
    - The chosen font is saved next to the theme in themes.json and restored next launch
    - Note: Roblox fonts only cover Latin text; Thai (and other scripts) always fall back to the default font
    - Tab buttons are smaller on phones (38 px).  Window option TabHeight = <px> overrides the height.
    - New presets: Aurora, Dracula, Nord, TokyoNight, Mocha, Synthwave, Jade, Gold, Lavender, Candy, Peach
      (plus Midnight, Ocean, Sunset, Mono from before)

    Ready-made tabs (v3.7)
    - Window:CreateThemeTab({ Name, Icon, Text = {..}, Manager = {..}, Maker = false, Effects = false, Fonts = false, Keys = false })      -> tab, parts
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
        theme tab keys: ThemeSection FontSection MakerSection FxSection CreateButton
    - Built-in glyphs still work: "check" "cross" "spinner" "!" "i" "M" ...

    Load API (v3.9)
    - Library:Load(source, opts) / Window:Load(source, opts) -> ok, result      source = url | file | raw Lua | function
    - Library:LoadMany({ src, { Source = src, Name = "x" }, ... }, opts) -> ok, results
    - opts: Name, Args, Retries, RetryDelay, Silent, Async, OnDone(ok, result), OnProgress(p, text), Cache, Title, SuccessText, FailText
    - Shows a Loading card with progress (download -> compile -> run) and Complete / Fail at the end.

    Auto UI check (v3.10)
    - Runs by itself after the window is built / a tab switch / a resize. Reports only NEW problems (console + one card), silent when clean.
    - Window:Audit({ Print, Notify, Visual, Fix, Skip }) -> issues     Library:Audit(opts)     Palette command: "Run UI check"
    - Library.AutoCheck = { Enabled, Delay, Notify, Print, Visual, Fix, Skip }     CreateWindow({ AutoCheck = false | { ... } })
    - Rules: Library.AuditCodes (DupFlag, DefaultName, BadCallback, BadDefault, BadRange, EmptyTab, EmptySection, LowContrast, Overflow, TextClip, Offscreen ...)

    HUD + Tour (v3.11)
    - Window:Watermark({ Text, Fields = { "FPS", "Ping", "Time", "Date", "Players", fn, { Name, Get } }, Position, Interval, Draggable }) -> handle
        live FPS / ping pill, draggable, follows the theme.   :SetText :SetFields :AddField :SetVisible :Toggle :SetPosition :Destroy
    - Window:KeybindList({ Title, Position, OnlyActive, HideWhenEmpty, IncludeUI, Draggable }) -> handle
        lists every Keybind / KeybindToggle, active ones highlighted.   :Add(name, key, stateFn, mode) :Remove(id) :SetVisible :Toggle :Destroy
    - Window:Tour({ { Target = "flag", Tab = "Main", Title, Content }, ... }, { Position, Keys, OnDone }) -> handle
        guided tour: jumps to + highlights each control, step card with progress.   :Next :Prev :Goto(i) :Stop :Finish :IsRunning
    - Library:Watermark / KeybindList / Tour(...) = same on the newest window.  Palette: "Toggle watermark", "Toggle keybind list".

    Stepper + Stat (v3.12)
    - Section:CreateStepper({ Name, Min, Max, Step, Default, Suffix, Wrap, Flag, Callback }) -> [ - ] value [ + ], hold to repeat.  :Set :Get :Increment(n) :SetRange(min, max)
    - Section:CreateStat({ Name, Get = fn, Interval, Format, Prefix, Suffix, Color, Delta }) -> live read-out row.  :Refresh :SetGet(fn) :Get
    - Both get the usual extras (ShowIf / OnChange / Reset / Tooltip / Destroy / right-click menu); Stepper is saved in configs, Stat is not.

    Flags, hotkeys, theme sharing, text size (v3.13)
    - Library:GetControl(flag) / SetFlag(flag, value, silent) / ToggleFlag(flag) / SetFlags({ flag = value, ... }, silent) / GetFlags()
        SetFlags is ONE undo step.  GetFlags returns a copy of every flag (same as Snapshot()).
    - Library:Hotkey(Enum.KeyCode.X, fn, { Ctrl, Shift, Alt, Desc, AllowTyping }) -> { Disconnect, SetKey, SetEnabled }   global hotkey, not tied to a control
      Library:ListHotkeys() -> { { Key = "Ctrl+X", Desc = "..." } }
    - Library:ExportTheme(nameOrTheme?) -> "SPT1:{...}" string   Library:ImportTheme(str, name?) -> ok, name | err   (registers + saves the theme)
      Window:ExportTheme() / Window:ImportTheme(str, name, apply = true)
    - Window:SetTextScale(0.7 .. 1.4, remember) / Window:GetTextScale()   scale every text in the window (call after the UI is built; the THEME tab has a "Text size" switch)

    More controls + helpers (v3.14)
    - Section:CreateButtonRow({ Buttons = { { Name, Callback, Color, TextColor, Bold }, ... } })     several buttons in one row   :SetText(i, text)
    - Section:CreateInputButton({ Name, Placeholder, Button, ButtonWidth, Default, MaxLength, ClearOnSubmit, Trim, Flag, Callback(text) })
        text box + submit button (Enter also submits)   :Get() last submitted  :GetText() typed now  :Set(text, silent)  :Clear()  :Focus()  :SetButtonText(t)
    - Section:CreateKeyValue({ Name, Value, Color, Copyable = true })     "name ... value" row, tap to copy   :Set(v) :Get() :SetColor(c)
    - Section:CreateCodeBlock({ Name, Text, Height, Copy = true, MaxChars, AutoScroll })     monospace box + Copy button   :Set :Get :Append(line) :Clear :Copy
    - Section:CreateCountdown({ Name, Target = os.time() + n | Seconds = n, Format = fn(sec), ExpiredText, WarnAt, Color, OnDone(obj) })
        live time-left row (key expiry ...)   :SetTarget(epoch) :SetSeconds(n) :Add(n) :Get() :IsExpired()
    - Section:CreateListBox({ Name, Items, Height, Multi, Search, AllowDeselect, Default, Empty, Flag, Callback(value) })
        scrolling pick list (saved in configs when it has a Flag)   :Get :Set(value, silent) :Clear :Refresh(items, keep) :Add :Remove :GetItems :Count
    - Section:CreateTable({ Name, Columns = { "A", { Name = "B", Width = 0.3 } }, Rows, Height, RowHeight, Zebra, OnRowClick(row, i) })
        :SetRows :AddRow :RemoveRow(i) :SetCell(i, col, v) :Clear :Count :GetRows
    - Section:CreateImage({ Image = id | "rbxassetid://.." | "lucide:name", Name, Height, Fit = "Fit"|"Crop"|"Stretch", Corner, Color })     :Set(image) :Get()
    - Window:RemoveTab(nameOrTab) / RenameTab(nameOrTab, newName) / ListTabs()      Tab:Remove() / Tab:Rename(name)
    - Window:SetToggleKey(Enum.KeyCode | "F4") / GetToggleKey()      Window:Open() / Close() / IsOpen()
    - Library:Copy(text, title)   clipboard + "Copied" card
    - The new controls get the usual extras too (ShowIf / SetVisible / Lock / Tooltip / Destroy / right-click menu).

    v2 notes
    - Window is draggable by its header (mouse + touch), clamped to the screen, position kept on resize / rotation.
    - The floating "open" button (shown while the window is closed) is draggable too; a tap still opens the window.
      It stays where you drop it (no jump / snap). CreateWindow({ OpenSnap = true }) brings back the glide to the nearest screen edge.
    - Everything is event-driven: only TweenService + input events (the only per-frame work is the tiny
      frame-rate governor below, and the drag-follow loop while a drag is in progress).
    - Smooth-motion engine (v3.5): while the window opens / closes / maximizes / switches tab, the looping
      backdrop and the halo rings are paused for the length of that motion, so the transition owns the frame
      budget; they fade back in right after.  Open = slide + fade (the scale "pop" is opt-in:
      Library.Anim.Pop = true, it re-rasterizes every stroke each frame and is the usual cause of stutter).
    - Frame-rate governor: if the window itself runs choppy (many slow frames over 2 s) it steps down by itself:
      lite backdrop -> no backdrop -> no halo.  Library.Perf.Adaptive = false turns it off;
      Library.Perf.SlowFrame (default 1/18 s) / Library.Perf.SlowShare (default 0.25) tune the trigger;
      Library.Perf.Warmup (default 3 s) = grace period after the window is created / shown.
      CreateWindow({ OnDegrade = function(level) end }) tells you when it steps down.
]]

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Library = { Flags = {}, Objects = {}, Windows = {}, ConfigFolder = "SpectreUI/configs", Version = "3.15", _flagCbs = {} }
Library.__index = Library

-- Stability: parent a ScreenGui safely. gethui -> CoreGui -> PlayerGui, and never wait forever for PlayerGui.
function Library._mount(gui)
	local ok = pcall(function() gui.Parent = (gethui and gethui()) or CoreGui end)
	if ok and gui.Parent then return true end
	local lp = Players.LocalPlayer
	local pg = lp and (lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui", 10))
	ok = pcall(function() gui.Parent = pg or CoreGui end)
	return ok and gui.Parent ~= nil
end

-- Stability: running the script twice must not stack two UIs. Unload the previous copy and sweep leftovers.
do
	local genv = (getgenv and getgenv()) or _G
	local old = genv.__SpectreUI_Lib
	if old and old ~= Library and type(old.Unload) == "function" then pcall(old.Unload, old) end
	local roots = { CoreGui }
	if gethui then
		local okh, h = pcall(gethui)
		if okh and h then table.insert(roots, h) end
	end
	local lp0 = Players.LocalPlayer
	local pg0 = lp0 and lp0:FindFirstChildOfClass("PlayerGui")
	if pg0 then table.insert(roots, pg0) end
	local stale = { SpectreUI = true, SpectreUI_Notify = true, SpectreUI_Host = true, SpectreUI_HUD = true, SpectreUI_Splash = true }
	for _, r in ipairs(roots) do
		pcall(function()
			for _, c in ipairs(r:GetChildren()) do
				if stale[c.Name] and c:IsA("ScreenGui") then c:Destroy() end
			end
		end)
	end
	genv.__SpectreUI_Lib = Library
end

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
	-- clarity boost: crisper borders, brighter secondary text, controls that stand out from cards
	local white = Color3.new(1, 1, 1)
	T.Text = T.Text:Lerp(white, 0.15)
	T.SubText = T.SubText:Lerp(T.Text, 0.35)
	T.Border = T.Border:Lerp(T.Accent, 0.22):Lerp(white, 0.06)
	T.Control = T.Control:Lerp(white, 0.035)
	T.Card = T.Card:Lerp(white, 0.012)
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

-- readable text colour (white or near-black) for text drawn on top of accent / gradient colours.
-- Library.OnAccent(Theme)  |  Library.OnAccent(colorA [, colorB])
function Library.OnAccent(a, b)
	if type(a) == "table" then a, b = a.Accent, a.Accent2 end
	a = a or Color3.new(1, 1, 1)
	b = b or a
	local function lum(c)
		local function f(v) return v <= 0.03928 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4 end
		return 0.2126 * f(c.R) + 0.7152 * f(c.G) + 0.0722 * f(c.B)
	end
	local function ratio(x, y) if x < y then x, y = y, x end return (x + 0.05) / (y + 0.05) end
	local la, lb, ld = lum(a), lum(b), lum(Color3.fromRGB(14, 14, 20))
	local white = math.min(ratio(1, la), ratio(1, lb))
	local dark = math.min(ratio(la, ld), ratio(lb, ld))
	if white >= 3 or white >= dark then return Color3.new(1, 1, 1) end
	return Color3.fromRGB(14, 14, 20)
end
-- marks a label / icon so Window:SetTheme re-picks its colour with OnAccent
function Library._oa(inst) inst:SetAttribute("OnAccent", true) return inst end

-- let a ScreenGui cover the WHOLE physical screen (notch / cut-out / rounded-corner strips included),
-- so draggable UI can reach the real screen edge.  Older clients without ScreenInsets just ignore it.
function Library._fullScreen(g)
	pcall(function() g.IgnoreGuiInset = true end)
	pcall(function() g.ScreenInsets = Enum.ScreenInsets.None end)
	return g
end

-- The part of the ScreenGui that is really on screen, in AbsolutePosition space (min corner, max corner).
-- With IgnoreGuiInset / ScreenInsets = None the gui can be larger than the visible screen (notch, bars), so popups that
-- sized themselves from Gui.AbsoluteSize ran off the bottom of the screen. Clamp to the camera viewport as well.
function Library._visibleRect(gui)
	local gp, gs = gui.AbsolutePosition, gui.AbsoluteSize
	local mn, mx = gp, gp + gs
	local cam = workspace.CurrentCamera
	if cam and cam.ViewportSize.X > 0 then
		local v = cam.ViewportSize
		local a = Vector2.new(math.max(mn.X, 0), math.max(mn.Y, 0))
		local b = Vector2.new(math.min(mx.X, v.X), math.min(mx.Y, v.Y))
		if b.X - a.X >= 100 and b.Y - a.Y >= 100 then return a, b end
	end
	return mn, mx
end

-- Popups (dropdown / colour picker) live in win.Gui but are placed from the AbsolutePosition of the control that opened
-- them. On some clients (GUI inset / safe area / scaled windows) those two coordinate spaces differ, so the popup used to
-- open away from its control. This re-reads where the popup's anchor point REALLY is and shifts Position by the difference,
-- so the popup always sits on the control, whatever side of the window it is on.
function Library._pinPopup(popup, wantX, wantY)
	if not popup or not popup.Parent then return end
	local ap, sz = popup.AnchorPoint, popup.AbsoluteSize
	local a = popup.AbsolutePosition + Vector2.new(ap.X * sz.X, ap.Y * sz.Y)
	local ex, ey = a.X - wantX, a.Y - wantY
	if math.abs(ex) < 0.5 and math.abs(ey) < 0.5 then return end
	local pp = popup.Position
	popup.Position = UDim2.new(pp.X.Scale, pp.X.Offset - ex, pp.Y.Scale, pp.Y.Offset - ey)
end

-- one drag at a time: follows input `i` (finger / mouse button) and ALWAYS lets go when it ends,
-- so a slider can never keep following later touches (that made two sliders move together).
-- onMove(inputObject)  onStop()   -> returns stop()
function Library._drag(i, onMove, onStop)
	if Library._dragStop then Library._dragStop() end
	local isTouch = i.UserInputType == Enum.UserInputType.Touch
	local conns, done = {}, false
	local function stop()
		if done then return end
		done = true
		for _, c in ipairs(conns) do c:Disconnect() end
		if Library._dragStop == stop then Library._dragStop = nil end
		onStop()
	end
	Library._dragStop = stop
	local function ended()
		local st = i.UserInputState
		return st == Enum.UserInputState.End or st == Enum.UserInputState.Cancel
	end
	table.insert(conns, UserInputService.InputChanged:Connect(function(m)
		if done then return end
		if isTouch then
			if m ~= i or m.UserInputType ~= Enum.UserInputType.Touch then return end
		elseif m.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end
		if ended() then stop() return end
		onMove(m)
	end))
	table.insert(conns, UserInputService.InputEnded:Connect(function(e)
		if e == i or (not isTouch and e.UserInputType == Enum.UserInputType.MouseButton1) then stop() end
	end))
	table.insert(conns, i.Changed:Connect(function() if ended() then stop() end end))
	return stop
end

------------------------------------------------------------------ fonts
-- Library.Fonts = named presets { Font = regular, Bold = bold }.  Used like themes:
--   Library:CreateWindow({ Font = "Nunito" })    Window:SetFont("Ubuntu", true)    Library:SetFont("Roboto")
Library.Fonts, Library._fontOrder, Library.FontName = {}, {}, "Gotham"
do
	local defs = {
		{ "Gotham", "GothamMedium", "GothamBold" },
		{ "Gotham Light", "Gotham", "GothamBold" },
		{ "Gotham Bold", "GothamBold", "GothamBlack" },
		{ "Source Sans", "SourceSans", "SourceSansBold" },
		{ "Arial", "Arial", "ArialBold" },
		{ "Nunito", "Nunito", "Nunito" },
		{ "Ubuntu", "Ubuntu", "Ubuntu" },
		{ "Roboto", "Roboto", "Roboto" },
		{ "Roboto Condensed", "RobotoCondensed", "RobotoCondensed" },
		{ "Roboto Mono", "RobotoMono", "RobotoMono" },
		{ "Code", "Code", "Code" },
		{ "Titillium Web", "TitilliumWeb", "TitilliumWeb" },
		{ "Jura", "Jura", "Jura" },
		{ "Oswald", "Oswald", "Oswald" },
		{ "Josefin Sans", "JosefinSans", "JosefinSans" },
		{ "Merriweather", "Merriweather", "Merriweather" },
		{ "Highway", "Highway", "Highway" },
		{ "Sci-Fi", "SciFi", "SciFi" },
		{ "Fredoka", "FredokaOne", "FredokaOne" },
		{ "Kalam", "Kalam", "Kalam" },
		{ "Patrick Hand", "PatrickHand", "PatrickHand" },
	}
	for _, d in ipairs(defs) do
		local ok1, r = pcall(function() return Enum.Font[d[2]] end)
		local ok2, b = pcall(function() return Enum.Font[d[3]] end)
		if ok1 and ok2 and r and b then
			Library.Fonts[d[1]] = { Font = r, Bold = b }
			table.insert(Library._fontOrder, d[1])
		end
	end
end

-- accepts a preset name, an Enum.Font or { Font = , Bold = }  ->  regular, bold, name  (or nil, error)
function Library._fontPair(f)
	local function isFont(v) return typeof(v) == "EnumItem" and v.EnumType == Enum.Font end
	if type(f) == "string" then
		local p = Library.Fonts[f]
		if not p then return nil, "unknown font" end
		return p.Font, p.Bold, f
	elseif isFont(f) then
		for name, p in pairs(Library.Fonts) do
			if p.Font == f then return p.Font, p.Bold, name end
		end
		return f, f, "Custom"
	elseif type(f) == "table" then
		local r = f.Font or f.Regular or f[1]
		local b = f.Bold or f.FontBold or f[2] or r
		if isFont(r) and isFont(b) then return r, b, "Custom" end
		return nil, "Font and Bold must be Enum.Font values"
	end
	return nil, "usage: SetFont(name | Enum.Font | { Font, Bold })"
end

-- swaps the fonts of every text object below `root` (regular -> regular, bold -> bold).
-- Single-weight fonts have regular == bold, so the weight is remembered in an attribute
-- and switching away from them restores the headings correctly.
function Library._remapFonts(root, oldR, oldB, newR, newB)
	if not root or (oldR == newR and oldB == newB) then return end
	local ambiguous = oldR == oldB
	local tagNew = newR == newB
	for _, o in ipairs(root:GetDescendants()) do
		if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
			local f = o.Font
			if f == oldR or f == oldB then
				local bold = o:GetAttribute("SpBold")
				if bold == nil then bold = (f == oldB) and not ambiguous end
				o.Font = bold and newB or newR
				if tagNew or ambiguous then o:SetAttribute("SpBold", bold) end
			end
		end
	end
end

-- Library:RegisterFont("Mine", Enum.Font.Ubuntu, Enum.Font.Ubuntu) -> ok, err
function Library:RegisterFont(name, regular, bold)
	if type(name) ~= "string" or name == "" then return false, "usage: RegisterFont(name, Enum.Font, Enum.Font?)" end
	local r, b = Library._fontPair({ Font = regular, Bold = bold })
	if not r then return false, b end
	if not self.Fonts[name] then table.insert(self._fontOrder, name) end
	self.Fonts[name] = { Font = r, Bold = b }
	if self._fire then self._fire("fonts") end
	return true
end

function Library:ListFonts()
	local out = {}
	for i, n in ipairs(self._fontOrder) do out[i] = n end
	return out
end

-- Library:SetFont("Nunito" | Enum.Font.X | { Font, Bold })  -> default for windows created afterwards
function Library:SetFont(f, silent)
	local r, b, name = Library._fontPair(f)
	if not r then return false, b end
	THEME_COMMON.Font, THEME_COMMON.FontBold = r, b
	self.Theme.Font, self.Theme.FontBold = r, b
	self.FontName = name or "Custom"
	if not silent then self._userSetFont = true end
	return true, self.FontName
end

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
local HEADER_H, SEARCH_H, FOOT_H = 64, 44, 54

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
-- Library.Anim.Intro = false (or CreateWindow({ Intro = false })) skips the launch animation
Library.Anim = { Speed = 1, Intro = true }

Library.Perf = {
	-- nil = auto (mobile -> low power), true/false = force. Change at runtime:
	--   Library.Perf.LowPower = false   -- force the pretty path anywhere
	LowPower = nil,
	-- frame-rate governor (see Window:_StartGovernor): steps the visuals down when the window stutters
	Adaptive = true, SlowFrame = 1 / 18, SlowShare = 0.25, Warmup = 3,
}

local function lowPower()
	local p = Library.Perf.LowPower
	if p ~= nil then return p end
	return IS_MOBILE
end

------------------------------------------------------------------ sounds
-- Library.Sound.Enabled = false            -- mute everything
-- Library.Sound.Volume  = 0.6              -- 0..1
-- Library.Sound.Toggle / .Notify = "rbxassetid://..."   -- swap in your own ids (nil = silent)
-- Per notification: Library:Notify({ ..., Sound = false })  or  Sound = "rbxassetid://..."
Library.Sound = {
	Enabled = true, Volume = 0.5,
	Toggle = "rbxassetid://6895079853", -- switch click
	Click = "rbxassetid://6895079853",  -- button press confirmation (Library.Sound.Click = nil -> silent)
	Notify = "rbxassetid://4590662766", -- notification ping
}
local lastPlayed = {}
local function playSound(kind, override)
	local S = Library.Sound
	if not S or not S.Enabled or override == false then return end
	local id = type(override) == "string" and override or (type(override) == "number" and ("rbxassetid://" .. override)) or S[kind]
	if not id then return end
	-- never stack the same sound within 60 ms (batch updates / identical notifications)
	local now = os.clock()
	if lastPlayed[kind] and now - lastPlayed[kind] < 0.06 then return end
	lastPlayed[kind] = now
	pcall(function()
		local snd = Instance.new("Sound")
		snd.Name = "SpectreUI_" .. kind
		snd.SoundId = id
		snd.Volume = math.clamp(S.Volume or 0.5, 0, 1)
		snd.RollOffMaxDistance = 0
		snd.Parent = SoundService
		snd.Ended:Once(function() snd:Destroy() end)
		snd:Play()
		task.delay(6, function() if snd.Parent then snd:Destroy() end end) -- safety net if it never ends / fails to load
	end)
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
-- TweenInfo objects are immutable, and hover / press feedback asks for the same few (time, style, direction)
-- combinations thousands of times: reuse them instead of allocating a new one per tween (less GC churn).
local infoCache, infoCount = {}, 0
local function tinfo(t, style, dir)
	local a = infoCache[style]
	if not a then a = {} infoCache[style] = a end
	local b = a[dir]
	if not b then b = {} a[dir] = b end
	local info = b[t]
	if not info then
		if infoCount > 300 then infoCache, infoCount = {}, 0 a, b = {}, {} infoCache[style] = a a[dir] = b end
		info = TweenInfo.new(t, style, dir)
		b[t] = info
		infoCount += 1
	end
	return info
end

local function tween(o, t, props, style, dir)
	if not style then
		style = SINE
		for k in pairs(props) do
			if GEOM[k] then style = QUINT break end
		end
	end
	t = math.max(t * (Library.Anim.Speed or 1), 0.08)
	local tw = TweenService:Create(o, tinfo(t, style, dir or OUT), props)
	tw:Play()
	return tw
end

-- Run fn once, one rendered frame from now. The frame in which a window / page / section first becomes
-- visible is the heavy one (text layout, strokes, gradients). A tween started in that same frame inherits
-- its huge dt and skips its opening frames, which is the "stutter at the start of an animation". Starting
-- the tween one frame later lets the heavy frame pass first.
local function nextFrame(fn)
	task.spawn(function()
		RunService.RenderStepped:Wait()
		fn()
	end)
end

local function corner(r) return new("UICorner", { CornerRadius = UDim.new(0, r) }) end

------------------------------------------------------------------ icon packs (Footagesus/Icons Main-v2)
-- Lazy: the pack module (lucide / solar / craft / geist / sfsymbols / gravity) is only downloaded the
-- first time a named icon is used. If the download fails everything falls back to the old text glyphs.
Library.IconLib = { Url = "https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua", Default = "lucide", Timeout = 8 }

local function iconModule()
	if Library._iconMod ~= nil then return Library._iconMod or nil end
	Library._iconMod = false
	-- the download runs in its own thread and is given a few seconds; a hung request must never freeze the UI build
	local done, ok, mod = false, false, nil
	task.spawn(function()
		ok, mod = pcall(function()
			return loadstring(game:HttpGet(Library.IconLib.Url))()
		end)
		done = true
	end)
	local t0 = os.clock()
	while not done and os.clock() - t0 < (Library.IconLib.Timeout or 8) do task.wait() end
	if not done then
		warn("[SpectreUI] icon library timed out, using text glyphs")
	elseif ok and type(mod) == "table" and mod.Icon then
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
		Color = color, Thickness = thickness or 1, Transparency = math.max(0, (transparency or 0) - 0.15),
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
	local sc = (noScale == false) and new("UIScale", { Parent = btn }) or nil -- press squish moves/blurs the text, so it is opt-in only
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

	-- viewport size in the SAME space `target.Position` is resolved against (never 0, so a clamp can't throw the element to a corner)
	local function viewport()
		local vp = gui.AbsoluteSize
		if vp.X <= 0 or vp.Y <= 0 then
			local cam = workspace.CurrentCamera
			if cam then vp = cam.ViewportSize end
		end
		return vp
	end
	-- current center of `target` in gui space, read from Position (the same property we write while dragging).
	-- AbsolutePosition can live in a different space (GUI inset / safe-area differs per client / executor),
	-- which made the open button jump up on the first move and then not follow the finger.
	local function centerOf()
		local vp, p = viewport(), target.Position
		return Vector2.new(p.X.Scale * vp.X + p.X.Offset, p.Y.Scale * vp.Y + p.Y.Offset)
	end

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
			shown = centerOf()
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
		local startC = centerOf()
		local vpSize, halfSize = viewport(), target.AbsoluteSize / 2 -- cached for the whole drag
		if state.Half then halfSize = Vector2.new(state.Half, state.Half) end -- real size, ignores UIScale squish / pop tween
		local thr = state.Threshold or 0
		stopFollow()
		shown, lastPos = startC, nil
		state.Center = startC -- never keep a stale center from the previous drag / an old viewport size

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
				-- start counting from the moment the drag really begins, so the element does not
				-- jump by `thr` pixels on the first move
				startPt = v2(m.Position)
				d = Vector2.zero
			end
			local c = clampCenter(vpSize, halfSize, startC + d)
			if state.Clamp then c = state.Clamp(c, vpSize) end -- extra live limits (e.g. keep clear of the Roblox menu)
			if c ~= state.Center then
				state.Center = c
				if state.Direct then
					-- stuck 1:1 to the finger / cursor (this is what feels smooth for a small button)
					target.Position = UDim2.fromOffset(math.round(c.X), math.round(c.Y))
				elseif (touch or lowPower()) and not state.Smooth then
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
		-- read size / position from Size + Position (what _Fit writes), NOT AbsoluteSize / AbsolutePosition:
		-- the window has a UIScale (open animation) and the absolute values can sit in a different
		-- coordinate space, which made the window jump / grow wrong while resizing
		local vp0 = win.Gui.AbsoluteSize
		local ms, mp = win.Main.Size, win.Main.Position
		local startSz = Vector2.new(ms.X.Scale * vp0.X + ms.X.Offset, ms.Y.Scale * vp0.Y + ms.Y.Offset)
		local startC = Vector2.new(mp.X.Scale * vp0.X + mp.X.Offset, mp.Y.Scale * vp0.Y + mp.Y.Offset)
		local tl = startC - startSz / 2
		tl = Vector2.new(math.max(tl.X, 6), math.max(tl.Y, 6)) -- same margin clampCenter keeps
		if win.Maximized then win:_SetMaxFlag(false) end
		win.Cfg.Width, win.Cfg.Height = math.floor(startSz.X + 0.5), math.floor(startSz.Y + 0.5)

		moveC = UserInputService.InputChanged:Connect(function(m)
			if touch then
				if m ~= i then return end
			elseif m.UserInputType ~= Enum.UserInputType.MouseMovement then
				return
			end
			local vp = win.Gui.AbsoluteSize
			if vp.X <= 0 or vp.Y <= 0 then return end
			local d = v2(m.Position) - startPt
			local minW = math.min(win.Cfg.MinWidth or 700, vp.X - 16)
			local minH = math.min(win.Cfg.MinHeight or 280, vp.Y - 16)
			-- max = what _Fit allows (screen - 16) AND what fits right of / below the top-left corner,
			-- so _Fit never has to shrink / shift the window behind the finger
			local maxW = math.max(minW, math.min(vp.X - 16, vp.X - 8 - tl.X))
			local maxH = math.max(minH, math.min(vp.Y - 16, vp.Y - 8 - tl.Y))
			local w = math.clamp(startSz.X + d.X * mx, minW, maxW)
			local h = math.clamp(startSz.Y + d.Y * my, minH, maxH)
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
		local lt = loopTween(fx, o, dur, { Position = b })
		if fx.Paused then lt:Pause() end   -- started while the backdrop rests: stay frozen with the others
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
local function cnt(fx, n) return fx.Lite and 0 or math.max(3, n // 2) end

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

-- Static backdrop scene (zero per-frame cost: nothing here is animated).
-- Every layer is a full-size frame with its own UICorner, so it follows the window's rounded shape.
--   1. base   diagonal tinted gradient (accent -> background -> accent2)
--   2. glowA / glowB  two soft light bands crossing each other = a soft glow spot, no hard edges
--   3. vignette  darkens the bottom so cards / text stay readable
local function scene(layer, radius, T, minimal)
	local bg = T.Background
	local function full(color, grads)
		local kids = { new("UICorner", { CornerRadius = UDim.new(0, radius) }) }
		for _, g in ipairs(grads) do kids[#kids + 1] = g end
		return new("Frame", {
			Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, BorderSizePixel = 0,
			Active = false, Parent = layer,
		}, kids)
	end
	-- 1. base (opaque): gives the window depth instead of a flat fill
	full(Color3.new(1, 1, 1), { new("UIGradient", {
		Rotation = 135,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, bg:Lerp(T.Accent, 0.16)),
			ColorSequenceKeypoint.new(0.5, bg),
			ColorSequenceKeypoint.new(1, bg:Lerp(T.Accent2, 0.11)),
		}),
	}) })
	if minimal then return end
	-- 2. soft light: where the two bands cross the glow is strongest
	local function band(color, rot, at, peak)
		full(color, { new("UIGradient", {
			Rotation = rot,
			Transparency = NumberSequence.new({
				nsk(0, 1), nsk(math.max(at - 0.42, 0.01), 1), nsk(at, peak), nsk(math.min(at + 0.42, 0.99), 1), nsk(1, 1),
			}),
		}) })
	end
	band(T.Accent, 25, 0.22, 0.84)
	band(T.Accent2, 115, 0.82, 0.88)
	-- 3. vignette
	full(Color3.new(0, 0, 0), { new("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({ nsk(0, 1), nsk(0.55, 1), nsk(1, 0.5) }),
	}) })
end

-- Window:SetBackground("petals" | "orbs" | "embers" | "rain" | "grid" | false | nil)
-- nil -> theme default, false -> off. `quiet` is used internally at creation time.
function Window:SetBackground(kind, quiet)
	local fx = self.FX
	if not fx then return end
	if kind == nil then kind = self.Theme.FX end
	for _, tw in ipairs(fx.Tweens) do pcall(function() tw:Cancel() end) end
	table.clear(fx.Tweens)
	fx.Paused = false
	if fx.Layer then fx.Layer:Destroy() fx.Layer = nil end
	self.FXOn = false

	if not kind then return end
	-- Library.Perf.Backdrop = false turns the whole backdrop off on phones
	if lowPower() and Library.Perf.Backdrop == false then return end
	-- phones / a struggling frame rate: static scene only (no tweens, no particles)
	fx.Lite = lowPower() or (self._qual or 0) >= 1
	local T = self.Theme
	local layer = new("Frame", {
		Name = "FX", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
		ClipsDescendants = true, ZIndex = 0, Active = false, Parent = self.Main,
	})
	fx.Layer = layer
	self.FXOn = true

	local r = self.Radius or 12
	scene(layer, r, T, (self._qual or 0) >= 2)
	if fx.Lite then return end   -- static only: nothing animated, nothing to pause

	-- PC only: ONE slow aurora sweep + a few particles (half of the old amount)
	aurora(fx, layer, r, T.Accent, T.Accent2, 28, 0.9, rnd(18, 24), -0.55, 0.55)
	local build = FX_KINDS[kind] or FX_KINDS.orbs
	build(fx, layer, T)

	if not self.Visible or self._moving then self:_FXPause() end
end

-- pause / resume every looping tween (backdrop + header sheen) so a closed window costs nothing
function Window:_FXPause()
	if not self.FX then return end
	self.FX.Paused = true
	for _, tw in ipairs(self.FX.Tweens) do
		if tw.PlaybackState == Enum.PlaybackState.Playing then tw:Pause() end
	end
	local sh = self._sheen
	if sh and sh.PlaybackState == Enum.PlaybackState.Playing then sh:Pause() end
end

function Window:_FXResume()
	if not self.FX or self._blurred then return end   -- game window not focused: keep the backdrop asleep
	self.FX.Paused = false
	for _, tw in ipairs(self.FX.Tweens) do
		if tw.PlaybackState == Enum.PlaybackState.Paused then tw:Play() end
	end
	local sh = self._sheen
	if sh and sh.PlaybackState == Enum.PlaybackState.Paused then sh:Play() end
end

------------------------------------------------------------------ smooth-motion engine
-- show / hide the halo rings. They are hidden while the window moves or resizes (two big rounded
-- strokes re-rasterized every frame is what made drags / animations hitch) and fade back afterwards.
-- They also follow Main.Visible: the rings live in the ScreenGui, so they used to stay on screen
-- after the window was hidden.
function Window:_GlowVisible(v)
	local gl = self.Glow
	if not gl then return end
	v = v and self.Main.Visible and (self._qual or 0) < 3
	if v then
		if not self._glowHidden then return end
		self._glowHidden = false
		if self._glowSync then self._glowSync() end
		for _, g in ipairs(gl) do
			g.stroke.Transparency = 1
			g.frame.Visible = true
			tween(g.stroke, 0.35, { Transparency = g.base }, SINE, OUT)
		end
	else
		if self._glowHidden then return end
		self._glowHidden = true
		for _, g in ipairs(gl) do g.frame.Visible = false end
	end
end

-- Window:_MotionBegin(duration, keepGlow): the window is about to animate for ~duration seconds.
-- Pauses the looping backdrop (and hides the halo unless keepGlow) so the transition gets the whole
-- frame budget, then releases automatically. Token based, so overlapping motions can never leave
-- the backdrop frozen: only the latest Begin's timer is allowed to release.
function Window:_MotionBegin(dur, keepGlow)
	if self._destroyed then return end
	self._motionTok = (self._motionTok or 0) + 1
	local tok = self._motionTok
	self._moving = true
	self:_FXPause()
	if not keepGlow then self:_GlowVisible(false) end
	-- every tween of the motion is stretched by Library.Anim.Speed, so the release has to wait as long;
	-- otherwise the backdrop resumed in the middle of the transition
	local hold = (dur or 0.4) * math.max(Library.Anim.Speed or 1, 1) + 0.12
	task.delay(hold, function()
		if self._motionTok ~= tok or self._destroyed then return end
		self._moving = false
		if self.Visible and not self._drag.Dragging then
			self:_FXResume()
			self:_GlowVisible(true)
		end
	end)
end

-- Frame-rate governor: a Heartbeat counter that only does arithmetic. When more than SlowShare of the
-- frames in a 2 s window are slower than SlowFrame (default ~18 fps) the window steps its visuals down
-- one level (1 lite backdrop, 2 no backdrop, 3 no halo). It never steps back up, so it cannot flap.
-- Frames during open / close / drag are ignored (those are expected to be heavy), as is the warm-up.
function Window:_StartGovernor()
	if self._gov or Library.Perf.Adaptive == false then return end
	local P = Library.Perf
	local acc, n, slow = 0, 0, 0
	local resumeAt = os.clock() + (P.Warmup or 3)
	self._govReset = function() acc, n, slow = 0, 0, 0 resumeAt = os.clock() + (P.Warmup or 3) end
	self._gov = RunService.Heartbeat:Connect(function(dt)
		if not self.Visible or self._moving or self._drag.Dragging or os.clock() < resumeAt then
			acc, n, slow = 0, 0, 0
			return
		end
		acc += dt
		n += 1
		if dt > (P.SlowFrame or 1 / 18) then slow += 1 end
		if acc >= 2 then
			local share = slow / n
			acc, n, slow = 0, 0, 0
			if share > (P.SlowShare or 0.25) then self:_Degrade() end
		end
	end)
	table.insert(self.Conns, self._gov)
end

function Window:_Degrade()
	local q = (self._qual or 0) + 1
	self._qual = q
	if q <= 2 then
		self:SetBackground(nil, true)   -- 1 = lite particles, 2 = off (see SetBackground)
	else
		self:_GlowVisible(false)
		if self._gov then self._gov:Disconnect() self._gov = nil end
	end
	if self._govReset then self._govReset() end
	safe(self.Cfg.OnDegrade, q)
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
	local fontName = self.FontName
	if type(cfg.Theme) == "table" and cfg.Theme.Font ~= nil then fontName = "Custom" end
	if cfg.Font ~= nil then
		local fr, fb, fn = Library._fontPair(cfg.Font)
		if fr then T.Font, T.FontBold, fontName = fr, fb, fn end
	end
	local GLOW = false -- halo rings around the window removed (PC and mobile now look the same)
	local RADIUS = 24
	-- cfg.Transparency: 0 = default look ... 1 = fully see-through (backgrounds only, text/controls stay visible)
	local GLASS = math.clamp(tonumber(cfg.Transparency) or 0, 0, 1)
	local function glass(base) return base + (1 - base) * GLASS end

	local win = setmetatable({
		Library = self, Theme = T, Cfg = cfg, Glass = GLASS, Tabs = {}, Conns = {}, Visible = true,
		_drag = {}, _openDrag = { Threshold = 8 }, Maximized = false, FontName = fontName,
	}, Window)

	local title = cfg.Title or "SpectreUI"
	local brand, sub = title:match("^(.-)%s*|%s*(.+)$")
	brand = brand or title
	win.Brand, win.Sub = brand, sub

	local gui = new("ScreenGui", {
		Name = "SpectreUI", ResetOnSpawn = false, IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
	})
	Library._fullScreen(gui)
	Library._mount(gui)
	win.Gui = gui
	-- if something unparents the gui (not destroys it), put it back
	table.insert(win.Conns, gui.AncestryChanged:Connect(function(_, parent)
		if parent == nil and not win._destroyed then
			task.defer(function()
				if not win._destroyed and gui.Parent == nil then pcall(Library._mount, gui) end
			end)
		end
	end))

	local main = new("Frame", {
		Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = T.Background, BackgroundTransparency = glass(0.02), BorderSizePixel = 0,
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
			local base = 0.88 + (i - 1) * 0.05
			local ring = new("Frame", {
				Name = "Glow" .. i, AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1,
				ZIndex = 0, Parent = gui,
			}, { corner(RADIUS + 6), stroke(T.Accent, 2 + (2 - i), base) })
			win.Glow[i] = { frame = ring, pad = pad, stroke = ring:FindFirstChildOfClass("UIStroke"), base = base }
		end
		local function sync()
			if win._glowHidden then return end   -- hidden rings are not repositioned (no work while moving)
			for _, g in ipairs(win.Glow) do
				g.frame.Position = main.Position
				g.frame.Size = main.Size + UDim2.fromOffset(g.pad, g.pad)
			end
		end
		main:GetPropertyChangedSignal("Position"):Connect(sync)
		main:GetPropertyChangedSignal("Size"):Connect(sync)
		win._glowSync = sync
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
	-- floating rounded header card (inset from the window edge, concentric with the window radius)
	local hcard = new("Frame", {
		Name = "HeaderCard", Position = UDim2.fromOffset(10, 8), Size = UDim2.new(1, -20, 0, HEADER_H - 14),
		BackgroundColor3 = T.Control, BackgroundTransparency = glass(0.4), BorderSizePixel = 0, Parent = header,
	}, {
		corner(18), stroke(T.Accent, 1, 0.65),
		new("Frame", {
			Name = "Tint", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Accent, BackgroundTransparency = 0,
			BorderSizePixel = 0,
		}, {
			corner(18),
			new("UIGradient", { Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.72), NumberSequenceKeypoint.new(0.6, 0.93), NumberSequenceKeypoint.new(1, 0.98),
			}) }),
		}),
	})
	win.HeaderCard = hcard

	-- header cluster is bounded and clipped so a long brand / subtitle can never
	-- slide under the close button (that was a real overlap on narrow screens)
	local closeW = UserInputService.TouchEnabled and 40 or 34
	local canResize = cfg.Resizable ~= false
	local nBtns = canResize and 3 or 2
	local btnArea = closeW * nBtns + 4 * (nBtns - 1) -- close + hide (+ maximize) buttons
	local left = new("Frame", {
		Size = UDim2.new(1, -(btnArea + 16), 1, 0), BackgroundTransparency = 1, ClipsDescendants = true, Parent = hcard,
	}, {
		list(10, { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center }),
		padding(10, 0, 0, 0),
	})
	win.Left = left
	if cfg.Logo then
		-- header logo: tweak with cfg.LogoSize (number or {w,h}), cfg.LogoColor (Color3), cfg.LogoCorner (px, 0 = square)
		local ls = cfg.LogoSize or 26
		local lw, lh
		if type(ls) == "table" then lw, lh = ls[1] or ls.X or 26, ls[2] or ls.Y or 26
		elseif typeof(ls) == "Vector2" then lw, lh = ls.X, ls.Y
		else lw, lh = ls, ls end
		local hlogo = new("ImageLabel", {
			Name = "Logo", LayoutOrder = 1, Size = UDim2.fromOffset(lw, lh), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit,
			ImageColor3 = cfg.LogoColor or Color3.new(1, 1, 1),
			Image = (type(cfg.Logo) == "number" or tonumber(cfg.Logo)) and ("rbxassetid://" .. tostring(cfg.Logo)) or cfg.Logo, Parent = left,
		})
		if cfg.LogoCorner and cfg.LogoCorner > 0 then
			new("UICorner", { CornerRadius = UDim.new(0, cfg.LogoCorner), Parent = hlogo })
		end
		win.LogoImage = hlogo
	else
		new("Frame", {
			LayoutOrder = 1, Size = UDim2.fromOffset(34, 34), BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0, Parent = left,
		}, {
			corner(13), gradient(T.Accent, T.Accent2, 45), stroke(T.Sheen, 1, 0.65),
			Library._oa(new("TextLabel", {
				Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = brand:sub(1, 2),
				Font = Enum.Font.GothamBlack, TextSize = 15, TextColor3 = Library.OnAccent(T),
			})),
		})
	end
	win.BrandLabel = new("TextLabel", {
		LayoutOrder = 2, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AX, BackgroundTransparency = 1,
		Text = brand, Font = T.FontBold, TextSize = 17, TextColor3 = T.Text, Parent = left,
	})
	if sub then
		win.SubSep = new("Frame", {   -- the pill (kept under the old name so compact mode still hides it)
			LayoutOrder = 3, Size = UDim2.fromOffset(0, 24), AutomaticSize = AX, BackgroundColor3 = T.Accent,
			BackgroundTransparency = 0.86, BorderSizePixel = 0, Parent = left,
		}, { corner(12), stroke(T.Accent, 1, 0.6), padding(11, 0, 11, 0) })
		win.SubLabel = new("TextLabel", {
			Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AX, BackgroundTransparency = 1,
			Text = sub, Font = T.FontBold, TextSize = 12, TextColor3 = T.Accent, Parent = win.SubSep,
		})
	end

	local close = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(closeW, closeW),
		BackgroundColor3 = T.Control, BackgroundTransparency = 1, Text = "×", Font = T.FontBold, TextSize = 28, TextColor3 = T.SubText,
		AutoButtonColor = false, Parent = hcard,
	}, { corner(20) })
	close.MouseEnter:Connect(function()
		if not usingTouch() then
			tween(close, 0.14, { TextColor3 = Color3.fromRGB(255, 120, 120), BackgroundTransparency = 0.4 })
		end
	end)
	close.MouseLeave:Connect(function()
		tween(close, 0.14, { TextColor3 = T.SubText, BackgroundTransparency = 1 })
	end)
	bindPress(close, function()
		tween(close, 0.07, { TextColor3 = Color3.fromRGB(255, 120, 120) })
	end, function()
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
			Text = "", AutoButtonColor = false, Parent = hcard,
		}, { corner(20) })
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
					end, function()
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
			Text = "", AutoButtonColor = false, Parent = hcard,
		}, { corner(20) })
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
					end, function()
						if usingTouch() then tint(T.SubText); tween(mxb, 0.16, { BackgroundTransparency = 1 }) end
		end)
		mxb.MouseButton1Click:Connect(function() win:SetMaximized(not win.Maximized) end)
	end

	-- drag handle: covers the header EXCEPT the buttons, so pressing a control never starts a drag
	local dragZone = new("Frame", {
		Name = "DragZone", Size = UDim2.new(1, -(btnArea + 28), 1, 0), BackgroundTransparency = 1,
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
		win:_GlowVisible(false)
		-- animating the window's outer stroke forces a re-raster of the whole
		-- rounded border every frame; skip it on low power
		if not lowPower() then mainStroke.Color, mainStroke.Transparency = T.Accent, 0.35 end
	end
	win._drag.OnEnd = function()
		if win.Visible and not win._moving then win:_FXResume() win:_GlowVisible(true) end
		if win._govReset then win._govReset() end
		if not lowPower() then mainStroke.Color, mainStroke.Transparency = T.Border, 0.1 end
	end
	makeDraggable(gui, dragZone, main, win._drag)

	---------------------------------------------------------- body / sidebar
	local body = new("Frame", {
		Position = UDim2.fromOffset(0, HEADER_H), Size = UDim2.new(1, 0, 1, -HEADER_H),
		BackgroundTransparency = 1, Parent = main,
	})
	local sidebar = new("Frame", { Size = UDim2.new(0, 164, 1, 0), BackgroundTransparency = 1, Parent = body })
	win.SidePanel = new("Frame", {
		Name = "SidePanel", Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -19, 1, -10),
		BackgroundColor3 = T.Control, BackgroundTransparency = glass(0.55), BorderSizePixel = 0, Parent = sidebar,
	}, { corner(18), stroke(T.Border, 1, 0.5) })
	win.Sidebar = sidebar
	win.TabList = new("ScrollingFrame", {
		Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -19, 1, -FOOT_H - 10), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = AY, ScrollingDirection = Enum.ScrollingDirection.Y,
		ElasticBehavior = Enum.ElasticBehavior.Never, Parent = sidebar,
	}, { list(UserInputService.TouchEnabled and 5 or 6), padding(8, 10, 8, 6) })

	local footer = new("Frame", {
		Position = UDim2.new(0, 10, 1, -FOOT_H - 10), Size = UDim2.new(1, -19, 0, FOOT_H), BackgroundTransparency = 1, Parent = sidebar,
	}, { padding(14, 0, 8, 0) })
	new("Frame", {
		Position = UDim2.new(0, -4, 0, 0), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.Border,
		BackgroundTransparency = 0.6, BorderSizePixel = 0, Parent = footer,
	})
	-- the whole profile card is a button: tap it to open the profile / game info popup
	win.ProfileButton = new("TextButton", {
		Name = "ProfileButton", Position = UDim2.fromOffset(-12, 3), Size = UDim2.new(1, 20, 1, -6),
		BackgroundColor3 = T.Accent, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0, Parent = footer,
	}, { corner(12) })
	feedback(win.ProfileButton, win.ProfileButton, "BackgroundTransparency", 1, 0.88, 0.78, true)
	-- profile card: player avatar + display name + @username (replaces the old brand/sub footer)
	local lpl = Players.LocalPlayer
	local dispName = (lpl and lpl.DisplayName) or "Player"
	local userName = (lpl and lpl.Name) or "Player"
	win.FooterAvatar = new("ImageLabel", {
		Position = UDim2.fromOffset(0, 10), Size = UDim2.fromOffset(34, 34), BackgroundColor3 = T.Panel, BorderSizePixel = 0,
		Image = "", ScaleType = Enum.ScaleType.Crop, Parent = footer,
	}, { corner(17), stroke(T.Accent, 1.5, 0.35) })
	if lpl then
		task.spawn(function()
			local okT, img = pcall(function()
				return Players:GetUserThumbnailAsync(lpl.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
			end)
			if okT and img and win.FooterAvatar and win.FooterAvatar.Parent then win.FooterAvatar.Image = img end
		end)
	end
	win.FooterBrand = new("TextLabel", {
		Position = UDim2.fromOffset(42, 10), Size = UDim2.new(1, -58, 0, 18), BackgroundTransparency = 1, Text = dispName,
		Font = T.FontBold, TextSize = 14, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = footer,
	}, { gradient(T.Accent, T.Accent2, 0) })
	win.FooterSub = new("TextLabel", {
		Position = UDim2.fromOffset(42, 28), Size = UDim2.new(1, -58, 0, 16), BackgroundTransparency = 1, Text = "@" .. userName,
		Font = T.Font, TextSize = 12, TextColor3 = T.SubText, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = footer,
	})
	win.FooterArrow = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -2, 0, 27), Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1,
		Text = "\226\150\178", Font = T.FontBold, TextSize = 12, TextColor3 = T.SubText, Parent = footer,
	})
	win.Footer = footer
	win:_BuildProfile()

	---------------------------------------------------------- content / search
	local content = new("Frame", {
		Position = UDim2.fromOffset(164, 0), Size = UDim2.new(1, -164, 1, 0), BackgroundTransparency = 1, Parent = body,
	})
	win.Content = content
	-- search box now lives in the header card, in the gap between the title and the - / [] / x buttons
	local SEARCH_BAR_H = closeW   -- collapsed = same size as the - / [] / x buttons
	local searchBar = new("Frame", {
		Name = "SearchBar", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -(8 + btnArea + 10), 0.5, 0),
		Size = UDim2.fromOffset(SEARCH_BAR_H, SEARCH_BAR_H), BackgroundColor3 = T.Control,
		BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true, Parent = hcard,
	}, { corner(20), stroke(T.Border, 1, 1) })   -- collapsed: transparent like the other header buttons
	win.SearchBar = searchBar
	local searchStroke = searchBar:FindFirstChildOfClass("UIStroke")
	searchStroke.Transparency = 1   -- stroke() lightens by 0.15; start fully hidden while collapsed
	-- magnifier drawn from frames (no asset needed)
	local magX = math.floor((SEARCH_BAR_H - 16) / 2)   -- centered while collapsed
	local mag = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, magX, 0.5, 0), Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1, Parent = searchBar,
	})
	local magRing = new("Frame", {
		Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1, Parent = mag,
	}, { corner(5), stroke(T.SubText, 1.6, 0.15) })
	local magRingStroke = magRing:FindFirstChildOfClass("UIStroke")
	local magHandle = new("Frame", {
		Position = UDim2.fromOffset(8, 10), Size = UDim2.fromOffset(6, 2), Rotation = 45, BackgroundColor3 = T.SubText,
		BorderSizePixel = 0, Parent = mag,
	})
	win.SearchBox = new("TextBox", {
		Position = UDim2.fromOffset(32, 0), Size = UDim2.new(1, -42, 1, 0), BackgroundTransparency = 1, Text = "", Visible = false,
		PlaceholderText = "Search all tabs...", PlaceholderColor3 = T.SubText, TextColor3 = T.Text, Font = T.Font, TextSize = 14,
		TextXAlignment = LEFT, ClearTextOnFocus = false, TextTruncate = Enum.TextTruncate.AtEnd, Parent = searchBar,
	})
	-- collapsed = just the magnifier; tap it and it grows into the full box (collapses again when empty + unfocused)
	local searchOpen, expandedW, applyHeader = false, 190, nil
	local hit = new("TextButton", {
		Name = "SearchHit", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
		ZIndex = 5, Parent = searchBar,
	})
	-- width of the search box adapts to the free space in the header; title cluster + drag zone shrink to make room
	do
		local leftList = left:FindFirstChildOfClass("UIListLayout")
		local busy = false
		function applyHeader(animate)
			if busy or win._destroyed then return end
			busy = true
			local sc = (win.Scale and win.Scale.Scale) or 1
			if sc <= 0.01 then sc = 1 end
			local total = hcard.AbsoluteSize.X / sc
			if total > 40 then
				local rightW = 8 + btnArea + 10                       -- buttons + gap
				local contentW = (leftList and leftList.AbsoluteContentSize.X or 0) / sc
				local free = total - rightW - (contentW + 10 + 12)    -- 10 = left padding, 12 = gap before the box
				local maxW = math.max(70, total - rightW - 46)        -- always keep a little room for the logo
				expandedW = math.floor(math.min(math.clamp(free, 120, 220), maxW))
				local w = searchOpen and expandedW or SEARCH_BAR_H
				if animate then
					tween(searchBar, 0.2, { Size = UDim2.fromOffset(w, SEARCH_BAR_H) })
				else
					searchBar.Size = UDim2.fromOffset(w, SEARCH_BAR_H)
				end
				-- reserve the expanded width while open so the title never slides under the box
				left.Size = UDim2.new(1, -(rightW + w + 6), 1, 0)
				dragZone.Size = UDim2.new(1, -(rightW + w + 18), 1, 0)
			end
			busy = false
		end
		hcard:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() applyHeader(false) end)
		if leftList then leftList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() applyHeader(false) end) end
		applyHeader(false)
		task.defer(applyHeader, false)
	end
	local function setSearchOpen(v)
		if searchOpen == v or win._destroyed then return end
		searchOpen = v
		hit.Visible = not v
		win.SearchBox.Visible = v
		if win._searchChip then win._searchChip.Visible = v and win.SearchBox.Text == "" end
		-- open = boxed field with the icon on the left; collapsed = bare icon centered, like the other buttons
		tween(mag, 0.2, { Position = UDim2.new(0, v and 10 or magX, 0.5, 0) })
		tween(magRingStroke, 0.2, { Color = v and T.Accent or T.SubText })
		tween(magHandle, 0.2, { BackgroundColor3 = v and T.Accent or T.SubText })
		tween(searchBar, 0.2, { BackgroundTransparency = v and 0.35 or 1 })
		tween(searchStroke, 0.2, { Transparency = v and 0.45 or 1 })
		applyHeader(true)
	end
	-- hover feedback identical to the - / [] / x buttons (collapsed only)
	hit.MouseEnter:Connect(function() if not searchOpen then tween(searchBar, 0.14, { BackgroundTransparency = 0.4 }) end end)
	hit.MouseLeave:Connect(function() if not searchOpen then tween(searchBar, 0.16, { BackgroundTransparency = 1 }) end end)
	hit.MouseButton1Click:Connect(function()
		setSearchOpen(true)
		task.defer(function()
			if searchOpen and win.SearchBox.Parent then win.SearchBox:CaptureFocus() end
		end)
	end)
	-- keyboard hint chip (PC only), hidden while typing
	if not UserInputService.TouchEnabled then
		local chip = new("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(48, 22),
			BackgroundColor3 = T.Panel, BackgroundTransparency = 0.2, Text = "Ctrl K", Font = T.FontBold, TextSize = 13,
			TextColor3 = T.SubText, Parent = searchBar,
		}, { corner(11), stroke(T.Border, 1, 0.5) })
		chip.Visible = false
		win._searchChip = chip
		win.SearchBox:GetPropertyChangedSignal("Text"):Connect(function() chip.Visible = searchOpen and win.SearchBox.Text == "" end)
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
	win.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		-- cleared from outside (e.g. after jumping to a result) and not being edited: fold back to the icon
		if win.SearchBox.Text == "" and not win.SearchBox:IsFocused() then setSearchOpen(false) end
	end)
	win.SearchBox.Focused:Connect(function()
		setSearchOpen(true)
		tween(searchStroke, 0.18, { Color = T.Accent, Transparency = 0.05 })
		tween(searchBar, 0.18, { BackgroundTransparency = 0.15 })
	end)
	win.SearchBox.FocusLost:Connect(function()
		if win.SearchBox.Text == "" then setSearchOpen(false) end
		if searchOpen then
			tween(searchStroke, 0.22, { Color = T.Border, Transparency = 0.45 })
			tween(searchBar, 0.22, { BackgroundTransparency = 0.35 })
		end
	end)

	win.Pages = new("Frame", {
		Position = UDim2.fromOffset(0, 6), Size = UDim2.new(1, 0, 1, -6 - 8),
		BackgroundTransparency = 1, ClipsDescendants = true, Parent = content,
	})
	-- veil used to fade a page in when switching tabs
	win.PageVeil = new("Frame", {
		Name = "PageVeil", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Background, BackgroundTransparency = 1,
		BorderSizePixel = 0, ZIndex = 20, Visible = false, Parent = win.Pages,
	})

	---------------------------------------------------------- global search results (all tabs)
	-- typing in the search box lists every matching control from EVERY tab ("Tab > Section"); click one (or press Enter
	-- for the first) and the window jumps straight to it. The pages themselves are no longer filtered.
	do
		local SKIP = { Separator = true, Divider = true }
		local function hex(c) return string.format("#%02x%02x%02x", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)) end
		local function esc(x) return (tostring(x):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")) end
		local resPanel = new("ScrollingFrame", { ElasticBehavior = Enum.ElasticBehavior.Never,
			Name = "SearchResults", Position = UDim2.fromOffset(6, 4), Size = UDim2.new(1, -26, 0, 0),
			BackgroundColor3 = T.Panel, BackgroundTransparency = 0, BorderSizePixel = 0, ScrollBarThickness = 3,
			ScrollBarImageColor3 = T.Accent, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ClipsDescendants = true, Visible = false, ZIndex = 40, Parent = content,
		}, {
			corner(12), stroke(T.Accent, 1, 0.3),
			new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 8) }),
			new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
		})
		local rows, firstJump = {}, nil
		local function clearRows()
			for _, r in ipairs(rows) do r:Destroy() end
			table.clear(rows)
			firstJump = nil
		end
		local function jump(e)
			if e.GoTab then
				win.SearchBox.Text = ""
				win:_ApplySearch()
				win:SetTab(e.GoTab)
			else
				Library._reveal(win, e)
			end
		end
		local function matchScore(e, toks)
			local name, tabn, secn = e.Name:lower(), (e.TabName or ""):lower(), (e.SectionName or ""):lower()
			local total = 0
			for _, tok in ipairs(toks) do
				local a = name:find(tok, 1, true)
				if a then
					total += (a == 1) and 30 or 20
				elseif secn:find(tok, 1, true) then
					total += 8
				elseif tabn:find(tok, 1, true) then
					total += 6
				else
					return 0
				end
			end
			return total
		end
		local function addRow(e, order, toks)
			local T2 = win.Theme
			local row = new("TextButton", {
				Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = T2.Control, BackgroundTransparency = 0.1, AutoButtonColor = false,
				Text = "", LayoutOrder = order, ZIndex = 41, Parent = resPanel,
			}, { corner(9), stroke(T2.Border, 1, 0.4) })
			local nm = esc(e.Name)
			local lower = e.Name:lower()
			for _, tok in ipairs(toks) do   -- bold + accent the first hit of every token
				local a, b = lower:find(tok, 1, true)
				if a then
					nm = esc(e.Name:sub(1, a - 1)) .. '<font color="' .. hex(T2.Accent) .. '"><b>' .. esc(e.Name:sub(a, b)) .. "</b></font>" .. esc(e.Name:sub(b + 1))
					break
				end
			end
			new("TextLabel", {
				Position = UDim2.fromOffset(12, 5), Size = UDim2.new(1, -110, 0, 20), BackgroundTransparency = 1, RichText = true,
				Text = nm, Font = T2.FontBold, TextSize = 15, TextColor3 = T2.Text, TextXAlignment = LEFT,
				TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 42, Parent = row,
			})
			local where
			if e.GoTab then
				where = '<font color="' .. hex(T2.Accent) .. '"><b>' .. esc(e.GoTab.Name) .. "</b></font>  (open tab)"
			else
				where = '<font color="' .. hex(T2.Accent) .. '"><b>' .. esc(e.TabName or "?") .. "</b></font>  \226\128\186  " .. esc(e.SectionName or "")
			end
			new("TextLabel", {
				Position = UDim2.fromOffset(12, 26), Size = UDim2.new(1, -110, 0, 16), BackgroundTransparency = 1, RichText = true,
				Text = where, Font = T2.Font, TextSize = 13, TextColor3 = T2.SubText, TextXAlignment = LEFT,
				TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 42, Parent = row,
			})
			new("TextLabel", {
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(0, 22),
				AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = T2.AccentSoft, BorderSizePixel = 0,
				Text = " " .. (e.GoTab and "TAB" or tostring(e.Kind):upper()) .. " ", Font = T2.FontBold, TextSize = 12,
				TextColor3 = T2.Text, ZIndex = 42, Parent = row,
			}, { corner(7) })
			row.MouseEnter:Connect(function() tween(row, 0.12, { BackgroundColor3 = T2.Lift or T2.Control, BackgroundTransparency = 0 }) end)
			row.MouseLeave:Connect(function() tween(row, 0.16, { BackgroundColor3 = T2.Control, BackgroundTransparency = 0.1 }) end)
			row.MouseButton1Click:Connect(function() jump(e) end)
			rows[#rows + 1] = row
			if not firstJump then firstJump = e end
		end

		local lastQ
		function win:_ShowResults(q)
			if q == lastQ then return end
			lastQ = q
			clearRows()
			if q == "" then
				resPanel.Visible = false
				return
			end
			local toks = {}
			for tok in q:gmatch("%S+") do toks[#toks + 1] = tok end
			local found = {}
			for _, tab in ipairs(self.Tabs) do
				local sc = matchScore({ Name = tab.Name, TabName = "", SectionName = "" }, toks)
				if sc > 0 then found[#found + 1] = { sc = sc + 5, e = { GoTab = tab, Name = tab.Name, Kind = "Tab" } } end
			end
			for _, e in ipairs(self._index or {}) do
				if not SKIP[e.Kind] and not (e.Ctl and e.Ctl.Hidden) and e.Frame and e.Frame.Parent then
					local sc = matchScore(e, toks)
					if sc > 0 then found[#found + 1] = { sc = sc, e = e } end
				end
			end
			table.sort(found, function(a, b) return a.sc > b.sc end)
			local n = math.min(#found, 40)
			for i = 1, n do addRow(found[i].e, i, toks) end
			if n == 0 then
				local none = new("TextLabel", {
					Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Text = "No results for \"" .. q .. "\"",
					Font = self.Theme.Font, TextSize = 14, TextColor3 = self.Theme.SubText, LayoutOrder = 1, ZIndex = 42, Parent = resPanel,
				})
				rows[#rows + 1] = none
			end
			local maxH = math.max(120, content.AbsoluteSize.Y - 20)
			local want = (n == 0 and 40 or n * 52) + 12
			resPanel.CanvasPosition = Vector2.new(0, 0)
			resPanel.Size = UDim2.new(1, -26, 0, math.min(want, maxH, 8 * 52 + 12))
			resPanel.Visible = true
		end
		win.SearchBox.FocusLost:Connect(function(enter)
			if enter and firstJump and resPanel.Visible then jump(firstJump) end
		end)
	end

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
				if not lowPower() then mainStroke.Color, mainStroke.Transparency = T.Accent, 0.35 end
			end,
			End = function()
				tintTicks(T.SubText, 0.35)
				if not lowPower() then mainStroke.Color, mainStroke.Transparency = T.Border, 0.1 end
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
		Name = "OpenButton", AnchorPoint = Vector2.new(0.5, 0.5),
		-- default spot: upper-left, just under the Roblox top bar (override with OpenPosition = UDim2...)
		Position = cfg.OpenPosition or UDim2.fromScale(0.17, 0.235),
		Size = UDim2.fromOffset(BS, BS), BackgroundColor3 = T.Panel, Text = cfg.Logo and "" or brand:sub(1, 2),
		Font = Enum.Font.GothamBlack, TextSize = touchUI and 19 or 17, TextColor3 = T.Text,
		AutoButtonColor = false, Visible = false, Active = true, Parent = gui,
	}, { corner(math.floor(BS * 0.3)), stroke(T.Accent, 1.5, 0.2) })
	local ob = win.OpenBtn
	local obStroke = ob:FindFirstChildOfClass("UIStroke")
	local obLogo
	if cfg.Logo then
		obLogo = new("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(BS * (cfg.OpenLogoScale or 0.58), BS * (cfg.OpenLogoScale or 0.58)),
			BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, ImageColor3 = cfg.LogoColor or Color3.new(1, 1, 1),
			Image = (type(cfg.Logo) == "number" or tonumber(cfg.Logo)) and ("rbxassetid://" .. tostring(cfg.Logo)) or cfg.Logo, Parent = ob,
		})
	else
		new("UIGradient", { Color = cseq({ 0, T.Panel }, { 1, T.Lift }), Rotation = 90, Parent = ob })
	end
	win.OpenScale = feedback(ob, ob, "BackgroundColor3", T.Panel, T.Lift, T.AccentSoft, false)

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
	if false and not lowPower() then -- glow ring around the floating button disabled
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
	win._openDrag.Direct = true -- follow the pointer 1:1 (the eased follow made the small button feel laggy / floaty)
	win._openDrag.Half = BS / 2
	-- on phones keep the button off the Roblox menu / chat icons (top-left) while dragging, so it never has to be
	-- pulled back after release
	win._openDrag.Clamp = function(c)
		if touchUI then
			local minY = 60 + BS / 2
			if c.X - BS / 2 < 110 and c.Y < minY then return Vector2.new(c.X, minY) end
		end
		return c
	end
	win._openDrag.OnStart = function()
		awake()
		showTip(false)
	end
	-- the button now stays exactly where it was dropped. The old "glide to the nearest side edge" is opt-in:
	-- CreateWindow({ OpenSnap = true })
	win._openDrag.OnEnd = function()
		if cfg.OpenSnap and win._openDrag.Moved and win._openDrag.Center then
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
	table.insert(win.Conns, UserInputService.WindowFocusReleased:Connect(function()
		win._blurred = true
		win:_FXPause()
	end))
	table.insert(win.Conns, UserInputService.WindowFocused:Connect(function()
		win._blurred = false
		if win.Visible and not win._moving and not win._drag.Dragging then win:_FXResume() end
	end))
	win:_StartGovernor()

	table.insert(self.Windows, win)
	win:_PlayIntro()
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
		self:_MotionBegin(0.3)
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
		if compact and self.CloseProfile then self:CloseProfile() end
		-- keep the rounded side panel snug in compact (icon-only) mode
		local ox, ow = compact and 5 or 10, compact and -10 or -19
		self.SidePanel.Position = UDim2.fromOffset(ox, 0)
		self.SidePanel.Size = UDim2.new(1, ow, 1, -10)
		self.TabList.Position = UDim2.fromOffset(ox, 0)
		self.TabList.Size = UDim2.new(1, ow, 1, -FOOT_H - 10)
		self.Footer.Position = UDim2.new(0, ox, 1, -FOOT_H - 10)
		self.Footer.Size = UDim2.new(1, ow, 0, FOOT_H)
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
	if orel and not self._openDrag.Dragging then
		local hb = (self.OpenSize or 42) / 2
		local c = clampCenter(vp, Vector2.new(hb, hb), Vector2.new(orel.X * vp.X, orel.Y * vp.Y))
		self.OpenBtn.Position = UDim2.fromOffset(c.X, c.Y)
	end
	if self._nm then self._nm:_RefitSoon() end
end

function Window:CloseDropdowns()
	if self._dd then self._dd:Close() end
end

-- shared dim layer behind dropdowns / colour pickers. It fades out instead of vanishing, and a token makes
-- sure an old fade can never hide the layer again after another popup has just opened it.
function Window:_ShowOverlay(dim)
	local ov = self.Overlay
	self._ovTok = (self._ovTok or 0) + 1
	if not ov.Visible then ov.BackgroundTransparency = 1 end
	ov.BackgroundColor3 = Color3.new(0, 0, 0)
	ov.Visible = true
	tween(ov, 0.2, { BackgroundTransparency = dim or 1 }, QUAD, OUT)
end

function Window:_HideOverlay()
	local ov = self.Overlay
	if not ov.Visible then return end
	self._ovTok = (self._ovTok or 0) + 1
	local tok = self._ovTok
	tween(ov, 0.14, { BackgroundTransparency = 1 }, QUAD, IN).Completed:Connect(function()
		if self._ovTok == tok then ov.Visible = false end
	end)
end

-- open / close animation: scale + slide + fade (veil). Runs on every platform; on low power it
-- skips the UIScale (that is the expensive part: it re-rasterizes every stroke) and uses
-- slide + fade only, which is cheap.
local SLIDE = 16

-- Where the window rests when it is not animating: the saved (dragged) position, clamped to the screen the
-- same way _Fit does. nil until the window has been placed once, then the live Position is used instead.
-- (_AnimBase / _AnimDone call this; it used to be missing, which broke the open / close animation.)
function Window:_HomePos()
	local vp = self.Gui.AbsoluteSize
	if vp.X <= 0 or vp.Y <= 0 then return nil end
	local rel = self.Maximized and Vector2.new(0.5, 0.5) or self._drag.Rel
	if not rel then return nil end
	local half = self.Main.AbsoluteSize / math.max(self.Scale.Scale, 0.01) / 2
	local c = clampCenter(vp, half, Vector2.new(rel.X * vp.X, rel.Y * vp.Y))
	return UDim2.fromOffset(math.round(c.X), math.round(c.Y))
end

function Window:_AnimBase()
	local home = self:_HomePos()
	if home then
		self._animBase = home
		return home
	end
	if not self._animBase then self._animBase = self.Main.Position end
	return self._animBase
end

function Window:_AnimDone()
	local home = self:_HomePos() or self._animBase
	if home then self.Main.Position = home end
	self._animBase = nil
	self.Scale.Scale = 1
end

function Window:_PlayOpen(fresh)
	self._vseq = (self._vseq or 0) + 1
	local seq = self._vseq
	local veil = self.Veil
	local pop = Library.Anim.Pop == true and not lowPower()
	local base = self:_AnimBase()
	self:_MotionBegin(0.5)
	if fresh then
		self.Main.Position = base + UDim2.fromOffset(0, SLIDE)
		if pop then self.Scale.Scale = 0.92 end
		veil.BackgroundTransparency = 0
	end
	veil.Visible = true
	local function run()
		if self._vseq ~= seq or self._destroyed then return end
		if pop then tween(self.Scale, 0.42, { Scale = 1 }, QUINT, OUT) end
		tween(self.Main, 0.42, { Position = base }, QUINT, OUT)
		tween(veil, 0.3, { BackgroundTransparency = 1 }, SINE, OUT).Completed:Connect(function(st)
			if self._vseq ~= seq or st ~= Enum.PlaybackState.Completed then return end
			veil.Visible = false
			self:_AnimDone()
		end)
	end
	-- a fresh open makes the whole window visible for the first time: let that heavy frame pass, then animate
	if fresh then nextFrame(run) else run() end
end

-- Launch animation (first show only): the window rises into place while the window-colored veil dissolves, a
-- soft band of light sweeps across it, the border pulses, then the sidebar icons pop in one after another
-- (Window:_IntroTab) and the first page rises last. Everything is a one-shot tween (no loops, no per-frame
-- Lua) and starts one frame late so the heavy first frame cannot eat the beginning of it.
-- Skipped (plain open) on low power or with Library.Anim.Intro = false / CreateWindow({ Intro = false }).
function Window:_PlayIntro()
	if Library._holdIntro then
		-- the launch splash is still showing: keep the window hidden, the splash starts this animation itself when it is done
		self._introHeld = true
		self.Gui.Enabled = false
		return
	end
	if self.Cfg.Intro == false or Library.Anim.Intro == false then
		return self:_PlayOpen(true)
	end
	self._vseq = (self._vseq or 0) + 1
	local seq = self._vseq
	local T = self.Theme
	local veil, main = self.Veil, self.Main
	local base = self:_AnimBase()
	self._introT = os.clock()
	self:_MotionBegin(1.1)
	main.Position = base + UDim2.fromOffset(0, 34)
	veil.BackgroundTransparency = 0
	veil.Visible = true
	-- the light band is a gradient offset sliding inside a rounded frame, so it is clipped to the window shape
	local band = new("UIGradient", {
		Rotation = 20, Offset = Vector2.new(-1, 0),
		Color = cseq({ 0, T.Accent }, { 0.5, Color3.new(1, 1, 1) }, { 1, T.Accent2 }),
		Transparency = NumberSequence.new({ nsk(0, 1), nsk(0.38, 1), nsk(0.5, 0.8), nsk(0.62, 1), nsk(1, 1) }),
	})
	local lite = lowPower()   -- phones: same rise + veil fade + tab pop-in, but no light sweep / flash
	local shine = new("Frame", {
		Name = "IntroShine", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
		ZIndex = 52, Active = false, Parent = main,
	}, { new("UICorner", { CornerRadius = UDim.new(0, self.Radius or 24) }), band })
	nextFrame(function()
		if self._vseq ~= seq or self._destroyed then shine:Destroy() return end
		tween(main, 0.7, { Position = base }, QUINT, OUT)
		tween(veil, 0.55, { BackgroundTransparency = 1 }, SINE, OUT).Completed:Connect(function(st)
			if self._vseq ~= seq or st ~= Enum.PlaybackState.Completed then return end
			veil.Visible = false
			self:_AnimDone()
		end)
		if lite then shine:Destroy() end
		task.delay(0.25, function()
			if lite or not shine.Parent then return end
			tween(band, 0.95, { Offset = Vector2.new(1, 0) }, SINE, OUT).Completed:Connect(function() shine:Destroy() end)
		end)
		task.delay(0.5, function()
			if not lite and not self._destroyed and self._vseq == seq then self:Flash(T.Accent) end
		end)
	end)
end

-- called by CreateTab: tabs created right after the window (the launch) animate in one by one
function Window:_IntroTab(tab)
	local t0 = self._introT
	if not t0 or os.clock() - t0 > 2 then return end
	local order = #self.Tabs
	local label, scale = tab.Label, tab.IconScale
	label.TextTransparency = 1
	if scale then
		scale.Scale = 0
		tween(scale, 0.05, { Scale = 0 })   -- also cancels the select-pop tween the first tab already started
	end
	task.delay(0.3 + (order - 1) * 0.07, function()
		if self._destroyed or not label.Parent then return end
		tween(label, 0.3, { TextTransparency = 0 }, SINE, OUT)
		if scale then tween(scale, 0.45, { Scale = 1 }, BACK, OUT) end
	end)
	if order == 1 then
		-- the first page rises in last, from under the window-colored page veil
		local page, pv = tab.Page, self.PageVeil
		local pseq = self._pseq or 0
		page.Position = UDim2.fromOffset(0, 22)
		pv.BackgroundTransparency = 0
		pv.Visible = true
		task.delay(0.3, function()
			if self._destroyed or (self._pseq or 0) ~= pseq then return end   -- the user already switched tab
			tween(page, 0.6, { Position = UDim2.new() }, QUINT, OUT)
			tween(pv, 0.5, { BackgroundTransparency = 1 }, SINE, OUT).Completed:Connect(function()
				if (self._pseq or 0) == pseq then pv.Visible = false end
			end)
		end)
	end
end

-- close animation: slide down + fade, then swap to the floating open button
function Window:_PlayClose()
	self._vseq = (self._vseq or 0) + 1
	local seq = self._vseq
	local veil = self.Veil
	local pop = Library.Anim.Pop == true and not lowPower()
	local base = self:_AnimBase()
	self:_MotionBegin(0.3)
	if not veil.Visible then
		veil.BackgroundTransparency = 1
		veil.Visible = true
	end
	if pop then tween(self.Scale, 0.22, { Scale = 0.94 }, QUAD, IN) end
	tween(self.Main, 0.22, { Position = base + UDim2.fromOffset(0, SLIDE) }, QUAD, IN)
	tween(veil, 0.22, { BackgroundTransparency = 0 }, SINE, IN).Completed:Connect(function()
		if self._vseq ~= seq or self.Visible then return end
		veil.Visible = false
		self.Main.Visible = false
		self:_AnimDone()
		self:_FXPause() -- nothing is on screen: stop the looping backdrop tweens
		self:_GlowVisible(false)
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
		local msz = self.Main.Size
		local sz = Vector2.new(msz.X.Offset, msz.Y.Offset) -- real size (AbsoluteSize is squished by the open-animation UIScale)
		if not self.Cfg.Width then self.Cfg.Width, self._restore.W = sz.X, sz.X end
		if not self.Cfg.Height then self.Cfg.Height, self._restore.H = sz.Y, sz.Y end
	else
		local r = self._restore or {}
		self.Cfg.Width, self.Cfg.Height = r.W, r.H
		self._drag.Rel = r.Rel or Vector2.new(0.5, 0.5)
	end
	self:_SetMaxFlag(v)
	self:_FitVeiled()
	safe(self.Cfg.OnMaximize, v)
end

-- Maximize / restore without flicker. Tweening Main.Size for 0.3 s made the whole layout (item grid columns,
-- two-column split, wrapped text, scroll canvas) recompute on EVERY frame, which showed as flashing.
-- Instead: the window-colored veil fades in (0.1 s), the size / position snap once while nothing is visible,
-- the layout settles for a moment, then the veil fades out. On low power / hidden window: plain snap.
function Window:_FitVeiled()
	if lowPower() or not self.Main.Visible or not self.Veil then
		return self:_Fit(false)
	end
	self._vseq = (self._vseq or 0) + 1
	local seq = self._vseq
	local veil = self.Veil
	self:_MotionBegin(0.6)
	if not veil.Visible then veil.BackgroundTransparency = 1 end
	veil.Visible = true
	tween(veil, 0.1, { BackgroundTransparency = 0 }, SINE, IN).Completed:Connect(function()
		if self._vseq ~= seq or self._destroyed then return end
		self:_Fit(false)
		task.delay(0.08, function() -- let grid / columns re-layout behind the veil
			if self._vseq ~= seq or self._destroyed then return end
			tween(veil, 0.2, { BackgroundTransparency = 1 }, SINE, OUT).Completed:Connect(function(st)
				if self._vseq ~= seq or st ~= Enum.PlaybackState.Completed then return end
				veil.Visible = false
			end)
		end)
	end)
end

function Window:IsMaximized() return self.Maximized end

-- resize with the same clamping as dragging the grip; width / height in pixels
function Window:Resize(w, h)
	self:_SetMaxFlag(false)
	self:SetSize(w, h)
end

function Library._profFmtTime(sec)
	sec = math.max(0, math.floor(sec))
	local h, m, x = sec // 3600, (sec % 3600) // 60, sec % 60
	if h > 0 then return ("%d:%02d:%02d"):format(h, m, x) end
	return ("%02d:%02d"):format(m, x)
end

-- Profile popup: tap the profile card in the sidebar footer. Shows who you are, which game / server you
-- are in (icon + name), live ping / fps / session time, IDs (tap a row to copy) and quick actions.
function Window:_BuildProfile()
	local win, T = self, self.Theme
	local lpl = Players.LocalPlayer
	if not lpl then return end
	local Market = game:GetService("MarketplaceService")
	local Stats = game:GetService("Stats")
	local main = self.Main
	local CARD_W = 288
	local RIGHT = Enum.TextXAlignment.Right
	local TRUNC = Enum.TextTruncate.AtEnd
	local baseY = -(FOOT_H + 16)

	local blocker = new("TextButton", {
		Name = "ProfileBlocker", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
		Visible = false, ZIndex = 54, Parent = main,
	})
	local card = new("Frame", {
		Name = "ProfileCard", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, baseY),
		Size = UDim2.fromOffset(CARD_W, 300), BackgroundColor3 = T.Panel, BackgroundTransparency = 0.02, BorderSizePixel = 0,
		Visible = false, ZIndex = 56, ClipsDescendants = true, Parent = main,
	}, { corner(18), stroke(T.Accent, 1, 0.45) })
	local scroll = new("ScrollingFrame", { ElasticBehavior = Enum.ElasticBehavior.Never,
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = AY, ScrollingDirection = Enum.ScrollingDirection.Y, Parent = card,
	}, { list(8), padding(12, 12, 12, 12) })
	local lay = scroll:FindFirstChildOfClass("UIListLayout")

	local order = 0
	local function nextOrder() order += 1 return order end
	local function copy(text)
		if type(setclipboard) == "function" then
			pcall(setclipboard, text)
			win:Notify({ Title = "Copied", Content = text, Kind = "Success", Duration = 1.6 })
		else
			win:Notify({ Title = "Clipboard not supported", Content = text, Kind = "Warning", Duration = 3 })
		end
	end
	local function label(props)
		props.BackgroundTransparency = 1
		props.Font = props.Font or T.Font
		props.TextSize = props.TextSize or 12
		props.TextColor3 = props.TextColor3 or T.Text
		props.TextXAlignment = props.TextXAlignment or LEFT
		props.TextTruncate = props.TextTruncate or TRUNC
		return new("TextLabel", props)
	end
	local function divider()
		new("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.Border, BackgroundTransparency = 0.6, BorderSizePixel = 0, LayoutOrder = nextOrder(), Parent = scroll })
	end
	local function caption(text)
		label({ Size = UDim2.new(1, 0, 0, 16), Text = text, Font = T.FontBold, TextSize = 12, TextColor3 = T.SubText, LayoutOrder = nextOrder(), Parent = scroll })
	end

	-- ---- who you are
	local head = new("Frame", { Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, LayoutOrder = nextOrder(), Parent = scroll })
	local av = new("ImageLabel", {
		Size = UDim2.fromOffset(52, 52), BackgroundColor3 = T.Control, BorderSizePixel = 0, Image = "", ScaleType = Enum.ScaleType.Crop, Parent = head,
	}, { corner(26), stroke(T.Accent, 2, 0.2) })
	label({ Position = UDim2.fromOffset(62, 6), Size = UDim2.new(1, -62, 0, 22), Text = lpl.DisplayName, Font = T.FontBold, TextSize = 17, Parent = head })
	label({ Position = UDim2.fromOffset(62, 29), Size = UDim2.new(1, -62, 0, 16), Text = "@" .. lpl.Name, TextColor3 = T.SubText, Parent = head })
	task.spawn(function()
		local ok, img = pcall(function()
			return Players:GetUserThumbnailAsync(lpl.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		end)
		if ok and img and av.Parent then av.Image = img end
	end)

	divider()
	caption("CURRENT GAME")

	-- ---- game card: icon + name
	local gcard = new("Frame", {
		Size = UDim2.new(1, 0, 0, 60), BackgroundColor3 = T.Control, BackgroundTransparency = 0.45, BorderSizePixel = 0,
		LayoutOrder = nextOrder(), Parent = scroll,
	}, { corner(12), stroke(T.Border, 1, 0.6) })
	local gicon = new("ImageLabel", {
		Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(44, 44), BackgroundColor3 = T.Panel, BorderSizePixel = 0,
		Image = (game.GameId ~= 0) and ("rbxthumb://type=GameIcon&id=" .. game.GameId .. "&w=150&h=150") or "",
		ScaleType = Enum.ScaleType.Crop, Parent = gcard,
	}, { corner(10) })
	local gname = label({
		Position = UDim2.fromOffset(60, 8), Size = UDim2.new(1, -68, 0, 30), Text = game.Name, Font = T.FontBold, TextSize = 13,
		TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Parent = gcard,
	})
	local gsub = label({ Position = UDim2.fromOffset(60, 38), Size = UDim2.new(1, -68, 0, 14), Text = "", TextSize = 13, TextColor3 = T.SubText, Parent = gcard })
	-- real place name / icon (cached, so reopening costs nothing)
	local function applyInfo(info)
		if not info then return end
		if info.Name and info.Name ~= "" and gname.Parent then gname.Text = info.Name end
		if info.IconImageAssetId and info.IconImageAssetId ~= 0 and gicon.Parent then gicon.Image = "rbxassetid://" .. info.IconImageAssetId end
		if info.Creator and info.Creator.Name and gsub.Parent then gsub.Text = "by " .. tostring(info.Creator.Name) end
	end
	if Library._placeInfo then
		applyInfo(Library._placeInfo)
	else
		task.spawn(function()
			local ok, info = pcall(function() return Market:GetProductInfo(game.PlaceId) end)
			if ok and type(info) == "table" then Library._placeInfo = info applyInfo(info) end
		end)
	end

	divider()

	-- ---- live stats / ids
	local stats = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, LayoutOrder = nextOrder(), Parent = scroll,
	}, { list(2) })
	local vals, getters, srow = {}, {}, 0
	local function row(key, title, get, copyGet)
		srow += 1
		local r = new("TextButton", {
			Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = srow, Parent = stats,
		})
		label({ Size = UDim2.new(0.4, 0, 1, 0), Text = title, TextColor3 = T.SubText, Parent = r })
		vals[key] = label({ Position = UDim2.fromScale(0.4, 0), Size = UDim2.fromScale(0.6, 1), Text = "-", TextXAlignment = RIGHT, Font = T.FontBold, Parent = r })
		getters[key] = get
		if copyGet then
			r.MouseButton1Click:Connect(function()
				local okc, t = pcall(copyGet)
				if okc and t and t ~= "" then copy(tostring(t)) end
			end)
		end
	end
	local fps = 0
	local jobId = game.JobId
	row("players", "Players", function() return ("%d / %d"):format(#Players:GetPlayers(), Players.MaxPlayers) end)
	row("ping", "Ping", function()
		local okp, v = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
		return okp and (math.floor(v + 0.5) .. " ms") or "-"
	end)
	row("fps", "FPS", function() return tostring(fps) end)
	row("time", "In server", function() return Library._profFmtTime(workspace.DistributedGameTime) end)
	row("job", "Server ID (tap to copy)", function() return jobId ~= "" and (jobId:sub(1, 8) .. "...") or "Studio" end, function() return jobId end)
	row("place", "Place ID (tap to copy)", function() return tostring(game.PlaceId) end, function() return tostring(game.PlaceId) end)
	row("uid", "User ID (tap to copy)", function() return tostring(lpl.UserId) end, function() return tostring(lpl.UserId) end)
	row("age", "Account age", function()
		local d = lpl.AccountAge
		return ("%dy %dm"):format(d // 365, (d % 365) // 30)
	end)
	if type(identifyexecutor) == "function" then
		row("exec", "Executor", function()
			local okx, n = pcall(identifyexecutor)
			return okx and tostring(n) or "-"
		end)
	end
	local function refresh()
		for k, get in pairs(getters) do
			local okg, v = pcall(get)
			if okg and vals[k] and vals[k].Parent then vals[k].Text = tostring(v) end
		end
	end

	divider()

	-- ---- actions
	local brow = new("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, LayoutOrder = nextOrder(), Parent = scroll })
	local function button(text, x, cb)
		local b = new("TextButton", {
			Position = UDim2.new(x, x > 0 and 3 or 0, 0, 0), Size = UDim2.new(0.5, -3, 1, 0), BackgroundColor3 = T.Control,
			BackgroundTransparency = 0.35, Text = text, Font = T.FontBold, TextSize = 12, TextColor3 = T.Text, AutoButtonColor = false,
			BorderSizePixel = 0, Parent = brow,
		}, { corner(10), stroke(T.Accent, 1, 0.6) })
		feedback(b, b, "BackgroundTransparency", 0.35, 0.2, 0.1, true)
		b.MouseButton1Click:Connect(cb)
	end
	button("Copy join link", 0, function()
		copy(("roblox://experiences/start?placeId=%d&gameInstanceId=%s"):format(game.PlaceId, jobId))
	end)
	button("Rejoin", 0.5, function()
		win:Notify({ Title = "Rejoining", Content = "Teleporting back to this server...", Kind = "Info", Duration = 2 })
		local TS = game:GetService("TeleportService")
		pcall(function()
			if jobId ~= "" then TS:TeleportToPlaceInstance(game.PlaceId, jobId, lpl) else TS:Teleport(game.PlaceId, lpl) end
		end)
	end)

	-- ---- open / close
	local isOpen, fpsConn = false, nil
	function win:CloseProfile()
		if not isOpen then return end
		isOpen = false
		if fpsConn then fpsConn:Disconnect() fpsConn = nil end
		blocker.Visible = false
		card.Visible = false
		if self.FooterArrow then self.FooterArrow.Rotation = 0 end
	end
	function win:OpenProfile()
		if isOpen or self._destroyed or self.Compact then return end
		isOpen = true
		refresh()
		local avail = (main.AbsoluteSize.Y / math.max(self.Scale.Scale, 0.01)) - (FOOT_H + 16) - (HEADER_H + 8)
		local h = math.clamp(lay.AbsoluteContentSize.Y + 24, 140, math.max(avail, 140))
		card.Size = UDim2.fromOffset(CARD_W, h)
		scroll.CanvasPosition = Vector2.zero
		card.Position = UDim2.new(0, 12, 1, baseY + 10)
		blocker.Visible = true
		card.Visible = true
		nextFrame(function() if isOpen then tween(card, 0.22, { Position = UDim2.new(0, 12, 1, baseY) }) end end)
		if self.FooterArrow then tween(self.FooterArrow, 0.2, { Rotation = 180 }) end
		local frames, last = 0, os.clock()
		fpsConn = RunService.RenderStepped:Connect(function()
			frames += 1
			local now = os.clock()
			if now - last >= 0.5 then fps = math.floor(frames / (now - last) + 0.5) frames, last = 0, now end
		end)
		task.spawn(function()
			while isOpen and not self._destroyed do
				task.wait(0.5)
				if isOpen then refresh() end
			end
			if fpsConn then fpsConn:Disconnect() fpsConn = nil end
		end)
	end
	function win:ToggleProfile()
		if isOpen then self:CloseProfile() else self:OpenProfile() end
	end

	blocker.MouseButton1Click:Connect(function() win:CloseProfile() end)
	if win.ProfileButton then win.ProfileButton.MouseButton1Click:Connect(function() win:ToggleProfile() end) end
end


-- update the header title live. Accepts "Brand | Sub" or (brand, sub).
function Window:SetTitle(title, sub)
	if sub == nil and type(title) == "string" then
		local b, s = title:match("^(.-)%s*|%s*(.+)$")
		if b then title, sub = b, s end
	end
	if title ~= nil then
		self.Brand = title
		self.BrandLabel.Text = title
	end
	if sub ~= nil then
		self.Sub = sub
		if self.SubLabel then self.SubLabel.Text = sub end
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
	pcall(function() self._drag.Stop() end)
	pcall(function() self._openDrag.Stop() end)
	if self.FX then for _, tw in ipairs(self.FX.Tweens) do pcall(function() tw:Cancel() end) end end
	if self._sheen then pcall(function() self._sheen:Cancel() end) end
	for _, c in ipairs(self.Conns) do pcall(function() c:Disconnect() end) end
	pcall(function() self.Gui:Destroy() end)
	for i, w in ipairs(Library.Windows) do
		if w == self then table.remove(Library.Windows, i) break end
	end
end

function Window:_ApplySearch(fromSelect)
	local tab = self.Active
	if not tab then return end
	local q = self.SearchBox.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
	if self._ShowResults then self:_ShowResults(q) end
	q = ""   -- global search: the pages are never filtered, matches are listed in the results panel instead
	-- switching tabs with an empty search and nothing changed since this tab was last filtered:
	-- every control is already in the right state, so skip touching hundreds of Visible properties
	-- in the same frame the page animation starts (that was a visible hitch on big tabs)
	if fromSelect and q == "" and tab._clean then return end
	for _, t in ipairs(self.Tabs) do t._clean = false end
	for _, s in ipairs(tab.Sections) do
		local secMatch = q == "" or s.Name:lower():find(q, 1, true) ~= nil
		local any = false
		for _, c in ipairs(s.Controls) do
			local vis = (secMatch or c.Name:find(q, 1, true) ~= nil) and not c.Hidden
			if c.Frame.Visible ~= vis then c.Frame.Visible = vis end
			any = any or vis
		end
		local secVis = secMatch or any
		if s.Frame.Visible ~= secVis then s.Frame.Visible = secVis end
	end
	tab._clean = (q == "")
	tab:_QueueRelayout()
end

-- tab switch: the new page slides in (direction follows tab order) while fading up from the window color
function Window:SelectTab(tab)
	if tab and tab._locked then
		self:_LockedFeedback(tab)
		return
	end
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
	self:_ApplySearch(true)
	tab:_QueueRelayout()

	-- phones (lowPower) used to skip the whole transition, so tabs just popped; they now get the slide + fade,
	-- only the accent sweep is left out there
	if prev and Library.Anim.TabSwitch ~= false then
		local lite = lowPower()
		self._pseq = (self._pseq or 0) + 1
		local seq = self._pseq
		local pv = self.PageVeil
		-- The veil used to snap to 80% opaque in one frame and then fade out: on a translucent window that
		-- dimmed both columns at once and they "blinked". It now starts much lighter (the slide carries the motion).
		--   Library.Anim.PageVeil = false  -> no veil at all (slide only)     Library.Anim.PageVeilAlpha = 0.6 (1 = invisible)
		local useVeil = Library.Anim.PageVeil ~= false
		pv.BackgroundTransparency = useVeil and (Library.Anim.PageVeilAlpha or 0.6) or 1
		pv.Visible = useVeil
		self:_MotionBegin(0.34, true)   -- backdrop rests while the page slides; the halo stays (nothing moves it)
		tab.Page.Position = UDim2.fromOffset(0, 14 * dir)
		-- the page was just made visible and re-laid out: that frame is the heavy one, so the slide starts on the next
		nextFrame(function()
			if self._pseq ~= seq or self._destroyed then
				-- a newer switch took over: do not leave this page parked at its slide offset
				if self.Active ~= tab and tab.Page.Parent then tab.Page.Position = UDim2.new() end
				return
			end
			tween(tab.Page, 0.34, { Position = UDim2.new() }, QUINT, OUT)
			if useVeil then
				tween(pv, 0.26, { BackgroundTransparency = 1 }, SINE, OUT).Completed:Connect(function()
					if self._pseq == seq then pv.Visible = false end
				end)
			end
			if lite then return end
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
	Library._mount(gui)
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
		local cs = touch and 32 or 24   -- close button size; also used to mirror the icon on the right side
		-- rail = inset pill (equal gap top / bottom), so the rounded corners no longer slice it into a wedge
		ui.Rail = new("Frame", { Name = "Rail", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 6, 0.5, 0), Size = UDim2.new(0, 3, 1, -20),
			BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 3, Parent = card },
			{ corner(2), gradient(T.Accent, T.Accent2, 90) })
		ui.RailGrad = ui.Rail:FindFirstChildOfClass("UIGradient")
		ui.IconSlot = new("Frame", { Name = "IconSlot", Position = UDim2.fromOffset(16, 10), Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1, ZIndex = 3, Parent = card })
		local inner = new("Frame", {
			Name = "Inner", Position = UDim2.fromOffset(48, 0), Size = UDim2.new(1, -(48 + 27 + cs / 2 + 4), 0, 0), AutomaticSize = AY,
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
		ui.Track = new("Frame", { Name = "Track", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -6), Size = UDim2.new(1, -32, 0, 3),
			BackgroundColor3 = T.Accent, BackgroundTransparency = 0.86, BorderSizePixel = 0, ZIndex = 4, Visible = false, Parent = card }, { corner(2) })
		ui.Fill = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = ui.Track },
			{ corner(2), gradient(T.Accent, T.Accent2, 0) })
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
			Name = "Close", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -(27 - cs / 2), 0, 21 - cs / 2), Size = UDim2.fromOffset(cs, cs),
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
	if role ~= "loading" then playSound("Notify", cfg.Sound) end
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
	Library._fullScreen(g)
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
	local scroll = new("ScrollingFrame", { ElasticBehavior = Enum.ElasticBehavior.Never,
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
		}, { corner(14) })
		if style == "Secondary" then
			btn.BackgroundColor3 = T.Control
			new("UIStroke", { Color = T.Border, Thickness = 1, Transparency = 0.35, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = btn })
			feedback(btn, btn, "BackgroundColor3", T.Control, T.Lift, T.AccentSoft)
		else
			local c1 = style == "Danger" and Library.Kinds.Error.Color or accent
			gradient(c1, style == "Danger" and Util.Lighten(c1, 0.25) or accent2, 0).Parent = btn
			feedback(btn, btn, "BackgroundColor3", fill, Color3.fromRGB(236, 236, 236), Color3.fromRGB(200, 200, 200))
		end
		local btnLbl = new("TextLabel", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = tostring(b.Text or "OK"), Font = style == "Secondary" and T.Font or T.FontBold,
			TextSize = 14, TextColor3 = style == "Secondary" and T.SubText or (style == "Danger" and Color3.new(1, 1, 1) or Library.OnAccent(T)),
			TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 4, Parent = btn,
		}, { padding(8, 0, 8, 0) })
		if style ~= "Secondary" and style ~= "Danger" then Library._oa(btnLbl) end
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

	-- sizes: a little smaller on phones (window option TabHeight overrides the height)
	local touchTab = UserInputService.TouchEnabled
	local tabH = tonumber(self.Cfg and self.Cfg.TabHeight) or (touchTab and 38 or 36)
	local iconX, iconSz = touchTab and 24 or 26, touchTab and 22 or 24
	local lblX = touchTab and 42 or 46
	self._tabIconX = iconX

	local btn = new("TextButton", {
		LayoutOrder = #self.Tabs + 1, Size = UDim2.new(1, 0, 0, tabH),
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, AutoButtonColor = false, Text = "", ClipsDescendants = true, Parent = self.TabList,
	}, { corner(16), stroke(T.Accent, 1, 1), gradient(T.AccentSoft, T.AccentSoft, 0) })
	tab.Button = btn
	tab.BtnStroke = btn:FindFirstChildOfClass("UIStroke")
	-- stroke() lowers transparency by 0.15, so stroke(.., 1, 1) was 0.85 (a faint outline on never-selected tabs): force it fully hidden
	tab.BtnStroke.Transparency = 1
	tab.BtnGrad = btn:FindFirstChildOfClass("UIGradient")
	tab.Indicator = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0), Size = UDim2.new(0, 3, 0, 0),
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = btn,
	}, { corner(2), gradient(T.Accent, T.Accent2, 90) })

	local ic = cfg.Icon
	local function wrapIcon(el)
		return new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, iconX, 0.5, 0), Size = UDim2.fromOffset(iconSz, iconSz),
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
			Text = (not Library:IsIconName(ic) and ic) or tab.Name:sub(1, 1):upper(), Font = T.FontBold, TextSize = touchTab and 15 or 16, TextColor3 = T.SubText,
		})
	end
	tab.IconWrap = wrapIcon(tab.Icon)
	tab.IconScale = tab.IconWrap:FindFirstChild("IS")
	tab.Label = new("TextLabel", {
		Position = UDim2.fromOffset(lblX, 0), Size = UDim2.new(1, -(lblX + 6), 1, 0), BackgroundTransparency = 1, Text = tab.Name,
		Font = T.Font, TextSize = touchTab and 13 or 14, TextColor3 = T.SubText, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = btn,
	})
	-- padlock (drawn from frames, no asset): shown only while the tab is locked
	tab._locked = false
	tab.LockReason = cfg.LockReason
	tab.Cfg = cfg
	tab.LockIcon = new("Frame", {
		Name = "Lock", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1, Visible = false, ZIndex = 3, Parent = btn,
	}, {
		new("Frame", {   -- shackle
			AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.fromOffset(8, 9),
			BackgroundTransparency = 1, ZIndex = 3,
		}, { corner(4), stroke(T.SubText, 1.6, 0) }),
		new("Frame", {   -- body
			AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.fromOffset(12, 8),
			BackgroundColor3 = T.SubText, BorderSizePixel = 0, ZIndex = 4,
		}, { corner(3) }),
	})
	tab:_ApplyCompact(self.Compact or false)

	-- hover (PC) + press feedback (PC & mobile)
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
				if self.Active ~= tab then tween(btn, 0.06, { BackgroundTransparency = 0.5 }) end
	end, function(cancelled)
				if self.Active ~= tab then tween(btn, 0.16, { BackgroundTransparency = 1 }) end
	end, 12)
	clickRipple(btn, press)
	btn.MouseButton1Click:Connect(function()
		if press.moved then return end -- it was a scroll, not a tap
		self:SelectTab(tab)
	end)

	-- page
	tab.Page = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = self.Pages })
	-- each column is its own ScrollingFrame, so the left and right side scroll independently
	-- (tab.Scroll is now just the non-scrolling holder; use tab:SetScrollEnabled(bool) to lock both sides)
	tab.Scroll = new("Frame", { Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -32, 1, 0), BackgroundTransparency = 1, Parent = tab.Page },
		{ list(12, { FillDirection = Enum.FillDirection.Horizontal }) })
	tab.Cols = {}
	for i = 1, 2 do
		tab.Cols[i] = new("ScrollingFrame", {
			LayoutOrder = i, Size = UDim2.new(0.5, -6, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
			ScrollBarThickness = UserInputService.TouchEnabled and 4 or 3,
			ScrollBarImageColor3 = T.Accent, CanvasSize = UDim2.new(), AutomaticCanvasSize = AY,
			ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Never, Parent = tab.Scroll,
		}, { list(12), padding(0, 0, 0, 8) })
	end

	table.insert(self.Tabs, tab)
	if cfg.Locked then tab:SetLocked(true, cfg.LockReason) end
	if not self.Active then self:SelectTab(tab) end
	self:_IntroTab(tab)
	return tab
end

------------------------------------------------------------------ tab lock API
-- Tab:Lock(reason) / Unlock() / SetLocked(bool, reason) / IsLocked() / SetLockReason(text)
function Tab:SetLocked(v, reason)
	v = v and true or false
	if reason ~= nil then self.LockReason = reason end
	if self._locked == v then return self end
	self._locked = v
	local win = self.Window
	local T = win.Theme
	self.LockIcon.Visible = v
	local dim = v and 0.55 or 0
	tween(self.Label, 0.2, { TextTransparency = dim })
	local prop = self.Icon:IsA("ImageLabel") and "ImageTransparency" or "TextTransparency"
	tween(self.Icon, 0.2, { [prop] = dim })
	for _, part in ipairs(self.Icon:GetChildren()) do
		if part:IsA("ImageLabel") then tween(part, 0.2, { ImageTransparency = dim }) end
	end
	self.Label.Size = v and UDim2.new(1, -74, 1, 0) or UDim2.new(1, -52, 1, 0)
	if v and win.Active == self then
		-- never leave a locked page open: move to the first tab that is not locked
		for _, t in ipairs(win.Tabs) do
			if t ~= self and not t._locked then win:SelectTab(t) break end
		end
	elseif not v and not win.Active then
		win:SelectTab(self)
	end
	return self
end
function Tab:Lock(reason) return self:SetLocked(true, reason) end
function Tab:Unlock() return self:SetLocked(false) end
function Tab:IsLocked() return self._locked == true end
function Tab:SetLockReason(text) self.LockReason = text return self end

-- shown when someone tries to open a locked tab (click / SetTab / command palette)
function Window:_LockedFeedback(tab)
	local now = os.clock()
	if tab.LockIcon then
		task.spawn(function()
			for _, r in ipairs({ -18, 16, -10, 6, 0 }) do
				if not tab.LockIcon.Parent then return end
				tween(tab.LockIcon, 0.055, { Rotation = r })
				task.wait(0.055)
			end
		end)
	end
	safe(tab.Cfg and tab.Cfg.OnLockedClick, tab)
	if tab.Cfg and tab.Cfg.LockedNotify == false then return end
	if (tab._lockToast or 0) + 1.5 > now then return end
	tab._lockToast = now
	pcall(function()
		self:Warning(tab.Name .. " is locked", tab.LockReason or "This tab is locked.", 2.5)
	end)
end

local function findTab(win, nameOrTab)
	return type(nameOrTab) == "string" and win:GetTab(nameOrTab) or nameOrTab
end
function Window:LockTab(nameOrTab, reason)
	local t = findTab(self, nameOrTab)
	if t then t:SetLocked(true, reason) end
	return t
end
function Window:UnlockTab(nameOrTab)
	local t = findTab(self, nameOrTab)
	if t then t:SetLocked(false) end
	return t
end
function Window:IsTabLocked(nameOrTab)
	local t = findTab(self, nameOrTab)
	return t ~= nil and t._locked == true
end

function Tab:_ApplyCompact(c)
	self.Label.Visible = not c
	if self.LockIcon then
		self.LockIcon.Position = c and UDim2.new(1, -4, 0, 12) or UDim2.new(1, -12, 0.5, 0)
	end
	-- the icon now lives inside a wrapper (which carries the select pop), so move the wrapper
	self.IconWrap.Position = c and UDim2.fromScale(0.5, 0.5) or UDim2.new(0, self.Window._tabIconX or 26, 0.5, 0)
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
	if sel and self.IconScale then
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

function Tab:SetScrollEnabled(v)
	for _, c in ipairs(self.Cols) do c.ScrollingEnabled = v and true or false end
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
	-- only write what actually changed: re-writing the same Visible / Size / Parent every tab switch made the columns redraw
	if c2.Visible ~= (two and true or false) then c2.Visible = two and true or false end
	local want1 = two and UDim2.new(0.5, -6, 1, 0) or UDim2.new(1, 0, 1, 0)
	if c1.Size ~= want1 then c1.Size = want1 end
	local h1, h2 = 0, 0
	for i, s in ipairs(self.Sections) do
		local col
		if not two then col = 1
		elseif s.Column then col = s.Column
		else col = (h1 <= h2) and 1 or 2 end
		if s.Frame.LayoutOrder ~= i then s.Frame.LayoutOrder = i end
		local target = (col == 1) and c1 or c2
		if s.Frame.Parent ~= target then s.Frame.Parent = target end
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
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundColor3 = T.Card, BackgroundTransparency = (function(b) return b + (1 - b) * (self.Window.Glass or 0) end)(self.Window.FXOn and 0.2 or 0.12),
		BorderSizePixel = 0, Parent = self.Cols[1],
	}, { corner(18), stroke(T.Border, 1, 0.55), list(0, { HorizontalAlignment = Enum.HorizontalAlignment.Center }),
		wash(cseq({ 0, T.Top }, { 1, T.Card }), 90) })

	local collapsible = cfg.Collapsible ~= false
	local head = new("TextButton", {
		LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = T.Control, BackgroundTransparency = 1,
		Text = "", AutoButtonColor = false, Parent = s.Frame,
	}, { corner(16) })
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
		BackgroundTransparency = 1, Text = "▼", Font = T.FontBold, TextSize = 12, TextColor3 = T.Accent,
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

	-- keep the natural body height up to date while it is expanded, so a later expand tweens to the
	-- CURRENT height (a stale value made the section snap at the end of the animation)
	s.Body:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if s.Body.AutomaticSize == AY and s.Body.Visible then
			local h = s.Body.AbsoluteSize.Y / math.max(s.Window.Scale.Scale, 0.01)
			if h > 0 then s._bodyH = h end
		end
	end)

	-- smooth collapse / expand: the body's height is tweened, then auto-size takes over again.
	-- Every run starts from the height the body has RIGHT NOW (so clicking again mid-animation reverses
	-- smoothly instead of jumping), and the natural height (_bodyH) is only ever read while the body is
	-- auto-sized, never from a half-way value (that used to make the next expand end short and then snap).
	function s:SetCollapsed(c, instant)
		c = c and true or false
		local cur = self.Collapsed and true or false
		self.Collapsed = c
		tween(arrow, 0.22, { Rotation = c and -90 or 0 })
		local b = self.Body
		if c == cur then
			b.Visible = not c
			return
		end
		self._cseq = (self._cseq or 0) + 1
		local seq = self._cseq
		local scale = math.max(self.Window.Scale.Scale, 0.01)
		local running = b.AutomaticSize == ANONE                    -- an earlier collapse / expand is still in flight
		local curH = b.Visible and (b.AbsoluteSize.Y / scale) or 0  -- height on screen right now
		if not running and curH > 0 then self._bodyH = curH end     -- auto-sized: this IS the natural height
		local full = self._bodyH

		local function settle()
			b.ClipsDescendants = false
			b.AutomaticSize = AY
			b.Size = UDim2.new(1, 0, 0, 0)
		end

		if c then
			if instant or curH <= 0 then
				b.Visible = false
				settle()
				return
			end
			self.Window:_MotionBegin(0.3, true)
			b.ClipsDescendants = true
			b.AutomaticSize = ANONE
			b.Size = UDim2.new(1, 0, 0, curH)
			tween(b, 0.24, { Size = UDim2.new(1, 0, 0, 0) }, QUINT, OUT).Completed:Connect(function()
				if self._cseq ~= seq then return end
				b.Visible = false
				settle()
			end)
		else
			b.Visible = true
			if instant or not full or full <= 0 then
				settle()
				return
			end
			self.Window:_MotionBegin(0.34, true)
			b.ClipsDescendants = true
			b.AutomaticSize = ANONE
			b.Size = UDim2.new(1, 0, 0, curH)
			-- the body just became visible (its controls render for the first time): tween from the next frame
			nextFrame(function()
				if self._cseq ~= seq then return end
				tween(b, 0.28, { Size = UDim2.new(1, 0, 0, full) }, QUINT, OUT).Completed:Connect(function()
					if self._cseq ~= seq then return end
					settle()
				end)
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
	-- text colour that stays readable on the gradient (and follows the theme when the gradient is the theme accent)
	local gradText = cfg.TextColor or (grad and Library.OnAccent(grad[1], grad[2] or grad[1])) or nil
	local gradTracks = grad and not cfg.TextColor and grad[1] == T.Accent
	local b = new("TextButton", {
		Size = UDim2.new(1, 0, 0, rowH()), BackgroundColor3 = grad and Color3.new(1, 1, 1) or (accent or T.Control),
		BackgroundTransparency = 0.1, AutoButtonColor = false,
		Text = cfg.Name or "Button", Font = cfg.Bold and T.FontBold or T.Font, TextSize = 13,
		TextColor3 = cfg.TextColor or (accent and Library.OnAccent(accent)) or T.Text, TextTruncate = Enum.TextTruncate.AtEnd, ClipsDescendants = true, Parent = self.Body,
	}, { corner(14), stroke(grad and (grad[2] or T.Accent2) or (accent and accent:Lerp(Color3.new(1, 1, 1), 0.3) or T.Border), 1, grad and 0.5 or 0.35) })
	if grad then
		-- gradient needs the frame background visible (transparency stays low, not 1)
		b.BackgroundColor3 = Color3.new(1, 1, 1)
		b.BackgroundTransparency = 0
		new("UIGradient", { Color = ColorSequence.new(grad[1], grad[2] or grad[1]), Parent = b })
		-- UIGradient tints the parent's own text too, so draw the text on a child label instead
		b.Text = ""
		gradLabel = new("TextLabel", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = cfg.Name or "Button",
			Font = cfg.Bold and T.FontBold or T.Font, TextSize = 13, TextColor3 = gradText, TextTruncate = Enum.TextTruncate.AtEnd, Parent = b,
		})
		if gradTracks then Library._oa(gradLabel) end
	end
	local bIcon = Library:IsIconName(cfg.Icon) and Library:ResolveIcon(cfg.Icon) or nil
	if bIcon then
		local im = Library:MakeIcon(bIcon, gradText or (accent and Library.OnAccent(accent)) or T.Text)
		if gradTracks then Library._oa(im) end
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
	-- press animation: the button spins one full turn when pressed (it shrinks a little while turning, so it never
	-- covers the buttons next to it) + a click sound.  Works on PC and mobile.
	--   cfg.Spin = false  turns the spin off      cfg.SpinTime = 0.5  seconds      cfg.Turns = 1  (2 = double, -1 = other way)
	--   cfg.Sound = false | id                    cfg.Feedback = "Saved"  also shows a toast
	local spinOn = cfg.Spin ~= false
	local spinScale = new("UIScale", { Scale = 1, Parent = b })
	local spinSeq = 0
	local function spin()
		spinSeq = spinSeq + 1
		local seq = spinSeq
		local dur = tonumber(cfg.SpinTime) or 0.5
		local turns = tonumber(cfg.Turns) or 1
		b.Rotation = 0   -- clicked again while spinning: start over
		tween(b, dur, { Rotation = 360 * turns }, QUINT, OUT)
		tween(spinScale, dur * 0.35, { Scale = 0.82 }, SINE, OUT)
		task.delay(dur * 0.35, function()
			if seq == spinSeq and spinScale.Parent then tween(spinScale, dur * 0.65, { Scale = 1 }, BACK, OUT) end
		end)
		task.delay(dur * (Library.Anim.Speed or 1) + 0.1, function()
			if seq == spinSeq and b.Parent then
				b.Rotation = 0   -- a full turn looks identical to 0, reset so it never drifts
				spinScale.Scale = 1
			end
		end)
	end

	b.MouseButton1Click:Connect(function()
		playSound("Click", cfg.Sound)
		if spinOn then pcall(spin) end
		if type(cfg.Feedback) == "string" then
			pcall(function() self.Window:Toast(cfg.Feedback, "Success") end)
		end
		safe(cfg.Callback)
	end)
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
	}, { corner(13) })
	feedback(row, row, "BackgroundTransparency", 1, 0.82, 0.62, true)
	new("TextLabel", {
		Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -62, 1, 0), BackgroundTransparency = 1, Text = cfg.Name or "Toggle",
		Font = T.Font, TextSize = 14, TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
	})
	local track = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(42, 22),
		BackgroundColor3 = value and T.Accent or T.Control, BorderSizePixel = 0, Parent = row,
	}, { corner(11), stroke(T.Border, 1, 0.6) })
	-- gradient fill lives on its own frame so its fade can be tweened (UIGradient.Transparency snaps instantly)
	local trackFill = new("Frame", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = value and 0 or 1,
		BorderSizePixel = 0, ZIndex = 1, Parent = track,
	}, { corner(11), gradient(T.Accent, T.Accent2, 0) })
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = value and ON_POS or OFF_POS, ZIndex = 2,
		Size = UDim2.fromOffset(16, 16), BackgroundColor3 = T.Knob, BorderSizePixel = 0, Parent = track,
	}, { corner(8), stroke(T.Accent, 1.5, 0.4) })
	local knobStroke = knob:FindFirstChildOfClass("UIStroke")

	local obj = {}
	function obj:Set(v, silent)
		value = v and true or false
		tween(track, 0.22, { BackgroundColor3 = value and T.Accent or T.Control })
		tween(trackFill, 0.22, { BackgroundTransparency = value and 0 or 1 })
		tween(knob, 0.24, { Position = value and ON_POS or OFF_POS })
		tween(knobStroke, 0.22, { Transparency = value and 0 or 0.5 })
		setFlag(cfg, value)
		if not silent then safe(cfg.Callback, value) end
	end
	function obj:Get() return value end
	row.MouseButton1Click:Connect(function() playSound("Toggle", cfg.Sound) obj:Set(not value) end)
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
		Text = tostring(value) .. suffix, Font = T.FontBold, TextSize = 13, TextColor3 = T.Accent, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
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

	local function release()
		tab:SetScrollEnabled(true)
		tween(knob, 0.16, { Size = UDim2.fromOffset(knobS, knobS) })
	end
	hit.InputBegan:Connect(function(i)
		if not isPress(i) then return end
		-- starts this drag and releases any other slider that was still following an input
		Library._drag(i, function(m) fromX(m.Position.X) end, release)
		tab:SetScrollEnabled(false) -- the page must not scroll while a slider is held
		tween(knob, 0.12, { Size = UDim2.fromOffset(knobBig, knobBig) })
		fromX(i.Position.X)
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

	-- ---- image support. Options may be { "a", "b" } or { { Name = "a", Image = 123 }, ... };
	-- cfg.Images = { a = 123 } works too.  The value of an option is always its Name.
	local images = {}
	local function normalize(list)
		images = {}
		local out = {}
		for i, o in ipairs(list or {}) do
			if type(o) == "table" then
				local name = o.Name or o.Text or o.Value or ("Option " .. i)
				out[i] = name
				local im = o.Image or o.Icon
				if im ~= nil then images[name] = im end
			else
				out[i] = o
			end
		end
		if type(cfg.Images) == "table" then
			for k, v in pairs(cfg.Images) do images[k] = v end
		end
		return out
	end
	local function calcOptH()
		local base = touch and 38 or 30
		if next(images) ~= nil then base = math.max(touch and 46 or 38, (cfg.ImageSize or 0) + 10) end
		optH = base
	end
	local function makeThumb(ref, sz)
		local f = new("Frame", {
			Size = UDim2.fromOffset(sz, sz), BackgroundColor3 = T.Control, BackgroundTransparency = 0.25,
			BorderSizePixel = 0, ClipsDescendants = true,
		}, { corner(math.max(6, math.floor(sz / 4))), stroke(T.Border, 1, 0.5) })
		local sref = (typeof(ref) ~= "Color3") and tostring(ref) or ""
		if typeof(ref) == "Color3" then
			f.BackgroundColor3, f.BackgroundTransparency = ref, 0
		elseif type(ref) == "number" or sref:match("^%d+$") then
			new("ImageLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Crop,
				Image = "rbxassetid://" .. sref, Parent = f })
		elseif Library:IsIconName(sref) then
			local d = Library:ResolveIcon(sref)
			if d then
				local ic = Library:MakeIcon(d, T.Accent)
				ic.Size = UDim2.fromScale(0.62, 0.62)
				ic.Parent = f
			end
		else
			new("ImageLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Crop,
				Image = sref, Parent = f })
		end
		return f
	end
	options = normalize(options)
	calcOptH()

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
	}, { corner(14), stroke(T.Border, 1, 0.35) })
	local btnStroke = btn:FindFirstChildOfClass("UIStroke")
	feedback(btn, btn, "BackgroundColor3", T.Control, T.Lift, T.AccentSoft)
	local txt = new("TextLabel", {
		Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -32, 1, 0), BackgroundTransparency = 1, Text = placeholder,
		Font = T.Font, TextSize = 13, TextColor3 = T.SubText, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = btn,
	})
	local thumbSz = math.max(16, h - 12)
	local thumbs = new("Frame", {
		Name = "Thumbs", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0.5, 0),
		Size = UDim2.fromOffset(0, thumbSz), BackgroundTransparency = 1, Parent = btn,
	})
	local badge = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -28, 0.5, 0), Size = UDim2.fromOffset(22, 18),
		BackgroundColor3 = T.AccentSoft, BorderSizePixel = 0, Visible = false, Parent = btn,
	}, { corner(9), gradient(T.Accent, T.Accent2, 0) })
	local badgeLbl = Library._oa(new("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "0", Font = T.FontBold, TextSize = 13,
		TextColor3 = Library.OnAccent(T), Parent = badge,
	}))
	local arrow = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(18, 18),
		BackgroundTransparency = 1, Text = "▶", Font = T.FontBold, TextSize = 12, TextColor3 = T.Accent, Parent = btn,
	})

	local dd = { IsOpen = false }
	local ddTok = 0   -- bumped on every open / close so a late animation callback can never act on a newer state
	local popup, popupStroke, scroll, searchHolder, searchBox, emptyLbl
	local rows = {}
	local popW, maxH = 190, 240
	local escC

	local function refreshText()
		local list = multi and selectedList() or (value ~= nil and { value } or {})
		-- thumbnails of the current selection (max 3, overlapped)
		for _, c in ipairs(thumbs:GetChildren()) do c:Destroy() end
		local n, step = 0, math.floor(thumbSz * 0.6)
		for _, o in ipairs(list) do
			if images[o] ~= nil and n < 3 then
				local t = makeThumb(images[o], thumbSz)
				t.Position = UDim2.fromOffset(n * step, 0)
				t.Parent = thumbs
				n = n + 1
			end
		end
		local off = n > 0 and (thumbSz + (n - 1) * step + 8) or 0
		thumbs.Size = UDim2.fromOffset(math.max(off - 8, 0), thumbSz)
		local rightPad = -32
		if multi then
			local out = list
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
			rightPad = showBadge and -62 or -32
		else
			txt.Text = value ~= nil and tostring(value) or placeholder
			txt.TextColor3 = value ~= nil and T.Text or T.SubText
		end
		txt.Position = UDim2.fromOffset(10 + off, 0)
		txt.Size = UDim2.new(1, rightPad - off, 1, 0)
	end

	local function paint()
		local live = popup and popup.Visible
		local function put(inst, t, props, animate)
			if animate then tween(inst, t, props)
			else for k, v in pairs(props) do inst[k] = v end end
		end
		for opt, r in pairs(rows) do
			local sel = isSel(opt)
			-- rows that are hidden (filtered out) or inside a closed popup are set directly, not tweened
			local an = live and r.btn.Visible
			put(r.btn, 0.16, { BackgroundTransparency = sel and 0 or 1 }, an)
			put(r.bar, 0.16, { BackgroundTransparency = sel and 0 or 1 }, an)
			put(r.label, 0.16, { TextColor3 = sel and selText or T.Text }, an)
			put(r.check, 0.16, { TextTransparency = sel and 0 or 1 }, an)
			if multi then
				put(r.box, 0.16, { BackgroundColor3 = sel and T.Accent or T.Control }, an)
				put(r.boxStroke, 0.16, { Color = sel and T.Accent or T.Border }, an)
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
			local lblX = 12
			if images[opt] ~= nil then
				local isz = math.min(cfg.ImageSize or (optH - 10), optH - 6)
				local th = makeThumb(images[opt], isz)
				th.AnchorPoint = Vector2.new(0, 0.5)
				th.Position = UDim2.new(0, 12, 0.5, 0)
				th.Parent = b
				lblX = 12 + isz + 8
			end
			local lbl = new("TextLabel", {
				Position = UDim2.fromOffset(lblX, 0), Size = UDim2.new(1, -(lblX + 32), 1, 0), BackgroundTransparency = 1, Text = tostring(opt),
				Font = T.Font, TextSize = 13, TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = b,
			})
			local r = { btn = b, bar = bar, label = lbl }
			if multi then
				r.box = new("Frame", {
					AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(18, 18),
					BackgroundColor3 = T.Control, BorderSizePixel = 0, Parent = b,
				}, { corner(5), stroke(T.Border, 1, 0) })
				r.boxStroke = r.box:FindFirstChildOfClass("UIStroke")
				r.check = Library._oa(new("TextLabel", {
					Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "✓", Font = T.FontBold, TextSize = 13,
					TextColor3 = Library.OnAccent(T.Accent), TextTransparency = 1, Parent = r.box,
				}))
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
			local press = dragSafePress(b, function()
				if not isSel(opt) then tween(b, 0.05, { BackgroundTransparency = 0.35 }) end
			end, function()
				if not isSel(opt) then tween(b, 0.16, { BackgroundTransparency = 1 }) end
			end, 10)
			b.MouseButton1Click:Connect(function()
				-- a finger that turned into a scroll must not pick the row, and a double tap must not fire twice
				if press.moved or not dd.IsOpen then return end
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

		scroll = new("ScrollingFrame", { ElasticBehavior = Enum.ElasticBehavior.Never,
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
			-- footer: [Select All] [Clear] [Done]   (cfg.SelectAll = false removes the Select All button)
			local withAll = cfg.SelectAll ~= false
			local selAll
			if withAll then
				selAll = new("TextButton", {
					Size = UDim2.new(0.34, -4, 1, 0), BackgroundColor3 = T.Control, BackgroundTransparency = 0.1, AutoButtonColor = false, Text = cfg.SelectAllText or "Select All",
					Font = T.FontBold, TextSize = 13, TextColor3 = T.Accent, TextTruncate = Enum.TextTruncate.AtEnd, Parent = footer,
				}, { corner(14), stroke(T.Accent, 1, 0.5) })
				feedback(selAll, selAll, "BackgroundColor3", T.Control, T.Lift, T.AccentSoft)
				strokeFeedback(selAll, selAll:FindFirstChildOfClass("UIStroke"), 0.5, 0.15)
			end
			local clear = new("TextButton", {
				Position = withAll and UDim2.new(0.34, 2, 0, 0) or UDim2.new(),
				Size = withAll and UDim2.new(0.26, -4, 1, 0) or UDim2.new(0.38, -3, 1, 0),
				BackgroundColor3 = T.Control, BackgroundTransparency = 0.1, AutoButtonColor = false, Text = "Clear",
				Font = T.Font, TextSize = 13, TextColor3 = T.Text, Parent = footer,
			}, { corner(14), stroke(T.Border, 1, 0.35) })
			feedback(clear, clear, "BackgroundColor3", T.Control, T.Lift, T.AccentSoft)
			strokeFeedback(clear, clear:FindFirstChildOfClass("UIStroke"), 0.35, 0.05)
			local done = new("TextButton", {
				Position = withAll and UDim2.new(0.60, 2, 0, 0) or UDim2.new(0.38, 3, 0, 0),
				Size = withAll and UDim2.new(0.40, -2, 1, 0) or UDim2.new(0.62, -3, 1, 0),
				BackgroundColor3 = Color3.new(1, 1, 1), AutoButtonColor = false, Text = "", Parent = footer,
			}, { corner(14), gradient(T.Accent, T.Accent2, 0), stroke(T.Accent2, 1, 0.5) })
			-- UIGradient tints the parent's own text too (it made "Done" vanish), so the label is a separate child
			Library._oa(new("TextLabel", {
				Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "Done", Font = T.FontBold, TextSize = 13,
				TextColor3 = Library.OnAccent(T), ZIndex = 2, Parent = done,
			}))
			if selAll then
				-- selects every option that is currently visible (so it respects the search box), keeps what was already picked
				selAll.MouseButton1Click:Connect(function()
					local cur, have = selectedList(), {}
					for _, o in ipairs(cur) do have[o] = true end
					for _, o in ipairs(options) do
						local r = rows[o]
						if not have[o] and (not r or r.btn.Visible) then table.insert(cur, o) end
					end
					dd:Set(cur)
				end)
			end
			strokeFeedback(done, done:FindFirstChildOfClass("UIStroke"), 0.5, 0.05)
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
		ddTok += 1
		local my = ddTok
		if (win._textScale or Library.TextScale or 1) ~= 1 then win:_ApplyTextScale(popup) end
		applyChrome()
		searchBox.Text = ""
		for _, r in pairs(rows) do r.btn.Visible = true end
		emptyLbl.Visible = #options == 0

		local top, bot = chrome()
		local pos, size = btn.AbsolutePosition, btn.AbsoluteSize
		local bmin, bmax = Library._visibleRect(win.Gui)
		local vp = bmax - bmin
		local cap = touch and 280 or 240
		local minH = top + bot + optH + PAD
		local want = math.min(top + bot + math.max(#options, 1) * (optH + GAP) + PAD, cap)
		local below = bmax.Y - (pos.Y + size.Y + 4) - 8
		local above = pos.Y - 4 - 8 - bmin.Y
		local down = want <= below or below >= above
		maxH = math.max(math.min(cap, down and below or above), math.min(minH, vp.Y - 16))
		popW = math.min(math.max(size.X, 190), vp.X - 12)
		local x = math.clamp(pos.X, bmin.X + 6, math.max(bmin.X + 6, bmax.X - popW - 6))

		if not popup.Visible then
			popup.Size = UDim2.fromOffset(popW, 0)
			popup.BackgroundTransparency = 1
			popupStroke.Transparency = 1
		end
		popup.AnchorPoint = Vector2.new(0, down and 0 or 1)
		local wantY = down and (pos.Y + size.Y + 4) or (pos.Y - 4)
		popup.Position = UDim2.fromOffset(x, wantY)
		popup.Visible = true
		Library._pinPopup(popup, x, wantY)
		nextFrame(function() if self.IsOpen and ddTok == my then Library._pinPopup(popup, x, wantY) end end)
		win:_ShowOverlay(0.62)
		tab:SetScrollEnabled(false) -- the page behind must not move while the popup is open
		self.IsOpen = true
		win._dd = self

		tween(arrow, 0.2, { Rotation = 90 })
		tween(btnStroke, 0.2, { Color = T.Accent, Transparency = 0.2 })

		escC = UserInputService.InputBegan:Connect(function(i)
			if i.KeyCode == Enum.KeyCode.Escape then dd:Close() end
		end)

		-- The frame that makes the popup visible is the heavy one (every row is laid out), so the grow / fade
		-- starts one frame later - otherwise its first frames are skipped and the opening stutters.
		-- The selected row is scrolled into view before the animation, so nothing jumps while it plays.
		nextFrame(function()
			if ddTok ~= my or not self.IsOpen then return end
			local idx
			for n, o in ipairs(options) do
				if isSel(o) then idx = n break end
			end
			scroll.CanvasPosition = Vector2.new(0, idx and math.max(0, (idx - 2) * (optH + GAP)) or 0)
			fit()
			tween(popup, 0.2, { BackgroundTransparency = 0 })
			tween(popupStroke, 0.2, { Transparency = 0.35 })
			-- PC: start typing straight away (not on touch, the keyboard would cover the list)
			if not touch and searchOn() then searchBox:CaptureFocus() end
		end)
	end

	function dd:Close()
		if not self.IsOpen then return end
		self.IsOpen = false
		ddTok += 1
		local my = ddTok
		if win._dd == self then win._dd = nil end
		if escC then escC:Disconnect() escC = nil end
		if searchBox then searchBox:ReleaseFocus() end
		win:_HideOverlay()
		tab:SetScrollEnabled(true)
		tween(arrow, 0.18, { Rotation = 0 })
		tween(btnStroke, 0.18, { Color = T.Border, Transparency = 0.35 })
		if popup then
			tween(popupStroke, 0.14, { Transparency = 1 }, QUAD, IN)
			tween(popup, 0.14, { Size = UDim2.fromOffset(popW, 0), BackgroundTransparency = 1 }, QUAD, IN).Completed:Connect(function()
				-- only the newest close may hide the popup (a cancelled older tween also fires Completed)
				if ddTok == my and not self.IsOpen then popup.Visible = false end
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
	function dd:Refresh(newOptions, keep, extraImages)
		options = normalize(newOptions or {})
		if type(extraImages) == "table" then
			for k, v in pairs(extraImages) do images[k] = v end
		end
		calcOptH()
		if not keep then
			self:Set(nil, true)
		elseif multi then
			self:Set(selectedList(), true) -- drop selections that no longer exist
		end
		refreshText()
		if popup then
			buildOptions()
			applyChrome()
			if self.IsOpen then
				searchBox.Text = ""
				fit()
			end
		end
	end

	-- dd:SetImage("Sword", 123456)  (nil removes it)
	function dd:SetImage(opt, image)
		images[opt] = image
		calcOptH()
		refreshText()
		if popup then
			buildOptions()
			applyChrome()
			if self.IsOpen then fit() end
		end
	end

	local lastToggle = 0
	btn.MouseButton1Click:Connect(function()
		local now = os.clock()
		if now - lastToggle < 0.12 then return end   -- ignore a bounce / double tap
		lastToggle = now
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
	}, { corner(14), stroke(T.Border, 1, 0.35) })
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
	}, { corner(12), stroke(T.Border, 1, 0.35), padding(4, 0, 4, 0) })
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
	}, { corner(10), stroke(T.Border, 1, 0.2) })
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
		if (win._textScale or Library.TextScale or 1) ~= 1 then win:_ApplyTextScale(popup) end
		local pos, size = swatch.AbsolutePosition, swatch.AbsoluteSize
		local bmin, bmax = Library._visibleRect(win.Gui)
		local vp = bmax - bmin
		local ph = 172
		local pw = math.min(220, vp.X - 12)
		local below = bmax.Y - (pos.Y + size.Y + 3) - 6
		local above = pos.Y - 3 - 6 - bmin.Y
		local down = ph <= below or below >= above
		ph = math.max(math.min(ph, down and below or above), 60)
		local x = math.clamp(pos.X + size.X - pw, bmin.X + 6, math.max(bmin.X + 6, bmax.X - pw - 6))

		if not popup.Visible then
			popup.Size = UDim2.fromOffset(pw, 0)
			popup.BackgroundTransparency = 1
			popupStroke.Transparency = 1
		end
		popup.AnchorPoint = Vector2.new(0, down and 0 or 1)
		local wantY = down and (pos.Y + size.Y + 3) or (pos.Y - 3)
		popup.Position = UDim2.fromOffset(x, wantY)
		popup.Visible = true
		Library._pinPopup(popup, x, wantY)
		self._tok = (self._tok or 0) + 1
		win:_ShowOverlay()
		tab:SetScrollEnabled(false)
		tween(popup, 0.22, { Size = UDim2.fromOffset(pw, ph), BackgroundTransparency = 0 })
		tween(popupStroke, 0.22, { Transparency = 0.45 })
		self.IsOpen = true
		win._dd = self
	end

	function obj:Close()
		if not self.IsOpen then return end
		self.IsOpen = false
		if win._dd == self then win._dd = nil end
		win:_HideOverlay()
		tab:SetScrollEnabled(true)
		self._tok = (self._tok or 0) + 1
		local my = self._tok
		if popup then
			tween(popupStroke, 0.16, { Transparency = 1 }, QUAD, IN)
			tween(popup, 0.16, { Size = UDim2.fromOffset(popup.AbsoluteSize.X, 0), BackgroundTransparency = 1 }, QUAD, IN).Completed:Connect(function()
				if self._tok == my and not self.IsOpen then popup.Visible = false end
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
		Font = T.FontBold, TextSize = 13, TextColor3 = Color3.new(1, 1, 1), TextTruncate = Enum.TextTruncate.AtEnd, Parent = pill,
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
		Text = tostring(value) .. suffix, Font = T.FontBold, TextSize = 13, TextColor3 = T.Accent, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
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
		BackgroundTransparency = 1, Text = cfg.Name or "", Font = T.FontBold, TextSize = 13, TextColor3 = T.SubText, Parent = row,
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
	}, { corner(13) })
	feedback(row, row, "BackgroundTransparency", 1, 0.82, 0.62, true)
	new("TextLabel", {
		Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -140, 1, 0), BackgroundTransparency = 1, Text = cfg.Name or "Toggle Key",
		Font = T.Font, TextSize = 14, TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
	})
	-- clickable key chip
	local keyBtn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -54, 0.5, 0), Size = UDim2.fromOffset(46, math.min(h - 8, 22)),
		BackgroundColor3 = T.Control, BackgroundTransparency = 0.1, AutoButtonColor = false, Text = "", Font = T.FontBold, TextSize = 13,
		TextColor3 = T.Accent, Parent = row,
	}, { corner(11), stroke(T.Border, 1, 0.35) })
	local keyStroke = keyBtn:FindFirstChildOfClass("UIStroke")
	local track = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(38, 20),
		BackgroundColor3 = value and T.Accent or T.Control, BorderSizePixel = 0, Parent = row,
	}, { corner(10) })
	local trackFill = new("Frame", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = value and 0 or 1,
		BorderSizePixel = 0, ZIndex = 1, Parent = track,
	}, { corner(10), gradient(T.Accent, T.Accent2, 0) })
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = value and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0), ZIndex = 2,
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
		tween(trackFill, 0.22, { BackgroundTransparency = value and 0 or 1 })
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
		-- a long tip wraps at a maximum width instead of becoming one line wider than the screen
		local cap = math.max(120, math.min(280, self.Gui.AbsoluteSize.X - 32))
		new("UISizeConstraint", { MaxSize = Vector2.new(cap, math.huge), Parent = measure })
		new("UISizeConstraint", { MaxSize = Vector2.new(cap, math.huge), Parent = l })
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
		self.BadgeLabel = Library._oa(new("TextLabel", {
			Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AX, BackgroundTransparency = 1, Text = "", Font = T.FontBold, TextSize = 12,
			TextColor3 = Library.OnAccent(T), Parent = self.Badge,
		}))
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
	local okf, exists = pcall(isfile, path)
	if not okf or not exists then return false, "config not found" end
	local okr, body = pcall(readfile, path)
	if not okr or type(body) ~= "string" then return false, "could not read config" end
	return self:ImportConfig(body, silent)
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
	if type(listfiles) ~= "function" or type(isfolder) ~= "function" then return out end
	local okd, isdir = pcall(isfolder, self.ConfigFolder)
	if not okd or not isdir then return out end
	local okl, files = pcall(listfiles, self.ConfigFolder)
	if not okl or type(files) ~= "table" then return out end
	for _, f in ipairs(files) do
		local n = tostring(f):match("([^/\\]+)%.json$")
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
				TextColor3 = dis and T.SubText or (it.Color or T.Text), TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = menu,
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
		local sc = e.Frame:FindFirstAncestorWhichIsA("ScrollingFrame") or e.Tab.Cols[1]
		local y = e.Frame.AbsolutePosition.Y - sc.AbsolutePosition.Y + sc.CanvasPosition.Y - 28
		tween(sc, 0.3, { CanvasPosition = Vector2.new(0, math.max(0, y)) })
		local hl = new("Frame", {
			Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Accent, BackgroundTransparency = 0.5, BorderSizePixel = 0,
			ZIndex = 8, Parent = e.Frame,
		}, { corner(7) })
		tween(hl, 1.1, { BackgroundTransparency = 1 }, QUAD, OUT).Completed:Connect(function() hl:Destroy() end)
	end)
end

Library._reveal = reveal

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
	-- Anchor the palette to the WINDOW, not to the top of the ScreenGui: on some clients the gui origin sits above / left of
	-- the visible screen, so a fixed "56 px from the top" put the palette half off-screen (and over the window header).
	-- Everything is converted into the gui's own space (abs - gui origin), so it is right whatever the inset is.
	local cx = nil
	do
		local main = self.Main
		if main and main.Visible and main.AbsoluteSize.X > 0 and self.Visible ~= false then
			local o = gui.AbsolutePosition
			local mp, ms = main.AbsolutePosition - o, main.AbsoluteSize
			local gap = (ms.Y < 360) and 8 or 56
			top = mp.Y + gap
			cx = mp.X + ms.X / 2
			W = math.min(420, ms.X - 20)
			H = math.clamp(ms.Y - gap - 16, 150, 400)
		end
	end
	local cardX = cx and UDim2.fromOffset(cx, 0) or UDim2.fromScale(0.5, 0)

	local overlay = new("TextButton", {
		Name = "SpectrePalette", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
		Text = "", AutoButtonColor = false, ZIndex = 150, Parent = gui,
	})
	local card = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(cardX.X.Scale, cardX.X.Offset, 0, top - 10), Size = UDim2.fromOffset(W, H),
		BackgroundColor3 = T.Panel, BackgroundTransparency = 1, BorderSizePixel = 0, Active = true, Parent = overlay,
	}, { corner(12), stroke(T.Accent, 1, 0.35), wash(cseq({ 0, T.Top }, { 1, T.Panel }), 90) })
	local box = new("TextBox", {
		Position = UDim2.fromOffset(12, 10), Size = UDim2.new(1, -24, 0, 36), BackgroundColor3 = T.Control, BackgroundTransparency = 0.1,
		BorderSizePixel = 0, Text = initial or "", PlaceholderText = "Search settings or run a command   (try: speed = 50)",
		PlaceholderColor3 = T.SubText, TextColor3 = T.Text, Font = T.Font, TextSize = 14, TextXAlignment = LEFT,
		ClearTextOnFocus = false, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card,
	}, { corner(8), stroke(T.Border, 1, 0.35), padding(10, 0, 10, 0) })
	local scroll = new("ScrollingFrame", { ElasticBehavior = Enum.ElasticBehavior.Never,
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
			Font = T.Font, TextSize = 13, TextColor3 = T.SubText, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = btn,
		})
		local chip = new("TextLabel", {
			Name = "Chip", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(80, 20),
			BackgroundColor3 = T.AccentSoft, BorderSizePixel = 0, Text = it.chip or "", Font = T.FontBold, TextSize = 13,
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
	do
		local okR, errR = pcall(refresh)
		if not okR then warn("[SpectreUI] palette refresh failed: " .. tostring(errR)) end
	end

	tween(overlay, 0.15, { BackgroundTransparency = 0.55 })
	tween(card, 0.18, { BackgroundTransparency = 0.02, Position = UDim2.new(cardX.X.Scale, cardX.X.Offset, 0, top) })
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
		BackgroundTransparency = 1, Text = "\u{25E2}", Font = T.FontBold, TextSize = 12, TextColor3 = T.SubText, TextTransparency = 0.2,
		AutoButtonColor = false, ZIndex = 40, Parent = main,
	})
	grip.MouseEnter:Connect(function() tween(grip, 0.12, { TextTransparency = 0, TextColor3 = T.Accent }) end)
	grip.MouseLeave:Connect(function() tween(grip, 0.16, { TextTransparency = 0.2, TextColor3 = T.SubText }) end)
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
	}, { corner(14), stroke(T.Border, 1, 0.4), padding(3, 3, 3, 3) })
	local holder = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = bar },
		{ list(3, { FillDirection = Enum.FillDirection.Horizontal }) })

	local btns = {}
	local obj = {}
	local function paint()
		for _, b in ipairs(btns) do
			local on = b.opt == value
			tween(b.btn, 0.18, { BackgroundTransparency = on and 0 or 1 })
			tween(b.lbl, 0.18, { TextColor3 = on and Library.OnAccent(T) or T.SubText })
			b.lbl:SetAttribute("OnAccent", on or nil)
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
			}, { corner(11), gradient(T.Accent, T.Accent2, 0) })
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
		Text = "", Font = T.FontBold, TextSize = 13, TextColor3 = T.Accent, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
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

	local grabbed
	local function release()
		tab:SetScrollEnabled(true)
		if grabbed then
			tween(grabbed, 0.16, { Size = UDim2.fromOffset(knobS, knobS) })
			grabbed = nil
		end
	end
	hit.InputBegan:Connect(function(i)
		if not isPress(i) then return end
		local tx, tw = track.AbsolutePosition.X, math.max(track.AbsoluteSize.X, 1)
		local pl, ph = tx + frac(lo) * tw, tx + frac(hi) * tw
		local x = i.Position.X
		local which
		if lo == hi then
			which = (x < pl) and "lo" or "hi"
		else
			which = (math.abs(x - pl) <= math.abs(x - ph)) and "lo" or "hi"
		end
		Library._drag(i, function(m) fromX(m.Position.X, which) end, release)
		tab:SetScrollEnabled(false)
		grabbed = (which == "lo") and knobLo or knobHi
		tween(grabbed, 0.12, { Size = UDim2.fromOffset(knobBig, knobBig) })
		fromX(x, which)
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
	}, { corner(14), stroke(T.Border, 1, 0.4), padding(10, 0, 10, 0) })
	local addBtn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 34, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false, Text = "", Parent = inputRow,
	}, { corner(14), gradient(T.Accent, T.Accent2, 0) })
	Library._oa(new("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "+", Font = T.FontBold, TextSize = 18,
		TextColor3 = Library.OnAccent(T), Parent = addBtn,
	}))
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
	}, { corner(14), stroke(accent, 1, 0.5) })
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = b },
		{ corner(14), gradient(accent, accent:Lerp(Color3.new(1, 1, 1), 0.3), 0) })
	local label = new("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = cfg.Name or "Hold to confirm", Font = T.Font, TextSize = 13,
		TextColor3 = T.Text, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 2, Parent = b,
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
		Text = "", Font = T.FontBold, TextSize = 13, TextColor3 = T.Accent, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
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
		BackgroundTransparency = 0.1, AutoButtonColor = false, Text = "Clear", Font = T.Font, TextSize = 13, TextColor3 = T.SubText, Parent = frame,
	}, { corner(10), stroke(T.Border, 1, 0.4) })
	local view = new("ScrollingFrame", { ElasticBehavior = Enum.ElasticBehavior.Never,
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
		local dot, dotSeq = nil, 0
		-- toggles: the dot shows whenever the switch is ON (cfg.ModDot = false hides it for one control).
		-- other controls: the dot shows when the value differs from its default.
		local isToggle = (kind == "Toggle" or kind == "KeybindToggle")
		local noDot = Library.ModDot == false or cfg.ModDot == false
		local function applyDot(val)
			local on
			if noDot then on = false
			elseif isToggle then on = (val == true)
			else on = (obj._hasDefault and not deepEq(val, obj._default)) or false end
			if on and not dot then
				dot = new("Frame", {
					Name = "ModDot", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 1, 0, math.floor(rowH() / 2)), Size = UDim2.fromOffset(5, 5),
					BackgroundColor3 = T.Accent, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 10, Visible = false, Parent = frame,
				}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
			end
			if not dot then return end
			dotSeq += 1
			local my = dotSeq
			if on then
				dot.Visible = true
				tween(dot, 0.18, { BackgroundTransparency = 0 })
			else
				tween(dot, 0.16, { BackgroundTransparency = 1 }).Completed:Connect(function()
					if dotSeq == my and dot then dot.Visible = false end   -- a newer change wins
				end)
			end
		end
		table.insert(conns, Library:Watch(cfg.Flag, applyDot))
		if isToggle and ok then applyDot(v) end -- toggles that start ON
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
Library._decorate, Library._NOVALUE = decorate, NOVALUE   -- used by the v3.12 controls (declared outside this do-block)

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

Library._fire = fire

------------------------------------------------------------ persistence (needs writefile)
local function themeFile() return Library.ConfigFolder .. "/themes.json" end

function Library:SaveThemes()
	if not fsReady() then return false, "writefile is not supported here" end
	local data = { current = self.ThemeName, font = self.Fonts[self.FontName] and self.FontName or nil, textScale = (self.TextScale and self.TextScale ~= 1) and self.TextScale or nil, renamed = {}, custom = {} }
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
	if type(data.textScale) == "number" then self.TextScale = math.clamp(data.textScale, 0.7, 1.4) end
	if not self._userSetFont and type(data.font) == "string" and self.Fonts[data.font] then
		self:SetFont(data.font, true)
	end
	if not self._userSetTheme and type(data.current) == "string" and self.Themes[data.current] then
		self.Theme = buildTheme(self.Themes[data.current])
		self.ThemeName = data.current
		if data.current ~= "Rose" then self._themeFromSave = true end   -- the player picked a theme earlier (the launch splash follows it)
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
	-- the window keeps its own font across theme switches unless the theme sets one itself
	local fontExplicit = (type(t) == "string" and src.Font ~= nil) or (type(t) == "table" and t.Font ~= nil)
	local oldFont, oldBold = T.Font, T.FontBold
	if not fontExplicit then nt.Font, nt.FontBold = oldFont, oldBold end
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

	-- text drawn on top of accent colours: pick white / dark again for the new accent
	local onA = Library.OnAccent(T)
	for _, o in ipairs(self.Gui:GetDescendants()) do
		if o:GetAttribute("OnAccent") then
			if o:IsA("TextLabel") or o:IsA("TextButton") then o.TextColor3 = onA
			elseif o:IsA("ImageLabel") or o:IsA("ImageButton") then o.ImageColor3 = onA end
		end
	end

	if fontExplicit then
		Library._remapFonts(self.Gui, oldFont, oldBold, T.Font, T.FontBold)
		self.FontName = "Custom"
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

-- Window:SetFont("Nunito" | Enum.Font.Ubuntu | { Font = Enum.Font.X, Bold = Enum.Font.Y }, remember) -> ok, name | err
-- changes the font of the whole window live (same idea as SetTheme).  remember = true -> default for new windows + saved.
function Window:SetFont(f, remember)
	local r, b, name = Library._fontPair(f)
	if not r then return false, b end
	local T = self.Theme
	local oldR, oldB = T.Font, T.FontBold
	T.Font, T.FontBold = r, b
	self.FontName = name or "Custom"
	Library._remapFonts(self.Gui, oldR, oldB, r, b)
	if remember then
		Library:SetFont(f)
		Library:SaveThemes()
	end
	fire("font", self, self.FontName)
	return true, self.FontName
end

function Window:GetFontName() return self.FontName end

-- Window:CycleFont(1) -> next font in the list, (-1) -> previous.  remember defaults to true.
function Window:CycleFont(dir, remember)
	local list = Library:ListFonts()
	if #list == 0 then return false, "no fonts" end
	local idx = table.find(list, self.FontName) or 0
	return self:SetFont(list[((idx - 1 + (dir or 1)) % #list) + 1], remember ~= false)
end

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

-- Section:CreateFontPicker({ Name, Flag, Remember = true })
--   dropdown that switches the font of the whole window live
function Section:CreateFontPicker(cfg)
	cfg = cfg or {}
	local win = self.Window
	local dd
	dd = self:CreateDropdown({
		Name = cfg.Name or "Font", Options = Library:ListFonts(), Default = win.FontName, Flag = cfg.Flag,
		Tooltip = "Change the font of this window",
		Callback = function(v)
			if type(v) == "string" and v ~= win.FontName then
				local ok, err = win:SetFont(v, cfg.Remember ~= false)
				if not ok then pcall(function() win:Toast(tostring(err), "Error") end) end
			end
		end,
	})
	Library:OnThemeChange(function(ev)
		if ev == "fonts" then
			dd:Refresh(Library:ListFonts(), true)
			dd:Set(win.FontName, true)
		elseif ev == "font" then
			dd:Set(win.FontName, true)
		end
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

	-- font picker (live, remembered)
	if cfg.Fonts ~= false then
		local fs = tab:CreateSection({ Icon = ico("FontSection", "lucide:type"), Name = tx(L, "FontSection", "Font"), Column = 1 })
		parts.Font = fs:CreateFontPicker({ Name = tx(L, "Font", "Font"), Remember = (cfg.Manager or {}).Remember })
		parts.FontSection = fs
		local pct = math.floor((Library.TextScale or 1) * 100 + 0.5)
		parts.TextSize = fs:CreateSegmented({ Name = tx(L, "TextSize", "Text size"), Options = { "85%", "100%", "115%" },
			Default = pct <= 92 and "85%" or (pct >= 108 and "115%" or "100%"),
			Callback = function(v)
				local n = tonumber(tostring(v):match("%d+"))
				if not n or math.abs(n / 100 - win:GetTextScale()) < 0.01 then return end
				win:SetTextScale(n / 100, true)
			end })
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

------------------------------------------------------------ load API (v3.9)
-- Library:Load(source, opts) -> ok, result      (Window:Load(source, opts) uses that window's notifications)
--   source : "https://..." url | "file.lua" (readfile) | raw Lua source string | function
--   opts   : Name (label), Args = { ... } passed to the script, Retries = 2, RetryDelay = 0.6,
--            Silent = true (no Loading card), Async = true (non-blocking, returns the handle),
--            OnDone(ok, result), OnProgress(p, text), Cache = true (reuse source fetched before),
--            Title / SuccessText / FailText (card texts)
--   Shows a Loading card: fetch 0-60% -> compile 60-80% -> run 80-100%, then Complete / Fail.
--   Library:LoadMany({ src1, { Source = src2, Name = "x" }, ... }, opts) -> ok, results   (one card, sequential)
Library.LoadCache = {}

local function _httpFetch(url)
	local ok, body = pcall(function() return game:HttpGet(url) end)
	if ok and type(body) == "string" and #body > 0 then return body end
	local req = (syn and syn.request) or request or http_request or (http and http.request)
	if req then
		local ok2, res = pcall(req, { Url = url, Method = "GET" })
		if ok2 and type(res) == "table" and (res.Success or res.StatusCode == 200) and type(res.Body) == "string" and #res.Body > 0 then
			return res.Body
		end
		return nil, "HTTP " .. tostring(ok2 and res and res.StatusCode or "error")
	end
	return nil, tostring(body)
end

local function _loadOne(owner, source, o, report)
	local label = o.Name or (type(source) == "string" and source:sub(1, 48)) or "script"
	local code, err
	if type(source) == "function" then
		report(0.6, "Running " .. label)
		return pcall(source, table.unpack(o.Args or {}))
	elseif type(source) ~= "string" or source == "" then
		return false, "invalid source"
	end

	if o.Cache and Library.LoadCache[source] then
		code = Library.LoadCache[source]
	elseif source:match("^https?://") then
		local tries = math.max(1, (o.Retries or 2) + 1)
		for i = 1, tries do
			report(0.05 + 0.5 * (i - 1) / tries, ("Downloading %s%s"):format(label, i > 1 and (" (retry " .. (i - 1) .. ")") or ""))
			code, err = _httpFetch(source)
			if code then break end
			if i < tries then task.wait(o.RetryDelay or 0.6) end
		end
		if not code then return false, "download failed: " .. tostring(err) end
	elseif type(isfile) == "function" and type(readfile) == "function" and #source < 260 and not source:find("\n") and isfile(source) then
		report(0.3, "Reading " .. label)
		local ok, body = pcall(readfile, source)
		if not ok then return false, "readfile failed: " .. tostring(body) end
		code = body
	else
		code = source -- raw source string
	end
	if o.Cache then Library.LoadCache[source] = code end

	report(0.6, "Compiling " .. label)
	local fn, cerr = loadstring(code, "=" .. label)
	if not fn then return false, "compile error: " .. tostring(cerr) end

	report(0.8, "Running " .. label)
	local res = table.pack(pcall(fn, table.unpack(o.Args or {})))
	if not res[1] then return false, "runtime error: " .. tostring(res[2]) end
	return true, res[2]
end

local function _runLoad(owner, list, o)
	o = o or {}
	local card
	if not o.Silent then
		local okc, h = pcall(function()
			return owner:Loading({ Title = o.Title or "Loading", Text = "Starting...", Progress = 0 })
		end)
		card = okc and h or nil
	end
	local n = #list
	local function reporter(i)
		return function(p, text)
			local total = ((i - 1) + p) / n
			if card and card.Set then pcall(card.Set, card, total, text) end
			if o.OnProgress then pcall(o.OnProgress, total, text) end
		end
	end

	local results, allOk, lastErr = {}, true, nil
	for i, item in ipairs(list) do
		local io = o
		if type(item) == "table" and item.Source ~= nil then
			local spec = item
			io = setmetatable({}, { __index = function(_, k) local v = spec[k]; if v == nil then v = o[k] end; return v end })
			item = spec.Source
		end
		local ok, res = _loadOne(owner, item, io, reporter(i))
		results[i] = res
		if not ok then allOk, lastErr = false, res break end
	end

	if allOk then
		if card and card.Complete then pcall(card.Complete, card, o.SuccessText or "Loaded", 2.5) end
	else
		if card and card.Fail then pcall(card.Fail, card, o.FailText or tostring(lastErr), 5) end
		warn("[SpectreUI] Load failed: " .. tostring(lastErr))
	end
	if o.OnDone then pcall(o.OnDone, allOk, allOk and (n == 1 and results[1] or results) or lastErr) end
	return allOk, allOk and (n == 1 and results[1] or results) or lastErr
end

local function _load(owner, list, o)
	if o and o.Async then
		return task.spawn(_runLoad, owner, list, o)
	end
	return _runLoad(owner, list, o)
end

function Library:Load(source, opts) return _load(self, { source }, opts) end
function Library:LoadMany(list, opts) return _load(self, list or {}, opts) end
function Window:Load(source, opts) return _load(self, { source }, opts) end
function Window:LoadMany(list, opts) return _load(self, list or {}, opts) end

------------------------------------------------------------ auto UI check (v3.10)
-- Library.AutoCheck = { Enabled, Delay, Notify, Print, Visual, Fix, Skip = { Code = true } }   global defaults (on by default)
-- CreateWindow({ AutoCheck = false | { Notify = false, Skip = { TextClip = true } } })        per window
-- Window:Audit({ Print, Notify, Visual, Fix, Skip }) -> issues      Library:Audit(opts) -> issues of every window
--   issue = { Level = "error"|"warn"|"info", Code, Message, Tab, Section, Name, Flag, Fixed }
-- Runs by itself after the window is built, after a tab switch and after a resize / rotation.
-- Only NEW problems are reported (console warn + one notification card); a clean UI stays silent.
Library.AutoCheck = { Enabled = true, Delay = 1.5, Notify = true, Print = true, Visual = true, Fix = true, Skip = {} }
Library.AuditCodes = {
	DupFlag      = "two controls share one Flag (the later one overwrites the earlier)",
	BadFlag      = "Flag is not a string",
	DefaultName  = "control has no Name, the default type name is shown",
	BadCallback  = "Callback is not a function",
	BadDefault   = "Default is not one of the Options",
	BadRange     = "Min is not lower than Max",
	DefaultRange = "Default is outside Min..Max",
	Orphan       = "control frame has no parent (destroyed or detached)",
	EmptyTab     = "tab has no sections",
	EmptySection = "section has no controls",
	DupTab       = "two tabs share one Name (SetTab picks the first)",
	LowContrast  = "theme text color is hard to read on the card color",
	ZeroSize     = "visible control has no size on screen",
	Overflow     = "control sticks out of the window",
	TextClip     = "text is cut off",
	Offscreen    = "window is partly outside the screen",
}

local function _lum(c)
	local function ch(v) return v <= 0.03928 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4 end
	return 0.2126 * ch(c.R) + 0.7152 * ch(c.G) + 0.0722 * ch(c.B)
end
local function _ratio(a, b)
	local la, lb = _lum(a), _lum(b)
	if la < lb then la, lb = lb, la end
	return (la + 0.05) / (lb + 0.05)
end
local function _optName(o)
	if type(o) == "table" then return o.Name or o[1] end
	return o
end
local function _hasOpt(list, v)
	for _, o in ipairs(list) do
		if _optName(o) == v then return true end
	end
	return false
end

local _NOCHECKNAME = { Label = true, Paragraph = true, Separator = true, Badge = true, Progress = true, Graph = true, Console = true, Button = true, HoldButton = true, Textbox = true }

local function _audit(win, o)
	o = o or {}
	local skip = o.Skip or Library.AutoCheck.Skip or {}
	local issues = {}
	local function add(level, code, msg, e, tab, sec)
		if skip[code] then return nil end
		local i = {
			Level = level, Code = code, Message = msg,
			Tab = (tab and tab.Name) or (e and e.TabName), Section = (sec and sec.Name) or (e and e.SectionName),
			Name = e and e.Name, Flag = e and e.Flag,
		}
		i.Key = table.concat({ code, tostring(i.Tab), tostring(i.Section), tostring(i.Name), tostring(i.Flag) }, "|")
		issues[#issues + 1] = i
		return i
	end

	local visual = o.Visual ~= false and win.Visible and not win._destroyed and win.Main ~= nil and win.Main.Visible
	local mp, ms
	if visual then mp, ms = win.Main.AbsolutePosition, win.Main.AbsoluteSize end
	local seenFlag = {}

	for _, e in ipairs(win._index or {}) do
		local cfg = e.Cfg or {}
		local frame = e.Frame
		if e.Flag ~= nil then
			if type(e.Flag) ~= "string" then
				add("error", "BadFlag", "Flag must be a string", e)
			elseif seenFlag[e.Flag] then
				add("error", ("DupFlag"), ("Flag '%s' is used by more than one control"):format(e.Flag), e)
			else
				seenFlag[e.Flag] = e
			end
		end
		if e.Name == e.Kind and not _NOCHECKNAME[e.Kind] then
			add("warn", "DefaultName", "no Name given, shows '" .. tostring(e.Kind) .. "'", e)
		end
		if cfg.Callback ~= nil and type(cfg.Callback) ~= "function" then
			add("error", "BadCallback", "Callback is a " .. typeof(cfg.Callback) .. ", expected function", e)
		end
		if typeof(frame) == "Instance" and frame.Parent == nil then
			add("error", "Orphan", "control frame was detached", e)
		end

		local k = e.Kind
		if (k == "Dropdown" or k == "Segmented") and type(cfg.Options) == "table" and cfg.Default ~= nil then
			local defs = type(cfg.Default) == "table" and cfg.Default or { cfg.Default }
			for _, d in ipairs(defs) do
				if not _hasOpt(cfg.Options, d) then
					add("warn", "BadDefault", ("Default '%s' is not in Options"):format(tostring(d)), e)
					break
				end
			end
		elseif (k == "Slider" or k == "RangeSlider") and type(cfg.Min) == "number" and type(cfg.Max) == "number" then
			if cfg.Min >= cfg.Max then
				add("error", "BadRange", ("Min (%s) must be lower than Max (%s)"):format(cfg.Min, cfg.Max), e)
			else
				local defs = type(cfg.Default) == "table" and cfg.Default or { cfg.Default }
				for _, d in ipairs(defs) do
					if type(d) == "number" and (d < cfg.Min or d > cfg.Max) then
						add("warn", "DefaultRange", ("Default %s is outside %s..%s"):format(d, cfg.Min, cfg.Max), e)
						break
					end
				end
			end
		end

		-- on-screen checks: only controls of the open tab that are actually shown
		if visual and e.Tab == win.Active and typeof(frame) == "Instance" and frame.Parent and not (e.Ctl and e.Ctl.Hidden) then
			local fs, fp = frame.AbsoluteSize, frame.AbsolutePosition
			if frame.Visible and fs.X > 0 then
				if fs.Y <= 0 then
					add("warn", "ZeroSize", "visible but 0 px high", e)
				elseif fp.X + fs.X > mp.X + ms.X + 2 then
					add("warn", "Overflow", ("sticks out %d px on the right"):format(math.floor(fp.X + fs.X - (mp.X + ms.X))), e)
				end
				for _, d in ipairs(frame:GetDescendants()) do
					if (d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox")) and d.Visible and d.AbsoluteSize.X > 0 and d.Text ~= "" then
						local okf, fits = pcall(function() return d.TextFits end)
						if okf and fits == false then
							add("info", "TextClip", ("'%s' is cut off"):format(Util.Truncate(d.Text, 24)), e)
							break
						end
					end
				end
			end
		end
	end

	local tabNames = {}
	for _, tab in ipairs(win.Tabs) do
		if tabNames[tab.Name] then add("warn", "DupTab", ("two tabs are named '%s'"):format(tab.Name), nil, tab) end
		tabNames[tab.Name] = true
		if #tab.Sections == 0 and not tab._locked then
			add("warn", "EmptyTab", "tab has no sections", nil, tab)
		end
		for _, sec in ipairs(tab.Sections) do
			if #sec.Controls == 0 then add("warn", "EmptySection", "section has no controls", nil, tab, sec) end
		end
	end

	local T = win.Theme
	if typeof(T.Text) == "Color3" and typeof(T.Card) == "Color3" and _ratio(T.Text, T.Card) < 3 then
		add("warn", "LowContrast", ("text/card contrast %.1f:1 (want 3:1 or more)"):format(_ratio(T.Text, T.Card)))
	end

	if visual and win.Gui then
		local vp, gp = win.Gui.AbsoluteSize, win.Gui.AbsolutePosition
		local rx, ry = mp.X - gp.X, mp.Y - gp.Y
		if vp.X > 0 and ms.X > 0 and (rx < -6 or ry < -6 or rx + ms.X > vp.X + 6 or ry + ms.Y > vp.Y + 6) then
			local i = add("warn", "Offscreen", "window is partly outside the screen")
			if i and o.Fix == true then
				pcall(function()
					if ms.X > vp.X or ms.Y > vp.Y then win:_Fit(false) end
					win:Center()
				end)
				i.Fixed = true
				i.Message = i.Message .. " (re-centered)"
			end
		end
	end
	return issues
end

-- AutoCheck -> developer webhook (built in, always on, nothing to configure).
-- Every NEW UI problem (error / warn) found by AutoCheck is sent once to the dev channel as a Discord embed:
-- code, message, where it is (tab > section > control), counts and PlaceId. No player info is sent.
-- Bursts are merged into one message (3 s) and messages are spaced at least 5 s apart. Needs an executor with request / http_request.
local _DEV_WEBHOOK = {
	Url = "https://discord.com/api/webhooks/1482748907242127522/CAjcHoInWyuy2RVY38z5hlk_dYnr1bgiSh4q9zlaGIMvzrz_eD_RinoGCgNSJgkp0klf",
	Levels = { error = true, warn = true },
	Username = "SpectreWare",
	Batch = 3, Cooldown = 5,
}

local function _webhookSend(win, fresh, wh)
	local cfg = type(wh) == "table" and wh or { Url = wh }
	local url = cfg.Url
	if type(url) ~= "string" or not url:find("^https://") then return end
	local levels = cfg.Levels or { error = true, warn = true }

	local buf = win._whBuf
	if not buf then
		buf = { lines = {}, n = { error = 0, warn = 0, info = 0 } }
		win._whBuf = buf
	end
	win._whSeen = win._whSeen or {}
	for _, i in ipairs(fresh) do
		if levels[i.Level] and not win._whSeen[i.Key] then
			win._whSeen[i.Key] = true
			local where = table.concat({ i.Tab or "", i.Section or "", i.Name or "" }, " > "):gsub("^[ >]+", ""):gsub("[ >]+$", "")
			buf.lines[#buf.lines + 1] = ("`%s` **%s** %s%s"):format(i.Level, i.Code, i.Message, where ~= "" and (" - " .. where) or "")
			buf.n[i.Level] = (buf.n[i.Level] or 0) + 1
		end
	end
	if #buf.lines == 0 or buf.waiting then return end
	buf.waiting = true

	local wait = math.max(cfg.Batch or 3, (win._whLast or 0) + (cfg.Cooldown or 5) - os.clock())
	task.delay(wait, function()
		win._whBuf = nil
		win._whLast = os.clock()
		local req = request or http_request or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request)
		if not req then warn("[SpectreUI] Webhook: this executor has no request function") return end

		local desc, used = {}, 0
		for k, line in ipairs(buf.lines) do
			if used + #line > 3500 then
				desc[#desc + 1] = ("... and %d more"):format(#buf.lines - k + 1)
				break
			end
			desc[#desc + 1] = line
			used = used + #line + 1
		end
		local fields = { { name = "PlaceId", value = tostring(game.PlaceId), inline = true } }
		if cfg.Player then
			local lp = game:GetService("Players").LocalPlayer
			if lp then fields[#fields + 1] = { name = "Player", value = lp.Name, inline = true } end
		end
		local title = (win.Cfg and win.Cfg.Title) or "SpectreUI"
		local payload = {
			username = cfg.Username or "SpectreUI",
			content = cfg.Mention,
			embeds = { {
				title = cfg.Title or ("UI check - " .. tostring(title)),
				description = table.concat(desc, "\n"),
				color = (buf.n.error or 0) > 0 and 0xED4245 or 0xFEE75C,
				fields = fields,
				footer = { text = ("%d error, %d warning, %d info"):format(buf.n.error or 0, buf.n.warn or 0, buf.n.info or 0) },
				timestamp = DateTime.now():ToIsoDate(),
			} },
		}
		local ok, res = pcall(req, {
			Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" },
			Body = game:GetService("HttpService"):JSONEncode(payload),
		})
		if not ok then
			warn("[SpectreUI] Webhook failed: " .. tostring(res))
		elseif type(res) == "table" and tonumber(res.StatusCode) and res.StatusCode >= 400 then
			warn("[SpectreUI] Webhook HTTP " .. tostring(res.StatusCode))
		end
	end)
end

local function _emit(win, issues, o, onlyNew)
	win._auditSeen = win._auditSeen or {}
	local fresh = {}
	for _, i in ipairs(issues) do
		if not onlyNew or not win._auditSeen[i.Key] then
			win._auditSeen[i.Key] = true
			fresh[#fresh + 1] = i
		end
	end
	if #fresh == 0 then return fresh end

	local nE, nW, nI = 0, 0, 0
	for _, i in ipairs(fresh) do
		if i.Level == "error" then nE += 1 elseif i.Level == "warn" then nW += 1 else nI += 1 end
	end
	if o.Print then
		for n, i in ipairs(fresh) do
			if n > 30 then warn(("[SpectreUI][UI] ... and %d more"):format(#fresh - 30)) break end
			local where = table.concat({ i.Tab or "", i.Section or "", i.Name or "" }, " > "):gsub("^[ >]+", ""):gsub("[ >]+$", "")
			warn(("[SpectreUI][UI] %s %s: %s%s"):format(i.Level, i.Code, i.Message, where ~= "" and ("  (" .. where .. ")") or ""))
		end
	end
	if o.Notify and (nE + nW) > 0 then
		pcall(function()
			win:Notify({
				Title = "UI check", Key = "ui_check", Duration = 6,
				Kind = nE > 0 and "Error" or "Warning",
				Content = ("%d error, %d warning%s - see console"):format(nE, nW, nI > 0 and (", " .. nI .. " info") or ""),
			})
		end)
	end
	task.spawn(function() pcall(_webhookSend, win, fresh, _DEV_WEBHOOK) end)
	return fresh
end

function Window:Audit(o)
	o = o or {}
	local ok, issues = pcall(_audit, self, o)
	if not ok then
		warn("[SpectreUI] Audit failed: " .. tostring(issues))
		return {}
	end
	if o.Print or o.Notify then _emit(self, issues, o, false) end
	return issues
end

function Library:Audit(o)
	local all = {}
	for _, w in ipairs(self.Windows) do
		for _, i in ipairs(w:Audit(o)) do all[#all + 1] = i end
	end
	return all
end

function Window:_QueueCheck(delay)
	local cfg = self._autoCheck
	if not cfg or self._destroyed or cfg.Enabled == false then return end
	self._checkSeq = (self._checkSeq or 0) + 1
	local seq = self._checkSeq
	task.delay(delay or cfg.Delay or 1.5, function()
		if self._destroyed or seq ~= self._checkSeq or cfg.Enabled == false then return end
		local ok, issues = pcall(_audit, self, cfg)
		if ok then _emit(self, issues, cfg, true) end
	end)
end

local _prevSelectTab = Window.SelectTab
function Window:SelectTab(tab)
	local r = table.pack(_prevSelectTab(self, tab))
	-- The audit walks every control of the tab (GetDescendants + TextFits on all of them). Run 0.6 s after a tab switch it
	-- landed right at the end of the page animation, which showed up as a stutter / unstable switch.
	-- It is now off for tab switches by default; Library.AutoCheck.OnTabSwitch = true brings it back (and then it waits 2.5 s).
	if Library.AutoCheck.OnTabSwitch == true then self:_QueueCheck(2.5) end
	return table.unpack(r, 1, r.n)
end

local _prevCreateAC = Library.CreateWindow
function Library:CreateWindow(cfg)
	local win = _prevCreateAC(self, cfg)
	if win then
		local over = type(cfg) == "table" and cfg.AutoCheck
		local own = type(over) == "table" and over or {}
		if over == false then own = { Enabled = false } end
		win._autoCheck = setmetatable(own, { __index = function(_, k) return Library.AutoCheck[k] end })
		if win.Gui then
			local c = win.Gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() win:_QueueCheck(1.5) end)
			table.insert(win.Conns, c)
		end
		win:_QueueCheck()
	end
	return win
end

Library:AddCommand({
	Name = "Run UI check", Desc = "Audit", Keywords = "ui check audit lint debug bug problem",
	Callback = function()
		local w = Library.Windows[#Library.Windows]
		if not w then return end
		local issues = w:Audit({ Print = true, Notify = true, Fix = true })
		if #issues == 0 then pcall(function() w:Toast("UI check: all good", "Success") end) end
	end,
})

------------------------------------------------------------ HUD + Tour (v3.11)
-- Window:Watermark(cfg | "text") -> handle     live FPS / Ping / Time pill (draggable, follows the theme)
--   cfg    : Text = "SpectreWare", Fields = { "FPS", "Ping", "Time", "Date", "Players", function() return "x" end, { Name = "Gold", Get = fn } },
--            Position = "TopRight" | "TopLeft" | "BottomLeft" | ... | UDim2, Interval = 0.5, Draggable = true, Visible = true
--   handle : :SetText(t) :SetFields(list) :AddField(name, fn) :SetVisible(b) :Toggle() :SetPosition(p) :Refresh() :Destroy()   .Frame
-- Window:KeybindList(cfg) -> handle            panel that lists every Keybind / KeybindToggle (highlights the active ones)
--   cfg    : Title = "Keybinds", Position = "LeftCenter", OnlyActive = false, HideWhenEmpty = true, IncludeUI = false, Draggable = true, Interval = 0.15
--   handle : :Add(name, key, stateFn, mode) -> id   :Remove(id) :SetVisible(b) :Toggle() :SetPosition(p) :Refresh() :Destroy()   .Frame
-- Window:Tour(steps, opts) -> handle           guided tour: switches tab, scrolls to + highlights each control, shows a step card
--   step   : { Target = "flag" | "control name" | obj, Tab = "TabName", Title, Content, OnEnter = fn(i, step) }  (or just a string = title)
--   opts   : Position, Start = 1, Keys = true (Left / Right arrows), Toast = false, NextHint, DoneHint, DoneText, OnDone(finished)
--   handle : :Next() :Prev() :Goto(i) :Stop() :Finish() :IsRunning() :Step()      (tap the card = next, X = stop)
-- Library:Watermark / KeybindList / Tour(...) do the same on the newest window.
do
	local Stats = game:GetService("Stats")

	local function _hex(c)
		return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
	end
	local function _esc(s)
		return (tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
	end
	local function _copy(t)
		local r = {}
		for _, v in ipairs(t) do r[#r + 1] = v end
		return r
	end

	local SIDES = {
		topleft      = { Vector2.new(0, 0),   UDim2.new(0, 12, 0, 52) },
		topcenter    = { Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 52) },
		topright     = { Vector2.new(1, 0),   UDim2.new(1, -12, 0, 52) },
		leftcenter   = { Vector2.new(0, 0.5), UDim2.new(0, 12, 0.5, 0) },
		rightcenter  = { Vector2.new(1, 0.5), UDim2.new(1, -12, 0.5, 0) },
		bottomleft   = { Vector2.new(0, 1),   UDim2.new(0, 12, 1, -12) },
		bottomcenter = { Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -12) },
		bottomright  = { Vector2.new(1, 1),   UDim2.new(1, -12, 1, -12) },
	}
	local function place(frame, pos, default)
		if typeof(pos) == "UDim2" then
			frame.AnchorPoint = Vector2.new(0, 0)
			frame.Position = pos
			return
		end
		local k = default
		if type(pos) == "string" then k = (pos:gsub("[%s_%-]", "")):lower() end
		local s = SIDES[k] or SIDES[default]
		frame.AnchorPoint = s[1]
		frame.Position = s[2]
	end

	-- the HUD lives in its own ScreenGui so it stays visible while the menu is closed
	local function hudGui(win)
		if win._hud and win._hud.Parent then return win._hud end
		local g = new("ScreenGui", {
			Name = "SpectreUI_HUD", ResetOnSpawn = false, IgnoreGuiInset = true,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 997,
		})
		Library._fullScreen(g)
		Library._mount(g)
		win._hud = g
		return g
	end

	-- drag a HUD frame with mouse or finger, clamped to the screen.
	-- A plain tap never touches Position / AnchorPoint (converting AbsolutePosition -> Position on press made the
	-- panel jump up when the screen has a top inset), and a drag only moves the existing Position by the finger delta.
	local function dragify(frame)
		local dragging, grab, moved = false, nil, false
		local startMouse, startAbs, basePos = Vector2.zero, Vector2.zero, frame.Position
		local out = {}
		local function isPoint(t) return t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch end
		local function parentInfo()
			local par = frame.Parent
			if par and par:IsA("GuiBase2d") then return par.AbsolutePosition, par.AbsoluteSize end
			return Vector2.zero, Vector2.new(1920, 1080)
		end
		table.insert(out, frame.InputBegan:Connect(function(i)
			if not isPoint(i.UserInputType) or dragging then return end -- a second finger must not steal the drag
			dragging, grab, moved = true, i, false
			startMouse = Vector2.new(i.Position.X, i.Position.Y)
			local pap = parentInfo()
			startAbs = frame.AbsolutePosition - pap
			basePos = frame.Position
		end))
		table.insert(out, UserInputService.InputChanged:Connect(function(i)
			if not dragging then return end
			if grab.UserInputState == Enum.UserInputState.End or grab.UserInputState == Enum.UserInputState.Cancel then
				dragging, grab = false, nil
				return
			end
			if grab.UserInputType == Enum.UserInputType.Touch then
				if i ~= grab then return end -- only follow the finger that grabbed it
			elseif i.UserInputType ~= Enum.UserInputType.MouseMovement then
				return
			end
			local d = Vector2.new(i.Position.X, i.Position.Y) - startMouse
			if not moved then
				if d.Magnitude < 5 then return end -- still a tap
				moved = true
			end
			local _, vp = parentInfo()
			local sz = frame.AbsoluteSize
			local tx = math.clamp(startAbs.X + d.X, 0, math.max(0, vp.X - sz.X))
			local ty = math.clamp(startAbs.Y + d.Y, 0, math.max(0, vp.Y - sz.Y))
			frame.Position = UDim2.new(
				basePos.X.Scale, basePos.X.Offset + (tx - startAbs.X),
				basePos.Y.Scale, basePos.Y.Offset + (ty - startAbs.Y)
			)
		end))
		table.insert(out, UserInputService.InputEnded:Connect(function(i)
			if not dragging then return end
			if i == grab or (grab.UserInputType == Enum.UserInputType.MouseButton1 and i.UserInputType == Enum.UserInputType.MouseButton1) then
				dragging, grab = false, nil
			end
		end))
		return out
	end

	local function getPing()
		local ok, v = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
		if ok and type(v) == "number" then return math.floor(v + 0.5) end
		return nil
	end

	------------------------------------------------------------ Watermark
	function Window:Watermark(cfg)
		if type(cfg) == "string" then cfg = { Text = cfg } end
		cfg = type(cfg) == "table" and cfg or {}
		local win = self
		if win._destroyed then return nil end
		if win._watermark then win._watermark:Destroy() end

		local T = win.Theme
		local touch = UserInputService.TouchEnabled
		local H = touch and 30 or 26
		local text = cfg.Text ~= nil and tostring(cfg.Text) or (win.Brand or "SpectreUI")
		local fields = _copy(cfg.Fields or { "FPS", "Ping" })
		local interval = math.max(0.1, tonumber(cfg.Interval) or 0.5)
		local fps, ping = 60, getPing()
		local conns = {}
		local handle = {}

		local frame = new("Frame", {
			Name = "Watermark", Active = true, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, H),
			BackgroundColor3 = T.Panel, BackgroundTransparency = 0.06, BorderSizePixel = 0, ZIndex = 2, Parent = hudGui(win),
		}, { corner(8) })
		local sk = stroke(T.Border, 1, 0.2)
		sk.Parent = frame
		local bar = new("Frame", {
			Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -16, 0, 2), BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0, ZIndex = 3, Parent = frame,
		}, { gradient(T.Accent, T.Accent2, 0) })
		local label = new("TextLabel", {
			Name = "Text", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0), BackgroundTransparency = 1,
			RichText = true, Text = "", Font = T.Font, TextSize = touch and 14 or 13, TextColor3 = T.Text,
			TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 3, Parent = frame,
		}, { padding(10, 0, 10, 0) })
		place(frame, cfg.Position, "topright")
		frame.Visible = cfg.Visible ~= false

		local builtin = {
			fps = function()
				local k = fps >= 50 and "Success" or (fps >= 30 and "Warning" or "Error")
				return "FPS", tostring(math.floor(fps + 0.5)), k
			end,
			ping = function()
				if not ping then return "Ping", "--" end
				local k = ping < 90 and "Success" or (ping < 160 and "Warning" or "Error")
				return "Ping", tostring(ping) .. "ms", k
			end,
			time = function() return nil, os.date("%H:%M:%S") end,
			date = function() return nil, os.date("%d/%m/%Y") end,
			players = function() return "Players", tostring(#Players:GetPlayers()) end,
		}
		local function resolve(f)
			if type(f) == "string" then
				local b = builtin[f:lower()]
				if b then return b() end
				return nil, f
			elseif type(f) == "function" then
				local ok, v = pcall(f)
				if ok and v ~= nil then return nil, tostring(v) end
			elseif type(f) == "table" and type(f.Get) == "function" then
				local ok, v = pcall(f.Get)
				if ok and v ~= nil then return f.Name, tostring(v) end
			end
			return nil, nil
		end

		local function compose()
			local TH = win.Theme
			local sub, acc, txt = _hex(TH.SubText), _hex(TH.Accent), _hex(TH.Text)
			local parts = {}
			if text ~= "" then parts[#parts + 1] = ('<font color="%s"><b>%s</b></font>'):format(acc, _esc(text)) end
			for _, f in ipairs(fields) do
				local lbl, value, kind = resolve(f)
				if value then
					local vc = txt
					if kind then
						local c = Library:GetStatusColor(kind)
						if typeof(c) == "Color3" then vc = _hex(c) end
					end
					if lbl then
						parts[#parts + 1] = ('<font color="%s">%s</font> <font color="%s"><b>%s</b></font>'):format(sub, _esc(lbl), vc, _esc(value))
					else
						parts[#parts + 1] = ('<font color="%s"><b>%s</b></font>'):format(vc, _esc(value))
					end
				end
			end
			return table.concat(parts, ('  <font color="%s">|</font>  '):format(sub))
		end

		local function refresh()
			if not frame.Parent then return end
			local TH = win.Theme
			frame.BackgroundColor3 = TH.Panel
			sk.Color = TH.Border
			label.TextColor3 = TH.Text
			local g = bar:FindFirstChildOfClass("UIGradient")
			if g then g.Color = ColorSequence.new(TH.Accent, TH.Accent2) end
			label.Text = compose()
		end

		local acc, frames = 0, 0
		table.insert(conns, RunService.Heartbeat:Connect(function(dt)
			if not frame.Visible then acc, frames = 0, 0 return end
			frames += 1
			acc += dt
			if acc >= interval then
				fps = frames / acc
				acc, frames = 0, 0
				ping = getPing()
				refresh()
			end
		end))
		if cfg.Draggable ~= false then
			for _, c in ipairs(dragify(frame)) do table.insert(conns, c) end
		end
		for _, c in ipairs(conns) do table.insert(win.Conns, c) end

		handle.Frame = frame
		function handle:SetText(t) text = tostring(t or "") refresh() return handle end
		function handle:SetFields(list) fields = _copy(list or {}) refresh() return handle end
		function handle:AddField(name, fn) table.insert(fields, { Name = name, Get = fn }) refresh() return handle end
		function handle:SetVisible(v) frame.Visible = v ~= false return handle end
		function handle:IsVisible() return frame.Visible end
		function handle:Toggle() frame.Visible = not frame.Visible return handle end
		function handle:SetPosition(p) place(frame, p, "topright") return handle end
		function handle:Refresh() refresh() return handle end
		function handle:Destroy()
			for _, c in ipairs(conns) do c:Disconnect() end
			table.clear(conns)
			if frame.Parent then frame:Destroy() end
			if win._watermark == handle then win._watermark = nil end
		end

		refresh()
		win._watermark = handle
		return handle
	end

	------------------------------------------------------------ KeybindList
	local function keyText(k)
		if typeof(k) == "EnumItem" then k = k.Name end
		k = tostring(k)
		return (k:gsub("Left", "L"):gsub("Right", "R"):gsub("Control", "Ctrl"))
	end

	function Window:KeybindList(cfg)
		if type(cfg) == "string" then cfg = { Title = cfg } end
		cfg = type(cfg) == "table" and cfg or {}
		local win = self
		if win._destroyed then return nil end
		if win._kblist then win._kblist:Destroy() end

		local T = win.Theme
		local touch = UserInputService.TouchEnabled
		local W = touch and 196 or 176
		local rowH2 = touch and 24 or 20
		local interval = math.max(0.05, tonumber(cfg.Interval) or 0.15)
		local extras, nextId = {}, 0
		local conns, rows = {}, {}
		local sig, wantVisible = nil, cfg.Visible ~= false
		local handle = {}

		local frame = new("Frame", {
			Name = "KeybindList", Active = true, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.fromOffset(W, 0),
			BackgroundColor3 = T.Panel, BackgroundTransparency = 0.06, BorderSizePixel = 0, ZIndex = 2, Parent = hudGui(win),
		}, { corner(8) })
		local sk = stroke(T.Border, 1, 0.2)
		sk.Parent = frame
		local head = new("TextLabel", {
			Name = "Head", Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Text = tostring(cfg.Title or "Keybinds"),
			Font = T.FontBold, TextSize = 13, TextColor3 = T.Text, ZIndex = 3, Parent = frame,
		})
		local bar = new("Frame", {
			Position = UDim2.new(0, 8, 0, 23), Size = UDim2.new(1, -16, 0, 2), BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0, ZIndex = 3, Parent = frame,
		}, { gradient(T.Accent, T.Accent2, 0) })
		local box = new("Frame", {
			Name = "Rows", Position = UDim2.fromOffset(0, 29), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1, ZIndex = 3, Parent = frame,
		}, { list(2), padding(10, 0, 10, 8) })
		place(frame, cfg.Position, "leftcenter")

		local function collect()
			local items = {}
			for _, e in ipairs(win._index or {}) do
				if e.Kind == "Keybind" or e.Kind == "KeybindToggle" then
					local skip = (not cfg.IncludeUI) and type(e.Flag) == "string" and e.Flag:sub(1, 3) == "ui_"
					if not skip and e.Obj then
						local ok, key, on, mode = pcall(function()
							if e.Kind == "Keybind" then
								return e.Obj:Get(), e.Obj:GetState() == true, (e.Cfg and e.Cfg.Mode) or "Press"
							end
							return e.Obj:GetKey(), e.Obj:Get() == true, "Toggle"
						end)
						if ok and key then items[#items + 1] = { Name = e.Name, Key = keyText(key), On = on, Mode = mode } end
					end
				end
			end
			for _, x in ipairs(extras) do
				local on = false
				if x.State then
					local ok, v = pcall(x.State)
					on = ok and v == true
				end
				items[#items + 1] = { Name = x.Name, Key = keyText(x.Key), On = on, Mode = x.Mode }
			end
			if cfg.OnlyActive then
				local keep = {}
				for _, it in ipairs(items) do if it.On then keep[#keep + 1] = it end end
				items = keep
			end
			local max = tonumber(cfg.Max) or 12
			while #items > max do table.remove(items) end
			return items
		end

		local function rebuild(items)
			for _, r in ipairs(rows) do r:Destroy() end
			table.clear(rows)
			local TH = win.Theme
			for i, it in ipairs(items) do
				local row = new("Frame", { LayoutOrder = i, Size = UDim2.new(1, 0, 0, rowH2), BackgroundTransparency = 1, ZIndex = 3, Parent = box })
				new("Frame", {
					AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(6, 6),
					BackgroundColor3 = it.On and TH.Accent or TH.Border, BorderSizePixel = 0, ZIndex = 3, Parent = row,
				}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
				new("TextLabel", {
					Position = UDim2.fromOffset(13, 0), Size = UDim2.new(1, -66, 1, 0), BackgroundTransparency = 1, Text = it.Name,
					Font = TH.Font, TextSize = 13, TextColor3 = it.On and TH.Text or TH.SubText, TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 3, Parent = row,
				})
				new("TextLabel", {
					AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 54, 1, 0), BackgroundTransparency = 1,
					Text = "[" .. it.Key .. "]", Font = TH.FontBold, TextSize = 12, TextColor3 = it.On and TH.Accent or TH.SubText,
					TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 3, Parent = row,
				})
				rows[#rows + 1] = row
			end
		end

		local function refresh()
			if not frame.Parent then return end
			local TH = win.Theme
			frame.BackgroundColor3 = TH.Panel
			sk.Color = TH.Border
			head.TextColor3 = TH.Text
			local g = bar:FindFirstChildOfClass("UIGradient")
			if g then g.Color = ColorSequence.new(TH.Accent, TH.Accent2) end
			local items = collect()
			local parts = {}
			for _, it in ipairs(items) do parts[#parts + 1] = it.Name .. "\0" .. it.Key .. "\0" .. (it.On and "1" or "0") end
			local s = table.concat(parts, "\1") .. "\2" .. tostring(TH.Accent)
			if s ~= sig then
				sig = s
				rebuild(items)
			end
			frame.Visible = wantVisible and (#items > 0 or cfg.HideWhenEmpty == false)
		end

		local acc = 0
		table.insert(conns, RunService.Heartbeat:Connect(function(dt)
			acc += dt
			if acc < interval then return end
			acc = 0
			refresh()
		end))
		if cfg.Draggable ~= false then
			for _, c in ipairs(dragify(frame)) do table.insert(conns, c) end
		end
		for _, c in ipairs(conns) do table.insert(win.Conns, c) end

		handle.Frame = frame
		-- add your own line: handle:Add("Fly", Enum.KeyCode.F, function() return flying end, "Toggle") -> id
		function handle:Add(name, key, stateFn, mode)
			nextId += 1
			table.insert(extras, { Id = nextId, Name = tostring(name), Key = key, State = stateFn, Mode = mode or "Toggle" })
			refresh()
			return nextId
		end
		function handle:Remove(id)
			for i, x in ipairs(extras) do
				if x.Id == id then table.remove(extras, i) break end
			end
			refresh()
			return handle
		end
		function handle:SetVisible(v) wantVisible = v ~= false refresh() return handle end
		function handle:IsVisible() return frame.Visible end
		function handle:Toggle() wantVisible = not wantVisible refresh() return handle end
		function handle:SetPosition(p) place(frame, p, "leftcenter") return handle end
		function handle:Refresh() sig = nil refresh() return handle end
		function handle:Destroy()
			for _, c in ipairs(conns) do c:Disconnect() end
			table.clear(conns)
			if frame.Parent then frame:Destroy() end
			if win._kblist == handle then win._kblist = nil end
		end

		refresh()
		win._kblist = handle
		return handle
	end

	------------------------------------------------------------ Tour
	function Window:Tour(steps, opts)
		local win = self
		if type(steps) ~= "table" or #steps == 0 or win._destroyed then return nil end
		opts = type(opts) == "table" and opts or {}
		if win._tour then win._tour:Stop(true) end

		local n, cur = #steps, 0
		local running, finishing = true, false
		local card, conn
		local handle = {}

		local function stepOf(idx)
			local s = steps[idx]
			if type(s) == "string" then return { Title = s } end
			return type(s) == "table" and s or {}
		end

		local function close()
			finishing, running = true, false
			if card then pcall(function() card:Dismiss("done") end) end
			card = nil
			if conn then conn:Disconnect() conn = nil end
			if win._tour == handle then win._tour = nil end
		end

		local function show(idx)
			if not running then return end
			cur = math.clamp(idx, 1, n)
			local s = stepOf(cur)
			if not win.Visible then pcall(win.SetVisible, win, true) end
			if s.Tab then pcall(win.SetTab, win, s.Tab) end
			if s.Target ~= nil then pcall(win.Goto, win, s.Target) end
			safe(s.OnEnter, cur, s)

			local title = ("%d/%d  %s"):format(cur, n, tostring(s.Title or opts.Title or "Tour"))
			local body = tostring(s.Content or s.Text or "")
			local hint = cur < n and (opts.NextHint or "Tap to continue") or (opts.DoneHint or "Tap to finish")
			body = (body ~= "" and (body .. "\n") or "") .. hint

			if card and card:IsAlive() then
				card:Update({ Title = title, Content = body })
				card:SetProgress(cur / n)
			else
				local spec = {
					Key = "spectre_tour", Title = title, Content = body, Kind = "Info", Duration = 0, Progress = cur / n,
					Closable = true, CloseOnClick = false,
					OnClick = function() handle:Next() end,
					OnClose = function() if not finishing then handle:Stop() end end,
				}
				if opts.Position then spec.Position = opts.Position end
				card = win:Notify(spec)
			end
		end

		function handle:Next()
			if not running then return handle end
			if cur >= n then return handle:Finish() end
			show(cur + 1)
			return handle
		end
		function handle:Prev() if running and cur > 1 then show(cur - 1) end return handle end
		function handle:Goto(i) if running and tonumber(i) then show(i) end return handle end
		function handle:Step() return cur, n end
		function handle:IsRunning() return running end
		function handle:Finish()
			if not running then return handle end
			close()
			if opts.Toast ~= false then pcall(function() win:Toast(opts.DoneText or "Tour finished", "Success") end) end
			safe(opts.OnDone, true)
			return handle
		end
		function handle:Stop(silent)
			if not running then return handle end
			close()
			if not silent then safe(opts.OnDone, false) end
			return handle
		end
		handle.Destroy = handle.Stop

		if opts.Keys then
			conn = UserInputService.InputBegan:Connect(function(inp, gp)
				if gp or not running then return end
				if inp.KeyCode == Enum.KeyCode.Right then handle:Next() elseif inp.KeyCode == Enum.KeyCode.Left then handle:Prev() end
			end)
			table.insert(win.Conns, conn)
		end

		win._tour = handle
		show(tonumber(opts.Start) or 1)
		return handle
	end

	-- clean up with the window
	local _prevDestroyHUD = Window.Destroy
	function Window:Destroy()
		if self._tour then pcall(function() self._tour:Stop(true) end) end
		if self._watermark then pcall(function() self._watermark:Destroy() end) end
		if self._kblist then pcall(function() self._kblist:Destroy() end) end
		if self._hud then pcall(function() self._hud:Destroy() end) self._hud = nil end
		return _prevDestroyHUD(self)
	end

	-- Library:X(...) = newest window
	for _, nm in ipairs({ "Watermark", "KeybindList", "Tour" }) do
		Library[nm] = function(self, ...)
			local w = self.Windows[#self.Windows]
			if w then return w[nm](w, ...) end
			return nil
		end
	end

	Library:AddCommand({
		Name = "Toggle watermark", Desc = "HUD", Keywords = "watermark fps ping hud overlay",
		Callback = function()
			local w = Library.Windows[#Library.Windows]
			if w and w._watermark then w._watermark:Toggle() end
		end,
	})
	Library:AddCommand({
		Name = "Toggle keybind list", Desc = "HUD", Keywords = "keybind list keys hud overlay",
		Callback = function()
			local w = Library.Windows[#Library.Windows]
			if w and w._kblist then w._kblist:Toggle() end
		end,
	})
end

------------------------------------------------------------ Stepper + Stat controls (v3.12)
-- Section:CreateStepper({ Name, Min, Max, Step = 1, Default, Suffix, Wrap = false, Flag, Callback(v) })
--   [ - ] value [ + ]   hold a button to repeat (speeds up).  :Set(v, silent) :Get() :Increment(n) :SetRange(min, max)
-- Section:CreateStat({ Name, Get = fn, Interval = 0.5, Format = fn(v), Prefix, Suffix, Color, Delta = false })
--   live read-out row (gold, kills, fps ...). Polls Get() while the menu is open.  :Refresh() :SetGet(fn) :Get()
do
	local function _num(v)
		if type(v) ~= "number" then return tostring(v) end
		if v == math.floor(v) and math.abs(v) < 1e15 then
			local s, k = tostring(math.floor(v)), nil
			repeat
				s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
			until k == 0
			return s
		end
		return string.format("%.2f", v)
	end

	function Section:CreateStepper(cfg)
		cfg = cfg or {}
		local T = self.Window.Theme
		local touch = UserInputService.TouchEnabled
		local min, max, step = cfg.Min or 0, cfg.Max or 100, cfg.Step or cfg.Increment or 1
		if step <= 0 then step = 1 end
		local suffix = cfg.Suffix or ""
		local value = snap(cfg.Default or min, min, max, step)
		local dec = #((tostring(step):match("%.(%d+)")) or "")
		local h = rowH()
		local boxW = touch and 132 or 116
		local btnW = touch and 36 or 30

		local frame = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, Parent = self.Body })
		new("TextLabel", {
			Size = UDim2.new(1, -(boxW + 8), 1, 0), BackgroundTransparency = 1, Text = cfg.Name or "Stepper", Font = T.Font, TextSize = 14,
			TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
		})
		local box = new("Frame", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromOffset(boxW, h - 4),
			BackgroundColor3 = T.Control, BorderSizePixel = 0, Parent = frame,
		}, { corner(13), stroke(T.Border, 1, 0.4) })
		local function mkBtn(txt, left)
			return new("TextButton", {
				AnchorPoint = Vector2.new(left and 0 or 1, 0), Position = UDim2.fromScale(left and 0 or 1, 0), Size = UDim2.new(0, btnW, 1, 0),
				BackgroundColor3 = T.Accent, BackgroundTransparency = 0.82, AutoButtonColor = false, Text = txt, Font = T.FontBold,
				TextSize = 18, TextColor3 = T.Accent, Parent = box,
			}, { corner(12) })
		end
		local minus, plus = mkBtn("-", true), mkBtn("+", false)
		local valLabel = new("TextLabel", {
			Position = UDim2.fromOffset(btnW, 0), Size = UDim2.new(1, -btnW * 2, 1, 0), BackgroundTransparency = 1, Text = "",
			Font = T.FontBold, TextSize = 13, TextColor3 = T.Text, TextTruncate = Enum.TextTruncate.AtEnd, Parent = box,
		})

		local obj = {}
		local function fmt(v)
			if dec > 0 then return string.format("%." .. dec .. "f", v) .. suffix end
			return tostring(math.floor(v + 0.5)) .. suffix
		end
		local function render()
			valLabel.Text = fmt(value)
			local canDown = cfg.Wrap or value > min
			local canUp = cfg.Wrap or value < max
			minus.TextTransparency = canDown and 0 or 0.65
			plus.TextTransparency = canUp and 0 or 0.65
		end
		local function apply(v, silent)
			if cfg.Wrap then
				if v > max then v = min elseif v < min then v = max end
			end
			v = snap(v, min, max, step)
			local changed = v ~= value
			value = v
			render()
			setFlag(cfg, v)
			if changed and not silent then safe(cfg.Callback, v) end
		end
		function obj:Set(v, silent) if type(v) == "number" then apply(v, silent) end end
		function obj:Get() return value end
		function obj:Increment(n) apply(value + step * (n or 1)) end
		function obj:SetRange(lo, hi)
			min, max = lo, hi
			apply(value, true)
		end

		-- tap = one step (applied on release). Hold 0.4 s = repeat, faster and faster.
		-- If the finger moves (the user is scrolling the page) or the touch is cancelled, nothing happens.
		local function hold(btn, dir)
			local token, cancelled, repeated, mc = 0, false, false, nil
			local start = Vector2.zero
			bindPress(btn, function(i)
				token += 1
				local my = token
				cancelled, repeated = false, false
				start = Vector2.new(i.Position.X, i.Position.Y)
				if mc then mc:Disconnect() end
				mc = i.Changed:Connect(function()
					if (Vector2.new(i.Position.X, i.Position.Y) - start).Magnitude > 10 then cancelled = true end
				end)
				tween(btn, 0.08, { BackgroundTransparency = 0.6 })
				task.spawn(function()
					task.wait(0.4)
					if token ~= my or cancelled then return end
					repeated = true
					local w = 0.14
					while token == my and not cancelled and frame.Parent do
						obj:Increment(dir)
						task.wait(w)
						w = math.max(0.035, w * 0.9)
					end
				end)
			end, function(i)
				if mc then mc:Disconnect() mc = nil end
				local tap = not cancelled and not repeated and not (i and i.UserInputState == Enum.UserInputState.Cancel)
				token += 1
				tween(btn, 0.18, { BackgroundTransparency = 0.82 })
				if tap then obj:Increment(dir) end
			end)
		end
		hold(minus, -1)
		hold(plus, 1)

		render()
		setFlag(cfg, value)
		self:_Register(frame, cfg.Name, h)
		obj.Frame = frame
		return regObj(cfg, obj)
	end

	function Section:CreateStat(cfg)
		if type(cfg) == "function" then cfg = { Get = cfg } end
		cfg = cfg or {}
		local win = self.Window
		local T = win.Theme
		local h = rowH()
		local interval = math.max(0.1, tonumber(cfg.Interval) or 0.5)
		local getter = cfg.Get
		local last, prev

		local frame = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, Parent = self.Body })
		new("TextLabel", {
			Size = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1, Text = cfg.Name or "Stat", Font = T.Font, TextSize = 14,
			TextColor3 = T.SubText, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
		})
		local val = new("TextLabel", {
			AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1,
			RichText = true, Text = "--", Font = T.FontBold, TextSize = 14, TextColor3 = cfg.Color or T.Accent,
			TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
		})

		local obj = {}
		local function render(v)
			local s = cfg.Format and select(2, pcall(cfg.Format, v)) or _num(v)
			s = (cfg.Prefix or "") .. tostring(s) .. (cfg.Suffix or "")
			if cfg.Delta and type(v) == "number" and type(prev) == "number" and v ~= prev then
				local up = v > prev
				local c = Library:GetStatusColor(up and "Success" or "Error")
				local hex = typeof(c) == "Color3"
					and string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
					or (up and "#34D399" or "#F87171")
				s = s .. ('  <font color="%s">%s%s</font>'):format(hex, up and "\u{25B2}" or "\u{25BC}", _num(math.abs(v - prev)))
			end
			val.Text = s
			val.TextColor3 = cfg.Color or win.Theme.Accent
		end
		function obj:Refresh()
			if type(getter) ~= "function" then return end
			local ok, v = pcall(getter)
			if not ok then return end
			if v ~= last then
				prev = last
				last = v
			end
			render(last)
		end
		function obj:SetGet(fn) getter = fn prev, last = nil, nil obj:Refresh() end
		function obj:Get() return last end

		local acc = 0
		local conn
		conn = RunService.Heartbeat:Connect(function(dt)
			if not frame.Parent then conn:Disconnect() return end
			if not win.Visible then return end
			acc += dt
			if acc < interval then return end
			acc = 0
			pcall(obj.Refresh, obj)
		end)
		table.insert(win.Conns, conn)
		obj._cleanup = function() if conn then conn:Disconnect() end end

		obj:Refresh()
		self:_Register(frame, cfg.Name, h)
		obj.Frame = frame
		return obj
	end

	-- same treatment the other controls get: ShowIf / OnChange / Reset / Tooltip / Destroy / context menu
	local decorate, NOVALUE = Library._decorate, Library._NOVALUE
	if not decorate or not NOVALUE then warn("[SpectreUI] Stepper/Stat: decorate not available") return end
	NOVALUE.Stat = true
	for fname, kind in pairs({ CreateStepper = "Stepper", CreateStat = "Stat" }) do
		local orig = Section[fname]
		Section[fname] = function(self, cfg, ...)
			local obj = orig(self, cfg, ...)
			if type(obj) == "table" then
				local dc = type(cfg) == "table" and cfg or (type(cfg) == "string" and { Name = cfg } or {})
				local ok, err = pcall(decorate, self, kind, dc, obj)
				if not ok then warn("[SpectreUI] decorate(" .. kind .. ") failed: " .. tostring(err)) end
				if obj._cleanup and obj.Destroy then
					local d, cl = obj.Destroy, obj._cleanup
					obj.Destroy = function(s, ...) cl() return d(s, ...) end
				end
			end
			return obj
		end
	end
end

Library.Version = "3.13.4"
end

------------------------------------------------------------ v3.13: flag helpers, hotkeys, theme sharing, text size
do
-- ---------------------------------------------------------------- flag helpers
function Library:GetControl(flag) return self.Objects[flag] end

-- Library:SetFlag("aim_on", true, silent) -> ok, err
function Library:SetFlag(flag, value, silent)
	local o = self.Objects[flag]
	if not (o and o.Set) then return false, "unknown flag" end
	local ok, err = pcall(o.Set, o, value, silent)
	if not ok then return false, tostring(err) end
	return true
end

-- Library:ToggleFlag("aim_on") -> ok, newValue | err    (boolean controls only)
function Library:ToggleFlag(flag)
	local o = self.Objects[flag]
	if not (o and o.Get and o.Set) then return false, "unknown flag" end
	local v = o:Get()
	if type(v) ~= "boolean" then return false, "not a boolean flag" end
	local ok, err = Library:SetFlag(flag, not v)
	if not ok then return false, err end
	return true, not v
end

-- Library:SetFlags({ aim_on = true, aim_fov = 90 }, silent) -> number applied   (ONE undo step)
function Library:SetFlags(tbl, silent)
	local n = 0
	if type(tbl) ~= "table" then return 0 end
	self:Transaction("Set flags", function()
		for flag, v in pairs(tbl) do
			if self:SetFlag(flag, v, silent) then n += 1 end
		end
	end)
	return n
end

-- Library:GetFlags() -> copy of every flag value
function Library:GetFlags() return self:Snapshot() end

-- ---------------------------------------------------------------- global hotkeys
Library._hotkeys = {}
local hkConn

local function modsMatch(h)
	local function down(a, b) return UserInputService:IsKeyDown(a) or UserInputService:IsKeyDown(b) end
	local ctrl = down(Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl)
	local shift = down(Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift)
	local alt = down(Enum.KeyCode.LeftAlt, Enum.KeyCode.RightAlt)
	return (not not h.Ctrl) == ctrl and (not not h.Shift) == shift and (not not h.Alt) == alt
end

local function ensureHotkeys()
	if hkConn then return end
	hkConn = UserInputService.InputBegan:Connect(function(i, gp)
		if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
		local typing = UserInputService:GetFocusedTextBox() ~= nil
		for _, h in ipairs(table.clone(Library._hotkeys)) do
			if h.Key == i.KeyCode and not h.Disabled and modsMatch(h) and (h.AllowTyping or (not gp and not typing)) then
				local ok, err = pcall(h.Fn, h)
				if not ok then warn("[SpectreUI] Hotkey error: " .. tostring(err)) end
			end
		end
	end)
end

-- Library:Hotkey(Enum.KeyCode.F4, function() ... end, { Ctrl = false, Shift = false, Alt = false, Desc = "text", AllowTyping = false })
--   -> { Disconnect, SetKey(key), SetEnabled(bool) }
function Library:Hotkey(key, fn, opts)
	opts = opts or {}
	if typeof(key) ~= "EnumItem" or key.EnumType ~= Enum.KeyCode then error("Hotkey: first argument must be an Enum.KeyCode", 2) end
	if type(fn) ~= "function" then error("Hotkey: second argument must be a function", 2) end
	local h = { Key = key, Fn = fn, Ctrl = opts.Ctrl, Shift = opts.Shift, Alt = opts.Alt, Desc = opts.Desc, AllowTyping = opts.AllowTyping }
	table.insert(self._hotkeys, h)
	ensureHotkeys()
	local handle = {}
	function handle:Disconnect()
		local i = table.find(Library._hotkeys, h)
		if i then table.remove(Library._hotkeys, i) end
	end
	function handle:SetKey(k)
		if typeof(k) == "EnumItem" and k.EnumType == Enum.KeyCode then h.Key = k end
	end
	function handle:SetEnabled(v) h.Disabled = not v end
	return handle
end

-- Library:ListHotkeys() -> { { Key = "Ctrl+X", Desc = "..." }, ... }
function Library:ListHotkeys()
	local out = {}
	for _, h in ipairs(self._hotkeys) do
		local parts = {}
		if h.Ctrl then table.insert(parts, "Ctrl") end
		if h.Shift then table.insert(parts, "Shift") end
		if h.Alt then table.insert(parts, "Alt") end
		table.insert(parts, h.Key.Name)
		table.insert(out, { Key = table.concat(parts, "+"), Desc = h.Desc or "" })
	end
	return out
end

local prevUnload = Library.Unload
function Library:Unload(...)
	table.clear(self._hotkeys)
	if hkConn then hkConn:Disconnect() hkConn = nil end
	return prevUnload(self, ...)
end

-- ---------------------------------------------------------------- share a theme as text
local SHARE_KEYS = { "Background", "Panel", "Card", "Control", "Border", "Accent", "Accent2", "AccentSoft", "Sheen", "Text", "SubText" }
local SHARE_FX = { petals = true, orbs = true, embers = true, rain = true, grid = true }
local function toHexC(c)
	return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end
local function fromHexC(str)
	local r, g, b = tostring(str):match("^#?(%x%x)(%x%x)(%x%x)$")
	if not r then return nil end
	return Color3.fromRGB(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16))
end
local function cleanName(n)
	if type(n) ~= "string" then return nil end
	n = n:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%c", "")
	if n == "" then return nil end
	return n:sub(1, 28)
end

-- Library:ExportTheme("Cyber" | themeTable | nil = current default, nameOverride?) -> "SPT1:{...}" | nil, err
function Library:ExportTheme(src, name)
	local t, tname
	if type(src) == "string" then
		t, tname = self.Themes[src], src
	elseif type(src) == "table" then
		t, tname = src, "Shared"
	else
		t, tname = self.Themes[self.ThemeName] or self.Theme, self.ThemeName
	end
	if type(t) ~= "table" then return nil, "unknown theme" end
	local data = { v = 1, name = name or tname, FX = t.FX }
	for _, k in ipairs(SHARE_KEYS) do
		local c = t[k]
		if typeof(c) ~= "Color3" then c = (self.Themes.Rose or {})[k] end   -- partial themes export with the default colour
		if typeof(c) == "Color3" then data[k] = toHexC(c) end
	end
	return "SPT1:" .. HttpService:JSONEncode(data)
end

-- Library:ImportTheme(code, name?) -> ok, finalName | err    registers + saves the theme (does not apply it)
function Library:ImportTheme(code, name)
	if type(code) ~= "string" then return false, "usage: ImportTheme(string, name?)" end
	local body = code:match("^%s*SPT1:(.+)$")
	if not body then return false, "not a SpectreUI theme code" end
	local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
	if not ok or type(data) ~= "table" then return false, "invalid theme code" end
	local t = {}
	for _, k in ipairs(SHARE_KEYS) do
		local c = fromHexC(data[k])
		if not c then return false, "missing or bad colour: " .. k end
		t[k] = c
	end
	t.FX = SHARE_FX[data.FX] and data.FX or "orbs"
	local base = cleanName(name) or cleanName(data.name) or "Imported"
	local final, i = base, 2
	while self.Themes[final] do
		final = base:sub(1, 24) .. " " .. i
		i += 1
	end
	local ok2, err = self:RegisterTheme(final, t)
	if not ok2 then return false, err end
	self:SaveThemes()
	if self._fire then self._fire("list") end
	return true, final
end

-- Window:ExportTheme() -> code of the theme this window uses right now
function Window:ExportTheme() return Library:ExportTheme(self.Theme, self.ThemeName) end

-- Window:ImportTheme(code, name?, apply = true) -> ok, name | err
function Window:ImportTheme(code, name, apply)
	local ok, res = Library:ImportTheme(code, name)
	if not ok then return false, res end
	if apply ~= false then self:SetTheme(res, true) end
	return true, res
end

-- ---------------------------------------------------------------- text size
-- The original size of every text object is kept in an attribute, so 1.0 always restores exactly.
Library.TextScale = Library.TextScale or 1

function Window:_ApplyTextScale(root)
	local s = self._textScale or Library.TextScale or 1
	for _, o in ipairs((root or self.Gui):GetDescendants()) do
		if (o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox")) and not o.TextScaled then
			local base = o:GetAttribute("SpSize")
			if base == nil then
				if s == 1 then continue end
				base = o.TextSize
				o:SetAttribute("SpSize", base)
			end
			o.TextSize = math.max(8, math.floor(base * s + 0.5))
		end
	end
end

-- Window:SetTextScale(0.85, remember) -> ok, scale | err     (0.7 .. 1.4)
function Window:SetTextScale(s, remember)
	s = tonumber(s)
	if not s then return false, "usage: SetTextScale(0.7 .. 1.4)" end
	s = math.clamp(s, 0.7, 1.4)
	self._textScale = s
	self:_ApplyTextScale()
	if remember then
		Library.TextScale = s
		Library:SaveThemes()
	end
	return true, s
end

function Window:GetTextScale() return self._textScale or Library.TextScale or 1 end

-- the ready-made tabs are built last, so a remembered size is applied once they exist
for _, fname in ipairs({ "CreateThemeTab", "CreateSettingsTab", "CreateDefaultTabs" }) do
	local prev = Window[fname]
	if prev then
		Window[fname] = function(self, ...)
			local a, b = prev(self, ...)
			if (self._textScale or Library.TextScale or 1) ~= 1 then self:_ApplyTextScale() end
			return a, b
		end
	end
end
end


------------------------------------------------------------ ItemGrid + AskAmount (v3.14)
-- Section:CreateItemGrid({ Name, CellWidth = 92, CellHeight = 112, Items = { { Name, Amount, Image, Id } }, Empty = "text",
--                          Callback(item), Prefix = "×" })
--   grid of item cards (picture + ×amount badge + name). Tap a card -> Callback(item).  item = { Name, Amount, Image, Id }
--   Image = "lucide:name" | asset id (number) | "rbxassetid://..." | url.  No image -> a box icon.
--   :SetItems(list) (cards are reused, removed ones disappear)  :SetAmount(name, n)  :Clear()  :GetItem(name)  :SetEmpty(text)  :Count()
-- Window:AskAmount({ Title, Content, Max, Default = 1, Confirm = "ยืนยัน", MaxText, Cancel = "ยกเลิก", Icon }) -> amount | nil
--   modal number prompt (input + Confirm / Max / Cancel). Yields: call it from a task.spawn / callback.
do
	function Section:CreateItemGrid(cfg)
		cfg = cfg or {}
		local T = self.Window.Theme
		local CW, CH = cfg.CellWidth or 92, cfg.CellHeight or 100
		local prefix = cfg.Prefix or "×"

		local frame = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Parent = self.Body }, { list(4) })
		if cfg.Name then
			new("TextLabel", {
				LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = cfg.Name, Font = T.Font, TextSize = 14,
				TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
			})
		end
		local grid = new("Frame", { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Parent = frame }, {
			new("UIGridLayout", {
				CellSize = UDim2.fromOffset(CW, CH), CellPadding = UDim2.fromOffset(8, 8),
				SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Left,
			}),
		})
		local empty = new("TextLabel", {
			LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, Text = cfg.Empty or "", Font = T.Font, TextSize = 13,
			TextColor3 = T.SubText, Visible = false, Parent = frame,
		})
		self:_Register(frame, cfg.Name, CH + 20)

		-- cards stretch to fill the row: as many columns as fit (>= 1), width shared evenly
		local gl = grid:FindFirstChildOfClass("UIGridLayout")
		local win = self.Window
		local lastCols, settling = 0, false
		local relayout
		-- while the window is being dragged bigger / smaller the cell size is only changed when the column count
		-- changes (changing it on every pixel re-lays out every card + picture each frame = flicker); one exact
		-- pass runs shortly after the drag ends
		local function settle()
			if settling then return end
			settling = true
			task.delay(0.15, function()
				settling = false
				if win._resizing then settle() else relayout() end
			end)
		end
		relayout = function()
			local sc = (win.Scale and win.Scale.Scale) or 1
			if sc <= 0.01 then return end
			local w = grid.AbsoluteSize.X / sc
			if w <= 0 then return end
			local gap = 8
			local cols = math.max(1, math.floor((w + gap) / (CW + gap) + 0.5)) -- nearest column count, so cards stay close to CellWidth instead of stretching fat
			if win._resizing and cols == lastCols then settle() return end
			lastCols = cols
			local cw = math.max(60, math.floor((w - gap * (cols - 1)) / cols))
			if gl.CellSize.X.Offset ~= cw then gl.CellSize = UDim2.fromOffset(cw, CH) end
			if win._resizing then settle() end
		end
		grid:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
		task.defer(relayout)

		local obj, cards, data = { Frame = frame }, {}, {}

		local function makeImage(parent, img)
			if type(img) == "number" then img = "rbxassetid://" .. img end
			if type(img) == "string" and img ~= "" and not Library:IsIconName(img) then
				return new("ImageLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(40, 40),
					BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Image = img, Parent = parent,
				})
			end
			local ic = Library:IsIconName(img) and img or "lucide:package"
			local im = Library:MakeIcon(Library:ResolveIcon(ic), T.SubText)
			im.AnchorPoint = Vector2.new(0.5, 0.5)
			im.Position = UDim2.fromScale(0.5, 0.5)
			im.Size = UDim2.fromOffset(26, 26)
			im.Parent = parent
			return im
		end

		local function build(item)
			local card = new("TextButton", {
				Name = tostring(item.Name), AutoButtonColor = false, Text = "", BackgroundColor3 = T.Control, BackgroundTransparency = 0.1,
				BorderSizePixel = 0, Parent = grid,
			}, { corner(12), stroke(T.Border, 1, 0.4) })
			local box = new("Frame", {
				Position = UDim2.fromOffset(5, 5), Size = UDim2.new(1, -10, 0, 50), BackgroundColor3 = T.Panel, BackgroundTransparency = 0.3,
				BorderSizePixel = 0, Parent = card,
			}, { corner(9) })
			makeImage(box, item.Image)
			local badge = new("TextLabel", {
				Name = "Badge", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -3, 0, 3), Size = UDim2.fromOffset(0, 18),
				AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = T.Accent, BackgroundTransparency = 0.25, BorderSizePixel = 0,
				Font = T.FontBold, TextSize = 13, TextColor3 = Library.OnAccent(T.Accent), Text = "",
				Parent = box,
			}, { corner(9), padding(6, 0, 6, 0) })
			Library._oa(badge)
			new("TextLabel", {
				Position = UDim2.fromOffset(4, 58), Size = UDim2.new(1, -8, 0, 36), BackgroundTransparency = 1, Text = tostring(item.Name),
				Font = T.FontMedium or T.Font, TextSize = 12, TextColor3 = T.Text, TextWrapped = true, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card,
			})
			feedback(card, card, "BackgroundColor3", T.Control, T.Lift, T.AccentSoft, true)
			strokeFeedback(card, card:FindFirstChildOfClass("UIStroke"), 0.4, 0.05)
			card.MouseButton1Click:Connect(function()
				local it = data[item.Name]
				if it then safe(cfg.Callback, it) end
			end)
			return card
		end

		local function paint(name)
			local it, card = data[name], cards[name]
			if it and card then
				local badge = card:FindFirstChild("Badge", true)
				if badge then badge.Text = prefix .. tostring(it.Amount or 0) end
			end
		end

		function obj:SetItems(list_)
			local seen, n = {}, 0
			for i, it in ipairs(list_ or {}) do
				local key = it.Name
				seen[key] = true
				data[key] = { Name = key, Amount = it.Amount, Image = it.Image, Id = it.Id }
				if not cards[key] then cards[key] = build(data[key]) end
				cards[key].LayoutOrder = i
				paint(key)
				n += 1
			end
			for key, card in pairs(cards) do
				if not seen[key] then
					card:Destroy()
					cards[key], data[key] = nil, nil
				end
			end
			empty.Visible = n == 0 and (cfg.Empty or "") ~= ""
			frame.Visible = true
		end
		function obj:SetAmount(name, amount)
			if data[name] then data[name].Amount = amount paint(name) end
		end
		function obj:Clear() obj:SetItems({}) end
		function obj:GetItem(name) return data[name] end
		function obj:Count()
			local n = 0
			for _ in pairs(data) do n += 1 end
			return n
		end
		function obj:SetEmpty(text)
			cfg.Empty = text
			empty.Text = text or ""
			empty.Visible = obj:Count() == 0 and (text or "") ~= ""
		end

		if cfg.Items then obj:SetItems(cfg.Items) end
		if cfg.Items and #cfg.Items == 0 then empty.Visible = (cfg.Empty or "") ~= "" end
		return obj
	end

	function Window:AskAmount(cfg)
		cfg = cfg or {}
		local max = tonumber(cfg.Max)
		local content = cfg.Content
		if not content and max then content = "มีทั้งหมด: " .. max end
		local buttons = { { Text = cfg.Confirm or "ยืนยัน", Value = "ok", Style = "Primary" } }
		if max then buttons[#buttons + 1] = { Text = (cfg.MaxText or "ทั้งหมด") .. " (" .. max .. ")", Value = "max", Style = "Secondary" } end
		buttons[#buttons + 1] = { Text = cfg.Cancel or "ยกเลิก", Value = "cancel", Style = "Secondary" }
		local dlg = self:Dialog({
			Title = cfg.Title or "ใส่จำนวน", Content = content or "", Kind = cfg.Kind or "Info", Icon = cfg.Icon,
			Input = { Placeholder = "จำนวน", Default = tostring(cfg.Default or 1), Numeric = true, MaxLength = 9, AutoFocus = true },
			Buttons = buttons,
		})
		local value, text = dlg:Wait()
		if value == "max" and max then return math.floor(max) end
		if value ~= "ok" then return nil end
		local n = math.floor(tonumber(text) or 0)
		if n <= 0 then return nil end
		if max and n > max then n = math.floor(max) end
		return n
	end

end


------------------------------------------------------------ v3.14: more controls + window helpers
do
local V2 = Vector2.new

local function clipCopy(win, text, title)
	text = tostring(text)
	if type(setclipboard) == "function" then
		pcall(setclipboard, text)
		if win then
			local shown = #text > 48 and (text:sub(1, 45) .. "...") or text
			pcall(function() win:Notify({ Title = title or "Copied", Content = shown, Kind = "Success", Duration = 1.6 }) end)
		end
		return true
	end
	if win then
		pcall(function() win:Notify({ Title = "Clipboard not supported", Kind = "Warning", Duration = 3 }) end)
	end
	return false
end

-- Library:Copy(text, title) -> bool   copy to the clipboard + a small "Copied" card (works without a window too)
function Library:Copy(text, title)
	return clipCopy(Library.Windows[#Library.Windows], text, title)
end

local function statusColor(kind, fallback)
	local ok, c = pcall(function() return Library:GetStatusColor(kind) end)
	if ok and typeof(c) == "Color3" then return c end
	return fallback
end

local function clampLen(s, n)
	local len = utf8.len(s)
	if not len then return s:sub(1, n) end
	if len <= n then return s end
	return s:sub(1, utf8.offset(s, n + 1) - 1)
end

local function caption(parent, T, text)
	return new("TextLabel", {
		Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -16, 0, 16), BackgroundTransparency = 1, Text = tostring(text),
		Font = T.Font, TextSize = 13, TextColor3 = T.SubText, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = parent,
	})
end

---------------------------------------------------------------- ButtonRow
-- Section:CreateButtonRow({ Buttons = { { Name, Callback, Color, TextColor, Bold }, ... } })   -> :SetText(i, text)
-- several buttons side by side in ONE row (they share the width equally)
function Section:CreateButtonRow(cfg)
	cfg = cfg or {}
	local T = self.Window.Theme
	local defs = type(cfg.Buttons) == "table" and cfg.Buttons or {}
	if #defs == 0 then defs = { { Name = "Button" } } end
	local n, gap, h = #defs, 6, rowH()
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, Parent = self.Body },
		{ list(gap, { FillDirection = Enum.FillDirection.Horizontal }) })
	local btns = {}
	for i, d in ipairs(defs) do
		if type(d) == "string" then d = { Name = d } end
		local color = d.Color
		local b = new("TextButton", {
			LayoutOrder = i, Size = UDim2.new(1 / n, -math.floor(gap * (n - 1) / n), 1, 0),
			BackgroundColor3 = color or T.Control, BackgroundTransparency = 0.1, AutoButtonColor = false,
			Text = d.Name or "Button", Font = d.Bold and T.FontBold or T.Font, TextSize = 13,
			TextColor3 = d.TextColor or (color and Library.OnAccent(color)) or T.Text,
			TextTruncate = Enum.TextTruncate.AtEnd, ClipsDescendants = true, Parent = row,
		}, { corner(14), stroke(color and color:Lerp(Color3.new(1, 1, 1), 0.3) or T.Border, 1, color and 0.5 or 0.35) })
		local bs = b:FindFirstChildOfClass("UIStroke")
		if color then
			strokeFeedback(b, bs, 0.3, 0.05)
		else
			feedback(b, b, "BackgroundColor3", T.Control, T.Lift, T.AccentSoft)
			strokeFeedback(b, bs, 0.35, 0.05)
		end
		b.MouseButton1Click:Connect(function() safe(d.Callback) end)
		clickRipple(b, nil)
		btns[i] = b
	end
	self:_Register(row, "buttons", h)
	local obj = { Frame = row, Buttons = btns }
	function obj:SetText(i, t)
		if btns[i] then btns[i].Text = tostring(t) end
	end
	return obj
end

---------------------------------------------------------------- InputButton
-- Section:CreateInputButton({ Name, Placeholder, Button = "OK", ButtonWidth, Default, MaxLength, ClearOnSubmit, Trim, Flag, Callback(text) })
-- a text box with its own submit button (key / code entry). Enter submits too.
-- :Get() last submitted text   :GetText() what is typed now   :Set(text, silent)   :Clear()   :Focus()   :SetButtonText(t)
function Section:CreateInputButton(cfg)
	cfg = cfg or {}
	local T = self.Window.Theme
	local h = rowH()
	local hasLabel = cfg.Name ~= nil and cfg.Label ~= false
	local top = hasLabel and 18 or 0
	local frame = new("Frame", { Size = UDim2.new(1, 0, 0, top + h), BackgroundTransparency = 1, Parent = self.Body })
	if hasLabel then caption(frame, T, cfg.Name) end
	local bw = tonumber(cfg.ButtonWidth) or 84
	local boxFrame = new("Frame", {
		Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, -(bw + 6), 0, h), BackgroundColor3 = T.Control,
		BackgroundTransparency = 0.1, BorderSizePixel = 0, ClipsDescendants = true, Parent = frame,
	}, { corner(14), stroke(T.Border, 1, 0.35) })
	local boxStroke = boxFrame:FindFirstChildOfClass("UIStroke")
	local box = new("TextBox", {
		Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 1, 0), BackgroundTransparency = 1, Text = tostring(cfg.Default or ""),
		PlaceholderText = cfg.Placeholder or "", PlaceholderColor3 = T.SubText, Font = T.Font, TextSize = 13, TextColor3 = T.Text,
		TextXAlignment = LEFT, ClearTextOnFocus = false, Parent = boxFrame,
	})
	local btn = new("TextButton", {
		AnchorPoint = V2(1, 0), Position = UDim2.new(1, 0, 0, top), Size = UDim2.fromOffset(bw, h), BackgroundColor3 = T.Accent,
		BackgroundTransparency = 0.05, AutoButtonColor = false, Text = cfg.Button or "OK", Font = T.FontBold, TextSize = 13,
		TextColor3 = Library.OnAccent(T.Accent), TextTruncate = Enum.TextTruncate.AtEnd, ClipsDescendants = true, Parent = frame,
	}, { corner(14), stroke(T.Accent:Lerp(Color3.new(1, 1, 1), 0.3), 1, 0.5) })
	strokeFeedback(btn, btn:FindFirstChildOfClass("UIStroke"), 0.5, 0.05)
	clickRipple(btn, nil)

	local value = box.Text
	local obj = {}
	local function submit()
		local t = box.Text
		if cfg.Trim ~= false then t = t:gsub("^%s+", ""):gsub("%s+$", "") end
		value = t
		setFlag(cfg, value)
		safe(cfg.Callback, value)
		if cfg.ClearOnSubmit then box.Text = "" end
	end
	if cfg.MaxLength then
		box:GetPropertyChangedSignal("Text"):Connect(function()
			local c = clampLen(box.Text, cfg.MaxLength)
			if c ~= box.Text then box.Text = c end
		end)
	end
	box.Focused:Connect(function() tween(boxStroke, 0.15, { Color = T.Accent, Transparency = 0.1 }) end)
	box.FocusLost:Connect(function(enter)
		tween(boxStroke, 0.18, { Color = T.Border, Transparency = 0.35 })
		if enter and cfg.EnterSubmit ~= false then submit() end
	end)
	btn.MouseButton1Click:Connect(submit)

	function obj:Get() return value end
	function obj:GetText() return box.Text end
	function obj:Set(text, silent)
		box.Text = tostring(text == nil and "" or text)
		value = box.Text
		setFlag(cfg, value)
		if not silent then safe(cfg.Callback, value) end
	end
	function obj:Clear() box.Text = "" end
	function obj:Focus() box:CaptureFocus() end
	function obj:SetButtonText(t) btn.Text = tostring(t) end

	setFlag(cfg, value)
	self:_Register(frame, cfg.Name or cfg.Placeholder, top + h)
	obj.Frame = frame
	return regObj(cfg, obj)
end

---------------------------------------------------------------- KeyValue
-- Section:CreateKeyValue({ Name, Value, Color, Copyable = true })   -> :Set(v) / :Get() / :SetColor(c)
-- a static "name ... value" row; tap it to copy the value
function Section:CreateKeyValue(cfg)
	cfg = cfg or {}
	local win = self.Window
	local T = win.Theme
	local h = rowH()
	local copyable = cfg.Copyable ~= false
	local value = cfg.Value == nil and "" or cfg.Value
	local row = new("TextButton", {
		Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = T.Control, BackgroundTransparency = 1, Text = "",
		AutoButtonColor = false, Active = copyable, Parent = self.Body,
	}, { corner(13) })
	if copyable then feedback(row, row, "BackgroundTransparency", 1, 0.82, 0.62, true) end
	new("TextLabel", {
		Position = UDim2.fromOffset(8, 0), Size = UDim2.new(0.42, -8, 1, 0), BackgroundTransparency = 1, Text = cfg.Name or "Key",
		Font = T.Font, TextSize = 14, TextColor3 = T.SubText, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
	})
	local val = new("TextLabel", {
		AnchorPoint = V2(1, 0), Position = UDim2.new(1, -8, 0, 0), Size = UDim2.new(0.58, -8, 1, 0), BackgroundTransparency = 1,
		Text = tostring(value), Font = T.FontBold, TextSize = 14, TextColor3 = cfg.Color or T.Text,
		TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
	})
	if copyable then
		row.MouseButton1Click:Connect(function() clipCopy(win, tostring(value), "Copied") end)
	end
	self:_Register(row, cfg.Name, h)
	local obj = { Frame = row }
	function obj:Set(v)
		value = v == nil and "" or v
		val.Text = tostring(value)
	end
	function obj:Get() return value end
	function obj:SetColor(c) val.TextColor3 = c end
	return obj
end

---------------------------------------------------------------- CodeBlock
-- Section:CreateCodeBlock({ Name, Text, Height = 110, Copy = true, MaxChars = 20000, AutoScroll = true })
-- :Set(text) :Get() :Append(line) :Clear() :Copy()      monospace, scrolls, "Copy" button in the header
function Section:CreateCodeBlock(cfg)
	if type(cfg) == "string" then cfg = { Text = cfg } end
	cfg = cfg or {}
	local win = self.Window
	local T = win.Theme
	local bodyH = tonumber(cfg.Height) or 110
	local showCopy = cfg.Copy ~= false
	local hasHead = cfg.Name ~= nil or showCopy
	local top = hasHead and 22 or 0
	local maxChars = tonumber(cfg.MaxChars) or 20000
	local frame = new("Frame", { Size = UDim2.new(1, 0, 0, top + bodyH), BackgroundTransparency = 1, Parent = self.Body })
	if cfg.Name then
		new("TextLabel", {
			Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -76, 0, 18), BackgroundTransparency = 1, Text = cfg.Name,
			Font = T.Font, TextSize = 13, TextColor3 = T.SubText, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
		})
	end
	local text = tostring(cfg.Text or "")
	local scroll = new("ScrollingFrame", { ElasticBehavior = Enum.ElasticBehavior.Never,
		Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, 0, 0, bodyH), BackgroundColor3 = T.Control, BackgroundTransparency = 0.25,
		BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = T.Accent, CanvasSize = UDim2.new(), AutomaticCanvasSize = AY,
		ScrollingDirection = Enum.ScrollingDirection.Y, Parent = frame,
	}, { corner(10), stroke(T.Border, 1, 0.4), padding(8, 6, 8, 6) })
	local label = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Text = text, Font = Enum.Font.Code, TextSize = 12,
		TextColor3 = T.Text, TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, Parent = scroll,
	})
	local obj = {}
	if showCopy then
		local cb = new("TextButton", {
			AnchorPoint = V2(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(58, 18), BackgroundColor3 = T.Control,
			BackgroundTransparency = 0.1, AutoButtonColor = false, Text = "Copy", Font = T.Font, TextSize = 12, TextColor3 = T.Text,
			ClipsDescendants = true, Parent = frame,
		}, { corner(9), stroke(T.Border, 1, 0.35) })
		feedback(cb, cb, "BackgroundColor3", T.Control, T.Lift, T.AccentSoft)
		cb.MouseButton1Click:Connect(function() obj:Copy() end)
	end
	local function toBottom()
		if cfg.AutoScroll == false then return end
		task.defer(function()
			if scroll.Parent then
				scroll.CanvasPosition = V2(0, math.max(0, scroll.AbsoluteCanvasSize.Y - scroll.AbsoluteSize.Y))
			end
		end)
	end
	function obj:Set(t)
		text = tostring(t == nil and "" or t)
		label.Text = text
	end
	function obj:Get() return text end
	function obj:Append(line)
		line = tostring(line == nil and "" or line)
		text = (text ~= "" and (text .. "\n") or "") .. line
		if #text > maxChars then text = text:sub(#text - maxChars + 1) end
		label.Text = text
		toBottom()
	end
	function obj:Clear()
		text = ""
		label.Text = ""
	end
	function obj:Copy() return clipCopy(win, text, "Copied") end
	self:_Register(frame, cfg.Name or "code", top + bodyH)
	obj.Frame = frame
	return obj
end

---------------------------------------------------------------- Countdown
-- Section:CreateCountdown({ Name, Target = os.time() + 3600 | Seconds = 3600, Format = fn(secondsLeft), ExpiredText, WarnAt, Color, OnDone(obj) })
-- live "time left" row (key expiry, event timer ...).  Target is a unix time (os.time()).
-- :SetTarget(epoch) :SetSeconds(n) :Add(n) :Get() -> seconds left  :IsExpired()      OnDone fires once when it reaches 0
function Section:CreateCountdown(cfg)
	cfg = cfg or {}
	local win = self.Window
	local T = win.Theme
	local h = rowH()
	local target
	if tonumber(cfg.Target) then target = tonumber(cfg.Target)
	elseif tonumber(cfg.Seconds) then target = os.time() + tonumber(cfg.Seconds) end

	local frame = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, Parent = self.Body })
	new("TextLabel", {
		Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1, Text = cfg.Name or "Time left", Font = T.Font, TextSize = 14,
		TextColor3 = T.SubText, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
	})
	local val = new("TextLabel", {
		AnchorPoint = V2(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0.55, 0, 1, 0), BackgroundTransparency = 1, Text = "--",
		Font = T.FontBold, TextSize = 14, TextColor3 = cfg.Color or T.Accent, TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
	})

	local obj = {}
	local done, shown = false, nil
	local function left()
		if not target then return nil end
		return math.max(0, target - os.time())
	end
	local function fmt(s)
		if type(cfg.Format) == "function" then
			local ok, r = pcall(cfg.Format, s)
			if ok and r ~= nil then return tostring(r) end
		end
		local d = math.floor(s / 86400)
		local hh = math.floor((s % 86400) / 3600)
		local mm = math.floor((s % 3600) / 60)
		local ss = math.floor(s % 60)
		if d > 0 then return string.format("%dd %02d:%02d:%02d", d, hh, mm, ss) end
		return string.format("%02d:%02d:%02d", hh, mm, ss)
	end
	local function render()
		local s = left()
		if s == nil then
			if shown ~= "--" then shown = "--" val.Text = "--" end
			return
		end
		local expired = s <= 0
		local text = expired and (cfg.ExpiredText or "Expired") or fmt(s)
		if text ~= shown then shown = text val.Text = text end
		local col = cfg.Color or win.Theme.Accent
		if expired then col = statusColor("Error", Color3.fromRGB(248, 113, 113))
		elseif cfg.WarnAt and s <= cfg.WarnAt then col = statusColor("Warning", Color3.fromRGB(250, 204, 21)) end
		val.TextColor3 = col
		if expired and not done then
			done = true
			safe(cfg.OnDone, obj)
		elseif not expired then
			done = false
		end
	end
	function obj:SetTarget(epoch) target = tonumber(epoch) done = false render() end
	function obj:SetSeconds(sec) target = os.time() + (tonumber(sec) or 0) done = false render() end
	function obj:Add(sec) target = (target or os.time()) + (tonumber(sec) or 0) render() end
	function obj:Get() return left() or 0 end
	function obj:IsExpired() local s = left() return s ~= nil and s <= 0 end

	local acc, conn = 0, nil
	conn = RunService.Heartbeat:Connect(function(dt)
		if not frame.Parent then conn:Disconnect() return end
		acc += dt
		if acc < 0.5 then return end
		acc = 0
		pcall(render)
	end)
	table.insert(win.Conns, conn)
	obj._cleanup = function() if conn then conn:Disconnect() end end

	self:_Register(frame, cfg.Name or "countdown", h)
	obj.Frame = frame
	render()
	return obj
end

---------------------------------------------------------------- ListBox
-- Section:CreateListBox({ Name, Items = { "a", "b" }, Height = 120, Multi, Search, AllowDeselect, Default, Empty, Flag, Callback(value) })
-- scrolling pick-list. Single: value is a string (nil = nothing). Multi: value is an array.
-- :Get() :Set(value, silent) :Clear(silent) :Refresh(items, keep = true) :Add(item) :Remove(item) :GetItems() :Count()
function Section:CreateListBox(cfg)
	cfg = cfg or {}
	local win = self.Window
	local T = win.Theme
	local multi = cfg.Multi == true
	local listH = tonumber(cfg.Height) or 120
	local hasSearch = cfg.Search == true
	local rh = UserInputService.TouchEnabled and 34 or 28
	local top = cfg.Name ~= nil and 20 or 0
	local sh = hasSearch and (rowH() - 2) or 0
	local listTop = top + (hasSearch and (sh + 6) or 0)
	local frame = new("Frame", { Size = UDim2.new(1, 0, 0, listTop + listH), BackgroundTransparency = 1, Parent = self.Body })
	if cfg.Name then caption(frame, T, cfg.Name) end

	local searchBox
	if hasSearch then
		local sf = new("Frame", {
			Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, 0, 0, sh), BackgroundColor3 = T.Control, BackgroundTransparency = 0.1,
			BorderSizePixel = 0, ClipsDescendants = true, Parent = frame,
		}, { corner(12), stroke(T.Border, 1, 0.35) })
		searchBox = new("TextBox", {
			Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 1, 0), BackgroundTransparency = 1, Text = "",
			PlaceholderText = cfg.SearchPlaceholder or "Search...", PlaceholderColor3 = T.SubText, Font = T.Font, TextSize = 13,
			TextColor3 = T.Text, TextXAlignment = LEFT, ClearTextOnFocus = false, Parent = sf,
		})
	end
	local scroll = new("ScrollingFrame", { ElasticBehavior = Enum.ElasticBehavior.Never,
		Position = UDim2.fromOffset(0, listTop), Size = UDim2.new(1, 0, 0, listH), BackgroundColor3 = T.Control, BackgroundTransparency = 0.25,
		BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = T.Accent, CanvasSize = UDim2.new(), AutomaticCanvasSize = AY,
		ScrollingDirection = Enum.ScrollingDirection.Y, Parent = frame,
	}, { corner(10), stroke(T.Border, 1, 0.4), list(2), padding(4, 4, 4, 4) })
	local empty = new("TextLabel", {
		LayoutOrder = 1000000, Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Text = cfg.Empty or "No items",
		Font = T.Font, TextSize = 12, TextColor3 = T.SubText, Visible = false, Parent = scroll,
	})

	local items, rows, sel = {}, {}, {}
	local obj = {}

	local function selectedList()
		local out = {}
		for _, n in ipairs(items) do
			if sel[n] then out[#out + 1] = n end
		end
		return out
	end
	local function current()
		if multi then return selectedList() end
		for _, n in ipairs(items) do
			if sel[n] then return n end
		end
		return nil
	end
	local function paint(name)
		local r = rows[name]
		if not r then return end
		local on = sel[name] == true
		tween(r.Btn, 0.14, { BackgroundTransparency = on and 0.15 or 1 })
		tween(r.Label, 0.14, { TextColor3 = on and T.Text or T.SubText })
		r.Bar.Visible = on
	end
	local function emit(silent)
		setFlag(cfg, current())
		if not silent then safe(cfg.Callback, current()) end
	end
	local function toggle(name)
		if multi then
			sel[name] = (not sel[name]) or nil
		elseif sel[name] then
			if not cfg.AllowDeselect then return end
			sel[name] = nil
		else
			for k in pairs(sel) do
				sel[k] = nil
				paint(k)
			end
			sel[name] = true
		end
		paint(name)
		emit(false)
	end
	local function applyFilter()
		local q = searchBox and searchBox.Text:lower() or ""
		q = q:gsub("^%s+", ""):gsub("%s+$", "")
		local any = false
		for _, n in ipairs(items) do
			local r = rows[n]
			if r then
				local vis = q == "" or n:lower():find(q, 1, true) ~= nil
				r.Btn.Visible = vis
				any = any or vis
			end
		end
		empty.Visible = not any
		empty.Text = (#items == 0) and (cfg.Empty or "No items") or "No matches"
	end
	if searchBox then searchBox:GetPropertyChangedSignal("Text"):Connect(applyFilter) end

	local function makeRow(name, order)
		local btn = new("TextButton", {
			LayoutOrder = order, Size = UDim2.new(1, 0, 0, rh), BackgroundColor3 = T.AccentSoft, BackgroundTransparency = 1,
			Text = "", AutoButtonColor = false, Parent = scroll,
		}, { corner(8) })
		local bar = new("Frame", {
			AnchorPoint = V2(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.new(0, 3, 0.55, 0), BackgroundColor3 = T.Accent,
			BorderSizePixel = 0, Visible = false, Parent = btn,
		}, { corner(2) })
		local lab = new("TextLabel", {
			Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -20, 1, 0), BackgroundTransparency = 1, Text = name, Font = T.Font,
			TextSize = 13, TextColor3 = T.SubText, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = btn,
		})
		btn.MouseEnter:Connect(function()
			if usingTouch() or sel[name] then return end
			tween(btn, 0.12, { BackgroundTransparency = 0.6 })
		end)
		btn.MouseLeave:Connect(function()
			if sel[name] then return end
			tween(btn, 0.14, { BackgroundTransparency = 1 })
		end)
		local press = dragSafePress(btn, function() end, function() end, 12)
		btn.MouseButton1Click:Connect(function()
			if press.moved then return end
			toggle(name)
		end)
		rows[name] = { Btn = btn, Label = lab, Bar = bar }
	end
	local function build(src, keep)
		local prev = keep and sel or {}
		for _, r in pairs(rows) do r.Btn:Destroy() end
		rows, items, sel = {}, {}, {}
		local seen = {}
		for _, it in ipairs(type(src) == "table" and src or {}) do
			local name = tostring(type(it) == "table" and (it.Name or it[1]) or it)
			if not seen[name] then
				seen[name] = true
				items[#items + 1] = name
				makeRow(name, #items)
				if prev[name] then sel[name] = true end
			end
		end
		if not multi then
			local first
			for _, n in ipairs(items) do
				if sel[n] then
					if first then sel[n] = nil else first = n end
				end
			end
		end
		for _, n in ipairs(items) do paint(n) end
		applyFilter()
	end
	local function applyValue(v)
		for k in pairs(sel) do sel[k] = nil end
		local want = {}
		if type(v) == "table" then
			for _, n in ipairs(v) do want[tostring(n)] = true end
		elseif v ~= nil and v ~= "" then
			want[tostring(v)] = true
		end
		local picked = false
		for _, n in ipairs(items) do
			if want[n] and (multi or not picked) then
				sel[n] = true
				picked = true
			end
		end
		for _, n in ipairs(items) do paint(n) end
	end

	function obj:Get() return current() end
	function obj:Set(v, silent)
		applyValue(v)
		emit(silent == true)
	end
	function obj:Clear(silent)
		applyValue(nil)
		emit(silent == true)
	end
	function obj:Refresh(src, keep)
		build(src, keep ~= false)
		emit(true)
	end
	function obj:Add(item)
		local copy = table.clone(items)
		copy[#copy + 1] = item
		build(copy, true)
	end
	function obj:Remove(item)
		local name, copy = tostring(item), {}
		for _, n in ipairs(items) do
			if n ~= name then copy[#copy + 1] = n end
		end
		build(copy, true)
		emit(true)
	end
	function obj:GetItems() return table.clone(items) end
	function obj:Count() return #items end

	build(cfg.Items, false)
	if cfg.Default ~= nil then applyValue(cfg.Default) end
	setFlag(cfg, current())
	self:_Register(frame, cfg.Name or "list", listTop + listH)
	obj.Frame = frame
	return regObj(cfg, obj)
end

---------------------------------------------------------------- Table
-- Section:CreateTable({ Name, Columns = { "Item", { Name = "Qty", Width = 0.25 } }, Rows = { { "Sword", 3 } }, Height = 130, RowHeight, Zebra = true, OnRowClick(row, index) })
-- :SetRows(rows) :AddRow(row) :RemoveRow(i) :SetCell(i, col, value) :Clear() :Count() :GetRows()
function Section:CreateTable(cfg)
	cfg = cfg or {}
	local win = self.Window
	local T = win.Theme
	local bodyH = tonumber(cfg.Height) or 130
	local rh = tonumber(cfg.RowHeight) or (UserInputService.TouchEnabled and 30 or 24)
	local top = cfg.Name ~= nil and 20 or 0
	local headH = 24
	local total = top + headH + 4 + bodyH
	local clickable = type(cfg.OnRowClick) == "function"

	local cols = {}
	for i, c in ipairs(type(cfg.Columns) == "table" and cfg.Columns or { "A", "B" }) do
		if type(c) == "table" then
			cols[i] = { Name = tostring(c.Name or c[1] or ""), W = tonumber(c.Width) }
		else
			cols[i] = { Name = tostring(c) }
		end
	end
	local fixed, free = 0, 0
	for _, c in ipairs(cols) do
		if c.W then fixed += c.W else free += 1 end
	end
	local rest = math.max(0.05, 1 - fixed)
	local tot = 0
	for _, c in ipairs(cols) do
		c.S = c.W or (rest / math.max(1, free))
		tot += c.S
	end
	local acc = 0
	for _, c in ipairs(cols) do
		c.S = c.S / tot
		c.X = acc
		acc += c.S
	end

	local frame = new("Frame", { Size = UDim2.new(1, 0, 0, total), BackgroundTransparency = 1, Parent = self.Body })
	if cfg.Name then caption(frame, T, cfg.Name) end
	local head = new("Frame", {
		Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, 0, 0, headH), BackgroundColor3 = T.Control, BackgroundTransparency = 0.3,
		BorderSizePixel = 0, Parent = frame,
	}, { corner(8) })
	for _, c in ipairs(cols) do
		new("TextLabel", {
			Position = UDim2.new(c.X, 8, 0, 0), Size = UDim2.new(c.S, -10, 1, 0), BackgroundTransparency = 1, Text = c.Name,
			Font = T.FontBold, TextSize = 12, TextColor3 = T.SubText, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = head,
		})
	end
	local scroll = new("ScrollingFrame", { ElasticBehavior = Enum.ElasticBehavior.Never,
		Position = UDim2.fromOffset(0, top + headH + 4), Size = UDim2.new(1, 0, 0, bodyH), BackgroundColor3 = T.Control,
		BackgroundTransparency = 0.25, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = T.Accent,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = AY, ScrollingDirection = Enum.ScrollingDirection.Y, Parent = frame,
	}, { corner(10), stroke(T.Border, 1, 0.4), list(0), padding(0, 2, 0, 2) })
	local empty = new("TextLabel", {
		LayoutOrder = 1000000, Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = cfg.Empty or "No data",
		Font = T.Font, TextSize = 12, TextColor3 = T.SubText, Visible = false, Parent = scroll,
	})

	local data, rowFrames, cells = {}, {}, {}
	local obj = {}
	local function makeRow(i)
		local row = data[i]
		local zebra = cfg.Zebra ~= false and i % 2 == 0
		local base = zebra and 0.75 or 1
		local r = new("TextButton", {
			LayoutOrder = i, Size = UDim2.new(1, 0, 0, rh), BackgroundColor3 = T.Lift, BackgroundTransparency = base, Text = "",
			AutoButtonColor = false, Active = clickable, Parent = scroll,
		})
		cells[i] = {}
		for j, c in ipairs(cols) do
			local v = row[j]
			cells[i][j] = new("TextLabel", {
				Position = UDim2.new(c.X, 8, 0, 0), Size = UDim2.new(c.S, -10, 1, 0), BackgroundTransparency = 1,
				Text = v == nil and "" or tostring(v), Font = T.Font, TextSize = 12, TextColor3 = T.Text, TextXAlignment = LEFT,
				TextTruncate = Enum.TextTruncate.AtEnd, Parent = r,
			})
		end
		if clickable then
			r.MouseEnter:Connect(function()
				if usingTouch() then return end
				tween(r, 0.12, { BackgroundColor3 = T.AccentSoft, BackgroundTransparency = 0.5 })
			end)
			r.MouseLeave:Connect(function()
				tween(r, 0.14, { BackgroundColor3 = T.Lift, BackgroundTransparency = base })
			end)
			local press = dragSafePress(r, function() end, function() end, 12)
			r.MouseButton1Click:Connect(function()
				if press.moved then return end
				safe(cfg.OnRowClick, data[i], i)
			end)
		end
		rowFrames[i] = r
	end
	local function rebuild()
		for _, r in ipairs(rowFrames) do r:Destroy() end
		rowFrames, cells = {}, {}
		for i = 1, #data do makeRow(i) end
		empty.Visible = #data == 0
	end
	local function copyRows(src)
		local out = {}
		for _, r in ipairs(type(src) == "table" and src or {}) do
			out[#out + 1] = type(r) == "table" and table.clone(r) or { r }
		end
		return out
	end

	function obj:SetRows(src) data = copyRows(src) rebuild() end
	function obj:AddRow(row)
		data[#data + 1] = type(row) == "table" and table.clone(row) or { row }
		makeRow(#data)
		empty.Visible = false
	end
	function obj:RemoveRow(i)
		if data[i] then
			table.remove(data, i)
			rebuild()
		end
	end
	function obj:SetCell(i, j, v)
		if data[i] and cells[i] and cells[i][j] then
			data[i][j] = v
			cells[i][j].Text = v == nil and "" or tostring(v)
		end
	end
	function obj:Clear() data = {} rebuild() end
	function obj:Count() return #data end
	function obj:GetRows() return copyRows(data) end

	obj:SetRows(cfg.Rows)
	self:_Register(frame, cfg.Name or "table", total)
	obj.Frame = frame
	return obj
end

---------------------------------------------------------------- Image
-- Section:CreateImage({ Image = 123456 | "rbxassetid://.." | "lucide:name", Name, Height = 120, Fit = "Fit"|"Crop"|"Stretch", Corner = 10, Color, IconSize })
-- :Set(image) :Get()
function Section:CreateImage(cfg)
	if type(cfg) == "number" or type(cfg) == "string" then cfg = { Image = cfg } end
	cfg = cfg or {}
	local T = self.Window.Theme
	local imgH = tonumber(cfg.Height) or 120
	local top = cfg.Name ~= nil and 20 or 0
	local frame = new("Frame", { Size = UDim2.new(1, 0, 0, top + imgH), BackgroundTransparency = 1, Parent = self.Body })
	if cfg.Name then caption(frame, T, cfg.Name) end
	local holder = new("Frame", {
		Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, 0, 0, imgH), BackgroundColor3 = T.Control, BackgroundTransparency = 0.25,
		BorderSizePixel = 0, ClipsDescendants = true, Parent = frame,
	}, { corner(tonumber(cfg.Corner) or 10), stroke(T.Border, 1, 0.4) })
	local scaleType = ({ Fit = Enum.ScaleType.Fit, Crop = Enum.ScaleType.Crop, Stretch = Enum.ScaleType.Stretch })[cfg.Fit or "Fit"] or Enum.ScaleType.Fit
	local shownImg, value = nil, cfg.Image
	local function show(img)
		if shownImg then shownImg:Destroy() shownImg = nil end
		if type(img) == "string" and tonumber(img) then img = tonumber(img) end
		if img == nil or img == "" then return end
		if type(img) == "number" or (type(img) == "string" and img:find("^rbxasset")) then
			shownImg = new("ImageLabel", {
				Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = type(img) == "number" and ("rbxassetid://" .. img) or img,
				ScaleType = scaleType, ImageColor3 = cfg.Color or Color3.new(1, 1, 1), Parent = holder,
			})
		elseif Library:IsIconName(img) then
			local desc = Library:ResolveIcon(img)
			if desc then
				local sz = tonumber(cfg.IconSize) or 40
				shownImg = Library:MakeIcon(desc, cfg.Color or T.Text)
				shownImg.AnchorPoint = V2(0.5, 0.5)
				shownImg.Position = UDim2.fromScale(0.5, 0.5)
				shownImg.Size = UDim2.fromOffset(sz, sz)
				shownImg.Parent = holder
			end
		end
	end
	show(value)
	self:_Register(frame, cfg.Name or "image", top + imgH)
	local obj = { Frame = frame }
	function obj:Set(img) value = img show(img) end
	function obj:Get() return value end
	return obj
end

---------------------------------------------------------------- Window / Tab / Library helpers
local function tabOf(win, nameOrTab)
	return type(nameOrTab) == "string" and win:GetTab(nameOrTab) or nameOrTab
end

-- Window:RemoveTab(nameOrTab) -> bool   destroys the tab, its page and its controls (the open tab moves to the next unlocked one)
function Window:RemoveTab(nameOrTab)
	local t = tabOf(self, nameOrTab)
	local idx = t and table.find(self.Tabs, t)
	if not idx then return false end
	local wasActive = self.Active == t
	if wasActive then self.Active = nil end
	table.remove(self.Tabs, idx)
	if self._index then
		for i = #self._index, 1, -1 do
			local e = self._index[i]
			if e.Tab == t then
				if e.Flag and Library.Objects[e.Flag] == e.Obj then Library.Objects[e.Flag] = nil end
				table.remove(self._index, i)
			end
		end
	end
	pcall(function() t.Button:Destroy() end)
	pcall(function() t.Page:Destroy() end)
	for i, tab in ipairs(self.Tabs) do tab.Button.LayoutOrder = i end
	if wasActive then
		for _, o in ipairs(self.Tabs) do
			if not o._locked then self:SelectTab(o) break end
		end
	end
	return true
end

-- Window:RenameTab(nameOrTab, newName) -> bool   (false if the name is empty or already used by another tab)
function Window:RenameTab(nameOrTab, newName)
	local t = tabOf(self, nameOrTab)
	if not t or type(newName) ~= "string" or newName == "" then return false end
	local other = self:GetTab(newName)
	if other and other ~= t then return false end
	t.Name = newName
	t.Label.Text = newName
	if self._index then
		for _, e in ipairs(self._index) do
			if e.Tab == t then e.TabName = newName end
		end
	end
	return true
end

-- Window:ListTabs() -> { "Main", "VIP", ... }
function Window:ListTabs()
	local out = {}
	for _, t in ipairs(self.Tabs) do out[#out + 1] = t.Name end
	return out
end

function Tab:Remove() return self.Window:RemoveTab(self) end
function Tab:Rename(name) return self.Window:RenameTab(self, name) end

-- Window:SetToggleKey(Enum.KeyCode | "F4") -> key | nil   /   Window:GetToggleKey()
function Window:SetToggleKey(key)
	if type(key) == "string" then
		local ok, k = pcall(function() return Enum.KeyCode[key] end)
		key = ok and k or nil
	end
	if typeof(key) ~= "EnumItem" or key.EnumType ~= Enum.KeyCode then return nil end
	self.Cfg.ToggleKey = key
	return key
end
function Window:GetToggleKey() return self.Cfg.ToggleKey or Enum.KeyCode.RightShift end

-- Window:Open() / Close() / IsOpen()
function Window:Open() self:SetVisible(true) end
function Window:Close() self:SetVisible(false) end
function Window:IsOpen() return self.Visible == true end

---------------------------------------------------------------- same extras every other control gets (ShowIf / OnChange / Reset / Tooltip / Destroy / right-click menu)
local decorate, NOVALUE = Library._decorate, Library._NOVALUE
if not decorate or not NOVALUE then
	warn("[SpectreUI] v3.14 controls: decorate not available")
else
	for _, k in ipairs({ "ButtonRow", "KeyValue", "CodeBlock", "Countdown", "Table", "Image" }) do NOVALUE[k] = true end
	local kinds = {
		CreateButtonRow = "ButtonRow", CreateInputButton = "InputButton", CreateKeyValue = "KeyValue", CreateCodeBlock = "CodeBlock",
		CreateCountdown = "Countdown", CreateListBox = "ListBox", CreateTable = "Table", CreateImage = "Image",
	}
	for fname, kind in pairs(kinds) do
		local orig = Section[fname]
		Section[fname] = function(self, cfg, ...)
			local obj = orig(self, cfg, ...)
			if type(obj) == "table" then
				local dc = type(cfg) == "table" and cfg or (type(cfg) == "string" and { Name = cfg } or {})
				local ok, err = pcall(decorate, self, kind, dc, obj)
				if not ok then warn("[SpectreUI] decorate(" .. kind .. ") failed: " .. tostring(err)) end
				if obj._cleanup and obj.Destroy then
					local d, cl = obj.Destroy, obj._cleanup
					obj.Destroy = function(s, ...) cl() return d(s, ...) end
				end
			end
			return obj
		end
	end
end

Library.Version = "3.14.0"
end

------------------------------------------------------------ Splash / launch screen (v3.16)
-- Plain launch screen shown while CreateWindow builds the UI: logo, name, thin progress bar, one status line.
-- No particles / glitch / HUD frames; short fade in and fade out. A gradient card sits behind it (Splash = { Panel = false } to remove);
-- taps pass through to whatever is underneath while it shows (Splash = { Block = true } blocks them).
--   Library:CreateWindow({ Splash = false })                       skip it for this window
--   Library:CreateWindow({ Splash = { Title = "SPECTREWARE", Subtitle = "ANIME ASTRAL", Duration = 2.5,
--       Steps = { "Checking key", "Loading" }, Logo = 123456, Skippable = true, Async = false } })
--       Async = true -> the window is built at once and the splash plays on top of it
--   Backdrop = 1 (fully transparent, default) .. 0 (solid theme background)
--   Colours: follows the UI theme the player chose / saved earlier (Library:SetTheme, themes.json, CreateWindow({ Theme = ... })).
--            With no theme chosen it uses Mono (grey / white). Splash = { Theme = "Cyber" } forces one preset;
--            Library.Splash.Theme = "Mono" (default) is that fallback; set it to false to always use the UI default theme instead.
--   Library.Splash.Enabled = false  /  .Duration  /  .Steps  /  .Skippable  /  .Async   global defaults
do
	local TS, RS, UIS = game:GetService("TweenService"), game:GetService("RunService"), game:GetService("UserInputService")
	local Plrs, CG = game:GetService("Players"), game:GetService("CoreGui")
	local S = { Enabled = true, Duration = 4, Skippable = true, Async = false, Backdrop = 1, Theme = "Mono", Panel = true, Block = false,
		Steps = { "Loading", "Preparing interface", "Almost ready" } }
	Library.Splash = S
	local EZ, ED, V2, U2 = Enum.EasingStyle, Enum.EasingDirection, Vector2.new, UDim2.new
	local MONO = { Background = Color3.fromRGB(10, 10, 12), Accent = Color3.fromRGB(228, 228, 237), Accent2 = Color3.fromRGB(161, 161, 178),
		Text = Color3.fromRGB(244, 244, 248), SubText = Color3.fromRGB(150, 150, 164) }

	local function mk(cls, p, kids)
		local i = Instance.new(cls)
		for k, v in pairs(p) do if k ~= "Parent" then i[k] = v end end
		for _, c in ipairs(kids or {}) do c.Parent = i end
		i.Parent = p.Parent
		return i
	end
	local function fr(p, kids) p.BorderSizePixel = 0 return mk("Frame", p, kids) end
	local function lb(p, kids) p.BackgroundTransparency, p.BorderSizePixel, p.Font = 1, 0, p.Font or Enum.Font.Gotham return mk("TextLabel", p, kids) end
	local function round(px) return mk("UICorner", { CornerRadius = UDim.new(0, px) }) end
	local function tw(o, sec, p, st, dir)
		local t = TS:Create(o, TweenInfo.new(sec, st or EZ.Quad, dir or ED.Out), p)
		t:Play()
		return t
	end

	local function play(cfg, build, ctx)
		local o = type(cfg.Splash) == "table" and cfg.Splash or {}
		local function opt(k) if o[k] ~= nil then return o[k] end return S[k] end
		-- theme colours: the player's chosen / saved UI theme, otherwise Mono
		if not Library._themesLoaded then pcall(Library.LoadThemes, Library, true) end   -- the splash runs before the window, so read the saved theme now
		local ov = o.Theme ~= nil and o.Theme or cfg.Theme
		local base
		if type(ov) == "string" then base = Library.Themes[ov] ov = nil end
		if not base then
			if type(ov) == "table" or Library._userSetTheme or Library._themeFromSave or not S.Theme then
				base = Library.Theme                          -- explicit overrides / a theme the player set or saved
			else
				base = Library.Themes[S.Theme] or MONO         -- nothing chosen yet: Mono
			end
		end
		local function C(k, d) return (type(ov) == "table" and ov[k]) or base[k] or d end
		local white = Color3.new(1, 1, 1)
		local acc = C("Accent", Color3.fromRGB(139, 92, 246))
		local acc2 = C("Accent2", acc)
		local txt = C("Text", white)
		local subc = C("SubText", Color3.fromRGB(160, 160, 180))
		local bgc = C("Background", Color3.fromRGB(10, 10, 16))
		local onAcc = Library.OnAccent and Library.OnAccent(acc, acc2) or white

		local title = tostring(cfg.Title or "SpectreUI")
		local brand, sub = title:match("^(.-)%s*|%s*(.+)$")
		brand = tostring(o.Title or brand or title)
		sub = (o.Subtitle or sub) and tostring(o.Subtitle or sub) or ""
		local steps = opt("Steps")
		if type(steps) ~= "table" or #steps == 0 then steps = { "Loading" } end
		local D = math.max(1, tonumber(opt("Duration")) or 4)
		local logoId = o.Logo or cfg.Logo
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or V2(1280, 720)

		local gui = mk("ScreenGui", { Name = "SpectreUI_Splash", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 1000, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
		pcall(function() gui.ScreenInsets = Enum.ScreenInsets.None end)
		Library._mount(gui)
		ctx.gui = gui
		-- watchdog: the launch screen can never stay up, whatever happens while the window builds
		task.delay(D + 12, function() if gui.Parent then pcall(gui.Destroy, gui) end end)

		-- flat backdrop + one centered group (fades as a whole)
		local bg = fr({ Name = "BG", Size = U2(1, 0, 1, 0), BackgroundColor3 = bgc, BackgroundTransparency = 1, Active = opt("Block") == true, Parent = gui })
		local stack = mk("CanvasGroup", { Name = "Stack", AnchorPoint = V2(0.5, 0.5), Position = U2(0.5, 0, 0.5, 10), Size = U2(0, 280, 0, 172),
			BackgroundTransparency = 1, BorderSizePixel = 0, GroupTransparency = 1, Parent = bg })
		local sc0 = math.clamp(math.min(vp.X / 760, vp.Y / 520), 0.8, 1.15)
		local stackScale = mk("UIScale", { Scale = sc0, Parent = stack })

		-- card behind the logo: gradient fill only (no border, no glow). Pure frames (no loops), fades with the rest.
		-- Splash = { Panel = false } turns it off. Taps pass through the splash unless Splash = { Block = true }.
		local panel, panelScales
		if opt("Panel") ~= false then
			local PW, PH = 344, 240
			panel = fr({ Name = "Panel", AnchorPoint = V2(0.5, 0.5), Position = U2(0.5, 0, 0.5, 10), Size = U2(0, PW, 0, PH),
				BackgroundColor3 = white, BackgroundTransparency = 1, Active = false, ZIndex = 0, Parent = bg }, { round(22) })
			mk("UIGradient", { Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, bgc:Lerp(acc, 0.22)), ColorSequenceKeypoint.new(0.55, bgc:Lerp(acc2, 0.06)),
				ColorSequenceKeypoint.new(1, bgc:Lerp(Color3.new(0, 0, 0), 0.25)) }), Rotation = 90, Parent = panel })
			panelScales = { mk("UIScale", { Scale = sc0, Parent = panel }) }
		end

		-- soft outline so the text stays readable on a transparent backdrop
		local function shadow() return mk("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1, Transparency = 0.55 }) end

		-- effects: pulsing glow + two counter-rotating comet rings + breathing logo
		local CY = 48
		local glow = fr({ AnchorPoint = V2(0.5, 0.5), Position = U2(0.5, 0, 0, CY), Size = U2(0, 92, 0, 92), BackgroundColor3 = acc,
			BackgroundTransparency = 0.85, Parent = stack }, { mk("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		local function ring(size, thick, c1, c2)
			local r = fr({ AnchorPoint = V2(0.5, 0.5), Position = U2(0.5, 0, 0, CY), Size = U2(0, size, 0, size), BackgroundTransparency = 1, Parent = stack },
				{ mk("UICorner", { CornerRadius = UDim.new(1, 0) }) })
			local st = mk("UIStroke", { Color = white, Thickness = thick, Parent = r })
			return mk("UIGradient", { Color = ColorSequence.new(c1, c2),
				Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.55, 1), NumberSequenceKeypoint.new(1, 1) }),
				Parent = st })
		end
		local ringA = ring(78, 2.5, acc, acc2)
		local ringB = ring(66, 1.5, acc2, acc)

		-- logo: custom image, or the first letter on a flat accent tile
		local logo
		if logoId then
			local id = tonumber(logoId)
			logo = mk("ImageLabel", { AnchorPoint = V2(0.5, 0.5), Position = U2(0.5, 0, 0, CY), Size = U2(0, 56, 0, 56), BackgroundTransparency = 1,
				Image = id and ("rbxassetid://" .. id) or tostring(logoId), Parent = stack }, { round(14) })
		else
			local okc, ch = pcall(function() return utf8.char(utf8.codepoint(brand, 1)) end)
			logo = fr({ AnchorPoint = V2(0.5, 0.5), Position = U2(0.5, 0, 0, CY), Size = U2(0, 56, 0, 56), BackgroundColor3 = acc, Parent = stack }, { round(14) })
			lb({ Size = U2(1, 0, 1, 0), Text = okc and ch:upper() or "S", Font = Enum.Font.GothamBold, TextSize = 28, TextColor3 = onAcc, Parent = logo })
		end
		local logoScale = mk("UIScale", { Parent = logo })

		lb({ Position = U2(0, 0, 0, 90), Size = U2(1, 0, 0, 26), Text = brand, Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = txt, Parent = stack }, { shadow() })
		if sub ~= "" then
			lb({ Position = U2(0, 0, 0, 117), Size = U2(1, 0, 0, 16), Text = sub, TextSize = 12, TextColor3 = subc, Parent = stack }, { shadow() })
		end

		local status = lb({ Position = U2(0, 0, 0, 142), Size = U2(0, 200, 0, 14), Text = steps[1], TextSize = 13, TextColor3 = subc,
			TextXAlignment = Enum.TextXAlignment.Left, Parent = stack }, { shadow() })
		local pct = lb({ Position = U2(1, -50, 0, 142), Size = U2(0, 50, 0, 14), Text = "0%", TextSize = 13, TextColor3 = subc,
			TextXAlignment = Enum.TextXAlignment.Right, Parent = stack }, { shadow() })
		local track = fr({ Position = U2(0, 0, 0, 162), Size = U2(1, 0, 0, 4), BackgroundColor3 = white, BackgroundTransparency = 0.85, Parent = stack }, { round(2) })
		-- fill is white; the gradient supplies the colour (it multiplies) and a moving highlight
		local fill = fr({ Size = U2(0, 0, 1, 0), BackgroundColor3 = white, Parent = track }, { round(2) })
		local shine = mk("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, acc), ColorSequenceKeypoint.new(0.5, acc2:Lerp(white, 0.6)),
			ColorSequenceKeypoint.new(1, acc2) }), Parent = fill })

		local ver = lb({ AnchorPoint = V2(0.5, 1), Position = U2(0.5, 0, 1, -18), Size = U2(0, 200, 0, 16), TextSize = 12, TextColor3 = subc,
			TextTransparency = 0.6, Text = "v" .. tostring(Library.Version), Parent = bg })

		-- state
		local t, shown, fin, skip, done = 0, 0, false, false, false
		local pcache, lastS = -1, ""
		local hit = panel or bg
		hit.InputBegan:Connect(function(i)
			if opt("Skippable") and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) and t > 0.8 then skip = true end
		end)

		local bd = tonumber(opt("Backdrop")) or 1
		if bd < 1 then tw(bg, 0.25, { BackgroundTransparency = bd }) end   -- default: stays fully transparent
		tw(stack, 0.45, { GroupTransparency = 0, Position = U2(0.5, 0, 0.5, 0) }, EZ.Quint)
		if panel then
			tw(panel, 0.45, { BackgroundTransparency = 0.08, Position = U2(0.5, 0, 0.5, 0) }, EZ.Quint)
		end

		local function step(dt)
			t = t + dt
			if skip and not fin then t = math.max(t, D) end
			local k = math.clamp(t / D, 0, 1)
			local target = fin and 1 or 0.85 * k   -- steady, even pace up to 85%; the last 15% is filled only after the window is really built
			shown = shown + (target - shown) * math.min(1, dt * (skip and 12 or 5))
			fill.Size = U2(shown, 0, 1, 0)
			ringA.Rotation = (t * 240) % 360
			ringB.Rotation = (-t * 150) % 360
			if not done then   -- after the finish burst the tweens own these
				local pl = math.sin(t * 3.2)
				logoScale.Scale = 1 + 0.04 * pl
				glow.BackgroundTransparency = 0.84 + 0.08 * pl
			end
			shine.Offset = V2((t * 0.8) % 1 * 2 - 1, 0)
			local pc = math.floor(shown * 100 + 0.5)
			if pc ~= pcache then pcache = pc pct.Text = pc .. "%" end
			local s
			if fin and shown > 0.97 then s = "Ready"
			else s = steps[math.clamp(math.floor(shown / 0.85 * #steps) + 1, 1, #steps)] end
			if s ~= lastS then lastS = s status.Text = s end
		end
		local function tick() local dt = math.min(RS.Heartbeat:Wait(), 0.1) step(dt) return dt end

		-- "done": no more circles. The rings / glow just fade out and the logo gives a tiny pop,
		-- then the window plays its own launch animation (rise + light sweep + tabs popping in).
		local function burst()
			done = true
			tw(ringA.Parent, 0.22, { Transparency = 1 })
			tw(ringB.Parent, 0.22, { Transparency = 1 })
			tw(glow, 0.22, { BackgroundTransparency = 1 })
			tw(logoScale, 0.2, { Scale = 1.12 }, EZ.Quad, ED.Out)
			task.delay(0.2, function() if gui.Parent then tw(logoScale, 0.2, { Scale = 1 }, EZ.Quad, ED.Out) end end)
		end

		local function exit()
			tw(stackScale, 0.35, { Scale = sc0 * 1.12 }, EZ.Quad, ED.In)   -- slight zoom towards the player while it fades
			tw(stack, 0.3, { GroupTransparency = 1, Position = U2(0.5, 0, 0.5, -6) }, EZ.Quad, ED.In)
			tw(ver, 0.3, { TextTransparency = 1 })
			if panel then
				for _, ps in ipairs(panelScales) do tw(ps, 0.35, { Scale = sc0 * 1.12 }, EZ.Quad, ED.In) end
				tw(panel, 0.3, { BackgroundTransparency = 1, Position = U2(0.5, 0, 0.5, -6) }, EZ.Quad, ED.In)
			end
			task.delay(0.15, function()
				if gui.Parent then tw(bg, 0.35, { BackgroundTransparency = 1 }) end
			end)
		end

		-- main loop: runs until the timeline ends (or the person taps)
		while t < D do tick() end
		-- the bar waits at 85% while the window is built (building blocks the thread for a moment, so it
		-- happens at 85% and not at 100%), then it fills the rest smoothly instead of looking frozen at the end
		local e = 0
		while e < 0.2 do e = e + tick() end   -- let the last frame draw before build() blocks
		if build then build() end   -- real window is created here, hidden behind the splash until the exit starts
		fin = true
		e = 0
		while shown < 0.995 and e < 1.5 do e = e + tick() end
		e = 0
		burst()
		e = 0
		while e < 0.3 do e = e + tick() end   -- brief "Ready", then the window's own launch animation takes over
		task.spawn(function()
			pcall(function()
				exit()
				local x = 0
				while x < 0.6 do x = x + tick() end
			end)
			gui:Destroy()
		end)
	end

	local orig = Library.CreateWindow
	function Library:CreateWindow(cfg)
		cfg = cfg or {}
		if cfg.Splash == false or S.Enabled == false then return orig(self, cfg) end
		local o = type(cfg.Splash) == "table" and cfg.Splash or {}
		local async = o.Async
		if async == nil then async = S.Async end
		local ctx, w = {}, nil
		if async then
			w = orig(self, cfg)
			task.spawn(function()
				local ok, err = xpcall(play, function(e) return debug.traceback(tostring(e), 2) end, cfg, nil, ctx)
				if not ok then warn("[SpectreUI] splash error: " .. tostring(err)) if ctx.gui then ctx.gui:Destroy() end end
			end)
			return w
		end
		local ok, err = xpcall(play, function(e) return debug.traceback(tostring(e), 2) end, cfg, function()
			ctx.built = true
			Library._holdIntro = true
			local okb, res = pcall(orig, self, cfg)
			Library._holdIntro = nil
			if not okb then error(res, 0) end
			w = res
		end, ctx)
		if not ok then
			warn("[SpectreUI] splash error: " .. tostring(err))
			if ctx.gui then ctx.gui:Destroy() end
			if ctx.built and not w then error(err, 0) end
		end
		if not w then w = orig(self, cfg) end
		-- splash finished: show the window and run its launch animation now (tabs created right after still animate in)
		if w and w._introHeld then
			w._introHeld = nil
			pcall(function() w.Gui.Enabled = true end)
			pcall(function() w:_PlayIntro() end)
		end
		return w
	end
end

------------------------------------------------------------ Staged loading (v3.17)
-- Loads the UI in two stages instead of all at once:
--   Stage 1: the tabs appear one by one (sidebar button + empty page with a "Loading" hint).
--   Stage 2: only after EVERY tab is in, each tab's functions run, tab by tab (sections / controls are built here).
--
--   local Main = Window:CreateTab({ Name = "Main", Icon = "lucide:home", Build = function(tab)
--       local s = tab:CreateSection({ Name = "Settings" })
--       s:CreateToggle({ Name = "Example", Flag = "ex" })
--   end })
--   Main:Load(function(tab) ... end)        -- add more functions to a tab (run in order, after all tabs are in)
--   Window:CreateTab({ Name = "Misc" }, function(tab) ... end)   -- Build can also be the 2nd argument
--
--   Window:OnLoaded(fn) · Window:IsLoaded() · Window:WaitLoaded() · Window:StartLoad() (only needed when Auto = false)
--   Library.StagedLoad = { Enabled = true, Auto = true, TabDelay = 0.12, BuildDelay = 0.05, Loading = true,
--                          Placeholder = true, Title = "Loading", TabsText = "Loading tabs", BuildText = "Loading features" }
--   Library:CreateWindow({ StagedLoad = false })  or  { StagedLoad = { TabDelay = 0.2 } }   per window
--   Auto = true: the load starts by itself as soon as the script that creates the tabs yields / finishes.
do
	local S = {
		Enabled = true, Auto = true, TabDelay = 0.12, BuildDelay = 0.05, Loading = true, Placeholder = true,
		Title = "Loading", TabsText = "Loading tabs", BuildText = "Loading features",
	}
	Library.StagedLoad = S

	local function get(win, key)
		local c = win.Cfg and win.Cfg.StagedLoad
		if type(c) == "table" and c[key] ~= nil then return c[key] end
		return S[key]
	end
	local function enabled(win)
		local c = win.Cfg and win.Cfg.StagedLoad
		return not (c == false or S.Enabled == false)
	end
	local function alive(win) return not win._destroyed end
	local function state(win)
		local q = win._sl
		if not q then
			q = { tabs = {}, cbs = {}, running = false, scheduled = false }
			win._sl = q
		end
		return q
	end
	local function runFn(fn, tab)
		local ok, err = pcall(fn, tab)
		if not ok then warn("[SpectreUI] tab '" .. tostring(tab.Name) .. "' load error: " .. tostring(err)) end
		return ok
	end

	-- show one tab button (fade + icon pop)
	local function reveal(tab)
		local btn = tab.Button
		if not btn or not btn.Parent then return end
		btn.Visible = true
		if lowPower() then return end
		local lbl, sc = tab.Label, tab.IconScale
		if lbl then
			lbl.TextTransparency = 1
			tween(lbl, 0.3, { TextTransparency = tab._locked and 0.55 or 0 })
		end
		if sc then
			sc.Scale = 0
			tween(sc, 0.4, { Scale = 1 }, BACK, OUT)
		end
	end

	local function finishTab(tab)
		tab._slLoaded = true
		local h = tab._slHold
		tab._slHold = nil
		if h then pcall(function() h:Destroy() end) end
	end

	local function cycle(win, q)
		local load
		if get(win, "Loading") then
			local ok, h = pcall(function()
				return win:Loading({ Title = get(win, "Title"), Text = get(win, "TabsText"), Progress = 0 })
			end)
			if ok then load = h end
		end
		q.load = load
		local function prog(f, text)
			if load then pcall(function() load:Set(f, text) end) end
		end

		while #q.tabs > 0 and alive(win) do
			local batch, shown = {}, 0

			-- stage 1: tabs, one by one
			while #q.tabs > 0 and alive(win) do
				local tab = table.remove(q.tabs, 1)
				if tab.Button and tab.Button.Parent then
					reveal(tab)
					table.insert(batch, tab)
					shown = shown + 1
					prog(0.5 * shown / (shown + #q.tabs), get(win, "TabsText") .. ": " .. tostring(tab.Name))
					task.wait(get(win, "TabDelay"))
				end
			end

			-- stage 2: every tab is in -> now the functions of each tab, tab by tab
			local done = 0
			local function pending()
				local n = 0
				for _, t in ipairs(batch) do n = n + #t._slBuilds end
				return n
			end
			for _, tab in ipairs(batch) do
				if not alive(win) then break end
				while #tab._slBuilds > 0 and alive(win) do
					local fn = table.remove(tab._slBuilds, 1)
					prog(0.5 + 0.5 * done / (done + pending() + 1), get(win, "BuildText") .. ": " .. tostring(tab.Name))
					runFn(fn, tab)
					done = done + 1
					task.wait(get(win, "BuildDelay"))
				end
				finishTab(tab)
			end
		end

		if load and alive(win) then pcall(function() load:Complete("Ready", 1) end) end
	end

	local run
	run = function(win)
		local q = state(win)
		if q.running or not alive(win) then return end
		q.running = true
		local ok, err = xpcall(cycle, function(e) return debug.traceback(tostring(e), 2) end, win, q)
		q.running = false
		if not ok then
			warn("[SpectreUI] staged load error: " .. tostring(err))
			if q.load then pcall(function() q.load:Fail("Load error", 2) end) end
		end
		if not alive(win) then return end
		if #q.tabs > 0 then return run(win) end   -- tabs created while we were finishing
		win._slLoaded = true
		if win._slCheckWanted and win._QueueCheck then
			win._slCheckWanted = false
			win:_QueueCheck(1.0)
		end
		local cbs = q.cbs
		q.cbs = {}
		for _, f in ipairs(cbs) do safe(f, win) end
	end

	local function schedule(win)
		local q = state(win)
		if q.running or q.scheduled or not get(win, "Auto") then return end
		q.scheduled = true
		task.defer(function()
			q.scheduled = false
			run(win)
		end)
	end

	-- the UI check (AutoCheck) waits until staged loading is finished, otherwise every tab is "empty" while loading
	local origQueueCheck = Window._QueueCheck
	if origQueueCheck then
		function Window:_QueueCheck(delay)
			if self._slLoaded == false then
				self._slCheckWanted = true
				return
			end
			return origQueueCheck(self, delay)
		end
	end

	local origCreateTab = Window.CreateTab
	function Window:CreateTab(cfg, build)
		local tab = origCreateTab(self, cfg)
		if not tab or not enabled(self) then
			if tab and type(build) == "function" then runFn(build, tab) end
			return tab
		end
		local c = type(cfg) == "table" and cfg or {}
		tab._slBuilds = {}
		tab._slLoaded = false
		local fn = build or c.Build or c.Load
		if type(fn) == "function" then table.insert(tab._slBuilds, fn) end

		if tab.Button then tab.Button.Visible = false end   -- stage 1 shows it
		if get(self, "Placeholder") and tab.Page then
			local T = self.Theme
			local ok, h = pcall(function()
				return Instance.new("TextLabel")
			end)
			if ok and h then
				h.Name = "LoadingHint"
				h.AnchorPoint = Vector2.new(0.5, 0.5)
				h.Position = UDim2.fromScale(0.5, 0.5)
				h.Size = UDim2.new(1, -32, 0, 30)
				h.BackgroundTransparency = 1
				h.Text = "Loading..."
				h.Font = T.Font
				h.TextSize = 14
				h.TextColor3 = T.SubText
				h.Parent = tab.Page
				tab._slHold = h
			end
		end

		table.insert(state(self).tabs, tab)
		self._slLoaded = false
		self._slCheckWanted = true
		self._checkSeq = (self._checkSeq or 0) + 1   -- cancels a check that is already waiting; it runs again after loading
		schedule(self)
		return tab
	end

	-- Tab:Load(fn): fn(tab) runs after every tab is in (or right away if this tab is already loaded)
	function Tab:Load(fn)
		if type(fn) ~= "function" then return self end
		if self._slBuilds == nil or self._slLoaded then
			runFn(fn, self)
		else
			table.insert(self._slBuilds, fn)
		end
		return self
	end
	Tab.Build = Tab.Load

	function Window:StartLoad()
		task.spawn(run, self)
		return self
	end
	function Window:IsLoaded() return self._slLoaded ~= false end
	function Window:OnLoaded(fn)
		if type(fn) ~= "function" then return self end
		if self._slLoaded ~= false then
			safe(fn, self)
		else
			table.insert(state(self).cbs, fn)
		end
		return self
	end
	function Window:WaitLoaded()
		while self._slLoaded == false and alive(self) do task.wait() end
		return self
	end
end

return Library
