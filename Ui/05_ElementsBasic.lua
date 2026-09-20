    function Window:CreateTab(name, icon)
        if type(name) == "table" then   -- รองรับ Window:Tab({Title=, Icon=}) แบบ WindUI
            local tabCfg = name
            name = tabCfg.Title or tabCfg.Name or "Tab"
            icon = icon or tabCfg.Icon
        end
        local rawTabName = name
        name = tostring(Library:Translate(name))
        local Tab = {}
        local TabBtn = Instance.new("TextButton")
        TabBtn.Size = UDim2.new(1, 0, 0, 36)
        applyThemeColor(TabBtn, "Element")
        TabBtn.BackgroundTransparency = 1
        TabBtn.AutoButtonColor = false
        TabBtn.Text = ""
        TabBtn.Parent = TabHolder
        tabOrderCounter = tabOrderCounter + 1
        TabBtn.LayoutOrder = tabOrderCounter
        corner(TabBtn, 8)
        applyPressAnimation(TabBtn, 0.96)
        ripple(TabBtn, "AccentA")

        local iconOffset = 10
        if icon then
            local IconImg = Instance.new("ImageLabel")
            IconImg.Size = UDim2.new(0, 18, 0, 18)
            IconImg.Position = UDim2.new(0, 10, 0.5, 0)
            IconImg.AnchorPoint = Vector2.new(0, 0.5)
            IconImg.BackgroundTransparency = 1
            IconImg.Image = Library.Icons[icon] or icon
            IconImg.ScaleType = Enum.ScaleType.Fit
            applyThemeColor(IconImg, "SubText", "ImageColor3")
            IconImg.Parent = TabBtn
            iconOffset = 36
        end

        local TabTitle = Instance.new("TextLabel")
        TabTitle.Size = UDim2.new(1, -iconOffset - 10, 1, 0)
        TabTitle.Position = UDim2.new(0, iconOffset, 0, 0)
        TabTitle.BackgroundTransparency = 1
        TabTitle.Text = name
        applyThemeColor(TabTitle, "SubText", "TextColor3")
        TabTitle.FontFace = UI_Font("SemiBold")
        TabTitle.TextSize = 13
        TabTitle.TextXAlignment = Enum.TextXAlignment.Left
        TabTitle.Parent = TabBtn
        if Library:IsLocalizedKey(rawTabName) then
            Library:BindLocalized(function() return TabTitle.Parent ~= nil end, function()
                name = tostring(Library:Translate(rawTabName))
                TabTitle.Text = name
                for _, e in ipairs(allTabs) do if e.btn == TabBtn then e.name = name end end
            end)
        end

        local ActiveBar = Instance.new("Frame")
        ActiveBar.Size = UDim2.new(0, 3, 0, 0)
        ActiveBar.Position = UDim2.new(0, 0, 0.5, 0)
        ActiveBar.AnchorPoint = Vector2.new(0, 0.5)
        applyThemeColor(ActiveBar, "AccentA")
        ActiveBar.BorderSizePixel = 0
        ActiveBar.Parent = TabBtn
        corner(ActiveBar, 2)
        accentGradient(ActiveBar, 90)

        table.insert(allTabs, {btn = TabBtn, name = name})
        if TabSearchBox and TabSearchBox.Text ~= "" then
            TabBtn.Visible = string.find(name:lower(), TabSearchBox.Text:lower(), 1, true) ~= nil
        end

        TabBtn.MouseEnter:Connect(function()
            if CurrentTab and CurrentTab.Btn == TabBtn then return end
            TweenService:Create(TabBtn, TI.d015_Sine_Out, {BackgroundTransparency = 0.4, BackgroundColor3 = Theme.Element}):Play()
        end)
        TabBtn.MouseLeave:Connect(function()
            if CurrentTab and CurrentTab.Btn == TabBtn then return end
            TweenService:Create(TabBtn, TI.d015_Sine_Out, {BackgroundTransparency = 1}):Play()
        end)
        -- SAFETY NET: บนมือถือบางที touch แตะ MouseEnter ติดแต่ปล่อยนิ้วแล้ว MouseLeave ไม่ยิงกลับมา
        -- (ปัญหาเดียวกับ Radial Menu ที่เจอก่อนหน้า) ทำให้ปุ่มแท็บที่ไม่ได้เลือกค้าง highlight ค้างตลอดไป
        -- ต้อง force เคลียร์ทุกครั้งที่มีนิ้วปล่อยจากจอ ถ้าแท็บนี้ไม่ใช่แท็บที่ active อยู่จริง
        UserInputService.TouchEnded:Connect(function()
            if CurrentTab and CurrentTab.Btn == TabBtn then return end
            TweenService:Create(TabBtn, TI.d015_Sine_Out, {BackgroundTransparency = 1}):Play()
        end)

        local TabContent = Instance.new("ScrollingFrame")
        TabContent.Size = UDim2.new(1, -20, 1, -20)
        TabContent.Position = UDim2.new(0, 10, 0, 10)
        TabContent.BackgroundTransparency = 1
        TabContent.ScrollBarThickness = 2
        applyThemeColor(TabContent, "AccentA", "ScrollBarImageColor3")
        TabContent.Visible = false
        TabContent.Active = true
        TabContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
        TabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
        TabContent.Parent = ContentArea
        local ContentLayout = Instance.new("UIListLayout")
        ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ContentLayout.Padding = UDim.new(0, 8)
        ContentLayout.Parent = TabContent

        -- ค่าตำแหน่ง/สเกลตั้งต้นของเนื้อหาแท็บ ใช้ตอนสลับแท็บให้เด้งเข้ามาสวยๆ
        -- (แค่ Tween ตอนคลิกครั้งเดียว ไม่มี loop ต่อเนื่อง เลยไม่กินเฟรมเรต)
        local ContentBasePos = TabContent.Position
        local ContentScale = Instance.new("UIScale")
        ContentScale.Parent = TabContent

        local function setActive(active)
            TweenService:Create(TabBtn, TI.d018_Sine_Out, {
                BackgroundTransparency = active and 0.85 or 1,
                BackgroundColor3 = active and Theme.AccentA or Theme.Element
            }):Play()
            TweenService:Create(ActiveBar, TI.d018_Sine_Out, {Size = UDim2.new(0, 3, 0, active and 20 or 0)}):Play()
            TabTitle.TextColor3 = active and Theme.Text or Theme.SubText
            if icon then
                local iconImg = TabBtn:FindFirstChildOfClass("ImageLabel")
                if iconImg then
                    TweenService:Create(iconImg, TI.d018_Sine_Out, {ImageColor3 = active and Theme.Text or Theme.SubText}):Play()
                end
            end
        end

        local function activateTab()
            if Tab.Locked then return end
            closeActivePopup()
            for _, t in ipairs(Tabs) do
                local isThis = (t.Btn == TabBtn)
                t.SetActive(isThis)
                if isThis then
                    slideIndicatorTo(t.Btn)
                    if not t.Content.Visible then
                        -- เด้งขึ้นมาจากด้านล่างนิดๆ พร้อม pop สเกล ให้รู้สึกลื่นไหลตอนสลับแท็บ
                        t.Content.Position = t.BasePos + UDim2.new(0, 0, 0, 12)
                        t.Scale.Scale = 0.96
                        t.Content.Visible = true
                        TweenService:Create(t.Content, TI.d02_Back_Out, {Position = t.BasePos}):Play()
                        TweenService:Create(t.Scale, TI.d02_Back_Out, {Scale = 1}):Play()
                    end
                else
                    t.Content.Visible = false
                end
            end
            CurrentTab = {Btn = TabBtn, Content = TabContent, SetActive = setActive}
        end
        TabBtn.MouseButton1Click:Connect(activateTab)
        Tab.Name = name
        Tab.Select = function() activateTab() end   -- เรียกได้ทั้ง tab:Select() และ tab.Select()
        function Tab:Lock(msg)
            Tab.Locked = true
            TabTitle.TextTransparency = 0.55
            return Tab
        end
        function Tab:Unlock()
            Tab.Locked = false
            TabTitle.TextTransparency = 0
            return Tab
        end
        function Tab:SetTitle(newName)
            name = tostring(Library:Translate(newName))
            Tab.Name = name
            TabTitle.Text = name
            for _, e in ipairs(allTabs) do if e.btn == TabBtn then e.name = name end end
            return Tab
        end
        function Tab:Destroy()
            for i, t in ipairs(Tabs) do if t.Btn == TabBtn then table.remove(Tabs, i) break end end
            for i, t in ipairs(allTabs) do if t.btn == TabBtn then table.remove(allTabs, i) break end end
            for i, t in ipairs(windowTabList) do if t == Tab then table.remove(windowTabList, i) break end end
            Library:UnregisterCommandsByTab(name)
            local wasCurrent = CurrentTab and CurrentTab.Btn == TabBtn
            TabBtn:Destroy()
            TabContent:Destroy()
            if wasCurrent then
                CurrentTab = nil
                if windowTabList[1] then windowTabList[1].Select() else ActiveIndicator.Visible = false end
            end
        end

        Library:RegisterCommand({
            Title = "ไปที่แท็บ: " .. name,
            SubText = "Tab",
            Icon = icon,
            TabName = name,
            Type = "Tab",
            Action = activateTab,
        })

        local function bindFlag(flag, value)
            if not flag then return end
            Library.Flags[flag] = value
            Library.FlagChanged:Fire(flag, value)
        end

        -- ============ v7: ชื่อ creator ทั้งหมด + proxy สำหรับ container (Section/Group) ============
        local CREATOR_NAMES = {"CreateSection", "CreateDivider", "CreateSpace", "CreateParagraph", "CreateAccordion", "CreateSegmentedControl",
            "CreateButton", "CreateToggle", "CreateCheckbox", "CreateSlider", "CreateDropdown", "CreateThemeDropdown", "CreateColorPicker",
            "CreateInput", "CreateKeybind", "CreateLabel", "CreateTextArea", "CreateErrorLog", "CreateProgressBar", "CreateGraph",
            "CreateRadioGroup", "CreateMultiDropdown", "CreateSearchBox", "CreateImage", "CreateCode", "CreateGroup", "CreateConfigManager"}

        -- สร้าง element ลงใน container ที่กำหนด โดยสลับ TabContent ชั่วคราวระหว่างสร้าง
        -- (ทุก creator อ้าง TabContent ตอนสร้างเท่านั้น ส่วน runtime กลับไปใช้ ScrollingFrame ตัวจริงเสมอ)
        local function withContainer(container, cname, cfg)
            local prev = TabContent
            if container then TabContent = container end
            local ok, res = pcall(Tab[cname], Tab, cfg)
            TabContent = prev
            if not ok then error(res, 0) end
            return res
        end
        local function attachCreators(target, container, after)
            for _, cname in ipairs(CREATOR_NAMES) do
                local fn = function(_, cfg)
                    local res = withContainer(container, cname, cfg)
                    if after then after() end
                    return res
                end
                target[cname] = fn
                target[string.sub(cname, 7)] = fn   -- alias แบบ WindUI: Button/Toggle/Slider/...
            end
            target.Colorpicker = target.CreateColorPicker
            target.Segmented = target.CreateSegmentedControl
            target.Radio = target.CreateRadioGroup
            target.Progress = target.CreateProgressBar
            return target
        end

        -- ============ Section: หัวข้อ (แบบเดิม) หรือ container พับได้ (Collapsible/Opened/Box) ============
        -- Tab:CreateSection("ชื่อ")                       → หัวข้อเส้นจาง เหมือนเดิม
        -- Tab:CreateSection({Title=, Desc=, Icon=, Opened=true, Box=true, Collapsible=true}) → กล่อง: section:CreateButton{...}
        function Tab:CreateSection(arg)
            local c = type(arg) == "table" and arg or {Title = arg}
            local title = tostring(Library:Translate(c.Title or c.Text or c.Name or "Section"))
            local rawDesc = c.Desc or c.Description
            local desc = rawDesc and tostring(Library:Translate(rawDesc)) or nil
            local isContainer = c.Collapsible == true or c.Opened ~= nil or c.Box == true or c.Container == true

            if not isContainer then
                local Holder = Instance.new("Frame")
                Holder.Name = "Section"
                Holder.Size = UDim2.new(1, 0, 0, desc and 38 or 24)
                Holder.BackgroundTransparency = 1
                Holder.Parent = TabContent
                local Bar = Instance.new("Frame")
                Bar.Size = UDim2.new(0, 3, 0, 12)
                Bar.Position = UDim2.new(0, 0, 0, 6)
                applyThemeColor(Bar, "AccentA")
                Bar.BorderSizePixel = 0
                Bar.Parent = Holder
                corner(Bar, 2)
                accentGradient(Bar, 90)
                local labelX = 10
                if c.Icon then
                    local Ic = Instance.new("ImageLabel")
                    Ic.Size = UDim2.new(0, 14, 0, 14)
                    Ic.Position = UDim2.new(0, 10, 0, 5)
                    Ic.BackgroundTransparency = 1
                    Ic.Image = Library.Icons[c.Icon] or normalizeAssetId(c.Icon)
                    applyThemeColor(Ic, "AccentA", "ImageColor3")
                    Ic.ScaleType = Enum.ScaleType.Fit
                    Ic.Parent = Holder
                    labelX = 30
                end
                local Label = Instance.new("TextLabel")
                Label.Size = UDim2.new(0, 0, 0, 16)
                Label.AutomaticSize = Enum.AutomaticSize.X
                Label.Position = UDim2.new(0, labelX, 0, 4)
                Label.BackgroundTransparency = 1
                Label.Text = string.upper(title)
                applyThemeColor(Label, "SubText", "TextColor3")
                Label.FontFace = UI_Font("Bold")
                Label.TextSize = 11
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.Parent = Holder
                -- เส้นจางลงทางขวาต่อจากชื่อ
                local Fade = Instance.new("Frame")
                Fade.BorderSizePixel = 0
                applyThemeColor(Fade, "Stroke")
                Fade.Parent = Holder
                local fadeGrad = Instance.new("UIGradient")
                fadeGrad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1)})
                fadeGrad.Parent = Fade
                local function relayout()
                    local w = Label.TextBounds.X
                    Fade.Position = UDim2.new(0, labelX + w + 8, 0, 12)
                    Fade.Size = UDim2.new(1, -(labelX + w + 8), 0, 1)
                end
                Label:GetPropertyChangedSignal("TextBounds"):Connect(relayout)
                relayout()
                local DescLbl
                if desc then
                    DescLbl = Instance.new("TextLabel")
                    DescLbl.Position = UDim2.new(0, 10, 0, 22)
                    DescLbl.Size = UDim2.new(1, -10, 0, 14)
                    DescLbl.BackgroundTransparency = 1
                    DescLbl.Text = desc
                    applyThemeColor(DescLbl, "SubText", "TextColor3")
                    DescLbl.FontFace = UI_Font("Medium")
                    DescLbl.TextSize = 11.5
                    DescLbl.TextTruncate = Enum.TextTruncate.AtEnd
                    DescLbl.TextXAlignment = Enum.TextXAlignment.Left
                    DescLbl.Parent = Holder
                end
                local elem = newElement(Holder, function() return title end, function(_, t) Label.Text = string.upper(tostring(t)); relayout() end)
                elem._setTitle = function(t) Label.Text = string.upper(t); relayout() end
                elem._setDesc = function(t) if DescLbl then DescLbl.Text = t end end
                if Library:IsLocalizedKey(c.Title or c.Text) then
                    local rawT = c.Title or c.Text
                    Library:BindLocalized(function() return Holder.Parent ~= nil end, function() elem._setTitle(tostring(Library:Translate(rawT))) end)
                end
                attachCreators(elem, nil)
                return elem
            end

            -- ---- container mode ----
            local boxed = c.Box ~= false
            local opened = c.Opened ~= false
            local collapsible = c.Collapsible ~= false
            local Outer = Instance.new("Frame")
            Outer.Name = "SectionBox"
            Outer.Size = UDim2.new(1, 0, 0, 0)
            Outer.AutomaticSize = Enum.AutomaticSize.Y
            if boxed then
                applyThemeColor(Outer, "Sidebar")
                Outer.BackgroundTransparency = 0.2
                Outer.Parent = TabContent
                corner(Outer, 12)
                local outerStroke = stroke(Outer, "Stroke", 1)
                outerStroke.Transparency = 0.5
            else
                Outer.BackgroundTransparency = 1
                Outer.Parent = TabContent
            end
            local oLayout = Instance.new("UIListLayout")
            oLayout.SortOrder = Enum.SortOrder.LayoutOrder
            oLayout.Parent = Outer

            local headerH = desc and 46 or 38
            local Header = Instance.new("TextButton")
            Header.Size = UDim2.new(1, 0, 0, headerH)
            Header.BackgroundTransparency = 1
            Header.AutoButtonColor = false
            Header.Text = ""
            Header.LayoutOrder = 1
            Header.Parent = Outer
            local hBar = Instance.new("Frame")
            hBar.Size = UDim2.new(0, 3, 0, 14)
            hBar.Position = UDim2.new(0, 10, 0.5, -7)
            applyThemeColor(hBar, "AccentA")
            hBar.BorderSizePixel = 0
            hBar.Parent = Header
            corner(hBar, 2)
            accentGradient(hBar, 90)
            local hx = 22
            if c.Icon then
                local Ic = Instance.new("ImageLabel")
                Ic.Size = UDim2.new(0, 16, 0, 16)
                Ic.Position = UDim2.new(0, 22, 0.5, -8)
                Ic.BackgroundTransparency = 1
                Ic.Image = Library.Icons[c.Icon] or normalizeAssetId(c.Icon)
                applyThemeColor(Ic, "AccentA", "ImageColor3")
                Ic.ScaleType = Enum.ScaleType.Fit
                Ic.Parent = Header
                hx = 44
            end
            local HTitle = Instance.new("TextLabel")
            HTitle.Position = UDim2.new(0, hx, 0, desc and 7 or 0)
            HTitle.Size = UDim2.new(1, -(hx + 34), 0, desc and 18 or headerH)
            HTitle.BackgroundTransparency = 1
            HTitle.Text = title
            applyThemeColor(HTitle, "Text", "TextColor3")
            HTitle.FontFace = UI_Font("Bold")
            HTitle.TextSize = 13.5
            HTitle.TextXAlignment = Enum.TextXAlignment.Left
            HTitle.TextTruncate = Enum.TextTruncate.AtEnd
            HTitle.Parent = Header
            local HDesc
            if desc then
                HDesc = Instance.new("TextLabel")
                HDesc.Position = UDim2.new(0, hx, 0, 25)
                HDesc.Size = UDim2.new(1, -(hx + 34), 0, 14)
                HDesc.BackgroundTransparency = 1
                HDesc.Text = desc
                applyThemeColor(HDesc, "SubText", "TextColor3")
                HDesc.FontFace = UI_Font("Medium")
                HDesc.TextSize = 11.5
                HDesc.TextXAlignment = Enum.TextXAlignment.Left
                HDesc.TextTruncate = Enum.TextTruncate.AtEnd
                HDesc.Parent = Header
            end
            local Arrow = Instance.new("ImageLabel")
            Arrow.Size = UDim2.new(0, 14, 0, 14)
            Arrow.Position = UDim2.new(1, -24, 0.5, -7)
            Arrow.BackgroundTransparency = 1
            Arrow.Image = "rbxassetid://6031091004"
            applyThemeColor(Arrow, "SubText", "ImageColor3")
            Arrow.Rotation = opened and 180 or 0
            Arrow.Visible = collapsible
            Arrow.Parent = Header

            local Body = Instance.new("Frame")
            Body.Name = "Body"
            Body.BackgroundTransparency = 1
            Body.ClipsDescendants = true
            Body.Size = UDim2.new(1, 0, 0, 0)
            Body.LayoutOrder = 2
            Body.Parent = Outer
            local bPad = Instance.new("UIPadding")
            bPad.PaddingLeft = UDim.new(0, boxed and 8 or 10)
            bPad.PaddingRight = UDim.new(0, boxed and 8 or 0)
            bPad.PaddingTop = UDim.new(0, 2)
            bPad.PaddingBottom = UDim.new(0, 8)
            bPad.Parent = Body
            local bLayout = Instance.new("UIListLayout")
            bLayout.Padding = UDim.new(0, 8)
            bLayout.SortOrder = Enum.SortOrder.LayoutOrder
            bLayout.Parent = Body

            local function bodyTarget()
                local y = bLayout.AbsoluteContentSize.Y
                if not opened or y <= 0 then return 0 end
                return y + 10
            end
            local function applyBody(animate)
                local target = UDim2.new(1, 0, 0, bodyTarget())
                if animate then
                    TweenService:Create(Body, TI.d024_Quint_Out, {Size = target}):Play()
                else
                    Body.Size = target
                end
                TweenService:Create(Arrow, TI.d022_Sine_Out, {Rotation = opened and 180 or 0}):Play()
            end
            bLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                if opened then Body.Size = UDim2.new(1, 0, 0, bodyTarget()) end
            end)
            applyBody(false)

            local elem
            local function setOpened(v, animate)
                opened = v and true or false
                applyBody(animate ~= false)
                if c.Callback then safeCallback(c.Callback, opened) end
            end
            if collapsible then
                Header.MouseButton1Click:Connect(function() setOpened(not opened, true) end)
            end
            elem = newElement(Outer, function() return opened end, function(_, v) setOpened(v, true) end)
            function elem:Open() setOpened(true, true) return elem end
            function elem:Close() setOpened(false, true) return elem end
            function elem:Toggle() setOpened(not opened, true) return elem end
            elem.Content = Body
            elem._setTitle = function(t) HTitle.Text = t end
            elem._setDesc = function(t) if HDesc then HDesc.Text = t end end
            if Library:IsLocalizedKey(c.Title or c.Text) then
                local rawT = c.Title or c.Text
                Library:BindLocalized(function() return Outer.Parent ~= nil end, function() HTitle.Text = tostring(Library:Translate(rawT)) end)
            end
            attachCreators(elem, Body)
            return elem
        end

        function Tab:CreateDivider(c)
            c = type(c) == "table" and c or {}
            local Holder = Instance.new("Frame")
            Holder.Size = UDim2.new(1, 0, 0, 20)
            Holder.BackgroundTransparency = 1
            Holder.Parent = TabContent
            local Line = Instance.new("Frame")
            Line.Size = UDim2.new(1, 0, 0, 1)
            Line.Position = UDim2.new(0, 0, 0.5, 0)
            applyThemeColor(Line, "Stroke")
            Line.BorderSizePixel = 0
            Line.Parent = Holder
            local lineGrad = Instance.new("UIGradient")
            lineGrad.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.15),
                NumberSequenceKeypoint.new(0.8, 0.15), NumberSequenceKeypoint.new(1, 1),
            })
            lineGrad.Parent = Line
            return newElement(Holder)
        end

        function Tab:CreateSpace(c)
            local h = 8
            if type(c) == "number" then h = c elseif type(c) == "table" then h = tonumber(c.Height or c.Size) or 8 end
            local Holder = Instance.new("Frame")
            Holder.Name = "Space"
            Holder.Size = UDim2.new(1, 0, 0, h)
            Holder.BackgroundTransparency = 1
            Holder.Parent = TabContent
            return newElement(Holder)
        end

        -- ============ Paragraph: Title / Desc(Text) / Icon / Image / Color / Buttons ============
        function Tab:CreateParagraph(c)
            c = type(c) == "table" and c or {}
            local titleText = c.Title and tostring(Library:Translate(c.Title)) or nil
            local bodyRaw = c.Text or c.Desc or c.Content or c.Description
            local bodyText = bodyRaw ~= nil and tostring(Library:Translate(bodyRaw)) or ((titleText == nil and not c.Image) and "Paragraph" or "")

            local tint
            if typeof(c.Color) == "Color3" then tint = c.Color
            elseif type(c.Color) == "string" then tint = (c.Color == "Accent") and Theme.AccentA or Theme[c.Color] end

            local Frame = Instance.new("Frame")
            Frame.Name = "Paragraph"
            Frame.Size = UDim2.new(1, 0, 0, 0)
            Frame.AutomaticSize = Enum.AutomaticSize.Y
            if tint then
                Frame.BackgroundColor3 = Theme.Element:Lerp(tint, 0.1)
            else
                applyThemeColor(Frame, "Element")
            end
            Frame.Parent = TabContent
            corner(Frame, 9)
            applyGlowOnHover(Frame)
            if tint then
                local ts = stroke(Frame, "Stroke", 1)
                ts.Color = tint
                ts.Transparency = 0.55
            end

            local Pad = Instance.new("UIPadding")
            Pad.PaddingLeft = UDim.new(0, 12)
            Pad.PaddingRight = UDim.new(0, 12)
            Pad.PaddingTop = UDim.new(0, 10)
            Pad.PaddingBottom = UDim.new(0, 10)
            Pad.Parent = Frame
            local Lay = Instance.new("UIListLayout")
            Lay.Padding = UDim.new(0, 6)
            Lay.SortOrder = Enum.SortOrder.LayoutOrder
            Lay.Parent = Frame

            if c.Image then
                local Img = Instance.new("ImageLabel")
                Img.Size = UDim2.new(1, 0, 0, tonumber(c.ImageHeight) or 120)
                Img.BackgroundTransparency = 1
                Img.Image = normalizeAssetId(c.Image)
                Img.ScaleType = Enum.ScaleType.Crop
                Img.LayoutOrder = 1
                Img.Parent = Frame
                corner(Img, 7)
            end

            local TitleLbl
            if titleText or c.Icon then
                local Head = Instance.new("Frame")
                Head.Size = UDim2.new(1, 0, 0, 0)
                Head.AutomaticSize = Enum.AutomaticSize.Y
                Head.BackgroundTransparency = 1
                Head.LayoutOrder = 2
                Head.Parent = Frame
                local hl = Instance.new("UIListLayout")
                hl.FillDirection = Enum.FillDirection.Horizontal
                hl.Padding = UDim.new(0, 8)
                hl.SortOrder = Enum.SortOrder.LayoutOrder
                hl.Parent = Head
                local iconW = 0
                if c.Icon then
                    local Ic = Instance.new("ImageLabel")
                    Ic.Size = UDim2.new(0, 16, 0, 16)
                    Ic.BackgroundTransparency = 1
                    Ic.Image = Library.Icons[c.Icon] or normalizeAssetId(c.Icon)
                    if tint then Ic.ImageColor3 = tint else applyThemeColor(Ic, "AccentA", "ImageColor3") end
                    Ic.ScaleType = Enum.ScaleType.Fit
                    Ic.LayoutOrder = 1
                    Ic.Parent = Head
                    iconW = 24
                end
                TitleLbl = Instance.new("TextLabel")
                TitleLbl.Size = UDim2.new(1, -iconW, 0, 0)
                TitleLbl.AutomaticSize = Enum.AutomaticSize.Y
                TitleLbl.BackgroundTransparency = 1
                TitleLbl.Text = titleText or ""
                applyThemeColor(TitleLbl, "Text", "TextColor3")
                TitleLbl.FontFace = UI_Font("Bold")
                TitleLbl.TextSize = 14
                TitleLbl.TextWrapped = true
                TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
                TitleLbl.LayoutOrder = 2
                TitleLbl.Parent = Head
            end

            local BodyLbl = Instance.new("TextLabel")
            BodyLbl.Size = UDim2.new(1, 0, 0, 0)
            BodyLbl.AutomaticSize = Enum.AutomaticSize.Y
            BodyLbl.BackgroundTransparency = 1
            BodyLbl.Text = bodyText
            BodyLbl.Visible = bodyText ~= ""
            BodyLbl.RichText = c.RichText == true
            applyThemeColor(BodyLbl, "SubText", "TextColor3")
            BodyLbl.FontFace = UI_Font("Medium")
            BodyLbl.TextSize = 13.5
            BodyLbl.LineHeight = 1.3
            BodyLbl.TextWrapped = true
            BodyLbl.TextXAlignment = Enum.TextXAlignment.Left
            BodyLbl.TextYAlignment = Enum.TextYAlignment.Top
            BodyLbl.LayoutOrder = 3
            BodyLbl.Parent = Frame

            if type(c.Buttons) == "table" and #c.Buttons > 0 then
                local Row = Instance.new("Frame")
                Row.Size = UDim2.new(1, 0, 0, 0)
                Row.AutomaticSize = Enum.AutomaticSize.Y
                Row.BackgroundTransparency = 1
                Row.LayoutOrder = 4
                Row.Parent = Frame
                local rl = Instance.new("UIListLayout")
                rl.FillDirection = Enum.FillDirection.Horizontal
                rl.Padding = UDim.new(0, 6)
                rl.SortOrder = Enum.SortOrder.LayoutOrder
                pcall(function() rl.Wraps = true end)
                rl.Parent = Row
                for idx, b in ipairs(c.Buttons) do
                    local variant = b.Variant or (idx == 1 and "Primary" or "Secondary")
                    local Btn = Instance.new("TextButton")
                    Btn.Size = UDim2.new(0, 0, 0, 28)
                    Btn.AutomaticSize = Enum.AutomaticSize.X
                    Btn.LayoutOrder = idx
                    Btn.AutoButtonColor = false
                    Btn.Text = ""
                    Btn.Parent = Row
                    corner(Btn, 7)
                    local white = false
                    if variant == "Primary" then applyThemeColor(Btn, "AccentA"); accentGradient(Btn, 100); white = true
                    elseif variant == "Danger" then applyThemeColor(Btn, "Danger"); white = true
                    else applyThemeColor(Btn, "ElementHover") end
                    local bp = Instance.new("UIPadding")
                    bp.PaddingLeft = UDim.new(0, 12)
                    bp.PaddingRight = UDim.new(0, 12)
                    bp.Parent = Btn
                    local bl = Instance.new("UIListLayout")
                    bl.FillDirection = Enum.FillDirection.Horizontal
                    bl.HorizontalAlignment = Enum.HorizontalAlignment.Center
                    bl.VerticalAlignment = Enum.VerticalAlignment.Center
                    bl.Padding = UDim.new(0, 6)
                    bl.SortOrder = Enum.SortOrder.LayoutOrder
                    bl.Parent = Btn
                    if b.Icon then
                        local BI = Instance.new("ImageLabel")
                        BI.Size = UDim2.new(0, 13, 0, 13)
                        BI.BackgroundTransparency = 1
                        BI.Image = Library.Icons[b.Icon] or normalizeAssetId(b.Icon)
                        BI.ImageColor3 = white and Color3.fromRGB(255, 255, 255) or Theme.Text
                        BI.ScaleType = Enum.ScaleType.Fit
                        BI.LayoutOrder = 1
                        BI.Parent = Btn
                    end
                    local BL = Instance.new("TextLabel")
                    BL.Size = UDim2.new(0, 0, 1, 0)
                    BL.AutomaticSize = Enum.AutomaticSize.X
                    BL.BackgroundTransparency = 1
                    BL.Text = tostring(Library:Translate(b.Title or b.Text or "OK"))
                    if white then BL.TextColor3 = Color3.fromRGB(255, 255, 255) else applyThemeColor(BL, "Text", "TextColor3") end
                    BL.FontFace = UI_Font("SemiBold")
                    BL.TextSize = 12
                    BL.LayoutOrder = 2
                    BL.Parent = Btn
                    applyPressAnimation(Btn, 0.95)
                    ripple(Btn, "AccentA")
                    Btn.MouseButton1Click:Connect(function() safeCallback(b.Callback) end)
                end
            end

            if c.Tooltip then Library:AttachTooltip(Frame, c.Tooltip) end
            local elem = newElement(Frame, function() return BodyLbl.Text end, function(_, newText)
                BodyLbl.Text = tostring(newText)
                BodyLbl.Visible = tostring(newText) ~= ""
            end)
            elem._setTitle = function(t) if TitleLbl then TitleLbl.Text = t end end
            elem._setDesc = function(t) BodyLbl.Text = t; BodyLbl.Visible = t ~= "" end
            return elem
        end

        -- ============ Checkbox (ทางเลือกของ Toggle — Toggle({Type="Checkbox"}) ก็เรียกตัวนี้) ============
        function Tab:CreateCheckbox(c)
            c = type(c) == "table" and c or {}
            local state = c.Default == true
            bindFlag(c.Flag, state)
            local Row = Instance.new("TextButton")
            Row.Size = UDim2.new(1, 0, 0, 40)
            applyThemeColor(Row, "Element")
            Row.AutoButtonColor = false
            Row.Text = ""
            Row.Parent = TabContent
            corner(Row, 9)
            applyHoverEffect(Row, "Element", "ElementHover")
            applyGlowOnHover(Row)
            applyPressAnimation(Row, 0.98)
            ripple(Row, "AccentA")

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -56, 1, 0)
            Label.Position = UDim2.new(0, 12, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = c.Text or "Checkbox"
            applyThemeColor(Label, "Text", "TextColor3")
            Label.FontFace = UI_Font("SemiBold")
            Label.TextSize = 14
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Row

            local Box = Instance.new("Frame")
            Box.Size = UDim2.new(0, 20, 0, 20)
            Box.Position = UDim2.new(1, -32, 0.5, -10)
            applyThemeColor(Box, state and "AccentA" or "ToggleOff")
            Box.Parent = Row
            corner(Box, 6)
            stroke(Box)
            local Check = Instance.new("TextLabel")
            Check.Size = UDim2.new(1, 0, 1, 0)
            Check.BackgroundTransparency = 1
            Check.Text = "✓"
            Check.TextColor3 = Color3.fromRGB(255, 255, 255)
            Check.FontFace = UI_Font("Bold")
            Check.TextSize = 14
            Check.TextTransparency = state and 0 or 1
            Check.Parent = Box

            local function applyState(newState, fire)
                state = newState and true or false
                bindFlag(c.Flag, state)
                Box:SetAttribute("ThemeKey", state and "AccentA" or "ToggleOff")
                Box:SetAttribute("ThemeBinds", "BackgroundColor3=" .. (state and "AccentA" or "ToggleOff"))
                TweenService:Create(Box, TI.d015_Sine_Out, {BackgroundColor3 = state and Theme.AccentA or Theme.ToggleOff}):Play()
                TweenService:Create(Check, TI.d015_Sine_Out, {TextTransparency = state and 0 or 1}):Play()
                if state then pulseRing(Box, "AccentA", 6) end
                if fire then
                    if c.Notify == true then
                        Library:Notify({Title = c.Text or "Checkbox", Content = state and "เปิดใช้งานแล้ว" or "ปิดใช้งานแล้ว", Type = state and "success" or "warning", Duration = 1.5})
                    end
                    safeCallback(c.Callback, state)
                end
            end
            Row.MouseButton1Click:Connect(function() applyState(not state, true) end)
            if c.Tooltip then Library:AttachTooltip(Row, c.Tooltip) end
            if c.Command ~= false then
                Library:RegisterCommand({Title = c.Text or "Checkbox", SubText = "Checkbox", TabName = name, Type = "Toggle", Action = function() applyState(not state, true) end})
            end
            return newElement(Row, function() return state end, function(_, v) applyState(v, true) end, nil, c.Flag)
        end

        -- ============ Code: บล็อกโค้ด + highlight Lua + ปุ่ม Copy ============
        function Tab:CreateCode(c)
            c = type(c) == "table" and c or {}
            local current = tostring(c.Code or c.Text or "")
            local titleText = c.Title and tostring(Library:Translate(c.Title)) or string.upper(tostring(c.Language or "lua"))
            local maxBody = tonumber(c.MaxHeight) or 240

            local Frame = Instance.new("Frame")
            Frame.Name = "Code"
            applyThemeColor(Frame, "Background")
            Frame.ClipsDescendants = true
            Frame.Parent = TabContent
            corner(Frame, 9)
            local fs = stroke(Frame, "Stroke", 1)
            fs.Transparency = 0.45

            local TitleLbl = Instance.new("TextLabel")
            TitleLbl.Position = UDim2.new(0, 12, 0, 0)
            TitleLbl.Size = UDim2.new(1, -90, 0, 30)
            TitleLbl.BackgroundTransparency = 1
            TitleLbl.Text = titleText
            applyThemeColor(TitleLbl, "SubText", "TextColor3")
            TitleLbl.FontFace = UI_Font("Bold")
            TitleLbl.TextSize = 11
            TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
            TitleLbl.TextTruncate = Enum.TextTruncate.AtEnd
            TitleLbl.Parent = Frame

            local CopyBtn = Instance.new("TextButton")
            CopyBtn.AnchorPoint = Vector2.new(1, 0.5)
            CopyBtn.Position = UDim2.new(1, -8, 0, 15)
            CopyBtn.Size = UDim2.new(0, 66, 0, 20)
            applyThemeColor(CopyBtn, "Element")
            CopyBtn.AutoButtonColor = false
            CopyBtn.Text = "Copy"
            applyThemeColor(CopyBtn, "SubText", "TextColor3")
            CopyBtn.FontFace = UI_Font("SemiBold")
            CopyBtn.TextSize = 11
            CopyBtn.Parent = Frame
            corner(CopyBtn, 6)
            applyHoverEffect(CopyBtn, "Element", "ElementHover")
            applyPressAnimation(CopyBtn, 0.94)

            local Sep = Instance.new("Frame")
            Sep.Position = UDim2.new(0, 0, 0, 30)
            Sep.Size = UDim2.new(1, 0, 0, 1)
            applyThemeColor(Sep, "Stroke")
            Sep.BackgroundTransparency = 0.5
            Sep.BorderSizePixel = 0
            Sep.Parent = Frame

            local Scroll = Instance.new("ScrollingFrame")
            Scroll.Position = UDim2.new(0, 0, 0, 31)
            Scroll.Size = UDim2.new(1, 0, 1, -31)
            Scroll.BackgroundTransparency = 1
            Scroll.BorderSizePixel = 0
            Scroll.ScrollBarThickness = 3
            applyThemeColor(Scroll, "AccentA", "ScrollBarImageColor3")
            Scroll.AutomaticCanvasSize = Enum.AutomaticSize.XY
            Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
            Scroll.ScrollingDirection = Enum.ScrollingDirection.XY
            Scroll.Parent = Frame

            local CodeLbl = Instance.new("TextLabel")
            CodeLbl.Size = UDim2.new(0, 0, 0, 0)
            CodeLbl.AutomaticSize = Enum.AutomaticSize.XY
            CodeLbl.BackgroundTransparency = 1
            CodeLbl.RichText = true
            CodeLbl.FontFace = Font.fromEnum(Enum.Font.Code)
            CodeLbl.TextSize = 12.5
            CodeLbl.TextWrapped = false
            CodeLbl.TextXAlignment = Enum.TextXAlignment.Left
            CodeLbl.TextYAlignment = Enum.TextYAlignment.Top
            applyThemeColor(CodeLbl, "Text", "TextColor3")
            CodeLbl.Parent = Scroll
            local cp = Instance.new("UIPadding")
            cp.PaddingLeft = UDim.new(0, 12)
            cp.PaddingRight = UDim.new(0, 12)
            cp.PaddingTop = UDim.new(0, 10)
            cp.PaddingBottom = UDim.new(0, 10)
            cp.Parent = CodeLbl

            local function fit()
                local body = math.min(math.max(CodeLbl.TextBounds.Y + 20, 40), maxBody)
                Frame.Size = UDim2.new(1, 0, 0, 31 + body)
            end
            local function render(text)
                current = tostring(text)
                local shown = string.gsub(current, "\t", "    ")
                if c.Highlight == false then
                    CodeLbl.Text = xmlEscape(shown)
                else
                    local okh, res = pcall(highlightLua, shown)
                    CodeLbl.Text = okh and res or xmlEscape(shown)
                end
                local _, lines = string.gsub(shown, "\n", "\n")
                Frame.Size = UDim2.new(1, 0, 0, 31 + math.min((lines + 1) * 16 + 20, maxBody))
                task.defer(fit)
            end
            CodeLbl:GetPropertyChangedSignal("TextBounds"):Connect(fit)
            render(current)

            CopyBtn.MouseButton1Click:Connect(function()
                local ok = copyToClipboard(current)
                CopyBtn.Text = ok and "Copied!" or "No clipboard"
                task.delay(1.2, function() if CopyBtn.Parent then CopyBtn.Text = "Copy" end end)
            end)
            if c.Tooltip then Library:AttachTooltip(Frame, c.Tooltip) end
            local elem = newElement(Frame, function() return current end, function(_, t) render(t) end)
            elem._setTitle = function(t) TitleLbl.Text = t end
            return elem
        end

        -- ============ Group: เรียง element แนวนอนเท่าๆ กัน (เหมาะกับ Button/Toggle/Checkbox) ============
        function Tab:CreateGroup(c)
            c = type(c) == "table" and c or {}
            local gap = tonumber(c.Gap) or 8
            local Row = Instance.new("Frame")
            Row.Name = "Group"
            Row.BackgroundTransparency = 1
            Row.Size = UDim2.new(1, 0, 0, 0)
            Row.AutomaticSize = Enum.AutomaticSize.Y
            Row.Parent = TabContent
            local rl = Instance.new("UIListLayout")
            rl.FillDirection = Enum.FillDirection.Horizontal
            rl.Padding = UDim.new(0, gap)
            rl.SortOrder = Enum.SortOrder.LayoutOrder
            rl.Parent = Row
            local function relayout()
                local kids = {}
                for _, ch in ipairs(Row:GetChildren()) do
                    if ch:IsA("GuiObject") then kids[#kids + 1] = ch end
                end
                local n = #kids
                if n == 0 then return end
                local sub = math.floor(gap * (n - 1) / n)
                for i, ch in ipairs(kids) do
                    ch.LayoutOrder = i
                    local sz = ch.Size
                    ch.Size = UDim2.new(1 / n, -sub, sz.Y.Scale, sz.Y.Offset)
                end
            end
            local elem = newElement(Row)
            attachCreators(elem, Row, relayout)
            return elem
        end

        -- ============ Accordion: หัวข้อกดขยาย/ย่อ พร้อมลูกศรหมุนและความสูงเด้งสปริง ============
        function Tab:CreateAccordion(c)
            c = type(c) == "table" and c or {}
            local expanded = c.Expanded or false

            local Holder = Instance.new("Frame")
            Holder.Size = UDim2.new(1, 0, 0, 40)
            applyThemeColor(Holder, "Element")
            Holder.ClipsDescendants = true
            Holder.Parent = TabContent
            corner(Holder, 9)
            applyGlowOnHover(Holder)

            local Header = Instance.new("TextButton")
            Header.Size = UDim2.new(1, 0, 0, 40)
            Header.BackgroundTransparency = 1
            Header.AutoButtonColor = false
            Header.Text = ""
            Header.Parent = Holder
            ripple(Header, "AccentA")

            local Arrow = Instance.new("ImageLabel")
            Arrow.Size = UDim2.new(0, 14, 0, 14)
            Arrow.Position = UDim2.new(1, -22, 0, 13)
            Arrow.BackgroundTransparency = 1
            Arrow.Image = "rbxassetid://6031091004"
            applyThemeColor(Arrow, "SubText", "ImageColor3")
            Arrow.Rotation = expanded and 180 or 0
            Arrow.Parent = Header

            local TitleLbl = Instance.new("TextLabel")
            TitleLbl.Size = UDim2.new(1, -46, 0, 40)
            TitleLbl.Position = UDim2.new(0, 12, 0, 0)
            TitleLbl.BackgroundTransparency = 1
            TitleLbl.Text = c.Title or "Accordion"
            applyThemeColor(TitleLbl, "Text", "TextColor3")
            TitleLbl.FontFace = UI_Font("SemiBold")
            TitleLbl.TextSize = 14
            TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
            TitleLbl.Parent = Header

            local Body = Instance.new("TextLabel")
            Body.Size = UDim2.new(1, -24, 0, 0)
            Body.Position = UDim2.new(0, 12, 0, 40)
            Body.BackgroundTransparency = 1
            Body.Text = c.Content or ""
            applyThemeColor(Body, "SubText", "TextColor3")
            Body.FontFace = UI_Font("Medium")
            Body.TextSize = 13.5
            Body.LineHeight = 1.3
            Body.TextWrapped = true
            Body.TextXAlignment = Enum.TextXAlignment.Left
            Body.TextYAlignment = Enum.TextYAlignment.Top
            Body.TextTransparency = 1
            Body.Parent = Holder

            local bodyHeight = 0
            local function setExpanded(newExpanded, animate)
                expanded = newExpanded
                Body.Size = UDim2.new(1, -24, 0, bodyHeight)
                local targetH = expanded and (48 + bodyHeight) or 40
                local tw = animate ~= false and TI.d028_Back_Out_Wobble or TweenInfo.new(0)
                TweenService:Create(Holder, tw, {Size = UDim2.new(1, 0, 0, targetH)}):Play()
                TweenService:Create(Arrow, TI.d022_Sine_Out, {Rotation = expanded and 180 or 0}):Play()
                TweenService:Create(Body, TI.d022_Sine_Out, {TextTransparency = expanded and 0 or 1}):Play()
            end

            task.defer(function()
                bodyHeight = Body.TextBounds.Y + 6
                setExpanded(expanded, false)
            end)

            Header.MouseButton1Click:Connect(function() setExpanded(not expanded, true) end)
            return newElement(Holder, function() return expanded end, function(_, v) setExpanded(v, true) end)
        end

        -- ============ Segmented Control: ปุ่มเลือกตัวเลือกแบบแคปซูล มีแท่งไฮไลต์เลื่อนตามสปริง ============
        function Tab:CreateSegmentedControl(c)
            c = type(c) == "table" and c or {}
            local options = c.Options or {"A", "B"}
            local selected = math.clamp(c.Default or 1, 1, #options)
            bindFlag(c.Flag, options[selected])

            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, 0, 0, c.Text and 62 or 38)
            applyThemeColor(Frame, "Element")
            Frame.Parent = TabContent
            corner(Frame, 9)

            local yOffset = 0
            if c.Text then
                local Label = Instance.new("TextLabel")
                Label.Size = UDim2.new(1, -24, 0, 18)
                Label.Position = UDim2.new(0, 12, 0, 6)
                Label.BackgroundTransparency = 1
                Label.Text = c.Text
                applyThemeColor(Label, "SubText", "TextColor3")
                Label.FontFace = UI_Font("SemiBold")
                Label.TextSize = 12
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.Parent = Frame
                yOffset = 24
            end

            local Track = Instance.new("Frame")
            Track.Size = UDim2.new(1, -12, 0, 30)
            Track.Position = UDim2.new(0, 6, 0, yOffset + 4)
            applyThemeColor(Track, "Background")
            Track.Parent = Frame
            corner(Track, 8)

            local Pill = Instance.new("Frame")
            Pill.Size = UDim2.new(1 / #options, 0, 1, 0)
            Pill.Position = UDim2.new((selected - 1) / #options, 0, 0, 0)
            applyThemeColor(Pill, "AccentA")
            Pill.ZIndex = 1
            Pill.Parent = Track
            corner(Pill, 7)
            accentGradient(Pill, 0)

            local buttons = {}
            for i, optText in ipairs(options) do
                local OptBtn = Instance.new("TextButton")
                OptBtn.Size = UDim2.new(1 / #options, 0, 1, 0)
                OptBtn.Position = UDim2.new((i - 1) / #options, 0, 0, 0)
                OptBtn.BackgroundTransparency = 1
                OptBtn.AutoButtonColor = false
                OptBtn.Text = tostring(optText)
                OptBtn.FontFace = UI_Font("SemiBold")
                OptBtn.TextSize = 12
                OptBtn.ZIndex = 2
                applyThemeColor(OptBtn, i == selected and "Text" or "SubText", "TextColor3")
                OptBtn.Parent = Track
                buttons[i] = OptBtn
            end

            local function setSelected(i, fireCallback)
                selected = i
                bindFlag(c.Flag, options[i])
                TweenService:Create(Pill, TI.d028_Back_Out_Wobble, {Position = UDim2.new((i - 1) / #options, 0, 0, 0)}):Play()
                for idx, btn in ipairs(buttons) do
                    TweenService:Create(btn, TI.d018_Sine_Out, {TextColor3 = idx == i and Theme.Text or Theme.SubText}):Play()
                end
                if fireCallback then safeCallback(c.Callback, options[i], i) end
            end

            for i, btn in ipairs(buttons) do
                btn.MouseButton1Click:Connect(function() setSelected(i, true) end)
            end

            return newElement(Frame, function() return options[selected] end, function(_, v)
                for i, o in ipairs(options) do
                    if o == v then setSelected(i, true) break end
                end
            end, nil, c.Flag)
        end

        function Tab:CreateButton(c)
            c = type(c) == "table" and c or {}
            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, 0, 0, 40)
            applyThemeColor(Btn, "Element")
            Btn.AutoButtonColor = false
            Btn.Text = ""
            Btn.Parent = TabContent
            corner(Btn, 9)
            applyHoverEffect(Btn, "Element", "ElementHover")
            applyGlowOnHover(Btn)
            applyPressAnimation(Btn)
            ripple(Btn, "AccentA")

            local iconOffset = 12
            if c.Icon then
                local IconImg = Instance.new("ImageLabel")
                IconImg.Size = UDim2.new(0, 18, 0, 18)
                IconImg.Position = UDim2.new(0, 12, 0.5, 0)
                IconImg.AnchorPoint = Vector2.new(0, 0.5)
                IconImg.BackgroundTransparency = 1
                IconImg.Image = Library.Icons[c.Icon] or c.Icon
                IconImg.ScaleType = Enum.ScaleType.Fit
                applyThemeColor(IconImg, "SubText", "ImageColor3")
                IconImg.Parent = Btn
                iconOffset = 38
            end

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -iconOffset - 12, 1, 0)
            Label.Position = UDim2.new(0, iconOffset, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = c.Text or "Button"
            applyThemeColor(Label, "Text", "TextColor3")
            Label.FontFace = UI_Font("SemiBold")
            Label.TextSize = 14
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Btn

            local debounceUntil = 0
            local function runButtonAction()
                local now = os.clock()
                if now < debounceUntil then return end
                debounceUntil = now + (c.Debounce or 0.3)

                if c.Notify ~= false then
                    Library:Notify({
                        Title = c.Text or "Button",
                        Content = c.NotifyText or "กดใช้งานเรียบร้อย",
                        Type = "info",
                        Duration = 1.5
                    })
                end
                safeCallback(c.Callback)
            end
            Btn.MouseButton1Click:Connect(runButtonAction)
            if c.Tooltip then Library:AttachTooltip(Btn, c.Tooltip) end

            if c.Command ~= false then
                Library:RegisterCommand({
                    Title = c.Text or "Button",
                    SubText = "Button",
                    Icon = c.Icon,
                    TabName = name,
                    Type = "Button",
                    Action = runButtonAction,
                })
            end
            return newElement(Btn, nil, function(_, newText) Label.Text = newText end)
        end

