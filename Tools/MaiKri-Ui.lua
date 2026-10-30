local M = ...
local CFG, DEFAULTS, GuiService, Players, RunService, S, T, TweenService, UIS, dc, env, inputEnded, isPress, keyClick, langHooks, lp, on, onCleanup, onLang, saveCfg, saveSpare, setLang, svc, v2 =
	M.CFG, M.DEFAULTS, M.GuiService, M.Players, M.RunService, M.S, M.T, M.TweenService, M.UIS, M.dc, M.env, M.inputEnded, M.isPress, M.keyClick, M.langHooks, M.lp, M.on, M.onCleanup, M.onLang, M.saveCfg, M.saveSpare, M.setLang, M.svc, M.v2
local gui, capturing = nil, false
local C = {
	BG = Color3.fromRGB(10, 10, 12), BG2 = Color3.fromRGB(19, 18, 21), FIELD = Color3.fromRGB(30, 30, 35),
	LINE = Color3.fromRGB(58, 52, 48), OFF = Color3.fromRGB(74, 72, 78), TXT = Color3.fromRGB(240, 238, 234),
	DIM = Color3.fromRGB(145, 138, 132), ACC = Color3.fromRGB(255, 142, 32), ACC2 = Color3.fromRGB(255, 190, 90),
	ACCTXT = Color3.fromRGB(20, 12, 4), WHITE = Color3.new(1, 1, 1), RED = Color3.fromRGB(255, 92, 100), GREEN = Color3.fromRGB(46, 220, 130),
	DARK = Color3.fromRGB(20, 19, 22), BTN = Color3.fromRGB(16, 14, 14),
}
local GRAD = ColorSequence.new(C.ACC, C.ACC2)
local FONT, FONTB = Enum.Font.SourceSans, Enum.Font.SourceSansBold
local O, CENTER, AUTO = UDim2.fromOffset, Vector2.new(0.5, 0.5), Enum.AutomaticSize.Y
local LEFT, MID, HORIZ = Enum.TextXAlignment.Left, Enum.TextXAlignment.Center, Enum.FillDirection.Horizontal
local EASE_BACK = Enum.EasingStyle.Back
local order = 0
local function mk(class, p, parent, r, line)
	local o = Instance.new(class)
	if o:IsA("GuiObject") then
		order += 1
		o.BorderSizePixel, o.LayoutOrder, o.BackgroundTransparency = 0, order, p.BackgroundColor3 and 0 or 1
		if class == "TextLabel" or class == "TextButton" then
			o.Text, o.TextColor3, o.TextSize, o.Font, o.TextXAlignment = "", C.TXT, 14, FONT, LEFT
			if class == "TextButton" then o.AutoButtonColor = false end
		end
	end
	for k, v in pairs(p) do o[k] = v end
	if r then mk("UICorner", { CornerRadius = UDim.new(0, r) }, o) end
	if line then
		mk("UIStroke", { Color = line, Thickness = 1, Transparency = 0.25, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
	end
	o.Parent = parent
	return o
end
local function stack(o, gap, dir, va)
	mk("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, gap or 0),
		FillDirection = dir or Enum.FillDirection.Vertical, VerticalAlignment = va or Enum.VerticalAlignment.Top,
	}, o)
end
local function pad(o, x, y)
	mk("UIPadding", {
		PaddingLeft = UDim.new(0, x), PaddingRight = UDim.new(0, x), PaddingTop = UDim.new(0, y), PaddingBottom = UDim.new(0, y),
	}, o)
end
local function dot(size, color, parent, z)
	return mk("Frame", { Size = O(size, size), AnchorPoint = CENTER, BackgroundColor3 = color, ZIndex = z or 1 }, parent, size)
end
local function grad(o, rot, seq, tr)
	return mk("UIGradient", { Color = seq or GRAD, Rotation = rot or 0, Transparency = tr or NumberSequence.new(0) }, o)
end
local function kp(a, b) return NumberSequenceKeypoint.new(a, b) end
local function tw(o, props, t, style)
	TweenService:Create(o, TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end
local function loop(o, props, t, style)
	local tn = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), props)
	tn:Play()
	return tn
end
local function ripple(parent, size, pos, color, z, to, t)
	local w = mk("Frame", { Size = O(size, size), AnchorPoint = CENTER, Position = pos, ZIndex = z }, parent, 100, color)
	w.UIStroke.Thickness, w.UIStroke.Transparency = 2, 0
	tw(w, { Size = O(to, to) }, t)
	tw(w.UIStroke, { Transparency = 1 }, t)
	return w
end
local function pressFx(btn)
	local sc = mk("UIScale", {}, btn)
	on(btn.InputBegan, function(i) if isPress(i) then keyClick(false) tw(sc, { Scale = 0.95 }, 0.08) end end)
	on(btn.InputEnded, function(i) if isPress(i) then keyClick(true) tw(sc, { Scale = 1 }, 0.18, EASE_BACK) end end)
end
local function sepLine(parent)
	local ln = mk("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.WHITE, ClipsDescendants = true }, parent)
	grad(ln, 0, GRAD, NumberSequence.new({ kp(0, 1), kp(0.2, 0.35), kp(0.8, 0.35), kp(1, 1) }))
	local g = mk("Frame", { Size = UDim2.new(0.25, 0, 1, 0), Position = UDim2.fromScale(0.05, 0), BackgroundColor3 = C.WHITE, ZIndex = 2 }, ln)
	grad(g, 0, ColorSequence.new(C.ACC2), NumberSequence.new({ kp(0, 1), kp(0.5, 0), kp(1, 1) }))
	TweenService:Create(g, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, math.random() * 1.5),
		{ Position = UDim2.fromScale(0.7, 0) }):Play()
end
local function shine(parent, color, mid, dur, delay, visible)
	local f = mk("Frame", {
		Size = UDim2.new(0.28, 0, 1.6, 0), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(-0.4, 0, 0.5, 0),
		BackgroundColor3 = C.WHITE, Rotation = 18, ZIndex = 3, Visible = visible,
	}, parent)
	grad(f, 0, ColorSequence.new(color), NumberSequence.new({ kp(0, 1), kp(0.5, mid), kp(1, 1) }))
	TweenService:Create(f, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, delay),
		{ Position = UDim2.new(1.15, 0, 0.5, 0) }):Play()
	return f
end
local function sweepFx(parent, color, mid, dur, gap, first)
	local f = mk("Frame", {
		Size = UDim2.new(0.22, 0, 1.8, 0), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(-0.3, 0, 0.5, 0),
		BackgroundColor3 = C.WHITE, Rotation = 18, ZIndex = 3,
	}, parent)
	grad(f, 0, ColorSequence.new(color), NumberSequence.new({ kp(0, 1), kp(0.5, mid), kp(1, 1) }))
	task.spawn(function()
		task.wait(first or 0)
		while f:IsDescendantOf(game) do
			f.Position = UDim2.new(-0.3, 0, 0.5, 0)
			tw(f, { Position = UDim2.new(1.1, 0, 0.5, 0) }, dur, Enum.EasingStyle.Sine)
			task.wait(dur + gap)
		end
	end)
	return f
end
local function drag(h, start, move, fin)
	local stopPrev
	on(h.InputBegan, function(i)
		if not isPress(i) then return end
		if stopPrev then stopPrev() end
		local touch = i.UserInputType == Enum.UserInputType.Touch
		local p0 = touch and v2(i) or UIS:GetMouseLocation()
		local evP, released, rs, ec, ic, mv
		local function pointer()
			if not touch then return UIS:GetMouseLocation() end
			local live = v2(i)
			if live ~= p0 then return live end
			return evP or p0
		end
		local function finish()
			dc(rs, ec, ic, mv) rs, ec, ic, mv = nil, nil, nil, nil
			if stopPrev == finish then stopPrev = nil end
			if released then return end
			released = true
			keyClick(true)
			if fin then fin() end
		end
		stopPrev = finish
		keyClick(false)
		start(i)
		ec = UIS.InputEnded:Connect(function(j)
			if j == i or (not touch and j.UserInputType == Enum.UserInputType.MouseButton1) then finish() end
		end)
		mv = touch and UIS.InputChanged:Connect(function(j)
			if j.UserInputType == Enum.UserInputType.Touch and (j == i or (v2(j) - pointer()).Magnitude < 250) then evP = v2(j) end
		end)
		ic = i.Changed:Connect(function()
			if inputEnded(i) then finish() end
		end)
		rs = RunService.RenderStepped:Connect(function()
			if released then return end
			if not h.Parent or inputEnded(i)
				or (not touch and not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)) then
				return finish()
			end
			move(pointer() - p0)
		end)
	end)
