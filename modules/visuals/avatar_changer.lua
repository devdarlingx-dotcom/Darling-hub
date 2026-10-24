-- ========================================================================
-- Darling Hub - Avatar Changer Engine
-- High-fidelity avatar replication engine ported from Noctra.
-- Features: Full body overlay pairing (R6 <-> R15 agnostic), snapshot capture &
-- restore, giant transformation watchdog, true proportion scaling, silent protection.
-- ========================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local typeof = typeof or type

local AvatarChanger = {}

-- ========================================================================
-- Avatar State
-- ========================================================================
local AvatarState = {
    activeId = nil,
    character = nil,
    snapshot = nil,
    template = nil,
    generation = 0,
    overlayPairs = {},
    overlayFolder = nil,
    overlayHeadClone = nil,
    giantMode = false,
    manualGiant = false,
    watchdogToken = 0,
    scaleBaseline = nil,
    bodyScaleBaseline = nil,
    giantFrames = 0,
    overlayCount = 0,
    overlayNames = "",
    rebuildTicks = 0,
    alive = true,
    charAddedConn = nil,
    status = "Idle",
    statusListeners = {},
}

AvatarChanger.State = AvatarState

local function updateStatus(text)
    AvatarState.status = tostring(text or "")
    for _, callback in ipairs(AvatarState.statusListeners) do
        pcall(callback, AvatarState.status)
    end
end

local function cloneAvatarInstance(instance)
    if not instance then
        return nil
    end
    local ok, clone = pcall(function()
        return instance:Clone()
    end)
    if ok and clone then
        return clone
    end
    return nil
end

local function destroyAvatarInstance(instance)
    if instance then
        pcall(function()
            instance:Destroy()
        end)
    end
end

local function isAvatarAccessory(instance)
    if not instance or typeof(instance) ~= "Instance" then
        return false
    end
    return instance:IsA("Accessory") or instance:IsA("Hat")
end

local function clearLocalAppearance(character)
    if not character then
        return
    end
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic") or child:IsA("BodyColors") or isAvatarAccessory(child) then
            destroyAvatarInstance(child)
        end
    end
    local head = character:FindFirstChild("Head")
    if head then
        for _, child in ipairs(head:GetChildren()) do
            if child:IsA("Decal") and string.lower(child.Name) == "face" then
                destroyAvatarInstance(child)
            end
        end
    end
end

local function destroyAvatarSnapshot()
    local snapshot = AvatarState.snapshot
    if not snapshot then
        return
    end
    destroyAvatarInstance(snapshot.bodyColors)
    destroyAvatarInstance(snapshot.face)
    for _, item in ipairs(snapshot.clothing or {}) do
        destroyAvatarInstance(item)
    end
    for _, item in ipairs(snapshot.accessories or {}) do
        destroyAvatarInstance(item)
    end
    AvatarState.snapshot = nil
end

local function destroyAvatarTemplate()
    if AvatarState.template then
        destroyAvatarInstance(AvatarState.template)
        AvatarState.template = nil
    end
end

local function stripAccessoryWelds(accessory)
    for _, descendant in ipairs(accessory:GetDescendants()) do
        if descendant:IsA("Weld") or descendant:IsA("WeldConstraint") or descendant:IsA("Motor6D") or descendant:IsA("AccessoryWeld") then
            destroyAvatarInstance(descendant)
        end
    end
end

local function attachLocalAccessory(character, accessory)
    if not character or not accessory then
        return false
    end
    local handle = accessory:FindFirstChild("Handle")
    if not handle or not handle:IsA("BasePart") then
        destroyAvatarInstance(accessory)
        return false
    end

    local targetPart = nil
    local targetAttachment = nil
    local accessoryAttachment = nil
    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            for _, attachment in ipairs(part:GetChildren()) do
                if attachment:IsA("Attachment") then
                    local match = handle:FindFirstChild(attachment.Name)
                    if match and match:IsA("Attachment") then
                        targetPart = part
                        targetAttachment = attachment
                        accessoryAttachment = match
                        break
                    end
                end
            end
        end
        if targetPart then
            break
        end
    end

    if not targetPart then
        targetPart = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
    end
    if not targetPart then
        destroyAvatarInstance(accessory)
        return false
    end

    stripAccessoryWelds(accessory)
    pcall(function()
        handle.CanCollide = false
        handle.Massless = true
    end)

    local positioned = false
    if targetAttachment and accessoryAttachment then
        positioned = pcall(function()
            handle.CFrame = targetAttachment.WorldCFrame * accessoryAttachment.CFrame:Inverse()
        end)
    end
    if not positioned then
        pcall(function()
            handle.CFrame = targetPart.CFrame
        end)
    end

    local ok = pcall(function()
        local weld = Instance.new("WeldConstraint")
        weld.Name = "DarlingAvatarWeld"
        weld.Part0 = handle
        weld.Part1 = targetPart
        weld.Parent = handle
        accessory.Parent = character
    end)
    if not ok then
        destroyAvatarInstance(accessory)
        return false
    end
    return true
