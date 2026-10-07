--[[
    SpectreUI - dark/purple Roblox UI library
    Window / Sidebar tabs / Search / Sections / Toggle / Dropdown / Slider / Button / Label / Divider / Notify

    local Library = loadstring(readfile("SpectreUI.lua"))()   -- or require(module)
    local Window  = Library:CreateWindow({ Title = "SpectreWare | Anime Astral" })
    local Tab     = Window:CreateTab({ Name = "Main", Icon = "M" })
    local Section = Tab:CreateSection({ Name = "Settings" })
    Section:CreateToggle({ Name = "Example", Default = false, Flag = "ex", Callback = function(v) end })

    Window options : Title, Logo (asset id), Width, Height, ToggleKey (Enum.KeyCode), Theme (table), OnClose
    Tab options    : Name, Icon (text glyph, or asset id number / "rbxassetid://..")
    Section options: Name, Column (1|2), Collapsible (default true), Collapsed
    Controls       : CreateToggle / CreateDropdown / CreateSlider / CreateButton / CreateLabel / CreateDivider
    Every control  : Flag (stores value in Library.Flags[Flag]); returned object has :Set / :Get where it makes sense
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local Library = { Flags = {}, Windows = {} }
Library.__index = Library

Library.Theme = {
	Background = Color3.fromRGB(9, 8, 15),
	Panel = Color3.fromRGB(15, 13, 25),
	Card = Color3.fromRGB(17, 15, 28),
	Control = Color3.fromRGB(24, 21, 38),
	Border = Color3.fromRGB(52, 40, 92),
	Accent = Color3.fromRGB(124, 58, 237),
	AccentSoft = Color3.fromRGB(36, 22, 72),
	Text = Color3.fromRGB(236, 234, 245),
	SubText = Color3.fromRGB(148, 144, 172),
	Font = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,
}

local Window, Tab, Section = {}, {}, {}
Window.__index, Tab.__index, Section.__index = Window, Tab, Section

local AY = Enum.AutomaticSize.Y
local AX = Enum.AutomaticSize.X
local LEFT = Enum.TextXAlignment.Left
local HEADER_H, SEARCH_H, FOOT_H = 44, 36, 54

------------------------------------------------------------------ helpers
local function new(class, props, children)
	local o = Instance.new(class)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then parent = v else o[k] = v end
	end
	for _, c in ipairs(children or {}) do c.Parent = o end
	if parent then o.Parent = parent end
	return o
end

local function tween(o, t, props)
	TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function corner(r) return new("UICorner", { CornerRadius = UDim.new(0, r) }) end

local function stroke(color, thickness, transparency)
	return new("UIStroke", {
		Color = color, Thickness = thickness or 1, Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function padding(l, t, r, b)
	return new("UIPadding", {
		PaddingLeft = UDim.new(0, l), PaddingTop = UDim.new(0, t),
		PaddingRight = UDim.new(0, r), PaddingBottom = UDim.new(0, b),
	})
end

local function list(gap, props)
	local p = { Padding = UDim.new(0, gap), SortOrder = Enum.SortOrder.LayoutOrder }
	for k, v in pairs(props or {}) do p[k] = v end
	return new("UIListLayout", p)
end

local function safe(cb, ...)
	if not cb then return end
	local ok, err = pcall(cb, ...)
	if not ok then warn("[SpectreUI] callback error: " .. tostring(err)) end
end

local function isPress(i)
	return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end

local function isMove(i)
	return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch
end

local function rowH() return UserInputService.TouchEnabled and 36 or 30 end

-- hover / pressed feedback (color tween on `target`)
local function feedback(btn, target, base, hover, press)
	local touch = UserInputService.TouchEnabled
	btn.MouseEnter:Connect(function() tween(target, 0.12, { BackgroundColor3 = hover }) end)
	btn.MouseLeave:Connect(function() tween(target, 0.12, { BackgroundColor3 = base }) end)
	btn.MouseButton1Down:Connect(function() tween(target, 0.08, { BackgroundColor3 = press }) end)
	btn.MouseButton1Up:Connect(function() tween(target, 0.12, { BackgroundColor3 = touch and base or hover }) end)
end

local function snap(v, min, max, inc)
	v = min + math.floor((v - min) / inc + 0.5) * inc
	v = math.clamp(v, min, max)
	return math.floor(v * 1e5 + 0.5) / 1e5
end

------------------------------------------------------------------ window
function Library:CreateWindow(cfg)
	cfg = cfg or {}
	local T = table.clone(self.Theme)
	for k, v in pairs(cfg.Theme or {}) do T[k] = v end

	local win = setmetatable({
		Library = self, Theme = T, Cfg = cfg, Tabs = {}, Conns = {}, Visible = true,
	}, Window)

	local title = cfg.Title or "SpectreUI"
	local brand, sub = title:match("^(.-)%s*|%s*(.+)$")
	brand = brand or title
	win.Brand, win.Sub = brand, sub

	local gui = new("ScreenGui", {
		Name = "SpectreUI", ResetOnSpawn = false, IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
	})
	local ok = pcall(function() gui.Parent = (gethui and gethui()) or CoreGui end)
	if not ok or not gui.Parent then gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end
	win.Gui = gui

	local main = new("Frame", {
		Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = T.Background, BackgroundTransparency = 0.04, BorderSizePixel = 0, Parent = gui,
	}, { corner(12), stroke(T.Border, 1, 0.1) })
	win.Main = main
	win.Scale = new("UIScale", { Scale = 1, Parent = main })

	---------------------------------------------------------- header
	local header = new("Frame", {
		Name = "Header", Size = UDim2.new(1, 0, 0, HEADER_H), BackgroundTransparency = 1, Parent = main,
	})
	new("Frame", {
		Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = T.Border,
		BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = header,
	})
	local left = new("Frame", {
		Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AX, BackgroundTransparency = 1, Parent = header,
	}, {
		list(8, { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center }),
		padding(14, 0, 0, 0),
	})
	if cfg.Logo then
		new("ImageLabel", {
			LayoutOrder = 1, Size = UDim2.fromOffset(26, 26), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit,
			Image = type(cfg.Logo) == "number" and ("rbxassetid://" .. cfg.Logo) or cfg.Logo, Parent = left,
		})
	else
		new("TextLabel", {
			LayoutOrder = 1, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AX, BackgroundTransparency = 1,
			Text = brand:sub(1, 2), Font = Enum.Font.GothamBlack, TextSize = 20, TextColor3 = T.Accent, Parent = left,
		})
	end
	new("TextLabel", {
		LayoutOrder = 2, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AX, BackgroundTransparency = 1,
		Text = brand, Font = T.FontBold, TextSize = 15, TextColor3 = T.Text, Parent = left,
	})
	if sub then
		win.SubSep = new("Frame", {
			LayoutOrder = 3, Size = UDim2.fromOffset(1, 18), BackgroundColor3 = T.Border, BorderSizePixel = 0, Parent = left,
		})
		win.SubLabel = new("TextLabel", {
			LayoutOrder = 4, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AX, BackgroundTransparency = 1,
			Text = sub, Font = T.FontBold, TextSize = 15, TextColor3 = T.Text, Parent = left,
		})
	end

	local close = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(34, 34),
		BackgroundTransparency = 1, Text = "×", Font = T.FontBold, TextSize = 28, TextColor3 = T.SubText,
		AutoButtonColor = false, Parent = header,
	})
	close.MouseEnter:Connect(function() tween(close, 0.12, { TextColor3 = T.Text }) end)
	close.MouseLeave:Connect(function() tween(close, 0.12, { TextColor3 = T.SubText }) end)
	close.MouseButton1Click:Connect(function()
		win:SetVisible(false)
		safe(cfg.OnClose)
	end)

	-- drag by header
	local dragMove, dragEnd
	header.InputBegan:Connect(function(i)
		if not isPress(i) then return end
		win:CloseDropdowns()
		local start, startPos = i.Position, main.Position
		dragMove = UserInputService.InputChanged:Connect(function(m)
			if isMove(m) then
				local d = m.Position - start
				main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end)
		dragEnd = UserInputService.InputEnded:Connect(function(e)
			if isPress(e) then
				if dragMove then dragMove:Disconnect() end
				if dragEnd then dragEnd:Disconnect() end
			end
		end)
	end)

	---------------------------------------------------------- body / sidebar
	local body = new("Frame", {
		Position = UDim2.fromOffset(0, HEADER_H), Size = UDim2.new(1, 0, 1, -HEADER_H),
		BackgroundTransparency = 1, Parent = main,
	})
	local sidebar = new("Frame", { Size = UDim2.new(0, 164, 1, 0), BackgroundTransparency = 1, Parent = body })
	new("Frame", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = T.Border, BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = sidebar,
	})
	win.Sidebar = sidebar
	win.TabList = new("ScrollingFrame", {
		Size = UDim2.new(1, -1, 1, -FOOT_H), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = AY, Parent = sidebar,
	}, { list(6), padding(10, 12, 10, 8) })

	local footer = new("Frame", {
		Position = UDim2.new(0, 0, 1, -FOOT_H), Size = UDim2.new(1, -1, 0, FOOT_H), BackgroundTransparency = 1, Parent = sidebar,
	}, { padding(16, 0, 8, 0) })
	new("Frame", {
		Position = UDim2.new(0, -6, 0, 0), Size = UDim2.new(1, -4, 0, 1), BackgroundColor3 = T.Border,
		BackgroundTransparency = 0.6, BorderSizePixel = 0, Parent = footer,
	})
	new("TextLabel", {
		Position = UDim2.fromOffset(0, 10), Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = brand,
		Font = T.FontBold, TextSize = 15, TextColor3 = T.Accent, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = footer,
	})
	if sub then
		new("TextLabel", {
			Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = sub,
			Font = T.Font, TextSize = 12, TextColor3 = T.SubText, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = footer,
		})
	end
	win.Footer = footer

	---------------------------------------------------------- content / search
	local content = new("Frame", {
		Position = UDim2.fromOffset(164, 0), Size = UDim2.new(1, -164, 1, 0), BackgroundTransparency = 1, Parent = body,
	})
	win.Content = content
	local searchBar = new("Frame", {
		Position = UDim2.fromOffset(12, 12), Size = UDim2.new(1, -24, 0, SEARCH_H), BackgroundColor3 = T.Control,
		BackgroundTransparency = 0.2, BorderSizePixel = 0, Parent = content,
	}, { corner(8), stroke(T.Border, 1, 0.3) })
	-- magnifier drawn from frames (no asset needed)
	local mag = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1, Parent = searchBar,
	})
	new("Frame", {
		Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1, Parent = mag,
	}, { corner(5), stroke(T.SubText, 1.5, 0) })
	new("Frame", {
		Position = UDim2.fromOffset(8, 10), Size = UDim2.fromOffset(6, 2), Rotation = 45, BackgroundColor3 = T.SubText,
		BorderSizePixel = 0, Parent = mag,
	})
	win.SearchBox = new("TextBox", {
		Position = UDim2.fromOffset(38, 0), Size = UDim2.new(1, -48, 1, 0), BackgroundTransparency = 1, Text = "",
		PlaceholderText = "Search...", PlaceholderColor3 = T.SubText, TextColor3 = T.Text, Font = T.Font, TextSize = 14,
		TextXAlignment = LEFT, ClearTextOnFocus = false, Parent = searchBar,
	})
	win.SearchBox:GetPropertyChangedSignal("Text"):Connect(function() win:_ApplySearch() end)

	win.Pages = new("Frame", {
		Position = UDim2.fromOffset(0, SEARCH_H + 22), Size = UDim2.new(1, 0, 1, -(SEARCH_H + 22) - 8),
		BackgroundTransparency = 1, ClipsDescendants = true, Parent = content,
	})

	---------------------------------------------------------- dropdown overlay + floating open button
	win.Overlay = new("TextButton", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
		Visible = false, ZIndex = 60, Parent = gui,
	})
	win.Overlay.MouseButton1Click:Connect(function() win:CloseDropdowns() end)

	win.OpenBtn = new("TextButton", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(42, 42),
		BackgroundColor3 = T.Panel, Text = brand:sub(1, 2), Font = Enum.Font.GothamBlack, TextSize = 16,
		TextColor3 = T.Accent, AutoButtonColor = false, Visible = false, Parent = gui,
	}, { corner(10), stroke(T.Accent, 1, 0.3) })
	win.OpenBtn.MouseButton1Click:Connect(function() win:SetVisible(true) end)

	---------------------------------------------------------- toggle key / responsive
	local key = cfg.ToggleKey or Enum.KeyCode.RightShift
	table.insert(win.Conns, UserInputService.InputBegan:Connect(function(i)
		if i.KeyCode == key and not UserInputService:GetFocusedTextBox() then win:SetVisible(not win.Visible) end
	end))
	table.insert(win.Conns, gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() win:_Fit() end))
	win:_Fit()

	table.insert(self.Windows, win)
	return win
