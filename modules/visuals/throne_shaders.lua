--[[
    Darling Hub - King's Throne Cosmic Shaders
    Standalone toggleable cosmic lighting and shader effect.
    Extracted from King's Throne (Masterclass Cosmic Sovereign Chariot).

    Provides:
        - ThroneShaders.enable(smooth, duration)
        - ThroneShaders.disable(smooth, duration)
        - ThroneShaders.destroy()
        - ThroneShaders.toggle()
        - ThroneShaders.isEnabled()
        - ThroneShaders.triggerFlash(duration)
]]--

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = nil
if LocalPlayer then
    PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5)
end

local ThroneShaders = {
    Enabled = false,
    OriginalLighting = nil,
    SavedSky = nil,
    Bloom = nil,
    ColorCorrection = nil,
    Atmosphere = nil,
    ActiveSky = nil,
    FlashGui = nil,
    FlashFrame = nil,
    CreatedEffects = {},
}

-- Cosmic Midnight Constants from King's Throne
local COSMIC_LIGHTING = {
    ClockTime = 0.0,
    Brightness = 0.15,
    OutdoorAmbient = Color3.fromRGB(15, 6, 25),
    Ambient = Color3.fromRGB(25, 10, 40),
    FogEnd = 450,
    FogStart = 60,
    FogColor = Color3.fromRGB(35, 8, 55),
    ExposureCompensation = 0.35,
}

local BLOOM_CONFIG = {
    Intensity = 2.0,
    Size = 42,
    Threshold = 0.45,
}

local COLOR_CORRECTION_CONFIG = {
    Brightness = 0.06,
    Contrast = 0.32,
    Saturation = 0.50,
    TintColor = Color3.fromRGB(230, 205, 255),
}

local ATMOSPHERE_CONFIG = {
    Density = 0.35,
    Offset = 0.25,
    Color = Color3.fromRGB(140, 75, 215),
    Decay = Color3.fromRGB(55, 12, 115),
    Glare = 0.4,
    Haze = 0.7,
}

local SKY_CONFIG = {
    Bk = "rbxassetid://5260808177",
    Dn = "rbxassetid://5260653793",
    Ft = "rbxassetid://5260817288",
    Lf = "rbxassetid://5260800833",
    Rt = "rbxassetid://5260800833",
    Up = "rbxassetid://5084576400",
    StarCount = 5000,
    CelestialBodiesShown = true,
}

local function saveOriginalLighting()
    if ThroneShaders.OriginalLighting then return end
    ThroneShaders.OriginalLighting = {
        ClockTime = Lighting.ClockTime,
        Brightness = Lighting.Brightness,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        Ambient = Lighting.Ambient,
        FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart,
        FogColor = Lighting.FogColor,
        ExposureCompensation = Lighting.ExposureCompensation,
    }
end