end

local function captureAvatarSnapshot(character)
    if not character then
        return
    end
    if AvatarState.character == character and AvatarState.snapshot then
        return
    end
    destroyAvatarSnapshot()
    AvatarState.character = character

    local snapshot = {
        bodyColors = nil,
        clothing = {},
        accessories = {},
        face = nil,
    }
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic") then
            local copy = cloneAvatarInstance(child)
            if copy then
                table.insert(snapshot.clothing, copy)
            end
        elseif isAvatarAccessory(child) then
            local copy = cloneAvatarInstance(child)
            if copy then
                table.insert(snapshot.accessories, copy)
            end
        elseif child:IsA("BodyColors") and not snapshot.bodyColors then
            snapshot.bodyColors = cloneAvatarInstance(child)
        end
    end
    local head = character:FindFirstChild("Head")
    if head then
        for _, child in ipairs(head:GetChildren()) do
            if child:IsA("Decal") and string.lower(child.Name) == "face" then
                snapshot.face = cloneAvatarInstance(child)
                break
            end
        end
    end
    AvatarState.snapshot = snapshot
end

local function restoreAvatarSnapshot(character)
    if not character or not AvatarState.snapshot then
        return false
    end
    local snapshot = AvatarState.snapshot
    clearLocalAppearance(character)

    if snapshot.bodyColors then
        snapshot.bodyColors.Parent = character
        snapshot.bodyColors = nil
    end
    for _, item in ipairs(snapshot.clothing or {}) do
        item.Parent = character
    end
    for _, item in ipairs(snapshot.accessories or {}) do
        attachLocalAccessory(character, item)
    end
    if snapshot.face then
        local head = character:FindFirstChild("Head")
        if head then
            snapshot.face.Parent = head
        end
    end
    AvatarState.snapshot = nil
    return true
end

-- ========================================================================
-- Body overlay: family planner (R6 <-> R15 agnostic, exact fit)
-- ========================================================================
local function removeLocalBodyOverlay(character)
    if not character then
        return
    end
    AvatarState.overlayCount = 0
    AvatarState.overlayNames = ""
    for _, pair in ipairs(AvatarState.overlayPairs or {}) do
        destroyAvatarInstance(pair.clone)
    end
    AvatarState.overlayPairs = {}
    AvatarState.overlayHeadClone = nil
    for _, localPart in ipairs(character:GetChildren()) do
        if localPart:IsA("BasePart") and localPart.Name ~= "HumanoidRootPart" then
            pcall(function()
                localPart.LocalTransparencyModifier = 0
            end)
        end
    end
end

local function avatarBodyFamily(name)
    local norm = string.lower(string.gsub(tostring(name), "%s", ""))
    local side = ""
    local rest = norm
    if string.sub(norm, 1, 4) == "left" then
        side = "left"
        rest = string.sub(norm, 5)
    elseif string.sub(norm, 1, 5) == "right" then
        side = "right"
        rest = string.sub(norm, 6)
    end
    if string.find(rest, "hand", 1, true) then
        return side .. "arm"
    end
    if string.find(rest, "foot", 1, true) then
        return side .. "leg"
    end
    if string.find(rest, "arm", 1, true) then
        return side .. "arm"
    end
    if string.find(rest, "leg", 1, true) then
        return side .. "leg"
    end
    if string.find(rest, "torso", 1, true) then
        return "torso"
    end
    if string.find(norm, "head", 1, true) then
        return "head"
    end
    return nil
end

local function avatarSegmentOrder(part)
    local norm = string.lower(string.gsub(tostring(part.Name), "%s", ""))
    if string.find(norm, "upper", 1, true) then
        return 0
    end
    if string.find(norm, "lower", 1, true) then
        return 1
    end
    return 2
