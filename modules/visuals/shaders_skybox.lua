--[[
    Darling Hub - Shaders & Skybox Environment Module
    High-fidelity RTX post-processing shaders and 14 ultra HD custom skybox environments.
]]--

local Lighting = game:GetService("Lighting")

local ShadersSkybox = {
    ShadersEnabled = false,
    CurrentPreset = "RTX ULTRA",
    SkyboxEnabled = false,
    CurrentSkybox = "Galaxy",

    ColorCorrection = nil,
    Bloom = nil,
    ActiveSky = nil,
}

local SHADER_PRESETS = {
    ["RTX ULTRA"]   = { contrast = 0.15, sat = 0.30, bright = 0.03, bloomI = 0.9 },
    ["RTX REFLECT"] = { contrast = 0.18, sat = 0.22, bright = 0.05, bloomI = 1.2 },
    ["REALISTIC"]   = { contrast = 0.08, sat = 0.15, bright = 0.00, bloomI = 0.6 },
    ["CINEMATIC"]   = { contrast = 0.22, sat = -0.05, bright = -0.02, bloomI = 1.1 },
    ["VIBRANT"]     = { contrast = 0.12, sat = 0.45, bright = 0.05, bloomI = 0.8 },
    ["SUNSET"]      = { contrast = 0.14, sat = 0.30, bright = 0.02, bloomI = 1.3 },
    ["NIGHT"]       = { contrast = 0.15, sat = 0.10, bright = -0.08, bloomI = 0.5 },
    ["GOLDEN"]      = { contrast = 0.10, sat = 0.20, bright = 0.02, bloomI = 1.0 },
}

local SKYBOX_PRESETS = {
    ["Galaxy"]         = { up="rbxassetid://159454288", lf="rbxassetid://159454293", ft="rbxassetid://159454293", dn="rbxassetid://159454296", bk="rbxassetid://159454299", rt="rbxassetid://159454293" },
    ["Purple Night"]   = { up="rbxassetid://5084576400", bk="rbxassetid://5260808177", ft="rbxassetid://5260817288", dn="rbxassetid://5260653793", lf="rbxassetid://5260800833", rt="rbxassetid://5260800833" },
    ["Blue Space"]     = { up="rbxassetid://16876552681", bk="rbxassetid://16876541778", lf="rbxassetid://16876548320", ft="rbxassetid://16876546384", dn="rbxassetid://16876543880", rt="rbxassetid://16876550345" },
    ["Flaming Sunset"] = { up="rbxassetid://415688354", ft="rbxassetid://415688242", bk="rbxassetid://415688378", dn="rbxassetid://415688193", lf="rbxassetid://415688310", rt="rbxassetid://415688274" },
    ["Nebula"]         = { up="rbxassetid://155674931", ft="rbxassetid://155657609", bk="rbxassetid://155657655", lf="rbxassetid://155657671", dn="rbxassetid://155674246", rt="rbxassetid://155657619" },
    ["Evening Glow"]   = { up="rbxassetid://173380790", bk="rbxassetid://173380597", dn="rbxassetid://173380627", ft="rbxassetid://173380642", lf="rbxassetid://173380671", rt="rbxassetid://173380774" },
    ["Sci-Fi Stars"]   = { up="rbxassetid://401664936", ft="rbxassetid://401664960", bk="rbxassetid://401664839", lf="rbxassetid://401664881", dn="rbxassetid://401664862", rt="rbxassetid://401664901" },
    ["Pink Cloud"]     = { up="rbxassetid://5260824661", dn="rbxassetid://5260653793", lf="rbxassetid://5260800833", bk="rbxassetid://5260808177", ft="rbxassetid://5260817288", rt="rbxassetid://5260811073" },
    ["Space Nebula"]   = { up="rbxassetid://402560052", bk="rbxassetid://402559900", ft="rbxassetid://402559953", dn="rbxassetid://402559927", lf="rbxassetid://402559983", rt="rbxassetid://402560019" },
    ["Red Planet"]     = { up="rbxassetid://4495867486", rt="rbxassetid://4495866584", lf="rbxassetid://4495866035", dn="rbxassetid://4495864887", ft="rbxassetid://4495865458", bk="rbxassetid://4495864450" },
    ["Arctic Dawn"]    = { up="rbxassetid://11457548274", bk="rbxassetid://11457548274", ft="rbxassetid://11457548274", dn="rbxassetid://11457548274", lf="rbxassetid://11457548274", rt="rbxassetid://11457548274" },
    ["Deep Void"]      = { up="rbxassetid://15359412677", dn="rbxassetid://15359411132", lf="rbxassetid://15359411633", bk="rbxassetid://15359410490", ft="rbxassetid://15359412131", rt="rbxassetid://15359417656" },
    ["Cloudscape"]     = { up="rbxassetid://154185031", bk="rbxassetid://154185004", ft="rbxassetid://154185021", dn="rbxassetid://154184960", lf="rbxassetid://154184943", rt="rbxassetid://154184972" },
    ["Dark Space"]     = { up="rbxassetid://252763920", bk="rbxassetid://252763920", ft="rbxassetid://252763920", dn="rbxassetid://252763920", lf="rbxassetid://252763920", rt="rbxassetid://252763920" },
}

