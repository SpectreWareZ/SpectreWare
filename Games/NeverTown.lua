-- NEVER TOWN | SpectreWare by #CaptainZ v1.6.12 (Performance Optimized by Bread)
if not game:IsLoaded() then game.Loaded:Wait() end

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser= game:GetService("VirtualUser")
local Lighting   = game:GetService("Lighting")
local LP         = Players.LocalPlayer

-- ── ESP Access Lock ──
-- เฉพาะ UserId ที่อยู่ในลิสต์นี้เท่านั้นที่ใช้ ESP ได้ คนอื่นแท็บจะถูกล็อค กดแล้วไม่ทำงาน
-- และมีการเช็คซ้ำใน RenderStepped ด้วย เพื่อไม่ให้ ESP รันได้จริงไม่ว่าจะพยายามเปิดผ่านช่องทางไหน
local ESP_ALLOWED_USERIDS = {[8514985969]=true}
local IsESPAuthorized = ESP_ALLOWED_USERIDS[LP.UserId] == true

-- Localize common functions for faster access
local t_insert, t_sort, ipairs, pairs = table.insert, table.sort, ipairs, pairs
local m_floor, m_min, m_max, m_clamp, m_huge = math.floor, math.min, math.max, math.clamp, math.huge
local v2_new, v3_new, c3_new = Vector2.new, Vector3.new, Color3.new

local char, hum
local function updateChar(c) char=c; hum=c:WaitForChild("Humanoid") end
updateChar(LP.Character or LP.CharacterAdded:Wait())
LP.CharacterAdded:Connect(updateChar)

local folderName = "PlantedTrees_"..LP.UserId
local allTrees, parentFolder, giveWaterRemote

-- FIX 1: Safer HTTP loading to prevent main thread hanging
local _pgBefore = {}
for _,c in ipairs(LP.PlayerGui:GetChildren()) do _pgBefore[c]=true end
local WindUI
local ok, err = pcall(function()
    WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua", true))()
end)
if not ok or not WindUI then
    LP:Kick("Failed to load WindUI library. Rejoin!")
    return
end

local WindUIGui
for _,c in ipairs(LP.PlayerGui:GetChildren()) do
    if not _pgBefore[c] and c:IsA("ScreenGui") then WindUIGui=c; break end
end
_pgBefore = nil

-- ── SpectreTheme v3 — matched to WindUI Default Dark palette ──
local SpectreAccent = Color3.fromRGB(75, 135, 255)

pcall(function()
    WindUI:AddTheme({
        Name        = "SpectreTheme",
        Accent      = SpectreAccent,
        Background  = Color3.fromRGB(25, 25, 25),
        Outline     = Color3.fromRGB(55, 55, 55),
        Button      = Color3.fromRGB(35, 35, 35),
        Text        = Color3.fromRGB(240, 240, 240),
        Placeholder = Color3.fromRGB(140, 140, 140),
        Icon        = Color3.fromRGB(185, 185, 185),
    })
end)

-- ── SpectreUI design tokens + helpers (shared by every floating panel) ──
local SW = {
    UIS      = game:GetService("UserInputService"),
    Tween    = game:GetService("TweenService"),
    Bg       = Color3.fromRGB(20, 20, 20),
    BgTop    = Color3.fromRGB(30, 30, 30),
    Row      = Color3.fromRGB(40, 40, 40),
    Track    = Color3.fromRGB(15, 15, 15),
    Text     = Color3.fromRGB(240, 240, 240),
    Sub      = Color3.fromRGB(155, 155, 155),
    Water    = Color3.fromRGB(86, 176, 255),
    Food     = Color3.fromRGB(255, 118, 176),
    Growth   = Color3.fromRGB(104, 240, 160),
    Danger   = Color3.fromRGB(255, 96, 96),
    Good     = Color3.fromRGB(110, 255, 165),
    Edge1    = Color3.fromRGB(100, 100, 100),
    Edge2    = SpectreAccent,
}

function SW.new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

function SW.round(obj, r)
    return SW.new("UICorner", {CornerRadius = UDim.new(0, r)}, obj)
end

function SW.stroke(obj, color, thick, trans)
    return SW.new("UIStroke", {
        Color = color, Thickness = thick or 1, Transparency = trans or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, obj)
end

-- ขอบไล่สี (ม่วง → ฟ้า) ใช้กับทุกแผงลอยให้หน้าตาเป็นชุดเดียวกัน
function SW.edge(obj, thick, trans, rot)
    local s = SW.stroke(obj, Color3.new(1, 1, 1), thick, trans)
    SW.new("UIGradient", {Color = ColorSequence.new(SW.Edge1, SW.Edge2), Rotation = rot or 90}, s)
    return s
end

-- SMOOTH: cache TweenInfo ต่อความยาว + ไม่สร้าง closure ใหม่ทุกครั้งที่เรียก (เรียกถี่ตอน hover/อัปเดตแท่ง)
local _tweenInfoCache = {}
function SW.tween(obj, t, props)
    local info = _tweenInfoCache[t]
    if not info then
        info = TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        _tweenInfoCache[t] = info
    end
    local ok, tw = pcall(SW.Tween.Create, SW.Tween, obj, info, props)
    if ok and tw then tw:Play() end
end

function SW.pop(frame)
    pcall(function()
        local sc = frame:FindFirstChild("SW_Scale") or SW.new("UIScale", {Name = "SW_Scale"}, frame)
        sc.Scale = 0.92
        SW.tween(sc, 0.2, {Scale = 1})
    end)
end

function SW.fmt(n)
    local s, k = tostring(m_floor(tonumber(n) or 0)), nil
    repeat s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2") until k == 0
    return s
end

-- ══════════════════════════════════════════════════════════════════════════
-- DRAG ENGINE v2 (ลากลื่นขึ้น) — ใช้ร่วมกันทั้งแผงลอย (Safe HUD / Candy) และหน้าต่าง WindUI
--   • อ่านตำแหน่งเมาส์ล่าสุดจาก UIS:GetMouseLocation() ในเฟรมนั้นเลย ไม่ต้องรอ/ฟัง InputChanged
--     (ของเดิมฟัง UIS.InputChanged ถาวรต่อ 1 แผง และมี input.Changed ยิงทุกครั้งที่เมาส์ขยับ)
--   • ต่อ listener เฉพาะตอนกำลังลากเท่านั้น ปล่อยแล้วตัดทิ้งทั้งหมด
--   • ขยับด้วย exponential smoothing แบบไม่ขึ้นกับ FPS → เฟรมตกก็ยังไหลนุ่ม ปล่อยนิ้วแล้วค่อยๆ หยุดเอง
--   • เขียน Position เฉพาะเฟรมที่ค่าเปลี่ยนจริง (ไม่สร้าง/ตั้ง UDim2 ซ้ำตอนอยู่นิ่ง)
--   • กัน "ลากค้าง" (ปล่อยเมาส์นอกจอ/นิ้วหลุด/สลับแอป) ด้วยการเช็คสถานะปุ่มทุกเฟรม
--   • เก็บ Scale ของ Position เดิมไว้ (บวก Offset เพิ่ม) แผงเลยไม่หลุดตำแหน่งเมื่อหมุนจอ/ย่อขยายหน้าต่าง
-- ══════════════════════════════════════════════════════════════════════════
SW.DRAG_FOLLOW = 26                    -- ยิ่งสูงยิ่งตามนิ้วไว (≈ หน่วง 40ms) | 0 = ตามตรงๆ ไม่มี smoothing
SW.THROTTLE_ESP_WHEN_DRAGGING = true   -- ระหว่างลาก ให้ ESP อัปเดตเฟรมเว้นเฟรม เหลือเฟรมไว้ให้ UI
SW.isDragging = false
SW._dragN = 0

local m_exp, m_abs = math.exp, math.abs
local IT_MOUSE1, IT_TOUCH = Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch
local IS_END, IS_CANCEL = Enum.UserInputState.End, Enum.UserInputState.Cancel

-- target  : GuiObject ที่จะถูกขยับ
-- handles : table ของ GuiObject ที่กดแล้วเริ่มลากได้ (เช่น header)
-- opts    : { clamp = ไม่ให้หลุดขอบจอ, onDrag = function(dragging, handle) }
-- return  : { CanDraggable = true, Set = fn }  (หน้าตาเดียวกับ Creator.Drag ของ WindUI)
function SW.attachDrag(target, handles, opts)
    opts = opts or {}
    local mod = {CanDraggable = true}
    function mod.Set(a, b)
        if type(a) == "table" then mod.CanDraggable = b else mod.CanDraggable = a end
    end

    local dragging, isTouch, track, activeHandle = false, false, nil, nil
    local sx, sy, startPos = 0, 0, nil          -- จุดเริ่มของ pointer + Position ตอนเริ่มลาก
    local clampOn, dxMin, dxMax, dyMin, dyMax = false, 0, 0, 0, 0
    local curX, curY, goalX, goalY = 0, 0, 0, 0 -- ระยะที่ขยับจากจุดเริ่ม (px): ปัจจุบัน / เป้าหมาย
    local rsConn, endConn

    local function finish()
        if not dragging then return end
        dragging = false
        SW._dragN = m_max(0, SW._dragN - 1)
        SW.isDragging = SW._dragN > 0
        if endConn then endConn:Disconnect(); endConn = nil end
        if opts.onDrag then pcall(opts.onDrag, false, activeHandle) end
        activeHandle = nil
    end

    local function step(dt)
        if not target.Parent then                -- แผงถูกลบไปแล้ว
            finish()
            if rsConn then rsConn:Disconnect(); rsConn = nil end
            return
        end

        if dragging then
            -- กันลากค้าง: event ปล่อยปุ่มหาย (ปล่อยนอกจอ/สลับแอป) ก็ยังหยุดได้
            if isTouch then
                local st = track.UserInputState
                if st == IS_END or st == IS_CANCEL then finish() end
            elseif not SW.UIS:IsMouseButtonPressed(IT_MOUSE1) then
                finish()
            end
        end

        if dragging and mod.CanDraggable then
            local p = isTouch and track.Position or SW.UIS:GetMouseLocation()
            local dx, dy = p.X - sx, p.Y - sy
            if clampOn then
                dx, dy = m_clamp(dx, dxMin, dxMax), m_clamp(dy, dyMin, dyMax)
            end
            goalX, goalY = dx, dy
        end

        local nx, ny = goalX, goalY
        local k = SW.DRAG_FOLLOW
        if k > 0 then
            local a = 1 - m_exp(-k * dt)          -- ไม่ขึ้นกับ FPS
            nx = curX + (goalX - curX) * a
            ny = curY + (goalY - curY) * a
            if m_abs(goalX - nx) < 0.25 and m_abs(goalY - ny) < 0.25 then nx, ny = goalX, goalY end
        end

        if nx ~= curX or ny ~= curY then
            curX, curY = nx, ny
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + nx,
                startPos.Y.Scale, startPos.Y.Offset + ny
            )
        end

        -- ปล่อยแล้วและไหลถึงเป้าแล้ว → ตัด RenderStepped ทิ้ง (ตอนอยู่นิ่งไม่มีอะไรรันเลย)
        if not dragging and curX == goalX and curY == goalY and rsConn then
            rsConn:Disconnect(); rsConn = nil
        end
    end

    local function begin(handle, input)
        if dragging or not mod.CanDraggable then return end
        local ut = input.UserInputType
        if ut ~= IT_MOUSE1 and ut ~= IT_TOUCH then return end
        local parent = target.Parent
        if not parent then return end

        dragging, activeHandle, track, isTouch = true, handle, input, (ut == IT_TOUCH)
        SW._dragN = SW._dragN + 1
        SW.isDragging = true

        local p = isTouch and input.Position or SW.UIS:GetMouseLocation()
        sx, sy = p.X, p.Y
        startPos = target.Position               -- เริ่มจากตำแหน่งที่เห็นอยู่จริง (ต่อจากที่กำลังไหลค้างได้ ไม่กระตุก)
        curX, curY, goalX, goalY = 0, 0, 0, 0

        -- จำขอบเขตตอนเริ่มลากครั้งเดียว (ไม่อ่าน AbsoluteSize ทุก event เพราะบังคับ layout คำนวณใหม่ทั้งแผง)
        clampOn = opts.clamp and parent:IsA("GuiBase2d") or false
        if clampOn then
            local rel = target.AbsolutePosition - parent.AbsolutePosition
            local ps, sz = parent.AbsoluteSize, target.AbsoluteSize
            local maxX, maxY = m_max(0, ps.X - sz.X), m_max(0, ps.Y - sz.Y)
            dxMin, dxMax = -rel.X, maxX - rel.X
            dyMin, dyMax = -rel.Y, maxY - rel.Y
        end

        endConn = SW.UIS.InputEnded:Connect(function(i)
            if isTouch then
                if i == track then finish() end
            elseif i.UserInputType == IT_MOUSE1 then
                finish()
            end
        end)
        if not rsConn then rsConn = RunService.RenderStepped:Connect(step) end
        if opts.onDrag then pcall(opts.onDrag, true, handle) end
    end

    for _, h in pairs(handles) do
        h.InputBegan:Connect(function(input) begin(h, input) end)
    end
    return mod
end

-- ลากแผงลอยของเรา (ไม่ให้หลุดขอบจอ) — signature เดิม
function SW.drag(handle, target)
    SW.attachDrag(target, {handle}, {clamp = true})
end

