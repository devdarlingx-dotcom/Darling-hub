--[[
    Darling Hub - Advanced PvP Player ESP & Multi-Tracers
    High-performance Player ESP: 2D Quad Boxes, Health Bars, Names, Distance, Tool, Chams, and Multi-Tracers.
]]--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local ESP = {
    Enabled = false,
    Boxes = false,
    Names = false,
    Health = false,
    Distance = false,
    Tool = false,
    Chams = false,
    TracersAll = false,

    BoxColor = Color3.fromRGB(255, 255, 255),
    NameColor = Color3.fromRGB(255, 255, 255),
    TracerColor = Color3.fromRGB(192, 132, 252),
    ChamsColor = Color3.fromRGB(244, 63, 94),

    Cache = {},
    RenderConnection = nil,
}

local function getGuiContainer()
    local ok, h = pcall(function() return gethui and gethui() end)
    if ok and h then return h end
    local ok2, c = pcall(function() return CoreGui end)
    if ok2 and c then return c end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local OverlayGui = nil
local function getOverlayGui()
    if OverlayGui and OverlayGui.Parent then return OverlayGui end
    local parent = getGuiContainer()
    local existing = parent:FindFirstChild("DarlingESPOverlay")
    if existing then
        OverlayGui = existing
        return OverlayGui
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "DarlingESPOverlay"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 2147481000
    if syn and syn.protect_gui then pcall(syn.protect_gui, gui) end
    gui.Parent = parent
    OverlayGui = gui
    return gui
end

local function createPlayerEntry(player)
    local entry = {
        Player = player,
        Highlight = nil,
        BoxOutline = nil,
        Box = nil,
        HealthBarBg = nil,
        HealthBar = nil,
        NameLabel = nil,
        InfoLabel = nil,
        TracerLine = nil,
    }

    local overlay = getOverlayGui()

    -- 2D Box
    local boxOutline = Instance.new("Frame")
    boxOutline.Name = "BoxOutline"
    boxOutline.BackgroundTransparency = 1
    boxOutline.BorderSizePixel = 0
    boxOutline.Visible = false
    boxOutline.Parent = overlay

    local strokeOut = Instance.new("UIStroke")
    strokeOut.Color = Color3.fromRGB(0, 0, 0)
    strokeOut.Thickness = 2.5
    strokeOut.Parent = boxOutline

    local box = Instance.new("Frame")
    box.Name = "Box"
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Size = UDim2.fromScale(1, 1)
    box.Parent = boxOutline

    local strokeIn = Instance.new("UIStroke")
    strokeIn.Color = ESP.BoxColor
    strokeIn.Thickness = 1.2
    strokeIn.Parent = box

    -- Health Bar
    local hpBg = Instance.new("Frame")
    hpBg.Name = "HPBg"
    hpBg.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    hpBg.BorderSizePixel = 0
    hpBg.Visible = false
    hpBg.Parent = overlay

    local hpFill = Instance.new("Frame")
    hpFill.Name = "HPFill"
    hpFill.BackgroundColor3 = Color3.fromRGB(56, 224, 128)
    hpFill.BorderSizePixel = 0
    hpFill.Size = UDim2.fromScale(1, 1)
    hpFill.AnchorPoint = Vector2.new(0, 1)
    hpFill.Position = UDim2.fromScale(0, 1)
    hpFill.Parent = hpBg

    -- Name Label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 11
    nameLabel.TextColor3 = ESP.NameColor
    nameLabel.TextStrokeTransparency = 0.2
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Visible = false
    nameLabel.Parent = overlay

    -- Info Label (Distance + Tool)
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Name = "Info"
    infoLabel.BackgroundTransparency = 1
    infoLabel.Font = Enum.Font.GothamMedium
    infoLabel.TextSize = 9
    infoLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
    infoLabel.TextStrokeTransparency = 0.3
    infoLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    infoLabel.Visible = false
    infoLabel.Parent = overlay

    -- Tracer Line (UI Frame rotated or Drawing line)
    local tracerFrame = Instance.new("Frame")
    tracerFrame.Name = "Tracer"
    tracerFrame.BackgroundColor3 = ESP.TracerColor
    tracerFrame.BorderSizePixel = 0
    tracerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    tracerFrame.Visible = false
    tracerFrame.Parent = overlay

    entry.BoxOutline = boxOutline
    entry.Box = box
    entry.BoxStroke = strokeIn
    entry.HealthBarBg = hpBg
    entry.HealthBar = hpFill
    entry.NameLabel = nameLabel
    entry.InfoLabel = infoLabel
    entry.TracerLine = tracerFrame

    ESP.Cache[player] = entry
    return entry
