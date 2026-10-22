--[[
    Darling Hub - Transcendence 1000X (Celestial Titan Dragon)
    Cinematic masterpiece cutscene and permanent celestial companion at Y + 38.0 studs.
]]--

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local Transcendence = {
    IsPlaying = false,
}

local AUDIO_CINEMATIC = "rbxassetid://90089940136467"
local AUDIO_METEOR_BOOM = "rbxassetid://157878578"
local AUDIO_CELESTIAL_ROAR = "rbxassetid://9069609200"
local AUDIO_RUMBLE = "rbxassetid://9114223171"

local TEX_SPARK = "rbxassetid://2581273950"
local TEX_MIST = "rbxassetid://12865656309"
local TEX_GLINT = "rbxassetid://94431438472232"
local TEX_BEAM = "rbxassetid://6034176465"

local MESH_DIAMOND = "rbxassetid://9756362"
local MESH_DRAGON = "rbxassetid://94316226"
local TEX_DRAGON = "rbxassetid://94257533"

local function makeKeyframeNumberSeq(points)
    local keypoints = {}
    for _, pt in ipairs(points) do
        table.insert(keypoints, NumberSequenceKeypoint.new(pt[1], pt[2]))
    end
    return NumberSequence.new(keypoints)
end

local function rainbowColor(offset, speed, s, v)
    local t = tick() * (speed or 0.3) + (offset or 0)
    local h = t % 1
    return Color3.fromHSV(h, s or 0.95, v or 1.0)
end

local function rainbowSeq(offset, speed)
    local t = tick() * (speed or 0.3) + (offset or 0)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromHSV(t % 1, 0.95, 1)),
        ColorSequenceKeypoint.new(0.33, Color3.fromHSV((t + 0.33) % 1, 0.95, 1)),
        ColorSequenceKeypoint.new(0.66, Color3.fromHSV((t + 0.66) % 1, 0.95, 1)),
        ColorSequenceKeypoint.new(1, Color3.fromHSV(t % 1, 0.95, 1))
    })
end

