-- dragon gun

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local FloatingWidget = nil
pcall(function()
    FloatingWidget = (_G.DarlingHub and _G.DarlingHub:Require("modules/pvp/floating_widget.lua"))
end)

local DragonGun = {
    Enabled = false,
    AttackMobs = true,
    AttackPlayers = true,
    AttackSeaEvents = true,
    MaxDistance = 400,
    ShotsPerFrame = 3,
    Keybind = Enum.KeyCode.G,
    Widget = nil,
    RenderConnection = nil,
    InputConnection = nil,
}

local getupval = debug.getupvalue or getupvalue
local setupval = debug.setupvalue or setupvalue
local getupvals = debug.getupvalues or getupvalues

local ShootFunction = nil
local V_Idx = { v26 = 12, v22 = 13, v25 = 14, v21 = 15, v23 = 16, v24 = 17, v27 = 18 }

local ShootGunEvent = nil
local Validator2 = nil

local function resolveRemotes()
    if ShootGunEvent and Validator2 then return true end
    pcall(function()
        local modules = ReplicatedStorage:FindFirstChild("Modules")
        local net = (modules and modules:FindFirstChild("Net")) or ReplicatedStorage:FindFirstChild("Net")
        if net then
            ShootGunEvent = net:FindFirstChild("RE/ShootGunEvent") or net:FindFirstChild("ShootGunEvent")
        end
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            ShootGunEvent = ShootGunEvent or remotes:FindFirstChild("RE/ShootGunEvent") or remotes:FindFirstChild("ShootGunEvent")
            Validator2 = remotes:FindFirstChild("Validator2") or remotes:FindFirstChild("Validator")
        end
    end)
    return (ShootGunEvent ~= nil)
end

local function InitDragonGun()
    if ShootFunction then return end
    pcall(function()
        local controllers = ReplicatedStorage:FindFirstChild("Controllers")
        local combatCtrl = controllers and controllers:FindFirstChild("CombatController")
        if combatCtrl and getupval then
            local success, result = pcall(require, combatCtrl)
            if success and type(result) == "table" and result.Attack then
                ShootFunction = getupval(result.Attack, 9)
            end
        end
    end)
end

local function GetNextValidator()
    if not ShootFunction then InitDragonGun() end
    if not (ShootFunction and getupvals and getupval and setupval) then return 0, 0 end

    local upvals = getupvals(ShootFunction)
    if not upvals then return 0, 0 end

    if upvals[V_Idx.v21] ~= 727595 then
        for i, v in pairs(upvals) do
            if v == 727595 then
                local offset = i - 15
                V_Idx.v21 = i
                V_Idx.v22 = 13 + offset
                V_Idx.v23 = 16 + offset
                V_Idx.v24 = 17 + offset
                V_Idx.v26 = 12 + offset
                V_Idx.v25 = 14 + offset
                V_Idx.v27 = 18 + offset
                break
            end
        end
    end

    local v1 = getupval(ShootFunction, V_Idx.v21)
    local v2 = getupval(ShootFunction, V_Idx.v22)
    local v3 = getupval(ShootFunction, V_Idx.v23)
    local v4 = getupval(ShootFunction, V_Idx.v24)
    local v5 = getupval(ShootFunction, V_Idx.v25)
    local v6 = getupval(ShootFunction, V_Idx.v26)
    local v7 = getupval(ShootFunction, V_Idx.v27)

    if not (v1 and v2 and v3 and v4 and v5 and v6 and v7) then return 0, 0 end

    local v8 = v6 * v2
    local v9 = (v5 * v2 + v6 * v1) % v3
    v9 = (v9 * v3 + v8) % v4
    v5 = math.floor(v9 / v3)
    v6 = v9 - v5 * v3
    v7 = v7 + 1

    setupval(ShootFunction, V_Idx.v25, v5)
    setupval(ShootFunction, V_Idx.v26, v6)
    setupval(ShootFunction, V_Idx.v27, v7)
    return math.floor(v9 / v4 * 16777215), v7
