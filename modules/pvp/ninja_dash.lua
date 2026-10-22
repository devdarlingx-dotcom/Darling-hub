-- Ninja Dash Module (Kitsune Wild Assault)
-- High-speed zigzag dash with official animations, sound, FOV punch, and physics impulse

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local FloatingWidget = nil
pcall(function()
    FloatingWidget = (_G.DarlingHub and _G.DarlingHub:Require("modules/pvp/floating_widget.lua"))
end)

local ANIM_IDS = {
    ZigzagDash = "rbxassetid://15539566377",
    ForwardDash = "rbxassetid://15518772630",
}

local SOUND_IDS = {
    DashWhoosh = "rbxassetid://9114223175",
}

-- Native Blox Fruits sound utility
local bloxFruitsUtil = nil
pcall(function()
    if ReplicatedStorage:FindFirstChild("Util") then
        bloxFruitsUtil = require(ReplicatedStorage.Util)
    end
end)

local NinjaDash = {
    Enabled = false,
    DashSpeed = 220,
    DashDuration = 0.32,
    Cooldown = 0.05,
    FovKick = 88,
    LastDash = 0,
    IsDashing = false,
    Keybind = Enum.KeyCode.Q,
    Widget = nil,
    InputConnection = nil,
}

local function getCharacterComponents()
    local char = LocalPlayer and LocalPlayer.Character
    if not char then return nil, nil, nil, nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    return char, hum, hrp, animator
end

local function playDashSound(parent)
    local playedNative = false
    if bloxFruitsUtil and bloxFruitsUtil.Sound and typeof(bloxFruitsUtil.Sound.Play) == "function" then
        pcall(function()
            bloxFruitsUtil.Sound:Play("FlashStep", parent, nil, 1, 1)
            playedNative = true
        end)
    end

    if not playedNative then
        pcall(function()
            local snd = Instance.new("Sound")
            snd.SoundId = SOUND_IDS.DashWhoosh
            snd.Volume = 1.0
            snd.PlaybackSpeed = 1.05
            snd.Parent = parent
            snd:Play()
            Debris:AddItem(snd, 3)
        end)
    end
end

local function punchCameraFov(targetFov, duration)
    local cam = Workspace.CurrentCamera or Camera
    if not cam then return end
    pcall(function()
        local origFov = cam.FieldOfView
        local inTween = TweenService:Create(cam, TweenInfo.new(duration * 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            FieldOfView = math.clamp(targetFov, 70, 100),
        })
        inTween:Play()
        inTween.Completed:Connect(function()
            local outTween = TweenService:Create(cam, TweenInfo.new(duration * 0.65, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                FieldOfView = origFov,
            })
            outTween:Play()
        end)
    end)
end

local function shakeCamera(intensity, duration)
    task.spawn(function()
        local cam = Workspace.CurrentCamera or Camera
        if not cam then return end
        local start = os.clock()
        while os.clock() - start < duration do
            local factor = 1 - ((os.clock() - start) / duration)
            local offset = Vector3.new(
                (math.random() - 0.5) * intensity * factor,
                (math.random() - 0.5) * intensity * factor,
                (math.random() - 0.5) * intensity * factor
            )
            pcall(function()
                cam.CFrame = cam.CFrame * CFrame.new(offset)
            end)
            RunService.RenderStepped:Wait()
        end
    end)
end

local function playDashAnimation()
    local _, _, _, animator = getCharacterComponents()
    if not animator then return nil end

    local anim = Instance.new("Animation")
    anim.AnimationId = ANIM_IDS.ZigzagDash

    local success, track = pcall(function()
        return animator:LoadAnimation(anim)
    end)
    pcall(function() anim:Destroy() end)

    if success and track then
        track.Priority = Enum.AnimationPriority.Action
        track:Play(0.08, 1, 1.45)
        return track
    else
        local anim2 = Instance.new("Animation")
        anim2.AnimationId = ANIM_IDS.ForwardDash
        local s2, t2 = pcall(function()
            return animator:LoadAnimation(anim2)
        end)
        pcall(function() anim2:Destroy() end)
        if s2 and t2 then
            t2.Priority = Enum.AnimationPriority.Action
            t2:Play(0.08, 1, 1.3)
            return t2
        end
    end
    return nil
end