end

function Window:_Fit()
	local vp = self.Gui.AbsoluteSize
	if vp.X <= 0 then return end
	local w = math.min(self.Cfg.Width or 820, vp.X - 16)
	local h = math.min(self.Cfg.Height or 540, vp.Y - 16)
	self.Main.Size = UDim2.fromOffset(w, h)

	local compact = w < 560
	local sw = compact and 56 or 164
	self.Sidebar.Size = UDim2.new(0, sw, 1, 0)
	self.Content.Position = UDim2.fromOffset(sw, 0)
	self.Content.Size = UDim2.new(1, -sw, 1, 0)
	local twoCol = (w - sw) >= 520

	if compact ~= self.Compact then
		self.Compact = compact
		self.Footer.Visible = not compact
		if self.SubLabel then self.SubLabel.Visible = not compact; self.SubSep.Visible = not compact end
		for _, t in ipairs(self.Tabs) do t:_ApplyCompact(compact) end
	end
	if twoCol ~= self.TwoCol then
		self.TwoCol = twoCol
		for _, t in ipairs(self.Tabs) do t:_QueueRelayout() end
	end
end

function Window:CloseDropdowns()
	if self._dd then self._dd:Close() end
end

function Window:SetVisible(v)
	if self.Visible == v then return end
	self.Visible = v
	self:CloseDropdowns()
	if v then
		self.OpenBtn.Visible = false
		self.Main.Visible = true
		self.Scale.Scale = 0.92
		tween(self.Scale, 0.18, { Scale = 1 })
	else
		tween(self.Scale, 0.15, { Scale = 0.92 })
		task.delay(0.15, function()
			if not self.Visible then
				self.Main.Visible = false
				self.OpenBtn.Visible = true
			end
		end)
	end