end

local function GetEntityPart(entity)
    return entity:FindFirstChild("HumanoidRootPart")
        or entity:FindFirstChild("Engine")
        or entity:FindFirstChild("Head")
        or entity:FindFirstChild("Base")
        or entity.PrimaryPart
end

local enemiesCandidates = {}
local seaCandidates = {}
local workspaceSeaCandidates = {}
local candidateConns = {}

local function isSeaModel(obj)
    if not (obj and obj:IsA("Model")) then return false end
    local name = obj.Name:lower()
    return (name:find("ship") or name:find("boat") or name:find("beast") or name:find("terror") or name:find("piranha") or name:find("leviathan")) ~= nil
end

local function clearCandidateListeners()
    for _, c in ipairs(candidateConns) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(candidateConns)
    table.clear(enemiesCandidates)
    table.clear(seaCandidates)
    table.clear(workspaceSeaCandidates)
end

local function setupCandidateListeners()
    clearCandidateListeners()

    local enemies = Workspace:FindFirstChild("Enemies")
    if enemies then
        for _, e in ipairs(enemies:GetChildren()) do
            table.insert(enemiesCandidates, e)
        end
        table.insert(candidateConns, enemies.ChildAdded:Connect(function(c)
            table.insert(enemiesCandidates, c)
        end))
        table.insert(candidateConns, enemies.ChildRemoved:Connect(function(c)
            local idx = table.find(enemiesCandidates, c)
            if idx then table.remove(enemiesCandidates, idx) end
        end))
    end

    local seaFolders = { Workspace:FindFirstChild("SeaBeasts"), Workspace:FindFirstChild("SeaEvents") }
    for _, folder in ipairs(seaFolders) do
        if folder then
            for _, m in ipairs(folder:GetChildren()) do
                table.insert(seaCandidates, m)
            end
            table.insert(candidateConns, folder.ChildAdded:Connect(function(c)
                table.insert(seaCandidates, c)
            end))
            table.insert(candidateConns, folder.ChildRemoved:Connect(function(c)
                local idx = table.find(seaCandidates, c)
                if idx then table.remove(seaCandidates, idx) end
            end))
        end
    end

    for _, obj in ipairs(Workspace:GetChildren()) do
        if isSeaModel(obj) then
            table.insert(workspaceSeaCandidates, obj)
        end
    end
    table.insert(candidateConns, Workspace.ChildAdded:Connect(function(c)
        if isSeaModel(c) then
            table.insert(workspaceSeaCandidates, c)
        end
    end))
    table.insert(candidateConns, Workspace.ChildRemoved:Connect(function(c)
        local idx = table.find(workspaceSeaCandidates, c)
        if idx then table.remove(workspaceSeaCandidates, idx) end
    end))
end

local function GetClosestTarget()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local closest, dist = nil, DragonGun.MaxDistance
    local myPos = root.Position

    if DragonGun.AttackMobs then
        for i = #enemiesCandidates, 1, -1 do
            local enemy = enemiesCandidates[i]
            if enemy and enemy.Parent then
                local hum = enemy:FindFirstChildOfClass("Humanoid")
                local r = GetEntityPart(enemy)
                if hum and hum.Health > 0 and r then
                    local d = (r.Position - myPos).Magnitude
                    if d < dist then dist = d; closest = r end
                end
            else
                table.remove(enemiesCandidates, i)
            end
        end
    end

    if DragonGun.AttackSeaEvents then
        for i = #seaCandidates, 1, -1 do
            local seaMob = seaCandidates[i]
            if seaMob and seaMob.Parent then
                local hum = seaMob:FindFirstChildOfClass("Humanoid")
                local r = GetEntityPart(seaMob)
                if r and (not hum or hum.Health > 0) then
                    local d = (r.Position - myPos).Magnitude
                    if d < dist then dist = d; closest = r end
                end
            else
                table.remove(seaCandidates, i)
            end
        end

        for i = #workspaceSeaCandidates, 1, -1 do
            local obj = workspaceSeaCandidates[i]
            if obj and obj.Parent and obj ~= char then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                local r = GetEntityPart(obj)
                if r and (not hum or hum.Health > 0) then
                    local d = (r.Position - myPos).Magnitude
                    if d < dist then dist = d; closest = r end
                end
            else
                table.remove(workspaceSeaCandidates, i)
            end
        end
    end

    if DragonGun.AttackPlayers then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                local r = player.Character:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and r then
                    local d = (r.Position - myPos).Magnitude
                    if d < dist then dist = d; closest = r end
                end
            end
        end
    end

    return closest
