-- player list

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local PlayerList = {}
PlayerList.Cards = {}
PlayerList.Connections = {}
PlayerList.CurrentSpectating = nil

-- Global blacklist table for aimbot exclusion
_G.DarlingBlacklistedPlayers = _G.DarlingBlacklistedPlayers or {}

-- ============================================================================
-- SPECTATE LOGIC
-- ============================================================================
function PlayerList.spectate(targetPlayer)
    if not targetPlayer or targetPlayer == LocalPlayer then
        PlayerList.stopSpectate()
        return
    end

    Camera = Workspace.CurrentCamera or Camera
    PlayerList.CurrentSpectating = targetPlayer

    local function setSubject()
        local char = targetPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            Camera.CameraSubject = hum
        elseif char then
            Camera.CameraSubject = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head") or char
        end
    end

    setSubject()

    if PlayerList.SpectateConn then
        PlayerList.SpectateConn:Disconnect()
        PlayerList.SpectateConn = nil
    end

    PlayerList.SpectateConn = targetPlayer.CharacterAdded:Connect(function()
        task.wait(0.2)
        if PlayerList.CurrentSpectating == targetPlayer then
            setSubject()
        end
    end)

    PlayerList.updateAllButtons()
end

function PlayerList.stopSpectate()
    PlayerList.CurrentSpectating = nil
    if PlayerList.SpectateConn then
        PlayerList.SpectateConn:Disconnect()
        PlayerList.SpectateConn = nil
    end

    Camera = Workspace.CurrentCamera or Camera
    local myChar = LocalPlayer and LocalPlayer.Character
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if myHum then
        Camera.CameraSubject = myHum
    end

    PlayerList.updateAllButtons()
end

function PlayerList.toggleSpectate(targetPlayer)
    if PlayerList.CurrentSpectating == targetPlayer then
        PlayerList.stopSpectate()
    else
        PlayerList.spectate(targetPlayer)
    end
end

-- ============================================================================
-- BLACKLIST LOGIC
-- ============================================================================
function PlayerList.isBlacklisted(targetPlayer)
    if not targetPlayer then return false end
    return _G.DarlingBlacklistedPlayers[targetPlayer.UserId] == true
        or _G.DarlingBlacklistedPlayers[targetPlayer.Name] == true
end

function PlayerList.toggleBlacklist(targetPlayer)
    if not targetPlayer then return end
    local uid = targetPlayer.UserId
    local name = targetPlayer.Name

    if PlayerList.isBlacklisted(targetPlayer) then
        _G.DarlingBlacklistedPlayers[uid] = nil
        _G.DarlingBlacklistedPlayers[name] = nil
    else
        _G.DarlingBlacklistedPlayers[uid] = true
        _G.DarlingBlacklistedPlayers[name] = true
    end

    PlayerList.updateCardButtons(uid)
end

