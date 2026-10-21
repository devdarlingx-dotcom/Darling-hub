--[[
    Darling Hub - Combat Core (Blox Fruits)
    Shared combat context, targeting resolution, prediction, and network hooks.
]]--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Core = {
    -- Toggles
    PlayerAimEnabled = false,
    NPCAimEnabled = false,

    -- Settings
    AimMode = "360", -- "360", "180", "FOV"
    TargetPriority = "Nearest", -- "Nearest", "Low HP", "Looking At Me", "Lock Player"
    SelectedPlayer = nil,
    TargetHitbox = "Head",
    MaxRange = 1000,
    PredictionEnabled = true,
    PredictionAmount = 0.12,

    -- FOV Settings
    FOV = {
        Visible = false,
        Radius = 100,
        Mode = "Center", -- "Center", "Mouse"
        Color = Color3.fromRGB(255, 60, 60),
        Thickness = 1.5,
    },

    -- Tracer Settings
    Tracers = {
        Visible = false,
        Color = Color3.fromRGB(255, 50, 50),
        Thickness = 1.5,
    },

    -- Resolved Targets
    CurrentTargetPosition = nil,
    CurrentTargetPart = nil,
    CurrentTargetCharacter = nil,
    CurrentTargetIsPlayer = false,

    -- Tool & Skill Tracking
    CurrentTool = nil,
    CurrentToolCategory = "Melee",
    CurrentSkillKey = nil,
    LastSkillTime = 0,

    -- Skill Blacklist
    BlacklistedKeys = {
        Melee = { Z = false, X = false, C = false },
        Sword = { Z = false, X = false },
        Fruit = { Z = false, X = false, C = false, V = false, F = false, TAP = false },
        Gun   = { Z = false, X = false },
    },

    -- Internal state
    IsHooked = false,
    RenderConnection = nil,
    CharConnections = {},
    LastVelocity = nil,
    LastDirection = nil,
}

local SKILL_KEYS = { "Z", "X", "C", "V", "F", "TAP" }

-- ============================================================================
-- TOOL CATEGORIZATION
-- ============================================================================
function Core.getToolCategory(tool)
    if not tool then return "Melee" end
    local name = string.lower(tool.Name)

    local gunNames = { "guitar", "rifle", "cannon", "gun", "slingshot", "kabucha", "serpent bow", "bow" }
    for _, g in ipairs(gunNames) do
        if string.find(name, g) then return "Gun" end
    end

    local meleeNames = { "claw", "godhuman", "superhuman", "talon", "step", "karate", "breath", "kung fu", "combat", "fist", "sanguine" }
    for _, m in ipairs(meleeNames) do
        if string.find(name, m) then return "Melee" end
    end

    if string.find(name, "fruit") or string.find(name, "-") then
        return "Fruit"
    end

    return "Sword"
end

function Core.isKeyBlacklisted(category, key)
    if not category or not key then return false end
    if Core.BlacklistedKeys[category] and Core.BlacklistedKeys[category][key] ~= nil then
        return Core.BlacklistedKeys[category][key]
    end
    return false
end

-- ============================================================================
-- TARGET VALIDATION & BLOX FRUITS ENVIRONMENT CHECKS
-- ============================================================================
local function isAlly(targetPlayer)
    if not targetPlayer or targetPlayer == LocalPlayer then return false end
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not pGui then return false end

    local main = pGui:FindFirstChild("Main")
    local allies = main and main:FindFirstChild("Allies")
    local container = allies and allies:FindFirstChild("Container")
    local alliesList = container and container:FindFirstChild("Allies")
    local scroll = alliesList and alliesList:FindFirstChild("ScrollingFrame")
    if not scroll then return false end

    for _, frame in ipairs(scroll:GetDescendants()) do
        if frame:IsA("ImageButton") and frame.Name == targetPlayer.Name then
            return true
        end
    end
    return false
end

