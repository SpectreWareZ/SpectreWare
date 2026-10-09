-- NEVER TOWN | SpectreWare by #CaptainZ v1.6.12 (Performance Optimized by Bread)
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer

-- ══════════════════════════════════════════════════════════════
-- Splash intro: transparent-background logo + title + thin loading line.
-- Falls back to a dotted "S" if the logo asset cannot be loaded.
-- Tweak the look via Splash.CFG.
-- ══════════════════════════════════════════════════════════════
local Splash = {
    alive = false,
    finishing = false,
    target = 0,
    shown = 0,
    t0 = os.clock(),
    CFG = {
        Title = "SPECTREWARE",
        ShowTitle = true,
        ShowStatus = true,
        ShowPercent = true,
        LogoTime = 2.2, -- โลโก้แสดงอย่างน้อยกี่วินาที ก่อนเริ่มสร้าง UI
        HoldTime = 0.4, -- ค้างโลโก้หลังโหลดครบ ก่อนจาง
        IntroTime = 1.0, -- รอเฟดเข้าให้จบก่อนคอมไพล์ไลบรารี (กันเฟดเข้าสะดุด)
        Blur = 0, -- ความเบลอฉากเกม (0 = ไม่เบลอ) — ยิ่งสูงยิ่งกินเครื่อง โดยเฉพาะมือถือ | v6 = 12
        Dim = 1, -- ความโปร่งของพื้นมืด (1 = ไม่มีพื้นหลังเลย, 0 = ทึบสุด) | v6 = 0.12
        LogoSize = 0.46, -- ขนาดโลโก้ เทียบความสูงจอ
        Speed = 2.6,
        Feather = 0.10, -- ความนุ่มของขอบตอนเผยโลโก้ (สัดส่วนความสูงโลโก้)
        Ghost = 0.5, -- ความเข้มเงาโลโก้ส่วนที่ยังไม่เผย (0 = ไม่มีเงา, 1 = เข้มสุด)
        Weight = 0.15, -- [fallback จุด] ความหนาริบบิ้น
        Density = 0.22, -- [fallback จุด] ระยะห่างจุดบนเส้น S เทียบขนาดจุด
        -- ── พาเลตสีตามโลโก้: ลาเวนเดอร์อ่อน + ม่วงกลาง ──
        C1 = Color3.fromRGB(228, 216, 250), -- ริบบิ้นด้านนอก (ลาเวนเดอร์อ่อน) / เส้นโหลดช่วงต้น
        C2 = Color3.fromRGB(148, 98, 224), -- ส่วนพับด้านใน (ม่วงกลาง) / เส้นโหลดช่วงท้าย
        Bg = Color3.fromRGB(32, 16, 56), -- ม่วงเข้ม (ขอบตัวหนังสือ / พื้นมืดถ้าเปิด Dim)
        Unlit = Color3.fromRGB(62, 44, 100), -- สีเงาโลโก้ส่วนที่ยังไม่ถูกเผย
        TitleText = Color3.fromRGB(240, 232, 255), -- สีชื่อ (ไล่ไปตาม C1→C2 อ่อนๆ)
        SubText = Color3.fromRGB(170, 150, 215), -- สีข้อความสถานะ / เปอร์เซ็นต์
    },
}

function Splash.set(p, text)
    if not Splash.alive then return end
    Splash.target = math.max(Splash.target, math.min(p, 1))
    if text and Splash.status and Splash.status.Text ~= text then Splash.status.Text = text end
end

-- รอให้แอนิเมชันเฟดเข้าเล่นจบก่อน แล้วค่อยทำงานหนักๆ (เช่น คอมไพล์ไลบรารี)
function Splash.waitIntro()
    while Splash.alive and os.clock() - Splash.t0 < Splash.CFG.IntroTime do
        task.wait()
    end
end

-- รอให้โลโก้เผยเกือบครบ (minP) + ครบเวลาขั้นต่ำ ก่อนเริ่มสร้าง UI
-- ช่วงสุดท้ายจะถูกเติมตอน Splash.finish() หลังสร้าง UI เสร็จ (ตอนนั้นเธรดว่าง เฟรมลื่น)
function Splash.waitLogo(minP)
    minP = minP or 0.9
    Splash.set(minP)
    while Splash.alive and (Splash.shown < minP or os.clock() - Splash.t0 < Splash.CFG.LogoTime) do
        task.wait()
    end
end

function Splash.destroy()
    Splash.alive = false
    if Splash.onReveal then pcall(Splash.onReveal) end -- Splash ปิดหลังสร้างครบ (รวมกรณีพังกลางทาง) → ต้องเปิด UI เสมอ
    pcall(function()
        if Splash.hb then Splash.hb:Disconnect() end
    end)
    pcall(function()
        if Splash.gui then Splash.gui:Destroy() end
    end)
    pcall(function()
        if Splash.blur then Splash.blur:Destroy() end
    end)
end

function Splash.flash()
    if not Splash.flashT then Splash.flashT = os.clock() end
end

function Splash.finish()
    if not Splash.alive or Splash.finishing then return end
    Splash.finishing = true
    Splash.set(1, "Ready")
    task.spawn(function()
        while Splash.alive and Splash.shown < 1 do
            task.wait()
        end
        if not Splash.alive then return end
        Splash.flash() -- เอฟเฟกต์ตอนโหลดครบ (โลโก้เด้งเบาๆ / โหมดจุดมีแสงวิ่ง) ตอนเธรดว่างแล้ว
        task.wait(Splash.CFG.HoldTime + 0.45) -- ให้เอฟเฟกต์จบ + ค้างแป๊บ
        if not Splash.alive then return end
        if Splash.onReveal then pcall(Splash.onReveal) end -- โหลดครบแล้ว → เปิดหน้าต่าง UI
        Splash.fadeT = os.clock() -- โลโก้จางด้วยลูปหลัก (อิงเวลา) ส่วนที่เหลือใช้ Tween
        pcall(function()
            local TS = game:GetService("TweenService")
            local ti = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            if Splash.dim then TS:Create(Splash.dim, ti, { BackgroundTransparency = 1 }):Play() end
            TS:Create(Splash.title, ti, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
            TS:Create(Splash.track, ti, { BackgroundTransparency = 1 }):Play()
            TS:Create(Splash.fill, ti, { BackgroundTransparency = 1 }):Play()
            TS:Create(Splash.scale, ti, { Scale = 1.04 }):Play()
            if Splash.status then TS:Create(Splash.status, ti, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play() end
            if Splash.pct then TS:Create(Splash.pct, ti, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play() end
            if Splash.blur then TS:Create(Splash.blur, ti, { Size = 0 }):Play() end
        end)
        task.wait(0.65)
        Splash.destroy()
    end)
end

-- ── โลโก้ S (PNG โปร่งใส 560×560) — ไม่ฝัง base64 ในสคริปต์แล้ว โหลดจากลิงก์/asset แทน ──
-- ใส่อย่างใดอย่างหนึ่ง (ว่างทั้งคู่ = ใช้เส้น S แบบจุดแทน):
--   LogoAssetId = "rbxassetid://เลขรูป"            ← อัปโหลดรูปเป็น Decal/Image บน Roblox (ใช้ได้ทุก executor)
--   LogoURL     = "https://raw.githubusercontent.com/<user>/<repo>/refs/heads/main/SpectreWare_Logo_v1.png"
-- ถ้าเปลี่ยนรูปที่ลิงก์ ให้เปลี่ยนชื่อไฟล์ LOGO_FILE ด้านล่างด้วย (ไม่งั้นจะใช้รูปเก่าที่เก็บไว้ในเครื่อง)
Splash.LogoAssetId = "rbxassetid://126278949078492"
Splash.LogoURL = ""

if
    not pcall(function()
        local C = Splash.CFG
        local TS = game:GetService("TweenService")
        local ES, ED = Enum.EasingStyle, Enum.EasingDirection
        local mclamp, msin, mcos, mfloor, mabs, mexp = math.clamp, math.sin, math.cos, math.floor, math.abs, math.exp
        local WHITE = Color3.new(1, 1, 1)
        local CENTER = Vector2.new(0.5, 0.5)
        local LOGO_FILE = "SpectreWare_Logo_v1.png" -- ชื่อไฟล์โลโก้ที่เขียนลง workspace ของ executor

        -- ขนาดตัวอักษรคงที่ตามความสูงจอ (แทน TextScaled ที่คำนวณใหม่ทุกครั้งที่ข้อความเปลี่ยน)
        local cam = workspace.CurrentCamera
        local vh = (cam and cam.ViewportSize.Y > 0) and cam.ViewportSize.Y or 720
        local function txtSize(f) return mclamp(mfloor(vh * f + 0.5), 11, 22) end

        local function new(class, props, parent)
            local o = Instance.new(class)
            for k, v in pairs(props) do
                o[k] = v
            end
            if parent then o.Parent = parent end
            return o
        end
        local function circ(o)
            new("UICorner", { CornerRadius = UDim.new(1, 0) }, o)
            return o
        end

        local gui = new("ScreenGui", {
            Name = "SW_Splash",
            ResetOnSpawn = false,
            IgnoreGuiInset = true,
            DisplayOrder = 100000,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        })
        Splash.gui = gui
        local okp = pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
        if not okp or not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

        -- พื้นมืด: ปิดเป็นค่าเริ่มต้น (Dim = 1 → ไม่สร้างเลย) | เบลอฉากเกม: ปิดเป็นค่าเริ่มต้น (Blur = 0)
        local dim
        if C.Dim < 1 then
            dim = new("Frame", {
                Name = "Dim",
                Size = UDim2.fromScale(1, 1),
                BorderSizePixel = 0,
                BackgroundColor3 = C.Bg,
                BackgroundTransparency = 1,
            }, gui)
        end
        Splash.dim = dim

        if C.Blur > 0 then
            local okb, b = pcall(function() return new("BlurEffect", { Name = "SW_SplashBlur", Size = 0 }, game:GetService("Lighting")) end)
            if okb then Splash.blur = b end
        end

        local holder = new("Frame", {
            Name = "Holder",
            BackgroundTransparency = 1,
            AnchorPoint = CENTER,
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromScale(1, 1),
        }, gui)
        local sc = new("UIScale", { Scale = 0.94 }, holder)
        Splash.scale = sc

        local logoY = C.ShowTitle and 0.42 or 0.5
        local stage = new("Frame", {
            Name = "Stage",
            BackgroundTransparency = 1,
            AnchorPoint = CENTER,
            Position = UDim2.fromScale(0.5, logoY),
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            Size = UDim2.fromScale(C.LogoSize, C.LogoSize),
        }, holder)
        local press = new("UIScale", { Scale = 1 }, stage)
        -- Frame ธรรมดา (ไม่ใช่ CanvasGroup) — การเฟดโลโก้ทำที่ความโปร่งของแต่ละชิ้นในลูปหลัก
        local lg = new("Frame", { Name = "Logo", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, stage)
        Splash.logo = lg

        local FEATHER = math.max(C.Feather, 0.01)
        local paint = function() end -- ถูกแทนที่ด้วย useImage / useDots ด้านล่าง: paint(ความคืบหน้า, แสงวิ่ง, ความโปร่งรวม, ความโปร่งเปลี่ยนไหม)

        -- ══ หาโลโก้ → คืนรหัสรูป หรือ nil ถ้าไม่ได้ (แล้วจะ fallback เป็นเส้น S แบบจุด) ══
        -- ลำดับ: (1) Splash.LogoAssetId = rbxassetid://... ใช้ได้เลย ไม่ต้องพึ่งฟังก์ชันไฟล์ของ executor
        --        (2) Splash.LogoURL = ลิงก์ PNG → โหลดครั้งเดียวเก็บใน workspace (รอบหน้าอ่านจากไฟล์ ไม่โหลดซ้ำ)
        local function isPng(d) return type(d) == "string" and #d > 8 and d:sub(2, 4) == "PNG" end
        local function logoAsset()
            local id = Splash.LogoAssetId
            if type(id) == "string" and id ~= "" then return id end
            local url = Splash.LogoURL
            local wf, gca = writefile, (getcustomasset or getsynasset)
            if type(url) ~= "string" or url == "" or type(wf) ~= "function" or type(gca) ~= "function" then return nil end
            local ok, res = pcall(function()
                local cached = false
                if type(isfile) == "function" and type(readfile) == "function" then
                    local okf, has = pcall(isfile, LOGO_FILE)
                    if okf and has then
                        local okr, cur = pcall(readfile, LOGO_FILE)
                        cached = okr and isPng(cur)
                    end
                end
                if not cached then
                    local data = game:HttpGet(url, true)
                    if not isPng(data) then return nil end -- ลิงก์ผิด/404/ได้หน้าเว็บมาแทนรูป
                    wf(LOGO_FILE, data)
                    -- กัน executor ที่เขียนไบนารีเพี้ยน: อ่านกลับมาต้องตรงเป๊ะ ไม่งั้นใช้ fallback
                    if type(readfile) == "function" and readfile(LOGO_FILE) ~= data then return nil end
                end
                return gca(LOGO_FILE)
            end)
            if ok and type(res) == "string" and res ~= "" then return res end
            return nil
        end

        -- ══ โหมดรูป: โลโก้จริง (โปร่งใส) 2 ชั้น = เงาส่วนที่ยังไม่เผย + ตัวจริงที่เผยจากบนลงล่างด้วย UIGradient ══
        local function useImage(asset)
            local GHOST = mclamp(C.Ghost or 0.5, 0, 1)
            local Y0, Y1 = 54 / 560, 507 / 560 -- ขอบบน/ล่างของตัว S ในภาพ (สัดส่วนความสูงภาพ)
            local function mk(name, col, z)
                return new("ImageLabel", {
                    Name = name,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.fromScale(1, 1),
                    Image = asset,
                    ScaleType = Enum.ScaleType.Fit,
                    ImageColor3 = col,
                    ImageTransparency = 1,
                    ZIndex = z,
                }, lg)
            end
            local ghost = mk("Unlit", C.Unlit, 1)
            local lit = mk("Lit", WHITE, 2)
            local wipe = new("UIGradient", { Rotation = 90 }, lit) -- Rotation 90 = ไล่จากบนลงล่าง
            local lastW, lastL, lastG = -1, -1, -1
            paint = function(sh, sheen, la, laChanged)
                -- เผยโลโก้จากบนลงล่างตามความคืบหน้า (ขอบนุ่ม FEATHER) — เขียนเฉพาะตอนค่าเปลี่ยน
                local w = (sh >= 0.9995) and 1 or mfloor(sh * 1000 + 0.5) / 1000
                if w ~= lastW then
                    lastW = w
                    if w >= 1 then
                        wipe.Transparency = NumberSequence.new(0)
                    else
                        local e0 = mclamp(Y0 - FEATHER + (Y1 - Y0 + FEATHER) * w, 0.001, 0.996)
                        local e1 = mclamp(e0 + FEATHER, e0 + 0.002, 0.999)
                        wipe.Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0),
                            NumberSequenceKeypoint.new(e0, 0),
                            NumberSequenceKeypoint.new(e1, 1),
                            NumberSequenceKeypoint.new(1, 1),
                        })
                    end
                end
                -- ความโปร่ง: ตัวจริงตามค่าเฟด la | เงาจางหายเมื่อเผยใกล้ครบ (ตอนครบ = โลโก้ล้วนเหมือนรูปเป๊ะ)
                local tl = 1 - la
                if tl ~= lastL then
                    lastL = tl
                    lit.ImageTransparency = tl
                end
                local ga = GHOST * (1 - mclamp((sh - 0.86) / 0.14, 0, 1))
                local tg = 1 - la * ga
                if tg ~= lastG then
                    lastG = tg
                    ghost.ImageTransparency = tg
                end
            end
        end

        -- ══ โหมด fallback: เส้น S แบบจุด (v6) — ใช้เมื่อ executor ไม่รองรับการโหลดรูปจากไฟล์ ══
        local function useDots()
            -- ตัว S แบบริบบิ้นพับ: แถบบน → โค้งซ้าย → แถบกลาง(ม่วงเข้ม) → โค้งขวา → แถบล่าง
            -- พิกัดด้านล่างวัดจากรูปโลโก้ (หน่วยพิกเซลของรูป) แล้วแปลงเป็นสัดส่วนของ stage ด้วย LG_SCALE
            -- เส้นทางเขียนจากปลายบนขวา → ปลายล่างซ้าย | สีแต่ละจุดไล่จาก C1 (ริบบิ้นด้านนอก) → C2 (ส่วนพับด้านใน)
            local T = mclamp(C.Weight, 0.06, 0.22) -- ความหนาริบบิ้น (สัดส่วน stage)
            local LG_SCALE, LG_CX, LG_CY = 560, 377.5, 354
            local RR = 91 -- รัศมีเส้นกลางของโค้ง
            local X_TIP_TOP, X_L, X_R, X_TIP_BOT = 570, 303, 452, 190
            local Y1, Y2, Y3 = 173, 355, 537 -- แถบบน / กลาง / ล่าง (เส้นกลาง)
            local sstep = function(u) return u * u * (3 - 2 * u) end
            local segs = {
                { len = X_TIP_TOP - X_L, f = 0, pos = function(u) return X_TIP_TOP - (X_TIP_TOP - X_L) * u, Y1 end },
                {
                    len = math.pi * RR,
                    fn = function(u) return sstep(u) end, -- โค้งซ้าย: ริบบิ้นอ่อน → ส่วนพับเข้ม
                    pos = function(u)
                        local t = math.pi * u
                        return X_L - RR * msin(t), (Y1 + RR) - RR * mcos(t)
                    end,
                },
                { len = X_R - X_L, f = 1, pos = function(u) return X_L + (X_R - X_L) * u, Y2 end },
                {
                    len = math.pi * RR,
                    fn = function(u) return 1 - sstep(u) end, -- โค้งขวา: ส่วนพับเข้ม → ริบบิ้นอ่อน
                    pos = function(u)
                        local t = math.pi * u
                        return X_R + RR * msin(t), (Y2 + RR) - RR * mcos(t)
                    end,
                },
                { len = X_R - X_TIP_BOT, f = 0, pos = function(u) return X_R - (X_R - X_TIP_BOT) * u, Y3 end },
            }
            local totalLen = 0
            for _, sg in ipairs(segs) do
                totalLen = totalLen + sg.len
            end

            local dimC = C.Unlit -- สีเส้นที่ยังไม่ถูกเขียน
            local dots, nDots = {}, 0
            local function put(px, py, sPar, f)
                local x, y = 0.5 + (px - LG_CX) / LG_SCALE, 0.5 + (py - LG_CY) / LG_SCALE
                local fr = circ(new("Frame", {
                    BorderSizePixel = 0,
                    BackgroundColor3 = dimC,
                    BackgroundTransparency = 1,
                    AnchorPoint = CENTER,
                    Position = UDim2.fromScale(x, y),
                    Size = UDim2.fromScale(T, T),
                }, lg))
                nDots = nDots + 1
                dots[nDots] = { f = fr, s = sPar, c = C.C1:Lerp(C.C2, f), key = -1 }
            end
            local stepPx = T * LG_SCALE * mclamp(C.Density, 0.08, 0.5)
            local N = math.ceil(totalLen / stepPx)
            for i = 0, N do
                local d = totalLen * (i / N)
                local acc = 0
                for _, sg in ipairs(segs) do
                    if d <= acc + sg.len or sg == segs[#segs] then
                        local u = mclamp((d - acc) / sg.len, 0, 1)
                        local px, py = sg.pos(u)
                        put(px, py, i / N, sg.fn and sg.fn(u) or sg.f)
                        break
                    end
                    acc = acc + sg.len
                end
            end

            -- เขียนค่าเฉพาะจุดที่สีเปลี่ยนจริง (key) และเขียนความโปร่งเฉพาะตอนที่ค่าเฟดเปลี่ยน (laChanged)
            paint = function(sh, sheen, la, laChanged)
                local head = sh * (1 + FEATHER)
                local tr = 1 - la
                for i = 1, nDots do
                    local d = dots[i]
                    local a = mclamp((head - d.s) / FEATHER, 0, 1)
                    local k = 0
                    if sheen then k = mclamp(1 - mabs(d.s - sheen) / 0.16, 0, 1) end
                    local key = mfloor(a * 255) + mfloor(k * 255) * 256
                    if key ~= d.key then
                        d.key = key
                        local col = dimC:Lerp(d.c, a * a * (3 - 2 * a))
                        if k > 0 then col = col:Lerp(WHITE, 0.6 * k * k) end
                        d.f.BackgroundColor3 = col
                    end
                    if laChanged then d.f.BackgroundTransparency = tr end
                end
            end
        end

        -- เลือกโหมด: มีรูป (ปกติ) → useImage | โหลดรูปไม่ได้/พัง → useDots
        local asset = logoAsset()
        local okImg = false
        if asset then
            okImg = pcall(useImage, asset)
            if not okImg then pcall(function() lg:ClearAllChildren() end) end
        end
        if not okImg then useDots() end
        Splash.mode = okImg and "image" or "dots"
        paint(0, nil, 0, true)

        -- ชื่อ: ตัวหนาสีขาวเรียบๆ + ขอบเข้มบางๆ (ไม่มีพื้นหลังแล้ว กันกลืนกับฉากเกม) — ตั้งข้อความครั้งเดียว ใช้ TextScaled ได้
        local title = new("TextLabel", {
            Name = "Title",
            BackgroundTransparency = 1,
            Visible = C.ShowTitle,
            AnchorPoint = CENTER,
            Position = UDim2.fromScale(0.5, 0.75),
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            Size = UDim2.fromScale(1.2, 0.05),
            TextScaled = true,
            Font = Enum.Font.GothamBold,
            Text = C.Title,
            TextColor3 = C.TitleText,
            TextTransparency = 1,
            TextStrokeColor3 = C.Bg,
            TextStrokeTransparency = 1,
        }, holder)
        Splash.title = title
        -- ไล่สีชื่อเบาๆ ขาว → ไซยานอ่อน → ม่วงอ่อน (UIGradient คงที่ ไม่กินเฟรม)
        new("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, C.TitleText),
                ColorSequenceKeypoint.new(0.5, C.TitleText:Lerp(C.C1, 0.35)),
                ColorSequenceKeypoint.new(1, C.TitleText:Lerp(C.C2, 0.45)),
            }),
        }, title)

        -- เส้นโหลดบางๆ + ข้อความสถานะซ้าย + เปอร์เซ็นต์ขวา
        local barY = C.ShowTitle and 0.84 or 0.78
        local box = new("Frame", {
            Name = "Bar",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AnchorPoint = CENTER,
            Position = UDim2.fromScale(0.5, barY),
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            Size = UDim2.fromScale(0.6, 0.06),
        }, holder)
        local track = circ(new("Frame", {
            Name = "BarTrack",
            BorderSizePixel = 0,
            BackgroundColor3 = C.Unlit,
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 0, 0, 2),
            Size = UDim2.new(1, 0, 0, 3),
        }, box))
        local fill = circ(new("Frame", {
            Name = "BarFill",
            BorderSizePixel = 0,
            BackgroundColor3 = C.C1,
            Size = UDim2.fromScale(0, 1),
        }, track))
        Splash.track, Splash.fill = track, fill

        if C.ShowStatus then
            Splash.status = new("TextLabel", {
                Name = "Status",
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0, 0.4),
                Size = UDim2.fromScale(0.75, 0.4),
                TextScaled = false,
                TextSize = txtSize(0.02),
                Font = Enum.Font.Gotham,
                Text = "",
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = C.SubText,
                TextTransparency = 1,
                TextStrokeColor3 = C.Bg,
                TextStrokeTransparency = 1,
            }, box)
        end
        if C.ShowPercent then
            Splash.pct = new("TextLabel", {
                Name = "Percent",
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.fromScale(1, 0.4),
                Size = UDim2.fromScale(0.2, 0.4),
                TextScaled = false,
                TextSize = txtSize(0.02),
                Font = Enum.Font.Gotham,
                Text = "0%",
                TextXAlignment = Enum.TextXAlignment.Right,
                TextColor3 = C.SubText,
                TextTransparency = 1,
                TextStrokeColor3 = C.Bg,
                TextStrokeTransparency = 1,
            }, box)
        end

        -- ══ ลูปหลัก (อิงเวลาจริง ไม่ผูกกับเฟรมเรต) ══
        local introT0 = os.clock()
        local lastShown, lastSheen, lastPct, lastLA, lastPop = -1, false, -1, -1, 0

        local function update(dt)
            dt = math.min(dt, 0.1)
            local now = os.clock()

            -- ความคืบหน้า: exp smoothing (ไม่ขึ้นกับเฟรมเรต) + ค่าคืบขั้นต่ำกันค้าง
            local full = Splash.target >= 1
            local goal = full and 1 or math.min(Splash.target + 0.06, 0.97)
            local d = goal - Splash.shown
            if d > 0 then
                local stepv = math.max(d * (1 - mexp(-C.Speed * dt)), math.min(d, dt * 0.05))
                Splash.shown = Splash.shown + stepv
                if full and Splash.shown > 0.996 then Splash.shown = 1 end
            end
            local sh = Splash.shown

            -- ความโปร่งของโลโก้: เฟดเข้า 0.7 วิ / เฟดออกตอน finish 0.6 วิ (อิงเวลา)
            local fi = mclamp((now - introT0) / 0.7, 0, 1)
            local la = 1 - (1 - fi) * (1 - fi)
            if Splash.fadeT then
                local fo = mclamp((now - Splash.fadeT) / 0.6, 0, 1)
                la = la * (1 - fo * fo)
            end
            la = mfloor(la * 100 + 0.5) / 100
            local laCh = la ~= lastLA

            -- เอฟเฟกต์ตอนโหลดครบ (เริ่มจาก Splash.flash() ตอน finish): แสงวิ่งผ่านตัว S (โหมดจุด) + โลโก้เด้งเบาๆ
            local sheen, pop = nil, 0
            if Splash.flashT then
                local ft = now - Splash.flashT
                if ft < 0.85 then
                    local p = ft / 0.85
                    sheen = -0.16 + 1.32 * (p * p * (3 - 2 * p))
                end
                if ft < 0.5 then pop = 0.02 * msin(math.pi * ft / 0.5) end
            end

            local sOn = sheen ~= nil
            local shCh = (sh >= 1 and lastShown < 1) or mabs(sh - lastShown) >= 0.0007
            if shCh or laCh or sOn or lastSheen then
                paint(sh, sheen, la, laCh)
                lastLA, lastSheen = la, sOn
                if shCh then
                    lastShown = sh
                    fill.Size = UDim2.fromScale(sh, 1)
                    fill.BackgroundColor3 = C.C1:Lerp(C.C2, sh)
                end
            end

            local pc = mfloor(sh * 100 + 0.5)
            if pc ~= lastPct then
                lastPct = pc
                if Splash.pct then Splash.pct.Text = pc .. "%" end
            end

            if pop ~= lastPop then
                lastPop = pop
                press.Scale = 1 + pop
            end
        end
        Splash.hb = RunService.RenderStepped:Connect(function(dt)
            if not pcall(update, dt) then Splash.destroy() end
        end)

        -- เข้าฉาก: แค่เฟดเข้าเบาๆ (โลโก้เฟดในลูปหลักแล้ว) — พื้นมืด/เบลอ ทำเฉพาะตอนเปิดใช้ (Dim < 1 / Blur > 0)
        if dim then TS:Create(dim, TweenInfo.new(0.5, ES.Quad, ED.Out), { BackgroundTransparency = C.Dim }):Play() end
        TS:Create(sc, TweenInfo.new(0.9, ES.Quad, ED.Out), { Scale = 1 }):Play()
        local tiT = TweenInfo.new(0.7, ES.Quad, ED.Out, 0, false, 0.25)
        TS:Create(title, tiT, { TextTransparency = 0, TextStrokeTransparency = 0.5 }):Play()
        TS:Create(track, tiT, { BackgroundTransparency = 0.35 }):Play()
        if Splash.status then TS:Create(Splash.status, tiT, { TextTransparency = 0, TextStrokeTransparency = 0.5 }):Play() end
        if Splash.pct then TS:Create(Splash.pct, tiT, { TextTransparency = 0, TextStrokeTransparency = 0.5 }):Play() end
        if Splash.blur then TS:Create(Splash.blur, TweenInfo.new(0.7), { Size = C.Blur }):Play() end

        Splash.t0 = os.clock() -- เริ่มนับเวลาเฟดเข้าจากตอนที่หน้าโหลดถูกสร้างเสร็จจริง
        Splash.alive = true
        Splash.set(0.06)
        task.delay(60, Splash.destroy)
    end)
