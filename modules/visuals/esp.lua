-- esp

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local ESP = {
    Boxes = false,
    Names = false,
    Health = false,
    Distance = false,
    Tool = false,
    Chams = false,
    TracersAll = false,

    BoxColor = Color3.fromRGB(255, 255, 255),
    NameColor = Color3.fromRGB(255, 255, 255),
    TracerColor = Color3.fromRGB(255, 255, 255),
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
    strokeOut.Thickness = 2.0
    strokeOut.Parent = boxOutline

    local box = Instance.new("Frame")
    box.Name = "Box"
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Size = UDim2.fromScale(1, 1)
    box.Parent = boxOutline

    local strokeIn = Instance.new("UIStroke")
    strokeIn.Color = ESP.BoxColor
    strokeIn.Thickness = 1.0
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

    -- Name Label (Compact & Clean)
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamMedium
    nameLabel.TextSize = 10
    nameLabel.TextColor3 = ESP.NameColor
    nameLabel.TextStrokeTransparency = 0.25
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Visible = false
    nameLabel.Parent = overlay

    -- Info Label (Distance + Tool)
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Name = "Info"
    infoLabel.BackgroundTransparency = 1
    infoLabel.Font = Enum.Font.GothamMedium
    infoLabel.TextSize = 8
    infoLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
    infoLabel.TextStrokeTransparency = 0.35
    infoLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    infoLabel.Visible = false
    infoLabel.Parent = overlay

    -- Tracer Snapline
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

    frame.Size = UDim2.fromOffset(distance, 1.2)
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
    local topPos = cam:WorldToViewportPoint(headPos + Vector3.new(0, 1.0, 0))
    local bottomPos = cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 2.8, 0))

    local boxHeight = math.abs(topPos.Y - bottomPos.Y)
    local boxWidth = boxHeight * 0.65
    local boxX = rootPos.X - boxWidth / 2
    local boxY = topPos.Y

    -- 1. Box ESP
    if ESP.Boxes then
        entry.BoxOutline.Position = UDim2.fromOffset(boxX, boxY)
        entry.BoxOutline.Size = UDim2.fromOffset(boxWidth, boxHeight)
        entry.BoxStroke.Color = ESP.BoxColor
        entry.BoxOutline.Visible = true
    else
        entry.BoxOutline.Visible = false
    end

    -- 2. Health Bar
    if ESP.Health then
        local hpPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
        entry.HealthBarBg.Position = UDim2.fromOffset(boxX - 5, boxY)
        entry.HealthBarBg.Size = UDim2.fromOffset(2.5, boxHeight)
        entry.HealthBar.Size = UDim2.fromScale(1, hpPercent)
        entry.HealthBar.BackgroundColor3 = Color3.fromHSV(hpPercent * 0.33, 1, 1)
        entry.HealthBarBg.Visible = true
    else
        entry.HealthBarBg.Visible = false
    end

    -- 3. Name Label (Compact)
    if ESP.Names then
        local dName = p.DisplayName
        if entry.CachedName ~= dName then
            entry.CachedName = dName
            entry.NameLabel.Text = dName
        end
        entry.NameLabel.TextColor3 = ESP.NameColor
        entry.NameLabel.Position = UDim2.fromOffset(rootPos.X - 80, boxY - 14)
        entry.NameLabel.Size = UDim2.fromOffset(160, 12)
        entry.NameLabel.Visible = true
    else
        entry.NameLabel.Visible = false
    end

    -- 4. Info Label (Distance & Tool)
    local infoParts = {}
    if ESP.Distance then
        local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local dist = myHRP and math.floor((hrp.Position - myHRP.Position).Magnitude) or 0
        table.insert(infoParts, tostring(dist) .. "m")
    end
    if ESP.Tool then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            table.insert(infoParts, tool.Name)
        end
    end
    if #infoParts > 0 then
        entry.InfoLabel.Text = table.concat(infoParts, " • ")
        entry.InfoLabel.Position = UDim2.fromOffset(rootPos.X - 80, boxY + boxHeight + 2)
        entry.InfoLabel.Size = UDim2.fromOffset(160, 10)
        entry.InfoLabel.Visible = true
    else
        entry.InfoLabel.Visible = false
    end

    -- 5. Multi-Tracers (All Players)
    if ESP.TracersAll then
        local vp = cam.ViewportSize
        drawTracerLine(entry.TracerLine, vp.X * 0.5, vp.Y, rootPos.X, boxY + boxHeight, ESP.TracerColor)
    else
        entry.TracerLine.Visible = false
    end

    -- 6. Chams / Highlight
    if ESP.Chams then
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