function NinjaDash.doDash()
    local now = os.clock()
    if now - NinjaDash.LastDash < NinjaDash.Cooldown or NinjaDash.IsDashing then return end
    NinjaDash.LastDash = now
    NinjaDash.IsDashing = true

    local char, hum, hrp = getCharacterComponents()
    if not char or not hum or not hrp or hum.Health <= 0 then
        NinjaDash.IsDashing = false
        return
    end

    -- Reset internal Blox Fruits dash cooldown attribute
    pcall(function()
        char:SetAttribute("DashCooldown", 0)
    end)

    local cam = Workspace.CurrentCamera or Camera
    local camLook = cam and cam.CFrame.LookVector or hrp.CFrame.LookVector
    local flatDirection = Vector3.new(camLook.X, 0, camLook.Z)
    if flatDirection.Magnitude > 0.05 then
        flatDirection = flatDirection.Unit
    else
        flatDirection = hrp.CFrame.LookVector
    end

    -- Collision check ahead
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = { char }
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local travelDistance = NinjaDash.DashSpeed * NinjaDash.DashDuration
    local rayResult = Workspace:Raycast(hrp.Position, flatDirection * travelDistance, rayParams)
    local targetTravelDistance = travelDistance
    if rayResult then
        targetTravelDistance = math.max(6, (rayResult.Position - hrp.Position).Magnitude - 3)
    end

    -- Orient character towards dash direction
    pcall(function()
        hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + flatDirection)
    end)

    -- Play authentic effects
    playDashAnimation()
    playDashSound(hrp)
    punchCameraFov(NinjaDash.FovKick, NinjaDash.DashDuration)
    shakeCamera(1.5, 0.22)

    -- Apply authentic high-speed BodyVelocity with zigzag oscillation
    local bodyVel = Instance.new("BodyVelocity")
    bodyVel.Name = "WildAssaultVelocity"
    bodyVel.Velocity = flatDirection * (targetTravelDistance / NinjaDash.DashDuration)
    bodyVel.MaxForce = Vector3.new(1e6, 1e5, 1e6)
    bodyVel.Parent = hrp
    Debris:AddItem(bodyVel, NinjaDash.DashDuration)

    local startTime = os.clock()
    local zigzagConn = nil
    zigzagConn = RunService.RenderStepped:Connect(function()
        local elapsed = os.clock() - startTime
        if elapsed >= NinjaDash.DashDuration or not bodyVel.Parent or not hrp.Parent then
            if zigzagConn then
                zigzagConn:Disconnect()
                zigzagConn = nil
            end
            if bodyVel and bodyVel.Parent then
                pcall(function() bodyVel:Destroy() end)
            end
            NinjaDash.IsDashing = false
            return
        end

        local progress = elapsed / NinjaDash.DashDuration
        local sideOffset = math.sin(progress * math.pi * 3) * 12
        local sideVector = hrp.CFrame.RightVector * sideOffset
        bodyVel.Velocity = (flatDirection * (targetTravelDistance / NinjaDash.DashDuration)) + sideVector
    end)
end

function NinjaDash.enable()
    if NinjaDash.Enabled then
        if NinjaDash.Widget then NinjaDash.Widget:SetVisible(true) end
        return
    end
    NinjaDash.Enabled = true

    if not NinjaDash.InputConnection then
        NinjaDash.InputConnection = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if not NinjaDash.Enabled then return end
            if input.KeyCode == NinjaDash.Keybind then
                if NinjaDash.Widget then
                    NinjaDash.Widget:TriggerAction()
                else
                    NinjaDash.doDash()
                end
            end
        end)
    end

    if not NinjaDash.Widget and FloatingWidget then
        NinjaDash.Widget = FloatingWidget.create({
            Id = "NinjaDashWidget",
            Label = "Q",
            Type = "Action",
            Position = UDim2.new(0.35, 0, 0.28, 0),
            AccentColor = Color3.fromRGB(244, 63, 94),
            Callback = function()
                NinjaDash.doDash()
            end
        })
    elseif NinjaDash.Widget then
        NinjaDash.Widget:SetVisible(true)
    end
end

function NinjaDash.disable()
    NinjaDash.Enabled = false
    if NinjaDash.InputConnection then
        pcall(function() NinjaDash.InputConnection:Disconnect() end)
        NinjaDash.InputConnection = nil
    end
    if NinjaDash.Widget then
        NinjaDash.Widget:SetVisible(false)
    end
end

function NinjaDash.toggle()
    if NinjaDash.Enabled then
        NinjaDash.disable()
    else
        NinjaDash.enable()
    end
    return NinjaDash.Enabled
end

function NinjaDash.setFloatingVisible(visible)
    if NinjaDash.Widget and NinjaDash.Enabled then
        NinjaDash.Widget:SetVisible(visible)
    end
end

function NinjaDash.destroy()
    NinjaDash.disable()
    if NinjaDash.Widget then
        pcall(function() NinjaDash.Widget:Destroy() end)
        NinjaDash.Widget = nil
    end
end

function NinjaDash.getDiagnostics()
    local connCount = NinjaDash.InputConnection and 1 or 0
    return {
        Connections = connCount,
        Threads = 0,
        Active = NinjaDash.Enabled,
    }
end

return NinjaDash