then
    Splash.destroy()
end

-- ── ESP Access Lock ──
-- เฉพาะ UserId ที่อยู่ในลิสต์นี้เท่านั้นที่ใช้ ESP ได้ คนอื่นแท็บจะถูกล็อค กดแล้วไม่ทำงาน
-- และมีการเช็คซ้ำใน RenderStepped ด้วย เพื่อไม่ให้ ESP รันได้จริงไม่ว่าจะพยายามเปิดผ่านช่องทางไหน
local ESP_ALLOWED_USERIDS = { [8514985969] = true }
local IsESPAuthorized = ESP_ALLOWED_USERIDS[LP.UserId] == true

-- Localize common functions for faster access
local t_insert, t_sort, ipairs, pairs = table.insert, table.sort, ipairs, pairs
local m_floor, m_min, m_max, m_clamp, m_huge = math.floor, math.min, math.max, math.clamp, math.huge
local v2_new, v3_new, c3_new = Vector2.new, Vector3.new, Color3.new

local char, hum
local function updateChar(c)
    char = c
    hum = c:WaitForChild("Humanoid")
end
updateChar(LP.Character or LP.CharacterAdded:Wait())
LP.CharacterAdded:Connect(updateChar)

local folderName = "PlantedTrees_" .. LP.UserId
local allTrees, parentFolder, giveWaterRemote

-- ══ เล่นหน้า Splash ให้จบทั้งหมดก่อน (เติมเต็ม 100% → ค้าง → จางหาย → ทำลาย) แล้วค่อยโหลด WindUI ══
-- หลังจากนี้ Splash.alive = false → Splash.set/waitIntro/waitLogo/finish ด้านล่างจะไม่ทำอะไร (ไม่ error)
pcall(function()
    Splash.set(1, "Ready")
    Splash.finish()
    local t = os.clock()
    while Splash.alive and os.clock() - t < 15 do
        task.wait()
    end -- กันค้าง: รอสูงสุด 15 วิ
end)
Splash.destroy() -- ปิดให้แน่ใจ (ถ้าปิดไปแล้วไม่มีผล)
task.wait(0.1)

-- FIX 1: Safer HTTP loading to prevent main thread hanging
local _pgBefore = {}
for _, c in ipairs(LP.PlayerGui:GetChildren()) do
    _pgBefore[c] = true
end
-- BOOT: ดึง Config พร้อมกับ WindUI (ขนานกัน) แทนที่จะรอทีละตัว → เวลาโหลดรวมสั้นลงเกือบครึ่ง
-- _Cfg เป็น table ตัวถือ (m = โมดูลที่โหลดเสร็จ, done = จบแล้ว) ไม่เพิ่มตัวแปร local ใหม่ (กันชนโควตา local 200 ตัว)
local _Cfg = { done = false }
task.spawn(function()
    for attempt = 1, 2 do
        local okc, mod = pcall(function()
            local src = game:HttpGet("https://raw.githubusercontent.com/Captaineieiei/Script-/refs/heads/main/SpectreConfig.lua", true)
            Splash.waitIntro() -- รอเฟดเข้าจบก่อนคอมไพล์ (คอมไพล์กินเฟรมเดียวเต็มๆ)
            task.wait() -- ให้เฟรมได้วาดคั่นระหว่างดาวน์โหลดกับคอมไพล์
            return loadstring(src)()
        end)
        if okc and mod then
            _Cfg.m = mod
            break
        end
        task.wait(1)
    end
    _Cfg.done = true
end)

Splash.set(0.12, "Downloading library...")
local WindUI
local ok, err = pcall(function()
    local src = game:HttpGet("https://raw.githubusercontent.com/SpectreWareZ/SpectreWare/refs/heads/main/Tools/main.lua", true)
    Splash.waitIntro() -- รอเฟดเข้าจบก่อนคอมไพล์ ไม่ให้แอนิเมชันเข้าฉากสะดุด
    task.wait() -- ให้เฟรมได้วาดคั่นระหว่างดาวน์โหลดกับคอมไพล์ (คอมไพล์ไฟล์ใหญ่กินเฟรมเดียวเต็มๆ)
    WindUI = loadstring(src)()
end)
if not ok or not WindUI then
    Splash.destroy()
    LP:Kick("Failed to load WindUI library. Rejoin!")
    return
end
Splash.set(0.4, "Library ready")

local WindUIGui
for _, c in ipairs(LP.PlayerGui:GetChildren()) do
    if not _pgBefore[c] and c:IsA("ScreenGui") then
        WindUIGui = c
        break
    end
end
_pgBefore = nil

-- ── SpectreTheme v3 — matched to WindUI Default Dark palette ──
local SpectreAccent = Color3.fromRGB(75, 135, 255)

pcall(
    function()
        WindUI:AddTheme({
            Name = "SpectreTheme",
            Accent = SpectreAccent,
            Background = Color3.fromRGB(25, 25, 25),
            Outline = Color3.fromRGB(55, 55, 55),
            Button = Color3.fromRGB(35, 35, 35),
            Text = Color3.fromRGB(240, 240, 240),
            Placeholder = Color3.fromRGB(140, 140, 140),
            Icon = Color3.fromRGB(185, 185, 185),
        })
    end
)

-- ── SpectreUI design tokens + helpers (shared by every floating panel) ──
local SW = {
    UIS = game:GetService("UserInputService"),
    Tween = game:GetService("TweenService"),
    Bg = Color3.fromRGB(20, 20, 20),
    BgTop = Color3.fromRGB(30, 30, 30),
    Row = Color3.fromRGB(40, 40, 40),
    Track = Color3.fromRGB(15, 15, 15),
    Text = Color3.fromRGB(240, 240, 240),
    Sub = Color3.fromRGB(155, 155, 155),
    Water = Color3.fromRGB(86, 176, 255),
    Food = Color3.fromRGB(255, 118, 176),
    Growth = Color3.fromRGB(104, 240, 160),
    Danger = Color3.fromRGB(255, 96, 96),
    Good = Color3.fromRGB(110, 255, 165),
    Edge1 = Color3.fromRGB(100, 100, 100),
    Edge2 = SpectreAccent,
}

function SW.new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do
        o[k] = v
    end
    if parent then o.Parent = parent end
    return o
end

function SW.round(obj, r) return SW.new("UICorner", { CornerRadius = UDim.new(0, r) }, obj) end

function SW.stroke(obj, color, thick, trans)
    return SW.new("UIStroke", {
        Color = color,
        Thickness = thick or 1,
        Transparency = trans or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, obj)
end

-- ขอบไล่สี (ม่วง → ฟ้า) ใช้กับทุกแผงลอยให้หน้าตาเป็นชุดเดียวกัน
function SW.edge(obj, thick, trans, rot)
    local s = SW.stroke(obj, Color3.new(1, 1, 1), thick, trans)
    SW.new("UIGradient", { Color = ColorSequence.new(SW.Edge1, SW.Edge2), Rotation = rot or 90 }, s)
    return s
end

-- SMOOTH: cache TweenInfo ต่อความยาว + ไม่สร้าง closure ใหม่ทุกครั้งที่เรียก (เรียกถี่ตอน hover/อัปเดตแท่ง)
local _tweenInfoCache = {}
local _activeTween = setmetatable({}, { __mode = "k" }) -- obj -> {prop -> tween} (weak values: no leak on destroyed objects)
function SW.tween(obj, t, props)
    local info = _tweenInfoCache[t]
    if not info then
        info = TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        _tweenInfoCache[t] = info
    end
    local ok, tw = pcall(SW.Tween.Create, SW.Tween, obj, info, props)
    if not (ok and tw) then return end
    -- single-property tween: cancel the one it supersedes so overlapping tweens never pile up
    local k = next(props)
    if k ~= nil and next(props, k) == nil then
        local slot = _activeTween[obj]
        if slot then
            local old = slot[k]
            if old then old:Cancel() end
        else
            slot = setmetatable({}, { __mode = "v" })
            _activeTween[obj] = slot
        end
        slot[k] = tw
    end
    tw:Play()
end

-- เสียงตอนกดปุ่มที่ล็อค/เปิดไม่ได้ (บี๊บต่ำ 2 จังหวะ) — ใช้เสียงในตัวไคลเอนต์ (rbxasset) ไม่ต้องพึ่ง asset ที่อาจโดนลบ
-- เปลี่ยนเสียงได้ที่ SW.DenySoundId / ความดัง SW.DenyVolume / ความต่ำสูง SW.DenyPitch
SW.DenySoundId = "rbxasset://sounds/button.wav"
SW.DenyVolume = 0.8
SW.DenyPitch = 0.55
function SW.denySound()
    task.spawn(function()
        pcall(function()
            local SS = game:GetService("SoundService")
            for i = 1, 2 do
                local snd = Instance.new("Sound")
                snd.Name = "SW_Deny"
                snd.SoundId = SW.DenySoundId
                snd.Volume = SW.DenyVolume
                snd.PlaybackSpeed = SW.DenyPitch - (i - 1) * 0.1 -- ครั้งที่ 2 ต่ำลงอีก ให้ได้ฟีล "ปฏิเสธ"
                snd.Parent = SS
                snd:Play()
                game:GetService("Debris"):AddItem(snd, 2)
                task.wait(0.12)
            end
        end)
    end)
end

function SW.pop(frame)
    pcall(function()
        local sc = frame:FindFirstChild("SW_Scale") or SW.new("UIScale", { Name = "SW_Scale" }, frame)
        sc.Scale = 0.92
        SW.tween(sc, 0.2, { Scale = 1 })
    end)
end

function SW.fmt(n)
    local s, k = tostring(m_floor(tonumber(n) or 0)), nil
    repeat
        s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
    until k == 0
    return s
end

-- PERF: recursive FindFirstChildWhichIsA was repeated 3x per tree per water cycle; cache the part (weak keys)
SW._treePart = setmetatable({}, { __mode = "k" })
function SW.treePart(tree)
    local p = SW._treePart[tree]
    if p and p.Parent then return p end
    p = tree:FindFirstChildWhichIsA("BasePart", true)
    SW._treePart[tree] = p
    return p
end
-- PERF: shared getter so pcall(SW.getText, x) needs no per-call closure
function SW.getText(o) return o.Text end

-- ══════════════════════════════════════════════════════════════
-- DRAG ENGINE v2 (ลากลื่นขึ้น) — ใช้ร่วมกันทั้งแผงลอย (Safe HUD / Candy) และหน้าต่าง WindUI
--   • อ่านตำแหน่งเมาส์ล่าสุดจาก UIS:GetMouseLocation() ในเฟรมนั้นเลย ไม่ต้องรอ/ฟัง InputChanged
--     (ของเดิมฟัง UIS.InputChanged ถาวรต่อ 1 แผง และมี input.Changed ยิงทุกครั้งที่เมาส์ขยับ)
--   • ต่อ listener เฉพาะตอนกำลังลากเท่านั้น ปล่อยแล้วตัดทิ้งทั้งหมด
--   • ขยับด้วย exponential smoothing แบบไม่ขึ้นกับ FPS → เฟรมตกก็ยังไหลนุ่ม ปล่อยนิ้วแล้วค่อยๆ หยุดเอง
--   • เขียน Position เฉพาะเฟรมที่ค่าเปลี่ยนจริง (ไม่สร้าง/ตั้ง UDim2 ซ้ำตอนอยู่นิ่ง)
--   • กัน "ลากค้าง" (ปล่อยเมาส์นอกจอ/นิ้วหลุด/สลับแอป) ด้วยการเช็คสถานะปุ่มทุกเฟรม
--   • เก็บ Scale ของ Position เดิมไว้ (บวก Offset เพิ่ม) แผงเลยไม่หลุดตำแหน่งเมื่อหมุนจอ/ย่อขยายหน้าต่าง
-- ══════════════════════════════════════════════════════════════
SW.DRAG_FOLLOW = 26 -- ยิ่งสูงยิ่งตามนิ้วไว (≈ หน่วง 40ms) | 0 = ตามตรงๆ ไม่มี smoothing
SW.THROTTLE_ESP_WHEN_DRAGGING = true -- ระหว่างลาก ให้ ESP อัปเดตเฟรมเว้นเฟรม เหลือเฟรมไว้ให้ UI
SW.isDragging = false
SW._dragN = 0

local m_exp, m_abs = math.exp, math.abs
local IT_MOUSE1, IT_TOUCH = Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch
local IS_END, IS_CANCEL = Enum.UserInputState.End, Enum.UserInputState.Cancel

-- target  : GuiObject ที่จะถูกขยับ
-- handles : table ของ GuiObject ที่กดแล้วเริ่มลากได้ (เช่น header)
-- opts    : { clamp = ไม่ให้หลุดขอบจอ, onDrag = function(dragging, handle) }
-- return  : { CanDraggable = true, Set = fn }  (หน้าตาเดียวกับ Creator.Drag ของ WindUI)
function SW.attachDrag(target, handles, opts)
    opts = opts or {}
    local mod = { CanDraggable = true }
    function mod.Set(a, b)
        if type(a) == "table" then
            mod.CanDraggable = b
        else
            mod.CanDraggable = a
        end
    end

    local dragging, isTouch, track, activeHandle = false, false, nil, nil
    local sx, sy, startPos = 0, 0, nil -- จุดเริ่มของ pointer + Position ตอนเริ่มลาก
    local clampOn, dxMin, dxMax, dyMin, dyMax = false, 0, 0, 0, 0
    local curX, curY, goalX, goalY = 0, 0, 0, 0 -- ระยะที่ขยับจากจุดเริ่ม (px): ปัจจุบัน / เป้าหมาย
    local rsConn, endConn

    local function finish()
        if not dragging then return end
        dragging = false
        SW._dragN = m_max(0, SW._dragN - 1)
        SW.isDragging = SW._dragN > 0
        if endConn then
            endConn:Disconnect()
            endConn = nil
        end
        if opts.onDrag then pcall(opts.onDrag, false, activeHandle) end
        activeHandle = nil
    end

    local function step(dt)
        if not target.Parent then -- แผงถูกลบไปแล้ว
            finish()
            if rsConn then
                rsConn:Disconnect()
                rsConn = nil
            end
            return
        end

        if dragging then
            -- กันลากค้าง: event ปล่อยปุ่มหาย (ปล่อยนอกจอ/สลับแอป) ก็ยังหยุดได้
            if isTouch then
                local st = track.UserInputState
                if st == IS_END or st == IS_CANCEL then finish() end
            elseif not SW.UIS:IsMouseButtonPressed(IT_MOUSE1) then
                finish()
            end
        end

        if dragging and mod.CanDraggable then
            local p = isTouch and track.Position or SW.UIS:GetMouseLocation()
            local dx, dy = p.X - sx, p.Y - sy
            if clampOn then
                dx, dy = m_clamp(dx, dxMin, dxMax), m_clamp(dy, dyMin, dyMax)
            end
            goalX, goalY = dx, dy
        end

        local nx, ny = goalX, goalY
        local k = SW.DRAG_FOLLOW
        if k > 0 then
            local a = 1 - m_exp(-k * dt) -- ไม่ขึ้นกับ FPS
            nx = curX + (goalX - curX) * a
            ny = curY + (goalY - curY) * a
            if m_abs(goalX - nx) < 0.25 and m_abs(goalY - ny) < 0.25 then
                nx, ny = goalX, goalY
            end
        end

        if nx ~= curX or ny ~= curY then
            curX, curY = nx, ny
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + nx, startPos.Y.Scale, startPos.Y.Offset + ny)
        end

        -- ปล่อยแล้วและไหลถึงเป้าแล้ว → ตัด RenderStepped ทิ้ง (ตอนอยู่นิ่งไม่มีอะไรรันเลย)
        if not dragging and curX == goalX and curY == goalY and rsConn then
            rsConn:Disconnect()
            rsConn = nil
        end
    end

    local function begin(handle, input)
        if dragging or not mod.CanDraggable then return end
        local ut = input.UserInputType
        if ut ~= IT_MOUSE1 and ut ~= IT_TOUCH then return end
        local parent = target.Parent
        if not parent then return end

        dragging, activeHandle, track, isTouch = true, handle, input, (ut == IT_TOUCH)
        SW._dragN = SW._dragN + 1
        SW.isDragging = true

        local p = isTouch and input.Position or SW.UIS:GetMouseLocation()
        sx, sy = p.X, p.Y
        startPos = target.Position -- เริ่มจากตำแหน่งที่เห็นอยู่จริง (ต่อจากที่กำลังไหลค้างได้ ไม่กระตุก)
        curX, curY, goalX, goalY = 0, 0, 0, 0

        -- จำขอบเขตตอนเริ่มลากครั้งเดียว (ไม่อ่าน AbsoluteSize ทุก event เพราะบังคับ layout คำนวณใหม่ทั้งแผง)
        clampOn = opts.clamp and parent:IsA("GuiBase2d") or false
        if clampOn then
            local rel = target.AbsolutePosition - parent.AbsolutePosition
            local ps, sz = parent.AbsoluteSize, target.AbsoluteSize
            local maxX, maxY = m_max(0, ps.X - sz.X), m_max(0, ps.Y - sz.Y)
            dxMin, dxMax = -rel.X, maxX - rel.X
            dyMin, dyMax = -rel.Y, maxY - rel.Y
        end

        endConn = SW.UIS.InputEnded:Connect(function(i)
            if isTouch then
                if i == track then finish() end
            elseif i.UserInputType == IT_MOUSE1 then
                finish()
            end
        end)
        if not rsConn then rsConn = RunService.RenderStepped:Connect(step) end
        if opts.onDrag then pcall(opts.onDrag, true, handle) end
    end

    for _, h in pairs(handles) do
        h.InputBegan:Connect(function(input) begin(h, input) end)
    end
    return mod
