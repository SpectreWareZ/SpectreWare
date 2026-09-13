--[[
    SpectreUI v6.9.0
    ==================
    Dark / purple component library (Lured.lua-style layout).

    Base components: Window, Tab, Section, Paragraph, Dropdown,
    MultiDropdown, Toggle, Slider, StringSlider, RangeSlider.

    Extended components (to match Load_api_v6_9_0.lua):
    Button, Divider, Label, ProgressBar, Accordion, SegmentedControl,
    Keybind, RadioGroup, ColorPicker, Input, SearchBox, Graph,
    TextArea, Image, SettingsTab (Theme dropdown), CommandPalette
    (Ctrl+K), RadialMenu (hold right-click), Notify / Confirm / Alert,
    Undo / Redo (generic, works on any Flag), Window:Toggle /
    SetTitle / Destroy / BindToClose, SubTitle + ToggleKeybind on
    CreateWindow, tab Group headers in the sidebar.

    Every element returned has .Instance (root Frame) so callers can
    freely reparent it. Flags live in Library.Flags (UI.Flags).
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

--============================================================
-- THEME
--============================================================
local Theme = {
    Background      = Color3.fromRGB(10, 10, 15),
    Sidebar         = Color3.fromRGB(15, 15, 21),
    Elevated        = Color3.fromRGB(22, 22, 30),
    ElevatedHover   = Color3.fromRGB(28, 28, 38),
    Stroke          = Color3.fromRGB(40, 40, 52),
    Accent          = Color3.fromRGB(147, 112, 246),
    AccentDim       = Color3.fromRGB(100, 80, 180),
    Text            = Color3.fromRGB(235, 235, 240),
    SubText         = Color3.fromRGB(150, 150, 165),
    Muted           = Color3.fromRGB(100, 100, 115),
    Font            = Enum.Font.GothamMedium,
    FontBold        = Enum.Font.GothamBold,
}

local ThemePresets = {
    ["Purple (Default)"] = Color3.fromRGB(147, 112, 246),
    ["Blue"]              = Color3.fromRGB(90, 150, 245),
    ["Red"]               = Color3.fromRGB(230, 90, 90),
    ["Green"]             = Color3.fromRGB(90, 200, 130),
}

local function corner(inst, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = inst
    return c
end

local function stroke(inst, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Stroke
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = inst
    return s
end

local function pad(inst, l, t, r, b)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, l or 0)
    p.PaddingTop = UDim.new(0, t or 0)
    p.PaddingRight = UDim.new(0, r or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.Parent = inst
    return p
end

local function tween(inst, props, time, style)
    local t = TweenService:Create(inst, TweenInfo.new(time or 0.15, style or Enum.EasingStyle.Quad), props)
    t:Play()
    return t
end

local function new(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    for _, c in ipairs(children or {}) do
        c.Parent = inst
    end
    return inst
end

--============================================================
-- LIBRARY (top-level: Flags, History, Notify/Confirm/Alert)
--============================================================
local Library = {}
Library.Flags = {}
Library.FlagObjects = {}
Library.History = {}
Library.RedoStack = {}
Library.AccentBound = {}
Library._suppressHistory = false
Library.__index = Library

local function trackChange(flag, old, new)
    if not flag or Library._suppressHistory or old == new then return end
    table.insert(Library.History, { flag = flag, old = old, new = new })
    Library.RedoStack = {}
end

local function bindAccent(inst, prop)
    table.insert(Library.AccentBound, { Instance = inst, Prop = prop or "BackgroundColor3" })
end

function Library:_ensureOverlay()
    if self._overlay then return self._overlay end
    local gui = new("ScreenGui", {
        Name = "SpectreUI_Overlay",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 1000,
        Parent = game:GetService("CoreGui"),
    })
    local notifHolder = new("Frame", {
        Size = UDim2.new(0, 280, 1, -20),
        Position = UDim2.new(1, -296, 0, 10),
        BackgroundTransparency = 1,
        Parent = gui,
    })
    new("UIListLayout", {
        Padding = UDim.new(0, 8),
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        SortOrder = Enum.SortOrder.LayoutOrder,
    }).Parent = notifHolder
    self._overlay = gui
    self._notifHolder = notifHolder
    return gui
end

local NotifyColors = {
    info = Theme.Accent,
    success = Color3.fromRGB(80, 200, 120),
    warning = Color3.fromRGB(230, 180, 60),
    error = Color3.fromRGB(230, 80, 80),
}

function Library:Notify(cfg)
    cfg = cfg or {}
    self:_ensureOverlay()
    local Card = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Elevated,
        Parent = self._notifHolder,
    })
    corner(Card, 8)
    stroke(Card, Theme.Stroke, 1)
    pad(Card, 12, 10, 12, 10)
    new("UIListLayout", { Padding = UDim.new(0, 2) }).Parent = Card
    new("TextLabel", {
        Text = cfg.Title or "",
        Font = Theme.FontBold, TextSize = 13,
        TextColor3 = NotifyColors[cfg.Type] or Theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Card,
    })
    new("TextLabel", {
        Text = cfg.Content or "",
        Font = Theme.Font, TextSize = 12, TextColor3 = Theme.SubText,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Card,
    })
    task.delay(cfg.Duration or 3, function()
        if Card and Card.Parent then
            tween(Card, { BackgroundTransparency = 1 }, 0.2)
            task.wait(0.2)
            if Card then Card:Destroy() end
        end
    end)
end

local function modalBase(self)
    self:_ensureOverlay()
    local Backdrop = new("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.5,
        ZIndex = 50,
        Parent = self._overlay,
    })
    local Box = new("Frame", {
        Size = UDim2.new(0, 300, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundColor3 = Theme.Elevated,
        ZIndex = 51,
        Parent = Backdrop,
    })
    corner(Box, 10)
    stroke(Box, Theme.Stroke, 1)
    pad(Box, 16, 16, 16, 16)
    new("UIListLayout", { Padding = UDim.new(0, 10) }).Parent = Box
    return Backdrop, Box
end

function Library:Confirm(cfg)
    cfg = cfg or {}
    local Backdrop, Box = modalBase(self)
    new("TextLabel", {
        Text = cfg.Title or "", Font = Theme.FontBold, TextSize = 15, TextColor3 = Theme.Text,
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20),
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 51, Parent = Box,
    })
    new("TextLabel", {
        Text = cfg.Content or "", Font = Theme.Font, TextSize = 13, TextColor3 = Theme.SubText,
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 51, Parent = Box,
    })
    local Row = new("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, ZIndex = 51, Parent = Box })
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 8),
    }).Parent = Row
    local CancelBtn = new("TextButton", {
        Size = UDim2.new(0, 100, 1, 0), BackgroundColor3 = Theme.Elevated,
        Text = cfg.CancelText or "Cancel", Font = Theme.Font, TextSize = 13,
        TextColor3 = Theme.SubText, ZIndex = 51, Parent = Row,
    })
    corner(CancelBtn, 6)
    stroke(CancelBtn, Theme.Stroke, 1)
    local ConfirmBtn = new("TextButton", {
        Size = UDim2.new(0, 100, 1, 0),
        BackgroundColor3 = cfg.Danger and Color3.fromRGB(200, 60, 60) or Theme.Accent,
        Text = cfg.ConfirmText or "Confirm", Font = Theme.FontBold, TextSize = 13,
        TextColor3 = Color3.new(1, 1, 1), ZIndex = 51, Parent = Row,
    })
    corner(ConfirmBtn, 6)
    CancelBtn.MouseButton1Click:Connect(function()
        Backdrop:Destroy()
        if cfg.OnCancel then cfg.OnCancel() end
    end)
    ConfirmBtn.MouseButton1Click:Connect(function()
        Backdrop:Destroy()
        if cfg.OnConfirm then cfg.OnConfirm() end
    end)
end

