# SpectreUI v3.10 — คู่มือการใช้งาน + รวม API ทั้งหมด

SpectreUI คือไลบรารี UI สำหรับสคริปต์ Roblox (Lua) มีหน้าต่าง แท็บ ตัวควบคุมครบชุด (สวิตช์ สไลเดอร์ ดรอปดาวน์ คีย์บายด์ ฯลฯ) ระบบธีม ระบบ Config และ Command Palette (Ctrl+K) ในตัว

แท็บ **THEME** และ **SETTINGS** เป็นของสำเร็จรูป สร้างให้ด้วยบรรทัดเดียว ไม่ต้องเขียนเอง

> อยากรู้ว่ามี API อะไรบ้าง ดู **หัวข้อ 11 รวม API ทั้งหมด** (มี API โหลด/Loading, แจ้งเตือน, Dialog, ไอคอน, Config, ธีม, Controls ครบ)

---

## 1. สิ่งที่ต้องมี

- ไฟล์ `SpectreUI.lua` เวอร์ชัน **3.10 ขึ้นไป** (แนบมาด้วย) วางไว้ในโฟลเดอร์ workspace ของ executor
- executor ที่รองรับ `loadstring` และ `readfile` รวมถึงฟังก์ชันไฟล์ เพราะ Config และธีมถูกบันทึกเป็นไฟล์
- ปุ่ม "คัดลอก Config" ต้องใช้คลิปบอร์ด ถ้า executor ไม่รองรับ UI จะแจ้งว่าเครื่องนี้ไม่รองรับคลิปบอร์ด
- ถ้าใช้เป็น ModuleScript ให้ใช้ `require(ModuleScript)` แทน `loadstring(readfile(...))`

---

## 2. เริ่มต้นเร็ว (Quick Start)

```lua
local Library = loadstring(readfile("SpectreUI.lua"))()

local Window = Library:CreateWindow({
    Title     = "SpectreWare | ชื่อเกม",
    ToggleKey = Enum.KeyCode.RightShift,   -- ปุ่มเปิด/ปิดเมนู
})

-- 1) สร้างแท็บ  2) สร้าง section ในแท็บ  3) ใส่ control ใน section
local Main = Window:CreateTab({ Name = "MAIN", Icon = "M" })
local sec  = Main:CreateSection({ Name = "ทั่วไป" })

sec:CreateToggle({
    Name = "เปิดฟีเจอร์", Default = false, Flag = "feature_on",
    Callback = function(on) print("feature", on) end,
})

-- แท็บสำเร็จรูป: เรียกท้ายสุด เพื่อให้ THEME / SETTINGS อยู่ล่างแถบด้านข้าง
Window:CreateThemeTab()
Window:CreateSettingsTab()
-- หรือทีเดียวสองแท็บ: Window:CreateDefaultTabs()

-- โหลด Config อัตโนมัติ (ถ้ามีไฟล์ auto.json) ต้องเรียกหลังสร้างทุก control แล้ว
Library:AutoloadConfig("auto", true)
```

ลำดับการสร้างคือ **Window → Tab → Section → Control** ทุก control ต้องอยู่ใน section และทุก section ต้องอยู่ในแท็บ

---

## 3. Library, Window, Tab, Section

### Library:CreateWindow(cfg) → Window

| ตัวเลือก | ความหมาย |
|---|---|
| `Title` | ชื่อที่แสดงบนหน้าต่าง |
| `ToggleKey` | ปุ่มเปิด/ปิดเมนู เช่น `Enum.KeyCode.RightShift` (ผู้ใช้เปลี่ยนเองได้ในแท็บ SETTINGS) |
| `Theme` | ชื่อธีมที่ต้องการบังคับ เช่น `"Cyber"` **ถ้าไม่ใส่** ธีมที่ผู้ใช้เลือกไว้ครั้งก่อนจะโหลดกลับมาเอง |

### โหมดประหยัด (มือถือ)

```lua
Library.Perf.LowPower = false   -- nil = อัตโนมัติ (มือถือเปิดเอง), true/false = บังคับ
```

### เมธอดของ Window

| เมธอด | ทำอะไร |
|---|---|
| `Window:CreateTab({ Name, Icon })` | สร้างแท็บ คืนค่า tab |
| `Window:SetTab("ชื่อแท็บ")` | สลับไปแท็บที่ระบุ |
| `Window:Notify({ Title, Content, Duration })` | แจ้งเตือนแบบมีหัวข้อ `Duration` เป็นวินาที |
| `Window:Toast("ข้อความ", "Info")` | แจ้งเตือนสั้น ๆ |
| `Window:GetThemeName()` | ชื่อธีมที่ใช้อยู่ตอนนี้ |
| `Window.Theme.Accent`, `Window.Theme.Accent2` | สีหลัก / สีรองของธีมปัจจุบัน (ใช้ทำ Gradient ให้ปุ่มได้) |
| `Window:CreateThemeTab(cfg)` | แท็บธีมสำเร็จรูป (หัวข้อ 7) |
| `Window:CreateSettingsTab(cfg)` | แท็บตั้งค่าสำเร็จรูป (หัวข้อ 7) |
| `Window:CreateDefaultTabs(cfg)` | สร้างสองแท็บข้างบนทีเดียว |

### เมธอดของ Tab และ Section

| เมธอด | ทำอะไร |
|---|---|
| `tab:CreateSection({ Name, Column })` | สร้าง section คืนค่า section `Column` คือคอลัมน์ที่จะวาง (เช่น `1`) |
| `tab:SetBadge("NEW")` | ติดป้ายเล็ก ๆ ที่แท็บ |

---

## 4. Controls

สร้างจาก section ทุกตัวรับ table ตัวเลือก และคืนค่า control กลับมา

```lua
local sec = Tab:CreateSection({ Name = "ตัวอย่าง" })
```

### ตัวเลือกที่ใช้ได้กับ control ส่วนใหญ่

| ตัวเลือก | ความหมาย |
|---|---|
| `Name` | ชื่อที่แสดง |
| `Default` | ค่าเริ่มต้น |
| `Flag` | ชื่อประจำ control ใช้อ่านค่าผ่าน `Library.Flags["ชื่อ"]` และให้ Config จำค่า |
| `Callback` | ฟังก์ชันที่ถูกเรียกเมื่อค่าเปลี่ยน |
| `Tooltip` | ข้อความอธิบายเมื่อชี้ที่ control |
| `ContextMenu` | เมนูคลิกขวา/กดค้างที่เพิ่มเอง (ดูตัวอย่างใต้ Slider) |

เมธอดที่ใช้ต่อท้ายได้:

- `control:ShowIf("flag", ค่า)` แสดง control นี้เมื่อ control ที่มี `Flag` นั้นมีค่าตามที่ระบุ
- `control:Set(ค่า)` ตั้งค่าด้วยโค้ด