local function createOrGetEffects()
    -- Bloom
    if not ThroneShaders.Bloom or not ThroneShaders.Bloom.Parent then
        local bloom = Lighting:FindFirstChild("Darling_Throne_Bloom") or Instance.new("BloomEffect")
        bloom.Name = "Darling_Throne_Bloom"
        bloom.Intensity = BLOOM_CONFIG.Intensity
        bloom.Size = BLOOM_CONFIG.Size
        bloom.Threshold = BLOOM_CONFIG.Threshold
        bloom.Enabled = true
        bloom.Parent = Lighting
        ThroneShaders.Bloom = bloom
        table.insert(ThroneShaders.CreatedEffects, bloom)
    else
        ThroneShaders.Bloom.Intensity = BLOOM_CONFIG.Intensity
        ThroneShaders.Bloom.Size = BLOOM_CONFIG.Size
        ThroneShaders.Bloom.Threshold = BLOOM_CONFIG.Threshold
        ThroneShaders.Bloom.Enabled = true
    end

    -- Color Correction
    if not ThroneShaders.ColorCorrection or not ThroneShaders.ColorCorrection.Parent then
        local cc = Lighting:FindFirstChild("Darling_Throne_ColorCorrection") or Instance.new("ColorCorrectionEffect")
        cc.Name = "Darling_Throne_ColorCorrection"
        cc.Brightness = COLOR_CORRECTION_CONFIG.Brightness
        cc.Contrast = COLOR_CORRECTION_CONFIG.Contrast
        cc.Saturation = COLOR_CORRECTION_CONFIG.Saturation
        cc.TintColor = COLOR_CORRECTION_CONFIG.TintColor
        cc.Enabled = true
        cc.Parent = Lighting
        ThroneShaders.ColorCorrection = cc
        table.insert(ThroneShaders.CreatedEffects, cc)
    else
        ThroneShaders.ColorCorrection.Brightness = COLOR_CORRECTION_CONFIG.Brightness
        ThroneShaders.ColorCorrection.Contrast = COLOR_CORRECTION_CONFIG.Contrast
        ThroneShaders.ColorCorrection.Saturation = COLOR_CORRECTION_CONFIG.Saturation
        ThroneShaders.ColorCorrection.TintColor = COLOR_CORRECTION_CONFIG.TintColor
        ThroneShaders.ColorCorrection.Enabled = true
    end

    -- Atmosphere
    if not ThroneShaders.Atmosphere or not ThroneShaders.Atmosphere.Parent then
        local atmo = Lighting:FindFirstChild("Darling_Throne_Atmosphere") or Instance.new("Atmosphere")
        atmo.Name = "Darling_Throne_Atmosphere"
        atmo.Density = ATMOSPHERE_CONFIG.Density
        atmo.Offset = ATMOSPHERE_CONFIG.Offset
        atmo.Color = ATMOSPHERE_CONFIG.Color
        atmo.Decay = ATMOSPHERE_CONFIG.Decay
        atmo.Glare = ATMOSPHERE_CONFIG.Glare
        atmo.Haze = ATMOSPHERE_CONFIG.Haze
        atmo.Parent = Lighting
        ThroneShaders.Atmosphere = atmo
        table.insert(ThroneShaders.CreatedEffects, atmo)
    end

    -- Cosmic Skybox
    local existingSky = Lighting:FindFirstChildOfClass("Sky")
    if existingSky and existingSky.Name ~= "Darling_Throne_Sky" then
        ThroneShaders.SavedSky = existingSky
        pcall(function() existingSky.Parent = nil end)
    end

    if not ThroneShaders.ActiveSky or not ThroneShaders.ActiveSky.Parent then
        local sky = Lighting:FindFirstChild("Darling_Throne_Sky") or Instance.new("Sky")
        sky.Name = "Darling_Throne_Sky"
        sky.SkyboxBk = SKY_CONFIG.Bk
        sky.SkyboxDn = SKY_CONFIG.Dn
        sky.SkyboxFt = SKY_CONFIG.Ft
        sky.SkyboxLf = SKY_CONFIG.Lf
        sky.SkyboxRt = SKY_CONFIG.Rt
        sky.SkyboxUp = SKY_CONFIG.Up
        sky.StarCount = SKY_CONFIG.StarCount
        sky.CelestialBodiesShown = SKY_CONFIG.CelestialBodiesShown
        sky.Parent = Lighting
        ThroneShaders.ActiveSky = sky
        table.insert(ThroneShaders.CreatedEffects, sky)
    end
end

function ThroneShaders.enable(smooth, duration)
    if ThroneShaders.Enabled then return true end

    saveOriginalLighting()
    createOrGetEffects()

    if smooth then
        local dur = (type(duration) == "number" and duration) or 2.0
        local twInfo = TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(Lighting, twInfo, COSMIC_LIGHTING):Play()
    else
        Lighting.ClockTime = COSMIC_LIGHTING.ClockTime
        Lighting.Brightness = COSMIC_LIGHTING.Brightness
        Lighting.OutdoorAmbient = COSMIC_LIGHTING.OutdoorAmbient
        Lighting.Ambient = COSMIC_LIGHTING.Ambient
        Lighting.FogEnd = COSMIC_LIGHTING.FogEnd
        Lighting.FogStart = COSMIC_LIGHTING.FogStart
        Lighting.FogColor = COSMIC_LIGHTING.FogColor
        Lighting.ExposureCompensation = COSMIC_LIGHTING.ExposureCompensation
    end

    ThroneShaders.Enabled = true
    return true
end

