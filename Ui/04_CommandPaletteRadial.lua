    -- ============ COMMAND PALETTE (Ctrl+K) ============
    -- ค้นหา/สั่งงาน Tab, Button, Toggle ทั้งหมดในหน้าต่างได้จากช่องพิมพ์ช่องเดียว โดยไม่ต้องไล่กดเมนูเอง
    -- ทุก element ที่สร้างผ่าน Tab:CreateButton / CreateToggle / Window:CreateTab ลงทะเบียนตัวเองไว้ใน Library.Commands อัตโนมัติแล้ว
    -- ปุ่ม/ทริกเกอร์อื่นๆ ก็เพิ่มเข้าไปเองได้ผ่าน Library:RegisterCommand({Title=..., Action=function() ... end})
    function Window:CreateCommandPalette(config)
        config = type(config) == "table" and config or {}
        local keybind = config.Keybind or Enum.KeyCode.K
        local requireCtrl = config.RequireCtrl ~= false

        local paletteOpen = false
        local Overlay, Box, SearchBox, ListHolder, EmptyLbl
        local filtered, highlightIndex = {}, 1
        local keyNavConn, outsideConn = nil, nil

        local closePalette, openPalette, rebuildList, runHighlighted, moveHighlight

        closePalette = function()
            if not paletteOpen then return end
            paletteOpen = false
            local closingOverlay, closingBox = Overlay, Box
            Overlay, Box, SearchBox, ListHolder, EmptyLbl = nil, nil, nil, nil, nil
            if keyNavConn then keyNavConn:Disconnect(); keyNavConn = nil end
            if outsideConn then outsideConn:Disconnect(); outsideConn = nil end
            if closingOverlay then
                local bStroke = closingBox and closingBox:FindFirstChildOfClass("UIStroke")
                local bScale = closingBox and closingBox:FindFirstChildOfClass("UIScale")
                TweenService:Create(closingOverlay, TI.d015_Sine_Out, {BackgroundTransparency = 1}):Play()
                if closingBox then TweenService:Create(closingBox, TI.d015_Quint_In, {BackgroundTransparency = 1}):Play() end
                if bStroke then TweenService:Create(bStroke, TI.d015_Quint_In, {Transparency = 1}):Play() end
                if bScale then TweenService:Create(bScale, TI.d015_Quint_In, {Scale = 0.94}):Play() end
                task.delay(0.15, function() closingOverlay:Destroy() end)
            end
        end

        moveHighlight = function(delta)
            if #filtered == 0 then return end
            highlightIndex = ((highlightIndex - 1 + delta) % #filtered) + 1
            rebuildList(SearchBox and SearchBox.Text or "", true)
        end

        runHighlighted = function()
            local entry = filtered[highlightIndex]
            if entry then
                closePalette()
                safeCallback(entry.Action)
            end
        end

        rebuildList = function(query, keepHighlight)
            if not ListHolder then return end
            for _, child in ipairs(ListHolder:GetChildren()) do
                if child ~= EmptyLbl and not child:IsA("UIListLayout") then child:Destroy() end
            end
            query = (query or ""):lower()
            filtered = {}
            for _, entry in ipairs(Library.Commands) do
                local haystack = (entry.Title .. " " .. (entry.SubText or "") .. " " .. (entry.TabName or "")):lower()
                if query == "" or string.find(haystack, query, 1, true) then
                    table.insert(filtered, entry)
                end
            end
            if not keepHighlight or highlightIndex > #filtered then highlightIndex = 1 end
            EmptyLbl.Visible = #filtered == 0

            for i, entry in ipairs(filtered) do
                local isHi = (i == highlightIndex)
                local Row = Instance.new("TextButton")
                Row.Size = UDim2.new(1, 0, 0, 42)
                Row.LayoutOrder = i
                applyThemeColor(Row, isHi and "AccentA" or "Element")
                Row.BackgroundTransparency = isHi and 0.85 or 1
                Row.AutoButtonColor = false
                Row.Text = ""
                Row.ZIndex = 63
                Row.Parent = ListHolder
                corner(Row, 8)

                local iconOffset = 12
                local iconKey = entry.Icon and (Library.Icons[entry.Icon] or entry.Icon)
                if iconKey then
                    local IconImg = Instance.new("ImageLabel")
                    IconImg.Size = UDim2.new(0, 16, 0, 16)
                    IconImg.Position = UDim2.new(0, 12, 0.5, 0)
                    IconImg.AnchorPoint = Vector2.new(0, 0.5)
                    IconImg.BackgroundTransparency = 1
                    IconImg.Image = iconKey
                    IconImg.ScaleType = Enum.ScaleType.Fit
                    applyThemeColor(IconImg, "SubText", "ImageColor3")
                    IconImg.ZIndex = 64
                    IconImg.Parent = Row
                    iconOffset = 36
                end

                local TitleLbl = Instance.new("TextLabel")
                TitleLbl.Size = UDim2.new(1, -iconOffset - 76, 1, 0)
                TitleLbl.Position = UDim2.new(0, iconOffset, 0, 0)
                TitleLbl.BackgroundTransparency = 1
                TitleLbl.Text = entry.Title
                applyThemeColor(TitleLbl, "Text", "TextColor3")
                TitleLbl.FontFace = UI_Font("SemiBold")
                TitleLbl.TextSize = 13.5
                TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
                TitleLbl.TextTruncate = Enum.TextTruncate.AtEnd
                TitleLbl.ZIndex = 64
                TitleLbl.Parent = Row

                if entry.TabName or entry.SubText then
                    local BadgeLbl = Instance.new("TextLabel")
                    BadgeLbl.AnchorPoint = Vector2.new(1, 0.5)
                    BadgeLbl.Position = UDim2.new(1, -10, 0.5, 0)
                    BadgeLbl.Size = UDim2.new(0, 60, 0, 16)
                    BadgeLbl.BackgroundTransparency = 1
                    BadgeLbl.Text = entry.TabName or entry.SubText or ""
                    applyThemeColor(BadgeLbl, "SubText", "TextColor3")
                    BadgeLbl.FontFace = UI_Font("Medium")
                    BadgeLbl.TextSize = 11
                    BadgeLbl.TextXAlignment = Enum.TextXAlignment.Right
                    BadgeLbl.TextTruncate = Enum.TextTruncate.AtEnd
                    BadgeLbl.ZIndex = 64
                    BadgeLbl.Parent = Row
                end

                Row.MouseEnter:Connect(function() highlightIndex = i; rebuildList(SearchBox and SearchBox.Text or "", true) end)
                Row.MouseButton1Click:Connect(function()
                    closePalette()
                    safeCallback(entry.Action)
                end)
            end
        end

        openPalette = function()
            if paletteOpen then return end
            closeActivePopup()
            paletteOpen = true
            highlightIndex = 1

            Overlay = Instance.new("Frame")
            Overlay.Name = "PaletteOverlay"
            Overlay.Size = UDim2.new(1, 0, 1, 0)
            Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            Overlay.BackgroundTransparency = 1
            Overlay.Active = true
            Overlay.ZIndex = 60
            Overlay.Parent = ScreenGui

            Box = Instance.new("Frame")
            Box.Name = "PaletteBox"
            Box.AnchorPoint = Vector2.new(0.5, 0)
            Box.Position = UDim2.new(0.5, 0, 0, 46)
            Box.Size = UDim2.new(1, -40, 0, 300)
            applyThemeColor(Box, "Element")
            Box.BackgroundTransparency = 1
            Box.ZIndex = 61
            Box.Active = true
            Box.Parent = Overlay
            corner(Box, 14)
            local bStroke = stroke(Box, "AccentA")
            bStroke.Thickness = 1.2
            bStroke.Transparency = 1
            local bScale = Instance.new("UIScale")
            bScale.Scale = 0.94
            bScale.Parent = Box

            local SearchWrap = Instance.new("Frame")
            SearchWrap.Size = UDim2.new(1, -24, 0, 40)
            SearchWrap.Position = UDim2.new(0, 12, 0, 12)
            applyThemeColor(SearchWrap, "Background")
            SearchWrap.ZIndex = 62
            SearchWrap.Parent = Box
            corner(SearchWrap, 10)

            local SearchIcon = Instance.new("ImageLabel")
            SearchIcon.Size = UDim2.new(0, 16, 0, 16)
            SearchIcon.AnchorPoint = Vector2.new(0, 0.5)
            SearchIcon.Position = UDim2.new(0, 12, 0.5, 0)
            SearchIcon.BackgroundTransparency = 1
            SearchIcon.Image = Library.Icons.search
            applyThemeColor(SearchIcon, "SubText", "ImageColor3")
            SearchIcon.ScaleType = Enum.ScaleType.Fit
            SearchIcon.ZIndex = 63
            SearchIcon.Parent = SearchWrap

            SearchBox = Instance.new("TextBox")
            SearchBox.Position = UDim2.new(0, 38, 0, 0)
            SearchBox.Size = UDim2.new(1, -50, 1, 0)
            SearchBox.BackgroundTransparency = 1
            SearchBox.Text = ""
            SearchBox.PlaceholderText = "พิมพ์เพื่อค้นหาคำสั่ง..."
            applyThemeColor(SearchBox, "Text", "TextColor3")
            applyThemeColor(SearchBox, "SubText", "PlaceholderColor3")
            SearchBox.FontFace = UI_Font("SemiBold")
            SearchBox.TextSize = 14
            SearchBox.ClearTextOnFocus = false
            SearchBox.TextXAlignment = Enum.TextXAlignment.Left
            SearchBox.ZIndex = 63
            SearchBox.Parent = SearchWrap

            ListHolder = Instance.new("ScrollingFrame")
            ListHolder.Position = UDim2.new(0, 12, 0, 62)
            ListHolder.Size = UDim2.new(1, -24, 1, -74)
            ListHolder.BackgroundTransparency = 1
            ListHolder.ScrollBarThickness = 3
            applyThemeColor(ListHolder, "AccentA", "ScrollBarImageColor3")
            ListHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
            ListHolder.AutomaticCanvasSize = Enum.AutomaticSize.Y
            ListHolder.ZIndex = 62
            ListHolder.Parent = Box
            local ListLayout = Instance.new("UIListLayout")
            ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            ListLayout.Padding = UDim.new(0, 4)
            ListLayout.Parent = ListHolder

            EmptyLbl = Instance.new("TextLabel")
            EmptyLbl.Size = UDim2.new(1, 0, 0, 30)
            EmptyLbl.BackgroundTransparency = 1
            EmptyLbl.Text = "ไม่พบคำสั่งที่ตรงกัน"
            applyThemeColor(EmptyLbl, "SubText", "TextColor3")
            EmptyLbl.FontFace = UI_Font("SemiBold")
            EmptyLbl.TextSize = 12.5
            EmptyLbl.Visible = false
            EmptyLbl.ZIndex = 62
            EmptyLbl.Parent = ListHolder

            rebuildList("")
            SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                rebuildList(SearchBox.Text)
            end)

            TweenService:Create(Overlay, TI.d02_Sine_Out, {BackgroundTransparency = 0.45}):Play()
            TweenService:Create(Box, TI.d024_Quint_Out, {BackgroundTransparency = 0}):Play()
            TweenService:Create(bStroke, TI.d024_Quint_Out, {Transparency = 0.4}):Play()
            TweenService:Create(bScale, TI.d045_Back_Out, {Scale = 1}):Play()

            outsideConn = Overlay.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    if Box and not isPointOverGui(input.Position, Box) then closePalette() end
                end
            end)

            -- Enter = สั่งงานตัวที่ไฮไลต์, Esc = ปิด, Up/Down = เลื่อนไฮไลต์ (TextBox ที่โฟกัสอยู่ปกติไม่กินคีย์พวกนี้)
            keyNavConn = UserInputService.InputBegan:Connect(function(input, gpe)
                if not paletteOpen then return end
                if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
                    runHighlighted()
                elseif input.KeyCode == Enum.KeyCode.Escape then
                    closePalette()
                elseif input.KeyCode == Enum.KeyCode.Down then
                    moveHighlight(1)
                elseif input.KeyCode == Enum.KeyCode.Up then
                    moveHighlight(-1)
                end
            end)

            task.defer(function() if SearchBox then SearchBox:CaptureFocus() end end)
        end

        UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe or input.KeyCode ~= keybind then return end
            if requireCtrl and not (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then return end
            if paletteOpen then closePalette() else openPalette() end
        end)

        return {Open = openPalette, Close = closePalette}
    end

    -- ============ FLOATING RADIAL MENU: กดค้างแล้วกางเมนูวงกลมรอบจุดนิ้ว (มือถือ) / คลิกขวาค้างแล้วลาก (PC) ============
    -- items = {{Text=, Icon=(optional), Callback=function() ... end}, ...} เรียงรอบวงตามเข็มนาฬิกาเริ่มจากด้านบน
    -- ปล่อยนิ้ว/เมาส์ตรงช่องไหนก็สั่งงานช่องนั้น, ปล่อยใกล้จุดศูนย์กลางเกินไป (ในระยะ Deadzone) ถือว่ายกเลิก
    function Window:BindRadialMenu(triggerObj, items, opts)
        opts = type(opts) == "table" and opts or {}
        items = type(items) == "table" and items or {}
        if not triggerObj or #items == 0 then return end

        local radius = opts.Radius or 76
        local itemSize = opts.ItemSize or 50
        local deadzone = opts.Deadzone or 24
        local startAngle = opts.StartAngle or -90

        local radialOpen = false
        local Root, cx, cy
        local itemFrames, highlighted = {}, nil

        local function angleDiff(a, b)
            local d = (a - b) % 360
            if d > 180 then d = 360 - d end
            return d
        end

        local function itemAt(px, py)
            local dx, dy = px - cx, py - cy
            if math.sqrt(dx * dx + dy * dy) < deadzone then return nil end
            local ang = (math.deg(math.atan2(dy, dx)) + 360) % 360
            local best, bestDiff = nil, math.huge
            for _, item in ipairs(itemFrames) do
                local diff = angleDiff(ang, item._angle)
                if diff < bestDiff then bestDiff, best = diff, item end
            end
            return best
        end

        local function setHighlight(item)
            if highlighted == item then return end
            if highlighted then
                TweenService:Create(highlighted._btn, TI.d015_Sine_Out, {BackgroundTransparency = 0.1, BackgroundColor3 = Theme.Element}):Play()
                TweenService:Create(highlighted._stroke, TI.d015_Sine_Out, {Transparency = 0.5, Thickness = 1}):Play()
            end
            highlighted = item
            if highlighted then
                TweenService:Create(highlighted._btn, TI.d015_Sine_Out, {BackgroundTransparency = 0, BackgroundColor3 = Theme.AccentA}):Play()
                TweenService:Create(highlighted._stroke, TI.d015_Sine_Out, {Transparency = 0, Thickness = 1.5}):Play()
                pulseRing(highlighted._btn, "AccentA", itemSize / 2)
            end
        end

        local function closeMenu()
            if not radialOpen then return end
            radialOpen = false
            local closingRoot = Root
            Root, itemFrames, highlighted = nil, {}, nil
            if closingRoot then
                for _, child in ipairs(closingRoot:GetDescendants()) do
                    if child:IsA("Frame") or child:IsA("ImageLabel") or child:IsA("TextLabel") then
                        pcall(function() TweenService:Create(child, TI.d015_Sine_Out, {BackgroundTransparency = 1, ImageTransparency = 1, TextTransparency = 1}):Play() end)
                    end
                end
                task.delay(0.16, function() closingRoot:Destroy() end)
            end
        end

        local function openAt(pos)
            if radialOpen then closeMenu() end
            radialOpen = true
            itemFrames, highlighted = {}, nil

            local screenSize = ScreenGui.AbsoluteSize
            local margin = radius + itemSize / 2 + 8
            cx = math.clamp(pos.X, margin, math.max(margin, screenSize.X - margin))
            cy = math.clamp(pos.Y, margin, math.max(margin, screenSize.Y - margin))

            Root = Instance.new("Frame")
            Root.Name = "RadialMenuRoot"
            Root.Size = UDim2.new(1, 0, 1, 0)
            Root.BackgroundTransparency = 1
            Root.Active = true
            Root.ZIndex = 70
            Root.Parent = ScreenGui

            local Backdrop = Instance.new("Frame")
            Backdrop.Size = UDim2.new(1, 0, 1, 0)
            Backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            Backdrop.BackgroundTransparency = 1
            Backdrop.ZIndex = 70
            Backdrop.Parent = Root
            TweenService:Create(Backdrop, TI.d02_Sine_Out, {BackgroundTransparency = 0.4}):Play()

            local Center = Instance.new("Frame")
            Center.AnchorPoint = Vector2.new(0.5, 0.5)
            Center.Position = UDim2.new(0, cx, 0, cy)
            Center.Size = UDim2.new(0, 26, 0, 26)
            applyThemeColor(Center, "Element")
            Center.BackgroundTransparency = 1
            Center.ZIndex = 71
            Center.Parent = Root
            corner(Center, 13)
            TweenService:Create(Center, TI.d02_Sine_Out, {BackgroundTransparency = 0.15}):Play()
            stroke(Center, "AccentA")

            local n = #items
            for i, item in ipairs(items) do
                local angleDeg = (startAngle + (360 / n) * (i - 1)) % 360
                local angleRad = math.rad(angleDeg)
                local ix, iy = cx + math.cos(angleRad) * radius, cy + math.sin(angleRad) * radius

                local ItemBtn = Instance.new("Frame")
                ItemBtn.AnchorPoint = Vector2.new(0.5, 0.5)
                ItemBtn.Position = UDim2.new(0, cx, 0, cy)
                ItemBtn.Size = UDim2.new(0, itemSize, 0, itemSize)
                applyThemeColor(ItemBtn, "Element")
                ItemBtn.BackgroundTransparency = 1
                ItemBtn.ZIndex = 72
                ItemBtn.Parent = Root
                corner(ItemBtn, itemSize / 2)
                local itemStroke = stroke(ItemBtn, "Stroke")
                itemStroke.Transparency = 1

                local hasIcon = item.Icon ~= nil
                if hasIcon then
                    local IconImg = Instance.new("ImageLabel")
                    IconImg.AnchorPoint = Vector2.new(0.5, 0.5)
                    IconImg.Position = UDim2.new(0.5, 0, item.Text and 0.36 or 0.5, 0)
                    IconImg.Size = UDim2.new(0, 20, 0, 20)
                    IconImg.BackgroundTransparency = 1
                    IconImg.Image = Library.Icons[item.Icon] or item.Icon
                    IconImg.ImageTransparency = 1
                    applyThemeColor(IconImg, "Text", "ImageColor3")
                    IconImg.ScaleType = Enum.ScaleType.Fit
                    IconImg.ZIndex = 73
                    IconImg.Parent = ItemBtn
                    TweenService:Create(IconImg, TI.d02_Sine_Out, {ImageTransparency = 0}):Play()
                end
                if item.Text then
                    local Lbl = Instance.new("TextLabel")
                    Lbl.AnchorPoint = Vector2.new(0.5, 1)
                    Lbl.Position = UDim2.new(0.5, 0, 1, -4)
                    Lbl.Size = UDim2.new(1, -6, 0, 12)
                    Lbl.BackgroundTransparency = 1
                    Lbl.Text = item.Text
                    applyThemeColor(Lbl, "Text", "TextColor3")
                    Lbl.FontFace = UI_Font("Bold")
                    Lbl.TextSize = 9.5
                    Lbl.TextTransparency = 1
                    Lbl.TextTruncate = Enum.TextTruncate.AtEnd
                    Lbl.ZIndex = 73
                    Lbl.Parent = ItemBtn
                    TweenService:Create(Lbl, TI.d02_Sine_Out, {TextTransparency = 0}):Play()
                end

                TweenService:Create(ItemBtn, TweenInfo.new(0.26 + (i - 1) * 0.02, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    Position = UDim2.new(0, ix, 0, iy),
                    BackgroundTransparency = 0.1,
                }):Play()
                TweenService:Create(itemStroke, TI.d024_Quint_Out, {Transparency = 0.5}):Play()

                table.insert(itemFrames, {_btn = ItemBtn, _stroke = itemStroke, _angle = angleDeg, Callback = item.Callback})
            end
        end

        -- มือถือ: กดค้าง (Roblox TouchLongPress) แล้วลากนิ้วไปช่องที่ต้องการ ปล่อยนิ้วเพื่อสั่งงาน
        if triggerObj:IsA("GuiButton") or triggerObj:IsA("GuiObject") then
            local ok = pcall(function()
                triggerObj.TouchLongPress:Connect(function(touchPositions, state)
                    local pos = touchPositions[1]
                    if not pos then return end
                    if state == Enum.UserInputState.Begin then
                        openAt(pos)
                    elseif state == Enum.UserInputState.Change then
                        if radialOpen then setHighlight(itemAt(pos.X, pos.Y)) end
                    elseif state == Enum.UserInputState.End then
                        if radialOpen then
                            local chosen = highlighted
                            closeMenu()
                            if chosen then safeCallback(chosen.Callback) end
                        end
                    elseif state == Enum.UserInputState.Cancel then
                        closeMenu()
                    end
                end)
            end)
        end

        -- SAFETY NET: บางเครื่อง/บางจังหวะ TouchLongPress ไม่ยิง End/Cancel กลับมาตอนปล่อยนิ้ว
        -- (ชนกับ touch ของกล้อง/ระบบมือถือ หรือแอพถูกสลับ) ทำให้ radialOpen ค้าง true และ Root
        -- (Active=true, เต็มจอ, ZIndex=70) บัง input ทั้งเกมแบบกดอะไรไม่ได้เลย ต้อง force-close ทุกครั้ง
        -- ที่มีนิ้วปล่อยจากจอ หรือแอพเสีย focus ไป ไม่ให้ Root มีโอกาสค้างอยู่ได้
        UserInputService.TouchEnded:Connect(function()
            if radialOpen then
                local chosen = highlighted
                closeMenu()
                if chosen then safeCallback(chosen.Callback) end
            end
        end)
        UserInputService.WindowFocusReleased:Connect(function()
            if radialOpen then closeMenu() end
        end)

        -- PC: คลิกขวาค้างแล้วลากเมาส์ไปช่องที่ต้องการ ปล่อยคลิกเพื่อสั่งงาน (เปิดทันทีไม่ต้องรอ hold เหมือนมือถือ)
        triggerObj.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
            openAt(Vector2.new(input.Position.X, input.Position.Y))
            local changedConn, endedConn
            changedConn = UserInputService.InputChanged:Connect(function(input2)
                if radialOpen and input2.UserInputType == Enum.UserInputType.MouseMovement then
                    setHighlight(itemAt(input2.Position.X, input2.Position.Y))
                end
            end)
            endedConn = UserInputService.InputEnded:Connect(function(input2)
                if input2.UserInputType == Enum.UserInputType.MouseButton2 then
                    if changedConn then changedConn:Disconnect() end
                    if endedConn then endedConn:Disconnect() end
                    if radialOpen then
                        local chosen = highlighted
                        closeMenu()
                        if chosen then safeCallback(chosen.Callback) end
                    end
                end
            end)
        end)

        return {Close = closeMenu}
    end

    -- ทางลัด: ผูก radial menu เข้ากับปุ่มลอย (RestoreBtn) ให้เลยในคำเรียกเดียว ไม่ต้องหา GuiObject เอง
    function Window:CreateRadialMenu(config)
        config = type(config) == "table" and config or {}
        return Window:BindRadialMenu(config.Trigger or RestoreBtn, config.Items, config)
    end

    function Window:CreateSettingsTab()
        local tab = Window:CreateTab("Settings", "settings")
        tab.Btn.LayoutOrder = 9999
        tab:CreateThemeDropdown()
        return tab
    end

