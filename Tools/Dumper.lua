-- MapDumper v4.2 (adjustable speed + cleanup)
-- PERF changes vs v4.0:
--   1. YIELD_INTERVAL 0.012 → 0.04  + batch counter (ลด task.wait() ~12×)
--   2. notAttrClass negative cache  (ข้าม GetAttributes/GetTags ของ class ที่ไม่เคยมี)
--   3. decompileAsync prefetch      (decompile ล่วงหน้า DECOMPILE_WORKERS thread พร้อมกัน)
--   4. DECOMPILE_TIMEOUT 6 → 4s, fail threshold 5→3, pause 15→10s
--   5. collectConstants depth 16 → 8

local env = getgenv()
if type(env.__MAPDUMPER_CLEANUP) == "function" then
	pcall(env.__MAPDUMPER_CLEANUP)
end

-- Services.
if not game:IsLoaded() then game.Loaded:Wait() end

local collectionService = game:GetService("CollectionService")
local marketplaceService = game:GetService("MarketplaceService")
local playersService = game:GetService("Players")

-- Constants.
local VERSION = "4.2"
local ROOT = "dump.map"
local PART_LIMIT = 1500000
local MAX_NAME_LEN = 40
local QUEUE_MAX, KEY_MAX = 3000, 2000
local SPEED_PRESETS = {
	Safe   = { yieldInterval = 0.08, yieldBatch = 10  },
	Normal = { yieldInterval = 0.04, yieldBatch = 25  },
	Fast   = { yieldInterval = 0.02, yieldBatch = 50  },
	Turbo  = { yieldInterval = 0.0,  yieldBatch = 150 },
}
local DECOMPILE_TIMEOUT  = 4    -- [PERF] เดิม 6
local DECOMPILE_WORKERS  = 3    -- [PERF] prefetch thread พร้อมกัน
local SPY_METHODS = { FireServer = true, InvokeServer = true }
local UI_URL = "https://raw.githubusercontent.com/tigergenz/SpectreMain/refs/heads/main/Library/SpectreUI.lua"
local ALL_SERVICES = {
	"Workspace", "ReplicatedStorage", "ReplicatedFirst", "StarterGui", "StarterPack", "StarterPlayer",
	"Lighting", "SoundService", "Teams", "Players", "Chat", "MaterialService", "TextChatService",
	"ProximityPromptService", "ServerScriptService", "ServerStorage", "TestService", "LocalizationService",
	"InsertService", "GuiService", "VoiceChatService", "BadgeService", "CoreGui",
}
local EXTRA_TARGETS = { NIL = true, HUI = true, ACTORS = true, CLIENT = true, RUNTIME = true }
local RESERVED = {}
for word in ("con prn aux nul com1 com2 com3 com4 com5 com6 com7 com8 com9 lpt1 lpt2 lpt3 lpt4 lpt5 lpt6 lpt7 lpt8 lpt9"):gmatch("%a+%d*") do RESERVED[word] = true end
local D2C_URL = "https://raw.githubusercontent.com/Awakenchan/GcViewerV2/refs/heads/main/Utility/Data2Code%40Amity.lua"
local STATES = {
	["🔄"] = "กำลังทำงาน", ["✅"] = "เสร็จแล้ว", ["❌"] = "ผิดพลาด",
	["⚠"] = "มีปัญหา", ["🟢"] = "พร้อม", ["🔴"] = "กำลังดักจับ",
}
local TOSTRING_TYPES = {
	number = true, boolean = true, Vector2 = true, UDim = true, UDim2 = true,
	BrickColor = true, Rect = true, NumberRange = true, EnumItem = true,
}
local USAGE = {
	RemoteEvent = "%s:FireServer(args...)",
	UnreliableRemoteEvent = "%s:FireServer(args...)",
	RemoteFunction = "local res = %s:InvokeServer(args...)",
	ProximityPrompt = "fireproximityprompt(%s)",
	ClickDetector = "fireclickdetector(%s)",
}
local ACTIONABLE = {
	RemoteEvent = true, UnreliableRemoteEvent = true, RemoteFunction = true,
	BindableEvent = true, BindableFunction = true,
	ProximityPrompt = true, ClickDetector = true,
}
local TYPE_PROPS = {
	BasePart = { "Position", "Size", "Anchored", "CanCollide" },
	Humanoid = { "Health", "MaxHealth", "WalkSpeed", "JumpPower" },
	TextLabel = { "Text" }, TextButton = { "Text" }, TextBox = { "Text" },
	ProximityPrompt = { "ActionText", "ObjectText", "HoldDuration", "MaxActivationDistance", "Enabled" },
	ClickDetector = { "MaxActivationDistance" },
	ValueBase = { "Value" },
	Sound = { "SoundId", "Volume", "Looped" },
	Animation = { "AnimationId" },
}

local USEFUL, KEYWORDS = {}, {}
for name in ([[RemoteEvent RemoteFunction UnreliableRemoteEvent BindableEvent BindableFunction ProximityPrompt
	ClickDetector Sound ModuleScript Tool Humanoid Animation SpawnLocation Seat VehicleSeat Configuration]]):gmatch("%a+") do
	USEFUL[name] = true
end
for word in ([[and break do else elseif end false for function if in local nil not or repeat return then true until while continue]]):gmatch("%a+") do
	KEYWORDS[word] = true
end

-- State.
local fmt = string.format
local localPlayer = playersService.LocalPlayer or playersService.PlayerAdded:Wait()
local window, mapStatus, spyStatus, spyToggle
local runDir, mapCancelled, singleFile, indexCache = ROOT, false, false, nil
local busy, pathCache = {}, setmetatable({}, { __mode = "k" })
local usefulByClass, propsByClass = {}, {}
-- [PERF] negative cache: class ที่ไม่เคยมี attrs/tags เลย → ข้ามการเรียกได้
local notAttrClass, notAttrMiss = {}, {}

local function safe(fn, default)
	local ok, result = pcall(fn)
	if ok and result ~= nil then return result end
	return default
end

local function httpGet(url)
	local ok, res = pcall(request, { Url = url, Method = "GET" })
	if ok and type(res) == "table" and res.Success then return res.Body end
end

local function ensureFolder(path)
	pcall(function() if not isfolder(path) then makefolder(path) end end)
end

local function safeWrite(path, content)
	if pcall(writefile, path, content) then return true end
	ensureFolder(ROOT)
	ensureFolder(runDir)
	task.wait(0.05)
	return (pcall(writefile, path, content))
end

