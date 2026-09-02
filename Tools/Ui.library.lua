--[[
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
Library.Version = "6.7.1"

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
end

local UserInputService = game:GetService("UserInputService")
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

function Library:AddTheme(name, overrides)
    if type(name) ~= "string" or name == "" then return end
    Library.Themes[name] = resolveTheme(overrides)
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
    local ok, err = pcall(fn, ...)
    if not ok then
        warn("[" .. Library.Version .. "] Callback error: " .. tostring(err))
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
        return false
    end
    ensureConfigFolder()
    local wok = pcall(writefile, configPath(name), encoded)
    if not wok then
        safeNotify({Title = "Config", Content = "บันทึกไฟล์ไม่สำเร็จ", Type = "error"})
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
        return false
    end
    local dok, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not dok or type(data) ~= "table" then
        safeNotify({Title = "Config", Content = "ไฟล์ config เสียหายหรือไม่ใช่ JSON", Type = "error"})
        return false
    end
    for flag, value in pairs(data) do
        local elem = Library.FlagElements[flag]
        if elem and elem.Set then
            pcall(function() elem:Set(value) end)
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
        local protected = Instance.new("ScreenGui")
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
    if Theme[key] then inst[prop] = Theme[key] end
end

local function stroke(inst, colorKey, thickness)
    local s = Instance.new("UIStroke")
    applyThemeColor(s, colorKey or "Stroke", "Color")
    s.Thickness = thickness or 1
    s.Transparency = 0.65
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
    if flag then Library.FlagElements[flag] = elem end
    return elem
end

-- ============ MAIN LIBRARY ============
function Library:CreateWindow(config)
    config = type(config) == "table" and config or {}
    local Window = setmetatable({}, Library)

    local oldGui = CoreGui:FindFirstChild("ProMobileUI")
    if oldGui then oldGui:Destroy() end
    local oldRestoreGui = CoreGui:FindFirstChild("RestoreGui")
    if oldRestoreGui then oldRestoreGui:Destroy() end
    local oldNotifyGui = CoreGui:FindFirstChild("NotifyGui")
    if oldNotifyGui then oldNotifyGui:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ProMobileUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.IgnoreGuiInset = true   -- ใช้จอจริงเต็มจอ ไม่ใช่พื้นที่ safe-area ที่ Roblox เว้นให้ topbar (กัน clamp ลากคำนวณผิดขนาด)
    local UiParent = getUiParent()
    ScreenGui.Parent = UiParent

    function Library:SetTheme(themeName)
        local newTheme = Library.Themes[themeName]
        if not newTheme then return end
        for k, v in pairs(newTheme) do Theme[k] = v end
        Library.CurrentTheme = themeName

        for _, inst in ipairs(ScreenGui:GetDescendants()) do
            local key = inst:GetAttribute("ThemeKey")
            if key and Theme[key] then
                local prop = inst:GetAttribute("ThemeProp") or "BackgroundColor3"
                inst[prop] = Theme[key]
            end
            if inst:IsA("UIGradient") and inst:GetAttribute("IsAccent") then
                inst.Color = ColorSequence.new(Theme.AccentA, Theme.AccentB)
            end
        end
    end

    -- ============ Notification layer ============
    local NotifyGui = Instance.new("ScreenGui")
    NotifyGui.Name = "NotifyGui"
    NotifyGui.ResetOnSpawn = false
    NotifyGui.IgnoreGuiInset = true
    NotifyGui.DisplayOrder = 998
    NotifyGui.Parent = UiParent

    local NotifyHolder = Instance.new("Frame")
    NotifyHolder.Name = "Notifications"
    NotifyHolder.AnchorPoint = Vector2.new(1, 0)
    NotifyHolder.Position = UDim2.new(1, -16, 0, 16)
    NotifyHolder.Size = UDim2.new(0, 312, 1, -32)
    NotifyHolder.BackgroundTransparency = 1
    NotifyHolder.Parent = NotifyGui
    local NotifyLayout = Instance.new("UIListLayout")
    NotifyLayout.Padding = UDim.new(0, 10)
    NotifyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    NotifyLayout.Parent = NotifyHolder

    -- ============ Notification queue (จำกัดจำนวนที่โชว์พร้อมกัน กันสแปม/ยิงรัว) ============
    local MAX_VISIBLE_NOTIFICATIONS = 4
    local activeNotifyCount = 0
    local notifyQueue = {} -- FIFO: เก็บ opts ที่รอคิวอยู่

    local spawnToast -- ประกาศล่วงหน้า เพราะ spawnToast เรียกตัวเองผ่าน queue ตอน dismiss เสร็จ

    local function tryDequeueNotify()
        if activeNotifyCount >= MAX_VISIBLE_NOTIFICATIONS then return end
        local nextOpts = table.remove(notifyQueue, 1)
        if nextOpts then
            spawnToast(nextOpts)
        end
    end

    function Library:Notify(opts)
        if type(opts) == "string" then opts = {Content = opts} end
        opts = type(opts) == "table" and opts or {}
        if activeNotifyCount >= MAX_VISIBLE_NOTIFICATIONS then
            table.insert(notifyQueue, opts)
            return
        end
        spawnToast(opts)
    end

    spawnToast = function(opts)
        activeNotifyCount += 1
        local title = opts.Title or "Notice"
        local content = opts.Content or ""
        local duration = math.max(opts.Duration or 3, 0.5)
        local ntype = opts.Type or "info"
        local COLOR_KEY = {success = "Success", error = "Danger", warning = "Warning", info = "Info"}
        local color = Theme[COLOR_KEY[ntype] or "Info"]

        -- เงานุ่มๆ ใต้การ์ด
        local Shadow = Instance.new("ImageLabel")
        Shadow.Name = "ToastShadow"
        Shadow.BackgroundTransparency = 1
        Shadow.Image = "rbxassetid://5028857084"
        Shadow.ImageColor3 = Color3.new(0, 0, 0)
        Shadow.ImageTransparency = 1
        Shadow.ScaleType = Enum.ScaleType.Slice
        Shadow.SliceCenter = Rect.new(24, 24, 276, 276)
        Shadow.ZIndex = 0
        Shadow.Parent = NotifyGui

        local Slot = Instance.new("Frame")
        Slot.Name = "ToastSlot"
        Slot.BackgroundTransparency = 1
        Slot.Size = UDim2.new(1, 0, 0, 0)
        Slot.ClipsDescendants = true
        Slot.ZIndex = 2
        Slot.Parent = NotifyHolder

        local Toast = Instance.new("Frame")
        applyThemeColor(Toast, "Element")
        Toast.Size = UDim2.new(1, 0, 0, 0)
        Toast.AutomaticSize = Enum.AutomaticSize.Y
        Toast.BackgroundTransparency = 1
        Toast.ClipsDescendants = true
        Toast.ZIndex = 2
        -- เพิ่ม Offset เริ่มต้นเพื่อทำ Slide-in Animation
        Toast.Position = UDim2.new(0, 30, 0, 0) 
        Toast.Parent = Slot
        corner(Toast, 18)
        local outline = stroke(Toast)
        outline.Thickness = 1
        outline.Transparency = 1

        -- ชั้นสีบางๆ ไล่เฉดตามประเภทแจ้งเตือน ให้การ์ดดูมีโทนสีแทนที่จะเทาแบนๆ
        local ColorTint = Instance.new("Frame")
        ColorTint.Name = "ColorTint"
        ColorTint.Size = UDim2.new(1, 0, 1, 0)
        ColorTint.BackgroundColor3 = color
        ColorTint.BorderSizePixel = 0
        ColorTint.ZIndex = 2
        ColorTint.BackgroundTransparency = 1
        ColorTint.Parent = Toast
        corner(ColorTint, 18)
        local tintGradient = Instance.new("UIGradient")
        tintGradient.Color = ColorSequence.new(color, color:Lerp(Theme.Element, 1))
        tintGradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.86),
            NumberSequenceKeypoint.new(0.6, 0.97),
            NumberSequenceKeypoint.new(1, 1),
        })
        tintGradient.Rotation = 100
        tintGradient.Parent = ColorTint

        -- เอฟเฟกต์ Glass Sheen บางๆ เพื่อให้การ์ดดูมีมิติ
        local Sheen = Instance.new("Frame")
        Sheen.Name = "Sheen"
        Sheen.Size = UDim2.new(1, 0, 1, 0)
        Sheen.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Sheen.BorderSizePixel = 0
        Sheen.ZIndex = 3
        Sheen.Active = false
        Sheen.Parent = Toast
        corner(Sheen, 18)
        local sheenGradient = Instance.new("UIGradient")
        sheenGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255))
        sheenGradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.95),
            NumberSequenceKeypoint.new(0.35, 1),
            NumberSequenceKeypoint.new(1, 1),
        })
        sheenGradient.Rotation = 100
        sheenGradient.Parent = Sheen

        local function syncShadow()
            if not Shadow.Parent or not Toast.Parent then return end
            Shadow.Position = UDim2.new(0, Toast.AbsolutePosition.X - 14, 0, Toast.AbsolutePosition.Y - 12)
            Shadow.Size = UDim2.new(0, Toast.AbsoluteSize.X + 28, 0, Toast.AbsoluteSize.Y + 26)
        end
        local shadowConns = {
            Toast:GetPropertyChangedSignal("AbsoluteSize"):Connect(syncShadow),
            Toast:GetPropertyChangedSignal("AbsolutePosition"):Connect(syncShadow),
        }
        syncShadow()

        -- แถบสีบอกประเภท ชิดซ้ายบน ปลายมนและไล่เฉดล่าง
        local AccentBar = Instance.new("Frame")
        AccentBar.AnchorPoint = Vector2.new(0, 0.5)
        AccentBar.Position = UDim2.new(0, 12, 0.5, 0)
        AccentBar.Size = UDim2.new(0, 4, 0, 0)
        AccentBar.BackgroundColor3 = color
        AccentBar.BackgroundTransparency = 1
        AccentBar.BorderSizePixel = 0
        AccentBar.ZIndex = 4
        AccentBar.Parent = Toast
        corner(AccentBar, 2)
        local accentFade = Instance.new("UIGradient")
        accentFade.Color = ColorSequence.new(color, color)
        accentFade.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 0.55),
        })
        accentFade.Rotation = 90
        accentFade.Parent = AccentBar

        -- วงกลมไอคอน (Badge) สีพาสเทลโทนนุ่มนวล
        local IconBadge = Instance.new("Frame")
        IconBadge.AnchorPoint = Vector2.new(0, 0)
        IconBadge.Size = UDim2.new(0, 34, 0, 34)
        IconBadge.Position = UDim2.new(0, 18, 0, 16)
        IconBadge.BackgroundColor3 = color:Lerp(Theme.Element, 0.7)
        IconBadge.BackgroundTransparency = 1
        IconBadge.ZIndex = 4
        IconBadge.Parent = Toast
        corner(IconBadge, 12)
        local badgeGradient = Instance.new("UIGradient")
        badgeGradient.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.12), color:Lerp(Theme.Element, 0.55))
        badgeGradient.Rotation = 90
        badgeGradient.Parent = IconBadge
        local badgeStroke = Instance.new("UIStroke")
        badgeStroke.Color = color
        badgeStroke.Transparency = 0.55
        badgeStroke.Thickness = 1
        badgeStroke.Parent = IconBadge

        local IconImg = Instance.new("ImageLabel")
        IconImg.AnchorPoint = Vector2.new(0.5, 0.5)
        IconImg.Position = UDim2.new(0.5, 0, 0.5, 0)
        IconImg.Size = UDim2.new(0, 17, 0, 17)
        IconImg.BackgroundTransparency = 1
        IconImg.Image = NOTIFY_ICON[ntype] or Library.Icons.info
        IconImg.ImageColor3 = color
        IconImg.ImageTransparency = 1
        IconImg.ScaleType = Enum.ScaleType.Fit
        IconImg.ZIndex = 5
        IconImg.Parent = IconBadge

        -- ข้อความ
        local TextHolder = Instance.new("Frame")
        TextHolder.BackgroundTransparency = 1
        TextHolder.Position = UDim2.new(0, 66, 0, 17)
        TextHolder.Size = UDim2.new(1, -104, 0, 0)
        TextHolder.AutomaticSize = Enum.AutomaticSize.Y
        TextHolder.ZIndex = 4
        TextHolder.Parent = Toast
        local Layout = Instance.new("UIListLayout")
        Layout.Padding = UDim.new(0, 5)
        Layout.Parent = TextHolder

        local TitleLbl = Instance.new("TextLabel")
        TitleLbl.BackgroundTransparency = 1
        TitleLbl.Size = UDim2.new(1, 0, 0, 16)
        TitleLbl.Font = Enum.Font.GothamBold
        TitleLbl.TextSize = 14.5
        applyThemeColor(TitleLbl, "Text", "TextColor3")
        TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
        TitleLbl.TextTransparency = 1
        TitleLbl.Text = title
        TitleLbl.ZIndex = 4
        TitleLbl.Parent = TextHolder

        local ContentLbl = Instance.new("TextLabel")
        ContentLbl.BackgroundTransparency = 1
        ContentLbl.Size = UDim2.new(1, 0, 0, 0)
        ContentLbl.AutomaticSize = Enum.AutomaticSize.Y
        ContentLbl.Font = Enum.Font.Gotham
        ContentLbl.TextSize = 12.5
        ContentLbl.LineHeight = 1.25
        applyThemeColor(ContentLbl, "SubText", "TextColor3")
        ContentLbl.TextXAlignment = Enum.TextXAlignment.Left
        ContentLbl.TextWrapped = true
        ContentLbl.TextTransparency = 1
        ContentLbl.Text = content
        ContentLbl.ZIndex = 4
        ContentLbl.Parent = TextHolder

        -- สเปเซอร์ล่างสุดเพื่อกันพื้นที่สำหรับ Progress Bar
        local BottomSpacer = Instance.new("Frame")
        BottomSpacer.BackgroundTransparency = 1
        BottomSpacer.Size = UDim2.new(1, 0, 0, 18)
        BottomSpacer.ZIndex = 4
        BottomSpacer.Parent = TextHolder

        -- ปุ่มปิด X พร้อมพื้นหลังวงกลมนุ่มๆ ตอน hover
        local CloseX = Instance.new("ImageButton")
        CloseX.AnchorPoint = Vector2.new(1, 0)
        CloseX.Position = UDim2.new(1, -10, 0, 10)
        CloseX.Size = UDim2.new(0, 24, 0, 24)
        CloseX.BackgroundColor3 = Theme.SubText
        CloseX.BackgroundTransparency = 1
        CloseX.AutoButtonColor = false
        CloseX.ZIndex = 5
        CloseX.Parent = Toast
        corner(CloseX, 8)

        local CloseXIcon = Instance.new("ImageLabel")
        CloseXIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        CloseXIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
        CloseXIcon.Size = UDim2.new(0, 13, 0, 13)
        CloseXIcon.BackgroundTransparency = 1
        CloseXIcon.Image = Library.Icons.close
        applyThemeColor(CloseXIcon, "SubText", "ImageColor3")
        CloseXIcon.ImageTransparency = 1
        CloseXIcon.ScaleType = Enum.ScaleType.Fit
        CloseXIcon.ZIndex = 6
        CloseXIcon.Parent = CloseX

        CloseX.MouseEnter:Connect(function()
            TweenService:Create(CloseX, TI.d012_Sine_Out, {BackgroundTransparency = 0.88}):Play()
            TweenService:Create(CloseXIcon, TI.d012_Sine_Out, {ImageColor3 = Theme.Text}):Play()
        end)
        CloseX.MouseLeave:Connect(function()
            TweenService:Create(CloseX, TI.d012_Sine_Out, {BackgroundTransparency = 1}):Play()
            TweenService:Create(CloseXIcon, TI.d012_Sine_Out, {ImageColor3 = Theme.SubText}):Play()
        end)

        -- แถบนับถอยหลัง (Progress bar) ด้านล่างสุดแบบเต็มความกว้าง
        local ProgressTrack = Instance.new("Frame")
        ProgressTrack.AnchorPoint = Vector2.new(0.5, 1)
        ProgressTrack.Position = UDim2.new(0.5, 0, 1, -10)
        ProgressTrack.Size = UDim2.new(1, -28, 0, 3)
        applyThemeColor(ProgressTrack, "Stroke")
        ProgressTrack.BackgroundTransparency = 1
        ProgressTrack.BorderSizePixel = 0
        ProgressTrack.ZIndex = 4
        ProgressTrack.ClipsDescendants = true
        ProgressTrack.Parent = Toast
        corner(ProgressTrack, 2)
        
        local ProgressBar = Instance.new("Frame")
        ProgressBar.Size = UDim2.new(1, 0, 1, 0)
        ProgressBar.BackgroundColor3 = color
        ProgressBar.BorderSizePixel = 0
        ProgressBar.ZIndex = 5
        ProgressBar.Parent = ProgressTrack
        corner(ProgressBar, 2)
        local progressGradient = Instance.new("UIGradient")
        progressGradient.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.2), color)
        progressGradient.Parent = ProgressBar

        -- UIScale สำหรับทำเอฟเฟกต์เด้ง
        local ToastScale = Instance.new("UIScale")
        ToastScale.Scale = 0.9
        ToastScale.Parent = Toast

        local IconScale = Instance.new("UIScale")
        IconScale.Scale = 0.5
        IconScale.Parent = IconBadge
        IconBadge.Rotation = -20

        -- รอให้ AutomaticSize คำนวณความสูงจริงให้นิ่งก่อน 1 เฟรม
        -- (แก้ bug: การ์ดที่มีข้อความหลายบรรทัดสูงผิด/กระตุกตอนเด้งเข้า เพราะ AbsoluteSize ยังไม่อัปเดตทันทีที่ Parent)
        RunService.Heartbeat:Wait()

        -- คำนวณความสูงเป้าหมาย (อ้างอิงจากค่าที่นิ่งแล้ว)
        local targetHeight = Toast.AbsoluteSize.Y
        Slot.Size = UDim2.new(1, 0, 0, 0)
        TweenService:Create(Slot, TI.d024_Quint_Out, {Size = UDim2.new(1, 0, 0, targetHeight)}):Play()

        -- sync ความสูงแบบนุ่มนวลทุกครั้งที่เนื้อหาเปลี่ยน (กันการกระตุก/สะดุดของ Slot และ AccentBar)
        local heightSyncConn = Toast:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            local h = Toast.AbsoluteSize.Y
            TweenService:Create(Slot, TI.d012_Sine_Out, {Size = UDim2.new(1, 0, 0, h)}):Play()
            TweenService:Create(AccentBar, TI.d012_Sine_Out, {Size = UDim2.new(0, 4, 0, math.max(h - 32, 0))}):Play()
        end)

        -- ลำดับแอนิเมชันเข้า: สไลด์เข้า + เด้ง + แสดงผลทีละส่วน
        TweenService:Create(Toast, TI.d024_Quint_Out, {Position = UDim2.new(0, 0, 0, 0)}):Play()
        TweenService:Create(ToastScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
        -- Toast background kept transparent (no background)
        TweenService:Create(outline, TI.d022_Sine_Out, {Transparency = 0.45}):Play()
        TweenService:Create(ColorTint, TI.d022_Sine_Out, {BackgroundTransparency = 0}):Play()
        TweenService:Create(Shadow, TI.d03_Sine_Out, {ImageTransparency = 0.55}):Play()

        TweenService:Create(AccentBar, TweenInfo.new(0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, 0.04), {Size = UDim2.new(0, 4, 0, targetHeight - 32), BackgroundTransparency = 0}):Play()

        TweenService:Create(IconScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0.08), {Scale = 1}):Play()
        TweenService:Create(IconBadge, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0.08), {Rotation = 0, BackgroundTransparency = 0}):Play()
        TweenService:Create(IconImg, TweenInfo.new(0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0.14), {ImageTransparency = 0}):Play()

        TweenService:Create(TitleLbl, TweenInfo.new(0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0.1), {TextTransparency = 0}):Play()
        TweenService:Create(ContentLbl, TweenInfo.new(0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0.16), {TextTransparency = 0}):Play()
        TweenService:Create(CloseXIcon, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0.2), {ImageTransparency = 0.25}):Play()

        ProgressBar.BackgroundTransparency = 1
        TweenService:Create(ProgressBar, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0.22), {BackgroundTransparency = 0}):Play()
        TweenService:Create(ProgressTrack, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0.18), {BackgroundTransparency = 0.85}):Play()

        local dismissed = false
        local function dismiss()
            if dismissed or not Toast or not Toast.Parent then return end
            dismissed = true
            if heightSyncConn then heightSyncConn:Disconnect(); heightSyncConn = nil end
            
            -- แอนิเมชันออก: สไลด์ออกขวา + จางหาย
            TweenService:Create(Toast, TI.d018_Quint_In, {Position = UDim2.new(0, 30, 0, 0)}):Play()
            TweenService:Create(ToastScale, TI.d018_Quint_In, {Scale = 0.92}):Play()
            TweenService:Create(IconBadge, TI.d016_Sine_In, {Rotation = 12, BackgroundTransparency = 1}):Play()
            -- Toast background already transparent, no tween needed
            TweenService:Create(outline, TI.d018_Sine_Out, {Transparency = 1}):Play()
            TweenService:Create(ColorTint, TI.d018_Sine_Out, {BackgroundTransparency = 1}):Play()
            TweenService:Create(Shadow, TI.d018_Sine_Out, {ImageTransparency = 1}):Play()
            TweenService:Create(AccentBar, TI.d016_Sine_In, {BackgroundTransparency = 1}):Play()
            TweenService:Create(IconImg, TI.d014_Sine_Out, {ImageTransparency = 1}):Play()
            TweenService:Create(TitleLbl, TI.d014_Sine_Out, {TextTransparency = 1}):Play()
            TweenService:Create(ContentLbl, TI.d014_Sine_Out, {TextTransparency = 1}):Play()
            TweenService:Create(CloseXIcon, TI.d014_Sine_Out, {ImageTransparency = 1}):Play()
            TweenService:Create(ProgressTrack, TI.d014_Sine_Out, {BackgroundTransparency = 1}):Play()
            TweenService:Create(ProgressBar, TI.d014_Sine_Out, {BackgroundTransparency = 1}):Play()
            
            TweenService:Create(Slot, TI.d018_Quint_In, {Size = UDim2.new(1, 0, 0, 0)}):Play()
            task.delay(0.2, function()
                for _, c in ipairs(shadowConns) do c:Disconnect() end
                Shadow:Destroy()
                if Slot then Slot:Destroy() end
                activeNotifyCount -= 1
                tryDequeueNotify()
            end)
        end

        -- ============ ตัวจับเวลาแบบ Pause ได้ ============
        -- Hover ค้างไว้ = หยุดนับถอยหลังชั่วคราว กันการ์ดหายไปตอนอ่านไม่ทัน (เดิมใช้ task.delay ตายตัว หยุดไม่ได้ = bug UX)
        local elapsed = 0
        local isHovering = false
        task.spawn(function()
            while Toast and Toast.Parent and not dismissed do
                local dt = task.wait()
                if not isHovering and not dismissed then
                    elapsed += dt
                    local ratio = math.clamp(1 - (elapsed / duration), 0, 1)
                    ProgressBar.Size = UDim2.new(ratio, 0, 1, 0)
                    if elapsed >= duration then
                        dismiss()
                        break
                    end
                end
            end
        end)

        -- โฮเวอร์การ์ด: หยุดนับถอยหลัง + ยกการ์ดขึ้นเล็กน้อยพร้อมเงาเข้มขึ้น ให้ความรู้สึก interactive
        Toast.MouseEnter:Connect(function()
            isHovering = true
            TweenService:Create(Shadow, TI.d02_Sine_Out, {ImageTransparency = 0.35}):Play()
            TweenService:Create(ToastScale, TI.d02_Sine_Out, {Scale = 1.015}):Play()
        end)
        Toast.MouseLeave:Connect(function()
            isHovering = false
            TweenService:Create(Shadow, TI.d02_Sine_Out, {ImageTransparency = 0.55}):Play()
            TweenService:Create(ToastScale, TI.d02_Sine_Out, {Scale = 1}):Play()
        end)

        CloseX.MouseButton1Click:Connect(dismiss)
    end

    -- ============ Library:Confirm — โมดัลยืนยัน (Yes/No) พร้อม backdrop เบลอ/มืดลง ============
    function Library:Confirm(opts)
        opts = type(opts) == "table" and opts or {}
        local ConfirmGui = Instance.new("ScreenGui")
        ConfirmGui.Name = "ConfirmGui"
        ConfirmGui.ResetOnSpawn = false
        ConfirmGui.IgnoreGuiInset = true
        ConfirmGui.DisplayOrder = 999
        ConfirmGui.Parent = UiParent

        local Backdrop = Instance.new("Frame")
        Backdrop.Size = UDim2.new(1, 0, 1, 0)
        Backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Backdrop.BackgroundTransparency = 1
        Backdrop.Active = true
        Backdrop.ZIndex = 1
        Backdrop.Parent = ConfirmGui

        local Dialog = Instance.new("Frame")
        Dialog.AnchorPoint = Vector2.new(0.5, 0.5)
        Dialog.Position = UDim2.new(0.5, 0, 0.5, 0)
        Dialog.Size = UDim2.new(0, 320, 0, 168)
        applyThemeColor(Dialog, "Background")
        Dialog.BackgroundTransparency = 1
        Dialog.Active = true
        Dialog.ZIndex = 2
        Dialog.Parent = ConfirmGui
        corner(Dialog, 14)
        local dStroke = stroke(Dialog, "Stroke", 1)
        dStroke.Transparency = 1
        local dScale = Instance.new("UIScale")
        dScale.Scale = 0.8
        dScale.Parent = Dialog

        local TitleLbl = Instance.new("TextLabel")
        TitleLbl.Size = UDim2.new(1, -32, 0, 24)
        TitleLbl.Position = UDim2.new(0, 16, 0, 16)
        TitleLbl.BackgroundTransparency = 1
        TitleLbl.Text = opts.Title or "ยืนยันการทำงาน"
        applyThemeColor(TitleLbl, "Text", "TextColor3")
        TitleLbl.Font = Enum.Font.GothamBold
        TitleLbl.TextSize = 16
        TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
        TitleLbl.TextTransparency = 1
        TitleLbl.ZIndex = 2
        TitleLbl.Parent = Dialog

        local ContentLbl = Instance.new("TextLabel")
        ContentLbl.Size = UDim2.new(1, -32, 0, 62)
        ContentLbl.Position = UDim2.new(0, 16, 0, 44)
        ContentLbl.BackgroundTransparency = 1
        ContentLbl.Text = opts.Content or ""
        applyThemeColor(ContentLbl, "SubText", "TextColor3")
        ContentLbl.Font = Enum.Font.Gotham
        ContentLbl.TextSize = 13
        ContentLbl.TextWrapped = true
        ContentLbl.TextXAlignment = Enum.TextXAlignment.Left
        ContentLbl.TextYAlignment = Enum.TextYAlignment.Top
        ContentLbl.TextTransparency = 1
        ContentLbl.ZIndex = 2
        ContentLbl.Parent = Dialog

        local BtnRow = Instance.new("Frame")
        BtnRow.Size = UDim2.new(1, -32, 0, 36)
        BtnRow.Position = UDim2.new(0, 16, 1, -52)
        BtnRow.BackgroundTransparency = 1
        BtnRow.ZIndex = 2
        BtnRow.Parent = Dialog
        local RowLayout = Instance.new("UIListLayout")
        RowLayout.FillDirection = Enum.FillDirection.Horizontal
        RowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        RowLayout.Padding = UDim.new(0, 8)
        RowLayout.Parent = BtnRow

        local CancelBtn
        if not opts.HideCancel then
            CancelBtn = Instance.new("TextButton")
            CancelBtn.Size = UDim2.new(0, 92, 1, 0)
            applyThemeColor(CancelBtn, "Element")
            CancelBtn.AutoButtonColor = false
            CancelBtn.Text = opts.CancelText or "ยกเลิก"
            applyThemeColor(CancelBtn, "SubText", "TextColor3")
            CancelBtn.Font = Enum.Font.GothamSemibold
            CancelBtn.TextSize = 13
            CancelBtn.ZIndex = 2
            CancelBtn.Parent = BtnRow
            corner(CancelBtn, 8)
            applyHoverEffect(CancelBtn, "Element", "ElementHover")
            applyPressAnimation(CancelBtn, 0.94)
            ripple(CancelBtn, "Stroke")
        end

        local ConfirmBtn = Instance.new("TextButton")
        ConfirmBtn.Size = UDim2.new(0, 92, 1, 0)
        applyThemeColor(ConfirmBtn, opts.Danger and "Danger" or "AccentA")
        ConfirmBtn.AutoButtonColor = false
        ConfirmBtn.Text = opts.ConfirmText or "ยืนยัน"
        ConfirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        ConfirmBtn.Font = Enum.Font.GothamBold
        ConfirmBtn.TextSize = 13
        ConfirmBtn.ZIndex = 2
        ConfirmBtn.Parent = BtnRow
        corner(ConfirmBtn, 8)
        applyPressAnimation(ConfirmBtn, 0.94)

        local closed = false
        local function close(result)
            if closed then return end
            closed = true
            TweenService:Create(Backdrop, TI.d018_Sine_Out, {BackgroundTransparency = 1}):Play()
            TweenService:Create(dScale, TI.d018_Quint_In, {Scale = 0.85}):Play()
            TweenService:Create(Dialog, TI.d018_Quint_In, {BackgroundTransparency = 1}):Play()
            TweenService:Create(dStroke, TI.d018_Quint_In, {Transparency = 1}):Play()
            TweenService:Create(TitleLbl, TI.d014_Sine_Out, {TextTransparency = 1}):Play()
            TweenService:Create(ContentLbl, TI.d014_Sine_Out, {TextTransparency = 1}):Play()
            task.delay(0.2, function() if ConfirmGui then ConfirmGui:Destroy() end end)
            if result then
                if opts.OnConfirm then safeCallback(opts.OnConfirm) end
            else
                if opts.OnCancel then safeCallback(opts.OnCancel) end
            end
        end

        Backdrop.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                close(false)
            end
        end)
        if CancelBtn then
            CancelBtn.MouseButton1Click:Connect(function() close(false) end)
        end
        ConfirmBtn.MouseButton1Click:Connect(function() close(true) end)

        -- ลำดับแอนิเมชันเข้า: backdrop มืดลง + กล่องเด้งเข้าแบบสปริง
        TweenService:Create(Backdrop, TI.d022_Sine_Out, {BackgroundTransparency = 0.45}):Play()
        TweenService:Create(dScale, TI.d045_Back_Out, {Scale = 1}):Play()
        TweenService:Create(Dialog, TI.d024_Quint_Out, {BackgroundTransparency = 0}):Play()
        TweenService:Create(dStroke, TI.d024_Quint_Out, {Transparency = 0.5}):Play()
        TweenService:Create(TitleLbl, TI.d022_Sine_Out, {TextTransparency = 0}):Play()
        TweenService:Create(ContentLbl, TI.d022_Sine_Out, {TextTransparency = 0}):Play()

        return {Close = function() close(false) end}
    end

    -- ============ Library:Alert — โมดัลแจ้งเตือนปุ่มเดียว (OK) ใช้ Confirm ภายในโดยซ่อนปุ่มยกเลิก ============
    function Library:Alert(opts)
        opts = type(opts) == "table" and opts or {}
        return Library:Confirm({
            Title = opts.Title,
            Content = opts.Content,
            ConfirmText = opts.ButtonText or "OK",
            CancelText = nil,
            HideCancel = true,
            OnConfirm = opts.OnClose,
            OnCancel = opts.OnClose,
        })
    end

    -- ============ Main window ============
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    Shadow.Size = (config.Size or UDim2.new(0, 400, 0, 380)) + UDim2.new(0, 60, 0, 60)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxassetid://1316045217"
    Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.ImageTransparency = 1
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    Shadow.Parent = ScreenGui

    local MainFrame = Instance.new("Frame")
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Size = UDim2.new(0, 380, 0, 340)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    applyThemeColor(MainFrame, "Background")
    MainFrame.BackgroundTransparency = 1
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Parent = Shadow
    corner(MainFrame, 14)
    local mainStroke = stroke(MainFrame)
    mainStroke.Transparency = 1

    -- CanvasGroup ห่อ TopBar/Tabs/Content ไว้ เพื่อให้ fade ตอนซ่อน/ปิด UI
    -- เป็นภาพเดียวกันทั้งหมดพร้อมกัน แทนที่จะเห็นแต่ละส่วนจางไม่พร้อมกัน
    local MainContent = Instance.new("CanvasGroup")
    MainContent.Name = "MainContent"
    MainContent.Size = UDim2.new(1, 0, 1, 0)
    MainContent.BackgroundTransparency = 1
    MainContent.GroupTransparency = 0
    MainContent.Parent = MainFrame
    corner(MainContent, 14)

    local WindowScale = Instance.new("UIScale")
    WindowScale.Scale = 1
    WindowScale.Parent = Shadow

    local Sheen = Instance.new("Frame")
    Sheen.Name = "Sheen"
    Sheen.Size = UDim2.new(1, 0, 1, 0)
    Sheen.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Sheen.BorderSizePixel = 0
    Sheen.ZIndex = 0
    Sheen.Active = false
    Sheen.Parent = MainFrame
    corner(Sheen, 14)
    local sheenGradient = Instance.new("UIGradient")
    sheenGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255))
    sheenGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.93),
        NumberSequenceKeypoint.new(0.35, 1),
        NumberSequenceKeypoint.new(1, 1),
    })
    sheenGradient.Rotation = 100
    sheenGradient.Parent = Sheen

    local topBarH = config.SubTitle and 50 or 42
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, topBarH)
    applyThemeColor(TopBar, "Topbar")
    TopBar.BackgroundTransparency = 1
    TopBar.BorderSizePixel = 0
    TopBar.Active = true
    TopBar.Parent = MainContent
    corner(TopBar, 14)
    
    local topBarFix = Instance.new("Frame")
    topBarFix.Size = UDim2.new(1, 0, 0, 12)
    topBarFix.Position = UDim2.new(0, 0, 1, -12)
    applyThemeColor(topBarFix, "Topbar")
    topBarFix.BackgroundTransparency = 1
    topBarFix.BorderSizePixel = 0
    topBarFix.ZIndex = 0
    topBarFix.Parent = TopBar

    local TopBarLine = Instance.new("Frame")
    TopBarLine.Name = "TopBarLine"
    TopBarLine.Size = UDim2.new(1, 0, 0, 1)
    TopBarLine.Position = UDim2.new(0, 0, 1, 0)
    applyThemeColor(TopBarLine, "Stroke")
    TopBarLine.BackgroundTransparency = 0.4
    TopBarLine.BorderSizePixel = 0
    TopBarLine.Parent = TopBar

    local LogoDot = Instance.new("Frame")
    LogoDot.Size = UDim2.new(0, 8, 0, 8)
    LogoDot.Position = UDim2.new(0, 15, 0, config.SubTitle and 14 or 17)
    applyThemeColor(LogoDot, "AccentA")
    LogoDot.BackgroundTransparency = 1
    LogoDot.Parent = TopBar
    corner(LogoDot, 4)
    accentGradient(LogoDot, 45)

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -96, 0, 18)
    TitleLabel.Position = UDim2.new(0, 30, 0, config.SubTitle and 8 or 0)
    if not config.SubTitle then TitleLabel.Size = UDim2.new(1, -96, 1, 0) end
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = config.Title or "Pro Hub"
    applyThemeColor(TitleLabel, "Text", "TextColor3")
    TitleLabel.TextTransparency = 1
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 15
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TopBar

    if config.SubTitle then
        local SubTitleLabel = Instance.new("TextLabel")
        SubTitleLabel.Size = UDim2.new(1, -96, 0, 14)
        SubTitleLabel.Position = UDim2.new(0, 30, 0, 27)
        SubTitleLabel.BackgroundTransparency = 1
        SubTitleLabel.Text = config.SubTitle
        applyThemeColor(SubTitleLabel, "SubText", "TextColor3")
        SubTitleLabel.TextTransparency = 1
        SubTitleLabel.Font = Enum.Font.Gotham
        SubTitleLabel.TextSize = 11
        SubTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
        SubTitleLabel.Parent = TopBar
        TweenService:Create(SubTitleLabel, TI.d03_Sine_Out, {TextTransparency = 0}):Play()
    end

    local CloseBtn = Instance.new("ImageButton")
    CloseBtn.Size = UDim2.new(0, 26, 0, 26)
    CloseBtn.AnchorPoint = Vector2.new(1, 0.5)
    CloseBtn.Position = UDim2.new(1, -10, 0.5, 0)
    applyThemeColor(CloseBtn, "Element")
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.AutoButtonColor = false
    CloseBtn.Image = Library.Icons.close
    applyThemeColor(CloseBtn, "SubText", "ImageColor3")
    CloseBtn.ScaleType = Enum.ScaleType.Fit
    CloseBtn.ZIndex = 5
    CloseBtn.Parent = TopBar
    corner(CloseBtn, 8)
    applyPressAnimation(CloseBtn, 0.8)
    CloseBtn.MouseEnter:Connect(function()
        TweenService:Create(CloseBtn, TI.d015_Sine_Out, {BackgroundColor3 = Theme.Danger, ImageColor3 = Color3.fromRGB(255,255,255)}):Play()
    end)
    CloseBtn.MouseLeave:Connect(function()
        TweenService:Create(CloseBtn, TI.d015_Sine_Out, {BackgroundColor3 = Theme.Element, ImageColor3 = Theme.SubText}):Play()
    end)
    CloseBtn.MouseButton1Click:Connect(function()
        Window:Confirm({
            Title = "ปิด UI",
            Content = "ยืนยันที่จะปิดหน้าต่างนี้หรือไม่?",
            ConfirmText = "ยืนยัน",
            CancelText = "ยกเลิก",
            Callback = function(result)
                if result then
                    Window:Destroy()
                end
            end
        })
    end)

    local HideBtn = Instance.new("ImageButton")
    HideBtn.Size = UDim2.new(0, 26, 0, 26)
    HideBtn.AnchorPoint = Vector2.new(1, 0.5)
    HideBtn.Position = UDim2.new(1, -46, 0.5, 0)
    applyThemeColor(HideBtn, "Element")
    HideBtn.BackgroundTransparency = 1
    HideBtn.AutoButtonColor = false
    HideBtn.Image = Library.Icons.minus
    applyThemeColor(HideBtn, "SubText", "ImageColor3")
    HideBtn.ScaleType = Enum.ScaleType.Fit
    HideBtn.ZIndex = 5
    HideBtn.Parent = TopBar
    corner(HideBtn, 8)
    applyPressAnimation(HideBtn, 0.8)
    HideBtn.MouseEnter:Connect(function()
        TweenService:Create(HideBtn, TI.d015_Sine_Out, {BackgroundColor3 = Theme.ElementHover, BackgroundTransparency = 0.3}):Play()
    end)
    HideBtn.MouseLeave:Connect(function()
        TweenService:Create(HideBtn, TI.d015_Sine_Out, {BackgroundTransparency = 1}):Play()
    end)

    local RestoreGui = Instance.new("ScreenGui")
    RestoreGui.Name = "RestoreGui"
    RestoreGui.ResetOnSpawn = false
    RestoreGui.IgnoreGuiInset = true
    RestoreGui.DisplayOrder = 999
    RestoreGui.Parent = UiParent

    local RestoreBtn = Instance.new("ImageButton")
    RestoreBtn.Name = "RestoreBtn"
    RestoreBtn.Size = UDim2.new(0, 46, 0, 46)
    RestoreBtn.Position = UDim2.new(0, 20, 0, 120)
    applyThemeColor(RestoreBtn, "AccentA")
    RestoreBtn.BackgroundTransparency = 0
    RestoreBtn.AutoButtonColor = false
    RestoreBtn.Image = ""
    RestoreBtn.ScaleType = Enum.ScaleType.Fit
    RestoreBtn.ZIndex = 20
    RestoreBtn.Visible = false
    RestoreBtn.Active = true
    RestoreBtn.Parent = RestoreGui
    corner(RestoreBtn, 23)
    local RestoreBtnScale = Instance.new("UIScale")
    RestoreBtnScale.Scale = 1
    RestoreBtnScale.Parent = RestoreBtn
    accentGradient(RestoreBtn, 100)
    stroke(RestoreBtn)

    if config.Icon then
        RestoreBtn.Image = normalizeAssetId(config.Icon)
        local iconPad = Instance.new("UIPadding")
        iconPad.PaddingLeft = UDim.new(0, 8)
        iconPad.PaddingRight = UDim.new(0, 8)
        iconPad.PaddingTop = UDim.new(0, 8)
        iconPad.PaddingBottom = UDim.new(0, 8)
        iconPad.Parent = RestoreBtn
    else
        local LetterLabel = Instance.new("TextLabel")
        LetterLabel.Name = "LetterLabel"
        LetterLabel.Size = UDim2.new(1, 0, 1, 0)
        LetterLabel.BackgroundTransparency = 1
        LetterLabel.Text = string.upper(string.sub(config.Title or "H", 1, 1))
        LetterLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        LetterLabel.Font = Enum.Font.GothamBold
        LetterLabel.TextSize = 20
        LetterLabel.ZIndex = 21
        LetterLabel.Parent = RestoreBtn
    end

    -- ============ FPS Badge (ติดข้างปุ่มเปิด UI) ============
    local FpsPill = Instance.new("Frame")
    FpsPill.Name = "FpsPill"
    FpsPill.AutomaticSize = Enum.AutomaticSize.X
    FpsPill.Size = UDim2.new(0, 0, 0, 46)          -- สูงเท่า RestoreBtn (46) ให้ตรงแนวกันสนิท
    applyThemeColor(FpsPill, "Element")
    FpsPill.BackgroundTransparency = 0.05
    FpsPill.BorderSizePixel = 0
    FpsPill.ZIndex = 20
    FpsPill.Visible = false
    FpsPill.Parent = RestoreGui
    corner(FpsPill, 23)
    local FpsStroke = stroke(FpsPill, "AccentA")   -- border สีเดียวกับปุ่ม S ให้เข้าชุด
    FpsStroke.Transparency = 0.3

    local FpsPillScale = Instance.new("UIScale")
    FpsPillScale.Scale = 1
    FpsPillScale.Parent = FpsPill

    local FpsPadding = Instance.new("UIPadding")
    FpsPadding.PaddingLeft = UDim.new(0, 14)
    FpsPadding.PaddingRight = UDim.new(0, 14)
    FpsPadding.Parent = FpsPill

    local FpsListLayout = Instance.new("UIListLayout")
    FpsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    FpsListLayout.FillDirection = Enum.FillDirection.Horizontal
    FpsListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    FpsListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    FpsListLayout.Padding = UDim.new(0, 6)
    FpsListLayout.Parent = FpsPill

    local FpsDotWrap = Instance.new("Frame")
    FpsDotWrap.Name = "FpsDotWrap"
    FpsDotWrap.Size = UDim2.new(0, 8, 0, 8)
    FpsDotWrap.BackgroundTransparency = 1
    FpsDotWrap.LayoutOrder = 1
    FpsDotWrap.ZIndex = 22
    FpsDotWrap.Visible = true
    FpsDotWrap.Parent = FpsPill

    local FpsDot = Instance.new("Frame")
    FpsDot.Name = "FpsDot"
    FpsDot.Size = UDim2.new(1, 0, 1, 0)
    FpsDot.BackgroundColor3 = Theme.Success
    FpsDot.BackgroundTransparency = 0
    FpsDot.BorderSizePixel = 0
    FpsDot.ZIndex = 22
    FpsDot.Visible = true
    FpsDot.Parent = FpsDotWrap
    corner(FpsDot, 4)

    -- glow เล็กๆ รอบจุดสี ให้ดูมีชีวิตขึ้นนิดหน่อย
    local FpsDotGlow = Instance.new("UIStroke")
    FpsDotGlow.Color = Theme.Success
    FpsDotGlow.Thickness = 3
    FpsDotGlow.Transparency = 0.6
    FpsDotGlow.Parent = FpsDot

    local FpsLabel = Instance.new("TextLabel")
    FpsLabel.Name = "FpsLabel"
    FpsLabel.BackgroundTransparency = 1
    FpsLabel.AutomaticSize = Enum.AutomaticSize.X
    FpsLabel.Size = UDim2.new(0, 0, 1, 0)
    FpsLabel.Font = Enum.Font.GothamBold
    FpsLabel.TextSize = 13
    FpsLabel.TextTransparency = 0
    FpsLabel.RichText = false
    FpsLabel.Text = "60 FPS"
    applyThemeColor(FpsLabel, "Text", "TextColor3")
    FpsLabel.TextXAlignment = Enum.TextXAlignment.Left
    FpsLabel.LayoutOrder = 2
    FpsLabel.ZIndex = 22
    FpsLabel.Visible = true
    FpsLabel.Parent = FpsPill

    -- เกาะติดขวาปุ่มเปิด UI เสมอ แม้จะลากปุ่มไปวางที่อื่น
    local function repositionFpsPill()
        FpsPill.Position = UDim2.new(
            0, RestoreBtn.Position.X.Offset + RestoreBtn.Size.X.Offset + 10,
            0, RestoreBtn.Position.Y.Offset + (RestoreBtn.Size.Y.Offset - FpsPill.AbsoluteSize.Y) / 2
        )
    end
    RestoreBtn:GetPropertyChangedSignal("Position"):Connect(repositionFpsPill)
    FpsPill:GetPropertyChangedSignal("AbsoluteSize"):Connect(repositionFpsPill)
    repositionFpsPill()

    -- sample fps แบบ smoothed (ค่าเฉลี่ยเคลื่อนที่) ทุกๆ ~0.4 วิ กันตัวเลขกระตุก
    local fpsConn
    do
        local fpsFrames, fpsAccum, fpsSmoothed = 0, 0, 60
        fpsConn = RunService.RenderStepped:Connect(function(dt)
            if dt <= 0 then return end
            fpsFrames += 1
            fpsAccum += dt
            if fpsAccum >= 0.4 then
                local currentFps = fpsFrames / fpsAccum
                fpsSmoothed = fpsSmoothed * 0.55 + currentFps * 0.45
                fpsFrames, fpsAccum = 0, 0
                local rounded = math.floor(fpsSmoothed + 0.5)
                FpsLabel.Text = rounded .. " FPS"     -- อัปเดตทุกครั้ง ไม่เช็ค Visible แล้ว กันเคสตกจังหวะ
                local dotColor
                if rounded >= 50 then
                    dotColor = Theme.Success
                elseif rounded >= 30 then
                    dotColor = Theme.Warning
                else
                    dotColor = Theme.Danger
                end
                FpsDot.BackgroundColor3 = dotColor
                FpsDotGlow.Color = dotColor
            end
        end)
    end

    -- normalize เป็น pure Offset ตั้งแต่เริ่ม กัน Scale=0.5 ปนกับ Offset ตอน tween กลับบ้านหลัง drag
    local _ss0 = ScreenGui.AbsoluteSize
    local _rp = Shadow.Position
    local _normX = _rp.X.Scale * _ss0.X + _rp.X.Offset
    local _normY = _rp.Y.Scale * _ss0.Y + _rp.Y.Offset
    Shadow.Position = UDim2.new(0, _normX, 0, _normY)
    local baseShadowPos = Shadow.Position
    local hiddenShadowPos = UDim2.new(0, _normX, 0, _normY + 14)
    local hideToken = 0
    local function setUiVisible(visible)
        hideToken = hideToken + 1
        local myToken = hideToken
        if visible then
            ScreenGui.Enabled = true
            RestoreBtn.Visible = false
            FpsPill.Visible = false
            WindowScale.Scale = 0.82
            MainFrame.Rotation = -2.2
            Shadow.Position = hiddenShadowPos
            MainFrame.BackgroundTransparency = 1
            mainStroke.Transparency = 1
            MainContent.GroupTransparency = 1
            local easeIn = TI.d024_Quint_Out
            -- เด้งเข้าแบบสปริงแรงๆ พร้อมเอียงตัวเล็กน้อยแล้วสะบัดกลับ ให้ความรู้สึก "โหด" ตอนเปิดหน้าต่าง
            TweenService:Create(WindowScale, TI.d045_Back_Out, {Scale = 1}):Play()
            TweenService:Create(MainFrame, TI.d045_Back_Out, {Rotation = 0}):Play()
            TweenService:Create(Shadow, easeIn, {Position = baseShadowPos}):Play()
            TweenService:Create(MainFrame, easeIn, {BackgroundTransparency = 0}):Play()
            TweenService:Create(mainStroke, easeIn, {Transparency = 0.5}):Play()
            TweenService:Create(MainContent, TI.d022_Sine_Out, {GroupTransparency = 0}):Play()
        else
            local easeOut = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
            local t = TweenService:Create(WindowScale, easeOut, {Scale = 0.9})
            TweenService:Create(Shadow, easeOut, {Position = hiddenShadowPos}):Play()
            TweenService:Create(MainFrame, easeOut, {BackgroundTransparency = 1}):Play()
            TweenService:Create(mainStroke, easeOut, {Transparency = 1}):Play()
            TweenService:Create(MainContent, TweenInfo.new(0.16, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {GroupTransparency = 1}):Play()
            t:Play()
            t.Completed:Connect(function()
                if myToken ~= hideToken then return end
                ScreenGui.Enabled = false
                Shadow.Position = baseShadowPos
                RestoreBtn.Visible = true
                RestoreBtnScale.Scale = 0.5
                TweenService:Create(RestoreBtnScale, TI.d022_Back_Out, {Scale = 1}):Play()
                FpsPill.Visible = true
                FpsPillScale.Scale = 0.5
                TweenService:Create(FpsPillScale, TI.d022_Back_Out, {Scale = 1}):Play()
            end)
        end
    end

    HideBtn.MouseButton1Click:Connect(function() setUiVisible(false) end)

    do
        local rDragging, rDragStart, rStartPos, rTouch, rMoved = false, nil, nil, nil, false
        local rChangedConn, rEndedConn = nil, nil

        -- กันปุ่ม S ลากหลุดจอ (RestoreBtn มี AnchorPoint 0,0 ค่า Offset คือมุมบนซ้าย)
        local function clampRestorePos(pos)
            local screenSize = RestoreGui.AbsoluteSize
            local w, h = RestoreBtn.AbsoluteSize.X, RestoreBtn.AbsoluteSize.Y
            local x = math.clamp(pos.X.Offset, 0, math.max(0, screenSize.X - w))
            local y = math.clamp(pos.Y.Offset, 0, math.max(0, screenSize.Y - h))
            return UDim2.new(0, x, 0, y)
        end

        local function stopRestoreDrag(input)
            if rDragging and not rMoved then
                setUiVisible(true)
            end
            rDragging = false
            if input and input == rTouch then rTouch = nil end
            if rChangedConn then rChangedConn:Disconnect(); rChangedConn = nil end
            if rEndedConn then rEndedConn:Disconnect(); rEndedConn = nil end
        end

        RestoreBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                rDragging = true
                rMoved = false
                rDragStart = input.Position
                rStartPos = RestoreBtn.Position
                if input.UserInputType == Enum.UserInputType.Touch then rTouch = input end

                rChangedConn = UserInputService.InputChanged:Connect(function(input2)
                    if rDragging and (input2.UserInputType == Enum.UserInputType.MouseMovement or input2.UserInputType == Enum.UserInputType.Touch) then
                        if input2.UserInputType == Enum.UserInputType.MouseMovement or input2 == rTouch then
                            local delta = input2.Position - rDragStart
                            if delta.Magnitude > 4 then rMoved = true end
                            RestoreBtn.Position = clampRestorePos(UDim2.new(rStartPos.X.Scale, rStartPos.X.Offset + delta.X, rStartPos.Y.Scale, rStartPos.Y.Offset + delta.Y))
                        end
                    end
                end)
                rEndedConn = UserInputService.InputEnded:Connect(function(input2)
                    if input2.UserInputType == Enum.UserInputType.MouseButton1 or input2.UserInputType == Enum.UserInputType.Touch then
                        stopRestoreDrag(input2)
                    end
                end)
            end
        end)
    end

    local TabContainer = Instance.new("Frame")
    TabContainer.Size = UDim2.new(0, 118, 1, -topBarH)
    TabContainer.Position = UDim2.new(0, 0, 0, topBarH)
    applyThemeColor(TabContainer, "Sidebar")
    TabContainer.BackgroundTransparency = 1
    TabContainer.BorderSizePixel = 0
    TabContainer.Active = true
    TabContainer.Parent = MainContent
    corner(TabContainer, 12)

    -- ============ ช่องค้นหาแท็บ (sticky อยู่บนสุดของ Sidebar) ============
    local TabSearchWrap = Instance.new("Frame")
    TabSearchWrap.Size = UDim2.new(1, -12, 0, 30)
    TabSearchWrap.Position = UDim2.new(0, 6, 0, 6)
    applyThemeColor(TabSearchWrap, "Background")
    TabSearchWrap.BackgroundTransparency = 0.15
    TabSearchWrap.ClipsDescendants = true
    TabSearchWrap.Parent = TabContainer
    corner(TabSearchWrap, 14) -- โค้งมนแบบแคปซูล ดูทันสมัยขึ้น
    local tabSearchStroke = stroke(TabSearchWrap)
    tabSearchStroke.Thickness = 1
    tabSearchStroke.Transparency = 0.75
    -- แถบเรืองแสงสีธีม ซ้อนอยู่เหนือกรอบปกติ โผล่มาตอน focus (ไม่แตะสี Stroke ที่ผูกกับระบบ Theme)
    local tabSearchGlow = stroke(TabSearchWrap, "AccentA", 1.2)
    tabSearchGlow.Transparency = 1
    -- ชั้นไล่เฉดบางๆ ให้พื้นผิวดูมีมิติ ไม่แบนราบ
    local tabSearchSheen = Instance.new("UIGradient")
    tabSearchSheen.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255))
    tabSearchSheen.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.93), NumberSequenceKeypoint.new(1, 1)})
    tabSearchSheen.Rotation = 90
    tabSearchSheen.Parent = TabSearchWrap
    local tabSearchScale = Instance.new("UIScale")
    tabSearchScale.Parent = TabSearchWrap

    local TabSearchIcon = Instance.new("ImageLabel")
    TabSearchIcon.Size = UDim2.new(0, 12, 0, 12)
    TabSearchIcon.AnchorPoint = Vector2.new(0, 0.5)
    TabSearchIcon.Position = UDim2.new(0, 9, 0.5, 0)
    TabSearchIcon.BackgroundTransparency = 1
    TabSearchIcon.ImageTransparency = 0.2
    TabSearchIcon.Image = Library.Icons.search
    applyThemeColor(TabSearchIcon, "SubText", "ImageColor3")
    TabSearchIcon.ScaleType = Enum.ScaleType.Fit
    TabSearchIcon.Parent = TabSearchWrap

    local TabSearchBox = Instance.new("TextBox")
    TabSearchBox.Position = UDim2.new(0, 26, 0, 0)
    TabSearchBox.Size = UDim2.new(1, -46, 1, 0)
    TabSearchBox.BackgroundTransparency = 1
    TabSearchBox.Text = ""
    TabSearchBox.PlaceholderText = "ค้นหา"
    applyThemeColor(TabSearchBox, "Text", "TextColor3")
    applyThemeColor(TabSearchBox, "SubText", "PlaceholderColor3")
    TabSearchBox.Font = Enum.Font.GothamSemibold
    TabSearchBox.TextSize = 11.5
    TabSearchBox.ClearTextOnFocus = false
    TabSearchBox.TextXAlignment = Enum.TextXAlignment.Left
    TabSearchBox.Parent = TabSearchWrap

    -- ปุ่มล้างคำค้นหา (X) โผล่มาเมื่อมีข้อความ กดแล้วเคลียร์ + โฟกัสกลับทันที
    local TabSearchClear = Instance.new("ImageButton")
    TabSearchClear.AnchorPoint = Vector2.new(1, 0.5)
    TabSearchClear.Position = UDim2.new(1, -6, 0.5, 0)
    TabSearchClear.Size = UDim2.new(0, 15, 0, 15)
    TabSearchClear.BackgroundTransparency = 1
    TabSearchClear.AutoButtonColor = false
    TabSearchClear.Image = Library.Icons.close
    applyThemeColor(TabSearchClear, "SubText", "ImageColor3")
    TabSearchClear.ImageTransparency = 1
    TabSearchClear.ScaleType = Enum.ScaleType.Fit
    TabSearchClear.Parent = TabSearchWrap
    TabSearchClear.MouseButton1Click:Connect(function()
        TabSearchBox.Text = ""
        TabSearchBox:CaptureFocus()
    end)

    TabSearchBox.Focused:Connect(function()
        TweenService:Create(tabSearchStroke, TI.d015_Sine_Out, {Transparency = 0.3}):Play()
        TweenService:Create(tabSearchGlow, TI.d02_Sine_Out, {Transparency = 0.35}):Play()
        TweenService:Create(TabSearchWrap, TI.d015_Sine_Out, {BackgroundTransparency = 0}):Play()
        TweenService:Create(TabSearchIcon, TI.d015_Sine_Out, {ImageTransparency = 0}):Play()
        TweenService:Create(tabSearchScale, TI.d02_Back_Out, {Scale = 1.015}):Play()
    end)
    TabSearchBox.FocusLost:Connect(function()
        TweenService:Create(tabSearchStroke, TI.d015_Sine_Out, {Transparency = 0.75}):Play()
        TweenService:Create(tabSearchGlow, TI.d015_Sine_Out, {Transparency = 1}):Play()
        TweenService:Create(TabSearchWrap, TI.d015_Sine_Out, {BackgroundTransparency = 0.15}):Play()
        TweenService:Create(TabSearchIcon, TI.d015_Sine_Out, {ImageTransparency = 0.2}):Play()
        TweenService:Create(tabSearchScale, TI.d02_Back_Out, {Scale = 1}):Play()
    end)
    TabSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        TweenService:Create(TabSearchClear, TI.d012_Sine_Out, {ImageTransparency = TabSearchBox.Text == "" and 1 or 0.1}):Play()
    end)

    local TabList = Instance.new("ScrollingFrame")
    TabList.Size = UDim2.new(1, -12, 1, -46)
    TabList.Position = UDim2.new(0, 6, 0, 40)
    TabList.BackgroundTransparency = 1
    TabList.ScrollBarThickness = 2
    applyThemeColor(TabList, "AccentA", "ScrollBarImageColor3")
    TabList.Active = true
    TabList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    TabList.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabList.Parent = TabContainer
    local TabLayout = Instance.new("UIListLayout")
    TabLayout.Padding = UDim.new(0, 4)
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabLayout.Parent = TabList

    -- registry ของแท็บทั้งหมด (ใช้กรองตอนค้นหา) + label "ไม่พบแท็บ"
    local allTabs = {}
    local TabEmptyLbl = Instance.new("TextLabel")
    TabEmptyLbl.Size = UDim2.new(1, 0, 0, 30)
    TabEmptyLbl.BackgroundTransparency = 1
    TabEmptyLbl.Text = "ไม่พบแท็บ"
    applyThemeColor(TabEmptyLbl, "SubText", "TextColor3")
    TabEmptyLbl.Font = Enum.Font.GothamSemibold
    TabEmptyLbl.TextSize = 12
    TabEmptyLbl.Visible = false
    TabEmptyLbl.Parent = TabList

    local function applyTabFilter(query)
        query = (query or ""):lower()
        local visibleCount = 0
        for _, entry in ipairs(allTabs) do
            local match = query == "" or string.find(entry.name:lower(), query, 1, true) ~= nil
            entry.btn.Visible = match
            if match then visibleCount += 1 end
        end
        TabEmptyLbl.Visible = visibleCount == 0
    end
    TabSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        applyTabFilter(TabSearchBox.Text)
    end)

    local ContentArea = Instance.new("Frame")
    ContentArea.Size = UDim2.new(1, -118, 1, -topBarH)
    ContentArea.Position = UDim2.new(0, 118, 0, topBarH)
    ContentArea.BackgroundTransparency = 1
    ContentArea.Active = true
    ContentArea.Parent = MainContent

    local resizing = false
    local ResizeHandle = Instance.new("ImageButton")
    ResizeHandle.Size = UDim2.new(0, 34, 0, 34)
    ResizeHandle.AnchorPoint = Vector2.new(1, 1)
    ResizeHandle.Position = UDim2.new(1, 0, 1, 0)
    ResizeHandle.BackgroundTransparency = 1
    ResizeHandle.AutoButtonColor = false
    ResizeHandle.Image = ""
    ResizeHandle.ZIndex = 6
    ResizeHandle.Parent = MainContent

    -- พื้นหลัง pill โชว์ตอน hover/resize
    local ResizeBg = Instance.new("Frame")
    ResizeBg.AnchorPoint = Vector2.new(1, 1)
    ResizeBg.Position = UDim2.new(1, -2, 1, -2)
    ResizeBg.Size = UDim2.new(0, 28, 0, 28)
    ResizeBg.BackgroundColor3 = Theme.AccentA
    ResizeBg.BackgroundTransparency = 1
    ResizeBg.BorderSizePixel = 0
    ResizeBg.ZIndex = 5
    ResizeBg.Parent = ResizeHandle
    corner(ResizeBg, 8)

    local ResizeIcon = Instance.new("ImageLabel")
    ResizeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    ResizeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    ResizeIcon.Size = UDim2.new(0, 14, 0, 14)
    ResizeIcon.BackgroundTransparency = 1
    ResizeIcon.Image = "rbxassetid://10709760051"
    ResizeIcon.Rotation = 90
    ResizeIcon.ImageTransparency = 0.55
    ResizeIcon.ImageColor3 = Theme.SubText
    ResizeIcon.ScaleType = Enum.ScaleType.Fit
    ResizeIcon.ZIndex = 6
    ResizeIcon.Parent = ResizeBg

    local ResizeIconScale = Instance.new("UIScale")
    ResizeIconScale.Scale = 1
    ResizeIconScale.Parent = ResizeBg

    ResizeHandle.MouseEnter:Connect(function()
        TweenService:Create(ResizeBg, TI.d015_Sine_Out, {BackgroundTransparency = 0.82}):Play()
        TweenService:Create(ResizeIcon, TI.d015_Sine_Out, {ImageTransparency = 0, ImageColor3 = Theme.AccentA}):Play()
        TweenService:Create(ResizeIconScale, TI.d015_Sine_Out, {Scale = 1.1}):Play()
    end)
    ResizeHandle.MouseLeave:Connect(function()
        if not resizing then
            TweenService:Create(ResizeBg, TI.d015_Sine_Out, {BackgroundTransparency = 1}):Play()
            TweenService:Create(ResizeIcon, TI.d015_Sine_Out, {ImageTransparency = 0.55, ImageColor3 = Theme.SubText}):Play()
            TweenService:Create(ResizeIconScale, TI.d015_Sine_Out, {Scale = 1}):Play()
        end
    end)

    local Tabs = {}
    local CurrentTab = nil
    local closeActivePopup = function() end
    local tabOrderCounter = 0

    TweenService:Create(MainFrame, TI.d028_Sine_Out, {
        BackgroundTransparency = 0
    }):Play()
    TweenService:Create(mainStroke, TI.d028_Sine_Out, {Transparency = 0.5}):Play()
    TweenService:Create(TopBar, TI.d028_Sine_Out, {BackgroundTransparency = 0}):Play()
    TweenService:Create(topBarFix, TI.d028_Sine_Out, {BackgroundTransparency = 0}):Play()
    TweenService:Create(TitleLabel, TI.d03_Sine_Out, {TextTransparency = 0}):Play()
    TweenService:Create(LogoDot, TI.d03_Sine_Out, {BackgroundTransparency = 0}):Play()
    TweenService:Create(CloseBtn, TI.d028_Sine_Out, {ImageTransparency = 1}):Play()
    TweenService:Create(CloseBtn, TI.d028_Sine_Out, {ImageTransparency = 0}):Play()
    HideBtn.ImageTransparency = 1
    TweenService:Create(HideBtn, TI.d028_Sine_Out, {ImageTransparency = 0}):Play()
    TweenService:Create(TabContainer, TI.d028_Sine_Out, {BackgroundTransparency = 0}):Play()

    if config.ToggleKeybind then
        UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == config.ToggleKeybind then
                setUiVisible(not ScreenGui.Enabled)
            end
        end)
    end

    function Window:Toggle() setUiVisible(not ScreenGui.Enabled) end
    function Window:SetTitle(newTitle) TitleLabel.Text = newTitle end
    function Window:Minimize() setUiVisible(false) end
    function Window:Restore() setUiVisible(true) end

    function Window:SetIcon(icon)
        local letterLabel = RestoreBtn:FindFirstChild("LetterLabel")
        if letterLabel then letterLabel:Destroy() end
        RestoreBtn.Image = normalizeAssetId(icon)
        if RestoreBtn:FindFirstChildOfClass("UIPadding") == nil then
            local iconPad = Instance.new("UIPadding")
            iconPad.PaddingLeft = UDim.new(0, 8)
            iconPad.PaddingRight = UDim.new(0, 8)
            iconPad.PaddingTop = UDim.new(0, 8)
            iconPad.PaddingBottom = UDim.new(0, 8)
            iconPad.Parent = RestoreBtn
        end
    end

    local closeCallbacks = {}
    function Window:BindToClose(callback)
        if type(callback) == "function" then table.insert(closeCallbacks, callback) end
    end

    local activeWatermark, activeKeyList = nil, nil

    function Window:Destroy()
        local function finalize()
            for _, cb in ipairs(closeCallbacks) do
                pcall(cb)
            end
            if activeWatermark then pcall(function() activeWatermark:Destroy() end) end
            if activeKeyList then pcall(function() activeKeyList:Destroy() end) end
            if fpsConn then fpsConn:Disconnect() end
            ScreenGui:Destroy(); RestoreGui:Destroy(); NotifyGui:Destroy()
        end
        if ScreenGui.Enabled then
            local easeOut = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
            TweenService:Create(WindowScale, easeOut, {Scale = 0.9}):Play()
            TweenService:Create(Shadow, easeOut, {Position = hiddenShadowPos, ImageTransparency = 1}):Play()
            TweenService:Create(MainFrame, easeOut, {BackgroundTransparency = 1}):Play()
            TweenService:Create(mainStroke, easeOut, {Transparency = 1}):Play()
            TweenService:Create(MainContent, TweenInfo.new(0.16, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {GroupTransparency = 1}):Play()
            task.delay(0.22, finalize)
        else
            finalize()
        end
    end

    function Window:CreateWatermark(config)
        config = type(config) == "table" and config or {}

        local oldWM = UiParent:FindFirstChild("WatermarkGui")
        if oldWM then oldWM:Destroy() end

        local WatermarkGui = Instance.new("ScreenGui")
        WatermarkGui.Name = "WatermarkGui"
        WatermarkGui.ResetOnSpawn = false
        WatermarkGui.IgnoreGuiInset = true
        WatermarkGui.DisplayOrder = 999
        WatermarkGui.Parent = UiParent

        local Pill = Instance.new("Frame")
        Pill.Position = config.Position or UDim2.new(0, 12, 0, 12)
        Pill.Size = UDim2.new(0, 0, 0, 30)
        Pill.AutomaticSize = Enum.AutomaticSize.X
        applyThemeColor(Pill, "Element")
        Pill.Visible = config.Visible ~= false
        Pill.Parent = WatermarkGui
        corner(Pill, 8)
        stroke(Pill)

        local AccentDot = Instance.new("Frame")
        AccentDot.AnchorPoint = Vector2.new(0, 0.5)
        AccentDot.Size = UDim2.new(0, 6, 0, 6)
        AccentDot.Position = UDim2.new(0, 10, 0.5, 0)
        applyThemeColor(AccentDot, "AccentA")
        AccentDot.Parent = Pill
        corner(AccentDot, 3)
        accentGradient(AccentDot, 0)

        local Label = Instance.new("TextLabel")
        Label.BackgroundTransparency = 1
        Label.Position = UDim2.new(0, 24, 0, 0)
        Label.Size = UDim2.new(0, 0, 1, 0)
        Label.AutomaticSize = Enum.AutomaticSize.X
        Label.Font = Enum.Font.GothamSemibold
        Label.TextSize = 12
        applyThemeColor(Label, "Text", "TextColor3")
        Label.Text = config.Text or "SpectreWare"
        Label.Parent = Pill

        local Pad = Instance.new("UIPadding")
        Pad.PaddingRight = UDim.new(0, 12)
        Pad.Parent = Pill

        local heartbeatConn
        if config.ShowFPS or config.ShowPing then
            local frames, lastClock, fps = 0, os.clock(), 0
            local lastPing = nil
            local function refreshStatsText()
                local parts = {config.Text or "SpectreWare"}
                if config.ShowFPS then table.insert(parts, fps .. " FPS") end
                if config.ShowPing then
                    local ok, ping = pcall(function()
                        return math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue())
                    end)
                    if ok and ping then lastPing = ping end
                    table.insert(parts, (lastPing or "--") .. " ms")
                end
                Label.Text = table.concat(parts, "  •  ")
            end
            refreshStatsText()
            heartbeatConn = RunService.Heartbeat:Connect(function()
                frames = frames + 1
                local now = os.clock()
                if now - lastClock >= 1 then
                    fps, frames, lastClock = frames, 0, now
                    refreshStatsText()
                end
            end)
        end

        local Watermark = {}
        function Watermark:SetText(text)
            config.Text = text
            if not (config.ShowFPS or config.ShowPing) then Label.Text = text end
        end
        function Watermark:Show() Pill.Visible = true end
        function Watermark:Hide() Pill.Visible = false end
        function Watermark:Toggle() Pill.Visible = not Pill.Visible end
        function Watermark:Destroy()
            if heartbeatConn then heartbeatConn:Disconnect() end
            WatermarkGui:Destroy()
        end
        activeWatermark = Watermark
        return Watermark
    end

    function Window:CreateKeyList(config)
        config = type(config) == "table" and config or {}

        local oldKL = UiParent:FindFirstChild("KeyListGui")
        if oldKL then oldKL:Destroy() end

        local KeyListGui = Instance.new("ScreenGui")
        KeyListGui.Name = "KeyListGui"
        KeyListGui.ResetOnSpawn = false
        KeyListGui.IgnoreGuiInset = true
        KeyListGui.DisplayOrder = 997
        KeyListGui.Parent = UiParent

        local Holder = Instance.new("Frame")
        Holder.AnchorPoint = Vector2.new(1, 0.5)
        Holder.Position = config.Position or UDim2.new(1, -12, 0.5, 0)
        Holder.Size = UDim2.new(0, 176, 0, 0)
        Holder.AutomaticSize = Enum.AutomaticSize.Y
        applyThemeColor(Holder, "Element")
        Holder.Visible = config.Visible ~= false
        Holder.Parent = KeyListGui
        corner(Holder, 10)
        stroke(Holder)

        local Pad = Instance.new("UIPadding")
        Pad.PaddingLeft = UDim.new(0, 10); Pad.PaddingRight = UDim.new(0, 10)
        Pad.PaddingTop = UDim.new(0, 8); Pad.PaddingBottom = UDim.new(0, 8)
        Pad.Parent = Holder

        local Layout = Instance.new("UIListLayout")
        Layout.Padding = UDim.new(0, 4)
        Layout.Parent = Holder

        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(1, 0, 0, 18)
        Title.LayoutOrder = 0
        Title.BackgroundTransparency = 1
        Title.Text = config.Title or "KEYBINDS"
        Title.Font = Enum.Font.GothamBold
        Title.TextSize = 11
        applyThemeColor(Title, "SubText", "TextColor3")
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.Parent = Holder

        local rowConns = {}
        local KeyList = {}
        local itemCount = 0

        function KeyList:AddItem(item)
            item = type(item) == "table" and item or {}
            itemCount = itemCount + 1
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 20)
            Row.BackgroundTransparency = 1
            Row.LayoutOrder = itemCount
            Row.Parent = Holder

            local NameLbl = Instance.new("TextLabel")
            NameLbl.Size = UDim2.new(0.58, 0, 1, 0)
            NameLbl.BackgroundTransparency = 1
            NameLbl.Text = item.Text or "Action"
            NameLbl.Font = Enum.Font.Gotham
            NameLbl.TextSize = 12
            NameLbl.TextXAlignment = Enum.TextXAlignment.Left
            NameLbl.TextTruncate = Enum.TextTruncate.AtEnd
            applyThemeColor(NameLbl, "SubText", "TextColor3")
            NameLbl.Parent = Row

            local KeyLbl = Instance.new("TextLabel")
            KeyLbl.Size = UDim2.new(0.42, 0, 1, 0)
            KeyLbl.Position = UDim2.new(0.58, 0, 0, 0)
            KeyLbl.BackgroundTransparency = 1
            KeyLbl.Font = Enum.Font.GothamBold
            KeyLbl.TextSize = 12
            KeyLbl.TextXAlignment = Enum.TextXAlignment.Right
            applyThemeColor(KeyLbl, "AccentA", "TextColor3")
            KeyLbl.Parent = Row

            local function updateKey()
                local kc = Library.Flags[item.Flag]
                KeyLbl.Text = (kc and kc.Name) or "None"
            end
            updateKey()
            table.insert(rowConns, Library.FlagChanged.Event:Connect(function(changedFlag)
                if changedFlag == item.Flag then updateKey() end
            end))
        end

        for _, item in ipairs(config.Items or {}) do KeyList:AddItem(item) end

        function KeyList:Show() Holder.Visible = true end
        function KeyList:Hide() Holder.Visible = false end
        function KeyList:Destroy()
            for _, conn in ipairs(rowConns) do conn:Disconnect() end
            KeyListGui:Destroy()
        end
        activeKeyList = KeyList
        return KeyList
    end

    function Window:Alert(opts)
        opts = type(opts) == "table" and opts or {}
        local Overlay = Instance.new("Frame")
        Overlay.Size = UDim2.new(1, 0, 1, 0)
        Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Overlay.BackgroundTransparency = 1
        Overlay.Active = true
        Overlay.ZIndex = 50
        Overlay.Parent = ScreenGui

        local Box = Instance.new("Frame")
        Box.Size = UDim2.new(0, 280, 0, 150)
        Box.AnchorPoint = Vector2.new(0.5, 0.5)
        Box.Position = UDim2.new(0.5, 0, 0.5, 0)
        applyThemeColor(Box, "Background")
        Box.ZIndex = 51
        Box.Parent = Overlay
        corner(Box, 12)
        stroke(Box)

        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(1, -24, 0, 24)
        Title.Position = UDim2.new(0, 12, 0, 12)
        Title.BackgroundTransparency = 1
        Title.Text = opts.Title or "Alert"
        applyThemeColor(Title, "Text", "TextColor3")
        Title.Font = Enum.Font.GothamBold
        Title.TextSize = 15
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.ZIndex = 52
        Title.Parent = Box

        local Content = Instance.new("TextLabel")
        Content.Size = UDim2.new(1, -24, 0, 60)
        Content.Position = UDim2.new(0, 12, 0, 40)
        Content.BackgroundTransparency = 1
        Content.Text = opts.Content or ""
        applyThemeColor(Content, "SubText", "TextColor3")
        Content.Font = Enum.Font.Gotham
        Content.TextSize = 13
        Content.TextWrapped = true
        Content.TextXAlignment = Enum.TextXAlignment.Left
        Content.TextYAlignment = Enum.TextYAlignment.Top
        Content.ZIndex = 52
        Content.Parent = Box

        local OkBtn = Instance.new("TextButton")
        OkBtn.Size = UDim2.new(1, -24, 0, 36)
        OkBtn.Position = UDim2.new(0, 12, 1, -48)
        applyThemeColor(OkBtn, "AccentA")
        OkBtn.AutoButtonColor = false
        OkBtn.Text = opts.ButtonText or "OK"
        applyThemeColor(OkBtn, "Text", "TextColor3")
        OkBtn.Font = Enum.Font.GothamBold
        OkBtn.TextSize = 14
        OkBtn.ZIndex = 52
        OkBtn.Parent = Box
        corner(OkBtn, 9)
        applyPressAnimation(OkBtn, 0.95)

        TweenService:Create(Overlay, TI.d02_Sine_Out, {BackgroundTransparency = 1}):Play()

        local function closeAlert()
            TweenService:Create(Overlay, TI.d015_Sine_Out, {BackgroundTransparency = 1}):Play()
            task.delay(0.15, function() if Overlay then Overlay:Destroy() end end)
            if opts.Callback then opts.Callback() end
        end
        OkBtn.MouseButton1Click:Connect(closeAlert)
        return newElement(Overlay, nil, nil, closeAlert)
    end

    function Window:Confirm(opts)
        opts = type(opts) == "table" and opts or {}
        local Overlay = Instance.new("Frame")
        Overlay.Size = UDim2.new(1, 0, 1, 0)
        Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Overlay.BackgroundTransparency = 1
        Overlay.Active = true
        Overlay.ZIndex = 50
        Overlay.Parent = ScreenGui

        local Box = Instance.new("Frame")
        Box.Size = UDim2.new(0, 280, 0, 150)
        Box.AnchorPoint = Vector2.new(0.5, 0.5)
        Box.Position = UDim2.new(0.5, 0, 0.5, 0)
        applyThemeColor(Box, "Background")
        Box.ZIndex = 51
        Box.Parent = Overlay
        corner(Box, 12)
        stroke(Box)

        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(1, -24, 0, 24)
        Title.Position = UDim2.new(0, 12, 0, 12)
        Title.BackgroundTransparency = 1
        Title.Text = opts.Title or "Confirm"
        applyThemeColor(Title, "Text", "TextColor3")
        Title.Font = Enum.Font.GothamBold
        Title.TextSize = 15
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.ZIndex = 52
        Title.Parent = Box

        local Content = Instance.new("TextLabel")
        Content.Size = UDim2.new(1, -24, 0, 60)
        Content.Position = UDim2.new(0, 12, 0, 40)
        Content.BackgroundTransparency = 1
        Content.Text = opts.Content or ""
        applyThemeColor(Content, "SubText", "TextColor3")
        Content.Font = Enum.Font.Gotham
        Content.TextSize = 13
        Content.TextWrapped = true
        Content.TextXAlignment = Enum.TextXAlignment.Left
        Content.TextYAlignment = Enum.TextYAlignment.Top
        Content.ZIndex = 52
        Content.Parent = Box

        local CancelBtn = Instance.new("TextButton")
        CancelBtn.Size = UDim2.new(0.5, -18, 0, 36)
        CancelBtn.Position = UDim2.new(0, 12, 1, -48)
        applyThemeColor(CancelBtn, "Element")
        CancelBtn.AutoButtonColor = false
        CancelBtn.Text = opts.CancelText or "Cancel"
        applyThemeColor(CancelBtn, "SubText", "TextColor3")
        CancelBtn.Font = Enum.Font.GothamBold
        CancelBtn.TextSize = 13
        CancelBtn.ZIndex = 52
        CancelBtn.Parent = Box
        corner(CancelBtn, 9)
        applyPressAnimation(CancelBtn, 0.95)

        local ConfirmBtn = Instance.new("TextButton")
        ConfirmBtn.Size = UDim2.new(0.5, -18, 0, 36)
        ConfirmBtn.Position = UDim2.new(0.5, 6, 1, -48)
        applyThemeColor(ConfirmBtn, "AccentA")
        ConfirmBtn.AutoButtonColor = false
        ConfirmBtn.Text = opts.ConfirmText or "Confirm"
        applyThemeColor(ConfirmBtn, "Text", "TextColor3")
        ConfirmBtn.Font = Enum.Font.GothamBold
        ConfirmBtn.TextSize = 13
        ConfirmBtn.ZIndex = 52
        ConfirmBtn.Parent = Box
        corner(ConfirmBtn, 9)
        applyPressAnimation(ConfirmBtn, 0.95)

        TweenService:Create(Overlay, TI.d02_Sine_Out, {BackgroundTransparency = 1}):Play()

        local function close(result)
            TweenService:Create(Overlay, TI.d015_Sine_Out, {BackgroundTransparency = 1}):Play()
            task.delay(0.15, function() if Overlay then Overlay:Destroy() end end)
            if opts.Callback then opts.Callback(result) end
        end
        ConfirmBtn.MouseButton1Click:Connect(function() close(true) end)
        CancelBtn.MouseButton1Click:Connect(function() close(false) end)
        return newElement(Overlay, nil, nil, function() close(false) end)
    end

    function Window:CreateSettingsTab()
        local tab = Window:CreateTab("Settings", "settings")
        tab.Btn.LayoutOrder = 9999
        tab:CreateThemeDropdown()
        return tab
    end

    function Window:CreateTab(name, icon)
        local Tab = {}
        local TabBtn = Instance.new("TextButton")
        TabBtn.Size = UDim2.new(1, 0, 0, 36)
        applyThemeColor(TabBtn, "Element")
        TabBtn.BackgroundTransparency = 1
        TabBtn.AutoButtonColor = false
        TabBtn.Text = ""
        TabBtn.Parent = TabList
        tabOrderCounter = tabOrderCounter + 1
        TabBtn.LayoutOrder = tabOrderCounter
        corner(TabBtn, 8)
        applyPressAnimation(TabBtn, 0.96)
        ripple(TabBtn, "AccentA")

        local iconOffset = 10
        if icon then
            local IconImg = Instance.new("ImageLabel")
            IconImg.Size = UDim2.new(0, 18, 0, 18)
            IconImg.Position = UDim2.new(0, 10, 0.5, 0)
            IconImg.AnchorPoint = Vector2.new(0, 0.5)
            IconImg.BackgroundTransparency = 1
            IconImg.Image = Library.Icons[icon] or icon
            IconImg.ScaleType = Enum.ScaleType.Fit
            applyThemeColor(IconImg, "SubText", "ImageColor3")
            IconImg.Parent = TabBtn
            iconOffset = 36
        end

        local TabTitle = Instance.new("TextLabel")
        TabTitle.Size = UDim2.new(1, -iconOffset - 10, 1, 0)
        TabTitle.Position = UDim2.new(0, iconOffset, 0, 0)
        TabTitle.BackgroundTransparency = 1
        TabTitle.Text = name
        applyThemeColor(TabTitle, "SubText", "TextColor3")
        TabTitle.Font = Enum.Font.GothamSemibold
        TabTitle.TextSize = 13
        TabTitle.TextXAlignment = Enum.TextXAlignment.Left
        TabTitle.Parent = TabBtn

        local ActiveBar = Instance.new("Frame")
        ActiveBar.Size = UDim2.new(0, 3, 0, 0)
        ActiveBar.Position = UDim2.new(0, 0, 0.5, 0)
        ActiveBar.AnchorPoint = Vector2.new(0, 0.5)
        applyThemeColor(ActiveBar, "AccentA")
        ActiveBar.BorderSizePixel = 0
        ActiveBar.Parent = TabBtn
        corner(ActiveBar, 2)
        accentGradient(ActiveBar, 90)

        table.insert(allTabs, {btn = TabBtn, name = name})
        if TabSearchBox and TabSearchBox.Text ~= "" then
            TabBtn.Visible = string.find(name:lower(), TabSearchBox.Text:lower(), 1, true) ~= nil
        end

        TabBtn.MouseEnter:Connect(function()
            if CurrentTab and CurrentTab.Btn == TabBtn then return end
            TweenService:Create(TabBtn, TI.d015_Sine_Out, {BackgroundTransparency = 0.4, BackgroundColor3 = Theme.Element}):Play()
        end)
        TabBtn.MouseLeave:Connect(function()
            if CurrentTab and CurrentTab.Btn == TabBtn then return end
            TweenService:Create(TabBtn, TI.d015_Sine_Out, {BackgroundTransparency = 1}):Play()
        end)

        local TabContent = Instance.new("ScrollingFrame")
        TabContent.Size = UDim2.new(1, -20, 1, -20)
        TabContent.Position = UDim2.new(0, 10, 0, 10)
        TabContent.BackgroundTransparency = 1
        TabContent.ScrollBarThickness = 2
        applyThemeColor(TabContent, "AccentA", "ScrollBarImageColor3")
        TabContent.Visible = false
        TabContent.Active = true
        TabContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
        TabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
        TabContent.Parent = ContentArea
        local ContentLayout = Instance.new("UIListLayout")
        ContentLayout.Padding = UDim.new(0, 8)
        ContentLayout.Parent = TabContent

        -- ค่าตำแหน่ง/สเกลตั้งต้นของเนื้อหาแท็บ ใช้ตอนสลับแท็บให้เด้งเข้ามาสวยๆ
        -- (แค่ Tween ตอนคลิกครั้งเดียว ไม่มี loop ต่อเนื่อง เลยไม่กินเฟรมเรต)
        local ContentBasePos = TabContent.Position
        local ContentScale = Instance.new("UIScale")
        ContentScale.Parent = TabContent

        local function setActive(active)
            TweenService:Create(TabBtn, TI.d018_Sine_Out, {
                BackgroundTransparency = active and 0.85 or 1,
                BackgroundColor3 = active and Theme.AccentA or Theme.Element
            }):Play()
            TweenService:Create(ActiveBar, TI.d018_Sine_Out, {Size = UDim2.new(0, 3, 0, active and 20 or 0)}):Play()
            TabTitle.TextColor3 = active and Theme.Text or Theme.SubText
            if icon then
                local iconImg = TabBtn:FindFirstChildOfClass("ImageLabel")
                if iconImg then
                    TweenService:Create(iconImg, TI.d018_Sine_Out, {ImageColor3 = active and Theme.Text or Theme.SubText}):Play()
                end
            end
        end

        TabBtn.MouseButton1Click:Connect(function()
            closeActivePopup()
            for _, t in ipairs(Tabs) do
                local isThis = (t.Btn == TabBtn)
                t.SetActive(isThis)
                if isThis then
                    if not t.Content.Visible then
                        -- เด้งขึ้นมาจากด้านล่างนิดๆ พร้อม pop สเกล ให้รู้สึกลื่นไหลตอนสลับแท็บ
                        t.Content.Position = t.BasePos + UDim2.new(0, 0, 0, 12)
                        t.Scale.Scale = 0.96
                        t.Content.Visible = true
                        TweenService:Create(t.Content, TI.d02_Back_Out, {Position = t.BasePos}):Play()
                        TweenService:Create(t.Scale, TI.d02_Back_Out, {Scale = 1}):Play()
                    end
                else
                    t.Content.Visible = false
                end
            end
            CurrentTab = {Btn = TabBtn, Content = TabContent, SetActive = setActive}
        end)

        local function bindFlag(flag, value)
            if not flag then return end
            Library.Flags[flag] = value
            Library.FlagChanged:Fire(flag, value)
        end

        function Tab:CreateSection(title)
            local Holder = Instance.new("Frame")
            Holder.Size = UDim2.new(1, 0, 0, 22)
            Holder.BackgroundTransparency = 1
            Holder.Parent = TabContent
            local Line = Instance.new("Frame")
            Line.Size = UDim2.new(0, 3, 0, 12)
            Line.Position = UDim2.new(0, 0, 0, 5)
            applyThemeColor(Line, "AccentA")
            Line.BorderSizePixel = 0
            Line.Parent = Holder
            corner(Line, 2)
            accentGradient(Line, 90)
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -10, 0, 16)
            Label.Position = UDim2.new(0, 10, 0, 3)
            Label.BackgroundTransparency = 1
            Label.Text = string.upper(title or "Section")
            applyThemeColor(Label, "SubText", "TextColor3")
            Label.Font = Enum.Font.GothamBold
            Label.TextSize = 11
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Holder
            return newElement(Holder)
        end

        function Tab:CreateDivider(c)
            c = type(c) == "table" and c or {}
            local Holder = Instance.new("Frame")
            Holder.Size = UDim2.new(1, 0, 0, 20)
            Holder.BackgroundTransparency = 1
            Holder.Parent = TabContent
            local Line = Instance.new("Frame")
            Line.Size = UDim2.new(1, 0, 0, 1)
            Line.Position = UDim2.new(0, 0, 0.5, 0)
            applyThemeColor(Line, "Stroke")
            Line.BorderSizePixel = 0
            Line.Parent = Holder
            return newElement(Holder)
        end

        function Tab:CreateParagraph(c)
            c = type(c) == "table" and c or {}
            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, 0, 0, 0)
            Frame.AutomaticSize = Enum.AutomaticSize.Y
            applyThemeColor(Frame, "Element")
            Frame.Parent = TabContent
            corner(Frame, 9)
            applyGlowOnHover(Frame)

            local Pad = Instance.new("UIPadding")
            Pad.PaddingLeft = UDim.new(0, 10)
            Pad.PaddingRight = UDim.new(0, 10)
            Pad.PaddingTop = UDim.new(0, 8)
            Pad.PaddingBottom = UDim.new(0, 8)
            Pad.Parent = Frame

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, 0, 0, 0)
            Label.AutomaticSize = Enum.AutomaticSize.Y
            Label.BackgroundTransparency = 1
            Label.Text = c.Text or "Paragraph"
            applyThemeColor(Label, "SubText", "TextColor3")
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 13
            Label.TextWrapped = true
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Frame
            return newElement(Frame, function() return Label.Text end, function(_, newText) Label.Text = newText end)
        end

        -- ============ Accordion: หัวข้อกดขยาย/ย่อ พร้อมลูกศรหมุนและความสูงเด้งสปริง ============
        function Tab:CreateAccordion(c)
            c = type(c) == "table" and c or {}
            local expanded = c.Expanded or false

            local Holder = Instance.new("Frame")
            Holder.Size = UDim2.new(1, 0, 0, 40)
            applyThemeColor(Holder, "Element")
            Holder.ClipsDescendants = true
            Holder.Parent = TabContent
            corner(Holder, 9)
            applyGlowOnHover(Holder)

            local Header = Instance.new("TextButton")
            Header.Size = UDim2.new(1, 0, 0, 40)
            Header.BackgroundTransparency = 1
            Header.AutoButtonColor = false
            Header.Text = ""
            Header.Parent = Holder
            ripple(Header, "AccentA")

            local Arrow = Instance.new("ImageLabel")
            Arrow.Size = UDim2.new(0, 14, 0, 14)
            Arrow.Position = UDim2.new(1, -22, 0, 13)
            Arrow.BackgroundTransparency = 1
            Arrow.Image = "rbxassetid://6031091004"
            applyThemeColor(Arrow, "SubText", "ImageColor3")
            Arrow.Rotation = expanded and 180 or 0
            Arrow.Parent = Header

            local TitleLbl = Instance.new("TextLabel")
            TitleLbl.Size = UDim2.new(1, -46, 0, 40)
            TitleLbl.Position = UDim2.new(0, 12, 0, 0)
            TitleLbl.BackgroundTransparency = 1
            TitleLbl.Text = c.Title or "Accordion"
            applyThemeColor(TitleLbl, "Text", "TextColor3")
            TitleLbl.Font = Enum.Font.GothamSemibold
            TitleLbl.TextSize = 14
            TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
            TitleLbl.Parent = Header

            local Body = Instance.new("TextLabel")
            Body.Size = UDim2.new(1, -24, 0, 0)
            Body.Position = UDim2.new(0, 12, 0, 40)
            Body.BackgroundTransparency = 1
            Body.Text = c.Content or ""
            applyThemeColor(Body, "SubText", "TextColor3")
            Body.Font = Enum.Font.Gotham
            Body.TextSize = 13
            Body.TextWrapped = true
            Body.TextXAlignment = Enum.TextXAlignment.Left
            Body.TextYAlignment = Enum.TextYAlignment.Top
            Body.TextTransparency = 1
            Body.Parent = Holder

            local bodyHeight = 0
            local function setExpanded(newExpanded, animate)
                expanded = newExpanded
                Body.Size = UDim2.new(1, -24, 0, bodyHeight)
                local targetH = expanded and (48 + bodyHeight) or 40
                local tw = animate ~= false and TI.d028_Back_Out_Wobble or TweenInfo.new(0)
                TweenService:Create(Holder, tw, {Size = UDim2.new(1, 0, 0, targetH)}):Play()
                TweenService:Create(Arrow, TI.d022_Sine_Out, {Rotation = expanded and 180 or 0}):Play()
                TweenService:Create(Body, TI.d022_Sine_Out, {TextTransparency = expanded and 0 or 1}):Play()
            end

            task.defer(function()
                bodyHeight = Body.TextBounds.Y + 6
                setExpanded(expanded, false)
            end)

            Header.MouseButton1Click:Connect(function() setExpanded(not expanded, true) end)
            return newElement(Holder, function() return expanded end, function(_, v) setExpanded(v, true) end)
        end

        -- ============ Segmented Control: ปุ่มเลือกตัวเลือกแบบแคปซูล มีแท่งไฮไลต์เลื่อนตามสปริง ============
        function Tab:CreateSegmentedControl(c)
            c = type(c) == "table" and c or {}
            local options = c.Options or {"A", "B"}
            local selected = math.clamp(c.Default or 1, 1, #options)
            bindFlag(c.Flag, options[selected])

            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, 0, 0, c.Text and 62 or 38)
            applyThemeColor(Frame, "Element")
            Frame.Parent = TabContent
            corner(Frame, 9)

            local yOffset = 0
            if c.Text then
                local Label = Instance.new("TextLabel")
                Label.Size = UDim2.new(1, -24, 0, 18)
                Label.Position = UDim2.new(0, 12, 0, 6)
                Label.BackgroundTransparency = 1
                Label.Text = c.Text
                applyThemeColor(Label, "SubText", "TextColor3")
                Label.Font = Enum.Font.GothamSemibold
                Label.TextSize = 12
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.Parent = Frame
                yOffset = 24
            end

            local Track = Instance.new("Frame")
            Track.Size = UDim2.new(1, -12, 0, 30)
            Track.Position = UDim2.new(0, 6, 0, yOffset + 4)
            applyThemeColor(Track, "Background")
            Track.Parent = Frame
            corner(Track, 8)

            local Pill = Instance.new("Frame")
            Pill.Size = UDim2.new(1 / #options, 0, 1, 0)
            Pill.Position = UDim2.new((selected - 1) / #options, 0, 0, 0)
            applyThemeColor(Pill, "AccentA")
            Pill.ZIndex = 1
            Pill.Parent = Track
            corner(Pill, 7)
            accentGradient(Pill, 0)

            local buttons = {}
            for i, optText in ipairs(options) do
                local OptBtn = Instance.new("TextButton")
                OptBtn.Size = UDim2.new(1 / #options, 0, 1, 0)
                OptBtn.Position = UDim2.new((i - 1) / #options, 0, 0, 0)
                OptBtn.BackgroundTransparency = 1
                OptBtn.AutoButtonColor = false
                OptBtn.Text = tostring(optText)
                OptBtn.Font = Enum.Font.GothamSemibold
                OptBtn.TextSize = 12
                OptBtn.ZIndex = 2
                applyThemeColor(OptBtn, i == selected and "Text" or "SubText", "TextColor3")
                OptBtn.Parent = Track
                buttons[i] = OptBtn
            end

            local function setSelected(i, fireCallback)
                selected = i
                bindFlag(c.Flag, options[i])
                TweenService:Create(Pill, TI.d028_Back_Out_Wobble, {Position = UDim2.new((i - 1) / #options, 0, 0, 0)}):Play()
                for idx, btn in ipairs(buttons) do
                    TweenService:Create(btn, TI.d018_Sine_Out, {TextColor3 = idx == i and Theme.Text or Theme.SubText}):Play()
                end
                if fireCallback then safeCallback(c.Callback, options[i], i) end
            end

            for i, btn in ipairs(buttons) do
                btn.MouseButton1Click:Connect(function() setSelected(i, true) end)
            end

            return newElement(Frame, function() return options[selected] end, function(_, v)
                for i, o in ipairs(options) do
                    if o == v then setSelected(i, true) break end
                end
            end, nil, c.Flag)
        end

        function Tab:CreateButton(c)
            c = type(c) == "table" and c or {}
            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, 0, 0, 40)
            applyThemeColor(Btn, "Element")
            Btn.AutoButtonColor = false
            Btn.Text = ""
            Btn.Parent = TabContent
            corner(Btn, 9)
            applyHoverEffect(Btn, "Element", "ElementHover")
            applyGlowOnHover(Btn)
            applyPressAnimation(Btn)
            ripple(Btn, "AccentA")

            local iconOffset = 12
            if c.Icon then
                local IconImg = Instance.new("ImageLabel")
                IconImg.Size = UDim2.new(0, 18, 0, 18)
                IconImg.Position = UDim2.new(0, 12, 0.5, 0)
                IconImg.AnchorPoint = Vector2.new(0, 0.5)
                IconImg.BackgroundTransparency = 1
                IconImg.Image = Library.Icons[c.Icon] or c.Icon
                IconImg.ScaleType = Enum.ScaleType.Fit
                applyThemeColor(IconImg, "SubText", "ImageColor3")
                IconImg.Parent = Btn
                iconOffset = 38
            end

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -iconOffset - 12, 1, 0)
            Label.Position = UDim2.new(0, iconOffset, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = c.Text or "Button"
            applyThemeColor(Label, "Text", "TextColor3")
            Label.Font = Enum.Font.GothamSemibold
            Label.TextSize = 14
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Btn

            local debounceUntil = 0
            Btn.MouseButton1Click:Connect(function()
                local now = os.clock()
                if now < debounceUntil then return end
                debounceUntil = now + (c.Debounce or 0.3)

                if c.Notify ~= false then
                    Library:Notify({
                        Title = c.Text or "Button",
                        Content = c.NotifyText or "กดใช้งานเรียบร้อย",
                        Type = "info",
                        Duration = 1.5
                    })
                end
                safeCallback(c.Callback)
            end)
            return newElement(Btn, nil, function(_, newText) Label.Text = newText end)
        end

        function Tab:CreateToggle(c)
            c = type(c) == "table" and c or {}
            local state = c.Default or false
            bindFlag(c.Flag, state)

            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, 0, 0, 40)
            applyThemeColor(Frame, "Element")
            Frame.Active = true
            Frame.Parent = TabContent
            corner(Frame, 9)
            applyGlowOnHover(Frame)

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -60, 1, 0)
            Label.Position = UDim2.new(0, 12, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = c.Text or "Toggle"
            applyThemeColor(Label, "Text", "TextColor3")
            Label.Font = Enum.Font.GothamSemibold
            Label.TextSize = 14
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Frame

            local Switch = Instance.new("TextButton")
            Switch.Size = UDim2.new(0, 40, 0, 20)
            Switch.Position = UDim2.new(1, -52, 0.5, -10)
            applyThemeColor(Switch, state and "AccentA" or "ToggleOff")
            Switch.AutoButtonColor = false
            Switch.Text = ""
            Switch.Parent = Frame
            corner(Switch, 10)
            applyPressAnimation(Switch, 0.85)
            ripple(Switch, "AccentA")
            local switchGrad = accentGradient(Switch, 0)
            switchGrad.Transparency = NumberSequence.new(1)

            local switchGradProxy = Instance.new("NumberValue")
            switchGradProxy.Value = 1
            switchGradProxy:GetPropertyChangedSignal("Value"):Connect(function()
                switchGrad.Transparency = NumberSequence.new(switchGradProxy.Value)
            end)

            local Circle = Instance.new("Frame")
            Circle.Size = UDim2.new(0, 16, 0, 16)
            Circle.Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Circle.Parent = Switch
            corner(Circle, 8)

            local function applyState(newState, fireCallback)
                state = newState
                bindFlag(c.Flag, state)
                TweenService:Create(Switch, TI.d015_Sine_Out, {BackgroundColor3 = state and Theme.AccentA or Theme.ToggleOff}):Play()
                TweenService:Create(switchGradProxy, TI.d015_Sine_Out, {Value = state and 0 or 1}):Play()
                -- ลูกบิดยืด-หด (squash & stretch) ก่อนเด้งไปตำแหน่งใหม่แบบสปริง ให้ความรู้สึก "หนึบ" ขึ้น
                local targetPos = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                TweenService:Create(Circle, TweenInfo.new(0.09, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = UDim2.new(0, 21, 0, 15)}):Play()
                TweenService:Create(Circle, TI.d028_Back_Out_Wobble, {Position = targetPos}):Play()
                task.delay(0.09, function()
                    if Circle.Parent then
                        TweenService:Create(Circle, TI.d028_Back_Out_Wobble, {Size = UDim2.new(0, 16, 0, 16)}):Play()
                    end
                end)
                if state then
                    pulseRing(Switch, "AccentA", 10)
                end
                if fireCallback then
                    if c.Notify ~= false then
                        Library:Notify({
                            Title = c.Text or "Toggle",
                            Content = state and (c.NotifyOnText or "เปิดใช้งานแล้ว") or (c.NotifyOffText or "ปิดใช้งานแล้ว"),
                            Type = state and "success" or "warning",
                            Duration = 1.5
                        })
                    end
                    safeCallback(c.Callback, state)
                end
            end
            applyState(state, false)

            Switch.MouseButton1Click:Connect(function() applyState(not state, true) end)
            return newElement(Frame, function() return state end, function(_, newState) applyState(newState, true) end, nil, c.Flag)
        end

        function Tab:CreateSlider(c)
            c = type(c) == "table" and c or {}
            local min, max = c.Min or 0, c.Max or 100
            local places = c.Places or 0
            local suffix = c.Suffix or ""
            local val = math.clamp(c.Default or min, min, max)
            bindFlag(c.Flag, val)

            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, 0, 0, 50)
            applyThemeColor(Frame, "Element")
            Frame.Active = true
            Frame.Parent = TabContent
            corner(Frame, 9)
            applyGlowOnHover(Frame)

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -20, 0, 20)
            Label.Position = UDim2.new(0, 10, 0, 5)
            Label.BackgroundTransparency = 1
            Label.Text = (c.Text or "Slider") .. ": " .. string.format("%." .. places .. "f", val) .. suffix
            applyThemeColor(Label, "Text", "TextColor3")
            Label.Font = Enum.Font.GothamSemibold
            Label.TextSize = 14
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Frame

            local Bar = Instance.new("Frame")
            Bar.Size = UDim2.new(1, -20, 0, 8)
            Bar.Position = UDim2.new(0, 10, 0, 33)
            applyThemeColor(Bar, "Background")
            Bar.Active = true
            Bar.Parent = Frame
            corner(Bar, 4)

            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
            applyThemeColor(Fill, "AccentA")
            Fill.Parent = Bar
            corner(Fill, 4)
            accentGradient(Fill, 0)

            local Handle = Instance.new("Frame")
            Handle.Size = UDim2.new(0, 14, 0, 14)
            Handle.AnchorPoint = Vector2.new(1, 0.5)
            Handle.Position = UDim2.new(1, 0, 0.5, 0)
            Handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Handle.Parent = Fill
            corner(Handle, 7)

            local dragging, activeType = false, nil
            local function updateFromPos(xPos, fireCallback)
                local pos = xPos - Bar.AbsolutePosition.X
                local percent = math.clamp(pos / Bar.AbsoluteSize.X, 0, 1)
                local value = min + (max - min) * percent
                value = math.floor(value * (10 ^ places)) / (10 ^ places)
                Fill.Size = UDim2.new(percent, 0, 1, 0)
                Label.Text = (c.Text or "Slider") .. ": " .. string.format("%." .. places .. "f", value) .. suffix
                val = value
                bindFlag(c.Flag, val)
                if fireCallback then safeCallback(c.Callback, value) end
            end

            -- Render-synced: a fast drag can raise several InputChanged events between
            -- two rendered frames, and each one previously re-ran Fill.Size, the
            -- string.format label rebuild, and the user's Callback in full. Coalescing
            -- to "latest position wins, applied once per frame" removes that redundant
            -- work without changing what the drag ends up producing.
            local sliderPush, sliderRSStart, sliderRSStop = createRenderSyncedDrag(function(xPos)
                updateFromPos(xPos, true)
            end)

            local inputChangedConn, inputEndedConn = nil, nil
            local function stopSliderDrag()
                dragging = false; activeType = nil
                TabContent.ScrollingEnabled = true
                if inputChangedConn then inputChangedConn:Disconnect(); inputChangedConn = nil end
                if inputEndedConn then inputEndedConn:Disconnect(); inputEndedConn = nil end
                sliderRSStop()
            end

            Bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    activeType = input.UserInputType
                    TabContent.ScrollingEnabled = false
                    updateFromPos(input.Position.X, true)
                    sliderRSStart()

                    inputChangedConn = UserInputService.InputChanged:Connect(function(input2)
                        if not dragging then return end
                        if activeType == Enum.UserInputType.Touch and input2.UserInputType == Enum.UserInputType.Touch then
                            sliderPush(input2.Position.X)
                        elseif activeType == Enum.UserInputType.MouseButton1 and input2.UserInputType == Enum.UserInputType.MouseMovement then
                            sliderPush(input2.Position.X)
                        end
                    end)
                    inputEndedConn = UserInputService.InputEnded:Connect(function(input2)
                        if dragging and input2.UserInputType == activeType then
                            stopSliderDrag()
                        end
                    end)
                end
            end)
            Bar.InputEnded:Connect(function(input)
                if input.UserInputType == activeType then
                    stopSliderDrag()
                end
            end)

            return newElement(Frame, function() return val end, function(_, newVal)
                newVal = math.clamp(newVal, min, max)
                local percent = (newVal - min) / (max - min)
                updateFromPos(Bar.AbsolutePosition.X + percent * Bar.AbsoluteSize.X, true)
            end, nil, c.Flag)
        end

        function Tab:CreateDropdown(c)
            c = type(c) == "table" and c or {}
            c.Options = (type(c.Options) == "table" and #c.Options > 0) and c.Options or {"Option 1"}
            local selected = c.Default or c.Options[1]
            bindFlag(c.Flag, selected)

            local Drop = Instance.new("TextButton")
            Drop.Size = UDim2.new(1, 0, 0, 44)
            applyThemeColor(Drop, "Element")
            Drop.AutoButtonColor = false
            Drop.Text = ""
            Drop.ClipsDescendants = false
            Drop.Parent = TabContent
            corner(Drop, 12)
            applyHoverEffect(Drop, "Element", "ElementHover")
            applyGlowOnHover(Drop)
            local dropStroke = stroke(Drop)
            dropStroke.Thickness = 1.2
            dropStroke.Transparency = 0.75

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -44, 1, 0)
            Label.Position = UDim2.new(0, 16, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = (c.Text or "Dropdown") .. ": " .. selected
            applyThemeColor(Label, "Text", "TextColor3")
            Label.Font = Enum.Font.GothamSemibold
            Label.TextSize = 14
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.TextTruncate = Enum.TextTruncate.AtEnd
            Label.Parent = Drop

            local ArrowWrap = Instance.new("Frame")
            ArrowWrap.Size = UDim2.new(0, 18, 0, 18)
            ArrowWrap.Position = UDim2.new(1, -32, 0.5, 0)
            ArrowWrap.AnchorPoint = Vector2.new(0, 0.5)
            ArrowWrap.BackgroundTransparency = 1
            ArrowWrap.Parent = Drop

            local Arrow = Instance.new("ImageLabel")
            Arrow.Size = UDim2.new(1, 0, 1, 0)
            Arrow.AnchorPoint = Vector2.new(0.5, 0.5)
            Arrow.Position = UDim2.new(0.5, 0, 0.5, 0)
            Arrow.BackgroundTransparency = 1
            Arrow.Image = Library.Icons.chevronDown
            applyThemeColor(Arrow, "SubText", "ImageColor3")
            Arrow.ScaleType = Enum.ScaleType.Fit
            Arrow.Parent = ArrowWrap

            local isOpen, list, shadow, outsideConn = false, nil, nil, nil
            local function closeDropdown()
                if list then
                    isOpen = false
                    local closingList, closingShadow = list, shadow
                    list, shadow = nil, nil
                    TweenService:Create(dropStroke, TI.d015_Sine_Out, {Transparency = 0.75}):Play()
                    TweenService:Create(Arrow, TI.d018_Sine_Out, {Rotation = 0}):Play()
                    local t = TweenService:Create(closingList, TI.d015_Quint_In, {
                        Size = UDim2.new(closingList.Size.X.Scale, closingList.Size.X.Offset, 0, 0),
                        BackgroundTransparency = 1
                    })
                    if closingShadow then
                        TweenService:Create(closingShadow, TI.d015_Sine_Out, {ImageTransparency = 1}):Play()
                        task.delay(0.15, function() closingShadow:Destroy() end)
                    end
                    t:Play()
                    t.Completed:Connect(function() closingList:Destroy() end)
                end
                if outsideConn then outsideConn:Disconnect(); outsideConn = nil end
            end
            local function selectOption(opt, fireCallback)
                selected = opt
                Label.Text = (c.Text or "Dropdown") .. ": " .. opt
                bindFlag(c.Flag, selected)
                closeDropdown()
                if fireCallback then safeCallback(c.Callback, opt) end
            end
            local function openDropdown()
                closeActivePopup()
                isOpen = true
                TweenService:Create(dropStroke, TI.d015_Sine_Out, {Transparency = 0.15}):Play()
                TweenService:Create(Arrow, TI.d02_Back_Out, {Rotation = 180}):Play()

                local itemH, gap, pad = 38, 6, 8
                local maxVisible = 5
                -- ช่องค้นหา: เปิดอัตโนมัติถ้าตัวเลือกเยอะ (>6) หรือบังคับเปิด/ปิดได้ผ่าน c.Searchable
                local searchable = c.Searchable
                if searchable == nil then searchable = #c.Options > 6 end
                local searchH = searchable and 40 or 0

                local contentH = #c.Options * itemH + math.max(#c.Options - 1, 0) * gap
                local optionsAreaH = math.min(contentH, maxVisible * itemH + (maxVisible - 1) * gap)
                local fullH = pad * 2 + searchH + optionsAreaH
                local needsScroll = #c.Options > maxVisible

                local popupX, edgeY, openUp = resolveFloatingPosition(Drop.AbsolutePosition, Drop.AbsoluteSize, Drop.AbsoluteSize.X, fullH, 6)
                local anchorPoint = Vector2.new(0, openUp and 1 or 0)
                local shadowEdgeY = edgeY + (openUp and 14 or -14)

                shadow = Instance.new("ImageLabel")
                shadow.Name = "DropShadow"
                shadow.BackgroundTransparency = 1
                shadow.Image = "rbxassetid://5028857084"
                shadow.ImageColor3 = Color3.new(0, 0, 0)
                shadow.ImageTransparency = 1
                shadow.ScaleType = Enum.ScaleType.Slice
                shadow.SliceCenter = Rect.new(24, 24, 276, 276)
                shadow.ZIndex = 9
                shadow.Parent = ScreenGui
                shadow.AnchorPoint = anchorPoint
                shadow.Position = UDim2.new(0, popupX - 14, 0, shadowEdgeY)
                shadow.Size = UDim2.new(0, Drop.AbsoluteSize.X + 28, 0, 28)
                TweenService:Create(shadow, TI.d018_Sine_Out, {ImageTransparency = 0.55}):Play()

                -- Popup การ์ดหลัก (ครอบทั้งช่องค้นหา + รายการตัวเลือก ให้ดูเป็นชิ้นเดียวกัน)
                list = Instance.new("Frame")
                list.Size = UDim2.new(0, Drop.AbsoluteSize.X, 0, 0)
                list.AnchorPoint = anchorPoint
                list.Position = UDim2.new(0, popupX, 0, edgeY)
                applyThemeColor(list, "Element")
                list.BackgroundTransparency = 1
                list.ClipsDescendants = true
                list.ZIndex = 10
                list.Active = true
                list.Parent = ScreenGui
                corner(list, 14)
                local listGrad = Instance.new("UIGradient")
                listGrad.Rotation = 90
                listGrad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.06)})
                listGrad.Parent = list
                local listStroke = stroke(list, "AccentA")
                listStroke.Thickness = 1
                listStroke.Transparency = 0.7

                -- ============ ช่องค้นหา (sticky อยู่บนสุด ไม่เลื่อนตามรายการ) ============
                local SearchBox
                if searchable then
                    local SearchWrap = Instance.new("Frame")
                    SearchWrap.Size = UDim2.new(1, -pad * 2, 0, searchH - 8)
                    SearchWrap.Position = UDim2.new(0, pad, 0, pad)
                    applyThemeColor(SearchWrap, "Background")
                    SearchWrap.BackgroundTransparency = 0.15
                    SearchWrap.ClipsDescendants = true
                    SearchWrap.ZIndex = 11
                    SearchWrap.Parent = list
                    corner(SearchWrap, 12) -- โค้งมนแบบแคปซูล
                    local swStroke = stroke(SearchWrap)
                    swStroke.Thickness = 1
                    swStroke.Transparency = 0.7
                    -- แถบเรืองแสงสีธีม ซ้อนอยู่เหนือกรอบปกติ โผล่มาตอน focus
                    local swGlow = stroke(SearchWrap, "AccentA", 1.2)
                    swGlow.Transparency = 1
                    local swSheen = Instance.new("UIGradient")
                    swSheen.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255))
                    swSheen.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.93), NumberSequenceKeypoint.new(1, 1)})
                    swSheen.Rotation = 90
                    swSheen.Parent = SearchWrap
                    local swScale = Instance.new("UIScale")
                    swScale.Parent = SearchWrap

                    local SearchIcon = Instance.new("ImageLabel")
                    SearchIcon.Size = UDim2.new(0, 13, 0, 13)
                    SearchIcon.AnchorPoint = Vector2.new(0, 0.5)
                    SearchIcon.Position = UDim2.new(0, 11, 0.5, 0)
                    SearchIcon.BackgroundTransparency = 1
                    SearchIcon.ImageTransparency = 0.2
                    SearchIcon.Image = Library.Icons.search
                    applyThemeColor(SearchIcon, "SubText", "ImageColor3")
                    SearchIcon.ScaleType = Enum.ScaleType.Fit
                    SearchIcon.ZIndex = 12
                    SearchIcon.Parent = SearchWrap

                    SearchBox = Instance.new("TextBox")
                    SearchBox.Position = UDim2.new(0, 31, 0, 0)
                    SearchBox.Size = UDim2.new(1, -58, 1, 0)
                    SearchBox.BackgroundTransparency = 1
                    SearchBox.Text = ""
                    SearchBox.PlaceholderText = "ค้นหา..."
                    applyThemeColor(SearchBox, "Text", "TextColor3")
                    applyThemeColor(SearchBox, "SubText", "PlaceholderColor3")
                    SearchBox.Font = Enum.Font.GothamSemibold
                    SearchBox.TextSize = 12.5
                    SearchBox.ClearTextOnFocus = false
                    SearchBox.TextXAlignment = Enum.TextXAlignment.Left
                    SearchBox.ZIndex = 12
                    SearchBox.Parent = SearchWrap

                    -- ปุ่มล้างคำค้นหา (X) โผล่มาเมื่อมีข้อความ
                    local SearchClear = Instance.new("ImageButton")
                    SearchClear.AnchorPoint = Vector2.new(1, 0.5)
                    SearchClear.Position = UDim2.new(1, -8, 0.5, 0)
                    SearchClear.Size = UDim2.new(0, 16, 0, 16)
                    SearchClear.BackgroundTransparency = 1
                    SearchClear.AutoButtonColor = false
                    SearchClear.Image = Library.Icons.close
                    applyThemeColor(SearchClear, "SubText", "ImageColor3")
                    SearchClear.ImageTransparency = 1
                    SearchClear.ScaleType = Enum.ScaleType.Fit
                    SearchClear.ZIndex = 12
                    SearchClear.Parent = SearchWrap
                    SearchClear.MouseButton1Click:Connect(function()
                        SearchBox.Text = ""
                        SearchBox:CaptureFocus()
                    end)

                    SearchBox.Focused:Connect(function()
                        TweenService:Create(swStroke, TI.d015_Sine_Out, {Transparency = 0.3}):Play()
                        TweenService:Create(swGlow, TI.d02_Sine_Out, {Transparency = 0.35}):Play()
                        TweenService:Create(SearchWrap, TI.d015_Sine_Out, {BackgroundTransparency = 0}):Play()
                        TweenService:Create(SearchIcon, TI.d015_Sine_Out, {ImageTransparency = 0}):Play()
                        TweenService:Create(swScale, TI.d02_Back_Out, {Scale = 1.015}):Play()
                    end)
                    SearchBox.FocusLost:Connect(function()
                        TweenService:Create(swStroke, TI.d015_Sine_Out, {Transparency = 0.7}):Play()
                        TweenService:Create(swGlow, TI.d015_Sine_Out, {Transparency = 1}):Play()
                        TweenService:Create(SearchWrap, TI.d015_Sine_Out, {BackgroundTransparency = 0.15}):Play()
                        TweenService:Create(SearchIcon, TI.d015_Sine_Out, {ImageTransparency = 0.2}):Play()
                        TweenService:Create(swScale, TI.d02_Back_Out, {Scale = 1}):Play()
                    end)
                    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                        TweenService:Create(SearchClear, TI.d012_Sine_Out, {ImageTransparency = SearchBox.Text == "" and 1 or 0.1}):Play()
                    end)
                end

                -- ============ พื้นที่รายการตัวเลือก ============
                local scrollWrap = Instance.new(needsScroll and "ScrollingFrame" or "Frame")
                scrollWrap.Size = UDim2.new(1, -pad * 2, 1, -(pad * 2 + searchH))
                scrollWrap.Position = UDim2.new(0, pad, 0, pad + searchH)
                scrollWrap.BackgroundTransparency = 1
                scrollWrap.ZIndex = 11
                scrollWrap.Parent = list
                if needsScroll then
                    scrollWrap.ScrollBarThickness = 3
                    scrollWrap.ScrollBarImageTransparency = 0.4
                    applyThemeColor(scrollWrap, "AccentA", "ScrollBarImageColor3")
                    scrollWrap.CanvasSize = UDim2.new(0, 0, 0, contentH)
                    scrollWrap.BorderSizePixel = 0
                end

                local inner = Instance.new("Frame")
                inner.Size = UDim2.new(1, 0, 1, 0)
                inner.BackgroundTransparency = 1
                inner.ZIndex = 11
                inner.Parent = scrollWrap
                local innerLayout = Instance.new("UIListLayout")
                innerLayout.Padding = UDim.new(0, gap)
                innerLayout.Parent = inner

                -- ข้อความ "ไม่พบผลลัพธ์" ตอนค้นหาแล้วไม่เจอ
                local emptyLbl = Instance.new("TextLabel")
                emptyLbl.Size = UDim2.new(1, 0, 1, 0)
                emptyLbl.BackgroundTransparency = 1
                emptyLbl.Text = "ไม่พบตัวเลือกที่ตรงกัน"
                applyThemeColor(emptyLbl, "SubText", "TextColor3")
                emptyLbl.Font = Enum.Font.GothamSemibold
                emptyLbl.TextSize = 12.5
                emptyLbl.TextXAlignment = Enum.TextXAlignment.Center
                emptyLbl.TextYAlignment = Enum.TextYAlignment.Center
                emptyLbl.Visible = false
                emptyLbl.ZIndex = 11
                emptyLbl.Parent = scrollWrap

                local optEntries = {}
                for _, opt in ipairs(c.Options) do
                    local isSelected = (opt == selected)
                    local optBtn = Instance.new("TextButton")
                    optBtn.Size = UDim2.new(1, 0, 0, itemH)
                    applyThemeColor(optBtn, "Element")
                    optBtn.BackgroundTransparency = 1
                    optBtn.AutoButtonColor = false
                    optBtn.Text = ""
                    optBtn.ZIndex = 11
                    optBtn.Parent = inner
                    corner(optBtn, 9)
                    if not isSelected then applyHoverEffect(optBtn, "Element", "ElementHover") end

                    if isSelected then
                        local accentBar = Instance.new("Frame")
                        accentBar.Size = UDim2.new(0, 3, 0, itemH * 0.5)
                        accentBar.AnchorPoint = Vector2.new(0, 0.5)
                        accentBar.Position = UDim2.new(0, 4, 0.5, 0)
                        applyThemeColor(accentBar, "AccentA")
                        accentBar.BorderSizePixel = 0
                        accentBar.ZIndex = 12
                        accentBar.Parent = optBtn
                        corner(accentBar, 2)
                    end

                    local optLabel = Instance.new("TextLabel")
                    optLabel.Size = UDim2.new(1, isSelected and -46 or -24, 1, 0)
                    optLabel.Position = UDim2.new(0, isSelected and 20 or 14, 0, 0)
                    optLabel.BackgroundTransparency = 1
                    optLabel.Text = opt
                    applyThemeColor(optLabel, isSelected and "AccentA" or "Text", "TextColor3")
                    optLabel.Font = isSelected and Enum.Font.GothamBold or Enum.Font.GothamSemibold
                    optLabel.TextSize = 13
                    optLabel.TextXAlignment = Enum.TextXAlignment.Left
                    optLabel.TextTruncate = Enum.TextTruncate.AtEnd
                    optLabel.ZIndex = 12
                    optLabel.Parent = optBtn

                    if isSelected then
                        local check = Instance.new("ImageLabel")
                        check.Size = UDim2.new(0, 15, 0, 15)
                        check.AnchorPoint = Vector2.new(1, 0.5)
                        check.Position = UDim2.new(1, -12, 0.5, 0)
                        check.BackgroundTransparency = 1
                        check.Image = Library.Icons.check
                        applyThemeColor(check, "AccentA", "ImageColor3")
                        check.ScaleType = Enum.ScaleType.Fit
                        check.ZIndex = 12
                        check.Parent = optBtn
                    end

                    optBtn.MouseButton1Click:Connect(function() selectOption(opt, true) end)
                    table.insert(optEntries, {opt = opt, btn = optBtn})
                end

                -- กรองรายการตามคำค้นหา (ซ่อน/โชว์ผ่าน Visible, UIListLayout จะจัดเรียงใหม่ให้อัตโนมัติ)
                local function applyFilter(query)
                    query = (query or ""):lower()
                    local visibleCount = 0
                    for _, entry in ipairs(optEntries) do
                        local match = query == "" or string.find(entry.opt:lower(), query, 1, true) ~= nil
                        entry.btn.Visible = match
                        if match then visibleCount += 1 end
                    end
                    emptyLbl.Visible = visibleCount == 0
                    if needsScroll then
                        local h = visibleCount * itemH + math.max(visibleCount - 1, 0) * gap
                        scrollWrap.CanvasSize = UDim2.new(0, 0, 0, h)
                    end
                end

                if SearchBox then
                    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                        applyFilter(SearchBox.Text)
                    end)
                end

                TweenService:Create(list, TI.d02_Quint_Out, {
                    Size = UDim2.new(0, Drop.AbsoluteSize.X, 0, fullH),
                    BackgroundTransparency = 0
                }):Play()
                TweenService:Create(shadow, TI.d02_Quint_Out, {
                    Size = UDim2.new(0, Drop.AbsoluteSize.X + 28, 0, fullH + 28)
                }):Play()

                closeActivePopup = closeDropdown
                outsideConn = UserInputService.InputBegan:Connect(function(input2)
                    if input2.UserInputType == Enum.UserInputType.MouseButton1 or input2.UserInputType == Enum.UserInputType.Touch then
                        local pos = input2.Position
                        if not isPointOverGui(pos, Drop) and (not list or not isPointOverGui(pos, list)) then closeDropdown() end
                    end
                end)

                if SearchBox then
                    task.defer(function()
                        if SearchBox and SearchBox.Parent then SearchBox:CaptureFocus() end
                    end)
                end
            end
            Drop.MouseButton1Click:Connect(function() if isOpen then closeDropdown() else openDropdown() end end)
            return newElement(Drop, function() return selected end, function(_, newVal) selectOption(newVal, true) end, nil, c.Flag)
        end

        function Tab:CreateThemeDropdown(c)
            c = c or {}
            c.Text = c.Text or "Theme"
            local options = {}
            for name, _ in pairs(Library.Themes) do table.insert(options, name) end
            c.Options = options
            c.Default = Library.CurrentTheme
            
            local origCallback = c.Callback
            c.Callback = function(selectedTheme)
                Library:SetTheme(selectedTheme)
                if origCallback then origCallback(selectedTheme) end
            end
            return Tab:CreateDropdown(c)
        end

        function Tab:CreateColorPicker(c)
            c = type(c) == "table" and c or {}
            local selectedColor = c.Default or Color3.fromRGB(255, 255, 255)
            bindFlag(c.Flag, selectedColor)

            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, 0, 0, 40)
            applyThemeColor(Btn, "Element")
            Btn.AutoButtonColor = false
            Btn.Text = ""
            Btn.Parent = TabContent
            corner(Btn, 9)
            applyHoverEffect(Btn, "Element", "ElementHover")
            applyGlowOnHover(Btn)

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -48, 1, 0)
            Label.Position = UDim2.new(0, 12, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = c.Text or "ColorPicker"
            applyThemeColor(Label, "Text", "TextColor3")
            Label.Font = Enum.Font.GothamSemibold
            Label.TextSize = 14
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Btn

            local colorPreview = Instance.new("Frame")
            colorPreview.Size = UDim2.new(0, 26, 0, 26)
            colorPreview.Position = UDim2.new(1, -34, 0.5, -13)
            colorPreview.AnchorPoint = Vector2.new(0, 0.5)
            colorPreview.BackgroundColor3 = selectedColor
            colorPreview.Parent = Btn
            corner(colorPreview, 8)
            local previewStroke = Instance.new("UIStroke")
            previewStroke.Color = Color3.fromRGB(255, 255, 255)
            previewStroke.Thickness = 1.5
            previewStroke.Transparency = 0.75
            previewStroke.Parent = colorPreview

            local isOpen, picker, outsideConn = false, nil, nil
            local h, s, v = selectedColor:ToHSV()

            local refreshVisuals

            local function closePicker()
                if picker then isOpen = false; picker:Destroy(); picker = nil end
                if outsideConn then outsideConn:Disconnect(); outsideConn = nil end
                refreshVisuals = nil
            end
            local function applyColor(col, fireCallback)
                selectedColor = col
                bindFlag(c.Flag, selectedColor)
                TweenService:Create(colorPreview, TI.d015_Sine_Out, {BackgroundColor3 = col}):Play()
                if fireCallback then safeCallback(c.Callback, col) end
            end

            Btn.MouseButton1Click:Connect(function()
                if isOpen then closePicker() return end
                closeActivePopup()
                isOpen = true
                h, s, v = selectedColor:ToHSV()

                picker = Instance.new("Frame")
                local pickerW = math.max(Btn.AbsoluteSize.X, 224)
                local estimatedH = 220 -- ความสูงโดยประมาณของเนื้อหา (SV box + hue bar + hex + swatches + padding)
                local popupX, edgeY, openUp = resolveFloatingPosition(Btn.AbsolutePosition, Btn.AbsoluteSize, pickerW, estimatedH, 6)
                picker.Size = UDim2.new(0, pickerW, 0, 0)
                picker.AutomaticSize = Enum.AutomaticSize.Y
                picker.AnchorPoint = Vector2.new(0, openUp and 1 or 0)
                picker.Position = UDim2.new(0, popupX, 0, edgeY)
                applyThemeColor(picker, "Background")
                picker.ZIndex = 10
                picker.Active = true
                picker.Parent = ScreenGui
                corner(picker, 12)
                local pStroke = stroke(picker)
                pStroke.Transparency = 0.4

                local pPad = Instance.new("UIPadding")
                pPad.PaddingLeft = UDim.new(0, 12)
                pPad.PaddingRight = UDim.new(0, 12)
                pPad.PaddingTop = UDim.new(0, 12)
                pPad.PaddingBottom = UDim.new(0, 12)
                pPad.Parent = picker

                local pLayout = Instance.new("UIListLayout")
                pLayout.Padding = UDim.new(0, 10)
                pLayout.SortOrder = Enum.SortOrder.LayoutOrder
                pLayout.Parent = picker

                local SVBox = Instance.new("Frame")
                SVBox.LayoutOrder = 1
                SVBox.Size = UDim2.new(1, 0, 0, 110)
                SVBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                SVBox.BorderSizePixel = 0
                SVBox.ClipsDescendants = true
                SVBox.ZIndex = 11
                SVBox.Parent = picker
                corner(SVBox, 8)

                local SatOverlay = Instance.new("Frame")
                SatOverlay.Size = UDim2.new(1, 0, 1, 0)
                SatOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                SatOverlay.BorderSizePixel = 0
                SatOverlay.ZIndex = 11
                SatOverlay.Parent = SVBox
                local satGradient = Instance.new("UIGradient")
                satGradient.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                })
                satGradient.Parent = SatOverlay

                local ValOverlay = Instance.new("Frame")
                ValOverlay.Size = UDim2.new(1, 0, 1, 0)
                ValOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                ValOverlay.BorderSizePixel = 0
                ValOverlay.ZIndex = 12
                ValOverlay.Parent = SVBox
                local valGradient = Instance.new("UIGradient")
                valGradient.Rotation = 90
                valGradient.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0),
                })
                valGradient.Parent = ValOverlay

                local SVCursor = Instance.new("Frame")
                SVCursor.Size = UDim2.new(0, 14, 0, 14)
                SVCursor.AnchorPoint = Vector2.new(0.5, 0.5)
                SVCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                SVCursor.BorderSizePixel = 0
                SVCursor.ZIndex = 13
                SVCursor.Parent = SVBox
                corner(SVCursor, 7)
                local svCursorStroke = Instance.new("UIStroke")
                svCursorStroke.Thickness = 2
                svCursorStroke.Color = Color3.fromRGB(25, 25, 25)
                svCursorStroke.Parent = SVCursor

                local HueBar = Instance.new("Frame")
                HueBar.LayoutOrder = 2
                HueBar.Size = UDim2.new(1, 0, 0, 16)
                HueBar.BorderSizePixel = 0
                HueBar.ZIndex = 11
                HueBar.Parent = picker
                corner(HueBar, 8)
                local hueGradient = Instance.new("UIGradient")
                hueGradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0.000, Color3.fromRGB(255, 0, 0)),
                    ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
                    ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
                    ColorSequenceKeypoint.new(0.500, Color3.fromRGB(0, 255, 255)),
                    ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
                    ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
                    ColorSequenceKeypoint.new(1.000, Color3.fromRGB(255, 0, 0)),
                })
                hueGradient.Parent = HueBar

                local HueCursor = Instance.new("Frame")
                HueCursor.Size = UDim2.new(0, 4, 1, 4)
                HueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
                HueCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                HueCursor.BorderSizePixel = 0
                HueCursor.ZIndex = 12
                HueCursor.Parent = HueBar
                corner(HueCursor, 2)
                local hueCursorStroke = Instance.new("UIStroke")
                hueCursorStroke.Thickness = 1.5
                hueCursorStroke.Color = Color3.fromRGB(25, 25, 25)
                hueCursorStroke.Parent = HueCursor

                local HexLabel = Instance.new("TextLabel")
                HexLabel.LayoutOrder = 3
                HexLabel.Size = UDim2.new(1, 0, 0, 16)
                HexLabel.BackgroundTransparency = 1
                HexLabel.Font = Enum.Font.GothamSemibold
                HexLabel.TextSize = 12
                HexLabel.TextXAlignment = Enum.TextXAlignment.Left
                HexLabel.ZIndex = 11
                applyThemeColor(HexLabel, "SubText", "TextColor3")
                HexLabel.Parent = picker

                local swatchRow = Instance.new("Frame")
                swatchRow.LayoutOrder = 4
                swatchRow.Size = UDim2.new(1, 0, 0, 22)
                swatchRow.BackgroundTransparency = 1
                swatchRow.ZIndex = 11
                swatchRow.Parent = picker
                local swatchLayout = Instance.new("UIListLayout")
                swatchLayout.FillDirection = Enum.FillDirection.Horizontal
                swatchLayout.Padding = UDim.new(0, 6)
                swatchLayout.SortOrder = Enum.SortOrder.LayoutOrder
                swatchLayout.Parent = swatchRow

                local presets = {
                    Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0),
                    Color3.fromRGB(255, 59, 48), Color3.fromRGB(255, 149, 0),
                    Color3.fromRGB(255, 204, 0), Color3.fromRGB(52, 199, 89),
                    Color3.fromRGB(0, 199, 190), Color3.fromRGB(0, 122, 255),
                    Color3.fromRGB(175, 82, 222),
                }

                local function refreshHex()
                    local col = Color3.fromHSV(h, s, v)
                    HexLabel.Text = string.format(
                        "#%02X%02X%02X",
                        math.floor(col.R * 255 + 0.5),
                        math.floor(col.G * 255 + 0.5),
                        math.floor(col.B * 255 + 0.5)
                    )
                end

                refreshVisuals = function()
                    SVCursor.Position = UDim2.new(s, 0, 1 - v, 0)
                    HueCursor.Position = UDim2.new(h, 0, 0.5, 0)
                    SVBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                    refreshHex()
                end
                refreshVisuals()

                local function updateSV(x, y)
                    s = math.clamp((x - SVBox.AbsolutePosition.X) / SVBox.AbsoluteSize.X, 0, 1)
                    v = 1 - math.clamp((y - SVBox.AbsolutePosition.Y) / SVBox.AbsoluteSize.Y, 0, 1)
                    refreshVisuals()
                    applyColor(Color3.fromHSV(h, s, v), true)
                end
                local function updateHue(x)
                    h = math.clamp((x - HueBar.AbsolutePosition.X) / HueBar.AbsoluteSize.X, 0, 1)
                    refreshVisuals()
                    applyColor(Color3.fromHSV(h, s, v), true)
                end

                -- Both drags rebuild the gradient visuals and re-run applyColor (which
                -- fans out to the flag/callback system) on every event. Render-syncing
                -- means a fast swipe across the box only pays that cost once per frame.
                local svPush, svRSStart, svRSStop = createRenderSyncedDrag(function(x, y)
                    updateSV(x, y)
                end)

                local svDragging, svChangedConn, svEndedConn = false, nil, nil
                local function stopSVDrag()
                    svDragging = false
                    if svChangedConn then svChangedConn:Disconnect(); svChangedConn = nil end
                    if svEndedConn then svEndedConn:Disconnect(); svEndedConn = nil end
                    svRSStop()
                end
                SVBox.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        svDragging = true
                        updateSV(input.Position.X, input.Position.Y)
                        svRSStart()
                        svChangedConn = UserInputService.InputChanged:Connect(function(input2)
                            if svDragging and (input2.UserInputType == Enum.UserInputType.MouseMovement or input2.UserInputType == Enum.UserInputType.Touch) then
                                svPush(input2.Position.X, input2.Position.Y)
                            end
                        end)
                        svEndedConn = UserInputService.InputEnded:Connect(function(input2)
                            if input2.UserInputType == Enum.UserInputType.MouseButton1 or input2.UserInputType == Enum.UserInputType.Touch then
                                stopSVDrag()
                            end
                        end)
                    end
                end)

                local huePush, hueRSStart, hueRSStop = createRenderSyncedDrag(function(x)
                    updateHue(x)
                end)

                local hueDragging, hueChangedConn, hueEndedConn = false, nil, nil
                local function stopHueDrag()
                    hueDragging = false
                    if hueChangedConn then hueChangedConn:Disconnect(); hueChangedConn = nil end
                    if hueEndedConn then hueEndedConn:Disconnect(); hueEndedConn = nil end
                    hueRSStop()
                end
                HueBar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        hueDragging = true
                        updateHue(input.Position.X)
                        hueRSStart()
                        hueChangedConn = UserInputService.InputChanged:Connect(function(input2)
                            if hueDragging and (input2.UserInputType == Enum.UserInputType.MouseMovement or input2.UserInputType == Enum.UserInputType.Touch) then
                                huePush(input2.Position.X)
                            end
                        end)
                        hueEndedConn = UserInputService.InputEnded:Connect(function(input2)
                            if input2.UserInputType == Enum.UserInputType.MouseButton1 or input2.UserInputType == Enum.UserInputType.Touch then
                                stopHueDrag()
                            end
                        end)
                    end
                end)

                for _, col in ipairs(presets) do
                    local sw = Instance.new("TextButton")
                    sw.Size = UDim2.new(0, 22, 0, 22)
                    sw.BackgroundColor3 = col
                    sw.AutoButtonColor = false
                    sw.Text = ""
                    sw.ZIndex = 11
                    sw.Parent = swatchRow
                    corner(sw, 6)
                    local swStroke = Instance.new("UIStroke")
                    swStroke.Color = Color3.fromRGB(255, 255, 255)
                    swStroke.Thickness = 1
                    swStroke.Transparency = 0.7
                    swStroke.Parent = sw
                    sw.MouseEnter:Connect(function()
                        TweenService:Create(swStroke, TI.d012_Sine_Out, {Thickness = 2, Transparency = 0.15}):Play()
                    end)
                    sw.MouseLeave:Connect(function()
                        TweenService:Create(swStroke, TI.d012_Sine_Out, {Thickness = 1, Transparency = 0.7}):Play()
                    end)
                    sw.MouseButton1Click:Connect(function()
                        h, s, v = col:ToHSV()
                        refreshVisuals()
                        applyColor(col, true)
                    end)
                end

                closeActivePopup = closePicker
                outsideConn = UserInputService.InputBegan:Connect(function(input2)
                    if input2.UserInputType == Enum.UserInputType.MouseButton1 or input2.UserInputType == Enum.UserInputType.Touch then
                        local pos = input2.Position
                        if not isPointOverGui(pos, Btn) and not isPointOverGui(pos, picker) then closePicker() end
                    end
                end)
            end)
            return newElement(Btn, function() return selectedColor end, function(_, newColor)
                h, s, v = newColor:ToHSV()
                if refreshVisuals then refreshVisuals() end
                applyColor(newColor, true)
            end, nil, c.Flag)
        end

        function Tab:CreateInput(c)
            c = type(c) == "table" and c or {}
            bindFlag(c.Flag, c.Default or "")
            local Box = Instance.new("TextBox")
            Box.Size = UDim2.new(1, 0, 0, 40)
            applyThemeColor(Box, "Element")
            Box.Text = c.Default or ""
            Box.PlaceholderText = c.Text or "Input here..."
            applyThemeColor(Box, "Text", "TextColor3")
            applyThemeColor(Box, "SubText", "PlaceholderColor3")
            Box.Font = Enum.Font.GothamSemibold
            Box.TextSize = 14
            Box.ClearTextOnFocus = false
            Box.TextXAlignment = Enum.TextXAlignment.Left
            Box.Parent = TabContent
            corner(Box, 9)
            
            local Pad = Instance.new("UIPadding")
            Pad.PaddingLeft = UDim.new(0, 12)
            Pad.Parent = Box
            
            applyGlowOnHover(Box)
            Box.FocusLost:Connect(function()
                Library.Flags[c.Flag or ""] = Box.Text
                safeCallback(c.Callback, Box.Text)
            end)
            return newElement(Box, function() return Box.Text end, function(_, newText)
                Box.Text = newText; safeCallback(c.Callback, newText)
            end, nil, c.Flag)
        end

        function Tab:CreateKeybind(c)
            c = type(c) == "table" and c or {}
            local selectedKey = c.Default
            bindFlag(c.Flag, selectedKey)
            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, 0, 0, 40)
            applyThemeColor(Btn, "Element")
            Btn.AutoButtonColor = false
            Btn.Text = ""
            Btn.Parent = TabContent
            corner(Btn, 9)
            applyHoverEffect(Btn, "Element", "ElementHover")
            applyGlowOnHover(Btn)

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -60, 1, 0)
            Label.Position = UDim2.new(0, 12, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = (c.Text or "Keybind") .. ": " .. (selectedKey and selectedKey.Name or "None")
            applyThemeColor(Label, "Text", "TextColor3")
            Label.Font = Enum.Font.GothamSemibold
            Label.TextSize = 14
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Btn

            local waiting, bindConn = false, nil
            Btn.MouseButton1Click:Connect(function()
                if waiting then return end
                if bindConn then bindConn:Disconnect(); bindConn = nil end
                waiting = true
                Label.Text = (c.Text or "Keybind") .. ": Press..."
                bindConn = UserInputService.InputBegan:Connect(function(input)
                    if waiting and input.UserInputType == Enum.UserInputType.Keyboard then
                        selectedKey = input.KeyCode
                        bindFlag(c.Flag, selectedKey)
                        Label.Text = (c.Text or "Keybind") .. ": " .. selectedKey.Name
                        waiting = false
                        if bindConn then bindConn:Disconnect(); bindConn = nil end
                        safeCallback(c.Callback, selectedKey)
                    end
                end)
            end)
            return newElement(Btn, function() return selectedKey end, function(_, newKey)
                selectedKey = newKey
                bindFlag(c.Flag, selectedKey)
                Label.Text = (c.Text or "Keybind") .. ": " .. (newKey and newKey.Name or "None")
            end, nil, c.Flag)
        end

        function Tab:CreateLabel(c)
            c = type(c) == "table" and c or {}
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, 0, 0, 24)
            Label.AutomaticSize = Enum.AutomaticSize.Y
            Label.BackgroundTransparency = 1
            Label.Text = c.Text or "Label"
            applyThemeColor(Label, "SubText", "TextColor3")
            Label.Font = Enum.Font.GothamSemibold
            Label.TextSize = 13
            Label.TextWrapped = true
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = TabContent
            return newElement(Label, function() return Label.Text end, function(_, newText) Label.Text = newText end)
        end

        function Tab:CreateTextArea(c)
            c = type(c) == "table" and c or {}
            bindFlag(c.Flag, c.Default or "")
            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, 0, 0, c.Height or 90)
            applyThemeColor(Frame, "Element")
            Frame.Parent = TabContent
            corner(Frame, 9)
            applyGlowOnHover(Frame)

            local Box = Instance.new("TextBox")
            Box.Size = UDim2.new(1, -20, 1, -16)
            Box.Position = UDim2.new(0, 10, 0, 8)
            Box.BackgroundTransparency = 1
            Box.Text = c.Default or ""
            Box.PlaceholderText = c.Text or "Type notes here..."
            applyThemeColor(Box, "Text", "TextColor3")
            applyThemeColor(Box, "SubText", "PlaceholderColor3")
            Box.Font = Enum.Font.Gotham
            Box.TextSize = 13
            Box.ClearTextOnFocus = false
            Box.MultiLine = true
            Box.TextWrapped = true
            Box.TextXAlignment = Enum.TextXAlignment.Left
            Box.TextYAlignment = Enum.TextYAlignment.Top
            Box.Parent = Frame

            Box.FocusLost:Connect(function()
                Library.Flags[c.Flag or ""] = Box.Text
                safeCallback(c.Callback, Box.Text)
            end)
            return newElement(Box, function() return Box.Text end, function(_, newText)
                Box.Text = newText; safeCallback(c.Callback, newText)
            end, nil, c.Flag)
        end

        function Tab:CreateProgressBar(c)
            c = type(c) == "table" and c or {}
            local min, max = c.Min or 0, c.Max or 100
            local val = math.clamp(c.Default or min, min, max)

            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, 0, 0, 44)
            applyThemeColor(Frame, "Element")
            Frame.Parent = TabContent
            corner(Frame, 9)

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -20, 0, 18)
            Label.Position = UDim2.new(0, 10, 0, 4)
            Label.BackgroundTransparency = 1
            Label.Text = c.Text or "Progress"
            applyThemeColor(Label, "Text", "TextColor3")
            Label.Font = Enum.Font.GothamSemibold
            Label.TextSize = 13
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Frame

            local Bar = Instance.new("Frame")
            Bar.Size = UDim2.new(1, -20, 0, 8)
            Bar.Position = UDim2.new(0, 10, 0, 26)
            applyThemeColor(Bar, "Background")
            Bar.Parent = Frame
            corner(Bar, 4)

            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new(max > min and (val - min) / (max - min) or 0, 0, 1, 0)
            applyThemeColor(Fill, "AccentA")
            Fill.Parent = Bar
            corner(Fill, 4)
            accentGradient(Fill, 0)

            local function setValue(newVal)
                newVal = math.clamp(newVal, min, max)
                val = newVal
                local percent = max > min and (val - min) / (max - min) or 0
                TweenService:Create(Fill, TI.d02_Sine_Out, {Size = UDim2.new(percent, 0, 1, 0)}):Play()
            end

            return newElement(Frame, function() return val end, function(_, newVal) setValue(newVal) end)
        end

        function Tab:CreateRadioGroup(c)
            c = type(c) == "table" and c or {}
            c.Options = (type(c.Options) == "table" and #c.Options > 0) and c.Options or {"Option 1"}
            local selected = c.Default or c.Options[1]
            bindFlag(c.Flag, selected)

            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, 0, 0, 0)
            Frame.AutomaticSize = Enum.AutomaticSize.Y
            applyThemeColor(Frame, "Element")
            Frame.Parent = TabContent
            corner(Frame, 9)

            local Pad = Instance.new("UIPadding")
            Pad.PaddingLeft = UDim.new(0, 10); Pad.PaddingRight = UDim.new(0, 10)
            Pad.PaddingTop = UDim.new(0, 8); Pad.PaddingBottom = UDim.new(0, 8)
            Pad.Parent = Frame

            local Layout = Instance.new("UIListLayout")
            Layout.Padding = UDim.new(0, 6)
            Layout.Parent = Frame

            if c.Text then
                local TitleLbl = Instance.new("TextLabel")
                TitleLbl.Size = UDim2.new(1, 0, 0, 18)
                TitleLbl.BackgroundTransparency = 1
                TitleLbl.Text = c.Text
                applyThemeColor(TitleLbl, "Text", "TextColor3")
                TitleLbl.Font = Enum.Font.GothamSemibold
                TitleLbl.TextSize = 13
                TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
                TitleLbl.Parent = Frame
            end

            local circles = {}
            local function refresh()
                for opt, circle in pairs(circles) do
                    local isSel = (opt == selected)
                    TweenService:Create(circle, TI.d015_Sine_Out, {BackgroundColor3 = isSel and Theme.AccentA or Theme.ToggleOff}):Play()
                end
            end

            for _, opt in ipairs(c.Options) do
                local Row = Instance.new("TextButton")
                Row.Size = UDim2.new(1, 0, 0, 26)
                Row.BackgroundTransparency = 1
                Row.AutoButtonColor = false
                Row.Text = ""
                Row.Parent = Frame

                local Circle = Instance.new("Frame")
                Circle.Size = UDim2.new(0, 16, 0, 16)
                Circle.Position = UDim2.new(0, 0, 0.5, -8)
                applyThemeColor(Circle, (opt == selected) and "AccentA" or "ToggleOff")
                Circle.Parent = Row
                corner(Circle, 8)
                stroke(Circle)
                local Dot = Instance.new("Frame")
                Dot.Size = UDim2.new(0, 6, 0, 6)
                Dot.AnchorPoint = Vector2.new(0.5, 0.5)
                Dot.Position = UDim2.new(0.5, 0, 0.5, 0)
                Dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Dot.Parent = Circle
                corner(Dot, 3)

                local OptLabel = Instance.new("TextLabel")
                OptLabel.Size = UDim2.new(1, -26, 1, 0)
                OptLabel.Position = UDim2.new(0, 26, 0, 0)
                OptLabel.BackgroundTransparency = 1
                OptLabel.Text = opt
                applyThemeColor(OptLabel, "Text", "TextColor3")
                OptLabel.Font = Enum.Font.GothamSemibold
                OptLabel.TextSize = 13
                OptLabel.TextXAlignment = Enum.TextXAlignment.Left
                OptLabel.Parent = Row

                circles[opt] = Circle
                Row.MouseButton1Click:Connect(function()
                    selected = opt
                    bindFlag(c.Flag, selected)
                    refresh()
                    safeCallback(c.Callback, opt)
                end)
            end

            return newElement(Frame, function() return selected end, function(_, newVal)
                selected = newVal; bindFlag(c.Flag, selected); refresh()
                safeCallback(c.Callback, newVal)
            end, nil, c.Flag)
        end

        function Tab:CreateMultiDropdown(c)
            c = type(c) == "table" and c or {}
            c.Options = (type(c.Options) == "table" and #c.Options > 0) and c.Options or {"Option 1"}
            local selected = {}
            if type(c.Default) == "table" then
                for _, v in ipairs(c.Default) do selected[v] = true end
            end
            local function getList()
                local list = {}
                for _, opt in ipairs(c.Options) do
                    if selected[opt] then table.insert(list, opt) end
                end
                return list
            end
            bindFlag(c.Flag, getList())

            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, 0, 0, 0)
            Frame.AutomaticSize = Enum.AutomaticSize.Y
            applyThemeColor(Frame, "Element")
            Frame.Parent = TabContent
            corner(Frame, 9)

            local Pad = Instance.new("UIPadding")
            Pad.PaddingLeft = UDim.new(0, 10); Pad.PaddingRight = UDim.new(0, 10)
            Pad.PaddingTop = UDim.new(0, 8); Pad.PaddingBottom = UDim.new(0, 8)
            Pad.Parent = Frame

            local Layout = Instance.new("UIListLayout")
            Layout.Padding = UDim.new(0, 6)
            Layout.Parent = Frame

            if c.Text then
                local TitleLbl = Instance.new("TextLabel")
                TitleLbl.Size = UDim2.new(1, 0, 0, 18)
                TitleLbl.BackgroundTransparency = 1
                TitleLbl.Text = c.Text
                applyThemeColor(TitleLbl, "Text", "TextColor3")
                TitleLbl.Font = Enum.Font.GothamSemibold
                TitleLbl.TextSize = 13
                TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
                TitleLbl.Parent = Frame
            end

            local boxes = {}
            local function fireCallback()
                local list = getList()
                bindFlag(c.Flag, list)
                safeCallback(c.Callback, list)
            end

            for _, opt in ipairs(c.Options) do
                local Row = Instance.new("TextButton")
                Row.Size = UDim2.new(1, 0, 0, 26)
                Row.BackgroundTransparency = 1
                Row.AutoButtonColor = false
                Row.Text = ""
                Row.Parent = Frame

                local CheckBox = Instance.new("Frame")
                CheckBox.Size = UDim2.new(0, 16, 0, 16)
                CheckBox.Position = UDim2.new(0, 0, 0.5, -8)
                applyThemeColor(CheckBox, selected[opt] and "AccentA" or "ToggleOff")
                CheckBox.Parent = Row
                corner(CheckBox, 4)
                stroke(CheckBox)

                local Check = Instance.new("ImageLabel")
                Check.Size = UDim2.new(1, -4, 1, -4)
                Check.AnchorPoint = Vector2.new(0.5, 0.5)
                Check.Position = UDim2.new(0.5, 0, 0.5, 0)
                Check.BackgroundTransparency = 1
                Check.Image = Library.Icons.check
                Check.ImageColor3 = Color3.fromRGB(255, 255, 255)
                Check.ImageTransparency = selected[opt] and 0 or 1
                Check.ScaleType = Enum.ScaleType.Fit
                Check.Parent = CheckBox

                local OptLabel = Instance.new("TextLabel")
                OptLabel.Size = UDim2.new(1, -26, 1, 0)
                OptLabel.Position = UDim2.new(0, 26, 0, 0)
                OptLabel.BackgroundTransparency = 1
                OptLabel.Text = opt
                applyThemeColor(OptLabel, "Text", "TextColor3")
                OptLabel.Font = Enum.Font.GothamSemibold
                OptLabel.TextSize = 13
                OptLabel.TextXAlignment = Enum.TextXAlignment.Left
                OptLabel.Parent = Row

                boxes[opt] = {Box = CheckBox, Check = Check}
                Row.MouseButton1Click:Connect(function()
                    selected[opt] = not selected[opt]
                    TweenService:Create(CheckBox, TI.d015_Sine_Out, {BackgroundColor3 = selected[opt] and Theme.AccentA or Theme.ToggleOff}):Play()
                    TweenService:Create(Check, TI.d015_Sine_Out, {ImageTransparency = selected[opt] and 0 or 1}):Play()
                    fireCallback()
                end)
            end

            return newElement(Frame, getList, function(_, newList)
                selected = {}
                if type(newList) == "table" then for _, v in ipairs(newList) do selected[v] = true end end
                for opt, b in pairs(boxes) do
                    b.Box.BackgroundColor3 = selected[opt] and Theme.AccentA or Theme.ToggleOff
                    b.Check.ImageTransparency = selected[opt] and 0 or 1
                end
                fireCallback()
            end, nil, c.Flag)
        end

        function Tab:CreateSearchBox(c)
            c = type(c) == "table" and c or {}

            local Outer = Instance.new("Frame")
            Outer.Size = UDim2.new(1, 0, 0, 38)
            applyThemeColor(Outer, "Element")
            Outer.ClipsDescendants = true
            Outer.Parent = TabContent
            corner(Outer, 9)
            applyGlowOnHover(Outer)

            local IconImg = Instance.new("ImageLabel")
            IconImg.Size = UDim2.new(0, 15, 0, 15)
            IconImg.Position = UDim2.new(0, 12, 0.5, -7)
            IconImg.BackgroundTransparency = 1
            IconImg.Image = Library.Icons.search
            applyThemeColor(IconImg, "SubText", "ImageColor3")
            IconImg.ScaleType = Enum.ScaleType.Fit
            IconImg.ZIndex = 2
            IconImg.Parent = Outer

            local contentPos = UDim2.new(0, 34, 0, 0)
            local contentSize = UDim2.new(1, -44, 1, 0)

            local Box = Instance.new("TextBox")
            Box.Position = contentPos
            Box.Size = contentSize
            Box.BackgroundTransparency = 1
            Box.Text = c.Default or ""
            Box.PlaceholderText = ""
            applyThemeColor(Box, "Text", "TextColor3")
            Box.Font = Enum.Font.GothamSemibold
            Box.TextSize = 13
            Box.ClearTextOnFocus = false
            Box.TextXAlignment = Enum.TextXAlignment.Left
            Box.TextYAlignment = Enum.TextYAlignment.Center
            Box.ZIndex = 3
            Box.Parent = Outer

            local PlaceholderLbl = Instance.new("TextLabel")
            PlaceholderLbl.BackgroundTransparency = 1
            PlaceholderLbl.Position = contentPos
            PlaceholderLbl.Size = contentSize
            PlaceholderLbl.Font = Enum.Font.GothamSemibold
            PlaceholderLbl.TextSize = 13
            PlaceholderLbl.TextXAlignment = Enum.TextXAlignment.Left
            PlaceholderLbl.TextYAlignment = Enum.TextYAlignment.Center
            PlaceholderLbl.TextTruncate = Enum.TextTruncate.AtEnd
            PlaceholderLbl.Text = c.Text or "Search..."
            PlaceholderLbl.ZIndex = 1
            applyThemeColor(PlaceholderLbl, "SubText", "TextColor3")
            PlaceholderLbl.Visible = Box.Text == ""
            PlaceholderLbl.Parent = Outer

            Box:GetPropertyChangedSignal("Text"):Connect(function()
                PlaceholderLbl.Visible = Box.Text == ""
                safeCallback(c.Callback, Box.Text)
            end)
            return newElement(Outer, function() return Box.Text end, function(_, newText)
                Box.Text = newText
                PlaceholderLbl.Visible = Box.Text == ""
            end)
        end

        function Tab:CreateImage(c)
            c = type(c) == "table" and c or {}
            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, 0, 0, c.Height or 120)
            applyThemeColor(Frame, "Element")
            Frame.ClipsDescendants = true
            Frame.Parent = TabContent
            corner(Frame, 9)

            local Img = Instance.new("ImageLabel")
            Img.Size = UDim2.new(1, 0, 1, 0)
            Img.BackgroundTransparency = 1
            Img.Image = normalizeAssetId(c.Image or "")
            Img.ScaleType = c.ScaleType or Enum.ScaleType.Crop
            Img.Parent = Frame

            return newElement(Frame, function() return Img.Image end, function(_, newImage)
                Img.Image = normalizeAssetId(newImage)
            end)
        end

        function Tab:CreateConfigManager(c)
            c = type(c) == "table" and c or {}
            Tab:CreateSection(c.Title or "Config")

            local existing = Library:ListConfigs()
            local startName = existing[1] or c.Default or "default"

            local nameInput = Tab:CreateInput({
                Text = "ชื่อ Config",
                Default = startName,
            })

            if #existing > 0 then
                Tab:CreateDropdown({
                    Text = "Config ที่มีอยู่",
                    Options = existing,
                    Default = existing[1],
                    Callback = function(pickedName)
                        nameInput:Set(pickedName)
                    end,
                })
            end

            local function currentName()
                local n = nameInput:Get()
                if not n or n == "" then n = "default" end
                return n
            end

            Tab:CreateButton({
                Text = "💾  บันทึก Config",
                Notify = false,
                Callback = function() Library:SaveConfig(currentName()) end,
            })
            Tab:CreateButton({
                Text = "📂  โหลด Config",
                Notify = false,
                Callback = function() Library:LoadConfig(currentName()) end,
            })
            Tab:CreateButton({
                Text = "🗑  ลบ Config",
                Notify = false,
                Callback = function() Library:DeleteConfig(currentName()) end,
            })

            if c.AutoLoad ~= false and #existing > 0 then
                Library:LoadConfig(existing[1])
            end
        end

        function Tab:Clear()
            for _, child in ipairs(TabContent:GetChildren()) do
                if not child:IsA("UIListLayout") then child:Destroy() end
            end
        end

        Tab.Btn = TabBtn
        table.insert(Tabs, {Btn = TabBtn, Content = TabContent, SetActive = setActive, BasePos = ContentBasePos, Scale = ContentScale})
        if #Tabs == 1 then
            setActive(true)
            TabContent.Visible = true
            CurrentTab = {Btn = TabBtn, Content = TabContent, SetActive = setActive}
        end

        return Tab
    end

    -- ============ Draggable ============
    local dragging, dragStart, startPos, activeTouch = false, nil, nil, nil
    local dragChangedConn, dragEndedConn = nil, nil

    -- กันหน้าต่างลากหลุดจอจริง (มือถือ/PC path เดียวกัน)
    -- Shadow มี AnchorPoint 0.5,0.5 → Position = จุดกึ่งกลาง Shadow ทั้งก้อน (รวม glow 30px รอบนอก)
    -- ใช้ Shadow.AbsoluteSize แทน MainFrame เพื่อนับ glow ด้วย ไม่งั้น edge ยัง overflow ได้ 30px
    -- return pure Offset เสมอ กัน Scale=0.5 ค้างใน startPos ทำให้ mixed Scale/Offset ในรอบถัดไป
    local SCREEN_PADDING = 6   -- ระยะห่างขอบจอจริงขั้นต่ำ (px) กัน window ชิดขอบสนิท
    local function clampWindowCenter(pos)
        local screenSize = ScreenGui.AbsoluteSize
        -- resolve Scale+Offset → pixel absolute (Shadow อาจยังมี Scale=0.5 ตอน init)
        local centerX = pos.X.Scale * screenSize.X + pos.X.Offset
        local centerY = pos.Y.Scale * screenSize.Y + pos.Y.Offset
        -- ใช้ Shadow (ใหญ่กว่า MainFrame 30px ต่อด้าน) เพื่อกัน glow ไม่ให้ทะลุด้วย
        local halfW = Shadow.AbsoluteSize.X / 2
        local halfH = Shadow.AbsoluteSize.Y / 2
        if screenSize.X > 0 and halfW > 0 then
            centerX = math.clamp(centerX, halfW + SCREEN_PADDING, math.max(halfW + SCREEN_PADDING, screenSize.X - halfW - SCREEN_PADDING))
        end
        if screenSize.Y > 0 and halfH > 0 then
            centerY = math.clamp(centerY, halfH + SCREEN_PADDING, math.max(halfH + SCREEN_PADDING, screenSize.Y - halfH - SCREEN_PADDING))
        end
        return UDim2.new(0, centerX, 0, centerY)   -- pure Offset เสมอ ไม่มี Scale ปน
    end

    -- Render-synced so a fast flick (which can fire many InputChanged events per
    -- rendered frame) only ever applies its latest position once per frame,
    -- instead of writing Shadow.Position (and re-triggering layout) on every event.
    local dragPush, dragRSStart, dragRSStop = createRenderSyncedDrag(function(newPos)
        Shadow.Position = clampWindowCenter(newPos)
    end)

    local function stopWindowDrag(input)
        dragging = false
        if input and input == activeTouch then activeTouch = nil end
        if dragChangedConn then dragChangedConn:Disconnect(); dragChangedConn = nil end
        if dragEndedConn then dragEndedConn:Disconnect(); dragEndedConn = nil end
        dragRSStop()
    end

    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if isPointOverGui(input.Position, CloseBtn) then return end
            dragging = true
            dragStart = input.Position
            -- normalize Shadow.Position → pure pixel Offset ก่อน เพราะ Shadow เริ่มที่ Scale=0.5,Offset=0
            -- ถ้าดึง startPos มาตรงๆ แล้ว delta บวกแค่ฝั่ง Offset → clampWindowCenter resolve เป็น
            -- 0.5*screenW + delta แทนที่จะเป็น currentCenter + delta → หน้าต่างกระโดดออกนอกจอ
            do
                local _ss = ScreenGui.AbsoluteSize
                startPos = UDim2.new(
                    0, Shadow.Position.X.Scale * _ss.X + Shadow.Position.X.Offset,
                    0, Shadow.Position.Y.Scale * _ss.Y + Shadow.Position.Y.Offset
                )
            end
            if input.UserInputType == Enum.UserInputType.Touch then activeTouch = input end
            dragRSStart()

            dragChangedConn = UserInputService.InputChanged:Connect(function(input2)
                if dragging and (input2.UserInputType == Enum.UserInputType.MouseMovement or input2.UserInputType == Enum.UserInputType.Touch) then
                    if input2.UserInputType == Enum.UserInputType.MouseMovement or input2 == activeTouch then
                        local delta = input2.Position - dragStart
                        dragPush(UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y))
                    end
                end
            end)
            dragEndedConn = UserInputService.InputEnded:Connect(function(input2)
                if input2.UserInputType == Enum.UserInputType.MouseButton1 or input2.UserInputType == Enum.UserInputType.Touch then
                    stopWindowDrag(input2)
                end
            end)
        end
    end)

    -- ============ Resizable ============
    local MIN_SIZE, MAX_SIZE = Vector2.new(380, 340), Vector2.new(650, 550)
    local resizeStart, startSize, resizeTouch = nil, nil, nil
    local resizeChangedConn, resizeEndedConn = nil, nil

    -- Same render-sync treatment as window drag: MainFrame.Size drives every
    -- descendant's layout recompute, so coalescing to one write per frame
    -- avoids re-running that layout pass multiple times per frame while resizing.
    local resizePush, resizeRSStart, resizeRSStop = createRenderSyncedDrag(function(newSize)
        MainFrame.Size = newSize
        Shadow.Position = clampWindowCenter(Shadow.Position)  -- โต ณ ใกล้ขอบจอ ก็ไม่ทะลุจอ
    end)

    local function stopResize(input)
        if resizing then
            resizing = false
            TweenService:Create(ResizeBg, TI.d015_Sine_Out, {BackgroundTransparency = 1}):Play()
            TweenService:Create(ResizeIcon, TI.d015_Sine_Out, {ImageTransparency = 0.55, ImageColor3 = Theme.SubText}):Play()
            TweenService:Create(ResizeIconScale, TI.d015_Sine_Out, {Scale = 1}):Play()
        end
        if input and input == resizeTouch then resizeTouch = nil end
        if resizeChangedConn then resizeChangedConn:Disconnect(); resizeChangedConn = nil end
        if resizeEndedConn then resizeEndedConn:Disconnect(); resizeEndedConn = nil end
        resizeRSStop()
    end

    ResizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resizeStart = input.Position
            startSize = MainFrame.Size
            if input.UserInputType == Enum.UserInputType.Touch then resizeTouch = input end
            resizeRSStart()

            resizeChangedConn = UserInputService.InputChanged:Connect(function(input2)
                if resizing and (input2.UserInputType == Enum.UserInputType.MouseMovement or input2.UserInputType == Enum.UserInputType.Touch) then
                    if input2.UserInputType == Enum.UserInputType.MouseMovement or input2 == resizeTouch then
                        local delta = input2.Position - resizeStart
                        local newW = math.clamp(startSize.X.Offset + delta.X, MIN_SIZE.X, MAX_SIZE.X)
                        local newH = math.clamp(startSize.Y.Offset + delta.Y, MIN_SIZE.Y, MAX_SIZE.Y)
                        resizePush(UDim2.new(0, newW, 0, newH))
                    end
                end
            end)
            resizeEndedConn = UserInputService.InputEnded:Connect(function(input2)
                if input2.UserInputType == Enum.UserInputType.MouseButton1 or input2.UserInputType == Enum.UserInputType.Touch then
                    stopResize(input2)
                end
            end)
        end
    end)

    return Window
end

return Library