end

local function findModelBodyParts(model)
    local parts = {}
    if typeof(model) ~= "Instance" then
        return parts
    end
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            table.insert(parts, descendant)
        end
    end
    return parts
end

local function sortAvatarSegments(list)
    table.sort(list, function(a, b)
        local orderA = avatarSegmentOrder(a)
        local orderB = avatarSegmentOrder(b)
        if orderA ~= orderB then
            return orderA < orderB
        end
        return a.Size.Y > b.Size.Y
    end)
end

local function createBodyOverlayClone(target, anchorPart, placedHeight, widthScale, offsetY, overlayList)
    local bodyClone = nil
    pcall(function()
        local clone = target:Clone()
        if not clone then
            return
        end
        for _, child in ipairs(clone:GetDescendants()) do
            if child:IsA("JointInstance") or child:IsA("WeldConstraint") then
                child:Destroy()
            end
        end
        clone.Name = anchorPart.Name
        clone.Anchored = false
        clone.CanCollide = false
        clone.CanQuery = false
        clone.CanTouch = false
        clone.Massless = true
        local size = clone.Size
        clone.Size = Vector3.new(
            size.X * widthScale,
            math.max(0.05, placedHeight),
            size.Z * widthScale
        )
        clone.CFrame = anchorPart.CFrame * CFrame.new(0, offsetY, 0)
        clone.Parent = anchorPart.Parent
        bodyClone = clone
    end)
    if bodyClone then
        pcall(function()
            local weld = Instance.new("WeldConstraint")
            weld.Name = "DarlingBodyWeld"
            weld.Part0 = anchorPart
            weld.Part1 = bodyClone
            weld.Parent = bodyClone
        end)
        if string.find(anchorPart.Name, "Head", 1, true) == 1 and not AvatarState.overlayHeadClone then
            AvatarState.overlayHeadClone = bodyClone
        end
        table.insert(overlayList, { clone = bodyClone, source = anchorPart })
    end
    return bodyClone ~= nil
end