end

-- ลากแผงลอยของเรา (ไม่ให้หลุดขอบจอ) — signature เดิม
function SW.drag(handle, target) SW.attachDrag(target, { handle }, { clamp = true }) end

-- ── แทน Creator.Drag ของ WindUI (หน้าต่างหลัก + ปุ่มเปิด) ──
-- ของเดิมสร้าง Tween ใหม่ "ทุกครั้งที่เมาส์ขยับ" (0.02 วิ) → alloc ถี่ + ตำแหน่งกระตุกตามจังหวะ event
-- ต้องแพตช์ก่อน WindUI:CreateWindow เพราะ WindUI เรียก Creator.Drag ตอนสร้างหน้าต่าง
-- ถ้า library เวอร์ชันนั้นไม่มี Creator.Drag / เรียกผ่านทางอื่น จะไม่แพตช์ (มี warn บอก) และใช้ของเดิมต่อโดยไม่พัง
SW.windDragPatched = false
do
    local Creator = type(WindUI) == "table" and WindUI.Creator or nil
    if type(Creator) == "table" and type(Creator.Drag) == "function" then
        local origDrag = Creator.Drag
        Creator.Drag = function(mainFrame, dragFrames, ondrag)
            local ok, mod = pcall(function()
                local handles = type(dragFrames) == "table" and dragFrames or { mainFrame }
                return SW.attachDrag(mainFrame, handles, {
                    clamp = false,
                    onDrag = type(ondrag) == "function" and ondrag or nil,
                })
            end)
            if ok and mod then
                SW.windDragPatched = true
                return mod
            end
            return origDrag(mainFrame, dragFrames, ondrag) -- ล้มเหลว → กลับไปใช้ของ WindUI
        end
    end
end

local AntiAFKEnabled = true
local FriendSet = {}

local function refreshFriends()
    FriendSet = {}
    pcall(function()
        local pages = Players:GetFriendsAsync(LP.UserId)
        while true do
            for _, info in ipairs(pages:GetCurrentPage()) do
                FriendSet[info.Id] = true
            end
            if pages.IsFinished then break end
            pages:AdvanceToNextPageAsync()
        end
    end)
end
task.spawn(refreshFriends)

-- FIX 2: รอ Config ที่ดึงไว้ขนานตั้งแต่ต้นไฟล์ (มี timeout กันค้างไม่รู้จบ)
Splash.set(0.45, "Loading config...")
do
    local t0 = os.clock()
    while not _Cfg.done and os.clock() - t0 < 25 do
        task.wait()
    end
end
if not _Cfg.m then
    Splash.destroy()
    LP:Kick("Failed to load Config. Rejoin!")
    return
end
Splash.set(0.9) -- ดาวน์โหลดครบแล้ว
Splash.waitLogo(0.9) -- รอโลโก้เขียนเกือบครบ + ครบเวลาขั้นต่ำ แล้วค่อยเริ่มสร้าง UI (ช่วงท้ายเติมตอนสร้างเสร็จ)
Splash.set(0.92, "Building UI...")

local CFG, SaveCFG, LoadCFG, OnCFGLoaded = _Cfg.m.new(
    "SpectreWare.json",
    { "Enabled", "NPCSESP", "ShowHP", "ShowHPText", "ShowName", "ShowDist", "BypassAntiESP", "HideDeadESP", "HideFriends" },
    { "BoxThickness", "HPBarWidth", "NameSize", "MaxDist", "ESPDetailDist" },
    { "BoxColor" },
    {
        Enabled = false,
        NPCSESP = false,
        BoxColor = Color3.fromRGB(255, 60, 60),
        BoxThickness = 2,
        ShowHP = true,
        HPBarWidth = 5,
        ShowHPText = true,
        ShowName = true,
        NameSize = 15,
        ShowDist = true,
        MaxDist = 600,
        BypassAntiESP = true,
        HideDeadESP = true,
        HideFriends = false,
        ESPDetailDist = 120, -- ในระยะนี้วาดโครงกระดูกเต็ม ไกลกว่านี้วาดกรอบสี่เหลี่ยมง่ายๆแทน (ลดจำนวน WorldToViewportPoint ต่อเฟรมเยอะมากเวลามีคน/NPC เยอะ)
    }
)

local _saveCFGPending = false
local function DebouncedSaveCFG()
    if _saveCFGPending then return end
    _saveCFGPending = true
    task.delay(0.5, function()
        _saveCFGPending = false
        pcall(SaveCFG)
    end)
end

task.wait() -- คั่นเฟรมก่อนสร้างหน้าต่าง (สร้าง UI ก้อนใหญ่)
local Window = WindUI:CreateWindow({
    Title = "SpectreWare | NEVER TOWN",
    Icon = "rbxassetid://120973730470455",
    Author = "#Captain",
    Folder = "MySuperHub",
    Size = UDim2.fromOffset(580, 460),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(850, 560),
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 200,
    BackgroundImageTransparency = 0.42,
    HideSearchBar = false,
    ScrollBarEnabled = false,
    IconRadius = 999, -- ไอคอนหน้าต่างเป็นวงกลม เข้าชุดกับปุ่มเปิด
})
-- ── ซ่อนหน้าต่าง WindUI ไว้ก่อน จนกว่าจะสร้างเนื้อหาครบทุกแท็บ (กัน UI โผล่มาทั้งที่ยังโหลดไม่เสร็จ) ──
SW.hold, SW.revealed = {}, false
pcall(function()
    local g = WindUIGui
    if not (g and g.Parent) then g = Window.UIElements.Main:FindFirstAncestorOfClass("ScreenGui") end
    if g then
        g.Enabled = false
        SW.hold[#SW.hold + 1] = g
    end
end)
function SW.reveal()
    if SW.revealed then return end
    SW.revealed = true
    for _, g in ipairs(SW.hold) do
        pcall(function()
            if g.Parent then g.Enabled = true end
        end)
    end
end
task.delay(45, SW.reveal) -- กันพลาด: ถ้าโหลดค้าง/พัง อย่างช้า 45 วิ UI จะโผล่เอง

if not SW.windDragPatched then
    warn(
        "[SpectreWare] WindUI drag patch ไม่ทำงาน (library เวอร์ชันนี้ไม่ได้เรียก Creator.Drag ผ่านตารางที่แพตช์ได้) — หน้าต่างหลักใช้การลากของ WindUI เดิม; แผงลอย Candy/HUD ยังใช้ engine ใหม่"
    )
end
Window:Tag({ Title = "v1.6.12", Icon = "github", Color = Color3.fromRGB(75, 135, 255), Radius = 13 })
-- ไอคอนหน้าต่าง: 80px ใหญ่กว่า topbar (52px) จนล้นออกนอกหน้าต่างและทับชื่อ → ใช้ 34px
SW.WIN_ICON_SIZE = 34 -- เก็บใน SW แทน local ใหม่ (กันชนโควตา local 200 ตัว)
Window:SetIconSize(SW.WIN_ICON_SIZE)
-- library บางเวอร์ชันเว้นที่ให้ไอคอนแค่ 22px แม้จะขยายไอคอนแล้ว → ขยายกรอบที่ใส่ไอคอนตามด้วย ชื่อจะได้ไม่โดนทับ
task.spawn(function()
    for _ = 1, 20 do
        task.wait(0.1)
        local done = false
        pcall(function()
            for _, c in ipairs(Window.UIElements.Main.Main.Topbar.Left:GetChildren()) do
                if c:IsA("Frame") and c:FindFirstChildWhichIsA("ImageLabel", true) then
                    c.Size = UDim2.fromOffset(SW.WIN_ICON_SIZE, SW.WIN_ICON_SIZE)
                    done = true
                end
            end
        end)
        if done then break end
    end
end)
-- ── ปุ่มเปิด UI แบบรูปภาพ ──
-- ปิดปุ่มเปิดเดิมของ WindUI แล้วใช้ปุ่มรูปของเราแทน: อยู่กลางจอบน เห็นตลอดแม้หน้าต่างเปิดอยู่
-- แตะ = สลับเปิด/ปิดหน้าต่าง | ลากย้ายตำแหน่งได้ | จุดมุมขวาล่าง: เขียว = เปิดอยู่, เทา = ปิดอยู่
-- เปลี่ยนรูปที่ OPEN_BTN_IMAGE (ใส่ rbxassetid://เลขรูป) | เปลี่ยนขนาดที่ OPEN_BTN_SIZE | ระยะจากขอบบนที่ OPEN_BTN_TOP
local OPEN_BTN_IMAGE = "rbxassetid://120973730470455"
local OPEN_BTN_SIZE = 52
local OPEN_BTN_TOP = 10

pcall(function() Window:EditOpenButton({ Enabled = false }) end)

do
    local TS = SW.Tween
    local ES, ED = Enum.EasingStyle, Enum.EasingDirection

    local openGui = SW.new("ScreenGui", {
        Name = "SW_OpenButton",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 60,
    }, LP:WaitForChild("PlayerGui"))

    if not SW.revealed then
        openGui.Enabled = false
        SW.hold[#SW.hold + 1] = openGui
    end

    local holder = SW.new("Frame", {
        Name = "OpenButtonHolder",
        Size = UDim2.fromOffset(OPEN_BTN_SIZE, OPEN_BTN_SIZE),
        Position = UDim2.new(0.5, -OPEN_BTN_SIZE / 2, 0, OPEN_BTN_TOP),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, openGui)
    local holderScale = SW.new("UIScale", { Scale = 0.85 }, holder)

    -- เงาเบาๆ ใต้ปุ่ม
    local shadow = SW.new("Frame", {
        Name = "Shadow",
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromOffset(0, 3),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        ZIndex = 1,
    }, holder)
    SW.new("UICorner", { CornerRadius = UDim.new(1, 0) }, shadow)

    -- ปุ่มรูป
    local openBtn = SW.new("ImageButton", {
        Name = "OpenButton",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = SW.Bg,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Active = true,
        ZIndex = 2,
        Image = OPEN_BTN_IMAGE,
        ScaleType = Enum.ScaleType.Crop,
    }, holder)
    SW.new("UICorner", { CornerRadius = UDim.new(1, 0) }, openBtn)
    local ring = SW.stroke(openBtn, SW.Edge1, 1.5, 0.35)

    -- วงโคจรหมุนรอบปุ่ม (ดีไซน์ใหม่): ดาวหาง = หัวสว่างคม + หางไล่จางยาวต่อเนื่อง ไล่สีม่วง → ฟ้า → ขาว
    -- 2 ชั้น: "แกน" เส้นคมบาง + "แสงฟุ้ง" เส้นหนากว่าโปร่งแสงอยู่ใต้ (ให้ความรู้สึกเรืองแสง)
    -- หมุนด้วย loop tween ฝั่งเอนจิน (ไม่กิน CPU สคริปต์) — ชั้นเดียวกันใช้ Rotation ตรงกันเลยไม่เหลื่อม
    local ORBIT_TIME = 2.4 -- วินาทีต่อ 1 รอบ (ช้าลงนิดนึงให้ดูนุ่ม)
    local orbitColor = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 70, 255)), -- ปลายหาง: ม่วงเข้ม
        ColorSequenceKeypoint.new(0.55, Color3.fromRGB(150, 110, 255)), -- ม่วงสว่าง
        ColorSequenceKeypoint.new(0.8, SpectreAccent), -- ฟ้า
        ColorSequenceKeypoint.new(0.95, Color3.fromRGB(190, 230, 255)), -- ฟ้าอ่อน
        ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)), -- หัว: ขาวสว่าง
    })
    -- ความโปร่งใสโค้งนุ่ม (ease-out) หลายจุด ไม่ให้เห็นขอบตัดแข็ง; แสงฟุ้ง = ชุดเดียวกันแต่จางกว่า
    local function tailSeq(minT)
        local pts = {
            { 0, 1 },
            { 0.28, 1 },
            { 0.45, 0.93 },
            { 0.6, 0.78 },
            { 0.75, 0.52 },
            { 0.88, 0.22 },
            { 0.96, 0.02 },
            { 0.985, 0.25 },
            { 1, 1 },
        }
        local kp = {}
        for i, v in ipairs(pts) do
            local t = v[2]
            if t < 1 then t = minT + (1 - minT) * t end -- ยกพื้นให้จางสุดไม่เกิน minT (ยกเว้นส่วนที่โปร่งใสสนิท)
            kp[i] = NumberSequenceKeypoint.new(v[1], math.clamp(t, 0, 1))
        end
        return NumberSequence.new(kp)
    end

    local function makeOrbitLayer(name, sizeAdd, thick, minT, z)
        local f = SW.new("Frame", {
            Name = name,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(1, sizeAdd, 1, sizeAdd),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = z,
        }, holder)
        SW.new("UICorner", { CornerRadius = UDim.new(1, 0) }, f)
        local st = SW.stroke(f, Color3.new(1, 1, 1), thick, 0)
        local g = SW.new("UIGradient", { Color = orbitColor, Transparency = tailSeq(minT) }, st)
        return g, st
    end

    local orbitGlow, orbitGlowStroke = makeOrbitLayer("OrbitGlow", 3, 5, 0.72, 3) -- แสงฟุ้งหนา จาง
    local orbitCore, orbitStroke = makeOrbitLayer("Orbit", 7, 2, 0, 4) -- แกนคมบาง
    local orbitInfo = TweenInfo.new(ORBIT_TIME, ES.Linear, ED.Out, -1)
    TS:Create(orbitGlow, orbitInfo, { Rotation = 360 }):Play()
    TS:Create(orbitCore, orbitInfo, { Rotation = 360 }):Play()

    -- จุดสถานะมุมขวาล่าง
    -- halo = วงแสงที่ขยายออกแล้วจางหาย (เหมือนไฟ "ออนไลน์") แสดงเฉพาะตอนหน้าต่างเปิดอยู่
    local halo = SW.new("Frame", {
        Name = "StatusHalo",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.82, 0.82),
        Size = UDim2.fromOffset(11, 11),
        BackgroundColor3 = SW.Good,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        ZIndex = 3,
        Visible = false,
    }, holder)
    SW.new("UICorner", { CornerRadius = UDim.new(1, 0) }, halo)
    TS:Create(halo, TweenInfo.new(1.6, ES.Quad, ED.Out, -1), { Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 1 }):Play()

    local dot = SW.new("Frame", {
        Name = "StatusDot",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.82, 0.82),
        Size = UDim2.fromOffset(11, 11),
        BackgroundColor3 = SW.Good,
        BorderSizePixel = 0,
        ZIndex = 4,
    }, holder)
    SW.new("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)
    local dotRing = SW.stroke(dot, SW.Bg, 2, 0)
    local dotScale = SW.new("UIScale", { Scale = 1 }, dot)

    local function paintState(isOpen) SW.tween(dot, 0.2, { BackgroundColor3 = isOpen and SW.Good or SW.Sub }) end
    local popTw
    local function setState(isOpen)
        paintState(isOpen)
        halo.Visible = isOpen
        -- เด้งเบาๆ ตอนสถานะเปลี่ยน (ยกเลิกตัวเก่าก่อนเสมอ กันซ้อน)
        if popTw then popTw:Cancel() end
        dotScale.Scale = 1.45
        popTw = TS:Create(dotScale, TweenInfo.new(0.35, ES.Back, ED.Out), { Scale = 1 })
        popTw:Play()
    end
    paintState(not Window.Closed)

    -- สเกล: tween ตัวเดียว ยกเลิกตัวเก่าก่อนเสมอ + ข้ามถ้าเป้าเหมือนเดิม
    local scaleTw, scaleGoal
    local function setScale(v, t)
        if scaleGoal == v then return end
        scaleGoal = v
        if scaleTw then scaleTw:Cancel() end
        scaleTw = TS:Create(holderScale, TweenInfo.new(t, ES.Quad, ED.Out), { Scale = v })
        scaleTw:Play()
    end

    local canHover = SW.UIS.MouseEnabled and not SW.UIS.TouchEnabled -- มือถือไม่ใช้ hover
    local pressed, hovering, pressPos = false, false, nil

    local function idleScale() return (canHover and hovering) and 1.04 or 1 end

    local function release()
        pressed = false
        setScale(idleScale(), 0.12)
    end

    SW.attachDrag(holder, { openBtn }, {
        clamp = true,
        onDrag = function(dragging)
            if dragging then
                pressed, pressPos = true, holder.AbsolutePosition
                setScale(0.93, 0.08)
            else
                release()
            end
        end,
    })

    openBtn.MouseEnter:Connect(function()
        hovering = true
        if canHover then
            SW.tween(ring, 0.15, { Color = SpectreAccent, Transparency = 0 })
            if not pressed then setScale(1.04, 0.15) end
        end
    end)
    openBtn.MouseLeave:Connect(function()
        hovering = false
        if canHover then
            SW.tween(ring, 0.15, { Color = SW.Edge1, Transparency = 0.35 })
            if not pressed then setScale(1, 0.15) end
        end
    end)
    openBtn.MouseButton1Up:Connect(release)

    -- ✨ Open effect: เรืองแสงฟุ้ง + สะเก็ดแสงกระจายรอบทิศ + วงแหวนไล่สีม่วง→ฟ้าซ้อนจังหวะ (staggered) เล่นเฉพาะตอน "เปิด"
    local SPARK_COUNT = 8
    local sparkAngles = {}
    for i = 1, SPARK_COUNT do
        sparkAngles[i] = (i - 1) * (2 * math.pi / SPARK_COUNT)
    end

    local function spawnGlow()
        local glow = SW.new("Frame", {
            Name = "OpenGlow",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = SpectreAccent,
            BackgroundTransparency = 0.25,
            BorderSizePixel = 0,
            ZIndex = 1,
        }, holder)
        SW.new("UICorner", { CornerRadius = UDim.new(1, 0) }, glow)
        TS:Create(glow, TweenInfo.new(0.45, ES.Quad, ED.Out), { Size = UDim2.fromScale(2.3, 2.3), BackgroundTransparency = 1 }):Play()
        task.delay(0.45, function() glow:Destroy() end)
    end

    local function spawnSparks()
        local dist = OPEN_BTN_SIZE * 0.9
        for i = 1, SPARK_COUNT do
            local dx, dy = math.cos(sparkAngles[i]) * dist, math.sin(sparkAngles[i]) * dist
            local spark = SW.new("Frame", {
                Name = "OpenSpark",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(4, 4),
                BackgroundColor3 = Color3.fromRGB(210, 225, 255),
                BorderSizePixel = 0,
                ZIndex = 6,
            }, holder)
            SW.new("UICorner", { CornerRadius = UDim.new(1, 0) }, spark)
            TS:Create(spark, TweenInfo.new(0.4, ES.Quad, ED.Out), {
                Position = UDim2.new(0.5, dx, 0.5, dy),
                Size = UDim2.fromOffset(1, 1),
                BackgroundTransparency = 1,
            }):Play()
            task.delay(0.4, function() spark:Destroy() end)
        end
    end

    local function spawnRing(delay, sizeMul, thick, life)
        task.delay(delay, function()
            if not holder.Parent then return end
            local ring = SW.new("Frame", {
                Name = "OpenRing",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 5,
            }, holder)
            SW.new("UICorner", { CornerRadius = UDim.new(1, 0) }, ring)
            local edge = SW.edge(ring, thick, 0, 90) -- ไล่สีม่วง→ฟ้าแบบเดียวกับขอบแผงอื่นๆ ในสคริปต์
            TS:Create(ring, TweenInfo.new(life, ES.Quad, ED.Out), { Size = UDim2.fromScale(sizeMul, sizeMul) }):Play()
            TS:Create(edge, TweenInfo.new(life, ES.Quad, ED.Out), { Transparency = 1 }):Play()
            task.delay(life, function() ring:Destroy() end)
        end)
    end

    local function playOpenEffect()
        spawnGlow()
        spawnSparks()
        spawnRing(0, 2.0, 2.5, 0.45)
        spawnRing(0.08, 2.6, 1.5, 0.5)
        spawnRing(0.16, 3.2, 1, 0.55)
    end

    -- ── เอฟเฟกต์ตอน "ปิด/ซ่อน" (ดีไซน์ใหม่) — "ดูดแสงเข้าหาปุ่ม" ──
    -- แสงฟุ้งหด + สะเก็ดแสงม่วง/ฟ้าไหลเข้าหาศูนย์กลาง + วงแหวนไล่สีหดมาชนขอบปุ่ม
    -- พอแสงถึงปุ่ม: ขอบปุ่มวาบ + ปุ่มยุบนิดนึงแล้วคืนตัวนุ่มๆ (ตรงข้ามกับตอนเปิดที่พุ่งออก)
    local CLOSE_COL_A = Color3.fromRGB(150, 110, 255) -- ม่วงสว่าง
    local CLOSE_COL_B = Color3.fromRGB(190, 230, 255) -- ฟ้าอ่อน
    local CLOSE_SPARKS = 10
    local CLOSE_TIME = 0.34 -- เวลาที่แสงใช้หดเข้าหาปุ่ม

    local function spawnCloseGlow()
        local glow = SW.new("Frame", {
            Name = "CloseGlow",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromScale(2.1, 2.1),
            BackgroundColor3 = Color3.fromRGB(110, 80, 255),
            BackgroundTransparency = 0.72,
            BorderSizePixel = 0,
            ZIndex = 1,
        }, holder)
        SW.new("UICorner", { CornerRadius = UDim.new(1, 0) }, glow)
        TS:Create(glow, TweenInfo.new(CLOSE_TIME, ES.Sine, ED.In), { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }):Play()
        task.delay(CLOSE_TIME, function() glow:Destroy() end)
    end

    local function spawnCloseSparks()
        local dist = OPEN_BTN_SIZE * 1.15
        local base = math.random() * math.pi * 2 -- หมุนมุมเริ่มสุ่ม ไม่ซ้ำแพทเทิร์นเดิมทุกครั้ง
        for i = 1, CLOSE_SPARKS do
            local ang = base + (i - 1) * (2 * math.pi / CLOSE_SPARKS)
            local life = 0.24 + (i % 3) * 0.04
            local spark = SW.new("Frame", {
                Name = "CloseSpark",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, math.cos(ang) * dist, 0.5, math.sin(ang) * dist),
                Size = UDim2.fromOffset(5, 5),
                BackgroundTransparency = 0.1,
                BorderSizePixel = 0,
                ZIndex = 6,
                BackgroundColor3 = (i % 2 == 0) and CLOSE_COL_A or CLOSE_COL_B,
            }, holder)
            SW.new("UICorner", { CornerRadius = UDim.new(1, 0) }, spark)
            -- เรียงจังหวะเหลื่อมกันนิดๆ ให้ไหลเข้าเป็นคลื่น ไม่ใช่พร้อมกันหมด
            TS:Create(spark, TweenInfo.new(life, ES.Quad, ED.In, 0, false, i * 0.012), {
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(1, 1),
                BackgroundTransparency = 1,
            }):Play()
            task.delay(life + i * 0.012 + 0.05, function() spark:Destroy() end)
        end
    end

    local function spawnCloseRing(delay, startMul, thick, startTrans)
        task.delay(delay, function()
            if not holder.Parent then return end
            local r = SW.new("Frame", {
                Name = "CloseRing",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(startMul, startMul),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 5,
            }, holder)
            SW.new("UICorner", { CornerRadius = UDim.new(1, 0) }, r)
            local edge = SW.edge(r, thick, startTrans, 90) -- ไล่สีม่วง→ฟ้าเหมือนตอนเปิด แต่หดเข้าแทน
            -- หดมาจบที่ขอบปุ่มพอดี (1.0) เหมือนถูกปุ่มดูดกลืน
            TS:Create(r, TweenInfo.new(CLOSE_TIME, ES.Quad, ED.In), { Size = UDim2.fromScale(1.02, 1.02) }):Play()
            TS:Create(edge, TweenInfo.new(CLOSE_TIME, ES.Quad, ED.In), { Transparency = 1 }):Play()
            task.delay(CLOSE_TIME + 0.02, function() r:Destroy() end)
        end)
    end

    -- ตอนแสงมาถึงปุ่ม: วงแสงวาบออกจากขอบปุ่มนิดเดียว + ขอบปุ่มติดสีม่วงแล้วค่อยกลับเป็นปกติ
    local function absorbFlash()
        if not holder.Parent then return end
        local fl = SW.new("Frame", {
            Name = "CloseFlash",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = CLOSE_COL_A,
            BackgroundTransparency = 0.45,
            BorderSizePixel = 0,
            ZIndex = 1,
        }, holder)
        SW.new("UICorner", { CornerRadius = UDim.new(1, 0) }, fl)
        TS:Create(fl, TweenInfo.new(0.32, ES.Quad, ED.Out), { Size = UDim2.fromScale(1.45, 1.45), BackgroundTransparency = 1 }):Play()
        task.delay(0.32, function() fl:Destroy() end)

        SW.tween(ring, 0.1, { Color = CLOSE_COL_A, Transparency = 0 })
        task.delay(0.35, function()
            if holder.Parent and not hovering then SW.tween(ring, 0.3, { Color = SW.Edge1, Transparency = 0.35 }) end
        end)
    end

    local function playCloseEffect()
        spawnCloseGlow()
        spawnCloseSparks()
        spawnCloseRing(0, 2.5, 2, 0.35)
        spawnCloseRing(0.07, 3.1, 1.2, 0.55)
        task.delay(CLOSE_TIME - 0.04, absorbFlash)
    end

    openBtn.MouseButton1Click:Connect(function()
        if pressPos and (holder.AbsolutePosition - pressPos).Magnitude > 10 then return end -- ลากอยู่ ไม่ใช่การแตะ
        local willOpen = Window.Closed -- true = ตอนนี้ปิดอยู่ กำลังจะเปิด
        Window:Toggle()
        if scaleTw then scaleTw:Cancel() end
        scaleGoal = idleScale()
        if willOpen then
            playOpenEffect()
            -- เด้งย้ำ (overshoot) ตอนเปิด ให้รู้สึกหนักแน่นกว่าการปล่อยเมาส์ปกติ
            holderScale.Scale = 0.86
            scaleTw = TS:Create(holderScale, TweenInfo.new(0.4, ES.Back, ED.Out), { Scale = scaleGoal })
        else
            playCloseEffect()
            -- ตอนปิด: รอแสงหดมาถึงปุ่ม → ปุ่มยุบลงนิดนึง (เหมือนกลืนแสง) → เด้งคืนนุ่มๆ (Back เบา)
            -- ถ้าผู้ใช้กดซ้ำระหว่างนี้ tween จะถูก Cancel และขั้นต่อไปไม่ทำงาน (กันซ้อน)
            holderScale.Scale = scaleGoal
            local dip =
                TS:Create(holderScale, TweenInfo.new(0.14, ES.Quad, ED.In, 0, false, CLOSE_TIME - 0.1), { Scale = scaleGoal * 0.86 })
            scaleTw = dip
            dip.Completed:Once(function(state)
                if state == Enum.PlaybackState.Completed and scaleTw == dip then
                    scaleTw = TS:Create(holderScale, TweenInfo.new(0.45, ES.Back, ED.Out), { Scale = scaleGoal })
                    scaleTw:Play()
                end
            end)
        end
        scaleTw:Play()
    end)

    Window:OnOpen(function() setState(true) end)
    Window:OnClose(function() setState(false) end)
    Window:OnDestroy(function() openGui:Destroy() end)

    -- ตอนเริ่ม: ค่อยๆ เฟดเข้า + ขยายจาก 0.85 → 1 (สั้นๆ ไม่เล่นใหญ่)
    local function fadeIn(obj, prop, target)
        obj[prop] = 1
        TS:Create(obj, TweenInfo.new(0.3, ES.Quad, ED.Out), { [prop] = target }):Play()
    end
    fadeIn(openBtn, "BackgroundTransparency", 0)
    fadeIn(openBtn, "ImageTransparency", 0)
    fadeIn(ring, "Transparency", 0.35)
    fadeIn(orbitStroke, "Transparency", 0)
    fadeIn(orbitGlowStroke, "Transparency", 0)
    fadeIn(shadow, "BackgroundTransparency", 0.7)
    fadeIn(dot, "BackgroundTransparency", 0)
    fadeIn(dotRing, "Transparency", 0)
    setScale(1, 0.3)
    task.delay(0.35, function() halo.Visible = not Window.Closed end) -- วงแสงโผล่หลังปุ่มเฟดเข้าเสร็จ
