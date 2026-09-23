-- ╔══════════════════════════════════════════════════════╗
-- ║  SpectreWare Gateway  –  Loader Entry Point           ║
-- ║  Public entry point. Fetches & runs whitelist.lua     ║
-- ║  (the real LuaSyncX client) via multi-executor HTTP.  ║
-- ╚══════════════════════════════════════════════════════╝

-- ── PlaceId → scriptUrl map ───────────────────────────────────────────────
-- ใส่ PlaceId (string) → URL ของสคริปต์สำหรับเกมนั้น ๆ ตรงนี้
-- whitelist.lua จะเช็ค map นี้ก่อนยิงไป backend เสมอ ถ้าเจอ placeId ใน map
-- จะใช้ scriptUrl นี้เลย (ไม่ต้องพึ่ง /api/script/:placeId จาก backend)
local PLACE_MAP = {
     ["77908479907662"] = "https://raw.githubusercontent.com/SpectreWareZ/SpectreWare/refs/heads/main/Games/NeverTown.lua",
    ["17766863403"] = "https://raw.githubusercontent.com/Captaineieiei/Script-/refs/heads/main/Beady",
}

local CFG = {
    whitelistUrl = "https://raw.githubusercontent.com/SpectreWareZ/SpectreWare/refs/heads/main/LuasyncX/whitelist.lua",
    maxRetries    = 3,
    retryBackoff  = 1,
    timeout       = 8,
}

local _r_pcall = pcall