end
local DRAG_MARGIN = 48
local function safeClamp(v, lo, hi)
	if hi < lo then hi = lo end
	return math.clamp(v, lo, hi)
end
local function topInset()
	local y = 0
	pcall(function() y = GuiService:GetGuiInset().Y end)
	return y
end
local function viewport()
	local v = gui and gui.AbsoluteSize or Vector2.zero
	if v.X < 100 or v.Y < 100 then
		local cam = workspace.CurrentCamera
		v = cam and cam.ViewportSize or Vector2.new(1280, 720)
	end
	return v
end
local dragStop = {}
local dragInput = {}
local function startDrag(node, i, onStart, onTap)
	if dragInput[node] == i and dragStop[node] then return end
	dragInput[node] = i
	if dragStop[node] then dragStop[node](true) end
	if onStart then onStart() end
	local touch = i.UserInputType == Enum.UserInputType.Touch
	local p0 = touch and Vector2.new(i.Position.X, i.Position.Y) or UIS:GetMouseLocation()
	local m0, cur, evMoved = UIS:GetMouseLocation(), p0, false
	local function pointer()
		if not touch then return UIS:GetMouseLocation() end
		local live = v2(i)
		if (live - p0).Magnitude > 0 then return live end
		if evMoved then return cur end
		local mm = UIS:GetMouseLocation() - m0
		if mm.Magnitude > 0 then return p0 + mm end
		return p0
	end
	local slop = touch and 8 or 4
	local base, a0 = node.Position, node.AbsolutePosition
	local target, shown, moved, released = Vector2.zero, Vector2.zero, false, false
	local rs, ec, ic, mv
	local function finish(force)
		dc(rs, ec, ic, mv) rs, ec, ic, mv = nil, nil, nil, nil
		if dragStop[node] == finish then dragStop[node] = nil end
		if force and node.Parent then
			node.Position = UDim2.new(base.X.Scale, base.X.Offset + target.X, base.Y.Scale, base.Y.Offset + target.Y)
		end
	end
	dragStop[node] = finish
	local function release()
		if released then return end
		released = true
		if not moved and onTap then task.defer(onTap) end
	end
	ec = UIS.InputEnded:Connect(function(j)
		if j == i or (not touch and j.UserInputType == Enum.UserInputType.MouseButton1) then
			release()
		elseif touch and j.UserInputType == Enum.UserInputType.Touch and (v2(j) - pointer()).Magnitude < 250 then
			release()
		end
	end)
	mv = touch and UIS.InputChanged:Connect(function(j)
		if j.UserInputType == Enum.UserInputType.Touch then
			local q = v2(j)
			if j == i or (q - pointer()).Magnitude < 250 then cur, evMoved = q, true end
		end
	end)
	ic = i.Changed:Connect(function()
		if inputEnded(i) then release() end
	end)
	rs = RunService.RenderStepped:Connect(function(dt)
		if not node.Parent then return finish() end
		if not released then
			if inputEnded(i)
				or (not touch and not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)) then
				release()
			else
				local d = pointer() - p0
				if moved or d.Magnitude >= slop then
					moved = true
					local vp, sz = viewport(), node.AbsoluteSize
					target = Vector2.new(
						safeClamp(a0.X + d.X, DRAG_MARGIN - sz.X, vp.X - DRAG_MARGIN) - a0.X,
						safeClamp(a0.Y + d.Y, -topInset(), vp.Y - DRAG_MARGIN) - a0.Y)
				end
			end
		end
		shown = shown:Lerp(target, 1 - math.exp(-34 * math.min(dt, 0.1)))
		if released and (target - shown).Magnitude < 0.4 then
			shown = target
		end
		node.Position = UDim2.new(base.X.Scale, base.X.Offset + shown.X, base.Y.Scale, base.Y.Offset + shown.Y)
		if released and shown == target then finish() end
	end)
end
local function smoothDrag(h, node, onStart, onTap)
	h.Active = true
	on(h.InputBegan, function(i)
		if isPress(i) then startDrag(node, i, onStart, onTap) end
	end)
end
local function nudgeIntoView(node)
	if not (gui and node.Parent and node.Visible) then return end
	local vp, sz, ap = viewport(), node.AbsoluteSize, node.AbsolutePosition
	local nx = safeClamp(ap.X, DRAG_MARGIN - sz.X, vp.X - DRAG_MARGIN)
	local ny = safeClamp(ap.Y, -topInset(), vp.Y - DRAG_MARGIN)
	if nx ~= ap.X or ny ~= ap.Y then
		local q = node.Position
		node.Position = UDim2.new(q.X.Scale, q.X.Offset + nx - ap.X, q.Y.Scale, q.Y.Offset + ny - ap.Y)
	end
end
local ring, SEG, segs = Instance.new("Folder"), 64, {}
onCleanup(function() ring:Destroy() end)
for k = 1, SEG do
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Material, p.Color, p.Transparency, p.Parent = Enum.Material.Neon, C.ACC:Lerp(C.ACC2, math.abs(k / SEG * 2 - 1)), 0.15, ring
	segs[k] = p
end
local function setSeg(p, a, b, tr)
	local len = (b - a).Magnitude
	p.Transparency = len < 0.01 and 1 or tr
	if len >= 0.01 then p.Size, p.CFrame = Vector3.new(0.25, 0.25, len), CFrame.lookAt((a + b) / 2, b) end
end
local function updateRing()
	local c = lp.Character
	local hrp = c and c:FindFirstChild("HumanoidRootPart")
	if not hrp then ring.Parent = nil return end
	ring.Parent = workspace
	local lv = hrp.CFrame.LookVector
	local fwd = Vector3.new(lv.X, 0, lv.Z)
	if fwd.Magnitude < 0.01 then return end
	fwd = fwd.Unit
	local right, head = fwd:Cross(Vector3.yAxis), c:FindFirstChild("Head")
	local base = Vector3.new(hrp.Position.X, head and head.Position.Y or hrp.Position.Y + 1.5, hrp.Position.Z)
	local h = S.half
	local function pt(deg)
		local a = math.rad(deg)
		return base + (fwd * math.cos(a) + right * math.sin(a)) * S.range
	end
	local tr = 0.12 + 0.1 * math.sin(os.clock() * 5)
	for k = 1, SEG do setSeg(segs[k], pt(-h + (k - 1) / SEG * 2 * h), pt(-h + k / SEG * 2 * h), tr) end
end
local ringConn
local function showRange(v)
	if v and not ringConn then
		ringConn = on(RunService.RenderStepped, updateRing)
		updateRing()
	elseif not v then
		if ringConn then ringConn:Disconnect() ringConn = nil end
		ring.Parent = nil
	end