end

task.spawn(function()
    allTrees = workspace:WaitForChild("AllPlantedTrees", 30)
    if allTrees then parentFolder = allTrees:WaitForChild(folderName, 15) end
    pcall(
        function() giveWaterRemote = game:GetService("ReplicatedStorage"):WaitForChild("Grow_vegetables", 15):WaitForChild("GiveWater", 10) end
    )
    task.wait(0.5)
    local t0 = os.clock()
    while not buildWaterPickDropdown and os.clock() - t0 < 20 do
        task.wait(0.2)
    end
    if buildWaterPickDropdown then pcall(buildWaterPickDropdown) end
end)

-- หา TextLabel ตามข้อความ: เดิมเรียก GetDescendants() ของ CoreGui+PlayerGui ทั้งก้อนในครั้งเดียว (เฟรมค้างชัดเจนตอนรัน)
-- ตอนนี้เดินทีละชั้นด้วย GetChildren แล้วเว้นเฟรมทุก ~250 โหนด | เริ่มจาก GUI ของ WindUI ก่อน (เจอเร็วสุด) ค่อยขยับไปที่อื่น
local function findLabelByText(text)
    local roots = {}
    if WindUIGui and WindUIGui.Parent then roots[#roots + 1] = WindUIGui end
    pcall(function()
        if gethui then roots[#roots + 1] = gethui() end
    end)
    roots[#roots + 1] = LP.PlayerGui
    roots[#roots + 1] = game:GetService("CoreGui")
    local done = {}
    for _, root in ipairs(roots) do
        if root and not done[root] then
            done[root] = true
            local queue, qh, qt, n = { root }, 1, 1, 0
            while qh <= qt do
                local node = queue[qh]
                queue[qh] = false
                qh = qh + 1
                local okc, kids = pcall(node.GetChildren, node)
                if okc then
                    for i = 1, #kids do
                        local v = kids[i]
                        if v:IsA("TextLabel") and v.Text == text then return v end
                        qt = qt + 1
                        queue[qt] = v
                        n = n + 1
                        if n % 250 == 0 then task.wait() end
                    end
                end
            end
        end
    end
end

local function resolveRemotePath(root, path, timeout)
    local cur = root
    for _, name in ipairs(path) do
        if not cur then return nil end
        cur = cur:WaitForChild(name, timeout or 1)
    end
    return cur
end

local function optionKey(opt) return type(opt) == "table" and opt.Title or tostring(opt) end

local AmountDescLabel
local function setAmount(text)
    if AmountDescLabel and AmountDescLabel.Parent then
        text = tostring(text)
        -- SMOOTH: ข้อความเดิมไม่ต้องเขียนซ้ำ (การเขียน Text ของ label ใน WindUI ทำให้ layout คำนวณใหม่ ทุก 3 วิ)
        if AmountDescLabel.Text ~= text then pcall(function() AmountDescLabel.Text = text end) end
    end
end

local SafeDescLabel

local function getSafeQty(itemName)
    local ok, qty = pcall(function()
        local sf = LP:FindFirstChild("Safe")
        if not sf then return 0 end
        local v = sf:FindFirstChild(itemName)
        return v and m_floor(v.Value) or 0
    end)
    return (ok and qty) or 0
end

-- ── Floating Safe HUD ──
local _hudGui, _hudIcon, _hudName, _hudCount

local function buildSafeHud()
    if _hudGui and _hudGui.Parent then return end

    _hudGui = Instance.new("ScreenGui")
    _hudGui.Name = "SW_SafeHUD"
    _hudGui.ResetOnSpawn = false
    _hudGui.IgnoreGuiInset = true
    _hudGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    _hudGui.DisplayOrder = 40
    _hudGui.Parent = LP.PlayerGui

    local card = SW.new("Frame", {
        Name = "Card",
        Size = UDim2.fromOffset(204, 66),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.12, 0, 0.78, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.02,
        BorderSizePixel = 0,
        Active = true,
        Visible = false,
    }, _hudGui)
    SW.round(card, 16)
    SW.new("UIGradient", { Color = ColorSequence.new(SW.BgTop, SW.Bg), Rotation = 125 }, card)
    SW.edge(card, 1.5, 0.2, 45)

    local iconBg = SW.new("Frame", {
        Size = UDim2.fromOffset(46, 46),
        Position = UDim2.new(0, 10, 0.5, -23),
        BackgroundColor3 = SW.Row,
        BorderSizePixel = 0,
        ZIndex = 2,
    }, card)
    SW.round(iconBg, 12)
    SW.stroke(iconBg, SpectreAccent, 1, 0.55)

    _hudIcon = SW.new("ImageLabel", {
        Size = UDim2.fromOffset(36, 36),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 1,
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 3,
    }, iconBg)

    _hudName = SW.new("TextLabel", {
        Size = UDim2.new(1, -74, 0, 20),
        Position = UDim2.fromOffset(64, 9),
        BackgroundTransparency = 1,
        TextColor3 = SW.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 2,
    }, card)

    _hudCount = SW.new("TextLabel", {
        Size = UDim2.new(1, -74, 0, 24),
        Position = UDim2.fromOffset(64, 32),
        BackgroundTransparency = 1,
        TextColor3 = SW.Good,
        Font = Enum.Font.GothamBold,
        TextSize = 17,
        RichText = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 2,
    }, card)

    SW.drag(card, card)
end

local function getHudCard()
    if _hudGui and _hudGui.Parent then return _hudGui:FindFirstChild("Card") end
end

-- ── ESP ──
local ESPObjects = {}
-- OPTIMIZE: frame-stride throttle. Far/off-screen-ish targets don't need a fresh
-- WorldToViewportPoint projection every single RenderStepped — reusing last frame's
-- screen box for 2-4 frames is visually lossless at range but skips the priciest calls
-- in the hot loop (this is what actually chokes framerate once 15-20+ ESP boxes stack up).
local _frameCounter = 0
local _staggerCounter = 0
local _espPartCache = {}
local _espCacheBuild = {} -- FIX: ไม่เคย declare ทำให้ indexing nil error ใน updateESPObject → ESP ไม่ขึ้น
local Z_MARGIN = 0.5 -- Z-buffer margin: kills edge-of-camera flicker

-- FIX (ESP ติดจอ/กะพริบตอนหมุนกล้องเร็ว): ตอนกล้องหมุนเร็ว จุดที่ cache ไว้ (skipProjection)
-- จะไม่ถูกเช็คว่ายังอยู่ในจอไหม เลยค้างตำแหน่งเดิมไว้ก่อนจะกระโดดไปตำแหน่งจริง/หายวับ ๆ
-- แก้โดยวัดมุมที่กล้องหมุนต่อเฟรม ถ้าหมุนเร็วเกิน threshold ให้บังคับรีเฟรช (ยิง WorldToViewportPoint ใหม่)
-- ทุกตัวทุกเฟรมชั่วคราว จนกว่าจะหมุนช้าลงถึงจะกลับไปใช้ stride ประหยัดเฟรมตามเดิม
local _lastCamLook = nil
local _fastRotate = false
-- FIX: 0.035 rad/frame = ~120°/s at 60fps — way too permissive. Any normal camera
-- turn sailed under it, so _fastRotate stayed false and the joint-stride cache kept
-- serving stale on-screen coordinates. 0.010 rad/frame ≈ 34°/s catches typical
-- turning without triggering on idle micro-jitter.
local ROTATE_ANGLE_THRESHOLD = 0.010
-- OPTIMIZE (CPU): acos(dot) > T  <=>  dot < cos(T). คำนวณ cos ครั้งเดียว แทน math.acos ทุกเฟรม
-- (เก็บไว้ใน SW เพื่อไม่เพิ่ม local ระดับไฟล์ — กันชนโควตา local 200 ตัว)
SW.ROTATE_COS_THRESHOLD = math.cos(ROTATE_ANGLE_THRESHOLD)

local ESP_EXCLUDE_PATHS = {
    { "System", "[Server] Npc_Seal" },
    { "System", "[Prompt] Team" },
    { "Farmer_1" },
}

-- OPTIMIZE: Cache excluded status to prevent path lookup every frame
local _excludedCache = setmetatable({}, { __mode = "k" })
local function isESPExcluded(model)
    if _excludedCache[model] ~= nil then return _excludedCache[model] end
    local result = false
    for _, path in ipairs(ESP_EXCLUDE_PATHS) do
        local node = workspace
        for _, name in ipairs(path) do
            node = node:FindFirstChild(name)
            if not node then break end
        end
        if node and (model == node or model:IsDescendantOf(node)) then
            result = true
            break
        end
    end
    _excludedCache[model] = result
    return result
end

local function newLine(thick, color)
    local d = Drawing.new("Line")
    d.Thickness = thick
    d.Color = color
    d.Transparency = 1
    d.Visible = false
    return d
end
local function newText(size, color)
    local d = Drawing.new("Text")
    d.Size = size
    d.Color = color
    d.Outline = true
    d.Center = true
    d.Visible = false
    return d
end

local RIG_BONES_R15 = {
    { "Head", "UpperTorso" },
    { "UpperTorso", "LowerTorso" },
    { "UpperTorso", "LeftUpperArm" },
    { "LeftUpperArm", "LeftLowerArm" },
    { "LeftLowerArm", "LeftHand" },
    { "UpperTorso", "RightUpperArm" },
    { "RightUpperArm", "RightLowerArm" },
    { "RightLowerArm", "RightHand" },
    { "LowerTorso", "LeftUpperLeg" },
    { "LeftUpperLeg", "LeftLowerLeg" },
    { "LeftLowerLeg", "LeftFoot" },
    { "LowerTorso", "RightUpperLeg" },
    { "RightUpperLeg", "RightLowerLeg" },
    { "RightLowerLeg", "RightFoot" },
}
local RIG_BONES_R6 = {
    { "Head", "Torso" },
    { "Torso", "Left Arm" },
    { "Torso", "Right Arm" },
    { "Torso", "Left Leg" },
    { "Torso", "Right Leg" },
}

local function detectRigType(model)
    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum then return hum.RigType == Enum.HumanoidRigType.R15 end
    return model:FindFirstChild("UpperTorso") ~= nil
end

local function buildPartCache(model)
    local parts = {}
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then parts[#parts + 1] = p end
    end
    _espPartCache[model] = parts
end

local function makeESP(model, isNPC)
    if ESPObjects[model] then return end
    local isR15 = detectRigType(model)
    local bones = isR15 and RIG_BONES_R15 or RIG_BONES_R6
    local skeleton = {}
    for i = 1, #bones do
        skeleton[i] = newLine(CFG.BoxThickness, CFG.BoxColor)
    end
    ESPObjects[model] = {
        skeleton = skeleton,
        bones = bones,
        jointCache = nil,
        jointScreen = nil,
        isNPC = isNPC or false,
        hpBar = newLine(CFG.HPBarWidth, Color3.new(0, 1, 0)),
        nameLabel = newText(CFG.NameSize, Color3.fromRGB(255, 255, 255)),
        distLabel = newText(13, Color3.fromRGB(255, 235, 120)),
        hpText = newText(14, Color3.fromRGB(110, 255, 165)),
        hpBack = newLine(CFG.HPBarWidth + 2, Color3.fromRGB(0, 0, 0)),
        _vis = false,
        lastDistStr = "",
        lastHpStr = "",
        staggerId = _staggerCounter % 4,
    }
    _staggerCounter = _staggerCounter + 1
    if CFG.BypassAntiESP then buildPartCache(model) end
end

local function removeESP(model)
    local obj = ESPObjects[model]
    if not obj then return end
    for _, l in ipairs(obj.skeleton) do
        pcall(function() l:Remove() end)
    end
    for _, k in ipairs({ "hpBar", "hpBack", "nameLabel", "distLabel", "hpText" }) do
        pcall(function() obj[k]:Remove() end)
    end
    ESPObjects[model] = nil
    _espPartCache[model] = nil
    _excludedCache[model] = nil
end

-- OPTIMIZE: Only update Visible property if it changed
local function setVisible(obj, v)
    if obj._vis == v then return end
    obj._vis = v
    obj._skelMode = nil -- OPTIMIZE (CPU): เส้นทั้งหมดถูกซ่อน/แสดงใหม่ → ต้องวาด skeleton ใหม่ครั้งถัดไป
    for i = 1, #obj.skeleton do
        obj.skeleton[i].Visible = v
    end
    obj.hpBar.Visible = v
    obj.hpBack.Visible = v
    obj.nameLabel.Visible = v
    obj.distLabel.Visible = v
    obj.hpText.Visible = v
end

-- OPTIMIZE: no per-frame table alloc for the far-mode box (was allocating 1 outer + 4 inner tables every object every frame)
local function applyBoxLine(obj, i, ax, ay, bx, by)
    local line = obj.skeleton[i]
    if not line then return end
    if line.Thickness ~= CFG.BoxThickness then line.Thickness = CFG.BoxThickness end
    if line.Color ~= CFG.BoxColor then line.Color = CFG.BoxColor end
    line.From = v2_new(ax, ay)
    line.To = v2_new(bx, by)
    line.Visible = true
end

-- OPTIMIZE: Massive Performance Boost
local function updateESPObject(model, obj, Camera, myRoot, myPos, fastRotate)
    -- OPTIMIZE: cache root/humanoid on the obj instead of FindFirstChild every frame;
    -- only re-look-up when the cached ref went stale (character respawned/parts swapped)
    local root = obj.rootCache
    if not root or not root.Parent then
        root = model:FindFirstChild("HumanoidRootPart")
        obj.rootCache = root
    end
    local hum = obj.humCache
    if not hum or not hum.Parent then
        hum = model:FindFirstChildOfClass("Humanoid")
        obj.humCache = hum
    end
    local isValid = myRoot ~= nil

    if not root or not hum then isValid = false end
    if isValid and CFG.HideDeadESP and hum.Health <= 0 then isValid = false end

    local plr = nil
    local dist = 0
    if isValid and myPos then
        dist = (myPos - root.Position).Magnitude
        if dist > CFG.MaxDist then isValid = false end

        if isValid then
            if not obj.isNPC then
                plr = Players:GetPlayerFromCharacter(model)
                if not plr then
                    isValid = false
                elseif CFG.HideFriends and FriendSet[plr.UserId] then
                    isValid = false
                end
            elseif isESPExcluded(model) then
                removeESP(model)
                return
            end
        end
    end

    if isValid and CFG.BypassAntiESP then
        local parts = _espPartCache[model]
        if parts then
            for i = 1, #parts do
                local p = parts[i]
                if p.Parent then p.LocalTransparencyModifier = 0 end
            end
        elseif not _espCacheBuild[model] then
            _espCacheBuild[model] = true
            task.spawn(function()
                local newParts = {}
                local idx = 1
                for _, p in ipairs(model:GetDescendants()) do
                    if p:IsA("BasePart") then
                        newParts[idx] = p
                        idx = idx + 1
                    end
                end
                _espPartCache[model] = newParts
                _espCacheBuild[model] = nil
            end)
        end
    end

    -- FIX (flicker / ESP-sticks-to-screen): always re-project the 3 anchor points
    -- every frame. The old code reused `lastPos3/lastTopPos3/lastBotPos3` on some
    -- frames to save a few WorldToViewportPoint calls — but a cached *screen* coord
    -- is only valid for the camera pose at the instant it was captured. The moment
    -- the camera turned, the cached box was drawn at the previous screen position,
    -- which is exactly why ESP "followed" the camera when you looked away and
    -- flickered as it alternated between stale and fresh frames.
    --
    -- Cost of always projecting: 3 extra WorldToViewportPoint calls per target per
    -- frame. The bone loop below already does up to 14 more per target, so this is
    -- a rounding error and the flicker is gone.
    if not isValid then
        setVisible(obj, false)
        return
    end

    local vp = Camera.ViewportSize
    local pos3 = Camera:WorldToViewportPoint(root.Position)
    if pos3.Z <= Z_MARGIN or pos3.X < 0 or pos3.X > vp.X or pos3.Y < 0 or pos3.Y > vp.Y then
        setVisible(obj, false)
        return
    end

    local head = obj.headCache
    if not head or not head.Parent then
        head = model:FindFirstChild("Head") or root
        obj.headCache = head
    end
    local topPos3 = Camera:WorldToViewportPoint(head.Position + v3_new(0, head.Size.Y / 2 + 0.3, 0))
    local botPos3 = Camera:WorldToViewportPoint(root.Position - v3_new(0, 3, 0))

    if
        topPos3.Z <= Z_MARGIN
        or botPos3.Z <= Z_MARGIN
        or topPos3.X < 0
        or topPos3.X > vp.X
        or topPos3.Y < 0
        or topPos3.Y > vp.Y
        or botPos3.X < 0
        or botPos3.X > vp.X
        or botPos3.Y < 0
        or botPos3.Y > vp.Y
    then
        setVisible(obj, false)
        return
    end

    -- Sync visibility flag. Drawings are individually re-shown below (skeleton
    -- lines / hpBar / labels), so we don't need to touch them here — this is just
    -- so setVisible(obj,false) on a future invalid frame isn't a no-op.
    obj._vis = true

    local cx = pos3.X
    local y1 = m_min(topPos3.Y, botPos3.Y)
    local y2 = m_max(topPos3.Y, botPos3.Y)
    local h = y2 - y1

    if h < 2 then h = 2 end
    local w = h * 0.6
    local x1, x2 = cx - w / 2, cx + w / 2

    -- LOD: โครงกระดูกเต็มรูปแบบต้องคำนวณ WorldToViewportPoint เพิ่มอีก ~14 จุดต่อตัวต่อเฟรม
    -- (นอกเหนือจาก 3 จุดที่คำนวณไปแล้วข้างบนสำหรับเช็คความถูกต้อง) ถ้ามีคน/NPC เยอะพร้อมกันนี่คือจุดที่กินเฟรมสุด
    -- เลยจำกัดไว้แค่ระยะใกล้ (CFG.ESPDetailDist) ไกลกว่านั้นวาดกรอบสี่เหลี่ยมง่ายๆจาก 4 จุดที่มีอยู่แล้วพอ ไม่ต้องยิง WorldToViewportPoint เพิ่มเลย
    local detailDist = CFG.ESPDetailDist or 120 -- fallback เผื่อ CFG.json เก่าที่ยังไม่มี field นี้
    local useDetail = dist <= detailDist

    -- OPTIMIZE (แก้ตามที่คุย): โครงกระดูกคือจุดที่แพงสุดต่อ object (~14 WorldToViewportPoint
    -- เพิ่มต่อเฟรม) ตัวที่อยู่ไกลหน่อย (แต่ยังอยู่ในระยะ detail) ไม่จำเป็นต้อง refresh ทุกเฟรม
    -- reuse jointScreen เดิมแล้ววาดเส้นซ้ำ — ใกล้มากๆ (DETAIL_CLOSE_RANGE) ยัง refresh ทุกเฟรมเหมือนเดิม
    -- เพื่อไม่ให้เห็นการหน่วงตอนประชิดตัว
    --
    -- FIX: joints are screen-space too — during any camera motion they must be
    -- re-projected or the skeleton visibly lags the bounding box. fastRotate is
    -- now sensitive enough (see ROTATE_ANGLE_THRESHOLD) to trip on real turns,
    -- so the stride only kicks in when the camera is essentially static.
    local DETAIL_CLOSE_RANGE = 25
    local detailStride = (fastRotate or dist <= DETAIL_CLOSE_RANGE) and 1 or 3
    local skipDetailRefresh = useDetail
        and detailStride > 1
        and obj.jointScreen ~= nil
        and not fastRotate
        and ((_frameCounter + obj.staggerId) % detailStride ~= 0)

    if useDetail and not skipDetailRefresh then
        local joints = obj.jointCache
        if not joints then
            joints = {}
            obj.jointCache = joints
        end
        for _, bone in ipairs(obj.bones) do
            for _, jname in ipairs(bone) do
                -- FIX: ถ้า part ที่ cache ไว้โดน Destroy/หลุดออกจาก model ไปแล้ว (Parent เป็น nil)
                -- ต้องหาใหม่ ไม่งั้น Position จะค้างอยู่ค่าสุดท้ายก่อนโดนทำลาย ทำให้เส้นโครงกระดูกลอยค้างจุดเดิม
                local cached = joints[jname]
                if not cached or not cached.Parent then joints[jname] = model:FindFirstChild(jname) end
            end
        end

        local jointScreen = obj.jointScreen
        if not jointScreen then
            jointScreen = {}
            obj.jointScreen = jointScreen
        end
        for jname, part in pairs(joints) do
            if part and part.Parent then
                local vp2 = Camera:WorldToViewportPoint(part.Position)
                jointScreen[jname] = (vp2.Z > 0) and vp2 or nil
            else
                jointScreen[jname] = nil
            end
        end

        for i, bone in ipairs(obj.bones) do
            local line = obj.skeleton[i]
            local v1, v2 = jointScreen[bone[1]], jointScreen[bone[2]]
            if v1 and v2 then
                if line.Thickness ~= CFG.BoxThickness then line.Thickness = CFG.BoxThickness end
                if line.Color ~= CFG.BoxColor then line.Color = CFG.BoxColor end
                line.From = v2_new(v1.X, v1.Y)
                line.To = v2_new(v2.X, v2.Y)
                line.Visible = true
            else
                if line.Visible then line.Visible = false end
            end
        end
        obj._skelMode = "detail"
    elseif useDetail then
        -- เฟรมที่ไม่ refresh: jointScreen เดิมไม่เปลี่ยน และ Drawing เก็บ From/To/Visible ล่าสุดไว้แล้ว
        -- OPTIMIZE (CPU): ถ้าเส้นถูกวาดจาก jointScreen ชุดนี้อยู่แล้ว (_skelMode == "detail") ไม่ต้องเขียนซ้ำ
        -- (เดิมสร้าง Vector2 x2 + เขียน From/To/Visible ครบทุกเส้น ~14 เส้น/ตัว ทุกเฟรมที่ข้าม refresh)
        -- วาดซ้ำเฉพาะตอนเพิ่งสลับมาจากโหมดไกล/เพิ่งโผล่กลับเข้าจอ (_skelMode ถูกรีเซ็ต)
        if obj._skelMode ~= "detail" then
            local jointScreen = obj.jointScreen
            for i, bone in ipairs(obj.bones) do
                local line = obj.skeleton[i]
                local v1, v2 = jointScreen[bone[1]], jointScreen[bone[2]]
                if v1 and v2 then
                    line.From = v2_new(v1.X, v1.Y)
                    line.To = v2_new(v2.X, v2.Y)
                    line.Visible = true
                else
                    if line.Visible then line.Visible = false end
                end
            end
            obj._skelMode = "detail"
        end
    else
        -- โหมดไกล: ใช้แค่ 4 เส้นแรกของ skeleton array วาดเป็นกรอบสี่เหลี่ยม จาก x1,y1,x2,y2 ที่มีอยู่แล้ว
        -- OPTIMIZE: เขียนตรงแทนสร้าง table ชั่วคราว (boxPts) ทุกเฟรมทุกตัว ลด GC churn ตอนมีคน/NPC ไกลๆ เยอะ
        applyBoxLine(obj, 1, x1, y1, x2, y1) -- บน
        applyBoxLine(obj, 2, x2, y1, x2, y2) -- ขวา
        applyBoxLine(obj, 3, x2, y2, x1, y2) -- ล่าง
        applyBoxLine(obj, 4, x1, y2, x1, y1) -- ซ้าย
        -- OPTIMIZE (CPU): เส้นที่ 5+ ซ่อนครั้งเดียวตอนเข้าโหมดกรอบ (เดิมอ่าน .Visible ทุกเส้นทุกเฟรม)
        if obj._skelMode ~= "box" then
            for i = 5, #obj.skeleton do
                if obj.skeleton[i].Visible then obj.skeleton[i].Visible = false end
            end
            obj._skelMode = "box"
        end
    end

    local hpR = m_clamp(hum.Health / m_max(hum.MaxHealth, 1), 0, 1)
    -- OPTIMIZE: skip recomputing Color3.fromRGB when the rounded hp% hasn't moved since last frame
    local hpBucket = m_floor(hpR * 200) -- 0.5% buckets, plenty smooth for a color gradient
    local hpColor = obj.lastHpBucket == hpBucket and obj.lastHpColor or nil
    if not hpColor then
        hpColor = hpR > 0.5 and Color3.fromRGB(m_floor(255 * (1 - hpR) * 2), 255, 0) or Color3.fromRGB(255, m_floor(255 * hpR * 2), 0)
        obj.lastHpBucket = hpBucket
        obj.lastHpColor = hpColor
    end
    if obj.hpBar.Color ~= hpColor then obj.hpBar.Color = hpColor end
    local bw = CFG.HPBarWidth
    if obj.hpBar.Thickness ~= bw then
        obj.hpBar.Thickness = bw
        obj.hpBack.Thickness = bw + 2
    end
    obj.hpBack.From = v2_new(x1 - 1, y2 + 5)
    obj.hpBack.To = v2_new(x2 + 1, y2 + 5)
    obj.hpBack.Visible = CFG.ShowHP
    obj.hpBar.From = v2_new(x1, y2 + 5)
    obj.hpBar.To = v2_new(x1 + (x2 - x1) * hpR, y2 + 5)
    obj.hpBar.Visible = CFG.ShowHP

    if CFG.ShowName then
        local nameStr = plr and plr.Name or model.Name
        if obj.nameLabel.Text ~= nameStr then obj.nameLabel.Text = nameStr end
        if obj.nameLabel.Size ~= CFG.NameSize then obj.nameLabel.Size = CFG.NameSize end
        obj.nameLabel.Position = v2_new(cx, y1 - CFG.NameSize - 4)
        obj.nameLabel.Visible = true
    else
        obj.nameLabel.Visible = false
    end

    if CFG.ShowDist then
        -- OPTIMIZE: เทียบค่าตัวเลขก่อน ไม่เรียก string.format ทุกเฟรมถ้าค่าปัดแล้วเท่าเดิม
        local distRounded = m_floor(dist + 0.5)
        if obj.lastDistRounded ~= distRounded then
            obj.lastDistRounded = distRounded
            obj.lastDistStr = distRounded .. "m"
            obj.distLabel.Text = obj.lastDistStr
        end
        obj.distLabel.Position = v2_new(cx, y2 + (CFG.ShowHPText and 28 or 11))
        obj.distLabel.Visible = true
    else
        obj.distLabel.Visible = false
    end

    if CFG.ShowHPText then
        local hpPct = m_floor(hpR * 100)
        local healthI, maxHealthI = m_floor(hum.Health), m_floor(hum.MaxHealth)
        -- OPTIMIZE: เทียบตัวเลขดิบก่อน ไม่ต่อ string ทุกเฟรมถ้าเลขเดิม (ลด GC churn ตอน ESP เยอะ)
        if obj.lastHpPct ~= hpPct or obj.lastHealthI ~= healthI or obj.lastMaxHealthI ~= maxHealthI then
            obj.lastHpPct, obj.lastHealthI, obj.lastMaxHealthI = hpPct, healthI, maxHealthI
            obj.hpText.Text = hpPct .. "%  (" .. healthI .. "/" .. maxHealthI .. ")"
        end
        local dynSize = 14
        if obj.hpText.Size ~= dynSize then obj.hpText.Size = dynSize end
        if obj.hpText.Color ~= hpColor then obj.hpText.Color = hpColor end
        obj.hpText.Position = v2_new(cx, y2 + 11)
        obj.hpText.Visible = true
    else
        obj.hpText.Visible = false
    end
end

RunService.RenderStepped:Connect(function()
    if not IsESPAuthorized then return end
    if not CFG.Enabled then return end
    _frameCounter = _frameCounter + 1
    -- SMOOTH: ระหว่างลาก UI ให้ ESP อัปเดตเฟรมเว้นเฟรม (Drawing ค้างตำแหน่งล่าสุดไว้) → เหลืองบเฟรมให้ UI ลื่น
    -- ปล่อยแล้วกลับมาเต็มอัตราเอง ปิดได้ที่ SW.THROTTLE_ESP_WHEN_DRAGGING = false
    if SW.THROTTLE_ESP_WHEN_DRAGGING and SW.isDragging and _frameCounter % 2 == 0 then return end
    local Camera = workspace.CurrentCamera
    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local myPos = myRoot and myRoot.Position

    -- FIX: วัดมุมที่กล้องหมุนเทียบกับเฟรมก่อนหน้า ถ้าหมุนเร็วเกิน threshold ให้ปิด stride-cache
    -- ชั่วคราวทั้งหมด (ดูฟังก์ชัน updateESPObject) ไม่งั้น ESP จะติดจอ/กะพริบตอนหมุนกล้องแรง ๆ
    _fastRotate = false
    if Camera then
        -- OPTIMIZE (CPU): เดิม pcall(function() ... end) สร้าง closure ใหม่ทุกเฟรม + math.acos ทุกเฟรม
        -- อ่าน CFrame ตรง ๆ ได้ (Camera ผ่านเช็ค nil แล้ว) และเทียบ dot กับ cos(threshold) ที่คำนวณไว้แล้วแทน
        local look = Camera.CFrame.LookVector
        if _lastCamLook then _fastRotate = look:Dot(_lastCamLook) < SW.ROTATE_COS_THRESHOLD end
        _lastCamLook = look
    end

    for model, obj in pairs(ESPObjects) do
        if not model.Parent then
            -- OPTIMIZE/FIX: โมเดลถูกลบ/ออกจากเกมไปแล้วแต่ event cleanup ไม่ทัน -> เก็บกวาดทิ้งเลย ไม่ปล่อยให้ ESP ค้างจอ
            removeESP(model)
        else
            pcall(updateESPObject, model, obj, Camera, myRoot, myPos, _fastRotate)
        end
    end
end)

local _plrConns = {}
local _npcConns = {}
local function trackPlayer(plr)
    if plr == LP then return end
    local function onChar(c)
        -- FIX: ถ้าเกมเปิด StreamingEnabled คนที่อยู่ไกลจากเรา HumanoidRootPart จะยังไม่ stream เข้ามา
        -- ถ้ารอแบบมี timeout แล้วยอมแพ้ (return ทิ้ง) จะไม่มีทาง sp ให้คนนั้นได้อีกเลยแม้จะเดินเข้ามาใกล้แล้ว
        -- เลยเปลี่ยนเป็นรอวนไม่จำกัดเวลา แต่เช็คทุกรอบว่าตัวละครยังอยู่จริงไหม (กันไม่ให้ค้างถ้าออกจากเกมไปแล้ว)
        while c.Parent and not c:FindFirstChild("HumanoidRootPart") do
            task.wait(1)
        end
        if not c.Parent or not c:FindFirstChild("HumanoidRootPart") then return end
        if ESPObjects[c] then removeESP(c) end
        makeESP(c, false)
        c.DescendantAdded:Connect(function(d)
            if d:IsA("BasePart") then _espPartCache[c] = nil end
        end)
        c.AncestryChanged:Connect(function(_, p)
            if not p then
                removeESP(c)
                _espPartCache[c] = nil
            end
        end)
    end
    local cr = plr.CharacterRemoving:Connect(function(c)
        removeESP(c)
        _espPartCache[c] = nil
    end)
    local ca = plr.CharacterAdded:Connect(function(c) task.spawn(onChar, c) end)
    if plr.Character then task.spawn(onChar, plr.Character) end
    _plrConns[plr] = { ca, cr }
end
Players.PlayerAdded:Connect(trackPlayer)
Players.PlayerRemoving:Connect(function(plr)
    if _plrConns[plr] then
        for _, c in ipairs(_plrConns[plr]) do
            c:Disconnect()
        end
        _plrConns[plr] = nil
    end
    if plr.Character then
        removeESP(plr.Character)
        _espPartCache[plr.Character] = nil
    end
end)
for _, plr in ipairs(Players:GetPlayers()) do
    trackPlayer(plr)
end

local esp = {}
function esp:FireScan()
    if not IsESPAuthorized then return end
    if not CFG.Enabled then
        for _, obj in pairs(ESPObjects) do
            setVisible(obj, false)
        end
        return
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character and not ESPObjects[plr.Character] then makeESP(plr.Character, false) end
    end
end
function esp:ScanWorkspace()
    if not IsESPAuthorized then return end
    -- เดินทีละชั้นด้วย GetChildren + เว้นเฟรมทุก 250 โหนด (เดิม GetDescendants() ก้อนเดียวบนแผนที่ใหญ่ = เฟรมค้าง)
    local queue, qh, qt, count = { workspace }, 1, 1, 0
    while qh <= qt do
        local node = queue[qh]
        queue[qh] = false
        qh = qh + 1
        local okc, kids = pcall(node.GetChildren, node)
        if okc then
            for i = 1, #kids do
                local obj = kids[i]
                qt = qt + 1
                queue[qt] = obj
                count = count + 1
                if count % 250 == 0 then task.wait() end
                if
                    obj:IsA("Model")
                    and obj:FindFirstChildOfClass("Humanoid")
                    and not Players:GetPlayerFromCharacter(obj)
                    and obj ~= LP.Character
                    and not isESPExcluded(obj)
                then
                    if not ESPObjects[obj] then makeESP(obj, true) end
                    if not _npcConns[obj] then
                        _npcConns[obj] = obj.AncestryChanged:Connect(function(_, p)
                            if not p then
                                removeESP(obj)
                                _espPartCache[obj] = nil
                                if _npcConns[obj] then
                                    _npcConns[obj]:Disconnect()
                                    _npcConns[obj] = nil
                                end
                            end
                        end)
                    end
                end
            end
        end
    end
end
function esp:Clear()
    for model in pairs(ESPObjects) do
        removeESP(model)
    end
    _espPartCache = {}
    _espCacheBuild = {}
end
esp.RemoveAll = esp.Clear

task.spawn(function()
    local _npcDescDebounce = setmetatable({}, { __mode = "k" })
    workspace.DescendantAdded:Connect(function(desc)
        if not CFG.Enabled or not CFG.NPCSESP then return end
        if not desc:IsA("Model") then return end
        if _npcDescDebounce[desc] then return end
        _npcDescDebounce[desc] = true
        task.delay(1, function()
            _npcDescDebounce[desc] = nil
            if not desc.Parent then return end
            if
                desc:FindFirstChildOfClass("Humanoid")
                and not Players:GetPlayerFromCharacter(desc)
                and desc ~= LP.Character
                and not isESPExcluded(desc)
                and not ESPObjects[desc]
            then
                makeESP(desc, true)
                if not _npcConns[desc] then
                    _npcConns[desc] = desc.AncestryChanged:Connect(function(_, p)
                        if not p then
                            removeESP(desc)
                            _espPartCache[desc] = nil
                            if _npcConns[desc] then
                                _npcConns[desc]:Disconnect()
                                _npcConns[desc] = nil
                            end
                        end
                    end)
                end
            end
        end)
    end)
end)

-- ── สร้างแท็บทั้งหมดก่อน (โครงแท็บ/ปุ่มขึ้นครบทันที) แล้วค่อยทยอยโหลด "เนื้อหา" ในแต่ละแท็บทีหลัง ──
local HomeTab = Window:Tab({ Title = "Home", Icon = "house", Locked = false })
Window:Divider()
local FarmTab = Window:Tab({ Title = "Menu", Icon = "archive", Locked = false })
local ESPTab = Window:Tab({ Title = "ESP", Icon = IsESPAuthorized and "eye" or "lock", Locked = not IsESPAuthorized })
local TeleportTab = Window:Tab({ Title = "Teleport", Icon = "map-pin", Locked = false })
Window:Divider()
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings", Locked = false })

-- SMOOTH LOAD: ตัวคั่นเฟรมอัตโนมัติตอนสร้างเนื้อหาแท็บ
-- ทุกครั้งที่สร้าง Section/Toggle/Dropdown/Slider ฯลฯ จะเช็คว่าเฟรมนี้ใช้เวลาไปเกิน ~6ms หรือยัง ถ้าเกินก็ปล่อยเฟรมให้วาด UI ก่อน
-- (เดิมสร้าง element ทีเดียวหลายสิบตัวในเฟรมเดียว → กระตุกตอนโหลด) | ปิดเองอัตโนมัติเมื่อสร้างเสร็จ หรือครบ 40 วิ
-- ใช้ตัวแปรใน SW ทั้งหมด ไม่เพิ่ม local ระดับไฟล์ (กันชนโควตา local 200 ตัว)
SW.building, SW.lastY, SW.frameBudget = true, os.clock(), 0.006
task.delay(40, function() SW.building = false end)
SW.softYield = function()
    if SW.building and os.clock() - SW.lastY >= SW.frameBudget then
        task.wait()
        SW.lastY = os.clock()
    end
end
do
    local ELEM = {
        Toggle = true,
        Button = true,
        Dropdown = true,
        Slider = true,
        Input = true,
        Keybind = true,
        Colorpicker = true,
        Paragraph = true,
        Code = true,
        Space = true,
        Divider = true,
    }
    local function wrapSection(sec)
        return setmetatable({}, {
            __index = function(_, k)
                local v = sec[k]
                if type(v) ~= "function" then return v end
                if ELEM[k] then
                    return function(_, ...)
                        local r = v(sec, ...)
                        SW.softYield()
                        return r
                    end
                end
                return function(_, ...) return v(sec, ...) end
            end,
            __newindex = function(_, k, val) sec[k] = val end,
        })
    end
    for _, t in ipairs({ HomeTab, FarmTab, ESPTab, TeleportTab, SettingsTab }) do
        local orig = t.Section
        if type(orig) == "function" then
            t.Section = function(_, ...)
                local s = orig(t, ...)
                SW.softYield()
                if type(s) == "table" then return wrapSection(s) end
                return s
            end
        end
    end
end

-- ── TAB: HOME — หน้า "มีอะไรใหม่" (Changelog) ──
-- เพิ่มอัปเดตใหม่: ใส่ก้อนใหม่ "บนสุด" ของ SW.Changelog (ก้อนบนสุดจะเปิดค้างไว้ ก้อนเก่าพับให้) — แก้แค่ตรงนี้ที่เดียว
-- added = สิ่งที่เพิ่มใหม่ | fixed = สิ่งที่แก้/ปรับปรุง (ใส่ได้ทีละหลายบรรทัด เว้นว่างได้ถ้าไม่มี)
SW.Changelog = {
    {
        title = "อัปเดตล่าสุด • 2026-10-03",
        added = {
            "หน้า Home แสดงรายการอัปเดต (เพิ่มอะไร / แก้อะไร) ที่คุณกำลังอ่านอยู่นี้",
            "เอฟเฟกต์ตอนกดปิดที่ปุ่มรูปแบบใหม่: แสงฟุ้งและสะเก็ดแสงม่วง/ฟ้าไหลเข้าหาปุ่ม พร้อมวงแหวนไล่สีหดมาชนขอบปุ่ม",
        },
        fixed = {
            "ปุ่มรูปตอนปิด: ยุบลงเล็กน้อยแล้วเด้งคืนนุ่มๆ แทนการหดธรรมดา และขอบปุ่มวาบสีม่วงตอนแสงถึง",
            "กดปุ่มรัวๆ ระหว่างเล่นเอฟเฟกต์แล้วแอนิเมชันไม่ซ้อนกัน",
        },
    },
}

-- ลิงก์ changelog.lua บน GitHub (ไฟล์ต้อง return ตารางแบบเดียวกับ SW.Changelog ด้านบน)
-- โหลดไม่ได้/ไฟล์พัง/รูปแบบไม่ถูก → ใช้ SW.Changelog ที่ฝังไว้ด้านบนแทนอัตโนมัติ (หน้า Home ไม่ว่าง)
SW.ChangelogURL = "https://raw.githubusercontent.com/SpectreWareZ/SpectreWare/refs/heads/main/Tools/changelog.lua"

SW.LoadHome = function()
    local list = SW.Changelog
    pcall(function()
        -- ต่อ ?v=เวลา กัน cache ของ GitHub raw ให้เห็นข้อความใหม่ทันทีหลังแก้ไฟล์
        local src = game:HttpGet(SW.ChangelogURL .. "?v=" .. os.time(), true)
        local fn = loadstring(src)
        local remote = fn and fn()
        if type(remote) ~= "table" then return end
        local ok = {}
        for _, e in ipairs(remote) do
            if type(e) == "table" and type(e.title) == "string" then ok[#ok + 1] = e end
        end
        if #ok > 0 then list = ok end
    end)
    for i, entry in ipairs(list) do
        local sec = HomeTab:Section({ Title = entry.title, Icon = (i == 1) and "sparkles" or "history", Opened = (i == 1) })
        local function block(title, icon, list)
            if not list or #list == 0 then return end
            local lines = {}
            for k, line in ipairs(list) do
                lines[k] = "• " .. line
            end
            sec:Paragraph({ Title = title, Desc = table.concat(lines, "\n"), Icon = icon })
        end
        block("เพิ่มใหม่", "plus-circle", entry.added)
        block("แก้ไข / ปรับปรุง", "wrench", entry.fixed)
    end
end

-- ── TAB: MENU / FARM (เนื้อหาโหลดทีหลัง ผ่านตัวคุมลำดับด้านล่างสุดของไฟล์) ──
local function LoadFarmTab() -- เนื้อหาแท็บ Menu (Farm)
    local DepositRemote, FarmRunning = nil, false
    local BACKPACK_GUI = "Backpack_Never"

    local function getScrolling()
        local bp = LP.PlayerGui:FindFirstChild(BACKPACK_GUI)
        if not bp then return nil end
        local bg = bp:FindFirstChild("BG")
        if not bg then return nil end
        local it = bg:FindFirstChild("item")
        if not it then return nil end
        return it:FindFirstChild("Scrollingitem")
    end

    local ITEM_THAI = {
        ["Grape"] = "องุ่น",
        ["Peach"] = "พีช",
        ["Orange"] = "ส้ม",
        ["Cauliflower"] = "กะหล่ำดอก",
        ["Corn"] = "ข้าวโพด",
        ["Gold"] = "ทอง",
        ["Iron"] = "เหล็ก",
        ["MineIron"] = "แร่เหล็ก",
        ["MineGold"] = "แร่ทอง",
    }

    local BLOCKED_ITEMS = {
        ["CASH"] = true,
        ["IDCard"] = true,
        ["R8"] = true,
        ["Classic"] = true,
    }

    local function loadBackpackItems()
        local scrolling = getScrolling()
        if not scrolling then
            local ok, s = pcall(
                function()
                    return LP.PlayerGui
                        :WaitForChild(BACKPACK_GUI, 5)
                        :WaitForChild("BG", 5)
                        :WaitForChild("item", 5)
                        :WaitForChild("Scrollingitem", 5)
                end
            )
            if ok then scrolling = s end
        end

        local titles, itemMap = {}, {}
        if scrolling then
            local count = 0
            for _, slot in ipairs(scrolling:GetChildren()) do
                if not slot:IsA("Frame") then continue end
                local name = slot.Name
                if name == "" or name == "Animation" then continue end
                if BLOCKED_ITEMS[name] then continue end
                count = count + 1
                if count % 10 == 0 then task.wait() end

                local max = 60
                local nl = name:lower()
                if nl:find("stone") or nl:find("gold") or nl:find("iron") then max = 500 end
                pcall(function()
                    local a = slot:FindFirstChild("Amout", true)
                    if a and a:IsA("TextLabel") then
                        local m = tonumber(a.Text:match("%d+|(%d+)"))
                        if m and m > 0 then max = m end
                    end
                end)

                local icon
                pcall(function()
                    local img = slot:FindFirstChild("ItemImage")
                    local src = (img and (img:IsA("ImageLabel") or img:IsA("ImageButton")) and img)
                        or (img and (img:FindFirstChildWhichIsA("ImageLabel") or img:FindFirstChildWhichIsA("ImageButton")))
                        or slot:FindFirstChildWhichIsA("ImageLabel", true)
                        or slot:FindFirstChildWhichIsA("ImageButton", true)
                    if src and src.Image ~= "" then icon = src.Image end
                end)

                local thaiName = ITEM_THAI[name]
                local displayName = thaiName and (name .. " (" .. thaiName .. ")") or name
                t_insert(titles, displayName)
                itemMap[displayName] = { Title = displayName, value = name, max = max, icon = icon }
            end
        end
        if #titles == 0 then
            titles = { "(ไม่พบไอเทม)" }
            itemMap["(ไม่พบไอเทม)"] = { Title = "(ไม่พบไอเทม)", value = "", max = 0 }
        end
        local PINNED_ORDER = { "Cauliflower", "Corn", "Peach", "Grape", "Orange", "Gold", "Iron", "MineIron", "MineGold" }
        local pinnedSet, rest = {}, {}
        for _, t in ipairs(titles) do
            local entry = itemMap[t]
            if entry then
                pinnedSet[entry.value] = t
            else
                t_insert(rest, t)
            end
        end
        local pinnedKeys = {}
        for _, v in ipairs(PINNED_ORDER) do
            pinnedKeys[v] = true
        end
        for _, t in ipairs(titles) do
            local entry = itemMap[t]
            if entry and not pinnedKeys[entry.value] then t_insert(rest, t) end
        end
        titles = {}
        for _, key in ipairs(PINNED_ORDER) do
            if pinnedSet[key] then t_insert(titles, pinnedSet[key]) end
        end
        for _, t in ipairs(rest) do
            t_insert(titles, t)
        end
        return titles, itemMap
    end

    local PLACEHOLDER = "Reload"
    local FarmItemTitles = { PLACEHOLDER }
    local FarmItemMap = { [PLACEHOLDER] = { Title = PLACEHOLDER, value = "", max = 60 } }
    local SelectedItem = FarmItemMap[PLACEHOLDER]
    local CustomMax = 60
    local CustomMaxSet = false
    local UserSelectedItem = false
    local ItemDropdown = nil
    local _suppressItemCallback = false
    local FarmSection = FarmTab:Section({ Title = "Deposit Settings", Icon = "package", Opened = true })
    local AutoFarmToggle

    local function setInSafe(text)
        if SafeDescLabel and SafeDescLabel.Parent then pcall(function() SafeDescLabel.Text = tostring(text) end) end
    end

    local function refreshSafePreview()
        buildSafeHud()
        local card = getHudCard()
        if not SelectedItem or SelectedItem.value == "" or not UserSelectedItem then
            setInSafe("-- ยังไม่ได้เลือกไอเทม")
            if card then card.Visible = false end
            return
        end
        local qty = getSafeQty(SelectedItem.value)
        local icon = SelectedItem.icon or ""
        setInSafe(SelectedItem.value .. "  ×  " .. tostring(qty) .. "  ในตู้")
        if _hudIcon then _hudIcon.Image = icon end
        if _hudName then _hudName.Text = SelectedItem.value end
        if _hudCount then _hudCount.Text = "×" .. SW.fmt(qty) .. ' <font size="11" color="rgb(150,141,190)">ในตู้</font>' end
        if card then card.Visible = true end
    end

    local _injectPending = false

    -- ไอคอนในลิสต์ dropdown: คำนวณขนาดจากความสูงจริงของแถว (p.AbsoluteSize.Y)
    -- แทนที่จะ hardcode 22px ตายตัว ไม่งั้นแถวสูงแค่ไหนไอคอนก็เท่าเดิม ดูลอยเล็กเมื่อเทียบกับแถว
    local ICON_PAD = 6 -- ระยะห่างขอบบน/ล่างของแถว
    local ICON_GAP = 8 -- ระยะห่างระหว่างไอคอนกับข้อความ
    local ICON_MAX = 34 -- เพดานกันไอคอนใหญ่เกินไปถ้าแถวสูงมาก

    local function injectIconLabel(lbl)
        local entry = FarmItemMap[lbl.Text]
        if not entry or not entry.icon then return end
        local p = lbl.Parent
        if not p then return end

        local rowH = p.AbsoluteSize.Y
        if rowH <= 0 then rowH = 32 end -- fallback ถ้าเฟรมยังไม่ render ขนาดจริง
        local iconSize = m_clamp(rowH - ICON_PAD * 2, 16, ICON_MAX)
        local shiftX = iconSize + ICON_GAP

        local existing = p:FindFirstChild("SW_Icon")
        if existing then
            existing.Image = entry.icon
            existing.Size = UDim2.fromOffset(iconSize, iconSize)
            existing.Position = UDim2.new(0, ICON_PAD, 0.5, -iconSize / 2)
            return
        end

        local img = Instance.new("ImageLabel")
        img.Name = "SW_Icon"
        img.BackgroundTransparency = 1
        img.Size = UDim2.fromOffset(iconSize, iconSize)
        img.Position = UDim2.new(0, ICON_PAD, 0.5, -iconSize / 2)
        img.Image = entry.icon
        img.ZIndex = lbl.ZIndex + 1
        img.Parent = p
        pcall(function() lbl.Position = UDim2.new(0, shiftX, lbl.Position.Y.Scale, lbl.Position.Y.Offset) end)
    end

    SW._injQ = setmetatable({}, { __mode = "k" }) -- labels that appeared / changed text since the last pass
    SW._injFull = false
    -- PERF: event-driven callers queue just the label (targeted pass); explicit rebuild callers pass full=true for one full scan
    local function injectIconsIntoDropdown(full)
        if full == true then SW._injFull = true end
        if _injectPending then return end
        _injectPending = true
        task.delay(0.15, function()
            _injectPending = false
            local doFull = SW._injFull
            SW._injFull = false
            pcall(function()
                if doFull then
                    for _, sg in ipairs(LP.PlayerGui:GetChildren()) do
                        if not sg:IsA("ScreenGui") then continue end
                        local n = sg.Name
                        if not (n == "WindUI" or n:sub(1, 7) == "WindUI/") then continue end
                        for _, lbl in ipairs(sg:GetDescendants()) do
                            if lbl:IsA("TextLabel") and FarmItemMap[lbl.Text] then injectIconLabel(lbl) end
                        end
                    end
                    table.clear(SW._injQ)
                else
                    for lbl in pairs(SW._injQ) do
                        SW._injQ[lbl] = nil
                        if lbl.Parent and FarmItemMap[lbl.Text] then injectIconLabel(lbl) end
                    end
                end
            end)
        end)
    end

    task.spawn(function()
        local _labelConnected = setmetatable({}, { __mode = "k" })
        -- OPTIMIZE: เดิมดัก DescendantAdded จาก LP.PlayerGui ทั้งก้อน ซึ่งรวม GUI อื่นๆทั้งหมดในเกม
        -- (chat, popup, GUI ของเกมเอง ฯลฯ) ทำให้ handler นี้ถูกเรียกถี่มากตลอดเวลาเล่นทั้งที่จริงๆสนใจแค่ label
        -- ที่ WindUI สร้างเอง เลยเปลี่ยนไปดักเฉพาะใน WindUIGui ที่จับไว้ตอนโหลด lib (ลด event ที่ไม่เกี่ยวข้องไปเกือบทั้งหมด)
        local listenTarget = WindUIGui or LP.PlayerGui
        listenTarget.DescendantAdded:Connect(function(obj)
            if not obj:IsA("TextLabel") then return end
            if listenTarget == LP.PlayerGui then
                local sg = obj:FindFirstAncestorWhichIsA("ScreenGui")
                if not sg then return end
                local n = sg.Name
                if not (n == "WindUI" or n:sub(1, 7) == "WindUI/") then return end
            end
            if FarmItemMap[obj.Text] then
                SW._injQ[obj] = true
                injectIconsIntoDropdown()
            end
            if _labelConnected[obj] then return end
            _labelConnected[obj] = true
            obj:GetPropertyChangedSignal("Text"):Connect(function()
                if FarmItemMap[obj.Text] then
                    SW._injQ[obj] = true
                    injectIconsIntoDropdown()
                end
            end)
        end)
    end)

    local function createItemDropdown(titles, itemMap)
        local values = {}
        for _, name in ipairs(titles) do
            local e = itemMap[name]
            t_insert(values, (e and e.icon) and { Title = name, Icon = e.icon } or name)
        end
        if ItemDropdown then
            local ok = pcall(function() ItemDropdown:Refresh(values) end)
            if ok then
                local firstKey = optionKey(values[1])
                SelectedItem = itemMap[firstKey]
                if SelectedItem then CustomMax = SelectedItem.max end
                task.delay(0.05, function()
                    pcall(function()
                        local dd = ItemDropdown.UIElements and ItemDropdown.UIElements.Dropdown
                        if not dd then return end
                        local inner = dd.Frame.Frame
                        local lbl = inner.TextLabel
                        lbl.Text = firstKey
                    end)
                end)
            else
                pcall(function() ItemDropdown:Destroy() end)
                ItemDropdown = nil
            end
        end
        if not ItemDropdown then
            ItemDropdown = FarmSection:Dropdown({
                Title = "Select Item",
                Desc = "อ่านจาก Backpack ของคุณโดยตรง",
                Values = values,
                Value = values[1],
                SearchBarEnabled = true,
                Callback = function(option)
                    if _suppressItemCallback then return end
                    local key = optionKey(option)
                    if UserSelectedItem and SelectedItem and SelectedItem.Title == key then
                        UserSelectedItem = false
                        SelectedItem = FarmItemMap[PLACEHOLDER]
                        refreshSafePreview()
                        task.delay(0.05, function()
                            pcall(function()
                                local dd = ItemDropdown.UIElements and ItemDropdown.UIElements.Dropdown
                                if dd then dd.Frame.Frame.TextLabel.Text = "-- ยังไม่ได้เลือก --" end
                            end)
                        end)
                        return
                    end
                    SelectedItem = FarmItemMap[key]
                    if SelectedItem then CustomMax = SelectedItem.max end
                    UserSelectedItem = true
                    injectIconsIntoDropdown(true)
                    refreshSafePreview()
                end,
            })
            task.delay(0.1, function()
                pcall(function()
                    local dd = ItemDropdown.UIElements and ItemDropdown.UIElements.Dropdown
                    if not dd then return end
                    local inner = dd.Frame.Frame
                    local lbl = inner.TextLabel
                    local iconShifted = false

                    local function updateSelIcon()
                        local entry = FarmItemMap[lbl.Text]
                        local img = inner:FindFirstChild("SW_SelIcon")
                        if not entry or not entry.icon then
                            if img then
                                img:Destroy()
                                if iconShifted then
                                    lbl.Size = UDim2.new(lbl.Size.X.Scale, lbl.Size.X.Offset + 38, lbl.Size.Y.Scale, lbl.Size.Y.Offset)
                                    lbl.Position = UDim2.new(
                                        lbl.Position.X.Scale,
                                        lbl.Position.X.Offset - 38,
                                        lbl.Position.Y.Scale,
                                        lbl.Position.Y.Offset
                                    )
                                    iconShifted = false
                                end
                            end
                            return
                        end
                        if not img then
                            img = Instance.new("ImageLabel")
                            img.Name = "SW_SelIcon"
                            img.BackgroundTransparency = 1
                            img.Size = UDim2.fromOffset(30, 30)
                            img.Position = UDim2.new(0, 4, 0.5, -15)
                            img.LayoutOrder = -1
                            img.ZIndex = lbl.ZIndex + 1
                            img.Parent = inner
                            if not iconShifted then
                                iconShifted = true
                                lbl.Size = UDim2.new(lbl.Size.X.Scale, lbl.Size.X.Offset - 38, lbl.Size.Y.Scale, lbl.Size.Y.Offset)
                                lbl.Position =
                                    UDim2.new(lbl.Position.X.Scale, lbl.Position.X.Offset + 38, lbl.Position.Y.Scale, lbl.Position.Y.Offset)
                            end
                        end
                        img.Image = entry.icon
                    end

                    lbl:GetPropertyChangedSignal("Text"):Connect(updateSelIcon)
                    updateSelIcon()
                end)
            end)
        end
        injectIconsIntoDropdown(true)
    end

    local function reloadItems()
        task.spawn(function()
            UserSelectedItem = false
            refreshSafePreview()
            local titles, itemMap
            for _ = 1, 5 do
                titles, itemMap = loadBackpackItems()
                if titles[1] ~= "(ไม่พบไอเทม)" then break end
                task.wait(1.5)
            end
            if titles and titles[1] ~= "(ไม่พบไอเทม)" then
                FarmItemTitles = titles
                FarmItemMap = itemMap
                createItemDropdown(titles, itemMap)
            end
        end)
    end

    task.wait()
    createItemDropdown(FarmItemTitles, FarmItemMap)
    reloadItems()

    task.wait()
    FarmSection:Input({
        Title = "Deposit Amount",
        Desc = "พิมตัวเลข เช่น 30 / 60 / 500",
        Placeholder = tostring(CustomMax),
        Numeric = true,
        Finished = true,
        Callback = function(v)
            local n = tonumber(v)
            if n and n > 0 then
                CustomMax = n
                CustomMaxSet = true
            end
        end,
    })
    FarmSection:Button({
        Title = "Reload Items",
        Desc = "กดถ้า Dropdown ยังแสดง placeholder",
        Icon = "refresh-cw",
        Callback = reloadItems,
    })
    FarmSection:Paragraph({ Title = "Current Amount", Desc = "__AMOUNT_INIT__" })
    task.spawn(function()
        task.wait(0.5)
        AmountDescLabel = findLabelByText("__AMOUNT_INIT__")
        if AmountDescLabel then AmountDescLabel.Text = "-- รอเลือกไอเทม..." end
    end)

    task.spawn(function()
        pcall(function()
            local safeFolder = LP:WaitForChild("Safe", 5)
            if not safeFolder then return end
            local function hookVal(v)
                v:GetPropertyChangedSignal("Value"):Connect(function()
                    if SelectedItem and SelectedItem.value ~= "" and UserSelectedItem and v.Name == SelectedItem.value then
                        refreshSafePreview()
                    end
                end)
            end
            for _, v in ipairs(safeFolder:GetChildren()) do
                hookVal(v)
            end
            safeFolder.ChildAdded:Connect(function(v)
                task.wait(0.1)
                hookVal(v)
            end)
        end)
    end)

    local slotLabelCache = setmetatable({}, { __mode = "k" })
    local function getSlotCount(slot)
        local lbl = slotLabelCache[slot]
        if not lbl or not lbl.Parent then
            lbl = slot:FindFirstChild("Amout", true)
            if not lbl then
                for _, c in ipairs(slot:GetDescendants()) do
                    if c:IsA("TextLabel") or c:IsA("TextButton") then
                        lbl = c
                        break
                    end
                end
            end
            slotLabelCache[slot] = lbl
        end
        if not lbl then return 0 end
        local ok, txt = pcall(SW.getText, lbl)
        txt = ok and txt or ""
        return tonumber(txt:match("%d+")) or 0
    end

    task.spawn(function()
        local cachedScrolling
        local function _amtTick()
            if not cachedScrolling or not cachedScrolling.Parent then
                cachedScrolling = getScrolling()
                if not cachedScrolling then return end
            end
            if SelectedItem and SelectedItem.value ~= "" and UserSelectedItem then
                local slot = cachedScrolling:FindFirstChild(SelectedItem.value)
                if slot then
                    setAmount(SelectedItem.value .. "  =  " .. getSlotCount(slot) .. " / " .. CustomMax)
                else
                    setAmount("-- " .. SelectedItem.value .. " : ไม่พบใน Backpack")
                end
            else
                setAmount("-- ยังไม่ได้เลือกไอเทม")
            end
        end
        while true do
            pcall(_amtTick)
            task.wait(3)
        end
    end)

    task.wait()
    AutoFarmToggle = FarmSection:Toggle({
        Title = "Auto Deposit",
        Desc = "เปิด = เริ่มเก็บใส่ตู้  |  ปิด = หยุด",
        Value = false,
        Callback = function(state)
            if state then
                local noItem = not UserSelectedItem
                local noAmt = not CustomMaxSet
                if noItem or noAmt then
                    FarmRunning = false
                    task.spawn(function()
                        pcall(function() AutoFarmToggle:Set(false) end)
                    end)
                    local msg
                    if noItem and noAmt then
                        msg =
                            "กรุณาเลือกของ และกรอกจำนวนก่อนเปิด Auto Deposit"
                    elseif noItem then
                        msg = "กรุณาเลือกของที่จะเก็บก่อนเปิด Auto Deposit"
                    else
                        msg =
                            "กรุณากรอกจำนวนของที่จะเก็บก่อนเปิด Auto Deposit"
                    end
                    SW.denySound()
                    WindUI:Notify({ Title = "เปิดไม่ได้", Icon = "lock", Content = msg, Duration = 4 })
                    return
                end
            end
            FarmRunning = state
            if not state then return end
            task.spawn(function()
                if not DepositRemote then
                    task.wait(0.5)
                    for _ = 1, 3 do
                        DepositRemote =
                            resolveRemotePath(game:GetService("ReplicatedStorage"), { "Game_Modules", "RemoteEventSafe", "DepositItem" }, 5)
                        if DepositRemote then break end
                        task.wait(1.5)
                    end
                end
                if not DepositRemote then
                    FarmRunning = false
                    WindUI:Notify({
                        Title = "Auto Deposit หยุด",
                        Icon = "x-circle",
                        Content = "ไม่พบ DepositRemote กรุณา Rejoin",
                        Duration = 5,
                    })
                    return
                end
                WindUI:Notify({
                    Title = "Auto Deposit เปิด",
                    Icon = "check-circle",
                    Content = "กำลังเก็บใส่ตู้: " .. SelectedItem.value,
                    Duration = 3,
                })
                local farmScrolling
                local function depositTick()
                    if not farmScrolling or not farmScrolling.Parent then
                        farmScrolling = getScrolling()
                        if not farmScrolling then return end
                    end
                    local slot = farmScrolling:FindFirstChild(SelectedItem.value)
                    if not slot then return end
                    local cur = getSlotCount(slot)
                    if cur >= CustomMax and SelectedItem.value ~= "" then DepositRemote:FireServer(SelectedItem.value, cur) end
                end
                while FarmRunning do
                    pcall(depositTick)
                    task.wait(1)
                end
            end)
        end,
    })

    -- ── SECTION: AUTO WATER ──
    task.wait()
    local WaterSection = FarmTab:Section({ Title = "Candy Tree - Auto Water", Icon = "droplet", Opened = true })
    local autoWaterEnabled, selectedWaterFolders, waterPickDropdown, waterFolderMap = false, {}, nil, {}

    local function buildFolderLabel(folder)
        local uid = tonumber(folder.Name:match("PlantedTrees_(%d+)"))
        if not uid then return folder.Name end
        local name = (Players:GetPlayerByUserId(uid) or {}).Name or tostring(uid)
        return folder.Name == folderName and ("ของฉัน (" .. name .. ")") or name
    end

    function buildWaterPickDropdown()
        local prevLabels = {}
        for _, f in ipairs(selectedWaterFolders) do
            prevLabels[buildFolderLabel(f)] = true
        end

        waterFolderMap = {}
        local titles = {}
        if allTrees then
            for _, folder in pairs(allTrees:GetChildren()) do
                local label = buildFolderLabel(folder)
                t_insert(titles, label)
                waterFolderMap[label] = folder
            end
        end
        if #titles == 0 then titles = { "(ไม่พบผู้เล่น)" } end

        local restoredTitles, restoredFolders = {}, {}
        for _, t in ipairs(titles) do
            if prevLabels[t] then
                t_insert(restoredTitles, t)
                t_insert(restoredFolders, waterFolderMap[t])
            end
        end
        if #restoredFolders > 0 then
            selectedWaterFolders = restoredFolders
        else
            selectedWaterFolders = waterFolderMap[titles[1]] and { waterFolderMap[titles[1]] } or {}
            restoredTitles = { titles[1] }
        end

        if waterPickDropdown then
            local ok = pcall(function() waterPickDropdown:Refresh(titles) end)
            if not ok then
                pcall(function() waterPickDropdown:Destroy() end)
                waterPickDropdown = nil
            end
            if waterPickDropdown then pcall(function() waterPickDropdown:Set(restoredTitles) end) end
        end
        if not waterPickDropdown then
            waterPickDropdown = WaterSection:Dropdown({
                Title = "Water Targets",
                Desc = "เลือกผู้เล่นได้หลายคน",
                Icon = "users",
                Values = titles,
                Value = restoredTitles,
                Multi = true,
                SearchBarEnabled = true,
                Callback = function(options)
                    selectedWaterFolders = {}
                    local list = type(options) == "table" and options or { options }
                    for _, opt in ipairs(list) do
                        local f = waterFolderMap[optionKey(opt)]
                        if f then t_insert(selectedWaterFolders, f) end
                    end
                end,
            })
        end
    end
    buildWaterPickDropdown()

    local WATER_REACH_DIST = 15

    local function walkToTarget(model)
        local part = SW.treePart(model)
        if not part then return false, "ไม่พบตำแหน่งของต้นไม้ (BasePart)" end
        local hum2 = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if not hum2 then return false, "ไม่พบ Humanoid ของตัวละคร (อาจกำลัง Respawn)" end
        if hum2.Health <= 0 then return false, "ตัวละครตายอยู่ รอ Respawn ก่อน" end
        local moveOk = pcall(hum2.MoveTo, hum2, part.Position)
        if not moveOk then
            return false,
                "สั่งเดินไม่สำเร็จ (ตัวละครถูกทำลายระหว่างเดิน)"
        end
        local arrived = false
        local conn = hum2.MoveToFinished:Connect(function(reached) arrived = reached end)
        local t = os.clock()
        repeat
            task.wait(0.1)
        until arrived or (os.clock() - t) > 20 or hum2.Health <= 0 or not hum2.Parent
        conn:Disconnect()
        if hum2.Health <= 0 or not hum2.Parent then
            return false, "ตัวละครตายหรือถูกทำลายระหว่างเดิน"
        end
        if not arrived then
            return false,
                "เดินไม่ถึงภายในเวลาที่กำหนด (อาจติดสิ่งกีดขวาง/ทางตัน)"
        end
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            if (hrp.Position - part.Position).Magnitude > WATER_REACH_DIST then
                return false,
                    "เดินถึงจุดแล้วแต่ยังอยู่นอกระยะรดน้ำ ("
                        .. WATER_REACH_DIST
                        .. " studs)"
            end
            return true
        end
        return arrived, (arrived and nil or "ไม่พบ HumanoidRootPart")
    end

    local _walkFailNotifyAt = setmetatable({}, { __mode = "k" })
    local WALK_FAIL_NOTIFY_COOLDOWN = 10
    local function notifyWalkFail(tree, reason)
        local now = os.clock()
        local last = _walkFailNotifyAt[tree]
        if last and (now - last) < WALK_FAIL_NOTIFY_COOLDOWN then return end
        _walkFailNotifyAt[tree] = now
        WindUI:Notify({
            Title = "เดินไปรดน้ำไม่ได้",
            Icon = "footprints",
            Content = (tree and tree.Name or "?") .. ": " .. (reason or "ไม่ทราบสาเหตุ"),
            Duration = 4,
        })
    end

    local _controls
    task.spawn(function()
        pcall(function() _controls = require(LP.PlayerScripts:WaitForChild("PlayerModule", 5)):GetControls() end)
    end)

    local function setWaterInputLock(state)
        if not _controls then return end
        if state then
            _controls:Disable()
        else
            _controls:Enable()
        end
    end

    local function checkAndWater(tree)
        if not tree or not tree.Parent then return end
        local stats = tree:FindFirstChild("Stats")
        if not stats then return end
        local wv = stats:FindFirstChild("Water")
        if not wv or not giveWaterRemote then return end
        if m_floor(wv.Value) >= 100 then return end
        local treePart = SW.treePart(tree)
        local walked, walkFailReason = walkToTarget(tree)
        if not walked then
            notifyWalkFail(tree, walkFailReason)
            return
        end
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if treePart and hrp and (hrp.Position - treePart.Position).Magnitude > WATER_REACH_DIST then
            notifyWalkFail(tree, "อยู่นอกระยะรดน้ำ (" .. WATER_REACH_DIST .. " studs)")
            return
        end
        local tries = 0
        while autoWaterEnabled and tree.Parent and wv.Parent and m_floor(wv.Value) < 100 do
            giveWaterRemote:FireServer(tree)
            task.wait(0.8)
            tries = tries + 1
            if tries > 60 then break end
        end
    end

    local waterRunId = 0
    local AutoWaterToggle

    AutoWaterToggle = WaterSection:Toggle({
        Title = "Auto Water",
        Desc = "รดน้ำอัตโนมัติเมื่อน้ำต่ำกว่า 50% (เรียงใกล้→ไกล)",
        Value = false,
        Callback = function(state)
            waterRunId = waterRunId + 1
            local myRunId = waterRunId
            autoWaterEnabled = state
            setWaterInputLock(state)
            if not state then return end
            if #selectedWaterFolders == 0 then
                autoWaterEnabled = false
                setWaterInputLock(false)
                task.spawn(function()
                    pcall(function() AutoWaterToggle:Set(false) end)
                end)
                SW.denySound()
                WindUI:Notify({
                    Title = "เปิดไม่ได้",
                    Icon = "lock",
                    Content = "กรุณาเลือกผู้เล่นที่จะรดน้ำก่อนเปิด Auto Water",
                    Duration = 4,
                })
                return
            end
            task.spawn(function()
                local function isCurrent() return autoWaterEnabled and waterRunId == myRunId end
                local ok, err = pcall(function()
                    while isCurrent() do
                        local orderedFolders, ownFolder = {}, nil
                        for _, folder in ipairs(selectedWaterFolders) do
                            if folder and folder.Parent then
                                if folder.Name == folderName then
                                    ownFolder = folder
                                else
                                    t_insert(orderedFolders, folder)
                                end
                            end
                        end
                        if ownFolder then t_insert(orderedFolders, 1, ownFolder) end

                        for _, folder in ipairs(orderedFolders) do
                            if not isCurrent() then break end

                            local treeList = {}
                            pcall(function()
                                for _, tree in pairs(folder:GetChildren()) do
                                    local stats = tree:FindFirstChild("Stats")
                                    local wv = stats and stats:FindFirstChild("Water")
                                    if wv and wv.Value <= 49 then t_insert(treeList, tree) end
                                end
                            end)

                            local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                            if hrp and #treeList > 1 then
                                local posCache = {}
                                for _, tree in ipairs(treeList) do
                                    local p = SW.treePart(tree)
                                    posCache[tree] = p and p.Position
                                end
                                local myPos = hrp.Position
                                t_sort(treeList, function(a, b)
                                    local pa, pb = posCache[a], posCache[b]
                                    return (pa and (myPos - pa).Magnitude or m_huge) < (pb and (myPos - pb).Magnitude or m_huge)
                                end)
                            end

                            for _, tree in ipairs(treeList) do
                                if not isCurrent() then break end
                                pcall(checkAndWater, tree)
                            end
                        end

                        task.wait(5)
                    end
                end)
                if not ok then
                    pcall(
                        function()
                            WindUI:Notify({
                                Title = "Auto Water หยุดทำงาน",
                                Icon = "alert-triangle",
                                Content = "เกิดข้อผิดพลาด: " .. tostring(err),
                                Duration = 5,
                            })
                        end
                    )
                end
                if waterRunId == myRunId then
                    autoWaterEnabled = false
                    setWaterInputLock(false)
                    if not ok then pcall(function() AutoWaterToggle:Set(false) end) end
                end
            end)
        end,
    })

    task.wait()
    -- ── Floating Candy Status Panel (toggleable, draggable, separate from WindUI tab) ──
    -- v2: ไอคอน lucide ของ WindUI แทนอีโมจิ | แถวใช้ซ้ำ ไม่สร้าง/ทำลายทุกรอบ | เขียน property เฉพาะที่เปลี่ยนจริง (ลื่น ไม่แลค)
    local CandyMain, refreshTreeStatus, CandyPanelToggle
    do
        local C = {
            W = 344,
            MIN_H = 150,
            MAX_H = 330,
            LIST_Y = 84,
            BAR_W = 0.19,
            ROW_T = 0.55,
            Stats = {
                { x = 0.36, label = "น้ำ", color = SW.Water, icon = { "droplet", "droplets" } },
                { x = 0.58, label = "ปุ๋ย", color = SW.Food, icon = { "candy", "cookie", "apple" } },
                { x = 0.80, label = "โต", color = SW.Growth, icon = { "trending-up", "sprout" } },
            },
        }

        -- ไอคอน lucide จาก WindUI: ลองทีละชื่อ ถ้าไม่มีเลยจะคืน nil (ช่องไอคอนว่างเฉยๆ ไม่ error)
        function C.icon(parent, names, size, color, props)
            local Creator = type(WindUI) == "table" and WindUI.Creator
            if type(Creator) ~= "table" or type(Creator.Icon) ~= "function" then return nil end
            if type(names) ~= "table" then names = { names } end
            for _, n in ipairs(names) do
                local ok, d = pcall(Creator.Icon, n)
                if ok and type(d) == "table" and d[1] and d[2] then
                    local img = SW.new("ImageLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.fromOffset(size, size),
                        Image = d[1],
                        ImageRectSize = d[2].ImageRectSize,
                        ImageRectOffset = d[2].ImageRectPosition,
                        ImageColor3 = color,
                        ScaleType = Enum.ScaleType.Fit,
                    }, parent)
                    if props then
                        for k, v in pairs(props) do
                            img[k] = v
                        end
                    end
                    return img
                end
            end
            return nil
        end

        local CandyGui = Instance.new("ScreenGui")
        CandyGui.Name = "CandyStatusUI"
        CandyGui.ResetOnSpawn = false
        CandyGui.IgnoreGuiInset = true
        CandyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        CandyGui.DisplayOrder = 50
        pcall(function() CandyGui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
        if not CandyGui.Parent then CandyGui.Parent = LP:WaitForChild("PlayerGui") end

        CandyMain = SW.new("Frame", {
            Name = "MainFrame",
            Size = UDim2.fromOffset(C.W, 170),
            Position = UDim2.new(0, 20, 0, 120),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 0.02,
            BorderSizePixel = 0,
            Active = true,
            Visible = false,
        }, CandyGui)
        SW.round(CandyMain, 18)
        SW.new("UIGradient", { Color = ColorSequence.new(SW.BgTop, SW.Bg), Rotation = 115 }, CandyMain)
        SW.edge(CandyMain, 1.4, 0.25, 90)

        -- ── Header (จับตรงนี้เพื่อลากแผง) ──
        local header = SW.new("Frame", {
            Name = "Header",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 56),
            Active = true,
        }, CandyMain)

        local logo = SW.new("Frame", {
            Position = UDim2.fromOffset(14, 11),
            Size = UDim2.fromOffset(34, 34),
            BackgroundColor3 = SpectreAccent,
            BackgroundTransparency = 0.82,
            BorderSizePixel = 0,
        }, header)
        SW.round(logo, 11)
        SW.stroke(logo, SpectreAccent, 1, 0.65)
        C.icon(
            logo,
            { "trees", "tree-pine", "sprout", "leaf" },
            20,
            Color3.fromRGB(150, 190, 255),
            { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) }
        )

        SW.new("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(58, 9),
            Size = UDim2.new(1, -130, 0, 20),
            Font = Enum.Font.GothamBold,
            TextSize = 15,
            TextColor3 = SW.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = "Candy Tree Status",
        }, header)
        C.subLabel = SW.new("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(58, 30),
            Size = UDim2.new(1, -130, 0, 14),
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = SW.Sub,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = "กำลังโหลด...",
        }, header)

        -- ปุ่มกลมในหัวแผง (ไอคอน lucide) พร้อม hover
        C.BTN = SW.UIS.TouchEnabled and 40 or 28 -- bigger tap targets on touchscreens
        function C.btn(xOff, iconNames, hoverColor)
            local b = SW.new("TextButton", {
                Size = UDim2.fromOffset(C.BTN, C.BTN),
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, xOff, 0.5, 0),
                BackgroundColor3 = SW.Row,
                Text = "",
                AutoButtonColor = false,
            }, header)
            SW.round(b, C.BTN // 2)
            local ic = C.icon(b, iconNames, 14, SW.Text, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
            if SW.UIS.MouseEnabled then -- hover tweens are pointless (and fire spuriously) on touch-only devices
                b.MouseEnter:Connect(function() SW.tween(b, 0.12, { BackgroundColor3 = hoverColor }) end)
                b.MouseLeave:Connect(function() SW.tween(b, 0.12, { BackgroundColor3 = SW.Row }) end)
            end
            return b, ic
        end
        local CandyCloseBtn = C.btn(-12, { "x" }, SW.Danger)
        local CandyRefreshBtn, refreshIcon = C.btn(-(12 + C.BTN + 6), { "refresh-cw", "rotate-cw" }, SpectreAccent)

        SW.drag(header, CandyMain)

        -- เส้นคั่นจางหายปลายสองข้าง
        local sep = SW.new("Frame", {
            BackgroundColor3 = SpectreAccent,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 12, 0, 56),
            Size = UDim2.new(1, -24, 0, 1),
        }, CandyMain)
        SW.new("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.5, 0.65),
                NumberSequenceKeypoint.new(1, 1),
            }),
        }, sep)

        -- ── หัวคอลัมน์: ไอคอน + ชื่อ สีตรงกับแท่งด้านล่าง ──
        local legend = SW.new("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(10, 63),
            Size = UDim2.new(1, -24, 0, 18),
        }, CandyMain)
        for _, s in ipairs(C.Stats) do
            local cell = SW.new("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.new(s.x, 0, 0, 0),
                Size = UDim2.new(C.BAR_W, 0, 1, 0),
            }, legend)
            SW.new("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }, cell)
            C.icon(cell, s.icon, 13, s.color, { LayoutOrder = 1 })
            SW.new("TextLabel", {
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.X,
                Size = UDim2.fromOffset(0, 16),
                LayoutOrder = 2,
                Font = Enum.Font.GothamMedium,
                TextSize = 11,
                TextColor3 = s.color,
                Text = s.label,
            }, cell)
        end

        local CandyList = SW.new("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(10, C.LIST_Y),
            Size = UDim2.new(1, -16, 1, -(C.LIST_Y + 10)),
            ScrollBarThickness = SW.UIS.TouchEnabled and 6 or 3,
            ScrollBarImageColor3 = SpectreAccent,
            ScrollBarImageTransparency = 0.3,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
        }, CandyMain)
        local layout = SW.new("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 5),
        }, CandyList)

        -- สถานะว่าง: ไอคอน + ข้อความ (โผล่ตอนโหลด/ไม่พบต้นไม้)
        local empty = SW.new("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -8, 0, 78),
            LayoutOrder = 0,
        }, CandyList)
        SW.new("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, empty)
        C.icon(empty, { "sprout", "leaf", "trees" }, 26, SW.Sub, { LayoutOrder = 1, ImageTransparency = 0.35 })
        C.emptyText = SW.new("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 16),
            LayoutOrder = 2,
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            TextColor3 = SW.Sub,
            Text = "กำลังโหลดข้อมูล...",
        }, empty)

        -- ให้แผงสูงพอดีกับจำนวนแถว (มีเพดาน แล้วเลื่อนเอา)
        local lastFitH
        local function fit()
            local h = m_clamp(C.LIST_Y + layout.AbsoluteContentSize.Y + 12, C.MIN_H, C.MAX_H)
            if h == lastFitH then return end -- ความสูงเท่าเดิมไม่ต้องสร้าง tween ใหม่
            lastFitH = h
            SW.tween(CandyMain, 0.2, { Size = UDim2.fromOffset(C.W, h) })
        end
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(fit)

        -- เก็บแถวไว้ใช้ซ้ำ (ไม่ทำลาย/สร้างใหม่ทุก 4 วิ) → ไม่กะพริบ ตำแหน่งเลื่อนไม่เด้งกลับ แท่งไหลอย่างนุ่ม
        local items = {} -- Instance -> {row, name, bars, ...}

        local structDirty = false -- only re-fit the panel height when rows were created/destroyed
        local function ensureHeader(inst, text, count, order, isMine)
            local e = items[inst]
            if not e then
                structDirty = true
                local row = SW.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -8, 0, 26) }, CandyList)
                local ic = C.icon(
                    row,
                    isMine and { "user", "circle-user" } or { "users", "user" },
                    14,
                    SW.Sub,
                    { Position = UDim2.new(0, 4, 0.5, -7) }
                )
                local lbl = SW.new("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(24, 0),
                    Size = UDim2.new(1, -84, 1, 0),
                    Font = Enum.Font.GothamBold,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                }, row)
                local cnt = SW.new("TextLabel", {
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, -4, 0, 0),
                    Size = UDim2.new(0, 56, 1, 0),
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextColor3 = SW.Sub,
                    TextXAlignment = Enum.TextXAlignment.Right,
                }, row)
                e = { row = row, name = lbl, cnt = cnt, icon = ic }
                items[inst] = e
            end
            -- เขียน property เฉพาะที่เปลี่ยนจริง (GUI ไม่ต้องประมวลผลใหม่ทั้งที่ค่าเท่าเดิม)
            if e.order ~= order then
                e.order = order
                e.row.LayoutOrder = order
            end
            if e.text ~= text then
                e.text = text
                e.name.Text = text
            end
            if e.count ~= count then
                e.count = count
                e.cnt.Text = count .. " ต้น"
            end
            if e.mine ~= isMine then
                e.mine = isMine
                e.name.TextColor3 = isMine and SpectreAccent or SW.Text
                if e.icon then e.icon.ImageColor3 = isMine and SpectreAccent or SW.Sub end
            end
        end

        local function ensureRow(inst, name, w, f, g, order)
            local e = items[inst]
            if not e then
                structDirty = true
                local row = SW.new("Frame", {
                    BackgroundColor3 = SW.Row,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, -8, 0, 32),
                }, CandyList)
                SW.round(row, 10)
                SW.tween(row, 0.25, { BackgroundTransparency = C.ROW_T }) -- แถวใหม่ค่อยๆ เฟดเข้า
                C.icon(row, { "sprout", "leaf" }, 14, SW.Growth, { Position = UDim2.new(0, 10, 0.5, -7) })
                local lbl = SW.new("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(30, 0),
                    Size = UDim2.new(0.34, -30, 1, 0),
                    Font = Enum.Font.GothamMedium,
                    TextSize = 12,
                    TextColor3 = SW.Text,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                }, row)
                local bars = {}
                for i, s in ipairs(C.Stats) do
                    local track = SW.new("Frame", {
                        BackgroundColor3 = SW.Track,
                        BorderSizePixel = 0,
                        ClipsDescendants = true,
                        Position = UDim2.new(s.x, 0, 0.5, -8),
                        Size = UDim2.new(C.BAR_W, 0, 0, 16),
                    }, row)
                    SW.round(track, 8)
                    local fill = SW.new("Frame", {
                        BackgroundColor3 = s.color,
                        BackgroundTransparency = 0.15,
                        BorderSizePixel = 0,
                        Size = UDim2.new(0, 0, 1, 0),
                    }, track)
                    SW.round(fill, 8)
                    SW.new(
                        "UIGradient",
                        { -- เงาไล่บางๆ ให้แท่งดูมีมิติ (ใช้ได้กับทุกสี รวมถึงสีแดงตอนน้ำต่ำ)
                            Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(205, 205, 205)),
                            Rotation = 90,
                        },
                        fill
                    )
                    local txt = SW.new("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        ZIndex = 2,
                        Font = Enum.Font.GothamBold,
                        TextSize = 10,
                        TextColor3 = Color3.new(1, 1, 1),
                        TextStrokeTransparency = 0.6,
                        Text = "0%",
                    }, track)
                    bars[i] = { fill = fill, txt = txt, color = s.color }
                end
                e = { row = row, name = lbl, bars = bars }
                items[inst] = e
            end
            if e.order ~= order then
                e.order = order
                e.row.LayoutOrder = order
            end
            if e.text ~= name then
                e.text = name
                e.name.Text = name
            end
            for i, b in ipairs(e.bars) do
                local raw = (i == 1 and w) or (i == 2 and f) or g
                local v = m_clamp(tonumber(raw) or 0, 0, 100)
                if b.v ~= v then
                    b.v = v
                    b.txt.Text = m_floor(v) .. "%"
                    -- น้ำต่ำกว่า 20% → แท่งเป็นสีแดงให้เห็นทันที
                    b.fill.BackgroundColor3 = (i == 1 and v < 20) and SW.Danger or b.color
                    SW.tween(b.fill, 0.35, { Size = UDim2.new(v / 100, 0, 1, 0) })
                end
            end
        end

        -- PERF: scratch arrays + uid cache reused across refreshes (was a fresh table per tree every 4s)
        C.t, C.w, C.f, C.g = {}, {}, {}, {}
        C.uid = setmetatable({}, { __mode = "k" })
        refreshTreeStatus = function()
            pcall(function()
                if not allTrees then allTrees = workspace:FindFirstChild("AllPlantedTrees") end
                if not allTrees then
                    if C.emptyText.Text ~= "กำลังโหลดข้อมูล..." then
                        C.emptyText.Text = "กำลังโหลดข้อมูล..."
                    end
                    empty.Visible = true
                    return
                end
                local seen, order, total = {}, 0, 0
                for _, folder in pairs(allTrees:GetChildren()) do
                    local uid = C.uid[folder]
                    if uid == nil then
                        uid = tonumber(folder.Name:match("PlantedTrees_(%d+)")) or false
                        C.uid[folder] = uid
                    end
                    local dname = uid and ((Players:GetPlayerByUserId(uid) or {}).Name or tostring(uid)) or folder.Name
                    local isMine = folder.Name == folderName
                    local header = isMine and ("ของฉัน (" .. dname .. ")") or dname
                    local tT, tW, tF, tG, n = C.t, C.w, C.f, C.g, 0
                    for _, tree in pairs(folder:GetChildren()) do
                        local stats = tree:FindFirstChild("Stats")
                        if stats then
                            local w = stats:FindFirstChild("Water")
                            local f = stats:FindFirstChild("Food")
                            local g = stats:FindFirstChild("Growth")
                            n = n + 1
                            tT[n] = tree
                            tW[n] = w and w.Value or 0
                            tF[n] = f and f.Value or 0
                            tG[n] = g and g.Value or 0
                        end
                    end
                    if n > 0 then
                        total = total + n
                        order = order + 1
                        seen[folder] = true
                        ensureHeader(folder, header, n, order, isMine)
                        for i = 1, n do
                            local tree = tT[i]
                            tT[i] = nil -- don't keep trees alive through the scratch array
                            order = order + 1
                            seen[tree] = true
                            ensureRow(tree, tree.Name, tW[i], tF[i], tG[i], order)
                        end
                    end
                end
                for inst, e in pairs(items) do
                    if not seen[inst] then
                        e.row:Destroy()
                        items[inst] = nil
                        structDirty = true
                    end
                end
                empty.Visible = (order == 0)
                if order == 0 and C.emptyText.Text ~= "ไม่พบต้นแคนดี้" then
                    C.emptyText.Text = "ไม่พบต้นแคนดี้"
                end
                local sub = total > 0 and (total .. " ต้น  •  อัปเดตทุก 4 วินาที")
                    or "ไม่มีข้อมูล"
                if C.subLabel.Text ~= sub then C.subLabel.Text = sub end
                if structDirty then
                    structDirty = false
                    task.delay(0.05, fit)
                end
            end)
        end

        CandyCloseBtn.MouseButton1Click:Connect(function()
            CandyMain.Visible = false
            pcall(function() CandyPanelToggle:Set(false) end)
        end)

        -- ปุ่มรีเฟรชในแผง: ไอคอนหมุน 1 รอบ + โหลดข้อมูลใหม่ทันที
        local spinning = false
        CandyRefreshBtn.MouseButton1Click:Connect(function()
            if refreshIcon and not spinning then
                spinning = true
                refreshIcon.Rotation = 0
                SW.tween(refreshIcon, 0.5, { Rotation = 360 })
                task.delay(0.55, function() spinning = false end)
            end
            task.spawn(function() pcall(refreshTreeStatus) end)
        end)

        task.spawn(function()
            while true do
                task.wait(4)
                if CandyMain.Visible and not SW.isDragging then pcall(refreshTreeStatus) end
            end
        end)
    end

    task.wait()
    CandyPanelToggle = WaterSection:Toggle({
        Title = "Show Tree Status UI",
        Desc = "เปิด/ปิดแผงลอยแสดงสถานะต้นไม้ (ลากย้ายตำแหน่งได้)",
        Value = false,
        Callback = function(state)
            CandyMain.Visible = state
            if state then
                SW.pop(CandyMain)
                pcall(refreshTreeStatus)
            end
        end,
    })

    WaterSection:Button({
        Title = "Reload Candy",
        Desc = "โหลดข้อมูลต้นแคนดี้ใหม่ + รีเฟรชรายชื่อผู้เล่น",
        Icon = "refresh-cw",
        Callback = function()
            task.spawn(function()
                allTrees = workspace:FindFirstChild("AllPlantedTrees")
                parentFolder = allTrees and allTrees:FindFirstChild(folderName) or nil
                task.wait(0.3)
                buildWaterPickDropdown()
                refreshTreeStatus()
                WindUI:Notify({
                    Title = "รีเฟรชแล้ว",
                    Icon = "refresh-cw",
                    Content = "อัพเดทรายชื่อผู้เล่นสำเร็จ",
                    Duration = 3,
                })
            end)
        end,
    })
