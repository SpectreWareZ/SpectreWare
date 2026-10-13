# SpectreUI v3.17 — คู่มือใช้งาน

SpectreUI คือไลบรารี UI สำหรับสคริปต์ Roblox (Lua) มีหน้าต่าง แท็บ ตัวควบคุมครบ (สวิตช์ สไลเดอร์ ดรอปดาวน์ คีย์บายด์ ตาราง ฯลฯ) ระบบธีม ระบบ Config และ Command Palette (`Ctrl+K`) ในตัว

แท็บ **SETTINGS** เป็นของสำเร็จรูป รวมธีม ฟอนต์ เอฟเฟกต์ ปุ่มลัด Config และ Undo ไว้ในแท็บเดียว เรียกบรรทัดเดียวก็ได้ ไม่ต้องเขียนเอง

> **ไม่รู้จะเริ่มตรงไหน?** อ่านหัวข้อ 1–4 (ประมาณ 5 นาที) ก็เขียน UI เป็นแล้ว ที่เหลือเปิดดูเฉพาะตอนต้องใช้

**สารบัญ**

1. [สิ่งที่ต้องมี](#1-สิ่งที่ต้องมี)
2. [เริ่มต้นเร็ว](#2-เริ่มต้นเร็ว-copy-แล้วรัน)
3. [อยากทำอะไร → ใช้อะไร](#3-อยากทำอะไร--ใช้อะไร)
4. [แนวคิดหลัก](#4-แนวคิดหลัก)
5. [โหลดแบบเป็นขั้น + หน้าโหลดตอนเปิด](#5-โหลดแบบเป็นขั้น--หน้าโหลดตอนเปิด)
6. [Controls ทุกตัว](#6-controls-ทุกตัว)
7. [สิ่งที่ทุก control มี](#7-สิ่งที่ทุก-control-มี)
8. [แจ้งเตือน / Dialog / Loading](#8-แจ้งเตือน--dialog--loading)
9. [Flag, Config, Undo](#9-flag-config-undo)
10. [ธีมและฟอนต์](#10-ธีมและฟอนต์)
11. [แท็บสำเร็จรูป SETTINGS](#11-แท็บสำเร็จรูป-settings)
12. [Command Palette และปุ่มลัด](#12-command-palette-และปุ่มลัด)
13. [HUD และ Tour](#13-hud-และ-tour)
14. [Load API (โหลดสคริปต์)](#14-load-api-โหลดสคริปต์)
15. [ตรวจ UI อัตโนมัติ](#15-ตรวจ-ui-อัตโนมัติ)
16. [ไอคอน](#16-ไอคอน)
17. [ตาราง API ของ Library / Window / Tab / Section](#17-ตาราง-api-ของ-library--window--tab--section)
18. [ปัญหาที่พบบ่อย](#18-ปัญหาที่พบบ่อย)
19. [บันทึกการเปลี่ยนแปลง](#19-บันทึกการเปลี่ยนแปลง)

---

## 1. สิ่งที่ต้องมี

- executor ที่รองรับ `loadstring`, `game:HttpGet` และฟังก์ชันไฟล์ (`readfile` / `writefile` ใช้บันทึก Config กับธีม)
- ไม่ต้องดาวน์โหลดไฟล์เอง: สคริปต์โหลด `SpectreUI.lua` จาก GitHub ทุกครั้งที่รัน (ต้องต่ออินเทอร์เน็ต)
- ปุ่ม "คัดลอก Config" ต้องใช้คลิปบอร์ด ถ้าไม่รองรับ UI จะแจ้งว่าเครื่องนี้ใช้ไม่ได้
- ถ้าใช้เป็น ModuleScript ให้ใช้ `require(ModuleScript)` แทน `loadstring(game:HttpGet(...))`

---

## 2. เริ่มต้นเร็ว (copy แล้วรัน)

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/SpectreWareZ/SpectreWare/refs/heads/main/Tools/Ui/SpectreUI.lua"))()

local Window = Library:CreateWindow({
    Title     = "SpectreWare | ชื่อเกม",
    ToggleKey = Enum.KeyCode.RightShift,   -- ปุ่มเปิด/ปิดเมนู
})

-- แท็บ → section → control  (ใส่ controls ใน Build เพื่อให้โหลดทีละขั้น ดูหัวข้อ 5)
Window:CreateTab({ Name = "MAIN", Icon = "lucide:home", Build = function(tab)
    local sec = tab:CreateSection({ Name = "ทั่วไป" })

    sec:CreateToggle({
        Name = "เปิดฟีเจอร์", Default = false, Flag = "feature_on",
        Callback = function(on) print("feature", on) end,
    })

    sec:CreateSlider({ Name = "ความเร็ว", Min = 16, Max = 200, Default = 16, Flag = "speed" })
end })

-- แท็บตั้งค่าสำเร็จรูป (มีธีม/ฟอนต์/Config/ปุ่มลัดครบในแท็บเดียว): เรียกท้ายสุด จะได้อยู่ล่างแถบด้านข้าง
Window:CreateSettingsTab()      -- หรือ Window:CreateDefaultTabs() ได้แท็บเดียวกัน

-- โหลด Config อัตโนมัติ: ต้องรอให้ UI สร้างเสร็จก่อน
Window:OnLoaded(function()
    Library:AutoloadConfig("auto", true)
end)
```

ลำดับคือ **Window → Tab → Section → Control** ทุก control ต้องอยู่ใน section ทุก section ต้องอยู่ในแท็บ

---

## 3. อยากทำอะไร → ใช้อะไร

| อยากทำ | ใช้ | ดูหัวข้อ |
|---|---|---|
| สวิตช์เปิด/ปิด | `CreateToggle` | 6 |
| ปรับค่าเป็นตัวเลข | `CreateSlider` / `CreateStepper` / `CreateRangeSlider` | 6 |
| เลือกจากรายการ | `CreateDropdown` / `CreateSegmented` / `CreateListBox` | 6 |
| ผูกปุ่มคีย์บอร์ด | `CreateKeybind` / `CreateKeybindToggle` | 6 |
| ให้พิมพ์ข้อความ | `CreateTextbox` / `CreateInputButton` / `CreateTagInput` | 6 |
| ปุ่มกด | `CreateButton` / `CreateButtonRow` / `CreateHoldButton` | 6 |
| แสดงค่าสด / สถานะ | `CreateStat` / `CreateKeyValue` / `CreateProgress` / `CreateCountdown` | 6 |
| แสดงตาราง / ไอเทม / รูป | `CreateTable` / `CreateItemGrid` / `CreateImage` | 6 |
| แสดงโค้ด / log | `CreateCodeBlock` / `CreateConsole` | 6 |
| แจ้งเตือน / ถามยืนยัน | `Window:Notify` / `Toast` / `Confirm` / `Prompt` / `AskAmount` | 8 |
| บอกความคืบหน้า | `Window:Loading` | 8 |
| อ่านค่าที่ผู้ใช้ตั้ง | `Library.Flags["flag"]` | 9 |
| บันทึก/โหลดค่าตั้งค่า | `Library:SaveConfig` / `LoadConfig` / `AutoloadConfig` | 9 |
| เปลี่ยนธีม / ฟอนต์ | `Window:SetTheme` / `SetFont` | 10 |
| แท็บตั้งค่า + ธีมสำเร็จรูป | `Window:CreateSettingsTab()` | 11 |
| ลายน้ำ FPS / รายการคีย์ / ทัวร์สอนใช้ | `Watermark` / `KeybindList` / `Tour` | 13 |
| โหลดสคริปต์จาก URL | `Window:Load(url)` | 14 |
| ล็อกแท็บ VIP | `CreateTab({ Locked = true })` | 17 |

---

## 4. แนวคิดหลัก

### โครงสร้าง

```
Library
 └─ Window (หน้าต่าง)
     └─ Tab (แท็บด้านข้าง)
         └─ Section (กล่องในแท็บ)
             └─ Control (สวิตช์, สไลเดอร์, ปุ่ม ...)
```

### ตัวเลือกที่ control ส่วนใหญ่ใช้ร่วมกัน

| ตัวเลือก | ความหมาย |
|---|---|
| `Name` | ชื่อที่แสดง |
| `Default` | ค่าเริ่มต้น |
| `Flag` | ชื่อประจำ control ใช้อ่านค่าผ่าน `Library.Flags["ชื่อ"]` และให้ Config จำค่า (**ไม่มี Flag = ไม่ถูกบันทึกใน Config**) |
| `Callback` | ฟังก์ชันที่ถูกเรียกเมื่อค่าเปลี่ยน |
| `Tooltip` | ข้อความอธิบายตอนชี้ที่ control |
| `ContextMenu` | เมนูคลิกขวา/กดค้างที่เพิ่มเอง |

ผู้ใช้คลิกขวา (หรือกดค้างบนมือถือ) ที่ control ใดก็ได้ เพื่อ **รีเซ็ต / คัดลอก / ล็อก** ค่า

### อ่าน/ตั้งค่า

```lua
if Library.Flags["aim_on"] then ... end      -- อ่านค่า
Library:SetFlag("aim_on", true)              -- ตั้งค่าด้วยโค้ด
local ctl = Library:GetControl("aim_on")     -- ได้ตัว control (ctl:Set / ctl:Get)
```

### โหมดประหยัด (มือถือ)

```lua
Library.Perf.LowPower = false   -- nil = อัตโนมัติ (มือถือเปิดเอง), true/false = บังคับ
```

---

## 5. โหลดแบบเป็นขั้น + หน้าโหลดตอนเปิด

UI โหลด 2 ช่วงให้ไม่กระตุกตอนเปิด และมีหน้าโหลด (Splash) ขึ้นเองตอน `CreateWindow` ทั้งสองอย่าง **เปิดอยู่ตามค่าเริ่มต้น** ไม่ต้องเขียนอะไรเพิ่ม

### 5.1 Staged Loading (v3.17)

| ช่วง | เกิดอะไรขึ้น |
|---|---|
| 1 | แท็บโผล่ทีละอัน (ปุ่มข้างๆ + หน้าว่างมีข้อความ "Loading...") |
| 2 | เมื่อแท็บ **ครบทุกอัน** แล้ว ฟังก์ชัน `Build` ของแต่ละแท็บถึงจะรัน (สร้าง section / control ตรงนี้) ทีละแท็บ |

ระหว่างนั้นมีการ์ด Loading ขึ้นบอกความคืบหน้า และจบด้วย "Ready"

**วิธีใส่ control เข้า Build (เลือกแบบใดก็ได้):**

```lua
-- แบบ 1: ใส่ Build ในตัวเลือก
local Main = Window:CreateTab({ Name = "Main", Icon = "lucide:home", Build = function(tab)
    local s = tab:CreateSection({ Name = "Settings" })
    s:CreateToggle({ Name = "Example", Flag = "ex" })
end })

-- แบบ 2: ส่งเป็นอาร์กิวเมนต์ตัวที่สอง
Window:CreateTab({ Name = "Misc" }, function(tab) ... end)

-- เพิ่มฟังก์ชันให้แท็บอีก (รันต่อกันตามลำดับ หลังทุกแท็บเข้าแล้ว)
Main:Load(function(tab) ... end)      -- Tab:Build ก็คือตัวเดียวกัน
```

control ที่สร้างตรงๆ นอก `Build` ก็ยังใช้ได้ทันทีเหมือนเดิม (แค่ไม่ได้โหลดเป็นขั้น)

| เมธอดของ Window | ทำอะไร |
|---|---|
| `Window:OnLoaded(fn)` | เรียก `fn` เมื่อโหลดครบ (ถ้าครบแล้วเรียกทันที) |
| `Window:IsLoaded()` | โหลดครบหรือยัง |
| `Window:WaitLoaded()` | รอจนโหลดครบ (ใช้ใน `task.spawn`) |
| `Window:StartLoad()` | สั่งเริ่มโหลดเอง (ต้องใช้เมื่อตั้ง `Auto = false` เท่านั้น) |

> ⚠️ **`Library:AutoloadConfig(...)` ไม่รอให้โหลดครบ** ถ้า control อยู่ใน `Build` ให้เรียกใน `Window:OnLoaded(function() ... end)` ไม่งั้นค่าที่โหลดจะไม่ถูกใส่ให้ control ที่ยังไม่ถูกสร้าง

ตั้งค่า (ค่ากลาง `Library.StagedLoad` หรือเฉพาะหน้าต่าง):

```lua
Library.StagedLoad.TabDelay = 0.2                       -- ค่ากลาง
Library:CreateWindow({ StagedLoad = false })            -- ปิดเฉพาะหน้าต่างนี้
Library:CreateWindow({ StagedLoad = { TabDelay = 0.2 } }) -- ปรับเฉพาะหน้าต่างนี้
Library.StagedLoad.Enabled = false                      -- ปิดทั้งระบบ
```

| ตัวเลือก | ค่าเริ่มต้น | ความหมาย |
|---|---|---|
| `Enabled` | `true` | เปิด/ปิดทั้งระบบ |
| `Auto` | `true` | เริ่มโหลดเองเมื่อสคริปต์ที่สร้างแท็บรันจบ/yield (`false` = ต้องเรียก `Window:StartLoad()` เอง) |
| `TabDelay` | `0.12` | หน่วงระหว่างโชว์แต่ละแท็บ (วินาที) |
| `BuildDelay` | `0.05` | หน่วงระหว่างรัน Build แต่ละอัน (วินาที) |
| `Loading` | `true` | แสดงการ์ด Loading |
| `Placeholder` | `true` | แสดงข้อความ "Loading..." ในหน้าแท็บที่ยังว่าง |
| `Title` / `TabsText` / `BuildText` | `"Loading"` / `"Loading tabs"` / `"Loading features"` | ข้อความบนการ์ด |

ระบบตรวจ UI อัตโนมัติ (หัวข้อ 15) จะรอจนโหลดครบก่อน เพื่อไม่ให้แจ้งว่าแท็บว่างทั้งที่ยังโหลดไม่เสร็จ

### 5.2 Splash — หน้าโหลดตอนเปิด UI (v3.16)

หน้าโหลดแบบเรียบ: โลโก้ + ชื่อ + แถบโหลดบางๆ + ข้อความสถานะบรรทัดเดียว เฟดเข้า/เฟดออก ใช้สีตามธีมของหน้าต่าง

```lua
-- ค่าเริ่มต้น: ไม่ต้องใส่อะไร (ประมาณ 2.5 วินาที)
local Window = Library:CreateWindow({ Title = "SpectreWare | Anime Astral" })

-- ปิดเฉพาะหน้าต่างนี้
Library:CreateWindow({ Title = "SpectreWare", Splash = false })

-- ปรับแต่ง
Library:CreateWindow({
    Title = "SpectreWare | Anime Astral",
    Splash = {
        Subtitle  = "ANIME ASTRAL",
        Duration  = 2.5,
        Steps     = { "Checking key", "Loading" },
        Logo      = 123456789,   -- asset id (ไม่ใส่ = ใช้ตัวอักษรแรกของชื่อ)
        Skippable = true,        -- แตะ/คลิกเพื่อข้าม
        Async     = false,       -- true = สร้างหน้าต่างทันที แล้วให้หน้าโหลดเล่นทับ
    },
})

-- ค่ากลาง (ใส่ก่อน CreateWindow)
Library.Splash.Enabled  = false
Library.Splash.Duration = 4
```

| ตัวเลือก | ค่าเริ่มต้น | ความหมาย |
|---|---|---|
| `Enabled` | `true` | เปิด/ปิดทั้งระบบ (ใช้ได้เฉพาะ `Library.Splash`) |
| `Title` / `Subtitle` | จาก `Title` ของ `CreateWindow` (ส่วนก่อน/หลัง `\|`) | ข้อความชื่อ / ข้อความรอง |
| `Duration` | `4` | ความยาว วินาที (ขั้นต่ำ `1`) ใช้เมื่อปิด `WaitBuild` เท่านั้น (ตัวอย่างด้านบนตั้ง `2.5` เอง) |
| `Steps` | `Loading`, `Preparing interface`, `Almost ready` | ข้อความสถานะที่ไล่เปลี่ยน (list ของ string) |
| `Logo` | `Logo` ของ `CreateWindow` | asset id หรือ `"rbxassetid://..."` |
| `Skippable` | `true` | แตะ/คลิกเพื่อข้าม (ไม่รับการแตะใน 0.8 วินาทีแรก) |
| `Async` | `false` | `true` = ไม่บล็อก |
| `WaitBuild` | `true` | หน้าต่างซ่อนไว้และ Splash ค้างจนสคริปต์สร้างแท็บ/control เสร็จ แล้วค่อยเปิดแบบครบ (ตรวจเองเมื่อไม่มี UI ใหม่เกิน `IdleTime`) · `false` = กลับเป็น Splash ตามเวลา `Duration` |
| `IdleTime` / `BuildTimeout` | `0.8` / `30` | วินาทีที่ไม่มี UI ใหม่ถึงถือว่าสร้างเสร็จ / เวลารอสูงสุดกันค้าง |
| `Theme` | `"Mono"` | สี Splash เมื่อผู้ใช้ยังไม่เคยเลือกธีม (ขาว/เทา) · ใส่ชื่อธีมเพื่อบังคับ · `false` = ใช้ธีมเริ่มต้นของ UI |
| `Panel` / `Block` / `Backdrop` | `true` / `false` / `1` | การ์ดไล่สีด้านหลัง / `true` = กันการแตะผ่าน / พื้นหลัง `1` โปร่งใส ถึง `0` ทึบ |

ข้อควรรู้:

- ค่าเริ่มต้น `CreateWindow` จะ **รอ** จน Splash จบ แล้วค่อยคืนหน้าต่าง สคริปต์ถัดไปจึงรันหลัง Splash จบ ถ้าไม่อยากรอใช้ `Async = true`
- ถ้าตรวจจังหวะ "สร้างเสร็จ" อัตโนมัติไม่แม่น (เช่น สร้าง UI ทีหลังด้วย `task.wait` นานๆ) คุมเองได้ด้วย `Window:HoldLoading()` / `Window:ReleaseLoading()` / `Window:FinishLoading()`
- ถ้า Splash มี error จะ `warn("[SpectreUI] splash error: ...")` ทิ้งหน้าโหลดแล้วสร้างหน้าต่างตามปกติ ไม่ทำให้ UI ไม่ขึ้น
- ตัวเลือกใน `Splash = { ... }` มีผลเฉพาะหน้าต่างนั้นและมาก่อนค่ากลาง

---

## 6. Controls ทุกตัว

ทุกตัวสร้างจาก section รับ table ตัวเลือก และคืนค่า control กลับมา

```lua
local sec = Tab:CreateSection({ Name = "ตัวอย่าง" })
```

### 6.1 เลือกค่า / ปรับค่า

#### Toggle — สวิตช์

```lua
sec:CreateToggle({ Name = "เปิด Aimbot", Default = false, Flag = "aim_on",
    Callback = function(v) print("aimbot", v) end })
```

#### Slider — แถบเลื่อน

```lua
sec:CreateSlider({ Name = "FOV", Min = 10, Max = 360, Default = 120, Suffix = "°", Flag = "aim_fov" })
    :ShowIf("aim_on", true)   -- โชว์เมื่อสวิตช์ aim_on เปิด

-- เพิ่มเมนูคลิกขวา
sec:CreateSlider({ Name = "WalkSpeed", Min = 16, Max = 200, Default = 16, Flag = "walkspeed",
    ContextMenu = {
        { Name = "ตั้งเป็น 50",  Callback = function(o) o:Set(50) end },
        { Name = "ตั้งเป็น 100", Callback = function(o) o:Set(100) end },
    } })
```

`Suffix` คือหน่วยต่อท้าย เช่น `"%"`, `"°"`, `"s"` · ตัวเลือกอื่น: `Increment` (ขนาดขั้น)

#### RangeSlider — แถบเลื่อนสองปลาย

```lua
sec:CreateRangeSlider({ Name = "ช่วงดีเลย์", Min = 0, Max = 5, Increment = 0.1, MinGap = 0.1,
    Default = { 0.5, 2 }, Suffix = "s", Flag = "delay_range",
    Callback = function(lo, hi) print("range", lo, hi) end })
```

`MinGap` = ระยะห่างต่ำสุดระหว่างสองปลาย · `:Get()` คืน `{ lo, hi }`

#### Stepper — ปุ่ม − ค่า +

```lua
sec:CreateStepper({ Name = "จำนวนรอบ", Min = 1, Max = 50, Step = 1, Default = 5, Flag = "loops" })
sec:CreateStepper({ Name = "ดีเลย์", Min = 0, Max = 5, Step = 0.25, Suffix = "s", Default = 1 })
sec:CreateStepper({ Name = "โหมด", Min = 1, Max = 4, Wrap = true })   -- ถึงปลายแล้ววนกลับ
```

กดปุ่มค้างเพื่อเพิ่มต่อเนื่อง (เร็วขึ้นเรื่อยๆ) · เมธอด: `:Set(v, silent)` `:Get()` `:Increment(n)` `:SetRange(min, max)`

#### Dropdown — รายการเลือก

```lua
-- เลือกได้อันเดียว
sec:CreateDropdown({ Name = "เป้าหมาย", Options = { "Head", "Torso", "Nearest" },
    Default = "Head", Flag = "aim_part" })

-- เลือกได้หลายอัน (Default และ Callback เป็น list)
sec:CreateDropdown({ Name = "เลือกหลายอัน", Multi = true,
    Options = { "Boss", "Elite", "Mob", "Chest" }, Default = { "Boss", "Mob" },
    Flag = "targets", Callback = function(list) print(table.concat(list, ", ")) end })

-- ตัวเลือกพร้อมรูป
sec:CreateDropdown({ Name = "อาวุธ", Options = {
    { Name = "Sword", Image = 123456 }, { Name = "Bow", Image = "lucide:target" }, "Plain text" } })
```

`Image` รับ: asset id / `"rbxassetid://..."` / https url / `"lucide:ชื่อ"` / `Color3` · ใช้ `Images = { Sword = 123456 }` แทนได้ · `ImageSize` ปรับขนาดรูป
เมธอด: `:Open` `:Close` `:Set` `:Get` `:Refresh(options, keep, images)` `:SetImage(opt, image)`

#### Segmented — ปุ่มเลือกแบบแถบ

```lua
sec:CreateSegmented({ Name = "แผนที่ Farm", Options = { "A", "B", "C" }, Default = "A", Flag = "auto_map" })
```

เมธอด: `:Set` `:Get` `:SetOptions(list, keep)`

#### ListBox — รายการเลื่อน เลือกได้ (v3.14)

```lua
local lb = sec:CreateListBox({ Name = "เซิร์ฟเวอร์", Items = { "US-1", "EU-1", "ASIA-1" },
    Height = 140, Search = true, Flag = "server", Callback = function(v) print(v) end })
lb:Add("ASIA-2")
```

ตัวเลือก: `Items`, `Height`, `Multi`, `Search` (ช่องค้นหา), `AllowDeselect`, `Default`, `Empty` (ข้อความตอนว่าง), `Flag`, `Callback(value)`
เมธอด: `:Get` `:Set(value, silent)` `:Clear` `:Refresh(items, keep)` `:Add` `:Remove` `:GetItems` `:Count` · ถ้ามี `Flag` ค่าถูกบันทึกใน Config

#### ColorPicker — เลือกสี

```lua
sec:CreateColorPicker({ Name = "สี ESP", Default = Color3.fromRGB(124, 58, 237),
    Flag = "esp_color", Callback = function(color) print(color) end })
```

เมธอด: `:Open` `:Close` `:Set` `:Get`

### 6.2 คีย์บอร์ด

#### Keybind — ผูกปุ่ม

```lua
sec:CreateKeybind({ Name = "Aimbot (กดค้าง)", Default = Enum.KeyCode.E, Mode = "Hold",
    Flag = "aim_key", Callback = function(down) print("aim", down) end })

sec:CreateKeybind({ Name = "Speed (สลับ)", Default = Enum.KeyCode.G, Mode = "Toggle",
    Flag = "speed_key", Callback = function(on) print("speed", on) end })
```

`Mode`: `"Press"` กดแล้วทำครั้งเดียว · `"Hold"` ทำงานตอนกดค้าง · `"Toggle"` กดครั้งหนึ่งเปิด อีกครั้งปิด
ตอนผู้ใช้ตั้งปุ่ม: กดปุ่มที่ต้องการ, `Esc` = ยกเลิก, `Backspace`/`Delete` = ลบปุ่ม
เมธอด: `:Set` `:Get` `:GetState()` · `Changed(key)` เรียกเมื่อเปลี่ยนปุ่ม

#### KeybindToggle — คีย์ + สวิตช์ในตัวเดียว

```lua
sec:CreateKeybindToggle({ Name = "ESP", Key = Enum.KeyCode.X, Default = false, Flag = "esp_on",
    Tooltip = "กด X หรือแตะสวิตช์ เพื่อเปิด/ปิด ESP", Callback = function(on) print("esp", on) end })
```

เมธอด: `:Set` `:Get` `:SetKey` `:GetKey`

### 6.3 พิมพ์ข้อความ

#### Textbox

```lua
sec:CreateTextbox({ Name = "ชื่อ", Default = "", Placeholder = "พิมพ์ที่นี่", Flag = "name",
    Callback = function(text) print(text) end })
```

ตัวเลือก: `ClearOnFocus`, `Numeric`, `Min`, `Max`, `MaxLength`, `Live` (ส่งค่าทุกตัวอักษร), `EnterOnly` (ส่งเมื่อกด Enter เท่านั้น)

#### InputButton — ช่องพิมพ์ + ปุ่มส่ง (v3.14)

```lua
local ib = sec:CreateInputButton({ Name = "ใส่คีย์", Placeholder = "XXXX-XXXX", Button = "ยืนยัน",
    ClearOnSubmit = true, Trim = true, Callback = function(text) print("ส่ง:", text) end })
```

กด Enter ก็ส่งได้ · ตัวเลือก: `ButtonWidth`, `Default`, `MaxLength`, `Flag`
เมธอด: `:Get()` (ค่าที่ส่งล่าสุด) `:GetText()` (ที่พิมพ์อยู่ตอนนี้) `:Set(text, silent)` `:Clear()` `:Focus()` `:SetButtonText(t)`

#### TagInput — พิมพ์แล้วกด Enter เพื่อเพิ่มแท็ก

```lua
sec:CreateTagInput({ Name = "ไวต์ลิสต์", Placeholder = "ชื่อผู้เล่น แล้วกด Enter",
    Default = { "Player1" }, Lower = true, Flag = "whitelist",
    Callback = function(list) print(table.concat(list, ", ")) end })
```

`Lower = true` เก็บเป็นตัวพิมพ์เล็ก · `Max` จำกัดจำนวน · เมธอด: `:Add` `:Remove` `:Has` `:Set` `:Get`

### 6.4 ปุ่ม

#### Button

```lua
sec:CreateButton({ Name = "หยุดจัดเซ็ต", Callback = function() print("stop") end })

-- ปุ่มสีไล่เฉด + ตัวหนา
sec:CreateButton({ Name = "เริ่ม", Bold = true,
    Gradient = { Window.Theme.Accent, Window.Theme.Accent2 },
    Callback = function() Window:Notify({ Title = "สถานะ", Content = "เริ่มแล้ว", Duration = 3 }) end })
```

ตัวเลือก: `Color`, `Gradient`, `TextColor`, `Bold`, `Icon` · ไม่ใส่ `TextColor` = ไลบรารีเลือกสีตัวอักษรที่อ่านง่ายให้เอง (ตามธีมสด) · เมธอด: `:SetText(t)`

#### ButtonRow — หลายปุ่มในแถวเดียว (v3.14)

```lua
sec:CreateButtonRow({ Buttons = {
    { Name = "เริ่ม", Bold = true, Callback = function() print("start") end },
    { Name = "หยุด", Color = Color3.fromRGB(220, 60, 60), Callback = function() print("stop") end },
} })
```

ปุ่มแต่ละอันรับ `Name, Callback, Color, TextColor, Bold` · เมธอด: `:SetText(i, text)`

#### HoldButton — กดค้างเพื่อยืนยัน

```lua
sec:CreateHoldButton({ Name = "ล้างข้อมูลทั้งหมด", Duration = 1.5, Color = Color3.fromRGB(220, 60, 60),
    Callback = function() print("cleared") end })
```

### 6.5 แสดงข้อมูล

| Control | ตัวอย่าง | หมายเหตุ |
|---|---|---|
| `CreateLabel` | `sec:CreateLabel({ Text = "พร้อมใช้งาน", Color = Color3.fromRGB(52,211,153), Bold = true })` | `:Set(t)` `:SetColor(c)` · มี `TextSize` |
| `CreateParagraph` | `sec:CreateParagraph({ Title = "หมายเหตุ", Content = "ข้อความยาวๆ" })` | `:Set(title, content)` |
| `CreateBadge` | `sec:CreateBadge({ Name = "สถานะ" })` | ป้ายสถานะ `:Set(v)` `:SetColor(c)` |
| `CreateProgress` | `sec:CreateProgress({ Name = "จัดเซ็ต", Min = 0, Max = 100, Default = 0, Suffix = "%" })` | `:Set(v)` `:Get()` `:SetColor(c)` |
| `CreateDivider()` / `CreateSeparator(cfg)` | `sec:CreateDivider()` | เส้นคั่น |

#### Stat — แถวแสดงค่าสด

```lua
local coins = sec:CreateStat({ Name = "Coins", Get = function() return getCoins() end, Delta = true })
sec:CreateStat({ Name = "เวลา", Get = function() return os.date("%H:%M:%S") end, Interval = 1 })
coins:Refresh()   -- อัปเดตทันที
```

| ตัวเลือก | ความหมาย |
|---|---|
| `Get` | ฟังก์ชันคืนค่าที่จะแสดง (ตัวเลขใส่จุลภาคให้เอง) |
| `Interval` | ความถี่อ่านค่า วินาที (ค่าเริ่มต้น `0.5`, อ่านเฉพาะตอนเมนูเปิด) |
| `Format` | `function(v) return "ข้อความ" end` กำหนดรูปแบบเอง |
| `Prefix` / `Suffix` / `Color` | ข้อความหน้า/หลัง และสีค่า |
| `Delta` | `true` = แสดง ▲ / ▼ พร้อมจำนวนที่เปลี่ยน |

Stat ไม่ถูกบันทึกใน Config · เมธอด: `:Refresh()` `:SetGet(fn)` `:Get()`

#### KeyValue — แถว "ชื่อ ... ค่า" แตะเพื่อคัดลอก (v3.14)

```lua
local kv = sec:CreateKeyValue({ Name = "HWID", Value = "ABC-123", Copyable = true })
kv:Set("XYZ-789")
```

เมธอด: `:Set(v)` `:Get()` `:SetColor(c)`

#### Countdown — นับถอยหลังสด เช่น วันหมดอายุคีย์ (v3.14)

```lua
sec:CreateCountdown({ Name = "คีย์หมดอายุใน", Target = os.time() + 3600,   -- หรือ Seconds = 3600
    WarnAt = 300, ExpiredText = "หมดอายุแล้ว", OnDone = function(obj) print("หมด") end })
```

ตัวเลือก: `Target` (epoch) หรือ `Seconds`, `Format = function(sec)`, `ExpiredText`, `WarnAt` (เหลือกี่วินาทีแล้วเปลี่ยนสีเตือน), `Color`, `OnDone(obj)`
เมธอด: `:SetTarget(epoch)` `:SetSeconds(n)` `:Add(n)` `:Get()` `:IsExpired()`

#### Table — ตาราง (v3.14)

```lua
local t = sec:CreateTable({ Name = "ผู้เล่น", Columns = { "ชื่อ", { Name = "คะแนน", Width = 0.3 } },
    Rows = { { "A", 10 }, { "B", 20 } }, Height = 160, Zebra = true,
    OnRowClick = function(row, i) print(i, row[1]) end })
t:AddRow({ "C", 30 })
```

ตัวเลือก: `Columns`, `Rows`, `Height`, `RowHeight`, `Zebra`, `OnRowClick(row, i)`
เมธอด: `:SetRows` `:AddRow` `:RemoveRow(i)` `:SetCell(i, col, v)` `:Clear` `:Count` `:GetRows`

#### ItemGrid — ตารางการ์ดไอเทม (v3.14)

```lua
local grid = sec:CreateItemGrid({ Name = "กระเป๋า", CellWidth = 92, CellHeight = 112, Prefix = "×",
    Empty = "ไม่มีไอเทม",
    Items = { { Name = "Sword", Amount = 3, Image = "lucide:sword" }, { Name = "Potion", Amount = 12 } },
    Callback = function(item) print("เลือก", item.Name) end })
grid:SetAmount("Potion", 10)
```

แตะการ์ด = เรียก `Callback(item)` · `item = { Name, Amount, Image, Id }` · ไม่มีรูป = ไอคอนกล่อง · การ์ดขยายเต็มแถวตามความกว้างหน้าต่าง
เมธอด: `:SetItems(list)` `:SetAmount(name, n)` `:Clear()` `:GetItem(name)` `:SetEmpty(text)` `:Count()`

#### Image — รูป (v3.14)

```lua
sec:CreateImage({ Image = 123456, Name = "โลโก้", Height = 120, Fit = "Fit", Corner = 8 })
```

`Image` = asset id / `"rbxassetid://..."` / `"lucide:ชื่อ"` · `Fit` = `"Fit"` / `"Crop"` / `"Stretch"` · `Color` ย้อมสี · เมธอด: `:Set(image)` `:Get()`

#### Graph — กราฟเส้นสด

```lua
local g = sec:CreateGraph({ Name = "FPS", Points = 60, Height = 80, Min = 0, Max = 120, Suffix = " fps" })
g:Push(60)
```

เมธอด: `:Push(n)` `:Clear()` `:SetRange(lo, hi)` `:Get()`

#### Console / CodeBlock

```lua
local con = sec:CreateConsole({ Name = "Log", Height = 160, MaxLines = 200 })
con:Info("เริ่มทำงาน") con:Warn("ระวัง") con:Error("พัง") con:Print("ข้อความ", Color3.new(1,1,1))

local code = sec:CreateCodeBlock({ Name = "สคริปต์", Text = "print('hi')", Height = 120, Copy = true })
code:Append("print('more')")
```

- Console เมธอด: `:Print(text, color)` `:Info` `:Warn` `:Error` `:Clear()` `:GetText()` `:Copy()`
- CodeBlock (v3.14) ตัวเลือก: `Text`, `Height`, `Copy` (ปุ่มคัดลอก), `MaxChars`, `AutoScroll` · เมธอด: `:Set` `:Get` `:Append(line)` `:Clear` `:Copy`

---

## 7. สิ่งที่ทุก control มี

| เมธอด | ทำอะไร |
|---|---|
| `:Set(v)` / `:Get()` | ตั้ง/อ่านค่า (ตัวที่มีค่า) |
| `:SetVisible(bool)` / `:IsVisible()` | ซ่อน/แสดง |
| `:ShowIf("flag" [, ค่า \| fn(v, flags)])` หรือ `:ShowIf({"a","b"}, fn(flags))` | แสดงเมื่อเงื่อนไขตรง |
| `:SetEnabled(bool)` / `:Lock()` / `:Unlock()` | ทำให้จาง + กันการกด |
| `:OnChange(fn(value, prev))` | ดักการเปลี่ยนค่า (ต้องมี `Flag`) |
| `:Reset()` / `:IsModified()` | กลับค่าเริ่มต้น / เช็กว่าถูกแก้ |
| `:SetTooltip(text)` | ตั้งทิป (หรือใส่ `Tooltip = "..."` ตอนสร้าง) |
| `:Destroy()` | ลบ control |

ตัวเลือกตอนสร้าง: `NoMenu = true` ปิดเมนูคลิกขวา · `ContextMenu = { { Name, Callback(obj) } }` เพิ่มรายการเอง
ทุก control มี `.Frame` จึงใช้ `Window:Tooltip(obj.Frame, "ข้อความ")` ได้

---

## 8. แจ้งเตือน / Dialog / Loading

ทุกตัวคืน handle และใช้ได้ทั้ง `Window:` และ `Library:` (ไม่ต้องมีหน้าต่างก็ได้ ยกเว้น `AskAmount`)

| API | ทำอะไร |
|---|---|
| `Window:Notify({ ... })` | การ์ดแจ้งเตือนเต็มรูปแบบ |
| `Window:Success / Warning / Error / Info(title, content, dur)` | ทางลัดของ Notify ตามชนิด |
| `Window:Toast("ข้อความ", "Success" \| 3 \| {Kind, Duration, Icon})` | แถบเล็กกลางล่าง |
| `Library:Banner({ Title, Content, Duration, Color })` | แถบด้านบน ใช้ได้ตอนเมนูปิด |
| `Window:Loading(cfg)` | แถบโหลด/ความคืบหน้า |
| `Window:Dialog(cfg)` | กล่องโต้ตอบปรับแต่งได้เต็มที่ |
| `Window:Confirm({ Title, Content, Yes, No, OnYes, OnNo, Danger })` | ถามยืนยัน ใช่/ไม่ |
| `Window:Alert(title, content)` | แจ้งให้ทราบ ปุ่มเดียว |
| `Window:Prompt({ Title, Placeholder, OnSubmit(text) })` | กล่องให้พิมพ์ข้อความ |
| `Window:AskAmount({ ... })` | กล่องถามจำนวน (v3.14) |
| `Window:DismissAll()` / `Library:DismissAll()` | ปิดการแจ้งเตือนทั้งหมด |
| `Window:SetNotifyTheme("Cyber" \| tbl \| nil)` | ธีมสีเฉพาะของการแจ้งเตือน/Dialog |
| `Library:Copy(text, title)` | คัดลอกลงคลิปบอร์ด + การ์ด "Copied" (v3.14) |

### Notify

ตัวเลือก: `Title`, `Content`, `Kind` (`Success`/`Warning`/`Error`/`Info`), `Duration`, `Icon`, `Color`, `Flash`, `Progress` (`true` = แถบนับถอยหลัง, `0..1` = แน่นอน), `Key` (Key เดียวกัน = อัปเดตการ์ดเดิม), `Position`, `OnClick`, `OnClose(reason)`, `Closable`, `Merge`, `Sound`

- `Duration = 0 / false / math.huge` = ค้างจนกว่าจะปิด
- handle: `:Update{...}` `:SetProgress(n)` `:Dismiss()` `:IsAlive()` `:OnClose(fn)`

### Dialog

ตัวเลือก: `Title`, `Content`, `Kind`, `Icon`, `Width`, `Buttons = { { Text, Value, Style = "Primary"\|"Secondary"\|"Danger", Callback, Close } }`, `Input = true \| { Placeholder, Default, MaxLength, Numeric }`, `Build = function(container, theme, handle) end`, `Dismissable`, `OnClose`

- handle: `:Close(value)` `:Update{}` `:IsOpen()` `:GetInput()` `:Wait()` → `value, input`

### AskAmount

```lua
task.spawn(function()      -- ต้องเรียกใน task.spawn / callback เพราะรอผู้ใช้ตอบ
    local n = Window:AskAmount({ Title = "ขายกี่ชิ้น?", Max = 50, Default = 1 })
    if n then print("ขาย", n) else print("ยกเลิก") end
end)
```

ตัวเลือก: `Title`, `Content` (ไม่ใส่ + มี `Max` = "มีทั้งหมด: N"), `Max`, `Default` (ค่าเริ่มต้น `1`), `Confirm`, `MaxText`, `Cancel`, `Icon` · คืนจำนวน หรือ `nil` ถ้ายกเลิก · มีปุ่ม "ทั้งหมด (Max)" ให้เองเมื่อใส่ `Max`

### Loading

```lua
local l = Window:Loading({ Title = "กำลังโหลด", Text = "เริ่มต้น...", Progress = 0 })
-- แบบสั้น: Window:Loading("กำลังโหลด...")   ·   ไม่มี Window: Library:Loading({ ... })

l:Set(0.5, "ครึ่งทางแล้ว")      -- 0..1 + ข้อความ (Set(false) = วนไม่รู้ความคืบหน้า)
l:SetText("กำลังดาวน์โหลด...")
l:Complete("เสร็จแล้ว", 2.5)     -- สำเร็จ แล้วปิดเองใน 2.5 วิ
l:Fail("ล้มเหลว", 4)             -- ล้มเหลว แล้วปิดเองใน 4 วิ
l:Close()
```

| ตัวเลือก | ความหมาย |
|---|---|
| `Title` | หัวข้อ (ค่าเริ่มต้น `"Loading"`) |
| `Text` / `Content` | ข้อความรอง |
| `Progress` | `0..1` = แถบแน่นอน, ไม่ใส่ = แถบวนไม่รู้ความคืบหน้า |
| `Closable` | `true` = มีปุ่มปิด (ค่าเริ่มต้น `false`) |

Loading **ไม่ปิดเอง** จนกว่าจะเรียก `Complete` / `Fail` / `Close`

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

ค่ากลาง `Library.NotifyConfig`: `Position`, `MaxVisible`, `Duration`, `Gap`, `Margin`, `Width`, `Merge`, `PauseOnHover`, `Animate`
เสียง: `Library.Sound.Enabled = false` ปิดทั้งหมด · `Library.Sound.Volume = 0.6` · เปลี่ยนเสียงด้วย `Library.Sound.Toggle` / `.Notify`

---

## 9. Flag, Config, Undo

### Flag

```lua
if Library.Flags["aim_on"] then ... end                  -- อ่านค่า

Library:SetFlag("aim_on", true)                          -- ตั้งค่า (ตัวที่สาม true = ไม่เรียก Callback)
Library:ToggleFlag("aim_on")                             -- สลับ (เฉพาะ true/false) → ok, ค่าใหม่
Library:SetFlags({ aim_on = true, aim_fov = 90 })        -- หลายค่า = Undo ขั้นเดียว
local all = Library:GetFlags()                           -- สำเนาค่าทุก Flag
local ctl = Library:GetControl("aim_fov")                -- ตัว control เอง

Library:OnFlag(function(flag, value, prev) print(flag, value, prev) end)   -- ดักทุก Flag
Library:Watch("aim_fov", function(value, prev) end)                        -- ดัก Flag เดียว
```

### Config

ผู้ใช้บันทึก/โหลดได้ในแท็บ SETTINGS ไฟล์เก็บที่ `SpectreUI/configs/` Config เก็บเฉพาะ control ที่มี `Flag`

```lua
Library:SaveConfig("name")        Library:LoadConfig("name", silent)
Library:DeleteConfig("name")      Library:ListConfigs()
local json = Library:ExportConfig()          Library:ImportConfig(json, silent)
Library:SaveAuto("auto")                      -- บันทึกเป็นไฟล์ auto
Library:AutoloadConfig("auto", true)          -- โหลดตอนเริ่ม (ถ้ามีไฟล์)
```

**โหลดอัตโนมัติตอนเริ่ม:** ผู้ใช้กด "บันทึกเป็น auto" ในแท็บ SETTINGS แล้วในสคริปต์ใส่:

```lua
Window:OnLoaded(function() Library:AutoloadConfig("auto", true) end)
```

> ต้องเรียก **หลังสร้างทุก control เสร็จ** ถ้าสร้าง control ตรงๆ (ไม่ใช้ `Build`) จะเรียกท้ายสคริปต์ก็ได้

### Undo / Snapshot

| API | ทำอะไร |
|---|---|
| `Library:Undo(silent)` / `Redo(silent)` | ย้อน/ทำซ้ำ (`Ctrl+Z` / `Ctrl+Y`) |
| `Library:CanUndo()` / `CanRedo()` | เช็กว่าย้อนได้ไหม |
| `Library:GetHistory()` / `ClearHistory()` | ประวัติการแก้ค่า (`Library.History.Max` = จำนวนสูงสุด) |
| `Library:Transaction("ชื่อ", fn)` | หลายการเปลี่ยนค่า = Undo ขั้นเดียว |
| `Library:Snapshot("a")` / `Restore("a")` / `Diff("a","b")` | โปรไฟล์ในหน่วยความจำ ไม่ใช้ไฟล์ |
| `Library:GetModified()` | รายการ control ที่ค่าต่างจากค่าเริ่มต้น |
| `Library:ResetAll()` | รีเซ็ตทุก control (มี `Tab:ResetAll()` / `Section:ResetAll()` ด้วย) |

---

## 10. ธีมและฟอนต์

ธีมที่มีให้: Rose (ค่าเริ่มต้น), Violet, Cyber, Crimson, Matrix, Aurora, Dracula, Nord, TokyoNight, Mocha, Synthwave, Jade, Gold, Lavender, Candy, Peach, Midnight, Ocean, Sunset, Mono

ธีมที่ผู้ใช้เลือกถูกจำใน `SpectreUI/configs/themes.json` และโหลดกลับเอง **ถ้าใส่ `Theme = "..."` ใน `CreateWindow` จะบังคับธีมนั้นทุกครั้ง** (ลบออกถ้าอยากให้จำของผู้ใช้)

| API | ทำอะไร |
|---|---|
| `Window:SetTheme(name \| tbl, remember)` | เปลี่ยนสีทั้งหน้าต่างสด ๆ |
| `Library:SetTheme(name \| tbl)` | ธีมเริ่มต้นของหน้าต่างที่สร้างหลังจากนี้ |
| `Window:GetThemeName()` / `Library.ThemeName` | ชื่อธีมปัจจุบัน |
| `Window:CycleTheme(dir, remember)` | ถัดไป (`1`) / ก่อนหน้า (`-1`) |
| `Window:RandomTheme(remember)` | สุ่มธีม |
| `Window:RenameTheme("ใหม่")` / `Library:RenameTheme(old, new)` | เปลี่ยนชื่อ → `ok, err` |
| `Window:DeleteTheme(name?)` / `Library:DeleteTheme(name)` | ลบ (เฉพาะธีมที่สร้างเอง) |
| `Library:CloneTheme(src, newName, overrides)` | ทำสำเนา |
| `Library:RegisterTheme(name, tbl)` | ลงทะเบียนธีมใหม่ |
| `Library:GetTheme(name?)` / `ListThemes()` | อ่านธีม / รายชื่อ |
| `Library:OnThemeChange(fn(event, a, b))` | ดักเมื่อธีมเปลี่ยน |
| `Library:SaveThemes()` / `LoadThemes()` | บันทึก/โหลด `themes.json` |
| `Library:SetStatusColors({ Success = c, ... })` / `GetStatusColor(kind)` | สี Success/Warning/Error/Info |
| `Section:CreateThemeManager({ Name, Flag, Remember, Random, Delete })` | UI จัดการธีมสำเร็จรูป |

`Window.Theme.Accent` / `Window.Theme.Accent2` = สีหลัก/สีรองปัจจุบัน (ใช้ทำ Gradient ให้ปุ่ม)

**สีตัวอักษรบนสีธีม:** `Library.OnAccent(Window.Theme)` (หรือ `OnAccent(colorA, colorB)`) คืนสีขาว/เกือบดำที่อ่านง่ายบนสีนั้น ไลบรารีใช้ให้เองกับ ✓ ใน Multi-dropdown, ปุ่ม Done, ป้ายบนแท็บ, ปุ่ม + ของ TagInput, Segmented, ปุ่ม Primary ของ Dialog, โลโก้ และปุ่มที่ตั้ง `Color`/`Gradient` โดยไม่ใส่ `TextColor` (เลือกใหม่ทุกครั้งที่เปลี่ยนธีม)

### แชร์ธีมเป็นข้อความ

```lua
local code = Window:ExportTheme()                         -- "SPT1:{...}"
setclipboard(code)
local ok, name = Window:ImportTheme(code, "ธีมเพื่อน")     -- นำเข้า + ใช้ทันที (ตัวที่สาม false = ไม่ใช้ทันที)
Library:ExportTheme("Cyber")                              -- ส่งออกธีมตามชื่อ
Library:ImportTheme(code)                                 -- นำเข้าเฉยๆ → ok, ชื่อที่ได้
```

ชื่อซ้ำจะต่อเลขท้ายให้ · ธีมที่นำเข้าบันทึกลง `themes.json` และลบได้เหมือนธีมที่สร้างเอง

### ฟอนต์ + ขนาดตัวอักษร

```lua
Library:CreateWindow({ Title = "SpectreWare", Font = "Nunito" })   -- ตั้งตอนสร้าง
Window:SetFont("Ubuntu", true)       -- เปลี่ยนสด (true = จำไว้ครั้งหน้า)
Window:CycleFont(1)                  -- ถัดไป (-1 = ก่อนหน้า)
Library:RegisterFont("ของฉัน", Enum.Font.Code, Enum.Font.Code)   -- (ปกติ, ตัวหนา)
sec:CreateFontPicker({ Name = "ฟอนต์" })
Window:SetTextScale(1.15, true)      -- 0.7 .. 1.4 เรียกหลังสร้าง UI เสร็จ
```

| API | ทำอะไร |
|---|---|
| `Window:SetFont(font, remember)` | `font` = ชื่อ / `Enum.Font` / `{ Font, Bold }` → `ok, name \| err` |
| `Window:GetFontName()` / `CycleFont(dir, remember)` | ชื่อปัจจุบัน / ถัดไป-ก่อนหน้า |
| `Library:SetFont(font)` | ฟอนต์เริ่มต้นของหน้าต่างที่สร้างหลังจากนี้ |
| `Library:RegisterFont(name, regular, bold)` / `ListFonts()` | เพิ่ม / ดูรายชื่อ (`Library.Fonts` = preset) |
| `Section:CreateFontPicker({ Name, Flag, Remember })` | dropdown เลือกฟอนต์ |
| `Window:SetTextScale(s, remember)` / `GetTextScale()` | ขนาดตัวอักษรทั้งหน้าต่าง |

ฟอนต์/ขนาดตัวอักษรเก็บใน `themes.json` และไม่ถูกรีเซ็ตเมื่อเปลี่ยนธีม · แท็บ SETTINGS มีตัวเลือก Font และ Text size (85/100/115%) ให้ในตัว (ปิดด้วย `CreateSettingsTab({ Fonts = false })`)

> ฟอนต์ของ Roblox ครอบคลุมเฉพาะตัวอักษรละติน ข้อความภาษาไทยจะใช้ฟอนต์สำรองของระบบเสมอ

---

## 11. แท็บสำเร็จรูป SETTINGS

แท็บเดียวที่มีทุกอย่าง: ธีม สีธีมของเราเอง ฟอนต์ เอฟเฟกต์ ปุ่มลัด HUD การแจ้งเตือน Config และ Undo เรียกท้ายสุดหลังสร้างแท็บของเกมครบ เพื่อให้อยู่ล่างแถบด้านข้าง

```lua
Window:CreateSettingsTab()
-- หรือ
Window:CreateDefaultTabs({
    Settings = { Text = TEXT_TH, Sections = { History = false } },    -- false = ไม่สร้าง
})
```

> **เปลี่ยนจากเดิม:** แท็บ THEME ถูกรวมเข้ามาใน SETTINGS แล้ว ไม่ต้องเรียก `CreateThemeTab()` แยก และ `CreateDefaultTabs()` จะไม่สร้างแท็บ THEME ให้อีก ถ้ายังอยากได้แท็บแยก ส่ง `Theme = true` (หรือ `Theme = { ... }`) ให้ `CreateDefaultTabs` หรือเรียก `Window:CreateThemeTab(cfg)` เอง (ตัวเลือกเดียวกับตารางด้านล่าง ชื่อและไอคอนเริ่มต้น `"THEME"` / `"lucide:palette"`)

### SETTINGS — `Window:CreateSettingsTab(cfg)` → `tab, parts`

| ส่วน | คอลัมน์ | มีอะไร |
|---|---|---|
| **ธีมสี** | 1 | เปลี่ยนธีมสด, เปลี่ยนชื่อ, ทำสำเนา, สุ่ม, ลบ (เฉพาะธีมที่สร้างเอง), ทิป |
| **Font** | 1 | เลือกฟอนต์ + Text size (85 / 100 / 115%) |
| **สร้างธีมของตัวเอง** | 1 | เลือกสีหลัก/สีรอง + ตั้งชื่อ + ปุ่มสร้างและใช้ทันที |
| **พื้นหลัง / เอฟเฟกต์** | 1 | เอฟเฟกต์ (petals/orbs/embers/rain/grid/ปิด/ตามธีม), คุณภาพ auto/low/high, คีย์ F6 = ธีมถัดไป, F5 = ก่อนหน้า |
| **UI / ปุ่มลัด** | 2 | ปุ่มเปิด/ปิดเมนู (เปลี่ยนแล้วใช้ได้ทันที และตามเมื่อโหลด Config), ปุ่มเปิดค้นหา, คำอธิบายการใช้ |
| **Interface** | 2 | สวิตช์ FPS / Ping (Watermark), สวิตช์รายการ Keybind, ตำแหน่งแจ้งเตือน, เวลาแจ้งเตือน (1–10 วิ), ปุ่มทดสอบแจ้งเตือน |
| **Config** | 2 | ชื่อ, รายการ, บันทึก, โหลด, ลบ (ถามยืนยัน), บันทึกเป็น `auto`, คัดลอกไปคลิปบอร์ด, วางนำเข้า |
| **Undo / Snapshot** | 2 | Undo, Redo, ดูค่าที่ถูกแก้, Snapshot A / กลับไป A, กดค้างเพื่อรีเซ็ตทั้งหมด |
| **หน้าต่าง** | 1 (ท้ายสุด) | จัดกลางจอ + กระพริบ, ปิด UI ทั้งหมด (Unload, ถามยืนยัน) |

ซ้าย = หน้าตา, ขวา = ระบบ ส่วนที่อันตรายอย่าง Unload อยู่ท้ายสุด · บนจอแคบ/มือถือที่เป็นคอลัมน์เดียว ส่วนต่างๆ เรียงตามลำดับในตารางนี้จากบนลงล่าง

| ตัวเลือก | ค่าเริ่มต้น | ความหมาย |
|---|---|---|
| `Name`, `Icon` | `"SETTINGS"`, `"lucide:settings"` | ชื่อ / ไอคอนแท็บ |
| `FlagPrefix` | `"ui_"` | คำนำหน้า Flag: `ui_menu_key`, `ui_bg_fx`, `ui_quality`, `ui_theme_next`, `ui_theme_prev`, `ui_watermark`, `ui_keybind_list`, `ui_notify_pos`, `ui_notify_dur` |
| `Sections` | ทุกส่วนเปิด | `{ Theme = false, Hotkeys = false, Interface = false, Config = false, Window = false, History = false }` ซ่อนทีละส่วน · `Theme = false` ซ่อนทั้งกลุ่มธีม (ธีมสี / Font / สร้างธีม / เอฟเฟกต์) |
| `Manager` | `{}` | ส่งต่อให้ `CreateThemeManager` เช่น `{ Random = false, Delete = false, Remember = true }` |
| `Maker` | `true` | `false` = ซ่อนส่วนสร้างธีม |
| `MakerColors` | ฟ้า/คราม | `{ Accent = Color3, Accent2 = Color3 }` สีเริ่มต้นของตัวเลือกสี |
| `Effects` | `true` | `false` = ซ่อนส่วนพื้นหลัง/คุณภาพ/คีย์ |
| `Fonts` | `true` | `false` = ซ่อน Font / Text size |
| `Keys` | F6 / F5 | `false` = ไม่สร้างคีย์ลัดเปลี่ยนธีม หรือ `{ Next = Enum.KeyCode.X, Prev = Enum.KeyCode.Z }` |
| `Tip` | ข้อความเริ่มต้น | `false` = ซ่อน หรือใส่ข้อความเอง |
| `Columns` | `{ Maker = 1, Fx = 1 }` | คอลัมน์ (`1` / `2`) ของส่วนสร้างธีม และส่วนเอฟเฟกต์ |
| `DefaultConfig` | `"default"` | ชื่อเริ่มต้นในช่องชื่อ Config |
| `AutoName` | `"auto"` | ชื่อไฟล์ของปุ่ม "บันทึกเป็น auto" |
| `WatermarkText` | `"SpectreWare"` | ข้อความหน้าสุดของ Watermark ที่สวิตช์ FPS / Ping เปิด |
| `Text` / `Icons` | `{}` | แปลข้อความ / เปลี่ยนไอคอน (หัวข้อ 16) |

`parts`: `Tab`, `Manager` (= `ThemePicker`), `ManagerSection` (= `ThemeSection`), `Font`, `FontSection`, `TextSize`, `Maker` (`Accent`, `Accent2`, `Name`, `Section`), `Background`, `Quality`, `NextKey`, `PrevKey`, `EffectsSection`, `MenuKey`, `UISection`, `WatermarkToggle`, `KeybindListToggle`, `NotifyPosition`, `NotifyDuration`, `InterfaceSection`, `ConfigName`, `ConfigList`, `ConfigSection`, `HistorySection`, `WindowSection`

> สวิตช์ FPS / Ping และรายการ Keybind สร้าง HUD ตอนเปิดครั้งแรก ถ้าอยากตั้งค่า Watermark เองละเอียดกว่านี้ (เลือก Fields, ตำแหน่ง) ใช้ `Window:Watermark({ ... })` ตามหัวข้อ 13 แทน แล้วซ่อนส่วนนี้ด้วย `Sections = { Interface = false }`

### เพิ่มของเราเองลงในแท็บสำเร็จรูป

```lua
local tab, parts = Window:CreateSettingsTab()
local mine = tab:CreateSection({ Name = "ของฉัน", Column = 1 })
mine:CreateToggle({ Name = "โหมดพิเศษ", Flag = "my_mode" })
```

### แปลข้อความ (`Text`)

ใส่เฉพาะคีย์ที่อยากเปลี่ยน คีย์ที่ไม่ใส่ใช้ภาษาอังกฤษเริ่มต้น ใช้ได้ทั้ง `CreateSettingsTab`, `CreateDefaultTabs` (และ `CreateThemeTab` ถ้าเรียกแยก)

**ธีม / Font / เอฟเฟกต์:** `ThemeSection` `Theme` `RenameLabel` `RenameButton` `DuplicateButton` `RandomButton` `DeleteButton` `TipTitle` `Tip` `FontSection` `Font` `TextSize` `MakerSection` `Accent` `Accent2` `NewName` `NewNameDefault` `NewNamePlaceholder` `CreateButton` `ThemeNotifyTitle` `Created` `FxSection` `FxName` `FxAuto` `FxOff` `Quality` `QualityTip` `NextTheme` `PrevTheme`

**ส่วนอื่นของ SETTINGS:** `UISection` `MenuKey` `Palette` `HowTitle` `HowText` `InterfaceSection` `Watermark` `KeybindList` `NotifyPosition` `NotifyDuration` `TestNotify` `TestTitle` `TestText` `ConfigTitle` `ConfigName` `ConfigList` `Save` `Saved` `Load` `Loaded` `Delete` `Cancel` `PickFirst` `DeleteTitle` `CannotUndo` `Deleted` `SaveAuto` `SavedAuto` `Copy` `Copied` `NoClipboard` `Import` `ImportTitle` `Applied` `WindowSection` `Center` `Unload` `UnloadTitle` `UnloadText` `Yes` `HistorySection` `Undo` `Redo` `NothingUndo` `NothingRedo` `Modified` `ChangedCount` `AllDefault` `Snapshot` `SnapSaved` `Restore` `Restored` `ResetAll` `ResetDone`

```lua
local TEXT_TH = {
    ThemeSection = "ธีมสี", RandomButton = "สุ่ม", DeleteButton = "ลบ", CreateButton = "สร้างและใช้ทันที",
    UISection = "UI / ปุ่มลัด", InterfaceSection = "หน้าจอ", Watermark = "แสดง FPS / Ping",
    NotifyPosition = "ตำแหน่งแจ้งเตือน", TestNotify = "ทดสอบแจ้งเตือน",
    Save = "บันทึก", Load = "โหลด", Delete = "ลบ",
    Cancel = "ยกเลิก", Yes = "ตกลง", Copy = "คัดลอก Config", Import = "วางนำเข้า",
}
Window:CreateSettingsTab({ Text = TEXT_TH })
```

---

## 12. Command Palette และปุ่มลัด

กด `Ctrl + K` ค้นหาและสั่งงานได้จากช่องเดียว เพิ่มคำสั่งเอง:

```lua
Library:AddCommand({
    Name     = "ไปหน้า Config",     -- ชื่อที่แสดง
    Desc     = "Settings",          -- คำอธิบายสั้นๆ
    Keywords = "config save load",  -- คำค้นหา (ใส่หลายภาษาได้)
    Callback = function() Window:SetTab("SETTINGS") end,
})
```

มีคำสั่งสำเร็จรูป เช่น Run UI check, Toggle watermark, Toggle keybind list · ตั้งปุ่มคู่กับ Ctrl ได้ด้วย `Library.PaletteKey` (ค่าเริ่มต้น `K`) · เปิด/ปิดจากโค้ด: `Window:OpenPalette(initial)` / `ClosePalette()`

### Hotkey ของตัวเอง (ไม่ผูกกับ control)

```lua
local hk = Library:Hotkey(Enum.KeyCode.F4, function() Window:Toggle() end,
    { Ctrl = true, Desc = "ซ่อน/แสดงเมนู" })
hk:SetKey(Enum.KeyCode.F3)    hk:SetEnabled(false)    hk:Disconnect()
print(Library:ListHotkeys()[1].Key)   -- "Ctrl+F4"
```

ตัวเลือก: `Ctrl` / `Shift` / `Alt` (ต้องกดตรงเป๊ะ), `Desc`, `AllowTyping = true` (ทำงานแม้กำลังพิมพ์ในช่องข้อความ) · ล้างเองตอน `Library:Unload()`

### ปุ่มลัดทั้งหมด

| ปุ่ม | ทำอะไร |
|---|---|
| `RightShift` (ตั้งที่ `ToggleKey` หรือแท็บ SETTINGS) | เปิด/ปิดเมนู |
| `Ctrl + K` | Command Palette |
| `F6` / `F5` | ธีมถัดไป / ก่อนหน้า (ตั้งใหม่/ปิดได้ที่ `Keys`) |
| `Ctrl + Z` / `Ctrl + Y` | Undo / Redo |
| คลิกขวา หรือกดค้างที่ control | รีเซ็ต / คัดลอก / ล็อก |
| ตอนตั้ง Keybind: `Esc` / `Backspace` | ยกเลิก / ลบปุ่ม |

---

## 13. HUD และ Tour

### Watermark — ลายน้ำ FPS / Ping

```lua
local wm = Window:Watermark({
    Text = "SpectreWare",
    Fields = { "FPS", "Ping", "Time", { Name = "Gold", Get = function() return 1234 end } },
    Position = "TopRight",
})
wm:SetText("MyHub v2")    wm:AddField("Kills", function() return kills end)    wm:Toggle()
```

| ตัวเลือก | ความหมาย |
|---|---|
| `Text` | ข้อความหน้าสุด (ค่าเริ่มต้น = ชื่อแบรนด์) |
| `Fields` | `"FPS"` `"Ping"` `"Time"` `"Date"` `"Players"` หรือ `function() return "ข้อความ" end` หรือ `{ Name, Get }` |
| `Position` | `TopLeft`/`TopCenter`/`TopRight`/`LeftCenter`/`RightCenter`/`BottomLeft`/`BottomCenter`/`BottomRight` หรือ `UDim2` (ค่าเริ่มต้น `TopRight`) |
| `Interval` | ความถี่อัปเดต วินาที (`0.5`) |
| `Draggable` | ลากย้ายได้ (`true`, ใช้ได้ทั้งเมาส์และนิ้ว) |
| `Visible` | `false` = สร้างแล้วซ่อนไว้ก่อน |

FPS/Ping เปลี่ยนสีเขียว-เหลือง-แดงตามค่า แสดงอยู่แม้ปิดเมนู · แตะเฉยๆ ไม่ขยับ (ต้องลากเกิน 5px) · ลากชิดขอบจอจริงได้
เมธอด: `:SetText` `:SetFields` `:AddField` `:SetVisible` `:Toggle` `:SetPosition` `:Refresh` `:Destroy`

### KeybindList — แผงรายการคีย์บายด์

```lua
local kb = Window:KeybindList({ Title = "Keybinds", Position = "LeftCenter" })
local id = kb:Add("Fly", Enum.KeyCode.F, function() return flying end)   -- เพิ่มบรรทัดเอง
kb:Remove(id)
```

ดึง `CreateKeybind` / `CreateKeybindToggle` ที่ผูกปุ่มแล้วมาแสดงเอง ตัวที่ทำงานอยู่ไฮไลต์สีหลัก

| ตัวเลือก | ความหมาย |
|---|---|
| `Title` | หัวข้อ (`"Keybinds"`) |
| `Position` | ตำแหน่ง (`LeftCenter`) |
| `OnlyActive` | `true` = แสดงเฉพาะตัวที่ทำงานอยู่ |
| `HideWhenEmpty` | ซ่อนเมื่อไม่มีรายการ (`true`) |
| `IncludeUI` | `true` = รวมปุ่มของระบบ (Flag ขึ้นต้น `ui_`) |
| `Max` | จำนวนแถวสูงสุด (`12`) |

### Tour — ทัวร์แนะนำการใช้งาน

```lua
Window:Tour({
    { Tab = "MAIN", Title = "ยินดีต้อนรับ", Content = "นี่คือหน้าหลัก" },
    { Target = "aim_on", Title = "เปิด Aimbot", Content = "สวิตช์นี้เปิด/ปิดระบบเล็ง" },
    "จบแล้ว ลองเล่นดูได้เลย",
}, { OnDone = function(finished) print("tour", finished) end })
```

แต่ละขั้นสลับแท็บ เลื่อนไปที่ control กระพริบไฮไลต์ พร้อมการ์ดบอกขั้น (`1/4`) · แตะการ์ด = ถัดไป, กด X = หยุด

| step | ความหมาย |
|---|---|
| `Target` | `Flag` / ชื่อ control / ตัว control |
| `Tab` | ชื่อแท็บที่จะสลับไป |
| `Title`, `Content` | หัวข้อ/คำอธิบาย (step เป็น string = หัวข้ออย่างเดียว) |
| `OnEnter(i, step)` | เรียกเมื่อเข้าขั้นนี้ |

| `opts` | ความหมาย |
|---|---|
| `Position` | ตำแหน่งการ์ด เช่น `"TopCenter"` |
| `Start` | เริ่มที่ขั้นไหน (`1`) |
| `Keys` | `true` = ใช้ลูกศรซ้าย/ขวา |
| `Toast` | `false` = ไม่แจ้งเตือนตอนจบ |
| `NextHint` / `DoneHint` / `DoneText` | ข้อความบนการ์ด |
| `OnDone(finished)` | `true` = ครบทุกขั้น, `false` = ผู้ใช้หยุดกลางทาง |

เมธอด: `:Next` `:Prev` `:Goto(i)` `:Stop` `:Finish` `:IsRunning` `:Step`
`Library:Watermark / KeybindList / Tour(...)` = ตัวเดียวกัน ใช้กับหน้าต่างล่าสุด

---

## 14. Load API (โหลดสคริปต์)

โหลดสคริปต์จาก URL / ไฟล์ / โค้ดดิบ / ฟังก์ชัน พร้อมการ์ด Loading แสดงความคืบหน้า (ดาวน์โหลด → คอมไพล์ → รัน) จบด้วย Complete / Fail เอง คืนค่า `ok, result`

```lua
local ok, res = Window:Load("https://example.com/script.lua", { Name = "MyScript" })   -- ลองใหม่เองถ้าพลาด

Library:Load("myscript.lua")                                    -- ไฟล์ใน workspace
Library:Load("print('hi')")                                     -- โค้ดดิบ
Library:Load(function(a) print(a) end, { Args = { 123 } })      -- ฟังก์ชัน

Window:Load(url, { Async = true, OnDone = function(ok, res) print(ok, res) end })   -- ไม่บล็อก

Window:LoadMany({                                               -- หลายอัน การ์ดเดียว หยุดที่อันแรกที่พัง
    "https://example.com/a.lua",
    { Source = "https://example.com/b.lua", Name = "B", Args = { Library } },
})
```

| ตัวเลือก | ความหมาย |
|---|---|
| `Name` | ชื่อบนการ์ด |
| `Args` | อาร์กิวเมนต์ที่ส่งให้สคริปต์ (`{ ... }`) |
| `Retries` / `RetryDelay` | ลองดาวน์โหลดซ้ำ (`2` ครั้ง / `0.6` วิ) |
| `Silent` | `true` = ไม่แสดงการ์ด |
| `Async` | `true` = ไม่บล็อก (ใช้ `OnDone` รับผล) |
| `OnDone(ok, result)` / `OnProgress(p, text)` | callback จบงาน / ความคืบหน้า |
| `Cache` | `true` = ใช้ซอร์สที่ดาวน์โหลดไว้ (`Library.LoadCache`) |
| `Title` / `SuccessText` / `FailText` | ข้อความบนการ์ด |

ใช้ `game:HttpGet` ก่อน ถ้าไม่ได้ลอง `request` / `syn.request` / `http_request` อัตโนมัติ ถ้าล้มเหลวจะแสดงสาเหตุบนการ์ดและ `warn` ออก console

---

## 15. ตรวจ UI อัตโนมัติ

ทำงานเองหลังสร้างหน้าต่าง (หน่วง 1.5 วิ), หลังสลับแท็บ และหลังปรับขนาด/หมุนจอ แจ้งเฉพาะปัญหา **ใหม่** ผ่าน `warn` + การ์ดใบเดียว ถ้า UI ปกติจะเงียบ

```lua
local issues = Window:Audit({ Print = true, Notify = true, Fix = true })   -- เรียกเอง
for _, i in ipairs(issues) do print(i.Level, i.Code, i.Message, i.Tab, i.Name) end
Library:Audit({ Print = true })                                             -- ทุกหน้าต่าง

Library.AutoCheck.Notify = false                                  -- ไม่เด้งการ์ด (ยัง warn)
Library.AutoCheck.Skip = { TextClip = true }                      -- ปิดบางกฎ
Library:CreateWindow({ Title = "X", AutoCheck = false })          -- ปิดทั้งหน้าต่าง
Library:CreateWindow({ Title = "X", AutoCheck = { Delay = 3 } })  -- ตั้งเฉพาะหน้าต่าง
```

| ตัวเลือก | ความหมาย |
|---|---|
| `Enabled` | เปิด/ปิดตรวจอัตโนมัติ (`true`) |
| `Delay` | หน่วงหลังสร้างหน้าต่าง วินาที (`1.5`) |
| `Print` / `Notify` | `warn` ใน console / การ์ดสรุป |
| `Visual` | ตรวจสิ่งที่เห็นบนจอ (ข้อความล้น, ล้นหน้าต่าง, ขนาดศูนย์, หลุดจอ) |
| `Fix` | แก้เองเมื่อทำได้ (ตอนนี้: หน้าต่างหลุดจอ → จัดกลาง) `Window:Audit` ต้องใส่ `Fix = true` เอง |
| `Skip` | `{ ชื่อกฎ = true }` ข้ามกฎนั้น |

| Code | ระดับ | ตรวจอะไร |
|---|---|---|
| `DupFlag` / `BadFlag` | error | Flag ซ้ำ / ไม่ใช่ string |
| `BadCallback` | error | `Callback` ไม่ใช่ function |
| `BadRange` | error | `Min` ไม่น้อยกว่า `Max` |
| `Orphan` | error | control ถูกลบ/หลุดจาก UI |
| `DefaultName` | warn | ไม่ใส่ `Name` เลยโชว์ชื่อชนิด |
| `BadDefault` / `DefaultRange` | warn | `Default` ไม่อยู่ใน `Options` / นอกช่วง |
| `EmptyTab` / `EmptySection` / `DupTab` | warn | แท็บ/section ว่าง, ชื่อแท็บซ้ำ |
| `LowContrast` | warn | สีตัวอักษรกับการ์ดอ่านยาก |
| `ZeroSize` / `Overflow` / `Offscreen` | warn | สูง 0 / ล้นขอบหน้าต่าง / หน้าต่างหลุดจอ |
| `TextClip` | info | ข้อความถูกตัด |

ตรวจ `Visual` เฉพาะแท็บที่เปิดอยู่ (แท็บอื่นตรวจเมื่อสลับไป) · มีคำสั่ง "Run UI check" ใน Command Palette · ดูคำอธิบายกฎที่ `Library.AuditCodes`

---

## 16. ไอคอน

```lua
Window:CreateTab({ Name = "Combat", Icon = "lucide:swords" })
Tab:CreateSection({ Name = "ESP", Icon = "lucide:eye" })
Section:CreateButton({ Name = "บันทึก", Icon = "lucide:save" })
Window:Notify({ Title = "สวัสดี", Icon = "lucide:bell" })
```

- แพ็ก: `lucide` (ค่าเริ่มต้น) / `solar` / `craft` / `geist` / `sfsymbols` / `gravity` เขียน `"pack:ชื่อ"` หรือแค่ `"ชื่อ"`
- `Icon` รับ: ตัวอักษร, asset id (ตัวเลข / `"rbxassetid://..."`), ชื่อไอคอน
- แพ็กโหลดตอนใช้ครั้งแรก (อาจใช้เวลาสองสามวินาที) ถ้าโหลดไม่ได้จะใช้ตัวอักษรแทน

| API | ทำอะไร |
|---|---|
| `Library.IconLib.Default = "solar"` | แพ็กเริ่มต้นสำหรับชื่อที่ไม่มี `pack:` |
| `Library.IconLib.Url = "..."` | ที่อยู่อื่นของ `Main-v2.lua` |
| `Library:PreloadIcons()` | ดาวน์โหลดล่วงหน้า (เรียกก่อนสร้างหน้าต่าง) |
| `Library:SetIconModule(mod)` | ใช้โมดูลที่โหลดไว้แล้ว |
| `Library:AddIcons("mine", { home = 123456 })` | เพิ่มแพ็กเอง → `Icon = "mine:home"` |
| `Library:IsIconName(name)` / `ResolveIcon(name)` / `MakeIcon(desc, color)` | ตัวช่วยระดับล่าง |

เปลี่ยน/เอาไอคอนออกในแท็บสำเร็จรูปด้วย `Icons = { ... }` (ใส่ `false` = ไม่มีไอคอน):

```lua
Window:CreateSettingsTab({ Icons = { ThemeSection = "solar:palette-bold", Save = "lucide:download", Delete = false } })
```

คีย์ใน SETTINGS: `ThemeSection FontSection MakerSection FxSection CreateButton UISection InterfaceSection ConfigSection HistorySection WindowSection Palette TestNotify Save Load Delete SaveAuto Copy Import Undo Redo Modified Snapshot Restore Center Unload`

---

## 17. ตาราง API ของ Library / Window / Tab / Section

### Library

| API | ทำอะไร |
|---|---|
| `Library:CreateWindow(cfg)` | สร้างหน้าต่าง |
| `Library:Unload()` | ทำลายทุกหน้าต่าง ล้าง Flags และ Hotkey |
| `Library.Flags` / `Library.Version` | ตาราง Flag / เวอร์ชัน |
| `Library.Splash` / `Library.StagedLoad` | ค่ากลางของหน้าโหลด / โหลดเป็นขั้น (หัวข้อ 5) |
| `Library:SetQuality("low"\|"high"\|"auto")` | ทางลัดของ `Perf.LowPower` |
| `Library.Perf` | `LowPower`, `Adaptive`, `SlowFrame`, `SlowShare`, `Warmup`, `Backdrop` |
| `Library:Goto(obj \| "flag" \| "ชื่อ")` | กระโดดไป control |
| `Library:ShowMenu(items, anchorFrame)` / `CloseMenu()` | เมนูคลิกขวาของเราเอง (`Library.ContextMenu = false` = ปิดทั้งระบบ) |
| `Library.Anim.Speed` | ความเร็วอนิเมชัน (1.25 = ช้าลง 25%) |

ที่เหลือดูหัวข้อ 8 (แจ้งเตือน), 9 (Flag/Config/Undo), 10 (ธีม/ฟอนต์), 12 (Command/Hotkey), 14 (Load), 15 (Audit), 16 (ไอคอน)

### CreateWindow(cfg)

| ตัวเลือก | ความหมาย |
|---|---|
| `Title` | ชื่อบนหน้าต่าง (`"แบรนด์ \| ย่อย"`) |
| `Logo` | asset id |
| `Width`, `Height` | ขนาด |
| `ToggleKey` | ปุ่มเปิด/ปิดเมนู (ผู้ใช้เปลี่ยนเองได้ในแท็บ SETTINGS) |
| `Theme` | ชื่อหรือ table (**ถ้าไม่ใส่** ธีมที่ผู้ใช้เลือกไว้จะโหลดกลับเอง) |
| `Font` | ชื่อฟอนต์ / `Enum.Font` / `{ Font, Bold }` |
| `TabHeight` | ความสูงปุ่มแท็บ px |
| `FX` | `"petals"`/`"orbs"`/`"grid"`/`"embers"`/`"rain"` |
| `Background = false` | ปิดพื้นหลัง |
| `Resizable = false` | ห้ามปรับขนาด |
| `OpenSnap = true` | ปุ่มลอย "เปิด" ไหลไปชิดขอบจอหลังปล่อย (ค่าเริ่มต้นอยู่ที่ที่วาง) |
| `Splash` | หน้าโหลด (หัวข้อ 5.2) |
| `StagedLoad` | โหลดเป็นขั้น (หัวข้อ 5.1) |
| `AutoCheck` | ตรวจ UI อัตโนมัติ (หัวข้อ 15) |
| `OnClose`, `OnDegrade(level)` | callback ตอนปิด / ตอนระบบลดคุณภาพเองเมื่อกระตุก |

### Window

| เมธอด | ทำอะไร |
|---|---|
| `CreateTab(cfg [, build])` | สร้างแท็บ: `Name`, `Icon`, `Build`, `Locked`, `LockReason`, `OnLockedClick`, `LockedNotify` |
| `GetTab(name)` / `SetTab(nameOrTab)` | หา / สลับแท็บ |
| `ListTabs()` | รายชื่อแท็บ (v3.14) |
| `RemoveTab(nameOrTab)` / `RenameTab(nameOrTab, newName)` | ลบ / เปลี่ยนชื่อแท็บ (v3.14) |
| `LockTab(tab, reason)` / `UnlockTab(tab)` / `IsTabLocked(tab)` | ล็อก/ปลดล็อกแท็บ |
| `SetVisible(v)` / `Toggle()` | แสดง/ซ่อนเมนู |
| `Open()` / `Close()` / `IsOpen()` | เปิด/ปิด/เช็กสถานะเมนู (v3.14) |
| `SetToggleKey(key)` / `GetToggleKey()` | เปลี่ยน/อ่านปุ่มเปิด-ปิดเมนู เช่น `Enum.KeyCode` หรือ `"F4"` (v3.14) |
| `SetMaximized(v)` / `IsMaximized()` | ขยายเต็มจอ |
| `Resize(w, h)` / `SetSize(w, h)` / `Center()` | ปรับขนาด / จัดกลาง |
| `SetTitle("แบรนด์ \| ย่อย")` | เปลี่ยนชื่อหน้าต่าง |
| `Flash(color)` | กระพริบหน้าต่าง |
| `Tooltip(frame, "ข้อความ")` | ใส่ทิปให้ UI ใดก็ได้ |
| `SetBackground("orbs"\|false\|nil)` | เปลี่ยนเอฟเฟกต์พื้นหลัง (`nil` = ตามธีม) |
| `Goto(obj \| "flag" \| "ชื่อ")` | กระโดดไป control |
| `OnResize(fn)` | ดักตอนปรับขนาด |
| `CloseDropdowns()` | ปิด dropdown ที่เปิดอยู่ |
| `Destroy()` | ทำลายหน้าต่างนี้ |
| `CreateSettingsTab` / `CreateDefaultTabs` (+ `CreateThemeTab` ถ้าอยากได้แท็บธีมแยก) | แท็บสำเร็จรูป (หัวข้อ 11) |

### Tab / Section

| เมธอด | ทำอะไร |
|---|---|
| `tab:CreateSection({ Name, Column, Collapsible, Collapsed, Icon })` | สร้าง section (`Column` = `1` หรือ `2`) |
| `tab:SetBadge("3")` | ป้ายที่แท็บ (เช่น `"NEW"`, ตัวเลข) |
| `tab:Load(fn)` / `tab:Build(fn)` | เพิ่มฟังก์ชันที่รันหลังทุกแท็บเข้าแล้ว (หัวข้อ 5.1) |
| `tab:Remove()` / `tab:Rename(name)` | ลบ / เปลี่ยนชื่อแท็บ (v3.14) |
| `tab:Lock(reason)` / `Unlock()` / `SetLocked(bool, reason)` / `IsLocked()` / `SetLockReason(text)` | ล็อกแท็บ (แสดงแม่กุญแจ เปิดไม่ได้) |
| `tab:ResetAll()` / `section:ResetAll()` | รีเซ็ตค่าทั้งแท็บ / ทั้ง section |
| `section:SetCollapsed(bool, instant)` | พับ/กาง section |

### Helper

- `Library.Util`: `Bag`, `Dispose`, `Opt`, `Debounce`, `Throttle`, `Round`, `FormatNumber`, `FormatTime`, `Truncate`, `Lighten`, `Darken`, `ToHex`, `FromHex`, `Contrast`, `Create`
- `Library.Anim`: `Tween`, `Show(obj, { From, Distance, Time, Scale })`, `Hide(obj, { To, Destroy })`, `Pulse(obj)`, `Stop(obj)`, `Speed`
- `Library.Responsive`: `IsTouch`, `Viewport(win)`, `Breakpoint(win)` → `"phone"`/`"tablet"`/`"desktop"`, `Width(win, max, margin)`, `Touch(pc, touch)`, `Scale(n)`, `OnChange(win, fn)`

---

## 18. ปัญหาที่พบบ่อย

**เมนูไม่ขึ้น**
ตรวจว่า executor รองรับ `game:HttpGet` และต่ออินเทอร์เน็ตอยู่ (เปิด URL ด้านบนในเบราว์เซอร์ดูได้ว่าโหลดขึ้นไหม) แล้วลองกดปุ่มเปิด/ปิดเมนู (`RightShift` ตามตัวอย่าง)

**รันแล้วเมนูยังว่าง / แท็บยังไม่ครบ**
เป็นการโหลดเป็นขั้นตามปกติ รอจนการ์ด Loading ขึ้น "Ready" ถ้าอยากให้ขึ้นทันทีใช้ `StagedLoad = false` ใน `CreateWindow`

**Config ไม่โหลดตอนเริ่ม**
ต้องมีไฟล์ `auto.json` (กด "บันทึกเป็น auto" ในแท็บ SETTINGS ก่อน) และต้องเรียก `AutoloadConfig` **หลังสร้างทุก control เสร็จ** ถ้า control อยู่ใน `Build` ให้เรียกใน `Window:OnLoaded(...)` (หัวข้อ 5.1)

**ธีมที่เลือกไว้ไม่ถูกจำ**
ถ้าใส่ `Theme = "..."` ใน `CreateWindow` จะบังคับธีมนั้นทุกครั้ง ลบออกเพื่อให้ธีมที่ผู้ใช้เลือกโหลดกลับเอง

**มือถือกระตุก / เครื่องช้า**
ตั้ง `Library.Perf.LowPower = true` หรือให้ผู้ใช้เลือกคุณภาพ `low` ในแท็บ SETTINGS (ส่วน พื้นหลัง / เอฟเฟกต์)

**กด "คัดลอก Config" แล้วไม่ได้**
executor ไม่รองรับคลิปบอร์ด ใช้การบันทึกเป็นไฟล์ Config แทน

**ตัวหนังสือมองไม่เห็นบนปุ่ม / ป้าย / ✓ ในธีมสีสว่าง**
ถ้าเป็นปุ่มที่ตั้ง `TextColor` เอง ให้ลบออก (ไลบรารีเลือกสีให้เอง) หรือเลือกสีที่ตัดกับพื้น

**รันแล้ว UI ไม่เหมือนที่คู่มือบอก (เช่น ไม่มี Splash แบบใหม่ / ไม่มี `CreateListBox`)**
ส่วนใหญ่คือไฟล์บน GitHub ยังไม่ได้อัปเดต หรือ executor แคชผลโหลดเก่าไว้ ลองรันใหม่ แล้วเช็ก:
```lua
print(Library.Splash, Library.StagedLoad, Library.CreateListBox == nil)
```
ถ้าสองตัวแรกขึ้น `table: ...` แปลว่าได้ตัวใหม่ · ถ้าไม่เห็นหน้าโหลดจริง ให้เปิด console หา `[SpectreUI] splash error: ...` และดูว่าไม่ได้ตั้ง `Splash = false` หรือ `Library.Splash.Enabled = false`

**หน้าโหลดนานไป / สั้นไป**
ปรับ `Splash = { Duration = ... }` (วินาที) หรือ `Library.Splash.Duration` ตั้ง `Skippable = true` ให้แตะข้ามได้

**แท็บขึ้นช้าไป / เร็วไป**
ปรับ `Library.StagedLoad.TabDelay` และ `BuildDelay`

**Watermark / KeybindList เด้งตอนแตะ หรือลากไม่ถึงขอบจอ**
ลากต้องเกิน 5px ถึงจะย้าย ถ้ายังไม่ถึงขอบจอจริง ให้ตรวจว่า executor รองรับ `ScreenInsets` (Roblox รุ่นเก่าไม่มีค่านี้)

**อัปเดตแล้วค่าที่เคยตั้งไว้หาย**
ดูตารางเปลี่ยนชื่อ Flag ในหัวข้อ 19 (v3.7)

---

## 19. บันทึกการเปลี่ยนแปลง

> หมายเหตุ: ตัวเลข `Library.Version` ในโค้ดตอนนี้ยังพิมพ์ `3.14.0` (ยังไม่ได้อัปเดต) เลขเวอร์ชันด้านล่างอ้างอิงตามหัวข้อฟีเจอร์ในไฟล์

### ล่าสุด (ยังไม่ระบุเลขเวอร์ชัน)

- **รวมแท็บ THEME เข้า SETTINGS:** `Window:CreateSettingsTab()` มีธีมสี / Font / สร้างธีม / เอฟเฟกต์ครบ ไม่ต้องเรียก `CreateThemeTab()` แยก (`CreateDefaultTabs` ไม่สร้างแท็บ THEME ให้แล้ว ใช้ `Theme = true` ถ้าต้องการ)
- เพิ่มส่วน **Interface** ใน SETTINGS: สวิตช์ FPS / Ping, สวิตช์รายการ Keybind, ตำแหน่ง/เวลาแจ้งเตือน, ปุ่มทดสอบ · ตัวเลือกใหม่ `Sections.Interface`, `WatermarkText`, `Columns`
- จัดเลย์เอาต์ใหม่: ซ้าย = หน้าตา, ขวา = ระบบ, ส่วน Window (Unload) ไว้ท้ายสุด
- Dropdown ธีมเดิมของ SETTINGS (Flag `ui_settings_theme`) ถูกแทนด้วยตัวจัดการธีมเต็มรูปแบบ Config เก่าที่เก็บค่านี้จะข้ามไป · `parts.ThemePicker` / `parts.ThemeSection` ยังใช้ได้
- **แก้คู่มือให้ตรงกับโค้ด:** ไอคอนเริ่มต้นของแท็บ (`lucide:settings` / `lucide:palette`), คีย์ `Icons` ใช้ `ThemeSection` ไม่ใช่ `Theme`, ค่าเริ่มต้น `Splash.Duration` เป็น `4` และเพิ่มตัวเลือก `WaitBuild` / `IdleTime` / `BuildTimeout` / `Theme` / `Panel` / `Block` / `Backdrop` กับ `HoldLoading` / `ReleaseLoading` / `FinishLoading`, แก้คำพิมพ์ผิด

### v3.17

- **โหลดเป็นขั้น (Staged Loading):** แท็บโผล่ทีละอัน แล้วค่อยรัน `Build` ของแต่ละแท็บ มีการ์ด Loading บอกความคืบหน้า
- เพิ่ม `Build` ใน `CreateTab`, `Tab:Load` / `Tab:Build`, `Window:OnLoaded` / `IsLoaded` / `WaitLoaded` / `StartLoad`
- ค่ากลาง `Library.StagedLoad` และตัวเลือก `StagedLoad` ใน `CreateWindow`
- ระบบตรวจ UI อัตโนมัติรอจนโหลดครบก่อน

### v3.16

- **Splash เปลี่ยนเป็นแบบเรียบ:** โลโก้ + ชื่อ + แถบโหลดบางๆ + ข้อความสถานะบรรทัดเดียว เฟดเข้า/ออก (เอาอนุภาค กลิตช์ มุม HUD ของ v3.15 ออก)
- ความยาวเริ่มต้นสั้นลงจาก 6 วิ เหลือ **2.5 วิ** · แตะข้ามได้หลัง 0.8 วิแรก

### v3.15

- เพิ่มหน้าโหลดตอนเปิด UI (Splash) และตัวเลือก `Splash` ใน `CreateWindow` + `Library.Splash` (ถูกปรับรูปแบบใน v3.16)

### v3.14

- **Controls ใหม่:** `CreateButtonRow`, `CreateInputButton`, `CreateKeyValue`, `CreateCodeBlock`, `CreateCountdown`, `CreateListBox`, `CreateTable`, `CreateImage`, `CreateItemGrid`
- **Window ใหม่:** `AskAmount`, `RemoveTab` / `RenameTab` / `ListTabs`, `SetToggleKey` / `GetToggleKey`, `Open` / `Close` / `IsOpen` · **Tab:** `Remove` / `Rename`
- **Library:** `Library:Copy(text, title)`

### v3.13.x

- **3.13.4** ScreenGui ของหน้าต่างหลัก/HUD/Dialog ครอบเต็มจอจริง (`ScreenInsets = None`) UI ที่ลากได้ไปชิดขอบจอจริงได้
- **3.13.3** แก้ Watermark / KeybindList เด้งตอนแตะ (ต้องลากเกิน 5px ถึงจะย้าย)
- **3.13.2** แก้ Slider / RangeSlider สองหลอดขยับพร้อมกันบนมือถือ (ลากได้ทีละหลอด)
- **3.13.1** แก้ตัวอักษรมองไม่เห็นในธีมสีสว่าง: เพิ่ม `Library.OnAccent` เลือกสีขาว/ดำตามสีหลักของธีม และเลือกใหม่ตอนเปลี่ยนธีมสด
- **3.13** ฟอนต์ (`SetFont` / `CycleFont` / `RegisterFont` / `ListFonts` / `CreateFontPicker`), `SetTextScale`, Flag helper (`SetFlag` / `ToggleFlag` / `SetFlags` / `GetFlags` / `GetControl`), `Library:Hotkey` / `ListHotkeys`, แชร์ธีม (`ExportTheme` / `ImportTheme`), ปุ่มแท็บเล็กลงบนมือถือ (`TabHeight`), แก้ Dropdown ค้าง/กระตุกบนมือถือ

### v3.12

- เพิ่ม `CreateStepper` และ `CreateStat`

### v3.11

- เพิ่ม `Window:Watermark`, `Window:KeybindList`, `Window:Tour` และคำสั่ง Palette: Toggle watermark / Toggle keybind list

### v3.10

- เพิ่มระบบตรวจ UI อัตโนมัติ: `Window:Audit` / `Library:Audit` / `Library.AutoCheck`

### v3.9

- เพิ่ม Load API: `Library:Load` / `LoadMany`, `Window:Load` / `LoadMany`

### v3.8

- เพิ่มระบบไอคอน และไอคอนในแท็บสำเร็จรูป

### v3.7

- แท็บ THEME / SETTINGS เป็นของสำเร็จรูป (`CreateThemeTab` / `CreateSettingsTab` / `CreateDefaultTabs`)
- เพิ่มปุ่มคัดลอก/นำเข้า Config และแจ้งผลทุกปุ่ม · ถามยืนยันก่อนลบ Config และก่อน Unload
- แก้ปุ่มเมนู: โหลด Config ที่มีปุ่มเมนูต่างจากเดิม ปุ่มเปิด/ปิดเมนูจะตามค่าที่โหลดด้วย
- **Flag ของส่วนธีมถูกเปลี่ยนชื่อ** (มีคำนำหน้า `ui_`):

| เดิม | ใหม่ |
|---|---|
| `bg_fx` | `ui_bg_fx` |
| `quality` | `ui_quality` |
| `theme_next_key` | `ui_theme_next` |
| `theme_prev_key` | `ui_theme_prev` |
| `menu_key` | `ui_menu_key` |

Config เก่าที่บันทึกไว้จะไม่ผูกกับค่าเหล่านี้ แค่ตั้งใหม่ครั้งเดียวแล้วบันทึกทับ
