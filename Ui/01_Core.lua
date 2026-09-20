--[[
    SpectreUI v7.0 — Pro Mobile & PC UI Library (WindUI-parity update)
    ใหม่ใน v7: Element API (Lock/Unlock/SetTitle/SetDesc/Highlight), Section แบบพับได้, Group, Code, Space, Checkbox,
    Paragraph แบบเต็ม (Title/Desc/Buttons), Desc ทุก element, Localization, SetFont, Dialog หลายปุ่ม, Notify (Icon/Buttons/Persistent),
    Window: Tag/TopbarButton/UserPanel/BackgroundImage/Acrylic/Transparency/SetUIScale/SelectTab/OnOpen/OnClose ฯลฯ, ธีมเพิ่ม 15 ชุด
    ------------------------------------------------------------------
    Pro Mobile & PC UI Library v6.1 (Massive Icon Update)
    =====================================================
    อัปเดตจาก v6:
    - เพิ่มระบบไอคอนเป็นจำนวนมาก (Navigation, System, Game, Social, etc.)
    - ใช้ Asset ID คุณภาพสูงแบบเดียวกับ WindUI/Fluent
]]

local Library = {}
Library.__index = Library
Library.Flags = {}
Library.Themes = {}
Library.CurrentTheme = "Midnight"
Library.Version = "7.0.0"

-- ============ FLAG SYSTEM (ต่อขยาย: registry + event สำหรับ Config save/load และ dependency) ============
Library.FlagElements = {}                    -- ชื่อ Flag -> element object (ใช้ตอน LoadConfig เพื่อ Set ค่ากลับเข้า UI จริง)
Library.FlagChanged = Instance.new("BindableEvent") -- ยิงทุกครั้งที่ Flag เปลี่ยนค่า (flag, value) ใช้กับ LinkVisibility/KeyList
Library.ConfigFolder = "SpectreUI_Config"     -- โฟลเดอร์เก็บไฟล์ config (เปลี่ยนได้ผ่าน CreateWindow({ConfigFolder = "..."}))

-- คืนค่าปัจจุบันของ Flag ตามชื่อ (เทียบเท่าการอ่าน Library.Flags[name] ตรงๆ)
function Library:GetFlag(name)
    return Library.Flags[name]
end

-- ตั้งค่า Flag แบบ manual โดยไม่ต้องผ่าน element ใดๆ (เช่น preset/config loader)
function Library:SetFlag(name, value)
    Library.Flags[name] = value
end

-- ============ ERROR LOG SYSTEM (ต่อขยาย: ring buffer + event สำหรับ Debug panel/telemetry) ============
-- เก็บ error ที่เกิดขึ้นระหว่างรัน (callback พัง, โหลด asset ไม่ผ่าน, ฯลฯ) ไว้ที่เดียว
-- ให้ตัว UI (Debug panel) หรือระบบ telemetry ภายนอกมาอ่าน/subscribe ต่อได้ ไม่ต้องเดาว่าพังตรงไหนจาก console เฉยๆ
Library.ErrorLog = {}
Library.MaxErrorLog = 50
Library.ErrorLogChanged = Instance.new("BindableEvent") -- ยิงทุกครั้งที่มี error ใหม่เข้า log (entry) ใช้กับ badge/แจ้งเตือนสด

-- source = ชื่อจุดที่ error เกิด เช่น "Callback:ESP.Chams", "IconsLoader", "SaveConfig"
-- message = ข้อความ error, traceback = ผลลัพธ์จาก debug.traceback (optional ใส่ nil ได้ถ้าไม่มี)
function Library:LogError(source, message, traceback)
    local entry = {
        time = os.time(),
        source = tostring(source or "unknown"),
        message = tostring(message),
        traceback = traceback,
    }
    table.insert(Library.ErrorLog, 1, entry)
    if #Library.ErrorLog > Library.MaxErrorLog then
        table.remove(Library.ErrorLog) -- ตัดตัวเก่าสุดทิ้ง กัน log บวมไม่รู้จบ
    end
    Library.ErrorLogChanged:Fire(entry)
    return entry
end

function Library:GetErrorLog()
    return Library.ErrorLog
end

-- ต่อ error log ทั้งหมดเป็นข้อความก้อนเดียว เอาไว้กด "Copy" ส่งเข้า Discord support ได้ในคลิกเดียว
function Library:ExportErrorLog()
    local lines = {}
    for _, e in ipairs(Library.ErrorLog) do
        table.insert(lines, string.format("[%s] %s: %s", os.date("%H:%M:%S", e.time), e.source, e.message))
    end
    return table.concat(lines, "\n")
end

-- ============ COMMAND REGISTRY (ต่อขยาย: ให้ทุก Button/Toggle/Tab ที่สร้างขึ้น ลงทะเบียนตัวเองอัตโนมัติ) ============
-- ใช้เป็นฐานข้อมูลให้ Command Palette (Ctrl+K) ค้นหา/สั่งงานได้จากจุดเดียว ไม่ต้องไล่กดเมนูเอง
-- เก็บแยกจาก UI เพื่อให้เรียก Library:RegisterCommand(...) เองจากนอก element ก็ได้เช่นกัน
Library.Commands = {}
Library.CommandsChanged = Instance.new("BindableEvent") -- ยิงตอนมี command ใหม่เพิ่มเข้ามา (เผื่อ Palette ที่เปิดค้างอยู่ต้อง refresh)

