        -- ============ v7: WRAPPER — ทำให้ทุก element รับ config แบบ WindUI + Desc/Locked/Localization/ขอบบาง ============
        local DESC_OK = {CreateButton = true, CreateToggle = true, CreateCheckbox = true, CreateSlider = true,
            CreateDropdown = true, CreateColorPicker = true, CreateKeybind = true}
        local OUTLINE_OK = {CreateButton = true, CreateToggle = true, CreateCheckbox = true, CreateSlider = true,
            CreateColorPicker = true, CreateKeybind = true, CreateInput = true, CreateParagraph = true, CreateAccordion = true}
        local LIST_ELEMENTS = {CreateDropdown = true, CreateMultiDropdown = true, CreateRadioGroup = true, CreateSegmentedControl = true}

        -- ใส่บรรทัดคำอธิบาย (Desc) ใต้ชื่อ element แถวเดียว: ขยายความสูง + เลื่อนของเดิมขึ้น
        local function attachDesc(cname, elem, root, text)
            local existing = elem._descLabel
            if existing and existing.Parent then
                existing.Text = text
                existing.Visible = text ~= ""
                return
            end
            if text == "" then return end
            local isSlider = cname == "CreateSlider"
            local extra = isSlider and 16 or 12
            local baseH = root.Size.Y.Offset
            local textX = 12
            for _, ch in ipairs(root:GetChildren()) do
                if ch:IsA("TextLabel") then textX = ch.Position.X.Offset break end
            end
            for _, ch in ipairs(root:GetChildren()) do
                if ch:IsA("GuiObject") and ch.Name ~= "__RippleHolder" and ch.Name ~= "__Lock" then
                    local sz, ps = ch.Size, ch.Position
                    if sz.Y.Scale == 1 then
                        ch.Size = UDim2.new(sz.X.Scale, sz.X.Offset, 1, sz.Y.Offset - extra)
                    end
                    if ps.Y.Scale > 0 then
                        ch.Position = UDim2.new(ps.X.Scale, ps.X.Offset, ps.Y.Scale, ps.Y.Offset - math.floor(extra * ps.Y.Scale))
                    end
                end
            end
            root.Size = UDim2.new(root.Size.X.Scale, root.Size.X.Offset, 0, baseH + extra)
            local Lbl = Instance.new("TextLabel")
            Lbl.Name = "__DescLabel"
            Lbl.Position = UDim2.new(0, textX, 0, isSlider and (baseH + 1) or (baseH - 8))
            Lbl.Size = UDim2.new(1, -(textX + 12), 0, 14)
            Lbl.BackgroundTransparency = 1
            Lbl.Text = text
            applyThemeColor(Lbl, "SubText", "TextColor3")
            Lbl.FontFace = UI_Font("Medium")
            Lbl.TextSize = 11.5
            Lbl.TextTruncate = Enum.TextTruncate.AtEnd
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.Parent = root
            elem._descLabel = Lbl
        end

        -- คืน (cfg, ชื่อ creator ที่ต้องส่งต่อ) — แปลง key แบบ WindUI เป็น key ของ SpectreUI
        local function normalizeConfig(cname, c)
            if type(c) ~= "table" then
                if type(c) == "string" then c = {Text = c} else c = {} end
            end
            if cname ~= "CreateAccordion" then
                if c.Text == nil then c.Text = c.Title or c.Name or c.Label end
            else
                if c.Title ~= nil then c.Title = Library:Translate(c.Title) end
                if c.Content ~= nil then c.Content = Library:Translate(c.Content) end
                if c.Content == nil and (c.Desc or c.Text) then c.Content = Library:Translate(c.Desc or c.Text) end
            end
            if c.Text ~= nil then c.Text = Library:Translate(c.Text) end
            if c.Tooltip == nil and c.Hint ~= nil then c.Tooltip = c.Hint end
            if c.Callback == nil and c.OnChange ~= nil then c.Callback = c.OnChange end

            if cname == "CreateSlider" then
                local v = c.Value
                if type(v) == "table" then
                    if c.Min == nil then c.Min = v.Min end
                    if c.Max == nil then c.Max = v.Max end
                    if c.Default == nil then c.Default = v.Default end
                elseif type(v) == "number" and c.Default == nil then
                    c.Default = v
                end
            elseif c.Default == nil and c.Value ~= nil then
                c.Default = c.Value
            end

            if LIST_ELEMENTS[cname] then
                if c.Options == nil and c.Values ~= nil then c.Options = c.Values end
                if type(c.Options) == "table" then
                    local conv, changed = {}, false
                    for i, v in ipairs(c.Options) do
                        if type(v) == "table" then
                            conv[i] = tostring(Library:Translate(v.Title or v.Name or v.Text or i))
                            changed = true
                        else
                            conv[i] = v
                        end
                    end
                    if changed then c.Options = conv end
                end
            end

            if cname == "CreateInput" then
                if c.Placeholder ~= nil then c.Text = Library:Translate(c.Placeholder) end
                local t = c.Type
                if type(t) == "string" and string.lower(t) == "textarea" then return c, "CreateTextArea" end
            elseif cname == "CreateDropdown" and c.Multi == true then
                return c, "CreateMultiDropdown"
            elseif cname == "CreateToggle" then
                local t = c.Type
                if type(t) == "string" and string.lower(t) == "checkbox" then return c, "CreateCheckbox" end
            elseif cname == "CreateKeybind" then
                if type(c.Default) == "string" then
                    local okk, kc = pcall(function() return Enum.KeyCode[c.Default] end)
                    c.Default = okk and kc or nil
                end
            end
            return c, nil
        end

        local function decorate(cname, elem, c, rawText, rawDesc)
            if type(elem) ~= "table" or elem.Instance == nil or elem._decorated then return elem end
            elem._decorated = true
            elem._cfg = c
            elem.ElementType = string.sub(cname, 7)
            local root = elem.Instance

            if OUTLINE_OK[cname] and root:IsA("GuiObject") and root.BackgroundTransparency < 0.5 then
                local hasBase = false
                for _, ch in ipairs(root:GetChildren()) do
                    if ch:IsA("UIStroke") and ch:GetAttribute("ThemeKey") == "Stroke" then hasBase = true break end
                end
                if not hasBase then
                    local st = stroke(root, "Stroke", 1)
                    st.Transparency = 0.75
                end
            end

            if DESC_OK[cname] then
                elem._descHook = function(text) attachDesc(cname, elem, root, tostring(text)) end
                if rawDesc ~= nil then elem._descHook(tostring(Library:Translate(rawDesc))) end
            end

            if c.Locked then elem:Lock(c.LockedTitle or c.LockedText) end

            if Library:IsLocalizedKey(rawText) then
                Library:BindLocalized(function() return root.Parent ~= nil end, function()
                    elem:SetTitle(Library:Translate(rawText))
                end)
            end
            if Library:IsLocalizedKey(rawDesc) then
                Library:BindLocalized(function() return root.Parent ~= nil end, function()
                    elem:SetDesc(Library:Translate(rawDesc))
                end)
            end
            return elem
        end

        local function wrapCreator(cname)
            local orig = Tab[cname]
            if type(orig) ~= "function" then return end
            Tab[cname] = function(self, c)
                local rawText, rawDesc
                if type(c) == "table" then
                    rawText = c.Text or c.Title or c.Name or c.Label
                    rawDesc = c.Desc or c.Description
                elseif type(c) == "string" then
                    rawText = c
                end
                local cfg, route = normalizeConfig(cname, c)
                if route then return Tab[route](Tab, cfg) end
                local elem = orig(self, cfg)
                if cname == "CreateParagraph" or cname == "CreateAccordion" or cname == "CreateCode" then rawText, rawDesc = nil, nil end
                return decorate(cname, elem, cfg, rawText, rawDesc)
            end
        end
        for _, cname in ipairs({"CreateButton", "CreateToggle", "CreateCheckbox", "CreateSlider", "CreateDropdown", "CreateColorPicker",
            "CreateInput", "CreateKeybind", "CreateLabel", "CreateTextArea", "CreateErrorLog", "CreateProgressBar", "CreateGraph",
            "CreateRadioGroup", "CreateMultiDropdown", "CreateSearchBox", "CreateImage", "CreateSegmentedControl", "CreateAccordion",
            "CreateParagraph", "CreateCode"}) do
            wrapCreator(cname)
        end
        -- alias แบบ WindUI: Tab:Button / Tab:Toggle / Tab:Slider / Tab:Section / Tab:Code / Tab:Group ...
        for _, cname in ipairs(CREATOR_NAMES) do
            Tab[string.sub(cname, 7)] = function(_, cfg) return Tab[cname](Tab, cfg) end
        end
        Tab.Colorpicker = Tab.ColorPicker
        Tab.Segmented = Tab.SegmentedControl
        Tab.Radio = Tab.RadioGroup
        Tab.Progress = Tab.ProgressBar

        Tab.Btn = TabBtn
        table.insert(windowTabList, Tab)
        table.insert(Tabs, {Btn = TabBtn, Content = TabContent, SetActive = setActive, BasePos = ContentBasePos, Scale = ContentScale})
        if #Tabs == 1 then
            setActive(true)
            slideIndicatorTo(TabBtn, true) -- true = จัดตำแหน่งทันทีไม่ต้องไถล (แท็บแรกตอนเปิด UI)
            TabContent.Visible = true
            CurrentTab = {Btn = TabBtn, Content = TabContent, SetActive = setActive}
        end

        return Tab
    end

    -- ============ Draggable ============
    local dragging, dragStart, startPos, activeTouch = false, nil, nil, nil
    local dragChangedConn, dragEndedConn = nil, nil

    -- กันหน้าต่างลากหลุดจอจริง (มือถือ/PC path เดียวกัน)
    -- Shadow มี AnchorPoint 0.5,0.5 → Position = จุดกึ่งกลาง Shadow ทั้งก้อน (รวม glow 30px รอบนอก)
    -- ใช้ Shadow.AbsoluteSize แทน MainFrame เพื่อนับ glow ด้วย ไม่งั้น edge ยัง overflow ได้ 30px
    -- return pure Offset เสมอ กัน Scale=0.5 ค้างใน startPos ทำให้ mixed Scale/Offset ในรอบถัดไป
    local SCREEN_PADDING = 6   -- ระยะห่างขอบจอจริงขั้นต่ำ (px) กัน window ชิดขอบสนิท
    local function clampWindowCenter(pos)
        local screenSize = ScreenGui.AbsoluteSize
        -- resolve Scale+Offset → pixel absolute (Shadow อาจยังมี Scale=0.5 ตอน init)
        local centerX = pos.X.Scale * screenSize.X + pos.X.Offset
        local centerY = pos.Y.Scale * screenSize.Y + pos.Y.Offset
        -- ใช้ Shadow (ใหญ่กว่า MainFrame 30px ต่อด้าน) เพื่อกัน glow ไม่ให้ทะลุด้วย
        local halfW = Shadow.AbsoluteSize.X / 2
        local halfH = Shadow.AbsoluteSize.Y / 2
        if screenSize.X > 0 and halfW > 0 then
            centerX = math.clamp(centerX, halfW + SCREEN_PADDING, math.max(halfW + SCREEN_PADDING, screenSize.X - halfW - SCREEN_PADDING))
        end
        if screenSize.Y > 0 and halfH > 0 then
            centerY = math.clamp(centerY, halfH + SCREEN_PADDING, math.max(halfH + SCREEN_PADDING, screenSize.Y - halfH - SCREEN_PADDING))
        end
        return UDim2.new(0, centerX, 0, centerY)   -- pure Offset เสมอ ไม่มี Scale ปน
    end

    -- Render-synced so a fast flick (which can fire many InputChanged events per
    -- rendered frame) only ever applies its latest position once per frame,
    -- instead of writing Shadow.Position (and re-triggering layout) on every event.
    local dragPush, dragRSStart, dragRSStop = createRenderSyncedDrag(function(newPos)
        Shadow.Position = clampWindowCenter(newPos)
    end)

    local function stopWindowDrag(input)
        dragging = false
        if input and input == activeTouch then activeTouch = nil end
        if dragChangedConn then dragChangedConn:Disconnect(); dragChangedConn = nil end
        if dragEndedConn then dragEndedConn:Disconnect(); dragEndedConn = nil end
        dragRSStop()
    end

    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            -- HideBtn อยู่ใน TopBar เหมือน CloseBtn: Roblox ยิง InputBegan ให้ทั้ง Frame แม่และปุ่มลูกพร้อมกัน
            -- ถ้าเช็คแค่ CloseBtn จุดเดียว การแตะปุ่ม Hide จะลาก window ไปด้วยพร้อมๆ กับสั่งซ่อน (ค้าง connection/สั่น)
            if isPointOverGui(input.Position, CloseBtn) or isPointOverGui(input.Position, HideBtn) or topbarButtonHit(input.Position) then return end
            -- กัน connection ค้างจากรอบลากก่อนหน้าที่ InputEnded ไม่ยิง (เช่น touch โดนขัดจังหวะกลางทางบนมือถือ
            -- - แจ้งเตือนดึงลงมา, สลับแอป, สาย โทรเข้า) ไม่งั้นหน้าต่างจะเกาะตามนิ้ว/เมาส์ครั้งถัดไปค้างตลอดไป
            stopWindowDrag()
            dragging = true
            dragStart = input.Position
            -- normalize Shadow.Position → pure pixel Offset ก่อน เพราะ Shadow เริ่มที่ Scale=0.5,Offset=0
            -- ถ้าดึง startPos มาตรงๆ แล้ว delta บวกแค่ฝั่ง Offset → clampWindowCenter resolve เป็น
            -- 0.5*screenW + delta แทนที่จะเป็น currentCenter + delta → หน้าต่างกระโดดออกนอกจอ
            do
                local _ss = ScreenGui.AbsoluteSize
                startPos = UDim2.new(
                    0, Shadow.Position.X.Scale * _ss.X + Shadow.Position.X.Offset,
                    0, Shadow.Position.Y.Scale * _ss.Y + Shadow.Position.Y.Offset
                )
            end
            if input.UserInputType == Enum.UserInputType.Touch then activeTouch = input end
            dragRSStart()

            dragChangedConn = UserInputService.InputChanged:Connect(function(input2)
                if dragging and (input2.UserInputType == Enum.UserInputType.MouseMovement or input2.UserInputType == Enum.UserInputType.Touch) then
                    if input2.UserInputType == Enum.UserInputType.MouseMovement or input2 == activeTouch then
                        local delta = input2.Position - dragStart
                        dragPush(UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y))
                    end
                end
            end)
            dragEndedConn = UserInputService.InputEnded:Connect(function(input2)
                if input2.UserInputType == Enum.UserInputType.MouseButton1 or input2.UserInputType == Enum.UserInputType.Touch then
                    stopWindowDrag(input2)
                end
            end)
        end
    end)

    -- ============ Resizable ============
    local MIN_SIZE, MAX_SIZE = Vector2.new(380, 340), Vector2.new(1100, 780)
    local resizeStart, startSize, resizeTouch = nil, nil, nil
    local resizeChangedConn, resizeEndedConn = nil, nil

    -- Same render-sync treatment as window drag: MainFrame.Size drives every
    -- descendant's layout recompute, so coalescing to one write per frame
    -- avoids re-running that layout pass multiple times per frame while resizing.
    local resizePush, resizeRSStart, resizeRSStop = createRenderSyncedDrag(function(newSize)
        MainFrame.Size = newSize
        Shadow.Position = clampWindowCenter(Shadow.Position)  -- โต ณ ใกล้ขอบจอ ก็ไม่ทะลุจอ
    end)

    local function stopResize(input)
        if resizing then
            resizing = false
            TweenService:Create(ResizeBg, TI.d015_Sine_Out, {BackgroundTransparency = 1}):Play()
            TweenService:Create(ResizeIcon, TI.d015_Sine_Out, {ImageTransparency = 0.55, ImageColor3 = Theme.SubText}):Play()
            TweenService:Create(ResizeIconScale, TI.d015_Sine_Out, {Scale = 1}):Play()
        end
        if input and input == resizeTouch then resizeTouch = nil end
        if resizeChangedConn then resizeChangedConn:Disconnect(); resizeChangedConn = nil end
        if resizeEndedConn then resizeEndedConn:Disconnect(); resizeEndedConn = nil end
        resizeRSStop()
    end

    ResizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            stopResize() -- กัน connection ค้างถ้ารอบก่อน InputEnded ไม่ยิง (touch โดนขัดจังหวะ)
            resizing = true
            resizeStart = input.Position
            startSize = MainFrame.Size
            if input.UserInputType == Enum.UserInputType.Touch then resizeTouch = input end
            resizeRSStart()

            resizeChangedConn = UserInputService.InputChanged:Connect(function(input2)
                if resizing and (input2.UserInputType == Enum.UserInputType.MouseMovement or input2.UserInputType == Enum.UserInputType.Touch) then
                    if input2.UserInputType == Enum.UserInputType.MouseMovement or input2 == resizeTouch then
                        -- WindowScale.Scale (รวม ResponsiveScale บนมือถือ) ย่อการ render จริงบนจอ
                        -- แต่ input2.Position เป็นพิกัดจอจริง (unscaled) → ต้องหาร scale ก่อนบวกเข้า
                        -- Size เดิม ไม่งั้นกรอบ resize จะ "ตามนิ้ว/เมาส์ไม่ทัน" ลากเท่าไหร่ก็โตช้ากว่าที่ลาก
                        local scale = WindowScale.Scale
                        if scale <= 0 then scale = 1 end
                        local delta = (input2.Position - resizeStart) / scale
                        local newW = math.clamp(startSize.X.Offset + delta.X, MIN_SIZE.X, MAX_SIZE.X)
                        local newH = math.clamp(startSize.Y.Offset + delta.Y, MIN_SIZE.Y, MAX_SIZE.Y)
                        resizePush(UDim2.new(0, newW, 0, newH))
                    end
                end
            end)
            resizeEndedConn = UserInputService.InputEnded:Connect(function(input2)
                if input2.UserInputType == Enum.UserInputType.MouseButton1 or input2.UserInputType == Enum.UserInputType.Touch then
                    stopResize(input2)
                end
            end)
        end
    end)

    -- ============ v7: WINDOW API (เทียบเท่า WindUI) ============
    table.insert(Library._Guis, ScreenGui)
    table.insert(Library._Guis, NotifyGui)
    table.insert(Library._Guis, TooltipGui)
    table.insert(Library._Guis, RestoreGui)

    local visibleCallbacks = {open = {}, close = {}}
    local windowShown = true
    local acrylicEnabled = false
    local blurEffect = nil
    local uiTransparency = 0
    local BgImage = nil
    local openButtonHidden = false
    local searchHidden = false
    local userPanel = nil
    local syncBlur, applyUiTransparency, updateSidebarLayout
    Window.VisibilityChanged = Instance.new("BindableEvent")

    if Library:IsLocalizedKey(rawWindowTitle) then
        Library:BindLocalized(function() return TitleLabel.Parent ~= nil end, function()
            TitleLabel.Text = tostring(Library:Translate(rawWindowTitle))
        end)
    end

    applyUiTransparency = function()
        local barT = uiTransparency
        if BgImage then barT = math.max(uiTransparency, 0.4) end
        MainFrame.BackgroundTransparency = uiTransparency
        TopBar.BackgroundTransparency = barT
        topBarFix.BackgroundTransparency = barT
        TabContainer.BackgroundTransparency = barT
    end

    syncBlur = function()
        if not acrylicEnabled then
            if blurEffect and blurEffect.Parent then TweenService:Create(blurEffect, TI.d028_Sine_Out, {Size = 0}):Play() end
            return
        end
        if not blurEffect or not blurEffect.Parent then
            local okb, eff = pcall(function()
                local e = Instance.new("BlurEffect")
                e.Name = "SpectreUI_Blur"
                e.Size = 0
                e.Parent = game:GetService("Lighting")
                return e
            end)
            if not okb then return end
            blurEffect = eff
        end
        TweenService:Create(blurEffect, TI.d028_Sine_Out, {Size = windowShown and 18 or 0}):Play()
    end

    do
        local baseSetVisible = setUiVisible
        setUiVisible = function(visible)
            visible = visible and true or false
            baseSetVisible(visible)
            if visible == windowShown then return end
            windowShown = visible
            syncBlur()
            if visible then
                task.delay(0.32, function() if windowShown then applyUiTransparency() end end)
                for _, cb in ipairs(visibleCallbacks.open) do safeCallback(cb) end
            else
                if openButtonHidden then
                    task.delay(0.28, function()
                        if not windowShown and openButtonHidden then
                            RestoreBtn.Visible = false
                            FpsPill.Visible = false
                        end
                    end)
                end
                for _, cb in ipairs(visibleCallbacks.close) do safeCallback(cb) end
            end
            Window.VisibilityChanged:Fire(visible)
        end
    end

    function Window:IsVisible() return windowShown end
    function Window:Open() setUiVisible(true) end
    function Window:Close() setUiVisible(false) end
    function Window:OnOpen(cb) if type(cb) == "function" then table.insert(visibleCallbacks.open, cb) end return Window end
    function Window:OnClose(cb) if type(cb) == "function" then table.insert(visibleCallbacks.close, cb) end return Window end
    function Window:OnDestroy(cb) Window:BindToClose(cb) return Window end

    function Window:SetToggleKey(key)
        if type(key) == "string" then
            local okk, kc = pcall(function() return Enum.KeyCode[key] end)
            key = okk and kc or nil
        end
        config.ToggleKeybind = key
        return Window
    end
    function Window:GetToggleKey() return config.ToggleKeybind end

    -- ---------- appearance ----------
    function Window:SetTransparency(alpha)
        uiTransparency = math.clamp(tonumber(alpha) or 0, 0, 0.9)
        if windowShown then applyUiTransparency() end
        return Window
    end
    function Window:GetTransparency() return uiTransparency end

    function Window:SetAcrylic(state)
        acrylicEnabled = state and true or false
        syncBlur()
        return Window
    end
    function Window:IsAcrylic() return acrylicEnabled end

    function Window:SetBackgroundImage(asset, transparency)
        if asset == nil or asset == "" then
            if BgImage then BgImage:Destroy() BgImage = nil end
            if windowShown then applyUiTransparency() end
            return Window
        end
        if not BgImage then
            BgImage = Instance.new("ImageLabel")
            BgImage.Name = "BackgroundImage"
            BgImage.Size = UDim2.new(1, 0, 1, 0)
            BgImage.BackgroundTransparency = 1
            BgImage.ScaleType = Enum.ScaleType.Crop
            BgImage.ImageTransparency = 0.6
            BgImage.ZIndex = 0
            BgImage.Parent = MainContent
            corner(BgImage, 14)
        end
        BgImage.Image = normalizeAssetId(asset)
        if transparency ~= nil then BgImage.ImageTransparency = math.clamp(transparency, 0, 1) end
        if windowShown then applyUiTransparency() end
        return Window
    end
    function Window:SetBackgroundImageTransparency(t)
        if BgImage then BgImage.ImageTransparency = math.clamp(tonumber(t) or 0.6, 0, 1) end
        return Window
    end

    function Window:SetUIScale(s)
        UserScale = math.clamp(tonumber(s) or 1, 0.5, 1.75)
        ResponsiveScale = computeResponsiveScale()
        if ScreenGui.Enabled then TweenService:Create(WindowScale, TI.d02_Sine_Out, {Scale = ResponsiveScale}):Play() end
        return Window
    end
    function Window:GetUIScale() return UserScale end

    function Window:SetSize(size, animate)
        if typeof(size) ~= "UDim2" then return Window end
        local w = math.clamp(size.X.Offset, MIN_SIZE.X, MAX_SIZE.X)
        local h = math.clamp(size.Y.Offset, MIN_SIZE.Y, MAX_SIZE.Y)
        local target = UDim2.new(0, w, 0, h)
        if animate == false then MainFrame.Size = target else TweenService:Create(MainFrame, TI.d028_Sine_Out, {Size = target}):Play() end
        return Window
    end
    function Window:GetSize() return Vector2.new(MainFrame.Size.X.Offset, MainFrame.Size.Y.Offset) end
    function Window:SetMinSize(v) if typeof(v) == "Vector2" then MIN_SIZE = v end return Window end
    function Window:SetMaxSize(v) if typeof(v) == "Vector2" then MAX_SIZE = v end return Window end
    function Window:Center()
        TweenService:Create(Shadow, TI.d028_Sine_Out, {Position = UDim2.new(0, ScreenGui.AbsoluteSize.X / 2, 0, ScreenGui.AbsoluteSize.Y / 2)}):Play()
        return Window
    end

    local fullscreenState = nil
    function Window:ToggleFullscreen()
        local sc = WindowScale.Scale
        if sc <= 0 then sc = 1 end
        if fullscreenState then
            TweenService:Create(MainFrame, TI.d028_Sine_Out, {Size = fullscreenState.size}):Play()
            TweenService:Create(Shadow, TI.d028_Sine_Out, {Position = fullscreenState.pos}):Play()
            fullscreenState = nil
        else
            local ss = ScreenGui.AbsoluteSize
            fullscreenState = {size = MainFrame.Size, pos = Shadow.Position}
            TweenService:Create(MainFrame, TI.d028_Sine_Out, {Size = UDim2.new(0, (ss.X - 24) / sc, 0, (ss.Y - 24) / sc)}):Play()
            TweenService:Create(Shadow, TI.d028_Sine_Out, {Position = UDim2.new(0, ss.X / 2, 0, ss.Y / 2)}):Play()
        end
        return Window
    end
    function Window:IsFullscreen() return fullscreenState ~= nil end

    -- ---------- open button ----------
    function Window:EditOpenButton(cfg)
        cfg = type(cfg) == "table" and cfg or {}
        if cfg.Icon ~= nil then Window:SetIcon(cfg.Icon) end
        local letter = RestoreBtn:FindFirstChild("LetterLabel")
        if cfg.Text and letter then letter.Text = tostring(cfg.Text) end
        if cfg.CornerRadius then
            local cr = RestoreBtn:FindFirstChildOfClass("UICorner")
            if cr then cr.CornerRadius = UDim.new(0, cfg.CornerRadius) end
        end
        if cfg.Color ~= nil then
            local g = RestoreBtn:FindFirstChildOfClass("UIGradient")
            if g then
                g:SetAttribute("IsAccent", nil)
                if typeof(cfg.Color) == "Color3" then g.Color = ColorSequence.new(cfg.Color)
                elseif typeof(cfg.Color) == "ColorSequence" then g.Color = cfg.Color end
            end
        end
        if cfg.Enabled ~= nil then Window:SetOpenButtonVisible(cfg.Enabled) end
        return Window
    end
    function Window:SetOpenButtonVisible(state)
        openButtonHidden = not state
        if openButtonHidden and not windowShown then
            RestoreBtn.Visible = false
            FpsPill.Visible = false
        elseif not openButtonHidden and not windowShown then
            RestoreBtn.Visible = true
            FpsPill.Visible = true
        end
        return Window
    end

    -- ---------- topbar: tags + extra buttons ----------
    local TagHolder = nil
    function Window:Tag(cfg)
        if type(cfg) ~= "table" then cfg = {Title = tostring(cfg)} end
        if not TagHolder then
            TagHolder = Instance.new("Frame")
            TagHolder.Name = "Tags"
            TagHolder.BackgroundTransparency = 1
            TagHolder.Size = UDim2.new(0, 0, 0, 16)
            TagHolder.AutomaticSize = Enum.AutomaticSize.X
            TagHolder.ZIndex = 4
            TagHolder.Parent = TopBar
            local tl = Instance.new("UIListLayout")
            tl.FillDirection = Enum.FillDirection.Horizontal
            tl.Padding = UDim.new(0, 4)
            tl.VerticalAlignment = Enum.VerticalAlignment.Center
            tl.SortOrder = Enum.SortOrder.LayoutOrder
            tl.Parent = TagHolder
            local function place()
                TagHolder.Position = UDim2.new(0, 30 + TitleLabel.TextBounds.X + 8, 0, config.SubTitle and 9 or math.floor((topBarH - 16) / 2))
            end
            TitleLabel:GetPropertyChangedSignal("TextBounds"):Connect(place)
            place()
        end
        local color = typeof(cfg.Color) == "Color3" and cfg.Color or Theme.AccentA
        local Chip = Instance.new("Frame")
        Chip.Size = UDim2.new(0, 0, 1, 0)
        Chip.AutomaticSize = Enum.AutomaticSize.X
        Chip.BackgroundColor3 = color
        Chip.BackgroundTransparency = 0.82
        Chip.LayoutOrder = #TagHolder:GetChildren()
        Chip.Parent = TagHolder
        corner(Chip, 8)
        local chipStroke = Instance.new("UIStroke")
        chipStroke.Color = color
        chipStroke.Transparency = 0.55
        chipStroke.Thickness = 1
        pcall(function() chipStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border end)
        chipStroke.Parent = Chip
        local cPad = Instance.new("UIPadding")
        cPad.PaddingLeft = UDim.new(0, 7)
        cPad.PaddingRight = UDim.new(0, 7)
        cPad.Parent = Chip
        local Lbl = Instance.new("TextLabel")
        Lbl.Size = UDim2.new(0, 0, 1, 0)
        Lbl.AutomaticSize = Enum.AutomaticSize.X
        Lbl.BackgroundTransparency = 1
        Lbl.Text = tostring(Library:Translate(cfg.Title or cfg.Text or "Tag"))
        Lbl.TextColor3 = color
        Lbl.FontFace = UI_Font("Bold")
        Lbl.TextSize = 10.5
        Lbl.Parent = Chip
        local tag = {Instance = Chip}
        function tag:SetTitle(t) Lbl.Text = tostring(t) return tag end
        function tag:SetColor(col) Lbl.TextColor3 = col Chip.BackgroundColor3 = col chipStroke.Color = col return tag end
        function tag:Destroy() Chip:Destroy() end
        return tag
    end

    local function relayoutTopbar()
        local reserve = 96 + 36 * #topbarButtons
        TitleLabel.Size = UDim2.new(1, -reserve, TitleLabel.Size.Y.Scale, TitleLabel.Size.Y.Offset)
        if SubTitleLabel then SubTitleLabel.Size = UDim2.new(1, -reserve, 0, 14) end
        for i, b in ipairs(topbarButtons) do
            b.Btn.Position = UDim2.new(1, -(46 + 36 * i), 0.5, 0)
        end
    end
    function Window:CreateTopbarButton(cfg)
        if type(cfg) ~= "table" then cfg = {Text = tostring(cfg)} end
        local Btn = Instance.new("TextButton")
        Btn.Name = "TopbarButton"
        Btn.Size = UDim2.new(0, 26, 0, 26)
        Btn.AnchorPoint = Vector2.new(1, 0.5)
        applyThemeColor(Btn, "ElementHover")
        Btn.BackgroundTransparency = 1
        Btn.AutoButtonColor = false
        Btn.Text = ""
        Btn.ZIndex = 5
        Btn.Parent = TopBar
        corner(Btn, 8)
        applyPressAnimation(Btn, 0.85)
        local Icon = Instance.new("ImageLabel")
        Icon.AnchorPoint = Vector2.new(0.5, 0.5)
        Icon.Position = UDim2.new(0.5, 0, 0.5, 0)
        Icon.Size = UDim2.new(0, 16, 0, 16)
        Icon.BackgroundTransparency = 1
        applyThemeColor(Icon, "SubText", "ImageColor3")
        Icon.ScaleType = Enum.ScaleType.Fit
        Icon.ZIndex = 6
        Icon.Parent = Btn
        local Glyph = Instance.new("TextLabel")
        Glyph.Size = UDim2.new(1, 0, 1, 0)
        Glyph.BackgroundTransparency = 1
        applyThemeColor(Glyph, "SubText", "TextColor3")
        Glyph.FontFace = UI_Font("Bold")
        Glyph.TextSize = 14
        Glyph.ZIndex = 6
        Glyph.Parent = Btn
        local function setContent(icon, text)
            if icon ~= nil and icon ~= "" then
                Icon.Image = Library.Icons[icon] or normalizeAssetId(icon)
                Icon.Visible = true
                Glyph.Visible = false
            else
                Icon.Visible = false
                Glyph.Text = text and tostring(text) or "•"
                Glyph.Visible = true
            end
        end
        setContent(cfg.Icon, cfg.Text)
        Btn.MouseEnter:Connect(function() TweenService:Create(Btn, TI.d015_Sine_Out, {BackgroundTransparency = 0.3}):Play() end)
        Btn.MouseLeave:Connect(function() TweenService:Create(Btn, TI.d015_Sine_Out, {BackgroundTransparency = 1}):Play() end)
        Btn.MouseButton1Click:Connect(function() safeCallback(cfg.Callback) end)
        if cfg.Tooltip then Library:AttachTooltip(Btn, cfg.Tooltip) end
        local obj = {Btn = Btn, Instance = Btn}
        function obj:SetIcon(icon) setContent(icon, nil) return obj end
        function obj:SetText(text) setContent(nil, text) return obj end
        function obj:SetVisible(v) Btn.Visible = v return obj end
        function obj:Destroy()
            for i, b in ipairs(topbarButtons) do if b == obj then table.remove(topbarButtons, i) break end end
            Btn:Destroy()
            relayoutTopbar()
        end
        table.insert(topbarButtons, obj)
        relayoutTopbar()
        return obj
    end

    -- ---------- sidebar: layout / user panel / dividers ----------
    updateSidebarLayout = function()
        local top = searchHidden and 6 or 40
        local bottom = userPanel and 62 or 6
        TabSearchWrap.Visible = not searchHidden
        TabList.Position = UDim2.new(0, 6, 0, top)
        TabList.Size = UDim2.new(1, -12, 1, -(top + bottom))
    end
    function Window:SetSearchBarVisible(state)
        searchHidden = not state
        updateSidebarLayout()
        return Window
    end

    function Window:CreateUserPanel(cfg)
        if userPanel then userPanel.Frame:Destroy() userPanel = nil end
        cfg = type(cfg) == "table" and cfg or {}
        local lp = game:GetService("Players").LocalPlayer
        local anonymous = cfg.Anonymous == true or lp == nil
        local Panel = Instance.new("TextButton")
        Panel.Name = "UserPanel"
        Panel.AnchorPoint = Vector2.new(0, 1)
        Panel.Position = UDim2.new(0, 6, 1, -6)
        Panel.Size = UDim2.new(1, -12, 0, 50)
        applyThemeColor(Panel, "Element")
        Panel.AutoButtonColor = false
        Panel.Text = ""
        Panel.Parent = TabContainer
        corner(Panel, 12)
        local ps = stroke(Panel, "Stroke", 1)
        ps.Transparency = 0.6
        applyHoverEffect(Panel, "Element", "ElementHover")
        applyPressAnimation(Panel, 0.97)
        local Avatar = Instance.new("ImageLabel")
        Avatar.Position = UDim2.new(0, 8, 0.5, -17)
        Avatar.Size = UDim2.new(0, 34, 0, 34)
        applyThemeColor(Avatar, "Background")
        Avatar.Parent = Panel
        corner(Avatar, 17)
        if anonymous then
            local Q = Instance.new("TextLabel")
            Q.Size = UDim2.new(1, 0, 1, 0)
            Q.BackgroundTransparency = 1
            Q.Text = "?"
            applyThemeColor(Q, "SubText", "TextColor3")
            Q.FontFace = UI_Font("Bold")
            Q.TextSize = 16
            Q.Parent = Avatar
        else
            Avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(lp.UserId) .. "&w=150&h=150"
        end
        local NameLbl = Instance.new("TextLabel")
        NameLbl.Position = UDim2.new(0, 48, 0, 9)
        NameLbl.Size = UDim2.new(1, -54, 0, 16)
        NameLbl.BackgroundTransparency = 1
        NameLbl.Text = anonymous and "Anonymous" or tostring(lp.DisplayName)
        applyThemeColor(NameLbl, "Text", "TextColor3")
        NameLbl.FontFace = UI_Font("Bold")
        NameLbl.TextSize = 12
        NameLbl.TextXAlignment = Enum.TextXAlignment.Left
        NameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        NameLbl.Parent = Panel
        local SubLbl = Instance.new("TextLabel")
        SubLbl.Position = UDim2.new(0, 48, 0, 26)
        SubLbl.Size = UDim2.new(1, -54, 0, 14)
        SubLbl.BackgroundTransparency = 1
        SubLbl.Text = anonymous and "Guest" or ("@" .. tostring(lp.Name))
        applyThemeColor(SubLbl, "SubText", "TextColor3")
        SubLbl.FontFace = UI_Font("Medium")
        SubLbl.TextSize = 10.5
        SubLbl.TextXAlignment = Enum.TextXAlignment.Left
        SubLbl.TextTruncate = Enum.TextTruncate.AtEnd
        SubLbl.Parent = Panel
        Panel.MouseButton1Click:Connect(function() safeCallback(cfg.Callback) end)
        userPanel = {Frame = Panel}
        function userPanel:SetName(t) NameLbl.Text = tostring(t) end
        function userPanel:SetSubText(t) SubLbl.Text = tostring(t) end
        updateSidebarLayout()
        return userPanel
    end

    function Window:CreateTabDivider(cfg)
        if type(cfg) == "string" then cfg = {Title = cfg} end
        cfg = type(cfg) == "table" and cfg or {}
        tabOrderCounter = tabOrderCounter + 1
        local title = cfg.Title and tostring(Library:Translate(cfg.Title)) or nil
        local Holder = Instance.new("Frame")
        Holder.Name = "TabDivider"
        Holder.Size = UDim2.new(1, 0, 0, title and 24 or 12)
        Holder.BackgroundTransparency = 1
        Holder.LayoutOrder = tabOrderCounter
        Holder.Parent = TabHolder
        if title then
            local Lbl = Instance.new("TextLabel")
            Lbl.Position = UDim2.new(0, 6, 0, 4)
            Lbl.Size = UDim2.new(1, -6, 1, -4)
            Lbl.BackgroundTransparency = 1
            Lbl.Text = string.upper(title)
            applyThemeColor(Lbl, "SubText", "TextColor3")
            Lbl.FontFace = UI_Font("Bold")
            Lbl.TextSize = 10
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.TextTruncate = Enum.TextTruncate.AtEnd
            Lbl.Parent = Holder
        else
            local Line = Instance.new("Frame")
            Line.Position = UDim2.new(0, 6, 0.5, 0)
            Line.Size = UDim2.new(1, -12, 0, 1)
            applyThemeColor(Line, "Stroke")
            Line.BackgroundTransparency = 0.3
            Line.BorderSizePixel = 0
            Line.Parent = Holder
        end
        return newElement(Holder)
    end
    Window.Divider = Window.CreateTabDivider

    -- Window:Section({Title="..."}) → หัวข้อกลุ่มแท็บ (สร้างแท็บต่อจากนี้ด้วย group:Tab{...})
    function Window:Section(cfg)
        local title = type(cfg) == "table" and (cfg.Title or cfg.Name) or cfg
        local group = {Header = Window:CreateTabDivider({Title = title})}
        function group:Tab(c, icon) return Window:CreateTab(c, icon) end
        group.CreateTab = group.Tab
        return group
    end

    -- ---------- tabs ----------
    function Window:Tab(cfg, icon) return Window:CreateTab(cfg, icon) end
    function Window:GetTabs()
        local copy = {}
        for i, t in ipairs(windowTabList) do copy[i] = t end
        return copy
    end
    function Window:GetTab(key)
        if type(key) == "number" then return windowTabList[key] end
        for _, t in ipairs(windowTabList) do
            if t == key or t.Name == key then return t end
        end
        return nil
    end
    function Window:GetCurrentTab()
        for _, t in ipairs(windowTabList) do
            if CurrentTab and CurrentTab.Btn == t.Btn then return t end
        end
        return nil
    end
    function Window:SelectTab(key)
        local t = Window:GetTab(key)
        if t and t.Select then t.Select() end
        return t
    end

    -- ---------- settings tab (ขยาย: ธีม/สเกล/โปร่งใส/เบลอ/ปุ่มเปิดปิด/ฟอนต์/ภาษา) ----------
    function Window:CreateSettingsTab(opts)
        opts = type(opts) == "table" and opts or {}
        local tab = Window:CreateTab(opts.Title or "Settings", opts.Icon or "settings")
        tab.Btn.LayoutOrder = 9999
        tab:CreateThemeDropdown()
        if opts.Extended ~= false then
            tab:CreateSection("Interface")
            tab:CreateSlider({Text = "UI Scale", Min = 50, Max = 175, Step = 5, Suffix = "%",
                Default = math.clamp(math.floor(UserScale * 100 + 0.5), 50, 175),
                Callback = function(v) Window:SetUIScale(v / 100) end})
            tab:CreateSlider({Text = "Transparency", Min = 0, Max = 60, Step = 5, Suffix = "%",
                Default = math.floor(uiTransparency * 100 + 0.5),
                Callback = function(v) Window:SetTransparency(v / 100) end})
            tab:CreateToggle({Text = "Acrylic Blur", Default = acrylicEnabled, Notify = false, Command = false,
                Callback = function(v) Window:SetAcrylic(v) end})
            tab:CreateKeybind({Text = "Toggle UI Key", Default = config.ToggleKeybind,
                Callback = function(k) Window:SetToggleKey(k) end})
            local fontNames = {}
            for fname in pairs(Library.FontPresets) do table.insert(fontNames, fname) end
            table.sort(fontNames)
            tab:CreateDropdown({Text = "Font", Options = fontNames, Default = Library.FontPresets[Library.CurrentFont] and Library.CurrentFont or "BuilderSans",
                Callback = function(v) Library:SetFont(v) end})
            local langs = Library:GetLanguages()
            if #langs > 1 then
                tab:CreateDropdown({Text = "Language", Options = langs, Default = Library:GetLanguage(),
                    Callback = function(v) Library:SetLanguage(v) end})
            end
        end
        return tab
    end

    -- ---------- destroy: เก็บ blur ด้วย ----------
    do
        local baseDestroy = Window.Destroy
        function Window:Destroy()
            if blurEffect then pcall(function() blurEffect:Destroy() end) blurEffect = nil end
            return baseDestroy(self)
        end
    end

    -- ---------- apply config options (WindUI-style) ----------
    if config.HideSearchBar == true then Window:SetSearchBarVisible(false) end
    if type(config.User) == "table" and config.User.Enabled ~= false then Window:CreateUserPanel(config.User)
    elseif config.User == true then Window:CreateUserPanel({}) end
    if config.Theme and Library.Themes[config.Theme] then Library:SetTheme(config.Theme) end
    if config.Transparent == true then Window:SetTransparency(0.18)
    elseif type(config.Transparent) == "number" then Window:SetTransparency(config.Transparent) end
    if config.Acrylic == true then Window:SetAcrylic(true) end
    if config.Fullscreen == true then
        Window:CreateTopbarButton({Text = "□", Tooltip = "Fullscreen", Callback = function() Window:ToggleFullscreen() end})
    end
    if config.BackgroundImage or config.Background then
        Window:SetBackgroundImage(config.BackgroundImage or config.Background, config.BackgroundImageTransparency)
    end
    if config.OpenButton == false then Window:SetOpenButtonVisible(false) end
    if config.UIScale then Window:SetUIScale(config.UIScale) end

    -- ============ GRAND ENTRANCE ============
    -- เอฟเฟกต์เด้งสปริง+เอียงสะบัด+fade ที่ setUiVisible(true) ทำไว้แล้ว (เดิมใช้แค่ตอน Restore จากการซ่อน)
    -- เรียกครั้งเดียวตอนสร้างหน้าต่างเสร็จ ให้ UI เด้งเข้ามาสวยๆ ตั้งแต่เปิดสคริปต์ครั้งแรกด้วย
    setUiVisible(true)

    return Window
end

return Library