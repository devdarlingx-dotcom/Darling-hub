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
        Originals = setmetatable({}, { __mode = "k" }),
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
        AllSlotsCache = {},
        AllSlotsListeners = {},
        GlobalSkin = nil,
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
    ["White"] = Color3.fromRGB(255, 255, 255),
    ["Black"] = Color3.fromRGB(20, 20, 24),
    ["Purple"] = Color3.fromRGB(165, 80, 235),
    ["Red"] = Color3.fromRGB(235, 45, 65),
    ["Blue"] = Color3.fromRGB(40, 120, 255),
    ["Cyan"] = Color3.fromRGB(0, 220, 245),
    ["Green"] = Color3.fromRGB(50, 220, 120),
    ["Gold"] = Color3.fromRGB(245, 195, 45),
    ["Pink"] = Color3.fromRGB(255, 105, 180),
    ["Orange"] = Color3.fromRGB(255, 140, 30),
    ["Crimson"] = Color3.fromRGB(180, 20, 35),
    ["Lime"] = Color3.fromRGB(130, 255, 50),
    ["Magenta"] = Color3.fromRGB(255, 30, 140),
    ["Midnight"] = Color3.fromRGB(35, 35, 48),
    ["Silver"] = Color3.fromRGB(215, 225, 245),
    ["Teal"] = Color3.fromRGB(0, 210, 190),
    ["Ice Blue"] = Color3.fromRGB(160, 225, 255),
    -- Backward compatibility aliases
    ["Darling Pink"] = Color3.fromRGB(255, 105, 180),
    ["Darling Signature"] = Color3.fromRGB(255, 105, 180),
    ["Pure White"] = Color3.fromRGB(255, 255, 255),
    ["Void Black"] = Color3.fromRGB(20, 20, 24),
    ["Pure Amethyst"] = Color3.fromRGB(165, 80, 235),
    ["Emerald Empress"] = Color3.fromRGB(50, 220, 120),
    ["Golden Sovereign"] = Color3.fromRGB(245, 195, 45),
    ["Crimson Phantom"] = Color3.fromRGB(235, 45, 65),
    ["Frost Diamond"] = Color3.fromRGB(90, 215, 245),
    ["Cyber Neon"] = Color3.fromRGB(255, 30, 140),
    ["Midnight Shadow"] = Color3.fromRGB(45, 35, 55),
    ["Blood Moon"] = Color3.fromRGB(180, 20, 35),
    ["Electric Blue"] = Color3.fromRGB(40, 120, 255),
    ["Solar Flare"] = Color3.fromRGB(255, 140, 30),
    ["Toxic Lime"] = Color3.fromRGB(130, 255, 50),
    ["Void Purple"] = Color3.fromRGB(110, 40, 190),
    ["Rose Quartz"] = Color3.fromRGB(245, 130, 180),
    ["Galaxy Astral"] = Color3.fromRGB(180, 100, 255),
    ["Dark Matter"] = Color3.fromRGB(120, 50, 180),
    ["Sakura Blossom"] = Color3.fromRGB(255, 130, 190),
    ["Ice Void"] = Color3.fromRGB(80, 210, 240),
}