local function isProtected(character, targetPlayer)
    if not character then return true end

    -- SafeZone or Combat Protection attributes
    if character:GetAttribute("SafeZone") == true
        or character:GetAttribute("PvpDisabled") == true
        or character:GetAttribute("CombatProtected") == true
        or character:GetAttribute("PVP") == false then
        return true
    end

    if targetPlayer then
        if targetPlayer:GetAttribute("SafeZone") == true
            or targetPlayer:GetAttribute("PvpDisabled") == true
            or targetPlayer:GetAttribute("CombatProtected") == true then
            return true
        end
    end

    -- Protection objects
    if character:FindFirstChild("SafeZone")
        or character:FindFirstChild("CombatPD")
        or character:FindFirstChild("PvpDisabled")
        or character:FindFirstChildWhichIsA("ForceField") then
        return true
    end

    return false
end

local function isEnemyPlayer(targetPlayer)
    if not targetPlayer or targetPlayer == LocalPlayer then return false end
    if not targetPlayer.Character then return false end
    if isProtected(targetPlayer.Character, targetPlayer) then return false end
    if isAlly(targetPlayer) then return false end

    local myTeam = LocalPlayer.Team
    local theirTeam = targetPlayer.Team
    if myTeam and theirTeam then
        if myTeam.Name == "Marines" and theirTeam.Name == "Marines" then
            return false
        end
    end

    return true
end

local function getHRP(model)
    if model and model:FindFirstChild("HumanoidRootPart") then
        return model.HumanoidRootPart
    end
    return nil
end

local function getTargetPart(character)
    if not character then return nil end
    local requested = Core.TargetHitbox
    local part = character:FindFirstChild(requested)
    if part and part:IsA("BasePart") then
        return part
    end
    return getHRP(character) or character:FindFirstChildWhichIsA("BasePart")
end

-- ============================================================================
-- FOV & ANGLE VALIDATION
-- ============================================================================
function Core.getFOVCenter()
    Camera = Workspace.CurrentCamera or Camera
    if Core.FOV.Mode == "Mouse" then
        return UserInputService:GetMouseLocation()
    end
    return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

local function isTargetInFOV(worldPos)
    Camera = Workspace.CurrentCamera or Camera
    local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)
    if not onScreen then return false end

    local center = Core.getFOVCenter()
    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
    return dist <= Core.FOV.Radius
end

local function isAngleValid(targetHRP, lpHRP)
    if Core.AimMode == "360" then
        return true
    elseif Core.AimMode == "180" then
        local dir = (targetHRP.Position - lpHRP.Position).Unit
        return lpHRP.CFrame.LookVector:Dot(dir) >= 0
    elseif Core.AimMode == "FOV" then
        return isTargetInFOV(targetHRP.Position)
    end
    return true
end

-- ============================================================================
-- PREDICTION ENGINE
-- ============================================================================
function Core.predictPosition(targetPart)
    if not targetPart then return nil end
    local character = targetPart.Parent
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return targetPart.Position
    end

    if not Core.PredictionEnabled then
        return targetPart.Position
    end

    local hrp = character:FindFirstChild("HumanoidRootPart") or targetPart
    local vel = hrp.Velocity
    local speed = vel.Magnitude

    if speed < 4 then
        Core.LastVelocity = nil
        Core.LastDirection = nil
        return targetPart.Position
    end

    local currentDir = vel.Unit
    if Core.LastDirection then
        local dot = Core.LastDirection:Dot(currentDir)
        if dot < 0.65 then
            -- Abrupt direction change, skip prediction overshoot
            Core.LastVelocity = nil
            Core.LastDirection = nil
            return targetPart.Position
        end
    end

    Core.LastDirection = currentDir
    Core.LastVelocity = vel

    local ping = 0
    pcall(function()
        local serverStats = Stats.Network:FindFirstChild("ServerStatsItem")
        if serverStats and serverStats:FindFirstChild("Data Ping") then
            ping = serverStats["Data Ping"]:GetValue() / 1000
        end
    end)
    ping = math.clamp(ping, 0, 0.3)

    local factor = Core.PredictionAmount + ping
    if speed > 110 then
        factor = math.min(factor, 0.14)
    end

    return targetPart.Position + (vel * factor)