ผู้ใช้คลิกขวา หรือกดค้างที่ control ใดก็ได้ เพื่อ **รีเซ็ต / คัดลอก / ล็อก** ค่า

### Toggle — สวิตช์เปิด/ปิด

```lua
sec:CreateToggle({ Name = "เปิด Aimbot", Default = false, Flag = "aim_on",
    Callback = function(v) print("aimbot", v) end })
```

### Slider — แถบเลื่อนค่าเดียว

```lua
sec:CreateSlider({ Name = "FOV", Min = 10, Max = 360, Default = 120, Suffix = "°", Flag = "aim_fov" })
    :ShowIf("aim_on", true)   -- โชว์เมื่อสวิตช์ aim_on เปิดอยู่

-- ใส่เมนูคลิกขวาเพิ่มเอง
sec:CreateSlider({ Name = "WalkSpeed", Min = 16, Max = 200, Default = 16, Flag = "walkspeed",
    ContextMenu = {
        { Name = "ตั้งเป็น 50",  Callback = function(o) o:Set(50) end },
        { Name = "ตั้งเป็น 100", Callback = function(o) o:Set(100) end },
    } })
```

`Suffix` คือหน่วยต่อท้ายตัวเลข เช่น `"%"`, `"°"`, `"s"`

### RangeSlider — แถบเลื่อนสองปลาย (ต่ำสุด–สูงสุด)

```lua
sec:CreateRangeSlider({ Name = "ช่วงดีเลย์", Min = 0, Max = 5, Increment = 0.1, MinGap = 0.1,
    Default = { 0.5, 2 }, Suffix = "s", Flag = "delay_range",
    Tooltip = "สุ่มดีเลย์ระหว่างค่าต่ำสุด-สูงสุด",
    Callback = function(lo, hi) print("range", lo, hi) end })
```

`Increment` คือขนาดของแต่ละขั้น `MinGap` คือระยะห่างต่ำสุดระหว่างสองปลาย `Default` เป็น `{ ต่ำ, สูง }`

### Dropdown — รายการเลือก

```lua
-- เลือกได้อันเดียว
sec:CreateDropdown({ Name = "เป้าหมาย", Options = { "Head", "Torso", "Nearest" },
    Default = "Head", Flag = "aim_part" })

-- เลือกได้หลายอัน Default และ Callback เป็น list
sec:CreateDropdown({ Name = "เลือกหลายอัน", Multi = true,
    Options = { "Boss", "Elite", "Mob", "Chest" }, Default = { "Boss", "Mob" },
    Flag = "targets", Callback = function(list) print(table.concat(list, ", ")) end })
```

### Segmented — ปุ่มเลือกแบบแถบ

```lua
sec:CreateSegmented({ Name = "แผนที่ Farm", Options = { "A", "B", "C" }, Default = "A", Flag = "auto_map" })
```

### Keybind — ผูกปุ่มคีย์บอร์ด

```lua
sec:CreateKeybind({ Name = "Aimbot (กดค้าง)", Default = Enum.KeyCode.E, Mode = "Hold",
    Flag = "aim_key", Callback = function(down) print("aim", down) end })

sec:CreateKeybind({ Name = "Speed (สลับ)", Default = Enum.KeyCode.G, Mode = "Toggle",
    Flag = "speed_key", Callback = function(on) print("speed", on) end })
```

`Mode = "Hold"` ทำงานตอนกดค้าง `Mode = "Toggle"` กดครั้งหนึ่งเปิด อีกครั้งปิด

ตอนผู้ใช้ตั้งปุ่ม: กดปุ่มที่ต้องการ, `Esc` = ยกเลิก, `Backspace` = ลบปุ่ม

### KeybindToggle — คีย์ + สวิตช์ในตัวเดียว

```lua
sec:CreateKeybindToggle({ Name = "ESP (คีย์+สวิตช์)", Key = Enum.KeyCode.X, Default = false,
    Flag = "esp_on", Tooltip = "กดคีย์ X หรือแตะสวิตช์ เพื่อเปิด/ปิด ESP",
    Callback = function(on) print("esp", on) end })
```

### ColorPicker — เลือกสี

```lua
sec:CreateColorPicker({ Name = "สี ESP", Default = Color3.fromRGB(124, 58, 237),
    Flag = "esp_color", Callback = function(color) print(color) end })
```

### TagInput — ช่องพิมพ์แล้วกด Enter เพื่อเพิ่มแท็ก

```lua
sec:CreateTagInput({ Name = "ไวต์ลิสต์", Placeholder = "ชื่อผู้เล่น แล้วกด Enter",
    Default = { "Player1" }, Lower = true, Flag = "whitelist",
    Callback = function(list) print(table.concat(list, ", ")) end })
```

`Placeholder` คือข้อความจางในช่องว่าง `Lower = true` เก็บแท็กเป็นตัวพิมพ์เล็ก

### Button — ปุ่มกด

```lua
sec:CreateButton({ Name = "หยุดจัดเซ็ต", Callback = function() print("stop") end })

-- ปุ่มสีไล่เฉด + ตัวหนา
sec:CreateButton({ Name = "เริ่ม", Bold = true,
    Gradient = { Window.Theme.Accent, Window.Theme.Accent2 },
    Callback = function() Window:Notify({ Title = "สถานะ", Content = "เริ่มแล้ว", Duration = 3 }) end })
```

### Label — ข้อความ

```lua
sec:CreateLabel({ Text = "พร้อมใช้งาน", Color = Color3.fromRGB(52, 211, 153), Bold = true })
```

### Progress — แถบความคืบหน้า

```lua
local progress = sec:CreateProgress({ Name = "กำลังจัดเซ็ต", Min = 0, Max = 100, Default = 0, Suffix = "%" })
```

---

## 5. Flag และ Config

**อ่านค่า** ของ control ที่ใส่ `Flag` ไว้:

```lua
if Library.Flags["aim_on"] then
    -- ...
end
```

**ดักทุกการเปลี่ยนแปลง** (เหมาะกับตอนดีบัก):

```lua
Library:OnFlag(function(flag, value, prev)
    print("flag:", flag, tostring(value), "(เดิม " .. tostring(prev) .. ")")
end)
```

**บันทึก / โหลด Config** ผู้ใช้ทำได้ในแท็บ SETTINGS (หัวข้อ 7) ไฟล์ Config เก็บในโฟลเดอร์ `SpectreUI/configs/`

**โหลดอัตโนมัติตอนเริ่ม:** ผู้ใช้กด "บันทึกเป็น auto" ในแท็บ SETTINGS แล้วในสคริปต์ใส่ท้ายสุด

```lua
Library:AutoloadConfig("auto", true)
```

> ต้องเรียก **หลังสร้างทุก control แล้ว** ไม่งั้นค่าที่โหลดจะไม่ถูกใส่ให้ control ที่ยังไม่ถูกสร้าง