-- ============================================================================
-- CARD RENDERING (WINDUI-NATIVE TRANSLUCENT GLASS & HEALTH REWORK)
-- ============================================================================
function PlayerList.createPlayerCard(player, parentFrame)
    if not player or player == LocalPlayer then return end
    local uid = player.UserId

    -- Remove existing card if present
    if PlayerList.Cards[uid] and PlayerList.Cards[uid].Card then
        pcall(function() PlayerList.Cards[uid].Card:Destroy() end)
    end

    -- Main Card (100% relative width, never overflows)
    local card = Instance.new("Frame")
    card.Name = "PlayerCard_" .. tostring(uid)
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    card.BackgroundTransparency = 0.45
    card.BorderSizePixel = 0
    card.Parent = parentFrame

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Color3.fromRGB(255, 255, 255)
    cardStroke.Transparency = 0.93
    cardStroke.Thickness = 1
    cardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    cardStroke.Parent = card

    local cardPadding = Instance.new("UIPadding")
    cardPadding.PaddingTop = UDim.new(0, 8)
    cardPadding.PaddingBottom = UDim.new(0, 8)
    cardPadding.PaddingLeft = UDim.new(0, 10)
    cardPadding.PaddingRight = UDim.new(0, 10)
    cardPadding.Parent = card

    local cardLayout = Instance.new("UIListLayout")
    cardLayout.FillDirection = Enum.FillDirection.Vertical
    cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
    cardLayout.Padding = UDim.new(0, 8)
    cardLayout.Parent = card

    -- ==================== ROW 1: AVATAR & INFO ====================
    local row1 = Instance.new("Frame")
    row1.Name = "InfoRow"
    row1.Size = UDim2.new(1, 0, 0, 72)
    row1.BackgroundTransparency = 1
    row1.BorderSizePixel = 0
    row1.Parent = card

    -- Avatar Box (Full body head-to-toe preview)
    local avatarBox = Instance.new("Frame")
    avatarBox.Name = "AvatarBox"
    avatarBox.Size = UDim2.new(0, 52, 0, 72)
    avatarBox.Position = UDim2.new(0, 0, 0, 0)
    avatarBox.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
    avatarBox.BackgroundTransparency = 0.35
    avatarBox.BorderSizePixel = 0
    avatarBox.Parent = row1

    local avCorner = Instance.new("UICorner")
    avCorner.CornerRadius = UDim.new(0, 6)
    avCorner.Parent = avatarBox

    local avStroke = Instance.new("UIStroke")
    avStroke.Color = Color3.fromRGB(255, 255, 255)
    avStroke.Transparency = 0.94
    avStroke.Thickness = 1
    avStroke.Parent = avatarBox

    local avatarImg = Instance.new("ImageLabel")
    avatarImg.Name = "AvatarSkin"
    avatarImg.Size = UDim2.new(1, 0, 1, 0)
    avatarImg.BackgroundTransparency = 1
    avatarImg.ScaleType = Enum.ScaleType.Fit
    avatarImg.Image = "rbxthumb://type=Avatar&id=" .. tostring(uid) .. "&w=420&h=420"
    avatarImg.Parent = avatarBox

    -- Async thumbnail fallback
    task.spawn(function()
        pcall(function()
            local thumb, isReady = Players:GetUserThumbnailAsync(
                uid,
                Enum.ThumbnailType.AvatarThumbnail,
                Enum.ThumbnailSize.Size420x420
            )
            if isReady and thumb and #thumb > 0 then
                avatarImg.Image = thumb
            end
        end)
    end)

    -- Player Info Column
    local infoCol = Instance.new("Frame")
    infoCol.Name = "InfoCol"
    infoCol.Size = UDim2.new(1, -62, 1, 0)
    infoCol.Position = UDim2.new(0, 62, 0, 0)
    infoCol.BackgroundTransparency = 1
    infoCol.BorderSizePixel = 0
    infoCol.Parent = row1

    local infoLayout = Instance.new("UIListLayout")
    infoLayout.FillDirection = Enum.FillDirection.Vertical
    infoLayout.SortOrder = Enum.SortOrder.LayoutOrder
    infoLayout.Padding = UDim.new(0, 3)
    infoLayout.Parent = infoCol

    -- DisplayName
    local dispLabel = Instance.new("TextLabel")
    dispLabel.Name = "DisplayName"
    dispLabel.Size = UDim2.new(1, 0, 0, 16)
    dispLabel.BackgroundTransparency = 1
    dispLabel.Text = player.DisplayName
    dispLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    dispLabel.Font = Enum.Font.GothamBold
    dispLabel.TextSize = 13
    dispLabel.TextXAlignment = Enum.TextXAlignment.Left
    dispLabel.TextTruncate = Enum.TextTruncate.AtEnd
    dispLabel.Parent = infoCol

    -- SubRow: Username & Team Badge
    local subRow = Instance.new("Frame")
    subRow.Name = "SubRow"
    subRow.Size = UDim2.new(1, 0, 0, 15)
    subRow.BackgroundTransparency = 1
    subRow.BorderSizePixel = 0
    subRow.Parent = infoCol

    local subLayout = Instance.new("UIListLayout")
    subLayout.FillDirection = Enum.FillDirection.Horizontal
    subLayout.SortOrder = Enum.SortOrder.LayoutOrder
    subLayout.Padding = UDim.new(0, 6)
    subLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    subLayout.Parent = subRow

    local userLabel = Instance.new("TextLabel")
    userLabel.Name = "Username"
    userLabel.Size = UDim2.new(0, 0, 1, 0)
    userLabel.AutomaticSize = Enum.AutomaticSize.X
    userLabel.BackgroundTransparency = 1
    userLabel.Text = "@" .. player.Name
    userLabel.TextColor3 = Color3.fromRGB(140, 140, 155)
    userLabel.Font = Enum.Font.Gotham
    userLabel.TextSize = 11
    userLabel.TextXAlignment = Enum.TextXAlignment.Left
    userLabel.TextTruncate = Enum.TextTruncate.AtEnd
    userLabel.Parent = subRow

    local isMarine = player.Team and player.Team.Name == "Marines"
    local teamBadge = Instance.new("Frame")
    teamBadge.Name = "TeamBadge"
    teamBadge.Size = UDim2.new(0, 0, 0, 14)
    teamBadge.AutomaticSize = Enum.AutomaticSize.X
    teamBadge.BackgroundColor3 = isMarine and Color3.fromRGB(20, 45, 80) or Color3.fromRGB(70, 35, 20)
    teamBadge.BackgroundTransparency = 0.4
    teamBadge.BorderSizePixel = 0
    teamBadge.Parent = subRow

    local tbCorner = Instance.new("UICorner")
    tbCorner.CornerRadius = UDim.new(0, 4)
    tbCorner.Parent = teamBadge

    local tbPadding = Instance.new("UIPadding")
    tbPadding.PaddingLeft = UDim.new(0, 5)
    tbPadding.PaddingRight = UDim.new(0, 5)
    tbPadding.Parent = teamBadge

    local tbLabel = Instance.new("TextLabel")
    tbLabel.Name = "TeamLabel"
    tbLabel.Size = UDim2.new(1, 0, 1, 0)
    tbLabel.BackgroundTransparency = 1
    tbLabel.Text = (player.Team and player.Team.Name) or "Neutral"
    tbLabel.TextColor3 = isMarine and Color3.fromRGB(80, 180, 255) or Color3.fromRGB(255, 145, 80)
    tbLabel.Font = Enum.Font.GothamBold
    tbLabel.TextSize = 9
    tbLabel.Parent = teamBadge

    -- Modern Micro Health Track (4px height)
    local hpBg = Instance.new("Frame")
    hpBg.Name = "HealthBg"
    hpBg.Size = UDim2.new(1, 0, 0, 4)
    hpBg.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    hpBg.BorderSizePixel = 0
    hpBg.Parent = infoCol

    local hpBgCorner = Instance.new("UICorner")
    hpBgCorner.CornerRadius = UDim.new(1, 0)
    hpBgCorner.Parent = hpBg

    local hpFill = Instance.new("Frame")
    hpFill.Name = "HealthFill"
    hpFill.Size = UDim2.new(1, 0, 1, 0)
    hpFill.BackgroundColor3 = Color3.fromRGB(56, 189, 248) -- Ice Cyan Accent
    hpFill.BorderSizePixel = 0
    hpFill.Parent = hpBg

    local hpFillCorner = Instance.new("UICorner")
    hpFillCorner.CornerRadius = UDim.new(1, 0)
    hpFillCorner.Parent = hpFill

    -- Health Status Row (Pill + Numeric HP)
    local hpRow = Instance.new("Frame")
    hpRow.Name = "HealthRow"
    hpRow.Size = UDim2.new(1, 0, 0, 15)
    hpRow.BackgroundTransparency = 1
    hpRow.BorderSizePixel = 0
    hpRow.Parent = infoCol

    local hpRowLayout = Instance.new("UIListLayout")
    hpRowLayout.FillDirection = Enum.FillDirection.Horizontal
    hpRowLayout.SortOrder = Enum.SortOrder.LayoutOrder
    hpRowLayout.Padding = UDim.new(0, 6)
    hpRowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    hpRowLayout.Parent = hpRow

    local hpPill = Instance.new("Frame")
    hpPill.Name = "HealthPill"
    hpPill.Size = UDim2.new(0, 0, 0, 14)
    hpPill.AutomaticSize = Enum.AutomaticSize.X
    hpPill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    hpPill.BackgroundTransparency = 0.92
    hpPill.BorderSizePixel = 0
    hpPill.Parent = hpRow

    local pillCorner = Instance.new("UICorner")
    pillCorner.CornerRadius = UDim.new(0, 4)
    pillCorner.Parent = hpPill

    local pillPadding = Instance.new("UIPadding")
    pillPadding.PaddingLeft = UDim.new(0, 5)
    pillPadding.PaddingRight = UDim.new(0, 5)
    pillPadding.Parent = hpPill

    local pillLabel = Instance.new("TextLabel")
    pillLabel.Name = "PillLabel"
    pillLabel.Size = UDim2.new(1, 0, 1, 0)
    pillLabel.BackgroundTransparency = 1
    pillLabel.Text = "100%"
    pillLabel.TextColor3 = Color3.fromRGB(56, 189, 248)
    pillLabel.Font = Enum.Font.GothamBold
    pillLabel.TextSize = 9
    pillLabel.Parent = hpPill

    local hpNumLabel = Instance.new("TextLabel")
    hpNumLabel.Name = "HealthNum"
    hpNumLabel.Size = UDim2.new(1, -50, 1, 0)
    hpNumLabel.BackgroundTransparency = 1
    hpNumLabel.Text = "100 / 100 HP"
    hpNumLabel.TextColor3 = Color3.fromRGB(165, 165, 180)
    hpNumLabel.Font = Enum.Font.GothamMedium
    hpNumLabel.TextSize = 10
    hpNumLabel.TextXAlignment = Enum.TextXAlignment.Left
    hpNumLabel.TextTruncate = Enum.TextTruncate.AtEnd
    hpNumLabel.Parent = hpRow

    -- ==================== ROW 2: ACTION BUTTONS ====================
    local btnRow = Instance.new("Frame")
    btnRow.Name = "ButtonRow"
    btnRow.Size = UDim2.new(1, 0, 0, 28)
    btnRow.BackgroundTransparency = 1
    btnRow.BorderSizePixel = 0
    btnRow.Parent = card

    local btnRowLayout = Instance.new("UIListLayout")
    btnRowLayout.FillDirection = Enum.FillDirection.Horizontal
    btnRowLayout.SortOrder = Enum.SortOrder.LayoutOrder
    btnRowLayout.Padding = UDim.new(0, 6)
    btnRowLayout.Parent = btnRow

    -- Blacklist Button (Ghost WindUI style)
    local blBtn = Instance.new("TextButton")
    blBtn.Name = "BlacklistBtn"
    blBtn.Size = UDim2.new(0.5, -3, 1, 0)
    blBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    blBtn.BackgroundTransparency = 0.94
    blBtn.BorderSizePixel = 0
    blBtn.Text = "Blacklist"
    blBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
    blBtn.Font = Enum.Font.GothamMedium
    blBtn.TextSize = 11
    blBtn.AutoButtonColor = true
    blBtn.Parent = btnRow

    local blCorner = Instance.new("UICorner")
    blCorner.CornerRadius = UDim.new(0, 6)
    blCorner.Parent = blBtn

    local blStroke = Instance.new("UIStroke")
    blStroke.Color = Color3.fromRGB(255, 255, 255)
    blStroke.Transparency = 0.90
    blStroke.Thickness = 1
    blStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    blStroke.Parent = blBtn

    blBtn.MouseButton1Click:Connect(function()
        PlayerList.toggleBlacklist(player)
    end)

    -- Spectate Button (Ghost WindUI style)
    local specBtn = Instance.new("TextButton")
    specBtn.Name = "SpectateBtn"
    specBtn.Size = UDim2.new(0.5, -3, 1, 0)
    specBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    specBtn.BackgroundTransparency = 0.94
    specBtn.BorderSizePixel = 0
    specBtn.Text = "Spectate"
    specBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
    specBtn.Font = Enum.Font.GothamMedium
    specBtn.TextSize = 11
    specBtn.AutoButtonColor = true
    specBtn.Parent = btnRow

    local specCorner = Instance.new("UICorner")
    specCorner.CornerRadius = UDim.new(0, 6)
    specCorner.Parent = specBtn

    local specStroke = Instance.new("UIStroke")
    specStroke.Color = Color3.fromRGB(255, 255, 255)
    specStroke.Transparency = 0.90
    specStroke.Thickness = 1
    specStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    specStroke.Parent = specBtn

    specBtn.MouseButton1Click:Connect(function()
        PlayerList.toggleSpectate(player)
    end)

    -- Live Health Update Function (Reworked Color Palette)
    local function updateHealth()
        pcall(function()
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local hp = math.max(0, hum.Health)
                local maxHp = math.max(1, hum.MaxHealth)
                local ratio = math.clamp(hp / maxHp, 0, 1)

                hpFill.Size = UDim2.new(ratio, 0, 1, 0)
                local accentColor
                if ratio > 0.5 then
                    accentColor = Color3.fromRGB(56, 189, 248) -- Ice Cyan Accent
                elseif ratio > 0.25 then
                    accentColor = Color3.fromRGB(251, 191, 36) -- Warm Amber
                else
                    accentColor = Color3.fromRGB(244, 63, 94)  -- Coral Crimson
                end

                hpFill.BackgroundColor3 = accentColor
                pillLabel.Text = string.format("%d%%", math.floor(ratio * 100))
                pillLabel.TextColor3 = accentColor
                hpNumLabel.Text = string.format("%d / %d HP", math.floor(hp), math.floor(maxHp))
                hpNumLabel.TextColor3 = Color3.fromRGB(165, 165, 180)
            else
                hpFill.Size = UDim2.new(0, 0, 1, 0)
                pillLabel.Text = "DEAD"
                pillLabel.TextColor3 = Color3.fromRGB(244, 63, 94)
                hpNumLabel.Text = "Respawning..."
                hpNumLabel.TextColor3 = Color3.fromRGB(130, 130, 145)
            end
        end)
    end

    updateHealth()

    -- Hook CharacterAdded & HealthChanged
    local function hookChar(c)
        if not c then return end
        local hum = c:WaitForChild("Humanoid", 4)
        if hum then
            updateHealth()
            hum.HealthChanged:Connect(updateHealth)
        end
    end

    if player.Character then hookChar(player.Character) end
    player.CharacterAdded:Connect(hookChar)

    -- Save reference
    PlayerList.Cards[uid] = {
        Card = card,
        Player = player,
        BlacklistBtn = blBtn,
        BlacklistStroke = blStroke,
        SpectateBtn = specBtn,
        SpectateStroke = specStroke,
        UpdateHealth = updateHealth,
    }

    PlayerList.updateCardButtons(uid)