function ESP.isAnyActive()
    return ESP.Boxes or ESP.Names or ESP.Health or ESP.Distance or ESP.Tool or ESP.Chams or ESP.TracersAll
end

function ESP.renderStep()
    if not ESP.isAnyActive() then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local entry = ESP.Cache[p] or createPlayerEntry(p)
            updatePlayerESP(entry)
        end
    end
end

function ESP.updateState()
    local shouldRun = ESP.isAnyActive()
    if shouldRun and not ESP.RenderConnection then
        ESP.RenderConnection = RunService.RenderStepped:Connect(ESP.renderStep)
    elseif not shouldRun and ESP.RenderConnection then
        pcall(function() ESP.RenderConnection:Disconnect() end)
        ESP.RenderConnection = nil
        for _, entry in pairs(ESP.Cache) do
            if entry.BoxOutline then entry.BoxOutline.Visible = false end
            if entry.HealthBarBg then entry.HealthBarBg.Visible = false end
            if entry.NameLabel then entry.NameLabel.Visible = false end
            if entry.InfoLabel then entry.InfoLabel.Visible = false end
            if entry.TracerLine then entry.TracerLine.Visible = false end
            if entry.Highlight then entry.Highlight.Enabled = false end
        end
    end
end

function ESP.setBoxes(state)
    ESP.Boxes = (state == true)
    ESP.updateState()
end

function ESP.setNames(state)
    ESP.Names = (state == true)
    ESP.updateState()
end

function ESP.setHealth(state)
    ESP.Health = (state == true)
    ESP.updateState()
end

function ESP.setDistance(state)
    ESP.Distance = (state == true)
    ESP.updateState()
end

function ESP.setTool(state)
    ESP.Tool = (state == true)
    ESP.updateState()
end

function ESP.setChams(state)
    ESP.Chams = (state == true)
    ESP.updateState()
end

function ESP.setTracers(state)
    ESP.TracersAll = (state == true)
    ESP.updateState()
end

function ESP.setTracerColor(color)
    if typeof(color) == "Color3" then
        ESP.TracerColor = color
    end
end

ESP.PlayerAddedConn = Players.PlayerAdded:Connect(function(p)
    if ESP.isAnyActive() then createPlayerEntry(p) end
end)

ESP.PlayerRemovingConn = Players.PlayerRemoving:Connect(removePlayerEntry)

function ESP.destroy()
    ESP.Boxes = false
    ESP.Names = false
    ESP.Health = false
    ESP.Distance = false
    ESP.Tool = false
    ESP.Chams = false
    ESP.TracersAll = false
    ESP.updateState()
    for p, _ in pairs(ESP.Cache) do
        removePlayerEntry(p)
    end
    ESP.Cache = {}
    if ESP.PlayerAddedConn then
        pcall(function() ESP.PlayerAddedConn:Disconnect() end)
        ESP.PlayerAddedConn = nil
    end
    if ESP.PlayerRemovingConn then
        pcall(function() ESP.PlayerRemovingConn:Disconnect() end)
        ESP.PlayerRemovingConn = nil
    end
    if OverlayGui then
        pcall(function() OverlayGui:Destroy() end)
        OverlayGui = nil
    end
end

function ESP.getDiagnostics()
    local cacheCount = 0
    for _ in pairs(ESP.Cache) do cacheCount = cacheCount + 1 end
    return {
        Name = "ESP",
        Active = ESP.isAnyActive(),
        Connections = (ESP.RenderConnection and 1 or 0) + (ESP.PlayerAddedConn and 1 or 0) + (ESP.PlayerRemovingConn and 1 or 0),
        Threads = 0,
        TrackedPlayers = cacheCount,
    }
end

return ESP