---

## 6. Command Palette (Ctrl+K)

กด `Ctrl + K` เพื่อค้นหาและสั่งงานได้ทุกอย่างจากช่องเดียว เพิ่มคำสั่งของตัวเองได้:

```lua
Library:AddCommand({
    Name     = "ไปหน้า Config",     -- ชื่อที่แสดงในรายการ
    Desc     = "Settings",          -- คำอธิบายสั้น ๆ
    Keywords = "config save load",  -- คำที่ใช้ค้นหา (ใส่ได้หลายภาษา)
    Callback = function() Window:SetTab("SETTINGS") end,
})
```

---

## 7. แท็บสำเร็จรูป (THEME / SETTINGS)

ไม่ต้องเขียนแท็บธีมกับแท็บตั้งค่าเองอีกแล้ว เรียกท้ายสุดหลังสร้างแท็บของเกมครบแล้ว เพื่อให้สองแท็บนี้อยู่ล่างแถบด้านข้าง

```lua
Window:CreateThemeTab()
Window:CreateSettingsTab()
-- หรือทีเดียวสองแท็บ: Window:CreateDefaultTabs()
```

### Window:CreateThemeTab(cfg) → tab, parts

| ส่วน | มีอะไร |
|---|---|
| **ธีมสี** (คอลัมน์ 1) | Dropdown เปลี่ยนธีมสด, เปลี่ยนชื่อ, ทำสำเนา, สุ่ม, ลบ (เฉพาะธีมที่สร้างเอง) + ทิป |
| **สร้างธีมของตัวเอง** (คอลัมน์ 2) | เลือกสีหลัก/สีรอง + ตั้งชื่อ + ปุ่มสร้างและใช้ทันที |
| **พื้นหลัง / เอฟเฟกต์** (คอลัมน์ 2) | เลือกเอฟเฟกต์ (petals/orbs/embers/rain/grid/ปิด/ตามธีม), คุณภาพ auto/low/high, คีย์ F6 = ธีมถัดไป, F5 = ก่อนหน้า |

ธีมที่เลือก / เปลี่ยนชื่อ / สร้างเอง ถูกเก็บที่ `SpectreUI/configs/themes.json` และโหลดกลับมาเองตอนเปิดครั้งหน้า (ไม่ต้องใส่ `Theme =` ใน `CreateWindow`)

| ตัวเลือก | ค่าเริ่มต้น | ความหมาย |
|---|---|---|
| `Name`, `Icon` | `"THEME"`, `"T"` | ชื่อ / ไอคอนแท็บ |
| `FlagPrefix` | `"ui_"` | คำนำหน้า Flag ที่บันทึกใน Config (`ui_bg_fx`, `ui_quality`, `ui_theme_next`, `ui_theme_prev`) |
| `Manager` | `{}` | ส่งต่อให้ `CreateThemeManager` เช่น `{ Random = false, Delete = false, Remember = true }` |
| `Maker` | `true` | `false` = ซ่อนส่วนสร้างธีม |
| `MakerColors` | ฟ้า/คราม | `{ Accent = Color3, Accent2 = Color3 }` สีเริ่มต้นของตัวเลือกสี |
| `Effects` | `true` | `false` = ซ่อนส่วนพื้นหลัง/คุณภาพ/คีย์ |
| `Keys` | F6 / F5 | `false` = ไม่สร้างคีย์ลัด หรือ `{ Next = Enum.KeyCode.X, Prev = Enum.KeyCode.Z }` |
| `Tip` | ข้อความเริ่มต้น | `false` = ซ่อน หรือใส่ข้อความเอง |
| `Text` | `{}` | แปล/เปลี่ยนข้อความ (หัวข้อ 8) |

`parts` ที่คืนมา: `Tab`, `Manager` (dropdown ธีม), `ManagerSection`, `Maker` (`Accent`, `Accent2`, `Name`, `Section`), `Background`, `Quality`, `NextKey`, `PrevKey`, `EffectsSection`

### Window:CreateSettingsTab(cfg) → tab, parts

| ส่วน | มีอะไร |
|---|---|
| **UI / ปุ่มลัด** | ปุ่มเปิด/ปิดเมนู (เปลี่ยนแล้วใช้ได้ทันที และตามเมื่อโหลด Config), ปุ่มเปิดค้นหา Ctrl+K, คำอธิบายการใช้ |
| **Config** | ชื่อ, รายการ Config, บันทึก, โหลด, ลบ (มีถามยืนยัน), บันทึกเป็น `auto`, คัดลอกไปคลิปบอร์ด, วางนำเข้า |
| **หน้าต่าง** | จัดกลางจอ + กระพริบ, ปิด UI ทั้งหมด (Unload, มีถามยืนยัน) |
| **Undo / Snapshot** | Undo, Redo, ดูค่าที่ถูกแก้, Snapshot A / กลับไป A, กดค้างเพื่อรีเซ็ตทั้งหมด |

| ตัวเลือก | ค่าเริ่มต้น | ความหมาย |
|---|---|---|
| `Name`, `Icon` | `"SETTINGS"`, `"S"` | ชื่อ / ไอคอนแท็บ |
| `FlagPrefix` | `"ui_"` | Flag ของปุ่มเมนูคือ `ui_menu_key` |
| `Sections` | ทุกส่วนเปิด | `{ Hotkeys = false, Config = false, Window = false, History = false }` ซ่อนทีละส่วน |
| `DefaultConfig` | `"default"` | ชื่อเริ่มต้นในช่องชื่อ Config |
| `AutoName` | `"auto"` | ชื่อไฟล์ของปุ่ม "บันทึกเป็น auto" |
| `Text` | `{}` | แปล/เปลี่ยนข้อความ (หัวข้อ 8) |

`parts` ที่คืนมา: `Tab`, `MenuKey`, `UISection`, `ConfigName`, `ConfigList`, `ConfigSection`, `WindowSection`, `HistorySection`

### Window:CreateDefaultTabs(cfg) → themeTab, settingsTab

```lua
Window:CreateDefaultTabs({
    Theme    = { Text = TEXT_TH },            -- หรือ false = ไม่สร้าง
    Settings = { Text = TEXT_TH, Sections = { History = false } },
})
```

### เพิ่มของเราเองลงในแท็บสำเร็จรูป

```lua
local tab, parts = Window:CreateSettingsTab()
local mine = tab:CreateSection({ Name = "ของฉัน", Column = 1 })
mine:CreateToggle({ Name = "โหมดพิเศษ", Flag = "my_mode" })
```

---

## 8. แปลข้อความ (`Text`)

ใส่เฉพาะคีย์ที่อยากเปลี่ยน คีย์ที่ไม่ใส่จะใช้ภาษาอังกฤษเริ่มต้น ใช้ได้ทั้ง `CreateThemeTab`, `CreateSettingsTab` และ `CreateDefaultTabs`

