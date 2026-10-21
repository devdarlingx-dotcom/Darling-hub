--[[
    Darling Hub - Player List & Management Module
    Displays each server player with:
    - Full-body avatar skin model preview (head to toe)
    - Live health bar and numerical HP display
    - Individual Aimbot Blacklist toggle
    - Spectate camera toggle
]]--

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

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

    PlayerList.SpectateConn = targetPlayer.CharacterAdded:Connect(function(newChar)
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
    local myChar = LocalPlayer.Character
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if myHum then
        Camera.CameraSubject = myHum
    elseif myChar then
        Camera.CameraSubject = myChar:FindFirstChild("HumanoidRootPart") or myChar
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
function PlayerList.isBlacklisted(player)
    if not player then return false end
    local uid = player.UserId
    local name = player.Name
    return (_G.DarlingBlacklistedPlayers[uid] == true) or (_G.DarlingBlacklistedPlayers[name] == true)
end

function PlayerList.toggleBlacklist(player)
    if not player then return end
    local uid = player.UserId
    local name = player.Name
    local current = PlayerList.isBlacklisted(player)
    local newState = not current

    _G.DarlingBlacklistedPlayers[uid] = newState and true or nil
    _G.DarlingBlacklistedPlayers[name] = newState and true or nil

    PlayerList.updateAllButtons()
    return newState
end

-- ============================================================================
-- UI CARD CREATION
-- ============================================================================
function PlayerList.createPlayerCard(player, parentContainer)
    if not player or not parentContainer then return nil end

    local card = Instance.new("Frame")
    card.Name = "PlayerCard_" .. player.Name
    card.Size = UDim2.new(1, 0, 0, 106)
    card.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
    card.BorderSizePixel = 0

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Color3.fromRGB(36, 36, 46)
    cardStroke.Thickness = 1
    cardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    cardStroke.Parent = card

    -- Avatar Box (Full Skin Body Preview)
    local avatarBox = Instance.new("Frame")
    avatarBox.Name = "AvatarBox"
    avatarBox.Size = UDim2.new(0, 72, 0, 92)
    avatarBox.Position = UDim2.new(0, 7, 0, 7)
    avatarBox.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
    avatarBox.BorderSizePixel = 0
    avatarBox.Parent = card

    local avatarCorner = Instance.new("UICorner")
    avatarCorner.CornerRadius = UDim.new(0, 6)
    avatarCorner.Parent = avatarBox

    local avatarImg = Instance.new("ImageLabel")
    avatarImg.Name = "AvatarSkin"
    avatarImg.Size = UDim2.new(1, 0, 1, 0)
    avatarImg.BackgroundTransparency = 1
    avatarImg.ScaleType = Enum.ScaleType.Fit
    -- High-definition full-body skin thumbnail
    avatarImg.Image = "rbxthumb://type=Avatar&id=" .. tostring(player.UserId) .. "&w=420&h=420"
    avatarImg.Parent = avatarBox

    -- Asynchronous thumbnail fallback
    task.spawn(function()
        pcall(function()
            local thumb, isReady = Players:GetUserThumbnailAsync(
                player.UserId,
                Enum.ThumbnailType.AvatarThumbnail,
                Enum.ThumbnailSize.Size420x420
            )
            if isReady and thumb and #thumb > 0 then
                avatarImg.Image = thumb
            end
        end)
    end)

    -- Info Area
    local infoFrame = Instance.new("Frame")
    infoFrame.Name = "Info"
    infoFrame.BackgroundTransparency = 1
    infoFrame.Position = UDim2.new(0, 86, 0, 8)
    infoFrame.Size = UDim2.new(1, -280, 0, 90)
    infoFrame.Parent = card

    -- Display Name
    local displayNameLabel = Instance.new("TextLabel")
    displayNameLabel.Name = "DisplayName"
    displayNameLabel.Size = UDim2.new(1, 0, 0, 18)
    displayNameLabel.Position = UDim2.new(0, 0, 0, 0)
    displayNameLabel.BackgroundTransparency = 1
    displayNameLabel.Text = player.DisplayName
    displayNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    displayNameLabel.Font = Enum.Font.GothamBold
    displayNameLabel.TextSize = 13
    displayNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    displayNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    displayNameLabel.Parent = infoFrame

    -- Username
    local usernameLabel = Instance.new("TextLabel")
    usernameLabel.Name = "Username"
    usernameLabel.Size = UDim2.new(1, 0, 0, 14)
    usernameLabel.Position = UDim2.new(0, 0, 0, 18)
    usernameLabel.BackgroundTransparency = 1
    usernameLabel.Text = "@" .. player.Name
    usernameLabel.TextColor3 = Color3.fromRGB(140, 140, 155)
    usernameLabel.Font = Enum.Font.Gotham
    usernameLabel.TextSize = 11
    usernameLabel.TextXAlignment = Enum.TextXAlignment.Left
    usernameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    usernameLabel.Parent = infoFrame

    -- Health Bar Background
    local hpBg = Instance.new("Frame")
    hpBg.Name = "HealthBarBg"
    hpBg.Size = UDim2.new(1, 0, 0, 8)
    hpBg.Position = UDim2.new(0, 0, 0, 42)
    hpBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    hpBg.BorderSizePixel = 0
    hpBg.Parent = infoFrame

    local hpBgCorner = Instance.new("UICorner")
    hpBgCorner.CornerRadius = UDim.new(0, 4)
    hpBgCorner.Parent = hpBg

    -- Health Bar Fill
    local hpFill = Instance.new("Frame")
    hpFill.Name = "HealthBarFill"
    hpFill.Size = UDim2.new(1, 0, 1, 0)
    hpFill.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
    hpFill.BorderSizePixel = 0
    hpFill.Parent = hpBg

    local hpFillCorner = Instance.new("UICorner")
    hpFillCorner.CornerRadius = UDim.new(0, 4)
    hpFillCorner.Parent = hpFill

    -- Health Text
    local hpLabel = Instance.new("TextLabel")
    hpLabel.Name = "HealthText"
    hpLabel.Size = UDim2.new(1, 0, 0, 16)
    hpLabel.Position = UDim2.new(0, 0, 0, 54)
    hpLabel.BackgroundTransparency = 1
    hpLabel.Text = "HP: ..."
    hpLabel.TextColor3 = Color3.fromRGB(200, 200, 215)
    hpLabel.Font = Enum.Font.GothamMedium
    hpLabel.TextSize = 11
    hpLabel.TextXAlignment = Enum.TextXAlignment.Left
    hpLabel.Parent = infoFrame

    -- Team Badge
    local teamLabel = Instance.new("TextLabel")
    teamLabel.Name = "TeamText"
    teamLabel.Size = UDim2.new(1, 0, 0, 14)
    teamLabel.Position = UDim2.new(0, 0, 0, 72)
    teamLabel.BackgroundTransparency = 1
    teamLabel.Text = player.Team and player.Team.Name or "Neutral"
    teamLabel.TextColor3 = (player.Team and player.Team.Name == "Marines") and Color3.fromRGB(70, 160, 255) or Color3.fromRGB(255, 120, 60)
    teamLabel.Font = Enum.Font.Gotham
    teamLabel.TextSize = 10
    teamLabel.TextXAlignment = Enum.TextXAlignment.Left
    teamLabel.Parent = infoFrame

    -- Controls Container (Right Side)
    local btnContainer = Instance.new("Frame")
    btnContainer.Name = "Controls"
    btnContainer.BackgroundTransparency = 1
    btnContainer.AnchorPoint = Vector2.new(1, 0.5)
    btnContainer.Position = UDim2.new(1, -8, 0.5, 0)
    btnContainer.Size = UDim2.new(0, 180, 0, 90)
    btnContainer.Parent = card

    -- Spectate Button
    local spectateBtn = Instance.new("TextButton")
    spectateBtn.Name = "SpectateButton"
    spectateBtn.Size = UDim2.new(0, 85, 0, 36)
    spectateBtn.Position = UDim2.new(0, 0, 0, 27)
    spectateBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    spectateBtn.BorderSizePixel = 0
    spectateBtn.Text = "Spectate"
    spectateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    spectateBtn.Font = Enum.Font.GothamBold
    spectateBtn.TextSize = 11
    spectateBtn.AutoButtonColor = true
    spectateBtn.Parent = btnContainer

    local specCorner = Instance.new("UICorner")
    specCorner.CornerRadius = UDim.new(0, 6)
    specCorner.Parent = spectateBtn

    spectateBtn.MouseButton1Click:Connect(function()
        PlayerList.toggleSpectate(player)
    end)

    -- Blacklist Button
    local blacklistBtn = Instance.new("TextButton")
    blacklistBtn.Name = "BlacklistButton"
    blacklistBtn.Size = UDim2.new(0, 90, 0, 36)
    blacklistBtn.Position = UDim2.new(0, 90, 0, 27)
    blacklistBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    blacklistBtn.BorderSizePixel = 0
    blacklistBtn.Text = "Blacklist"
    blacklistBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    blacklistBtn.Font = Enum.Font.GothamBold
    blacklistBtn.TextSize = 11
    blacklistBtn.AutoButtonColor = true
    blacklistBtn.Parent = btnContainer

    local blCorner = Instance.new("UICorner")
    blCorner.CornerRadius = UDim.new(0, 6)
    blCorner.Parent = blacklistBtn

    blacklistBtn.MouseButton1Click:Connect(function()
        PlayerList.toggleBlacklist(player)
    end)

    -- Health Update Function
    local function updateHealth()
        pcall(function()
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local hp = math.max(0, hum.Health)
                local maxHp = math.max(1, hum.MaxHealth)
                local ratio = math.clamp(hp / maxHp, 0, 1)

                hpFill.Size = UDim2.new(ratio, 0, 1, 0)
                if ratio > 0.5 then
                    hpFill.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
                elseif ratio > 0.25 then
                    hpFill.BackgroundColor3 = Color3.fromRGB(255, 190, 40)
                else
                    hpFill.BackgroundColor3 = Color3.fromRGB(230, 50, 50)
                end

                hpLabel.Text = string.format("%d / %d HP (%d%%)", math.floor(hp), math.floor(maxHp), math.floor(ratio * 100))
            else
                hpFill.Size = UDim2.new(0, 0, 1, 0)
                hpLabel.Text = "Dead / Respawning"
                hpLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
            end
        end)
    end

    -- Initial Health update
    updateHealth()

    -- Live Health listener
    local function hookChar(c)
        local hum = c:WaitForChild("Humanoid", 5)
        if hum then
            updateHealth()
            hum.HealthChanged:Connect(updateHealth)
        end
    end

    if player.Character then hookChar(player.Character) end
    player.CharacterAdded:Connect(hookChar)

    card.Parent = parentContainer

    PlayerList.Cards[player.UserId] = {
        Card = card,
        Player = player,
        SpectateBtn = spectateBtn,
        BlacklistBtn = blacklistBtn,
        UpdateHealth = updateHealth,
    }

    PlayerList.updateCardButtons(player.UserId)
    return card
end

function PlayerList.updateCardButtons(userId)
    local item = PlayerList.Cards[userId]
    if not item then return end
    local pl = item.Player

    -- Spectate button state
    local isSpec = (PlayerList.CurrentSpectating == pl)
    if isSpec then
        item.SpectateBtn.BackgroundColor3 = Color3.fromRGB(45, 130, 255)
        item.SpectateBtn.Text = "Viewing"
    else
        item.SpectateBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
        item.SpectateBtn.Text = "Spectate"
    end

    -- Blacklist button state
    local isBl = PlayerList.isBlacklisted(pl)
    if isBl then
        item.BlacklistBtn.BackgroundColor3 = Color3.fromRGB(220, 45, 75)
        item.BlacklistBtn.Text = "Blacklisted"
    else
        item.BlacklistBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
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
        targetFrame = container.ContainerFrame or (container.UIElements and container.UIElements.ContainerFrame) or (container.UIElements and container.UIElements.Main)
    end
    if not targetFrame or typeof(targetFrame) ~= "Instance" then return end
    PlayerList.Container = targetFrame

    -- Card List Container
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
        -- Clear existing
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