end

function Window:Toggle() self:SetVisible(not self.Visible) end

function Window:Destroy()
	for _, c in ipairs(self.Conns) do c:Disconnect() end
	self.Gui:Destroy()
	for i, w in ipairs(Library.Windows) do
		if w == self then table.remove(Library.Windows, i) break end
	end
end

function Window:_ApplySearch()
	local tab = self.Active
	if not tab then return end
	local q = self.SearchBox.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
	for _, s in ipairs(tab.Sections) do
		local secMatch = q == "" or s.Name:lower():find(q, 1, true) ~= nil
		local any = false
		for _, c in ipairs(s.Controls) do
			local vis = secMatch or c.Name:find(q, 1, true) ~= nil
			c.Frame.Visible = vis
			any = any or vis
		end
		s.Frame.Visible = secMatch or any
	end
	tab:_QueueRelayout()
end

function Window:SelectTab(tab)
	if self.Active == tab then return end
	self:CloseDropdowns()
	local prev = self.Active
	if prev then
		prev.Page.Visible = false
		prev:_SetSelected(false)
	end
	self.Active = tab
	tab.Page.Visible = true
	tab.Page.Position = UDim2.fromOffset(0, 12)
	tween(tab.Page, 0.2, { Position = UDim2.new() })
	tab:_SetSelected(true)
	self:_ApplySearch()
	tab:_QueueRelayout()
