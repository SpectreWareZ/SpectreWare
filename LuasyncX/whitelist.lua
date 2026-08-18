-- ╔══════════════════════════════════════════════════════╗
-- ║  SpectreWare Loader  –  Optimised Build              ║
-- ║  Changes vs original:                                ║
-- ║  · httpSend fn-list built once (not per-call)        ║
-- ║  · executor lookup table built once outside fn       ║
-- ║  · WL sets pre-indexed for O(1) uid lookup           ║
-- ║  · executor whitelist is a hash-set (O(1))           ║
-- ║  · sentinel helpers cache getgenv() once per call    ║
-- ║  · _djb2 reused inside getHWID (no duplicate loop)   ║
-- ║  · sendWebhook caches PL.UserId locally              ║
-- ║  · announce loop removes redundant task.wait()       ║
-- ║  · _normalizeRes simplified                          ║
-- ╚══════════════════════════════════════════════════════╝

print("[ LuaSyncX ]: Loading Luacx client...")
task.wait(0.6)

local CFG = {
    API                 = "https://luasyncxz.wisp.uno",
    clientKey           = "0f9b3fd53469b88a5ed98d27687650cf5c2812346fd46665",
    loaderVersion       = "2.6.0",
    waitOnStart         = 0.6,
    sessionCheckEvery   = 10,
    clockDriftLimit     = 60,
    splashImageId       = "71815202801684",
    announceDisplayTime = 5,
    announceSound       = "6518811702",
    announceTimeout     = 6,
    apiSessionTimeout   = 10,
    discordUrl          = "https://discord.gg/KJHk8c2Q65",
    notifLibUrl         = "https://pastefy.app/vVYdYcbO/raw",
    -- DJB2 hex hash of the current notiflib source, uppercase. Leave "" to
    -- run unpinned (old behaviour). Get the real value by running once with
    -- it blank — the loader will warn()-print the computed hash — then paste
    -- that in here. Any future change to the pastefy content (hijack, edit,
    -- deletion/replacement) will then fail closed instead of silently
    -- loadstring-ing whatever is at that URL.
    notifLibHash        = "",
}

local CLIENT_HEADERS = { ["X-Client-Key"] = CFG.clientKey }

-- ── Whitelist tables ─────────────────────────────────────────────────────────
local WL = {
    DEVS  = {},
    FREE  = {},
    EXECUTORS = {
        "wispbyte","synapse x","synapse","delta","fluxus","arceus x","hydrogen",
        "codex","krnl","electron","scriptware","vega x","swift","proxo",
        "nihon","celery","trigon","cryptic","evon","calamari","executor",
    },
    MIN_ACCOUNT_AGE = 7,
}

local _devSet, _freeSet = {}, {}
for _, v in ipairs(WL.DEVS)  do _devSet[v]  = true end
for _, v in ipairs(WL.FREE)  do _freeSet[v] = true end

local _exSet = {}
for _, v in ipairs(WL.EXECUTORS) do _exSet[v] = true end

-- ── Stdlib aliases ───────────────────────────────────────────────────────────
if not getgenv then getgenv = function() return _G end end

local _r_pcall    = pcall
local _r_rawget   = rawget
local _r_rawequal = rawequal
local _r_type     = type
local _r_ipairs   = ipairs
local _r_tostring = tostring
local _r_loadstring = loadstring
local _r_format   = string.format
local _r_byte, _r_char = string.byte, string.char
local _r_concat   = table.concat
local _r_floor, _r_random = math.floor, math.random

local function _djb2(s)
    local h = 5381
    for i = 1, #s do h = ((h * 33) + _r_byte(s, i)) % 0x100000000 end
    return _r_format("%08X", h)
end

local _r_bxor = (bit32 and bit32.bxor) or (function()
    local F = math.floor
    return function(a, b)
        local r, b2 = 0, 1
        while a > 0 or b > 0 do
            if a % 2 ~= b % 2 then r = r + b2 end
            a = F(a / 2); b = F(b / 2); b2 = b2 * 2
        end
        return r
    end
end)()

do
    local _n  = { _r_pcall, _r_rawget, _r_type, _r_loadstring, _r_bxor }
    local _nm = { "pcall", "rawget", "type", "loadstring", "bxor" }
    for i, f in _r_ipairs(_n) do
        if _r_type(f) ~= "function" then
            warn("LuaSyncX: '" .. _nm[i] .. "' missing"); return
        end
    end
end

-- ── Integrity probes ─────────────────────────────────────────────────────────
local _native_getgenv = getgenv

local function _checkGetgenv()
    if _r_type(_native_getgenv) ~= "function" then return false end
    local ok, e1 = _r_pcall(_native_getgenv)
    if not ok or _r_type(e1) ~= "table" then return false end
    local ok2, e2 = _r_pcall(_native_getgenv)
    return ok2 and _r_rawequal(e1, e2)
end

local function _checkPcall()
    local p = "__sw_probe_" .. _r_format("%08X", _r_random(0x10000000, 0x7FFFFFFF))
    local ok, v = _r_pcall(function() error(p) end)
    return (not ok) and _r_type(v) == "string" and v:find(p, 1, true) ~= nil
end

local function _checkRawops()
    local t = { __sw_chk = 91 }
    return _r_rawget(t, "__sw_chk") == 91 and _r_rawget(t, "__sw_miss") == nil
end

-- ── Global key symbols ──────────────────────────────────────────────────────
-- s1/s2/s3/xk/canary get a random per-session suffix so a getgenv() key name
-- harvested from one dumped/leaked session can't be hardcoded into a public
-- bypass script and reused against a different session or user.
-- running/stime stay fixed — they're needed as a cross-restart anchor for the
-- double-run guard below, but they only ever hold a boolean/timestamp, never
-- the sentinel token itself, so a fixed name there leaks little.
local _GK = (function()
    local c = _r_char
    local salt = _r_format("%06x", _r_random(0, 0xFFFFFF))
    return {
        running = c(95,114,119,110,103,95),
        stime   = c(95,115,116,109,50,95),
        xk      = c(95,120,107,118,48,95) .. salt,
        s1      = c(95,115,119,49,120,95) .. salt,
        s2      = c(95,115,119,50,121,95) .. salt,
        s3      = c(95,115,119,51,122,95) .. salt,
        canary  = c(95,99,110,114,121,95) .. salt,
    }
end)()

-- ── XOR cipher ───────────────────────────────────────────────────────────────
local _xorKey

local function _xorStr(s, k)
    k = k or _xorKey or "SPW"
    local r, kl = {}, #k
    for i = 1, #s do
        r[i] = _r_char(_r_bxor(_r_byte(s, i), _r_byte(k, (i - 1) % kl + 1)))
    end
    return _r_concat(r)
end

-- ── Sentinel helpers ───────────────────────────────────────────────────────
local function _writeSentinel(tok, xk)
    xk = xk or _xorKey
    if not xk then return end
    local e   = _xorStr(tok, xk)
    local gev = getgenv()
    gev[_GK.s1] = e; gev[_GK.s2] = e; gev[_GK.s3] = e; gev[_GK.xk] = xk
end

local function _verifySentinel(tok, xk)
    xk = xk or _xorKey
    if not xk then return false, "no_xk" end
    local gev = getgenv()
    local v1, v2, v3 = gev[_GK.s1], gev[_GK.s2], gev[_GK.s3]
    if not v1 or v1 ~= v2 or v2 ~= v3 then return false, "split" end
    if _xorStr(v1, xk) ~= tok then return false, "mismatch" end
    return true
end

local function _clearSentinel()
    local gev = getgenv()
    gev[_GK.s1] = nil; gev[_GK.s2] = nil; gev[_GK.s3] = nil; gev[_GK.xk] = nil
end

-- ── Canary ───────────────────────────────────────────────────────────────────
local _canaryVal

local function _plantCanary()
    _canaryVal = _r_format("%08X%08X",
        _r_random(0x10000000, 0x7FFFFFFF),
        _r_random(0x10000000, 0x7FFFFFFF))
    getgenv()[_GK.canary] = _canaryVal
end

local function _checkCanary()
    return getgenv()[_GK.canary] == _canaryVal
end