end

local function removePlayerEntry(player)
    local entry = ESP.Cache[player]
    if entry then
        if entry.Highlight then pcall(function() entry.Highlight:Destroy() end) end
        if entry.BoxOutline then pcall(function() entry.BoxOutline:Destroy() end) end
        if entry.HealthBarBg then pcall(function() entry.HealthBarBg:Destroy() end) end
        if entry.NameLabel then pcall(function() entry.NameLabel:Destroy() end) end
        if entry.InfoLabel then pcall(function() entry.InfoLabel:Destroy() end) end
        if entry.TracerLine then pcall(function() entry.TracerLine:Destroy() end) end
        ESP.Cache[player] = nil
    end
end

local function drawTracerLine(frame, x1, y1, x2, y2, color)
    local distance = math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
    local angle = math.deg(math.atan2(y2 - y1, x2 - x1))

    frame.Size = UDim2.fromOffset(distance, 1.5)
    frame.Position = UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2)
    frame.Rotation = angle
    frame.BackgroundColor3 = color
    frame.Visible = true
end

local function updatePlayerESP(entry)
    local p = entry.Player
    local char = p and p.Character
    local cam = Workspace.CurrentCamera or Camera
    if not char or not cam then
        entry.BoxOutline.Visible = false
        entry.HealthBarBg.Visible = false
        entry.NameLabel.Visible = false
        entry.InfoLabel.Visible = false
        entry.TracerLine.Visible = false
        if entry.Highlight then entry.Highlight.Enabled = false end
        return
    end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then
        entry.BoxOutline.Visible = false
        entry.HealthBarBg.Visible = false
        entry.NameLabel.Visible = false
        entry.InfoLabel.Visible = false
        entry.TracerLine.Visible = false
        if entry.Highlight then entry.Highlight.Enabled = false end
        return
    end

    local rootPos, onScreen = cam:WorldToViewportPoint(hrp.Position)
    if not onScreen then
        entry.BoxOutline.Visible = false
        entry.HealthBarBg.Visible = false
        entry.NameLabel.Visible = false
        entry.InfoLabel.Visible = false
        entry.TracerLine.Visible = false
        if entry.Highlight then entry.Highlight.Enabled = false end
        return
    end

    local head = char:FindFirstChild("Head")
    local headPos = head and head.Position or (hrp.Position + Vector3.new(0, 2, 0))
    local topPos = cam:WorldToViewportPoint(headPos + Vector3.new(0, 1.2, 0))
    local bottomPos = cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3.0, 0))

    local boxHeight = math.abs(topPos.Y - bottomPos.Y)
    local boxWidth = boxHeight * 0.65
    local boxX = rootPos.X - boxWidth / 2
    local boxY = topPos.Y

    -- 1. Box ESP
    if ESP.Boxes and ESP.Enabled then
        entry.BoxOutline.Position = UDim2.fromOffset(boxX, boxY)
        entry.BoxOutline.Size = UDim2.fromOffset(boxWidth, boxHeight)
        entry.BoxStroke.Color = ESP.BoxColor
        entry.BoxOutline.Visible = true
    else
        entry.BoxOutline.Visible = false
    end

    -- 2. Health Bar
    if ESP.Health and ESP.Enabled then
        local hpPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
        entry.HealthBarBg.Position = UDim2.fromOffset(boxX - 6, boxY)
        entry.HealthBarBg.Size = UDim2.fromOffset(3, boxHeight)
        entry.HealthBar.Size = UDim2.fromScale(1, hpPercent)
        entry.HealthBar.BackgroundColor3 = Color3.fromHSV(hpPercent * 0.33, 1, 1)
        entry.HealthBarBg.Visible = true
    else
        entry.HealthBarBg.Visible = false
    end

    -- 3. Name Label
    if ESP.Names and ESP.Enabled then
        entry.NameLabel.Text = p.DisplayName .. " (@" .. p.Name .. ")"
        entry.NameLabel.TextColor3 = ESP.NameColor
        entry.NameLabel.Position = UDim2.fromOffset(rootPos.X - 100, boxY - 16)
        entry.NameLabel.Size = UDim2.fromOffset(200, 14)
        entry.NameLabel.Visible = true
    else
        entry.NameLabel.Visible = false
    end

    -- 4. Info Label (Distance & Tool)
    local infoParts = {}
    if ESP.Distance and ESP.Enabled then
        local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local dist = myHRP and math.floor((hrp.Position - myHRP.Position).Magnitude) or 0
        table.insert(infoParts, tostring(dist) .. "m")
    end
    if ESP.Tool and ESP.Enabled then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            table.insert(infoParts, tool.Name)
        end
    end
    if #infoParts > 0 and ESP.Enabled then
        entry.InfoLabel.Text = table.concat(infoParts, " • ")
        entry.InfoLabel.Position = UDim2.fromOffset(rootPos.X - 100, boxY + boxHeight + 2)
        entry.InfoLabel.Size = UDim2.fromOffset(200, 12)
        entry.InfoLabel.Visible = true
    else
        entry.InfoLabel.Visible = false
    end

    -- 5. Multi-Tracers (to ALL visible players from bottom of screen)
    if ESP.TracersAll and ESP.Enabled then
        local vp = cam.ViewportSize
        drawTracerLine(entry.TracerLine, vp.X * 0.5, vp.Y, rootPos.X, boxY + boxHeight, ESP.TracerColor)
    else
        entry.TracerLine.Visible = false
    end

    -- 6. Chams / Highlight
    if ESP.Chams and ESP.Enabled then
        if not entry.Highlight or entry.Highlight.Parent ~= char then
            if entry.Highlight then entry.Highlight:Destroy() end
            local hl = Instance.new("Highlight")
            hl.Name = "DarlingChams"
            hl.FillColor = ESP.ChamsColor
            hl.FillTransparency = 0.5
            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
            hl.OutlineTransparency = 0.1
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Adornee = char
            hl.Parent = char
            entry.Highlight = hl
        else
            entry.Highlight.FillColor = ESP.ChamsColor
            entry.Highlight.Enabled = true
        end
    elseif entry.Highlight then
        entry.Highlight.Enabled = false
    end
end

function ESP.renderStep()
    if not ESP.Enabled then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local entry = ESP.Cache[p] or createPlayerEntry(p)
            updatePlayerESP(entry)
        end
    end
end

function ESP.setEnabled(state)
    ESP.Enabled = state
    if state and not ESP.RenderConnection then
        ESP.RenderConnection = RunService.RenderStepped:Connect(ESP.renderStep)
    elseif not state and ESP.RenderConnection then
        pcall(function() ESP.RenderConnection:Disconnect() end)
        ESP.RenderConnection = nil
        for _, entry in pairs(ESP.Cache) do
            entry.BoxOutline.Visible = false
            entry.HealthBarBg.Visible = false
            entry.NameLabel.Visible = false
            entry.InfoLabel.Visible = false
            entry.TracerLine.Visible = false
            if entry.Highlight then entry.Highlight.Enabled = false end
        end
    end
end

Players.PlayerAdded:Connect(function(p)
    if ESP.Enabled then createPlayerEntry(p) end
end)

Players.PlayerRemoving:Connect(removePlayerEntry)

return ESP
