-- ═══════════════════════════════════════════════════════════
-- MM2 CHEAT MOBILE v7.0 — FINAL
-- ═══════════════════════════════════════════════════════════

if _G.MM2_V7 then pcall(function() _G.MM2_V7() end) end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local Workspace = game.Workspace
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local HAS_DRAWING = false
pcall(function()
    if Drawing and Drawing.new and type(Drawing.new) == "function" then
        HAS_DRAWING = true
    end
end)

local GUI_PARENT = nil
pcall(function()
    local test = Instance.new("ScreenGui")
    test.Parent = game:GetService("CoreGui")
    test:Destroy()
    GUI_PARENT = game:GetService("CoreGui")
end)
if not GUI_PARENT then
    GUI_PARENT = LocalPlayer:WaitForChild("PlayerGui")
end

-- ═══════════════════════════════════════════════════════════
-- КОНФИГ
-- ═══════════════════════════════════════════════════════════

local CONFIG = {
    ESP = false, ESP_Box = true, ESP_Name = true, ESP_Role = true,
    ESP_Distance = true, ESP_Health = true,
    MaxDistance = 2000,

    Aimbot = false, Aimbot_FOV = 120, Aimbot_Smooth = 0.15,
    Aimbot_Part = "Head", Aimbot_TeamCheck = true,

    SilentAim = false, SilentAim_HitChance = 100,
    Reach = false, ReachDistance = 15,

    AutoFarm = false, AutoFarm_Speed = 5, AutoCollect = false,
    CoinMagnet = false, AutoRespawn = false, AutoPickupGun = false,

    WalkSpeed = 16, JumpPower = 50, InfiniteJump = false,
    FullBright = false, NoClip = false, Fly = false, FlySpeed = 50,
    AntiFling = false, ChatSpam = false, ChatSpamText = "MM2 ON TOP",

    HitboxExpand = false, HitboxSize = 2.5,
    AutoDodge = false,

    FlingAll = false, FlingPower = 500,
    VoidPush = false, VoidPower = 300,
    FreezeAll = false, RagdollAll = false, KillAll = false,

    Watermark = true,
}

local ROLE_COLORS = {
    Innocent = Color3.fromRGB(0, 255, 100),
    Sheriff  = Color3.fromRGB(0, 150, 255),
    Murderer = Color3.fromRGB(255, 0, 0),
    Unknown  = Color3.fromRGB(200, 200, 200),
    Local    = Color3.fromRGB(255, 255, 0),
}

local THEME = {
    bg = Color3.fromRGB(10, 10, 18),
    panel = Color3.fromRGB(16, 15, 28),
    panel2 = Color3.fromRGB(22, 20, 38),
    accent = Color3.fromRGB(139, 92, 246),
    text = Color3.fromRGB(230, 230, 245),
    text_dim = Color3.fromRGB(140, 140, 170),
    success = Color3.fromRGB(34, 197, 94),
    danger = Color3.fromRGB(239, 68, 68),
}

-- ═══════════════════════════════════════════════════════════
-- СОСТОЯНИЕ
-- ═══════════════════════════════════════════════════════════

local State = {
    ESP = {},
    FOV = nil,
    Fly_BV = nil, Fly_BG = nil,
    Noclip = nil,
    Panic = false,
    GUI = nil,
    Connections = {},
}

_G.MM2_V7 = function()
    pcall(function()
        for _, c in pairs(State.Connections) do pcall(function() c:Disconnect() end) end
        if State.GUI then State.GUI:Destroy() end
        for _, o in pairs(State.ESP) do
            for _, d in pairs(o) do pcall(function() d:Remove() end) end
        end
        if State.FOV then pcall(function() State.FOV:Remove() end) end
    end)
end

local function track(c) table.insert(State.Connections, c); return c end
local function notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "MM2", Text = text or "", Duration = dur or 3,
        })
    end)
end

local function getHRP(p)
    local c = p and p.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum(p)
    local c = p and p.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- ═══════════════════════════════════════════════════════════
-- РОЛИ
-- ═══════════════════════════════════════════════════════════

local RoleCache = {}
local RolePrio = {}

local function normRole(s)
    if not s then return nil end
    local l = tostring(s):lower()
    if l:find("murder") or l:find("убий") then return "Murderer" end
    if l:find("sheriff") or l:find("шериф") then return "Sheriff" end
    if l:find("innocent") or l:find("невин") then return "Innocent" end
    return nil
end

