# SpectreUI v3.17 beta — คู่มือย่อ

ไลบรารี UI สำหรับสคริปต์ Roblox (Lua): หน้าต่าง แท็บ control ครบ ระบบธีม Config และ Command Palette (`Ctrl+K`)
แท็บ **SETTINGS** เป็นของสำเร็จรูป (ธีม ฟอนต์ เอฟเฟกต์ ปุ่มลัด Config Undo) เรียกบรรทัดเดียวจบ

---

## 1. สิ่งที่ต้องมี

- executor ที่รองรับ `loadstring`, `game:HttpGet`, `readfile` / `writefile` (ใช้เซฟ Config + ธีม)
- ต้องต่ออินเทอร์เน็ต: สคริปต์โหลด `SpectreUI.lua` จาก GitHub ทุกครั้งที่รัน
- ปุ่ม "คัดลอก Config" ต้องมีคลิปบอร์ด (ไม่มี = UI แจ้งว่าใช้ไม่ได้)

---

## 2. เริ่มต้นเร็ว

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/SpectreWareZ/SpectreWare/refs/heads/main/Tools/Ui/SpectreUI.lua"))()

local Window = Library:CreateWindow({
    Title     = "SpectreWare | ชื่อเกม",
    ToggleKey = Enum.KeyCode.RightShift,
})

Window:CreateTab({ Name = "MAIN", Icon = "lucide:home", Build = function(tab)
    local sec = tab:CreateSection({ Name = "ทั่วไป" })
    sec:CreateToggle({ Name = "เปิดฟีเจอร์", Default = false, Flag = "feature_on",
        Callback = function(on) print("feature", on) end })
    sec:CreateSlider({ Name = "ความเร็ว", Min = 16, Max = 200, Default = 16, Flag = "speed" })
end })

Window:CreateSettingsTab()   -- เรียกท้ายสุด จะได้อยู่ล่างแถบด้านข้าง