**THEME:** `ThemeSection` `Theme` `RenameLabel` `RenameButton` `DuplicateButton` `RandomButton` `DeleteButton` `TipTitle` `Tip` `MakerSection` `Accent` `Accent2` `NewName` `NewNameDefault` `NewNamePlaceholder` `CreateButton` `ThemeNotifyTitle` `Created` `FxSection` `FxName` `FxAuto` `FxOff` `Quality` `QualityTip` `NextTheme` `PrevTheme`

**SETTINGS:** `UISection` `MenuKey` `Palette` `HowTitle` `HowText` `ConfigTitle` `ConfigName` `ConfigList` `Save` `Saved` `Load` `Loaded` `Delete` `Cancel` `PickFirst` `DeleteTitle` `CannotUndo` `Deleted` `SaveAuto` `SavedAuto` `Copy` `Copied` `NoClipboard` `Import` `ImportTitle` `Applied` `WindowSection` `Center` `Unload` `UnloadTitle` `UnloadText` `Yes` `HistorySection` `Undo` `Redo` `NothingUndo` `NothingRedo` `Modified` `ChangedCount` `AllDefault` `Snapshot` `SnapSaved` `Restore` `Restored` `ResetAll` `ResetDone`

ตัวอย่าง (ใส่เฉพาะคีย์ที่อยากแปล ที่เหลือใช้ค่าเริ่มต้น):

```lua
local TEXT_TH = {
    -- THEME
    ThemeSection = "ธีมสี", RandomButton = "สุ่ม", DeleteButton = "ลบ",
    CreateButton = "สร้างและใช้ทันที",
    -- SETTINGS
    UISection = "UI / ปุ่มลัด", Save = "บันทึก", Load = "โหลด", Delete = "ลบ",
    Cancel = "ยกเลิก", Yes = "ตกลง", Copy = "คัดลอก Config", Import = "วางนำเข้า",
}

Window:CreateThemeTab({ Text = TEXT_TH })
Window:CreateSettingsTab({ Text = TEXT_TH })
```

---

## 9. ปุ่มลัดทั้งหมด

| ปุ่ม | ทำอะไร |
|---|---|
| `RightShift` (ตั้งได้ที่ `ToggleKey` หรือในแท็บ SETTINGS) | เปิด/ปิดเมนู |
| `Ctrl + K` | เปิดค้นหา / Command Palette |
| `F6` / `F5` | สลับธีมถัดไป / ก่อนหน้า (ตั้งใหม่หรือปิดได้ที่ตัวเลือก `Keys`) |
| `Ctrl + Z` / `Ctrl + Y` | Undo / Redo การแก้ค่า |
| คลิกขวา หรือกดค้างที่ control | รีเซ็ต / คัดลอก / ล็อก |
| ตอนตั้งปุ่ม Keybind: `Esc` / `Backspace` | ยกเลิก / ลบปุ่ม |

---

## 10. ปัญหาที่พบบ่อย

**เมนูไม่ขึ้น**
ตรวจว่า `SpectreUI.lua` อยู่ในโฟลเดอร์ workspace ของ executor และชื่อไฟล์ตรงกับที่ใส่ใน `readfile("SpectreUI.lua")` แล้วลองกดปุ่มเปิด/ปิดเมนู (`RightShift` ตามตัวอย่าง)

**Config ไม่โหลดตอนเริ่ม**
ต้องมีไฟล์ `auto.json` (กด "บันทึกเป็น auto" ในแท็บ SETTINGS ก่อน) และ `Library:AutoloadConfig("auto", true)` ต้องอยู่ท้ายสคริปต์ หลังสร้างทุก control แล้ว

**ธีมที่เลือกไว้ไม่ถูกจำ**
ถ้าใส่ `Theme = "..."` ใน `CreateWindow` ธีมนั้นจะถูกบังคับทุกครั้ง ลบตัวเลือกนี้ออกเพื่อให้ธีมที่ผู้ใช้เลือกโหลดกลับมาเอง

**มือถือกระตุก / เครื่องช้า**
ตั้ง `Library.Perf.LowPower = true` หรือให้ผู้ใช้เลือกคุณภาพ `low` ในแท็บ THEME (ปิดพื้นหลังไล่สีและเอฟเฟกต์)

**กด "คัดลอก Config" แล้วไม่ได้**
executor ไม่รองรับคลิปบอร์ด ใช้การบันทึกเป็นไฟล์ Config แทน

**อัปเดตแล้วค่าที่เคยตั้งไว้หาย**
ดูหัวข้อ 12 Flag ของส่วนธีมกับปุ่มเมนูถูกเปลี่ยนชื่อ

---

## 11. รวม API ทั้งหมด (Reference)

ส่วนนี้ไล่ทุก API ที่มีใน `SpectreUI.lua` เพื่อให้รู้ว่ามีอะไรให้ใช้บ้าง

### 11.1 โหลด / ความคืบหน้า — Loading API

แถบโหลดแบบการ์ด ใช้บอกความคืบหน้างานที่ใช้เวลา (โหลดสคริปต์, เซฟ Config ฯลฯ) คืนค่า handle กลับมา

```lua
local l = Window:Loading({ Title = "กำลังโหลด", Text = "เริ่มต้น...", Progress = 0 })
-- หรือแบบสั้น: Window:Loading("กำลังโหลด...")
-- ไม่มี Window ก็ใช้ได้: Library:Loading({ ... })

l:Set(0.5, "ครึ่งทางแล้ว")      -- Progress 0..1 + ข้อความ (Set(false) = วนไม่รู้ความคืบหน้า)
l:SetText("กำลังดาวน์โหลด...")   -- เปลี่ยนแต่ข้อความ
l:Complete("เสร็จแล้ว", 2.5)     -- เปลี่ยนเป็นสำเร็จ แล้วปิดเองใน 2.5 วิ (ค่าเริ่มต้น 2.5)
l:Fail("ล้มเหลว", 4)             -- เปลี่ยนเป็นล้มเหลว แล้วปิดเองใน 4 วิ (ค่าเริ่มต้น 4)
l:Close()                        -- ปิดเอง
```

| ตัวเลือก | ความหมาย |
|---|---|
| `Title` | หัวข้อ (ค่าเริ่มต้น `"Loading"`) |
| `Text` / `Content` | ข้อความรอง |
| `Progress` | `0..1` = แถบแน่นอน, ไม่ใส่ = แถบวนไม่รู้ความคืบหน้า |
| `Closable` | `true` = มีปุ่มปิด (ค่าเริ่มต้น `false`) |

Loading ไม่ปิดเอง จนกว่าจะเรียก `Complete` / `Fail` / `Close`

ตัวอย่างโหลดงานจริง:

```lua
local l = Window:Loading({ Title = "โหลดข้อมูล", Text = "เริ่ม..." })
task.spawn(function()
    for i = 1, 10 do
        task.wait(0.2)
        l:Set(i / 10, ("ขั้นที่ %d/10"):format(i))
    end
    l:Complete("โหลดเสร็จ")
end)
```

### 11.1.1 Load API — โหลดสคริปต์ (v3.9)

โหลดสคริปต์จาก URL / ไฟล์ / โค้ดดิบ / ฟังก์ชัน พร้อมการ์ด Loading แสดงความคืบหน้า (ดาวน์โหลด → คอมไพล์ → รัน) และจบด้วย Complete / Fail เอง คืนค่า `ok, result`

```lua
-- URL (ลองใหม่เองถ้าพลาด)
local ok, res = Window:Load("https://example.com/script.lua", { Name = "MyScript" })

-- ไฟล์ใน workspace / โค้ดดิบ / ฟังก์ชัน
Library:Load("myscript.lua")
Library:Load("print('hi')")
Library:Load(function(a) print(a) end, { Args = { 123 } })

-- ไม่บล็อก + callback
Window:Load(url, { Async = true, OnDone = function(ok, res) print(ok, res) end })

-- หลายอันต่อกัน (การ์ดเดียว ความคืบหน้ารวม หยุดที่อันแรกที่พัง)
Window:LoadMany({
    "https://example.com/a.lua",
    { Source = "https://example.com/b.lua", Name = "B", Args = { Library } },
})
```

| ตัวเลือก | ความหมาย |
|---|---|
| `Name` | ชื่อที่แสดงในการ์ด |
| `Args` | อาร์กิวเมนต์ที่ส่งให้สคริปต์ (`{ ... }`) |
| `Retries` / `RetryDelay` | ลองดาวน์โหลดซ้ำ (ค่าเริ่มต้น `2` ครั้ง / `0.6` วิ) |
| `Silent` | `true` = ไม่แสดงการ์ด |
| `Async` | `true` = ไม่บล็อก (ใช้ `OnDone` รับผล) |
| `OnDone(ok, result)` / `OnProgress(p, text)` | callback จบงาน / ความคืบหน้า |
| `Cache` | `true` = ใช้ซอร์สที่ดาวน์โหลดไว้แล้ว (`Library.LoadCache`) |
| `Title` / `SuccessText` / `FailText` | ข้อความบนการ์ด |

ใช้ `game:HttpGet` ก่อน ถ้าไม่ได้จะลอง `request` / `syn.request` / `http_request` อัตโนมัติ ถ้าล้มเหลวจะแสดงสาเหตุบนการ์ดและ `warn` ออก console

### 11.1.2 ตรวจ UI อัตโนมัติ — Auto UI Check (v3.10)

ตรวจ UI ให้เองโดยไม่ต้องเรียก: ทำงานหลังสร้างหน้าต่าง (หน่วง 1.5 วิ), หลังสลับแท็บ และหลังปรับขนาด/หมุนจอ แจ้งเฉพาะปัญหา **ใหม่** ผ่าน `warn` ใน console และการ์ดแจ้งเตือนใบเดียว ถ้า UI ปกติจะเงียบ

```lua
-- เรียกเองตอนไหนก็ได้ ได้ list ของปัญหา
local issues = Window:Audit({ Print = true, Notify = true, Fix = true })
for _, i in ipairs(issues) do print(i.Level, i.Code, i.Message, i.Tab, i.Name) end

-- ทุกหน้าต่าง
Library:Audit({ Print = true })

-- ปรับค่ากลาง / ต่อหน้าต่าง
Library.AutoCheck.Notify = false                       -- ไม่เด้งการ์ด (ยัง warn ใน console)
Library.AutoCheck.Skip = { TextClip = true }           -- ปิดบางกฎ
Library:CreateWindow({ Title = "X", AutoCheck = false })                 -- ปิดทั้งหน้าต่าง
Library:CreateWindow({ Title = "X", AutoCheck = { Delay = 3 } })         -- ตั้งค่าเฉพาะหน้าต่าง
```

มีคำสั่ง **"Run UI check"** ใน Command Palette (Ctrl+K) ด้วย

| ตัวเลือก (`Library.AutoCheck` / `Window:Audit`) | ความหมาย |
|---|---|
| `Enabled` | เปิด/ปิดตรวจอัตโนมัติ (ค่าเริ่มต้น `true`) |
| `Delay` | หน่วงก่อนตรวจหลังสร้างหน้าต่าง (วินาที, ค่าเริ่มต้น `1.5`) |
| `Print` / `Notify` | `warn` ใน console / การ์ดสรุป |
| `Visual` | ตรวจสิ่งที่เห็นบนจอ (ข้อความล้น, ล้นหน้าต่าง, ขนาดศูนย์, หลุดจอ) |
| `Fix` | แก้ให้เองเมื่อทำได้ (ตอนนี้: หน้าต่างหลุดจอ → จัดกลางจอ) `Window:Audit` ต้องใส่ `Fix = true` เอง |
| `Skip` | `{ ชื่อกฎ = true }` ข้ามกฎนั้น |

กฎที่ตรวจ (`Library.AuditCodes` ดูคำอธิบายได้):

| Code | ระดับ | ตรวจอะไร |
|---|---|---|
| `DupFlag` / `BadFlag` | error | Flag ซ้ำ / Flag ไม่ใช่ string |
| `BadCallback` | error | `Callback` ไม่ใช่ function |
| `BadRange` | error | `Min` ไม่น้อยกว่า `Max` |
| `Orphan` | error | control ถูกลบ/หลุดจาก UI |
| `DefaultName` | warn | ไม่ใส่ `Name` เลยโชว์ชื่อชนิด |
| `BadDefault` / `DefaultRange` | warn | `Default` ไม่อยู่ใน `Options` / นอกช่วง |
| `EmptyTab` / `EmptySection` / `DupTab` | warn | แท็บ/section ว่าง, ชื่อแท็บซ้ำ |
| `LowContrast` | warn | สีตัวอักษรกับสีการ์ดของธีมอ่านยาก |
| `ZeroSize` / `Overflow` / `Offscreen` | warn | control สูง 0 / ล้นขอบหน้าต่าง / หน้าต่างหลุดจอ |
| `TextClip` | info | ข้อความถูกตัด |

การตรวจ `Visual` ดูเฉพาะแท็บที่เปิดอยู่ ดังนั้นปัญหาข้อความล้นของแท็บอื่นจะถูกตรวจเมื่อสลับไปแท็บนั้น

### 11.2 แจ้งเตือน / Dialog

ทุกตัวคืน handle และใช้ได้ทั้ง `Window:` และ `Library:` (ไม่ต้องมีหน้าต่างก็ได้)