end

------------------------------------------------------------------ notifications
function Window:Notify(cfg)
	if type(cfg) == "string" then cfg = { Content = cfg } end
	cfg = cfg or {}
	local T = self.Theme
	local dur = cfg.Duration or 4
	if not self.NotifyHolder then
		self.NotifyHolder = new("Frame", {
			AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -14), Size = UDim2.new(0, 260, 1, -28),
			BackgroundTransparency = 1, ZIndex = 100, Parent = self.Gui,
		}, { list(8, { VerticalAlignment = Enum.VerticalAlignment.Bottom }) })
	end
	local wrap = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Parent = self.NotifyHolder })
	local card = new("Frame", {
		Position = UDim2.fromOffset(50, 0), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundColor3 = T.Panel,
		BackgroundTransparency = 1, BorderSizePixel = 0, Parent = wrap,
	}, { corner(9), stroke(T.Accent, 1, 0.5), list(4), padding(12, 10, 12, 10) })
	new("TextLabel", {
		LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Text = cfg.Title or "Notice",
		Font = T.FontBold, TextSize = 14, TextColor3 = T.Text, TextXAlignment = LEFT, TextWrapped = true, Parent = card,
	})
	if cfg.Content then
		new("TextLabel", {
			LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Text = cfg.Content,
			Font = T.Font, TextSize = 13, TextColor3 = T.SubText, TextXAlignment = LEFT, TextWrapped = true, Parent = card,
		})
	end
	local bar = new("Frame", {
		LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = T.Accent, BorderSizePixel = 0, Parent = card,
	}, { corner(1) })
	tween(card, 0.2, { Position = UDim2.new(), BackgroundTransparency = 0.05 })
	TweenService:Create(bar, TweenInfo.new(dur, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) }):Play()
	task.delay(dur, function()
		if not wrap.Parent then return end
		tween(card, 0.2, { Position = UDim2.fromOffset(50, 0), BackgroundTransparency = 1 })
		task.delay(0.2, function() wrap:Destroy() end)
	end)
end