Window:OnLoaded(function()
    Library:AutoloadConfig("auto", true)   -- ต้องรอ UI สร้างเสร็จก่อน
end)
```

ลำดับ: **Window → Tab → Section → Control** (control ต้องอยู่ใน section, section ต้องอยู่ในแท็บ)

---

## 3. แนวคิดหลัก

ตัวเลือกที่ control ส่วนใหญ่ใช้ร่วมกัน:

| ตัวเลือก | ความหมาย |
|---|---|
| `Name` | ชื่อที่แสดง |
| `Default` | ค่าเริ่มต้น |
| `Flag` | ชื่อประจำ control อ่านผ่าน `Library.Flags["ชื่อ"]` และให้ Config จำค่า (**ไม่มี Flag = ไม่ถูกบันทึก**) |
| `Callback` | เรียกเมื่อค่าเปลี่ยน |
| `Tooltip` | ข้อความตอนชี้ |

```lua
if Library.Flags["aim_on"] then ... end      -- อ่านค่า
Library:SetFlag("aim_on", true)              -- ตั้งค่า (ตัวที่ 3 = true ไม่เรียก Callback)
local ctl = Library:GetControl("aim_on")     -- ctl:Set / ctl:Get
Library:Watch("aim_fov", function(v, prev) end)
```

ผู้ใช้คลิกขวา (มือถือ: กดค้าง) ที่ control เพื่อ รีเซ็ต / คัดลอก / ล็อก ค่า
มือถือกระตุก: `Library.Perf.LowPower = true`

---

## 4. โหลดเป็นขั้น (Staged Loading) + Splash

เปิดอยู่เป็นค่าเริ่มต้น ไม่ต้องเขียนเพิ่ม: แท็บโผล่ทีละอัน แล้วค่อยรัน `Build` ของแต่ละแท็บ

ใส่ control ผ่าน `Build` ได้ 3 แบบ:

```lua
Window:CreateTab({ Name = "Main", Build = function(tab) ... end })
Window:CreateTab({ Name = "Misc" }, function(tab) ... end)
Main:Load(function(tab) ... end)      -- Tab:Build ตัวเดียวกัน
```

> ⚠️ `Library:AutoloadConfig` **ไม่รอ** โหลดครบ ถ้า control อยู่ใน `Build` ให้เรียกใน `Window:OnLoaded(...)`

| API | ทำอะไร |
|---|---|
| `Window:OnLoaded(fn)` / `IsLoaded()` / `WaitLoaded()` | รอ/เช็กว่าโหลดครบ |
| `Window:StartLoad()` | เริ่มเอง (เมื่อ `StagedLoad = { Auto = false }`) |

ปรับ/ปิด:

```lua
Library:CreateWindow({ StagedLoad = false })                 -- ปิดเฉพาะหน้าต่างนี้
Library.StagedLoad.TabDelay = 0.2                            -- ค่ากลาง (BuildDelay ด้วย)
Library:CreateWindow({ Splash = false })                     -- ปิด Splash
Library:CreateWindow({ Splash = { Duration = 2.5, Skippable = true, Async = false } })
```

- ค่าเริ่มต้น `CreateWindow` จะรอ Splash จบก่อนคืนหน้าต่าง (`Async = true` = ไม่รอ)
- ถ้าตรวจจังหวะ "สร้างเสร็จ" ไม่แม่น ใช้ `Window:HoldLoading()` / `ReleaseLoading()` / `FinishLoading()`

---

## 5. Controls

ทุกตัวสร้างจาก section รับ table ตัวเลือก คืน control กลับมา

| อยากทำ | ใช้ | ตัวเลือก / หมายเหตุสำคัญ |
|---|---|---|
| สวิตช์ | `CreateToggle` | `Default` `Flag` `Callback(on)` |
| ตัวเลข | `CreateSlider` | `Min` `Max` `Increment` `Suffix` |
| | `CreateRangeSlider` | `Default = {lo, hi}` `MinGap` · Callback(lo, hi) |
| | `CreateStepper` | `Step` `Wrap` |
| เลือกจากรายการ | `CreateDropdown` | `Options` `Multi = true` (Default/Callback เป็น list) · `:Refresh(options)` |
| | `CreateSegmented` | `Options` `:SetOptions` |
| | `CreateListBox` | `Items` `Search` `Multi` · `:Add` `:Remove` |
| เลือกสี | `CreateColorPicker` | `Default = Color3` |
| ผูกปุ่ม | `CreateKeybind` | `Mode = "Press"/"Hold"/"Toggle"` · `Esc` ยกเลิก, `Backspace` ลบ |
| | `CreateKeybindToggle` | `Key` + สวิตช์ในตัวเดียว |
| พิมพ์ข้อความ | `CreateTextbox` | `Numeric` `Min` `Max` `Live` `EnterOnly` |
| | `CreateInputButton` | ช่องพิมพ์ + ปุ่มส่ง (`Button`, `ClearOnSubmit`) |
| | `CreateTagInput` | พิมพ์ + Enter เพิ่มแท็ก (`Lower`, `Max`) |
| ปุ่ม | `CreateButton` | `Color` `Gradient` `Bold` `Icon` `:SetText` |
| | `CreateButtonRow` | `Buttons = { {Name, Callback}, ... }` |
| | `CreateHoldButton` | `Duration` กดค้างเพื่อยืนยัน |
| ข้อความ / สถานะ | `CreateLabel` `CreateParagraph` `CreateBadge` `CreateDivider` | `:Set` |
| | `CreateProgress` | `Min` `Max` · `:Set(v)` |
| | `CreateStat` | `Get = fn` `Interval` `Delta = true` (ไม่เซฟ Config) |
| | `CreateKeyValue` | `Value` `Copyable` |
| | `CreateCountdown` | `Target` (epoch) หรือ `Seconds` · `WarnAt` `OnDone` |
| | `CreateGraph` | `Points` `Height` · `:Push(n)` |
| ตาราง / รูป | `CreateTable` | `Columns` `Rows` `OnRowClick` · `:AddRow` `:SetRows` |
| | `CreateItemGrid` | `Items = {{Name, Amount, Image}}` · `:SetAmount` |
| | `CreateImage` | `Image` `Height` `Fit` |
| | `CreateStatusCard` | รูป + ชื่อ + ป้าย + แถบค่า (สูงสุด 4) · `:SetBar(i, v, text, color)` `:SetBadge` `:SetEmpty` |
| โค้ด / log | `CreateConsole` | `:Info` `:Warn` `:Error` `:Print` |
| | `CreateCodeBlock` | `Text` `Copy` · `:Append` |
| อื่นๆ | `CreateDiscord` | `Invite` `Button` `Refresh` · `:GetInfo()` |
| | `CreateConfigManager` | Save / Load / Delete หลาย Config ในชุดเดียว |

ตัวอย่างที่ใช้บ่อย:

```lua
sec:CreateDropdown({ Name = "เป้าหมาย", Options = { "Head", "Torso" }, Default = "Head", Flag = "aim_part" })
sec:CreateKeybind({ Name = "Aimbot", Default = Enum.KeyCode.E, Mode = "Hold", Flag = "aim_key",
    Callback = function(down) print(down) end })