end

function PlayerList.updateCardButtons(uid)
    local item = PlayerList.Cards[uid]
    if not item then return end
    local pl = item.Player

    -- Spectate button state
    if PlayerList.CurrentSpectating == pl then
        item.SpectateBtn.BackgroundColor3 = Color3.fromRGB(50, 140, 245)
        item.SpectateBtn.BackgroundTransparency = 0.2
        item.SpectateStroke.Color = Color3.fromRGB(90, 170, 255)
        item.SpectateStroke.Transparency = 0.4
        item.SpectateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        item.SpectateBtn.Text = "Viewing"
    else
        item.SpectateBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        item.SpectateBtn.BackgroundTransparency = 0.94
        item.SpectateStroke.Color = Color3.fromRGB(255, 255, 255)
        item.SpectateStroke.Transparency = 0.90
        item.SpectateBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
        item.SpectateBtn.Text = "Spectate"
    end

    -- Blacklist button state
    if PlayerList.isBlacklisted(pl) then
        item.BlacklistBtn.BackgroundColor3 = Color3.fromRGB(220, 45, 75)
        item.BlacklistBtn.BackgroundTransparency = 0.2
        item.BlacklistStroke.Color = Color3.fromRGB(255, 80, 110)
        item.BlacklistStroke.Transparency = 0.4
        item.BlacklistBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        item.BlacklistBtn.Text = "Blacklisted"
    else
        item.BlacklistBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        item.BlacklistBtn.BackgroundTransparency = 0.94
        item.BlacklistStroke.Color = Color3.fromRGB(255, 255, 255)
        item.BlacklistStroke.Transparency = 0.90
        item.BlacklistBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
        item.BlacklistBtn.Text = "Blacklist"
    end
