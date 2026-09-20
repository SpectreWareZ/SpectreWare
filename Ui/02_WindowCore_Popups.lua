-- ============ MAIN LIBRARY ============
function Library:CreateWindow(config)
    do
        local copy = {}
        if type(config) == "table" then for k, v in pairs(config) do copy[k] = v end end
        config = copy
    end
    -- alias ให้ config แบบ WindUI ใช้ได้ (Author/ToggleKey/Name/Folder)
    if config.SubTitle == nil and config.Author ~= nil then config.SubTitle = config.Author end
    if config.ToggleKeybind == nil and config.ToggleKey ~= nil then config.ToggleKeybind = config.ToggleKey end
    if config.Title == nil and config.Name ~= nil then config.Title = config.Name end
    local cfgFolder = config.ConfigFolder or config.Folder
    if type(cfgFolder) == "string" and cfgFolder ~= "" then Library.ConfigFolder = cfgFolder end
    local rawWindowTitle = config.Title
    if type(config.Title) == "string" then config.Title = Library:Translate(config.Title) end
    local Window = setmetatable({}, Library)

    local UiParent = getUiParent()
    -- เช็คจาก UiParent จริง (gethui()/protect_gui อาจไม่ใช่ CoreGui ตรงๆ) ไม่งั้นของเก่าจาก
    -- การรันสคริปต์ครั้งก่อนไม่ถูกลบ ค้างซ้อนกันทุกครั้งที่ inject ใหม่
    for _, guiName in ipairs({"ProMobileUI", "RestoreGui", "NotifyGui", "TooltipGui"}) do
        local old = UiParent:FindFirstChild(guiName)
        if old then old:Destroy() end
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ProMobileUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.IgnoreGuiInset = true   -- ใช้จอจริงเต็มจอ ไม่ใช่พื้นที่ safe-area ที่ Roblox เว้นให้ topbar (กัน clamp ลากคำนวณผิดขนาด)
    ScreenGui.Parent = UiParent

    -- ============ RESPONSIVE SCALE (มือถือ/PC) ============
    -- ย่อ/ขยาย UI ทั้งบานตามมิติสั้นสุดของจอจริง แทนที่จะ fix ขนาดเดียว
    -- แล้วล้น/เกะกะบนจอมือถือเล็ก หรือดูจิ๋วเกินไปบนจอ PC ใหญ่ๆ
    -- อัปเดตสดตอนหมุนจอ/ปรับขนาดหน้าต่าง เพื่อคง proportion เดิมเสมอ
    local ResponsiveScale = 1
    -- มือถือ (touch, ไม่มีเมาส์) รายงาน AbsoluteSize เป็นพิกเซลดิบซึ่งมักสูงกว่า REF_MAX
    -- อยู่แล้ว (จอ 1080p+) ทำให้สเกลชนเพดาน 1.0 เท่า PC ทั้งที่ขนาดจริงบนจอเล็กกว่ามาก
    -- → ต้อง boost เพิ่มเฉพาะ touch device กันไม่ให้ UI ดูจิ๋ว
    local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
    local UserScale = 1   -- ตัวคูณจากผู้ใช้ (Window:SetUIScale)
    local function computeResponsiveScale()
        local screenSize = ScreenGui.AbsoluteSize
        local minDim = math.min(screenSize.X, screenSize.Y)
        if minDim <= 0 then return ResponsiveScale end
        local REF_MIN, REF_MAX = 380, 900   -- มิติสั้นสุด: มือถือจอเล็กสุด ~380px ถึง PC ทั่วไป ~900px
        local SCALE_MIN, SCALE_MAX = 0.74, 1.0
        local t = math.clamp((minDim - REF_MIN) / (REF_MAX - REF_MIN), 0, 1)
        local scale = SCALE_MIN + (SCALE_MAX - SCALE_MIN) * t
        if IS_MOBILE then
            scale = scale * 1.35   -- boost มือถือเพิ่ม ~35% ปรับตัวเลขนี้ได้ตามชอบ
        end
        return scale * UserScale
    end
    ResponsiveScale = computeResponsiveScale()

    function Library:SetTheme(themeName)
        local newTheme = Library.Themes[themeName]
        if not newTheme then return end
        for k, v in pairs(newTheme) do Theme[k] = v end
        Library.CurrentTheme = themeName

        for _, inst in ipairs(ScreenGui:GetDescendants()) do
            local binds = inst:GetAttribute("ThemeBinds")
            if binds then
                for p in string.gmatch(binds, "[^;]+") do
                    local pr, k = string.match(p, "^(.-)=(.+)$")
                    if pr and Theme[k] then pcall(function() inst[pr] = Theme[k] end) end
                end
            else
                local key = inst:GetAttribute("ThemeKey")
                if key and Theme[key] then
                    local prop = inst:GetAttribute("ThemeProp") or "BackgroundColor3"
                    inst[prop] = Theme[key]
                end
            end
            if inst:IsA("UIGradient") and inst:GetAttribute("IsAccent") then
                inst.Color = ColorSequence.new(Theme.AccentA, Theme.AccentB)
            end
        end
    end

    -- ============ TOOLTIP SYSTEM ============
    -- ScreenGui แยกต่างหาก DisplayOrder สูงสุด กันโดน Dropdown/ColorPicker popup อื่นบังตอนเด้ง
    local TooltipGui = Instance.new("ScreenGui")
    TooltipGui.Name = "TooltipGui"
    TooltipGui.ResetOnSpawn = false
    TooltipGui.IgnoreGuiInset = true
    TooltipGui.DisplayOrder = 1000
    TooltipGui.Parent = UiParent

    local TooltipFrame = Instance.new("Frame")
    TooltipFrame.Name = "Tooltip"
    TooltipFrame.AutomaticSize = Enum.AutomaticSize.X
    TooltipFrame.Size = UDim2.new(0, 0, 0, 28)
    TooltipFrame.BackgroundTransparency = 1
    TooltipFrame.Visible = false
    TooltipFrame.ZIndex = 10000
    applyThemeColor(TooltipFrame, "Topbar")
    corner(TooltipFrame, 6)
    local TooltipStroke = stroke(TooltipFrame, "Stroke", 1)
    TooltipStroke.Transparency = 1
    TooltipFrame.Parent = TooltipGui

    local TooltipPad = Instance.new("UIPadding")
    TooltipPad.PaddingLeft = UDim.new(0, 9)
    TooltipPad.PaddingRight = UDim.new(0, 9)
    TooltipPad.PaddingTop = UDim.new(0, 6)
    TooltipPad.PaddingBottom = UDim.new(0, 6)
    TooltipPad.Parent = TooltipFrame

    local TooltipLabel = Instance.new("TextLabel")
    TooltipLabel.BackgroundTransparency = 1
    TooltipLabel.AutomaticSize = Enum.AutomaticSize.X
    TooltipLabel.Size = UDim2.new(0, 0, 1, 0)
    TooltipLabel.FontFace = UI_Font("Medium")
    TooltipLabel.TextSize = 12
    TooltipLabel.TextTransparency = 1
    TooltipLabel.ZIndex = 10001
    applyThemeColor(TooltipLabel, "Text", "TextColor3")
    TooltipLabel.Parent = TooltipFrame

    local tooltipToken, tooltipVisible = 0, false

    -- กันเด้งทะลุขอบจอ: สลับฝั่งเป็นซ้าย/บนของเมาส์ถ้าเด้งฝั่งขวา/ล่างแล้วล้นจอ
    local function positionTooltip(mousePos)
        if not mousePos then return end
        local screenSize = ScreenGui.AbsoluteSize
        local ttSize = TooltipFrame.AbsoluteSize
        local x, y = mousePos.X + 16, mousePos.Y + 20
        if x + ttSize.X > screenSize.X - 6 then x = mousePos.X - ttSize.X - 14 end
        if y + ttSize.Y > screenSize.Y - 6 then y = mousePos.Y - ttSize.Y - 10 end
        TooltipFrame.Position = UDim2.new(0, math.max(6, x), 0, math.max(6, y))
    end

    local function hideTooltip()
        tooltipToken += 1
        if not tooltipVisible then return end
        tooltipVisible = false
        local myToken = tooltipToken
        TweenService:Create(TooltipFrame, TI.d014_Sine_Out, {BackgroundTransparency = 1}):Play()
        TweenService:Create(TooltipStroke, TI.d014_Sine_Out, {Transparency = 1}):Play()
        local tw = TweenService:Create(TooltipLabel, TI.d014_Sine_Out, {TextTransparency = 1})
        tw:Play()
        tw.Completed:Connect(function()
            if tooltipToken == myToken then TooltipFrame.Visible = false end
        end)
    end

    -- แสดง tooltip ตรงๆ ที่ตำแหน่งเมาส์ (เรียกเองได้จาก custom element นอกเหนือจาก AttachTooltip)
    function Library:ShowTooltip(text, mousePos)
        if not text or text == "" then return end
        tooltipToken += 1
        local myToken = tooltipToken
        TooltipLabel.Text = text
        TooltipFrame.Visible = true
        mousePos = mousePos or UserInputService:GetMouseLocation()
        positionTooltip(mousePos)
        task.defer(function()
            if tooltipToken == myToken then positionTooltip(mousePos) end
        end)
        tooltipVisible = true
        TweenService:Create(TooltipFrame, TI.d014_Sine_Out, {BackgroundTransparency = 0.05}):Play()
        TweenService:Create(TooltipStroke, TI.d014_Sine_Out, {Transparency = 0.5}):Play()
        TweenService:Create(TooltipLabel, TI.d014_Sine_Out, {TextTransparency = 0}):Play()
    end

    function Library:HideTooltip()
        hideTooltip()
    end

    local TOOLTIP_HOVER_DELAY = 0.45
    -- ผูก tooltip เข้ากับ GuiObject ไหนก็ได้ — ใช้ได้ทั้งกับ element ของ Library เองและ custom GuiObject
    -- text รับเป็น string ตรงๆ หรือ function() return string end (เผื่ออยาก dynamic ตาม flag/state ปัจจุบัน)
    function Library:AttachTooltip(inst, text, opts)
        if not text then return end
        opts = type(opts) == "table" and opts or {}
        local hoverToken, moveConn = 0, nil
        inst.MouseEnter:Connect(function()
            hoverToken += 1
            local myHover = hoverToken
            -- กัน connection ค้าง: ถ้า MouseEnter ยิงซ้ำโดยไม่มี MouseLeave คั่น (เกิดได้บ่อยกับ
            -- element ที่ reflow เช่น AutomaticSize/UIListLayout/ScrollingFrame) ต้อง disconnect
            -- moveConn ตัวเก่าก่อนสร้างใหม่ ไม่งั้น MouseMoved connection จะสะสมค้างไปเรื่อยๆ
            if moveConn then moveConn:Disconnect(); moveConn = nil end
            task.delay(opts.Delay or TOOLTIP_HOVER_DELAY, function()
                if hoverToken ~= myHover then return end
                local resolved = text
                if type(text) == "function" then
                    local ok, result = pcall(text)
                    resolved = ok and result or nil
                end
                Library:ShowTooltip(resolved, UserInputService:GetMouseLocation())
            end)
            moveConn = inst.MouseMoved:Connect(function(x, y)
                if tooltipVisible then positionTooltip(Vector2.new(x, y)) end
            end)
        end)
        inst.MouseLeave:Connect(function()
            hoverToken += 1
            if moveConn then moveConn:Disconnect(); moveConn = nil end
            hideTooltip()
        end)
        inst.Destroying:Connect(function()
            -- ถ้า instance ถูก Destroy ระหว่างกำลัง hover (รอ delay หรือ tooltip โชว์อยู่แล้ว)
            -- MouseLeave จะไม่มีทางยิงอีก ต้องตัด hoverToken ค้าง + สั่งซ่อนเองตรงนี้
            -- ไม่งั้น tooltip จะค้างโชว์บนจอตลอดไปหลัง element หายไป (เช่น ปิด tab/สลับหน้า)
            hoverToken += 1
            if moveConn then moveConn:Disconnect(); moveConn = nil end
            hideTooltip()
        end)
    end

    -- ============ Notification layer ============
    local NotifyGui = Instance.new("ScreenGui")
    NotifyGui.Name = "NotifyGui"
    NotifyGui.ResetOnSpawn = false
    NotifyGui.IgnoreGuiInset = true
    NotifyGui.DisplayOrder = 998
    NotifyGui.Parent = UiParent

    local NotifyHolder = Instance.new("Frame")
    NotifyHolder.Name = "Notifications"
    NotifyHolder.AnchorPoint = Vector2.new(1, 0)
    NotifyHolder.Position = UDim2.new(1, -16, 0, 16)
    NotifyHolder.Size = UDim2.new(0, 312, 1, -32)
    NotifyHolder.BackgroundTransparency = 1
    NotifyHolder.Parent = NotifyGui
    local NotifyLayout = Instance.new("UIListLayout")
    NotifyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    NotifyLayout.Padding = UDim.new(0, 10)
    NotifyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    NotifyLayout.Parent = NotifyHolder

    -- ============ Notification queue (จำกัดจำนวนที่โชว์พร้อมกัน กันสแปม/ยิงรัว) ============
    local MAX_VISIBLE_NOTIFICATIONS = 4
    local activeNotifyCount = 0
    local notifyQueue = {} -- FIFO: เก็บ opts ที่รอคิวอยู่

    local spawnToast -- ประกาศล่วงหน้า เพราะ spawnToast เรียกตัวเองผ่าน queue ตอน dismiss เสร็จ

    local function tryDequeueNotify()
        if activeNotifyCount >= MAX_VISIBLE_NOTIFICATIONS then return end
        local nextOpts = table.remove(notifyQueue, 1)
        if nextOpts then
            spawnToast(nextOpts)
        end
    end

    -- opts: Title, Content, Type(info/success/warning/error), Duration, Persistent, Icon, Color,
    --       Buttons = {{Title=, Callback=, Variant="Primary"/"Secondary"/"Danger", KeepOpen=}}
    -- คืน handle: :Close() :SetTitle(t) :SetContent(t)
    function Library:Notify(opts)
        if type(opts) == "string" then opts = {Content = opts} end
        opts = type(opts) == "table" and opts or {}
        local o = {}
        for k, v in pairs(opts) do o[k] = v end
        local handle = {}
        function handle:Close()
            handle._closeRequested = true
            if handle._dismiss then handle._dismiss() end
        end
        function handle:SetTitle(t) if handle._title then handle._title.Text = tostring(t) end end
        function handle:SetContent(t) if handle._content then handle._content.Text = tostring(t) end end
        o._handle = handle
        if activeNotifyCount >= MAX_VISIBLE_NOTIFICATIONS then
            table.insert(notifyQueue, o)
            return handle
        end
        task.spawn(spawnToast, o)
        return handle
    end

    spawnToast = function(opts)
        activeNotifyCount += 1
        local title = Library:Translate(opts.Title or "Notice")
        local content = Library:Translate(opts.Content or "")
        local duration = math.max(opts.Duration or 3, 0.5)
        if opts.Persistent == true or opts.Duration == math.huge then duration = math.huge end
        local ntype = opts.Type or "info"
        local COLOR_KEY = {success = "Success", error = "Danger", warning = "Warning", info = "Info"}
        local color = Theme[COLOR_KEY[ntype] or "Info"]
        if typeof(opts.Color) == "Color3" then color = opts.Color end

        -- ===== SHADOW =====
        local Shadow = Instance.new("ImageLabel")
        Shadow.Name = "ToastShadow"
        Shadow.BackgroundTransparency = 1
        Shadow.Image = "rbxassetid://5028857084"
        Shadow.ImageColor3 = Color3.new(0, 0, 0)
        Shadow.ImageTransparency = 1
        Shadow.ScaleType = Enum.ScaleType.Slice
        Shadow.SliceCenter = Rect.new(24, 24, 276, 276)
        Shadow.ZIndex = 0
        Shadow.Parent = NotifyGui

        local Slot = Instance.new("Frame")
        Slot.Name = "ToastSlot"
        Slot.BackgroundTransparency = 1
        Slot.Size = UDim2.new(1, 0, 0, 0)
        Slot.ClipsDescendants = true
        Slot.ZIndex = 2
        Slot.Parent = NotifyHolder

        -- ===== CARD =====
        local Toast = Instance.new("Frame")
        applyThemeColor(Toast, "Element")
        Toast.BackgroundTransparency = 0.08
        Toast.Size = UDim2.new(1, 0, 0, 0)
        Toast.AutomaticSize = Enum.AutomaticSize.Y
        Toast.ClipsDescendants = false
        Toast.ZIndex = 2
        Toast.Position = UDim2.new(0, 24, 0, 0)
        Toast.Parent = Slot
        corner(Toast, 14)

        -- subtle stroke border
        local outline = Instance.new("UIStroke")
        outline.Color = color
        outline.Transparency = 1
        outline.Thickness = 1
        outline.Parent = Toast

        -- top-edge colored highlight (thin 2px line inside card top)
        local TopEdge = Instance.new("Frame")
        TopEdge.Name = "TopEdge"
        TopEdge.Size = UDim2.new(1, -28, 0, 2)
        TopEdge.Position = UDim2.new(0, 14, 0, 0)
        TopEdge.BackgroundColor3 = color
        TopEdge.BackgroundTransparency = 1
        TopEdge.BorderSizePixel = 0
        TopEdge.ZIndex = 6
        TopEdge.Parent = Toast
        corner(TopEdge, 1)
        local topEdgeGrad = Instance.new("UIGradient")
        topEdgeGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, color),
            ColorSequenceKeypoint.new(0.5, color:Lerp(Color3.new(1,1,1), 0.25)),
            ColorSequenceKeypoint.new(1, color),
        })
        topEdgeGrad.Parent = TopEdge

        -- very subtle color wash (barely visible tint)
        local ColorTint = Instance.new("Frame")
        ColorTint.Name = "ColorTint"
        ColorTint.Size = UDim2.new(1, 0, 1, 0)
        ColorTint.BackgroundColor3 = color
        ColorTint.BorderSizePixel = 0
        ColorTint.ZIndex = 2
        ColorTint.BackgroundTransparency = 1
        ColorTint.Parent = Toast
        corner(ColorTint, 14)
        local tintGradient = Instance.new("UIGradient")
        tintGradient.Color = ColorSequence.new(color, color:Lerp(Theme.Element, 1))
        tintGradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.93),
            NumberSequenceKeypoint.new(0.5, 0.98),
            NumberSequenceKeypoint.new(1, 1),
        })
        tintGradient.Rotation = 135
        tintGradient.Parent = ColorTint

        local function syncShadow()
            if not Shadow.Parent or not Toast.Parent then return end
            Shadow.Position = UDim2.new(0, Toast.AbsolutePosition.X - 14, 0, Toast.AbsolutePosition.Y - 10)
            Shadow.Size = UDim2.new(0, Toast.AbsoluteSize.X + 28, 0, Toast.AbsoluteSize.Y + 22)
        end
        local shadowConns = {
            Toast:GetPropertyChangedSignal("AbsoluteSize"):Connect(syncShadow),
            Toast:GetPropertyChangedSignal("AbsolutePosition"):Connect(syncShadow),
        }
        syncShadow()

        -- ===== LEFT ACCENT STRIP (3px, rounded) =====
        local AccentBar = Instance.new("Frame")
        AccentBar.Name = "AccentBar"
        AccentBar.AnchorPoint = Vector2.new(0, 0)
        AccentBar.Position = UDim2.new(0, 0, 0, 8)
        AccentBar.Size = UDim2.new(0, 3, 1, -16)
        AccentBar.BackgroundColor3 = color
        AccentBar.BackgroundTransparency = 1
        AccentBar.BorderSizePixel = 0
        AccentBar.ZIndex = 5
        AccentBar.Parent = Toast
        corner(AccentBar, 2)
        local accentFade = Instance.new("UIGradient")
        accentFade.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 0.45),
        })
        accentFade.Rotation = 90
        accentFade.Parent = AccentBar

        -- ===== ICON BADGE (compact 28x28) =====
        local IconBadge = Instance.new("Frame")
        IconBadge.Size = UDim2.new(0, 28, 0, 28)
        IconBadge.Position = UDim2.new(0, 14, 0, 14)
        IconBadge.BackgroundColor3 = color:Lerp(Theme.Element, 0.78)
        IconBadge.BackgroundTransparency = 1
        IconBadge.ZIndex = 4
        IconBadge.Parent = Toast
        corner(IconBadge, 8)
        local badgeStroke = Instance.new("UIStroke")
        badgeStroke.Color = color
        badgeStroke.Transparency = 0.6
        badgeStroke.Thickness = 1
        badgeStroke.Parent = IconBadge

        local IconImg = Instance.new("ImageLabel")
        IconImg.AnchorPoint = Vector2.new(0.5, 0.5)
        IconImg.Position = UDim2.new(0.5, 0, 0.5, 0)
        IconImg.Size = UDim2.new(0, 14, 0, 14)
        IconImg.BackgroundTransparency = 1
        do
            local custom
            if opts.Icon ~= nil then
                custom = Library.Icons[opts.Icon]
                if not custom then
                    local asText = tostring(opts.Icon)
                    if typeof(opts.Icon) == "number" or string.match(asText, "^rbx") or string.match(asText, "^%d+$") then
                        custom = normalizeAssetId(opts.Icon)
                    end
                end
            end
            IconImg.Image = custom or NOTIFY_ICON[ntype] or Library.Icons.info
        end
        IconImg.ImageColor3 = color
        IconImg.ImageTransparency = 1
        IconImg.ScaleType = Enum.ScaleType.Fit
        IconImg.ZIndex = 5
        IconImg.Parent = IconBadge

        -- ===== TYPE CHIP (small uppercase label, colored) =====
        local TypeChip = Instance.new("TextLabel")
        TypeChip.BackgroundTransparency = 1
        TypeChip.Position = UDim2.new(0, 54, 0, 14)
        TypeChip.Size = UDim2.new(1, -92, 0, 11)
        TypeChip.FontFace = UI_Font("Bold")
        TypeChip.TextSize = 10.5
        TypeChip.TextColor3 = color
        TypeChip.TextTransparency = 1
        TypeChip.TextXAlignment = Enum.TextXAlignment.Left
        TypeChip.Text = string.upper(ntype)
        TypeChip.ZIndex = 4
        TypeChip.Parent = Toast

        -- ===== TITLE =====
        local TitleLbl = Instance.new("TextLabel")
        TitleLbl.BackgroundTransparency = 1
        TitleLbl.Position = UDim2.new(0, 54, 0, 26)
        TitleLbl.Size = UDim2.new(1, -92, 0, 16)
        TitleLbl.FontFace = UI_Font("Bold")
        TitleLbl.TextSize = 13.5
        applyThemeColor(TitleLbl, "Text", "TextColor3")
        TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
        TitleLbl.TextTransparency = 1
        TitleLbl.Text = title
        TitleLbl.ZIndex = 4
        TitleLbl.Parent = Toast

        -- ===== CONTENT =====
        local ContentLbl = Instance.new("TextLabel")
        ContentLbl.BackgroundTransparency = 1
        ContentLbl.Position = UDim2.new(0, 54, 0, 44)
        ContentLbl.Size = UDim2.new(1, -66, 0, 0)
        ContentLbl.AutomaticSize = Enum.AutomaticSize.Y
        ContentLbl.FontFace = UI_Font("Medium")
        ContentLbl.TextSize = 12
        ContentLbl.LineHeight = 1.35
        applyThemeColor(ContentLbl, "SubText", "TextColor3")
        ContentLbl.TextXAlignment = Enum.TextXAlignment.Left
        ContentLbl.TextWrapped = true
        ContentLbl.TextTransparency = 1
        ContentLbl.Text = content
        ContentLbl.ZIndex = 4
        ContentLbl.Parent = Toast

        -- ===== BOTTOM SPACER (for progress bar gap) =====
        local BottomSpacer = Instance.new("Frame")
        BottomSpacer.BackgroundTransparency = 1
        BottomSpacer.Position = UDim2.new(0, 54, 0, 44)
        BottomSpacer.Size = UDim2.new(1, 0, 0, 22)
        BottomSpacer.ZIndex = 2
        BottomSpacer.Parent = Toast

        -- ===== ACTION BUTTONS (opts.Buttons) =====
        local actionButtons = type(opts.Buttons) == "table" and opts.Buttons or nil
        local hasActions = actionButtons ~= nil and #actionButtons > 0
        local ActionsRow
        if hasActions then
            ActionsRow = Instance.new("CanvasGroup")
            ActionsRow.Name = "Actions"
            ActionsRow.BackgroundTransparency = 1
            ActionsRow.GroupTransparency = 1
            ActionsRow.Position = UDim2.new(0, 54, 0, 60)
            ActionsRow.Size = UDim2.new(1, -66, 0, 28)
            ActionsRow.ZIndex = 6
            ActionsRow.Parent = Toast
            local rowLayout = Instance.new("UIListLayout")
            rowLayout.FillDirection = Enum.FillDirection.Horizontal
            rowLayout.Padding = UDim.new(0, 6)
            rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
            rowLayout.Parent = ActionsRow
        end

        -- ===== PROGRESS BAR (2px full-width bottom edge) =====
        local ProgressTrack = Instance.new("Frame")
        ProgressTrack.AnchorPoint = Vector2.new(0, 1)
        ProgressTrack.Position = UDim2.new(0, 0, 1, 0)
        ProgressTrack.Size = UDim2.new(1, 0, 0, 2)
        ProgressTrack.BackgroundColor3 = Theme.Stroke
        ProgressTrack.BackgroundTransparency = 1
        ProgressTrack.BorderSizePixel = 0
        ProgressTrack.ZIndex = 6
        ProgressTrack.ClipsDescendants = true
        ProgressTrack.Parent = Toast
        corner(ProgressTrack, 1)

        local ProgressBar = Instance.new("Frame")
        ProgressBar.Size = UDim2.new(1, 0, 1, 0)
        ProgressBar.BackgroundColor3 = color
        ProgressBar.BorderSizePixel = 0
        ProgressBar.ZIndex = 7
        ProgressBar.Parent = ProgressTrack
        corner(ProgressBar, 1)
        local progressGradient = Instance.new("UIGradient")
        progressGradient.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.3), color)
        progressGradient.Parent = ProgressBar

        -- ===== CLOSE BUTTON =====
        local CloseX = Instance.new("ImageButton")
        CloseX.AnchorPoint = Vector2.new(1, 0)
        CloseX.Position = UDim2.new(1, -8, 0, 8)
        CloseX.Size = UDim2.new(0, 20, 0, 20)
        CloseX.BackgroundColor3 = Theme.SubText
        CloseX.BackgroundTransparency = 1
        CloseX.AutoButtonColor = false
        CloseX.ZIndex = 6
        CloseX.Parent = Toast
        corner(CloseX, 6)

        local CloseXIcon = Instance.new("ImageLabel")
        CloseXIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        CloseXIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
        CloseXIcon.Size = UDim2.new(0, 10, 0, 10)
        CloseXIcon.BackgroundTransparency = 1
        CloseXIcon.Image = Library.Icons.close
        applyThemeColor(CloseXIcon, "SubText", "ImageColor3")
        CloseXIcon.ImageTransparency = 1
        CloseXIcon.ScaleType = Enum.ScaleType.Fit
        CloseXIcon.ZIndex = 7
        CloseXIcon.Parent = CloseX

        CloseX.MouseEnter:Connect(function()
            TweenService:Create(CloseX, TI.d012_Sine_Out, {BackgroundTransparency = 0.82}):Play()
            TweenService:Create(CloseXIcon, TI.d012_Sine_Out, {ImageColor3 = Theme.Text}):Play()
        end)
        CloseX.MouseLeave:Connect(function()
            TweenService:Create(CloseX, TI.d012_Sine_Out, {BackgroundTransparency = 1}):Play()
            TweenService:Create(CloseXIcon, TI.d012_Sine_Out, {ImageColor3 = Theme.SubText}):Play()
        end)

        -- ===== UIScale for bounce animation =====
        local ToastScale = Instance.new("UIScale")
        ToastScale.Scale = 0.88
        ToastScale.Parent = Toast

        -- รอ AutomaticSize นิ่ง 1 เฟรม
        RunService.Heartbeat:Wait()
        if hasActions then
            local ch = (ContentLbl.Text ~= "") and ContentLbl.TextBounds.Y or 0
            ActionsRow.Position = UDim2.new(0, 54, 0, 44 + ch + 8)
            BottomSpacer.Size = UDim2.new(1, 0, 0, ch + 8 + 28 + 12)
            RunService.Heartbeat:Wait()
        end

        local targetHeight = Toast.AbsoluteSize.Y
        Slot.Size = UDim2.new(1, 0, 0, 0)
        TweenService:Create(Slot, TI.d024_Quint_Out, {Size = UDim2.new(1, 0, 0, targetHeight)}):Play()

        local heightSyncConn = Toast:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            local h = Toast.AbsoluteSize.Y
            TweenService:Create(Slot, TI.d012_Sine_Out, {Size = UDim2.new(1, 0, 0, h)}):Play()
        end)

        -- ===== ENTER ANIMATION =====
        TweenService:Create(Toast, TI.d024_Quint_Out, {Position = UDim2.new(0, 0, 0, 0)}):Play()
        TweenService:Create(ToastScale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
        TweenService:Create(outline, TI.d022_Sine_Out, {Transparency = 0.55}):Play()
        TweenService:Create(ColorTint, TI.d022_Sine_Out, {BackgroundTransparency = 0}):Play()
        TweenService:Create(Shadow, TI.d03_Sine_Out, {ImageTransparency = 0.6}):Play()
        TweenService:Create(TopEdge, TI.d022_Sine_Out, {BackgroundTransparency = 0}):Play()
        TweenService:Create(AccentBar, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, 0.04), {BackgroundTransparency = 0}):Play()
        TweenService:Create(IconBadge, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0.06), {BackgroundTransparency = 0}):Play()
        TweenService:Create(IconImg, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0.12), {ImageTransparency = 0}):Play()
        TweenService:Create(TypeChip, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0.08), {TextTransparency = 0}):Play()
        TweenService:Create(TitleLbl, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0.1), {TextTransparency = 0}):Play()
        TweenService:Create(ContentLbl, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0.15), {TextTransparency = 0}):Play()
        TweenService:Create(CloseXIcon, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0.18), {ImageTransparency = 0.4}):Play()
        ProgressBar.BackgroundTransparency = 1
        TweenService:Create(ProgressBar, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0.2), {BackgroundTransparency = 0}):Play()
        TweenService:Create(ProgressTrack, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0.15), {BackgroundTransparency = 0.7}):Play()

        local dismissed = false
        local function dismiss()
            if dismissed or not Toast or not Toast.Parent then return end
            dismissed = true
            if heightSyncConn then heightSyncConn:Disconnect(); heightSyncConn = nil end

            -- EXIT ANIMATION
            TweenService:Create(Toast, TI.d018_Quint_In, {Position = UDim2.new(0, 24, 0, 0)}):Play()
            TweenService:Create(ToastScale, TI.d018_Quint_In, {Scale = 0.93}):Play()
            TweenService:Create(outline, TI.d018_Sine_Out, {Transparency = 1}):Play()
            TweenService:Create(ColorTint, TI.d018_Sine_Out, {BackgroundTransparency = 1}):Play()
            TweenService:Create(TopEdge, TI.d018_Sine_Out, {BackgroundTransparency = 1}):Play()
            TweenService:Create(AccentBar, TI.d016_Sine_In, {BackgroundTransparency = 1}):Play()
            TweenService:Create(Shadow, TI.d018_Sine_Out, {ImageTransparency = 1}):Play()
            TweenService:Create(IconBadge, TI.d016_Sine_In, {BackgroundTransparency = 1}):Play()
            TweenService:Create(IconImg, TI.d014_Sine_Out, {ImageTransparency = 1}):Play()
            TweenService:Create(TypeChip, TI.d014_Sine_Out, {TextTransparency = 1}):Play()
            TweenService:Create(TitleLbl, TI.d014_Sine_Out, {TextTransparency = 1}):Play()
            TweenService:Create(ContentLbl, TI.d014_Sine_Out, {TextTransparency = 1}):Play()
            TweenService:Create(CloseXIcon, TI.d014_Sine_Out, {ImageTransparency = 1}):Play()
            TweenService:Create(ProgressTrack, TI.d014_Sine_Out, {BackgroundTransparency = 1}):Play()
            TweenService:Create(ProgressBar, TI.d014_Sine_Out, {BackgroundTransparency = 1}):Play()
            if ActionsRow then TweenService:Create(ActionsRow, TI.d014_Sine_Out, {GroupTransparency = 1}):Play() end
            TweenService:Create(Slot, TI.d018_Quint_In, {Size = UDim2.new(1, 0, 0, 0)}):Play()
            task.delay(0.22, function()
                for _, c in ipairs(shadowConns) do c:Disconnect() end
                Shadow:Destroy()
                if Slot then Slot:Destroy() end
                activeNotifyCount -= 1
                tryDequeueNotify()
            end)
        end

        -- handle + ปุ่มใน toast
        if opts._handle then
            opts._handle._dismiss = dismiss
            opts._handle._title = TitleLbl
            opts._handle._content = ContentLbl
            if opts._handle._closeRequested then dismiss() end
        end
        if hasActions then
            for idx, b in ipairs(actionButtons) do
                local variant = b.Variant or (idx == 1 and "Primary" or "Secondary")
                local Btn = Instance.new("TextButton")
                Btn.AutomaticSize = Enum.AutomaticSize.X
                Btn.Size = UDim2.new(0, 0, 1, 0)
                Btn.LayoutOrder = idx
                Btn.AutoButtonColor = false
                Btn.Text = tostring(Library:Translate(b.Title or b.Text or "OK"))
                Btn.FontFace = UI_Font("SemiBold")
                Btn.TextSize = 12
                Btn.ZIndex = 7
                if variant == "Primary" then
                    Btn.BackgroundColor3 = color
                    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                elseif variant == "Danger" then
                    applyThemeColor(Btn, "Danger")
                    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                else
                    applyThemeColor(Btn, "ElementHover")
                    applyThemeColor(Btn, "Text", "TextColor3")
                end
                local bp = Instance.new("UIPadding")
                bp.PaddingLeft = UDim.new(0, 12)
                bp.PaddingRight = UDim.new(0, 12)
                bp.Parent = Btn
                Btn.Parent = ActionsRow
                corner(Btn, 7)
                applyPressAnimation(Btn, 0.94)
                Btn.MouseButton1Click:Connect(function()
                    if b.Callback then safeCallback(b.Callback) end
                    if b.KeepOpen ~= true then dismiss() end
                end)
            end
            TweenService:Create(ActionsRow, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0.18), {GroupTransparency = 0}):Play()
        end

        -- HOVER: หยุดนับถอยหลัง + lift card
        local elapsed = 0
        local isHovering = false
        task.spawn(function()
            while Toast and Toast.Parent and not dismissed do
                local dt = task.wait()
                if not isHovering and not dismissed then
                    elapsed += dt
                    local ratio = math.clamp(1 - (elapsed / duration), 0, 1)
                    ProgressBar.Size = UDim2.new(ratio, 0, 1, 0)
                    if elapsed >= duration then
                        dismiss()
                        break
                    end
                end
            end
        end)

        Toast.MouseEnter:Connect(function()
            isHovering = true
            TweenService:Create(Shadow, TI.d02_Sine_Out, {ImageTransparency = 0.4}):Play()
            TweenService:Create(ToastScale, TI.d02_Sine_Out, {Scale = 1.012}):Play()
        end)
        Toast.MouseLeave:Connect(function()
            isHovering = false
            TweenService:Create(Shadow, TI.d02_Sine_Out, {ImageTransparency = 0.6}):Play()
            TweenService:Create(ToastScale, TI.d02_Sine_Out, {Scale = 1}):Play()
        end)

        CloseX.MouseButton1Click:Connect(dismiss)
    end

    -- ============ Library:Confirm — โมดัลยืนยัน (Yes/No) พร้อม backdrop เบลอ/มืดลง ============
    function Library:Confirm(opts)
        opts = type(opts) == "table" and opts or {}
        local ConfirmGui = Instance.new("ScreenGui")
        ConfirmGui.Name = "ConfirmGui"
        ConfirmGui.ResetOnSpawn = false
        ConfirmGui.IgnoreGuiInset = true
        ConfirmGui.DisplayOrder = 999
        ConfirmGui.Parent = UiParent

        local Backdrop = Instance.new("Frame")
        Backdrop.Size = UDim2.new(1, 0, 1, 0)
        Backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Backdrop.BackgroundTransparency = 1
        Backdrop.Active = true
        Backdrop.ZIndex = 1
        Backdrop.Parent = ConfirmGui

        local Dialog = Instance.new("Frame")
        Dialog.AnchorPoint = Vector2.new(0.5, 0.5)
        Dialog.Position = UDim2.new(0.5, 0, 0.5, 0)
        Dialog.Size = UDim2.new(0, 320, 0, 168)
        applyThemeColor(Dialog, "Background")
        Dialog.BackgroundTransparency = 1
        Dialog.Active = true
        Dialog.ZIndex = 2
        Dialog.Parent = ConfirmGui
        corner(Dialog, 14)
        local dStroke = stroke(Dialog, "Stroke", 1)
        dStroke.Transparency = 1
        local dScale = Instance.new("UIScale")
        dScale.Scale = 0.8
        dScale.Parent = Dialog

        local TitleLbl = Instance.new("TextLabel")
        TitleLbl.Size = UDim2.new(1, -32, 0, 24)
        TitleLbl.Position = UDim2.new(0, 16, 0, 16)
        TitleLbl.BackgroundTransparency = 1
        TitleLbl.Text = opts.Title or "ยืนยันการทำงาน"
        applyThemeColor(TitleLbl, "Text", "TextColor3")
        TitleLbl.FontFace = UI_Font("Bold")
        TitleLbl.TextSize = 16
        TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
        TitleLbl.TextTransparency = 1
        TitleLbl.ZIndex = 2
        TitleLbl.Parent = Dialog

        local ContentLbl = Instance.new("TextLabel")
        ContentLbl.Size = UDim2.new(1, -32, 0, 62)
        ContentLbl.Position = UDim2.new(0, 16, 0, 44)
        ContentLbl.BackgroundTransparency = 1
        ContentLbl.Text = opts.Content or ""
        applyThemeColor(ContentLbl, "SubText", "TextColor3")
        ContentLbl.FontFace = UI_Font("Medium")
        ContentLbl.TextSize = 13.5
        ContentLbl.LineHeight = 1.3
        ContentLbl.TextWrapped = true
        ContentLbl.TextXAlignment = Enum.TextXAlignment.Left
        ContentLbl.TextYAlignment = Enum.TextYAlignment.Top
        ContentLbl.TextTransparency = 1
        ContentLbl.ZIndex = 2
        ContentLbl.Parent = Dialog

        local BtnRow = Instance.new("Frame")
        BtnRow.Size = UDim2.new(1, -32, 0, 36)
        BtnRow.Position = UDim2.new(0, 16, 1, -52)
        BtnRow.BackgroundTransparency = 1
        BtnRow.ZIndex = 2
        BtnRow.Parent = Dialog
        local RowLayout = Instance.new("UIListLayout")
        RowLayout.SortOrder = Enum.SortOrder.LayoutOrder
        RowLayout.FillDirection = Enum.FillDirection.Horizontal
        RowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        RowLayout.Padding = UDim.new(0, 8)
        RowLayout.Parent = BtnRow

        local CancelBtn
        if not opts.HideCancel then
            CancelBtn = Instance.new("TextButton")
            CancelBtn.Size = UDim2.new(0, 92, 1, 0)
            applyThemeColor(CancelBtn, "Element")
            CancelBtn.AutoButtonColor = false
            CancelBtn.Text = opts.CancelText or "ยกเลิก"
            applyThemeColor(CancelBtn, "SubText", "TextColor3")
            CancelBtn.FontFace = UI_Font("SemiBold")
            CancelBtn.TextSize = 13
            CancelBtn.ZIndex = 2
            CancelBtn.Parent = BtnRow
            corner(CancelBtn, 8)
            applyHoverEffect(CancelBtn, "Element", "ElementHover")
            applyPressAnimation(CancelBtn, 0.94)
            ripple(CancelBtn, "Stroke")
        end

        local ConfirmBtn = Instance.new("TextButton")
        ConfirmBtn.Size = UDim2.new(0, 92, 1, 0)
        applyThemeColor(ConfirmBtn, opts.Danger and "Danger" or "AccentA")
        ConfirmBtn.AutoButtonColor = false
        ConfirmBtn.Text = opts.ConfirmText or "ยืนยัน"
        ConfirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        ConfirmBtn.FontFace = UI_Font("Bold")
        ConfirmBtn.TextSize = 13
        ConfirmBtn.ZIndex = 2
        ConfirmBtn.Parent = BtnRow
        corner(ConfirmBtn, 8)
        applyPressAnimation(ConfirmBtn, 0.94)

        local closed = false
        local function close(result)
            if closed then return end
            closed = true
            TweenService:Create(Backdrop, TI.d018_Sine_Out, {BackgroundTransparency = 1}):Play()
            TweenService:Create(dScale, TI.d018_Quint_In, {Scale = 0.85}):Play()
            TweenService:Create(Dialog, TI.d018_Quint_In, {BackgroundTransparency = 1}):Play()
            TweenService:Create(dStroke, TI.d018_Quint_In, {Transparency = 1}):Play()
            TweenService:Create(TitleLbl, TI.d014_Sine_Out, {TextTransparency = 1}):Play()
            TweenService:Create(ContentLbl, TI.d014_Sine_Out, {TextTransparency = 1}):Play()
            task.delay(0.2, function() if ConfirmGui then ConfirmGui:Destroy() end end)
            if result then
                if opts.OnConfirm then safeCallback(opts.OnConfirm) end
            else
                if opts.OnCancel then safeCallback(opts.OnCancel) end
            end
        end

        Backdrop.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                close(false)
            end
        end)
        if CancelBtn then
            CancelBtn.MouseButton1Click:Connect(function() close(false) end)
        end
        ConfirmBtn.MouseButton1Click:Connect(function() close(true) end)

        -- ลำดับแอนิเมชันเข้า: backdrop มืดลง + กล่องเด้งเข้าแบบสปริง
        TweenService:Create(Backdrop, TI.d022_Sine_Out, {BackgroundTransparency = 0.45}):Play()
        TweenService:Create(dScale, TI.d045_Back_Out, {Scale = 1}):Play()
        TweenService:Create(Dialog, TI.d024_Quint_Out, {BackgroundTransparency = 0}):Play()
        TweenService:Create(dStroke, TI.d024_Quint_Out, {Transparency = 0.5}):Play()
        TweenService:Create(TitleLbl, TI.d022_Sine_Out, {TextTransparency = 0}):Play()
        TweenService:Create(ContentLbl, TI.d022_Sine_Out, {TextTransparency = 0}):Play()

        return {Close = function() close(false) end}
    end

    -- ============ Library:Alert — โมดัลแจ้งเตือนปุ่มเดียว (OK) ใช้ Confirm ภายในโดยซ่อนปุ่มยกเลิก ============
    function Library:Alert(opts)
        opts = type(opts) == "table" and opts or {}
        return Library:Confirm({
            Title = opts.Title,
            Content = opts.Content,
            ConfirmText = opts.ButtonText or "OK",
            CancelText = nil,
            HideCancel = true,
            OnConfirm = opts.OnClose,
            OnCancel = opts.OnClose,
        })
    end

    -- ============ v7: Library:Dialog — โมดัลหลายปุ่ม (สไตล์ WindUI Popup/Dialog) ============
    -- opts: Title, Content, Icon, Width, Closable(=true), OnClose,
    --       Buttons = {{Title=, Icon=, Variant="Primary"/"Secondary"/"Tertiary"/"Danger", Callback=fn, KeepOpen=false}}
    function Library:Dialog(opts)
        opts = type(opts) == "table" and opts or {}
        local Gui = Instance.new("ScreenGui")
        Gui.Name = "DialogGui"
        Gui.ResetOnSpawn = false
        Gui.IgnoreGuiInset = true
        Gui.DisplayOrder = 999
        Gui.Parent = UiParent
        table.insert(Library._Guis, Gui)

        local Backdrop = Instance.new("Frame")
        Backdrop.Size = UDim2.new(1, 0, 1, 0)
        Backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Backdrop.BackgroundTransparency = 1
        Backdrop.Active = true
        Backdrop.ZIndex = 1
        Backdrop.Parent = Gui

        local Card = Instance.new("CanvasGroup")
        Card.AnchorPoint = Vector2.new(0.5, 0.5)
        Card.Position = UDim2.new(0.5, 0, 0.5, 0)
        Card.Size = UDim2.new(0, math.clamp(tonumber(opts.Width) or 340, 260, 560), 0, 0)
        Card.AutomaticSize = Enum.AutomaticSize.Y
        applyThemeColor(Card, "Background")
        Card.GroupTransparency = 1
        Card.ZIndex = 2
        Card.Parent = Gui
        corner(Card, 14)
        local cardStroke = stroke(Card, "Stroke", 1)
        cardStroke.Transparency = 0.45
        local cScale = Instance.new("UIScale")
        cScale.Scale = 0.85
        cScale.Parent = Card
        local cPad = Instance.new("UIPadding")
        cPad.PaddingLeft = UDim.new(0, 18)
        cPad.PaddingRight = UDim.new(0, 18)
        cPad.PaddingTop = UDim.new(0, 18)
        cPad.PaddingBottom = UDim.new(0, 16)
        cPad.Parent = Card
        local cLayout = Instance.new("UIListLayout")
        cLayout.Padding = UDim.new(0, 12)
        cLayout.SortOrder = Enum.SortOrder.LayoutOrder
        cLayout.Parent = Card

        local titleText = opts.Title and Library:Translate(opts.Title) or nil
        if titleText or opts.Icon then
            local Header = Instance.new("Frame")
            Header.Size = UDim2.new(1, 0, 0, 30)
            Header.BackgroundTransparency = 1
            Header.LayoutOrder = 1
            Header.Parent = Card
            local textX = 0
            if opts.Icon then
                local Badge = Instance.new("Frame")
                Badge.Size = UDim2.new(0, 30, 0, 30)
                applyThemeColor(Badge, "AccentA")
                Badge.BackgroundTransparency = 0.8
                Badge.Parent = Header
                corner(Badge, 8)
                local BIcon = Instance.new("ImageLabel")
                BIcon.AnchorPoint = Vector2.new(0.5, 0.5)
                BIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
                BIcon.Size = UDim2.new(0, 16, 0, 16)
                BIcon.BackgroundTransparency = 1
                BIcon.Image = Library.Icons[opts.Icon] or normalizeAssetId(opts.Icon)
                applyThemeColor(BIcon, "AccentA", "ImageColor3")
                BIcon.ScaleType = Enum.ScaleType.Fit
                BIcon.Parent = Badge
                textX = 40
            end
            local TitleLbl = Instance.new("TextLabel")
            TitleLbl.Size = UDim2.new(1, -textX, 1, 0)
            TitleLbl.Position = UDim2.new(0, textX, 0, 0)
            TitleLbl.BackgroundTransparency = 1
            TitleLbl.Text = titleText or ""
            applyThemeColor(TitleLbl, "Text", "TextColor3")
            TitleLbl.FontFace = UI_Font("Bold")
            TitleLbl.TextSize = 16
            TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
            TitleLbl.TextTruncate = Enum.TextTruncate.AtEnd
            TitleLbl.Parent = Header
        end

        if opts.Content and opts.Content ~= "" then
            local ContentLbl = Instance.new("TextLabel")
            ContentLbl.Size = UDim2.new(1, 0, 0, 0)
            ContentLbl.AutomaticSize = Enum.AutomaticSize.Y
            ContentLbl.BackgroundTransparency = 1
            ContentLbl.Text = Library:Translate(opts.Content)
            ContentLbl.RichText = opts.RichText == true
            applyThemeColor(ContentLbl, "SubText", "TextColor3")
            ContentLbl.FontFace = UI_Font("Medium")
            ContentLbl.TextSize = 13.5
            ContentLbl.LineHeight = 1.3
            ContentLbl.TextWrapped = true
            ContentLbl.TextXAlignment = Enum.TextXAlignment.Left
            ContentLbl.TextYAlignment = Enum.TextYAlignment.Top
            ContentLbl.LayoutOrder = 2
            ContentLbl.Parent = Card
        end

        local buttons = (type(opts.Buttons) == "table" and #opts.Buttons > 0) and opts.Buttons or {{Title = "OK", Variant = "Primary"}}
        local vertical = #buttons > 3
        local BtnRow = Instance.new("Frame")
        BtnRow.Size = UDim2.new(1, 0, 0, 0)
        BtnRow.AutomaticSize = Enum.AutomaticSize.Y
        BtnRow.BackgroundTransparency = 1
        BtnRow.LayoutOrder = 3
        BtnRow.Parent = Card
        local rowLayout = Instance.new("UIListLayout")
        rowLayout.Padding = UDim.new(0, 8)
        rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
        if vertical then
            rowLayout.FillDirection = Enum.FillDirection.Vertical
        else
            rowLayout.FillDirection = Enum.FillDirection.Horizontal
            rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        end
        rowLayout.Parent = BtnRow

        local closed = false
        local function close()
            if closed then return end
            closed = true
            TweenService:Create(Backdrop, TI.d018_Sine_Out, {BackgroundTransparency = 1}):Play()
            TweenService:Create(cScale, TI.d018_Quint_In, {Scale = 0.88}):Play()
            TweenService:Create(Card, TI.d018_Quint_In, {GroupTransparency = 1}):Play()
            task.delay(0.2, function() if Gui then Gui:Destroy() end end)
            if opts.OnClose then safeCallback(opts.OnClose) end
        end

        for idx, b in ipairs(buttons) do
            local variant = b.Variant or (idx == #buttons and "Primary" or "Secondary")
            local Btn = Instance.new("TextButton")
            Btn.LayoutOrder = idx
            Btn.AutoButtonColor = false
            Btn.Text = ""
            Btn.ZIndex = 3
            if vertical then
                Btn.Size = UDim2.new(1, 0, 0, 36)
            else
                Btn.Size = UDim2.new(0, 0, 0, 34)
                Btn.AutomaticSize = Enum.AutomaticSize.X
            end
            local textKey = "Text"
            local whiteText = false
            if variant == "Primary" then
                applyThemeColor(Btn, "AccentA")
                accentGradient(Btn, 100)
                whiteText = true
            elseif variant == "Danger" then
                applyThemeColor(Btn, "Danger")
                whiteText = true
            elseif variant == "Tertiary" then
                Btn.BackgroundTransparency = 1
                stroke(Btn, "Stroke", 1)
                textKey = "SubText"
            else
                applyThemeColor(Btn, "ElementHover")
            end
            Btn.Parent = BtnRow
            corner(Btn, 9)
            applyPressAnimation(Btn, 0.95)
            ripple(Btn, "AccentA")
            local bPad = Instance.new("UIPadding")
            bPad.PaddingLeft = UDim.new(0, 16)
            bPad.PaddingRight = UDim.new(0, 16)
            bPad.Parent = Btn
            local bLay = Instance.new("UIListLayout")
            bLay.FillDirection = Enum.FillDirection.Horizontal
            bLay.HorizontalAlignment = Enum.HorizontalAlignment.Center
            bLay.VerticalAlignment = Enum.VerticalAlignment.Center
            bLay.Padding = UDim.new(0, 6)
            bLay.SortOrder = Enum.SortOrder.LayoutOrder
            bLay.Parent = Btn
            if b.Icon then
                local BI = Instance.new("ImageLabel")
                BI.Size = UDim2.new(0, 14, 0, 14)
                BI.BackgroundTransparency = 1
                BI.Image = Library.Icons[b.Icon] or normalizeAssetId(b.Icon)
                BI.ImageColor3 = whiteText and Color3.fromRGB(255, 255, 255) or Theme[textKey]
                BI.ScaleType = Enum.ScaleType.Fit
                BI.LayoutOrder = 1
                BI.ZIndex = 4
                BI.Parent = Btn
            end
            local BL = Instance.new("TextLabel")
            BL.Size = UDim2.new(0, 0, 1, 0)
            BL.AutomaticSize = Enum.AutomaticSize.X
            BL.BackgroundTransparency = 1
            BL.Text = tostring(Library:Translate(b.Title or b.Text or "OK"))
            if whiteText then BL.TextColor3 = Color3.fromRGB(255, 255, 255) else applyThemeColor(BL, textKey, "TextColor3") end
            BL.FontFace = UI_Font("SemiBold")
            BL.TextSize = 13
            BL.LayoutOrder = 2
            BL.ZIndex = 4
            BL.Parent = Btn
            Btn.MouseButton1Click:Connect(function()
                if b.Callback then safeCallback(b.Callback) end
                if b.KeepOpen ~= true then close() end
            end)
        end

        Backdrop.InputBegan:Connect(function(input)
            if opts.Closable == false then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                close()
            end
        end)

        TweenService:Create(Backdrop, TI.d022_Sine_Out, {BackgroundTransparency = 0.45}):Play()
        TweenService:Create(cScale, TI.d045_Back_Out, {Scale = 1}):Play()
        TweenService:Create(Card, TI.d024_Quint_Out, {GroupTransparency = 0}):Play()
        return {Close = close, Gui = Gui}
    end
    Library.Popup = Library.Dialog