end -- จบเนื้อหาแท็บ Menu (Farm)

-- FIX: ล็อคแท็บ ESP ทั้งแท็บสำหรับ UserId ที่ไม่ได้อยู่ใน ESP_ALLOWED_USERIDS
-- (Locked=true ทำให้แท็บกดไม่ได้/เทาไว้จาก WindUI เอง) และ "ตัวมันเอง" ก็เช็คซ้ำที่ esp:FireScan/
-- esp:ScanWorkspace/RenderStepped ด้านบนอีกชั้น เผื่อมีทางกดเข้ามาได้บ้างช่องทางใดช่องทางหนึ่ง
task.wait(0.15) -- โหลดทีละแท็บ ไม่กระชากมาทีเดียว
local function LoadESPTab() -- เนื้อหาแท็บ ESP
    local function notifyESPMaintenance()
        pcall(function()
            SW.denySound()
            WindUI:Notify({
                Title = "ปิดปรับปรุง",
                Icon = "wrench",
                Content = "ระบบ ESP กำลังปิดปรับปรุงชั่วคราว กรุณารอการอัปเดตครั้งถัดไป",
                Duration = 4,
            })
        end)
    end

    if not IsESPAuthorized then
        -- แสดง notify เมื่อกดที่ตัวแท็บ ESP เอง (ไม่ใช่แค่ปุ่ม/สวิตช์ข้างใน) เพราะแท็บถูกล็อคไว้กดเข้าไม่ได้อยู่แล้ว
        task.spawn(function()
            task.wait(1)
            local tabBtn
            pcall(function()
                local lbl = findLabelByText("ESP")
                if lbl then
                    local p = lbl
                    for i = 1, 6 do
                        if not p then break end
                        if p:IsA("GuiButton") then
                            tabBtn = p
                            break
                        end
                        p = p.Parent
                    end
                    if not tabBtn then tabBtn = lbl.Parent end
                end
            end)
            if tabBtn then
                pcall(function()
                    if tabBtn:IsA("GuiButton") then
                        tabBtn.MouseButton1Click:Connect(notifyESPMaintenance)
                    else
                        tabBtn.InputBegan:Connect(function(input)
                            if
                                input.UserInputType == Enum.UserInputType.MouseButton1
                                or input.UserInputType == Enum.UserInputType.Touch
                            then
                                notifyESPMaintenance()
                            end
                        end)
                    end
                end)
            end
        end)
        -- แสดงแค่หน้าตาแท็บ ไม่มีอะไรทำงานได้จริง ทุกปุ่ม/สวิตช์แค่เด้งแจ้งเตือนแล้วดีดกลับ
        local LockedSection = ESPTab:Section({ Title = "ESP Settings", Opened = true })
        local lockedToggle
        lockedToggle = LockedSection:Toggle({
            Title = "Enable ESP",
            Desc = "เปิด/ปิด ESP ทั้งหมด",
            Icon = "lock",
            Value = false,
            Callback = function(s)
                notifyESPMaintenance()
                if s then pcall(function() lockedToggle:SetValue(false) end) end
            end,
        })
        LockedSection:Button({
            Title = "Under Maintenance",
            Desc = "ESP ไม่พร้อมใช้งานในขณะนี้",
            Icon = "shield-off",
            Callback = function() notifyESPMaintenance() end,
        })
    else
        local ESPMain = ESPTab:Section({ Title = "ESP Settings", Opened = true })

        ESPMain:Toggle({
            Title = "Enable ESP",
            Desc = "เปิด/ปิด ESP ทั้งหมด",
            Icon = "eye",
            Value = CFG.Enabled,
            Callback = function(s)
                CFG.Enabled = s
                if not s then
                    pcall(function() esp:Clear() end)
                    pcall(function() esp:RemoveAll() end)
                elseif CFG.NPCSESP then
                    task.spawn(function() esp:ScanWorkspace() end)
                end
                esp:FireScan()
                DebouncedSaveCFG()
            end,
        })

        local espToggles = {
            {
                "NPC ESP",
                "แสดง ESP ของ NPC ในแผนที่",
                "NPCSESP",
                function(s)
                    if s then task.spawn(function() esp:ScanWorkspace() end) end
                end,
            },
            { "Hide Dead Players", "เปิด = ไม่แสดง ESP เมื่อ HP = 0", "HideDeadESP", nil },
            { "Show Health Bar", "แสดงแถบ HP", "ShowHP", nil },
            { "Show HP Text", "แสดง % HP ใต้กล่อง เช่น 75%", "ShowHPText", nil },
            { "Show Name", "แสดงชื่อเหนือกรอบ", "ShowName", nil },
            { "Show Distance", "แสดงระยะ studs ใต้กรอบ", "ShowDist", nil },
            {
                "Hide Roblox Friends",
                "เปิด = ไม่แสดง ESP ของผู้เล่นที่แอดเป็นเพื่อนใน Roblox",
                "HideFriends",
                nil,
            },
        }
        for _, t in ipairs(espToggles) do
            ESPMain:Toggle({
                Title = t[1],
                Desc = t[2],
                Value = CFG[t[3]],
                Callback = function(s)
                    CFG[t[3]] = s
                    if t[4] then t[4](s) end
                    DebouncedSaveCFG()
                end,
            })
        end

        ESPMain:Slider({
            Title = "Max Distance",
            Desc = "ไม่แสดง ESP เกินระยะนี้ (studs)",
            Icon = "maximize-2",
            Step = 10,
            Value = { Min = 50, Max = 2000, Default = CFG.MaxDist },
            Callback = function(v)
                CFG.MaxDist = v
                DebouncedSaveCFG()
            end,
        })

        ESPMain:Slider({
            Title = "Full Skeleton Distance",
            Desc = "ใกล้กว่านี้วาดโครงกระดูกเต็มรูปแบบ ไกลกว่านี้วาดกรอบสี่เหลี่ยมแทน (ลดกระตุกตอนคน/NPC เยอะ)",
            Icon = "bone",
            Step = 10,
            Value = { Min = 30, Max = 500, Default = CFG.ESPDetailDist or 120 },
            Callback = function(v)
                CFG.ESPDetailDist = v
                DebouncedSaveCFG()
            end,
        })
    end -- IsESPAuthorized
