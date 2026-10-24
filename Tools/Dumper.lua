-- AI Dumper v3.5
-- ดัมพ์แมพ (หลายเป้าหมาย) | ผู้เล่น | remote spy | deep scan | หา remote

-- เก็บ native function ไว้ในตัวแปร (ใช้ชุดนี้ทั้งไฟล์)
local _pcall    = pcall
local _typeof   = typeof
local _tostring = tostring
local _mmin     = math.min
local _floor    = math.floor
local _clock    = os.clock
local _tinsert  = table.insert
local _tconcat  = table.concat
local _tsort    = table.sort
local _sformat  = string.format
local _rawget   = rawget
local _next     = next
local _pairs    = pairs
local _ipairs   = ipairs

-- รันซ้ำ: ปิดอินสแตนซ์เก่าก่อน
local _g = getgenv and getgenv() or nil
if _g and type(_g.__AI_DUMPER_CLEANUP) == "function" then _pcall(_g.__AI_DUMPER_CLEANUP); _g.__AI_DUMPER_CLEANUP = nil end

local CS = game:GetService("CollectionService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

-- ประกาศตัวแปรล่วงหน้า
local UI, Window
local Status, PlayerStatus, SpyStatus, DeepStatus, HiddenStatus

-- คืนผลลัพธ์ของ fn หรือ `def` ถ้า error / เป็น nil
local safe = function(fn, def)
    local ok, r = _pcall(fn)
    if ok and r ~= nil then return r end
    return def
end

local ROOT = "dump.map"
local mkdirSafe = function(p)
    if not (isfolder and makefolder) then return end
    _pcall(function() if not isfolder(p) then makefolder(p) end end)
end
-- ทุกการดัมพ์มีโฟลเดอร์ของตัวเอง: dump.map/<MapName> ถ้าดัมพ์ซ้ำ -> <MapName>-1, -2, ...
local OUT, _mapName = ROOT, nil
local function getMapName()
    if _mapName then return _mapName end
    local n, done = nil, false
    task.spawn(function() -- ชื่อ place จริง (game.Name บนเกม UGC จะเป็นแค่ "Ugc"); รอไม่เกิน 3 วินาที
        local ok, info = _pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId) end)
        if ok and type(info) == "table" then n = info.Name end
        done = true
    end)
    local t0 = _clock()
    while not done and _clock() - t0 < 3 do task.wait() end
    -- ตัวเลือกเรียงจากดีสุด: ชื่อจริง -> ชื่อ ASCII + PlaceId -> PlaceId ตัดตามตัวอักษร ไม่ตัดตาม byte
    local raw = _tostring(n or game.Name)
    local pid = _tostring(game.PlaceId)
    local uni = raw:gsub('[%c\\/:*?"<>|]+', "-"):gsub("[\240-\247][\128-\191]*", "") -- เอาอักขระต้องห้ามและอีโมจิ 4 byte ออก
    uni = uni:gsub("%s+", " "):gsub("^[%s%.%-]+", ""):gsub("[%s%.%-]+$", "")
    local len = utf8.len(uni)
    if not len then
        uni = ""
    elseif len > 40 then
        uni = uni:sub(1, utf8.offset(uni, 41) - 1):gsub("[%s%.%-]+$", "") -- ตัดตามตัวอักษร ไม่ตัดกลาง sequence
    end
    local ascii = raw:gsub("[^%w _%.%-]+", "_"):gsub("[%s_]+", "_"):gsub("^[%._%-]+", ""):gsub("[%._%-]+$", ""):sub(1, 40)
    ascii = (ascii ~= "") and (ascii .. "_" .. pid) or pid
    _mapName = {}
    if uni ~= "" then _mapName[#_mapName + 1] = uni end
    if ascii ~= uni then _mapName[#_mapName + 1] = ascii end
    if pid ~= ascii then _mapName[#_mapName + 1] = pid end
    return _mapName
end
local function newRunDir()
    -- ชื่อที่ถูกโฟลเดอร์หรือไฟล์เก่า (ไฟล์ 0B) ใช้ไปแล้ว จะต่อท้าย -1, -2, ...
    local function pick(base)
        local p, i = base, 0
        while isfolder and (isfolder(p) or (isfile and isfile(p))) and i < 999 do i = i + 1; p = base .. "-" .. i end
        return p
    end
    mkdirSafe(ROOT)
    for _, name in _ipairs(getMapName()) do
        local p = pick(ROOT .. "/" .. name)
        mkdirSafe(p)
        if not isfolder or isfolder(p) then OUT = p; return end -- executor รับชื่อนี้
    end
    OUT = ROOT -- ใช้ไม่ได้เลย (ไม่มี isfolder/makefolder): เขียนลง dump.map ตรงๆ
end
local function outDir() if OUT == ROOT then newRunDir() end return OUT end -- เครื่องมืออื่น: สร้างโฟลเดอร์ตอนใช้ครั้งแรก

-- writefile ที่ทนต่อโฟลเดอร์ถูกลบ / executor ล้มชั่วคราว
local function safeWrite(name, content)
    if not writefile then return false end
    if _pcall(writefile, name, content) then return true end
    mkdirSafe(ROOT); mkdirSafe(OUT)
    _pcall(task.wait, 0.05)
    return (_pcall(writefile, name, content))
end

local function setStatusOf(obj, text)
    if obj then _pcall(function() obj:Set(nil, text) end) end
end

local function notify(title, content, kind)
    if Window then _pcall(function() Window:Notify({ Title = title, Content = content, Duration = 3, Kind = kind or "Success" }) end) end
end

local ALL_SERVICES = {
    "Workspace", "ReplicatedStorage", "ReplicatedFirst", "StarterGui",
    "StarterPack", "StarterPlayer", "Lighting", "SoundService", "Teams",
    "Players", "Chat", "MaterialService", "TextChatService", "ProximityPromptService"
}

-- ------------------------------------------------------------
-- path ที่ resolve กลับมาเป็น instance เดิมได้จริง
--  * ชื่อพี่น้องซ้ำกัน              -> :GetChildren()[i]
--  * ชื่อตรงกับ property/method    -> :FindFirstChild("X")   (game.Foo.Parent จะได้ property แทน)
--  * ชื่อแปลก / keyword            -> ["name"]
--  * instance ที่ไม่มี parent       -> NIL["name"]
-- ------------------------------------------------------------
local LUA_KEYWORDS = {}
for _, w in _ipairs({ "and", "break", "do", "else", "elseif", "end", "false", "for", "function",
    "if", "in", "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while", "continue" }) do
    LUA_KEYWORDS[w] = true
end

local _pathCache = setmetatable({}, { __mode = "k" })
local _idxCache = nil -- มีค่าเฉพาะตอนดัมพ์ (กัน O(n^2) เวลาพี่น้องชื่อซ้ำเยอะมาก)

local function childIndex(parent, obj)
    if _idxCache then
        local m = _idxCache[parent]
        if not m then
            m = {}
            for i, c in _ipairs(parent:GetChildren()) do m[c] = i end
            _idxCache[parent] = m
        end
        return m[obj]
    end
    for i, c in _ipairs(parent:GetChildren()) do
        if c == obj then return i end
    end
    return nil
end

local function segFor(obj, parent)
    if LP and obj == LP and parent == Players then return ".LocalPlayer" end
    local name = obj.Name
    local ok, v = _pcall(function() return parent[name] end)
    if ok and v == obj then
        if name:match("^[%a_][%w_]*$") and not LUA_KEYWORDS[name] then
            return "." .. name
        end
        return "[" .. _sformat("%q", name) .. "]"
    end
    if parent:FindFirstChild(name) == obj then
        return _sformat(":FindFirstChild(%q)", name)
    end
    local idx = childIndex(parent, obj)
    if idx then return _sformat(":GetChildren()[%d]", idx) end
    return _sformat(":FindFirstChild(%q)", name)
end

local function getCleanPath(obj)
    if obj == game then return "game" end
    local chain, base = {}, nil
    local cur = obj
    while cur do
        if cur == game then base = "game" break end
        local c = _pathCache[cur]
        if c and c.parent == cur.Parent and c.name == cur.Name then base = c.path break end
        chain[#chain + 1] = cur
        cur = cur.Parent
    end
    for i = #chain, 1, -1 do
        local o = chain[i]
        local par = o.Parent
        local path
        if par == game then
            path = _sformat('game:GetService("%s")', o.ClassName)
        elseif par == nil then
            path = _sformat("NIL[%q]", o.Name)
        else
            path = base .. segFor(o, par)
        end
        _pathCache[o] = { parent = par, name = o.Name, path = path }
        base = path
    end
    return base
end

-- Full serializer — รองรับทุก type ที่เจอบ่อย
local function serVal(v, depth)
    depth = depth or 0
    if depth > 3 then return "..." end
    local t = _typeof(v)
    if t == "string" then
        return _sformat("%q", #v > 50 and (v:sub(1, 50) .. "...") or v)
    elseif t == "number" or t == "boolean" then
        return _tostring(v)
    elseif t == "Instance" then
        return _sformat("<%s.%s>", v.ClassName, v.Name)
    elseif t == "Vector3" then
        return _sformat("V3(%.2f,%.2f,%.2f)", v.X, v.Y, v.Z)
    elseif t == "CFrame" then
        return _sformat("CF(%.2f,%.2f,%.2f)", v.X, v.Y, v.Z)
    elseif t == "Color3" then
        return _sformat("RGB(%d,%d,%d)", _floor(v.R * 255 + 0.5), _floor(v.G * 255 + 0.5), _floor(v.B * 255 + 0.5))
    elseif t == "Vector2" or t == "UDim" or t == "UDim2" or t == "BrickColor"
        or t == "Rect" or t == "NumberRange" or t == "EnumItem" then
        return _tostring(v)
    elseif t == "table" then
        local items = {}
        local c = 0
        for k, val in _pairs(v) do
            c = c + 1
            if c > 5 then _tinsert(items, "...") break end
            _tinsert(items, _tostring(k) .. "=" .. serVal(val, depth + 1))
        end
        return "{" .. _tconcat(items, ", ") .. "}"
    elseif t == "function" then
        return "<function>"
    else
        return _sformat("<%s>", t)
    end
end

-- ชนิด Remote (ใช้ร่วมกันทุกเครื่องมือ)
local function isRemoteEvent(o) return o:IsA("RemoteEvent") or o:IsA("UnreliableRemoteEvent") end
local function isRemote(o) return isRemoteEvent(o) or o:IsA("RemoteFunction") end

-- ตัวกรอง
local USEFUL_EXACT = {}
for _, cn in _ipairs({
    "RemoteEvent", "RemoteFunction", "UnreliableRemoteEvent", "BindableEvent", "BindableFunction",
    "ProximityPrompt", "ClickDetector", "Sound", "ModuleScript",
    "Tool", "Humanoid", "Animation", "SpawnLocation", "Seat", "VehicleSeat", "Configuration",
}) do USEFUL_EXACT[cn] = true end

-- ผลขึ้นกับ ClassName อย่างเดียว เลย cache ไว้ (IsA ไล่บน part 100k+ ชิ้นคือจุดที่ช้า)
local _classUseful = {}
local function classUseful(obj)
    local cn = obj.ClassName
    local v = _classUseful[cn]
    if v == nil then
        v = USEFUL_EXACT[cn] == true
            or obj:IsA("ValueBase") or obj:IsA("BaseScript")
            or obj:IsA("LayerCollector") or obj:IsA("GuiObject")
        _classUseful[cn] = v
    end
    return v
end

local function isUseful(obj, detail)
    if detail == "everything" then return true end
    if classUseful(obj) then return true end
    if safe(function() return _next(obj:GetAttributes()) ~= nil end, false) then return true end
    if safe(function() return #CS:GetTags(obj) > 0 end, false) then return true end
    return false
end

-- เอาต์พุต: แบ่งเป็นไฟล์ย่อยจำกัดขนาด (writefile ก้อนใหญ่ก้อนเดียวเคยพังแล้วหายหมด)
local PART_LIMIT = 1500000 -- byte ต่อการ flush หนึ่งครั้ง
local SINGLE_FILE = false   -- ตั้งค่าทุกรอบจากสวิตช์ "Single file"
local SINGLE_NAME = "dump_all.txt"

local function newSink(base)
    local s = { base = base, part = 0, buf = {}, size = 0, files = {}, failed = 0 }
    -- เขียน buf[a..b] เป็นไฟล์ย่อยหนึ่งไฟล์ ถ้าพังจะแบ่งครึ่ง (สาเหตุปกติคือเขียนก้อนเดียวใหญ่เกินไป)
    function s:writeRange(buf, a, b, depth)
        if a > b then return end
        self.part = self.part + 1
        local name = _sformat("%s/%s_%03d.txt", OUT, self.base, self.part)
        mkdirSafe(OUT)
        local ok
        if SINGLE_FILE and appendfile then
            -- รวมทุกอย่างลงไฟล์เดียว ต่อทีละก้อน (ไม่สร้าง string ยักษ์ก้อนเดียว)
            name = OUT .. "/" .. SINGLE_NAME
            local head = _sformat("\n\n===== [%s] part %d =====\n", self.base, self.part)
            ok = _pcall(appendfile, name, head .. _tconcat(buf, "\n", a, b))
            if not ok then name = _sformat("%s/%s_%03d.txt", OUT, self.base, self.part) end
        end
        if not ok then ok = safeWrite(name, _tconcat(buf, "\n", a, b)) end
        if ok then
            if not (SINGLE_FILE and appendfile and name:find(SINGLE_NAME, 1, true)) or #self.files == 0 then
                _tinsert(self.files, name)
            end
        elseif b > a and depth < 3 then
            self.part = self.part - 1 -- ใช้เลขเดิมซ้ำ
            local mid = _floor((a + b) / 2)
            self:writeRange(buf, a, mid, depth + 1)
            self:writeRange(buf, mid + 1, b, depth + 1)
        else
            self.failed = self.failed + 1
        end
    end
    function s:flush()
        if #self.buf == 0 then return end
        local buf = self.buf
        self.buf = {}
        self.size = 0
        self:writeRange(buf, 1, #buf, 0)
    end
    function s:write(str)
        self.buf[#self.buf + 1] = str
        self.size = self.size + #str + 1
        if self.size >= PART_LIMIT then self:flush() end
    end
    return s
end

-- 0.5 Deobfuscator: อยู่ใน deobf_module.lua โหลดแบบ lazy (เฉพาะตอนดัมพ์ที่เปิด deobf) รอไม่เกิน 10 วินาที
-- โฮสต์ช้าหรือโดนบล็อกก็ไม่ทำให้สตาร์ทค้าง ก่อนโหลดเสร็จใช้ stub ให้ทุกอย่างทำงานตอนปิด deobf
local DEOBF_URL = "https://pastefy.app/BC8JRbuF/raw"
local Deobf = {
    failed = true,
    constants = function() return nil end,
    process = function() return nil end,
}
local _deobfTried = false
local function loadDeobf()
    if _deobfTried then return not Deobf.failed end
    _deobfTried = true
    local done, mod = false, nil
    task.spawn(function()
        local ok, r = _pcall(function()
            local fn = loadstring(game:HttpGet(DEOBF_URL), "=deobf_module")
            return fn and fn()
        end)
        if ok then mod = r end
        done = true
    end)
    local t0 = _clock()
    while not done and _clock() - t0 < 10 do task.wait() end
    if type(mod) == "table" and mod.process and mod.constants then
        Deobf = mod
        return true
    end
    warn("[dumper] โหลด deobf_module จาก DEOBF_URL ไม่ได้ - ปิด deobf")
    return false
end

-- 1. ดัมพ์แมพ
local function rd(o, k)
    local ok, v = _pcall(function() return o[k] end)
    if ok then return v end
    return "<unreadable>"
end

-- decompile อาจค้างตลอดกาลในบางสคริปต์ -> ตั้ง timeout เด็ดขาดไม่ให้ดัมพ์ค้าง
-- breaker: นับเฉพาะ timeout ถ้าติดกัน 5 ครั้งจะพัก decompile 15 วินาที แล้วลองใหม่
local _decFail, _decPause = 0, 0

local function decompileSafe(scr, timeout)
    if not decompile then return nil, "ใช้ decompile ไม่ได้" end
    if _clock() < _decPause then return nil, "พัก decompile (timeout ติดกัน 5 ครั้ง เดี๋ยวลองใหม่)" end
    local done, res, errMsg = false, nil, nil
    local th = task.spawn(function()
        local ok, r = _pcall(decompile, scr)
        if ok then res = r ~= nil and _tostring(r) or nil
        else res = nil; errMsg = _tostring(r) end
        done = true
    end)
    local t0 = _clock()
    while not done and _clock() - t0 < (timeout or 6) do task.wait() end
    if not done then
        _pcall(task.cancel, th)
        _decFail = _decFail + 1
        if _decFail >= 5 then _decFail, _decPause = 0, _clock() + 15 end
        return nil, "decompile timeout"
    end
    _decFail = 0
    if res == nil or #res == 0 then
        return nil, "decompile error" .. (errMsg and (": " .. errMsg:sub(1, 80)) or "")
    end
    return res, nil
end

-- เก็บ property เฉพาะชนิดของ instance ลงใน L
local function addTypeProps(L, obj)
    if obj:IsA("BasePart") then
        _tinsert(L, _sformat("Position = %s", serVal(rd(obj, "Position"))))
        _tinsert(L, _sformat("Size = %s", serVal(rd(obj, "Size"))))
        _tinsert(L, _sformat("Anchored = %s | CanCollide = %s", serVal(rd(obj, "Anchored")), serVal(rd(obj, "CanCollide"))))
    elseif obj:IsA("Humanoid") then
        _tinsert(L, _sformat("Health = %s | MaxHealth = %s", serVal(rd(obj, "Health")), serVal(rd(obj, "MaxHealth"))))
        _tinsert(L, _sformat("WalkSpeed = %s | JumpPower = %s", serVal(rd(obj, "WalkSpeed")), serVal(rd(obj, "JumpPower"))))
    elseif obj:IsA("TextButton") or obj:IsA("TextBox") or obj:IsA("TextLabel") then
        _tinsert(L, _sformat("Text = %q", _tostring(rd(obj, "Text"))))
    elseif obj:IsA("ProximityPrompt") then
        _tinsert(L, _sformat("ActionText = %q", _tostring(rd(obj, "ActionText"))))
        _tinsert(L, _sformat("ObjectText = %q", _tostring(rd(obj, "ObjectText"))))
        _tinsert(L, _sformat("HoldDuration = %s | MaxActivationDistance = %s | Enabled = %s",
            serVal(rd(obj, "HoldDuration")), serVal(rd(obj, "MaxActivationDistance")), serVal(rd(obj, "Enabled"))))
    elseif obj:IsA("ClickDetector") then
        _tinsert(L, _sformat("MaxActivationDistance = %s", serVal(rd(obj, "MaxActivationDistance"))))
    elseif obj:IsA("ValueBase") then
        _tinsert(L, _sformat("Value = %s", serVal(rd(obj, "Value"))))
    elseif obj:IsA("Sound") then
        _tinsert(L, _sformat("SoundId = %q", _tostring(rd(obj, "SoundId"))))
        _tinsert(L, _sformat("Volume = %s | Looped = %s", serVal(rd(obj, "Volume")), serVal(rd(obj, "Looped"))))
    elseif obj:IsA("Animation") then
        _tinsert(L, _sformat("AnimationId = %q", _tostring(rd(obj, "AnimationId"))))
    end
end

-- บรรทัดวิธีเรียกใช้ (FireServer, fireproximityprompt ฯลฯ)
local function addUsage(L, obj, path)
    if isRemoteEvent(obj) then
        _tinsert(L, "-- Usage: " .. path .. ":FireServer(args...)")
    elseif obj:IsA("RemoteFunction") then
        _tinsert(L, "-- Usage: local res = " .. path .. ":InvokeServer(args...)")
    elseif obj:IsA("ProximityPrompt") then
        _tinsert(L, "-- Usage: fireproximityprompt(" .. path .. ")")
    elseif obj:IsA("ClickDetector") then
        _tinsert(L, "-- Usage: fireclickdetector(" .. path .. ")")
    end
end

local function getProps(obj, ctx)
    local L = {}
    local okp, path = _pcall(getCleanPath, obj)
    if not okp or type(path) ~= "string" then path = "<path error: " .. _tostring(obj.ClassName) .. "." .. _tostring(obj.Name) .. ">" end
    local cn = obj.ClassName
    _tinsert(L, _sformat("-- [%s] %s", cn, path))
    local tags = safe(function() return CS:GetTags(obj) end, {})
    if #tags > 0 then
        _tsort(tags)
        _tinsert(L, _sformat("Tags: { %s }", _tconcat(tags, ", ")))
    end
    local attrs = safe(function() return obj:GetAttributes() end, {})
    if _next(attrs) then
        local keys = {}
        for k in _pairs(attrs) do keys[#keys + 1] = k end
        _tsort(keys)
        local aL = {}
        for _, k in _ipairs(keys) do _tinsert(aL, k .. " = " .. serVal(attrs[k])) end
        _tinsert(L, _sformat("Attributes: { %s }", _tconcat(aL, ", ")))
    end
    addTypeProps(L, obj)
    local src, raw
    if obj:IsA("BaseScript") or obj:IsA("ModuleScript") then
        if obj:IsA("BaseScript") then
            _tinsert(L, _sformat("Disabled = %s | RunContext = %s", serVal(rd(obj, "Disabled")), _tostring(rd(obj, "RunContext"))))
        end
        if ctx and ctx.scripts then
            local st = ctx.cur.st
            local s, why = decompileSafe(obj, 6)
            if s and #s > 0 then
                src = "=== " .. path .. " ===\n" .. s .. "\n"
                local note = "-- Source: see scripts_" .. ctx.cur.label .. "_*.txt (search the path above)"
                st.scripts = st.scripts + 1
                if ctx.deobf then
                    local okd, dsrc, score = _pcall(Deobf.process, path, s, obj)
                    if not okd then dsrc = nil end
                    if dsrc then
                        src = dsrc
                        raw = "=== " .. path .. " ===\n" .. s .. "\n"
                        st.deobf = st.deobf + 1
                        note = note .. _sformat(" | OBFUSCATED (score %d) -> deobf'd%s", score,
                            ctx.keepRaw and (", original in scripts-original_" .. ctx.cur.label .. "_*.txt") or "")
                    end
                end
                _tinsert(L, note)
            else
                st.srcFail = st.srcFail + 1
                local cs = ctx.deobf and Deobf.constants(obj)
                if cs then
                    src = _sformat("=== %s ===\n-- [DEOBF] decompile failed (%s) - constants only\n%s\n", path, why or "empty", cs)
                    st.deobf = st.deobf + 1
                    _tinsert(L, "-- Source: decompile failed (" .. (why or "empty") .. ") -> constants only, see scripts_" .. ctx.cur.label .. "_*.txt")
                else
                    _tinsert(L, "-- Source: unavailable (" .. (why or "empty") .. ")")
                end
            end
        end
    end
    addUsage(L, obj, path)
    return _tconcat(L, "\n"), src, raw
end

local _mapCancel = false

-- DFS แบบวนลูป (ไม่ใช้ recursion -> ไม่จำกัดความลึก ไม่ stack overflow) แบ่งเวลาทำงาน
local function scanRoots(label, roots, childrenOnly, ctx)
    local st = { visited = 0, dumped = 0, errors = 0, gone = 0, scripts = 0, srcFail = 0, deobf = 0 }
    local entry = { name = label, st = st }
    ctx.sections[#ctx.sections + 1] = entry
    local mapSink = newSink("map_" .. label)
    local srcSink = ctx.scripts and newSink("scripts_" .. label) or nil
    local rawSink = (ctx.deobf and ctx.keepRaw) and newSink("scripts-original_" .. label) or nil
    ctx.cur = { label = label, st = st }
    entry.map, entry.src, entry.raw = mapSink, srcSink, rawSink
    local stack, sp = {}, 0
    for i = #roots, 1, -1 do
        if childrenOnly then
            local kids = safe(function() return roots[i]:GetChildren() end, {})
            for j = #kids, 1, -1 do sp = sp + 1; stack[sp] = kids[j] end
        else
            sp = sp + 1; stack[sp] = roots[i]
        end
    end
    local lastYield, lastUi = _clock(), _clock()
    while sp > 0 do
        if _mapCancel then entry.cancelled = true break end
        local obj = stack[sp]; stack[sp] = nil; sp = sp - 1
        st.visited = st.visited + 1
        if childrenOnly and obj.Parent == nil then
            st.gone = st.gone + 1 -- ถูกทำลายระหว่างที่เรา yield อยู่
        else
            local kids = safe(function() return obj:GetChildren() end, nil)
            if kids then
                for j = #kids, 1, -1 do sp = sp + 1; stack[sp] = kids[j] end
            end
            local okU, useful = _pcall(isUseful, obj, ctx.detail)
            if okU and useful then
                local ok, text, src, raw = _pcall(getProps, obj, ctx)
                if ok and text then
                    mapSink:write(text .. "\n")
                    st.dumped = st.dumped + 1
                    if src and srcSink then srcSink:write(src) end
                    if raw and rawSink then rawSink:write(raw) end
                else
                    st.errors = st.errors + 1
                    if #ctx.errors < 20 then
                        _tinsert(ctx.errors, _sformat("%s: %s", label, _tostring(text)))
                    end
                end
            end
        end
        local now = _clock()
        if now - lastYield > 0.012 then task.wait(); lastYield = _clock() end
        if now - lastUi > 0.5 then
            lastUi = now
            ctx.setStatus(_sformat("🔄 %s\nสแกนแล้ว %d | ดัมพ์ %d | สคริปต์ %d | deobf %d", label, st.visited, st.dumped, st.scripts, st.deobf))
        end
    end
    mapSink:flush()
    if srcSink then srcSink:flush() end
    if rawSink then rawSink:flush() end
end

-- รันได้ทีละงานต่อเครื่องมือ ปลดล็อกเสมอ error จะขึ้นที่สถานะของเครื่องมือนั้น
local _busy = {}
local function once(key, fn, getStatus, ...)
    if _busy[key] then return end
    _busy[key] = true
    local ok, err = _pcall(fn, ...)
    _busy[key] = nil
    if not ok then
        warn("[dumper] " .. key .. ": " .. _tostring(err))
        setStatusOf(getStatus and getStatus(), "❌ " .. _tostring(err):sub(1, 200))
    end
end

-- สารบัญ + รายงานความครอบคลุม เรียกหลังจบทุก section ด้วย เพื่อให้ถ้าเกมแครช/โดนเตะยังมีสารบัญใช้ได้
local function writeIndex(ctx, t0, final)
    local R = {
        "# AI MAP DUMP v3.5" .. (final and "" or " (CHECKPOINT - dump still running or died here)"),
        "# Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. " | Place: " .. game.PlaceId,
        "# Target: " .. (ctx.targetLabel or "All") .. " | Detail: " .. ctx.detail
            .. " | Scripts: " .. (ctx.scripts and "decompiled" or "off") .. " | Deobf: " .. (ctx.deobf and "on" or "off"),
        _sformat("# Elapsed: %.1fs%s", _clock() - t0, _mapCancel and " (STOPPED by user - partial)" or ""),
        "", "# COVERAGE (visited = every instance seen, dumped = passed the filter)",
    }
    local failed, files = 0, {}
    for _, e in _ipairs(ctx.sections) do
        local s = e.st
        _tinsert(R, _sformat("  %-24s visited=%d dumped=%d scripts=%d deobf=%d srcFail=%d errors=%d gone=%d%s",
            e.name, s.visited, s.dumped, s.scripts, s.deobf, s.srcFail, s.errors, s.gone, e.cancelled and " (cancelled)" or ""))
        for _, sk in _ipairs({ e.map or false, e.src or false, e.raw or false }) do
            if sk then
                failed = failed + sk.failed
                for _, f in _ipairs(sk.files) do files[#files + 1] = "  " .. f end
            end
        end
    end
    _tinsert(R, "\n# FILES"); for _, f in _ipairs(files) do _tinsert(R, f) end
    if failed > 0 then _tinsert(R, _sformat("\n# WARNING: %d part file(s) failed to write", failed)) end
    if #ctx.errors > 0 then
        _tinsert(R, "\n# ERRORS (first 20)")
        for _, m in _ipairs(ctx.errors) do _tinsert(R, "  " .. m) end
    end
    return safeWrite(OUT .. "/index.txt", _tconcat(R, "\n")), failed
end

-- target เป็น "All" ชื่อเดียว หรือ list (เลือกหลายอัน) ก็ได้; "NIL" = instance ที่ parent เป็น nil
-- คืน: รายชื่อที่เลือก, เอา NIL ไหม, เป็น All ไหม
local function parseTargets(raw)
    local picked, wantNil, seen = {}, false, {}
    if type(raw) ~= "table" then raw = { raw } end
    for _, v in _ipairs(raw) do
        if type(v) == "table" then v = v.Title or v.Name or v[1] end
        if type(v) == "string" and not seen[v] then
            seen[v] = true
            if v == "NIL" then wantNil = true
            elseif v ~= "All" then picked[#picked + 1] = v end
        end
    end
    -- ถ้าเลือกเฉพาะเจาะจงจะชนะ "All" เสมอ; ถ้าไม่ได้เลือกอะไรเฉพาะ -> ทั้งหมด
    return picked, wantNil, (#picked == 0 and not wantNil)
end

local function startMapDump(opts)
    opts = opts or {}
    if not writefile then setStatusOf(Status, "❌ executor ไม่มี writefile"); return end
    local picked, wantNil, isAll = parseTargets(opts.target)
    local labelParts = {}
    for _, n in _ipairs(picked) do labelParts[#labelParts + 1] = n end
    if wantNil then labelParts[#labelParts + 1] = "NIL" end
    local ctx = {
        targetLabel = isAll and "All" or _tconcat(labelParts, ", "),
        detail = (opts.detail == "Everything") and "everything" or "useful",
        scripts = (opts.scripts ~= false) and decompile ~= nil,
        sections = {}, errors = {},
        setStatus = function(s) setStatusOf(Status, s) end,
    }
    ctx.deobf = ctx.scripts and opts.deobf ~= false
    if ctx.deobf then
        ctx.setStatus("🔄 กำลังโหลด deobfuscator...")
        if not loadDeobf() then
            ctx.deobf = false
            _tinsert(ctx.errors, "โหลด deobf module ไม่ได้ -> ดัมพ์สคริปต์โดยไม่ deobfuscate")
        end
    end
    ctx.keepRaw = opts.keepRaw ~= false
    local t0 = _clock()
    _mapCancel, _decFail, _decPause, _idxCache = false, 0, 0, {}
    for k in _pairs(_pathCache) do _pathCache[k] = nil end -- ชื่ออาจเปลี่ยนไปตั้งแต่ดัมพ์รอบก่อน
    newRunDir()
    SINGLE_FILE = (opts.single == true) and appendfile ~= nil
    if SINGLE_FILE then
        if not safeWrite(OUT .. "/" .. SINGLE_NAME, "# AI MAP DUMP - single file | Place: " .. game.PlaceId .. "\n") then SINGLE_FILE = false end
    elseif opts.single then
        _tinsert(ctx.errors, "ขอ Single file แต่ executor ไม่มี appendfile -> เขียนแยกเป็นไฟล์ย่อยแทน")
    end
    ctx.setStatus("🔄 กำลังสแกน...")
    local function section(label, roots, childrenOnly)
        if _mapCancel then return end
        local ok, err = _pcall(scanRoots, label, roots, childrenOnly, ctx)
        if not ok then
            _tinsert(ctx.errors, _sformat("%s: section ล้มเหลว (%s)", label, _tostring(err)))
            local e = ctx.sections[#ctx.sections]
            for _, sk in _ipairs({ e and e.map or false, e and e.src or false, e and e.raw or false }) do
                if sk then _pcall(sk.flush, sk) end
            end
        end
        _pcall(writeIndex, ctx, t0, false)
    end
    local ok, err = _pcall(function()
        for _, svcName in _ipairs(isAll and ALL_SERVICES or picked) do
            local svc = safe(function() return game:GetService(svcName) end, nil)
            if svc then section(svcName, { svc }, true)
            else _tinsert(ctx.errors, svcName .. ": เกมนี้ไม่มี service นี้") end
        end
        if ((isAll and opts.nilInst ~= false) or wantNil) and getnilinstances and not _mapCancel then
            local roots, seen = {}, {}
            for _, o in _ipairs(safe(getnilinstances, {})) do
                if _typeof(o) == "Instance" and not seen[o] and safe(function() return o.Parent == nil end, false) then
                    seen[o] = true; roots[#roots + 1] = o
                end
            end
            if #roots > 0 then section("NIL", roots, false) end
        end
    end)
    _idxCache = nil
    if not ok then _tinsert(ctx.errors, "ผิดพลาดร้ายแรง (ข้อมูลที่ได้บางส่วนยังถูกบันทึกไว้): " .. _tostring(err)) end
    local saved, failed = writeIndex(ctx, t0, true)
    local good = saved and ok and failed == 0
    local where = SINGLE_FILE and ("/" .. SINGLE_NAME .. " (ไฟล์เดียว) + index.txt")
        or "/index.txt (สารบัญ) + ไฟล์ map_* / scripts_*"
    if good then
        ctx.setStatus("✅ เสร็จแล้ว! → " .. OUT .. where)
    else
        ctx.setStatus("⚠️ จบแต่มีปัญหา — ดู index.txt" .. (saved and "" or " (เขียน index ไม่สำเร็จ)"))
    end
    notify("Map Dump", good and "✅ เสร็จสมบูรณ์" or "⚠️ ได้บางส่วน", good and "Success" or "Warning")
end

-- 2. ดัมพ์ข้อมูลผู้เล่น
local function dumpPlayerData()
    local plr = Players.LocalPlayer
    if not plr then error("ไม่พบ LocalPlayer", 0) end
    setStatusOf(PlayerStatus, "🔄 กำลังสแกน...")
    local L = { "# PLAYER DATA", "# Time: " .. os.date("%Y-%m-%d %H:%M:%S"), "",
        "Name: " .. plr.Name, "DisplayName: " .. plr.DisplayName, "UserId: " .. plr.UserId, "AccountAge: " .. plr.AccountAge, "" }
    local function add(s) _tinsert(L, s) end
    local ls = plr:FindFirstChild("leaderstats")
    if ls then
        add("# Leaderstats:")
        for _, v in _ipairs(ls:GetChildren()) do
            if v:IsA("ValueBase") then add("  " .. v.Name .. " = " .. serVal(rd(v, "Value"))) end
        end
    end
    local char = plr.Character
    if char then
        local hum, root = char:FindFirstChildOfClass("Humanoid"), char:FindFirstChild("HumanoidRootPart")
        if hum then
            add("\n# Character:")
            add(_sformat("  Health = %s | WalkSpeed = %s | JumpPower = %s", serVal(hum.Health), serVal(hum.WalkSpeed), serVal(rd(hum, "JumpPower"))))
        end
        if root then add("  Position = " .. serVal(root.Position)) end
        add("\n# Equipped:")
        for _, tool in _ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then add("  Tool: " .. tool.Name) end
        end
    end
    local bp = plr:FindFirstChildOfClass("Backpack")
    if bp then
        add("\n# Backpack:")
        for _, tool in _ipairs(bp:GetChildren()) do add("  Tool: " .. tool.Name) end
    end
    local saved = safeWrite(outDir() .. "/player.txt", _tconcat(L, "\n"))
    setStatusOf(PlayerStatus, saved and "✅ เสร็จแล้ว! → " .. outDir() .. "/player.txt" or "❌ writefile ล้มเหลว")
    notify("Player Dump", "✅ เสร็จสมบูรณ์")
end

-- ============================================================
-- 3. Remote Spy v5
--   hook ทำแค่จด (self, method, args ที่แพ็คไว้) ลงคิว งานหนักทั้งหมด (หา path, serialize)
--   ทำใน worker thread v4 ทำใน __namecall เลย ซึ่ง (a) อาจ throw เข้าไปในเกม และ
--   (b) ทับค่า getnamecallmethod() ก่อนที่ของเดิมจะรัน -> method ผิดตัว
-- ============================================================
local spyActive, spyDirty, spyKeys = false, false, 0
local spyData, spyQueue, _inConns = {}, {}, {}
local _hookMethod, _origNamecall = "none", nil
local SPY_METHODS = { FireServer = true, InvokeServer = true, Fire = true, Invoke = true }
local QUEUE_MAX, KEY_MAX = 3000, 2000

local function enqueue(self, method, ...)
    if #spyQueue < QUEUE_MAX then spyQueue[#spyQueue + 1] = { self, method, table.pack(...) } end
end

local function logCall(self, method, pk)
    local key = getCleanPath(self) .. ":" .. method
    local d = spyData[key]
    if not d then
        if spyKeys >= KEY_MAX then return end
        spyKeys = spyKeys + 1
        d = { count = 0, samples = {}, seen = {}, class = self.ClassName }
        spyData[key] = d
    end
    d.count, spyDirty = d.count + 1, true
    if #d.samples < 5 then
        local a = {}
        for i = 1, _mmin(pk.n, 8) do a[i] = serVal(pk[i]) end
        local s = _tconcat(a, ", ")
        if not d.seen[s] then d.seen[s] = true; _tinsert(d.samples, s) end
    end
end

local function spyDrain()
    local q = spyQueue
    spyQueue = {}
    for i = 1, #q do
        _pcall(logCall, q[i][1], q[i][2], q[i][3])
        if i % 200 == 0 then task.wait() end
    end
end

local function spyFlush()
    if not _next(spyData) then return end
    local keys = {}
    for k in _pairs(spyData) do keys[#keys + 1] = k end
    _tsort(keys)
    local out = { "# REMOTE SPY REPORT v5", "# Hook Method: " .. _hookMethod, "# Time: " .. os.date("%Y-%m-%d %H:%M:%S"), "" }
    for _, key in _ipairs(keys) do
        local d = spyData[key]
        _tinsert(out, "## " .. key .. "\n  Class: " .. d.class .. "\n  Calls: " .. d.count .. "\n  Args:")
        for _, s in _ipairs(d.samples) do _tinsert(out, "    - " .. s) end
        _tinsert(out, "")
    end
    spyDirty = false
    safeWrite(outDir() .. "/remote_spy.txt", _tconcat(out, "\n"))
end

local function makeHook()
    local gm, sm, cc = getnamecallmethod, setnamecallmethod, checkcaller
    return (newcclosure or function(f) return f end)(function(self, ...)
        local method = gm and gm() or ""
        if spyActive and SPY_METHODS[method] and not (cc and cc()) then
            _pcall(enqueue, self, method, ...) -- ไม่ throw เข้าไปในเกม
            if sm then _pcall(sm, method) end  -- คืนค่า: ของเดิมอ่าน method จาก state นี้
        end
        return _origNamecall(self, ...)
    end)
end

local function setupHooks()
    if not _origNamecall then -- hook ครั้งเดียวพอ (ซ้อนจะ recurse); spyActive เป็นตัวคุมการบันทึก
        local ok, orig = false, nil
        if hookmetamethod then ok, orig = _pcall(hookmetamethod, game, "__namecall", makeHook()) end
        if ok and orig then
            _origNamecall, _hookMethod = orig, "hookmetamethod ✅"
        elseif getrawmetatable then
            -- สำรอง: แพตช์ metatable ของ Instance ที่ใช้ร่วมกัน (setrawmetatable(game, ...) จะไม่เห็น remote เลย)
            local mt = getrawmetatable(game)
            local old = mt and _rawget(mt, "__namecall")
            local unlocked = old and ((setreadonly and _pcall(setreadonly, mt, false)) or (make_writeable and _pcall(make_writeable, mt)))
            if unlocked then
                _origNamecall = old
                if _pcall(rawset, mt, "__namecall", makeHook()) then _hookMethod = "direct __namecall override"
                else _origNamecall = nil end
                if setreadonly then _pcall(setreadonly, mt, true) end
            end
        end
        if not _origNamecall then _hookMethod = "FAILED" end
    end
    return _origNamecall and 1 or 0
end

-- ขาเข้า (server -> client): OnClientEvent
local function hookInbound(r)
    if not spyActive or not isRemoteEvent(r) then return end
    local ok, conn = _pcall(function()
        return r.OnClientEvent:Connect(function(...) if spyActive then enqueue(r, "OnClientEvent", ...) end end)
    end)
    if ok and conn then _tinsert(_inConns, conn) end
end

local function startInbound()
    _pcall(function() _tinsert(_inConns, game.DescendantAdded:Connect(hookInbound)) end)
    task.spawn(safe, function()
        for i, obj in _ipairs(game:GetDescendants()) do
            if not spyActive then break end
            hookInbound(obj)
            if i % 2000 == 0 then task.wait() end
        end
    end)
end

local function stopInbound()
    for _, c in _ipairs(_inConns) do _pcall(function() c:Disconnect() end) end
    _inConns = {}
end

local function spyStart()
    if spyActive then return end
    spyActive, spyData, spyQueue, spyKeys = true, {}, {}, 0
    if setupHooks() == 0 then
        spyActive = false
        setStatusOf(SpyStatus, "❌ ติด hook ไม่สำเร็จ\nhookmetamethod: " .. (hookmetamethod and "✅" or "❌") .. "\ngetrawmetatable: " .. (getrawmetatable and "✅" or "❌"))
        return
    end
    startInbound()
    task.spawn(function()
        local last = _clock()
        while spyActive do
            task.wait(0.5)
            _pcall(spyDrain)
            if spyDirty and _clock() - last >= 2 then last = _clock(); _pcall(spyFlush) end
        end
    end)
    setStatusOf(SpyStatus, "🔴 กำลังดักจับ (ขาออก + OnClientEvent)...\nวิธี: " .. _hookMethod)
end

local function spyStop()
    if not spyActive then return end
    spyActive = false
    stopInbound()
    task.wait(0.3)
    _pcall(spyDrain); _pcall(spyFlush)
    setStatusOf(SpyStatus, "🟢 หยุดแล้ว\n📄 " .. outDir() .. "/remote_spy.txt")
end

-- 4. Deep Analyzer (getgc + upvalue)
local function runDeepAnalysis()
    setStatusOf(DeepStatus, "🔄 กำลังวิเคราะห์...")
    local report, seen, MAXL = { "# DEEP GAME ANALYTICS", "# Time: " .. os.date("%Y-%m-%d %H:%M:%S"), "" }, {}, 8000
    local function add(s) if #report < MAXL and not seen[s] then seen[s] = true; report[#report + 1] = s end end
    local function pathOf(o)
        local ok, p = _pcall(getCleanPath, o)
        return ok and p or ("<" .. _tostring(o) .. ">")
    end
    local function isRemoteValue(v)
        return _typeof(v) == "Instance" and isRemote(v)
    end
    local function scanTbl(tbl, name)
        if type(tbl) ~= "table" then return end
        local c = 0
        for k, v in _pairs(tbl) do
            c = c + 1; if c > 50 then break end
            local t = _typeof(v)
            if t == "string" or t == "number" or t == "boolean" then
                add(_sformat("%s.%s = %s", name, _tostring(k), _tostring(v)))
            elseif t == "function" then
                if getconstants then
                    local okc, consts = _pcall(getconstants, v)
                    local strs = {}
                    for _, cv in _ipairs(okc and type(consts) == "table" and consts or {}) do
                        if type(cv) == "string" and #cv > 3 then strs[#strs + 1] = cv end
                    end
                    if #strs > 0 then add(_sformat("%s.%s -> { %s }", name, _tostring(k), _tconcat(strs, ", "))) end
                end
                local oku, ups = false, nil
                if getupvalues then oku, ups = _pcall(getupvalues, v) end
                for uk, uv in _pairs(oku and type(ups) == "table" and ups or {}) do
                    if isRemoteValue(uv) then add(_sformat("%s.%s upvalue[%s] = REMOTE: %s", name, _tostring(k), _tostring(uk), pathOf(uv))) end
                end
            elseif t == "Instance" then
                add(_sformat("%s.%s = Instance<%s> %s", name, _tostring(k), v.ClassName, v.Name))
            end
        end
    end
    local renv = getrenv and safe(getrenv, nil)
    _pcall(scanTbl, renv and renv._G or _G, "_G")
    _pcall(scanTbl, renv and renv.shared or shared, "shared")
    if getgc then
        add("\n# GC Scan (closures with remote references):")
        local okg, gc = _pcall(getgc, true)
        local nFn = 0
        for i, obj in _ipairs(okg and type(gc) == "table" and gc or {}) do
            if i % 500 == 0 then task.wait() end
            if type(obj) == "function" and not (iscclosure and _pcall(iscclosure, obj) and iscclosure(obj)) then
                nFn = nFn + 1
                if nFn > 20000 then break end
                local oku, ups = false, nil
                if getupvalues then oku, ups = _pcall(getupvalues, obj) end
                for _, uv in _pairs(oku and type(ups) == "table" and ups or {}) do
                    if isRemoteValue(uv) then
                        add(_sformat("  Closure(%s) -> Remote: %s", safe(function() return debug.info(obj, "s") end, "?"), pathOf(uv)))
                    end
                end
            end
        end
    end
    if getloadedmodules then
        add("\n# Loaded Modules:")
        for _, mod in _ipairs(safe(getloadedmodules, {})) do add(_sformat("  %s [%s]", mod.Name, mod.ClassName)) end
    end
    if #report >= MAXL then report[#report + 1] = "# (report truncated at " .. MAXL .. " lines)" end
    local saved = safeWrite(outDir() .. "/deep_scan.txt", _tconcat(report, "\n"))
    setStatusOf(DeepStatus, saved and "✅ เสร็จแล้ว! → " .. outDir() .. "/deep_scan.txt" or "❌ writefile ล้มเหลว")
    notify("Deep Scan", "✅ เสร็จสมบูรณ์")
end

-- ============================================================
-- 5. หา Remote ที่ซ่อนอยู่
--   keyword สั้น (<=4 ตัว: ban, kill, tp, gun...) ต้องตรงกับคำเต็มแบบ camel/snake (หรือพหูพจน์)
--   "bank"/"skill"/"http" จึงไม่ match อีก; keyword ยาวกว่านั้น match แบบ substring
-- ============================================================
local HIDDEN_RULES = {
    { "⚠️ PUNISHMENT", { "admin", "kick", "ban", "punish", "kill" } },
    { "💰 ECONOMY", { "give", "reward", "money", "coin", "cash", "gold" } },
    { "🌀 TELEPORT", { "teleport", "tp" } },
    { "⚔️ ITEM", { "weapon", "gun", "sword", "item" } },
    { "💾 DATA", { "data", "save", "load" } },
}

local function classifyRemote(name)
    local lower = name:lower()
    local words = {}
    for w in name:gsub("(%l)(%u)", "%1 %2"):gsub("(%u)(%u%l)", "%1 %2"):gsub("[^%a]", " "):lower():gmatch("%a+") do words[w] = true end
    for _, rule in _ipairs(HIDDEN_RULES) do
        for _, kw in _ipairs(rule[2]) do
            if (#kw <= 4 and (words[kw] or words[kw .. "s"])) or (#kw > 4 and lower:find(kw, 1, true)) then return rule[1] end
        end
    end
end

local function findHiddenRemotes()
    setStatusOf(HiddenStatus, "🔄 กำลังค้นหา...")
    local L, n = { "# HIDDEN/SUSPICIOUS REMOTES", "" }, 0
    local function scan(list)
        for i, obj in _ipairs(list) do
            if i % 3000 == 0 then task.wait() end
            local ok = _pcall(function()
                if isRemote(obj) then
                    local tag = classifyRemote(obj.Name)
                    if tag then n = n + 1; _tinsert(L, tag .. ": " .. getCleanPath(obj)) end
                end
            end)
            if not ok then _tinsert(L, "-- (error reading one instance)") end
        end
    end
    scan(game:GetDescendants())
    if getnilinstances then _tinsert(L, "\n# NIL instances:"); scan(safe(getnilinstances, {})) end
    local saved = safeWrite(outDir() .. "/hidden_remotes.txt", _tconcat(L, "\n"))
    setStatusOf(HiddenStatus, saved and ("✅ " .. n .. " รายการ → " .. outDir() .. "/hidden_remotes.txt") or "❌ writefile ล้มเหลว")
    notify("Remote Finder", "✅ เสร็จสมบูรณ์")
end

-- ตั้งค่า UI (SpectreUI ผ่านเน็ต; ถ้าโหลดไม่ได้ให้รันแบบไม่มี UI)
local UI_URL = "https://raw.githubusercontent.com/tigergenz/SpectreMain/refs/heads/main/Library/SpectreUI.lua"
local function loadUI()
    local okh, body = _pcall(function() return game:HttpGet(UI_URL) end)
    local okl, fn = _pcall(loadstring, okh and type(body) == "string" and body or "")
    local okr, lib = false, nil
    if okl and fn then okr, lib = _pcall(fn) end
    if okr and type(lib) == "table" and lib.SpectreUI then return lib end
end

local opts = { target = { "All" }, detail = "Useful only", scripts = decompile ~= nil, nilInst = true, deobf = true, keepRaw = true }
local function pick(v) return type(v) == "table" and v[1] or v end -- dropdown อาจส่งกลับมาเป็น table

local function stopAll()
    _mapCancel, spyActive = true, false
    stopInbound()
end

if _g then
    _g.AI_DUMPER = { opts = opts, mapDump = function() task.spawn(once, "map", startMapDump, nil, opts) end, mapStop = function() _mapCancel = true end,
        spyStart = spyStart, spyStop = spyStop, player = dumpPlayerData, deep = runDeepAnalysis, hidden = findHiddenRemotes }
    _g.__AI_DUMPER_CLEANUP = function()
        stopAll()
        local old = Window
        Window = nil
        if old then task.spawn(_pcall, function() old:Destroy() end) end -- แยก thread กัน Destroy ค้างแล้วรันซ้ำไม่ได้
    end
end

UI = loadUI()
if not UI then
    warn("[dumper] โหลด SpectreUI ไม่ได้ (ไม่มีเน็ต / โดนบล็อก) -> ดัมพ์แมพแบบไม่มี UI ด้วยค่าเริ่มต้น "
        .. "เครื่องมืออื่น: getgenv().AI_DUMPER.spyStart() / .player() / .deep() / .hidden()")
    task.spawn(once, "map", startMapDump, nil, opts)
    return
end
if UI.OnUnload then _pcall(UI.OnUnload, stopAll) end -- UI ถูกถอน -> หยุดงานที่ค้างอยู่

local Library = UI.SpectreUI
Window = Library:CreateWindow({
    Brand = { Title = "AI", Accent = "DUMPER", Subtitle = "v3.5", Icon = "zap" },
    Theme = "Midnight",
    ToggleKey = Enum.KeyCode.RightControl,
})

local function newTab(name, icon, secName)
    return Window:CreateTab({ Name = name, Icon = icon }):CreateSection({ Name = secName })
end
local function newStatus(sec, text)
    return sec:CreateParagraph({ Title = "สถานะ", Content = text })
end
local function runBtn(sec, name, icon, key, fn, getStatus)
    sec:CreateButton({ Name = name, Icon = icon, Callback = function() task.spawn(once, key, fn, getStatus) end })
end

-- แท็บ 1: ดัมพ์แมพ
local MSec = newTab("Map Dumper", "package", "ตั้งค่า")
Status = newStatus(MSec, "🟢 ว่าง")
MSec:CreateDropdown({
    Name = "Target (เลือกได้หลายอัน | ไม่เลือกเฉพาะ = All)",
    Options = { "All", "NIL", table.unpack(ALL_SERVICES) }, Default = { "All" }, Multi = true,
    Callback = function(v) opts.target = (type(v) == "table") and v or { v } end,
})
MSec:CreateDropdown({
    Name = "Detail (Everything = ทุก part/model, ช้า+ไฟล์ใหญ่)",
    Options = { "Useful only", "Everything" }, Default = "Useful only",
    Callback = function(v) opts.detail = pick(v) end,
})
MSec:CreateToggle({ Name = "ดีคอมไพล์สคริปต์", Default = decompile ~= nil, Callback = function(on) opts.scripts = on end })
MSec:CreateToggle({ Name = "Deobfuscate สคริปต์อัตโนมัติ (ตรวจจับ + ล้าง)", Default = true, Callback = function(on) opts.deobf = on end })
MSec:CreateToggle({ Name = "เก็บต้นฉบับของสคริปต์ที่ deobf แล้ว (scripts-original_*)", Default = true, Callback = function(on) opts.keepRaw = on end })
MSec:CreateToggle({ Name = "รวม nil instances (ตอนเลือก All)", Default = true, Callback = function(on) opts.nilInst = on end })
MSec:CreateToggle({ Name = "Single file (รวมทุกอย่างเป็น dump_all.txt)", Default = false, Callback = function(on) opts.single = on end })
MSec:CreateButton({
    Name = "เริ่มดัมพ์ทั้งหมด", Icon = "download",
    Callback = function() task.spawn(once, "map", startMapDump, function() return Status end, opts) end,
})
MSec:CreateButton({ Name = "หยุดดัมพ์ (เซฟเท่าที่ได้)", Icon = "square", Callback = function() _mapCancel = true end })

-- แท็บ 2-5
local PSec = newTab("Player Dumper", "user", "ข้อมูลผู้เล่น")
PlayerStatus = newStatus(PSec, "🟢 ว่าง")
runBtn(PSec, "ดัมพ์ข้อมูลผู้เล่น", "scan-face", "player", dumpPlayerData, function() return PlayerStatus end)

local SSec = newTab("Remote Spy", "radar", "ตรวจจับ Remotes")
SpyStatus = newStatus(SSec, "🔴 ว่าง")
SSec:CreateToggle({
    Name = "เปิดใช้งาน Spy", Default = false,
    Callback = function(on)
        if on then task.spawn(once, "spy", spyStart, function() return SpyStatus end) else task.spawn(spyStop) end
    end,
})

local DSec = newTab("Deep Scan", "skull", "เจาะลึก GC + upvalues")
DeepStatus = newStatus(DSec, "🟢 ว่าง")
runBtn(DSec, "เริ่มวิเคราะห์เชิงลึก", "zap", "deep", runDeepAnalysis, function() return DeepStatus end)

local HSec = newTab("Remote Finder", "search", "หา remote ที่น่าสนใจ")
HiddenStatus = newStatus(HSec, "🟢 ว่าง")
runBtn(HSec, "ค้นหา Remote ที่น่าสงสัย", "crosshair", "hidden", findHiddenRemotes, function() return HiddenStatus end)
