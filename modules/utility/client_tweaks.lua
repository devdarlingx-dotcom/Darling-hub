-- client tweaks

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local ClientTweaks = {
    FFlags1Enabled = false,
    NoAnimEnabled = false,
    AntiLavaEnabled = false,

    FFlagsThread = nil,
    FFlagsAddedConn = nil,
    NoAnimConn = nil,
    AntiLavaConn = nil,
}

-- ========================================================================
-- 1. FFLAGS 1 PERFORMANCE & RENDERING BOOSTER
-- ========================================================================
local function isCharacterPart(obj)
    local char = LocalPlayer.Character
    if char and obj:IsDescendantOf(char) then return true end
    for _, p in ipairs(Players:GetPlayers()) do
        local c = p.Character
        if c and obj:IsDescendantOf(c) then return true end
    end
    return false
end

local function optimizePart(obj)
    pcall(function()
        if isCharacterPart(obj) then return end

        if obj:IsA("BasePart") then
            obj.Material = Enum.Material.SmoothPlastic
            obj.Reflectance = 0
            obj.CastShadow = false
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            obj.Transparency = 1
        elseif obj:IsA("ParticleEmitter") then
            obj.Rate = math.min(obj.Rate, 1)
            obj.Speed = NumberRange.new(0)
        elseif obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
            obj.Enabled = false
        elseif obj:IsA("Trail") or obj:IsA("Beam") then
            obj.Enabled = false
        end
    end)
end

local function clearAtmosphere()
    pcall(function()
        Lighting.FogStart = 0
        Lighting.FogEnd = 1e5
        Lighting.Brightness = 1
        Lighting.GlobalShadows = false
        for _, effect in ipairs(Lighting:GetDescendants()) do
            if effect:IsA("Atmosphere") then
                effect.Density = 0
                effect.Haze = 0
                effect.Glare = 0
                effect.Offset = 0
            elseif effect:IsA("BlurEffect") then
                effect.Size = 0
            elseif effect:IsA("BloomEffect") then
                effect.Intensity = 0
                effect.Size = 0
                effect.Threshold = 1
            elseif effect:IsA("DepthOfFieldEffect") then
                effect.InFocusRadius = 1e5
            elseif effect:IsA("SunRaysEffect") then
                effect.Intensity = 0
            end
        end
    end)
end

local DEBRIS_SIZE = 2
local function handleDebris(obj)
    if not obj:IsA("BasePart") or obj.Anchored or isCharacterPart(obj) then return end
    local size = obj.Size
    if size.X < DEBRIS_SIZE and size.Y < DEBRIS_SIZE and size.Z < DEBRIS_SIZE then
        pcall(function()
            obj.Transparency = 1
            obj.CanCollide = false
        end)
    end
end

function ClientTweaks.setFFlags1(state)
    ClientTweaks.FFlags1Enabled = state
    if state then
        pcall(function()
            if setfpscap then setfpscap(120) end
        end)

        clearAtmosphere()

        for _, v in ipairs(Workspace:GetDescendants()) do
            optimizePart(v)
            handleDebris(v)
        end

        if not ClientTweaks.FFlagsAddedConn then
            ClientTweaks.FFlagsAddedConn = Workspace.DescendantAdded:Connect(function(v)
                if not ClientTweaks.FFlags1Enabled then return end
                RunService.Heartbeat:Wait()
                optimizePart(v)
                handleDebris(v)
            end)
        end

        if not ClientTweaks.FFlagsThread then
            ClientTweaks.FFlagsThread = task.spawn(function()
                while ClientTweaks.FFlags1Enabled do
                    clearAtmosphere()
                    task.wait(2.5)
                end
                ClientTweaks.FFlagsThread = nil
            end)
        end
    else
        if ClientTweaks.FFlagsAddedConn then
            pcall(function() ClientTweaks.FFlagsAddedConn:Disconnect() end)
            ClientTweaks.FFlagsAddedConn = nil
        end
    end
end

-- ========================================================================
-- 2. NO ANIMATIONS (FIX SIDEWAY BUG & FREEZES)
-- ========================================================================
local ATTACK_KEYWORDS = { "attack", "slash", "punch", "m1", "combo", "hit", "tool", "ability", "skill", "kamehameha", "bullet", "gun", "sword", "melee", "fruit" }

local function isAttackAnim(track)
    local name = string.lower(track.Name)
    for _, kw in ipairs(ATTACK_KEYWORDS) do
        if string.find(name, kw) then return true end
    end
    if track.Priority == Enum.AnimationPriority.Action then return true end
    return false
end

function ClientTweaks.setNoAnimations(state)
    ClientTweaks.NoAnimEnabled = state
    if state and not ClientTweaks.NoAnimConn then
        ClientTweaks.NoAnimConn = RunService.Stepped:Connect(function()
            if not ClientTweaks.NoAnimEnabled then return end
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            hum.AutoRotate = true

            local animator = hum:FindFirstChildOfClass("Animator")
            if not animator then return end

            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                if not isAttackAnim(track) then
                    track:Stop(0)
                end
            end
        end)
    elseif not state and ClientTweaks.NoAnimConn then
        pcall(function() ClientTweaks.NoAnimConn:Disconnect() end)
        ClientTweaks.NoAnimConn = nil
    end
end

-- ========================================================================
-- 3. ANTI LAVA IMMUNITY
-- ========================================================================
function ClientTweaks.setAntiLava(state)
    ClientTweaks.AntiLavaEnabled = state
    if state and not ClientTweaks.AntiLavaConn then
        local timer = 0
        ClientTweaks.AntiLavaConn = RunService.Stepped:Connect(function(_, dt)
            if not ClientTweaks.AntiLavaEnabled then return end
            timer = timer + dt
            if timer < 0.2 then return end
            timer = 0

            local char = LocalPlayer.Character
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart")
                    and part.Name ~= "HumanoidRootPart"
                    and part.Name ~= "Torso"
                    and part.Name ~= "UpperTorso"
                    and part.Name ~= "LowerTorso"
                    and part.Name ~= "Head" then
                    part.CanTouch = false
                end
            end
        end)
    elseif not state and ClientTweaks.AntiLavaConn then
        pcall(function() ClientTweaks.AntiLavaConn:Disconnect() end)
        ClientTweaks.AntiLavaConn = nil
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanTouch = true
                end
            end
        end
    end
end

-- ========================================================================
-- 4. CAMERA SKEW (RARE VIEW)
-- ========================================================================
ClientTweaks.CameraSkewEnabled = false
ClientTweaks.SkewResolution = 0.2
ClientTweaks.SkewConn = nil

function ClientTweaks.setCameraSkew(state, resolution)
    ClientTweaks.CameraSkewEnabled = (state == true)
    if resolution then
        ClientTweaks.SkewResolution = tonumber(resolution) or 0.2
    end
    if ClientTweaks.CameraSkewEnabled and not ClientTweaks.SkewConn then
        ClientTweaks.SkewConn = RunService.RenderStepped:Connect(function()
            if not ClientTweaks.CameraSkewEnabled then return end
            local cam = Workspace.CurrentCamera
            if cam then
                cam.CFrame = cam.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, ClientTweaks.SkewResolution, 0, 0, 0, 1)
            end
        end)
    elseif not ClientTweaks.CameraSkewEnabled and ClientTweaks.SkewConn then
        pcall(function() ClientTweaks.SkewConn:Disconnect() end)
        ClientTweaks.SkewConn = nil
    end
end

return ClientTweaks