end -- จบเนื้อหาแท็บ ESP

-- ── TAB: TELEPORT (เนื้อหา) ──
local function LoadTeleportTab()
    local Locations = {
        { Title = "ปลูกแคนดี้", Position = Vector3.new(647, 30, 990) },
        { Title = "ปลูกแคนดี้2", Position = Vector3.new(-3267, 4, 1397) },
        { Title = "เรเบล", Position = Vector3.new(4235, 33, 4641) },
        { Title = "การาจกลาง", Position = Vector3.new(2099, 16, 470) },
        { Title = "ขายของ", Position = Vector3.new(4188, 6, 68) },
        { Title = "⛏️เหมืองทอง+เหล็ก", Position = Vector3.new(-805, 3, 5813) },
        { Title = "ที่โพ เหล็ก+ทอง", Position = Vector3.new(2713, 46, -1113) },
        { Title = "กะหล่ำ", Position = Vector3.new(-4175, 75, 1243) },
        { Title = "ข้าวโพด", Position = Vector3.new(-4521, 118, 408) },
        { Title = "พีช", Position = Vector3.new(-5275, 99, -266) },
        { Title = "องุ่น", Position = Vector3.new(-5213, 98, -544) },
        { Title = "ส้ม", Position = Vector3.new(-4624, 123, -780) },
    }
    local LocationTitles, LocationMap = {}, {}
    for _, loc in ipairs(Locations) do
        t_insert(LocationTitles, loc.Title)
        LocationMap[loc.Title] = loc
    end
    local SelectedLocation = Locations[1]

    TeleportTab:Dropdown({
        Title = "Select Location",
        Desc = "เลือกตำแหน่งที่ต้องการ Teleport",
        Icon = "map-pin",
        Values = LocationTitles,
        Value = LocationTitles[1],
        SearchBarEnabled = true,
        Callback = function(opt) SelectedLocation = LocationMap[opt] end,
    })

    TeleportTab:Button({
        Title = "Teleport",
        Desc = "กด Teleport ไปยังสถานที่ที่เลือก",
        Icon = "navigation",
        Callback = function()
            pcall(function()
                local c2 = LP.Character
                if c2 and c2:FindFirstChild("HumanoidRootPart") then c2:PivotTo(CFrame.new(SelectedLocation.Position)) end
            end)
            if CFG.Enabled then
                task.spawn(function()
                    for _, delay in ipairs({ 0.3, 1, 2 }) do
                        task.wait(delay)
                        esp:FireScan()
                        if CFG.NPCSESP then esp:ScanWorkspace() end
                    end
                end)
            end
        end,
    })
