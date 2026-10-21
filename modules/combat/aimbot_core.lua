--[[
    Darling Hub - Combat Core (Blox Fruits)
    High-compatibility targeting engine with Mouse override, Namecall interception,
    and multi-folder NPC/Player resolution.
]]--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer and LocalPlayer:GetMouse()

local Core = {
    -- Toggles
    PlayerAimEnabled = false,
    NPCAimEnabled = false,
    TeamCheck = false, -- Default false for maximum compatibility

    -- Settings
    AimMode = "360", -- "360", "180", "FOV"
    TargetPriority = "Nearest", -- "Nearest", "Low HP", "Looking At Me"
    MaxRange = 1000,
    PredictionEnabled = true,
    PredictionAmount = 0.12,

    -- FOV Settings
    FOV = {
        Visible = false,
        Radius = 100,
        Mode = "Center",
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

    -- Internal
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

    local gunNames = { "guitar", "rifle", "cannon", "gun", "slingshot", "kabucha", "bow" }
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
-- HEALTH & HITBOX UTILITIES
-- ============================================================================
local function isAlive(char)
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function getHRP(char)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChild("UpperTorso")
        or char:FindFirstChild("Torso")
        or char:FindFirstChild("Head")
end

local function getTargetPart(char)
    if not char then return nil end
    return getHRP(char) or char:FindFirstChildWhichIsA("BasePart")
end

-- ============================================================================
-- FOV & ANGLE VALIDATION
-- ============================================================================
function Core.getFOVCenter()
    Camera = Workspace.CurrentCamera or Camera
    local hubSettings = (_G.DarlingHub and _G.DarlingHub.Settings and _G.DarlingHub.Settings.FOV) or Core.FOV
    if hubSettings.Mode == "Mouse" then
        return UserInputService:GetMouseLocation()
    end
    return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

local function isTargetInFOV(worldPos)
    Camera = Workspace.CurrentCamera or Camera
    local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)
    if not onScreen then return false end

    local hubSettings = (_G.DarlingHub and _G.DarlingHub.Settings and _G.DarlingHub.Settings.FOV) or Core.FOV
    local radius = hubSettings.Radius or Core.FOV.Radius or 100
    local center = Core.getFOVCenter()
    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
    return dist <= radius
end

local function isAngleValid(targetPart, lpHRP)
    local hubSettings = (_G.DarlingHub and _G.DarlingHub.Settings and _G.DarlingHub.Settings.Aim) or Core
    local mode = hubSettings.Mode or Core.AimMode or "360"

    if mode == "360" then
        return true
    elseif mode == "180" then
        local dir = (targetPart.Position - lpHRP.Position).Unit
        return lpHRP.CFrame.LookVector:Dot(dir) >= 0
    elseif mode == "FOV" then
        return isTargetInFOV(targetPart.Position)
    end
    return true
end

-- ============================================================================
-- PREDICTION ENGINE
-- ============================================================================
function Core.predictPosition(targetPart)
    if not targetPart then return nil end
    local char = targetPart.Parent
    if not isAlive(char) then return targetPart.Position end

    local hubSettings = (_G.DarlingHub and _G.DarlingHub.Settings and _G.DarlingHub.Settings.Aim) or Core
    if hubSettings.Prediction == false then
        return targetPart.Position
    end

    local hrp = char:FindFirstChild("HumanoidRootPart") or targetPart
    local vel = hrp.Velocity
    local speed = vel.Magnitude

    if speed < 3 then
        Core.LastVelocity = nil
        Core.LastDirection = nil
        return targetPart.Position
    end

    local currentDir = vel.Unit
    if Core.LastDirection then
        local dot = Core.LastDirection:Dot(currentDir)
        if dot < 0.65 then
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
    ping = math.clamp(ping, 0, 0.25)

    local factor = (hubSettings.PredictionAmount or Core.PredictionAmount or 0.12) + ping
    if speed > 100 then factor = math.min(factor, 0.14) end

    return targetPart.Position + (vel * factor)
end

-- ============================================================================
-- TARGET SELECTION (PLAYERS & NPCS)
-- ============================================================================
local function resolvePlayerTarget(lpHRP)
    if not lpHRP then return nil, nil end
    local hubSettings = (_G.DarlingHub and _G.DarlingHub.Settings and _G.DarlingHub.Settings.Aim) or Core
    local maxRange = hubSettings.MaxRange or Core.MaxRange or 1000
    local priority = hubSettings.Priority or Core.TargetPriority or "Nearest"
    local mode = hubSettings.Mode or Core.AimMode or "360"

    local candidates = {}
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and pl.Character and isAlive(pl.Character) then
            local char = pl.Character
            local hrp = getHRP(char)
            if hrp and isAngleValid(hrp, lpHRP) then
                local dist = (hrp.Position - lpHRP.Position).Magnitude
                if dist <= maxRange then
                    table.insert(candidates, {
                        Player = pl,
                        Character = char,
                        Humanoid = char:FindFirstChildOfClass("Humanoid"),
                        HRP = hrp,
                        Distance = dist,
                    })
                end
            end
        end
    end

    if #candidates == 0 then return nil, nil end

    if mode == "FOV" then
        local center = Core.getFOVCenter()
        table.sort(candidates, function(a, b)
            local pA = Camera:WorldToViewportPoint(a.HRP.Position)
            local pB = Camera:WorldToViewportPoint(b.HRP.Position)
            local dA = (Vector2.new(pA.X, pA.Y) - center).Magnitude
            local dB = (Vector2.new(pB.X, pB.Y) - center).Magnitude
            return dA < dB
        end)
    elseif priority == "Low HP" then
        table.sort(candidates, function(a, b) return a.Humanoid.Health < b.Humanoid.Health end)
    elseif priority == "Looking At Me" then
        table.sort(candidates, function(a, b)
            local dirA = (lpHRP.Position - a.HRP.Position).Unit
            local lookA = a.HRP.CFrame.LookVector
            local dirB = (lpHRP.Position - b.HRP.Position).Unit
            local lookB = b.HRP.CFrame.LookVector
            return lookA:Dot(dirA) > lookB:Dot(dirB)
        end)
    else
        table.sort(candidates, function(a, b) return a.Distance < b.Distance end)
    end

    local chosen = candidates[1]
    local part = getTargetPart(chosen.Character)
    return part, Core.predictPosition(part), chosen.Character
end

local function resolveNPCTarget(lpHRP)
    if not lpHRP then return nil, nil end
    local hubSettings = (_G.DarlingHub and _G.DarlingHub.Settings and _G.DarlingHub.Settings.Aim) or Core
    local maxRange = hubSettings.MaxRange or Core.MaxRange or 1000

    local closestPart = nil
    local closestPredicted = nil
    local closestChar = nil
    local shortestDist = math.huge

    local function checkEntity(entity)
        if entity:IsA("Model") and isAlive(entity) and not Players:GetPlayerFromCharacter(entity) then
            local hrp = getHRP(entity)
            if hrp and isAngleValid(hrp, lpHRP) then
                local dist = (hrp.Position - lpHRP.Position).Magnitude
                if dist <= maxRange and dist < shortestDist then
                    local part = getTargetPart(entity)
                    closestPart = part
                    closestPredicted = Core.predictPosition(part)
                    closestChar = entity
                    shortestDist = dist
                end
            end
        end
    end

    -- Check all known Blox Fruits entity folders
    local folders = {
        Workspace:FindFirstChild("Enemies"),
        Workspace:FindFirstChild("Characters"),
        Workspace:FindFirstChild("NPCs"),
        Workspace:FindFirstChild("Live"),
    }

    local foundAnyFolder = false
    for _, f in ipairs(folders) do
        if f then
            foundAnyFolder = true
            for _, child in ipairs(f:GetChildren()) do
                checkEntity(child)
            end
        end
    end

    -- Fallback: scan workspace if folders not present
    if not foundAnyFolder then
        for _, child in ipairs(Workspace:GetChildren()) do
            checkEntity(child)
        end
    end

    return closestPart, closestPredicted, closestChar
end

function Core.resolveAnyTarget()
    Camera = Workspace.CurrentCamera or Camera
    local char = LocalPlayer and LocalPlayer.Character
    local lpHRP = char and getHRP(char)
    if not lpHRP then return nil, nil end

    local pPart, pPos, pChar = resolvePlayerTarget(lpHRP)
    if pPart and pPos then return pPart, pPos, pChar end

    return resolveNPCTarget(lpHRP)
end

-- ============================================================================
-- ROTATION TOWARDS TARGET
-- ============================================================================
function Core.faceTarget(targetPos)
    if not targetPos then return end
    local char = LocalPlayer and LocalPlayer.Character
    local hrp = char and getHRP(char)
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
-- METATABLE HOOKS (MOUSE OVERRIDE + REMOTES)
-- ============================================================================
function Core.installHooks()
    if Core.IsHooked then return end
    Core.IsHooked = true

    -- Hook 1: Mouse.Hit and Mouse.Target (Direct skill and weapon redirect)
    if Mouse then
        local rawMt = getrawmetatable(game)
        if rawMt then
            local oldIndex = rawMt.__index
            setreadonly(rawMt, false)
            rawMt.__index = newcclosure(function(t, k)
                if (Core.PlayerAimEnabled or Core.NPCAimEnabled) and t == Mouse then
                    if Core.CurrentTargetPosition then
                        if k == "Hit" then
                            return CFrame.new(Core.CurrentTargetPosition)
                        elseif k == "Target" then
                            return Core.CurrentTargetPart
                        end
                    end
                end
                return oldIndex(t, k)
            end)
            setreadonly(rawMt, true)
        end
    end

    -- Hook 2: ReplicatedStorage.Mouse module (used in Blox Fruits for PC and Mobile)
    task.spawn(function()
        local mouseModInstance = ReplicatedStorage:WaitForChild("Mouse", 5)
        if mouseModInstance then
            local ok, mouseMod = pcall(require, mouseModInstance)
            if ok and typeof(mouseMod) == "table" then
                local realStore = { Hit = rawget(mouseMod, "Hit"), Target = rawget(mouseMod, "Target") }
                local mmt = getrawmetatable(mouseMod) or {}
                pcall(setreadonly, mmt, false)
                rawset(mouseMod, "Hit", nil)
                rawset(mouseMod, "Target", nil)
                mmt.__index = function(self, key)
                    if (Core.PlayerAimEnabled or Core.NPCAimEnabled) and Core.CurrentTargetPosition then
                        if key == "Hit" then
                            return CFrame.new(Core.CurrentTargetPosition)
                        elseif key == "Target" then
                            return Core.CurrentTargetPart
                        end
                    end
                    return realStore[key] or rawget(self, key)
                end
                setmetatable(mouseMod, mmt)
            end
        end
    end)

    -- Hook 3: Remote interception (__namecall for FireServer & InvokeServer)
    local rawMt = getrawmetatable(game)
    if rawMt then
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

            local activeKey = skillKey or Core.CurrentSkillKey
            local isBlacklisted = false
            if activeKey and Core.isKeyBlacklisted(Core.CurrentToolCategory, activeKey) then
                isBlacklisted = true
            end

            if not isBlacklisted and (Core.PlayerAimEnabled or Core.NPCAimEnabled) and Core.CurrentTargetPosition then
                local targetPos = Core.CurrentTargetPosition

                if method == "FireServer" then
                    local sName = tostring(self)
                    if sName == "RemoteEvent" or sName == "CommE" or sName == "RegisterAttack" or typeof(args[1]) == "Vector3" then
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
end

-- ============================================================================
-- RENDER LOOP (TARGET UPDATES)
-- ============================================================================
local function updateTargetCycle()
    Camera = Workspace.CurrentCamera or Camera
    local char = LocalPlayer and LocalPlayer.Character
    local lpHRP = char and getHRP(char)

    if not lpHRP or (not Core.PlayerAimEnabled and not Core.NPCAimEnabled) then
        Core.CurrentTargetPosition = nil
        Core.CurrentTargetPart = nil
        Core.CurrentTargetCharacter = nil
        return
    end

    local targetPart, predictedPos, targetChar = nil, nil, nil

    if Core.PlayerAimEnabled then
        targetPart, predictedPos, targetChar = resolvePlayerTarget(lpHRP)
        if targetPart then Core.CurrentTargetIsPlayer = true end
    end

    if not targetPart and Core.NPCAimEnabled then
        targetPart, predictedPos, targetChar = resolveNPCTarget(lpHRP)
        if targetPart then Core.CurrentTargetIsPlayer = false end
    end

    Core.CurrentTargetPart = targetPart
    Core.CurrentTargetPosition = predictedPos
    Core.CurrentTargetCharacter = targetChar
end

function Core.startLoop()
    if Core.RenderConnection then return end
    Core.installHooks()
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
local function setupCharacter(char)
    for _, c in ipairs(Core.CharConnections) do pcall(function() c:Disconnect() end) end
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

if LocalPlayer then
    LocalPlayer.CharacterAdded:Connect(setupCharacter)
    if LocalPlayer.Character then setupCharacter(LocalPlayer.Character) end
end

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
    if mapped then Core.setCurrentSkillKey(mapped) end
end)

-- Mobile buttons hook
task.spawn(function()
    while not LocalPlayer or not LocalPlayer:FindFirstChild("PlayerGui") do task.wait(0.5) end
    local pGui = LocalPlayer.PlayerGui
    local main = pGui:WaitForChild("Main", 10)
    if main then
        local skills = main:WaitForChild("Skills", 10)
        if skills then
            local function hookBtn(b)
                if (b:IsA("ImageButton") or b:IsA("TextButton")) and table.find(SKILL_KEYS, b.Name) then
                    b.Activated:Connect(function() Core.setCurrentSkillKey(b.Name) end)
                end
            end
            for _, wf in ipairs(skills:GetChildren()) do
                if wf:IsA("GuiObject") then
                    for _, b in ipairs(wf:GetChildren()) do hookBtn(b) end
                end
            end
        end
    end
end)

-- Global exposure across both _G and getgenv()
_G.DarlingCombatCore = Core
if getgenv then pcall(function() getgenv().DarlingCombatCore = Core end) end

return Core
