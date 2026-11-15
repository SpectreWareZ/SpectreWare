# SpectreUI — API Reference

ไลบรารี UI สำหรับ Roblox (Lua) · เอกสารนี้มีเฉพาะ API

## สารบัญ

1. [Entry](#1-entry)
2. [CreateWindow](#2-createwindow)
3. [Window](#3-window)
4. [Tab / Section](#4-tab--section)
5. [Controls](#5-controls)
6. [Flags](#6-flags)
7. [Notify / Dialog / Loading](#7-notify--dialog--loading)
8. [Config / Undo](#8-config--undo)
9. [Theme / Font](#9-theme--font)
10. [SETTINGS Tab](#10-settings-tab)
11. [Command Palette / Hotkey / HUD](#11-command-palette--hotkey--hud)
12. [Staged Loading / Splash](#12-staged-loading--splash)
13. [Tab Password Lock](#13-tab-password-lock)
14. [Load API](#14-load-api)
15. [Audit / Icons](#15-audit--icons)
16. [Library Utilities](#16-library-utilities)
17. [Language](#17-language)
18. [AutoUpdate](#18-autoupdate)
19. [Undocumented](#19-undocumented)

---

## 1. Entry

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/SpectreWareZ/SpectreWare/refs/heads/main/Ui/SpectreUI.lua"))()
local Window  = Library:CreateWindow({ Title = "SpectreWare | Game", ToggleKey = Enum.KeyCode.RightShift })
```

ลำดับ: **Window → Tab → Section → Control**

---

## 2. CreateWindow

`Library:CreateWindow(cfg)`

| ตัวเลือก | ความหมาย |
|---|---|
| `Title` | `"แบรนด์ \| ย่อย"` |
| `Logo` `Width` `Height` | โลโก้ (asset id) / ขนาด |
| `ToggleKey` | ปุ่มเปิด/ปิดเมนู |
| `HideOpenButtonOnPC = true` | ซ่อนปุ่มเปิด UI บน PC (มือถือยังเห็น) · ตั้งทั้งไลบรารี: `Library.HideOpenButtonOnPC` |
| `Theme` `Font` `FX` | ธีม / ฟอนต์ / เอฟเฟกต์ (`petals` `orbs` `grid` `embers` `rain`) · ใส่ `Theme` = บังคับธีมทุกครั้ง |
| `Background = false` | ปิดพื้นหลัง |
| `Resizable = false` | ห้ามปรับขนาด |
| `TwoColumn` / `Compact` | บังคับ 2 คอลัมน์ / โหมดแคบ (มือถือ: `TwoColumn` ต้องใส่ `true` เอง และเนื้อหากว้าง ≥ 520px) |
| `Splash` / `StagedLoad` / `AutoCheck` | ดูหัวข้อ 12 / 12 / 15 |

---

## 3. Window

| เมธอด | ทำอะไร |
|---|---|
| `CreateTab(cfg [, build])` | สร้างแท็บ (`Name` `Icon` `Build` `Locked` `LockReason` `Password`) |
| `AddTab(name, icon?, build?)` | ทางลัดของ `CreateTab` |
| `GetTab` / `SetTab` / `SelectTab` / `ListTabs` | อ่าน / สลับ / รายชื่อแท็บ |
| `RemoveTab` / `RenameTab` | ลบ / เปลี่ยนชื่อแท็บ |
| `LockTab(tab, reason)` / `UnlockTab(tab)` / `IsTabLocked(tab)` | ล็อก / ปลด (จากโค้ด ไม่ต้องใช้รหัส) / เช็ก |
| `Open` / `Close` / `Toggle` / `IsOpen` | เปิด/ปิดเมนู |
| `SetToggleKey(key)` / `GetToggleKey()` | ปุ่มเมนู |
| `SetHideOpenButtonOnPC(bool)` | ซ่อน/แสดงปุ่มเปิดบน PC |
| `SetTitle` `Center` `Resize` `SetSize(w, h)` `SetMaximized` `IsMaximized` `Flash` | หน้าตา / ขนาดหน้าต่าง |
| `SetTwoColumn(bool)` / `SetCompact(bool)` | 2 คอลัมน์ / โหมดแคบ |
| `SetUIScale(0.6–1.6)` / `GetUIScale()` | ขนาด UI ทั้งหมด |
| `SetAnimSpeed(0.25–3)` | ความเร็วอนิเมชัน (= `Library:SetAnimSpeed`) |
| `AddFloatingButton(cfg)` | ปุ่มลอยบนจอ (`Name` `Text` `Toggle` `Default` `Flag` `Position` `Size` `Callback`) · `:Set` `:Get` `:SetText` `:SetVisible` `:Destroy` |
| `Goto(obj \| "flag" \| "ชื่อ")` | กระโดดไป control |
| `OnResize(fn)` / `CloseDropdowns()` | ดักปรับขนาด / ปิด dropdown ที่เปิด |
| `SetBackground("orbs" \| false \| nil)` | เอฟเฟกต์พื้นหลัง (`nil` = ตามธีม) |
| `SetNotifyTheme("Cyber" \| tbl \| nil)` | ธีมสีเฉพาะแจ้งเตือน/Dialog |
| `OpenPalette(initial)` / `ClosePalette()` | Command Palette จากโค้ด |
| `Tooltip(target, text \| fn)` | ผูก tooltip กับ GuiObject (ซ่อนบนมือถือ) |
| `Destroy()` | ทำลายหน้าต่าง · `Library:Unload()` ทำลายทั้งหมด |

---

## 4. Tab / Section

### Tab

| เมธอด | ทำอะไร |
|---|---|
| `tab:CreateSection({ Name, Column = 1 \| 2, Collapsible, Collapsed, Icon })` | สร้าง section |
| `tab:AddSection(name, column?)` | ทางลัดของ `CreateSection` |
| `tab:Build(fn)` / `tab:Load(fn)` | ใส่ control แบบโหลดเป็นขั้น |
| `tab:SetBadge("NEW")` | ป้ายที่แท็บ |
| `tab:ResetAll()` | รีเซ็ตค่าทั้งแท็บ |
| `tab:SetLocked(bool, reason)` / `IsLocked()` / `SetLockReason(text)` | ล็อกแท็บ |
| `tab:SetPassword(pw \| fn, reason)` / `ClearPassword()` / `HasPassword()` / `CheckPassword(x)` | รหัสของแท็บ (ตั้งแล้วล็อกทันที) |
| `tab:TryUnlock(pw)` / `PromptUnlock()` / `Relock()` | ลองปลด / กล่องใส่รหัส / ล็อกกลับ |

### Section

| เมธอด | ทำอะไร |
|---|---|
| `section:SetCollapsed(bool)` | พับ/กาง |
| `section:ResetAll()` | รีเซ็ตค่าทั้ง section |
| `section:CreateSeparator(cfg)` | เส้นคั่น (คู่กับ `CreateDivider`) |
| `section:CreateThemeManager({ Name, Flag, Remember, Random, Delete })` | UI จัดการธีม |
| `section:CreateFontPicker({ Name, Flag, Remember })` | dropdown เลือกฟอนต์ |

---

## 5. Controls

ทุกตัวสร้างจาก section รับ table ตัวเลือก และคืน control กลับมา

### ตัวเลือกร่วม

| ตัวเลือก | ความหมาย |
|---|---|
| `Name` | ชื่อที่แสดง |
| `Default` | ค่าเริ่มต้น |
| `Flag` | ชื่อประจำ control · อ่านผ่าน `Library.Flags["ชื่อ"]` · Config จำค่า (**ไม่มี Flag = ไม่บันทึก**) |
| `Callback` | เรียกเมื่อค่าเปลี่ยน |
| `Tooltip` | ข้อความตอนชี้ |
| `NoMenu = true` | ปิดเมนูคลิกขวา |
| `ContextMenu = {{ Name, Callback(obj) }}` | เพิ่มรายการเมนูคลิกขวา |

### เมธอดร่วม

| เมธอด | ทำอะไร |
|---|---|
| `:Set(v)` / `:Get()` | ตั้ง/อ่านค่า |
| `:SetVisible(b)` / `:ShowIf(flag, value \| fn)` | ซ่อน/แสดง |
| `:SetEnabled(b)` / `:Lock()` / `:Unlock()` | ทำให้จาง + กันการกด |
| `:OnChange(fn(v, prev))` | ดักการเปลี่ยนค่า (ต้องมี `Flag`) |
| `:Reset()` / `:IsModified()` | กลับค่าเริ่มต้น / เช็กว่าถูกแก้ |
| `:Destroy()` | ลบ control |

### สวิตช์ / ตัวเลข

| ใช้ | ตัวเลือก / หมายเหตุ |
|---|---|
| `CreateToggle` | `Default` `Flag` `Callback(on)` |
| `CreateSlider` | `Min` `Max` `Increment` `Suffix` |
| `CreateRangeSlider` | `Default = {lo, hi}` `MinGap` · Callback(lo, hi) |
| `CreateStepper` | `Step` `Wrap` |
| `CreateTubeSlider` | หลอดบาง ปุ่มกลมขอบส้ม · `Min` `Max` `Increment` `Suffix` `NameWidth` `Color` `Color2` · Callback(v) |
| `CreateArcDial` | วงจุด + หัวคน + จุดจับ L/R · ค่า = ครึ่งมุม · `Min` `Max` (0–180) `Default` `Color` `Color2` `ShowInfo` `Format = fn(half) -> main, sub` `Top` `Bottom` `Front` · Callback(half) |

### เลือกจากรายการ

| ใช้ | ตัวเลือก / หมายเหตุ |
|---|---|
| `CreateDropdown` | `Options` `Multi = true` (Default/Callback เป็น list) · `:Refresh(options)` |
| `CreateSegmented` | `Options` · `:SetOptions` |
| `CreateRadio` | `Options` `Default` `AllowNone` · `:Set` `:Get` `:SetOptions(list, keep)` · ทางลัด `sec:Radio(name, options, default, cb, flag)` |
| `CreateListBox` | `Items` `Search` `Multi` · `:Add` `:Remove` |
| `CreateChips` | `Options` `Default` `Multi` `Max` `AllowNone` · `:Set` `:Get` `:Refresh(options)` |
| `CreatePlayerPicker` | `Display = "DisplayName"` `IncludeSelf` `Placeholder` · `:Get` `:GetName` `:Set(player)` `:Refresh` |

### สี / ปุ่มลัด

| ใช้ | ตัวเลือก / หมายเหตุ |
|---|---|
| `CreateColorPicker` | `Default = Color3` |
| `CreateKeybind` | `Mode = "Press" \| "Hold" \| "Toggle"` · `Esc` ยกเลิก · `Backspace` ลบ |
| `CreateKeybindToggle` | `Key` + สวิตช์ในตัวเดียว |

### ข้อความ / ปุ่ม

| ใช้ | ตัวเลือก / หมายเหตุ |
|---|---|
| `CreateTextbox` | `Numeric` `Min` `Max` `Live` `EnterOnly` |
| `CreateInputButton` | `Button` `ClearOnSubmit` |
| `CreateTagInput` | `Lower` `Max` |
| `CreateButton` | `Color` `Gradient` `Bold` `Icon` · `:SetText` |
| `CreateButtonRow` | `Buttons = { {Name, Callback}, ... }` |
| `CreateHoldButton` | `Duration` |

### แสดงผล

| ใช้ | ตัวเลือก / หมายเหตุ |
|---|---|
| `CreateLabel` `CreateParagraph` `CreateBadge` `CreateDivider` | `:Set` |
| `CreateProgress` | `Min` `Max` · `:Set(v)` |
| `CreateRating` | `Max` (5) `Default` `Color` `AllowZero` · `:Set` `:Get` · ทางลัด `sec:Rating(name, max, default, cb, flag)` |
| `CreateStat` | `Get = fn` `Interval` `Delta = true` (ไม่เซฟ Config) |
| `CreateKeyValue` | `Value` `Copyable` |
| `CreateCountdown` | `Target` (epoch) หรือ `Seconds` · `WarnAt` `OnDone` |
| `CreateGraph` | `Points` `Height` · `:Push(n)` |
| `CreatePerformance` | `Interval` (ต่ำสุด 0.2) · `:Get()` → `{ Fps, Ping, Memory }` |
| `CreateStatusCard` | แถบค่าสูงสุด 4 · `:SetBar(i, v, text, color)` `:SetBadge` `:SetEmpty` |

### ตาราง / รูป

| ใช้ | ตัวเลือก / หมายเหตุ |
|---|---|
| `CreateTable` | `Columns` `Rows` `OnRowClick` · `:AddRow` `:SetRows` |
| `CreateItemGrid` | `Items = {{Name, Amount, Image}}` · `:SetAmount` |
| `CreateImage` | `Image` `Height` `Fit` |

### โค้ด / Log / อื่น ๆ

| ใช้ | ตัวเลือก / หมายเหตุ |
|---|---|
| `CreateConsole` | `:Info` `:Warn` `:Error` `:Print` |
| `CreateCodeBlock` | `Text` `Copy` · `:Append` |
| `CreateDiscord` | `Invite` `Button` `Refresh` · `:GetInfo()` |
| `CreateConfigManager` | Save / Load / Delete หลาย Config · คืน `{ Name, List, Refresh }` |

---

## 6. Flags

### อ่าน / ตั้งค่า

```lua
Library.Flags["aim_on"]                       -- อ่านค่า
Library:SetFlag("aim_on", true)               -- ตั้งค่า (arg ที่ 3 = true → ไม่เรียก Callback)
Library:GetControl("aim_on")                  -- control → :Set / :Get
Library:Watch("aim_fov", function(v, prev) end)
Library:GetFlag("aim_fov", 120)               -- อ่านพร้อม fallback
```

### Library

| API | ทำอะไร |
|---|---|
| `GetFlags()` / `HasFlag(flag)` | อ่านทุก Flag / เช็กว่ามี |
| `ToggleFlag(flag)` | สลับค่า |
| `CycleFlag(flag, options, step)` | หมุนค่าไปตัวถัดไป (`step` ติดลบ = ย้อน) คืนค่าใหม่ · ไม่อัปเดต UI เอง → ต่อด้วย `Library:GetControl(flag):Set(v, true)` |
| `OnFlag(fn(flag, v, prev))` | ดักทุก Flag |
| `Bind(flag, fn(v, prev))` | เหมือน `Watch` แต่ยิงทันที 1 ครั้งถ้ามีค่าอยู่แล้ว |
| `WaitFlag(flag, want = true, timeout)` | ยีลด์รอจน Flag ได้ค่า · คืน `false` ถ้าหมดเวลา |

---

## 7. Notify / Dialog / Loading

ใช้ได้ทั้ง `Window:` และ `Library:` (ยกเว้น `AskAmount`)

| API | ทำอะไร |
|---|---|
| `Notify({ Title, Content, Kind, Duration, Progress, Key })` | การ์ดแจ้งเตือน · `Kind` = Success / Warning / Error / Info · `Duration = 0` ค้างจนปิด · `Key` เดียวกัน = อัปเดตการ์ดเดิม |
| `Success` / `Warning` / `Error` / `Info(title, content, dur)` | ทางลัด |
| `Toast("ข้อความ", "Success" \| 3)` | แถบเล็กกลางล่าง |
| `Confirm({ Title, Content, OnYes, OnNo, Danger })` | ถามยืนยัน |
| `Prompt({ Title, Placeholder, OnSubmit, Password, EnterSubmits })` | กล่องพิมพ์ข้อความ |
| `AskAmount({ Title, Max, Default })` | ถามจำนวน → เลข / `nil` (เรียกใน `task.spawn`) · `Window:` เท่านั้น |
| `Dialog(cfg)` | กล่องโต้ตอบเต็มรูปแบบ · `:Wait()` รอผล |
| `Library:Copy(text, title)` | คัดลอก + การ์ด "Copied" |
| `DismissAll()` | ปิดแจ้งเตือนทั้งหมด |
| `Library:Alert(title, content)` | แจ้งปุ่มเดียว |
| `Library:Banner({ Title, Content, Duration, Color })` | แถบบน (ใช้ได้ตอนเมนูปิด) |

### Loading

```lua
local l = Window:Loading({ Title = "กำลังโหลด", Text = "เริ่ม...", Progress = 0 })
l:Set(0.5, "ครึ่งทาง")      -- 0..1 · Set(false) = วนไม่รู้ความคืบหน้า
l:Complete("เสร็จ", 2.5)    -- หรือ l:Fail(...) / l:Close()
```

Loading **ไม่ปิดเอง** จนกว่าจะเรียก `Complete` / `Fail` / `Close`

### ตั้งค่า

| API | ทำอะไร |
|---|---|
| `Library.Sound.Enabled = false` | ปิดเสียง |
| `Library.NotifyConfig` | `Position` `MaxVisible` `Duration` `Gap` `Margin` `Width` `Merge` `PauseOnHover` `Animate` |

---

## 8. Config / Undo

ไฟล์เก็บที่ `SpectreUI/configs/` · เก็บเฉพาะ control ที่มี `Flag`

```lua
Library:SaveConfig("name")      Library:LoadConfig("name", silent)
Library:DeleteConfig("name")    Library:ListConfigs()
Library:ExportConfig()          Library:ImportConfig(json, silent)
Library:SaveAuto("auto")        Library:AutoloadConfig("auto", true)

Window:OnLoaded(function() Library:AutoloadConfig("auto", true) end)
```

> `AutoloadConfig` **ไม่รอ** โหลดครบ → control ที่อยู่ใน `Build` ต้องเรียกใน `Window:OnLoaded`

| API | ทำอะไร |
|---|---|
| `Undo()` / `Redo()` | ย้อน/ทำซ้ำ (`Ctrl+Z` / `Ctrl+Y`) |
| `CanUndo()` / `CanRedo()` | เช็ก |
| `Transaction("ชื่อ", fn)` / `SetFlags({...})` | หลายค่า = Undo ขั้นเดียว |
| `Snapshot("a")` / `Restore("a")` / `Diff("a", "b")` | โปรไฟล์ในหน่วยความจำ / เทียบ |
| `GetHistory()` / `ClearHistory()` | ประวัติ (`Library.History.Max` = จำนวนสูงสุด) |
| `GetModified()` / `ResetAll()` | ค่าที่ถูกแก้ / รีเซ็ตทั้งหมด |

---

## 9. Theme / Font

**ธีมในตัว:** Rose (เริ่มต้น) · Violet · Cyber · Crimson · Matrix · Aurora · Dracula · Nord · TokyoNight · Mocha · Synthwave · Jade · Gold · Lavender · Candy · Peach · Midnight · Ocean · Sunset · Mono

ธีมที่ผู้ใช้เลือกถูกจำใน `themes.json` · `Theme = "..."` ใน `CreateWindow` = บังคับธีมทุกครั้ง

### Window

| API | ทำอะไร |
|---|---|
| `SetTheme(name \| tbl, remember)` | เปลี่ยนธีมสด |
| `CycleTheme(dir)` / `RandomTheme()` | ถัดไป / สุ่ม |
| `ExportTheme()` / `ImportTheme(code, name)` | แชร์ธีมเป็น `SPT1:{...}` |
| `GetThemeName()` / `RenameTheme("ใหม่")` / `DeleteTheme(name?)` | จัดการธีมของหน้าต่าง |
| `SetFont(font, remember)` / `CycleFont(dir)` / `GetFontName()` | ฟอนต์ |
| `SetTextScale(0.7–1.4, remember)` / `GetTextScale()` | ขนาดตัวอักษร (เรียกหลังสร้าง UI) |
| `Window.Theme.Accent` / `.Accent2` | สีหลัก/รองปัจจุบัน |

### Library

| API | ทำอะไร |
|---|---|
| `RegisterTheme(name, tbl)` / `CloneTheme(src, new, overrides)` | เพิ่ม / ทำสำเนา |
| `GetTheme(name?)` / `ListThemes()` / `RenameTheme(old, new)` / `DeleteTheme(name)` | จัดการธีม |
| `OnThemeChange(fn(event, a, b))` | ดักธีมเปลี่ยน |
| `SaveThemes()` / `LoadThemes()` | เซฟ/โหลด `themes.json` |
| `SetStatusColors({ Success = c, ... })` / `GetStatusColor(kind)` | สี Success / Warning / Error / Info |
| `RegisterFont(...)` / `ListFonts()` | ฟอนต์ |
| `OnAccent(Window.Theme)` | สีตัวอักษรอ่านง่ายบนสีธีม |

> ฟอนต์ Roblox รองรับเฉพาะละติน · ภาษาไทยใช้ฟอนต์สำรองของระบบเสมอ

---

## 10. SETTINGS Tab

```lua
local tab, parts = Window:CreateSettingsTab()      -- หรือ Window:CreateDefaultTabs({...})
local mine = tab:CreateSection({ Name = "ของฉัน", Column = 1 })
```

**มี:** ธีมสี · Font/Text size · สร้างธีม · พื้นหลัง/เอฟเฟกต์ · ปุ่มลัด · Interface · Config · Undo/Snapshot · Window (Unload)

| ตัวเลือก | ความหมาย |
|---|---|
| `Sections` | `{ Theme / Hotkeys / Interface / Config / Window / History = false }` ซ่อนทีละส่วน |
| `Maker` / `Effects` / `Fonts` | `false` = ซ่อนส่วนสร้างธีม / เอฟเฟกต์ / ฟอนต์ |
| `Keys` | F6/F5 เปลี่ยนธีม · `false` = ปิด · `{ Next, Prev }` ตั้งเอง |
| `DefaultConfig` / `AutoName` | ชื่อเริ่มต้นของ Config / ไฟล์ auto |
| `WatermarkText` | ข้อความ Watermark |
| `Text` | แปลข้อความ (ใส่เฉพาะคีย์ที่จะเปลี่ยน) |
| `Icons` | เปลี่ยนไอคอน (`false` = ไม่มี) |

**Flag ของระบบ** (คำนำหน้า `ui_`): `ui_menu_key` `ui_bg_fx` `ui_quality` `ui_theme_next` `ui_theme_prev` `ui_watermark` `ui_keybind_list` `ui_notify_pos` `ui_notify_dur`

`Window:CreateThemeTab(cfg)` / `CreateDefaultTabs({ Theme = true })` = แท็บ THEME แยก

---

## 11. Command Palette / Hotkey / HUD

```lua
Library:AddCommand({ Name = "ไปหน้า Config", Keywords = "config save",
    Callback = function() Window:SetTab("SETTINGS") end })

Library:Hotkey(Enum.KeyCode.F4, function() Window:Toggle() end, { Ctrl = true, Desc = "ซ่อน/แสดงเมนู" })

Window:Watermark({ Text = "SpectreWare", Fields = { "FPS", "Ping", "Time" }, Position = "TopRight" })
Window:KeybindList({ Title = "Keybinds", Position = "LeftCenter" })
Window:Tour({ { Tab = "MAIN", Title = "ยินดีต้อนรับ", Content = "..." }, { Target = "aim_on", Title = "...", Content = "..." } })
```

| ปุ่มเริ่มต้น | ทำอะไร |
|---|---|
| `RightShift` (ตั้งที่ `ToggleKey`) | เปิด/ปิดเมนู |
| `Ctrl + K` (`Library.PaletteKey`) | Command Palette |
| `F6` / `F5` | ธีมถัดไป / ก่อนหน้า |
| `Ctrl + Z` / `Ctrl + Y` | Undo / Redo |

**Watermark `Fields`:** `"FPS"` `"Ping"` `"Time"` `"Date"` `"Players"` หรือ `{ Name, Get = fn }`
**Position:** `TopLeft` `TopCenter` `TopRight` `LeftCenter` `RightCenter` `BottomLeft` `BottomCenter` `BottomRight` หรือ `UDim2`

| API | ทำอะไร |
|---|---|
| `Library:ListHotkeys()` | รายชื่อ hotkey |
| `Library:ShowMenu(items, anchorFrame)` / `CloseMenu()` | เมนูคลิกขวาของเรา (`Library.ContextMenu = false` = ปิดทั้งระบบ) |

---

## 12. Staged Loading / Splash

เปิดเป็นค่าเริ่มต้น: แท็บโผล่ทีละอัน แล้วรัน `Build` ของแต่ละแท็บ

```lua
Window:CreateTab({ Name = "Main", Build = function(tab) ... end })
Window:CreateTab({ Name = "Misc" }, function(tab) ... end)
Main:Load(function(tab) ... end)      -- = Tab:Build
```

| API | ทำอะไร |
|---|---|
| `Window:OnLoaded(fn)` / `IsLoaded()` / `WaitLoaded()` | รอ / เช็กว่าโหลดครบ |
| `Window:StartLoad()` | เริ่มเอง (เมื่อ `StagedLoad = { Auto = false }`) |
| `Window:HoldLoading()` / `ReleaseLoading()` / `FinishLoading()` | คุมจังหวะ "สร้างเสร็จ" เอง |

```lua
Library:CreateWindow({ StagedLoad = false })                  -- ปิดเฉพาะหน้าต่างนี้
Library.StagedLoad.TabDelay = 0.2                             -- ค่ากลาง (`BuildDelay` ด้วย)
Library:CreateWindow({ Splash = false })                      -- ปิด Splash
Library:CreateWindow({ Splash = { Duration = 2.5, Skippable = true, Async = false } })
```

`CreateWindow` รอ Splash จบก่อนคืนหน้าต่าง (`Async = true` = ไม่รอ)

---

## 13. Tab Password Lock

### Window

| API | ทำอะไร |
|---|---|
| `LockTabWithPassword(tab, password, reason)` | ล็อกแท็บ + ต้องใส่รหัสถึงจะปลด |
| `TryUnlockTab(tab, password)` | → `ok, why, secs` (`why` = `"wrong"` \| `"lockout"` \| `"nopassword"`) |
| `PromptUnlockTab(tab)` | เปิดกล่องใส่รหัส |
| `HasTabPassword(tab)` | เช็กว่ามีรหัส |
| `UnlockTab(tab)` | ปลดจากโค้ดทันที ไม่ใช้รหัส |

```lua
Window:CreateTab({ Name = "VIP", Icon = "lucide:crown", Password = "1234",
    MaxAttempts = 3, LockoutTime = 30,
    OnUnlock = function(tab) end,
    OnWrongPassword = function(tab, tries) end,
    Build = function(tab) ... end })

Window:LockTabWithPassword("VIP", "1234", "ต้องมีรหัสเข้า")
local ok, why, secs = Window:TryUnlockTab("VIP", "1234")
Window:PromptUnlockTab("VIP")
Window:GetTab("VIP"):Relock()
```

### ตัวเลือกใน `CreateTab`

| ตัวเลือก | ความหมาย |
|---|---|
| `Password` | สตริง หรือ **ฟังก์ชัน** `function(input) return true/false end` |
| `MaxAttempts` / `LockoutTime` | จำกัดครั้งที่ผิด / เวลารอ (วินาที, ค่าเริ่มต้น 30) |
| `RetryPrompt = false` | ผิดแล้วไม่ถามซ้ำ แค่แจ้งเตือน |
| `OnUnlock(tab)` / `OnWrongPassword(tab, tries)` | callback |
| `PasswordTitle` `PasswordContent` `PasswordPlaceholder` | ข้อความในกล่องรหัสของแท็บนั้น |

- แปลข้อความที่ `Library.LockText`: `Title` `Content` `Placeholder` `Unlock` `Cancel` `Reason` `Wrong` `WrongLeft` `LockedOut` `Unlocked` `UnlockedText` `CoverTitle` `CoverSub` `Default` `ToastTitle` (`%s` / `%d` = ชื่อแท็บ / ตัวเลข)
- `Password` เป็นสตริง = รหัสอยู่ในสคริปต์ ใครอ่านก็เห็น → ต้องการความปลอดภัยจริง ให้ส่ง **ฟังก์ชัน** ตรวจกับเซิร์ฟเวอร์
- กล่องรหัสใช้ทั่วไปได้: `Window:Prompt({ ..., Password = true, EnterSubmits = true })`

---

## 14. Load API

โหลดสคริปต์จาก URL / ไฟล์ / โค้ดดิบ / ฟังก์ชัน พร้อมการ์ด Loading · คืน `ok, result`

```lua
Window:Load("https://example.com/script.lua", { Name = "MyScript" })
Library:Load("myscript.lua")
Window:LoadMany({ "https://example.com/a.lua", { Source = "https://example.com/b.lua", Args = { Library } } })
```

**ตัวเลือก:** `Name` `Args` `Retries` `Silent` `Async` `OnDone(ok, res)` `Cache`

ใช้ `game:HttpGet` ก่อน ถ้าไม่ได้ลอง `request` / `syn.request` / `http_request`

---

## 15. Audit / Icons

### Audit

```lua
local issues = Window:Audit({ Print = true, Notify = true, Fix = true })
Library.AutoCheck.Notify = false                        -- ไม่เด้งการ์ด (ยัง warn)
Library:CreateWindow({ Title = "X", AutoCheck = false })
```

**รหัสปัญหา:** `DupFlag` `BadCallback` `BadRange` `BadDefault` `EmptyTab` `LowContrast` `Offscreen` · คำอธิบายทั้งหมด: `Library.AuditCodes`

### Icons

| API | ทำอะไร |
|---|---|
| `Icon = "lucide:swords"` | ใช้ไอคอน (แพ็ก `lucide` เริ่มต้น / `solar` / `craft` / `geist` / `sfsymbols` / `gravity`) หรือ asset id |
| `Library:AddIcons("mine", { home = 123456 })` | เพิ่มแพ็กเอง |
| `Library:PreloadIcons()` | ดาวน์โหลดล่วงหน้า |
| `IsIconName` / `ResolveIcon` / `MakeIcon(desc, color)` / `SetIconModule(mod)` | ตัวช่วยระดับล่าง |
| `Library.IconLib.Default` / `.Url` | แพ็กเริ่มต้น / ที่อยู่ `Main-v2.lua` |
| `Library.KindIcons` | ไอคอนของ control แต่ละชนิดในผลค้นหา (เช่น `.Toggle = "lucide:power"`) |

---

## 16. Library Utilities

| API | ทำอะไร |
|---|---|
| `SetQuality("low" \| "high" \| "auto")` | ทางลัดของ `Perf.LowPower` (`Library.Perf.LowPower = true` ลดอาการกระตุกมือถือ) |
| `SetAnimSpeed(n)` / `Library.Anim.Speed` | ความเร็วอนิเมชัน (1.25 = ช้าลง 25%) |
| `Track(x)` | เก็บ Connection/Instance/ฟังก์ชันไว้เคลียร์ตอน `Unload()` |
| `OnUnload(fn)` | ลงทะเบียนฟังก์ชันให้รันตอน `Unload()` |
| `Connect(signal, fn)` | เหมือน `signal:Connect` + pcall + track |
| `Cooldown(key, seconds)` | `if Library:Cooldown("k", 3) then ... end` รันได้ 1 ครั้งต่อช่วงเวลา |
| `Try(fn, ...)` | `pcall` ที่ `warn` error → `ok, ...` |
| `Loop(flag?, interval, fn(handle))` | ลูป task · `flag` = รันเฉพาะตอน Flag เปิด · handle: `:Start` `:Stop` `:IsRunning` `:SetInterval` `:Destroy` |
| `Http(o)` | `{ Url, Method, Headers, Body, Json, Retries }` → `ok, res` (`res.Data` = JSON decode แล้วถ้า `Json = true`) |
| `HttpGet(url, json?)` / `HttpPost(url, body, json?)` | ทางลัดของ `Http` → `ok, body \| decoded` |
| `Webhook(url, text \| { Content, Username, Avatar, Embeds }, { Retries, Async })` | ส่ง Discord webhook (ไม่ ping ใคร) → `ok, err?` |
| `Embed(cfg)` | `{ Title, Description, Url, Color, Fields = {{Name,Value,Inline}}, Footer, Image, Thumbnail, Timestamp = true }` ใช้คู่ `Webhook` |
| `SaveData(key, value)` / `LoadData(key, default)` / `DeleteData(key)` | เก็บค่าถาวรแยกจาก Config (number/string/boolean/table) ที่ `SpectreUI/data/` |
| `Character(timeout = 10)` | ยีลด์รอ `char, humanoid, rootPart` · `nil` ถ้าหมดเวลา |
| `OnRespawn(fn(char, humanoid, root))` | รันทันทีถ้ามีตัวละคร แล้วรันซ้ำทุก respawn |
| `Library.Util` | `Round` `FormatNumber` `FormatTime` `Debounce` `Throttle` `Lighten` `Darken` `ToHex` ... |
| `Library.Anim` | `Tween` `Show` `Hide` `Pulse` |
| `Library.Responsive` | `IsTouch` `Breakpoint` `Scale` |

---

## 17. Language

| API | ทำอะไร |
|---|---|
| `Library:AddLanguage(code, strings, meta)` | เพิ่ม/ต่อภาษา · `strings = { ["English"] = "แปล" }` · `meta = { Name, Native }` → `ok, err?` |
| `Library:LoadLanguage(code, urlOrJson, meta?)` | โหลดภาษาจาก URL / JSON (`{ strings, Name, Native }` หรือ table ตรง ๆ) |
| `Library:SetLanguage(code, save)` / `Window:SetLanguage(code, save)` | เปลี่ยนภาษา (`save = true` จำค่า) → `ok, code \| err` |
| `Library:GetLanguage()` | โค้ดภาษาปัจจุบัน |
| `Library:ListLanguages()` | → `{ { Code, Name, Native }, ... }` |
| `Library:Translate(key, ...)` / `Library.T(key, ...)` | แปลคีย์ (มี `...` = `string.format`) |
| `Library:OnLanguageChange(fn(code, old))` | ดักเปลี่ยนภาษา → `{ Disconnect }` |

---

## 18. AutoUpdate

```lua
local h = Library:AutoUpdate({ Url = "https://host/hub.lua", Interval = 30 })
h.Check()   h.Stop()
```

| ตัวเลือก | ความหมาย |
|---|---|
| `Url` | สคริปต์หลักที่สร้าง UI (รันซ้ำเมื่อมีการเปลี่ยน) · ใส่สตริงตรง ๆ ได้ · ค่าเริ่มต้น `Library.SourceUrl` |
| `Watch` | ลิสต์ URL ที่ต้องเฝ้า (เช่น `{ hubUrl, libUrl }`) · ค่าเริ่มต้น `{ Url }` |
| `Run` | URL ที่ใช้รันเมื่ออัปเดต |
| `VersionUrl` | endpoint เล็ก (ข้อความ/JSON) ใช้เช็กแทนการโหลดต้นฉบับ |
| `Interval` | วินาทีระหว่างเช็ก (ต่ำสุด 10 · ค่าเริ่มต้น 120) |
| `CacheBust` | ค่าเริ่มต้น `true` |
| `Delay` | หน่วงก่อนรีโหลด (ค่าเริ่มต้น 1.2) |
| `OnUpdate(newSource)` | คืน `false` = ข้ามอัปเดตนี้ |

คอมไพล์เวอร์ชันใหม่ก่อนเสมอ ไฟล์ที่พังจะไม่ทำให้ UI เดิมล่ม · คืน handle `{ Check(), Stop() }`

---

## 19. Undocumented

มีในโค้ด แต่ยังไม่ทราบพฤติกรรมแน่ชัด: `Window:FitText` `Glitch` `PlayCascade` `Scramble` `SetAurora` `SetRainbow` `SetShaded` `SetSpotlight` `Shake` · `Tab:SetScrollEnabled`