| API | ทำอะไร |
|---|---|
| `Window:Notify({ ... })` | การ์ดแจ้งเตือนเต็มรูปแบบ |
| `Window:Success / Warning / Error / Info(title, content, dur)` | ทางลัดของ Notify ตามชนิด |
| `Window:Toast("ข้อความ", "Success" \| 3 \| {Kind, Duration, Icon})` | แถบเล็กกลางล่าง |
| `Library:Banner({ Title, Content, Duration, Color })` | แถบด้านบน ใช้ได้ตอนเมนูปิด |
| `Window:Loading(cfg)` | แถบโหลด (หัวข้อ 11.1) |
| `Window:Dialog(cfg)` | กล่องโต้ตอบปรับแต่งได้เต็มที่ |
| `Window:Confirm({ Title, Content, Yes, No, OnYes, OnNo, Danger })` | ถามยืนยัน ใช่/ไม่ |
| `Window:Alert(title, content)` | กล่องแจ้งให้ทราบ ปุ่มเดียว |
| `Window:Prompt({ Title, Placeholder, OnSubmit(text) })` | กล่องให้พิมพ์ข้อความ |
| `Window:DismissAll()` / `Library:DismissAll()` | ปิดการแจ้งเตือนทั้งหมด |
| `Window:SetNotifyTheme("Cyber" \| tbl \| nil)` | ธีมสีเฉพาะของการแจ้งเตือน/Dialog ในหน้าต่างนั้น |

**Notify** — ตัวเลือก: `Title`, `Content`, `Kind` (`Success`/`Warning`/`Error`/`Info`), `Duration`, `Icon`, `Color`, `Flash`, `Progress` (`true` = แถบนับถอยหลัง, `0..1` = แน่นอน), `Key` (Key เดียวกัน = อัปเดตการ์ดเดิม), `Position`, `OnClick`, `OnClose(reason)`, `Closable`, `Merge`, `Sound`

- `Duration = 0 / false / math.huge` = ค้างจนกว่าจะปิด
- handle: `:Update{...}` `:SetProgress(n)` `:Dismiss()` `:IsAlive()` `:OnClose(fn)`

**Dialog** — ตัวเลือก: `Title`, `Content`, `Kind`, `Icon`, `Width`, `Buttons = { { Text, Value, Style = "Primary"|"Secondary"|"Danger", Callback, Close } }`, `Input = true | { Placeholder, Default, MaxLength, Numeric }`, `Build = function(container, theme, handle) end`, `Dismissable`, `OnClose`

- handle: `:Close(value)` `:Update{}` `:IsOpen()` `:GetInput()` `:Wait()` → `value, input`

ตั้งค่ากลาง `Library.NotifyConfig`: `Position`, `MaxVisible`, `Duration`, `Gap`, `Margin`, `Width`, `Merge`, `PauseOnHover`, `Animate`

เสียง: `Library.Sound.Enabled = false` ปิดทั้งหมด, `Library.Sound.Volume = 0.6`, เปลี่ยนเสียงด้วย `Library.Sound.Toggle` / `.Notify`

### 11.3 ไอคอน

```lua
Window:CreateTab({ Name = "Combat", Icon = "lucide:swords" })
Tab:CreateSection({ Name = "ESP", Icon = "lucide:eye" })
Section:CreateButton({ Name = "บันทึก", Icon = "lucide:save" })
Window:Notify({ Title = "สวัสดี", Icon = "lucide:bell" })
```

- แพ็ก: `lucide` (ค่าเริ่มต้น) / `solar` / `craft` / `geist` / `sfsymbols` / `gravity` เขียน `"pack:ชื่อ"` หรือแค่ `"ชื่อ"`
- `Icon` รับได้: ตัวอักษร, asset id (ตัวเลข / `"rbxassetid://..."`), ชื่อไอคอน
- โหลดแพ็กตอนใช้ครั้งแรก (อาจใช้เวลาสองสามวินาที) ถ้าโหลดไม่ได้จะใช้ตัวอักษรแทน

| API | ทำอะไร |
|---|---|
| `Library.IconLib.Default = "solar"` | แพ็กเริ่มต้นสำหรับชื่อที่ไม่มี `pack:` |
| `Library.IconLib.Url = "..."` | ที่อยู่อื่นของ `Main-v2.lua` |
| `Library:PreloadIcons()` | ดาวน์โหลดล่วงหน้า (เรียกก่อนสร้างหน้าต่าง) |
| `Library:SetIconModule(mod)` | ใช้โมดูลที่โหลดไว้แล้ว |
| `Library:AddIcons("mine", { home = 123456 })` | เพิ่มแพ็กของตัวเอง → `Icon = "mine:home"` |
| `Library:IsIconName(name)` / `ResolveIcon(name)` / `MakeIcon(desc, color)` | ตัวช่วยระดับล่าง |

ไอคอนในแท็บสำเร็จรูป เปลี่ยนหรือเอาออกได้ด้วย `Icons = { ... }`:

```lua
Window:CreateSettingsTab({ Icons = { Theme = "solar:palette-bold", Save = "lucide:download", Delete = false } })
```

คีย์ของ SETTINGS: `ThemeSection UISection ConfigSection WindowSection HistorySection RandomButton Palette Save Load Delete SaveAuto Copy Import Center Unload Undo Redo Modified Snapshot Restore` · คีย์ของ THEME: `ThemeSection MakerSection FxSection CreateButton`

### 11.4 Library

| API | ทำอะไร |
|---|---|
| `Library:CreateWindow(cfg)` | สร้างหน้าต่าง |
| `Library:Unload()` | ทำลายทุกหน้าต่างและล้าง Flags |
| `Library.Flags` | ตารางค่าของทุก control ที่มี `Flag` |
| `Library.Version` | เวอร์ชัน (`"3.10"`) |
| `Library:SetQuality("low"\|"high"\|"auto")` | ทางลัดของ `Perf.LowPower` |
| `Library:OnFlag(fn(flag, value, prev))` | ดักทุกการเปลี่ยนค่า (คืน connection มี `:Disconnect()`) |
| `Library:Watch("flag", fn(value, prev))` | ดักเฉพาะ Flag เดียว |
| `Library:AddCommand({ Name, Desc, Keywords, Callback })` | เพิ่มคำสั่งใน Command Palette |
| `Library:Goto(obj \| "flag" \| "ชื่อ")` | กระโดดไป control นั้น |
| `Library:ShowMenu(items, anchorFrame)` / `CloseMenu()` | เมนูคลิกขวาของเราเอง (`Library.ContextMenu = false` = ปิดทั้งระบบ) |
| `Library.PaletteKey` | ปุ่มคู่กับ Ctrl เปิดค้นหา (ค่าเริ่มต้น `K`) |
| `Library.Anim.Speed` | ความเร็วอนิเมชันทั้งหมด (1.25 = ช้าลง 25%) |
| `Library.Perf` | `LowPower`, `Adaptive`, `SlowFrame`, `SlowShare`, `Warmup`, `Backdrop` |