function Library:Notify(cfg)
	local w = self.Windows[#self.Windows]
	if w then w:Notify(cfg) end
end

------------------------------------------------------------------ tabs
function Window:CreateTab(cfg)
	if type(cfg) == "string" then cfg = { Name = cfg } end
	cfg = cfg or {}
	local T = self.Theme
	local tab = setmetatable({ Window = self, Name = cfg.Name or "Tab", Sections = {} }, Tab)

	local btn = new("TextButton", {
		LayoutOrder = #self.Tabs + 1, Size = UDim2.new(1, 0, 0, UserInputService.TouchEnabled and 44 or 38),
		BackgroundColor3 = T.AccentSoft, BackgroundTransparency = 1, AutoButtonColor = false, Text = "", Parent = self.TabList,
	}, { corner(8), stroke(T.Accent, 1, 1) })
	tab.Button = btn
	tab.BtnStroke = btn:FindFirstChildOfClass("UIStroke")
	tab.Indicator = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0), Size = UDim2.new(0, 3, 0, 0),
		BackgroundColor3 = T.Accent, BorderSizePixel = 0, Parent = btn,
	}, { corner(2) })

	local ic = cfg.Icon
	if type(ic) == "number" or (type(ic) == "string" and ic:find("^rbxasset")) then
		tab.Icon = new("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1,
			Image = type(ic) == "number" and ("rbxassetid://" .. ic) or ic, ImageColor3 = T.SubText, Parent = btn,
		})
	else
		tab.Icon = new("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1,
			Text = ic or tab.Name:sub(1, 1):upper(), Font = T.FontBold, TextSize = 16, TextColor3 = T.SubText, Parent = btn,
		})
	end
	tab.Label = new("TextLabel", {
		Position = UDim2.fromOffset(46, 0), Size = UDim2.new(1, -52, 1, 0), BackgroundTransparency = 1, Text = tab.Name,
		Font = T.Font, TextSize = 14, TextColor3 = T.SubText, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = btn,
	})
	tab:_ApplyCompact(self.Compact or false)

	btn.MouseEnter:Connect(function()
		if self.Active ~= tab then tween(tab.Label, 0.12, { TextColor3 = T.Text }) end
	end)
	btn.MouseLeave:Connect(function()
		if self.Active ~= tab then tween(tab.Label, 0.12, { TextColor3 = T.SubText }) end
	end)
	btn.MouseButton1Click:Connect(function() self:SelectTab(tab) end)

	-- page
	tab.Page = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = self.Pages })
	tab.Scroll = new("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
		ScrollBarImageColor3 = T.Accent, CanvasSize = UDim2.new(), AutomaticCanvasSize = AY,
		ScrollingDirection = Enum.ScrollingDirection.Y, Parent = tab.Page,
	}, { padding(12, 0, 14, 8) })
	local holder = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Parent = tab.Scroll },
		{ list(12, { FillDirection = Enum.FillDirection.Horizontal }) })
	tab.Cols = {}
	for i = 1, 2 do
		tab.Cols[i] = new("Frame", {
			LayoutOrder = i, Size = UDim2.new(0.5, -6, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Parent = holder,
		}, { list(12) })
	end

	table.insert(self.Tabs, tab)
	if not self.Active then self:SelectTab(tab) end
	return tab
end

function Tab:_ApplyCompact(c)
	self.Label.Visible = not c
	self.Icon.Position = c and UDim2.fromScale(0.5, 0.5) or UDim2.new(0, 26, 0.5, 0)
end

function Tab:_SetSelected(sel)
	local T = self.Window.Theme
	tween(self.Button, 0.18, { BackgroundTransparency = sel and 0 or 1 })
	tween(self.BtnStroke, 0.18, { Transparency = sel and 0.35 or 1 })
	tween(self.Indicator, 0.18, { Size = UDim2.new(0, 3, sel and 0.55 or 0, 0) })
	tween(self.Label, 0.18, { TextColor3 = sel and T.Text or T.SubText })
	local prop = self.Icon:IsA("ImageLabel") and "ImageColor3" or "TextColor3"
	tween(self.Icon, 0.18, { [prop] = sel and T.Accent or T.SubText })
end

function Tab:_QueueRelayout()
	if self._rq then return end
	self._rq = true
	task.defer(function()
		self._rq = false
		self:_Relayout()
	end)
end

function Tab:_Relayout()
	local two = self.Window.TwoCol
	local c1, c2 = self.Cols[1], self.Cols[2]
	c2.Visible = two and true or false
	c1.Size = two and UDim2.new(0.5, -6, 0, 0) or UDim2.new(1, 0, 0, 0)
	local h1, h2 = 0, 0
	for i, s in ipairs(self.Sections) do
		local col
		if not two then col = 1
		elseif s.Column then col = s.Column
		else col = (h1 <= h2) and 1 or 2 end
		s.Frame.LayoutOrder = i
		s.Frame.Parent = (col == 1) and c1 or c2
		if s.Frame.Visible then
			if col == 1 then h1 += s.Est + 12 else h2 += s.Est + 12 end
		end
	end
end

------------------------------------------------------------------ sections
function Tab:CreateSection(cfg)
	if type(cfg) == "string" then cfg = { Name = cfg } end
	cfg = cfg or {}
	local T = self.Window.Theme
	local s = setmetatable({
		Tab = self, Window = self.Window, Name = cfg.Name or "Section", Controls = {}, Est = 35 + 20, Column = cfg.Column,
	}, Section)

	s.Frame = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundColor3 = T.Card, BackgroundTransparency = 0.15,
		BorderSizePixel = 0, Parent = self.Cols[1],
	}, { corner(10), stroke(T.Border, 1, 0.35), list(0, { HorizontalAlignment = Enum.HorizontalAlignment.Center }) })

	local head = new("TextButton", {
		LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = s.Frame,
	})
	new("TextLabel", {
		Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -40, 1, 0), BackgroundTransparency = 1, Text = s.Name,
		Font = T.FontBold, TextSize = 14, TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = head,
	})
	local arrow = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(12, 12),
		BackgroundTransparency = 1, Text = "▼", Font = T.FontBold, TextSize = 10, TextColor3 = T.Accent,
		Visible = cfg.Collapsible ~= false, Parent = head,
	})
	new("Frame", {
		LayoutOrder = 2, Size = UDim2.new(1, -24, 0, 1), BackgroundColor3 = T.Border, BackgroundTransparency = 0.5,
		BorderSizePixel = 0, Parent = s.Frame,
	})
	s.Body = new("Frame", {
		LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Parent = s.Frame,
	}, { list(6), padding(12, 10, 12, 12) })

	function s:SetCollapsed(c)
		self.Collapsed = c
		self.Body.Visible = not c
		tween(arrow, 0.15, { Rotation = c and -90 or 0 })
	end
	if cfg.Collapsible ~= false then
		head.MouseButton1Click:Connect(function() s:SetCollapsed(not s.Collapsed) end)
	end
	if cfg.Collapsed then s:SetCollapsed(true) end

	table.insert(self.Sections, s)
	self:_QueueRelayout()
	return s