local function getShaders()
    if not ShadersSkybox.ColorCorrection or not ShadersSkybox.ColorCorrection.Parent then
        local cc = Lighting:FindFirstChild("Darling_RTX_CC") or Instance.new("ColorCorrectionEffect")
        cc.Name = "Darling_RTX_CC"
        cc.Parent = Lighting
        ShadersSkybox.ColorCorrection = cc
    end
    if not ShadersSkybox.Bloom or not ShadersSkybox.Bloom.Parent then
        local bloom = Lighting:FindFirstChild("Darling_RTX_Bloom") or Instance.new("BloomEffect")
        bloom.Name = "Darling_RTX_Bloom"
        bloom.Size = 24
        bloom.Parent = Lighting
        ShadersSkybox.Bloom = bloom
    end
    return ShadersSkybox.ColorCorrection, ShadersSkybox.Bloom
end

function ShadersSkybox.applyShaders()
    local cc, bloom = getShaders()
    if ShadersSkybox.ShadersEnabled then
        local p = SHADER_PRESETS[ShadersSkybox.CurrentPreset] or SHADER_PRESETS["RTX ULTRA"]
        cc.Contrast = p.contrast
        cc.Saturation = p.sat
        cc.Brightness = p.bright
        cc.Enabled = true

        bloom.Intensity = p.bloomI
        bloom.Size = 24
        bloom.Enabled = true
    else
        cc.Enabled = false
        bloom.Enabled = false
    end
end

function ShadersSkybox.setShaders(state, preset)
    ShadersSkybox.ShadersEnabled = state
    if preset then ShadersSkybox.CurrentPreset = preset end
    ShadersSkybox.applyShaders()
end

function ShadersSkybox.applySkybox()
    if ShadersSkybox.SkyboxEnabled then
        local p = SKYBOX_PRESETS[ShadersSkybox.CurrentSkybox]
        if p then
            if not ShadersSkybox.ActiveSky or ShadersSkybox.ActiveSky.Parent ~= Lighting then
                if ShadersSkybox.ActiveSky then pcall(function() ShadersSkybox.ActiveSky:Destroy() end) end
                local sky = Instance.new("Sky")
                sky.Name = "Darling_CustomSkybox"
                sky.SkyboxBk = p.bk
                sky.SkyboxDn = p.dn
                sky.SkyboxFt = p.ft
                sky.SkyboxLf = p.lf
                sky.SkyboxRt = p.rt
                sky.SkyboxUp = p.up
                sky.Parent = Lighting
                ShadersSkybox.ActiveSky = sky
            else
                ShadersSkybox.ActiveSky.SkyboxBk = p.bk
                ShadersSkybox.ActiveSky.SkyboxDn = p.dn
                ShadersSkybox.ActiveSky.SkyboxFt = p.ft
                ShadersSkybox.ActiveSky.SkyboxLf = p.lf
                ShadersSkybox.ActiveSky.SkyboxRt = p.rt
                ShadersSkybox.ActiveSky.SkyboxUp = p.up
            end
            pcall(function() Lighting.ClockTime = 12 end)
        end
    else
        if ShadersSkybox.ActiveSky then
            pcall(function() ShadersSkybox.ActiveSky:Destroy() end)
            ShadersSkybox.ActiveSky = nil
        end
    end
end

function ShadersSkybox.setSkybox(state, choice)
    ShadersSkybox.SkyboxEnabled = state
    if choice then ShadersSkybox.CurrentSkybox = choice end
    ShadersSkybox.applySkybox()
end

return ShadersSkybox
