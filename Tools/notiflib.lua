-- Script by IceMinister#9889
local NotificationLibrary = {}
local TweenService = game:GetService("TweenService")
local CoreGui = cloneref(game:GetService("CoreGui"))
local LibraryName = "Notification Library"
local library, templateFolder, canvas

-- ── ปรับได้ตรงนี้ ─────────────────────────────────────────────────────────────
local NOTIF_HEIGHT_SCALE = 0.16
local NOTIF_TEXT_SIZE    = 20
local CORNER_RADIUS      = UDim.new(0, 10)
local STROKE_THICKNESS   = 1
local SHADOW_TRANSPARENCY = 0.55

-- สี accent ต่อโหมด (ปรับชื่อ key ให้ตรงกับชื่อ template จริงของนายได้เลย)
local MODE_COLORS = {
    Success = Color3.fromRGB(80, 220, 130),
    Error   = Color3.fromRGB(235, 70, 70),
    Warning = Color3.fromRGB(250, 190, 60),
    Info    = Color3.fromRGB(90, 160, 250),
}

function NotificationLibrary:Load()
    library = game:GetObjects("rbxassetid://15133757123")[1]
    templateFolder = library.Templates
    canvas = library.list
    library.Name = LibraryName
    library.Parent = CoreGui
end

local function polish(n, mode)
    -- มุมโค้ง
    if not n:FindFirstChildOfClass("UICorner") then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = CORNER_RADIUS
        corner.Parent = n
    end

    -- ขอบบาง + เรืองแสงอ่อนๆตามสีโหมด
    local accent = MODE_COLORS[mode] or Color3.fromRGB(150, 150, 255)
    local stroke = n:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
    stroke.Thickness = STROKE_THICKNESS
    stroke.Transparency = 0.5
    stroke.Color = accent
    stroke.Parent = n

    -- เงาด้านล่างให้การ์ดลอยขึ้นมาจากพื้นหลัง
    if not n:FindFirstChild("__Shadow") then
        local shadow = Instance.new("ImageLabel")
        shadow.Name = "__Shadow"
        shadow.Image = "rbxassetid://6014261993" -- soft shadow asset
        shadow.ImageColor3 = Color3.new(0,0,0)
        shadow.ImageTransparency = SHADOW_TRANSPARENCY
        shadow.ScaleType = Enum.ScaleType.Slice
        shadow.SliceCenter = Rect.new(49, 49, 450, 450)
        shadow.BackgroundTransparency = 1
        shadow.Size = UDim2.new(1, 24, 1, 24)
        shadow.Position = UDim2.new(0.5, 0, 0.5, 6)
        shadow.AnchorPoint = Vector2.new(0.5, 0.5)
        shadow.ZIndex = n.ZIndex - 1
        shadow.Parent = n
    end

    -- ทาสี bar ด้านข้างให้ตรงกับ accent (ถ้ามี bar/filler ที่ใช้แถบสีสถานะ)
    local bar = n:FindFirstChild("bar")
    if bar and bar:IsA("Frame") then
        pcall(function() bar.BackgroundColor3 = accent end)
    end
end

function NotificationLibrary:SendNotification(Mode, Text, Duration)
    local libaryCore = CoreGui:FindFirstChild(LibraryName)
    if not libaryCore then
        NotificationLibrary:Load()
    else
        library = libaryCore
        templateFolder = library.Templates
        canvas = library.list
    end
    local _resolvedMode = Mode
    if not templateFolder:FindFirstChild(Mode) then
        local _avail = {}
        for _, c in ipairs(templateFolder:GetChildren()) do table.insert(_avail, c.Name) end
        warn("notif: mode '"..Mode.."' not found. Available: "..table.concat(_avail,", "))
        _resolvedMode = _avail[1]
    end
    if not _resolvedMode then return end

    task.spawn(function()
        local ok, err = pcall(function()
            local n = templateFolder:WaitForChild(_resolvedMode):Clone()
            local filler, bar = n.Filler, n.bar
            n.Header.Text = Text
            n.Header.TextTransparency = 1 -- เริ่มโปร่งใส เดี๋ยว fade เข้า

            polish(n, _resolvedMode)

            pcall(function()
                n.Header.TextWrapped = true
                n.Header.TextScaled  = true
                local constraint = n.Header:FindFirstChildOfClass("UITextSizeConstraint")
                    or Instance.new("UITextSizeConstraint")
                constraint.MinTextSize = 13
                constraint.MaxTextSize = NOTIF_TEXT_SIZE
                constraint.Parent = n.Header
            end)

            n.Visible = true
            n.Parent = canvas
            n.Size = UDim2.new(0,0,NOTIF_HEIGHT_SCALE,0)
            n.Position = n.Position + UDim2.new(0.15, 0, 0, 0) -- เลื่อนจากขวาเข้ามา
            filler.Size = UDim2.new(1,0,1,0)

            local TIn   = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            local TFade = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local TBar  = TweenInfo.new(Duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
            local TOutFiller = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local TOut  = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)

            -- เข้าแบบเด้งนิดๆ + เลื่อนกลับเข้าตำแหน่งเดิม
            TweenService:Create(n, TIn, {
                Size = UDim2.new(1,0,NOTIF_HEIGHT_SCALE,0),
                Position = n.Position - UDim2.new(0.15, 0, 0, 0),
            }):Play()
            TweenService:Create(n.Header, TFade, {TextTransparency = 0}):Play()

            task.wait(0.2)
            TweenService:Create(filler, TFade, {Size=UDim2.new(0.011,0,1,0)}):Play()
            TweenService:Create(bar, TBar, {Size=UDim2.new(1,0,0.05,0)}):Play()

            task.wait(Duration)
            TweenService:Create(n.Header, TOutFiller, {TextTransparency = 1}):Play()
            TweenService:Create(filler, TOutFiller, {Size=UDim2.new(1,0,1,0)}):Play()
            task.wait(0.2)
            TweenService:Create(n, TOut, {Size=UDim2.new(0,0,NOTIF_HEIGHT_SCALE,0)}):Play()
            task.wait(0.3)
            n:Destroy()
        end)
        if not ok then warn("notif error: "..tostring(err)) end
    end)
end

return NotificationLibrary