function Library:Alert(cfg)
    cfg = cfg or {}
    local Backdrop, Box = modalBase(self)
    new("TextLabel", {
        Text = cfg.Title or "", Font = Theme.FontBold, TextSize = 15, TextColor3 = Theme.Text,
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20),
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 51, Parent = Box,
    })
    new("TextLabel", {
        Text = cfg.Content or "", Font = Theme.Font, TextSize = 13, TextColor3 = Theme.SubText,
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 51, Parent = Box,
    })
    local OkBtn = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Theme.Accent,
        Text = cfg.ButtonText or "OK", Font = Theme.FontBold, TextSize = 13,
        TextColor3 = Color3.new(1, 1, 1), ZIndex = 51, Parent = Box,
    })
    corner(OkBtn, 6)
    OkBtn.MouseButton1Click:Connect(function() Backdrop:Destroy() end)
end

function Library:Undo()
    local entry = table.remove(self.History)
    if not entry then return false end
    local api = self.FlagObjects[entry.flag]
    self._suppressHistory = true
    if api and api.Set then api:Set(entry.old) end
    self._suppressHistory = false
    self.Flags[entry.flag] = entry.old
    table.insert(self.RedoStack, entry)
    return true, entry
end

function Library:Redo()
    local entry = table.remove(self.RedoStack)
    if not entry then return false end
    local api = self.FlagObjects[entry.flag]
    self._suppressHistory = true
    if api and api.Set then api:Set(entry.new) end
    self._suppressHistory = false
    self.Flags[entry.flag] = entry.new
    table.insert(self.History, entry)
    return true, entry
end