end -- จบเนื้อหาแท็บ Teleport

-- ── TAB: SETTINGS (เนื้อหา) ──
local function LoadSettingsTab()
    local function doAntiAFK()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
        pcall(function()
            if hum and hum.Parent and hum.Health > 0 then
                hum:Move(v3_new(0.001, 0, 0), false)
                task.wait(0.1)
                hum:Move(v3_new(0, 0, 0), false)
            end
        end)
    end
    LP.Idled:Connect(function()
        if AntiAFKEnabled then doAntiAFK() end
    end)

    -- ── Fullbright (event-driven — ไม่มี loop, ไม่สร้าง closure ซ้ำ) ──
    --   • ฟังเฉพาะ property ที่เราแตะ แล้วเขียนกลับเฉพาะตัวที่เกมเปลี่ยนจริง
    --     (ของเดิมฟัง Lighting.Changed ทุกอย่าง → ตอนเกมมี day/night cycle จะยิงรัวแล้วรัน 7 prop + GetChildren + pcall ใหม่ทุกครั้ง)
    --   • เขียนเฉพาะตอนค่าต่างจริง (กันสู้กับเกมวนไม่จบ) และจำค่า "ล่าสุดที่เกมตั้ง" ไว้คืนตอนปิด
    --   • effect: สแกนรอบเดียวตอนเปิด + ChildAdded สำหรับตัวที่เกมสร้างทีหลัง + จำสถานะ Enabled เดิมรายตัว
    --   • แก้บั๊ก `vals and vals[i] or orig` ที่ทำให้ GlobalShadows=false ไม่เคยถูกตั้ง
    --   • ยัดทุกอย่างไว้ใน table เดียว ประหยัดโควตา local ของสคริปต์ (limit 200)
    local FB = {
        on = false,
        target = {
            Ambient = Color3.fromRGB(178, 178, 178),
            OutdoorAmbient = Color3.fromRGB(155, 155, 180),
            Brightness = 1,
            ClockTime = 14,
            FogEnd = 1e6,
            FogStart = 1e6,
            GlobalShadows = false,
        },
        fxClasses = { SunRaysEffect = true, DepthOfFieldEffect = true }, -- เพิ่มคลาสที่อยากปิดได้ตรงนี้
        orig = {}, -- ค่า Lighting ล่าสุดที่เกมตั้ง (ใช้คืนตอนปิด)
        origFx = {}, -- [effect] = Enabled เดิม
        conns = {}, -- connection ของ property + ChildAdded/Removed
        fxConns = {}, -- [effect] = connection ของ Enabled
    }

    -- ค่าต่างจริงไหม (ตัวเลขเผื่อ float คลาดเล็กน้อย เช่น ClockTime)
    function FB.differs(cur, want)
        if type(cur) == "number" then return m_abs(cur - want) > 1e-3 end
        return cur ~= want
    end

    function FB.force(prop)
        local cur = Lighting[prop]
        local want = FB.target[prop]
        if FB.differs(cur, want) then
            FB.orig[prop] = cur -- จำสิ่งที่เกมเพิ่งตั้ง จะได้คืนถูกตอนปิด
            Lighting[prop] = want
        end
    end

    function FB.hookFx(fx)
        if not FB.fxClasses[fx.ClassName] or FB.fxConns[fx] then return end
        FB.origFx[fx] = fx.Enabled
        fx.Enabled = false
        FB.fxConns[fx] = fx:GetPropertyChangedSignal("Enabled"):Connect(function()
            if fx.Enabled then
                FB.origFx[fx] = true
                fx.Enabled = false
            end
        end)
    end

    function FB.unhookFx(fx)
        local c = FB.fxConns[fx]
        if c then
            c:Disconnect()
            FB.fxConns[fx] = nil
            FB.origFx[fx] = nil
        end
    end

    function FB.enable()
        pcall(function()
            for prop, want in pairs(FB.target) do
                FB.orig[prop] = Lighting[prop]
                Lighting[prop] = want
            end
            for _, fx in ipairs(Lighting:GetChildren()) do
                FB.hookFx(fx)
            end
        end)
        -- ต่อ listener หลังตั้งค่าเสร็จ (ไม่ให้ตัวเองไปกระตุ้นตัวเอง)
        for prop in pairs(FB.target) do
            t_insert(FB.conns, Lighting:GetPropertyChangedSignal(prop):Connect(function() FB.force(prop) end))
        end
        t_insert(FB.conns, Lighting.ChildAdded:Connect(FB.hookFx))
        t_insert(FB.conns, Lighting.ChildRemoved:Connect(FB.unhookFx))
    end

    function FB.disable()
        for _, c in ipairs(FB.conns) do
            c:Disconnect()
        end
        table.clear(FB.conns)
        pcall(function()
            for prop, v in pairs(FB.orig) do
                Lighting[prop] = v
            end
            for fx, c in pairs(FB.fxConns) do
                c:Disconnect()
                if fx.Parent then fx.Enabled = FB.origFx[fx] end
            end
        end)
        table.clear(FB.fxConns)
        table.clear(FB.origFx)
        table.clear(FB.orig)
    end

    local function setFullbright(state)
        state = state and true or false
        if state == FB.on then return end -- กันเรียกซ้ำ: ไม่งั้นจะเซฟค่า fullbright ทับค่าเดิม
        FB.on = state
        if state then
            FB.enable()
        else
            FB.disable()
        end
    end

    local GameplaySettings = SettingsTab:Section({ Title = "Gameplay", Opened = true })
    GameplaySettings:Toggle({
        Title = "Anti AFK",
        Desc = "ป้องกันถูกเตะออกเกมตอนไม่ได้เล่น",
        Icon = "moon",
        Value = AntiAFKEnabled,
        Callback = function(s)
            AntiAFKEnabled = s
            DebouncedSaveCFG()
        end,
    })
    GameplaySettings:Toggle({
        Title = "Fullbright",
        Desc = "ทำให้มองเห็นชัดในที่มืด ลบ fog/shadow/bloom",
        Icon = "sun-medium",
        Value = false,
        Callback = setFullbright,
    })

    local UISettings = SettingsTab:Section({ Title = "UI Configuration", Opened = true })
    UISettings:Keybind({
        Flag = "UIKeybind",
        Title = "Toggle Menu Key",
        Icon = "keyboard",
        Value = "LeftControl",
        Callback = function(v)
            if Window.SetToggleKey then Window:SetToggleKey(Enum.KeyCode[v]) end
        end,
    })

    local themes = {}
    if WindUI.Themes then
        for name in pairs(WindUI.Themes) do
            t_insert(themes, name)
        end
    end
    if #themes == 0 then themes = { "Dark" } end
    UISettings:Dropdown({
        Flag = "UITheme",
        Title = "UI Theme",
        Icon = "palette",
        Values = themes,
        Default = "SpectreTheme",
        SearchBarEnabled = true,
        Callback = function(t)
            pcall(function() WindUI:SetTheme(t) end)
        end,
    })