local function splitState(text)
	text = tostring(text):gsub("\239\184\143", "")
	for emoji, title in pairs(STATES) do
		if text:sub(1, #emoji) == emoji then
			return (text:sub(#emoji + 1):gsub("^%s+", "")), title
		end
	end
	return text
end

local function setStatus(label, text)
	if not label then return end
	local clean, title = splitState(text)
	pcall(label.Set, label, title, clean)
end

local function notify(title, content, kind)
	if not window then return end
	pcall(function()
		window:Notify({ Title = (splitState(title)), Content = (splitState(content)), Duration = 3, Kind = kind or "Success" })
	end)
end

-- สร้างโฟลเดอร์ dump.map/<ชื่อแมพ> ซ้ำก็ต่อ -1, -2
local function newRunDir()
	ensureFolder(ROOT)
	local info = safe(function() return marketplaceService:GetProductInfo(game.PlaceId) end, {})
	local name = tostring(info.Name or game.Name)
	name = name:gsub('[%c\\/:*?"<>|]+', "-"):gsub("[\240-\247][\128-\191]*", ""):gsub("%s+", " "):gsub("^[%s%.%-]+", ""):gsub("[%s%.%-]+$", "")
	local len = utf8.len(name)
	if not len then
		name = ""
	elseif len > MAX_NAME_LEN then
		name = name:sub(1, utf8.offset(name, MAX_NAME_LEN + 1) - 1)
	end

	for _, base in ipairs({ name, tostring(game.PlaceId) }) do
		if base ~= "" then
			local dir, i = ROOT .. "/" .. base, 0
			while (isfolder(dir) or isfile(dir)) and i < 999 do
				i += 1
				dir = ROOT .. "/" .. base .. "-" .. i
			end
			ensureFolder(dir)
			if isfolder(dir) then
				runDir = dir
				return
			end
		end
	end
	runDir = ROOT
end

local function getRunDir()
	if runDir == ROOT then newRunDir() end
	return runDir
end

local function outPath(name)
	return runDir .. "/" .. name
end

-- ชื่อโฟลเดอร์/ไฟล์ให้ตรงกับชื่อใน Dex (ตัดเฉพาะอักขระที่ Windows ไม่รับ)
local function cleanName(name)
	name = tostring(name):gsub('[%c\\/:*?"<>|]+', "_"):gsub("[\240-\247][\128-\191]*", ""):gsub("[%s%.]+$", "")
	name = name ~= "" and name:sub(1, 60) or "_"
	if RESERVED[name:lower():match("^[^%.]*")] then name = "_" .. name end
	return name
end

-- path ที่ resolve กลับเป็น instance เดิมได้จริง
local function childIndex(parent, obj)
	local map = indexCache and indexCache[parent]
	if not map then
		map = {}
		for i, child in ipairs(parent:GetChildren()) do map[child] = i end
		if indexCache then indexCache[parent] = map end
	end
	return map[obj]
end

local function pathSegment(obj, parent)
	if obj == localPlayer and parent == playersService then return ".LocalPlayer" end
	local name = obj.Name
	local ok, found = pcall(function() return parent[name] end)
	if ok and found == obj then
		if name:match("^[%a_][%w_]*$") and not KEYWORDS[name] then return "." .. name end
		return fmt("[%q]", name)
	end
	if parent:FindFirstChild(name) == obj then return fmt(":FindFirstChild(%q)", name) end
	local idx = childIndex(parent, obj)
	return idx and fmt(":GetChildren()[%d]", idx) or fmt(":FindFirstChild(%q)", name)
end

local function getPath(obj)
	local chain, base, cur = {}, "game", obj
	while cur and cur ~= game do
		local cached = pathCache[cur]
		if cached and cached.parent == cur.Parent and cached.name == cur.Name then
			base = cached.path
			break
		end
		chain[#chain + 1] = cur
		cur = cur.Parent
	end

	for i = #chain, 1, -1 do
		local o = chain[i]
		local parent, path = o.Parent, nil
		if parent == game then
			path = fmt('game:GetService("%s")', o.ClassName)
		elseif parent == nil then
			path = fmt("NIL[%q]", o.Name)
		else
			path = base .. pathSegment(o, parent)
		end
		pathCache[o] = { parent = parent, name = o.Name, path = path }
		base = path
	end
	return base
end

local function serialize(v, depth)
	depth = depth or 0
	local t = typeof(v)
	if t == "string" then
		return fmt("%q", #v > 50 and v:sub(1, 50) .. "..." or v)
	elseif TOSTRING_TYPES[t] then
		return tostring(v)
	elseif t == "Instance" then
		return fmt("<%s.%s>", v.ClassName, v.Name)
	elseif t == "Vector3" or t == "CFrame" then
		return fmt("%s(%.2f,%.2f,%.2f)", t, v.X, v.Y, v.Z)
	elseif t == "Color3" then
		return fmt("RGB(%d,%d,%d)", math.floor(v.R * 255 + 0.5), math.floor(v.G * 255 + 0.5), math.floor(v.B * 255 + 0.5))
	elseif t == "table" then
		if depth > 3 then return "..." end
		local items = {}
		for k, val in pairs(v) do
			if #items >= 5 then
				items[#items + 1] = "..."
				break
			end
			items[#items + 1] = tostring(k) .. "=" .. serialize(val, depth + 1)
		end
		return "{" .. table.concat(items, ", ") .. "}"
	end
	return fmt("<%s>", t)
end

local function readProp(obj, key)
	local ok, value = pcall(function() return obj[key] end)
	if ok then return value end
	return "<unreadable>"
end

-- Data2Code serializer (โหลดไม่ได้ก็ใช้ serialize ธรรมดา)
local d2c
local function toCode(value)
	if d2c == nil then
		local body = httpGet(D2C_URL)
		local chunk = body and loadstring(body)
		local ok, lib = pcall(chunk or error)
		d2c = ok and type(lib) == "table" and lib or false
	end
	local ok, text = pcall(function() return d2c and d2c.Convert(value, true) or serialize(value) end)
	text = ok and tostring(text) or serialize(value)
	return #text > 4000 and text:sub(1, 4000) .. "\n--[[truncated]]" or text
end

-- [PERF] isUseful: เพิ่ม negative cache สำหรับ class ที่ไม่เคยมี attr/tag เลย
-- หลังจาก miss 80 ครั้ง จะข้าม GetAttributes()+GetTags() โดยตรง
local function isUseful(obj, everything)
	if everything then return true end
	local class = obj.ClassName
	local cached = usefulByClass[class]
	if cached == nil then
		cached = USEFUL[class] or obj:IsA("ValueBase") or obj:IsA("BaseScript")
			or obj:IsA("LayerCollector") or obj:IsA("GuiObject") or false
		usefulByClass[class] = cached
	end
	if cached then return true end
	-- fast path: class นี้ไม่เคยมี attr/tag ใน session นี้
	if notAttrClass[class] then return false end
	local hasAttr = next(obj:GetAttributes()) ~= nil
	if not hasAttr and #collectionService:GetTags(obj) == 0 then
		local n = (notAttrMiss[class] or 0) + 1
		notAttrMiss[class] = n
		if n >= 80 then notAttrClass[class] = true end
		return false
	end
	return true
end

local function isActionable(obj)
	return ACTIONABLE[obj.ClassName] == true
end

local function typeProps(obj)
	local class = obj.ClassName
	local list = propsByClass[class]
	if list == nil then
		list = false
		for base, props in pairs(TYPE_PROPS) do
			if obj:IsA(base) then
				list = props
				break
			end
		end
		propsByClass[class] = list
	end
	return list
end

-- เขียนผลลัพธ์เป็นไฟล์ย่อย กัน writefile ก้อนใหญ่พัง
local function newSink(base)
	local sink = { part = 0, buf = {}, size = 0, files = {}, failed = 0 }

	function sink:flush()
		if #self.buf == 0 then return end
		local data = table.concat(self.buf, "\n")
		self.buf, self.size = {}, 0
		self.part += 1
		ensureFolder(runDir)
		local path = outPath(self.part == 1 and base .. ".txt" or fmt("%s_%d.txt", base, self.part))
		local ok = singleFile and pcall(appendfile, outPath("all.txt"), fmt("\n===== [%s] %d =====\n%s", base, self.part, data))
		if ok then
			path = outPath("all.txt")
		else
			ok = safeWrite(path, data)
		end
		if not ok then
			self.failed += 1
		elseif self.files[#self.files] ~= path then
			self.files[#self.files + 1] = path
		end
	end

	function sink:write(str)
		self.buf[#self.buf + 1] = str
		self.size += #str + 1
		if self.size >= PART_LIMIT then self:flush() end
	end

	return sink
end

-- [PERF] decompile แบบ parallel prefetch
-- decompileCore  = logic เดิมของ decompileSafe
-- decompileAsync = เริ่ม decompile ล่วงหน้า (ไม่บล็อก)
-- decompileSafe  = ตรวจ cache ก่อน ถ้าไม่มีค่อย decompileCore ตามปกติ

local decompileFails, decompilePausedUntil = 0, 0
local decompileCache = setmetatable({}, { __mode = "k" })  -- obj → true|{code,why}
local decompileSem = 0  -- จำนวน prefetch thread ที่รันอยู่

local function decompileCore(scr)
	if os.clock() < decompilePausedUntil then return nil, "paused (timeouts)" end
	local done, result, errMsg
	local thread = task.spawn(function()
		local ok, r = pcall(decompile, scr)
		if ok then result = r else errMsg = tostring(r) end
		done = true
	end)
	local start = os.clock()
	while not done and os.clock() - start < DECOMPILE_TIMEOUT do task.wait() end
	if not done then
		pcall(task.cancel, thread)
		decompileFails += 1
		if decompileFails >= 3 then   -- [PERF] เดิม 5
			decompileFails, decompilePausedUntil = 0, os.clock() + 10  -- เดิม 15
		end
		return nil, "timeout"
	end
	decompileFails = 0
	if type(result) ~= "string" or result == "" then return nil, errMsg and errMsg:sub(1, 80) or "empty" end
	return result
end

-- เริ่ม decompile ล่วงหน้าโดยไม่บล็อก (ถ้า slot ว่าง)
local function decompileAsync(scr)
	if decompileCache[scr] ~= nil then return end
	if decompileSem >= DECOMPILE_WORKERS then return end
	if os.clock() < decompilePausedUntil then return end
	decompileCache[scr] = true
	decompileSem += 1
	task.spawn(function()
		local code, why = decompileCore(scr)
		decompileCache[scr] = { code = code, why = why }
		decompileSem -= 1
	end)
end

local function decompileSafe(scr)
	-- ตรวจ prefetch cache ก่อน
	local cached = decompileCache[scr]
	if type(cached) == "table" then
		decompileCache[scr] = nil
		return cached.code, cached.why
	end
	-- prefetch กำลังรันอยู่ → รอ
	if cached == true then
		local deadline = os.clock() + DECOMPILE_TIMEOUT + 1
		while decompileCache[scr] == true and os.clock() < deadline do
			task.wait()
		end
		local res = decompileCache[scr]
		if type(res) == "table" then
			decompileCache[scr] = nil
			return res.code, res.why
		end
	end
	-- ไม่มี cache: decompile ตรงๆ
	return decompileCore(scr)
end

local function collectConstants(fn, out, seen, depth)
	if depth > 8 then return end   -- [PERF] เดิม 16
	for _, v in pairs(safe(function() return debug.getconstants(fn) end, {})) do
		local t = type(v)
		if t == "string" or t == "number" then
			local line = t == "string" and fmt("%q", v) or tostring(v)
			if not seen[line] then
				seen[line] = true
				out[#out + 1] = line
			end
		end
	end
	for _, proto in ipairs(safe(function() return debug.getprotos(fn) end, {})) do
		collectConstants(proto, out, seen, depth + 1)
	end
end

-- decompile ไม่ได้ -> constants หรือ bytecode ดิบ
local function bytecodeFallback(obj)
	local fn = safe(function() return getscriptclosure(obj) end)
	if type(fn) == "function" then
		local out = {}
		collectConstants(fn, out, {}, 0)
		if #out > 0 then return "-- [BYTECODE] constants\n" .. table.concat(out, "\n") end
	end
	local bc = safe(function() return getscriptbytecode(obj) end)
	if type(bc) == "string" and bc ~= "" then return "-- [BYTECODE] base64\n" .. base64encode(bc) end
end

-- สคริปต์เนื้อหาเหมือนกันจะไม่ดัมพ์ซ้ำ
local function dumpScript(lines, obj, path, ctx)
	local stats = ctx.cur.stats
	local hash = safe(function() return "hash:" .. getscripthash(obj) end)
	local function duplicate(first)
		stats.dupes += 1
		lines[#lines + 1] = "-- Source: DUPLICATE of " .. first
	end
	if hash and ctx.scriptSeen[hash] then return duplicate(ctx.scriptSeen[hash]) end

	local code, why = decompileSafe(obj)
	if code then
		local first = ctx.scriptSeen[code]
		if first then
			if hash then ctx.scriptSeen[hash] = first end
			return duplicate(first)
		end
		ctx.scriptSeen[code] = path
		stats.scripts += 1
		lines[#lines + 1] = "-- Source: saved as .lua at the same path as in Dex"
	else
		stats.srcFail += 1
		code = bytecodeFallback(obj)
		if not code then
			lines[#lines + 1] = "-- Source: unavailable (" .. why .. ")"
			return
		end
		lines[#lines + 1] = "-- Source: decompile failed (" .. why .. "), fallback saved as .lua"
	end
	if hash then ctx.scriptSeen[hash] = path end
	return code
end

local function describe(obj, ctx)
	local path = safe(function() return getPath(obj) end, fmt("<path error: %s.%s>", obj.ClassName, obj.Name))
	local lines = { fmt("-- [%s] %s", obj.ClassName, path) }

	local tags = safe(function() return collectionService:GetTags(obj) end, {})
	if #tags > 0 then
		table.sort(tags)
		lines[#lines + 1] = fmt("Tags: { %s }", table.concat(tags, ", "))
	end

	local attrs, keys = safe(function() return obj:GetAttributes() end, {}), {}
	for k in pairs(attrs) do keys[#keys + 1] = k end
	table.sort(keys)
	for i, k in ipairs(keys) do keys[i] = k .. " = " .. serialize(attrs[k]) end
	if #keys > 0 then lines[#lines + 1] = fmt("Attributes: { %s }", table.concat(keys, ", ")) end

	for _, key in ipairs(typeProps(obj) or {}) do
		lines[#lines + 1] = fmt("%s = %s", key, serialize(readProp(obj, key)))
	end

	local getter = gethiddenproperties or getproperties
	if ctx.everything and getter then
		local props, names = safe(function() return getter(obj) end, {}), {}
		for k, v in pairs(props) do
			if v ~= nil and v ~= "" then names[#names + 1] = tostring(k) end
		end
		table.sort(names)
		for _, k in ipairs(names) do lines[#lines + 1] = fmt("Prop %s = %s", k, serialize(props[k])) end
	end

	local source
	if obj:IsA("LuaSourceContainer") then
		if obj:IsA("BaseScript") then
			if readProp(obj, "Disabled") == true then lines[#lines + 1] = "Disabled = true" end
			local runContext = tostring(readProp(obj, "RunContext"))
			if runContext ~= "Enum.RunContext.Legacy" then lines[#lines + 1] = "RunContext = " .. runContext end
		end
		if ctx.scripts then source = dumpScript(lines, obj, path, ctx) end
	end

	local usage = USAGE[obj.ClassName]
	if usage then lines[#lines + 1] = "-- Usage: " .. fmt(usage, path) end
	return table.concat(lines, "\n"), source
end

-- เซฟสคริปต์เป็น .lua ตามโครงสร้างโฟลเดอร์แบบ Dex (ชื่อซ้ำจะต่อ (2), (3))
local function saveScript(obj, code, ctx)
	local names, cur = {}, obj
	while cur and cur ~= game do
		names[#names + 1] = cleanName(cur.Name)
		cur = cur.Parent
	end
	if not cur then names[#names + 1] = "NIL" end

	local dir = runDir
	for i = #names, 2, -1 do
		dir = dir .. "/" .. names[i]
		ensureFolder(dir)
	end
	local base = dir .. "/" .. names[1]
	local path, n = base .. ".lua", 1
	while ctx.used[path:lower()] do
		n += 1
		path = fmt("%s (%d).lua", base, n)
	end
	ctx.used[path:lower()] = true
	return safeWrite(path, code)
end

-- [PERF] DFS แบบ batch yield + prefetch decompile ล่วงหน้า
local function scanRoots(label, roots, childrenOnly, ctx)
	local stats = { visited = 0, dumped = 0, errors = 0, scripts = 0, dupes = 0, srcFail = 0 }
	local mapSink = newSink(label)
	local entry = { name = label, stats = stats, sinks = { mapSink } }
	ctx.sections[#ctx.sections + 1] = entry
	ctx.cur = { label = label, stats = stats }

	local stack = {}
	-- [PERF] push พร้อม prefetch decompile สำหรับ BaseScript ที่เจอ
	local function push(list)
		for j = #list, 1, -1 do
			local child = list[j]
			if not ctx.seen[child] then
				stack[#stack + 1] = child
				-- เริ่ม decompile ล่วงหน้าทันที (ไม่บล็อก)
				if ctx.scripts and safe(function() return child:IsA("BaseScript") end, false) then
					pcall(decompileAsync, child)
				end
			end
		end
	end

	if childrenOnly then
		for i = #roots, 1, -1 do push(safe(function() return roots[i]:GetChildren() end, {})) end
	else
		push(roots)
	end

	-- [PERF] batch counter: เช็ค clock ทุก yieldBatch รายการแทนทุกรายการ
	local speed = ctx.speed or SPEED_PRESETS.Normal
	local lastYield, lastUi, batchN = os.clock(), 0, 0
	while #stack > 0 and not mapCancelled do
		local obj = table.remove(stack)
		if not ctx.seen[obj] then
			ctx.seen[obj] = true
			stats.visited += 1

			if not (childrenOnly and obj.Parent == nil) then
				push(safe(function() return obj:GetChildren() end, {}))
				local okU, useful = pcall(ctx.actionableOnly and isActionable or isUseful, obj, ctx.everything)
				if okU and useful then
					local ok, text, source = pcall(describe, obj, ctx)
					if ok and text then
						mapSink:write(text)
						stats.dumped += 1
						if source then
							if singleFile then
								mapSink:write(fmt("=== %s ===\n%s\n", obj:GetFullName(), source))
							elseif not saveScript(obj, source, ctx) then
								stats.errors += 1
							end
						end
					else
						stats.errors += 1
						if #ctx.errors < 20 then ctx.errors[#ctx.errors + 1] = fmt("%s: %s", label, tostring(text)) end
					end
				end
			end
		end

		-- [PERF] เช็ค clock + yield เฉพาะทุก YIELD_BATCH รายการ
		batchN += 1
		if batchN >= speed.yieldBatch then
			batchN = 0
			local now = os.clock()
			if now - lastYield > speed.yieldInterval then
				task.wait()
				lastYield = os.clock()
				now = lastYield
			end
			if now - lastUi > 0.15 then
				lastUi = now
				setStatus(mapStatus, fmt("🔄 %s\nสแกน %d | ดัมพ์ %d | สคริปต์ %d (ซ้ำ %d)", label, stats.visited, stats.dumped, stats.scripts, stats.dupes))
			end
		end
	end

	entry.cancelled = mapCancelled
	for _, sink in pairs(entry.sinks) do sink:flush() end
end

local function runOnce(key, fn, getStatus, ...)
	if busy[key] then return notify("กำลังทำงานอยู่", "รอให้งานเดิมจบก่อนนะ", "Warning") end
	busy[key] = true
	local ok, err = pcall(fn, ...)
	busy[key] = nil
	if not ok then
		warn("[dumper] " .. key .. ": " .. tostring(err))
		setStatus(getStatus and getStatus(), "❌ " .. tostring(err):sub(1, 200))
		notify("เกิดข้อผิดพลาด", tostring(err):sub(1, 80), "Warning")
	end
end

local function writeIndex(ctx, startTime)
	local report = {
		fmt("# MAP DUMP v%s | Place: %d | %s", VERSION, game.PlaceId, os.date("%Y-%m-%d %H:%M:%S")),
		fmt("# Target: %s | Detail: %s | Scripts: %s | Elapsed: %.1fs%s", ctx.targetLabel, ctx.everything and "everything" or "useful",
			ctx.scripts and "decompiled" or "off", os.clock() - startTime, mapCancelled and " (STOPPED - partial)" or ""),
		"",
		"# COVERAGE",
	}
	local failed, files = 0, {}
	for _, e in ipairs(ctx.sections) do
		local s = e.stats
		report[#report + 1] = fmt("  %-24s visited=%d dumped=%d scripts=%d dupes=%d srcFail=%d errors=%d%s",
			e.name, s.visited, s.dumped, s.scripts, s.dupes, s.srcFail, s.errors, e.cancelled and " (cancelled)" or "")
		for _, sink in pairs(e.sinks) do
			failed += sink.failed
			for _, f in ipairs(sink.files) do files[#files + 1] = "  " .. f end
		end
	end
	report[#report + 1] = "\n# FILES"
	table.move(files, 1, #files, #report + 1, report)
	if failed > 0 then report[#report + 1] = fmt("\n# WARNING: %d part file(s) failed to write", failed) end
	if #ctx.errors > 0 then
		report[#report + 1] = "\n# ERRORS (first 20)"
		for _, msg in ipairs(ctx.errors) do report[#report + 1] = "  " .. msg end
	end
	return safeWrite(outPath("index.txt"), table.concat(report, "\n")), failed
end

local function parseTargets(raw)
	local picked, extras = {}, {}
	for _, v in ipairs(type(raw) == "table" and raw or { raw }) do
		if type(v) == "table" then v = v.Title or v.Name or v[1] end
		if EXTRA_TARGETS[v] then
			extras[v] = true
		elseif type(v) == "string" and v ~= "All" and not table.find(picked, v) then
			picked[#picked + 1] = v
		end
	end
	return picked, extras, #picked == 0 and next(extras) == nil
end

local function collectNil()
	local roots = {}
	for _, o in ipairs(safe(getnilinstances, {})) do
		if typeof(o) == "Instance" and safe(function() return o.Parent == nil end, false) then roots[#roots + 1] = o end
	end
	return roots
end

-- actor ที่ถูกลบ + สคริปต์บน foreign state ที่ไม่อยู่ใน DataModel
local function collectActors()
	local roots = {}
	for _, actor in ipairs(safe(getdeletedactors, {})) do roots[#roots + 1] = actor end
	if getallthreads and getscriptfromthread then
		for i, thread in ipairs(safe(getallthreads, {})) do
			local scr = safe(function() return getscriptfromthread(thread) end)
			if typeof(scr) == "Instance" and not safe(function() return scr:IsDescendantOf(game) end, false) then
				roots[#roots + 1] = scr
			end
			if i % 200 == 0 then task.wait() end
		end
	end
	return roots
end

local function describeFn(fn, withConstants)
	local info = safe(function() return debug.getinfo(fn) end, {})
	local text = fmt("%s:%s %s\nupvalues = %s", tostring(info.short_src or info.source), tostring(info.linedefined),
		tostring(info.name or "?"), toCode(safe(function() return debug.getupvalues(fn) end, {})))
	if withConstants then
		text ..= "\nconstants = " .. toCode(safe(function() return debug.getconstants(fn) end, {}))
	end
	return text
end

local function runtimeSection(ctx, label)
	local sink = newSink(label)
	local stats = { visited = 0, dumped = 0, errors = 0, scripts = 0, dupes = 0, srcFail = 0 }
	ctx.sections[#ctx.sections + 1] = { name = label, stats = stats, sinks = { sink } }
	return sink, stats
end

-- ข้อมูล runtime: ค่าที่ module return, handler ของ remote, ฟังก์ชัน/ตารางใน getgc
local function dumpRuntime(ctx)
	local lastYield = os.clock()
	local function alive()
		if os.clock() - lastYield > 0.012 then
			task.wait()
			lastYield = os.clock()
		end
		return not mapCancelled
	end
	local function nameOf(obj) return safe(function() return getPath(obj) end, tostring(obj)) end

	local sink, stats = runtimeSection(ctx, "RUNTIME_modules")
	for _, module in ipairs(safe(getloadedmodules, {})) do
		if not alive() then break end
		setthreadidentity(2)
		local ok, value = pcall(require, module)
		setthreadidentity(8)
		stats.visited += 1
		stats.dumped += 1
		sink:write(fmt("-- [Module] %s\n%s\n", nameOf(module), ok and toCode(value) or "-- require failed: " .. tostring(value)))
		if stats.visited % 20 == 0 then setStatus(mapStatus, fmt("🔄 RUNTIME modules %d", stats.visited)) end
	end
	sink:flush()

	sink, stats = runtimeSection(ctx, "RUNTIME_remotes")
	local remotes = (getinstances and safe(getinstances)) or game:GetDescendants()
	for _, obj in ipairs(remotes) do
		if not alive() then break end
		local ok, kind = pcall(function()
			if obj:IsA("BaseRemoteEvent") then return "OnClientEvent" end
			if obj:IsA("BindableEvent") then return "Event" end
			if obj:IsA("RemoteFunction") then return "OnClientInvoke" end
			if obj:IsA("BindableFunction") then return "OnInvoke" end
		end)
		if ok and kind then
			stats.visited += 1
			local fns, lines = {}, { fmt("-- [%s] %s", obj.ClassName, nameOf(obj)) }
			if kind == "OnClientEvent" or kind == "Event" then
				for _, conn in ipairs(safe(function() return getconnections(obj[kind]) end, {})) do
					fns[#fns + 1] = conn.Function or false
				end
			else
				fns[1] = safe(function() return getcallbackvalue(obj, kind) end, false)
			end
			for _, fn in ipairs(fns) do
				if type(fn) ~= "function" then
					lines[#lines + 1] = "  " .. kind .. ": foreign state / none"
				elseif not isexecutorclosure(fn) then
					lines[#lines + 1] = "  " .. kind .. ": " .. describeFn(fn)
				end
			end
			if #lines > 1 then
				stats.dumped += 1
				sink:write(table.concat(lines, "\n") .. "\n")
			end
			if stats.visited % 50 == 0 then setStatus(mapStatus, fmt("🔄 RUNTIME remotes %d", stats.visited)) end
		end
	end
	sink:flush()

	sink, stats = runtimeSection(ctx, "RUNTIME_gc_functions")
	for _, fn in ipairs(safe(function() return getgc(false) end, {})) do
		if not alive() then break end
		if type(fn) == "function" and islclosure(fn) and not isexecutorclosure(fn) then
			stats.visited += 1
			stats.dumped += 1
			sink:write("-- [Function] " .. describeFn(fn, true) .. "\n")
			if stats.visited % 100 == 0 then setStatus(mapStatus, fmt("🔄 RUNTIME getgc functions %d", stats.visited)) end
		end
	end
	sink:flush()

	if ctx.gcTables then
		sink, stats = runtimeSection(ctx, "RUNTIME_gc_tables")
		for _, t in ipairs(safe(function() return getgc(true) end, {})) do
			if not alive() or stats.dumped >= 3000 then break end
			if type(t) == "table" and t ~= env and next(t) ~= nil then
				stats.visited += 1
				stats.dumped += 1
				sink:write("-- [Table]\n" .. toCode(t) .. "\n")
				if stats.visited % 50 == 0 then setStatus(mapStatus, fmt("🔄 RUNTIME getgc tables %d", stats.visited)) end
			end
		end
		sink:flush()
	end
end

local function startMapDump(opts)
	opts = opts or {}
	local picked, extras, isAll = parseTargets(opts.target)
	local labels = table.clone(picked)
	for key in pairs(extras) do labels[#labels + 1] = key end
	table.sort(labels)

	local ctx = {
		targetLabel = isAll and "All" or table.concat(labels, ", "),
		everything = opts.detail == "Everything",
		actionableOnly = opts.detail == "Actionable",
		scripts = opts.scripts ~= false and decompile ~= nil, gcTables = opts.gcTables == true,
		speed = SPEED_PRESETS[opts.speed] or SPEED_PRESETS.Normal,
		sections = {}, errors = {}, seen = {}, scriptSeen = {}, used = {},
	}
	local startTime = os.clock()
	mapCancelled, indexCache, decompileFails, decompilePausedUntil = false, {}, 0, 0
	-- [PERF] ล้าง prefetch cache ของ run ก่อน
	for k in next, decompileCache do decompileCache[k] = nil end
	table.clear(pathCache)
	newRunDir()

	singleFile = opts.single == true
	if singleFile and not safeWrite(outPath("all.txt"), "# MAP DUMP - single file | Place: " .. game.PlaceId .. "\n") then
		singleFile = false
	end
	setStatus(mapStatus, "🔄 กำลังสแกน...")

	local jobs = {}
	local function add(label, getRoots, childrenOnly) jobs[#jobs + 1] = { label, getRoots, childrenOnly } end
	local function want(key, flag) return (isAll and opts[flag] ~= false) or extras[key] end

	local names = picked
	if isAll then
		names = table.clone(ALL_SERVICES)
		for _, child in ipairs(game:GetChildren()) do
			if not table.find(names, child.ClassName) then names[#names + 1] = child.ClassName end
		end
	end
	for _, name in ipairs(names) do
		local service = safe(function() return game:GetService(name) end)
		if service then
			add(name, function() return { service } end, true)
		elseif not isAll then
			ctx.errors[#ctx.errors + 1] = name .. ": เกมนี้ไม่มี service นี้"
		end
	end
	if want("NIL", "nilInst") and getnilinstances then add("NIL", collectNil, false) end
	if want("HUI", "hiddenUi") and gethui then add("HUI", function() return { gethui() } end, true) end
	if want("ACTORS", "actors") then add("ACTORS", collectActors, false) end
	if extras.CLIENT then add("CLIENT", function() return { localPlayer, localPlayer.Character } end, true) end

	local ok, err = pcall(function()
		for _, job in ipairs(jobs) do
			if mapCancelled then break end
			local roots = job[2]()
			if #roots > 0 then
				local okScan, scanErr = pcall(scanRoots, job[1], roots, job[3], ctx)
				if not okScan then
					ctx.errors[#ctx.errors + 1] = fmt("%s: section ล้มเหลว (%s)", job[1], tostring(scanErr))
					for _, sink in pairs(ctx.sections[#ctx.sections].sinks) do pcall(sink.flush, sink) end
				end
			end
		end
	end)
	indexCache = nil
	if want("RUNTIME", "runtime") and not mapCancelled then
		local okRt, errRt = pcall(dumpRuntime, ctx)
		if not okRt then ok, err = false, errRt end
	end
	if not ok then ctx.errors[#ctx.errors + 1] = "ผิดพลาดร้ายแรง: " .. tostring(err) end

	local saved, failed = writeIndex(ctx, startTime)
	local good = saved and ok and failed == 0
	setStatus(mapStatus, good and ("✅ เสร็จแล้ว! → " .. runDir) or "⚠ จบแต่มีปัญหา — ดู index.txt")
	notify("Map Dump", good and "✅ เสร็จสมบูรณ์" or "⚠ ได้บางส่วน", good and "Success" or "Warning")
end

local function dumpPlayerData()
	if not localPlayer then error("ไม่พบ LocalPlayer", 0) end
	setStatus(mapStatus, "🔄 กำลังสแกน...")

	local lines = {}
	local function add(s) lines[#lines + 1] = s end
	add("# PLAYER DATA | " .. os.date("%Y-%m-%d %H:%M:%S"))
	add(fmt("Name: %s\nDisplayName: %s\nUserId: %d\nAccountAge: %d", localPlayer.Name, localPlayer.DisplayName, localPlayer.UserId, localPlayer.AccountAge))

	local stats = localPlayer:FindFirstChild("leaderstats")
	if stats then
		add("\n# Leaderstats:")
		for _, v in ipairs(stats:GetChildren()) do
			if v:IsA("ValueBase") then add(fmt("  %s = %s", v.Name, serialize(readProp(v, "Value")))) end
		end
	end

	local char = localPlayer.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if humanoid then
		add(fmt("\n# Character:\n  Health = %s | WalkSpeed = %s | JumpPower = %s",
			serialize(humanoid.Health), serialize(humanoid.WalkSpeed), serialize(readProp(humanoid, "JumpPower"))))
	end
	if root then add("  Position = " .. serialize(root.Position)) end

	for _, group in ipairs({ { "Equipped", char }, { "Backpack", localPlayer:FindFirstChildOfClass("Backpack") } }) do
		if group[2] then
			add("\n# " .. group[1] .. ":")
			for _, tool in ipairs(group[2]:GetChildren()) do
				if tool:IsA("Tool") then add("  Tool: " .. tool.Name) end
			end
		end
	end

	getRunDir()
	local path = outPath("player.txt")
	local saved = safeWrite(path, table.concat(lines, "\n"))
	setStatus(mapStatus, saved and ("✅ เสร็จแล้ว! → " .. path) or "❌ writefile ล้มเหลว")
	notify("Player Dump", saved and "✅ เสร็จสมบูรณ์" or "❌ writefile ล้มเหลว", saved and "Success" or "Warning")
end

-- Remote Spy: hook แค่จดลงคิว งานหนักทำใน worker thread
local spyActive, spyDirty, spyKeyCount, spyTotal, spyRun = false, false, 0, 0, 0
local spyData, spyQueue, inboundConns = {}, {}, {}

-- เก็บ hook ไว้ใน getgenv() รันซ้ำจะได้ไม่ hook ซ้อน
local hook = env.__MAPDUMPER_HOOK or {}
env.__MAPDUMPER_HOOK = hook

local function enqueue(self, method, ...)
	if #spyQueue < QUEUE_MAX then spyQueue[#spyQueue + 1] = { self, method, table.pack(...) } end
end

hook.record = function(...)
	if spyActive then enqueue(...) end
end

local function logCall(self, method, packed)
	local key = getPath(self) .. ":" .. method
	local entry = spyData[key]
	if not entry then
		if spyKeyCount >= KEY_MAX then return end
		spyKeyCount += 1
		entry = { count = 0, samples = {}, seen = {}, class = self.ClassName }
		spyData[key] = entry
	end
	entry.count += 1
	spyTotal += 1
	spyDirty = true

	if #entry.samples < 5 then
		local args = {}
		for i = 1, math.min(packed.n, 8) do args[i] = serialize(packed[i]) end
		local sample = table.concat(args, ", ")
		if not entry.seen[sample] then
			entry.seen[sample] = true
			entry.samples[#entry.samples + 1] = sample
		end
	end
end

local function spyDrain(noYield)
	local queue = spyQueue
	spyQueue = {}
	for i, item in ipairs(queue) do
		pcall(logCall, item[1], item[2], item[3])
		if not noYield and i % 200 == 0 then task.wait() end
	end
end

local function spyFlush()
	local keys = {}
	for key in pairs(spyData) do keys[#keys + 1] = key end
	table.sort(keys)
	local out = { "# REMOTE SPY REPORT | " .. os.date("%Y-%m-%d %H:%M:%S"), "" }
	for _, key in ipairs(keys) do
		local e = spyData[key]
		out[#out + 1] = fmt("## %s\n  Class: %s\n  Calls: %d\n  Args:\n    - %s\n", key, e.class, e.count, table.concat(e.samples, "\n    - "))
	end
	spyDirty = false
	getRunDir()
	safeWrite(outPath("remote_spy.txt"), table.concat(out, "\n"))
end

local function setupHooks()
	if hook.orig then return true end
	local getMethod, setMethod, isOwnCall, isOurs = getnamecallmethod, setnamecallmethod, checkcaller, isourthread

	local fn = newcclosure(function(self, ...)
		local method = getMethod()
		if method == "Kick" and self == localPlayer then return end
		if not SPY_METHODS[method] or isOwnCall() or (isOurs and isOurs()) then return hook.orig(self, ...) end
		pcall(hook.record, self, method, ...)
		pcall(setMethod, method)
		return hook.orig(self, ...)
	end)
	pcall(setstackhidden, fn, true)
	pcall(debug.setinfo, fn, "s", "[C]")
	pcall(debug.setname, fn, "")

	local ok, orig = pcall(hookmetamethod, game, "__namecall", fn)
	if ok and orig then hook.orig = orig end
	return hook.orig ~= nil
end

-- ขาเข้า (server -> client): OnClientEvent
local function hookInbound(remote)
	if not spyActive or not remote:IsA("BaseRemoteEvent") then return end
	local ok, conn = pcall(function()
		return remote.OnClientEvent:Connect(function(...)
			if spyActive then enqueue(remote, "OnClientEvent", ...) end
		end)
	end)
	if ok then inboundConns[#inboundConns + 1] = conn end
end

local function startInbound()
	local root = cloneref(game:GetService("ReplicatedStorage"))
	inboundConns[#inboundConns + 1] = root.DescendantAdded:Connect(hookInbound)
	task.spawn(function()
		for i, obj in ipairs(root:GetDescendants()) do
			if not spyActive then break end
			hookInbound(obj)
			if i % 500 == 0 then task.wait() end
		end
	end)
end

local function stopInbound()
	for _, conn in ipairs(inboundConns) do pcall(conn.Disconnect, conn) end
	inboundConns = {}
end

local function spyStart()
	if spyActive then return end
	spyActive, spyData, spyQueue, spyKeyCount, spyTotal = true, {}, {}, 0, 0

	if not setupHooks() then
		spyActive = false
		setStatus(spyStatus, "❌ ติด hook ไม่สำเร็จ (hookmetamethod: " .. tostring(hookmetamethod ~= nil) .. ")")
		if spyToggle then pcall(spyToggle.Set, spyToggle, false, true) end
		return
	end

	startInbound()
	spyRun += 1
	local myRun = spyRun
	task.spawn(function()
		local lastFlush = os.clock()
		while spyActive and spyRun == myRun do
			task.wait(0.5)
			pcall(spyDrain)
			setStatus(spyStatus, fmt("🔴 กำลังดักจับ\nจับได้ %d ครั้ง | %d remote", spyTotal, spyKeyCount))
			if spyDirty and os.clock() - lastFlush >= 2 then
				lastFlush = os.clock()
				pcall(spyFlush)
			end
		end
	end)
end

local function spyStop()
	if not spyActive then return end
	spyActive = false
	spyRun += 1
	stopInbound()
	pcall(spyDrain, true)
	pcall(spyFlush)
	setStatus(spyStatus, "🟢 หยุดแล้ว\n" .. (getRunDir() and outPath("remote_spy.txt")))
end

-- UI
local settings = {
	target = { "All" }, detail = "Everything", scripts = decompile ~= nil,
	nilInst = true, hiddenUi = true, actors = true, single = false, runtime = true, gcTables = false,
	speed = "Normal",
}

local function saveGame()
	getRunDir()
	setStatus(mapStatus, "🔄 saveinstance...")
	local ok, err = pcall(saveinstance, game, { FileName = outPath("game") })
	setStatus(mapStatus, ok and "✅ saveinstance เสร็จ (ดูในโฟลเดอร์ workspace)" or ("❌ " .. tostring(err):sub(1, 150)))
end

local function stopAll()
	mapCancelled = true
	pcall(spyStop)
	stopInbound()
end

local function stopMapDump()
	if not busy.map then return notify("ไม่มีงานที่รันอยู่", "ยังไม่ได้เริ่มดัมพ์", "Warning") end
	mapCancelled = true
	setStatus(mapStatus, "🔄 กำลังหยุด... (เซฟเท่าที่ได้)")
end

env.MapDumper = {
	settings = settings,
	mapDump = function() task.spawn(runOnce, "map", startMapDump, nil, settings) end,
	mapStop = stopMapDump,
	spyStart = spyStart,
	spyStop = spyStop,
	player = dumpPlayerData,
}
env.__MAPDUMPER_CLEANUP = function()
	stopAll()
	local old = window
	window = nil
	if old then task.spawn(pcall, function() old:Destroy() end) end
end

local function loadUI()
	local body = httpGet(UI_URL)
	local chunk = body and loadstring(body)
	if not chunk then return end
	local ok, lib = pcall(chunk)
	if ok and type(lib) == "table" and lib.SpectreUI then return lib end
end

local ui = loadUI()
if not ui then
	warn("[dumper] โหลด SpectreUI ไม่ได้ -> ดัมพ์แมพแบบไม่มี UI (ใช้ getgenv().MapDumper ได้)")
	return task.spawn(runOnce, "map", startMapDump, nil, settings)
end
if ui.OnUnload then pcall(ui.OnUnload, stopAll) end

window = ui.SpectreUI:CreateWindow({
	Brand = { Title = "MAP", Accent = "DUMPER", Subtitle = "v" .. VERSION, Icon = "zap" },
	Theme = "Midnight",
	ToggleKey = Enum.KeyCode.RightControl,
})

local function newStatus(section, text)
	local paragraph = section:CreateParagraph({ Title = "สถานะ", Content = (splitState(text)) })
	setStatus(paragraph, text)
	return paragraph
end

local function getMapStatus() return mapStatus end

local mapTab = window:CreateTab({ Name = "Map Dumper", Icon = "package" })
local mapSection = mapTab:CreateSection({ Name = "ดัมพ์แมพ" })
mapStatus = newStatus(mapSection, "🟢 พร้อม")

for _, b in ipairs({
	{ "เริ่มดัมพ์", "download", function() task.spawn(runOnce, "map", startMapDump, getMapStatus, settings) end },
	{ "หยุด (เซฟเท่าที่ได้)", "square", stopMapDump },
	{ "saveinstance (.rbxl)", "save", function() task.spawn(runOnce, "save", saveGame, getMapStatus) end },
	{ "ดัมพ์ข้อมูลผู้เล่น", "scan-face", function() task.spawn(runOnce, "player", dumpPlayerData, getMapStatus) end },
}) do
	mapSection:CreateButton({ Name = b[1], Icon = b[2], Callback = b[3] })
end

local okSection, optionSection = pcall(mapTab.CreateSection, mapTab, { Name = "ตัวเลือก" })
optionSection = okSection and optionSection or mapSection

optionSection:CreateDropdown({
	Name = "Target (เลือกได้หลายอัน | ไม่เลือกเฉพาะ = All)",
	Options = { "All", "NIL", "HUI", "ACTORS", "CLIENT", "RUNTIME", table.unpack(ALL_SERVICES) },
	Default = { "All" },
	Multi = true,
	Callback = function(v) settings.target = type(v) == "table" and v or { v } end,
})
optionSection:CreateDropdown({
	Name = "ความละเอียด (Quick=สำคัญ | Full=ทุกอย่าง | Actionable=ยิง/เรียกสคริปได้เท่านั้น)",
	Options = { "Quick", "Full", "Actionable" },
	Default = "Full",
	Callback = function(v)
		v = type(v) == "table" and v[1] or v
		settings.detail = v == "Full" and "Everything" or (v == "Actionable" and "Actionable" or "Useful only")
	end,
})
optionSection:CreateDropdown({
	Name = "ความเร็วดัมพ์ (Safe=เบาเฟรม | Normal | Fast | Turbo=ไม่ yield เลย เสี่ยงเฟรมกระตุก)",
	Options = { "Safe", "Normal", "Fast", "Turbo" },
	Default = settings.speed,
	Callback = function(v)
		v = type(v) == "table" and v[1] or v
		settings.speed = SPEED_PRESETS[v] and v or "Normal"
	end,
})
for _, s in ipairs({
	{ "ดีคอมไพล์สคริปต์", "scripts" },
	{ "รวม nil instances (ตอนเลือก All)", "nilInst" },
	{ "รวม gethui() (ตอนเลือก All)", "hiddenUi" },
	{ "รวม Actor ที่ถูกลบ + foreign state (ตอนเลือก All)", "actors" },
	{ "Runtime dump: modules / remotes / getgc (ตอนเลือก All)", "runtime" },
	{ "รวม getgc tables (หนักมาก)", "gcTables" },
	{ "Single file (รวมเป็นไฟล์เดียว)", "single" },
}) do
	optionSection:CreateToggle({ Name = s[1], Default = settings[s[2]], Callback = function(on) settings[s[2]] = on end })
end

local spySection = window:CreateTab({ Name = "Remote Spy", Icon = "radar" }):CreateSection({ Name = "ตรวจจับ Remotes" })
spyStatus = newStatus(spySection, "🟢 ปิดอยู่ (เปิดสวิตช์ข้างล่างเพื่อเริ่มจับ)")
spyToggle = spySection:CreateToggle({
	Name = "เปิดใช้งาน Spy",
	Default = false,
	Callback = function(on)
		if on then
			task.spawn(runOnce, "spy", spyStart, function() return spyStatus end)
		else
			task.spawn(spyStop)
		end
	end,
})

local aboutSection = window:CreateTab({ Name = "เกี่ยวกับ", Icon = "info" }):CreateSection({ Name = "MapDumper v" .. VERSION })
aboutSection:CreateParagraph({
	Title = "วิธีใช้",
	Content = "กด RightControl เพื่อซ่อน/แสดงเมนู\nผลลัพธ์เซฟที่ dump.map/<ชื่อแมพ>",
})
aboutSection:CreateButton({ Name = "ปิด Dumper", Icon = "power", Callback = env.__MAPDUMPER_CLEANUP })