end

-- ============================================================================
-- TARGET SELECTION
-- ============================================================================
local function resolvePlayerTarget(lpHRP)
    if not lpHRP then return nil, nil end

    if Core.TargetPriority == "Lock Player" then
        if Core.SelectedPlayer and Core.SelectedPlayer.Character then
            local pl = Core.SelectedPlayer
            local char = pl.Character
            if not isProtected(char, pl) then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local hrp = getHRP(char)
                if hum and hum.Health > 0 and hrp and isAngleValid(hrp, lpHRP) then
                    local dist = (hrp.Position - lpHRP.Position).Magnitude
                    if dist <= Core.MaxRange then
                        local part = getTargetPart(char)
                        return part, Core.predictPosition(part)
                    end
                end
            end
        end
        return nil, nil
    end

    local candidates = {}
    for _, pl in ipairs(Players:GetPlayers()) do
        if isEnemyPlayer(pl) and pl.Character then
            local char = pl.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = getHRP(char)
            if hum and hum.Health > 0 and hrp and isAngleValid(hrp, lpHRP) then
                local dist = (hrp.Position - lpHRP.Position).Magnitude
                if dist <= Core.MaxRange then
                    table.insert(candidates, {
                        Player = pl,
                        Character = char,
                        Humanoid = hum,
                        HRP = hrp,
                        Distance = dist,
                    })
                end
            end
        end
    end

    if #candidates == 0 then return nil, nil end

    if Core.AimMode == "FOV" then
        local center = Core.getFOVCenter()
        table.sort(candidates, function(a, b)
            local pA = Camera:WorldToViewportPoint(a.HRP.Position)
            local pB = Camera:WorldToViewportPoint(b.HRP.Position)
            local dA = (Vector2.new(pA.X, pA.Y) - center).Magnitude
            local dB = (Vector2.new(pB.X, pB.Y) - center).Magnitude
            return dA < dB
        end)
    else
        if Core.TargetPriority == "Nearest" then
            table.sort(candidates, function(a, b) return a.Distance < b.Distance end)
        elseif Core.TargetPriority == "Low HP" then
            table.sort(candidates, function(a, b) return a.Humanoid.Health < b.Humanoid.Health end)
        elseif Core.TargetPriority == "Looking At Me" then
            table.sort(candidates, function(a, b)
                local dirA = (lpHRP.Position - a.HRP.Position).Unit
                local lookA = a.HRP.CFrame.LookVector
                local dirB = (lpHRP.Position - b.HRP.Position).Unit
                local lookB = b.HRP.CFrame.LookVector
                return lookA:Dot(dirA) > lookB:Dot(dirB)
            end)
        end
    end

    local chosen = candidates[1]
    local part = getTargetPart(chosen.Character)
    return part, Core.predictPosition(part), chosen.Character
end

local function resolveNPCTarget(lpHRP)
    if not lpHRP then return nil, nil end
    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    if not enemiesFolder then return nil, nil end

    local closestPart = nil
    local closestPredicted = nil
    local closestChar = nil
    local shortestDist = math.huge

    for _, npc in ipairs(enemiesFolder:GetChildren()) do
        if npc:IsA("Model") then
            local hum = npc:FindFirstChildOfClass("Humanoid")
            local hrp = getHRP(npc)
            if hum and hum.Health > 0 and hrp and isAngleValid(hrp, lpHRP) then
                local dist = (hrp.Position - lpHRP.Position).Magnitude
                if dist <= Core.MaxRange and dist < shortestDist then
                    local part = getTargetPart(npc)
                    closestPart = part
                    closestPredicted = Core.predictPosition(part)
                    closestChar = npc
                    shortestDist = dist
                end
            end
        end
    end

    return closestPart, closestPredicted, closestChar