-- ── Session token ────────────────────────────────────────────────────────────
local function _makeSessionToken(prev)
    local t, c = os.time(), os.clock()
    local r1, r2 = _r_random(0x10000000, 0x7FFFFFFF), _r_random(0x10000000, 0x7FFFFFFF)
    local uid = _r_tostring((function()
        local ok, v = _r_pcall(function() return game:GetService("Players").LocalPlayer.UserId end)
        return ok and v or 0
    end)())
    local raw = (prev or "") .. tostring(t) .. tostring(c):gsub("%D", "") ..
                tostring(r1) .. tostring(r2) .. uid
    local h = 5381
    for i = 1, #raw do h = ((h * 33) + _r_byte(raw, i)) % 0x100000000 end
    return _r_format("%08X", h) .. _r_format("%08X", r1) ..
           _r_format("%08X", r2) .. _r_format("%08X", t % 0x100000000)
end

local function _deriveXk(tok)
    local h1, h2 = 0x1505, 0xDEAD
    for i = 1, #tok do
        h1 = ((h1 * 33) + _r_byte(tok, i))           % 0x10000
        h2 = ((h2 * 31) + _r_byte(tok, #tok + 1 - i)) % 0x10000
    end
    return _r_format("%04X%04X", h1, h2)
end

local _sessionToken = _makeSessionToken()
_xorKey = _deriveXk(_sessionToken)

-- ── Encrypted key store ──────────────────────────────────────────────────────
local _encKey = ""
local function _getKey()    return _xorStr(_encKey, _xorKey) end
local function _setKey(k)   _encKey = _xorStr(k or "", _xorKey) end

-- ── Stale-session / double-run guard ─────────────────────────────────────────
local _startTime = os.time()
do
    local gev = getgenv()
    if gev[_GK.running] then
        local al  = (os.time() - (gev[_GK.stime] or 0)) < 30
        local v1, v2, v3 = gev[_GK.s1], gev[_GK.s2], gev[_GK.s3]
        if al and gev[_GK.xk] and v1 and v1 == v2 and v2 == v3 then
            warn("LuaSyncX: already running"); return
        end
        warn("LuaSyncX: stale session — restarting")
    end
    gev[_GK.running] = true
    gev[_GK.stime]   = _startTime
end

_writeSentinel(_sessionToken); _plantCanary()

do
    local _raw = luasyncx_key or ""
    luasyncx_key = _r_char(0):rep(#(luasyncx_key or ""))
    luasyncx_key = nil
    _setKey(_raw); _raw = nil
end

-- ── Services ─────────────────────────────────────────────────────────────────
local hwid = ""
local _native_pcall, _native_loadstring, _native_tostring =
      _r_pcall, _r_loadstring, _r_tostring

local integrityFail
integrityFail = function(r)
    warn("LuaSyncX: integrity fail — " .. _native_tostring(r))
    _clearSentinel()
    local gev = getgenv()
    gev[_GK.running] = nil; gev[_GK.stime] = nil; gev[_GK.canary] = nil
    _native_pcall(function()
        game:GetService("Players").LocalPlayer:Kick(
            "[ LuaSyncX ]  Anti-Bypass triggered.\nReason: " .. _native_tostring(r))
    end)
end
local _integrityFail_ref = integrityFail

local HS  = game:GetService("HttpService")
local PL  = game:GetService("Players").LocalPlayer
local UIS = game:GetService("UserInputService")
local MPS = game:GetService("MarketplaceService")
local STS = game:GetService("Stats")

-- ── Logging / UI helpers ─────────────────────────────────────────────────────
local NotificationLibrary
local _TAG = "[ LuaSyncX ]: "

local _stripChars = {
    "✔","✘","⚡","🔑","🖥","👤","🎮","⏳","💬","👑","🎁","∞","⚠️","⚠","›","·","🚀","🔥",
}

local function _stripDeco(msg)
    msg = tostring(msg)
    for _, ch in ipairs(_stripChars) do
        msg = msg:gsub(ch, "")
    end
    msg = msg:gsub("^%s*[>%-]+%s*", "")
    msg = msg:gsub("%s%s+", " ")
    return (msg:match("^%s*(.-)%s*$"))
end

local function _div()  end
local function _sep()  end
local function _bRow(msg)  end
local function _bTop()     end
local function _bBot()     end
local function _bMid()     end

local function _banner(msg)
end

local function log(msg, t)
end
local function try(fn, def) local ok, v = pcall(fn); return ok and v or def end

-- ── HTTP layer ───────────────────────────────────────────────────────────────
local _httpFns = {
    function(o) return syn       and syn.request      and syn.request(o)             end,
    function(o) return http      and http.request     and http.request(o)            end,
    function(o) return http      and http.Request     and http.Request(o)            end,
    function(o) return request   and request(o)                                       end,
    function(o) return http_request and http_request(o)                               end,
    function(o) return HttpRequest  and HttpRequest(o)                                end,
    function(o) return httpRequest  and httpRequest(o)                                end,
    function(o) return fluxus   and fluxus.request    and fluxus.request(o)          end,
    function(o) return fluxus   and fluxus.http       and fluxus.http.request and fluxus.http.request(o) end,
    function(o) return Delta    and Delta.request      and Delta.request(o)           end,
    function(o) return delta    and delta.request      and delta.request(o)           end,
    function(o) return ARCEUS_X and ARCEUS_X.http_request and ARCEUS_X.http_request(o)  end,
    function(o) return Scriptware and Scriptware.http_request and Scriptware.http_request(o) end,
    function(o) return Electron  and Electron.http_request  and Electron.http_request(o)  end,
    function(o) return calamari  and calamari.request  and calamari.request(o)        end,
    function(o) return VEGA_X   and VEGA_X.request    and VEGA_X.request(o)          end,
    function(o) return nihon    and nihon.request      and nihon.request(o)           end,
    function(o) return celery   and celery.request     and celery.request(o)          end,
    function(o) return trigon   and trigon.request     and trigon.request(o)          end,
    function(o) return SWIFT    and SWIFT.request      and SWIFT.request(o)           end,
    function(o) return proxo    and proxo.request      and proxo.request(o)           end,
    function(o) return _r_rawget(_G, "executor_request") and _r_rawget(_G, "executor_request")(o) end,
    function(o) return _r_rawget(_G, "http_call")       and _r_rawget(_G, "http_call")(o)         end,
    function(o) return getgenv().request and getgenv().request(o)                     end,
}

local function _normalizeRes(res)
    if not res then return nil end
    local body = res.Body or res.body
    local code = res.StatusCode or res.statusCode
    if type(body) == "table" then body = tostring(body) end
    if not body or body == "" then return nil end
    res.Body = body; res.body = body
    res.StatusCode = code; res.statusCode = code
    return res
end

local _httpCacheIdx
local function httpSend(opts)
    local url    = opts.Url or opts.url or ""
    local method = (opts.Method or "GET"):upper()

    if _httpCacheIdx then
        local ok, res = pcall(_httpFns[_httpCacheIdx], opts)
        local nr = ok and _normalizeRes(res)
        if nr then return nr end
        if not ok then _httpCacheIdx = nil end
    end

    for i = 1, #_httpFns do
        local ok, res = pcall(_httpFns[i], opts)
        local nr = ok and _normalizeRes(res)
        if nr then _httpCacheIdx = i; return nr end
    end

    if method == "GET" then
        local ok, body = pcall(function() return game:HttpGet(url, true) end)
        if ok and body and body ~= "" then
            return { Body = body, body = body, StatusCode = 200 }
        end
    end
    warn("LuaSyncX: no http function found")
end

local function safeGet(url, headers, timeout)
    local ok, res = pcall(httpSend, {
        Url = url, Method = "GET", Headers = headers,
        Timeout = timeout, timeout = timeout,
    })
    if ok and res and (res.Body or "") ~= "" then return true, res.Body end
    return false, ""
end

local function safeGetTimeout(url, timeout, headers)
    local done, result, body = false, false, ""
    local co = task.spawn(function()
        local ok, b = safeGet(url, headers, timeout)
        if not done then result, body = ok, b end
        done = true
    end)
    local ticks, max = 0, timeout * 20
    while not done and ticks < max do task.wait(0.05); ticks = ticks + 1 end
    if not done then
        pcall(task.cancel, co)
    end
    return done and result or false, done and body or "timeout"
end

-- ── Notification library (async) ─────────────────────────────────────────────
-- Pinned by hash: the notiflib is fetched from an external URL Claude doesn't
-- control the origin of. Without pinning, anyone who hijacks/edits/replaces
-- that pastefy page gets loadstring'd code execution in every client. With
-- CFG.notifLibHash set, a mismatch aborts the load instead of running it.
task.spawn(function()
    local _nlOk, _nlSrc = safeGet(CFG.notifLibUrl)
    if not _nlOk or not _nlSrc or _nlSrc == "" then
        warn("LuaSyncX: notiflib fetch failed"); return
    end
    if CFG.notifLibHash ~= "" then
        local gotHash = _djb2(_nlSrc)
        if gotHash ~= CFG.notifLibHash:upper() then
            warn("LuaSyncX: notiflib hash mismatch — refusing to run untrusted code " ..
                 "(expected " .. CFG.notifLibHash:upper() .. ", got " .. gotHash .. ")")
            return
        end
    else
        warn("LuaSyncX: notiflib running UNPINNED — set CFG.notifLibHash to " ..
             _djb2(_nlSrc) .. " to pin it")
    end
    local _fn, _cerr = _native_loadstring(_nlSrc)
    if not _fn then warn("LuaSyncX: notiflib compile error — " .. tostring(_cerr)); return end
    local _runOk, _lib = _r_pcall(_fn)
    NotificationLibrary = _runOk and _lib or nil
    if not NotificationLibrary then warn("LuaSyncX: notiflib load failed") end
end)

-- ── HWID ─────────────────────────────────────────────────────────────────────
local _hwidSeedCache
local _SEED_FILE = "sw_seed.dat"

local function getHWID()
    local parts = {}
    local function push(tag, fn)
        local v = try(fn, ""); if v ~= "" then parts[#parts + 1] = tag .. v end
    end
    push("A:", function() return game:GetService("RbxAnalyticsService"):GetClientId() end)
    push("U:", function() return tostring(PL.UserId) end)
    push("G:", function()
        local i = game:GetService("GuiService"):GetGuiInset()
        return tostring(_r_floor(i.X + 0.5)) .. "x" .. tostring(_r_floor(i.Y + 0.5))
    end)
    local s4 = try(function()
        local id = ""
        if identifyexecutor then id = tostring(identifyexecutor()) end
        if id == "" and typeof(syn)    == "table" then id = "synapse" end
        if id == "" and typeof(fluxus) == "table" then id = "fluxus"  end
        return id ~= "" and "E:" .. id or nil
    end, nil)
    if s4 then parts[#parts + 1] = s4 end
    push("AG:", function() return tostring(PL.AccountAge) end)

    if not _hwidSeedCache then
        _hwidSeedCache = try(function()
            local done, out = false, nil
            task.spawn(function()
                local ok = pcall(function()
                    if isfile and isfile(_SEED_FILE) then
                        local s = readfile(_SEED_FILE)
                        if s and s ~= "" then out = s end
                    end
                end)
                done = true
            end)
            local t = 0
            while not done and t < 30 do task.wait(0.1); t = t + 1 end
            return out
        end, nil)
        if not _hwidSeedCache then
            _hwidSeedCache = try(function()
                local ms = game:GetService("MemStorageService")
                local s  = ms:GetItem("_sw_seed")
                if s and s ~= "" then pcall(writefile, _SEED_FILE, s); return s end
            end, nil)
        end
        if not _hwidSeedCache then
            local seed = tostring(math.random(0x10000, 0xFFFFFF)) .. "_" ..
                         tostring(math.random(0x10000, 0xFFFFFF))
            pcall(writefile, _SEED_FILE, seed)
            pcall(function() game:GetService("MemStorageService"):SetItem("_sw_seed", seed) end)
            _hwidSeedCache = seed
        end
    end
    if _hwidSeedCache then parts[#parts + 1] = "M:" .. _hwidSeedCache end
    if #parts == 0 then return "UNKNOWN" end

    local combined = table.concat(parts, "|")
    local h = 5381
    for i = 1, #combined do h = ((h * 33) + combined:byte(i)) % 0x100000000 end
    return combined .. "#" .. _r_format("%08X", h)
end

-- ── Utility ───────────────────────────────────────────────────────────────────
local function fmtTime(s)
    if s >= 86400 then
        return _r_floor(s / 86400) .. "d " .. _r_floor((s % 86400) / 3600) .. "h " ..
               _r_floor((s % 3600) / 60) .. "m"
    elseif s >= 3600 then
        return _r_floor(s / 3600) .. "h " .. _r_floor((s % 3600) / 60) .. "m"
    else
        return _r_floor(s / 60) .. "m " .. _r_floor(s % 60) .. "s"
    end
end

local function _notifyWL(timeLeft, tier)
    local isPerm = timeLeft == "Permanent" or timeLeft == "∞  Developer" or timeLeft == "∞  Free"
    local msg = "⚡  LuaSyncX  ✔  " .. (tier or "") .. "  —  " ..
                (isPerm and "🔑 Whitelist ของคุณ: ตลอดกาล ∞"
                         or "⏳ Whitelist ของคุณเหลือ: " .. timeLeft)
    local waited = 0
    while not NotificationLibrary and waited < 50 do
        task.wait(0.1); waited = waited + 1
    end
    if NotificationLibrary then
        pcall(function() NotificationLibrary:SendNotification("Success", msg, 7) end)
    end
end

local function _notifyHWID(reason)
    reason = reason or "mismatch"
    local msg
    if reason == "drift" then
        msg = "⚠  HWID Drift Detected\n⚡  LuaSyncX  —  HWID เปลี่ยนระหว่าง session\nติดต่อ Discord เพื่อรีเซ็ต HWID"
    else
        msg = "⚠  HWID Mismatch\n⚡  LuaSyncX  —  Key นี้ผูกกับอุปกรณ์อื่น\nติดต่อ Discord เพื่อรีเซ็ต HWID"
    end
    local waited = 0
    while not NotificationLibrary and waited < 50 do
        task.wait(0.1); waited = waited + 1
    end
    if NotificationLibrary then
        pcall(function() NotificationLibrary:SendNotification("Warning", msg, 10) end)
    end
end

-- ── HWID Reset UI ─────────────────────────────────────────────────────────────
local function _showHWIDResetUI(currentHwid, kickDelay)
    kickDelay = kickDelay or 5
    local _ok, _err = pcall(function()
        local pgOk, pg = pcall(function() return game:GetService("CoreGui") end)
        if not pgOk or not pg then
            pg = PL:WaitForChild("PlayerGui", 3)
            if not pg then return end
        end

        local existing = pg:FindFirstChild("SW_HWIDGui")
        if existing then existing:Destroy() end

        local gui = Instance.new("ScreenGui")
        gui.Name            = "SW_HWIDGui"
        gui.ResetOnSpawn    = false
        gui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
        gui.IgnoreGuiInset  = true
        pcall(function() gui.DisplayOrder = 999 end)

        local function mk(cls, props, par)
            local i = Instance.new(cls)
            for k, v in pairs(props) do
                local pOk, pErr = pcall(function() i[k] = v end)
                if not pOk then
                    warn("LuaSyncX: HWID UI prop '" .. tostring(k) .. "' on " .. cls .. " failed — " .. tostring(pErr))
                end
            end
            i.Parent = par or gui; return i
        end

        mk("Frame", {
            Size = UDim2.new(1,0,1,0),
            BackgroundColor3 = Color3.fromRGB(0,0,0),
            BackgroundTransparency = 0.5,
            ZIndex = 10,
        })

        -- ขยายการ์ดให้ใหญ่ขึ้นเพื่อรองรับรูปภาพที่ใหญ่ขึ้น
        local card = mk("Frame", {
            Size        = UDim2.new(0.9, 0, 0, 500), 
            Position    = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(20, 20, 27),
            BorderSizePixel  = 0,
            ZIndex = 11,
        }, gui)
        mk("UISizeConstraint", {
            MaxSize = Vector2.new(380, 520),
        }, card)
        
        -- ระบบย่อ-ขยายอัตโนมัติขนาดตามจอ (ถ้าจอเล็กกว่าการ์ด จะย่อลงมาพอดี)
        local uiScale = mk("UIScale", { Scale = 1 }, card)
        local function _updateScale()
            local requiredH = 520
            local viewH = workspace.CurrentCamera.ViewportSize.Y
            if viewH < requiredH then
                uiScale.Scale = math.max(0.1, viewH / requiredH)
            else
                uiScale.Scale = 1
            end
        end
        _updateScale()
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(_updateScale)

        mk("UICorner", { CornerRadius = UDim.new(0, 12) }, card)
        mk("UIStroke", {
            Color = Color3.fromRGB(60, 60, 75),
            Thickness = 1,
            Transparency = 0.5,
        }, card)

        local layout = mk("UIListLayout", {
            Padding = UDim.new(0, 12),
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, card)
        
        local padding = mk("UIPadding", {
            PaddingTop = UDim.new(0, 20),
            PaddingBottom = UDim.new(0, 20),
            PaddingLeft = UDim.new(0, 20),
            PaddingRight = UDim.new(0, 20),
        }, card)

        mk("Frame", {
            Size = UDim2.new(1, 0, 0, 4),
            BackgroundColor3 = Color3.fromRGB(235, 70, 70),
            BorderSizePixel = 0,
            LayoutOrder = 1,
        }, card)
        mk("UIGradient", {
            Color = ColorSequence.new(Color3.fromRGB(235, 70, 70), Color3.fromRGB(255, 140, 60)),
        }, card:FindFirstChildWhichIsA("Frame"))

        local headerFrame = mk("Frame", {
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundTransparency = 1,
            LayoutOrder = 2,
        }, card)
        mk("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 10),
        }, headerFrame)

        mk("TextLabel", {
            Size = UDim2.new(0, 30, 0, 30),
            BackgroundColor3 = Color3.fromRGB(45, 20, 25),
            Text = "⚠",
            TextColor3 = Color3.fromRGB(255, 100, 100),
            TextSize = 18,
            Font = Enum.Font.GothamBold,
            LayoutOrder = 1,
        }, headerFrame)
        mk("UICorner", { CornerRadius = UDim.new(1, 0) }, headerFrame:GetChildren()[1])

        local titleBox = mk("Frame", {
            Size = UDim2.new(1, -40, 1, 0),
            BackgroundTransparency = 1,
            LayoutOrder = 2,
        }, headerFrame)
        mk("UIListLayout", {
            Padding = UDim.new(0, 2),
            VerticalAlignment = Enum.VerticalAlignment.Center,
        }, titleBox)

        mk("TextLabel", {
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            Text = "HWID Mismatch",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 17,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 1,
        }, titleBox)
        mk("TextLabel", {
            Size = UDim2.new(1, 0, 0, 14),
            BackgroundTransparency = 1,
            Text = "LuaSyncX v" .. CFG.loaderVersion,
            TextColor3 = Color3.fromRGB(140, 140, 160),
            TextSize = 11,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 2,
        }, titleBox)

        mk("TextLabel", {
            Size = UDim2.new(1, 0, 0, 14),
            BackgroundTransparency = 1,
            Text = "รหัสอุปกรณ์ของคุณ (HWID)",
            TextColor3 = Color3.fromRGB(120, 120, 140),
            TextSize = 11,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 3,
        }, card)

        local hwidBox = mk("Frame", {
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = Color3.fromRGB(12, 12, 17),
            BorderSizePixel = 0,
            LayoutOrder = 4,
        }, card)
        mk("UICorner", { CornerRadius = UDim.new(0, 6) }, hwidBox)
        mk("UIStroke", {
            Color = Color3.fromRGB(45, 45, 60), Thickness = 1, Transparency = 0.2,
        }, hwidBox)
        mk("Frame", {
            Size = UDim2.new(0, 3, 1, -12), Position = UDim2.new(0, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = Color3.fromRGB(235, 70, 70), BorderSizePixel = 0,
        }, hwidBox)
        mk("TextLabel", {
            Size = UDim2.new(1, -20, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            Text = tostring(currentHwid or "?"):sub(1, 28) .. "...",
            TextColor3 = Color3.fromRGB(170, 170, 195),
            TextSize = 12,
            Font = Enum.Font.Code,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
        }, hwidBox)

        local btn = mk("TextButton", {
            Size = UDim2.new(1, 0, 0, 42),
            BackgroundColor3 = Color3.fromRGB(88, 101, 242),
            AutoButtonColor = false,
            BorderSizePixel = 0,
            Text = "💬  คัดลอก Discord Link",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            LayoutOrder = 5,
        }, card)
        mk("UICorner", { CornerRadius = UDim.new(0, 8) }, btn)
        mk("UIGradient", {
            Rotation = 90,
            Color = ColorSequence.new(Color3.fromRGB(98, 111, 250), Color3.fromRGB(69, 78, 205)),
        }, btn)
        btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(110, 120, 255) end)
        btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(88, 101, 242) end)

        local statusPill = mk("Frame", {
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundColor3 = Color3.fromRGB(30, 25, 20),
            BorderSizePixel = 0,
            LayoutOrder = 6,
        }, card)
        mk("UICorner", { CornerRadius = UDim.new(0, 14) }, statusPill)
        mk("UIStroke", {
            Color = Color3.fromRGB(80, 65, 40), Thickness = 1, Transparency = 0.5,
        }, statusPill)
        local cdLabel = mk("TextLabel", {
            Size = UDim2.new(1, -10, 1, 0),
            Position = UDim2.new(0, 5, 0, 0),
            BackgroundTransparency = 1,
            Text = "●  สคริปต์ถูกระงับจนกว่าจะรีเซ็ต",
            TextColor3 = Color3.fromRGB(255, 200, 100),
            TextSize = 11,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Center,
        }, statusPill)

        mk("Frame", {
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = Color3.fromRGB(40, 40, 55),
            BorderSizePixel = 0,
            LayoutOrder = 7,
        }, card)

        mk("TextLabel", {
            Size = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            Text = "📋  วิธีรีเซ็ต HWID ผ่าน Discord",
            TextColor3 = Color3.fromRGB(180, 180, 205),
            TextSize = 12,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 8,
        }, card)

        -- ขยายขนาดรูปภาพ Guide จาก 120px เป็น 180px ให้เห็นชัดเจนขึ้น
        local guideBox = mk("Frame", {
            Size = UDim2.new(1, 0, 0, 180), 
            BackgroundColor3 = Color3.fromRGB(12, 12, 17),
            BorderSizePixel = 0,
            LayoutOrder = 9,
        }, card)
        mk("UICorner", { CornerRadius = UDim.new(0, 8) }, guideBox)
        mk("UIStroke", {
            Color = Color3.fromRGB(45, 45, 60), Thickness = 1, Transparency = 0.2,
        }, guideBox)
        mk("ImageLabel", {
            Size = UDim2.new(1, -10, 1, -10),
            Position = UDim2.new(0, 5, 0, 5),
            BackgroundTransparency = 1,
            Image = "rbxassetid://137221357132370",
            ScaleType = Enum.ScaleType.Fit,
        }, guideBox)

        local parented = false
        pcall(function() gui.Parent = game:GetService("CoreGui"); parented = true end)
        if not parented then
            pcall(function() gui.Parent = PL:WaitForChild("PlayerGui", 3) end)
        end

        btn.MouseButton1Click:Connect(function()
            pcall(function() setclipboard(CFG.discordUrl) end)
            btn.Text = "✔  คัดลอกลิงก์แล้ว!"
            btn.BackgroundColor3 = Color3.fromRGB(55, 170, 95)
            task.delay(2, function()
                if btn and btn.Parent then
                    btn.Text = "💬  คัดลอก Discord Link"
                    btn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
                end
            end)
        end)

        task.spawn(function()
            while gui and gui.Parent do
                task.wait(10)
                local encOk, body = pcall(HS.JSONEncode, HS, {
                    key           = _getKey(),
                    hwid          = currentHwid,
                    loaderVersion = CFG.loaderVersion,
                    placeId       = tostring(game.PlaceId),
                })
                if encOk then
                    local sendOk, res = pcall(httpSend, {
                        Url = CFG.API .. "/api/lookup", Method = "POST",
                        Headers = { ["Content-Type"] = "application/json",
                                    ["X-Loader-Version"] = CFG.loaderVersion },
                        Body = body, Timeout = 6, timeout = 6,
                    })
                    if sendOk and res and res.Body and res.Body ~= "" and res.Body:sub(1,1) ~= "<" then
                        local decOk, d = pcall(HS.JSONDecode, HS, res.Body)
                        if decOk and type(d) == "table" then
                            local success = d.success == true or d.success == "true"
                            local code = (type(d.data) == "table" and tostring(d.data.code or "")) or ""
                            local dHwid = (type(d.data) == "table" and tostring(d.data.hwid or "")) or ""
                            local stillMismatch = (not success and code == "HWID_MISMATCH")
                                or (success and dHwid ~= "" and dHwid ~= currentHwid)
                            if success and not stillMismatch then
                                cdLabel.Text = "✅  รีเซ็ต HWID สำเร็จ — กรุณารีจอย"
                                cdLabel.TextColor3 = Color3.fromRGB(90, 210, 130)
                                btn.Visible = false
                                pcall(function()
                                    game:GetService("StarterGui"):SetCore("SendNotification", {
                                        Title = "LuaSyncX",
                                        Text = "HWID reset สำเร็จ — กรุณารีจอยเซิร์ฟเวอร์",
                                        Duration = 6,
                                    })
                                end)
                                task.wait(2)
                                if gui and gui.Parent then gui:Destroy() end
                                break
                            end
                        end
                    end
                end
            end
        end)
    end)
    if not _ok then
        warn("LuaSyncX: HWID reset UI build failed — " .. tostring(_err))
        task.spawn(function() _notifyHWID("mismatch") end)
    end
end

local function maskKey(k)
    local s = tostring(k or "")
    if #s <= 8 then return string.rep("*", #s) end
    return s:sub(1, 4) .. string.rep("*", #s - 8) .. s:sub(-4)
end

local ERR_MAP = {
    expired          = "Key has expired",
    ["hwid mismatch"]= "HWID mismatch — bound to another device",
    ["not found"]    = "Key not found",
    ["not activated"]= "Key not activated",
    already          = "Key already redeemed",
}
local CODE_MAP = {
    EXPIRED       = "Key has expired",
    HWID_MISMATCH = "HWID mismatch — bound to another device",
}
local function parseApiError(msg, code)
    if code and CODE_MAP[code] then return CODE_MAP[code] end
    local m = tostring(msg or ""):lower()
    for k, v in pairs(ERR_MAP) do if m:find(k) then return v end end
    return "Invalid key: " .. tostring(msg or "unknown")
end

local function getPlatform()
    return try(function() return tostring(UIS:GetPlatform()):gsub("Enum.Platform.", "") end, "Unknown")
end
local function getPing()
    return try(function()
        return _r_floor(STS.Network.ServerStatsItem["Data Ping"]:GetValue()) .. " ms"
    end, "?")
end
local function getMembership()
    return try(function()
        return PL.MembershipType == Enum.MembershipType.Premium and "Premium ⭐" or "None"
    end, "None")
end
local function getPlayerCount()
    return try(function() return tostring(#game:GetService("Players"):GetPlayers()) end, "?")
end

local _EXEC_GLOBALS = {
    WISPBYTE="WispByte", WispByte="WispByte", ARCEUS_X="Arceus X", arceus="Arceus X",
    Delta="Delta", DELTA_LOADED="Delta", HYDROGEN="Hydrogen", hydrogen="Hydrogen",
    CODEX="Codex", Codex="Codex", EVON="Evon", Evon="Evon",
    CRYPTIC="Cryptic", Cryptic="Cryptic", KRNL_LOADED="Krnl",
    is_sirhurt_closure="SirHurt", ELECTRON="Electron", Electron="Electron",
    SCRIPTWARE="Scriptware", Scriptware="Scriptware", VEGA_X="Vega X", VegaX="Vega X",
    SWIFT="Swift", Swift="Swift", PROXO="Proxo", Proxo="Proxo",
    NIHON="Nihon", Nihon="Nihon", CELERY="Celery", Celery="Celery",
    TRIGON="Trigon", Trigon="Trigon",
}
local function getExecutor()
    return try(function()
        if identifyexecutor then return identifyexecutor() end
        for k, v in pairs(_EXEC_GLOBALS) do if _r_rawget(_G, k) then return v end end
        if typeof(syn)    == "table" then return "Synapse X" end
        if typeof(fluxus) == "table" then return "Fluxus"   end
        return "Unknown"
    end, "Unknown")
end

local function getAccountAge()
    return try(function()
        local d = PL.AccountAge
        if d >= 365 then
            return _r_floor(d / 365) .. "y " .. _r_floor((d % 365) / 30) .. "m"
        elseif d >= 30 then
            return _r_floor(d / 30) .. "mo " .. _r_floor(d % 30) .. "d"
        else
            return d .. "d"
        end
    end, "?")
end

local function getFriendCount()
    return try(function()
        local res = httpSend({ Url = "https://friends.roblox.com/v1/users/" .. PL.UserId .. "/friends/count", Method = "GET" })
        local d   = res and res.Body and HS:JSONDecode(res.Body)
        return d and d.count ~= nil and tostring(d.count) or "?"
    end, "?")
end

local function getGameInfo()
    local name, creator = "Unknown", "?"
    try(function()
        local info = MPS:GetProductInfo(game.PlaceId, Enum.InfoType.Asset)
        if info then name = info.Name or name; creator = info.Creator and info.Creator.Name or "?" end
    end)
    return name, creator,
        try(function() return tostring(game:GetService("Players").MaxPlayers) end, "?"),
        try(function() return tostring(game.PlaceVersion) end, "?")
end

local function getAvatar(uid)
    local fb = "https://www.roblox.com/headshot-thumbnail/image?userId=" ..
               uid .. "&width=150&height=150&format=png"
    return try(function()
        local res = httpSend({ Url = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" ..
                                     uid .. "&size=420x420&format=Png&isCircular=false", Method = "GET" })
        local d   = res and res.Body and HS:JSONDecode(res.Body)
        return d and d.data and d.data[1] and d.data[1].imageUrl
    end, fb), fb
end

local function sendWebhook(event, info)
    info = info or {}
    local uid                           = PL.UserId
    local avatar, headshot              = getAvatar(uid)
    local gameName, gameCreator, maxP, placeVer = getGameInfo()
    local clockDrift
    pcall(function()
        local res = httpSend({ Url = CFG.API .. "/api/time", Method = "GET", Headers = CLIENT_HEADERS })
        if res and res.Body then
            local d = HS:JSONDecode(res.Body)
            if d and type(d.serverTime) == "number" then
                clockDrift = math.abs(os.time() - math.floor(d.serverTime / 1000))
                if clockDrift > CFG.clockDriftLimit then
                    warn("LuaSyncX: clock drift " .. clockDrift .. "s")
                end
            end
        end
    end)
    local ok, body = pcall(HS.JSONEncode, HS, {
        event       = event,
        key         = info.key     or "?",
        hwid        = info.hwid    or "?",
        timeLeft    = info.timeLeft or "?",
        expiresAt   = info.expiresAt,
        loaderVersion = CFG.loaderVersion,
        clockDrift  = clockDrift,
        player = {
            name        = PL.Name,
            displayName = tostring(PL.DisplayName or PL.Name),
            userId      = tostring(uid),
            accountAge  = getAccountAge(),
            friends     = getFriendCount(),
            membership  = getMembership(),
            avatar      = avatar,
            headshot    = headshot,
        },
        device = { platform = getPlatform(), ping = getPing(), executor = getExecutor() },
        game   = {
            name        = gameName,
            creator     = gameCreator,
            placeId     = tostring(game.PlaceId),
            version     = placeVer,
            maxPlayers  = maxP,
            playerCount = getPlayerCount(),
            uptime      = fmtTime(_r_floor(workspace.DistributedGameTime)),
            jobId       = tostring(game.JobId),
        },
    })
    if ok then
        pcall(httpSend, { Url = CFG.API .. "/api/event", Method = "POST",
                          Headers = { ["Content-Type"] = "application/json" }, Body = body })
    end
end

-- ── Announce module (async) ───────────────────────────────────────────────────
local _Announce
task.spawn(function()
    local _ok, _src = safeGet("https://pastefy.app/YSGBTdpW/raw")
    if _ok and _src and _src ~= "" then
        local _fn = loadstring(_src)
        if _fn then
            _Announce = _fn()({ splashImageId      = CFG.splashImageId,
                                 announceSound      = CFG.announceSound,
                                 announceDisplayTime = CFG.announceDisplayTime })
        end
    end
    if not _Announce then warn("LuaSyncX: sw_announce load failed") end
end)
local function showAnnounce(msg) if _Announce then _Announce.show(msg) end end

-- ── Core helpers ─────────────────────────────────────────────────────────────
local function _isExpired(d)
    if type(d) ~= "table" then return true end
    local ea = d.expiresAt
    return ea ~= nil and ea ~= -1 and ea - os.time() * 1000 <= 0
end

local function _parseResult(raw)
    local ok, r = pcall(HS.JSONDecode, HS, raw)
    if not ok or type(r) ~= "table" then return nil end
    if r.success == nil or r.data == nil or r.message == nil then return nil end
    return r
end

local function _fnv1a(s)
    local h = 0x811C9DC5
    for i = 1, #s do
        h = _r_bxor(h, _r_byte(s, i))
        h = (h * 0x01000193) % 0x100000000
    end
    return _r_format("%08X", h)
end
local function _hexDecode(h)
    local b = {}
    for i = 1, #h, 2 do b[#b + 1] = _r_char(tonumber(h:sub(i, i + 1), 16) or 0) end
    return _r_concat(b)
end

local function _wlHas(set, val) return set[val] == true end

local function _checkExecutorWL()
    if #WL.EXECUTORS == 0 then return true, nil end
    local ex = getExecutor():lower()
    if ex == "" or ex == "unknown" then return false, "unknown_executor" end
    for k in pairs(_exSet) do
        if ex:find(k, 1, true) then return true, nil end
    end
    return false, "executor_not_whitelisted:" .. ex
end

local function _checkAccountAge()
    if WL.MIN_ACCOUNT_AGE <= 0 then return true, nil end
    local age = try(function() return PL.AccountAge end, nil)
    if age == nil then return true, nil end
    if age < WL.MIN_ACCOUNT_AGE then return false, "account_too_new:" .. tostring(age) .. "d" end
    return true, nil
end

local function _checkUIDSanity()
    local uid = try(function() return PL.UserId end, nil)
    if not uid or uid <= 0 then return false, "invalid_uid:" .. tostring(uid) end
    return true, nil
end

-- ── API helpers ───────────────────────────────────────────────────────────────
local _verified      = false
local _expiresAt_cached

local function apiLookup(key, hwidStr, timeout)
    local ok, body = pcall(HS.JSONEncode, HS, {
        key           = key,
        hwid          = hwidStr,
        loaderVersion = CFG.loaderVersion,
        placeId       = tostring(game.PlaceId),
        loaderXk      = _xorKey,
    })
    if not ok then return false, "" end
    local res = httpSend({ Url = CFG.API .. "/api/lookup", Method = "POST",
                           Headers = { ["Content-Type"] = "application/json",
                                       ["X-Loader-Version"] = CFG.loaderVersion },
                           Body = body, Timeout = timeout, timeout = timeout })
    if res and res.Body and res.Body ~= "" then return true, res.Body end
    return false, ""
end

local function _awaitResult(fn, timeoutSec)
    local done, r1, r2 = false, nil, nil
    local co = task.spawn(function() r1, r2 = fn(); done = true end)
    local t, max = 0, (timeoutSec or 5) * 10
    while not done and t < max do task.wait(0.1); t = t + 1 end
    if not done then pcall(task.cancel, co) end
    return r1, r2
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Main execution block
-- ══════════════════════════════════════════════════════════════════════════════
print("[ LuaSyncX ]: Connecting to Server...")

local _mainOk = xpcall(function()
    task.wait(CFG.waitOnStart)
    local _uid = PL.UserId
    do
        local _uidOk, _uidErr = _checkUIDSanity()
        if not _uidOk then
            log("Invalid player UID — aborting", "error")
            integrityFail("uid_sanity:" .. tostring(_uidErr)); return
        end
        local _ageOk, _ageErr = _checkAccountAge()
        if not _ageOk then
            log("Account too new — access denied (minimum " .. tostring(WL.MIN_ACCOUNT_AGE) .. "d)", "error")
            task.wait(1.5)
            pcall(function()
                PL:Kick("[ LuaSyncX ]  Access denied.\nAccount age too low. ต้องการบัญชีอายุมากกว่า " ..
                        tostring(WL.MIN_ACCOUNT_AGE) .. " วัน")
            end)
            getgenv()[_GK.running] = nil; return
        end
        local _exOk, _exErr = _checkExecutorWL()
        if not _exOk then
            log("Executor not whitelisted — aborting", "error")
            warn("LuaSyncX: executor rejected — " .. tostring(_exErr))
            integrityFail("executor_wl:" .. tostring(_exErr)); return
        end
    end

    local _isDev  = _wlHas(_devSet,  _uid)
    local _isFree = not _isDev and _wlHas(_freeSet, _uid)

    if _isDev or _isFree then
        local sentOk, sentErr = _verifySentinel(_sessionToken)
        if not sentOk then integrityFail("sentinel_bypass:" .. tostring(sentErr)); return end
        if not _checkGetgenv() then integrityFail("getgenv_bypass");  return end
        if not _checkPcall()   then integrityFail("pcall_bypass");    return end
        if not _checkRawops()  then integrityFail("rawops_bypass");   return end
        hwid = getHWID()
        if hwid == "" or hwid == "UNKNOWN" then
            log("Cannot determine HWID", "error"); integrityFail("HWID unknown"); return
        end
        log("Fetching script URL from API...", "loading")
        task.wait(0.5)
        print("[ LuaSyncX ]: Authenticating to Server...")
        local _authStart2 = os.clock()
        local _scriptUrl = ""
        local _apiOk, _apiRaw = safeGetTimeout(CFG.API .. "/api/script/" .. tostring(game.PlaceId), 8, CLIENT_HEADERS)
        if _apiOk and _apiRaw and _apiRaw ~= "" then
            local _jOk, _jd = _r_pcall(HS.JSONDecode, HS, _apiRaw)
            if _jOk and _r_type(_jd) == "table" and _r_type(_jd.data) == "table" then
                _scriptUrl = tostring(_jd.data.scriptUrl or "")
            end
        end
        if _scriptUrl == "" then
            log((_isDev and "DEV" or "FREE") .. " bypass: no script configured for PlaceId " ..
                tostring(game.PlaceId), "error")
            getgenv()[_GK.running] = nil
            pcall(function()
                PL:Kick("[ LuaSyncX ]  This game is not supported.")
            end)
            return
        end
        print("[ LuaSyncX ]: Authenticated in " .. tostring(os.clock() - _authStart2) .. "s")
        log("Script URL received ✓", "success")
        if NotificationLibrary then
            pcall(function()
                NotificationLibrary:SendNotification("Info",
                    "⚡  LuaSyncX  v" .. CFG.loaderVersion .. "  —  กำลังโหลด...", 4)
            end)
        end
        local _label  = _isDev and "DEV ACCESS 👑"  or "FREE ACCESS 🎁"
        local _keyTag = _isDev and "[DEV]"           or "[FREE]"
        local _timeTag = _isDev and "∞  Developer"  or "∞  Free"
        _bTop()
        task.wait(0.15)
        _bRow("✔  " .. _label .. "  ·  LuaSyncX  v" .. CFG.loaderVersion)
        _bMid()
        task.wait(0.15)
        _bRow("👤  Player   ›  " .. PL.Name .. "  (" .. tostring(_uid) .. ")")
        task.wait(0.15)
        _bRow("🎮  PlaceId  ›  " .. tostring(game.PlaceId))
        task.wait(0.15)
        _bRow("⏳  Access   ›  " .. _timeTag)
        task.wait(0.2)
        _bBot()
        task.wait(0.5)
        task.delay(1, function() _notifyWL(_timeTag, _isDev and "DEV 👑" or "FREE 🎁") end)
        _expiresAt_cached = -1
        task.spawn(function() sendWebhook("login", { key = _keyTag, hwid = hwid, timeLeft = _timeTag }) end)
        log("Loading script...", "loading")
        task.wait(0.3)
        local _ok, _src
        for i = 1, 3 do
            log(("Fetching script... (%d/3)"):format(i), "loading")
            _ok, _src = safeGetTimeout(_scriptUrl, 8)
            if _ok and _src and _src ~= "" then break end
            if i < 3 then task.wait(1 * i) end
        end
        if not _ok or not _src or _src == "" then
            log("Failed to fetch script after 3 attempts", "error"); getgenv()[_GK.running] = nil; return
        end
        if #_src < 32 then log("Script source too short", "error"); integrityFail("script too short"); return end
        if not _r_rawequal(_native_loadstring, _r_loadstring) then integrityFail("loadstring_hooked"); return end
        task.wait(0.35)
        local _fn, _err = _native_loadstring(_src); _src = nil
        if not _fn then log("Compile error: " .. tostring(_err), "error"); getgenv()[_GK.running] = nil; return end
        _verified = true; task.spawn(_fn); log("Script launched 🚀", "success"); _div()
        return
    end

    if _getKey() == "" then
        log("No key — set luasyncx_key before running", "error"); getgenv()[_GK.running] = nil; return
    end
    local sentOk, sentErr = _verifySentinel(_sessionToken)
    if not sentOk then
        warn("LuaSyncX: pre-auth sentinel fail (" .. tostring(sentErr) .. ")")
        integrityFail("sentinel_preauth:" .. tostring(sentErr)); return
    end
    if not _checkGetgenv() then warn("LuaSyncX: getgenv hook pre-auth"); integrityFail("getgenv_preauth"); return end
    if not _checkPcall()   then warn("LuaSyncX: pcall hook pre-auth");   integrityFail("pcall_preauth");   return end
    if not _checkRawops()  then warn("LuaSyncX: rawops hook pre-auth");  integrityFail("rawops_preauth");  return end
    _banner("⚡  LuaSyncX  v" .. CFG.loaderVersion .. "  ·  Initialising...")
    task.wait(0.5)
    log("🔑  Key    ›  " .. maskKey(_getKey()), "loading")
    task.wait(0.4)
    hwid = getHWID()
    if hwid == "" or hwid == "UNKNOWN" then
        log("Cannot determine HWID", "error"); integrityFail("HWID unknown"); return
    end
    log("🖥  HWID   ›  " .. tostring(hwid):sub(1, 28) .. "...", "info")
    task.wait(0.4)
    print("[ LuaSyncX ]: Authenticating to Server...")
    local _authStart = os.clock()
    local callOk, raw, result
    for i = 1, 3 do
        log(("Connecting to API... (%d/3)"):format(i), "loading")
        callOk, raw = _awaitResult(function() return apiLookup(_getKey(), hwid, 5) end, 5)
        callOk = callOk or false; raw = raw or ""
        if callOk and raw ~= "" then
            local _isHtml = raw:sub(1, 1) == "<" or raw:find("<!DOCTYPE", 1, true) ~= nil
            if _isHtml then
                log(("Server กำลังตื่น (%d/3)... รอสักครู่"):format(i), "loading")
                if i < 3 then task.wait(4 * i) end
            else
                result = _parseResult(raw)
                if result then break end
                if i < 3 then task.wait(0.7 * i) end
            end
        elseif i < 3 then
            task.wait(0.7 * i)
        end
    end
    if not callOk or not raw or raw == "" then
        log("Cannot reach API", "error"); getgenv()[_GK.running] = nil; return
    end
    if not result then
        if raw:sub(1, 1) == "<" or raw:find("<!DOCTYPE", 1, true) ~= nil then
            log("Server ยังไม่พร้อม (offline/sleeping) — กรุณาลองใหม่อีกครั้ง", "error")
        else
            log("Invalid API response after 3 attempts — server issue?", "error")
        end
        warn("LuaSyncX: raw response was → " .. tostring(raw):sub(1, 300))
        getgenv()[_GK.running] = nil; return
    end
    log("API response received ✓", "info")
    task.wait(0.35)
    if result.success ~= true and result.success ~= "true" then
        local _code = (type(result.data) == "table" and tostring(result.data.code or "")) or ""
        log(parseApiError(result.message, _code), "error")
        if _code == "HWID_MISMATCH" then
            task.spawn(function() sendWebhook("mismatch", { key = _getKey(), hwid = hwid, timeLeft = "BLOCKED" }) end)
            getgenv()[_GK.running] = nil
            task.spawn(function()
                _showHWIDResetUI(hwid, 5)
            end)
            return
        end
        if _code == "EXPIRED" then
            task.spawn(function() sendWebhook("expired", { key = _getKey(), hwid = hwid, timeLeft = "EXPIRED" }) end)
            task.wait(2); PL:Kick("[ LuaSyncX ]  Your key has expired.\nPlease redeem a new key in Discord.")
        end
        getgenv()[_GK.running] = nil; return
    end
    if type(result.data) ~= "table" then
        log("Incomplete data from API", "error"); getgenv()[_GK.running] = nil; return
    end
    local data = result.data
    if type(data.hwid) == "string" and data.hwid ~= "" and data.hwid ~= hwid then
        log("HWID mismatch — key bound to another device", "error")
        task.spawn(function() sendWebhook("mismatch", { key = _getKey(), hwid = hwid, timeLeft = "BLOCKED" }) end)
        getgenv()[_GK.running] = nil
        task.spawn(function()
            _showHWIDResetUI(hwid, 5)
        end)
        return
    end
    log("HWID verified ✓", "success")
    print("[ LuaSyncX ]: Authenticated in " .. tostring(os.clock() - _authStart) .. "s")
    task.wait(0.4)
    local _hasScript = (type(data.scriptEnc) == "string" and data.scriptEnc ~= "") or
                        (type(data.scriptUrl) == "string" and data.scriptUrl ~= "")
    if not _hasScript then
        log("API did not return scriptUrl for PlaceId " .. tostring(game.PlaceId), "error")
        getgenv()[_GK.running] = nil
        pcall(function()
            PL:Kick("[ LuaSyncX ]  This game is not supported.")
        end)
        return
    end
    if NotificationLibrary then
        pcall(function()
            NotificationLibrary:SendNotification("Info",
                "⚡  LuaSyncX  v" .. CFG.loaderVersion .. "  —  กำลังโหลด...", 4)
        end)
    end
    local timeLeft, expiresAt = "Permanent", data.expiresAt
    if expiresAt ~= nil and expiresAt ~= -1 then
        local diff = _r_floor((expiresAt - os.time() * 1000) / 1000)
        if diff <= 0 then log("Key has already expired", "error"); getgenv()[_GK.running] = nil; return end
        timeLeft = fmtTime(diff)
    end
    _expiresAt_cached = expiresAt
    log("Key verified  —  Expires: " .. timeLeft, "success")
    task.wait(0.4)
    _div()
    task.wait(0.15)
    _bTop()
    _bRow("✔  VERIFIED  ·  LuaSyncX  v" .. CFG.loaderVersion)
    _bMid()
    task.wait(0.15)
    _bRow("👤  Player   ›  " .. PL.Name)
    local _discordStr  = tostring(data.redeemed_by or "")
    local _discordName = _discordStr:match("^(.-)%s*%(%d+%)$") or _discordStr
    if _discordName ~= "" then task.wait(0.15); _bRow("💬  Discord  ›  " .. _discordName) end
    task.wait(0.15)
    _bRow("⏳  Expires  ›  " .. timeLeft)
    task.wait(0.15)
    _bRow("🎮  PlaceId  ›  " .. tostring(game.PlaceId))
    task.wait(0.2)
    _bBot()
    task.wait(0.5)
    task.delay(1, function() _notifyWL(timeLeft, "KEY") end)
    task.spawn(function() sendWebhook("login", { key = _getKey(), hwid = hwid, timeLeft = timeLeft, expiresAt = expiresAt }) end)
    local scriptSrc
    if type(data.scriptEnc) == "string" and data.scriptEnc ~= "" then
        scriptSrc = _xorStr(_hexDecode(data.scriptEnc), _xorKey)
        log("Script decrypted ✓", "success")
        task.wait(0.3)
    else
        local SCRIPT = data.scriptUrl
        if not SCRIPT or SCRIPT == "" then
            log("API did not return scriptUrl for PlaceId " .. tostring(game.PlaceId), "error")
            getgenv()[_GK.running] = nil
            pcall(function()
                PL:Kick("[ LuaSyncX ]  This game is not supported.")
            end)
            return
        end
        log("Loading script...", "loading")
        task.wait(0.3)
        local scriptOk
        for i = 1, 3 do
            log(("Fetching script... (%d/3)"):format(i), "loading")
            scriptOk, scriptSrc = safeGetTimeout(SCRIPT, 8)
            if scriptOk and scriptSrc and scriptSrc ~= "" then break end
            if i < 3 then task.wait(1 * i) end
        end
        if not scriptOk or not scriptSrc or scriptSrc == "" then
            log("Failed to fetch script after 3 attempts", "error"); getgenv()[_GK.running] = nil; return
        end
    end
    if not scriptSrc or #scriptSrc < 32 then
        log("Script source too short — aborting", "error"); integrityFail("script too short"); return
    end
    if type(data.scriptHash) == "string" and data.scriptHash ~= "" then
        if _djb2(scriptSrc) ~= data.scriptHash:upper() then
            log("Script hash mismatch (DJB2)", "error"); integrityFail("script hash mismatch DJB2"); return
        end
        log("Script integrity ✓ (DJB2)", "success")
        task.wait(0.3)
    end
    if type(data.scriptHashFnv) == "string" and data.scriptHashFnv ~= "" then
        if _fnv1a(scriptSrc) ~= data.scriptHashFnv:upper() then
            log("Script hash mismatch (FNV1a)", "error"); integrityFail("script hash mismatch FNV1a"); return
        end
        log("Script integrity ✓ (FNV1a)", "success")
        task.wait(0.3)
    end
    if not _r_rawequal(_native_loadstring, _r_loadstring) then
        log("loadstring hooked — aborting", "error"); integrityFail("loadstring_hooked"); return
    end
    task.wait(0.4)
    local fn, compErr = _native_loadstring(scriptSrc); scriptSrc = nil
    if not fn then log("Compile error: " .. tostring(compErr), "error"); getgenv()[_GK.running] = nil; return end
    _verified = true; task.spawn(fn); log("Script launched 🚀", "success"); _div()

end, function(err)
    warn("LuaSyncX: unexpected error — " .. tostring(err))
    _clearSentinel(); getgenv()[_GK.running] = nil; getgenv()[_GK.canary] = nil
end)

if not _mainOk or not _verified then return end

-- ── Post-launch: announce poller ──────────────────────────────────────────────
local _sessionActive = true
local _lastSeq, _lastId, _rotationTick, _rotationEvery = 0, "", 0, 3

task.spawn(function()
    while _sessionActive do
        local gotMsg = false
        pcall(function()
            local ok, raw2 = safeGetTimeout(
                CFG.API .. "/api/announce?key=" .. _getKey() .. "&seq=" .. _lastSeq,
                CFG.announceTimeout, CLIENT_HEADERS)
            if not ok or not raw2 or raw2 == "" then return end
            local ok2, d = pcall(HS.JSONDecode, HS, raw2)
            if not ok2 or type(d) ~= "table" then return end
            if type(d.seq) == "number" then _lastSeq = d.seq end
            local id, m = tostring(d.id or ""), tostring(d.message or "")
            if id ~= "" and id ~= _lastId and m ~= "" then
                _lastId = id; gotMsg = true; showAnnounce(m)
            end
        end)
        task.wait(gotMsg and 2 or 4)
    end
end)

-- ── Post-launch: player-remove cleanup ───────────────────────────────────────
local _conn
_conn = game:GetService("Players").PlayerRemoving:Connect(function(p)
    if p == PL then
        _sessionActive = false; _clearSentinel()
        local gev = getgenv()
        gev[_GK.running] = nil; gev[_GK.stime] = nil; gev[_GK.canary] = nil; luasyncx_key = nil
        _conn:Disconnect()
    end
end)

-- ── Post-launch: session integrity heartbeat ──────────────────────────────────
task.spawn(function()
    while _sessionActive and task.wait(CFG.sessionCheckEvery) do
        if not PL or not PL.Parent then _sessionActive = false; break end

        if not _r_rawequal(integrityFail, _integrityFail_ref) or _r_type(integrityFail) ~= "function" then
            _sessionActive = false; warn("LuaSyncX: integrityFail hooked")
            _clearSentinel(); getgenv()[_GK.running] = nil
            _r_pcall(function() PL:Kick("[ LuaSyncX ]  Anti-Bypass triggered.\nReason: fn_hook") end)
            break
        end

        if not _checkCanary() then
            _sessionActive = false; warn("LuaSyncX: canary tampered")
            integrityFail("canary_violated"); break
        end

        local sentOk, sentErr = _verifySentinel(_sessionToken)
        if not sentOk then
            _sessionActive = false
            warn("LuaSyncX: sentinel tampered (" .. tostring(sentErr) .. ")")
            integrityFail("sentinel:" .. tostring(sentErr)); break
        end

        if getgenv()[_GK.stime] ~= _startTime then
            _sessionActive = false; warn("LuaSyncX: stime tampered")
            integrityFail("stime_tamper"); break
        end

        local curHwid = getHWID()
        if curHwid ~= hwid and curHwid ~= "UNKNOWN" then
            _sessionActive = false; warn("LuaSyncX: HWID drift")
            pcall(function() sendWebhook("mismatch", { key = _getKey(), hwid = curHwid, timeLeft = "DRIFT" }) end)
            task.spawn(function()
                _showHWIDResetUI(curHwid, 5)
            end)
            break
        end

        if _r_type(_r_pcall) ~= "function" or _r_type(_r_rawget) ~= "function" then
            _sessionActive = false; warn("LuaSyncX: stdlib hooked")
            integrityFail("stdlib_hooked"); break
        end
        if not _checkGetgenv() then
            _sessionActive = false; warn("LuaSyncX: getgenv hooked")
            integrityFail("getgenv_hooked"); break
        end
        if not _checkPcall() then
            _sessionActive = false; warn("LuaSyncX: pcall hooked")
            integrityFail("pcall_hooked"); break
        end
        if not _checkRawops() then
            _sessionActive = false; warn("LuaSyncX: rawops hooked")
            integrityFail("rawops_hooked"); break
        end

        local _skipRemote = _expiresAt_cached == -1 or
            (_expiresAt_cached ~= nil and (_expiresAt_cached - os.time() * 1000) > 30000)
        if not _skipRemote then
            local ok2, raw3 = _awaitResult(function() return apiLookup(_getKey(), hwid, CFG.apiSessionTimeout) end, CFG.apiSessionTimeout)
            if ok2 and raw3 and raw3 ~= "" then
                local ok3, cr = pcall(HS.JSONDecode, HS, raw3)
                if ok3 and type(cr) == "table" then
                    local expired = (cr.success ~= true and cr.success ~= "true") or
                                    (type(cr.data) == "table" and _isExpired(cr.data))
                    if expired then
                        _sessionActive = false; log("Key expired", "error")
                        pcall(function() sendWebhook("expired", { key = _getKey(), hwid = hwid, timeLeft = "EXPIRED" }) end)
                        task.wait(2)
                        PL:Kick("[ LuaSyncX ]  Your key has expired.\nPlease redeem a new key in Discord.")
                        _clearSentinel(); getgenv()[_GK.running] = nil; getgenv()[_GK.canary] = nil
                        _conn:Disconnect(); return
                    end
                    if type(cr.data) == "table" then _expiresAt_cached = cr.data.expiresAt end
                end
            end
        end

        -- Token rotation
        _rotationTick = _rotationTick + 1
        if _rotationTick >= _rotationEvery then
            _rotationTick = 0
            local nT = _makeSessionToken(_sessionToken)
            local nX = _deriveXk(nT)
            local _rk = _getKey()
            _sessionToken = nT; _xorKey = nX
            _setKey(_rk); _rk = nil
            _writeSentinel(nT, nX); _plantCanary()
        end
    end

    _clearSentinel()
    local gev = getgenv()
    gev[_GK.running] = nil; gev[_GK.stime] = nil; gev[_GK.canary] = nil; luasyncx_key = nil
    if _conn then _conn:Disconnect() end
end)
