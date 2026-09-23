-- SpectreWare Notification Library  (rewrite — procedural, ไม่พึ่ง rbxassetid template)
-- UI เดิมโดย IceMinister#9889 · เวอร์ชันนี้สร้างการ์ดจากโค้ดทั้งหมด
-- เลย์เอาต์การ์ด: [ไอคอนโหมด + ชื่อโหมดตัวหนา] → [แถบเวลาเต็มความกว้าง] → [ข้อความ] (โทนเดิม เข้ากับ ui ประกาศ)
--
-- API (เข้ากันได้กับของเดิม):
--   NotificationLibrary:SendNotification(Mode, Text, Duration)
--       Mode = "Success" | "Info" | "Warning" | "Error"   (ไม่รู้จัก → Info)
--       Text = ข้อความ (RichText เปิดอยู่)     Duration = วินาที (1–30, ค่าเริ่มต้น 4)
--   NotificationLibrary:Clear()   -- ปิดทุกการ์ดแบบมีอนิเมชัน
--   NotificationLibrary:Load()    -- สร้าง GUI ล่วงหน้า (ไม่จำเป็น เผื่อโค้ดเก่าเรียก)
--   NotificationLibrary:Destroy() -- ลบ GUI ทั้งหมด
--
-- หลักที่ทำให้ลื่น/นิ่ง:
--   • มีแค่ "ความสูงของ slot" ที่ไปกระทบ UIListLayout — การ์ดข้างล่างจึงเลื่อนขึ้นนุ่ม ๆ ตอนอันบนหายไป
--   • การ์ดเลื่อนเข้า/ออกทาง Position + เฟดด้วย CanvasGroup (ไม่ใช้ TextScaled ระหว่างอนิเมชัน)
--   • วัดความสูงจริงของข้อความก่อนเล่นอนิเมชัน → ไม่กระตุก ไม่เด้งข้าม (ไม่ใช้ Back easing กับ layout)
--   • ไม่พึ่ง asset ภายนอก / cloneref / gethui เป็นข้อบังคับ — มี fallback ทุกจุด
--   • จำกัดจำนวนการ์ดพร้อมกัน, เคลียร์ตัวเองแม้เกิด error กลางทาง, สร้าง GUI ใหม่ถ้าถูกลบ

local NotificationLibrary = {}

local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local Players      = game:GetService("Players")

local cloneref_ = cloneref or function(x) return x end

-- ── ปรับได้ตรงนี้ ─────────────────────────────────────────────────────────────
local GUI_NAME         = "SW_Notifications"
local LEGACY_NAME      = "Notification Library"   -- GUI ของเวอร์ชันเก่า (ลบทิ้งถ้าค้างอยู่)
local MAX_VISIBLE      = 5
local DEFAULT_DURATION = 4
local CARD_MAX_WIDTH   = 340    -- px
local WIDTH_SCALE      = 0.42   -- สัดส่วนความกว้างจอ (ก่อนโดน MaxWidth)
local MARGIN_RIGHT     = 16     -- px
local ANCHOR_Y         = 0.23   -- ตำแหน่งแนวตั้งของกอง (สัดส่วนความสูงจอ) — ขยับลงจาก 0.18 ให้เว้นจาก top bar มากขึ้น
local GAP              = 8      -- px ระหว่างการ์ด
local TEXT_SIZE        = 15
local TITLE_SIZE       = 17     -- ขนาดหัวข้อ (ชื่อโหมดตัวหนา แบบการ์ดประกาศ)
local ICON_BOX         = 26     -- กรอบไอคอนหัวข้อ (px)
local BAR_HEIGHT       = 4      -- ความสูงแถบเวลาที่วิ่งเต็มความกว้าง (px)
local CORNER           = 10
local SLIDE_OFFSET     = 56     -- px ที่เลื่อนเข้า/ออกจากขวา
local BG_COLOR         = Color3.fromRGB(18, 18, 24)
local BG_TRANSPARENCY  = 0.06
local BODY_TEXT_COLOR  = Color3.fromRGB(180, 180, 196)  -- สีข้อความเนื้อหา (โทนเทาเดียวกันทุกโหมด)
local SHADOW_TRANSPARENCY = 0.55
local STROKE_TRANSPARENCY = 0.45
local SYNC_DISMISS      = true   -- true = แจ้งเตือนที่โชว์ค้างพร้อมกันจะหายไปพร้อมกัน (ตามอันที่หมดเวลาทีหลังสุด)
local HARD_GRACE       = 3      -- วินาที: เกินเวลานี้หลังหมดอายุ ตัวเก็บกวาดจะสั่งปิด/ลบให้ (กันค้าง)