local function overlayLocalBodyParts(character, model)
    if not character or not model then
        return false
    end
    removeLocalBodyOverlay(character)

    local overlayList = {}
    local matchedSources = 0
    local matchedNames = {}
    local modelParts = findModelBodyParts(model)

    local familyLocalParts = {}
    for _, localPart in ipairs(character:GetChildren()) do
        if localPart:IsA("BasePart") and localPart.Name ~= "HumanoidRootPart" then
            local family = avatarBodyFamily(localPart.Name)
            if family then
                if not familyLocalParts[family] then
                    familyLocalParts[family] = {}
                end
                table.insert(familyLocalParts[family], localPart)
            end
        end
    end

    local heightScale = 1
    local widthScale = 1
    local headScale = 1
    local userId = AvatarState.activeId
    if userId then
        pcall(function()
            local description = nil
            for _, methodName in ipairs({
                "GetHumanoidDescriptionFromUserId",
                "GetHumanoidDescriptionFromUserIdAsync",
            }) do
                local method = Players[methodName]
                if typeof(method) == "function" then
                    local ok, result = pcall(method, Players, userId)
                    if ok and typeof(result) == "Instance" then
                        description = result
                        break
                    end
                end
            end
            if description then
                if description.HeightScale and description.HeightScale > 0 then
                    heightScale = description.HeightScale
                end
                if description.WidthScale and description.WidthScale > 0 then
                    widthScale = description.WidthScale
                end
                if description.HeadScale and description.HeadScale > 0 then
                    headScale = description.HeadScale
                end
            end
        end)
    end
    if heightScale == 1 and widthScale == 1 and typeof(model) == "Instance" then
        pcall(function()
            local modelHumanoid = model:FindFirstChildOfClass("Humanoid")
            if modelHumanoid then
                local heightValue = modelHumanoid:FindFirstChild("BodyHeightScale")
                local widthValue = modelHumanoid:FindFirstChild("BodyWidthScale")
                local headValue = modelHumanoid:FindFirstChild("HeadScale")
                if heightValue and heightValue:IsA("NumberValue") and heightValue.Value > 1 then
                    heightScale = heightValue.Value
                end
                if widthValue and widthValue:IsA("NumberValue") and widthValue.Value > 1 then
                    widthScale = widthValue.Value
                end
                if headValue and headValue:IsA("NumberValue") and headValue.Value > 1 then
                    headScale = headValue.Value
                end
            end
        end)
    end

    local function hideAvatarSource(localPart)
        pcall(function()
            localPart.LocalTransparencyModifier = 1
        end)
        matchedSources = matchedSources + 1
        table.insert(matchedNames, localPart.Name)
    end

    local function familyHeightScale(family)
        if family == "head" then
            return headScale
        end
        return heightScale
    end

    for family, localParts in pairs(familyLocalParts) do
        sortAvatarSegments(localParts)
        local targetParts = {}
        for _, candidate in ipairs(modelParts) do
            if avatarBodyFamily(candidate.Name) == family then
                table.insert(targetParts, candidate)
            end
        end
        if #targetParts > 0 then
            sortAvatarSegments(targetParts)
            local segHeightScale = familyHeightScale(family)
            if #localParts == 1 then
                local localPart = localParts[1]
                local localHeight = math.max(0.05, localPart.Size.Y)
                local totalTarget = 0
                for _, target in ipairs(targetParts) do
                    totalTarget = totalTarget + math.max(0.05, target.Size.Y)
                end
                local fitScale = localHeight / math.max(0.05, totalTarget)
                local placed = 0
                local localCloned = false
                for _, target in ipairs(targetParts) do
                    local targetHeight = math.max(0.05, target.Size.Y)
                    local placedHeight = targetHeight * fitScale * segHeightScale
                    local offsetY = localPart.Size.Y * 0.5 - placed - placedHeight * 0.5
                    if createBodyOverlayClone(target, localPart, placedHeight, widthScale, offsetY, overlayList) then
                        localCloned = true
                    end
                    placed = placed + placedHeight
                end
                if localCloned then
                    hideAvatarSource(localPart)
                end
            elseif #localParts == #targetParts then
                for i = 1, #localParts do
                    local localPart = localParts[i]
                    local target = targetParts[i]
                    if createBodyOverlayClone(target, localPart, localPart.Size.Y * segHeightScale, widthScale, 0, overlayList) then
                        hideAvatarSource(localPart)
                    end
                end
            else
                local anchorPart = localParts[1]
                local totalLocal = 0
                for _, localPart in ipairs(localParts) do
                    totalLocal = totalLocal + math.max(0.05, localPart.Size.Y)
                end
                local totalTarget = 0
                for _, target in ipairs(targetParts) do
                    totalTarget = totalTarget + math.max(0.05, target.Size.Y)
                end
                local fitScale = totalLocal / math.max(0.05, totalTarget)
                local placed = 0
                local anyCloneSucceeded = false
                for _, target in ipairs(targetParts) do
                    local targetHeight = math.max(0.05, target.Size.Y)
                    local placedHeight = targetHeight * fitScale * segHeightScale
                    local offsetY = anchorPart.Size.Y * 0.5 - placed - placedHeight * 0.5
                    if createBodyOverlayClone(target, anchorPart, placedHeight, widthScale, offsetY, overlayList) then
                        anyCloneSucceeded = true
                    end
                    placed = placed + placedHeight
                end
                if anyCloneSucceeded then
                    for _, localPart in ipairs(localParts) do
                        hideAvatarSource(localPart)
                    end
                end
            end
        end
    end

    AvatarState.overlayPairs = overlayList
    AvatarState.overlayCount = matchedSources
    AvatarState.overlayNames = table.concat(matchedNames, ",")
    return #overlayList > 0
end

local function applyAvatarModel(character, model)
    if not character or not model then
        return false, "Appearance model unavailable."
    end
    clearLocalAppearance(character)
    overlayLocalBodyParts(character, model)

    local bodyColors = model:FindFirstChildOfClass("BodyColors")
    if bodyColors then
        local copy = cloneAvatarInstance(bodyColors)
        if copy then
            copy.Parent = character
        end
    end

    for _, child in ipairs(model:GetChildren()) do
        if child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic") then
            local copy = cloneAvatarInstance(child)
            if copy then
                copy.Parent = character
            end
        end
    end

    local face = model:FindFirstChild("face", true)
    if face and face:IsA("Decal") then
        local head = AvatarState.overlayHeadClone or character:FindFirstChild("Head")
        if head then
            local copy = cloneAvatarInstance(face)
            if copy then
                copy.Parent = head
            end
        end
    end

    for _, child in ipairs(model:GetChildren()) do
        if isAvatarAccessory(child) then
            local copy = cloneAvatarInstance(child)
            if copy then
                attachLocalAccessory(character, copy)
            end
        end
    end
    return true
