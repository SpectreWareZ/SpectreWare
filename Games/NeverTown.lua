-- NEVER TOWN | SpectreWare by #CaptainZ v1.6.12 (Performance Optimized by Bread)
if not game:IsLoaded() then game.Loaded:Wait() end

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser= game:GetService("VirtualUser")
local Lighting   = game:GetService("Lighting")
local LP         = Players.LocalPlayer

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

-- ── SpectreTheme v2 — matched to Spectre logo palette ──
local SpectreAccent = Color3.fromRGB(160, 110, 255)

pcall(function()
    WindUI:AddTheme({
        Name        = "SpectreTheme",
        Accent      = SpectreAccent,
        Background  = Color3.fromRGB(10, 8, 18),
        Outline     = Color3.fromRGB(80, 70, 120),
        Button      = Color3.fromRGB(55, 46, 90),
        Text        = Color3.fromRGB(235, 232, 252),
        Placeholder = Color3.fromRGB(140, 130, 175),
        Icon        = Color3.fromRGB(185, 170, 240),
    })
end)

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
    {"BoxThickness","HPBarWidth","NameSize","MaxDist"},
    {"BoxColor"},
    {
        Enabled=false, NPCSESP=false,
        BoxColor=Color3.fromRGB(255,255,255), BoxThickness=1.5,
        ShowHP=true, HPBarWidth=4, ShowHPText=true,
        ShowName=true, NameSize=13,
        ShowDist=true, MaxDist=600,
        BypassAntiESP=true, HideDeadESP=true, HideFriends=false,
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
Window:EditOpenButton({
    Title="SpectreWare", Icon="monitor", CornerRadius=UDim.new(0,16),
    StrokeThickness=2,
    Color=ColorSequence.new(Color3.fromRGB(123,142,200), Color3.fromRGB(107,47,160)),
    OnlyMobile=true, Enabled=true, Draggable=true,
})
Window:Tag({Title="v1.6.12", Icon="github", Color=Color3.fromRGB(123,142,200), Radius=13})
Window:SetIconSize(80)

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
        pcall(function() AmountDescLabel.Text=tostring(text) end)
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
    _hudGui.Parent = LP.PlayerGui

    local card = Instance.new("Frame")
    card.Name = "Card"
    card.Size = UDim2.fromOffset(172, 64)
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.Position = UDim2.new(0.12, 0, 0.78, 0)
    card.BackgroundColor3 = Color3.fromRGB(10, 8, 18)
    card.BackgroundTransparency = 0.08
    card.BorderSizePixel = 0
    card.Visible = false
    card.Parent = _hudGui

    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 16)

    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = Color3.fromRGB(123, 142, 200)
    stroke.Thickness = 1.8
    stroke.Transparency = 0.15
    stroke.Parent = card

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(22, 18, 42)),
        ColorSequenceKeypoint.new(0.55, Color3.fromRGB(14, 11, 26)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(10,  8, 18)),
    })
    grad.Rotation = 135
    grad.Parent = card

    local iconBg = Instance.new("Frame")
    iconBg.Size = UDim2.fromOffset(48, 48)
    iconBg.Position = UDim2.new(0, 8, 0.5, -24)
    iconBg.BackgroundColor3 = Color3.fromRGB(28, 22, 50)
    iconBg.BorderSizePixel = 0
    iconBg.ZIndex = 2
    iconBg.Parent = card
    Instance.new("UICorner", iconBg).CornerRadius = UDim.new(0, 11)

    local iconStroke = Instance.new("UIStroke")
    iconStroke.Color = Color3.fromRGB(107, 47, 160)
    iconStroke.Thickness = 1
    iconStroke.Transparency = 0.45
    iconStroke.Parent = iconBg

    _hudIcon = Instance.new("ImageLabel")
    _hudIcon.Size = UDim2.fromOffset(36, 36)
    _hudIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    _hudIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    _hudIcon.BackgroundTransparency = 1
    _hudIcon.ScaleType = Enum.ScaleType.Fit
    _hudIcon.ZIndex = 3
    _hudIcon.Parent = iconBg

    _hudName = Instance.new("TextLabel")
    _hudName.Size = UDim2.new(1, -66, 0, 22)
    _hudName.Position = UDim2.new(0, 62, 0, 7)
    _hudName.BackgroundTransparency = 1
    _hudName.TextColor3 = Color3.fromRGB(185, 170, 240)
    _hudName.Font = Enum.Font.GothamBold
    _hudName.TextSize = 12
    _hudName.TextXAlignment = Enum.TextXAlignment.Left
    _hudName.TextTruncate = Enum.TextTruncate.AtEnd
    _hudName.ZIndex = 2
    _hudName.Parent = card

    _hudCount = Instance.new("TextLabel")
    _hudCount.Size = UDim2.new(1, -66, 0, 22)
    _hudCount.Position = UDim2.new(0, 62, 0, 30)
    _hudCount.BackgroundTransparency = 1
    _hudCount.TextColor3 = Color3.fromRGB(110, 255, 165)
    _hudCount.Font = Enum.Font.GothamMedium
    _hudCount.TextSize = 13
    _hudCount.TextXAlignment = Enum.TextXAlignment.Left
    _hudCount.ZIndex = 2
    _hudCount.Parent = card