-- ── Multi-executor HTTP layer (mirrors whitelist.lua's httpSend) ────────────
local _httpFns = {
    function(o) return http        and http.request          and http.request(o)             end,
    function(o) return http        and http.Request          and http.Request(o)              end,
    function(o) return request     and request(o)                                              end,
    function(o) return http_request and http_request(o)                                        end,
    function(o) return HttpRequest and HttpRequest(o)                                           end,
    function(o) return httpRequest and httpRequest(o)                                           end,
    function(o) return fluxus      and fluxus.request        and fluxus.request(o)             end,
    function(o) return fluxus      and fluxus.http and fluxus.http.request and fluxus.http.request(o) end,
    function(o) return Delta       and Delta.request          and Delta.request(o)              end,
    function(o) return delta       and delta.request          and delta.request(o)              end,
    function(o) return ARCEUS_X    and ARCEUS_X.http_request  and ARCEUS_X.http_request(o)       end,
    function(o) return Scriptware  and Scriptware.http_request and Scriptware.http_request(o)    end,
    function(o) return Electron    and Electron.http_request  and Electron.http_request(o)       end,
    function(o) return calamari    and calamari.request       and calamari.request(o)            end,
    function(o) return VEGA_X      and VEGA_X.request         and VEGA_X.request(o)              end,
    function(o) return nihon       and nihon.request          and nihon.request(o)               end,
    function(o) return celery      and celery.request         and celery.request(o)              end,
    function(o) return trigon      and trigon.request         and trigon.request(o)              end,
    function(o) return SWIFT       and SWIFT.request          and SWIFT.request(o)               end,
    function(o) return proxo       and proxo.request          and proxo.request(o)               end,
    function(o) return Xeno        and Xeno.request           and Xeno.request(o)                end,
    function(o) return Wave        and Wave.request           and Wave.request(o)                end,
    function(o) return Solara      and Solara.request         and Solara.request(o)              end,
    function(o) return Potassium   and Potassium.request      and Potassium.request(o)           end,
    function(o) return Cosmic      and Cosmic.request         and Cosmic.request(o)              end,
    function(o) return Real        and Real.request           and Real.request(o)                end,
}

local function _normalizeRes(res)
    if not res then return nil end
    local body = res.Body or res.body
    if type(body) == "table" then body = tostring(body) end
    if not body or body == "" then return nil end
    return body
end

-- เรียก _httpFns[i] แบบมี timeout ของตัวเอง ไม่แชร์ budget กับตัวอื่น
-- ฟังก์ชันที่ global ไม่มีอยู่ (nil) จะ short-circuit คืนค่าใน tick แรกอยู่แล้ว
-- ดังนั้นตัวที่กิน timeout จริง ๆ มีแค่ executor ที่ "มีอยู่จริง" แต่ request ค้าง
local function _tryFn(fn, opts, timeout)
    local done, ok, res = false, false, nil
    local co = task.spawn(function()
        local o, r = _r_pcall(fn, opts)
        ok, res = o, r
        done = true
    end)
    -- ถ้า fn เสร็จทันที (executor nil) done = true แล้ว → ไม่ต้อง poll เลย
    if done then return ok, res end
    local ticks, max = 0, math.max(1, math.floor(timeout * 10)) -- ลด max 2x (interval เพิ่ม 2x)
    while not done and ticks < max do
        task.wait(0.1) -- 0.05 → 0.1 (poll ทุก 100ms แทน 50ms ลด wakeup overhead)
        ticks = ticks + 1
    end
    if not done then
        pcall(task.cancel, co)
        return false, nil
    end
    return ok, res
end

local _cacheIdx
local function httpGet(url, timeout)
    local opts = { Url = url, Method = "GET", Timeout = timeout, timeout = timeout }

    if _cacheIdx then
        local ok, res = _tryFn(_httpFns[_cacheIdx], opts, timeout)
        local body = ok and _normalizeRes(res)
        if body then return true, body end
        if not ok then _cacheIdx = nil end
    end

    for i = 1, #_httpFns do
        local ok, res = _tryFn(_httpFns[i], opts, timeout)
        local body = ok and _normalizeRes(res)
        if body then _cacheIdx = i; return true, body end
    end

    local ok, body = _r_pcall(function() return game:HttpGet(url, true) end)
    if ok and body and body ~= "" then return true, body end
    return false, nil
end

local function safeGetTimeout(url, timeout)
    local done, ok, body = false, false, nil
    local co = task.spawn(function()
        local o, b = httpGet(url, timeout)
        if not done then ok, body = o, b end
        done = true
    end)
    local ticks, max = 0, timeout * 10 -- ลด max ให้สอดคล้อง interval ใหม่
    while not done and ticks < max do task.wait(0.1); ticks = ticks + 1 end -- 0.05 → 0.1
    if not done then pcall(task.cancel, co) end
    return done and ok or false, done and body or nil
end

-- ── Double-execute guard (gateway-level, before any fetch) ──────────────────
-- Prevents wasting an HTTP round-trip when the gateway itself gets invoked
-- twice in quick succession (autoexec + manual run, double-bound hotkey,
-- UI button without debounce, etc). This is separate from whitelist.lua's
-- own guard, which only catches it *after* the fetch+decrypt already ran.
-- รอบที่ซ้ำจะ return เงียบ ๆ (ไม่ warn แล้ว เพราะ UI ของรอบแรกยังทำงานอยู่)
-- ถ้าอยากรู้ว่าใครเรียกซ้ำ: getgenv()._SW_DEBUG = true ก่อนรัน → จะ print traceback ของตัวที่เรียกซ้ำ
do
    local gev = getgenv()
    if gev._SW_GW_RUNNING and (os.time() - (gev._SW_GW_STIME or 0)) < 10 then
        if gev._SW_DEBUG then
            print("[ SpectreWare Gateway ]: duplicate invocation skipped\n" .. debug.traceback())
        end
        return
    end
    gev._SW_GW_RUNNING = true
    gev._SW_GW_STIME = os.time()
end

-- ปล่อย guard เมื่อโหลดล้มเหลว เพื่อให้กดรันใหม่ได้ทันที (ไม่ต้องรอ 10 วิ)
-- ตอนสำเร็จไม่ปล่อย เพื่อยังกันการเรียกซ้ำช่วงท้าย ๆ ได้ตามเดิม
local function _releaseGuard()
    pcall(function() getgenv()._SW_GW_RUNNING = nil end)
end


-- ── Loader UI ────────────────────────────────────────────────────────────────
-- แสดง UI โหลดทันทีที่กดรันสคริปต์ (การ์ดกลางจอ + progress bar + ข้อความสถานะ)
-- whitelist.lua อัปเดตผ่าน getgenv()._SW_LOADER (เรียกแบบ dot ไม่ใช่ colon):
--   .Log(text, kind)   kind = "loading" | "info" | "success" | "error" | "done"
--   .Set(pct, text)    ดัน progress (0-99, ไม่ถอยหลัง) + เปลี่ยนข้อความ
--   .Done(text)        เต็ม 100% สีเขียว แล้วเลือนหาย
--   .Fail(text)        สีแดง แล้วเลือนหายใน 4 วิ
--   .Close(onlyIfRunning)
-- สร้าง UI ไม่ได้ (executor ไม่รองรับ) → fallback เป็น no-op ไม่กระทบการโหลด
-- ถ้ามี loader ของรอบก่อนยังรันอยู่ (เช่น รันซ้ำหลังผ่านช่วง guard 10 วิ) ไม่สร้างใหม่/ไม่แย่งไป
-- รอบนี้จะใช้ NOOP แทน เพื่อไม่ให้ไปปิดหรือทับ UI ของรอบที่กำลังโหลดอยู่
local _prevAlive = false
pcall(function()
    local prev = getgenv()._SW_LOADER
    _prevAlive = type(prev) == "table" and type(prev.IsRunning) == "function" and prev.IsRunning() == true
end)

local LOADER = (function()
    local NOOP = {
        Log = function() end, Set = function() end, Done = function() end,
        Fail = function() end, Close = function() end, IsRunning = function() return false end,
    }
    if _prevAlive then return NOOP end

    local built, api = pcall(function()
        local TweenService = game:GetService("TweenService")
        local RunService   = game:GetService("RunService")
        local Players      = game:GetService("Players")
        local cr           = cloneref or function(x) return x end

        local C = {
            bg      = Color3.fromRGB(12, 12, 18),
            inset   = Color3.fromRGB(20, 20, 30),
            track   = Color3.fromRGB(30, 30, 42),
            text    = Color3.fromRGB(232, 232, 242),
            muted   = Color3.fromRGB(108, 108, 136),
            accentA = Color3.fromRGB(140, 100, 255),
            accentB = Color3.fromRGB(80, 150, 245),
            ok      = Color3.fromRGB(72, 210, 120),
            okB     = Color3.fromRGB(52, 180, 200),
            err     = Color3.fromRGB(235, 75, 75),
            errB    = Color3.fromRGB(245, 130, 50),
            white   = Color3.new(1, 1, 1),
        }

        local ICON = {
            wifi     = "rbxassetid://10747382504",
            shield   = "rbxassetid://10734951847",
            download = "rbxassetid://10723344270",
            check    = "rbxassetid://10709790644",
            x        = "rbxassetid://10747384394",
        }

        local function mk(cls, props, parent)
            local i = Instance.new(cls)
            for k, v in pairs(props) do pcall(function() i[k] = v end) end
            i.Parent = parent
            return i
        end

        local CSK, NSK = ColorSequenceKeypoint.new, NumberSequenceKeypoint.new
        local function grad2(a, b) return ColorSequence.new(a, b) end
        local function tw(obj, dur, props, style, dir, rep)
            local t = TweenService:Create(obj,
                TweenInfo.new(dur, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out, rep or 0),
                props)
            t:Play()
            return t
        end

        local function attach(gui)
            pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
            local parents = {}
            local okH, hui = pcall(function() return gethui and gethui() end)
            if okH and typeof(hui) == "Instance" then parents[#parents + 1] = hui end
            local okC, cg = pcall(function() return cr(game:GetService("CoreGui")) end)
            if okC and cg then parents[#parents + 1] = cg end
            local lp = Players.LocalPlayer
            local pg = lp and lp:FindFirstChildOfClass("PlayerGui")
            if pg then parents[#parents + 1] = pg end
            for _, par in ipairs(parents) do
                local old = par:FindFirstChild("SW_LoaderGui")
                if old then pcall(function() old:Destroy() end) end
            end
            for _, par in ipairs(parents) do
                local ok = pcall(function() gui.Parent = par end)
                if ok and gui.Parent ~= nil then return true end
            end
            return false
        end

        -- ── Build ──────────────────────────────────────────────────────────────
        local H = 136
        local gui = mk("ScreenGui", {
            Name = "SW_LoaderGui", ResetOnSpawn = false, IgnoreGuiInset = true,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 998,
        })

        local cardClass = pcall(Instance.new, "CanvasGroup") and "CanvasGroup" or "Frame"
        local card = mk(cardClass, {
            Name = "Card", Size = UDim2.new(0.86, 0, 0, H),
            Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = C.bg, BorderSizePixel = 0, GroupTransparency = 1, ClipsDescendants = true,
        }, gui)
        mk("UISizeConstraint", { MaxSize = Vector2.new(360, H), MinSize = Vector2.new(250, H) }, card)
        mk("UICorner", { CornerRadius = UDim.new(0, 14) }, card)
        local uiScale = mk("UIScale", { Scale = 0.92 }, card)

        -- Static border with gradient (not animated)
        local borderStroke = mk("UIStroke", { Color = C.white, Thickness = 1, Transparency = 0 }, card)
        mk("UIGradient", { Color = grad2(C.accentA, C.accentB) }, borderStroke)

        -- Left accent bar — deliberate design anchor
        mk("Frame", {
            Size = UDim2.new(0, 3, 0, 64), Position = UDim2.fromOffset(0, 24),
            BackgroundColor3 = C.accentA, BorderSizePixel = 0, ZIndex = 3,
        }, card)

        -- ── Badge: spinner ring + stage icon ──
        local badge = mk("Frame", {
            Position = UDim2.fromOffset(18, 22), Size = UDim2.fromOffset(52, 52),
            BackgroundTransparency = 1, ZIndex = 2,
        }, card)
        local ringTrack = mk("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2 }, badge)
        mk("UICorner", { CornerRadius = UDim.new(1, 0) }, ringTrack)
        mk("UIStroke", { Color = C.track, Thickness = 3 }, ringTrack)
        local ring = mk("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 3 }, badge)
        mk("UICorner", { CornerRadius = UDim.new(1, 0) }, ring)
        local ringStroke = mk("UIStroke", { Color = C.white, Thickness = 3 }, ring)
        local ringGrad = mk("UIGradient", {
            Color       = grad2(C.accentA, C.accentB),
            Transparency = NumberSequence.new({ NSK(0, 0), NSK(0.5, 0.2), NSK(0.75, 1), NSK(1, 1) }),
        }, ringStroke)
        local coreFrame = mk("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(38, 38), BackgroundColor3 = C.inset, BorderSizePixel = 0, ZIndex = 3,
        }, badge)
        mk("UICorner", { CornerRadius = UDim.new(1, 0) }, coreFrame)
        local stageIcon = mk("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1,
            Image = ICON.wifi, ImageColor3 = C.accentB, ScaleType = Enum.ScaleType.Fit, ZIndex = 4,
        }, coreFrame)

        -- ── Text ──
        local title = mk("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.fromOffset(86, 20), Size = UDim2.new(1, -170, 0, 22),
            Font = Enum.Font.GothamBlack, Text = "SPECTREWARE", TextSize = 17, ZIndex = 2,
            TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left,
        }, card)
        mk("UIGradient", {
            Color = ColorSequence.new({
                CSK(0, C.accentA), CSK(0.45, Color3.fromRGB(200, 175, 255)),
                CSK(0.55, Color3.fromRGB(170, 210, 255)), CSK(1, C.accentB),
            }),
        }, title)

        mk("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.fromOffset(86, 42), Size = UDim2.new(1, -170, 0, 14),
            Font = Enum.Font.GothamMedium, Text = "LuaSyncX", TextSize = 11, TextColor3 = C.muted, ZIndex = 2,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, card)

        local pctLabel = mk("TextLabel", {
            BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -16, 0, 18), Size = UDim2.fromOffset(70, 28),
            Font = Enum.Font.GothamBold, Text = "0%", TextSize = 21,
            TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 2,
        }, card)

        local statusLabel = mk("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.fromOffset(86, 60),
            Size = UDim2.new(1, -102, 0, 18), Font = Enum.Font.GothamMedium,
            Text = "Starting...", TextSize = 12, TextColor3 = C.muted, ZIndex = 2,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        }, card)

        -- ── Progress bar ──
        local trackFrame = mk("Frame", {
            Position = UDim2.fromOffset(16, 94), Size = UDim2.new(1, -32, 0, 6),
            BackgroundColor3 = C.track, BorderSizePixel = 0, ZIndex = 2,
        }, card)
        mk("UICorner", { CornerRadius = UDim.new(1, 0) }, trackFrame)
        local fillFrame = mk("Frame", {
            Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 3,
        }, trackFrame)
        mk("UICorner", { CornerRadius = UDim.new(1, 0) }, fillFrame)
        local fillGrad = mk("UIGradient", { Color = grad2(C.accentA, C.accentB) }, fillFrame)

        -- Shine sweep — TweenService loop, runs off heartbeat
        local shineFrame = mk("Frame", {
            Size = UDim2.new(0.32, 0, 1, 0), Position = UDim2.new(-0.32, 0, 0, 0),
            BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 4,
        }, fillFrame)
        mk("UIGradient", {
            Transparency = NumberSequence.new({ NSK(0, 1), NSK(0.5, 0.48), NSK(1, 1) }),
        }, shineFrame)

        -- Spark dot
        local sparkDot = mk("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.fromOffset(10, 10), BackgroundColor3 = C.accentB,
            BackgroundTransparency = 0.15, BorderSizePixel = 0, ZIndex = 4, Visible = false,
        }, trackFrame)
        mk("UICorner", { CornerRadius = UDim.new(1, 0) }, sparkDot)

        -- ── Footer ──
        local lp = Players.LocalPlayer
        mk("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 110),
            Size = UDim2.new(0.65, -16, 0, 16), Font = Enum.Font.Gotham, TextSize = 11,
            TextColor3 = C.muted, ZIndex = 2,
            Text = lp and ("Welcome, " .. lp.DisplayName) or "Welcome",
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        }, card)
        local timeLbl = mk("TextLabel", {
            BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -16, 0, 110), Size = UDim2.new(0.35, -16, 0, 16),
            Font = Enum.Font.GothamMedium, Text = "0:00", TextSize = 11,
            TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 2,
        }, card)

        if not attach(gui) then error("no valid GUI parent") end

        -- ── TweenService loops (off heartbeat, GPU-side on Roblox) ──
        -- Ring rotation: smooth, no heartbeat cost
        TweenService:Create(ringGrad,
            TweenInfo.new(1.4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
            { Rotation = 360 }):Play()
        -- Shine sweep: slow back-and-forth
        TweenService:Create(shineFrame,
            TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            { Position = UDim2.new(1, 0, 0, 0) }):Play()

        -- Card entrance: scale + fade
        tw(uiScale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        if cardClass == "CanvasGroup" then
            tw(card, 0.22, { GroupTransparency = 0 }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end

        -- ── State ──
        local state, target, creep, shown = "running", 0, 0, 0
        local closing, conn = false, nil
        local lastSec = -1
        local bornC = os.clock()
        local curStage = "wifi"
        local accentA, accentB = C.accentA, C.accentB

        local function setStage(name)
            if curStage == name then return end
            curStage = name
            stageIcon.Image = ICON[name] or ICON.wifi
            stageIcon.ImageColor3 = accentB
        end

        local function paint(a, b)
            accentA, accentB = a, b
            fillGrad.Color = grad2(a, b)
            ringGrad.Color = grad2(a, b)
            sparkDot.BackgroundColor3 = b
            stageIcon.ImageColor3 = b
        end

        -- ── Heartbeat: minimal updates only ──
        conn = RunService.Heartbeat:Connect(function(dt)
            dt = math.min(dt, 0.1)

            -- Progress lerp
            local goal
            if state == "running" then
                creep = math.min(creep + dt * 0.6, 5)
                goal = math.min(97, target + creep)
            elseif state == "done" then
                goal = 100
            else
                goal = shown
            end
            shown = shown + (goal - shown) * math.min(1, dt * 7)
            local frac = math.clamp(shown / 100, 0, 1)
            fillFrame.Size = UDim2.new(frac, 0, 1, 0)
            pctLabel.Text = math.floor(shown + 0.5) .. "%"
            sparkDot.Position = UDim2.new(frac, 0, 0.5, 0)
            sparkDot.Visible = (state == "running" and shown > 1) or state == "done"

            -- Stage icon (no tween, instant swap)
            if state == "running" then
                setStage(shown < 28 and "wifi" or shown < 62 and "shield" or "download")
            end

            -- Timer (only on second boundary)
            local sec = math.floor(os.clock() - bornC)
            if sec ~= lastSec then
                lastSec = sec
                timeLbl.Text = string.format("%d:%02d", math.floor(sec / 60), sec % 60)
            end
        end)

        local function setStatus(text)
            text = (tostring(text or ""):gsub("[\r\n]+", " ")):match("^%s*(.-)%s*$") or ""
            if text == "" then return end
            -- strip emoji tokens silently
            text = text:gsub("[\u{2714}\u{2713}\u{2705}\u{2718}\u{274C}\u{26A1}\u{26A0}\u{23F3}\u{1F511}]", "")
                       :gsub("\u{FE0F}", ""):match("^%s*(.-)%s*$") or text
            if statusLabel.Text == text then return end
            statusLabel.Text = text
            statusLabel.TextTransparency = 0.75
            tw(statusLabel, 0.18, { TextTransparency = 0 })
        end

        local function close()
            if closing then return end
            closing = true
            state = "closed"
            tw(uiScale, 0.25, { Scale = 0.93 })
            if cardClass == "CanvasGroup" then
                tw(card, 0.25, { GroupTransparency = 1 })
            end
            task.delay(0.32, function()
                pcall(function() conn:Disconnect() end)
                pcall(function() gui:Destroy() end)
            end)
        end

        local born = os.time()
        local A = {}

        function A.Set(p, text)
            if state ~= "running" then return end
            if type(p) == "number" then target = math.clamp(p, target, 99); creep = 0 end
            setStatus(text)
        end

        function A.Log(text, kind)
            if kind == "error" then return A.Fail(text) end
            if kind == "done"  then return A.Done(text) end
            if state ~= "running" then return end
            target = target + (92 - target) * 0.18; creep = 0
            setStatus(text)
        end

        function A.Done(text)
            if state ~= "running" then return end
            state = "done"
            setStatus(text or "Loaded")
            paint(C.ok, C.okB)
            ringGrad.Transparency = NumberSequence.new(0)
            curStage = "check"; stageIcon.Image = ICON.check; stageIcon.ImageColor3 = C.ok
            -- subtle scale bump, then settle
            tw(uiScale, 0.12, { Scale = 1.04 }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            task.delay(0.12, function()
                tw(uiScale, 0.18, { Scale = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            end)
            task.delay(1.1, close)
        end

        function A.Fail(text)
            if state ~= "running" then return end
            state = "error"
            setStatus(text or "Failed")
            statusLabel.TextColor3 = C.err
            paint(C.err, C.errB)
            ringGrad.Transparency = NumberSequence.new(0)
            curStage = "x"; stageIcon.Image = ICON.x; stageIcon.ImageColor3 = C.err
            -- 3-step tween shake (no heartbeat needed)
            tw(card, 0.055, { Position = UDim2.new(0.5, -9, 0.5, 0) }, Enum.EasingStyle.Quad)
            task.delay(0.055, function()
                tw(card, 0.055, { Position = UDim2.new(0.5, 9, 0.5, 0) }, Enum.EasingStyle.Quad)
                task.delay(0.055, function()
                    tw(card, 0.08, { Position = UDim2.new(0.5, 0, 0.5, 0) }, Enum.EasingStyle.Quad)
                end)
            end)
            task.delay(4, close)
        end

        function A.Close(onlyIfRunning)
            if onlyIfRunning and state ~= "running" then return end
            close()
        end

        function A.IsRunning()
            return state == "running" and gui.Parent ~= nil and (os.time() - born) < 65
        end

        task.delay(60, close) -- fail-safe
        return A
    end)

    if not built then
        warn("[ SpectreWare Gateway ]: Loader UI unavailable — " .. tostring(api))
        return NOOP
    end
    return api
end)()
if not _prevAlive then pcall(function() getgenv()._SW_LOADER = LOADER end) end

-- ── Fetch whitelist.lua ──────────────────────────────────────────────────────
print("[ SpectreWare Gateway ]: Initializing...")
LOADER.Set(4, "Initializing...")

local ok, src
for i = 1, CFG.maxRetries do
    LOADER.Set(6 + i * 6, ("Connecting to server... (%d/%d)"):format(i, CFG.maxRetries))
    ok, src = safeGetTimeout(CFG.whitelistUrl, CFG.timeout)
    if ok and src and #src > 32 then break end
    warn(("[ SpectreWare Gateway ]: fetch attempt %d/%d failed"):format(i, CFG.maxRetries))
    if i < CFG.maxRetries then task.wait(CFG.retryBackoff * i) end
end

if not ok or not src or #src < 32 then
    warn("[ SpectreWare Gateway ]: Failed to fetch whitelist.lua after " .. CFG.maxRetries .. " attempts.")
    LOADER.Fail("Can't reach server — try again")
    _releaseGuard()
    return
end
LOADER.Set(30, "Loader ready")

-- ── Compile & run ─────────────────────────────────────────────────────────────
local fn, compErr = loadstring(src)
src = nil
if not fn then
    warn("[ SpectreWare Gateway ]: Compile error — " .. tostring(compErr))
    LOADER.Fail("Loader compile error")
    _releaseGuard()
    return
end

local _gOk = pcall(function() getgenv()._SW_PLACE_MAP = PLACE_MAP end)
if not _gOk then
    warn("[ SpectreWare Gateway ]: getgenv() unavailable — PLACE_MAP override disabled")
end

local runOk, runErr = pcall(fn)
if not runOk then
    warn("[ SpectreWare Gateway ]: Runtime error — " .. tostring(runErr))
    LOADER.Fail("Runtime error — check console (F9)")
    _releaseGuard()
else
    LOADER.Close(true) -- whitelist จบโดยไม่ได้ Done/Fail (เช่น ถูก kick/duplicate) → ปิดการ์ดเงียบๆ
end