end

function PlayerList.updateAllButtons()
    for uid, _ in pairs(PlayerList.Cards) do
        PlayerList.updateCardButtons(uid)
    end
end

-- ============================================================================
-- MOUNT INTO PLAYERS TAB
-- ============================================================================
function PlayerList.mount(container)
    if not container then return end

    local targetFrame = container
    if typeof(container) == "table" then
        targetFrame = (container.UIElements and container.UIElements.ContainerFrame)
            or container.ContainerFrame
            or (container.UIElements and container.UIElements.Main)
    end
    if not targetFrame or typeof(targetFrame) ~= "Instance" then return end
    PlayerList.Container = targetFrame

    -- Container Frame for all player cards
    local listFrame = Instance.new("Frame")
    listFrame.Name = "DarlingPlayerList"
    listFrame.Size = UDim2.new(1, 0, 0, 0)
    listFrame.AutomaticSize = Enum.AutomaticSize.Y
    listFrame.BackgroundTransparency = 1
    listFrame.BorderSizePixel = 0
    listFrame.Parent = targetFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 8)
    listLayout.Parent = listFrame

    PlayerList.ListFrame = listFrame

    local function populate()
        for _, child in ipairs(listFrame:GetChildren()) do
            if child:IsA("Frame") and child.Name:find("PlayerCard_") then
                child:Destroy()
            end
        end
        PlayerList.Cards = {}

        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= LocalPlayer then
                PlayerList.createPlayerCard(pl, listFrame)
            end
        end
    end

    populate()

    -- PlayerAdded & PlayerRemoving Listeners
    table.insert(PlayerList.Connections, Players.PlayerAdded:Connect(function(pl)
        if pl ~= LocalPlayer then
            task.wait(0.5)
            PlayerList.createPlayerCard(pl, listFrame)
        end
    end))

    table.insert(PlayerList.Connections, Players.PlayerRemoving:Connect(function(pl)
        if PlayerList.CurrentSpectating == pl then
            PlayerList.stopSpectate()
        end
        if PlayerList.Cards[pl.UserId] and PlayerList.Cards[pl.UserId].Card then
            PlayerList.Cards[pl.UserId].Card:Destroy()
            PlayerList.Cards[pl.UserId] = nil
        end
    end))

    -- Periodic health poll every 2s
    table.insert(PlayerList.Connections, task.spawn(function()
        while true do
            task.wait(2)
            for _, item in pairs(PlayerList.Cards) do
                if item and item.UpdateHealth then
                    item.UpdateHealth()
                end
            end
        end
    end))
end

function PlayerList.destroy()
    PlayerList.stopSpectate()
    for _, c in ipairs(PlayerList.Connections) do
        if typeof(c) == "RBXScriptConnection" then
            pcall(function() c:Disconnect() end)
        end
    end
    PlayerList.Connections = {}
    if PlayerList.ListFrame then
        PlayerList.ListFrame:Destroy()
        PlayerList.ListFrame = nil
    end
    PlayerList.Cards = {}
end

return PlayerList
