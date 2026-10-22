-- fast attack

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local FloatingWidget = nil
pcall(function()
    FloatingWidget = (_G.DarlingHub and _G.DarlingHub:Require("modules/pvp/floating_widget.lua"))
end)

local FastAttack = {
    Enabled = false,
    AttackDelay = 0.08,
    AttackRange = 85,
    MaxTargets = 4,
    Widget = nil,
    HeartbeatConnection = nil,
    KeyConnection = nil,
    ToolConnections = {},
    LastAttackTime = 0,
    LastRemoteCheck = 0,
}

local RegisterHit = nil
local RegisterAttack = nil

local function resolveAttackRemotes()
    if RegisterHit and RegisterAttack then return true end
    local now = os.clock()
    if now - FastAttack.LastRemoteCheck < 1 then return false end
    FastAttack.LastRemoteCheck = now

    pcall(function()
        local net = (ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Net"))
            or ReplicatedStorage:FindFirstChild("Net")
        if net then
            RegisterHit = net:FindFirstChild("RE/RegisterHit") or net:FindFirstChild("RegisterHit")
            RegisterAttack = net:FindFirstChild("RE/RegisterAttack") or net:FindFirstChild("RegisterAttack")
        end
        if not (RegisterHit and RegisterAttack) then
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes then
                RegisterHit = RegisterHit or remotes:FindFirstChild("RE/RegisterHit") or remotes:FindFirstChild("RegisterHit")
                RegisterAttack = RegisterAttack or remotes:FindFirstChild("RE/RegisterAttack") or remotes:FindFirstChild("RegisterAttack")
            end
        end
        if not (RegisterHit and RegisterAttack) then
            local common = ReplicatedStorage:FindFirstChild("Common")
            if common then
                RegisterHit = RegisterHit or common:FindFirstChild("RE/RegisterHit") or common:FindFirstChild("RegisterHit")
                RegisterAttack = RegisterAttack or common:FindFirstChild("RE/RegisterAttack") or common:FindFirstChild("RegisterAttack")
            end
        end
        if not (RegisterHit and RegisterAttack) then
            RegisterHit = RegisterHit or ReplicatedStorage:FindFirstChild("RE/RegisterHit") or ReplicatedStorage:FindFirstChild("RegisterHit")
            RegisterAttack = RegisterAttack or ReplicatedStorage:FindFirstChild("RE/RegisterAttack") or ReplicatedStorage:FindFirstChild("RegisterAttack")
        end
    end)
    return (RegisterHit ~= nil and RegisterAttack ~= nil)
end

local function executeFastAttackBurst()
    if not FastAttack.Enabled then return end
    local now = os.clock()
    if now - FastAttack.LastAttackTime < FastAttack.AttackDelay then return end
    FastAttack.LastAttackTime = now

    local myChar = LocalPlayer.Character
    local myHRP = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar.PrimaryPart)
    if not myHRP then return end

    local currentTool = myChar:FindFirstChildOfClass("Tool")
    if not currentTool or currentTool.ToolTip == "Gun" then return end

    local isCasting = myChar:GetAttribute("isUsingSkill") or myChar:GetAttribute("UsingSkill") or myChar:GetAttribute("Busy")
    if isCasting == true then return end

    pcall(function()
        currentTool:SetAttribute("LocalOverheat", 0)
        currentTool:SetAttribute("Cooldown", 0)
    end)

    local myPos = myHRP.Position
    local hitList = {}

    local function checkEnemy(model)
        if not model or model == myChar then return end
        local hum = model:FindFirstChildOfClass("Humanoid")
        local hrp = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
        local head = model:FindFirstChild("Head") or hrp
        if hum and hum.Health > 0 and hrp and head and (hrp.Position - myPos).Magnitude <= FastAttack.AttackRange then
            table.insert(hitList, { model, head })
        end
    end

    local enemies = Workspace:FindFirstChild("Enemies")
    if enemies then
        for _, npc in ipairs(enemies:GetChildren()) do
            checkEnemy(npc)
            if #hitList >= FastAttack.MaxTargets then break end
        end
    end

    local chars = Workspace:FindFirstChild("Characters")
    if chars and #hitList < FastAttack.MaxTargets then
        for _, c in ipairs(chars:GetChildren()) do
            checkEnemy(c)
            if #hitList >= FastAttack.MaxTargets then break end
        end
    end

    if #hitList < FastAttack.MaxTargets then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                checkEnemy(p.Character)
                if #hitList >= FastAttack.MaxTargets then break end
            end
        end
    end

    if #hitList > 0 then
        local primaryPart = hitList[1][2]
        local myLook = myHRP.CFrame.LookVector
        pcall(function()
            if currentTool:FindFirstChild("LeftClickRemote") then
                currentTool.LeftClickRemote:FireServer(myLook, 1)
            end
            if resolveAttackRemotes() then
                RegisterAttack:FireServer(0)
                RegisterHit:FireServer(primaryPart, hitList)
            end
        end)
    end