sec:CreateSlider({ Name = "FOV", Min = 10, Max = 360, Default = 120, Flag = "aim_fov" })
    :ShowIf("aim_on", true)       -- โชว์เมื่อ aim_on เปิด
```

### เมธอดที่ทุก control มี

| เมธอด | ทำอะไร |
|---|---|
| `:Set(v)` / `:Get()` | ตั้ง/อ่านค่า |
| `:SetVisible(b)` / `:ShowIf(flag, value\|fn)` | ซ่อน/แสดง |
| `:SetEnabled(b)` / `:Lock()` / `:Unlock()` | ทำให้จาง + กันการกด |
| `:OnChange(fn(v, prev))` | ดักการเปลี่ยนค่า (ต้องมี `Flag`) |
| `:Reset()` / `:IsModified()` | กลับค่าเริ่มต้น / เช็กว่าถูกแก้ |
| `:Destroy()` | ลบ control |

ตอนสร้าง: `NoMenu = true` ปิดเมนูคลิกขวา · `ContextMenu = {{ Name, Callback(obj) }}` เพิ่มรายการเอง

---

## 6. แจ้งเตือน / Dialog / Loading

ใช้ได้ทั้ง `Window:` และ `Library:` (ยกเว้น `AskAmount`)

| API | ทำอะไร |
|---|---|
| `Window:Notify({ Title, Content, Kind, Duration, Progress, Key })` | การ์ดแจ้งเตือน (`Kind` = Success/Warning/Error/Info · `Duration = 0` ค้างจนปิด · `Key` เดียวกัน = อัปเดตการ์ดเดิม) |
| `Window:Success / Warning / Error / Info(title, content, dur)` | ทางลัด |
| `Window:Toast("ข้อความ", "Success" \| 3)` | แถบเล็กกลางล่าง |
| `Window:Confirm({ Title, Content, OnYes, OnNo, Danger })` | ถามยืนยัน |
| `Window:Prompt({ Title, Placeholder, OnSubmit })` | กล่องพิมพ์ข้อความ |
| `Window:AskAmount({ Title, Max, Default })` | ถามจำนวน → คืนเลข/`nil` (เรียกใน `task.spawn`) |
| `Window:Dialog(cfg)` | กล่องโต้ตอบเต็มรูปแบบ (`:Wait()` รอผล) |
| `Library:Copy(text, title)` | คัดลอก + การ์ด "Copied" |
| `Window:DismissAll()` | ปิดการแจ้งเตือนทั้งหมด |

```lua
local l = Window:Loading({ Title = "กำลังโหลด", Text = "เริ่ม...", Progress = 0 })
l:Set(0.5, "ครึ่งทางแล้ว")      -- 0..1 (Set(false) = วนไม่รู้ความคืบหน้า)
l:Complete("เสร็จแล้ว", 2.5)    -- หรือ l:Fail(...) / l:Close()
```

Loading **ไม่ปิดเอง** จนกว่าจะเรียก `Complete` / `Fail` / `Close`
ปิดเสียง: `Library.Sound.Enabled = false`

---

## 7. Config และ Undo

ไฟล์เก็บที่ `SpectreUI/configs/` · เก็บเฉพาะ control ที่มี `Flag`

```lua
Library:SaveConfig("name")      Library:LoadConfig("name", silent)
Library:DeleteConfig("name")    Library:ListConfigs()
Library:ExportConfig()          Library:ImportConfig(json, silent)
Library:SaveAuto("auto")        Library:AutoloadConfig("auto", true)

