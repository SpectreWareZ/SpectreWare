        function Tab:CreateToggle(c)
            c = type(c) == "table" and c or {}
            local state = c.Default or false
            bindFlag(c.Flag, state)

            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, 0, 0, 40)
            applyThemeColor(Frame, "Element")
            Frame.Active = true
            Frame.Parent = TabContent
            corner(Frame, 9)
            applyGlowOnHover(Frame)

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -60, 1, 0)
            Label.Position = UDim2.new(0, 12, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = c.Text or "Toggle"
            applyThemeColor(Label, "Text", "TextColor3")
            Label.FontFace = UI_Font("SemiBold")
            Label.TextSize = 14
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Frame

            local Switch = Instance.new("TextButton")
            Switch.Size = UDim2.new(0, 40, 0, 20)
            Switch.Position = UDim2.new(1, -52, 0.5, -10)
            applyThemeColor(Switch, state and "AccentA" or "ToggleOff")
            Switch.AutoButtonColor = false
            Switch.Text = ""
            Switch.Parent = Frame
            corner(Switch, 10)
            applyPressAnimation(Switch, 0.85)
            ripple(Switch, "AccentA")
            local switchGrad = accentGradient(Switch, 0)
            switchGrad.Transparency = NumberSequence.new(1)

            local switchGradProxy = Instance.new("NumberValue")
            switchGradProxy.Value = 1
            switchGradProxy:GetPropertyChangedSignal("Value"):Connect(function()
                switchGrad.Transparency = NumberSequence.new(switchGradProxy.Value)
            end)

            local Circle = Instance.new("Frame")
            Circle.Size = UDim2.new(0, 16, 0, 16)
            Circle.Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Circle.Parent = Switch
            corner(Circle, 8)

            local function applyState(newState, fireCallback)
                state = newState
                bindFlag(c.Flag, state)
                Switch:SetAttribute("ThemeKey", state and "AccentA" or "ToggleOff")
                Switch:SetAttribute("ThemeBinds", "BackgroundColor3=" .. (state and "AccentA" or "ToggleOff"))
                TweenService:Create(Switch, TI.d015_Sine_Out, {BackgroundColor3 = state and Theme.AccentA or Theme.ToggleOff}):Play()
                TweenService:Create(switchGradProxy, TI.d015_Sine_Out, {Value = state and 0 or 1}):Play()
                -- ลูกบิดยืด-หด (squash & stretch) ก่อนเด้งไปตำแหน่งใหม่แบบสปริง ให้ความรู้สึก "หนึบ" ขึ้น
                local targetPos = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                TweenService:Create(Circle, TweenInfo.new(0.09, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = UDim2.new(0, 21, 0, 15)}):Play()
                TweenService:Create(Circle, TI.d028_Back_Out_Wobble, {Position = targetPos}):Play()
                task.delay(0.09, function()
                    if Circle.Parent then
                        TweenService:Create(Circle, TI.d028_Back_Out_Wobble, {Size = UDim2.new(0, 16, 0, 16)}):Play()
                    end
                end)
                if state then
                    pulseRing(Switch, "AccentA", 10)
                end
                if fireCallback then
                    if c.Notify ~= false then
                        Library:Notify({
                            Title = c.Text or "Toggle",
                            Content = state and (c.NotifyOnText or "เปิดใช้งานแล้ว") or (c.NotifyOffText or "ปิดใช้งานแล้ว"),
                            Type = state and "success" or "warning",
                            Duration = 1.5
                        })
                    end
                    safeCallback(c.Callback, state)
                end
            end
            applyState(state, false)

            Switch.MouseButton1Click:Connect(function() applyState(not state, true) end)
            if c.Tooltip then Library:AttachTooltip(Frame, c.Tooltip) end

            if c.Command ~= false then
                Library:RegisterCommand({
                    Title = c.Text or "Toggle",
                    SubText = "Toggle",
                    TabName = name,
                    Type = "Toggle",
                    Action = function() applyState(not state, true) end,
                })
            end
            return newElement(Frame, function() return state end, function(_, newState) applyState(newState, true) end, nil, c.Flag)
        end

        function Tab:CreateSlider(c)
            c = type(c) == "table" and c or {}
            local min, max = c.Min or 0, c.Max or 100
            local step = tonumber(c.Step)
            if step and step <= 0 then step = nil end
            local places = c.Places
            if places == nil then
                places = 0
                if step then
                    local dec = string.match(tostring(step), "%.(%d+)$")
                    places = dec and math.min(#dec, 4) or 0
                end
            end
            local suffix = c.Suffix or ""
            local val = math.clamp(c.Default or min, min, max)
            bindFlag(c.Flag, val)

            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, 0, 0, 50)
            applyThemeColor(Frame, "Element")
            Frame.Active = true
            Frame.Parent = TabContent
            corner(Frame, 9)
            applyGlowOnHover(Frame)

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -20, 0, 20)
            Label.Position = UDim2.new(0, 10, 0, 5)
            Label.BackgroundTransparency = 1
            Label.Text = (c.Text or "Slider") .. ": " .. string.format("%." .. places .. "f", val) .. suffix
            applyThemeColor(Label, "Text", "TextColor3")
            Label.FontFace = UI_Font("SemiBold")
            Label.TextSize = 14
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Frame

            local Bar = Instance.new("Frame")
            Bar.Size = UDim2.new(1, -20, 0, 8)
            Bar.Position = UDim2.new(0, 10, 0, 33)
            applyThemeColor(Bar, "Background")
            Bar.Active = true
            Bar.Parent = Frame
            corner(Bar, 4)

            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
            applyThemeColor(Fill, "AccentA")
            Fill.Parent = Bar
            corner(Fill, 4)
            accentGradient(Fill, 0)

            local Handle = Instance.new("Frame")
            Handle.Size = UDim2.new(0, 14, 0, 14)
            Handle.AnchorPoint = Vector2.new(1, 0.5)
            Handle.Position = UDim2.new(1, 0, 0.5, 0)
            Handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Handle.Parent = Fill
            corner(Handle, 7)

            local dragging, activeType = false, nil
            local function updateFromPos(xPos, fireCallback)
                local pos = xPos - Bar.AbsolutePosition.X
                local percent = math.clamp(pos / Bar.AbsoluteSize.X, 0, 1)
                local value = min + (max - min) * percent
                if step then
                    value = min + math.floor((value - min) / step + 0.5) * step
                    value = math.clamp(value, min, max)
                    value = math.floor(value * (10 ^ places) + 0.5) / (10 ^ places)
                    percent = (max - min) > 0 and (value - min) / (max - min) or 0
                else
                    value = math.floor(value * (10 ^ places)) / (10 ^ places)
                end
                Fill.Size = UDim2.new(percent, 0, 1, 0)
                Label.Text = (c.Text or "Slider") .. ": " .. string.format("%." .. places .. "f", value) .. suffix
                val = value
                bindFlag(c.Flag, val)
                if fireCallback then safeCallback(c.Callback, value) end
            end

            -- Render-synced: a fast drag can raise several InputChanged events between
            -- two rendered frames, and each one previously re-ran Fill.Size, the
            -- string.format label rebuild, and the user's Callback in full. Coalescing
            -- to "latest position wins, applied once per frame" removes that redundant
            -- work without changing what the drag ends up producing.
            local sliderPush, sliderRSStart, sliderRSStop = createRenderSyncedDrag(function(xPos)
                updateFromPos(xPos, true)
            end)

            local inputChangedConn, inputEndedConn = nil, nil
            local function stopSliderDrag()
                dragging = false; activeType = nil
                TabContent.ScrollingEnabled = true
                if inputChangedConn then inputChangedConn:Disconnect(); inputChangedConn = nil end
                if inputEndedConn then inputEndedConn:Disconnect(); inputEndedConn = nil end
                sliderRSStop()
            end

            Bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    activeType = input.UserInputType
                    TabContent.ScrollingEnabled = false
                    updateFromPos(input.Position.X, true)
                    sliderRSStart()

                    inputChangedConn = UserInputService.InputChanged:Connect(function(input2)
                        if not dragging then return end
                        if activeType == Enum.UserInputType.Touch and input2.UserInputType == Enum.UserInputType.Touch then
                            sliderPush(input2.Position.X)
                        elseif activeType == Enum.UserInputType.MouseButton1 and input2.UserInputType == Enum.UserInputType.MouseMovement then
                            sliderPush(input2.Position.X)
                        end
                    end)
                    inputEndedConn = UserInputService.InputEnded:Connect(function(input2)
                        if dragging and input2.UserInputType == activeType then
                            stopSliderDrag()
                        end
                    end)
                end
            end)
            Bar.InputEnded:Connect(function(input)
                if input.UserInputType == activeType then
                    stopSliderDrag()
                end
            end)
            if c.Tooltip then Library:AttachTooltip(Frame, c.Tooltip) end

            return newElement(Frame, function() return val end, function(_, newVal)
                newVal = math.clamp(newVal, min, max)
                local percent = (newVal - min) / (max - min)
                updateFromPos(Bar.AbsolutePosition.X + percent * Bar.AbsoluteSize.X, true)
            end, nil, c.Flag)
        end

        function Tab:CreateDropdown(c)
            c = type(c) == "table" and c or {}
            c.Options = (type(c.Options) == "table" and #c.Options > 0) and c.Options or {"Option 1"}
            local selected = c.Default or c.Options[1]
            bindFlag(c.Flag, selected)

            local Drop = Instance.new("TextButton")
            Drop.Size = UDim2.new(1, 0, 0, 44)
            applyThemeColor(Drop, "Element")
            Drop.AutoButtonColor = false
            Drop.Text = ""
            Drop.ClipsDescendants = false
            Drop.Parent = TabContent
            corner(Drop, 12)
            applyHoverEffect(Drop, "Element", "ElementHover")
            applyGlowOnHover(Drop)
            local dropStroke = stroke(Drop)
            dropStroke.Thickness = 1.2
            dropStroke.Transparency = 0.75
            if c.Tooltip then Library:AttachTooltip(Drop, c.Tooltip) end

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -44, 1, 0)
            Label.Position = UDim2.new(0, 16, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = (c.Text or "Dropdown") .. ": " .. selected
            applyThemeColor(Label, "Text", "TextColor3")
            Label.FontFace = UI_Font("SemiBold")
            Label.TextSize = 14
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.TextTruncate = Enum.TextTruncate.AtEnd
            Label.Parent = Drop

            local ArrowWrap = Instance.new("Frame")
            ArrowWrap.Size = UDim2.new(0, 18, 0, 18)
            ArrowWrap.Position = UDim2.new(1, -32, 0.5, 0)
            ArrowWrap.AnchorPoint = Vector2.new(0, 0.5)
            ArrowWrap.BackgroundTransparency = 1
            ArrowWrap.Parent = Drop

            local Arrow = Instance.new("ImageLabel")
            Arrow.Size = UDim2.new(1, 0, 1, 0)
            Arrow.AnchorPoint = Vector2.new(0.5, 0.5)
            Arrow.Position = UDim2.new(0.5, 0, 0.5, 0)
            Arrow.BackgroundTransparency = 1
            Arrow.Image = Library.Icons.chevronDown
            applyThemeColor(Arrow, "SubText", "ImageColor3")
            Arrow.ScaleType = Enum.ScaleType.Fit
            Arrow.Parent = ArrowWrap

            local isOpen, list, shadow, outsideConn = false, nil, nil, nil
            local function closeDropdown()
                if list then
                    isOpen = false
                    local closingList, closingShadow = list, shadow
                    list, shadow = nil, nil
                    TweenService:Create(dropStroke, TI.d015_Sine_Out, {Transparency = 0.75}):Play()
                    TweenService:Create(Arrow, TI.d018_Sine_Out, {Rotation = 0}):Play()
                    local t = TweenService:Create(closingList, TI.d015_Quint_In, {
                        Size = UDim2.new(closingList.Size.X.Scale, closingList.Size.X.Offset, 0, 0),
                        BackgroundTransparency = 1
                    })
                    if closingShadow then
                        TweenService:Create(closingShadow, TI.d015_Sine_Out, {ImageTransparency = 1}):Play()
                        task.delay(0.15, function() closingShadow:Destroy() end)
                    end
                    t:Play()
                    t.Completed:Connect(function() closingList:Destroy() end)
                end
                if outsideConn then outsideConn:Disconnect(); outsideConn = nil end
            end
            local function selectOption(opt, fireCallback)
                selected = opt
                Label.Text = (c.Text or "Dropdown") .. ": " .. opt
                bindFlag(c.Flag, selected)
                closeDropdown()
                if fireCallback then safeCallback(c.Callback, opt) end
            end
            local function openDropdown()
                closeActivePopup()
                isOpen = true
                TweenService:Create(dropStroke, TI.d015_Sine_Out, {Transparency = 0.15}):Play()
                TweenService:Create(Arrow, TI.d02_Back_Out, {Rotation = 180}):Play()

                local itemH, gap, pad = 38, 6, 8
                local maxVisible = 5
                -- ช่องค้นหา: เปิดอัตโนมัติถ้าตัวเลือกเยอะ (>6) หรือบังคับเปิด/ปิดได้ผ่าน c.Searchable
                local searchable = c.Searchable
                if searchable == nil then searchable = #c.Options > 6 end
                local searchH = searchable and 40 or 0

                local contentH = #c.Options * itemH + math.max(#c.Options - 1, 0) * gap
                local optionsAreaH = math.min(contentH, maxVisible * itemH + (maxVisible - 1) * gap)
                local fullH = pad * 2 + searchH + optionsAreaH
                local needsScroll = #c.Options > maxVisible

                local popupX, edgeY, openUp = resolveFloatingPosition(Drop.AbsolutePosition, Drop.AbsoluteSize, Drop.AbsoluteSize.X, fullH, 6)
                local anchorPoint = Vector2.new(0, openUp and 1 or 0)
                local shadowEdgeY = edgeY + (openUp and 14 or -14)

                shadow = Instance.new("ImageLabel")
                shadow.Name = "DropShadow"
                shadow.BackgroundTransparency = 1
                shadow.Image = "rbxassetid://5028857084"
                shadow.ImageColor3 = Color3.new(0, 0, 0)
                shadow.ImageTransparency = 1
                shadow.ScaleType = Enum.ScaleType.Slice
                shadow.SliceCenter = Rect.new(24, 24, 276, 276)
                shadow.ZIndex = 9
                shadow.Parent = ScreenGui
                shadow.AnchorPoint = anchorPoint
                shadow.Position = UDim2.new(0, popupX - 14, 0, shadowEdgeY)
                shadow.Size = UDim2.new(0, Drop.AbsoluteSize.X + 28, 0, 28)
                TweenService:Create(shadow, TI.d018_Sine_Out, {ImageTransparency = 0.55}):Play()

                -- Popup การ์ดหลัก (ครอบทั้งช่องค้นหา + รายการตัวเลือก ให้ดูเป็นชิ้นเดียวกัน)
                list = Instance.new("Frame")
                list.Size = UDim2.new(0, Drop.AbsoluteSize.X, 0, 0)
                list.AnchorPoint = anchorPoint
                list.Position = UDim2.new(0, popupX, 0, edgeY)
                applyThemeColor(list, "Element")
                list.BackgroundTransparency = 1
                list.ClipsDescendants = true
                list.ZIndex = 10
                list.Active = true
                list.Parent = ScreenGui
                corner(list, 14)
                local listGrad = Instance.new("UIGradient")
                listGrad.Rotation = 90
                listGrad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.06)})
                listGrad.Parent = list
                local listStroke = stroke(list, "AccentA")
                listStroke.Thickness = 1
                listStroke.Transparency = 0.7

                -- จับ reference ของ list รอบนี้ไว้ กัน stagger animation ยิงใส่ popup รอบใหม่ถ้าปิด/เปิดซ้ำเร็วๆ
                local myList = list

                -- ============ ช่องค้นหา (sticky อยู่บนสุด ไม่เลื่อนตามรายการ) ============
                local SearchBox
                if searchable then
                    local SearchWrap = Instance.new("Frame")
                    SearchWrap.Size = UDim2.new(1, -pad * 2, 0, searchH - 8)
                    SearchWrap.Position = UDim2.new(0, pad, 0, pad)
                    applyThemeColor(SearchWrap, "Background")
                    SearchWrap.BackgroundTransparency = 0.15
                    SearchWrap.ClipsDescendants = true
                    SearchWrap.ZIndex = 11
                    SearchWrap.Parent = list
                    corner(SearchWrap, 12) -- โค้งมนแบบแคปซูล
                    local swStroke = stroke(SearchWrap)
                    swStroke.Thickness = 1
                    swStroke.Transparency = 0.7
                    -- แถบเรืองแสงสีธีม ซ้อนอยู่เหนือกรอบปกติ โผล่มาตอน focus
                    local swGlow = stroke(SearchWrap, "AccentA", 1.2)
                    swGlow.Transparency = 1
                    local swSheen = Instance.new("UIGradient")
                    swSheen.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255))
                    swSheen.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.93), NumberSequenceKeypoint.new(1, 1)})
                    swSheen.Rotation = 90
                    swSheen.Parent = SearchWrap
                    local swScale = Instance.new("UIScale")
                    swScale.Parent = SearchWrap

                    local SearchIcon = Instance.new("ImageLabel")
                    SearchIcon.Size = UDim2.new(0, 13, 0, 13)
                    SearchIcon.AnchorPoint = Vector2.new(0, 0.5)
                    SearchIcon.Position = UDim2.new(0, 11, 0.5, 0)
                    SearchIcon.BackgroundTransparency = 1
                    SearchIcon.ImageTransparency = 0.2
                    SearchIcon.Image = Library.Icons.search
                    applyThemeColor(SearchIcon, "SubText", "ImageColor3")
                    SearchIcon.ScaleType = Enum.ScaleType.Fit
                    SearchIcon.ZIndex = 12
                    SearchIcon.Parent = SearchWrap

                    SearchBox = Instance.new("TextBox")
                    SearchBox.Position = UDim2.new(0, 31, 0, 0)
                    SearchBox.Size = UDim2.new(1, -58, 1, 0)
                    SearchBox.BackgroundTransparency = 1
                    SearchBox.Text = ""
                    SearchBox.PlaceholderText = "ค้นหา..."
                    applyThemeColor(SearchBox, "Text", "TextColor3")
                    applyThemeColor(SearchBox, "SubText", "PlaceholderColor3")
                    SearchBox.FontFace = UI_Font("SemiBold")
                    SearchBox.TextSize = 12.5
                    SearchBox.ClearTextOnFocus = false
                    SearchBox.TextXAlignment = Enum.TextXAlignment.Left
                    SearchBox.ZIndex = 12
                    SearchBox.Parent = SearchWrap

                    -- ปุ่มล้างคำค้นหา (X) โผล่มาเมื่อมีข้อความ
                    local SearchClear = Instance.new("ImageButton")
                    SearchClear.AnchorPoint = Vector2.new(1, 0.5)
                    SearchClear.Position = UDim2.new(1, -8, 0.5, 0)
                    SearchClear.Size = UDim2.new(0, 16, 0, 16)
                    SearchClear.BackgroundTransparency = 1
                    SearchClear.AutoButtonColor = false
                    SearchClear.Image = Library.Icons.close
                    applyThemeColor(SearchClear, "SubText", "ImageColor3")
                    SearchClear.ImageTransparency = 1
                    SearchClear.ScaleType = Enum.ScaleType.Fit
                    SearchClear.ZIndex = 12
                    SearchClear.Parent = SearchWrap
                    SearchClear.MouseButton1Click:Connect(function()
                        SearchBox.Text = ""
                        SearchBox:CaptureFocus()
                    end)

                    SearchBox.Focused:Connect(function()
                        TweenService:Create(swStroke, TI.d015_Sine_Out, {Transparency = 0.3}):Play()
                        TweenService:Create(swGlow, TI.d02_Sine_Out, {Transparency = 0.35}):Play()
                        TweenService:Create(SearchWrap, TI.d015_Sine_Out, {BackgroundTransparency = 0}):Play()
                        TweenService:Create(SearchIcon, TI.d015_Sine_Out, {ImageTransparency = 0}):Play()
                        TweenService:Create(swScale, TI.d02_Back_Out, {Scale = 1.015}):Play()
                    end)
                    SearchBox.FocusLost:Connect(function()
                        TweenService:Create(swStroke, TI.d015_Sine_Out, {Transparency = 0.7}):Play()
                        TweenService:Create(swGlow, TI.d015_Sine_Out, {Transparency = 1}):Play()
                        TweenService:Create(SearchWrap, TI.d015_Sine_Out, {BackgroundTransparency = 0.15}):Play()
                        TweenService:Create(SearchIcon, TI.d015_Sine_Out, {ImageTransparency = 0.2}):Play()
                        TweenService:Create(swScale, TI.d02_Back_Out, {Scale = 1}):Play()
                    end)
                    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                        TweenService:Create(SearchClear, TI.d012_Sine_Out, {ImageTransparency = SearchBox.Text == "" and 1 or 0.1}):Play()
                    end)
                end

                -- ============ พื้นที่รายการตัวเลือก ============
                local scrollWrap = Instance.new(needsScroll and "ScrollingFrame" or "Frame")
                scrollWrap.Size = UDim2.new(1, -pad * 2, 1, -(pad * 2 + searchH))
                scrollWrap.Position = UDim2.new(0, pad, 0, pad + searchH)
                scrollWrap.BackgroundTransparency = 1
                scrollWrap.ZIndex = 11
                scrollWrap.Parent = list
                if needsScroll then
                    scrollWrap.ScrollBarThickness = 3
                    scrollWrap.ScrollBarImageTransparency = 0.4
                    applyThemeColor(scrollWrap, "AccentA", "ScrollBarImageColor3")
                    scrollWrap.CanvasSize = UDim2.new(0, 0, 0, contentH)
                    scrollWrap.BorderSizePixel = 0
                end

                local inner = Instance.new("Frame")
                inner.Size = UDim2.new(1, 0, 1, 0)
                inner.BackgroundTransparency = 1
                inner.ZIndex = 11
                inner.Parent = scrollWrap
                local innerLayout = Instance.new("UIListLayout")
                innerLayout.SortOrder = Enum.SortOrder.LayoutOrder
                innerLayout.Padding = UDim.new(0, gap)
                innerLayout.Parent = inner

                -- ข้อความ "ไม่พบผลลัพธ์" ตอนค้นหาแล้วไม่เจอ
                local emptyLbl = Instance.new("TextLabel")
                emptyLbl.Size = UDim2.new(1, 0, 1, 0)
                emptyLbl.BackgroundTransparency = 1
                emptyLbl.Text = "ไม่พบตัวเลือกที่ตรงกัน"
                applyThemeColor(emptyLbl, "SubText", "TextColor3")
                emptyLbl.FontFace = UI_Font("SemiBold")
                emptyLbl.TextSize = 12.5
                emptyLbl.TextXAlignment = Enum.TextXAlignment.Center
                emptyLbl.TextYAlignment = Enum.TextYAlignment.Center
                emptyLbl.Visible = false
                emptyLbl.ZIndex = 11
                emptyLbl.Parent = scrollWrap

                local optEntries = {}
                for _, opt in ipairs(c.Options) do
                    local isSelected = (opt == selected)
                    local optBtn = Instance.new("TextButton")
                    optBtn.Size = UDim2.new(1, 0, 0, itemH)
                    applyThemeColor(optBtn, "Element")
                    optBtn.BackgroundTransparency = 1
                    optBtn.AutoButtonColor = false
                    optBtn.Text = ""
                    optBtn.ZIndex = 11
                    optBtn.Parent = inner
                    corner(optBtn, 9)
                    if not isSelected then applyHoverEffect(optBtn, "Element", "ElementHover") end

                    local accentBar
                    if isSelected then
                        accentBar = Instance.new("Frame")
                        accentBar.Size = UDim2.new(0, 3, 0, itemH * 0.5)
                        accentBar.AnchorPoint = Vector2.new(0, 0.5)
                        accentBar.Position = UDim2.new(0, 4, 0.5, 0)
                        applyThemeColor(accentBar, "AccentA")
                        accentBar.BorderSizePixel = 0
                        accentBar.BackgroundTransparency = 1 -- เริ่มจาง แล้วค่อย fade เข้าตอน stagger
                        accentBar.ZIndex = 12
                        accentBar.Parent = optBtn
                        corner(accentBar, 2)
                    end

                    local optLabel = Instance.new("TextLabel")
                    optLabel.Size = UDim2.new(1, isSelected and -46 or -24, 1, 0)
                    optLabel.Position = UDim2.new(0, (isSelected and 20 or 14) - 6, 0, 0) -- เลื่อนซ้าย 6px ไว้ก่อน แล้ว slide-in เข้าที่
                    optLabel.BackgroundTransparency = 1
                    optLabel.Text = opt
                    applyThemeColor(optLabel, isSelected and "AccentA" or "Text", "TextColor3")
                    optLabel.Font = isSelected and Enum.Font.GothamBold or Enum.Font.GothamSemibold
                    optLabel.TextSize = 13
                    optLabel.TextXAlignment = Enum.TextXAlignment.Left
                    optLabel.TextTruncate = Enum.TextTruncate.AtEnd
                    optLabel.TextTransparency = 1 -- เริ่มโปร่งใส แล้ว fade-in ทีละแถว (stagger)
                    optLabel.ZIndex = 12
                    optLabel.Parent = optBtn

                    local check
                    if isSelected then
                        check = Instance.new("ImageLabel")
                        check.Size = UDim2.new(0, 15, 0, 15)
                        check.AnchorPoint = Vector2.new(1, 0.5)
                        check.Position = UDim2.new(1, -12, 0.5, 0)
                        check.BackgroundTransparency = 1
                        check.Image = Library.Icons.check
                        check.ImageTransparency = 1 -- เริ่มโปร่งใส แล้ว fade-in พร้อม label
                        applyThemeColor(check, "AccentA", "ImageColor3")
                        check.ScaleType = Enum.ScaleType.Fit
                        check.ZIndex = 12
                        check.Parent = optBtn
                    end

                    optBtn.MouseButton1Click:Connect(function() selectOption(opt, true) end)
                    table.insert(optEntries, {opt = opt, btn = optBtn, label = optLabel, check = check, bar = accentBar, baseX = isSelected and 20 or 14})
                end

                -- กรองรายการตามคำค้นหา (ซ่อน/โชว์ผ่าน Visible, UIListLayout จะจัดเรียงใหม่ให้อัตโนมัติ)
                local function applyFilter(query)
                    query = (query or ""):lower()
                    local visibleCount = 0
                    for _, entry in ipairs(optEntries) do
                        local match = query == "" or string.find(entry.opt:lower(), query, 1, true) ~= nil
                        entry.btn.Visible = match
                        if match then visibleCount += 1 end
                    end
                    emptyLbl.Visible = visibleCount == 0
                    if needsScroll then
                        local h = visibleCount * itemH + math.max(visibleCount - 1, 0) * gap
                        scrollWrap.CanvasSize = UDim2.new(0, 0, 0, h)
                    end
                end

                if SearchBox then
                    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                        applyFilter(SearchBox.Text)
                    end)
                end

                -- เปิด popup ด้วย Back_Out ให้มีเด้งเล็กน้อย (overshoot) ดูมีชีวิตชีวากว่า Quint ตรงๆ
                TweenService:Create(list, TI.d022_Back_Out, {
                    Size = UDim2.new(0, Drop.AbsoluteSize.X, 0, fullH),
                    BackgroundTransparency = 0
                }):Play()
                -- เงาโตตามแบบนุ่มๆ ไม่เด้ง (เด้งพร้อมกันทั้งคู่จะดูรก)
                TweenService:Create(shadow, TI.d024_Quint_Out, {
                    Size = UDim2.new(0, Drop.AbsoluteSize.X + 28, 0, fullH + 28)
                }):Play()

                -- Stagger reveal: แต่ละแถว fade+slide เข้าทีละนิดเรียงจากบนลงล่าง ให้ความรู้สึกลื่นไหลกว่าโผล่มาพร้อมกันหมด
                for idx, entry in ipairs(optEntries) do
                    local delay = math.min((idx - 1) * 0.026, 0.22)
                    task.delay(delay, function()
                        if list ~= myList then return end -- popup นี้ถูกปิดไปแล้วก่อน stagger จะยิงครบ
                        TweenService:Create(entry.label, TI.d02_Sine_Out, {
                            TextTransparency = 0,
                            Position = UDim2.new(0, entry.baseX, 0, 0)
                        }):Play()
                        if entry.check then
                            TweenService:Create(entry.check, TI.d02_Sine_Out, {ImageTransparency = 0}):Play()
                        end
                        if entry.bar then
                            TweenService:Create(entry.bar, TI.d02_Sine_Out, {BackgroundTransparency = 0}):Play()
                        end
                    end)
                end

                closeActivePopup = closeDropdown
                outsideConn = UserInputService.InputBegan:Connect(function(input2)
                    if input2.UserInputType == Enum.UserInputType.MouseButton1 or input2.UserInputType == Enum.UserInputType.Touch then
                        local pos = input2.Position
                        if not isPointOverGui(pos, Drop) and (not list or not isPointOverGui(pos, list)) then closeDropdown() end
                    end
                end)

                -- SearchBox ไม่ auto-focus ตอนเปิด dropdown — user กดเองเมื่อต้องการค้นหา
            end
            Drop.MouseButton1Click:Connect(function() if isOpen then closeDropdown() else openDropdown() end end)
            return newElement(Drop, function() return selected end, function(_, newVal) selectOption(newVal, true) end, nil, c.Flag)
        end

        function Tab:CreateThemeDropdown(c)
            c = c or {}
            c.Text = c.Text or "Theme"
            local options = {}
            for name, _ in pairs(Library.Themes) do table.insert(options, name) end
            c.Options = options
            c.Default = Library.CurrentTheme
            
            local origCallback = c.Callback
            c.Callback = function(selectedTheme)
                Library:SetTheme(selectedTheme)
                if origCallback then origCallback(selectedTheme) end
            end
            return Tab:CreateDropdown(c)
        end

        function Tab:CreateColorPicker(c)
            c = type(c) == "table" and c or {}
            local selectedColor = c.Default or Color3.fromRGB(255, 255, 255)
            bindFlag(c.Flag, selectedColor)

            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, 0, 0, 40)
            applyThemeColor(Btn, "Element")
            Btn.AutoButtonColor = false
            Btn.Text = ""
            Btn.Parent = TabContent
            corner(Btn, 9)
            applyHoverEffect(Btn, "Element", "ElementHover")
            applyGlowOnHover(Btn)
            if c.Tooltip then Library:AttachTooltip(Btn, c.Tooltip) end

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -48, 1, 0)
            Label.Position = UDim2.new(0, 12, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = c.Text or "ColorPicker"
            applyThemeColor(Label, "Text", "TextColor3")
            Label.FontFace = UI_Font("SemiBold")
            Label.TextSize = 14
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Btn

            local colorPreview = Instance.new("Frame")
            colorPreview.Size = UDim2.new(0, 26, 0, 26)
            colorPreview.Position = UDim2.new(1, -34, 0.5, -13)
            colorPreview.AnchorPoint = Vector2.new(0, 0.5)
            colorPreview.BackgroundColor3 = selectedColor
            colorPreview.Parent = Btn
            corner(colorPreview, 8)
            local previewStroke = Instance.new("UIStroke")
            previewStroke.Color = Color3.fromRGB(255, 255, 255)
            previewStroke.Thickness = 1.5
            previewStroke.Transparency = 0.75
            previewStroke.Parent = colorPreview

            local isOpen, picker, outsideConn = false, nil, nil
            local h, s, v = selectedColor:ToHSV()

            local refreshVisuals

            local function closePicker()
                if picker then
                    isOpen = false
                    local closingPicker, closingScale = picker, picker:FindFirstChildOfClass("UIScale")
                    picker = nil
                    TweenService:Create(closingPicker, TI.d015_Sine_Out, {GroupTransparency = 1}):Play()
                    if closingScale then
                        TweenService:Create(closingScale, TI.d015_Sine_Out, {Scale = 0.92}):Play()
                    end
                    task.delay(0.15, function() closingPicker:Destroy() end)
                end
                if outsideConn then outsideConn:Disconnect(); outsideConn = nil end
                refreshVisuals = nil
            end
            local function applyColor(col, fireCallback)
                selectedColor = col
                bindFlag(c.Flag, selectedColor)
                TweenService:Create(colorPreview, TI.d015_Sine_Out, {BackgroundColor3 = col}):Play()
                if fireCallback then safeCallback(c.Callback, col) end
            end

            Btn.MouseButton1Click:Connect(function()
                if isOpen then closePicker() return end
                closeActivePopup()
                isOpen = true
                h, s, v = selectedColor:ToHSV()

                -- ใช้ CanvasGroup แทน Frame เพื่อ fade เนื้อหาข้างในทั้งก้อนพร้อมกันได้ด้วย GroupTransparency เดียว
                picker = Instance.new("CanvasGroup")
                local pickerW = math.max(Btn.AbsoluteSize.X, 224)
                local estimatedH = 220 -- ความสูงโดยประมาณของเนื้อหา (SV box + hue bar + hex + swatches + padding)
                local popupX, edgeY, openUp = resolveFloatingPosition(Btn.AbsolutePosition, Btn.AbsoluteSize, pickerW, estimatedH, 6)
                picker.Size = UDim2.new(0, pickerW, 0, 0)
                picker.AutomaticSize = Enum.AutomaticSize.Y
                picker.AnchorPoint = Vector2.new(0, openUp and 1 or 0)
                picker.Position = UDim2.new(0, popupX, 0, edgeY)
                applyThemeColor(picker, "Background")
                picker.GroupTransparency = 1 -- เริ่มโปร่งใสสนิท แล้ว fade+pop เข้าตอนเปิด
                picker.ZIndex = 10
                picker.Active = true
                picker.Parent = ScreenGui
                corner(picker, 12)
                local pStroke = stroke(picker)
                pStroke.Transparency = 0.4

                -- ตัวย่อ/ขยายไว้ทำ pop animation ตอนเปิด (เริ่มเล็กกว่าปกตินิดหน่อยแล้วเด้งขึ้นมาที่ 1)
                local pScale = Instance.new("UIScale")
                pScale.Scale = 0.9
                pScale.Parent = picker

                local pPad = Instance.new("UIPadding")
                pPad.PaddingLeft = UDim.new(0, 12)
                pPad.PaddingRight = UDim.new(0, 12)
                pPad.PaddingTop = UDim.new(0, 12)
                pPad.PaddingBottom = UDim.new(0, 12)
                pPad.Parent = picker

                local pLayout = Instance.new("UIListLayout")
                pLayout.Padding = UDim.new(0, 10)
                pLayout.SortOrder = Enum.SortOrder.LayoutOrder
                pLayout.Parent = picker

                local SVBox = Instance.new("Frame")
                SVBox.LayoutOrder = 1
                SVBox.Size = UDim2.new(1, 0, 0, 110)
                SVBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                SVBox.BorderSizePixel = 0
                SVBox.ClipsDescendants = true
                SVBox.ZIndex = 11
                SVBox.Parent = picker
                corner(SVBox, 8)

                local SatOverlay = Instance.new("Frame")
                SatOverlay.Size = UDim2.new(1, 0, 1, 0)
                SatOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                SatOverlay.BorderSizePixel = 0
                SatOverlay.ZIndex = 11
                SatOverlay.Parent = SVBox
                local satGradient = Instance.new("UIGradient")
                satGradient.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                })
                satGradient.Parent = SatOverlay

                local ValOverlay = Instance.new("Frame")
                ValOverlay.Size = UDim2.new(1, 0, 1, 0)
                ValOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                ValOverlay.BorderSizePixel = 0
                ValOverlay.ZIndex = 12
                ValOverlay.Parent = SVBox
                local valGradient = Instance.new("UIGradient")
                valGradient.Rotation = 90
                valGradient.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0),
                })
                valGradient.Parent = ValOverlay

                local SVCursor = Instance.new("Frame")
                SVCursor.Size = UDim2.new(0, 14, 0, 14)
                SVCursor.AnchorPoint = Vector2.new(0.5, 0.5)
                SVCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                SVCursor.BorderSizePixel = 0
                SVCursor.ZIndex = 13
                SVCursor.Parent = SVBox
                corner(SVCursor, 7)
                local svCursorStroke = Instance.new("UIStroke")
                svCursorStroke.Thickness = 2
                svCursorStroke.Color = Color3.fromRGB(25, 25, 25)
                svCursorStroke.Parent = SVCursor

                local HueBar = Instance.new("Frame")
                HueBar.LayoutOrder = 2
                HueBar.Size = UDim2.new(1, 0, 0, 16)
                HueBar.BorderSizePixel = 0
                HueBar.ZIndex = 11
                HueBar.Parent = picker
                corner(HueBar, 8)
                local hueGradient = Instance.new("UIGradient")
                hueGradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0.000, Color3.fromRGB(255, 0, 0)),
                    ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
                    ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
                    ColorSequenceKeypoint.new(0.500, Color3.fromRGB(0, 255, 255)),
                    ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
                    ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
                    ColorSequenceKeypoint.new(1.000, Color3.fromRGB(255, 0, 0)),
                })
                hueGradient.Parent = HueBar

                local HueCursor = Instance.new("Frame")
                HueCursor.Size = UDim2.new(0, 4, 1, 4)
                HueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
                HueCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                HueCursor.BorderSizePixel = 0
                HueCursor.ZIndex = 12
                HueCursor.Parent = HueBar
                corner(HueCursor, 2)
                local hueCursorStroke = Instance.new("UIStroke")
                hueCursorStroke.Thickness = 1.5
                hueCursorStroke.Color = Color3.fromRGB(25, 25, 25)
                hueCursorStroke.Parent = HueCursor

                local HexLabel = Instance.new("TextLabel")
                HexLabel.LayoutOrder = 3
                HexLabel.Size = UDim2.new(1, 0, 0, 16)
                HexLabel.BackgroundTransparency = 1
                HexLabel.FontFace = UI_Font("SemiBold")
                HexLabel.TextSize = 12
                HexLabel.TextXAlignment = Enum.TextXAlignment.Left
                HexLabel.ZIndex = 11
                applyThemeColor(HexLabel, "SubText", "TextColor3")
                HexLabel.Parent = picker

                local swatchRow = Instance.new("Frame")
                swatchRow.LayoutOrder = 4
                swatchRow.Size = UDim2.new(1, 0, 0, 22)
                swatchRow.BackgroundTransparency = 1
                swatchRow.ZIndex = 11
                swatchRow.Parent = picker
                local swatchLayout = Instance.new("UIListLayout")
                swatchLayout.FillDirection = Enum.FillDirection.Horizontal
                swatchLayout.Padding = UDim.new(0, 6)
                swatchLayout.SortOrder = Enum.SortOrder.LayoutOrder
                swatchLayout.Parent = swatchRow

                local presets = {
                    Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0),
                    Color3.fromRGB(255, 59, 48), Color3.fromRGB(255, 149, 0),
                    Color3.fromRGB(255, 204, 0), Color3.fromRGB(52, 199, 89),
                    Color3.fromRGB(0, 199, 190), Color3.fromRGB(0, 122, 255),
                    Color3.fromRGB(175, 82, 222),
                }

                local function refreshHex()
                    local col = Color3.fromHSV(h, s, v)
                    HexLabel.Text = string.format(
                        "#%02X%02X%02X",
                        math.floor(col.R * 255 + 0.5),
                        math.floor(col.G * 255 + 0.5),
                        math.floor(col.B * 255 + 0.5)
                    )
                end

                refreshVisuals = function()
                    SVCursor.Position = UDim2.new(s, 0, 1 - v, 0)
                    HueCursor.Position = UDim2.new(h, 0, 0.5, 0)
                    SVBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                    refreshHex()
                end
                refreshVisuals()

                local function updateSV(x, y)
                    s = math.clamp((x - SVBox.AbsolutePosition.X) / SVBox.AbsoluteSize.X, 0, 1)
                    v = 1 - math.clamp((y - SVBox.AbsolutePosition.Y) / SVBox.AbsoluteSize.Y, 0, 1)
                    refreshVisuals()
                    applyColor(Color3.fromHSV(h, s, v), true)
                end
                local function updateHue(x)
                    h = math.clamp((x - HueBar.AbsolutePosition.X) / HueBar.AbsoluteSize.X, 0, 1)
                    refreshVisuals()
                    applyColor(Color3.fromHSV(h, s, v), true)
                end

                -- Both drags rebuild the gradient visuals and re-run applyColor (which
                -- fans out to the flag/callback system) on every event. Render-syncing
                -- means a fast swipe across the box only pays that cost once per frame.
                local svPush, svRSStart, svRSStop = createRenderSyncedDrag(function(x, y)
                    updateSV(x, y)
                end)

                local svDragging, svChangedConn, svEndedConn = false, nil, nil
                local function stopSVDrag()
                    svDragging = false
                    if svChangedConn then svChangedConn:Disconnect(); svChangedConn = nil end
                    if svEndedConn then svEndedConn:Disconnect(); svEndedConn = nil end
                    svRSStop()
                end
                SVBox.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        svDragging = true
                        updateSV(input.Position.X, input.Position.Y)
                        svRSStart()
                        svChangedConn = UserInputService.InputChanged:Connect(function(input2)
                            if svDragging and (input2.UserInputType == Enum.UserInputType.MouseMovement or input2.UserInputType == Enum.UserInputType.Touch) then
                                svPush(input2.Position.X, input2.Position.Y)
                            end
                        end)
                        svEndedConn = UserInputService.InputEnded:Connect(function(input2)
                            if input2.UserInputType == Enum.UserInputType.MouseButton1 or input2.UserInputType == Enum.UserInputType.Touch then
                                stopSVDrag()
                            end
                        end)
                    end
                end)

                local huePush, hueRSStart, hueRSStop = createRenderSyncedDrag(function(x)
                    updateHue(x)
                end)

                local hueDragging, hueChangedConn, hueEndedConn = false, nil, nil
                local function stopHueDrag()
                    hueDragging = false
                    if hueChangedConn then hueChangedConn:Disconnect(); hueChangedConn = nil end
                    if hueEndedConn then hueEndedConn:Disconnect(); hueEndedConn = nil end
                    hueRSStop()
                end
                HueBar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        hueDragging = true
                        updateHue(input.Position.X)
                        hueRSStart()
                        hueChangedConn = UserInputService.InputChanged:Connect(function(input2)
                            if hueDragging and (input2.UserInputType == Enum.UserInputType.MouseMovement or input2.UserInputType == Enum.UserInputType.Touch) then
                                huePush(input2.Position.X)
                            end
                        end)
                        hueEndedConn = UserInputService.InputEnded:Connect(function(input2)
                            if input2.UserInputType == Enum.UserInputType.MouseButton1 or input2.UserInputType == Enum.UserInputType.Touch then
                                stopHueDrag()
                            end
                        end)
                    end
                end)

                for _, col in ipairs(presets) do
                    local sw = Instance.new("TextButton")
                    sw.Size = UDim2.new(0, 22, 0, 22)
                    sw.BackgroundColor3 = col
                    sw.AutoButtonColor = false
                    sw.Text = ""
                    sw.ZIndex = 11
                    sw.Parent = swatchRow
                    corner(sw, 6)
                    local swStroke = Instance.new("UIStroke")
                    swStroke.Color = Color3.fromRGB(255, 255, 255)
                    swStroke.Thickness = 1
                    swStroke.Transparency = 0.7
                    swStroke.Parent = sw
                    sw.MouseEnter:Connect(function()
                        TweenService:Create(swStroke, TI.d012_Sine_Out, {Thickness = 2, Transparency = 0.15}):Play()
                    end)
                    sw.MouseLeave:Connect(function()
                        TweenService:Create(swStroke, TI.d012_Sine_Out, {Thickness = 1, Transparency = 0.7}):Play()
                    end)
                    sw.MouseButton1Click:Connect(function()
                        h, s, v = col:ToHSV()
                        refreshVisuals()
                        applyColor(col, true)
                    end)
                end

                -- Pop เข้าแบบมีเด้งนิดๆ (Back_Out) พร้อมกับ fade ทั้งก้อนผ่าน GroupTransparency
                TweenService:Create(picker, TI.d022_Back_Out, {GroupTransparency = 0}):Play()
                TweenService:Create(pScale, TI.d022_Back_Out, {Scale = 1}):Play()

                closeActivePopup = closePicker
                outsideConn = UserInputService.InputBegan:Connect(function(input2)
                    if input2.UserInputType == Enum.UserInputType.MouseButton1 or input2.UserInputType == Enum.UserInputType.Touch then
                        local pos = input2.Position
                        if not isPointOverGui(pos, Btn) and not isPointOverGui(pos, picker) then closePicker() end
                    end
                end)
            end)
            return newElement(Btn, function() return selectedColor end, function(_, newColor)
                h, s, v = newColor:ToHSV()
                if refreshVisuals then refreshVisuals() end
                applyColor(newColor, true)
            end, nil, c.Flag)
        end

        function Tab:CreateInput(c)
            c = type(c) == "table" and c or {}
            bindFlag(c.Flag, c.Default or "")
            local Box = Instance.new("TextBox")
            Box.Size = UDim2.new(1, 0, 0, 40)
            applyThemeColor(Box, "Element")
            Box.Text = c.Default or ""
            Box.PlaceholderText = c.Text or "Input here..."
            applyThemeColor(Box, "Text", "TextColor3")
            applyThemeColor(Box, "SubText", "PlaceholderColor3")
            Box.FontFace = UI_Font("SemiBold")
            Box.TextSize = 14
            Box.ClearTextOnFocus = false
            Box.TextXAlignment = Enum.TextXAlignment.Left
            Box.Parent = TabContent
            corner(Box, 9)
            
            local Pad = Instance.new("UIPadding")
            Pad.PaddingLeft = UDim.new(0, 12)
            Pad.Parent = Box
            
            applyGlowOnHover(Box)
            if c.Tooltip then Library:AttachTooltip(Box, c.Tooltip) end
            Box.FocusLost:Connect(function()
                Library.Flags[c.Flag or ""] = Box.Text
                safeCallback(c.Callback, Box.Text)
            end)
            return newElement(Box, function() return Box.Text end, function(_, newText)
                Box.Text = newText; safeCallback(c.Callback, newText)
            end, nil, c.Flag)
        end

        function Tab:CreateKeybind(c)
            c = type(c) == "table" and c or {}
            local selectedKey = c.Default
            bindFlag(c.Flag, selectedKey)
            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, 0, 0, 40)
            applyThemeColor(Btn, "Element")
            Btn.AutoButtonColor = false
            Btn.Text = ""
            Btn.Parent = TabContent
            corner(Btn, 9)
            applyHoverEffect(Btn, "Element", "ElementHover")
            applyGlowOnHover(Btn)

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -60, 1, 0)
            Label.Position = UDim2.new(0, 12, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = (c.Text or "Keybind") .. ": " .. (selectedKey and selectedKey.Name or "None")
            applyThemeColor(Label, "Text", "TextColor3")
            Label.FontFace = UI_Font("SemiBold")
            Label.TextSize = 14
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Btn

            local waiting, bindConn, pulseConn = false, nil, nil
            local waitStroke = stroke(Btn, "AccentA", 1.2)
            waitStroke.Transparency = 1
            if c.Tooltip then Library:AttachTooltip(Btn, c.Tooltip) end
            Btn.MouseButton1Click:Connect(function()
                if waiting then return end
                if bindConn then bindConn:Disconnect(); bindConn = nil end
                waiting = true
                Label.Text = (c.Text or "Keybind") .. ": Press..."
                -- ชีพจรเรืองแสงวนไปมาตอนรอกดปุ่ม ให้รู้ชัดว่า "กำลังฟังอยู่" ไม่ใช่ค้าง
                local t0 = os.clock()
                pulseConn = RunService.RenderStepped:Connect(function()
                    if not Btn.Parent then -- element ถูกทำลายระหว่างรอ (เช่น Tab:Clear()) กันลูป/คอนเนกชันค้าง
                        if pulseConn then pulseConn:Disconnect(); pulseConn = nil end
                        if bindConn then bindConn:Disconnect(); bindConn = nil end
                        return
                    end
                    local a = (math.sin((os.clock() - t0) * 4) + 1) / 2 -- 0..1
                    waitStroke.Transparency = 0.85 - a * 0.55
                end)
                local function stopWaitPulse()
                    if pulseConn then pulseConn:Disconnect(); pulseConn = nil end
                    TweenService:Create(waitStroke, TI.d02_Sine_Out, {Transparency = 1}):Play()
                end
                bindConn = UserInputService.InputBegan:Connect(function(input)
                    if waiting and input.UserInputType == Enum.UserInputType.Keyboard then
                        selectedKey = input.KeyCode
                        bindFlag(c.Flag, selectedKey)
                        Label.Text = (c.Text or "Keybind") .. ": " .. selectedKey.Name
                        waiting = false
                        stopWaitPulse()
                        if bindConn then bindConn:Disconnect(); bindConn = nil end
                        safeCallback(c.Callback, selectedKey)
                    end
                end)
            end)
            return newElement(Btn, function() return selectedKey end, function(_, newKey)
                selectedKey = newKey
                bindFlag(c.Flag, selectedKey)
                Label.Text = (c.Text or "Keybind") .. ": " .. (newKey and newKey.Name or "None")
            end, nil, c.Flag)
        end

        function Tab:CreateLabel(c)
            c = type(c) == "table" and c or {}
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, 0, 0, 24)
            Label.AutomaticSize = Enum.AutomaticSize.Y
            Label.BackgroundTransparency = 1
            Label.Text = c.Text or "Label"
            applyThemeColor(Label, "SubText", "TextColor3")
            Label.FontFace = UI_Font("SemiBold")
            Label.TextSize = 13
            Label.TextWrapped = true
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = TabContent
            if c.Tooltip then Library:AttachTooltip(Label, c.Tooltip) end
            return newElement(Label, function() return Label.Text end, function(_, newText) Label.Text = newText end)
        end

        function Tab:CreateTextArea(c)
            c = type(c) == "table" and c or {}
            bindFlag(c.Flag, c.Default or "")
            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, 0, 0, c.Height or 90)
            applyThemeColor(Frame, "Element")
            Frame.Parent = TabContent
            corner(Frame, 9)
            applyGlowOnHover(Frame)

            local Box = Instance.new("TextBox")
            Box.Size = UDim2.new(1, -20, 1, -16)
            Box.Position = UDim2.new(0, 10, 0, 8)
            Box.BackgroundTransparency = 1
            Box.Text = c.Default or ""
            Box.PlaceholderText = c.Text or "Type notes here..."
            applyThemeColor(Box, "Text", "TextColor3")
            applyThemeColor(Box, "SubText", "PlaceholderColor3")
            Box.FontFace = UI_Font("Medium")
            Box.TextSize = 13
            Box.ClearTextOnFocus = false
            Box.MultiLine = true
            Box.TextWrapped = true
            Box.TextXAlignment = Enum.TextXAlignment.Left
            Box.TextYAlignment = Enum.TextYAlignment.Top
            Box.Parent = Frame

            Box.FocusLost:Connect(function()
                Library.Flags[c.Flag or ""] = Box.Text
                safeCallback(c.Callback, Box.Text)
            end)
            return newElement(Box, function() return Box.Text end, function(_, newText)
                Box.Text = newText; safeCallback(c.Callback, newText)
            end, nil, c.Flag)
        end

