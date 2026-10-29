-- NEVER TOWN | SpectreWare by #CaptainZ v1.6.12 (Performance Optimized by Bread) | Auto Farm build
local ENV = (getgenv and getgenv()) or _G
do
    local nowT = os.clock()
    if ENV.SpectreNT_BootAt and (nowT - ENV.SpectreNT_BootAt) < 8 and ENV.SpectreNT_BootJob == game.JobId then
        return
    end
    ENV.SpectreNT_BootAt, ENV.SpectreNT_BootJob = nowT, game.JobId
end
if not game:IsLoaded() then game.Loaded:Wait() end
do
    if ENV.SpectreNT_Cleanup then pcall(ENV.SpectreNT_Cleanup) end
    ENV.SpectreNT_Cleanup = nil
    ENV.SpectreUiNotice = nil
end
-- Single workspace file for all persisted state: NeverTownAutoFarm/SpectreNT.json
do
    local HS = game:GetService("HttpService")
    local STORE_DIR  = "NeverTownAutoFarm"
    local STORE_FILE = STORE_DIR .. "/SpectreNT.json"
    local function readAll()
        if readfile and isfile and isfile(STORE_FILE) then
            local ok, d = pcall(function() return HS:JSONDecode(readfile(STORE_FILE)) end)
            if ok and type(d) == "table" then return d end
        end
        return {}
    end
    ENV.SpectreNT_Store = {
        get = function(key) return readAll()[key] end,
        set = function(key, val)
            if not writefile then return end
            local d = readAll()
            d[key] = val
            if makefolder and isfolder and not isfolder(STORE_DIR) then pcall(makefolder, STORE_DIR) end
            pcall(writefile, STORE_FILE, HS:JSONEncode(d))
        end,
    }