end
gui = mk("ScreenGui", { Name = "MaiKriUI", ResetOnSpawn = false, DisplayOrder = 999, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
M.gui = gui
if not pcall(function() gui.Parent = (gethui and gethui()) or svc("CoreGui") end) or not gui.Parent then
	gui.Parent = lp:WaitForChild("PlayerGui")
end
local W, ddOpen = 440, false
local paint
local main = mk("Frame", {
	Size = UDim2.new(0, W, 0, 0), AutomaticSize = AUTO, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -90), Active = true,
}, gui)
stack(main, 8)
local uiScale = mk("UIScale", {}, main)
local function fitScale()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	local base = UIS.TouchEnabled and math.clamp(math.min(vp.X / (W + 24), vp.Y / (ddOpen and 650 or 510), 1), 0.5, 1) or 1
	uiScale.Scale = math.clamp(base * CFG.scale / 100, 0.4, 1.4)
end
fitScale()
if workspace.CurrentCamera then on(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), fitScale) end
local introTw = TweenService:Create(main, TweenInfo.new(0.6, EASE_BACK, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, 0, 8) })
introTw:Play()
local panel = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO, BackgroundColor3 = C.WHITE }, main, 16)
grad(panel, 90, ColorSequence.new(Color3.fromRGB(32, 23, 16), Color3.fromRGB(11, 10, 12)))
panel.BackgroundTransparency = 1 - CFG.opacity / 100
local popScale = mk("UIScale", { Scale = 0.88 }, panel)
tw(popScale, { Scale = 1 }, 0.55, EASE_BACK)
local panelStroke = mk("UIStroke", { Color = C.WHITE, Thickness = 1.5, Transparency = 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, panel)
local strokeGrad = grad(panelStroke, 0, ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(78, 66, 56)), ColorSequenceKeypoint.new(0.3, C.ACC),
	ColorSequenceKeypoint.new(0.5, C.ACC2), ColorSequenceKeypoint.new(0.7, C.ACC),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(78, 66, 56)),
}), NumberSequence.new(0.2, 0.15))
TweenService:Create(strokeGrad, TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Rotation = 360 }):Play()
loop(panelStroke, { Transparency = 0.4 }, 2.2)
do
	local layer = mk("Frame", { Size = UDim2.fromScale(1, 1), ClipsDescendants = true, ZIndex = 0 }, panel)
	local rnd, lin = Random.new(), Enum.EasingStyle.Linear
	for k = 1, 16 do
		local sz = rnd:NextInteger(2, 4)
		local sp = mk("Frame", {
			Size = O(sz, sz), AnchorPoint = CENTER, BackgroundColor3 = k % 3 == 0 and C.ACC2 or C.ACC, BackgroundTransparency = 1,
		}, layer, sz)
		task.spawn(function()
			task.wait(rnd:NextNumber(0, 6))
			while sp:IsDescendantOf(game) do
				local x, dur = rnd:NextNumber(0.06, 0.94), rnd:NextNumber(5, 9)
				sp.Position = UDim2.new(x, 0, 1, 4)
				TweenService:Create(sp, TweenInfo.new(dur, lin), { Position = UDim2.new(x + rnd:NextNumber(-0.08, 0.08), 0, 0, -4) }):Play()
				TweenService:Create(sp, TweenInfo.new(dur * 0.3, lin), { BackgroundTransparency = rnd:NextNumber(0.35, 0.7) }):Play()
				task.delay(dur * 0.65, function()
					if sp.Parent then TweenService:Create(sp, TweenInfo.new(dur * 0.35, lin), { BackgroundTransparency = 1 }):Play() end
				end)
				task.wait(dur + rnd:NextNumber(0, 1.5))
			end
		end)
	end
end
local content = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO }, panel)
stack(content)
local function logo(parent, x, y, s)
	local h = mk("Frame", { Size = O(s, s), AnchorPoint = CENTER, Position = O(x, y), Rotation = 45 }, parent, math.floor(s * 0.3), C.ACC)
	h.UIStroke.Thickness, h.UIStroke.Transparency = 2, 0
	dot(math.floor(s * 0.4), C.ACC, parent).Position = O(x, y)
	return h.UIStroke
end
local orb = mk("TextButton", {
	Size = O(104, 34), Position = UDim2.new(0, 16, 0.5, -17), BackgroundColor3 = C.BG2, Text = T("orb"),
	TextSize = 15, Font = FONTB, TextXAlignment = MID, Visible = false, ZIndex = 5,
}, gui, 17, C.ACC)
loop(orb.UIStroke, { Thickness = 2.6, Transparency = 0.45 }, 1.1)
local function setCollapsed(v)
	main.Visible, orb.Visible = not v, v
	local s = v and mk("UIScale", { Scale = 0.6 }, orb) or popScale
	s.Scale = v and 0.6 or 0.88
	tw(s, { Scale = 1 }, v and 0.3 or 0.4, EASE_BACK)
	if v then task.delay(0.4, function() s:Destroy() end) end
end
local header = mk("Frame", { Size = UDim2.new(1, 0, 0, 44), Active = true }, content)
local logoStroke = logo(header, 26, 22, 18)
loop(logoStroke, { Transparency = 0.55 }, 1.4)
mk("TextLabel", {
	Size = UDim2.new(1, -200, 1, 0), Position = O(48, 0), TextSize = 17, Font = FONTB, RichText = true,
	Text = 'Captain <font color="rgb(255,142,32)">Shop</font>',
}, header)
sweepFx(mk("Frame", { Size = UDim2.new(1, -24, 1, 0), Position = O(12, 0), ClipsDescendants = true }, header), C.ACC2, 0.86, 1.5, 4, 2)
local function hover(b, color, tint)
	local st = b.UIStroke
	on(b.MouseEnter, function() tw(st, { Color = color, Transparency = 0 }, 0.12) tint(color) end)
	on(b.MouseLeave, function() tw(st, { Color = C.LINE, Transparency = 0.25 }, 0.12) tint(C.TXT) end)
	pressFx(b)
end
local function pill(text, k, color, fn)
	local b = mk("TextButton", {
		Size = O(52, 26), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14 - (k - 1) * 58, 0.5, 0), Text = text,
		TextSize = 12, Font = FONTB, TextXAlignment = MID, BackgroundColor3 = C.BTN,
	}, header, 6, C.LINE)
	hover(b, color, function(c) tw(b, { TextColor3 = c }, 0.12) end)
	on(b.Activated, fn)
end
pill("EXIT", 1, C.RED, function() env.__MaiKri() end)
pill("HIDE", 2, C.ACC, function() setCollapsed(true) end)
on(UIS.InputBegan, function(i, gp)
	if not gp and not capturing and i.KeyCode.Name == CFG.hideKey then setCollapsed(main.Visible) end
end)
smoothDrag(orb, orb, nil, function() setCollapsed(false) end)
local dragHandle = mk("TextButton", { Size = UDim2.fromScale(1, 1), ZIndex = 0, Text = "" }, header)
smoothDrag(dragHandle, main, function() introTw:Cancel() end)
local function hitRect(i, o, cutRight)
	local p = Vector2.new(i.Position.X, i.Position.Y)
	local ap, sz = o.AbsolutePosition, o.AbsoluteSize
	local inset = Vector2.new(0, 0)
	pcall(function() inset = GuiService:GetGuiInset() end)
	for _, q in ipairs({ p, p + Vector2.new(0, inset.Y) }) do
		if q.X >= ap.X and q.X <= ap.X + sz.X - cutRight and q.Y >= ap.Y and q.Y <= ap.Y + sz.Y then return true end
	end
	return false
end
on(UIS.InputBegan, function(i)
	if not isPress(i) then return end
	if orb.Visible then
		if hitRect(i, orb, 0) then startDrag(orb, i, nil, function() setCollapsed(false) end) end
	elseif main.Visible and header.AbsoluteSize.X > 0 then
		if hitRect(i, header, 200 * header.AbsoluteSize.X / W) then startDrag(main, i, function() introTw:Cancel() end) end
	end
end)
if workspace.CurrentCamera then
	on(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), function()
		task.wait(0.15)
		nudgeIntoView(main)
		nudgeIntoView(orb)
	end)
end
sepLine(content)
local body = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO }, content)
pad(body, 14, 10)
stack(body, 8)
local radarBox = mk("Frame", { Size = UDim2.new(1, 0, 0, 160) }, body)
for _, t in ipairs({ { "0°", 2 }, { "180°", 145 } }) do
	mk("TextLabel", {
		Size = UDim2.new(1, 0, 0, 14), Position = O(0, t[2]), Text = t[1], TextSize = 14, Font = FONTB, TextXAlignment = MID,
		TextStrokeTransparency = 0.6,
	}, radarBox)
end
local arc = mk("Frame", {
	Size = O(112, 112), AnchorPoint = CENTER, Position = UDim2.new(0.5, 0, 0, 80), BackgroundColor3 = Color3.fromRGB(14, 13, 15),
	BackgroundTransparency = 0.2,
}, radarBox, 56, C.LINE)
mk("Frame", { Size = O(56, 56), AnchorPoint = CENTER, Position = UDim2.fromScale(0.5, 0.5) }, arc, 28, C.LINE)
local sonar = {}
for i = 1, 2 do
	local rg = mk("Frame", { Size = O(20, 20), AnchorPoint = CENTER, Position = UDim2.fromScale(0.5, 0.5), Visible = S.enabled }, arc, 56, C.ACC)
	rg.UIStroke.Thickness, rg.UIStroke.Transparency = 1.5, 0.35
	sonar[i] = rg
	task.delay((i - 1) * 1.2, function()
		local ti = TweenInfo.new(2.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1)
		TweenService:Create(rg, ti, { Size = O(108, 108) }):Play()
		TweenService:Create(rg.UIStroke, ti, { Transparency = 1 }):Play()
	end)