-- Skin Catalog (Clean, standard, accurate color names)
DarlingSkins.SkinCatalog = {
    { Name = "White", Color = Color3.fromRGB(255, 255, 255) },
    { Name = "Black", Color = Color3.fromRGB(20, 20, 24) },
    { Name = "Purple", Color = Color3.fromRGB(165, 80, 235) },
    { Name = "Red", Color = Color3.fromRGB(235, 45, 65) },
    { Name = "Blue", Color = Color3.fromRGB(40, 120, 255) },
    { Name = "Cyan", Color = Color3.fromRGB(0, 220, 245) },
    { Name = "Green", Color = Color3.fromRGB(50, 220, 120) },
    { Name = "Gold", Color = Color3.fromRGB(245, 195, 45) },
    { Name = "Pink", Color = Color3.fromRGB(255, 105, 180) },
    { Name = "Orange", Color = Color3.fromRGB(255, 140, 30) },
    { Name = "Crimson", Color = Color3.fromRGB(180, 20, 35) },
    { Name = "Lime", Color = Color3.fromRGB(130, 255, 50) },
    { Name = "Magenta", Color = Color3.fromRGB(255, 30, 140) },
    { Name = "Midnight", Color = Color3.fromRGB(35, 35, 48) },
    { Name = "Silver", Color = Color3.fromRGB(215, 225, 245) },
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
local function blendColor(baseColor, targetColor)
    if typeof(baseColor) ~= "Color3" then return targetColor end
    if targetColor.R > 0.92 and targetColor.G > 0.92 and targetColor.B > 0.92 then
        return Color3.fromRGB(255, 255, 255)
    end
    local h, s, v = targetColor:ToHSV()
    local lum = math.clamp(baseColor.R * 0.2126 + baseColor.G * 0.7152 + baseColor.B * 0.0722, 0, 1)
    local val = math.clamp(v * (0.35 + 0.65 * math.sqrt(lum)), 0.05, 1)
    local recolored = Color3.fromHSV(h, s, val)
    return baseColor:Lerp(recolored, 1.0)
end

local function blendColorSequence(origSeq, targetColor)
    if typeof(origSeq) ~= "ColorSequence" then return ColorSequence.new(targetColor) end
    if targetColor.R > 0.92 and targetColor.G > 0.92 and targetColor.B > 0.92 then
        return ColorSequence.new(Color3.fromRGB(255, 255, 255))
    end
    local keypoints = {}
    for _, kp in ipairs(origSeq.Keypoints) do
        table.insert(keypoints, ColorSequenceKeypoint.new(kp.Time, blendColor(kp.Value, targetColor)))
    end
    return ColorSequence.new(keypoints)
end

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

local function isVisualObject(child)
    return child:IsA("ParticleEmitter") or child:IsA("Beam") or child:IsA("Trail")
        or child:IsA("Highlight") or child:IsA("SpecialMesh") or child:IsA("Decal")
        or child:IsA("Texture") or child:IsA("Light")
end

local function applyVisualColor(inst, targetColor)
    if not inst or not inst.Parent then return end
    targetColor = targetColor or DarlingSkins.VFX.ActiveColor
    local isWhite = (targetColor.R > 0.92 and targetColor.G > 0.92 and targetColor.B > 0.92)
    local isDark = (targetColor.R < 0.2 and targetColor.G < 0.2 and targetColor.B < 0.2)

    pcall(function()
        if inst:IsA("ParticleEmitter") then
            if not DarlingSkins.VFX.AffectSkills then return end
            recordOriginal(inst, "Color")
            local orig = (DarlingSkins.VFX.Originals[inst] and DarlingSkins.VFX.Originals[inst].Color) or inst.Color
            inst.Color = blendColorSequence(orig, targetColor)
            if isWhite then
                recordOriginal(inst, "LightEmission")
                inst.LightEmission = 1
            end
        elseif inst:IsA("Beam") or inst:IsA("Trail") then
            if not DarlingSkins.VFX.AffectSkills and not DarlingSkins.VFX.AffectSwords then return end
            recordOriginal(inst, "Color")
            local orig = (DarlingSkins.VFX.Originals[inst] and DarlingSkins.VFX.Originals[inst].Color) or inst.Color
            inst.Color = blendColorSequence(orig, targetColor)
            if isWhite then
                recordOriginal(inst, "LightEmission")
                inst.LightEmission = 1
            end
        elseif inst:IsA("Highlight") then
            if not DarlingSkins.VFX.AffectTransform then return end
            recordOriginal(inst, "FillColor")
            recordOriginal(inst, "OutlineColor")
            inst.FillColor = targetColor
            inst.OutlineColor = isWhite and Color3.fromRGB(255, 255, 255) or (isDark and Color3.fromRGB(30, 30, 30) or Color3.fromRGB(255, 255, 255))
        elseif inst:IsA("Light") then
            if not DarlingSkins.VFX.AffectSkills then return end
            recordOriginal(inst, "Color")
            inst.Color = targetColor
        elseif inst:IsA("Decal") or inst:IsA("Texture") then
            if not DarlingSkins.VFX.AffectSkills then return end
            recordOriginal(inst, "Color3")
            local dCol = isDark and Color3.fromRGB(55, 55, 60) or targetColor
            inst.Color3 = dCol
        elseif inst:IsA("SpecialMesh") then
            if not DarlingSkins.VFX.AffectSwords then return end
            recordOriginal(inst, "VertexColor")
            if inst.TextureId ~= "" then
                local minLum = 0.35
                local vR = math.clamp(targetColor.R * 0.7 + (isDark and minLum or 0), 0.2, 1)
                local vG = math.clamp(targetColor.G * 0.7 + (isDark and minLum or 0), 0.2, 1)
                local vB = math.clamp(targetColor.B * 0.7 + (isDark and minLum or 0), 0.2, 1)
                inst.VertexColor = Vector3.new(vR, vG, vB)
            else
                inst.VertexColor = Vector3.new(targetColor.R, targetColor.G, targetColor.B)
            end
        end
    end)
end

local vfxScanThread = nil
local vfxScanToken = 0

local function scanAndApply(root, targetColor)
    if not root then return end
    applyVisualColor(root, targetColor)
    local descs = root:GetDescendants()
    local myToken = vfxScanToken
    for i = 1, #descs do
        if myToken ~= vfxScanToken then return end
        applyVisualColor(descs[i], targetColor)
        if i % 300 == 0 then
            task.wait()
        end
    end
end

function DarlingSkins.refreshAllVFX()
    if not DarlingSkins.VFX.Enabled then return end
    if vfxScanThread then
        pcall(function() task.cancel(vfxScanThread) end)
        vfxScanThread = nil
    end
    vfxScanToken = vfxScanToken + 1
    local currentToken = vfxScanToken
    vfxScanThread = task.spawn(function()
        local col = DarlingSkins.VFX.ActiveColor
        local char = LocalPlayer.Character
        if char and currentToken == vfxScanToken then scanAndApply(char, col) end

        local wo = Workspace:FindFirstChild("_WorldOrigin")
        if wo and (DarlingSkins.VFX.AffectEnvironment or DarlingSkins.VFX.AffectSkills or DarlingSkins.VFX.AffectSwords) then
            if currentToken == vfxScanToken then scanAndApply(wo, col) end
        end

        local fx = Workspace:FindFirstChild("Effects") or Workspace:FindFirstChild("FX")
        if fx and DarlingSkins.VFX.AffectSkills then
            if currentToken == vfxScanToken then scanAndApply(fx, col) end
        end
        if currentToken == vfxScanToken then
            vfxScanThread = nil
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
                if isVisualObject(child) then
                    task.defer(applyVisualColor, child, DarlingSkins.VFX.ActiveColor)
                end
            end
        end))
    end

    local function bindChar(char)
        if not char then return end
        table.insert(DarlingSkins.VFX.Connections, char.DescendantAdded:Connect(function(child)
            if DarlingSkins.VFX.Enabled then
                if isVisualObject(child) then
                    task.defer(applyVisualColor, child, DarlingSkins.VFX.ActiveColor)
                end
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
                if isVisualObject(child) then
                    task.defer(applyVisualColor, child, DarlingSkins.VFX.ActiveColor)
                end
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
local CATEGORY_DEFAULT_ITEMS = {
    Fruits = "Bomb-Bomb",
    Swords = "Katana",
    Guns = "Slingshot",
    Melee = "Combat"
}

local function scanPlayerItem(cat)
    local targetTip = DarlingSkins.CategoryTips[cat]
    local char = LocalPlayer.Character
    if char then
        for _, c in ipairs(char:GetChildren()) do
            if c:IsA("Tool") then
                if c.ToolTip == targetTip or tostring(c:GetAttribute("WeaponType")) == targetTip or tostring(c:GetAttribute("ItemType")) == targetTip then
                    return c.Name, "EQUIPPED"
                end
            end
        end
    end
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if bp then
        for _, c in ipairs(bp:GetChildren()) do
            if c:IsA("Tool") then
                if c.ToolTip == targetTip or tostring(c:GetAttribute("WeaponType")) == targetTip or tostring(c:GetAttribute("ItemType")) == targetTip then
                    return c.Name, "IN BAG"
                end
            end
        end
    end
    return "None", "None"
end

function DarlingSkins.getTargetItem(cat)
    cat = cat or DarlingSkins.Tools.SelectedCategory or "Fruits"
    local det, _ = scanPlayerItem(cat)
    if det ~= "None" then return det end
    return CATEGORY_DEFAULT_ITEMS[cat] or "Item"
end

local function getSlotIcon(slot)
    if not slot then return nil end
    for _, name in ipairs({"Icon", "ItemIcon", "ToolIcon", "SkillIcon", "ActionIcon", "FruitIcon"}) do
        local child = slot:FindFirstChild(name)
        if child and (child:IsA("ImageLabel") or child:IsA("ImageButton")) and child.Image ~= "" then
            return child
        end
    end
    local imgChild = slot:FindFirstChild("Image")
    if imgChild and (imgChild:IsA("ImageLabel") or imgChild:IsA("ImageButton")) and imgChild.Image ~= "" then
        return imgChild
    end
    local candidates = {}
    for _, desc in ipairs(slot:GetDescendants()) do
        if (desc:IsA("ImageLabel") or desc:IsA("ImageButton")) and desc.Image ~= "" then
            local n = string.lower(desc.Name)
            local isBg = (n:find("bg") or n:find("back") or n:find("frame") or n:find("border") or n:find("shadow") or n:find("bar") or n:find("cooldown") or n:find("key") or n:find("outline"))
            if not isBg then
                table.insert(candidates, desc)
            end
        end
    end
    if #candidates > 0 then
        table.sort(candidates, function(a, b)
            return (a.ZIndex or 1) > (b.ZIndex or 1)
        end)
        return candidates[1]
    end
    for _, desc in ipairs(slot:GetDescendants()) do
        if (desc:IsA("ImageLabel") or desc:IsA("ImageButton")) and desc.Image ~= "" then
            return desc
        end
    end
    return slot:FindFirstChildOfClass("ImageLabel")
end

local function getHotbarContainers()
    local pGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pGui then return {} end
    local containers = {}
    local function addIfValid(c)
        if c and c:IsA("GuiObject") and not table.find(containers, c) then
            table.insert(containers, c)
        end
    end

    local bpGui = pGui:FindFirstChild("Backpack")
    if bpGui then
        local hotbar = bpGui:FindFirstChild("Hotbar")
        if hotbar then
            addIfValid(hotbar:FindFirstChild("Container"))
            addIfValid(hotbar)
        end
        local inv = bpGui:FindFirstChild("Inventory")
        if inv then
            addIfValid(inv:FindFirstChild("Container"))
            addIfValid(inv)
        end
    end

    local mainGui = pGui:FindFirstChild("Main")
    if mainGui then
        local hotbar = mainGui:FindFirstChild("Hotbar")
        if hotbar then
            addIfValid(hotbar:FindFirstChild("Container"))
            addIfValid(hotbar)
        end
        local bottom = mainGui:FindFirstChild("BottomBar")
        if bottom then
            addIfValid(bottom:FindFirstChild("Container"))
            addIfValid(bottom)
        end
        local inv = mainGui:FindFirstChild("Inventory")
        if inv then
            addIfValid(inv:FindFirstChild("Container"))
            addIfValid(inv)
        end
    end

    return containers
end

local function findHotbarSlot(cat, itemName)
    cat = cat or DarlingSkins.Tools.SelectedCategory or "Fruits"
    if not itemName or itemName == "" then
        itemName = DarlingSkins.getTargetItem(cat)
    end
    local pGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pGui then return nil, nil end

    local targetLower = string.lower(itemName or "")
    local targetSlotIdx = (cat == "Fruits" and 2) or (cat == "Swords" and 3) or (cat == "Guns" and 4) or 1
    local targetTip = string.lower(DarlingSkins.CategoryTips[cat] or "")

    local function checkContainer(container)
        if not container then return nil, nil end
        local slots = {}
        for _, slot in ipairs(container:GetChildren()) do
            if slot:IsA("GuiObject") then
                table.insert(slots, slot)
                local matched = false
                for _, attr in ipairs({"ItemName", "ToolName", "WeaponType", "ItemType", "Name"}) do
                    local val = slot:GetAttribute(attr)
                    if val and targetLower ~= "" and string.lower(tostring(val)):find(targetLower, 1, true) then
                        matched = true
                        break
                    end
                end
                if not matched then
                    for _, child in ipairs(slot:GetDescendants()) do
                        if child:IsA("TextLabel") and child.Text ~= "" then
                            local tLower = string.lower(child.Text)
                            if targetLower ~= "" and tLower:find(targetLower, 1, true) then
                                matched = true
                                break
                            elseif targetTip ~= "" and tLower:find(targetTip, 1, true) then
                                matched = true
                                break
                            end
                        end
                    end
                end
                if not matched and targetLower ~= "" and string.lower(slot.Name):find(targetLower, 1, true) then
                    matched = true
                end
                if matched then
                    local img = getSlotIcon(slot)
                    if img then
                        return img, slot
                    end
                end
            end
        end

        table.sort(slots, function(a, b) return (a.LayoutOrder or 0) < (b.LayoutOrder or 0) end)
        if slots[targetSlotIdx] then
            local s = slots[targetSlotIdx]
            local img = getSlotIcon(s)
            if img then
                return img, s
            end
        end
        return nil, nil
    end

    local containers = getHotbarContainers()
    for _, cont in ipairs(containers) do
        local img, slot = checkContainer(cont)
        if img then return img, slot end
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

    local targetItemName = DarlingSkins.getTargetItem(category)
    local img, slot = findHotbarSlot(category, targetItemName)
    if img then
        if not DarlingSkins.Tools.HotbarCache[category] then
            DarlingSkins.Tools.HotbarCache[category] = {
                ImageColor3 = img.ImageColor3,
                Image = img.Image,
                ImgInstance = img
            }
        end
        img.ImageColor3 = skin.Color

        if DarlingSkins.Tools.CustomAssetId ~= "" then
            pcall(function() img.Image = DarlingSkins.Tools.CustomAssetId end)
        end

        if DarlingSkins.Tools.Listeners[category] then
            pcall(function() DarlingSkins.Tools.Listeners[category]:Disconnect() end)
        end
        local updatingCat = false
        DarlingSkins.Tools.Listeners[category] = img:GetPropertyChangedSignal("Image"):Connect(function()
            if updatingCat then return end
            local eq = DarlingSkins.Tools.EquippedSkins[category]
            if eq and eq.Color then
                updatingCat = true
                pcall(function()
                    if DarlingSkins.Tools.CustomAssetId ~= "" and img.Image ~= DarlingSkins.Tools.CustomAssetId then
                        img.Image = DarlingSkins.Tools.CustomAssetId
                    end
                    img.ImageColor3 = eq.Color
                end)
                updatingCat = false
            end
        end)
    end

    -- Recolor equipped and backpack tools matching this category
    pcall(function()
        local targetTip = DarlingSkins.CategoryTips[category]
        local tools = {}
        local char = LocalPlayer.Character
        local bp = LocalPlayer:FindFirstChildOfClass("Backpack")

        if char then
            for _, c in ipairs(char:GetChildren()) do
                if c:IsA("Tool") and (c.ToolTip == targetTip or tostring(c:GetAttribute("WeaponType")) == targetTip or tostring(c:GetAttribute("ItemType")) == targetTip or (targetItemName and string.lower(c.Name) == string.lower(targetItemName))) then
                    table.insert(tools, c)
                end
            end
        end
        if bp then
            for _, c in ipairs(bp:GetChildren()) do
                if c:IsA("Tool") and (c.ToolTip == targetTip or tostring(c:GetAttribute("WeaponType")) == targetTip or tostring(c:GetAttribute("ItemType")) == targetTip or (targetItemName and string.lower(c.Name) == string.lower(targetItemName))) then
                    table.insert(tools, c)
                end
            end
        end

        for _, tool in ipairs(tools) do
            for _, part in ipairs(tool:GetDescendants()) do
                if part:IsA("SpecialMesh") then
                    if part.TextureId ~= "" then
                        local minLum = 0.32
                        local isDk = (skin.Color.R < 0.2 and skin.Color.G < 0.2 and skin.Color.B < 0.2)
                        local vR = math.clamp(skin.Color.R * 0.7 + (isDk and minLum or 0), 0.15, 1)
                        local vG = math.clamp(skin.Color.G * 0.7 + (isDk and minLum or 0), 0.15, 1)
                        local vB = math.clamp(skin.Color.B * 0.7 + (isDk and minLum or 0), 0.15, 1)
                        part.VertexColor = Vector3.new(vR, vG, vB)
                    else
                        part.VertexColor = Vector3.new(skin.Color.R, skin.Color.G, skin.Color.B)
                    end
                elseif part:IsA("MeshPart") then
                    if part.TextureID ~= "" then
                        local isDk = (skin.Color.R < 0.2 and skin.Color.G < 0.2 and skin.Color.B < 0.2)
                        part.Color = isDk and Color3.fromRGB(80, 80, 90) or skin.Color
                    else
                        part.Color = skin.Color
                    end
                elseif part:IsA("BasePart") then
                    part.Color = skin.Color
                end
            end
        end
    end)

    DarlingSkins.Tools.EquippedSkins[category] = skin
    return true
end

function DarlingSkins.recolorAllHotbarSlots(skinName, customColor)
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

    local containers = getHotbarContainers()
    local coloredCount = 0

    for _, cont in ipairs(containers) do
        for _, slot in ipairs(cont:GetChildren()) do
            if slot:IsA("GuiObject") then
                local img = getSlotIcon(slot)
                if img then
                    if not DarlingSkins.Tools.AllSlotsCache[img] then
                        DarlingSkins.Tools.AllSlotsCache[img] = {
                            ImageColor3 = img.ImageColor3,
                            Image = img.Image
                        }
                    end
                    img.ImageColor3 = skin.Color
                    if DarlingSkins.Tools.CustomAssetId ~= "" then
                        pcall(function() img.Image = DarlingSkins.Tools.CustomAssetId end)
                    end
                    if DarlingSkins.Tools.AllSlotsListeners[img] then
                        pcall(function() DarlingSkins.Tools.AllSlotsListeners[img]:Disconnect() end)
                    end
                    local updatingSlot = false
                    DarlingSkins.Tools.AllSlotsListeners[img] = img:GetPropertyChangedSignal("Image"):Connect(function()
                        if updatingSlot then return end
                        if DarlingSkins.Tools.GlobalSkin and DarlingSkins.Tools.GlobalSkin.Color then
                            updatingSlot = true
                            pcall(function()
                                if DarlingSkins.Tools.CustomAssetId ~= "" and img.Image ~= DarlingSkins.Tools.CustomAssetId then
                                    img.Image = DarlingSkins.Tools.CustomAssetId
                                end
                                img.ImageColor3 = DarlingSkins.Tools.GlobalSkin.Color
                            end)
                            updatingSlot = false
                        end
                    end)
                    coloredCount = coloredCount + 1
                end
            end
        end
    end

    pcall(function()
        local char = LocalPlayer.Character
        local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
        local allTools = {}
        if char then
            for _, c in ipairs(char:GetChildren()) do
                if c:IsA("Tool") then table.insert(allTools, c) end
            end
        end
        if bp then
            for _, c in ipairs(bp:GetChildren()) do
                if c:IsA("Tool") then table.insert(allTools, c) end
            end
        end
        for _, tool in ipairs(allTools) do
            for _, part in ipairs(tool:GetDescendants()) do
                if part:IsA("SpecialMesh") then
                    if part.TextureId ~= "" then
                        local minLum = 0.32
                        local isDk = (skin.Color.R < 0.2 and skin.Color.G < 0.2 and skin.Color.B < 0.2)
                        local vR = math.clamp(skin.Color.R * 0.7 + (isDk and minLum or 0), 0.15, 1)
                        local vG = math.clamp(skin.Color.G * 0.7 + (isDk and minLum or 0), 0.15, 1)
                        local vB = math.clamp(skin.Color.B * 0.7 + (isDk and minLum or 0), 0.15, 1)
                        part.VertexColor = Vector3.new(vR, vG, vB)
                    else
                        part.VertexColor = Vector3.new(skin.Color.R, skin.Color.G, skin.Color.B)
                    end
                elseif part:IsA("MeshPart") then
                    if part.TextureID ~= "" then
                        local isDk = (skin.Color.R < 0.2 and skin.Color.G < 0.2 and skin.Color.B < 0.2)
                        part.Color = isDk and Color3.fromRGB(80, 80, 90) or skin.Color
                    else
                        part.Color = skin.Color
                    end
                elseif part:IsA("BasePart") then
                    part.Color = skin.Color
                end
            end
        end
    end)

    DarlingSkins.Tools.GlobalSkin = skin
    return coloredCount
end

function DarlingSkins.resetCategoryToolSkin(category)
    category = category or DarlingSkins.Tools.SelectedCategory or "Fruits"
    if DarlingSkins.Tools.Listeners[category] then
        pcall(function() DarlingSkins.Tools.Listeners[category]:Disconnect() end)
        DarlingSkins.Tools.Listeners[category] = nil
    end

    local cached = DarlingSkins.Tools.HotbarCache[category]
    if cached and cached.ImgInstance and cached.ImgInstance.Parent then
        pcall(function()
            cached.ImgInstance.ImageColor3 = cached.ImageColor3
            cached.ImgInstance.Image = cached.Image
        end)
    end
    DarlingSkins.Tools.HotbarCache[category] = nil
    DarlingSkins.Tools.EquippedSkins[category] = nil
end

function DarlingSkins.resetAllToolSkins()
    for cat, _ in pairs(DarlingSkins.CategoryTips) do
        DarlingSkins.resetCategoryToolSkin(cat)
    end
    for img, conn in pairs(DarlingSkins.Tools.AllSlotsListeners or {}) do
        pcall(function() conn:Disconnect() end)
    end
    DarlingSkins.Tools.AllSlotsListeners = {}
    for img, cached in pairs(DarlingSkins.Tools.AllSlotsCache or {}) do
        if img and img.Parent then
            pcall(function()
                img.ImageColor3 = cached.ImageColor3
                img.Image = cached.Image
            end)
        end
    end
    DarlingSkins.Tools.AllSlotsCache = {}
    DarlingSkins.Tools.GlobalSkin = nil
end

-- ============================================================================
-- SECTION 3: CHARACTER SKIN CHANGER & APPEARANCE CLONER
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

function DarlingSkins.cloneCharacterAppearance(targetChar)
    if not targetChar then return false, "Target character not found" end
    local myChar = LocalPlayer.Character
    if not myChar then return false, "Local character not found" end

    local myHum = myChar:FindFirstChildOfClass("Humanoid")
    local tgtHum = targetChar:FindFirstChildOfClass("Humanoid")
    if not myHum or not tgtHum then return false, "Humanoid missing" end

    local okDesc, desc = pcall(function()
        return tgtHum:GetAppliedDescription()
    end)
    if okDesc and desc then
        pcall(function()
            myHum:ApplyDescription(desc)
        end)
    end

    pcall(function()
        for _, item in ipairs(myChar:GetChildren()) do
            if item:IsA("Accessory") or item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") or item:IsA("BodyColors") then
                item:Destroy()
            end
        end

        for _, item in ipairs(targetChar:GetChildren()) do
            if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") or item:IsA("BodyColors") then
                local clone = item:Clone()
                clone.Parent = myChar
            elseif item:IsA("Accessory") then
                local clone = item:Clone()
                clone.Parent = myChar
            end
        end
    end)

    return true, "Cloned appearance from " .. targetChar.Name
end

function DarlingSkins.cloneNearestPlayer()
    local myChar = LocalPlayer.Character
    local myHrp = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso"))
    if not myHrp then return false, "Local character missing" end

    local closestDist = math.huge
    local closestPlr = nil

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local pHrp = p.Character:FindFirstChild("HumanoidRootPart") or p.Character:FindFirstChild("Torso")
            if pHrp then
                local dist = (myHrp.Position - pHrp.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestPlr = p
                end
            end
        end
    end

    if closestPlr and closestPlr.Character then
        return DarlingSkins.cloneCharacterAppearance(closestPlr.Character)
    end
    return false, "No nearby player found"
end

function DarlingSkins.cloneByUserId(identifier)
    if not identifier or identifier == "" then return false, "Invalid User ID or Name" end
    local userId = tonumber(identifier)
    if not userId then
        local okId, fetchedId = pcall(function()
            return Players:GetUserIdFromNameAsync(tostring(identifier))
        end)
        if okId and fetchedId then
            userId = fetchedId
        else
            return false, "Could not resolve username: " .. tostring(identifier)
        end
    end

    local myChar = LocalPlayer.Character
    local hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not hum then return false, "Local character missing" end

    local okDesc, desc = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(userId)
    end)
    if okDesc and desc then
        pcall(function()
            hum:ApplyDescription(desc)
        end)
        return true, "Applied skin from User ID: " .. tostring(userId)
    end

    return false, "Failed to load HumanoidDescription for User ID: " .. tostring(userId)
end

DarlingSkins.CharAddedConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
    if DarlingSkins.Character.Enabled then
        task.delay(0.3, function()
            DarlingSkins.applyCharacterSkin(DarlingSkins.Character.ActivePreset, DarlingSkins.Character.ActiveColor)
        end)
    end
end)

function DarlingSkins.destroy()
    DarlingSkins.setVFXEnabled(false)
    DarlingSkins.stopVFXWatchers()
    if vfxScanThread then
        pcall(function() task.cancel(vfxScanThread) end)
        vfxScanThread = nil
    end
    vfxScanToken = vfxScanToken + 1
    DarlingSkins.resetOriginalVFX()
    DarlingSkins.resetCharacterSkin()
    DarlingSkins.resetAllToolSkins()
    if DarlingSkins.CharAddedConn then
        pcall(function() DarlingSkins.CharAddedConn:Disconnect() end)
        DarlingSkins.CharAddedConn = nil
    end
end

function DarlingSkins.getDiagnostics()
    local toolListenerCount = 0
    for _ in pairs(DarlingSkins.Tools.Listeners or {}) do toolListenerCount = toolListenerCount + 1 end
    for _ in pairs(DarlingSkins.Tools.AllSlotsListeners or {}) do toolListenerCount = toolListenerCount + 1 end
    local connCount = #DarlingSkins.VFX.Connections + toolListenerCount + (DarlingSkins.CharAddedConn and 1 or 0)
    return {
        Name = "SkinsSystem",
        Active = (DarlingSkins.VFX.Enabled or DarlingSkins.Character.Enabled) == true,
        Connections = connCount,
        Threads = vfxScanThread and 1 or 0,
    }
end

return DarlingSkins
