        -- ============ ERROR LOG PANEL ============
        -- แผงแสดง error ล่าสุดจาก Library.ErrorLog สดๆ (อัปเดตอัตโนมัติทุกครั้งที่มี error ใหม่)
        -- ใช้วางไว้ในแท็บ Settings/Misc เพื่อ "รู้ตัว" ว่าฟีเจอร์ไหนพังโดยไม่ต้องเปิด console ดู
        function Tab:CreateErrorLog(c)
            c = type(c) == "table" and c or {}
            local maxShow = c.MaxShow or 8

            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, 0, 0, 0)
            Frame.AutomaticSize = Enum.AutomaticSize.Y
            applyThemeColor(Frame, "Element")
            Frame.Parent = TabContent
            corner(Frame, 9)

            local Pad = Instance.new("UIPadding")
            Pad.PaddingLeft = UDim.new(0, 12); Pad.PaddingRight = UDim.new(0, 12)
            Pad.PaddingTop = UDim.new(0, 10); Pad.PaddingBottom = UDim.new(0, 10)
            Pad.Parent = Frame

            local Layout = Instance.new("UIListLayout")
            Layout.SortOrder = Enum.SortOrder.LayoutOrder
            Layout.Padding = UDim.new(0, 6)
            Layout.Parent = Frame

            local Header = Instance.new("Frame")
            Header.Size = UDim2.new(1, 0, 0, 24)
            Header.BackgroundTransparency = 1
            Header.Parent = Frame

            local TitleLbl = Instance.new("TextLabel")
            TitleLbl.Size = UDim2.new(1, -70, 1, 0)
            TitleLbl.BackgroundTransparency = 1
            TitleLbl.Text = c.Text or "Error Log"
            applyThemeColor(TitleLbl, "Text", "TextColor3")
            TitleLbl.FontFace = UI_Font("Bold")
            TitleLbl.TextSize = 14
            TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
            TitleLbl.Parent = Header

            local CopyBtn = Instance.new("TextButton")
            CopyBtn.Size = UDim2.new(0, 60, 0, 22)
            CopyBtn.Position = UDim2.new(1, -60, 0.5, -11)
            applyThemeColor(CopyBtn, "Background")
            CopyBtn.AutoButtonColor = false
            CopyBtn.Text = "Copy"
            applyThemeColor(CopyBtn, "SubText", "TextColor3")
            CopyBtn.FontFace = UI_Font("SemiBold")
            CopyBtn.TextSize = 12
            CopyBtn.Parent = Header
            corner(CopyBtn, 6)
            applyHoverEffect(CopyBtn, "Background", "ElementHover")

            local ListHolder = Instance.new("Frame")
            ListHolder.Size = UDim2.new(1, 0, 0, 0)
            ListHolder.AutomaticSize = Enum.AutomaticSize.Y
            ListHolder.BackgroundTransparency = 1
            ListHolder.Parent = Frame
            local ListLayout = Instance.new("UIListLayout")
            ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            ListLayout.Padding = UDim.new(0, 4)
            ListLayout.Parent = ListHolder

            local EmptyLbl = Instance.new("TextLabel")
            EmptyLbl.Size = UDim2.new(1, 0, 0, 20)
            EmptyLbl.BackgroundTransparency = 1
            EmptyLbl.Text = "ยังไม่มี error — ทุกอย่างโอเค"
            applyThemeColor(EmptyLbl, "SubText", "TextColor3")
            EmptyLbl.FontFace = UI_Font("SemiBold")
            EmptyLbl.TextSize = 12
            EmptyLbl.TextXAlignment = Enum.TextXAlignment.Left
            EmptyLbl.Parent = ListHolder

            local function fmtEntry(e)
                return string.format("[%s] %s: %s", os.date("%H:%M:%S", e.time), e.source, e.message)
            end

            local function refresh()
                for _, child in ipairs(ListHolder:GetChildren()) do
                    if child ~= EmptyLbl and not child:IsA("UIListLayout") then child:Destroy() end
                end
                local log = Library:GetErrorLog()
                EmptyLbl.Visible = #log == 0
                for i = 1, math.min(#log, maxShow) do
                    local e = log[i]
                    local row = Instance.new("TextLabel")
                    row.Size = UDim2.new(1, 0, 0, 0)
                    row.AutomaticSize = Enum.AutomaticSize.Y
                    row.BackgroundTransparency = 1
                    row.Text = fmtEntry(e)
                    row.TextWrapped = true
                    applyThemeColor(row, "Danger", "TextColor3")
                    row.Font = Enum.Font.Code
                    row.TextSize = 12
                    row.LineHeight = 1.25
                    row.TextXAlignment = Enum.TextXAlignment.Left
                    row.LayoutOrder = i
                    row.Parent = ListHolder
                end
            end
            refresh()

            local changedConn = Library.ErrorLogChanged.Event:Connect(function()
                refresh()
            end)
            Frame.Destroying:Connect(function() changedConn:Disconnect() end) -- กัน connection ค้างเวลา Tab:Clear() ทำลาย Frame ตรงๆ

            CopyBtn.MouseButton1Click:Connect(function()
                local text = Library:ExportErrorLog()
                local copied = false
                if type(setclipboard) == "function" then
                    copied = pcall(setclipboard, text)
                end
                safeNotify({
                    Title = c.Text or "Error Log",
                    Content = (text == "" and "ไม่มี log ให้คัดลอก") or (copied and "คัดลอก log แล้ว" or "executor นี้ไม่รองรับ copy อัตโนมัติ"),
                    Type = copied and "success" or "warning",
                    Duration = 2
                })
            end)

            return newElement(Frame, function() return Library:GetErrorLog() end, function() refresh() end)
        end

        function Tab:CreateProgressBar(c)
            c = type(c) == "table" and c or {}
            local min, max = c.Min or 0, c.Max or 100
            local val = math.clamp(c.Default or min, min, max)

            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, 0, 0, 44)
            applyThemeColor(Frame, "Element")
            Frame.Parent = TabContent
            corner(Frame, 9)

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -20, 0, 18)
            Label.Position = UDim2.new(0, 10, 0, 4)
            Label.BackgroundTransparency = 1
            Label.Text = c.Text or "Progress"
            applyThemeColor(Label, "Text", "TextColor3")
            Label.FontFace = UI_Font("SemiBold")
            Label.TextSize = 13
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Frame

            local Bar = Instance.new("Frame")
            Bar.Size = UDim2.new(1, -20, 0, 8)
            Bar.Position = UDim2.new(0, 10, 0, 26)
            applyThemeColor(Bar, "Background")
            Bar.Parent = Frame
            corner(Bar, 4)

            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new(max > min and (val - min) / (max - min) or 0, 0, 1, 0)
            applyThemeColor(Fill, "AccentA")
            Fill.Parent = Bar
            corner(Fill, 4)
            accentGradient(Fill, 0)

            local function setValue(newVal)
                newVal = math.clamp(newVal, min, max)
                val = newVal
                local percent = max > min and (val - min) / (max - min) or 0
                TweenService:Create(Fill, TI.d02_Sine_Out, {Size = UDim2.new(percent, 0, 1, 0)}):Play()
            end

            return newElement(Frame, function() return val end, function(_, newVal) setValue(newVal) end)
        end

        -- ============ LIVE GRAPH: กราฟเส้นเรียลไทม์ (FPS/Ping/ค่าที่กำหนดเอง) วาดด้วย Frame ล้วนๆ ไม่พึ่ง Drawing API ============
        -- ใช้ได้ 2 แบบ: (1) push ค่าเองผ่าน graph:Push(value) เช่นตอนมี event ยิงมา
        --              (2) ให้ระบบ sample ให้อัตโนมัติทุก c.Interval วิ ผ่าน c.GetValue = function() return currentValue end
        function Tab:CreateGraph(c)
            c = type(c) == "table" and c or {}
            local maxPoints = c.MaxPoints or 40
            local plotHeight = c.Height or 90
            local suffix = c.Suffix or ""
            local places = c.Places or 0
            local fixedMin, fixedMax = c.Min, c.Max

            local values = {}
            if type(c.Default) == "table" then
                for _, v in ipairs(c.Default) do table.insert(values, v) end
            end

            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, 0, 0, plotHeight + 44)
            applyThemeColor(Frame, "Element")
            Frame.Parent = TabContent
            corner(Frame, 9)
            applyGlowOnHover(Frame)

            local Header = Instance.new("Frame")
            Header.Size = UDim2.new(1, -20, 0, 22)
            Header.Position = UDim2.new(0, 10, 0, 8)
            Header.BackgroundTransparency = 1
            Header.Parent = Frame

            local TitleLbl = Instance.new("TextLabel")
            TitleLbl.Size = UDim2.new(0.6, 0, 1, 0)
            TitleLbl.BackgroundTransparency = 1
            TitleLbl.Text = c.Text or "Graph"
            applyThemeColor(TitleLbl, "Text", "TextColor3")
            TitleLbl.FontFace = UI_Font("SemiBold")
            TitleLbl.TextSize = 13
            TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
            TitleLbl.Parent = Header

            local ValueLbl = Instance.new("TextLabel")
            ValueLbl.AnchorPoint = Vector2.new(1, 0)
            ValueLbl.Position = UDim2.new(1, 0, 0, 0)
            ValueLbl.Size = UDim2.new(0.4, 0, 1, 0)
            ValueLbl.BackgroundTransparency = 1
            ValueLbl.Text = "--"
            applyThemeColor(ValueLbl, "AccentA", "TextColor3")
            ValueLbl.FontFace = UI_Font("Bold")
            ValueLbl.TextSize = 14
            ValueLbl.TextXAlignment = Enum.TextXAlignment.Right
            ValueLbl.Parent = Header

            local PlotArea = Instance.new("Frame")
            PlotArea.Size = UDim2.new(1, -20, 0, plotHeight)
            PlotArea.Position = UDim2.new(0, 10, 0, 34)
            applyThemeColor(PlotArea, "Background")
            PlotArea.ClipsDescendants = true
            PlotArea.Parent = Frame
            corner(PlotArea, 8)

            -- เส้นกริดแนวนอนบางๆ ไว้กะระดับค่าคร่าวๆ
            for i = 1, 3 do
                local grid = Instance.new("Frame")
                grid.Size = UDim2.new(1, 0, 0, 1)
                grid.Position = UDim2.new(0, 0, i / 4, 0)
                applyThemeColor(grid, "Stroke")
                grid.BackgroundTransparency = 0.6
                grid.BorderSizePixel = 0
                grid.Parent = PlotArea
            end

            local segmentsFolder = Instance.new("Frame")
            segmentsFolder.BackgroundTransparency = 1
            segmentsFolder.Size = UDim2.new(1, 0, 1, 0)
            segmentsFolder.ZIndex = 2
            segmentsFolder.Parent = PlotArea

            local dotFolder = Instance.new("Frame")
            dotFolder.BackgroundTransparency = 1
            dotFolder.Size = UDim2.new(1, 0, 1, 0)
            dotFolder.ZIndex = 3
            dotFolder.Parent = PlotArea

            local segmentPool = {}
            local lastSegCount = 0
            local endDot

            local function getSegment(i)
                local seg = segmentPool[i]
                if not seg then
                    seg = Instance.new("Frame")
                    seg.AnchorPoint = Vector2.new(0, 0.5)
                    seg.BorderSizePixel = 0
                    applyThemeColor(seg, "AccentA")
                    seg.ZIndex = 2
                    seg.Parent = segmentsFolder
                    corner(seg, 2)
                    segmentPool[i] = seg
                end
                return seg
            end

            local function redraw()
                local n = #values
                local w, h = PlotArea.AbsoluteSize.X, PlotArea.AbsoluteSize.Y
                if n == 0 or w <= 0 or h <= 0 then
                    for _, seg in pairs(segmentPool) do seg.Visible = false end
                    if endDot then endDot.Visible = false end
                    return
                end

                local lo, hi
                if fixedMin and fixedMax then
                    lo, hi = fixedMin, fixedMax
                else
                    lo, hi = values[1], values[1]
                    for _, v in ipairs(values) do
                        if v < lo then lo = v end
                        if v > hi then hi = v end
                    end
                    if hi - lo < 1e-6 then hi = lo + 1 end
                    local pad = (hi - lo) * 0.12 -- เผื่อขอบบน-ล่างนิดหน่อย กันเส้นกราฟชิดขอบเกินไป
                    lo, hi = lo - pad, hi + pad
                end

                local function pointAt(i)
                    local x = (n == 1) and w or (w * (i - 1) / (n - 1))
                    local ratio = math.clamp((values[i] - lo) / (hi - lo), 0, 1)
                    return x, h - ratio * h
                end

                for i = 1, n - 1 do
                    local x1, y1 = pointAt(i)
                    local x2, y2 = pointAt(i + 1)
                    local seg = getSegment(i)
                    local dx, dy = x2 - x1, y2 - y1
                    local len = math.sqrt(dx * dx + dy * dy)
                    seg.Visible = true
                    seg.Size = UDim2.new(0, math.max(len, 1), 0, 2)
                    seg.Position = UDim2.new(0, x1, 0, y1)
                    seg.Rotation = math.deg(math.atan2(dy, dx))
                end
                for i = n, lastSegCount do
                    if segmentPool[i] then segmentPool[i].Visible = false end
                end
                lastSegCount = math.max(n - 1, 0)

                if not endDot then
                    endDot = Instance.new("Frame")
                    endDot.AnchorPoint = Vector2.new(0.5, 0.5)
                    endDot.Size = UDim2.new(0, 8, 0, 8)
                    applyThemeColor(endDot, "AccentA")
                    endDot.ZIndex = 3
                    endDot.Parent = dotFolder
                    corner(endDot, 4)
                    local dotGlow = Instance.new("UIStroke")
                    dotGlow.Thickness = 3
                    applyThemeColor(dotGlow, "AccentA", "Color")
                    dotGlow.Transparency = 0.6
                    dotGlow.Parent = endDot
                end
                local lastX, lastY = pointAt(n)
                endDot.Visible = true
                endDot.Position = UDim2.new(0, lastX, 0, lastY)

                ValueLbl.Text = string.format("%." .. places .. "f", values[n]) .. suffix
            end

            local function pushValue(v, fireCallback)
                table.insert(values, v)
                while #values > maxPoints do table.remove(values, 1) end
                redraw()
                if fireCallback then safeCallback(c.Callback, v) end
            end

            PlotArea:GetPropertyChangedSignal("AbsoluteSize"):Connect(redraw)
            task.defer(redraw)

            local sampleConn
            if type(c.GetValue) == "function" then
                local interval = c.Interval or 0.5
                local accum = 0
                sampleConn = RunService.Heartbeat:Connect(function(dt)
                    accum += dt
                    if accum >= interval then
                        accum = 0
                        local ok, v = pcall(c.GetValue)
                        if ok and type(v) == "number" then pushValue(v, false) end
                    end
                end)
            end

            local elem = newElement(Frame, function() return values end, function(_, v)
                if type(v) == "table" then values = v; redraw()
                elseif type(v) == "number" then pushValue(v, false) end
            end)
            local baseDestroy = elem.Destroy
            elem.Destroy = function()
                if sampleConn then sampleConn:Disconnect() end
                baseDestroy()
            end
            function elem:Push(v) pushValue(v, true) end
            function elem:Clear() values = {}; redraw() end
            return elem
        end

        function Tab:CreateRadioGroup(c)
            c = type(c) == "table" and c or {}
            c.Options = (type(c.Options) == "table" and #c.Options > 0) and c.Options or {"Option 1"}
            local selected = c.Default or c.Options[1]
            bindFlag(c.Flag, selected)

            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, 0, 0, 0)
            Frame.AutomaticSize = Enum.AutomaticSize.Y
            applyThemeColor(Frame, "Element")
            Frame.Parent = TabContent
            corner(Frame, 9)

            local Pad = Instance.new("UIPadding")
            Pad.PaddingLeft = UDim.new(0, 10); Pad.PaddingRight = UDim.new(0, 10)
            Pad.PaddingTop = UDim.new(0, 8); Pad.PaddingBottom = UDim.new(0, 8)
            Pad.Parent = Frame

            local Layout = Instance.new("UIListLayout")
            Layout.SortOrder = Enum.SortOrder.LayoutOrder
            Layout.Padding = UDim.new(0, 6)
            Layout.Parent = Frame

            if c.Text then
                local TitleLbl = Instance.new("TextLabel")
                TitleLbl.Size = UDim2.new(1, 0, 0, 18)
                TitleLbl.BackgroundTransparency = 1
                TitleLbl.Text = c.Text
                applyThemeColor(TitleLbl, "Text", "TextColor3")
                TitleLbl.FontFace = UI_Font("SemiBold")
                TitleLbl.TextSize = 13
                TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
                TitleLbl.Parent = Frame
            end

            local circles = {}
            local function refresh()
                for opt, circle in pairs(circles) do
                    local isSel = (opt == selected)
                    TweenService:Create(circle, TI.d015_Sine_Out, {BackgroundColor3 = isSel and Theme.AccentA or Theme.ToggleOff}):Play()
                end
            end

            for _, opt in ipairs(c.Options) do
                local Row = Instance.new("TextButton")
                Row.Size = UDim2.new(1, 0, 0, 26)
                Row.BackgroundTransparency = 1
                Row.AutoButtonColor = false
                Row.Text = ""
                Row.Parent = Frame

                local Circle = Instance.new("Frame")
                Circle.Size = UDim2.new(0, 16, 0, 16)
                Circle.Position = UDim2.new(0, 0, 0.5, -8)
                applyThemeColor(Circle, (opt == selected) and "AccentA" or "ToggleOff")
                Circle.Parent = Row
                corner(Circle, 8)
                stroke(Circle)
                local Dot = Instance.new("Frame")
                Dot.Size = UDim2.new(0, 6, 0, 6)
                Dot.AnchorPoint = Vector2.new(0.5, 0.5)
                Dot.Position = UDim2.new(0.5, 0, 0.5, 0)
                Dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Dot.Parent = Circle
                corner(Dot, 3)

                local OptLabel = Instance.new("TextLabel")
                OptLabel.Size = UDim2.new(1, -26, 1, 0)
                OptLabel.Position = UDim2.new(0, 26, 0, 0)
                OptLabel.BackgroundTransparency = 1
                OptLabel.Text = opt
                applyThemeColor(OptLabel, "Text", "TextColor3")
                OptLabel.FontFace = UI_Font("SemiBold")
                OptLabel.TextSize = 13
                OptLabel.TextXAlignment = Enum.TextXAlignment.Left
                OptLabel.Parent = Row

                circles[opt] = Circle
                Row.MouseButton1Click:Connect(function()
                    selected = opt
                    bindFlag(c.Flag, selected)
                    refresh()
                    safeCallback(c.Callback, opt)
                end)
            end

            return newElement(Frame, function() return selected end, function(_, newVal)
                selected = newVal; bindFlag(c.Flag, selected); refresh()
                safeCallback(c.Callback, newVal)
            end, nil, c.Flag)
        end

        function Tab:CreateMultiDropdown(c)
            c = type(c) == "table" and c or {}
            c.Options = (type(c.Options) == "table" and #c.Options > 0) and c.Options or {"Option 1"}
            local selected = {}
            if type(c.Default) == "table" then
                for _, v in ipairs(c.Default) do selected[v] = true end
            end
            local function getList()
                local list = {}
                for _, opt in ipairs(c.Options) do
                    if selected[opt] then table.insert(list, opt) end
                end
                return list
            end
            bindFlag(c.Flag, getList())

            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, 0, 0, 0)
            Frame.AutomaticSize = Enum.AutomaticSize.Y
            applyThemeColor(Frame, "Element")
            Frame.Parent = TabContent
            corner(Frame, 9)

            local Pad = Instance.new("UIPadding")
            Pad.PaddingLeft = UDim.new(0, 10); Pad.PaddingRight = UDim.new(0, 10)
            Pad.PaddingTop = UDim.new(0, 8); Pad.PaddingBottom = UDim.new(0, 8)
            Pad.Parent = Frame

            local Layout = Instance.new("UIListLayout")
            Layout.SortOrder = Enum.SortOrder.LayoutOrder
            Layout.Padding = UDim.new(0, 6)
            Layout.Parent = Frame

            if c.Text then
                local TitleLbl = Instance.new("TextLabel")
                TitleLbl.Size = UDim2.new(1, 0, 0, 18)
                TitleLbl.BackgroundTransparency = 1
                TitleLbl.Text = c.Text
                applyThemeColor(TitleLbl, "Text", "TextColor3")
                TitleLbl.FontFace = UI_Font("SemiBold")
                TitleLbl.TextSize = 13
                TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
                TitleLbl.Parent = Frame
            end

            local boxes = {}
            local function fireCallback()
                local list = getList()
                bindFlag(c.Flag, list)
                safeCallback(c.Callback, list)
            end

            for _, opt in ipairs(c.Options) do
                local Row = Instance.new("TextButton")
                Row.Size = UDim2.new(1, 0, 0, 26)
                Row.BackgroundTransparency = 1
                Row.AutoButtonColor = false
                Row.Text = ""
                Row.Parent = Frame
                corner(Row, 6)
                applyHoverEffect(Row, "Element", "ElementHover") -- เดิมแถวไม่มี feedback ตอน hover เลย ทำให้รู้สึกดิบๆ

                local CheckBox = Instance.new("Frame")
                CheckBox.Size = UDim2.new(0, 16, 0, 16)
                CheckBox.Position = UDim2.new(0, 0, 0.5, -8)
                applyThemeColor(CheckBox, selected[opt] and "AccentA" or "ToggleOff")
                CheckBox.Parent = Row
                corner(CheckBox, 4)
                stroke(CheckBox)
                local cbScale = Instance.new("UIScale")
                cbScale.Parent = CheckBox

                local Check = Instance.new("ImageLabel")
                Check.Size = UDim2.new(1, -4, 1, -4)
                Check.AnchorPoint = Vector2.new(0.5, 0.5)
                Check.Position = UDim2.new(0.5, 0, 0.5, 0)
                Check.BackgroundTransparency = 1
                Check.Image = Library.Icons.check
                Check.ImageColor3 = Color3.fromRGB(255, 255, 255)
                Check.ImageTransparency = selected[opt] and 0 or 1
                Check.ScaleType = Enum.ScaleType.Fit
                Check.Parent = CheckBox

                local OptLabel = Instance.new("TextLabel")
                OptLabel.Size = UDim2.new(1, -26, 1, 0)
                OptLabel.Position = UDim2.new(0, 26, 0, 0)
                OptLabel.BackgroundTransparency = 1
                OptLabel.Text = opt
                applyThemeColor(OptLabel, "Text", "TextColor3")
                OptLabel.FontFace = UI_Font("SemiBold")
                OptLabel.TextSize = 13
                OptLabel.TextXAlignment = Enum.TextXAlignment.Left
                OptLabel.Parent = Row

                boxes[opt] = {Box = CheckBox, Check = Check}
                Row.MouseButton1Click:Connect(function()
                    selected[opt] = not selected[opt]
                    TweenService:Create(CheckBox, TI.d015_Sine_Out, {BackgroundColor3 = selected[opt] and Theme.AccentA or Theme.ToggleOff}):Play()
                    TweenService:Create(Check, TI.d015_Sine_Out, {ImageTransparency = selected[opt] and 0 or 1}):Play()
                    -- กระเพื่อมเล็กๆ ตอนติ๊ก/ถอด ให้รู้สึกหนึบเหมือน Toggle
                    TweenService:Create(cbScale, TI.d008_Quad_Out, {Scale = 0.8}):Play()
                    task.delay(0.08, function()
                        if cbScale.Parent then
                            TweenService:Create(cbScale, TI.d022_Back_Out, {Scale = 1}):Play()
                        end
                    end)
                    fireCallback()
                end)
            end

            return newElement(Frame, getList, function(_, newList)
                selected = {}
                if type(newList) == "table" then for _, v in ipairs(newList) do selected[v] = true end end
                for opt, b in pairs(boxes) do
                    b.Box.BackgroundColor3 = selected[opt] and Theme.AccentA or Theme.ToggleOff
                    b.Check.ImageTransparency = selected[opt] and 0 or 1
                end
                fireCallback()
            end, nil, c.Flag)
        end

        function Tab:CreateSearchBox(c)
            c = type(c) == "table" and c or {}

            local Outer = Instance.new("Frame")
            Outer.Size = UDim2.new(1, 0, 0, 38)
            applyThemeColor(Outer, "Element")
            Outer.ClipsDescendants = true
            Outer.Parent = TabContent
            corner(Outer, 9)
            applyGlowOnHover(Outer)

            local IconImg = Instance.new("ImageLabel")
            IconImg.Size = UDim2.new(0, 15, 0, 15)
            IconImg.Position = UDim2.new(0, 12, 0.5, -7)
            IconImg.BackgroundTransparency = 1
            IconImg.Image = Library.Icons.search
            applyThemeColor(IconImg, "SubText", "ImageColor3")
            IconImg.ScaleType = Enum.ScaleType.Fit
            IconImg.ZIndex = 2
            IconImg.Parent = Outer

            local contentPos = UDim2.new(0, 34, 0, 0)
            local contentSize = UDim2.new(1, -44, 1, 0)

            local Box = Instance.new("TextBox")
            Box.Position = contentPos
            Box.Size = contentSize
            Box.BackgroundTransparency = 1
            Box.Text = c.Default or ""
            Box.PlaceholderText = ""
            applyThemeColor(Box, "Text", "TextColor3")
            Box.FontFace = UI_Font("SemiBold")
            Box.TextSize = 13
            Box.ClearTextOnFocus = false
            Box.TextXAlignment = Enum.TextXAlignment.Left
            Box.TextYAlignment = Enum.TextYAlignment.Center
            Box.ZIndex = 3
            Box.Parent = Outer

            local PlaceholderLbl = Instance.new("TextLabel")
            PlaceholderLbl.BackgroundTransparency = 1
            PlaceholderLbl.Position = contentPos
            PlaceholderLbl.Size = contentSize
            PlaceholderLbl.FontFace = UI_Font("SemiBold")
            PlaceholderLbl.TextSize = 13
            PlaceholderLbl.TextXAlignment = Enum.TextXAlignment.Left
            PlaceholderLbl.TextYAlignment = Enum.TextYAlignment.Center
            PlaceholderLbl.TextTruncate = Enum.TextTruncate.AtEnd
            PlaceholderLbl.Text = c.Text or "Search..."
            PlaceholderLbl.ZIndex = 1
            applyThemeColor(PlaceholderLbl, "SubText", "TextColor3")
            PlaceholderLbl.Visible = Box.Text == ""
            PlaceholderLbl.Parent = Outer

            Box:GetPropertyChangedSignal("Text"):Connect(function()
                PlaceholderLbl.Visible = Box.Text == ""
                safeCallback(c.Callback, Box.Text)
            end)
            return newElement(Outer, function() return Box.Text end, function(_, newText)
                Box.Text = newText
                PlaceholderLbl.Visible = Box.Text == ""
            end)
        end

        function Tab:CreateImage(c)
            c = type(c) == "table" and c or {}
            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, 0, 0, c.Height or 120)
            applyThemeColor(Frame, "Element")
            Frame.ClipsDescendants = true
            Frame.Parent = TabContent
            corner(Frame, 9)

            local Img = Instance.new("ImageLabel")
            Img.Size = UDim2.new(1, 0, 1, 0)
            Img.BackgroundTransparency = 1
            Img.Image = normalizeAssetId(c.Image or "")
            Img.ScaleType = c.ScaleType or Enum.ScaleType.Crop
            Img.Parent = Frame

            return newElement(Frame, function() return Img.Image end, function(_, newImage)
                Img.Image = normalizeAssetId(newImage)
            end)
        end

        function Tab:CreateConfigManager(c)
            c = type(c) == "table" and c or {}
            Tab:CreateSection(c.Title or "Config")

            local existing = Library:ListConfigs()
            local startName = existing[1] or c.Default or "default"

            local nameInput = Tab:CreateInput({
                Text = "ชื่อ Config",
                Default = startName,
            })

            if #existing > 0 then
                Tab:CreateDropdown({
                    Text = "Config ที่มีอยู่",
                    Options = existing,
                    Default = existing[1],
                    Callback = function(pickedName)
                        nameInput:Set(pickedName)
                    end,
                })
            end

            local function currentName()
                local n = nameInput:Get()
                if not n or n == "" then n = "default" end
                return n
            end

            Tab:CreateButton({
                Text = "💾  บันทึก Config",
                Notify = false,
                Callback = function() Library:SaveConfig(currentName()) end,
            })
            Tab:CreateButton({
                Text = "📂  โหลด Config",
                Notify = false,
                Callback = function() Library:LoadConfig(currentName()) end,
            })
            Tab:CreateButton({
                Text = "🗑  ลบ Config",
                Notify = false,
                Callback = function() Library:DeleteConfig(currentName()) end,
            })

            if c.AutoLoad ~= false and #existing > 0 then
                Library:LoadConfig(existing[1])
            end
        end

        function Tab:Clear()
            for _, child in ipairs(TabContent:GetChildren()) do
                if not child:IsA("UIListLayout") then child:Destroy() end
            end
        end