task.spawn(function()
    pcall(function()
        local RS = game:GetService("ReplicatedStorage")
        for _, v in ipairs(RS:GetDescendants()) do
            if v:IsA("RemoteEvent") then
                local n = v.Name:lower()
                if n:find("role") or n:find("assign") or n:find("round") or n:find("start") or n:find("murder") then
                    pcall(function()
                        track(v.OnClientEvent:Connect(function(...)
                            local args = {...}
                            for _, a in ipairs(args) do
                                if typeof(a) == "Instance" and a:IsA("Player") then
                                    for _, b in ipairs(args) do
                                        if typeof(b) == "string" then
                                            local r = normRole(b)
                                            if r then RoleCache[a] = r; RolePrio[a] = 100 end
                                        end
                                    end
                                end
                            end
                        end))
                    end)
                end
            end
        end
    end)
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(function()
            for _, p in ipairs(Players:GetPlayers()) do
                if p == LocalPlayer then continue end
                pcall(function()
                    local r = normRole(p:GetAttribute("Role") or p:GetAttribute("role"))
                    if r and (RolePrio[p] or 0) < 80 then RoleCache[p] = r; RolePrio[p] = 80 end
                end)
                pcall(function()
                    local ls = p:FindFirstChild("leaderstats")
                    if ls then
                        local rr = ls:FindFirstChild("Role") or ls:FindFirstChild("Team")
                        if rr then
                            local r = normRole(rr.Value)
                            if r and (RolePrio[p] or 0) < 70 then RoleCache[p] = r; RolePrio[p] = 70 end
                        end
                    end
                end)
                pcall(function()
                    local h = p.Character and p.Character:FindFirstChild("Head")
                    if h then
                        for _, v in ipairs(h:GetChildren()) do
                            if v:IsA("BillboardGui") then
                                for _, t in ipairs(v:GetDescendants()) do
                                    if t:IsA("TextLabel") then
                                        local r = normRole(t.Text)
                                        if r and (RolePrio[p] or 0) < 60 then RoleCache[p] = r; RolePrio[p] = 60 end
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end)
    end
end)

local function getRole(p)
    if p == LocalPlayer then return "Local" end
    if RoleCache[p] then return RoleCache[p] end
    local c = p.Character
    if not c then return "Unknown" end
    local function chk(tool)
        local n = tool.Name:lower()
        if n:find("knife") or n:find("murder") or n:find("blade") then return "Murderer" end
        if n:find("gun") or n:find("revolver") or n:find("sheriff") then return "Sheriff" end
    end
    for _, t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") then local r = chk(t); if r then RoleCache[p] = r; RolePrio[p] = 40; return r end end
    end
    local bp = p:FindFirstChild("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then local r = chk(t); if r then RoleCache[p] = r; RolePrio[p] = 40; return r end end
        end
    end
    return "Innocent"
end

-- ═══════════════════════════════════════════════════════════
-- HITBOX
-- ═══════════════════════════════════════════════════════════

local function expandHB(p)
    if not CONFIG.HitboxExpand then return end
    local c = p.Character
    if not c then return end
    for _, part in ipairs(c:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            if not part:GetAttribute("_os") then
                part:SetAttribute("_os", part.Size)
                part:SetAttribute("_ot", part.Transparency)
                part:SetAttribute("_oc", part.CanCollide)
            end
            local o = part:GetAttribute("_os")
            if o then
                pcall(function()
                    part.Size = Vector3.new(o.X * CONFIG.HitboxSize, o.Y * CONFIG.HitboxSize, o.Z * CONFIG.HitboxSize)
                    part.Transparency = 1
                    part.CanCollide = false
                end)
            end
        end
    end
end

local function resetHB(p)
    local c = p and p.Character
    if not c then return end
    for _, part in ipairs(c:GetDescendants()) do
        if part:IsA("BasePart") then
            local o = part:GetAttribute("_os")
            if o then
                pcall(function()
                    part.Size = o
                    part.Transparency = part:GetAttribute("_ot") or 0
                    part.CanCollide = part:GetAttribute("_oc") ~= false
                    part:SetAttribute("_os", nil)
                    part:SetAttribute("_ot", nil)
                    part:SetAttribute("_oc", nil)
                end)
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- ESP (если Drawing поддерживается)
-- ═══════════════════════════════════════════════════════════

local function createESP(p)
    if not HAS_DRAWING then return end
    if p == LocalPlayer or State.ESP[p] then return end
    local o = {}
    pcall(function()
        o.box = Drawing.new("Square"); o.box.Thickness = 2; o.box.Filled = false; o.box.Transparency = 1; o.box.Visible = false
        o.name = Drawing.new("Text"); o.name.Size = 14; o.name.Center = true; o.name.Outline = true; o.name.Font = Drawing.Fonts.UI; o.name.Visible = false
        o.role = Drawing.new("Text"); o.role.Size = 14; o.role.Center = true; o.role.Outline = true; o.role.Font = Drawing.Fonts.UI; o.role.Visible = false
        o.dist = Drawing.new("Text"); o.dist.Size = 12; o.dist.Center = true; o.dist.Outline = true; o.dist.Font = Drawing.Fonts.UI; o.dist.Visible = false
        o.hp = Drawing.new("Text"); o.hp.Size = 12; o.hp.Center = true; o.hp.Outline = true; o.hp.Font = Drawing.Fonts.UI; o.hp.Visible = false
        State.ESP[p] = o
    end)
end

local function removeESP(p)
    local o = State.ESP[p]
    if not o then return end
    for _, d in pairs(o) do pcall(function() d:Remove() end) end
    State.ESP[p] = nil
end

local function updateESP()
    if not HAS_DRAWING or State.Panic then return end
    for p, o in pairs(State.ESP) do
        local hrp, hum = getHRP(p), getHum(p)
        if not (hrp and hum and hum.Health > 0) then
            pcall(function()
                o.box.Visible=false; o.name.Visible=false; o.role.Visible=false
                o.dist.Visible=false; o.hp.Visible=false
            end)
            continue
        end
        if CONFIG.HitboxExpand then expandHB(p) end
        local pos, on = Camera:WorldToViewportPoint(hrp.Position)
        local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
        if not on or dist > CONFIG.MaxDistance then
            pcall(function()
                o.box.Visible=false; o.name.Visible=false; o.role.Visible=false
                o.dist.Visible=false; o.hp.Visible=false
            end)
            continue
        end
        local sc = 1 / dist * 100
        local sz = Vector2.new(sc * 2.5, sc * 3.5)
        local rv = getRole(p)
        local col = ROLE_COLORS[rv] or ROLE_COLORS.Unknown
        pcall(function()
            o.box.Size = sz
            o.box.Position = Vector2.new(pos.X - sz.X/2, pos.Y - sz.Y/2)
            o.box.Color = col
            o.box.Visible = CONFIG.ESP and CONFIG.ESP_Box

            o.name.Text = p.Name
            o.name.Position = Vector2.new(pos.X, pos.Y - sz.Y/2 - 30)
            o.name.Color = Color3.fromRGB(255,255,255)
            o.name.Visible = CONFIG.ESP and CONFIG.ESP_Name

            o.role.Text = rv
            o.role.Position = Vector2.new(pos.X, pos.Y + sz.Y/2 + 5)
            o.role.Color = col
            o.role.Visible = CONFIG.ESP and CONFIG.ESP_Role

            o.dist.Text = string.format("[%dm]", math.floor(dist))
            o.dist.Position = Vector2.new(pos.X, pos.Y + sz.Y/2 + 22)
            o.dist.Color = Color3.fromRGB(200,200,200)
            o.dist.Visible = CONFIG.ESP and CONFIG.ESP_Distance

            o.hp.Text = string.format("HP %d", math.floor(hum.Health))
            o.hp.Position = Vector2.new(pos.X, pos.Y - sz.Y/2 - 46)
            o.hp.Color = Color3.fromRGB(255,255,255)
            o.hp.Visible = CONFIG.ESP and CONFIG.ESP_Health
        end)
    end
end

-- ═══════════════════════════════════════════════════════════
-- AIMBOT
-- ═══════════════════════════════════════════════════════════

local function getTarget()
    local closest, shortest = nil, CONFIG.Aimbot_FOV
    local ctr = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local hrp, hum = getHRP(p), getHum(p)
        if not (hrp and hum and hum.Health > 0) then continue end
        if CONFIG.Aimbot_TeamCheck then
            local my, th = getRole(LocalPlayer), getRole(p)
            if my == th and my ~= "Innocent" then continue end
        end
        local tp = hrp
        if CONFIG.Aimbot_Part == "Head" and p.Character:FindFirstChild("Head") then
            tp = p.Character.Head
        end
        local pos, on = Camera:WorldToViewportPoint(tp.Position)
        if not on then continue end
        local d = (Vector2.new(pos.X, pos.Y) - ctr).Magnitude
        if d < shortest then shortest = d; closest = tp end
    end
    return closest
end

local function aimbot()
    if State.Panic or not CONFIG.Aimbot then return end
    if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
    local t = getTarget()
    if not t then return end
    local cur = Camera.CFrame
    Camera.CFrame = cur:Lerp(CFrame.new(cur.Position, t.Position), CONFIG.Aimbot_Smooth)
end

-- ═══════════════════════════════════════════════════════════
-- ФУНКЦИИ
-- ═══════════════════════════════════════════════════════════

local function setWS(v) local h = getHum(LocalPlayer); if h then h.WalkSpeed = v end end
local function setJP(v) local h = getHum(LocalPlayer); if h then h.JumpPower = v end end

local function infJump()
    if State.Panic or not CONFIG.InfiniteJump then return end
    local h = getHum(LocalPlayer)
    if h and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        h:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end

local function fb()
    if CONFIG.FullBright then
        Lighting.Brightness = 2; Lighting.ClockTime = 12
        Lighting.FogEnd = 100000; Lighting.GlobalShadows = false
    end
end

local function noclip()
    if not CONFIG.NoClip then
        if State.Noclip then State.Noclip:Disconnect(); State.Noclip = nil end
        return
    end
    if State.Noclip then return end
    State.Noclip = RunService.Stepped:Connect(function()
        local c = LocalPlayer.Character
        if c then
            for _, part in ipairs(c:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
            end
        end
    end)
end

local function fly()
    if not CONFIG.Fly then
        if State.Fly_BV then State.Fly_BV:Destroy(); State.Fly_BV = nil end
        if State.Fly_BG then State.Fly_BG:Destroy(); State.Fly_BG = nil end
        return
    end
    if State.Fly_BV then return end
    local hrp = getHRP(LocalPlayer); if not hrp then return end
    State.Fly_BV = Instance.new("BodyVelocity")
    State.Fly_BV.MaxForce = Vector3.new(1e5,1e5,1e5)
    State.Fly_BV.Velocity = Vector3.zero
    State.Fly_BV.Parent = hrp
    State.Fly_BG = Instance.new("BodyGyro")
    State.Fly_BG.MaxTorque = Vector3.new(1e5,1e5,1e5)
    State.Fly_BG.P = 1000
    State.Fly_BG.Parent = hrp
    task.spawn(function()
        while CONFIG.Fly and State.Fly_BV do
            local m = Vector3.zero
            local cam = Camera.CFrame
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then m += cam.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then m -= cam.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then m -= cam.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then m += cam.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then m += Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then m -= Vector3.new(0,1,0) end
            State.Fly_BV.Velocity = m * CONFIG.FlySpeed
            State.Fly_BG.CFrame = cam
            RunService.RenderStepped:Wait()
        end
    end)
end

local function antiFling()
    if not CONFIG.AntiFling then return end
    local hrp = getHRP(LocalPlayer); if not hrp then return end
    pcall(function() hrp.CustomPhysicalProperties = PhysicalProperties.new(0.01,0.01,0.01,0,0) end)
end

local function autoCollect()
    if State.Panic or not CONFIG.AutoCollect then return end
    local hrp = getHRP(LocalPlayer); if not hrp then return end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name ~= "Baseplate" then
            if (hrp.Position - obj.Position).Magnitude < 5 then
                pcall(function()
                    if firetouchinterest then
                        firetouchinterest(hrp, obj, 0)
                        firetouchinterest(hrp, obj, 1)
                    end
                end)
            end
        end
    end
end

local function coinMagnet()
    if State.Panic or not CONFIG.CoinMagnet then return end
    local hrp = getHRP(LocalPlayer); if not hrp then return end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:lower():find("coin") then
            pcall(function() obj.CFrame = hrp.CFrame end)
        end
    end
end

local function autoFarm()
    if State.Panic or not CONFIG.AutoFarm then return end
    local hrp = getHRP(LocalPlayer); if not hrp then return end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name:lower():find("coin") and obj:IsA("BasePart") then
            if (hrp.Position - obj.Position).Magnitude < 500 then
                hrp.CFrame = CFrame.new(obj.Position + Vector3.new(0,3,0))
                task.wait(CONFIG.AutoFarm_Speed / 100)
            end
        end
    end
end

local function autoRespawn()
    if State.Panic or not CONFIG.AutoRespawn then return end
    local h = getHum(LocalPlayer)
    if h and h.Health <= 0 then pcall(function() LocalPlayer:LoadCharacter() end) end
end

local function autoDodge()
    if State.Panic or not CONFIG.AutoDodge then return end
    local my = getHRP(LocalPlayer); if not my then return end
    if getRole(LocalPlayer) == "Murderer" then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if getRole(p) == "Murderer" then
            local hrp = getHRP(p)
            if hrp and (hrp.Position - my.Position).Magnitude < 12 then
                local dir = (my.Position - hrp.Position).Unit
                my.Velocity = Vector3.new(-dir.Z, 0, dir.X) * 60 + Vector3.new(0, 30, 0)
            end
        end
    end
end

local function autoPickup()
    if State.Panic or not CONFIG.AutoPickupGun then return end
    local my = getHRP(LocalPlayer); if not my then return end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Tool") then
            local n = obj.Name:lower()
            if n:find("gun") or n:find("revolver") then
                if (my.Position - obj.Position).Magnitude < 8 then
                    pcall(function()
                        if firetouchinterest then
                            firetouchinterest(my, obj, 0)
                            firetouchinterest(my, obj, 1)
                        end
                    end)
                end
            end
        end
    end
end

local function reachLoop()
    if State.Panic or not CONFIG.Reach then return end
    local c = LocalPlayer.Character
    if not c then return end
    local tool = c:FindFirstChildOfClass("Tool")
    if tool then pcall(function() tool:SetAttribute("Reach", CONFIG.ReachDistance) end) end
end

local function chatSpam()
    if State.Panic or not CONFIG.ChatSpam then return end
    pcall(function()
        game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(CONFIG.ChatSpamText, "All")
    end)
end

local function fling(p, power)
    local hrp = getHRP(p); if not hrp then return end
    task.spawn(function()
        local t = tick()
        while tick() - t < 0.3 do
            pcall(function()
                local bv = Instance.new("BodyVelocity")
                bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bv.Velocity = Vector3.new(
                    math.random(-power, power),
                    math.random(power, power*2),
                    math.random(-power, power))
                bv.Parent = hrp
                task.wait(0.05)
                bv:Destroy()
            end)
            RunService.Heartbeat:Wait()
        end
    end)
end

local function voidPush(p, power)
    local hrp = getHRP(p); if not hrp then return end
    task.spawn(function()
        local t = tick()
        local vp = Vector3.new(
            math.random(-power*10, power*10),
            -power*10 - 500,
            math.random(-power*10, power*10))
        while tick() - t < 0.5 do
            pcall(function()
                if hrp and hrp.Parent then
                    hrp.CFrame = CFrame.new(vp)
                    hrp.Velocity = Vector3.new(0, -power*2, 0)
                    hrp.AssemblyLinearVelocity = Vector3.new(0, -power*2, 0)
                else
                    break
                end
            end)
            RunService.Heartbeat:Wait()
        end
    end)
end

local function griefLoop()
    while true do
        task.wait(0.5)
        if not State.Panic then
            if CONFIG.FlingAll then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer then fling(p, CONFIG.FlingPower) end
                end
            end
            if CONFIG.VoidPush then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer then voidPush(p, CONFIG.VoidPower) end
                end
            end
            if CONFIG.FreezeAll then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer then
                        local hrp, hum = getHRP(p), getHum(p)
                        if hrp and hum then
                            pcall(function() hum.WalkSpeed = 0; hum.JumpPower = 0; hrp.Anchored = true end)
                        end
                    end
                end
            end
            if CONFIG.RagdollAll then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer then
                        local hum = getHum(p)
                        if hum then
                            pcall(function()
                                hum:ChangeState(Enum.HumanoidStateType.Physics)
                                hum.PlatformStand = true
                            end)
                        end
                    end
                end
            end
            if CONFIG.KillAll then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer then
                        local hum = getHum(p)
                        if hum then pcall(function() hum.Health = 0 end) end
                    end
                end
            end
        end
    end
end

local function panic()
    State.Panic = true
    if State.GUI then State.GUI.Enabled = false end
    for _, o in pairs(State.ESP) do
        for _, d in pairs(o) do pcall(function() d.Visible = false end) end
    end
    for _, p in ipairs(Players:GetPlayers()) do resetHB(p) end
    CONFIG.ESP = false; CONFIG.Aimbot = false; CONFIG.SilentAim = false
    CONFIG.Fly = false; CONFIG.FlingAll = false; CONFIG.VoidPush = false
    CONFIG.FreezeAll = false; CONFIG.RagdollAll = false; CONFIG.ChatSpam = false
    CONFIG.HitboxExpand = false; CONFIG.KillAll = false
    notify("Panic", "всё скрыто", 2)
end

local function unpanic()
    State.Panic = false
    if State.GUI then State.GUI.Enabled = true end
    notify("Panic", "снято", 2)
end

-- ═══════════════════════════════════════════════════════════
-- UI — из рабочих кусков
-- ═══════════════════════════════════════════════════════════

local function buildUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "MM2_" .. math.random(100000, 999999)
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 999999
    gui.Parent = GUI_PARENT
    State.GUI = gui

    local wm = Instance.new("TextLabel")
    wm.Size = UDim2.new(0, 130, 0, 22)
    wm.Position = UDim2.new(1, -140, 0, 10)
    wm.BackgroundColor3 = THEME.panel
    wm.BackgroundTransparency = 0.2
    wm.BorderSizePixel = 0
    wm.Text = "⚡ MM2 v7"
    wm.TextColor3 = THEME.text
    wm.TextSize = 11
    wm.Font = Enum.Font.GothamBold
    wm.Visible = CONFIG.Watermark
    wm.Parent = gui
    local wmc = Instance.new("UICorner"); wmc.CornerRadius = UDim.new(0, 6); wmc.Parent = wm

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 60, 0, 60)
    btn.Position = UDim2.new(0, 20, 0.5, -30)
    btn.BackgroundColor3 = THEME.panel
    btn.Text = "⚡"
    btn.TextColor3 = THEME.accent
    btn.TextSize = 28
    btn.Font = Enum.Font.GothamBold
    btn.Parent = gui
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(1, 0); bc.Parent = btn

    local menu = Instance.new("Frame")
    menu.Size = UDim2.new(0, 340, 0, 400)
    menu.Position = UDim2.new(0.5, -170, 0.5, -200)
    menu.BackgroundColor3 = THEME.bg
    menu.Visible = false
    menu.Parent = gui
    local mc = Instance.new("UICorner"); mc.CornerRadius = UDim.new(0, 14); mc.Parent = menu

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = Color3.fromRGB(30, 25, 50)
    title.Text = "MM2 CHEAT"
    title.TextColor3 = Color3.fromRGB(167, 139, 250)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.Parent = menu
    local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0, 14); tc.Parent = title

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 28, 0, 28)
    close.Position = UDim2.new(1, -32, 0, 7)
    close.BackgroundColor3 = THEME.panel2
    close.Text = "✕"
    close.TextColor3 = THEME.danger
    close.TextSize = 14
    close.Font = Enum.Font.GothamBold
    close.Parent = title
    local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 8); cc.Parent = close

    local tabbar = Instance.new("ScrollingFrame")
    tabbar.Size = UDim2.new(1, -8, 0, 36)
    tabbar.Position = UDim2.new(0, 4, 0, 44)
    tabbar.BackgroundTransparency = 1
    tabbar.BorderSizePixel = 0
    tabbar.ScrollBarThickness = 0
    tabbar.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabbar.AutomaticCanvasSize = Enum.AutomaticSize.X
    tabbar.ScrollingDirection = Enum.ScrollingDirection.X
    tabbar.Parent = menu

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabbar

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -8, 1, -90)
    content.Position = UDim2.new(0, 4, 0, 84)
    content.BackgroundColor3 = THEME.panel
    content.BorderSizePixel = 0
    content.Parent = menu
    local con = Instance.new("UICorner"); con.CornerRadius = UDim.new(0, 10); con.Parent = content

    local tabs, pages = {}, {}

    local function makeTab(name)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 75, 0, 30)
        b.BackgroundColor3 = THEME.panel2
        b.Text = name
        b.TextColor3 = THEME.text_dim
        b.TextSize = 11
        b.Font = Enum.Font.GothamBold
        b.AutoButtonColor = false
        b.Parent = tabbar
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = b
        table.insert(tabs, b)

        local p = Instance.new("ScrollingFrame")
        p.Size = UDim2.new(1, -8, 1, -8)
        p.Position = UDim2.new(0, 4, 0, 4)
        p.BackgroundTransparency = 1
        p.BorderSizePixel = 0
        p.ScrollBarThickness = 3
        p.ScrollBarImageColor3 = THEME.accent
        p.CanvasSize = UDim2.new(0, 0, 0, 1000)
        p.Visible = false
        p.Parent = content
        table.insert(pages, p)

        b.MouseButton1Click:Connect(function()
            for i, pp in ipairs(pages) do
                pp.Visible = false
                tabs[i].BackgroundColor3 = THEME.panel2
                tabs[i].TextColor3 = THEME.text_dim
            end
            p.Visible = true
            b.BackgroundColor3 = THEME.accent
            b.TextColor3 = Color3.fromRGB(255,255,255)
        end)
        return p
    end

    local function makeToggle(page, y, text, default, cb)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, -8, 0, 36)
        f.Position = UDim2.new(0, 4, 0, y)
        f.BackgroundColor3 = THEME.panel2
        f.BorderSizePixel = 0
        f.Parent = page
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = f

        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -70, 1, 0)
        l.Position = UDim2.new(0, 12, 0, 0)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = THEME.text
        l.TextSize = 12
        l.Font = Enum.Font.Gotham
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = f

        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 50, 0, 24)
        b.Position = UDim2.new(1, -58, 0, 6)
        b.BackgroundColor3 = default and THEME.accent or Color3.fromRGB(45,42,65)
        b.Text = default and "ON" or "OFF"
        b.TextColor3 = default and Color3.fromRGB(255,255,255) or THEME.text_dim
        b.TextSize = 11
        b.Font = Enum.Font.GothamBold
        b.AutoButtonColor = false
        b.Parent = f
        local bc2 = Instance.new("UICorner"); bc2.CornerRadius = UDim.new(1, 0); bc2.Parent = b

        b.MouseButton1Click:Connect(function()
            local s = b.Text == "ON"
            s = not s
            b.Text = s and "ON" or "OFF"
            b.BackgroundColor3 = s and THEME.accent or Color3.fromRGB(45,42,65)
            b.TextColor3 = s and Color3.fromRGB(255,255,255) or THEME.text_dim
            if cb then pcall(cb, s) end
        end)
        return f
    end

    local function makeSlider(page, y, text, min, max, default, cb)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, -8, 0, 50)
        f.Position = UDim2.new(0, 4, 0, y)
        f.BackgroundColor3 = THEME.panel2
        f.BorderSizePixel = 0
        f.Parent = page
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = f

        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -20, 0, 20)
        l.Position = UDim2.new(0, 12, 0, 4)
        l.BackgroundTransparency = 1
        l.Text = text .. ": " .. default
        l.TextColor3 = THEME.text
        l.TextSize = 12
        l.Font = Enum.Font.Gotham
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = f

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -24, 0, 10)
        bar.Position = UDim2.new(0, 12, 0, 30)
        bar.BackgroundColor3 = Color3.fromRGB(35,32,52)
        bar.BorderSizePixel = 0
        bar.Parent = f
        local bc2 = Instance.new("UICorner"); bc2.CornerRadius = UDim.new(1,0); bc2.Parent = bar

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0)
        fill.BackgroundColor3 = THEME.accent
        fill.BorderSizePixel = 0
        fill.Parent = bar
        local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(1,0); fc.Parent = fill

        local hb = Instance.new("TextButton")
        hb.Size = UDim2.new(1, 0, 0, 30)
        hb.Position = UDim2.new(0, 0, 0, -10)
        hb.BackgroundTransparency = 1
        hb.Text = ""
        hb.AutoButtonColor = false
        hb.Parent = bar

        hb.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                _G.MM2_SLIDER = function(inp)
                    local ax = bar.AbsolutePosition.X
                    local aw = bar.AbsoluteSize.X
                    if aw <= 0 then return end
                    local pos = math.clamp((inp.Position.X - ax) / aw, 0, 1)
                    local v = math.floor(min + (max - min) * pos)
                    fill.Size = UDim2.new(pos, 0, 1, 0)
                    l.Text = text .. ": " .. v
                    if cb then pcall(cb, v) end
                end
                _G.MM2_SLIDER(input)
            end
        end)
        return f
    end

    local function makeButton(page, y, text, cb, color)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -8, 0, 36)
        b.Position = UDim2.new(0, 4, 0, y)
        b.BackgroundColor3 = color or THEME.accent
        b.Text = text
        b.TextColor3 = Color3.fromRGB(255,255,255)
        b.TextSize = 12
        b.Font = Enum.Font.GothamBold
        b.AutoButtonColor = false
        b.Parent = page
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = b
        b.MouseButton1Click:Connect(function() if cb then pcall(cb) end end)
        return b
    end

    -- ESP
    local esp = makeTab("ESP")
    local y = 4
    makeToggle(esp, y, "ESP вкл", CONFIG.ESP, function(s) CONFIG.ESP = s end); y = y + 40
    makeToggle(esp, y, "Боксы", CONFIG.ESP_Box, function(s) CONFIG.ESP_Box = s end); y = y + 40
    makeToggle(esp, y, "Имена", CONFIG.ESP_Name, function(s) CONFIG.ESP_Name = s end); y = y + 40
    makeToggle(esp, y, "Роли", CONFIG.ESP_Role, function(s) CONFIG.ESP_Role = s end); y = y + 40
    makeToggle(esp, y, "Дистанция", CONFIG.ESP_Distance, function(s) CONFIG.ESP_Distance = s end); y = y + 40
    makeToggle(esp, y, "HP", CONFIG.ESP_Health, function(s) CONFIG.ESP_Health = s end); y = y + 40
    makeSlider(esp, y, "Макс дистанция", 100, 5000, CONFIG.MaxDistance, function(v) CONFIG.MaxDistance = v end); y = y + 54

    -- Aimbot
    local aim = makeTab("Aimbot")
    y = 4
    makeToggle(aim, y, "Aimbot", CONFIG.Aimbot, function(s) CONFIG.Aimbot = s end); y = y + 40
    makeToggle(aim, y, "TeamCheck", CONFIG.Aimbot_TeamCheck, function(s) CONFIG.Aimbot_TeamCheck = s end); y = y + 40
    makeSlider(aim, y, "FOV", 10, 500, CONFIG.Aimbot_FOV, function(v) CONFIG.Aimbot_FOV = v end); y = y + 54
    makeSlider(aim, y, "Smooth x100", 1, 100, math.floor(CONFIG.Aimbot_Smooth*100), function(v) CONFIG.Aimbot_Smooth = v/100 end); y = y + 54

    -- Combat
    local cmb = makeTab("Combat")
    y = 4
    makeToggle(cmb, y, "Silent Aim", CONFIG.SilentAim, function(s) CONFIG.SilentAim = s end); y = y + 40
    makeSlider(cmb, y, "Hit %", 1, 100, CONFIG.SilentAim_HitChance, function(v) CONFIG.SilentAim_HitChance = v end); y = y + 54
    makeToggle(cmb, y, "Reach", CONFIG.Reach, function(s) CONFIG.Reach = s end); y = y + 40
    makeSlider(cmb, y, "Reach x10", 50, 300, math.floor(CONFIG.ReachDistance*10), function(v) CONFIG.ReachDistance = v/10 end); y = y + 54
    makeToggle(cmb, y, "Auto-Dodge", CONFIG.AutoDodge, function(s) CONFIG.AutoDodge = s end); y = y + 40
    makeToggle(cmb, y, "Auto-Pickup Gun", CONFIG.AutoPickupGun, function(s) CONFIG.AutoPickupGun = s end); y = y + 40

    -- Farm
    local farm = makeTab("Farm")
    y = 4
    makeToggle(farm, y, "Auto-Farm", CONFIG.AutoFarm, function(s) CONFIG.AutoFarm = s end); y = y + 40
    makeToggle(farm, y, "Auto-Collect", CONFIG.AutoCollect, function(s) CONFIG.AutoCollect = s end); y = y + 40
    makeToggle(farm, y, "Coin Magnet", CONFIG.CoinMagnet, function(s) CONFIG.CoinMagnet = s end); y = y + 40
    makeToggle(farm, y, "Auto-Respawn", CONFIG.AutoRespawn, function(s) CONFIG.AutoRespawn = s end); y = y + 40
    makeSlider(farm, y, "Farm Speed", 1, 20, CONFIG.AutoFarm_Speed, function(v) CONFIG.AutoFarm_Speed = v end); y = y + 54
    makeButton(farm, y, "TP к убийце", function()
        for _, p in ipairs(Players:GetPlayers()) do
            if getRole(p) == "Murderer" then
                local hrp = getHRP(p); local my = getHRP(LocalPlayer)
                if hrp and my then my.CFrame = hrp.CFrame + Vector3.new(0,3,0) end
            end
        end
    end); y = y + 40
    makeButton(farm, y, "TP к пистолету", function()
        for _, o in ipairs(Workspace:GetDescendants()) do
            if o.Name:lower():find("gun") or o.Name:lower():find("revolver") then
                if o:IsA("BasePart") or o:IsA("Tool") then
                    local my = getHRP(LocalPlayer)
                    if my then my.CFrame = CFrame.new(o.Position + Vector3.new(0,3,0)) end
                    break
                end
            end
        end
    end); y = y + 40

    -- Grief
    local grief = makeTab("Grief")
    y = 4
    makeToggle(grief, y, "Fling All", CONFIG.FlingAll, function(s) CONFIG.FlingAll = s end); y = y + 40
    makeToggle(grief, y, "Void Push", CONFIG.VoidPush, function(s) CONFIG.VoidPush = s end); y = y + 40
    makeToggle(grief, y, "Freeze All", CONFIG.FreezeAll, function(s) CONFIG.FreezeAll = s end); y = y + 40
    makeToggle(grief, y, "Ragdoll All", CONFIG.RagdollAll, function(s) CONFIG.RagdollAll = s end); y = y + 40
    makeToggle(grief, y, "Kill All", CONFIG.KillAll, function(s) CONFIG.KillAll = s end); y = y + 40
    makeToggle(grief, y, "Chat Spam", CONFIG.ChatSpam, function(s) CONFIG.ChatSpam = s end); y = y + 40
    makeSlider(grief, y, "Fling Power", 100, 2000, CONFIG.FlingPower, function(v) CONFIG.FlingPower = v end); y = y + 54
    makeSlider(grief, y, "Void Power", 100, 2000, CONFIG.VoidPower, function(v) CONFIG.VoidPower = v end); y = y + 54
    makeButton(grief, y, "🔴 ВСЕХ ЗА КАРТУ", function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then voidPush(p, 500) end
        end
    end, THEME.danger); y = y + 40
    makeButton(grief, y, "☠ KILL ALL", function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local h = getHum(p)
                if h then pcall(function() h.Health = 0 end) end
            end
        end
    end, THEME.danger); y = y + 40

    -- Misc
    local misc = makeTab("Misc")
    y = 4
    makeToggle(misc, y, "Infinite Jump", CONFIG.InfiniteJump, function(s) CONFIG.InfiniteJump = s end); y = y + 40
    makeToggle(misc, y, "NoClip", CONFIG.NoClip, function(s) CONFIG.NoClip = s noclip() end); y = y + 40
    makeToggle(misc, y, "Fly", CONFIG.Fly, function(s) CONFIG.Fly = s fly() end); y = y + 40
    makeToggle(misc, y, "FullBright", CONFIG.FullBright, function(s) CONFIG.FullBright = s fb() end); y = y + 40
    makeToggle(misc, y, "Anti-Fling", CONFIG.AntiFling, function(s) CONFIG.AntiFling = s antiFling() end); y = y + 40
    makeToggle(misc, y, "Hitbox Expand", CONFIG.HitboxExpand, function(s)
        CONFIG.HitboxExpand = s
        if not s then for _, p in ipairs(Players:GetPlayers()) do resetHB(p) end end
    end); y = y + 40
    makeSlider(misc, y, "Hitbox x10", 10, 100, math.floor(CONFIG.HitboxSize*10), function(v) CONFIG.HitboxSize = v/10 end); y = y + 54
    makeSlider(misc, y, "WalkSpeed", 16, 500, CONFIG.WalkSpeed, function(v) CONFIG.WalkSpeed = v; setWS(v) end); y = y + 54
    makeSlider(misc, y, "JumpPower", 50, 500, CONFIG.JumpPower, function(v) CONFIG.JumpPower = v; setJP(v) end); y = y + 54
    makeSlider(misc, y, "FlySpeed", 10, 500, CONFIG.FlySpeed, function(v) CONFIG.FlySpeed = v end); y = y + 54

    -- Stealth
    local st = makeTab("Stealth")
    y = 4
    makeButton(st, y, "🚨 PANIC", function() panic() end, THEME.danger); y = y + 40
    makeButton(st, y, "✅ Un-Panic", function() unpanic() end, THEME.success); y = y + 40

    if tabs[1] then
        tabs[1].BackgroundColor3 = THEME.accent
        tabs[1].TextColor3 = Color3.fromRGB(255,255,255)
        pages[1].Visible = true
    end

    -- открытие/закрытие
    local btnDrag = false
    local btnStart = nil
    local btnStartPos = nil
    local btnMoved = false

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            btnDrag = true
            btnMoved = false
            btnStart = input.Position
            btnStartPos = btn.Position
        end
    end)

    track(UserInputService.InputChanged:Connect(function(input)
        if btnDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - btnStart
            if math.abs(d.X) > 8 or math.abs(d.Y) > 8 then
                btnMoved = true
            end
            btn.Position = UDim2.new(
                btnStartPos.X.Scale, btnStartPos.X.Offset + d.X,
                btnStartPos.Y.Scale, btnStartPos.Y.Offset + d.Y)
        end
    end))

    track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if btnDrag and not btnMoved then
                menu.Visible = not menu.Visible
            end
            btnDrag = false
        end
    end))

    close.MouseButton1Click:Connect(function()
        menu.Visible = false
    end)