end
local arrow = mk("Frame", { Size = O(6, 6), AnchorPoint = CENTER, Position = UDim2.new(0.5, 0, 0, 11), Rotation = 45, BackgroundColor3 = C.TXT }, arc, 1)
loop(arrow, { Position = UDim2.new(0.5, 0, 0, 15) }, 0.9)
mk("TextLabel", {
	Size = O(60, 14), AnchorPoint = CENTER, Position = UDim2.new(0.5, 0, 0, 26), Text = "FRONT", TextSize = 11, Font = FONTB,
	TextXAlignment = MID, TextStrokeTransparency = 0.5,
}, arc)
local avatar = mk("Frame", { Size = O(80, 60), AnchorPoint = CENTER, Position = UDim2.fromScale(0.5, 0.5) }, arc)
mk("UIScale", { Scale = 0.8 }, avatar)
mk("Frame", { Size = O(76, 30), AnchorPoint = CENTER, Position = O(40, 42), BackgroundColor3 = Color3.fromRGB(20, 24, 36), ZIndex = 1 }, avatar, 15, Color3.fromRGB(50, 58, 82))
grad(mk("Frame", { Size = O(58, 24), AnchorPoint = CENTER, Position = O(40, 38), BackgroundColor3 = C.WHITE, ZIndex = 2 }, avatar, 12),
	90, ColorSequence.new(Color3.fromRGB(88, 100, 128), Color3.fromRGB(40, 46, 68)))
local avatarHead = dot(32, C.WHITE, avatar, 3)
avatarHead.Position = O(40, 22)
grad(avatarHead, 45, ColorSequence.new(Color3.fromRGB(170, 180, 204), Color3.fromRGB(62, 70, 96)))
loop(avatar, { Position = UDim2.new(0.5, 0, 0.5, -3) }, 1.6)
local R, dots, ends = 56, {}, {}
local function at(f, deg, rad)
	local a = math.rad(deg)
	f.Position = UDim2.new(0.5, math.sin(a) * rad, 0.5, -math.cos(a) * rad)
