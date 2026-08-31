--[[
    SpectreUI Icons Module
    ======================
    Asset id ทั้งหมดอ้างอิงจาก Lucide icon pack บน Roblox (ตัวเดียวกับที่ Fluent UI ใช้จริง)
    ตรวจสอบชื่อ<->id ตรงกันแล้วทีละตัว ไม่มีการใช้ id ซ้ำข้ามชื่อ

    Host ไฟล์นี้แยกจาก main library แล้ว loadstring ในตัว main script ด้วย:
        Library.Icons = loadstring(game:HttpGet("<raw-url-ของไฟล์นี้>", true))()
]]

return {
    -- Navigation
    home = "rbxassetid://10723407389",
    list = "rbxassetid://10723433811",
    chevronDown = "rbxassetid://10709790948",
    chevronUp = "rbxassetid://10709791523",
    chevronLeft = "rbxassetid://10709791281",
    chevronRight = "rbxassetid://10709791437",

    -- Settings & System
    settings = "rbxassetid://10734950309",
    sliders = "rbxassetid://10734963400",
    toggle = "rbxassetid://10734985040",
    toggleOff = "rbxassetid://10734984834",
    lock = "rbxassetid://10723434711",
    unlock = "rbxassetid://10747366027",
    power = "rbxassetid://10734930466",
    logout = "rbxassetid://10723434906",
    shield = "rbxassetid://10734951847",

    -- Actions
    play = "rbxassetid://10734923549",
    pause = "rbxassetid://10734919336",
    refresh = "rbxassetid://10734933222",
    search = "rbxassetid://10734943674",
    edit = "rbxassetid://10734883598",
    copy = "rbxassetid://10709812159",
    trash = "rbxassetid://10747362393",
    plus = "rbxassetid://10734924532",
    minus = "rbxassetid://10734896206",
    check = "rbxassetid://10709790644",
    close = "rbxassetid://10747384394",

    -- Content
    script = "rbxassetid://10723356507",
    code = "rbxassetid://10709810463",
    file = "rbxassetid://10723374641",
    folder = "rbxassetid://10723387563",
    image = "rbxassetid://10723415040",
    eye = "rbxassetid://10723346959",
    eyeOff = "rbxassetid://10723346871",

    -- People & Social
    user = "rbxassetid://10747373176",
    users = "rbxassetid://10747373426",
    heart = "rbxassetid://10723406885",
    star = "rbxassetid://10734966248",
    bell = "rbxassetid://10709775704",
    mail = "rbxassetid://10734885430",
    message = "rbxassetid://10734888000",

    -- Time & Status
    clock = "rbxassetid://10709805144",
    calendar = "rbxassetid://10709789505",
    info = "rbxassetid://10723415903",
    warning = "rbxassetid://10709753149",
    error = "rbxassetid://10709753064",

    -- Game & Items
    sword = "rbxassetid://10734975486",
    target = "rbxassetid://10734977012",
    crosshair = "rbxassetid://10709818534",
    flag = "rbxassetid://10723375890",
    trophy = "rbxassetid://10747363809",
    crown = "rbxassetid://10709818626",
    gem = "rbxassetid://10723396000",
    coin = "rbxassetid://10709811110",
    key = "rbxassetid://10723416652",
    gift = "rbxassetid://10723396402",

    -- Environment
    globe = "rbxassetid://10723404337",
    cloud = "rbxassetid://10709806740",
    wifi = "rbxassetid://10747382504",
    sun = "rbxassetid://10734974297",
    moon = "rbxassetid://10734897102",
    fire = "rbxassetid://10723376114",
    water = "rbxassetid://10723344432",
    leaf = "rbxassetid://10723425539",
    wind = "rbxassetid://10747382750",
}