function ThroneShaders.disable(smooth, duration)
    if not ThroneShaders.Enabled then return end

    local orig = ThroneShaders.OriginalLighting
    if orig then
        if smooth then
            local dur = (type(duration) == "number" and duration) or 2.0
            local twInfo = TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            TweenService:Create(Lighting, twInfo, {
                ClockTime = orig.ClockTime,
                Brightness = orig.Brightness,
                OutdoorAmbient = orig.OutdoorAmbient,
                Ambient = orig.Ambient,
                FogEnd = orig.FogEnd,
                FogStart = orig.FogStart,
                FogColor = orig.FogColor,
                ExposureCompensation = orig.ExposureCompensation,
            }):Play()

            task.delay(dur, function()
                if not ThroneShaders.Enabled then
                    for _, eff in ipairs(ThroneShaders.CreatedEffects) do
                        pcall(function() eff:Destroy() end)
                    end
                    ThroneShaders.CreatedEffects = {}
                    ThroneShaders.Bloom = nil
                    ThroneShaders.ColorCorrection = nil
                    ThroneShaders.Atmosphere = nil
                    ThroneShaders.ActiveSky = nil
                end
            end)
        else
            Lighting.ClockTime = orig.ClockTime
            Lighting.Brightness = orig.Brightness
            Lighting.OutdoorAmbient = orig.OutdoorAmbient
            Lighting.Ambient = orig.Ambient
            Lighting.FogEnd = orig.FogEnd
            Lighting.FogStart = orig.FogStart
            Lighting.FogColor = orig.FogColor
            Lighting.ExposureCompensation = orig.ExposureCompensation

            for _, eff in ipairs(ThroneShaders.CreatedEffects) do
                pcall(function() eff:Destroy() end)
            end
            ThroneShaders.CreatedEffects = {}
            ThroneShaders.Bloom = nil
            ThroneShaders.ColorCorrection = nil
            ThroneShaders.Atmosphere = nil
            ThroneShaders.ActiveSky = nil
        end
    end

    -- Restore saved skybox
    if ThroneShaders.SavedSky then
        pcall(function() ThroneShaders.SavedSky.Parent = Lighting end)
        ThroneShaders.SavedSky = nil
    end

    ThroneShaders.OriginalLighting = nil
    ThroneShaders.Enabled = false
end

function ThroneShaders.triggerFlash(duration)
    if not ThroneShaders.Enabled then
        ThroneShaders.enable()
    end

    if not PlayerGui and LocalPlayer then
        PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    end

    if not ThroneShaders.FlashGui and PlayerGui then
        local gui = Instance.new("ScreenGui")
        gui.Name = "Darling_ThroneFlashGui"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = 999999

        local frame = Instance.new("Frame")
        frame.Name = "FlashFrame"
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundColor3 = Color3.fromRGB(240, 220, 255)
        frame.BackgroundTransparency = 1.0
        frame.BorderSizePixel = 0
        frame.Parent = gui

        gui.Parent = PlayerGui
        ThroneShaders.FlashGui = gui
        ThroneShaders.FlashFrame = frame
    end

    local flashDur = (type(duration) == "number" and duration) or 1.8

    if ThroneShaders.FlashFrame then
        ThroneShaders.FlashFrame.BackgroundTransparency = 0.0
        local twInfo = TweenInfo.new(flashDur, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        TweenService:Create(ThroneShaders.FlashFrame, twInfo, { BackgroundTransparency = 1.0 }):Play()
    end

    if ThroneShaders.Bloom then
        ThroneShaders.Bloom.Intensity = 8.5
        local twBloom = TweenInfo.new(flashDur, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        TweenService:Create(ThroneShaders.Bloom, twBloom, { Intensity = BLOOM_CONFIG.Intensity }):Play()
    end

    if ThroneShaders.ColorCorrection then
        ThroneShaders.ColorCorrection.Brightness = 0.75
        local twCC = TweenInfo.new(flashDur, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        TweenService:Create(ThroneShaders.ColorCorrection, twCC, { Brightness = COLOR_CORRECTION_CONFIG.Brightness }):Play()
    end
end

function ThroneShaders.destroy()
    ThroneShaders.disable(false)

    if ThroneShaders.FlashGui then
        pcall(function() ThroneShaders.FlashGui:Destroy() end)
        ThroneShaders.FlashGui = nil
        ThroneShaders.FlashFrame = nil
    end

    for _, eff in ipairs(ThroneShaders.CreatedEffects) do
        pcall(function() eff:Destroy() end)
    end
    ThroneShaders.CreatedEffects = {}
    ThroneShaders.Bloom = nil
    ThroneShaders.ColorCorrection = nil
    ThroneShaders.Atmosphere = nil
    ThroneShaders.ActiveSky = nil
    ThroneShaders.SavedSky = nil
    ThroneShaders.OriginalLighting = nil
    ThroneShaders.Enabled = false
end

function ThroneShaders.toggle(state)
    if state == nil then
        state = not ThroneShaders.Enabled
    end
    if state then
        ThroneShaders.enable()
    else
        ThroneShaders.disable()
    end
    return ThroneShaders.Enabled
end

function ThroneShaders.isEnabled()
    return ThroneShaders.Enabled
end

return ThroneShaders