local THEMES = {
    Success = { accent = Color3.fromRGB(80, 220, 130), text = Color3.fromRGB(80, 220, 130),  icon = Color3.fromRGB(80, 220, 130),  symbol = "check" },
    Info    = { accent = Color3.fromRGB(90, 160, 250), text = Color3.fromRGB(228, 228, 238), icon = Color3.fromRGB(210, 210, 225), symbol = "i" },
    Warning = { accent = Color3.fromRGB(250, 190, 60), text = Color3.fromRGB(250, 190, 60),  icon = Color3.fromRGB(250, 190, 60),  symbol = "bang" },
    Error   = { accent = Color3.fromRGB(235, 70, 70),  text = Color3.fromRGB(235, 70, 70),   icon = Color3.fromRGB(235, 70, 70),   symbol = "x" },
}

-- ── Tween presets ─────────────────────────────────────────────────────────────
local T_IN_SIZE   = TweenInfo.new(0.40, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local T_IN_SLIDE  = TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local T_IN_FADE   = TweenInfo.new(0.30, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local T_OUT_SLIDE = TweenInfo.new(0.30, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
local T_OUT_FADE  = TweenInfo.new(0.26, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local T_OUT_SIZE  = TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
local OUT_SLIDE_WAIT, OUT_SIZE_WAIT = 0.30, 0.32

-- ── Helpers ───────────────────────────────────────────────────────────────────
local GROUP_OK
do
    local ok, inst = pcall(Instance.new, "CanvasGroup")
    GROUP_OK = ok and inst ~= nil
    if ok and inst then pcall(function() inst:Destroy() end) end
end

local function mk(cls, props, parent)
    local i = Instance.new(cls)
    for k, v in pairs(props) do pcall(function() i[k] = v end) end
    if parent then i.Parent = parent end
    return i
end

local function play(inst, info, props)
    local ok, tw = pcall(function()
        local t = TweenService:Create(inst, info, props)
        t:Play()
        return t
    end)
    return ok and tw or nil
end

local function frameWait()
    local dt = RunService.Heartbeat:Wait()
    return type(dt) == "number" and dt or 0.03
end

-- ── Icons (วาดจาก Frame ล้วน ๆ — ไม่พึ่ง asset / font emoji) ───────────────────
-- ใน Text ใส่อีโมจิเดิมได้เลย ระบบจะสลับเป็นไอคอนให้อัตโนมัติ:
--   ⚡ bolt · ✔ ✓ ✅ check · ⏳ ⌛ hourglass · 🔑 key · ⚠ warn · 👑 crown · 🎁 gift · ❌ x
-- ถ้าข้อความไม่มีอีโมจิเหล่านี้ จะใช้ TextLabel เดียว (RichText + ตัดบรรทัดแบบปกติ — รองรับไทยไม่มีเว้นวรรค)
-- ถ้ามี: วางไอคอนนำหน้าท่อนข้อความทีละแถว (ไม่ตัดคำทีละคำอีกต่อไป กันบั๊กคำไทยยาวโดนตัดกลางคำ)
local TEXT_LINE_H = math.floor(TEXT_SIZE * 1.4 + 0.5)
local ICON_PX     = TEXT_LINE_H - 4

local atan2 = math.atan2 or math.atan

local ICON_TOKENS = {
    { "\u{26A1}",  "bolt" },      { "\u{2714}", "check" },  { "\u{2713}", "check" },
    { "\u{2705}",  "check" },     { "\u{23F3}", "hourglass" }, { "\u{231B}", "hourglass" },
    { "\u{1F511}", "key" },       { "\u{26A0}", "warn" },   { "\u{1F451}", "crown" },
    { "\u{1F381}", "gift" },      { "\u{274C}", "x" },
}
local VS16 = "\u{FE0F}"

local ICON_COLORS = {
    bolt      = Color3.fromRGB(255, 214, 10),
    check     = Color3.fromRGB(80, 220, 130),
    x         = Color3.fromRGB(235, 70, 70),
    hourglass = Color3.fromRGB(250, 190, 60),
    key       = Color3.fromRGB(240, 205, 110),
    crown     = Color3.fromRGB(255, 200, 60),
    gift      = Color3.fromRGB(240, 120, 170),
    warn      = Color3.fromRGB(250, 190, 60),
}

-- พิกัดเป็นสัดส่วน 0..1 ของกรอบไอคอน (สี่เหลี่ยมจัตุรัส)
local function seg(parent, x1, y1, x2, y2, th, color)
    local dx, dy = x2 - x1, y2 - y1
    local len = math.sqrt(dx * dx + dy * dy)
    local f = mk("Frame", {
        BackgroundColor3 = color, BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale((x1 + x2) / 2, (y1 + y2) / 2),
        Size = UDim2.fromScale(len + th, th), -- +th ให้หัวมนของเส้นต่อกันสนิท
        Rotation = math.deg(atan2(dy, dx)),
    }, parent)
    mk("UICorner", { CornerRadius = UDim.new(1, 0) }, f)
    return f
end

local function poly(parent, pts, th, color, closed)
    for i = 1, #pts - 1 do
        seg(parent, pts[i][1], pts[i][2], pts[i + 1][1], pts[i + 1][2], th, color)
    end
    if closed and #pts > 2 then
        seg(parent, pts[#pts][1], pts[#pts][2], pts[1][1], pts[1][2], th, color)
    end
end

local function dot(parent, cx, cy, d, color)
    local f = mk("Frame", {
        BackgroundColor3 = color, BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(cx, cy), Size = UDim2.fromScale(d, d),
    }, parent)
    mk("UICorner", { CornerRadius = UDim.new(1, 0) }, f)
    return f
end

local function ring(parent, cx, cy, d, thPx, color)
    local f = mk("Frame", {
        BackgroundTransparency = 1, BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(cx, cy), Size = UDim2.fromScale(d, d),
    }, parent)
    mk("UICorner", { CornerRadius = UDim.new(1, 0) }, f)
    mk("UIStroke", { Color = color, Thickness = thPx }, f)
    return f
end

local DRAW = {
    check = function(p, c)
        poly(p, { { 0.14, 0.54 }, { 0.40, 0.80 }, { 0.88, 0.24 } }, 0.16, c)
    end,
    x = function(p, c)
        seg(p, 0.20, 0.20, 0.80, 0.80, 0.16, c)
        seg(p, 0.80, 0.20, 0.20, 0.80, 0.16, c)
    end,
    i = function(p, c)
        dot(p, 0.5, 0.16, 0.22, c)
        seg(p, 0.5, 0.42, 0.5, 0.86, 0.22, c)
    end,
    bang = function(p, c)
        seg(p, 0.5, 0.12, 0.5, 0.58, 0.22, c)
        dot(p, 0.5, 0.86, 0.24, c)
    end,
    bolt = function(p, c)
        poly(p, { { 0.58, 0.06 }, { 0.22, 0.56 }, { 0.50, 0.56 }, { 0.42, 0.94 },
                  { 0.80, 0.42 }, { 0.52, 0.42 } }, 0.12, c, true)
    end,
    hourglass = function(p, c)
        seg(p, 0.20, 0.10, 0.80, 0.10, 0.13, c)
        seg(p, 0.20, 0.90, 0.80, 0.90, 0.13, c)
        seg(p, 0.30, 0.10, 0.70, 0.90, 0.12, c)
        seg(p, 0.70, 0.10, 0.30, 0.90, 0.12, c)
    end,
    key = function(p, c, px)
        ring(p, 0.30, 0.70, 0.40, math.max(1, 0.12 * px), c)
        seg(p, 0.42, 0.58, 0.90, 0.10, 0.12, c)
        seg(p, 0.74, 0.26, 0.86, 0.38, 0.12, c)
        seg(p, 0.62, 0.38, 0.72, 0.48, 0.12, c)
    end,
    crown = function(p, c)
        poly(p, { { 0.10, 0.82 }, { 0.10, 0.30 }, { 0.32, 0.56 }, { 0.50, 0.18 },
                  { 0.68, 0.56 }, { 0.90, 0.30 }, { 0.90, 0.82 } }, 0.12, c, true)
    end,
    gift = function(p, c)
        poly(p, { { 0.14, 0.44 }, { 0.14, 0.90 }, { 0.86, 0.90 }, { 0.86, 0.44 } }, 0.11, c)
        poly(p, { { 0.08, 0.30 }, { 0.92, 0.30 }, { 0.92, 0.44 }, { 0.08, 0.44 } }, 0.11, c, true)
        seg(p, 0.50, 0.30, 0.50, 0.90, 0.11, c)
        poly(p, { { 0.50, 0.30 }, { 0.30, 0.08 }, { 0.20, 0.22 }, { 0.50, 0.30 } }, 0.10, c)
        poly(p, { { 0.50, 0.30 }, { 0.70, 0.08 }, { 0.80, 0.22 }, { 0.50, 0.30 } }, 0.10, c)
    end,
    warn = function(p, c)
        poly(p, { { 0.50, 0.08 }, { 0.93, 0.88 }, { 0.07, 0.88 } }, 0.11, c, true)
        seg(p, 0.50, 0.38, 0.50, 0.60, 0.11, c)
        dot(p, 0.50, 0.76, 0.12, c)
    end,
}

-- ไอคอนหัวข้อของการ์ด: สัญลักษณ์กลางกรอบ (scale ปรับได้ — หัวข้อไม่มีวงแหวนล้อมแล้ว จึงขยายได้เต็มตา)
local function drawSymbol(parent, name, color, px, scale)
    local fn = DRAW[name]
    if not fn then return end
    scale = scale or 0.56
    local inner = mk("Frame", {
        BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(scale, scale),
    }, parent)
    fn(inner, color, px * scale)
end

-- แยกข้อความเป็น {t="text"|"icon", v=...}
local function tokenize(text)
    local segs, pos = {}, 1
    while pos <= #text do
        local bs, be, bn
        for _, pair in ipairs(ICON_TOKENS) do
            local s, e = string.find(text, pair[1], pos, true)
            if s and (not bs or s < bs) then bs, be, bn = s, e, pair[2] end
        end
        if not bs then
            segs[#segs + 1] = { t = "text", v = text:sub(pos) }
            break
        end
        if bs > pos then segs[#segs + 1] = { t = "text", v = text:sub(pos, bs - 1) } end
        segs[#segs + 1] = { t = "icon", v = bn }
        pos = be + 1
        if text:sub(pos, pos + #VS16 - 1) == VS16 then pos = pos + #VS16 end
    end
    return segs
end

local function iconItem(parent, name, order)
    local wrap = mk("Frame", {
        Name = "IconItem", BackgroundTransparency = 1, LayoutOrder = order,
        Size = UDim2.fromOffset(TEXT_LINE_H, TEXT_LINE_H),
    }, parent)
    local box = mk("Frame", {
        BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(ICON_PX, ICON_PX),
    }, wrap)
    local fn = DRAW[name]
    if fn then fn(box, ICON_COLORS[name] or Color3.new(1, 1, 1), ICON_PX) end
    return wrap
end

-- ส่วนข้อความของการ์ด (อยู่ใต้แถบเวลาเต็มความกว้าง — คืน Instance ที่ AutomaticSize Y, กว้างเต็มการ์ด)
-- ไม่มีอีโมจิ: TextLabel เดียวห่อบรรทัดปกติ (ปลอดภัยกับภาษาไทยที่ไม่มีเว้นวรรค)
-- มีอีโมจิ: วางไอคอนนำหน้าแล้วท่อนข้อความที่เหลือ "ห่อบรรทัดได้เต็มที่" ในแถวเดียวกัน (ไม่ตัดคำทีละคำ)
local function buildMessage(parent, text, theme)
    local segs = tokenize(text)
    local hasIcon = false
    for _, sg in ipairs(segs) do
        if sg.t == "icon" then hasIcon = true; break end
    end

    if not hasIcon then
        return mk("TextLabel", {
            Name = "Message", BackgroundTransparency = 1, LayoutOrder = 3,
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            Font = Enum.Font.Gotham, TextSize = TEXT_SIZE, TextColor3 = BODY_TEXT_COLOR,
            RichText = true, TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
            Text = text,
        }, parent)
    end

    local wrap = mk("Frame", {
        Name = "Message", BackgroundTransparency = 1, LayoutOrder = 3,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
    }, parent)
    mk("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2),
    }, wrap)

    local rowIdx, row, order, rowHasContent, pendingIconW = 0, nil, 0, false, 0
    local function newRow()
        rowIdx = rowIdx + 1; order = 0; rowHasContent = false; pendingIconW = 0
        row = mk("Frame", {
            Name = "Row", BackgroundTransparency = 1, LayoutOrder = rowIdx,
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        }, wrap)
        mk("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Top, Padding = UDim.new(0, 6),
        }, row)
    end
    newRow()

    for _, sg in ipairs(segs) do
        if sg.t == "icon" then
            if rowHasContent then newRow() end
            order = order + 1
            iconItem(row, sg.v, order)
            pendingIconW, rowHasContent = TEXT_LINE_H + 6, true
        else
            local first = true
            for part in (sg.v .. "\n"):gmatch("(.-)\n") do
                if not first then newRow() end
                first = false
                local t = part:gsub("^%s+", ""):gsub("%s+$", "")
                if t ~= "" then
                    order = order + 1
                    mk("TextLabel", {
                        Name = "Text", BackgroundTransparency = 1, LayoutOrder = order,
                        Size = UDim2.new(1, -pendingIconW, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                        Font = Enum.Font.Gotham, TextSize = TEXT_SIZE, TextColor3 = BODY_TEXT_COLOR,
                        RichText = true, TextWrapped = true,
                        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
                        Text = t,
                    }, row)
                    rowHasContent = true
                end
            end
        end
    end
    return wrap
end

-- ── GUI root ──────────────────────────────────────────────────────────────────
local gui, container
local activeList = {}
local seq = 0
local entering = false   -- กัน entrance animation ทับกัน
local startJanitor -- ประกาศไว้ก่อน (ฟังก์ชันอยู่ด้านล่าง)

local function alive()
    return gui ~= nil and gui.Parent ~= nil
end

local function attach(g)
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(g) end end)

    local parents = {}
    local okH, hui = pcall(function() return gethui and gethui() end)
    if okH and typeof(hui) == "Instance" then parents[#parents + 1] = hui end
    local okC, core = pcall(function() return cloneref_(game:GetService("CoreGui")) end)
    if okC and core then parents[#parents + 1] = core end
    local lp = Players.LocalPlayer
    local pg = lp and lp:FindFirstChildOfClass("PlayerGui")
    if pg then parents[#parents + 1] = pg end

    -- เก็บกวาดของเก่า (รอบก่อน / เวอร์ชันเก่า) ไม่ให้ซ้อนกัน
    for _, par in ipairs(parents) do
        for _, name in ipairs({ GUI_NAME, LEGACY_NAME }) do
            local old = par:FindFirstChild(name)
            if old and old ~= g then pcall(function() old:Destroy() end) end
        end
    end

    -- เช็คแค่ว่า "มี parent แล้ว" (เทียบ == กับ cloneref จะเป็น false เสมอ)
    for _, par in ipairs(parents) do
        local ok = pcall(function() g.Parent = par end)
        if ok and g.Parent ~= nil then return true end
    end
    return false
end

local function ensureGui()
    if alive() then return true end
    activeList = {}

    local g = mk("ScreenGui", {
        Name = GUI_NAME, ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 1000,
    })
    local c = mk("Frame", {
        Name = "List", BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -MARGIN_RIGHT, ANCHOR_Y, 0),
        Size = UDim2.new(WIDTH_SCALE, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    }, g)
    mk("UISizeConstraint", {
        MinSize = Vector2.new(220, 0), MaxSize = Vector2.new(CARD_MAX_WIDTH, 100000),
    }, c)
    mk("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 0), -- ช่องว่างอยู่ใน slot เอง เพื่อให้ยุบพร้อมกันแล้วไม่กระตุก
    }, c)

    if not attach(g) then
        pcall(function() g:Destroy() end)
        return false
    end
    gui, container = g, c
    startJanitor(g)
    return true
end

-- ── Active list / cap ─────────────────────────────────────────────────────────
local function removeRec(rec)
    for i, r in ipairs(activeList) do
        if r == rec then table.remove(activeList, i); break end
    end
end

local function enforceCap()
    local n = 0
    for _, r in ipairs(activeList) do
        if not r.closing then n = n + 1 end
    end
    for _, r in ipairs(activeList) do
        if n <= MAX_VISIBLE then break end
        if not r.closing then r.closing = true; n = n - 1 end
    end
end

-- ── กลุ่ม/เวลาเลิก/ตัวเก็บกวาด ─────────────────────────────────────────────────
local BAR_FULL = UDim2.new(1, 0, 1, 0)  -- Fill โตเต็มความกว้าง Track (สูงคงที่ = 100% ของ Track เอง)

local function liveStarted()
    local list = {}
    for _, r in ipairs(activeList) do
        if r.started and not r.leaving then list[#list + 1] = r end
    end
    return list
end

-- แถบเวลาของทุกการ์ดต้องวิ่งเต็มพอดีตอนที่การ์ดนั้นจะออก (ปรับใหม่เมื่อ deadline ถูกขยายตามกลุ่ม)
local function retimeBars()
    for _, r in ipairs(liveStarted()) do
        if r.bar and r.barDeadline ~= r.deadline then
            r.barDeadline = r.deadline
            r.hardExpire = r.deadline + HARD_GRACE
            local remaining = math.max(0.05, r.deadline - os.clock())
            play(r.bar, TweenInfo.new(remaining, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
                { Size = BAR_FULL })
        end
    end
end

-- กันค้าง: ถ้าการ์ดไหนเลยเวลาไปแล้ว (เช่น thread ของมันตายกลางทาง) สั่งปิด แล้วลบทิ้งถ้ายังไม่หาย
startJanitor = function(g)
    task.spawn(function()
        while gui == g and g.Parent ~= nil do
            task.wait(0.5)
            local t = os.clock()
            local copy = {}
            for i, r in ipairs(activeList) do copy[i] = r end
            for _, r in ipairs(copy) do
                if r.hardExpire and t > r.hardExpire then
                    r.closing = true
                    if t > r.hardExpire + 2 then
                        removeRec(r)
                        if r.slot then pcall(function() r.slot:Destroy() end) end
                    end
                end
            end
        end
    end)
end

-- ── One toast ─────────────────────────────────────────────────────────────────
local function run(mode, text, duration)
    if not ensureGui() then return end
    local theme = THEMES[mode] or THEMES.Info

    seq = seq + 1
    local rec = {
        closing = false, leaving = false, started = false,
        hardExpire = os.clock() + duration + HARD_GRACE + 3,
    }
    activeList[#activeList + 1] = rec
    enforceCap()

    local slot = mk("Frame", {
        Name = "Slot", BackgroundTransparency = 1, LayoutOrder = seq,
        Size = UDim2.new(1, 0, 0, 0),
    }, container)
    rec.slot = slot

    local body_ok, body_err = pcall(function()
        local holder = mk("Frame", {
            Name = "Holder", BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            Position = UDim2.new(0, SLIDE_OFFSET, 0, 0),
        }, slot)

        local shadow = mk("ImageLabel", {
            Name = "Shadow", BackgroundTransparency = 1,
            Image = "rbxassetid://6014261993", ImageColor3 = Color3.new(0, 0, 0),
            ImageTransparency = 1, ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(49, 49, 450, 450),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 4), Size = UDim2.new(1, 28, 1, 28),
            ZIndex = 1,
        }, holder)

        local card = mk(GROUP_OK and "CanvasGroup" or "Frame", {
            Name = "Card", BackgroundColor3 = BG_COLOR, BackgroundTransparency = BG_TRANSPARENCY,
            BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 2,
            GroupTransparency = GROUP_OK and 1 or nil,
        }, holder)
        mk("UICorner", { CornerRadius = UDim.new(0, CORNER) }, card)
        -- หมายเหตุ: UIStroke ของ CanvasGroup เองไม่ถูกเฟดโดย GroupTransparency → ต้อง tween เอง (ไม่งั้นเหลือเส้นขอบผีค้าง)
        local cardStroke = mk("UIStroke", { Color = theme.accent, Thickness = 1, Transparency = 1 }, card)

        local body = mk("Frame", {
            Name = "Body", BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        }, card)
        mk("UIPadding", {
            PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14),
            PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16),
        }, body)
        mk("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10),
        }, body)

        -- แถวหัวข้อ: ไอคอนโหมด (ไม่มีวงแหวนล้อมแล้ว) + ชื่อโหมดตัวหนาตัวใหญ่ ตามการ์ด ui ประกาศ
        local header = mk("Frame", {
            Name = "Header", BackgroundTransparency = 1, LayoutOrder = 1,
            Size = UDim2.new(1, 0, 0, ICON_BOX),
        }, body)
        mk("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10),
        }, header)

        local icon = mk("Frame", {
            Name = "Icon", BackgroundTransparency = 1, LayoutOrder = 1,
            Size = UDim2.fromOffset(ICON_BOX, ICON_BOX),
        }, header)
        drawSymbol(icon, theme.symbol, theme.icon, ICON_BOX, 0.78)

        mk("TextLabel", {
            Name = "Title", BackgroundTransparency = 1, LayoutOrder = 2,
            Size = UDim2.new(1, -(ICON_BOX + 10), 1, 0),
            Font = Enum.Font.GothamBlack, TextSize = TITLE_SIZE, TextColor3 = theme.text,
            RichText = false, TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            Text = mode:upper(),
        }, header)

        -- แถบเวลาเต็มความกว้าง (แทนแถบเล็กมุมล่างขวาของเดิม) — เดินตามเวลาที่เหลือเหมือนเดิมทุกอย่าง
        local track = mk("Frame", {
            Name = "Track", LayoutOrder = 2, BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 0.92, BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, BAR_HEIGHT),
        }, body)
        mk("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
        local bar = mk("Frame", {
            Name = "Fill", BackgroundColor3 = theme.accent, BackgroundTransparency = 0.1,
            BorderSizePixel = 0, Size = UDim2.new(0, 0, 1, 0), ZIndex = 3,
        }, track)
        mk("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)

        buildMessage(body, text, theme)

        -- วัดความสูงจริง (รอให้ layout + การตัดบรรทัดนิ่งก่อน) ระหว่างนี้การ์ดยังโปร่งใส/ความสูง slot = 0
        local H, prev = 0, -1
        for _ = 1, 14 do
            frameWait()
            if not slot.Parent then return end
            H = holder.AbsoluteSize.Y
            if H > 8 and math.abs(H - prev) < 0.5 then break end
            prev = H
        end
        if H <= 8 then H = 56 end

        -- เวลาเลิก: โหมด SYNC ทุกการ์ดที่ยังโชว์อยู่จะใช้ deadline เดียวกัน (ตัวที่หมดทีหลังสุด)
        rec.deadline = os.clock() + duration
        if SYNC_DISMISS then
            local latest = rec.deadline
            for _, r in ipairs(liveStarted()) do
                if r.deadline and r.deadline > latest then latest = r.deadline end
            end
            for _, r in ipairs(liveStarted()) do r.deadline = latest end
            rec.deadline = latest
        end
        rec.bar, rec.started = bar, true

        -- เข้า: ต่อคิวถ้ามีการ์ดใดกำลัง animate อยู่ → กันทับกัน
        while entering do task.wait(0.02) end
        entering = true
        play(slot,   T_IN_SIZE,  { Size = UDim2.new(1, 0, 0, H + GAP) })
        play(holder, T_IN_SLIDE, { Position = UDim2.new(0, 0, 0, 0) })
        if GROUP_OK then play(card, T_IN_FADE, { GroupTransparency = 0 }) end
        play(cardStroke, T_IN_FADE, { Transparency = STROKE_TRANSPARENCY })
        play(shadow, T_IN_FADE,  { ImageTransparency = SHADOW_TRANSPARENCY })
        task.wait(T_IN_SIZE.Time)  -- รอ slot ขยายเต็มก่อนปล่อยให้อันถัดไปเริ่ม
        entering = false
        retimeBars()

        -- รอ (ตัดจบได้ทันทีถูกสั่งปิด / GUI ถูกลบ)
        while not rec.closing and slot.Parent and os.clock() < rec.deadline do
            task.wait(0.05)   -- 20x/sec แทนทุก frame → ลด CPU 3× per notif
        end
        rec.leaving = true
        if not slot.Parent then return end

        -- ออก: เลื่อนไปขวา+เฟด (รวมเส้นขอบ) → แล้วค่อยยุบความสูงให้อันข้างล่างไหลขึ้น
        play(holder, T_OUT_SLIDE, { Position = UDim2.new(0, SLIDE_OFFSET, 0, 0) })
        if GROUP_OK then play(card, T_OUT_FADE, { GroupTransparency = 1 }) end
        play(cardStroke, T_OUT_FADE, { Transparency = 1 })
        play(shadow, T_OUT_FADE, { ImageTransparency = 1 })
        task.wait(OUT_SLIDE_WAIT)
        if not slot.Parent then return end

        pcall(function() slot.ClipsDescendants = true end)
        play(slot, T_OUT_SIZE, { Size = UDim2.new(1, 0, 0, 0) })
        task.wait(OUT_SIZE_WAIT)
    end)
    if not body_ok then entering = false; warn("notif error: " .. tostring(body_err)) end

    rec.leaving = true
    removeRec(rec)
    pcall(function() slot:Destroy() end)
end

-- ── Public API ────────────────────────────────────────────────────────────────
local function normalizeMode(mode)
    local m = tostring(mode == nil and "Info" or mode)
    m = m:sub(1, 1):upper() .. m:sub(2):lower()
    return THEMES[m] and m or "Info"
end

function NotificationLibrary:SendNotification(Mode, Text, Duration)
    local dur = math.clamp(tonumber(Duration) or DEFAULT_DURATION, 1, 30)
    local mode = normalizeMode(Mode)
    local text = tostring(Text == nil and "" or Text)
    task.spawn(function()
        local ok, err = pcall(run, mode, text, dur)
        if not ok then warn("notif error: " .. tostring(err)) end
    end)
end

function NotificationLibrary:Load()
    pcall(ensureGui)
end

function NotificationLibrary:Clear()
    for _, r in ipairs(activeList) do r.closing = true end
end

function NotificationLibrary:Destroy()
    for _, r in ipairs(activeList) do r.closing = true end
    if gui then pcall(function() gui:Destroy() end) end
    gui, container, activeList = nil, nil, {}
end

return NotificationLibrary