end

function Section:_Register(frame, name, est)
	table.insert(self.Controls, { Frame = frame, Name = (name or ""):lower() })
	frame.LayoutOrder = #self.Controls
	self.Est += est + 6
	self.Tab:_QueueRelayout()
end

local function setFlag(cfg, v)
	if cfg.Flag then Library.Flags[cfg.Flag] = v end
end

------------------------------------------------------------------ controls
function Section:CreateLabel(cfg)
	if type(cfg) == "string" then cfg = { Text = cfg } end
	local T = self.Window.Theme
	local l = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Text = cfg.Text or cfg.Name or "",
		Font = T.Font, TextSize = 13, TextColor3 = T.SubText, TextXAlignment = LEFT, TextWrapped = true, Parent = self.Body,
	})
	self:_Register(l, cfg.Text or cfg.Name, 18)
	local obj = {}
	function obj:Set(t) l.Text = t end
	return obj
end

function Section:CreateDivider()
	local T = self.Window.Theme
	local d = new("Frame", {
		Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.Border, BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = self.Body,
	})
	self:_Register(d, "", 1)
end

function Section:CreateButton(cfg)
	local T = self.Window.Theme
	local b = new("TextButton", {
		Size = UDim2.new(1, 0, 0, rowH()), BackgroundColor3 = T.Control, BackgroundTransparency = 0.1, AutoButtonColor = false,
		Text = cfg.Name or "Button", Font = T.Font, TextSize = 13, TextColor3 = T.Text, Parent = self.Body,
	}, { corner(7), stroke(T.Border, 1, 0.35) })
	feedback(b, b, T.Control, Color3.fromRGB(34, 30, 54), T.AccentSoft)
	b.MouseButton1Click:Connect(function() safe(cfg.Callback) end)
	self:_Register(b, cfg.Name, rowH())
	local obj = {}
	function obj:SetText(t) b.Text = t end
	return obj
end