Window:OnLoaded(function() Library:AutoloadConfig("auto", true) end)
```

โหลดอัตโนมัติ: ผู้ใช้กด "บันทึกเป็น auto" ในแท็บ SETTINGS ก่อน แล้วค่อยเรียก `AutoloadConfig` **หลังสร้าง control ครบ**

| API | ทำอะไร |
|---|---|
| `Library:Undo()` / `Redo()` | ย้อน/ทำซ้ำ (`Ctrl+Z` / `Ctrl+Y`) |
| `Library:Transaction("ชื่อ", fn)` / `SetFlags({...})` | หลายค่า = Undo ขั้นเดียว |
| `Library:Snapshot("a")` / `Restore("a")` | โปรไฟล์ในหน่วยความจำ |
| `Library:GetModified()` / `ResetAll()` | ค่าที่ถูกแก้ / รีเซ็ตทั้งหมด |

---

## 8. ธีมและฟอนต์

ธีม: Rose (เริ่มต้น), Violet, Cyber, Crimson, Matrix, Aurora, Dracula, Nord, TokyoNight, Mocha, Synthwave, Jade, Gold, Lavender, Candy, Peach, Midnight, Ocean, Sunset, Mono

ธีมที่ผู้ใช้เลือกถูกจำใน `themes.json` — **ถ้าใส่ `Theme = "..."` ใน `CreateWindow` จะบังคับธีมนั้นทุกครั้ง** (ลบออกถ้าอยากให้จำของผู้ใช้)

| API | ทำอะไร |
|---|---|
| `Window:SetTheme(name\|tbl, remember)` | เปลี่ยนธีมสด |
| `Window:CycleTheme(dir)` / `RandomTheme()` | ถัดไป / สุ่ม |
| `Library:RegisterTheme(name, tbl)` / `CloneTheme(src, new, overrides)` | เพิ่ม / ทำสำเนา |
| `Window:ExportTheme()` / `ImportTheme(code, name)` | แชร์ธีมเป็นข้อความ `SPT1:{...}` |
| `Window:SetFont(font, remember)` / `Library:RegisterFont(...)` | ฟอนต์ |
| `Window:SetTextScale(1.15, true)` | ขนาดตัวอักษร (0.7–1.4) เรียกหลังสร้าง UI |

`Window.Theme.Accent` / `Accent2` = สีหลัก/รองปัจจุบัน (ใช้ทำ Gradient)
ฟอนต์ Roblox รองรับเฉพาะละติน ภาษาไทยใช้ฟอนต์สำรองของระบบเสมอ

---

## 9. แท็บ SETTINGS สำเร็จรูป

```lua
local tab, parts = Window:CreateSettingsTab()      -- หรือ Window:CreateDefaultTabs({...})
local mine = tab:CreateSection({ Name = "ของฉัน", Column = 1 })   -- เพิ่มของเราเองได้
```

มี: ธีมสี · Font/Text size · สร้างธีม · พื้นหลัง/เอฟเฟกต์ · ปุ่มลัด · Interface (FPS/Ping, Keybind list, ตำแหน่งแจ้งเตือน) · Config · Undo/Snapshot · Window (Unload)

| ตัวเลือก | ความหมาย |
|---|---|
| `Sections` | `{ Theme/Hotkeys/Interface/Config/Window/History = false }` ซ่อนทีละส่วน |
| `Maker` / `Effects` / `Fonts` | `false` = ซ่อนส่วนสร้างธีม / เอฟเฟกต์ / ฟอนต์ |
| `Keys` | F6/F5 เปลี่ยนธีม · `false` = ปิด · `{ Next, Prev }` ตั้งเอง |
| `DefaultConfig` / `AutoName` | ชื่อเริ่มต้นของ Config / ไฟล์ auto |
| `WatermarkText` | ข้อความหน้า Watermark |
| `Text` | แปลข้อความ ใส่เฉพาะคีย์ที่อยากเปลี่ยน |
| `Icons` | เปลี่ยนไอคอน (`false` = ไม่มี) |

Flag ของระบบมีคำนำหน้า `ui_` (`ui_menu_key`, `ui_bg_fx`, `ui_quality`, `ui_theme_next`, `ui_theme_prev`, `ui_watermark`, `ui_keybind_list`, `ui_notify_pos`, `ui_notify_dur`)

แท็บ THEME แยกไม่ต้องเรียกแล้ว (รวมใน SETTINGS) ถ้าอยากได้ ใช้ `Window:CreateThemeTab(cfg)` หรือ `CreateDefaultTabs({ Theme = true })`

---

## 10. Command Palette, ปุ่มลัด, HUD

```lua
Library:AddCommand({ Name = "ไปหน้า Config", Keywords = "config save",
    Callback = function() Window:SetTab("SETTINGS") end })

