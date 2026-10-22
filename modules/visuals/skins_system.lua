-- skins engine
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local DarlingSkins = {
    VFX = {
        Enabled = false,
        AffectSkills = true,
        AffectSwords = true,
        AffectTransform = true,
        AffectEnvironment = false,
        ActiveColor = Color3.fromRGB(255, 105, 180),
        Originals = {},
        Connections = {},
    },
    Tools = {
        SelectedCategory = "Fruits",
        EquippedSkins = {
            Fruits = nil,
            Swords = nil,
            Guns = nil,
            Melee = nil,
        },
        HotbarCache = {},
        Listeners = {},
        CustomAssetId = "",
    },
    Character = {
        Enabled = false,
        ActivePreset = "Darling Pink",
        ActiveColor = Color3.fromRGB(255, 105, 180),
        Material = Enum.Material.SmoothPlastic,
        AuraEnabled = false,
        AuraHighlight = nil,
        OriginalColors = {},
        OriginalMaterials = {},
    }
}

-- Color Presets Dictionary
DarlingSkins.Presets = {
    ["Darling Pink"] = Color3.fromRGB(255, 105, 180),
    ["Purple"] = Color3.fromRGB(165, 80, 235),
    ["Red"] = Color3.fromRGB(240, 40, 50),
    ["Blue"] = Color3.fromRGB(40, 120, 255),
    ["Cyan"] = Color3.fromRGB(0, 240, 255),
    ["Green"] = Color3.fromRGB(50, 220, 120),
    ["Gold"] = Color3.fromRGB(245, 195, 45),
    ["Magenta"] = Color3.fromRGB(255, 30, 140),
    ["White"] = Color3.fromRGB(255, 255, 255),
    ["Black"] = Color3.fromRGB(20, 20, 25),
    ["Midnight"] = Color3.fromRGB(45, 35, 55),
    ["Violet"] = Color3.fromRGB(110, 40, 190),
    ["Lime"] = Color3.fromRGB(130, 255, 50),
    ["Orange"] = Color3.fromRGB(255, 140, 30),
    ["Silver"] = Color3.fromRGB(200, 205, 215),
    ["Crimson"] = Color3.fromRGB(180, 20, 35),
    ["Yellow"] = Color3.fromRGB(255, 235, 60),
    ["Teal"] = Color3.fromRGB(30, 190, 180),
    ["Ice Blue"] = Color3.fromRGB(90, 215, 245),
}

-- Skin Catalog
DarlingSkins.SkinCatalog = {
    { Name = "Darling Signature", Color = Color3.fromRGB(255, 105, 180) },
    { Name = "Pure White", Color = Color3.fromRGB(255, 255, 255) },
    { Name = "Pure Amethyst", Color = Color3.fromRGB(165, 80, 235) },
    { Name = "Emerald Empress", Color = Color3.fromRGB(50, 220, 120) },
    { Name = "Golden Sovereign", Color = Color3.fromRGB(245, 195, 45) },
    { Name = "Crimson Phantom", Color = Color3.fromRGB(235, 45, 65) },
    { Name = "Frost Diamond", Color = Color3.fromRGB(90, 215, 245) },
    { Name = "Cyber Neon", Color = Color3.fromRGB(255, 30, 140) },
    { Name = "Midnight Shadow", Color = Color3.fromRGB(45, 35, 55) },
    { Name = "Blood Moon", Color = Color3.fromRGB(180, 20, 35) },
    { Name = "Electric Blue", Color = Color3.fromRGB(40, 120, 255) },
    { Name = "Solar Flare", Color = Color3.fromRGB(255, 140, 30) },
    { Name = "Toxic Lime", Color = Color3.fromRGB(130, 255, 50) },
    { Name = "Void Purple", Color = Color3.fromRGB(110, 40, 190) },
    { Name = "Rose Quartz", Color = Color3.fromRGB(245, 130, 180) },
    { Name = "Galaxy Astral", Color = Color3.fromRGB(180, 100, 255) },
    { Name = "Dark Matter", Color = Color3.fromRGB(120, 50, 180) },
    { Name = "Sakura Blossom", Color = Color3.fromRGB(255, 130, 190) },
    { Name = "Ice Void", Color = Color3.fromRGB(80, 210, 240) },
}