end

local function fetchAvatarModel(userId)
    local model = nil
    for _, methodName in ipairs({
        "CreateHumanoidModelFromUserId",
        "CreateHumanoidModelFromUserIdAsync",
    }) do
        local method = Players[methodName]
        if typeof(method) == "function" then
            local ok, result = pcall(method, Players, userId)
            if ok and typeof(result) == "Instance" then
                model = result
                break
            end
        end
    end
    if model then
        return model
    end
    for _, methodName in ipairs({
        "GetCharacterAppearanceAsync",
    }) do
        local method = Players[methodName]
        if typeof(method) == "function" then
            local ok, result = pcall(method, Players, userId)
            if ok and typeof(result) == "Instance" then
                model = result
                break
            end
        end
    end
    return model, "Avatar appearance could not be loaded."
end

local function resolveAvatarUserId(input)
    if typeof(input) == "Instance" and input:IsA("Player") then
        return input.UserId
    end
    local text = tostring(input or "")
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    if text == "" then
        return nil, "Enter a Roblox User ID or username."
    end
    local numeric = tonumber(text)
    if numeric and numeric >= 1 and numeric % 1 == 0 then
        return math.floor(numeric)
    end
    local ok, userId = pcall(function()
        return Players:GetUserIdFromNameAsync(text)
    end)
    userId = tonumber(userId)
    if ok and userId and userId >= 1 then
        return math.floor(userId)
    end
    return nil, "That User ID or username was not found."
end

-- ========================================================================
-- Silent client-side protection for character
-- (top-up + Dead/Ragdoll blocked)
-- ========================================================================
local GodState = {
    active = false,
    heartbeat = nil,
    connections = {},
    cachedHumanoid = nil,
}

local function refreshGodHumanoid()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid") or nil
    if humanoid and humanoid.Parent then
        GodState.cachedHumanoid = humanoid
    else
        GodState.cachedHumanoid = nil
    end
    return GodState.cachedHumanoid
end

local function applyGodStateProtection(humanoid, enabled)
    if not humanoid or not humanoid.Parent then
        return
    end
    pcall(function()
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, not enabled)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, not enabled)
    end)
end

local function bindGodCharacter(character)
    task.spawn(function()
        local humanoid = character:WaitForChild("Humanoid", 4)
        if humanoid and humanoid.Parent and GodState.active then
            GodState.cachedHumanoid = humanoid
            applyGodStateProtection(humanoid, true)
            local diedConnection = humanoid.Died:Connect(function()
                if not GodState.active then
                    return
                end
                pcall(function()
                    humanoid.Health = humanoid.MaxHealth
                    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                    applyGodStateProtection(humanoid, true)
                end)
            end)
            local stateConnection = humanoid.StateChanged:Connect(function()
                if GodState.active then
                    applyGodStateProtection(humanoid, true)
                end
            end)
            table.insert(GodState.connections, diedConnection)
            table.insert(GodState.connections, stateConnection)
        end
    end)
end

local function enableProtectionSilently()
    if GodState.active then
        return
    end
    GodState.active = true
    if GodState.heartbeat then
        pcall(function()
            GodState.heartbeat:Disconnect()
        end)
    end
    GodState.heartbeat = RunService.Heartbeat:Connect(function()
        if not GodState.active then
            return
        end
        local humanoid = GodState.cachedHumanoid
        if not humanoid or not humanoid.Parent then
            humanoid = refreshGodHumanoid()
        end
        if humanoid and humanoid.Parent and humanoid.Health > 0 and humanoid.Health < humanoid.MaxHealth then
            humanoid.Health = humanoid.MaxHealth
            applyGodStateProtection(humanoid, true)
        end
    end)
    refreshGodHumanoid()
end

