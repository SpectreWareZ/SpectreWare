    -- ============ Main window ============
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    Shadow.Size = (config.Size or UDim2.new(0, 400, 0, 380)) + UDim2.new(0, 60, 0, 60)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxassetid://1316045217"
    Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.ImageTransparency = 1
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    Shadow.Parent = ScreenGui

    local MainFrame = Instance.new("Frame")
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    local initW, initH = 380, 340
    if not IS_MOBILE then initW, initH = 500, 380 end
    if typeof(config.Size) == "UDim2" then
        initW = math.max(380, config.Size.X.Offset)
        initH = math.max(340, config.Size.Y.Offset)
    end
    MainFrame.Size = UDim2.new(0, initW, 0, initH)
    -- เงาตามขนาดหน้าต่างจริงเสมอ (เดิมเงาคงที่ พอ resize แล้วเงาไม่ตาม)
    Shadow.Size = MainFrame.Size + UDim2.new(0, 60, 0, 60)
    MainFrame:GetPropertyChangedSignal("Size"):Connect(function()
        Shadow.Size = MainFrame.Size + UDim2.new(0, 60, 0, 60)
    end)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    applyThemeColor(MainFrame, "Background")
    MainFrame.BackgroundTransparency = 1
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Parent = Shadow
    corner(MainFrame, 14)
    local mainStroke = stroke(MainFrame)
    mainStroke.Transparency = 1

    -- CanvasGroup ห่อ TopBar/Tabs/Content ไว้ เพื่อให้ fade ตอนซ่อน/ปิด UI
    -- เป็นภาพเดียวกันทั้งหมดพร้อมกัน แทนที่จะเห็นแต่ละส่วนจางไม่พร้อมกัน
    local MainContent = Instance.new("CanvasGroup")
    MainContent.Name = "MainContent"
    MainContent.Size = UDim2.new(1, 0, 1, 0)
    MainContent.BackgroundTransparency = 1
    MainContent.GroupTransparency = 0
    MainContent.Parent = MainFrame
    corner(MainContent, 14)

    local WindowScale = Instance.new("UIScale")
    WindowScale.Scale = ResponsiveScale
    WindowScale.Parent = Shadow

    local Sheen = Instance.new("Frame")
    Sheen.Name = "Sheen"
    Sheen.Size = UDim2.new(1, 0, 1, 0)
    Sheen.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Sheen.BorderSizePixel = 0
    Sheen.ZIndex = 0
    Sheen.Active = false
    Sheen.Parent = MainFrame
    corner(Sheen, 14)
    local sheenGradient = Instance.new("UIGradient")
    sheenGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255))
    sheenGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.93),
        NumberSequenceKeypoint.new(0.35, 1),
        NumberSequenceKeypoint.new(1, 1),
    })
    sheenGradient.Rotation = 100
    sheenGradient.Parent = Sheen

    local topBarH = config.SubTitle and 50 or 42
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, topBarH)
    applyThemeColor(TopBar, "Topbar")
    TopBar.BackgroundTransparency = 1
    TopBar.BorderSizePixel = 0
    TopBar.Active = true
    TopBar.Parent = MainContent
    corner(TopBar, 14)
    
    local topBarFix = Instance.new("Frame")
    topBarFix.Size = UDim2.new(1, 0, 0, 12)
    topBarFix.Position = UDim2.new(0, 0, 1, -12)
    applyThemeColor(topBarFix, "Topbar")
    topBarFix.BackgroundTransparency = 1
    topBarFix.BorderSizePixel = 0
    topBarFix.ZIndex = 0
    topBarFix.Parent = TopBar

    -- accent gradient strip ที่ขอบบนสุดของหน้าต่าง (2px, ครบความกว้าง)
    local TopAccentStrip = Instance.new("Frame")
    TopAccentStrip.Name = "TopAccentStrip"
    TopAccentStrip.Size = UDim2.new(1, -24, 0, 2)
    TopAccentStrip.Position = UDim2.new(0, 12, 0, 0)
    TopAccentStrip.BackgroundColor3 = Theme.AccentA
    TopAccentStrip.BackgroundTransparency = 0
    TopAccentStrip.BorderSizePixel = 0
    TopAccentStrip.ZIndex = 10
    TopAccentStrip.Parent = TopBar
    corner(TopAccentStrip, 1)
    local stripGrad = Instance.new("UIGradient")
    stripGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.AccentA),
        ColorSequenceKeypoint.new(0.5, Theme.AccentB),
        ColorSequenceKeypoint.new(1, Theme.AccentA),
    })
    stripGrad:SetAttribute("IsAccent", true)
    stripGrad.Parent = TopAccentStrip

    local TopBarLine = Instance.new("Frame")
    TopBarLine.Name = "TopBarLine"
    TopBarLine.Size = UDim2.new(1, 0, 0, 1)
    TopBarLine.Position = UDim2.new(0, 0, 1, 0)
    applyThemeColor(TopBarLine, "Stroke")
    TopBarLine.BackgroundTransparency = 0.4
    TopBarLine.BorderSizePixel = 0
    TopBarLine.Parent = TopBar

    local LogoDot = Instance.new("Frame")
    LogoDot.Size = UDim2.new(0, 8, 0, 8)
    LogoDot.Position = UDim2.new(0, 15, 0, config.SubTitle and 14 or 17)
    applyThemeColor(LogoDot, "AccentA")
    LogoDot.BackgroundTransparency = 1
    LogoDot.Parent = TopBar
    corner(LogoDot, 4)
    accentGradient(LogoDot, 45)

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -96, 0, 18)
    TitleLabel.Position = UDim2.new(0, 30, 0, config.SubTitle and 8 or 0)
    if not config.SubTitle then TitleLabel.Size = UDim2.new(1, -96, 1, 0) end
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = config.Title or "Pro Hub"
    applyThemeColor(TitleLabel, "Text", "TextColor3")
    TitleLabel.TextTransparency = 1
    TitleLabel.FontFace = UI_Font("Bold")
    TitleLabel.TextSize = 15
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TopBar

    local SubTitleLabel
    if config.SubTitle then
        SubTitleLabel = Instance.new("TextLabel")
        SubTitleLabel.Size = UDim2.new(1, -96, 0, 14)
        SubTitleLabel.Position = UDim2.new(0, 30, 0, 27)
        SubTitleLabel.BackgroundTransparency = 1
        SubTitleLabel.Text = config.SubTitle
        applyThemeColor(SubTitleLabel, "SubText", "TextColor3")
        SubTitleLabel.TextTransparency = 1
        SubTitleLabel.FontFace = UI_Font("Medium")
        SubTitleLabel.TextSize = 11
        SubTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
        SubTitleLabel.Parent = TopBar
        TweenService:Create(SubTitleLabel, TI.d03_Sine_Out, {TextTransparency = 0}):Play()
    end

    local CloseBtn = Instance.new("ImageButton")
    CloseBtn.Size = UDim2.new(0, 26, 0, 26)
    CloseBtn.AnchorPoint = Vector2.new(1, 0.5)
    CloseBtn.Position = UDim2.new(1, -10, 0.5, 0)
    applyThemeColor(CloseBtn, "Element")
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.AutoButtonColor = false
    CloseBtn.Image = Library.Icons.close
    applyThemeColor(CloseBtn, "SubText", "ImageColor3")
    CloseBtn.ScaleType = Enum.ScaleType.Fit
    CloseBtn.ZIndex = 5
    CloseBtn.Parent = TopBar
    corner(CloseBtn, 8)
    applyPressAnimation(CloseBtn, 0.8)
    CloseBtn.MouseEnter:Connect(function()
        TweenService:Create(CloseBtn, TI.d015_Sine_Out, {BackgroundColor3 = Theme.Danger, ImageColor3 = Color3.fromRGB(255,255,255)}):Play()
    end)
    CloseBtn.MouseLeave:Connect(function()
        TweenService:Create(CloseBtn, TI.d015_Sine_Out, {BackgroundColor3 = Theme.Element, ImageColor3 = Theme.SubText}):Play()
    end)
    CloseBtn.MouseButton1Click:Connect(function()
        Window:Confirm({
            Title = "ปิด UI",
            Content = "ยืนยันที่จะปิดหน้าต่างนี้หรือไม่?",
            ConfirmText = "ยืนยัน",
            CancelText = "ยกเลิก",
            Callback = function(result)
                if result then
                    Window:Destroy()
                end
            end
        })
    end)

    local HideBtn = Instance.new("ImageButton")
    HideBtn.Size = UDim2.new(0, 26, 0, 26)
    HideBtn.AnchorPoint = Vector2.new(1, 0.5)
    HideBtn.Position = UDim2.new(1, -46, 0.5, 0)
    applyThemeColor(HideBtn, "Element")
    HideBtn.BackgroundTransparency = 1
    HideBtn.AutoButtonColor = false
    HideBtn.Image = Library.Icons.minus
    applyThemeColor(HideBtn, "SubText", "ImageColor3")
    HideBtn.ScaleType = Enum.ScaleType.Fit
    HideBtn.ZIndex = 5
    HideBtn.Parent = TopBar
    corner(HideBtn, 8)
    applyPressAnimation(HideBtn, 0.8)
    HideBtn.MouseEnter:Connect(function()
        TweenService:Create(HideBtn, TI.d015_Sine_Out, {BackgroundColor3 = Theme.ElementHover, BackgroundTransparency = 0.3}):Play()
    end)
    HideBtn.MouseLeave:Connect(function()
        TweenService:Create(HideBtn, TI.d015_Sine_Out, {BackgroundTransparency = 1}):Play()
    end)

    local RestoreGui = Instance.new("ScreenGui")
    RestoreGui.Name = "RestoreGui"
    RestoreGui.ResetOnSpawn = false
    RestoreGui.IgnoreGuiInset = true
    RestoreGui.DisplayOrder = 999
    RestoreGui.Parent = UiParent

    local RestoreBtn = Instance.new("ImageButton")
    RestoreBtn.Name = "RestoreBtn"
    RestoreBtn.Size = UDim2.new(0, 46, 0, 46)
    RestoreBtn.Position = UDim2.new(0, 20, 0, 120)
    applyThemeColor(RestoreBtn, "AccentA")
    RestoreBtn.BackgroundTransparency = 0
    RestoreBtn.AutoButtonColor = false
    RestoreBtn.Image = ""
    RestoreBtn.ScaleType = Enum.ScaleType.Fit
    RestoreBtn.ZIndex = 20
    RestoreBtn.Visible = false
    RestoreBtn.Active = true
    RestoreBtn.Parent = RestoreGui
    corner(RestoreBtn, 23)
    local RestoreBtnScale = Instance.new("UIScale")
    RestoreBtnScale.Scale = 1
    RestoreBtnScale.Parent = RestoreBtn
    accentGradient(RestoreBtn, 100)
    stroke(RestoreBtn)

    if config.Icon then
        RestoreBtn.Image = normalizeAssetId(config.Icon)
        local iconPad = Instance.new("UIPadding")
        iconPad.PaddingLeft = UDim.new(0, 8)
        iconPad.PaddingRight = UDim.new(0, 8)
        iconPad.PaddingTop = UDim.new(0, 8)
        iconPad.PaddingBottom = UDim.new(0, 8)
        iconPad.Parent = RestoreBtn
    else
        local LetterLabel = Instance.new("TextLabel")
        LetterLabel.Name = "LetterLabel"
        LetterLabel.Size = UDim2.new(1, 0, 1, 0)
        LetterLabel.BackgroundTransparency = 1
        LetterLabel.Text = string.upper(string.sub(config.Title or "H", 1, 1))
        LetterLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        LetterLabel.FontFace = UI_Font("Bold")
        LetterLabel.TextSize = 20
        LetterLabel.ZIndex = 21
        LetterLabel.Parent = RestoreBtn
    end

    -- ============ FPS Badge (ติดข้างปุ่มเปิด UI) ============
    local FpsPill = Instance.new("Frame")
    FpsPill.Name = "FpsPill"
    FpsPill.AutomaticSize = Enum.AutomaticSize.X
    FpsPill.Size = UDim2.new(0, 0, 0, 46)          -- สูงเท่า RestoreBtn (46) ให้ตรงแนวกันสนิท
    applyThemeColor(FpsPill, "Element")
    FpsPill.BackgroundTransparency = 0.05
    FpsPill.BorderSizePixel = 0
    FpsPill.ZIndex = 20
    FpsPill.Visible = false
    FpsPill.Parent = RestoreGui
    corner(FpsPill, 23)
    local FpsStroke = stroke(FpsPill, "AccentA")   -- border สีเดียวกับปุ่ม S ให้เข้าชุด
    FpsStroke.Transparency = 0.3

    local FpsPillScale = Instance.new("UIScale")
    FpsPillScale.Scale = 1
    FpsPillScale.Parent = FpsPill

    local FpsPadding = Instance.new("UIPadding")
    FpsPadding.PaddingLeft = UDim.new(0, 14)
    FpsPadding.PaddingRight = UDim.new(0, 14)
    FpsPadding.Parent = FpsPill

    local FpsListLayout = Instance.new("UIListLayout")
    FpsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    FpsListLayout.FillDirection = Enum.FillDirection.Horizontal
    FpsListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    FpsListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    FpsListLayout.Padding = UDim.new(0, 6)
    FpsListLayout.Parent = FpsPill

    local FpsDotWrap = Instance.new("Frame")
    FpsDotWrap.Name = "FpsDotWrap"
    FpsDotWrap.Size = UDim2.new(0, 8, 0, 8)
    FpsDotWrap.BackgroundTransparency = 1
    FpsDotWrap.LayoutOrder = 1
    FpsDotWrap.ZIndex = 22
    FpsDotWrap.Visible = true
    FpsDotWrap.Parent = FpsPill

    local FpsDot = Instance.new("Frame")
    FpsDot.Name = "FpsDot"
    FpsDot.Size = UDim2.new(1, 0, 1, 0)
    FpsDot.BackgroundColor3 = Theme.Success
    FpsDot.BackgroundTransparency = 0
    FpsDot.BorderSizePixel = 0
    FpsDot.ZIndex = 22
    FpsDot.Visible = true
    FpsDot.Parent = FpsDotWrap
    corner(FpsDot, 4)

    -- glow เล็กๆ รอบจุดสี ให้ดูมีชีวิตขึ้นนิดหน่อย
    local FpsDotGlow = Instance.new("UIStroke")
    FpsDotGlow.Color = Theme.Success
    FpsDotGlow.Thickness = 3
    FpsDotGlow.Transparency = 0.6
    FpsDotGlow.Parent = FpsDot

    local FpsLabel = Instance.new("TextLabel")
    FpsLabel.Name = "FpsLabel"
    FpsLabel.BackgroundTransparency = 1
    FpsLabel.AutomaticSize = Enum.AutomaticSize.X
    FpsLabel.Size = UDim2.new(0, 0, 1, 0)
    FpsLabel.FontFace = UI_Font("Bold")
    FpsLabel.TextSize = 13
    FpsLabel.TextTransparency = 0
    FpsLabel.RichText = false
    FpsLabel.Text = "60 FPS"
    applyThemeColor(FpsLabel, "Text", "TextColor3")
    FpsLabel.TextXAlignment = Enum.TextXAlignment.Left
    FpsLabel.LayoutOrder = 2
    FpsLabel.ZIndex = 22
    FpsLabel.Visible = true
    FpsLabel.Parent = FpsPill

    -- เกาะติดขวาปุ่มเปิด UI เสมอ แม้จะลากปุ่มไปวางที่อื่น
    local function repositionFpsPill()
        FpsPill.Position = UDim2.new(
            0, RestoreBtn.Position.X.Offset + RestoreBtn.Size.X.Offset + 10,
            0, RestoreBtn.Position.Y.Offset + (RestoreBtn.Size.Y.Offset - FpsPill.AbsoluteSize.Y) / 2
        )
    end
    RestoreBtn:GetPropertyChangedSignal("Position"):Connect(repositionFpsPill)
    FpsPill:GetPropertyChangedSignal("AbsoluteSize"):Connect(repositionFpsPill)
    repositionFpsPill()

    -- sample fps แบบ smoothed (ค่าเฉลี่ยเคลื่อนที่) ทุกๆ ~0.4 วิ กันตัวเลขกระตุก
    local fpsConn
    do
        local fpsFrames, fpsAccum, fpsSmoothed = 0, 0, 60
        fpsConn = RunService.RenderStepped:Connect(function(dt)
            if dt <= 0 then return end
            fpsFrames += 1
            fpsAccum += dt
            if fpsAccum >= 0.4 then
                local currentFps = fpsFrames / fpsAccum
                fpsSmoothed = fpsSmoothed * 0.55 + currentFps * 0.45
                fpsFrames, fpsAccum = 0, 0
                local rounded = math.floor(fpsSmoothed + 0.5)
                FpsLabel.Text = rounded .. " FPS"     -- อัปเดตทุกครั้ง ไม่เช็ค Visible แล้ว กันเคสตกจังหวะ
                local dotColor
                if rounded >= 50 then
                    dotColor = Theme.Success
                elseif rounded >= 30 then
                    dotColor = Theme.Warning
                else
                    dotColor = Theme.Danger
                end
                FpsDot.BackgroundColor3 = dotColor
                FpsDotGlow.Color = dotColor
            end
        end)
    end

    -- normalize เป็น pure Offset ตั้งแต่เริ่ม กัน Scale=0.5 ปนกับ Offset ตอน tween กลับบ้านหลัง drag
    local _ss0 = ScreenGui.AbsoluteSize
    local _rp = Shadow.Position
    local _normX = _rp.X.Scale * _ss0.X + _rp.X.Offset
    local _normY = _rp.Y.Scale * _ss0.Y + _rp.Y.Offset
    Shadow.Position = UDim2.new(0, _normX, 0, _normY)
    local baseShadowPos = Shadow.Position
    local hiddenShadowPos = UDim2.new(0, _normX, 0, _normY + 14)
    local hideToken = 0
    local function setUiVisible(visible)
        hideToken = hideToken + 1
        local myToken = hideToken
        if visible then
            ScreenGui.Enabled = true
            RestoreBtn.Visible = false
            FpsPill.Visible = false
            WindowScale.Scale = ResponsiveScale * 0.82
            MainFrame.Rotation = -2.2
            Shadow.Position = hiddenShadowPos
            MainFrame.BackgroundTransparency = 1
            mainStroke.Transparency = 1
            MainContent.GroupTransparency = 1
            local easeIn = TI.d024_Quint_Out
            -- เด้งเข้าแบบสปริงแรงๆ พร้อมเอียงตัวเล็กน้อยแล้วสะบัดกลับ ให้ความรู้สึก "โหด" ตอนเปิดหน้าต่าง
            TweenService:Create(WindowScale, TI.d045_Back_Out, {Scale = ResponsiveScale}):Play()
            TweenService:Create(MainFrame, TI.d045_Back_Out, {Rotation = 0}):Play()
            TweenService:Create(Shadow, easeIn, {Position = baseShadowPos}):Play()
            TweenService:Create(MainFrame, easeIn, {BackgroundTransparency = 0}):Play()
            TweenService:Create(mainStroke, easeIn, {Transparency = 0.5}):Play()
            TweenService:Create(MainContent, TI.d022_Sine_Out, {GroupTransparency = 0}):Play()
        else
            local easeOut = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
            local t = TweenService:Create(WindowScale, easeOut, {Scale = ResponsiveScale * 0.9})
            TweenService:Create(Shadow, easeOut, {Position = hiddenShadowPos}):Play()
            TweenService:Create(MainFrame, easeOut, {BackgroundTransparency = 1}):Play()
            TweenService:Create(mainStroke, easeOut, {Transparency = 1}):Play()
            TweenService:Create(MainContent, TweenInfo.new(0.16, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {GroupTransparency = 1}):Play()
            t:Play()
            t.Completed:Connect(function()
                if myToken ~= hideToken then return end
                ScreenGui.Enabled = false
                Shadow.Position = baseShadowPos
                RestoreBtn.Visible = true
                RestoreBtnScale.Scale = 0.5
                TweenService:Create(RestoreBtnScale, TI.d022_Back_Out, {Scale = 1}):Play()
                FpsPill.Visible = true
                FpsPillScale.Scale = 0.5
                TweenService:Create(FpsPillScale, TI.d022_Back_Out, {Scale = 1}):Play()
            end)
        end
    end

    -- หมุนจอ/ปรับขนาดหน้าต่าง (มือถือ↔PC, พับ-กางจอ) → คำนวณ ResponsiveScale ใหม่แล้ว tween เนียนๆ
    -- ไม่ snap ทันที กันกระตุกตอนหมุนจอ
    ScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        local newScale = computeResponsiveScale()
        if math.abs(newScale - ResponsiveScale) < 0.005 then return end
        ResponsiveScale = newScale
        if ScreenGui.Enabled then
            TweenService:Create(WindowScale, TI.d02_Sine_Out, {Scale = ResponsiveScale}):Play()
        end
    end)

    HideBtn.MouseButton1Click:Connect(function() setUiVisible(false) end)

    do
        local rDragging, rDragStart, rStartPos, rTouch, rMoved = false, nil, nil, nil, false
        local rChangedConn, rEndedConn = nil, nil

        -- กันปุ่ม S ลากหลุดจอ (RestoreBtn มี AnchorPoint 0,0 ค่า Offset คือมุมบนซ้าย)
        local function clampRestorePos(pos)
            local screenSize = RestoreGui.AbsoluteSize
            local w, h = RestoreBtn.AbsoluteSize.X, RestoreBtn.AbsoluteSize.Y
            local x = math.clamp(pos.X.Offset, 0, math.max(0, screenSize.X - w))
            local y = math.clamp(pos.Y.Offset, 0, math.max(0, screenSize.Y - h))
            return UDim2.new(0, x, 0, y)
        end

        local function stopRestoreDrag(input)
            if rDragging and not rMoved then
                setUiVisible(true)
            end
            rDragging = false
            if input and input == rTouch then rTouch = nil end
            if rChangedConn then rChangedConn:Disconnect(); rChangedConn = nil end
            if rEndedConn then rEndedConn:Disconnect(); rEndedConn = nil end
        end

        RestoreBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                rDragging = true
                rMoved = false
                rDragStart = input.Position
                rStartPos = RestoreBtn.Position
                if input.UserInputType == Enum.UserInputType.Touch then rTouch = input end

                rChangedConn = UserInputService.InputChanged:Connect(function(input2)
                    if rDragging and (input2.UserInputType == Enum.UserInputType.MouseMovement or input2.UserInputType == Enum.UserInputType.Touch) then
                        if input2.UserInputType == Enum.UserInputType.MouseMovement or input2 == rTouch then
                            local delta = input2.Position - rDragStart
                            if delta.Magnitude > 4 then rMoved = true end
                            RestoreBtn.Position = clampRestorePos(UDim2.new(rStartPos.X.Scale, rStartPos.X.Offset + delta.X, rStartPos.Y.Scale, rStartPos.Y.Offset + delta.Y))
                        end
                    end
                end)
                rEndedConn = UserInputService.InputEnded:Connect(function(input2)
                    if input2.UserInputType == Enum.UserInputType.MouseButton1 or input2.UserInputType == Enum.UserInputType.Touch then
                        stopRestoreDrag(input2)
                    end
                end)
            end
        end)
    end

    local SIDEBAR_W = tonumber(config.SideBarWidth) or (IS_MOBILE and 118 or 132)
    local TabContainer = Instance.new("Frame")
    TabContainer.Size = UDim2.new(0, SIDEBAR_W, 1, -topBarH)
    TabContainer.Position = UDim2.new(0, 0, 0, topBarH)
    applyThemeColor(TabContainer, "Sidebar")
    TabContainer.BackgroundTransparency = 1
    TabContainer.BorderSizePixel = 0
    TabContainer.Active = true
    TabContainer.Parent = MainContent
    corner(TabContainer, 12)

    -- ============ ช่องค้นหาแท็บ (sticky อยู่บนสุดของ Sidebar) ============
    local TabSearchWrap = Instance.new("Frame")
    TabSearchWrap.Size = UDim2.new(1, -12, 0, 30)
    TabSearchWrap.Position = UDim2.new(0, 6, 0, 6)
    applyThemeColor(TabSearchWrap, "Background")
    TabSearchWrap.BackgroundTransparency = 0.15
    TabSearchWrap.ClipsDescendants = true
    TabSearchWrap.Parent = TabContainer
    corner(TabSearchWrap, 14) -- โค้งมนแบบแคปซูล ดูทันสมัยขึ้น
    local tabSearchStroke = stroke(TabSearchWrap)
    tabSearchStroke.Thickness = 1
    tabSearchStroke.Transparency = 0.75
    -- แถบเรืองแสงสีธีม ซ้อนอยู่เหนือกรอบปกติ โผล่มาตอน focus (ไม่แตะสี Stroke ที่ผูกกับระบบ Theme)
    local tabSearchGlow = stroke(TabSearchWrap, "AccentA", 1.2)
    tabSearchGlow.Transparency = 1
    -- ชั้นไล่เฉดบางๆ ให้พื้นผิวดูมีมิติ ไม่แบนราบ
    local tabSearchSheen = Instance.new("UIGradient")
    tabSearchSheen.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255))
    tabSearchSheen.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.93), NumberSequenceKeypoint.new(1, 1)})
    tabSearchSheen.Rotation = 90
    tabSearchSheen.Parent = TabSearchWrap
    local tabSearchScale = Instance.new("UIScale")
    tabSearchScale.Parent = TabSearchWrap

    local TabSearchIcon = Instance.new("ImageLabel")
    TabSearchIcon.Size = UDim2.new(0, 12, 0, 12)
    TabSearchIcon.AnchorPoint = Vector2.new(0, 0.5)
    TabSearchIcon.Position = UDim2.new(0, 9, 0.5, 0)
    TabSearchIcon.BackgroundTransparency = 1
    TabSearchIcon.ImageTransparency = 0.2
    TabSearchIcon.Image = Library.Icons.search
    applyThemeColor(TabSearchIcon, "SubText", "ImageColor3")
    TabSearchIcon.ScaleType = Enum.ScaleType.Fit
    TabSearchIcon.Parent = TabSearchWrap

    local TabSearchBox = Instance.new("TextBox")
    TabSearchBox.Position = UDim2.new(0, 26, 0, 0)
    TabSearchBox.Size = UDim2.new(1, -46, 1, 0)
    TabSearchBox.BackgroundTransparency = 1
    TabSearchBox.Text = ""
    TabSearchBox.PlaceholderText = "ค้นหา"
    applyThemeColor(TabSearchBox, "Text", "TextColor3")
    applyThemeColor(TabSearchBox, "SubText", "PlaceholderColor3")
    TabSearchBox.FontFace = UI_Font("SemiBold")
    TabSearchBox.TextSize = 11.5
    TabSearchBox.ClearTextOnFocus = false
    TabSearchBox.TextXAlignment = Enum.TextXAlignment.Left
    TabSearchBox.Parent = TabSearchWrap

    -- ปุ่มล้างคำค้นหา (X) โผล่มาเมื่อมีข้อความ กดแล้วเคลียร์ + โฟกัสกลับทันที
    local TabSearchClear = Instance.new("ImageButton")
    TabSearchClear.AnchorPoint = Vector2.new(1, 0.5)
    TabSearchClear.Position = UDim2.new(1, -6, 0.5, 0)
    TabSearchClear.Size = UDim2.new(0, 15, 0, 15)
    TabSearchClear.BackgroundTransparency = 1
    TabSearchClear.AutoButtonColor = false
    TabSearchClear.Image = Library.Icons.close
    applyThemeColor(TabSearchClear, "SubText", "ImageColor3")
    TabSearchClear.ImageTransparency = 1
    TabSearchClear.ScaleType = Enum.ScaleType.Fit
    TabSearchClear.Parent = TabSearchWrap
    TabSearchClear.MouseButton1Click:Connect(function()
        TabSearchBox.Text = ""
        TabSearchBox:CaptureFocus()
    end)

    TabSearchBox.Focused:Connect(function()
        TweenService:Create(tabSearchStroke, TI.d015_Sine_Out, {Transparency = 0.3}):Play()
        TweenService:Create(tabSearchGlow, TI.d02_Sine_Out, {Transparency = 0.35}):Play()
        TweenService:Create(TabSearchWrap, TI.d015_Sine_Out, {BackgroundTransparency = 0}):Play()
        TweenService:Create(TabSearchIcon, TI.d015_Sine_Out, {ImageTransparency = 0}):Play()
        TweenService:Create(tabSearchScale, TI.d02_Back_Out, {Scale = 1.015}):Play()
    end)
    TabSearchBox.FocusLost:Connect(function()
        TweenService:Create(tabSearchStroke, TI.d015_Sine_Out, {Transparency = 0.75}):Play()
        TweenService:Create(tabSearchGlow, TI.d015_Sine_Out, {Transparency = 1}):Play()
        TweenService:Create(TabSearchWrap, TI.d015_Sine_Out, {BackgroundTransparency = 0.15}):Play()
        TweenService:Create(TabSearchIcon, TI.d015_Sine_Out, {ImageTransparency = 0.2}):Play()
        TweenService:Create(tabSearchScale, TI.d02_Back_Out, {Scale = 1}):Play()
    end)
    TabSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        TweenService:Create(TabSearchClear, TI.d012_Sine_Out, {ImageTransparency = TabSearchBox.Text == "" and 1 or 0.1}):Play()
    end)

    local TabList = Instance.new("ScrollingFrame")
    TabList.Size = UDim2.new(1, -12, 1, -46)
    TabList.Position = UDim2.new(0, 6, 0, 40)
    TabList.BackgroundTransparency = 1
    TabList.ScrollBarThickness = 2
    applyThemeColor(TabList, "AccentA", "ScrollBarImageColor3")
    TabList.Active = true
    TabList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    TabList.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabList.Parent = TabContainer
    local TabLayout = Instance.new("UIListLayout")
    TabLayout.Padding = UDim.new(0, 4)
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    -- ปุ่มแท็บอยู่ใน TabHolder (มี UIListLayout) ส่วน ActiveIndicator อยู่นอก layout
    -- ไม่งั้น UIListLayout จะยึดตำแหน่ง indicator ทำให้กลายเป็นแถบว่างค้างบนสุดและไม่ไถลตามแท็บ
    local TabHolder = Instance.new("Frame")
    TabHolder.Name = "TabHolder"
    TabHolder.BackgroundTransparency = 1
    TabHolder.Size = UDim2.new(1, 0, 0, 0)
    TabHolder.AutomaticSize = Enum.AutomaticSize.Y
    TabHolder.Parent = TabList
    TabLayout.Parent = TabHolder

    -- ============ SLIDING ACTIVE-TAB INDICATOR ============
    -- แถบไฮไลต์เดียวที่ไถลลื่นๆ จากตำแหน่งแท็บเดิมไปตำแหน่งแท็บใหม่ (Back_Out) แทนการกระพริบทีละปุ่ม
    -- ต้องมี ZIndex ต่ำกว่าปุ่มแท็บ (ปุ่มโปร่งใสตอนไม่ active อยู่แล้ว เลยเห็นแถบทะลุขึ้นมาข้างหลังสวยๆ)
    local ActiveIndicator = Instance.new("Frame")
    ActiveIndicator.Name = "ActiveIndicator"
    ActiveIndicator.Size = UDim2.new(1, 0, 0, 36)
    ActiveIndicator.Position = UDim2.new(0, 0, 0, 0)
    ActiveIndicator.BackgroundTransparency = 1
    applyThemeColor(ActiveIndicator, "AccentA")
    ActiveIndicator.BorderSizePixel = 0
    ActiveIndicator.ZIndex = 0
    ActiveIndicator.Parent = TabList
    corner(ActiveIndicator, 8)
    accentGradient(ActiveIndicator, 100)
    local indicatorStroke = stroke(ActiveIndicator, "AccentA")
    indicatorStroke.Transparency = 1

    local function slideIndicatorTo(targetBtn, instant)
        ActiveIndicator.Visible = true
        if instant then
            ActiveIndicator.Position = targetBtn.Position
            ActiveIndicator.Size = targetBtn.Size
            ActiveIndicator.BackgroundTransparency = 0.88
            indicatorStroke.Transparency = 0.7
            return
        end
        TweenService:Create(ActiveIndicator, TI.d02_Back_Out, {
            Position = targetBtn.Position,
            Size = targetBtn.Size,
            BackgroundTransparency = 0.88,
        }):Play()
        TweenService:Create(indicatorStroke, TI.d02_Back_Out, {Transparency = 0.7}):Play()
    end

    -- registry ของแท็บทั้งหมด (ใช้กรองตอนค้นหา) + label "ไม่พบแท็บ"
    local allTabs = {}
    local TabEmptyLbl = Instance.new("TextLabel")
    TabEmptyLbl.Size = UDim2.new(1, 0, 0, 30)
    TabEmptyLbl.BackgroundTransparency = 1
    TabEmptyLbl.Text = "ไม่พบแท็บ"
    applyThemeColor(TabEmptyLbl, "SubText", "TextColor3")
    TabEmptyLbl.FontFace = UI_Font("SemiBold")
    TabEmptyLbl.TextSize = 12
    TabEmptyLbl.Visible = false
    TabEmptyLbl.Parent = TabHolder

    local function applyTabFilter(query)
        query = (query or ""):lower()
        local visibleCount = 0
        for _, entry in ipairs(allTabs) do
            local match = query == "" or string.find(entry.name:lower(), query, 1, true) ~= nil
            entry.btn.Visible = match
            if match then visibleCount += 1 end
        end
        TabEmptyLbl.Visible = visibleCount == 0
    end
    TabSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        applyTabFilter(TabSearchBox.Text)
    end)

    local ContentArea = Instance.new("Frame")
    ContentArea.Size = UDim2.new(1, -SIDEBAR_W, 1, -topBarH)
    ContentArea.Position = UDim2.new(0, SIDEBAR_W, 0, topBarH)
    ContentArea.BackgroundTransparency = 1
    ContentArea.Active = true
    ContentArea.Parent = MainContent

    local resizing = false
    local ResizeHandle = Instance.new("ImageButton")
    ResizeHandle.Size = UDim2.new(0, 34, 0, 34)
    ResizeHandle.AnchorPoint = Vector2.new(1, 1)
    ResizeHandle.Position = UDim2.new(1, 0, 1, 0)
    ResizeHandle.BackgroundTransparency = 1
    ResizeHandle.AutoButtonColor = false
    ResizeHandle.Image = ""
    ResizeHandle.ZIndex = 6
    ResizeHandle.Parent = MainContent

    -- พื้นหลัง pill โชว์ตอน hover/resize
    local ResizeBg = Instance.new("Frame")
    ResizeBg.AnchorPoint = Vector2.new(1, 1)
    ResizeBg.Position = UDim2.new(1, -2, 1, -2)
    ResizeBg.Size = UDim2.new(0, 28, 0, 28)
    ResizeBg.BackgroundColor3 = Theme.AccentA
    ResizeBg.BackgroundTransparency = 1
    ResizeBg.BorderSizePixel = 0
    ResizeBg.ZIndex = 5
    ResizeBg.Parent = ResizeHandle
    corner(ResizeBg, 8)

    local ResizeIcon = Instance.new("ImageLabel")
    ResizeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    ResizeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    ResizeIcon.Size = UDim2.new(0, 14, 0, 14)
    ResizeIcon.BackgroundTransparency = 1
    ResizeIcon.Image = "rbxassetid://10709760051"
    ResizeIcon.Rotation = 90
    ResizeIcon.ImageTransparency = 0.55
    ResizeIcon.ImageColor3 = Theme.SubText
    ResizeIcon.ScaleType = Enum.ScaleType.Fit
    ResizeIcon.ZIndex = 6
    ResizeIcon.Parent = ResizeBg

    local ResizeIconScale = Instance.new("UIScale")
    ResizeIconScale.Scale = 1
    ResizeIconScale.Parent = ResizeBg

    ResizeHandle.MouseEnter:Connect(function()
        TweenService:Create(ResizeBg, TI.d015_Sine_Out, {BackgroundTransparency = 0.82}):Play()
        TweenService:Create(ResizeIcon, TI.d015_Sine_Out, {ImageTransparency = 0, ImageColor3 = Theme.AccentA}):Play()
        TweenService:Create(ResizeIconScale, TI.d015_Sine_Out, {Scale = 1.1}):Play()
    end)
    ResizeHandle.MouseLeave:Connect(function()
        if not resizing then
            TweenService:Create(ResizeBg, TI.d015_Sine_Out, {BackgroundTransparency = 1}):Play()
            TweenService:Create(ResizeIcon, TI.d015_Sine_Out, {ImageTransparency = 0.55, ImageColor3 = Theme.SubText}):Play()
            TweenService:Create(ResizeIconScale, TI.d015_Sine_Out, {Scale = 1}):Play()
        end
    end)

    local Tabs = {}
    local CurrentTab = nil
    local closeActivePopup = function() end
    local tabOrderCounter = 0
    local windowTabList = {}   -- Tab object ทั้งหมด (ใช้กับ Window:SelectTab/GetTabs)
    local topbarButtons = {}   -- ปุ่มเพิ่มบน TopBar (Window:CreateTopbarButton)
    local function topbarButtonHit(pos)
        for _, b in ipairs(topbarButtons) do
            if b.Btn.Parent and isPointOverGui(pos, b.Btn) then return true end
        end
        return false
    end
    -- ค้นหา/ซ่อนแท็บแล้ว layout ขยับ → ให้ indicator ตามปุ่มแท็บปัจจุบันเสมอ
    TabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        task.defer(function()
            if CurrentTab and CurrentTab.Btn and CurrentTab.Btn.Parent then
                if CurrentTab.Btn.Visible then
                    ActiveIndicator.Position = CurrentTab.Btn.Position
                    ActiveIndicator.Size = CurrentTab.Btn.Size
                    ActiveIndicator.Visible = true
                else
                    ActiveIndicator.Visible = false
                end
            end
        end)
    end)

    TweenService:Create(MainFrame, TI.d028_Sine_Out, {
        BackgroundTransparency = 0
    }):Play()
    TweenService:Create(mainStroke, TI.d028_Sine_Out, {Transparency = 0.5}):Play()
    TweenService:Create(TopBar, TI.d028_Sine_Out, {BackgroundTransparency = 0}):Play()
    TweenService:Create(topBarFix, TI.d028_Sine_Out, {BackgroundTransparency = 0}):Play()
    TweenService:Create(TitleLabel, TI.d03_Sine_Out, {TextTransparency = 0}):Play()
    TweenService:Create(LogoDot, TI.d03_Sine_Out, {BackgroundTransparency = 0}):Play()
    TweenService:Create(CloseBtn, TI.d028_Sine_Out, {ImageTransparency = 1}):Play()
    TweenService:Create(CloseBtn, TI.d028_Sine_Out, {ImageTransparency = 0}):Play()
    HideBtn.ImageTransparency = 1
    TweenService:Create(HideBtn, TI.d028_Sine_Out, {ImageTransparency = 0}):Play()
    TweenService:Create(TabContainer, TI.d028_Sine_Out, {BackgroundTransparency = 0}):Play()

    local toggleKeyConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        local key = config.ToggleKeybind
        if key and input.KeyCode == key then
            setUiVisible(not ScreenGui.Enabled)
        end
    end)

    function Window:Toggle() setUiVisible(not ScreenGui.Enabled) end
    function Window:SetTitle(newTitle) TitleLabel.Text = newTitle end
    function Window:Minimize() setUiVisible(false) end
    function Window:Restore() setUiVisible(true) end

    function Window:SetIcon(icon)
        local letterLabel = RestoreBtn:FindFirstChild("LetterLabel")
        if letterLabel then letterLabel:Destroy() end
        RestoreBtn.Image = normalizeAssetId(icon)
        if RestoreBtn:FindFirstChildOfClass("UIPadding") == nil then
            local iconPad = Instance.new("UIPadding")
            iconPad.PaddingLeft = UDim.new(0, 8)
            iconPad.PaddingRight = UDim.new(0, 8)
            iconPad.PaddingTop = UDim.new(0, 8)
            iconPad.PaddingBottom = UDim.new(0, 8)
            iconPad.Parent = RestoreBtn
        end
    end

    local closeCallbacks = {}
    function Window:BindToClose(callback)
        if type(callback) == "function" then table.insert(closeCallbacks, callback) end
    end

    local activeWatermark, activeKeyList = nil, nil

    function Window:Destroy()
        local function finalize()
            for _, cb in ipairs(closeCallbacks) do
                pcall(cb)
            end
            if activeWatermark then pcall(function() activeWatermark:Destroy() end) end
            if activeKeyList then pcall(function() activeKeyList:Destroy() end) end
            if fpsConn then fpsConn:Disconnect() end
            if toggleKeyConn then toggleKeyConn:Disconnect() end
            ScreenGui:Destroy(); RestoreGui:Destroy(); NotifyGui:Destroy(); TooltipGui:Destroy()
        end
        if ScreenGui.Enabled then
            local easeOut = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
            TweenService:Create(WindowScale, easeOut, {Scale = ResponsiveScale * 0.9}):Play()
            TweenService:Create(Shadow, easeOut, {Position = hiddenShadowPos, ImageTransparency = 1}):Play()
            TweenService:Create(MainFrame, easeOut, {BackgroundTransparency = 1}):Play()
            TweenService:Create(mainStroke, easeOut, {Transparency = 1}):Play()
            TweenService:Create(MainContent, TweenInfo.new(0.16, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {GroupTransparency = 1}):Play()
            task.delay(0.22, finalize)
        else
            finalize()
        end
    end

    function Window:CreateWatermark(config)
        config = type(config) == "table" and config or {}

        local oldWM = UiParent:FindFirstChild("WatermarkGui")
        if oldWM then oldWM:Destroy() end

        local WatermarkGui = Instance.new("ScreenGui")
        WatermarkGui.Name = "WatermarkGui"
        WatermarkGui.ResetOnSpawn = false
        WatermarkGui.IgnoreGuiInset = true
        WatermarkGui.DisplayOrder = 999
        WatermarkGui.Parent = UiParent

        local Pill = Instance.new("Frame")
        Pill.Position = config.Position or UDim2.new(0, 12, 0, 12)
        Pill.Size = UDim2.new(0, 0, 0, 30)
        Pill.AutomaticSize = Enum.AutomaticSize.X
        applyThemeColor(Pill, "Element")
        Pill.Visible = config.Visible ~= false
        Pill.Parent = WatermarkGui
        corner(Pill, 8)
        stroke(Pill)

        local AccentDot = Instance.new("Frame")
        AccentDot.AnchorPoint = Vector2.new(0, 0.5)
        AccentDot.Size = UDim2.new(0, 6, 0, 6)
        AccentDot.Position = UDim2.new(0, 10, 0.5, 0)
        applyThemeColor(AccentDot, "AccentA")
        AccentDot.Parent = Pill
        corner(AccentDot, 3)
        accentGradient(AccentDot, 0)

        local Label = Instance.new("TextLabel")
        Label.BackgroundTransparency = 1
        Label.Position = UDim2.new(0, 24, 0, 0)
        Label.Size = UDim2.new(0, 0, 1, 0)
        Label.AutomaticSize = Enum.AutomaticSize.X
        Label.FontFace = UI_Font("SemiBold")
        Label.TextSize = 12
        applyThemeColor(Label, "Text", "TextColor3")
        Label.Text = config.Text or "SpectreWare"
        Label.Parent = Pill

        local Pad = Instance.new("UIPadding")
        Pad.PaddingRight = UDim.new(0, 12)
        Pad.Parent = Pill

        local heartbeatConn
        if config.ShowFPS or config.ShowPing then
            local frames, lastClock, fps = 0, os.clock(), 0
            local lastPing = nil
            local function refreshStatsText()
                local parts = {config.Text or "SpectreWare"}
                if config.ShowFPS then table.insert(parts, fps .. " FPS") end
                if config.ShowPing then
                    local ok, ping = pcall(function()
                        return math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue())
                    end)
                    if ok and ping then lastPing = ping end
                    table.insert(parts, (lastPing or "--") .. " ms")
                end
                Label.Text = table.concat(parts, "  •  ")
            end
            refreshStatsText()
            heartbeatConn = RunService.Heartbeat:Connect(function()
                frames = frames + 1
                local now = os.clock()
                if now - lastClock >= 1 then
                    fps, frames, lastClock = frames, 0, now
                    refreshStatsText()
                end
            end)
        end

        local Watermark = {}
        function Watermark:SetText(text)
            config.Text = text
            if not (config.ShowFPS or config.ShowPing) then Label.Text = text end
        end
        function Watermark:Show() Pill.Visible = true end
        function Watermark:Hide() Pill.Visible = false end
        function Watermark:Toggle() Pill.Visible = not Pill.Visible end
        function Watermark:Destroy()
            if heartbeatConn then heartbeatConn:Disconnect() end
            WatermarkGui:Destroy()
        end
        activeWatermark = Watermark
        return Watermark
    end

    function Window:CreateKeyList(config)
        config = type(config) == "table" and config or {}

        local oldKL = UiParent:FindFirstChild("KeyListGui")
        if oldKL then oldKL:Destroy() end

        local KeyListGui = Instance.new("ScreenGui")
        KeyListGui.Name = "KeyListGui"
        KeyListGui.ResetOnSpawn = false
        KeyListGui.IgnoreGuiInset = true
        KeyListGui.DisplayOrder = 997
        KeyListGui.Parent = UiParent

        local Holder = Instance.new("Frame")
        Holder.AnchorPoint = Vector2.new(1, 0.5)
        Holder.Position = config.Position or UDim2.new(1, -12, 0.5, 0)
        Holder.Size = UDim2.new(0, 176, 0, 0)
        Holder.AutomaticSize = Enum.AutomaticSize.Y
        applyThemeColor(Holder, "Element")
        Holder.Visible = config.Visible ~= false
        Holder.Parent = KeyListGui
        corner(Holder, 10)
        stroke(Holder)

        local Pad = Instance.new("UIPadding")
        Pad.PaddingLeft = UDim.new(0, 10); Pad.PaddingRight = UDim.new(0, 10)
        Pad.PaddingTop = UDim.new(0, 8); Pad.PaddingBottom = UDim.new(0, 8)
        Pad.Parent = Holder

        local Layout = Instance.new("UIListLayout")
        Layout.SortOrder = Enum.SortOrder.LayoutOrder
        Layout.Padding = UDim.new(0, 4)
        Layout.Parent = Holder

        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(1, 0, 0, 18)
        Title.LayoutOrder = 0
        Title.BackgroundTransparency = 1
        Title.Text = config.Title or "KEYBINDS"
        Title.FontFace = UI_Font("Bold")
        Title.TextSize = 11
        applyThemeColor(Title, "SubText", "TextColor3")
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.Parent = Holder

        local rowConns = {}
        local KeyList = {}
        local itemCount = 0

        function KeyList:AddItem(item)
            item = type(item) == "table" and item or {}
            itemCount = itemCount + 1
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 20)
            Row.BackgroundTransparency = 1
            Row.LayoutOrder = itemCount
            Row.Parent = Holder

            local NameLbl = Instance.new("TextLabel")
            NameLbl.Size = UDim2.new(0.58, 0, 1, 0)
            NameLbl.BackgroundTransparency = 1
            NameLbl.Text = item.Text or "Action"
            NameLbl.FontFace = UI_Font("Medium")
            NameLbl.TextSize = 12
            NameLbl.TextXAlignment = Enum.TextXAlignment.Left
            NameLbl.TextTruncate = Enum.TextTruncate.AtEnd
            applyThemeColor(NameLbl, "SubText", "TextColor3")
            NameLbl.Parent = Row

            local KeyLbl = Instance.new("TextLabel")
            KeyLbl.Size = UDim2.new(0.42, 0, 1, 0)
            KeyLbl.Position = UDim2.new(0.58, 0, 0, 0)
            KeyLbl.BackgroundTransparency = 1
            KeyLbl.FontFace = UI_Font("Bold")
            KeyLbl.TextSize = 12
            KeyLbl.TextXAlignment = Enum.TextXAlignment.Right
            applyThemeColor(KeyLbl, "AccentA", "TextColor3")
            KeyLbl.Parent = Row

            local function updateKey()
                local kc = Library.Flags[item.Flag]
                KeyLbl.Text = (kc and kc.Name) or "None"
            end
            updateKey()
            table.insert(rowConns, Library.FlagChanged.Event:Connect(function(changedFlag)
                if changedFlag == item.Flag then updateKey() end
            end))
        end

        for _, item in ipairs(config.Items or {}) do KeyList:AddItem(item) end

        function KeyList:Show() Holder.Visible = true end
        function KeyList:Hide() Holder.Visible = false end
        function KeyList:Destroy()
            for _, conn in ipairs(rowConns) do conn:Disconnect() end
            KeyListGui:Destroy()
        end
        activeKeyList = KeyList
        return KeyList
    end

    function Window:Alert(opts)
        opts = type(opts) == "table" and opts or {}
        local Overlay = Instance.new("Frame")
        Overlay.Size = UDim2.new(1, 0, 1, 0)
        Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Overlay.BackgroundTransparency = 1
        Overlay.Active = true
        Overlay.ZIndex = 50
        Overlay.Parent = ScreenGui

        local Box = Instance.new("Frame")
        Box.Size = UDim2.new(0, 280, 0, 150)
        Box.AnchorPoint = Vector2.new(0.5, 0.5)
        Box.Position = UDim2.new(0.5, 0, 0.5, 0)
        applyThemeColor(Box, "Background")
        Box.ZIndex = 51
        Box.Parent = Overlay
        corner(Box, 12)
        stroke(Box)

        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(1, -24, 0, 24)
        Title.Position = UDim2.new(0, 12, 0, 12)
        Title.BackgroundTransparency = 1
        Title.Text = opts.Title or "Alert"
        applyThemeColor(Title, "Text", "TextColor3")
        Title.FontFace = UI_Font("Bold")
        Title.TextSize = 15
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.ZIndex = 52
        Title.Parent = Box

        local Content = Instance.new("TextLabel")
        Content.Size = UDim2.new(1, -24, 0, 60)
        Content.Position = UDim2.new(0, 12, 0, 40)
        Content.BackgroundTransparency = 1
        Content.Text = opts.Content or ""
        applyThemeColor(Content, "SubText", "TextColor3")
        Content.FontFace = UI_Font("Medium")
        Content.TextSize = 13.5
        Content.LineHeight = 1.3
        Content.TextWrapped = true
        Content.TextXAlignment = Enum.TextXAlignment.Left
        Content.TextYAlignment = Enum.TextYAlignment.Top
        Content.ZIndex = 52
        Content.Parent = Box

        local OkBtn = Instance.new("TextButton")
        OkBtn.Size = UDim2.new(1, -24, 0, 36)
        OkBtn.Position = UDim2.new(0, 12, 1, -48)
        applyThemeColor(OkBtn, "AccentA")
        OkBtn.AutoButtonColor = false
        OkBtn.Text = opts.ButtonText or "OK"
        applyThemeColor(OkBtn, "Text", "TextColor3")
        OkBtn.FontFace = UI_Font("Bold")
        OkBtn.TextSize = 14
        OkBtn.ZIndex = 52
        OkBtn.Parent = Box
        corner(OkBtn, 9)
        applyPressAnimation(OkBtn, 0.95)

        TweenService:Create(Overlay, TI.d02_Sine_Out, {BackgroundTransparency = 1}):Play()

        local function closeAlert()
            TweenService:Create(Overlay, TI.d015_Sine_Out, {BackgroundTransparency = 1}):Play()
            task.delay(0.15, function() if Overlay then Overlay:Destroy() end end)
            if opts.Callback then opts.Callback() end
        end
        OkBtn.MouseButton1Click:Connect(closeAlert)
        return newElement(Overlay, nil, nil, closeAlert)
    end

    function Window:Confirm(opts)
        opts = type(opts) == "table" and opts or {}
        local Overlay = Instance.new("Frame")
        Overlay.Size = UDim2.new(1, 0, 1, 0)
        Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Overlay.BackgroundTransparency = 1
        Overlay.Active = true
        Overlay.ZIndex = 50
        Overlay.Parent = ScreenGui

        local Box = Instance.new("Frame")
        Box.Size = UDim2.new(0, 280, 0, 150)
        Box.AnchorPoint = Vector2.new(0.5, 0.5)
        Box.Position = UDim2.new(0.5, 0, 0.5, 0)
        applyThemeColor(Box, "Background")
        Box.ZIndex = 51
        Box.Parent = Overlay
        corner(Box, 12)
        stroke(Box)

        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(1, -24, 0, 24)
        Title.Position = UDim2.new(0, 12, 0, 12)
        Title.BackgroundTransparency = 1
        Title.Text = opts.Title or "Confirm"
        applyThemeColor(Title, "Text", "TextColor3")
        Title.FontFace = UI_Font("Bold")
        Title.TextSize = 15
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.ZIndex = 52
        Title.Parent = Box

        local Content = Instance.new("TextLabel")
        Content.Size = UDim2.new(1, -24, 0, 60)
        Content.Position = UDim2.new(0, 12, 0, 40)
        Content.BackgroundTransparency = 1
        Content.Text = opts.Content or ""
        applyThemeColor(Content, "SubText", "TextColor3")
        Content.FontFace = UI_Font("Medium")
        Content.TextSize = 13.5
        Content.LineHeight = 1.3
        Content.TextWrapped = true
        Content.TextXAlignment = Enum.TextXAlignment.Left
        Content.TextYAlignment = Enum.TextYAlignment.Top
        Content.ZIndex = 52
        Content.Parent = Box

        local CancelBtn = Instance.new("TextButton")
        CancelBtn.Size = UDim2.new(0.5, -18, 0, 36)
        CancelBtn.Position = UDim2.new(0, 12, 1, -48)
        applyThemeColor(CancelBtn, "Element")
        CancelBtn.AutoButtonColor = false
        CancelBtn.Text = opts.CancelText or "Cancel"
        applyThemeColor(CancelBtn, "SubText", "TextColor3")
        CancelBtn.FontFace = UI_Font("Bold")
        CancelBtn.TextSize = 13
        CancelBtn.ZIndex = 52
        CancelBtn.Parent = Box
        corner(CancelBtn, 9)
        applyPressAnimation(CancelBtn, 0.95)

        local ConfirmBtn = Instance.new("TextButton")
        ConfirmBtn.Size = UDim2.new(0.5, -18, 0, 36)
        ConfirmBtn.Position = UDim2.new(0.5, 6, 1, -48)
        applyThemeColor(ConfirmBtn, "AccentA")
        ConfirmBtn.AutoButtonColor = false
        ConfirmBtn.Text = opts.ConfirmText or "Confirm"
        applyThemeColor(ConfirmBtn, "Text", "TextColor3")
        ConfirmBtn.FontFace = UI_Font("Bold")
        ConfirmBtn.TextSize = 13
        ConfirmBtn.ZIndex = 52
        ConfirmBtn.Parent = Box
        corner(ConfirmBtn, 9)
        applyPressAnimation(ConfirmBtn, 0.95)

        TweenService:Create(Overlay, TI.d02_Sine_Out, {BackgroundTransparency = 1}):Play()

        local function close(result)
            TweenService:Create(Overlay, TI.d015_Sine_Out, {BackgroundTransparency = 1}):Play()
            task.delay(0.15, function() if Overlay then Overlay:Destroy() end end)
            if opts.Callback then opts.Callback(result) end
        end
        ConfirmBtn.MouseButton1Click:Connect(function() close(true) end)
        CancelBtn.MouseButton1Click:Connect(function() close(false) end)
        return newElement(Overlay, nil, nil, function() close(false) end)
    end