end

local function onRenderStep()
    if not DragonGun.Enabled then return end

    local char = LocalPlayer.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if not (tool and tool.ToolTip == "Gun") then return end

    local target = GetClosestTarget()
    if not target then return end

    resolveRemotes()
    if not ShootGunEvent then return end

    for _ = 1, math.clamp(DragonGun.ShotsPerFrame, 1, 5) do
        local code, count = GetNextValidator()
        if code ~= 0 and Validator2 then
            pcall(function() Validator2:FireServer(code, count) end)
        end

        pcall(function()
            tool:SetAttribute("LocalOverheat", 0)
            local currentTotal = tool:GetAttribute("LocalTotalShots") or 0
            tool:SetAttribute("LocalTotalShots", currentTotal + 1)
            ShootGunEvent:FireServer(target.Position, { target })
        end)
    end
end

function DragonGun.enable()
    if DragonGun.Enabled then return end
    DragonGun.Enabled = true
    resolveRemotes()
    InitDragonGun()
    setupCandidateListeners()

    if not DragonGun.RenderConnection then
        DragonGun.RenderConnection = RunService.RenderStepped:Connect(onRenderStep)
    end

    if not DragonGun.InputConnection then
        DragonGun.InputConnection = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == DragonGun.Keybind then
                DragonGun.toggle()
            end
        end)
    end

    if not DragonGun.Widget and FloatingWidget then
        DragonGun.Widget = FloatingWidget.create({
            Id = "DragonStormAuraWidget",
            Label = "GUN",
            Type = "Toggle",
            Default = true,
            Position = UDim2.new(0.35, 0, 0.28, 0),
            AccentColor = Color3.fromRGB(245, 158, 11),
            Callback = function(state)
                if state then
                    DragonGun.enable()
                else
                    DragonGun.disable()
                end
            end
        })
    elseif DragonGun.Widget then
        DragonGun.Widget:Set(true, true)
        DragonGun.Widget:SetVisible(true)
    end
end

function DragonGun.disable()
    DragonGun.Enabled = false
    clearCandidateListeners()
    if DragonGun.RenderConnection then
        pcall(function() DragonGun.RenderConnection:Disconnect() end)
        DragonGun.RenderConnection = nil
    end
    if DragonGun.Widget then
        DragonGun.Widget:Set(false, true)
        DragonGun.Widget:SetVisible(false)
    end
end

function DragonGun.toggle()
    if DragonGun.Enabled then
        DragonGun.disable()
    else
        DragonGun.enable()
    end
    return DragonGun.Enabled
end

function DragonGun.setFloatingVisible(visible)
    if DragonGun.Widget then
        DragonGun.Widget:SetVisible(visible)
    end
end

function DragonGun.destroy()
    DragonGun.disable()
    if DragonGun.InputConnection then
        pcall(function() DragonGun.InputConnection:Disconnect() end)
        DragonGun.InputConnection = nil
    end
    if DragonGun.Widget then
        pcall(function() DragonGun.Widget:Destroy() end)
        DragonGun.Widget = nil
    end
end

function DragonGun.getDiagnostics()
    local connCount = 0
    if DragonGun.RenderConnection then connCount = connCount + 1 end
    if DragonGun.InputConnection then connCount = connCount + 1 end
    connCount = connCount + #candidateConns
    return {
        Connections = connCount,
        Threads = 0,
        Active = DragonGun.Enabled,
    }
end

return DragonGun
