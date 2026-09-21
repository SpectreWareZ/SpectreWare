-- SpectreWare Notification Library  (rewrite — procedural, ไม่พึ่ง rbxassetid template)
-- UI เดิมโดย IceMinister#9889 · เวอร์ชันนี้สร้างการ์ดจากโค้ดทั้งหมด
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
local ANCHOR_Y         = 0.18   -- ตำแหน่งแนวตั้งของกอง (สัดส่วนความสูงจอ)
local GAP              = 8      -- px ระหว่างการ์ด
local TEXT_SIZE        = 15
local CORNER           = 10
local SLIDE_OFFSET     = 56     -- px ที่เลื่อนเข้า/ออกจากขวา
local BG_COLOR         = Color3.fromRGB(18, 18, 24)
local BG_TRANSPARENCY  = 0.06
local SHADOW_TRANSPARENCY = 0.55

local THEMES = {
    Success = { accent = Color3.fromRGB(80, 220, 130), text = Color3.fromRGB(80, 220, 130),  icon = Color3.fromRGB(80, 220, 130),  glyph = "✓" },
    Info    = { accent = Color3.fromRGB(90, 160, 250), text = Color3.fromRGB(228, 228, 238), icon = Color3.fromRGB(210, 210, 225), glyph = "i" },
    Warning = { accent = Color3.fromRGB(250, 190, 60), text = Color3.fromRGB(250, 190, 60),  icon = Color3.fromRGB(250, 190, 60),  glyph = "!" },
    Error   = { accent = Color3.fromRGB(235, 70, 70),  text = Color3.fromRGB(235, 70, 70),   icon = Color3.fromRGB(235, 70, 70),   glyph = "×" },
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

-- ── GUI root ──────────────────────────────────────────────────────────────────
local gui, container
local activeList = {}
local seq = 0

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

-- ── One toast ─────────────────────────────────────────────────────────────────
local function run(mode, text, duration)
    if not ensureGui() then return end
    local theme = THEMES[mode] or THEMES.Info

    seq = seq + 1
    local rec = { closing = false }
    activeList[#activeList + 1] = rec
    enforceCap()

    local slot = mk("Frame", {
        Name = "Slot", BackgroundTransparency = 1, LayoutOrder = seq,
        Size = UDim2.new(1, 0, 0, 0),
    }, container)

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
        mk("UIStroke", { Color = theme.accent, Thickness = 1, Transparency = 0.45 }, card)

        local body = mk("Frame", {
            Name = "Body", BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        }, card)
        mk("UIPadding", {
            PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 14),
            PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 12),
        }, body)
        mk("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10),
        }, body)

        local icon = mk("Frame", {
            Name = "Icon", BackgroundTransparency = 1, LayoutOrder = 1,
            Size = UDim2.fromOffset(22, 22),
        }, body)
        mk("UICorner", { CornerRadius = UDim.new(1, 0) }, icon)
        mk("UIStroke", { Color = theme.icon, Thickness = 1.5, Transparency = 0.1 }, icon)
        mk("TextLabel", {
            BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
            Font = Enum.Font.GothamBold, Text = theme.glyph, TextSize = 13, TextColor3 = theme.icon,
        }, icon)

        mk("TextLabel", {
            Name = "Header", BackgroundTransparency = 1, LayoutOrder = 2,
            Size = UDim2.new(1, -32, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            Font = Enum.Font.GothamBold, TextSize = TEXT_SIZE, TextColor3 = theme.text,
            RichText = true, TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
            Text = text,
        }, body)

        mk("Frame", {
            Name = "Stripe", BackgroundColor3 = theme.accent, BorderSizePixel = 0,
            Size = UDim2.new(0, 3, 1, 0), ZIndex = 3,
        }, card)
        local bar = mk("Frame", {
            Name = "Bar", BackgroundColor3 = theme.accent, BackgroundTransparency = 0.15,
            BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, 0, 1, 0), Size = UDim2.new(0, 0, 0, 3), ZIndex = 3,
        }, card)

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

        -- เข้า: ความสูง slot ขยาย + การ์ดเลื่อนเข้า + เฟด (ไม่มี overshoot บน layout)
        play(slot,   T_IN_SIZE,  { Size = UDim2.new(1, 0, 0, H + GAP) })
        play(holder, T_IN_SLIDE, { Position = UDim2.new(0, 0, 0, 0) })
        if GROUP_OK then play(card, T_IN_FADE, { GroupTransparency = 0 }) end
        play(shadow, T_IN_FADE,  { ImageTransparency = SHADOW_TRANSPARENCY })
        play(bar, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
            { Size = UDim2.new(1, 0, 0, 3) })

        -- รอ (ตัดจบได้ทันทีถูกสั่งปิด / GUI ถูกลบ)
        local elapsed = 0
        while elapsed < duration and not rec.closing and slot.Parent do
            elapsed = elapsed + frameWait()
        end
        if not slot.Parent then return end

        -- ออก: เลื่อนไปขวา+เฟด → แล้วค่อยยุบความสูงให้อันข้างล่างไหลขึ้น
        play(holder, T_OUT_SLIDE, { Position = UDim2.new(0, SLIDE_OFFSET, 0, 0) })
        if GROUP_OK then play(card, T_OUT_FADE, { GroupTransparency = 1 }) end
        play(shadow, T_OUT_FADE, { ImageTransparency = 1 })
        task.wait(OUT_SLIDE_WAIT)
        if not slot.Parent then return end

        pcall(function() slot.ClipsDescendants = true end)
        play(slot, T_OUT_SIZE, { Size = UDim2.new(1, 0, 0, 0) })
        task.wait(OUT_SIZE_WAIT)
    end)
    if not body_ok then warn("notif error: " .. tostring(body_err)) end

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