end

local hookedTools = {}

local function unhookTool(tool)
    local conn = hookedTools[tool]
    if conn then
        pcall(function() conn:Disconnect() end)
        hookedTools[tool] = nil
    end
end

local function hookTool(tool)
    if tool and tool:IsA("Tool") and tool.ToolTip ~= "Gun" then
        if hookedTools[tool] then return end
        local conn = tool.Activated:Connect(function()
            if FastAttack.Enabled then executeFastAttackBurst() end
        end)
        hookedTools[tool] = conn
        table.insert(FastAttack.ToolConnections, conn)

        local unequipConn
        unequipConn = tool.Unequipped:Connect(function()
            if unequipConn then
                pcall(function() unequipConn:Disconnect() end)
            end
            unhookTool(tool)
        end)
        table.insert(FastAttack.ToolConnections, unequipConn)
    end
end

local function hookCharacter(char)
    if not char then return end
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") then hookTool(item) end
    end
    local childAddedConn = char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then hookTool(child) end
    end)
    table.insert(FastAttack.ToolConnections, childAddedConn)
end

function FastAttack.enable()
    if FastAttack.Enabled then return end
    FastAttack.Enabled = true
    resolveAttackRemotes()

    if not FastAttack.HeartbeatConnection then
        FastAttack.HeartbeatConnection = RunService.Heartbeat:Connect(executeFastAttackBurst)
    end

    if LocalPlayer.Character then hookCharacter(LocalPlayer.Character) end

    if not FastAttack.KeyConnection then
        FastAttack.KeyConnection = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.RightControl then
                FastAttack.toggle()
            end
        end)
    end

    if not FastAttack.Widget and FloatingWidget then
        FastAttack.Widget = FloatingWidget.create({
            Id = "FastAttackFruitsWidget",
            Label = "ATK",
            Type = "Toggle",
            Default = true,
            Position = UDim2.new(0.35, 0, 0.34, 0),
            AccentColor = Color3.fromRGB(34, 197, 94),
            Callback = function(state)
                if state then
                    FastAttack.enable()
                else
                    FastAttack.disable()
                end
            end
        })
    elseif FastAttack.Widget then
        FastAttack.Widget:Set(true, true)
        FastAttack.Widget:SetVisible(true)
    end
end

function FastAttack.disable()
    FastAttack.Enabled = false
    if FastAttack.HeartbeatConnection then
        pcall(function() FastAttack.HeartbeatConnection:Disconnect() end)
        FastAttack.HeartbeatConnection = nil
    end
    for _, conn in ipairs(FastAttack.ToolConnections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(FastAttack.ToolConnections)
    for tool, conn in pairs(hookedTools) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(hookedTools)
    if FastAttack.Widget then
        FastAttack.Widget:Set(false, true)
        FastAttack.Widget:SetVisible(false)
    end
end

function FastAttack.toggle()
    if FastAttack.Enabled then
        FastAttack.disable()
    else
        FastAttack.enable()
    end
    return FastAttack.Enabled
end

function FastAttack.setFloatingVisible(visible)
    if FastAttack.Widget then
        FastAttack.Widget:SetVisible(visible)
    end
end

function FastAttack.destroy()
    FastAttack.disable()
    if FastAttack.KeyConnection then
        pcall(function() FastAttack.KeyConnection:Disconnect() end)
        FastAttack.KeyConnection = nil
    end
    if FastAttack.Widget then
        pcall(function() FastAttack.Widget:Destroy() end)
        FastAttack.Widget = nil
    end
end

function FastAttack.getDiagnostics()
    local connCount = 0
    if FastAttack.HeartbeatConnection then connCount = connCount + 1 end
    if FastAttack.KeyConnection then connCount = connCount + 1 end
    connCount = connCount + #FastAttack.ToolConnections
    return {
        Connections = connCount,
        Threads = 0,
        Active = FastAttack.Enabled,
    }
end

return FastAttack