function Section:CreateToggle(cfg)
	local T = self.Window.Theme
	local h = rowH()
	local value = cfg.Default and true or false
	local row = new("TextButton", {
		Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = self.Body,
	})
	new("TextLabel", {
		Size = UDim2.new(1, -52, 1, 0), BackgroundTransparency = 1, Text = cfg.Name or "Toggle", Font = T.Font, TextSize = 14,
		TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
	})
	local track = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(38, 20),
		BackgroundColor3 = value and T.Accent or T.Control, BorderSizePixel = 0, Parent = row,
	}, { corner(10) })
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = value and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(14, 14), BackgroundColor3 = Color3.fromRGB(245, 243, 255), BorderSizePixel = 0, Parent = track,
	}, { corner(7) })

	local obj = {}
	function obj:Set(v, silent)
		value = v and true or false
		tween(track, 0.15, { BackgroundColor3 = value and T.Accent or T.Control })
		tween(knob, 0.15, { Position = value and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) })
		setFlag(cfg, value)
		if not silent then safe(cfg.Callback, value) end
	end
	function obj:Get() return value end
	row.MouseButton1Click:Connect(function() obj:Set(not value) end)
	setFlag(cfg, value)
	self:_Register(row, cfg.Name, h)
	return obj
end

function Section:CreateSlider(cfg)
	local T = self.Window.Theme
	local tab = self.Tab
	local min, max, inc = cfg.Min or 0, cfg.Max or 100, cfg.Increment or 1
	local value = snap(cfg.Default or min, min, max, inc)
	local suffix = cfg.Suffix or ""
	local total = UserInputService.TouchEnabled and 50 or 42

	local frame = new("Frame", { Size = UDim2.new(1, 0, 0, total), BackgroundTransparency = 1, Parent = self.Body })
	new("TextLabel", {
		Size = UDim2.new(1, -70, 0, 18), BackgroundTransparency = 1, Text = cfg.Name or "Slider", Font = T.Font, TextSize = 14,
		TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
	})
	local valLabel = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(66, 18), BackgroundTransparency = 1,
		Text = tostring(value) .. suffix, Font = T.Font, TextSize = 13, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Right, Parent = frame,
	})
	local hit = new("TextButton", {
		Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 1, -20), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = frame,
	})
	local track = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(1, 0, 0, 4),
		BackgroundColor3 = T.Control, BorderSizePixel = 0, Parent = hit,
	}, { corner(2) })
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = T.Accent, BorderSizePixel = 0, Parent = track }, { corner(2) })
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(12, 12),
		BackgroundColor3 = Color3.fromRGB(245, 243, 255), BorderSizePixel = 0, ZIndex = 2, Parent = track,
	}, { corner(6), stroke(T.Accent, 2, 0) })

	local obj = {}
	local function render(v, animate)
		local a = (max == min) and 0 or (v - min) / (max - min)
		valLabel.Text = tostring(v) .. suffix
		if animate then
			tween(fill, 0.1, { Size = UDim2.fromScale(a, 1) })
			tween(knob, 0.1, { Position = UDim2.fromScale(a, 0.5) })
		else
			fill.Size = UDim2.fromScale(a, 1)
			knob.Position = UDim2.fromScale(a, 0.5)
		end
	end
	function obj:Set(v, silent)
		v = snap(v, min, max, inc)
		local changed = v ~= value
		value = v
		render(v, true)
		setFlag(cfg, v)
		if changed and not silent then safe(cfg.Callback, v) end
	end
	function obj:Get() return value end
	render(value, false)
	setFlag(cfg, value)

	local function fromX(x)
		local a = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		local v = snap(min + (max - min) * a, min, max, inc)
		if v ~= value then
			value = v
			render(v, false)
			setFlag(cfg, v)
			safe(cfg.Callback, v)
		end
	end

	local moveC, endC
	local function stop()
		if moveC then moveC:Disconnect() moveC = nil end
		if endC then endC:Disconnect() endC = nil end
		tab.Scroll.ScrollingEnabled = true
	end
	hit.InputBegan:Connect(function(i)
		if not isPress(i) then return end
		stop()
		tab.Scroll.ScrollingEnabled = false
		fromX(i.Position.X)
		moveC = UserInputService.InputChanged:Connect(function(m)
			if isMove(m) then fromX(m.Position.X) end
		end)
		endC = UserInputService.InputEnded:Connect(function(e)
			if isPress(e) then stop() end
		end)
	end)

	self:_Register(frame, cfg.Name, total)
	return obj
end