-- entry = {Title, SubText (optional), Icon (optional asset/ชื่อไอคอนใน Library.Icons), TabName (optional, โชว์เป็น breadcrumb), Type ("Tab"/"Button"/"Toggle"/"Custom"), Action = function() ... end}
function Library:RegisterCommand(entry)
    entry = type(entry) == "table" and entry or {}
    if type(entry.Action) ~= "function" then return end
    entry.Title = tostring(entry.Title or "Command")
    entry.Id = entry.Id or (entry.Title .. "#" .. tostring(#Library.Commands + 1))
    table.insert(Library.Commands, entry)
    Library.CommandsChanged:Fire(entry)
    return entry
end

function Library:UnregisterCommandsByTab(tabName)
    for i = #Library.Commands, 1, -1 do
        if Library.Commands[i].TabName == tabName then table.remove(Library.Commands, i) end
    end
end

-- ============ UNDO / REDO HISTORY (ต่อขยาย: จำค่า Flag ก่อน-หลังการเปลี่ยนทุกครั้ง) ============
-- ทำงานอัตโนมัติกับทุก element ที่ผูก Flag ไว้ (Toggle/Slider/Dropdown/ColorPicker ฯลฯ) เพราะทุกตัวยิงผ่าน Library.FlagChanged อยู่แล้ว
-- การลาก Slider/ColorPicker เร็วๆ จะถูก "รวม" เป็น undo step เดียวถ้าเปลี่ยน flag เดิมซ้ำภายใน 0.6 วิ กัน undo stack บวมจนต้องกด undo เป็นสิบครั้งกว่าจะกลับไปถึงค่าก่อนหน้าจริงๆ
Library.HistoryEnabled = true
Library.History = {}
Library.HistoryPointer = 0
Library.MaxHistory = 100
Library.HistoryChanged = Instance.new("BindableEvent") -- ยิงทุกครั้งที่ history เปลี่ยน (push/undo/redo) ใช้กับปุ่ม Undo/Redo ที่ต้อง enable/disable ตาม pointer

local HISTORY_MERGE_WINDOW = 0.6
local applyingHistory = false
local lastKnownFlagValue = {}

local function pushHistoryEntry(flag, oldValue, newValue)
    if applyingHistory or not Library.HistoryEnabled then return end
    if oldValue == newValue then return end
    local now = os.clock()
    local top = Library.History[Library.HistoryPointer]
    if top and top.flag == flag and (now - top.time) < HISTORY_MERGE_WINDOW then
        top.newValue = newValue
        top.time = now
        Library.HistoryChanged:Fire()
        return
    end
    -- ถ้า undo ย้อนมาแล้วเพิ่งแก้ค่าใหม่ ให้ตัดกิ่ง redo เดิมทิ้ง (พฤติกรรมมาตรฐานของ undo stack ทั่วไป)
    for i = #Library.History, Library.HistoryPointer + 1, -1 do
        table.remove(Library.History)
    end
    table.insert(Library.History, {flag = flag, oldValue = oldValue, newValue = newValue, time = now})
    if #Library.History > Library.MaxHistory then
        table.remove(Library.History, 1)
    end
    Library.HistoryPointer = #Library.History
    Library.HistoryChanged:Fire()
end

Library.FlagChanged.Event:Connect(function(flag, value)
    pushHistoryEntry(flag, lastKnownFlagValue[flag], value)
    lastKnownFlagValue[flag] = value
end)

local function applyHistoryValue(flag, value)
    applyingHistory = true
    local elem = Library.FlagElements[flag]
    local ok = false
    if elem and elem.Set then
        ok = pcall(function() elem:Set(value) end)
    end
    if not ok then
        Library.Flags[flag] = value
        Library.FlagChanged:Fire(flag, value)
    end
    lastKnownFlagValue[flag] = value
    applyingHistory = false
end

-- ย้อนกลับการเปลี่ยน Flag ล่าสุด 1 ขั้น คืนค่า true ถ้าย้อนสำเร็จ, false ถ้าไม่มีอะไรให้ย้อนแล้ว
function Library:Undo()
    if Library.HistoryPointer <= 0 then return false end
    local entry = Library.History[Library.HistoryPointer]
    applyHistoryValue(entry.flag, entry.oldValue)
    Library.HistoryPointer -= 1
    Library.HistoryChanged:Fire()
    return true, entry
end

-- ทำซ้ำการเปลี่ยนที่เพิ่ง Undo ไป คืนค่า true ถ้าทำสำเร็จ, false ถ้าอยู่ปลายสุดของ history แล้ว
function Library:Redo()
    if Library.HistoryPointer >= #Library.History then return false end
    Library.HistoryPointer += 1
    local entry = Library.History[Library.HistoryPointer]
    applyHistoryValue(entry.flag, entry.newValue)
    Library.HistoryChanged:Fire()
    return true, entry
end

function Library:ClearHistory()
    Library.History = {}
    Library.HistoryPointer = 0
    Library.HistoryChanged:Fire()
end

function Library:CanUndo() return Library.HistoryPointer > 0 end
function Library:CanRedo() return Library.HistoryPointer < #Library.History end

-- ============ ICONS SETUP ============
-- แยกออกเป็นไฟล์ Icons.lua ต่างหากแล้ว โหลดผ่าน loadstring เหมือนไฟล์อื่นๆ ที่ host บน GitHub raw
-- แก้ URL ตรงนี้ให้ตรงกับ path จริงของ Icons.lua ในเรโปก่อนใช้งาน
local ICONS_URL = "https://raw.githubusercontent.com/SpectreWareZ/SpectreWare/refs/heads/main/Tools/Icons.lua"
local iconsOk, iconsResult = pcall(function()
    return loadstring(game:HttpGet(ICONS_URL, true))()
end)
Library.Icons = iconsOk and iconsResult or {}
if not iconsOk then
    warn("[SpectreUI] โหลด Icons.lua ไม่สำเร็จ ไอคอนจะไม่ขึ้น: " .. tostring(iconsResult))
    Library:LogError("IconsLoader", iconsResult)
end


local UserInputService = game:GetService("UserInputService")

-- ============ FONT SYSTEM (อังกฤษคมชัด + รองรับไทยอัตโนมัติ) ============
-- Enum.Font.Gotham* ถูก Roblox ประกาศเลิกใช้ไปแล้วและถูก map ไปที่ Montserrat โดยอัตโนมัติ
-- (บางเครื่อง/บางจอเรนเดอร์แล้วดูไม่คมเท่าที่ควร โดยเฉพาะบนมือถือจอละเอียดสูง)
-- เปลี่ยนมาใช้ Builder Sans ซึ่งเป็นฟอนต์ระบบตัวล่าสุดที่ Roblox ใช้เองในหน้า UI ปัจจุบัน คมชัดกว่า
-- หมายเหตุสำคัญ: Roblox ยังไม่มีฟอนต์ built-in ตัวไหนที่ออกแบบมาคู่กับภาษาไทยโดยเฉพาะ
-- ตัวอักษรไทยจะ fallback ไปฟอนต์ระบบของเครื่องนั้นๆ เสมอไม่ว่าจะตั้ง FontFace เป็นอะไร
-- ถ้าต้องการให้ไทย-อังกฤษเป็นฟอนต์เดียวกันจริงๆ (เช่น Kanit/Sarabun/IBM Plex Sans Thai)
-- ต้องอัปโหลดฟอนต์นั้นผ่าน Studio Font Uploader เอง แล้วเอา rbxassetid ที่ได้มาแทนที่ BUILDER_FAMILY ด้านล่างนี้
local BUILDER_FAMILY = "rbxasset://fonts/families/BuilderSans.json"
local FONT_WEIGHTS = {
    Regular  = Enum.FontWeight.Regular,
    Medium   = Enum.FontWeight.Medium,
    SemiBold = Enum.FontWeight.SemiBold,
    Bold     = Enum.FontWeight.Bold,
}
local function UI_Font(weightName)
    return Font.new(BUILDER_FAMILY, FONT_WEIGHTS[weightName] or Enum.FontWeight.Regular, Enum.FontStyle.Normal)
end
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local StatsService = game:GetService("Stats")

-- ============ CACHED TWEENINFO (avoid re-allocating identical TweenInfo objects on every hover/click) ============
local TI = {
    d012_Sine_Out = TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
    d014_Sine_Out = TweenInfo.new(0.14, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
    d015_Sine_Out = TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
    d016_Sine_In = TweenInfo.new(0.16, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
    d018_Quint_In = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
    d018_Sine_Out = TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
    d02_Quint_Out = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    d02_Sine_Out = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
    d022_Sine_Out = TweenInfo.new(0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
    d028_Sine_Out = TweenInfo.new(0.28, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
    d03_Sine_Out = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
    d008_Quad_Out = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    d015_Quint_In = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
    d02_Back_Out = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    d022_Back_Out = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    d024_Quint_Out = TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    d02_Quint_In = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
    -- เพิ่มชุด "สปริง/เด้งแรง" สำหรับแอนิเมชันโหดๆ (เปิดหน้าต่าง, ทอมโบน, พัลส์)
    d035_Elastic_Out = TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
    d045_Back_Out = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    d028_Back_Out_Wobble = TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
}
local CoreGui = game:GetService("CoreGui")

-- ============ RENDER-SYNCED DRAG HELPER ============
local function createRenderSyncedDrag(applyFn)
    local conn, pending, hasPending = nil, nil, false
    local function push(...)
        pending = {...}
        hasPending = true
    end
    local function start()
        if conn then return end
        conn = RunService.RenderStepped:Connect(function()
            if hasPending then
                hasPending = false
                applyFn(table.unpack(pending))
            end
        end)
    end
    local function stop()
        if conn then conn:Disconnect(); conn = nil end
        hasPending, pending = false, nil
    end
    return push, start, stop
end

-- ============ THEMES SETUP ============
local BaseTheme = {
    Background = Color3.fromRGB(10, 10, 15),
    Sidebar = Color3.fromRGB(14, 14, 20),
    Topbar = Color3.fromRGB(16, 16, 24),
    Element = Color3.fromRGB(24, 24, 34),
    ElementHover = Color3.fromRGB(33, 33, 46),
    Text = Color3.fromRGB(245, 245, 250),
    SubText = Color3.fromRGB(150, 150, 172),
    AccentA = Color3.fromRGB(124, 108, 255),
    AccentB = Color3.fromRGB(96, 200, 255),
    ToggleOff = Color3.fromRGB(46, 46, 60),
    Stroke = Color3.fromRGB(50, 50, 66),
    Success = Color3.fromRGB(66, 214, 146),
    Danger = Color3.fromRGB(255, 92, 92),
    Warning = Color3.fromRGB(255, 189, 74),
    Info = Color3.fromRGB(94, 176, 255)
}

local function resolveTheme(overrides)
    local t = {}
    for k, v in pairs(BaseTheme) do t[k] = v end
    if overrides then
        for k, v in pairs(overrides) do t[k] = v end
    end
    t.Accent = t.AccentA
    return t
end

Library.Themes.Midnight = resolveTheme(nil)
Library.Themes.Ocean = resolveTheme({
    Background = Color3.fromRGB(6, 14, 22), Sidebar = Color3.fromRGB(8, 18, 28), Topbar = Color3.fromRGB(10, 22, 34),
    Element = Color3.fromRGB(14, 30, 46), ElementHover = Color3.fromRGB(19, 40, 60), AccentA = Color3.fromRGB(45, 212, 233),
    AccentB = Color3.fromRGB(59, 130, 246), ToggleOff = Color3.fromRGB(22, 40, 58), Stroke = Color3.fromRGB(27, 50, 70),
    Text = Color3.fromRGB(240, 248, 252), SubText = Color3.fromRGB(140, 165, 185)
})
Library.Themes.Crimson = resolveTheme({
    Background = Color3.fromRGB(18, 8, 11), Sidebar = Color3.fromRGB(22, 10, 13), Topbar = Color3.fromRGB(26, 12, 16),
    Element = Color3.fromRGB(35, 16, 20), ElementHover = Color3.fromRGB(45, 21, 26), AccentA = Color3.fromRGB(255, 78, 108),
    AccentB = Color3.fromRGB(255, 158, 87), ToggleOff = Color3.fromRGB(47, 23, 27), Stroke = Color3.fromRGB(52, 25, 30),
    Text = Color3.fromRGB(252, 245, 246)
})
Library.Themes.Light = resolveTheme({
    Background = Color3.fromRGB(240, 241, 246), Sidebar = Color3.fromRGB(255, 255, 255), Topbar = Color3.fromRGB(255, 255, 255),
    Element = Color3.fromRGB(255, 255, 255), ElementHover = Color3.fromRGB(245, 246, 250), Text = Color3.fromRGB(20, 20, 28),
    SubText = Color3.fromRGB(102, 102, 120), AccentA = Color3.fromRGB(109, 99, 255), AccentB = Color3.fromRGB(0, 191, 214),
    ToggleOff = Color3.fromRGB(216, 218, 227), Stroke = Color3.fromRGB(228, 229, 236),
    Success = Color3.fromRGB(22, 163, 106), Danger = Color3.fromRGB(224, 54, 54), Warning = Color3.fromRGB(217, 130, 0), Info = Color3.fromRGB(37, 108, 224)
})
-- ดาร์กเขียว ป่าลึก อำพลาง
Library.Themes.Forest = resolveTheme({
    Background = Color3.fromRGB(8, 14, 10), Sidebar = Color3.fromRGB(10, 18, 12), Topbar = Color3.fromRGB(12, 20, 14),
    Element = Color3.fromRGB(16, 28, 18), ElementHover = Color3.fromRGB(22, 38, 24),
    AccentA = Color3.fromRGB(52, 211, 110), AccentB = Color3.fromRGB(101, 232, 169),
    ToggleOff = Color3.fromRGB(20, 35, 22), Stroke = Color3.fromRGB(26, 46, 30),
    Text = Color3.fromRGB(240, 252, 244), SubText = Color3.fromRGB(130, 170, 140),
    Success = Color3.fromRGB(52, 211, 110), Info = Color3.fromRGB(101, 232, 200)
})
-- ส้มอมชมพูอ่อน อาทิตย์ตก
Library.Themes.Sunset = resolveTheme({
    Background = Color3.fromRGB(18, 10, 8), Sidebar = Color3.fromRGB(22, 12, 9), Topbar = Color3.fromRGB(26, 14, 10),
    Element = Color3.fromRGB(34, 18, 12), ElementHover = Color3.fromRGB(44, 24, 16),
    AccentA = Color3.fromRGB(255, 118, 56), AccentB = Color3.fromRGB(255, 212, 86),
    ToggleOff = Color3.fromRGB(45, 24, 16), Stroke = Color3.fromRGB(52, 28, 18),
    Text = Color3.fromRGB(255, 248, 240), SubText = Color3.fromRGB(185, 155, 130),
    Warning = Color3.fromRGB(255, 212, 86), Danger = Color3.fromRGB(255, 80, 60)
})
-- ชมพูอ่อน ซากุระ ญี่ปุ่น
Library.Themes.Sakura = resolveTheme({
    Background = Color3.fromRGB(16, 10, 14), Sidebar = Color3.fromRGB(20, 13, 18), Topbar = Color3.fromRGB(24, 15, 21),
    Element = Color3.fromRGB(32, 20, 28), ElementHover = Color3.fromRGB(42, 27, 37),
    AccentA = Color3.fromRGB(255, 128, 180), AccentB = Color3.fromRGB(255, 190, 220),
    ToggleOff = Color3.fromRGB(42, 26, 36), Stroke = Color3.fromRGB(52, 32, 46),
    Text = Color3.fromRGB(255, 245, 252), SubText = Color3.fromRGB(188, 148, 175),
    Success = Color3.fromRGB(200, 160, 220), Info = Color3.fromRGB(180, 130, 200)
})
-- ดำสนิท เส้นขอบไซยาน ว่างเปล่า
Library.Themes.Void = resolveTheme({
    Background = Color3.fromRGB(4, 4, 6), Sidebar = Color3.fromRGB(7, 7, 10), Topbar = Color3.fromRGB(8, 8, 12),
    Element = Color3.fromRGB(14, 14, 20), ElementHover = Color3.fromRGB(20, 20, 30),
    AccentA = Color3.fromRGB(0, 245, 255), AccentB = Color3.fromRGB(0, 180, 255),
    ToggleOff = Color3.fromRGB(18, 18, 28), Stroke = Color3.fromRGB(24, 24, 36),
    Text = Color3.fromRGB(245, 250, 255), SubText = Color3.fromRGB(140, 155, 175),
    Info = Color3.fromRGB(0, 200, 240)
})
-- ดำทองคำ หรูหรา
Library.Themes.Gold = resolveTheme({
    Background = Color3.fromRGB(12, 9, 4), Sidebar = Color3.fromRGB(16, 12, 5), Topbar = Color3.fromRGB(18, 14, 6),
    Element = Color3.fromRGB(26, 20, 8), ElementHover = Color3.fromRGB(34, 26, 10),
    AccentA = Color3.fromRGB(255, 195, 60), AccentB = Color3.fromRGB(255, 230, 120),
    ToggleOff = Color3.fromRGB(34, 26, 10), Stroke = Color3.fromRGB(46, 34, 14),
    Text = Color3.fromRGB(255, 252, 240), SubText = Color3.fromRGB(185, 168, 120),
    Warning = Color3.fromRGB(255, 195, 60), Success = Color3.fromRGB(180, 215, 90)
})
-- น้ำเงินเข้ม น้ำแข็งขั้วโลก
Library.Themes.Arctic = resolveTheme({
    Background = Color3.fromRGB(7, 12, 18), Sidebar = Color3.fromRGB(9, 16, 24), Topbar = Color3.fromRGB(11, 18, 28),
    Element = Color3.fromRGB(15, 25, 38), ElementHover = Color3.fromRGB(20, 33, 50),
    AccentA = Color3.fromRGB(160, 220, 255), AccentB = Color3.fromRGB(210, 240, 255),
    ToggleOff = Color3.fromRGB(18, 30, 46), Stroke = Color3.fromRGB(24, 38, 58),
    Text = Color3.fromRGB(235, 248, 255), SubText = Color3.fromRGB(148, 185, 215),
    Info = Color3.fromRGB(160, 220, 255), Success = Color3.fromRGB(100, 220, 200)
})
-- ดำสนิท สีเขียวนีออนเรืองแสง
Library.Themes.Neon = resolveTheme({
    Background = Color3.fromRGB(5, 8, 5), Sidebar = Color3.fromRGB(7, 11, 7), Topbar = Color3.fromRGB(8, 13, 8),
    Element = Color3.fromRGB(10, 18, 10), ElementHover = Color3.fromRGB(14, 25, 14),
    AccentA = Color3.fromRGB(57, 255, 20), AccentB = Color3.fromRGB(120, 255, 80),
    ToggleOff = Color3.fromRGB(13, 22, 13), Stroke = Color3.fromRGB(18, 32, 18),
    Text = Color3.fromRGB(240, 255, 235), SubText = Color3.fromRGB(130, 200, 130),
    Success = Color3.fromRGB(57, 255, 20), Info = Color3.fromRGB(80, 240, 160), Danger = Color3.fromRGB(255, 80, 80)
})
-- ม่วงลึก องุ่น
Library.Themes.Grape = resolveTheme({
    Background = Color3.fromRGB(12, 8, 18), Sidebar = Color3.fromRGB(16, 10, 24), Topbar = Color3.fromRGB(19, 12, 28),
    Element = Color3.fromRGB(26, 16, 38), ElementHover = Color3.fromRGB(34, 22, 50),
    AccentA = Color3.fromRGB(180, 100, 255), AccentB = Color3.fromRGB(220, 160, 255),
    ToggleOff = Color3.fromRGB(34, 22, 50), Stroke = Color3.fromRGB(44, 28, 64),
    Text = Color3.fromRGB(248, 240, 255), SubText = Color3.fromRGB(168, 148, 200),
    Info = Color3.fromRGB(180, 100, 255), Success = Color3.fromRGB(140, 200, 180)
})
-- น้ำตาลทองแดง ดิบ
Library.Themes.Copper = resolveTheme({
    Background = Color3.fromRGB(14, 9, 6), Sidebar = Color3.fromRGB(18, 12, 8), Topbar = Color3.fromRGB(22, 14, 9),
    Element = Color3.fromRGB(30, 19, 12), ElementHover = Color3.fromRGB(40, 25, 16),
    AccentA = Color3.fromRGB(210, 120, 60), AccentB = Color3.fromRGB(240, 175, 100),
    ToggleOff = Color3.fromRGB(38, 24, 15), Stroke = Color3.fromRGB(48, 30, 18),
    Text = Color3.fromRGB(255, 248, 240), SubText = Color3.fromRGB(185, 155, 125),
    Warning = Color3.fromRGB(240, 175, 100), Danger = Color3.fromRGB(220, 80, 60)
})
-- ชมพูทองกุหลาบ อบอุ่น
Library.Themes.RoseGold = resolveTheme({
    Background = Color3.fromRGB(16, 10, 12), Sidebar = Color3.fromRGB(20, 13, 15), Topbar = Color3.fromRGB(24, 15, 18),
    Element = Color3.fromRGB(32, 19, 23), ElementHover = Color3.fromRGB(42, 25, 30),
    AccentA = Color3.fromRGB(230, 140, 155), AccentB = Color3.fromRGB(255, 185, 190),
    ToggleOff = Color3.fromRGB(44, 26, 32), Stroke = Color3.fromRGB(54, 32, 40),
    Text = Color3.fromRGB(255, 245, 248), SubText = Color3.fromRGB(190, 155, 165),
    Success = Color3.fromRGB(200, 200, 160), Info = Color3.fromRGB(190, 160, 220)
})
-- ดำสุดขั้ว เขียวแมทริกซ์
Library.Themes.Matrix = resolveTheme({
    Background = Color3.fromRGB(2, 6, 2), Sidebar = Color3.fromRGB(3, 8, 3), Topbar = Color3.fromRGB(4, 10, 4),
    Element = Color3.fromRGB(6, 16, 6), ElementHover = Color3.fromRGB(9, 23, 9),
    AccentA = Color3.fromRGB(0, 200, 50), AccentB = Color3.fromRGB(0, 255, 80),
    ToggleOff = Color3.fromRGB(8, 20, 8), Stroke = Color3.fromRGB(12, 30, 12),
    Text = Color3.fromRGB(210, 255, 210), SubText = Color3.fromRGB(100, 180, 100),
    Success = Color3.fromRGB(0, 220, 60), Info = Color3.fromRGB(0, 200, 150), Danger = Color3.fromRGB(200, 50, 50)
})
-- น้ำตาลอบอุ่น คาราเมล กาแฟ
Library.Themes.Caramel = resolveTheme({
    Background = Color3.fromRGB(16, 11, 6), Sidebar = Color3.fromRGB(20, 14, 8), Topbar = Color3.fromRGB(24, 17, 10),
    Element = Color3.fromRGB(32, 23, 13), ElementHover = Color3.fromRGB(42, 30, 17),
    AccentA = Color3.fromRGB(200, 148, 80), AccentB = Color3.fromRGB(230, 190, 120),
    ToggleOff = Color3.fromRGB(40, 28, 16), Stroke = Color3.fromRGB(50, 35, 20),
    Text = Color3.fromRGB(255, 250, 238), SubText = Color3.fromRGB(188, 162, 128),
    Warning = Color3.fromRGB(230, 190, 120), Success = Color3.fromRGB(150, 200, 130)
})


-- ============ ธีมเพิ่มใหม่ v7 (สไตล์ WindUI / ธีมยอดนิยม) ============
local function T(bg, side, top, el, hov, txt, sub, a, b, off, str, extra)
    local o = {Background = bg, Sidebar = side, Topbar = top, Element = el, ElementHover = hov, Text = txt, SubText = sub,
        AccentA = a, AccentB = b, ToggleOff = off, Stroke = str}
    if extra then for k, v in pairs(extra) do o[k] = v end end
    return o
end
local RGB = Color3.fromRGB
Library.Themes.Indigo = resolveTheme(T(RGB(9,9,20), RGB(12,12,26), RGB(14,14,30), RGB(22,22,44), RGB(31,31,60), RGB(240,240,255), RGB(150,152,196), RGB(99,102,241), RGB(129,140,248), RGB(36,36,68), RGB(44,44,80)))
Library.Themes.Sky = resolveTheme(T(RGB(7,15,24), RGB(9,19,30), RGB(11,23,36), RGB(15,32,48), RGB(21,44,66), RGB(240,249,255), RGB(140,172,196), RGB(56,189,248), RGB(125,211,252), RGB(22,44,64), RGB(28,54,78)))
Library.Themes.Violet = resolveTheme(T(RGB(13,9,22), RGB(17,12,29), RGB(20,14,34), RGB(29,20,48), RGB(40,28,66), RGB(247,242,255), RGB(163,148,200), RGB(139,92,246), RGB(196,181,253), RGB(40,28,66), RGB(52,36,84)))
Library.Themes.Amber = resolveTheme(T(RGB(17,12,5), RGB(22,16,7), RGB(26,19,8), RGB(37,27,11), RGB(50,37,15), RGB(255,251,235), RGB(190,168,120), RGB(245,158,11), RGB(252,211,77), RGB(50,37,15), RGB(64,47,18)))
Library.Themes.Emerald = resolveTheme(T(RGB(6,15,12), RGB(8,20,16), RGB(10,24,19), RGB(14,33,27), RGB(20,46,38), RGB(236,253,245), RGB(130,178,158), RGB(16,185,129), RGB(110,231,183), RGB(20,44,36), RGB(26,56,46)))
Library.Themes.Rose = resolveTheme(T(RGB(18,8,12), RGB(23,10,15), RGB(27,12,18), RGB(38,17,25), RGB(52,24,34), RGB(255,241,245), RGB(196,150,164), RGB(244,63,94), RGB(251,113,133), RGB(52,24,34), RGB(66,30,42)))
Library.Themes.Mocha = resolveTheme(T(RGB(30,30,46), RGB(24,24,37), RGB(17,17,27), RGB(49,50,68), RGB(69,71,90), RGB(205,214,244), RGB(166,173,200), RGB(203,166,247), RGB(137,180,250), RGB(69,71,90), RGB(88,91,112),
    {Success = RGB(166,227,161), Danger = RGB(243,139,168), Warning = RGB(249,226,175), Info = RGB(137,220,235)}))
Library.Themes.Dracula = resolveTheme(T(RGB(40,42,54), RGB(33,34,44), RGB(30,31,40), RGB(56,58,76), RGB(68,71,90), RGB(248,248,242), RGB(160,165,196), RGB(189,147,249), RGB(255,121,198), RGB(68,71,90), RGB(98,114,164),
    {Success = RGB(80,250,123), Danger = RGB(255,85,85), Warning = RGB(241,250,140), Info = RGB(139,233,253)}))
Library.Themes.Nord = resolveTheme(T(RGB(46,52,64), RGB(41,46,57), RGB(38,43,53), RGB(59,66,82), RGB(67,76,94), RGB(236,239,244), RGB(168,178,196), RGB(136,192,208), RGB(129,161,193), RGB(67,76,94), RGB(76,86,106),
    {Success = RGB(163,190,140), Danger = RGB(191,97,106), Warning = RGB(235,203,139), Info = RGB(94,129,172)}))
Library.Themes.TokyoNight = resolveTheme(T(RGB(26,27,38), RGB(22,22,30), RGB(20,21,28), RGB(36,40,59), RGB(47,53,77), RGB(192,202,245), RGB(130,139,184), RGB(122,162,247), RGB(187,154,247), RGB(47,53,77), RGB(59,66,97),
    {Success = RGB(158,206,106), Danger = RGB(247,118,142), Warning = RGB(224,175,104), Info = RGB(125,207,255)}))
Library.Themes.Cyberpunk = resolveTheme(T(RGB(12,6,20), RGB(16,8,26), RGB(20,10,32), RGB(30,14,46), RGB(42,20,64), RGB(255,240,250), RGB(190,150,200), RGB(255,0,153), RGB(0,240,255), RGB(40,20,60), RGB(60,25,88),
    {Success = RGB(0,255,170), Danger = RGB(255,60,90), Warning = RGB(255,230,0), Info = RGB(0,240,255)}))
Library.Themes.Monokai = resolveTheme(T(RGB(39,40,34), RGB(33,34,29), RGB(29,30,26), RGB(55,56,48), RGB(70,71,62), RGB(248,248,242), RGB(166,165,150), RGB(166,226,46), RGB(102,217,239), RGB(70,71,62), RGB(73,72,62),
    {Danger = RGB(249,38,114), Warning = RGB(230,219,116), Info = RGB(102,217,239)}))
Library.Themes.Obsidian = resolveTheme(T(RGB(0,0,0), RGB(5,5,6), RGB(8,8,10), RGB(14,14,17), RGB(22,22,27), RGB(250,250,252), RGB(140,140,150), RGB(235,235,245), RGB(160,160,180), RGB(24,24,30), RGB(34,34,42)))
Library.Themes.Lavender = resolveTheme(T(RGB(245,243,255), RGB(255,255,255), RGB(255,255,255), RGB(255,255,255), RGB(243,240,255), RGB(30,27,46), RGB(110,105,140), RGB(139,92,246), RGB(217,70,239), RGB(221,217,240), RGB(226,222,245),
    {Success = RGB(22,163,106), Danger = RGB(224,54,54), Warning = RGB(217,130,0), Info = RGB(37,108,224)}))
Library.Themes.Mint = resolveTheme(T(RGB(240,251,247), RGB(255,255,255), RGB(255,255,255), RGB(255,255,255), RGB(238,250,245), RGB(16,42,34), RGB(90,128,114), RGB(16,185,129), RGB(45,212,191), RGB(208,232,223), RGB(216,238,230),
    {Success = RGB(22,163,106), Danger = RGB(224,54,54), Warning = RGB(217,130,0), Info = RGB(37,108,224)}))
Library.Themes.Peach = resolveTheme(T(RGB(255,247,242), RGB(255,255,255), RGB(255,255,255), RGB(255,255,255), RGB(255,243,236), RGB(52,28,18), RGB(140,102,86), RGB(251,113,80), RGB(251,191,36), RGB(240,220,210), RGB(246,228,219),
    {Success = RGB(22,163,106), Danger = RGB(224,54,54), Warning = RGB(217,130,0), Info = RGB(37,108,224)}))

function Library:AddTheme(name, overrides)
    if type(name) ~= "string" or name == "" then return end
    Library.Themes[name] = resolveTheme(overrides)
end


-- ============ v7: LOCALIZATION (ข้อความ "loc:KEY" แปลตามภาษา สลับสดได้) ============
Library.Localization = {Enabled = true, Language = "en", DefaultLanguage = "en", Translations = {}}
Library.LanguageChanged = Instance.new("BindableEvent")
Library._locBindings = {}   -- {alive = function() -> bool, apply = function()}

function Library:SetLocalization(cfg)
    cfg = type(cfg) == "table" and cfg or {}
    local L = Library.Localization
    if cfg.Enabled ~= nil then L.Enabled = cfg.Enabled end
    if cfg.DefaultLanguage then
        L.DefaultLanguage = cfg.DefaultLanguage
        if not L._userSet then L.Language = cfg.DefaultLanguage end
    end
    if type(cfg.Translations) == "table" then
        for lang, map in pairs(cfg.Translations) do
            L.Translations[lang] = L.Translations[lang] or {}
            for k, v in pairs(map) do L.Translations[lang][k] = v end
        end
    end
    return L
end
function Library:AddTranslations(lang, map) return Library:SetLocalization({Translations = {[lang] = map}}) end
function Library:GetLanguage() return Library.Localization.Language end
function Library:GetLanguages()
    local list = {}
    for lang in pairs(Library.Localization.Translations) do table.insert(list, lang) end
    table.sort(list)
    return list
end

-- "loc:KEY" → ข้อความตามภาษาปัจจุบัน (ไม่เจอ key → คืนชื่อ key)
function Library:Translate(text)
    if type(text) ~= "string" then return text end
    local key = string.match(text, "^loc:(.+)$")
    if not key then return text end
    local L = Library.Localization
    if not L.Enabled then return key end
    local pack = L.Translations[L.Language]
    local v = pack and pack[key]
    if v == nil then
        local def = L.Translations[L.DefaultLanguage]
        v = def and def[key]
    end
    if v == nil then return key end
    return v
end

function Library:IsLocalizedKey(text)
    return type(text) == "string" and string.match(text, "^loc:(.+)$") ~= nil
end

function Library:BindLocalized(aliveFn, applyFn)
    table.insert(Library._locBindings, {alive = aliveFn, apply = applyFn})
end

function Library:SetLanguage(lang)
    local L = Library.Localization
    L._userSet = true
    L.Language = lang
    for i = #Library._locBindings, 1, -1 do
        local b = Library._locBindings[i]
        local okAlive, alive = pcall(b.alive)
        if not okAlive or not alive then
            table.remove(Library._locBindings, i)
        else
            pcall(b.apply)
        end
    end
    Library.LanguageChanged:Fire(lang)
end

-- ============ v7: FONT (สลับฟอนต์ทั้ง UI สด ๆ) ============
Library.FontPresets = {
    BuilderSans = "rbxasset://fonts/families/BuilderSans.json",
    Gotham = "rbxasset://fonts/families/GothamSSm.json",
    Montserrat = "rbxasset://fonts/families/Montserrat.json",
    Roboto = "rbxasset://fonts/families/Roboto.json",
    RobotoMono = "rbxasset://fonts/families/RobotoMono.json",
    Ubuntu = "rbxasset://fonts/families/Ubuntu.json",
    Nunito = "rbxasset://fonts/families/Nunito.json",
    SourceSans = "rbxasset://fonts/families/SourceSansPro.json",
    Oswald = "rbxasset://fonts/families/Oswald.json",
    Arimo = "rbxasset://fonts/families/Arimo.json",
    JosefinSans = "rbxasset://fonts/families/JosefinSans.json",
    TitilliumWeb = "rbxasset://fonts/families/TitilliumWeb.json",
}
Library.CurrentFont = "BuilderSans"
Library._Guis = {}   -- ScreenGui ทั้งหมดที่ Library สร้าง (ใช้กับ SetFont)

function Library:SetFont(family)
    if type(family) == "number" then family = "rbxassetid://" .. tostring(math.floor(family)) end
    if type(family) ~= "string" or family == "" then return false end
    local label = family
    family = Library.FontPresets[family] or family
    BUILDER_FAMILY = family
    Library.CurrentFont = label
    for i = #Library._Guis, 1, -1 do
        local gui = Library._Guis[i]
        if not gui or not gui.Parent then
            table.remove(Library._Guis, i)
        else
            for _, inst in ipairs(gui:GetDescendants()) do
                if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
                    pcall(function()
                        local old = inst.FontFace
                        inst.FontFace = Font.new(family, old.Weight, old.Style)
                    end)
                end
            end
        end
    end
    return true
end

-- ============ v7: CODE HIGHLIGHT (Lua → RichText) ============
local LUA_KEYWORDS = {}
for _, w in ipairs({"and", "break", "do", "else", "elseif", "end", "false", "for", "function", "if", "in", "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while", "continue"}) do LUA_KEYWORDS[w] = true end
local LUA_BUILTINS = {}
for _, w in ipairs({"game", "workspace", "script", "print", "warn", "error", "pairs", "ipairs", "pcall", "xpcall", "type", "typeof", "tostring", "tonumber", "require", "select", "next", "setmetatable", "getmetatable", "task", "math", "string", "table", "os", "coroutine", "Instance", "Vector3", "Vector2", "CFrame", "Color3", "UDim2", "Enum", "loadstring", "wait", "spawn", "delay", "tick", "Random", "Drawing", "getgenv", "Library"}) do LUA_BUILTINS[w] = true end

local function xmlEscape(text)
    text = string.gsub(text, "&", "&amp;")
    text = string.gsub(text, "<", "&lt;")
    text = string.gsub(text, ">", "&gt;")
    text = string.gsub(text, '"', "&quot;")
    text = string.gsub(text, "'", "&apos;")
    return text
end

local function highlightLua(code)
    local COL = {kw = "#c678dd", str = "#98c379", num = "#d19a66", com = "#5c6370", fn = "#61afef", bi = "#e5c07b"}
    local out, plain = {}, {}
    local function flush()
        if #plain > 0 then
            out[#out + 1] = xmlEscape(table.concat(plain))
            plain = {}
        end
    end
    local function push(kind, text)
        flush()
        out[#out + 1] = '<font color="' .. COL[kind] .. '">' .. xmlEscape(text) .. '</font>'
    end
    local i, n = 1, #code
    while i <= n do
        local ch = string.sub(code, i, i)
        if string.sub(code, i, i + 1) == "--" then
            local lvl = string.match(code, "^%-%-%[(=*)%[", i)
            if lvl then
                local close = "]" .. lvl .. "]"
                local e = string.find(code, close, i, true)
                local stop = e and (e + #close - 1) or n
                push("com", string.sub(code, i, stop))
                i = stop + 1
            else
                local e = string.find(code, "\n", i, true) or (n + 1)
                push("com", string.sub(code, i, e - 1))
                i = e
            end
        elseif ch == '"' or ch == "'" then
            local j = i + 1
            while j <= n do
                local cj = string.sub(code, j, j)
                if cj == "\\" then j = j + 2
                elseif cj == ch or cj == "\n" then break
                else j = j + 1 end
            end
            push("str", string.sub(code, i, math.min(j, n)))
            i = j + 1
        elseif string.match(code, "^%[=*%[", i) then
            local lvl = string.match(code, "^%[(=*)%[", i)
            local close = "]" .. lvl .. "]"
            local e = string.find(code, close, i, true)
            local stop = e and (e + #close - 1) or n
            push("str", string.sub(code, i, stop))
            i = stop + 1
        elseif string.match(ch, "%d") then
            local num = string.match(code, "^0[xX]%x+", i)
            if not num then
                num = string.match(code, "^%d+%.?%d*", i)
                local ex = string.match(code, "^[eE][%+%-]?%d+", i + #num)
                if ex then num = num .. ex end
            end
            push("num", num)
            i = i + #num
        elseif string.match(ch, "[%a_]") then
            local word = string.match(code, "^[%w_]+", i)
            local nextCh = string.match(code, "^%s*(.)", i + #word)
            if LUA_KEYWORDS[word] then push("kw", word)
            elseif LUA_BUILTINS[word] then push("bi", word)
            elseif nextCh == "(" then push("fn", word)
            else plain[#plain + 1] = word end
            i = i + #word
        else
            plain[#plain + 1] = ch
            i = i + 1
        end
    end
    flush()
    return table.concat(out)
end

local function copyToClipboard(text)
    local fn = (type(setclipboard) == "function" and setclipboard) or (type(toclipboard) == "function" and toclipboard) or (type(set_clipboard) == "function" and set_clipboard)
    if not fn then return false end
    return (pcall(fn, text))
end

-- ============ CONFIG SAVE/LOAD ============
local function hasFileSupport()
    return type(writefile) == "function" and type(readfile) == "function"
       and type(isfile) == "function" and type(isfolder) == "function" and type(makefolder) == "function"
end

local function ensureConfigFolder()
    if not isfolder(Library.ConfigFolder) then
        makefolder(Library.ConfigFolder)
    end
end

local function safeNotify(opts)
    if Library.Notify then
        pcall(function() Library:Notify(opts) end)
    end
end

local function safeCallback(fn, ...)
    if type(fn) ~= "function" then return end
    local args = table.pack(...)
    local ok, errInfo = xpcall(function()
        return fn(table.unpack(args, 1, args.n))
    end, function(e)
        return {message = e, traceback = debug.traceback(nil, 2)}
    end)
    if not ok then
        warn("[" .. Library.Version .. "] Callback error: " .. tostring(errInfo.message))
        Library:LogError("Callback", errInfo.message, errInfo.traceback)
    end
end

local function configPath(name)
    name = tostring(name or "default"):gsub("[^%w_%- ]", "_")
    return Library.ConfigFolder .. "/" .. name .. ".json"
end

function Library:SaveConfig(name)
    if not hasFileSupport() then
        safeNotify({Title = "Config", Content = "Executor นี้ไม่รองรับการเขียนไฟล์ (writefile)", Type = "error"})
        return false
    end
    local ok, encoded = pcall(function() return HttpService:JSONEncode(Library.Flags) end)
    if not ok then
        safeNotify({Title = "Config", Content = "แปลงค่า Config เป็น JSON ไม่สำเร็จ", Type = "error"})
        Library:LogError("SaveConfig:Encode", encoded)
        return false
    end
    ensureConfigFolder()
    local wok, werr = pcall(writefile, configPath(name), encoded)
    if not wok then
        safeNotify({Title = "Config", Content = "บันทึกไฟล์ไม่สำเร็จ", Type = "error"})
        Library:LogError("SaveConfig:Write", werr)
        return false
    end
    safeNotify({Title = "Config", Content = "บันทึก \"" .. tostring(name or "default") .. "\" แล้ว", Type = "success", Duration = 2})
    return true
end

function Library:LoadConfig(name)
    if not hasFileSupport() then
        safeNotify({Title = "Config", Content = "Executor นี้ไม่รองรับการอ่านไฟล์ (readfile)", Type = "error"})
        return false
    end
    local path = configPath(name)
    if not isfile(path) then
        safeNotify({Title = "Config", Content = "ไม่พบไฟล์ config \"" .. tostring(name or "default") .. "\"", Type = "warning", Duration = 2})
        return false
    end
    local rok, raw = pcall(readfile, path)
    if not rok then
        safeNotify({Title = "Config", Content = "อ่านไฟล์ config ไม่สำเร็จ", Type = "error"})
        Library:LogError("LoadConfig:Read", raw)
        return false
    end
    local dok, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not dok or type(data) ~= "table" then
        safeNotify({Title = "Config", Content = "ไฟล์ config เสียหายหรือไม่ใช่ JSON", Type = "error"})
        Library:LogError("LoadConfig:Decode", dok and "ไม่ใช่ table" or data)
        return false
    end
    for flag, value in pairs(data) do
        local elem = Library.FlagElements[flag]
        if elem and elem.Set then
            local sok, serr = pcall(function() elem:Set(value) end)
            if not sok then Library:LogError("LoadConfig:ApplyFlag:" .. tostring(flag), serr) end
        else
            Library.Flags[flag] = value
        end
    end
    safeNotify({Title = "Config", Content = "โหลด \"" .. tostring(name or "default") .. "\" แล้ว", Type = "success", Duration = 2})
    return true
end

function Library:ListConfigs()
    local list = {}
    if not hasFileSupport() or type(listfiles) ~= "function" then return list end
    if not isfolder(Library.ConfigFolder) then return list end
    for _, filePath in ipairs(listfiles(Library.ConfigFolder)) do
        local fname = filePath:match("([^/\\]+)%.json$")
        if fname then table.insert(list, fname) end
    end
    table.sort(list)
    return list
end

function Library:DeleteConfig(name)
    if not hasFileSupport() or type(delfile) ~= "function" then return false end
    local path = configPath(name)
    if isfile(path) then
        pcall(delfile, path)
        safeNotify({Title = "Config", Content = "ลบ \"" .. tostring(name or "default") .. "\" แล้ว", Type = "warning", Duration = 2})
        return true
    end
    return false
end

local Theme = resolveTheme(nil)
local NOTIFY_ICON = {success = Library.Icons.check, error = Library.Icons.close, warning = Library.Icons.warning, info = Library.Icons.info}

-- ============ HELPERS ============
local function getUiParent()
    if gethui then return gethui() end
    if syn and syn.protect_gui then
        -- ตั้งชื่อ + เช็คของเก่าก่อนสร้างใหม่ ไม่งั้นทุกครั้งที่รันสคริปต์ซ้ำ (โหลดใหม่/inject ใหม่)
        -- จะได้ protected ScreenGui เปล่าๆ ค้างใน CoreGui เพิ่มขึ้นเรื่อยๆ ไม่มีวันถูกเก็บกวาด
        local old = CoreGui:FindFirstChild("SpectreUI_Protected")
        if old then old:Destroy() end
        local protected = Instance.new("ScreenGui")
        protected.Name = "SpectreUI_Protected"
        protected.Parent = CoreGui
        syn.protect_gui(protected)
        return protected
    end
    return CoreGui
end

local function corner(inst, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = inst
    return c
end

local function normalizeAssetId(id)
    if typeof(id) == "number" then
        return "rbxassetid://" .. tostring(math.floor(id))
    end
    if typeof(id) == "string" then
        local trimmed = id:match("^%s*(.-)%s*$") or id
        if trimmed == "" then return "" end
        if trimmed:match("^rbxassetid://") or trimmed:match("^rbxthumb://") then
            return trimmed
        end
        if trimmed:match("^%d+$") then
            return "rbxassetid://" .. trimmed
        end
        local digits = trimmed:match("(%d+)")
        if digits then
            return "rbxassetid://" .. digits
        end
        return trimmed
    end
    return ""
end

local function applyThemeColor(inst, key, prop)
    prop = prop or "BackgroundColor3"
    inst:SetAttribute("ThemeKey", key)
    inst:SetAttribute("ThemeProp", prop)
    -- เก็บทุก binding ของ instance เดียวกัน (เดิมเก็บแค่คีย์สุดท้าย → ตอนสลับธีม prop อื่นค้างสีเก่า)
    local binds = inst:GetAttribute("ThemeBinds")
    local entry = prop .. "=" .. key
    if binds == nil or binds == "" then
        binds = entry
    else
        local parts, found = {}, false
        for p in string.gmatch(binds, "[^;]+") do
            if string.sub(p, 1, #prop + 1) == prop .. "=" then
                parts[#parts + 1] = entry
                found = true
            else
                parts[#parts + 1] = p
            end
        end
        if not found then parts[#parts + 1] = entry end
        binds = table.concat(parts, ";")
    end
    inst:SetAttribute("ThemeBinds", binds)
    if Theme[key] then inst[prop] = Theme[key] end
end

local function stroke(inst, colorKey, thickness)
    local s = Instance.new("UIStroke")
    applyThemeColor(s, colorKey or "Stroke", "Color")
    s.Thickness = thickness or 1
    s.Transparency = 0.65
    -- Contextual (ค่าเริ่มต้น) จะวาดเป็น "ขอบตัวอักษร" เมื่อ parent เป็น TextButton/TextBox/TextLabel
    -- ทำให้ glow/ขอบรอบปุ่มไม่เคยโผล่ → บังคับ Border เสมอ
    pcall(function() s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border end)
    s.Parent = inst
    return s
end

local function accentGradient(inst, rotation)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(Theme.AccentA, Theme.AccentB)
    g.Rotation = rotation or 100
    g:SetAttribute("IsAccent", true)
    g.Parent = inst
    return g
end

local function applyHoverEffect(btn, defKey, hovKey)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TI.d015_Sine_Out, {BackgroundColor3 = Theme[hovKey]}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TI.d015_Sine_Out, {BackgroundColor3 = Theme[defKey]}):Play()
    end)
end

local function applyGlowOnHover(frame)
    local glow = stroke(frame, "AccentA", 1)
    glow.Transparency = 1
    frame.MouseEnter:Connect(function()
        TweenService:Create(glow, TI.d02_Sine_Out, {Transparency = 0.6}):Play()
    end)
    frame.MouseLeave:Connect(function()
        TweenService:Create(glow, TI.d02_Sine_Out, {Transparency = 1}):Play()
    end)
end

local function applyPressAnimation(btn, pressScale)
    pressScale = pressScale or 0.94
    local uiScale = btn:FindFirstChildOfClass("UIScale")
    if not uiScale then
        uiScale = Instance.new("UIScale")
        uiScale.Parent = btn
    end
    local function pressDown()
        TweenService:Create(uiScale, TI.d008_Quad_Out, {Scale = pressScale}):Play()
    end
    local function pressUp()
        TweenService:Create(uiScale, TI.d022_Back_Out, {Scale = 1}):Play()
    end
    btn.MouseButton1Down:Connect(pressDown)
    btn.MouseButton1Up:Connect(pressUp)
    btn.MouseLeave:Connect(pressUp)
    btn.TouchTap:Connect(function()
        pressDown()
        task.delay(0.08, pressUp)
    end)
end

-- ============ RIPPLE CLICK EFFECT (วงกลมกระเพื่อมออกจากจุดคลิก แบบ Material) ============
local function ripple(btn, colorKey)
    local holder = Instance.new("Frame")
    holder.Name = "__RippleHolder"
    holder.BackgroundTransparency = 1
    holder.Size = UDim2.new(1, 0, 1, 0)
    holder.ClipsDescendants = true
    holder.ZIndex = btn.ZIndex
    holder.Parent = btn
    local srcCorner = btn:FindFirstChildOfClass("UICorner")
    if srcCorner then
        local hc = Instance.new("UICorner")
        hc.CornerRadius = srcCorner.CornerRadius
        hc.Parent = holder
    end
    btn.MouseButton1Down:Connect(function(x, y)
        local absPos, absSize = btn.AbsolutePosition, btn.AbsoluteSize
        local relX, relY = x - absPos.X, y - absPos.Y
        local maxDim = math.max(absSize.X, absSize.Y) * 2.4
        local circle = Instance.new("Frame")
        circle.AnchorPoint = Vector2.new(0.5, 0.5)
        circle.Position = UDim2.new(0, relX, 0, relY)
        circle.Size = UDim2.new(0, 0, 0, 0)
        circle.BackgroundColor3 = Theme[colorKey or "AccentA"]
        circle.BackgroundTransparency = 0.5
        circle.BorderSizePixel = 0
        circle.ZIndex = holder.ZIndex
        circle.Parent = holder
        corner(circle, 999)
        local tw = TweenService:Create(circle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, maxDim, 0, maxDim),
            BackgroundTransparency = 1
        })
        tw:Play()
        tw.Completed:Connect(function() circle:Destroy() end)
    end)
end

-- ============ PULSE RING (แหวนกระเพื่อมออกจากขอบ element ใช้ตอน toggle เปิด/สถานะสำเร็จ) ============
local function pulseRing(inst, colorKey, radiusInst)
    local pulse = Instance.new("Frame")
    pulse.AnchorPoint = Vector2.new(0.5, 0.5)
    pulse.Position = UDim2.new(0.5, 0, 0.5, 0)
    pulse.Size = UDim2.new(1, 0, 1, 0)
    pulse.BackgroundTransparency = 0.25
    pulse.BackgroundColor3 = Theme[colorKey or "AccentA"]
    pulse.BorderSizePixel = 0
    pulse.ZIndex = math.max(inst.ZIndex - 1, 0)
    pulse.Parent = inst
    corner(pulse, radiusInst or 10)
    local tw = TweenService:Create(pulse, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = UDim2.new(1, 28, 1, 28),
        BackgroundTransparency = 1
    })
    tw:Play()
    tw.Completed:Connect(function() pulse:Destroy() end)
end

local function isPointOverGui(pos, guiObject)
    if not guiObject or not guiObject.Parent then return false end
    if guiObject:IsA("GuiObject") and not guiObject.Visible then return false end
    local topLeft = guiObject.AbsolutePosition
    local size = guiObject.AbsoluteSize
    return pos.X >= topLeft.X and pos.X <= topLeft.X + size.X
       and pos.Y >= topLeft.Y and pos.Y <= topLeft.Y + size.Y
end

-- ============ FLOATING POPUP POSITIONING (dropdown/color picker) ============
-- คำนวณตำแหน่งกล่อง popup ไม่ให้ล้นขอบจอ ทั้งแนวตั้ง (สลับเปิดขึ้น-ลง) และแนวนอน (เลื่อนเข้าขอบ)
-- คืนค่า posX, edgeY, openUp — edgeY คือ "ขอบที่ยึดตำแหน่งไว้" (ขอบบนถ้าเปิดลง, ขอบล่างถ้าเปิดขึ้น)
-- ใช้คู่กับ AnchorPoint = Vector2.new(0, openUp and 1 or 0) เพื่อให้กล่องขยายออกจากขอบที่ถูกต้อง
local function resolveFloatingPosition(anchorAbsPos, anchorAbsSize, popupW, popupH, gap)
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local margin = 8

    local spaceBelow = viewport.Y - (anchorAbsPos.Y + anchorAbsSize.Y + gap) - margin
    local spaceAbove = anchorAbsPos.Y - gap - margin
    local openUp = spaceBelow < popupH and spaceAbove > spaceBelow

    local edgeY
    if openUp then
        edgeY = anchorAbsPos.Y - gap
        if edgeY - popupH < margin then edgeY = popupH + margin end
    else
        edgeY = anchorAbsPos.Y + anchorAbsSize.Y + gap
        if edgeY + popupH > viewport.Y - margin then
            edgeY = math.max(margin, viewport.Y - margin - popupH)
        end
    end

    local posX = anchorAbsPos.X
    if posX + popupW > viewport.X - margin then
        posX = viewport.X - margin - popupW
    end
    if posX < margin then posX = margin end

    return posX, edgeY, openUp
end

local function newElement(root, getter, setter, destroyer, flag)
    local elem
    elem = {
        Instance = root,
        Get = getter or function() return nil end,
        Set = setter or function() end,
        SetVisible = function(_, visible) root.Visible = visible end,
        Destroy = function()
            if elem._depConn then elem._depConn:Disconnect() end
            if destroyer then destroyer() else root:Destroy() end
        end,
    }
    function elem:LinkVisibility(depFlag, expectedValue, opts)
        opts = type(opts) == "table" and opts or {}
        if expectedValue == nil then expectedValue = true end
        local invert = opts.Invert == true
        local function apply(value)
            local match = (value == expectedValue)
            if invert then match = not match end
            root.Visible = match
        end
        apply(Library.Flags[depFlag])
        if elem._depConn then elem._depConn:Disconnect() end
        elem._depConn = Library.FlagChanged.Event:Connect(function(changedFlag, value)
            if changedFlag == depFlag then apply(value) end
        end)
        return elem
    end
    -- ============ v7: Element API (เทียบเท่า WindUI) ============
    function elem:Show() root.Visible = true return elem end
    function elem:Hide() root.Visible = false return elem end
    function elem:IsVisible() return root.Visible end
    function elem:GetInstance() return root end
    function elem:SetTooltip(text)
        if text and Library.AttachTooltip then Library:AttachTooltip(root, text) end
        return elem
    end

    function elem:IsLocked() return elem._lockOverlay ~= nil end
    function elem:Lock(message)
        local ov = elem._lockOverlay
        if not ov then
            ov = Instance.new("TextButton")
            ov.Name = "__Lock"
            ov.AutoButtonColor = false
            ov.Text = ""
            ov.Size = UDim2.new(1, 0, 1, 0)
            applyThemeColor(ov, "Background")
            ov.BackgroundTransparency = 0.38
            ov.BorderSizePixel = 0
            ov.ZIndex = 100
            local rc = root:FindFirstChildOfClass("UICorner")
            local oc = Instance.new("UICorner")
            oc.CornerRadius = rc and rc.CornerRadius or UDim.new(0, 9)
            oc.Parent = ov
            local lbl = Instance.new("TextLabel")
            lbl.BackgroundTransparency = 1
            lbl.Size = UDim2.new(1, -16, 1, 0)
            lbl.Position = UDim2.new(0, 8, 0, 0)
            lbl.FontFace = UI_Font("SemiBold")
            lbl.TextSize = 12.5
            lbl.TextTruncate = Enum.TextTruncate.AtEnd
            applyThemeColor(lbl, "SubText", "TextColor3")
            lbl.ZIndex = 101
            lbl.Parent = ov
            ov.Parent = root
            elem._lockOverlay, elem._lockLabel = ov, lbl
        end
        elem._lockLabel.Text = message and ("🔒  " .. tostring(message)) or "🔒"
        return elem
    end
    function elem:Unlock()
        if elem._lockOverlay then
            elem._lockOverlay:Destroy()
            elem._lockOverlay, elem._lockLabel = nil, nil
        end
        return elem
    end

    -- เลื่อนหน้าไปหา element + วูบขอบสีธีม ใช้ชี้ให้ผู้ใช้เห็นว่า "อยู่ตรงนี้"
    function elem:Highlight(duration)
        duration = tonumber(duration) or 1.4
        pcall(function()
            local sf = root:FindFirstAncestorOfClass("ScrollingFrame")
            if sf then
                local y = root.AbsolutePosition.Y - sf.AbsolutePosition.Y + sf.CanvasPosition.Y
                sf.CanvasPosition = Vector2.new(0, math.max(0, y - 16))
            end
        end)
        local hs = Instance.new("UIStroke")
        hs.Color = Theme.AccentA
        hs.Thickness = 2
        hs.Transparency = 0
        pcall(function() hs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border end)
        hs.Parent = root
        local tw = TweenService:Create(hs, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Transparency = 1})
        tw:Play()
        tw.Completed:Connect(function() hs:Destroy() end)
        return elem
    end

    local function findTitleLabel()
        if root:IsA("TextLabel") then return root end
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("TextLabel") and d.Name ~= "__DescLabel" and d.Text ~= "" and not (elem._lockOverlay and d:IsDescendantOf(elem._lockOverlay)) then
                return d
            end
        end
        return nil
    end

    function elem:SetTitle(text)
        text = tostring(text)
        if elem._setTitle then elem._setTitle(text) return elem end
        local cfg = elem._cfg
        local old = cfg and cfg.Text
        if cfg then cfg.Text = text; cfg.Title = text end
        if root:IsA("TextBox") then root.PlaceholderText = text return elem end
        local lbl = findTitleLabel()
        if lbl then
            local cur = lbl.Text
            if old and old ~= "" and cur == old then
                lbl.Text = text
            elseif old and old ~= "" and string.sub(cur, 1, #old + 2) == old .. ": " then
                lbl.Text = text .. string.sub(cur, #old + 1)   -- แบบ "ชื่อ: ค่า" (Slider/Dropdown/Keybind)
            elseif not old then
                lbl.Text = text
            end
        end
        return elem
    end

    function elem:SetDesc(text)
        text = tostring(text)
        if elem._setDesc then elem._setDesc(text)
        elseif elem._descHook then elem._descHook(text) end
        return elem
    end

    function elem:OnChanged(fn)
        if not flag or type(fn) ~= "function" then return nil end
        return Library.FlagChanged.Event:Connect(function(changedFlag, value)
            if changedFlag == flag then fn(value) end
        end)
    end

    if flag then Library.FlagElements[flag] = elem end
    return elem
end