DarlingSkins.WeaponLists = {
    Fruits = {
        "Auto", "Kitsune", "Dragon", "Dough", "Venom", "Control", "Spirit", "Shadow", "Blizzard", "Gravity",
        "Mammoth", "T-Rex", "Sound", "Phoenix", "Portal", "Rumble", "Pain", "Buddha", "Quake", "Magma",
        "Ghost", "Barrier", "Rubber", "Light", "Diamond", "Dark", "Sand", "Ice", "Falcon", "Flame",
        "Spike", "Smoke", "Bomb", "Spring", "Chop", "Spin", "Rocket", "Yeti"
    },
    Swords = {
        "Auto", "Cursed Dual Katana", "True Triple Katana", "Shark Anchor", "Dark Blade",
        "Fox Lamp", "Hallow Scythe", "Tushita", "Yama", "Spikey Trident",
        "Dragon Trident", "Saber", "Rengoku", "Bisento", "Pole (2nd Form)",
        "Midnight Blade", "Soul Cane", "Gravity Cane", "Canvander", "Buddy Sword",
        "Koko", "Shisui", "Wando", "Saddi", "Longsword", "Triple Katana",
        "Iron Mace", "Dual Katana", "Katana", "Cutlass"
    },
    Guns = {
        "Auto", "Soul Guitar", "Serpent Bow", "Kabucha", "Acidum Rifle", "Bizarre Rifle",
        "Bazooka", "Refined Slingshot", "Flintlock", "Cannon", "Musket", "Slingshot"
    },
    Melee = {
        "Auto", "Sanguine Art", "Godhuman", "Dragon Talon", "Electric Claw", "Sharkman Karate",
        "Death Step", "Superhuman", "Dragon Breath", "Water Kung Fu", "Electro",
        "Dark Step", "Combat"
    }
}

DarlingSkins.CategoryTips = {
    Fruits = "Blox Fruit",
    Swords = "Sword",
    Guns = "Gun",
    Melee = "Melee"
}

-- ============================================================================
-- SECTION 1: VFX & SKILL COLORING
-- ============================================================================
local function recordOriginal(inst, prop)
    if not DarlingSkins.VFX.Originals[inst] then
        DarlingSkins.VFX.Originals[inst] = {}
    end
    if DarlingSkins.VFX.Originals[inst][prop] == nil then
        pcall(function()
            DarlingSkins.VFX.Originals[inst][prop] = inst[prop]
        end)
    end
end

local function applyVisualColor(inst, targetColor)
    if not inst or not inst.Parent then return end
    targetColor = targetColor or DarlingSkins.VFX.ActiveColor

    pcall(function()
        if inst:IsA("ParticleEmitter") then
            if not DarlingSkins.VFX.AffectSkills then return end
            recordOriginal(inst, "Color")
            recordOriginal(inst, "LightEmission")
            inst.Color = ColorSequence.new(targetColor)
            inst.LightEmission = 0.8
        elseif inst:IsA("Beam") or inst:IsA("Trail") then
            if not DarlingSkins.VFX.AffectSkills and not DarlingSkins.VFX.AffectSwords then return end
            recordOriginal(inst, "Color")
            recordOriginal(inst, "LightEmission")
            inst.Color = ColorSequence.new(targetColor)
            inst.LightEmission = 0.8
        elseif inst:IsA("Highlight") then
            if not DarlingSkins.VFX.AffectTransform then return end
            recordOriginal(inst, "FillColor")
            recordOriginal(inst, "OutlineColor")
            inst.FillColor = targetColor
            inst.OutlineColor = Color3.fromRGB(255, 255, 255)
        elseif inst:IsA("Light") then
            if not DarlingSkins.VFX.AffectSkills then return end
            recordOriginal(inst, "Color")
            inst.Color = targetColor
        elseif inst:IsA("Decal") or inst:IsA("Texture") then
            if not DarlingSkins.VFX.AffectSkills then return end
            recordOriginal(inst, "Color3")
            inst.Color3 = targetColor
        elseif inst:IsA("SpecialMesh") then
            if not DarlingSkins.VFX.AffectSwords then return end
            recordOriginal(inst, "VertexColor")
            inst.VertexColor = Vector3.new(targetColor.R, targetColor.G, targetColor.B)
        end
    end)
end