### 11.5 Config / Undo / Snapshot

| API | ทำอะไร |
|---|---|
| `Library:SaveConfig(name)` | บันทึก Config เป็นไฟล์ |
| `Library:LoadConfig(name, silent)` | โหลด Config |
| `Library:DeleteConfig(name)` | ลบ Config |
| `Library:ListConfigs()` | รายชื่อ Config ทั้งหมด |
| `Library:ExportConfig()` | คืน JSON (string) เช่นเอาไปใส่คลิปบอร์ด |
| `Library:ImportConfig(json, silent)` | นำเข้าจาก JSON |
| `Library:AutoloadConfig(name, silent)` | โหลดตอนเริ่ม (เรียกท้ายสุด) |
| `Library:SaveAuto(name)` | บันทึกเป็นไฟล์ auto |
| `Library:Undo(silent)` / `Redo(silent)` | ย้อน/ทำซ้ำ (Ctrl+Z / Ctrl+Y) |
| `Library:CanUndo()` / `CanRedo()` | เช็กว่าย้อนได้ไหม |
| `Library:GetHistory()` / `ClearHistory()` | ประวัติการแก้ค่า (`Library.History.Max` = จำนวนสูงสุด) |
| `Library:Transaction("ชื่อ", fn)` | หลายการเปลี่ยนค่า = Undo ขั้นเดียว |
| `Library:Snapshot("a")` / `Restore("a")` / `Diff("a","b")` | โปรไฟล์ในหน่วยความจำ ไม่ต้องใช้ไฟล์ |
| `Library:GetModified()` | รายการ control ที่ค่าต่างจากค่าเริ่มต้น |
| `Library:ResetAll()` | รีเซ็ตทุก control (มี `Tab:ResetAll()` และ `Section:ResetAll()` ด้วย) |

### 11.6 ธีม

| API | ทำอะไร |
|---|---|
| `Library:SetTheme(name \| tbl)` | ธีมเริ่มต้นของหน้าต่างที่สร้างหลังจากนี้ |
| `Window:SetTheme(name \| tbl, remember)` | เปลี่ยนสีทั้งหน้าต่างสด ๆ |
| `Window:GetThemeName()` / `Library.ThemeName` | ชื่อธีมปัจจุบัน |
| `Window:CycleTheme(dir, remember)` | ธีมถัดไป (`1`) / ก่อนหน้า (`-1`) |
| `Window:RandomTheme(remember)` | สุ่มธีม |
| `Window:RenameTheme("ชื่อใหม่")` / `Library:RenameTheme(old, new)` | เปลี่ยนชื่อธีม → `ok, err` |
| `Window:DeleteTheme(name?)` / `Library:DeleteTheme(name)` | ลบธีม (เฉพาะที่สร้างเอง) |
| `Library:CloneTheme(src, newName, overrides)` | ทำสำเนาธีม |
| `Library:RegisterTheme(name, tbl)` | ลงทะเบียนธีมใหม่ |
| `Library:GetTheme(name?)` / `ListThemes()` | อ่านธีม / รายชื่อธีม |
| `Library:OnThemeChange(fn(event, a, b))` | ดักเมื่อธีมเปลี่ยน |
| `Library:SaveThemes()` / `LoadThemes()` | บันทึก/โหลด `themes.json` |
| `Library:SetStatusColors({ Success = c, ... })` / `GetStatusColor(kind)` | สีของ Success/Warning/Error/Info |
| `Section:CreateThemeManager({ Name, Flag, Remember, Random, Delete })` | UI จัดการธีมสำเร็จรูป |

ธีมที่มีให้: Rose (ค่าเริ่มต้น), Violet, Cyber, Crimson, Matrix, Aurora, Dracula, Nord, TokyoNight, Mocha, Synthwave, Jade, Gold, Lavender, Candy, Peach, Midnight, Ocean, Sunset, Mono

### 11.7 Window (ทั้งหมด)

`CreateWindow` รับ: `Title`, `Logo` (asset id), `Width`, `Height`, `ToggleKey`, `Theme` (ชื่อหรือ table), `FX` (`"petals"`/`"orbs"`/`"grid"`/`"embers"`/`"rain"`), `Background = false` (ปิดพื้นหลัง), `Resizable = false`, `OnClose`, `OnDegrade(level)`

| เมธอด | ทำอะไร |
|---|---|
| `Window:CreateTab(cfg)` | สร้างแท็บ: `Name`, `Icon`, `Locked`, `LockReason`, `OnLockedClick`, `LockedNotify` |
| `Window:GetTab(name)` / `SetTab(nameOrTab)` | หา / สลับแท็บ |
| `Window:LockTab(tab, reason)` / `UnlockTab(tab)` / `IsTabLocked(tab)` | ล็อก/ปลดล็อกแท็บ |
| `Window:SetVisible(v)` / `Toggle()` | แสดง/ซ่อนเมนู |
| `Window:SetMaximized(v)` / `IsMaximized()` | ขยายเต็มจอ |
| `Window:Resize(w, h)` / `SetSize(w, h)` / `Center()` | ปรับขนาด / จัดกลาง |
| `Window:SetTitle("แบรนด์ \| ย่อย")` | เปลี่ยนชื่อหน้าต่าง |
| `Window:Flash(color)` | กระพริบหน้าต่าง |
| `Window:Tooltip(frame, "ข้อความ")` | ใส่ทิปให้ UI ใดก็ได้ (ทุก control มี `.Frame`) |
| `Window:SetBackground("orbs"\|false\|nil)` | เปลี่ยนเอฟเฟกต์พื้นหลังตอนรัน (`nil` = ตามธีม) |
| `Window:OpenPalette(initial)` / `ClosePalette()` | เปิด/ปิดค้นหา (Ctrl+K) |
| `Window:Goto(obj \| "flag" \| "ชื่อ")` | กระโดดไป control |
| `Window:OnResize(fn)` | ดักตอนปรับขนาด |
| `Window:CloseDropdowns()` | ปิด dropdown ที่เปิดอยู่ |
| `Window:Destroy()` | ทำลายหน้าต่างนี้ |

### 11.8 Tab / Section

| เมธอด | ทำอะไร |
|---|---|
| `tab:CreateSection({ Name, Column, Collapsible, Collapsed, Icon })` | สร้าง section (`Column` = `1` หรือ `2`) |
| `tab:SetBadge("3")` | ป้ายตัวเลขที่แท็บ |
| `tab:Lock(reason)` / `Unlock()` / `SetLocked(bool, reason)` / `IsLocked()` / `SetLockReason(text)` | ล็อกแท็บ (แสดงแม่กุญแจ เปิดไม่ได้) |
| `tab:ResetAll()` / `section:ResetAll()` | รีเซ็ตค่าทั้งแท็บ / ทั้ง section |
| `section:SetCollapsed(bool, instant)` | พับ/กาง section |

