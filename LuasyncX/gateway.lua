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
            bg      = Color3.fromRGB(14, 14, 20),
            inset   = Color3.fromRGB(22, 22, 31),
            track   = Color3.fromRGB(34, 34, 46),
            stroke  = Color3.fromRGB(60, 60, 78),
            text    = Color3.fromRGB(236, 236, 246),
            muted   = Color3.fromRGB(126, 126, 150),
            accentA = Color3.fromRGB(150, 110, 255),
            accentB = Color3.fromRGB(90, 160, 250),
            ok      = Color3.fromRGB(80, 220, 130),
            okB     = Color3.fromRGB(60, 190, 210),
            err     = Color3.fromRGB(240, 84, 84),
            errB    = Color3.fromRGB(255, 140, 60),
            warn    = Color3.fromRGB(250, 190, 60),
            bolt    = Color3.fromRGB(255, 214, 10),
            white   = Color3.new(1, 1, 1),
        }

        -- ไอคอน Lucide (asset id ชุดเดียวกับ Icons.lua) — ไม่พึ่ง emoji/font glyph
        local ICON = {
            wifi        = "rbxassetid://10747382504",
            shield      = "rbxassetid://10734951847",
            download    = "rbxassetid://10723344270",
            check       = "rbxassetid://10709790644",
            x           = "rbxassetid://10747384394",
            checkCircle = "rbxassetid://10709790387",
            xCircle     = "rbxassetid://10747383819",
            alert       = "rbxassetid://10709753149",
            hourglass   = "rbxassetid://10723407498",
            key         = "rbxassetid://10723416652",
            rocket      = "rbxassetid://10734934585",
        }
        local ICON_COLORS = {
            checkCircle = C.ok, xCircle = C.err, rocket = C.bolt,
            alert = C.warn, hourglass = C.warn, key = C.accentA,
        }

        local function mk(cls, props, parent)
            local i = Instance.new(cls)
            for k, v in pairs(props) do pcall(function() i[k] = v end) end
            i.Parent = parent
            return i
        end

        -- token → ชื่อไอคอน: whitelist.lua อาจส่งข้อความที่มีสัญลักษณ์หลุดมา (เช่น "✓")
        -- ตัดออกจากข้อความแล้วโชว์เป็นไอคอน Lucide เล็ก ๆ หน้าข้อความแทน
        local ICON_TOKENS = {
            { "\u{2714}", "checkCircle" }, { "\u{2713}", "checkCircle" }, { "\u{2705}", "checkCircle" },
            { "\u{2718}", "xCircle" },     { "\u{274C}", "xCircle" },
            { "\u{26A1}", "rocket" },
            { "\u{26A0}", "alert" },
            { "\u{23F3}", "hourglass" },   { "\u{231B}", "hourglass" },
            { "\u{1F511}", "key" },
        }
        local VS16 = "\u{FE0F}"

        local function extractIcon(text)
            local bs, be, bn
            for _, pair in ipairs(ICON_TOKENS) do
                local s, e = string.find(text, pair[1], 1, true)
                if s and (not bs or s < bs) then bs, be, bn = s, e, pair[2] end
            end
            if not bs then return text, nil end
            if text:sub(be + 1, be + #VS16) == VS16 then be = be + #VS16 end
            local out = text:sub(1, bs - 1) .. text:sub(be + 1)
            out = out:gsub("%s%s+", " "):match("^%s*(.-)%s*$")
            return out, bn
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

        local CSK, NSK = ColorSequenceKeypoint.new, NumberSequenceKeypoint.new
        local function grad2(a, b) return ColorSequence.new(a, b) end

        -- ── build ──────────────────────────────────────────────────────────────
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
        mk("UICorner", { CornerRadius = UDim.new(0, 16) }, card)
        local uiScale = mk("UIScale", { Scale = 0.86 }, card)

        -- เส้นขอบเรืองแสงวิ่งรอบการ์ด (UIGradient บน UIStroke หมุนตลอด)
        local borderStroke = mk("UIStroke", { Color = C.white, Thickness = 1.5, Transparency = 0 }, card)
        local borderGrad = mk("UIGradient", {
            Color = grad2(C.accentA, C.accentB),
            Transparency = NumberSequence.new({ NSK(0, 0.72), NSK(0.12, 0), NSK(0.32, 0.72), NSK(1, 0.72) }),
        }, borderStroke)

        -- ชั้นเอฟเฟกต์ด้านหลัง: แสงฟุ้ง + อนุภาคลอยขึ้น
        local fx = mk("Frame", {
            BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 1, ClipsDescendants = true,
        }, card)
        local glow = mk("Frame", {
            Size = UDim2.fromOffset(220, 220), Position = UDim2.fromOffset(-60, -80),
            BackgroundColor3 = C.accentA, BackgroundTransparency = 0.9, BorderSizePixel = 0, ZIndex = 1,
        }, fx)
        mk("UICorner", { CornerRadius = UDim.new(1, 0) }, glow)

        local parts = {}
        for i = 1, 11 do
            local sz = math.random(2, 4)
            local f = mk("Frame", {
                Size = UDim2.fromOffset(sz, sz), BackgroundColor3 = C.accentB,
                BackgroundTransparency = 0.8, BorderSizePixel = 0, ZIndex = 1,
            }, fx)
            mk("UICorner", { CornerRadius = UDim.new(1, 0) }, f)
            parts[i] = { f = f, x = math.random(), y = math.random(), v = 0.05 + math.random() * 0.12,
                         w = 1 + math.random() * 2, ph = math.random() * 6.28 }
        end

        -- ── Badge: วงแหวนหมุน + ไอคอนตามขั้นตอน ──
        local badge = mk("Frame", {
            Position = UDim2.fromOffset(16, 24), Size = UDim2.fromOffset(52, 52),
            BackgroundTransparency = 1, ZIndex = 2,
        }, card)
        local ringTrack = mk("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2 }, badge)
        mk("UICorner", { CornerRadius = UDim.new(1, 0) }, ringTrack)
        mk("UIStroke", { Color = C.track, Thickness = 3 }, ringTrack)
        local ring = mk("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 3 }, badge)
        mk("UICorner", { CornerRadius = UDim.new(1, 0) }, ring)
        mk("UIStroke", { Color = C.white, Thickness = 3 }, ring)
        local ringGrad = mk("UIGradient", {
            Color = grad2(C.accentA, C.accentB),
            Transparency = NumberSequence.new({ NSK(0, 0), NSK(0.5, 0.25), NSK(0.75, 1), NSK(1, 1) }),
        }, ring:FindFirstChildOfClass("UIStroke"))
        local core = mk("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(40, 40), BackgroundColor3 = C.inset, BorderSizePixel = 0, ZIndex = 3,
        }, badge)
        mk("UICorner", { CornerRadius = UDim.new(1, 0) }, core)
        local stageIcon = mk("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1,
            Image = ICON.wifi, ImageColor3 = C.accentB, ScaleType = Enum.ScaleType.Fit, ZIndex = 4,
        }, core)

        -- ── ข้อความ ──
        local title = mk("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.fromOffset(84, 22), Size = UDim2.new(1, -170, 0, 22),
            Font = Enum.Font.GothamBlack, Text = "SPECTREWARE", TextSize = 17, ZIndex = 2,
            TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left,
        }, card)
        local titleGrad = mk("UIGradient", {
            Color = ColorSequence.new({
                CSK(0, C.accentA), CSK(0.42, C.accentA), CSK(0.5, Color3.fromRGB(255, 255, 255)),
                CSK(0.58, C.accentB), CSK(1, C.accentB),
            }),
        }, title)
        pcall(function() title.MaxVisibleGraphemes = 0 end)

        mk("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.fromOffset(84, 43), Size = UDim2.new(1, -170, 0, 14),
            Font = Enum.Font.GothamMedium, Text = "LuaSyncX", TextSize = 11, TextColor3 = C.muted, ZIndex = 2,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, card)

        local pct = mk("TextLabel", {
            BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 20),
            Size = UDim2.fromOffset(74, 26), Font = Enum.Font.GothamBold, Text = "0%", TextSize = 21,
            TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 2,
        }, card)

        local statusRow = mk("Frame", {
            BackgroundTransparency = 1, Position = UDim2.fromOffset(84, 62), Size = UDim2.new(1, -100, 0, 20), ZIndex = 2,
        }, card)
        local sIcon = mk("ImageLabel", {
            BackgroundTransparency = 1, Visible = false, Position = UDim2.fromOffset(0, 3),
            Size = UDim2.fromOffset(14, 14), ScaleType = Enum.ScaleType.Fit, ZIndex = 2,
        }, statusRow)
        local status = mk("TextLabel", {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Font = Enum.Font.GothamMedium,
            Text = "Starting...", TextSize = 13, TextColor3 = C.text, ZIndex = 2,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        }, statusRow)

        -- ── Progress bar: เส้นไหลแสง + ประกายที่ปลายบาร์ ──
        local track = mk("Frame", {
            Position = UDim2.fromOffset(16, 96), Size = UDim2.new(1, -32, 0, 8),
            BackgroundColor3 = C.track, BorderSizePixel = 0, ZIndex = 2,
        }, card)
        mk("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
        local fill = mk("Frame", {
            Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
            ClipsDescendants = true, ZIndex = 3,
        }, track)
        mk("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
        local fillGrad = mk("UIGradient", { Color = grad2(C.accentA, C.accentB) }, fill)
        local shine = mk("Frame", {
            Size = UDim2.new(0.4, 0, 1, 0), Position = UDim2.new(-0.4, 0, 0, 0),
            BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 4,
        }, fill)
        mk("UIGradient", {
            Transparency = NumberSequence.new({ NSK(0, 1), NSK(0.5, 0.45), NSK(1, 1) }),
        }, shine)
        local sparkOuter = mk("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(22, 22),
            BackgroundColor3 = C.accentB, BackgroundTransparency = 0.8, BorderSizePixel = 0, ZIndex = 4,
        }, track)
        mk("UICorner", { CornerRadius = UDim.new(1, 0) }, sparkOuter)
        local sparkInner = mk("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(10, 10),
            BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.05, BorderSizePixel = 0, ZIndex = 5,
        }, sparkOuter)
        mk("UICorner", { CornerRadius = UDim.new(1, 0) }, sparkInner)

        -- ── Footer ──
        local lp = Players.LocalPlayer
        mk("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 112), Size = UDim2.new(0.65, -16, 0, 16),
            Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.muted, ZIndex = 2,
            Text = lp and ("Welcome, " .. lp.DisplayName) or "Welcome",
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        }, card)
        local timeLbl = mk("TextLabel", {
            BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 112),
            Size = UDim2.new(0.35, -16, 0, 16), Font = Enum.Font.GothamMedium, Text = "0:00", TextSize = 11,
            TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 2,
        }, card)

        if not attach(gui) then error("no valid GUI parent") end

        -- ── state & animation ─────────────────────────────────────────────────
        local state, target, creep, shown = "running", 0, 0, 0
        local closing, conn = false, nil
        local t, lastSec = 0, -1
        local bornC = os.clock()
        local fade, fadeGoal = 1, 0            -- GroupTransparency
        local sc, scv, scGoal = 0.86, 0, 1     -- สปริงขนาดการ์ด (เด้งตอนเข้า)
        local ip, ipv = 0.4, 0                 -- สปริง "ป๊อป" ของไอคอนกลางวงแหวน
        local shake = 0
        local curStage = "wifi"
        local accA, accB = C.accentA, C.accentB
        local introChars = 0
        local bursts = {}

        local function spring(x, v, goal, k, d, dt)
            v = v + (k * (goal - x) - d * v) * dt
            return x + v * dt, v
        end

        local function tw(obj, dur, props, style, dir)
            pcall(function()
                TweenService:Create(obj, TweenInfo.new(dur, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out), props):Play()
            end)
        end

        local function setStage(name, color)
            if curStage == name then return end
            curStage = name
            stageIcon.Image = ICON[name]
            stageIcon.ImageColor3 = color or accB
            ip, ipv = 0.3, 0
        end

        local function paint(a, b)
            accA, accB = a, b
            fillGrad.Color = grad2(a, b)
            borderGrad.Color = grad2(a, b)
            ringGrad.Color = grad2(a, b)
            sparkOuter.BackgroundColor3 = b
            glow.BackgroundColor3 = a
            stageIcon.ImageColor3 = b
            for _, p in ipairs(parts) do p.f.BackgroundColor3 = b end
        end

        local function shockwave(color)
            local w = mk("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(42, 50),
                Size = UDim2.fromOffset(52, 52), BackgroundTransparency = 1, ZIndex = 5,
            }, card)
            mk("UICorner", { CornerRadius = UDim.new(1, 0) }, w)
            local s = mk("UIStroke", { Color = color, Thickness = 3, Transparency = 0.1 }, w)
            tw(w, 0.7, { Size = UDim2.fromOffset(190, 190) })
            tw(s, 0.7, { Transparency = 1, Thickness = 0.5 })
            task.delay(0.8, function() pcall(function() w:Destroy() end) end)
        end

        local function confetti(colors)
            for i = 1, 20 do
                local ang = math.random() * math.pi * 2
                local spd = 90 + math.random() * 150
                local sz = math.random(3, 6)
                local f = mk("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(42, 50),
                    Size = UDim2.fromOffset(sz, sz), BackgroundColor3 = colors[math.random(1, #colors)],
                    BorderSizePixel = 0, ZIndex = 6, Rotation = math.random(0, 360),
                }, card)
                if i % 2 == 0 then mk("UICorner", { CornerRadius = UDim.new(1, 0) }, f) end
                bursts[#bursts + 1] = {
                    f = f, x = 42, y = 50, vx = math.cos(ang) * spd, vy = math.sin(ang) * spd - 70,
                    life = 0.9 + math.random() * 0.4, age = 0, vr = math.random(-360, 360),
                }
            end
        end

        conn = RunService.Heartbeat:Connect(function(dt)
            dt = math.min(dt, 0.1)
            t = t + dt

            -- progress
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
            local frac = math.clamp(shown / 100, 0, 1)
            fill.Size = UDim2.new(frac, 0, 1, 0)
            pct.Text = math.floor(shown + 0.5) .. "%"
            shine.Position = UDim2.new(((t * 0.85) % 1.7) - 0.4, 0, 0, 0)
            sparkOuter.Position = UDim2.new(frac, 0, 0.5, 0)
            local live = state == "running" and shown > 1
            sparkOuter.Visible = live or state == "done"
            local pz = 22 + math.sin(t * 9) * 4
            sparkOuter.Size = UDim2.fromOffset(pz, pz)

            -- ขั้นตอน → ไอคอนกลางวงแหวน
            if state == "running" then
                setStage(shown < 28 and "wifi" or (shown < 62 and "shield" or "download"), accB)
            end

            -- วงแหวน/ขอบ/ชื่อ
            ringGrad.Rotation = (t * 330) % 360
            borderGrad.Rotation = (t * 110) % 360
            local u = (t * 0.5) % 1.9
            titleGrad.Offset = Vector2.new(math.min(1, -1 + u * 2), 0)
            glow.Position = UDim2.fromOffset(-60 + math.sin(t * 0.7) * 16, -80 + math.cos(t * 0.5) * 12)

            -- พิมพ์ชื่อทีละตัวอักษรตอนเข้า
            if introChars < 11 then
                introChars = math.min(11, math.floor(math.max(0, t - 0.12) * 28))
                pcall(function() title.MaxVisibleGraphemes = introChars >= 11 and -1 or introChars end)
            end

            -- อนุภาคลอยขึ้น
            for _, p in ipairs(parts) do
                p.y = p.y - p.v * dt
                if p.y < -0.05 then p.y, p.x, p.v = 1.05, math.random(), 0.05 + math.random() * 0.12 end
                p.f.Position = UDim2.fromScale(p.x + math.sin(t * p.w + p.ph) * 0.012, p.y)
                p.f.BackgroundTransparency = 0.55 + 0.4 * math.abs(p.y - 0.5) * 2
            end

            -- confetti
            for i = #bursts, 1, -1 do
                local b = bursts[i]
                b.age = b.age + dt
                if b.age >= b.life then
                    pcall(function() b.f:Destroy() end); table.remove(bursts, i)
                else
                    b.vy = b.vy + 320 * dt
                    b.x = b.x + b.vx * dt; b.y = b.y + b.vy * dt
                    b.f.Position = UDim2.fromOffset(b.x, b.y)
                    b.f.Rotation = b.f.Rotation + b.vr * dt
                    b.f.BackgroundTransparency = math.clamp((b.age / b.life) ^ 2, 0, 1)
                end
            end

            -- สปริง: ขนาดการ์ด + ป๊อปไอคอน
            sc, scv = spring(sc, scv, scGoal, 190, 15, dt)
            ip, ipv = spring(ip, ipv, 1, 200, 12, dt)
            uiScale.Scale = math.max(0.05, sc)
            local isz = 22 * math.max(0.05, ip)
            stageIcon.Size = UDim2.fromOffset(isz, isz)

            -- fade + สั่น (ตอน error)
            fade = fade + (fadeGoal - fade) * math.min(1, dt * 9)
            if cardClass == "CanvasGroup" then card.GroupTransparency = fade end
            shake = math.max(0, shake - dt * 1.7)
            card.Position = UDim2.new(0.5, math.sin(t * 58) * shake * 10, 0.5, (1 - sc) * 46)

            -- เวลา
            local sec = math.floor(os.clock() - bornC)
            if sec ~= lastSec then
                lastSec = sec
                timeLbl.Text = string.format("%d:%02d", math.floor(sec / 60), sec % 60)
            end
        end)

        local function setStatus(text)
            text = (tostring(text or ""):gsub("[\r\n]+", " "))
            if text == "" then return end
            local cleanText, iconName = extractIcon(text)
            local newText = cleanText ~= "" and cleanText or text
            local textX = 0
            if iconName and ICON[iconName] then
                sIcon.Image = ICON[iconName]
                sIcon.ImageColor3 = ICON_COLORS[iconName] or C.text
                textX = 20
                if not sIcon.Visible then sIcon.Visible = true end
            else
                sIcon.Visible = false
            end
            status.Size = UDim2.new(1, -textX, 1, 0)
            if status.Text ~= newText then
                status.Text = newText
                status.Position = UDim2.new(0, textX, 0, 8)
                status.TextTransparency = 0.85
                tw(status, 0.28, { Position = UDim2.new(0, textX, 0, 0), TextTransparency = 0 })
                if sIcon.Visible then
                    sIcon.ImageTransparency = 1
                    tw(sIcon, 0.28, { ImageTransparency = 0 })
                end
            else
                status.Position = UDim2.new(0, textX, 0, 0)
            end
        end

        local function close()
            if closing then return end
            closing = true
            state = "closed"
            scGoal, fadeGoal = 0.92, 1
            task.delay(0.45, function()
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
            ip, ipv = 0.2, 0
            sc, scv = 1, 0.9 -- เด้งการ์ดเบา ๆ
            shockwave(C.ok)
            confetti({ C.ok, C.okB, C.white, C.accentA })
            task.delay(1.2, close)
        end
        function A.Fail(text)
            if state ~= "running" then return end
            state = "error"
            setStatus(text or "Failed")
            status.TextColor3 = C.err
            paint(C.err, C.errB)
            ringGrad.Transparency = NumberSequence.new(0)
            curStage = "x"; stageIcon.Image = ICON.x; stageIcon.ImageColor3 = C.err
            ip, ipv = 0.2, 0
            shake = 1
            shockwave(C.err)
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