-- ── แทน Creator.Drag ของ WindUI (หน้าต่างหลัก + ปุ่มเปิด) ──
-- ของเดิมสร้าง Tween ใหม่ "ทุกครั้งที่เมาส์ขยับ" (0.02 วิ) → alloc ถี่ + ตำแหน่งกระตุกตามจังหวะ event
-- ต้องแพตช์ก่อน WindUI:CreateWindow เพราะ WindUI เรียก Creator.Drag ตอนสร้างหน้าต่าง
-- ถ้า library เวอร์ชันนั้นไม่มี Creator.Drag / เรียกผ่านทางอื่น จะไม่แพตช์ (มี warn บอก) และใช้ของเดิมต่อโดยไม่พัง
SW.windDragPatched = false
do
    local Creator = type(WindUI) == "table" and WindUI.Creator or nil
    if type(Creator) == "table" and type(Creator.Drag) == "function" then
        local origDrag = Creator.Drag
        Creator.Drag = function(mainFrame, dragFrames, ondrag)
            local ok, mod = pcall(function()
                local handles = type(dragFrames) == "table" and dragFrames or {mainFrame}
                return SW.attachDrag(mainFrame, handles, {
                    clamp = false,
                    onDrag = type(ondrag) == "function" and ondrag or nil,
                })
            end)
            if ok and mod then SW.windDragPatched = true; return mod end
            return origDrag(mainFrame, dragFrames, ondrag)   -- ล้มเหลว → กลับไปใช้ของ WindUI
        end
    end
end

local AntiAFKEnabled = true
local FriendSet = {}

local function refreshFriends()
    FriendSet = {}
    pcall(function()
        local pages = Players:GetFriendsAsync(LP.UserId)
        while true do
            for _, info in ipairs(pages:GetCurrentPage()) do FriendSet[info.Id]=true end
            if pages.IsFinished then break end
            pages:AdvanceToNextPageAsync()
        end
    end)
end
task.spawn(refreshFriends)

-- FIX 2: Pcall HTTP for Config
local _Cfg
ok, err = pcall(function()
    _Cfg = loadstring(game:HttpGet("https://raw.githubusercontent.com/Captaineieiei/Script-/refs/heads/main/SpectreConfig.lua", true))()
end)
if not ok or not _Cfg then LP:Kick("Failed to load Config. Rejoin!") return end

local CFG, SaveCFG, LoadCFG, OnCFGLoaded = _Cfg.new(
    "SpectreWare.json",
    {"Enabled","NPCSESP","ShowHP","ShowHPText","ShowName","ShowDist","BypassAntiESP","HideDeadESP","HideFriends"},
    {"BoxThickness","HPBarWidth","NameSize","MaxDist","ESPDetailDist"},
    {"BoxColor"},
    {
        Enabled=false, NPCSESP=false,
        BoxColor=Color3.fromRGB(255,255,255), BoxThickness=1.5,
        ShowHP=true, HPBarWidth=4, ShowHPText=true,
        ShowName=true, NameSize=13,
        ShowDist=true, MaxDist=600,
        BypassAntiESP=true, HideDeadESP=true, HideFriends=false,
        ESPDetailDist=120, -- ในระยะนี้วาดโครงกระดูกเต็ม ไกลกว่านี้วาดกรอบสี่เหลี่ยมง่ายๆแทน (ลดจำนวน WorldToViewportPoint ต่อเฟรมเยอะมากเวลามีคน/NPC เยอะ)
    }
)

local _saveCFGPending = false
local function DebouncedSaveCFG()
    if _saveCFGPending then return end
    _saveCFGPending = true
    task.delay(0.5, function()
        _saveCFGPending = false
        pcall(SaveCFG)
    end)
end

local Window = WindUI:CreateWindow({
    Title="SpectreWare | NEVER TOWN", Icon="rbxassetid://71815202801684",
    Author="#Captain", Folder="MySuperHub",
    Size=UDim2.fromOffset(580,460), MinSize=Vector2.new(560,350),
    MaxSize=Vector2.new(850,560), Transparent=true, Theme="SpectreTheme",
    Resizable=true, SideBarWidth=200, BackgroundImageTransparency=0.42,
    HideSearchBar=true, ScrollBarEnabled=false,
})
if not SW.windDragPatched then
    warn("[SpectreWare] WindUI drag patch ไม่ทำงาน (library เวอร์ชันนี้ไม่ได้เรียก Creator.Drag ผ่านตารางที่แพตช์ได้) — หน้าต่างหลักใช้การลากของ WindUI เดิม; แผงลอย Candy/HUD ยังใช้ engine ใหม่")
end
Window:Tag({Title="v1.6.12", Icon="github", Color=Color3.fromRGB(75,135,255), Radius=13})
Window:SetIconSize(80)
-- ตัดชื่อบนปุ่มเปิดให้สั้นลง (ตัวเต็ม "SpectreWare | NEVER TOWN" ยาวเกินจอมือถือ) + ขอบไล่สีตามธีม Spectre
if not pcall(function()
    Window:EditOpenButton({
        Title = "SpectreWare",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 2,
        Color = ColorSequence.new(Color3.fromRGB(75, 135, 255), Color3.fromRGB(50, 100, 220)),
        Draggable = true,
    })
end) then
    pcall(function() Window:EditOpenButton({ Title = "SpectreWare" }) end)
end

task.spawn(function()
    allTrees = workspace:WaitForChild("AllPlantedTrees",30)
    if allTrees then parentFolder=allTrees:WaitForChild(folderName,15) end
    pcall(function()
        giveWaterRemote = game:GetService("ReplicatedStorage")
            :WaitForChild("Grow_vegetables",15):WaitForChild("GiveWater",10)
    end)
    task.wait(0.5); buildWaterPickDropdown()
end)

local function findLabelByText(text)
    for _,root in ipairs({game:GetService("CoreGui"), LP.PlayerGui}) do
        local found
        pcall(function()
            local descendants = root:GetDescendants()
            for i,v in ipairs(descendants) do
                if i % 200 == 0 then task.wait() end
                if v:IsA("TextLabel") and v.Text == text then found = v; break end
            end
        end)
        if found then return found end
    end
end

local function resolveRemotePath(root, path, timeout)
    local cur = root
    for _,name in ipairs(path) do
        if not cur then return nil end
        cur = cur:WaitForChild(name, timeout or 1)
    end
    return cur
end

local function optionKey(opt)
    return type(opt)=="table" and opt.Title or tostring(opt)
end

local AmountDescLabel
local function setAmount(text)
    if AmountDescLabel and AmountDescLabel.Parent then
        text = tostring(text)
        -- SMOOTH: ข้อความเดิมไม่ต้องเขียนซ้ำ (การเขียน Text ของ label ใน WindUI ทำให้ layout คำนวณใหม่ ทุก 3 วิ)
        if AmountDescLabel.Text ~= text then
            pcall(function() AmountDescLabel.Text = text end)
        end
    end
end

local SafeDescLabel

local function getSafeQty(itemName)
    local ok, qty = pcall(function()
        local sf = LP:FindFirstChild("Safe")
        if not sf then return 0 end
        local v = sf:FindFirstChild(itemName)
        return v and m_floor(v.Value) or 0
    end)
    return (ok and qty) or 0
end

-- ── Floating Safe HUD ──
local _hudGui, _hudIcon, _hudName, _hudCount

local function buildSafeHud()
    if _hudGui and _hudGui.Parent then return end

    _hudGui = Instance.new("ScreenGui")
    _hudGui.Name = "SW_SafeHUD"
    _hudGui.ResetOnSpawn = false
    _hudGui.IgnoreGuiInset = true
    _hudGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    _hudGui.DisplayOrder = 40
    _hudGui.Parent = LP.PlayerGui

    local card = SW.new("Frame", {
        Name = "Card", Size = UDim2.fromOffset(204, 66), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.12, 0, 0.78, 0), BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.02, BorderSizePixel = 0, Active = true, Visible = false,
    }, _hudGui)
    SW.round(card, 16)
    SW.new("UIGradient", {Color = ColorSequence.new(SW.BgTop, SW.Bg), Rotation = 125}, card)
    SW.edge(card, 1.5, 0.2, 45)

    local iconBg = SW.new("Frame", {
        Size = UDim2.fromOffset(46, 46), Position = UDim2.new(0, 10, 0.5, -23),
        BackgroundColor3 = SW.Row, BorderSizePixel = 0, ZIndex = 2,
    }, card)
    SW.round(iconBg, 12)
    SW.stroke(iconBg, SpectreAccent, 1, 0.55)

    _hudIcon = SW.new("ImageLabel", {
        Size = UDim2.fromOffset(36, 36), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1,
        ScaleType = Enum.ScaleType.Fit, ZIndex = 3,
    }, iconBg)

    _hudName = SW.new("TextLabel", {
        Size = UDim2.new(1, -74, 0, 20), Position = UDim2.fromOffset(64, 9),
        BackgroundTransparency = 1, TextColor3 = SW.Text, Font = Enum.Font.GothamBold,
        TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 2,
    }, card)

    _hudCount = SW.new("TextLabel", {
        Size = UDim2.new(1, -74, 0, 24), Position = UDim2.fromOffset(64, 32),
        BackgroundTransparency = 1, TextColor3 = SW.Good, Font = Enum.Font.GothamBold,
        TextSize = 17, RichText = true, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2,
    }, card)

    SW.drag(card, card)
end

local function getHudCard()
    if _hudGui and _hudGui.Parent then
        return _hudGui:FindFirstChild("Card")
    end
end


-- ── ESP ──
local ESPObjects     = {}
-- OPTIMIZE: frame-stride throttle. Far/off-screen-ish targets don't need a fresh
-- WorldToViewportPoint projection every single RenderStepped — reusing last frame's
-- screen box for 2-4 frames is visually lossless at range but skips the priciest calls
-- in the hot loop (this is what actually chokes framerate once 15-20+ ESP boxes stack up).
local _frameCounter   = 0
local _staggerCounter = 0
local _espPartCache   = {}
local _espCacheBuild  = {}  -- FIX: ไม่เคย declare ทำให้ indexing nil error ใน updateESPObject → ESP ไม่ขึ้น
local Z_MARGIN       = 0.5  -- Z-buffer margin: kills edge-of-camera flicker

-- FIX (ESP ติดจอ/กะพริบตอนหมุนกล้องเร็ว): ตอนกล้องหมุนเร็ว จุดที่ cache ไว้ (skipProjection)
-- จะไม่ถูกเช็คว่ายังอยู่ในจอไหม เลยค้างตำแหน่งเดิมไว้ก่อนจะกระโดดไปตำแหน่งจริง/หายวับ ๆ
-- แก้โดยวัดมุมที่กล้องหมุนต่อเฟรม ถ้าหมุนเร็วเกิน threshold ให้บังคับรีเฟรช (ยิง WorldToViewportPoint ใหม่)
-- ทุกตัวทุกเฟรมชั่วคราว จนกว่าจะหมุนช้าลงถึงจะกลับไปใช้ stride ประหยัดเฟรมตามเดิม
local _lastCamLook = nil
local _fastRotate  = false
-- FIX: 0.035 rad/frame = ~120°/s at 60fps — way too permissive. Any normal camera
-- turn sailed under it, so _fastRotate stayed false and the joint-stride cache kept
-- serving stale on-screen coordinates. 0.010 rad/frame ≈ 34°/s catches typical
-- turning without triggering on idle micro-jitter.
local ROTATE_ANGLE_THRESHOLD = 0.010

local ESP_EXCLUDE_PATHS = {
    {"System", "[Server] Npc_Seal"},
    {"System", "[Prompt] Team"},
    {"Farmer_1"},
}

-- OPTIMIZE: Cache excluded status to prevent path lookup every frame
local _excludedCache = setmetatable({}, {__mode = "k"})
local function isESPExcluded(model)
    if _excludedCache[model] ~= nil then return _excludedCache[model] end
    local result = false
    for _,path in ipairs(ESP_EXCLUDE_PATHS) do
        local node = workspace
        for _,name in ipairs(path) do
            node = node:FindFirstChild(name)
            if not node then break end
        end
        if node and (model == node or model:IsDescendantOf(node)) then
            result = true
            break
        end
    end
    _excludedCache[model] = result
    return result
end

local function newLine(thick, color)
    local d=Drawing.new("Line"); d.Thickness=thick; d.Color=color; d.Transparency=1; d.Visible=false; return d
end
local function newText(size, color)
    local d=Drawing.new("Text"); d.Size=size; d.Color=color; d.Outline=true; d.Center=true; d.Visible=false; return d
end

local RIG_BONES_R15 = {
    {"Head","UpperTorso"}, {"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"}, {"LeftUpperArm","LeftLowerArm"}, {"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"}, {"RightUpperArm","RightLowerArm"}, {"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"}, {"LeftUpperLeg","LeftLowerLeg"}, {"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"}, {"RightUpperLeg","RightLowerLeg"}, {"RightLowerLeg","RightFoot"},
}
local RIG_BONES_R6 = {
    {"Head","Torso"},
    {"Torso","Left Arm"}, {"Torso","Right Arm"},
    {"Torso","Left Leg"}, {"Torso","Right Leg"},
}

local function detectRigType(model)
    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum then
        return hum.RigType == Enum.HumanoidRigType.R15
    end
    return model:FindFirstChild("UpperTorso") ~= nil
end