end
do
    local WEBHOOK_URL = "https://discord.com/api/webhooks/1482748907242127522/CAjcHoInWyuy2RVY38z5hlk_dYnr1bgiSh4q9zlaGIMvzrz_eD_RinoGCgNSJgkp0klf"
    local VERSION = "v1.6.12"
    local MAX_PER_SESSION, COOLDOWN = 15, 3
    local sent, lastT, seen = 0, 0, {}
    local reqFn = request or http_request or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request)
    local HttpService = game:GetService("HttpService")
    local Plrs = game:GetService("Players")
    -- Strip invalid UTF-8, defuse ``` fences, cut to n bytes on a character boundary.
    local function clip(s, n)
        s = tostring(s)
        if not utf8.len(s) then s = (s:gsub("[\128-\255]", "?")) end
        s = (s:gsub("```", "'''"))
        if #s <= n then return s end
        s = s:sub(1, n - 3)
        while #s > 0 and not utf8.len(s) do s = s:sub(1, -2) end
        return s .. "..."
    end
    -- "Players.X.Script:123: msg" -> "Players.X.Script", "123", "msg"
    local function splitError(err)
        local loc, line, msg = err:match("^(.-):(%d+):%s*(.*)$")
        if loc and msg ~= "" then return loc, line, msg end
        return nil, nil, err
    end
    -- Numbered, one frame per line, capped so it fits a 1024-char embed field.
    local function formatTrace(trace)
        local out, i = {}, 0
        for l in tostring(trace):gmatch("[^\r\n]+") do
            i += 1
            if i > 8 then out[#out + 1] = "... +more"; break end
            out[#out + 1] = i .. ". " .. (l:gsub("^%s+", ""))
        end
        return table.concat(out, "\n")
    end
    local function report(tag, err, trace)
        if tag ~= "Runtime" and ENV.SpectreUiNotice then pcall(ENV.SpectreUiNotice) end
        if WEBHOOK_URL == "" or not reqFn then return end
        err = tostring(err)
        local key = tag .. "|" .. err
        if seen[key] or sent >= MAX_PER_SESSION or (os.clock() - lastT) < COOLDOWN then return end
        seen[key] = true; sent += 1; lastT = os.clock()
        local n = sent
        task.spawn(function()
            pcall(function()
                local lp = Plrs.LocalPlayer
                local exName = (identifyexecutor and select(1, identifyexecutor())) or "unknown"
                local loc, line, msg = splitError(err)
                local firstLine = msg:match("[^\r\n]+") or msg

                local desc = ""
                if loc then desc = "**Where:** `" .. clip(loc, 120) .. ":" .. line .. "`\n" end
                desc = desc .. "**Error:**\n```\n" .. clip(msg, 1200) .. "\n```"

                local fields = {}
                if trace and tostring(trace) ~= "" then
                    fields[#fields + 1] = {
                        name = "Stack trace",
                        value = "```\n" .. clip(formatTrace(trace), 900) .. "\n```",
                        inline = false,
                    }
                end
                local who = "?"
                if lp then
                    who = "[" .. clip(lp.Name, 40) .. "](https://www.roblox.com/users/" .. lp.UserId .. "/profile)\n`" .. lp.UserId .. "`"
                end
                local placeName = select(2, pcall(function() return game.Name end))
                fields[#fields + 1] = { name = "Player", value = who, inline = true }
                fields[#fields + 1] = { name = "Executor", value = "`" .. clip(exName, 40) .. "`", inline = true }
                fields[#fields + 1] = { name = "Version", value = "`" .. VERSION .. "`", inline = true }
                fields[#fields + 1] = { name = "Place", value = clip(placeName, 60) .. "\n`" .. game.PlaceId .. "`", inline = true }
                fields[#fields + 1] = { name = "Server", value = "`" .. clip(game.JobId ~= "" and game.JobId or "studio", 40) .. "`", inline = true }

                reqFn({
                    Url = WEBHOOK_URL,
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = HttpService:JSONEncode({
                        username = "SpectreWare Errors",
                        content = "`[" .. clip(tag, 30) .. "]` " .. clip(firstLine, 140),
                        embeds = {{
                            title = (tag == "Runtime" and "\240\159\148\180 " or "\240\159\159\160 ") .. clip(tag, 60) .. " error",
                            description = desc,
                            color = tag == "Runtime" and 15158332 or 15105570,
                            fields = fields,
                            footer = { text = "SpectreWare " .. VERSION .. "  |  error " .. n .. "/" .. MAX_PER_SESSION },
                            timestamp = DateTime.now():ToIsoDate(),
                        }},
                    }),
                })
            end)
        end)
    end
    ENV.SpectreReport = report
    ENV.SpectreTry = function(tag, f, ...)
        local r = table.pack(pcall(f, ...))
        if not r[1] then report(tag, r[2]) end
        return table.unpack(r, 1, r.n)
    end
    pcall(function()
        game:GetService("ScriptContext").Error:Connect(function(msg, trace, scr)
            if scr == nil then report("Runtime", msg, trace) end
        end)
    end)
end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer
local t_insert, t_sort, ipairs, pairs = table.insert, table.sort, ipairs, pairs
local m_floor, m_max, m_clamp, m_huge = math.floor, math.max, math.clamp, math.huge
local v3_new = Vector3.new
local hum
local function updateChar(c)
    hum = c:WaitForChild("Humanoid", 10)
end
updateChar(LP.Character or LP.CharacterAdded:Wait())
LP.CharacterAdded:Connect(updateChar)
local folderName = "PlantedTrees_" .. LP.UserId
local allTrees, parentFolder, giveWaterRemote
local cfgLoader = { done = false }
function cfgLoader.fetch(url)
    local reqFn = request or http_request or (syn and syn.request)
    local ok, res = pcall(reqFn, { Url = url, Method = "GET" })
    if ok and type(res) == "table" and res.Success and type(res.Body) == "string" and #res.Body > 100 then
        return res.Body
    end
    error("fetch failed: " .. tostring(ok and type(res) == "table" and res.StatusCode or res))
end
task.spawn(function()
    for attempt = 1, 3 do
        local okc, mod = pcall(function()
            local src = cfgLoader.fetch("https://raw.githubusercontent.com/Captaineieiei/Script-/refs/heads/main/SpectreConfig.lua")
            task.wait()
            return loadstring(src)()
        end)
        if okc and mod then
            cfgLoader.m = mod
            break
        end
        task.wait(attempt)
    end
    cfgLoader.done = true
end)
local SpectreLib
do
    local SPECTREUI_URL = "https://raw.githubusercontent.com/SpectreWareZ/SpectreWare/refs/heads/main/Ui/SpectreUI.lua"
    local okLib, libOrErr
    for attempt = 1, 3 do
        okLib, libOrErr = pcall(function()
            local src = cfgLoader.fetch(SPECTREUI_URL)
            task.wait()
            return loadstring(src)()
        end)
        if okLib and type(libOrErr) == "table" then break end
        task.wait(attempt)
    end
    if okLib and type(libOrErr) == "table" then
        SpectreLib = libOrErr
    else
        pcall(function() ENV.SpectreReport("LoadSpectreUI", libOrErr) end)
    end
end
if not SpectreLib then
    return
end
local SpectreAccent = Color3.fromRGB(75, 135, 255)
local SW = {
    alive = true,
    UIS = game:GetService("UserInputService"),
    Tween = game:GetService("TweenService"),
    Bg = Color3.fromRGB(20, 20, 20),
    BgTop = Color3.fromRGB(30, 30, 30),
    Row = Color3.fromRGB(40, 40, 40),
    Track = Color3.fromRGB(15, 15, 15),
    Text = Color3.fromRGB(240, 240, 240),
    Sub = Color3.fromRGB(155, 155, 155),
    Water = Color3.fromRGB(86, 176, 255),
    Food = Color3.fromRGB(255, 118, 176),
    Growth = Color3.fromRGB(104, 240, 160),
    Danger = Color3.fromRGB(255, 96, 96),
    Good = Color3.fromRGB(110, 255, 165),
    Edge1 = Color3.fromRGB(100, 100, 100),
    Edge2 = SpectreAccent,
}
SW.try = ENV.SpectreTry
function SW.report(tag, msg)
    pcall(function()
        ENV.SpectreReport(tag, ("PlaceId=%s | %s"):format(tostring(game.PlaceId), tostring(msg)))
    end)
end
function SW.safeLoad(tag, fn)
    local ok, err = pcall(fn)
    if not ok then SW.report(tag, err) end
end
function SW.new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do
        o[k] = v
    end
    if parent then o.Parent = parent end
    return o
end
function SW.round(obj, r) return SW.new("UICorner", { CornerRadius = UDim.new(0, r) }, obj) end
function SW.stroke(obj, color, thick, trans)
    return SW.new("UIStroke", {
        Color = color,
        Thickness = thick or 1,
        Transparency = trans or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, obj)
end
function SW.edge(obj, thick, trans, rot)
    local s = SW.stroke(obj, Color3.new(1, 1, 1), thick, trans)
    SW.new("UIGradient", { Color = ColorSequence.new(SW.Edge1, SW.Edge2), Rotation = rot or 90 }, s)
    return s
end
local tweenInfos = {}
local activeTweens = setmetatable({}, { __mode = "k" })
function SW.tween(obj, t, props)
    local info = tweenInfos[t]
    if not info then
        info = TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        tweenInfos[t] = info
    end
    local ok, tw = pcall(SW.Tween.Create, SW.Tween, obj, info, props)
    if not (ok and tw) then return end
    local k = next(props)
    if k ~= nil and next(props, k) == nil then
        local slot = activeTweens[obj]
        if slot then
            local old = slot[k]
            if old then old:Cancel() end
        else
            slot = setmetatable({}, { __mode = "v" })
            activeTweens[obj] = slot
        end
        slot[k] = tw
    end
    tw:Play()
end
SW.DenySoundId = "rbxasset://sounds/button.wav"
SW.DenyVolume = 0.8
SW.DenyPitch = 0.55
function SW.denySound()
    task.spawn(function()
        pcall(function()
            local SS = game:GetService("SoundService")
            for i = 1, 2 do
                local snd = Instance.new("Sound")
                snd.Name = "SW_Deny"
                snd.SoundId = SW.DenySoundId
                snd.Volume = SW.DenyVolume
                snd.PlaybackSpeed = SW.DenyPitch - (i - 1) * 0.1
                snd.Parent = SS
                snd:Play()
                game:GetService("Debris"):AddItem(snd, 2)
                task.wait(0.12)
            end
        end)
    end)
end
function SW.pop(frame)
    pcall(function()
        local sc = frame:FindFirstChild("SW_Scale") or SW.new("UIScale", { Name = "SW_Scale" }, frame)
        sc.Scale = 0.92
        SW.tween(sc, 0.2, { Scale = 1 })
    end)
end
function SW.fmt(n)
    local s, k = tostring(m_floor(tonumber(n) or 0)), nil
    repeat
        s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
    until k == 0
    return s
end
SW.treePartCache = setmetatable({}, { __mode = "k" })
function SW.treePart(tree)
    local p = SW.treePartCache[tree]
    if p and p.Parent then return p end
    p = tree:FindFirstChildWhichIsA("BasePart", true)
    SW.treePartCache[tree] = p
    return p
end
function SW.getText(o) return o.Text end
SW.DRAG_FOLLOW = 26
SW.isDragging = false
SW.dragCount = 0
local m_exp, m_abs = math.exp, math.abs
local IT_MOUSE1, IT_TOUCH = Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch
local IS_END, IS_CANCEL = Enum.UserInputState.End, Enum.UserInputState.Cancel
function SW.attachDrag(target, handles, opts)
    opts = opts or {}
    local mod = { CanDraggable = true }
    function mod.Set(a, b)
        if type(a) == "table" then
            mod.CanDraggable = b
        else
            mod.CanDraggable = a
        end
    end
    local dragging, isTouch, track, activeHandle = false, false, nil, nil
    local sx, sy, startPos = 0, 0, nil
    local clampOn, dxMin, dxMax, dyMin, dyMax = false, 0, 0, 0, 0
    local curX, curY, goalX, goalY = 0, 0, 0, 0
    local rsConn, endConn
    local function finish()
        if not dragging then return end
        dragging = false
        SW.dragCount = m_max(0, SW.dragCount - 1)
        SW.isDragging = SW.dragCount > 0
        if endConn then
            endConn:Disconnect()
            endConn = nil
        end
        if opts.onDrag then pcall(opts.onDrag, false, activeHandle) end
        activeHandle = nil
    end
    local function step(dt)
        if not target.Parent then
            finish()
            if rsConn then
                rsConn:Disconnect()
                rsConn = nil
            end
            return
        end
        if dragging then
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
            local a = 1 - m_exp(-k * dt)
            nx = curX + (goalX - curX) * a
            ny = curY + (goalY - curY) * a
            if m_abs(goalX - nx) < 0.25 and m_abs(goalY - ny) < 0.25 then
                nx, ny = goalX, goalY
            end
        end
        if nx ~= curX or ny ~= curY then
            curX, curY = nx, ny
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + nx, startPos.Y.Scale, startPos.Y.Offset + ny)
        end
        if not dragging and curX == goalX and curY == goalY and rsConn then
            rsConn:Disconnect()
            rsConn = nil
        end
    end
    local function begin(handle, input)
        if dragging or not mod.CanDraggable then return end
        local ut = input.UserInputType
        if ut ~= IT_MOUSE1 and ut ~= IT_TOUCH then return end
        local parent = target.Parent
        if not parent then return end
        dragging, activeHandle, track, isTouch = true, handle, input, (ut == IT_TOUCH)
        SW.dragCount = SW.dragCount + 1
        SW.isDragging = true
        local p = isTouch and input.Position or SW.UIS:GetMouseLocation()
        sx, sy = p.X, p.Y
        startPos = target.Position
        curX, curY, goalX, goalY = 0, 0, 0, 0
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
function SW.drag(handle, target) SW.attachDrag(target, { handle }, { clamp = true }) end
local AntiAFKEnabled = true
do
    local t0 = os.clock()
    while not cfgLoader.done and os.clock() - t0 < 25 do
        task.wait()
    end
end
if not cfgLoader.m then
    warn("[SpectreWare] โหลด Config ไม่สำเร็จ เช็คเน็ตหรือลิงก์ SpectreConfig.lua แล้วรันใหม่")
    return
end
local CFG, SaveCFG = cfgLoader.m.new(
    "SpectreWare.json",
    { "Enabled", "NPCSESP", "ShowHP", "ShowHPText", "ShowName", "ShowDist", "BypassAntiESP", "HideDeadESP", "HideFriends", "AntiAFK" },
    { "BoxThickness", "HPBarWidth", "NameSize", "MaxDist", "ESPDetailDist" },
    { "BoxColor" },
    {
        Enabled = false,
        NPCSESP = true,
        BoxColor = Color3.fromRGB(255, 60, 60),
        BoxThickness = 2,
        ShowHP = true,
        HPBarWidth = 5,
        ShowHPText = true,
        ShowName = true,
        NameSize = 15,
        ShowDist = true,
        MaxDist = 600,
        BypassAntiESP = true,
        HideDeadESP = true,
        HideFriends = false,
        AntiAFK = true,
        ESPDetailDist = 120,
    }
)
local saveCfgQueued = false
local function saveCfgSoon()
    if saveCfgQueued then return end
    saveCfgQueued = true
    task.delay(0.5, function()
        saveCfgQueued = false
        pcall(SaveCFG)
    end)
end
task.wait()
local Window = SpectreLib:CreateWindow({
    Title = "SpectreWare | NEVER TOWN  v1.6.12",
    Logo = 75093357559651,
    Theme = "Mono",
    Width = 640,
    Height = 480,
    ToggleKey = Enum.KeyCode.LeftControl,
    HideOpenButtonOnPC = true,
    Resizable = true,
    Splash = false,
    StagedLoad = { Auto = false, TabDelay = 0.12, BuildDelay = 0.15 },
})
pcall(function()
    local acc = Window.Theme and Window.Theme.Accent
    if typeof(acc) == "Color3" then
        SpectreAccent = acc
        SW.Edge2 = acc
    end
end)
SW.winEvents = { open = {}, close = {}, destroy = {} }
SW.fireWinEvent = function(kind)
    for _, fn in ipairs(SW.winEvents[kind]) do
        task.spawn(fn)
    end
end
function Window:OnOpen(fn) t_insert(SW.winEvents.open, fn) end
function Window:OnClose(fn) t_insert(SW.winEvents.close, fn) end
function Window:OnDestroy(fn) t_insert(SW.winEvents.destroy, fn) end
do
    local origSetVisible, origDestroy = Window.SetVisible, Window.Destroy
    function Window:SetVisible(v)
        local was = self.Visible
        origSetVisible(self, v)
        if self.Visible ~= was then SW.fireWinEvent(self.Visible and "open" or "close") end
    end
    function Window:Destroy()
        SW.alive = false
        SW.fireWinEvent("destroy")
        return origDestroy(self)
    end
end
do
    ENV.SpectreNT_Cleanup = function() pcall(function() Window:Destroy() end) end
end
SW.NotifyKinds = {
    ["wrench"] = "Warning",
    ["x-circle"] = "Error",
    ["alert-triangle"] = "Error",
    ["check-circle"] = "Success",
}
function SW.Notify(cfg)
    pcall(function()
        Window:Notify({
            Title = cfg.Title,
            Content = cfg.Content,
            Duration = cfg.Duration,
            Kind = SW.NotifyKinds[cfg.Icon] or "Info",
            Icon = cfg.Icon and ("lucide:" .. cfg.Icon) or nil,
            -- lock notices use the UI theme colour instead of the amber warning colour
            Color = cfg.Color or (cfg.Icon == "lock" and Window.Theme and Window.Theme.Accent) or nil,
        })
    end)
end
SW.failShownAt = -m_huge
ENV.SpectreUiNotice = function()
    if os.clock() - SW.failShownAt < 10 then return end
    SW.failShownAt = os.clock()
    SW.Notify({ Title = "ขัดข้อง", Icon = "x-circle", Content = "ฟีเจอร์นี้ใช้งานไม่ได้ในตอนนี้ แจ้งทีมงานแล้ว", Duration = 4 })
end
SW.hold, SW.revealed = {}, false
pcall(function()
    local g = Window.Gui
    if g then
        g.Enabled = false
        SW.hold[#SW.hold + 1] = g
    end
end)
function SW.reveal()
    if SW.revealed then return end
    SW.revealed = true
    for _, g in ipairs(SW.hold) do
        pcall(function()
            if g.Parent then g.Enabled = true end
        end)
    end
end
task.delay(45, SW.reveal)
task.spawn(function()
    allTrees = workspace:WaitForChild("AllPlantedTrees", 30)
    if allTrees then parentFolder = allTrees:WaitForChild(folderName, 15) end
    pcall(
        function() giveWaterRemote = game:GetService("ReplicatedStorage"):WaitForChild("Grow_vegetables", 15):WaitForChild("GiveWater", 10) end
    )
    task.wait(0.5)
    local t0 = os.clock()
    while not SW.buildWaterPickDropdown and os.clock() - t0 < 20 do
        task.wait(0.2)
    end
    if SW.buildWaterPickDropdown then pcall(SW.buildWaterPickDropdown) end
end)
local function resolveRemotePath(root, path, timeout)
    local cur = root
    for _, name in ipairs(path) do
        if not cur then return nil end
        cur = cur:WaitForChild(name, math.min(timeout or 1, 2))
    end
    return cur
end
local function optionKey(opt) return type(opt) == "table" and (opt.Title or opt.Name) or tostring(opt) end
local AmountDescLabel
local function setAmount(text)
    if AmountDescLabel then
        text = tostring(text)
        if SW.lastAmountText ~= text then
            SW.lastAmountText = text
            pcall(AmountDescLabel.Set, AmountDescLabel, nil, text)
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
local safeHudGui, safeHudIcon, safeHudName, safeHudCount
local function buildSafeHud()
    if safeHudGui and safeHudGui.Parent then return end
    safeHudGui = Instance.new("ScreenGui")
    safeHudGui.Name = "SW_SafeHUD"
    safeHudGui.ResetOnSpawn = false
    safeHudGui.IgnoreGuiInset = true
    safeHudGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    safeHudGui.DisplayOrder = 40
    safeHudGui.Parent = LP.PlayerGui
    local card = SW.new("Frame", {
        Name = "Card",
        Size = UDim2.fromOffset(204, 66),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.12, 0, 0.78, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.02,
        BorderSizePixel = 0,
        Active = true,
        Visible = false,
    }, safeHudGui)
    SW.round(card, 16)
    SW.new("UIGradient", { Color = ColorSequence.new(SW.BgTop, SW.Bg), Rotation = 125 }, card)
    SW.edge(card, 1.5, 0.2, 45)
    local iconBg = SW.new("Frame", {
        Size = UDim2.fromOffset(46, 46),
        Position = UDim2.new(0, 10, 0.5, -23),
        BackgroundColor3 = SW.Row,
        BorderSizePixel = 0,
        ZIndex = 2,
    }, card)
    SW.round(iconBg, 12)
    SW.stroke(iconBg, SpectreAccent, 1, 0.55)
    safeHudIcon = SW.new("ImageLabel", {
        Size = UDim2.fromOffset(36, 36),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 1,
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 3,
    }, iconBg)
    safeHudName = SW.new("TextLabel", {
        Size = UDim2.new(1, -74, 0, 20),
        Position = UDim2.fromOffset(64, 9),
        BackgroundTransparency = 1,
        TextColor3 = SW.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 2,
    }, card)
    safeHudCount = SW.new("TextLabel", {
        Size = UDim2.new(1, -74, 0, 24),
        Position = UDim2.fromOffset(64, 32),
        BackgroundTransparency = 1,
        TextColor3 = SW.Good,
        Font = Enum.Font.GothamBold,
        TextSize = 17,
        RichText = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 2,
    }, card)
    SW.drag(card, card)
end
local function getHudCard()
    if safeHudGui and safeHudGui.Parent then return safeHudGui:FindFirstChild("Card") end
end
local HomeTab = Window:CreateTab({ Name = "Home", Icon = "lucide:house" })
local FarmTab = Window:CreateTab({ Name = "Menu", Icon = "lucide:archive" })
SW.FishTab = Window:CreateTab({ Name = "Fishing", Icon = "lucide:fish" })
SW.EatTab = Window:CreateTab({ Name = "Auto Eat", Icon = "lucide:utensils" })
SW.CandyHardLock = false -- true = ล็อคทุกคน (รวม whitelist) | false = เปิดเฉพาะ SW.CandyAllowed
SW.CandyLockText = "แท็บนี้ปิดปรับปรุงชั่วคราว (กำลังแก้บัก) ฟีเจอร์อื่นใช้งานได้ตามปกติ"
SW.CandyTab = Window:CreateTab({
    Name = "Candy Farm", Icon = "lucide:candy",
    Locked = SW.CandyHardLock, LockReason = SW.CandyLockText,   -- SpectreUI tab lock API
    LockedNotify = false,                                       -- we show our own notify below
    OnLockedClick = function() if SW.CandyLockNotify then SW.CandyLockNotify() end end,
})
local TeleportTab = Window:CreateTab({ Name = "Teleport", Icon = "lucide:map-pin" })
SW.SafeTab = Window:CreateTab({ Name = "SAFE", Icon = "lucide:package" })
SW.ServerTab = Window:CreateTab({ Name = "Server", Icon = "lucide:server" })
local SettingsTab = Window:CreateTab({ Name = "Settings", Icon = "lucide:settings" })
if not (Window.StartLoad and Window.OnLoaded and HomeTab.Load) then
    pcall(ENV.SpectreReport, "OldSpectreUI", "SpectreUI too old (StartLoad/OnLoaded/Tab.Load missing)")
    pcall(function() Window:Destroy() end)
    return warn("SpectreUI is outdated, update required.")
end
SW.building, SW.lastY, SW.frameBudget = true, os.clock(), 0.006
task.delay(40, function() SW.building = false end)
SW.softYield = function()
    if SW.building and os.clock() - SW.lastY >= SW.frameBudget then
        task.wait()
        SW.lastY = os.clock()
    end
end
do
    local ELEM = {
        CreateToggle = true,
        CreateButton = true,
        CreateDropdown = true,
        CreateSlider = true,
        CreateTextbox = true,
        CreateKeybind = true,
        CreateColorPicker = true,
        CreateParagraph = true,
        CreateLabel = true,
        CreateDivider = true,
        CreateThemeManager = true,
    }
    local function wrapSection(sec)
        return setmetatable({}, {
            __index = function(_, k)
                local v = sec[k]
                if type(v) ~= "function" then return v end
                if ELEM[k] then
                    return function(_, ...)
                        local r = v(sec, ...)
                        SW.softYield()
                        return r
                    end
                end
                return function(_, ...) return v(sec, ...) end
            end,
            __newindex = function(_, k, val) sec[k] = val end,
        })
    end
    for _, t in ipairs({ HomeTab, FarmTab, SW.FishTab, TeleportTab, SW.SafeTab, SW.ServerTab, SettingsTab }) do
        local orig = t.CreateSection
        if type(orig) == "function" then
            t.CreateSection = function(_, ...)
                local s = orig(t, ...)
                SW.softYield()
                if type(s) == "table" then return wrapSection(s) end
                return s
            end
        end
    end
end
SW.Changelog = {
    {
        title = "อัปเดตล่าสุด • 2026-10-22",
        added = {
            "แท็บ Candy Farm ล็อคชั่วคราว เปิดให้เฉพาะผู้ที่ได้รับสิทธิ์ระหว่างที่แก้บัก",
            "แจ้งเตือนสวยๆ เมื่อแท็บถูกล็อค พร้อมปุ่ม \"ทำไมถึงใช้ไม่ได้?\" กดดูเหตุผลซ้ำได้",
        },
        fixed = {
            "ผู้ที่ไม่ได้รับสิทธิ์จะไม่โหลดระบบออโต้ปลูกแคนดี้เลย ไม่ไปรบกวนฟีเจอร์อื่น แท็บอื่นใช้งานได้ปกติ",
            "แผงสถานะ Candy แบบลอยในแท็บ Menu ยังใช้งานได้ตามเดิม",
        },
    },
    {
        title = "อัปเดต • 2026-10-03",
        added = {
            "หน้า Home แสดงรายการอัปเดต (เพิ่มอะไร / แก้อะไร) ที่คุณกำลังอ่านอยู่นี้",
            "เอฟเฟกต์ตอนกดปิดที่ปุ่มรูปแบบใหม่: แสงฟุ้งและสะเก็ดแสงม่วง/ฟ้าไหลเข้าหาปุ่ม พร้อมวงแหวนไล่สีหดมาชนขอบปุ่ม",
            "โลโก้หน้าโหลดย้ายไปใช้ Roblox asset ทำให้สคริปต์เล็กลง",
        },
        fixed = {
            "ปุ่มรูปตอนปิด: ยุบลงเล็กน้อยแล้วเด้งคืนนุ่มๆ แทนการหดธรรมดา และขอบปุ่มวาบสีม่วงตอนแสงถึง",
            "กดปุ่มรัวๆ ระหว่างเล่นเอฟเฟกต์แล้วแอนิเมชันไม่ซ้อนกัน",
        },
    },
}
SW.ChangelogURL = "https://raw.githubusercontent.com/SpectreWareZ/SpectreWare/refs/heads/main/Tools/changelog.lua"
SW.LoadHome = function()
    local list = SW.Changelog
    pcall(function()
        local src = cfgLoader.fetch(SW.ChangelogURL .. "?v=" .. os.time())
        local fn = loadstring(src)
        local remote = fn and fn()
        if type(remote) ~= "table" then return end
        local ok = {}
        for _, e in ipairs(remote) do
            if type(e) == "table" and type(e.title) == "string" then ok[#ok + 1] = e end
        end
        if #ok > 0 then list = ok end
    end)
    for i, entry in ipairs(list) do
        local sec = HomeTab:CreateSection({ Name = entry.title, Icon = (i == 1) and "lucide:sparkles" or "lucide:history", Collapsed = (i ~= 1) })
        local function block(title, icon, list)
            if not list or #list == 0 then return end
            local lines = {}
            for k, line in ipairs(list) do
                lines[k] = "• " .. line
            end
            sec:CreateParagraph({ Title = title, Content = table.concat(lines, "\n") })
        end
        block("เพิ่มใหม่", "plus-circle", entry.added)
        block("แก้ไข / ปรับปรุง", "wrench", entry.fixed)
    end
end
local function LoadFarmTab()
    local DepositRemote, FarmRunning = nil, false
    local depositRunId = 0
    local BACKPACK_GUI = "Backpack_Never"
    local function getScrolling()
        local bp = LP.PlayerGui:FindFirstChild(BACKPACK_GUI)
        if not bp then return nil end
        local bg = bp:FindFirstChild("BG")
        if not bg then return nil end
        local it = bg:FindFirstChild("item")
        if not it then return nil end
        return it:FindFirstChild("Scrollingitem")
    end
    local ITEM_THAI = {
        ["Grape"] = "องุ่น",
        ["Peach"] = "พีช",
        ["Orange"] = "ส้ม",
        ["Cauliflower"] = "กะหล่ำดอก",
        ["Corn"] = "ข้าวโพด",
        ["Gold"] = "ทอง",
        ["Iron"] = "เหล็ก",
        ["MineIron"] = "แร่เหล็ก",
        ["MineGold"] = "แร่ทอง",
    }
    local BLOCKED_ITEMS = {
        ["CASH"] = true,
        ["IDCard"] = true,
        ["R8"] = true,
        ["Classic"] = true,
    }
    local function loadBackpackItems()
        local scrolling = getScrolling()
        if not scrolling then
            local ok, s = pcall(
                function()
                    return LP.PlayerGui
                        :WaitForChild(BACKPACK_GUI, 5)
                        :WaitForChild("BG", 5)
                        :WaitForChild("item", 5)
                        :WaitForChild("Scrollingitem", 5)
                end
            )
            if ok then scrolling = s end
        end
        local titles, itemMap = {}, {}
        if scrolling then
            local count = 0
            for _, slot in ipairs(scrolling:GetChildren()) do
                if not slot:IsA("Frame") then continue end
                local name = slot.Name
                if name == "" or name == "Animation" then continue end
                if BLOCKED_ITEMS[name] then continue end
                count = count + 1
                if count % 10 == 0 then task.wait() end
                local max = 60
                local nl = name:lower()
                if nl:find("stone") or nl:find("gold") or nl:find("iron") then max = 500 end
                pcall(function()
                    local a = slot:FindFirstChild("Amout", true)
                    if a and a:IsA("TextLabel") then
                        local m = tonumber(a.Text:match("%d+|(%d+)"))
                        if m and m > 0 then max = m end
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
                local displayName = thaiName and (name .. " (" .. thaiName .. ")") or name
                t_insert(titles, displayName)
                itemMap[displayName] = { Title = displayName, value = name, max = max, icon = icon }
            end
        end
        if #titles == 0 then
            titles = { "(ไม่พบไอเทม)" }
            itemMap["(ไม่พบไอเทม)"] = { Title = "(ไม่พบไอเทม)", value = "", max = 0 }
        end
        local PINNED_ORDER = { "Cauliflower", "Corn", "Peach", "Grape", "Orange", "Gold", "Iron", "MineIron", "MineGold" }
        local pinnedSet, rest = {}, {}
        for _, t in ipairs(titles) do
            local entry = itemMap[t]
            if entry then
                pinnedSet[entry.value] = t
            else
                t_insert(rest, t)
            end
        end
        local pinnedKeys = {}
        for _, v in ipairs(PINNED_ORDER) do
            pinnedKeys[v] = true
        end
        for _, t in ipairs(titles) do
            local entry = itemMap[t]
            if entry and not pinnedKeys[entry.value] then t_insert(rest, t) end
        end
        titles = {}
        for _, key in ipairs(PINNED_ORDER) do
            if pinnedSet[key] then t_insert(titles, pinnedSet[key]) end
        end
        for _, t in ipairs(rest) do
            t_insert(titles, t)
        end
        return titles, itemMap
    end
    local PLACEHOLDER = "Reload"
    local FarmItemTitles = { PLACEHOLDER }
    local FarmItemMap = { [PLACEHOLDER] = { Title = PLACEHOLDER, value = "", max = 60 } }
    local SelectedItem = FarmItemMap[PLACEHOLDER]
    local CustomMax = 60
    local CustomMaxSet = false
    local UserSelectedItem = false
    local ItemDropdown = nil
    local suppressItemCallback = false
    local FarmSection = FarmTab:CreateSection({ Name = "Deposit Settings", Icon = "lucide:package" })
    local AutoFarmToggle
    local function setInSafe(text)
        if SafeDescLabel and SafeDescLabel.Parent then pcall(function() SafeDescLabel.Text = tostring(text) end) end
    end
    local function refreshSafePreview()
        buildSafeHud()
        local card = getHudCard()
        if not SelectedItem or SelectedItem.value == "" or not UserSelectedItem then
            setInSafe("ยังไม่ได้เลือกไอเทม")
            if card then card.Visible = false end
            return
        end
        local qty = getSafeQty(SelectedItem.value)
        local icon = SelectedItem.icon or ""
        setInSafe(SelectedItem.value .. "  ×  " .. tostring(qty) .. "  ในตู้")
        if safeHudIcon then safeHudIcon.Image = icon end
        if safeHudName then safeHudName.Text = SelectedItem.value end
        if safeHudCount then safeHudCount.Text = "×" .. SW.fmt(qty) .. ' <font size="11" color="rgb(150,141,190)">ในตู้</font>' end
        if card then card.Visible = true end
    end
    local function createItemDropdown(titles, itemMap)
        local options = {}
        for _, name in ipairs(titles) do
            local e = itemMap[name]
            t_insert(options, (e and e.icon and e.icon ~= "") and { Name = name, Image = e.icon } or name)
        end
        if ItemDropdown then
            local ok = pcall(function() ItemDropdown:Refresh(options, false) end)
            if ok then
                SelectedItem = itemMap[titles[1]]
                if SelectedItem then CustomMax = SelectedItem.max end
                return
            end
            pcall(function() ItemDropdown:Destroy() end)
            ItemDropdown = nil
        end
        ItemDropdown = FarmSection:CreateDropdown({
            Name = "Select Item",
            Placeholder = "ยังไม่ได้เลือก",
            Tooltip = "ดึงจาก Backpack ตรงๆ",
            Options = options,
            Searchable = true,
            Callback = function(option)
                if suppressItemCallback or not option then return end
                local key = optionKey(option)
                if UserSelectedItem and SelectedItem and SelectedItem.Title == key then
                    UserSelectedItem = false
                    SelectedItem = FarmItemMap[PLACEHOLDER]
                    refreshSafePreview()
                    task.defer(function() pcall(function() ItemDropdown:Set(nil, true) end) end)
                    return
                end
                SelectedItem = FarmItemMap[key]
                if SelectedItem then CustomMax = SelectedItem.max end
                UserSelectedItem = true
                refreshSafePreview()
            end,
        })
    end
    local function reloadItems()
        task.spawn(function()
            UserSelectedItem = false
            refreshSafePreview()
            local titles, itemMap
            for _ = 1, 5 do
                titles, itemMap = loadBackpackItems()
                if titles[1] ~= "(ไม่พบไอเทม)" then break end
                task.wait(1.5)
            end
            if titles and titles[1] ~= "(ไม่พบไอเทม)" then
                FarmItemTitles = titles
                FarmItemMap = itemMap
                createItemDropdown(titles, itemMap)
            end
        end)
    end
    task.wait()
    createItemDropdown(FarmItemTitles, FarmItemMap)
    reloadItems()
    task.wait()
    FarmSection:CreateTextbox({
        Name = "Deposit Amount",
        Placeholder = "ใส่ตัวเลข เช่น 30 / 60 / 500 (ค่าเริ่มต้น " .. tostring(CustomMax) .. ")",
        Callback = function(v)
            local n = tonumber(v)
            if n and n > 0 then
                CustomMax = n
                CustomMaxSet = true
            end
        end,
    })
    FarmSection:CreateButton({
        Name = "Reload Items",
        Icon = "lucide:refresh-cw",
        Tooltip = "กดถ้า Dropdown ยังโชว์ placeholder",
        Callback = reloadItems,
    })
    AmountDescLabel = FarmSection:CreateParagraph({ Title = "Current Amount", Content = "รอเลือกไอเทม..." })
    task.spawn(function()
        pcall(function()
            local safeFolder = LP:WaitForChild("Safe", 5)
            if not safeFolder then return end
            local function hookVal(v)
                v:GetPropertyChangedSignal("Value"):Connect(function()
                    if SelectedItem and SelectedItem.value ~= "" and UserSelectedItem and v.Name == SelectedItem.value then
                        refreshSafePreview()
                    end
                end)
            end
            for _, v in ipairs(safeFolder:GetChildren()) do
                hookVal(v)
            end
            safeFolder.ChildAdded:Connect(function(v)
                task.wait(0.1)
                hookVal(v)
            end)
        end)
    end)
    local slotLabelCache = setmetatable({}, { __mode = "k" })
    local function getSlotCount(slot)
        local lbl = slotLabelCache[slot]
        if not lbl or not lbl.Parent then
            lbl = slot:FindFirstChild("Amout", true)
            if not lbl then
                for _, c in ipairs(slot:GetDescendants()) do
                    if c:IsA("TextLabel") or c:IsA("TextButton") then
                        lbl = c
                        break
                    end
                end
            end
            slotLabelCache[slot] = lbl
        end
        if not lbl then return 0 end
        local ok, txt = pcall(SW.getText, lbl)
        txt = ok and txt or ""
        return tonumber(txt:match("%d+")) or 0
    end
    task.spawn(function()
        local cachedScrolling
        local function _amtTick()
            if not cachedScrolling or not cachedScrolling.Parent then
                cachedScrolling = getScrolling()
                if not cachedScrolling then return end
            end
            if SelectedItem and SelectedItem.value ~= "" and UserSelectedItem then
                local slot = cachedScrolling:FindFirstChild(SelectedItem.value)
                if slot then
                    setAmount(SelectedItem.value .. "  =  " .. getSlotCount(slot) .. " / " .. CustomMax)
                else
                    setAmount(SelectedItem.value .. " : ไม่พบใน Backpack")
                end
            else
                setAmount("ยังไม่ได้เลือกไอเทม")
            end
        end
        while SW.alive do
            SW.try("AmountTick", _amtTick)
            task.wait(3)
        end
    end)
    task.wait()
    AutoFarmToggle = FarmSection:CreateToggle({
        Name = "Auto Deposit",
        Tooltip = "เปิดแล้วเริ่มเก็บใส่ตู้ ปิดแล้วหยุด",
        Default = false,
        Callback = function(state)
            depositRunId = depositRunId + 1
            local myDepId = depositRunId
            if state then
                local noItem = not UserSelectedItem
                local noAmt = not CustomMaxSet
                if noItem or noAmt then
                    FarmRunning = false
                    task.spawn(function()
                        pcall(function() AutoFarmToggle:Set(false) end)
                    end)
                    local msg
                    if noItem and noAmt then
                        msg =
                            "เลือกของกับใส่จำนวนก่อนเปิด Auto Deposit"
                    elseif noItem then
                        msg = "เลือกของที่จะเก็บก่อนเปิด Auto Deposit"
                    else
                        msg =
                            "ใส่จำนวนของที่จะเก็บก่อนเปิด Auto Deposit"
                    end
                    SW.denySound()
                    SW.Notify({ Title = "เปิดไม่ได้", Icon = "lock", Content = msg, Duration = 4 })
                    return
                end
            end
            FarmRunning = state
            if not state then return end
            task.spawn(function()
                if not DepositRemote then
                    task.wait(0.5)
                    for _ = 1, 3 do
                        DepositRemote =
                            resolveRemotePath(game:GetService("ReplicatedStorage"), { "Game_Modules", "RemoteEventSafe", "DepositItem" }, 5)
                        if DepositRemote then break end
                        task.wait(1.5)
                    end
                end
                if not DepositRemote then
                    FarmRunning = false
                    SW.report("AutoDeposit_NoRemote", "DepositRemote not found")
                    return
                end
                SW.Notify({
                    Title = "Auto Deposit เปิด",
                    Icon = "check-circle",
                    Content = "กำลังเก็บใส่ตู้: " .. SelectedItem.value,
                    Duration = 3,
                })
                local farmScrolling
                local function depositTick()
                    if not farmScrolling or not farmScrolling.Parent then
                        farmScrolling = getScrolling()
                        if not farmScrolling then return end
                    end
                    local slot = farmScrolling:FindFirstChild(SelectedItem.value)
                    if not slot then return end
                    local cur = getSlotCount(slot)
                    if cur >= CustomMax and SelectedItem.value ~= "" then DepositRemote:FireServer(SelectedItem.value, cur) end
                end
                while FarmRunning and SW.alive and depositRunId == myDepId do
                    SW.try("Deposit", depositTick)
                    task.wait(1)
                end
            end)
        end,
    })
    task.wait()
    local WaterSection = FarmTab:CreateSection({ Name = "Candy Tree - Auto Water", Icon = "lucide:droplet" })
    local autoWaterEnabled, selectedWaterFolders, waterPickDropdown, waterFolderMap = false, {}, nil, {}
    local function buildFolderLabel(folder)
        local uid = tonumber(folder.Name:match("PlantedTrees_(%d+)"))
        if not uid then return folder.Name end
        local name = (Players:GetPlayerByUserId(uid) or {}).Name or tostring(uid)
        return folder.Name == folderName and ("ของฉัน (" .. name .. ")") or name
    end
    SW.buildWaterPickDropdown = function()
        local prevLabels = {}
        for _, f in ipairs(selectedWaterFolders) do
            prevLabels[buildFolderLabel(f)] = true
        end
        waterFolderMap = {}
        local titles = {}
        if allTrees then
            for _, folder in pairs(allTrees:GetChildren()) do
                local label = buildFolderLabel(folder)
                t_insert(titles, label)
                waterFolderMap[label] = folder
            end
        end
        if #titles == 0 then titles = { "(ไม่พบผู้เล่น)" } end
        local restoredTitles, restoredFolders = {}, {}
        for _, t in ipairs(titles) do
            if prevLabels[t] then
                t_insert(restoredTitles, t)
                t_insert(restoredFolders, waterFolderMap[t])
            end
        end
        if #restoredFolders > 0 then
            selectedWaterFolders = restoredFolders
        else
            selectedWaterFolders = waterFolderMap[titles[1]] and { waterFolderMap[titles[1]] } or {}
            restoredTitles = { titles[1] }
        end
        if waterPickDropdown then
            local ok = pcall(function() waterPickDropdown:Refresh(titles, false) end)
            if not ok then
                pcall(function() waterPickDropdown:Destroy() end)
                waterPickDropdown = nil
            end
            if waterPickDropdown then pcall(function() waterPickDropdown:Set(restoredTitles) end) end
        end
        if not waterPickDropdown then
            waterPickDropdown = WaterSection:CreateDropdown({
                Name = "Water Targets",
                Tooltip = "เลือกผู้เล่นได้หลายคน",
                Options = titles,
                Default = restoredTitles,
                Multi = true,
                Searchable = true,
                Callback = function(options)
                    selectedWaterFolders = {}
                    local list = type(options) == "table" and options or { options }
                    for _, opt in ipairs(list) do
                        local f = waterFolderMap[optionKey(opt)]
                        if f then t_insert(selectedWaterFolders, f) end
                    end
                end,
            })
        end
    end
    SW.buildWaterPickDropdown()
    local WATER_REACH_DIST = 15
    local function walkToTarget(model)
        local part = SW.treePart(model)
        if not part then return false, "หาตำแหน่งต้นไม้ไม่เจอ (BasePart)" end
        local hum2 = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if not hum2 then return false, "หา Humanoid ของตัวละครไม่เจอ (อาจกำลัง Respawn)" end
        if hum2.Health <= 0 then return false, "ตัวละครตายอยู่ รอ Respawn ก่อน" end
        local arrived = false
        local conn = hum2.MoveToFinished:Connect(function(reached) arrived = reached end)
        local moveOk = pcall(hum2.MoveTo, hum2, part.Position)
        if not moveOk then
            conn:Disconnect()
            return false,
                "สั่งเดินไม่ได้ (ตัวละครหายระหว่างเดิน)"
        end
        local t = os.clock()
        repeat
            task.wait(0.1)
        until arrived or not autoWaterEnabled or (os.clock() - t) > 20 or hum2.Health <= 0 or not hum2.Parent
        conn:Disconnect()
        if not autoWaterEnabled then
            local hrp0 = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if hrp0 and hum2.Parent then pcall(hum2.MoveTo, hum2, hrp0.Position) end
            return false, "ยกเลิก (ปิด Auto Water)"
        end
        if hum2.Health <= 0 or not hum2.Parent then
            return false, "ตัวละครตายหรือหายระหว่างเดิน"
        end
        if not arrived then
            return false,
                "เดินไม่ถึงในเวลาที่ตั้งไว้ (อาจติดสิ่งกีดขวางหรือทางตัน)"
        end
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            if (hrp.Position - part.Position).Magnitude > WATER_REACH_DIST then
                return false,
                    "เดินถึงแล้วแต่ยังอยู่นอกระยะรดน้ำ ("
                        .. WATER_REACH_DIST
                        .. " studs)"
            end
            return true
        end
        return arrived, (arrived and nil or "หา HumanoidRootPart ไม่เจอ")
    end
    local walkFailNotifiedAt = setmetatable({}, { __mode = "k" })
    local WALK_FAIL_NOTIFY_COOLDOWN = 10
    local function notifyWalkFail(tree, reason)
        local now = os.clock()
        local last = walkFailNotifiedAt[tree]
        if last and (now - last) < WALK_FAIL_NOTIFY_COOLDOWN then return end
        walkFailNotifiedAt[tree] = now
        SW.Notify({
            Title = "เดินไปรดน้ำไม่ได้",
            Icon = "footprints",
            Content = (tree and tree.Name or "?") .. ": " .. (reason or "ไม่ทราบสาเหตุ"),
            Duration = 4,
        })
    end
    local playerControls
    task.spawn(function()
        pcall(function() playerControls = require(LP.PlayerScripts:WaitForChild("PlayerModule", 5)):GetControls() end)
    end)
    local function setWaterInputLock(state)
        if not playerControls then return end
        if state then
            playerControls:Disable()
        else
            playerControls:Enable()
        end
    end
    local STILL_SPEED = 0.3
    local function waitUntilStill(settle, timeout)
        local t0 = os.clock()
        local stillSince
        while autoWaterEnabled and (os.clock() - t0) < timeout do
            local ch = LP.Character
            local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
            local h = ch and ch:FindFirstChildOfClass("Humanoid")
            if not hrp or not h or h.Health <= 0 then return false end
            local v = hrp.AssemblyLinearVelocity
            local moving = Vector3.new(v.X, 0, v.Z).Magnitude > STILL_SPEED or h.MoveDirection.Magnitude > 0.01
            if moving then
                stillSince = nil
            else
                stillSince = stillSince or os.clock()
                if os.clock() - stillSince >= settle then return true end
            end
            task.wait(0.05)
        end
        return false
    end
    local function checkAndWater(tree)
        if not tree or not tree.Parent then return end
        local stats = tree:FindFirstChild("Stats")
        if not stats then return end
        local wv = stats:FindFirstChild("Water")
        if not wv or not giveWaterRemote then return end
        local gv = stats:FindFirstChild("Growth")
        if gv and (tonumber(gv.Value) or 0) >= 100 then return end
        if m_floor(wv.Value) >= 100 then return end
        local treePart = SW.treePart(tree)
        local walked, walkFailReason = walkToTarget(tree)
        if not walked then
            if autoWaterEnabled then notifyWalkFail(tree, walkFailReason) end
            return
        end
        if not waitUntilStill(0.4, 5) then
            if autoWaterEnabled then notifyWalkFail(tree, "ตัวละครยังไม่นิ่ง เลยยังไม่รดน้ำ") end
            return
        end
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if treePart and hrp and (hrp.Position - treePart.Position).Magnitude > WATER_REACH_DIST then
            notifyWalkFail(tree, "อยู่นอกระยะรดน้ำ (" .. WATER_REACH_DIST .. " studs)")
            return
        end
        local tries = 0
        while autoWaterEnabled and tree.Parent and wv.Parent and m_floor(wv.Value) < 100
            and not (gv and (tonumber(gv.Value) or 0) >= 100) do
            if not waitUntilStill(0, 3) then break end
            giveWaterRemote:FireServer(tree)
            task.wait(0.8)
            tries = tries + 1
            if tries > 60 then break end
        end
    end
    local waterRunId = 0
    local AutoWaterToggle
    AutoWaterToggle = WaterSection:CreateToggle({
        Name = "Auto Water",
        Tooltip = "รดน้ำให้เองเมื่อน้ำต่ำกว่า 50% เรียงจากใกล้ไปไกล",
        Default = false,
        Callback = function(state)
            waterRunId = waterRunId + 1
            local myRunId = waterRunId
            autoWaterEnabled = state
            setWaterInputLock(state)
            if not state then return end
            if #selectedWaterFolders == 0 then
                autoWaterEnabled = false
                setWaterInputLock(false)
                task.spawn(function()
                    pcall(function() AutoWaterToggle:Set(false) end)
                end)
                SW.denySound()
                SW.Notify({
                    Title = "เปิดไม่ได้",
                    Icon = "lock",
                    Content = "เลือกผู้เล่นที่จะรดน้ำก่อนเปิด Auto Water",
                    Duration = 4,
                })
                return
            end
            task.spawn(function()
                local function isCurrent() return autoWaterEnabled and waterRunId == myRunId end
                local ok, err = SW.try("AutoWater", function()
                    while isCurrent() do
                        local orderedFolders, ownFolder = {}, nil
                        for _, folder in ipairs(selectedWaterFolders) do
                            if folder and folder.Parent then
                                if folder.Name == folderName then
                                    ownFolder = folder
                                else
                                    t_insert(orderedFolders, folder)
                                end
                            end
                        end
                        if ownFolder then t_insert(orderedFolders, 1, ownFolder) end
                        for _, folder in ipairs(orderedFolders) do
                            if not isCurrent() then break end
                            local treeList = {}
                            pcall(function()
                                for _, tree in pairs(folder:GetChildren()) do
                                    local stats = tree:FindFirstChild("Stats")
                                    local wv = stats and stats:FindFirstChild("Water")
                                    local gv = stats and stats:FindFirstChild("Growth")
                                    local grown = gv and (tonumber(gv.Value) or 0) >= 100
                                    if wv and wv.Value <= 49 and not grown then t_insert(treeList, tree) end
                                end
                            end)
                            local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                            if hrp and #treeList > 1 then
                                local posCache = {}
                                for _, tree in ipairs(treeList) do
                                    local p = SW.treePart(tree)
                                    posCache[tree] = p and p.Position
                                end
                                local myPos = hrp.Position
                                t_sort(treeList, function(a, b)
                                    local pa, pb = posCache[a], posCache[b]
                                    return (pa and (myPos - pa).Magnitude or m_huge) < (pb and (myPos - pb).Magnitude or m_huge)
                                end)
                            end
                            for _, tree in ipairs(treeList) do
                                if not isCurrent() then break end
                                SW.try("WaterTree", checkAndWater, tree)
                            end
                        end
                        task.wait(5)
                    end
                end)
                if not ok then
                    SW.report("AutoWater_Crash", err)
                end
                if waterRunId == myRunId then
                    autoWaterEnabled = false
                    setWaterInputLock(false)
                    if not ok then pcall(function() AutoWaterToggle:Set(false) end) end
                end
            end)
        end,
    })
    task.wait()
    local CandyMain, refreshTreeStatus, CandyPanelToggle
    do
        local C = {
            W = 344,
            MIN_H = 150,
            MAX_H = 330,
            LIST_Y = 84,
            BAR_W = 0.19,
            ROW_T = 0.55,
            Stats = {
                { x = 0.36, label = "น้ำ", color = SW.Water, icon = { "droplet", "droplets" } },
                { x = 0.58, label = "ปุ๋ย", color = SW.Food, icon = { "candy", "cookie", "apple" } },
                { x = 0.80, label = "โต", color = SW.Growth, icon = { "trending-up", "sprout" } },
            },
        }
        function C.icon(parent, names, size, color, props)
            if type(names) ~= "table" then names = { names } end
            for _, n in ipairs(names) do
                local ok, d = pcall(function() return SpectreLib:ResolveIcon("lucide:" .. n) end)
                if ok and d then
                    local img = SpectreLib:MakeIcon(d, color)
                    img.AnchorPoint = Vector2.new(0, 0)
                    img.Position = UDim2.new()
                    img.Size = UDim2.fromOffset(size, size)
                    img.Parent = parent
                    if props then
                        for k, v in pairs(props) do
                            img[k] = v
                        end
                    end
                    return img
                end
            end
            return nil
        end
        local CandyGui = Instance.new("ScreenGui")
        CandyGui.Name = "CandyStatusUI"
        CandyGui.ResetOnSpawn = false
        CandyGui.IgnoreGuiInset = true
        CandyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        CandyGui.DisplayOrder = 50
        pcall(function() CandyGui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
        if not CandyGui.Parent then CandyGui.Parent = LP:WaitForChild("PlayerGui") end
        CandyMain = SW.new("Frame", {
            Name = "MainFrame",
            Size = UDim2.fromOffset(C.W, 170),
            Position = UDim2.new(0, 20, 0, 120),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 0.02,
            BorderSizePixel = 0,
            Active = true,
            Visible = false,
        }, CandyGui)
        SW.round(CandyMain, 18)
        SW.new("UIGradient", { Color = ColorSequence.new(SW.BgTop, SW.Bg), Rotation = 115 }, CandyMain)
        SW.edge(CandyMain, 1.4, 0.25, 90)
        local header = SW.new("Frame", {
            Name = "Header",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 56),
            Active = true,
        }, CandyMain)
        local logo = SW.new("Frame", {
            Position = UDim2.fromOffset(14, 11),
            Size = UDim2.fromOffset(34, 34),
            BackgroundColor3 = SpectreAccent,
            BackgroundTransparency = 0.82,
            BorderSizePixel = 0,
        }, header)
        SW.round(logo, 11)
        SW.stroke(logo, SpectreAccent, 1, 0.65)
        C.icon(
            logo,
            { "trees", "tree-pine", "sprout", "leaf" },
            20,
            Color3.fromRGB(150, 190, 255),
            { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) }
        )
        SW.new("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(58, 9),
            Size = UDim2.new(1, -130, 0, 20),
            Font = Enum.Font.GothamBold,
            TextSize = 15,
            TextColor3 = SW.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = "Candy Tree Status",
        }, header)
        C.subLabel = SW.new("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(58, 30),
            Size = UDim2.new(1, -130, 0, 14),
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = SW.Sub,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = "กำลังโหลด...",
        }, header)
        C.BTN = SW.UIS.TouchEnabled and 40 or 28
        function C.btn(xOff, iconNames, hoverColor)
            local b = SW.new("TextButton", {
                Size = UDim2.fromOffset(C.BTN, C.BTN),
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, xOff, 0.5, 0),
                BackgroundColor3 = SW.Row,
                Text = "",
                AutoButtonColor = false,
            }, header)
            SW.round(b, C.BTN // 2)
            local ic = C.icon(b, iconNames, 14, SW.Text, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
            if SW.UIS.MouseEnabled then
                b.MouseEnter:Connect(function() SW.tween(b, 0.12, { BackgroundColor3 = hoverColor }) end)
                b.MouseLeave:Connect(function() SW.tween(b, 0.12, { BackgroundColor3 = SW.Row }) end)
            end
            return b, ic
        end
        local CandyCloseBtn = C.btn(-12, { "x" }, SW.Danger)
        local CandyRefreshBtn, refreshIcon = C.btn(-(12 + C.BTN + 6), { "refresh-cw", "rotate-cw" }, SpectreAccent)
        SW.drag(header, CandyMain)
        local sep = SW.new("Frame", {
            BackgroundColor3 = SpectreAccent,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 12, 0, 56),
            Size = UDim2.new(1, -24, 0, 1),
        }, CandyMain)
        SW.new("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.5, 0.65),
                NumberSequenceKeypoint.new(1, 1),
            }),
        }, sep)
        local legend = SW.new("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(10, 63),
            Size = UDim2.new(1, -24, 0, 18),
        }, CandyMain)
        for _, s in ipairs(C.Stats) do
            local cell = SW.new("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.new(s.x, 0, 0, 0),
                Size = UDim2.new(C.BAR_W, 0, 1, 0),
            }, legend)
            SW.new("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }, cell)
            C.icon(cell, s.icon, 13, s.color, { LayoutOrder = 1 })
            SW.new("TextLabel", {
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.X,
                Size = UDim2.fromOffset(0, 16),
                LayoutOrder = 2,
                Font = Enum.Font.GothamMedium,
                TextSize = 11,
                TextColor3 = s.color,
                Text = s.label,
            }, cell)
        end
        local CandyList = SW.new("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(10, C.LIST_Y),
            Size = UDim2.new(1, -16, 1, -(C.LIST_Y + 10)),
            ScrollBarThickness = SW.UIS.TouchEnabled and 6 or 3,
            ScrollBarImageColor3 = SpectreAccent,
            ScrollBarImageTransparency = 0.3,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
        }, CandyMain)
        local layout = SW.new("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 5),
        }, CandyList)
        local empty = SW.new("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -8, 0, 78),
            LayoutOrder = 0,
        }, CandyList)
        SW.new("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, empty)
        C.icon(empty, { "sprout", "leaf", "trees" }, 26, SW.Sub, { LayoutOrder = 1, ImageTransparency = 0.35 })
        C.emptyText = SW.new("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 16),
            LayoutOrder = 2,
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            TextColor3 = SW.Sub,
            Text = "กำลังโหลดข้อมูล...",
        }, empty)
        local lastFitH
        local function fit()
            local h = m_clamp(C.LIST_Y + layout.AbsoluteContentSize.Y + 12, C.MIN_H, C.MAX_H)
            if h == lastFitH then return end
            lastFitH = h
            SW.tween(CandyMain, 0.2, { Size = UDim2.fromOffset(C.W, h) })
        end
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(fit)
        function C.treeImage(tree)
            local ok, lbl = pcall(function()
                local gui = tree:FindFirstChild("HelpGui", true)
                local fr = gui and gui:FindFirstChild("Frame")
                if not fr then return nil end
                for _, n in ipairs({ "Item", "ImageProp" }) do
                    local l = fr:FindFirstChild(n)
                    if l and l:IsA("ImageLabel") and l.Image ~= "" then return l end
                end
            end)
            return ok and lbl or nil
        end
        local items = {}
        local structDirty = false
        local function ensureHeader(inst, text, count, order, isMine)
            local e = items[inst]
            if not e then
                structDirty = true
                local row = SW.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -8, 0, 26) }, CandyList)
                local ic = C.icon(
                    row,
                    isMine and { "user", "circle-user" } or { "users", "user" },
                    14,
                    SW.Sub,
                    { Position = UDim2.new(0, 4, 0.5, -7) }
                )
                local lbl = SW.new("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(24, 0),
                    Size = UDim2.new(1, -84, 1, 0),
                    Font = Enum.Font.GothamBold,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                }, row)
                local cnt = SW.new("TextLabel", {
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, -4, 0, 0),
                    Size = UDim2.new(0, 56, 1, 0),
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextColor3 = SW.Sub,
                    TextXAlignment = Enum.TextXAlignment.Right,
                }, row)
                e = { row = row, name = lbl, cnt = cnt, icon = ic }
                items[inst] = e
            end
            if e.order ~= order then
                e.order = order
                e.row.LayoutOrder = order
            end
            if e.text ~= text then
                e.text = text
                e.name.Text = text
            end
            if e.count ~= count then
                e.count = count
                e.cnt.Text = count .. " ต้น"
            end
            if e.mine ~= isMine then
                e.mine = isMine
                e.name.TextColor3 = isMine and SpectreAccent or SW.Text
                if e.icon then e.icon.ImageColor3 = isMine and SpectreAccent or SW.Sub end
            end
        end
        local function ensureRow(inst, name, w, f, g, order)
            local e = items[inst]
            if not e then
                structDirty = true
                local row = SW.new("Frame", {
                    BackgroundColor3 = SW.Row,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, -8, 0, 32),
                }, CandyList)
                SW.round(row, 10)
                SW.tween(row, 0.25, { BackgroundTransparency = C.ROW_T })
                local fallbackIc = C.icon(row, { "sprout", "leaf" }, 14, SW.Growth, { Position = UDim2.new(0, 10, 0.5, -7) })
                local lbl = SW.new("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(30, 0),
                    Size = UDim2.new(0.34, -30, 1, 0),
                    Font = Enum.Font.GothamMedium,
                    TextSize = 12,
                    TextColor3 = SW.Text,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                }, row)
                local bars = {}
                for i, s in ipairs(C.Stats) do
                    local track = SW.new("Frame", {
                        BackgroundColor3 = SW.Track,
                        BorderSizePixel = 0,
                        ClipsDescendants = true,
                        Position = UDim2.new(s.x, 0, 0.5, -8),
                        Size = UDim2.new(C.BAR_W, 0, 0, 16),
                    }, row)
                    SW.round(track, 8)
                    local fill = SW.new("Frame", {
                        BackgroundColor3 = s.color,
                        BackgroundTransparency = 0.15,
                        BorderSizePixel = 0,
                        Size = UDim2.new(0, 0, 1, 0),
                    }, track)
                    SW.round(fill, 8)
                    SW.new(
                        "UIGradient",
                        {
                            Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(205, 205, 205)),
                            Rotation = 90,
                        },
                        fill
                    )
                    local txt = SW.new("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        ZIndex = 2,
                        Font = Enum.Font.GothamBold,
                        TextSize = 10,
                        TextColor3 = Color3.new(1, 1, 1),
                        TextStrokeTransparency = 0.6,
                        Text = "0%",
                    }, track)
                    bars[i] = { fill = fill, txt = txt, color = s.color }
                end
                e = { row = row, name = lbl, bars = bars, icon = fallbackIc }
                items[inst] = e
            end
            if not e.imgSet then
                local src = C.treeImage(inst)
                if src then
                    e.imgSet = true
                    if e.icon then e.icon.Visible = false end
                    pcall(function()
                        SW.new("ImageLabel", {
                            BackgroundTransparency = 1,
                            Position = UDim2.new(0, 7, 0.5, -10),
                            Size = UDim2.fromOffset(20, 20),
                            Image = src.Image,
                            ImageRectOffset = src.ImageRectOffset,
                            ImageRectSize = src.ImageRectSize,
                            ScaleType = Enum.ScaleType.Fit,
                        }, e.row)
                    end)
                end
            end
            if e.order ~= order then
                e.order = order
                e.row.LayoutOrder = order
            end
            if e.text ~= name then
                e.text = name
                e.name.Text = name
            end
            for i, b in ipairs(e.bars) do
                local raw = (i == 1 and w) or (i == 2 and f) or g
                local v = m_clamp(tonumber(raw) or 0, 0, 100)
                if b.v ~= v then
                    b.v = v
                    b.txt.Text = m_floor(v) .. "%"
                    b.fill.BackgroundColor3 = (i == 1 and v < 20) and SW.Danger or b.color
                    SW.tween(b.fill, 0.35, { Size = UDim2.new(v / 100, 0, 1, 0) })
                end
            end
        end
        C.t, C.w, C.f, C.g = {}, {}, {}, {}
        C.uid = setmetatable({}, { __mode = "k" })
        refreshTreeStatus = function()
            pcall(function()
                if not allTrees then allTrees = workspace:FindFirstChild("AllPlantedTrees") end
                if not allTrees then
                    if C.emptyText.Text ~= "กำลังโหลดข้อมูล..." then
                        C.emptyText.Text = "กำลังโหลดข้อมูล..."
                    end
                    empty.Visible = true
                    return
                end
                local seen, order, total = {}, 0, 0
                for _, folder in pairs(allTrees:GetChildren()) do
                    local uid = C.uid[folder]
                    if uid == nil then
                        uid = tonumber(folder.Name:match("PlantedTrees_(%d+)")) or false
                        C.uid[folder] = uid
                    end
                    local dname = uid and ((Players:GetPlayerByUserId(uid) or {}).Name or tostring(uid)) or folder.Name
                    local isMine = folder.Name == folderName
                    local header = isMine and ("ของฉัน (" .. dname .. ")") or dname
                    local tT, tW, tF, tG, n = C.t, C.w, C.f, C.g, 0
                    for _, tree in pairs(folder:GetChildren()) do
                        local stats = tree:FindFirstChild("Stats")
                        if stats then
                            local w = stats:FindFirstChild("Water")
                            local f = stats:FindFirstChild("Food")
                            local g = stats:FindFirstChild("Growth")
                            n = n + 1
                            tT[n] = tree
                            tW[n] = w and w.Value or 0
                            tF[n] = f and f.Value or 0
                            tG[n] = g and g.Value or 0
                        end
                    end
                    if n > 0 then
                        total = total + n
                        order = order + 1
                        seen[folder] = true
                        ensureHeader(folder, header, n, order, isMine)
                        for i = 1, n do
                            local tree = tT[i]
                            tT[i] = nil
                            order = order + 1
                            seen[tree] = true
                            ensureRow(tree, tree.Name, tW[i], tF[i], tG[i], order)
                        end
                    end
                end
                for inst, e in pairs(items) do
                    if not seen[inst] then
                        e.row:Destroy()
                        items[inst] = nil
                        structDirty = true
                    end
                end
                empty.Visible = (order == 0)
                if order == 0 and C.emptyText.Text ~= "ไม่พบต้นแคนดี้" then
                    C.emptyText.Text = "ไม่พบต้นแคนดี้"
                end
                local sub = total > 0 and (total .. " ต้น | อัปเดตทุก 4 วิ")
                    or "ไม่มีข้อมูล"
                if C.subLabel.Text ~= sub then C.subLabel.Text = sub end
                if structDirty then
                    structDirty = false
                    task.delay(0.05, fit)
                end
            end)
        end
        CandyCloseBtn.MouseButton1Click:Connect(function()
            CandyMain.Visible = false
            pcall(function() CandyPanelToggle:Set(false) end)
        end)
        local spinning = false
        CandyRefreshBtn.MouseButton1Click:Connect(function()
            if refreshIcon and not spinning then
                spinning = true
                refreshIcon.Rotation = 0
                SW.tween(refreshIcon, 0.5, { Rotation = 360 })
                task.delay(0.55, function() spinning = false end)
            end
            task.spawn(function() SW.try("TreeStatus", refreshTreeStatus) end)
        end)
        task.spawn(function()
            while SW.alive do
                task.wait(4)
                if CandyMain.Visible and not SW.isDragging then SW.try("TreeStatus", refreshTreeStatus) end
            end
        end)
    end
    task.wait()
    CandyPanelToggle = WaterSection:CreateToggle({
        Name = "Show Tree Status UI",
        Tooltip = "เปิด/ปิดแผงสถานะต้นไม้ที่ลอยอยู่ ลากย้ายได้",
        Default = false,
        Callback = function(state)
            CandyMain.Visible = state
            if state then
                SW.pop(CandyMain)
                SW.try("TreeStatus", refreshTreeStatus)
            end
        end,
    })
    WaterSection:CreateButton({
        Name = "Reload Candy",
        Icon = "lucide:refresh-cw",
        Tooltip = "โหลดข้อมูลต้นแคนดี้ใหม่และรีเฟรชรายชื่อผู้เล่น",
        Callback = function()
            task.spawn(function()
                allTrees = workspace:FindFirstChild("AllPlantedTrees")
                parentFolder = allTrees and allTrees:FindFirstChild(folderName) or nil
                task.wait(0.3)
                SW.buildWaterPickDropdown()
                refreshTreeStatus()
                SW.Notify({
                    Title = "รีเฟรชแล้ว",
                    Icon = "refresh-cw",
                    Content = "อัปเดตรายชื่อผู้เล่นแล้ว",
                    Duration = 3,
                })
            end)
        end,
    })
end
local function LoadTeleportTab()
    local function A(id) return "rbxassetid://" .. id end
    local ICON_GARAGE = A("99428541054573")
    local ICON_GAS = A("132348950185756")
    local Locations = {
        { Title = "ปลูกแคนดี้ (มินิแมพเกม)", Position = Vector3.new(3046.795, 0.703, 662.523), Img = A("110425764136152"), Key = "plantCandy" },
        { Title = "ตัดไม้ (Wood)", Position = Vector3.new(-866.013, 24.13, -4003.826), Img = A("91943172065402"), Key = "Wood" },
        { Title = "เหมือง (Mine)", Position = Vector3.new(1067.779, 22.676, 5330.04), Img = A("127430380358142"), Key = "Mine" },
        { Title = "นาซ่า (Nasa)", Position = Vector3.new(-2825.87, 0.777, 3600.15), Img = A("113373271416630"), Key = "Nasa" },
        { Title = "เห็ด (Mushroom)", Position = Vector3.new(-2283.547, 89.083, -5207.612), Img = A("89311367435239"), Key = "Mushroom" },
        { Title = "เก็บขี้ (Poop)", Position = Vector3.new(-1699.68, 0.408, -187.402), Img = A("124974228589556"), Key = "Poop" },
        { Title = "กะหล่ำ", Position = Vector3.new(-4168.924, 73.68, 1200.048), Img = A("122060013253395"), Key = "Cauliflower" },
        { Title = "ข้าวโพด", Position = Vector3.new(-4521.129, 121.83, 413.401), Img = A("99704142695713"), Key = "Corn" },
        { Title = "พีช", Position = Vector3.new(-5200.449, 96.208, -252.969), Img = A("140281424213479"), Key = "Peach" },
        { Title = "องุ่น", Position = Vector3.new(-5210.451, 95.821, -542.606), Img = A("136015585832185"), Key = "Grape" },
        { Title = "ส้ม", Position = Vector3.new(-4619.112, 121.592, -832.225), Img = A("89183187146997"), Key = "Orange" },
        { Title = "เนื้อวัว (Beef)", Position = Vector3.new(-1862.251, 0.422, -448.037), Img = A("128296620260244"), Key = "Beef" },
        { Title = "ผักกาด (Lettuce)", Position = Vector3.new(-3100.51, 45.843, -1077.348), Img = A("132591729093336"), Key = "Lettuce" },
        { Title = "ข้าว (Rice)", Position = Vector3.new(-3183.808, 46.197, -1350.211), Img = A("131987931432803"), Key = "Rice" },
        { Title = "เมลอน (Melon)", Position = Vector3.new(-3381.215, 47.712, -1896), Img = A("109405249665565"), Key = "Melon" },
        { Title = "ตกปลาทะเลลึก", Position = Vector3.new(-1934.433, 0.166, 1231.153), Img = A("111648180019928"), Key = "DeepSeafishing1" },
        { Title = "ตลาด (Market)", Position = Vector3.new(3059.354, 2.753, 619.172), Img = A("98517733284302"), Key = "Market" },
        { Title = "โรงแปรรูป เหล็ก+ทอง", Position = Vector3.new(2737.5, 42.629, -1022.676), Img = A("121613973911504"), Key = "ProcessAll" },
        { Title = "แปรรูปไม้ (แผ่นไม้)", Position = Vector3.new(-1502.828, 1.467, -4412.845), Img = A("87760295874471"), Key = "ProcessWoodBoard" },
        { Title = "แปรรูปไม้ (เยื่อไม้)", Position = Vector3.new(-1436.098, 1.426, -4382.762), Img = A("92903499071816"), Key = "ProcessWoodPulp" },
        { Title = "Wish (กาชา)", Position = Vector3.new(3004.27, 0.703, 622.63), Img = A("136112763876149"), Key = "Wish" },
        { Title = "ร้านรถ (CarShop)", Position = Vector3.new(3501.188, 0.653, 1377.415), Img = A("138812509586188"), Key = "CarShop" },
        { Title = "ร้านแต่งรถ", Position = Vector3.new(2619.039, 0.704, 1105.369), Img = A("109458456513719"), Key = "VehicleCustom" },
        { Title = "โรงพยาบาล", Position = Vector3.new(2071.743, 0.703, 1451.185), Img = A("113407340829995"), Key = "Hospital" },
        { Title = "สถานีตำรวจ", Position = Vector3.new(2080.583, 74.645, 1883.181), Img = A("87379406167436"), Key = "Police" },
        { Title = "ปั๊มน้ำมัน 1", Position = Vector3.new(1874.212, 32.58, 20.785), Img = ICON_GAS, Key = "GasStation 1" },
        { Title = "ปั๊มน้ำมัน 2", Position = Vector3.new(-532.426, 0.729, 3840.912), Img = ICON_GAS, Key = "GasStation 2" },
        { Title = "ปั๊มน้ำมัน 3", Position = Vector3.new(-3266.664, 0.743, 1218.61), Img = ICON_GAS, Key = "GasStation 3" },
        { Title = "ปั๊มน้ำมัน 4", Position = Vector3.new(1632.248, 0.859, -6489.933), Img = ICON_GAS, Key = "GasStation 4" },
        { Title = "Label", Position = Vector3.new(3709.34, 40.543, 6290.65), Img = A("114945556081376"), Key = "Label" },
        { Title = "การาจแดง", Position = Vector3.new(3135.683, 0.653, -13.839), Img = ICON_GARAGE, Key = "GarageRad" },
        { Title = "การาจน้ำเงิน", Position = Vector3.new(3847.59, 0.653, 702.82), Img = ICON_GARAGE, Key = "GarageBlue" },
        { Title = "การาจเทา", Position = Vector3.new(1179.435, 0.73, 1280.809), Img = ICON_GARAGE, Key = "GarageGrey" },
        { Title = "การาจเขียว", Position = Vector3.new(2571.936, 0.653, 1867.416), Img = ICON_GARAGE, Key = "GarageGreen" },
        { Title = "การาจชมพู", Position = Vector3.new(-54.843, 110.06, -1608.074), Img = ICON_GARAGE, Key = "GaragePink" },
        { Title = "การาจเงิน", Position = Vector3.new(3822.548, 0.653, -35.119), Img = ICON_GARAGE, Key = "GarageSilver" },
        { Title = "การาจเหลือง", Position = Vector3.new(3068.115, 0.703, 615.834), Img = ICON_GARAGE, Key = "GarageYellow" },
        { Title = "การาจฟ้า", Position = Vector3.new(3101.569, 48.493, -799.189), Img = ICON_GARAGE, Key = "GarageSky" },
        { Title = "การาจ Halloween", Position = Vector3.new(3821.15, 0.653, 729.8), Img = A("121774278192453"), Key = "Halloween26" },
    }
    local Hardcoded, CustomLocs, NameByKey = {}, {}, {}
    for _, l in ipairs(Locations) do
        if l.Custom then
            t_insert(CustomLocs, l)
        else
            t_insert(Hardcoded, l)
            if l.Key then NameByKey[l.Key] = l end
        end
    end
    local function loadLive()
        local ok, icons = pcall(function()
            local RS = game:GetService("ReplicatedStorage")
            local gm = RS:FindFirstChild("Game_Modules")
            local m = (gm and gm:FindFirstChild("MapConfig")) or RS:FindFirstChild("MapConfig", true)
            return require(m).Icons
        end)
        if not ok or type(icons) ~= "table" or #icons == 0 then return nil end
        local list = {}
        for _, ic in ipairs(icons) do
            if typeof(ic.Position) == "Vector3" and type(ic.Image) == "string" and ic.Image ~= "" then
                local known = NameByKey[ic.Name]
                t_insert(list, {
                    Title = known and known.Title or tostring(ic.Name),
                    Position = ic.Position,
                    Img = ic.Image,
                    Key = ic.Name,
                })
            end
        end
        return #list > 0 and list or nil
    end
    local LocationOptions, LocationMap = {}, {}
    local SelectedLocation
    local liveCount = 0
    local function rebuildLocations()
        local live = loadLive()
        liveCount = live and #live or 0
        local list = {}
        for _, l in ipairs(live or Hardcoded) do t_insert(list, l) end
        for _, l in ipairs(CustomLocs) do t_insert(list, l) end
        Locations = list
        table.clear(LocationOptions); table.clear(LocationMap)
        for _, loc in ipairs(Locations) do
            if LocationMap[loc.Title] then loc.Title = loc.Title .. " (" .. tostring(loc.Key or "?") .. ")" end
            t_insert(LocationOptions, loc.Img and { Name = loc.Title, Image = loc.Img } or loc.Title)
            LocationMap[loc.Title] = loc
        end
        if not (SelectedLocation and LocationMap[SelectedLocation.Title]) then SelectedLocation = Locations[1] end
    end
    rebuildLocations()
    local function groundAt(pos, ch)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { ch }
        params.RespectCanCollide = true
        local hit = workspace:Raycast(pos + Vector3.new(0, 8, 0), Vector3.new(0, -60, 0), params)
        if not hit then
            hit = workspace:Raycast(pos + Vector3.new(0, 400, 0), Vector3.new(0, -800, 0), params)
        end
        return hit and hit.Position or pos
    end
    local function safeTeleport(loc)
        local ch = LP.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if not hrp then return false, "ไม่พบตัวละคร" end
        if hum and hum.SeatPart then hum.Sit = false; task.wait(0.1) end
        local target = groundAt(loc.Position, ch) + Vector3.new(0, 3, 0)
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        ch:PivotTo(CFrame.new(target))
        task.delay(0.25, function()
            local h2 = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if h2 and (h2.Position - target).Magnitude > 40 then
                pcall(function() LP.Character:PivotTo(CFrame.new(target)) end)
            end
        end)
        return true
    end
    local TPSec = TeleportTab:CreateSection({ Name = "Teleport", Icon = "lucide:map-pin" })
    local TPDropdown = TPSec:CreateDropdown({
        Name = "Select Location",
        Tooltip = "เลือกที่ที่จะ Teleport ไป (พิกัด+ไอคอนจาก MapConfig ของเกม)",
        Options = LocationOptions,
        Default = Locations[1].Title,
        Searchable = true,
        Callback = function(opt)
            if type(opt) == "table" then opt = opt.Name or opt.Title end
            SelectedLocation = LocationMap[opt] or SelectedLocation
        end,
    })
    TPSec:CreateButton({
        Name = "Teleport",
        Icon = "lucide:navigation",
        Tooltip = "กดเพื่อ Teleport ไปที่เลือกไว้",
        Callback = function()
            local ok, res, why = pcall(safeTeleport, SelectedLocation)
            if not ok then
                SW.report("Teleport", res)
            elseif res == false then
                SW.Notify({ Title = "Teleport", Icon = "x-circle", Content = tostring(why), Duration = 4 })
            end
        end,
    })
    TPSec:CreateButton({
        Name = "Refresh Locations",
        Icon = "lucide:refresh-cw",
        Tooltip = "โหลดรายการจุดใหม่จาก MapConfig (ใช้หลังเกมอัพเดทแมพ)",
        Callback = function()
            rebuildLocations()
            pcall(function() TPDropdown:Refresh(LocationOptions, false) end)
            SW.Notify({
                Title = "Teleport", Icon = "check-circle", Duration = 4,
                Content = liveCount > 0 and ("โหลด " .. liveCount .. " จุดจากแมพ")
                    or "อ่าน MapConfig ไม่ได้ ใช้ลิสต์สำรอง",
            })
        end,
    })
    do
        ENV.SpectreNT_NpcGen = (ENV.SpectreNT_NpcGen or 0) + 1
        local npcGen = ENV.SpectreNT_NpcGen
        local npcFolder
        local npcIds, npcNext = setmetatable({}, { __mode = "k" }), 0
        local NpcOptions, NpcMap, NpcOrder = {}, {}, {}
        local SelectedNpc
        local NpcDropdown
        local lastSig = ""
        local npcMissingReported = false
        local function npcPart(obj)
            return obj.PrimaryPart
                or obj:FindFirstChild("HumanoidRootPart")
                or obj:FindFirstChildWhichIsA("BasePart", true)
        end
        local function npcSpawned(obj)
            if not obj:IsA("Model") or not obj:IsDescendantOf(workspace) then return false end
            if obj:GetAttribute("Active") ~= true then return false end
            if obj:GetAttribute("IsLoading") == true then return false end
            if obj:GetAttribute("Done") == true then return false end
            local part = npcPart(obj)
            if not part then return false end
            local p = part.Position
            if p.Y < -500 or p.Magnitude > 100000 then return false end
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health <= 0 then return false end
            for _, d in ipairs(obj:GetDescendants()) do
                if d:IsA("BasePart") and d.Transparency < 0.95 then return true end
            end
            return false
        end
        local function npcLabel(obj, root)
            local id = npcIds[obj]
            if not id then npcNext += 1; id = npcNext; npcIds[obj] = id end
            local part = npcPart(obj)
            local d = (root and part) and math.floor((part.Position - root.Position).Magnitude) or 0
            return string.format("%s #%d  [%dm]", obj.Name, id, d)
        end
        local function scanNpc()
            if not (npcFolder and npcFolder.Parent) then
                local sys = workspace:FindFirstChild("System")
                npcFolder = sys and sys:FindFirstChild("[Server] Npc_Seal")
                if not npcFolder and not npcMissingReported then
                    npcMissingReported = true
                    local kids = {}
                    if sys then
                        for _, c in ipairs(sys:GetChildren()) do t_insert(kids, c.Name) end
                    end
                    pcall(function()
                        ENV.SpectreReport("NPC_FolderMissing", string.format(
                            "ไม่พบ workspace.System[\"[Server] Npc_Seal\"] | System=%s | children(System)=%s",
                            sys and "found" or "missing",
                            #kids > 0 and table.concat(kids, ", "):sub(1, 400) or "-"
                        ))
                    end)
                end
            end
            local found = {}
            if not npcFolder then return found end
            local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            for _, o in ipairs(npcFolder:GetChildren()) do
                if npcSpawned(o) then t_insert(found, o) end
            end
            if root then
                table.sort(found, function(a, b)
                    return (npcPart(a).Position - root.Position).Magnitude < (npcPart(b).Position - root.Position).Magnitude
                end)
            end
            return found
        end
        local function rebuildNpc(force)
            local found = scanNpc()
            local ids = {}
            for _, o in ipairs(found) do npcLabel(o); t_insert(ids, npcIds[o]) end
            table.sort(ids)
            local sig = table.concat(ids, ",")
            if sig == lastSig and not force then return #found end
            lastSig = sig
            local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            table.clear(NpcOptions); table.clear(NpcMap); table.clear(NpcOrder)
            for _, o in ipairs(found) do
                local label = npcLabel(o, root)
                t_insert(NpcOptions, label)
                NpcMap[label] = o
                NpcOrder[o] = label
            end
            if not (SelectedNpc and NpcOrder[SelectedNpc]) then SelectedNpc = found[1] end
            if #NpcOptions == 0 then t_insert(NpcOptions, "(ยังไม่มี NPC เกิด)") end
            if NpcDropdown then
                pcall(function() NpcDropdown:Refresh(NpcOptions, false) end)
                local cur = SelectedNpc and NpcOrder[SelectedNpc] or NpcOptions[1]
                pcall(function() NpcDropdown:Set(cur) end)
            end
            return #found
        end
        local function teleportToNpc(obj)
            if not (obj and obj.Parent and npcSpawned(obj)) then return false, "NPC ตัวนี้หายไป/ยังไม่เกิด กด Refresh แล้วเลือกใหม่" end
            local part = npcPart(obj)
            return safeTeleport({ Position = part.Position + Vector3.new(5, 0, 0) })
        end
        local NPCSec = TeleportTab:CreateSection({ Name = "NPC ที่เกิดอยู่", Icon = "lucide:ghost" })
        rebuildNpc(true)
        NpcDropdown = NPCSec:CreateDropdown({
            Name = "Select NPC",
            Tooltip = "เลือก NPC ที่เกิดอยู่ตอนนี้ (เรียงจากใกล้ไปไกล) ตัวที่ยังไม่เกิดจะไม่โผล่",
            Options = NpcOptions,
            Default = SelectedNpc and NpcOrder[SelectedNpc] or NpcOptions[1],
            Searchable = true,
            Callback = function(opt)
                if type(opt) == "table" then opt = opt.Name or opt.Title end
                if NpcMap[opt] then SelectedNpc = NpcMap[opt] end
            end,
        })
        NPCSec:CreateButton({
            Name = "Teleport to NPC",
            Icon = "lucide:navigation",
            Tooltip = "วาร์ปไปหา NPC ที่เลือกไว้",
            Callback = function()
                local ok, res, why = pcall(teleportToNpc, SelectedNpc)
                if not ok then
                    SW.report("NPC_Teleport", res)
                elseif res == false then
                    SW.Notify({ Title = "NPC", Icon = "x-circle", Content = tostring(why), Duration = 4 })
                end
            end,
        })
        NPCSec:CreateButton({
            Name = "Teleport to Nearest NPC",
            Icon = "lucide:crosshair",
            Tooltip = "วาร์ปไป NPC ที่เกิดอยู่และใกล้ที่สุด",
            Callback = function()
                local found = scanNpc()
                if #found == 0 then
                    SW.Notify({ Title = "NPC", Icon = "x-circle", Content = "ยังไม่มี NPC เกิด", Duration = 4 })
                    return
                end
                local ok, res, why = pcall(teleportToNpc, found[1])
                if not ok then
                    SW.report("NPC_Teleport", res)
                elseif res == false then
                    SW.Notify({ Title = "NPC", Icon = "x-circle", Content = tostring(why), Duration = 4 })
                end
            end,
        })
        NPCSec:CreateButton({
            Name = "Refresh NPC",
            Icon = "lucide:refresh-cw",
            Tooltip = "โหลดรายการ NPC ใหม่ + อัปเดตระยะทาง",
            Callback = function()
                local n = rebuildNpc(true)
                SW.Notify({ Title = "NPC", Icon = "check-circle", Content = "เจอ NPC ที่เกิดอยู่ " .. n .. " ตัว", Duration = 3 })
            end,
        })
        task.spawn(function()
            while task.wait(1) do
                if ENV.SpectreNT_NpcGen ~= npcGen then break end
                pcall(rebuildNpc, false)
            end
        end)
    end
end
local function LoadSettingsTab()
    local function doAntiAFK()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
        pcall(function()
            if hum and hum.Parent and hum.Health > 0 then
                hum:Move(v3_new(0.001, 0, 0), false)
                task.wait(0.1)
                hum:Move(v3_new(0, 0, 0), false)
            end
        end)
    end
    AntiAFKEnabled = CFG.AntiAFK ~= false
    LP.Idled:Connect(function()
        if SW.alive and AntiAFKEnabled then doAntiAFK() end
    end)
    local FB = {
        on = false,
        target = {
            Ambient = Color3.fromRGB(178, 178, 178),
            OutdoorAmbient = Color3.fromRGB(155, 155, 180),
            Brightness = 1,
            ClockTime = 14,
            FogEnd = 1e6,
            FogStart = 1e6,
            GlobalShadows = false,
        },
        fxClasses = { SunRaysEffect = true, DepthOfFieldEffect = true },
        orig = {},
        origFx = {},
        conns = {},
        fxConns = {},
    }
    function FB.differs(cur, want)
        if type(cur) == "number" then return m_abs(cur - want) > 1e-3 end
        return cur ~= want
    end
    function FB.force(prop)
        local cur = Lighting[prop]
        local want = FB.target[prop]
        if FB.differs(cur, want) then
            FB.orig[prop] = cur
            Lighting[prop] = want
        end
    end
    function FB.hookFx(fx)
        if not FB.fxClasses[fx.ClassName] or FB.fxConns[fx] then return end
        FB.origFx[fx] = fx.Enabled
        fx.Enabled = false
        FB.fxConns[fx] = fx:GetPropertyChangedSignal("Enabled"):Connect(function()
            if fx.Enabled then
                FB.origFx[fx] = true
                fx.Enabled = false
            end
        end)
    end
    function FB.unhookFx(fx)
        local c = FB.fxConns[fx]
        if c then
            c:Disconnect()
            FB.fxConns[fx] = nil
            FB.origFx[fx] = nil
        end
    end
    function FB.enable()
        pcall(function()
            for prop, want in pairs(FB.target) do
                FB.orig[prop] = Lighting[prop]
                Lighting[prop] = want
            end
            for _, fx in ipairs(Lighting:GetChildren()) do
                FB.hookFx(fx)
            end
        end)
        for prop in pairs(FB.target) do
            t_insert(FB.conns, Lighting:GetPropertyChangedSignal(prop):Connect(function() FB.force(prop) end))
        end
        t_insert(FB.conns, Lighting.ChildAdded:Connect(FB.hookFx))
        t_insert(FB.conns, Lighting.ChildRemoved:Connect(FB.unhookFx))
    end
    function FB.disable()
        for _, c in ipairs(FB.conns) do
            c:Disconnect()
        end
        table.clear(FB.conns)
        pcall(function()
            for prop, v in pairs(FB.orig) do
                Lighting[prop] = v
            end
            for fx, c in pairs(FB.fxConns) do
                c:Disconnect()
                if fx.Parent then fx.Enabled = FB.origFx[fx] end
            end
        end)
        table.clear(FB.fxConns)
        table.clear(FB.origFx)
        table.clear(FB.orig)
    end
    local function setFullbright(state)
        state = state and true or false
        if state == FB.on then return end
        FB.on = state
        if state then
            FB.enable()
        else
            FB.disable()
        end
    end
    local GameplaySettings = SettingsTab:CreateSection({ Name = "Gameplay", Icon = "lucide:gamepad-2" })
    GameplaySettings:CreateToggle({
        Name = "Anti AFK",
        Tooltip = "กันโดนเตะออกเกมตอนไม่ได้เล่น",
        Default = CFG.AntiAFK ~= false,
        Callback = function(s)
            AntiAFKEnabled = s
            CFG.AntiAFK = s
            saveCfgSoon()
        end,
    })
    GameplaySettings:CreateToggle({
        Name = "Fullbright",
        Tooltip = "มองเห็นชัดในที่มืด ตัด fog/shadow/bloom ออก",
        Default = false,
        Callback = setFullbright,
    })
    local UISettings = SettingsTab:CreateSection({ Name = "UI Configuration", Icon = "lucide:palette" })
    UISettings:CreateKeybind({
        Flag = "UIKeybind",
        Name = "Toggle Menu Key",
        Default = Enum.KeyCode.LeftControl,
        Tooltip = "ปุ่มเปิด/ปิดเมนู กดแล้วเลือกคีย์ที่ต้องการ",
        Callback = function() end,
        Changed = function(key)
            if typeof(key) == "EnumItem" then Window:SetToggleKey(key) end
        end,
    })
    UISettings:CreateThemeManager({ Name = "UI Theme", Delete = false })
    UISettings:CreateFontPicker({ Name = "UI Font", Remember = true })
end
SW.charParts = function()
    local c = LP.Character
    return c, c and c:FindFirstChild("HumanoidRootPart")
end
SW.LoadSafe = function()
    local RS = game:GetService("ReplicatedStorage")
    local PG = LP:WaitForChild("PlayerGui")
    local FOLDER = "Safe"
    local function isValueType(v)
        return v:IsA("DoubleConstrainedValue") or v:IsA("IntValue") or v:IsA("NumberValue") or v:IsA("IntConstrainedValue")
    end
    local function getItemImage(itemName)
        local ok, img = pcall(function()
            local n = PG:FindFirstChild("Backpack_Never")
            n = n and n:FindFirstChild("BG")
            n = n and n:FindFirstChild("item")
            n = n and n:FindFirstChild("Scrollingitem")
            local slot = n and n:FindFirstChild(itemName)
            local il = slot and slot:FindFirstChild("ItemImage")
            return il and il:IsA("ImageLabel") and il.Image or nil
        end)
        if ok and type(img) == "string" and img ~= "" then return img end
        return nil
    end
    local function getWithdrawRemote()
        local ok, r = pcall(function()
            local m = RS:WaitForChild("Game_Modules", 1)
            local f = m and m:WaitForChild("RemoteEventSafe", 1)
            return f and f:WaitForChild("WithdrawItem", 1)
        end)
        return ok and r or nil
    end
    local function Withdraw(itemName, amount)
        amount = math.floor(tonumber(amount) or 0)
        if amount <= 0 then return false, "bad amount" end
        local r = getWithdrawRemote()
        if not r then return false, "remote not found" end
        if r:IsA("RemoteFunction") then
            local ok, res = SW.try("RemoteInvoke", function() return r:InvokeServer(itemName, amount) end)
            if not ok then return false, tostring(res) end
            if res == false then return false, "server refused" end
            return true
        elseif r:IsA("RemoteEvent") then
            local ok, err = SW.try("RemoteFire", function() r:FireServer(itemName, amount) end)
            return ok, ok and nil or tostring(err)
        end
        return false, "unsupported remote"
    end
    local T = {
        Tab = "SAFE", TabIcon = "lucide:package",
        Info = "ตู้เซฟ", InfoIcon = "lucide:package-open",
        Items = "ของในตู้", ItemsIcon = "lucide:list",
        Status = "สถานะ", Unit = "ชนิด", Refresh = "รีเฟรช",
        Loading = "โหลด...", Empty = "ตู้ว่าง",
        Hint = "แตะไอเทมแล้วใส่จำนวนที่จะเอาออก", Total = "รวม %d ชิ้น",
        AskTitle = "เอาของออก : ", Confirm = "ยืนยันเอาออก",
    }
    local GREEN = Color3.fromRGB(52, 211, 153)
    local RED = Color3.fromRGB(248, 113, 113)
    local YELLOW = Color3.fromRGB(250, 204, 21)
    local GRAY = Color3.fromRGB(148, 163, 184)
    local SafeTab = SW.SafeTab
    local Info = SafeTab:CreateSection({ Name = T.Info, Icon = T.InfoIcon, Column = 1 })
    local status = Info:CreateBadge({ Name = T.Status, Value = T.Loading, Color = YELLOW })
    local hint = Info:CreateLabel({ Text = T.Hint, Color = GRAY })
    local GridSec = SafeTab:CreateSection({ Name = T.Items, Icon = T.ItemsIcon, Column = 2 })
    local items = {}
    local busy = false
    local Refresh
    local grid = GridSec:CreateItemGrid({
        Empty = T.Empty,
        Callback = function(item)
            if busy then return end
            task.spawn(function()
                local name = item.Name
                local have = items[name] or 0
                local amt = Window:AskAmount({
                    Title = T.AskTitle .. name, Max = have, Default = 1, Confirm = T.Confirm, Icon = T.InfoIcon,
                })
                if not amt then return end
                local now = items[name] or 0
                if amt > now then return Window:Error(T.Info, "เกินจำนวนในตู้ (มี " .. now .. ")", 2) end
                busy = true
                local ok, err = Withdraw(name, amt)
                busy = false
                if ok then
                    Window:Success(T.Info, "เอา " .. name .. " ×" .. amt .. " ออกแล้ว", 2)
                    task.delay(0.3, function() Refresh() end)
                else
                    warn("[SafeTab] withdraw failed:", err)
                    Window:Error(T.Info, err == "remote not found" and "ไม่เจอ Remote WithdrawItem" or ("ล้มเหลว: " .. tostring(err)), 3)
                end
            end)
        end,
    })
    Info:CreateButton({ Name = T.Refresh, Icon = "lucide:refresh-cw", Callback = function() Refresh() end })
    Refresh = function()
        status:Set(T.Loading) status:SetColor(YELLOW)
        local folder = LP:FindFirstChild(FOLDER) or LP:WaitForChild(FOLDER, 3)
        if typeof(folder) ~= "Instance" then
            items = {}
            grid:SetEmpty("ไม่เจอ folder: " .. FOLDER)
            grid:SetItems({})
            status:Set("ไม่เจอ " .. FOLDER) status:SetColor(RED)
            return
        end
        local list, newItems, total = {}, {}, 0
        for _, v in ipairs(folder:GetChildren()) do
            if isValueType(v) then
                local n = math.floor(v.Value)
                if n > 0 then
                    newItems[v.Name] = n
                    total += n
                    table.insert(list, { Name = v.Name, Amount = n, Image = getItemImage(v.Name) })
                end
            end
        end
        table.sort(list, function(a, b) return a.Name < b.Name end)
        items = newItems
        grid:SetEmpty(T.Empty)
        grid:SetItems(list)
        if #list == 0 then
            status:Set("ว่างเปล่า") status:SetColor(GRAY)
            hint:Set(T.Empty)
        else
            status:Set(#list .. " " .. T.Unit) status:SetColor(GREEN)
            hint:Set(string.format(T.Total, total) .. " · " .. T.Hint)
        end
    end
    local pending = false
    local function scheduleRefresh()
        if pending then return end
        pending = true
        task.delay(0.25, function()
            pending = false
            Refresh()
        end)
    end
    task.spawn(function()
        local folder = LP:WaitForChild(FOLDER, 10)
        if typeof(folder) == "Instance" then
            local function hook(v)
                if isValueType(v) then v:GetPropertyChangedSignal("Value"):Connect(scheduleRefresh) end
            end
            for _, v in ipairs(folder:GetChildren()) do hook(v) end
            folder.ChildAdded:Connect(function(v) hook(v) if isValueType(v) then scheduleRefresh() end end)
            folder.ChildRemoved:Connect(scheduleRefresh)
        end
        Refresh()
    end)
end
SW.LoadProcess = function()
    local RS = game:GetService("ReplicatedStorage")
    local ORES = {
        Gold = { ore = "MineGold", product = "Gold", prompt = "StoneGold" },
        Iron = { ore = "MineIron", product = "Iron", prompt = "StoneIron" },
    }
    local MODE_LIST = { "Gold (ทอง)", "Iron (เหล็ก)", "Gold + Iron (ทั้งสอง)" }
    local MODES = {
        [MODE_LIST[1]] = { "Gold" },
        [MODE_LIST[2]] = { "Iron" },
        [MODE_LIST[3]] = { "Gold", "Iron" },
    }
    local BATCH = 500
    local IDLE = { Gold = 30, Iron = 45 }
    local WARM_WAIT = 6
    local MOVE_LIST = { "วาป (Teleport)", "ไม่วาป (อยู่ใกล้จุด)" }
    local P = { on = false, run = 0, mode = MODE_LIST[1], keep = true, warm = {}, tp = true }
    local depositRemote, withdrawRemote
    local function live(id) return P.on and SW.alive and P.run == id end
    local function bagCount(name)
        local ok, n = pcall(function()
            local list = LP.PlayerGui.Backpack_Never.BG.item.Scrollingitem
            local lbl = list[name]:FindFirstChild("Amout", true)
            return tonumber(lbl.Text:match("%d+")) or 0
        end)
        return ok and n or 0
    end
    local function safeCount(name) return getSafeQty(name) end
    local function waitUntil(id, cond, timeout)
        local t0 = os.clock()
        while live(id) and os.clock() - t0 < timeout do
            if cond() then return true end
            task.wait(0.2)
        end
        return false
    end
    local function gate(id)
        while live(id) and LP:GetAttribute("FarmPaused") do task.wait(0.3) end
    end
    local function depositAll(id, name)
        local n = bagCount(name)
        if n <= 0 then return end
        depositRemote:FireServer(name, n)
        waitUntil(id, function() return bagCount(name) == 0 end, 5)
    end
    local function withdraw(id, name)
        local before = bagCount(name)
        local need = math.min(BATCH - before, safeCount(name))
        if need <= 0 then return end
        withdrawRemote:FireServer(name, need)
        waitUntil(id, function() return bagCount(name) > before end, 5)
    end
    local function getPrompt(name)
        local n = workspace:FindFirstChild("Processing")
        n = n and n:FindFirstChild(name)
        n = n and n:FindFirstChild("Procressing")
        n = n and n:FindFirstChild("Part")
        return n and n:FindFirstChildOfClass("ProximityPrompt"), n
    end
    local function goTo(part)
        if not P.tp then return end
        local _, root = SW.charParts()
        if not root then return end
        local target = (part.CFrame * CFrame.new(0, 3, 4)).Position
        if (root.Position - target).Magnitude < 6 then return end
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.CFrame = CFrame.lookAt(target, Vector3.new(part.Position.X, target.Y, part.Position.Z))
        task.wait(0.3)
    end
    local function stationSig(prompt, part)
        local t = { tostring(prompt.Enabled), prompt.ActionText, prompt.ObjectText }
        local root = part.Parent and part.Parent.Parent or part
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail") then
                t[#t + 1] = tostring(d.Enabled)
            elseif d:IsA("Sound") then
                t[#t + 1] = tostring(d.Playing)
            elseif d:IsA("TextLabel") then
                t[#t + 1] = d.Text
            elseif d:IsA("ValueBase") then
                t[#t + 1] = tostring(d.Value)
            end
            for k, v in pairs(d:GetAttributes()) do t[#t + 1] = k .. tostring(v) end
        end
        for k, v in pairs(root:GetAttributes()) do t[#t + 1] = k .. tostring(v) end
        return table.concat(t, "|")
    end
    local function processOre(id, e, warm)
        local prompt, part = getPrompt(e.prompt)
        if not prompt then
            SW.report("AutoProcess_NoPrompt", e.prompt)
            return false
        end
        local idleMax = IDLE[e.product] or 30
        gate(id)
        goTo(part)
        local lastOre, lastProd, lastSig = bagCount(e.ore), bagCount(e.product), stationSig(prompt, part)
        local ore0, sig0 = lastOre, lastSig
        local function busy()
            return bagCount(e.ore) < ore0 or not prompt.Enabled or stationSig(prompt, part) ~= sig0
        end
        local running = waitUntil(id, busy, warm and WARM_WAIT or 2.5)
        local tries = 0
        while live(id) and not running and tries < 3 do
            tries = tries + 1
            goTo(part)
            fireproximityprompt(prompt)
            running = waitUntil(id, busy, 6)
        end
        if not running then
            if live(id) then SW.report("AutoProcess_NoStart", e.prompt) end
            return false
        end
        local lastChange, drained = os.clock(), false
        lastOre, lastProd, lastSig = bagCount(e.ore), bagCount(e.product), stationSig(prompt, part)
        while live(id) do
            task.wait(1)
            if LP:GetAttribute("FarmPaused") then
                gate(id)
                lastChange = os.clock()
            end
            local ore, prod, sig = bagCount(e.ore), bagCount(e.product), stationSig(prompt, part)
            if ore <= 0 then
                drained = true
                break
            end
            if ore ~= lastOre or prod ~= lastProd or sig ~= lastSig then
                lastChange = os.clock()
                lastOre, lastProd, lastSig = ore, prod, sig
            elseif os.clock() - lastChange > idleMax then
                break
            end
        end
        return drained
    end
    local function cycle(id, e)
        depositAll(id, e.product)
        withdraw(id, e.ore)
        if bagCount(e.ore) <= 0 then return false end
        P.warm[e.product] = processOre(id, e, P.keep and P.warm[e.product]) and P.keep
        depositAll(id, e.product)
        return true
    end
    local Sec = FarmTab:CreateSection({ Name = "Auto Process (แปรรูป)", Icon = "lucide:factory" })
    local statusP
    local lastTxt = ""
    local function setStatus(t)
        if t == lastTxt then return end
        lastTxt = t
        if statusP then pcall(statusP.Set, statusP, nil, t) end
    end
    local toggle
    local function loop(id)
        depositRemote = depositRemote or resolveRemotePath(RS, { "Game_Modules", "RemoteEventSafe", "DepositItem" }, 5)
        withdrawRemote = withdrawRemote or resolveRemotePath(RS, { "Game_Modules", "RemoteEventSafe", "WithdrawItem" }, 5)
        if not (depositRemote and withdrawRemote) then
            SW.report("AutoProcess_NoRemote", "deposit/withdraw remote not found")
        else
            while live(id) do
                local worked = false
                for _, key in ipairs(MODES[P.mode]) do
                    if not live(id) then break end
                    setStatus("กำลังแปรรูป: " .. key)
                    worked = cycle(id, ORES[key]) or worked
                end
                if not worked then
                    SW.Notify({ Title = "Auto Process", Icon = "check-circle", Content = "ในตู้ไม่มีแร่แล้ว หยุดทำงาน", Duration = 5 })
                    break
                end
                task.wait(1)
            end
        end
        if P.run == id then
            P.on = false
            setStatus("หยุดแล้ว")
            task.defer(function() pcall(function() toggle:Set(false) end) end)
        end
    end
    Sec:CreateDropdown({
        Name = "Select Process",
        Tooltip = "เลือกว่าจะแปรรูปอะไร (เปลี่ยนระหว่างทำงานได้ มีผลรอบถัดไป)",
        Options = MODE_LIST,
        Default = MODE_LIST[1],
        Callback = function(opt)
            local key = optionKey(opt)
            if MODES[key] then P.mode = key end
        end,
    })
    Sec:CreateDropdown({
        Name = "Move Mode",
        Tooltip = "วาป = วาปไปจุดแปรรูปเอง | ไม่วาป = ยืนใกล้จุดเอง สคริปต์แค่กดปุ่ม",
        Options = MOVE_LIST,
        Default = MOVE_LIST[1],
        Callback = function(opt)
            P.tp = optionKey(opt) == MOVE_LIST[1]
        end,
    })
    statusP = Sec:CreateParagraph({ Title = "Status", Content = "ยังไม่เริ่ม" })
    toggle = Sec:CreateToggle({
        Name = "Auto Process",
        Tooltip = "เอาแร่จากตู้ > แปรรูป > เก็บของที่ได้เข้าตู้ วนจนแร่หมด",
        Default = false,
        Callback = function(state)
            P.run = P.run + 1
            P.on = state
            P.warm = {}
            if not state then
                setStatus("หยุดแล้ว")
                return
            end
            local id = P.run
            task.spawn(function() SW.try("AutoProcess", loop, id) end)
        end,
    })
end
SW.LoadNever = function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace         = game:GetService("Workspace")
    local TeleportService   = game:GetService("TeleportService")
    local GuiService        = game:GetService("GuiService")
    local CoreGui           = game:GetService("CoreGui")
    local SCRIPT_URL = "https://raw.githubusercontent.com/SpectreWareZ/SpectreWare/refs/heads/main/Games/NeverTown-AutoFarm.lua"
    local cfg = {
        farm      = false,
        fish      = false,
        rejoin    = true,
        sameServer = true,
        maxPlayersTarget = 6,
        preferLowPing    = true,
        fishLead         = 0,
        pickDelay        = 60,
        homeWait         = 180,
    }
    if ENV.SW_NEVER_STOP then pcall(ENV.SW_NEVER_STOP) end
    local alive = true
    local conns = {}
    local function track(c) conns[#conns + 1] = c; return c end
    if type(ENV.SW_NEVER_CFG) == "table" then
        for k, v in pairs(ENV.SW_NEVER_CFG) do
            if cfg[k] ~= nil and type(v) == type(cfg[k]) then cfg[k] = v end
        end
    end
    local statusP, toggles = nil, {}
    local lastStatus = ""
    local function setStatus(t)
        t = tostring(t)
        if t == lastStatus then return end
        lastStatus = t
        if statusP then pcall(statusP.Set, statusP, nil, t) end
    end
    local function notify(txt, icon)
        SW.Notify({ Title = "Fishing", Content = tostring(txt), Duration = 4, Icon = icon })
        setStatus(txt)
    end
    local function setToggle(key, v)
        cfg[key] = v
        local t = toggles[key]
        if t then pcall(function() t:Set(v) end) end
    end
    local function getChar()
        local c = LP.Character
        return c, c and c:FindFirstChild("HumanoidRootPart"), c and c:FindFirstChildOfClass("Humanoid")
    end
    local hopping = false
    local badServers = {}
    local function queueSelf()
        local q = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
        if not q then return false end
        if ENV.SpectreNT_Queued == game.JobId then return true end
        local code
        if SCRIPT_URL ~= "" then
            code = ("loadstring(game:HttpGet(%q))()"):format(SCRIPT_URL)
        end
        if not code then return false end
        local okQ = pcall(q, code)
        if okQ then ENV.SpectreNT_Queued = game.JobId end
        return okQ
    end
    local function disconnected()
        if GuiService:GetErrorMessage() ~= "" then return true end
        local ok, found = pcall(function()
            local g = CoreGui:FindFirstChild("RobloxPromptGui")
            local o = g and g:FindFirstChild("promptOverlay")
            return o and o:FindFirstChild("ErrorPrompt") ~= nil
        end)
        return ok and found == true
    end
    local MAX_PLAYERS = 50
    local RS = game:GetService("ReplicatedStorage")
    local function getMM()
        return RS:FindFirstChild("MatchmakingRemotes")
    end
    local homeIndex, homeJobId = nil, game.JobId
    local homeFailed = false
    local lastTp = 0
    local function readShards()
        local list = {}
        local cache = RS:FindFirstChild("ServerCache")
        if cache then
            local myUid = "UID_" .. tostring(LP.UserId)
            local maxU = 0
            for _, f in ipairs(cache:GetChildren()) do
                local u = tonumber(f:GetAttribute("UpdatedAt")) or 0
                if u > maxU then maxU = u end
            end
            for _, f in ipairs(cache:GetChildren()) do
                local idx = tonumber(f.Name:match("^Server(%d+)$"))
                if idx then
                    local pc, pl = f:FindFirstChild("PlayerCount"), f:FindFirstChild("Players")
                    local jid, pg = f:FindFirstChild("JobId"), f:FindFirstChild("Ping")
                    local n = (pc and tonumber(pc.Value)) or (pl and #pl:GetChildren()) or 0
                    local mine = (jid and jid.Value ~= "" and jid.Value == game.JobId) or false
                    if pl and not mine then
                        if pl:FindFirstChild(myUid) then
                            mine = true
                        else
                            for _, v in ipairs(pl:GetChildren()) do
                                if v.Name == myUid or (v:IsA("ValueBase") and tonumber(v.Value) == LP.UserId) then
                                    mine = true
                                    break
                                end
                            end
                        end
                    end
                    local u = tonumber(f:GetAttribute("UpdatedAt")) or maxU
                    local online = f:GetAttribute("Online") ~= false and (maxU - u) <= 180
                    list[#list + 1] = {
                        index = idx, playing = n, mine = mine, online = online,
                        ping = (pg and tonumber(pg.Value)) or 9e9,
                    }
                end
            end
        end
        if #list == 0 then
            local mm = getMM()
            local rf = mm and mm:FindFirstChild("RequestServerSnapshot")
            if rf then
                local ok, snap = pcall(function() return rf:InvokeServer() end)
                if ok and type(snap) == "table" then
                    for _, d in ipairs(snap) do
                        local idx = type(d) == "table" and tonumber(d.shardIndex)
                        if idx then
                            list[#list + 1] = {
                                index = idx, playing = tonumber(d.playerCount) or 0, online = true,
                                mine = (type(d.jobId) == "string" and d.jobId ~= "" and d.jobId == game.JobId),
                                ping = tonumber(d.serverPing) or 9e9,
                            }
                        end
                    end
                end
            end
        end
        return list
    end
    local function pickServer()
        local list = {}
        for _, s in ipairs(readShards()) do
            if not s.mine and s.online and not badServers[s.index] and s.playing < MAX_PLAYERS - 1 then
                list[#list + 1] = s
            end
        end
        if #list == 0 then return nil end
        table.sort(list, function(a, b)
            if a.playing ~= b.playing then return a.playing < b.playing end
            return a.index < b.index
        end)
        local limit = math.max(cfg.maxPlayersTarget, list[1].playing + 3)
        local pool = {}
        for _, s in ipairs(list) do
            if s.playing <= limit then pool[#pool + 1] = s end
        end
        if #pool == 0 then pool = { list[1] } end
        table.sort(pool, function(a, b)
            if cfg.preferLowPing then
                local pa, pb = math.floor(a.ping / 25), math.floor(b.ping / 25)
                if pa ~= pb then return pa < pb end
            end
            return a.index < b.index
        end)
        return pool[1]
    end
    local HttpService = game:GetService("HttpService")
    local function saveState(t)
        ENV.SpectreNT_State = t
        ENV.SpectreNT_Store.set("rejoin", t)
    end
    local function loadState()
        local t = ENV.SpectreNT_State
        if type(t) ~= "table" then t = ENV.SpectreNT_Store.get("rejoin") end
        return type(t) == "table" and t or nil
    end
    local function hop(reason, forceLowPop)
        if hopping then return end
        hopping = true
        saveState({ home = homeIndex, pending = true, t = os.time() })
        notify("Rejoin: " .. tostring(reason or "กำลังหาเซิร์ฟคนน้อย..."))
        task.spawn(function()
            local mm = getMM()
            local joinRF = (not disconnected()) and mm and mm:FindFirstChild("RequestJoinByIndex") or nil
            local tryHome = cfg.sameServer and not forceLowPop and not homeFailed
            if tryHome then
                local viaRemote = false
                if joinRF and homeIndex then
                    local home
                    for _, s in ipairs(readShards()) do
                        if s.index == homeIndex then home = s break end
                    end
                    if home and home.online and home.playing < MAX_PLAYERS then
                        notify("กลับเซิร์ฟเดิม Server " .. homeIndex)
                        local ok, res = pcall(function() return joinRF:InvokeServer(homeIndex) end)
                        if ok and type(res) == "table" and res.ok == true then
                            viaRemote = true
                            task.wait(20)
                        end
                    end
                end
                if not viaRemote and alive then
                    notify("กลับเซิร์ฟเดิมด้วย JobId")
                    homeFailed = true
                    lastTp = os.clock()
                    pcall(function()
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, homeJobId, LP)
                    end)
                    -- รอนานพอให้วาร์ปเสร็จ ไม่งั้นด่านเฝ้าสั่งย้ายเซิร์ฟสุ่มทับ
                    task.wait(45)
                end
                hopping = false
                return
            end
            for _ = 1, 6 do
                if not alive then hopping = false return end
                if not joinRF then break end
                local s = pickServer()
                if not s then
                    task.wait(3)
                else
                    notify(("ย้ายไป Server %d (%d/%d คน, ping %s)"):format(
                        s.index, s.playing, MAX_PLAYERS, s.ping < 9e8 and tostring(s.ping) or "?"))
                    badServers[s.index] = true
                    local ok, res = pcall(function() return joinRF:InvokeServer(s.index) end)
                    if not ok then
                        break
                    elseif type(res) == "table" and res.ok == true then
                        task.wait(20)
                    else
                        local why = type(res) == "table" and res.err or "ไม่ทราบสาเหตุ"
                        notify("Server " .. s.index .. " เข้าไม่ได้: " .. tostring(why), "alert-triangle")
                        task.wait(1.5)
                    end
                end
            end
            if alive then pcall(function() TeleportService:Teleport(game.PlaceId, LP) end) end
            task.wait(15)
            hopping = false
        end)
    end
    -- ในเซิร์ฟเกมไม่มี ServerCache: เลขเซิร์ฟต้องอ่านจาก TeleportData.shardIndex / SendShardInfo
    local function setHome(idx)
        idx = tonumber(idx)
        if not idx then return end
        local changed = homeIndex ~= idx
        homeIndex = idx
        saveState({ home = idx, pending = false, t = os.time() })
        if changed then notify("จำเซิร์ฟเดิมไว้แล้ว: Server " .. idx) end
    end
    local function trackHome()
        pcall(function()
            local d = TeleportService:GetLocalPlayerTeleportData()
            if type(d) == "table" then setHome(d.shardIndex) end
        end)
        local function bind(ev)
            if ev:IsA("RemoteEvent") then track(ev.OnClientEvent:Connect(setHome)) end
        end
        local shardEv = RS:FindFirstChild("SendShardInfo")
        if shardEv then bind(shardEv) end
        track(RS.ChildAdded:Connect(function(c)
            if c.Name == "SendShardInfo" then bind(c) end
        end))
        task.delay(12, function()
            local st = loadState()
            local pending = st and st.pending and os.time() - (tonumber(st.t) or 0) < 600
            if alive and not homeIndex and not pending and not getMM() then
                notify("จับเลข Server ไม่ได้ ออกไปเข้าใหม่ผ่านหน้าเลือกเซิร์ฟ", "alert-triangle")
            end
        end)
        task.spawn(function()
            while alive do
                local st = loadState()
                local pendingFresh = st and st.pending and os.time() - (tonumber(st.t) or 0) < 600
                if not hopping and not pendingFresh and GuiService:GetErrorMessage() == "" then
                    pcall(function()
                        for _, s in ipairs(readShards()) do
                            if s.mine then
                                if homeIndex ~= s.index then
                                    homeIndex = s.index
                                    saveState({ home = homeIndex, pending = false, t = os.time() })
                                end
                                break
                            end
                        end
                    end)
                end
                task.wait(5)
            end
        end)
    end
    -- หลัง Rejoin: ถ้าโดนโยนมาหน้าเลือกเซิร์ฟ (ยังไม่ได้อยู่ในเซิร์ฟใดเลย) ให้เลือกเซิร์ฟเข้าให้เอง
    local function autoPickAfterRejoin()
        task.spawn(function()
            local st = loadState()
            if not (cfg.rejoin and st) then return end
            -- pending = หลุดจากการ hop | ไม่ pending = ออกเกมเองแล้วเข้าใหม่ (กลับเซิร์ฟที่จำไว้ ถ้าเปิด sameServer)
            local pending = st.pending and os.time() - (tonumber(st.t) or 0) < 600
            if not pending and not (cfg.sameServer and tonumber(st.home)) then return end
            homeIndex = tonumber(st.home) or homeIndex
            local joinRF
            local t0 = os.clock()
            while alive and os.clock() - t0 < (pending and 60 or 15) do
                local mm = getMM()
                joinRF = mm and mm:FindFirstChild("RequestJoinByIndex")
                if joinRF then break end
                task.wait(1)
            end
            if not joinRF then
                if pending then notify("ไม่เจอ RequestJoinByIndex เลือกเซิร์ฟเองด้วยมือ", "alert-triangle") end
                return
            end
            local delay = pending and math.max(0, tonumber(cfg.pickDelay) or 60) or 5
            local left = delay - (os.clock() - t0)
            for i = math.ceil(left), 1, -1 do
                if not alive or not cfg.rejoin then return end
                setStatus(((cfg.sameServer and homeIndex) and "รอ %d วิ แล้วกลับเซิร์ฟเดิม" or "รอ %d วิ แล้วเลือกเซิร์ฟคนน้อยสุด"):format(i))
                task.wait(1)
            end
            local wantHome = cfg.sameServer and homeIndex ~= nil
            local homeDeadline = os.clock() + math.max(0, tonumber(cfg.homeWait) or 180)
            local homeFails, tries = 0, 0
            while alive and cfg.rejoin and tries < 20 do
                local shards = readShards()
                local joined = false
                -- ครั้งแรกตอนออกเกมเอง ServerCache อาจยังค้างชื่อเราในเซิร์ฟเก่า ไม่นับว่าเข้าแล้ว
                if pending or tries > 0 then
                    for _, s in ipairs(shards) do
                        if s.mine then
                            saveState({ home = s.index, pending = false, t = os.time() })
                            joined = true
                            break
                        end
                    end
                end
                if joined then return end
                local target, waitHome
                if wantHome then
                    for _, s in ipairs(shards) do
                        if s.index == homeIndex and s.online and s.playing < MAX_PLAYERS then
                            target = s
                            break
                        end
                    end
                    if not target then
                        if os.clock() < homeDeadline then
                            waitHome = true
                        else
                            wantHome = false
                            notify("Server " .. homeIndex .. " ยังไม่กลับมา/เต็ม ไปเซิร์ฟคนน้อยสุดแทน", "alert-triangle")
                        end
                    end
                end
                if waitHome then
                    setStatus(("รอ Server %d กลับมาออนไลน์ (เหลือ %d วิ)"):format(
                        homeIndex, math.max(0, math.ceil(homeDeadline - os.clock()))))
                    task.wait(3)
                else
                    local isHome = target ~= nil
                    if not target then
                        local pool = {}
                        for _, s in ipairs(shards) do
                            if s.online and not s.mine and not badServers[s.index] and s.playing < MAX_PLAYERS - 1 then
                                pool[#pool + 1] = s
                            end
                        end
                        table.sort(pool, function(a, b)
                            if a.playing ~= b.playing then return a.playing < b.playing end
                            if a.ping ~= b.ping then return a.ping < b.ping end
                            return a.index < b.index
                        end)
                        target = pool[1]
                    end
                    if not target then
                        task.wait(3)
                    else
                        tries = tries + 1
                        if isHome then
                            notify(("กลับ Server %d เดิม (%d/%d คน)"):format(target.index, target.playing, MAX_PLAYERS))
                        else
                            notify(("เลือก Server %d (%d/%d คน, คนน้อยสุด)"):format(target.index, target.playing, MAX_PLAYERS))
                            badServers[target.index] = true
                        end
                        local ok, res = pcall(function() return joinRF:InvokeServer(target.index) end)
                        if ok and type(res) == "table" and res.ok == true then
                            task.wait(20)
                        else
                            local why = (ok and type(res) == "table" and res.err) or (not ok and tostring(res)) or "ไม่ทราบสาเหตุ"
                            notify("Server " .. target.index .. " เข้าไม่ได้: " .. tostring(why), "alert-triangle")
                            if isHome then
                                homeFails = homeFails + 1
                                if homeFails >= 4 then wantHome = false end
                            end
                            task.wait(2)
                        end
                    end
                end
            end
            saveState({ home = homeIndex, pending = false, t = os.time() })
            notify("เลือกเซิร์ฟให้ไม่สำเร็จ ลองกด Hop Low-Pop Server", "alert-triangle")
        end)
    end
    local function setupRejoin()
        task.spawn(function()
            local ok, overlay = pcall(function()
                return CoreGui:WaitForChild("RobloxPromptGui", 30):WaitForChild("promptOverlay", 30)
            end)
            if ok and overlay then
                track(overlay.ChildAdded:Connect(function(child)
                    if cfg.rejoin and child.Name == "ErrorPrompt" then
                        task.wait(1)
                        hop("หลุดจากเซิร์ฟเวอร์")
                    end
                end))
            end
        end)
        track(GuiService.ErrorMessageChanged:Connect(function()
            if cfg.rejoin and GuiService:GetErrorMessage() ~= "" then
                task.wait(1.5)
                hop("เกิด error: " .. tostring(GuiService:GetErrorMessage()))
            end
        end))
        track(TeleportService.TeleportInitFailed:Connect(function(_, result, msg)
            hopping = false
            if cfg.rejoin then
                notify("วาร์ปกลับเซิร์ฟเดิมไม่ได้: " .. tostring(result) .. " " .. tostring(msg), "alert-triangle")
                task.wait(3)
                hop("วาร์ปล้มเหลว ลองใหม่", true)
            end
        end))
        trackHome()
        autoPickAfterRejoin()
        if not queueSelf() then
            notify("queue_on_teleport ใช้ไม่ได้ ต้องรันสคริปต์เองหลังย้ายเซิร์ฟ", "alert-triangle")
        end
        task.spawn(function()
            while alive do
                task.wait(15)
                if cfg.rejoin and not hopping and os.clock() - lastTp > 60 and disconnected() then
                    hop("ยังหลุดอยู่ ลองใหม่", true)
                end
            end
        end)
    end
    local farmFails, lastToggle, weTurnedOn = 0, 0, false
    local function getAutoRemote()
        local pg = LP:FindFirstChild("PlayerGui")
        local ui = pg and pg:FindFirstChild("AutoUi")
        local fr = ui and ui:FindFirstChild("Frame")
        local bt = fr and fr:FindFirstChild("TextButton")
        local ls = bt and bt:FindFirstChild("LocalScript")
        return ls and ls:FindFirstChild("RemoteEvent")
    end
    local function farmStep()
        local c = LP.Character
        local flag = c and c:FindFirstChild("Auto")
        local remote = getAutoRemote()
        if not (flag and remote) then return end
        local now = os.clock()
        if cfg.farm then
            if flag.Value then
                farmFails = 0
            elseif now - lastToggle > 3 then
                lastToggle = now
                remote:FireServer()
                weTurnedOn = true
                farmFails = farmFails + 1
                if farmFails == 4 then
                    notify("เปิด Auto Farm ไม่ติด: เซิร์ฟเวอร์ไม่ยอมเปิด (อาจต้องอยู่จุดฟาร์ม/มีสิทธิ์ใช้)", "alert-triangle")
                end
            end
        elseif weTurnedOn and flag.Value and now - lastToggle > 1 then
            lastToggle = now
            weTurnedOn = false
            remote:FireServer()
        end
    end
    local function findRemote(name)
        return ReplicatedStorage:FindFirstChild(name) or ReplicatedStorage:FindFirstChild(name, true)
    end
    local FishingEvent, MGStart, MGAttempt, MGFeedback
    local fish = {
        state = "idle", castAt = 0, finishedAt = 0, roundId = nil, speed = 2.2,
        startClock = 0, lastSend = 0, lastCastPos = nil, selfCast = false, timeouts = 0, armId = 0,
    }
    local lastWarn = {}
    local function warnOnce(key, txt, gap)
        local now = os.clock()
        if now - (lastWarn[key] or -1e9) < (gap or 10) then return end
        lastWarn[key] = now
        notify(txt, "alert-triangle")
    end
    local function getFishGui()
        local pg = LP:FindFirstChild("PlayerGui")
        local sys = pg and pg:FindFirstChild("System")
        local mg = sys and sys:FindFirstChild("MINIGAME")
        local f = mg and mg:FindFirstChild("MiniGameFishing")
        local img = f and f:FindFirstChild("ImageLabel")
        if not img then return nil, nil end
        return img:FindFirstChild("dash"), img:FindFirstChild("target")
    end
    local function gameHasAutoFishing()
        local ls = LP:FindFirstChild("leaderstats")
        local af = ls and ls:FindFirstChild("AutoFishing")
        return af ~= nil and (tonumber(af.Value) or 0) > 1
    end
    local function angDiff(from, to) return (to - from + 180) % 360 - 180 end
    local function guiAngle()
        local dash = getFishGui()
        if dash and dash.Parent then return dash.Rotation % 360 end
        return nil
    end
    local function synthAngle()
        return (((os.clock() - fish.startClock) / fish.speed) * 360) % 360
    end
    local function netLead()
        local ok, p = pcall(function() return LP:GetNetworkPing() end)
        p = (ok and tonumber(p)) or 0.06
        return math.clamp(p * 0.5, 0, 0.25)
    end
    local function sendAttempt(id)
        if id ~= fish.armId or fish.state ~= "minigame" or not fish.roundId or not MGAttempt then return end
        local now = os.clock()
        if now - fish.lastSend < 0.1 then return end
        fish.lastSend = now
        MGAttempt:FireServer({ roundId = fish.roundId })
    end
    local hitConn
    local function stopHitter()
        fish.armId = fish.armId + 1
        if hitConn then hitConn:Disconnect(); hitConn = nil end
    end
    local function armHit(targetAngle)
        stopHitter()
        if gameHasAutoFishing() then return end
        local id = fish.armId
        local _, targetGui = getFishGui()
        local target = tonumber(targetAngle)
        if not target and targetGui then target = targetGui.Rotation end
        if not target then return end
        target = target % 360
        local armedAt = os.clock()
        local lastG, still, samples = nil, 0, 0
        local omega = 360 / fish.speed
        local prevTta
        if fish.omegaRound == fish.roundId and fish.omega then
            omega = fish.omega
            samples = 2
        end
        hitConn = RunService.Heartbeat:Connect(function(dt)
            if id ~= fish.armId then return end
            if not alive or not cfg.fish or hopping or fish.state ~= "minigame" then
                stopHitter()
                return
            end
            local g = guiAngle()
            if g and lastG and math.abs(angDiff(lastG, g)) < 0.01 then still = still + 1 else still = 0 end
            local useSynth = (g == nil) or still >= 6
            local ang = useSynth and synthAngle() or g
            if useSynth then
                omega = 360 / fish.speed
            elseif lastG and dt > 0 then
                local inst = angDiff(lastG, g) / dt
                if math.abs(inst) > 5 then
                    omega = (samples == 0) and inst or (omega * 0.7 + inst * 0.3)
                    samples = samples + 1
                end
            end
            lastG = g
            if not useSynth and samples >= 2 then
                fish.omega, fish.omegaRound = omega, fish.roundId
            end
            if not useSynth and samples < 2 then return end
            if os.clock() - armedAt < 0.01 then return end
            local d = angDiff(ang, target)
            local tta
            if omega > 0 then
                tta = (d % 360) / omega
            else
                tta = ((-d) % 360) / (-omega)
            end
            local lead = math.max(netLead() + (tonumber(cfg.fishLead) or 0), dt)
            local crossed = prevTta ~= nil and prevTta <= lead + dt * 2 and tta > prevTta + 0.3
            prevTta = tta
            if tta <= lead or crossed then
                sendAttempt(id)
                stopHitter()
                local rid = fish.roundId
                task.delay(1.2, function()
                    if alive and cfg.fish and fish.state == "minigame"
                        and fish.roundId == rid and fish.armId == id + 1 then
                        armHit(nil)
                    end
                end)
            end
        end)
    end
    local function getBait()
        local item = LP:FindFirstChild("Item")
        if not item and LP:FindFirstChild("Data") then item = LP.Data:FindFirstChild("Item") end
        if not item then return nil end
        local b = item:FindFirstChild("FishingBaitRare")
        return b and (tonumber(b.Value) or 0) or 0
    end
    local function equipRod()
        local c, _, h = getChar()
        if not (c and h) then return false end
        if c:FindFirstChild("FishingRod") then return true end
        local rod = LP:FindFirstChild("Backpack") and LP.Backpack:FindFirstChild("FishingRod")
        if not rod then return false end
        pcall(function() h:EquipTool(rod) end)
        task.wait(0.4)
        return c:FindFirstChild("FishingRod") ~= nil
    end
    local function isWaterPart(p)
        if not p then return false end
        local map = Workspace:FindFirstChild("ALL_MAP")
        local water = map and map:FindFirstChild("Water")
        if water and (p == water or p:IsDescendantOf(water)) then return true end
        return p.Name == "Water" or p.Name == "water_00000"
    end
    local function findCastPos()
        local _, hrp = getChar()
        if not hrp then return nil end
        if fish.lastCastPos and (fish.lastCastPos - hrp.Position).Magnitude <= 240 then
            return fish.lastCastPos
        end
        local map = Workspace:FindFirstChild("ALL_MAP")
        local water = map and map:FindFirstChild("Water")
        local w0 = water and water:FindFirstChild("water_00000")
        local part = w0 and (w0:FindFirstChild("Water") or w0)
        if part and part:IsA("BasePart") then
            local cf, size = part.CFrame, part.Size
            local rel = cf:PointToObjectSpace(hrp.Position)
            local hx, hz = size.X / 2 - 3, size.Z / 2 - 3
            local cx = math.clamp(rel.X, -hx, hx)
            local cz = math.clamp(rel.Z, -hz, hz)
            local guess = cf:PointToWorldSpace(Vector3.new(cx, size.Y / 2, cz))
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = { LP.Character }
            local hit = Workspace:Raycast(guess + Vector3.new(0, 40, 0), Vector3.new(0, -120, 0), params)
            local pos = (hit and isWaterPart(hit.Instance)) and hit.Position or guess
            if (pos - hrp.Position).Magnitude <= 245 then return pos end
        end
        return nil
    end
    local function castNow()
        if not FishingEvent then return end
        local bait = getBait()
        if bait ~= nil and bait <= 0 then
            notify("เหยื่อหมด (FishingBaitRare = 0) หยุด Auto Fishing", "alert-triangle")
            setToggle("fish", false)
            return
        end
        if not equipRod() then
            warnOnce("rod", "ไม่พบ FishingRod ในตัว/กระเป๋า", 8)
            return
        end
        if not cfg.fish then return end
        local pos = findCastPos()
        if not pos then
            warnOnce("pos", "หาจุดน้ำไม่เจอ/ไกลเกิน 250 หน่วย: เดินเข้าใกล้น้ำหรือโยนเองสักครั้ง", 10)
            task.wait(3)
            return
        end
        fish.state = "casting"
        fish.castAt = os.clock()
        fish.selfCast = true
        local ok = pcall(function() FishingEvent:FireServer("StartFishing", pos) end)
        fish.selfCast = false
        if not ok then
            fish.state = "idle"
            fish.finishedAt = os.clock()
        end
    end
    local function resolveRemotes()
        local t0 = os.clock()
        while alive and os.clock() - t0 < 25 do
            FishingEvent = FishingEvent or findRemote("FishingEvent")
            MGStart      = MGStart      or findRemote("MiniGameStart")
            MGAttempt    = MGAttempt    or findRemote("MiniGameAttempt")
            MGFeedback   = MGFeedback   or findRemote("MiniGameFeedback")
            if FishingEvent and MGStart and MGAttempt and MGFeedback then return true end
            task.wait(1)
        end
        return false
    end
    local function setupFishing()
        if not resolveRemotes() then
            if alive then notify("ไม่พบรีโมตตกปลาครบ (อาจไม่ใช่แมพนี้)", "alert-triangle") end
            SW.report("Fishing_RemotesMissing", string.format("FishingEvent=%s MiniGameStart=%s MiniGameAttempt=%s MiniGameFeedback=%s",
                tostring(FishingEvent ~= nil), tostring(MGStart ~= nil), tostring(MGAttempt ~= nil), tostring(MGFeedback ~= nil)))
            return
        end
        ENV.SW_NEVER_FE = FishingEvent
        ENV.SW_NEVER_ONCAST = function(pos)
            if not fish.selfCast then fish.lastCastPos = pos end
        end
        if ENV.SW_NEVER_HOOKED ~= game.JobId and hookmetamethod and newcclosure and getnamecallmethod then
            local ok = pcall(function()
                local old
                old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                    if self == ENV.SW_NEVER_FE and getnamecallmethod() == "FireServer" then
                        local a, b = ...
                        if a == "StartFishing" and typeof(b) == "Vector3" then
                            local f = ENV.SW_NEVER_ONCAST
                            if f then pcall(f, b) end
                        end
                    end
                    return old(self, ...)
                end))
            end)
            if ok then ENV.SW_NEVER_HOOKED = game.JobId end
        end
        track(MGStart.OnClientEvent:Connect(function(a, roundId, targetAngle, speed)
            if a == "STOP_MINIGAME" or a == "FORCE_CLOSE_UI" then
                stopHitter()
                if fish.state == "minigame" then
                    fish.state = "idle"
                    fish.finishedAt = os.clock()
                end
                return
            end
            if roundId == nil then return end
            fish.roundId = roundId
            fish.speed = tonumber(speed) or 2.2
            fish.startClock = os.clock()
            fish.state = "minigame"
            fish.timeouts = 0
            if cfg.fish then
                task.defer(function()
                    if fish.state == "minigame" and fish.roundId == roundId then armHit(targetAngle) end
                end)
            end
        end))
        track(MGFeedback.OnClientEvent:Connect(function(data)
            if typeof(data) ~= "table" or data.roundId ~= fish.roundId then return end
            if data.final ~= nil then
                stopHitter()
                fish.state = "idle"
                fish.finishedAt = os.clock()
                return
            end
            if tonumber(data.speed) then
                fish.speed = tonumber(data.speed)
                fish.omegaRound = nil
            end
            if cfg.fish and fish.state == "minigame" then
                task.defer(function()
                    if fish.state == "minigame" and fish.roundId == data.roundId then
                        armHit(data.targetAngle)
                    end
                end)
            end
        end))
        track(FishingEvent.OnClientEvent:Connect(function(a)
            if a == "FinishFishing" or a == "Canceled" or a == "FORCE_CLOSE_UI" then
                stopHitter()
                fish.state = "idle"
                fish.finishedAt = os.clock()
            elseif a == "NoBait" then
                stopHitter()
                fish.state = "idle"
                fish.finishedAt = os.clock()
                if cfg.fish then
                    setToggle("fish", false)
                    notify("เหยื่อหมด หยุด Auto Fishing", "alert-triangle")
                end
            end
        end))
        track(LP.CharacterAdded:Connect(function()
            stopHitter()
            fish.state = "idle"
            fish.finishedAt = os.clock()
        end))
    end
    local function fishStep()
        if not cfg.fish or hopping then return end
        local _, hrp, h = getChar()
        if not (hrp and h) or h.Health <= 0 then
            if fish.state ~= "idle" then
                stopHitter()
                fish.state = "idle"
                fish.finishedAt = os.clock()
            end
            return
        end
        local now = os.clock()
        if fish.state == "idle" then
            local w = 0.9 + 0.8 * math.min(fish.timeouts, 3)
            if now - fish.finishedAt >= w then castNow() end
        elseif fish.state == "casting" then
            if now - fish.castAt > 40 then
                pcall(function() FishingEvent:FireServer("CancelFishing") end)
                fish.timeouts = fish.timeouts + 1
                if fish.timeouts >= 2 then fish.lastCastPos = nil end
                fish.state = "idle"
                fish.finishedAt = now
            end
        elseif fish.state == "minigame" then
            if now - fish.startClock > 60 then
                stopHitter()
                fish.state = "idle"
                fish.finishedAt = now
            elseif not hitConn and now - fish.startClock > 0.5 and now - fish.lastSend > 1.4 then
                armHit(nil)
            end
        end
    end
    local function addToggle(sec, key, name, tip, onChange)
        toggles[key] = sec:CreateToggle({
            Name = name,
            Tooltip = tip,
            Default = cfg[key],
            Callback = function(s)
                if cfg[key] == s and not onChange then return end
                cfg[key] = s
                if onChange then onChange(s) end
                queueSelf()
            end,
        })
    end
    local function addSlider(sec, key, name, tip, min, max, step, suffix)
        local function cb(v)
            local n = tonumber(type(v) == "table" and (v.Value or v[1]) or v)
            if n then cfg[key] = n; queueSelf() end
        end
        local ok = pcall(function()
            sec:CreateSlider({ Name = name, Tooltip = tip, Min = min, Max = max, Default = cfg[key],
                Increment = step, Suffix = suffix, Callback = cb })
        end)
        if not ok then
            pcall(function()
                sec:CreateSlider({ Name = name, Tooltip = tip, Range = { min, max }, Default = cfg[key],
                    Increment = step, Callback = cb })
            end)
        end
    end
    local Tab = SW.FishTab
    local Fish = Tab:CreateSection({ Name = "Auto Farm / Fishing", Icon = "lucide:fish" })
    addToggle(Fish, "farm", "Auto Farm", "เปิดระบบ Automated Farm ของเกมค้างไว้ (ปุ่ม X ของเกม)")
    addToggle(Fish, "fish", "Auto Fishing", "ตกปลาอัตโนมัติ: โยน รอปลากิน แล้วจับจังหวะมินิเกมให้", function(on)
        if on then stopHitter(); fish.state = "idle"; fish.finishedAt = 0 end
    end)
    addSlider(Fish, "fishLead", "Timing Offset", "ปรับจังหวะยิงมินิเกม (วินาที) บวก = ยิงเร็วขึ้น ลบ = ช้าลง", -0.3, 0.3, 0.01, "s")
    do
        local RS = game:GetService("ReplicatedStorage")
        local PriceSec = Tab:CreateSection({ Name = "Fish Prices (ราคาปลา)", Icon = "lucide:coins" })
        local NOT_FISH = {
            Template = true, MineGold = true, MineIron = true, Gold = true, Iron = true,
            Oreo = true, Candy = true, Taffy = true, Donuts = true, CottonCandy = true,
            Corn = true, Grape = true, Cauliflower = true, Peach = true, Orange = true,
        }
        local FALLBACK = {
            { "WhiteShark", 400, 450 }, { "Hammerheadshark", 330, 360 }, { "Squid", 320, 330 },
            { "Tuna", 300, 320 }, { "Lobster", 90, 95 }, { "Salmon", 81, 85 },
            { "Shrimp", 76, 79 },
        }
        local function getEconomyList()
            local ok, sc = pcall(function()
                return LP.PlayerGui.Iphone.ssr.BGFApp.Economy.Frame.Scrollingitem
            end)
            return ok and sc or nil
        end
        local function scanFish()
            local out, seen = {}, {}
            local function add(name, mn, mx)
                if type(name) ~= "string" or seen[name] or NOT_FISH[name] then return end
                seen[name] = true
                out[#out + 1] = { name, mn, mx }
            end
            local okM, mod = pcall(function() return require(RS.Game_Modules.Selling_Value) end)
            local okI, itemsMod = pcall(function() return require(RS.Game_Modules.Items) end)
            if okM and type(mod) == "table" then
                for name, r in pairs(mod) do
                    if type(r) == "table" and not (okI and type(itemsMod) == "table" and itemsMod[name] == nil) then
                        add(name, tonumber(r.Min) or 0, tonumber(r.Max) or 0)
                    end
                end
            end
            local sc = getEconomyList()
            if sc then
                for _, c in ipairs(sc:GetChildren()) do
                    if c:IsA("Frame") then add(c.Name, 0, 0) end
                end
            end
            if #out == 0 then
                for _, f in ipairs(FALLBACK) do add(f[1], f[2], f[3]) end
            end
            table.sort(out, function(a, b)
                if a[3] ~= b[3] then return a[3] > b[3] end
                return a[1] < b[1]
            end)
            return out
        end
        local function livePrice(name)
            local cp = RS:FindFirstChild("CurrentPrices")
            local v = cp and cp:FindFirstChild(name)
            if v and tonumber(v.Value) then return tonumber(v.Value) end
            local ok, n = pcall(function()
                return tonumber(tostring(getEconomyList()[name].Sell.Text):match("%d+"))
            end)
            return ok and n or nil
        end
        local function ownedOf(name)
            local itemF = LP:FindFirstChild("Item")
            local cv = itemF and itemF:FindFirstChild(name)
            return cv and tonumber(cv.Value) or 0
        end
        local function fishImage(name)
            local ok, img = pcall(function()
                local it = require(RS.Game_Modules.Items)[name]
                if type(it) == "table" and it.image and it.image ~= "" then return it.image end
                local row = getEconomyList()[name]
                local fr = row and row:FindFirstChild("Frame")
                local il = fr and fr:FindFirstChildOfClass("ImageLabel")
                return il and il.Image or nil
            end)
            return ok and img or nil
        end
        local FISH_PRICES = scanFish()
        local fishSig = ""
        local function signature(list)
            local t = {}
            for _, f in ipairs(list) do t[#t + 1] = f[1] .. ":" .. f[2] .. "-" .. f[3] end
            return table.concat(t, ",")
        end
        fishSig = signature(FISH_PRICES)
        local priceP
        local function buildPrices()
            local lines, total = {}, 0
            for _, f in ipairs(FISH_PRICES) do
                local live, n = livePrice(f[1]), ownedOf(f[1])
                total = total + n * (live or f[2])
                local range = (f[3] > 0) and ("  (" .. SW.fmt(f[2]) .. "-" .. SW.fmt(f[3]) .. ")") or ""
                lines[#lines + 1] = ("%s  %s%s%s"):format(
                    f[1],
                    live and (SW.fmt(live) .. "$") or "?",
                    range,
                    n > 0 and ("  ×" .. n) or ""
                )
            end
            lines[#lines + 1] = ("ปลาที่ถืออยู่รวม ≈ %s$"):format(SW.fmt(total))
            return table.concat(lines, "\n")
        end
        local fishGrid
        local function buildGrid()
            local items = {}
            for _, f in ipairs(FISH_PRICES) do
                local live = livePrice(f[1])
                items[#items + 1] = {
                    Name = f[1] .. (live and ("  " .. SW.fmt(live) .. "$") or ""),
                    Amount = ownedOf(f[1]),
                    Image = fishImage(f[1]),
                }
            end
            fishGrid:SetItems(items)
        end
        local function refreshAll()
            if not priceP then return end
            local ok, txt = pcall(buildPrices)
            if ok then pcall(priceP.Set, priceP, nil, txt) end
            if fishGrid then pcall(buildGrid) end
        end
        local okB, firstText = pcall(buildPrices)
        priceP = PriceSec:CreateParagraph({
            Title = "ราคาขายตอนนี้ • อัปเดตอัตโนมัติ",
            Content = okB and firstText or "กำลังโหลดราคา...",
        })
        pcall(function()
            fishGrid = PriceSec:CreateItemGrid({ Empty = "ไม่พบรายชื่อปลา", Callback = function() end })
            buildGrid()
        end)
        PriceSec:CreateButton({
            Name = "Refresh Prices",
            Icon = "lucide:refresh-cw",
            Tooltip = "สแกนรายชื่อปลา ราคา และจำนวนที่ถืออยู่ใหม่ (ปกติอัปเดตเองอยู่แล้ว)",
            Callback = function()
                FISH_PRICES = scanFish()
                fishSig = signature(FISH_PRICES)
                refreshAll()
            end,
        })
        local dirty, hooked = false, {}
        local function markDirty()
            if dirty then return end
            dirty = true
            task.delay(0.15, function()
                dirty = false
                if alive then refreshAll() end
            end)
        end
        local function hookValue(v)
            if v and not hooked[v] and v:IsA("ValueBase") then
                hooked[v] = true
                t_insert(conns, v:GetPropertyChangedSignal("Value"):Connect(markDirty))
            end
        end
        local function hookFolder(folder)
            if not folder or hooked[folder] then return end
            hooked[folder] = true
            for _, c in ipairs(folder:GetChildren()) do hookValue(c) end
            t_insert(conns, folder.ChildAdded:Connect(function(c)
                hookValue(c)
                markDirty()
            end))
            t_insert(conns, folder.ChildRemoved:Connect(markDirty))
        end
        local function hookPrices()
            hookFolder(RS:FindFirstChild("CurrentPrices"))
            hookFolder(LP:FindFirstChild("Item"))
        end
        hookPrices()
        refreshAll()
        task.spawn(function()
            while alive do
                task.wait(3)
                hookPrices()
                local list = scanFish()
                local sig = signature(list)
                if sig ~= fishSig then
                    FISH_PRICES, fishSig = list, sig
                end
                markDirty()
            end
        end)
    end
    SW.BuildServer = function()
        local Rej = SW.ServerTab:CreateSection({ Name = "Auto Rejoin", Icon = "lucide:refresh-cw" })
        addToggle(Rej, "rejoin", "Auto Rejoin", "หลุด/โดนเตะ แล้วเข้าเซิร์ฟใหม่อัตโนมัติ (ต้องรันสคริปต์ใหม่เองหลังย้าย)")
        addToggle(Rej, "sameServer", "Rejoin Same Server", "หลุดแล้วกลับเซิร์ฟเดิม (ถ้าเต็ม/ปิด/เข้าไม่ได้ ค่อยย้ายไปเซิร์ฟคนน้อย)")
        addToggle(Rej, "preferLowPing", "Prefer Low Ping", "เลือกเซิร์ฟที่ ping ต่ำก่อน")
        addSlider(Rej, "maxPlayersTarget", "Target Players", "เป้าหมายจำนวนผู้เล่นในเซิร์ฟที่จะย้ายไป", 1, 20, 1, "")
        Rej:CreateButton({
            Name = "Hop Low-Pop Server",
            Icon = "lucide:shuffle",
            Tooltip = "ย้ายไปเซิร์ฟคนน้อยตอนนี้",
            Callback = function() hop("ย้ายเซิร์ฟตามสั่ง", true) end,
        })
        statusP = Rej:CreateParagraph({ Title = "Status", Content = "พร้อมใช้งาน" })
    end
    setupRejoin()
    task.spawn(setupFishing)
    task.spawn(function()
        while alive do
            pcall(farmStep)
            pcall(fishStep)
            task.wait(0.25)
        end
    end)
    ENV.SW_NEVER_STOP = function()
        alive = false
        pcall(stopHitter)
        ENV.SW_NEVER_ONCAST = nil
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    end
    pcall(function() Window:OnDestroy(ENV.SW_NEVER_STOP) end)
end
SW.addSlider = function(sec, name, tip, min, max, step, suffix, default, onChange)
    local function cb(v)
        local n = tonumber(type(v) == "table" and (v.Value or v[1]) or v)
        if n then onChange(n) end
    end
    local ok = pcall(function()
        sec:CreateSlider({ Name = name, Tooltip = tip, Min = min, Max = max, Default = default, Increment = step, Suffix = suffix, Callback = cb })
    end)
    if not ok then
        pcall(function()
            sec:CreateSlider({ Name = name, Tooltip = tip, Range = { min, max }, Default = default, Increment = step, Callback = cb })
        end)
    end
end
SW.LoadEat = function()
    local RS = game:GetService("ReplicatedStorage")
    local PG = LP:WaitForChild("PlayerGui")
    local function walk(root, path)
        local cur = root
        for _, n in ipairs(path) do cur = cur and cur:FindFirstChild(n) end
        return cur
    end
    local ItemFolder, Bag, holdVal, delayVal, ShopEvent
    local function resolveEat()
        ItemFolder = LP:FindFirstChild("Item")
        Bag = walk(RS, { "RemoteEvent_Solf", "RemoteEventA", "Bag" })
        holdVal = walk(PG, { "Backpack_Never", "Check", "hold" }) or walk(PG, { "Backpack_Never", "BG", "Check", "hold" })
        delayVal = walk(PG, { "Backpack_Never", "Check", "delay" }) or walk(PG, { "Backpack_Never", "BG", "Check", "delay" })
        ShopEvent = RS:FindFirstChild("ShopEvent")
        return (ItemFolder and Bag and holdVal and delayVal) and true or false
    end
    resolveEat()
    local function liveVal(name)
        return setmetatable({}, { __index = function(_, k)
            if k ~= "Value" then return nil end
            local ds = LP:FindFirstChild("DataStats")
            local o = ds and ds:FindFirstChild(name)
            return o and o.Value or 0
        end })
    end
    local HungerVal, ThirstVal = liveVal("HungerVal"), liveVal("ThirstVal")
    local FOODS = {
        { "Onigiri", 20, 500 },
        { "Cake", nil, 650 },
        { "Ramen", 50 },
        { "Curry", 50 },
        { "Watermelon", 50 },
    }
    local DRINKS = {
        { "Water", 20, 500 },
        { "OrangeJuice", 75 },
        { "Ice", 100 },
        { "Watermelon", 50 },
    }
    local CFGE = {
        Interval = 5,
        UseWait = 1.5,
        BuyWait = 2,
        Prices = { Onigiri = 500, Water = 500, Cake = 650 },
    }
    local shopToken, shopHooked = nil, false
    local function hookShop()
        if shopHooked or not ShopEvent then return end
        shopHooked = true
        ShopEvent.OnClientEvent:Connect(function(action, data, token)
            if action == "SetupShop" then
                shopToken = token
                if type(data) == "table" then
                    for name, v in pairs(data) do
                        if type(v) == "table" and v.Price then CFGE.Prices[name] = v.Price end
                    end
                end
            elseif action == "UpdateToken" then
                shopToken = data
            end
        end)
    end
    hookShop()
    local function getCount(itemName)
        if not ItemFolder then return 0 end
        local v = ItemFolder:FindFirstChild(itemName)
        return v and (tonumber(v.Value) or 0) or 0
    end
    local function useItem(itemName)
        local c = LP.Character
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        local animator = hum and hum:FindFirstChildOfClass("Animator")
        local base = {}
        if animator then
            for _, tr in ipairs(animator:GetPlayingAnimationTracks()) do base[tr] = true end
        end
        if not (Bag and holdVal and delayVal) then resolveEat() end
        if not (Bag and holdVal and delayVal) then
            SW.report("AutoEat_NoRemote", "eat remote not found")
            return
        end
        Bag:FireServer("Use", itemName, holdVal, delayVal)
        task.wait(CFGE.UseWait)
        local t0 = os.clock()
        while animator and os.clock() - t0 < 6 do
            local active = false
            for _, tr in ipairs(animator:GetPlayingAnimationTracks()) do
                if not base[tr] and (not tr.Looped or tr.Priority.Value >= Enum.AnimationPriority.Action.Value) then
                    active = true
                    break
                end
            end
            if not active then break end
            task.wait(0.15)
        end
        task.wait(0.4)
    end
    local function tryOpenShop()
        local gui = PG:FindFirstChild("Shop.Never")
        if not gui then return end
        gui.Visible = true
        local t = os.clock()
        while not shopToken and (os.clock() - t) < 5 do
            task.wait(0.2)
        end
        gui.Visible = false
    end
    local function buyItem(itemName, count)
        if not ShopEvent then return false end
        if not shopToken then tryOpenShop() end
        if not shopToken then return false end
        local price = CFGE.Prices[itemName]
        if not price then return false end
        ShopEvent:FireServer("Buy", { [itemName] = { Count = count, Price = price } }, false, shopToken)
        task.wait(CFGE.BuyWait)
        return true
    end
    local busy = false
    local function serve(st, once)
        while busy do
            task.wait(0.2)
        end
        busy = true
        LP:SetAttribute("FarmPaused", true)
        do
            local w0 = os.clock()
            while LP:GetAttribute("FarmBusy") and os.clock() - w0 < 6 do task.wait(0.1) end
            task.wait(0.3)
        end
        local ok, err = pcall(function()
            -- กิน/ดื่มแค่ 1 ชิ้นต่อรอบ แล้วรอตรวจใหม่ตาม Check Interval ว่าค่าลดลงถึงเกณฑ์อีกไหม
            local target = math.huge
            local uses, stuck = 0, 0
            while (once or st.on) do
                local cur = st.val.Value
                if not once and cur >= target then break end
                if uses >= 40 then break end -- กันวนไม่รู้จบ
                if getCount(st.item) <= 0 then
                    if not st.buy then
                        SW.Notify({ Title = "Auto Eat", Icon = "alert-triangle", Content = st.item .. " หมด (Auto Buy ปิดอยู่)", Duration = 4 })
                        st.cool = os.clock() + 30
                        break
                    end
                    if CFGE.Prices[st.item] == nil then
                        SW.Notify({ Title = "Auto Eat", Icon = "alert-triangle", Content = st.item .. " ซื้อไม่ได้ในร้านค้า (ต้องคราฟ)", Duration = 5 })
                        st.cool = os.clock() + 30
                        break
                    end
                    if not buyItem(st.item, st.amount) or getCount(st.item) <= 0 then
                        SW.Notify({ Title = "Auto Eat", Icon = "alert-triangle", Content = "ซื้อ " .. st.item .. " ไม่ได้ (ไม่มีขาย / ไม่มีเงิน / ยังไม่เจอร้าน)", Duration = 5 })
                        st.cool = os.clock() + 30
                        break
                    end
                end
                useItem(st.item)
                uses = uses + 1
                if true then break end -- 1 ชิ้นพอ
                -- รอให้ค่าเพิ่มขึ้นจริง (เซิร์ฟเวอร์อัปเดตช้าได้) แล้วค่อยตัดสินว่าจะกินต่อไหม
                local w1 = os.clock()
                while st.val.Value <= cur and os.clock() - w1 < 4 do task.wait(0.2) end
                if st.val.Value <= cur then
                    stuck = stuck + 1
                    -- ค่าไม่ขึ้น 2 รอบติด = เต็มแล้ว/กินไม่เข้า พักไม่วนซ้ำ
                    if stuck >= 2 then
                        st.cool = os.clock() + 15
                        break
                    end
                else
                    stuck = 0
                    task.wait(0.3)
                end
            end
        end)
        busy = false
        LP:SetAttribute("FarmPaused", false)
        if not ok then SW.report("AutoEat_" .. st.kind, err) end
    end
    local function startLoop(st)
        st.run = st.run + 1
        local myId = st.run
        task.spawn(function()
            while st.on and st.run == myId do
                if LP.Character and os.clock() >= st.cool and st.val.Value <= st.at then serve(st) end
                task.wait(m_max(1, CFGE.Interval))
            end
        end)
    end
    local function setPara(p, text)
        if p then pcall(p.Set, p, nil, text) end
    end
    local addSlider = SW.addSlider
    local iconCache = {}
    local function pickImage(root)
        if not root then return nil end
        if (root:IsA("ImageLabel") or root:IsA("ImageButton")) and root.Image ~= "" then return root.Image end
        local img = root:FindFirstChild("ItemImage")
        if img and (img:IsA("ImageLabel") or img:IsA("ImageButton")) and img.Image ~= "" then return img.Image end
        local any = root:FindFirstChildWhichIsA("ImageLabel", true) or root:FindFirstChildWhichIsA("ImageButton", true)
        if any and any.Image ~= "" then return any.Image end
        return nil
    end
    local function iconFor(itemName)
        local cached = iconCache[itemName]
        if cached then return cached end
        local found
        pcall(function()
            local bp = walk(PG, { "Backpack_Never", "BG", "item", "Scrollingitem" })
            found = pickImage(bp and bp:FindFirstChild(itemName))
        end)
        if not found then
            pcall(function()
                local shop = PG:FindFirstChild("Shop.Never")
                if not shop then return end
                for _, d in ipairs(shop:GetDescendants()) do
                    if d.Name == itemName and d:IsA("GuiObject") then
                        found = pickImage(d)
                        if found then return end
                    end
                end
            end)
        end
        if not found then
            pcall(function()
                for _, root in ipairs({ LP:FindFirstChild("Backpack"), game:GetService("StarterPack"), RS }) do
                    local tool = root and root:FindFirstChild(itemName, true)
                    if tool and tool:IsA("Tool") and tool.TextureId ~= "" then
                        found = tool.TextureId
                        return
                    end
                end
            end)
        end
        if found then iconCache[itemName] = found end
        return found
    end
    local function labelOf(e)
        local s = e[1]
        if e[2] then s = s .. "  (+" .. e[2] .. ")" end
        s = s .. (e[3] and ("  |  ซื้อได้ " .. e[3] .. ".-") or "  |  ซื้อไม่ได้ (คราฟ)")
        return s
    end
    local function buildKind(kind, secName, icon, catalog, val, valName, thaiAct)
        local st = { kind = kind, val = val, item = nil, on = false, at = 30, upto = 100, buy = true, amount = 5, run = 0, cool = 0 }
        local sec = SW.EatTab:CreateSection({ Name = secName, Icon = icon })
        local byLabel, labelByItem = {}, {}
        for _, e in ipairs(catalog) do
            local lb = labelOf(e)
            byLabel[lb] = e[1]
            labelByItem[e[1]] = lb
        end
        local function makeOptions()
            local opts = {}
            for _, e in ipairs(catalog) do
                local lb = labelByItem[e[1]]
                local img = iconFor(e[1])
                t_insert(opts, img and { Name = lb, Image = img } or lb)
            end
            return opts
        end
        local toggle
        local dd = sec:CreateDropdown({
            Name = "Select " .. (kind == "food" and "Food" or "Drink"),
            Placeholder = "เลือก" .. (kind == "food" and "อาหาร" or "น้ำ"),
            Tooltip = "ของที่จะใช้ " .. thaiAct .. " (+ค่าที่เพิ่ม | ซื้อในร้านได้ หรือต้องคราฟ)",
            Options = makeOptions(),
            Callback = function(option)
                if not option then return end
                local key = optionKey(option)
                st.item = byLabel[key] or st.item
                st.cool = 0
            end,
        })
        task.spawn(function()
            for _ = 1, 12 do
                local missing, gained = 0, false
                for _, e in ipairs(catalog) do
                    if not iconCache[e[1]] then
                        if iconFor(e[1]) then gained = true else missing = missing + 1 end
                    end
                end
                if gained and dd then
                    pcall(function() dd:Refresh(makeOptions(), false) end)
                    if st.item and labelByItem[st.item] then
                        pcall(function() dd:Set(labelByItem[st.item]) end)
                    end
                end
                if missing == 0 or not SW.alive then return end
                task.wait(4)
            end
        end)
        addSlider(sec, thaiAct .. "เมื่อ " .. valName .. " ≤", "ค่า " .. valName .. " ที่ต่ำกว่านี้ถึงจะเริ่ม" .. thaiAct, 0, 100, 1, "", st.at, function(n)
            st.at = n
        end)
        sec:CreateToggle({
            Name = "Auto Buy",
            Tooltip = "ของหมดแล้วซื้อจากร้านให้เอง (ซื้อให้เฉพาะของที่ซื้อในร้านได้ ของที่ต้องคราฟจะข้าม)",
            Default = true,
            Callback = function(s) st.buy = s end,
        })
        addSlider(sec, "Buy Amount", "ซื้อกี่ชิ้นต่อครั้ง", 1, 20, 1, "", st.amount, function(n)
            st.amount = m_floor(n)
        end)
        local para = sec:CreateParagraph({ Title = "Status", Content = "รอเลือก" })
        sec:CreateButton({
            Name = "Use Now",
            Icon = "lucide:utensils",
            Tooltip = "ใช้ 1 ชิ้นตอนนี้เลย (ไม่สนค่าที่ตั้งไว้)",
            Callback = function()
                if not st.item then
                    SW.denySound()
                    SW.Notify({ Title = "เลือกก่อน", Icon = "lock", Content = "ยังไม่ได้เลือกของใน dropdown", Duration = 3 })
                    return
                end
                task.spawn(serve, st, true)
            end,
        })
        toggle = sec:CreateToggle({
            Name = "Auto " .. (kind == "food" and "Eat" or "Drink"),
            Tooltip = "เปิดแล้ว" .. thaiAct .. "ให้อัตโนมัติตามค่าที่ตั้งไว้",
            Default = false,
            Callback = function(state)
                if state and not st.item then
                    st.on = false
                    task.spawn(function()
                        pcall(function() toggle:Set(false) end)
                    end)
                    SW.denySound()
                    SW.Notify({ Title = "เปิดไม่ได้", Icon = "lock", Content = "เลือก" .. (kind == "food" and "อาหาร" or "น้ำ") .. "ใน dropdown ก่อนเปิด", Duration = 4 })
                    return
                end
                st.on = state
                if state then
                    st.cool = 0
                    startLoop(st)
                else
                    st.run = st.run + 1
                end
            end,
        })
        st.para = para
        return st
    end
    local food = buildKind("food", "Food (อาหาร)", "lucide:utensils", FOODS, HungerVal, "Hunger", "กิน")
    local drink = buildKind("drink", "Drink (น้ำ)", "lucide:cup-soda", DRINKS, ThirstVal, "Thirst", "ดื่ม")
    local gen = SW.EatTab:CreateSection({ Name = "General", Icon = "lucide:settings-2" })
    addSlider(gen, "Check Interval", "ตรวจค่า Hunger/Thirst ทุกกี่วินาที", 1, 30, 1, "s", CFGE.Interval, function(n)
        CFGE.Interval = n
    end)
    task.spawn(function()
        local t0, reported = os.clock(), false
        while SW.alive and os.clock() - t0 < 180 do
            local ok = resolveEat()
            hookShop()
            if ok and ShopEvent then break end
            if not ok and not reported and os.clock() - t0 > 8 then
                reported = true
                local miss = {}
                for k, v in pairs({ Item = ItemFolder, Bag = Bag, hold = holdVal, delay = delayVal }) do
                    if not v then miss[#miss + 1] = k end
                end
                local ds = LP:FindFirstChild("DataStats")
                if not (ds and ds:FindFirstChild("HungerVal")) then miss[#miss + 1] = "HungerVal" end
                if not (ds and ds:FindFirstChild("ThirstVal")) then miss[#miss + 1] = "ThirstVal" end
                local msg = table.concat(miss, ", ")
                SW.report("AutoEat_Missing", "หาไม่เจอ: " .. msg)
            end
            task.wait(2)
        end
    end)
    task.spawn(function()
        local last = {}
        while SW.alive do
            for _, st in ipairs({ food, drink }) do
                local txt
                if st.item then
                    local canBuy = CFGE.Prices[st.item] ~= nil
                    txt = ("%s %d  |  %s ×%d  |  %s  |  %s"):format(st.kind == "food" and "Hunger" or "Thirst", m_floor(st.val.Value), st.item, getCount(st.item), canBuy and "ซื้อได้" or "ซื้อไม่ได้ (คราฟ)", st.on and "ON" or "OFF")
                else
                    txt = ("%s %d  |  ยังไม่ได้เลือก"):format(st.kind == "food" and "Hunger" or "Thirst", m_floor(st.val.Value))
                end
                if last[st] ~= txt then
                    last[st] = txt
                    setPara(st.para, txt)
                end
            end
            task.wait(1)
        end
    end)
end
SW.LoadCandy = function()
    local RS = game:GetService("ReplicatedStorage")
    local function liveRemote(name)
        return { FireServer = function(_, ...)
            local gv = RS:FindFirstChild("Grow_vegetables")
            local r = gv and gv:FindFirstChild(name)
            if not r then
                SW.report("CandyFarm_NoRemote", name)
                return
            end
            r:FireServer(...)
        end }
    end
    local PlantRemote = liveRemote("PlantTreeEvent")
    local WaterRemote = liveRemote("GiveWater")
    local FertRemote = liveRemote("GiveFertilizer")
    local ItemFolder = { FindFirstChild = function(_, n)
        local f = LP:FindFirstChild("Item")
        return f and f:FindFirstChild(n)
    end }
    task.spawn(function()
        local t0 = os.clock()
        while SW.alive and os.clock() - t0 < 8 do
            local gv = RS:FindFirstChild("Grow_vegetables")
            if gv and gv:FindFirstChild("PlantTreeEvent") and gv:FindFirstChild("GiveWater")
                and gv:FindFirstChild("GiveFertilizer") and LP:FindFirstChild("Item") then
                return
            end
            task.wait(1)
        end
        if not SW.alive then return end
        local gv = RS:FindFirstChild("Grow_vegetables")
        local function has(name) return tostring(gv ~= nil and gv:FindFirstChild(name) ~= nil) end
        local msg = string.format("Grow_vegetables=%s Plant=%s Water=%s Fert=%s Item=%s",
            tostring(gv ~= nil), has("PlantTreeEvent"), has("GiveWater"), has("GiveFertilizer"), tostring(LP:FindFirstChild("Item") ~= nil))
        SW.report("CandyFarm_Missing", msg)
    end)
    local BAG = "FertilizerBag"
    -- fertCount เก็บลงไฟล์ ไม่งั้นย้ายเซิร์ฟแล้ว ENV ถูกล้าง นับปุ๋ยใหม่จาก 0 แล้วใส่ซ้ำ
    local FERT_KEY = "fert_" .. LP.UserId
    local function saveFert()
        ENV.SpectreNT_Store.set(FERT_KEY, ENV.SW_CandyFertCount)
    end
    if type(ENV.SW_CandyFertCount) ~= "table" then
        local d = ENV.SpectreNT_Store.get(FERT_KEY)
        ENV.SW_CandyFertCount = type(d) == "table" and d or {}
    end
    local S = {
        on = false,
        run = 0,
        seed = nil,
        target = 5,
        spacing = 4,
        spaceFails = 0,
        anchor = nil,
        anchorManual = false,
        lastGood = nil,
        recovered = false,
        plant = true,
        water = true,
        fert = true,
        collect = true,
        waterAt = 95, -- ต้นที่ยังไม่โต: รดบ่อย
        fertCount = ENV.SW_CandyFertCount,
        gain = 50,
        fertTimes = 2,
        bad = {},
        waterSkip = setmetatable({}, { __mode = "k" }),
        fertSkip = setmetatable({}, { __mode = "k" }),
        bagWarnAt = 0,
        plantLog = {},
        fails = 0,
        coolUntil = 0,
        lastCollect = setmetatable({}, { __mode = "k" }),
        cycleRun = -1,
        holdBag = false,
        needBagEquip = false,
        holdSeed = false,
        needEquip = true,
        needEquipOld = false,
        badPts = {},
        known = {},
    }
    local function live() return S.on and SW.alive and S.run == S.cycleRun end
    S.stat = { planted = 0, failed = 0, watered = 0, fert = 0, collected = 0 }
    S.logs = {}
    S.phase = "-"
    S.log = function(msg)
        t_insert(S.logs, os.date("%H:%M:%S") .. "  " .. tostring(msg))
        if #S.logs > 8 then table.remove(S.logs, 1) end
    end
    local statusP
    local lastStatus = ""
    local function setStatus(t)
        t = tostring(t)
        if t == lastStatus then return end
        lastStatus = t
        S.phase = t
        if statusP then pcall(statusP.Set, statusP, nil, t) end
    end
    local function pauseGate()
        local t0, waited = os.clock(), false
        if not LP:GetAttribute("FarmPaused") then S.pausedFrom = nil end
        while live() and LP:GetAttribute("FarmPaused") and os.clock() - t0 < 30 do
            S.pausedFrom = S.pausedFrom or os.clock()
            if os.clock() - S.pausedFrom > 90 then
                LP:SetAttribute("FarmPaused", false)
                S.pausedFrom = nil
                S.log("FarmPaused ค้างเกิน 90 วิ ปลดให้แล้ว")
                break
            end
            waited = true
            setStatus("รอ Auto Eat...")
            task.wait(0.2)
        end
        if waited then task.wait(0.5) end
    end
    local function getCount(name)
        local v = ItemFolder:FindFirstChild(name)
        if not v then
            local d = LP:FindFirstChild("Data")
            local f = d and d:FindFirstChild("Item")
            v = f and f:FindFirstChild(name)
        end
        return v and (tonumber(v.Value) or 0) or 0
    end
    local function getChar()
        local c = LP.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if not (c and hrp and h) or h.Health <= 0 then return nil end
        return c, hrp, h
    end
    local ownFolderCache
    local function ownFolder()
        if ownFolderCache and ownFolderCache.Parent then return ownFolderCache end
        local all = workspace:FindFirstChild("AllPlantedTrees")
        if not all then return nil end
        local f = all:FindFirstChild("PlantedTrees_" .. LP.UserId)
        if not f then
            local uid = tostring(LP.UserId)
            for _, c in ipairs(all:GetChildren()) do
                if c.Name:find(uid, 1, true) then
                    f = c
                    break
                end
            end
        end
        ownFolderCache = f
        return f
    end
    local function deepTrees(f)
        local list, seen = {}, {}
        for _, d in ipairs(f:GetDescendants()) do
            if d.Name == "Stats" and not d:IsA("BasePart") then
                local t = d.Parent
                if t and t ~= f and not seen[t] then
                    seen[t] = true
                    t_insert(list, t)
                end
            end
        end
        return list
    end
    local function ownTrees()
        local list = {}
        local f = ownFolder()
        if f then
            for _, t in ipairs(f:GetChildren()) do
                if t:IsA("Model") and t:FindFirstChild("Stats") then t_insert(list, t) end
            end
            if #list == 0 then list = deepTrees(f) end
        end
        return list
    end
    local function statOf(tree, name)
        local st = tree:FindFirstChild("Stats")
        local v = st and st:FindFirstChild(name)
        return v and (tonumber(v.Value) or 0) or 0
    end
    local function flat(a, b)
        return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
    end
    local PathfindingService = game:GetService("PathfindingService")
    local function pathTo(pos, h, hrp, budget)
        local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true })
        local ok = pcall(path.ComputeAsync, path, hrp.Position, pos)
        if not (ok and path.Status == Enum.PathStatus.Success) then return false end
        local t0 = os.clock()
        for _, wp in ipairs(path:GetWaypoints()) do
            if not live() or os.clock() - t0 > budget then return false end
            if wp.Action == Enum.PathWaypointAction.Jump and not S.planting then h.Jump = true end
            h:MoveTo(wp.Position)
            local w = os.clock()
            while live() and os.clock() - w < 1.5 do
                local _, r = getChar()
                if not r or flat(r.Position, wp.Position) < 3 then break end
                task.wait(0.05)
            end
        end
        return true
    end
    local function walkNear(pos, dist, timeout)
        local t0 = os.clock()
        local lastPos, lastMove = nil, os.clock()
        local stuck = 0
        while live() and os.clock() - t0 < (timeout or 15) do
            local _, hrp, h = getChar()
            if not hrp then return false end
            if LP:GetAttribute("FarmPaused") then
                h:MoveTo(hrp.Position)
                local w = os.clock()
                pauseGate()
                t0 = t0 + (os.clock() - w)
                lastPos, lastMove = nil, os.clock()
                continue
            end
            if flat(hrp.Position, pos) <= dist then return true end
            if not lastPos or flat(hrp.Position, lastPos) >= 0.4 then
                lastPos, lastMove = hrp.Position, os.clock()
            elseif os.clock() - lastMove > 1.5 then
                if not S.collecting then
                    if not S.planting then h.Jump = true end
                    stuck = stuck + 1
                    if stuck >= 2 then
                        stuck = 0
                        pathTo(pos, h, hrp, 8)
                        lastPos = nil
                    end
                end
                lastMove = os.clock()
            end
            h:MoveTo(Vector3.new(pos.X, hrp.Position.Y, pos.Z))
            task.wait(0.15)
        end
        return false
    end
    local function waitStill(timeout)
        local t0 = os.clock()
        local since
        while live() and os.clock() - t0 < (timeout or 3) do
            local _, hrp, h = getChar()
            if not hrp then return false end
            local v = hrp.AssemblyLinearVelocity
            if Vector3.new(v.X, 0, v.Z).Magnitude > 0.3 or h.MoveDirection.Magnitude > 0.01 then
                since = nil
            else
                since = since or os.clock()
                if os.clock() - since >= 0.3 then return true end
            end
            task.wait(0.05)
        end
        return false
    end
    local function norm(s) return (tostring(s):lower():gsub("[%s_%-]", "")) end
    S.seedRank = function(t)
        if not (t and t:IsA("Tool")) then return 0 end
        if t:GetAttribute("ServerCandyPlantingTool") then return 3 end
        local n = norm(t.Name)
        local hasSeedWord = n:find("seed", 1, true) or n:find("เมล็ด", 1, true) or n:find("sapling", 1, true)
        if hasSeedWord and (n:find("candy", 1, true) or n:find("แคนดี้", 1, true) or n:find("ลูกอม", 1, true)) then return 2 end
        local okA, attrs = pcall(t.GetAttributes, t)
        if okA and type(attrs) == "table" then
            for k in pairs(attrs) do
                local kn = norm(k)
                if kn:find("plant", 1, true) and kn:find("candy", 1, true) then return 2 end
            end
        end
        if hasSeedWord then return 1 end
        return 0
    end
    S.isSeedTool = function(t) return S.seedRank(t) > 0 end
    S.itemFolders = function()
        local list = {}
        local a = LP:FindFirstChild("Item")
        if a then t_insert(list, a) end
        local d = LP:FindFirstChild("Data")
        local b = d and d:FindFirstChild("Item")
        if b and b ~= a then t_insert(list, b) end
        return list
    end
    S.seedNames = function()
        local cand, seen = {}, {}
        local function add(n, rank)
            if n and not seen[n] then
                seen[n] = true
                t_insert(cand, { n = n, r = rank, i = #cand })
            end
        end
        for _, holder in ipairs({ LP.Character, LP:FindFirstChild("Backpack") }) do
            if holder then
                for _, t in ipairs(holder:GetChildren()) do
                    local r = S.seedRank(t)
                    if r > 0 then add(t.Name, r) end
                end
            end
        end
        for _, item in ipairs(S.itemFolders()) do
            for _, v in ipairs(item:GetChildren()) do
                local n = norm(v.Name)
                local hasSeedWord = n:find("seed", 1, true) or n:find("เมล็ด", 1, true)
                if hasSeedWord and (n:find("candy", 1, true) or n:find("แคนดี้", 1, true)) then
                    add(v.Name, 2)
                elseif hasSeedWord then
                    add(v.Name, 1)
                end
            end
        end
        add("SeedCandy", 0)
        t_sort(cand, function(a, b)
            if a.r ~= b.r then return a.r > b.r end
            return a.i < b.i
        end)
        local names = {}
        for _, c in ipairs(cand) do t_insert(names, c.n) end
        return names
    end
    S.dumpSeedy = function()
        local out = {}
        for _, holder in ipairs({ LP.Character, LP:FindFirstChild("Backpack") }) do
            if holder then
                for _, t in ipairs(holder:GetChildren()) do
                    if t:IsA("Tool") then t_insert(out, "T:" .. t.Name) end
                end
            end
        end
        for _, item in ipairs(S.itemFolders()) do
            for _, v in ipairs(item:GetChildren()) do
                local n = norm(v.Name)
                if n:find("seed", 1, true) or n:find("candy", 1, true) or n:find("เมล็ด", 1, true) then
                    t_insert(out, "I:" .. v.Name .. "=" .. tostring(v.Value))
                end
            end
        end
        if #out > 14 then
            for i = #out, 15, -1 do table.remove(out, i) end
        end
        return #out > 0 and table.concat(out, ", ") or "ไม่มีอะไรเลย"
    end
    local function findTool(name)
        local holders = { LP.Character, LP:FindFirstChild("Backpack") }
        for _, holder in ipairs(holders) do
            local t = holder and holder:FindFirstChild(name)
            if t and t:IsA("Tool") then return t end
        end
        local want = norm(name)
        local seedLike = want:find("seed", 1, true) ~= nil
        for _, holder in ipairs(holders) do
            if holder then
                for _, t in ipairs(holder:GetChildren()) do
                    if t:IsA("Tool") then
                        local tn = norm(t.Name)
                        if tn == want or tn:find(want, 1, true) or (seedLike and S.isSeedTool(t)) then
                            return t
                        end
                    end
                end
            end
        end
        return nil
    end
    -- เมล็ด/ของอยู่ใน LP.Item (ไม่ใช่ Tool) เกมสร้าง Tool ให้เมื่อส่ง Bag:FireServer("Use", ชื่อ, hold, delay)
    local lastUse = {}
    local lastBagWarn = -m_huge
    local function requestToolFromBag(name)
        if getCount(name) <= 0 then return false end
        if lastUse[name] and os.clock() - lastUse[name] < 1.5 then return false end
        local okR, Bag = pcall(function()
            return game:GetService("ReplicatedStorage").RemoteEvent_Solf.RemoteEventA.Bag
        end)
        local pg = LP:FindFirstChild("PlayerGui")
        local bn = pg and pg:FindFirstChild("Backpack_Never")
        local chk = bn and (bn:FindFirstChild("Check") or (bn:FindFirstChild("BG") and bn.BG:FindFirstChild("Check")))
        local hold = chk and chk:FindFirstChild("hold")
        local dly = chk and chk:FindFirstChild("delay")
        if not (okR and Bag and hold and dly) then
            if os.clock() - lastBagWarn > 20 then
                lastBagWarn = os.clock()
                SW.report("CandyFarm_BagRemote", ("Bag=%s hold=%s delay=%s"):format(tostring(okR and Bag ~= nil), tostring(hold ~= nil), tostring(dly ~= nil)))
            end
            return false
        end
        lastUse[name] = os.clock()
        pcall(function() Bag:FireServer("Use", name, hold, dly) end)
        return true
    end
    local function equip(name, patience)
        pauseGate()
        local c = getChar()
        if not c then return nil end
        local t = findTool(name)
        if t then lastUse[name] = nil end -- มี Tool อยู่แล้ว: รอบหน้าถ้า Tool หายให้ขอใหม่ได้ทันที
        if not t then requestToolFromBag(name) end
        local w0 = os.clock()
        while not t and live() and os.clock() - w0 < (patience or 0) do
            task.wait(0.15)
            t = findTool(name)
            if not t then requestToolFromBag(name) end
        end
        if not t then return nil end
        lastUse[name] = nil
        if t.Parent == c then return t end
        for _ = 1, 3 do
            local _, _, h2 = getChar()
            if not h2 then return nil end
            pcall(h2.EquipTool, h2, t)
            local t0 = os.clock()
            while os.clock() - t0 < 1.2 and t.Parent ~= c do
                task.wait(0.05)
            end
            if t.Parent == c then break end
            t = findTool(name) or t
        end
        task.wait(0.15)
        return t.Parent == c and t or nil
    end
    S.release = function(which)
        local c = getChar()
        if not c then return false end
        local held
        for _, t in ipairs(c:GetChildren()) do
            if t:IsA("Tool") then
                local isBag = norm(t.Name) == norm(BAG)
                local isSeed = not isBag and S.isSeedTool(t)
                if (which == "seed" and isSeed) or (which == "bag" and isBag) or (not which and (isSeed or isBag)) then
                    held = t
                    break
                end
            end
        end
        if not held then return false end
        pauseGate()
        for _ = 1, 3 do
            local _, _, h = getChar()
            if not h then return false end
            pcall(h.UnequipTools, h)
            local t0 = os.clock()
            while os.clock() - t0 < 0.8 and held.Parent == c do
                task.wait(0.05)
            end
            if held.Parent ~= c then break end
        end
        if held.Parent ~= c then
            S.log("เลิกถือ " .. held.Name)
            return true
        end
        return false
    end
    local function treePos(tree)
        local prop = tree:FindFirstChild("PROP")
        local part = prop and prop:FindFirstChild("Part")
        if not (part and part:IsA("BasePart")) then part = SW.treePart(tree) end
        if part then return part.Position end
        local ok, cf = pcall(tree.GetPivot, tree)
        return ok and cf and cf.Position or nil
    end
    local function treeKey(tree)
        local p = treePos(tree)
        if not p then return tree end
        return m_floor(p.X + 0.5) .. "," .. m_floor(p.Z + 0.5)
    end
    local function fertOf(tree) return S.fertCount[treeKey(tree)] or 0 end
    S.snap = function(stat)
        local snap = {}
        for _, t in ipairs(ownTrees()) do snap[treeKey(t)] = statOf(t, stat) end
        return snap
    end
    S.hitTree = function(snap, stat, minDelta)
        local best, bd = nil, minDelta or 0.5
        for _, t in ipairs(ownTrees()) do
            local k = treeKey(t)
            if snap[k] then
                local d = statOf(t, stat) - snap[k]
                if d >= bd then best, bd = t, d end
            end
        end
        return best
    end
    local function rememberTrees(trees)
        for _, t in ipairs(trees) do
            local p = treePos(t)
            if p then
                local k = treeKey(t)
                -- ต้นโตแล้วตำแหน่งขยับ key เปลี่ยน -> ลบรายการเก่าที่อยู่ใกล้ ไม่ให้นับเป็นต้นหาย
                for key, info in pairs(S.known) do
                    if key ~= k and flat(info.pos, p) < 3 then S.known[key] = nil end
                end
                S.known[k] = { pos = p, misses = 0, grown = statOf(t, "Growth") >= 100 }
            end
        end
    end
    local function missingKeys(trees)
        local miss = {}
        for key, info in pairs(S.known) do
            local found = false
            for _, t in ipairs(trees) do
                local tp = treePos(t)
                if tp and flat(tp, info.pos) < 3 then
                    found = true
                    break
                end
            end
            if not found then t_insert(miss, key) end
        end
        return miss
    end
    local function recoverMissing(trees)
        local miss = missingKeys(trees)
        -- ต้นที่โตเต็มแล้วหายไป = ถูกเก็บแล้ว ไม่ต้องเดินกลับไป
        for i = #miss, 1, -1 do
            local info = S.known[miss[i]]
            if info and info.grown then
                S.known[miss[i]] = nil
                table.remove(miss, i)
            end
        end
        if #miss == 0 then return false end
        task.wait(1.5)
        if not live() then return true end
        miss = missingKeys(ownTrees())
        if #miss == 0 then return false end
        local info = S.known[miss[1]]
        if not info then return false end
        -- เดินกลับเฉพาะตอนอยู่ไกลจริง (ต้นอาจถูก stream ออก) ถ้าอยู่ใกล้แล้วยังไม่เจอ ให้ลืมไปเลย
        local _, hrpNow = getChar()
        local far = hrpNow and flat(hrpNow.Position, info.pos) > 25
        if not far or info.misses >= 3 then
            S.known[miss[1]] = nil
            return false
        end
        info.misses = info.misses + 1
        setStatus(("หาต้นแคนดี้ไม่เจอ เดินกลับไปที่เดิม (ครั้งที่ %d/3)"):format(info.misses))
        walkNear(info.pos, 8, 15)
        task.wait(1)
        return true
    end
    local function allTreeCount()
        local f, n = ownFolder(), 0
        if f then
            for _, t in ipairs(f:GetChildren()) do
                if t:IsA("Model") then n = n + 1 end
            end
            if n == 0 then n = #deepTrees(f) end
        end
        return n
    end
    local function nearestTree(from, skip)
        local all = workspace:FindFirstChild("AllPlantedTrees")
        if not all then return nil end
        local best, bd
        for _, folder in ipairs(all:GetChildren()) do
            for _, t in ipairs(folder:GetChildren()) do
                if t ~= skip then
                    local p = treePos(t)
                    if p then
                        local d = (p - from).Magnitude
                        if not bd or d < bd then best, bd = t, d end
                    end
                end
            end
        end
        return best, bd
    end
    local function standBy(tree, timeout)
        local t0 = os.clock()
        local lastPos, lastMove, rot = nil, os.clock(), 0
        local blockedAtCenter = false
        while live() and tree.Parent and os.clock() - t0 < (timeout or 12) do
            local _, hrp, h = getChar()
            if not hrp then return false end
            if LP:GetAttribute("FarmPaused") then
                h:MoveTo(hrp.Position)
                local w = os.clock()
                pauseGate()
                t0 = t0 + (os.clock() - w)
                lastPos, lastMove = nil, os.clock()
                continue
            end
            local tp = treePos(tree)
            if not tp then return false end
            local dc = flat(hrp.Position, tp)
            -- ยืนกลางต้น: เข้าไปอยู่ที่จุดกึ่งกลางต้น (ใกล้ไม่เกิน 1.0) ถือว่าถึง
            -- ถ้าต้นขวางจนเข้าไม่ถึง (ติดเกิน 1.2 วิ) ยอมรับระยะเดิม 4.6 เป็นทางสำรอง
            if dc <= 1.0 and nearestTree(hrp.Position) == tree then return true end
            if blockedAtCenter and dc <= 4.6 and nearestTree(hrp.Position) == tree then return true end
            if not lastPos or flat(hrp.Position, lastPos) >= 0.4 then
                lastPos, lastMove = hrp.Position, os.clock()
            elseif os.clock() - lastMove > 1.2 then
                if dc <= 4.6 then
                    blockedAtCenter = true
                else
                    if not S.collecting then h.Jump = true end
                    rot = rot + 1
                end
                lastMove = os.clock()
            end
            if blockedAtCenter then
                -- สำรอง: ยืนชิดต้นด้านที่เราอยู่ (หรือฝั่งตรงข้ามต้นข้างเคียง)
                local other = nearestTree(tp, tree)
                local op = other and treePos(other)
                local dir
                if op and flat(tp, op) < 9 then
                    dir = Vector3.new(tp.X - op.X, 0, tp.Z - op.Z)
                else
                    dir = Vector3.new(hrp.Position.X - tp.X, 0, hrp.Position.Z - tp.Z)
                end
                dir = dir.Magnitude > 0.1 and dir.Unit or Vector3.new(1, 0, 0)
                h:MoveTo(Vector3.new(tp.X, hrp.Position.Y, tp.Z) + dir * 1.2)
            else
                local dir = Vector3.new(hrp.Position.X - tp.X, 0, hrp.Position.Z - tp.Z)
                dir = dir.Magnitude > 0.1 and dir.Unit or Vector3.new(1, 0, 0)
                if rot > 0 then dir = CFrame.Angles(0, rot * math.pi / 2, 0):VectorToWorldSpace(dir) end
                -- เส้นทางเข้ากลางต้น: ถ้า rot>0 (ติดตอนยังไกล) อ้อมไปเข้าอีกด้านก่อน
                local aim = rot > 0 and (Vector3.new(tp.X, hrp.Position.Y, tp.Z) + dir * 3) or Vector3.new(tp.X, hrp.Position.Y, tp.Z)
                h:MoveTo(aim)
            end
            task.wait(0.1)
        end
        return false
    end
    S.confirmNear = function(tree)
        for _ = 1, 2 do
            local _, hrp = getChar()
            if not (hrp and tree.Parent) then return false end
            local tp = treePos(tree)
            if not tp or flat(hrp.Position, tp) > 6 or nearestTree(hrp.Position) ~= tree then return false end
            task.wait(0.08)
        end
        return true
    end
    S.collectTries = {}
    S.beingSince = setmetatable({}, { __mode = "k" })
    S.collectBusy = function()
        local now = os.clock()
        if S.collecting then
            if now - (S.collectingAt or now) < 45 then return true end
            S.collecting = false -- ค้างเกิน 45 วิ ถือว่าเก็บจบไปแล้ว
        end
        if now < (S.noPlantUntil or 0) then return true end
        for _, t in ipairs(ownTrees()) do
            local k = treeKey(t)
            if t:GetAttribute("BeingCollected") then
                local since = S.beingSince[t]
                if not since then
                    since = now
                    S.beingSince[t] = since
                end
                -- เซิร์ฟเวอร์บางทีค้างแฟลก BeingCollected ไว้ ไม่ให้บล็อกเกิน 12 วิ
                if now - since < 12 and now >= (S.ignoreBeing or 0) then return true end
            else
                S.beingSince[t] = nil
            end
            if S.collect and statOf(t, "Growth") >= 100 then
                if (S.collectTries[k] or 0) < 3 then return true end
            else
                S.collectTries[k] = nil
            end
        end
        return false
    end
    local function collectTree(tree)
        if os.clock() - (S.lastCollect[tree] or 0) < 6 then return end
        S.lastCollect[tree] = os.clock()
        local tk = treeKey(tree)
        S.collectTries[tk] = (S.collectTries[tk] or 0) + 1
        S.collecting, S.collectingAt = true, os.clock()
        local ok, err = pcall(S.collectInner, tree)
        S.collecting = false
        if not ok then SW.report("CollectTree", err) end
    end
    S.collectInner = function(tree)
        if not standBy(tree, 15) then return end
        do
            local _, hr, hh = getChar()
            if hh and hr then hh:MoveTo(hr.Position) end
        end
        waitStill(2)
        local function findPrompt()
            local first
            for _, d in ipairs(tree:GetDescendants()) do
                if d:IsA("ProximityPrompt") then
                    if d.Enabled then return d end
                    first = first or d
                end
            end
            return first
        end
        local prompt = findPrompt()
        local pw = os.clock()
        while not prompt and live() and tree.Parent and os.clock() - pw < 3 do
            task.wait(0.3)
            prompt = findPrompt()
        end
        if not prompt then
            SW.report("CandyFarm_NoPrompt", tree.Name)
            return
        end
        if not fireproximityprompt then
            SW.report("CandyFarm_NoFireProximityPrompt", "executor lacks fireproximityprompt")
            return
        end
        pauseGate()
        setStatus("เก็บ " .. tree.Name)
        local ck = treeKey(tree)
        pcall(fireproximityprompt, prompt)
        S.stat.collected = S.stat.collected + 1
        S.log("เก็บผล " .. tree.Name)
        local w0 = os.clock()
        while os.clock() - w0 < 5 and tree.Parent and statOf(tree, "Growth") >= 100 do
            task.wait(0.2)
        end
        local b0 = os.clock()
        while live() and tree.Parent and tree:GetAttribute("BeingCollected") and os.clock() - b0 < 8 do
            task.wait(0.2)
        end
        S.collectTries[ck] = nil
        S.noPlantUntil = os.clock() + 2
        S.fertCount[ck] = nil
        saveFert()
        S.known[ck] = nil
        task.wait(0.5)
    end
    S.panic = 25
    local function isFull(v) return v >= 99 end
    -- ต้นที่โตเต็มแล้ว (Growth >= 100) ไม่ต้องรดน้ำ รอเก็บอย่างเดียว
    local function isGrown(tree) return statOf(tree, "Growth") >= 100 end
    local function waterTree(tree)
        if not standBy(tree, 12) then
            S.waterSkip[tree] = os.clock() + 5
            return
        end
        local tries, stall = 0, 0
        while live() and S.water and tree.Parent and not isGrown(tree) and not isFull(statOf(tree, "Water")) and tries < 40 do
            waitStill(2)
            local _, hrp = getChar()
            if not hrp then return end
            if nearestTree(hrp.Position) ~= tree and not standBy(tree, 6) then
                S.waterSkip[tree] = os.clock() + 5
                return
            end
            local before = statOf(tree, "Water")
            if isFull(before) then break end
            setStatus("รดน้ำ " .. tree.Name .. " " .. m_floor(before) .. "%")
            pauseGate()
            if isFull(statOf(tree, "Water")) then break end
            if not S.confirmNear(tree) then
                if not standBy(tree, 6) then
                    S.waterSkip[tree] = os.clock() + 5
                    return
                end
                waitStill(1)
            end
            LP:SetAttribute("FarmBusy", true)
            local snap = S.snap("Water")
            WaterRemote:FireServer(tree)
            tries = tries + 1
            local hit
            local w0 = os.clock()
            while live() and tree.Parent and not hit and os.clock() - w0 < 2 do
                hit = S.hitTree(snap, "Water", 0.5)
                if not hit then task.wait(0.1) end
            end
            LP:SetAttribute("FarmBusy", false)
            local onTarget = (hit and treeKey(hit) == treeKey(tree)) or statOf(tree, "Water") > before
            if onTarget then
                stall = 0
                S.stat.watered = S.stat.watered + 1
                if isFull(statOf(tree, "Water")) then S.log("รดน้ำ " .. tree.Name .. " เต็มแล้ว") end
                task.wait(0.4)
            else
                stall = stall + 1
                if hit then
                    S.log("รดโดนต้นอื่น ยืนใหม่")
                    standBy(tree, 4)
                end
                if stall >= 3 then
                    S.waterSkip[tree] = os.clock() + 8
                    break
                end
            end
        end
    end
    local function fertEnough(tree)
        local food = statOf(tree, "Food")
        if food >= 99.5 or fertOf(tree) >= S.fertTimes then return true end
        return (100 - food) < S.gain * 0.4
    end
    local function hasBag() return getCount(BAG) > 0 or findTool(BAG) ~= nil end
    local function needHold() return S.holdBag or S.needBagEquip end
    local function fertTree(tree)
        if not hasBag() then
            if os.clock() > S.bagWarnAt then
                SW.Notify({ Title = "Candy Farm", Icon = "alert-triangle", Content = "ปุ๋ย (FertilizerBag) หมด", Duration = 4 })
                S.bagWarnAt = os.clock() + 30
            end
            S.fertSkip[tree] = os.clock() + 30
            return
        end
        if not standBy(tree, 12) or (needHold() and not equip(BAG, 2)) then
            S.fertSkip[tree] = os.clock() + 10
            return
        end
        local function shoot()
            local snap = S.snap("Food")
            setStatus(("ใส่ปุ๋ย %s %d%% (ครั้งที่ %d/%d)"):format(tree.Name, m_floor(snap[treeKey(tree)] or 0), fertOf(tree) + 1, S.fertTimes))
            LP:SetAttribute("FarmBusy", true)
            FertRemote:FireServer()
            task.wait(2.2)
            LP:SetAttribute("FarmBusy", false)
            local hit
            local w0 = os.clock()
            while live() and not hit and os.clock() - w0 < 1.5 do
                hit = S.hitTree(snap, "Food", 0.5)
                if not hit then task.wait(0.1) end
            end
            if hit then
                task.wait(0.15)
                hit = S.hitTree(snap, "Food", 0.5) or hit
            end
            return hit, snap
        end
        local tries, stall = 0, 0
        while live() and S.fert and tree.Parent and not fertEnough(tree) and tries < 12 and hasBag() do
            waitStill(2)
            local _, hrp = getChar()
            if not hrp then return end
            if nearestTree(hrp.Position) ~= tree and not standBy(tree, 6) then
                S.fertSkip[tree] = os.clock() + 10
                return
            end
            pauseGate()
            if not S.confirmNear(tree) then
                if not standBy(tree, 6) then
                    S.fertSkip[tree] = os.clock() + 10
                    return
                end
                waitStill(1)
            end
            if needHold() and not equip(BAG, 2) then
                S.fertSkip[tree] = os.clock() + 10
                return
            end
            local hit, snap = shoot()
            if not hit and not needHold() and live() and findTool(BAG) then
                if equip(BAG, 2) then
                    local h2, s2 = shoot()
                    if h2 then
                        hit, snap = h2, s2
                        S.needBagEquip = true
                        SW.Notify({ Title = "Candy Farm", Icon = "info", Content = "เกมต้องถือถุงปุ๋ยถึงจะใส่ได้ สลับไปถือให้อัตโนมัติแล้ว", Duration = 5 })
                    end
                end
            end
            tries = tries + 1
            if hit then
                stall = 0
                local hk = treeKey(hit)
                local after = statOf(hit, "Food")
                if after < 99.5 and after - snap[hk] >= 5 then S.gain = after - snap[hk] end
                S.fertCount[hk] = (S.fertCount[hk] or 0) + 1
                saveFert()
                S.stat.fert = S.stat.fert + 1
                S.log(("ปุ๋ย %s → %d%%"):format(hit.Name, m_floor(after)))
                if hk ~= treeKey(tree) then
                    standBy(tree, 4)
                end
            else
                stall = stall + 1
                if stall == 1 then
                    standBy(tree, 4)
                elseif stall >= 3 then
                    S.fertSkip[tree] = os.clock() + 20
                    break
                end
            end
        end
    end
    local function hasSeed(name)
        return name ~= nil and (getCount(name) > 0 or findTool(name) ~= nil)
    end
    local function findSeed()
        if S.seed and hasSeed(S.seed) then return S.seed end
        local names = S.seedNames()
        for _, n in ipairs(names) do
            if hasSeed(n) then return n end
        end
        return nil
    end
    local function autoAnchor()
        if S.anchorManual and S.anchor then return end
        local sum, n = Vector3.new(), 0
        for _, t in ipairs(ownTrees()) do
            local tp = treePos(t)
            if tp then
                sum = sum + tp
                n = n + 1
            end
        end
        if n > 0 then
            S.anchor = sum / n
            S.lastCenter = S.anchor
        else
            local _, hrp = getChar()
            if S.lastCenter and (not hrp or flat(hrp.Position, S.lastCenter) < 80) then
                S.anchor = S.lastCenter
            elseif hrp then
                S.anchor = hrp.Position
            end
        end
        S.bad = {}
    end
    S.allPts = function()
        local pts = {}
        local all = workspace:FindFirstChild("AllPlantedTrees")
        if all then
            -- ไล่ทุกระดับ: ต้นที่ซ้อนอยู่ลึกกว่าโฟลเดอร์ชั้นเดียว (กรณี deepTrees) ต้องนับเป็นสิ่งกีดขวางด้วย
            for _, t in ipairs(all:GetDescendants()) do
                if t:IsA("Model") then
                    local par = t.Parent
                    if (par and par.Parent == all) or t:FindFirstChild("Stats") then
                        local p = treePos(t)
                        if p then t_insert(pts, p) end
                        local okp, cf = pcall(t.GetPivot, t)
                        if okp and cf and (not p or flat(cf.Position, p) > 1.5) then t_insert(pts, cf.Position) end
                    end
                end
            end
        end
        for _, info in pairs(S.known) do
            if info.pos then t_insert(pts, info.pos) end
        end
        local pl, now = S.placed, os.clock()
        if pl then
            for i = #pl, 1, -1 do
                if now - pl[i].t > 25 then
                    table.remove(pl, i)
                else
                    t_insert(pts, pl[i].pos)
                end
            end
        end
        return pts
    end
    S.isBadPt = function(pos)
        local now = os.clock()
        for i = #S.badPts, 1, -1 do
            local b = S.badPts[i]
            if now - b.t > 150 then
                table.remove(S.badPts, i)
            elseif (b.pos.X - pos.X) ^ 2 + (b.pos.Z - pos.Z) ^ 2 < 2.5 ^ 2 then
                return true
            end
        end
        return false
    end
    -- เช็คจากชิ้นส่วนจริงใน AllPlantedTrees (ทุกคน ทุกระดับ) ว่ามีต้นอยู่ตรงจุดนี้ไหม
    -- ไม่พึ่งพิกัดจาก treePos อย่างเดียว: ถ้ารายการพิกัดตกหล่น/เพี้ยน จุดที่ปลูกไปแล้วจะถูกมองว่าว่าง
    -- below = ลึกลงจาก pos.Y กี่ studs (ใช้ค่ามากเมื่อ pos.Y คือความสูงตัวละคร ไม่ใช่พื้น)
    S.occHalf = 1.0
    S.physHits, S.physLogAt = 0, 0
    S.occupied = function(pos, below)
        local apt = workspace:FindFirstChild("AllPlantedTrees")
        if not apt then return false end
        local op = S.occParams
        if not op then
            op = OverlapParams.new()
            op.FilterType = Enum.RaycastFilterType.Include
            op.MaxParts = 4
            S.occParams = op
        end
        op.FilterDescendantsInstances = { apt }
        below = below or 0.6
        local h = 3 + below
        local ok, parts = pcall(workspace.GetPartBoundsInBox, workspace,
            CFrame.new(pos.X, pos.Y + (3 - below) / 2, pos.Z), Vector3.new(S.occHalf * 2, h, S.occHalf * 2), op)
        if not (ok and parts and #parts > 0) then return false end
        S.physHits = S.physHits + 1
        if os.clock() - S.physLogAt > 8 then
            S.physLogAt = os.clock()
            S.log(("ข้ามจุดที่มีต้นอยู่แล้ว (เช็คจากชิ้นส่วนจริง) x%d | %s"):format(S.physHits, parts[1]:GetFullName():sub(-60)))
        end
        return true
    end
    S.groundAt = function(x, z, refY, params)
        local ignore = table.clone(params.FilterDescendantsInstances)
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then t_insert(ignore, p.Character) end
        end
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.IgnoreWater = true
        local origin = Vector3.new(x, refY + 8, z)
        for _ = 1, 5 do
            rp.FilterDescendantsInstances = ignore
            local ray = workspace:Raycast(origin, Vector3.new(0, -60, 0), rp)
            if not ray then return nil end
            local inst = ray.Instance
            if inst.CanCollide and inst.Transparency < 0.9 then
                if math.abs(ray.Position.Y - refY) > 10 then return nil end
                return ray
            end
            t_insert(ignore, inst)
        end
        return nil
    end
    S.scanCfg = { radius = 30, step = 2, groundMinY = 0.7, maxTreeDist = 12 }
    -- ระยะห่างขั้นต่ำจริงระหว่างต้น (จุดศูนย์กลางต้น) ใช้ค่าเดียวกันทุกที่ ไม่ให้ scan/เช็คก่อนปลูกขัดกัน
    S.minGap = function() return S.spacing * 0.85 end
    S.scanSpots = function(center, radius, step, trees, relaxed)
        local cfg = S.scanCfg
        local sp = S.spacing
        local minGap = S.minGap()
        local minD2 = minGap ^ 2
        local obs = S.allPts()
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local ignore = { LP.Character }
        local apt = workspace:FindFirstChild("AllPlantedTrees")
        if apt then t_insert(ignore, apt) end
        params.FilterDescendantsInstances = ignore
        local _, hrp = getChar()
        local me = hrp and hrp.Position or center
        local out, seenKey = {}, {}
        local ownPts = {}
        for _, t in ipairs(trees) do
            local tp = treePos(t)
            if tp then t_insert(ownPts, tp) end
        end
        local function consider(x, z, key)
            if seenKey[key] or (S.bad[key] and not relaxed) then return end
            seenKey[key] = true
            local ray = S.groundAt(x, z, center.Y, params)
            if not (ray and ray.Normal.Y >= cfg.groundMinY and (relaxed or not S.isBadPt(ray.Position))) then return end
            local pos = ray.Position
            local nearestAll = math.huge
            for _, o in ipairs(obs) do
                local d2 = (o.X - pos.X) ^ 2 + (o.Z - pos.Z) ^ 2
                if d2 < minD2 then return end -- ทับ/ชิดเกิน ตัดทิ้ง
                if d2 < nearestAll then nearestAll = d2 end
            end
            local nearestOwn = math.huge
            for _, tp in ipairs(ownPts) do
                local d2 = (tp.X - pos.X) ^ 2 + (tp.Z - pos.Z) ^ 2
                if d2 < nearestOwn then nearestOwn = d2 end
            end
            if not relaxed and #ownPts > 0 and nearestOwn > cfg.maxTreeDist ^ 2 then return end
            -- ยิ่งชิดต้นข้างเคียง (แต่ไม่ทับ) ยิ่งดี: โทษตามส่วนที่ห่างเกินระยะห่างที่ตั้งไว้
            local gapPenalty = 0
            if nearestAll < math.huge then
                local nd = math.sqrt(nearestAll)
                if nd > sp * 1.05 then gapPenalty = (nd - sp) * 2.5 end
            end
            t_insert(out, { pos = pos, key = key, score = flat(me, pos) + gapPenalty })
        end
        -- (ก) จุดวงแหวนรอบต้นของเรา ระยะ = spacing พอดี -> ต้นเรียงติดกันแน่นแบบไม่ทับ
        for _, tp in ipairs(ownPts) do
            for i = 0, 23 do
                local a = i * math.pi / 12
                local x, z = tp.X + math.cos(a) * sp, tp.Z + math.sin(a) * sp
                if (x - center.X) ^ 2 + (z - center.Z) ^ 2 <= (radius + 10) ^ 2 then
                    consider(x, z, "r" .. m_floor(x * 2) .. "," .. m_floor(z * 2))
                end
            end
        end
        -- (ข) กริดรอบจุดปลูก (ใช้ตอนยังไม่มีต้น/ไม่มีวงแหวนที่ใช้ได้)
        local n = m_floor(radius / step)
        for ix = -n, n do
            for iz = -n, n do
                local x = center.X + ix * step
                local z = center.Z + iz * step
                consider(x, z, "s" .. m_floor(x) .. "," .. m_floor(z))
            end
        end
        table.sort(out, function(a, b) return a.score < b.score end)
        -- กรองด้วยชิ้นส่วนจริงเฉพาะหัวแถว (เช็คทุกจุดในกริดแพงเกิน) จุดที่มีต้นอยู่ตัดทิ้งและจำว่าไม่ดี
        local clean = {}
        for _, c in ipairs(out) do
            if S.occupied(c.pos) then
                S.bad[c.key] = true
            else
                t_insert(clean, c)
                if #clean >= 8 then break end
            end
        end
        return clean
    end
    -- กริดตายตัว: ทุกช่องห่างกัน spacing พอดี ไม่ทับกันโดยโครงสร้าง เลือกช่องว่างที่ใกล้ตัวที่สุด (เดินน้อยสุด)
    S.latSpot = function(trees)
        local _, hrp = getChar()
        local anchor = S.anchor or (hrp and hrp.Position)
        if not anchor then return nil end
        if #trees == 0 then
            S.latOrigin = anchor
        elseif not S.latOrigin then
            local best, bd
            for _, t in ipairs(trees) do
                local tp = treePos(t)
                if tp then
                    local d = flat(tp, anchor)
                    if not bd or d < bd then best, bd = tp, d end
                end
            end
            S.latOrigin = best or anchor
        end
        local o, sp = S.latOrigin, S.spacing
        local minD2 = S.minGap() ^ 2
        local radius = S.scanCfg.radius
        local me = hrp and hrp.Position or anchor
        local obs = S.allPts()
        local cc, cn = Vector3.new(), 0
        for _, t in ipairs(trees) do
            local tp = treePos(t)
            if tp then cc, cn = cc + tp, cn + 1 end
        end
        cc = cn > 0 and cc / cn or nil
        local n = math.ceil(radius / sp)
        local cand = {}
        for ix = -n, n do
            for iz = -n, n do
                local x, z = o.X + ix * sp, o.Z + iz * sp
                local key = "L" .. ix .. "," .. iz
                if not S.bad[key] and (x - anchor.X) ^ 2 + (z - anchor.Z) ^ 2 <= radius ^ 2 then
                    local free = true
                    for _, p in ipairs(obs) do
                        if (p.X - x) ^ 2 + (p.Z - z) ^ 2 < minD2 then free = false break end
                    end
                    if free then
                        local flatP = v3_new(x, 0, z)
                        t_insert(cand, { x = x, z = z, key = key, score = (cc and flat(cc, flatP) or flat(me, flatP)) + flat(me, flatP) * 0.05 })
                    end
                end
            end
        end
        t_sort(cand, function(a, b) return a.score < b.score end)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local ignore = { LP.Character }
        local apt = workspace:FindFirstChild("AllPlantedTrees")
        if apt then t_insert(ignore, apt) end
        params.FilterDescendantsInstances = ignore
        for i = 1, math.min(#cand, 30) do
            local c = cand[i]
            local ray = S.groundAt(c.x, c.z, anchor.Y, params)
            if ray and ray.Normal.Y >= S.scanCfg.groundMinY and not S.isBadPt(ray.Position) and not S.occupied(ray.Position) then
                return { pos = ray.Position, key = c.key }
            end
            S.bad[c.key] = true
        end
        return nil
    end
    -- ปลูกชิดต้นที่มีอยู่จริง: ช่องข้างต้น (4 ทิศ) ระยะ spacing พอดี เรียงแน่นเป็นกลุ่ม ไม่ทับต้นไหน
    S.nearSpot = function(trees)
        local sp = S.spacing
        local parents = {}
        for _, t in ipairs(trees) do
            local tp = treePos(t)
            if tp then t_insert(parents, tp) end
        end
        for _, pl in ipairs(S.placed or {}) do
            if os.clock() - pl.t <= 25 then t_insert(parents, pl.pos) end
        end
        if #parents == 0 then return nil end
        local _, hrp = getChar()
        local anchor = S.anchor or (hrp and hrp.Position) or parents[1]
        local me = hrp and hrp.Position or anchor
        local sum = Vector3.new()
        for _, tp in ipairs(parents) do sum = sum + tp end
        local center = sum / #parents
        local obs = S.allPts()
        local minD2 = (sp * 0.92) ^ 2
        local cand, seen = {}, {}
        for _, tp in ipairs(parents) do
            for _, dir in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
                local x, z = tp.X + dir[1] * sp, tp.Z + dir[2] * sp
                local key = "N" .. m_floor(x * 2) .. "," .. m_floor(z * 2)
                if not seen[key] and not S.bad[key] then
                    seen[key] = true
                    local free = true
                    for _, o in ipairs(obs) do
                        if (o.X - x) ^ 2 + (o.Z - z) ^ 2 < minD2 then free = false break end
                    end
                    if free then
                        local fp = v3_new(x, 0, z)
                        t_insert(cand, { x = x, z = z, key = key, score = flat(center, fp) + flat(me, fp) * 0.05 })
                    end
                end
            end
        end
        t_sort(cand, function(a, b) return a.score < b.score end)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local ignore = { LP.Character }
        local apt = workspace:FindFirstChild("AllPlantedTrees")
        if apt then t_insert(ignore, apt) end
        params.FilterDescendantsInstances = ignore
        for i = 1, math.min(#cand, 20) do
            local c = cand[i]
            local ray = S.groundAt(c.x, c.z, anchor.Y, params)
            if ray and ray.Normal.Y >= S.scanCfg.groundMinY and not S.isBadPt(ray.Position) and not S.occupied(ray.Position) then
                return { pos = ray.Position, key = c.key }
            end
            S.bad[c.key] = true
        end
        return nil
    end
    local function pickSpot(trees)
        local near = S.nearSpot(trees)
        if near then return near.pos, near.key end
        local lat = S.latSpot(trees)
        if lat then return lat.pos, lat.key end
        local _, hrpNow = getChar()
        local center = S.anchor or (hrpNow and hrpNow.Position)
        if center then
            local list = S.scanSpots(center, S.scanCfg.radius, S.scanCfg.step, trees)
            if list[1] then
                return list[1].pos, list[1].key
            end
            list = S.scanSpots(center, S.scanCfg.radius + 20, S.scanCfg.step, trees, true)
            if list[1] then return list[1].pos, list[1].key end
            if hrpNow and not S.anchorManual and #trees == 0 then
                list = S.scanSpots(hrpNow.Position, 40, S.scanCfg.step, trees, true)
                if list[1] then return list[1].pos, list[1].key end
            end
        end
        local sp = S.spacing
        local obs = S.allPts()
        local function okSpot(pos)
            if S.isBadPt(pos) then return false end
            for _, o in ipairs(obs) do
                if (o.X - pos.X) ^ 2 + (o.Z - pos.Z) ^ 2 < (sp * 0.85) ^ 2 then return false end
            end
            if S.occupied(pos, 4.5) then return false end -- pos.Y ตรงนี้ไม่ใช่ระดับพื้น เลยตรวจลึกลงมา
            return true
        end
        if not S.anchorManual then
            local pts, sum = {}, Vector3.new()
            for _, t in ipairs(trees) do
                local tp = treePos(t)
                if tp then
                    t_insert(pts, tp)
                    sum = sum + tp
                end
            end
            if #pts > 0 then
                local center = sum / #pts
                local best, bestKey, bestScore
                for _, tp in ipairs(pts) do
                    for _, mul in ipairs({ 1, 1.5, 2 }) do
                        for i = 0, 15 do
                            local a = i * math.pi / 8
                            local pos = tp + Vector3.new(math.cos(a) * sp * mul, 0, math.sin(a) * sp * mul)
                            local key = "n" .. m_floor(pos.X / 2) .. "," .. m_floor(pos.Z / 2)
                            if not S.bad[key] and okSpot(pos) then
                                local nd = math.huge
                                for _, o in ipairs(pts) do
                                    local d = Vector3.new(o.X - pos.X, 0, o.Z - pos.Z).Magnitude
                                    if d < nd then nd = d end
                                end
                                if nd >= sp * 0.85 then
                                    local score = (nd - sp) * 1.0 + (pos - center).Magnitude * 0.3
                                    if not bestScore or score < bestScore then
                                        best, bestKey, bestScore = pos, key, score
                                    end
                                end
                            end
                        end
                    end
                end
                if best then return best, bestKey end
            end
        end
        local anchor = S.anchor
        if not anchor then return nil end
        for r = 0, 5 do
            for dx = -r, r do
                for dz = -r, r do
                    if m_max(math.abs(dx), math.abs(dz)) == r then
                        local key = dx .. "," .. dz
                        if not S.bad[key] then
                            local pos = anchor + Vector3.new(dx * sp, 0, dz * sp)
                            local ok = true
                            for _, t in ipairs(trees) do
                                local tp = treePos(t)
                                if tp then
                                    local d = Vector3.new(tp.X - pos.X, 0, tp.Z - pos.Z).Magnitude
                                    if d < sp * 0.85 then
                                        ok = false
                                        break
                                    end
                                end
                            end
                            if ok and okSpot(pos) then return pos, key end
                        end
                    end
                end
            end
        end
        return nil
    end
    -- ตั้งเมล็ดลงสล็อตเองถ้ายังไม่อยู่ในสล็อตไหนเลย (ใช้ CheckSlot ตัวเดียวกับที่ UI กระเป๋าเกมใช้)
    S.autoSlot = true
    S.slotAt = 0
    S.ensureSlot = function(name, force)
        if not S.autoSlot or not name then return end
        if not force and os.clock() - S.slotAt < 30 then return end
        S.slotAt = os.clock()
        local okR, CheckSlot = pcall(function()
            return game:GetService("ReplicatedStorage").RemoteEvent_Solf.RemoteEventA.CheckSlot
        end)
        if not (okR and CheckSlot) then return end
        local okL, data = pcall(function() return CheckSlot:InvokeServer("loadbars") end)
        if not (okL and type(data) == "table") then return end
        local function key(bar, i)
            return bar == 1 and ("Slot" .. i) or ("Bar" .. bar .. "_Slot" .. i)
        end
        local firstEmpty
        for bar = 1, 3 do
            for i = 1, 7 do
                local k = key(bar, i)
                local v = data[k]
                if v == name then return end -- อยู่ในสล็อตแล้ว
                if (type(v) ~= "string" or v == "") and not firstEmpty then firstEmpty = k end
            end
        end
        if not firstEmpty then
            SW.Notify({ Title = "Candy Farm", Icon = "alert-triangle", Content = "สล็อตเต็มทุกช่อง เซ็ตเมล็ดอัตโนมัติไม่ได้", Duration = 5 })
            return
        end
        local okS, res = pcall(function() return CheckSlot:InvokeServer("save", firstEmpty, name, "Solf Town") end)
        if okS and res then
            S.log(("เซ็ต %s ลงสล็อต %s"):format(name, firstEmpty))
            SW.Notify({ Title = "Candy Farm", Icon = "check-circle", Content = ("เซ็ต %s ลงสล็อต %s ให้แล้ว"):format(name, firstEmpty), Duration = 4 })
        else
            S.log("เซ็ตสล็อตไม่สำเร็จ: " .. firstEmpty)
        end
    end
    -- ===== ความแม่นยำตำแหน่งปลูก =====
    -- เรียนรู้ว่าเซิร์ฟเวอร์วางต้นห่างจากตัวเราเท่าไร (หน่วย local ตามทิศที่หัน) แล้วเอามาคำนวณจุดยืน/เช็คทับ
    S.offSamples = {}
    S.plantOff = nil -- Vector3 (object space ของ HRP) ใช้เมื่อค่าที่วัดได้นิ่งพอเท่านั้น
    S.faceDir = Vector3.new(0, 0, -1) -- ถ้ามี offset จะหันทิศนี้ทุกครั้งก่อนปลูก ให้ต้นไปโผล่ที่เดิมเสมอ
    S.learnOffset = function(hrp, at, real)
        if not (hrp and real) then return end
        local d = hrp.CFrame:VectorToObjectSpace(Vector3.new(real.X - at.X, 0, real.Z - at.Z))
        t_insert(S.offSamples, d)
        if #S.offSamples > 6 then table.remove(S.offSamples, 1) end
        if #S.offSamples < 2 then
            S.plantOff = d.Magnitude > 0.8 and d or nil
            return
        end
        local sum = Vector3.new()
        for _, v in ipairs(S.offSamples) do sum = sum + v end
        local mean = sum / #S.offSamples
        for _, v in ipairs(S.offSamples) do
            if (v - mean).Magnitude > 1.2 then
                S.offSamples = { d }
                S.plantOff = d.Magnitude > 0.8 and d or nil
                return
            end
        end
        S.plantOff = mean.Magnitude > 0.8 and mean or nil -- เล็กกว่านี้ถือว่าวางตรงตัวเรา
    end
    -- ต้นจะไปโผล่ตรงไหน ถ้ายิงตอนนี้ (ใช้ทิศที่หันอยู่จริง)
    S.predictTree = function(hrp)
        local at = hrp.Position
        if not S.plantOff then return at end
        local v = hrp.CFrame:VectorToWorldSpace(S.plantOff)
        return Vector3.new(at.X + v.X, at.Y, at.Z + v.Z)
    end
    -- จุดที่ต้องยืน เพื่อให้ต้นไปโผล่ที่ spot พอดี
    S.standFor = function(spot)
        if not S.plantOff then return spot end
        local cf = CFrame.lookAt(spot, spot + S.faceDir)
        local v = cf:VectorToWorldSpace(S.plantOff)
        return Vector3.new(spot.X - v.X, spot.Y, spot.Z - v.Z)
    end
    -- ยืนให้ตรง stand (คลาดไม่เกิน ~0.6) และหันทิศคงที่ถ้ามี offset
    S.settleAt = function(stand)
        local _, hrp, hum = getChar()
        if not hrp then return false end
        if flat(hrp.Position, stand) > 1.5 then
            if not walkNear(stand, 1.2, 5) then return false end
            _, hrp, hum = getChar()
            if not hrp then return false end
        end
        if hum then hum:MoveTo(hrp.Position) end
        if flat(hrp.Position, stand) > 3 then return false end
        local p = Vector3.new(stand.X, hrp.Position.Y, stand.Z)
        local v = hrp.AssemblyLinearVelocity
        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.new(0, v.Y, 0)
            hrp.CFrame = CFrame.lookAt(p, p + S.faceDir)
        end)
        task.wait(0.1)
        return true
    end
    -- ดักแจ้งเตือนของเกม (PlayerGui.Gui.NotificationContainer) ErrorContainer/WarningContainer = เซิร์ฟเวอร์ปฏิเสธ
    S.lastNotif, S.lastReject, S.seenReject = nil, nil, {}
    S.watchNotif = function()
        if S.notifConn or S.notifBusy then return end
        S.notifBusy = true
        local pg = LP:FindFirstChildOfClass("PlayerGui") or LP:WaitForChild("PlayerGui", 10)
        local gui = pg and (pg:FindFirstChild("Gui") or pg:WaitForChild("Gui", 10))
        local box = gui and (gui:FindFirstChild("NotificationContainer") or gui:WaitForChild("NotificationContainer", 10))
        S.notifBusy = false
        if not box then return end
        S.notifConn = box.ChildAdded:Connect(function(child)
            if not SW.alive then
                if S.notifConn then S.notifConn:Disconnect() S.notifConn = nil end
                return
            end
            local n = child:FindFirstChild("Notification")
            local item = n and n:FindFirstChild("Item")
            local head = n and n:FindFirstChild("Header")
            local text = item and item:IsA("TextLabel") and item.Text or ""
            if text == "" and head and head:IsA("TextLabel") then text = head.Text end
            S.lastNotif = { kind = child.Name, text = text, t = os.clock() }
            if child.Name:find("Error") or child.Name:find("Warning") then
                S.log(("เกมแจ้ง [%s]: %s"):format(child.Name, text))
            end
        end)
    end
    S.plantReject = function(since)
        local nt = S.lastNotif
        if nt and nt.t >= since - 0.05 and (nt.kind:find("Error") or nt.kind:find("Warning")) then return nt end
        return nil
    end
    S.hasWord = function(text, words)
        text = tostring(text):lower()
        for _, w in ipairs(words) do
            if text:find(w, 1, true) then return true end
        end
        return false
    end
    local function plantOne(trees)
        if not S.notifConn then task.spawn(S.watchNotif) end
        if not S.seed or not hasSeed(S.seed) then
            local alt = findSeed()
            if alt then
                S.seed = alt
                setStatus("ใช้เมล็ด " .. alt)
            end
        end
        local seed = S.seed
        if not seed then return end
        if not hasSeed(seed) then
            if os.clock() > S.coolUntil then
                SW.Notify({ Title = "Candy Farm", Icon = "alert-triangle", Content = "เมล็ด " .. seed .. " หมด | เจอ: " .. S.dumpSeedy(), Duration = 8 })
                S.coolUntil = os.clock() + 30
            end
            return
        end
        local tStart = os.clock()
        local spot, key = pickSpot(trees)
        if not spot then
            if os.clock() > S.coolUntil then
                SW.Notify({ Title = "Candy Farm", Icon = "alert-triangle", Content = "หาที่ว่างปลูกไม่เจอรอบจุดปลูก (ลองลดระยะห่าง หรือกด Set Plant Point ใหม่)", Duration = 5 })
                S.coolUntil = os.clock() + 5
                S.log("หาที่ว่างไม่เจอ รีเซ็ตจุดแล้วลองใหม่")
                S.bad = {}
                S.badPts = {}
                if not S.anchorManual then
                    S.anchor = nil
                    autoAnchor()
                end
            end
            return
        end
        setStatus("เดินไปจุดปลูก")
        local stand = S.standFor(spot)
        if not walkNear(stand, 1.5, 8) then
            S.bad[key] = true
            S.log("เดินไปจุดปลูกไม่ถึง ข้ามจุด " .. key)
            return
        end
        if #trees > 0 then
            local _, hr = getChar()
            local near = false
            if hr then
                for _, t in ipairs(trees) do
                    local tp = treePos(t)
                    if tp and flat(hr.Position, tp) <= 14 then near = true break end
                end
            end
            if not near then
                S.bad[key] = true
                S.log("ไม่มีต้นเดิมในระยะ 14 ข้ามจุด " .. key)
                return
            end
        end
        local tWalked = os.clock()
        pauseGate()
        task.spawn(S.ensureSlot, seed) -- ไม่บล็อกรอบปลูก เผื่อเซิร์ฟเวอร์ตอบช้า
        local tool, equipped
        if not S.holdSeed and not S.needEquip then tool = findTool(seed) end
        if not tool then
            setStatus("หยิบเมล็ด " .. seed)
            tool = equip(seed, 4)
            equipped = true
        end
        if not tool then
            local names = {}
            local bp = LP:FindFirstChild("Backpack")
            for _, holder in ipairs({ LP.Character, bp }) do
                if holder then
                    for _, t in ipairs(holder:GetChildren()) do
                        if t:IsA("Tool") then t_insert(names, t.Name) end
                    end
                end
            end
            S.toolMiss = (S.toolMiss or 0) + 1
            if S.toolMiss <= 1 or S.toolMiss % 5 == 0 then
                SW.report("CandyFarm_NoTool", seed .. " | have: " .. (#names > 0 and table.concat(names, ", ") or "none"))
            end
            S.coolUntil = os.clock() + 4
            return
        end
        S.toolMiss = 0
        local tEquipped = os.clock()
        -- ยืนให้ตรงจุดจริงก่อนยิง (ตอนหยิบเมล็ด/รอเซิร์ฟเวอร์ ตัวละครอาจเลื่อน) แล้วเช็คใหม่กับทุกต้นสดๆ
        if not S.settleAt(stand) then
            S.bad[key] = true
            S.log("ยืนไม่ตรงจุด ข้ามจุด " .. key)
            setStatus("ยืนไม่ตรงจุด หาจุดใหม่")
            return
        end
        -- ระหว่างเดิน/ยืนนิ่ง Tool อาจหลุดมือ (ถูกระบบอื่นถอด) -> หยิบใหม่ก่อนยิง ไม่งั้นยิงเปล่าแล้วรอ timeout
        if tool.Parent ~= LP.Character then
            tool = equip(seed, 2)
            if not tool then
                S.coolUntil = os.clock() + 2
                return
            end
        end
        local _, hrpNow = getChar()
        if not hrpNow then return end
        local at = hrpNow.Position
        local predicted = S.predictTree(hrpNow)
        do
            local tooClose = false
            local minGap = S.minGap() - 0.15
            for _, o in ipairs(S.allPts()) do
                if flat(predicted, o) < minGap then tooClose = true break end
            end
            -- ยืนจริงแล้ว เช็คซ้ำด้วยชิ้นส่วนจริง ณ จุดที่ต้นจะโผล่ (hrp.Y สูงกว่าพื้น ~3 studs)
            if not tooClose and S.occupied(predicted, 4.5) then tooClose = true end
            if tooClose then
                S.bad[key] = true
                t_insert(S.badPts, { pos = spot, t = os.clock() })
                setStatus("ใกล้ต้นเดิมเกินไป หาจุดใหม่")
                task.wait(0.05)
                return
            end
        end
        -- นับจาก Model ในโฟลเดอร์เราโดยตรง (ไม่รอ Stats) ต้นใหม่ถึงเห็นทันทีที่เซิร์ฟเวอร์วาง
        local function ownModels()
            local list, f = {}, ownFolder()
            if f then
                for _, t in ipairs(f:GetChildren()) do
                    if t:IsA("Model") then t_insert(list, t) end
                end
            end
            return list
        end
        local beforeSet = {}
        for _, t in ipairs(ownModels()) do beforeSet[t] = true end
        local function newModel()
            for _, t in ipairs(ownModels()) do
                if not beforeSet[t] then return t end
            end
            return nil
        end
        local function grew(before)
            return allTreeCount() > before or newModel() ~= nil
        end
        local count0 = allTreeCount()
        local function tryPlant(t)
            local before = allTreeCount()
            setStatus("ปลูก " .. seed)
            LP:SetAttribute("FarmBusy", true)
            S.lastReject = nil
            local sent = os.clock()
            local okFire = pcall(PlantRemote.FireServer, PlantRemote, t)
            if not okFire then
                LP:SetAttribute("FarmBusy", false)
                return false
            end
            local t0 = os.clock()
            while os.clock() - t0 < 2.5 and not grew(before) and not S.plantReject(sent) do
                task.wait()
            end
            -- เซิร์ฟเวอร์ตอบช้า: รออีกนิดก่อนตัดสินว่าไม่ติด กันยิงซ้ำลงจุดเดิม
            local w = os.clock()
            while os.clock() - w < 1 and not grew(before) and not S.plantReject(sent) do
                task.wait()
            end
            LP:SetAttribute("FarmBusy", false)
            if grew(before) then return true end
            S.lastReject = S.plantReject(sent)
            return false
        end
        local planted = tryPlant(tool)
        if not planted and not equipped and live() and not S.lastReject then
            local t2 = equip(seed, 2)
            if t2 then
                planted = grew(count0) or tryPlant(t2)
                if planted then
                    S.needEquip = true
                    SW.Notify({ Title = "Candy Farm", Icon = "info", Content = "เกมต้องถือเมล็ดถึงจะปลูกได้ สลับไปถือให้อัตโนมัติแล้ว", Duration = 5 })
                end
            end
        end
        local tFired = os.clock()
        if planted then
            -- รอ Stats เฉพาะต้นที่เพิ่งวาง (สูงสุด 1 วิ) ไม่รอให้ทุกต้นมี Stats เพราะอาจไม่ครบตลอด -> ค้าง 3 วิทุกครั้ง
            local fresh = newModel()
            local s0 = os.clock()
            while live() and fresh and fresh.Parent and not fresh:FindFirstChild("Stats") and os.clock() - s0 < 1 do
                task.wait()
            end
        end
        t_insert(S.plantLog, { planted, m_floor(at.X), m_floor(at.Y), m_floor(at.Z) })
        if #S.plantLog > 200 then table.remove(S.plantLog, 1) end
        if planted then
            S.stat.planted = S.stat.planted + 1
            S.log(("ปลูกสำเร็จ (%d/%d)"):format(allTreeCount(), S.target))
            S.fails = 0
            S.spaceFails = 0
            S.recovered = false
            S.lastGood = at
            S.placed = S.placed or {}
            -- หาต้นใหม่จริงๆ เอาตำแหน่งจริงมาเก็บ + เรียนรู้ offset ระหว่างที่ยืนกับที่ต้นไปโผล่
            local real
            local r0 = os.clock()
            while os.clock() - r0 < 1 do
                local fresh = newModel()
                real = fresh and treePos(fresh)
                if real and flat(real, at) > 25 then real = nil end -- Model ยังไม่โหลด part ได้พิกัดเพี้ยน
                if real then break end
                task.wait()
            end
            if real and count0 == 0 then S.latOrigin = real end
            local mark = real or at
            t_insert(S.placed, { pos = mark, t = os.clock() })
            if real then
                S.learnOffset(hrpNow, at, real)
                local nearest = math.huge
                for _, o in ipairs(S.allPts()) do
                    local d = flat(real, o)
                    if d > 0.4 and d < nearest then nearest = d end
                end
                if nearest < S.minGap() - 0.3 then
                    S.stat.overlap = (S.stat.overlap or 0) + 1
                    if S.spacing < 10 then
                        S.spacing = S.spacing + 0.5
                        S.bad = {}
                    end
                    S.log(("เตือน: ต้นใหม่ชิดเกิน %.1f < %.1f"):format(nearest, S.minGap()))
                end
            end
        else
            S.stat.failed = S.stat.failed + 1
            S.log("ปลูกไม่ติด")
            local rej = S.lastReject
            S.lastReject = nil
            if rej then
                setStatus("เกมแจ้ง: " .. rej.text)
                if not S.seenReject[rej.text] then
                    S.seenReject[rej.text] = true
                    SW.Notify({ Title = "Candy Farm", Icon = "alert-triangle", Content = "เกมแจ้ง: " .. rej.text, Duration = 6 })
                end
                if S.hasWord(rej.text, { "ใกล้", "ชิด", "ซ้อน", "ทับ", "ระยะ", "close", "near", "space", "overlap", "distance" }) then
                    t_insert(S.badPts, { pos = spot, t = os.clock() })
                    if S.spacing < 10 then S.spacing = S.spacing + 0.5 end
                    S.bad = {}
                elseif S.hasWord(rej.text, { "เต็ม", "โควตา", "ครบ", "สูงสุด", "limit", "max", "full", "quota" }) then
                    S.coolUntil = os.clock() + 30
                end
            end
            S.bad[key] = true
            if tool and tool.Parent == LP.Character then
                t_insert(S.badPts, { pos = at, t = os.clock() })
                if #S.badPts > 40 then table.remove(S.badPts, 1) end
            end
            S.fails = S.fails + 1
            S.spaceFails = S.spaceFails + 1
            if S.spaceFails >= 2 and S.spacing < 10 then
                S.spaceFails = 0
                S.spacing = S.spacing + 1
                S.log("ถ่างระยะห่างเป็น " .. S.spacing)
                S.bad = {}
                setStatus(("ปลูกไม่ติด ถ่างระยะห่างเป็น %d studs"):format(S.spacing))
            end
            if S.fails >= 3 and not S.recovered and not S.anchorManual then
                S.fails = 0
                S.recovered = true
                S.bad = {}
                if S.lastGood then
                    S.anchor = S.lastGood
                else
                    S.anchor = nil
                    autoAnchor()
                end
                SW.Notify({ Title = "Candy Farm", Icon = "refresh-cw", Content = "ปลูกไม่ติด ย้ายจุดปลูกให้อัตโนมัติแล้วลองใหม่", Duration = 4 })
            elseif S.fails >= 3 then
                S.fails = 0
                S.recovered = false
                S.bad = {}
                S.log("ปลูกไม่ติด 3 ครั้ง พัก 8 วิ แล้วลองใหม่ (ระยะห่าง " .. S.spacing .. ")")
                S.coolUntil = os.clock() + 8
                SW.Notify({
                    Title = "Candy Farm",
                    Icon = "alert-triangle",
                    Content = "ปลูกไม่ติด 3 ครั้งติด: ต้องยืนในพื้นที่ปลูกของคุณ / ต้นไม้อาจเต็มโควตา พักปลูก 30 วิ",
                    Duration = 6,
                })
            end
        end
        local tDone = os.clock()
        if tDone - tStart > 4 then
            S.log(("ปลูกช้า %.1fs | เดิน %.1f หยิบ %.1f ยืน+ยิง %.1f รอผล %.1f"):format(
                tDone - tStart, tWalked - tStart, tEquipped - tWalked, tFired - tEquipped, tDone - tFired))
        end
        task.wait(planted and 0.05 or 0.4)
        return true
    end
    -- เก็บให้หมดก่อน: ต้นที่ Growth >= 100 และยังไม่เกินโควตาลองเก็บ (ต้นที่เก็บไม่ติด 3 ครั้งข้ามไป กันค้าง)
    local function grownList()
        local list = {}
        for _, tree in ipairs(ownTrees()) do
            if tree.Parent and statOf(tree, "Growth") >= 100 and (S.collectTries[treeKey(tree)] or 0) < 3 then
                t_insert(list, tree)
            end
        end
        local _, me = getChar()
        if me and #list > 1 then
            t_sort(list, function(a, b)
                local pa, pb = treePos(a), treePos(b)
                return (pa and flat(me.Position, pa) or m_huge) < (pb and flat(me.Position, pb) or m_huge)
            end)
        end
        return list
    end
    local function softReset(why)
        S.collecting, S.noPlantUntil, S.pausedFrom = false, 0, nil
        S.harvesting, S.replant = false, false
        S.collectTries, S.bad, S.badPts, S.known = {}, {}, {}, {}
        for k in pairs(S.lastCollect) do S.lastCollect[k] = nil end
        S.ignoreBeing = os.clock() + 20
        LP:SetAttribute("FarmBusy", false)
        S.log("รีเซ็ตกันค้าง: " .. why)
    end
    local function harvestAll()
        local list = grownList()
        if #list == 0 then return false end
        S.harvesting = true
        S.release("seed")
        for _, tree in ipairs(list) do
            if not live() then return true end
            if tree.Parent and statOf(tree, "Growth") >= 100 then
                setStatus(("เก็บผลให้หมดก่อน (%d ต้น)"):format(#list))
                collectTree(tree)
            end
        end
        return true
    end
    local function cycle()
        local _, hrp = getChar()
        if not hrp then
            setStatus("รอตัวละคร...")
            return
        end
        pauseGate()
        if not live() then return end
        local trees = ownTrees()
        rememberTrees(trees)
        if live() and recoverMissing(trees) then return end
        trees = ownTrees()
        -- watchdog: มีงานให้ทำ (ปลูกไม่ครบ/มีต้นโตรอเก็บ) แต่ปลูก/เก็บ/จำนวนต้นไม่ขยับ 45 วิ -> ล้างสถานะค้าง
        do
            local now = os.clock()
            local sig = S.stat.planted .. ":" .. S.stat.collected .. ":" .. #trees
            local want = S.plant and S.seed and S.batchOpen ~= false and #trees < S.target and hasSeed(S.seed)
            if not want and S.collect then
                for _, t in ipairs(trees) do
                    if statOf(t, "Growth") >= 100 then want = true break end
                end
            end
            if sig ~= S.wdSig or not want then
                S.wdSig, S.wdAt = sig, now
            elseif now - (S.wdAt or now) > 45 then
                S.wdAt = now
                softReset("ไม่คืบหน้า 45 วิ")
            end
        end
        -- 1) มีต้นโตเต็มอยู่ -> เก็บทุกต้นก่อน ยังไม่ปลูก/รด/ใส่ปุ๋ย
        if live() and S.collect and harvestAll() then return end
        -- 2) เก็บหมดแล้ว รอให้ต้นไม้ในโฟลเดอร์อัปเดตก่อน แล้วค่อยเริ่มรอบปลูกใหม่
        if S.harvesting then
            if S.collectBusy() then
                setStatus("เก็บครบแล้ว รอเริ่มรอบปลูกใหม่...")
                return
            end
            S.harvesting = false
            S.replant = true
            S.log("เก็บครบแล้ว เริ่มปลูกรอบใหม่")
        end
        if S.replant and #trees >= S.target then S.replant = false end
        -- ห้ามลด target ตอนรอบปลูกใหม่ ไม่งั้นเก็บ 3 ต้นแล้ว target หดตามไปด้วย
        if live() and S.plant and S.seed and not S.replant and #trees >= 5 and #trees < S.target then
            S.target = #trees
        end
        -- ปลูกเป็นชุด: ชุดเต็มแล้ว (ถึง target) ต้องรอให้ต้นที่ปลูกไว้ "โตและเก็บหมด" ก่อน ค่อยเปิดชุดใหม่
        -- (ต้นที่เก็บไม่ติดครบ 3 ครั้งไม่นับ กันค้างรอไม่จบ)
        if S.batchOpen == nil then S.batchOpen = true end
        if S.batchOpen and #trees >= S.target then
            S.batchOpen = false
            S.log("ปลูกครบชุดแล้ว รอเก็บให้หมดก่อนปลูกใหม่")
        end
        if not S.batchOpen then
            local pending = 0
            for _, t in ipairs(trees) do
                if not (statOf(t, "Growth") >= 100 and (S.collectTries[treeKey(t)] or 0) >= 3) then pending = pending + 1 end
            end
            if pending == 0 then
                S.batchOpen = true
                S.log("เก็บครบทุกต้นแล้ว เริ่มปลูกชุดใหม่")
            else
                setStatus(("รอแคนดี้โตและเก็บให้หมด (เหลือ %d ต้น) ก่อนปลูกใหม่"):format(pending))
            end
        end
        if live() and S.plant and S.seed and S.batchOpen and #trees < S.target and os.clock() >= S.coolUntil and not S.collectBusy() then
            S.planting = true
            local okP, did = pcall(plantOne, trees)
            S.planting = false
            if not okP then error(did, 0) end
            setStatus(("ปลูก %d/%d | %s ×%d"):format(#ownTrees(), S.target, S.seed, getCount(S.seed)))
            return did and "fast" or nil
        end
        if live() then S.release("seed") end
        -- ยืนต้นเดียว รดน้ำให้เต็ม + ใส่ปุ๋ยให้ครบ แล้วค่อยไปต้นที่ใกล้ตัวที่สุดต่อ (ไม่เดินไปมา)
        local function needsWork(t, now)
            if not t.Parent or isGrown(t) then return false end
            if S.water and (S.waterSkip[t] or 0) <= now and statOf(t, "Water") <= S.waterAt then return true end
            return S.fert and (S.fertSkip[t] or 0) <= now and not fertEnough(t)
        end
        local visited = {}
        while live() do
            local _, me = getChar()
            if not me then return end
            local now, best, bd = os.clock(), nil, m_huge
            for _, t in ipairs(ownTrees()) do
                if not visited[t] and needsWork(t, now) then
                    local pp = treePos(t)
                    local d = pp and flat(me.Position, pp) or m_huge
                    if not best or d < bd then best, bd = t, d end
                end
            end
            if not best then break end
            visited[best] = true
            if S.water and best.Parent and not isGrown(best) and not isFull(statOf(best, "Water")) and (S.waterSkip[best] or 0) <= os.clock() then
                waterTree(best)
            end
            if live() and S.fert and best.Parent and not isGrown(best) and not fertEnough(best) and (S.fertSkip[best] or 0) <= os.clock() then
                fertTree(best)
            end
        end
        if live() then S.release() end
        if not live() then return end
        if S.collect then
            for _, tree in ipairs(ownTrees()) do
                if not live() then return end
                if tree.Parent and statOf(tree, "Growth") >= 100 then collectTree(tree) end
            end
        end
        local n = #ownTrees()
        if n == 0 then
            local f = ownFolder()
            setStatus(f and "ยังไม่มีต้นไม้ (หรือหา Stats ของต้นไม่เจอ)" or "ยังไม่เจอโฟลเดอร์ต้นไม้ของเรา (ยังไม่ได้ปลูก?)")
            return
        end
        setStatus(("ต้นไม้ %d/%d | %s ×%d | ปุ๋ย ×%d"):format(n, S.target, S.seed or "-", S.seed and getCount(S.seed) or 0, getCount(BAG)))
    end
    S.seed = findSeed() or "SeedCandy"
    local run = SW.CandyTab:CreateSection({ Name = "Run", Icon = "lucide:play", Column = 1 })
    statusP = run:CreateParagraph({ Title = "Status", Content = "ยังไม่เริ่ม" })
    local C_OK, C_WARN, C_BAD, C_DIM = Color3.fromRGB(90, 220, 130), Color3.fromRGB(255, 190, 80), Color3.fromRGB(255, 95, 95), Color3.fromRGB(150, 150, 160)
    local function kv(sec, name, init)
        local o = sec:CreateKeyValue({ Name = name, Value = init, Copyable = false })
        return {
            set = function(v, col)
                pcall(o.Set, o, v)
                if col then pcall(o.SetColor, o, col) end
            end,
        }
    end
    local mon = SW.CandyTab:CreateSection({ Name = "Auto Plant Monitor", Icon = "lucide:activity", Column = 2 })
    local mState = kv(mon, "สถานะ", "หยุด")
    local mActP = mon:CreateParagraph({ Title = "กำลังทำ", Content = "-" })
    local mTrees = kv(mon, "ต้นไม้", "0/5")
    local mSeed = kv(mon, "เมล็ด (เหลือ)", "-")
    local mHeld = kv(mon, "ถืออยู่", "-")
    local mPlant = kv(mon, "ปลูก ติด/ไม่ติด", "0/0")
    local mWork = kv(mon, "รดน้ำ/ปุ๋ย/เก็บ", "0/0/0")
    local mBag = kv(mon, "ถุงปุ๋ยคงเหลือ", "0")
    local treeSec = SW.CandyTab:CreateSection({ Name = "My Candy Trees", Icon = "lucide:candy", Column = 2 })
    local slots = {}
    for i = 1, 5 do
        local card = treeSec:CreateStatusCard({
            Name = "ต้น " .. i, Image = "lucide:candy", IconSize = 26,
            Bars = {
                { Label = "น้ำ", Color = Color3.fromRGB(80, 170, 255) },
                { Label = "ปุ๋ย", Color = Color3.fromRGB(255, 176, 72) },
                { Label = "โต", Color = Color3.fromRGB(90, 220, 130) },
            },
        })
        pcall(card.SetEmpty, card, true, "ว่าง")
        slots[i] = { card = card }
    end
    local CANDY_MAX = 50 -- เต็มช่องเมื่อถึงค่านี้ (MaxValue ของไอเทมแคนดี้)
    local CANDY_ITEMS = {
        { "Oreo", "rbxassetid://97509034510777", Color3.fromRGB(150, 110, 255) },
        { "Candy", "rbxassetid://99771998549525", Color3.fromRGB(255, 110, 170) },
        { "Taffy", "rbxassetid://73348402490940", Color3.fromRGB(80, 200, 255) },
        { "Donuts", "rbxassetid://137665949906510", Color3.fromRGB(255, 176, 72) },
        { "CottonCandy", "rbxassetid://126371470160157", Color3.fromRGB(255, 150, 220) },
    }
    local candySec = SW.CandyTab:CreateSection({ Name = "Candy Items", Icon = "lucide:candy", Column = 2 })
    local candyCards = {}
    for i, it in ipairs(CANDY_ITEMS) do
        candyCards[i] = candySec:CreateStatusCard({
            Name = it[1], Image = it[2], IconSize = 26,
            Bars = { { Label = "จำนวน", Color = it[3] } },
        })
    end
    local candyRemote
    local candyWait, candySig = {}, {}
    task.spawn(function()
        while SW.alive do
            task.wait(1)
            pcall(function()
                for i, it in ipairs(CANDY_ITEMS) do
                    local name, card = it[1], candyCards[i]
                    local n = getCount(name)
                    local full = n >= CANDY_MAX
                    local sig = n .. (full and "F" or "")
                    if candySig[name] ~= sig then
                        candySig[name] = sig
                        pcall(card.SetEmpty, card, false)
                        pcall(card.SetBadge, card, full and "เต็ม" or ("×" .. n), full and C_BAD or (n > 0 and C_OK or C_DIM))
                        pcall(card.SetBar, card, 1, m_clamp(m_floor(n / CANDY_MAX * 100), 0, 100), n .. "/" .. CANDY_MAX, full and C_BAD or nil)
                    end
                    if full and S.on and (candyWait[name] or 0) < os.clock() then
                        if not candyRemote or not candyRemote.Parent then
                            candyRemote = resolveRemotePath(RS, { "Game_Modules", "RemoteEventSafe", "DepositItem" }, 2)
                        end
                        if candyRemote then
                            candyWait[name] = os.clock() + 3
                            pcall(candyRemote.FireServer, candyRemote, name, n)
                            S.log("เก็บใส่ตู้ " .. name .. " ×" .. n)
                        end
                    end
                end
            end)
        end
    end)
    local logSec = SW.CandyTab:CreateSection({ Name = "Activity", Icon = "lucide:list", Column = 2, Collapsed = false })
    local monLog = logSec:CreateParagraph({ Title = "เหตุการณ์ล่าสุด", Content = "ยังไม่มีเหตุการณ์" })
    local monLast = {}
    local function put(key, setter, v, col)
        local sig = tostring(v) .. tostring(col)
        if monLast[key] == sig then return end
        monLast[key] = sig
        setter(v, col)
    end
    task.spawn(function()
        while SW.alive do
            task.wait(0.6)
            pcall(function()
                local c = LP.Character
                local held = "ไม่ได้ถือ"
                if c then
                    for _, t in ipairs(c:GetChildren()) do
                        if t:IsA("Tool") then
                            held = t.Name
                            break
                        end
                    end
                end
                local trees = ownTrees()
                local seed = S.seed or "-"
                put("state", mState.set, S.on and "ทำงาน" or "หยุด", S.on and C_OK or C_DIM)
                put("act", function(v) pcall(mActP.Set, mActP, nil, v) end, tostring(S.phase), nil)
                put("trees", mTrees.set, ("%d/%d"):format(#trees, S.target), #trees >= S.target and C_OK or C_WARN)
                put("seed", mSeed.set, "×" .. (S.seed and getCount(seed) or 0), nil)
                put("held", mHeld.set, held, nil)
                put("plant", mPlant.set, ("%d/%d"):format(S.stat.planted, S.stat.failed), S.stat.failed > 0 and C_WARN or nil)
                put("work", mWork.set, ("%d/%d/%d"):format(S.stat.watered, S.stat.fert, S.stat.collected), nil)
                local bag = getCount(BAG)
                put("bag", mBag.set, "×" .. bag, bag <= 3 and C_BAD or nil)
                table.sort(trees, function(a, b) return treeKey(a) < treeKey(b) end)
                for i, sl in ipairs(slots) do
                    local t = trees[i]
                    local c = sl.card
                    if t then
                        local w, f, g = m_floor(statOf(t, "Water")), m_floor(statOf(t, "Food")), m_floor(statOf(t, "Growth"))
                        put("t" .. i, function()
                            local ready = g >= 100
                            local label, lc = "กำลังโต", Color3.fromRGB(120, 175, 255)
                            if ready then
                                label, lc = "พร้อมเก็บ", C_OK
                            elseif w <= 25 then
                                label, lc = "ขาดน้ำ", C_BAD
                            end
                            pcall(c.SetEmpty, c, false)
                            pcall(c.SetBadge, c, label, lc)
                            pcall(c.SetBar, c, 1, w, tostring(w), w <= 25 and C_BAD or nil)
                            pcall(c.SetBar, c, 2, f, tostring(f))
                            pcall(c.SetBar, c, 3, g, g .. "%", ready and C_OK or nil)
                        end, w .. "/" .. f .. "/" .. g)
                        if sl.icon ~= t.Name then
                            local okT, src = pcall(function()
                                local gui = t:FindFirstChild("HelpGui", true)
                                local fr = gui and gui:FindFirstChild("Frame")
                                for _, n in ipairs({ "Item", "ImageProp" }) do
                                    local l = fr and fr:FindFirstChild(n)
                                    if l and l:IsA("ImageLabel") and l.Image ~= "" then return l.Image end
                                end
                            end)
                            if okT and src and pcall(c.SetImage, c, src) then sl.icon = t.Name end
                        end
                    else
                        put("t" .. i, function() pcall(c.SetEmpty, c, true, "ว่าง") end, "empty")
                        if sl.icon then
                            sl.icon = nil
                            pcall(c.SetImage, c, "lucide:candy")
                        end
                    end
                end
                local lines = {}
                for i = #S.logs, 1, -1 do lines[#lines + 1] = S.logs[i] end
                put("log", function(v) pcall(monLog.Set, monLog, nil, v) end, #lines > 0 and table.concat(lines, "\n") or "ยังไม่มีเหตุการณ์")
            end)
        end
    end)
    SW.addSlider(run, "Water At (%)", "รดน้ำเมื่อน้ำของต้นไม้ลดลงถึงค่านี้ (ถ้าน้ำต่ำมากจะรีบรดให้เองอยู่แล้ว)", 10, 95, 5, "%", S.waterAt, function(n)
        S.waterAt = m_floor(n)
        S.log("ตั้งรดน้ำเมื่อ ≤ " .. S.waterAt .. "%")
    end)
    run:CreateButton({
        Name = "Teleport to My Candy",
        Icon = "lucide:navigation",
        Tooltip = "วาร์ปไปยืนข้างต้นแคนดี้ของเรา",
        Callback = function()
            local c, hrp, h = getChar()
            if not c then
                SW.Notify({ Title = "Candy Farm", Icon = "x-circle", Content = "ไม่พบตัวละคร", Duration = 3 })
                return
            end
            local target
            local best
            for _, t in ipairs(ownTrees()) do
                local p = treePos(t)
                if p then
                    local d = flat(hrp.Position, p)
                    if not best or d < best then target, best = p, d end
                end
            end
            if not target then
                for _, info in pairs(S.known) do
                    if info.pos then target = info.pos break end
                end
            end
            target = target or S.anchor
            if not target then
                SW.Notify({ Title = "Candy Farm", Icon = "alert-triangle", Content = "ยังไม่มีต้นแคนดี้ให้วาร์ปไป", Duration = 4 })
                return
            end
            if h.SeatPart then h.Sit = false task.wait(0.1) end
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            local ignore = { c }
            local apt = workspace:FindFirstChild("AllPlantedTrees")
            if apt then t_insert(ignore, apt) end
            params.FilterDescendantsInstances = ignore
            local spot = target + Vector3.new(3, 0, 0)
            local ray = workspace:Raycast(spot + Vector3.new(0, 30, 0), Vector3.new(0, -80, 0), params)
            local dest = (ray and ray.Position or spot) + Vector3.new(0, 3, 0)
            hrp.AssemblyLinearVelocity = Vector3.zero
            c:PivotTo(CFrame.new(dest))
            task.delay(0.25, function()
                local h2 = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                if h2 and (h2.Position - dest).Magnitude > 40 then
                    pcall(function() LP.Character:PivotTo(CFrame.new(dest)) end)
                end
            end)
            S.log("วาร์ปไปที่แคนดี้")
        end,
    })
    run:CreateToggle({
        Name = "Auto Set Slot",
        Tooltip = "ถ้าเมล็ดแคนดี้ยังไม่อยู่ในสล็อตไหน จะเซ็ตลงสล็อตว่างช่องแรกให้เอง",
        Default = true,
        Callback = function(state)
            S.autoSlot = state
            if state then task.spawn(S.ensureSlot, S.seed, true) end
        end,
    })
    do
        local view, HUD, viewLoop = { n = 0 }, { on = true }, false
        local hudGui, hudFrame, hudLbl
        local function refreshView()
            local sx, sy, sz, n = 0, 0, 0, 0
            for _, t in ipairs(ownTrees()) do
                local p = treePos(t)
                if p then sx, sy, sz, n = sx + p.X, sy + p.Y, sz + p.Z, n + 1 end
            end
            view.n = n
            view.center = n > 0 and v3_new(sx / n, sy / n, sz / n) or S.anchor
        end
        local function buildHud()
            hudGui = SW.new("ScreenGui", { Name = "SW_CandyHUD", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 39 }, LP.PlayerGui)
            hudFrame = SW.new("Frame", {
                Size = UDim2.fromOffset(300, 78), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
                BackgroundColor3 = SW.Bg, BackgroundTransparency = 0.35, BorderSizePixel = 0, Active = false, Visible = false,
            }, hudGui)
            SW.round(hudFrame, 12)
            SW.edge(hudFrame, 1.5, 0.3, 45)
            SW.new("UIListLayout", {
                Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder,
                HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center,
            }, hudFrame)
            local function lbl(i, sz, col)
                return SW.new("TextLabel", {
                    Size = UDim2.new(1, -12, 0, sz + 4), BackgroundTransparency = 1, Font = Enum.Font.SourceSansBold,
                    TextSize = sz, TextColor3 = col, TextTruncate = Enum.TextTruncate.AtEnd, LayoutOrder = i, Text = "",
                }, hudFrame)
            end
            hudLbl = { lbl(1, 18, SW.Good), lbl(2, 17, SW.Text), lbl(3, 14, SW.Sub) }
        end
        local function paintHud()
            if not (hudGui and hudGui.Parent) then buildHud() end
            hudFrame.Visible = HUD.on and S.on
            if not hudFrame.Visible then return end
            local st = S.stat
            hudLbl[1].Text = "● CANDY FARM"
            hudLbl[2].Text = tostring(S.phase)
            hudLbl[3].Text = ("ต้น %d/%d  ปลูก %d/%d  น้ำ %d  ปุ๋ย %d  เก็บ %d"):format(view.n, S.target, st.planted, st.failed, st.watered, st.fert, st.collected)
        end
        local function startView()
            if viewLoop then return end
            viewLoop = true
            task.spawn(function()
                while SW.alive and HUD.on do
                    if S.on then pcall(refreshView) end
                    pcall(paintHud)
                    task.wait(0.5)
                end
                viewLoop = false
            end)
        end
        run:CreateToggle({
            Name = "Center Status HUD",
            Tooltip = "แสดงสถานะ Candy Farm กลางหน้าจอตอนออโต้ทำงาน",
            Default = true,
            Callback = function(state)
                HUD.on = state
                if state then startView() elseif hudFrame then hudFrame.Visible = false end
            end,
        })
        startView()
        pcall(function()
            Window:OnDestroy(function()
                if hudGui then hudGui:Destroy() end
            end)
        end)
    end
    local runToggle
    runToggle = run:CreateToggle({
        Name = "Candy Farm",
        Tooltip = "กดเปิดอย่างเดียวจบ: เลือกเมล็ด/ตั้งจุดปลูกให้เอง แล้ว ปลูก > รดน้ำ > ปุ๋ย > เก็บ วนเอง",
        Default = false,
        Callback = function(state)
            if state and S.plant and not hasSeed(S.seed) then
                local alt = findSeed()
                if alt then
                    S.seed = alt
                else
                    SW.Notify({ Title = "Candy Farm", Icon = "alert-triangle", Content = "ไม่มีเมล็ดแคนดี้ในกระเป๋า (จะรดน้ำ/ใส่ปุ๋ย/เก็บผลให้ตามปกติ) | เจอ: " .. S.dumpSeedy(), Duration = 10 })
                end
            end
            S.on = state
            S.run = S.run + 1
            LP:SetAttribute("FarmBusy", false)
            if not state then
                setStatus("หยุดแล้ว")
                task.spawn(S.release)
                return
            end
            autoAnchor()
            if S.seed then task.spawn(S.ensureSlot, S.seed, true) end
            S.coolUntil, S.fails, S.bad, S.recovered = 0, 0, {}, false
            S.harvesting, S.replant, S.batchOpen = false, false, nil
            S.collecting, S.noPlantUntil, S.pausedFrom, S.wdSig = false, 0, nil, nil
            S.collectTries, S.badPts, S.known, S.latOrigin = {}, {}, {}, nil
            for k in pairs(S.lastCollect) do S.lastCollect[k] = nil end
            local myRun = S.run
            task.spawn(function()
                local w0 = os.clock()
                while S.looping and os.clock() - w0 < 10 do task.wait(0.1) end
                if not (S.on and S.run == myRun) then return end
                S.looping, S.cycleRun = true, myRun
                local errs = 0
                while S.on and SW.alive and S.run == myRun do
                    local ok, fast = SW.try("CandyFarm", cycle)
                    if ok then
                        errs = 0
                        task.wait(fast and 0.05 or 0.5)
                    else
                        errs = errs + 1
                        task.wait(m_clamp(0.5 * 2 ^ errs, 0.5, 8))
                    end
                end
                if S.cycleRun == myRun then S.looping = false end
            end)
        end,
    })
end
SW.CandyAllowed = {
    [8514985969] = true,
}
SW.LoadCandyGate = function()
    if SW.CandyAllowed[LP.UserId] and not SW.CandyHardLock then
        SW.safeLoad("SW.LoadCandy", SW.LoadCandy)
        return
    end
    SW.CandyLockNotify = function()
        SW.Notify({
            Title = "Candy Farm ถูกล็อคอยู่",
            Content = "แท็บนี้ปิดปรับปรุงชั่วคราว (กำลังแก้บัก) เปิดให้เฉพาะผู้ที่ได้รับสิทธิ์ ส่วนฟีเจอร์อื่นใช้งานได้ตามปกติ",
            Icon = "lock",
            Duration = 6,
        })
    end
    if SW.CandyHardLock then return end -- ล็อคเต็ม: Locked = true ตั้งไว้ตอน CreateTab แล้ว
    SW.CandyTab:Lock(SW.CandyLockText)  -- ไม่อยู่ใน whitelist: ล็อคด้วย API ของ SpectreUI
    task.spawn(function()
        local t0 = os.clock()
        while SW.alive and not SW.revealed and os.clock() - t0 < 50 do task.wait(0.5) end
        task.wait(1.2)
        if SW.alive then SW.CandyLockNotify() end
    end)
end
HomeTab:Load(function()
    SW.safeLoad("SW.LoadHome", SW.LoadHome)
end)
FarmTab:Load(function()
    LoadFarmTab()
    SW.safeLoad("SW.LoadProcess", SW.LoadProcess)
end)
SW.FishTab:Load(function()
    SW.safeLoad("SW.LoadNever", SW.LoadNever)
end)
SW.EatTab:Load(function()
    SW.safeLoad("SW.LoadEat", SW.LoadEat)
end)
SW.CandyTab:Load(SW.LoadCandyGate)
TeleportTab:Load(LoadTeleportTab)
SW.SafeTab:Load(function()
    SW.safeLoad("SW.LoadSafe", SW.LoadSafe)
end)
SW.ServerTab:Load(function()
    SW.safeLoad("SW.BuildServer", SW.BuildServer)
end)
SettingsTab:Load(LoadSettingsTab)
SW.CandyLockNotify = SW.CandyLockNotify or function()
    SW.Notify({
        Title = "Candy Farm ถูกล็อคอยู่",
        Content = "แท็บนี้ปิดปรับปรุงชั่วคราว (กำลังแก้บัก) ฟีเจอร์อื่นใช้งานได้ตามปกติ",
        Icon = "lock",
        Duration = 5,
    })
end
Window:OnLoaded(function()
    SW.building = false
    SW.reveal()
end)
task.spawn(function()
    task.wait(0.25)
    SW.reveal()
    Window:StartLoad()
end)