end
local TUBE_OFF = Color3.fromRGB(38, 36, 42)
for k = -90, 90 do
	local a = k * 2
	local col = C.ACC:Lerp(C.ACC2, math.abs(a) / 180)
	local f = dot(5, TUBE_OFF, arc, 2)
	at(f, a, R)
	dots[#dots + 1] = { f = f, a = a, col = col, on = false }
end
local function lbl(text, color)
	return mk("TextLabel", {
		Size = O(40, 16), AnchorPoint = CENTER, Text = text, TextSize = 12, Font = FONTB, TextColor3 = color, TextXAlignment = MID,
		ZIndex = 6, TextStrokeTransparency = 0.45,
	}, arc)
end
local RING_TI = TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1)
for i = 1, 2 do
	local vis = dot(18, C.WHITE, arc, 5)
	mk("UIStroke", { Color = C.ACC, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, vis)
	local rg = mk("Frame", { Size = O(18, 18), AnchorPoint = CENTER, Position = UDim2.fromScale(0.5, 0.5) }, vis, 12, C.ACC)
	TweenService:Create(rg, RING_TI, { Size = O(36, 36) }):Play()
	TweenService:Create(rg.UIStroke, RING_TI, { Transparency = 1 }):Play()
	ends[i] = {
		vis = vis, hit = mk("TextButton", { Size = O(40, 40), AnchorPoint = CENTER, ZIndex = 7 }, arc),
		inn = lbl(i == 1 and "L" or "R", C.ACC), out = (function() local o = lbl("", C.TXT) o.TextSize, o.TextStrokeTransparency = 16, 0.15 return o end)(),
	}
end
local xLbl = lbl("", C.ACC)
xLbl.Size = O(70, 16)
do
	local tr, szs = {}, { 6, 5, 4, 3 }
	for k = 1, 4 do tr[k] = dot(szs[k], k == 1 and C.WHITE or C.ACC2, arc, 4) end
	local t0 = os.clock()
	on(RunService.RenderStepped, function()
		local e = S.enabled and S.half > 3
		local t = os.clock() - t0
		for k = 1, 4 do
			local f = tr[k]
			f.Visible = e
			if e then
				at(f, math.sin((t - (k - 1) * 0.07) * 1.9) * S.half, R)
				f.BackgroundTransparency = 0.05 + (k - 1) * 0.25
			end
		end
	end)
end
local infoRow = mk("Frame", { Size = UDim2.new(1, 0, 0, 50) }, body)
local angleTxt = mk("TextLabel", {
	Size = UDim2.new(1, 0, 0, 28), TextSize = 24, Font = FONTB, TextColor3 = C.ACC, TextXAlignment = MID,
	TextStrokeColor3 = C.ACC, TextStrokeTransparency = 0.82,
}, infoRow)
local angScale = mk("UIScale", {}, angleTxt)
local subTxt = mk("TextLabel", {
	Size = UDim2.new(1, 0, 0, 16), Position = O(0, 30), TextSize = 13, TextTransparency = 0.25, TextXAlignment = MID,
}, infoRow)
local shownHalf = S.half
local function paintArc(h)
	for _, d in ipairs(dots) do
		local inside = math.abs(d.a) <= h
		if d.on ~= inside then
			d.on = inside
			d.f.BackgroundColor3 = inside and d.col or TUBE_OFF
		end
	end
	for i = 1, 2 do
		local e, deg = ends[i], (i == 1 and -1 or 1) * h
		at(e.vis, deg, R) at(e.hit, deg, R) at(e.inn, deg, R - 14) at(e.out, deg, R + 26)
		local push = math.max(0, (40 - 2 * R * math.sin(math.rad(h))) / 2 + 2)
		if push > 0 then e.hit.Position += UDim2.fromOffset((i == 1 and -1 or 1) * push, 0) end
	end
end
local function drawArc()
	for i = 1, 2 do ends[i].out.Text = S.half .. "°" end
	xLbl.Position = UDim2.new(1, 44, 0, 120)
	xLbl.Text = T("rangeX"):format(S.range / 12)
	local angleStr = ("%d° - %d%%"):format(S.half * 2, math.floor(S.half * 2 / 360 * 100 + 0.5))
	if angleTxt.Text ~= angleStr then
		angleTxt.Text = angleStr
		angScale.Scale = 1.1
		tw(angScale, { Scale = 1 }, 0.2, EASE_BACK)
	end
	subTxt.Text = T("total"):format(S.half * 2, S.range)
end
paintArc(shownHalf)
on(RunService.RenderStepped, function(dt)
	local diff = S.half - shownHalf
	if diff == 0 then return end
	if math.abs(diff) < 0.02 then
		shownHalf = S.half
	else
		shownHalf += diff * (1 - math.exp(-30 * math.min(dt, 0.1)))
	end
	paintArc(shownHalf)
end)
local function setHalf(v)
	S.half = math.clamp(math.floor(v + 0.5), 0, 180)
	CFG.half = S.half
	saveCfg()
	drawArc()
end
for i = 1, 2 do
	local sgn, hp = i == 1 and -1 or 1, nil
	drag(ends[i].hit, function(inp)
		hp = ends[i].vis.AbsolutePosition + ends[i].vis.AbsoluteSize / 2
		showRange(true)
		tw(ends[i].vis, { Size = O(23, 23) }, 0.1)
	end, function(d)
		local v = hp + Vector2.new(d.X, d.Y) - (arc.AbsolutePosition + arc.AbsoluteSize / 2)
		if v.Magnitude < 6 then return end
		local h = math.deg(math.atan2(v.X, -v.Y)) * sgn
		if h < -90 then h = 180 elseif h < 0 then h = 0 end
		setHalf(h)
	end, function()
		showRange(false)
		tw(ends[i].vis, { Size = O(18, 18) }, 0.18, EASE_BACK)
	end)
end
local ctrl = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO, BackgroundColor3 = Color3.fromRGB(17, 16, 19) }, body, 12, C.LINE)
pad(ctrl, 12, 8)
stack(ctrl, 8)
local function slider(parent, name, min, max, init, unit, cb, quiet, nameW, onEnd)
	nameW = nameW or 40
	local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 20) }, parent)
	local nameL = mk("TextLabel", { Size = O(nameW, 20), Text = name, TextSize = 12, TextColor3 = C.DIM }, row)
	local val = mk("TextLabel", {
		Size = O(70, 20), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), TextSize = 12, Font = FONTB, TextColor3 = C.ACC2,
		TextXAlignment = Enum.TextXAlignment.Right,
	}, row)
	local bar = mk("Frame", { Size = UDim2.new(1, -(nameW + 84), 0, 5), Position = O(nameW + 6, 8), BackgroundColor3 = C.BG }, row, 3, C.LINE)
	local fill = mk("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.WHITE }, bar, 3)
	grad(fill, 0)
	local glow = dot(22, C.ACC, bar, 1)
	glow.BackgroundTransparency = 0.88
	local knob = dot(14, C.TXT, bar, 2)
	mk("UIStroke", { Color = C.ACC, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, knob)
	local hit = mk("TextButton", { Size = UDim2.new(1, -(nameW + 70), 0, 20), Position = O(nameW - 1, 0), ZIndex = 3 }, row)
	local cur, shownT, targetT, stopDrag = nil, 0, 0, nil
	local function toT(v) return (v - min) / (max - min) end
	local function render(t)
		knob.Position = UDim2.new(t, 0, 0.5, 0)
		fill.Size = UDim2.fromScale(t, 1)
		glow.Position = knob.Position
	end
	local function commit(v)
		local n = math.clamp(math.floor(v + 0.5), min, max)
		if n == cur then return end
		cur = n
		val.Text = n .. unit
		cb(n)
	end
	local function set(v)
		if stopDrag then stopDrag(true) end
		cur = nil
		commit(v)
		shownT, targetT = toT(cur), toT(cur)
		render(shownT)
	end
	on(hit.InputBegan, function(i)
		if not isPress(i) then return end
		if stopDrag then stopDrag(true) end
		local touch = i.UserInputType == Enum.UserInputType.Touch
		local p0 = i.Position.X
		local evX
		local function pointerX()
			if not touch then return UIS:GetMouseLocation().X end
			local live = i.Position.X
			if live ~= p0 then return live end
			return evX or p0
		end
		local w = math.max(bar.AbsoluteSize.X, 1)
		local t0 = math.clamp((p0 - bar.AbsolutePosition.X) / w, 0, 1)
		targetT = t0
		commit(min + t0 * (max - min))
		keyClick(false)
		if not quiet then showRange(true) end
		tw(knob, { Size = O(18, 18) }, 0.1)
		tw(glow, { Size = O(34, 34), BackgroundTransparency = 0.7 }, 0.12)
		local released, rs, ec, ic, mv = false
		local function disconnectAll()
			dc(rs, ec, ic, mv) rs, ec, ic, mv = nil, nil, nil, nil
			if stopDrag == disconnectAll then stopDrag = nil end
		end
		local function release(silent)
			if released then return end
			released = true
			targetT = toT(cur)
			keyClick(true)
			if not quiet then showRange(false) end
			tw(knob, { Size = O(14, 14) }, 0.18, EASE_BACK)
			tw(glow, { Size = O(22, 22), BackgroundTransparency = 0.88 }, 0.2)
			if not silent and onEnd then onEnd(cur) end
		end
		stopDrag = function(silent)
			release(silent)
			disconnectAll()
		end
		ec = UIS.InputEnded:Connect(function(j)
			if j == i or (not touch and j.UserInputType == Enum.UserInputType.MouseButton1) then release() end
		end)
		mv = touch and UIS.InputChanged:Connect(function(j)
			if j.UserInputType == Enum.UserInputType.Touch and (j == i or math.abs(j.Position.X - pointerX()) < 250) then
				evX = j.Position.X
			end
		end)
		ic = i.Changed:Connect(function()
			if inputEnded(i) then release() end
		end)
		rs = RunService.RenderStepped:Connect(function(dt)
			if not bar.Parent then return disconnectAll() end
			if not released then
				if inputEnded(i)
					or (not touch and not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)) then
					release()
				else
					targetT = math.clamp(t0 + (pointerX() - p0) / w, 0, 1)
					commit(min + targetT * (max - min))
				end
			end
			shownT = shownT + (targetT - shownT) * (1 - math.exp(-32 * math.min(dt, 0.1)))
			if released and math.abs(targetT - shownT) < 0.0005 then
				shownT = targetT
				render(shownT)
				return disconnectAll()
			end
			render(shownT)
		end)
	end)
	set(init)
	return set, nameL
end
local setRange, rangeNameL = slider(ctrl, T("range"), 1, 25, S.range, " studs", function(v) S.range = v CFG.range = v saveCfg() drawArc() end)
local setDash, dashNameL = slider(ctrl, T("dashStop"), 3, 20, S.dashStop, " studs", function(v) S.dashStop = v CFG.dashStop = v saveCfg() end, true, 58)
local setCd, cdNameL = slider(ctrl, T("cd"), 25, 100, S.cdPct, "%", function(v) S.cdPct = v CFG.cdPct = v saveCfg() end, true, 58)
local refreshers = {}
local row2 = mk("Frame", { Size = UDim2.new(1, 0, 0, 28) }, ctrl)
stack(row2, 8, HORIZ)
local function segment(parent, w, items, onPick, isSel)
	local seg = mk("Frame", { Size = O(w, 28), BackgroundColor3 = C.BG }, parent, 8, C.LINE)
	pad(seg, 2, 2)
	stack(seg, 0, HORIZ)
	local fns, btns = {}, {}
	for k, v in ipairs(items) do
		local b = mk("TextButton", {
			Size = UDim2.new(0.5, 0, 1, 0), Text = v[2], TextSize = 13, Font = FONTB, TextXAlignment = MID, BackgroundColor3 = C.BG,
		}, seg, 6)
		pressFx(b)
		on(b.Activated, function() onPick(v) end)
		btns[k] = b
		fns[k] = function()
			local sel = isSel(v)
			tw(b, { BackgroundColor3 = sel and C.ACC or C.BG, TextColor3 = sel and C.ACCTXT or C.DIM }, 0.18)
		end
	end
	return function() for _, f in ipairs(fns) do f() end end, seg, btns
end
local partRefresh, _, partBtns = segment(row2, 100, { { "Head", T("head") }, { "HumanoidRootPart", T("body") } },
	function(v) S.part = v[1] CFG.part = v[1] saveCfg() paint() end, function(v) return S.part == v[1] end)
refreshers[1] = partRefresh
local ddBtn = mk("TextButton", { Size = UDim2.new(1, -108, 1, 0), TextSize = 13, BackgroundColor3 = C.FIELD }, row2, 8, C.LINE)
pad(ddBtn, 10, 0)
pressFx(ddBtn)
local ddArrow = mk("TextLabel", {
	Size = O(16, 28), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), TextXAlignment = MID, TextColor3 = C.ACC, TextSize = 12, Font = FONTB,
}, ddBtn)
local listBox = mk("Frame", { Size = UDim2.new(1, 0, 0, 124), BackgroundColor3 = C.BG, Visible = false }, ctrl, 8, C.LINE)
local searchBox = mk("TextBox", {
	Size = UDim2.new(1, -8, 0, 24), Position = O(4, 4), BackgroundColor3 = C.FIELD, TextSize = 13, Text = "",
	PlaceholderText = T("search"), PlaceholderColor3 = C.DIM, ClearTextOnFocus = false, TextXAlignment = LEFT,
}, listBox, 6, C.LINE)
pad(searchBox, 8, 0)
local list = mk("ScrollingFrame", {
	Size = UDim2.new(1, -8, 1, -36), Position = O(4, 32), ScrollBarThickness = 3, ScrollBarImageColor3 = C.ACC,
	CanvasSize = UDim2.new(), AutomaticCanvasSize = AUTO, Active = true,
}, listBox)
stack(list)
local function playerOf(m)
	local p = Players:GetPlayerFromCharacter(m)
	if p then return p end
	local o = Players:FindFirstChild(m.Name)
	return o and o:IsA("Player") and o or nil
end
local rows = {}
local friendCache = {}
local function isFriend(p) return friendCache[p.UserId] == true end
local reorder
local function checkFriend(p)
	if friendCache[p.UserId] ~= nil then return end
	friendCache[p.UserId] = false
	task.spawn(function()
		local ok, res = pcall(function() return lp:IsFriendsWith(p.UserId) end)
		if ok and res == true then
			friendCache[p.UserId] = true
			local r = rows[p]
			if r and r.tag then r.tag.Visible = true end
			if reorder then reorder() end
		end
	end)
end
local function distTo(p)
	local a = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	local b = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
	return a and b and (a.Position - b.Position).Magnitude or math.huge