local function disableProtectionSilently()
    GodState.active = false
    if GodState.heartbeat then
        pcall(function()
            GodState.heartbeat:Disconnect()
        end)
        GodState.heartbeat = nil
    end
    for _, connection in ipairs(GodState.connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    if table.clear then
        table.clear(GodState.connections)
    else
        GodState.connections = {}
    end
    applyGodStateProtection(GodState.cachedHumanoid, false)
    GodState.cachedHumanoid = nil
end

-- ========================================================================
-- Scaling Baselines & Giant Detection
-- ========================================================================
local function isAvatarGiant(humanoid, root)
    if AvatarState.manualGiant then
        return true
    end
    local giant = false
    if root and root:IsA("BasePart") then
        local scale = root.Size.Magnitude
        local baseline = AvatarState.scaleBaseline
        if not baseline or baseline <= 0 then
            baseline = scale
            AvatarState.scaleBaseline = scale
        end
        if baseline > 0 then
            if scale >= baseline * 2.2 then
                AvatarState.giantFrames = (AvatarState.giantFrames or 0) + 1
                if AvatarState.giantFrames >= 4 then
                    giant = true
                end
            elseif scale <= baseline * 1.3 then
                AvatarState.giantFrames = 0
                AvatarState.scaleBaseline = baseline * 0.8 + scale * 0.2
            else
                AvatarState.giantFrames = 0
            end
        end
    end
    if humanoid and not giant then
        local scaleValue = humanoid:FindFirstChild("BodyHeightScale")
        if scaleValue and scaleValue:IsA("NumberValue") then
            local value = tonumber(scaleValue.Value)
            if value then
                local baseline = AvatarState.bodyScaleBaseline
                if not baseline then
                    baseline = value
                    AvatarState.bodyScaleBaseline = value
                end
                if baseline > 0 and value >= baseline * 2.2 then
                    giant = true
                end
            end
        end
    end
    return giant
end

local function overlayFallbackRebuild(character)
    if not AvatarState.activeId or not AvatarState.template then
        return
    end
    pcall(function()
        captureAvatarSnapshot(character)
        applyAvatarModel(character, AvatarState.template)
        AvatarState.overlayHeadClone = nil
        for _, pair in ipairs(AvatarState.overlayPairs) do
            local clone = pair.clone
            if clone and clone.Parent and string.find(clone.Name, "Head", 1, true) == 1 then
                AvatarState.overlayHeadClone = clone
                break
            end
        end
    end)
    AvatarState.scaleBaseline = nil
    AvatarState.bodyScaleBaseline = nil
    AvatarState.giantFrames = 0
end

local function startAvatarWatchdog()
    AvatarState.watchdogToken = AvatarState.watchdogToken + 1
    local token = AvatarState.watchdogToken
    task.spawn(function()
        while token == AvatarState.watchdogToken and AvatarState.alive do
            task.wait(0.25)
            if token ~= AvatarState.watchdogToken or not AvatarState.alive then
                break
            end
            local character = LocalPlayer.Character
            if character and character.Parent then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    local root = character:FindFirstChild("HumanoidRootPart")
                    local giant = isAvatarGiant(humanoid, root)

                    if giant and not AvatarState.giantMode then
                        AvatarState.giantMode = true
                        pcall(removeLocalBodyOverlay, character)
                        if AvatarState.snapshot then
                            pcall(restoreAvatarSnapshot, character)
                        end
                        updateStatus("Transform detected: original look active.")
                    elseif not giant and AvatarState.giantMode then
                        AvatarState.giantMode = false
                        AvatarState.rebuildTicks = 0
                    elseif not AvatarState.giantMode then
                        for _, pair in ipairs(AvatarState.overlayPairs or {}) do
                            if pair.source and pair.source.Parent and pair.clone and pair.clone.Parent then
                                pcall(function()
                                    pair.source.LocalTransparencyModifier = 1
                                end)
                            end
                        end
                        local activeCount = 0
                        for _, pair in ipairs(AvatarState.overlayPairs or {}) do
                            if pair.clone and pair.clone.Parent and pair.source and pair.source.Parent then
                                activeCount = activeCount + 1
                            end
                        end
                        if activeCount > 0 then
                            AvatarState.rebuildTicks = 0
                        elseif AvatarState.activeId and AvatarState.template and (AvatarState.rebuildTicks or 0) < 6 then
                            AvatarState.rebuildTicks = (AvatarState.rebuildTicks or 0) + 1
                            overlayFallbackRebuild(character)
                        end
                    end
                end
            end
        end
    end)
end

-- ========================================================================
-- Public Methods
-- ========================================================================

function AvatarChanger.apply(input)
    AvatarState.generation = AvatarState.generation + 1
    local generation = AvatarState.generation
    updateStatus("Resolving...")

    local userId, resolveError = resolveAvatarUserId(input)
    if generation ~= AvatarState.generation then
        return false, "Aborted by newer request"
    end
    if not userId then
        updateStatus(resolveError or "Invalid User ID")
        return false, resolveError or "Invalid User ID"
    end

    updateStatus("Loading avatar " .. tostring(userId) .. "...")
    local model, fetchError = fetchAvatarModel(userId)
    if generation ~= AvatarState.generation then
        destroyAvatarInstance(model)
        return false, "Aborted by newer request"
    end
    if not model then
        updateStatus("Avatar load failed: " .. tostring(fetchError or "unknown error"))
        return false, "Avatar load failed: " .. tostring(fetchError or "unknown error")
    end

    local character = LocalPlayer.Character
    if not character or not character:FindFirstChildOfClass("Humanoid") then
        destroyAvatarInstance(model)
        updateStatus("Character is not ready.")
        return false, "Character is not ready."
    end

    local captured = pcall(captureAvatarSnapshot, character)
    if not captured then
        destroyAvatarInstance(model)
        updateStatus("Snapshot failed, try again.")
        return false, "Snapshot failed, try again."
    end

    destroyAvatarTemplate()
    AvatarState.template = model
    AvatarState.activeId = userId
    AvatarState.character = character
    AvatarState.scaleBaseline = nil
    AvatarState.bodyScaleBaseline = nil
    AvatarState.giantFrames = 0
    AvatarState.giantMode = false
    AvatarState.manualGiant = false

    local applied, applyError = pcall(applyAvatarModel, character, model)
    if generation ~= AvatarState.generation then
        destroyAvatarInstance(model)
        return false, "Aborted by newer request"
    end
    if not applied then
        AvatarState.activeId = nil
        destroyAvatarTemplate()
        pcall(removeLocalBodyOverlay, character)
        pcall(restoreAvatarSnapshot, character)
        updateStatus("Apply failed: " .. tostring(applyError))
        return false, "Apply failed: " .. tostring(applyError)
    end

    startAvatarWatchdog()
    enableProtectionSilently()
    bindGodCharacter(character)

    local bodyText = " | body: " .. tostring(AvatarState.overlayCount or 0) .. " parts (" .. tostring(AvatarState.overlayNames or "") .. ")"
    local successMsg = "Avatar " .. tostring(userId) .. " applied" .. bodyText
    updateStatus(successMsg)
    return true, successMsg
end

function AvatarChanger.applyAsync(input, callback)
    task.spawn(function()
        local ok, msg = AvatarChanger.apply(input)
        if typeof(callback) == "function" then
            pcall(callback, ok, msg)
        end
    end)
end

function AvatarChanger.reset(announce)
    AvatarState.generation = AvatarState.generation + 1
    AvatarState.activeId = nil
    AvatarState.giantMode = false
    AvatarState.manualGiant = false
    disableProtectionSilently()
    destroyAvatarTemplate()
    AvatarState.watchdogToken = AvatarState.watchdogToken + 1
    local character = LocalPlayer.Character
    local restored = false
    if character then
        pcall(removeLocalBodyOverlay, character)
    end
    if character and AvatarState.character == character and AvatarState.snapshot then
        restored = pcall(restoreAvatarSnapshot, character)
    else
        destroyAvatarSnapshot()
    end
    AvatarState.scaleBaseline = nil
    AvatarState.bodyScaleBaseline = nil
    AvatarState.giantFrames = 0
    local msg = restored and "Original appearance restored." or "Local avatar reset."
    if announce ~= false then
        updateStatus(msg)
    end
    return true, msg
end

function AvatarChanger.setGiant(enabled)
    local isGiantState = (enabled == true)
    AvatarState.manualGiant = isGiantState
    AvatarState.giantMode = isGiantState

    local character = LocalPlayer.Character
    if isGiantState then
        if character then
            pcall(removeLocalBodyOverlay, character)
            if AvatarState.snapshot then
                pcall(restoreAvatarSnapshot, character)
            end
        end
        updateStatus("Giant mode enabled: original look active.")
        return true, "Giant mode enabled"
    else
        if character and AvatarState.activeId and AvatarState.template then
            overlayFallbackRebuild(character)
        end
        updateStatus("Giant mode disabled: avatar restored.")
        return true, "Giant mode disabled"
    end
end

function AvatarChanger.destroy()
    AvatarState.alive = false
    AvatarState.generation = AvatarState.generation + 1
    AvatarState.watchdogToken = AvatarState.watchdogToken + 1

    if AvatarState.charAddedConn then
        pcall(function()
            AvatarState.charAddedConn:Disconnect()
        end)
        AvatarState.charAddedConn = nil
    end

    AvatarChanger.reset(false)
    disableProtectionSilently()
    destroyAvatarTemplate()
    destroyAvatarSnapshot()

    if table.clear then
        table.clear(AvatarState.overlayPairs)
        table.clear(AvatarState.statusListeners)
    else
        AvatarState.overlayPairs = {}
        AvatarState.statusListeners = {}
    end
    AvatarState.overlayHeadClone = nil
    AvatarState.character = nil
    AvatarState.activeId = nil
    AvatarState.status = "Destroyed"
end

-- ========================================================================
-- Character Respawns
-- ========================================================================
local function setupCharacterAddedListener()
    if AvatarState.charAddedConn then
        pcall(function()
            AvatarState.charAddedConn:Disconnect()
        end)
        AvatarState.charAddedConn = nil
    end

    AvatarState.charAddedConn = LocalPlayer.CharacterAdded:Connect(function(character)
        if not AvatarState.alive then
            return
        end
        AvatarState.generation = AvatarState.generation + 1
        AvatarState.character = nil
        AvatarState.overlayPairs = {}
        AvatarState.overlayHeadClone = nil
        destroyAvatarSnapshot()
        if GodState.active then
            bindGodCharacter(character)
        end

        local activeId = AvatarState.activeId
        if not activeId then
            return
        end
        local generation = AvatarState.generation

        local function attemptAvatarRepair(retryCount)
            if not AvatarState.alive or AvatarState.activeId ~= activeId or generation ~= AvatarState.generation then
                return
            end
            local current = LocalPlayer.Character
            if not current or current ~= character or not current:FindFirstChildOfClass("Humanoid") then
                if retryCount < 12 then
                    task.delay(0.1, function() attemptAvatarRepair(retryCount + 1) end)
                end
                return
            end
            local markerPart = current:FindFirstChild("Head")
                or current:FindFirstChild("Torso")
                or current:FindFirstChild("UpperTorso")
            if not markerPart then
                if retryCount < 12 then
                    task.delay(0.1, function() attemptAvatarRepair(retryCount + 1) end)
                end
                return
            end
            if AvatarState.template then
                pcall(captureAvatarSnapshot, current)
                pcall(applyAvatarModel, current, AvatarState.template)
                if AvatarState.activeId == activeId then
                    AvatarState.character = current
                    if GodState.active then
                        refreshGodHumanoid()
                        applyGodStateProtection(AvatarState.cachedHumanoid, true)
                    end
                    updateStatus("Avatar " .. tostring(activeId) .. " applied | body: " .. tostring(AvatarState.overlayCount or 0) .. " parts")
                    return
                end
                if retryCount < 12 then
                    task.delay(0.1, function() attemptAvatarRepair(retryCount + 1) end)
                end
            else
                AvatarChanger.apply(activeId)
            end
        end
        attemptAvatarRepair(1)
    end)
end

setupCharacterAddedListener()

-- ========================================================================
-- Status & Diagnostics Helpers
-- ========================================================================

function AvatarChanger.getActiveId()
    return AvatarState.activeId
end

function AvatarChanger.isGiant()
    return AvatarState.giantMode or AvatarState.manualGiant
end

function AvatarChanger.getStatus()
    return AvatarState.status
end

function AvatarChanger.onStatusChanged(callback)
    if typeof(callback) == "function" then
        table.insert(AvatarState.statusListeners, callback)
    end
end

function AvatarChanger.getDiagnostics()
    local connCount = (AvatarState.charAddedConn and 1 or 0) + #GodState.connections + (GodState.heartbeat and 1 or 0)
    return {
        Name = "AvatarChanger",
        Active = AvatarState.activeId ~= nil,
        UserId = AvatarState.activeId,
        Giant = AvatarState.giantMode or AvatarState.manualGiant,
        Overlays = #AvatarState.overlayPairs,
        Connections = connCount,
    }
end

return AvatarChanger