function Section:CreateDropdown(cfg)
	local T = self.Window.Theme
	local win = self.Window
	local h = rowH()
	local optH = UserInputService.TouchEnabled and 34 or 28
	local options = cfg.Options or {}
	local value

	local frame = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Parent = self.Body }, { list(4) })
	if cfg.Name then
		new("TextLabel", {
			LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = cfg.Name, Font = T.Font, TextSize = 14,
			TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
		})
	end
	local btn = new("TextButton", {
		LayoutOrder = 2, Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = T.Control, BackgroundTransparency = 0.1,
		AutoButtonColor = false, Text = "", Parent = frame,
	}, { corner(7), stroke(T.Border, 1, 0.35) })
	feedback(btn, btn, T.Control, Color3.fromRGB(32, 28, 50), T.AccentSoft)
	local txt = new("TextLabel", {
		Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -32, 1, 0), BackgroundTransparency = 1, Text = "Select...",
		Font = T.Font, TextSize = 13, TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = btn,
	})
	local arrow = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(12, 12),
		BackgroundTransparency = 1, Text = "▶", Font = T.FontBold, TextSize = 10, TextColor3 = T.Accent, Parent = btn,
	})

	local dd = { IsOpen = false }
	local popup, scroll, optBtns = nil, nil, {}

	local function paint()
		for opt, b in pairs(optBtns) do
			local sel = opt == value
			b.TextColor3 = sel and T.Accent or T.Text
			b.BackgroundTransparency = sel and 0 or 1
		end
	end

	local function buildOptions()
		for _, b in pairs(optBtns) do b:Destroy() end
		optBtns = {}
		for i, opt in ipairs(options) do
			local b = new("TextButton", {
				LayoutOrder = i, Size = UDim2.new(1, 0, 0, optH), BackgroundColor3 = T.AccentSoft, BackgroundTransparency = 1,
				AutoButtonColor = false, Text = tostring(opt), Font = T.Font, TextSize = 13, TextColor3 = T.Text,
				TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = scroll,
			}, { corner(5), padding(8, 0, 8, 0) })
			b.MouseEnter:Connect(function()
				if opt ~= value then tween(b, 0.1, { BackgroundTransparency = 0.6 }) end
			end)
			b.MouseLeave:Connect(function()
				if opt ~= value then tween(b, 0.1, { BackgroundTransparency = 1 }) end
			end)
			b.MouseButton1Click:Connect(function()
				dd:Set(opt)
				dd:Close()
			end)
			optBtns[opt] = b
		end
		paint()
	end

	local function build()
		popup = new("Frame", {
			Visible = false, ZIndex = 61, BackgroundColor3 = T.Panel, BorderSizePixel = 0, ClipsDescendants = true, Parent = win.Gui,
		}, { corner(7), stroke(T.Accent, 1, 0.45) })
		scroll = new("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
			ScrollBarImageColor3 = T.Accent, CanvasSize = UDim2.new(), AutomaticCanvasSize = AY, Parent = popup,
		}, { list(2), padding(4, 4, 6, 4) })
		buildOptions()
	end

	function dd:Open()
		if self.IsOpen then return end
		win:CloseDropdowns()
		if not popup then build() end
		local pos, size = btn.AbsolutePosition, btn.AbsoluteSize
		local maxH = UserInputService.TouchEnabled and 180 or 150
		local ph = math.min(#options * (optH + 2) + 6, maxH)
		local vp = win.Gui.AbsoluteSize
		local y = pos.Y + size.Y + 3
		if y + ph > vp.Y - 6 then y = math.max(6, pos.Y - ph - 3) end
		popup.Position = UDim2.fromOffset(pos.X, y)
		popup.Size = UDim2.fromOffset(size.X, 0)
		popup.Visible = true
		win.Overlay.Visible = true
		tween(popup, 0.14, { Size = UDim2.fromOffset(size.X, ph) })
		tween(arrow, 0.14, { Rotation = 90 })
		self.IsOpen = true
		win._dd = self
	end

	function dd:Close()
		if not self.IsOpen then return end
		self.IsOpen = false
		if win._dd == self then win._dd = nil end
		win.Overlay.Visible = false
		tween(arrow, 0.12, { Rotation = 0 })
		if popup then
			tween(popup, 0.12, { Size = UDim2.fromOffset(popup.AbsoluteSize.X, 0) })
			task.delay(0.12, function()
				if not self.IsOpen then popup.Visible = false end
			end)
		end
	end

	function dd:Set(v, silent)
		value = v
		txt.Text = v ~= nil and tostring(v) or "Select..."
		paint()
		setFlag(cfg, v)
		if not silent then safe(cfg.Callback, v) end
	end
	function dd:Get() return value end
	function dd:Refresh(newOptions, keep)
		options = newOptions or {}
		if not keep then self:Set(nil, true) end
		if popup then buildOptions() end
	end

	btn.MouseButton1Click:Connect(function()
		if dd.IsOpen then dd:Close() else dd:Open() end
	end)

	if cfg.Default ~= nil then dd:Set(cfg.Default, true) end
	setFlag(cfg, value)
	self:_Register(frame, cfg.Name, h + (cfg.Name and 20 or 0))
	return dd
end

return Library