end

local function getHudCard()
    if _hudGui and _hudGui.Parent then
        return _hudGui:FindFirstChild("Card")
    end
end

-- ── ESP (Corner Box) ──
-- ดีไซน์ใหม่: กรอบมุม 4 มุม (corner bracket) แทนโครงกระดูก อ่านง่าย เบากว่า ไม่รกจอ
local ESPObjects     = {}
local _espPartCache  = {}
local _espCacheBuild = {}
local Z_MARGIN       = 0.5  -- Z-buffer margin: kills edge-of-camera flicker
local CORNER_RATIO   = 0.25 -- ความยาวแขนกรอบมุม เทียบกับด้านที่สั้นกว่าของกล่อง

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

local function buildPartCache(model)
    local parts = {}
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then parts[#parts+1] = p end
    end
    _espPartCache[model] = parts
end

-- HP-based color: เขียว (เลือดเต็ม) ไล่ไปแดง (เลือดใกล้หมด) อ่านง่ายในสถานการณ์จริง
local function hpToColor(hpR)
    if hpR > 0.5 then
        return Color3.fromRGB(m_floor(255*(1-hpR)*2), 255, 60)
    else
        return Color3.fromRGB(255, m_floor(255*hpR*2), 60)
    end
end

local function makeESP(model, isNPC)
    if ESPObjects[model] then return end
    -- 4 มุม x 2 เส้นต่อมุม (แนวนอน+แนวตั้ง) = 8 เส้น
    local corners = {}
    for i=1,8 do corners[i]=newLine(CFG.BoxThickness, CFG.BoxColor) end
    ESPObjects[model]={
        corners=corners, isNPC=isNPC or false,
        hpBar    = newLine(CFG.HPBarWidth, Color3.new(0,1,0)),
        hpBarBg  = newLine(CFG.HPBarWidth + 2, Color3.fromRGB(15,12,24)),
        nameLabel= newText(CFG.NameSize,   Color3.fromRGB(235,232,252)),
        distLabel= newText(11,             Color3.fromRGB(140,130,175)),
        hpText   = newText(16,             Color3.fromRGB(110,255,165)),
        lastPos3 = nil, lastTopPos3 = nil, lastBotPos3 = nil,
        _vis = false, lastDistStr = "", lastHpStr = ""
    }
    if CFG.BypassAntiESP then buildPartCache(model) end
end

local function removeESP(model)
    local obj=ESPObjects[model]; if not obj then return end
    for _,l in ipairs(obj.corners) do pcall(function() l:Remove() end) end
    for _,k in ipairs({"hpBar","hpBarBg","nameLabel","distLabel","hpText"}) do
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
    for i=1, #obj.corners do obj.corners[i].Visible = v end
    obj.hpBar.Visible=v; obj.hpBarBg.Visible=v; obj.nameLabel.Visible=v
    obj.distLabel.Visible=v; obj.hpText.Visible=v
end

-- OPTIMIZE: Massive Performance Boost
local function updateESPObject(model, obj, Camera, myRoot, myPos)
    local root = model:FindFirstChild("HumanoidRootPart")
    local hum  = model:FindFirstChildOfClass("Humanoid")
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

    local pos3, topPos3, botPos3

    if isValid then
        local tempPos3 = Camera:WorldToViewportPoint(root.Position)

        if tempPos3.Z <= 0 then
            isValid = false
        else
            pos3 = tempPos3
            obj.lastPos3 = pos3

            local head = model:FindFirstChild("Head") or root
            local tempTop = Camera:WorldToViewportPoint(head.Position + v3_new(0, head.Size.Y / 2 + 0.3, 0))
            local tempBot = Camera:WorldToViewportPoint(root.Position - v3_new(0, 3, 0))

            if tempTop.Z <= 0 or tempBot.Z <= 0 then
                isValid = false
            else
                topPos3 = tempTop
                botPos3 = tempBot
                obj.lastTopPos3 = topPos3
                obj.lastBotPos3 = botPos3
            end
        end
    end

    if not isValid then
        setVisible(obj, false)
        return
    end

    obj._vis = true -- FIX: sync flag ตอน object valid จริง ไม่งั้น setVisible(false) รอบถัดไปจะเป็น no-op เพราะ _vis ค้างเป็น false ตลอด ทำให้ ESP เก่าค้างจอตอนหมุนกล้องเร็ว

    pos3 = obj.lastPos3
    topPos3 = obj.lastTopPos3
    botPos3 = obj.lastBotPos3

    local cx = pos3.X
    local y1 = m_min(topPos3.Y, botPos3.Y)
    local y2 = m_max(topPos3.Y, botPos3.Y)
    local h  = y2 - y1

    if h < 2 then h = 2 end
    local w  = h * 0.6
    local x1, x2 = cx - w/2, cx + w/2

    local hpR = m_clamp(hum.Health / m_max(hum.MaxHealth, 1), 0, 1)
    local hpColor = hpToColor(hpR)

    -- ── Corner Box: กรอบมุม 4 มุม สีไล่ตาม HP อ่านง่ายด้วยตาเปล่า ──
    local armLen = m_max(4, m_min(w, h) * CORNER_RATIO)
    if CFG.BoxColor and CFG.BoxColor ~= Color3.fromRGB(255,255,255) then
        -- ผู้ใช้ตั้งสีกรอบเองจาก settings ให้เคารพค่านั้น
        hpColor = CFG.BoxColor
    end
    local c = obj.corners
    -- มุมบนซ้าย
    c[1].From=v2_new(x1,y1); c[1].To=v2_new(x1+armLen,y1)
    c[2].From=v2_new(x1,y1); c[2].To=v2_new(x1,y1+armLen)
    -- มุมบนขวา
    c[3].From=v2_new(x2,y1); c[3].To=v2_new(x2-armLen,y1)
    c[4].From=v2_new(x2,y1); c[4].To=v2_new(x2,y1+armLen)
    -- มุมล่างซ้าย
    c[5].From=v2_new(x1,y2); c[5].To=v2_new(x1+armLen,y2)
    c[6].From=v2_new(x1,y2); c[6].To=v2_new(x1,y2-armLen)
    -- มุมล่างขวา
    c[7].From=v2_new(x2,y2); c[7].To=v2_new(x2-armLen,y2)
    c[8].From=v2_new(x2,y2); c[8].To=v2_new(x2,y2-armLen)
    for i=1,8 do
        if c[i].Thickness ~= CFG.BoxThickness then c[i].Thickness = CFG.BoxThickness end
        if c[i].Color ~= hpColor then c[i].Color = hpColor end
        c[i].Visible = true
    end

    -- ── HP Bar แนวตั้งด้านซ้ายกล่อง (อ่านง่าย ไม่บังตัวละคร) ──
    local barX = x1 - 6
    obj.hpBarBg.From = v2_new(barX, y1)
    obj.hpBarBg.To   = v2_new(barX, y2)
    obj.hpBarBg.Visible = CFG.ShowHP

    if obj.hpBar.Color ~= hpColor then obj.hpBar.Color = hpColor end
    obj.hpBar.From = v2_new(barX, y2)
    obj.hpBar.To   = v2_new(barX, y2 - h*hpR)
    obj.hpBar.Visible = CFG.ShowHP

    if CFG.ShowName then
        local nameStr = plr and plr.Name or model.Name
        if obj.nameLabel.Text ~= nameStr then obj.nameLabel.Text = nameStr end
        if obj.nameLabel.Size ~= CFG.NameSize then obj.nameLabel.Size = CFG.NameSize end
        obj.nameLabel.Position = v2_new(cx, y1-CFG.NameSize-4)
        obj.nameLabel.Visible = true
    else
        obj.nameLabel.Visible = false
    end

    if CFG.ShowDist then
        local distStr = string.format("%.0f studs", dist)
        if obj.lastDistStr ~= distStr then
            obj.distLabel.Text = distStr
            obj.lastDistStr = distStr
        end
        obj.distLabel.Position = v2_new(cx, y2+22)
        obj.distLabel.Visible = true
    else
        obj.distLabel.Visible = false
    end

    if CFG.ShowHPText then
        local hpPct = m_floor(hpR*100)
        local hpStr = hpPct.."%"
        if obj.lastHpStr ~= hpStr then
            obj.hpText.Text = hpStr
            obj.lastHpStr = hpStr
        end
        local dynSize = m_clamp(m_floor(20 - dist/16), 10, 20)
        if obj.hpText.Size ~= dynSize then obj.hpText.Size = dynSize end
        if obj.hpText.Color ~= hpColor then obj.hpText.Color = hpColor end
        obj.hpText.Position = v2_new(cx, y2+6)
        obj.hpText.Visible = true
    else
        obj.hpText.Visible = false
    end
end

RunService.RenderStepped:Connect(function()
    if not CFG.Enabled then return end
    local Camera = workspace.CurrentCamera
    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local myPos = myRoot and myRoot.Position

    for model, obj in pairs(ESPObjects) do
        if not model.Parent then
            -- OPTIMIZE/FIX: โมเดลถูกลบ/ออกจากเกมไปแล้วแต่ event cleanup ไม่ทัน -> เก็บกวาดทิ้งเลย ไม่ปล่อยให้ ESP ค้างจอ
            removeESP(model)
        else
            pcall(updateESPObject, model, obj, Camera, myRoot, myPos)
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
    if not CFG.Enabled then
        for _,obj in pairs(ESPObjects) do setVisible(obj,false) end; return
    end
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=LP and plr.Character and not ESPObjects[plr.Character] then makeESP(plr.Character, false) end
    end
end
function esp:ScanWorkspace()
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
local FarmSection    = FarmTab:Section({Title="⚙️ ตั้งค่าของที่จะเก็บใส่ตู้", Opened=true})
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
    if _hudCount then _hudCount.Text = "×" .. tostring(qty) .. " ในตู้" end
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
    LP.PlayerGui.DescendantAdded:Connect(function(obj)
        if not obj:IsA("TextLabel") then return end
        local sg = obj:FindFirstAncestorWhichIsA("ScreenGui")
        if not sg then return end
        local n = sg.Name
        if not (n == "WindUI" or n:sub(1,7) == "WindUI/") then return end
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
                WindUI:Notify({Title="🔒 เปิดไม่ได้", Content=msg, Duration=4})
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
                WindUI:Notify({Title="❌ Auto Deposit หยุด", Content="ไม่พบ DepositRemote กรุณา Rejoin", Duration=5})
                return
            end
            WindUI:Notify({Title="🟢 Auto Deposit เปิด", Content="กำลังเก็บใส่ตู้: "..SelectedItem.value, Duration=3})
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
local WaterSection = FarmTab:Section({Title="🌿 ต้นแคนดี้ - Auto Water", Opened=true})
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
    local hum2=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if not part or not hum2 then return false end
    local origSpeed=hum2.WalkSpeed
    hum2.WalkSpeed=32
    hum2:MoveTo(part.Position)
    local arrived=false
    local conn=hum2.MoveToFinished:Connect(function(reached) arrived=reached end)
    local t=os.clock()
    repeat task.wait(0.1) until arrived or (os.clock()-t)>8
    conn:Disconnect()
    hum2.WalkSpeed=origSpeed
    local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        return (hrp.Position - part.Position).Magnitude <= WATER_REACH_DIST
    end
    return arrived
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
    local stats=tree:FindFirstChild("Stats"); if not stats then return end
    local wv=stats:FindFirstChild("Water");  if not wv or not giveWaterRemote then return end
    if m_floor(wv.Value)>=100 then return end
    local treePart=tree:FindFirstChildWhichIsA("BasePart",true)
    if not walkToTarget(tree) then return end
    local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if treePart and hrp and (hrp.Position-treePart.Position).Magnitude > WATER_REACH_DIST then return end
    local tries=0
    while m_floor(wv.Value)<100 and autoWaterEnabled do
        giveWaterRemote:FireServer(tree); task.wait(0.3)
        tries=tries+1; if tries>60 then break end
    end
end

WaterSection:Toggle({
    Title="Auto Water", Desc="รดน้ำอัตโนมัติเมื่อน้ำต่ำกว่า 50% (เรียงใกล้→ไกล)", Value=false,
    Callback=function(state)
        autoWaterEnabled=state; setWaterInputLock(state); if not state then return end
        if #selectedWaterFolders==0 then
            autoWaterEnabled=false; setWaterInputLock(false); return
        end
        task.spawn(function()
            while autoWaterEnabled do
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

                local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")

                for _,folder in ipairs(orderedFolders) do
                    if not autoWaterEnabled then break end

                    local treeList={}
                    for _,tree in pairs(folder:GetChildren()) do
                        local stats=tree:FindFirstChild("Stats")
                        local wv=stats and stats:FindFirstChild("Water")
                        if wv and wv.Value<=49 then t_insert(treeList,tree) end
                    end

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
                        if not autoWaterEnabled then break end
                        pcall(function() checkAndWater(tree) end)
                    end
                end

                task.wait(5)
            end
            setWaterInputLock(false)
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

local function refreshTreeStatus()
    pcall(function()
        if not allTrees then return end
        local lines={}
        for _,folder in pairs(allTrees:GetChildren()) do
            local uid=tonumber(folder.Name:match("PlantedTrees_(%d+)"))
            local dname=uid and ((Players:GetPlayerByUserId(uid) or {}).Name or tostring(uid)) or folder.Name
            local header=folder.Name==folderName and ("👤 ของฉัน ("..dname..")") or ("👥 "..dname)
            local treeLines={}
            for _,tree in pairs(folder:GetChildren()) do
                local stats=tree:FindFirstChild("Stats")
                if stats then
                    local w=stats:FindFirstChild("Water"); local f=stats:FindFirstChild("Food"); local g=stats:FindFirstChild("Growth")
                    local pad=string.rep(" ",m_max(0,10-#tree.Name))
                    t_insert(treeLines, string.format(
                        '<font face="Code">  %s%s | 💧%3d%%  🍬%3d%%  📈%3d%%</font>',
                        tree.Name, pad,
                        w and m_floor(w.Value) or 0,
                        f and m_floor(f.Value) or 0,
                        g and m_floor(g.Value) or 0
                    ))
                end
            end
            if #treeLines>0 then
                t_insert(lines, header)
                for _,l in ipairs(treeLines) do t_insert(lines,l) end
            end
        end
        if TreeStatusDescLabel and TreeStatusDescLabel.Parent then
            TreeStatusDescLabel.Text=#lines>0 and table.concat(lines,"\n") or "-- ไม่พบต้นแคนดี้"
        end
    end)
end

WaterSection:Button({
    Title="Reload Candy", Desc="โหลดข้อมูลต้นแคนดี้ใหม่ + รีเฟรชรายชื่อผู้เล่น", Icon="refresh-cw",
    Callback=function()
        task.spawn(function()
            allTrees=workspace:FindFirstChild("AllPlantedTrees")
            parentFolder=allTrees and allTrees:FindFirstChild(folderName) or nil
            task.wait(0.3); buildWaterPickDropdown()
            refreshTreeStatus()
            WindUI:Notify({Title="🔄 รีเฟรชแล้ว", Content="อัพเดทรายชื่อผู้เล่นสำเร็จ", Duration=3})
        end)
    end,
})

-- ── SECTION: DISCORD WEBHOOK NOTIFY ──
local NotifySection = FarmTab:Section({Title="🔔 แจ้งเตือนน้ำเหลือน้อย", Opened=false})

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
        WindUI:Notify({Title="⚠️ ส่ง Webhook ไม่ได้", Content="Executor นี้ไม่มีฟังก์ชัน request/http_request", Duration=4})
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
    Title="เปิดแจ้งเตือน Discord", Desc="ส่ง webhook เมื่อน้ำต้นแคนดี้ของเราลดลงถึงเกณฑ์ที่ตั้งไว้",
    Value=false,
    Callback=function(s)
        growthNotifyEnabled = s
        if s and webhookURL=="" then
            WindUI:Notify({Title="⚠️ ยังไม่ใส่ Webhook URL", Content="กรอก Webhook URL ก่อนถึงจะส่งแจ้งเตือนได้", Duration=4})
        end
    end,
})

NotifySection:Slider({
    Title="แจ้งเตือนเมื่อน้ำเหลือ", Desc="ถ้าน้ำต้นแคนดี้ลดลงถึงค่านี้ (หรือต่ำกว่า) จะส่ง webhook แจ้งเตือน", Icon="droplet",
    Step=5, Value={Min=0, Max=90, Default=notifyWaterThreshold},
    Callback=function(v) notifyWaterThreshold = v end,
})

NotifySection:Input({
    Title="Webhook URL", Desc="วาง Discord Webhook URL", Placeholder="https://discord.com/api/webhooks/...",
    Value="",
    Callback=function(v) webhookURL = v end,
})

NotifySection:Input({
    Title="Discord User ID (แท็ก)", Desc="ใส่ User ID ถ้าอยากแท็กคนใดคนหนึ่ง (เว้นว่างได้ถ้าไม่แท็ก)",
    Placeholder="เช่น 123456789012345678",
    Value="",
    Callback=function(v) mentionUserId = v:match("^%s*(.-)%s*$") or "" end,
})


local ESPTab  = Window:Tab({Title="ESP", Icon="eye", Locked=false})
local ESPMain = ESPTab:Section({Title="⚙️ ตั้งค่า ESP", Opened=true})

ESPMain:Toggle({
    Title="Enable ESP", Desc="เปิด/ปิด ESP ทั้งหมด", Value=CFG.Enabled,
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

TeleportTab:Dropdown({Title="เลือกสถานที่", Desc="เลือกตำแหน่งที่ต้องการ Teleport",
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

local FullbrightEnabled = false
local _origLighting     = {}
local _fbProps   = {"Ambient","OutdoorAmbient","Brightness","ClockTime","FogEnd","FogStart","GlobalShadows"}
local _fbVals    = {Color3.fromRGB(178,178,178), Color3.fromRGB(155,155,180), 1, 14, 1e6, 1e6, false}
local _fbFxTypes = {"SunRaysEffect","DepthOfFieldEffect"}
local _fbConn    = nil   
local _fbGuard   = false 

local function setLighting(vals)
    pcall(function()
        for i,k in ipairs(_fbProps) do Lighting[k] = vals and vals[i] or _origLighting[k] end
        for _,fx in ipairs(Lighting:GetChildren()) do
            for _,t in ipairs(_fbFxTypes) do
                if fx:IsA(t) then pcall(function() fx.Enabled = not vals end); break end
            end
        end
    end)
end

local function setFullbright(state)
    FullbrightEnabled = state
    if _fbConn then _fbConn:Disconnect(); _fbConn = nil end
    if state then
        for _,k in ipairs(_fbProps) do _origLighting[k] = Lighting[k] end
        setLighting(_fbVals)
        _fbConn = Lighting.Changed:Connect(function()
            if not FullbrightEnabled or _fbGuard then return end
            _fbGuard = true
            setLighting(_fbVals)
            _fbGuard = false
        end)
    else
        setLighting(nil)
    end
end

local GameplaySettings = SettingsTab:Section({Title="Gameplay", Opened=true})
GameplaySettings:Toggle({Title="Anti AFK", Desc="ป้องกันถูกเตะออกเกมตอนไม่ได้เล่น", Value=AntiAFKEnabled, Callback=function(s) AntiAFKEnabled=s; DebouncedSaveCFG() end})
GameplaySettings:Toggle({Title="Fullbright", Desc="ทำให้มองเห็นชัดในที่มืด ลบ fog/shadow/bloom", Value=false, Callback=setFullbright})

local UISettings = SettingsTab:Section({Title="UI Configuration", Opened=true})
UISettings:Keybind({Flag="UIKeybind", Title="Toggle Menu Key", Value="LeftControl",
    Callback=function(v) if Window.SetToggleKey then Window:SetToggleKey(Enum.KeyCode[v]) end end})

local themes={}
if WindUI.Themes then for name in pairs(WindUI.Themes) do t_insert(themes,name) end end
if #themes==0 then themes={"Dark"} end
UISettings:Dropdown({Flag="UITheme", Title="UI Theme", Values=themes, Default="Dark",
    Callback=function(t) pcall(function() WindUI:SetTheme(t) end) end})

OnCFGLoaded(function(cfg)
    if not cfg.Enabled then return end
    esp:FireScan()
    if cfg.NPCSESP then task.spawn(function() esp:ScanWorkspace() end) end
end)