Library:Hotkey(Enum.KeyCode.F4, function() Window:Toggle() end, { Ctrl = true, Desc = "ซ่อน/แสดงเมนู" })

Window:Watermark({ Text = "SpectreWare", Fields = { "FPS", "Ping", "Time" }, Position = "TopRight" })
Window:KeybindList({ Title = "Keybinds", Position = "LeftCenter" })
Window:Tour({ { Tab = "MAIN", Title = "ยินดีต้อนรับ", Content = "..." }, { Target = "aim_on", Title = "...", Content = "..." } })
```

| ปุ่ม | ทำอะไร |
|---|---|
| `RightShift` (ตั้งที่ `ToggleKey` / SETTINGS) | เปิด/ปิดเมนู |
| `Ctrl + K` | Command Palette |
| `F6` / `F5` | ธีมถัดไป / ก่อนหน้า |
| `Ctrl + Z` / `Ctrl + Y` | Undo / Redo |

Watermark `Fields`: `"FPS"` `"Ping"` `"Time"` `"Date"` `"Players"` หรือ `{ Name, Get = fn }`
ตำแหน่ง: `TopLeft/TopCenter/TopRight/LeftCenter/RightCenter/BottomLeft/BottomCenter/BottomRight` หรือ `UDim2`

---

## 11. Load API

โหลดสคริปต์จาก URL / ไฟล์ / โค้ดดิบ / ฟังก์ชัน พร้อมการ์ด Loading คืน `ok, result`

```lua
Window:Load("https://example.com/script.lua", { Name = "MyScript" })
Library:Load("myscript.lua")
Window:LoadMany({ "https://example.com/a.lua", { Source = "https://example.com/b.lua", Args = { Library } } })
```

ตัวเลือก: `Name` `Args` `Retries` `Silent` `Async` `OnDone(ok, res)` `Cache`
ใช้ `game:HttpGet` ก่อน ถ้าไม่ได้ลอง `request` / `syn.request` / `http_request` เอง

---

## 12. ตรวจ UI อัตโนมัติ + ไอคอน

ตรวจเองหลังสร้างหน้าต่าง/สลับแท็บ/ปรับขนาด แจ้งเฉพาะปัญหาใหม่ (UI ปกติจะเงียบ)

```lua
local issues = Window:Audit({ Print = true, Notify = true, Fix = true })
Library.AutoCheck.Notify = false                       -- ไม่เด้งการ์ด (ยัง warn)
Library:CreateWindow({ Title = "X", AutoCheck = false })
```

ปัญหาที่เจอบ่อย: `DupFlag` (Flag ซ้ำ), `BadCallback`, `BadRange` (Min ≥ Max), `BadDefault`, `EmptyTab`, `LowContrast`, `Offscreen`

ไอคอน: `Icon = "lucide:swords"` (แพ็ก `lucide` เริ่มต้น / `solar` / `craft` / `geist` / `sfsymbols` / `gravity`) หรือ asset id · เพิ่มแพ็กเอง `Library:AddIcons("mine", { home = 123456 })` · ดาวน์โหลดล่วงหน้า `Library:PreloadIcons()`

---

## 13. API หลัก

### CreateWindow(cfg)

| ตัวเลือก | ความหมาย |
|---|---|
| `Title` | `"แบรนด์ \| ย่อย"` |
| `Logo` `Width` `Height` | โลโก้ (asset id) / ขนาด |
| `ToggleKey` | ปุ่มเปิด/ปิดเมนู |
| `Theme` `Font` `FX` | ธีม / ฟอนต์ / เอฟเฟกต์ (`petals/orbs/grid/embers/rain`) |
| `Background = false` / `Resizable = false` | ปิดพื้นหลัง / ห้ามปรับขนาด |
| `Splash` / `StagedLoad` / `AutoCheck` | หัวข้อ 4 / 4 / 12 |

### Window

| เมธอด | ทำอะไร |
|---|---|
| `CreateTab(cfg [, build])` | `Name` `Icon` `Build` `Locked` `LockReason` |
| `GetTab` / `SetTab` / `ListTabs` / `RemoveTab` / `RenameTab` | จัดการแท็บ |
| `LockTab(tab, reason)` / `UnlockTab(tab)` | ล็อกแท็บ VIP |
| `Open` / `Close` / `Toggle` / `IsOpen` | เปิด/ปิดเมนู |
| `SetToggleKey(key)` | เปลี่ยนปุ่มเมนู |
| `SetTitle` `Center` `Resize` `SetMaximized` `Flash` | หน้าตาหน้าต่าง |
| `Goto(obj\|"flag"\|"ชื่อ")` | กระโดดไป control |
| `Destroy()` | ทำลายหน้าต่าง · `Library:Unload()` ทำลายทั้งหมด |

### Tab / Section

| เมธอด | ทำอะไร |
|---|---|
| `tab:CreateSection({ Name, Column = 1\|2, Collapsible, Collapsed, Icon })` | สร้าง section |
| `tab:SetBadge("NEW")` | ป้ายที่แท็บ |
| `tab:ResetAll()` / `section:ResetAll()` | รีเซ็ตค่า |
| `section:SetCollapsed(bool)` | พับ/กาง |

### API เพิ่มเติม (อ้างอิงเร็ว)

**Library**

| API | ทำอะไร |
|---|---|
| `GetFlags()` / `ToggleFlag(flag)` / `OnFlag(fn(flag, v, prev))` | อ่านทุก Flag / สลับ / ดักทุก Flag |
| `CanUndo()` / `CanRedo()` / `GetHistory()` / `ClearHistory()` / `Diff("a","b")` | ประวัติ Undo + เทียบ Snapshot (`Library.History.Max` = จำนวนสูงสุด) |
| `Alert(title, content)` / `Banner({ Title, Content, Duration, Color })` | แจ้งปุ่มเดียว / แถบบน (ใช้ได้ตอนเมนูปิด) |
| `ShowMenu(items, anchorFrame)` / `CloseMenu()` | เมนูคลิกขวาของเราเอง (`Library.ContextMenu = false` = ปิดทั้งระบบ) |
| `SetQuality("low"\|"high"\|"auto")` | ทางลัดของ `Perf.LowPower` |
| `GetTheme(name?)` / `ListThemes()` / `RenameTheme(old, new)` / `DeleteTheme(name)` | จัดการธีม |
| `OnThemeChange(fn(event, a, b))` / `SaveThemes()` / `LoadThemes()` | ดักธีมเปลี่ยน / เซฟ-โหลด `themes.json` |
| `SetStatusColors({ Success = c, ... })` / `GetStatusColor(kind)` | สี Success/Warning/Error/Info |
| `ListFonts()` / `ListHotkeys()` | รายชื่อฟอนต์ / hotkey |
| `OnAccent(Window.Theme)` | สีตัวอักษรที่อ่านง่ายบนสีธีม (ไลบรารีใช้เองอัตโนมัติ) |
| `IsIconName` / `ResolveIcon` / `MakeIcon(desc, color)` / `SetIconModule(mod)` | ตัวช่วยไอคอนระดับล่าง |
| `Library.IconLib.Default` / `.Url` | แพ็กไอคอนเริ่มต้น / ที่อยู่ `Main-v2.lua` |
| `Library.PaletteKey` | ปุ่มคู่กับ Ctrl เปิด Palette (ค่าเริ่มต้น `K`) |
| `Library.NotifyConfig` | `Position` `MaxVisible` `Duration` `Gap` `Margin` `Width` `Merge` `PauseOnHover` `Animate` |
| `Library.Anim.Speed` | ความเร็วอนิเมชัน (1.25 = ช้าลง 25%) |
| `Library.Util` / `Library.Anim` / `Library.Responsive` | helper (`Round` `FormatNumber` `FormatTime` `Debounce` `Throttle` `Lighten` `Darken` `ToHex` ... / `Tween` `Show` `Hide` `Pulse` / `IsTouch` `Breakpoint` `Scale`) |
| `Library.AuditCodes` | คำอธิบายกฎตรวจ UI ทั้งหมด |

**Window**

| API | ทำอะไร |
|---|---|
| `SelectTab(nameOrTab)` | สลับแท็บ (เหมือน `SetTab`) |
| `IsTabLocked(tab)` | เช็กว่าแท็บล็อก |
| `IsMaximized()` / `SetSize(w, h)` | เช็กขยายเต็มจอ / ตั้งขนาด |
| `OnResize(fn)` / `CloseDropdowns()` | ดักปรับขนาด / ปิด dropdown ที่เปิดอยู่ |
| `SetBackground("orbs"\|false\|nil)` | เปลี่ยนเอฟเฟกต์พื้นหลัง (`nil` = ตามธีม) |
| `SetNotifyTheme("Cyber"\|tbl\|nil)` | ธีมสีเฉพาะการแจ้งเตือน/Dialog |
| `GetThemeName()` / `GetFontName()` / `CycleFont(dir)` / `GetTextScale()` / `GetToggleKey()` | อ่านค่าปัจจุบัน / ฟอนต์ถัดไป |
| `RenameTheme("ใหม่")` / `DeleteTheme(name?)` | จัดการธีมของหน้าต่าง |
| `OpenPalette(initial)` / `ClosePalette()` | เปิด/ปิด Command Palette จากโค้ด |

**Tab / Section**

| API | ทำอะไร |
|---|---|
| `tab:SetLocked(bool, reason)` / `IsLocked()` / `SetLockReason(text)` | ล็อกแท็บ |
| `section:CreateSeparator(cfg)` | เส้นคั่น (คู่กับ `CreateDivider`) |
| `section:CreateThemeManager({ Name, Flag, Remember, Random, Delete })` | UI จัดการธีมสำเร็จรูป |
| `section:CreateFontPicker({ Name, Flag, Remember })` | dropdown เลือกฟอนต์ |

**มีในโค้ดแต่ไม่เคยอยู่ในคู่มือ (ยังไม่ทราบพฤติกรรมแน่ชัด):** `Window:FitText` `Glitch` `PlayCascade` `Scramble` `SetAurora` `SetHideOpenButtonOnPC` `SetRainbow` `SetShaded` `SetSpotlight` `Shake` · `Tab:SetScrollEnabled`

---

## 14. ปัญหาที่พบบ่อย

| อาการ | วิธีแก้ |
|---|---|
| เมนูไม่ขึ้น | เช็กว่า executor รองรับ `game:HttpGet` + ต่อเน็ตอยู่ แล้วลองกดปุ่มเปิด/ปิด (`RightShift`) |
| เมนูว่าง / แท็บไม่ครบ | โหลดเป็นขั้นตามปกติ รอการ์ด Loading ขึ้น "Ready" (หรือตั้ง `StagedLoad = false`) |
| Config ไม่โหลดตอนเริ่ม | ต้องมีไฟล์ `auto.json` (กด "บันทึกเป็น auto" ก่อน) และเรียก `AutoloadConfig` ใน `Window:OnLoaded` |
| ธีมที่เลือกไม่ถูกจำ | ลบ `Theme = "..."` ออกจาก `CreateWindow` |
| มือถือกระตุก | `Library.Perf.LowPower = true` หรือเลือกคุณภาพ `low` ใน SETTINGS |
| "คัดลอก Config" ไม่ได้ | executor ไม่รองรับคลิปบอร์ด ใช้บันทึกเป็นไฟล์แทน |
| ตัวหนังสือมองไม่เห็นในธีมสว่าง | ลบ `TextColor` ที่ตั้งเองออก ไลบรารีเลือกสีให้ |
| UI ไม่ตรงคู่มือ | ไฟล์ GitHub ยังไม่อัปเดต หรือ executor แคชเก่า รันใหม่แล้วเช็ก `print(Library.Splash, Library.StagedLoad)` (ต้องเป็น `table`) |
| Splash มี error | ดู console หา `[SpectreUI] splash error: ...` UI ยังสร้างตามปกติ |

---

## 15. บันทึกการเปลี่ยนแปลง (ย่อ)

สถานะ **beta**: `Library.Version = "3.17"`, `Library.Stage = "beta"` (ตั้ง `Stage = nil` ตอนปล่อยเสถียร)

- **ล่าสุด:** เพิ่ม `CreateStatusCard` · รวมแท็บ THEME เข้า SETTINGS · เพิ่มส่วน Interface ใน SETTINGS
- **v3.17:** โหลดเป็นขั้น (`Build`, `OnLoaded`, `StagedLoad`)
- **v3.16:** Splash แบบเรียบ (ค่าเริ่มต้นสั้นลง)
- **v3.15:** เพิ่ม Splash
- **v3.14:** Controls ใหม่ (ButtonRow, InputButton, KeyValue, CodeBlock, Countdown, ListBox, Table, Image, ItemGrid) · `AskAmount` · `RemoveTab`/`RenameTab` · `SetToggleKey` · `Library:Copy`
- **v3.13:** ฟอนต์ + `SetTextScale` · Flag helper · `Library:Hotkey` · แชร์ธีม
- **v3.12:** `CreateStepper`, `CreateStat`
- **v3.11:** `Watermark`, `KeybindList`, `Tour`
- **v3.10:** ตรวจ UI อัตโนมัติ
- **v3.9:** Load API
- **v3.8:** ระบบไอคอน
- **v3.7:** แท็บสำเร็จรูป · **Flag ธีมเปลี่ยนชื่อ** เป็นคำนำหน้า `ui_` (`bg_fx`→`ui_bg_fx`, `quality`→`ui_quality`, `theme_next_key`→`ui_theme_next`, `theme_prev_key`→`ui_theme_prev`, `menu_key`→`ui_menu_key`) Config เก่าไม่ผูกกับค่าเหล่านี้ ตั้งใหม่แล้วบันทึกทับครั้งเดียว