end
function reorder()
	local arr = {}
	for p, r in pairs(rows) do arr[#arr + 1] = { p, r, distTo(p) } end
	table.sort(arr, function(x, y)
		local fx, fy = isFriend(x[1]), isFriend(y[1])
		if fx ~= fy then return fx end
		if x[3] ~= y[3] then return x[3] < y[3] end
		return x[1].Name:lower() < y[1].Name:lower()
	end)
	for i, e in ipairs(arr) do
		e[2].row.LayoutOrder = i
		e[2].dist.Text = e[3] == math.huge and "-" or ("%d studs"):format(math.floor(e[3] + 0.5))
	end
end
local function updateDD()
	local n = 0
	for _, p in ipairs(Players:GetPlayers()) do
		if S.spare[p.UserId] then n += 1 end
	end
	ddBtn.Text = n == 0 and T("spare0") or T("spareN"):format(n)
	ddBtn.TextColor3 = n == 0 and C.DIM or C.TXT
	ddArrow.Text = listBox.Visible and "^" or "v"
end
local noMatchL
local function applyFilter()
	local q = searchBox.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
	local shown = 0
	for _, r in pairs(rows) do
		local vis = q == "" or r.key:find(q, 1, true) ~= nil
		r.row.Visible = vis
		if vis then shown += 1 end
	end
	if noMatchL and noMatchL.Parent then noMatchL.Visible = shown == 0 end
end
on(searchBox:GetPropertyChangedSignal("Text"), applyFilter)
local function rebuildList()
	for _, c in ipairs(list:GetChildren()) do
		if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
	end
	rows = {}
	local n = 0
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= lp then
			n += 1
			local row = mk("TextButton", { Size = UDim2.new(1, -4, 0, 24), LayoutOrder = n }, list)
			local cell = mk("Frame", { Size = O(16, 16), Position = O(4, 4), BackgroundColor3 = C.FIELD }, row, 5, C.OFF)
			local nameL = mk("TextLabel", {
				Size = UDim2.new(1, -158, 1, 0), Position = O(26, 0), TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd,
				Text = p.DisplayName == p.Name and p.Name or (p.DisplayName .. " (@" .. p.Name .. ")"),
			}, row)
			local tag = mk("TextLabel", {
				Size = O(60, 24), Position = UDim2.new(1, -126, 0, 0), TextSize = 11, Font = FONTB, TextColor3 = C.ACC,
				TextXAlignment = Enum.TextXAlignment.Right, Text = T("friend"), Visible = isFriend(p),
			}, row)
			rows[p] = { row = row, tag = tag, key = (p.Name .. " " .. p.DisplayName):lower(), dist = mk("TextLabel", {
				Size = O(60, 24), Position = UDim2.new(1, -62, 0, 0), TextSize = 11, TextColor3 = C.DIM,
				TextXAlignment = Enum.TextXAlignment.Right, Text = "-",
			}, row) }
			checkFriend(p)
			local function sync()
				local v = S.spare[p.UserId] == true
				tw(cell, { BackgroundColor3 = v and C.ACC or C.FIELD }, 0.15)
				cell.UIStroke.Color = v and C.ACC or C.OFF
			end
			sync()
			row.Activated:Connect(function()
				S.spare[p.UserId] = (not S.spare[p.UserId]) or nil
				saveSpare()
				sync()
				updateDD()
			end)
		end
	end
	if n == 0 then
		mk("TextLabel", { Size = UDim2.new(1, 0, 0, 24), Text = T("noPlayers"), TextColor3 = C.DIM, TextSize = 13, TextXAlignment = MID }, list)
	else
		noMatchL = mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 24), Text = T("noMatch"), TextColor3 = C.DIM, TextSize = 13, TextXAlignment = MID,
			Visible = false, LayoutOrder = 99999,
		}, list)
	end
	reorder()
	applyFilter()
	updateDD()
end
on(ddBtn.Activated, function()
	listBox.Visible = not listBox.Visible
	ddOpen = listBox.Visible
	fitScale()
	if ddOpen then rebuildList() else updateDD() end
end)
on(Players.PlayerAdded, function() task.delay(0.1, rebuildList) end)
on(Players.PlayerRemoving, function() task.delay(0.1, rebuildList) end)
rebuildList()
local blur, toastOn
onCleanup(function() if blur then pcall(function() blur:Destroy() end) end end)
local function showToast(title, sub)
	if toastOn then return end
	toastOn = true
	local sc = uiScale.Scale * popScale.Scale
	local ov = mk("TextButton", {
		Size = O(panel.AbsoluteSize.X / sc, panel.AbsoluteSize.Y / sc), BackgroundColor3 = Color3.fromRGB(10, 20, 15),
		BackgroundTransparency = 1, ZIndex = 30, Active = true,
	}, panel, 16)
	pcall(function()
		blur = Instance.new("BlurEffect")
		blur.Size = 0
		blur.Parent = workspace.CurrentCamera
		tw(blur, { Size = 8 }, 0.3)
	end)
	local SHOW = 2.2
	tw(ov, { BackgroundTransparency = 0.3 }, 0.25)
	local glow = mk("Frame", {
		Size = O(332, 178), AnchorPoint = CENTER, Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = C.GREEN, BackgroundTransparency = 0.92, ZIndex = 31,
	}, ov, 30)
	local card = mk("Frame", {
		Size = O(310, 160), AnchorPoint = CENTER, Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = C.WHITE, ZIndex = 32,
	}, ov, 16, C.GREEN)
	grad(card, 90, ColorSequence.new(Color3.fromRGB(38, 124, 90), Color3.fromRGB(14, 58, 42)))
	local cs = mk("UIScale", { Scale = 0.7 }, card)
	tw(cs, { Scale = 1 }, 0.4, EASE_BACK)
	card.UIStroke.Thickness = 1.5
	loop(card.UIStroke, { Transparency = 0.65 }, 0.9)
	local ic = mk("Frame", { Size = O(36, 36), AnchorPoint = CENTER, Position = O(155, 32), BackgroundColor3 = C.GREEN, ZIndex = 33 }, card, 18)
	local ics = mk("UIScale", { Scale = 0.01 }, ic)
	task.delay(0.15, function() if ics.Parent then tw(ics, { Scale = 1 }, 0.4, EASE_BACK) end end)
	local wave = mk("Frame", { Size = O(36, 36), AnchorPoint = CENTER, Position = O(155, 32), ZIndex = 33 }, card, 30, C.GREEN)
	task.delay(0.25, function()
		if not wave.Parent then return end
		tw(wave, { Size = O(64, 64) }, 0.7)
		tw(wave.UIStroke, { Transparency = 1 }, 0.7)
	end)
	for k = 1, 14 do
		local a, d, sz = math.rad(k / 14 * 360 + math.random(-10, 10)), math.random(34, 56), math.random(3, 5)
		local spk = mk("Frame", {
			Size = O(sz, sz), AnchorPoint = CENTER, Position = O(155, 32), ZIndex = 35,
			BackgroundColor3 = k % 2 == 0 and C.WHITE or Color3.fromRGB(86, 242, 164),
		}, card, sz)
		task.delay(0.25, function()
			if spk.Parent then tw(spk, { Position = O(155 + math.sin(a) * d, 32 - math.cos(a) * d), BackgroundTransparency = 1, Size = O(1, 1) }, 0.7) end
		end)
		task.delay(1.1, function() spk:Destroy() end)
	end
	mk("Frame", { Size = O(3, 8), AnchorPoint = CENTER, Position = UDim2.new(0.5, -4, 0.5, 2), Rotation = -45, BackgroundColor3 = C.BG, ZIndex = 34 }, ic)
	mk("Frame", { Size = O(3, 15), AnchorPoint = CENTER, Position = UDim2.new(0.5, 3, 0.5, 0), Rotation = 45, BackgroundColor3 = C.BG, ZIndex = 34 }, ic)
	mk("TextLabel", { Size = UDim2.new(1, 0, 0, 22), Position = O(0, 60), Text = title, TextSize = 19, Font = FONTB, TextXAlignment = MID, ZIndex = 33 }, card)
	mk("TextLabel", {
		Size = UDim2.new(1, -28, 0, 34), Position = O(14, 84), Text = sub, TextSize = 13, TextColor3 = Color3.fromRGB(205, 236, 218),
		TextXAlignment = MID, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 33,
	}, card)
	local okBtn = mk("TextButton", {
		Size = UDim2.new(1, -28, 0, 28), Position = O(14, 120), BackgroundColor3 = C.WHITE, Text = "OK", TextSize = 15, Font = FONTB,
		TextColor3 = C.BG, TextXAlignment = MID, ZIndex = 34,
	}, card, 8)
	grad(okBtn, 90, ColorSequence.new(Color3.fromRGB(86, 242, 164), Color3.fromRGB(40, 196, 118)))
	local timerBar = mk("Frame", { Size = UDim2.new(1, -28, 0, 3), Position = O(14, 152), BackgroundColor3 = C.WHITE, BackgroundTransparency = 0.55, ZIndex = 34 }, card, 2)
	TweenService:Create(timerBar, TweenInfo.new(SHOW, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 3) }):Play()
	local done = false
	local function close()
		if done then return end
		done = true
		tw(ov, { BackgroundTransparency = 1 }, 0.2)
		tw(glow, { BackgroundTransparency = 1 }, 0.2)
		tw(cs, { Scale = 0.85 }, 0.2)
		pcall(tw, blur, { Size = 0 }, 0.25)
		task.delay(0.3, function()
			ov:Destroy()
			pcall(function() blur:Destroy() end)
			blur, toastOn = nil, false
		end)
	end
	ov.Activated:Connect(close)
	okBtn.Activated:Connect(close)
	task.delay(SHOW, close)