### 11.9 Controls ทั้งหมด

| Control | ตัวเลือกสำคัญ | เมธอดเฉพาะ |
|---|---|---|
| `CreateToggle` | `Name, Default, Flag, Callback` | `:Set(v, silent)` `:Get()` |
| `CreateSlider` | `Name, Min, Max, Default, Increment, Suffix` | `:Set` `:Get` |
| `CreateRangeSlider` | `Min, Max, Increment, MinGap, Default={lo,hi}` | `:Set` `:Get()` → `{lo,hi}` |
| `CreateDropdown` | `Options, Default, Multi, Images, ImageSize` | `:Open` `:Close` `:Set` `:Get` `:Refresh(options, keep, images)` `:SetImage(opt, image)` |
| `CreateSegmented` | `Options, Default` | `:Set` `:Get` `:SetOptions(list, keep)` |
| `CreateKeybind` | `Default, Mode="Press"\|"Hold"\|"Toggle", Changed(key)` | `:Set` `:Get` `:GetState()` |
| `CreateKeybindToggle` | `Key, Default` | `:Set` `:Get` `:SetKey` `:GetKey` |
| `CreateColorPicker` | `Default (Color3)` | `:Open` `:Close` `:Set` `:Get` |
| `CreateTextbox` | `Default, Placeholder, ClearOnFocus, Numeric, Min, Max, MaxLength, Live, EnterOnly` | `:Set` `:Get` |
| `CreateTagInput` | `Default, Placeholder, Max, Lower` | `:Add` `:Remove` `:Has` `:Set` `:Get` |
| `CreateButton` | `Callback, Color, Gradient, TextColor, Bold, Icon` | `:SetText(t)` |
| `CreateHoldButton` | `Duration, Color, Callback` (กดค้างเพื่อยืนยัน) | `:SetText(t)` |
| `CreateLabel` | `Text, Color, Bold, TextSize` | `:Set(t)` `:SetColor(c)` |
| `CreateParagraph` | `Title, Content` | `:Set(title, content)` |
| `CreateBadge` | `Name, ...` (ป้ายสถานะ) | `:Set(v)` `:SetColor(c)` |
| `CreateProgress` | `Name, Min, Max, Default, Suffix` | `:Set(v)` `:Get()` `:SetColor(c)` |
| `CreateGraph` | `Name, Points, Height, Min, Max, Suffix` | `:Push(n)` `:Clear()` `:SetRange(lo, hi)` `:Get()` |
| `CreateConsole` | `Name, Height, MaxLines` | `:Print(text, color)` `:Info` `:Warn` `:Error` `:Clear()` `:GetText()` `:Copy()` |
| `CreateDivider()` / `CreateSeparator(cfg)` | เส้นคั่น | — |

### 11.10 เมธอดที่ทุก control มี

| เมธอด | ทำอะไร |
|---|---|
| `:SetVisible(bool)` / `:IsVisible()` | ซ่อน/แสดง |
| `:ShowIf("flag" [, ค่า \| fn(v, flags)])` หรือ `:ShowIf({"a","b"}, fn(flags))` | แสดงตามเงื่อนไข |
| `:SetEnabled(bool)` / `:Lock()` / `:Unlock()` | ทำให้จาง + กันการกด |
| `:OnChange(fn(value, prev))` | ดักการเปลี่ยนค่า (ต้องมี `Flag`) |
| `:Reset()` / `:IsModified()` | กลับค่าเริ่มต้น / เช็กว่าถูกแก้ |
| `:SetTooltip(text)` | ตั้งทิป (หรือใส่ `Tooltip = "..."` ตอนสร้าง) |
| `:Destroy()` | ลบ control |

ตัวเลือก `NoMenu = true` ปิดเมนูคลิกขวาของ control นั้น และ `ContextMenu = { { Name, Callback(obj) } }` เพิ่มรายการเอง

### 11.11 Helper

- `Library.Util`: `Bag`, `Dispose`, `Opt`, `Debounce`, `Throttle`, `Round`, `FormatNumber`, `FormatTime`, `Truncate`, `Lighten`, `Darken`, `ToHex`, `FromHex`, `Contrast`, `Create`
- `Library.Anim`: `Tween`, `Show(obj, { From, Distance, Time, Scale })`, `Hide(obj, { To, Destroy })`, `Pulse(obj)`, `Stop(obj)`, `Speed`
- `Library.Responsive`: `IsTouch`, `Viewport(win)`, `Breakpoint(win)` → `"phone"`/`"tablet"`/`"desktop"`, `Width(win, max, margin)`, `Touch(pc, touch)`, `Scale(n)`, `OnChange(win, fn)`

---

## 12. บันทึกการเปลี่ยนแปลง

### v3.10

- เพิ่มระบบตรวจ UI อัตโนมัติ: `Window:Audit` / `Library:Audit` / `Library.AutoCheck` (หัวข้อ 11.1.2)

### v3.9

- เพิ่ม Load API: `Library:Load` / `LoadMany` และ `Window:Load` / `LoadMany` (หัวข้อ 11.1.1)

### v3.8

- เพิ่มระบบไอคอน (หัวข้อ 11.3) และไอคอนในแท็บสำเร็จรูป
- README นี้รวม API ทั้งหมดไว้ที่หัวข้อ 11 (Loading / Notify / Dialog / Tab Lock / Textbox / Graph / Console ฯลฯ)

### v3.7

- แท็บ THEME และ SETTINGS เป็นของสำเร็จรูป เรียกได้ด้วย `CreateThemeTab` / `CreateSettingsTab` / `CreateDefaultTabs`
- เพิ่มปุ่ม คัดลอก/นำเข้า Config และแจ้งผลทุกปุ่ม
- ถามยืนยันก่อนลบ Config และก่อน Unload
- แก้ปุ่มเมนู: ถ้าโหลด Config ที่มีปุ่มเมนูต่างจากเดิม ปุ่มเปิด/ปิดเมนูจะตามค่าที่โหลดด้วย (เดิมไม่ตาม)
- Flag ของส่วนธีมเปลี่ยนชื่อ มีคำนำหน้า `ui_`:

| เดิม | ใหม่ |
|---|---|
| `bg_fx` | `ui_bg_fx` |
| `quality` | `ui_quality` |
| `theme_next_key` | `ui_theme_next` |
| `theme_prev_key` | `ui_theme_prev` |
| `menu_key` | `ui_menu_key` |

Config เก่าที่บันทึกไว้จะไม่ผูกกับค่าเหล่านี้ แค่ตั้งใหม่ครั้งเดียวแล้วบันทึกทับ