local function uiTween(instance, duration, properties, style, dir)
    if not instance then return end
    local info = TweenInfo.new(duration, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
    local tw = TweenService:Create(instance, info, properties)
    tw:Play()
    return tw
end

function Transcendence.play(onComplete)
    if Transcendence.IsPlaying then return end
    Transcendence.IsPlaying = true

    local char = LocalPlayer and LocalPlayer.Character
    if not char then
        char = LocalPlayer and LocalPlayer.CharacterAdded:Wait()
    end
    local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChildWhichIsA("BasePart"))
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp then
        Transcendence.IsPlaying = false
        if onComplete then onComplete() end
        return
    end

    local isDone = false
    local renderConn = nil

    hrp.Anchored = true
    if humanoid then
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
    end

    local cam = Workspace.CurrentCamera
    local oldCameraType = cam.CameraType
    local oldCameraCF = cam.CFrame
    local oldCameraFOV = cam.FieldOfView
    cam.CameraType = Enum.CameraType.Scriptable

    local oldClockTime = Lighting.ClockTime
    local oldBrightness = Lighting.Brightness
    local oldAmbient = Lighting.Ambient
    local oldOutdoorAmbient = Lighting.OutdoorAmbient
    local oldFogEnd = Lighting.FogEnd
    local oldFogColor = Lighting.FogColor
    local oldExposure = Lighting.ExposureCompensation

    local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5)

    local cinemaScreen = Instance.new("ScreenGui")
    cinemaScreen.Name = "DarlingTranscendenceCinema"
    cinemaScreen.ResetOnSpawn = false
    cinemaScreen.IgnoreGuiInset = true
    cinemaScreen.DisplayOrder = 999999
    cinemaScreen.Parent = PlayerGui

    local flashFrame = Instance.new("Frame")
    flashFrame.Name = "FlashOverlay"
    flashFrame.Size = UDim2.fromScale(1, 1)
    flashFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    flashFrame.BackgroundTransparency = 1
    flashFrame.BorderSizePixel = 0
    flashFrame.Parent = cinemaScreen

    local bloom = Instance.new("BloomEffect")
    bloom.Intensity = 1.3
    bloom.Size = 32
    bloom.Threshold = 0.55
    bloom.Parent = Lighting

    local colorCorrection = Instance.new("ColorCorrectionEffect")
    colorCorrection.Brightness = 0.05
    colorCorrection.Contrast = 0.18
    colorCorrection.Saturation = 0.35
    colorCorrection.Parent = Lighting

    local cinematicSound = Instance.new("Sound")
    cinematicSound.SoundId = AUDIO_CINEMATIC
    cinematicSound.Volume = 0.95
    cinematicSound.Parent = cinemaScreen
    cinematicSound:Play()

    local boomSound = Instance.new("Sound")
    boomSound.SoundId = AUDIO_METEOR_BOOM
    boomSound.Volume = 1.0
    boomSound.Parent = cinemaScreen

    local celestialRoarSound = Instance.new("Sound")
    celestialRoarSound.SoundId = AUDIO_CELESTIAL_ROAR
    celestialRoarSound.Volume = 1.0
    celestialRoarSound.Parent = cinemaScreen

    local vfxFolder = Instance.new("Folder")
    vfxFolder.Name = "Darling_TranscendenceVFX"
    vfxFolder.Parent = Workspace

    local companionFolder = Workspace:FindFirstChild("Darling_DragonCompanion")
    if companionFolder then companionFolder:Destroy() end
    companionFolder = Instance.new("Folder")
    companionFolder.Name = "Darling_DragonCompanion"
    companionFolder.Parent = Workspace

    local targetPos = hrp.Position
    local lookVec = hrp.CFrame.LookVector
    local rightVec = hrp.CFrame.RightVector
    local centerRitualPos = targetPos + lookVec * 20.0
    local skyDetonationPos = centerRitualPos + Vector3.new(0, 220.0, 0)

    -- Genesis Diamond Core
    local genesisCore = Instance.new("Part")
    genesisCore.Size = Vector3.new(1, 1, 1)
    genesisCore.CFrame = CFrame.new(centerRitualPos + Vector3.new(0, 3.5, 0))
    genesisCore.Material = Enum.Material.Neon
    genesisCore.Color = Color3.fromRGB(255, 255, 255)
    genesisCore.Transparency = 0
    genesisCore.Anchored = true
    genesisCore.CanCollide = false
    genesisCore.Parent = vfxFolder

    local genesisMesh = Instance.new("SpecialMesh")
    genesisMesh.MeshType = Enum.MeshType.FileMesh
    genesisMesh.MeshId = MESH_DIAMOND
    genesisMesh.Scale = Vector3.new(2.8, 4.2, 2.8)
    genesisMesh.Parent = genesisCore

    -- Celestial Titan Dragon
    local dragonBody = Instance.new("Part")
    dragonBody.Name = "CelestialTitanDragon"
    dragonBody.Size = Vector3.new(12, 10, 36)
    dragonBody.Material = Enum.Material.SmoothPlastic
    dragonBody.Color = Color3.fromRGB(255, 255, 255)
    dragonBody.Transparency = 1
    dragonBody.Anchored = true
    dragonBody.CanCollide = false
    dragonBody.Parent = companionFolder

    local dragonMesh = Instance.new("SpecialMesh")
    dragonMesh.MeshType = Enum.MeshType.FileMesh
    dragonMesh.MeshId = MESH_DRAGON
    dragonMesh.TextureId = TEX_DRAGON
    dragonMesh.Scale = Vector3.new(36, 36, 36)
    dragonMesh.Parent = dragonBody

    local function endCinematic()
        if isDone then return end
        isDone = true
        if renderConn then renderConn:Disconnect() end

        pcall(function()
            if cinemaScreen then cinemaScreen:Destroy() end
            if vfxFolder then vfxFolder:Destroy() end
            if bloom then bloom:Destroy() end
            if colorCorrection then colorCorrection:Destroy() end
        end)

        pcall(function()
            Lighting.ClockTime = oldClockTime
            Lighting.Brightness = oldBrightness
            Lighting.Ambient = oldAmbient
            Lighting.OutdoorAmbient = oldOutdoorAmbient
            Lighting.FogEnd = oldFogEnd
            Lighting.FogColor = oldFogColor
            Lighting.ExposureCompensation = oldExposure
        end)

        local liveChar = LocalPlayer and LocalPlayer.Character or char
        local liveHrp = liveChar and (liveChar:FindFirstChild("HumanoidRootPart") or liveChar:FindFirstChild("Torso") or liveChar:FindFirstChildWhichIsA("BasePart"))
        local liveHum = liveChar and liveChar:FindFirstChildOfClass("Humanoid")
        if liveHrp then liveHrp.Anchored = false end
        if liveHum then liveHum.WalkSpeed = 16 liveHum.JumpPower = 50 end

        cam.CameraType = oldCameraType
        if oldCameraCF and liveHrp then
            cam.CFrame = CFrame.lookAt(liveHrp.Position - liveHrp.CFrame.LookVector * 18 + Vector3.new(0, 5, 0), liveHrp.Position + Vector3.new(0, 1.8, 0))
            cam.FieldOfView = oldCameraFOV
        end

        -- Permanent companion following player at Y + 38.0 studs
        task.spawn(function()
            local companionConn = nil
            companionConn = RunService.Heartbeat:Connect(function()
                local cChar = LocalPlayer and LocalPlayer.Character or char
                local cHrp = cChar and (cChar:FindFirstChild("HumanoidRootPart") or cChar:FindFirstChild("Torso") or cChar:FindFirstChildWhichIsA("BasePart"))
                if not cHrp or not companionFolder or not companionFolder.Parent then
                    if companionConn then companionConn:Disconnect() end
                    return
                end
                local now = tick()
                local targetFollowPos = cHrp.Position + cHrp.CFrame.RightVector * 28 + cHrp.CFrame.LookVector * 8 + Vector3.new(0, 38.0 + math.sin(now * 2.2) * 1.8, 0)
                dragonBody.CFrame = CFrame.lookAt(targetFollowPos, cHrp.Position + cHrp.CFrame.LookVector * 65 + Vector3.new(0, 15, 0)) * CFrame.Angles(math.rad(10), 0, math.sin(now * 1.8) * 0.06)
                dragonBody.Transparency = 0.05
            end)
        end)

        Transcendence.IsPlaying = false
        if onComplete then onComplete() end
    end

    local startTime = tick()
    renderConn = RunService.RenderStepped:Connect(function(dt)
        local elapsed = tick() - startTime
        if elapsed >= 34.0 then
            endCinematic()
            return
        end

        -- Simple smooth camera cutscene flow
        if elapsed < 8.0 then
            local p = elapsed / 8.0
            genesisCore.CFrame = CFrame.new(centerRitualPos + Vector3.new(0, 3.5 + p * 40, 0)) * CFrame.Angles(0, elapsed * 3, 0)
            local camPos = centerRitualPos - lookVec * (30 + p * 30) + Vector3.new(0, 15 + p * 20, 0)
            cam.CFrame = CFrame.lookAt(camPos, genesisCore.Position)
            cam.FieldOfView = 75
        elseif elapsed < 16.0 then
            genesisCore.Transparency = 1
            if not boomSound.IsPlaying then boomSound:Play() end
            local p = (elapsed - 8.0) / 8.0
            local camPos = skyDetonationPos - lookVec * (40 + p * 50) + Vector3.new(0, 20, 0)
            cam.CFrame = CFrame.lookAt(camPos, skyDetonationPos)
            cam.FieldOfView = 85
        elseif elapsed < 26.0 then
            if not celestialRoarSound.IsPlaying then celestialRoarSound:Play() end
            local p = (elapsed - 16.0) / 10.0
            local divePos = skyDetonationPos:Lerp(targetPos + rightVec * 28 + lookVec * 8 + Vector3.new(0, 38, 0), p)
            dragonBody.CFrame = CFrame.lookAt(divePos, targetPos)
            dragonBody.Transparency = 0.05
            local camPos = targetPos - lookVec * 50 + Vector3.new(0, 18, 0)
            cam.CFrame = CFrame.lookAt(camPos, divePos)
            cam.FieldOfView = 80
        else
            local liveChar = LocalPlayer and LocalPlayer.Character or char
            local liveHrp = liveChar and (liveChar:FindFirstChild("HumanoidRootPart") or liveChar:FindFirstChild("Torso") or liveChar:FindFirstChildWhichIsA("BasePart"))
            local currentHrpPos = liveHrp and liveHrp.Position or targetPos
            local companionPos = currentHrpPos + rightVec * 28 + lookVec * 8 + Vector3.new(0, 38, 0)
            dragonBody.CFrame = CFrame.lookAt(companionPos, currentHrpPos + currentHrpPos.Unit * 45)
            local orbitAng = (elapsed - 26.0) * 0.4
            local camPos = currentHrpPos + Vector3.new(math.sin(orbitAng) * 55, 14, math.cos(orbitAng) * 55)
            cam.CFrame = CFrame.lookAt(camPos, currentHrpPos)
        end
    end)
end

return Transcendence