end

-- ============================================================================
-- ROTATION TOWARDS TARGET
-- ============================================================================
function Core.faceTarget(targetPos)
    if not targetPos then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local currentPos = hrp.Position
    local look = (Vector3.new(targetPos.X, currentPos.Y, targetPos.Z) - currentPos).Unit
    if look.Magnitude < 0.001 then return end

    hrp.CFrame = CFrame.lookAt(currentPos, currentPos + look, Vector3.new(0, 1, 0))
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.AutoRotate = true end
end

-- ============================================================================
-- SKILL TRACKING
-- ============================================================================
function Core.setCurrentSkillKey(key)
    Core.CurrentSkillKey = key
    Core.LastSkillTime = os.clock()

    if Core.PlayerAimEnabled or Core.NPCAimEnabled then
        if Core.CurrentTargetPosition then
            task.spawn(function() Core.faceTarget(Core.CurrentTargetPosition) end)
        end
    end

    task.spawn(function()
        local capturedTime = Core.LastSkillTime
        task.wait(1.5)
        if Core.LastSkillTime == capturedTime and Core.CurrentSkillKey == key then
            Core.CurrentSkillKey = nil
        end
    end)
end

local function getSkillKeyFromArgs(args)
    for _, arg in ipairs(args) do
        if type(arg) == "string" and table.find(SKILL_KEYS, arg) then
            return arg
        end
    end
    return nil
end

-- ============================================================================
-- METATABLE REDIRECTION HOOK (BLOODLINE OF RJR + NAMELESS)
-- ============================================================================
function Core.installMetatableHook()
    if Core.IsHooked then return end
    Core.IsHooked = true

    local rawMt = getrawmetatable(game)
    if not rawMt then return end

    local oldNamecall = rawMt.__namecall
    setreadonly(rawMt, false)

    rawMt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = { ... }

        if args[1] == "TAP" then
            return oldNamecall(self, ...)
        end

        local skillKey = getSkillKeyFromArgs(args)
        if skillKey then
            Core.setCurrentSkillKey(skillKey)
        end

        -- Check blacklist
        local activeKey = skillKey or Core.CurrentSkillKey
        local isBlacklisted = false
        if activeKey and Core.isKeyBlacklisted(Core.CurrentToolCategory, activeKey) then
            isBlacklisted = true
        end

        if not isBlacklisted and (Core.PlayerAimEnabled or Core.NPCAimEnabled) and Core.CurrentTargetPosition then
            local targetPos = Core.CurrentTargetPosition

            if method == "FireServer" then
                local sName = tostring(self)
                if sName == "RemoteEvent" or sName == "CommE" or sName == "RigidBodyEvent" or typeof(args[1]) == "Vector3" then
                    for i, v in ipairs(args) do
                        if typeof(v) == "Vector3" then
                            args[i] = targetPos
                        end
                    end
                end
            elseif method == "InvokeServer" then
                local sName = tostring(self)
                if sName == "RemoteFunction" or sName == "CommF_" then
                    for i, v in ipairs(args) do
                        if typeof(v) == "Vector3" then
                            args[i] = targetPos
                        end
                    end
                end
            end
        end

        return oldNamecall(self, unpack(args))
    end)

    setreadonly(rawMt, true)
end

-- ============================================================================
-- RENDER LOOP (TARGET UPDATES)
-- ============================================================================
local function updateTargetCycle()
    Camera = Workspace.CurrentCamera or Camera
    local char = LocalPlayer.Character
    local lpHRP = char and char:FindFirstChild("HumanoidRootPart")

    if not lpHRP or (not Core.PlayerAimEnabled and not Core.NPCAimEnabled) then
        Core.CurrentTargetPosition = nil
        Core.CurrentTargetPart = nil
        Core.CurrentTargetCharacter = nil
        return
    end

    local targetPart, predictedPos, targetChar = nil, nil, nil

    if Core.PlayerAimEnabled then
        targetPart, predictedPos, targetChar = resolvePlayerTarget(lpHRP)
        if targetPart then
            Core.CurrentTargetIsPlayer = true
        end
    end

    if not targetPart and Core.NPCAimEnabled then
        targetPart, predictedPos, targetChar = resolveNPCTarget(lpHRP)
        if targetPart then
            Core.CurrentTargetIsPlayer = false
        end
    end

    Core.CurrentTargetPart = targetPart
    Core.CurrentTargetPosition = predictedPos
    Core.CurrentTargetCharacter = targetChar