end
local btnRow = mk("Frame", { Size = UDim2.new(1, 0, 0, 48) }, body)
stack(btnRow, 10, HORIZ)
local resetBtn = mk("TextButton", {
	Size = UDim2.new(0.5, -5, 1, 0), BackgroundColor3 = C.DARK, Text = T("reset"), TextSize = 16, Font = FONTB,
	TextColor3 = C.DIM, TextXAlignment = MID, ClipsDescendants = true,
}, btnRow, 12, C.LINE)
local resetStroke = resetBtn.UIStroke
local resetIcon = mk("Frame", { Size = O(14, 14), AnchorPoint = CENTER, Position = UDim2.new(0.5, -34, 0.5, 0) }, resetBtn, 7, C.DIM)
resetIcon.UIStroke.Thickness = 2
mk("Frame", { Size = O(6, 6), AnchorPoint = CENTER, Position = UDim2.new(1, -1, 0, 1), BackgroundColor3 = C.DARK }, resetIcon)
on(resetBtn.MouseEnter, function() tw(resetBtn, { TextColor3 = C.TXT }, 0.12) tw(resetStroke, { Color = C.ACC }, 0.12) end)
on(resetBtn.MouseLeave, function() tw(resetBtn, { TextColor3 = C.DIM }, 0.12) tw(resetStroke, { Color = C.LINE }, 0.12) end)
pressFx(resetBtn)
loop(resetStroke, { Transparency = 0.7 }, 1.6)
shine(resetBtn, C.ACC2, 0.82, 1.1, 2.4)
local iconLoop = loop(resetIcon, { Rotation = -30 }, 1.4)
local fxBusy = false
local function resetFx()
	if fxBusy then return end
	fxBusy = true
	iconLoop:Cancel()
	tw(resetIcon, { Rotation = 360 }, 0.7, Enum.EasingStyle.Quint)
	task.delay(0.75, function()
		if not resetIcon.Parent then return end
		resetIcon.Rotation = 0
		iconLoop = loop(resetIcon, { Rotation = -30 }, 1.4)
		fxBusy = false
	end)
	local flash = mk("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.ACC, BackgroundTransparency = 0.72, ZIndex = 2 }, resetBtn, 12)
	tw(flash, { BackgroundTransparency = 1 }, 0.55)
	local wave = ripple(resetBtn, 16, UDim2.fromScale(0.5, 0.5), C.ACC, 3, 150, 0.6)
	tw(resetStroke, { Color = C.ACC }, 0.1)
	tw(resetBtn, { TextColor3 = C.ACC }, 0.1)
	task.delay(0.45, function()
		tw(resetStroke, { Color = C.LINE }, 0.3)
		tw(resetBtn, { TextColor3 = C.DIM }, 0.3)
	end)
	task.delay(0.7, function() flash:Destroy() wave:Destroy() end)
end
on(resetBtn.Activated, function()
	resetFx()
	setHalf(DEFAULTS.half)
	setRange(DEFAULTS.range)
	setDash(DEFAULTS.dashStop)
	setCd(DEFAULTS.cdPct)
	showToast(T("resetDone"), T("resetSub"))
end)
local big = mk("TextButton", { Size = UDim2.new(0.5, -5, 1, 0), BackgroundColor3 = C.DARK, ClipsDescendants = true }, btnRow, 12, C.LINE)
local bigStroke = big.UIStroke
bigStroke.Thickness = 1.5
local bigGlow = mk("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.WHITE, BackgroundTransparency = 1 }, big, 12)
grad(bigGlow, 90, ColorSequence.new(Color3.fromRGB(150, 80, 16), Color3.fromRGB(56, 30, 8)))
local bigShine = shine(big, C.WHITE, 0.8, 1.2, 1.5, false)
loop(bigStroke, { Transparency = 0.6 }, 1.1)
local pw = mk("Frame", { Size = O(14, 14), AnchorPoint = CENTER, Position = UDim2.new(0.5, -36, 0.5, 1), ZIndex = 2 }, big, 7, C.OFF)
local pwStroke = pw.UIStroke
pwStroke.Thickness = 2
local pwLine = mk("Frame", { Size = O(2, 8), AnchorPoint = CENTER, Position = UDim2.new(0.5, 0, 0, 0), BackgroundColor3 = C.OFF, ZIndex = 3 }, pw)
local bigTxt = mk("TextLabel", { Size = UDim2.fromScale(1, 1), Position = O(8, 0), TextSize = 17, Font = FONTB, TextXAlignment = MID, ZIndex = 2 }, big)
pressFx(big)
on(big.Activated, function()
	S.enabled = not S.enabled
	paint()
	if S.enabled then
		local w = ripple(big, 14, UDim2.new(0.5, -36, 0.5, 1), C.ACC2, 3, 130, 0.55)
		local f = mk("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.ACC2, BackgroundTransparency = 0.6, ZIndex = 2 }, big, 12)
		tw(f, { BackgroundTransparency = 1 }, 0.5)
		task.delay(0.6, function() w:Destroy() f:Destroy() end)
	end
end)
local setOpen = false
local function showSettings()
	if setOpen then return end
	setOpen = true
	local sc = uiScale.Scale * popScale.Scale
	local ov = mk("Frame", {
		Size = O(panel.AbsoluteSize.X / sc, math.max(panel.AbsoluteSize.Y / sc, 330)), Position = O(0, 14),
		BackgroundColor3 = Color3.fromRGB(14, 13, 16), ZIndex = 40, Active = true,
	}, panel, 16)
	tw(ov, { Position = O(0, 0) }, 0.22)
	pad(ov, 14, 12)
	stack(ov, 10)
	local labels = {}
	local top = mk("Frame", { Size = UDim2.new(1, 0, 0, 30) }, ov)
	local title = mk("TextLabel", { Size = UDim2.new(1, -80, 1, 0), TextSize = 18, Font = FONTB }, top)
	local closeB = mk("TextButton", {
		Size = O(64, 26), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), TextSize = 12, Font = FONTB,
		TextXAlignment = MID, BackgroundColor3 = C.BTN,
	}, top, 6, C.LINE)
	pressFx(closeB)
	sepLine(ov)
	local function line(key)
		local r = mk("Frame", { Size = UDim2.new(1, 0, 0, 32) }, ov)
		labels[#labels + 1] = { mk("TextLabel", { Size = UDim2.new(0.5, 0, 1, 0), TextSize = 14, Font = FONTB }, r), key }
		return r
	end
	local function rightAnchor(o) o.AnchorPoint, o.Position = Vector2.new(1, 0.5), UDim2.new(1, 0, 0.5, 0) end
	local langRefresh
	do
		local seg
		langRefresh, seg = segment(line("language"), 150, { { "th", "ไทย" }, { "en", "English" } },
			function(v) setLang(v[1]) end, function(v) return CFG.lang == v[1] end)
		rightAnchor(seg)
	end
	local keyConn, keyB
	local function keyText() keyB.Text = keyConn and T("pressKey") or CFG.hideKey end
	do
		keyB = mk("TextButton", {
			Size = O(150, 28), BackgroundColor3 = C.FIELD, TextSize = 13, Font = FONTB, TextColor3 = C.ACC, TextXAlignment = MID,
		}, line("hideKey"), 8, C.LINE)
		rightAnchor(keyB)
		pressFx(keyB)
		keyB.Activated:Connect(function()
			if keyConn then return end
			capturing = true
			keyConn = UIS.InputBegan:Connect(function(i)
				if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
				if i.KeyCode ~= Enum.KeyCode.Escape and i.KeyCode ~= Enum.KeyCode.Unknown then
					CFG.hideKey = i.KeyCode.Name
					saveCfg()
				end
				keyConn:Disconnect()
				keyConn = nil
				task.defer(function() capturing = false end)
				keyText()
			end)
			keyText()
		end)
	end
	do
		local sw = mk("TextButton", { Size = O(48, 26), BackgroundColor3 = C.FIELD }, line("sound"), 13, C.LINE)
		rightAnchor(sw)
		local knob = dot(20, C.TXT, sw, 2)
		local function swPaint(instant)
			local bg, pos = CFG.sfx and C.ACC or C.FIELD, UDim2.new(0, CFG.sfx and 36 or 12, 0.5, 0)
			if instant then sw.BackgroundColor3, knob.Position = bg, pos else tw(sw, { BackgroundColor3 = bg }, 0.15) tw(knob, { Position = pos }, 0.15) end
		end
		swPaint(true)
		pressFx(sw)
		sw.Activated:Connect(function()
			CFG.sfx = not CFG.sfx
			saveCfg()
			swPaint(false)
		end)
	end
	local function cfgSlider(key, name, min, max, cb, onEnd)
		local _, l = slider(ov, T(name), min, max, CFG[key], "%", function(v) CFG[key] = v cb(v) end, true, 76, onEnd)
		labels[#labels + 1] = { l, name }
	end
	cfgSlider("vol", "volume", 0, 100, saveCfg)
	cfgSlider("scale", "size", 60, 120, function() end, function() saveCfg() fitScale() end)
	cfgSlider("opacity", "opacity", 50, 100, function(v) panel.BackgroundTransparency = 1 - v / 100 saveCfg() end)
	local function refresh()
		title.Text, closeB.Text = T("settings"), T("close")
		for _, e in ipairs(labels) do e[1].Text = T(e[2]) end
		langRefresh()
		keyText()
	end
	local hid = onLang(refresh)
	refresh()
	closeB.Activated:Connect(function()
		if not setOpen then return end
		setOpen = false
		langHooks[hid] = nil
		if keyConn then keyConn:Disconnect() keyConn = nil capturing = false end
		ov:Destroy()
	end)
end
local setBtn = mk("TextButton", {
	Size = O(30, 26), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14 - 2 * 58, 0.5, 0), BackgroundColor3 = C.BTN,
}, header, 6, C.LINE)
local gear = mk("Frame", { Size = O(20, 20), AnchorPoint = CENTER, Position = UDim2.fromScale(0.5, 0.5) }, setBtn)
local gearRing = mk("Frame", { Size = O(12, 12), AnchorPoint = CENTER, Position = O(10, 10) }, gear, 6, C.TXT)
gearRing.UIStroke.Thickness, gearRing.UIStroke.Transparency = 2, 0
local teeth = {}
for k = 0, 5 do
	local a = math.rad(k * 60)
	teeth[k + 1] = mk("Frame", {
		Size = O(3, 5), AnchorPoint = CENTER, Position = O(10 + math.sin(a) * 8, 10 - math.cos(a) * 8), Rotation = k * 60, BackgroundColor3 = C.TXT,
	}, gear, 1)
end
hover(setBtn, C.ACC, function(c)
	gearRing.UIStroke.Color = c
	for _, t in ipairs(teeth) do t.BackgroundColor3 = c end
end)
on(setBtn.Activated, function()
	tw(gear, { Rotation = gear.Rotation + 90 }, 0.35, EASE_BACK)
	showSettings()
end)
local barF = mk("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Color3.fromRGB(17, 15, 15) }, main, 14, C.LINE)
grad(barF.UIStroke, 0, ColorSequence.new(C.ACC, C.LINE), NumberSequence.new(0.3, 0.3))
do
	local barHandle = mk("TextButton", { Size = UDim2.fromScale(1, 1), ZIndex = 0, Text = "" }, barF)
	smoothDrag(barHandle, main, function() introTw:Cancel() end)
	on(UIS.InputBegan, function(i)
		if isPress(i) and main.Visible and hitRect(i, barF, 0) then startDrag(main, i, function() introTw:Cancel() end) end
	end)
end
logo(barF, 24, 20, 14)
local person = mk("Frame", { Size = O(12, 12), Position = O(46, 14) }, barF)
dot(5, C.ACC, person).Position = O(6, 3)
mk("Frame", { Size = O(11, 5), Position = O(0, 7), BackgroundColor3 = C.ACC }, person, 3)
local status = mk("TextLabel", {
	Size = UDim2.new(1, -270, 1, 0), Position = O(64, 0), Text = T("statusOn"), TextSize = 12, Font = FONTB, TextTruncate = Enum.TextTruncate.AtEnd,
}, barF)
local function setStatus(t)
	status.Text, status.TextColor3 = t, C.ACC2
	tw(status, { TextColor3 = C.TXT }, 0.7)
end
local stats = mk("Frame", {
	Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 0),
}, barF)
stack(stats, 14, HORIZ, Enum.VerticalAlignment.Center)
local function stat(iconFn)
	local it = mk("Frame", { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X }, stats)
	stack(it, 6, HORIZ, Enum.VerticalAlignment.Center)
	iconFn(mk("Frame", { Size = O(12, 12) }, it))
	return mk("TextLabel", { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, TextSize = 12, Font = FONTB }, it)
end
local fpsL = stat(function(h) mk("Frame", { Size = O(12, 5), AnchorPoint = CENTER, Position = O(6, 6), Rotation = -45, BackgroundColor3 = C.ACC }, h, 3) end)
local pingL = stat(function(h)
	for k = 1, 3 do
		mk("Frame", { Size = O(3, 3 + k * 3), AnchorPoint = Vector2.new(0, 1), Position = O((k - 1) * 4.5, 12), BackgroundColor3 = C.ACC }, h, 1)
	end
end)
local timeL = stat(function(h)
	mk("Frame", { Size = O(12, 12) }, h, 6, C.ACC).UIStroke.Thickness = 1.5
	mk("Frame", { Size = O(1.5, 4), Position = O(5, 2), BackgroundColor3 = C.ACC }, h)
	mk("Frame", { Size = O(3.5, 1.5), Position = O(5, 6), BackgroundColor3 = C.ACC }, h)
end)
do
	local frames, t0 = 0, os.clock()
	on(RunService.RenderStepped, function() frames += 1 end)
	task.spawn(function()
		while gui and gui.Parent do
			local now = os.clock()
			fpsL.Text = ("%d fps"):format(frames / math.max(now - t0, 0.01) + 0.5)
			frames, t0 = 0, now
			local ok, ms = pcall(function() return svc("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() end)
			pingL.Text = ok and ("%d ms"):format(ms + 0.5) or "- ms"
			timeL.Text = os.date("!%H:%M", os.time() + 7 * 3600)
			task.wait(1)
		end
	end)
end
local lastE
paint = function()
	for _, f in ipairs(refreshers) do f() end
	local e = S.enabled
	tw(orb, { BackgroundColor3 = e and C.ACC or C.BG2 }, 0.2)
	orb.Text, orb.TextColor3 = e and (T("orb") .. "  ON") or T("orb"), e and C.ACCTXT or C.TXT
	logoStroke.Color = e and C.ACC or C.OFF
	tw(bigGlow, { BackgroundTransparency = e and 0.1 or 1 }, 0.25)
	tw(bigStroke, { Color = e and C.ACC or C.LINE }, 0.25)
	tw(bigTxt, { TextColor3 = e and C.ACC or C.DIM }, 0.25)
	tw(pwStroke, { Color = e and C.ACC or C.OFF }, 0.25)
	tw(pwLine, { BackgroundColor3 = e and C.ACC or C.OFF }, 0.25)
	bigShine.Visible = e
	for _, r in ipairs(sonar) do r.Visible = e end
	if lastE ~= e then
		lastE = e
		setStatus(e and T("statusOn") or T("statusOff"))
	end
	bigTxt.Text = e and T("on") or T("off")
end
paint()
drawArc()
onLang(function()
	drawArc()
	updateDD()
	rebuildList()
	searchBox.PlaceholderText = T("search")
	resetBtn.Text, rangeNameL.Text, dashNameL.Text, cdNameL.Text = T("reset"), T("range"), T("dashStop"), T("cd")
	partBtns[1].Text, partBtns[2].Text = T("head"), T("body")
	lastE = nil
	paint()
end)
M.playerOf, M.setStatus = playerOf, setStatus