local function scanAndApply(root, targetColor)
    if not root then return end
    applyVisualColor(root, targetColor)
    local descs = root:GetDescendants()
    for i = 1, #descs do
        applyVisualColor(descs[i], targetColor)
        if i % 300 == 0 then
            task.wait()
        end
    end
end

function DarlingSkins.refreshAllVFX()
    if not DarlingSkins.VFX.Enabled then return end
    task.spawn(function()
        local col = DarlingSkins.VFX.ActiveColor
        local char = LocalPlayer.Character
        if char then scanAndApply(char, col) end

        local wo = Workspace:FindFirstChild("_WorldOrigin")
        if wo and (DarlingSkins.VFX.AffectEnvironment or DarlingSkins.VFX.AffectSkills or DarlingSkins.VFX.AffectSwords) then
            scanAndApply(wo, col)
        end

        local fx = Workspace:FindFirstChild("Effects") or Workspace:FindFirstChild("FX")
        if fx and DarlingSkins.VFX.AffectSkills then
            scanAndApply(fx, col)
        end
    end)
end

function DarlingSkins.stopVFXWatchers()
    for _, conn in ipairs(DarlingSkins.VFX.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(DarlingSkins.VFX.Connections)
end

function DarlingSkins.startVFXWatchers()
    DarlingSkins.stopVFXWatchers()

    local function bindWorld(wo)
        if not wo then return end
        table.insert(DarlingSkins.VFX.Connections, wo.DescendantAdded:Connect(function(child)
            if DarlingSkins.VFX.Enabled and (DarlingSkins.VFX.AffectEnvironment or DarlingSkins.VFX.AffectSkills or DarlingSkins.VFX.AffectSwords) then
                task.defer(applyVisualColor, child, DarlingSkins.VFX.ActiveColor)
            end
        end))
    end

    local function bindChar(char)
        if not char then return end
        table.insert(DarlingSkins.VFX.Connections, char.DescendantAdded:Connect(function(child)
            if DarlingSkins.VFX.Enabled then
                task.defer(applyVisualColor, child, DarlingSkins.VFX.ActiveColor)
            end
        end))
    end

    local wo = Workspace:FindFirstChild("_WorldOrigin")
    if wo then bindWorld(wo) end
    table.insert(DarlingSkins.VFX.Connections, Workspace.ChildAdded:Connect(function(child)
        if child.Name == "_WorldOrigin" then
            bindWorld(child)
            if DarlingSkins.VFX.Enabled then scanAndApply(child, DarlingSkins.VFX.ActiveColor) end
        end
    end))

    local char = LocalPlayer.Character
    if char then bindChar(char) end
    table.insert(DarlingSkins.VFX.Connections, LocalPlayer.CharacterAdded:Connect(function(newChar)
        bindChar(newChar)
        if DarlingSkins.VFX.Enabled then
            task.delay(0.2, function() scanAndApply(newChar, DarlingSkins.VFX.ActiveColor) end)
        end
    end))

    local fx = Workspace:FindFirstChild("Effects") or Workspace:FindFirstChild("FX")
    if fx then
        table.insert(DarlingSkins.VFX.Connections, fx.DescendantAdded:Connect(function(child)
            if DarlingSkins.VFX.Enabled and DarlingSkins.VFX.AffectSkills then
                task.defer(applyVisualColor, child, DarlingSkins.VFX.ActiveColor)
            end
        end))
    end
end

function DarlingSkins.resetOriginalVFX()
    for inst, props in pairs(DarlingSkins.VFX.Originals) do
        if inst and inst.Parent then
            pcall(function()
                for pName, pVal in pairs(props) do
                    inst[pName] = pVal
                end
            end)
        end
    end
    table.clear(DarlingSkins.VFX.Originals)
end

function DarlingSkins.setVFXEnabled(enabled)
    DarlingSkins.VFX.Enabled = enabled
    if enabled then
        DarlingSkins.startVFXWatchers()
        DarlingSkins.refreshAllVFX()
    else
        DarlingSkins.stopVFXWatchers()
        DarlingSkins.resetOriginalVFX()
    end
end

function DarlingSkins.setVFXColor(color)
    DarlingSkins.VFX.ActiveColor = color
    if DarlingSkins.VFX.Enabled then
        DarlingSkins.refreshAllVFX()
    end
end

-- ============================================================================
-- SECTION 2: TOOL SKINS & HOTBAR
-- ============================================================================
local function findHotbarSlot(category, targetItem)
    local pGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pGui then return nil, nil end

    local mainGui = pGui:FindFirstChild("Main")
    local hotbar = mainGui and (mainGui:FindFirstChild("Hotbar") or mainGui:FindFirstChild("ToolBar"))
    if not hotbar then
        hotbar = pGui:FindFirstChild("Hotbar", true)
    end
    if not hotbar then return nil, nil end

    local slotOrder = { Fruits = 2, Swords = 3, Guns = 4, Melee = 1 }

    local candidates = {}
    for _, desc in ipairs(hotbar:GetDescendants()) do
        if desc:IsA("ImageLabel") or desc:IsA("ImageButton") then
            local parentName = string.lower(desc.Parent and desc.Parent.Name or "")
            local selfName = string.lower(desc.Name)
            if selfName:find("icon") or parentName:find("slot") or parentName:find("item") then
                table.insert(candidates, desc)
            end
        end
    end

    if #candidates > 0 then
        local targetIdx = slotOrder[category] or 1
        if candidates[targetIdx] then
            return candidates[targetIdx], targetIdx
        end
        return candidates[1], 1
    end

    return nil, nil
end

function DarlingSkins.applyToolSkin(category, skinName, customColor)
    category = category or DarlingSkins.Tools.SelectedCategory or "Fruits"
    local skin = nil
    if typeof(skinName) == "table" and skinName.Color then
        skin = skinName
    else
        for _, s in ipairs(DarlingSkins.SkinCatalog) do
            if s.Name == skinName then skin = s break end
        end
    end
    if not skin then
        local col = customColor or DarlingSkins.Presets[skinName] or Color3.fromRGB(255, 105, 180)
        skin = { Name = tostring(skinName), Color = col }
    end

    -- Recolor hotbar slot icon
    local img, _ = findHotbarSlot(category)
    if img then
        if not DarlingSkins.Tools.HotbarCache[img] then
            DarlingSkins.Tools.HotbarCache[img] = {
                ImageColor3 = img.ImageColor3,
                Image = img.Image
            }
        end
        img.ImageColor3 = skin.Color

        if DarlingSkins.Tools.CustomAssetId ~= "" then
            pcall(function() img.Image = DarlingSkins.Tools.CustomAssetId end)
        end

        if DarlingSkins.Tools.Listeners[category] then
            pcall(function() DarlingSkins.Tools.Listeners[category]:Disconnect() end)
        end
        DarlingSkins.Tools.Listeners[category] = img:GetPropertyChangedSignal("ImageColor3"):Connect(function()
            local eq = DarlingSkins.Tools.EquippedSkins[category]
            if eq and eq.Color and img.ImageColor3 ~= eq.Color then
                img.ImageColor3 = eq.Color
            end
        end)
    end

    -- Recolor equipped and backpack tools
    pcall(function()
        local targetTip = DarlingSkins.CategoryTips[category]
        local tools = {}
        local char = LocalPlayer.Character
        local bp = LocalPlayer:FindFirstChildOfClass("Backpack")

        if char then
            for _, c in ipairs(char:GetChildren()) do
                if c:IsA("Tool") and (c.ToolTip == targetTip or tostring(c:GetAttribute("WeaponType")) == targetTip or tostring(c:GetAttribute("ItemType")) == targetTip) then
                    table.insert(tools, c)
                end
            end
        end
        if bp then
            for _, c in ipairs(bp:GetChildren()) do
                if c:IsA("Tool") and (c.ToolTip == targetTip or tostring(c:GetAttribute("WeaponType")) == targetTip or tostring(c:GetAttribute("ItemType")) == targetTip) then
                    table.insert(tools, c)
                end
            end
        end

        for _, tool in ipairs(tools) do
            for _, part in ipairs(tool:GetDescendants()) do
                if part:IsA("SpecialMesh") then
                    part.VertexColor = Vector3.new(skin.Color.R, skin.Color.G, skin.Color.B)
                elseif part:IsA("BasePart") then
                    part.Color = skin.Color
                end
            end
        end
    end)

    DarlingSkins.Tools.EquippedSkins[category] = skin
    return true
end

function DarlingSkins.resetCategoryToolSkin(category)
    category = category or DarlingSkins.Tools.SelectedCategory or "Fruits"
    if DarlingSkins.Tools.Listeners[category] then
        pcall(function() DarlingSkins.Tools.Listeners[category]:Disconnect() end)
        DarlingSkins.Tools.Listeners[category] = nil
    end

    local img, _ = findHotbarSlot(category)
    if img and DarlingSkins.Tools.HotbarCache[img] then
        pcall(function()
            img.ImageColor3 = DarlingSkins.Tools.HotbarCache[img].ImageColor3
            img.Image = DarlingSkins.Tools.HotbarCache[img].Image
        end)
    end

    DarlingSkins.Tools.EquippedSkins[category] = nil
end

function DarlingSkins.resetAllToolSkins()
    for cat, _ in pairs(DarlingSkins.Tools.EquippedSkins) do
        DarlingSkins.resetCategoryToolSkin(cat)
    end
end

-- ============================================================================
-- SECTION 3: CHARACTER SKIN CHANGER
-- ============================================================================
function DarlingSkins.applyCharacterSkin(presetName, customColor)
    local col = customColor or DarlingSkins.Presets[presetName] or Color3.fromRGB(255, 105, 180)
    DarlingSkins.Character.ActivePreset = presetName or "Custom"
    DarlingSkins.Character.ActiveColor = col
    DarlingSkins.Character.Enabled = true

    local char = LocalPlayer.Character
    if not char then return end

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            if not DarlingSkins.Character.OriginalColors[part] then
                DarlingSkins.Character.OriginalColors[part] = part.Color
                DarlingSkins.Character.OriginalMaterials[part] = part.Material
            end
            part.Color = col
            if DarlingSkins.Character.Material then
                part.Material = DarlingSkins.Character.Material
            end
        end
    end

    -- Character Aura Highlight
    if DarlingSkins.Character.AuraEnabled then
        if not DarlingSkins.Character.AuraHighlight or not DarlingSkins.Character.AuraHighlight.Parent then
            local hl = Instance.new("Highlight")
            hl.Name = "DarlingCharacterAura"
            hl.FillColor = col
            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
            hl.FillTransparency = 0.4
            hl.OutlineTransparency = 0.1
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Parent = char
            DarlingSkins.Character.AuraHighlight = hl
        else
            DarlingSkins.Character.AuraHighlight.FillColor = col
        end
    end
end

function DarlingSkins.resetCharacterSkin()
    DarlingSkins.Character.Enabled = false
    local char = LocalPlayer.Character
    if not char then return end

    for part, origCol in pairs(DarlingSkins.Character.OriginalColors) do
        if part and part.Parent then
            pcall(function()
                part.Color = origCol
                if DarlingSkins.Character.OriginalMaterials[part] then
                    part.Material = DarlingSkins.Character.OriginalMaterials[part]
                end
            end)
        end
    end
    table.clear(DarlingSkins.Character.OriginalColors)
    table.clear(DarlingSkins.Character.OriginalMaterials)

    if DarlingSkins.Character.AuraHighlight and DarlingSkins.Character.AuraHighlight.Parent then
        pcall(function() DarlingSkins.Character.AuraHighlight:Destroy() end)
    end
    DarlingSkins.Character.AuraHighlight = nil
end

function DarlingSkins.setAuraEnabled(state)
    DarlingSkins.Character.AuraEnabled = state
    if state then
        DarlingSkins.applyCharacterSkin(DarlingSkins.Character.ActivePreset, DarlingSkins.Character.ActiveColor)
    else
        if DarlingSkins.Character.AuraHighlight and DarlingSkins.Character.AuraHighlight.Parent then
            pcall(function() DarlingSkins.Character.AuraHighlight:Destroy() end)
        end
        DarlingSkins.Character.AuraHighlight = nil
    end
end

-- Re-apply skin on character respawn
LocalPlayer.CharacterAdded:Connect(function(newChar)
    if DarlingSkins.Character.Enabled then
        task.delay(0.3, function()
            DarlingSkins.applyCharacterSkin(DarlingSkins.Character.ActivePreset, DarlingSkins.Character.ActiveColor)
        end)
    end
end)

return DarlingSkins