end -- จบเนื้อหาแท็บ Settings

-- ══════════════════════════════════════════════════════════════
-- ตัวคุมลำดับการโหลด: สร้างแท็บครบทุกแท็บไปแล้วด้านบน (ปุ่มแท็บขึ้นทันที)
-- ส่วนนี้จะทยอยโหลด "เนื้อหา" ของแต่ละแท็บทีละแท็บ เว้นช่วงสั้นๆ ระหว่างแท็บ
-- ไม่ให้ทุกอย่างประมวลผล/สร้าง UI ภายในพร้อมกันหมดตอนรัน
-- ══════════════════════════════════════════════════════════════
task.spawn(function()
    task.wait(0.25) -- ให้หน้าต่าง/ปุ่มเปิดวาดขึ้นจอก่อน แล้วค่อยทยอยสร้างเนื้อหา (ไม่ค้างตอนเริ่ม)
    Splash.set(0.93, "Loading Home...")
    pcall(SW.LoadHome) -- พังก็ไม่ลากตัวโหลดแท็บอื่นล้มไปด้วย
    task.wait(0.1)
    Splash.set(0.94, "Loading Menu...")
    LoadFarmTab()
    task.wait(0.15)
    Splash.set(0.96, "Loading ESP...")
    LoadESPTab()
    task.wait(0.15)
    Splash.set(0.97, "Loading Teleport...")
    LoadTeleportTab()
    task.wait(0.15)
    Splash.set(0.98, "Loading Settings...")
    LoadSettingsTab()
    SW.building = false -- สร้างครบแล้ว เลิกคั่นเฟรม
    Splash.onReveal = SW.reveal -- เปิด UI ตอน Splash เริ่มจาง
    Splash.finish()
    if not Splash.alive then SW.reveal() end -- UI สร้างครบแล้ว → โลโก้ค้างแป๊บนึงแล้วค่อยๆจางหาย
end)

-- อยู่นอก task.spawn ของแท็บ Settings โดยตั้งใจ: ลงทะเบียนทันทีแบบ sync กันพลาดจังหวะถ้า CFG โหลดเสร็จเร็วกว่า
OnCFGLoaded(function(cfg)
    if not cfg.Enabled then return end
    esp:FireScan()
    if cfg.NPCSESP then task.spawn(function() esp:ScanWorkspace() end) end
end)