--============================================================
-- WINDOW
--============================================================
function Library:CreateWindow(config)
    config = config or {}
    local Window = {}
    Window.Tabs = {}
    Window.TabButtons = {}
    Window.Commands = {}
    Window.GroupLabels = {}
    Window._navOrder = 0
    Window.ActiveTab = nil
    Window.CloseCallback = nil

    local ScreenGui = new("ScreenGui", {
        Name = "SpectreUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = game:GetService("CoreGui"),
    })
    Window.ScreenGui = ScreenGui

    local Size = config.Size or UDim2.new(0, 660, 0, 480)

    local Main = new("Frame", {
        Name = "Main",
        Size = Size,
        Position = UDim2.new(0.5, -Size.X.Offset / 2, 0.5, -Size.Y.Offset / 2),
        BackgroundColor3 = Theme.Background,
        Parent = ScreenGui,
    })
    Window.Main = Main
    corner(Main, 10)
    stroke(Main, Theme.Stroke, 1)
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, {}).Parent = Main

    -- Drag support
    do
        local dragging, dragStart, startPos
        Main.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = Main.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end

    -- Sidebar
    local Sidebar = new("Frame", { Size = UDim2.new(0, 190, 1, 0), BackgroundColor3 = Theme.Sidebar, Parent = Main })
    pad(Sidebar, 12, 14, 12, 12)
    new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }).Parent = Sidebar

    local TitleBlock = new("Frame", {
        Size = UDim2.new(1, 0, 0, config.SubTitle and 40 or 24),
        BackgroundTransparency = 1, LayoutOrder = 1, Parent = Sidebar,
    })
    new("UIListLayout", { Padding = UDim.new(0, 2) }).Parent = TitleBlock

    local TitleRow = new("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Parent = TitleBlock })
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 8),
    }).Parent = TitleRow

    local LogoDot = new("Frame", { Size = UDim2.new(0, 18, 0, 18), BackgroundColor3 = Theme.Accent, Parent = TitleRow })
    corner(LogoDot, 5)
    bindAccent(LogoDot)

    local TitleLabel = new("TextLabel", {
        Text = config.Title or "SpectreUI",
        Font = Theme.FontBold, TextSize = 15, TextColor3 = Theme.Text,
        BackgroundTransparency = 1, Size = UDim2.new(1, -26, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left, Parent = TitleRow,
    })
    Window.TitleLabel = TitleLabel

    if config.SubTitle then
        new("TextLabel", {
            Text = config.SubTitle, Font = Theme.Font, TextSize = 11, TextColor3 = Theme.Muted,
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 14),
            TextXAlignment = Enum.TextXAlignment.Left, Parent = TitleBlock,
        })
    end

    local SearchBox = new("TextBox", {
        Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.Elevated,
        TextColor3 = Theme.SubText, PlaceholderText = "Search...", PlaceholderColor3 = Theme.Muted,
        Font = Theme.Font, TextSize = 13, Text = "", ClearTextOnFocus = false,
        LayoutOrder = 2, Parent = Sidebar,
    })
    corner(SearchBox, 6)
    pad(SearchBox, 10, 0, 10, 0)

    local NavList = new("Frame", { Size = UDim2.new(1, 0, 1, -80), BackgroundTransparency = 1, LayoutOrder = 3, Parent = Sidebar })
    new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }).Parent = NavList

    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local q = SearchBox.Text:lower()
        for _, btn in ipairs(Window.TabButtons) do
            btn.Instance.Visible = q == "" or btn.Name:lower():find(q, 1, true) ~= nil
        end
    end)

    -- Content area
    local Content = new("Frame", { Size = UDim2.new(1, -190, 1, 0), BackgroundTransparency = 1, Parent = Main })
    pad(Content, 16, 14, 16, 14)
    new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }).Parent = Content

    local HeaderPill = new("Frame", { Size = UDim2.new(0, 100, 0, 26), BackgroundColor3 = Theme.Elevated, LayoutOrder = 1, Parent = Content })
    corner(HeaderPill, 6)
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Padding = UDim.new(0, 6),
    }).Parent = HeaderPill
    local HeaderLabel = new("TextLabel", {
        Text = "", Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Text,
        BackgroundTransparency = 1, Size = UDim2.new(0, 70, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Center, Parent = HeaderPill,
    })

    local PagesHolder = new("Frame", { Size = UDim2.new(1, 0, 1, -38), BackgroundTransparency = 1, LayoutOrder = 2, Parent = Content })

    --========================================================
    -- Window-level API
    --========================================================
    function Window:Toggle()
        Main.Visible = not Main.Visible
    end

    function Window:SetTitle(text)
        TitleLabel.Text = text
    end

    function Window:BindToClose(fn)
        Window.CloseCallback = fn
    end

    function Window:Destroy()
        if Window.CloseCallback then
            local ok = pcall(Window.CloseCallback)
            if not ok then end
        end
        ScreenGui:Destroy()
    end

    if config.ToggleKeybind then
        UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == config.ToggleKeybind then
                Window:Toggle()
            end
        end)
    end

    -- Command Palette (Ctrl+K)
    function Window:CreateCommandPalette()
        local Backdrop, resultsHolder, searchBox
        local open = false

        local function close()
            open = false
            if Backdrop then Backdrop:Destroy() Backdrop = nil end
        end

        local function show()
            if open then return end
            open = true
            Library:_ensureOverlay()
            Backdrop = new("Frame", {
                Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0),
                BackgroundTransparency = 0.5, ZIndex = 60, Parent = Library._overlay,
            })
            local Box = new("Frame", {
                Size = UDim2.new(0, 360, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.15, 0),
                BackgroundColor3 = Theme.Elevated, ZIndex = 61, Parent = Backdrop,
            })
            corner(Box, 10)
            stroke(Box, Theme.Stroke, 1)
            pad(Box, 10, 10, 10, 10)
            new("UIListLayout", { Padding = UDim.new(0, 6) }).Parent = Box

            searchBox = new("TextBox", {
                Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Theme.ElevatedHover,
                TextColor3 = Theme.Text, PlaceholderText = "Type a command...",
                PlaceholderColor3 = Theme.Muted, Font = Theme.Font, TextSize = 14,
                Text = "", ClearTextOnFocus = false, ZIndex = 61, Parent = Box,
            })
            corner(searchBox, 6)
            pad(searchBox, 10, 0, 10, 0)

            resultsHolder = new("Frame", {
                Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1, ZIndex = 61, Parent = Box,
            })
            new("UIListLayout", { Padding = UDim.new(0, 2) }).Parent = resultsHolder

            local function renderResults()
                for _, c in ipairs(resultsHolder:GetChildren()) do
                    if c:IsA("TextButton") then c:Destroy() end
                end
                local q = searchBox.Text:lower()
                for _, cmd in ipairs(Window.Commands) do
                    if q == "" or cmd.Name:lower():find(q, 1, true) then
                        local Btn = new("TextButton", {
                            Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.ElevatedHover,
                            BackgroundTransparency = 1, AutoButtonColor = false,
                            Text = cmd.Name, Font = Theme.Font, TextSize = 13,
                            TextColor3 = Theme.SubText, ZIndex = 61, Parent = resultsHolder,
                        })
                        corner(Btn, 5)
                        Btn.MouseEnter:Connect(function() tween(Btn, { BackgroundTransparency = 0 }, 0.1) end)
                        Btn.MouseLeave:Connect(function() tween(Btn, { BackgroundTransparency = 1 }, 0.1) end)
                        Btn.MouseButton1Click:Connect(function()
                            close()
                            if cmd.Run then cmd.Run() end
                        end)
                    end
                end
            end

            searchBox:GetPropertyChangedSignal("Text"):Connect(renderResults)
            renderResults()
            searchBox:CaptureFocus()
        end

        UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            local ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
            if ctrl and input.KeyCode == Enum.KeyCode.K then
                if open then close() else show() end
            elseif input.KeyCode == Enum.KeyCode.Escape and open then
                close()
            end
        end)

        return { Open = show, Close = close }
    end

    -- Radial menu (hold right mouse button)
    function Window:CreateRadialMenu(cfg)
        cfg = cfg or {}
        local items = cfg.Items or {}
        local holding = false

        UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                holding = true
                Library:_ensureOverlay()
                local pos = UserInputService:GetMouseLocation()
                local Popup = new("Frame", {
                    Size = UDim2.new(0, 160, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                    Position = UDim2.new(0, pos.X - 80, 0, pos.Y - 20),
                    BackgroundColor3 = Theme.Elevated, ZIndex = 70, Parent = Library._overlay,
                })
                corner(Popup, 8)
                stroke(Popup, Theme.Stroke, 1)
                pad(Popup, 6, 6, 6, 6)
                new("UIListLayout", { Padding = UDim.new(0, 4) }).Parent = Popup
                for _, item in ipairs(items) do
                    local Btn = new("TextButton", {
                        Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = Theme.ElevatedHover,
                        BackgroundTransparency = 1, AutoButtonColor = false,
                        Text = item.Text or "", Font = Theme.Font, TextSize = 13,
                        TextColor3 = Theme.Text, ZIndex = 70, Parent = Popup,
                    })
                    corner(Btn, 5)
                    Btn.MouseEnter:Connect(function() tween(Btn, { BackgroundTransparency = 0 }, 0.1) end)
                    Btn.MouseLeave:Connect(function() tween(Btn, { BackgroundTransparency = 1 }, 0.1) end)
                    Btn.MouseButton1Click:Connect(function()
                        Popup:Destroy()
                        if item.Callback then item.Callback() end
                    end)
                end
                local conn
                conn = UserInputService.InputEnded:Connect(function(endInput)
                    if endInput.UserInputType == Enum.UserInputType.MouseButton2 then
                        holding = false
                        task.delay(3, function() if Popup and Popup.Parent then Popup:Destroy() end end)
                        conn:Disconnect()
                    end
                end)
            end
        end)
    end

    --========================================================
    -- TAB
    --========================================================
    function Window:CreateTab(name, icon, group)
        local Tab = {}
        Tab.Name = name

        local groupKey = group or "Main"
        if not Window.GroupLabels[groupKey] then
            Window._navOrder = Window._navOrder + 10
            local GroupLabel = new("TextLabel", {
                Text = groupKey:upper(), Font = Theme.FontBold, TextSize = 10, TextColor3 = Theme.Muted,
                BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18),
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = Window._navOrder, Parent = NavList,
            })
            Window.GroupLabels[groupKey] = GroupLabel
        end

        Window._navOrder = Window._navOrder + 10
        local NavBtn = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Theme.Elevated,
            BackgroundTransparency = 1, AutoButtonColor = false, Text = "",
            LayoutOrder = Window._navOrder, Parent = NavList,
        })
        corner(NavBtn, 6)
        pad(NavBtn, 10, 0, 10, 0)
        new("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8),
        }).Parent = NavBtn

        local Icon = new("Frame", { Size = UDim2.new(0, 14, 0, 14), BackgroundColor3 = Theme.Muted, Parent = NavBtn })
        corner(Icon, 7)

        local Label = new("TextLabel", {
            Text = name, Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Muted,
            BackgroundTransparency = 1, Size = UDim2.new(1, -22, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left, Parent = NavBtn,
        })

        local Page = new("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Stroke,
            CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false, Parent = PagesHolder,
        })
        new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }).Parent = Page

        local function setActive()
            for _, t in ipairs(Window.Tabs) do
                t.Page.Visible = false
                tween(t.Label, { TextColor3 = Theme.Muted }, 0.12)
                tween(t.Icon, { BackgroundColor3 = Theme.Muted }, 0.12)
                tween(t.NavBtn, { BackgroundTransparency = 1 }, 0.12)
            end
            Page.Visible = true
            tween(Label, { TextColor3 = Theme.Text }, 0.12)
            tween(Icon, { BackgroundColor3 = Theme.Accent }, 0.12)
            tween(NavBtn, { BackgroundTransparency = 0 }, 0.12)
            HeaderLabel.Text = name
            Window.ActiveTab = Tab
        end

        NavBtn.MouseButton1Click:Connect(setActive)
        table.insert(Window.Commands, { Name = "Go to " .. name, Run = setActive })

        Tab.Instance = Page
        Tab.Page = Page
        Tab.NavBtn = NavBtn
        Tab.Icon = Icon
        Tab.Label = Label
        Tab.Group = group

        table.insert(Window.Tabs, Tab)
        table.insert(Window.TabButtons, { Instance = NavBtn, Name = name })

        if #Window.Tabs == 1 then setActive() end

        --====================================================
        -- Layout helper
        --====================================================
        local function baseRow(labelText)
            local Frame = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = Page })
            new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }).Parent = Frame
            local LabelRow = new("Frame", { Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Parent = Frame })
            local Label = new("TextLabel", {
                Text = labelText or "", Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Text,
                BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left, Parent = LabelRow,
            })
            return Frame, Label, LabelRow
        end

        --====================================================
        -- BASIC ELEMENTS
        --====================================================
        function Tab:CreateSection(text)
            local Section = new("Frame", { Size = UDim2.new(1, 0, 0, 20), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = Page })
            new("TextLabel", {
                Text = text, Font = Theme.FontBold, TextSize = 13, TextColor3 = Theme.SubText,
                BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20),
                TextXAlignment = Enum.TextXAlignment.Left, Parent = Section,
            })
            return { Instance = Section }
        end

        function Tab:CreateDivider()
            local Frame = new("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Stroke, Parent = Page })
            return { Instance = Frame }
        end

        function Tab:CreateLabel(cfg)
            cfg = cfg or {}
            local Frame = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = Page })
            new("TextLabel", {
                Text = cfg.Text or "", Font = Theme.Font, TextSize = 13, TextColor3 = Theme.SubText,
                BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = Frame,
            })
            return { Instance = Frame }
        end

        function Tab:CreateParagraph(cfg)
            cfg = cfg or {}
            local Frame = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = Page })
            new("TextLabel", {
                Text = cfg.Text or "", Font = Theme.Font, TextSize = 13, TextColor3 = Theme.SubText,
                BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
                Parent = Frame,
            })
            return { Instance = Frame }
        end

        function Tab:CreateImage(cfg)
            cfg = cfg or {}
            local Frame = new("Frame", { Size = UDim2.new(1, 0, 0, cfg.Height or 80), BackgroundTransparency = 1, Parent = Page })
            local Img = new("ImageLabel", {
                Image = cfg.Image or "", Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = Theme.Elevated, ScaleType = Enum.ScaleType.Crop, Parent = Frame,
            })
            corner(Img, 8)
            return { Instance = Frame }
        end

        function Tab:CreateButton(cfg)
            cfg = cfg or {}
            local Btn = new("TextButton", {
                Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Theme.Elevated,
                AutoButtonColor = false, Text = cfg.Text or "", Font = Theme.Font, TextSize = 13,
                TextColor3 = Theme.Text, Parent = Page,
            })
            corner(Btn, 6)
            stroke(Btn, Theme.Stroke, 1)
            Btn.MouseEnter:Connect(function() tween(Btn, { BackgroundColor3 = Theme.ElevatedHover }, 0.1) end)
            Btn.MouseLeave:Connect(function() tween(Btn, { BackgroundColor3 = Theme.Elevated }, 0.1) end)
            local function run()
                if cfg.Callback then cfg.Callback() end
                local shouldNotify = cfg.Notify
                if shouldNotify == nil then shouldNotify = cfg.NotifyText ~= nil end
                if shouldNotify and cfg.NotifyText then
                    Library:Notify({ Title = cfg.Text, Content = cfg.NotifyText, Type = "info", Duration = 2 })
                end
            end
            Btn.MouseButton1Click:Connect(run)
            table.insert(Window.Commands, { Name = cfg.Text or "Button", Run = run })
            return { Instance = Btn }
        end

        function Tab:CreateProgressBar(cfg)
            cfg = cfg or {}
            local Min, Max = cfg.Min or 0, cfg.Max or 100
            local Value = cfg.Default or Min
            local Frame, Label = baseRow(cfg.Text)
            local Track = new("Frame", { Size = UDim2.new(1, 0, 0, 8), BackgroundColor3 = Theme.Elevated, Parent = Frame })
            corner(Track, 4)
            local Fill = new("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Accent, Parent = Track })
            corner(Fill, 4)
            bindAccent(Fill)
            local api = { Instance = Frame }
            local function render(v)
                v = math.clamp(v, Min, Max)
                Value = v
                api.Value = v
                Fill.Size = UDim2.new((v - Min) / (Max - Min == 0 and 1 or (Max - Min)), 0, 1, 0)
            end
            function api:Set(v) render(v) end
            render(Value)
            return api
        end

        function Tab:CreateAccordion(cfg)
            cfg = cfg or {}
            local Frame = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.Elevated, Parent = Page })
            corner(Frame, 6)
            stroke(Frame, Theme.Stroke, 1)
            pad(Frame, 12, 10, 12, 10)
            new("UIListLayout", { Padding = UDim.new(0, 6) }).Parent = Frame

            local Header = new("TextButton", {
                Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, AutoButtonColor = false, Text = "", Parent = Frame,
            })
            new("TextLabel", {
                Text = cfg.Title or "", Font = Theme.FontBold, TextSize = 13, TextColor3 = Theme.Text,
                BackgroundTransparency = 1, Size = UDim2.new(1, -16, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left, Parent = Header,
            })
            local Chevron = new("TextLabel", {
                Text = cfg.Expanded and "-" or "+", Font = Theme.FontBold, TextSize = 14, TextColor3 = Theme.Muted,
                BackgroundTransparency = 1, Size = UDim2.new(0, 16, 1, 0), Position = UDim2.new(1, -16, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Right, Parent = Header,
            })
            local Body = new("TextLabel", {
                Text = cfg.Content or "", Font = Theme.Font, TextSize = 12, TextColor3 = Theme.SubText,
                BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
                Visible = cfg.Expanded or false, Parent = Frame,
            })
            Header.MouseButton1Click:Connect(function()
                Body.Visible = not Body.Visible
                Chevron.Text = Body.Visible and "-" or "+"
            end)
            return { Instance = Frame }
        end

        --====================================================
        -- DROPDOWN (single)
        --====================================================
        function Tab:CreateDropdown(cfg)
            cfg = cfg or {}
            local Options = cfg.Options or {}
            local Selected = cfg.Default or Options[1]
            local Frame, Label = baseRow(cfg.Text)

            local Box = new("TextButton", {
                Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Theme.Elevated,
                AutoButtonColor = false, Text = "", Parent = Frame,
            })
            corner(Box, 6)
            stroke(Box, Theme.Stroke, 1)
            pad(Box, 12, 0, 12, 0)

            local ValueLabel = new("TextLabel", {
                Text = tostring(Selected or ""), Font = Theme.Font, TextSize = 13, TextColor3 = Theme.SubText,
                BackgroundTransparency = 1, Size = UDim2.new(1, -20, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left, Parent = Box,
            })
            new("TextLabel", {
                Text = "v", Font = Theme.FontBold, TextSize = 12, TextColor3 = Theme.Muted,
                BackgroundTransparency = 1, Size = UDim2.new(0, 16, 1, 0), Position = UDim2.new(1, -16, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Right, Parent = Box,
            })

            local ListFrame = new("Frame", {
                Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Theme.ElevatedHover, Visible = false, ZIndex = 5, Parent = Frame,
            })
            corner(ListFrame, 6)
            stroke(ListFrame, Theme.Stroke, 1)
            pad(ListFrame, 4, 4, 4, 4)
            new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }).Parent = ListFrame

            local api = { Instance = Frame, Value = Selected }

            local function setValue(v, isInit)
                local old = Selected
                Selected = v
                api.Value = v
                ValueLabel.Text = tostring(v)
                if cfg.Flag then
                    Library.Flags[cfg.Flag] = v
                    if not isInit then trackChange(cfg.Flag, old, v) end
                end
                if cfg.Callback and not isInit then cfg.Callback(v) end
            end

            for _, opt in ipairs(Options) do
                local OptBtn = new("TextButton", {
                    Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = Theme.ElevatedHover, BackgroundTransparency = 1,
                    AutoButtonColor = false, Text = tostring(opt), Font = Theme.Font, TextSize = 13,
                    TextColor3 = Theme.SubText, ZIndex = 6, Parent = ListFrame,
                })
                corner(OptBtn, 4)
                OptBtn.MouseEnter:Connect(function() tween(OptBtn, { BackgroundTransparency = 0 }, 0.1) end)
                OptBtn.MouseLeave:Connect(function() tween(OptBtn, { BackgroundTransparency = 1 }, 0.1) end)
                OptBtn.MouseButton1Click:Connect(function()
                    setValue(opt)
                    ListFrame.Visible = false
                end)
            end

            Box.MouseButton1Click:Connect(function() ListFrame.Visible = not ListFrame.Visible end)

            function api:Set(v) setValue(v, true) end
            function api:Get() return Selected end

            setValue(Selected, true)
            if cfg.Flag then Library.FlagObjects[cfg.Flag] = api end
            return api
        end

        --====================================================
        -- DROPDOWN (multi)
        --====================================================
        function Tab:CreateMultiDropdown(cfg)
            cfg = cfg or {}
            local Options = cfg.Options or {}
            local SelectedSet = {}
            for _, v in ipairs(cfg.Default or {}) do SelectedSet[v] = true end

            local Frame, Label = baseRow(cfg.Text)

            local Box = new("TextButton", {
                Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Theme.Elevated,
                AutoButtonColor = false, Text = "", Parent = Frame,
            })
            corner(Box, 6)
            stroke(Box, Theme.Stroke, 1)
            pad(Box, 12, 0, 12, 0)

            local ValueLabel = new("TextLabel", {
                Text = "", Font = Theme.Font, TextSize = 13, TextColor3 = Theme.SubText,
                BackgroundTransparency = 1, Size = UDim2.new(1, -20, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = Box,
            })
            new("TextLabel", {
                Text = "v", Font = Theme.FontBold, TextSize = 12, TextColor3 = Theme.Muted,
                BackgroundTransparency = 1, Size = UDim2.new(0, 16, 1, 0), Position = UDim2.new(1, -16, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Right, Parent = Box,
            })

            local ListFrame = new("Frame", {
                Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Theme.ElevatedHover, Visible = false, ZIndex = 5, Parent = Frame,
            })
            corner(ListFrame, 6)
            stroke(ListFrame, Theme.Stroke, 1)
            pad(ListFrame, 4, 4, 4, 4)
            new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }).Parent = ListFrame

            local api = { Instance = Frame }

            local function refreshLabel()
                local list = {}
                for _, opt in ipairs(Options) do
                    if SelectedSet[opt] then table.insert(list, tostring(opt)) end
                end
                ValueLabel.Text = table.concat(list, ", ")
                api.Value = list
                if cfg.Flag then Library.Flags[cfg.Flag] = list end
            end

            local checks = {}
            for _, opt in ipairs(Options) do
                local OptBtn = new("TextButton", {
                    Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = Theme.ElevatedHover, BackgroundTransparency = 1,
                    AutoButtonColor = false, Text = "", ZIndex = 6, Parent = ListFrame,
                })
                corner(OptBtn, 4)
                pad(OptBtn, 8, 0, 8, 0)
                new("TextLabel", {
                    Text = tostring(opt), Font = Theme.Font, TextSize = 13, TextColor3 = Theme.SubText,
                    BackgroundTransparency = 1, Size = UDim2.new(1, -20, 1, 0),
                    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6, Parent = OptBtn,
                })
                local Check = new("Frame", {
                    Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(1, -14, 0.5, -7),
                    BackgroundColor3 = SelectedSet[opt] and Theme.Accent or Theme.Elevated, ZIndex = 6, Parent = OptBtn,
                })
                corner(Check, 4)
                stroke(Check, Theme.Stroke, 1)
                checks[opt] = Check

                OptBtn.MouseEnter:Connect(function() tween(OptBtn, { BackgroundTransparency = 0 }, 0.1) end)
                OptBtn.MouseLeave:Connect(function() tween(OptBtn, { BackgroundTransparency = 1 }, 0.1) end)
                OptBtn.MouseButton1Click:Connect(function()
                    SelectedSet[opt] = not SelectedSet[opt]
                    tween(Check, { BackgroundColor3 = SelectedSet[opt] and Theme.Accent or Theme.Elevated }, 0.1)
                    refreshLabel()
                    if cfg.Callback then cfg.Callback(api.Value) end
                end)
            end

            Box.MouseButton1Click:Connect(function() ListFrame.Visible = not ListFrame.Visible end)

            function api:Set(list)
                SelectedSet = {}
                for _, v in ipairs(list) do
                    SelectedSet[v] = true
                    if checks[v] then checks[v].BackgroundColor3 = Theme.Accent end
                end
                refreshLabel()
            end

            refreshLabel()
            if cfg.Flag then Library.FlagObjects[cfg.Flag] = api end
            return api
        end

        --====================================================
        -- TOGGLE (checkbox, optional tooltip)
        --====================================================
        function Tab:CreateToggle(cfg)
            cfg = cfg or {}
            local Value = cfg.Default or false

            local Frame = new("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Parent = Page })
            local Label = new("TextLabel", {
                Text = cfg.Text or "", Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Text,
                BackgroundTransparency = 1, Size = UDim2.new(1, -30, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left, Parent = Frame,
            })
            local Box = new("TextButton", {
                Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(1, -18, 0.5, -9),
                BackgroundColor3 = Theme.Elevated, AutoButtonColor = false, Text = "", Parent = Frame,
            })
            corner(Box, 5)
            stroke(Box, Theme.Stroke, 1)
            local Check = new("TextLabel", {
                Text = "\226\156\147", Font = Theme.FontBold, TextSize = 12, TextColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Visible = Value, Parent = Box,
            })

            if cfg.Tooltip then
                local Tip = new("Frame", {
                    BackgroundColor3 = Theme.ElevatedHover, Size = UDim2.new(0, 200, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y, Visible = false, ZIndex = 10, Parent = Frame,
                })
                corner(Tip, 6)
                stroke(Tip, Theme.Stroke, 1)
                pad(Tip, 8, 6, 8, 6)
                new("TextLabel", {
                    Text = cfg.Tooltip, Font = Theme.Font, TextSize = 12, TextColor3 = Theme.SubText,
                    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                    TextWrapped = true, ZIndex = 10, Parent = Tip,
                })
                Label.MouseEnter:Connect(function()
                    Tip.Position = UDim2.new(0, 0, 1, 4)
                    Tip.Visible = true
                end)
                Label.MouseLeave:Connect(function() Tip.Visible = false end)
            end

            local api = { Instance = Frame, Value = Value }

            local function setValue(v, isInit)
                local old = Value
                Value = v
                api.Value = v
                Check.Visible = v
                tween(Box, { BackgroundColor3 = v and Theme.Accent or Theme.Elevated }, 0.1)
                if cfg.Flag then
                    Library.Flags[cfg.Flag] = v
                    if not isInit then trackChange(cfg.Flag, old, v) end
                end
                if not isInit then
                    if v and cfg.NotifyOnText then Library:Notify({ Title = cfg.Text, Content = cfg.NotifyOnText, Type = "success", Duration = 2 }) end
                    if not v and cfg.NotifyOffText then Library:Notify({ Title = cfg.Text, Content = cfg.NotifyOffText, Type = "warning", Duration = 2 }) end
                    if cfg.Callback then cfg.Callback(v) end
                end
            end

            Box.MouseButton1Click:Connect(function() setValue(not Value) end)
            table.insert(Window.Commands, { Name = "Toggle " .. (cfg.Text or ""), Run = function() setValue(not Value) end })

            function api:Set(v) setValue(v, true) end
            function api:Get() return Value end

            setValue(Value, true)
            if cfg.Flag then Library.FlagObjects[cfg.Flag] = api end
            return api
        end

        --====================================================
        -- SLIDER
        --====================================================
        function Tab:CreateSlider(cfg)
            cfg = cfg or {}
            local Min, Max = cfg.Min or 0, cfg.Max or 100
            local Places = cfg.Places or 0
            local Suffix = cfg.Suffix or ""
            local Value = cfg.Default or Min

            local Frame = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = Page })
            new("UIListLayout", { Padding = UDim.new(0, 6) }).Parent = Frame

            local Top = new("Frame", { Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Parent = Frame })
            new("TextLabel", {
                Text = cfg.Text or "", Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Text,
                BackgroundTransparency = 1, Size = UDim2.new(0.7, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left, Parent = Top,
            })
            local ValueLabel = new("TextLabel", {
                Text = "", Font = Theme.Font, TextSize = 13, TextColor3 = Theme.SubText,
                BackgroundTransparency = 1, Size = UDim2.new(0.3, 0, 1, 0), Position = UDim2.new(0.7, 0, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Right, Parent = Top,
            })

            local Track = new("Frame", { Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = Theme.Elevated, Parent = Frame })
            corner(Track, 2)
            local Fill = new("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Accent, Parent = Track })
            corner(Fill, 2)
            bindAccent(Fill)
            local Handle = new("Frame", {
                Size = UDim2.new(0, 12, 0, 12), AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255), Parent = Track,
            })
            corner(Handle, 6)

            local api = { Instance = Frame, Value = Value }

            local function round(n)
                local mult = 10 ^ Places
                return math.floor(n * mult + 0.5) / mult
            end

            local function render(v, isInit)
                local old = Value
                v = math.clamp(v, Min, Max)
                v = round(v)
                Value = v
                api.Value = v
                local alpha = (v - Min) / (Max - Min == 0 and 1 or (Max - Min))
                Fill.Size = UDim2.new(alpha, 0, 1, 0)
                Handle.Position = UDim2.new(alpha, 0, 0.5, 0)
                ValueLabel.Text = (Places > 0 and string.format("%." .. Places .. "f", v) or tostring(math.floor(v))) .. Suffix
                if cfg.Flag then
                    Library.Flags[cfg.Flag] = v
                    if not isInit then trackChange(cfg.Flag, old, v) end
                end
            end

            local dragging = false
            local function updateFromInput(x)
                local rel = math.clamp((x - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                local v = Min + rel * (Max - Min)
                render(v)
                if cfg.Callback then cfg.Callback(Value) end
            end

            Track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    updateFromInput(input.Position.X)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateFromInput(input.Position.X)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            function api:Set(v) render(v, true) end
            function api:Get() return Value end

            render(Value, true)
            if cfg.Flag then Library.FlagObjects[cfg.Flag] = api end
            return api
        end

        --====================================================
        -- STRING SLIDER
        --====================================================
        function Tab:CreateStringSlider(cfg)
            cfg = cfg or {}
            local Values = cfg.Values or {}
            local Index = 1
            for i, v in ipairs(Values) do if v == cfg.Default then Index = i break end end

            local Frame = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = Page })
            new("UIListLayout", { Padding = UDim.new(0, 6) }).Parent = Frame

            local Top = new("Frame", { Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Parent = Frame })
            new("TextLabel", {
                Text = cfg.Text or "", Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Text,
                BackgroundTransparency = 1, Size = UDim2.new(0.7, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left, Parent = Top,
            })
            local ValueLabel = new("TextLabel", {
                Text = "", Font = Theme.Font, TextSize = 13, TextColor3 = Theme.SubText,
                BackgroundTransparency = 1, Size = UDim2.new(0.3, 0, 1, 0), Position = UDim2.new(0.7, 0, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Right, Parent = Top,
            })

            local Track = new("Frame", { Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = Theme.Elevated, Parent = Frame })
            corner(Track, 2)
            local Fill = new("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Accent, Parent = Track })
            corner(Fill, 2)
            bindAccent(Fill)
            local Handle = new("Frame", {
                Size = UDim2.new(0, 12, 0, 12), AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255), Parent = Track,
            })
            corner(Handle, 6)

            local api = { Instance = Frame }

            local function render(i, isInit)
                i = math.clamp(i, 1, #Values)
                Index = i
                local v = Values[i]
                local old = api.Value
                api.Value = v
                local alpha = #Values > 1 and (i - 1) / (#Values - 1) or 0
                Fill.Size = UDim2.new(alpha, 0, 1, 0)
                Handle.Position = UDim2.new(alpha, 0, 0.5, 0)
                ValueLabel.Text = tostring(v)
                if cfg.Flag then
                    Library.Flags[cfg.Flag] = v
                    if not isInit then trackChange(cfg.Flag, old, v) end
                end
            end

            local dragging = false
            local function updateFromInput(x)
                local rel = math.clamp((x - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                local i = math.floor(rel * (#Values - 1) + 0.5) + 1
                render(i)
                if cfg.Callback then cfg.Callback(api.Value) end
            end

            Track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    updateFromInput(input.Position.X)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateFromInput(input.Position.X)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            function api:Set(v)
                for i, val in ipairs(Values) do if val == v then render(i, true) return end end
            end
            function api:Get() return api.Value end

            render(Index, true)
            if cfg.Flag then Library.FlagObjects[cfg.Flag] = api end
            return api
        end

        --====================================================
        -- RANGE SLIDER
        --====================================================
        function Tab:CreateRangeSlider(cfg)
            cfg = cfg or {}
            local Min, Max = cfg.Min or 0, cfg.Max or 100
            local Places = cfg.Places or 0
            local Suffix = cfg.Suffix or ""
            local LowVal = cfg.DefaultMin or Min
            local HighVal = cfg.DefaultMax or Max

            local Frame = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = Page })
            new("UIListLayout", { Padding = UDim.new(0, 6) }).Parent = Frame

            local Top = new("Frame", { Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Parent = Frame })
            new("TextLabel", {
                Text = cfg.Text or "", Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Text,
                BackgroundTransparency = 1, Size = UDim2.new(0.6, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left, Parent = Top,
            })
            local ValueLabel = new("TextLabel", {
                Text = "", Font = Theme.Font, TextSize = 13, TextColor3 = Theme.SubText,
                BackgroundTransparency = 1, Size = UDim2.new(0.4, 0, 1, 0), Position = UDim2.new(0.6, 0, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Right, Parent = Top,
            })

            local Track = new("Frame", { Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = Theme.Elevated, Parent = Frame })
            corner(Track, 2)
            local Fill = new("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Accent, Parent = Track })
            corner(Fill, 2)
            bindAccent(Fill)
            local HandleLow = new("Frame", {
                Size = UDim2.new(0, 12, 0, 12), AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255), ZIndex = 3, Parent = Track,
            })
            corner(HandleLow, 6)
            local HandleHigh = new("Frame", {
                Size = UDim2.new(0, 12, 0, 12), AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255), ZIndex = 3, Parent = Track,
            })
            corner(HandleHigh, 6)

            local api = { Instance = Frame }

            local function round(n)
                local mult = 10 ^ Places
                return math.floor(n * mult + 0.5) / mult
            end
            local function fmt(v)
                return Places > 0 and string.format("%." .. Places .. "f", v) or tostring(math.floor(v))
            end

            local function render()
                local aLow = (LowVal - Min) / (Max - Min == 0 and 1 or (Max - Min))
                local aHigh = (HighVal - Min) / (Max - Min == 0 and 1 or (Max - Min))
                HandleLow.Position = UDim2.new(aLow, 0, 0.5, 0)
                HandleHigh.Position = UDim2.new(aHigh, 0, 0.5, 0)
                Fill.Position = UDim2.new(aLow, 0, 0, 0)
                Fill.Size = UDim2.new(aHigh - aLow, 0, 1, 0)
                ValueLabel.Text = fmt(LowVal) .. " - " .. fmt(HighVal) .. Suffix
                api.Value = { LowVal, HighVal }
                if cfg.Flag then Library.Flags[cfg.Flag] = api.Value end
            end

            local draggingHandle = nil
            local function posToValue(x)
                local rel = math.clamp((x - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                return round(Min + rel * (Max - Min))
            end

            HandleLow.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingHandle = "low" end
            end)
            HandleHigh.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingHandle = "high" end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if draggingHandle and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local v = posToValue(input.Position.X)
                    if draggingHandle == "low" then LowVal = math.clamp(v, Min, HighVal)
                    else HighVal = math.clamp(v, LowVal, Max) end
                    render()
                    if cfg.Callback then cfg.Callback(api.Value) end
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingHandle = nil end
            end)

            function api:Set(lo, hi)
                LowVal, HighVal = math.clamp(lo, Min, Max), math.clamp(hi, Min, Max)
                render()
            end
            function api:Get() return LowVal, HighVal end

            render()
            return api
        end

        --====================================================
        -- SEGMENTED CONTROL
        --====================================================
        function Tab:CreateSegmentedControl(cfg)
            cfg = cfg or {}
            local Options = cfg.Options or {}
            local Selected = cfg.Default or 1
            if type(Selected) ~= "number" then
                for i, v in ipairs(Options) do if v == Selected then Selected = i break end end
            end

            local Frame, Label = baseRow(cfg.Text)
            local Row = new("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.Elevated, Parent = Frame })
            corner(Row, 6)
            pad(Row, 3, 3, 3, 3)
            new("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 3),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }).Parent = Row

            local api = { Instance = Frame }
            local buttons = {}

            local function setValue(i, isInit)
                local old = api.Value
                Selected = i
                api.Value = Options[i]
                for idx, btn in ipairs(buttons) do
                    tween(btn, { BackgroundColor3 = idx == i and Theme.Accent or Theme.Elevated }, 0.1)
                end
                if cfg.Flag then
                    Library.Flags[cfg.Flag] = Options[i]
                    if not isInit then trackChange(cfg.Flag, old, Options[i]) end
                end
                if cfg.Callback and not isInit then cfg.Callback(Options[i]) end
            end

            for i, opt in ipairs(Options) do
                local Btn = new("TextButton", {
                    Size = UDim2.new(1 / #Options, -2, 1, 0), BackgroundColor3 = i == Selected and Theme.Accent or Theme.Elevated,
                    AutoButtonColor = false, Text = tostring(opt), Font = Theme.Font, TextSize = 12,
                    TextColor3 = Theme.Text, Parent = Row,
                })
                corner(Btn, 4)
                if i == Selected then bindAccent(Btn) end
                buttons[i] = Btn
                Btn.MouseButton1Click:Connect(function() setValue(i) end)
            end

            function api:Set(v)
                for i, opt in ipairs(Options) do if opt == v then setValue(i, true) return end end
            end
            function api:Get() return api.Value end

            setValue(Selected, true)
            if cfg.Flag then Library.FlagObjects[cfg.Flag] = api end
            return api
        end

        --====================================================
        -- RADIO GROUP
        --====================================================
        function Tab:CreateRadioGroup(cfg)
            cfg = cfg or {}
            local Options = cfg.Options or {}
            local Selected = cfg.Default or Options[1]

            local Frame, Label = baseRow(cfg.Text)
            local List = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = Frame })
            new("UIListLayout", { Padding = UDim.new(0, 4) }).Parent = List

            local api = { Instance = Frame, Value = Selected }
            local dots = {}

            local function setValue(v, isInit)
                local old = Selected
                Selected = v
                api.Value = v
                for opt, dot in pairs(dots) do
                    dot.BackgroundColor3 = (opt == v) and Theme.Accent or Theme.Background
                end
                if cfg.Flag then
                    Library.Flags[cfg.Flag] = v
                    if not isInit then trackChange(cfg.Flag, old, v) end
                end
                if cfg.Callback and not isInit then cfg.Callback(v) end
            end

            for _, opt in ipairs(Options) do
                local Row = new("TextButton", {
                    Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, AutoButtonColor = false, Text = "", Parent = List,
                })
                new("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 8),
                }).Parent = Row
                local Ring = new("Frame", { Size = UDim2.new(0, 14, 0, 14), BackgroundColor3 = Theme.Elevated, Parent = Row })
                corner(Ring, 7)
                stroke(Ring, Theme.Stroke, 1)
                local Dot = new("Frame", {
                    Size = UDim2.new(0, 8, 0, 8), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
                    BackgroundColor3 = (opt == Selected) and Theme.Accent or Theme.Background, Parent = Ring,
                })
                corner(Dot, 4)
                dots[opt] = Dot
                new("TextLabel", {
                    Text = tostring(opt), Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Text,
                    BackgroundTransparency = 1, Size = UDim2.new(1, -22, 1, 0),
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = Row,
                })
                Row.MouseButton1Click:Connect(function() setValue(opt) end)
            end

            function api:Set(v) setValue(v, true) end
            function api:Get() return Selected end

            setValue(Selected, true)
            if cfg.Flag then Library.FlagObjects[cfg.Flag] = api end
            return api
        end

        --====================================================
        -- KEYBIND
        --====================================================
        function Tab:CreateKeybind(cfg)
            cfg = cfg or {}
            local Key = cfg.Default or Enum.KeyCode.Unknown
            local listening = false

            local Frame = new("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Parent = Page })
            new("TextLabel", {
                Text = cfg.Text or "", Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Text,
                BackgroundTransparency = 1, Size = UDim2.new(1, -100, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left, Parent = Frame,
            })
            local KeyBtn = new("TextButton", {
                Size = UDim2.new(0, 90, 0, 22), Position = UDim2.new(1, -90, 0, 0),
                BackgroundColor3 = Theme.Elevated, AutoButtonColor = false,
                Text = Key.Name, Font = Theme.Font, TextSize = 12, TextColor3 = Theme.SubText, Parent = Frame,
            })
            corner(KeyBtn, 5)
            stroke(KeyBtn, Theme.Stroke, 1)

            local api = { Instance = Frame, Value = Key }

            KeyBtn.MouseButton1Click:Connect(function()
                listening = true
                KeyBtn.Text = "..."
            end)

            UserInputService.InputBegan:Connect(function(input, gpe)
                if not listening then return end
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    local old = Key
                    Key = input.KeyCode
                    api.Value = Key
                    KeyBtn.Text = Key.Name
                    listening = false
                    if cfg.Flag then
                        Library.Flags[cfg.Flag] = Key
                        trackChange(cfg.Flag, old, Key)
                    end
                    if cfg.Callback then cfg.Callback(Key) end
                end
            end)

            function api:Set(k)
                Key = k
                api.Value = k
                KeyBtn.Text = k.Name
            end
            function api:Get() return Key end

            if cfg.Flag then Library.Flags[cfg.Flag] = Key Library.FlagObjects[cfg.Flag] = api end
            return api
        end

        --====================================================
        -- COLOR PICKER (RGB sliders in a popout)
        --====================================================
        function Tab:CreateColorPicker(cfg)
            cfg = cfg or {}
            local Color = cfg.Default or Color3.fromRGB(255, 255, 255)

            local Frame = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = Page })
            new("UIListLayout", { Padding = UDim.new(0, 6) }).Parent = Frame

            local Row = new("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Parent = Frame })
            new("TextLabel", {
                Text = cfg.Text or "", Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Text,
                BackgroundTransparency = 1, Size = UDim2.new(1, -30, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left, Parent = Row,
            })
            local Swatch = new("TextButton", {
                Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(1, -22, 0, 0),
                BackgroundColor3 = Color, AutoButtonColor = false, Text = "", Parent = Row,
            })
            corner(Swatch, 5)
            stroke(Swatch, Theme.Stroke, 1)

            local Panel = new("Frame", {
                Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Theme.Elevated, Visible = false, Parent = Frame,
            })
            corner(Panel, 6)
            stroke(Panel, Theme.Stroke, 1)
            pad(Panel, 10, 10, 10, 10)
            new("UIListLayout", { Padding = UDim.new(0, 8) }).Parent = Panel

            local api = { Instance = Frame, Value = Color }

            local sliders = {}
            local function makeChannel(name, initial)
                local CRow = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = Panel })
                new("UIListLayout", { Padding = UDim.new(0, 4) }).Parent = CRow
                local Top = new("Frame", { Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Parent = CRow })
                new("TextLabel", {
                    Text = name, Font = Theme.Font, TextSize = 11, TextColor3 = Theme.SubText,
                    BackgroundTransparency = 1, Size = UDim2.new(0.5, 0, 1, 0),
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = Top,
                })
                local ValLabel = new("TextLabel", {
                    Text = tostring(initial), Font = Theme.Font, TextSize = 11, TextColor3 = Theme.SubText,
                    BackgroundTransparency = 1, Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(0.5, 0, 0, 0),
                    TextXAlignment = Enum.TextXAlignment.Right, Parent = Top,
                })
                local Track = new("Frame", { Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = Theme.Background, Parent = CRow })
                corner(Track, 2)
                local Fill = new("Frame", { Size = UDim2.new(initial / 255, 0, 1, 0), BackgroundColor3 = Theme.Accent, Parent = Track })
                corner(Fill, 2)
                local Handle = new("Frame", {
                    Size = UDim2.new(0, 10, 0, 10), AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(initial / 255, 0, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1), Parent = Track,
                })
                corner(Handle, 5)
                return { Track = Track, Fill = Fill, Handle = Handle, ValLabel = ValLabel, Value = initial }
            end

            sliders.R = makeChannel("R", math.floor(Color.R * 255))
            sliders.G = makeChannel("G", math.floor(Color.G * 255))
            sliders.B = makeChannel("B", math.floor(Color.B * 255))

            local function applyColor(isInit)
                local old = api.Value
                Color = Color3.fromRGB(sliders.R.Value, sliders.G.Value, sliders.B.Value)
                api.Value = Color
                Swatch.BackgroundColor3 = Color
                if cfg.Flag then
                    Library.Flags[cfg.Flag] = Color
                    if not isInit then trackChange(cfg.Flag, old, Color) end
                end
                if cfg.Callback and not isInit then cfg.Callback(Color) end
            end

            for _, ch in pairs(sliders) do
                local dragging = false
                local function update(x)
                    local rel = math.clamp((x - ch.Track.AbsolutePosition.X) / ch.Track.AbsoluteSize.X, 0, 1)
                    ch.Value = math.floor(rel * 255)
                    ch.Fill.Size = UDim2.new(rel, 0, 1, 0)
                    ch.Handle.Position = UDim2.new(rel, 0, 0.5, 0)
                    ch.ValLabel.Text = tostring(ch.Value)
                    applyColor()
                end
                ch.Track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true update(input.Position.X) end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then update(input.Position.X) end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end)
            end

            Swatch.MouseButton1Click:Connect(function() Panel.Visible = not Panel.Visible end)

            function api:Set(c)
                sliders.R.Value = math.floor(c.R * 255)
                sliders.G.Value = math.floor(c.G * 255)
                sliders.B.Value = math.floor(c.B * 255)
                for _, ch in pairs(sliders) do
                    local rel = ch.Value / 255
                    ch.Fill.Size = UDim2.new(rel, 0, 1, 0)
                    ch.Handle.Position = UDim2.new(rel, 0, 0.5, 0)
                    ch.ValLabel.Text = tostring(ch.Value)
                end
                applyColor(true)
            end
            function api:Get() return Color end

            applyColor(true)
            if cfg.Flag then Library.FlagObjects[cfg.Flag] = api end
            return api
        end

        --====================================================
        -- TEXT INPUT / SEARCH BOX / TEXT AREA
        --====================================================
        function Tab:CreateInput(cfg)
            cfg = cfg or {}
            local Frame, Label = baseRow(cfg.Text)
            local Box = new("TextBox", {
                Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Theme.Elevated,
                TextColor3 = Theme.Text, Text = tostring(cfg.Default or ""), PlaceholderColor3 = Theme.Muted,
                Font = Theme.Font, TextSize = 13, ClearTextOnFocus = false, Parent = Frame,
            })
            corner(Box, 6)
            stroke(Box, Theme.Stroke, 1)
            pad(Box, 10, 0, 10, 0)

            local api = { Instance = Frame, Value = Box.Text }

            Box.FocusLost:Connect(function()
                local old = api.Value
                api.Value = Box.Text
                if cfg.Flag then
                    Library.Flags[cfg.Flag] = Box.Text
                    trackChange(cfg.Flag, old, Box.Text)
                end
                if cfg.Callback then cfg.Callback(Box.Text) end
            end)

            function api:Set(v) Box.Text = v api.Value = v end
            function api:Get() return Box.Text end

            if cfg.Flag then Library.Flags[cfg.Flag] = Box.Text Library.FlagObjects[cfg.Flag] = api end
            return api
        end

        function Tab:CreateSearchBox(cfg)
            cfg = cfg or {}
            local Box = new("TextBox", {
                Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Theme.Elevated,
                TextColor3 = Theme.Text, PlaceholderText = cfg.Text or "Search...",
                PlaceholderColor3 = Theme.Muted, Text = "", Font = Theme.Font, TextSize = 13,
                ClearTextOnFocus = false, Parent = Page,
            })
            corner(Box, 6)
            stroke(Box, Theme.Stroke, 1)
            pad(Box, 10, 0, 10, 0)
            Box:GetPropertyChangedSignal("Text"):Connect(function()
                if cfg.Callback then cfg.Callback(Box.Text) end
            end)
            return { Instance = Box }
        end

        function Tab:CreateTextArea(cfg)
            cfg = cfg or {}
            local Frame, Label = baseRow(cfg.Text)
            local Box = new("TextBox", {
                Size = UDim2.new(1, 0, 0, cfg.Height or 100), BackgroundColor3 = Theme.Elevated,
                TextColor3 = Theme.Text, Text = cfg.Default or "", PlaceholderColor3 = Theme.Muted,
                Font = Theme.Font, TextSize = 13, ClearTextOnFocus = false, MultiLine = true,
                TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true, Parent = Frame,
            })
            corner(Box, 6)
            stroke(Box, Theme.Stroke, 1)
            pad(Box, 10, 8, 10, 8)

            local api = { Instance = Frame, Value = Box.Text }
            Box.FocusLost:Connect(function()
                local old = api.Value
                api.Value = Box.Text
                if cfg.Flag then
                    Library.Flags[cfg.Flag] = Box.Text
                    trackChange(cfg.Flag, old, Box.Text)
                end
                if cfg.Callback then cfg.Callback(Box.Text) end
            end)

            function api:Set(v) Box.Text = v api.Value = v end
            function api:Get() return Box.Text end

            if cfg.Flag then Library.Flags[cfg.Flag] = Box.Text Library.FlagObjects[cfg.Flag] = api end
            return api
        end

        --====================================================
        -- GRAPH (auto-sampling sparkline)
        --====================================================
        function Tab:CreateGraph(cfg)
            cfg = cfg or {}
            local MaxPoints = cfg.MaxPoints or 30
            local Interval = cfg.Interval or 0.5
            local Suffix = cfg.Suffix or ""
            local Places = cfg.Places or 0

            local Frame = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = Page })
            new("UIListLayout", { Padding = UDim.new(0, 6) }).Parent = Frame

            local Top = new("Frame", { Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Parent = Frame })
            new("TextLabel", {
                Text = cfg.Text or "", Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Text,
                BackgroundTransparency = 1, Size = UDim2.new(0.6, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left, Parent = Top,
            })
            local ValueLabel = new("TextLabel", {
                Text = "", Font = Theme.Font, TextSize = 13, TextColor3 = Theme.SubText,
                BackgroundTransparency = 1, Size = UDim2.new(0.4, 0, 1, 0), Position = UDim2.new(0.6, 0, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Right, Parent = Top,
            })

            local ChartArea = new("Frame", { Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = Theme.Elevated, ClipsDescendants = true, Parent = Frame })
            corner(ChartArea, 6)
            local BarHolder = new("Frame", {
                Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = ChartArea,
            })
            new("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Bottom,
                HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }).Parent = BarHolder

            local points = {}
            local api = { Instance = Frame }

            local running = true
            task.spawn(function()
                while running and Frame.Parent do
                    if cfg.GetValue then
                        local v = cfg.GetValue()
                        table.insert(points, v)
                        if #points > MaxPoints then table.remove(points, 1) end
                        local maxV = 1
                        for _, p in ipairs(points) do if p > maxV then maxV = p end end
                        for _, c in ipairs(BarHolder:GetChildren()) do
                            if c:IsA("Frame") then c:Destroy() end
                        end
                        for _, p in ipairs(points) do
                            local bar = new("Frame", {
                                Size = UDim2.new(0, 4, math.clamp(p / maxV, 0.05, 1), 0),
                                BackgroundColor3 = Theme.Accent, Parent = BarHolder,
                            })
                            corner(bar, 1)
                        end
                        ValueLabel.Text = (Places > 0 and string.format("%." .. Places .. "f", v) or tostring(math.floor(v))) .. Suffix
                        api.Value = v
                    end
                    task.wait(Interval)
                end
            end)

            function api:Stop() running = false end

            return api
        end

        --====================================================
        -- SETTINGS TAB (pinned bottom, has Theme dropdown)
        --====================================================
        return Tab
    end

    function Window:CreateSettingsTab()
        local SettingsTab = Window:CreateTab("Settings", "settings", nil)
        SettingsTab.NavBtn.LayoutOrder = 100000

        SettingsTab:CreateSection("Appearance")

        local names = {}
        for name in pairs(ThemePresets) do table.insert(names, name) end
        table.sort(names)

        SettingsTab:CreateDropdown({
            Text = "Theme",
            Options = names,
            Default = "Purple (Default)",
            Callback = function(name)
                local color = ThemePresets[name]
                if not color then return end
                Theme.Accent = color
                for _, bound in ipairs(Library.AccentBound) do
                    if bound.Instance and bound.Instance.Parent then
                        tween(bound.Instance, { [bound.Prop] = color }, 0.2)
                    end
                end
            end,
        })

        SettingsTab:CreateParagraph({
            Text = "Theme changes apply to accent-colored elements. New elements created afterwards use the selected theme automatically.",
        })

        return SettingsTab
    end

    return Window
end

return Library
