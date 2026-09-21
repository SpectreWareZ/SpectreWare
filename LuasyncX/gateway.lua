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
     ["77908479907662"] = "https://raw.githubusercontent.com/Captaineieiei/Script-/refs/heads/main/Never",
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
    local ticks, max = 0, math.max(1, math.floor(timeout * 20))
    while not done and ticks < max do
        task.wait(0.05)
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
    local ticks, max = 0, timeout * 20
    while not done and ticks < max do task.wait(0.05); ticks = ticks + 1 end
    if not done then pcall(task.cancel, co) end
    return done and ok or false, done and body or nil
end

-- ── Double-execute guard (gateway-level, before any fetch) ──────────────────
-- Prevents wasting an HTTP round-trip when the gateway itself gets invoked
-- twice in quick succession (autoexec + manual run, double-bound hotkey,
-- UI button without debounce, etc). This is separate from whitelist.lua's
-- own guard, which only catches it *after* the fetch+decrypt already ran.
do
    local gev = getgenv()
    if gev._SW_GW_RUNNING and (os.time() - (gev._SW_GW_STIME or 0)) < 10 then
        warn("[ SpectreWare Gateway ]: already running — skipping duplicate invocation")
        return
    end
    gev._SW_GW_RUNNING = true
    gev._SW_GW_STIME = os.time()
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
            bg      = Color3.fromRGB(20, 20, 27),
            track   = Color3.fromRGB(38, 38, 50),
            stroke  = Color3.fromRGB(60, 60, 75),
            text    = Color3.fromRGB(215, 215, 228),
            muted   = Color3.fromRGB(130, 130, 150),
            accentA = Color3.fromRGB(150, 110, 255),
            accentB = Color3.fromRGB(90, 160, 250),
            ok      = Color3.fromRGB(80, 220, 130),
            err     = Color3.fromRGB(235, 70, 70),
        }

        local function mk(cls, props, parent)
            local i = Instance.new(cls)
            for k, v in pairs(props) do pcall(function() i[k] = v end) end
            i.Parent = parent
            return i
        end

        local function attach(gui)
            pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
            local parents = {}
            local okH, hui = pcall(function() return gethui and gethui() end)
            if okH and typeof(hui) == "Instance" then parents[#parents + 1] = hui end
            local okC, core = pcall(function() return cr(game:GetService("CoreGui")) end)
            if okC and core then parents[#parents + 1] = core end
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

        -- ── build ──
        local gui = mk("ScreenGui", {
            Name = "SW_LoaderGui", ResetOnSpawn = false, IgnoreGuiInset = true,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 998,
        })

        local cardClass = pcall(Instance.new, "CanvasGroup") and "CanvasGroup" or "Frame"
        local card = mk(cardClass, {
            Name = "Card", Size = UDim2.new(0.86, 0, 0, 116),
            Position = UDim2.new(0.5, 0, 0.5, 14), AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = C.bg, BorderSizePixel = 0, GroupTransparency = 1,
        }, gui)
        mk("UISizeConstraint", { MaxSize = Vector2.new(340, 116), MinSize = Vector2.new(220, 116) }, card)
        mk("UICorner", { CornerRadius = UDim.new(0, 12) }, card)
        mk("UIStroke", { Color = C.stroke, Thickness = 1, Transparency = 0.4 }, card)

        local topLine = mk("Frame", {
            Size = UDim2.new(1, 0, 0, 3), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
        }, card)
        mk("UIGradient", { Color = ColorSequence.new(C.accentA, C.accentB) }, topLine)

        local title = mk("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 12), Size = UDim2.new(0.6, 0, 0, 20),
            Font = Enum.Font.GothamBlack, Text = "SPECTREWARE", TextSize = 15,
            TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left,
        }, card)
        mk("UIGradient", { Color = ColorSequence.new(C.accentA, C.accentB) }, title)

        mk("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0, 12), Size = UDim2.new(0.5, -16, 0, 20),
            Font = Enum.Font.GothamMedium, Text = "LuaSyncX", TextSize = 11, TextColor3 = C.muted,
            TextXAlignment = Enum.TextXAlignment.Right,
        }, card)

        local dot = mk("Frame", {
            Position = UDim2.fromOffset(16, 47), Size = UDim2.fromOffset(8, 8),
            BackgroundColor3 = C.accentB, BorderSizePixel = 0,
        }, card)
        mk("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)

        local status = mk("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.fromOffset(32, 41), Size = UDim2.new(1, -48, 0, 20),
            Font = Enum.Font.GothamMedium, Text = "Starting...", TextSize = 13, TextColor3 = C.text,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        }, card)

        local track = mk("Frame", {
            Position = UDim2.fromOffset(16, 72), Size = UDim2.new(1, -32, 0, 6),
            BackgroundColor3 = C.track, BorderSizePixel = 0,
        }, card)
        mk("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
        local fill = mk("Frame", {
            Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
        }, track)
        mk("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
        local fillGrad = mk("UIGradient", { Color = ColorSequence.new(C.accentA, C.accentB) }, fill)

        local lp = Players.LocalPlayer
        mk("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 88), Size = UDim2.new(0.7, -16, 0, 16),
            Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.muted,
            Text = lp and ("Welcome, " .. lp.DisplayName) or "Welcome",
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        }, card)
        local pct = mk("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.new(0.7, 0, 0, 88), Size = UDim2.new(0.3, -16, 0, 16),
            Font = Enum.Font.GothamBold, Text = "0%", TextSize = 11, TextColor3 = C.text,
            TextXAlignment = Enum.TextXAlignment.Right,
        }, card)

        if not attach(gui) then error("no valid GUI parent") end

        -- ── state ──
        local state, target, creep, shown = "running", 0, 0, 0
        local conn, pulse

        pcall(function()
            pulse = TweenService:Create(dot,
                TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                { BackgroundTransparency = 0.75 })
            pulse:Play()
        end)
        pcall(function()
            TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                { GroupTransparency = 0, Position = UDim2.new(0.5, 0, 0.5, 0) }):Play()
        end)

        conn = RunService.Heartbeat:Connect(function(dt)
            local goal
            if state == "running" then
                creep = math.min(creep + dt * 0.6, 5) -- ขยับเองนิดๆ ไม่ให้บาร์ดูค้าง
                goal = math.min(97, target + creep)
            elseif state == "done" then
                goal = 100
            else
                goal = shown
            end
            shown = shown + (goal - shown) * math.min(1, dt * 7)
            fill.Size = UDim2.new(math.clamp(shown / 100, 0, 1), 0, 1, 0)
            pct.Text = math.floor(shown + 0.5) .. "%"
        end)

        local function setStatus(text)
            text = (tostring(text or ""):gsub("[\r\n]+", " "))
            if text ~= "" then status.Text = text end
        end

        local function paint(color)
            fillGrad.Color = ColorSequence.new(color)
            dot.BackgroundColor3 = color
            pcall(function() if pulse then pulse:Cancel() end end)
            dot.BackgroundTransparency = 0
        end

        local function close()
            if state == "closed" then return end
            state = "closed"
            pcall(function() conn:Disconnect() end)
            pcall(function()
                TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                    { GroupTransparency = 1, Position = UDim2.new(0.5, 0, 0.5, 10) }):Play()
            end)
            task.delay(0.35, function() pcall(function() gui:Destroy() end) end)
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
            paint(C.ok)
            task.delay(1.1, close)
        end
        function A.Fail(text)
            if state ~= "running" then return end
            state = "error"
            setStatus(text or "Failed")
            status.TextColor3 = C.err
            paint(C.err)
            task.delay(4, close)
        end
        function A.Close(onlyIfRunning)
            if onlyIfRunning and state ~= "running" then return end
            close()
        end
        function A.IsRunning()
            return state == "running" and gui.Parent ~= nil and (os.time() - born) < 65
        end

        task.delay(60, close) -- fail-safe: ไม่ให้ UI ค้างจอถ้าเกิดอะไรผิดปกติ
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
    return
end
LOADER.Set(30, "Loader ready")

-- ── Compile & run ─────────────────────────────────────────────────────────────
local fn, compErr = loadstring(src)
src = nil
if not fn then
    warn("[ SpectreWare Gateway ]: Compile error — " .. tostring(compErr))
    LOADER.Fail("Loader compile error")
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
else
    LOADER.Close(true) -- whitelist จบโดยไม่ได้ Done/Fail (เช่น ถูก kick/duplicate) → ปิดการ์ดเงียบๆ
end
