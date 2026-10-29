local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Library = { Flags = {}, Objects = {}, Windows = {}, ConfigFolder = "SpectreUI/configs", Version = "3.17", _flagCbs = {} }
Library.DiskWrites = false
Library.__index = Library
do
local jobs, hb = {}, nil
local function step(dt)
local dead = false
for i = 1, #jobs do
local j = jobs[i]
if not j.dead then
j.acc += dt
if j.acc >= j.every then
j.acc = 0
pcall(j.fn, j.every)
end
end
if j.dead then dead = true end
end
if dead then
for i = #jobs, 1, -1 do if jobs[i].dead then table.remove(jobs, i) end end
if #jobs == 0 and hb then hb:Disconnect() hb = nil end
end
end
function Library._tick(every, fn)
local P = Library.Perf
every = tonumber(every) or 0.5
if P and P.LowPower then every = math.max(every, 0.25) end
local job = { every = every, acc = 0, fn = fn, dead = false, Connected = true }
function job:Disconnect() self.dead = true self.Connected = false end
jobs[#jobs + 1] = job
if not hb then hb = RunService.Heartbeat:Connect(step) end
return job
end
end
function Library._mount(gui)
local ok = pcall(function() gui.Parent = (gethui and gethui()) or CoreGui end)
if ok and gui.Parent then return true end
local lp = Players.LocalPlayer
local pg = lp and (lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui", 10))
ok = pcall(function() gui.Parent = pg or CoreGui end)
return ok and gui.Parent ~= nil
end
do
local genv = (getgenv and getgenv()) or _G
local old = genv.__SpectreUI_Lib
if old and old ~= Library and type(old.Unload) == "function" then pcall(old.Unload, old) end
local roots = { CoreGui }
if gethui then
local okh, h = pcall(gethui)
if okh and h then table.insert(roots, h) end
end
local lp0 = Players.LocalPlayer
local pg0 = lp0 and lp0:FindFirstChildOfClass("PlayerGui")
if pg0 then table.insert(roots, pg0) end
local stale = { SpectreUI = true, SpectreUI_Notify = true, SpectreUI_Host = true, SpectreUI_HUD = true, SpectreUI_Splash = true, SpectreUI_Tap = true }
for _, r in ipairs(roots) do
pcall(function()
for _, c in ipairs(r:GetChildren()) do
if stale[c.Name] and c:IsA("ScreenGui") then c:Destroy() end
end
end)
end
genv.__SpectreUI_Lib = Library
end
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
Library.Themes = {
Clean = {
Background = rgb(17, 17, 20),  Panel = rgb(22, 22, 26),   Card = rgb(27, 27, 31),   Control = rgb(36, 36, 42),
Border = rgb(46, 46, 54),      Accent = rgb(94, 140, 240), Accent2 = rgb(94, 140, 240), AccentSoft = rgb(31, 40, 62),
Sheen = rgb(214, 226, 250),    Text = rgb(236, 237, 242), SubText = rgb(142, 144, 156),
FX = false, Glow = false, Clean = true,
},
Nova = {
Background = rgb(10, 12, 14),  Panel = rgb(15, 18, 21),   Card = rgb(21, 25, 29),   Control = rgb(31, 36, 42),
Border = rgb(42, 50, 58),      Accent = rgb(45, 212, 170), Accent2 = rgb(94, 234, 212), AccentSoft = rgb(13, 50, 44),
Sheen = rgb(204, 251, 241),    Text = rgb(240, 246, 245), SubText = rgb(138, 153, 160),
FX = false,
},
Rose = {
Background = rgb(13, 9, 12),   Panel = rgb(20, 14, 18),   Card = rgb(26, 19, 24),   Control = rgb(37, 27, 34),
Border = rgb(74, 46, 62),      Accent = rgb(244, 114, 182), Accent2 = rgb(251, 146, 190), AccentSoft = rgb(70, 28, 52),
Sheen = rgb(255, 208, 226),    Text = rgb(253, 242, 248), SubText = rgb(196, 152, 174),
FX = "petals",
},
Violet = {
Background = rgb(8, 7, 14),    Panel = rgb(14, 12, 23),   Card = rgb(18, 16, 29),   Control = rgb(24, 21, 38),
Border = rgb(52, 42, 94),      Accent = rgb(139, 92, 246), Accent2 = rgb(217, 70, 239), AccentSoft = rgb(40, 26, 78),
Sheen = rgb(190, 170, 255),    Text = rgb(240, 238, 250), SubText = rgb(152, 148, 180),
FX = "orbs",
},
Cyber = {
Background = rgb(6, 10, 16),   Panel = rgb(10, 17, 27),   Card = rgb(13, 22, 35),   Control = rgb(19, 31, 48),
Border = rgb(30, 78, 110),     Accent = rgb(34, 211, 238), Accent2 = rgb(59, 130, 246), AccentSoft = rgb(10, 46, 70),
Sheen = rgb(165, 243, 252),    Text = rgb(236, 248, 255), SubText = rgb(140, 170, 190),
FX = "grid",
},
Crimson = {
Background = rgb(12, 6, 7),    Panel = rgb(20, 10, 12),   Card = rgb(26, 13, 16),   Control = rgb(36, 20, 24),
Border = rgb(100, 36, 44),     Accent = rgb(239, 68, 68), Accent2 = rgb(249, 115, 22), AccentSoft = rgb(70, 20, 24),
Sheen = rgb(254, 202, 202),    Text = rgb(254, 242, 242), SubText = rgb(190, 150, 150),
FX = "embers",
},
Matrix = {
Background = rgb(5, 10, 7),    Panel = rgb(9, 18, 12),    Card = rgb(12, 24, 16),   Control = rgb(18, 34, 24),
Border = rgb(30, 92, 56),      Accent = rgb(34, 197, 94), Accent2 = rgb(132, 204, 22), AccentSoft = rgb(12, 52, 30),
Sheen = rgb(187, 247, 208),    Text = rgb(240, 253, 244), SubText = rgb(140, 180, 155),
FX = "rain",
},
Midnight = {
Background = rgb(7, 9, 18),    Panel = rgb(12, 15, 28),   Card = rgb(16, 20, 36),   Control = rgb(24, 29, 50),
Border = rgb(44, 54, 96),      Accent = rgb(99, 102, 241), Accent2 = rgb(56, 189, 248), AccentSoft = rgb(30, 34, 84),
Sheen = rgb(199, 210, 254),    Text = rgb(238, 242, 255), SubText = rgb(148, 158, 196),
FX = "orbs",
},
Ocean = {
Background = rgb(5, 12, 16),   Panel = rgb(9, 20, 26),   Card = rgb(12, 27, 34),   Control = rgb(18, 40, 50),
Border = rgb(28, 74, 90),      Accent = rgb(45, 212, 191), Accent2 = rgb(56, 189, 248), AccentSoft = rgb(10, 52, 60),
Sheen = rgb(153, 246, 228),    Text = rgb(236, 254, 255), SubText = rgb(136, 178, 188),
FX = "grid",
},
Sunset = {
Background = rgb(15, 9, 8),    Panel = rgb(24, 14, 12),   Card = rgb(31, 19, 16),   Control = rgb(44, 28, 23),
Border = rgb(94, 54, 40),      Accent = rgb(251, 146, 60), Accent2 = rgb(244, 63, 94), AccentSoft = rgb(78, 36, 24),
Sheen = rgb(254, 215, 170),    Text = rgb(255, 247, 237), SubText = rgb(196, 160, 140),
FX = "embers",
},
Mono = {
Background = rgb(10, 10, 12),  Panel = rgb(17, 17, 20),   Card = rgb(22, 22, 26),   Control = rgb(32, 32, 38),
Border = rgb(58, 58, 68),      Accent = rgb(228, 228, 237), Accent2 = rgb(161, 161, 178), AccentSoft = rgb(44, 44, 54),
Sheen = rgb(255, 255, 255),    Text = rgb(244, 244, 248), SubText = rgb(150, 150, 164),
FX = "orbs",
},
Minimal = {
Background = rgb(15, 16, 19),  Panel = rgb(21, 22, 26),   Card = rgb(27, 28, 33),   Control = rgb(35, 37, 43),
Border = rgb(54, 57, 66),      Accent = rgb(126, 150, 196), Accent2 = rgb(150, 171, 210), AccentSoft = rgb(36, 42, 56),
Sheen = rgb(222, 229, 244),    Text = rgb(230, 233, 240), SubText = rgb(138, 144, 158),
},
Aurora = {
Background = rgb(7, 11, 18),   Panel = rgb(12, 18, 28),   Card = rgb(16, 24, 37),   Control = rgb(24, 34, 52),
Border = rgb(42, 66, 98),      Accent = rgb(110, 231, 183), Accent2 = rgb(167, 139, 250), AccentSoft = rgb(22, 56, 70),
Sheen = rgb(209, 250, 229),    Text = rgb(240, 253, 250), SubText = rgb(146, 174, 188),
FX = "orbs",
},
Dracula = {
Background = rgb(20, 21, 30),  Panel = rgb(27, 28, 40),   Card = rgb(33, 34, 49),   Control = rgb(44, 46, 66),
Border = rgb(70, 73, 104),     Accent = rgb(189, 147, 249), Accent2 = rgb(255, 121, 198), AccentSoft = rgb(58, 44, 94),
Sheen = rgb(233, 220, 255),    Text = rgb(248, 248, 242), SubText = rgb(160, 164, 198),
FX = "orbs",
},
Nord = {
Background = rgb(20, 24, 32),  Panel = rgb(27, 32, 43),   Card = rgb(33, 39, 52),   Control = rgb(44, 52, 68),
Border = rgb(67, 80, 102),     Accent = rgb(136, 192, 208), Accent2 = rgb(129, 161, 193), AccentSoft = rgb(34, 54, 68),
Sheen = rgb(216, 236, 244),    Text = rgb(236, 239, 244), SubText = rgb(150, 166, 188),
FX = "grid",
},
TokyoNight = {
Background = rgb(15, 16, 26),  Panel = rgb(22, 24, 38),   Card = rgb(26, 28, 46),   Control = rgb(36, 40, 64),
Border = rgb(60, 68, 102),     Accent = rgb(122, 162, 247), Accent2 = rgb(187, 154, 247), AccentSoft = rgb(36, 46, 86),
Sheen = rgb(196, 213, 255),    Text = rgb(214, 222, 255), SubText = rgb(132, 142, 184),
FX = "orbs",
},
Mocha = {
Background = rgb(17, 17, 27),  Panel = rgb(24, 24, 37),   Card = rgb(30, 30, 46),   Control = rgb(42, 43, 62),
Border = rgb(69, 71, 92),      Accent = rgb(203, 166, 247), Accent2 = rgb(245, 194, 231), AccentSoft = rgb(56, 44, 86),
Sheen = rgb(240, 220, 255),    Text = rgb(205, 214, 244), SubText = rgb(147, 153, 180),
FX = "petals",
},
Synthwave = {
Background = rgb(13, 7, 22),   Panel = rgb(22, 11, 36),   Card = rgb(29, 15, 47),   Control = rgb(42, 22, 68),
Border = rgb(98, 40, 124),     Accent = rgb(255, 64, 200), Accent2 = rgb(0, 229, 255), AccentSoft = rgb(76, 18, 88),
Sheen = rgb(255, 190, 240),    Text = rgb(255, 240, 252), SubText = rgb(188, 150, 202),
FX = "grid",
},
Jade = {
Background = rgb(6, 13, 11),   Panel = rgb(10, 22, 18),   Card = rgb(13, 29, 24),   Control = rgb(20, 43, 35),
Border = rgb(34, 86, 68),      Accent = rgb(74, 222, 168), Accent2 = rgb(253, 224, 71), AccentSoft = rgb(14, 56, 44),
Sheen = rgb(209, 250, 232),    Text = rgb(240, 253, 247), SubText = rgb(140, 182, 164),
FX = "orbs",
},
Gold = {
Background = rgb(12, 10, 7),   Panel = rgb(21, 17, 11),   Card = rgb(28, 23, 15),   Control = rgb(41, 34, 22),
Border = rgb(98, 80, 36),      Accent = rgb(250, 204, 21), Accent2 = rgb(245, 158, 11), AccentSoft = rgb(76, 58, 16),
Sheen = rgb(254, 240, 170),    Text = rgb(254, 252, 232), SubText = rgb(196, 182, 142),
FX = "embers",
},
Lavender = {
Background = rgb(12, 10, 18),  Panel = rgb(19, 16, 28),   Card = rgb(25, 21, 38),   Control = rgb(36, 31, 56),
Border = rgb(76, 64, 114),     Accent = rgb(196, 167, 255), Accent2 = rgb(244, 170, 255), AccentSoft = rgb(54, 42, 90),
Sheen = rgb(232, 220, 255),    Text = rgb(248, 244, 255), SubText = rgb(172, 162, 202),
FX = "petals",
},
Candy = {
Background = rgb(11, 12, 20),  Panel = rgb(17, 19, 31),   Card = rgb(22, 24, 40),   Control = rgb(32, 35, 58),
Border = rgb(66, 74, 114),     Accent = rgb(125, 211, 252), Accent2 = rgb(249, 168, 212), AccentSoft = rgb(34, 50, 86),
Sheen = rgb(224, 242, 254),    Text = rgb(244, 248, 255), SubText = rgb(158, 168, 198),
FX = "petals",
},
Peach = {
Background = rgb(16, 10, 11),  Panel = rgb(26, 16, 17),   Card = rgb(33, 21, 22),   Control = rgb(47, 31, 32),
Border = rgb(102, 62, 58),     Accent = rgb(253, 164, 175), Accent2 = rgb(253, 186, 116), AccentSoft = rgb(80, 36, 40),
Sheen = rgb(255, 228, 220),    Text = rgb(255, 245, 242), SubText = rgb(204, 166, 160),
FX = "petals",
},
}
local THEME_COMMON = { Font = Enum.Font.GothamMedium, FontBold = Enum.Font.GothamBold, Glow = true, Animate = true }
local function buildTheme(src)
local T = table.clone(THEME_COMMON)
for k, v in pairs(Library.Themes.Rose) do T[k] = v end
T.Clean = nil
for k, v in pairs(src or {}) do T[k] = v end
if src and src.FX == nil then T.FX = "orbs" end
local white = Color3.new(1, 1, 1)
T.Text = T.Text:Lerp(white, 0.15)
T.SubText = T.SubText:Lerp(T.Text, 0.35)
T.Border = T.Border:Lerp(T.Accent, 0.08):Lerp(white, 0.04)
T.Control = T.Control:Lerp(white, 0.035)
T.Card = T.Card:Lerp(white, 0.012)
return T
end
local function deriveTheme(T)
local black, white = Color3.new(0, 0, 0), Color3.new(1, 1, 1)
T.Top  = T.Top  or T.Panel:Lerp(T.Accent, 0.06)
T.Deep = T.Deep or T.Background:Lerp(black, 0.4)
T.Lift = T.Lift or T.Control:Lerp(T.Accent, 0.12)
T.Wash = T.Wash or T.AccentSoft:Lerp(T.Accent2, 0.15)
T.Knob = T.Knob or white:Lerp(T.Accent, 0.04)
return T
end
Library.Theme = buildTheme(Library.Themes.Clean)
function Library.OnAccent(a, b)
if type(a) == "table" then a, b = a.Accent, a.Accent2 end
a = a or Color3.new(1, 1, 1)
b = b or a
local function lum(c)
local function f(v) return v <= 0.03928 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4 end
return 0.2126 * f(c.R) + 0.7152 * f(c.G) + 0.0722 * f(c.B)
end
local function ratio(x, y) if x < y then x, y = y, x end return (x + 0.05) / (y + 0.05) end
local la, lb, ld = lum(a), lum(b), lum(Color3.fromRGB(14, 14, 20))
local white = math.min(ratio(1, la), ratio(1, lb))
local dark = math.min(ratio(la, ld), ratio(lb, ld))
if white >= 3 or white >= dark then return Color3.new(1, 1, 1) end
return Color3.fromRGB(14, 14, 20)
end
function Library._oa(inst) inst:SetAttribute("OnAccent", true) return inst end
function Library._fullScreen(g)
pcall(function() g.IgnoreGuiInset = true end)
pcall(function() g.ScreenInsets = Enum.ScreenInsets.None end)
return g
end
function Library._visibleRect(gui)
local gp, gs = gui.AbsolutePosition, gui.AbsoluteSize
local mn, mx = gp, gp + gs
local cam = workspace.CurrentCamera
if cam and cam.ViewportSize.X > 0 then
local v = cam.ViewportSize
local a = Vector2.new(math.max(mn.X, 0), math.max(mn.Y, 0))
local b = Vector2.new(math.min(mx.X, v.X), math.min(mx.Y, v.Y))
if b.X - a.X >= 100 and b.Y - a.Y >= 100 then return a, b end
end
return mn, mx
end
function Library._topSafe(cfg, vp)
local t
if cfg and type(cfg.TopMargin) == "number" then
t = math.max(cfg.TopMargin, 0)
elseif false then
local ref = (vp and vp.Y > 0) and math.min(vp.X, vp.Y) or 390
t = math.clamp(math.floor(ref * 0.17 + 0.5), 62, 84)
else
return 0
end
if vp and vp.Y > 0 then t = math.min(t, vp.Y * 0.25) end
return math.floor(t + 0.5)
end
function Library._sideSafe(cfg, vp)
if cfg and type(cfg.SideMargin) == "number" then
local m = math.max(cfg.SideMargin, 0)
return { L = m, R = m, B = m }
end
return Library._edge(vp)
end
Library.EdgeScale = 1
Library.MaxMargin = nil
function Library._edge(vp)
if not false then return nil end
if not vp or vp.X <= 0 or vp.Y <= 0 then
local cam = workspace.CurrentCamera
vp = cam and cam.ViewportSize or Vector2.new(844, 390)
end
local k = (type(Library.EdgeScale) == "number" and Library.EdgeScale or 1)
local sd = math.clamp(math.floor(math.min(vp.X, vp.Y) * 0.11 + 0.5), 30, 56) * k
return { L = math.floor(sd), R = math.floor(sd), B = math.floor(sd * 0.8) }
end
function Library._pinPopup(popup, wantX, wantY)
if not popup or not popup.Parent then return end
local ap, sz = popup.AnchorPoint, popup.AbsoluteSize
local a = popup.AbsolutePosition + Vector2.new(ap.X * sz.X, ap.Y * sz.Y)
local ex, ey = a.X - wantX, a.Y - wantY
if math.abs(ex) < 0.5 and math.abs(ey) < 0.5 then return end
local pp = popup.Position
popup.Position = UDim2.new(pp.X.Scale, pp.X.Offset - ex, pp.Y.Scale, pp.Y.Offset - ey)
end
function Library._drag(i, onMove, onStop)
if Library._dragStop then Library._dragStop() end
local isTouch = i.UserInputType == Enum.UserInputType.Touch
local conns, done = {}, false
local function stop()
if done then return end
done = true
for _, c in ipairs(conns) do c:Disconnect() end
if Library._dragStop == stop then Library._dragStop = nil end
onStop()
end
Library._dragStop = stop
local function ended()
local st = i.UserInputState
return st == Enum.UserInputState.End or st == Enum.UserInputState.Cancel
end
table.insert(conns, UserInputService.InputChanged:Connect(function(m)
if done then return end
if isTouch then
if m ~= i or m.UserInputType ~= Enum.UserInputType.Touch then return end
elseif m.UserInputType ~= Enum.UserInputType.MouseMovement then
return
end
if ended() then stop() return end
onMove(m)
end))
table.insert(conns, UserInputService.InputEnded:Connect(function(e)
if e == i or (not isTouch and e.UserInputType == Enum.UserInputType.MouseButton1) then stop() end
end))
table.insert(conns, i.Changed:Connect(function() if ended() then stop() end end))
return stop
end
Library.Fonts, Library._fontOrder, Library.FontName = {}, {}, "Gotham"
do
local defs = {
{ "Builder Sans", "BuilderSansMedium", "BuilderSansBold" },
{ "Gotham", "GothamMedium", "GothamBold" },
{ "Gotham Light", "Gotham", "GothamBold" },
{ "Gotham Bold", "GothamBold", "GothamBlack" },
{ "Source Sans", "SourceSans", "SourceSansBold" },
{ "Arial", "Arial", "ArialBold" },
{ "Nunito", "Nunito", "Nunito" },
{ "Ubuntu", "Ubuntu", "Ubuntu" },
{ "Roboto", "Roboto", "Roboto" },
{ "Roboto Condensed", "RobotoCondensed", "RobotoCondensed" },
{ "Roboto Mono", "RobotoMono", "RobotoMono" },
{ "Code", "Code", "Code" },
{ "Titillium Web", "TitilliumWeb", "TitilliumWeb" },
{ "Jura", "Jura", "Jura" },
{ "Oswald", "Oswald", "Oswald" },
{ "Josefin Sans", "JosefinSans", "JosefinSans" },
{ "Merriweather", "Merriweather", "Merriweather" },
{ "Highway", "Highway", "Highway" },
{ "Sci-Fi", "SciFi", "SciFi" },
{ "Fredoka", "FredokaOne", "FredokaOne" },
{ "Kalam", "Kalam", "Kalam" },
{ "Patrick Hand", "PatrickHand", "PatrickHand" },
}
for _, d in ipairs(defs) do
local ok1, r = pcall(function() return Enum.Font[d[2]] end)
local ok2, b = pcall(function() return Enum.Font[d[3]] end)
if ok1 and ok2 and r and b then
Library.Fonts[d[1]] = { Font = r, Bold = b }
table.insert(Library._fontOrder, d[1])
end
end
end
do
local bs = Library.Fonts["Builder Sans"]
if bs then
THEME_COMMON.Font, THEME_COMMON.FontBold, Library.FontName = bs.Font, bs.Bold, "Builder Sans"
Library.Theme.Font, Library.Theme.FontBold = bs.Font, bs.Bold
end
end
function Library._fontPair(f)
local function isFont(v) return typeof(v) == "EnumItem" and v.EnumType == Enum.Font end
if type(f) == "string" then
local p = Library.Fonts[f]
if not p then return nil, "unknown font" end
return p.Font, p.Bold, f
elseif isFont(f) then
for name, p in pairs(Library.Fonts) do
if p.Font == f then return p.Font, p.Bold, name end
end
return f, f, "Custom"
elseif type(f) == "table" then
local r = f.Font or f.Regular or f[1]
local b = f.Bold or f.FontBold or f[2] or r
if isFont(r) and isFont(b) then return r, b, "Custom" end
return nil, "Font and Bold must be Enum.Font values"
end
return nil, "usage: SetFont(name | Enum.Font | { Font, Bold })"
end
function Library._remapFonts(root, oldR, oldB, newR, newB)
if not root or (oldR == newR and oldB == newB) then return end
local ambiguous = oldR == oldB
local tagNew = newR == newB
for _, o in ipairs(root:GetDescendants()) do
if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
local f = o.Font
if f == oldR or f == oldB then
local bold = o:GetAttribute("SpBold")
if bold == nil then bold = (f == oldB) and not ambiguous end
o.Font = bold and newB or newR
if tagNew or ambiguous then o:SetAttribute("SpBold", bold) end
end
end
end
end
function Library:RegisterFont(name, regular, bold)
if type(name) ~= "string" or name == "" then return false, "usage: RegisterFont(name, Enum.Font, Enum.Font?)" end
local r, b = Library._fontPair({ Font = regular, Bold = bold })
if not r then return false, b end
if not self.Fonts[name] then table.insert(self._fontOrder, name) end
self.Fonts[name] = { Font = r, Bold = b }
if self._fire then self._fire("fonts") end
return true
end
function Library:ListFonts()
local out = {}
for i, n in ipairs(self._fontOrder) do out[i] = n end
return out
end
function Library:SetFont(f, silent)
local r, b, name = Library._fontPair(f)
if not r then return false, b end
THEME_COMMON.Font, THEME_COMMON.FontBold = r, b
self.Theme.Font, self.Theme.FontBold = r, b
self.FontName = name or "Custom"
if not silent then self._userSetFont = true end
return true, self.FontName
end
function Library:SetTheme(t)
if type(t) == "string" then t = self.Themes[t] end
if type(t) ~= "table" then return false end
self.Theme = buildTheme(t)
return true
end
local Window, Tab, Section = {}, {}, {}
Window.__index, Tab.__index, Section.__index = Window, Tab, Section
local AY = Enum.AutomaticSize.Y
local AX = Enum.AutomaticSize.X
local ANONE = Enum.AutomaticSize.None
local LEFT = Enum.TextXAlignment.Left
local IS_MOBILE = false
Library.Mobile = false
Library.IsTouchDevice = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
Library.SizeTouch = true
local HEADER_H, FOOT_H = 56, 54
local QUINT, QUAD, BACK = Enum.EasingStyle.Quint, Enum.EasingStyle.Quad, Enum.EasingStyle.Back
local SINE, LINEAR = Enum.EasingStyle.Sine, Enum.EasingStyle.Linear
local OUT, IN = Enum.EasingDirection.Out, Enum.EasingDirection.In
Library.Anim = { Speed = 1, Intro = true, Spin = false }
Library.Perf = {
LowPower = nil,
Adaptive = true, SlowFrame = 1 / 35, SlowShare = 0.15, Warmup = 1.5, Recover = true, RecoverWindows = 4,
Aurora = false, Particles = 2, Twinkle = false,
Slice = true, SliceBudget = IS_MOBILE and 0.003 or 0.005, SliceBudgetBusy = 0.0015,
CollapseAnimMax = 12,
}
local function lowPower()
local p = Library.Perf.LowPower
if p ~= nil then return p end
return IS_MOBILE
end
Library.Sound = {
Enabled = true, Volume = 0.5,
Toggle = "rbxassetid://6895079853",
Click = "rbxassetid://6895079853",
Notify = "rbxassetid://4590662766",
}
local lastPlayed = {}
local function playSound(kind, override)
local S = Library.Sound
if not S or not S.Enabled or override == false then return end
local id = type(override) == "string" and override or (type(override) == "number" and ("rbxassetid://" .. override)) or S[kind]
if not id then return end
local now = os.clock()
if lastPlayed[kind] and now - lastPlayed[kind] < 0.06 then return end
lastPlayed[kind] = now
pcall(function()
local snd = Instance.new("Sound")
snd.Name = "SpectreUI_" .. kind
snd.SoundId = id
snd.Volume = math.clamp(S.Volume or 0.5, 0, 1)
snd.RollOffMaxDistance = 0
snd.Parent = SoundService
snd.Ended:Once(function() snd:Destroy() end)
snd:Play()
task.delay(6, function() if snd.Parent then snd:Destroy() end end)
end)
end
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
local GEOM = { Size = true, Position = true, Rotation = true, Scale = true, Offset = true, CanvasPosition = true }
local infoCache, infoCount = {}, 0
local function tinfo(t, style, dir)
local a = infoCache[style]
if not a then a = {} infoCache[style] = a end
local b = a[dir]
if not b then b = {} a[dir] = b end
local info = b[t]
if not info then
if infoCount > 300 then infoCache, infoCount = {}, 0 a, b = {}, {} infoCache[style] = a a[dir] = b end
info = TweenInfo.new(t, style, dir)
b[t] = info
infoCount += 1
end
return info
end
local INSTANT = {
BackgroundColor3 = true, BackgroundTransparency = true, TextColor3 = true, TextTransparency = true,
ImageColor3 = true, ImageTransparency = true, Transparency = true, Color = true,
}
local lastTw = setmetatable({}, { __mode = "k" })
local function tween(o, t, props, style, dir)
if t <= 0.07 and lowPower() and not style then
local direct = true
for k in pairs(props) do
if not INSTANT[k] then direct = false break end
end
if direct then
local prev = lastTw[o]
if prev then prev:Cancel() lastTw[o] = nil end
for k, v in pairs(props) do o[k] = v end
return { Completed = { Connect = function() return { Disconnect = function() end } end }, Cancel = function() end, Play = function() end }
end
end
if not style then
style = SINE
for k in pairs(props) do
if GEOM[k] then style = QUINT break end
end
end
t = math.max(t * (Library.Anim.Speed or 1), 0.08)
local tw = TweenService:Create(o, tinfo(t, style, dir or OUT), props)
lastTw[o] = tw
tw:Play()
return tw
end
local function nextFrame(fn)
task.spawn(function()
RunService.RenderStepped:Wait()
fn()
end)
end
local function corner(r) return new("UICorner", { CornerRadius = UDim.new(0, r <= 3 and 5 or math.min(math.floor(r * 0.7 + 0.5), 16)) }) end
Library.IconLib = {
Url = "https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua", Default = "lucide", Timeout = 10,
Mirrors = { "https://cdn.jsdelivr.net/gh/Footagesus/Icons@main/Main-v2.lua" },
}
Library._iconReady = {}
local iconState = { started = false, done = false, timedOut = false }
local function iconLoad()
if iconState.started then return end
iconState.started = true
task.spawn(function()
local urls = { Library.IconLib.Url }
for _, u in ipairs(Library.IconLib.Mirrors or {}) do table.insert(urls, u) end
local ok, mod = false, nil
for attempt = 1, 2 do
for _, u in ipairs(urls) do
ok, mod = pcall(function() return loadstring(game:HttpGet(u))() end)
if ok and type(mod) == "table" and mod.Icon then break end
end
if ok and type(mod) == "table" and mod.Icon then break end
task.wait(0.6)
end
iconState.done = true
if ok and type(mod) == "table" and mod.Icon then
if not Library._iconUserSet then
Library._iconMod = mod
if mod.SetIconsType then pcall(mod.SetIconsType, Library.IconLib.Default or "lucide") end
Library._iconCache = {}
for _, fn in ipairs(Library._iconReady) do task.spawn(fn) end
Library._iconReady = {}
end
else
warn("[SpectreUI] icon library could not be loaded: " .. tostring(mod))
end
end)
end
local function iconModule()
local m = Library._iconMod
if m then return m end
if Library._iconUserSet or iconState.timedOut or (iconState.done and not m) then return nil end
iconLoad()
local t0 = os.clock()
while not iconState.done and os.clock() - t0 < (Library.IconLib.Timeout or 5) do task.wait() end
if not iconState.done then
iconState.timedOut = true
warn("[SpectreUI] icon library is slow, using text glyphs for now (it keeps downloading)")
end
return Library._iconMod or nil
end
function Library:SetIconModule(mod)
Library._iconUserSet = true
Library._iconMod = type(mod) == "table" and mod or false
Library._iconCache = {}
end
function Library:PreloadIcons(async)
if async then iconLoad() return true end
return iconModule() ~= nil
end
task.defer(function() if not Library._iconUserSet then iconLoad() end end)
function Library:AddIcons(pack, data)
local mod = iconModule()
if mod and mod.AddIcons then Library._iconCache = {} return pcall(mod.AddIcons, pack, data) end
return false
end
function Library:IsIconName(icon)
if type(icon) ~= "string" or icon:find("rbxasset", 1, true) then return false end
if icon:find(":", 1, true) then return true end
return #icon >= 3 and icon:match("^[%l%d][%l%d%-_%.]+$") ~= nil
end
function Library:ResolveIcon(name)
if not Library:IsIconName(name) then return nil end
Library._iconCache = Library._iconCache or {}
local c = Library._iconCache[name]
if c ~= nil then return c or nil end
local res = false
local mod = iconModule()
if mod then
local ok, r = pcall(mod.Icon, name, nil, true)
if ok and type(r) == "table" and type(r[1]) == "string" and type(r[2]) == "table" then
local d = r[2]
res = { Image = r[1], Size = d.ImageRectSize or Vector2.new(0, 0), Offset = d.ImageRectPosition or Vector2.new(0, 0) }
if type(d.Parts) == "table" then
local pack = name:match("^(.-):")
res.Parts = {}
for _, p in ipairs(d.Parts) do
local ok2, pr = pcall(mod.Icon, p, pack, true)
if ok2 and type(pr) == "table" and type(pr[1]) == "string" and type(pr[2]) == "table" then
res.Parts[#res.Parts + 1] = { Image = pr[1], Size = pr[2].ImageRectSize or Vector2.new(0, 0), Offset = pr[2].ImageRectPosition or Vector2.new(0, 0) }
end
end
end
else
warn("[SpectreUI] icon not found: " .. tostring(name))
end
end
Library._iconCache[name] = res
return res or nil
end
function Library:MakeIcon(desc, color)
local img = new("ImageLabel", {
Name = "IconImg", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1),
BackgroundTransparency = 1, ImageColor3 = color, ScaleType = Enum.ScaleType.Fit,
Image = desc.Image, ImageRectSize = desc.Size, ImageRectOffset = desc.Offset,
})
if desc.Parts then
for _, p in ipairs(desc.Parts) do
new("ImageLabel", {
Name = "Part", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ImageColor3 = color,
Image = p.Image, ImageRectSize = p.Size, ImageRectOffset = p.Offset, Parent = img,
})
end
end
return img
end
Library.KindIcons = {
Toggle = "lucide:toggle-right", KeybindToggle = "lucide:toggle-right", Keybind = "lucide:keyboard",
Slider = "lucide:sliders-horizontal", RangeSlider = "lucide:sliders-horizontal", Stepper = "lucide:hash",
Dropdown = "lucide:chevron-down", Segmented = "lucide:layout-grid", ListBox = "lucide:list",
ColorPicker = "lucide:palette", Textbox = "lucide:text-cursor-input", InputButton = "lucide:text-cursor-input",
TagInput = "lucide:tag", Button = "lucide:mouse-pointer-click", ButtonRow = "lucide:mouse-pointer-click",
HoldButton = "lucide:mouse-pointer-click", Stat = "lucide:activity", Graph = "lucide:activity", KeyValue = "lucide:key",
Countdown = "lucide:timer", Table = "lucide:table", ItemGrid = "lucide:package", Image = "lucide:image",
StatusCard = "lucide:layout-dashboard", Discord = "lucide:message-circle", CodeBlock = "lucide:code",
Console = "lucide:terminal", ConfigManager = "lucide:save", ThemeManager = "lucide:palette", FontPicker = "lucide:type",
Command = "lucide:zap", Tab = "lucide:folder",
}
function Library._searchIcon(parent, spec, fallback, color, size, T)
local o
local d = Library:IsIconName(spec) and Library:ResolveIcon(spec) or nil
if d then
o = Library:MakeIcon(d, color)
o.Size = UDim2.fromOffset(size, size)
elseif type(spec) == "number" or (type(spec) == "string" and spec:find("^rbxasset")) then
o = new("ImageLabel", {
AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(size, size),
BackgroundTransparency = 1, ImageColor3 = color, ScaleType = Enum.ScaleType.Fit,
Image = type(spec) == "number" and ("rbxassetid://" .. spec) or spec,
})
else
o = new("TextLabel", {
AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(size, size),
BackgroundTransparency = 1, Text = tostring(fallback or "?"):sub(1, 1):upper(), Font = T and T.FontBold or Enum.Font.GothamBold,
TextSize = math.max(10, math.floor(size * 0.9)), TextColor3 = color,
})
end
o.Parent = parent
return o
end
function Library._iconBadge(parent, spec, fallback, color, size, z, T, flat)
local b = new("Frame", {
Name = "IconBadge", AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(size, size),
BackgroundColor3 = color, BackgroundTransparency = flat and 1 or 0.82, BorderSizePixel = 0, Parent = parent,
}, { corner(8) })
Library._searchIcon(b, spec, fallback, color, math.floor(size * (flat and 1 or 0.58)), T)
if z then
b.ZIndex = z
for _, d in ipairs(b:GetDescendants()) do
if d:IsA("GuiObject") then d.ZIndex = z end
end
end
return b
end
local function stroke(color, thickness, transparency)
local st = new("UIStroke", {
Color = color, Thickness = thickness or 1, Transparency = math.max(0, (transparency or 0) - 0.15),
ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
})
if lowPower() and Library.Perf.Strokes ~= true and (thickness or 1) <= 1 and (transparency or 0) >= 0.3 then
st.Enabled = false
end
return st
end
local function gradient(a, b, rot)
local seq
if typeof(a) == "ColorSequence" then
seq, rot = a, b or 0
else
seq = ColorSequence.new(a, b)
rot = rot or 0
end
return new("UIGradient", { Color = seq, Rotation = rot })
end
local function cseq(...)
local pts = {}
for _, p in ipairs({ ... }) do table.insert(pts, ColorSequenceKeypoint.new(p[1], p[2])) end
return ColorSequence.new(pts)
end
local function wash(seq, rot)
local g = gradient(seq, rot)
if lowPower() then g.Enabled = false end
return g
end
local function fadeSeq(peak)
return NumberSequence.new({
NumberSequenceKeypoint.new(0, 1),
NumberSequenceKeypoint.new(0.5, peak or 0),
NumberSequenceKeypoint.new(1, 1),
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
if not ok then
warn("[SpectreUI] callback error: " .. tostring(err))
local hook = Library._onCbError
if hook then pcall(hook, err) end
end
end
local function isPress(i)
return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end
local function v2(p) return Vector2.new(p.X, p.Y) end
Library.AutoScale = true
Library.AutoScaleRef = nil
Library.AutoScaleMin = nil
Library.AutoScaleMax = nil
function Library._autoK(vp)
if Library.AutoScale == false then return 1 end
if not vp or vp.X <= 0 or vp.Y <= 0 then
local cam = workspace.CurrentCamera
vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
end
local ref = Library.AutoScaleRef or 520
local lo = Library.AutoScaleMin or 0.5
local hi = Library.AutoScaleMax or 2.2
return math.floor(math.clamp(vp.Y / ref, lo, hi) * 100 + 0.5) / 100
end
function Library._openSize(vp)
if not vp or vp.X <= 0 or vp.Y <= 0 then
local cam = workspace.CurrentCamera
vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
end
local phone = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
return math.clamp(math.floor(math.min(vp.X, vp.Y) * 0.14 + 0.5), 50, 60)

end
local function rowH() return 36 end
local function usingTouch()
return UserInputService:GetLastInputType() == Enum.UserInputType.Touch
end
local function onEnd(input, fn)
local c
c = input.Changed:Connect(function()
local s = input.UserInputState
if s == Enum.UserInputState.End or s == Enum.UserInputState.Cancel then
c:Disconnect()
fn()
end
end)
return c
end
local function bindPress(btn, down, up)
btn.InputBegan:Connect(function(i)
if not isPress(i) then return end
down(i)
onEnd(i, function() up(i) end)
end)
end
local function feedback(btn, target, prop, base, hover, press, noScale)
if prop == "BackgroundColor3" and typeof(hover) == "Color3" then
press = hover:Lerp(Color3.new(1, 1, 1), 0.1)
end
local sc = (noScale == false) and new("UIScale", { Parent = btn }) or nil
local hovering, pressed = false, false
local function refresh()
tween(target, pressed and 0.06 or 0.16, { [prop] = pressed and press or (hovering and hover or base) })
if sc then tween(sc, pressed and 0.07 or 0.2, { Scale = pressed and 0.97 or 1 }) end
end
btn.MouseEnter:Connect(function()
if usingTouch() then return end
hovering = true
refresh()
end)
btn.MouseLeave:Connect(function()
hovering = false
refresh()
end)
bindPress(btn, function()
pressed = true
refresh()
end, function()
pressed = false
if usingTouch() then hovering = false end
refresh()
end)
return sc
end
local function strokeFeedback(btn, s, base, hover)
local hovering = false
btn.MouseEnter:Connect(function()
if usingTouch() then return end
hovering = true
tween(s, 0.16, { Transparency = hover })
end)
btn.MouseLeave:Connect(function()
hovering = false
tween(s, 0.18, { Transparency = base })
end)
bindPress(btn, function()
tween(s, 0.06, { Transparency = math.max(0, hover - 0.15) })
end, function()
tween(s, 0.18, { Transparency = hovering and hover or base })
end)
end
local function snap(v, min, max, inc)
v = tonumber(v) or min
if v ~= v then v = min end
if min > max then min, max = max, min end
if inc and inc > 0 then v = min + math.floor((v - min) / inc + 0.5) * inc end
v = math.clamp(v, min, max)
return math.floor(v * 1e5 + 0.5) / 1e5
end
local rippleLive = setmetatable({}, { __mode = "k" })
local RIPPLE_MAX = 3
local function ripple(btn, pos)
if lowPower() then return end
local live = rippleLive[btn]
if not live then live = {} rippleLive[btn] = live end
if #live >= RIPPLE_MAX then
local oldest = table.remove(live, 1)
if oldest.Parent then oldest:Destroy() end
end
local layer = btn:FindFirstChild("RippleLayer")
if not layer then
layer = new("Frame", {
Name = "RippleLayer", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
ClipsDescendants = true, Active = false, ZIndex = 0, Parent = btn,
})
end
local bc = btn:FindFirstChildOfClass("UICorner")
local lc = layer:FindFirstChildOfClass("UICorner")
if bc then
if not lc then lc = Instance.new("UICorner") lc.Parent = layer end
lc.CornerRadius = bc.CornerRadius
elseif lc then
lc:Destroy()
end
local sc = 1
local node = btn
while node and node ~= game do
local u = node:FindFirstChildOfClass("UIScale")
if u and u.Scale > 0.01 then sc *= u.Scale end
node = node.Parent
end
local ap, sz = layer.AbsolutePosition, layer.AbsoluteSize
local base = math.max(sz.X, sz.Y) / sc
local r = new("Frame", {
AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.fromOffset(math.clamp((pos.X - ap.X) / sc, 0, sz.X / sc), math.clamp((pos.Y - ap.Y) / sc, 0, sz.Y / sc)),
Size = UDim2.fromOffset(base * 0.5, base * 0.5),
BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.85,
BorderSizePixel = 0, ZIndex = 0, Active = false, Parent = layer,
}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
table.insert(live, r)
tween(r, 0.55, { Size = UDim2.fromOffset(base * 2.6, base * 2.6), BackgroundTransparency = 1 }, QUAD, OUT).Completed:Connect(function()
local at = table.find(live, r)
if at then table.remove(live, at) end
r:Destroy()
end)
end
local function clickRipple(btn, press)
local pos
btn.InputBegan:Connect(function(i)
if isPress(i) then pos = i.Position end
end)
btn.MouseButton1Click:Connect(function()
if press and press.moved then return end
if pos then ripple(btn, pos) end
end)
end
local function dragSafePress(btn, down, up, thr)
thr = thr or 10
local state = { moved = false }
btn.InputBegan:Connect(function(i)
if not isPress(i) then return end
local start = v2(i.Position)
local cancelled = false
state.moved = false
down(i)
local mc
if i.UserInputType == Enum.UserInputType.Touch then
mc = i.Changed:Connect(function(prop)
if cancelled or prop ~= "Position" then return end
local m = i
if (v2(m.Position) - start).Magnitude > thr then
cancelled = true
state.moved = true
if mc then mc:Disconnect() mc = nil end
up(true)
end
end)
end
onEnd(i, function()
if mc then mc:Disconnect() mc = nil end
if not cancelled then up(false) end
end)
end)
return state
end
local function clampCenter(vp, half, c, top, side, free)
local m = 6
if free then
local keepX = math.min(half.X, 140)
local loX, hiX = keepX - half.X, vp.X + half.X - keepX
local loY, hiY = half.Y + m, vp.Y + half.Y - math.min(half.Y * 2, 72)
return Vector2.new(math.clamp(c.X, loX, hiX), math.clamp(c.Y, loY, math.max(loY, hiY)))
end
local mL, mR, mB = m, m, m
if side then mL, mR, mB = side.L, side.R, side.B end
local tm = math.max(m, top or 0)
local loX, hiX = half.X + mL, vp.X - half.X - mR
local loY, hiY = half.Y + tm, vp.Y - half.Y - mB
local x = (loX > hiX) and (mL + vp.X - mR) / 2 or math.clamp(c.X, loX, hiX)
local y = (loY > hiY) and (tm + vp.Y - mB) / 2 or math.clamp(c.Y, loY, hiY)
return Vector2.new(x, y)
end
local function makeDraggable(gui, handle, target, state)
local moveC, endC, focusC
local function viewport()
local vp = gui.AbsoluteSize
if vp.X <= 0 or vp.Y <= 0 then
local cam = workspace.CurrentCamera
if cam then vp = cam.ViewportSize end
end
return vp
end
local function centerOf()
local vp, p = viewport(), target.Position
return Vector2.new(p.X.Scale * vp.X + p.X.Offset, p.Y.Scale * vp.Y + p.Y.Offset)
end
local followC, shown, lastPos
local function stopFollow()
if followC then followC:Disconnect() followC = nil end
end
local function follow()
if followC then return end
followC = RunService.RenderStepped:Connect(function(dt)
dt = math.min(dt, 1 / 20)
if not target.Parent or not state.Center or (lastPos and target.Position ~= lastPos) then
stopFollow()
return
end
shown = shown:Lerp(state.Center, 1 - math.exp(-dt * (state.FollowRate or 24)))
if (shown - state.Center).Magnitude < 0.25 then
shown = state.Center
if not state.Dragging then stopFollow() end
end
lastPos = UDim2.fromOffset(math.round(shown.X), math.round(shown.Y))
target.Position = lastPos
end)
end
local function stop()
if moveC then moveC:Disconnect() moveC = nil end
if endC then endC:Disconnect() endC = nil end
if focusC then focusC:Disconnect() focusC = nil end
if state.Dragging then
state.Dragging = false
local vp = gui.AbsoluteSize
if state.Center and vp.X > 0 and vp.Y > 0 then
state.Rel = Vector2.new(state.Center.X / vp.X, state.Center.Y / vp.Y)
end
if state.OnEnd then state.OnEnd() end
end
end
state.Stop = stop
state.Glide = function(c)
local vp = gui.AbsoluteSize
if not shown or not followC then
shown = centerOf()
lastPos = nil
end
state.Center = c
if vp.X > 0 and vp.Y > 0 then state.Rel = Vector2.new(c.X / vp.X, c.Y / vp.Y) end
follow()
end
handle.InputBegan:Connect(function(i)
if not isPress(i) then return end
stop()
state.Dragging, state.Moved = true, false
if state.OnStart then state.OnStart() end
local touch = i.UserInputType == Enum.UserInputType.Touch
local startPt = v2(i.Position)
local startC = centerOf()
local vpSize, halfSize = viewport(), target.AbsoluteSize / 2
if state.Half then halfSize = Vector2.new(state.Half, state.Half) end
local thr = state.Threshold or 0
local topM = state.Top and state.Top() or 0
local sideM = state.Side and state.Side() or nil
stopFollow()
shown, lastPos = startC, nil
state.Center = startC
moveC = UserInputService.InputChanged:Connect(function(m)
if touch then
if m ~= i then return end
elseif m.UserInputType ~= Enum.UserInputType.MouseMovement then
return
end
local d = v2(m.Position) - startPt
if not state.Moved then
if d.Magnitude <= thr then return end
state.Moved = true
if not state.CatchUp then
startPt = v2(m.Position)
d = Vector2.zero
end
end
local c = clampCenter(vpSize, halfSize, startC + d, topM, sideM, state.Free)
if state.Clamp then c = state.Clamp(c, vpSize) end
if c ~= state.Center then
state.Center = c
if state.Direct then
target.Position = UDim2.fromOffset(math.round(c.X), math.round(c.Y))
elseif (touch or lowPower()) and not state.Smooth then
target.Position = UDim2.fromOffset(c.X, c.Y)
else
follow()
end
end
end)
endC = onEnd(i, stop)
focusC = UserInputService.WindowFocusReleased:Connect(stop)
end)
end
local function makeResizable(win, handle, mx, my)
local moveC, endC, focusC, stepC
local function stop()
if moveC then moveC:Disconnect() moveC = nil end
if endC then endC:Disconnect() endC = nil end
if focusC then focusC:Disconnect() focusC = nil end
if stepC then stepC:Disconnect() stepC = nil end
if win._resizing then
win._resizing = false
local fx = win._resizeFx
if fx and fx.End then fx.End() end
if win.Visible and not win._moving and not win._destroyed then pcall(win._FXResume, win) end
local sz = win.Main.AbsoluteSize
safe(win.Cfg.OnResize, math.floor(sz.X + 0.5), math.floor(sz.Y + 0.5))
if win._QueueFit and not win._destroyed then win:_QueueFit(0.2) end
end
end
handle.InputBegan:Connect(function(i)
if not isPress(i) then return end
stop()
win:CloseDropdowns()
win._drag.Stop()
win._resizing = true
pcall(win._FXPause, win)
local fx = win._resizeFx
if fx and fx.Start then fx.Start() end
local touch = i.UserInputType == Enum.UserInputType.Touch
local startPt = v2(i.Position)
local last = startPt
local vp0 = win.Gui.AbsoluteSize
local ms, mp = win.Main.Size, win.Main.Position
local startSz = Vector2.new(ms.X.Scale * vp0.X + ms.X.Offset, ms.Y.Scale * vp0.Y + ms.Y.Offset)
local startC = Vector2.new(mp.X.Scale * vp0.X + mp.X.Offset, mp.Y.Scale * vp0.Y + mp.Y.Offset)
local k0 = win._k or 1
local tl = startC - startSz * k0 / 2
tl = Vector2.new(math.max(tl.X, 6), math.max(tl.Y, 6))
if win.Maximized then win:_SetMaxFlag(false) end
win.Cfg.Width, win.Cfg.Height = math.floor(startSz.X + 0.5), math.floor(startSz.Y + 0.5)
win._userSized = true
local appliedW, appliedH = win.Cfg.Width, win.Cfg.Height
-- Input only records the pointer; the size is applied at most once per frame.
moveC = UserInputService.InputChanged:Connect(function(m)
if touch then
if m ~= i then return end
elseif m.UserInputType ~= Enum.UserInputType.MouseMovement then
return
end
last = v2(m.Position)
end)
stepC = RunService.RenderStepped:Connect(function()
if not win._resizing or win._destroyed then stop() return end
-- Release safety: a missed End event must never leave the window stuck in resize.
if touch then
local st = i.UserInputState
if st == Enum.UserInputState.End or st == Enum.UserInputState.Cancel then stop() return end
elseif not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
stop()
return
end
local rvp = win.Gui.AbsoluteSize
if rvp.X <= 0 or rvp.Y <= 0 then return end
local k = win._k or 1
local vp, tlD = rvp / k, tl / k
local d = (last - startPt) / k
local sL, sR, sB = 8 / k, 8 / k, 8 / k
local minW = math.min(win.Cfg.MinWidth or 520, vp.X - sL - sR)
local topPad = 8 / k
local minH = math.min(win.Cfg.MinHeight or 280, vp.Y - topPad - sB)
local maxW = math.max(minW, math.min(vp.X - sL - sR, vp.X - sR - tlD.X))
local maxH = math.max(minH, math.min(vp.Y - topPad - sB, vp.Y - sB - tlD.Y))
local w = math.floor(math.clamp(startSz.X + d.X * mx, minW, maxW) + 0.5)
local h = math.floor(math.clamp(startSz.Y + d.Y * my, minH, maxH) + 0.5)
if w == appliedW and h == appliedH then return end
appliedW, appliedH = w, h
win.Cfg.Width, win.Cfg.Height = w, h
local c = tl + Vector2.new(w, h) * k / 2
win._drag.Rel = Vector2.new(c.X / rvp.X, c.Y / rvp.Y)
win._drag.Center = c
win:_Fit()
end)
endC = onEnd(i, stop)
focusC = UserInputService.WindowFocusReleased:Connect(stop)
end)
return stop
end
local function rnd(a, b) return a + math.random() * (b - a) end
local function nsk(t, v) return NumberSequenceKeypoint.new(t, v) end
local function loopTween(fx, o, dur, props, style, reverse)
local tw = TweenService:Create(o, TweenInfo.new(dur, style or LINEAR, Enum.EasingDirection.InOut, -1, reverse or false), props)
tw:Play()
table.insert(fx.Tweens, tw)
return tw
end
local function travel(fx, o, a, b, dur)
local f = math.random()
o.Position = a:Lerp(b, f)
local first = TweenService:Create(o, TweenInfo.new(math.max(dur * (1 - f), 0.05), LINEAR), { Position = b })
table.insert(fx.Tweens, first)
first:Play()
first.Completed:Connect(function(state)
if state ~= Enum.PlaybackState.Completed or not o.Parent then return end
o.Position = a
local lt = loopTween(fx, o, dur, { Position = b })
if fx.Paused then lt:Pause() end
end)
end
local function dot(layer, size, color, transp, round)
return new("Frame", {
AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(size, round and size or math.max(2, size * 0.62)),
BackgroundColor3 = color, BackgroundTransparency = transp, BorderSizePixel = 0, Parent = layer,
}, { new("UICorner", { CornerRadius = UDim.new(round and 0.5 or 0.45, 0) }) })
end
local FX_KINDS = {}
local function cnt(fx, n) return fx.Lite and 0 or math.min(Library.Perf.Particles or 5, math.max(3, n // 2)) end
local function twinkle() return Library.Perf.Twinkle == true end
FX_KINDS.petals = function(fx, layer, T)
for i = 1, cnt(fx, 12) do
local o = dot(layer, math.random(8, 13), (i % 3 == 0) and T.Sheen or T.Accent2, rnd(0.6, 0.8), false)
o.Rotation = math.random(0, 360)
local x = rnd(0.05, 0.95)
local x2 = math.clamp(x + rnd(-0.14, 0.14), 0.03, 0.97)
travel(fx, o, UDim2.fromScale(x, -0.06), UDim2.fromScale(x2, 1.06), rnd(12, 19))
if twinkle() then loopTween(fx, o, rnd(3.5, 6.5), { Rotation = o.Rotation + (math.random() < 0.5 and 360 or -360) }) end
end
end
FX_KINDS.orbs = function(fx, layer, T)
local cols = { T.Accent, T.Accent2, T.Sheen }
for i = 1, cnt(fx, 14) do
local o = dot(layer, math.random(4, 8), cols[(i % 3) + 1], rnd(0.65, 0.85), true)
local x = rnd(0.05, 0.95)
travel(fx, o, UDim2.fromScale(x, 1.06), UDim2.fromScale(math.clamp(x + rnd(-0.06, 0.06), 0.03, 0.97), -0.06), rnd(15, 26))
if twinkle() then loopTween(fx, o, rnd(1.8, 3.6), { BackgroundTransparency = rnd(0.75, 0.88) }, SINE, true) end
end
end
FX_KINDS.embers = function(fx, layer, T)
for i = 1, cnt(fx, 16) do
local o = dot(layer, math.random(3, 5), (i % 4 == 0) and T.Sheen or T.Accent2, rnd(0.6, 0.8), true)
local x = rnd(0.05, 0.95)
travel(fx, o, UDim2.fromScale(x, 1.06), UDim2.fromScale(math.clamp(x + rnd(-0.07, 0.07), 0.03, 0.97), -0.06), rnd(6, 11))
if twinkle() then loopTween(fx, o, rnd(0.6, 1.4), { BackgroundTransparency = rnd(0.7, 0.85) }, SINE, true) end
end
end
FX_KINDS.rain = function(fx, layer, T)
for i = 1, cnt(fx, 14) do
local h = math.random(18, 38)
local o = new("Frame", {
AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(1, h), BackgroundColor3 = (i % 4 == 0) and T.Sheen or T.Accent,
BackgroundTransparency = rnd(0.65, 0.82), BorderSizePixel = 0, Parent = layer,
}, { new("UIGradient", { Rotation = 90, Transparency = fadeSeq(0) }) })
local x = rnd(0.04, 0.96)
travel(fx, o, UDim2.fromScale(x, -0.08), UDim2.fromScale(x, 1.08), rnd(2.6, 5.2))
end
end
FX_KINDS.grid = function(fx, layer, T)
local function line(vertical, at)
new("Frame", {
AnchorPoint = vertical and Vector2.new(0.5, 0) or Vector2.new(0, 0.5),
Position = vertical and UDim2.fromScale(at, 0) or UDim2.fromScale(0, at),
Size = vertical and UDim2.new(0, 1, 1, 0) or UDim2.new(1, 0, 0, 1),
BackgroundColor3 = T.Accent, BackgroundTransparency = 0.96, BorderSizePixel = 0, Parent = layer,
}, { new("UIGradient", { Rotation = vertical and 90 or 0, Transparency = NumberSequence.new({ nsk(0, 1), nsk(0.5, 0), nsk(1, 1) }) }) })
end
for i = 1, 7 do line(true, i / 8) end
for i = 1, 4 do line(false, i / 5) end
local beam = new("Frame", {
Size = UDim2.new(1, 0, 0.24, 0), Position = UDim2.fromScale(0, -0.3), BackgroundColor3 = T.Accent,
BackgroundTransparency = 0.92, BorderSizePixel = 0, Parent = layer,
}, { new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ nsk(0, 1), nsk(0.85, 0.4), nsk(1, 1) }) }) })
local tw = TweenService:Create(beam, TweenInfo.new(4.2, LINEAR, Enum.EasingDirection.Out, -1, false, 1.3), { Position = UDim2.fromScale(0, 1.05) })
tw:Play()
table.insert(fx.Tweens, tw)
for i = 1, cnt(fx, 6) do
local o = dot(layer, 5, (i % 2 == 0) and T.Accent2 or T.Accent, 0.82, true)
o.Position = UDim2.fromScale(math.random(1, 7) / 8, math.random(1, 4) / 5)
if twinkle() then loopTween(fx, o, rnd(1.2, 2.6), { BackgroundTransparency = 0.95 }, SINE, true) end
end
end
local function aurora(fx, layer, radius, a, b, rot, peak, dur, from, to)
local g = new("UIGradient", {
Rotation = rot, Offset = Vector2.new(from, 0),
Color = cseq({ 0, a }, { 0.5, b }, { 1, a }),
Transparency = NumberSequence.new({ nsk(0, 1), nsk(0.25, 0.94), nsk(0.5, peak), nsk(0.75, 0.94), nsk(1, 1) }),
})
new("Frame", {
Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = layer,
}, { new("UICorner", { CornerRadius = UDim.new(0, radius) }), g })
loopTween(fx, g, dur, { Offset = Vector2.new(to, 0) }, SINE, true)
end
local function scene(layer, radius, T, minimal)
local bg = T.Background
local white = Color3.new(1, 1, 1)
local function full(color, grads)
local kids = { new("UICorner", { CornerRadius = UDim.new(0, radius) }) }
for _, g in ipairs(grads) do kids[#kids + 1] = g end
return new("Frame", {
Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, BorderSizePixel = 0,
Active = false, Parent = layer,
}, kids)
end
full(white, { new("UIGradient", {
Rotation = 135,
Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, bg:Lerp(T.Accent, 0.14)),
ColorSequenceKeypoint.new(0.42, bg:Lerp(T.Accent, 0.03)),
ColorSequenceKeypoint.new(0.72, bg),
ColorSequenceKeypoint.new(1, bg:Lerp(T.Accent2, 0.12)),
}),
}) })
if minimal then return end
local function band(color, rot, at, peak)
full(color, { new("UIGradient", {
Rotation = rot,
Transparency = NumberSequence.new({
nsk(0, 1), nsk(math.max(at - 0.45, 0.01), 1), nsk(at, peak), nsk(math.min(at + 0.45, 0.99), 1), nsk(1, 1),
}),
}) })
end
band(T.Accent, 25, 0.2, 0.9)
band(T.Accent2, 115, 0.85, 0.92)
full(Color3.new(0, 0, 0), { new("UIGradient", {
Rotation = 90,
Transparency = NumberSequence.new({ nsk(0, 1), nsk(0.55, 1), nsk(1, 0.35) }),
}) })
new("Frame", {
Name = "Rim", Position = UDim2.fromOffset(1, 1), Size = UDim2.new(1, -2, 1, -2),
BackgroundTransparency = 1, BorderSizePixel = 0, Active = false, Parent = layer,
}, {
new("UICorner", { CornerRadius = UDim.new(0, math.max(radius - 1, 0)) }),
new("UIStroke", {
Color = white, Thickness = 1, Transparency = 0.45, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
}, {
new("UIGradient", {
Rotation = 135,
Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, T.Sheen),
ColorSequenceKeypoint.new(0.5, T.Accent),
ColorSequenceKeypoint.new(1, T.Accent2),
}),
Transparency = NumberSequence.new({ nsk(0, 0.1), nsk(0.5, 0.8), nsk(1, 0.2) }),
}),
}),
})
end
function Window:SetBackground(kind, quiet)
local fx = self.FX
if not fx then return end
if kind == nil then kind = self.Theme.FX end
for _, tw in ipairs(fx.Tweens) do pcall(function() tw:Cancel() end) end
table.clear(fx.Tweens)
fx.Paused = false
if fx.Layer then fx.Layer:Destroy() fx.Layer = nil end
self.FXOn = false
if not kind then return end
if lowPower() and Library.Perf.Backdrop == false then return end
fx.Lite = lowPower() or (self._qual or 0) >= 1
local T = self.Theme
local layer = new("Frame", {
Name = "FX", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
ClipsDescendants = true, ZIndex = 0, Active = false, Parent = self.Main,
})
fx.Layer = layer
self.FXOn = true
local r = self.Radius or 12
scene(layer, r, T, (self._qual or 0) >= 2 or lowPower())
if fx.Lite then return end
if Library.Perf.Aurora == true then aurora(fx, layer, r, T.Accent, T.Accent2, 28, 0.9, rnd(18, 24), -0.55, 0.55) end
local build = FX_KINDS[kind] or FX_KINDS.orbs
build(fx, layer, T)
if not self.Visible or self._moving then self:_FXPause() end
end
function Window:_FXPause()
if not self.FX then return end
self.FX.Paused = true
for _, tw in ipairs(self.FX.Tweens) do
if tw.PlaybackState == Enum.PlaybackState.Playing then tw:Pause() end
end
local sh = self._sheen
if sh and sh.PlaybackState == Enum.PlaybackState.Playing then sh:Pause() end
end
function Window:_FXResume()
if not self.FX or self._blurred then return end
self.FX.Paused = false
for _, tw in ipairs(self.FX.Tweens) do
if tw.PlaybackState == Enum.PlaybackState.Paused then tw:Play() end
end
local sh = self._sheen
if sh and sh.PlaybackState == Enum.PlaybackState.Paused then sh:Play() end
end
function Window:_GlowVisible(v)
local gl = self.Glow
if not gl then return end
v = v and self.Main.Visible and (self._qual or 0) < 3
if v then
if not self._glowHidden then return end
self._glowHidden = false
if self._glowSync then self._glowSync() end
for _, g in ipairs(gl) do
g.stroke.Transparency = 1
g.frame.Visible = true
tween(g.stroke, 0.35, { Transparency = g.base }, SINE, OUT)
end
else
if self._glowHidden then return end
self._glowHidden = true
for _, g in ipairs(gl) do g.frame.Visible = false end
end
end
function Window:_MotionBegin(dur, keepGlow)
if self._destroyed then return end
self._motionTok = (self._motionTok or 0) + 1
local tok = self._motionTok
self._moving = true
self:_FXPause()
if not keepGlow then self:_GlowVisible(false) end
local hold = (dur or 0.4) * math.max(Library.Anim.Speed or 1, 1) + 0.12
task.delay(hold, function()
if self._motionTok ~= tok or self._destroyed then return end
self._moving = false
if self.Visible and not self._drag.Dragging then
self:_FXResume()
self:_GlowVisible(true)
end
end)
end
function Window:_StartGovernor()
if self._gov or Library.Perf.Adaptive == false then return end
local P = Library.Perf
local acc, n, slow = 0, 0, 0
local good = 0
local holdUntil, backoff = 0, 12
local resumeAt = os.clock() + (P.Warmup or 3)
self._govReset = function() acc, n, slow, good = 0, 0, 0, 0 resumeAt = os.clock() + (P.Warmup or 3) end
self._govHold = function() holdUntil = os.clock() + backoff backoff = math.min(backoff * 2, 120) good = 0 end
self._gov = RunService.Heartbeat:Connect(function(dt)
if not self.Visible or self._moving or self._drag.Dragging or os.clock() < resumeAt then
acc, n, slow = 0, 0, 0
return
end
acc += dt
n += 1
if dt > (P.SlowFrame or 1 / 30) then slow += 1 end
if acc >= 2 then
local share, avg = slow / n, acc / n
acc, n, slow = 0, 0, 0
local q = self._qual or 0
if share > (P.SlowShare or 0.2) then
good = 0
self:_Degrade()
elseif P.Recover ~= false and q >= 1 and q <= 2 and not lowPower() and share == 0 and avg < 1 / 45 and os.clock() >= holdUntil then
good += 1
if good >= (P.RecoverWindows or 4) then
good = 0
self:_Recover()
end
else
good = 0
end
end
end)
table.insert(self.Conns, self._gov)
end
function Window:_Recover()
local q = self._qual or 0
if q < 1 or q > 2 or self._destroyed then return end
self._qual = q - 1
self:SetBackground(nil, true)
if self._govReset then self._govReset() end
safe(self.Cfg.OnRecover, self._qual)
end
function Window:_Degrade()
local q = (self._qual or 0) + 1
self._qual = q
if q <= 2 then
self:SetBackground(nil, true)
else
self:_GlowVisible(false)
self._flat = true
local mg = self.Main and self.Main:FindFirstChildOfClass("UIGradient")
if mg then mg.Enabled = false end
for _, t in ipairs(self.Tabs) do
for _, sec in ipairs(t.Sections) do
local g = sec.Frame and sec.Frame:FindFirstChildOfClass("UIGradient")
if g then g.Enabled = false end
end
end
if self._gov then self._gov:Disconnect() self._gov = nil end
end
if self._govReset then self._govReset() end
if self._govHold then self._govHold() end
safe(self.Cfg.OnDegrade, q)
end
function Library:CreateWindow(cfg)
cfg = cfg or {}
local T = table.clone(self.Theme)
local ov = cfg.Theme
if type(ov) == "string" then
ov = self.Themes[ov]
if ov then T = buildTheme(ov) end
ov = nil
end
for k, v in pairs(ov or {}) do T[k] = v end
deriveTheme(T)
local fontName = self.FontName
if type(cfg.Theme) == "table" and cfg.Theme.Font ~= nil then fontName = "Custom" end
if cfg.Font ~= nil then
local fr, fb, fn = Library._fontPair(cfg.Font)
if fr then T.Font, T.FontBold, fontName = fr, fb, fn end
end
local RADIUS = 16
local GLASS = math.clamp(tonumber(cfg.Transparency) or 0, 0, 1)
local function glass(base) return base + (1 - base) * GLASS end
local win = setmetatable({
Library = self, Theme = T, Cfg = cfg, Glass = GLASS, Tabs = {}, Conns = {}, Visible = true,
_drag = {}, _openDrag = { Threshold = 8 }, Maximized = false, FontName = fontName,
}, Window)
local title = cfg.Title or "SpectreUI"
local brand, sub = title:match("^(.-)%s*|%s*(.+)$")
brand = brand or title
win.Brand, win.Sub = brand, sub
local gui = new("ScreenGui", {
Name = "SpectreUI", ResetOnSpawn = false, IgnoreGuiInset = true,
ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
})
Library._fullScreen(gui)
Library._mount(gui)
win.Gui = gui
table.insert(win.Conns, gui.AncestryChanged:Connect(function(_, parent)
if parent == nil and not win._destroyed then
task.defer(function()
if not win._destroyed and gui.Parent == nil then pcall(Library._mount, gui) end
end)
end
end))
local main = new("Frame", {
Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
BackgroundColor3 = T.Background, BackgroundTransparency = glass(0.02), BorderSizePixel = 0,
Active = true,
Parent = gui,
}, {
corner(RADIUS),
stroke(T.Border, 1, 0.25),
wash(cseq({ 0, T.Top }, { 1, T.Background }), 90),
})
win.Main = main
win._k = Library._autoK(gui.AbsoluteSize)
win._kApplied = win._k
win.Scale = new("UIScale", { Scale = win._k, Parent = main })
local mainStroke = main:FindFirstChildOfClass("UIStroke")
if Library.Flat ~= false then
win._flat = true
local mg = main:FindFirstChildOfClass("UIGradient")
if mg then mg.Enabled = false end
end
do
local mg = main:FindFirstChildOfClass("UIGradient")
if mg and not T.Clean then
mg.Color = cseq({ 0, T.Top:Lerp(T.Background, 0.45) }, { 1, T.Background })
mg.Rotation = 90
mg.Enabled = true
elseif mg then
mg.Enabled = false
end
win.TopGlow = new("Frame", {
Name = "TopGlow", Visible = false, Size = UDim2.new(1, 0, 0, 190), BackgroundColor3 = T.Accent, BackgroundTransparency = 0,
BorderSizePixel = 0, Active = false, ZIndex = 1, Parent = main,
}, {
corner(RADIUS),
new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 1) }) }),
})
end
win.Radius = RADIUS
win.FX = { Tweens = {} }
win:SetBackground(cfg.Background ~= false and (cfg.FX or T.FX) or false, true)
win.Veil = new("Frame", {
Name = "Veil", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Background, BackgroundTransparency = 1,
BorderSizePixel = 0, ZIndex = 50, Visible = false, Parent = main,
}, { corner(RADIUS) })
local header = new("Frame", {
Name = "Header", Size = UDim2.new(1, 0, 0, HEADER_H), BackgroundTransparency = 1, Parent = main,
})
local hcard = new("Frame", {
Name = "HeaderCard", Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 0, HEADER_H - 12),
BackgroundColor3 = T.Panel, BackgroundTransparency = glass(0), BorderSizePixel = 0, Parent = header,
}, {
corner(12), stroke(T.Border, 1, 0.45),
new("Frame", {
Name = "Tint", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Accent, BackgroundTransparency = 1,
BorderSizePixel = 0,
}, {
corner(12),
new("UIGradient", { Transparency = NumberSequence.new({
NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(0.5, 0.95), NumberSequenceKeypoint.new(1, 0.98),
}) }),
}),
})
win.HeaderCard = hcard
win._rest = 0.9
new("Frame", {
Name = "GlowLine", Visible = not T.Clean, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 16, 1, 0), Size = UDim2.fromOffset(44, 3),
BackgroundColor3 = T.Accent, BorderSizePixel = 0, Parent = hcard,
}, { corner(4) })
if false then
new("Frame", {
Name = "Sheen", Size = UDim2.new(1, 0, 0.55, 0), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.93,
BorderSizePixel = 0, Active = false, Parent = hcard,
}, { corner(12), new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0, 1) }) })
end
local closeW = 38
local canResize = cfg.Resizable ~= false
local nBtns = canResize and 3 or 2
local btnArea = closeW * nBtns + 4 * (nBtns - 1)
local left = new("Frame", {
Size = UDim2.new(1, -(btnArea + 16), 1, 0), BackgroundTransparency = 1, ClipsDescendants = true, Parent = hcard,
}, {
list(10, { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center }),
padding(10, 0, 0, 0),
})
win.Left = left
if cfg.Logo then
local ls = cfg.LogoSize or 34
local lw, lh
if type(ls) == "table" then lw, lh = ls[1] or ls.X or 26, ls[2] or ls.Y or 26
elseif typeof(ls) == "Vector2" then lw, lh = ls.X, ls.Y
else lw, lh = ls, ls end
local hlogo = new("ImageLabel", {
Name = "Logo", LayoutOrder = 1, Size = UDim2.fromOffset(lw, lh), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit,
ImageColor3 = cfg.LogoColor or Color3.new(1, 1, 1),
Image = (type(cfg.Logo) == "number" or tonumber(cfg.Logo)) and ("rbxassetid://" .. tostring(cfg.Logo)) or cfg.Logo, Parent = left,
})
if cfg.LogoCorner and cfg.LogoCorner > 0 then
new("UICorner", { CornerRadius = UDim.new(0, cfg.LogoCorner), Parent = hlogo })
end
win.LogoImage = hlogo
else
new("Frame", {
LayoutOrder = 1, Size = UDim2.fromOffset(34, 34), BackgroundColor3 = Color3.new(1, 1, 1),
BorderSizePixel = 0, Parent = left,
}, {
corner(10), gradient(T.Accent, T.Accent2, 45), stroke(T.Border, 1, 0.3),
Library._oa(new("TextLabel", {
Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = brand:sub(1, 2),
Font = Enum.Font.GothamBlack, TextSize = 15, TextColor3 = Library.OnAccent(T),
})),
})
end
win.BrandLabel = new("TextLabel", {
LayoutOrder = 2, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AX, BackgroundTransparency = 1,
Text = brand, Font = T.FontBold, TextSize = 18, TextColor3 = T.Text, Parent = left,
})
do
local lbl = win.BrandLabel
local bscale = new("UIScale", { Scale = 1, Parent = lbl })
do
local base, hi = Color3.fromRGB(150, 150, 170), Color3.new(1, 1, 1)
local grad = new("UIGradient", {
Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, base), ColorSequenceKeypoint.new(0.3, base),
ColorSequenceKeypoint.new(0.5, hi),
ColorSequenceKeypoint.new(0.7, base), ColorSequenceKeypoint.new(1, base),
}),
Offset = Vector2.new(-1, 0), Enabled = false, Parent = lbl,
})
local sw = TweenService:Create(grad, TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false), { Offset = Vector2.new(1, 0) })
win._sheen = sw
end
function win:_BrandIntro()
if self._destroyed then return end
lbl.TextTransparency = 1
bscale.Scale = 0.88
nextFrame(function()
if win._destroyed then return end
tween(lbl, 0.5, { TextTransparency = 0 })
tween(bscale, 0.6, { Scale = 1 }, Enum.EasingStyle.Back)
end)
end
task.delay(0.25, function() if not win._destroyed then win:_BrandIntro() end end)
end
if sub then
win.SubSep = new("Frame", {
LayoutOrder = 3, Size = UDim2.fromOffset(0, 24), AutomaticSize = AX, BackgroundColor3 = T.Accent,
BackgroundTransparency = 0.82, BorderSizePixel = 0, Parent = left,
}, { corner(12), stroke(T.Border, 1, 0.4), padding(10, 0, 10, 0) })
win.SubLabel = new("TextLabel", {
Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AX, BackgroundTransparency = 1,
Text = sub, Font = T.Font, TextSize = 13, TextColor3 = T.Text, Parent = win.SubSep,
})
end
local close = new("TextButton", {
AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(closeW, closeW),
BackgroundColor3 = T.Control, BackgroundTransparency = win._rest, Text = "", AutoButtonColor = false, Parent = hcard,
}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
win._xs = {}
for _, rot in ipairs({ 45, -45 }) do
table.insert(win._xs, new("Frame", {
AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(14, 2), Rotation = rot,
BackgroundColor3 = T.SubText, BorderSizePixel = 0, Active = false, Parent = close,
}, { new("UICorner", { CornerRadius = UDim.new(1, 0) }) }))
end
win._xTint = function(c, d)
for _, f in ipairs(win._xs) do tween(f, d or 0.14, { BackgroundColor3 = c }) end
end
close.MouseEnter:Connect(function()
if not usingTouch() then
win._xTint(Color3.fromRGB(255, 125, 125))
tween(close, 0.14, { BackgroundColor3 = Color3.fromRGB(140, 42, 48), BackgroundTransparency = 0.3 })
end
end)
close.MouseLeave:Connect(function()
win._xTint(T.SubText)
tween(close, 0.16, { BackgroundColor3 = T.Control, BackgroundTransparency = win._rest })
end)
bindPress(close, function()
win._xTint(Color3.fromRGB(255, 125, 125), 0.07)
end, function()
win._xTint(T.SubText, 0.16)
tween(close, 0.16, { BackgroundColor3 = T.Control, BackgroundTransparency = win._rest })
end)
local confirmOpen = false
local function deleteNow()
safe(cfg.OnClose)
task.defer(function()
if not win._destroyed then win:Destroy() end
end)
end
close.MouseButton1Click:Connect(function()
if confirmOpen or win._destroyed then return end
confirmOpen = true
local h = win:Confirm({
Title = cfg.ConfirmTitle or "Delete UI",
Content = cfg.ConfirmText or "Are you sure you want to delete this UI? This cannot be undone.",
Kind = "Warning", Danger = true,
Yes = cfg.ConfirmYes or "Confirm", No = cfg.ConfirmNo or "Cancel",
OnYes = deleteNow,
OnClose = function() confirmOpen = false end,
})
if not h then
confirmOpen = false
deleteNow()
end
end)
do
local hideB = new("TextButton", {
Name = "Hide", AnchorPoint = Vector2.new(1, 0.5),
Position = UDim2.new(1, -(8 + (closeW + 4) * (canResize and 2 or 1)), 0.5, 0),
Size = UDim2.fromOffset(closeW, closeW), BackgroundColor3 = T.Control, BackgroundTransparency = win._rest,
Text = "", AutoButtonColor = false, Parent = hcard,
}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
local bar = new("Frame", {
AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(15, 2),
BackgroundColor3 = T.SubText, BorderSizePixel = 0, Parent = hideB,
}, { corner(1) })
hideB.MouseEnter:Connect(function()
if not usingTouch() then
tween(bar, 0.14, { BackgroundColor3 = T.Accent })
tween(hideB, 0.14, { BackgroundTransparency = 0.4 })
end
end)
hideB.MouseLeave:Connect(function()
tween(bar, 0.14, { BackgroundColor3 = T.SubText })
tween(hideB, 0.14, { BackgroundTransparency = win._rest })
end)
bindPress(hideB, function()
end, function()
tween(bar, 0.16, { BackgroundColor3 = T.SubText })
tween(hideB, 0.16, { BackgroundTransparency = win._rest })
end)
hideB.MouseButton1Click:Connect(function() win:SetVisible(false) end)
end
if canResize then
local mxb = new("TextButton", {
Name = "Maximize", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -(8 + closeW + 4), 0.5, 0),
Size = UDim2.fromOffset(closeW, closeW), BackgroundColor3 = T.Control, BackgroundTransparency = win._rest,
Text = "", AutoButtonColor = false, Parent = hcard,
}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
local IT, IARM = 2, 5
local bars = {}
for _, cn in ipairs({ { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }) do
for _, horiz in ipairs({ true, false }) do
bars[#bars + 1] = {
sx = cn[1], sy = cn[2], h = horiz,
f = new("Frame", {
AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = T.SubText, BorderSizePixel = 0, ZIndex = 3, Parent = mxb,
}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }) }),
}
end
end
local function tint(c)
for _, b in ipairs(bars) do b.f.BackgroundColor3 = c end
end
local function drawIcon(restore, instant)
local vd = restore and 2 or 7
local dir = restore and 1 or -1
for _, b in ipairs(bars) do
local vx, vy = b.sx * vd, b.sy * vd
local len = IARM + IT / 2
local cx, cy, w, h = vx, vy, IT, IT
if b.h then
cx, w = vx + b.sx * dir * (IARM - IT / 2) / 2, len
else
cy, h = vy + b.sy * dir * (IARM - IT / 2) / 2, len
end
local pos, size = UDim2.new(0.5, cx, 0.5, cy), UDim2.fromOffset(w, h)
if instant then
b.f.Position, b.f.Size = pos, size
else
tween(b.f, 0.2, { Position = pos, Size = size })
end
end
end
drawIcon(false, true)
win._setMaxIcon = function(v) drawIcon(v and true or false) end
mxb.MouseEnter:Connect(function()
if not usingTouch() then
tint(T.Accent)
tween(mxb, 0.14, { BackgroundTransparency = 0.4 })
end
end)
mxb.MouseLeave:Connect(function()
tint(T.SubText)
tween(mxb, 0.16, { BackgroundTransparency = win._rest })
end)
bindPress(mxb, function()
end, function()
if usingTouch() then tint(T.SubText); tween(mxb, 0.16, { BackgroundTransparency = win._rest }) end
end)
mxb.MouseButton1Click:Connect(function() win:SetMaximized(not win.Maximized) end)
end
local dragZone = new("Frame", {
Name = "DragZone", Size = UDim2.new(1, -(btnArea + 28), 1, 0), BackgroundTransparency = 1,
Active = true, ZIndex = 5, Parent = header,
})
if canResize then
local lastTap = 0
dragZone.InputBegan:Connect(function(i)
if not isPress(i) then return end
local now = os.clock()
if now - lastTap < 0.35 then
lastTap = 0
win:SetMaximized(not win.Maximized)
else
lastTap = now
end
end)
end
win._drag.OnStart = function()
win:CloseDropdowns()
win:_FXPause()
win:_GlowVisible(false)
if not lowPower() then mainStroke.Color, mainStroke.Transparency = T.Accent, 0.35 end
end
win._drag.OnEnd = function()
if win.Visible and not win._moving then win:_FXResume() win:_GlowVisible(true) end
if win._govReset then win._govReset() end
if not lowPower() then mainStroke.Color, mainStroke.Transparency = T.Border, 0.1 end
end
win._drag.Top = function() return win:_Top() end
win._drag.Side = function() return win:_Sides() end
win._drag.Free = false
makeDraggable(gui, dragZone, main, win._drag)
local body = new("Frame", {
Name = "Body", Position = UDim2.fromOffset(0, HEADER_H), Size = UDim2.new(1, 0, 1, -HEADER_H),
BackgroundTransparency = 1, Parent = main,
})
win.Body = body
local sidebar = new("Frame", { Size = UDim2.new(0, 192, 1, 0), BackgroundTransparency = 1, Parent = body })
win.SidePanel = new("Frame", {
Name = "SidePanel", Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -19, 1, -10),
BackgroundColor3 = T.Panel, BackgroundTransparency = glass(0), BorderSizePixel = 0, Parent = sidebar,
}, { corner(14), stroke(T.Border, 1, 0.35) })
win.Sidebar = sidebar
win.TabList = new("ScrollingFrame", {
Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -19, 1, -FOOT_H - 16), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
CanvasSize = UDim2.new(), AutomaticCanvasSize = AY, ScrollingDirection = Enum.ScrollingDirection.Y,
ElasticBehavior = Enum.ElasticBehavior.Never, Parent = sidebar,
}, { list(7), padding(8, 10, 8, 6) })
local footer = new("Frame", {
Position = UDim2.new(0, 14, 1, -FOOT_H - 16), Size = UDim2.new(1, -27, 0, FOOT_H), BackgroundColor3 = T.Control,
BackgroundTransparency = 0.55, BorderSizePixel = 0, Parent = sidebar,
}, { corner(12), stroke(T.Border, 1, 0.5), padding(14, 0, 8, 0) })
win.ProfileButton = new("TextButton", {
Name = "ProfileButton", Position = UDim2.fromOffset(-14, 0), Size = UDim2.new(1, 22, 1, 0),
BackgroundColor3 = T.Accent, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0, Parent = footer,
}, { corner(12) })
feedback(win.ProfileButton, win.ProfileButton, "BackgroundTransparency", 1, 0.88, 0.78, true)
local lpl = Players.LocalPlayer
local dispName = (lpl and lpl.DisplayName) or "Player"
local userName = (lpl and lpl.Name) or "Player"
win.FooterAvatar = new("ImageLabel", {
Position = UDim2.fromOffset(0, 10), Size = UDim2.fromOffset(34, 34), BackgroundColor3 = T.Panel, BorderSizePixel = 0,
Image = "", ScaleType = Enum.ScaleType.Crop, Parent = footer,
}, { corner(17), stroke(T.Accent, 1.5, 0.35) })
if lpl then
task.spawn(function()
local okT, img = pcall(function()
return Players:GetUserThumbnailAsync(lpl.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
end)
if okT and img and win.FooterAvatar and win.FooterAvatar.Parent then win.FooterAvatar.Image = img end
end)
end
win.FooterBrand = new("TextLabel", {
Position = UDim2.fromOffset(42, 10), Size = UDim2.new(1, -58, 0, 18), BackgroundTransparency = 1, Text = dispName,
Font = T.FontBold, TextSize = 14, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = footer,
}, { gradient(T.Accent, T.Accent2, 0) })
win.FooterSub = new("TextLabel", {
Position = UDim2.fromOffset(42, 28), Size = UDim2.new(1, -58, 0, 16), BackgroundTransparency = 1, Text = "@" .. userName,
Font = T.Font, TextSize = 13, TextColor3 = T.SubText, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = footer,
})
win.FooterArrow = new("TextLabel", {
AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -2, 0, 27), Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1,
Text = "\226\150\178", Font = T.FontBold, TextSize = 13, TextColor3 = T.SubText, Parent = footer,
})
win.Footer = footer
win:_BuildProfile()
local content = new("Frame", {
Position = UDim2.fromOffset(164, 0), Size = UDim2.new(1, -164, 1, 0), BackgroundTransparency = 1, Parent = body,
})
win.Content = content
local SEARCH_BAR_H = closeW
local searchBar = new("Frame", {
Name = "SearchBar", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -(8 + btnArea + 10), 0.5, 0),
Size = UDim2.fromOffset(SEARCH_BAR_H, SEARCH_BAR_H), BackgroundColor3 = T.Control,
BackgroundTransparency = win._rest, BorderSizePixel = 0, ClipsDescendants = true, Parent = hcard,
}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }), stroke(T.Border, 1, 1) })
win.SearchBar = searchBar
local searchStroke = searchBar:FindFirstChildOfClass("UIStroke")
searchStroke.Transparency = 1
local magX = math.floor((SEARCH_BAR_H - 16) / 2)
local mag = new("Frame", {
AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, magX, 0.5, 0), Size = UDim2.fromOffset(16, 16),
BackgroundTransparency = 1, Parent = searchBar,
})
local magRing = new("Frame", {
Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1, Parent = mag,
}, { corner(5), stroke(T.SubText, 1.6, 0.15) })
local magRingStroke = magRing:FindFirstChildOfClass("UIStroke")
local magHandle = new("Frame", {
Position = UDim2.fromOffset(8, 10), Size = UDim2.fromOffset(6, 2), Rotation = 45, BackgroundColor3 = T.SubText,
BorderSizePixel = 0, Parent = mag,
})
win.SearchBox = new("TextBox", {
Position = UDim2.fromOffset(32, 0), Size = UDim2.new(1, -62, 1, 0), BackgroundTransparency = 1, Text = "", Visible = false,
PlaceholderText = "Search all tabs...", PlaceholderColor3 = T.SubText, TextColor3 = T.Text, Font = T.Font, TextSize = 14,
TextXAlignment = LEFT, ClearTextOnFocus = false, TextTruncate = Enum.TextTruncate.AtEnd, Parent = searchBar,
})
local clearBtn = new("TextButton", {
Name = "SearchClear", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(18, 18),
BackgroundColor3 = T.SubText, BackgroundTransparency = 0.8, Text = "", AutoButtonColor = false, Visible = false, ZIndex = 6, Parent = searchBar,
}, { new("UICorner", { CornerRadius = UDim.new(1, 0) }) })
for _, rot in ipairs({ 45, -45 }) do
new("Frame", {
AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(8, 1.5), Rotation = rot,
BackgroundColor3 = T.Text, BorderSizePixel = 0, ZIndex = 7, Parent = clearBtn,
})
end
local function updateClear()
clearBtn.Visible = win.SearchBox.Visible and win.SearchBox.Text ~= ""
end
win.SearchBox:GetPropertyChangedSignal("Text"):Connect(updateClear)
clearBtn.MouseEnter:Connect(function() if not usingTouch() then tween(clearBtn, 0.12, { BackgroundTransparency = 0.5 }) end end)
clearBtn.MouseLeave:Connect(function() tween(clearBtn, 0.16, { BackgroundTransparency = 0.8 }) end)
clearBtn.MouseButton1Click:Connect(function()
win.SearchBox.Text = ""
win.SearchBox:CaptureFocus()
end)
local searchOpen, expandedW, applyHeader = false, 190, nil
local hit = new("TextButton", {
Name = "SearchHit", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
ZIndex = 5, Parent = searchBar,
})
do
local leftList = left:FindFirstChildOfClass("UIListLayout")
local busy = false
function applyHeader(animate)
if busy or win._destroyed then return end
busy = true
local sc = (win.Scale and win.Scale.Scale) or 1
if sc <= 0.01 then sc = 1 end
local total = hcard.AbsoluteSize.X / sc
if total > 40 then
local rightW = 8 + btnArea + 10
local contentW = (leftList and leftList.AbsoluteContentSize.X or 0) / sc
local free = total - rightW - (contentW + 10 + 12)
local maxW = math.max(70, total - rightW - 46)
expandedW = math.floor(math.min(math.clamp(free, 120, 220), maxW))
local w = searchOpen and expandedW or SEARCH_BAR_H
if animate then
tween(searchBar, 0.2, { Size = UDim2.fromOffset(w, SEARCH_BAR_H) })
else
searchBar.Size = UDim2.fromOffset(w, SEARCH_BAR_H)
end
left.Size = UDim2.new(1, -(rightW + w + 6), 1, 0)
dragZone.Size = UDim2.new(1, -(rightW + w + 18), 1, 0)
end
busy = false
end
hcard:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() applyHeader(false) end)
if leftList then leftList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() applyHeader(false) end) end
applyHeader(false)
task.defer(applyHeader, false)
end
local function setSearchOpen(v)
if searchOpen == v or win._destroyed then return end
searchOpen = v
hit.Visible = not v
win.SearchBox.Visible = v
updateClear()
if win._searchChip then win._searchChip.Visible = v and win.SearchBox.Text == "" end
tween(mag, 0.2, { Position = UDim2.new(0, v and 10 or magX, 0.5, 0) })
tween(magRingStroke, 0.2, { Color = v and T.Accent or T.SubText })
tween(magHandle, 0.2, { BackgroundColor3 = v and T.Accent or T.SubText })
tween(searchBar, 0.2, { BackgroundTransparency = v and 0.35 or win._rest })
tween(searchStroke, 0.2, { Transparency = v and 0.45 or 1 })
if not v then
tween(searchBar, 0.2, { BackgroundColor3 = T.Control })
tween(searchStroke, 0.2, { Color = T.Border, Thickness = 1 })
end
applyHeader(true)
end
hit.MouseEnter:Connect(function()
if searchOpen then return end
tween(searchBar, 0.14, { BackgroundTransparency = 0.4 })
tween(magRingStroke, 0.14, { Color = T.Text })
tween(magHandle, 0.14, { BackgroundColor3 = T.Text })
end)
hit.MouseLeave:Connect(function()
if searchOpen then return end
tween(searchBar, 0.16, { BackgroundTransparency = win._rest })
tween(magRingStroke, 0.16, { Color = T.SubText })
tween(magHandle, 0.16, { BackgroundColor3 = T.SubText })
end)
local hoverSeq = 0
local function mouseOverBar()
local m, p, sz = UserInputService:GetMouseLocation(), searchBar.AbsolutePosition, searchBar.AbsoluteSize
return m.X >= p.X and m.X <= p.X + sz.X and m.Y >= p.Y and m.Y <= p.Y + sz.Y
end
local function hoverFold()
hoverSeq = hoverSeq + 1
local seq = hoverSeq
task.delay(0.35, function()
if seq ~= hoverSeq or not searchOpen or win._destroyed then return end
if win.SearchBox:IsFocused() or win.SearchBox.Text ~= "" or mouseOverBar() then return end
setSearchOpen(false)
end)
end
hit.MouseEnter:Connect(function()
if usingTouch() or Library.SearchHover == false then return end
hoverSeq = hoverSeq + 1
setSearchOpen(true)
end)
searchBar.MouseLeave:Connect(function() if searchOpen then hoverFold() end end)
win.SearchBox.MouseLeave:Connect(function() if searchOpen then hoverFold() end end)
hit.MouseButton1Click:Connect(function()
setSearchOpen(true)
task.defer(function()
if searchOpen and win.SearchBox.Parent then win.SearchBox:CaptureFocus() end
end)
end)
if not false then
local chip = new("TextLabel", {
AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(48, 22),
BackgroundColor3 = T.Panel, BackgroundTransparency = 0.2, Text = "Ctrl K", Font = T.FontBold, TextSize = 14,
TextColor3 = T.SubText, Parent = searchBar,
}, { corner(11), stroke(T.Border, 1, 0.5) })
chip.Visible = false
win._searchChip = chip
win.SearchBox:GetPropertyChangedSignal("Text"):Connect(function() chip.Visible = searchOpen and win.SearchBox.Text == "" end)
end
win._searchQ = false
win.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
if win._searchQ then return end
win._searchQ = true
task.delay(0.08, function()
win._searchQ = false
win:_ApplySearch()
end)
end)
win.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
if win.SearchBox.Text == "" and not win.SearchBox:IsFocused() then setSearchOpen(false) end
end)
win.SearchBox.Focused:Connect(function()
setSearchOpen(true)
tween(searchStroke, 0.18, { Color = T.Accent, Transparency = 0.05, Thickness = 1.5 })
tween(searchBar, 0.18, { BackgroundTransparency = 0.15, BackgroundColor3 = T.Control:Lerp(T.Accent, 0.12) })
end)
win.SearchBox.FocusLost:Connect(function()
if win.SearchBox.Text == "" then setSearchOpen(false) end
if searchOpen then
tween(searchStroke, 0.22, { Color = T.Border, Transparency = 0.45, Thickness = 1 })
tween(searchBar, 0.22, { BackgroundTransparency = 0.35, BackgroundColor3 = T.Control })
end
end)
win.Pages = new("Frame", {
Position = UDim2.fromOffset(0, 6), Size = UDim2.new(1, 0, 1, -6 - 8),
BackgroundTransparency = 1, ClipsDescendants = true, Parent = content,
})
win.PageVeil = new("Frame", {
Name = "PageVeil", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Background, BackgroundTransparency = 1,
BorderSizePixel = 0, ZIndex = 20, Visible = false, Parent = win.Pages,
})
do
local SKIP = { Separator = true, Divider = true }
local function hex(c) return string.format("#%02x%02x%02x", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)) end
local function esc(x) return (tostring(x):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")) end
local resPanel = new("ScrollingFrame", { ElasticBehavior = Enum.ElasticBehavior.Never,
Name = "SearchResults", Position = UDim2.fromOffset(6, 4), Size = UDim2.new(1, -26, 0, 0),
BackgroundColor3 = T.Panel, BackgroundTransparency = 0, BorderSizePixel = 0, ScrollBarThickness = 3,
ScrollBarImageColor3 = T.Accent, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
ClipsDescendants = true, Visible = false, ZIndex = 40, Parent = content,
}, {
corner(12), stroke(T.Accent, 1, 0.3),
new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 8) }),
new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
})
local rows, firstJump = {}, nil
local function clearRows()
for _, r in ipairs(rows) do r:Destroy() end
table.clear(rows)
firstJump = nil
end
local function jump(e)
if e.GoTab then
win.SearchBox.Text = ""
win:_ApplySearch()
win:SetTab(e.GoTab)
else
Library._reveal(win, e)
end
end
local function matchScore(e, toks)
local name, tabn, secn = e.Name:lower(), (e.TabName or ""):lower(), (e.SectionName or ""):lower()
local total = 0
for _, tok in ipairs(toks) do
local a = name:find(tok, 1, true)
if a then
total += (a == 1) and 30 or 20
elseif secn:find(tok, 1, true) then
total += 8
elseif tabn:find(tok, 1, true) then
total += 6
else
return 0
end
end
return total
end
local function addRow(e, order, toks)
local T2 = win.Theme
local row = new("TextButton", {
Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = T2.Control, BackgroundTransparency = 0.1, AutoButtonColor = false,
Text = "", LayoutOrder = order, ZIndex = 41, Parent = resPanel,
}, { corner(9), stroke(T2.Border, 1, 0.4) })
local nm = esc(e.Name)
local lower = e.Name:lower()
for _, tok in ipairs(toks) do
local a, b = lower:find(tok, 1, true)
if a then
nm = esc(e.Name:sub(1, a - 1)) .. '<font color="' .. hex(T2.Accent) .. '"><b>' .. esc(e.Name:sub(a, b)) .. "</b></font>" .. esc(e.Name:sub(b + 1))
break
end
end
local tabObj = e.GoTab or e.Tab
local tabSpec = tabObj and tabObj.Cfg and tabObj.Cfg.Icon
local tabLetter = tostring(tabObj and tabObj.Name or "?")
local badgeSpec, badgeLetter
if e.GoTab then
badgeSpec, badgeLetter = tabSpec, tabLetter
else
local own = e.Cfg and e.Cfg.Icon
badgeSpec = (type(own) == "string" or type(own) == "number") and own or Library.KindIcons[e.Kind] or "lucide:circle"
badgeLetter = tostring(e.Kind)
end
Library._iconBadge(row, badgeSpec, badgeLetter, T2.Accent, 34, 42, T2).Position = UDim2.new(0, 8, 0.5, 0)
local subX = 54
if not e.GoTab then
Library._iconBadge(row, tabSpec, tabLetter, T2.SubText, 14, 42, T2, true).Position = UDim2.fromOffset(54, 34)
subX = 73
end
new("TextLabel", {
Position = UDim2.fromOffset(54, 5), Size = UDim2.new(1, -152, 0, 20), BackgroundTransparency = 1, RichText = true,
Text = nm, Font = T2.FontBold, TextSize = 15, TextColor3 = T2.Text, TextXAlignment = LEFT,
TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 42, Parent = row,
})
local where
if e.GoTab then
where = '<font color="' .. hex(T2.Accent) .. '"><b>' .. esc(e.GoTab.Name) .. "</b></font>  (open tab)"
else
where = '<font color="' .. hex(T2.Accent) .. '"><b>' .. esc(e.TabName or "?") .. "</b></font>  \226\128\186  " .. esc(e.SectionName or "")
end
new("TextLabel", {
Position = UDim2.fromOffset(subX, 26), Size = UDim2.new(1, -(subX + 98), 0, 16), BackgroundTransparency = 1, RichText = true,
Text = where, Font = T2.Font, TextSize = 14, TextColor3 = T2.SubText, TextXAlignment = LEFT,
TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 42, Parent = row,
})
new("TextLabel", {
AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(0, 22),
AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = T2.AccentSoft, BorderSizePixel = 0,
Text = " " .. (e.GoTab and "TAB" or tostring(e.Kind):upper()) .. " ", Font = T2.FontBold, TextSize = 13,
TextColor3 = T2.Text, ZIndex = 42, Parent = row,
}, { corner(7) })
row.MouseEnter:Connect(function() tween(row, 0.12, { BackgroundColor3 = T2.Lift or T2.Control, BackgroundTransparency = 0 }) end)
row.MouseLeave:Connect(function() tween(row, 0.16, { BackgroundColor3 = T2.Control, BackgroundTransparency = 0.1 }) end)
row.MouseButton1Click:Connect(function() jump(e) end)
rows[#rows + 1] = row
if not firstJump then firstJump = e end
end
local lastQ
function win:_ShowResults(q)
if q == lastQ then return end
lastQ = q
clearRows()
if q == "" then
resPanel.Visible = false
return
end
local toks = {}
for tok in q:gmatch("%S+") do toks[#toks + 1] = tok end
local found = {}
for _, tab in ipairs(self.Tabs) do
local sc = matchScore({ Name = tab.Name, TabName = "", SectionName = "" }, toks)
if sc > 0 then found[#found + 1] = { sc = sc + 5, e = { GoTab = tab, Name = tab.Name, Kind = "Tab" } } end
end
for _, e in ipairs(self._index or {}) do
if not SKIP[e.Kind] and not (e.Ctl and e.Ctl.Hidden) and e.Frame and e.Frame.Parent then
local sc = matchScore(e, toks)
if sc > 0 then found[#found + 1] = { sc = sc, e = e } end
end
end
table.sort(found, function(a, b) return a.sc > b.sc end)
local n = math.min(#found, 40)
for i = 1, n do addRow(found[i].e, i, toks) end
if n == 0 then
local none = new("TextLabel", {
Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Text = "No results for \"" .. q .. "\"",
Font = self.Theme.Font, TextSize = 14, TextColor3 = self.Theme.SubText, LayoutOrder = 1, ZIndex = 42, Parent = resPanel,
})
rows[#rows + 1] = none
end
local maxH = math.max(120, content.AbsoluteSize.Y - 20)
local want = (n == 0 and 40 or n * 52) + 12
resPanel.CanvasPosition = Vector2.new(0, 0)
resPanel.Size = UDim2.new(1, -26, 0, math.min(want, maxH, 8 * 52 + 12))
resPanel.Visible = true
end
win.SearchBox.FocusLost:Connect(function(enter)
if enter and firstJump and resPanel.Visible then jump(firstJump) end
end)
end
win.Overlay = new("TextButton", {
Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
Visible = false, ZIndex = 60, Parent = gui,
})
win.Overlay.MouseButton1Click:Connect(function() win:CloseDropdowns() end)
if canResize then
local gripSize = (Library.Mobile or usingTouch()) and 56 or 30
local grip = new("TextButton", {
Name = "ResizeGrip", AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1),
Size = UDim2.fromOffset(gripSize, gripSize), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
Active = true, ZIndex = 30, Parent = main,
})
local GRIP_REST = 0.1
local mark = new("Frame", {
Name = "Mark", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -6, 1, -6), Size = UDim2.fromOffset(20, 20),
BackgroundTransparency = 1, ZIndex = 31, Parent = grip,
})
local ticks = {}
local PIECES = {
{ 10, 10, 19, 2, 45 },
{ 13.75, 17, 7, 2, 0 },
{ 17, 13.75, 2, 7, 0 },
{ 6.25, 3, 7, 2, 0 },
{ 3, 6.25, 2, 7, 0 },
}
for _, pc in ipairs(PIECES) do
ticks[#ticks + 1] = new("Frame", {
AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(pc[1], pc[2]), Size = UDim2.fromOffset(pc[3], pc[4]),
Rotation = pc[5], BackgroundColor3 = T.SubText, BackgroundTransparency = GRIP_REST, BorderSizePixel = 0, ZIndex = 32, Parent = mark,
}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
end
local function tintTicks(c, tr)
for _, t in ipairs(ticks) do tween(t, 0.14, { BackgroundColor3 = c, BackgroundTransparency = tr }) end
end
grip.MouseEnter:Connect(function() if not usingTouch() then tintTicks(T.Accent, 0) end end)
grip.MouseLeave:Connect(function() if not win._resizing then tintTicks(T.SubText, GRIP_REST) end end)
makeResizable(win, grip, 1, 1)
win._resizeFx = {
Start = function()
tintTicks(T.Accent, 0)
if not lowPower() then mainStroke.Color, mainStroke.Transparency = T.Accent, 0.35 end
end,
End = function()
tintTicks(T.SubText, GRIP_REST)
if not lowPower() then mainStroke.Color, mainStroke.Transparency = T.Border, 0.1 end
end,
}
end
local touchUI = false
local BS = cfg.OpenSize or Library._openSize(gui.AbsoluteSize)
win.OpenSize = BS
local function resolveToggleKey()
local k = cfg.ToggleKey
if type(k) == "string" then
local okk, v = pcall(function() return Enum.KeyCode[k] end)
k = okk and v or nil
end
if typeof(k) == "EnumItem" and k.EnumType == Enum.KeyCode then return k end
return Enum.KeyCode.RightShift
end
win._ResolveToggleKey = resolveToggleKey
local toggleKey = resolveToggleKey()
win.OpenBtn = new("TextButton", {
Name = "OpenButton", AnchorPoint = Vector2.new(0.5, 0.5),
Position = cfg.OpenPosition or UDim2.fromScale(0.17, 0.235),
Size = UDim2.fromOffset(BS, BS), BackgroundColor3 = T.Panel, Text = cfg.Logo and "" or brand:sub(1, 2),
Font = Enum.Font.GothamBlack, TextSize = math.max(17, math.floor(BS * 0.38)), TextColor3 = T.Text,
AutoButtonColor = false, Visible = false, Active = true, Parent = gui,
}, { corner(math.floor(BS * 0.3)), stroke(T.Accent, 1.5, 0.2) })
local ob = win.OpenBtn
local obStroke = ob:FindFirstChildOfClass("UIStroke")
local obLogo
if cfg.Logo then
obLogo = new("ImageLabel", {
AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(BS * (cfg.OpenLogoScale or 0.58), BS * (cfg.OpenLogoScale or 0.58)),
BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, ImageColor3 = cfg.LogoColor or Color3.new(1, 1, 1),
Image = (type(cfg.Logo) == "number" or tonumber(cfg.Logo)) and ("rbxassetid://" .. tostring(cfg.Logo)) or cfg.Logo, Parent = ob,
})
end
if not T.Clean then new("UIGradient", { Color = cseq({ 0, T.Panel:Lerp(Color3.new(1, 1, 1), 0.06) }, { 1, T.Panel:Lerp(Color3.new(0, 0, 0), 0.12) }), Rotation = 90, Parent = ob }) end
if obStroke then
obStroke.Thickness = 1.25
new("UIGradient", { Color = cseq({ 0, T.Accent }, { 1, T.Accent2 }), Rotation = 45, Parent = obStroke })
end
win.OpenScale = feedback(ob, ob, "BackgroundColor3", T.Panel, T.Lift, T.AccentSoft, false)
local tip
if not touchUI then
tip = new("TextLabel", {
Name = "Tip", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(1, 10, 0.5, 0), Size = UDim2.fromOffset(0, 28),
AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = T.Panel, BackgroundTransparency = 0.05,
Text = "Open " .. brand .. "  [" .. toggleKey.Name .. "]", Font = T.FontBold, TextSize = 14,
TextColor3 = T.Text, Visible = false, ZIndex = 3, Parent = ob,
}, { corner(8), stroke(T.Border, 1, 0.2), padding(10, 0, 10, 0) })
end
function win:_RefreshToggleTip()
if tip then tip.Text = "Open " .. brand .. "  [" .. resolveToggleKey().Name .. "]" end
end
local function showTip(on)
if not tip then return end
win:_RefreshToggleTip()
if on and not win._openDrag.Dragging then
local vp = gui.AbsoluteSize
local leftSide = ob.AbsolutePosition.X + BS / 2 < vp.X / 2
tip.AnchorPoint = Vector2.new(leftSide and 0 or 1, 0.5)
tip.Position = UDim2.new(leftSide and 1 or 0, leftSide and 10 or -10, 0.5, 0)
tip.Visible = true
else
tip.Visible = false
end
end
local idleSeq, hoverOpen = 0, false
local function wake(on)
local a = on and 0 or 0.5
tween(ob, 0.25, { TextTransparency = a })
if obStroke then tween(obStroke, 0.25, { Transparency = on and 0.3 or 0.7 }) end
if obLogo then tween(obLogo, 0.25, { ImageTransparency = a }) end
if not on then tween(ob, 0.25, { BackgroundTransparency = 0.4 }) else tween(ob, 0.15, { BackgroundTransparency = 0 }) end
end
local function scheduleIdle()
idleSeq += 1
local seq = idleSeq
task.delay(3, function()
if seq == idleSeq and not win._destroyed and ob.Visible and not hoverOpen and not win._openDrag.Dragging then wake(false) end
end)
end
local function awake()
idleSeq += 1
wake(true)
end
ob.MouseEnter:Connect(function()
if usingTouch() or win._openDrag.Dragging then return end
hoverOpen = true
awake()
showTip(true)
end)
ob.MouseLeave:Connect(function()
if win._openDrag.Dragging then return end
hoverOpen = false
showTip(false)
scheduleIdle()
end)
bindPress(ob, function() awake(); showTip(false) end, function() scheduleIdle() end)
ob:GetPropertyChangedSignal("Visible"):Connect(function()
if ob.Visible then
wake(true)
scheduleIdle()
else
showTip(false)
end
end)
win._openDrag.Threshold = touchUI and 6 or 6
win._openDrag.Smooth = true
win._openDrag.FollowRate = touchUI and 10000 or 50
win._openDrag.CatchUp = not touchUI
win._openDrag.Half = BS / 2
win._openDrag.Clamp = function(c)
if touchUI then
local minY = 60 + BS / 2
if c.X - BS / 2 < 110 and c.Y < minY then return Vector2.new(c.X, minY) end
end
return c
end
win._openDrag.OnStart = function()
awake()
showTip(false)
end
win._openDrag.OnEnd = function()
if cfg.OpenSnap and win._openDrag.Moved and win._openDrag.Center then
local vp = gui.AbsoluteSize
local c = win._openDrag.Center
local half, m = BS / 2, 10
local onLeft = c.X < vp.X / 2
local x = onLeft and (half + m) or (vp.X - half - m)
local top = (touchUI and onLeft) and 60 or 8
local y = math.clamp(c.Y, top + half, math.max(top + half, vp.Y - half - m))
win._openDrag.Glide(Vector2.new(x, y))
end
scheduleIdle()
end
makeDraggable(gui, ob, ob, win._openDrag)
ob.MouseButton1Click:Connect(function()
if win._openDrag.Moved then return end
win:SetVisible(true)
end)
table.insert(win.Conns, UserInputService.InputBegan:Connect(function(i)
if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
if Library._listening then return end
if i.KeyCode ~= resolveToggleKey() then return end
if UserInputService:GetFocusedTextBox() then return end
win:SetVisible(not win.Visible)
end))
table.insert(win.Conns, gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() win:_Fit() end))
win:_Fit()
table.insert(win.Conns, UserInputService.WindowFocusReleased:Connect(function()
win._blurred = true
win:_FXPause()
end))
table.insert(win.Conns, UserInputService.WindowFocused:Connect(function()
win._blurred = false
if win.Visible and not win._moving and not win._drag.Dragging then win:_FXResume() end
end))
do
table.insert(win.Conns, main:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() if not win._resizing then win:_QueueFit(0.35) end end))
for _, t in ipairs({ 1.5, 4, 8 }) do
task.delay(t, function() if not win._destroyed then win:_QueueFit(0.1) end end)
end
local rings = 0
local tapGui = new("ScreenGui", {
Name = "SpectreUI_Tap", ResetOnSpawn = false, DisplayOrder = 1000, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
Library._mount(tapGui)
win.TapGui = tapGui
table.insert(win.Conns, UserInputService.InputBegan:Connect(function(i)
local ut = i.UserInputType
if ut ~= Enum.UserInputType.MouseButton1 and ut ~= Enum.UserInputType.Touch then return end
if win._destroyed or not win.Visible or not main.Visible or not gui.Enabled or rings >= 5 or (win._qual or 0) >= 3 then return end
local p = Vector2.new(i.Position.X, i.Position.Y)
local q = p + (tapGui.AbsolutePosition - gui.AbsolutePosition)
local mp, ms = main.AbsolutePosition, main.AbsoluteSize
if q.X < mp.X or q.Y < mp.Y or q.X > mp.X + ms.X or q.Y > mp.Y + ms.Y then return end
rings = rings + 1
local ring = new("Frame", {
Name = "TapRing", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(p.X, p.Y), Size = UDim2.fromOffset(10, 10),
BackgroundTransparency = 1, BorderSizePixel = 0, Active = false, ZIndex = 900, Parent = tapGui,
}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }), new("UIStroke", { Color = (win.Theme or T).Accent, Thickness = 2, Transparency = 0.2 }) })
local info = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
TweenService:Create(ring:FindFirstChildOfClass("UIStroke"), info, { Transparency = 1 }):Play()
local tw = TweenService:Create(ring, info, { Size = UDim2.fromOffset(72, 72) })
tw.Completed:Connect(function() rings = rings - 1; ring:Destroy() end)
tw:Play()
end))
local topBtn = new("TextButton", {
Name = "ToTop", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -20, 1, -2), Size = UDim2.fromOffset(38, 38),
BackgroundColor3 = T.Accent, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Visible = false, ZIndex = 24,
Parent = win.Pages,
}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }), stroke(T.Border, 1, 0.3) })
local legs = {}
for _, d in ipairs({ { -4, -45 }, { 4, 45 } }) do
table.insert(legs, new("Frame", {
AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, d[1], 0.5, 0), Size = UDim2.fromOffset(12, 3), Rotation = d[2],
BackgroundColor3 = Library.OnAccent(T), BorderSizePixel = 0, Active = false, ZIndex = 25, Parent = topBtn,
}, { new("UICorner", { CornerRadius = UDim.new(1, 0) }) }))
end
local shown = false
local function setShown(v)
shown = v
local info = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
if v then
topBtn.Position = UDim2.new(1, -20, 1, 10)
topBtn.Visible = true
TweenService:Create(topBtn, info, { Position = UDim2.new(1, -20, 1, -2), BackgroundTransparency = 0.12 }):Play()
for _, l in ipairs(legs) do TweenService:Create(l, info, { BackgroundTransparency = 0 }):Play() end
else
local tw = TweenService:Create(topBtn, info, { Position = UDim2.new(1, -20, 1, 10), BackgroundTransparency = 1 })
tw.Completed:Connect(function() if not shown then topBtn.Visible = false end end)
tw:Play()
for _, l in ipairs(legs) do TweenService:Create(l, info, { BackgroundTransparency = 1 }):Play() end
end
end
topBtn.MouseButton1Click:Connect(function()
local t = win.Active
if not (t and t.Cols) then return end
for _, c in ipairs(t.Cols) do
TweenService:Create(c, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { CanvasPosition = Vector2.zero }):Play()
end
end)
task.spawn(function()
while not win._destroyed do
task.wait(0.25)
local t = win.Active
local show = false
if win.Visible and t and t.Cols and t.Page and t.Page.Visible then
for _, c in ipairs(t.Cols) do
if c.CanvasPosition.Y > 240 then show = true end
end
end
if show ~= shown then setShown(show) end
if shown then
local th = win.Theme or T
topBtn.BackgroundColor3 = th.Accent
for _, l in ipairs(legs) do l.BackgroundColor3 = Library.OnAccent(th) end
end
end
end)
end
win:_StartGovernor()
table.insert(self.Windows, win)
win:_PlayIntro()
return win
end
function Window:_Fit(animate)
local rvp = self.Gui.AbsoluteSize
if rvp.X <= 0 or rvp.Y <= 0 then return end
local k = Library._autoK(rvp)
self._k = k
if self._kApplied ~= k then
self._kApplied = k
if not self._spinning then self.Scale.Scale = k end
end
local vp = rvp / k
local w, h
local topR, sdR = self:_Top(), self:_Sides()
local top = topR / k
local sd = sdR and { L = sdR.L / k, R = sdR.R / k, B = sdR.B / k } or nil
if self.Maximized then
local ms = self:_MaxM()
local mL, mR, mB = sd and sd.L or ms, sd and sd.R or ms, sd and sd.B or ms
w, h = math.max(vp.X - mL - mR, 200), math.max(vp.Y - top - mB, 160)
else
local touch = false
local edge = touch and 20 or 8
local eL, eR, eB = sd and sd.L or edge, sd and sd.R or edge, sd and sd.B or edge
local topPad = math.max(edge, top)
local sized = self._userSized == true
if sized then eL, eR, eB, topPad = 8, 8, 8, 8 end
local fw = math.min(self.Cfg.MinWidth or 520, vp.X - eL - eR)
local fh = math.min(self.Cfg.MinHeight or 280, vp.Y - topPad - eB)
local autoW = touch and vp.X * 0.69 or math.clamp(vp.X * 0.62, 980, 1280)
local autoH = touch and vp.Y * 0.95 or math.clamp(vp.Y * 0.72, 640, 820)
if not sized then
eL, eR, eB = math.max(eL, 14), math.max(eR, 14), math.max(eB, 14)
topPad = math.max(topPad, 14)
autoW, autoH = vp.X * 0.8, vp.Y * 0.86
fw = math.min(self.Cfg.MinWidth or 520, vp.X - eL - eR)
fh = math.min(self.Cfg.MinHeight or 240, vp.Y - topPad - eB)
end
if touch and not sized and self.Cfg.TopMargin == nil and (self.Cfg.Width or autoW) <= vp.X * 0.72 then
top = math.min(top, 12)
topPad = math.max(edge, top)
fh = math.min(self.Cfg.MinHeight or 280, vp.Y - topPad - eB)
end
w = math.max(math.min(self.Cfg.Width or autoW, vp.X - eL - eR), fw)
h = math.max(math.min(self.Cfg.Height or autoH, vp.Y - topPad - eB), fh)
if touch and not sized then
w = math.max(math.min(w, vp.X * 0.86), fw)
h = math.max(math.min(h, vp.Y * 0.96), fh)
end
if touch and not sized and not self.Cfg.Width then
w = math.max(vp.X < vp.Y and (vp.X - 20) or math.min(vp.X * 0.92, 960, vp.X - eL - eR), fw)
end
if touch and not sized and not self.Cfg.Height then
h = math.max(vp.Y - topPad - 10, fh)
end
end
if self._shaded then h = HEADER_H end
local anim = animate and not lowPower()
if anim then
self:_MotionBegin(0.3)
tween(self.Main, 0.3, { Size = UDim2.fromOffset(w, h) })
else
self.Main.Size = UDim2.fromOffset(w, h)
end
if self._forceCompact == nil and Library.Mobile and self.Cfg.Compact == true then self._forceCompact = true end
local compact = self._forceCompact == true or (not Library.Mobile and w < (self.Compact and 590 or 560))
local sw = compact and 66 or (192)
self.Sidebar.Size = UDim2.new(0, sw, 1, 0)
self.Content.Position = UDim2.fromOffset(sw, 0)
self.Content.Size = UDim2.new(1, -sw, 1, 0)
local twoCol = ((w - sw) >= (self.TwoCol and 500 or 540) or Library.Mobile == true) and self.Cfg.TwoColumn ~= false
if compact ~= self.Compact then
self.Compact = compact
self.Footer.Visible = true
if self.CloseProfile then self:CloseProfile() end
if self.FooterAvatar then
self.FooterAvatar.AnchorPoint = compact and Vector2.new(0.5, 0) or Vector2.zero
self.FooterAvatar.Position = compact and UDim2.new(0.5, -3, 0, 10) or UDim2.fromOffset(0, 10)
end
for _, f in ipairs({ self.FooterBrand, self.FooterSub, self.FooterArrow }) do
if f then f.Visible = not compact end
end
local ox, ow = compact and 5 or 10, compact and -10 or -19
self.SidePanel.Position = UDim2.fromOffset(ox, 0)
self.SidePanel.Size = UDim2.new(1, ow, 1, -10)
self.TabList.Position = UDim2.fromOffset(ox, 0)
self.TabList.Size = UDim2.new(1, ow, 1, -FOOT_H - 16)
self.Footer.Position = UDim2.new(0, ox + 4, 1, -FOOT_H - 16)
self.Footer.Size = UDim2.new(1, ow - 8, 0, FOOT_H)
if self.BrandLabel then self.BrandLabel.Visible = not compact end
if self.SubLabel then self.SubLabel.Visible = not compact; self.SubSep.Visible = not compact end
for _, t in ipairs(self.Tabs) do t:_ApplyCompact(compact) end
end
if twoCol ~= self.TwoCol then
self.TwoCol = twoCol
for _, t in ipairs(self.Tabs) do t:_QueueRelayout() end
end
vp, top, sd = rvp, topR, sdR
local rel = self:_Rel()
if rel then
local free = sd ~= nil and self._drag.Rel ~= nil and not self.Maximized
local c = clampCenter(vp, Vector2.new(w, h) * k / 2, Vector2.new(rel.X * vp.X, rel.Y * vp.Y), top, sd, free)
if anim then
tween(self.Main, 0.3, { Position = UDim2.fromOffset(c.X, c.Y) })
else
self.Main.Position = UDim2.fromOffset(c.X, c.Y)
end
end
local orel = self._openDrag.Rel
if orel and not self._openDrag.Dragging then
local hb = (self.OpenSize or 42) / 2
local c = clampCenter(vp, Vector2.new(hb, hb), Vector2.new(orel.X * vp.X, orel.Y * vp.Y))
self.OpenBtn.Position = UDim2.fromOffset(c.X, c.Y)
end
if self._nm then self._nm:_RefitSoon() end
end
function Window:CloseDropdowns()
if self._dd then self._dd:Close() end
end
function Window:_ShowOverlay(dim)
local ov = self.Overlay
self._ovTok = (self._ovTok or 0) + 1
if not ov.Visible then ov.BackgroundTransparency = 1 end
ov.BackgroundColor3 = Color3.new(0, 0, 0)
ov.Visible = true
tween(ov, 0.2, { BackgroundTransparency = dim or 1 }, QUAD, OUT)
end
function Window:_HideOverlay()
local ov = self.Overlay
if not ov.Visible then return end
self._ovTok = (self._ovTok or 0) + 1
local tok = self._ovTok
tween(ov, 0.14, { BackgroundTransparency = 1 }, QUAD, IN).Completed:Connect(function()
if self._ovTok == tok then ov.Visible = false end
end)
end
local SLIDE = 8
function Window:_MaxM()
local cfg = self.Cfg or {}
local m = tonumber(Library.MaxMargin) or (12)
local sm = type(cfg.SideMargin) == "number" and math.max(cfg.SideMargin, 0) or m
local tm = type(cfg.TopMargin) == "number" and math.max(cfg.TopMargin, 0) or m
return sm, math.max(tm, 6)
end
function Window:_Top()
if self.Maximized then local _, tm = self:_MaxM() return tm end
local vp = self.Gui.AbsoluteSize
local t = Library._topSafe(self.Cfg, vp)
if t > 0 and self.Cfg.TopMargin == nil and self.Main and not self.Maximized and not self._userSized then
local w = self.Main.Size.X.Offset * (self._k or 1)
if vp.X > 0 and w > 0 and w <= vp.X * 0.72 then t = math.min(t, 12) end
end
return t
end
function Window:_Sides()
if self.Maximized and false then local sm = self:_MaxM() return { L = sm, R = sm, B = sm } end
return Library._sideSafe(self.Cfg, self.Gui.AbsoluteSize)
end
function Window:_Rel()
if self.Maximized then return Vector2.new(0.5, 0.5) end
local r = self._drag.Rel
if not r and self:_Top() > 0 then r = Vector2.new(0.5, 0.5) end
return r
end
function Window:_UpdateFades()
local T = self.Theme
local col = T.Top:Lerp(T.Background, 0.15)
for _, t in ipairs(self.Tabs) do
if t.Fades then for _, f in ipairs(t.Fades) do f.BackgroundColor3 = col end end
end
end
function Window:_HomePos()
local vp = self.Gui.AbsoluteSize
if vp.X <= 0 or vp.Y <= 0 then return nil end
local rel = self:_Rel()
if not rel then return nil end
local half = self.Main.AbsoluteSize / math.max(self.Scale.Scale, 0.01) * (self._k or 1) / 2
local sd = self:_Sides()
local c = clampCenter(vp, half, Vector2.new(rel.X * vp.X, rel.Y * vp.Y), self:_Top(), sd, sd ~= nil and self._drag.Rel ~= nil and not self.Maximized)
return UDim2.fromOffset(math.round(c.X), math.round(c.Y))
end
function Window:_AnimBase()
local home = self:_HomePos()
if home then
self._animBase = home
return home
end
if not self._animBase then self._animBase = self.Main.Position end
return self._animBase
end
function Window:_AnimDone()
local home = self:_HomePos() or self._animBase
if home then self.Main.Position = home end
self._animBase = nil
if not self._spinning then self.Scale.Scale = self._k or 1 end
end
function Window:_SpinPrep()
if Library.Anim.Spin == false or self.Cfg.Spin == false then return nil end
if (self._qual or 0) >= 2 then return nil end
self._spinSeq = (self._spinSeq or 0) + 1
self._spinning = true
self.Main.Rotation = -360
if self:_SpinZoom() then self.Scale.Scale = 0.5 * (self._k or 1) end
local fxl = self.Main:FindFirstChild("FX")
if fxl then fxl.Visible = false end
return self._spinSeq
end
function Window:_SpinZoom()
return Library.Anim.SpinZoom == true and not lowPower()
end
function Window:_SpinShowFX()
local fxl = self.Main:FindFirstChild("FX")
if fxl then fxl.Visible = true end
end
function Window:_SpinEnd()
self._spinning = false
self.Main.Rotation = 0
self.Scale.Scale = self._k or 1
local fxl = self.Main:FindFirstChild("FX")
if fxl then fxl.Visible = true end
end
function Window:_SpinGo(tok)
if not tok then return end
if self._spinSeq ~= tok or self._destroyed then return end
tween(self.Main, 0.7, { Rotation = 0 }, QUINT, OUT).Completed:Connect(function(st)
if self._spinSeq ~= tok or st ~= Enum.PlaybackState.Completed then return end
self:_SpinEnd()
end)
if self:_SpinZoom() then tween(self.Scale, 0.7, { Scale = self._k or 1 }, QUINT, OUT) end
end
function Window:_PlayOpen(fresh)
self._vseq = (self._vseq or 0) + 1
local seq = self._vseq
local veil = self.Veil
local pop = Library.Anim.Pop == true and not lowPower()
local base = self:_AnimBase()
local spin = fresh and self:_SpinPrep() or nil
self:_MotionBegin(spin and 1.0 or 0.5)
if fresh then
self.Main.Position = base + UDim2.fromOffset(0, SLIDE)
if pop and not spin then self.Scale.Scale = 0.92 * (self._k or 1) end
veil.BackgroundTransparency = 0
end
veil.Visible = true
local function run()
if self._vseq ~= seq or self._destroyed then return end
if spin then self:_SpinGo(spin) elseif pop then tween(self.Scale, 0.42, { Scale = self._k or 1 }, QUINT, OUT) end
tween(self.Main, 0.3, { Position = base }, QUINT, OUT)
local function fade()
if self._vseq ~= seq or self._destroyed then return end
if spin then self:_SpinShowFX() end
tween(veil, 0.22, { BackgroundTransparency = 1 }, SINE, OUT).Completed:Connect(function(st)
if self._vseq ~= seq or st ~= Enum.PlaybackState.Completed then return end
veil.Visible = false
self:_AnimDone()
end)
end
if spin then task.delay(0.55, fade) else fade() end
end
if fresh then nextFrame(run) else run() end
end
function Window:_PlayIntro()
if Library._holdIntro then
self._introHeld = true
self.Gui.Enabled = false
return
end
if self.Cfg.Intro == false or Library.Anim.Intro == false then
return self:_PlayOpen(true)
end
self._vseq = (self._vseq or 0) + 1
local seq = self._vseq
local veil, main = self.Veil, self.Main
local base = self:_AnimBase()
self._introT = os.clock()
local spin = self:_SpinPrep()
self:_MotionBegin(1.1)
main.Position = base + UDim2.fromOffset(0, 12)
veil.BackgroundTransparency = 0
veil.Visible = true
nextFrame(function()
if self._vseq ~= seq or self._destroyed then return end
tween(main, 0.45, { Position = base }, QUINT, OUT)
self:_SpinGo(spin)
task.delay(spin and 0.5 or 0, function()
if self._vseq ~= seq or self._destroyed then return end
if spin then self:_SpinShowFX() end
tween(veil, 0.4, { BackgroundTransparency = 1 }, SINE, OUT).Completed:Connect(function(st)
if self._vseq ~= seq or st ~= Enum.PlaybackState.Completed then return end
veil.Visible = false
self:_AnimDone()
end)
end)
end)
end
function Window:_IntroTab(tab)
local t0 = self._introT
if not t0 or os.clock() - t0 > 2 then return end
local order = #self.Tabs
local label, scale = tab.Label, tab.IconScale
label.TextTransparency = 1
if scale then
scale.Scale = 0
tween(scale, 0.05, { Scale = 0 })
end
task.delay(0.2 + (order - 1) * 0.035, function()
if self._destroyed or not label.Parent then return end
tween(label, 0.25, { TextTransparency = 0 }, SINE, OUT)
if scale then tween(scale, 0.3, { Scale = 1 }, QUINT, OUT) end
end)
if order == 1 then
local page, pv = tab.Page, self.PageVeil
local pseq = self._pseq or 0
page.Position = UDim2.fromOffset(0, 8)
pv.BackgroundTransparency = 0
pv.Visible = true
task.delay(0.2, function()
if self._destroyed or (self._pseq or 0) ~= pseq then return end
tween(page, 0.4, { Position = UDim2.new() }, QUINT, OUT)
tween(pv, 0.35, { BackgroundTransparency = 1 }, SINE, OUT).Completed:Connect(function()
if (self._pseq or 0) == pseq then pv.Visible = false end
end)
end)
end
end
function Window:_PlayClose()
self._vseq = (self._vseq or 0) + 1
local seq = self._vseq
local veil = self.Veil
local pop = Library.Anim.Pop == true and not lowPower()
local base = self:_AnimBase()
if self._spinning then
self._spinSeq = (self._spinSeq or 0) + 1
self:_SpinEnd()
end
self:_MotionBegin(0.3)
if not veil.Visible then
veil.BackgroundTransparency = 1
veil.Visible = true
end
if pop then tween(self.Scale, 0.22, { Scale = 0.94 * (self._k or 1) }, QUAD, IN) end
tween(self.Main, 0.22, { Position = base + UDim2.fromOffset(0, SLIDE) }, QUAD, IN)
tween(veil, 0.22, { BackgroundTransparency = 0 }, QUAD, OUT).Completed:Connect(function()
if self._vseq ~= seq or self.Visible then return end
veil.Visible = false
self.Main.Visible = false
self:_AnimDone()
self:_FXPause()
self:_GlowVisible(false)
if self:_OpenBtnAllowed() then self.OpenBtn.Visible = true end
self.OpenScale.Scale = 0.85
tween(self.OpenScale, 0.25, { Scale = 1 }, QUINT, OUT)
end)
end
function Window:_OpenBtnAllowed()
return not (self.Cfg.HideOpenButtonOnPC == true and not false)
end
function Window:SetHideOpenButtonOnPC(v)
self.Cfg.HideOpenButtonOnPC = v and true or false
if not self.Visible and self.OpenBtn and not self.Main.Visible then
self.OpenBtn.Visible = self:_OpenBtnAllowed()
end
end
function Window:SetVisible(v)
if self.Visible == v then return end
self.Visible = v
self:CloseDropdowns()
self._drag.Stop()
if v then
local fresh = not self.Main.Visible
self._openDrag.Stop()
self.OpenBtn.Visible = false
self.Main.Visible = true
self:_PlayOpen(fresh)
if fresh and self._BrandIntro then self:_BrandIntro() end
else
self:_PlayClose()
end
end
function Window:Toggle() self:SetVisible(not self.Visible) end
function Window:_SetMaxFlag(v)
self.Maximized = v and true or false
if self._setMaxIcon then self._setMaxIcon(self.Maximized) end
end
function Window:SetShaded(v)
v = v and true or false
if (self._shaded or false) == v or self.Maximized then return end
self:CloseDropdowns()
self._drag.Stop()
self._shaded = v
if self.Body then self.Body.Visible = not v end
local grip = self.Main:FindFirstChild("ResizeGrip", true)
if grip then grip.Visible = not v end
self:_FitVeiled()
end
function Window:SetMaximized(v)
v = v and true or false
if self.Maximized == v then return end
if v and self._shaded then self:SetShaded(false) end
self:CloseDropdowns()
self._drag.Stop()
if v then
self._restore = { W = self.Cfg.Width, H = self.Cfg.Height, Rel = self._drag.Rel }
local msz = self.Main.Size
local sz = Vector2.new(msz.X.Offset, msz.Y.Offset)
if not self.Cfg.Width then self.Cfg.Width, self._restore.W = sz.X, sz.X end
if not self.Cfg.Height then self.Cfg.Height, self._restore.H = sz.Y, sz.Y end
else
local r = self._restore or {}
self.Cfg.Width, self.Cfg.Height = r.W, r.H
self._drag.Rel = r.Rel or Vector2.new(0.5, 0.5)
end
self:_SetMaxFlag(v)
self:_FitVeiled()
safe(self.Cfg.OnMaximize, v)
end
function Window:_FitVeiled()
if lowPower() or not self.Main.Visible or not self.Veil then
return self:_Fit(false)
end
self._vseq = (self._vseq or 0) + 1
local seq = self._vseq
local veil = self.Veil
self:_MotionBegin(0.6)
if not veil.Visible then veil.BackgroundTransparency = 1 end
veil.Visible = true
tween(veil, 0.1, { BackgroundTransparency = 0 }, SINE, IN).Completed:Connect(function()
if self._vseq ~= seq or self._destroyed then return end
self:_Fit(false)
task.delay(0.08, function()
if self._vseq ~= seq or self._destroyed then return end
tween(veil, 0.2, { BackgroundTransparency = 1 }, SINE, OUT).Completed:Connect(function(st)
if self._vseq ~= seq or st ~= Enum.PlaybackState.Completed then return end
veil.Visible = false
end)
end)
end)
end
function Window:IsMaximized() return self.Maximized end
function Window:Resize(w, h)
self:_SetMaxFlag(false)
self:SetSize(w, h)
end
function Library._profFmtTime(sec)
sec = math.max(0, math.floor(sec))
local h, m, x = sec // 3600, (sec % 3600) // 60, sec % 60
if h > 0 then return ("%d:%02d:%02d"):format(h, m, x) end
return ("%02d:%02d"):format(m, x)
end
function Window:_BuildProfile()
local win, T = self, self.Theme
local lpl = Players.LocalPlayer
if not lpl then return end
local Market = game:GetService("MarketplaceService")
local Stats = game:GetService("Stats")
local main = self.Main
local CARD_W = 288
local RIGHT = Enum.TextXAlignment.Right
local TRUNC = Enum.TextTruncate.AtEnd
local baseY = -(FOOT_H + 22)
local blocker = new("TextButton", {
Name = "ProfileBlocker", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
Visible = false, ZIndex = 54, Parent = main,
})
local card = new("Frame", {
Name = "ProfileCard", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, baseY),
Size = UDim2.fromOffset(CARD_W, 300), BackgroundColor3 = T.Panel, BackgroundTransparency = 0.02, BorderSizePixel = 0,
Visible = false, ZIndex = 56, ClipsDescendants = true, Parent = main,
}, { corner(18), stroke(T.Accent, 1, 0.45) })
local scroll = new("ScrollingFrame", { ElasticBehavior = Enum.ElasticBehavior.Never,
Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
CanvasSize = UDim2.new(), AutomaticCanvasSize = AY, ScrollingDirection = Enum.ScrollingDirection.Y, Parent = card,
}, { list(8), padding(12, 12, 12, 12) })
local lay = scroll:FindFirstChildOfClass("UIListLayout")
local order = 0
local function nextOrder() order += 1 return order end
local function copy(text)
if type(setclipboard) == "function" then
pcall(setclipboard, text)
win:Notify({ Title = "Copied", Content = text, Kind = "Success", Duration = 1.6 })
else
win:Notify({ Title = "Clipboard not supported", Content = text, Kind = "Warning", Duration = 3 })
end
end
local function label(props)
props.BackgroundTransparency = 1
props.Font = props.Font or T.Font
props.TextSize = props.TextSize or 12
props.TextColor3 = props.TextColor3 or T.Text
props.TextXAlignment = props.TextXAlignment or LEFT
props.TextTruncate = props.TextTruncate or TRUNC
return new("TextLabel", props)
end
local function divider()
new("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.Border, BackgroundTransparency = 0.6, BorderSizePixel = 0, LayoutOrder = nextOrder(), Parent = scroll })
end
local function caption(text)
label({ Size = UDim2.new(1, 0, 0, 16), Text = text, Font = T.FontBold, TextSize = 13, TextColor3 = T.SubText, LayoutOrder = nextOrder(), Parent = scroll })
end
local head = new("Frame", { Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, LayoutOrder = nextOrder(), Parent = scroll })
local av = new("ImageLabel", {
Size = UDim2.fromOffset(52, 52), BackgroundColor3 = T.Control, BorderSizePixel = 0, Image = "", ScaleType = Enum.ScaleType.Crop, Parent = head,
}, { corner(26), stroke(T.Accent, 2, 0.2) })
label({ Position = UDim2.fromOffset(62, 6), Size = UDim2.new(1, -62, 0, 22), Text = lpl.DisplayName, Font = T.FontBold, TextSize = 17, Parent = head })
label({ Position = UDim2.fromOffset(62, 29), Size = UDim2.new(1, -62, 0, 16), Text = "@" .. lpl.Name, TextColor3 = T.SubText, Parent = head })
task.spawn(function()
local ok, img = pcall(function()
return Players:GetUserThumbnailAsync(lpl.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
end)
if ok and img and av.Parent then av.Image = img end
end)
divider()
caption("CURRENT GAME")
local gcard = new("Frame", {
Size = UDim2.new(1, 0, 0, 60), BackgroundColor3 = T.Control, BackgroundTransparency = 0.45, BorderSizePixel = 0,
LayoutOrder = nextOrder(), Parent = scroll,
}, { corner(12), stroke(T.Border, 1, 0.6) })
local gicon = new("ImageLabel", {
Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(44, 44), BackgroundColor3 = T.Panel, BorderSizePixel = 0,
Image = (game.GameId ~= 0) and ("rbxthumb://type=GameIcon&id=" .. game.GameId .. "&w=150&h=150") or "",
ScaleType = Enum.ScaleType.Crop, Parent = gcard,
}, { corner(10) })
local gname = label({
Position = UDim2.fromOffset(60, 8), Size = UDim2.new(1, -68, 0, 30), Text = game.Name, Font = T.FontBold, TextSize = 14,
TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Parent = gcard,
})
local gsub = label({ Position = UDim2.fromOffset(60, 38), Size = UDim2.new(1, -68, 0, 14), Text = "", TextSize = 14, TextColor3 = T.SubText, Parent = gcard })
local function applyInfo(info)
if not info then return end
if info.Name and info.Name ~= "" and gname.Parent then gname.Text = info.Name end
if info.IconImageAssetId and info.IconImageAssetId ~= 0 and gicon.Parent then gicon.Image = "rbxassetid://" .. info.IconImageAssetId end
if info.Creator and info.Creator.Name and gsub.Parent then gsub.Text = "by " .. tostring(info.Creator.Name) end
end
if Library._placeInfo then
applyInfo(Library._placeInfo)
else
task.spawn(function()
local ok, info = pcall(function() return Market:GetProductInfo(game.PlaceId) end)
if ok and type(info) == "table" then Library._placeInfo = info applyInfo(info) end
end)
end
divider()
local stats = new("Frame", {
Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, LayoutOrder = nextOrder(), Parent = scroll,
}, { list(2) })
local vals, getters, srow = {}, {}, 0
local function row(key, title, get, copyGet)
srow += 1
local r = new("TextButton", {
Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = srow, Parent = stats,
})
label({ Size = UDim2.new(0.4, 0, 1, 0), Text = title, TextColor3 = T.SubText, Parent = r })
vals[key] = label({ Position = UDim2.fromScale(0.4, 0), Size = UDim2.fromScale(0.6, 1), Text = "-", TextXAlignment = RIGHT, Font = T.FontBold, Parent = r })
getters[key] = get
if copyGet then
r.MouseButton1Click:Connect(function()
local okc, t = pcall(copyGet)
if okc and t and t ~= "" then copy(tostring(t)) end
end)
end
end
local fps = 0
local jobId = game.JobId
row("players", "Players", function() return ("%d / %d"):format(#Players:GetPlayers(), Players.MaxPlayers) end)
row("ping", "Ping", function()
local okp, v = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
return okp and (math.floor(v + 0.5) .. " ms") or "-"
end)
row("fps", "FPS", function() return tostring(fps) end)
row("time", "In server", function() return Library._profFmtTime(workspace.DistributedGameTime) end)
row("job", "Server ID (tap to copy)", function() return jobId ~= "" and (jobId:sub(1, 8) .. "...") or "Studio" end, function() return jobId end)
row("place", "Place ID (tap to copy)", function() return tostring(game.PlaceId) end, function() return tostring(game.PlaceId) end)
row("uid", "User ID (tap to copy)", function() return tostring(lpl.UserId) end, function() return tostring(lpl.UserId) end)
row("age", "Account age", function()
local d = lpl.AccountAge
return ("%dy %dm"):format(d // 365, (d % 365) // 30)
end)
if type(identifyexecutor) == "function" then
row("exec", "Executor", function()
local okx, n = pcall(identifyexecutor)
return okx and tostring(n) or "-"
end)
end
local function refresh()
for k, get in pairs(getters) do
local okg, v = pcall(get)
if okg and vals[k] and vals[k].Parent then vals[k].Text = tostring(v) end
end
end
divider()
local brow = new("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, LayoutOrder = nextOrder(), Parent = scroll })
local function button(text, x, cb)
local b = new("TextButton", {
Position = UDim2.new(x, x > 0 and 3 or 0, 0, 0), Size = UDim2.new(0.5, -3, 1, 0), BackgroundColor3 = T.Control,
BackgroundTransparency = 0.35, Text = text, Font = T.FontBold, TextSize = 13, TextColor3 = T.Text, AutoButtonColor = false,
BorderSizePixel = 0, Parent = brow,
}, { corner(10), stroke(T.Accent, 1, 0.6) })
feedback(b, b, "BackgroundTransparency", 0.35, 0.2, 0.1, true)
b.MouseButton1Click:Connect(cb)
end
button("Copy join link", 0, function()
copy(("roblox://experiences/start?placeId=%d&gameInstanceId=%s"):format(game.PlaceId, jobId))
end)
button("Rejoin", 0.5, function()
win:Notify({ Title = "Rejoining", Content = "Teleporting back to this server...", Kind = "Info", Duration = 2 })
local TS = game:GetService("TeleportService")
pcall(function()
if jobId ~= "" then TS:TeleportToPlaceInstance(game.PlaceId, jobId, lpl) else TS:Teleport(game.PlaceId, lpl) end
end)
end)
local isOpen, fpsConn = false, nil
function win:CloseProfile()
if not isOpen then return end
isOpen = false
if fpsConn then fpsConn:Disconnect() fpsConn = nil end
blocker.Visible = false
card.Visible = false
if self.FooterArrow then self.FooterArrow.Rotation = 0 end
end
function win:OpenProfile()
if isOpen or self._destroyed then return end
isOpen = true
refresh()
local avail = (main.AbsoluteSize.Y / math.max(self.Scale.Scale, 0.01)) - (FOOT_H + 22) - (HEADER_H + 8)
local h = math.clamp(lay.AbsoluteContentSize.Y + 24, 140, math.max(avail, 140))
card.Size = UDim2.fromOffset(CARD_W, h)
scroll.CanvasPosition = Vector2.zero
card.Position = UDim2.new(0, 12, 1, baseY + 10)
blocker.Visible = true
card.Visible = true
nextFrame(function() if isOpen then tween(card, 0.22, { Position = UDim2.new(0, 12, 1, baseY) }) end end)
if self.FooterArrow then tween(self.FooterArrow, 0.2, { Rotation = 180 }) end
local frames, last = 0, os.clock()
fpsConn = RunService.RenderStepped:Connect(function()
frames += 1
local now = os.clock()
if now - last >= 0.5 then fps = math.floor(frames / (now - last) + 0.5) frames, last = 0, now end
end)
task.spawn(function()
while isOpen and not self._destroyed do
task.wait(0.5)
if isOpen then refresh() end
end
if fpsConn then fpsConn:Disconnect() fpsConn = nil end
end)
end
function win:ToggleProfile()
if isOpen then self:CloseProfile() else self:OpenProfile() end
end
blocker.MouseButton1Click:Connect(function() win:CloseProfile() end)
if win.ProfileButton then win.ProfileButton.MouseButton1Click:Connect(function() win:ToggleProfile() end) end
end
function Window:SetTitle(title, sub)
if sub == nil and type(title) == "string" then
local b, s = title:match("^(.-)%s*|%s*(.+)$")
if b then title, sub = b, s end
end
if title ~= nil then
self.Brand = title
self.BrandLabel.Text = title
end
if sub ~= nil then
self.Sub = sub
if self.SubLabel then self.SubLabel.Text = sub end
end
end
function Window:GetTab(name)
for _, t in ipairs(self.Tabs) do
if t.Name == name then return t end
end
end
function Window:SetTab(nameOrTab)
local t = type(nameOrTab) == "string" and self:GetTab(nameOrTab) or nameOrTab
if t then self:SelectTab(t) end
return t
end
function Window:SetSize(w, h)
self.Cfg.Width = w
self.Cfg.Height = h
self:_Fit()
end
function Window:Center()
local vp = self.Gui.AbsoluteSize
local y = vp.Y / 2 + math.max(self:_Top() - 8, 0) / 2
self.Main.Position = UDim2.fromOffset(vp.X / 2, y)
self._drag.Rel = Vector2.new(0.5, vp.Y > 0 and y / vp.Y or 0.5)
end
function Window:Flash(color)
local s = self.Main:FindFirstChildOfClass("UIStroke")
if not s then return end
color = color or self.Theme.Accent
local seq = (self._fseq or 0) + 1
self._fseq = seq
s.Color = color
tween(s, 0.18, { Transparency = 0 })
task.delay(0.5, function()
if self._fseq ~= seq then return end
tween(s, 0.6, { Color = self.Theme.Border, Transparency = 0.1 })
end)
end
function Window:Destroy()
self._destroyed = true
if self._nm then pcall(function() self._nm:Destroy() end) end
pcall(function() self._drag.Stop() end)
pcall(function() self._openDrag.Stop() end)
if self.FX then for _, tw in ipairs(self.FX.Tweens) do pcall(function() tw:Cancel() end) end end
if self._sheen then pcall(function() self._sheen:Cancel() end) end
for _, c in ipairs(self.Conns) do pcall(function() c:Disconnect() end) end
pcall(function() self.Gui:Destroy() end)
if self.TapGui then pcall(function() self.TapGui:Destroy() end) end
for i, w in ipairs(Library.Windows) do
if w == self then table.remove(Library.Windows, i) break end
end
end
function Window:_ApplySearch(fromSelect)
local tab = self.Active
if not tab then return end
local q = self.SearchBox.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
if self._ShowResults then self:_ShowResults(q) end
q = ""
if fromSelect and q == "" and tab._clean then return end
for _, t in ipairs(self.Tabs) do t._clean = false end
for _, s in ipairs(tab.Sections) do
local secMatch = q == "" or s.Name:lower():find(q, 1, true) ~= nil
local any = false
for _, c in ipairs(s.Controls) do
local vis = (secMatch or c.Name:find(q, 1, true) ~= nil) and not c.Hidden
if c.Frame.Visible ~= vis then c.Frame.Visible = vis end
any = any or vis
end
local secVis = secMatch or any
if s.Frame.Visible ~= secVis then s.Frame.Visible = secVis end
end
tab._clean = (q == "")
tab:_QueueRelayout()
end
function Window:SelectTab(tab)
if tab and tab._locked then
self:_LockedFeedback(tab)
return
end
if self.Active == tab then return end
local T = self.Theme
self:CloseDropdowns()
local prev = self.Active
local dir = 1
if prev then
dir = ((table.find(self.Tabs, tab) or 0) > (table.find(self.Tabs, prev) or 0)) and 1 or -1
prev.Page.Visible = false
prev:_SetSelected(false)
end
self.Active = tab
tab.Page.Visible = true
tab:_SetSelected(true)
self:_ApplySearch(true)
tab:_QueueRelayout()
if prev and Library.Anim.TabSwitch ~= false then
local lite = lowPower()
self._pseq = (self._pseq or 0) + 1
local seq = self._pseq
local pv = self.PageVeil
local useVeil = Library.Anim.PageVeil == true
if self._veilTw then pcall(function() self._veilTw:Cancel() end) self._veilTw = nil end
pv.BackgroundTransparency = useVeil and (Library.Anim.PageVeilAlpha or 0.6) or 1
pv.Visible = useVeil
if useVeil then
task.delay(0.8, function()
if self._pseq == seq and pv.Parent then pv.Visible = false pv.BackgroundTransparency = 1 end
end)
end
self:_MotionBegin(0.34, true)
tab.Page.Position = UDim2.fromOffset(0, 14 * dir)
nextFrame(function()
if self._pseq ~= seq or self._destroyed then
if self.Active ~= tab and tab.Page.Parent then tab.Page.Position = UDim2.new() end
if not useVeil then pv.Visible = false end
return
end
tween(tab.Page, 0.34, { Position = UDim2.new() }, QUINT, OUT)
if useVeil then
self._veilTw = tween(pv, 0.26, { BackgroundTransparency = 1 }, SINE, OUT)
self._veilTw.Completed:Connect(function()
if self._pseq == seq then pv.Visible = false end
end)
end
if lite or Library.Anim.TabSweep ~= true then return end
local sweep = new("Frame", {
Size = UDim2.new(0, 0, 0, 2), Position = UDim2.fromOffset(0, 0), BackgroundColor3 = Color3.new(1, 1, 1),
BorderSizePixel = 0, ZIndex = 21, Parent = tab.Page,
}, { gradient(cseq({ 0, Color3.new(1, 1, 1) }, { 0.5, T.Accent2 }, { 1, Color3.new(1, 1, 1) }), 0) })
sweep:FindFirstChildOfClass("UIGradient").Transparency = NumberSequence.new({
NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 0.4),
})
tween(sweep, 0.4, { Size = UDim2.new(1, 0, 0, 2) }, QUAD, OUT).Completed:Connect(function()
tween(sweep, 0.25, { BackgroundTransparency = 1 }, QUAD, IN).Completed:Connect(function() sweep:Destroy() end)
end)
end)
end
end
local Workspace = game:GetService("Workspace")
local Util = {}
Library.Util = Util
Util.Create = new
function Util.Dispose(x)
local t = typeof(x)
if t == "RBXScriptConnection" then
x:Disconnect()
elseif t == "Instance" then
if x:IsA("TweenBase") then pcall(function() x:Cancel() end) end
x:Destroy()
elseif t == "thread" then
pcall(task.cancel, x)
elseif t == "function" then
pcall(x)
elseif t == "table" then
if type(x.Destroy) == "function" then pcall(x.Destroy, x)
elseif type(x.Disconnect) == "function" then pcall(x.Disconnect, x)
elseif type(x.Cancel) == "function" then pcall(x.Cancel, x) end
end
end
function Util.Bag()
local bag = { _items = {}, _dead = false }
function bag:Add(x)
if x == nil then return x end
if self._dead then pcall(Util.Dispose, x) return x end
table.insert(self._items, x)
return x
end
function bag:Clean()
local items = self._items
self._items = {}
for i = #items, 1, -1 do pcall(Util.Dispose, items[i]) end
end
function bag:Destroy()
self._dead = true
self:Clean()
end
return bag
end
function Util.Opt(t, key, kind, default, lo, hi)
local v = type(t) == "table" and t[key] or nil
if v == nil or typeof(v) ~= kind then return default end
if kind == "number" then
if v ~= v then return default end
if lo then v = math.max(v, lo) end
if hi then v = math.min(v, hi) end
end
return v
end
function Util.Debounce(fn, wait)
local token = 0
return function(...)
token = token + 1
local my, args = token, table.pack(...)
task.delay(wait or 0.1, function()
if my == token then safe(fn, table.unpack(args, 1, args.n)) end
end)
end
end
function Util.Throttle(fn, interval)
local last = -math.huge
return function(...)
local now = os.clock()
if now - last >= (interval or 0.1) then
last = now
return fn(...)
end
end
end
function Util.Round(n, dp)
local m = 10 ^ (dp or 0)
return math.floor(n * m + 0.5) / m
end
function Util.FormatNumber(n)
if type(n) ~= "number" or n ~= n then return "0" end
local a = math.abs(n)
if a >= 1e9 then return Util.Round(n / 1e9, 1) .. "B" end
if a >= 1e6 then return Util.Round(n / 1e6, 1) .. "M" end
if a >= 1e3 then return Util.Round(n / 1e3, 1) .. "K" end
return tostring(Util.Round(n, 1))
end
function Util.FormatTime(sec)
sec = math.max(0, math.floor(tonumber(sec) or 0))
local h, m, s = math.floor(sec / 3600), math.floor(sec / 60) % 60, sec % 60
if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
return string.format("%d:%02d", m, s)
end
function Util.Truncate(s, n, tail)
s = tostring(s)
local len = utf8.len(s)
if not len then return #s > n and (s:sub(1, n) .. (tail or "...")) or s end
if len <= n then return s end
local cut = utf8.offset(s, n + 1)
return s:sub(1, (cut or (n + 1)) - 1) .. (tail or "\u{2026}")
end
function Util.Lighten(c, a) return c:Lerp(Color3.new(1, 1, 1), a or 0.3) end
function Util.Darken(c, a) return c:Lerp(Color3.new(0, 0, 0), a or 0.3) end
function Util.ToHex(c)
return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end
function Util.FromHex(s)
if type(s) ~= "string" then return nil end
local h = s:match("^#?(%x%x%x%x%x%x)$")
if not h then return nil end
return Color3.fromRGB(tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16))
end
function Util.Contrast(c)
local l = 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
return l > 0.6 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
end
local Responsive = {}
Library.Responsive = Responsive
function Responsive.IsTouch() return false end
function Responsive.Viewport(win)
local gui = win and win.Gui
if gui and gui.Parent then
local s = gui.AbsoluteSize
if s.X > 0 and s.Y > 0 then return s end
end
local cam = Workspace.CurrentCamera
if cam and cam.ViewportSize.X > 0 then return cam.ViewportSize end
return Vector2.new(1280, 720)
end
function Responsive.Breakpoint(win)
local vp = Responsive.Viewport(win)
if false then
return math.min(vp.X, vp.Y) < 500 and "phone" or "tablet"
end
return vp.X < 560 and "phone" or "desktop"
end
function Responsive.Width(win, max, margin)
local vp = Responsive.Viewport(win)
margin = margin or 12
local e = Library._edge(vp)
if e then margin = math.max(margin, e.L) end
return math.floor(math.clamp(vp.X - margin * 2, 120, max or 320))
end
function Responsive.Touch(pc, touch)
if false then return touch end
return pc
end
function Responsive.Scale(n)
return false and math.floor(n * 1.15 + 0.5) or n
end
function Responsive.OnChange(win, fn)
local gui = win and win.Gui
if not gui then return { Disconnect = function() end } end
return gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
safe(fn, gui.AbsoluteSize, Responsive.Breakpoint(win))
end)
end
function Window:OnResize(fn)
local c = Responsive.OnChange(self, fn)
table.insert(self.Conns, c)
return c
end
local Anim = Library.Anim
local animSeq = setmetatable({}, { __mode = "k" })
local animHome = setmetatable({}, { __mode = "k" })
local function tw(o, t, props, style, dir, delay)
t = math.max(t * (Library.Anim.Speed or 1), 0.06)
local tweenObj = TweenService:Create(o, TweenInfo.new(t, style or SINE, dir or OUT, 0, false, delay or 0), props)
tweenObj:Play()
return tweenObj
end
function Anim.Tween(obj, t, props, style, dir)
if typeof(obj) ~= "Instance" or type(props) ~= "table" then return nil end
return tween(obj, t or 0.2, props, style, dir)
end
local DIRS = {
Left = Vector2.new(-1, 0), Right = Vector2.new(1, 0), Top = Vector2.new(0, -1), Bottom = Vector2.new(0, 1),
None = Vector2.new(0, 0),
}
local function fadeProp(obj)
if obj:IsA("CanvasGroup") then return "GroupTransparency" end
if obj:IsA("GuiObject") then return "BackgroundTransparency" end
end
local function ensureScale(obj)
local s = obj:FindFirstChild("SpectreScale")
if not s then s = new("UIScale", { Name = "SpectreScale", Parent = obj }) end
return s
end
local function homeOf(obj)
local h = animHome[obj]
if not h then
h = { Pos = obj.Position, Fade = obj:IsA("CanvasGroup") and 0 or obj.BackgroundTransparency }
animHome[obj] = h
end
return h
end
function Anim.Show(obj, opts, done)
if typeof(obj) ~= "Instance" or not obj:IsA("GuiObject") then return nil end
opts = type(opts) == "table" and opts or {}
local seq = (animSeq[obj] or 0) + 1
animSeq[obj] = seq
local home = homeOf(obj)
local d = (DIRS[opts.From or "Bottom"] or DIRS.None) * (opts.Distance or 24)
local t = opts.Time or 0.3
local fp = fadeProp(obj)
local fade = fp and home.Fade < 1
obj.Position = home.Pos + UDim2.fromOffset(d.X, d.Y)
if fade then obj[fp] = 1 end
obj.Visible = true
local sc
if opts.Scale then
sc = ensureScale(obj)
sc.Scale = opts.Scale
end
local main = tw(obj, t, { Position = home.Pos }, opts.Style or QUINT, OUT)
if fade then tw(obj, t * 0.8, { [fp] = home.Fade }, SINE, OUT) end
if sc then tw(sc, t, { Scale = 1 }, opts.Style or QUINT, OUT) end
if done then
main.Completed:Connect(function(st)
if animSeq[obj] == seq and st == Enum.PlaybackState.Completed then safe(done, obj) end
end)
end
return main
end
function Anim.Hide(obj, opts, done)
if typeof(obj) ~= "Instance" or not obj:IsA("GuiObject") then return nil end
opts = type(opts) == "table" and opts or {}
local seq = (animSeq[obj] or 0) + 1
animSeq[obj] = seq
local home = homeOf(obj)
local d = (DIRS[opts.To or "Bottom"] or DIRS.None) * (opts.Distance or 24)
local t = opts.Time or 0.2
local fp = fadeProp(obj)
local fade = fp and home.Fade < 1
local sc = opts.Scale and ensureScale(obj)
local main = tw(obj, t, { Position = home.Pos + UDim2.fromOffset(d.X, d.Y) }, opts.Style or QUAD, IN)
if fade then tw(obj, t, { [fp] = 1 }, SINE, IN) end
if sc then tw(sc, t, { Scale = opts.Scale }, QUAD, IN) end
main.Completed:Connect(function()
if animSeq[obj] ~= seq then return end
animHome[obj] = nil
if opts.Destroy then
obj:Destroy()
else
obj.Visible = false
obj.Position = home.Pos
if fade then obj[fp] = home.Fade end
if sc then sc.Scale = 1 end
end
if done then safe(done, obj) end
end)
return main
end
function Anim.Pulse(obj, amount, t)
if typeof(obj) ~= "Instance" or not obj:IsA("GuiObject") then return end
local sc = ensureScale(obj)
local seq = (animSeq[sc] or 0) + 1
animSeq[sc] = seq
tw(sc, (t or 0.2) * 0.4, { Scale = 1 + (amount or 0.04) }, QUAD, OUT).Completed:Connect(function()
if animSeq[sc] == seq then tw(sc, (t or 0.2) * 0.6, { Scale = 1 }, QUAD, OUT) end
end)
end
function Anim.Stop(obj)
if obj then
animSeq[obj] = (animSeq[obj] or 0) + 1
animHome[obj] = nil
end
end
Library.Kinds = {
Success = { Color = rgb(52, 211, 153), Icon = "check" },
Warning = { Color = rgb(251, 191, 36), Icon = "!" },
Error   = { Color = rgb(248, 113, 113), Icon = "cross" },
Info    = { Color = rgb(96, 165, 250), Icon = "i" },
Loading = { Color = nil, Icon = "spinner" },
}
local THEME_COLOR_KEYS = { "Background", "Panel", "Card", "Control", "Border", "Accent", "Accent2", "AccentSoft", "Sheen", "Text", "SubText" }
function Library:RegisterTheme(name, theme)
if type(name) ~= "string" or name == "" or type(theme) ~= "table" then return false, "usage: RegisterTheme(name, table)" end
for _, k in ipairs(THEME_COLOR_KEYS) do
if theme[k] ~= nil and typeof(theme[k]) ~= "Color3" then return false, k .. " must be a Color3" end
end
self.Themes[name] = theme
return true
end
function Library:GetTheme(name)
if name == nil then return deriveTheme(table.clone(self.Theme)) end
local src = self.Themes[name]
if not src then return nil end
return deriveTheme(buildTheme(src))
end
function Library:ListThemes()
local out = {}
for k in pairs(self.Themes) do table.insert(out, k) end
table.sort(out)
return out
end
function Library:SetStatusColors(map)
if type(map) ~= "table" then return false end
for k, c in pairs(map) do
if self.Kinds[k] and typeof(c) == "Color3" then self.Kinds[k].Color = c end
end
return true
end
function Library:GetStatusColor(kind)
local k = self.Kinds[kind]
return k and k.Color
end
local NotifyCfg = { Position = nil, MaxVisible = nil, Duration = 4, Gap = 8, Margin = nil, Width = nil, Merge = true, PauseOnHover = true, Animate = true }
Library.NotifyConfig = NotifyCfg
local POSITIONS = {
TopLeft = { 0, 0 }, TopCenter = { 0.5, 0 }, TopRight = { 1, 0 },
BottomLeft = { 0, 1 }, BottomCenter = { 0.5, 1 }, BottomRight = { 1, 1 },
}
local function normPos(p)
if type(p) ~= "string" then return nil end
local k = p:gsub("[%s_%-]", "")
k = k:lower()
for name in pairs(POSITIONS) do
if name:lower() == k then return name end
end
end
local KIND_ALIAS = {
success = "Success", ok = "Success", warning = "Warning", warn = "Warning", error = "Error", err = "Error",
info = "Info", information = "Info", loading = "Loading",
}
local function normKind(k)
if type(k) ~= "string" then return nil end
return KIND_ALIAS[k:lower()]
end
local function roleDuration(role)
if role == "toast" then return 2.4 end
if role == "banner" then return 5 end
if role == "loading" then return math.huge end
return NotifyCfg.Duration or 4
end
local function normDuration(d, dismissFlag, default)
if dismissFlag == false then return math.huge end
if d == nil then return default end
if d == false then return math.huge end
if type(d) ~= "number" or d ~= d then return default end
if d <= 0 or d == math.huge then return math.huge end
return math.clamp(d, 0.4, 3600)
end
local function clip(v, n)
if v == nil or v == false then return nil end
v = tostring(v)
if v == "" then return nil end
return Util.Truncate(v, n)
end
local function normalize(cfg, role, base)
if type(cfg) == "string" then cfg = { Content = cfg } end
if type(cfg) ~= "table" then cfg = {} end
local s
if base then
s = table.clone(base)
else
s = {
Role = role, Duration = roleDuration(role), Countdown = (role == "notify" or role == "banner"),
Closable = (role ~= "toast"), CloseOnClick = true,
}
end
if cfg.Kind ~= nil or cfg.Type ~= nil then s.Kind = normKind(cfg.Kind ~= nil and cfg.Kind or cfg.Type) end
if cfg.Title ~= nil then s.Title = clip(cfg.Title, 90) end
if cfg.Content ~= nil or cfg.Text ~= nil or cfg.Message ~= nil then
local c = cfg.Content
if c == nil then c = cfg.Text end
if c == nil then c = cfg.Message end
s.Content = clip(c, 500)
end
if cfg.Icon ~= nil then
if cfg.Icon == "auto" then s.Icon = nil
elseif cfg.Icon == false or type(cfg.Icon) == "string" or type(cfg.Icon) == "number" then s.Icon = cfg.Icon end
end
if cfg.Color ~= nil then s.Color = typeof(cfg.Color) == "Color3" and cfg.Color or nil end
if cfg.Duration ~= nil or cfg.Dismiss ~= nil then
s.Duration = normDuration(cfg.Duration, cfg.Dismiss, roleDuration(s.Role))
end
if cfg.Progress ~= nil then
local p = cfg.Progress
if type(p) == "number" and p == p then
s.Value = math.clamp(p, 0, 1)
elseif type(p) == "boolean" then
s.Value = nil
s.Countdown = p
end
end
if cfg.Position ~= nil then s.Position = normPos(cfg.Position) end
if cfg.Key ~= nil or cfg.Id ~= nil then
local k = cfg.Key
if k == nil then k = cfg.Id end
s.Key = k ~= nil and tostring(k) or nil
end
if type(cfg.Closable) == "boolean" then s.Closable = cfg.Closable end
if type(cfg.CloseOnClick) == "boolean" then s.CloseOnClick = cfg.CloseOnClick end
if type(cfg.Merge) == "boolean" then s.Merge = cfg.Merge end
if cfg.Flash ~= nil then s.Flash = cfg.Flash and true or false end
if type(cfg.OnClick) == "function" then s.OnClick = cfg.OnClick end
if type(cfg.OnClose) == "function" then s.OnClose = cfg.OnClose end
if not base then
if s.Role ~= "toast" and s.Title == nil then
s.Title = s.Kind == "Loading" and "Loading" or s.Kind or "Notice"
end
if s.Role == "toast" and s.Content == nil then s.Content = s.Title; s.Title = nil end
if s.Content == nil and s.Title == nil then s.Title = "Notice" end
end
return s
end
local function defaultPosition(role)
local p = normPos(NotifyCfg.Position)
if p then return p end
if false then return "TopRight" end
if role == "banner" then return "TopCenter" end
return role == "toast" and "BottomCenter" or "BottomRight"
end
local function isPersistent(spec) return spec.Duration == math.huge or spec.Value ~= nil end
local function styleOf(T, spec)
local k = spec.Kind and Library.Kinds[spec.Kind]
local base = (k and k.Color) or spec.Color
if base then return base, Util.Lighten(base, 0.35) end
return T.Accent, T.Accent2
end
local function seg(parent, x1, y1, x2, y2, th, color)
local dx, dy = x2 - x1, y2 - y1
return new("Frame", {
AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2),
Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy) + th * 0.5, th), Rotation = math.deg(math.atan2(dy, dx)),
BackgroundColor3 = color, BorderSizePixel = 0, Parent = parent,
}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
end
local function buildIcon(parent, icon, color, T, size, bag)
local holder = new("Frame", { Name = "Icon", Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, Parent = parent })
local u = size / 22
if icon == "spinner" then
local ring = new("Frame", {
AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(18 * u, 18 * u),
BackgroundTransparency = 1, Parent = holder,
}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
local st = new("UIStroke", { Color = color, Thickness = 2.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = ring })
local g = new("UIGradient", {
Transparency = NumberSequence.new({
NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.35, 0.05),
NumberSequenceKeypoint.new(0.7, 1), NumberSequenceKeypoint.new(1, 1),
}), Parent = st,
})
local lp = TweenService:Create(g, TweenInfo.new(0.9, LINEAR, OUT, -1), { Rotation = 360 })
lp:Play()
if bag then bag:Add(lp) end
return holder
end
new("Frame", {
Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, BackgroundTransparency = 0.82, BorderSizePixel = 0, Parent = holder,
}, { new("UICorner", { CornerRadius = UDim.new(0, 8) }) })
if icon == "check" then
seg(holder, 6.2 * u, 11.6 * u, 9.6 * u, 15 * u, 2 * u, color)
seg(holder, 9.6 * u, 15 * u, 16.2 * u, 7.6 * u, 2 * u, color)
elseif icon == "cross" then
seg(holder, 7.2 * u, 7.2 * u, 14.8 * u, 14.8 * u, 2 * u, color)
seg(holder, 14.8 * u, 7.2 * u, 7.2 * u, 14.8 * u, 2 * u, color)
elseif type(icon) == "number" or (type(icon) == "string" and icon:find("rbxasset", 1, true)) then
new("ImageLabel", {
AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.64, 0.64),
BackgroundTransparency = 1, ImageColor3 = color, ScaleType = Enum.ScaleType.Fit,
Image = type(icon) == "number" and ("rbxassetid://" .. icon) or icon, Parent = holder,
})
elseif Library:IsIconName(icon) and Library:ResolveIcon(icon) then
local img = Library:MakeIcon(Library:ResolveIcon(icon), color)
img.Size = UDim2.fromScale(0.64, 0.64)
img.Parent = holder
else
new("TextLabel", {
Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = tostring(icon or "i"):sub(1, 2),
Font = T.FontBold, TextSize = math.floor(14 * u), TextColor3 = color, Parent = holder,
})
end
return holder
end
local NM = {}
NM.__index = NM
local function mountGui(gui)
Library._mount(gui)
end
function NM.new(owner)
return setmetatable({ Owner = owner, Regions = {}, Dialogs = {}, Bag = Util.Bag(), Seq = 0, Dead = false }, NM)
end
function NM:Theme()
local o = self.Owner
if o.Headless then return deriveTheme(table.clone(Library.Theme)) end
return o._nTheme or o.Theme
end
function NM:_VP()
local o = self.Owner
if self.Gui and self.Gui.Parent then
local s = self.Gui.AbsoluteSize
if s.X > 0 and s.Y > 0 then return s end
end
return Responsive.Viewport(not o.Headless and o or nil)
end
function NM:_Gui()
if self.Gui and self.Gui.Parent then return self.Gui end
if self.Gui then self:_Reset() end
local g = new("ScreenGui", {
Name = "SpectreUI_Notify", ResetOnSpawn = false, IgnoreGuiInset = false,
ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 1000,
})
local og = self.Owner.Gui
if og and og.Parent then g.Parent = og.Parent else mountGui(g) end
self.Gui = g
self.GuiConn = g:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:_RefitSoon() end)
return g
end
function NM:_Reset()
for _, r in pairs(self.Regions) do
for _, e in ipairs(table.clone(r.Items)) do self:_Kill(e, "destroyed") end
for _, e in ipairs(table.clone(r.Queue)) do self:_Kill(e, "destroyed") end
end
self.Regions = {}
if self.GuiConn then self.GuiConn:Disconnect() self.GuiConn = nil end
self.Gui = nil
end
function NM:_RefitSoon()
if self._refit or self.Dead then return end
self._refit = true
task.defer(function()
self._refit = false
if self.Dead then return end
for _, r in pairs(self.Regions) do self:_FitRegion(r) end
for _, d in ipairs(self.Dialogs) do if d.fit then d.fit() end end
end)
end
function NM:_MaxVisible()
local m = NotifyCfg.MaxVisible
if type(m) ~= "number" then m = 5 end
return math.clamp(math.floor(m), 1, 10)
end
function NM:_FitRegion(r)
local vp = self:_VP()
local m = NotifyCfg.Margin
local mx, mt, mb
if type(m) == "number" then
mx, mt, mb = m, m, m
else
m = Responsive.Touch(14, 14)
mx, mt, mb = m, m, m
local e = Library._edge(vp)
if e then mx, mb = e.L, e.B end
end
local maxW = NotifyCfg.Width
if type(maxW) ~= "number" then maxW = (r.AX == 0.5) and 360 or Responsive.Touch(320, 300) end
r.W = math.floor(math.clamp(vp.X - mx * 2, 120, maxW))
r.H = math.max(vp.Y - mt - mb, 60)
r.Gap = type(NotifyCfg.Gap) == "number" and NotifyCfg.Gap or 8
r.Holder.AnchorPoint = Vector2.new(r.AX, r.AY)
r.Holder.Position = UDim2.new(r.AX, r.AX == 0 and mx or (r.AX == 1 and -mx or 0), r.AY, r.AY == 0 and mt or -mb)
r.Holder.Size = UDim2.fromOffset(r.W, r.H)
r.Layout.Padding = UDim.new(0, r.Gap)
for _, e in ipairs(r.Items) do
if e.wrap and not e.auto and e.state ~= "dead" then
e.wrap.Size = UDim2.fromOffset(r.W, e.wrap.Size.Y.Offset)
end
end
self:_Overflow(r)
end
function NM:_Region(pos)
local r = self.Regions[pos]
if r and r.Holder.Parent then return r end
local gui = self:_Gui()
local ax, ay = POSITIONS[pos][1], POSITIONS[pos][2]
local holder = new("Frame", { Name = "Region_" .. pos, BackgroundTransparency = 1, Parent = gui })
local layout = list(8, {
FillDirection = Enum.FillDirection.Vertical,
HorizontalAlignment = ax == 0 and Enum.HorizontalAlignment.Left or (ax == 1 and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Center),
VerticalAlignment = ay == 0 and Enum.VerticalAlignment.Top or Enum.VerticalAlignment.Bottom,
})
layout.Parent = holder
r = { Pos = pos, AX = ax, AY = ay, Holder = holder, Layout = layout, Items = {}, Queue = {}, W = 300, H = 400, Gap = 8 }
self.Regions[pos] = r
self:_FitRegion(r)
return r
end
local function activeCount(r)
local n = 0
for _, e in ipairs(r.Items) do
if e.state ~= "leaving" and e.state ~= "dead" then n = n + 1 end
end
return n
end
local function oldestDismissable(r, except)
for _, e in ipairs(r.Items) do
if e ~= except and (e.state == "entering" or e.state == "shown") and not isPersistent(e.spec) then return e end
end
end
function NM:_Overflow(r)
for _ = 1, 12 do
local total, n = 0, 0
for _, e in ipairs(r.Items) do
if e.state ~= "leaving" and e.state ~= "dead" and e.h then
total = total + e.h + r.Gap
n = n + 1
end
end
if n <= 1 or total - r.Gap <= r.H then return end
local newest = r.Items[#r.Items]
local v = oldestDismissable(r, newest)
if not v then return end
self:_Dismiss(v, "evicted")
end
end
function NM:_Pump(r)
if self.Dead then return end
while #r.Queue > 0 and activeCount(r) < self:_MaxVisible() do
local e = table.remove(r.Queue, 1)
self:_Show(e, r)
end
end
local function slideDir(r)
if r.AX == 1 then return "Right" end
if r.AX == 0 then return "Left" end
return r.AY == 0 and "Top" or "Bottom"
end
local function deadHandle()
local h = { Id = 0 }
local no = function() return false end
for _, n in ipairs({ "Update", "SetProgress", "Dismiss", "Close", "IsAlive", "OnClose", "Set", "SetText", "Complete", "Fail" }) do h[n] = no end
return h
end
Library._deadHandle = deadHandle
local function method(h, fn)
return function(a, ...)
if a == h then return fn(...) end
return fn(a, ...)
end
end
function NM:_Handle(entry)
local h = { Id = entry.Id }
local nm = self
h.Update = method(h, function(patch)
if nm:_Update(entry, patch) then return h end
return false
end)
h.SetProgress = method(h, function(v)
if type(v) ~= "number" then return false end
return nm:_Update(entry, { Progress = v }) and h or false
end)
h.Dismiss = method(h, function(reason) return nm:_Dismiss(entry, type(reason) == "string" and reason or "api") end)
h.Close = h.Dismiss
h.IsAlive = method(h, function() return entry.state ~= "dead" and entry.state ~= "leaving" end)
h.OnClose = method(h, function(fn)
if type(fn) == "function" then entry.spec.OnClose = fn end
return h
end)
entry.handle = h
return h
end
function NM:_Build(entry)
local T = self:Theme()
local spec, r = entry.spec, entry.region
local ui = {}
entry.ui = ui
local toast = spec.Role == "toast"
entry.auto = toast
local bag = entry.bag
local touch = Library.SizeTouch
local wrap = new("Frame", {
Name = "N" .. entry.Id, BackgroundTransparency = 1, LayoutOrder = entry.Id,
Size = UDim2.fromOffset(toast and 0 or r.W, 0), Parent = r.Holder,
})
entry.wrap = wrap
local dir = slideDir(r)
local card = new("CanvasGroup", {
Name = "Card", BackgroundTransparency = 1, GroupTransparency = 1,
Size = toast and UDim2.fromOffset(0, 0) or UDim2.new(1, 0, 0, 0), AutomaticSize = toast and Enum.AutomaticSize.XY or AY,
Parent = wrap,
}, { corner(toast and 16 or 10) })
ui.Card = card
if not toast then new("UISizeConstraint", { MinSize = Vector2.new(0, 46), Parent = card }) end
ui.Bg = new("Frame", { Name = "Bg", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Panel, BackgroundTransparency = 0.03, BorderSizePixel = 0, ZIndex = 1, Parent = card })
ui.BgGrad = wash(cseq({ 0, T.Top }, { 1, T.Deep }), 90)
ui.BgGrad.Parent = ui.Bg
ui.Tint = new("Frame", { Name = "Tint", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Accent, BackgroundTransparency = 0,
BorderSizePixel = 0, ZIndex = 2, Visible = not lowPower(), Parent = card },
{ new("UIGradient", { Transparency = NumberSequence.new({
NumberSequenceKeypoint.new(0, 0.78), NumberSequenceKeypoint.new(0.55, 0.94), NumberSequenceKeypoint.new(1, 1),
}) }) })
ui.Rim = new("Frame", { Name = "Rim", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2, Parent = card },
{ corner(toast and 16 or 10), stroke(T.Accent, 2, 0.5) })
ui.RimStroke = ui.Rim:FindFirstChildOfClass("UIStroke")
if toast then
local row = new("Frame", { Name = "Row", Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1, ZIndex = 3, Parent = card },
{ list(8, { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center }), padding(12, 8, 16, 8) })
ui.Row = row
ui.IconSlot = new("Frame", { LayoutOrder = 1, Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1, Parent = row })
local maxText = math.max(r.W - 12 - 16 - 18 - 8, 60)
ui.Content = new("TextLabel", {
LayoutOrder = 2, Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1,
Font = T.Font, TextSize = 14, TextColor3 = T.Text, TextWrapped = true, TextXAlignment = LEFT, Parent = row,
}, { new("UISizeConstraint", { MaxSize = Vector2.new(maxText, math.huge) }) })
ui.MaxText = ui.Content:FindFirstChildOfClass("UISizeConstraint")
else
local cs = touch and 32 or 24
ui.Rail = new("Frame", { Name = "Rail", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 6, 0.5, 0), Size = UDim2.new(0, 3, 1, -20),
BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 3, Parent = card },
{ corner(2), gradient(T.Accent, T.Accent2, 90) })
ui.RailGrad = ui.Rail:FindFirstChildOfClass("UIGradient")
ui.IconSlot = new("Frame", { Name = "IconSlot", Position = UDim2.fromOffset(16, 10), Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1, ZIndex = 3, Parent = card })
local inner = new("Frame", {
Name = "Inner", Position = UDim2.fromOffset(48, 0), Size = UDim2.new(1, -(48 + 27 + cs / 2 + 4), 0, 0), AutomaticSize = AY,
BackgroundTransparency = 1, ZIndex = 3, Parent = card,
}, { list(3), padding(0, 11, 0, 13) })
ui.Title = new("TextLabel", {
LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Font = T.FontBold, TextSize = 14,
TextColor3 = T.Text, TextXAlignment = LEFT, TextWrapped = true, Parent = inner,
})
ui.Content = new("TextLabel", {
LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Font = T.Font, TextSize = 14,
TextColor3 = T.SubText, TextXAlignment = LEFT, TextWrapped = true, Parent = inner,
})
ui.Track = new("Frame", { Name = "Track", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -6), Size = UDim2.new(1, -32, 0, 3),
BackgroundColor3 = T.Accent, BackgroundTransparency = 0.86, BorderSizePixel = 0, ZIndex = 4, Visible = false, Parent = card }, { corner(2) })
ui.Fill = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = ui.Track },
{ corner(2), gradient(T.Accent, T.Accent2, 0) })
ui.FillGrad = ui.Fill:FindFirstChildOfClass("UIGradient")
end
ui.Hit = new("TextButton", { Name = "Hit", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 5, Parent = card })
bag:Add(ui.Hit.MouseButton1Click:Connect(function()
local s = entry.spec
if s.OnClick then safe(s.OnClick, entry.handle) end
if s.CloseOnClick then self:_Dismiss(entry, "click") end
end))
if not toast then
local cs = touch and 32 or 24
ui.Close = new("TextButton", {
Name = "Close", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -(27 - cs / 2), 0, 21 - cs / 2), Size = UDim2.fromOffset(cs, cs),
BackgroundTransparency = 1, Text = "\u{00D7}", Font = T.FontBold, TextSize = 20, TextColor3 = T.SubText, AutoButtonColor = false, ZIndex = 6, Parent = card,
})
bag:Add(ui.Close.MouseButton1Click:Connect(function() self:_Dismiss(entry, "close") end))
bag:Add(ui.Close.MouseEnter:Connect(function()
if not usingTouch() then tween(ui.Close, 0.12, { TextColor3 = T.Text }) end
end))
bag:Add(ui.Close.MouseLeave:Connect(function() tween(ui.Close, 0.14, { TextColor3 = T.SubText }) end))
end
if NotifyCfg.PauseOnHover ~= false then
bag:Add(ui.Hit.MouseEnter:Connect(function()
if usingTouch() then return end
self:_Hover(entry, true)
end))
bag:Add(ui.Hit.MouseLeave:Connect(function() self:_Hover(entry, false) end))
end
self:_Paint(entry)
bag:Add(card:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:_OnSize(entry) end))
bag:Add(task.delay(0.4, function()
if entry.state == "entering" and not entry.measured then
entry.h = entry.h or 64
entry.w = entry.w or r.W
entry.measured = true
self:_Enter(entry)
end
end))
self:_OnSize(entry)
end
function NM:_Paint(entry)
local T = self:Theme()
local spec, ui = entry.spec, entry.ui
local accent, accent2 = styleOf(T, spec)
local toast = spec.Role == "toast"
ui.RimStroke.Color = accent
if ui.Tint then ui.Tint.BackgroundColor3 = accent end
if ui.RailGrad then ui.RailGrad.Color = ColorSequence.new(accent, accent2) end
if ui.FillGrad then ui.FillGrad.Color = ColorSequence.new(accent, accent2) end
if ui.Track then ui.Track.BackgroundColor3 = accent end
local content = spec.Content or ""
if ui.Title then
local title = spec.Title or ""
if entry.count > 1 then title = title .. "  \u{00D7}" .. entry.count end
if spec.Value ~= nil and spec.Kind == "Loading" then title = title .. "  \u{00B7}  " .. math.floor(spec.Value * 100 + 0.5) .. "%" end
ui.Title.Text = title
ui.Title.Visible = title ~= ""
ui.Content.Text = content
ui.Content.Visible = content ~= ""
else
ui.Content.Text = (entry.count > 1 and (content .. "  \u{00D7}" .. entry.count)) or content
end
if ui.Close then ui.Close.Visible = spec.Closable end
local k = spec.Kind and Library.Kinds[spec.Kind]
local icon = spec.Icon
if icon == nil then icon = k and k.Icon or "i" end
local key = tostring(icon) .. "|" .. tostring(accent)
if ui.IconKey ~= key then
ui.IconKey = key
ui.IconBag = ui.IconBag or Util.Bag()
ui.IconBag:Clean()
for _, c in ipairs(ui.IconSlot:GetChildren()) do c:Destroy() end
ui.IconSlot.Visible = icon ~= false
if icon ~= false then buildIcon(ui.IconSlot, icon, accent, T, toast and 18 or 22, ui.IconBag) end
end
if ui.IconBag and not entry.iconBagAdded then
entry.iconBagAdded = true
entry.bag:Add(function() ui.IconBag:Destroy() end)
end
end
function NM:_OnSize(entry)
if entry.state == "dead" or not entry.ui then return end
local sz = entry.ui.Card.AbsoluteSize
if sz.Y <= 0 then return end
entry.h, entry.w = sz.Y, sz.X
if not entry.measured then
entry.measured = true
if entry.state == "entering" then self:_Enter(entry) end
elseif entry.state == "shown" then
self:_SetWrap(entry, true)
self:_Overflow(entry.region)
end
end
function NM:_SetWrap(entry, animate)
local wrap = entry.wrap
if not wrap or entry.state == "dead" then return end
local size = UDim2.fromOffset(entry.auto and entry.w or entry.region.W, entry.h)
if animate and NotifyCfg.Animate ~= false then
tw(wrap, 0.18, { Size = size }, QUAD, OUT)
else
wrap.Size = size
end
end
function NM:_Enter(entry)
if entry.state ~= "entering" then return end
local r = entry.region
local fw = entry.auto and entry.w or r.W
local fin = UDim2.fromOffset(fw, entry.h)
local anim = NotifyCfg.Animate ~= false
self:_Overflow(r)
if not anim then
entry.wrap.Size = fin
entry.ui.Card.GroupTransparency = 0
entry.state = "shown"
self:_StartTimer(entry)
return
end
local t = lowPower() and 0.2 or 0.32
entry.wrap.Size = UDim2.fromOffset(fw, 0)
local grow = tw(entry.wrap, t, { Size = fin }, QUINT, OUT)
Anim.Show(entry.ui.Card, { From = lowPower() and "None" or slideDir(r), Distance = 36, Time = t })
entry.bag:Add(grow)
entry.bag:Add(grow.Completed:Connect(function()
if entry.state ~= "entering" then return end
entry.state = "shown"
self:_SetWrap(entry, false)
self:_StartTimer(entry)
end))
entry.bag:Add(task.delay(t + 0.8, function()
if entry.state == "entering" then
entry.state = "shown"
self:_SetWrap(entry, false)
entry.ui.Card.GroupTransparency = 0
self:_StartTimer(entry)
end
end))
end
function NM:_StopTimer(entry)
if entry.lifeConn then entry.lifeConn:Disconnect() entry.lifeConn = nil end
if entry.life then
pcall(function() entry.life:Cancel() end)
entry.life = nil
end
end
function NM:_StartTimer(entry)
self:_StopTimer(entry)
if entry.state ~= "shown" then return end
local spec, ui = entry.spec, entry.ui
if not ui.Track then
if spec.Duration == math.huge then return end
local probe = ui.Probe
if not probe then
probe = new("Frame", { Name = "Probe", Visible = false, Size = UDim2.fromOffset(1, 1), Parent = ui.Card })
ui.Probe = probe
end
probe.Size = UDim2.fromOffset(1, 1)
local life = TweenService:Create(probe, TweenInfo.new(spec.Duration, LINEAR), { Size = UDim2.fromOffset(0, 0) })
entry.life = life
entry.lifeConn = life.Completed:Connect(function(st)
if st == Enum.PlaybackState.Completed then self:_Dismiss(entry, "timeout") end
end)
life:Play()
if entry.hovering then life:Pause() end
return
end
if spec.Value ~= nil then
ui.Track.Visible = true
tw(ui.Fill, 0.2, { Size = UDim2.fromScale(spec.Value, 1) }, QUAD, OUT)
return
end
if spec.Duration == math.huge then
ui.Track.Visible = false
return
end
ui.Track.Visible = spec.Countdown and true or false
ui.Fill.Size = UDim2.fromScale(1, 1)
local life = TweenService:Create(ui.Fill, TweenInfo.new(spec.Duration, LINEAR), { Size = UDim2.fromScale(0, 1) })
entry.life = life
entry.lifeConn = life.Completed:Connect(function(st)
if st == Enum.PlaybackState.Completed then self:_Dismiss(entry, "timeout") end
end)
life:Play()
if entry.hovering then life:Pause() end
end
function NM:_Hover(entry, on)
if entry.state == "dead" or entry.state == "leaving" then return end
entry.hovering = on
if entry.pauseThread then
pcall(task.cancel, entry.pauseThread)
entry.pauseThread = nil
end
if on then
if entry.life then pcall(function() entry.life:Pause() end) end
if entry.ui.RimStroke then tween(entry.ui.RimStroke, 0.15, { Transparency = 0.1 }) end
entry.pauseThread = task.delay(12, function()
entry.pauseThread = nil
self:_Hover(entry, false)
end)
else
if entry.life then pcall(function() entry.life:Play() end) end
if entry.ui.RimStroke then tween(entry.ui.RimStroke, 0.2, { Transparency = 0.5 }) end
end
end
function NM:_Kill(entry, reason)
if entry.state == "dead" then return end
entry.state = "dead"
self:_StopTimer(entry)
if entry.pauseThread then pcall(task.cancel, entry.pauseThread) entry.pauseThread = nil end
entry.bag:Destroy()
if entry.wrap then
pcall(function() entry.wrap:Destroy() end)
entry.wrap = nil
end
local r = entry.region
if r then
for i, e in ipairs(r.Items) do
if e == entry then table.remove(r.Items, i) break end
end
for i, e in ipairs(r.Queue) do
if e == entry then table.remove(r.Queue, i) break end
end
end
local cb = entry.spec.OnClose
entry.ui = nil
if cb then safe(cb, reason or "api") end
if r and not self.Dead then
self:_Pump(r)
end
end
function NM:_Dismiss(entry, reason)
local st = entry.state
if st == "dead" or st == "leaving" then return false end
if st == "queued" then
self:_Kill(entry, reason)
return true
end
entry.state = "leaving"
self:_StopTimer(entry)
if entry.pauseThread then pcall(task.cancel, entry.pauseThread) entry.pauseThread = nil end
local wrap, card, r = entry.wrap, entry.ui and entry.ui.Card, entry.region
if not wrap or not card or NotifyCfg.Animate == false then
self:_Kill(entry, reason)
return true
end
Anim.Hide(card, { To = lowPower() and "None" or slideDir(r), Distance = 36, Time = 0.2 })
local collapse = tw(wrap, 0.26, { Size = UDim2.fromOffset(wrap.Size.X.Offset, 0) }, QUAD, IN, 0.08)
entry.bag:Add(collapse)
entry.bag:Add(collapse.Completed:Connect(function() self:_Kill(entry, reason) end))
entry.bag:Add(task.delay(0.9, function() self:_Kill(entry, reason) end))
return true
end
function NM:DismissAll(reason)
for _, r in pairs(self.Regions) do
for _, e in ipairs(table.clone(r.Queue)) do self:_Dismiss(e, reason or "api") end
for _, e in ipairs(table.clone(r.Items)) do self:_Dismiss(e, reason or "api") end
end
end
function NM:_Update(entry, patch)
if entry.state == "dead" or entry.state == "leaving" or type(patch) ~= "table" then return false end
local old = entry.spec
local spec = normalize(patch, old.Role, old)
if patch.Position ~= nil and spec.Position ~= old.Position then spec.Position = old.Position end
entry.spec = spec
if entry.ui then
self:_Paint(entry)
if patch.Duration ~= nil or patch.Dismiss ~= nil or patch.Progress ~= nil or patch.Kind ~= nil then
self:_StartTimer(entry)
end
if entry.ui.Card then Anim.Pulse(entry.ui.Card, 0.03) end
end
return true
end
local function sameText(a, b)
return a.Role == b.Role and a.Kind == b.Kind and a.Title == b.Title and a.Content == b.Content and a.Value == nil and b.Value == nil
end
function NM:_Each(fn)
for _, r in pairs(self.Regions) do
for _, e in ipairs(r.Items) do if fn(e) then return e end end
for _, e in ipairs(r.Queue) do if fn(e) then return e end end
end
end
function NM:_Show(entry, r)
entry.region = r
entry.state = "entering"
table.insert(r.Items, entry)
local ok, err = pcall(self._Build, self, entry)
if not ok then
warn("[SpectreUI] notification build failed: " .. tostring(err))
self:_Kill(entry, "error")
end
end
function NM:Add(cfg, role)
if self.Dead then return deadHandle() end
if type(cfg) == "string" then cfg = { Content = cfg } end
if type(cfg) ~= "table" then cfg = {} end
local spec = normalize(cfg, role)
if spec.Key then
local found = self:_Each(function(e) return e.spec.Key == spec.Key and e.state ~= "leaving" and e.state ~= "dead" end)
if found then
self:_Update(found, cfg)
return found.handle
end
end
if NotifyCfg.Merge ~= false and spec.Merge ~= false and not spec.Key then
local found = self:_Each(function(e)
return e.state ~= "leaving" and e.state ~= "dead" and not e.spec.Key and sameText(e.spec, spec)
end)
if found then
found.count = found.count + 1
if found.ui then
self:_Paint(found)
self:_StartTimer(found)
Anim.Pulse(found.ui.Card, 0.04)
end
return found.handle
end
end
local r = self:_Region(spec.Position or defaultPosition(role))
self.Seq = self.Seq + 1
local entry = { Id = self.Seq, spec = spec, count = 1, state = "queued", bag = Util.Bag(), region = r }
local handle = self:_Handle(entry)
if activeCount(r) >= self:_MaxVisible() then
local victim = oldestDismissable(r)
if victim then
self:_Dismiss(victim, "evicted")
else
table.insert(r.Queue, entry)
return handle
end
end
self:_Show(entry, r)
if role ~= "loading" then playSound("Notify", cfg.Sound) end
if spec.Flash and self.Owner.Flash then
local T = self:Theme()
self.Owner:Flash((styleOf(T, spec)))
end
return handle
end
function NM:Destroy()
if self.Dead then return end
for _, r in pairs(self.Regions) do
for _, e in ipairs(table.clone(r.Items)) do self:_Kill(e, "destroyed") end
for _, e in ipairs(table.clone(r.Queue)) do self:_Kill(e, "destroyed") end
end
self.Dead = true
for i = #self.Dialogs, 1, -1 do
if self.Dialogs[i] and self.Dialogs[i].destroy then self.Dialogs[i].destroy() end
end
if self.GuiConn then self.GuiConn:Disconnect() self.GuiConn = nil end
self.Bag:Destroy()
if self.Gui then pcall(function() self.Gui:Destroy() end) end
if self.HostGui then pcall(function() self.HostGui:Destroy() end) end
self.Regions = {}
end
function NM:_DialogGui()
local o = self.Owner
if o.Gui and o.Gui.Parent then return o.Gui end
if self.HostGui and self.HostGui.Parent then return self.HostGui end
local g = new("ScreenGui", { Name = "SpectreUI_Host", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 998 })
Library._fullScreen(g)
mountGui(g)
self.HostGui = g
return g
end
function NM:Dialog(cfg)
if self.Dead then return deadHandle() end
if type(cfg) ~= "table" then cfg = {} end
local T = self:Theme()
local gui = self:_DialogGui()
local touch = Library.Mobile
local owner = (not self.Owner.Headless) and self.Owner or nil
local bag = Util.Bag()
local dlg = { open = true, input = nil }
local handle = { }
local kind = normKind(cfg.Kind)
local accent = (kind and Library.Kinds[kind] and Library.Kinds[kind].Color) or T.Accent
local accent2 = (kind and Util.Lighten(accent, 0.35)) or T.Accent2
local dismissable = cfg.Dismissable ~= false
local depth = #self.Dialogs + 1
local btnH = Library.SizeTouch and 42 or 34
local result = { value = nil, input = nil, reason = nil }
local waiters = {}
local overlay = new("Frame", {
Name = "Dialog", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
BorderSizePixel = 0, Active = true, ZIndex = 130 + depth * 2, Parent = gui,
})
local outside = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 1, Parent = overlay })
local W = Responsive.Width(owner, math.floor(Util.Opt(cfg, "Width", "number", 340, 220, 560)), 16)
local card = new("CanvasGroup", {
Name = "Card", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(W, 0),
AutomaticSize = AY, BackgroundTransparency = 1, Active = true, ZIndex = 2, Visible = false, Parent = overlay,
}, { corner(12) })
new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Panel, BackgroundTransparency = 0.02, BorderSizePixel = 0, ZIndex = 1, Parent = card },
{ wash(cseq({ 0, T.Top }, { 1, T.Deep }), 90) })
local dlgTint = new("Frame", { Name = "Tint", Size = UDim2.new(1, 0, 0, 96), BackgroundColor3 = accent, BackgroundTransparency = 0,
BorderSizePixel = 0, ZIndex = 2, Visible = not lowPower(), Parent = card },
{ new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0.84, 1) }) })
local dlgRim = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2, Parent = card }, { corner(12), stroke(accent, 2, 0.45) })
local dlgStroke = dlgRim:FindFirstChildOfClass("UIStroke")
local accentGrads = {}
local col = new("Frame", { Size = UDim2.fromScale(1, 0), AutomaticSize = AY, BackgroundTransparency = 1, ZIndex = 3, Parent = card },
{ list(12), padding(18, 18, 18, 16) })
local head = new("Frame", { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, ZIndex = 3, Parent = col },
{ list(10, { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center }) })
local iconSlot = new("Frame", { LayoutOrder = 1, Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 1, ZIndex = 3, Parent = head })
local titleL = new("TextLabel", {
LayoutOrder = 2, Size = UDim2.new(1, -34, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Font = T.FontBold, TextSize = 16,
TextColor3 = T.Text, TextXAlignment = LEFT, TextWrapped = true, ZIndex = 3, Parent = head,
})
local scroll = new("ScrollingFrame", { ElasticBehavior = Enum.ElasticBehavior.Never,
LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
ScrollBarImageColor3 = accent, CanvasSize = UDim2.new(), AutomaticCanvasSize = AY, ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 3, Parent = col,
})
local body = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, ZIndex = 3, Parent = scroll },
{ list(10), padding(0, 0, 4, 0) })
local contentL = new("TextLabel", {
LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Font = T.Font, TextSize = 14,
TextColor3 = T.SubText, TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, ZIndex = 3, Parent = body,
})
local box
if cfg.Input then
local ic = type(cfg.Input) == "table" and cfg.Input or {}
local fr = new("Frame", { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, btnH), BackgroundColor3 = T.Control, BackgroundTransparency = 0.1, BorderSizePixel = 0, ZIndex = 3, Parent = body },
{ corner(8), stroke(T.Border, 1, 0.3), padding(10, 0, 10, 0) })
box = new("TextBox", {
Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = tostring(ic.Default or ""), PlaceholderText = tostring(ic.Placeholder or ""),
PlaceholderColor3 = T.SubText, TextColor3 = T.Text, Font = T.Font, TextSize = 14, TextXAlignment = LEFT, ClearTextOnFocus = false, ZIndex = 4, Parent = fr,
})
local maxLen = type(ic.MaxLength) == "number" and math.floor(ic.MaxLength) or 200
bag:Add(box:GetPropertyChangedSignal("Text"):Connect(function()
local t = box.Text
if ic.Numeric then t = t:gsub("[^%d%.%-]", "") end
if utf8.len(t) and utf8.len(t) > maxLen then t = Util.Truncate(t, maxLen, "") end
if t ~= box.Text then box.Text = t end
end))
bag:Add(box.Focused:Connect(function() tween(fr:FindFirstChildOfClass("UIStroke"), 0.15, { Color = accent, Transparency = 0.05 }) end))
bag:Add(box.FocusLost:Connect(function() tween(fr:FindFirstChildOfClass("UIStroke"), 0.2, { Color = T.Border, Transparency = 0.3 }) end))
dlg.box = box
end
local custom
if type(cfg.Build) == "function" then
custom = new("Frame", { LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, ZIndex = 3, Parent = body })
end
local buttons = type(cfg.Buttons) == "table" and cfg.Buttons or { { Text = "OK", Style = "Primary", Value = true } }
local n = math.min(#buttons, 4)
if n == 0 then buttons = { { Text = "OK", Style = "Primary", Value = true } } n = 1 end
local vertical = n > 2 or W < 280
local brow = new("Frame", { LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, ZIndex = 3, Parent = col },
{ list(8, { FillDirection = vertical and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal }) })
local btnObjs = {}
local function finish(value, input, reason)
if not dlg.open then return end
dlg.open = false
result.value, result.input, result.reason = value, input, reason
for i, d in ipairs(self.Dialogs) do
if d == dlg then table.remove(self.Dialogs, i) break end
end
local anim = NotifyCfg.Animate ~= false and not dlg.instant
local function cleanup()
bag:Destroy()
pcall(function() overlay:Destroy() end)
end
if anim then
tw(overlay, 0.14, { BackgroundTransparency = 1 }, SINE, IN)
tw(card, 0.12, { GroupTransparency = 1 }, SINE, IN)
task.delay(0.16, cleanup)
else
cleanup()
end
if cfg.OnClose then safe(cfg.OnClose, value, input, reason) end
for _, co in ipairs(waiters) do task.spawn(co, value, input) end
waiters = {}
end
dlg.destroy = function() dlg.instant = true finish(nil, nil, "destroyed") end
local function currentInput() return box and box.Text or nil end
local defaultBtn
for i = 1, n do
local b = buttons[i]
if type(b) == "string" then b = { Text = b } end
if type(b) ~= "table" then b = { Text = "OK" } end
local style = b.Style or (i == n and "Primary" or "Secondary")
local fill = Color3.new(1, 1, 1)
local btn = new("TextButton", {
LayoutOrder = (vertical and (n - i + 1)) or i, AutoButtonColor = false, Text = "", BackgroundColor3 = style == "Secondary" and T.Control or fill,
BackgroundTransparency = style == "Secondary" and 0.1 or 0, ZIndex = 3,
Size = vertical and UDim2.new(1, 0, 0, btnH) or UDim2.new(1 / n, -math.ceil(8 * (n - 1) / n), 0, btnH), Parent = brow,
}, { corner(14) })
if style == "Secondary" then
btn.BackgroundColor3 = T.Control
new("UIStroke", { Color = T.Border, Thickness = 1, Transparency = 0.35, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = btn })
feedback(btn, btn, "BackgroundColor3", T.Control, T.Lift, T.AccentSoft)
else
local c1 = style == "Danger" and Library.Kinds.Error.Color or accent
local g = gradient(c1, style == "Danger" and Util.Lighten(c1, 0.25) or accent2, 0)
g.Parent = btn
if style ~= "Danger" then table.insert(accentGrads, g) end
feedback(btn, btn, "BackgroundColor3", fill, Color3.fromRGB(236, 236, 236), Color3.fromRGB(200, 200, 200))
end
local btnLbl = new("TextLabel", {
Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = tostring(b.Text or "OK"), Font = style == "Secondary" and T.Font or T.FontBold,
TextSize = 14, TextColor3 = style == "Secondary" and T.SubText or (style == "Danger" and Color3.new(1, 1, 1) or Library.OnAccent(T)),
TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 4, Parent = btn,
}, { padding(8, 0, 8, 0) })
if style ~= "Secondary" and style ~= "Danger" then Library._oa(btnLbl) end
local value = b.Value
if value == nil then value = b.Text end
if b.Default or (style ~= "Secondary" and not defaultBtn) then defaultBtn = { btn = btn, b = b, value = value } end
local function fire()
if not dlg.open then return end
if b.Callback then safe(b.Callback, handle, currentInput()) end
if b.Close ~= false then finish(value, currentInput(), "button") end
end
bag:Add(btn.MouseButton1Click:Connect(fire))
btnObjs[i] = { btn = btn, fire = fire }
end
if box then
bag:Add(box.FocusLost:Connect(function(enter)
if enter and defaultBtn then
for _, bo in ipairs(btnObjs) do
if bo.btn == defaultBtn.btn then bo.fire() end
end
end
end))
end
local function paintAccent()
if dlgStroke then dlgStroke.Color = accent end
dlgTint.BackgroundColor3 = accent
scroll.ScrollBarImageColor3 = accent
for _, g in ipairs(accentGrads) do g.Color = ColorSequence.new(accent, accent2) end
end
local function setHead()
titleL.Text = tostring(cfg.Title or "")
head.Visible = (cfg.Title ~= nil and cfg.Title ~= "") or kind ~= nil or cfg.Icon ~= nil
contentL.Text = tostring(cfg.Content or "")
contentL.Visible = cfg.Content ~= nil and cfg.Content ~= ""
for _, c in ipairs(iconSlot:GetChildren()) do c:Destroy() end
local icon = cfg.Icon
if icon == nil and kind then icon = Library.Kinds[kind].Icon end
iconSlot.Visible = icon ~= nil and icon ~= false
if iconSlot.Visible then buildIcon(iconSlot, icon, accent, T, 24, nil) end
end
setHead()
if custom then
local ok, err = pcall(cfg.Build, custom, T, handle)
if not ok then warn("[SpectreUI] Dialog Build failed: " .. tostring(err)) end
end
local pending = false
local function fit()
if not dlg.open then return end
local vp = Responsive.Viewport(owner)
local used = head.AbsoluteSize.Y + brow.AbsoluteSize.Y + 12 * 2 + 18 + 16
local avail = math.max(vp.Y - 24 - used, 48)
local want = math.min(body.AbsoluteSize.Y, avail)
if want > 0 and math.abs(scroll.Size.Y.Offset - want) > 0.5 then scroll.Size = UDim2.new(1, 0, 0, want) end
local w = Responsive.Width(owner, math.floor(Util.Opt(cfg, "Width", "number", 340, 220, 560)), 16)
if card.Size.X.Offset ~= w then card.Size = UDim2.fromOffset(w, 0) end
end
dlg.fit = fit
local function fitSoon()
if pending then return end
pending = true
task.defer(function() pending = false fit() end)
end
bag:Add(body:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitSoon))
bag:Add(head:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitSoon))
bag:Add(brow:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitSoon))
bag:Add(gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitSoon))
local function dismiss(reason)
if dismissable and dlg.open then finish(nil, currentInput(), reason) end
end
bag:Add(outside.MouseButton1Click:Connect(function() dismiss("overlay") end))
bag:Add(UserInputService.InputBegan:Connect(function(i)
if i.KeyCode == Enum.KeyCode.Escape and self.Dialogs[#self.Dialogs] == dlg then dismiss("escape") end
end))
handle.Close = method(handle, function(value) finish(value, currentInput(), "api") return true end)
handle.IsOpen = method(handle, function() return dlg.open end)
handle.IsAlive = handle.IsOpen
handle.GetInput = method(handle, function() return currentInput() end)
handle.Update = method(handle, function(patch)
if not dlg.open or type(patch) ~= "table" then return false end
if patch.Title ~= nil then cfg.Title = patch.Title end
if patch.Content ~= nil then cfg.Content = patch.Content end
if patch.Kind ~= nil then
kind = normKind(patch.Kind)
cfg.Kind = patch.Kind
accent = (kind and Library.Kinds[kind].Color) or T.Accent
accent2 = (kind and Util.Lighten(accent, 0.35)) or T.Accent2
paintAccent()
end
if patch.Icon ~= nil then cfg.Icon = patch.Icon end
setHead()
return handle
end)
handle.Wait = method(handle, function()
if not dlg.open then return result.value, result.input end
table.insert(waiters, coroutine.running())
return coroutine.yield()
end)
handle.Id = depth
table.insert(self.Dialogs, dlg)
bag:Add(overlay.Destroying:Connect(function()
if dlg.open then
dlg.instant = true
finish(nil, nil, "destroyed")
end
end))
if NotifyCfg.Animate ~= false then
tw(overlay, 0.15, { BackgroundTransparency = 0.5 }, SINE, OUT)
card.GroupTransparency = 1
card.Visible = true
nextFrame(function()
if not dlg.open or not card.Parent then return end
fit()
nextFrame(function()
if not dlg.open or not card.Parent then return end
tw(card, 0.15, { GroupTransparency = 0 }, SINE, OUT)
end)
end)
else
overlay.BackgroundTransparency = 0.5
card.Visible = true
card.GroupTransparency = 0
end
if box and not touch and (type(cfg.Input) ~= "table" or cfg.Input.AutoFocus ~= false) then
bag:Add(task.delay(0.25, function() if dlg.open and box.Parent then box:CaptureFocus() end end))
end
return handle
end
function NM:Confirm(cfg)
if type(cfg) ~= "table" then cfg = {} end
local choice
return self:Dialog({
Title = cfg.Title or "Confirm", Content = cfg.Content, Kind = cfg.Kind, Icon = cfg.Icon, Width = cfg.Width, Dismissable = cfg.Dismissable,
Buttons = {
{ Text = cfg.No or "Cancel", Style = "Secondary", Value = false, Callback = function() choice = false end },
{ Text = cfg.Yes or "Confirm", Style = cfg.Danger and "Danger" or "Primary", Value = true, Callback = function() choice = true end },
},
OnClose = function(value, _, reason)
if value == true then safe(cfg.OnYes) else safe(cfg.OnNo) end
safe(cfg.OnClose, value == true, reason)
end,
})
end
function NM:Alert(cfg)
if type(cfg) ~= "table" then cfg = {} end
return self:Dialog({
Title = cfg.Title or "Notice", Content = cfg.Content, Kind = cfg.Kind, Icon = cfg.Icon, Width = cfg.Width, Dismissable = cfg.Dismissable,
Buttons = { { Text = cfg.Ok or "OK", Style = "Primary", Value = true } },
OnClose = function(value, _, reason) safe(cfg.OnClose, value, reason) end,
})
end
function NM:Prompt(cfg)
if type(cfg) ~= "table" then cfg = {} end
return self:Dialog({
Title = cfg.Title or "Input", Content = cfg.Content, Kind = cfg.Kind, Icon = cfg.Icon, Width = cfg.Width, Dismissable = cfg.Dismissable,
Input = { Placeholder = cfg.Placeholder, Default = cfg.Default, MaxLength = cfg.MaxLength, Numeric = cfg.Numeric, AutoFocus = cfg.AutoFocus },
Buttons = {
{ Text = cfg.No or "Cancel", Style = "Secondary", Value = false },
{ Text = cfg.Yes or "OK", Style = "Primary", Value = true },
},
OnClose = function(value, input, reason)
if value == true then safe(cfg.OnSubmit, input) else safe(cfg.OnCancel) end
safe(cfg.OnClose, value == true and input or nil, reason)
end,
})
end
function NM:Loading(cfg)
if type(cfg) == "string" then cfg = { Text = cfg } end
if type(cfg) ~= "table" then cfg = {} end
local c = table.clone(cfg)
c.Kind = "Loading"
c.Title = c.Title or "Loading"
if c.Text ~= nil and c.Content == nil then c.Content = c.Text end
c.Duration = false
c.Closable = c.Closable == true
if type(c.Progress) ~= "number" then c.Progress = nil end
local h = self:Add(c, "loading")
if not h or h.Id == 0 then return h end
local nm = self
local base = h
local entryOf = function() return nm:_Each(function(e) return e.handle == base end) end
local function patch(p)
local e = entryOf()
if not e then return false end
return nm:_Update(e, p)
end
base.Set = method(base, function(progress, text)
local p = {}
if type(progress) == "number" then p.Progress = progress elseif progress == false then p.Progress = true end
if text ~= nil then p.Content = text end
return patch(p) and base or false
end)
base.SetText = method(base, function(text) return patch({ Content = text }) and base or false end)
base.Complete = method(base, function(text, secs)
return patch({ Kind = "Success", Title = "Done", Content = text or "", Progress = true, Duration = secs or 2.5, Closable = true }) and base or false
end)
base.Fail = method(base, function(text, secs)
return patch({ Kind = "Error", Title = "Failed", Content = text or "", Progress = true, Duration = secs or 4, Closable = true }) and base or false
end)
return base
end
local function mergeCfg(first, extra, field)
local cfg = {}
if type(first) == "table" then
for k, v in pairs(first) do cfg[k] = v end
elseif first ~= nil then
cfg[field or "Content"] = first
end
if type(extra) == "table" then
for k, v in pairs(extra) do cfg[k] = v end
elseif type(extra) == "string" then
cfg.Kind = extra
elseif type(extra) == "number" then
cfg.Duration = extra
end
return cfg
end
function Window:_NM()
if self._destroyed then return nil end
if not self._nm or self._nm.Dead then self._nm = NM.new(self) end
return self._nm
end
local function guarded(label, fn)
local ok, res = pcall(fn)
if ok and res then return res end
if not ok then warn("[SpectreUI] " .. label .. " failed: " .. tostring(res)) end
return deadHandle()
end
function Window:Notify(cfg)
return guarded("Notify", function()
local nm = self:_NM()
return nm and nm:Add(cfg, "notify")
end)
end
for kind in pairs({ Success = true, Warning = true, Error = true, Info = true }) do
Window[kind] = function(self, title, content, dur)
local cfg
if type(title) == "table" then
cfg = table.clone(title)
else
cfg = { Title = title, Content = content, Duration = dur }
end
cfg.Kind = kind
return self:Notify(cfg)
end
end
function Window:Toast(text, opts)
return guarded("Toast", function()
local nm = self:_NM()
return nm and nm:Add(mergeCfg(text, opts), "toast")
end)
end
function Window:Banner(cfg)
return guarded("Banner", function()
local nm = self:_NM()
return nm and nm:Add(mergeCfg(cfg, nil, "Title"), "banner")
end)
end
function Window:Loading(cfg)
return guarded("Loading", function()
local nm = self:_NM()
return nm and nm:Loading(cfg)
end)
end
function Window:Dialog(cfg) return guarded("Dialog", function() local nm = self:_NM() return nm and nm:Dialog(cfg) end) end
function Window:Confirm(cfg) return guarded("Confirm", function() local nm = self:_NM() return nm and nm:Confirm(cfg) end) end
function Window:Alert(a, b)
local cfg = type(a) == "table" and a or { Title = a, Content = b }
return guarded("Alert", function() local nm = self:_NM() return nm and nm:Alert(cfg) end)
end
function Window:Prompt(cfg) return guarded("Prompt", function() local nm = self:_NM() return nm and nm:Prompt(cfg) end) end
function Window:DismissAll(reason)
if self._nm then self._nm:DismissAll(reason) end
end
function Window:SetNotifyTheme(t)
if t == nil then
self._nTheme = nil
return true
end
local src = type(t) == "string" and Library.Themes[t] or t
if type(src) ~= "table" then return false end
self._nTheme = deriveTheme(buildTheme(src))
return true
end
function Library:_Host()
local w = self.Windows[#self.Windows]
if w then return w:_NM() end
if not self._nm or self._nm.Dead then self._nm = NM.new({ Headless = true }) end
return self._nm
end
function Library:Notify(cfg) return guarded("Notify", function() return self:_Host():Add(cfg, "notify") end) end
function Library:Toast(text, opts) return guarded("Toast", function() return self:_Host():Add(mergeCfg(text, opts), "toast") end) end
function Library:Banner(cfg) return guarded("Banner", function() return self:_Host():Add(mergeCfg(cfg, nil, "Title"), "banner") end) end
function Library:Loading(cfg) return guarded("Loading", function() return self:_Host():Loading(cfg) end) end
function Library:Dialog(cfg) return guarded("Dialog", function() return self:_Host():Dialog(cfg) end) end
function Library:Confirm(cfg) return guarded("Confirm", function() return self:_Host():Confirm(cfg) end) end
function Library:Alert(a, b)
local cfg = type(a) == "table" and a or { Title = a, Content = b }
return guarded("Alert", function() return self:_Host():Alert(cfg) end)
end
function Library:Prompt(cfg) return guarded("Prompt", function() return self:_Host():Prompt(cfg) end) end
function Library:DismissAll(reason)
for _, w in ipairs(self.Windows) do w:DismissAll(reason) end
if self._nm then self._nm:DismissAll(reason) end
end
Library._NM = NM
function Window:CreateTab(cfg)
if type(cfg) == "string" then cfg = { Name = cfg } end
cfg = cfg or {}
local T = self.Theme
local tab = setmetatable({ Window = self, Name = cfg.Name or "Tab", Sections = {} }, Tab)
local touchTab = false
local tabH = tonumber(self.Cfg and self.Cfg.TabHeight) or 40
local iconX, iconSz = 28, 20
local lblX = touchTab and 40 or 54
self._tabIconX = iconX
local btn = new("TextButton", {
LayoutOrder = #self.Tabs + 1, Size = UDim2.new(1, 0, 0, tabH),
BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, AutoButtonColor = false, Text = "", ClipsDescendants = true, Parent = self.TabList,
}, { corner(10), stroke(T.Accent, 1, 1), gradient(T.AccentSoft, T.AccentSoft, 0) })
tab.Button = btn
tab.BtnStroke = btn:FindFirstChildOfClass("UIStroke")
tab.BtnStroke.Transparency = 1
tab.BtnGrad = btn:FindFirstChildOfClass("UIGradient")
tab.Indicator = new("Frame", {
AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0), Size = UDim2.new(0, 4, 0, 0),
BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = btn,
}, { corner(4), gradient(T.Accent, T.Accent2, 90) })
local ic = cfg.Icon
local function wrapIcon(el)
return new("Frame", {
AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, iconX, 0.5, 0), Size = UDim2.fromOffset(iconSz, iconSz),
BackgroundTransparency = 1, Parent = btn,
}, { new("UIScale", { Scale = 1, Name = "IS" }), el })
end
local iconDesc = Library:IsIconName(ic) and Library:ResolveIcon(ic) or nil
if iconDesc then
tab.Icon = Library:MakeIcon(iconDesc, T.SubText)
elseif type(ic) == "number" or (type(ic) == "string" and ic:find("^rbxasset")) then
tab.Icon = new("ImageLabel", {
Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
Image = type(ic) == "number" and ("rbxassetid://" .. ic) or ic, ImageColor3 = T.SubText,
})
else
tab.Icon = new("TextLabel", {
Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
Text = (not Library:IsIconName(ic) and ic) or tab.Name:sub(1, 1):upper(), Font = T.FontBold, TextSize = touchTab and 17 or 18, TextColor3 = T.SubText,
})
end
tab.IconWrap = wrapIcon(tab.Icon)
tab.IconScale = tab.IconWrap:FindFirstChild("IS")
if not iconDesc and Library:IsIconName(ic) and not Library._iconUserSet then
table.insert(Library._iconReady, function()
if self._destroyed or not tab.IconWrap or not tab.IconWrap.Parent then return end
local d = Library:ResolveIcon(ic)
if not d then return end
local fresh = Library:MakeIcon(d, T.SubText)
if tab.Icon then tab.Icon:Destroy() end
fresh.Parent = tab.IconWrap
tab.Icon = fresh
if self.Active == tab then tab:_SetSelected(true) end
end)
end
tab._lblX = lblX
tab._lblBase = touchTab and 14 or 15
tab.Label = new("TextLabel", {
Position = UDim2.fromOffset(lblX, 0), Size = UDim2.new(1, -(lblX + 6), 1, 0), BackgroundTransparency = 1, Text = tab.Name,
Font = T.Font, TextSize = touchTab and 14 or 15, TextColor3 = T.SubText, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = btn,
})
tab.Label:SetAttribute("SGSkip", true)
tab._locked = false
tab.LockReason = cfg.LockReason
tab.Cfg = cfg
tab.LockIcon = new("Frame", {
Name = "Lock", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(14, 14),
BackgroundTransparency = 1, Visible = false, ZIndex = 3, Parent = btn,
}, {
new("Frame", {
AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.fromOffset(8, 9),
BackgroundTransparency = 1, ZIndex = 3,
}, { corner(4), stroke(T.SubText, 1.6, 0) }),
new("Frame", {
AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.fromOffset(12, 8),
BackgroundColor3 = T.SubText, BorderSizePixel = 0, ZIndex = 4,
}, { corner(3) }),
})
tab:_ApplyCompact(self.Compact or false)
btn.MouseEnter:Connect(function()
if usingTouch() or self.Active == tab or tab._slLoaded == false then return end
tween(tab.Label, 0.14, { TextColor3 = T.Text })
tween(btn, 0.14, { BackgroundTransparency = 0.7 })
end)
btn.MouseLeave:Connect(function()
if self.Active ~= tab then
tween(tab.Label, 0.14, { TextColor3 = T.SubText })
tween(btn, 0.16, { BackgroundTransparency = 1 })
end
end)
local savedSeq
local press = dragSafePress(btn, function(i)
if self.Active ~= tab and tab._slLoaded ~= false then
if tab.BtnGrad then savedSeq = tab.BtnGrad.Color tab.BtnGrad.Color = ColorSequence.new(T.Lift or T.Control) end
tween(btn, 0.06, { BackgroundTransparency = 0.45 })
end
end, function(cancelled)
if savedSeq and tab.BtnGrad then tab.BtnGrad.Color = savedSeq savedSeq = nil end
if self.Active ~= tab then tween(btn, 0.16, { BackgroundTransparency = 1 }) end
end, 12)
clickRipple(btn, press)
btn.MouseButton1Click:Connect(function()
if press.moved then return end
if tab._lpFired then tab._lpFired = false return end
self:SelectTab(tab)
end)
tab.Page = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = self.Pages })
tab.Scroll = new("Frame", { Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -32, 1, 0), BackgroundTransparency = 1, Parent = tab.Page },
{ list(12, { FillDirection = Enum.FillDirection.Horizontal }) })
tab.Cols = {}
for i = 1, 2 do
tab.Cols[i] = new("ScrollingFrame", {
LayoutOrder = i, Size = UDim2.new(0.5, -6, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
ScrollBarThickness = 3,
ScrollBarImageColor3 = T.Accent, CanvasSize = UDim2.new(), AutomaticCanvasSize = AY,
ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Never, Parent = tab.Scroll,
}, { list(12), padding(0, 0, 0, 8) })
end
tab.Fades = {}
do
local fadeCol = T.Top:Lerp(T.Background, 0.15)
for i = 1, 2 do
local col = tab.Cols[i]
local fade = new("Frame", {
Name = "ColFade", Position = i == 1 and UDim2.fromOffset(12, 0) or UDim2.new(0.5, 2, 0, 0),
Size = UDim2.new(0.5, -22, 0, 18), BackgroundColor3 = fadeCol, BackgroundTransparency = 1,
BorderSizePixel = 0, Active = false, ZIndex = 8, Parent = tab.Page,
}, { new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({
NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.5, 0.62), NumberSequenceKeypoint.new(1, 1),
}) }) })
tab.Fades[i] = fade
col:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
local bt = 1 - math.clamp(col.CanvasPosition.Y / 20, 0, 1)
if math.abs(fade.BackgroundTransparency - bt) > 0.02 then fade.BackgroundTransparency = bt end
end)
end
end
table.insert(self.Tabs, tab)
if cfg.Locked then tab:SetLocked(true, cfg.LockReason) end
if not self.Active then self:SelectTab(tab) end
self:_IntroTab(tab)
return tab
end
function Tab:SetLocked(v, reason)
v = v and true or false
if reason ~= nil then self.LockReason = reason end
if self._locked == v then return self end
self._locked = v
local win = self.Window
local T = win.Theme
self.LockIcon.Visible = v
local dim = v and 0.55 or 0
tween(self.Label, 0.2, { TextTransparency = dim })
local prop = self.Icon:IsA("ImageLabel") and "ImageTransparency" or "TextTransparency"
tween(self.Icon, 0.2, { [prop] = dim })
for _, part in ipairs(self.Icon:GetChildren()) do
if part:IsA("ImageLabel") then tween(part, 0.2, { ImageTransparency = dim }) end
end
self:_FitLabel()
if v and win.Active == self then
for _, t in ipairs(win.Tabs) do
if t ~= self and not t._locked then win:SelectTab(t) break end
end
elseif not v and not win.Active then
win:SelectTab(self)
end
return self
end
function Tab:Lock(reason) return self:SetLocked(true, reason) end
function Tab:Unlock() return self:SetLocked(false) end
function Tab:IsLocked() return self._locked == true end
function Tab:SetLockReason(text) self.LockReason = text return self end
function Window:_LockedFeedback(tab)
local now = os.clock()
if tab.LockIcon then
task.spawn(function()
for _, r in ipairs({ -18, 16, -10, 6, 0 }) do
if not tab.LockIcon.Parent then return end
tween(tab.LockIcon, 0.055, { Rotation = r })
task.wait(0.055)
end
end)
end
safe(tab.Cfg and tab.Cfg.OnLockedClick, tab)
if tab.Cfg and tab.Cfg.LockedNotify == false then return end
if (tab._lockToast or 0) + 1.5 > now then return end
tab._lockToast = now
pcall(function()
self:Warning(tab.Name .. " is locked", tab.LockReason or "This tab is locked.", 2.5)
end)
end
local function findTab(win, nameOrTab)
return type(nameOrTab) == "string" and win:GetTab(nameOrTab) or nameOrTab
end
function Window:LockTab(nameOrTab, reason)
local t = findTab(self, nameOrTab)
if t then t:SetLocked(true, reason) end
return t
end
function Window:UnlockTab(nameOrTab)
local t = findTab(self, nameOrTab)
if t then t:SetLocked(false) end
return t
end
function Window:IsTabLocked(nameOrTab)
local t = findTab(self, nameOrTab)
return t ~= nil and t._locked == true
end
function Tab:_ApplyCompact(c)
self.Label.Visible = not c
if self.LockIcon then
self.LockIcon.Position = c and UDim2.new(1, -4, 0, 12) or UDim2.new(1, -12, 0.5, 0)
end
self.IconWrap.Position = c and UDim2.fromScale(0.5, 0.5) or UDim2.new(0, self.Window._tabIconX or 26, 0.5, 0)
end
function Tab:_SetSelected(sel)
local T = self.Window.Theme
tween(self.Button, 0.22, { BackgroundTransparency = sel and 0 or 1 })
tween(self.BtnStroke, 0.22, { Transparency = sel and 0.8 or 1 })
tween(self.Indicator, 0.18, { Size = UDim2.new(0, 4, sel and 0.55 or 0, 0) })
tween(self.Label, 0.22, { TextColor3 = sel and T.Text or T.SubText })
local prop = self.Icon:IsA("ImageLabel") and "ImageColor3" or "TextColor3"
local icol = T.SubText
if sel then
icol = T.Accent
if math.max(icol.R, icol.G, icol.B) > 0.85 then icol = icol:Lerp(T.SubText, 0.4) end
end
tween(self.Icon, 0.22, { [prop] = icol })
for _, part in ipairs(self.Icon:GetChildren()) do
if part:IsA("ImageLabel") then tween(part, 0.22, { ImageColor3 = icol }) end
end
if sel and self.IconScale then
self.IconScale.Scale = 1
end
if self.BtnGrad then
self.BtnGrad.Color = cseq({ 0, T.AccentSoft }, { 1, T.AccentSoft })
end
end
function Tab:SetScrollEnabled(v)
for _, c in ipairs(self.Cols) do c.ScrollingEnabled = v and true or false end
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
if c2.Visible ~= (two and true or false) then c2.Visible = two and true or false end
local want1 = two and UDim2.new(0.5, -6, 1, 0) or UDim2.new(1, 0, 1, 0)
if c1.Size ~= want1 then c1.Size = want1 end
local f1, f2 = self.Fades and self.Fades[1], self.Fades and self.Fades[2]
if f1 and f2 then
local fs = two and UDim2.new(0.5, -22, 0, 18) or UDim2.new(1, -32, 0, 18)
if f1.Size ~= fs then f1.Size = fs end
if f2.Visible ~= (two and true or false) then f2.Visible = two and true or false end
end
local h1, h2 = 0, 0
for i, s in ipairs(self.Sections) do
local col
if not two then col = 1
elseif s.Column then col = s.Column
else col = (h1 <= h2) and 1 or 2 end
if s.Frame.LayoutOrder ~= i then s.Frame.LayoutOrder = i end
local target = (col == 1) and c1 or c2
if s.Frame.Parent ~= target then s.Frame.Parent = target end
if s.Frame.Visible then
if col == 1 then h1 += s.Est + 12 else h2 += s.Est + 12 end
end
end
end
function Tab:CreateSection(cfg)
if type(cfg) == "string" then cfg = { Name = cfg } end
cfg = cfg or {}
local T = self.Window.Theme
local s = setmetatable({
Tab = self, Window = self.Window, Name = cfg.Name or "Section", Controls = {}, Est = 35 + 20, Column = cfg.Column,
}, Section)
s.Frame = new("Frame", {
Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundColor3 = T.Card, BackgroundTransparency = (function(b) return b + (1 - b) * (self.Window.Glass or 0) end)(self.Window.FXOn and 0.2 or 0),
BorderSizePixel = 0, Parent = self.Cols[1],
}, { corner(14), stroke(T.Border, 1, 0.45), list(0, { HorizontalAlignment = Enum.HorizontalAlignment.Center }),
wash(cseq({ 0, T.Top }, { 1, T.Card }), 90) })
if self.Window._flat then
local g = s.Frame:FindFirstChildOfClass("UIGradient")
if g then g.Enabled = false end
end
local collapsible = cfg.Collapsible ~= false
local head = new("TextButton", {
LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = T.Control, BackgroundTransparency = 1,
Text = "", AutoButtonColor = false, Parent = s.Frame,
}, { corner(12) })
if collapsible then feedback(head, head, "BackgroundTransparency", 1, 0.85, 0.7, true) end
local secIcon = Library:IsIconName(cfg.Icon) and Library:ResolveIcon(cfg.Icon) or nil
if secIcon then
local im = Library:MakeIcon(secIcon, T.Accent)
im.AnchorPoint = Vector2.new(0, 0.5)
im.Position = UDim2.new(0, 12, 0.5, 0)
im.Size = UDim2.fromOffset(22, 22)
im.Parent = head
else
new("Frame", {
AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.fromOffset(6, 6),
BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = head,
}, { corner(3), gradient(T.Accent, T.Accent2, 0) })
end
new("TextLabel", {
Position = UDim2.fromOffset(secIcon and 42 or 28, 0), Size = UDim2.new(1, secIcon and -72 or -58, 1, 0), BackgroundTransparency = 1, Text = s.Name,
Font = T.FontBold, TextSize = 15, TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = head,
})
local arrow
do
local chev = Library:ResolveIcon("lucide:chevron-down")
if chev then
arrow = Library:MakeIcon(chev, T.SubText)
arrow.AnchorPoint = Vector2.new(1, 0.5)
arrow.Position = UDim2.new(1, -12, 0.5, 0)
arrow.Size = UDim2.fromOffset(20, 20)
arrow.Visible = collapsible
arrow.Parent = head
else
arrow = new("TextLabel", {
AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(16, 16),
BackgroundTransparency = 1, Text = "▼", Font = T.FontBold, TextSize = 14, TextColor3 = T.Accent,
Visible = collapsible, Parent = head,
})
end
end
new("Frame", {
LayoutOrder = 2, Size = UDim2.new(1, -24, 0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.55,
BorderSizePixel = 0, Parent = s.Frame,
}, { gradient(cseq({ 0, T.Border }, { 1, T.Border }), 0) })
s.Body = new("Frame", {
LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Parent = s.Frame,
}, { list(8), padding(12, 12, 12, 14) })
s.Body:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
if s.Body.AutomaticSize == AY and s.Body.Visible then
local h = s.Body.AbsoluteSize.Y / math.max(s.Window.Scale.Scale, 0.01)
if h > 0 then s._bodyH = h end
end
end)
local function restoreRows()
local hid = s._hidRows
if not hid then return end
s._hidRows = nil
for _, k in ipairs(hid) do
if k.Parent == s.Body then k.Visible = true end
end
end
function s:SetCollapsed(c, instant)
c = c and true or false
if not instant and #self.Controls > (Library.Perf.CollapseAnimMax or 24) then instant = true end
local cur = self.Collapsed and true or false
self.Collapsed = c
tween(arrow, 0.22, { Rotation = c and -90 or 0 })
local b = self.Body
if c == cur then
b.Visible = not c
return
end
self._cseq = (self._cseq or 0) + 1
local seq = self._cseq
local scale = math.max(self.Window.Scale.Scale, 0.01)
local running = b.AutomaticSize == ANONE
local curH = b.Visible and (b.AbsoluteSize.Y / scale) or 0
if not running and curH > 0 then self._bodyH = curH end
local full = self._bodyH
local function settle()
b.ClipsDescendants = false
b.AutomaticSize = AY
b.Size = UDim2.new(1, 0, 0, 0)
end
if c then
if instant or curH <= 0 then
b.Visible = false
settle()
return
end
self.Window:_MotionBegin(0.3, true)
b.ClipsDescendants = true
b.AutomaticSize = ANONE
b.Size = UDim2.new(1, 0, 0, curH)
restoreRows()
local hid = {}
for _, k in ipairs(b:GetChildren()) do
if k:IsA("GuiObject") and k.Visible then
k.Visible = false
hid[#hid + 1] = k
end
end
self._hidRows = hid
tween(b, 0.2, { Size = UDim2.new(1, 0, 0, 0) }, QUAD, Enum.EasingDirection.InOut).Completed:Connect(function()
if self._cseq ~= seq then return end
b.Visible = false
settle()
end)
else
b.Visible = true
restoreRows()
if instant or not full or full <= 0 then
settle()
return
end
self.Window:_MotionBegin(0.34, true)
b.ClipsDescendants = true
b.AutomaticSize = ANONE
b.Size = UDim2.new(1, 0, 0, curH)
nextFrame(function()
if self._cseq ~= seq then return end
tween(b, 0.28, { Size = UDim2.new(1, 0, 0, full) }, QUINT, OUT).Completed:Connect(function()
if self._cseq ~= seq then return end
settle()
end)
end)
end
end
if collapsible then
head.MouseButton1Click:Connect(function() s:SetCollapsed(not s.Collapsed) end)
end
if cfg.Collapsed then s:SetCollapsed(true, true) end
table.insert(self.Sections, s)
self:_QueueRelayout()
return s
end
function Section:_Register(frame, name, est)
local win = self.Window
local P = Library.Perf
local nowT = os.clock()
local budget = (nowT - (win._lastTouch or 0) < 0.4) and (P.SliceBudgetBusy or 0.002) or (P.SliceBudget or 0.008)
if win._slThread and P.Slice ~= false and coroutine.running() == win._slThread
and nowT - (win._sliceT or 0) > budget then
task.wait()
if win._destroyed then error("window destroyed while loading", 0) end
win._sliceT = os.clock()
end
table.insert(self.Controls, { Frame = frame, Name = (name or ""):lower() })
frame.LayoutOrder = #self.Controls
self.Est += est + 6
self.Tab:_QueueRelayout()
end
local function setFlag(cfg, v)
if cfg.Flag then
local prev = Library.Flags[cfg.Flag]
Library.Flags[cfg.Flag] = v
if prev ~= v then
for _, cb in ipairs(Library._flagCbs) do safe(cb, cfg.Flag, v, prev) end
end
end
end
local function regObj(cfg, obj)
if cfg.Flag then Library.Objects[cfg.Flag] = obj end
return obj
end
function Section:CreateLabel(cfg)
if type(cfg) == "string" then cfg = { Text = cfg } end
cfg = cfg or {}
local T = self.Window.Theme
local l = new("TextLabel", {
Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Text = cfg.Text or cfg.Name or "",
Font = cfg.Bold and T.FontBold or T.Font, TextSize = cfg.TextSize or 13, TextColor3 = cfg.Color or T.SubText,
TextXAlignment = LEFT, TextWrapped = true, Parent = self.Body,
})
self:_Register(l, cfg.Text or cfg.Name, 18)
local obj = { Frame = l }
function obj:Set(t) l.Text = t end
function obj:SetColor(c) l.TextColor3 = c end
return obj
end
function Section:CreateDivider()
local T = self.Window.Theme
local d = new("Frame", {
Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.45, BorderSizePixel = 0, Parent = self.Body,
}, { gradient(cseq({ 0, Color3.new(1, 1, 1) }, { 0.5, T.Accent }, { 1, Color3.new(1, 1, 1) }), 0) })
d:FindFirstChildOfClass("UIGradient").Transparency = NumberSequence.new({
NumberSequenceKeypoint.new(0, 0.5),
NumberSequenceKeypoint.new(0.5, 0.2),
NumberSequenceKeypoint.new(1, 0.5),
})
self:_Register(d, "", 1)
return { Frame = d }
end
function Library._bevel(btn, base, sunken)
if false and not sunken and btn and not lowPower() and not btn:FindFirstChild("SoftSheen") then
new("Frame", { Name = "SoftSheen", Size = UDim2.new(1, 0, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1),
BackgroundTransparency = 0.93, BorderSizePixel = 0, ZIndex = 5, Active = false, Parent = btn },
{ new("UICorner", { CornerRadius = UDim.new(0, 8) }),
new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0, 1) }) })
end
return function() end
end
function Section:CreateButton(cfg)
local T = self.Window.Theme
local R = math.clamp(tonumber(cfg.Radius) or 8, 0, 16)
local accent = cfg.Color
local grad = cfg.Gradient
local gradLabel
local gradText = cfg.TextColor or (grad and Library.OnAccent(grad[1], grad[2] or grad[1])) or nil
local gradTracks = grad and not cfg.TextColor and grad[1] == T.Accent
local b = new("TextButton", {
Size = UDim2.new(1, 0, 0, rowH()), BackgroundColor3 = grad and Color3.new(1, 1, 1) or (accent or T.Control),
BackgroundTransparency = 0.1, AutoButtonColor = false,
Text = cfg.Name or "Button", Font = cfg.Bold and T.FontBold or T.Font, TextSize = 14,
TextColor3 = cfg.TextColor or (accent and Library.OnAccent(accent)) or T.Text, TextTruncate = Enum.TextTruncate.AtEnd, ClipsDescendants = true, Parent = self.Body,
}, { new("UICorner", { CornerRadius = UDim.new(0, R) }), stroke(grad and (grad[2] or T.Accent2) or (accent and accent:Lerp(Color3.new(1, 1, 1), 0.3) or T.Border), 1, grad and 0.5 or 0.35) })
if grad then
b.BackgroundColor3 = Color3.new(1, 1, 1)
b.BackgroundTransparency = 0
new("UIGradient", { Color = ColorSequence.new(grad[1], grad[2] or grad[1]), Parent = b })
b.Text = ""
gradLabel = new("TextLabel", {
Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = cfg.Name or "Button",
Font = cfg.Bold and T.FontBold or T.Font, TextSize = 14, TextColor3 = gradText, TextTruncate = Enum.TextTruncate.AtEnd, Parent = b,
})
if gradTracks then Library._oa(gradLabel) end
end
local bIcon = Library:IsIconName(cfg.Icon) and Library:ResolveIcon(cfg.Icon) or nil
if bIcon then
local im = Library:MakeIcon(bIcon, gradText or (accent and Library.OnAccent(accent)) or T.Text)
if gradTracks then Library._oa(im) end
im.AnchorPoint = Vector2.new(0, 0.5)
im.Position = UDim2.new(0, 12, 0.5, 0)
im.Size = UDim2.fromOffset(20, 20)
im.ZIndex = b.ZIndex + 1
im.Parent = b
end
new("Frame", {
Size = UDim2.fromScale(1, 0.55), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Active = false, ZIndex = 3, Visible = false, Parent = b,
}, {
new("UICorner", { CornerRadius = UDim.new(0, R) }),
new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, grad and 0.86 or 0.9), NumberSequenceKeypoint.new(1, 1) }) }),
})
local bStroke = b:FindFirstChildOfClass("UIStroke")
local shade
if grad or accent then
shade = new("Frame", {
Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
BorderSizePixel = 0, ZIndex = 4, Parent = b,
}, { new("UICorner", { CornerRadius = UDim.new(0, R) }) })
end
if not (grad or accent) then
local bar = new("Frame", {
AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0), Size = UDim2.new(0, 3, 0, 0),
BackgroundColor3 = T.Accent, BorderSizePixel = 0, ZIndex = 5, Parent = b,
}, { new("UICorner", { CornerRadius = UDim.new(1, 0) }) })
b.MouseEnter:Connect(function()
if usingTouch() then return end
bar.BackgroundColor3 = T.Accent
tween(bar, 0.2, { Size = UDim2.new(0, 3, 0.55, 0) }, BACK, OUT)
if bStroke then tween(bStroke, 0.16, { Color = T.Accent }) end
end)
b.MouseLeave:Connect(function()
tween(bar, 0.16, { Size = UDim2.new(0, 3, 0, 0) }, SINE, OUT)
if bStroke then tween(bStroke, 0.18, { Color = T.Border }) end
end)
end
dragSafePress(b, function()
if shade then tween(shade, 0.07, { BackgroundTransparency = 0.8 }, SINE, OUT) end
end, function()
if shade then tween(shade, 0.26, { BackgroundTransparency = 1 }, SINE, OUT) end
end, 10)
if grad or accent then
strokeFeedback(b, bStroke, grad and 0.5 or 0.3, 0.05)
else
feedback(b, b, "BackgroundColor3", T.Control, T.Lift, T.AccentSoft)
strokeFeedback(b, bStroke, 0.35, 0.05)
end
local spinOn = cfg.Spin == true
local spinScale = new("UIScale", { Scale = 1, Parent = b })
local spinSeq = 0
local function spin()
spinSeq = spinSeq + 1
local seq = spinSeq
local dur = tonumber(cfg.SpinTime) or 0.5
local turns = tonumber(cfg.Turns) or 1
b.Rotation = 0
tween(b, dur, { Rotation = 360 * turns }, QUINT, OUT)
tween(spinScale, dur * 0.35, { Scale = 0.82 }, SINE, OUT)
task.delay(dur * 0.35, function()
if seq == spinSeq and spinScale.Parent then tween(spinScale, dur * 0.65, { Scale = 1 }, BACK, OUT) end
end)
task.delay(dur * (Library.Anim.Speed or 1) + 0.1, function()
if seq == spinSeq and b.Parent then
b.Rotation = 0
spinScale.Scale = 1
end
end)
end
clickRipple(b, nil)
b.MouseButton1Click:Connect(function()
playSound("Click", cfg.Sound)
if spinOn then pcall(spin) end
if type(cfg.Feedback) == "string" then
pcall(function() self.Window:Toast(cfg.Feedback, "Success") end)
end
if cfg.Callback then nextFrame(function() safe(cfg.Callback) end) end
end)
self:_Register(b, cfg.Name, rowH())
local obj = { Frame = b }
function obj:SetText(t)
if gradLabel then gradLabel.Text = t else b.Text = t end
end
return obj
end
function Section:CreateToggle(cfg)
local T = self.Window.Theme
local h = rowH()
local value = cfg.Default and true or false
local ON_POS, OFF_POS = UDim2.new(1, -19, 0.5, 0), UDim2.new(0, 3, 0.5, 0)
local row = new("TextButton", {
Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = T.Control, BackgroundTransparency = 1, Text = "",
AutoButtonColor = false, Parent = self.Body,
}, { corner(10) })
feedback(row, row, "BackgroundTransparency", 1, 0.82, 0.62, true)
new("TextLabel", {
Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -62, 1, 0), BackgroundTransparency = 1, Text = cfg.Name or "Toggle",
Font = T.Font, TextSize = 14, TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
})
local track = new("Frame", {
AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(42, 22),
BackgroundColor3 = value and T.Accent or T.Control, BorderSizePixel = 0, Parent = row,
}, { corner(11), stroke(T.Border, 1, 0.5) })
Library._bevel(track, T.Control, true)
local trackFill = new("Frame", {
Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = value and 0 or 1,
BorderSizePixel = 0, ZIndex = 1, Parent = track,
}, { corner(2), gradient(T.Accent, T.Accent2, 0) })
local knob = new("Frame", {
AnchorPoint = Vector2.new(0, 0.5), Position = value and ON_POS or OFF_POS, ZIndex = 2,
Size = UDim2.fromOffset(16, 16), BackgroundColor3 = T.Knob, BorderSizePixel = 0, Parent = track,
}, { corner(2), stroke(T.Accent, 1.5, 0.4) })
local knobStroke = knob:FindFirstChildOfClass("UIStroke")
knobStroke.Enabled = false
local obj = {}
function obj:Set(v, silent)
value = v and true or false
tween(track, 0.22, { BackgroundColor3 = value and T.Accent or T.Control })
tween(trackFill, 0.22, { BackgroundTransparency = value and 0 or 1 })
tween(knob, 0.24, { Position = value and ON_POS or OFF_POS })
tween(knobStroke, 0.22, { Transparency = value and 0 or 0.5 })
setFlag(cfg, value)
if not silent then safe(cfg.Callback, value) end
end
function obj:Get() return value end
row.MouseButton1Click:Connect(function() playSound("Toggle", cfg.Sound) obj:Set(not value) end)
setFlag(cfg, value)
self:_Register(row, cfg.Name, h)
obj.Frame = row
return regObj(cfg, obj)
end
function Library._numBox(T, props, suffix, getRaw, commit)
local p = {
BackgroundColor3 = T.Control, BackgroundTransparency = 1, BorderSizePixel = 0, Font = T.FontBold, TextSize = 14,
TextColor3 = T.Accent, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Right,
TextTruncate = Enum.TextTruncate.AtEnd, Text = "", ZIndex = 3,
}
for k, v in pairs(props) do p[k] = v end
local st = stroke(T.Accent, 1, 1)
local box = new("TextBox", p, { corner(6), st, padding(4, 0, 4, 0) })
local sx = (suffix or ""):gsub("%s", "")
box.Focused:Connect(function()
box.Text = getRaw()
tween(st, 0.15, { Transparency = 0.25 })
tween(box, 0.15, { BackgroundTransparency = 0.3 })
task.defer(function()
if box:IsFocused() then pcall(function() box.SelectionStart = 1 box.CursorPosition = #box.Text + 1 end) end
end)
end)
box.FocusLost:Connect(function()
tween(st, 0.18, { Transparency = 1 })
tween(box, 0.18, { BackgroundTransparency = 1 })
local s = box.Text:gsub(",", "."):gsub("%s", "")
if sx ~= "" and s:sub(-#sx) == sx then s = s:sub(1, -#sx - 1) end
local n = tonumber(s)
if n and (n ~= n or math.abs(n) == math.huge) then n = nil end
commit(n)
end)
return box
end
function Section:CreateSlider(cfg)	local T = self.Window.Theme
local tab = self.Tab
local min, max, inc = cfg.Min or 0, cfg.Max or 100, cfg.Increment or 1
local value = snap(cfg.Default or min, min, max, inc)
local suffix = cfg.Suffix or ""
local touch = Library.SizeTouch
local total = touch and 50 or 42
local knobS, knobBig = touch and 16 or 12, touch and 20 or 15
local frame = new("Frame", { Size = UDim2.new(1, 0, 0, total), BackgroundTransparency = 1, Parent = self.Body })
new("TextLabel", {
Size = UDim2.new(1, -70, 0, 18), BackgroundTransparency = 1, Text = cfg.Name or "Slider", Font = T.Font, TextSize = 14,
TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
})
local valLabel
local hit = new("TextButton", {
Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 1, -20), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = frame,
})
local track = new("Frame", {
AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(1, 0, 0, 4),
BackgroundColor3 = T.Control, BorderSizePixel = 0, Parent = hit,
}, { corner(2) })
local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = track },
{ corner(2), gradient(T.Accent, T.Accent2, 0) })
local knob = new("Frame", {
AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(knobS, knobS),
BackgroundColor3 = T.Knob, BorderSizePixel = 0, ZIndex = 2, Parent = track,
}, { new("UICorner", { CornerRadius = UDim.new(0, 8) }), stroke(T.Accent, 2, 0) })
local obj = {}
local pendingX, pumpC, dragging
local tgtA, visA, lastPut
local function render(v, animate, dur)
local a = (max == min) and 0 or (v - min) / (max - min)
valLabel.Text = tostring(v) .. suffix
if animate then
tween(fill, dur or 0.18, { Size = UDim2.fromScale(a, 1) })
tween(knob, dur or 0.18, { Position = UDim2.fromScale(a, 0.5) })
else
fill.Size = UDim2.fromScale(a, 1)
knob.Position = UDim2.fromScale(a, 0.5)
end
tgtA, visA, lastPut = a, a, nil
end
function obj:Set(v, silent)
v = snap(v, min, max, inc)
local changed = v ~= value
value = v
render(v, not dragging)
setFlag(cfg, v)
if changed and not silent then safe(cfg.Callback, v) end
end
function obj:Get() return value end
valLabel = Library._numBox(T, {
AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(72, 20), Parent = frame,
}, suffix, function() return tostring(value) end, function(n)
if n == nil then render(value, false) else obj:Set(n) end
end)
render(value, false)
setFlag(cfg, value)
local function coarse()
local n = (max - min) / math.max(inc, 1e-9)
return n > 0 and (track.AbsoluteSize.X / n) > 2.5
end
local function aOf(v) return (max == min) and 0 or (v - min) / (max - min) end
local function put(a)
local w = math.max(track.AbsoluteSize.X, 1)
a = math.floor(a * w + 0.5) / w
if a == lastPut then return end
lastPut = a
fill.Size = UDim2.fromScale(a, 1)
knob.Position = UDim2.fromScale(a, 0.5)
end
local function fromX(x)
local a = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
local v = snap(min + (max - min) * a, min, max, inc)
if v ~= value then
value = v
valLabel.Text = tostring(v) .. suffix
tgtA = aOf(v)
if visA == nil then visA = tgtA end
setFlag(cfg, v)
safe(cfg.Callback, v)
end
end
local function pump(dt)
local x = pendingX
if x then
pendingX = nil
fromX(x)
end
local settled = true
if tgtA then
if visA == nil or not coarse() then
visA = tgtA
else
local d = tgtA - visA
if math.abs(d) < 0.0008 then
visA = tgtA
else
visA += d * (1 - math.exp(-(dt or 1 / 60) * 26))
settled = false
end
end
put(visA)
end
if settled and not dragging and pumpC then
pumpC:Disconnect()
pumpC = nil
end
end
local function release()
dragging = false
pump(1 / 60)
tab:SetScrollEnabled(true)
tween(knob, 0.16, { Size = UDim2.fromOffset(knobS, knobS) })
end
hit.InputBegan:Connect(function(i)
if not isPress(i) then return end
pendingX = nil
Library._drag(i, function(m) pendingX = m.Position.X end, release)
if pumpC then pumpC:Disconnect() pumpC = nil end
dragging = true
pumpC = RunService.RenderStepped:Connect(pump)
tab:SetScrollEnabled(false)
tween(knob, 0.12, { Size = UDim2.fromOffset(knobBig, knobBig) })
fromX(i.Position.X)
end)
self:_Register(frame, cfg.Name, total)
obj.Frame = frame
return regObj(cfg, obj)
end
function Section:CreateDropdown(cfg)
local T = self.Window.Theme
local win = self.Window
local tab = self.Tab
local touch = Library.SizeTouch
local h = rowH()
local optH = touch and 44 or 36
local searchH = touch and 50 or 44
local footH = touch and 50 or 44
local GAP, PAD = 5, 16
local options = cfg.Options or {}
local multi = cfg.Multi and true or false
local placeholder = cfg.Placeholder or "Select..."
local value = multi and {} or nil
local selText = T.Accent:Lerp(Color3.new(1, 1, 1), 0.55)
local selBG = T.AccentSoft:Lerp(T.Accent, 0.3)
local popBG = T.Panel:Lerp(T.Accent, 0.10):Lerp(Color3.new(1, 1, 1), 0.035)
local function rc(r) return corner(r) end
local images = {}
local hasSub = false
local function splitName(opt)
local t, d = tostring(opt):match("^(.-)%s*|%s*(.+)$")
if t and t ~= "" and d then return t, d end
return tostring(opt), nil
end
local function normalize(list)
images = {}
local out = {}
for i, o in ipairs(list or {}) do
if type(o) == "table" then
local name = o.Name or o.Text or o.Value or ("Option " .. i)
out[i] = name
local im = o.Image or o.Icon
if im ~= nil then images[name] = im end
else
out[i] = o
end
end
if type(cfg.Images) == "table" then
for k, v in pairs(cfg.Images) do images[k] = v end
end
hasSub = false
for _, n in ipairs(out) do
local _, d = splitName(n)
if d then hasSub = true break end
end
return out
end
local function imgSz()
local sz = cfg.ImageSize or (touch and 28 or 32)
if touch then sz = math.min(sz, 30) end
return sz
end
local function calcOptH()
local base = touch and 44 or 36
if next(images) ~= nil then base = math.max(touch and 46 or 40, imgSz() + 12) end
if hasSub then base = math.max(base, touch and 52 or 46) end
optH = base
end
local function makeThumb(ref, sz)
local f = new("Frame", {
Size = UDim2.fromOffset(sz, sz), BackgroundColor3 = T.Control, BackgroundTransparency = 0.25,
BorderSizePixel = 0, ClipsDescendants = true,
}, { corner(math.max(6, math.floor(sz / 4))), stroke(T.Border, 1, 0.5) })
local sref = (typeof(ref) ~= "Color3") and tostring(ref) or ""
if typeof(ref) == "Color3" then
f.BackgroundColor3, f.BackgroundTransparency = ref, 0
elseif type(ref) == "number" or sref:match("^%d+$") then
new("ImageLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit,
Image = "rbxassetid://" .. sref, Parent = f })
elseif Library:IsIconName(sref) then
local d = Library:ResolveIcon(sref)
if d then
local ic = Library:MakeIcon(d, T.Accent)
ic.Size = UDim2.fromScale(0.62, 0.62)
ic.Parent = f
end
else
new("ImageLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit,
Image = sref, Parent = f })
end
return f
end
options = normalize(options)
calcOptH()
local function isSel(o)
if multi then return value[o] == true end
return o == value
end
local function selectedList()
local out = {}
for _, o in ipairs(options) do
if value[o] then table.insert(out, o) end
end
return out
end
local function searchOn()
return cfg.Searchable == true
end
local function chrome()
return searchOn() and searchH or 0, multi and footH or 0
end
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
}, { rc(11), stroke(T.Border, 1, 0.35) })
if not lowPower() then
new("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(206, 206, 216)), Rotation = 90, Parent = btn })
end
local btnStroke = btn:FindFirstChildOfClass("UIStroke")
feedback(btn, btn, "BackgroundColor3", T.Control, T.Lift, T.AccentSoft)
local txt = new("TextLabel", {
Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -38, 1, 0), BackgroundTransparency = 1, Text = placeholder,
Font = T.Font, TextSize = 14, TextColor3 = T.SubText, TextXAlignment = LEFT, TextWrapped = true, TextTruncate = Enum.TextTruncate.None, Parent = btn,
})
txt:SetAttribute("SGSkip", true)
local thumbSz = math.min(math.max(16, h - 12), touch and 26 or 32)
local thumbs = new("Frame", {
Name = "Thumbs", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0.5, 0),
Size = UDim2.fromOffset(0, thumbSz), BackgroundTransparency = 1, Parent = btn,
})
local badge = new("Frame", {
AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -34, 0.5, 0), Size = UDim2.fromOffset(22, 18),
BackgroundColor3 = T.AccentSoft, BorderSizePixel = 0, Visible = false, Parent = btn,
}, { rc(9), gradient(T.Accent, T.Accent2, 0) })
local badgeLbl = Library._oa(new("TextLabel", {
Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "0", Font = T.FontBold, TextSize = 14,
TextColor3 = Library.OnAccent(T), Parent = badge,
}))
local chip = new("Frame", {
AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(22, 22),
BackgroundColor3 = T.AccentSoft, BackgroundTransparency = 0.25, BorderSizePixel = 0, Parent = btn,
}, { rc(11) })
local arrow = new("TextLabel", {
AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(22, 22),
BackgroundTransparency = 1, Text = "▼", Font = T.FontBold, TextSize = 9, TextColor3 = T.Accent, Parent = chip,
})
local dd = { IsOpen = false }
btn.MouseEnter:Connect(function()
if usingTouch() or dd.IsOpen then return end
tween(btnStroke, 0.15, { Color = T.Accent, Transparency = 0.55 })
end)
btn.MouseLeave:Connect(function()
if dd.IsOpen then return end
tween(btnStroke, 0.18, { Color = T.Border, Transparency = 0.35 })
end)
local ddTok = 0
local popup, popupStroke, popGrad, popScale, scroll, searchHolder, searchBox, emptyLbl
local rows = {}
local popW, maxH = 190, 240
local escC, vpC, kC
local openK = 1
local curOff, curPad, lastFitW = 0, -38, -1
local TextSvcDD = game:GetService("TextService")
local function fitText()
local sc = win.Scale and win.Scale.Scale or 1
local w = btn.AbsoluteSize.X / math.max(sc, 0.01)
if w <= 0 then return end
local avail = math.max(20, w + curPad - curOff - 12)
local ok, b = pcall(function() return TextSvcDD:GetTextSize(txt.Text, txt.TextSize, txt.Font, Vector2.new(avail, 2000)) end)
local need = ok and b.Y or txt.TextSize
local newH = math.max(h, math.ceil(need) + 16)
if btn.Size.Y.Offset ~= newH then btn.Size = UDim2.new(1, 0, 0, newH) end
end
btn:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
local w = btn.AbsoluteSize.X
if w ~= lastFitW then lastFitW = w fitText() end
end)
local function refreshText()
local list = multi and selectedList() or (value ~= nil and { value } or {})
for _, c in ipairs(thumbs:GetChildren()) do c:Destroy() end
local n, step = 0, math.floor(thumbSz * 0.6)
for _, o in ipairs(list) do
if images[o] ~= nil and n < 3 then
local t = makeThumb(images[o], thumbSz)
t.Position = UDim2.fromOffset(n * step, 0)
t.Parent = thumbs
n = n + 1
end
end
local off = n > 0 and (thumbSz + (n - 1) * step + 8) or 0
thumbs.Size = UDim2.fromOffset(math.max(off - 8, 0), thumbSz)
local rightPad = -38
if multi then
local out = list
if #out == 0 then
txt.Text, txt.TextColor3 = placeholder, T.SubText
else
local names = {}
for i, o in ipairs(out) do names[i] = (splitName(o)) end
txt.Text, txt.TextColor3 = table.concat(names, ", "), T.Text
end
local showBadge = #out > 1
badge.Visible = showBadge
badgeLbl.Text = tostring(#out)
rightPad = showBadge and -68 or -38
else
txt.Text = value ~= nil and (splitName(value)) or placeholder
txt.TextColor3 = value ~= nil and T.Text or T.SubText
end
txt.Position = UDim2.fromOffset(12 + off, 0)
txt.Size = UDim2.new(1, rightPad - off, 1, 0)
curOff, curPad = off, rightPad
fitText()
end
local function paint()
local live = popup and popup.Visible
local function put(inst, t, props, animate)
if animate then tween(inst, t, props)
else for k, v in pairs(props) do inst[k] = v end end
end
for opt, r in pairs(rows) do
local sel = isSel(opt)
if r.sel ~= sel then
r.sel = sel
local an = live and r.btn.Visible
put(r.btn, 0.16, { BackgroundTransparency = sel and 0.08 or 1 }, an)
put(r.bar, 0.16, { BackgroundTransparency = sel and 0 or 1 }, an)
put(r.label, 0.16, { TextColor3 = sel and selText or T.Text }, an)
r.label.Font = sel and T.FontBold or T.Font
if r.stroke then put(r.stroke, 0.16, { Transparency = sel and 0.5 or 1 }, an) end
if r.chk then put(r.chk, 0.16, { BackgroundTransparency = sel and 0 or 1 }, an) end
put(r.check, 0.16, { TextTransparency = sel and 0 or 1 }, an)
if multi then
put(r.box, 0.16, { BackgroundColor3 = sel and T.Accent or T.Control }, an)
put(r.boxStroke, 0.16, { Color = sel and T.Accent or T.Border }, an)
end
end
end
end
local function visibleCount()
local n = 0
for _, r in pairs(rows) do
if r.btn.Visible then n = n + 1 end
end
return n
end
local TextSvc = game:GetService("TextService")
local function lblSize()
local sc = win._textScale or Library.TextScale or 1
local base = touch and 15 or 14
return math.max(8, math.floor(base * sc + 0.5))
end
local function measure(text, width, size)
size = size or lblSize()
local ok, v = pcall(function()
return TextSvc:GetTextSize(text, size, T.Font, Vector2.new(math.max(width, 20), 10000))
end)
if ok and v then return v end
return Vector2.new(#text * size * 0.55, size)
end
local function labelX(opt)
if images[opt] ~= nil then return 18 + math.min(imgSz(), optH - 8) + 10 end
return 18
end
local function desiredWidth()
local w = 0
local sc = win._textScale or Library.TextScale or 1
local subSz = math.max(8, math.floor((touch and 12 or 11) * sc + 0.5))
for _, opt in ipairs(options) do
local t, d = splitName(opt)
local tw = measure(t, 10000).X
if d then tw = math.max(tw, measure(d, 10000, subSz).X) end
w = math.max(w, tw + labelX(opt) + 34 + 20 + 6)
end
return w
end
local function layoutRows()
for _, r in pairs(rows) do
r.h = optH
r.btn.Size = UDim2.new(1, 0, 0, optH)
end
end
local function rowsHeight(untilIdx)
local total = 0
for i, opt in ipairs(options) do
if untilIdx and i > untilIdx then break end
local r = rows[opt]
if not r or r.btn.Visible then total = total + ((r and r.h) or optH) + GAP end
end
return total
end
local function fit(opening)
if not popup then return end
local top, bot = chrome()
local n = visibleCount()
emptyLbl.Visible = n == 0
local rowsH = (n == 0 and (optH + GAP) or rowsHeight()) + PAD
local ph = math.clamp(top + bot + rowsH, math.min(top + bot + optH + PAD, maxH), maxH)
if opening then
popup.Size = UDim2.fromOffset(popW, math.max(math.floor(ph * 0.5), 1))
tween(popup, 0.28, { Size = UDim2.fromOffset(popW, ph) }, QUINT, OUT)
else
tween(popup, 0.16, { Size = UDim2.fromOffset(popW, ph) }, QUINT, OUT)
end
end
local function applyChrome()
local top, bot = chrome()
searchHolder.Visible = top > 0
scroll.Position = UDim2.fromOffset(0, top)
scroll.Size = UDim2.new(1, 0, 1, -(top + bot))
end
local function applyFilter()
local q = searchBox.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
for opt, r in pairs(rows) do
r.btn.Visible = q == "" or tostring(opt):lower():find(q, 1, true) ~= nil
end
emptyLbl.Visible = visibleCount() == 0
if dd.IsOpen then
fit()
scroll.CanvasPosition = Vector2.new()
end
end
local function buildOptions()
for _, r in pairs(rows) do r.btn:Destroy() end
rows = {}
for i, opt in ipairs(options) do
local b = new("TextButton", {
LayoutOrder = i, Size = UDim2.new(1, 0, 0, optH), BackgroundColor3 = selBG, BackgroundTransparency = 1,
AutoButtonColor = false, Text = "", Parent = scroll,
}, { rc(12) })
if not lowPower() then
new("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(190, 190, 205)), Rotation = 0, Parent = b })
end
local rowStroke
if not lowPower() then
rowStroke = new("UIStroke", { Color = T.Accent, Thickness = 1, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = b })
end
local bar = new("Frame", {
AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 5, 0.5, 0), Size = UDim2.new(0, 4, 0.55, 0),
BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = b,
}, { corner(2), gradient(T.Accent, T.Accent2, 90) })
local lblX = 18
if images[opt] ~= nil then
local isz = math.min(imgSz(), optH - 8)
local th = makeThumb(images[opt], isz)
th.AnchorPoint = Vector2.new(0, 0.5)
th.Position = UDim2.new(0, 18, 0.5, 0)
th.Parent = b
lblX = 18 + isz + 10
end
local title, detail = splitName(opt)
local holder = new("Frame", {
AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, lblX, 0.5, 0), Size = UDim2.new(1, -(lblX + 34), 0, 0),
AutomaticSize = AY, BackgroundTransparency = 1, Parent = b,
}, { new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 1), VerticalAlignment = Enum.VerticalAlignment.Center }) })
local lbl = new("TextLabel", {
LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Text = title,
Font = T.Font, TextSize = touch and 15 or 14, TextColor3 = T.Text, TextXAlignment = LEFT,
TextTruncate = Enum.TextTruncate.AtEnd, Parent = holder,
})
local sub
if detail then
sub = new("TextLabel", {
LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Text = detail,
Font = T.Font, TextSize = touch and 12 or 11, TextColor3 = T.SubText, TextXAlignment = LEFT,
TextTruncate = Enum.TextTruncate.AtEnd, Parent = holder,
})
end
local r = { btn = b, bar = bar, label = lbl, sub = sub, stroke = rowStroke, h = optH }
if multi then
r.box = new("Frame", {
AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(18, 18),
BackgroundColor3 = T.Control, BorderSizePixel = 0, Parent = b,
}, { rc(6), stroke(T.Border, 1, 0) })
r.boxStroke = r.box:FindFirstChildOfClass("UIStroke")
r.check = Library._oa(new("TextLabel", {
Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "✓", Font = T.FontBold, TextSize = 14,
TextColor3 = Library.OnAccent(T.Accent), TextTransparency = 1, Parent = r.box,
}))
else
r.chk = new("Frame", {
AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(20, 20),
BackgroundColor3 = T.Accent, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = b,
}, { rc(10) })
r.check = Library._oa(new("TextLabel", {
Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "✓", Font = T.FontBold, TextSize = 14,
TextColor3 = Library.OnAccent(T.Accent), TextTransparency = 1, Parent = r.chk,
}))
end
b.MouseEnter:Connect(function()
if usingTouch() or isSel(opt) then return end
tween(b, 0.12, { BackgroundTransparency = 0.62 })
end)
b.MouseLeave:Connect(function()
if not isSel(opt) then tween(b, 0.14, { BackgroundTransparency = 1 }) end
end)
local press = dragSafePress(b, function()
if not isSel(opt) then tween(b, 0.05, { BackgroundTransparency = 0.35 }) end
end, function()
if not isSel(opt) then tween(b, 0.16, { BackgroundTransparency = 1 }) end
end, 10)
b.MouseButton1Click:Connect(function()
if press.moved or not dd.IsOpen then return end
if multi then
local cur = selectedList()
local found = false
for idx, o in ipairs(cur) do
if o == opt then table.remove(cur, idx) found = true break end
end
if not found then table.insert(cur, opt) end
dd:Set(cur)
else
dd:Set(opt)
dd:Close()
end
end)
rows[opt] = r
end
layoutRows()
paint()
end
local function restyle()
local white = Color3.new(1, 1, 1)
selText = T.Accent:Lerp(white, 0.55)
selBG = T.AccentSoft:Lerp(T.Accent, 0.3)
popBG = T.Panel:Lerp(T.Accent, 0.10):Lerp(white, 0.035)
if not popup then return end
popup.BackgroundColor3 = (popGrad and popGrad.Enabled) and white or popBG
if popGrad then popGrad.Color = cseq({ 0, popBG:Lerp(white, 0.06) }, { 1, popBG:Lerp(Color3.new(0, 0, 0), 0.14) }) end
popupStroke.Color = T.Accent
searchBox.BackgroundColor3 = popBG:Lerp(white, 0.09)
searchBox.TextColor3, searchBox.PlaceholderColor3 = T.Text, T.SubText
local ss = searchBox:FindFirstChildOfClass("UIStroke")
if ss then ss.Color = T.Accent end
scroll.ScrollBarImageColor3 = T.Accent
for _, r in pairs(rows) do
r.sel = nil
r.btn.BackgroundColor3 = selBG
if r.sub then r.sub.TextColor3 = T.SubText end
if r.chk then r.chk.BackgroundColor3 = T.Accent end
if r.stroke then r.stroke.Color = T.Accent end
end
end
local function build()
popup = new("Frame", {
Visible = false, ZIndex = 61, BackgroundColor3 = popBG, BorderSizePixel = 0, ClipsDescendants = true,
Active = true, Parent = win.Gui,
}, { rc(18),
new("UIStroke", { Color = T.Accent, Thickness = 1, Transparency = 0.3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
wash(cseq({ 0, popBG }, { 1, popBG }), 90) })
popupStroke = popup:FindFirstChildOfClass("UIStroke")
popGrad = popup:FindFirstChildOfClass("UIGradient")
popScale = new("UIScale", { Scale = math.max(win._k or 1, 0.01), Parent = popup })
searchHolder = new("Frame", { Size = UDim2.new(1, 0, 0, searchH), BackgroundTransparency = 1, Parent = popup }, { padding(10, 10, 10, 6) })
searchBox = new("TextBox", {
Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Control, Text = "", PlaceholderText = "Search…",
PlaceholderColor3 = T.SubText, TextColor3 = T.Text, Font = T.Font, TextSize = touch and 14 or 13, TextXAlignment = LEFT,
ClearTextOnFocus = false, Parent = searchHolder,
}, { rc(12), new("UIStroke", { Color = T.Accent, Thickness = 1, Transparency = 0.6, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }), padding(14, 0, 14, 0) })
scroll = new("ScrollingFrame", { ElasticBehavior = Enum.ElasticBehavior.Never,
Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = touch and 5 or 4, ScrollBarImageTransparency = 0.3,
ScrollBarImageColor3 = T.Accent, CanvasSize = UDim2.new(), AutomaticCanvasSize = AY,
ScrollingDirection = Enum.ScrollingDirection.Y, Parent = popup,
}, { list(GAP), padding(10, 8, 10, 10) })
emptyLbl = new("TextLabel", {
LayoutOrder = 0, Size = UDim2.new(1, 0, 0, optH), BackgroundTransparency = 1, Text = "No results found", Font = T.Font,
TextSize = 14, TextColor3 = T.SubText, Visible = false, Parent = scroll,
})
if multi then
new("Frame", {
AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, -footH), Size = UDim2.new(1, 0, 0, 1),
BackgroundColor3 = T.Border, BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = popup,
})
local footer = new("Frame", {
AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, footH),
BackgroundTransparency = 1, Parent = popup,
}, { padding(8, 6, 8, 8) })
local withAll = cfg.SelectAll ~= false
local selAll
if withAll then
selAll = new("TextButton", {
Size = UDim2.new(0.34, -4, 1, 0), BackgroundColor3 = T.Control, BackgroundTransparency = 0.1, AutoButtonColor = false, Text = cfg.SelectAllText or "Select All",
Font = T.FontBold, TextSize = 14, TextColor3 = T.Accent, TextTruncate = Enum.TextTruncate.AtEnd, Parent = footer,
}, { rc(11), stroke(T.Accent, 1, 0.5) })
feedback(selAll, selAll, "BackgroundColor3", T.Control, T.Lift, T.AccentSoft)
strokeFeedback(selAll, selAll:FindFirstChildOfClass("UIStroke"), 0.5, 0.15)
end
local clear = new("TextButton", {
Position = withAll and UDim2.new(0.34, 2, 0, 0) or UDim2.new(),
Size = withAll and UDim2.new(0.26, -4, 1, 0) or UDim2.new(0.38, -3, 1, 0),
BackgroundColor3 = T.Control, BackgroundTransparency = 0.1, AutoButtonColor = false, Text = "Clear",
Font = T.Font, TextSize = 14, TextColor3 = T.Text, Parent = footer,
}, { rc(11), stroke(T.Border, 1, 0.35) })
feedback(clear, clear, "BackgroundColor3", T.Control, T.Lift, T.AccentSoft)
strokeFeedback(clear, clear:FindFirstChildOfClass("UIStroke"), 0.35, 0.05)
local done = new("TextButton", {
Position = withAll and UDim2.new(0.60, 2, 0, 0) or UDim2.new(0.38, 3, 0, 0),
Size = withAll and UDim2.new(0.40, -2, 1, 0) or UDim2.new(0.62, -3, 1, 0),
BackgroundColor3 = Color3.new(1, 1, 1), AutoButtonColor = false, Text = "", Parent = footer,
}, { rc(11), gradient(T.Accent, T.Accent2, 0), stroke(T.Accent2, 1, 0.5) })
Library._oa(new("TextLabel", {
Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "Done", Font = T.FontBold, TextSize = 14,
TextColor3 = Library.OnAccent(T), ZIndex = 2, Parent = done,
}))
if selAll then
selAll.MouseButton1Click:Connect(function()
local cur, have = selectedList(), {}
for _, o in ipairs(cur) do have[o] = true end
for _, o in ipairs(options) do
local r = rows[o]
if not have[o] and (not r or r.btn.Visible) then table.insert(cur, o) end
end
dd:Set(cur)
end)
end
strokeFeedback(done, done:FindFirstChildOfClass("UIStroke"), 0.5, 0.05)
clear.MouseButton1Click:Connect(function() dd:Set({}) end)
done.MouseButton1Click:Connect(function() dd:Close() end)
end
searchBox:GetPropertyChangedSignal("Text"):Connect(applyFilter)
searchBox.FocusLost:Connect(function(enter)
if enter and not multi then
for _, opt in ipairs(options) do
local r = rows[opt]
if r and r.btn.Visible then
dd:Set(opt)
dd:Close()
return
end
end
end
end)
buildOptions()
restyle()
end
function dd:Open()
if self.IsOpen then return end
win:CloseDropdowns()
if not popup then build() else restyle() paint() end
ddTok += 1
local my = ddTok
if (win._textScale or Library.TextScale or 1) ~= 1 then win:_ApplyTextScale(popup) end
applyChrome()
searchBox.Text = ""
for _, r in pairs(rows) do r.btn.Visible = true end
emptyLbl.Visible = #options == 0
local top, bot = chrome()
local k = math.max(win._k or 1, 0.01)
openK = k
popScale.Scale = k
local pos, size = btn.AbsolutePosition, btn.AbsoluteSize
local bmin, bmax = Library._visibleRect(win.Gui)
local vp = (bmax - bmin) / k
local cap = touch and 300 or 260
local minH = top + bot + optH + PAD
popW = math.min(math.max(size.X / k, 190, math.min(desiredWidth(), touch and 340 or 320)), vp.X - 12)
layoutRows()
local want = math.min(top + bot + math.max(rowsHeight(), optH + GAP) + PAD, cap)
local below = (bmax.Y - (pos.Y + size.Y + 4 * k)) / k - 8
local above = (pos.Y - 4 * k - bmin.Y) / k - 8
local down = want <= below or below >= above
maxH = math.max(math.min(cap, down and below or above), math.min(minH, vp.Y - 16))
local x = math.clamp(pos.X, bmin.X + 6 * k, math.max(bmin.X + 6 * k, bmax.X - popW * k - 6 * k))
if not popup.Visible then
popup.Size = UDim2.fromOffset(popW, 0)
popup.BackgroundTransparency = 1
popupStroke.Transparency = 1
end
popup.AnchorPoint = Vector2.new(0, down and 0 or 1)
local wantY = down and (pos.Y + size.Y + 4 * k) or (pos.Y - 4 * k)
popup.Position = UDim2.fromOffset(x, wantY)
popup.Visible = true
Library._pinPopup(popup, x, wantY)
nextFrame(function() if self.IsOpen and ddTok == my then Library._pinPopup(popup, x, wantY) end end)
win:_ShowOverlay(0.5)
tab:SetScrollEnabled(false)
self.IsOpen = true
win._dd = self
tween(arrow, 0.2, { Rotation = 180 })
tween(chip, 0.2, { BackgroundColor3 = T.Accent, BackgroundTransparency = 0.15 })
tween(arrow, 0.2, { TextColor3 = Library.OnAccent(T.Accent) })
tween(btnStroke, 0.2, { Color = T.Accent, Transparency = 0.2 })
escC = UserInputService.InputBegan:Connect(function(i)
if i.KeyCode == Enum.KeyCode.Escape then dd:Close() end
end)
local cam = workspace.CurrentCamera
if cam then
vpC = cam:GetPropertyChangedSignal("ViewportSize"):Connect(function() dd:Close() end)
end
if kC then kC:Disconnect() end
kC = win.Scale:GetPropertyChangedSignal("Scale"):Connect(function()
if dd.IsOpen and math.abs((win._k or 1) - openK) > 0.005 then dd:Close() end
end)
nextFrame(function()
if ddTok ~= my or not self.IsOpen then return end
local idx
for n, o in ipairs(options) do
if isSel(o) then idx = n break end
end
local target = idx and math.max(0, rowsHeight(idx - 2)) or 0
scroll.CanvasPosition = Vector2.new()
if target > 0 then tween(scroll, 0.3, { CanvasPosition = Vector2.new(0, target) }, QUINT, OUT) end
fit(true)
tween(popup, 0.18, { BackgroundTransparency = 0 }, SINE, OUT)
tween(popupStroke, 0.18, { Transparency = 0.3 }, SINE, OUT)
end)
end
function dd:Close()
if not self.IsOpen then return end
self.IsOpen = false
ddTok += 1
local my = ddTok
if win._dd == self then win._dd = nil end
if escC then escC:Disconnect() escC = nil end
if vpC then vpC:Disconnect() vpC = nil end
if kC then kC:Disconnect() kC = nil end
if searchBox then searchBox:ReleaseFocus() end
win:_HideOverlay()
tab:SetScrollEnabled(true)
tween(arrow, 0.18, { Rotation = 0 })
tween(chip, 0.18, { BackgroundColor3 = T.AccentSoft, BackgroundTransparency = 0.25 })
tween(arrow, 0.18, { TextColor3 = T.Accent })
tween(btnStroke, 0.18, { Color = T.Border, Transparency = 0.35 })
if popup then
tween(popupStroke, 0.14, { Transparency = 1 }, QUAD, IN)
tween(popup, 0.14, { Size = UDim2.fromOffset(popW, 0), BackgroundTransparency = 1 }, QUAD, IN).Completed:Connect(function()
if popup and ddTok == my and not self.IsOpen then popup.Visible = false end
end)
end
end
function dd:Set(v, silent)
local out
if multi then
value = {}
if type(v) == "table" then
for k, x in pairs(v) do
if x == true then value[k] = true else value[x] = true end
end
end
out = selectedList()
else
value = v
out = v
end
refreshText()
paint()
setFlag(cfg, out)
if not silent then safe(cfg.Callback, out) end
end
function dd:Get()
if multi then return selectedList() end
return value
end
function dd:Refresh(newOptions, keep, extraImages)
options = normalize(newOptions or {})
if type(extraImages) == "table" then
for k, v in pairs(extraImages) do images[k] = v end
end
calcOptH()
if not keep then
self:Set(nil, true)
elseif multi then
self:Set(selectedList(), true)
end
refreshText()
if popup then
buildOptions()
applyChrome()
if self.IsOpen then
searchBox.Text = ""
fit()
end
end
end
function dd:SetImage(opt, image)
images[opt] = image
calcOptH()
refreshText()
if popup then
buildOptions()
applyChrome()
if self.IsOpen then fit() end
end
end
frame.Destroying:Connect(function()
if dd.IsOpen then pcall(function() dd:Close() end) end
if escC then escC:Disconnect() escC = nil end
if vpC then vpC:Disconnect() vpC = nil end
if kC then kC:Disconnect() kC = nil end
if popup then popup:Destroy() popup = nil end
end)
local lastToggle = 0
btn.MouseButton1Click:Connect(function()
local now = os.clock()
if now - lastToggle < 0.12 then return end
lastToggle = now
if dd.IsOpen then dd:Close() else dd:Open() end
end)
if cfg.Default ~= nil then
dd:Set(cfg.Default, true)
elseif multi then
dd:Set({}, true)
end
setFlag(cfg, dd:Get())
self:_Register(frame, cfg.Name, h + (cfg.Name and 20 or 0))
dd.Frame = frame
return regObj(cfg, dd)
end
function Section:CreateParagraph(cfg)
cfg = cfg or {}
local T = self.Window.Theme
local frame = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Parent = self.Body }, { list(2) })
local title = new("TextLabel", {
LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Text = cfg.Title or "",
Font = T.FontBold, TextSize = 14, TextColor3 = T.Text, TextXAlignment = LEFT, TextWrapped = true, Parent = frame,
})
local body = new("TextLabel", {
LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Text = cfg.Content or "",
Font = T.Font, TextSize = 14, TextColor3 = T.SubText, TextXAlignment = LEFT, TextWrapped = true, Parent = frame,
})
self:_Register(frame, cfg.Title, 40)
local obj = { Frame = frame }
function obj:Set(t, c)
if t ~= nil then title.Text = t end
if c ~= nil then body.Text = c end
end
return obj
end
function Section:CreateTextbox(cfg)
cfg = cfg or {}
local T = self.Window.Theme
local h = rowH()
local value
if cfg.Numeric then
value = tonumber(cfg.Default) or cfg.Min or 0
if cfg.Min then value = math.max(value, cfg.Min) end
if cfg.Max then value = math.min(value, cfg.Max) end
else
value = cfg.Default ~= nil and tostring(cfg.Default) or ""
end
local frame = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Parent = self.Body }, { list(4) })
if cfg.Name then
new("TextLabel", {
LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = cfg.Name, Font = T.Font, TextSize = 14,
TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
})
end
local boxFrame = new("Frame", {
LayoutOrder = 2, Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = T.Control, BackgroundTransparency = 0.1, Parent = frame,
}, { corner(2), stroke(T.Border, 1, 0.35) })
Library._bevel(boxFrame, T.Control, true)
local bStroke = boxFrame:FindFirstChildOfClass("UIStroke")
local box = new("TextBox", {
Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 1, 0), BackgroundTransparency = 1, Text = tostring(value),
PlaceholderText = cfg.Placeholder or "", PlaceholderColor3 = T.SubText, ClearTextOnFocus = cfg.ClearOnFocus == true,
Font = T.Font, TextSize = 14, TextColor3 = T.Text, TextXAlignment = LEFT, ClipsDescendants = true, Parent = boxFrame,
})
local function clip(s)
local n = tonumber(cfg.MaxLength)
if not n then return s end
local len = utf8.len(s)
if len and len > n then return s:sub(1, utf8.offset(s, n + 1) - 1) end
if not len then return s:sub(1, n) end
return s
end
local function apply(v)
if cfg.Numeric then
local n = tonumber(v)
if n == nil or n ~= n or n == math.huge or n == -math.huge then return false end
if cfg.Min then n = math.max(n, cfg.Min) end
if cfg.Max then n = math.min(n, cfg.Max) end
value = n
else
v = tostring(v == nil and "" or v)
v = clip(v)
value = v
end
box.Text = tostring(value)
return true
end
local obj = {}
function obj:Set(v, silent)
if not apply(v) then return end
setFlag(cfg, value)
if not silent then safe(cfg.Callback, value) end
end
function obj:Get() return value end
box.Focused:Connect(function()
tween(bStroke, 0.16, { Color = T.Accent, Transparency = 0 })
end)
box.FocusLost:Connect(function(enter)
tween(bStroke, 0.16, { Color = T.Border, Transparency = 0.35 })
if cfg.EnterOnly and not enter then
box.Text = tostring(value)
return
end
local old = value
if not apply(box.Text) then
box.Text = tostring(value)
return
end
setFlag(cfg, value)
if value ~= old then safe(cfg.Callback, value) end
end)
if cfg.Live and not cfg.Numeric then
box:GetPropertyChangedSignal("Text"):Connect(function()
if not box:IsFocused() then return end
local clipped = clip(box.Text)
if clipped ~= box.Text then box.Text = clipped return end
value = clipped
setFlag(cfg, value)
safe(cfg.Callback, value)
end)
end
setFlag(cfg, value)
self:_Register(frame, cfg.Name, h + (cfg.Name and 20 or 0))
obj.Frame = frame
return regObj(cfg, obj)
end
local CAS_ = game:GetService("ContextActionService")
local function sinkKeys(on)
if on then
pcall(function()
CAS_:BindActionAtPriority("SpectreKeybindSink", function() return Enum.ContextActionResult.Sink end, false, 3000, Enum.UserInputType.Keyboard)
end)
else
pcall(function() CAS_:UnbindAction("SpectreKeybindSink") end)
end
end
Library._setListening = function(token, on)
if on then
Library._listening = token
sinkKeys(true)
else
sinkKeys(false)
task.delay(0.25, function()
if Library._listening == token then Library._listening = nil end
end)
end
end
local function toKey(v)
if typeof(v) == "EnumItem" then return v end
if type(v) == "string" then
local ok, k = pcall(function() return Enum.KeyCode[v] end)
return ok and k or nil
end
return nil
end
function Section:CreateKeybind(cfg)
cfg = cfg or {}
local T = self.Window.Theme
local win = self.Window
local h = rowH()
local mode = cfg.Mode or "Press"
local key = toKey(cfg.Default)
local listening, state = false, false
local token = {}
local row = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, Parent = self.Body })
new("TextLabel", {
Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -96, 1, 0), BackgroundTransparency = 1, Text = cfg.Name or "Keybind",
Font = T.Font, TextSize = 14, TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
})
local btn = new("TextButton", {
AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(80, math.min(h - 4, 24)),
BackgroundColor3 = T.Control, BackgroundTransparency = 0.1, AutoButtonColor = false, Text = "", Font = T.Font, TextSize = 13,
TextColor3 = T.Text, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
}, { corner(2), stroke(T.Border, 1, 0.35), padding(4, 0, 4, 0) })
feedback(btn, btn, "BackgroundColor3", T.Control, T.Lift, T.AccentSoft)
local function setListening(v)
listening = v and true or false
Library._setListening(token, listening)
end
local function refresh()
btn.Text = listening and "..." or (key and key.Name or "None")
tween(btn, 0.14, { TextColor3 = listening and T.Accent or T.Text })
end
refresh()
local obj = {}
function obj:Set(v, silent)
key = toKey(v)
setListening(false)
state = false
refresh()
setFlag(cfg, key)
if not silent then safe(cfg.Changed, key) end
end
function obj:Get() return key end
function obj:GetState() return state end
btn.MouseButton1Click:Connect(function()
setListening(not listening)
refresh()
end)
table.insert(win.Conns, UserInputService.InputBegan:Connect(function(i, gp)
if listening then
if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
if i.KeyCode == Enum.KeyCode.Escape then
setListening(false)
refresh()
elseif i.KeyCode == Enum.KeyCode.Backspace or i.KeyCode == Enum.KeyCode.Delete then
obj:Set(nil)
else
obj:Set(i.KeyCode)
end
return
end
if Library._listening then return end
if gp or not key or i.KeyCode ~= key then return end
if mode == "Hold" then
state = true
safe(cfg.Callback, true)
elseif mode == "Toggle" then
state = not state
safe(cfg.Callback, state)
else
safe(cfg.Callback)
end
end))
table.insert(win.Conns, UserInputService.InputEnded:Connect(function(i)
if mode == "Hold" and state and key and i.KeyCode == key then
state = false
safe(cfg.Callback, false)
end
end))
setFlag(cfg, key)
self:_Register(row, cfg.Name, h)
obj.Frame = row
return regObj(cfg, obj)
end
local function toHex(c)
return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end
local function parseHex(s)
s = tostring(s):gsub("[#%s]", "")
if #s == 3 then s = s:gsub(".", function(ch) return ch .. ch end) end
if #s ~= 6 or not s:match("^%x+$") then return nil end
return Color3.fromRGB(tonumber(s:sub(1, 2), 16), tonumber(s:sub(3, 4), 16), tonumber(s:sub(5, 6), 16))
end
function Section:CreateColorPicker(cfg)
cfg = cfg or {}
local T = self.Window.Theme
local win, tab = self.Window, self.Tab
local h = rowH()
local color = typeof(cfg.Default) == "Color3" and cfg.Default or Color3.fromRGB(255, 255, 255)
local hue, sat, val = color:ToHSV()
local row = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, Parent = self.Body })
new("TextLabel", {
Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -62, 1, 0), BackgroundTransparency = 1, Text = cfg.Name or "Color",
Font = T.Font, TextSize = 14, TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
})
local swatch = new("TextButton", {
AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(38, 20),
BackgroundColor3 = color, Text = "", AutoButtonColor = false, Parent = row,
}, { corner(10), stroke(T.Border, 1, 0.2) })
feedback(swatch, swatch, "BackgroundTransparency", 0, 0.12, 0.25)
local obj = { IsOpen = false }
local popup, popupStroke, svBox, svKnob, hueKnob, hexBox
local function render()
color = Color3.fromHSV(hue, sat, val)
swatch.BackgroundColor3 = color
if popup then
svBox.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
svKnob.Position = UDim2.fromScale(sat, 1 - val)
hueKnob.Position = UDim2.fromScale(hue, 0.5)
if not hexBox:IsFocused() then hexBox.Text = toHex(color) end
end
end
local function push(silent)
render()
setFlag(cfg, color)
if not silent then safe(cfg.Callback, color) end
end
local function dragOn(hit, onMove)
hit.InputBegan:Connect(function(i)
if not isPress(i) then return end
local isTouch = i.UserInputType == Enum.UserInputType.Touch
onMove(i.Position)
local mc = UserInputService.InputChanged:Connect(function(m)
if isTouch then
if m ~= i then return end
elseif m.UserInputType ~= Enum.UserInputType.MouseMovement then
return
end
onMove(m.Position)
end)
onEnd(i, function() mc:Disconnect() end)
end)
end
local function build()
popup = new("Frame", {
Visible = false, ZIndex = 61, Active = true, BackgroundColor3 = T.Panel, BorderSizePixel = 0, ClipsDescendants = true, Parent = win.Gui,
}, { corner(8), stroke(T.Accent, 1, 0.45),
wash(cseq({ 0, T.Top }, { 1, T.Panel }), 90) })
popupStroke = popup:FindFirstChildOfClass("UIStroke")
svBox = new("Frame", {
Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 0, 104), BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
BorderSizePixel = 0, Parent = popup,
}, { corner(6) })
new("Frame", {
Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = svBox,
}, { corner(6), new("UIGradient", { Transparency = NumberSequence.new(0, 1) }) })
new("Frame", {
Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Parent = svBox,
}, { corner(6), new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }) })
svKnob = new("Frame", {
AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 3, Parent = svBox,
}, { new("UICorner", { CornerRadius = UDim.new(0, 8) }), stroke(Color3.new(1, 1, 1), 2, 0) })
local svHit = new("TextButton", {
Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 4, Parent = svBox,
})
dragOn(svHit, function(p)
sat = math.clamp((p.X - svBox.AbsolutePosition.X) / math.max(svBox.AbsoluteSize.X, 1), 0, 1)
val = 1 - math.clamp((p.Y - svBox.AbsolutePosition.Y) / math.max(svBox.AbsoluteSize.Y, 1), 0, 1)
push()
end)
local pts = {}
for n = 0, 6 do table.insert(pts, ColorSequenceKeypoint.new(n / 6, Color3.fromHSV(n / 6, 1, 1))) end
local hueBar = new("Frame", {
Position = UDim2.fromOffset(8, 120), Size = UDim2.new(1, -16, 0, 12), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = popup,
}, { corner(6), new("UIGradient", { Color = ColorSequence.new(pts) }) })
hueKnob = new("Frame", {
AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(8, 16), BackgroundColor3 = T.Knob, BorderSizePixel = 0, ZIndex = 3, Parent = hueBar,
}, { corner(3), stroke(T.Accent, 2, 0) })
local hueHit = new("TextButton", {
Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 4, Parent = hueBar,
})
dragOn(hueHit, function(p)
hue = math.clamp((p.X - hueBar.AbsolutePosition.X) / math.max(hueBar.AbsoluteSize.X, 1), 0, 1)
push()
end)
local hexFrame = new("Frame", {
Position = UDim2.fromOffset(8, 140), Size = UDim2.new(1, -16, 0, 24), BackgroundColor3 = T.Control, BackgroundTransparency = 0.1, BorderSizePixel = 0, Parent = popup,
}, { corner(6), stroke(T.Border, 1, 0.35) })
hexBox = new("TextBox", {
Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = toHex(color), ClearTextOnFocus = false, Font = T.Font, TextSize = 14,
TextColor3 = T.Text, Parent = hexFrame,
})
hexBox.FocusLost:Connect(function()
local c = parseHex(hexBox.Text)
if c then
hue, sat, val = c:ToHSV()
push()
end
hexBox.Text = toHex(color)
end)
render()
end
function obj:Open()
if self.IsOpen then return end
win:CloseDropdowns()
if not popup then build() end
render()
if (win._textScale or Library.TextScale or 1) ~= 1 then win:_ApplyTextScale(popup) end
local pos, size = swatch.AbsolutePosition, swatch.AbsoluteSize
local bmin, bmax = Library._visibleRect(win.Gui)
local vp = bmax - bmin
local ph = 172
local pw = math.min(220, vp.X - 12)
local below = bmax.Y - (pos.Y + size.Y + 3) - 6
local above = pos.Y - 3 - 6 - bmin.Y
local down = ph <= below or below >= above
ph = math.max(math.min(ph, down and below or above), 60)
local x = math.clamp(pos.X + size.X - pw, bmin.X + 6, math.max(bmin.X + 6, bmax.X - pw - 6))
if not popup.Visible then
popup.Size = UDim2.fromOffset(pw, 0)
popup.BackgroundTransparency = 1
popupStroke.Transparency = 1
end
popup.AnchorPoint = Vector2.new(0, down and 0 or 1)
local wantY = down and (pos.Y + size.Y + 3) or (pos.Y - 3)
popup.Position = UDim2.fromOffset(x, wantY)
popup.Visible = true
Library._pinPopup(popup, x, wantY)
self._tok = (self._tok or 0) + 1
win:_ShowOverlay()
tab:SetScrollEnabled(false)
tween(popup, 0.22, { Size = UDim2.fromOffset(pw, ph), BackgroundTransparency = 0 })
tween(popupStroke, 0.22, { Transparency = 0.45 })
self.IsOpen = true
win._dd = self
end
function obj:Close()
if not self.IsOpen then return end
self.IsOpen = false
if win._dd == self then win._dd = nil end
win:_HideOverlay()
tab:SetScrollEnabled(true)
self._tok = (self._tok or 0) + 1
local my = self._tok
if popup then
tween(popupStroke, 0.16, { Transparency = 1 }, QUAD, IN)
tween(popup, 0.16, { Size = UDim2.fromOffset(popup.AbsoluteSize.X, 0), BackgroundTransparency = 1 }, QUAD, IN).Completed:Connect(function()
if self._tok == my and not self.IsOpen then popup.Visible = false end
end)
end
end
function obj:Set(c, silent)
if typeof(c) ~= "Color3" then return end
hue, sat, val = c:ToHSV()
push(silent)
end
function obj:Get() return color end
swatch.MouseButton1Click:Connect(function()
if obj.IsOpen then obj:Close() else obj:Open() end
end)
setFlag(cfg, color)
self:_Register(row, cfg.Name, h)
obj.Frame = row
return regObj(cfg, obj)
end
function Section:CreateBadge(cfg)
cfg = cfg or {}
local T = self.Window.Theme
local row = new("Frame", { Size = UDim2.new(1, 0, 0, rowH()), BackgroundTransparency = 1, Parent = self.Body })
local lbl = new("TextLabel", {
Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -92, 1, 0), BackgroundTransparency = 1, Text = cfg.Name or "Status",
Font = T.Font, TextSize = 14, TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
})
local pill = new("Frame", {
AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(72, 20),
BackgroundColor3 = cfg.Color or T.Accent, BorderSizePixel = 0, Parent = row,
}, { corner(10), stroke(cfg.Color or T.Accent, 1, 0.55) })
local pillStroke = pill:FindFirstChildOfClass("UIStroke")
local val = new("TextLabel", {
Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = tostring(cfg.Value or "ON"),
Font = T.FontBold, TextSize = 14, TextColor3 = Library.OnAccent(cfg.Color or T.Accent), TextTruncate = Enum.TextTruncate.AtEnd, Parent = pill,
}, { padding(6, 0, 6, 0) })
if not cfg.Color then Library._oa(val) end
self:_Register(row, cfg.Name, rowH())
local obj = { Frame = row }
function obj:Set(v)
val.Text = tostring(v)
end
function obj:SetColor(c)
pill.BackgroundColor3 = c
pillStroke.Color = c
val.TextColor3 = Library.OnAccent(c)
end
return obj
end
function Section:CreateProgress(cfg)
cfg = cfg or {}
local T = self.Window.Theme
local min, max = cfg.Min or 0, cfg.Max or 100
local value = math.clamp(cfg.Default or min, min, max)
local suffix = cfg.Suffix or ""
local total = 42
local frame = new("Frame", { Size = UDim2.new(1, 0, 0, total), BackgroundTransparency = 1, Parent = self.Body })
new("TextLabel", {
Size = UDim2.new(1, -70, 0, 18), BackgroundTransparency = 1, Text = cfg.Name or "Progress", Font = T.Font, TextSize = 14,
TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
})
local valLabel = new("TextLabel", {
AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(66, 18), BackgroundTransparency = 1,
Text = tostring(value) .. suffix, Font = T.FontBold, TextSize = 14, TextColor3 = T.Accent, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
})
local track = new("Frame", {
AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0, 32), Size = UDim2.new(1, 0, 0, 8),
BackgroundColor3 = T.Control, BorderSizePixel = 0, Parent = frame,
}, { corner(4) })
local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = track },
{ corner(4), gradient(cfg.Color or T.Accent, (cfg.Color or T.Accent2), 0) })
self:_Register(frame, cfg.Name, total)
local obj = { Frame = frame }
local function fmtNum(n)
if n == math.floor(n) then return tostring(math.floor(n)) end
return tostring(n)
end
local function render(animate)
local a = (max == min) and 0 or (value - min) / (max - min)
valLabel.Text = fmtNum(value) .. suffix
if animate then tween(fill, 0.2, { Size = UDim2.fromScale(a, 1) }) else fill.Size = UDim2.fromScale(a, 1) end
end
function obj:Set(v)
if cfg.Auto then
value = math.clamp(v, 0, 1)
valLabel.Text = fmtNum(math.floor(value * 100 + 0.5)) .. "%"
tween(fill, 0.2, { Size = UDim2.fromScale(value, 1) })
return
end
value = math.clamp(v, min, max)
render(true)
end
function obj:Get() return value end
function obj:SetColor(c)
local g = fill:FindFirstChildOfClass("UIGradient")
if g then g.Color = ColorSequence.new(c, c:Lerp(Color3.new(1, 1, 1), 0.25)) end
end
render(false)
return regObj(cfg, obj)
end
function Section:CreateSeparator(cfg)
if type(cfg) == "string" then cfg = { Name = cfg } end
cfg = cfg or {}
local T = self.Window.Theme
local row = new("Frame", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Parent = self.Body })
local function hair(anchor, pos)
return new("Frame", {
AnchorPoint = Vector2.new(anchor, 0.5), Position = pos, Size = UDim2.new(0.5, -34, 0, 1),
BackgroundColor3 = T.Border, BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = row,
})
end
hair(0, UDim2.new(0, 0, 0.5, 0))
hair(1, UDim2.new(1, 0, 0.5, 0))
new("TextLabel", {
AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AX,
BackgroundTransparency = 1, Text = cfg.Name or "", Font = T.FontBold, TextSize = 14, TextColor3 = T.SubText, Parent = row,
}, { padding(6, 0, 6, 0) })
self:_Register(row, cfg.Name, 20)
return { Frame = row }
end
function Section:CreateKeybindToggle(cfg)
cfg = cfg or {}
local T = self.Window.Theme
local win = self.Window
local h = rowH()
local key = toKey(cfg.Key or cfg.Default)
local value = cfg.On and true or false
local row = new("TextButton", {
Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = T.Control, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = self.Body,
}, { corner(2) })
feedback(row, row, "BackgroundTransparency", 1, 0.82, 0.62, true)
new("TextLabel", {
Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -140, 1, 0), BackgroundTransparency = 1, Text = cfg.Name or "Toggle Key",
Font = T.Font, TextSize = 14, TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
})
local keyBtn = new("TextButton", {
AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -54, 0.5, 0), Size = UDim2.fromOffset(46, math.min(h - 6, 22)),
BackgroundColor3 = T.Control, BackgroundTransparency = 0.1, AutoButtonColor = false, Text = "", Font = T.FontBold, TextSize = 14,
TextColor3 = T.Accent, Parent = row,
}, { corner(2), stroke(T.Border, 1, 0.35) })
local keyStroke = keyBtn:FindFirstChildOfClass("UIStroke")
local track = new("Frame", {
AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(38, 20),
BackgroundColor3 = value and T.Accent or T.Control, BorderSizePixel = 0, Parent = row,
}, { corner(2) })
local trackFill = new("Frame", {
Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = value and 0 or 1,
BorderSizePixel = 0, ZIndex = 1, Parent = track,
}, { corner(2), gradient(T.Accent, T.Accent2, 0) })
local knob = new("Frame", {
AnchorPoint = Vector2.new(0, 0.5), Position = value and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0), ZIndex = 2,
Size = UDim2.fromOffset(14, 14), BackgroundColor3 = T.Knob, BorderSizePixel = 0, Parent = track,
}, { corner(2), stroke(T.Accent, 1.5, 0.4) })
local listening = false
local token = {}
local obj = {}
local function refreshKey()
keyBtn.Text = listening and "..." or (key and key.Name or "None")
tween(keyBtn, 0.14, { TextColor3 = listening and T.Accent or T.Text })
tween(keyStroke, 0.14, { Color = listening and T.Accent or T.Border })
end
refreshKey()
local function setValue(v, silent)
value = v and true or false
tween(track, 0.22, { BackgroundColor3 = value and T.Accent or T.Control })
tween(trackFill, 0.22, { BackgroundTransparency = value and 0 or 1 })
tween(knob, 0.24, { Position = value and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) })
setFlag(cfg, value)
if not silent then safe(cfg.Callback, value) end
end
function obj:Set(v, silent) setValue(v, silent) end
function obj:Get() return value end
function obj:SetKey(v, silent)
key = toKey(v)
listening = false
Library._setListening(token, false)
refreshKey()
if not silent then safe(cfg.Changed, key) end
end
function obj:GetKey() return key end
row.MouseButton1Click:Connect(function()
if listening then return end
setValue(not value)
end)
keyBtn.MouseButton1Click:Connect(function()
listening = not listening
Library._setListening(token, listening)
refreshKey()
end)
table.insert(win.Conns, UserInputService.InputBegan:Connect(function(i, gp)
if listening then
if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
if i.KeyCode == Enum.KeyCode.Escape then
listening = false
Library._setListening(token, false)
refreshKey()
elseif i.KeyCode == Enum.KeyCode.Backspace or i.KeyCode == Enum.KeyCode.Delete then
obj:SetKey(nil)
else
obj:SetKey(i.KeyCode)
end
return
end
if Library._listening then return end
if gp or not key or i.KeyCode ~= key then return end
setValue(not value)
end))
setFlag(cfg, value)
self:_Register(row, cfg.Name, h)
obj.Frame = row
return regObj(cfg, obj)
end
function Window:Tooltip(target, text)
if not text or text == "" then return end
local T = self.Theme
local tip, measure
local function show()
if tip or usingTouch() then return end
local txt = type(text) == "function" and text() or text
if not txt or txt == "" then return end
measure = new("TextLabel", {
BackgroundTransparency = 1, Size = UDim2.new(0, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.XY,
Text = txt, Font = T.Font, TextSize = 13, TextColor3 = T.Text, TextWrapped = true,
Visible = false, Parent = self.Gui,
})
tip = new("Frame", {
BackgroundColor3 = T.Panel, BackgroundTransparency = 0.05, BorderSizePixel = 0, ZIndex = 120, Visible = false, Parent = self.Gui,
}, { corner(6), stroke(T.Accent, 1, 0.5), padding(10, 6, 10, 6) })
local l = new("TextLabel", {
BackgroundTransparency = 1, Size = UDim2.new(0, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.XY, Text = txt,
Font = T.Font, TextSize = 13, TextColor3 = T.Text, TextWrapped = true, Parent = tip,
})
local cap = math.max(120, math.min(280, self.Gui.AbsoluteSize.X - 32))
new("UISizeConstraint", { MaxSize = Vector2.new(cap, math.huge), Parent = measure })
new("UISizeConstraint", { MaxSize = Vector2.new(cap, math.huge), Parent = l })
task.defer(function()
if not tip then return end
local m = measure.AbsoluteSize
local tw, th = m.X + 20, m.Y + 12
local pos, size = target.AbsolutePosition, target.AbsoluteSize
local vp = self.Gui.AbsoluteSize
tip.Size = UDim2.fromOffset(tw, th)
local x = math.clamp(pos.X + size.X / 2 - tw / 2, 6, math.max(6, vp.X - tw - 6))
local y = pos.Y + size.Y + 6
if y + th > vp.Y - 6 then y = pos.Y - th - 6 end
tip.Position = UDim2.fromOffset(x, y)
tip.Visible = true
tip.BackgroundTransparency = 1
tween(tip, 0.14, { BackgroundTransparency = 0.05 })
end)
end
local function hide()
if measure then measure:Destroy() measure = nil end
if tip then tip:Destroy() tip = nil end
end
target.MouseEnter:Connect(show)
target.MouseLeave:Connect(hide)
return { Hide = hide }
end
local _twCache, _twCount = {}, 0
function Tab._textW(text, size, font)
local key = tostring(font) .. "|" .. size .. "|" .. text
local w = _twCache[key]
if w then return w end
local ok, v = pcall(function()
return game:GetService("TextService"):GetTextSize(text, size, font, Vector2.new(10000, 10000))
end)
w = ok and v.X or 0
if _twCount > 400 then _twCache, _twCount = {}, 0 end
_twCache[key] = w
_twCount += 1
return w
end
function Tab:_FitLabel()
local lbl = self.Label
if not lbl then return end
local lx = self._lblX or 46
local right = self._locked and 34 or 6
if self._uxStar and self._uxStar.Visible then right = right + 34 end
local badge = self.Badge
local corner = false
if badge and badge.Visible and self.BadgeLabel then
local btnW = self.Button.AbsoluteSize.X / math.max(self.Window.Scale.Scale, 0.01)
local bw = Tab._textW(self.BadgeLabel.Text, 12, self.BadgeLabel.Font) + 12
local need = lx + Tab._textW(lbl.Text, lbl.TextSize, lbl.Font) + 8 + bw + 10
if self._locked then need = need + 18 end
if btnW > 0 and need > btnW then
corner = true
else
right = math.max(right, bw + 18 + (self._locked and 18 or 0))
end
end
if badge then
if corner then
badge.AnchorPoint = Vector2.new(1, 0)
badge.Position = UDim2.new(1, -5, 0, 1)
badge.Size = UDim2.fromOffset(14, 12)
if self.BadgeLabel then self.BadgeLabel.TextSize = 9 end
else
badge.AnchorPoint = Vector2.new(1, 0.5)
badge.Position = UDim2.new(1, -8, 0.5, 0)
badge.Size = UDim2.fromOffset(18, 16)
if self.BadgeLabel then self.BadgeLabel.TextSize = 13 end
end
end
lbl.Size = UDim2.new(1, -(lx + right), 1, 0)
local base = self._lblBase
if base then
local btnW = self.Button.AbsoluteSize.X / math.max(self.Window.Scale.Scale, 0.01)
local avail = btnW - lx - right
if avail > 20 then
local size = base
while size > 9 and Tab._textW(lbl.Text, size, lbl.Font) > avail do size = size - 1 end
if lbl.TextSize ~= size then lbl.TextSize = size end
end
end
end
function Tab:SetBadge(v)
local T = self.Window.Theme
if v == nil or v == false or v == "" then
if self.Badge then self.Badge.Visible = false end
self:_FitLabel()
return
end
if not self.Badge then
self.Badge = new("Frame", {
AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(18, 16),
AutomaticSize = AX, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Visible = false, ZIndex = 3, Parent = self.Button,
}, { corner(8), gradient(T.Accent, T.Accent2, 0), padding(6, 0, 6, 0) })
self.BadgeLabel = Library._oa(new("TextLabel", {
Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AX, BackgroundTransparency = 1, Text = "", Font = T.FontBold, TextSize = 13,
TextColor3 = Library.OnAccent(T), Parent = self.Badge,
}))
self.Button:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
if not self.Window._spinning then self:_FitLabel() end
end)
end
self.BadgeLabel.Text = tostring(v)
self.Badge.Visible = true
self:_FitLabel()
end
local function encodeValue(v)
local t = typeof(v)
if v == nil then return { __t = "none" } end
if t == "Color3" then
return { __t = "c3", r = math.floor(v.R * 255 + 0.5), g = math.floor(v.G * 255 + 0.5), b = math.floor(v.B * 255 + 0.5) }
elseif t == "EnumItem" then
return { __t = "key", n = v.Name }
elseif t == "table" then
local a = {}
for i, x in ipairs(v) do a[i] = x end
return { __t = "list", v = a }
end
return v
end
local function decodeValue(v)
if type(v) ~= "table" then return v end
if v.__t == "c3" then return Color3.fromRGB(v.r or 0, v.g or 0, v.b or 0) end
if v.__t == "key" then return toKey(v.n) end
if v.__t == "list" then return v.v or {} end
return nil
end
function Library:ExportConfig()
local data = {}
for flag, obj in pairs(self.Objects) do
local ok, v = pcall(obj.Get, obj)
if ok then data[flag] = encodeValue(v) end
end
if self._themeData then data.__theme = self:_themeData() end
return HttpService:JSONEncode(data)
end
function Library:ImportConfig(json, silent)
local ok, data = pcall(function() return HttpService:JSONDecode(json) end)
if not ok or type(data) ~= "table" then return false, "invalid config" end
local n = 0
for flag, raw in pairs(data) do
local obj = self.Objects[flag]
if obj and obj.Set then
obj:Set(decodeValue(raw), silent)
n += 1
end
end
local td = data.__theme
if type(td) == "table" and self._applyThemeData then
pcall(self._applyThemeData, self, td, false, true)
for _, w in ipairs(self.Windows) do
if type(td.current) == "string" and self.Themes[td.current] then pcall(w.SetTheme, w, td.current, false) end
if type(td.font) == "string" then pcall(w.SetFont, w, td.font, false) end
if type(td.textScale) == "number" then pcall(w.SetTextScale, w, td.textScale, false) end
end
end
return true, n
end
local function ensureFolder(path)
local cur
for part in path:gmatch("[^/\\]+") do
cur = cur and (cur .. "/" .. part) or part
if not isfolder(cur) then makefolder(cur) end
end
end
local function cleanName(name)
name = tostring(name or ""):gsub("[^%w_%- \128-\255]", ""):gsub("^%s+", ""):gsub("%s+$", "")
return name ~= "" and name or nil
end
local function fsReady()
return type(writefile) == "function" and type(readfile) == "function" and type(isfolder) == "function" and type(makefolder) == "function"
end
function Library:SaveConfig(name)
name = cleanName(name)
if not name then return false, "invalid name" end
if not fsReady() then return false, "writefile is not supported here" end
local ok, err = pcall(function()
ensureFolder(self.ConfigFolder)
writefile(self.ConfigFolder .. "/" .. name .. ".json", self:ExportConfig())
end)
return ok, ok and name or tostring(err)
end
function Library:LoadConfig(name, silent)
name = cleanName(name)
if not name then return false, "invalid name" end
if not fsReady() or type(isfile) ~= "function" then return false, "readfile is not supported here" end
local path = self.ConfigFolder .. "/" .. name .. ".json"
local okf, exists = pcall(isfile, path)
if not okf or not exists then return false, "config not found" end
local okr, body = pcall(readfile, path)
if not okr or type(body) ~= "string" then return false, "could not read config" end
return self:ImportConfig(body, silent)
end
function Library:DeleteConfig(name)
name = cleanName(name)
if not name then return false, "invalid name" end
if type(delfile) ~= "function" or type(isfile) ~= "function" then return false, "delfile is not supported here" end
local path = self.ConfigFolder .. "/" .. name .. ".json"
if not isfile(path) then return false, "config not found" end
return pcall(delfile, path)
end
function Library:ListConfigs()
local out = {}
if type(listfiles) ~= "function" or type(isfolder) ~= "function" then return out end
local okd, isdir = pcall(isfolder, self.ConfigFolder)
if not okd or not isdir then return out end
local okl, files = pcall(listfiles, self.ConfigFolder)
if not okl or type(files) ~= "table" then return out end
for _, f in ipairs(files) do
local n = tostring(f):match("([^/\\]+)%.json$")
if n and n ~= "themes" then table.insert(out, n) end
end
table.sort(out)
return out
end
function Library:Unload()
if self._nm then pcall(function() self._nm:Destroy() end) self._nm = nil end
for i = #self.Windows, 1, -1 do self.Windows[i]:Destroy() end
table.clear(self.Flags)
table.clear(self.Objects)
end
function Library:OnFlag(cb)
table.insert(self._flagCbs, cb)
local conn = {}
function conn:Disconnect()
for i, c in ipairs(Library._flagCbs) do
if c == cb then table.remove(Library._flagCbs, i) break end
end
end
return conn
end
function Library:AutoloadConfig(name, silent)
if type(isfile) ~= "function" or not fsReady() then return false, "no filesystem" end
local path = self.ConfigFolder .. "/" .. (cleanName(name) or "") .. ".json"
if not isfile(path) then return false, "not found" end
return self:LoadConfig(name, silent)
end
function Library:SaveAuto(name)
return self:SaveConfig(name or "auto")
end
do
local KC = Enum.KeyCode
Library.Commands = {}
Library._watch = {}
Library._names = {}
Library._snaps = {}
Library.ContextMenu = true
Library.MenuHold = 0.55
Library.PaletteKey = KC.K
Library.History = { Max = 100, Merge = 0.6, Hotkeys = true, Toast = true, Undos = {}, Redos = {} }
local function deepEq(a, b)
if a == b then return true end
if type(a) ~= "table" or type(b) ~= "table" then return false end
for k, v in pairs(a) do
if not deepEq(v, b[k]) then return false end
end
for k in pairs(b) do
if a[k] == nil then return false end
end
return true
end
local function cloneVal(v)
if type(v) ~= "table" then return v end
local o = {}
for k, x in pairs(v) do o[k] = cloneVal(x) end
return o
end
local function fmtVal(v)
local t = typeof(v)
local s
if v == nil then
s = "\u{2014}"
elseif t == "boolean" then
s = v and "ON" or "OFF"
elseif t == "number" then
if v == math.floor(v) then
s = tostring(math.floor(v))
else
s = string.format("%.2f", v):gsub("0+$", ""):gsub("%.$", "")
end
elseif t == "Color3" then
s = toHex(v)
elseif t == "EnumItem" then
s = v.Name
elseif t == "table" then
local parts = {}
for _, x in ipairs(v) do table.insert(parts, tostring(x)) end
s = #parts == 0 and "\u{2014}" or table.concat(parts, ", ")
else
s = tostring(v)
end
if #s > 14 then s = s:sub(1, 13) .. "\u{2026}" end
return s
end
local function copyValue(win, v)
local text
local t = typeof(v)
if t == "Color3" then
text = toHex(v)
elseif t == "EnumItem" then
text = v.Name
elseif t == "table" then
local ok, js = pcall(function() return HttpService:JSONEncode(v) end)
text = ok and js or tostring(v)
else
text = tostring(v)
end
if type(setclipboard) == "function" then
pcall(setclipboard, text)
win:Notify({ Title = "Copied", Content = text, Kind = "Success", Duration = 1.6 })
else
win:Notify({ Title = "Clipboard not supported", Content = text, Kind = "Warning", Duration = 3 })
end
end
local function activeWindow()
for i = #Library.Windows, 1, -1 do
local w = Library.Windows[i]
if w.Visible then return w end
end
return Library.Windows[#Library.Windows]
end
local function isHidden(e)
return e.Ctl ~= nil and e.Ctl.Hidden == true
end
function Library:Watch(flag, fn)
local w = self._watch[flag]
if not w then
w = {}
self._watch[flag] = w
end
table.insert(w, fn)
return {
Disconnect = function()
local i = table.find(w, fn)
if i then table.remove(w, i) end
end,
}
end
Library:OnFlag(function(flag, v, prev)
local w = Library._watch[flag]
if w then
for _, fn in ipairs(table.clone(w)) do safe(fn, v, prev) end
end
end)
local function trimStack(list)
while #list > Library.History.Max do table.remove(list, 1) end
end
Library:OnFlag(function(flag, v, prev)
if Library._replay then return end
if prev == nil or Library.Objects[flag] == nil then return end
if Library._batch then
table.insert(Library._batch, { flag = flag, new = cloneVal(v), old = cloneVal(prev) })
return
end
local H = Library.History
local top = H.Undos[#H.Undos]
local now = os.clock()
if top and not top.group and top.flag == flag and now - top.t < H.Merge then
top.new = cloneVal(v)
top.t = now
table.clear(H.Redos)
return
end
table.insert(H.Undos, { flag = flag, new = cloneVal(v), old = cloneVal(prev), t = now })
trimStack(H.Undos)
table.clear(H.Redos)
end)
local function applyValue(flag, val)
local o = Library.Objects[flag]
if o and o.Set then
local ok, err = pcall(o.Set, o, cloneVal(val))
if not ok then warn("[SpectreUI] history apply failed: " .. tostring(err)) end
end
end
local function entryLabel(e)
if e.group then return (e.label or "Changes") .. " (" .. #e.items .. ")" end
return Library._names[e.flag] or tostring(e.flag)
end
local function toast(title, e)
if not Library.History.Toast then return end
local w = Library.Windows[#Library.Windows]
if w then w:Notify({ Title = title, Content = entryLabel(e), Kind = "Info", Duration = 1.6 }) end
end
function Library:Undo(silent)
local H = self.History
local e = table.remove(H.Undos)
if not e then return false end
self._replay = true
if e.group then
for i = #e.items, 1, -1 do applyValue(e.items[i].flag, e.items[i].old) end
else
applyValue(e.flag, e.old)
end
self._replay = false
table.insert(H.Redos, e)
if not silent then toast("Undo", e) end
return true, e
end
function Library:Redo(silent)
local H = self.History
local e = table.remove(H.Redos)
if not e then return false end
self._replay = true
if e.group then
for i = 1, #e.items do applyValue(e.items[i].flag, e.items[i].new) end
else
applyValue(e.flag, e.new)
end
self._replay = false
table.insert(H.Undos, e)
if not silent then toast("Redo", e) end
return true, e
end
function Library:CanUndo() return #self.History.Undos > 0 end
function Library:CanRedo() return #self.History.Redos > 0 end
function Library:GetHistory()
local out = {}
for i = #self.History.Undos, 1, -1 do table.insert(out, entryLabel(self.History.Undos[i])) end
return out
end
function Library:ClearHistory()
table.clear(self.History.Undos)
table.clear(self.History.Redos)
end
function Library:Transaction(label, fn)
if self._batch then return fn() end
self._batch = {}
local res = table.pack(pcall(fn))
local items = self._batch
self._batch = nil
local order, map = {}, {}
for _, it in ipairs(items) do
local m = map[it.flag]
if m then
m.new = it.new
else
m = { flag = it.flag, old = it.old, new = it.new }
map[it.flag] = m
table.insert(order, m)
end
end
local kept = {}
for _, m in ipairs(order) do
if not deepEq(m.old, m.new) then table.insert(kept, m) end
end
if #kept > 0 then
local H = self.History
table.insert(H.Undos, { group = true, label = label or "Batch", items = kept, t = os.clock() })
trimStack(H.Undos)
table.clear(H.Redos)
end
if not res[1] then error(res[2], 0) end
return table.unpack(res, 2, res.n)
end
local origImport = Library.ImportConfig
function Library:ImportConfig(json, silent)
return self:Transaction("Load config", function() return origImport(self, json, silent) end)
end
function Library:Snapshot(name)
local snap = {}
for flag, o in pairs(self.Objects) do
if o.Get then
local ok, v = pcall(o.Get, o)
if ok then snap[flag] = cloneVal(v) end
end
end
if name then self._snaps[name] = snap end
return snap
end
function Library:Restore(src, silent)
local snap = type(src) == "string" and self._snaps[src] or src
if type(snap) ~= "table" then return false, "snapshot not found" end
local n = 0
self:Transaction("Restore", function()
for flag, v in pairs(snap) do
local o = self.Objects[flag]
if o and o.Set and o.Get then
local ok, cur = pcall(o.Get, o)
if ok and not deepEq(cur, v) then
o:Set(cloneVal(v), silent)
n += 1
end
end
end
end)
return true, n
end
function Library:Diff(a, b)
if type(a) == "string" then a = self._snaps[a] end
a = a or {}
if b == nil then b = self:Snapshot() elseif type(b) == "string" then b = self._snaps[b] end
b = b or {}
local out, seen = {}, {}
for flag, v in pairs(a) do
seen[flag] = true
if not deepEq(v, b[flag]) then table.insert(out, { Flag = flag, From = v, To = b[flag] }) end
end
for flag, v in pairs(b) do
if not seen[flag] and not deepEq(a[flag], v) then table.insert(out, { Flag = flag, From = a[flag], To = v }) end
end
table.sort(out, function(x, y) return x.Flag < y.Flag end)
return out
end
function Library:CloseMenu()
if self._menuGui then
self._menuGui:Destroy()
self._menuGui = nil
end
end
function Library:ShowMenu(items, anchor, win)
win = win or self.Windows[#self.Windows]
if not win or not items or #items == 0 then return end
self:CloseMenu()
local T = win.Theme
local gui = win.Gui
local vp = gui.AbsoluteSize
local ROW = 34
local W = 196
local h = 12 + (#items - 1) * 2
for _, it in ipairs(items) do h += it.Separator and 7 or ROW end
local catcher = new("TextButton", {
Name = "SpectreMenu", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
ZIndex = 160, Parent = gui,
})
self._menuGui = catcher
catcher.MouseButton1Click:Connect(function() self:CloseMenu() end)
catcher.InputBegan:Connect(function(i)
if i.UserInputType == Enum.UserInputType.MouseButton2 then self:CloseMenu() end
end)
local x, y = vp.X / 2 - W / 2, vp.Y / 2 - h / 2
if typeof(anchor) == "Instance" then
local ap, as = anchor.AbsolutePosition, anchor.AbsoluteSize
x = ap.X + as.X - W - 6
y = ap.Y + as.Y + 2
if y + h > vp.Y - 6 then y = ap.Y - h - 2 end
end
x = math.clamp(x, 6, math.max(6, vp.X - W - 6))
y = math.clamp(y, 6, math.max(6, vp.Y - h - 6))
local menu = new("Frame", {
Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(W, h), BackgroundColor3 = T.Panel, BackgroundTransparency = 0.02,
BorderSizePixel = 0, Active = true, Parent = catcher,
}, { corner(9), stroke(T.Accent, 1, 0.4), list(2), padding(6, 6, 6, 6) })
for idx, it in ipairs(items) do
if it.Separator then
new("Frame", { LayoutOrder = idx, Size = UDim2.new(1, 0, 0, 7), BackgroundTransparency = 1, Parent = menu }, {
new("Frame", {
AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(1, 0, 0, 1),
BackgroundColor3 = T.Border, BackgroundTransparency = 0.5, BorderSizePixel = 0,
}),
})
else
local dis = it.Disabled and true or false
local b = new("TextButton", {
LayoutOrder = idx, Size = UDim2.new(1, 0, 0, ROW), BackgroundColor3 = T.Control, BackgroundTransparency = 1,
AutoButtonColor = false, Text = it.Name or "Item", Font = T.Font, TextSize = 14,
TextColor3 = dis and T.SubText or (it.Color or T.Text), TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = menu,
}, { corner(6), padding(10, 0, 8, 0) })
if not dis then feedback(b, b, "BackgroundTransparency", 1, 0.8, 0.55, true) end
b.MouseButton1Click:Connect(function()
if dis then return end
self:CloseMenu()
safe(it.Callback, it)
end)
end
end
return { Close = function() self:CloseMenu() end }
end
local function reveal(win, e)
if not win.Visible then win:SetVisible(true) end
if win.SearchBox and win.SearchBox.Text ~= "" then
win.SearchBox.Text = ""
win:_ApplySearch()
end
win:SetTab(e.Tab)
if e.Section.Collapsed then e.Section:SetCollapsed(false, true) end
e.Tab:_QueueRelayout()
task.delay(0.15, function()
if not e.Frame.Parent then return end
local T = win.Theme
local sc = e.Frame:FindFirstAncestorWhichIsA("ScrollingFrame") or e.Tab.Cols[1]
local y = e.Frame.AbsolutePosition.Y - sc.AbsolutePosition.Y + sc.CanvasPosition.Y - 28
tween(sc, 0.3, { CanvasPosition = Vector2.new(0, math.max(0, y)) })
local hl = new("Frame", {
Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Accent, BackgroundTransparency = 0.5, BorderSizePixel = 0,
ZIndex = 8, Parent = e.Frame,
}, { corner(7) })
tween(hl, 1.1, { BackgroundTransparency = 1 }, QUAD, OUT).Completed:Connect(function() hl:Destroy() end)
end)
end
Library._reveal = reveal
function Window:Goto(target)
local e
for _, x in ipairs(self._index or {}) do
if type(target) == "table" and x.Obj == target then e = x break end
if type(target) == "string" and (x.Flag == target or x.Name:lower() == target:lower()) then e = x break end
end
if e then reveal(self, e) end
return e ~= nil
end
function Library:Goto(target)
for i = #self.Windows, 1, -1 do
if self.Windows[i]:Goto(target) then return true end
end
return false
end
function Library:AddCommand(cfg)
table.insert(self.Commands, cfg)
return {
Remove = function()
local i = table.find(Library.Commands, cfg)
if i then table.remove(Library.Commands, i) end
end,
}
end
local NOJUMP = { Label = true, Paragraph = true, Separator = true, Badge = true, Progress = true, Graph = true, Console = true }
local ASSIGN = { Slider = true, Toggle = true, KeybindToggle = true, Textbox = true }
local function score(hay, q)
if q == "" then return 1 end
local total = 0
for tok in q:gmatch("%S+") do
local s = hay:find(tok, 1, true)
if s then
total += (s == 1) and 16 or 10
else
local pos = 1
for ch in tok:gmatch(".") do
local f = hay:find(ch, pos, true)
if not f then return 0 end
pos = f + 1
end
total += 3
end
end
return total
end
local function scoreEntry(e, q)
local hay = (e.Name .. " " .. e.SectionName .. " " .. e.TabName .. " " .. e.Kind):lower()
local s = score(hay, q)
if s > 0 then s += score(e.Name:lower(), q) * 2 end
return s
end
local function parseBool(s)
s = s:lower()
if s == "on" or s == "true" or s == "1" or s == "yes" then return true end
if s == "off" or s == "false" or s == "0" or s == "no" then return false end
return nil
end
local function applyAssign(win, e, av)
local o, k = e.Obj, e.Kind
local ok = false
if k == "Toggle" or k == "KeybindToggle" then
local b = parseBool(av)
if b ~= nil then
o:Set(b)
ok = true
end
elseif k == "Slider" then
local n = tonumber(av)
if n then
o:Set(n)
ok = true
end
elseif k == "Textbox" then
if e.Cfg.Numeric then
local n = tonumber(av)
if n then
o:Set(n)
ok = true
end
else
o:Set(av)
ok = true
end
end
win:Notify({
Title = e.Name, Content = ok and ("Set to " .. fmtVal(o:Get())) or "Invalid value",
Kind = ok and "Success" or "Error", Duration = 2,
})
end
local function pushRecent(win, e)
win._palRecent = win._palRecent or {}
local r = table.find(win._palRecent, e)
if r then table.remove(win._palRecent, r) end
table.insert(win._palRecent, 1, e)
while #win._palRecent > 5 do table.remove(win._palRecent) end
end
local function builtinCommands()
return {
{ Name = "Undo last change", Desc = "History", Icon = "lucide:undo-2", Callback = function() Library:Undo() end },
{ Name = "Redo", Desc = "History", Icon = "lucide:redo-2", Callback = function() Library:Redo() end },
{
Name = "Reset modified settings", Desc = #Library:GetModified() .. " modified", Icon = "lucide:rotate-ccw",
Callback = function()
Library:Confirm({
Title = "Reset settings?", Content = "Every changed setting goes back to its default. You can undo this.",
Yes = "Reset", OnYes = function() Library:ResetAll() end,
})
end,
},
}
end
local function entryItem(win, e, close)
local function valueText()
if e.Obj.Get then
local ok, v = pcall(e.Obj.Get, e.Obj)
if ok then return fmtVal(v) end
end
return e.Kind:upper()
end
local own = e.Cfg and e.Cfg.Icon
return {
title = e.Name, sub = e.TabName .. "  \u{203A}  " .. e.SectionName, chip = valueText(),
icon = (type(own) == "string" or type(own) == "number") and own or Library.KindIcons[e.Kind] or "lucide:circle",
letter = e.Kind, tabIcon = e.Tab and e.Tab.Cfg and e.Tab.Cfg.Icon, tabLetter = e.TabName,
run = function(chip)
pushRecent(win, e)
if e.Obj._locked then
win:Notify({ Title = e.Name, Content = "This control is locked", Kind = "Warning", Duration = 2 })
return
end
if (e.Kind == "Toggle" or e.Kind == "KeybindToggle") and e.Obj.Set and e.Obj.Get then
e.Obj:Set(not e.Obj:Get())
if chip then chip.Text = valueText() end
elseif e.Kind == "Button" then
close()
safe(e.Cfg.Callback)
else
close()
reveal(win, e)
end
end,
}
end
local function buildItems(win, raw, close)
local q = raw:lower():gsub("^%s+", ""):gsub("%s+$", "")
local out = {}
local an, av = raw:match("^%s*(.-)%s*=%s*(.-)%s*$")
if an and an ~= "" and av and av ~= "" then
local best, bs = nil, 0
for _, e in ipairs(win._index or {}) do
if ASSIGN[e.Kind] and not isHidden(e) then
local s = scoreEntry(e, an:lower())
if s > bs then best, bs = e, s end
end
end
if best then
table.insert(out, {
title = "Set " .. best.Name .. " = " .. av, sub = best.TabName .. "  \u{203A}  " .. best.SectionName, chip = "SET",
icon = "lucide:pencil", letter = "S", tabIcon = best.Tab and best.Tab.Cfg and best.Tab.Cfg.Icon, tabLetter = best.TabName,
run = function()
close()
applyAssign(win, best, av)
end,
})
end
end
local scored = {}
for idx, e in ipairs(win._index or {}) do
if not NOJUMP[e.Kind] and not isHidden(e) then
local s = (q == "") and 1 or scoreEntry(e, q)
if s > 0 then
if q == "" and win._palRecent then
local r = table.find(win._palRecent, e)
if r then s = 1000 - r end
end
table.insert(scored, { s = s, i = idx, e = e })
end
end
end
local cmds = {}
for _, c in ipairs(Library.Commands) do table.insert(cmds, c) end
for _, c in ipairs(builtinCommands()) do table.insert(cmds, c) end
for idx, c in ipairs(cmds) do
local nm = (c.Name or ""):lower()
local hay = nm .. " " .. (c.Desc or ""):lower() .. " " .. (c.Keywords or ""):lower()
local s = (q == "") and 0.5 or score(hay, q)
if s > 0 and q ~= "" then s += score(nm, q) * 2 end
if s > 0 then table.insert(scored, { s = s, i = 10000 + idx, c = c }) end
end
table.sort(scored, function(a, b)
if a.s ~= b.s then return a.s > b.s end
return a.i < b.i
end)
for n = 1, math.min(#scored, lowPower() and 24 or 40) do
local it = scored[n]
if it.e then
table.insert(out, entryItem(win, it.e, close))
else
local c = it.c
table.insert(out, {
title = c.Name or "Command", sub = c.Desc or "Command", chip = "CMD",
icon = c.Icon or Library.KindIcons.Command, letter = "C",
run = function()
close()
safe(c.Callback)
end,
})
end
end
return out
end
function Window:ClosePalette()
local p = self._palette
if not p then return end
self._palette = nil
p.overlay:Destroy()
end
function Window:OpenPalette(initial)
if self._palette then
self:ClosePalette()
return
end
self:CloseDropdowns()
Library:CloseMenu()
local T, gui = self.Theme, self.Gui
local vp = gui.AbsoluteSize
local top = (vp.Y < 520) and 8 or 56
local W = math.min(420, vp.X - 20)
local H = math.clamp(vp.Y - top - 16, 150, 400)
local cx = nil
do
local main = self.Main
if main and main.Visible and main.AbsoluteSize.X > 0 and self.Visible ~= false then
local o = gui.AbsolutePosition
local mp, ms = main.AbsolutePosition - o, main.AbsoluteSize
local gap = (ms.Y < 360) and 8 or 56
top = mp.Y + gap
cx = mp.X + ms.X / 2
W = math.min(420, ms.X - 20)
H = math.clamp(ms.Y - gap - 16, 150, 400)
end
end
local cardX = cx and UDim2.fromOffset(cx, 0) or UDim2.fromScale(0.5, 0)
local overlay = new("TextButton", {
Name = "SpectrePalette", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
Text = "", AutoButtonColor = false, ZIndex = 150, Parent = gui,
})
local card = new("Frame", {
AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(cardX.X.Scale, cardX.X.Offset, 0, top - 10), Size = UDim2.fromOffset(W, H),
BackgroundColor3 = T.Panel, BackgroundTransparency = 1, BorderSizePixel = 0, Active = true, Parent = overlay,
}, { corner(12), stroke(T.Accent, 1, 0.35), wash(cseq({ 0, T.Top }, { 1, T.Panel }), 90) })
local box = new("TextBox", {
Position = UDim2.fromOffset(12, 10), Size = UDim2.new(1, -24, 0, 36), BackgroundColor3 = T.Control, BackgroundTransparency = 0.1,
BorderSizePixel = 0, Text = initial or "", PlaceholderText = "Search settings or run a command   (try: speed = 50)",
PlaceholderColor3 = T.SubText, TextColor3 = T.Text, Font = T.Font, TextSize = 14, TextXAlignment = LEFT,
ClearTextOnFocus = false, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card,
}, { corner(8), stroke(T.Border, 1, 0.35), padding(10, 0, 10, 0) })
local scroll = new("ScrollingFrame", { ElasticBehavior = Enum.ElasticBehavior.Never,
Position = UDim2.fromOffset(8, 54), Size = UDim2.new(1, -16, 1, -62), BackgroundTransparency = 1, BorderSizePixel = 0,
ScrollBarThickness = 3, ScrollBarImageColor3 = T.Accent, CanvasSize = UDim2.new(), AutomaticCanvasSize = AY,
ScrollingDirection = Enum.ScrollingDirection.Y, Parent = card,
}, { list(4) })
local state = { overlay = overlay, card = card }
self._palette = state
local function close()
if self._palette == state then self:ClosePalette() end
end
overlay.MouseButton1Click:Connect(close)
local rows, current, sel = {}, {}, 1
local ROWH = 44
local PADY = (ROWH - 40) / 2
local function paintSel()
for i, r in ipairs(rows) do
local m = r:FindFirstChild("Sel")
if m then m.Visible = (i == sel) and not false end
end
end
local function makeRow(it, idx)
local btn = new("TextButton", {
LayoutOrder = idx, Size = UDim2.new(1, 0, 0, ROWH), BackgroundColor3 = T.Control, BackgroundTransparency = 1,
Text = "", AutoButtonColor = false, Parent = scroll,
}, { corner(8) })
new("Frame", {
Name = "Sel", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0), Size = UDim2.fromOffset(3, ROWH - 16),
BackgroundColor3 = T.Accent, BorderSizePixel = 0, Visible = false, Parent = btn,
}, { corner(2) })
feedback(btn, btn, "BackgroundTransparency", 1, 0.8, 0.55, true)
Library._iconBadge(btn, it.icon, it.letter, T.Accent, 32, nil, T).Position = UDim2.new(0, 8, 0.5, 0)
local subX = 48
if it.tabLetter then
Library._iconBadge(btn, it.tabIcon, it.tabLetter, T.SubText, 14, nil, T, true).Position = UDim2.fromOffset(48, 21 + PADY + 7)
subX = 66
end
new("TextLabel", {
Position = UDim2.fromOffset(48, 3 + PADY), Size = UDim2.new(1, -140, 0, 18), BackgroundTransparency = 1, Text = it.title,
Font = T.FontBold, TextSize = 14, TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = btn,
})
new("TextLabel", {
Position = UDim2.fromOffset(subX, 21 + PADY), Size = UDim2.new(1, -(subX + 92), 0, 14), BackgroundTransparency = 1, Text = it.sub or "",
Font = T.Font, TextSize = 14, TextColor3 = T.SubText, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = btn,
})
local chip = new("TextLabel", {
Name = "Chip", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(80, 20),
BackgroundColor3 = T.AccentSoft, BorderSizePixel = 0, Text = it.chip or "", Font = T.FontBold, TextSize = 14,
TextColor3 = T.Accent, TextTruncate = Enum.TextTruncate.AtEnd, Parent = btn,
}, { corner(10), padding(6, 0, 6, 0) })
btn.MouseButton1Click:Connect(function() it.run(chip) end)
return btn
end
local function refresh()
for _, r in ipairs(rows) do r:Destroy() end
table.clear(rows)
current = buildItems(self, box.Text, close)
for idx, it in ipairs(current) do rows[idx] = makeRow(it, idx) end
scroll.CanvasPosition = Vector2.zero
sel = 1
paintSel()
end
local queued = false
box:GetPropertyChangedSignal("Text"):Connect(function()
if queued then return end
queued = true
task.delay(0.07, function()
queued = false
if self._palette == state then refresh() end
end)
end)
box.FocusLost:Connect(function(enter)
if enter and current[sel] and rows[sel] then current[sel].run(rows[sel]:FindFirstChild("Chip")) end
end)
state.Move = function(d)
if #rows == 0 then return end
sel = math.clamp(sel + d, 1, #rows)
paintSel()
local r = rows[sel]
local px = math.max(r.AbsoluteSize.Y / ROWH, 0.01)
local delta = (r.AbsolutePosition.Y - scroll.AbsolutePosition.Y) / px
local view = scroll.AbsoluteSize.Y / px
if delta < 0 then
scroll.CanvasPosition += Vector2.new(0, delta)
elseif delta + ROWH > view then
scroll.CanvasPosition += Vector2.new(0, delta + ROWH - view)
end
end
do
local okR, errR = pcall(refresh)
if not okR then warn("[SpectreUI] palette refresh failed: " .. tostring(errR)) end
end
tween(overlay, 0.15, { BackgroundTransparency = 0.55 })
tween(card, 0.18, { BackgroundTransparency = 0.02, Position = UDim2.new(cardX.X.Scale, cardX.X.Offset, 0, top) })
task.delay(0.04, function()
if box.Parent then box:CaptureFocus() end
end)
end
local function ensureInput()
if Library._inp then return end
Library._inp = UserInputService.InputBegan:Connect(function(i, gp)
if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
if i.KeyCode == KC.Escape then
Library:CloseMenu()
for _, w in ipairs(Library.Windows) do
if w._palette then w:ClosePalette() end
end
elseif i.KeyCode == KC.Down or i.KeyCode == KC.Up then
for _, w in ipairs(Library.Windows) do
if w._palette and w._palette.Move then w._palette.Move(i.KeyCode == KC.Down and 1 or -1) end
end
end
if gp or Library._listening then return end
local ctrl = UserInputService:IsKeyDown(KC.LeftControl) or UserInputService:IsKeyDown(KC.RightControl)
if not ctrl then return end
local w = activeWindow()
if not w then return end
if i.KeyCode == Library.PaletteKey then
w:OpenPalette()
elseif Library.History.Hotkeys and w.Visible then
local shift = UserInputService:IsKeyDown(KC.LeftShift) or UserInputService:IsKeyDown(KC.RightShift)
if i.KeyCode == KC.Z then
if shift then Library:Redo() else Library:Undo() end
elseif i.KeyCode == KC.Y then
Library:Redo()
end
end
end)
end
local origCreateWindow = Library.CreateWindow
function Library:CreateWindow(cfg)
ensureInput()
local win = origCreateWindow(self, cfg)
win._index = win._index or {}
return win
end
function Library:SetQuality(q)
self.Perf.LowPower = (q == "low") and true or (q == "high") and false or nil
end
local origUnload = Library.Unload
function Library:Unload()
self:CloseMenu()
origUnload(self)
if self._inp then
self._inp:Disconnect()
self._inp = nil
end
table.clear(self._watch)
table.clear(self._names)
self:ClearHistory()
end
function Section:CreateSegmented(cfg)
cfg = cfg or {}
local T = self.Window.Theme
local touch = Library.SizeTouch
local options = cfg.Options or {}
local value = cfg.Default
if value == nil then value = options[1] end
local barH = touch and 34 or 28
local total = 22 + barH + 2
local frame = new("Frame", { Size = UDim2.new(1, 0, 0, total), BackgroundTransparency = 1, Parent = self.Body })
new("TextLabel", {
Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = cfg.Name or "Mode", Font = T.Font, TextSize = 14,
TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
})
local bar = new("Frame", {
Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0, barH), BackgroundColor3 = T.Control, BackgroundTransparency = 0.1,
BorderSizePixel = 0, Parent = frame,
}, { corner(2), stroke(T.Border, 1, 0.4), padding(3, 3, 3, 3) })
local holder = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = bar },
{ list(3, { FillDirection = Enum.FillDirection.Horizontal }) })
local btns = {}
local obj = {}
local function paint()
for _, b in ipairs(btns) do
local on = b.opt == value
tween(b.btn, 0.18, { BackgroundTransparency = on and 0 or 1 })
tween(b.lbl, 0.18, { TextColor3 = on and Library.OnAccent(T) or T.SubText })
b.lbl:SetAttribute("OnAccent", on or nil)
end
end
local function build()
for _, b in ipairs(btns) do b.btn:Destroy() end
btns = {}
local n = math.max(#options, 1)
for idx, opt in ipairs(options) do
local b = new("TextButton", {
LayoutOrder = idx, Size = UDim2.new(1 / n, -(3 * (n - 1)) / n, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1),
BackgroundTransparency = 1, AutoButtonColor = false, Text = "", Parent = holder,
}, { corner(2), gradient(T.Accent, T.Accent2, 0) })
local lbl = new("TextLabel", {
Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = tostring(opt), Font = T.Font, TextSize = 14,
TextColor3 = T.SubText, TextTruncate = Enum.TextTruncate.AtEnd, Parent = b,
})
b.MouseButton1Click:Connect(function() obj:Set(opt) end)
table.insert(btns, { btn = b, lbl = lbl, opt = opt })
end
paint()
end
function obj:Set(v, silent)
if table.find(options, v) == nil then return end
local changed = v ~= value
value = v
paint()
setFlag(cfg, v)
if changed and not silent then safe(cfg.Callback, v) end
end
function obj:Get() return value end
function obj:SetOptions(list, keep)
options = list or {}
if not (keep and table.find(options, value)) then value = options[1] end
build()
setFlag(cfg, value)
end
build()
setFlag(cfg, value)
self:_Register(frame, cfg.Name, total)
obj.Frame = frame
return regObj(cfg, obj)
end
function Section:CreateRangeSlider(cfg)
cfg = cfg or {}
local T = self.Window.Theme
local tab = self.Tab
local min, max, inc = cfg.Min or 0, cfg.Max or 100, cfg.Increment or 1
local gap = cfg.MinGap or 0
local suffix = cfg.Suffix or ""
local d = cfg.Default or { min, max }
local lo, hi = snap(d[1] or min, min, max, inc), snap(d[2] or max, min, max, inc)
if lo > hi then lo, hi = hi, lo end
local touch = Library.SizeTouch
local total = touch and 50 or 42
local knobS, knobBig = touch and 16 or 12, touch and 20 or 15
local frame = new("Frame", { Size = UDim2.new(1, 0, 0, total), BackgroundTransparency = 1, Parent = self.Body })
new("TextLabel", {
Size = UDim2.new(1, -112, 0, 18), BackgroundTransparency = 1, Text = cfg.Name or "Range", Font = T.Font, TextSize = 14,
TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
})
local loBox, hiBox
local hit = new("TextButton", {
Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 1, -20), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = frame,
})
local track = new("Frame", {
AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(1, 0, 0, 4),
BackgroundColor3 = T.Control, BorderSizePixel = 0, Parent = hit,
}, { corner(2) })
local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = track },
{ corner(2), gradient(T.Accent, T.Accent2, 0) })
local function mkKnob()
return new("Frame", {
AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(knobS, knobS),
BackgroundColor3 = T.Knob, BorderSizePixel = 0, ZIndex = 2, Parent = track,
}, { new("UICorner", { CornerRadius = UDim.new(0, 8) }), stroke(T.Accent, 2, 0) })
end
local knobLo, knobHi = mkKnob(), mkKnob()
local function frac(v) return (max == min) and 0 or (v - min) / (max - min) end
local function render(animate)
local a, b = frac(lo), frac(hi)
loBox.Text, hiBox.Text = fmtVal(lo), fmtVal(hi) .. suffix
local fp, fs = UDim2.fromScale(a, 0), UDim2.fromScale(b - a, 1)
local kl, kh = UDim2.fromScale(a, 0.5), UDim2.fromScale(b, 0.5)
if animate then
tween(fill, 0.18, { Position = fp, Size = fs })
tween(knobLo, 0.18, { Position = kl })
tween(knobHi, 0.18, { Position = kh })
else
fill.Position, fill.Size, knobLo.Position, knobHi.Position = fp, fs, kl, kh
end
end
local obj = {}
function obj:Set(v, silent)
if type(v) ~= "table" then return end
local a = snap(tonumber(v[1]) or lo, min, max, inc)
local b = snap(tonumber(v[2]) or hi, min, max, inc)
if a > b then a, b = b, a end
local changed = a ~= lo or b ~= hi
lo, hi = a, b
render(true)
setFlag(cfg, { lo, hi })
if changed and not silent then safe(cfg.Callback, lo, hi) end
end
function obj:Get() return { lo, hi } end
loBox = Library._numBox(T, {
AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -64, 0, 0), Size = UDim2.fromOffset(48, 20), Parent = frame,
}, "", function() return fmtVal(lo) end, function(n)
if n == nil then render(false) else obj:Set({ math.max(math.min(n, hi - gap), min), hi }) end
end)
new("TextLabel", {
AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -56, 0, 0), Size = UDim2.fromOffset(8, 20), BackgroundTransparency = 1,
Text = "-", Font = T.FontBold, TextSize = 14, TextColor3 = T.SubText, Parent = frame,
})
hiBox = Library._numBox(T, {
AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(56, 20), Parent = frame,
}, suffix, function() return fmtVal(hi) end, function(n)
if n == nil then render(false) else obj:Set({ lo, math.min(math.max(n, lo + gap), max) }) end
end)
render(false)
setFlag(cfg, { lo, hi })
local function fromX(x, which)
local a = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
local v = snap(min + (max - min) * a, min, max, inc)
local nl, nh = lo, hi
if which == "lo" then nl = math.min(v, hi - gap) else nh = math.max(v, lo + gap) end
nl, nh = math.clamp(nl, min, max), math.clamp(nh, min, max)
if nl ~= lo or nh ~= hi then
lo, hi = nl, nh
render(false)
setFlag(cfg, { lo, hi })
safe(cfg.Callback, lo, hi)
end
end
local grabbed
local function release()
tab:SetScrollEnabled(true)
if grabbed then
tween(grabbed, 0.16, { Size = UDim2.fromOffset(knobS, knobS) })
grabbed = nil
end
end
hit.InputBegan:Connect(function(i)
if not isPress(i) then return end
local tx, tw = track.AbsolutePosition.X, math.max(track.AbsoluteSize.X, 1)
local pl, ph = tx + frac(lo) * tw, tx + frac(hi) * tw
local x = i.Position.X
local which
if lo == hi then
which = (x < pl) and "lo" or "hi"
else
which = (math.abs(x - pl) <= math.abs(x - ph)) and "lo" or "hi"
end
Library._drag(i, function(m) fromX(m.Position.X, which) end, release)
tab:SetScrollEnabled(false)
grabbed = (which == "lo") and knobLo or knobHi
tween(grabbed, 0.12, { Size = UDim2.fromOffset(knobBig, knobBig) })
fromX(x, which)
end)
self:_Register(frame, cfg.Name, total)
obj.Frame = frame
return regObj(cfg, obj)
end
function Section:CreateTagInput(cfg)
cfg = cfg or {}
local T = self.Window.Theme
local touch = Library.SizeTouch
local tags = {}
local obj = {}
local function norm(s)
s = tostring(s):gsub("^%s+", ""):gsub("%s+$", "")
if cfg.Lower then s = s:lower() end
return s
end
for _, t in ipairs(cfg.Default or {}) do
local n = norm(t)
if n ~= "" and not table.find(tags, n) then table.insert(tags, n) end
end
local frame = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Parent = self.Body }, { list(6) })
new("TextLabel", {
LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = cfg.Name or "Tags", Font = T.Font, TextSize = 14,
TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
})
local inputRow = new("Frame", { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, touch and 34 or 30), BackgroundTransparency = 1, Parent = frame })
local box = new("TextBox", {
Size = UDim2.new(1, -40, 1, 0), BackgroundColor3 = T.Control, BackgroundTransparency = 0.1, BorderSizePixel = 0, Text = "",
PlaceholderText = cfg.Placeholder or "Add and press Enter", PlaceholderColor3 = T.SubText, TextColor3 = T.Text, Font = T.Font,
TextSize = 14, TextXAlignment = LEFT, ClearTextOnFocus = false, Parent = inputRow,
}, { corner(2), stroke(T.Border, 1, 0.4), padding(10, 0, 10, 0) })
local addBtn = new("TextButton", {
AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 34, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1),
AutoButtonColor = false, Text = "", Parent = inputRow,
}, { corner(2), gradient(T.Accent, T.Accent2, 0) })
Library._oa(new("TextLabel", {
Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "+", Font = T.FontBold, TextSize = 18,
TextColor3 = Library.OnAccent(T), Parent = addBtn,
}))
local chips = new("Frame", { LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Parent = frame },
{ list(6, { FillDirection = Enum.FillDirection.Horizontal, Wraps = true }) })
local function rebuild()
for _, c in ipairs(chips:GetChildren()) do
if c:IsA("GuiObject") then c:Destroy() end
end
for idx, tag in ipairs(tags) do
local chip = new("Frame", {
LayoutOrder = idx, Size = UDim2.new(0, 0, 0, touch and 30 or 24), AutomaticSize = AX, BackgroundColor3 = T.AccentSoft, BorderSizePixel = 0, Parent = chips,
}, { corner(2), stroke(T.Accent, 1, 0.6),
list(0, { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center }),
padding(10, 0, 4, 0) })
new("TextLabel", {
LayoutOrder = 1, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = AX, BackgroundTransparency = 1, Text = tag, Font = T.Font,
TextSize = 13, TextColor3 = T.Text, Parent = chip,
})
local x = new("TextButton", {
LayoutOrder = 2, Size = UDim2.fromOffset(touch and 30 or 22, touch and 30 or 22), BackgroundTransparency = 1, Text = "\u{00D7}", Font = T.FontBold,
TextSize = 14, TextColor3 = T.SubText, AutoButtonColor = false, Parent = chip,
})
x.MouseButton1Click:Connect(function() obj:Remove(tag) end)
end
end
local function commit(silent)
setFlag(cfg, cloneVal(tags))
rebuild()
if not silent then safe(cfg.Callback, cloneVal(tags)) end
end
function obj:Add(t, silent)
t = norm(t)
if t == "" or table.find(tags, t) then return false end
if cfg.Max and #tags >= cfg.Max then return false end
table.insert(tags, t)
commit(silent)
return true
end
function obj:Remove(t, silent)
local i = table.find(tags, t)
if not i then return false end
table.remove(tags, i)
commit(silent)
return true
end
function obj:Has(t) return table.find(tags, norm(t)) ~= nil end
function obj:Set(list, silent)
tags = {}
for _, t in ipairs(type(list) == "table" and list or {}) do
local n = norm(t)
if n ~= "" and not table.find(tags, n) then table.insert(tags, n) end
end
commit(silent)
end
function obj:Get() return cloneVal(tags) end
local function submit()
for part in box.Text:gmatch("[^,]+") do obj:Add(part) end
box.Text = ""
end
box.FocusLost:Connect(function(enter)
if enter then submit() end
end)
addBtn.MouseButton1Click:Connect(submit)
rebuild()
setFlag(cfg, cloneVal(tags))
self:_Register(frame, cfg.Name, 76)
obj.Frame = frame
return regObj(cfg, obj)
end
function Section:CreateHoldButton(cfg)
cfg = cfg or {}
local T = self.Window.Theme
local dur = cfg.Duration or 1
local accent = cfg.Color or Color3.fromRGB(248, 113, 113)
local h = rowH()
local b = new("TextButton", {
Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = T.Control, BackgroundTransparency = 0.1, AutoButtonColor = false, Text = "",
ClipsDescendants = true, Parent = self.Body,
}, { corner(2), stroke(accent, 1, 0.5) })
local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = b },
{ corner(2), gradient(accent, accent:Lerp(Color3.new(1, 1, 1), 0.3), 0) })
local label = new("TextLabel", {
Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = cfg.Name or "Hold to confirm", Font = T.Font, TextSize = 14,
TextColor3 = T.Text, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 2, Parent = b,
})
local obj = { Frame = b }
function obj:SetText(t)
cfg.Name = t
label.Text = t
end
local tw, holding, seq = nil, false, 0
local function down()
holding = true
seq += 1
local mine = seq
if tw then tw:Cancel() end
fill.Size = UDim2.fromScale(0, 1)
local t = TweenService:Create(fill, TweenInfo.new(dur, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(1, 1) })
tw = t
t.Completed:Connect(function(state)
if state ~= Enum.PlaybackState.Completed or tw ~= t or not holding then return end
holding = false
tw = nil
label.Text = cfg.DoneText or "Done"
safe(cfg.Callback)
task.delay(0.45, function()
if seq ~= mine then return end
label.Text = cfg.Name or "Hold to confirm"
tween(fill, 0.3, { Size = UDim2.fromScale(0, 1) })
end)
end)
t:Play()
end
local function up()
holding = false
if tw then
tw:Cancel()
tw = nil
tween(fill, 0.14, { Size = UDim2.fromScale(0, 1) }, QUAD, OUT)
end
end
dragSafePress(b, down, function() up() end, 12)
self:_Register(b, cfg.Name, h)
return obj
end
function Section:CreateGraph(cfg)
cfg = cfg or {}
local T = self.Window.Theme
local N = math.clamp(cfg.Points or 30, 5, 120)
local H = cfg.Height or 56
local color = cfg.Color or T.Accent
local suffix = cfg.Suffix or ""
local total = 22 + H + 4
local frame = new("Frame", { Size = UDim2.new(1, 0, 0, total), BackgroundTransparency = 1, Parent = self.Body })
new("TextLabel", {
Size = UDim2.new(1, -90, 0, 18), BackgroundTransparency = 1, Text = cfg.Name or "Graph", Font = T.Font, TextSize = 14,
TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
})
local valLabel = new("TextLabel", {
AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(86, 18), BackgroundTransparency = 1,
Text = "", Font = T.FontBold, TextSize = 14, TextColor3 = T.Accent, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
})
local area = new("Frame", {
Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0, H), BackgroundColor3 = T.Control, BackgroundTransparency = 0.15,
BorderSizePixel = 0, ClipsDescendants = true, Parent = frame,
}, { corner(7), stroke(T.Border, 1, 0.45) })
local bars, data = {}, {}
for i = 1, N do
bars[i] = new("Frame", {
AnchorPoint = Vector2.new(0, 1), Position = UDim2.new((i - 1) / N, 1, 1, 0), Size = UDim2.new(1 / N, -2, 0, 0),
BackgroundColor3 = color, BackgroundTransparency = 0.15, BorderSizePixel = 0, Parent = area,
})
end
local function render()
local lo, hi = cfg.Min, cfg.Max
if lo == nil or hi == nil then
local dmin, dmax = math.huge, -math.huge
for _, v in ipairs(data) do
dmin = math.min(dmin, v)
dmax = math.max(dmax, v)
end
if dmin == math.huge then dmin, dmax = 0, 1 end
if lo == nil then lo = math.min(0, dmin) end
if hi == nil then hi = dmax end
end
if hi == lo then hi = lo + 1 end
local off = N - #data
for i = 1, N do
local v = data[i - off]
local a = v and math.clamp((v - lo) / (hi - lo), 0, 1) or 0
bars[i].Size = UDim2.new(1 / N, -2, a, v and 2 or 0)
bars[i].BackgroundColor3 = (i == N and v) and T.Accent2 or color
end
end
local obj = { Frame = frame }
function obj:Push(v)
v = tonumber(v) or 0
table.insert(data, v)
if #data > N then table.remove(data, 1) end
valLabel.Text = fmtVal(v) .. suffix
render()
end
function obj:Clear()
table.clear(data)
valLabel.Text = ""
render()
end
function obj:SetRange(lo, hi)
cfg.Min, cfg.Max = lo, hi
render()
end
function obj:Get() return data[#data] end
for _, v in ipairs(cfg.Data or {}) do obj:Push(v) end
render()
self:_Register(frame, cfg.Name, total)
return obj
end
function Section:CreateConsole(cfg)
cfg = cfg or {}
local T = self.Window.Theme
local H = cfg.Height or 120
local maxLines = cfg.MaxLines or 100
local total = 24 + H + 4
local frame = new("Frame", { Size = UDim2.new(1, 0, 0, total), BackgroundTransparency = 1, Parent = self.Body })
new("TextLabel", {
Size = UDim2.new(1, -64, 0, 20), BackgroundTransparency = 1, Text = cfg.Name or "Console", Font = T.Font, TextSize = 14,
TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
})
local clearBtn = new("TextButton", {
AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(52, 20), BackgroundColor3 = T.Control,
BackgroundTransparency = 0.1, AutoButtonColor = false, Text = "Clear", Font = T.Font, TextSize = 14, TextColor3 = T.SubText, Parent = frame,
}, { corner(10), stroke(T.Border, 1, 0.4) })
local view = new("ScrollingFrame", { ElasticBehavior = Enum.ElasticBehavior.Never,
Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, H), BackgroundColor3 = T.Deep, BackgroundTransparency = 0.1,
BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = T.Accent, CanvasSize = UDim2.new(), AutomaticCanvasSize = AY,
ScrollingDirection = Enum.ScrollingDirection.Y, Parent = frame,
}, { corner(7), stroke(T.Border, 1, 0.45), list(1), padding(8, 6, 8, 6) })
local lines, order, scrollQueued = {}, 0, false
local obj = { Frame = frame }
local COLORS = {
Info = T.Text, Success = Color3.fromRGB(52, 211, 153), Warn = Color3.fromRGB(251, 191, 36), Error = Color3.fromRGB(248, 113, 113),
}
function obj:Print(text, color)
order += 1
local stamp = (cfg.Timestamp ~= false) and (os.date("%H:%M:%S") .. "  ") or ""
local l = new("TextLabel", {
LayoutOrder = order, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Text = stamp .. tostring(text),
Font = Enum.Font.Code, TextSize = 13, TextColor3 = color or T.Text, TextXAlignment = LEFT, TextWrapped = true, Parent = view,
})
table.insert(lines, l)
if #lines > maxLines then
local old = table.remove(lines, 1)
old:Destroy()
end
if not scrollQueued then
scrollQueued = true
task.delay(0.03, function()
scrollQueued = false
if view.Parent then view.CanvasPosition = Vector2.new(0, 1e6) end
end)
end
return l
end
for name, col in pairs(COLORS) do
obj[name] = function(self, text) return self:Print(text, col) end
end
function obj:Clear()
for _, l in ipairs(lines) do l:Destroy() end
lines = {}
end
function obj:GetText()
local out = {}
for _, l in ipairs(lines) do table.insert(out, l.Text) end
return table.concat(out, "\n")
end
function obj:Copy()
if type(setclipboard) == "function" then
pcall(setclipboard, self:GetText())
return true
end
return false
end
clearBtn.MouseButton1Click:Connect(function() obj:Clear() end)
self:_Register(frame, cfg.Name, total)
return obj
end
local NOVALUE = { Progress = true, Badge = true, Label = true, Paragraph = true, Graph = true, Console = true, Separator = true }
local function buildMenuItems(entry)
local obj, win = entry.Obj, entry.Section.Window
local items = {}
if entry.Flag and obj.Get and obj.IsModified then
table.insert(items, { Name = "Reset to default", Disabled = not obj:IsModified(), Callback = function() obj:Reset() end })
table.insert(items, { Name = "Copy value", Callback = function()
local ok, v = pcall(obj.Get, obj)
if ok then copyValue(win, v) end
end })
end
if obj.SetEnabled then
table.insert(items, { Name = obj._locked and "Unlock" or "Lock", Callback = function() obj:SetEnabled(obj._locked) end })
end
if obj._tipText and obj._tipText ~= "" then
table.insert(items, { Name = "What is this?", Callback = function()
win:Notify({ Title = entry.Name, Content = obj._tipText, Kind = "Info", Duration = 5 })
end })
end
local custom = entry.Cfg.ContextMenu
if type(custom) == "table" and #custom > 0 then
if #items > 0 then table.insert(items, { Separator = true }) end
for _, it in ipairs(custom) do
table.insert(items, {
Name = it.Name, Color = it.Color, Disabled = it.Disabled,
Callback = function() safe(it.Callback, obj) end,
})
end
end
return items
end
local function attachMenu(entry)
local frame, win = entry.Frame, entry.Section.Window
local function open()
if Library.ContextMenu == false then return end
local items = buildMenuItems(entry)
if #items > 0 then Library:ShowMenu(items, frame, win) end
end
local function hookRight(g)
g.InputBegan:Connect(function(i)
if i.UserInputType == Enum.UserInputType.MouseButton2 then open() end
end)
end
if UserInputService.MouseEnabled then
hookRight(frame)
for _, d in ipairs(frame:GetDescendants()) do
if d:IsA("GuiButton") then hookRight(d) end
end
end
if not false then return end
frame.InputBegan:Connect(function(i)
if i.UserInputType ~= Enum.UserInputType.Touch then return end
local start = Vector2.new(i.Position.X, i.Position.Y)
local held = true
local mc = i.Changed:Connect(function(prop)
if prop == "Position" and (Vector2.new(i.Position.X, i.Position.Y) - start).Magnitude > 10 then held = false end
end)
onEnd(i, function()
held = false
mc:Disconnect()
end)
task.delay(Library.MenuHold or 0.55, function()
if held then
held = false
mc:Disconnect()
open()
end
end)
end)
end
local function decorate(sec, kind, cfg, obj)
local win = sec.Window
local T = win.Theme
local frame = obj.Frame
if typeof(frame) ~= "Instance" then return end
obj.Kind = obj.Kind or kind
local ctl
for i = #sec.Controls, 1, -1 do
local c = sec.Controls[i]
if c.Frame == frame then ctl = c break end
end
local entry = {
Kind = kind, Name = tostring(cfg.Name or cfg.Title or cfg.Text or kind), Obj = obj, Cfg = cfg, Section = sec, Tab = sec.Tab,
Frame = frame, Ctl = ctl, Flag = cfg.Flag, SectionName = sec.Name, TabName = sec.Tab.Name,
}
win._index = win._index or {}
table.insert(win._index, entry)
if cfg.Flag then Library._names[cfg.Flag] = entry.Name end
local conns = {}
local function def(name, fn)
if obj[name] == nil then obj[name] = fn end
end
if cfg.Flag and obj.Get and obj.Set and not NOVALUE[kind] then
local ok, v = pcall(obj.Get, obj)
if ok then
obj._default = cloneVal(v)
obj._hasDefault = true
end
local dot, dotSeq = nil, 0
local isToggle = (kind == "Toggle" or kind == "KeybindToggle")
local noDot = Library.ModDot == false or cfg.ModDot == false
local function applyDot(val)
local on
if noDot then on = false
elseif isToggle then on = (val == true)
else on = (obj._hasDefault and not deepEq(val, obj._default)) or false end
if on and not dot then
dot = new("Frame", {
Name = "ModDot", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 1, 0, math.floor(rowH() / 2)), Size = UDim2.fromOffset(5, 5),
BackgroundColor3 = T.Accent, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 10, Visible = false, Parent = frame,
}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
end
if not dot then return end
dotSeq += 1
local my = dotSeq
if on then
dot.Visible = true
tween(dot, 0.18, { BackgroundTransparency = 0 })
else
tween(dot, 0.16, { BackgroundTransparency = 1 }).Completed:Connect(function()
if dotSeq == my and dot then dot.Visible = false end
end)
end
end
table.insert(conns, Library:Watch(cfg.Flag, applyDot))
if isToggle and ok then applyDot(v) end
sec._objs = sec._objs or {}
table.insert(sec._objs, obj)
end
def("IsModified", function(self)
if not self._hasDefault or not self.Get then return false end
local ok, cur = pcall(self.Get, self)
return ok and not deepEq(cur, self._default)
end)
def("Reset", function(self, silent)
if not self._hasDefault then return false end
self:Set(cloneVal(self._default), silent)
return true
end)
def("OnChange", function(self, fn)
if not cfg.Flag then
warn("[SpectreUI] OnChange needs a Flag on '" .. entry.Name .. "'")
return { Disconnect = function() end }
end
local c = Library:Watch(cfg.Flag, fn)
table.insert(conns, c)
return c
end)
def("SetVisible", function(self, v)
v = v and true or false
if ctl then ctl.Hidden = not v end
if sec.Tab == win.Active then
win:_ApplySearch()
else
frame.Visible = v
end
sec.Tab:_QueueRelayout()
end)
def("IsVisible", function() return not (ctl and ctl.Hidden) end)
def("ShowIf", function(self, src, expected)
if self._showConn then self._showConn.Disconnect() end
local flags = type(src) == "table" and src or { src }
local function eval()
local ok, show = pcall(function()
if type(expected) == "function" then
if type(src) == "table" then return expected(Library.Flags) end
return expected(Library.Flags[flags[1]], Library.Flags)
elseif expected == nil then
return Library.Flags[flags[1]]
end
return deepEq(Library.Flags[flags[1]], expected)
end)
self:SetVisible(ok and show and true or false)
end
local cs = {}
for _, f in ipairs(flags) do table.insert(cs, Library:Watch(f, eval)) end
self._showConn = { Disconnect = function() for _, c in ipairs(cs) do c:Disconnect() end end }
table.insert(conns, self._showConn)
eval()
return self
end)
def("SetEnabled", function(self, v)
local locked = not v
self._locked = locked
if locked and self.IsOpen and self.Close then pcall(self.Close, self) end
if locked and not self._lockGui then
self._lockGui = new("TextButton", {
Name = "Lock", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Background, BackgroundTransparency = 0.35, Text = "",
AutoButtonColor = false, Active = true, ZIndex = 20, Visible = false, Parent = frame,
}, { corner(7) })
end
if self._lockGui then self._lockGui.Visible = locked end
end)
def("Lock", function(self) self:SetEnabled(false) end)
def("Unlock", function(self) self:SetEnabled(true) end)
def("IsEnabled", function(self) return not self._locked end)
def("SetTooltip", function(self, text)
self._tipText = text
if not self._tipBound and text and text ~= "" then
self._tipBound = true
win:Tooltip(frame, function() return self._tipText end)
end
end)
if cfg.Tooltip then obj:SetTooltip(cfg.Tooltip) end
def("Destroy", function(self)
for _, c in ipairs(conns) do c.Disconnect() end
table.clear(conns)
for i, c in ipairs(sec.Controls) do
if c == ctl then table.remove(sec.Controls, i) break end
end
for i, c in ipairs(sec.Controls) do c.Frame.LayoutOrder = i end
local ix = table.find(win._index, entry)
if ix then table.remove(win._index, ix) end
if sec._objs then
local ox = table.find(sec._objs, self)
if ox then table.remove(sec._objs, ox) end
end
if cfg.Flag and Library.Objects[cfg.Flag] == self then
Library.Objects[cfg.Flag] = nil
Library.Flags[cfg.Flag] = nil
end
frame:Destroy()
sec.Tab:_QueueRelayout()
end)
if (cfg.Flag and obj.Get and not NOVALUE[kind]) or cfg.ContextMenu then
if not cfg.NoMenu then attachMenu(entry) end
end
end
Library._decorate, Library._NOVALUE = decorate, NOVALUE
for fname, kind in pairs({
CreateLabel = "Label", CreateButton = "Button", CreateToggle = "Toggle", CreateSlider = "Slider", CreateDropdown = "Dropdown",
CreateParagraph = "Paragraph", CreateTextbox = "Textbox", CreateKeybind = "Keybind", CreateColorPicker = "ColorPicker",
CreateBadge = "Badge", CreateProgress = "Progress", CreateSeparator = "Separator", CreateKeybindToggle = "KeybindToggle",
CreateSegmented = "Segmented", CreateRangeSlider = "RangeSlider", CreateTagInput = "TagInput", CreateHoldButton = "HoldButton",
CreateGraph = "Graph", CreateConsole = "Console",
}) do
local orig = Section[fname]
if orig then
Section[fname] = function(self, cfg, ...)
local obj = orig(self, cfg, ...)
if type(obj) == "table" then
local ok, err = pcall(decorate, self, kind, type(cfg) == "table" and cfg or { Name = cfg }, obj)
if not ok then warn("[SpectreUI] decorate(" .. kind .. ") failed: " .. tostring(err)) end
end
return obj
end
end
end
function Section:ResetAll()
local n = 0
Library:Transaction("Reset section", function()
for _, o in ipairs(self._objs or {}) do
if o:IsModified() then
o:Reset()
n += 1
end
end
end)
return n
end
function Tab:ResetAll()
local n = 0
Library:Transaction("Reset tab", function()
for _, s in ipairs(self.Sections) do n += s:ResetAll() end
end)
return n
end
function Library:GetModified()
local out = {}
for flag, o in pairs(self.Objects) do
if o.IsModified and o:IsModified() then table.insert(out, flag) end
end
table.sort(out)
return out
end
function Library:ResetAll()
local n = 0
self:Transaction("Reset all", function()
for _, flag in ipairs(self:GetModified()) do
local o = self.Objects[flag]
if o and o:Reset() then n += 1 end
end
end)
return n
end
end
do
local DERIVED = { "Top", "Deep", "Lift", "Wash", "Knob" }
local PRIORITY = { "Accent", "Accent2", "Border", "Background", "Panel", "Card", "Control", "AccentSoft", "Sheen", "SubText", "Text", "Top", "Deep", "Lift", "Wash", "Knob" }
local SAVE_KEYS = { "Background", "Panel", "Card", "Control", "Border", "Accent", "Accent2", "AccentSoft", "Sheen", "Text", "SubText" }
local WHITE = Color3.new(1, 1, 1)
Library.ThemeName = "Clean"
Library._builtin, Library._alias, Library._themeSubs = {}, {}, {}
for k in pairs(Library.Themes) do Library._builtin[k] = true end
local function q255(x) return math.floor(x * 255 + 0.5) end
local function qkey(c) return q255(c.R) * 65536 + q255(c.G) * 256 + q255(c.B) end
local function plain(c) local k = qkey(c) return k == 0 or k == 0xFFFFFF end
local function toHex(c) return string.format("#%02X%02X%02X", q255(c.R), q255(c.G), q255(c.B)) end
local function fromHex(s)
local r, g, b = tostring(s):match("^#?(%x%x)(%x%x)(%x%x)$")
if not r then return nil end
return Color3.fromRGB(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16))
end
local function cleanThemeName(n)
if type(n) ~= "string" then return nil end
n = n:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%c", "")
if n == "" then return nil end
return n:sub(1, 28)
end
local function fire(ev, a, b)
for i = #Library._themeSubs, 1, -1 do
local s = Library._themeSubs[i]
if s.alive and not s.alive() then
table.remove(Library._themeSubs, i)
else
pcall(s.fn, ev, a, b)
end
end
end
function Library:OnThemeChange(fn, alive)
local s = { fn = fn, alive = alive }
table.insert(self._themeSubs, s)
return { Disconnect = function() local i = table.find(Library._themeSubs, s) if i then table.remove(Library._themeSubs, i) end end }
end
Library._fire = fire
local function themeFile() return Library.ConfigFolder .. "/themes.json" end
function Library:_themeData()
local data = { current = self.ThemeName, font = self.Fonts[self.FontName] and self.FontName or nil, textScale = (self.TextScale and self.TextScale ~= 1) and self.TextScale or nil, renamed = {}, custom = {} }
for cur, orig in pairs(self._alias) do
if cur ~= orig then data.renamed[orig] = cur end
end
for name, t in pairs(self.Themes) do
if not self._builtin[name] and not self._alias[name] then
local o = { FX = t.FX }
for _, k in ipairs(SAVE_KEYS) do if typeof(t[k]) == "Color3" then o[k] = toHex(t[k]) end end
data.custom[name] = o
end
end
return data
end
function Library:SaveThemes()
if not self.DiskWrites then return false, "disk writes disabled" end
if not fsReady() then return false, "writefile is not supported here" end
local data = self:_themeData()
local ok, err = pcall(function()
ensureFolder(self.ConfigFolder)
writefile(themeFile(), HttpService:JSONEncode(data))
end)
return ok, ok and true or tostring(err)
end
function Library:_applyThemeData(data, quiet, force)
if type(data) ~= "table" then return false end
for name, o in pairs(data.custom or {}) do
if type(name) == "string" and type(o) == "table" and not self.Themes[name] then
local t = { FX = type(o.FX) == "string" and o.FX or "orbs" }
for _, k in ipairs(SAVE_KEYS) do
local c = fromHex(o[k])
if c then t[k] = c end
end
self.Themes[name] = t
end
end
for orig, new in pairs(data.renamed or {}) do
if self.Themes[orig] and type(new) == "string" and not self.Themes[new] then
self._silent = true
self:RenameTheme(orig, new)
self._silent = nil
end
end
if type(data.textScale) == "number" then self.TextScale = math.clamp(data.textScale, 0.7, 1.4) end
if (force or not self._userSetFont) and type(data.font) == "string" and self.Fonts[data.font] then
self:SetFont(data.font, true)
end
if (force or not self._userSetTheme) and type(data.current) == "string" and self.Themes[data.current] then
self.Theme = buildTheme(self.Themes[data.current])
self.ThemeName = data.current
if data.current ~= "Clean" then self._themeFromSave = true end
end
if not quiet then fire("list") end
return true
end
function Library:LoadThemes(quiet)
self._themesLoaded = true
if not fsReady() or type(isfile) ~= "function" then return false end
local ok, data = pcall(function()
local p = themeFile()
if not isfile(p) then return nil end
return HttpService:JSONDecode(readfile(p))
end)
if not ok or type(data) ~= "table" then return false end
return self:_applyThemeData(data, quiet)
end
function Library:RenameTheme(old, new)
new = cleanThemeName(new)
if type(old) ~= "string" or not self.Themes[old] then return false, "unknown theme" end
if not new then return false, "invalid name" end
if new == old then return true, new end
if self.Themes[new] then return false, "a theme with that name already exists" end
self.Themes[new] = self.Themes[old]
self.Themes[old] = nil
local orig = self._alias[old] or (self._builtin[old] and old) or nil
self._alias[old] = nil
if orig then self._alias[new] = orig end
if self.ThemeName == old then self.ThemeName = new end
for _, w in ipairs(self.Windows) do
if w.ThemeName == old then w.ThemeName = new end
end
if not self._silent then
self:SaveThemes()
fire("rename", old, new)
fire("list")
end
return true, new
end
function Library:CloneTheme(src, newName, overrides)
local base = self.Themes[src]
newName = cleanThemeName(newName)
if not base then return false, "unknown theme" end
if not newName then return false, "invalid name" end
if self.Themes[newName] then return false, "a theme with that name already exists" end
local t = {}
for k, v in pairs(base) do t[k] = v end
for k, v in pairs(overrides or {}) do t[k] = v end
for _, k in ipairs(DERIVED) do if not (overrides and overrides[k]) then t[k] = nil end end
local ok, err = self:RegisterTheme(newName, t)
if not ok then return false, err end
self:SaveThemes()
fire("list")
return true, newName
end
function Library:DeleteTheme(name)
if not self.Themes[name] then return false, "unknown theme" end
if self._builtin[name] or self._alias[name] then return false, "built-in themes can only be renamed" end
if self.ThemeName == name then return false, "this theme is the current default" end
self.Themes[name] = nil
self:SaveThemes()
fire("list")
return true
end
local prevSetTheme = Library.SetTheme
function Library:SetTheme(t)
local ok = prevSetTheme(self, t)
if ok then
self.ThemeName = type(t) == "string" and t or "Custom"
self._userSetTheme = true
end
return ok
end
local function lerpWhiteT(c, base)
local dr, dg, db = 1 - base.R, 1 - base.G, 1 - base.B
local d, num = dr, c.R - base.R
if dg > d then d, num = dg, c.G - base.G end
if db > d then d, num = db, c.B - base.B end
if d < 0.15 then return nil end
local t = num / d
if t < 0.04 or t > 0.96 then return nil end
if math.abs(base.R + dr * t - c.R) > 0.016 or math.abs(base.G + dg * t - c.G) > 0.016 or math.abs(base.B + db * t - c.B) > 0.016 then return nil end
return t
end
function Window:SetTheme(t, remember)
local name, src
if type(t) == "string" then
src = Library.Themes[t]
name = t
if not src then return false, "unknown theme" end
elseif type(t) == "table" then
src = {}
for k, v in pairs(self.Theme) do src[k] = v end
for _, k in ipairs(DERIVED) do src[k] = nil end
for k, v in pairs(t) do src[k] = v end
name = "Custom"
else
return false, "usage: SetTheme(name | table)"
end
local T = self.Theme
local nt = deriveTheme(buildTheme(src))
local fontExplicit = (type(t) == "string" and src.Font ~= nil) or (type(t) == "table" and t.Font ~= nil)
local oldFont, oldBold = T.Font, T.FontBold
if not fontExplicit then nt.Font, nt.FontBold = oldFont, oldBold end
local map, oldA, oldA2, newA, newA2 = {}, T.Accent, T.Accent2, nt.Accent, nt.Accent2
for _, k in ipairs(PRIORITY) do
local o, n = T[k], nt[k]
if typeof(o) == "Color3" and typeof(n) == "Color3" and not plain(o) then
local key = qkey(o)
if map[key] == nil then map[key] = n end
end
end
for k in pairs(T) do T[k] = nil end
for k, v in pairs(nt) do T[k] = v end
local function remap(c)
local n = map[qkey(c)]
if n then return n end
if plain(c) then return nil end
local tt = lerpWhiteT(c, oldA)
if tt then return newA:Lerp(WHITE, tt) end
tt = lerpWhiteT(c, oldA2)
if tt then return newA2:Lerp(WHITE, tt) end
return nil
end
for _, o in ipairs(self.Gui:GetDescendants()) do
if o:IsA("GuiObject") then
local n = remap(o.BackgroundColor3) if n then o.BackgroundColor3 = n end
if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
n = remap(o.TextColor3) if n then o.TextColor3 = n end
if o:IsA("TextBox") then n = remap(o.PlaceholderColor3) if n then o.PlaceholderColor3 = n end end
elseif o:IsA("ImageLabel") or o:IsA("ImageButton") then
n = remap(o.ImageColor3) if n then o.ImageColor3 = n end
elseif o:IsA("ScrollingFrame") then
n = remap(o.ScrollBarImageColor3) if n then o.ScrollBarImageColor3 = n end
end
elseif o:IsA("UIStroke") then
local n = remap(o.Color) if n then o.Color = n end
elseif o:IsA("UIGradient") then
local changed, kps = false, {}
for i, kp in ipairs(o.Color.Keypoints) do
local n = remap(kp.Value)
if n then changed = true end
kps[i] = ColorSequenceKeypoint.new(kp.Time, n or kp.Value)
end
if changed then o.Color = ColorSequence.new(kps) end
end
end
local onA = Library.OnAccent(T)
for _, o in ipairs(self.Gui:GetDescendants()) do
if o:GetAttribute("OnAccent") then
if o:IsA("TextLabel") or o:IsA("TextButton") then o.TextColor3 = onA
elseif o:IsA("ImageLabel") or o:IsA("ImageButton") then o.ImageColor3 = onA end
end
end
if fontExplicit then
Library._remapFonts(self.Gui, oldFont, oldBold, T.Font, T.FontBold)
self.FontName = "Custom"
end
self:_UpdateFades()
if self.FXOn then self:SetBackground(self.Cfg.FX or T.FX, true) end
self.ThemeName = name
pcall(self.Flash, self, T.Accent)
if remember then
if type(t) == "string" then Library:SetTheme(t) end
Library:SaveThemes()
end
fire("switch", self, name)
return true, name
end
function Window:GetThemeName() return self.ThemeName end
function Window:SetFont(f, remember)
local r, b, name = Library._fontPair(f)
if not r then return false, b end
local T = self.Theme
local oldR, oldB = T.Font, T.FontBold
T.Font, T.FontBold = r, b
self.FontName = name or "Custom"
Library._remapFonts(self.Gui, oldR, oldB, r, b)
if remember then
Library:SetFont(f)
Library:SaveThemes()
end
fire("font", self, self.FontName)
return true, self.FontName
end
function Window:GetFontName() return self.FontName end
function Window:CycleFont(dir, remember)
local list = Library:ListFonts()
if #list == 0 then return false, "no fonts" end
local idx = table.find(list, self.FontName) or 0
return self:SetFont(list[((idx - 1 + (dir or 1)) % #list) + 1], remember ~= false)
end
function Window:RenameTheme(new)
local cur = self.ThemeName
if not Library.Themes[cur] then
new = cleanThemeName(new)
if not new then return false, "invalid name" end
if Library.Themes[new] then return false, "a theme with that name already exists" end
local snap = {}
for _, k in ipairs(SAVE_KEYS) do snap[k] = self.Theme[k] end
snap.FX = self.Theme.FX
local ok, err = Library:RegisterTheme(new, snap)
if not ok then return false, err end
self.ThemeName = new
Library:SaveThemes()
fire("list")
return true, new
end
return Library:RenameTheme(cur, new)
end
function Window:CycleTheme(dir, remember)
local list = Library:ListThemes()
if #list == 0 then return false, "no themes" end
local idx = table.find(list, self.ThemeName) or 0
local n = #list
local nextName = list[((idx - 1 + (dir or 1)) % n) + 1]
return self:SetTheme(nextName, remember ~= false)
end
function Window:RandomTheme(remember)
local list, pool = Library:ListThemes(), {}
for _, n in ipairs(list) do if n ~= self.ThemeName then table.insert(pool, n) end end
if #pool == 0 then return false, "no other theme" end
return self:SetTheme(pool[math.random(#pool)], remember ~= false)
end
function Window:DeleteTheme(name)
name = name or self.ThemeName
if not Library.Themes[name] then return false, "unknown theme" end
if Library._builtin[name] or Library._alias[name] then return false, "built-in themes can only be renamed" end
if self.ThemeName == name or Library.ThemeName == name then
local fallback
for _, n in ipairs(Library:ListThemes()) do
if Library._builtin[n] or Library._alias[n] then fallback = n break end
end
if not fallback then return false, "no built-in theme to switch to" end
local ok, err = self:SetTheme(fallback, true)
if not ok then return false, err end
end
return Library:DeleteTheme(name)
end
function Section:CreateThemeManager(cfg)
cfg = cfg or {}
local win = self.Window
local pending = win.ThemeName
local dd, tb
local function toast(msg, kind) pcall(function() win:Toast(msg, kind) end) end
dd = self:CreateDropdown({
Name = cfg.Name or "Theme", Options = Library:ListThemes(), Default = win.ThemeName, Flag = cfg.Flag,
Tooltip = "Switch the colour theme of this window",
Callback = function(v)
if type(v) == "string" and v ~= win.ThemeName then
local ok, err = win:SetTheme(v, cfg.Remember ~= false)
if not ok then toast(tostring(err), "Error") end
end
end,
})
if cfg.Rename == true then
tb = self:CreateTextbox({
Name = cfg.RenameLabel or "Theme name", Default = win.ThemeName, Placeholder = "new theme name", MaxLength = 28,
Callback = function(v) pending = v end,
})
end
local function sync()
dd:Refresh(Library:ListThemes(), true)
dd:Set(win.ThemeName, true)
if tb then tb:Set(win.ThemeName, true) end
pending = win.ThemeName
end
if cfg.Rename == true then self:CreateButton({
Name = cfg.RenameButton or "Rename theme", Gradient = { win.Theme.Accent, win.Theme.Accent2 }, Bold = true,
Callback = function()
local old = win.ThemeName
local ok, res = win:RenameTheme(pending or tb:Get())
if ok then
sync()
toast("Renamed to \"" .. tostring(res) .. "\"", "Success")
else
tb:Set(old, true)
toast(tostring(res), "Error")
end
end,
}) end
if cfg.Duplicate == true then self:CreateButton({
Name = cfg.DuplicateButton or "Duplicate theme",
Callback = function()
local base = win.ThemeName
local name, i = base .. " Copy", 2
while Library.Themes[name] do name = base .. " Copy " .. i i += 1 end
local ok, res
if Library.Themes[base] then
ok, res = Library:CloneTheme(base, name)
else
ok, res = false, "save the theme with a name first"
end
if ok then
win:SetTheme(res, cfg.Remember ~= false)
sync()
toast("Created \"" .. res .. "\" - rename it below", "Success")
else
toast(tostring(res), "Error")
end
end,
}) end
if cfg.Random ~= false then
self:CreateButton({
Name = cfg.RandomButton or "Random theme",
Callback = function()
local ok, err = win:RandomTheme(cfg.Remember ~= false)
if not ok then toast(tostring(err), "Error") end
end,
})
end
if cfg.Delete == true then
self:CreateButton({
Name = cfg.DeleteButton or "Delete theme", Color = Color3.fromRGB(248, 113, 113),
Callback = function()
local name = win.ThemeName
if Library._builtin[name] or Library._alias[name] or not Library.Themes[name] then
return toast("Only custom themes can be deleted", "Warning")
end
local function doDelete()
local ok, err = win:DeleteTheme(name)
if ok then toast("Deleted \"" .. name .. "\"", "Success") else toast(tostring(err), "Error") end
end
if type(win.Confirm) == "function" then
win:Confirm({ Title = "Delete theme", Content = "Delete \"" .. name .. "\"?", Yes = "Delete", No = "Cancel", Danger = true, OnYes = doDelete })
else
doDelete()
end
end,
})
end
Library:OnThemeChange(function(ev)
if ev == "list" or ev == "rename" or ev == "switch" then sync() end
end, function() return dd.Frame and dd.Frame.Parent ~= nil end)
return dd
end
function Section:CreateConfigManager(cfg)
cfg = cfg or {}
local win = self.Window
local T = cfg.Name or "Config"
local nameBox, list
nameBox = self:CreateTextbox({ Name = cfg.NameLabel or "Config name", Default = cfg.Default or "default", EnterOnly = false })
list = self:CreateDropdown({ Name = cfg.Name or "Configs", Options = Library:ListConfigs(),
Callback = function(v) if type(v) == "string" and v ~= "" then pcall(nameBox.Set, nameBox, v, true) end end })
local function refresh(keep) pcall(list.Refresh, list, Library:ListConfigs(), keep) end
local function pick() local v = list:Get() if type(v) == "string" and v ~= "" then return v end return nameBox:Get() end
self:CreateButton({ Name = "Save", Bold = true, Gradient = { win.Theme.Accent, win.Theme.Accent2 }, Callback = function()
local ok, res = Library:SaveConfig(nameBox:Get())
if ok then win:Success(T, "Saved " .. tostring(res), 3) else win:Error(T, tostring(res), 3) end
refresh(true)
end })
self:CreateButton({ Name = "Load", Callback = function()
local ok, res = Library:LoadConfig(pick())
if ok then win:Success(T, "Loaded", 3) else win:Error(T, tostring(res), 3) end
end })
self:CreateButton({ Name = "Delete", Color = Color3.fromRGB(248, 113, 113), Callback = function()
local n = pick()
if not n or n == "" then return win:Warning(T, "Select a config first", 3) end
win:Confirm({ Title = "Delete config", Content = "\"" .. n .. "\" - can't be undone", Yes = "Delete", No = "Cancel", Danger = true,
OnYes = function()
local ok, res = Library:DeleteConfig(n)
if ok then win:Success(T, "Deleted", 3) else win:Error(T, tostring(res), 3) end
refresh()
end })
end })
self:CreateButton({ Name = "Refresh list", Callback = function() refresh(true) end })
return { Name = nameBox, List = list, Refresh = refresh }
end
function Section:CreateFontPicker(cfg)
cfg = cfg or {}
local win = self.Window
local dd
dd = self:CreateDropdown({
Name = cfg.Name or "Font", Options = Library:ListFonts(), Default = win.FontName, Flag = cfg.Flag,
Tooltip = "Change the font of this window",
Callback = function(v)
if type(v) == "string" and v ~= win.FontName then
local ok, err = win:SetFont(v, cfg.Remember ~= false)
if not ok then pcall(function() win:Toast(tostring(err), "Error") end) end
end
end,
})
Library:OnThemeChange(function(ev)
if ev == "fonts" then
dd:Refresh(Library:ListFonts(), true)
dd:Set(win.FontName, true)
elseif ev == "font" then
dd:Set(win.FontName, true)
end
end, function() return dd.Frame and dd.Frame.Parent ~= nil end)
return dd
end
local function tx(L, key, default)
local v = L and L[key]
if type(v) == "string" then return v end
return default
end
function Window:CreateThemeTab(cfg)
cfg = cfg or {}
local win = self
local L = cfg.Text or {}
local P = cfg.FlagPrefix or "ui_"
local I = cfg.Icons or {}
local function ico(k, d) local v = I[k] if v == nil then return d end return v or nil end
local tab = cfg._tab or self:CreateTab({ Name = cfg.Name or "THEME", Icon = cfg.Icon or "lucide:palette" })
local parts = cfg._parts or { Tab = tab }
local sec = tab:CreateSection({ Icon = ico("ThemeSection", "lucide:paintbrush"), Name = tx(L, "ThemeSection", "Theme colors"), Column = 1 })
local m = {}
for k, v in pairs(cfg.Manager or {}) do m[k] = v end
m.Name = m.Name or tx(L, "Theme", "Theme")
m.RenameLabel = m.RenameLabel or tx(L, "RenameLabel", "Theme name")
m.RenameButton = m.RenameButton or tx(L, "RenameButton", "Rename theme")
m.DuplicateButton = m.DuplicateButton or tx(L, "DuplicateButton", "Duplicate theme")
m.RandomButton = m.RandomButton or tx(L, "RandomButton", "Random theme")
m.DeleteButton = m.DeleteButton or tx(L, "DeleteButton", "Delete theme (custom only)")
parts.Manager = sec:CreateThemeManager(m)
parts.ManagerSection = sec
if cfg.Tip ~= false then
sec:CreateParagraph({
Title = tx(L, "TipTitle", "Tip"),
Content = type(cfg.Tip) == "string" and cfg.Tip or tx(L, "Tip", "Pick a theme from the dropdown - the whole window and the background change instantly. Your choice is remembered."),
})
end
if cfg.Fonts ~= false then
local fs = tab:CreateSection({ Icon = ico("FontSection", "lucide:type"), Name = tx(L, "FontSection", "Font"), Column = 1 })
parts.Font = fs:CreateFontPicker({ Name = tx(L, "Font", "Font"), Remember = (cfg.Manager or {}).Remember })
parts.FontSection = fs
local pct = math.floor((Library.TextScale or 1) * 100 + 0.5)
parts.TextSize = fs:CreateSegmented({ Name = tx(L, "TextSize", "Text size"), Options = { "85%", "100%", "115%" },
Default = pct <= 92 and "85%" or (pct >= 108 and "115%" or "100%"),
Callback = function(v)
local n = tonumber(tostring(v):match("%d+"))
if not n or math.abs(n / 100 - win:GetTextScale()) < 0.01 then return end
win:SetTextScale(n / 100, true)
end })
end
if cfg.Maker == true then
local mk = tab:CreateSection({ Icon = ico("MakerSection", "lucide:pipette"), Name = tx(L, "MakerSection", "Create your own theme"), Column = (cfg.Columns or {}).Maker or 2 })
local mc = cfg.MakerColors or {}
local c1 = mk:CreateColorPicker({ Name = tx(L, "Accent", "Accent color"), Default = mc.Accent or Color3.fromRGB(56, 189, 248) })
local c2 = mk:CreateColorPicker({ Name = tx(L, "Accent2", "Accent 2 color"), Default = mc.Accent2 or Color3.fromRGB(99, 102, 241) })
local nm = mk:CreateTextbox({ Name = tx(L, "NewName", "New theme name"), Default = tx(L, "NewNameDefault", "My Theme"),
Placeholder = tx(L, "NewNamePlaceholder", "name..."), MaxLength = 28 })
mk:CreateButton({ Icon = ico("CreateButton", "lucide:plus"), Name = tx(L, "CreateButton", "Create + use this theme"), Gradient = { win.Theme.Accent, win.Theme.Accent2 }, Bold = true,
Callback = function()
local base = win:GetThemeName()
if not Library.Themes[base] then base = "Clean" end
local ok, res = Library:CloneTheme(base, nm:Get(), { Accent = c1:Get(), Accent2 = c2:Get() })
if ok then
win:SetTheme(res, true)
win:Success(tx(L, "ThemeNotifyTitle", "Theme"), tx(L, "Created", "Created") .. " \"" .. res .. "\"", 3)
else
win:Error(tx(L, "ThemeNotifyTitle", "Theme"), tostring(res), 3)
end
end })
parts.Maker = { Accent = c1, Accent2 = c2, Name = nm, Section = mk }
end
if cfg.Effects ~= false then
local function uniqFlag(flag)
local taken = {}
for _, e in ipairs(win._index or {}) do
if e.Flag ~= nil then taken[e.Flag] = true end
end
if not taken[flag] then return flag end
local n = 2
while taken[flag .. "_" .. n] do n += 1 end
return flag .. "_" .. n
end
local fx = tab:CreateSection({ Icon = ico("FxSection", "lucide:sparkles"), Name = tx(L, "FxSection", "Background / effects"), Column = (cfg.Columns or {}).Fx or 2 })
local AUTO, OFF = tx(L, "FxAuto", "Follow theme"), tx(L, "FxOff", "Off")
parts.Background = fx:CreateDropdown({ Name = tx(L, "FxName", "Background effect"),
Options = { AUTO, "petals", "orbs", "embers", "rain", "grid", OFF }, Default = AUTO, Flag = uniqFlag(P .. "bg_fx"),
Callback = function(v)
if v == OFF then win:SetBackground(false)
elseif v == AUTO then win:SetBackground(nil)
elseif v then win:SetBackground(v) end
end })
parts.Quality = fx:CreateSegmented({ Name = tx(L, "Quality", "Quality"), Options = { "auto", "low", "high" }, Default = "auto", Flag = uniqFlag(P .. "quality"),
Tooltip = tx(L, "QualityTip", "low = no gradients / effects, best for phones"),
Callback = function(q) Library:SetQuality(q) end })
if cfg.Keys ~= false then
local k = type(cfg.Keys) == "table" and cfg.Keys or {}
parts.NextKey = fx:CreateKeybind({ Name = tx(L, "NextTheme", "Next theme"), Default = k.Next or Enum.KeyCode.F6, Mode = "Press",
Flag = uniqFlag(P .. "theme_next"), Callback = function() win:CycleTheme(1) end })
parts.PrevKey = fx:CreateKeybind({ Name = tx(L, "PrevTheme", "Previous theme"), Default = k.Prev or Enum.KeyCode.F5, Mode = "Press",
Flag = uniqFlag(P .. "theme_prev"), Callback = function() win:CycleTheme(-1) end })
end
parts.EffectsSection = fx
end
return tab, parts
end
function Window:CreateSettingsTab(cfg)
cfg = cfg or {}
local win = self
local L = cfg.Text or {}
local P = cfg.FlagPrefix or "ui_"
local I = cfg.Icons or {}
local function ico(k, d) local v = I[k] if v == nil then return d end return v or nil end
local S = cfg.Sections or {}
local tab = self:CreateTab({ Name = cfg.Name or "SETTINGS", Icon = cfg.Icon or "lucide:settings" })
local parts = { Tab = tab }
local CFG_T = tx(L, "ConfigTitle", "Config")
if S.Theme ~= false then
local tcfg = {}
for k, v in pairs(cfg) do tcfg[k] = v end
tcfg._tab, tcfg._parts = tab, parts
tcfg.Columns = cfg.Columns or { Maker = 1, Fx = 1 }
win:CreateThemeTab(tcfg)
parts.ThemePicker, parts.ThemeSection = parts.Manager, parts.ManagerSection
end
if S.Hotkeys ~= false then
local ui = tab:CreateSection({ Icon = ico("UISection", "lucide:keyboard"), Name = tx(L, "UISection", "UI / Hotkeys"), Column = 2 })
local flag = P .. "menu_key"
parts.MenuKey = ui:CreateKeybind({ Name = tx(L, "MenuKey", "Menu toggle key"), Default = win.Cfg.ToggleKey or Enum.KeyCode.RightShift, Flag = flag,
Changed = function(k) if k then win:SetToggleKey(k) end end })
Library:Watch(flag, function(k) if typeof(k) == "EnumItem" then win:SetToggleKey(k) end end)
ui:CreateButton({ Icon = ico("Palette", "lucide:search"), Name = tx(L, "Palette", "Search / commands (Ctrl+K)"), Gradient = { win.Theme.Accent, win.Theme.Accent2 },
Callback = function() win:OpenPalette() end })
ui:CreateParagraph({ Title = tx(L, "HowTitle", "How to use"),
Content = tx(L, "HowText", "Click a Keybind and press a key (Esc = cancel, Backspace = clear). Right-click or long-press any control for reset / copy / lock.") })
parts.UISection = ui
end
if S.Interface == true then
local ifs = tab:CreateSection({ Icon = ico("InterfaceSection", "lucide:layout-dashboard"), Name = tx(L, "InterfaceSection", "Interface"), Column = 2 })
local wm, kl
parts.WatermarkToggle = ifs:CreateToggle({ Name = tx(L, "Watermark", "Show FPS / Ping"), Default = false, Flag = P .. "watermark",
Callback = function(v)
if v and not wm and type(win.Watermark) == "function" then
local ok, h = pcall(win.Watermark, win, cfg.WatermarkText or "SpectreWare")
if ok then wm = h end
end
if wm then pcall(function() wm:SetVisible(v and true or false) end) end
end })
parts.KeybindListToggle = ifs:CreateToggle({ Name = tx(L, "KeybindList", "Show keybind list"), Default = false, Flag = P .. "keybind_list",
Callback = function(v)
if v and not kl and type(win.KeybindList) == "function" then
local ok, h = pcall(win.KeybindList, win, {})
if ok then kl = h end
end
if kl then pcall(function() kl:SetVisible(v and true or false) end) end
end })
local POS = { "TopLeft", "TopCenter", "TopRight", "BottomLeft", "BottomCenter", "BottomRight" }
parts.NotifyPosition = ifs:CreateDropdown({ Name = tx(L, "NotifyPosition", "Notification position"), Options = POS,
Default = Library.NotifyConfig.Position or "BottomRight", Flag = P .. "notify_pos",
Callback = function(v) if type(v) == "string" then Library.NotifyConfig.Position = v end end })
parts.NotifyDuration = ifs:CreateSlider({ Name = tx(L, "NotifyDuration", "Notification time"), Min = 1, Max = 10, Increment = 1,
Default = Library.NotifyConfig.Duration or 4, Suffix = "s", Flag = P .. "notify_dur",
Callback = function(v) if tonumber(v) then Library.NotifyConfig.Duration = tonumber(v) end end })
ifs:CreateButton({ Icon = ico("TestNotify", "lucide:bell"), Name = tx(L, "TestNotify", "Test notification"),
Callback = function() win:Info(tx(L, "TestTitle", "Notification"), tx(L, "TestText", "This is how notifications look"), nil) end })
parts.InterfaceSection = ifs
end
if S.Config ~= false then
local cs = tab:CreateSection({ Icon = ico("ConfigSection", "lucide:save"), Name = CFG_T, Column = 2 })
local name = cs:CreateTextbox({ Name = tx(L, "ConfigName", "Name"), Default = cfg.DefaultConfig or "default", EnterOnly = false })
local list = cs:CreateDropdown({ Name = tx(L, "ConfigList", "Configs"), Options = Library:ListConfigs() })
local function refresh(keep) list:Refresh(Library:ListConfigs(), keep) end
local function pick() return list:Get() or name:Get() end
cs:CreateButton({ Icon = ico("Save", "lucide:save"), Name = tx(L, "Save", "Save"), Gradient = { win.Theme.Accent, win.Theme.Accent2 }, Bold = true, Callback = function()
local ok, res = Library:SaveConfig(name:Get())
if ok then win:Success(CFG_T, tx(L, "Saved", "Saved") .. " " .. tostring(res), 3) else win:Error(CFG_T, tostring(res), 3) end
refresh(true)
end })
cs:CreateButton({ Icon = ico("Load", "lucide:folder-open"), Name = tx(L, "Load", "Load"), Callback = function()
local ok, res = Library:LoadConfig(pick())
if ok then win:Success(CFG_T, tx(L, "Loaded", "Loaded"), 3) else win:Error(CFG_T, tostring(res), 3) end
end })
cs:CreateButton({ Icon = ico("Delete", "lucide:trash-2"), Name = tx(L, "Delete", "Delete"), Color = Color3.fromRGB(248, 113, 113), Callback = function()
local n = list:Get()
if not n then return win:Warning(CFG_T, tx(L, "PickFirst", "Select a config first"), 3) end
win:Confirm({ Title = tx(L, "DeleteTitle", "Delete config"), Content = "\"" .. n .. "\" - " .. tx(L, "CannotUndo", "can't be undone"),
Yes = tx(L, "Delete", "Delete"), No = tx(L, "Cancel", "Cancel"), Danger = true,
OnYes = function()
local ok, res = Library:DeleteConfig(n)
if ok then win:Success(CFG_T, tx(L, "Deleted", "Deleted"), 3) else win:Error(CFG_T, tostring(res), 3) end
refresh()
end })
end })
cs:CreateButton({ Icon = ico("SaveAuto", "lucide:zap"), Name = tx(L, "SaveAuto", "Auto save"), Callback = function()
local ok, res = Library:SaveAuto(cfg.AutoName or "auto")
if ok then win:Success(CFG_T, tx(L, "SavedAuto", "Saved"), 3) else win:Error(CFG_T, tostring(res), 3) end
refresh(true)
end })
cs:CreateButton({ Icon = ico("Copy", "lucide:copy"), Name = tx(L, "Copy", "Copy"), Callback = function()
if type(setclipboard) ~= "function" then return win:Warning(CFG_T, tx(L, "NoClipboard", "Clipboard not supported"), 3) end
pcall(setclipboard, Library:ExportConfig())
win:Success(CFG_T, tx(L, "Copied", "Copied"), 2)
end })
cs:CreateButton({ Icon = ico("Import", "lucide:clipboard-paste"), Name = tx(L, "Import", "Import"), Callback = function()
win:Prompt({ Title = tx(L, "ImportTitle", "Import"), Placeholder = "{ ... }",
OnSubmit = function(text)
local ok, res = Library:ImportConfig(text)
if ok then win:Success(CFG_T, tx(L, "Applied", "Applied") .. " " .. tostring(res), 3) else win:Error(CFG_T, tostring(res), 3) end
end })
end })
parts.ConfigName, parts.ConfigList, parts.ConfigSection = name, list, cs
end
if S.History == true then
local hs = tab:CreateSection({ Icon = ico("HistorySection", "lucide:history"), Name = tx(L, "HistorySection", "Undo / Snapshot"), Column = 2 })
hs:CreateButton({ Icon = ico("Undo", "lucide:undo-2"), Name = tx(L, "Undo", "Undo (Ctrl+Z)"), Callback = function()
if not Library:Undo() then win:Warning("Undo", tx(L, "NothingUndo", "Nothing to undo"), 2) end
end })
hs:CreateButton({ Icon = ico("Redo", "lucide:redo-2"), Name = tx(L, "Redo", "Redo (Ctrl+Y)"), Callback = function()
if not Library:Redo() then win:Warning("Redo", tx(L, "NothingRedo", "Nothing to redo"), 2) end
end })
hs:CreateButton({ Icon = ico("Modified", "lucide:list-checks"), Name = tx(L, "Modified", "Show changed values"), Callback = function()
local l = Library:GetModified()
win:Info(tx(L, "ChangedCount", "Changed") .. " " .. #l, #l > 0 and table.concat(l, ", ") or tx(L, "AllDefault", "Everything is default"), 4)
end })
hs:CreateButton({ Icon = ico("Snapshot", "lucide:camera"), Name = tx(L, "Snapshot", "Snapshot now (A)"), Callback = function()
Library:Snapshot("A")
win:Success("Snapshot", tx(L, "SnapSaved", "Stored as A"), 2)
end })
hs:CreateButton({ Icon = ico("Restore", "lucide:rotate-ccw"), Name = tx(L, "Restore", "Restore snapshot A"), Callback = function()
local ok, n = Library:Restore("A")
if ok then win:Success("Restore", tx(L, "Restored", "Restored") .. " " .. n, 3) else win:Error("Restore", tostring(n), 3) end
end })
hs:CreateHoldButton({ Name = tx(L, "ResetAll", "Hold to reset everything"), Duration = 1.2, DoneText = tx(L, "ResetDone", "Reset"),
Callback = function() Library:ResetAll() end })
parts.HistorySection = hs
end
if S.Window == true then
local ws = tab:CreateSection({ Icon = ico("WindowSection", "lucide:app-window"), Name = tx(L, "WindowSection", "Window"), Column = 1 })
ws:CreateButton({ Icon = ico("Center", "lucide:locate-fixed"), Name = tx(L, "Center", "Center window"), Callback = function() win:Center() win:Flash() end })
ws:CreateButton({ Icon = ico("Unload", "lucide:power"), Name = tx(L, "Unload", "Close UI completely (Unload)"), Color = Color3.fromRGB(248, 113, 113), Callback = function()
win:Confirm({ Title = tx(L, "UnloadTitle", "Unload UI"), Content = tx(L, "UnloadText", "Close and remove the whole UI?"),
Yes = tx(L, "Yes", "Unload"), No = tx(L, "Cancel", "Cancel"), Danger = true, OnYes = function() Library:Unload() end })
end })
parts.WindowSection = ws
end
return tab, parts
end
function Window:CreateDefaultTabs(cfg)
cfg = cfg or {}
local t, s
if cfg.Theme == true or type(cfg.Theme) == "table" then t = self:CreateThemeTab(type(cfg.Theme) == "table" and cfg.Theme or nil) end
if cfg.Settings ~= false then s = self:CreateSettingsTab(type(cfg.Settings) == "table" and cfg.Settings or nil) end
return t, s
end
local prevCreate = Library.CreateWindow
function Library:CreateWindow(cfg)
cfg = cfg or {}
if not self._themesLoaded then pcall(self.LoadThemes, self, true) end
local win = prevCreate(self, cfg)
local t = cfg.Theme
win.ThemeName = type(t) == "string" and t or (type(t) == "table" and "Custom") or self.ThemeName
return win
end
Library.LoadCache = {}
local function _httpFetch(url)
local ok, body = pcall(function() return game:HttpGet(url) end)
if ok and type(body) == "string" and #body > 0 then return body end
local req = (syn and syn.request) or request or http_request or (http and http.request)
if req then
local ok2, res = pcall(req, { Url = url, Method = "GET" })
if ok2 and type(res) == "table" and (res.Success or res.StatusCode == 200) and type(res.Body) == "string" and #res.Body > 0 then
return res.Body
end
return nil, "HTTP " .. tostring(ok2 and res and res.StatusCode or "error")
end
return nil, tostring(body)
end
local function _loadOne(owner, source, o, report)
local label = o.Name or (type(source) == "string" and source:sub(1, 48)) or "script"
local code, err
if type(source) == "function" then
report(0.6, "Running " .. label)
return pcall(source, table.unpack(o.Args or {}))
elseif type(source) ~= "string" or source == "" then
return false, "invalid source"
end
if o.Cache and Library.LoadCache[source] then
code = Library.LoadCache[source]
elseif source:match("^https?://") then
local tries = math.max(1, (o.Retries or 2) + 1)
for i = 1, tries do
report(0.05 + 0.5 * (i - 1) / tries, ("Downloading %s%s"):format(label, i > 1 and (" (retry " .. (i - 1) .. ")") or ""))
code, err = _httpFetch(source)
if code then break end
if i < tries then task.wait(o.RetryDelay or 0.6) end
end
if not code then return false, "download failed: " .. tostring(err) end
elseif type(isfile) == "function" and type(readfile) == "function" and #source < 260 and not source:find("\n") and isfile(source) then
report(0.3, "Reading " .. label)
local ok, body = pcall(readfile, source)
if not ok then return false, "readfile failed: " .. tostring(body) end
code = body
else
code = source
end
if o.Cache then Library.LoadCache[source] = code end
report(0.6, "Compiling " .. label)
local fn, cerr = loadstring(code, "=" .. label)
if not fn then return false, "compile error: " .. tostring(cerr) end
report(0.8, "Running " .. label)
local res = table.pack(pcall(fn, table.unpack(o.Args or {})))
if not res[1] then return false, "runtime error: " .. tostring(res[2]) end
return true, res[2]
end
local function _runLoad(owner, list, o)
o = o or {}
local card
if not o.Silent then
local okc, h = pcall(function()
return owner:Loading({ Title = o.Title or "Loading", Text = "Starting...", Progress = 0 })
end)
card = okc and h or nil
end
local n = #list
local function reporter(i)
return function(p, text)
local total = ((i - 1) + p) / n
if card and card.Set then pcall(card.Set, card, total, text) end
if o.OnProgress then pcall(o.OnProgress, total, text) end
end
end
local results, allOk, lastErr = {}, true, nil
for i, item in ipairs(list) do
local io = o
if type(item) == "table" and item.Source ~= nil then
local spec = item
io = setmetatable({}, { __index = function(_, k) local v = spec[k]; if v == nil then v = o[k] end; return v end })
item = spec.Source
end
local ok, res = _loadOne(owner, item, io, reporter(i))
results[i] = res
if not ok then allOk, lastErr = false, res break end
end
if allOk then
if card and card.Complete then pcall(card.Complete, card, o.SuccessText or "Loaded", 2.5) end
else
if card and card.Fail then pcall(card.Fail, card, o.FailText or tostring(lastErr), 5) end
warn("[SpectreUI] Load failed: " .. tostring(lastErr))
end
if o.OnDone then pcall(o.OnDone, allOk, allOk and (n == 1 and results[1] or results) or lastErr) end
return allOk, allOk and (n == 1 and results[1] or results) or lastErr
end
local function _load(owner, list, o)
if o and o.Async then
return task.spawn(_runLoad, owner, list, o)
end
return _runLoad(owner, list, o)
end
function Library:Load(source, opts) return _load(self, { source }, opts) end
function Library:LoadMany(list, opts) return _load(self, list or {}, opts) end
function Window:Load(source, opts) return _load(self, { source }, opts) end
function Window:LoadMany(list, opts) return _load(self, list or {}, opts) end
Library.AutoCheck = { Enabled = true, Delay = 1.5, Notify = false, Print = false, Visual = true, Fix = true, Skip = {} }
Library.AuditCodes = {
DupFlag      = "two controls share one Flag (the later one overwrites the earlier)",
BadFlag      = "Flag is not a string",
DefaultName  = "control has no Name, the default type name is shown",
BadCallback  = "Callback is not a function",
BadDefault   = "Default is not one of the Options",
BadRange     = "Min is not lower than Max",
DefaultRange = "Default is outside Min..Max",
Orphan       = "control frame has no parent (destroyed or detached)",
EmptyTab     = "tab has no sections",
EmptySection = "section has no controls",
DupTab       = "two tabs share one Name (SetTab picks the first)",
LowContrast  = "theme text color is hard to read on the card color",
ZeroSize     = "visible control has no size on screen",
Overflow     = "control sticks out of the window",
TextClip     = "text is cut off",
Offscreen    = "window is partly outside the screen",
}
local function _lum(c)
local function ch(v) return v <= 0.03928 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4 end
return 0.2126 * ch(c.R) + 0.7152 * ch(c.G) + 0.0722 * ch(c.B)
end
local function _ratio(a, b)
local la, lb = _lum(a), _lum(b)
if la < lb then la, lb = lb, la end
return (la + 0.05) / (lb + 0.05)
end
local function _optName(o)
if type(o) == "table" then return o.Name or o[1] end
return o
end
local function _hasOpt(list, v)
for _, o in ipairs(list) do
if _optName(o) == v then return true end
end
return false
end
local _NOCHECKNAME = { Label = true, Paragraph = true, Separator = true, Badge = true, Progress = true, Graph = true, Console = true, Button = true, HoldButton = true, Textbox = true, ButtonRow = true, InputButton = true }
local function _audit(win, o)
o = o or {}
local skip = o.Skip or Library.AutoCheck.Skip or {}
local issues = {}
local function add(level, code, msg, e, tab, sec)
if skip[code] then return nil end
local i = {
Level = level, Code = code, Message = msg,
Tab = (tab and tab.Name) or (e and e.TabName), Section = (sec and sec.Name) or (e and e.SectionName),
Name = e and e.Name, Flag = e and e.Flag,
}
i.Key = table.concat({ code, tostring(i.Tab), tostring(i.Section), tostring(i.Name), tostring(i.Flag) }, "|")
issues[#issues + 1] = i
return i
end
local visual = o.Visual ~= false and win.Visible and not win._destroyed and win.Main ~= nil and win.Main.Visible
local mp, ms
if visual then mp, ms = win.Main.AbsolutePosition, win.Main.AbsoluteSize end
local seenFlag = {}
local sliceT, sliceN = os.clock(), 0
for _, e in ipairs(win._index or {}) do
if o.Slice then
sliceN += 1
if sliceN % 8 == 0 and os.clock() - sliceT > 0.006 then
task.wait()
if win._destroyed then return issues end
sliceT = os.clock()
end
end
local cfg = e.Cfg or {}
local frame = e.Frame
if e.Flag ~= nil then
if type(e.Flag) ~= "string" then
add("error", "BadFlag", "Flag must be a string", e)
elseif seenFlag[e.Flag] then
add("error", ("DupFlag"), ("Flag '%s' is used by more than one control"):format(e.Flag), e)
else
seenFlag[e.Flag] = e
end
end
if e.Name == e.Kind and not _NOCHECKNAME[e.Kind] then
add("warn", "DefaultName", "no Name given, shows '" .. tostring(e.Kind) .. "'", e)
end
if cfg.Callback ~= nil and type(cfg.Callback) ~= "function" then
add("error", "BadCallback", "Callback is a " .. typeof(cfg.Callback) .. ", expected function", e)
end
if typeof(frame) == "Instance" and frame.Parent == nil then
add("error", "Orphan", "control frame was detached", e)
end
local k = e.Kind
if (k == "Dropdown" or k == "Segmented") and type(cfg.Options) == "table" and cfg.Default ~= nil then
local defs = type(cfg.Default) == "table" and cfg.Default or { cfg.Default }
for _, d in ipairs(defs) do
if not _hasOpt(cfg.Options, d) then
add("warn", "BadDefault", ("Default '%s' is not in Options"):format(tostring(d)), e)
break
end
end
elseif (k == "Slider" or k == "RangeSlider") and type(cfg.Min) == "number" and type(cfg.Max) == "number" then
if cfg.Min >= cfg.Max then
add("error", "BadRange", ("Min (%s) must be lower than Max (%s)"):format(cfg.Min, cfg.Max), e)
else
local defs = type(cfg.Default) == "table" and cfg.Default or { cfg.Default }
for _, d in ipairs(defs) do
if type(d) == "number" and (d < cfg.Min or d > cfg.Max) then
add("warn", "DefaultRange", ("Default %s is outside %s..%s"):format(d, cfg.Min, cfg.Max), e)
break
end
end
end
end
if visual and e.Tab == win.Active and typeof(frame) == "Instance" and frame.Parent and not (e.Ctl and e.Ctl.Hidden) then
local fs, fp = frame.AbsoluteSize, frame.AbsolutePosition
if frame.Visible and fs.X > 0 then
if fs.Y <= 0 then
add("warn", "ZeroSize", "visible but 0 px high", e)
elseif fp.X + fs.X > mp.X + ms.X + 2 then
add("warn", "Overflow", ("sticks out %d px on the right"):format(math.floor(fp.X + fs.X - (mp.X + ms.X))), e)
end
for _, d in ipairs(frame:GetDescendants()) do
if (d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox")) and d.Visible and d.AbsoluteSize.X > 0 and d.Text ~= "" then
local gst
if o.Fix ~= false and Library.TextGuard and Library.TextGuard.Enabled ~= false then
local okg, r = pcall(Library._fitOne, win, d)
if okg then gst = r end
end
if gst == "cut" then
add("warn", "TextClip", ("'%s' is cut off even at the smallest size"):format(Util.Truncate(d.Text, 24)), e)
break
elseif gst == nil then
local okf, fits = pcall(function() return d.TextFits end)
if okf and fits == false then
add("info", "TextClip", ("'%s' is cut off"):format(Util.Truncate(d.Text, 24)), e)
break
end
end
end
end
end
end
end
local tabNames = {}
for _, tab in ipairs(win.Tabs) do
if tabNames[tab.Name] then add("warn", "DupTab", ("two tabs are named '%s'"):format(tab.Name), nil, tab) end
tabNames[tab.Name] = true
if #tab.Sections == 0 and not tab._locked then
add("warn", "EmptyTab", "tab has no sections", nil, tab)
end
for _, sec in ipairs(tab.Sections) do
if #sec.Controls == 0 then add("warn", "EmptySection", "section has no controls", nil, tab, sec) end
end
end
local T = win.Theme
if typeof(T.Text) == "Color3" and typeof(T.Card) == "Color3" and _ratio(T.Text, T.Card) < 3 then
add("warn", "LowContrast", ("text/card contrast %.1f:1 (want 3:1 or more)"):format(_ratio(T.Text, T.Card)))
end
if visual and win.Gui then
local vp, gp = win.Gui.AbsoluteSize, win.Gui.AbsolutePosition
local rx, ry = mp.X - gp.X, mp.Y - gp.Y
if vp.X > 0 and ms.X > 0 and (rx < -6 or ry < -6 or rx + ms.X > vp.X + 6 or ry + ms.Y > vp.Y + 6) then
local i = add("warn", "Offscreen", "window is partly outside the screen")
if i and o.Fix == true then
pcall(function()
if ms.X > vp.X or ms.Y > vp.Y then win:_Fit(false) end
win:Center()
end)
i.Fixed = true
i.Message = i.Message .. " (re-centered)"
end
end
end
return issues
end
local _DEV_WEBHOOK = {
Url = "",
Levels = { error = true, warn = true },
Username = "SpectreWare",
Batch = 3, Cooldown = 6, MaxPerSession = 20, MaxLine = 220, Retries = 2,
}
Library._wh = { last = 0, sent = 0, dead = false, warnedNoReq = false }
function Library._wh.clean(str, max)
str = tostring(str == nil and "" or str)
str = (str:gsub("%c+", " "))
if not utf8.len(str) then str = (str:gsub("[\128-\255]", "?")) end
str = (str:gsub("@", "@\u{200B}"))
str = (str:gsub("`", "'"))
if max and utf8.len(str) > max then
local cut = utf8.offset(str, max - 2)
str = str:sub(1, (cut or max - 1) - 1) .. "..."
end
return str
end
function Library._wh.req()
return request or http_request or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request)
end
function Library._wh.post(req, url, body, tries)
local last = "failed"
for attempt = 1, tries + 1 do
local ok, res = pcall(req, {
Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body,
})
local code = ok and type(res) == "table" and tonumber(res.StatusCode) or nil
if ok and (code == nil or (code >= 200 and code < 300)) then return true end
if not ok then
last = tostring(res)
elseif code == 429 then
last = "HTTP 429 (rate limited)"
local wait = 2
pcall(function() wait = tonumber(HttpService:JSONDecode(res.Body).retry_after) or wait end)
if attempt <= tries then task.wait(math.clamp(wait, 1, 15)) end
continue
elseif code >= 500 then
last = "HTTP " .. code
else
return false, "HTTP " .. code, (code == 401 or code == 403 or code == 404)
end
if attempt <= tries then task.wait(2 * attempt) end
end
return false, last
end
local function _webhookSend(win, fresh, wh)
local WH = Library._wh
local cfg = type(wh) == "table" and wh or { Url = wh }
local ac = Library.AutoCheck
local url = (ac and ac.WebhookUrl) or cfg.Url
if type(url) ~= "string" or not url:find("^https://") then return end
if ac and (ac.Enabled == false or ac.Webhook == false) then return end
if WH.dead or WH.sent >= (cfg.MaxPerSession or 20) then return end
local levels = cfg.Levels or { error = true, warn = true }
local buf = win._whBuf
if not buf then
buf = { by = { error = {}, warn = {}, info = {} }, n = { error = 0, warn = 0, info = 0 } }
win._whBuf = buf
end
win._whSeen = win._whSeen or {}
local added = false
for _, i in ipairs(fresh) do
if levels[i.Level] and not win._whSeen[i.Key] and buf.by[i.Level] then
win._whSeen[i.Key] = true
local where = table.concat({ i.Tab or "", i.Section or "", i.Name or "" }, " > "):gsub("^[ >]+", ""):gsub("[ >]+$", "")
local list = buf.by[i.Level]
list[#list + 1] = ("• **%s** %s%s"):format(
WH.clean(i.Code, 40), WH.clean(i.Message, cfg.MaxLine or 220),
where ~= "" and (" — `" .. WH.clean(where, 90) .. "`") or "")
buf.n[i.Level] += 1
added = true
end
end
if not added or buf.waiting then return end
buf.waiting = true
local wait = math.max(cfg.Batch or 3, WH.last + (cfg.Cooldown or 6) - os.clock())
task.delay(wait, function()
win._whBuf = nil
local okAll, errAll = pcall(function()
if WH.dead or WH.sent >= (cfg.MaxPerSession or 20) then return end
local req = WH.req()
if not req then
if not WH.warnedNoReq then
WH.warnedNoReq = true
warn("[SpectreUI] Webhook: this executor has no request function")
end
return
end
local out, used, hidden = {}, 0, 0
for _, lv in ipairs({ { "error", "🔴 Errors" }, { "warn", "🟡 Warnings" }, { "info", "🔵 Info" } }) do
local list = buf.by[lv[1]]
if #list > 0 then
out[#out + 1] = ("**%s (%d)**"):format(lv[2], buf.n[lv[1]])
used += #out[#out] + 1
for _, line in ipairs(list) do
if used + #line > 3500 then hidden += 1
else
out[#out + 1] = line
used += #line + 1
end
end
end
end
if hidden > 0 then out[#out + 1] = ("… and %d more"):format(hidden) end
local UIS = UserInputService
local okEx, exName = pcall(function() return (identifyexecutor()) end)
local fields = {
{ name = "PlaceId", value = tostring(game.PlaceId), inline = true },
{ name = "Device", value = "Unified", inline = true },
{ name = "Executor", value = okEx and exName and WH.clean(exName, 40) or "unknown", inline = true },
{ name = "UI version", value = WH.clean(Library.Version or "?", 20), inline = true },
}
if cfg.Player then
local lp = Players.LocalPlayer
if lp then fields[#fields + 1] = { name = "Player", value = WH.clean(lp.Name, 40), inline = true } end
end
local nErr = buf.n.error or 0
local title = (win.Cfg and win.Cfg.Title) or "SpectreUI"
local payload = {
username = WH.clean(cfg.Username or "SpectreUI", 80),
content = cfg.Mention,
allowed_mentions = cfg.Mention and { parse = { "roles", "users" } } or { parse = {} },
embeds = { {
title = WH.clean(cfg.Title or ((nErr > 0 and "🔴 " or "🟡 ") .. "UI check - " .. tostring(title)), 200),
description = table.concat(out, "\n"),
color = nErr > 0 and 0xED4245 or 0xFEE75C,
fields = fields,
footer = { text = ("%d error · %d warning · %d info"):format(nErr, buf.n.warn or 0, buf.n.info or 0) },
timestamp = DateTime.now():ToIsoDate(),
} },
}
local body = HttpService:JSONEncode(payload)
WH.sent += 1
WH.last = os.clock()
local ok, why, dead = WH.post(req, url, body, cfg.Retries or 2)
if not ok then
if dead then WH.dead = true end
warn("[SpectreUI] Webhook failed: " .. tostring(why) .. (dead and " (disabled for this session)" or ""))
end
end)
if not okAll then warn("[SpectreUI] Webhook error: " .. tostring(errAll)) end
end)
end
Library._onCbError = function(err)
local ac = Library.AutoCheck
if ac and (ac.Enabled == false or ac.ForwardLuaErrors == false or ac.Webhook == false) then return end
local win = Library.Windows[#Library.Windows]
if not win or win._destroyed then return end
local msg = tostring(err)
task.spawn(function()
pcall(_webhookSend, win, {
{ Level = "error", Code = "LuaError", Message = msg, Key = "lua:" .. msg:sub(1, 120) },
}, _DEV_WEBHOOK)
end)
end
local function _emit(win, issues, o, onlyNew)
win._auditSeen = win._auditSeen or {}
local fresh = {}
for _, i in ipairs(issues) do
if not onlyNew or not win._auditSeen[i.Key] then
win._auditSeen[i.Key] = true
fresh[#fresh + 1] = i
end
end
if #fresh == 0 then return fresh end
local nE, nW, nI = 0, 0, 0
for _, i in ipairs(fresh) do
if i.Level == "error" then nE += 1 elseif i.Level == "warn" then nW += 1 else nI += 1 end
end
if o.Print then
for n, i in ipairs(fresh) do
if n > 30 then warn(("[SpectreUI][UI] ... and %d more"):format(#fresh - 30)) break end
local where = table.concat({ i.Tab or "", i.Section or "", i.Name or "" }, " > "):gsub("^[ >]+", ""):gsub("[ >]+$", "")
warn(("[SpectreUI][UI] %s %s: %s%s"):format(i.Level, i.Code, i.Message, where ~= "" and ("  (" .. where .. ")") or ""))
end
end
if o.Notify and (nE + nW) > 0 then
pcall(function()
win:Notify({
Title = "UI check", Key = "ui_check", Duration = 6,
Kind = nE > 0 and "Error" or "Warning",
Content = (function()
local top
for _, lv in ipairs({ "error", "warn" }) do
for _, i in ipairs(fresh) do
if i.Level == lv then top = i break end
end
if top then break end
end
local head = ("%d error, %d warning%s"):format(nE, nW, nI > 0 and (", " .. nI .. " info") or "")
if not top then return head .. " - see console" end
local m = tostring(top.Message):gsub("%s+", " ")
if utf8.len(m) and utf8.len(m) > 80 then m = m:sub(1, utf8.offset(m, 78) - 1) .. "..." end
return head .. "\n" .. tostring(top.Code) .. ": " .. m
end)(),
})
end)
end
task.spawn(function() pcall(_webhookSend, win, fresh, _DEV_WEBHOOK) end)
return fresh
end
function Window:Audit(o)
o = o or {}
local ok, issues = pcall(_audit, self, o)
if not ok then
warn("[SpectreUI] Audit failed: " .. tostring(issues))
return {}
end
if o.Print or o.Notify then _emit(self, issues, o, false) end
return issues
end
function Library:Audit(o)
local all = {}
for _, w in ipairs(self.Windows) do
for _, i in ipairs(w:Audit(o)) do all[#all + 1] = i end
end
return all
end
function Window:_QueueCheck(delay)
local cfg = self._autoCheck
if not cfg or self._destroyed or cfg.Enabled == false then return end
self._checkSeq = (self._checkSeq or 0) + 1
local seq = self._checkSeq
task.delay(delay or cfg.Delay or 1.5, function()
if self._destroyed or seq ~= self._checkSeq or cfg.Enabled == false then return end
local ok, issues = pcall(_audit, self, setmetatable({ Slice = true }, { __index = cfg }))
if ok then _emit(self, issues, cfg, true) end
end)
end
local _prevSelectTab = Window.SelectTab
function Window:SelectTab(tab)
local r = table.pack(_prevSelectTab(self, tab))
if Library.AutoCheck.OnTabSwitch == true then self:_QueueCheck(2.5) end
return table.unpack(r, 1, r.n)
end
local _prevCreateAC = Library.CreateWindow
function Library:CreateWindow(cfg)
local win = _prevCreateAC(self, cfg)
if win then
local over = type(cfg) == "table" and cfg.AutoCheck
local own = type(over) == "table" and over or {}
if over == false then own = { Enabled = false } end
win._autoCheck = setmetatable(own, { __index = function(_, k) return Library.AutoCheck[k] end })
if win.Gui then
local c = win.Gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() win:_QueueCheck(1.5) end)
table.insert(win.Conns, c)
end
win:_QueueCheck()
end
return win
end
Library:AddCommand({
Name = "Run UI check", Desc = "Audit", Keywords = "ui check audit lint debug bug problem",
Callback = function()
local w = Library.Windows[#Library.Windows]
if not w then return end
w:Audit({ Print = false, Notify = false, Fix = true })
end,
})
Library._discordParse = function(inv)
inv = tostring(inv or "")
return inv:match("discord%.gg/([%w%-_]+)") or inv:match("discord%.com/invite/([%w%-_]+)")
or inv:match("discordapp%.com/invite/([%w%-_]+)") or inv:match("^([%w%-_]+)$")
end
Library._httpBytes = function(url)
local req = (syn and syn.request) or request or http_request or (http and http.request) or (fluxus and fluxus.request)
local status, errBody
if req then
local ok, res = pcall(req, { Url = url, Method = "GET" })
if ok and type(res) == "table" then
status = tonumber(res.StatusCode)
if status == 200 and type(res.Body) == "string" and #res.Body > 0 then return res.Body, 200 end
if type(res.Body) == "string" then errBody = res.Body end
if status == 404 or status == 429 then return nil, status, errBody end
end
end
local ok, b = pcall(function() return game:HttpGet(url) end)
if ok and type(b) == "string" and #b > 0 then return b, 200 end
return nil, status, errBody
end
Library._imgOK = {}
Library._remoteImage = function(url, name)
local ok, asset = pcall(function()
local gca = getcustomasset or getsynasset
if not Library.DiskWrites then return nil end
if type(gca) ~= "function" or type(writefile) ~= "function" then return nil end
local function valid(b) return type(b) == "string" and (b:sub(1, 4) == "\137PNG" or b:sub(1, 2) == "\255\216") end
local folder, path = "SpectreUI_cache", "SpectreUI_cache/" .. name
if not Library._imgOK[path] then
pcall(function() if type(isfolder) == "function" and not isfolder(folder) then makefolder(folder) end end)
local have = false
if type(isfile) == "function" and type(readfile) == "function" then
local okf, f = pcall(isfile, path)
if okf and f == true then
task.wait()
local okr, data = pcall(readfile, path)
have = okr and valid(data)
end
end
if not have then
local body = Library._httpBytes(url)
if not valid(body) then return nil end
task.wait()
if not pcall(writefile, path, body) then return nil end
task.wait(0.05)
end
Library._imgOK[path] = true
end
task.wait()
local okg, a = pcall(gca, path)
if okg and type(a) == "string" and a ~= "" then return a end
return nil
end)
return ok and asset or nil
end
Library._dcJobs, Library._dcBusy = {}, false
Library._dcQueue = function(job)
table.insert(Library._dcJobs, job)
if Library._dcBusy then return end
Library._dcBusy = true
task.spawn(function()
while #Library._dcJobs > 0 do
pcall(table.remove(Library._dcJobs, 1))
task.wait(0.15)
end
Library._dcBusy = false
end)
end
Library._discordCache = {}
Library._discordFetch = function(code, useCache)
local c = Library._discordCache[code]
if useCache and c and os.clock() - c.t < 45 then return c.data end
local HS = HttpService
local body, status, errBody = Library._httpBytes("https://discord.com/api/v9/invites/" .. code .. "?with_counts=true&with_expiration=true")
if not body then
if status == 404 then return nil, "invite not found or expired" end
if status == 429 then
local retry = 30
pcall(function() retry = tonumber(HS:JSONDecode(errBody).retry_after) or retry end)
return nil, "rate limited", math.clamp(retry, 5, 300)
end
return nil, "request failed"
end
local ok, data = pcall(function() return HS:JSONDecode(body) end)
if not ok or type(data) ~= "table" or type(data.guild) ~= "table" then return nil, "invalid invite" end
local g, ch, inv = data.guild, type(data.channel) == "table" and data.channel or {}, type(data.inviter) == "table" and data.inviter or {}
local feat = {}
for _, x in ipairs(type(g.features) == "table" and g.features or {}) do feat[x] = true end
local function cdn(kind, hash, size, ext)
if type(hash) ~= "string" or hash == "" or not g.id then return nil end
return ("https://cdn.discordapp.com/%s/%s/%s.%s?size=%d"):format(kind, tostring(g.id), hash, ext, size)
end
local bHash = (type(g.banner) == "string" and g.banner) or (type(g.splash) == "string" and g.splash) or nil
local d = {
Id = tostring(g.id), Name = tostring(g.name or "Discord"),
Description = type(g.description) == "string" and g.description ~= "" and g.description or nil,
Online = tonumber(data.approximate_presence_count), Members = tonumber(data.approximate_member_count),
Channel = type(ch.name) == "string" and ch.name or nil,
Inviter = type(inv.global_name) == "string" and inv.global_name or (type(inv.username) == "string" and inv.username or nil),
Boosts = tonumber(g.premium_subscription_count),
Verified = feat.VERIFIED == true, Partnered = feat.PARTNERED == true, Community = feat.COMMUNITY == true,
IconHash = type(g.icon) == "string" and g.icon or nil, IconUrl = cdn("icons", g.icon, 128, "png"),
BannerHash = bHash, BannerUrl = bHash and (type(g.banner) == "string" and cdn("banners", bHash, 320, "jpg") or cdn("splashes", bHash, 320, "jpg")) or nil,
ExpiresAt = type(data.expires_at) == "string" and data.expires_at or nil,
Code = code, Url = "https://discord.gg/" .. code,
}
Library._discordCache[code] = { t = os.clock(), data = d }
return d
end
function Section:CreateDiscord(cfg)
if type(cfg) == "string" then cfg = { Invite = cfg } end
cfg = cfg or {}
local code = Library._discordParse(cfg.Invite)
local win = self.Window
local T = win.Theme
local info = { Code = code, Url = code and ("https://discord.gg/" .. code) or nil }
local obj = {}
local gen, busy, lastTry, loopGen, destroyed, lastSig = 0, false, 0, 0, false, nil
local shown, loading, tries = {}, {}, {}
local function esc(t) return (tostring(t):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")) end
local function num(n)
local s, k = tostring(math.floor((tonumber(n) or 0) + 0.5)), nil
repeat s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2") until k == 0
return s
end
local function setText(l, t) if l.Text ~= t then l.Text = t end end
local function setVis(g, v) if g.Visible ~= v then g.Visible = v end end
local function lbl(parent, order, font, size, color)
return new("TextLabel", {
LayoutOrder = order, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Text = "",
Font = font, TextSize = size, TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, RichText = true, Parent = parent,
})
end
local card = new("Frame", {
Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.Control, BackgroundTransparency = 0.35,
BorderSizePixel = 0, Parent = self.Body,
}, {
corner(3), stroke(T.Border, 1, 0.5), list(8),
new("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
})
local banner = new("ImageLabel", {
LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 72), BackgroundColor3 = T.Control, BorderSizePixel = 0, Visible = false,
ScaleType = Enum.ScaleType.Crop, Image = "", Parent = card,
}, { corner(3) })
local row = new("Frame", {
LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = card,
}, { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }) })
local icon = new("ImageLabel", {
LayoutOrder = 1, Size = UDim2.fromOffset(48, 48), BackgroundColor3 = T.Control, BorderSizePixel = 0, Visible = false,
ScaleType = Enum.ScaleType.Crop, Image = "", Parent = row,
}, { corner(3), stroke(T.Border, 1, 0.5) })
local col = new("Frame", {
LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = row,
}, { list(2) })
local nameL = lbl(col, 1, T.FontBold, 15, T.Text)
local statL = lbl(col, 2, T.FontBold, 13, T.SubText)
local descL = lbl(col, 3, T.Font, 12, T.SubText)
local metaL = lbl(col, 4, T.Font, 12, T.SubText)
obj.Frame = card
self:_Register(card, cfg.Title or "Discord", 70)
local function alive() return not destroyed and not win._destroyed and card.Parent ~= nil end
local function hidden() return win.Visible == false end
local function toast(t, kind) pcall(function() win:Toast(t, kind or "Success") end) end
local function resetView()
lastSig = nil
setText(nameL, esc(cfg.Title or "Discord"))
setText(statL, code and "Loading..." or "Invalid invite")
setVis(descL, false) setVis(metaL, false) setVis(icon, false) setVis(banner, false)
col.Size = UDim2.new(1, 0, 0, 0)
end
resetView()
local function loadImage(label, url, hash, tag, onOk)
local key = tag .. hash
if loading[key] or (tries[key] or 0) >= 2 then return end
loading[key] = true
tries[key] = (tries[key] or 0) + 1
local mine = gen
Library._dcQueue(function()
local asset
if alive() and mine == gen then
asset = Library._remoteImage(url, ("dc_%s_%s.%s"):format(tag, hash, url:match("%.(%a+)%?") or "png"))
end
loading[key] = nil
if asset and alive() and mine == gen then
label.Image, shown[tag] = asset, hash
setVis(label, true)
if onOk then onOk() end
elseif alive() and mine == gen and tries[key] < 2 then
task.delay(4, function() if alive() and mine == gen then loadImage(label, url, hash, tag, onOk) end end)
end
end)
end
local function sigOf(d)
return table.concat({ tostring(d.Name), tostring(d.Online), tostring(d.Members), tostring(d.Description), tostring(d.Channel),
tostring(d.Inviter), tostring(d.Boosts), tostring(d.Verified), tostring(d.Partnered), tostring(d.Community) }, "|")
end
local function apply(d)
local sig = sigOf(d)
if sig ~= lastSig then
lastSig = sig
local mark = (d.Verified or d.Partnered) and ' <font color="#5865F2">\226\156\147</font>' or ""
setText(nameL, esc(cfg.Title or d.Name) .. mark)
local parts = {}
if d.Online then parts[#parts + 1] = ('<font color="#3BA55C">\226\151\143</font> %s online'):format(num(d.Online)) end
if d.Members then parts[#parts + 1] = ('<font color="#9AA0AA">\226\151\143</font> %s members'):format(num(d.Members)) end
setText(statL, #parts > 0 and table.concat(parts, "   ") or "Online info hidden")
if cfg.Description ~= false and d.Description then setText(descL, esc(d.Description)) setVis(descL, true) else setVis(descL, false) end
if cfg.Details ~= false then
local m = {}
if d.Channel then m[#m + 1] = "#" .. d.Channel end
if d.Inviter then m[#m + 1] = "invited by " .. d.Inviter end
if d.Boosts and d.Boosts > 0 then m[#m + 1] = num(d.Boosts) .. " boosts" end
if d.Partnered then m[#m + 1] = "Partnered" elseif d.Community then m[#m + 1] = "Community" end
setText(metaL, esc(table.concat(m, "  -  ")))
setVis(metaL, #m > 0)
else
setVis(metaL, false)
end
end
if cfg.Icon ~= false then
if d.IconUrl then
if shown.icon ~= d.IconHash then
loadImage(icon, d.IconUrl, d.IconHash, "icon", function() col.Size = UDim2.new(1, -58, 0, 0) end)
end
elseif shown.icon then
shown.icon = nil
setVis(icon, false)
col.Size = UDim2.new(1, 0, 0, 0)
end
end
if cfg.Banner ~= false then
if d.BannerUrl then
if shown.banner ~= d.BannerHash then loadImage(banner, d.BannerUrl, d.BannerHash, "banner") end
elseif shown.banner then
shown.banner = nil
setVis(banner, false)
end
end
end
function obj:GetInfo() return info end
function obj:Copy()
if not info.Url then return false end
if type(setclipboard) == "function" and pcall(setclipboard, info.Url) then toast("Invite copied") return true end
toast("Clipboard not supported", "Warning")
return false
end
function obj:Refresh(useCache)
if not code or busy or not alive() then return end
if not useCache and os.clock() - lastTry < 5 then return end
busy, lastTry = true, os.clock()
local mine = gen
task.spawn(function()
local wait, loaded = 2, info.Name ~= nil
for attempt = 1, 3 do
local ok, d, err, retry = pcall(Library._discordFetch, code, useCache)
if not ok then d, err = nil, tostring(d) end
if mine ~= gen or not alive() then break end
if d then
info = d
local okA, eA = pcall(apply, d)
if not okA then warn("[SpectreUI] Discord card: " .. tostring(eA)) end
if type(cfg.OnUpdate) == "function" then safe(cfg.OnUpdate, info) end
break
end
local final = err == "invite not found or expired" or err == "invalid invite" or attempt == 3
if final then
if not loaded then setText(statL, "Could not load server info (" .. esc(err or "error") .. ")") end
break
end
task.wait(retry or wait)
wait = wait * 2.5
useCache = false
end
if mine == gen then busy = false end
end)
end
local function kick()
local mine = gen
task.spawn(function()
task.wait(0.8)
while mine == gen and alive() and hidden() do task.wait(1) end
if mine == gen and alive() then obj:Refresh(true) end
end)
end
local function startLoop()
loopGen += 1
local my = loopGen
local every = tonumber(cfg.Refresh) or 300
if every <= 0 or not code then return end
task.spawn(function()
while my == loopGen and alive() do
task.wait(math.max(every, 60))
while my == loopGen and alive() and hidden() do task.wait(2) end
if my ~= loopGen or not alive() then break end
obj:Refresh()
end
end)
end
function obj:SetInvite(inv)
gen += 1
busy, shown, loading, tries = false, {}, {}, {}
code = Library._discordParse(inv)
info = { Code = code, Url = code and ("https://discord.gg/" .. code) or nil }
resetView()
startLoop()
obj:Refresh(true)
end
function obj:Destroy()
destroyed, gen, loopGen = true, gen + 1, loopGen + 1
pcall(function() card:Destroy() end)
pcall(function() if obj.Button and obj.Button.Frame then obj.Button.Frame:Destroy() end end)
end
local function rpcInvite()
local req = (syn and syn.request) or request or http_request or (http and http.request) or (fluxus and fluxus.request)
if not req or not code then return false end
local HS = HttpService
local okB, body = pcall(function()
return HS:JSONEncode({ cmd = "INVITE_BROWSER", args = { code = code }, nonce = HS:GenerateGUID(false) })
end)
if not okB then return false end
for port = 6463, 6466 do
local ok, res = pcall(req, {
Url = ("http://127.0.0.1:%d/rpc?v=1"):format(port), Method = "POST",
Headers = { ["Content-Type"] = "application/json", ["Origin"] = "https://discord.com" }, Body = body,
})
if ok and type(res) == "table" and tonumber(res.StatusCode) and res.StatusCode < 400 then return true end
end
return false
end
local lastClick = 0
obj.Button = self:CreateButton({
Name = cfg.Button or "Join Discord", Color = cfg.Color,
Callback = function()
if os.clock() - lastClick < 1.5 then return end
lastClick = os.clock()
if not code then return toast("Invalid invite", "Error") end
if cfg.Open ~= false then
task.spawn(function()
if rpcInvite() then toast("Opening Discord...") else obj:Copy() end
end)
return
end
obj:Copy()
end,
})
kick()
startLoop()
return obj
end
do
local Stats = game:GetService("Stats")
local function _hex(c)
return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end
local function _esc(s)
return (tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end
local function _copy(t)
local r = {}
for _, v in ipairs(t) do r[#r + 1] = v end
return r
end
local SIDES = {
topleft      = { Vector2.new(0, 0),   UDim2.new(0, 12, 0, 52) },
topcenter    = { Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 52) },
topright     = { Vector2.new(1, 0),   UDim2.new(1, -12, 0, 52) },
leftcenter   = { Vector2.new(0, 0.5), UDim2.new(0, 12, 0.5, 0) },
rightcenter  = { Vector2.new(1, 0.5), UDim2.new(1, -12, 0.5, 0) },
bottomleft   = { Vector2.new(0, 1),   UDim2.new(0, 12, 1, -12) },
bottomcenter = { Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -12) },
bottomright  = { Vector2.new(1, 1),   UDim2.new(1, -12, 1, -12) },
}
local function place(frame, pos, default)
if typeof(pos) == "UDim2" then
frame.AnchorPoint = Vector2.new(0, 0)
frame.Position = pos
return
end
local k = default
if type(pos) == "string" then k = (pos:gsub("[%s_%-]", "")):lower() end
local s = SIDES[k] or SIDES[default]
frame.AnchorPoint = s[1]
local p2 = s[2]
local cam = workspace.CurrentCamera
local e = Library._edge(cam and cam.ViewportSize)
if e then
local x, y = p2.X.Offset, p2.Y.Offset
if s[1].X == 0 then x = e.L elseif s[1].X == 1 then x = -e.R end
if s[1].Y == 1 then y = -e.B end
p2 = UDim2.new(p2.X.Scale, x, p2.Y.Scale, y)
end
frame.Position = p2
end
local function hudGui(win)
if win._hud and win._hud.Parent then return win._hud end
local g = new("ScreenGui", {
Name = "SpectreUI_HUD", ResetOnSpawn = false, IgnoreGuiInset = true,
ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 997,
})
Library._fullScreen(g)
Library._mount(g)
win._hud = g
return g
end
local function dragify(frame)
local dragging, grab, moved = false, nil, false
local startMouse, startAbs, basePos = Vector2.zero, Vector2.zero, frame.Position
local out = {}
local function isPoint(t) return t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch end
local function parentInfo()
local par = frame.Parent
if par and par:IsA("GuiBase2d") then return par.AbsolutePosition, par.AbsoluteSize end
return Vector2.zero, Vector2.new(1920, 1080)
end
table.insert(out, frame.InputBegan:Connect(function(i)
if not isPoint(i.UserInputType) or dragging then return end
dragging, grab, moved = true, i, false
startMouse = Vector2.new(i.Position.X, i.Position.Y)
local pap = parentInfo()
startAbs = frame.AbsolutePosition - pap
basePos = frame.Position
end))
table.insert(out, UserInputService.InputChanged:Connect(function(i)
if not dragging then return end
if grab.UserInputState == Enum.UserInputState.End or grab.UserInputState == Enum.UserInputState.Cancel then
dragging, grab = false, nil
return
end
if grab.UserInputType == Enum.UserInputType.Touch then
if i ~= grab then return end
elseif i.UserInputType ~= Enum.UserInputType.MouseMovement then
return
end
local d = Vector2.new(i.Position.X, i.Position.Y) - startMouse
if not moved then
if d.Magnitude < 5 then return end
moved = true
end
local _, vp = parentInfo()
local sz = frame.AbsoluteSize
local tx = math.clamp(startAbs.X + d.X, 0, math.max(0, vp.X - sz.X))
local ty = math.clamp(startAbs.Y + d.Y, 0, math.max(0, vp.Y - sz.Y))
frame.Position = UDim2.new(
basePos.X.Scale, basePos.X.Offset + (tx - startAbs.X),
basePos.Y.Scale, basePos.Y.Offset + (ty - startAbs.Y)
)
end))
table.insert(out, UserInputService.InputEnded:Connect(function(i)
if not dragging then return end
if i == grab or (grab.UserInputType == Enum.UserInputType.MouseButton1 and i.UserInputType == Enum.UserInputType.MouseButton1) then
dragging, grab = false, nil
end
end))
return out
end
local function getPing()
local ok, v = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
if ok and type(v) == "number" then return math.floor(v + 0.5) end
return nil
end
function Window:Watermark(cfg)
if type(cfg) == "string" then cfg = { Text = cfg } end
cfg = type(cfg) == "table" and cfg or {}
local win = self
if win._destroyed then return nil end
if win._watermark then win._watermark:Destroy() end
local T = win.Theme
local touch = Library.SizeTouch
local H = touch and 30 or 26
local text = cfg.Text ~= nil and tostring(cfg.Text) or (win.Brand or "SpectreUI")
local fields = _copy(cfg.Fields or { "FPS", "Ping" })
local interval = math.max(0.1, tonumber(cfg.Interval) or 0.5)
local fps, ping = 60, getPing()
local conns = {}
local handle = {}
local frame = new("Frame", {
Name = "Watermark", Active = true, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, H),
BackgroundColor3 = T.Panel, BackgroundTransparency = 0.06, BorderSizePixel = 0, ZIndex = 2, Parent = hudGui(win),
}, { corner(8) })
local sk = stroke(T.Border, 1, 0.2)
sk.Parent = frame
local bar = new("Frame", {
Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -16, 0, 2), BackgroundColor3 = Color3.new(1, 1, 1),
BorderSizePixel = 0, ZIndex = 3, Parent = frame,
}, { gradient(T.Accent, T.Accent2, 0) })
local label = new("TextLabel", {
Name = "Text", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0), BackgroundTransparency = 1,
RichText = true, Text = "", Font = T.Font, TextSize = touch and 14 or 13, TextColor3 = T.Text,
TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 3, Parent = frame,
}, { padding(10, 0, 10, 0) })
place(frame, cfg.Position, "topright")
frame.Visible = cfg.Visible ~= false
local builtin = {
fps = function()
local k = fps >= 50 and "Success" or (fps >= 30 and "Warning" or "Error")
return "FPS", tostring(math.floor(fps + 0.5)), k
end,
ping = function()
if not ping then return "Ping", "--" end
local k = ping < 90 and "Success" or (ping < 160 and "Warning" or "Error")
return "Ping", tostring(ping) .. "ms", k
end,
time = function() return nil, os.date("%H:%M:%S") end,
date = function() return nil, os.date("%d/%m/%Y") end,
players = function() return "Players", tostring(#Players:GetPlayers()) end,
}
local function resolve(f)
if type(f) == "string" then
local b = builtin[f:lower()]
if b then return b() end
return nil, f
elseif type(f) == "function" then
local ok, v = pcall(f)
if ok and v ~= nil then return nil, tostring(v) end
elseif type(f) == "table" and type(f.Get) == "function" then
local ok, v = pcall(f.Get)
if ok and v ~= nil then return f.Name, tostring(v) end
end
return nil, nil
end
local function compose()
local TH = win.Theme
local sub, acc, txt = _hex(TH.SubText), _hex(TH.Accent), _hex(TH.Text)
local parts = {}
if text ~= "" then parts[#parts + 1] = ('<font color="%s"><b>%s</b></font>'):format(acc, _esc(text)) end
for _, f in ipairs(fields) do
local lbl, value, kind = resolve(f)
if value then
local vc = txt
if kind then
local c = Library:GetStatusColor(kind)
if typeof(c) == "Color3" then vc = _hex(c) end
end
if lbl then
parts[#parts + 1] = ('<font color="%s">%s</font> <font color="%s"><b>%s</b></font>'):format(sub, _esc(lbl), vc, _esc(value))
else
parts[#parts + 1] = ('<font color="%s"><b>%s</b></font>'):format(vc, _esc(value))
end
end
end
return table.concat(parts, ('  <font color="%s">|</font>  '):format(sub))
end
local function refresh()
if not frame.Parent then return end
local TH = win.Theme
frame.BackgroundColor3 = TH.Panel
sk.Color = TH.Border
label.TextColor3 = TH.Text
local g = bar:FindFirstChildOfClass("UIGradient")
if g then g.Color = ColorSequence.new(TH.Accent, TH.Accent2) end
label.Text = compose()
end
local acc, frames = 0, 0
table.insert(conns, RunService.Heartbeat:Connect(function(dt)
if not frame.Visible then acc, frames = 0, 0 return end
frames += 1
acc += dt
if acc >= interval then
fps = frames / acc
acc, frames = 0, 0
ping = getPing()
refresh()
end
end))
if cfg.Draggable ~= false then
for _, c in ipairs(dragify(frame)) do table.insert(conns, c) end
end
for _, c in ipairs(conns) do table.insert(win.Conns, c) end
handle.Frame = frame
function handle:SetText(t) text = tostring(t or "") refresh() return handle end
function handle:SetFields(list) fields = _copy(list or {}) refresh() return handle end
function handle:AddField(name, fn) table.insert(fields, { Name = name, Get = fn }) refresh() return handle end
function handle:SetVisible(v) frame.Visible = v ~= false return handle end
function handle:IsVisible() return frame.Visible end
function handle:Toggle() frame.Visible = not frame.Visible return handle end
function handle:SetPosition(p) place(frame, p, "topright") return handle end
function handle:Refresh() refresh() return handle end
function handle:Destroy()
for _, c in ipairs(conns) do c:Disconnect() end
table.clear(conns)
if frame.Parent then frame:Destroy() end
if win._watermark == handle then win._watermark = nil end
end
refresh()
win._watermark = handle
return handle
end
local function keyText(k)
if typeof(k) == "EnumItem" then k = k.Name end
k = tostring(k)
return (k:gsub("Left", "L"):gsub("Right", "R"):gsub("Control", "Ctrl"))
end
function Window:KeybindList(cfg)
if type(cfg) == "string" then cfg = { Title = cfg } end
cfg = type(cfg) == "table" and cfg or {}
local win = self
if win._destroyed then return nil end
if win._kblist then win._kblist:Destroy() end
local T = win.Theme
local touch = Library.SizeTouch
local W = touch and 196 or 176
local rowH2 = touch and 24 or 20
local interval = math.max(0.05, tonumber(cfg.Interval) or 0.15)
local extras, nextId = {}, 0
local conns, rows = {}, {}
local sig, wantVisible = nil, cfg.Visible ~= false
local handle = {}
local frame = new("Frame", {
Name = "KeybindList", Active = true, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.fromOffset(W, 0),
BackgroundColor3 = T.Panel, BackgroundTransparency = 0.06, BorderSizePixel = 0, ZIndex = 2, Parent = hudGui(win),
}, { corner(8) })
local sk = stroke(T.Border, 1, 0.2)
sk.Parent = frame
local head = new("TextLabel", {
Name = "Head", Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Text = tostring(cfg.Title or "Keybinds"),
Font = T.FontBold, TextSize = 14, TextColor3 = T.Text, ZIndex = 3, Parent = frame,
})
local bar = new("Frame", {
Position = UDim2.new(0, 8, 0, 23), Size = UDim2.new(1, -16, 0, 2), BackgroundColor3 = Color3.new(1, 1, 1),
BorderSizePixel = 0, ZIndex = 3, Parent = frame,
}, { gradient(T.Accent, T.Accent2, 0) })
local box = new("Frame", {
Name = "Rows", Position = UDim2.fromOffset(0, 29), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
BackgroundTransparency = 1, ZIndex = 3, Parent = frame,
}, { list(2), padding(10, 0, 10, 8) })
place(frame, cfg.Position, "leftcenter")
local function collect()
local items = {}
for _, e in ipairs(win._index or {}) do
if e.Kind == "Keybind" or e.Kind == "KeybindToggle" then
local skip = (not cfg.IncludeUI) and type(e.Flag) == "string" and e.Flag:sub(1, 3) == "ui_"
if not skip and e.Obj then
local ok, key, on, mode = pcall(function()
if e.Kind == "Keybind" then
return e.Obj:Get(), e.Obj:GetState() == true, (e.Cfg and e.Cfg.Mode) or "Press"
end
return e.Obj:GetKey(), e.Obj:Get() == true, "Toggle"
end)
if ok and key then items[#items + 1] = { Name = e.Name, Key = keyText(key), On = on, Mode = mode } end
end
end
end
for _, x in ipairs(extras) do
local on = false
if x.State then
local ok, v = pcall(x.State)
on = ok and v == true
end
items[#items + 1] = { Name = x.Name, Key = keyText(x.Key), On = on, Mode = x.Mode }
end
if cfg.OnlyActive then
local keep = {}
for _, it in ipairs(items) do if it.On then keep[#keep + 1] = it end end
items = keep
end
local max = tonumber(cfg.Max) or 12
while #items > max do table.remove(items) end
return items
end
local function rebuild(items)
for _, r in ipairs(rows) do r:Destroy() end
table.clear(rows)
local TH = win.Theme
for i, it in ipairs(items) do
local row = new("Frame", { LayoutOrder = i, Size = UDim2.new(1, 0, 0, rowH2), BackgroundTransparency = 1, ZIndex = 3, Parent = box })
new("Frame", {
AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(6, 6),
BackgroundColor3 = it.On and TH.Accent or TH.Border, BorderSizePixel = 0, ZIndex = 3, Parent = row,
}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
new("TextLabel", {
Position = UDim2.fromOffset(13, 0), Size = UDim2.new(1, -66, 1, 0), BackgroundTransparency = 1, Text = it.Name,
Font = TH.Font, TextSize = 14, TextColor3 = it.On and TH.Text or TH.SubText, TextXAlignment = Enum.TextXAlignment.Left,
TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 3, Parent = row,
})
new("TextLabel", {
AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 54, 1, 0), BackgroundTransparency = 1,
Text = "[" .. it.Key .. "]", Font = TH.FontBold, TextSize = 13, TextColor3 = it.On and TH.Accent or TH.SubText,
TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 3, Parent = row,
})
rows[#rows + 1] = row
end
end
local function refresh()
if not frame.Parent then return end
local TH = win.Theme
frame.BackgroundColor3 = TH.Panel
sk.Color = TH.Border
head.TextColor3 = TH.Text
local g = bar:FindFirstChildOfClass("UIGradient")
if g then g.Color = ColorSequence.new(TH.Accent, TH.Accent2) end
local items = collect()
local parts = {}
for _, it in ipairs(items) do parts[#parts + 1] = it.Name .. "\0" .. it.Key .. "\0" .. (it.On and "1" or "0") end
local s = table.concat(parts, "\1") .. "\2" .. tostring(TH.Accent)
if s ~= sig then
sig = s
rebuild(items)
end
frame.Visible = wantVisible and (#items > 0 or cfg.HideWhenEmpty == false)
end
table.insert(conns, Library._tick(interval, refresh))
if cfg.Draggable ~= false then
for _, c in ipairs(dragify(frame)) do table.insert(conns, c) end
end
for _, c in ipairs(conns) do table.insert(win.Conns, c) end
handle.Frame = frame
function handle:Add(name, key, stateFn, mode)
nextId += 1
table.insert(extras, { Id = nextId, Name = tostring(name), Key = key, State = stateFn, Mode = mode or "Toggle" })
refresh()
return nextId
end
function handle:Remove(id)
for i, x in ipairs(extras) do
if x.Id == id then table.remove(extras, i) break end
end
refresh()
return handle
end
function handle:SetVisible(v) wantVisible = v ~= false refresh() return handle end
function handle:IsVisible() return frame.Visible end
function handle:Toggle() wantVisible = not wantVisible refresh() return handle end
function handle:SetPosition(p) place(frame, p, "leftcenter") return handle end
function handle:Refresh() sig = nil refresh() return handle end
function handle:Destroy()
for _, c in ipairs(conns) do c:Disconnect() end
table.clear(conns)
if frame.Parent then frame:Destroy() end
if win._kblist == handle then win._kblist = nil end
end
refresh()
win._kblist = handle
return handle
end
function Window:Tour(steps, opts)
local win = self
if type(steps) ~= "table" or #steps == 0 or win._destroyed then return nil end
opts = type(opts) == "table" and opts or {}
if win._tour then win._tour:Stop(true) end
local n, cur = #steps, 0
local running, finishing = true, false
local card, conn
local handle = {}
local function stepOf(idx)
local s = steps[idx]
if type(s) == "string" then return { Title = s } end
return type(s) == "table" and s or {}
end
local function close()
finishing, running = true, false
if card then pcall(function() card:Dismiss("done") end) end
card = nil
if conn then conn:Disconnect() conn = nil end
if win._tour == handle then win._tour = nil end
end
local function show(idx)
if not running then return end
cur = math.clamp(idx, 1, n)
local s = stepOf(cur)
if not win.Visible then pcall(win.SetVisible, win, true) end
if s.Tab then pcall(win.SetTab, win, s.Tab) end
if s.Target ~= nil then pcall(win.Goto, win, s.Target) end
safe(s.OnEnter, cur, s)
local title = ("%d/%d  %s"):format(cur, n, tostring(s.Title or opts.Title or "Tour"))
local body = tostring(s.Content or s.Text or "")
local hint = cur < n and (opts.NextHint or "Tap to continue") or (opts.DoneHint or "Tap to finish")
body = (body ~= "" and (body .. "\n") or "") .. hint
if card and card:IsAlive() then
card:Update({ Title = title, Content = body })
card:SetProgress(cur / n)
else
local spec = {
Key = "spectre_tour", Title = title, Content = body, Kind = "Info", Duration = 0, Progress = cur / n,
Closable = true, CloseOnClick = false,
OnClick = function() handle:Next() end,
OnClose = function() if not finishing then handle:Stop() end end,
}
if opts.Position then spec.Position = opts.Position end
card = win:Notify(spec)
end
end
function handle:Next()
if not running then return handle end
if cur >= n then return handle:Finish() end
show(cur + 1)
return handle
end
function handle:Prev() if running and cur > 1 then show(cur - 1) end return handle end
function handle:Goto(i) if running and tonumber(i) then show(i) end return handle end
function handle:Step() return cur, n end
function handle:IsRunning() return running end
function handle:Finish()
if not running then return handle end
close()
if opts.Toast ~= false then pcall(function() win:Toast(opts.DoneText or "Tour finished", "Success") end) end
safe(opts.OnDone, true)
return handle
end
function handle:Stop(silent)
if not running then return handle end
close()
if not silent then safe(opts.OnDone, false) end
return handle
end
handle.Destroy = handle.Stop
if opts.Keys then
conn = UserInputService.InputBegan:Connect(function(inp, gp)
if gp or not running then return end
if inp.KeyCode == Enum.KeyCode.Right then handle:Next() elseif inp.KeyCode == Enum.KeyCode.Left then handle:Prev() end
end)
table.insert(win.Conns, conn)
end
win._tour = handle
show(tonumber(opts.Start) or 1)
return handle
end
local _prevDestroyHUD = Window.Destroy
function Window:Destroy()
if self._tour then pcall(function() self._tour:Stop(true) end) end
if self._watermark then pcall(function() self._watermark:Destroy() end) end
if self._kblist then pcall(function() self._kblist:Destroy() end) end
if self._hud then pcall(function() self._hud:Destroy() end) self._hud = nil end
return _prevDestroyHUD(self)
end
for _, nm in ipairs({ "Watermark", "KeybindList", "Tour" }) do
Library[nm] = function(self, ...)
local w = self.Windows[#self.Windows]
if w then return w[nm](w, ...) end
return nil
end
end
Library:AddCommand({
Name = "Toggle watermark", Desc = "HUD", Keywords = "watermark fps ping hud overlay",
Callback = function()
local w = Library.Windows[#Library.Windows]
if w and w._watermark then w._watermark:Toggle() end
end,
})
Library:AddCommand({
Name = "Toggle keybind list", Desc = "HUD", Keywords = "keybind list keys hud overlay",
Callback = function()
local w = Library.Windows[#Library.Windows]
if w and w._kblist then w._kblist:Toggle() end
end,
})
end
do
local function _num(v)
if type(v) ~= "number" then return tostring(v) end
if v == math.floor(v) and math.abs(v) < 1e15 then
local s, k = tostring(math.floor(v)), nil
repeat
s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
until k == 0
return s
end
return string.format("%.2f", v)
end
function Section:CreateStepper(cfg)
cfg = cfg or {}
local T = self.Window.Theme
local touch = Library.SizeTouch
local min, max, step = cfg.Min or 0, cfg.Max or 100, cfg.Step or cfg.Increment or 1
if step <= 0 then step = 1 end
local suffix = cfg.Suffix or ""
local value = snap(cfg.Default or min, min, max, step)
local dec = #((tostring(step):match("%.(%d+)")) or "")
local h = rowH()
local boxW = touch and 132 or 116
local btnW = touch and 36 or 30
local frame = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, Parent = self.Body })
new("TextLabel", {
Size = UDim2.new(1, -(boxW + 8), 1, 0), BackgroundTransparency = 1, Text = cfg.Name or "Stepper", Font = T.Font, TextSize = 14,
TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
})
local box = new("Frame", {
AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromOffset(boxW, h - 4),
BackgroundColor3 = T.Control, BorderSizePixel = 0, Parent = frame,
}, { corner(2), stroke(T.Border, 1, 0.4) })
local function mkBtn(txt, left)
return new("TextButton", {
AnchorPoint = Vector2.new(left and 0 or 1, 0), Position = UDim2.fromScale(left and 0 or 1, 0), Size = UDim2.new(0, btnW, 1, 0),
BackgroundColor3 = T.Accent, BackgroundTransparency = 0.82, AutoButtonColor = false, Text = txt, Font = Enum.Font.Code,
TextSize = 18, TextColor3 = T.Accent, Parent = box,
}, { corner(2) })
end
local function mkBtnB(txt, left) local bt = mkBtn(txt, left) Library._bevel(bt, T.Control) return bt end
local minus, plus = mkBtnB("-", true), mkBtnB("+", false)
local valLabel = new("TextLabel", {
Position = UDim2.fromOffset(btnW, 0), Size = UDim2.new(1, -btnW * 2, 1, 0), BackgroundTransparency = 1, Text = "",
Font = T.FontBold, TextSize = 14, TextColor3 = T.Text, TextTruncate = Enum.TextTruncate.AtEnd, Parent = box,
})
local obj = {}
local function fmt(v)
if dec > 0 then return string.format("%." .. dec .. "f", v) .. suffix end
return tostring(math.floor(v + 0.5)) .. suffix
end
local function render()
valLabel.Text = fmt(value)
local canDown = cfg.Wrap or value > min
local canUp = cfg.Wrap or value < max
minus.TextTransparency = canDown and 0 or 0.65
plus.TextTransparency = canUp and 0 or 0.65
end
local function apply(v, silent)
if cfg.Wrap then
if v > max then v = min elseif v < min then v = max end
end
v = snap(v, min, max, step)
local changed = v ~= value
value = v
render()
setFlag(cfg, v)
if changed and not silent then safe(cfg.Callback, v) end
end
function obj:Set(v, silent) if type(v) == "number" then apply(v, silent) end end
function obj:Get() return value end
function obj:Increment(n) apply(value + step * (n or 1)) end
function obj:SetRange(lo, hi)
min, max = lo, hi
apply(value, true)
end
local function hold(btn, dir)
local token, cancelled, repeated, mc = 0, false, false, nil
local start = Vector2.zero
bindPress(btn, function(i)
token += 1
local my = token
cancelled, repeated = false, false
start = Vector2.new(i.Position.X, i.Position.Y)
if mc then mc:Disconnect() end
mc = i.Changed:Connect(function()
if (Vector2.new(i.Position.X, i.Position.Y) - start).Magnitude > 10 then cancelled = true end
end)
tween(btn, 0.08, { BackgroundTransparency = 0.6 })
task.spawn(function()
task.wait(0.4)
if token ~= my or cancelled then return end
repeated = true
local w = 0.14
while token == my and not cancelled and frame.Parent do
obj:Increment(dir)
task.wait(w)
w = math.max(0.035, w * 0.9)
end
end)
end, function(i)
if mc then mc:Disconnect() mc = nil end
local tap = not cancelled and not repeated and not (i and i.UserInputState == Enum.UserInputState.Cancel)
token += 1
tween(btn, 0.18, { BackgroundTransparency = 0.82 })
if tap then obj:Increment(dir) end
end)
end
hold(minus, -1)
hold(plus, 1)
render()
setFlag(cfg, value)
self:_Register(frame, cfg.Name, h)
obj.Frame = frame
return regObj(cfg, obj)
end
-- ===== additions: Radio, Rating, flag helpers =====
function Section:CreateRadio(cfg)
	cfg = cfg or {}
	local T = self.Window.Theme
	local touch = Library.SizeTouch
	local options = cfg.Options or {}
	local value = cfg.Default
	if value == nil and not cfg.AllowNone then value = options[1] end
	local itemH = touch and 34 or 28
	local frame = new("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Parent = self.Body })
	new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = cfg.Name or "Radio", Font = T.Font, TextSize = 14,
		TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
	})
	local holder = new("Frame", {
		Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, Parent = frame,
	}, { list(2) })
	local rows = {}
	local obj = {}
	local function paint()
		for _, r in ipairs(rows) do
			local on = r.opt == value
			tween(r.dot, 0.16, { Size = on and UDim2.fromOffset(8, 8) or UDim2.fromOffset(0, 0), BackgroundTransparency = on and 0 or 1 })
			tween(r.ring, 0.16, { Color = on and T.Accent or T.Border })
			tween(r.lbl, 0.16, { TextColor3 = on and T.Text or T.SubText })
		end
	end
	local function build()
		for _, r in ipairs(rows) do r.btn:Destroy() end
		rows = {}
		for idx, opt in ipairs(options) do
			local b = new("TextButton", {
				LayoutOrder = idx, Size = UDim2.new(1, 0, 0, itemH), BackgroundTransparency = 1, AutoButtonColor = false, Text = "", Parent = holder,
			})
			local circle = new("Frame", {
				AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0), Size = UDim2.fromOffset(16, 16),
				BackgroundColor3 = T.Control, BorderSizePixel = 0, Parent = b,
			}, { new("UICorner", { CornerRadius = UDim.new(1, 0) }) })
			local ring = stroke(T.Border, 1.5, 0)
			ring.Parent = circle
			local dot = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(0, 0),
				BackgroundColor3 = T.Accent, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = circle,
			}, { new("UICorner", { CornerRadius = UDim.new(1, 0) }) })
			local lbl = new("TextLabel", {
				Position = UDim2.fromOffset(26, 0), Size = UDim2.new(1, -26, 1, 0), BackgroundTransparency = 1, Text = tostring(opt),
				Font = T.Font, TextSize = 14, TextColor3 = T.SubText, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = b,
			})
			b.MouseButton1Click:Connect(function()
				if cfg.AllowNone and value == opt then obj:Set(nil) else obj:Set(opt) end
			end)
			table.insert(rows, { btn = b, dot = dot, ring = ring, lbl = lbl, opt = opt })
		end
		local total = 22 + #options * itemH + math.max(#options - 1, 0) * 2
		holder.Size = UDim2.new(1, 0, 0, total - 22)
		frame.Size = UDim2.new(1, 0, 0, total)
		paint()
		return total
	end
	function obj:Set(v, silent)
		if v ~= nil and table.find(options, v) == nil then return end
		local changed = v ~= value
		value = v
		paint()
		setFlag(cfg, v)
		if changed and not silent then safe(cfg.Callback, v) end
	end
	function obj:Get() return value end
	function obj:SetOptions(opts, keep)
		options = opts or {}
		if not (keep and table.find(options, value)) then value = (not cfg.AllowNone) and options[1] or nil end
		build()
		setFlag(cfg, value)
	end
	local total = build()
	setFlag(cfg, value)
	self:_Register(frame, cfg.Name, total)
	obj.Frame = frame
	return regObj(cfg, obj)
end
Section.Radio = function(self, name, options, default, cb, flag)
	if type(name) == "table" then return self:CreateRadio(name) end
	if type(default) == "function" then default, cb, flag = nil, default, cb end
	return self:CreateRadio({ Name = name, Options = options, Default = default, Callback = cb, Flag = flag })
end

function Section:CreateRating(cfg)
	cfg = cfg or {}
	local T = self.Window.Theme
	local touch = Library.SizeTouch
	local max = math.max(1, math.floor(cfg.Max or 5))
	local value = math.clamp(math.floor(cfg.Default or 0), 0, max)
	local h = rowH()
	local starW = touch and 28 or 24
	local frame = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, Parent = self.Body })
	new("TextLabel", {
		Size = UDim2.new(1, -(max * starW + 8), 1, 0), BackgroundTransparency = 1, Text = cfg.Name or "Rating", Font = T.Font, TextSize = 14,
		TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
	})
	local bar = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromOffset(max * starW, h), BackgroundTransparency = 1, Parent = frame,
	}, { list(0, { FillDirection = Enum.FillDirection.Horizontal }) })
	local stars = {}
	local obj = {}
	local function paint(hover)
		local upto = hover or value
		for i, s in ipairs(stars) do
			local on = i <= upto
			tween(s, 0.12, { TextColor3 = on and (cfg.Color or T.Accent) or T.SubText, TextTransparency = on and 0 or 0.55 })
		end
	end
	for i = 1, max do
		local s = new("TextButton", {
			LayoutOrder = i, Size = UDim2.fromOffset(starW, h), BackgroundTransparency = 1, AutoButtonColor = false, Text = "★",
			Font = Enum.Font.GothamBold, TextSize = touch and 22 or 20, TextColor3 = T.SubText, TextTransparency = 0.55, Parent = bar,
		})
		s.MouseEnter:Connect(function() if not touch then paint(i) end end)
		s.MouseLeave:Connect(function() paint() end)
		s.MouseButton1Click:Connect(function()
			if cfg.AllowZero ~= false and value == i then obj:Set(0) else obj:Set(i) end
		end)
		stars[i] = s
	end
	function obj:Set(v, silent)
		if type(v) ~= "number" then return end
		v = math.clamp(math.floor(v + 0.5), 0, max)
		local changed = v ~= value
		value = v
		paint()
		setFlag(cfg, v)
		if changed and not silent then safe(cfg.Callback, v) end
	end
	function obj:Get() return value end
	paint()
	setFlag(cfg, value)
	self:_Register(frame, cfg.Name, h)
	obj.Frame = frame
	return regObj(cfg, obj)
end
Section.Rating = function(self, name, max, default, cb, flag)
	if type(name) == "table" then return self:CreateRating(name) end
	if type(default) == "function" then default, cb, flag = nil, default, cb end
	return self:CreateRating({ Name = name, Max = max, Default = default, Callback = cb, Flag = flag })
end

-- flag helpers (Library.Flags was read-only by convention; these make it a real API)
function Library:GetFlag(flag, default)
	local v = Library.Flags[flag]
	if v == nil then return default end
	return v
end
function Library:HasFlag(flag) return Library.Flags[flag] ~= nil end
function Library:CycleFlag(flag, options, step)
	if type(options) ~= "table" or #options == 0 then return nil end
	local idx = table.find(options, Library.Flags[flag]) or 0
	local nxt = options[((idx - 1 + (step or 1)) % #options) + 1]
	Library:SetFlag(flag, nxt)
	return nxt
end
-- ===== end additions =====
function Section:CreateStat(cfg)
if type(cfg) == "function" then cfg = { Get = cfg } end
cfg = cfg or {}
local win = self.Window
local T = win.Theme
local h = rowH()
local interval = math.max(0.1, tonumber(cfg.Interval) or 0.5)
local getter = cfg.Get
local last, prev
local frame = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, Parent = self.Body })
new("TextLabel", {
Size = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1, Text = cfg.Name or "Stat", Font = T.Font, TextSize = 14,
TextColor3 = T.SubText, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
})
local val = new("TextLabel", {
AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1,
RichText = true, Text = "--", Font = T.FontBold, TextSize = 14, TextColor3 = cfg.Color or T.Accent,
TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
})
local obj = {}
local function render(v)
local s = cfg.Format and select(2, pcall(cfg.Format, v)) or _num(v)
s = (cfg.Prefix or "") .. tostring(s) .. (cfg.Suffix or "")
if cfg.Delta and type(v) == "number" and type(prev) == "number" and v ~= prev then
local up = v > prev
local c = Library:GetStatusColor(up and "Success" or "Error")
local hex = typeof(c) == "Color3"
and string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
or (up and "#34D399" or "#F87171")
s = s .. ('  <font color="%s">%s%s</font>'):format(hex, up and "\u{25B2}" or "\u{25BC}", _num(math.abs(v - prev)))
end
val.Text = s
val.TextColor3 = cfg.Color or win.Theme.Accent
end
function obj:Refresh()
if type(getter) ~= "function" then return end
local ok, v = pcall(getter)
if not ok then return end
if v ~= last then
prev = last
last = v
end
render(last)
end
function obj:SetGet(fn) getter = fn prev, last = nil, nil obj:Refresh() end
function obj:Get() return last end
local conn
conn = Library._tick(interval, function()
if not frame.Parent then conn:Disconnect() return end
if not win.Visible then return end
pcall(obj.Refresh, obj)
end)
table.insert(win.Conns, conn)
obj._cleanup = function() if conn then conn:Disconnect() end end
obj:Refresh()
self:_Register(frame, cfg.Name, h)
obj.Frame = frame
return obj
end
local decorate, NOVALUE = Library._decorate, Library._NOVALUE
if not decorate or not NOVALUE then warn("[SpectreUI] Stepper/Stat: decorate not available") return end
NOVALUE.Stat = true
for fname, kind in pairs({ CreateStepper = "Stepper", CreateStat = "Stat" }) do
local orig = Section[fname]
Section[fname] = function(self, cfg, ...)
local obj = orig(self, cfg, ...)
if type(obj) == "table" then
local dc = type(cfg) == "table" and cfg or (type(cfg) == "string" and { Name = cfg } or {})
local ok, err = pcall(decorate, self, kind, dc, obj)
if not ok then warn("[SpectreUI] decorate(" .. kind .. ") failed: " .. tostring(err)) end
if obj._cleanup and obj.Destroy then
local d, cl = obj.Destroy, obj._cleanup
obj.Destroy = function(s, ...) cl() return d(s, ...) end
end
end
return obj
end
end
end
Library.Version = "3.13.4"
end
do
function Library:GetControl(flag) return self.Objects[flag] end
function Library:SetFlag(flag, value, silent)
local o = self.Objects[flag]
if not (o and o.Set) then return false, "unknown flag" end
local ok, err = pcall(o.Set, o, value, silent)
if not ok then return false, tostring(err) end
return true
end
function Library:ToggleFlag(flag)
local o = self.Objects[flag]
if not (o and o.Get and o.Set) then return false, "unknown flag" end
local v = o:Get()
if type(v) ~= "boolean" then return false, "not a boolean flag" end
local ok, err = Library:SetFlag(flag, not v)
if not ok then return false, err end
return true, not v
end
function Library:SetFlags(tbl, silent)
local n = 0
if type(tbl) ~= "table" then return 0 end
self:Transaction("Set flags", function()
for flag, v in pairs(tbl) do
if self:SetFlag(flag, v, silent) then n += 1 end
end
end)
return n
end
function Library:GetFlags() return self:Snapshot() end
Library._hotkeys = {}
local hkConn
local function modsMatch(h)
local function down(a, b) return UserInputService:IsKeyDown(a) or UserInputService:IsKeyDown(b) end
local ctrl = down(Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl)
local shift = down(Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift)
local alt = down(Enum.KeyCode.LeftAlt, Enum.KeyCode.RightAlt)
return (not not h.Ctrl) == ctrl and (not not h.Shift) == shift and (not not h.Alt) == alt
end
local function ensureHotkeys()
if hkConn then return end
hkConn = UserInputService.InputBegan:Connect(function(i, gp)
if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
local typing = UserInputService:GetFocusedTextBox() ~= nil
for _, h in ipairs(table.clone(Library._hotkeys)) do
if h.Key == i.KeyCode and not h.Disabled and modsMatch(h) and (h.AllowTyping or (not gp and not typing)) then
local ok, err = pcall(h.Fn, h)
if not ok then warn("[SpectreUI] Hotkey error: " .. tostring(err)) end
end
end
end)
end
function Library:Hotkey(key, fn, opts)
opts = opts or {}
if typeof(key) ~= "EnumItem" or key.EnumType ~= Enum.KeyCode then error("Hotkey: first argument must be an Enum.KeyCode", 2) end
if type(fn) ~= "function" then error("Hotkey: second argument must be a function", 2) end
local h = { Key = key, Fn = fn, Ctrl = opts.Ctrl, Shift = opts.Shift, Alt = opts.Alt, Desc = opts.Desc, AllowTyping = opts.AllowTyping }
table.insert(self._hotkeys, h)
ensureHotkeys()
local handle = {}
function handle:Disconnect()
local i = table.find(Library._hotkeys, h)
if i then table.remove(Library._hotkeys, i) end
end
function handle:SetKey(k)
if typeof(k) == "EnumItem" and k.EnumType == Enum.KeyCode then h.Key = k end
end
function handle:SetEnabled(v) h.Disabled = not v end
return handle
end
function Library:ListHotkeys()
local out = {}
for _, h in ipairs(self._hotkeys) do
local parts = {}
if h.Ctrl then table.insert(parts, "Ctrl") end
if h.Shift then table.insert(parts, "Shift") end
if h.Alt then table.insert(parts, "Alt") end
table.insert(parts, h.Key.Name)
table.insert(out, { Key = table.concat(parts, "+"), Desc = h.Desc or "" })
end
return out
end
local prevUnload = Library.Unload
function Library:Unload(...)
table.clear(self._hotkeys)
if hkConn then hkConn:Disconnect() hkConn = nil end
return prevUnload(self, ...)
end
local SHARE_KEYS = { "Background", "Panel", "Card", "Control", "Border", "Accent", "Accent2", "AccentSoft", "Sheen", "Text", "SubText" }
local SHARE_FX = { petals = true, orbs = true, embers = true, rain = true, grid = true }
local function toHexC(c)
return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end
local function fromHexC(str)
local r, g, b = tostring(str):match("^#?(%x%x)(%x%x)(%x%x)$")
if not r then return nil end
return Color3.fromRGB(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16))
end
local function cleanName(n)
if type(n) ~= "string" then return nil end
n = n:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%c", "")
if n == "" then return nil end
return n:sub(1, 28)
end
function Library:ExportTheme(src, name)
local t, tname
if type(src) == "string" then
t, tname = self.Themes[src], src
elseif type(src) == "table" then
t, tname = src, "Shared"
else
t, tname = self.Themes[self.ThemeName] or self.Theme, self.ThemeName
end
if type(t) ~= "table" then return nil, "unknown theme" end
local data = { v = 1, name = name or tname, FX = t.FX }
for _, k in ipairs(SHARE_KEYS) do
local c = t[k]
if typeof(c) ~= "Color3" then c = (self.Themes.Rose or {})[k] end
if typeof(c) == "Color3" then data[k] = toHexC(c) end
end
return "SPT1:" .. HttpService:JSONEncode(data)
end
function Library:ImportTheme(code, name)
if type(code) ~= "string" then return false, "usage: ImportTheme(string, name?)" end
local body = code:match("^%s*SPT1:(.+)$")
if not body then return false, "not a SpectreUI theme code" end
local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
if not ok or type(data) ~= "table" then return false, "invalid theme code" end
local t = {}
for _, k in ipairs(SHARE_KEYS) do
local c = fromHexC(data[k])
if not c then return false, "missing or bad colour: " .. k end
t[k] = c
end
t.FX = SHARE_FX[data.FX] and data.FX or "orbs"
local base = cleanName(name) or cleanName(data.name) or "Imported"
local final, i = base, 2
while self.Themes[final] do
final = base:sub(1, 24) .. " " .. i
i += 1
end
local ok2, err = self:RegisterTheme(final, t)
if not ok2 then return false, err end
self:SaveThemes()
if self._fire then self._fire("list") end
return true, final
end
function Window:ExportTheme() return Library:ExportTheme(self.Theme, self.ThemeName) end
function Window:ImportTheme(code, name, apply)
local ok, res = Library:ImportTheme(code, name)
if not ok then return false, res end
if apply ~= false then self:SetTheme(res, true) end
return true, res
end
Library.TextScale = Library.TextScale or 1
function Window:_ApplyTextScale(root)
local s = self._textScale or Library.TextScale or 1
for _, o in ipairs((root or self.Gui):GetDescendants()) do
if (o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox")) and not o.TextScaled then
local base = o:GetAttribute("SpSize")
if base == nil then
if s == 1 then continue end
base = o.TextSize
o:SetAttribute("SpSize", base)
end
o.TextSize = math.max(8, math.floor(base * s + 0.5))
end
end
end
function Window:SetTextScale(s, remember)
s = tonumber(s)
if not s then return false, "usage: SetTextScale(0.7 .. 1.4)" end
s = math.clamp(s, 0.7, 1.4)
self._textScale = s
self:_ApplyTextScale()
if remember then
Library.TextScale = s
Library:SaveThemes()
end
return true, s
end
function Window:GetTextScale() return self._textScale or Library.TextScale or 1 end
for _, fname in ipairs({ "CreateThemeTab", "CreateSettingsTab", "CreateDefaultTabs" }) do
local prev = Window[fname]
if prev then
Window[fname] = function(self, ...)
local a, b = prev(self, ...)
if (self._textScale or Library.TextScale or 1) ~= 1 then self:_ApplyTextScale() end
return a, b
end
end
end
end
do
function Section:CreateItemGrid(cfg)
cfg = cfg or {}
local T = self.Window.Theme
local CW, CH = cfg.CellWidth or 92, cfg.CellHeight or 100
local prefix = cfg.Prefix or "×"
local frame = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Parent = self.Body }, { list(4) })
if cfg.Name then
new("TextLabel", {
LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = cfg.Name, Font = T.Font, TextSize = 14,
TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
})
end
local grid = new("Frame", { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Parent = frame }, {
new("UIGridLayout", {
CellSize = UDim2.fromOffset(CW, CH), CellPadding = UDim2.fromOffset(8, 8),
SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Left,
}),
})
local empty = new("TextLabel", {
LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, Text = cfg.Empty or "", Font = T.Font, TextSize = 14,
TextColor3 = T.SubText, Visible = false, Parent = frame,
})
self:_Register(frame, cfg.Name, CH + 20)
local gl = grid:FindFirstChildOfClass("UIGridLayout")
local win = self.Window
local lastCols, settling = 0, false
local relayout
local function settle()
if settling then return end
settling = true
task.delay(0.15, function()
settling = false
if win._resizing then settle() else relayout() end
end)
end
relayout = function()
local sc = (win.Scale and win.Scale.Scale) or 1
if sc <= 0.01 then return end
local w = grid.AbsoluteSize.X / sc
if w <= 0 then return end
local gap = 8
local cols = math.max(1, math.floor((w + gap) / (CW + gap) + 0.5))
if win._resizing and cols == lastCols then settle() return end
lastCols = cols
local cw = math.max(60, math.floor((w - gap * (cols - 1)) / cols))
if gl.CellSize.X.Offset ~= cw then gl.CellSize = UDim2.fromOffset(cw, CH) end
if win._resizing then settle() end
end
grid:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
task.defer(relayout)
local obj, cards, data = { Frame = frame }, {}, {}
local function makeImage(parent, img)
if type(img) == "number" then img = "rbxassetid://" .. img end
if type(img) == "string" and img ~= "" and not Library:IsIconName(img) then
return new("ImageLabel", {
AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(40, 40),
BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Image = img, Parent = parent,
})
end
local ic = Library:IsIconName(img) and img or "lucide:package"
local im = Library:MakeIcon(Library:ResolveIcon(ic), T.SubText)
im.AnchorPoint = Vector2.new(0.5, 0.5)
im.Position = UDim2.fromScale(0.5, 0.5)
im.Size = UDim2.fromOffset(26, 26)
im.Parent = parent
return im
end
local function build(item)
local card = new("TextButton", {
Name = tostring(item.Name), AutoButtonColor = false, Text = "", BackgroundColor3 = T.Control, BackgroundTransparency = 0.1,
BorderSizePixel = 0, Parent = grid,
}, { corner(12), stroke(T.Border, 1, 0.4) })
local box = new("Frame", {
Position = UDim2.fromOffset(5, 5), Size = UDim2.new(1, -10, 0, 50), BackgroundColor3 = T.Panel, BackgroundTransparency = 0.3,
BorderSizePixel = 0, Parent = card,
}, { corner(9) })
makeImage(box, item.Image)
local badge = new("TextLabel", {
Name = "Badge", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -3, 0, 3), Size = UDim2.fromOffset(0, 18),
AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = T.Accent, BackgroundTransparency = 0.25, BorderSizePixel = 0,
Font = T.FontBold, TextSize = 14, TextColor3 = Library.OnAccent(T.Accent), Text = "",
Parent = box,
}, { corner(9), padding(6, 0, 6, 0) })
Library._oa(badge)
new("TextLabel", {
Position = UDim2.fromOffset(4, 58), Size = UDim2.new(1, -8, 0, 36), BackgroundTransparency = 1, Text = tostring(item.Name),
Font = T.FontMedium or T.Font, TextSize = 13, TextColor3 = T.Text, TextWrapped = true, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card,
})
feedback(card, card, "BackgroundColor3", T.Control, T.Lift, T.AccentSoft, true)
strokeFeedback(card, card:FindFirstChildOfClass("UIStroke"), 0.4, 0.05)
card.MouseButton1Click:Connect(function()
local it = data[item.Name]
if it then safe(cfg.Callback, it) end
end)
return card
end
local function paint(name)
local it, card = data[name], cards[name]
if it and card then
local badge = card:FindFirstChild("Badge", true)
if badge then badge.Text = prefix .. tostring(it.Amount or 0) end
end
end
function obj:SetItems(list_)
local seen, n = {}, 0
for i, it in ipairs(list_ or {}) do
local key = it.Name
seen[key] = true
data[key] = { Name = key, Amount = it.Amount, Image = it.Image, Id = it.Id }
if not cards[key] then cards[key] = build(data[key]) end
cards[key].LayoutOrder = i
paint(key)
n += 1
end
for key, card in pairs(cards) do
if not seen[key] then
card:Destroy()
cards[key], data[key] = nil, nil
end
end
empty.Visible = n == 0 and (cfg.Empty or "") ~= ""
frame.Visible = true
end
function obj:SetAmount(name, amount)
if data[name] then data[name].Amount = amount paint(name) end
end
function obj:Clear() obj:SetItems({}) end
function obj:GetItem(name) return data[name] end
function obj:Count()
local n = 0
for _ in pairs(data) do n += 1 end
return n
end
function obj:SetEmpty(text)
cfg.Empty = text
empty.Text = text or ""
empty.Visible = obj:Count() == 0 and (text or "") ~= ""
end
if cfg.Items then obj:SetItems(cfg.Items) end
if cfg.Items and #cfg.Items == 0 then empty.Visible = (cfg.Empty or "") ~= "" end
return obj
end
function Window:AskAmount(cfg)
cfg = cfg or {}
local max = tonumber(cfg.Max)
local content = cfg.Content
if not content and max then content = "มีทั้งหมด: " .. max end
local buttons = { { Text = cfg.Confirm or "ยืนยัน", Value = "ok", Style = "Primary" } }
if max then buttons[#buttons + 1] = { Text = (cfg.MaxText or "ทั้งหมด") .. " (" .. max .. ")", Value = "max", Style = "Secondary" } end
buttons[#buttons + 1] = { Text = cfg.Cancel or "ยกเลิก", Value = "cancel", Style = "Secondary" }
local dlg = self:Dialog({
Title = cfg.Title or "ใส่จำนวน", Content = content or "", Kind = cfg.Kind or "Info", Icon = cfg.Icon,
Input = { Placeholder = "จำนวน", Default = tostring(cfg.Default or 1), Numeric = true, MaxLength = 9, AutoFocus = true },
Buttons = buttons,
})
local value, text = dlg:Wait()
if value == "max" and max then return math.floor(max) end
if value ~= "ok" then return nil end
local n = math.floor(tonumber(text) or 0)
if n <= 0 then return nil end
if max and n > max then n = math.floor(max) end
return n
end
end
do
local V2 = Vector2.new
local function clipCopy(win, text, title)
text = tostring(text)
if type(setclipboard) == "function" then
pcall(setclipboard, text)
if win then
local shown = #text > 48 and (text:sub(1, 45) .. "...") or text
pcall(function() win:Notify({ Title = title or "Copied", Content = shown, Kind = "Success", Duration = 1.6 }) end)
end
return true
end
if win then
pcall(function() win:Notify({ Title = "Clipboard not supported", Kind = "Warning", Duration = 3 }) end)
end
return false
end
function Library:Copy(text, title)
return clipCopy(Library.Windows[#Library.Windows], text, title)
end
local function statusColor(kind, fallback)
local ok, c = pcall(function() return Library:GetStatusColor(kind) end)
if ok and typeof(c) == "Color3" then return c end
return fallback
end
local function clampLen(s, n)
local len = utf8.len(s)
if not len then return s:sub(1, n) end
if len <= n then return s end
return s:sub(1, utf8.offset(s, n + 1) - 1)
end
local function caption(parent, T, text)
return new("TextLabel", {
Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -16, 0, 16), BackgroundTransparency = 1, Text = tostring(text),
Font = T.Font, TextSize = 14, TextColor3 = T.SubText, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = parent,
})
end
function Section:CreateButtonRow(cfg)
cfg = cfg or {}
local T = self.Window.Theme
local defs = type(cfg.Buttons) == "table" and cfg.Buttons or {}
if #defs == 0 then defs = { { Name = "Button" } } end
local n, gap, h = #defs, 6, rowH()
local row = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, Parent = self.Body },
{ list(gap, { FillDirection = Enum.FillDirection.Horizontal }) })
local btns = {}
for i, d in ipairs(defs) do
if type(d) == "string" then d = { Name = d } end
local color = d.Color
local b = new("TextButton", {
LayoutOrder = i, Size = UDim2.new(1 / n, -math.floor(gap * (n - 1) / n), 1, 0),
BackgroundColor3 = color or T.Control, BackgroundTransparency = 0.1, AutoButtonColor = false,
Text = d.Name or "Button", Font = d.Bold and T.FontBold or T.Font, TextSize = 14,
TextColor3 = d.TextColor or (color and Library.OnAccent(color)) or T.Text,
TextTruncate = Enum.TextTruncate.AtEnd, ClipsDescendants = true, Parent = row,
}, { new("UICorner", { CornerRadius = UDim.new(0, 8) }), stroke(color and color:Lerp(Color3.new(1, 1, 1), 0.3) or T.Border, 1, color and 0.5 or 0.35) })
local bs = b:FindFirstChildOfClass("UIStroke")
new("Frame", {
Size = UDim2.fromScale(1, 0.55), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Active = false, ZIndex = 3, Visible = false, Parent = b,
}, {
new("UICorner", { CornerRadius = UDim.new(0, 8) }),
new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 1) }) }),
})
if not color then
b.MouseEnter:Connect(function() if not usingTouch() then tween(bs, 0.16, { Color = T.Accent }) end end)
b.MouseLeave:Connect(function() tween(bs, 0.18, { Color = T.Border }) end)
end
if color then
strokeFeedback(b, bs, 0.3, 0.05)
else
feedback(b, b, "BackgroundColor3", T.Control, T.Lift, T.AccentSoft)
strokeFeedback(b, bs, 0.35, 0.05)
end
b.MouseButton1Click:Connect(function() safe(d.Callback) end)
clickRipple(b, nil)
btns[i] = b
end
self:_Register(row, "buttons", h)
local obj = { Frame = row, Buttons = btns }
function obj:SetText(i, t)
if btns[i] then btns[i].Text = tostring(t) end
end
return obj
end
function Section:CreateInputButton(cfg)
cfg = cfg or {}
local T = self.Window.Theme
local h = rowH()
local hasLabel = cfg.Name ~= nil and cfg.Label ~= false
local top = hasLabel and 18 or 0
local frame = new("Frame", { Size = UDim2.new(1, 0, 0, top + h), BackgroundTransparency = 1, Parent = self.Body })
if hasLabel then caption(frame, T, cfg.Name) end
local bw = tonumber(cfg.ButtonWidth) or 84
local boxFrame = new("Frame", {
Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, -(bw + 6), 0, h), BackgroundColor3 = T.Control,
BackgroundTransparency = 0.1, BorderSizePixel = 0, ClipsDescendants = true, Parent = frame,
}, { corner(2), stroke(T.Border, 1, 0.35) })
local boxStroke = boxFrame:FindFirstChildOfClass("UIStroke")
local box = new("TextBox", {
Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 1, 0), BackgroundTransparency = 1, Text = tostring(cfg.Default or ""),
PlaceholderText = cfg.Placeholder or "", PlaceholderColor3 = T.SubText, Font = T.Font, TextSize = 14, TextColor3 = T.Text,
TextXAlignment = LEFT, ClearTextOnFocus = false, Parent = boxFrame,
})
local btn = new("TextButton", {
AnchorPoint = V2(1, 0), Position = UDim2.new(1, 0, 0, top), Size = UDim2.fromOffset(bw, h), BackgroundColor3 = T.Accent,
BackgroundTransparency = 0.05, AutoButtonColor = false, Text = cfg.Button or "OK", Font = T.FontBold, TextSize = 14,
TextColor3 = Library.OnAccent(T.Accent), TextTruncate = Enum.TextTruncate.AtEnd, ClipsDescendants = true, Parent = frame,
}, { corner(2), stroke(T.Accent:Lerp(Color3.new(1, 1, 1), 0.3), 1, 0.5) })
strokeFeedback(btn, btn:FindFirstChildOfClass("UIStroke"), 0.5, 0.05)
clickRipple(btn, nil)
local value = box.Text
local obj = {}
local function submit()
local t = box.Text
if cfg.Trim ~= false then t = t:gsub("^%s+", ""):gsub("%s+$", "") end
value = t
setFlag(cfg, value)
safe(cfg.Callback, value)
if cfg.ClearOnSubmit then box.Text = "" end
end
if cfg.MaxLength then
box:GetPropertyChangedSignal("Text"):Connect(function()
local c = clampLen(box.Text, cfg.MaxLength)
if c ~= box.Text then box.Text = c end
end)
end
box.Focused:Connect(function() tween(boxStroke, 0.15, { Color = T.Accent, Transparency = 0.1 }) end)
box.FocusLost:Connect(function(enter)
tween(boxStroke, 0.18, { Color = T.Border, Transparency = 0.35 })
if enter and cfg.EnterSubmit ~= false then submit() end
end)
btn.MouseButton1Click:Connect(submit)
function obj:Get() return value end
function obj:GetText() return box.Text end
function obj:Set(text, silent)
box.Text = tostring(text == nil and "" or text)
value = box.Text
setFlag(cfg, value)
if not silent then safe(cfg.Callback, value) end
end
function obj:Clear() box.Text = "" end
function obj:Focus() box:CaptureFocus() end
function obj:SetButtonText(t) btn.Text = tostring(t) end
setFlag(cfg, value)
self:_Register(frame, cfg.Name or cfg.Placeholder, top + h)
obj.Frame = frame
return regObj(cfg, obj)
end
function Section:CreateKeyValue(cfg)
cfg = cfg or {}
local win = self.Window
local T = win.Theme
local h = rowH()
local copyable = cfg.Copyable ~= false
local value = cfg.Value == nil and "" or cfg.Value
local row = new("TextButton", {
Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = T.Control, BackgroundTransparency = 1, Text = "",
AutoButtonColor = false, Active = copyable, Parent = self.Body,
}, { corner(13) })
if copyable then feedback(row, row, "BackgroundTransparency", 1, 0.82, 0.62, true) end
new("TextLabel", {
Position = UDim2.fromOffset(8, 0), Size = UDim2.new(0.42, -8, 1, 0), BackgroundTransparency = 1, Text = cfg.Name or "Key",
Font = T.Font, TextSize = 14, TextColor3 = T.SubText, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
})
local val = new("TextLabel", {
AnchorPoint = V2(1, 0), Position = UDim2.new(1, -8, 0, 0), Size = UDim2.new(0.58, -8, 1, 0), BackgroundTransparency = 1,
Text = tostring(value), Font = T.FontBold, TextSize = 14, TextColor3 = cfg.Color or T.Text,
TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
})
if copyable then
row.MouseButton1Click:Connect(function() clipCopy(win, tostring(value), "Copied") end)
end
self:_Register(row, cfg.Name, h)
local obj = { Frame = row }
function obj:Set(v)
value = v == nil and "" or v
val.Text = tostring(value)
end
function obj:Get() return value end
function obj:SetColor(c) val.TextColor3 = c end
return obj
end
function Section:CreateCodeBlock(cfg)
if type(cfg) == "string" then cfg = { Text = cfg } end
cfg = cfg or {}
local win = self.Window
local T = win.Theme
local bodyH = tonumber(cfg.Height) or 110
local showCopy = cfg.Copy ~= false
local hasHead = cfg.Name ~= nil or showCopy
local top = hasHead and (22) or 0
local maxChars = tonumber(cfg.MaxChars) or 20000
local frame = new("Frame", { Size = UDim2.new(1, 0, 0, top + bodyH), BackgroundTransparency = 1, Parent = self.Body })
if cfg.Name then
new("TextLabel", {
Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -76, 0, 18), BackgroundTransparency = 1, Text = cfg.Name,
Font = T.Font, TextSize = 14, TextColor3 = T.SubText, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
})
end
local text = tostring(cfg.Text or "")
local scroll = new("ScrollingFrame", { ElasticBehavior = Enum.ElasticBehavior.Never,
Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, 0, 0, bodyH), BackgroundColor3 = T.Control, BackgroundTransparency = 0.25,
BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = T.Accent, CanvasSize = UDim2.new(), AutomaticCanvasSize = AY,
ScrollingDirection = Enum.ScrollingDirection.Y, Parent = frame,
}, { corner(10), stroke(T.Border, 1, 0.4), padding(8, 6, 8, 6) })
local label = new("TextLabel", {
Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Text = text, Font = Enum.Font.Code, TextSize = 13,
TextColor3 = T.Text, TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, Parent = scroll,
})
local obj = {}
if showCopy then
local cb = new("TextButton", {
AnchorPoint = V2(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(58, 18), BackgroundColor3 = T.Control,
BackgroundTransparency = 0.1, AutoButtonColor = false, Text = "Copy", Font = T.Font, TextSize = 13, TextColor3 = T.Text,
ClipsDescendants = true, Parent = frame,
}, { corner(9), stroke(T.Border, 1, 0.35) })
feedback(cb, cb, "BackgroundColor3", T.Control, T.Lift, T.AccentSoft)
cb.MouseButton1Click:Connect(function() obj:Copy() end)
end
local function toBottom()
if cfg.AutoScroll == false then return end
task.defer(function()
if scroll.Parent then
scroll.CanvasPosition = V2(0, math.max(0, scroll.AbsoluteCanvasSize.Y - scroll.AbsoluteSize.Y))
end
end)
end
function obj:Set(t)
text = tostring(t == nil and "" or t)
label.Text = text
end
function obj:Get() return text end
function obj:Append(line)
line = tostring(line == nil and "" or line)
text = (text ~= "" and (text .. "\n") or "") .. line
if #text > maxChars then text = text:sub(#text - maxChars + 1) end
label.Text = text
toBottom()
end
function obj:Clear()
text = ""
label.Text = ""
end
function obj:Copy() return clipCopy(win, text, "Copied") end
self:_Register(frame, cfg.Name or "code", top + bodyH)
obj.Frame = frame
return obj
end
function Section:CreateCountdown(cfg)
cfg = cfg or {}
local win = self.Window
local T = win.Theme
local h = rowH()
local target
if tonumber(cfg.Target) then target = tonumber(cfg.Target)
elseif tonumber(cfg.Seconds) then target = os.time() + tonumber(cfg.Seconds) end
local frame = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, Parent = self.Body })
new("TextLabel", {
Size = UDim2.new(0.45, 0, 1, 0), BackgroundTransparency = 1, Text = cfg.Name or "Time left", Font = T.Font, TextSize = 14,
TextColor3 = T.SubText, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
})
local val = new("TextLabel", {
AnchorPoint = V2(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0.55, 0, 1, 0), BackgroundTransparency = 1, Text = "--",
Font = T.FontBold, TextSize = 14, TextColor3 = cfg.Color or T.Accent, TextXAlignment = Enum.TextXAlignment.Right,
TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
})
local obj = {}
local done, shown = false, nil
local function left()
if not target then return nil end
return math.max(0, target - os.time())
end
local function fmt(s)
if type(cfg.Format) == "function" then
local ok, r = pcall(cfg.Format, s)
if ok and r ~= nil then return tostring(r) end
end
local d = math.floor(s / 86400)
local hh = math.floor((s % 86400) / 3600)
local mm = math.floor((s % 3600) / 60)
local ss = math.floor(s % 60)
if d > 0 then return string.format("%dd %02d:%02d:%02d", d, hh, mm, ss) end
return string.format("%02d:%02d:%02d", hh, mm, ss)
end
local function render()
local s = left()
if s == nil then
if shown ~= "--" then shown = "--" val.Text = "--" end
return
end
local expired = s <= 0
local text = expired and (cfg.ExpiredText or "Expired") or fmt(s)
if text ~= shown then shown = text val.Text = text end
local col = cfg.Color or win.Theme.Accent
if expired then col = statusColor("Error", Color3.fromRGB(248, 113, 113))
elseif cfg.WarnAt and s <= cfg.WarnAt then col = statusColor("Warning", Color3.fromRGB(250, 204, 21)) end
val.TextColor3 = col
if expired and not done then
done = true
safe(cfg.OnDone, obj)
elseif not expired then
done = false
end
end
function obj:SetTarget(epoch) target = tonumber(epoch) done = false render() end
function obj:SetSeconds(sec) target = os.time() + (tonumber(sec) or 0) done = false render() end
function obj:Add(sec) target = (target or os.time()) + (tonumber(sec) or 0) render() end
function obj:Get() return left() or 0 end
function obj:IsExpired() local s = left() return s ~= nil and s <= 0 end
local conn
conn = Library._tick(0.5, function()
if not frame.Parent then conn:Disconnect() return end
if not win.Visible then return end
pcall(render)
end)
table.insert(win.Conns, conn)
obj._cleanup = function() if conn then conn:Disconnect() end end
self:_Register(frame, cfg.Name or "countdown", h)
obj.Frame = frame
render()
return obj
end
function Section:CreateListBox(cfg)
cfg = cfg or {}
local win = self.Window
local T = win.Theme
local multi = cfg.Multi == true
local listH = tonumber(cfg.Height) or 120
local hasSearch = cfg.Search == true
local rh = 28
local top = cfg.Name ~= nil and 20 or 0
local sh = hasSearch and (rowH() - 2) or 0
local listTop = top + (hasSearch and (sh + 6) or 0)
local frame = new("Frame", { Size = UDim2.new(1, 0, 0, listTop + listH), BackgroundTransparency = 1, Parent = self.Body })
if cfg.Name then caption(frame, T, cfg.Name) end
local searchBox
if hasSearch then
local sf = new("Frame", {
Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, 0, 0, sh), BackgroundColor3 = T.Control, BackgroundTransparency = 0.1,
BorderSizePixel = 0, ClipsDescendants = true, Parent = frame,
}, { corner(12), stroke(T.Border, 1, 0.35) })
searchBox = new("TextBox", {
Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 1, 0), BackgroundTransparency = 1, Text = "",
PlaceholderText = cfg.SearchPlaceholder or "Search...", PlaceholderColor3 = T.SubText, Font = T.Font, TextSize = 14,
TextColor3 = T.Text, TextXAlignment = LEFT, ClearTextOnFocus = false, Parent = sf,
})
end
local scroll = new("ScrollingFrame", { ElasticBehavior = Enum.ElasticBehavior.Never,
Position = UDim2.fromOffset(0, listTop), Size = UDim2.new(1, 0, 0, listH), BackgroundColor3 = T.Control, BackgroundTransparency = 0.25,
BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = T.Accent, CanvasSize = UDim2.new(), AutomaticCanvasSize = AY,
ScrollingDirection = Enum.ScrollingDirection.Y, Parent = frame,
}, { corner(10), stroke(T.Border, 1, 0.4), list(2), padding(4, 4, 4, 4) })
local empty = new("TextLabel", {
LayoutOrder = 1000000, Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Text = cfg.Empty or "No items",
Font = T.Font, TextSize = 13, TextColor3 = T.SubText, Visible = false, Parent = scroll,
})
local items, rows, sel = {}, {}, {}
local obj = {}
local function selectedList()
local out = {}
for _, n in ipairs(items) do
if sel[n] then out[#out + 1] = n end
end
return out
end
local function current()
if multi then return selectedList() end
for _, n in ipairs(items) do
if sel[n] then return n end
end
return nil
end
local function paint(name)
local r = rows[name]
if not r then return end
local on = sel[name] == true
tween(r.Btn, 0.14, { BackgroundTransparency = on and 0.15 or 1 })
tween(r.Label, 0.14, { TextColor3 = on and T.Text or T.SubText })
r.Bar.Visible = on
end
local function emit(silent)
setFlag(cfg, current())
if not silent then safe(cfg.Callback, current()) end
end
local function toggle(name)
if multi then
sel[name] = (not sel[name]) or nil
elseif sel[name] then
if not cfg.AllowDeselect then return end
sel[name] = nil
else
for k in pairs(sel) do
sel[k] = nil
paint(k)
end
sel[name] = true
end
paint(name)
emit(false)
end
local function applyFilter()
local q = searchBox and searchBox.Text:lower() or ""
q = q:gsub("^%s+", ""):gsub("%s+$", "")
local any = false
for _, n in ipairs(items) do
local r = rows[n]
if r then
local vis = q == "" or n:lower():find(q, 1, true) ~= nil
r.Btn.Visible = vis
any = any or vis
end
end
empty.Visible = not any
empty.Text = (#items == 0) and (cfg.Empty or "No items") or "No matches"
end
if searchBox then searchBox:GetPropertyChangedSignal("Text"):Connect(applyFilter) end
local function makeRow(name, order)
local btn = new("TextButton", {
LayoutOrder = order, Size = UDim2.new(1, 0, 0, rh), BackgroundColor3 = T.AccentSoft, BackgroundTransparency = 1,
Text = "", AutoButtonColor = false, Parent = scroll,
}, { corner(8) })
local bar = new("Frame", {
AnchorPoint = V2(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.new(0, 3, 0.55, 0), BackgroundColor3 = T.Accent,
BorderSizePixel = 0, Visible = false, Parent = btn,
}, { corner(2) })
local lab = new("TextLabel", {
Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -20, 1, 0), BackgroundTransparency = 1, Text = name, Font = T.Font,
TextSize = 14, TextColor3 = T.SubText, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = btn,
})
btn.MouseEnter:Connect(function()
if usingTouch() or sel[name] then return end
tween(btn, 0.12, { BackgroundTransparency = 0.6 })
end)
btn.MouseLeave:Connect(function()
if sel[name] then return end
tween(btn, 0.14, { BackgroundTransparency = 1 })
end)
local press = dragSafePress(btn, function() end, function() end, 12)
btn.MouseButton1Click:Connect(function()
if press.moved then return end
toggle(name)
end)
rows[name] = { Btn = btn, Label = lab, Bar = bar }
end
local function build(src, keep)
local prev = keep and sel or {}
for _, r in pairs(rows) do r.Btn:Destroy() end
rows, items, sel = {}, {}, {}
local seen = {}
for _, it in ipairs(type(src) == "table" and src or {}) do
local name = tostring(type(it) == "table" and (it.Name or it[1]) or it)
if not seen[name] then
seen[name] = true
items[#items + 1] = name
makeRow(name, #items)
if prev[name] then sel[name] = true end
end
end
if not multi then
local first
for _, n in ipairs(items) do
if sel[n] then
if first then sel[n] = nil else first = n end
end
end
end
for _, n in ipairs(items) do paint(n) end
applyFilter()
end
local function applyValue(v)
for k in pairs(sel) do sel[k] = nil end
local want = {}
if type(v) == "table" then
for _, n in ipairs(v) do want[tostring(n)] = true end
elseif v ~= nil and v ~= "" then
want[tostring(v)] = true
end
local picked = false
for _, n in ipairs(items) do
if want[n] and (multi or not picked) then
sel[n] = true
picked = true
end
end
for _, n in ipairs(items) do paint(n) end
end
function obj:Get() return current() end
function obj:Set(v, silent)
applyValue(v)
emit(silent == true)
end
function obj:Clear(silent)
applyValue(nil)
emit(silent == true)
end
function obj:Refresh(src, keep)
build(src, keep ~= false)
emit(true)
end
function obj:Add(item)
local copy = table.clone(items)
copy[#copy + 1] = item
build(copy, true)
end
function obj:Remove(item)
local name, copy = tostring(item), {}
for _, n in ipairs(items) do
if n ~= name then copy[#copy + 1] = n end
end
build(copy, true)
emit(true)
end
function obj:GetItems() return table.clone(items) end
function obj:Count() return #items end
build(cfg.Items, false)
if cfg.Default ~= nil then applyValue(cfg.Default) end
setFlag(cfg, current())
self:_Register(frame, cfg.Name or "list", listTop + listH)
obj.Frame = frame
return regObj(cfg, obj)
end
function Section:CreateTable(cfg)
cfg = cfg or {}
local win = self.Window
local T = win.Theme
local bodyH = tonumber(cfg.Height) or 130
local rh = tonumber(cfg.RowHeight) or (24)
local top = cfg.Name ~= nil and 20 or 0
local headH = 24
local total = top + headH + 4 + bodyH
local clickable = type(cfg.OnRowClick) == "function"
local cols = {}
for i, c in ipairs(type(cfg.Columns) == "table" and cfg.Columns or { "A", "B" }) do
if type(c) == "table" then
cols[i] = { Name = tostring(c.Name or c[1] or ""), W = tonumber(c.Width) }
else
cols[i] = { Name = tostring(c) }
end
end
local fixed, free = 0, 0
for _, c in ipairs(cols) do
if c.W then fixed += c.W else free += 1 end
end
local rest = math.max(0.05, 1 - fixed)
local tot = 0
for _, c in ipairs(cols) do
c.S = c.W or (rest / math.max(1, free))
tot += c.S
end
local acc = 0
for _, c in ipairs(cols) do
c.S = c.S / tot
c.X = acc
acc += c.S
end
local frame = new("Frame", { Size = UDim2.new(1, 0, 0, total), BackgroundTransparency = 1, Parent = self.Body })
if cfg.Name then caption(frame, T, cfg.Name) end
local head = new("Frame", {
Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, 0, 0, headH), BackgroundColor3 = T.Control, BackgroundTransparency = 0.3,
BorderSizePixel = 0, Parent = frame,
}, { corner(8) })
for _, c in ipairs(cols) do
new("TextLabel", {
Position = UDim2.new(c.X, 8, 0, 0), Size = UDim2.new(c.S, -10, 1, 0), BackgroundTransparency = 1, Text = c.Name,
Font = T.FontBold, TextSize = 13, TextColor3 = T.SubText, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = head,
})
end
local scroll = new("ScrollingFrame", { ElasticBehavior = Enum.ElasticBehavior.Never,
Position = UDim2.fromOffset(0, top + headH + 4), Size = UDim2.new(1, 0, 0, bodyH), BackgroundColor3 = T.Control,
BackgroundTransparency = 0.25, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = T.Accent,
CanvasSize = UDim2.new(), AutomaticCanvasSize = AY, ScrollingDirection = Enum.ScrollingDirection.Y, Parent = frame,
}, { corner(10), stroke(T.Border, 1, 0.4), list(0), padding(0, 2, 0, 2) })
local empty = new("TextLabel", {
LayoutOrder = 1000000, Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = cfg.Empty or "No data",
Font = T.Font, TextSize = 13, TextColor3 = T.SubText, Visible = false, Parent = scroll,
})
local data, rowFrames, cells = {}, {}, {}
local obj = {}
local function makeRow(i)
local row = data[i]
local zebra = cfg.Zebra ~= false and i % 2 == 0
local base = zebra and 0.75 or 1
local r = new("TextButton", {
LayoutOrder = i, Size = UDim2.new(1, 0, 0, rh), BackgroundColor3 = T.Lift, BackgroundTransparency = base, Text = "",
AutoButtonColor = false, Active = clickable, Parent = scroll,
})
cells[i] = {}
for j, c in ipairs(cols) do
local v = row[j]
cells[i][j] = new("TextLabel", {
Position = UDim2.new(c.X, 8, 0, 0), Size = UDim2.new(c.S, -10, 1, 0), BackgroundTransparency = 1,
Text = v == nil and "" or tostring(v), Font = T.Font, TextSize = 13, TextColor3 = T.Text, TextXAlignment = LEFT,
TextTruncate = Enum.TextTruncate.AtEnd, Parent = r,
})
end
if clickable then
r.MouseEnter:Connect(function()
if usingTouch() then return end
tween(r, 0.12, { BackgroundColor3 = T.AccentSoft, BackgroundTransparency = 0.5 })
end)
r.MouseLeave:Connect(function()
tween(r, 0.14, { BackgroundColor3 = T.Lift, BackgroundTransparency = base })
end)
local press = dragSafePress(r, function() end, function() end, 12)
r.MouseButton1Click:Connect(function()
if press.moved then return end
safe(cfg.OnRowClick, data[i], i)
end)
end
rowFrames[i] = r
end
local function rebuild()
for _, r in ipairs(rowFrames) do r:Destroy() end
rowFrames, cells = {}, {}
for i = 1, #data do makeRow(i) end
empty.Visible = #data == 0
end
local function copyRows(src)
local out = {}
for _, r in ipairs(type(src) == "table" and src or {}) do
out[#out + 1] = type(r) == "table" and table.clone(r) or { r }
end
return out
end
function obj:SetRows(src) data = copyRows(src) rebuild() end
function obj:AddRow(row)
data[#data + 1] = type(row) == "table" and table.clone(row) or { row }
makeRow(#data)
empty.Visible = false
end
function obj:RemoveRow(i)
if data[i] then
table.remove(data, i)
rebuild()
end
end
function obj:SetCell(i, j, v)
if data[i] and cells[i] and cells[i][j] then
data[i][j] = v
cells[i][j].Text = v == nil and "" or tostring(v)
end
end
function obj:Clear() data = {} rebuild() end
function obj:Count() return #data end
function obj:GetRows() return copyRows(data) end
obj:SetRows(cfg.Rows)
self:_Register(frame, cfg.Name or "table", total)
obj.Frame = frame
return obj
end
function Section:CreateImage(cfg)
if type(cfg) == "number" or type(cfg) == "string" then cfg = { Image = cfg } end
cfg = cfg or {}
local T = self.Window.Theme
local imgH = tonumber(cfg.Height) or 120
local top = cfg.Name ~= nil and 20 or 0
local frame = new("Frame", { Size = UDim2.new(1, 0, 0, top + imgH), BackgroundTransparency = 1, Parent = self.Body })
if cfg.Name then caption(frame, T, cfg.Name) end
local holder = new("Frame", {
Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, 0, 0, imgH), BackgroundColor3 = T.Control, BackgroundTransparency = 0.25,
BorderSizePixel = 0, ClipsDescendants = true, Parent = frame,
}, { corner(tonumber(cfg.Corner) or 10), stroke(T.Border, 1, 0.4) })
local scaleType = ({ Fit = Enum.ScaleType.Fit, Crop = Enum.ScaleType.Crop, Stretch = Enum.ScaleType.Stretch })[cfg.Fit or "Fit"] or Enum.ScaleType.Fit
local shownImg, value = nil, cfg.Image
local function show(img)
if shownImg then shownImg:Destroy() shownImg = nil end
if type(img) == "string" and tonumber(img) then img = tonumber(img) end
if img == nil or img == "" then return end
if type(img) == "number" or (type(img) == "string" and img:find("^rbxasset")) then
shownImg = new("ImageLabel", {
Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = type(img) == "number" and ("rbxassetid://" .. img) or img,
ScaleType = scaleType, ImageColor3 = cfg.Color or Color3.new(1, 1, 1), Parent = holder,
})
elseif Library:IsIconName(img) then
local desc = Library:ResolveIcon(img)
if desc then
local sz = tonumber(cfg.IconSize) or 40
shownImg = Library:MakeIcon(desc, cfg.Color or T.Text)
shownImg.AnchorPoint = V2(0.5, 0.5)
shownImg.Position = UDim2.fromScale(0.5, 0.5)
shownImg.Size = UDim2.fromOffset(sz, sz)
shownImg.Parent = holder
end
end
end
show(value)
self:_Register(frame, cfg.Name or "image", top + imgH)
local obj = { Frame = frame }
function obj:Set(img) value = img show(img) end
function obj:Get() return value end
return obj
end
function Section:CreateStatusCard(cfg)
if type(cfg) == "string" then cfg = { Name = cfg } end
cfg = cfg or {}
local T = self.Window.Theme
local H, PAD = 64, 8
local TILE = H - PAD * 2
local accent = cfg.Color or T.Accent
local WHITE = Color3.new(1, 1, 1)
local RIGHT = Enum.TextXAlignment.Right
local ATEND = Enum.TextTruncate.AtEnd
local card = new("Frame", {
Size = UDim2.new(1, 0, 0, H), BackgroundColor3 = T.Control, BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = self.Body,
}, { new("UICorner", { CornerRadius = UDim.new(0, 8) }), stroke(T.Border, 1, 0.45) })
local tile = new("Frame", {
Position = UDim2.fromOffset(PAD, PAD), Size = UDim2.fromOffset(TILE, TILE), BackgroundColor3 = accent, BackgroundTransparency = 0.88,
BorderSizePixel = 0, ClipsDescendants = true, Parent = card,
}, { new("UICorner", { CornerRadius = UDim.new(0, 8) }), stroke(accent, 1, 0.65) })
local bx = PAD * 2 + TILE
local body = new("Frame", {
Position = UDim2.fromOffset(bx, 0), Size = UDim2.new(1, -(bx + PAD), 1, 0), BackgroundTransparency = 1, Parent = card,
})
local title = new("TextLabel", {
Position = UDim2.fromOffset(0, PAD), Size = UDim2.new(0.6, 0, 0, 18), BackgroundTransparency = 1, Text = tostring(cfg.Name or "Item"),
Font = T.FontBold, TextSize = 14, TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = ATEND, Parent = body,
})
local pill = new("TextLabel", {
AnchorPoint = V2(1, 0), Position = UDim2.new(1, 0, 0, PAD), Size = UDim2.fromOffset(0, 18), AutomaticSize = Enum.AutomaticSize.X,
BackgroundColor3 = T.SubText, BackgroundTransparency = 0.85, BorderSizePixel = 0, Text = "", Font = T.FontBold, TextSize = 13,
TextColor3 = T.SubText, Visible = false, Parent = body,
}, { new("UICorner", { CornerRadius = UDim.new(1, 0) }), new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }) })
local bars = type(cfg.Bars) == "table" and cfg.Bars or {}
local n = math.clamp(#bars, 1, 4)
local cols = new("Frame", {
Position = UDim2.fromOffset(0, PAD + 18 + 6), Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Parent = body,
}, { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })
local cells = {}
for i = 1, n do
local b = bars[i] or {}
local col = b.Color or accent
local cell = new("Frame", {
LayoutOrder = i, Size = UDim2.new(1 / n, -math.floor(8 * (n - 1) / n), 1, 0), BackgroundTransparency = 1, Parent = cols,
})
new("TextLabel", {
Size = UDim2.new(0.5, 0, 0, 14), BackgroundTransparency = 1, Text = tostring(b.Label or ""), Font = T.Font, TextSize = 13,
TextColor3 = T.SubText, TextXAlignment = LEFT, TextTruncate = ATEND, Parent = cell,
})
local val = new("TextLabel", {
AnchorPoint = V2(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0.5, 0, 0, 14), BackgroundTransparency = 1, Text = "--",
Font = T.FontBold, TextSize = 14, TextColor3 = col, TextXAlignment = RIGHT, TextTruncate = ATEND, Parent = cell,
})
local track = new("Frame", {
Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 5), BackgroundColor3 = T.Background, BackgroundTransparency = 0.2,
BorderSizePixel = 0, Parent = cell,
}, { new("UICorner", { CornerRadius = UDim.new(1, 0) }) })
local fill = new("Frame", {
Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = track,
}, { new("UICorner", { CornerRadius = UDim.new(1, 0) }), gradient(col, col:Lerp(WHITE, 0.25), 0) })
cells[i] = { val = val, fill = fill, default = col, max = tonumber(b.Max) or 100 }
end
local empty, shown, picValue = false, nil, cfg.Image
local function applyEmpty()
card.BackgroundTransparency = empty and 0.6 or 0.3
tile.BackgroundTransparency = empty and 0.94 or 0.88
title.TextColor3 = empty and T.SubText or T.Text
if shown then pcall(function() shown.ImageTransparency = empty and 0.65 or 0 end) end
end
local function showPic(img)
if shown then shown:Destroy() shown = nil end
if type(img) == "string" and tonumber(img) then img = tonumber(img) end
if img ~= nil and img ~= "" then
if type(img) == "number" or (type(img) == "string" and (img:find("^rbxasset") or img:find("^https?://"))) then
shown = new("ImageLabel", {
AnchorPoint = V2(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -8, 1, -8), BackgroundTransparency = 1,
Image = type(img) == "number" and ("rbxassetid://" .. img) or img, ScaleType = Enum.ScaleType.Fit, Parent = tile,
})
elseif Library:IsIconName(img) then
local desc = Library:ResolveIcon(img)
if desc then
local sz = tonumber(cfg.IconSize) or 26
shown = Library:MakeIcon(desc, accent)
shown.AnchorPoint = V2(0.5, 0.5)
shown.Position = UDim2.fromScale(0.5, 0.5)
shown.Size = UDim2.fromOffset(sz, sz)
shown.Parent = tile
end
end
end
applyEmpty()
end
local function setBadge(text, color)
if text == nil or text == "" then pill.Visible = false return end
color = color or T.SubText
pill.Text = tostring(text)
pill.TextColor3 = color
pill.BackgroundColor3 = color
pill.Visible = true
end
local function paintBar(i, v, text, color)
local c = cells[i]
if not c then return end
v = tonumber(v) or 0
local a = c.max > 0 and math.clamp(v / c.max, 0, 1) or 0
local col = color or c.default
c.val.Text = text ~= nil and tostring(text) or tostring(math.floor(v + 0.5))
c.val.TextColor3 = col
local g = c.fill:FindFirstChildOfClass("UIGradient")
if g then g.Color = ColorSequence.new(col, col:Lerp(WHITE, 0.25)) end
tween(c.fill, 0.25, { Size = UDim2.fromScale(a, 1) })
end
local function setEmpty(on, text)
empty = on ~= false
if empty then
setBadge(text or cfg.EmptyText or "ว่าง", T.SubText)
for i = 1, n do paintBar(i, 0, "--") end
end
applyEmpty()
end
showPic(picValue)
setBadge(cfg.Badge, cfg.BadgeColor)
for i = 1, n do
local b = bars[i] or {}
paintBar(i, b.Value or 0, b.Value == nil and "--" or b.Text, nil)
end
self:_Register(card, cfg.Name or "card", H)
local obj = { Frame = card }
function obj:SetTitle(t) title.Text = tostring(t) end
function obj:SetImage(img) picValue = img showPic(img) end
function obj:SetBadge(text, color) setBadge(text, color) end
function obj:SetBar(i, v, text, color) paintBar(i, v, text, color) end
function obj:SetEmpty(on, text) setEmpty(on, text) end
function obj:Set(t)
if type(t) ~= "table" then return end
if t.Name ~= nil then title.Text = tostring(t.Name) end
if t.Image ~= nil then picValue = t.Image showPic(t.Image) end
if t.Empty ~= nil then setEmpty(t.Empty, t.EmptyText) end
if t.Badge ~= nil then setBadge(t.Badge, t.BadgeColor) end
if type(t.Bars) == "table" then
if t.Empty == nil then empty = false applyEmpty() end
for i, b in ipairs(t.Bars) do paintBar(i, b.Value, b.Text, b.Color) end
end
end
function obj:Get() return { Name = title.Text, Image = picValue, Empty = empty, Badge = pill.Visible and pill.Text or nil } end
return obj
end
local function tabOf(win, nameOrTab)
return type(nameOrTab) == "string" and win:GetTab(nameOrTab) or nameOrTab
end
function Window:RemoveTab(nameOrTab)
local t = tabOf(self, nameOrTab)
local idx = t and table.find(self.Tabs, t)
if not idx then return false end
local wasActive = self.Active == t
if wasActive then self.Active = nil end
table.remove(self.Tabs, idx)
if self._index then
for i = #self._index, 1, -1 do
local e = self._index[i]
if e.Tab == t then
if e.Flag and Library.Objects[e.Flag] == e.Obj then Library.Objects[e.Flag] = nil end
table.remove(self._index, i)
end
end
end
pcall(function() t.Button:Destroy() end)
pcall(function() t.Page:Destroy() end)
for i, tab in ipairs(self.Tabs) do tab.Button.LayoutOrder = i end
if wasActive then
for _, o in ipairs(self.Tabs) do
if not o._locked then self:SelectTab(o) break end
end
end
return true
end
function Window:RenameTab(nameOrTab, newName)
local t = tabOf(self, nameOrTab)
if not t or type(newName) ~= "string" or newName == "" then return false end
local other = self:GetTab(newName)
if other and other ~= t then return false end
t.Name = newName
t.Label.Text = newName
pcall(t._FitLabel, t)
if self._index then
for _, e in ipairs(self._index) do
if e.Tab == t then e.TabName = newName end
end
end
return true
end
function Window:ListTabs()
local out = {}
for _, t in ipairs(self.Tabs) do out[#out + 1] = t.Name end
return out
end
function Tab:Remove() return self.Window:RemoveTab(self) end
function Tab:Rename(name) return self.Window:RenameTab(self, name) end
function Window:SetToggleKey(key)
if type(key) == "string" then
local ok, k = pcall(function() return Enum.KeyCode[key] end)
key = ok and k or nil
end
if typeof(key) ~= "EnumItem" or key.EnumType ~= Enum.KeyCode then return nil end
self.Cfg.ToggleKey = key
if self._RefreshToggleTip then self:_RefreshToggleTip() end
return key
end
function Window:GetToggleKey()
if self._ResolveToggleKey then return self._ResolveToggleKey() end
return self.Cfg.ToggleKey or Enum.KeyCode.RightShift
end
function Window:Open() self:SetVisible(true) end
function Window:Close() self:SetVisible(false) end
function Window:IsOpen() return self.Visible == true end
local decorate, NOVALUE = Library._decorate, Library._NOVALUE
if not decorate or not NOVALUE then
warn("[SpectreUI] v3.14 controls: decorate not available")
else
for _, k in ipairs({ "ButtonRow", "KeyValue", "CodeBlock", "Countdown", "Table", "Image", "StatusCard" }) do NOVALUE[k] = true end
local kinds = {
CreateButtonRow = "ButtonRow", CreateInputButton = "InputButton", CreateKeyValue = "KeyValue", CreateCodeBlock = "CodeBlock",
CreateCountdown = "Countdown", CreateListBox = "ListBox", CreateTable = "Table", CreateImage = "Image", CreateStatusCard = "StatusCard",
}
for fname, kind in pairs(kinds) do
local orig = Section[fname]
Section[fname] = function(self, cfg, ...)
local obj = orig(self, cfg, ...)
if type(obj) == "table" then
local dc = type(cfg) == "table" and cfg or (type(cfg) == "string" and { Name = cfg } or {})
local ok, err = pcall(decorate, self, kind, dc, obj)
if not ok then warn("[SpectreUI] decorate(" .. kind .. ") failed: " .. tostring(err)) end
if obj._cleanup and obj.Destroy then
local d, cl = obj.Destroy, obj._cleanup
obj.Destroy = function(s, ...) cl() return d(s, ...) end
end
end
return obj
end
end
end
Library.Version = "3.17-safe"
Library.Stage = "beta"
end
do
local TS, RS, UIS = TweenService, RunService, UserInputService
local S = { Enabled = true, Duration = 4, Skippable = false, Async = false, Backdrop = 1, Theme = false, Panel = true, Block = false,
WaitBuild = true, IdleTime = 0.8, BuildTimeout = 30,
Steps = { "Loading", "Preparing interface", "Almost ready" } }
Library.Splash = S
local EZ, ED, V2, U2 = Enum.EasingStyle, Enum.EasingDirection, Vector2.new, UDim2.new
local MONO = { Background = Color3.fromRGB(10, 10, 12), Accent = Color3.fromRGB(228, 228, 237), Accent2 = Color3.fromRGB(161, 161, 178),
Text = Color3.fromRGB(244, 244, 248), SubText = Color3.fromRGB(150, 150, 164) }
local function mk(cls, p, kids)
local i = Instance.new(cls)
for k, v in pairs(p) do if k ~= "Parent" then i[k] = v end end
for _, c in ipairs(kids or {}) do c.Parent = i end
i.Parent = p.Parent
return i
end
local function fr(p, kids) p.BorderSizePixel = 0 return mk("Frame", p, kids) end
local function lb(p, kids) p.BackgroundTransparency, p.BorderSizePixel, p.Font = 1, 0, p.Font or Enum.Font.Gotham return mk("TextLabel", p, kids) end
local function round(px) return mk("UICorner", { CornerRadius = UDim.new(0, px) }) end
local function tw(o, sec, p, st, dir)
local t = TS:Create(o, TweenInfo.new(sec, st or EZ.Quad, dir or ED.Out), p)
t:Play()
return t
end
local function play(cfg, build, ctx)
local o = type(cfg.Splash) == "table" and cfg.Splash or {}
local function opt(k) if o[k] ~= nil then return o[k] end return S[k] end
if not Library._themesLoaded then pcall(Library.LoadThemes, Library, true) end
local ov = o.Theme ~= nil and o.Theme or cfg.Theme
local base
if type(ov) == "string" then base = Library.Themes[ov] ov = nil end
if not base then
if type(ov) == "table" or Library._userSetTheme or Library._themeFromSave or not S.Theme then
base = Library.Theme
else
base = Library.Themes[S.Theme] or MONO
end
end
local function C(k, d) return (type(ov) == "table" and ov[k]) or base[k] or d end
local white = Color3.new(1, 1, 1)
local acc = C("Accent", Color3.fromRGB(139, 92, 246))
local acc2 = C("Accent2", acc)
local txt = C("Text", white)
local subc = C("SubText", Color3.fromRGB(160, 160, 180))
local bgc = C("Background", Color3.fromRGB(10, 10, 16))
local onAcc = Library.OnAccent and Library.OnAccent(acc, acc2) or white
local title = tostring(cfg.Title or "SpectreUI")
local brand, sub = title:match("^(.-)%s*|%s*(.+)$")
brand = tostring(o.Title or brand or title)
sub = (o.Subtitle or sub) and tostring(o.Subtitle or sub) or ""
local steps = opt("Steps")
if type(steps) ~= "table" or #steps == 0 then steps = { "Loading" } end
local D = math.max(3, tonumber(opt("Duration")) or 4)
local logoId = o.Logo or cfg.Logo
local cam = workspace.CurrentCamera
local vp = cam and cam.ViewportSize or V2(1280, 720)
local gui = mk("ScreenGui", { Name = "SpectreUI_Splash", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 1000, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
pcall(function() gui.ScreenInsets = Enum.ScreenInsets.None end)
Library._mount(gui)
ctx.gui = gui
local holdT = (ctx and ctx.hold) and (tonumber(opt("BuildTimeout")) or 30) or 0
task.delay(D + 12 + holdT, function() if gui.Parent then pcall(gui.Destroy, gui) end end)
local fades, movers = {}, {}
local function R(obj, prop, d, g)
local base = obj[prop]
fades[#fades + 1] = { obj = obj, prop = prop, base = base, d = d or 0, g = g, last = 2 }
obj[prop] = 1
return obj
end
local function M(obj, d)
local p = obj.Position
movers[#movers + 1] = { obj = obj, p = p, d = d or 0, last = -1 }
return obj
end
local function ease(x) x = math.clamp(x, 0, 1) return 1 - (1 - x) ^ 4 end
local lowP = lowPower()
local bg = fr({ Name = "BG", Size = U2(1, 0, 1, 0), BackgroundColor3 = bgc, BackgroundTransparency = 1, Active = opt("Block") == true, Parent = gui })
local sc0 = math.clamp(math.min(vp.X / 760, vp.Y / 520), 0.8, 1.15)
sc0 = math.floor(sc0 * 20 + 0.5) / 20
local PW, PH = 380, 292
local holder = fr({ Name = "Holder", AnchorPoint = V2(0.5, 0.5), Position = U2(0.5, 0, 0.5, 0), Size = U2(0, PW, 0, PH), BackgroundTransparency = 1, Parent = bg })
local holderScale = mk("UIScale", { Scale = sc0, Parent = holder })
local panel, panelStroke
if opt("Panel") ~= false then
panel = fr({ Name = "Panel", Size = U2(1, 0, 1, 0), BackgroundColor3 = white, BackgroundTransparency = 0.06, Active = false, ZIndex = 0, Parent = holder }, { round(24) })
mk("UIGradient", { Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, bgc:Lerp(acc, 0.20)), ColorSequenceKeypoint.new(0.5, bgc:Lerp(acc2, 0.05)),
ColorSequenceKeypoint.new(1, bgc:Lerp(Color3.new(0, 0, 0), 0.30)) }), Rotation = 90, Parent = panel })
panelStroke = mk("UIStroke", { Color = acc:Lerp(white, 0.25), Thickness = 1, Transparency = 0.45, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = panel })
mk("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.45, 0.65),
NumberSequenceKeypoint.new(1, 1) }), Parent = panelStroke })
local line = fr({ AnchorPoint = V2(0.5, 0), Position = U2(0.5, 0, 0, 0), Size = U2(0.34, 0, 0, 2), BackgroundColor3 = white, BackgroundTransparency = 0.1, Parent = panel }, { round(1) })
mk("UIGradient", { Color = ColorSequence.new(acc, acc2), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1),
NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }), Parent = line })
R(panel, "BackgroundTransparency", 0)
R(panelStroke, "Transparency", 0)
R(line, "BackgroundTransparency", 0.25)
end
local stack = fr({ Name = "Stack", AnchorPoint = V2(0.5, 0.5), Position = U2(0.5, 0, 0.5, 0), Size = U2(0, 320, 0, 224), BackgroundTransparency = 1, Parent = holder })
local function shadow() return mk("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1, Transparency = 0.6 }) end
local function T(p, d)
local l = lb(p)
local s = shadow() s.Parent = l
R(l, "TextTransparency", d) R(s, "Transparency", d)
return l
end
local CY = 56
local glow = fr({ AnchorPoint = V2(0.5, 0.5), Position = U2(0.5, 0, 0, CY), Size = U2(0, 118, 0, 118), BackgroundColor3 = acc,
BackgroundTransparency = 0.86, Parent = stack }, { mk("UICorner", { CornerRadius = UDim.new(1, 0) }) })
R(glow, "BackgroundTransparency", 0.05, "fx") M(glow, 0.05)
local function ring(size, thick, c1, c2, comet)
local r = fr({ AnchorPoint = V2(0.5, 0.5), Position = U2(0.5, 0, 0, CY), Size = U2(0, size, 0, size), BackgroundTransparency = 1, Parent = stack },
{ mk("UICorner", { CornerRadius = UDim.new(1, 0) }) })
local st = mk("UIStroke", { Color = comet and white or acc, Thickness = thick, Transparency = comet and 0 or 0.86, Parent = r })
local g
if comet then
g = mk("UIGradient", { Color = ColorSequence.new(c1, c2),
Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 1), NumberSequenceKeypoint.new(1, 1) }),
Parent = st })
end
R(st, "Transparency", 0.1, "fx") M(r, 0.1)
return g
end
ring(96, 2, acc, acc, false)
local ringA = ring(96, 2.5, acc, acc2, true)
local ringB = ring(82, 1.5, acc2, acc, true)
local logo
local logoBase = 64
if logoId then
local id = tonumber(logoId)
logo = mk("ImageLabel", { AnchorPoint = V2(0.5, 0.5), Position = U2(0.5, 0, 0, CY), Size = U2(0, logoBase, 0, logoBase), BackgroundTransparency = 1,
Image = id and ("rbxassetid://" .. id) or tostring(logoId), Parent = stack }, { round(16) })
R(logo, "ImageTransparency", 0.1)
else
local okc, ch = pcall(function() return utf8.char(utf8.codepoint(brand, 1)) end)
logo = fr({ AnchorPoint = V2(0.5, 0.5), Position = U2(0.5, 0, 0, CY), Size = U2(0, logoBase, 0, logoBase), BackgroundColor3 = white, Parent = stack }, { round(16) })
mk("UIGradient", { Color = ColorSequence.new(acc, acc2), Rotation = 45, Parent = logo })
local ls = mk("UIStroke", { Color = white, Thickness = 1, Transparency = 0.75, Parent = logo })
local lt = lb({ Size = U2(1, 0, 1, 0), Text = okc and ch:upper() or "S", Font = Enum.Font.GothamBold, TextSize = 28, TextColor3 = onAcc, Parent = logo })
R(logo, "BackgroundTransparency", 0.1) R(ls, "Transparency", 0.1) R(lt, "TextTransparency", 0.1)
end
M(logo, 0.1)
local logoScale = mk("UIScale", { Parent = logo })
local brandL = T({ Position = U2(0, 0, 0, 108), Size = U2(1, 0, 0, 28), Text = brand, Font = Enum.Font.GothamBold, TextSize = 22, TextColor3 = txt, Parent = stack }, 0.2)
M(brandL, 0.2)
if sub ~= "" then
local pill = fr({ AnchorPoint = V2(0.5, 0), Position = U2(0.5, 0, 0, 140), Size = U2(0, 0, 0, 22), AutomaticSize = Enum.AutomaticSize.X,
BackgroundColor3 = acc, BackgroundTransparency = 0.82, Parent = stack },
{ round(11), mk("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }) })
local ps = mk("UIStroke", { Color = acc, Thickness = 1, Transparency = 0.6, Parent = pill })
local pl = lb({ Size = U2(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Text = sub, TextSize = 13, Font = Enum.Font.GothamMedium, TextColor3 = txt, Parent = pill })
R(pill, "BackgroundTransparency", 0.3) R(ps, "Transparency", 0.3) R(pl, "TextTransparency", 0.3)
M(pill, 0.3)
end
local status = T({ Position = U2(0, 0, 0, 178), Size = U2(0, 236, 0, 16), Text = steps[1], TextSize = 14, TextColor3 = subc,
TextXAlignment = Enum.TextXAlignment.Left, Parent = stack }, 0.4)
local pct = T({ Position = U2(1, -56, 0, 178), Size = U2(0, 56, 0, 16), Text = "0%", TextSize = 14, TextColor3 = subc,
TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.GothamMedium, Parent = stack }, 0.4)
M(status, 0.4) M(pct, 0.4)
local track = fr({ Position = U2(0, 0, 0, 202), Size = U2(1, 0, 0, 6), BackgroundColor3 = white, BackgroundTransparency = 0.9, Parent = stack }, { round(3) })
local fill = fr({ Size = U2(0, 0, 1, 0), BackgroundColor3 = white, Parent = track }, { round(3) })
local shine = mk("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, acc), ColorSequenceKeypoint.new(0.5, acc2:Lerp(white, 0.55)),
ColorSequenceKeypoint.new(1, acc2) }), Parent = fill })
R(track, "BackgroundTransparency", 0.45) R(fill, "BackgroundTransparency", 0.45)
M(track, 0.45)
local ver = lb({ AnchorPoint = V2(0.5, 1), Position = U2(0.5, 0, 1, -18), Size = U2(0, 200, 0, 16), TextSize = 13, TextColor3 = subc,
TextTransparency = 0.6, Text = "v" .. tostring(Library.Version) .. ((type(Library.Stage) == "string" and Library.Stage ~= "") and (" " .. Library.Stage) or ""), Parent = bg })
R(ver, "TextTransparency", 0.6)
local bd = tonumber(opt("Backdrop")) or 1
if bd < 1 then R(bg, "BackgroundTransparency", 0, "bg") fades[#fades].base = bd end
local t, shown, fin, skip, done = 0, 0, false, false, false
local pcache, lastS, fcount = -1, "", 0
local t0c = os.clock()
local tExit, burstAt
local settled = false
local glowPx = 118
local stage, real, tgtMax = 1, 0, 0
local SPEED = 0.6
local function apply(now)
local tin = now - t0c
local ex = tExit and math.clamp((now - tExit) / 0.32, 0, 1) or 0
local exBg = tExit and math.clamp((now - tExit - 0.15) / 0.35, 0, 1) or 0
local fx = burstAt and math.clamp((now - burstAt) / 0.24, 0, 1) or 0
if tin >= 1.3 and not tExit and not burstAt then
if settled then return end
settled = true
else
settled = false
end
local exE = ex * ex
for i = 1, #fades do
local e = fades[i]
local v = ease((tin - e.d) / 0.55)
if e.g == "bg" then v = v * (1 - exBg) else v = v * (1 - exE) end
if e.g == "fx" then v = v * (1 - fx) end
local val = 1 - (1 - e.base) * v
if math.abs(val - e.last) > 0.002 then e.last = val e.obj[e.prop] = val end
end
for i = 1, #movers do
local m = movers[i]
local dy = math.floor((1 - ease((tin - m.d) / 0.6)) * 10 + 0.5)
if dy ~= m.last then
m.last = dy
m.obj.Position = U2(m.p.X.Scale, m.p.X.Offset, m.p.Y.Scale, m.p.Y.Offset + dy)
end
end
holderScale.Scale = sc0 * (1 + 0.07 * exE)
holder.Position = U2(0.5, 0, 0.5, math.floor(-6 * exE + 0.5))
end
local function step(dt)
t = t + dt
local now = os.clock()
local ph = now - t0c
if skip and not fin then t = math.max(t, D) end
local k = math.clamp(t / D, 0, 1)
local target
if fin then target = 1
elseif stage == 1 then target = 0.55 * (k * k * (3 - 2 * k))
else target = 0.55 + 0.42 * math.clamp(real, 0, 1) end
tgtMax = math.max(tgtMax, target)
local move = (tgtMax - shown) * math.min(1, dt * (skip and 12 or 4))
move = math.min(move, (skip and 3 or SPEED) * dt)
if not fin and move < 0.0008 * dt * 60 and shown < tgtMax then move = math.min(tgtMax - shown, 0.0008 * dt * 60) end
shown = math.min(1, shown + move)
fill.Size = U2(shown, 0, 1, 0)
fcount = fcount + 1
if not lowP or fcount % 2 == 0 then
ringA.Rotation = (ph * 230) % 360
ringB.Rotation = (-ph * 140) % 360
end
if not done then
local pl = math.sin(ph * 3)
logoScale.Scale = 1 + 0.035 * pl
if not lowP then
local gs = 118 + math.floor(8 * pl + 0.5)
if gs ~= glowPx then glowPx = gs glow.Size = U2(0, gs, 0, gs) end
end
elseif burstAt then
logoScale.Scale = 1 + 0.12 * math.sin(math.pi * math.clamp((now - burstAt) / 0.4, 0, 1))
end
if not lowP then shine.Offset = V2((ph * 0.9) % 1 * 2 - 1, 0) end
local pc = math.floor(shown * 100 + 0.5)
if pc ~= pcache then pcache = pc pct.Text = pc .. "%" end
local s
if fin and shown > 0.97 then s = "Ready"
else s = steps[math.clamp(math.floor(shown / 0.97 * #steps) + 1, 1, #steps)] .. string.rep(".", math.floor(ph * 2.5) % 4) end
if s ~= lastS then lastS = s status.Text = s end
apply(now)
end
local function frameStep() local dt = math.min(RS.Heartbeat:Wait(), 0.1) step(dt) return dt end
local function burst()
done = true
burstAt = os.clock()
end
local function exit()
tExit = os.clock()
end
while t < D do frameStep() end
local e = 0
while e < 0.2 do e = e + frameStep() end
stage = 2
if build then build() end
if ctx and ctx.hold and ctx.win then
local win = ctx.win
local t0, last = os.clock(), os.clock()
local conn, loadedAt
if win.Gui then conn = win.Gui.DescendantAdded:Connect(function() last = os.clock() end) end
local idle = tonumber(opt("IdleTime")) or 0.8
local limit = tonumber(opt("BuildTimeout")) or 30
while not ctx.released and not win._destroyed and win.Gui and win.Gui.Parent do
local now = os.clock()
if win._slLoaded == true then loadedAt = loadedAt or now else loadedAt = nil end
if (win._loadHolds or 0) <= 0 and (now - last >= idle or (loadedAt and now - loadedAt >= 0.4)) then break end
if now - t0 >= limit then break end
local nT, okT = #win.Tabs, 0
for _, tb in ipairs(win.Tabs) do if tb._slLoaded ~= false then okT = okT + 1 end end
local tabsP = win._slLoaded == true and 1 or (nT > 0 and okT / nT or 0)
local quietP = math.clamp((now - last) / idle, 0, 1)
real = math.max(real, 0.5 * tabsP + 0.5 * quietP)
local dtH = frameStep()
real = math.min(0.95, real + 0.015 * dtH)
if real > 0.95 then real = 0.95 end
end
if conn then conn:Disconnect() end
end
fin = true
e = 0
while shown < 0.995 and e < 1.5 do e = e + frameStep() end
e = 0
burst()
e = 0
while e < 0.3 do e = e + frameStep() end
if ctx and ctx.onExit then pcall(ctx.onExit) end
task.spawn(function()
pcall(function()
exit()
local x = 0
while x < 0.6 do x = x + frameStep() end
end)
gui:Destroy()
end)
end
local orig = Library.CreateWindow
local function traceback(e) return debug.traceback(tostring(e), 2) end
function Window:HoldLoading() self._loadHolds = (self._loadHolds or 0) + 1 end
function Window:ReleaseLoading() self._loadHolds = math.max(0, (self._loadHolds or 0) - 1) end
function Window:FinishLoading() local c = self._splashCtx if c then c.released = true end end
function Library:CreateWindow(cfg)
cfg = cfg or {}
cfg.Splash = type(cfg.Splash) == "table" and cfg.Splash or {}
local o = cfg.Splash
local async = o.Async
if async == nil then async = S.Async end
local hold = o.WaitBuild
if hold == nil then hold = S.WaitBuild end
local ctx, w = {}, nil
if hold then
ctx.hold = true
local function reveal()
if not w then return end
w._loadHeld = nil
if w._introHeld then
w._introHeld = nil
pcall(function() w.Gui.Enabled = true end)
pcall(function() w:_PlayIntro() end)
else
pcall(function() w.Gui.Enabled = true end)
end
end
ctx.onExit = reveal
local function buildHeld()
if ctx.abandoned then return end
ctx.built = true
Library._holdIntro = true
local okb, res = pcall(orig, self, cfg)
Library._holdIntro = nil
if not okb then error(res, 0) end
w = res
ctx.win = w
w._splashCtx = ctx
w._loadHeld = true
pcall(function()
w.Gui:GetPropertyChangedSignal("Enabled"):Connect(function()
if w._loadHeld and w.Gui.Enabled then w.Gui.Enabled = false end
end)
end)
pcall(function() w.Gui.Enabled = false end)
end
local failed = false
local function run(build)
local ok, err = xpcall(play, traceback, cfg, build, ctx)
if not ok then
warn("[SpectreUI] splash error: " .. tostring(err))
if ctx.gui then ctx.gui:Destroy() end
failed = true
pcall(ctx.onExit)
end
end
if async then
local okb, err = pcall(buildHeld)
if not okb then error(err, 0) end
task.spawn(run, nil)
return w
end
task.spawn(run, buildHeld)
local tw0 = os.clock()
while not w and not failed and os.clock() - tw0 < 20 do task.wait() end
if not w then
ctx.abandoned = true
if ctx.gui then pcall(function() ctx.gui:Destroy() end) end
w = orig(self, cfg)
end
return w
end
if async then
w = orig(self, cfg)
task.spawn(function()
local ok, err = xpcall(play, function(e) return debug.traceback(tostring(e), 2) end, cfg, nil, ctx)
if not ok then warn("[SpectreUI] splash error: " .. tostring(err)) if ctx.gui then ctx.gui:Destroy() end end
end)
return w
end
local ok, err = xpcall(play, function(e) return debug.traceback(tostring(e), 2) end, cfg, function()
ctx.built = true
Library._holdIntro = true
local okb, res = pcall(orig, self, cfg)
Library._holdIntro = nil
if not okb then error(res, 0) end
w = res
end, ctx)
if not ok then
warn("[SpectreUI] splash error: " .. tostring(err))
if ctx.gui then ctx.gui:Destroy() end
if ctx.built and not w then error(err, 0) end
end
if not w then w = orig(self, cfg) end
if w and w._introHeld then
w._introHeld = nil
pcall(function() w.Gui.Enabled = true end)
pcall(function() w:_PlayIntro() end)
end
return w
end
end
do
local S = {
Enabled = true, Auto = true, TabDelay = lowPower() and 0.05 or 0.12, BuildDelay = 0.05, Loading = true, Placeholder = true,
Title = "Loading", TabsText = "Loading tabs", BuildText = "Loading features",
}
Library.StagedLoad = S
local function get(win, key)
local c = win.Cfg and win.Cfg.StagedLoad
if type(c) == "table" and c[key] ~= nil then return c[key] end
return S[key]
end
local function enabled(win)
local c = win.Cfg and win.Cfg.StagedLoad
return not (c == false or S.Enabled == false)
end
local function alive(win) return not win._destroyed end
local function state(win)
local q = win._sl
if not q then
q = { tabs = {}, cbs = {}, running = false, scheduled = false }
win._sl = q
end
return q
end
local function runFn(fn, tab, slice)
local win = tab.Window
if slice and win then win._slThread, win._sliceT = coroutine.running(), os.clock() end
local ok, err = pcall(fn, tab)
if slice and win then win._slThread = nil end
if not ok and win and win._destroyed then return false end
if not ok then warn("[SpectreUI] tab '" .. tostring(tab.Name) .. "' load error: " .. tostring(err)) end
return ok
end
local function reveal(tab)
local btn = tab.Button
if not btn or not btn.Parent then return end
btn.Visible = true
if lowPower() then return end
local lbl, sc = tab.Label, tab.IconScale
if lbl then
lbl.TextTransparency = 1
tween(lbl, 0.3, { TextTransparency = (tab._locked or tab._slLoaded == false) and 0.55 or 0 })
end
if sc then
sc.Scale = 0
tween(sc, 0.4, { Scale = 1 }, BACK, OUT)
end
end
local function finishTab(tab)
tab._slLoaded = true
if tab.Label and tab.Label.Parent then tween(tab.Label, 0.25, { TextTransparency = tab._locked and 0.55 or 0 }) end
local h = tab._slHold
tab._slHold = nil
if h then pcall(function() h:Destroy() end) end
end
local function cycle(win, q)
local load
if get(win, "Loading") then
local ok, h = pcall(function()
return win:Loading({ Title = get(win, "Title"), Text = get(win, "TabsText"), Progress = 0 })
end)
if ok then load = h end
end
q.load = load
if q.conns then for _, c in ipairs(q.conns) do c:Disconnect() end end
local function mark(i)
local t = i.UserInputType
if t == Enum.UserInputType.Touch or t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.MouseWheel then
win._lastTouch = os.clock()
end
end
q.conns = {
UserInputService.InputBegan:Connect(mark),
UserInputService.InputChanged:Connect(function(i)
if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseWheel then win._lastTouch = os.clock() end
end),
UserInputService.InputEnded:Connect(mark),
}
local function prog(f, text)
if load then pcall(function() load:Set(f, text) end) end
end
while #q.tabs > 0 and alive(win) do
local batch, shown = {}, 0
while #q.tabs > 0 and alive(win) do
local tab = table.remove(q.tabs, 1)
if tab.Button and tab.Button.Parent then
reveal(tab)
table.insert(batch, tab)
shown = shown + 1
prog(0.5 * shown / (shown + #q.tabs), get(win, "TabsText") .. ": " .. tostring(tab.Name))
task.wait(get(win, "TabDelay"))
end
end
local done = 0
local function pending()
local n = 0
for _, t in ipairs(batch) do n = n + #t._slBuilds end
return n
end
local function nextTab()
for _, t in ipairs(batch) do
if t._slLoaded == false then return t end
end
end
while alive(win) do
local tab = nextTab()
if not tab then break end
if #tab._slBuilds > 0 then
local fn = table.remove(tab._slBuilds, 1)
prog(0.5 + 0.5 * done / (done + pending() + 1), get(win, "BuildText") .. ": " .. tostring(tab.Name))
runFn(fn, tab, true)
done = done + 1
task.wait(get(win, "BuildDelay"))
else
finishTab(tab)
end
end
end
if load and alive(win) then pcall(function() load:Complete("Ready", 1) end) end
end
local run
run = function(win)
local q = state(win)
if q.running or not alive(win) then return end
q.running = true
local ok, err = xpcall(cycle, function(e) return debug.traceback(tostring(e), 2) end, win, q)
q.running = false
if q.conns then for _, c in ipairs(q.conns) do c:Disconnect() end q.conns = nil end
if not ok then
warn("[SpectreUI] staged load error: " .. tostring(err))
if q.load then pcall(function() q.load:Fail("Load error", 2) end) end
table.clear(q.tabs)
for _, t in ipairs(win.Tabs) do
if t._slLoaded == false then
if t.Button then t.Button.Visible = true end
finishTab(t)
end
end
end
if not alive(win) then return end
if ok and #q.tabs > 0 then return run(win) end
win._slLoaded = true
if win._slCheckWanted and win._QueueCheck then
win._slCheckWanted = false
win:_QueueCheck(1.0)
end
local cbs = q.cbs
q.cbs = {}
for _, f in ipairs(cbs) do safe(f, win) end
end
local function schedule(win)
local q = state(win)
if q.running or q.scheduled or not get(win, "Auto") then return end
q.scheduled = true
task.defer(function()
q.scheduled = false
run(win)
end)
end
local origQueueCheck = Window._QueueCheck
if origQueueCheck then
function Window:_QueueCheck(delay)
if self._slLoaded == false then
self._slCheckWanted = true
return
end
return origQueueCheck(self, delay)
end
end
local origSelectTab = Window.SelectTab
function Window:SelectTab(tab)
if type(tab) == "table" and tab._slLoaded == false then return end
return origSelectTab(self, tab)
end
local origCreateTab = Window.CreateTab
function Window:CreateTab(cfg, build)
local tab = origCreateTab(self, cfg)
if not tab or not enabled(self) then
if tab and type(build) == "function" then runFn(build, tab) end
return tab
end
local c = type(cfg) == "table" and cfg or {}
tab._slBuilds = {}
tab._slLoaded = false
if tab.Label then tab.Label.TextTransparency = 0.55 end
local fn = build or c.Build or c.Load
if type(fn) == "function" then table.insert(tab._slBuilds, fn) end
if tab.Button then tab.Button.Visible = false end
if get(self, "Placeholder") and tab.Page then
local T = self.Theme
local ok, h = pcall(function()
return Instance.new("TextLabel")
end)
if ok and h then
h.Name = "LoadingHint"
h.AnchorPoint = Vector2.new(0.5, 0.5)
h.Position = UDim2.fromScale(0.5, 0.5)
h.Size = UDim2.new(1, -32, 0, 30)
h.BackgroundTransparency = 1
h.Text = "Loading..."
h.Font = T.Font
h.TextSize = 14
h.TextColor3 = T.SubText
h.Parent = tab.Page
tab._slHold = h
end
end
table.insert(state(self).tabs, tab)
self._slLoaded = false
self._slCheckWanted = true
self._checkSeq = (self._checkSeq or 0) + 1
schedule(self)
return tab
end
function Tab:Load(fn)
if type(fn) ~= "function" then return self end
if self._slBuilds == nil or self._slLoaded then
runFn(fn, self)
else
table.insert(self._slBuilds, fn)
end
return self
end
Tab.Build = Tab.Load
function Window:StartLoad()
task.spawn(run, self)
return self
end
function Window:IsLoaded() return self._slLoaded ~= false end
function Window:OnLoaded(fn)
if type(fn) ~= "function" then return self end
if self._slLoaded ~= false then
safe(fn, self)
else
table.insert(state(self).cbs, fn)
end
return self
end
function Window:WaitLoaded(timeout)
local t0, limit = os.clock(), tonumber(timeout) or 60
while self._slLoaded == false and alive(self) and os.clock() - t0 < limit do task.wait() end
return self
end
end
do
local TS = TweenService
local UIS = UserInputService
local RS = RunService
local A = Library.Anim
local EQUAD, EBACK, ESINE = Enum.EasingStyle.Quad, Enum.EasingStyle.Back, Enum.EasingStyle.Sine
local EOUT = Enum.EasingDirection.Out
if A.Plus == nil then A.Plus = true end
if A.Cascade == nil then A.Cascade = true end
if A.CascadeStep == nil then A.CascadeStep = 0.03 end
if A.CascadeMax == nil then A.CascadeMax = 5 end
if A.CascadeLow == nil then A.CascadeLow = false end
if A.ToggleStretch == nil then A.ToggleStretch = true end
local function lite() return false end
local function go(o, t, props, style, dir, delay)
t = math.max(t * (A.Speed or 1), 0.06)
local tw = TS:Create(o, TweenInfo.new(t, style or ESINE, dir or EOUT, 0, false, (delay or 0) * (A.Speed or 1)), props)
tw:Play()
return tw
end
local origToggle = Section.CreateToggle
function Section:CreateToggle(cfg)
local obj = origToggle(self, cfg)
if type(obj) ~= "table" or typeof(obj.Frame) ~= "Instance" or type(obj.Set) ~= "function" then return obj end
pcall(function()
local row = obj.Frame
local track
for _, c in ipairs(row:GetChildren()) do
if c:IsA("Frame") then track = c break end
end
if not track then return end
local knob
for _, c in ipairs(track:GetChildren()) do
if c:IsA("Frame") and c.ZIndex == 2 then knob = c break end
end
if not knob then return end
local baseSize = knob.Size
local seq = 0
local function jelly()
seq += 1
local my = seq
go(knob, 0.09, { Size = UDim2.fromOffset(baseSize.X.Offset + 4, baseSize.Y.Offset - 2) }, EQUAD, EOUT)
task.delay(0.09 * (A.Speed or 1), function()
if my ~= seq or not knob.Parent then return end
go(knob, 0.26, { Size = baseSize }, EBACK, EOUT)
end)
end
local rawSet = obj.Set
function obj:Set(v, silent)
local before = obj:Get()
rawSet(self, v, silent)
if A.Plus and A.ToggleStretch and ((v and true or false) ~= before) and knob.Parent then
jelly()
end
end
end)
return obj
end
local inflight = setmetatable({}, { __mode = "k" })
function Window:PlayCascade(tab)
tab = tab or self.Active
if not A.Plus or not A.Cascade or not tab or self._destroyed then return end
if lite() and A.CascadeLow ~= true then return end
local win = self
task.spawn(function()
RS.RenderStepped:Wait()
if win._destroyed or win.Active ~= tab or not tab.Page or not tab.Page.Visible then return end
local cards = {}
for _, s in ipairs(tab.Sections or {}) do
local f = s.Frame
if f and f.Parent and f.Visible then table.insert(cards, f) end
end
table.sort(cards, function(a, b)
local ay, by = a.AbsolutePosition.Y, b.AbsolutePosition.Y
if math.abs(ay - by) > 4 then return ay < by end
return a.AbsolutePosition.X < b.AbsolutePosition.X
end)
local step = A.CascadeStep or 0.045
for i = 1, math.min(#cards, A.CascadeMax or 8) do
local f = cards[i]
local st = f:FindFirstChildOfClass("UIStroke")
local rest = inflight[f]
if not rest then
rest = { bg = f.BackgroundTransparency, stroke = st and st.Transparency or nil }
inflight[f] = rest
end
local delay = (i - 1) * step
f.BackgroundTransparency = 1
if st and rest.stroke then st.Transparency = 1 end
local t1 = go(f, 0.34, { BackgroundTransparency = rest.bg }, ESINE, EOUT, delay)
if st and rest.stroke then go(st, 0.34, { Transparency = rest.stroke }, ESINE, EOUT, delay) end
t1.Completed:Connect(function(state)
if state == Enum.PlaybackState.Completed and inflight[f] == rest then inflight[f] = nil end
end)
end
end)
end
local origSelect = Window.SelectTab
function Window:SelectTab(tab)
local prev = self.Active
origSelect(self, tab)
if prev and prev ~= tab and self.Active == tab then
pcall(self.PlayCascade, self, tab)
end
end
local origSettings = Window.CreateSettingsTab
function Window:CreateSettingsTab(cfg)
local parts = origSettings(self, cfg)
cfg = cfg or {}
local S = cfg.Sections or {}
if S.Animation == false or type(parts) ~= "table" or not parts.Tab or parts.AnimationSection then return parts end
pcall(function()
local P = cfg.FlagPrefix or "ui_"
local sec = parts.Tab:CreateSection({ Name = "Animation", Column = 2 })
parts.AnimationSection = sec
local PRESETS = { Snappy = 0.8, Normal = 1, Soft = 1.25 }
local current = "Normal"
for name, v in pairs(PRESETS) do
if math.abs((A.Speed or 1) - v) < 0.01 then current = name end
end
parts.AnimSpeed = sec:CreateSegmented({
Name = "Speed", Options = { "Snappy", "Normal", "Soft" }, Default = current, Flag = P .. "anim_speed",
Callback = function(v) if PRESETS[v] then A.Speed = PRESETS[v] end end,
})
parts.AnimCascade = sec:CreateToggle({
Name = "Card cascade on tab change", Default = A.Cascade == true, Flag = P .. "anim_cascade",
Callback = function(v) A.Cascade = v and true or false end,
})
parts.AnimJelly = sec:CreateToggle({
Name = "Toggle jelly", Default = A.ToggleStretch == true, Flag = P .. "anim_jelly",
Callback = function(v) A.ToggleStretch = v and true or false end,
})
end)
return parts
end
end
do
local function attach(win)
if type(win) ~= "table" or win._kbAvoid then return end
if win.Cfg and win.Cfg.KeyboardAvoid == false then return end
local main, gui = win.Main, win.Gui
if not main or not gui then return end
win._kbAvoid = true
local base, liftPos, lifted, seq = nil, nil, 0, 0
local function info(t) return TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out) end
local function keyboardTop(vp)
local okV, visible = pcall(function() return UserInputService.OnScreenKeyboardVisible end)
local okP, pos = pcall(function() return UserInputService.OnScreenKeyboardPosition end)
local okS, size = pcall(function() return UserInputService.OnScreenKeyboardSize end)
if okV and visible and okP and okS and typeof(pos) == "Vector2" and typeof(size) == "Vector2" and size.Y > 40 then
return pos.Y
end
if UserInputService.KeyboardEnabled then return nil end
return vp.Y * 0.55
end
local function restore()
seq += 1
if lifted == 0 or not base then return end
local target, from, to = base, liftPos, nil
lifted, base, liftPos = 0, nil, nil
if win._destroyed or not main.Parent or not from then return end
local cur = main.Position
local lo, hi = math.min(from.Y.Offset, target.Y.Offset) - 1, math.max(from.Y.Offset, target.Y.Offset) + 1
if cur.X == target.X and cur.Y.Scale == target.Y.Scale and cur.Y.Offset >= lo and cur.Y.Offset <= hi then
TweenService:Create(main, info(), { Position = target }):Play()
end
end
local function lift(box)
seq += 1
local my = seq
task.delay(0.28, function()
if my ~= seq or win._destroyed or not main.Parent or not main.Visible then return end
if not box.Parent or not box:IsDescendantOf(main) then return end
local top = keyboardTop(gui.AbsoluteSize)
if not top then return end
local need = (box.AbsolutePosition.Y + box.AbsoluteSize.Y + 14) - top
if need <= 0 then return end
local room = box.AbsolutePosition.Y - 8
local dy = math.floor(math.min(need, math.max(room, 0)))
if dy < 1 then return end
local cur = main.Position
if lifted == 0 then base = cur end
local target = UDim2.new(cur.X.Scale, cur.X.Offset, cur.Y.Scale, cur.Y.Offset - dy)
lifted += dy
liftPos = target
TweenService:Create(main, info(), { Position = target }):Play()
end)
end
table.insert(win.Conns, UserInputService.TextBoxFocused:Connect(function(box)
if box then lift(box) end
end))
table.insert(win.Conns, UserInputService.TextBoxFocusReleased:Connect(function()
seq += 1
local my = seq
task.delay(0.12, function()
if my ~= seq or win._destroyed then return end
restore()
end)
end))
end
if false then
local prevCreate = Library.CreateWindow
function Library:CreateWindow(cfg)
local win = prevCreate(self, cfg)
if type(win) == "table" then pcall(attach, win) end
return win
end
end
end
Library._tabLockV2 = (function()
local K = {}
local function LC(T) return Library.LockColor or T.SubText end
local function pickable(win, skip)
for _, t in ipairs(win.Tabs) do
if t ~= skip and not t._locked and t._slLoaded ~= false and t.Page and t.Page.Parent then return t end
end
end
local function ensureCover(win)
local c = win._lockCover
if c and c.Parent then return c end
local T = win.Theme
c = new("Frame", {
Name = "LockCover", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 18, Parent = win.Pages,
}, {
new("Frame", {
Name = "Padlock", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, -52),
Size = UDim2.fromOffset(46, 46), BackgroundTransparency = 1, ZIndex = 19,
}, {
new("Frame", {
AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.fromOffset(26, 30),
BackgroundTransparency = 1, ZIndex = 19,
}, { corner(13), stroke(LC(T), 3, 0.15) }),
new("Frame", {
AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.fromOffset(42, 26),
BackgroundColor3 = LC(T), BorderSizePixel = 0, ZIndex = 20,
}, { corner(8) }),
}),
new("TextLabel", {
Name = "Title", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, -16), Size = UDim2.new(1, -32, 0, 26),
BackgroundTransparency = 1, Text = "LOCKED", Font = T.FontBold, TextSize = 18, TextColor3 = T.Text, ZIndex = 19,
}),
new("TextLabel", {
Name = "Sub", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, 12), Size = UDim2.new(1, -32, 0, 20),
BackgroundTransparency = 1, Text = "", Font = T.Font, TextSize = 14, TextColor3 = T.Text, ZIndex = 19,
}),
new("TextLabel", {
Name = "Reason", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, 34), Size = UDim2.new(1, -48, 0, 44),
BackgroundTransparency = 1, Text = "", Font = T.Font, TextSize = 14, TextColor3 = T.SubText,
TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 19,
}),
})
win._lockCover = c
return c
end
local function syncCover(win)
if win._destroyed or not win.Pages or not win.Pages.Parent then return end
local cover = win._lockCover
if win.Active then
if cover and cover.Visible then cover.Visible = false end
return
end
local focus = win._lockFocus
if not (focus and focus._locked and focus.Button and focus.Button.Parent) then
focus = nil
for _, t in ipairs(win.Tabs) do
if t._locked then focus = t break end
end
end
if not focus then
if cover and cover.Visible then cover.Visible = false end
return
end
cover = ensureCover(win)
cover.Sub.Text = tostring(focus.Name) .. " is locked"
cover.Reason.Text = focus.LockReason or "This tab is locked."
cover.Visible = true
end
local startPicker
local function leave(win, tab)
local t = pickable(win, tab)
if t then win:SelectTab(t) end
if win.Active == tab then
if tab.Page then tab.Page.Visible = false end
tab:_SetSelected(false)
win.Active = nil
startPicker(win)
end
end
startPicker = function(win)
if win._lockPicker then return end
win._lockPicker = true
task.spawn(function()
while not win._destroyed and not win.Active do
local t = pickable(win)
if t then win:SelectTab(t) break end
if win._slLoaded ~= false then break end
task.wait(0.2)
end
win._lockPicker = nil
syncCover(win)
end)
end
local function parts(tab)
local p = tab._lockParts
if p then return p end
local T, btn = tab.Window.Theme, tab.Button
p = {}
p.Shade = new("Frame", {
Name = "LockShade", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Background:Lerp(T.Text, 0.04),
BackgroundTransparency = 0.45, BorderSizePixel = 0, Visible = false, ZIndex = 2, Parent = btn,
}, { corner(10) })
p.Stroke = new("UIStroke", {
Color = T.Text, Thickness = 1, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = p.Shade,
})
p.Bar = new("Frame", {
Name = "LockBar", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0), Size = UDim2.new(0, 3, 0.5, 0),
BackgroundColor3 = T.SubText, BorderSizePixel = 0, Visible = false, ZIndex = 3, Parent = btn,
}, { corner(3) })
p.Pill = new("TextLabel", {
Name = "LockPill", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -32, 0.5, 0), Size = UDim2.fromOffset(50, 16),
BackgroundColor3 = T.Text, BackgroundTransparency = 0.92, Text = "LOCKED", Font = T.FontBold, TextSize = 9,
TextColor3 = T.SubText, Visible = false, ZIndex = 3, Parent = btn,
}, { corner(8) })
btn:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() K.pill(tab) end)
tab._lockParts = p
return p
end
function K.pill(tab)
local p = tab._lockParts
if not p or not tab.Button or not tab.Button.Parent then return end
local win = tab.Window
local sc = (win.Scale and win.Scale.Scale) or 1
local w = tab.Button.AbsoluteSize.X / math.max(sc, 0.01)
local lbl = tab.Label
local need = (tab._lblX or 46) + Tab._textW(lbl.Text, lbl.TextSize, lbl.Font) + 8 + 50 + 34
local show = tab._locked == true and lbl.Visible and w >= need
if p.Pill.Visible ~= show then p.Pill.Visible = show end
end
local function applyVisual(tab, v)
local p = parts(tab)
local T = tab.Window.Theme
p.Shade.Visible = v
p.Bar.Visible = false
tab.LockIcon.Visible = v
for _, c in ipairs(tab.LockIcon:GetChildren()) do
local st = c:FindFirstChildOfClass("UIStroke")
if st then st.Color = LC(T) end
if c.BackgroundTransparency < 1 then c.BackgroundColor3 = LC(T) end
end
local dim = (v or tab._slLoaded == false) and 0.55 or 0
tween(tab.Label, 0.2, { TextTransparency = dim })
local prop = tab.Icon:IsA("ImageLabel") and "ImageTransparency" or "TextTransparency"
tween(tab.Icon, 0.2, { [prop] = dim })
for _, part in ipairs(tab.Icon:GetChildren()) do
if part:IsA("ImageLabel") then tween(part, 0.2, { ImageTransparency = dim }) end
end
tab:_FitLabel()
K.pill(tab)
end
function Tab:SetLocked(v, reason)
v = v and true or false
if reason ~= nil then self.LockReason = reason end
local win = self.Window
self._locked = v
applyVisual(self, v)
if v then
win._lockFocus = self
if win.Active == self then
leave(win, self)
elseif self.Page then
self.Page.Visible = false
end
else
if win._lockFocus == self then win._lockFocus = nil end
if not win.Active then
if self._slLoaded ~= false then win:SelectTab(self) else startPicker(win) end
end
end
syncCover(win)
return self
end
function Tab:SetLockReason(text)
self.LockReason = text
syncCover(self.Window)
return self
end
local prevSelect = Window.SelectTab
function Window:SelectTab(tab)
if type(tab) == "table" and tab._locked then
self:_LockedFeedback(tab)
return
end
local r = table.pack(prevSelect(self, tab))
local a = self.Active
if a and a._locked then leave(self, a) end
syncCover(self)
return table.unpack(r, 1, r.n)
end
local prevFeedback = Window._LockedFeedback
function Window:_LockedFeedback(tab)
local p = tab._lockParts
if p and p.Stroke and p.Stroke.Parent then
p.Stroke.Transparency = 0.6
tween(p.Stroke, 0.6, { Transparency = 1 })
end
self._lockFocus = tab
prevFeedback(self, tab)
syncCover(self)
end
K.Sync = syncCover
return K
end)()
;(function()
local TOP, SW = 58, 40
local CURATED = { "Clean", "Nova", "Rose", "Violet", "Cyber", "Crimson", "Matrix", "Midnight", "Ocean", "Sunset", "Aurora", "Dracula", "Nord", "TokyoNight", "Mocha", "Synthwave", "Mono", "Minimal" }
local function glyph(parent, name, fallback, size, color)
local d = Library:IsIconName(name) and Library:ResolveIcon(name) or nil
local o
if d then
o = Library:MakeIcon(d, color)
o.Size = UDim2.fromOffset(size, size)
else
o = new("TextLabel", {
Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, Text = fallback,
Font = Enum.Font.GothamBold, TextSize = size, TextColor3 = color,
})
end
o.AnchorPoint = Vector2.new(0.5, 0.5)
o.Position = UDim2.fromScale(0.5, 0.5)
o.Parent = parent
return o
end
local function recolor(o, c)
if o:IsA("ImageLabel") then o.ImageColor3 = c else o.TextColor3 = c end
end
local function swatch(parent, th, size, x)
return new("Frame", {
AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, x, 0.5, 0), Size = UDim2.fromOffset(size, size),
BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 62, Parent = parent,
}, {
new("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
new("UIGradient", { Rotation = 45, Color = ColorSequence.new(th.Accent, th.Accent2 or th.Accent) }),
})
end
local function addRipple(btn, win)
if not btn or btn:FindFirstChild("UXRipple") then return end
local rc = btn:FindFirstChildOfClass("UICorner")
local layer = new("Frame", {
Name = "UXRipple", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
ClipsDescendants = true, Active = false, ZIndex = btn.ZIndex + 1, Parent = btn,
})
if rc then new("UICorner", { CornerRadius = rc.CornerRadius, Parent = layer }) end
btn.InputBegan:Connect(function(i)
if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
if Library.Perf and Library.Perf.Ripple == false then return end
local sc = (win.Scale and win.Scale.Scale) or 1
if sc <= 0.01 then sc = 1 end
local ap, as = layer.AbsolutePosition, layer.AbsoluteSize
if as.X <= 0 or as.Y <= 0 then return end
local px = math.clamp((i.Position.X - ap.X) / sc, 0, as.X / sc)
local py = math.clamp((i.Position.Y - ap.Y) / sc, 0, as.Y / sc)
local d = math.max(as.X, as.Y) / sc * 2.2
local dot = new("Frame", {
AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(px, py), Size = UDim2.fromOffset(0, 0),
BackgroundColor3 = win.Theme.Accent, BackgroundTransparency = 0.7, BorderSizePixel = 0, Active = false, Parent = layer,
}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
tween(dot, 0.5, { Size = UDim2.fromOffset(d, d), BackgroundTransparency = 1 })
task.delay(0.55, function() if dot.Parent then dot:Destroy() end end)
end)
end
local function build(win)
local T, side = win.Theme, win.Sidebar
if not (side and win.TabList and win.Pages and win.Main) then return end
local bar = new("Frame", { Name = "UXBar", Position = UDim2.fromOffset(10, 12), Size = UDim2.new(1, -19, 0, 36), BackgroundTransparency = 1, Parent = side })
local crumb = new("TextLabel", {
Name = "UXCrumb", Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -52, 1, 0), BackgroundTransparency = 1, Text = "",
Font = T.FontBold, TextSize = 12, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Left,
TextTruncate = Enum.TextTruncate.AtEnd, Parent = bar,
})
local cbtn = new("TextButton", {
Name = "Collapse", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 0), Size = UDim2.fromOffset(34, 34),
BackgroundColor3 = T.Background, BackgroundTransparency = 0.35, Text = "", AutoButtonColor = false, BorderSizePixel = 0, Parent = bar,
}, {
new("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
new("UIStroke", { Color = T.Border, Thickness = 1, Transparency = 0.35, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
})
addRipple(cbtn, win)
local icClose = glyph(cbtn, "lucide:panel-left-close", "<", 18, T.SubText)
local icOpen = glyph(cbtn, "lucide:panel-left-open", ">", 18, T.SubText)
icOpen.Visible = false
cbtn.MouseEnter:Connect(function()
tween(cbtn, 0.12, { BackgroundTransparency = 0.1 })
recolor(icClose, win.Theme.Accent) recolor(icOpen, win.Theme.Accent)
end)
cbtn.MouseLeave:Connect(function()
tween(cbtn, 0.14, { BackgroundTransparency = 0.35 })
recolor(icClose, win.Theme.SubText) recolor(icOpen, win.Theme.SubText)
end)
local chip = new("TextButton", {
Name = "UXTheme", BackgroundColor3 = T.Control, BackgroundTransparency = 0.55, Text = "", AutoButtonColor = false,
BorderSizePixel = 0, Parent = side,
}, {
new("UICorner", { CornerRadius = UDim.new(0, 10) }),
new("UIStroke", { Color = T.Border, Thickness = 1, Transparency = 0.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
})
addRipple(chip, win)
local chipSw = new("Frame", {
AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(18, 18),
BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = chip,
}, {
new("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
new("UIGradient", { Rotation = 45, Color = ColorSequence.new(T.Accent, T.Accent2) }),
})
local chipLbl = new("TextLabel", {
Position = UDim2.fromOffset(36, 0), Size = UDim2.new(1, -62, 1, 0), BackgroundTransparency = 1, Text = "Theme",
Font = T.Font, TextSize = 14, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left,
TextTruncate = Enum.TextTruncate.AtEnd, Parent = chip,
})
local chipChev = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1, Parent = chip })
local chevIco = glyph(chipChev, "lucide:chevron-up", "^", 14, T.SubText)
chip.MouseEnter:Connect(function() tween(chip, 0.12, { BackgroundTransparency = 0.3 }) end)
chip.MouseLeave:Connect(function() tween(chip, 0.14, { BackgroundTransparency = 0.55 }) end)
local function curName()
for n, th in pairs(Library.Themes) do
if th.Accent == win.Theme.Accent and th.Accent2 == win.Theme.Accent2 then return n end
end
return "Custom"
end
local function paint()
if win._destroyed then return end
local g = chipSw:FindFirstChildOfClass("UIGradient")
if g then g.Color = ColorSequence.new(win.Theme.Accent, win.Theme.Accent2) end
chipSw.BackgroundColor3 = Color3.new(1, 1, 1)
crumb.TextColor3 = win.Theme.SubText
chipLbl.Text = curName()
if win._uxProg then
win._uxProg.BackgroundColor3 = win.Theme.Accent
local pg = win._uxProg:FindFirstChildOfClass("UIGradient")
if pg then pg.Color = ColorSequence.new(win.Theme.Accent, win.Theme.Accent2) end
end
end
win._uxPaint = paint
local pop, shield
local function closePop()
if pop then pop:Destroy() pop = nil end
if shield then shield:Destroy() shield = nil end
end
local function openPop()
if pop then closePop() return end
local main, TH = win.Main, win.Theme
local sc = math.max((win.Scale and win.Scale.Scale) or 1, 0.01)
local rel = (chip.AbsolutePosition - main.AbsolutePosition) / sc
shield = new("TextButton", { Name = "UXShield", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 58, Parent = main })
shield.MouseButton1Click:Connect(closePop)
local names, seen = {}, {}
for _, n in ipairs(CURATED) do if Library.Themes[n] then names[#names + 1] = n seen[n] = true end end
local rest = {}
for n in pairs(Library.Themes) do if not seen[n] then rest[#rest + 1] = n end end
table.sort(rest)
for _, n in ipairs(rest) do names[#names + 1] = n end
local cur = curName()
local W, ROW = math.max(chip.AbsoluteSize.X / sc, 176), 34
local H = math.min(#names * (ROW + 2) + 12, 260)
pop = new("Frame", {
Name = "UXPop", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromOffset(rel.X, rel.Y - 8), Size = UDim2.fromOffset(W, H),
BackgroundColor3 = TH.Panel, BorderSizePixel = 0, ZIndex = 60, Parent = main,
}, { corner(14), stroke(TH.Accent, 1, 0.45) })
local scr = new("ScrollingFrame", {
Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
ScrollBarImageColor3 = TH.Accent, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 61, Parent = pop,
}, {
new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }),
})
for i, n in ipairs(names) do
local th = Library.Themes[n]
local on = n == cur
local row = new("TextButton", {
LayoutOrder = i, Size = UDim2.new(1, 0, 0, ROW), BackgroundColor3 = TH.Accent, BackgroundTransparency = on and 0.82 or 1,
Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 62, Parent = scr,
}, { new("UICorner", { CornerRadius = UDim.new(0, 10) }) })
swatch(row, th, 18, 10)
new("TextLabel", {
Position = UDim2.fromOffset(36, 0), Size = UDim2.new(1, -46, 1, 0), BackgroundTransparency = 1, Text = n,
Font = on and TH.FontBold or TH.Font, TextSize = 14, TextColor3 = on and TH.Accent or TH.Text,
TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 62, Parent = row,
})
row.MouseEnter:Connect(function() if not on then tween(row, 0.1, { BackgroundTransparency = 0.9 }) end end)
row.MouseLeave:Connect(function() if not on then tween(row, 0.12, { BackgroundTransparency = 1 }) end end)
row.MouseButton1Click:Connect(function()
closePop()
win:SetTheme(n)
end)
end
end
chip.MouseButton1Click:Connect(openPop)
win._uxClosePop = closePop
paint()
local function layout()
if win._destroyed then return end
local c = win.Compact == true
local ox, ow = c and 5 or 10, c and -10 or -19
bar.Position = UDim2.fromOffset(ox, 12)
bar.Size = UDim2.new(1, ow, 0, 36)
crumb.Visible = not c
cbtn.AnchorPoint = c and Vector2.new(0.5, 0) or Vector2.new(1, 0)
cbtn.Position = c and UDim2.new(0.5, 0, 0, 0) or UDim2.new(1, -8, 0, 0)
icClose.Visible, icOpen.Visible = not c, c
chip.Visible = not c
chip.Position = UDim2.new(0, ox + 4, 1, -(FOOT_H + 16 + SW))
chip.Size = UDim2.new(1, ow - 8, 0, 34)
for _, t in ipairs(win.Tabs) do if t._uxPinApply then t._uxPinApply() end end
win.TabList.Position = UDim2.fromOffset(ox, TOP)
win.TabList.Size = UDim2.new(1, ow, 1, -(TOP + FOOT_H + 16 + (c and 0 or SW + 4)))
if c then closePop() end
end
win._uxLayout = layout
layout()
cbtn.MouseButton1Click:Connect(function()
win._forceCompact = not (win.Compact == true)
win:_Fit(false)
end)
local prog = new("Frame", {
Name = "UXProgress", Size = UDim2.new(0, 0, 0, 3), BackgroundColor3 = T.Accent, BorderSizePixel = 0,
Visible = false, ZIndex = 25, Parent = win.Pages,
}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }), new("UIGradient", { Color = ColorSequence.new(T.Accent, T.Accent2) }) })
win._uxProg = prog
local dock = new("Frame", {
Name = "UXDock", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -18, 1, -4), Size = UDim2.fromOffset(0, 44),
AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = T.Panel, BackgroundTransparency = 1, BorderSizePixel = 0,
Visible = false, ZIndex = 30, Parent = win.Pages,
}, {
new("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
new("UIStroke", { Color = T.Accent, Thickness = 1, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
new("UIListLayout", {
FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder,
}),
new("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }),
})
local dstroke = dock:FindFirstChildOfClass("UIStroke")
local function dbtn(order, iconName, fb)
local b = new("TextButton", {
LayoutOrder = order, Size = UDim2.fromOffset(36, 36), BackgroundColor3 = T.Accent, BackgroundTransparency = 1,
Text = "", AutoButtonColor = false, BorderSizePixel = 0, Visible = false, ZIndex = 31, Parent = dock,
}, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
local g = glyph(b, iconName, fb, 18, T.Accent)
g.ZIndex = 32
b.MouseEnter:Connect(function() tween(b, 0.12, { BackgroundTransparency = 0.8 }) end)
b.MouseLeave:Connect(function() tween(b, 0.14, { BackgroundTransparency = 1 }) end)
return b, g
end
local fold, foldA = dbtn(1, "lucide:chevrons-down-up", "=")
local foldB = glyph(fold, "lucide:chevrons-up-down", "+", 18, T.Accent)
foldB.ZIndex = 32
foldB.Visible = false
local up = dbtn(2, "lucide:arrow-up", "^")
local function foldable(tab)
local n = {}
for _, sec in ipairs(tab and tab.Sections or {}) do
local head = sec.Frame and sec.Frame:FindFirstChildWhichIsA("TextButton")
local ok = false
if head then
for _, c in ipairs(head:GetChildren()) do
if c:IsA("GuiObject") and c.AnchorPoint == Vector2.new(1, 0.5) and c.Visible then ok = true end
end
end
if ok and sec.SetCollapsed then n[#n + 1] = sec end
end
return n
end
local dockOn = false
local function setDock(on)
if Library.Dock ~= true then on = false end
if on == dockOn then return end
dockOn = on
if on then
dock.Visible = true
tween(dock, 0.22, { BackgroundTransparency = 0.04, Position = UDim2.new(1, -18, 1, -16) })
tween(dstroke, 0.22, { Transparency = 0.45 })
else
tween(dock, 0.2, { BackgroundTransparency = 1, Position = UDim2.new(1, -18, 1, -4) })
tween(dstroke, 0.2, { Transparency = 1 })
task.delay(0.24, function() if not dockOn and dock.Parent then dock.Visible = false end end)
end
end
win._uxRefresh = function()
if win._destroyed then return end
local tab = win.Active
local far, frac = false, 0
if tab and tab.Cols then
for _, c in ipairs(tab.Cols) do
local y = c.CanvasPosition.Y
if y > 160 then far = true end
local range = c.AbsoluteCanvasSize.Y - c.AbsoluteSize.Y
if range > 4 then frac = math.max(frac, math.clamp(y / range, 0, 1)) end
end
end
crumb.Text = tab and ("%s  %s"):format("\226\128\186", tostring(tab.Name):upper()) or ""
prog.Visible = frac > 0.001
prog.Size = UDim2.new(frac, 0, 0, 3)
local secs = foldable(tab)
local anyOpen = false
for _, sec in ipairs(secs) do if not sec.Collapsed then anyOpen = true end end
fold.Visible = #secs >= 2
up.Visible = far
foldA.Visible, foldB.Visible = anyOpen, not anyOpen
setDock(fold.Visible or far)
end
up.MouseButton1Click:Connect(function()
local tab = win.Active
if not (tab and tab.Cols) then return end
for _, c in ipairs(tab.Cols) do
TweenService:Create(c, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { CanvasPosition = Vector2.new(0, 0) }):Play()
end
end)
fold.MouseButton1Click:Connect(function()
local secs = foldable(win.Active)
local anyOpen = false
for _, sec in ipairs(secs) do if not sec.Collapsed then anyOpen = true end end
for _, sec in ipairs(secs) do sec:SetCollapsed(anyOpen) end
task.delay(0.3, win._uxRefresh)
end)
end
local prevCW = Library.CreateWindow
function Library:CreateWindow(cfg)
local win = prevCW(self, cfg)
if type(win) == "table" then
local ok, err = pcall(build, win)
if not ok then warn("[SpectreUI] UX pack: " .. tostring(err)) end
end
return win
end
local prevFit = Window._Fit
function Window:_Fit(...)
local r = prevFit(self, ...)
if self._uxLayout then self._uxLayout() end
return r
end
local prevCT = Window.CreateTab
function Window:CreateTab(...)
local tab = prevCT(self, ...)
if type(tab) == "table" and tab.Cols and self._uxRefresh then
for _, c in ipairs(tab.Cols) do c:GetPropertyChangedSignal("CanvasPosition"):Connect(self._uxRefresh) end
end
return tab
end
Library._pins = Library._pins or {}
local function addPin(win, tab)
local btn = tab.Button
if not btn or tab._uxStar then return end
local order = btn.LayoutOrder
local pin = new("TextButton", {
Name = "Pin", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -2, 0.5, 0), Size = UDim2.fromOffset(34, 34),
BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 4, Visible = false, Parent = btn,
})
local g = glyph(pin, "lucide:pin", "*", 16, win.Theme.SubText)
g.ZIndex = 5
local function apply()
local pinned = Library._pins[tab.Name] == true
btn.LayoutOrder = pinned and (order - 1000) or order
pin.Visible = not (win.Compact == true) and (pinned or win.Active == tab)
recolor(g, pinned and win.Theme.Accent or win.Theme.SubText)
local tr = pinned and 0 or 0.55
if g:IsA("ImageLabel") then g.ImageTransparency = tr else g.TextTransparency = tr end
g.Rotation = pinned and 0 or 35
if tab._FitLabel then tab:_FitLabel() end
end
tab._uxStar = pin
tab._uxPinApply = apply
pin.MouseButton1Click:Connect(function()
Library._pins[tab.Name] = not Library._pins[tab.Name] or nil
apply()
end)
local token = 0
btn.InputBegan:Connect(function(i)
local t = i.UserInputType
if t ~= Enum.UserInputType.Touch and t ~= Enum.UserInputType.MouseButton1 then return end
token += 1
tab._lpFired = false
local my = token
local start = i.Position
task.delay(0.45, function()
if my ~= token or i.UserInputState == Enum.UserInputState.End then return end
if (i.Position - start).Magnitude > 10 then return end
tab._lpFired = true
Library._pins[tab.Name] = not Library._pins[tab.Name] or nil
apply()
end)
end)
btn.InputEnded:Connect(function(i)
local t = i.UserInputType
if t == Enum.UserInputType.Touch or t == Enum.UserInputType.MouseButton1 then token += 1 end
end)
apply()
end
local prevCT2 = Window.CreateTab
function Window:CreateTab(...)
local tab = prevCT2(self, ...)
if type(tab) == "table" then pcall(addPin, self, tab) end
return tab
end
if Tab and Tab.CreateSection then
local prevCS = Tab.CreateSection
function Tab:CreateSection(...)
local sec = prevCS(self, ...)
local w = self.Window
if w and w._uxRefresh then task.defer(w._uxRefresh) end
return sec
end
end
local prevSel = Window.SelectTab
function Window:SelectTab(tab)
local r = table.pack(prevSel(self, tab))
if self._uxRefresh then self._uxRefresh() end
for _, t in ipairs(self.Tabs) do if t._uxPinApply then t._uxPinApply() end end
return table.unpack(r, 1, r.n)
end
local prevTheme = Window.SetTheme
function Window:SetTheme(...)
local r = table.pack(prevTheme(self, ...))
if self.TopGlow then self.TopGlow.BackgroundColor3 = self.Theme.Accent end
local mgr = self.Main and self.Main:FindFirstChildOfClass("UIGradient")
if mgr then mgr.Color = cseq({ 0, self.Theme.Top:Lerp(self.Theme.Background, 0.45) }, { 1, self.Theme.Background }) mgr.Enabled = true end
if self._uxPaint then
self._uxPaint()
task.delay(0.7, self._uxPaint)
end
return table.unpack(r, 1, r.n)
end
end)()
Library.TextGuard = { Enabled = true, MinSize = 10, Wrap = true }
do
local TextService = game:GetService("TextService")
local base = setmetatable({}, { __mode = "k" })
local lastSet = setmetatable({}, { __mode = "k" })
local wrapBy = setmetatable({}, { __mode = "k" })
local sigOf = setmetatable({}, { __mode = "k" })
local NONE = Enum.AutomaticSize.None
local function measure(text, size, font, bound)
local ok, v = pcall(TextService.GetTextSize, TextService, text, size, font, bound)
if ok then return v end
return nil
end
function Library._fitOne(win, d)
local g = Library.TextGuard
if g.Enabled == false or d.TextScaled or d.RichText or d.Text == "" or d:GetAttribute("SGSkip") then return "skip" end
local auto = d.AutomaticSize
if auto == Enum.AutomaticSize.X or auto == Enum.AutomaticSize.XY then return "skip" end
if d.TextWrapped and auto == Enum.AutomaticSize.Y and not wrapBy[d] then return "skip" end
local sz = d.AbsoluteSize
if sz.X < 8 or sz.Y < 8 then return "skip" end
local sc = math.max((win.Scale and win.Scale.Scale) or 1, 0.01)
local aw, ah = sz.X / sc, sz.Y / sc
local pd = d:FindFirstChildOfClass("UIPadding")
if pd then
aw = aw - (pd.PaddingLeft.Offset + pd.PaddingLeft.Scale * aw) - (pd.PaddingRight.Offset + pd.PaddingRight.Scale * aw)
ah = ah - (pd.PaddingTop.Offset + pd.PaddingTop.Scale * ah) - (pd.PaddingBottom.Offset + pd.PaddingBottom.Scale * ah)
end
if aw < 6 or ah < 6 then return "skip" end
local cur = d.TextSize
if base[d] == nil or lastSet[d] ~= cur then base[d] = cur end
local b = base[d]
local text, font = d.Text, d.Font
local sig = text .. "|" .. b .. "|" .. math.floor(aw) .. "|" .. math.floor(ah) .. "|" .. tostring(font) .. "|" .. tostring(wrapBy[d] ~= nil)
if sigOf[d] == sig then return "same" end
sigOf[d] = sig
local minS = math.min(g.MinSize or 10, b)
local multi = d.TextWrapped and not wrapBy[d]
local function fitsLine(size)
local v = measure(text, size, font, Vector2.new(100000, 100000))
return v ~= nil and v.X <= aw + 0.5 and v.Y <= ah + 2
end
local function fitsWrap(size)
local v = measure(text, size, font, Vector2.new(aw, 100000))
return v ~= nil and v.Y <= ah + 2
end
local function apply(size, wrap)
if d.TextSize ~= size then d.TextSize = size end
lastSet[d] = size
if wrap then
if not wrapBy[d] then wrapBy[d] = d.TextTruncate end
d.TextWrapped = true
d.TextTruncate = Enum.TextTruncate.None
elseif wrapBy[d] then
d.TextWrapped = false
d.TextTruncate = wrapBy[d]
wrapBy[d] = nil
end
end
if multi then
for size = b, minS, -1 do
if fitsWrap(size) then
apply(size, false)
return size == b and "ok" or "shrunk"
end
end
apply(minS, false)
return "cut"
end
local soft = math.max(minS, math.floor(b * 0.8))
for size = b, soft, -1 do
if fitsLine(size) then
apply(size, false)
return size == b and "ok" or "shrunk"
end
end
if g.Wrap ~= false then
for size = b, minS, -1 do
if fitsWrap(size) then
local v = measure(text, size, font, Vector2.new(aw, 100000))
if v and v.Y > size * 1.1 then
apply(size, true)
return "wrapped"
end
end
end
end
for size = soft - 1, minS, -1 do
if fitsLine(size) then
apply(size, false)
return "shrunk"
end
end
apply(minS, false)
return "cut"
end
function Window:FitText(root)
if Library.TextGuard.Enabled == false or self._destroyed then return 0 end
root = root or self.Main
if not root or not root.Parent then return 0 end
local fixed, t0, n = 0, os.clock(), 0
for _, d in ipairs(root:GetDescendants()) do
if self._destroyed or not root.Parent then break end
if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Visible then
n += 1
if n % 12 == 0 and os.clock() - t0 > 0.005 then
task.wait()
t0 = os.clock()
end
local ok, st = pcall(Library._fitOne, self, d)
if ok and (st == "shrunk" or st == "wrapped") then fixed += 1 end
end
end
return fixed
end
function Window:_FitChrome()
if self._fitBusy or self._destroyed then return end
self._fitBusy = true
for _, r in ipairs({ self.HeaderCard, self.Sidebar, self.Active and self.Active.Page }) do
if r then pcall(self.FitText, self, r) end
end
self._fitBusy = false
end
function Window:_QueueFit(delay)
if self._destroyed or Library.TextGuard.Enabled == false then return end
self._fitSeq = (self._fitSeq or 0) + 1
local seq = self._fitSeq
task.delay(delay or 0.4, function()
if self._destroyed or seq ~= self._fitSeq then return end
if not (self.Visible and self.Main and self.Main.Visible) then self._fitDirty = true return end
if self._moving or (self._drag and self._drag.Dragging) then return self:_QueueFit(0.5) end
self:_FitChrome()
task.delay(1.2, function()
if not self._destroyed and seq == self._fitSeq and self.Visible then self:_FitChrome() end
end)
end)
end
for _, name in ipairs({ "SelectTab", "SetFont", "SetTextScale", "SetTheme", "SetSize", "Resize", "SetMaximized", "SetShaded", "RenameTab" }) do
local prev = Window[name]
if type(prev) == "function" then
Window[name] = function(self, ...)
local r = table.pack(prev(self, ...))
if self._QueueFit and not self._destroyed then self:_QueueFit(name == "SelectTab" and 0.45 or 0.6) end
return table.unpack(r, 1, r.n)
end
end
end
local prevVis = Window.SetVisible
function Window:SetVisible(v, ...)
local r = table.pack(prevVis(self, v, ...))
if v and not self._destroyed then self:_QueueFit(self._fitDirty and 0.5 or 0.9) self._fitDirty = nil end
return table.unpack(r, 1, r.n)
end
end
Library.Visual = Library.Visual or {
Plus = true, AuroraSpeed = 9,
Aurora = false, GlowSweep = false, Sparkle = false, Spotlight = false, RevealSweep = false, ThemeWave = false,
ClickRing = false, TitleShine = false, ScrollBar = false, TapGlow = false, Rainbow = false,
Brackets = false, Scanline = false, Neon = false, Trail = false, Scramble = false, Glitch = false, ShakeOnError = false,
}
Library._visualPlus = (function()
local TS, UIS = TweenService, UserInputService
local V = Library.Visual
local WHITE = Color3.new(1, 1, 1)
local function lite() return false end
local function on(key)
if V.Plus == false or V[key] == false then return false end
if lite() then return V.Mobile ~= false and (Library.MobileKeys or {})[key] == true end
return true
end
local function accents(win)
local T = win.Theme or {}
local a = T.Accent or WHITE
return a, T.Accent2 or a
end
local function paint(win)
local au = win._aurora
if not au or not au.g.Parent then return end
local a, b = accents(win)
au.g.Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, a), ColorSequenceKeypoint.new(0.33, b),
ColorSequenceKeypoint.new(0.66, a:Lerp(WHITE, 0.35)), ColorSequenceKeypoint.new(1, a),
})
au.st.Color = WHITE
end
local function startAurora(win)
if win._aurora or win._destroyed or not on("Aurora") then return end
local main = win.Main
local st = main and main:FindFirstChildOfClass("UIStroke")
if not st then return end
local g = Instance.new("UIGradient")
g.Name = "Aurora"
g.Parent = st
local tw = TS:Create(g, TweenInfo.new(math.max(tonumber(V.AuroraSpeed) or 9, 2), Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Rotation = 360 })
win._aurora = { g = g, st = st, tw = tw, rest = st.Color }
paint(win)
tw:Play()
if win.Visible == false then tw:Pause() end
end
local function stopAurora(win)
local au = win._aurora
if not au then return end
win._aurora = nil
pcall(function() au.tw:Cancel() end)
pcall(function() au.g:Destroy() end)
pcall(function() if au.st.Parent then au.st.Color = (win.Theme and win.Theme.Border) or au.rest end end)
end
function Window:SetAurora(v)
V.Aurora = v and true or false
if v then startAurora(self) else stopAurora(self) end
return self
end
local function startSweep(win)
if win._sweep or win._destroyed or not on("GlowSweep") then return end
local hc = win.HeaderCard
local line = hc and hc:FindFirstChild("GlowLine")
local g = line and line:FindFirstChildOfClass("UIGradient")
if not g then return end
g.Offset = Vector2.new(-0.45, 0)
local tw = TS:Create(g, TweenInfo.new(3.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Offset = Vector2.new(0.45, 0) })
win._sweep = tw
tw:Play()
if win.Visible == false then tw:Pause() end
end
local prevCreate = Library.CreateWindow
function Library:CreateWindow(cfg)
local win = prevCreate(self, cfg)
if type(win) == "table" then
pcall(startAurora, win)
pcall(startSweep, win)
end
return win
end
local prevTheme = Window.SetTheme
function Window:SetTheme(...)
local r = table.pack(prevTheme(self, ...))
if self._aurora then
pcall(paint, self)
task.delay(0.7, function() if self._aurora then pcall(paint, self) end end)
end
return table.unpack(r, 1, r.n)
end
local prevVis = Window.SetVisible
function Window:SetVisible(v, ...)
local r = table.pack(prevVis(self, v, ...))
for _, tw in ipairs({ self._aurora and self._aurora.tw or false, self._sweep or false }) do
if tw then pcall(function() if v then tw:Play() else tw:Pause() end end) end
end
return table.unpack(r, 1, r.n)
end
local prevDestroy = Window.Destroy
function Window:Destroy(...)
pcall(stopAurora, self)
if self._sweep then pcall(function() self._sweep:Cancel() end) self._sweep = nil end
return prevDestroy(self, ...)
end
local function burst(win, obj)
local gui = win.Gui
local row = obj.Frame
if not (gui and gui.Parent and row and row.Parent) or win.Visible == false then return end
local track, knob
for _, c in ipairs(row:GetChildren()) do
if c:IsA("Frame") then track = c break end
end
if track then
for _, c in ipairs(track:GetChildren()) do
if c:IsA("Frame") and c.ZIndex == 2 then knob = c break end
end
end
local src = knob or track or row
local c = src.AbsolutePosition + src.AbsoluteSize / 2 - gui.AbsolutePosition
local a, b = accents(win)
local info = TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
for i = 1, 9 do
local p = Instance.new("Frame")
p.AnchorPoint = Vector2.new(0.5, 0.5)
p.Size = UDim2.fromOffset(5, 5)
p.Position = UDim2.fromOffset(c.X, c.Y)
p.BackgroundColor3 = (i % 2 == 0) and a or b
p.BorderSizePixel = 0
p.ZIndex = 300
p.Rotation = math.random(0, 90)
Instance.new("UICorner", p).CornerRadius = UDim.new(i % 3 == 0 and 0 or 1, i % 3 == 0 and 1 or 0)
p.Parent = gui
local ang = (i / 9) * math.pi * 2 + (math.random() - 0.5) * 0.6
local d = 16 + math.random() * 14
local tw = TS:Create(p, info, {
Position = UDim2.fromOffset(c.X + math.cos(ang) * d, c.Y + math.sin(ang) * d - 4),
BackgroundTransparency = 1, Size = UDim2.fromOffset(1, 1), Rotation = p.Rotation + 120,
})
tw.Completed:Once(function() p:Destroy() end)
tw:Play()
end
end
local origToggle = Section.CreateToggle
function Section:CreateToggle(cfg)
local obj = origToggle(self, cfg)
local win = self.Window
if type(obj) == "table" and type(obj.Set) == "function" and type(obj.Get) == "function" and win then
local raw = obj.Set
function obj:Set(v, silent)
local before = obj:Get()
raw(self, v, silent)
if v and not before and not silent and on("Sparkle") and not win._destroyed then
pcall(burst, win, obj)
end
end
end
return obj
end
return { start = startAurora, burst = burst }
end)()
do
local defaults = {
Plus = false, Spotlight = false, RevealSweep = false, ThemeWave = false,
ClickRing = false, TitleShine = false, ScrollBar = true, Rainbow = false, Mobile = true, TapGlow = false,
}
for k, v in pairs(defaults) do
if Library.Visual[k] == nil then Library.Visual[k] = v end
end
Library.MobileKeys = { Sparkle = true, RevealSweep = true, ThemeWave = true, ClickRing = true, TitleShine = true, ScrollBar = true, TapGlow = true }
end
Library._visualPlus2 = (function()
local TS, UIS = TweenService, UserInputService
local V = Library.Visual
local WHITE = Color3.new(1, 1, 1)
local KP, NK = ColorSequenceKeypoint.new, NumberSequenceKeypoint.new
local BAND = NumberSequence.new({ NK(0, 0.93), NK(0.5, 0), NK(1, 0.93) })
local ST = setmetatable({}, { __mode = "k" })
local function lite() return false end
local function on(key)
if V.Plus == false or V[key] == false then return false end
if lite() then return V.Mobile ~= false and (Library.MobileKeys or {})[key] == true end
return true
end
local function accents(win)
local T = win.Theme or {}
local a = T.Accent or WHITE
return a, T.Accent2 or a
end
local function alive(win) return win and not win._destroyed and win.Gui ~= nil and win.Gui.Parent ~= nil end
local function shown(win) return alive(win) and win.Visible ~= false end
local function state(win)
local s = ST[win]
if not s then
s = { byTab = {}, conns = {}, scConns = {}, rings = 0 }
ST[win] = s
end
return s
end
local function cleanup(win)
local st = ST[win]
if not st then return end
ST[win] = nil
for _, c in ipairs(st.conns) do pcall(function() c:Disconnect() end) end
for _, c in ipairs(st.scConns) do pcall(function() c:Disconnect() end) end
if st.title then pcall(function() st.title.tw:Cancel() end) end
end
local function attach(win, sec)
local f = sec and sec.Frame
if not f then return end
local stroke = f:FindFirstChildOfClass("UIStroke")
if not stroke or stroke:FindFirstChild("SpotGrad") then return end
local g = Instance.new("UIGradient")
g.Name = "SpotGrad"
g.Transparency = BAND
g.Enabled = false
g.Parent = stroke
local rec = { sec = sec, stroke = stroke, g = g, t0 = stroke.Transparency, th0 = stroke.Thickness, on = false, seq = 0 }
local st = state(win)
local list = st.byTab[sec.Tab]
if not list then list = {} st.byTab[sec.Tab] = list end
list[#list + 1] = rec
end
local function paint(win, rec)
local a, b = accents(win)
rec.g.Color = ColorSequence.new({ KP(0, a), KP(0.5, a:Lerp(WHITE, 0.5)), KP(1, b) })
end
local function lightOn(win, rec)
if rec.on then return end
rec.on = true
rec.seq += 1
paint(win, rec)
rec.g.Enabled = true
rec.stroke.Color = WHITE
rec.stroke.Transparency = 1
rec.stroke.Thickness = 1.5
TS:Create(rec.stroke, TweenInfo.new(0.16, Enum.EasingStyle.Quad), { Transparency = 0.1 }):Play()
end
local function lightOff(win, rec)
if not rec.on then return end
rec.on = false
rec.seq += 1
local my = rec.seq
local tw = TS:Create(rec.stroke, TweenInfo.new(0.14, Enum.EasingStyle.Quad), { Transparency = 1 })
tw.Completed:Once(function()
if rec.seq ~= my or rec.on or not rec.stroke.Parent then return end
rec.g.Enabled = false
local T = win.Theme
if T and T.Border then rec.stroke.Color = T.Border end
rec.stroke.Thickness = rec.th0
rec.stroke.Transparency = 1
TS:Create(rec.stroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { Transparency = rec.t0 }):Play()
end)
tw:Play()
end
local function clearHover(win)
local st = ST[win]
if st and st.hover then
local r = st.hover
st.hover = nil
lightOff(win, r)
end
end
local function sweep(win, rec, delay)
task.delay(delay or 0, function()
if not shown(win) or rec.on or rec.sweeping or not rec.sec.Frame.Parent then return end
rec.sweeping = true
lightOn(win, rec)
rec.g.Offset = Vector2.new(-1, 0)
local tw = TS:Create(rec.g, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Offset = Vector2.new(1, 0) })
tw.Completed:Once(function()
rec.sweeping = false
local st = ST[win]
if st and st.hover == rec then return end
lightOff(win, rec)
end)
tw:Play()
end)
end
local function playSweep(win, base)
local st = ST[win]
if not st or not st.ready or not on("RevealSweep") or not shown(win) then return end
local list = st.byTab[win.Active]
if not list then return end
local n = 0
for _, rec in ipairs(list) do
if rec.sec.Frame.Parent then
n += 1
if n > 8 then break end
sweep(win, rec, (base or 0.12) + n * 0.07)
end
end
end
local function onMove(win, input)
local st = ST[win]
if not st or not on("Spotlight") or not shown(win) then return end
local now = os.clock()
if now - (st.last or 0) < 0.025 then return end
st.last = now
if win._moving or (win._drag and win._drag.Dragging) then return end
local pos = input.Position
local hit
local list = win.Active and st.byTab[win.Active]
local pg = win.Pages
if list and pg and pg.Parent then
local pp, ps = pg.AbsolutePosition, pg.AbsoluteSize
if pos.X >= pp.X and pos.X <= pp.X + ps.X and pos.Y >= pp.Y and pos.Y <= pp.Y + ps.Y then
for i = #list, 1, -1 do
local rec = list[i]
local f = rec.sec.Frame
if not f.Parent then
table.remove(list, i)
else
local ap, as = f.AbsolutePosition, f.AbsoluteSize
if pos.X >= ap.X and pos.X <= ap.X + as.X and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y then hit = rec end
end
end
end
end
if hit ~= st.hover then
local cur = st.hover
st.hover = hit
if cur then lightOff(win, cur) end
if hit then lightOn(win, hit) end
end
if hit and not hit.sweeping then
local f = hit.sec.Frame
local w = f.AbsoluteSize.X
if w > 0 then
hit.g.Offset = Vector2.new(math.clamp((pos.X - f.AbsolutePosition.X) / w, 0, 1) - 0.5, 0)
end
end
end
local function sectionAt(win, pos)
local st = ST[win]
local list = st and win.Active and st.byTab[win.Active]
local pg = win.Pages
if not list or not pg or not pg.Parent then return nil end
local pp, ps = pg.AbsolutePosition, pg.AbsoluteSize
if pos.X < pp.X or pos.X > pp.X + ps.X or pos.Y < pp.Y or pos.Y > pp.Y + ps.Y then return nil end
for _, rec in ipairs(list) do
local f = rec.sec.Frame
if f.Parent then
local ap, as = f.AbsolutePosition, f.AbsoluteSize
if pos.X >= ap.X and pos.X <= ap.X + as.X and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y then return rec end
end
end
return nil
end
local function ring(win, pos, touch)
local st, gui = ST[win], win.Gui
if not st or not gui or st.rings >= 4 then return end
st.rings += 1
local a = accents(win)
local p = Instance.new("Frame")
p.AnchorPoint = Vector2.new(0.5, 0.5)
p.Position = UDim2.fromOffset(pos.X - gui.AbsolutePosition.X, pos.Y - gui.AbsolutePosition.Y)
p.Size = UDim2.fromOffset(6, 6)
p.BackgroundTransparency = 1
p.BorderSizePixel = 0
p.Active = false
p.ZIndex = 300
Instance.new("UICorner", p).CornerRadius = UDim.new(0.5, 0)
local sk = Instance.new("UIStroke")
sk.Color = a
sk.Thickness = touch and 2.5 or 2
sk.Transparency = 0.1
sk.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
sk.Parent = p
p.Parent = gui
local info = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tw = TS:Create(p, info, { Size = UDim2.fromOffset(touch and 80 or 54, touch and 80 or 54) })
TS:Create(sk, info, { Transparency = 1, Thickness = 0.5 }):Play()
tw.Completed:Once(function()
local s2 = ST[win]
if s2 then s2.rings = math.max(s2.rings - 1, 0) end
p:Destroy()
end)
tw:Play()
end
local function findTitle(win)
local left = win.Left
if not left then return nil end
local best, size = nil, 0
for _, d in ipairs(left:GetDescendants()) do
if d:IsA("TextLabel") and d.Text ~= "" and d.TextSize > size then best, size = d, d.TextSize end
end
return best
end
local function paintTitle(win)
local st = ST[win]
local ts = st and st.title
if not ts or not ts.g.Parent then return end
local a, b = accents(win)
ts.g.Color = ColorSequence.new({
KP(0, WHITE), KP(ts.c - ts.w, WHITE), KP(ts.c, a:Lerp(b, 0.4)), KP(ts.c + ts.w, WHITE), KP(1, WHITE),
})
end
local function startTitle(win)
local st = ST[win]
if not st or st.title or not alive(win) or not on("TitleShine") then return end
local lbl = findTitle(win)
if not lbl then return end
local r = math.clamp(lbl.TextBounds.X / math.max(lbl.AbsoluteSize.X, 1), 0.15, 1)
local s0 = 0
if lbl.TextXAlignment == Enum.TextXAlignment.Center then s0 = (1 - r) / 2
elseif lbl.TextXAlignment == Enum.TextXAlignment.Right then s0 = 1 - r end
local c, w = s0 + r / 2, 0.14 * r
local g = Instance.new("UIGradient")
g.Name = "TitleShine"
g.Offset = Vector2.new(-(c + w), 0)
g.Parent = lbl
local info = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 3.5)
local tw = TS:Create(g, info, { Offset = Vector2.new(r / 2 + w, 0) })
st.title = { g = g, tw = tw, lbl = lbl, c = c, w = w }
paintTitle(win)
tw:Play()
end
local function paintBar(win)
local st = ST[win]
if not st or not st.bar or not st.bar.Parent then return end
local a, b = accents(win)
st.barG.Color = ColorSequence.new(a, b)
end
local function bindScroll(win)
local st = ST[win]
if not st or not st.bar then return end
for _, c in ipairs(st.scConns) do pcall(function() c:Disconnect() end) end
table.clear(st.scConns)
local tab = win.Active
if not tab or not tab.Cols then st.bar.Visible = false return end
local function update()
if not st.bar.Parent then return end
local best, vis = 0, false
for _, col in ipairs(tab.Cols) do
local mx = col.AbsoluteCanvasSize.Y - col.AbsoluteWindowSize.Y
if mx > 6 then
vis = true
best = math.max(best, math.clamp(col.CanvasPosition.Y / mx, 0, 1))
end
end
st.bar.Visible = vis and on("ScrollBar")
st.bar.Size = UDim2.new(best, 0, 0, 2)
end
for _, col in ipairs(tab.Cols) do
for _, prop in ipairs({ "CanvasPosition", "AbsoluteCanvasSize", "AbsoluteWindowSize" }) do
st.scConns[#st.scConns + 1] = col:GetPropertyChangedSignal(prop):Connect(update)
end
end
update()
end
local function rainbowSeq()
local k = {}
for i = 0, 6 do k[#k + 1] = KP(i / 6, Color3.fromHSV((i % 6) / 6, 0.7, 1)) end
return ColorSequence.new(k)
end
local function applyRainbow(win)
local au = win._aurora
if au and au.g.Parent then au.g.Color = rainbowSeq() end
end
function Window:SetRainbow(v)
self._rainbow = v and true or false
if self._rainbow then
if not self._aurora and self.SetAurora then self:SetAurora(true) end
applyRainbow(self)
elseif self._aurora and self.SetAurora then
self:SetAurora(false)
self:SetAurora(true)
end
return self
end
function Window:SetSpotlight(v)
V.Spotlight = v and true or false
if not v then clearHover(self) end
return self
end
local function setup(win)
local st = state(win)
if st.ready ~= nil then return end
st.ready = false
st.conns[#st.conns + 1] = UIS.InputChanged:Connect(function(i)
if i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
if not alive(win) then return cleanup(win) end
onMove(win, i)
end)
st.conns[#st.conns + 1] = UIS.InputBegan:Connect(function(i)
local ty = i.UserInputType
local touch = ty == Enum.UserInputType.Touch
if ty ~= Enum.UserInputType.MouseButton1 and not touch then return end
if not alive(win) then return cleanup(win) end
if not shown(win) or not win.Main then return end
local ap, as, p = win.Main.AbsolutePosition, win.Main.AbsoluteSize, i.Position
if p.X < ap.X or p.X > ap.X + as.X or p.Y < ap.Y or p.Y > ap.Y + as.Y then return end
if touch then
st.tap = { input = i, pos = Vector2.new(p.X, p.Y), t = os.clock() }
elseif on("ClickRing") then
pcall(ring, win, p, false)
end
end)
st.conns[#st.conns + 1] = UIS.InputEnded:Connect(function(i)
local tap = st.tap
if not tap or tap.input ~= i then return end
st.tap = nil
if not alive(win) then return cleanup(win) end
if not shown(win) then return end
local p = i.Position
if os.clock() - tap.t > 0.45 or (Vector2.new(p.X, p.Y) - tap.pos).Magnitude > 12 then return end
if on("ClickRing") then pcall(ring, win, tap.pos, true) end
if on("TapGlow") then
local rec = sectionAt(win, tap.pos)
if rec then sweep(win, rec, 0) end
end
end)
if win.Main then
st.conns[#st.conns + 1] = win.Main.MouseLeave:Connect(function() clearHover(win) end)
end
if win.Pages then
local bar = Instance.new("Frame")
bar.Name = "VPScroll"
bar.Size = UDim2.new(0, 0, 0, 2)
bar.BackgroundColor3 = WHITE
bar.BorderSizePixel = 0
bar.Active = false
bar.Visible = false
bar.ZIndex = 30
bar.Parent = win.Pages
st.bar = bar
st.barG = Instance.new("UIGradient")
st.barG.Parent = bar
paintBar(win)
bindScroll(win)
end
task.delay(0.7, function() if alive(win) then pcall(startTitle, win) end end)
if V.Rainbow == true then
task.delay(0.3, function() if alive(win) then pcall(win.SetRainbow, win, true) end end)
end
task.delay(1.0, function() if ST[win] then ST[win].ready = true end end)
end
local prevCS = Tab.CreateSection
function Tab:CreateSection(...)
local sec = prevCS(self, ...)
local win = self.Window
if type(sec) == "table" and win and not win._destroyed then pcall(attach, win, sec) end
return sec
end
local prevCreate = Library.CreateWindow
function Library:CreateWindow(cfg)
local win = prevCreate(self, cfg)
if type(win) == "table" then pcall(setup, win) end
return win
end
local prevSel = Window.SelectTab
function Window:SelectTab(...)
local r = table.pack(prevSel(self, ...))
pcall(function()
if not ST[self] or self._destroyed then return end
clearHover(self)
bindScroll(self)
playSweep(self, 0.12)
end)
return table.unpack(r, 1, r.n)
end
local prevVis = Window.SetVisible
function Window:SetVisible(v, ...)
local r = table.pack(prevVis(self, v, ...))
pcall(function()
if not ST[self] then return end
if v then playSweep(self, 0.3) else clearHover(self) end
end)
return table.unpack(r, 1, r.n)
end
local prevTheme = Window.SetTheme
function Window:SetTheme(...)
local r = table.pack(prevTheme(self, ...))
local win = self
pcall(function()
if not ST[win] then return end
if V.ThemeWave ~= false then playSweep(win, 0.1) end
paintBar(win)
task.delay(0.8, function()
if not alive(win) then return end
pcall(paintBar, win)
pcall(paintTitle, win)
if win._rainbow then pcall(applyRainbow, win) end
end)
end)
return table.unpack(r, 1, r.n)
end
local prevDestroy = Window.Destroy
function Window:Destroy(...)
pcall(cleanup, self)
return prevDestroy(self, ...)
end
return { sweep = playSweep, ring = ring }
end)()
do
local d = { Brackets = false, Scanline = false, Neon = false, Trail = true, Scramble = true, Glitch = true, ShakeOnError = true }
for k, v in pairs(d) do
if Library.Visual[k] == nil then Library.Visual[k] = v end
end
Library.MobileKeys = Library.MobileKeys or {}
Library.MobileKeys.Scramble = true
Library.MobileKeys.ShakeOnError = true
Library.MobileKeys.Brackets = true
Library.MobileKeys.Neon = true
Library.MobileKeys.Scanline = true
Library.MobileKeys.Glitch = true
Library.MobileKeys.Aurora = true
Library.MobileKeys.GlowSweep = true
Library.MobileKeys.Trail = true
end
Library._visualPlus3 = (function()
local TS, UIS = TweenService, UserInputService
local V = Library.Visual
local WHITE = Color3.new(1, 1, 1)
local NK = NumberSequenceKeypoint.new
local ST = setmetatable({}, { __mode = "k" })
local function lite() return false end
local function on(key)
if V.Plus == false or V[key] == false then return false end
if lite() then return V.Mobile ~= false and (Library.MobileKeys or {})[key] == true end
return true
end
local function accents(win)
local T = win.Theme or {}
local a = T.Accent or WHITE
return a, T.Accent2 or a
end
local function alive(win) return win and not win._destroyed and win.Gui ~= nil and win.Gui.Parent ~= nil end
local function shown(win) return alive(win) and win.Visible ~= false end
local function state(win)
local s = ST[win]
if not s then s = { feat = {}, scr = 0, shake = 0 } ST[win] = s end
return s
end
local function mk(class, props, parent)
local o = Instance.new(class)
for k, v in pairs(props) do o[k] = v end
o.Parent = parent
return o
end
local function loop(inst, dur, props, style, reverse, delay)
local tw = TS:Create(inst, TweenInfo.new(dur, style or Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, reverse or false, delay or 0), props)
tw:Play()
return tw
end
local function stopFeat(win, name)
local s = ST[win]
local f = s and s.feat[name]
if not f then return end
s.feat[name] = nil
for _, tw in ipairs(f.tweens or {}) do pcall(function() tw:Cancel() end) end
if f.conn then pcall(function() f.conn:Disconnect() end) end
if f.inst then pcall(function() f.inst:Destroy() end) end
end
local builders = {}
local function startFeat(win, name)
if not alive(win) or ST[win] and ST[win].feat[name] or not on(name) then return end
local ok, inst, tweens, conn = pcall(builders[name], win)
if not ok or not inst then return end
state(win).feat[name] = { inst = inst, tweens = tweens or {}, conn = conn }
if win.Visible == false then
for _, tw in ipairs(tweens or {}) do pcall(function() tw:Pause() end) end
end
end
local function restartAll(win)
for name in pairs(builders) do
if ST[win] and ST[win].feat[name] then
stopFeat(win, name)
startFeat(win, name)
end
end
end
local function setPaused(win, paused)
local s = ST[win]
if not s then return end
for _, f in pairs(s.feat) do
for _, tw in ipairs(f.tweens) do
pcall(function() if paused then tw:Pause() else tw:Play() end end)
end
end
end
builders.Brackets = function(win)
local a = accents(win)
local holder = mk("CanvasGroup", {
Name = "HudBrackets", Position = UDim2.fromOffset(-5, -5), Size = UDim2.new(1, 10, 1, 10),
BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 46, Active = false,
}, win.Main)
holder.GroupTransparency = 0.15
local L, W = 20, 2
for _, c in ipairs({ { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } }) do
local ax, ay = c[1], c[2]
mk("Frame", { AnchorPoint = Vector2.new(ax, ay), Position = UDim2.new(ax, 0, ay, 0), Size = UDim2.fromOffset(L, W), BackgroundColor3 = a, BorderSizePixel = 0, ZIndex = 46 }, holder)
mk("Frame", { AnchorPoint = Vector2.new(ax, ay), Position = UDim2.new(ax, 0, ay, 0), Size = UDim2.fromOffset(W, L), BackgroundColor3 = a, BorderSizePixel = 0, ZIndex = 46 }, holder)
end
return holder, { loop(holder, 1.8, { GroupTransparency = 0.7 }, nil, true) }
end
builders.Neon = function(win)
local a, b = accents(win)
local r = (win.Radius or 16) + 7
local halo = mk("Frame", {
Name = "NeonHalo", Position = UDim2.fromOffset(-7, -7), Size = UDim2.new(1, 14, 1, 14),
BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1, Active = false,
}, win.Main)
mk("UICorner", { CornerRadius = UDim.new(0, r) }, halo)
local st = mk("UIStroke", { Color = a, Thickness = 5, Transparency = 0.9 }, halo)
return halo, {
loop(st, 2.4, { Transparency = 0.58 }, nil, true),
loop(st, 4.2, { Color = b }, nil, true),
}
end
builders.Scanline = function(win)
local a = accents(win)
local clip = mk("Frame", {
Name = "ScanBeam", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
ClipsDescendants = true, ZIndex = 45, Active = false,
}, win.Main)
mk("UICorner", { CornerRadius = UDim.new(0, win.Radius or 16) }, clip)
local beam = mk("Frame", {
Position = UDim2.new(0, 0, 0, -48), Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = a, BorderSizePixel = 0, ZIndex = 45, Active = false,
}, clip)
mk("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NK(0, 1), NK(0.7, 0.96), NK(0.96, 0.78), NK(1, 1) }) }, beam)
return clip, { loop(beam, 3.4, { Position = UDim2.new(0, 0, 1, 0) }, Enum.EasingStyle.Linear, false, 3.2) }
end
builders.Trail = function(win)
local layer = mk("Frame", {
Name = "CursorTrail", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 200, Active = false,
}, win.Gui)
local pool, N, idx = {}, 18, 0
local GS = game:GetService("GuiService")
for i = 1, N do
local dot = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(9, 9), BackgroundColor3 = WHITE, BorderSizePixel = 0, Visible = false, ZIndex = 200, Active = false }, layer)
mk("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)
pool[i] = { dot = dot, tw = nil }
end
local last
local conn = UIS.InputChanged:Connect(function(input)
local t = input.UserInputType
if (t ~= Enum.UserInputType.MouseMovement and t ~= Enum.UserInputType.Touch) or not shown(win) or not on("Trail") then return end
local main = win.Main
local mp = t == Enum.UserInputType.Touch and (Vector2.new(input.Position.X, input.Position.Y) + GS:GetGuiInset()) or UIS:GetMouseLocation()
local p0, sz = main.AbsolutePosition, main.AbsoluteSize
if mp.X < p0.X or mp.Y < p0.Y or mp.X > p0.X + sz.X or mp.Y > p0.Y + sz.Y then last = nil return end
if last and (mp - last).Magnitude < 9 then return end
last = mp
idx = idx % N + 1
local e = pool[idx]
if e.tw then pcall(function() e.tw:Cancel() end) end
local a, b = accents(win)
e.dot.BackgroundColor3 = a:Lerp(b, (os.clock() * 0.6) % 1)
e.dot.Position = UDim2.fromOffset(mp.X, mp.Y)
e.dot.Size = UDim2.fromOffset(9, 9)
e.dot.BackgroundTransparency = 0.2
e.dot.Visible = true
local tw = TS:Create(e.dot, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(2, 2), BackgroundTransparency = 1 })
e.tw = tw
tw.Completed:Connect(function(st)
if st == Enum.PlaybackState.Completed and e.tw == tw then e.dot.Visible = false end
end)
tw:Play()
end)
return layer, {}, conn
end
local GLYPHS = "ABCDEFGHJKLMNPQRSTUVWXYZ0123456789#%&@"
local function splitChars(str)
local out = {}
local ok = pcall(function()
for _, c in utf8.codes(str) do out[#out + 1] = utf8.char(c) end
end)
if not ok then out = {} for i = 1, #str do out[i] = str:sub(i, i) end end
return out
end
function Window:Scramble(dur)
local lbl = self.BrandLabel
if not lbl or not lbl.Parent or self._destroyed then return self end
local s = state(self)
s.scr += 1
local tok = s.scr
local final = s.scrFinal or lbl.Text
s.scrFinal = final
local chars = splitChars(final)
local n = #chars
if n == 0 then s.scrFinal = nil return self end
local steps = 14
local dt = math.max((tonumber(dur) or 0.6) / steps, 0.016)
task.spawn(function()
for i = 1, steps do
if tok ~= s.scr or self._destroyed or not lbl.Parent then return end
local reveal = math.floor(n * i / steps)
local buf = table.create(n)
for j = 1, n do
local c = chars[j]
if j <= reveal or c:match("%s") then
buf[j] = c
else
local g = math.random(1, #GLYPHS)
buf[j] = GLYPHS:sub(g, g)
end
end
lbl.Text = table.concat(buf)
task.wait(dt)
end
if tok == s.scr and lbl.Parent then
lbl.Text = final
s.scrFinal = nil
end
end)
return self
end
function Window:Glitch(dur)
local lbl = self.BrandLabel
if not lbl or not lbl.Parent or self._destroyed then return self end
local s = state(self)
if s.glitching then return self end
s.glitching = true
local function layer(color)
return mk("TextLabel", {
Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = lbl.Text, Font = lbl.Font, TextSize = lbl.TextSize,
TextColor3 = color, TextTransparency = 0.35, TextXAlignment = lbl.TextXAlignment, ZIndex = (lbl.ZIndex or 1) + 1, Active = false,
}, lbl)
end
local red, cyan = layer(Color3.fromRGB(255, 45, 95)), layer(Color3.fromRGB(45, 230, 255))
task.spawn(function()
local steps = 7
local dt = math.max((tonumber(dur) or 0.28) / steps, 0.02)
for _ = 1, steps do
if self._destroyed or not lbl.Parent then break end
local dx, dy = math.random(-3, 3), math.random(-1, 1)
red.Position = UDim2.fromOffset(-dx - 1, dy)
cyan.Position = UDim2.fromOffset(dx + 1, -dy)
red.Text, cyan.Text = lbl.Text, lbl.Text
task.wait(dt)
end
pcall(function() red:Destroy() end)
pcall(function() cyan:Destroy() end)
s.glitching = false
end)
return self
end
local function glitchLoop(win)
task.spawn(function()
while alive(win) do
task.wait(math.random(70, 140) / 10)
if shown(win) and on("Glitch") and (win._qual or 0) < 2 and not (win._drag and win._drag.Dragging) then pcall(win.Glitch, win) end
end
end)
end
function Window:Shake(strength)
local main = self.Main
if not main or self._destroyed or self.Visible == false or (self._drag and self._drag.Dragging) then return self end
local s = state(self)
s.shake += 1
local tok = s.shake
local k = tonumber(strength) or 1.6
task.spawn(function()
for _, ang in ipairs({ k, -k, k * 0.6, -k * 0.4, 0 }) do
if tok ~= s.shake or self._destroyed then break end
local tw = TS:Create(main, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Rotation = ang })
tw:Play()
task.wait(0.055)
end
if tok == s.shake and main.Parent then main.Rotation = 0 end
end)
return self
end
local function switch(name, setter)
Window[setter] = function(self, v)
V[name] = v and true or false
if v then startFeat(self, name) else stopFeat(self, name) end
return self
end
end
switch("Brackets", "SetBrackets")
switch("Scanline", "SetScanline")
switch("Neon", "SetNeon")
switch("Trail", "SetTrail")
local function setup(win)
state(win)
for name in pairs(builders) do startFeat(win, name) end
if on("Scramble") then task.delay(0.25, function() if shown(win) then pcall(win.Scramble, win, 0.7) end end) end
glitchLoop(win)
end
local prevCreate = Library.CreateWindow
function Library:CreateWindow(cfg)
local win = prevCreate(self, cfg)
if type(win) == "table" then pcall(setup, win) end
return win
end
local prevVis = Window.SetVisible
function Window:SetVisible(v, ...)
local was = self.Visible
local r = table.pack(prevVis(self, v, ...))
pcall(function()
if not ST[self] or self._destroyed then return end
setPaused(self, not v)
if v and not was and on("Scramble") then
task.delay(0.2, function() if shown(self) then pcall(self.Scramble, self, 0.55) end end)
end
end)
return table.unpack(r, 1, r.n)
end
local prevTheme = Window.SetTheme
function Window:SetTheme(...)
local r = table.pack(prevTheme(self, ...))
local win = self
pcall(function()
if not ST[win] then return end
if on("Scramble") then win:Scramble(0.45) end
if on("Glitch") then win:Glitch(0.3) end
task.delay(0.8, function()
if alive(win) and ST[win] then pcall(restartAll, win) end
end)
end)
return table.unpack(r, 1, r.n)
end
local prevTitle = Window.SetTitle
function Window:SetTitle(...)
local s = ST[self]
if s then s.scr += 1 s.scrFinal = nil end
return prevTitle(self, ...)
end
local function isError(x)
if type(x) == "string" then return x:lower() == "error" or x:lower() == "err" end
if type(x) == "table" then
local k = x.Kind or x.kind or x.Type
return type(k) == "string" and (k:lower() == "error" or k:lower() == "err")
end
return false
end
local prevNotify = Window.Notify
function Window:Notify(cfg, ...)
if on("ShakeOnError") and isError(cfg) then pcall(self.Shake, self) end
return prevNotify(self, cfg, ...)
end
local prevToast = Window.Toast
function Window:Toast(text, opts, ...)
if on("ShakeOnError") and (isError(opts) or isError(text)) then pcall(self.Shake, self) end
return prevToast(self, text, opts, ...)
end
local prevDegrade = Window._Degrade
function Window:_Degrade(...)
local r = table.pack(prevDegrade(self, ...))
pcall(function()
stopFeat(self, "Neon")
stopFeat(self, "Scanline")
if (self._qual or 0) >= 2 then stopFeat(self, "Trail") end
if self._aurora then pcall(function() self._aurora.tw:Pause() end) end
end)
return table.unpack(r, 1, r.n)
end
local prevRecover = Window._Recover
function Window:_Recover(...)
local r = table.pack(prevRecover(self, ...))
pcall(function()
if (self._qual or 0) == 0 and ST[self] and alive(self) then
startFeat(self, "Neon") startFeat(self, "Scanline") startFeat(self, "Trail")
if self._aurora and self.Visible ~= false then pcall(function() self._aurora.tw:Play() end) end
end
end)
return table.unpack(r, 1, r.n)
end
local prevDestroy = Window.Destroy
function Window:Destroy(...)
pcall(function()
local s = ST[self]
if not s then return end
for name in pairs(s.feat) do stopFeat(self, name) end
ST[self] = nil
end)
return prevDestroy(self, ...)
end
return { scramble = function(w, d) return w:Scramble(d) end, glitch = function(w, d) return w:Glitch(d) end }
end)()
-- v3.22 additions: UI scale, layout toggles, FloatingButton, Chips, PlayerPicker, Performance.
do
local StatsService = game:GetService("Stats")

local baseAutoK = Library._autoK
Library.UserScale = 1
function Library._autoK(vp)
	local k = baseAutoK(vp) * (Library.UserScale or 1)
	return math.floor(math.clamp(k, 0.4, 2.6) * 100 + 0.5) / 100
end

function Window:SetUIScale(s)
	Library.UserScale = math.clamp(tonumber(s) or 1, 0.6, 1.6)
	for _, w in ipairs(Library.Windows) do
		if w._Fit and not w._destroyed then pcall(w._Fit, w, true) end
	end
	return Library.UserScale
end
function Window:GetUIScale() return Library.UserScale or 1 end

function Window:SetCompact(v)
	self._forceCompact = v == true
	self.Cfg.Compact = v == true
	self:_Fit(true)
end

function Window:SetTwoColumn(v)
	self.Cfg.TwoColumn = v == true
	self:_Fit(true)
end

function Library:SetAnimSpeed(s)
	Library.Anim.Speed = math.clamp(tonumber(s) or 1, 0.25, 3)
	return Library.Anim.Speed
end
function Window:SetAnimSpeed(s) return Library:SetAnimSpeed(s) end

-- Draggable on-screen button. Phones have no hotkeys, so this is the quick-action key.
function Window:AddFloatingButton(cfg)
	if type(cfg) == "string" then cfg = { Name = cfg } end
	cfg = cfg or {}
	local win, T = self, self.Theme
	local size = cfg.Size or 56
	local linked = cfg.Flag and Library.Objects[cfg.Flag] ~= nil
	local toggle = cfg.Toggle == true or linked
	local state = linked and (Library.Flags[cfg.Flag] == true) or (cfg.Default == true)
	win._floatN = (win._floatN or 0) + 1
	local label = cfg.Text or tostring(cfg.Name or "F"):sub(1, 3)

	local btn = new("TextButton", {
		Name = "FloatingButton", AnchorPoint = Vector2.new(0.5, 0.5), AutoButtonColor = false, Text = "",
		Position = cfg.Position or UDim2.new(1, -(size / 2 + 14), 0.5, (win._floatN - 1) * (size + 10)),
		Size = UDim2.fromOffset(size, size), BackgroundColor3 = T.Panel, BorderSizePixel = 0,
		ZIndex = 30, Active = true, Parent = win.Gui,
	}, { new("UICorner", { CornerRadius = UDim.new(1, 0) }), stroke(T.Border, 1.5, 0.15) })
	local ring = btn:FindFirstChildOfClass("UIStroke")
	local txt = new("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = label, Font = T.FontBold,
		TextSize = math.floor(size * 0.3), TextColor3 = T.Text, ZIndex = 31, Parent = btn,
	}, { padding(4, 0, 4, 0) })
	local press = new("UIScale", { Scale = 1, Parent = btn })

	local function paint()
		if toggle then
			tween(btn, 0.15, { BackgroundColor3 = state and T.Accent or T.Panel })
			tween(txt, 0.15, { TextColor3 = state and Library.OnAccent(T.Accent) or T.Text })
			tween(ring, 0.15, { Color = state and T.Accent2 or T.Border })
		end
	end
	paint()

	local function tap()
		if linked then
			Library:ToggleFlag(cfg.Flag)
			return
		end
		if toggle then
			state = not state
			paint()
			safe(cfg.Callback, state)
			return
		end
		btn.BackgroundColor3 = T.Accent
		txt.TextColor3 = Library.OnAccent(T.Accent)
		tween(btn, 0.3, { BackgroundColor3 = T.Panel })
		tween(txt, 0.3, { TextColor3 = T.Text })
		safe(cfg.Callback)
	end

	if linked then
		table.insert(Library._flagCbs, function(flag, v)
			if flag == cfg.Flag and btn.Parent then
				state = v == true
				paint()
			end
		end)
	end

	btn.InputBegan:Connect(function(i)
		if not isPress(i) then return end
		local start = Vector2.new(i.Position.X, i.Position.Y)
		local origin = btn.AbsolutePosition + btn.AbsoluteSize / 2
		local moved = false
		tween(press, 0.08, { Scale = 0.92 })
		local conn = UserInputService.InputChanged:Connect(function(m)
			if m ~= i and m.UserInputType ~= Enum.UserInputType.MouseMovement then return end
			local d = Vector2.new(m.Position.X, m.Position.Y) - start
			if not moved and d.Magnitude < 8 then return end
			moved = true
			local vp, half = win.Gui.AbsoluteSize, size / 2
			local p = origin + d
			btn.Position = UDim2.fromOffset(math.clamp(p.X, half, vp.X - half), math.clamp(p.Y, half, vp.Y - half))
		end)
		onEnd(i, function()
			conn:Disconnect()
			tween(press, 0.18, { Scale = 1 }, BACK)
			if not moved then tap() end
		end)
	end)

	local obj = { Frame = btn }
	function obj:Set(v)
		state = v == true
		paint()
	end
	function obj:Get() return state end
	function obj:SetText(t) txt.Text = tostring(t) end
	function obj:SetVisible(v) btn.Visible = v ~= false end
	function obj:Destroy() btn:Destroy() end
	return obj
end

-- Wrapping chip group. Multi = true by default; Max limits the pick count.
function Section:CreateChips(cfg)
	cfg = cfg or {}
	local T = self.Window.Theme
	local options = {}
	local multi = cfg.Multi ~= false
	local selected = {}
	local chipH = 36

	local frame = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Parent = self.Body },
		{ list(6), padding(0, 4, 0, 4) })
	if cfg.Name then
		new("TextLabel", {
			LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = cfg.Name, Font = T.Font,
			TextSize = 14, TextColor3 = T.Text, TextXAlignment = LEFT, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
		})
	end
	local wrap = new("Frame", { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AY, BackgroundTransparency = 1, Parent = frame },
		{ new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Wraps = true, SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Top }) })
	local chips = {}

	local function picked()
		local out = {}
		for _, o in ipairs(options) do
			if selected[o] then out[#out + 1] = o end
		end
		return out
	end
	local function result()
		if multi then return picked() end
		return picked()[1]
	end
	local function paint(animate)
		for o, c in pairs(chips) do
			local on = selected[o] == true
			local props = {
				BackgroundColor3 = on and T.Accent or T.Control,
				TextColor3 = on and Library.OnAccent(T.Accent) or T.Text,
			}
			if animate then
				tween(c, 0.15, props)
			else
				for k, v in pairs(props) do c[k] = v end
			end
		end
	end
	local function commit(silent)
		paint(true)
		local out = result()
		setFlag(cfg, out)
		if not silent then safe(cfg.Callback, out) end
	end
	local function count()
		local n = 0
		for _ in pairs(selected) do n += 1 end
		return n
	end
	local function build(list2)
		for _, c in pairs(chips) do c:Destroy() end
		chips, options = {}, {}
		for i, o in ipairs(list2 or {}) do
			o = tostring(o)
			options[i] = o
			local c = new("TextButton", {
				LayoutOrder = i, Size = UDim2.fromOffset(0, chipH), AutomaticSize = AX, AutoButtonColor = false, Text = o,
				Font = T.Font, TextSize = 14, TextColor3 = T.Text, BackgroundColor3 = T.Control, BorderSizePixel = 0, Parent = wrap,
			}, { new("UICorner", { CornerRadius = UDim.new(0, chipH / 2) }), stroke(T.Border, 1, 0.5), padding(14, 0, 14, 0) })
			chips[o] = c
			c.MouseButton1Click:Connect(function()
				if multi then
					if not selected[o] and cfg.Max and count() >= cfg.Max then return end
					selected[o] = (not selected[o]) or nil
				elseif selected[o] and cfg.AllowNone then
					selected[o] = nil
				else
					selected = { [o] = true }
				end
				commit()
			end)
		end
		paint(false)
	end
	local function assign(v)
		selected = {}
		if type(v) == "table" then
			for k, x in pairs(v) do
				if x == true then selected[tostring(k)] = true else selected[tostring(x)] = true end
			end
		elseif v ~= nil then
			selected[tostring(v)] = true
		end
		if not multi then
			local first = picked()[1]
			selected = first and { [first] = true } or {}
		end
	end

	build(cfg.Options)
	assign(cfg.Default)
	paint(false)
	setFlag(cfg, result())
	self:_Register(frame, cfg.Name, (cfg.Name and 22 or 0) + chipH + 8)

	local obj = { Frame = frame }
	function obj:Set(v, silent)
		assign(v)
		commit(silent)
	end
	function obj:Get() return result() end
	function obj:Refresh(newOptions, keep)
		local prev = picked()
		build(newOptions)
		selected = {}
		if keep then
			for _, o in ipairs(prev) do
				if chips[o] then selected[o] = true end
			end
		end
		commit(true)
	end
	return regObj(cfg, obj)
end

-- Searchable dropdown of live players. Callback receives the Player (nil when cleared or left).
function Section:CreatePlayerPicker(cfg)
	cfg = cfg or {}
	local win = self.Window
	local players = game:GetService("Players")
	local me = players.LocalPlayer
	local byLabel, selected = {}, nil

	local function labelOf(p)
		if cfg.Display == "DisplayName" and p.DisplayName ~= p.Name then
			return p.DisplayName .. " (@" .. p.Name .. ")"
		end
		return p.Name
	end
	local function options()
		local out = {}
		byLabel = {}
		for _, p in ipairs(players:GetPlayers()) do
			if p ~= me or cfg.IncludeSelf then
				local l = labelOf(p)
				byLabel[l] = p
				out[#out + 1] = l
			end
		end
		table.sort(out, function(a, b) return a:lower() < b:lower() end)
		return out
	end

	local dd
	dd = self:CreateDropdown({
		Name = cfg.Name or "Player", Options = options(), Searchable = true, Placeholder = cfg.Placeholder or "Select player...",
		Callback = function(label)
			selected = byLabel[label]
			setFlag(cfg, selected and selected.Name or nil)
			safe(cfg.Callback, selected)
		end,
	})

	local function refresh()
		task.defer(function()
			if win._destroyed then return end
			local keepName = selected and selected.Name
			dd:Refresh(options(), false)
			local p = keepName and players:FindFirstChild(keepName)
			if p and p:IsA("Player") then
				selected = p
				dd:Set(labelOf(p), true)
			else
				local had = selected ~= nil
				selected = nil
				setFlag(cfg, nil)
				if had then safe(cfg.Callback, nil) end
			end
		end)
	end
	table.insert(win.Conns, players.PlayerAdded:Connect(refresh))
	table.insert(win.Conns, players.PlayerRemoving:Connect(refresh))

	local obj = { Frame = dd.Frame, Dropdown = dd }
	function obj:Get() return selected end
	function obj:GetName() return selected and selected.Name end
	function obj:Set(p, silent)
		if typeof(p) == "string" then p = players:FindFirstChild(p) end
		if typeof(p) ~= "Instance" or not p:IsA("Player") then return end
		selected = p
		dd:Set(labelOf(p), true)
		setFlag(cfg, p.Name)
		if not silent then safe(cfg.Callback, p) end
	end
	function obj:Refresh() refresh() end
	return regObj(cfg, obj)
end

-- Live FPS / ping / memory card. Updates only while the window is visible.
function Section:CreatePerformance(cfg)
	cfg = cfg or {}
	local win, T = self.Window, self.Window.Theme
	local interval = math.max(0.2, tonumber(cfg.Interval) or 0.5)
	local h = 50
	local frame = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = T.Control, BorderSizePixel = 0, Parent = self.Body },
		{ corner(10), stroke(T.Border, 1, 0.5) })
	local cells = {}
	for i, cap in ipairs({ "FPS", "PING", "MEM" }) do
		local cell = new("Frame", {
			Position = UDim2.fromScale((i - 1) / 3, 0), Size = UDim2.fromScale(1 / 3, 1), BackgroundTransparency = 1, Parent = frame,
		})
		cells[i] = new("TextLabel", {
			Position = UDim2.fromOffset(0, 6), Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = "-",
			Font = T.FontBold, TextSize = 17, TextColor3 = T.Accent, Parent = cell,
		})
		new("TextLabel", {
			Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Text = cap,
			Font = T.Font, TextSize = 11, TextColor3 = T.SubText, Parent = cell,
		})
	end
	local good, mid, bad = Color3.fromRGB(74, 222, 128), Color3.fromRGB(250, 204, 21), Color3.fromRGB(248, 113, 113)
	local last = { Fps = 0, Ping = 0, Memory = 0 }
	local frames, t0 = 0, os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		frames += 1
		local now = os.clock()
		if now - t0 < interval then return end
		local fps = frames / (now - t0)
		frames, t0 = 0, now
		if win.Visible == false then return end
		local ping = 0
		pcall(function() ping = StatsService.Network.ServerStatsItem["Data Ping"]:GetValue() end)
		local mem = 0
		pcall(function() mem = StatsService:GetTotalMemoryUsageMb() end)
		last.Fps, last.Ping, last.Memory = fps, ping, mem
		cells[1].Text = tostring(math.floor(fps + 0.5))
		cells[1].TextColor3 = fps >= 50 and good or (fps >= 30 and mid or bad)
		cells[2].Text = math.floor(ping + 0.5) .. " ms"
		cells[2].TextColor3 = ping <= 100 and good or (ping <= 200 and mid or bad)
		cells[3].Text = math.floor(mem + 0.5) .. " MB"
	end)
	table.insert(win.Conns, conn)
	frame.Destroying:Connect(function() conn:Disconnect() end)
	self:_Register(frame, cfg.Name or "Performance", h)
	local obj = { Frame = frame }
	function obj:Get() return { Fps = last.Fps, Ping = last.Ping, Memory = last.Memory } end
	return obj
end
end
-- Auto "Interface" section in the Settings tab: no setup needed.
do
local prevSettings = Window.CreateSettingsTab
function Window:CreateSettingsTab(...)
	local parts = prevSettings(self, ...)
	pcall(function()
		local tab = parts and parts.Tab
		if not tab or parts.InterfaceSection then return end
		local sec = tab:CreateSection({ Name = "Interface", Column = 1 })
		parts.InterfaceSection = sec
		sec:CreateSlider({
			Name = "UI Scale", Min = 0.6, Max = 1.6, Increment = 0.05, Default = Library.UserScale or 1,
			Callback = function(v) self:SetUIScale(v) end,
		})
		sec:CreateToggle({
			Name = "Icon-only sidebar", Default = self.Compact == true,
			Callback = function(v) self:SetCompact(v) end,
		})
		sec:CreateToggle({
			Name = "Two columns", Default = self.TwoCol == true,
			Callback = function(v) self:SetTwoColumn(v) end,
		})
		sec:CreatePerformance({})
	end)
	return parts
end
end
-- v3.23 additions: easy helper APIs (Loop, Track, Bind, Http, Webhook, Data, Character, shorthand controls).
do
local clock = os.clock
Library._cleanups = Library._cleanups or {}
Library._gen = Library._gen or 0

local function runCleanup(x)
	local t = typeof(x)
	if t == "RBXScriptConnection" then
		pcall(x.Disconnect, x)
	elseif t == "Instance" then
		pcall(x.Destroy, x)
	elseif t == "function" then
		pcall(x)
	elseif t == "table" then
		local f = x.Disconnect or x.Destroy or x.Stop or x.Close
		if type(f) == "function" then pcall(f, x) end
	end
end

-- Anything tracked here is cleaned up automatically on Library:Unload().
function Library:Track(x)
	if x ~= nil then table.insert(Library._cleanups, x) end
	return x
end
function Library:Connect(signal, fn)
	return Library:Track(signal:Connect(function(...) safe(fn, ...) end))
end
function Library:OnUnload(fn)
	if type(fn) == "function" then table.insert(Library._cleanups, fn) end
	return fn
end

local prevUnload = Library.Unload
function Library:Unload(...)
	Library._gen += 1
	local list = Library._cleanups
	Library._cleanups = {}
	for i = #list, 1, -1 do runCleanup(list[i]) end
	return prevUnload(self, ...)
end

-- Loop: Library:Loop("flag", 0.2, fn) runs only while the flag is true; Library:Loop(0.5, fn) runs right away.
function Library:Loop(flag, interval, fn)
	if type(flag) ~= "string" then flag, interval, fn = nil, flag, interval end
	if type(fn) ~= "function" then error("Library:Loop([flag,] interval, fn) needs a function", 2) end
	local h = { Interval = math.max(tonumber(interval) or 0.1, 0.03), Ticks = 0, Errors = 0, Flag = flag }
	local running, token, warned, watch = false, 0, false, nil
	local function start()
		if running then return end
		running = true
		token += 1
		local my = token
		task.spawn(function()
			while running and token == my do
				h.Ticks += 1
				local ok, err = pcall(fn, h)
				if not ok then
					h.Errors += 1
					if not warned then
						warned = true
						warn("[SpectreUI] Loop error: " .. tostring(err))
					end
				end
				task.wait(h.Interval)
			end
		end)
	end
	function h:Start() start() return self end
	function h:Stop()
		running = false
		token += 1
		return self
	end
	function h:IsRunning() return running end
	function h:SetInterval(s)
		self.Interval = math.max(tonumber(s) or self.Interval, 0.03)
		return self
	end
	function h:Destroy()
		running = false
		token += 1
		if watch then
			watch:Disconnect()
			watch = nil
		end
	end
	h.Disconnect = h.Destroy
	if flag then
		watch = Library:Watch(flag, function(v)
			if v then start() else h:Stop() end
		end)
		if Library.Flags[flag] then start() end
	else
		start()
	end
	return Library:Track(h)
end

-- Bind: like Watch, but also fires once now if the flag already has a value.
function Library:Bind(flag, fn)
	local c = Library:Watch(flag, fn)
	local v = Library.Flags[flag]
	if v ~= nil then safe(fn, v, nil) end
	return c
end

-- WaitFlag: yields until Flags[flag] == want (default true). Returns false on timeout or unload.
function Library:WaitFlag(flag, want, timeout)
	if want == nil then want = true end
	local gen = Library._gen
	local limit = clock() + (tonumber(timeout) or math.huge)
	while Library.Flags[flag] ~= want do
		if clock() >= limit or Library._gen ~= gen then return false end
		task.wait(0.1)
	end
	return true
end

-- Cooldown: `if Library:Cooldown("key", 3) then ... end` lets the code run at most once per 3 seconds.
local cds = {}
function Library:Cooldown(key, seconds)
	local now = clock()
	local untilT = cds[key]
	if untilT and untilT > now then return false, untilT - now end
	cds[key] = now + (tonumber(seconds) or 1)
	return true, 0
end

-- Try: pcall that warns instead of failing silently. Returns ok, ...
function Library:Try(fn, ...)
	local r = table.pack(pcall(fn, ...))
	if not r[1] then
		warn("[SpectreUI] Try error: " .. tostring(r[2]))
		return false, r[2]
	end
	return true, table.unpack(r, 2, r.n)
end

-- ===== HTTP =====
local function reqFn()
	return request or http_request or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request)
end

-- Library:Http({ Url, Method, Headers, Body (string|table), Json, Retries }) -> ok, res | err
-- res = { StatusCode, Body, Headers, Data } (Data = decoded JSON when Json = true)
function Library:Http(o)
	if type(o) == "string" then o = { Url = o } end
	o = o or {}
	local url = o.Url or o.url
	if type(url) ~= "string" or url == "" then return false, "no url" end
	local method = tostring(o.Method or (o.Body ~= nil and "POST" or "GET")):upper()
	local headers = {}
	for k, v in pairs(o.Headers or {}) do headers[k] = v end
	local body = o.Body
	if type(body) == "table" then
		local okj, enc = pcall(HttpService.JSONEncode, HttpService, body)
		if not okj then return false, "bad body: " .. tostring(enc) end
		body = enc
		if not headers["Content-Type"] then headers["Content-Type"] = "application/json" end
	end
	local req = reqFn()
	local tries = math.max(0, math.floor(tonumber(o.Retries) or 1))
	local last = "failed"
	for attempt = 0, tries do
		local res
		if req then
			local ok, r = pcall(req, { Url = url, Method = method, Headers = headers, Body = body })
			if ok and type(r) == "table" then res = r else last = tostring(r) end
		elseif method == "GET" then
			local ok, r = pcall(game.HttpGet, game, url, true)
			if ok then
				res = { Success = true, StatusCode = 200, Body = r, Headers = {} }
			else
				last = tostring(r)
			end
		else
			return false, "executor has no request function"
		end
		if res then
			local code = tonumber(res.StatusCode)
			if res.Success ~= false and (code == nil or (code >= 200 and code < 300)) then
				if o.Json then
					local okd, data = pcall(HttpService.JSONDecode, HttpService, tostring(res.Body or ""))
					if not okd then return false, "bad json", res end
					res.Data = data
				end
				return true, res
			end
			last = "HTTP " .. tostring(code or res.StatusMessage or "?")
			if code and code < 500 and code ~= 429 then return false, last, res end
		end
		if attempt < tries then task.wait(math.min(0.5 * 2 ^ attempt, 4)) end
	end
	return false, last
end

-- HttpGet(url, json) / HttpPost(url, body, json) -> ok, body | decoded | err
function Library:HttpGet(url, json)
	local ok, res = Library:Http({ Url = url, Json = json == true })
	if not ok then return false, res end
	if json then return true, res.Data end
	return true, res.Body
end
function Library:HttpPost(url, body, json)
	local ok, res = Library:Http({ Url = url, Method = "POST", Body = body, Json = json == true })
	if not ok then return false, res end
	if json then return true, res.Data end
	return true, res.Body
end

-- ===== Discord webhook =====
local function cut(s, n)
	s = tostring(s == nil and "" or s)
	local len = utf8.len(s)
	if not len then return s:sub(1, n) end
	if len > n then
		local at = utf8.offset(s, n - 2)
		s = s:sub(1, (at or n - 1) - 1) .. "..."
	end
	return s
end
local function colorInt(c)
	if typeof(c) == "Color3" then
		return math.floor(c.R * 255 + 0.5) * 65536 + math.floor(c.G * 255 + 0.5) * 256 + math.floor(c.B * 255 + 0.5)
	end
	if type(c) == "string" then
		local h = c:match("^#?(%x%x%x%x%x%x)$")
		return h and tonumber(h, 16) or nil
	end
	return tonumber(c)
end

-- Embed spec: { Title, Description, Url, Color (Color3|"#RRGGBB"|int), Fields = {{Name, Value, Inline}}, Footer, Image, Thumbnail, Timestamp = true }
function Library:Embed(e)
	e = e or {}
	local out = {}
	if e.Title then out.title = cut(e.Title, 256) end
	local desc = e.Description or e.Text
	if desc then out.description = cut(desc, 4096) end
	if e.Url then out.url = tostring(e.Url) end
	local col = colorInt(e.Color)
	if col then out.color = col end
	if type(e.Fields) == "table" then
		out.fields = {}
		for i, f in ipairs(e.Fields) do
			if i > 25 then break end
			local name = cut(f.Name or f[1], 256)
			local value = cut(f.Value or f[2], 1024)
			if name == "" then name = "\u{200B}" end
			if value == "" then value = "\u{200B}" end
			out.fields[#out.fields + 1] = { name = name, value = value, inline = f.Inline == true or f[3] == true }
		end
	end
	if e.Footer then out.footer = { text = cut(e.Footer, 2048) } end
	if e.Image then out.image = { url = tostring(e.Image) } end
	if e.Thumbnail then out.thumbnail = { url = tostring(e.Thumbnail) } end
	if e.Timestamp == true then out.timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ") end
	return out
end

-- Library:Webhook(url, "text")  |  Library:Webhook(url, { Title, Description, Fields... })  |  { Content, Username, Avatar, Embeds = {...} }
-- Never pings anyone. opts: { Retries, Async } -> ok, err
function Library:Webhook(url, payload, opts)
	if type(url) ~= "string" or not url:find("^https://") then return false, "bad webhook url" end
	opts = opts or {}
	local body
	if type(payload) == "string" then
		body = { content = cut(payload, 2000) }
	elseif type(payload) == "table" then
		if payload.content ~= nil or payload.embeds ~= nil then
			body = payload
		else
			body = {}
			if payload.Content then body.content = cut(payload.Content, 2000) end
			if payload.Username then body.username = cut(payload.Username, 80) end
			if payload.Avatar then body.avatar_url = tostring(payload.Avatar) end
			if type(payload.Embeds) == "table" then
				body.embeds = {}
				for i, e in ipairs(payload.Embeds) do
					if i > 10 then break end
					body.embeds[#body.embeds + 1] = Library:Embed(e)
				end
			elseif payload.Title or payload.Description or payload.Fields then
				body.embeds = { Library:Embed(payload) }
			end
			if not body.content and not body.embeds then return false, "empty payload" end
		end
	else
		return false, "payload must be a string or table"
	end
	body.allowed_mentions = body.allowed_mentions or { parse = {} }
	local function send()
		local ok, err = Library:Http({ Url = url, Method = "POST", Body = body, Retries = opts.Retries or 2 })
		if not ok then warn("[SpectreUI] Webhook failed: " .. tostring(err)) end
		return ok, (not ok) and err or nil
	end
	if opts.Async then
		task.spawn(send)
		return true
	end
	return send()
end

-- ===== Small persistent data (separate from UI configs): numbers, strings, booleans, plain tables =====
local DATA_DIR = "SpectreUI/data"
local mem = {}
local function fsOk()
	return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
end
local function dataPath(key)
	local k = tostring(key):gsub("[^%w_%-]", function(c) return string.format("%%%02X", c:byte()) end)
	return DATA_DIR .. "/" .. k:sub(1, 80) .. ".json"
end
local function ensureDir()
	if type(isfolder) == "function" and type(makefolder) == "function" then
		pcall(function()
			if not isfolder("SpectreUI") then makefolder("SpectreUI") end
			if not isfolder(DATA_DIR) then makefolder(DATA_DIR) end
		end)
	end
end
function Library:SaveData(key, value)
	mem[key] = value
	if not fsOk() then return false, "no filesystem" end
	local ok, enc = pcall(HttpService.JSONEncode, HttpService, { v = value })
	if not ok then return false, tostring(enc) end
	ensureDir()
	local okw, err = pcall(writefile, dataPath(key), enc)
	if not okw then return false, tostring(err) end
	return true
end
function Library:LoadData(key, default)
	if mem[key] ~= nil then return mem[key] end
	if fsOk() then
		local p = dataPath(key)
		local okf, exists = pcall(isfile, p)
		if okf and exists then
			local okr, raw = pcall(readfile, p)
			if okr then
				local okd, data = pcall(HttpService.JSONDecode, HttpService, raw)
				if okd and type(data) == "table" and data.v ~= nil then
					mem[key] = data.v
					return data.v
				end
			end
		end
	end
	return default
end
function Library:DeleteData(key)
	mem[key] = nil
	if fsOk() and type(delfile) == "function" then
		local p = dataPath(key)
		pcall(function()
			if isfile(p) then delfile(p) end
		end)
	end
	return true
end

-- ===== Character helpers =====
-- Library:Character(timeout) -> char, humanoid, rootPart (waits until all three exist; nil on timeout)
function Library:Character(timeout)
	local lp = Players.LocalPlayer
	if not lp then return nil end
	local limit = clock() + (tonumber(timeout) or 10)
	while true do
		local char = lp.Character
		if char and char.Parent then
			local hum = char:FindFirstChildOfClass("Humanoid")
			local root = char:FindFirstChild("HumanoidRootPart")
			if hum and root then return char, hum, root end
		end
		if clock() >= limit then return nil end
		task.wait(0.1)
	end
end

-- Library:OnRespawn(function(char, humanoid, root) end): runs now (if alive) and after every respawn.
function Library:OnRespawn(fn)
	local lp = Players.LocalPlayer
	if not lp or type(fn) ~= "function" then return nil end
	local gone = false
	local function fire(char)
		task.spawn(function()
			local hum = char:WaitForChild("Humanoid", 10)
			local root = char:WaitForChild("HumanoidRootPart", 10)
			if not gone and hum and root and char.Parent then safe(fn, char, hum, root) end
		end)
	end
	local conn = lp.CharacterAdded:Connect(fire)
	if lp.Character then fire(lp.Character) end
	return Library:Track({
		Disconnect = function()
			gone = true
			conn:Disconnect()
		end,
	})
end

-- ===== Shorthand controls: sec:Toggle("Auto Farm", false, function(v) end) =====
-- Flag is generated from the name when you don't give one, so Config still saves the value.
local function hash(s)
	local h = 5381
	for i = 1, #s do h = (h * 33 + s:byte(i)) % 4294967296 end
	return string.format("%x", h)
end
local function autoFlag(name)
	name = tostring(name or "control")
	local base = name:lower():gsub("[^%w]+", "_"):gsub("^_+", ""):gsub("_+$", "")
	if base == "" then base = "c" .. hash(name) end
	base = base:sub(1, 24)
	local flag, n = base, 1
	while Library.Objects[flag] ~= nil or Library.Flags[flag] ~= nil do
		n += 1
		flag = base .. "_" .. n
	end
	return flag
end
local function shorthand(method, build)
	Section[method] = function(self, ...)
		local first = ...
		local cfg
		if type(first) == "table" then
			cfg = first
		else
			cfg = build(...)
		end
		if cfg.Flag == nil and method ~= "Button" and method ~= "Label" then cfg.Flag = autoFlag(cfg.Name) end
		return self["Create" .. method](self, cfg)
	end
end
-- callback may be passed in place of the value: sec:Toggle("X", function(v) end)
local function cbShift(value, cb, flag)
	if type(value) == "function" then return nil, value, cb end
	return value, cb, flag
end
shorthand("Toggle", function(name, default, cb, flag)
	default, cb, flag = cbShift(default, cb, flag)
	return { Name = name, Default = default == true, Callback = cb, Flag = flag }
end)
shorthand("Slider", function(name, min, max, default, cb, flag)
	default, cb, flag = cbShift(default, cb, flag)
	return { Name = name, Min = min or 0, Max = max or 100, Default = default or min or 0, Callback = cb, Flag = flag }
end)
shorthand("Dropdown", function(name, options, default, cb, flag)
	default, cb, flag = cbShift(default, cb, flag)
	options = options or {}
	return { Name = name, Options = options, Default = default or options[1], Callback = cb, Flag = flag }
end)
shorthand("Textbox", function(name, default, cb, flag)
	default, cb, flag = cbShift(default, cb, flag)
	return { Name = name, Default = default or "", Callback = cb, Flag = flag }
end)
shorthand("Keybind", function(name, key, cb, mode, flag)
	key, cb, mode = cbShift(key, cb, mode)
	return { Name = name, Default = key, Callback = cb, Mode = mode, Flag = flag }
end)
shorthand("ColorPicker", function(name, color, cb, flag)
	color, cb, flag = cbShift(color, cb, flag)
	return { Name = name, Default = color or Color3.new(1, 1, 1), Callback = cb, Flag = flag }
end)
Section.Color = Section.ColorPicker
shorthand("Button", function(name, cb) return { Name = name, Callback = cb } end)
shorthand("Label", function(text) return { Text = text } end)

-- Window:AddTab("Main", "lucide:home", function(tab) ... end)  |  tab:AddSection("Farm", 1)
function Window:AddTab(name, icon, build)
	if type(name) == "table" then return self:CreateTab(name) end
	if type(icon) == "function" then build, icon = icon, nil end
	return self:CreateTab({ Name = name, Icon = icon, Build = build })
end
function Tab:AddSection(name, column)
	if type(name) == "table" then return self:CreateSection(name) end
	return self:CreateSection({ Name = name, Column = column })
end
end
if Library.Perf.LowPower == nil then Library:SetQuality("high") end
Library.Version = "3.23"
return Library
