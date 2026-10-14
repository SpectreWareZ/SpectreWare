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
    -- ย้ายไปอยู่ฝั่ง server แล้ว (place_scripts.json / env PLACE_SCRIPTS)
    -- ไม่ฝัง URL สคริปต์ในไฟล์ public นี้อีก — server ส่งให้แบบเข้ารหัสหลังตรวจ key+HWID เท่านั้น
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

        -- พาเลตต์: ดำ/เทาถ่าน + ม่วงเป็นสีเน้นสีเดียว (ใช้แค่ที่โลโก้, X ในชื่อ, แถบ progress)
        local C = {
            bg      = Color3.fromRGB(16, 16, 19),
            edge    = Color3.fromRGB(40, 40, 47),
            track   = Color3.fromRGB(34, 34, 40),
            text    = Color3.fromRGB(232, 232, 236),
            muted   = Color3.fromRGB(116, 116, 128),
            accent  = Color3.fromRGB(124, 92, 224),
            err     = Color3.fromRGB(222, 82, 82),
            white   = Color3.new(1, 1, 1),
            black   = Color3.new(0, 0, 0),
        }
        local ACCENT_HEX = "rgb(124,92,224)"

        local function mk(cls, props, parent)
            local i = Instance.new(cls)
            for k, v in pairs(props) do pcall(function() i[k] = v end) end
            i.Parent = parent
            return i
        end

        local function tw(obj, dur, props, style, dir)
            local t = TweenService:Create(obj,
                TweenInfo.new(dur, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
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

        -- ── Fade registry ──────────────────────────────────────────────────────
        -- ไม่ใช้ CanvasGroup (บนมือถือ/บาง executor เรนเดอร์ไม่ขึ้น) จึงเฟดทีละ property แทน
        local fades = {}
        local function reg(obj, prop, visible)
            fades[#fades + 1] = { obj, prop, visible }
            pcall(function() obj[prop] = 1 end)
            return obj
        end
        local function fadeTo(show, dur, style, dir)
            for _, f in ipairs(fades) do
                tw(f[1], dur, { [f[2]] = show and f[3] or 1 }, style, dir)
            end
        end

        -- ── Build ──────────────────────────────────────────────────────────────
        local H = 120
        local gui = mk("ScreenGui", {
            Name = "SW_LoaderGui", ResetOnSpawn = false, IgnoreGuiInset = true,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 998,
        })

        -- root: จัดกลางจอ กว้างตามจอแต่ล็อกช่วง 240–340px ไม่ล้นจอเล็ก ไม่ใหญ่เกินบน PC
        local root = mk("Frame", {
            Name = "Root", Size = UDim2.new(0.88, 0, 0, H), BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 10),
        }, gui)
        mk("UISizeConstraint", { MinSize = Vector2.new(240, H), MaxSize = Vector2.new(340, H) }, root)

        -- เงาแบบเรียบ: เฟรมดำโปร่งหลังการ์ด ไม่มี glow
        local shadow = reg(mk("Frame", {
            Position = UDim2.new(0, -2, 0, 3), Size = UDim2.new(1, 4, 1, 4),
            BackgroundColor3 = C.black, BorderSizePixel = 0, ZIndex = 1,
        }, root), "BackgroundTransparency", 0.6)
        mk("UICorner", { CornerRadius = UDim.new(0, 8) }, shadow)

        local card = reg(mk("Frame", {
            Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.bg, BorderSizePixel = 0, ZIndex = 2,
        }, root), "BackgroundTransparency", 0)
        mk("UICorner", { CornerRadius = UDim.new(0, 8) }, card)
        reg(mk("UIStroke", { Color = C.edge, Thickness = 1 }, card), "Transparency", 0)

        -- โลโก้: สี่เหลี่ยมม่วงทึบ + ตัว S (ไม่พึ่ง asset ภายนอก เรนเดอร์ได้ทุก executor)
        local logo = reg(mk("Frame", {
            Position = UDim2.fromOffset(18, 18), Size = UDim2.fromOffset(30, 30),
            BackgroundColor3 = C.accent, BorderSizePixel = 0, ZIndex = 3,
        }, card), "BackgroundTransparency", 0)
        mk("UICorner", { CornerRadius = UDim.new(0, 7) }, logo)
        reg(mk("TextLabel", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 4,
            Font = Enum.Font.GothamBold, Text = "S", TextSize = 18, TextColor3 = C.white,
        }, logo), "TextTransparency", 0)

        -- ชื่อโปรดักต์: "LuaSync" ขาว + "X" ม่วง ; บรรทัดเล็กใต้ชื่อบอกผู้ทำ
        reg(mk("TextLabel", {
            Position = UDim2.fromOffset(58, 16), Size = UDim2.new(1, -140, 0, 18), BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = C.text, RichText = true, ZIndex = 3,
            Text = 'LuaSync<font color="' .. ACCENT_HEX .. '">X</font>',
            TextXAlignment = Enum.TextXAlignment.Left,
        }, card), "TextTransparency", 0)
        reg(mk("TextLabel", {
            Position = UDim2.fromOffset(58, 34), Size = UDim2.new(1, -140, 0, 14), BackgroundTransparency = 1,
            Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = C.muted, ZIndex = 3,
            Text = "SpectreWare", TextXAlignment = Enum.TextXAlignment.Left,
        }, card), "TextTransparency", 0)

        local pctLabel = reg(mk("TextLabel", {
            AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 20), Size = UDim2.fromOffset(60, 20),
            BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 14, TextColor3 = C.text, ZIndex = 3,
            Text = "0%", TextXAlignment = Enum.TextXAlignment.Right,
        }, card), "TextTransparency", 0)

        local statusLabel = reg(mk("TextLabel", {
            Position = UDim2.fromOffset(18, 62), Size = UDim2.new(1, -36, 0, 18), BackgroundTransparency = 1,
            Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.text, ZIndex = 3,
            Text = "Initializing...", TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, card), "TextTransparency", 0)

        -- progress: บาง 3px เหลี่ยมนิด ๆ สีทึบ ไม่มี gradient/shine
        local track = reg(mk("Frame", {
            Position = UDim2.new(0, 18, 0, 87), Size = UDim2.new(1, -36, 0, 3),
            BackgroundColor3 = C.track, BorderSizePixel = 0, ZIndex = 3,
        }, card), "BackgroundTransparency", 0)
        mk("UICorner", { CornerRadius = UDim.new(0, 2) }, track)
        local fill = reg(mk("Frame", {
            Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = C.accent, BorderSizePixel = 0, ZIndex = 4,
        }, track), "BackgroundTransparency", 0)
        mk("UICorner", { CornerRadius = UDim.new(0, 2) }, fill)

        -- บรรทัดรอง: ว่างไว้ แสดงเฉพาะตอนค้างนานหรือมี error
        local noteLabel = reg(mk("TextLabel", {
            Position = UDim2.fromOffset(18, 96), Size = UDim2.new(1, -36, 0, 14), BackgroundTransparency = 1,
            Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.muted, ZIndex = 3,
            Text = "", TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        }, card), "TextTransparency", 0)

        if not attach(gui) then error("no valid GUI parent") end

        -- เข้า: เฟด + เลื่อนขึ้น 10px (ไม่มี overshoot/เด้ง)
        fadeTo(true, 0.2)
        tw(root, 0.2, { Position = UDim2.new(0.5, 0, 0.5, 0) })

        -- ── State ──────────────────────────────────────────────────────────────
        -- progress มาจาก Set()/Log() ของ whitelist.lua จริง ๆ เท่านั้น (ไม่มี creep ปลอมแล้ว)
        local state, target, shown = "running", 0, 0
        local closing, conn = false, nil
        local lastChange, lastNoteSec = os.clock(), -1
        local STALL_AFTER = 6

        conn = RunService.Heartbeat:Connect(function(dt)
            dt = math.min(dt, 0.1)
            local goal = (state == "done") and 100 or target
            shown = shown + (goal - shown) * math.min(1, dt * 8)
            if math.abs(goal - shown) < 0.05 then shown = goal end
            fill.Size = UDim2.new(math.clamp(shown / 100, 0, 1), 0, 1, 0)
            pctLabel.Text = math.floor(shown + 0.5) .. "%"

            -- ค้างนานเกิน STALL_AFTER วิ → แจ้งว่ายังทำงานอยู่ (อัปเดตทุกวินาที ไม่ใช่ทุกเฟรม)
            if state == "running" then
                local idle = os.clock() - lastChange
                local sec = idle >= STALL_AFTER and math.floor(idle) or -1
                if sec ~= lastNoteSec then
                    lastNoteSec = sec
                    noteLabel.Text = sec >= 0 and ("Waiting for response · " .. sec .. "s") or ""
                end
            end
        end)

        local function setStatus(text)
            text = (tostring(text or ""):gsub("[\r\n]+", " ")):match("^%s*(.-)%s*$") or ""
            if text == "" then return end
            text = text:gsub("[\u{2714}\u{2713}\u{2705}\u{2718}\u{274C}\u{26A1}\u{26A0}\u{23F3}\u{1F511}]", "")
                       :gsub("\u{FE0F}", ""):match("^%s*(.-)%s*$") or text
            if statusLabel.Text ~= text then statusLabel.Text = text end
        end

        local function close()
            if closing then return end
            closing = true
            state = "closed"
            fadeTo(false, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            tw(root, 0.2, { Position = UDim2.new(0.5, 0, 0.5, 6) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            task.delay(0.26, function()
                pcall(function() conn:Disconnect() end)
                pcall(function() gui:Destroy() end)
            end)
        end

        local born = os.time()
        local A = {}

        function A.Set(p, text)
            if state ~= "running" then return end
            if type(p) == "number" then target = math.clamp(p, target, 99) end
            lastChange = os.clock()
            setStatus(text)
        end

        -- Log ไม่มีเปอร์เซ็นต์มาให้ → ขยับเข้าใกล้ 92% ทีละขั้นตามจำนวนขั้นตอนที่ผ่านจริง
        function A.Log(text, kind)
            if kind == "error" then return A.Fail(text) end
            if kind == "done"  then return A.Done(text) end
            if state ~= "running" then return end
            target = target + (92 - target) * 0.18
            lastChange = os.clock()
            setStatus(text)
        end

        function A.Done(text)
            if state ~= "running" then return end
            state = "done"
            noteLabel.Text = ""
            setStatus(text or "Loaded")
            task.delay(0.8, close)
        end

        function A.Fail(text)
            if state ~= "running" then return end
            state = "error"
            setStatus(text or "Failed")
            statusLabel.TextColor3 = C.err
            fill.BackgroundColor3 = C.err
            pctLabel.TextColor3 = C.err
            noteLabel.Text = "Run the script again to retry"
            -- สั่นแนวนอนเบา ๆ สามจังหวะ
            local function x(px, d) tw(root, d, { Position = UDim2.new(0.5, px, 0.5, 0) }) end
            x(-5, 0.05)
            task.delay(0.05, function()
                x(5, 0.05)
                task.delay(0.05, function() x(0, 0.07) end)
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

        task.delay(60, close) -- fail-safe: ไม่ให้ค้างบนจอ
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