end

-- слайдеры (единый обработчик)
track(UserInputService.InputChanged:Connect(function(input)
    if _G.MM2_SLIDER and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        pcall(_G.MM2_SLIDER, input)
    end
end))

track(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        _G.MM2_SLIDER = nil
    end
end))

-- ═══════════════════════════════════════════════════════════
-- ЗАПУСК
-- ═══════════════════════════════════════════════════════════

local ok, err = pcall(function()
    for _, p in ipairs(Players:GetPlayers()) do
        pcall(createESP, p)
    end
    track(Players.PlayerAdded:Connect(function(p) pcall(createESP, p) end))
    track(Players.PlayerRemoving:Connect(function(p)
        pcall(resetHB, p)
        pcall(removeESP, p)
    end))

    buildUI()

    track(RunService.RenderStepped:Connect(function()
        pcall(updateESP)
        pcall(aimbot)
        pcall(infJump)
        pcall(autoCollect)
        pcall(coinMagnet)
        pcall(chatSpam)
        pcall(autoRespawn)
        pcall(autoDodge)
        pcall(autoPickup)
        pcall(reachLoop)
    end))

    task.spawn(function()
        while true do task.wait(0.5); pcall(autoFarm) end
    end)

    task.spawn(griefLoop)

    notify("MM2 v7", "тапни ⚡ чтобы открыть", 5)
end)

if not ok then
    notify("MM2 v7", "ошибка: " .. tostring(err):sub(1, 50), 6)
end