end

function Core.startLoop()
    if Core.RenderConnection then return end
    Core.installMetatableHook()
    Core.RenderConnection = RunService.RenderStepped:Connect(updateTargetCycle)
end

function Core.stopLoop()
    if Core.PlayerAimEnabled or Core.NPCAimEnabled then return end
    if Core.RenderConnection then
        Core.RenderConnection:Disconnect()
        Core.RenderConnection = nil
    end
    Core.CurrentTargetPosition = nil
    Core.CurrentTargetPart = nil
    Core.CurrentTargetCharacter = nil
end

-- ============================================================================
-- INPUT AND CHARACTER HOOKS
-- ============================================================================
local function hookMobileButton(btn)
    if btn:GetAttribute("DarlingHooked") then return end
    btn:SetAttribute("DarlingHooked", true)
    local key = btn.Name
    if table.find(SKILL_KEYS, key) then
        btn.Activated:Connect(function()
            Core.setCurrentSkillKey(key)
        end)
    end
end

local function setupCharacter(char)
    for _, c in ipairs(Core.CharConnections) do
        pcall(function() c:Disconnect() end)
    end
    Core.CharConnections = {}

    local function checkTool(child)
        if child:IsA("Tool") then
            Core.CurrentTool = child
            Core.CurrentToolCategory = Core.getToolCategory(child)
            Core.CurrentSkillKey = nil
            table.insert(Core.CharConnections, child.AncestryChanged:Connect(function(_, parent)
                if not parent then Core.CurrentTool = nil end
            end))
        end
    end

    for _, child in ipairs(char:GetChildren()) do checkTool(child) end
    table.insert(Core.CharConnections, char.ChildAdded:Connect(checkTool))
    table.insert(Core.CharConnections, char.ChildRemoved:Connect(function(child)
        if child == Core.CurrentTool then Core.CurrentTool = nil end
    end))
end

LocalPlayer.CharacterAdded:Connect(setupCharacter)
if LocalPlayer.Character then setupCharacter(LocalPlayer.Character) end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    local keyMap = {
        [Enum.KeyCode.Z] = "Z",
        [Enum.KeyCode.X] = "X",
        [Enum.KeyCode.C] = "C",
        [Enum.KeyCode.V] = "V",
        [Enum.KeyCode.F] = "F",
    }
    local mapped = keyMap[input.KeyCode]
    if mapped then
        Core.setCurrentSkillKey(mapped)
    end
end)

task.spawn(function()
    while not LocalPlayer:FindFirstChild("PlayerGui") do task.wait(0.5) end
    local pGui = LocalPlayer.PlayerGui
    local main = pGui:WaitForChild("Main", 10)
    if main then
        local skills = main:WaitForChild("Skills", 10)
        if skills then
            for _, wf in ipairs(skills:GetChildren()) do
                if wf:IsA("GuiObject") then
                    for _, b in ipairs(wf:GetChildren()) do
                        if b:IsA("ImageButton") or b:IsA("TextButton") then hookMobileButton(b) end
                    end
                end
            end
            skills.ChildAdded:Connect(function(wf)
                if wf:IsA("GuiObject") then
                    for _, b in ipairs(wf:GetChildren()) do
                        if b:IsA("ImageButton") or b:IsA("TextButton") then hookMobileButton(b) end
                    end
                end
            end)
        end
    end
end)

_G.DarlingCombatCore = Core
return Core