local function buildPartCache(model)
    local parts = {}
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then parts[#parts+1] = p end
    end
    _espPartCache[model] = parts
end

local function makeESP(model, isNPC)
    if ESPObjects[model] then return end
    local isR15 = detectRigType(model)
    local bones = isR15 and RIG_BONES_R15 or RIG_BONES_R6
    local skeleton={}; for i=1,#bones do skeleton[i]=newLine(CFG.BoxThickness, CFG.BoxColor) end
    ESPObjects[model]={
        skeleton=skeleton, bones=bones, jointCache=nil, jointScreen=nil, isNPC=isNPC or false,
        hpBar    = newLine(CFG.HPBarWidth, Color3.new(0,1,0)),
        nameLabel= newText(CFG.NameSize,   Color3.fromRGB(185,170,240)),
        distLabel= newText(11,             Color3.fromRGB(140,130,175)),
        hpText   = newText(16,             Color3.fromRGB(110,255,165)),
        _vis = false, lastDistStr = "", lastHpStr = "",
        staggerId = _staggerCounter % 4
    }
    _staggerCounter = _staggerCounter + 1
    if CFG.BypassAntiESP then buildPartCache(model) end
end

local function removeESP(model)
    local obj=ESPObjects[model]; if not obj then return end
    for _,l in ipairs(obj.skeleton) do pcall(function() l:Remove() end) end
    for _,k in ipairs({"hpBar","nameLabel","distLabel","hpText"}) do
        pcall(function() obj[k]:Remove() end)
    end
    ESPObjects[model]=nil
    _espPartCache[model]=nil
    _excludedCache[model] = nil
end

-- OPTIMIZE: Only update Visible property if it changed
local function setVisible(obj, v)
    if obj._vis == v then return end
    obj._vis = v
    for i=1, #obj.skeleton do obj.skeleton[i].Visible = v end
    obj.hpBar.Visible=v; obj.nameLabel.Visible=v
    obj.distLabel.Visible=v; obj.hpText.Visible=v
end

-- OPTIMIZE: no per-frame table alloc for the far-mode box (was allocating 1 outer + 4 inner tables every object every frame)
local function applyBoxLine(obj, i, ax, ay, bx, by)
    local line = obj.skeleton[i]
    if not line then return end
    if line.Thickness ~= CFG.BoxThickness then line.Thickness = CFG.BoxThickness end
    if line.Color ~= CFG.BoxColor then line.Color = CFG.BoxColor end
    line.From = v2_new(ax, ay); line.To = v2_new(bx, by)
    line.Visible = true
end

-- OPTIMIZE: Massive Performance Boost
local function updateESPObject(model, obj, Camera, myRoot, myPos, fastRotate)
    -- OPTIMIZE: cache root/humanoid on the obj instead of FindFirstChild every frame;
    -- only re-look-up when the cached ref went stale (character respawned/parts swapped)
    local root = obj.rootCache
    if not root or not root.Parent then
        root = model:FindFirstChild("HumanoidRootPart")
        obj.rootCache = root
    end
    local hum = obj.humCache
    if not hum or not hum.Parent then
        hum = model:FindFirstChildOfClass("Humanoid")
        obj.humCache = hum
    end
    local isValid = myRoot ~= nil

    if not root or not hum then isValid = false end
    if isValid and CFG.HideDeadESP and hum.Health <= 0 then isValid = false end

    local plr = nil
    local dist = 0
    if isValid and myPos then
        dist = (myPos - root.Position).Magnitude
        if dist > CFG.MaxDist then isValid = false end

        if isValid then
            if not obj.isNPC then
                plr = Players:GetPlayerFromCharacter(model)
                if not plr then isValid = false
                elseif CFG.HideFriends and FriendSet[plr.UserId] then isValid = false end
            elseif isESPExcluded(model) then
                removeESP(model); return
            end
        end
    end

    if isValid and CFG.BypassAntiESP then
        local parts = _espPartCache[model]
        if parts then
            for i = 1, #parts do
                local p = parts[i]
                if p.Parent then p.LocalTransparencyModifier = 0 end
            end
        elseif not _espCacheBuild[model] then
            _espCacheBuild[model] = true
            task.spawn(function()
                local newParts = {}
                local idx = 1
                for _, p in ipairs(model:GetDescendants()) do
                    if p:IsA("BasePart") then 
                        newParts[idx] = p
                        idx = idx + 1
                    end
                end
                _espPartCache[model] = newParts
                _espCacheBuild[model] = nil
            end)
        end
    end

    -- FIX (flicker / ESP-sticks-to-screen): always re-project the 3 anchor points
    -- every frame. The old code reused `lastPos3/lastTopPos3/lastBotPos3` on some
    -- frames to save a few WorldToViewportPoint calls — but a cached *screen* coord
    -- is only valid for the camera pose at the instant it was captured. The moment
    -- the camera turned, the cached box was drawn at the previous screen position,
    -- which is exactly why ESP "followed" the camera when you looked away and
    -- flickered as it alternated between stale and fresh frames.
    --
    -- Cost of always projecting: 3 extra WorldToViewportPoint calls per target per
    -- frame. The bone loop below already does up to 14 more per target, so this is
    -- a rounding error and the flicker is gone.
    if not isValid then
        setVisible(obj, false)
        return
    end

    local vp = Camera.ViewportSize
    local pos3 = Camera:WorldToViewportPoint(root.Position)
    if pos3.Z <= Z_MARGIN or pos3.X < 0 or pos3.X > vp.X or pos3.Y < 0 or pos3.Y > vp.Y then
        setVisible(obj, false)
        return
    end

    local head = obj.headCache
    if not head or not head.Parent then
        head = model:FindFirstChild("Head") or root
        obj.headCache = head
    end
    local topPos3 = Camera:WorldToViewportPoint(head.Position + v3_new(0, head.Size.Y / 2 + 0.3, 0))
    local botPos3 = Camera:WorldToViewportPoint(root.Position - v3_new(0, 3, 0))

    if topPos3.Z <= Z_MARGIN or botPos3.Z <= Z_MARGIN
        or topPos3.X < 0 or topPos3.X > vp.X or topPos3.Y < 0 or topPos3.Y > vp.Y
        or botPos3.X < 0 or botPos3.X > vp.X or botPos3.Y < 0 or botPos3.Y > vp.Y then
        setVisible(obj, false)
        return
    end

    -- Sync visibility flag. Drawings are individually re-shown below (skeleton
    -- lines / hpBar / labels), so we don't need to touch them here — this is just
    -- so setVisible(obj,false) on a future invalid frame isn't a no-op.
    obj._vis = true

    local cx = pos3.X
    local y1 = m_min(topPos3.Y, botPos3.Y)
    local y2 = m_max(topPos3.Y, botPos3.Y)
    local h  = y2 - y1

    if h < 2 then h = 2 end
    local w  = h * 0.6
    local x1, x2 = cx - w/2, cx + w/2

    -- LOD: โครงกระดูกเต็มรูปแบบต้องคำนวณ WorldToViewportPoint เพิ่มอีก ~14 จุดต่อตัวต่อเฟรม
    -- (นอกเหนือจาก 3 จุดที่คำนวณไปแล้วข้างบนสำหรับเช็คความถูกต้อง) ถ้ามีคน/NPC เยอะพร้อมกันนี่คือจุดที่กินเฟรมสุด
    -- เลยจำกัดไว้แค่ระยะใกล้ (CFG.ESPDetailDist) ไกลกว่านั้นวาดกรอบสี่เหลี่ยมง่ายๆจาก 4 จุดที่มีอยู่แล้วพอ ไม่ต้องยิง WorldToViewportPoint เพิ่มเลย
    local detailDist = CFG.ESPDetailDist or 120 -- fallback เผื่อ CFG.json เก่าที่ยังไม่มี field นี้
    local useDetail = dist <= detailDist

    -- OPTIMIZE (แก้ตามที่คุย): โครงกระดูกคือจุดที่แพงสุดต่อ object (~14 WorldToViewportPoint
    -- เพิ่มต่อเฟรม) ตัวที่อยู่ไกลหน่อย (แต่ยังอยู่ในระยะ detail) ไม่จำเป็นต้อง refresh ทุกเฟรม
    -- reuse jointScreen เดิมแล้ววาดเส้นซ้ำ — ใกล้มากๆ (DETAIL_CLOSE_RANGE) ยัง refresh ทุกเฟรมเหมือนเดิม
    -- เพื่อไม่ให้เห็นการหน่วงตอนประชิดตัว
    --
    -- FIX: joints are screen-space too — during any camera motion they must be
    -- re-projected or the skeleton visibly lags the bounding box. fastRotate is
    -- now sensitive enough (see ROTATE_ANGLE_THRESHOLD) to trip on real turns,
    -- so the stride only kicks in when the camera is essentially static.
    local DETAIL_CLOSE_RANGE = 25
    local detailStride = (fastRotate or dist <= DETAIL_CLOSE_RANGE) and 1 or 3
    local skipDetailRefresh = useDetail and detailStride > 1
        and obj.jointScreen ~= nil
        and not fastRotate
        and ((_frameCounter + obj.staggerId) % detailStride ~= 0)

    if useDetail and not skipDetailRefresh then
        local joints = obj.jointCache
        if not joints then joints={}; obj.jointCache=joints end
        for _,bone in ipairs(obj.bones) do
            for _,jname in ipairs(bone) do
                -- FIX: ถ้า part ที่ cache ไว้โดน Destroy/หลุดออกจาก model ไปแล้ว (Parent เป็น nil)
                -- ต้องหาใหม่ ไม่งั้น Position จะค้างอยู่ค่าสุดท้ายก่อนโดนทำลาย ทำให้เส้นโครงกระดูกลอยค้างจุดเดิม
                local cached = joints[jname]
                if not cached or not cached.Parent then
                    joints[jname] = model:FindFirstChild(jname)
                end
            end
        end

        local jointScreen = obj.jointScreen
        if not jointScreen then jointScreen={}; obj.jointScreen=jointScreen end
        for jname, part in pairs(joints) do
            if part and part.Parent then
                local vp2 = Camera:WorldToViewportPoint(part.Position)
                jointScreen[jname] = (vp2.Z > 0) and vp2 or nil
            else
                jointScreen[jname] = nil
            end
        end

        for i, bone in ipairs(obj.bones) do
            local line = obj.skeleton[i]
            local v1, v2 = jointScreen[bone[1]], jointScreen[bone[2]]
            if v1 and v2 then
                if line.Thickness ~= CFG.BoxThickness then line.Thickness = CFG.BoxThickness end
                if line.Color ~= CFG.BoxColor then line.Color = CFG.BoxColor end
                line.From = v2_new(v1.X, v1.Y); line.To = v2_new(v2.X, v2.Y)
                line.Visible = true
            else
                if line.Visible then line.Visible = false end
            end
        end
    elseif useDetail then
        -- เฟรมที่ไม่ refresh: ใช้ jointScreen เดิมวาดซ้ำ (ไม่ยิง WorldToViewportPoint เพิ่ม)
        local jointScreen = obj.jointScreen
        for i, bone in ipairs(obj.bones) do
            local line = obj.skeleton[i]
            local v1, v2 = jointScreen[bone[1]], jointScreen[bone[2]]
            if v1 and v2 then
                line.From = v2_new(v1.X, v1.Y); line.To = v2_new(v2.X, v2.Y)
                line.Visible = true
            else
                if line.Visible then line.Visible = false end
            end
        end
    else
        -- โหมดไกล: ใช้แค่ 4 เส้นแรกของ skeleton array วาดเป็นกรอบสี่เหลี่ยม จาก x1,y1,x2,y2 ที่มีอยู่แล้ว
        -- OPTIMIZE: เขียนตรงแทนสร้าง table ชั่วคราว (boxPts) ทุกเฟรมทุกตัว ลด GC churn ตอนมีคน/NPC ไกลๆ เยอะ
        applyBoxLine(obj, 1, x1,y1, x2,y1) -- บน
        applyBoxLine(obj, 2, x2,y1, x2,y2) -- ขวา
        applyBoxLine(obj, 3, x2,y2, x1,y2) -- ล่าง
        applyBoxLine(obj, 4, x1,y2, x1,y1) -- ซ้าย
        for i=5, #obj.skeleton do
            if obj.skeleton[i].Visible then obj.skeleton[i].Visible = false end
        end
    end

    local hpR = m_clamp(hum.Health / m_max(hum.MaxHealth, 1), 0, 1)
    -- OPTIMIZE: skip recomputing Color3.fromRGB when the rounded hp% hasn't moved since last frame
    local hpBucket = m_floor(hpR*200) -- 0.5% buckets, plenty smooth for a color gradient
    local hpColor = obj.lastHpBucket == hpBucket and obj.lastHpColor or nil
    if not hpColor then
        hpColor = hpR > 0.5
            and Color3.fromRGB(m_floor(255*(1-hpR)*2), 255, 0)
            or  Color3.fromRGB(255, m_floor(255*hpR*2), 0)
        obj.lastHpBucket = hpBucket
        obj.lastHpColor = hpColor
    end
    if obj.hpBar.Color ~= hpColor then obj.hpBar.Color = hpColor end
    obj.hpBar.From = v2_new(x1, y2+4)
    obj.hpBar.To = v2_new(x1+(x2-x1)*hpR, y2+4)
    obj.hpBar.Visible = CFG.ShowHP

    if CFG.ShowName then
        local nameStr = plr and plr.Name or model.Name
        if obj.nameLabel.Text ~= nameStr then obj.nameLabel.Text = nameStr end
        if obj.nameLabel.Size ~= CFG.NameSize then obj.nameLabel.Size = CFG.NameSize end
        obj.nameLabel.Position = v2_new(cx, y1-CFG.NameSize-2)
        obj.nameLabel.Visible = true
    else
        obj.nameLabel.Visible = false
    end

    if CFG.ShowDist then
        -- OPTIMIZE: เทียบค่าตัวเลขก่อน ไม่เรียก string.format ทุกเฟรมถ้าค่าปัดแล้วเท่าเดิม
        local distRounded = m_floor(dist + 0.5)
        if obj.lastDistRounded ~= distRounded then
            obj.lastDistRounded = distRounded
            obj.lastDistStr = distRounded.." studs"
            obj.distLabel.Text = obj.lastDistStr
        end
        obj.distLabel.Position = v2_new(cx, y2+30)
        obj.distLabel.Visible = true
    else
        obj.distLabel.Visible = false
    end

    if CFG.ShowHPText then
        local hpPct = m_floor(hpR*100)
        local healthI, maxHealthI = m_floor(hum.Health), m_floor(hum.MaxHealth)
        -- OPTIMIZE: เทียบตัวเลขดิบก่อน ไม่ต่อ string ทุกเฟรมถ้าเลขเดิม (ลด GC churn ตอน ESP เยอะ)
        if obj.lastHpPct ~= hpPct or obj.lastHealthI ~= healthI or obj.lastMaxHealthI ~= maxHealthI then
            obj.lastHpPct, obj.lastHealthI, obj.lastMaxHealthI = hpPct, healthI, maxHealthI
            obj.hpText.Text = hpPct.."%  ("..healthI.."/"..maxHealthI..")"
        end
        local dynSize = m_clamp(m_floor(22 - dist/14), 11, 22)
        if obj.hpText.Size ~= dynSize then obj.hpText.Size = dynSize end
        if obj.hpText.Color ~= hpColor then obj.hpText.Color = hpColor end
        obj.hpText.Position = v2_new(cx, y2+12)
        obj.hpText.Visible = true
    else
        obj.hpText.Visible = false
    end
end

RunService.RenderStepped:Connect(function()
    if not IsESPAuthorized then return end
    if not CFG.Enabled then return end
    _frameCounter = _frameCounter + 1
    -- SMOOTH: ระหว่างลาก UI ให้ ESP อัปเดตเฟรมเว้นเฟรม (Drawing ค้างตำแหน่งล่าสุดไว้) → เหลืองบเฟรมให้ UI ลื่น
    -- ปล่อยแล้วกลับมาเต็มอัตราเอง ปิดได้ที่ SW.THROTTLE_ESP_WHEN_DRAGGING = false
    if SW.THROTTLE_ESP_WHEN_DRAGGING and SW.isDragging and _frameCounter % 2 == 0 then return end
    local Camera = workspace.CurrentCamera
    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local myPos = myRoot and myRoot.Position

    -- FIX: วัดมุมที่กล้องหมุนเทียบกับเฟรมก่อนหน้า ถ้าหมุนเร็วเกิน threshold ให้ปิด stride-cache
    -- ชั่วคราวทั้งหมด (ดูฟังก์ชัน updateESPObject) ไม่งั้น ESP จะติดจอ/กะพริบตอนหมุนกล้องแรง ๆ
    _fastRotate = false
    if Camera then
        local ok, look = pcall(function() return Camera.CFrame.LookVector end)
        if ok and look then
            if _lastCamLook then
                local dot = m_clamp(look:Dot(_lastCamLook), -1, 1)
                _fastRotate = math.acos(dot) > ROTATE_ANGLE_THRESHOLD
            end
            _lastCamLook = look
        end
    end

    for model, obj in pairs(ESPObjects) do
        if not model.Parent then
            -- OPTIMIZE/FIX: โมเดลถูกลบ/ออกจากเกมไปแล้วแต่ event cleanup ไม่ทัน -> เก็บกวาดทิ้งเลย ไม่ปล่อยให้ ESP ค้างจอ
            removeESP(model)
        else
            pcall(updateESPObject, model, obj, Camera, myRoot, myPos, _fastRotate)
        end
    end
end)

local _plrConns = {}
local _npcConns = {}
local function trackPlayer(plr)
    if plr==LP then return end
    local function onChar(c)
        -- FIX: ถ้าเกมเปิด StreamingEnabled คนที่อยู่ไกลจากเรา HumanoidRootPart จะยังไม่ stream เข้ามา
        -- ถ้ารอแบบมี timeout แล้วยอมแพ้ (return ทิ้ง) จะไม่มีทาง sp ให้คนนั้นได้อีกเลยแม้จะเดินเข้ามาใกล้แล้ว
        -- เลยเปลี่ยนเป็นรอวนไม่จำกัดเวลา แต่เช็คทุกรอบว่าตัวละครยังอยู่จริงไหม (กันไม่ให้ค้างถ้าออกจากเกมไปแล้ว)
        while c.Parent and not c:FindFirstChild("HumanoidRootPart") do
            task.wait(1)
        end
        if not c.Parent or not c:FindFirstChild("HumanoidRootPart") then return end
        if ESPObjects[c] then removeESP(c) end
        makeESP(c, false)
        c.DescendantAdded:Connect(function(d)
            if d:IsA("BasePart") then _espPartCache[c]=nil end
        end)
        c.AncestryChanged:Connect(function(_,p)
            if not p then removeESP(c); _espPartCache[c]=nil end
        end)
    end
    local cr=plr.CharacterRemoving:Connect(function(c) removeESP(c); _espPartCache[c]=nil end)
    local ca=plr.CharacterAdded:Connect(function(c) task.spawn(onChar, c) end)
    if plr.Character then task.spawn(onChar, plr.Character) end
    _plrConns[plr]={ca,cr}
end
Players.PlayerAdded:Connect(trackPlayer)
Players.PlayerRemoving:Connect(function(plr)
    if _plrConns[plr] then for _,c in ipairs(_plrConns[plr]) do c:Disconnect() end; _plrConns[plr]=nil end
    if plr.Character then removeESP(plr.Character); _espPartCache[plr.Character]=nil end
end)
for _,plr in ipairs(Players:GetPlayers()) do trackPlayer(plr) end

local esp = {}
function esp:FireScan()
    if not IsESPAuthorized then return end
    if not CFG.Enabled then
        for _,obj in pairs(ESPObjects) do setVisible(obj,false) end; return
    end
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=LP and plr.Character and not ESPObjects[plr.Character] then makeESP(plr.Character, false) end
    end
end
function esp:ScanWorkspace()
    if not IsESPAuthorized then return end
    local all = workspace:GetDescendants()
    local count = 0
    for _,obj in ipairs(all) do
        count = count + 1
        if count % 150 == 0 then task.wait() end
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid")
        and not Players:GetPlayerFromCharacter(obj) and obj~=LP.Character
        and not isESPExcluded(obj) then
            if not ESPObjects[obj] then makeESP(obj, true) end
            if not _npcConns[obj] then
                _npcConns[obj] = obj.AncestryChanged:Connect(function(_,p)
                    if not p then
                        removeESP(obj); _espPartCache[obj]=nil
                        if _npcConns[obj] then _npcConns[obj]:Disconnect(); _npcConns[obj]=nil end
                    end
                end)
            end
        end
    end
end
function esp:Clear()
    for model in pairs(ESPObjects) do removeESP(model) end
    _espPartCache = {}
    _espCacheBuild = {}
end
esp.RemoveAll = esp.Clear

task.spawn(function()
    local _npcDescDebounce = setmetatable({}, {__mode = "k"})
    workspace.DescendantAdded:Connect(function(desc)
        if not CFG.Enabled or not CFG.NPCSESP then return end
        if not desc:IsA("Model") then return end
        if _npcDescDebounce[desc] then return end
        _npcDescDebounce[desc] = true
        task.delay(1, function()
            _npcDescDebounce[desc] = nil
            if not desc.Parent then return end
            if desc:FindFirstChildOfClass("Humanoid")
            and not Players:GetPlayerFromCharacter(desc) and desc ~= LP.Character
            and not isESPExcluded(desc) and not ESPObjects[desc] then
                makeESP(desc, true)
                if not _npcConns[desc] then
                    _npcConns[desc] = desc.AncestryChanged:Connect(function(_,p)
                        if not p then removeESP(desc); _espPartCache[desc]=nil; if _npcConns[desc] then _npcConns[desc]:Disconnect(); _npcConns[desc]=nil end end
                    end)
                end
            end
        end)
    end)
end)

-- ── TAB: MENU / FARM ──
local FarmTab = Window:Tab({Title="Menu", Icon="archive", Locked=false})
local DepositRemote, FarmRunning = nil, false
local BACKPACK_GUI = "Backpack_Never"

local function getScrolling()
    local bp=LP.PlayerGui:FindFirstChild(BACKPACK_GUI); if not bp then return nil end
    local bg=bp:FindFirstChild("BG");                  if not bg then return nil end
    local it=bg:FindFirstChild("item");                if not it then return nil end
    return it:FindFirstChild("Scrollingitem")
end

local ITEM_THAI = {
    ["Grape"]        = "องุ่น",
    ["Peach"]        = "พีช",
    ["Orange"]       = "ส้ม",
    ["Cauliflower"]  = "กะหล่ำดอก",
    ["Corn"]         = "ข้าวโพด",
    ["Gold"]         = "ทอง",
    ["Iron"]         = "เหล็ก",
    ["MineIron"]     = "แร่เหล็ก",
    ["MineGold"]     = "แร่ทอง",
}

local BLOCKED_ITEMS = {
    ["CASH"]    = true,
    ["IDCard"]  = true,
    ["R8"]      = true,
    ["Classic"] = true,
}

local function loadBackpackItems()
    local scrolling = getScrolling()
    if not scrolling then
        local ok,s = pcall(function()
            return LP.PlayerGui:WaitForChild(BACKPACK_GUI,5):WaitForChild("BG",5)
                :WaitForChild("item",5):WaitForChild("Scrollingitem",5)
        end)
        if ok then scrolling=s end
    end

    local titles, itemMap = {}, {}
    if scrolling then
        local count=0
        for _,slot in ipairs(scrolling:GetChildren()) do
            if not slot:IsA("Frame") then continue end
            local name=slot.Name
            if name=="" or name=="Animation" then continue end
            if BLOCKED_ITEMS[name] then continue end
            count=count+1
            if count%10==0 then task.wait() end

            local max=60
            local nl=name:lower()
            if nl:find("stone") or nl:find("gold") or nl:find("iron") then max=500 end
            pcall(function()
                local a=slot:FindFirstChild("Amout",true)
                if a and a:IsA("TextLabel") then
                    local m=tonumber(a.Text:match("%d+|(%d+)")); if m and m>0 then max=m end
                end
            end)

            local icon
            pcall(function()
                local img = slot:FindFirstChild("ItemImage")
                local src = (img and (img:IsA("ImageLabel") or img:IsA("ImageButton")) and img)
                         or (img and (img:FindFirstChildWhichIsA("ImageLabel") or img:FindFirstChildWhichIsA("ImageButton")))
                         or slot:FindFirstChildWhichIsA("ImageLabel", true)
                         or slot:FindFirstChildWhichIsA("ImageButton", true)
                if src and src.Image ~= "" then icon = src.Image end
            end)

            local thaiName = ITEM_THAI[name]
            local displayName = thaiName and (name.." ("..thaiName..")") or name
            t_insert(titles, displayName)
            itemMap[displayName]={Title=displayName, value=name, max=max, icon=icon}
        end
    end
    if #titles==0 then
        titles={"(ไม่พบไอเทม)"}; itemMap["(ไม่พบไอเทม)"]={Title="(ไม่พบไอเทม)", value="", max=0}
    end
    local PINNED_ORDER = {"Cauliflower","Corn","Peach","Grape","Orange","Gold","Iron","MineIron","MineGold"}
    local pinnedSet, rest = {}, {}
    for _, t in ipairs(titles) do
        local entry = itemMap[t]
        if entry then pinnedSet[entry.value] = t
        else t_insert(rest, t) end
    end
    local pinnedKeys = {}
    for _, v in ipairs(PINNED_ORDER) do pinnedKeys[v] = true end
    for _, t in ipairs(titles) do
        local entry = itemMap[t]
        if entry and not pinnedKeys[entry.value] then t_insert(rest, t) end
    end
    titles = {}
    for _, key in ipairs(PINNED_ORDER) do
        if pinnedSet[key] then t_insert(titles, pinnedSet[key]) end
    end
    for _, t in ipairs(rest) do t_insert(titles, t) end
    return titles, itemMap
end

local PLACEHOLDER    = "Reload"
local FarmItemTitles = {PLACEHOLDER}
local FarmItemMap    = {[PLACEHOLDER]={Title=PLACEHOLDER, value="", max=60}}
local SelectedItem   = FarmItemMap[PLACEHOLDER]
local CustomMax      = 60
local CustomMaxSet   = false
local UserSelectedItem = false
local ItemDropdown   = nil
local _suppressItemCallback = false
local FarmSection    = FarmTab:Section({Title="ตั้งค่าของที่จะเก็บใส่ตู้", Icon="package", Opened=true})
local AutoFarmToggle

local function setInSafe(text)
    if SafeDescLabel and SafeDescLabel.Parent then
        pcall(function() SafeDescLabel.Text = tostring(text) end)
    end
end

local function refreshSafePreview()
    buildSafeHud()
    local card = getHudCard()
    if not SelectedItem or SelectedItem.value == "" or not UserSelectedItem then
        setInSafe("-- ยังไม่ได้เลือกไอเทม")
        if card then card.Visible = false end
        return
    end
    local qty  = getSafeQty(SelectedItem.value)
    local icon = SelectedItem.icon or ""
    setInSafe(SelectedItem.value .. "  ×  " .. tostring(qty) .. "  ในตู้")
    if _hudIcon  then _hudIcon.Image = icon end
    if _hudName  then _hudName.Text  = SelectedItem.value end
    if _hudCount then _hudCount.Text = "×" .. SW.fmt(qty) .. ' <font size="11" color="rgb(150,141,190)">ในตู้</font>' end
    if card then card.Visible = true end
end

local _injectPending = false

local function injectIconLabel(lbl)
    local entry=FarmItemMap[lbl.Text]
    if not entry or not entry.icon then return end
    local p=lbl.Parent; if not p then return end
    local existing=p:FindFirstChild("SW_Icon")
    if existing then existing.Image=entry.icon; return end
    local img=Instance.new("ImageLabel")
    img.Name="SW_Icon"; img.BackgroundTransparency=1
    img.Size=UDim2.fromOffset(22,22)
    img.Position=UDim2.new(0,4,0.5,-11)
    img.Image=entry.icon
    img.ZIndex=lbl.ZIndex+1
    img.Parent=p
    pcall(function() lbl.Position=UDim2.new(0,30,lbl.Position.Y.Scale,lbl.Position.Y.Offset) end)
end

local function injectIconsIntoDropdown()
    if _injectPending then return end
    _injectPending=true
    task.delay(0.15, function()
        _injectPending=false
        pcall(function()
            for _,sg in ipairs(LP.PlayerGui:GetChildren()) do
                if not sg:IsA("ScreenGui") then continue end
                local n=sg.Name
                if not (n=="WindUI" or n:sub(1,7)=="WindUI/") then continue end
                for _,lbl in ipairs(sg:GetDescendants()) do
                    if lbl:IsA("TextLabel") and FarmItemMap[lbl.Text] then
                        injectIconLabel(lbl)
                    end
                end
            end
        end)
    end)
end

task.spawn(function()
    local _labelConnected = setmetatable({}, {__mode = "k"})
    -- OPTIMIZE: เดิมดัก DescendantAdded จาก LP.PlayerGui ทั้งก้อน ซึ่งรวม GUI อื่นๆทั้งหมดในเกม
    -- (chat, popup, GUI ของเกมเอง ฯลฯ) ทำให้ handler นี้ถูกเรียกถี่มากตลอดเวลาเล่นทั้งที่จริงๆสนใจแค่ label
    -- ที่ WindUI สร้างเอง เลยเปลี่ยนไปดักเฉพาะใน WindUIGui ที่จับไว้ตอนโหลด lib (ลด event ที่ไม่เกี่ยวข้องไปเกือบทั้งหมด)
    local listenTarget = WindUIGui or LP.PlayerGui
    listenTarget.DescendantAdded:Connect(function(obj)
        if not obj:IsA("TextLabel") then return end
        if listenTarget == LP.PlayerGui then
            local sg = obj:FindFirstAncestorWhichIsA("ScreenGui")
            if not sg then return end
            local n = sg.Name
            if not (n == "WindUI" or n:sub(1,7) == "WindUI/") then return end
        end
        if FarmItemMap[obj.Text] then task.delay(0.05, injectIconsIntoDropdown) end
        if _labelConnected[obj] then return end
        _labelConnected[obj] = true
        obj:GetPropertyChangedSignal("Text"):Connect(function()
            if FarmItemMap[obj.Text] then task.delay(0.05, injectIconsIntoDropdown) end
        end)
    end)
end)

local function createItemDropdown(titles, itemMap)
    local values={}
    for _,name in ipairs(titles) do
        local e=itemMap[name]
        t_insert(values, (e and e.icon) and {Title=name, Icon=e.icon} or name)
    end
    if ItemDropdown then
        local ok=pcall(function() ItemDropdown:Refresh(values) end)
        if ok then
            local firstKey = optionKey(values[1])
            SelectedItem = itemMap[firstKey]
            if SelectedItem then CustomMax = SelectedItem.max end
            task.delay(0.05, function()
                pcall(function()
                    local dd = ItemDropdown.UIElements and ItemDropdown.UIElements.Dropdown
                    if not dd then return end
                    local inner = dd.Frame.Frame
                    local lbl   = inner.TextLabel
                    lbl.Text = firstKey
                end)
            end)
        else
            pcall(function() ItemDropdown:Destroy() end); ItemDropdown=nil
        end
    end
    if not ItemDropdown then
        ItemDropdown=FarmSection:Dropdown({
            Title="เลือกของที่จะเก็บ", Desc="อ่านจาก Backpack ของคุณโดยตรง",
            Values=values, Value=values[1],
            Callback=function(option)
                if _suppressItemCallback then return end
                local key=optionKey(option)
                if UserSelectedItem and SelectedItem and SelectedItem.Title==key then
                    UserSelectedItem=false
                    SelectedItem=FarmItemMap[PLACEHOLDER]
                    refreshSafePreview()
                    task.delay(0.05, function()
                        pcall(function()
                            local dd=ItemDropdown.UIElements and ItemDropdown.UIElements.Dropdown
                            if dd then dd.Frame.Frame.TextLabel.Text="-- ยังไม่ได้เลือก --" end
                        end)
                    end)
                    return
                end
                SelectedItem=FarmItemMap[key]
                if SelectedItem then CustomMax=SelectedItem.max end
                UserSelectedItem=true
                injectIconsIntoDropdown()
                refreshSafePreview()
            end,
        })
        task.delay(0.1, function()
            pcall(function()
                local dd = ItemDropdown.UIElements and ItemDropdown.UIElements.Dropdown
                if not dd then return end
                local inner = dd.Frame.Frame   
                local lbl   = inner.TextLabel
                local iconShifted = false

                local function updateSelIcon()
                    local entry = FarmItemMap[lbl.Text]
                    local img   = inner:FindFirstChild("SW_SelIcon")
                    if not entry or not entry.icon then
                        if img then
                            img:Destroy()
                            if iconShifted then
                                lbl.Size     = UDim2.new(lbl.Size.X.Scale,
                                    lbl.Size.X.Offset + 38,
                                    lbl.Size.Y.Scale, lbl.Size.Y.Offset)
                                lbl.Position = UDim2.new(lbl.Position.X.Scale,
                                    lbl.Position.X.Offset - 38,
                                    lbl.Position.Y.Scale, lbl.Position.Y.Offset)
                                iconShifted = false
                            end
                        end
                        return
                    end
                    if not img then
                        img = Instance.new("ImageLabel")
                        img.Name                  = "SW_SelIcon"
                        img.BackgroundTransparency = 1
                        img.Size                  = UDim2.fromOffset(30, 30)
                        img.Position              = UDim2.new(0, 4, 0.5, -15)
                        img.LayoutOrder           = -1
                        img.ZIndex                = lbl.ZIndex + 1
                        img.Parent                = inner
                        if not iconShifted then
                            iconShifted  = true
                            lbl.Size     = UDim2.new(lbl.Size.X.Scale,
                                lbl.Size.X.Offset - 38,
                                lbl.Size.Y.Scale, lbl.Size.Y.Offset)
                            lbl.Position = UDim2.new(lbl.Position.X.Scale,
                                lbl.Position.X.Offset + 38,
                                lbl.Position.Y.Scale, lbl.Position.Y.Offset)
                        end
                    end
                    img.Image = entry.icon
                end

                lbl:GetPropertyChangedSignal("Text"):Connect(updateSelIcon)
                updateSelIcon()
            end)
        end)
    end
    injectIconsIntoDropdown()
end

local function reloadItems()
    task.spawn(function()
        UserSelectedItem = false
        refreshSafePreview()
        local titles, itemMap
        for _=1,5 do
            titles,itemMap=loadBackpackItems()
            if titles[1]~="(ไม่พบไอเทม)" then break end
            task.wait(1.5)
        end
        if titles and titles[1]~="(ไม่พบไอเทม)" then
            FarmItemTitles=titles; FarmItemMap=itemMap; createItemDropdown(titles,itemMap)
        end
    end)
end

createItemDropdown(FarmItemTitles, FarmItemMap); reloadItems()

FarmSection:Input({
    Title="จำนวนของที่จะเก็บก่อน Deposit", Desc="พิมตัวเลข เช่น 30 / 60 / 500",
    Placeholder=tostring(CustomMax), Numeric=true, Finished=true,
    Callback=function(v) local n=tonumber(v); if n and n>0 then CustomMax=n; CustomMaxSet=true end end,
})
FarmSection:Button({Title="Reload Items", Desc="กดถ้า Dropdown ยังแสดง placeholder", Icon="refresh-cw", Callback=reloadItems})
FarmSection:Paragraph({Title="📦 จำนวนปัจจุบัน", Desc="__AMOUNT_INIT__"})
task.spawn(function()
    task.wait(0.5); AmountDescLabel=findLabelByText("__AMOUNT_INIT__")
    if AmountDescLabel then AmountDescLabel.Text="-- รอเลือกไอเทม..." end
end)

task.spawn(function()
    pcall(function()
        local safeFolder = LP:WaitForChild("Safe", 5)
        if not safeFolder then return end
        local function hookVal(v)
            v:GetPropertyChangedSignal("Value"):Connect(function()
                if SelectedItem and SelectedItem.value ~= "" and UserSelectedItem
                and v.Name == SelectedItem.value then
                    refreshSafePreview()
                end
            end)
        end
        for _, v in ipairs(safeFolder:GetChildren()) do hookVal(v) end
        safeFolder.ChildAdded:Connect(function(v) task.wait(0.1); hookVal(v) end)
    end)
end)

local slotLabelCache=setmetatable({}, {__mode = "k"})
local function getSlotCount(slot)
    local lbl=slotLabelCache[slot]
    if not lbl or not lbl.Parent then
        lbl=slot:FindFirstChild("Amout",true)
        if not lbl then
            for _,c in ipairs(slot:GetDescendants()) do
                if c:IsA("TextLabel") or c:IsA("TextButton") then lbl=c; break end
            end
        end
        slotLabelCache[slot]=lbl
    end
    if not lbl then return 0 end
    local ok,txt=pcall(function() return lbl.Text end); txt=ok and txt or ""
    return tonumber(txt:match("%d+")) or 0
end

task.spawn(function()
    local cachedScrolling
    while true do
        pcall(function()
            if not cachedScrolling or not cachedScrolling.Parent then
                cachedScrolling=getScrolling(); if not cachedScrolling then return end
            end
            if SelectedItem and SelectedItem.value~="" and UserSelectedItem then
                local slot=cachedScrolling:FindFirstChild(SelectedItem.value)
                if slot then setAmount(SelectedItem.value.."  =  "..getSlotCount(slot).." / "..CustomMax)
                else         setAmount("-- "..SelectedItem.value.." : ไม่พบใน Backpack") end
            else setAmount("-- ยังไม่ได้เลือกไอเทม") end
        end)
        task.wait(3)
    end
end)

AutoFarmToggle = FarmSection:Toggle({
    Title="Auto Deposit", Desc="เปิด = เริ่มเก็บใส่ตู้  |  ปิด = หยุด", Value=false,
    Callback=function(state)
        if state then
            local noItem=not UserSelectedItem
            local noAmt =not CustomMaxSet
            if noItem or noAmt then
                FarmRunning=false
                task.spawn(function() pcall(function() AutoFarmToggle:Set(false) end) end)
                local msg
                if   noItem and noAmt then msg="กรุณาเลือกของ และกรอกจำนวนก่อนเปิด Auto Deposit"
                elseif noItem         then msg="กรุณาเลือกของที่จะเก็บก่อนเปิด Auto Deposit"
                else                       msg="กรุณากรอกจำนวนของที่จะเก็บก่อนเปิด Auto Deposit" end
                WindUI:Notify({Title="เปิดไม่ได้", Icon="lock", Content=msg, Duration=4})
                return
            end
        end
        FarmRunning=state
        if not state then return end
        task.spawn(function()
            if not DepositRemote then
                task.wait(0.5)
                for _=1,3 do
                    DepositRemote=resolveRemotePath(game:GetService("ReplicatedStorage"),
                        {"Game_Modules","RemoteEventSafe","DepositItem"},5)
                    if DepositRemote then break end; task.wait(1.5)
                end
            end
            if not DepositRemote then
                FarmRunning=false
                WindUI:Notify({Title="Auto Deposit หยุด", Icon="x-circle", Content="ไม่พบ DepositRemote กรุณา Rejoin", Duration=5})
                return
            end
            WindUI:Notify({Title="Auto Deposit เปิด", Icon="check-circle", Content="กำลังเก็บใส่ตู้: "..SelectedItem.value, Duration=3})
            local farmScrolling
            while FarmRunning do
                pcall(function()
                    if not farmScrolling or not farmScrolling.Parent then
                        farmScrolling=getScrolling(); if not farmScrolling then return end
                    end
                    local slot=farmScrolling:FindFirstChild(SelectedItem.value); if not slot then return end
                    local cur=getSlotCount(slot)
                    if cur>=CustomMax and SelectedItem.value~="" then
                        DepositRemote:FireServer(SelectedItem.value, cur)
                    end
                end)
                task.wait(1)
            end
        end)
    end,
})

-- ── SECTION: AUTO WATER ──
local WaterSection = FarmTab:Section({Title="ต้นแคนดี้ - Auto Water", Icon="droplet", Opened=true})
local autoWaterEnabled, selectedWaterFolders, waterPickDropdown, waterFolderMap = false, {}, nil, {}

local function buildFolderLabel(folder)
    local uid=tonumber(folder.Name:match("PlantedTrees_(%d+)")); if not uid then return folder.Name end
    local name=(Players:GetPlayerByUserId(uid) or {}).Name or tostring(uid)
    return folder.Name==folderName and ("ของฉัน ("..name..")") or name
end

function buildWaterPickDropdown()
    local prevLabels = {}
    for _,f in ipairs(selectedWaterFolders) do prevLabels[buildFolderLabel(f)] = true end

    waterFolderMap={}; local titles={}
    if allTrees then
        for _,folder in pairs(allTrees:GetChildren()) do
            local label=buildFolderLabel(folder)
            t_insert(titles,label); waterFolderMap[label]=folder
        end
    end
    if #titles==0 then titles={"(ไม่พบผู้เล่น)"} end

    local restoredTitles, restoredFolders = {}, {}
    for _,t in ipairs(titles) do
        if prevLabels[t] then
            t_insert(restoredTitles, t)
            t_insert(restoredFolders, waterFolderMap[t])
        end
    end
    if #restoredFolders > 0 then
        selectedWaterFolders = restoredFolders
    else
        selectedWaterFolders = waterFolderMap[titles[1]] and {waterFolderMap[titles[1]]} or {}
        restoredTitles = {titles[1]}
    end

    if waterPickDropdown then
        local ok=pcall(function() waterPickDropdown:Refresh(titles) end)
        if not ok then pcall(function() waterPickDropdown:Destroy() end); waterPickDropdown=nil end
        if waterPickDropdown then
            pcall(function() waterPickDropdown:Set(restoredTitles) end)
        end
    end
    if not waterPickDropdown then
        waterPickDropdown=WaterSection:Dropdown({
            Title="รดน้ำต้นของ", Desc="เลือกผู้เล่นได้หลายคน", Icon="users",
            Values=titles, Value=restoredTitles, Multi=true,
            Callback=function(options)
                selectedWaterFolders={}
                local list=type(options)=="table" and options or {options}
                for _,opt in ipairs(list) do
                    local f=waterFolderMap[optionKey(opt)]; if f then t_insert(selectedWaterFolders,f) end
                end
            end,
        })
    end
end
buildWaterPickDropdown()

local WATER_REACH_DIST = 15  

local function walkToTarget(model)
    local part=model:FindFirstChildWhichIsA("BasePart",true)
    if not part then return false, "ไม่พบตำแหน่งของต้นไม้ (BasePart)" end
    local hum2=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if not hum2 then return false, "ไม่พบ Humanoid ของตัวละคร (อาจกำลัง Respawn)" end
    if hum2.Health<=0 then return false, "ตัวละครตายอยู่ รอ Respawn ก่อน" end
    local moveOk=pcall(function()
        hum2:MoveTo(part.Position)
    end)
    if not moveOk then return false, "สั่งเดินไม่สำเร็จ (ตัวละครถูกทำลายระหว่างเดิน)" end
    local arrived=false
    local conn=hum2.MoveToFinished:Connect(function(reached) arrived=reached end)
    local t=os.clock()
    repeat
        task.wait(0.1)
    until arrived or (os.clock()-t)>20 or hum2.Health<=0 or not hum2.Parent
    conn:Disconnect()
    if hum2.Health<=0 or not hum2.Parent then return false, "ตัวละครตายหรือถูกทำลายระหว่างเดิน" end
    if not arrived then return false, "เดินไม่ถึงภายในเวลาที่กำหนด (อาจติดสิ่งกีดขวาง/ทางตัน)" end
    local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        if (hrp.Position - part.Position).Magnitude > WATER_REACH_DIST then
            return false, "เดินถึงจุดแล้วแต่ยังอยู่นอกระยะรดน้ำ ("..WATER_REACH_DIST.." studs)"
        end
        return true
    end
    return arrived, (arrived and nil or "ไม่พบ HumanoidRootPart")
end

local _walkFailNotifyAt = setmetatable({}, {__mode="k"})
local WALK_FAIL_NOTIFY_COOLDOWN = 10
local function notifyWalkFail(tree, reason)
    local now = os.clock()
    local last = _walkFailNotifyAt[tree]
    if last and (now - last) < WALK_FAIL_NOTIFY_COOLDOWN then return end
    _walkFailNotifyAt[tree] = now
    WindUI:Notify({
        Title = "เดินไปรดน้ำไม่ได้",
        Icon = "footprints",
        Content = (tree and tree.Name or "?")..": "..(reason or "ไม่ทราบสาเหตุ"),
        Duration = 4,
    })
end

local _controls
task.spawn(function()
    pcall(function()
        _controls = require(LP.PlayerScripts:WaitForChild("PlayerModule",5)):GetControls()
    end)
end)

local function setWaterInputLock(state)
    if not _controls then return end
    if state then _controls:Disable() else _controls:Enable() end
end

local function checkAndWater(tree)
    if not tree or not tree.Parent then return end
    local stats=tree:FindFirstChild("Stats"); if not stats then return end
    local wv=stats:FindFirstChild("Water");  if not wv or not giveWaterRemote then return end
    if m_floor(wv.Value)>=100 then return end
    local treePart=tree:FindFirstChildWhichIsA("BasePart",true)
    local walked, walkFailReason = walkToTarget(tree)
    if not walked then
        notifyWalkFail(tree, walkFailReason)
        return
    end
    local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if treePart and hrp and (hrp.Position-treePart.Position).Magnitude > WATER_REACH_DIST then
        notifyWalkFail(tree, "อยู่นอกระยะรดน้ำ ("..WATER_REACH_DIST.." studs)")
        return
    end
    local tries=0
    while autoWaterEnabled and tree.Parent and wv.Parent and m_floor(wv.Value)<100 do
        giveWaterRemote:FireServer(tree); task.wait(0.8)
        tries=tries+1; if tries>60 then break end
    end
end

local waterRunId = 0
local AutoWaterToggle

AutoWaterToggle = WaterSection:Toggle({
    Title="Auto Water", Desc="รดน้ำอัตโนมัติเมื่อน้ำต่ำกว่า 50% (เรียงใกล้→ไกล)", Value=false,
    Callback=function(state)
        waterRunId = waterRunId + 1
        local myRunId = waterRunId
        autoWaterEnabled=state; setWaterInputLock(state)
        if not state then return end
        if #selectedWaterFolders==0 then
            autoWaterEnabled=false; setWaterInputLock(false)
            task.spawn(function() pcall(function() AutoWaterToggle:Set(false) end) end)
            WindUI:Notify({Title="เปิดไม่ได้", Icon="lock", Content="กรุณาเลือกผู้เล่นที่จะรดน้ำก่อนเปิด Auto Water", Duration=4})
            return
        end
        task.spawn(function()
            local function isCurrent() return autoWaterEnabled and waterRunId==myRunId end
            local ok, err = pcall(function()
                while isCurrent() do
                    local orderedFolders, ownFolder = {}, nil
                    for _,folder in ipairs(selectedWaterFolders) do
                        if folder and folder.Parent then
                            if folder.Name == folderName then
                                ownFolder = folder
                            else
                                t_insert(orderedFolders, folder)
                            end
                        end
                    end
                    if ownFolder then t_insert(orderedFolders, 1, ownFolder) end

                    for _,folder in ipairs(orderedFolders) do
                        if not isCurrent() then break end

                        local treeList={}
                        pcall(function()
                            for _,tree in pairs(folder:GetChildren()) do
                                local stats=tree:FindFirstChild("Stats")
                                local wv=stats and stats:FindFirstChild("Water")
                                if wv and wv.Value<=49 then t_insert(treeList,tree) end
                            end
                        end)

                        local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                        if hrp and #treeList>1 then
                            local posCache={}
                            for _,tree in ipairs(treeList) do
                                local p=tree:FindFirstChildWhichIsA("BasePart",true); posCache[tree]=p and p.Position
                            end
                            local myPos=hrp.Position
                            t_sort(treeList, function(a,b)
                                local pa,pb=posCache[a],posCache[b]
                                return (pa and (myPos-pa).Magnitude or m_huge) < (pb and (myPos-pb).Magnitude or m_huge)
                            end)
                        end

                        for _,tree in ipairs(treeList) do
                            if not isCurrent() then break end
                            pcall(function() checkAndWater(tree) end)
                        end
                    end

                    task.wait(5)
                end
            end)
            if not ok then
                pcall(function()
                    WindUI:Notify({Title="Auto Water หยุดทำงาน", Icon="alert-triangle", Content="เกิดข้อผิดพลาด: "..tostring(err), Duration=5})
                end)
            end
            if waterRunId == myRunId then
                autoWaterEnabled = false
                setWaterInputLock(false)
                if not ok then pcall(function() AutoWaterToggle:Set(false) end) end
            end
        end)
    end,
})

WaterSection:Paragraph({Title="🌳 สถานะต้นแคนดี้", Desc="__TREE_STATUS_INIT__"})

local TreeStatusDescLabel
task.spawn(function()
    task.wait(0.5); TreeStatusDescLabel=findLabelByText("__TREE_STATUS_INIT__")
    if TreeStatusDescLabel then
        pcall(function() TreeStatusDescLabel.RichText=true end)
        TreeStatusDescLabel.Text="กรุณากด Reload Candy"
    end
end)

-- ── Floating Candy Status Panel (toggleable, draggable, separate from WindUI tab) ──
local CandyMain, refreshTreeStatus, CandyPanelToggle
do
    local CANDY_W, CANDY_MIN_H, CANDY_MAX_H, CANDY_LIST_Y = 316, 122, 300, 68
    local CANDY_BAR_W = 0.19
    local CANDY_STATS = {
        {x = 0.36, label = "น้ำ",    color = SW.Water},
        {x = 0.58, label = "อาหาร", color = SW.Food},
        {x = 0.80, label = "โต",    color = SW.Growth},
    }

    local CandyGui = Instance.new("ScreenGui")
    CandyGui.Name = "CandyStatusUI"
    CandyGui.ResetOnSpawn = false
    CandyGui.IgnoreGuiInset = true
    CandyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    CandyGui.DisplayOrder = 50
    pcall(function() CandyGui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
    if not CandyGui.Parent then CandyGui.Parent = LP:WaitForChild("PlayerGui") end

    CandyMain = SW.new("Frame", {
        Name = "MainFrame", Size = UDim2.fromOffset(CANDY_W, 160), Position = UDim2.new(0, 20, 0, 120),
        BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.02,
        BorderSizePixel = 0, Active = true, Visible = false,
    }, CandyGui)
    SW.round(CandyMain, 16)
    SW.new("UIGradient", {Color = ColorSequence.new(SW.BgTop, SW.Bg), Rotation = 115}, CandyMain)
    SW.edge(CandyMain, 1.4, 0.2, 90)

    -- Header (จับตรงนี้เพื่อลากแผง)
    local header = SW.new("Frame", {
        Name = "Header", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), Active = true,
    }, CandyMain)
    SW.new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -56, 1, 0),
        Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = SW.Text,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        Text = "🌳  สถานะต้นแคนดี้",
    }, header)

    local CandyCloseBtn = SW.new("TextButton", {
        Size = UDim2.fromOffset(26, 26), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
        BackgroundColor3 = SW.Row, TextColor3 = SW.Text, Font = Enum.Font.GothamBold,
        TextSize = 15, Text = "×", AutoButtonColor = false,
    }, header)
    SW.round(CandyCloseBtn, 13)
    CandyCloseBtn.MouseEnter:Connect(function() SW.tween(CandyCloseBtn, 0.12, {BackgroundColor3 = SW.Danger}) end)
    CandyCloseBtn.MouseLeave:Connect(function() SW.tween(CandyCloseBtn, 0.12, {BackgroundColor3 = SW.Row}) end)

    SW.drag(header, CandyMain)

    SW.new("Frame", {
        BackgroundColor3 = SpectreAccent, BackgroundTransparency = 0.8, BorderSizePixel = 0,
        Position = UDim2.new(0, 12, 0, 44), Size = UDim2.new(1, -24, 0, 1),
    }, CandyMain)

    -- หัวคอลัมน์ (น้ำ / อาหาร / โต) สีตรงกับแท่งด้านล่าง
    local legend = SW.new("Frame", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 49), Size = UDim2.new(1, -24, 0, 16),
    }, CandyMain)
    for _, s in ipairs(CANDY_STATS) do
        SW.new("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.new(s.x, 0, 0, 0), Size = UDim2.new(CANDY_BAR_W, 0, 1, 0),
            Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = s.color, Text = s.label,
        }, legend)
    end

    local CandyList = SW.new("ScrollingFrame", {
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = UDim2.fromOffset(10, CANDY_LIST_Y), Size = UDim2.new(1, -16, 1, -(CANDY_LIST_Y + 10)),
        ScrollBarThickness = 3, ScrollBarImageColor3 = SpectreAccent, ScrollBarImageTransparency = 0.3,
        CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
    }, CandyMain)
    local layout = SW.new("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4),
    }, CandyList)

    local empty = SW.new("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, -8, 0, 40), LayoutOrder = 0, Visible = false,
        Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = SW.Sub, Text = "ไม่พบต้นแคนดี้",
    }, CandyList)

    -- ให้แผงสูงพอดีกับจำนวนแถว (มีเพดาน แล้วเลื่อนเอา)
    local lastFitH
    local function fit()
        local h = m_clamp(CANDY_LIST_Y + layout.AbsoluteContentSize.Y + 12, CANDY_MIN_H, CANDY_MAX_H)
        if h == lastFitH then return end   -- SMOOTH: ความสูงเท่าเดิมไม่ต้องสร้าง tween ใหม่ (เดิมยิงทุก 4 วิ + ทุกครั้งที่ content เปลี่ยน)
        lastFitH = h
        SW.tween(CandyMain, 0.2, {Size = UDim2.fromOffset(CANDY_W, h)})
    end
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(fit)

    -- เก็บแถวไว้ใช้ซ้ำ (ไม่ทำลาย/สร้างใหม่ทุก 4 วิ) → ไม่กะพริบ ตำแหน่งเลื่อนไม่เด้งกลับ แท่งไหลอย่างนุ่ม
    local items = {}   -- Instance -> {row=Frame, name=TextLabel, bars={...}}

    local function ensureHeader(inst, text, order, isMine)
        local e = items[inst]
        if not e then
            local row = SW.new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, -8, 0, 24)}, CandyList)
            local lbl = SW.new("TextLabel", {
                BackgroundTransparency = 1, Position = UDim2.fromOffset(2, 0), Size = UDim2.new(1, -4, 1, 0),
                Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
            }, row)
            e = {row = row, name = lbl}
            items[inst] = e
        end
        -- SMOOTH: เขียน property เฉพาะที่เปลี่ยนจริง (เดิมเขียนทุกแถวทุก 4 วิ → GUI ต้องประมวลผลใหม่ทั้งที่ค่าเท่าเดิม)
        if e.order ~= order then e.order = order; e.row.LayoutOrder = order end
        if e.text ~= text then e.text = text; e.name.Text = text end
        if e.mine ~= isMine then e.mine = isMine; e.name.TextColor3 = isMine and SpectreAccent or SW.Sub end
    end

    local function ensureRow(inst, name, w, f, g, order)
        local e = items[inst]
        if not e then
            local row = SW.new("Frame", {
                BackgroundColor3 = SW.Row, BackgroundTransparency = 0.4, BorderSizePixel = 0,
                Size = UDim2.new(1, -8, 0, 28),
            }, CandyList)
            SW.round(row, 8)
            local lbl = SW.new("TextLabel", {
                BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(0.34, -10, 1, 0),
                Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = SW.Text,
                TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
            }, row)
            local bars = {}
            for i, s in ipairs(CANDY_STATS) do
                local track = SW.new("Frame", {
                    BackgroundColor3 = SW.Track, BorderSizePixel = 0, ClipsDescendants = true,
                    Position = UDim2.new(s.x, 0, 0.5, -9), Size = UDim2.new(CANDY_BAR_W, 0, 0, 18),
                }, row)
                SW.round(track, 9)
                local fill = SW.new("Frame", {
                    BackgroundColor3 = s.color, BackgroundTransparency = 0.25, BorderSizePixel = 0,
                    Size = UDim2.new(0, 0, 1, 0),
                }, track)
                SW.round(fill, 9)
                local txt = SW.new("TextLabel", {
                    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 2,
                    Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = Color3.new(1, 1, 1),
                    TextStrokeTransparency = 0.6, Text = "0%",
                }, track)
                bars[i] = {fill = fill, txt = txt, color = s.color}
            end
            e = {row = row, name = lbl, bars = bars}
            items[inst] = e
        end
        -- SMOOTH: เขียน/tween เฉพาะค่าที่เปลี่ยนจริง (เดิมสร้าง tween 3 อัน/ต้น ทุก 4 วิ แม้ค่าเท่าเดิม)
        if e.order ~= order then e.order = order; e.row.LayoutOrder = order end
        if e.text ~= name then e.text = name; e.name.Text = name end
        for i, b in ipairs(e.bars) do
            local raw = (i == 1 and w) or (i == 2 and f) or g
            local v = m_clamp(tonumber(raw) or 0, 0, 100)
            if b.v ~= v then
                b.v = v
                b.txt.Text = m_floor(v) .. "%"
                -- น้ำต่ำกว่า 20% → แท่งเป็นสีแดงให้เห็นทันที
                b.fill.BackgroundColor3 = (i == 1 and v < 20) and SW.Danger or b.color
                SW.tween(b.fill, 0.35, {Size = UDim2.new(v / 100, 0, 1, 0)})
            end
        end
    end

    refreshTreeStatus = function()
        pcall(function()
            if not allTrees then return end
            local lines, seen, order = {}, {}, 0
            local wantText = TreeStatusDescLabel ~= nil and TreeStatusDescLabel.Parent ~= nil   -- SMOOTH: ไม่มี label ก็ไม่ต้องต่อ string ทุก 4 วิ
            for _, folder in pairs(allTrees:GetChildren()) do
                local uid = tonumber(folder.Name:match("PlantedTrees_(%d+)"))
                local dname = uid and ((Players:GetPlayerByUserId(uid) or {}).Name or tostring(uid)) or folder.Name
                local isMine = folder.Name == folderName
                local header = isMine and ("👤 ของฉัน (" .. dname .. ")") or ("👥 " .. dname)
                local treeLines, treeData = {}, {}
                for _, tree in pairs(folder:GetChildren()) do
                    local stats = tree:FindFirstChild("Stats")
                    if stats then
                        local w = stats:FindFirstChild("Water"); local f = stats:FindFirstChild("Food"); local g = stats:FindFirstChild("Growth")
                        local wv, fv, gv = w and w.Value or 0, f and f.Value or 0, g and g.Value or 0
                        if wantText then
                            local pad = string.rep(" ", m_max(0, 10 - #tree.Name))
                            t_insert(treeLines, string.format(
                                '<font face="Code">  %s%s | 💧%3d%%  🍬%3d%%  📈%3d%%</font>',
                                tree.Name, pad, m_floor(wv), m_floor(fv), m_floor(gv)
                            ))
                        end
                        t_insert(treeData, {tree, tree.Name, wv, fv, gv})
                    end
                end
                if #treeData > 0 then
                    if wantText then
                        t_insert(lines, header)
                        for _, l in ipairs(treeLines) do t_insert(lines, l) end
                    end
                    order = order + 1
                    seen[folder] = true
                    ensureHeader(folder, header, order, isMine)
                    for _, d in ipairs(treeData) do
                        order = order + 1
                        seen[d[1]] = true
                        ensureRow(d[1], d[2], d[3], d[4], d[5], order)
                    end
                end
            end
            for inst, e in pairs(items) do
                if not seen[inst] then e.row:Destroy(); items[inst] = nil end
            end
            empty.Visible = (order == 0)
            if wantText and TreeStatusDescLabel and TreeStatusDescLabel.Parent then
                TreeStatusDescLabel.Text = #lines > 0 and table.concat(lines, "\n") or "-- ไม่พบต้นแคนดี้"
            end
            task.delay(0.05, fit)
        end)
    end

    CandyCloseBtn.MouseButton1Click:Connect(function()
        CandyMain.Visible = false
        pcall(function() CandyPanelToggle:Set(false) end)
    end)

    task.spawn(function()
        while true do
            task.wait(4)
            if CandyMain.Visible and not SW.isDragging then pcall(refreshTreeStatus) end
        end
    end)
end

CandyPanelToggle = WaterSection:Toggle({
    Title="แสดง UI สถานะต้นแคนดี้", Desc="เปิด/ปิดแผงลอยแสดงสถานะต้นไม้ (ลากย้ายตำแหน่งได้)", Value=false,
    Callback=function(state)
        CandyMain.Visible = state
        if state then SW.pop(CandyMain); pcall(refreshTreeStatus) end
    end,
})

WaterSection:Button({
    Title="Reload Candy", Desc="โหลดข้อมูลต้นแคนดี้ใหม่ + รีเฟรชรายชื่อผู้เล่น", Icon="refresh-cw",
    Callback=function()
        task.spawn(function()
            allTrees=workspace:FindFirstChild("AllPlantedTrees")
            parentFolder=allTrees and allTrees:FindFirstChild(folderName) or nil
            task.wait(0.3); buildWaterPickDropdown()
            refreshTreeStatus()
            WindUI:Notify({Title="รีเฟรชแล้ว", Icon="refresh-cw", Content="อัพเดทรายชื่อผู้เล่นสำเร็จ", Duration=3})
        end)
    end,
})

-- ── SECTION: DISCORD WEBHOOK NOTIFY ──
local NotifySection = FarmTab:Section({Title="แจ้งเตือนน้ำเหลือน้อย", Icon="bell", Opened=false})

local growthNotifyEnabled = false
local webhookURL, mentionUserId = "", ""
local notifyWaterThreshold = 30   
local NOTIFY_RESET_MARGIN = 20    
local _notifiedTrees = setmetatable({}, {__mode="k"})

local _cachedReqFn = nil
local function getRequestFn()
    if _cachedReqFn then return _cachedReqFn end
    if type(request)=="function" then _cachedReqFn=request
    elseif syn and type(syn.request)=="function" then _cachedReqFn=syn.request
    elseif type(http_request)=="function" then _cachedReqFn=http_request
    elseif type(fluxus)=="table" and type(fluxus.request)=="function" then _cachedReqFn=fluxus.request end
    return _cachedReqFn
end

local function sendWaterLowWebhook(tree, waterValue)
    if webhookURL=="" then return end
    local reqFn = getRequestFn()
    if not reqFn then
        WindUI:Notify({Title="ส่ง Webhook ไม่ได้", Icon="alert-triangle", Content="Executor นี้ไม่มีฟังก์ชัน request/http_request", Duration=4})
        return
    end
    local mentionText = (mentionUserId~="") and ("<@"..mentionUserId..">") or ""
    local ok, body = pcall(function()
        return game:GetService("HttpService"):JSONEncode({
            content = mentionText,
            allowed_mentions = { parse = {"users"} },
            embeds = {{
                title = "💧 น้ำต้นแคนดี้เหลือน้อย!",
                description = string.format("ต้น **%s** เหลือน้ำ **%d%%** รีบไปรดน้ำนะ!", tree.Name, waterValue),
                color = 3447003,
            }},
        })
    end)
    if not ok then return end
    task.spawn(function()
        pcall(function()
            reqFn({ Url=webhookURL, Method="POST", Headers={["Content-Type"]="application/json"}, Body=body })
        end)
    end)
end

local _treeWaterCache = setmetatable({}, {__mode="k"})
local function getTreeWater(tree)
    local wv = _treeWaterCache[tree]
    if wv and wv.Parent then return wv end
    local stats = tree:FindFirstChild("Stats")
    wv = stats and stats:FindFirstChild("Water")
    if wv then _treeWaterCache[tree] = wv end
    return wv
end

local function checkWaterNotify()
    if not growthNotifyEnabled then return end
    if #selectedWaterFolders==0 then return end
    local resetThreshold = notifyWaterThreshold + NOTIFY_RESET_MARGIN
    for _,folder in ipairs(selectedWaterFolders) do
        if folder and folder.Parent then
            for _,tree in ipairs(folder:GetChildren()) do
                local wv = getTreeWater(tree)
                if wv then
                    local val = m_floor(wv.Value)
                    if val<=notifyWaterThreshold then
                        if not _notifiedTrees[tree] then
                            _notifiedTrees[tree]=true
                            sendWaterLowWebhook(tree, val)
                        end
                    elseif val > resetThreshold then
                        _notifiedTrees[tree]=nil
                    end
                end
            end
        end
    end
end

task.spawn(function()
    while true do
        task.wait(growthNotifyEnabled and 5 or 10)
        pcall(checkWaterNotify)
    end
end)

NotifySection:Toggle({
    Title="เปิดแจ้งเตือน Discord", Desc="ส่ง webhook เมื่อน้ำต้นแคนดี้ของเราลดลงถึงเกณฑ์ที่ตั้งไว้", Icon="bell",
    Value=false,
    Callback=function(s)
        growthNotifyEnabled = s
        if s and webhookURL=="" then
            WindUI:Notify({Title="ยังไม่ใส่ Webhook URL", Icon="alert-triangle", Content="กรอก Webhook URL ก่อนถึงจะส่งแจ้งเตือนได้", Duration=4})
        end
    end,
})

NotifySection:Slider({
    Title="แจ้งเตือนเมื่อน้ำเหลือ", Desc="ถ้าน้ำต้นแคนดี้ลดลงถึงค่านี้ (หรือต่ำกว่า) จะส่ง webhook แจ้งเตือน", Icon="droplet",
    Step=5, Value={Min=0, Max=90, Default=notifyWaterThreshold},
    Callback=function(v) notifyWaterThreshold = v end,
})

NotifySection:Input({
    Title="Webhook URL", Desc="วาง Discord Webhook URL", Icon="link", Placeholder="https://discord.com/api/webhooks/...",
    Value="",
    Callback=function(v) webhookURL = v end,
})

NotifySection:Input({
    Title="Discord User ID (แท็ก)", Desc="ใส่ User ID ถ้าอยากแท็กคนใดคนหนึ่ง (เว้นว่างได้ถ้าไม่แท็ก)", Icon="at-sign",
    Placeholder="เช่น 123456789012345678",
    Value="",
    Callback=function(v) mentionUserId = v:match("^%s*(.-)%s*$") or "" end,
})


-- FIX: ล็อคแท็บ ESP ทั้งแท็บสำหรับ UserId ที่ไม่ได้อยู่ใน ESP_ALLOWED_USERIDS
-- (Locked=true ทำให้แท็บกดไม่ได้/เทาไว้จาก WindUI เอง) และ "ตัวมันเอง" ก็เช็คซ้ำที่ esp:FireScan/
-- esp:ScanWorkspace/RenderStepped ด้านบนอีกชั้น เผื่อมีทางกดเข้ามาได้บ้างช่องทางใดช่องทางหนึ่ง
local ESPTab = Window:Tab({Title="ESP", Icon = IsESPAuthorized and "eye" or "lock", Locked = not IsESPAuthorized})

local function notifyESPMaintenance()
    pcall(function()
        WindUI:Notify({Title="ปิดปรับปรุง", Icon="wrench", Content="ระบบ ESP กำลังปิดปรับปรุงชั่วคราว กรุณารอการอัปเดตครั้งถัดไป", Duration=4})
    end)
end

if not IsESPAuthorized then
    -- แสดง notify เมื่อกดที่ตัวแท็บ ESP เอง (ไม่ใช่แค่ปุ่ม/สวิตช์ข้างใน) เพราะแท็บถูกล็อคไว้กดเข้าไม่ได้อยู่แล้ว
    task.spawn(function()
        task.wait(1)
        local tabBtn
        pcall(function()
            local lbl = findLabelByText("ESP")
            if lbl then
                local p = lbl
                for i=1,6 do
                    if not p then break end
                    if p:IsA("GuiButton") then tabBtn = p; break end
                    p = p.Parent
                end
                if not tabBtn then tabBtn = lbl.Parent end
            end
        end)
        if tabBtn then
            pcall(function()
                if tabBtn:IsA("GuiButton") then
                    tabBtn.MouseButton1Click:Connect(notifyESPMaintenance)
                else
                    tabBtn.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                            notifyESPMaintenance()
                        end
                    end)
                end
            end)
        end
    end)
    -- แสดงแค่หน้าตาแท็บ ไม่มีอะไรทำงานได้จริง ทุกปุ่ม/สวิตช์แค่เด้งแจ้งเตือนแล้วดีดกลับ
    local LockedSection = ESPTab:Section({Title="ตั้งค่า ESP", Opened=true})
    local lockedToggle
    lockedToggle = LockedSection:Toggle({
        Title="Enable ESP", Desc="เปิด/ปิด ESP ทั้งหมด", Icon="lock", Value=false,
        Callback=function(s)
            notifyESPMaintenance()
            if s then pcall(function() lockedToggle:SetValue(false) end) end
        end,
    })
    LockedSection:Button({Title="ระบบปิดปรับปรุงอยู่", Desc="ESP ไม่พร้อมใช้งานในขณะนี้", Icon="shield-off",
        Callback=function() notifyESPMaintenance() end})
else

local ESPMain = ESPTab:Section({Title="ตั้งค่า ESP", Opened=true})

ESPMain:Toggle({
    Title="Enable ESP", Desc="เปิด/ปิด ESP ทั้งหมด", Icon="eye", Value=CFG.Enabled,
    Callback=function(s)
        CFG.Enabled=s
        if not s then pcall(function() esp:Clear() end); pcall(function() esp:RemoveAll() end)
        elseif CFG.NPCSESP then task.spawn(function() esp:ScanWorkspace() end) end
        esp:FireScan(); DebouncedSaveCFG()
    end,
})

local espToggles = {
    {"NPC ESP",               "แสดง ESP ของ NPC ในแผนที่",              "NPCSESP",      function(s) if s then task.spawn(function() esp:ScanWorkspace() end) end end},
    {"ซ่อน ESP ผู้เล่นที่ตาย","เปิด = ไม่แสดง ESP เมื่อ HP = 0",       "HideDeadESP",  nil},
    {"แสดงเลือด",             "แสดงแถบ HP",                             "ShowHP",       nil},
    {"แสดงตัวเลข HP",         "แสดง % HP ใต้กล่อง เช่น 75%",            "ShowHPText",   nil},
    {"แสดงชื่อ",              "แสดงชื่อเหนือกรอบ",                      "ShowName",     nil},
    {"แสดงระยะห่าง",          "แสดงระยะ studs ใต้กรอบ",                 "ShowDist",     nil},
    {"ซ่อน ESP เพื่อน Roblox","เปิด = ไม่แสดง ESP ของผู้เล่นที่แอดเป็นเพื่อนใน Roblox","HideFriends",nil},
}
for _,t in ipairs(espToggles) do
    ESPMain:Toggle({Title=t[1], Desc=t[2], Value=CFG[t[3]],
        Callback=function(s) CFG[t[3]]=s; if t[4] then t[4](s) end; DebouncedSaveCFG() end})
end

ESPMain:Slider({Title="ระยะสูงสุด", Desc="ไม่แสดง ESP เกินระยะนี้ (studs)", Icon="maximize-2",
    Step=10, Value={Min=50, Max=2000, Default=CFG.MaxDist},
    Callback=function(v) CFG.MaxDist=v; DebouncedSaveCFG() end})

ESPMain:Slider({Title="ระยะโครงกระดูกเต็ม", Desc="ใกล้กว่านี้วาดโครงกระดูกเต็มรูปแบบ ไกลกว่านี้วาดกรอบสี่เหลี่ยมแทน (ลดกระตุกตอนคน/NPC เยอะ)", Icon="bone",
    Step=10, Value={Min=30, Max=500, Default=CFG.ESPDetailDist or 120},
    Callback=function(v) CFG.ESPDetailDist=v; DebouncedSaveCFG() end})

end -- IsESPAuthorized

-- ── TAB: TELEPORT ──
local TeleportTab = Window:Tab({Title="Teleport", Icon="map-pin", Locked=false})

local Locations = {
    {Title="ปลูกแคนดี้",         Position=Vector3.new(647,30,990)},
        {Title="ปลูกแคนดี้2",         Position=Vector3.new(-3267, 4, 1397)},
    {Title="เรเบล",               Position=Vector3.new(4235,33,4641)},
    {Title="การาจกลาง",          Position=Vector3.new(2099,16,470)},
    {Title="ขายของ",              Position=Vector3.new(4188,6,68)},
    {Title="⛏️เหมืองทอง+เหล็ก", Position=Vector3.new(-805, 3, 5813)},
    {Title="ที่โพ เหล็ก+ทอง",   Position=Vector3.new(2713,46,-1113)},
    {Title="กะหล่ำ",          Position=Vector3.new(-4175, 75, 1243)},
    {Title="ข้าวโพด",          Position=Vector3.new(-4521, 118, 408)},
    {Title="พีช",          Position=Vector3.new(-5275, 99, -266)},
    {Title="องุ่น",          Position=Vector3.new(-5213, 98, -544)},
    {Title="ส้ม",          Position=Vector3.new(-4624, 123, -780)},
}
local LocationTitles, LocationMap = {}, {}
for _,loc in ipairs(Locations) do t_insert(LocationTitles,loc.Title); LocationMap[loc.Title]=loc end
local SelectedLocation = Locations[1]

TeleportTab:Dropdown({Title="เลือกสถานที่", Desc="เลือกตำแหน่งที่ต้องการ Teleport", Icon="map-pin",
    Values=LocationTitles, Value=LocationTitles[1],
    Callback=function(opt) SelectedLocation=LocationMap[opt] end})

TeleportTab:Button({Title="Teleport", Desc="กด Teleport ไปยังสถานที่ที่เลือก", Icon="navigation",
    Callback=function()
        pcall(function()
            local c2=LP.Character
            if c2 and c2:FindFirstChild("HumanoidRootPart") then
                c2:PivotTo(CFrame.new(SelectedLocation.Position))
            end
        end)
        if CFG.Enabled then
            task.spawn(function()
                for _,delay in ipairs({0.3,1,2}) do
                    task.wait(delay); esp:FireScan()
                    if CFG.NPCSESP then esp:ScanWorkspace() end
                end
            end)
        end
    end})

Window:Divider()

-- ── TAB: SETTINGS ──
local SettingsTab = Window:Tab({Title="Settings", Icon="settings", Locked=false})

local function doAntiAFK()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
    pcall(function()
        if hum and hum.Parent and hum.Health > 0 then
            hum:Move(v3_new(0.001, 0, 0), false)
            task.wait(0.1)
            hum:Move(v3_new(0,0,0), false)
        end
    end)
end
LP.Idled:Connect(function() if AntiAFKEnabled then doAntiAFK() end end)

-- ── Fullbright (event-driven — ไม่มี loop, ไม่สร้าง closure ซ้ำ) ──
--   • ฟังเฉพาะ property ที่เราแตะ แล้วเขียนกลับเฉพาะตัวที่เกมเปลี่ยนจริง
--     (ของเดิมฟัง Lighting.Changed ทุกอย่าง → ตอนเกมมี day/night cycle จะยิงรัวแล้วรัน 7 prop + GetChildren + pcall ใหม่ทุกครั้ง)
--   • เขียนเฉพาะตอนค่าต่างจริง (กันสู้กับเกมวนไม่จบ) และจำค่า "ล่าสุดที่เกมตั้ง" ไว้คืนตอนปิด
--   • effect: สแกนรอบเดียวตอนเปิด + ChildAdded สำหรับตัวที่เกมสร้างทีหลัง + จำสถานะ Enabled เดิมรายตัว
--   • แก้บั๊ก `vals and vals[i] or orig` ที่ทำให้ GlobalShadows=false ไม่เคยถูกตั้ง
--   • ยัดทุกอย่างไว้ใน table เดียว ประหยัดโควตา local ของสคริปต์ (limit 200)
local FB = {
    on = false,
    target = {
        Ambient        = Color3.fromRGB(178,178,178),
        OutdoorAmbient = Color3.fromRGB(155,155,180),
        Brightness     = 1,
        ClockTime      = 14,
        FogEnd         = 1e6,
        FogStart       = 1e6,
        GlobalShadows  = false,
    },
    fxClasses = {SunRaysEffect = true, DepthOfFieldEffect = true}, -- เพิ่มคลาสที่อยากปิดได้ตรงนี้
    orig    = {},  -- ค่า Lighting ล่าสุดที่เกมตั้ง (ใช้คืนตอนปิด)
    origFx  = {},  -- [effect] = Enabled เดิม
    conns   = {},  -- connection ของ property + ChildAdded/Removed
    fxConns = {},  -- [effect] = connection ของ Enabled
}

-- ค่าต่างจริงไหม (ตัวเลขเผื่อ float คลาดเล็กน้อย เช่น ClockTime)
function FB.differs(cur, want)
    if type(cur) == "number" then return m_abs(cur - want) > 1e-3 end
    return cur ~= want
end

function FB.force(prop)
    local cur = Lighting[prop]
    local want = FB.target[prop]
    if FB.differs(cur, want) then
        FB.orig[prop] = cur      -- จำสิ่งที่เกมเพิ่งตั้ง จะได้คืนถูกตอนปิด
        Lighting[prop] = want
    end
end

function FB.hookFx(fx)
    if not FB.fxClasses[fx.ClassName] or FB.fxConns[fx] then return end
    FB.origFx[fx] = fx.Enabled
    fx.Enabled = false
    FB.fxConns[fx] = fx:GetPropertyChangedSignal("Enabled"):Connect(function()
        if fx.Enabled then FB.origFx[fx] = true; fx.Enabled = false end
    end)
end

function FB.unhookFx(fx)
    local c = FB.fxConns[fx]
    if c then c:Disconnect(); FB.fxConns[fx] = nil; FB.origFx[fx] = nil end
end

function FB.enable()
    pcall(function()
        for prop, want in pairs(FB.target) do
            FB.orig[prop] = Lighting[prop]
            Lighting[prop] = want
        end
        for _, fx in ipairs(Lighting:GetChildren()) do FB.hookFx(fx) end
    end)
    -- ต่อ listener หลังตั้งค่าเสร็จ (ไม่ให้ตัวเองไปกระตุ้นตัวเอง)
    for prop in pairs(FB.target) do
        t_insert(FB.conns, Lighting:GetPropertyChangedSignal(prop):Connect(function() FB.force(prop) end))
    end
    t_insert(FB.conns, Lighting.ChildAdded:Connect(FB.hookFx))
    t_insert(FB.conns, Lighting.ChildRemoved:Connect(FB.unhookFx))
end

function FB.disable()
    for _, c in ipairs(FB.conns) do c:Disconnect() end
    table.clear(FB.conns)
    pcall(function()
        for prop, v in pairs(FB.orig) do Lighting[prop] = v end
        for fx, c in pairs(FB.fxConns) do
            c:Disconnect()
            if fx.Parent then fx.Enabled = FB.origFx[fx] end
        end
    end)
    table.clear(FB.fxConns); table.clear(FB.origFx); table.clear(FB.orig)
end

local function setFullbright(state)
    state = state and true or false
    if state == FB.on then return end   -- กันเรียกซ้ำ: ไม่งั้นจะเซฟค่า fullbright ทับค่าเดิม
    FB.on = state
    if state then FB.enable() else FB.disable() end
end

local GameplaySettings = SettingsTab:Section({Title="Gameplay", Opened=true})
GameplaySettings:Toggle({Title="Anti AFK", Desc="ป้องกันถูกเตะออกเกมตอนไม่ได้เล่น", Icon="moon", Value=AntiAFKEnabled, Callback=function(s) AntiAFKEnabled=s; DebouncedSaveCFG() end})
GameplaySettings:Toggle({Title="Fullbright", Desc="ทำให้มองเห็นชัดในที่มืด ลบ fog/shadow/bloom", Icon="sun-medium", Value=false, Callback=setFullbright})

local UISettings = SettingsTab:Section({Title="UI Configuration", Opened=true})
UISettings:Keybind({Flag="UIKeybind", Title="Toggle Menu Key", Icon="keyboard", Value="LeftControl",
    Callback=function(v) if Window.SetToggleKey then Window:SetToggleKey(Enum.KeyCode[v]) end end})

local themes={}
if WindUI.Themes then for name in pairs(WindUI.Themes) do t_insert(themes,name) end end
if #themes==0 then themes={"Dark"} end
UISettings:Dropdown({Flag="UITheme", Title="UI Theme", Icon="palette", Values=themes, Default="SpectreTheme",
    Callback=function(t) pcall(function() WindUI:SetTheme(t) end) end})

OnCFGLoaded(function(cfg)
    if not cfg.Enabled then return end
    esp:FireScan()
    if cfg.NPCSESP then task.spawn(function() esp:ScanWorkspace() end) end
end)
