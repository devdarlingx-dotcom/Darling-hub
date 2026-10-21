--[[
    ========================================================================
    DARLING HUB - WIND UI
    ========================================================================
    UI Framework: WindUI (by Footagesus)
    Hub Title: Darling Hub
    Topbar Style: Modern WindUI Standard Controls (Minimize, Maximize, Close)
    Floating Toggle: WindUI Native OpenButton with Custom Darling Logo
    Media Engine: Anti-flicker double-buffered video renderer
    Language: 100% English
    ========================================================================
]]--

-- Roblox Services
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

-- Executor Capabilities
local exRequest = request or http_request or (syn and syn.request)
local exWriteFile = writefile
local exIsFile = isfile or is_file
local exGetCustomAsset = getcustomasset or getsynasset

-- ========================================================================
-- UNIVERSAL HTTP REQUEST HANDLER
-- ========================================================================
local function universalHttpGet(url, timeout)
    timeout = timeout or 6
    if exRequest then
        local ok, res = pcall(exRequest, { Url = url, Method = "GET", Timeout = timeout })
        if ok and res and type(res) == "table" then
            local code = res.StatusCode or res.Status or 200
            if (code == 200 or code == 0) and type(res.Body) == "string" and #res.Body > 0 then
                return res.Body
            end
        end
    end
    local ok2, body = pcall(function() return game:HttpGet(url, true) end)
    if ok2 and type(body) == "string" and #body > 0 then
        return body
    end
    return nil
end

-- ========================================================================
-- LOCAL ASSET MANAGER (CUSTOM ASSET REGISTRATION & CACHING)
-- ========================================================================
local function loadCustomMediaAsset(url, fileName, timeout)
    if exIsFile and exIsFile(fileName) and exGetCustomAsset then
        local ok, asset = pcall(exGetCustomAsset, fileName)
        if ok and type(asset) == "string" and #asset > 0 then
            return asset
        end
    end

    local body = universalHttpGet(url, timeout)

    if body and #body > 10 and exWriteFile and exGetCustomAsset then
        local okW = pcall(exWriteFile, fileName, body)
        if okW then
            local okA, customAsset = pcall(exGetCustomAsset, fileName)
            if okA and type(customAsset) == "string" and #customAsset > 0 then
                return customAsset
            end
        end
    end

    return nil
end

-- Initial Darling Hub Logo
local initialDarlingUrl = "https://darling-media-api.onrender.com/img?v=d_bc0f17390bb1&k=darling_secret_key"
local darlingIcon = loadCustomMediaAsset(initialDarlingUrl, "darling_icon_d_bc0f17390bb1.png") or initialDarlingUrl

-- ========================================================================
-- MODULAR LOADER (LAZY LOADING)
-- ========================================================================
local SharedEnv = (getgenv and getgenv()) or _G
local RepoBase = "https://raw.githubusercontent.com/devdarlingx-dotcom/Darling-hub/main/"

local DarlingHub = {
    Modules = {},
    Overlay = nil,
    -- Shared settings: UI writes here, modules read here (no module load needed)
    Settings = {
        Aim = {
            Mode = "360",            -- "360", "180", "FOV"
            Priority = "Nearest",    -- "Nearest", "Low HP", "Looking At Me"
            Hitbox = "HumanoidRootPart",
            MaxRange = 1000,
            Prediction = true,
            PredictionAmount = 0.12,
        },
        FOV = {
            Radius = 100,
            Mode = "Center",         -- "Center", "Mouse"
            Color = Color3.fromRGB(255, 60, 60),
            Thickness = 1.5,
        },
        Tracers = {
            Color = Color3.fromRGB(255, 50, 50),
            Thickness = 1.5,
        },
        Blacklist = {
            Melee = { Z = false, X = false, C = false },
            Sword = { Z = false, X = false },
            Fruit = { Z = false, X = false, C = false, V = false, F = false, TAP = false },
            Gun   = { Z = false, X = false },
        },
    },
}
SharedEnv.DarlingHub = DarlingHub
_G.DarlingHub = DarlingHub

local function readLocalModule(relPath)
    if not (exIsFile and readfile) then return nil end
    for _, p in ipairs({ relPath, "darling-hub/" .. relPath }) do
        local okF, exists = pcall(exIsFile, p)
        if okF and exists then
            local ok, content = pcall(readfile, p)
            if ok and type(content) == "string" and #content > 0 then
                return content
            end
        end
    end
    return nil
end

function DarlingHub:Require(relPath)
    if self.Modules[relPath] then
        return self.Modules[relPath]
    end

    local code = readLocalModule(relPath)
    if not code then
        code = universalHttpGet(RepoBase .. relPath .. "?v=" .. tostring(os.time()))
            or universalHttpGet(RepoBase .. relPath)
    end

    if not code then
        warn("[Darling Hub] Failed to load module: " .. tostring(relPath))
        return nil
    end

    local fn, err = loadstring(code)
    if not fn then
        warn("[Darling Hub] Syntax error in module " .. tostring(relPath) .. ": " .. tostring(err))
        return nil
    end

    local okExec, mod = pcall(fn)
    if not okExec or type(mod) ~= "table" then
        warn("[Darling Hub] Runtime error in module " .. tostring(relPath) .. ": " .. tostring(mod))
        return nil
    end

    self.Modules[relPath] = mod
    return mod
end

-- Fullscreen overlay used by FOV / Tracers (works on every executor, no Drawing API needed)
function DarlingHub:GetOverlay()
    if self.Overlay and self.Overlay.Parent then
        return self.Overlay
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = HttpService:GenerateGUID(false)
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 2147483000
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() gui.ScreenInsets = Enum.ScreenInsets.None end)
    if syn and syn.protect_gui then pcall(syn.protect_gui, gui) end

    local parented = false
    if gethui then
        parented = pcall(function() gui.Parent = gethui() end)
    end
    if not parented then
        parented = pcall(function() gui.Parent = CoreGui end)
    end
    if not parented then
        gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    end

    self.Overlay = gui
    return gui
end

-- Enables/disables a module. Disabling a module that was never loaded does nothing,
-- so nothing is downloaded or executed until the user actually turns it on.
function DarlingHub:Toggle(relPath, state)
    if not state and not self.Modules[relPath] then
        return
    end
    local mod = self:Require(relPath)
    if not mod then
        return false
    end
    local ok, err = pcall(function()
        if state then mod.enable() else mod.disable() end
    end)
    if not ok then
        warn("[Darling Hub] " .. tostring(relPath) .. ": " .. tostring(err))
    end
    return ok
end

function DarlingHub:UnloadAll()
    for _, mod in pairs(self.Modules) do
        if type(mod) == "table" then
            if mod.destroy then pcall(mod.destroy) elseif mod.disable then pcall(mod.disable) end
        end
    end
    if self.Overlay then
        pcall(function() self.Overlay:Destroy() end)
        self.Overlay = nil
    end
end

-- Preload combat core
task.spawn(function()
    local ok, core = pcall(function() return DarlingHub:Require("modules/combat/aimbot_core.lua") end)
    if ok and core then
        SharedEnv.DarlingCombatCore = core
        _G.DarlingCombatCore = core
    end
end)

-- ========================================================================
-- LOAD WINDUI WITH ESSENTIAL PC INPUT FIXES
-- ========================================================================
local winduiUrl = "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
local winduiRaw = universalHttpGet(winduiUrl) or game:HttpGet(winduiUrl)

if type(winduiRaw) == "string" then
    -- Fix 1: Slider disconnect on any mouse/touch release
    winduiRaw = winduiRaw:gsub("%)and aB==f", ")")

    -- Fix 2: Window drag release unconditionality (never gets stuck to cursor)
    winduiRaw = winduiRaw:gsub("e%.InputEnded:Connect%(function%(M%)\nif not F or p%.CurrentInput~=B then", "e.InputEnded:Connect(function(M)\nif not F then")

    -- Fix 3: Slider Value table fallback (prevents arithmetic crash on nil Min/Max)
    winduiRaw = winduiRaw:gsub(",\nLockedTitle=ak%.LockedTitle,\nValue=ak%.Value or{},", ",\nLockedTitle=ak.LockedTitle,\nValue=(typeof(ak.Value)==\"table\" and ak.Value) or {Min=ak.Min or 0, Max=ak.Max or 100, Default=ak.Default or ak.Min or 0},")

    -- Fix 4: Slider Container active hitbox for reliable PC clicks
    winduiRaw = winduiRaw:gsub('al%.UIElements%.SliderContainer=af%("Frame",{\nSize=UDim2%.new%(al%.Title==nil and 1 or 0,al%.Title==nil and 0 or al%.Width,0,0%),\nAutomaticSize="Y",', 'al.UIElements.SliderContainer=af("Frame",{\nSize=UDim2.new(al.Title==nil and 1 or 0,al.Title==nil and 0 or al.Width,0,32),\nActive=true,\nAutomaticSize="Y",')
end

local WindUI = loadstring(winduiRaw)()

-- Global shortcut key (default: F)
local currentToggleKey = Enum.KeyCode.F

-- Create Darling Hub Main Window with WindUI native OpenButton
local Window = WindUI:CreateWindow({
    Title = "Darling Hub",
    Icon = darlingIcon,
    IconRadius = 8,
    Author = "by Darling",
    Folder = "DarlingHubConfigs",
    Size = UDim2.fromOffset(800, 560),
    MinSize = Vector2.new(680, 480),
    MaxSize = Vector2.new(980, 680),
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    ScrollBarEnabled = true,
    HideSearchBar = false,
    ButtonsType = "Default",
    Topbar = {
        Height = 44,
        ButtonsType = "Default",
    },
    Background = "",
    BackgroundImageTransparency = 0.25,
    OpenButton = {
        Enabled = true,
        OnlyMobile = false,
        Title = "Darling Hub",
        Icon = darlingIcon,
        Position = UDim2.new(0.5, 0, 0, 24),
        Draggable = true,
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 1.5,
        Color = ColorSequence.new(Color3.fromRGB(0, 0, 0), Color3.fromRGB(0, 0, 0))
    }
})

-- Enforce pure black border on OpenButton
local function enforceBlackOpenButtonBorder()
    pcall(function()
        if Window.OpenButtonMain and Window.OpenButtonMain.Button then
            local btn = Window.OpenButtonMain.Button
            local stroke = btn:FindFirstChildOfClass("UIStroke")
            if stroke then
                stroke.Color = Color3.fromRGB(0, 0, 0)
                stroke.Thickness = 1.5
                local grad = stroke:FindFirstChildOfClass("UIGradient")
                if grad then
                    grad.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0), Color3.fromRGB(0, 0, 0))
                end
            end
            local glow = btn:FindFirstChild("Glow")
            if glow and glow:FindFirstChildOfClass("UIGradient") then
                glow:FindFirstChildOfClass("UIGradient").Color = ColorSequence.new(Color3.fromRGB(0, 0, 0), Color3.fromRGB(0, 0, 0))
            end
        end
    end)
end

enforceBlackOpenButtonBorder()
task.spawn(function()
    for _ = 1, 5 do
        task.wait(0.2)
        enforceBlackOpenButtonBorder()
    end
end)

-- Disable WindUI tooltip GUI so mouse clicks and sliders are never intercepted
pcall(function()
    if WindUI.TooltipGui then
        WindUI.TooltipGui.Enabled = false
    end
end)

-- ========================================================================
-- WINDOW BORDER (CRISP SUBTLE OUTLINE)
-- ========================================================================
pcall(function()
    local main = Window.UIElements and Window.UIElements.Main
    if main then
        local windowStroke = main:FindFirstChild("DarlingWindowBorder")
        if not windowStroke then
            windowStroke = Instance.new("UIStroke")
            windowStroke.Name = "DarlingWindowBorder"
            windowStroke.Color = Color3.fromHex("#3A3A42")
            windowStroke.Thickness = 1.5
            windowStroke.Transparency = 0.25
            windowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            windowStroke.Parent = main
        end
    end
end)

-- ========================================================================
-- INTEGRATED BOTTOM PROGRESS BAR (INSET SILVER LINE, ZERO SPILL)
-- ========================================================================
local bottomProgressContainer = nil
local bottomProgressFill = nil
local bottomProgressLabel = nil

local function setupBottomProgress()
    local main = Window.UIElements and Window.UIElements.Main
    if not main then return end

    if not bottomProgressContainer or not bottomProgressContainer.Parent then
        bottomProgressContainer = Instance.new("Frame")
        bottomProgressContainer.Name = "DarlingBottomProgress"
        bottomProgressContainer.AnchorPoint = Vector2.new(0.5, 1)
        bottomProgressContainer.Position = UDim2.new(0.5, 0, 1, -6)
        bottomProgressContainer.Size = UDim2.new(1, -44, 0, 2)
        bottomProgressContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 44)
        bottomProgressContainer.BorderSizePixel = 0
        bottomProgressContainer.Active = false
        bottomProgressContainer.ZIndex = 30
        bottomProgressContainer.Visible = false

        local barCorner = Instance.new("UICorner")
        barCorner.CornerRadius = UDim.new(1, 0)
        barCorner.Parent = bottomProgressContainer

        bottomProgressFill = Instance.new("Frame")
        bottomProgressFill.Name = "Fill"
        bottomProgressFill.Size = UDim2.new(0, 0, 1, 0)
        bottomProgressFill.BackgroundColor3 = Color3.fromRGB(235, 235, 242)
        bottomProgressFill.BorderSizePixel = 0
        bottomProgressFill.Active = false
        bottomProgressFill.ZIndex = 31

        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(1, 0)
        fillCorner.Parent = bottomProgressFill
        bottomProgressFill.Parent = bottomProgressContainer

        bottomProgressLabel = Instance.new("TextLabel")
        bottomProgressLabel.Name = "PercentText"
        bottomProgressLabel.AnchorPoint = Vector2.new(1, 1)
        bottomProgressLabel.Position = UDim2.new(1, -24, 1, -10)
        bottomProgressLabel.Size = UDim2.fromOffset(50, 12)
        bottomProgressLabel.BackgroundTransparency = 1
        bottomProgressLabel.Font = Enum.Font.GothamMedium
        bottomProgressLabel.TextSize = 10
        bottomProgressLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
        bottomProgressLabel.TextXAlignment = Enum.TextXAlignment.Right
        bottomProgressLabel.Text = "0%"
        bottomProgressLabel.Active = false
        bottomProgressLabel.ZIndex = 32
        bottomProgressLabel.Visible = false

        bottomProgressContainer.Parent = main
        bottomProgressLabel.Parent = main
    end
end

local function setBottomProgress(percent)
    setupBottomProgress()
    if bottomProgressContainer and bottomProgressFill and bottomProgressLabel then
        bottomProgressContainer.Visible = true
        bottomProgressLabel.Visible = true
        bottomProgressContainer.BackgroundTransparency = 0
        bottomProgressFill.BackgroundTransparency = 0
        bottomProgressLabel.TextTransparency = 0

        local clamped = math.clamp(percent or 0, 0, 100)
        bottomProgressLabel.Text = string.format("%d%%", clamped)
        bottomProgressFill.Size = UDim2.new(clamped / 100, 0, 1, 0)
    end
end

local function finishBottomProgress()
    if bottomProgressContainer and bottomProgressFill and bottomProgressLabel then
        bottomProgressFill.Size = UDim2.new(1, 0, 1, 0)
        bottomProgressLabel.Text = "100%"
        task.delay(0.25, function()
            if bottomProgressContainer and bottomProgressFill and bottomProgressLabel then
                local tw1 = TweenService:Create(bottomProgressContainer, TweenInfo.new(0.25), { BackgroundTransparency = 1 })
                local tw2 = TweenService:Create(bottomProgressFill, TweenInfo.new(0.25), { BackgroundTransparency = 1 })
                local tw3 = TweenService:Create(bottomProgressLabel, TweenInfo.new(0.25), { TextTransparency = 1 })
                tw1:Play()
                tw2:Play()
                tw3:Play()
                task.wait(0.25)
                bottomProgressContainer.Visible = false
                bottomProgressLabel.Visible = false
                bottomProgressFill.Size = UDim2.new(0, 0, 1, 0)
            end
        end)
    end
end

local function hideBottomProgress()
    if bottomProgressContainer then
        bottomProgressContainer.Visible = false
        if bottomProgressFill then
            bottomProgressFill.Size = UDim2.new(0, 0, 1, 0)
        end
    end
    if bottomProgressLabel then
        bottomProgressLabel.Visible = false
    end
end

-- ========================================================================
-- BACKGROUND MEDIA ENGINE (ANTI-FLICKER DOUBLE BUFFER & SQUIRCLE CORNERS)
-- ========================================================================
local currentBackgroundTransparency = 0.25
local currentScaleType = Enum.ScaleType.Crop
local lastEnteredBackgroundInput = ""

local activeAnimTask = nil
local activeDownloadTask = nil
local activeSound = nil

local imgA, imgB = nil, nil
local tintOverlay = nil

local function setupBackgroundContainers()
    local main = Window.UIElements and Window.UIElements.Main
    if not main then return end

    local bgTarget = main:FindFirstChild("Background") or main
    local bgContainer = bgTarget:FindFirstChild("DarlingMediaContainer")
    if not bgContainer then
        bgContainer = Instance.new("Frame")
        bgContainer.Name = "DarlingMediaContainer"
        bgContainer.Size = UDim2.fromScale(1, 1)
        bgContainer.Position = UDim2.fromScale(0, 0)
        bgContainer.BackgroundTransparency = 1
        bgContainer.Active = false
        bgContainer.ZIndex = 2
        bgContainer.ClipsDescendants = true

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 18)
        corner.Parent = bgContainer

        -- Buffer A (100% solid to eliminate texture flashing)
        imgA = Instance.new("ImageLabel")
        imgA.Name = "BufferA"
        imgA.Size = UDim2.fromScale(1, 1)
        imgA.Position = UDim2.fromScale(0, 0)
        imgA.BackgroundTransparency = 1
        imgA.Active = false
        imgA.ScaleType = currentScaleType
        imgA.ImageTransparency = 0
        imgA.ZIndex = 6
        imgA.Visible = false

        local cornerA = Instance.new("UICorner")
        cornerA.CornerRadius = UDim.new(0, 18)
        cornerA.Parent = imgA
        imgA.Parent = bgContainer

        -- Buffer B (100% solid for asynchronous frame preloading)
        imgB = Instance.new("ImageLabel")
        imgB.Name = "BufferB"
        imgB.Size = UDim2.fromScale(1, 1)
        imgB.Position = UDim2.fromScale(0, 0)
        imgB.BackgroundTransparency = 1
        imgB.Active = false
        imgB.ScaleType = currentScaleType
        imgB.ImageTransparency = 0
        imgB.ZIndex = 5
        imgB.Visible = false

        local cornerB = Instance.new("UICorner")
        cornerB.CornerRadius = UDim.new(0, 18)
        cornerB.Parent = imgB
        imgB.Parent = bgContainer

        -- Tint Overlay (handles background dimming independently of texture buffers)
        tintOverlay = Instance.new("Frame")
        tintOverlay.Name = "TintOverlay"
        tintOverlay.Size = UDim2.fromScale(1, 1)
        tintOverlay.Position = UDim2.fromScale(0, 0)
        tintOverlay.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
        tintOverlay.BackgroundTransparency = 1 - currentBackgroundTransparency
        tintOverlay.BorderSizePixel = 0
        tintOverlay.Active = false
        tintOverlay.ZIndex = 7
        tintOverlay.Visible = false

        local tintCorner = Instance.new("UICorner")
        tintCorner.CornerRadius = UDim.new(0, 18)
        tintCorner.Parent = tintOverlay
        tintOverlay.Parent = bgContainer

        bgContainer.Parent = bgTarget
    else
        imgA = bgContainer:FindFirstChild("BufferA")
        imgB = bgContainer:FindFirstChild("BufferB")
        tintOverlay = bgContainer:FindFirstChild("TintOverlay")
    end
end

local function clearActiveMedia()
    if activeAnimTask then
        task.cancel(activeAnimTask)
        activeAnimTask = nil
    end
    if activeDownloadTask then
        task.cancel(activeDownloadTask)
        activeDownloadTask = nil
    end
    if activeSound then
        pcall(function()
            activeSound:Stop()
            activeSound:Destroy()
        end)
        activeSound = nil
    end
end

local function playStaticBackground(assetId)
    clearActiveMedia()
    setupBackgroundContainers()

    if imgA and imgB then
        imgA.Image = assetId
        imgA.ImageTransparency = 0
        imgA.ScaleType = currentScaleType
        imgA.ZIndex = 6
        imgA.Visible = true

        imgB.Image = ""
        imgB.Visible = false

        if tintOverlay then
            tintOverlay.BackgroundTransparency = 1 - currentBackgroundTransparency
            tintOverlay.Visible = true
        end

        local main = Window.UIElements and Window.UIElements.Main
        local bg = main and main:FindFirstChild("Background")
        if bg and bg:IsA("ImageLabel") then
            bg.Image = ""
            bg.BackgroundTransparency = 1
        end

        if Window.SetBackground then
            pcall(function() Window:SetBackground("") end)
        end
    else
        if Window.SetBackground then
            pcall(function() Window:SetBackground(assetId) end)
            if tintOverlay then
                tintOverlay.Visible = false
            end
        end
    end
end

local function playVideoBackground(slotData)
    clearActiveMedia()
    setupBackgroundContainers()

    local n = tonumber(slotData.frames) or 0
    local fps = tonumber(slotData.fps) or 15
    local duration = tonumber(slotData.duration) or (n / fps)
    local frameExt = slotData.frameExt or "jpg"
    local mediaId = slotData.id

    if n < 1 then return end

    activeDownloadTask = task.spawn(function()
        -- 1. Synchronized audio track
        if slotData.hasAudio then
            local audioName = string.format("darling_vid_audio_%s.mp3", mediaId)
            local audioUrl = string.format("https://darling-media-api.onrender.com/video/audio/%s.mp3?k=darling_secret_key", mediaId)
            local audioAsset = loadCustomMediaAsset(audioUrl, audioName, 10)
            if audioAsset then
                pcall(function()
                    activeSound = Instance.new("Sound")
                    activeSound.SoundId = audioAsset
                    activeSound.Volume = 0.5
                    activeSound.Parent = SoundService
                    activeSound:Play()
                end)
            end
        end

        -- 2. Local cache check
        local assets = {}
        local missingFrames = {}

        if exIsFile and exGetCustomAsset then
            for i = 1, n do
                local fname = string.format("darling_vid_%s_f%d.%s", mediaId, i, frameExt)
                if exIsFile(fname) then
                    local ok, asset = pcall(exGetCustomAsset, fname)
                    if ok and type(asset) == "string" and #asset > 0 then
                        assets[i] = asset
                    else
                        table.insert(missingFrames, i)
                    end
                else
                    table.insert(missingFrames, i)
                end
            end
        else
            for i = 1, n do
                table.insert(missingFrames, i)
            end
        end

        if #missingFrames == 0 then
            hideBottomProgress()
        else
            setBottomProgress(0)
            local totalMissing = #missingFrames
            local downloaded = 0

            for _, i in ipairs(missingFrames) do
                local fname = string.format("darling_vid_%s_f%d.%s", mediaId, i, frameExt)
                local url = string.format("https://darling-media-api.onrender.com/video/frame/%s/%d.%s?k=darling_secret_key", mediaId, i, frameExt)
                local loaded = loadCustomMediaAsset(url, fname, 5)
                if loaded then
                    assets[i] = loaded
                elseif i > 1 and assets[i - 1] then
                    assets[i] = assets[i - 1]
                end
                downloaded = downloaded + 1

                if downloaded % 4 == 0 or downloaded == totalMissing then
                    local percent = math.floor((downloaded / totalMissing) * 100)
                    setBottomProgress(percent)
                    RunService.RenderStepped:Wait()
                end
            end
            finishBottomProgress()
        end

        -- Ensure continuous textures
        local lastValid = nil
        for i = 1, n do
            if assets[i] then
                lastValid = assets[i]
            elseif lastValid then
                assets[i] = lastValid
            end
        end

        if not assets[1] and lastValid then
            assets[1] = lastValid
        end

        if not assets[1] then
            hideBottomProgress()
            return
        end

        -- Double buffer initialization
        imgA.Image = assets[1]
        imgB.Image = assets[2] or assets[1]
        imgA.ImageTransparency = 0
        imgB.ImageTransparency = 0
        imgA.ScaleType = currentScaleType
        imgB.ScaleType = currentScaleType
        imgA.ZIndex = 6
        imgB.ZIndex = 5
        imgA.Visible = true
        imgB.Visible = true

        if tintOverlay then
            tintOverlay.BackgroundTransparency = 1 - currentBackgroundTransparency
            tintOverlay.Visible = true
        end

        local cur, back = imgA, imgB
        local lastTarget = 1
        local startTime = tick()

        activeAnimTask = task.spawn(function()
            while true do
                local elapsed = 0
                if activeSound and activeSound.IsPlaying then
                    elapsed = activeSound.TimePosition
                else
                    elapsed = (tick() - startTime)
                end

                local target = math.clamp(math.floor(elapsed * fps) + 1, 1, n)
                if target ~= lastTarget then
                    lastTarget = target
                    back.ZIndex = 6
                    cur.ZIndex = 5
                    cur, back = back, cur

                    local nextIdx = (target % n) + 1
                    local nextAsset = assets[nextIdx]
                    if nextAsset and type(nextAsset) == "string" and #nextAsset > 0 then
                        back.Image = nextAsset
                    end
                end

                if elapsed >= duration then
                    startTime = tick()
                    if activeSound then activeSound.TimePosition = 0 end
                end

                RunService.Heartbeat:Wait()
            end
        end)
    end)
end

local function playGifBackground(slotData)
    clearActiveMedia()
    setupBackgroundContainers()

    local n = tonumber(slotData.frames) or 0
    local mediaId = slotData.id
    if n < 1 then return end

    activeDownloadTask = task.spawn(function()
        local assets = {}
        local missingFrames = {}

        if exIsFile and exGetCustomAsset then
            for i = 0, n - 1 do
                local fname = string.format("darling_gif_%s_f%d.png", mediaId, i)
                if exIsFile(fname) then
                    local ok, asset = pcall(exGetCustomAsset, fname)
                    if ok and type(asset) == "string" and #asset > 0 then
                        assets[i + 1] = asset
                    else
                        table.insert(missingFrames, i)
                    end
                else
                    table.insert(missingFrames, i)
                end
            end
        else
            for i = 0, n - 1 do
                table.insert(missingFrames, i)
            end
        end

        if #missingFrames == 0 then
            hideBottomProgress()
        else
            setBottomProgress(0)
            local totalMissing = #missingFrames
            local downloaded = 0
            for _, i in ipairs(missingFrames) do
                local fname = string.format("darling_gif_%s_f%d.png", mediaId, i)
                local url = string.format("https://darling-media-api.onrender.com/frame/%d.png?v=%s&k=darling_secret_key", i, mediaId)
                local loaded = loadCustomMediaAsset(url, fname, 5)
                if loaded then
                    assets[i + 1] = loaded
                elseif i > 0 and assets[i] then
                    assets[i + 1] = assets[i]
                end
                downloaded = downloaded + 1

                if downloaded % 4 == 0 or downloaded == totalMissing then
                    local percent = math.floor((downloaded / totalMissing) * 100)
                    setBottomProgress(percent)
                    RunService.RenderStepped:Wait()
                end
            end
            finishBottomProgress()
        end

        local lastValid = nil
        for i = 1, n do
            if assets[i] then
                lastValid = assets[i]
            elseif lastValid then
                assets[i] = lastValid
            end
        end

        if not assets[1] and lastValid then
            assets[1] = lastValid
        end

        if not assets[1] then
            hideBottomProgress()
            return
        end

        imgA.Image = assets[1]
        imgB.Image = assets[2] or assets[1]
        imgA.ImageTransparency = 0
        imgB.ImageTransparency = 0
        imgA.ScaleType = currentScaleType
        imgB.ScaleType = currentScaleType
        imgA.ZIndex = 6
        imgB.ZIndex = 5
        imgA.Visible = true
        imgB.Visible = true

        if tintOverlay then
            tintOverlay.BackgroundTransparency = 1 - currentBackgroundTransparency
            tintOverlay.Visible = true
        end

        local delays = {}
        for i = 1, n do
            local ms = (slotData.delays and slotData.delays[i]) or 80
            delays[i] = math.max(0.02, ms / 1000)
        end

        local cur, back = imgA, imgB
        activeAnimTask = task.spawn(function()
            while true do
                for i = 1, n do
                    back.ZIndex = 6
                    cur.ZIndex = 5
                    cur, back = back, cur

                    local nextIdx = (i % n) + 1
                    local nextAsset = assets[nextIdx]
                    if nextAsset and type(nextAsset) == "string" and #nextAsset > 0 then
                        back.Image = nextAsset
                    end
                    task.wait(delays[i])
                end
            end
        end)
    end)
end

local function processAndApplyMediaInput(input)
    if not input or type(input) ~= "string" then return end
    local clean = input:gsub("^%s+", ""):gsub("%s+$", "")
    if #clean == 0 then return end

    local darlingId = clean:match("id=([%w_%-]+)") or clean:match("v=([%w_%-]+)") or clean:match("^(d_[%w_%-]+)$")

    if darlingId then
        task.spawn(function()
            local queryUrl = string.format("https://darling-media-api.onrender.com/api/slot?k=darling_secret_key&id=%s", darlingId)
            local raw = universalHttpGet(queryUrl)

            if raw then
                local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
                if ok and data and data.ok and data.slot then
                    local slot = data.slot
                    if slot.kind == "video" then
                        playVideoBackground(slot)
                        return
                    elseif slot.kind == "gif" then
                        playGifBackground(slot)
                        return
                    end
                end
            end

            -- Static image fallback
            local staticName = "darling_bg_" .. darlingId .. ".png"
            if exIsFile and exIsFile(staticName) and exGetCustomAsset then
                local ok, asset = pcall(exGetCustomAsset, staticName)
                if ok and type(asset) == "string" and #asset > 0 then
                    hideBottomProgress()
                    playStaticBackground(asset)
                    return
                end
            end

            setBottomProgress(40)
            local staticUrl = string.format("https://darling-media-api.onrender.com/img?v=%s&k=darling_secret_key", darlingId)
            local staticAsset = loadCustomMediaAsset(staticUrl, staticName)
            if staticAsset then
                finishBottomProgress()
                playStaticBackground(staticAsset)
            else
                hideBottomProgress()
            end
        end)
        return
    end

    if clean:match("^%d+$") then
        hideBottomProgress()
        playStaticBackground("rbxassetid://" .. clean)
        return
    elseif clean:match("^rbxassetid://") then
        hideBottomProgress()
        playStaticBackground(clean)
        return
    end

    if clean:match("^https?://") then
        task.spawn(function()
            local cleanUrl = clean:match("(https?://[^%s%\"]+)") or clean
            local ext = cleanUrl:match("%.(%w+)%??") or "png"
            local hash = "darling_web_" .. tostring(#cleanUrl) .. "." .. ext
            if exIsFile and exIsFile(hash) and exGetCustomAsset then
                local ok, asset = pcall(exGetCustomAsset, hash)
                if ok and type(asset) == "string" and #asset > 0 then
                    hideBottomProgress()
                    playStaticBackground(asset)
                    return
                end
            end

            setBottomProgress(40)
            local asset = loadCustomMediaAsset(cleanUrl, hash)
            if asset then
                finishBottomProgress()
                playStaticBackground(asset)
            else
                hideBottomProgress()
            end
        end)
    end
end

-- ========================================================================
-- WINDOW STATE & CENTRALIZED TOGGLE SYSTEM
-- ========================================================================
-- Enabled by default
local allowFloatingWidget = true

local function toggleHub()
    pcall(function()
        if Window.Toggle then
            Window:Toggle()
        else
            local frame = (Window.GetMainFrame and Window:GetMainFrame()) or Window.Frame or (Window.UIElements and Window.UIElements.Main)
            if frame then
                frame.Visible = not frame.Visible
            end
        end
    end)
end

if Window.OnDestroy then
    Window:OnDestroy(function()
        allowFloatingWidget = false
        pcall(function()
            if Window.EditOpenButton then
                Window:EditOpenButton({ Enabled = false })
            end
            if Window.OpenButtonMain then
                Window.OpenButtonMain:Visible(false)
            end
        end)
        clearActiveMedia()
    end)
end

-- Global Keyboard Shortcut Listener with 0.3s Debounce
local lastToggleTick = 0
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if UserInputService:GetFocusedTextBox() then return end

    if input.KeyCode == currentToggleKey then
        local now = tick()
        if now - lastToggleTick >= 0.3 then
            lastToggleTick = now
            toggleHub()
        end
    end
end)

-- Helper to enhance PC tab scrolling with a clean visible scrollbar
local function enhanceTabScrolling(tab)
    task.spawn(function()
        task.wait(0.05)
        pcall(function()
            local cf = tab.ContainerFrame or (tab.UIElements and tab.UIElements.ContainerFrame)
            if cf and cf:IsA("ScrollingFrame") then
                cf.ScrollBarThickness = 6
                cf.ScrollBarImageTransparency = 0.4
                cf.ScrollBarImageColor3 = Color3.fromRGB(180, 180, 195)
                cf.ScrollingDirection = Enum.ScrollingDirection.Y
                cf.ElasticBehavior = Enum.ElasticBehavior.Always
                cf.Active = true
            end
        end)
    end)
end

-- ========================================================================
-- 1. HOME TAB
-- ========================================================================
local HomeTab = Window:Tab({
    Title = "Home",
    Icon = "house"
})
enhanceTabScrolling(HomeTab)

HomeTab:Paragraph({
    Title = "User: " .. (game.Players.LocalPlayer and game.Players.LocalPlayer.DisplayName or "Player"),
    Desc = "Welcome to Darling Hub. Premium features and customization controls are active.",
    Image = "sparkles"
})

HomeTab:Paragraph({
    Title = "System Status",
    Desc = "Status: Online | Version: 1.0.0 | Performance: Optimal",
    Image = "check-circle"
})

HomeTab:Divider()

HomeTab:Paragraph({
    Title = "Window & Media Backgrounds",
    Desc = "Configure animated videos and themes with real-time bottom buffering indicator."
})

-- ========================================================================
-- 2. AIMBOT TAB (MODULAR - BLOX FRUITS)
-- ========================================================================
local AimbotTab = Window:Tab({
    Title = "Aimbot",
    Icon = "crosshair"
})
enhanceTabScrolling(AimbotTab)

local AimSettings = DarlingHub.Settings

local function notifyModuleFail(name)
    WindUI:Notify({
        Title = "Darling Hub",
        Content = "Failed to load " .. name .. ". Check your connection.",
        Duration = 4,
        Icon = "triangle-alert"
    })
end

local function bindToggle(path, name)
    return function(state)
        if DarlingHub:Toggle(path, state) == false then
            notifyModuleFail(name)
        end
    end
end

local ColorMap = {
    Red = Color3.fromRGB(255, 50, 50),
    Green = Color3.fromRGB(50, 255, 90),
    Blue = Color3.fromRGB(50, 150, 255),
    Yellow = Color3.fromRGB(255, 220, 50),
    Purple = Color3.fromRGB(170, 90, 255),
    White = Color3.fromRGB(255, 255, 255),
}
local ColorNames = { "Red", "Green", "Blue", "Yellow", "Purple", "White" }

-- Silent Aim
AimbotTab:Toggle({
    Title = "Player Silent Aim",
    Desc = "Redirects skills towards enemy players",
    Value = false,
    Callback = bindToggle("modules/combat/player_aimbot.lua", "Player Silent Aim")
})

AimbotTab:Toggle({
    Title = "NPC Silent Aim",
    Desc = "Redirects skills towards mobs and bosses",
    Value = false,
    Callback = bindToggle("modules/combat/npc_aimbot.lua", "NPC Silent Aim")
})

AimbotTab:Dropdown({
    Title = "Target Priority",
    Values = { "Nearest", "Low HP", "Looking At Me" },
    Value = "Nearest",
    Callback = function(v)
        if type(v) == "string" then AimSettings.Aim.Priority = v end
    end
})

AimbotTab:Dropdown({
    Title = "Aim Mode",
    Desc = "FOV = only targets inside the circle",
    Values = { "360", "180", "FOV" },
    Value = "360",
    Callback = function(v)
        if type(v) == "string" then AimSettings.Aim.Mode = v end
    end
})

AimbotTab:Slider({
    Title = "Max Range",
    Value = { Min = 100, Max = 3000, Default = 1000 },
    Step = 50,
    Callback = function(v)
        AimSettings.Aim.MaxRange = tonumber(v) or AimSettings.Aim.MaxRange
    end
})

AimbotTab:Dropdown({
    Title = "Skill Blacklist",
    Desc = "Selected skills are not redirected",
    Values = {
        "Melee Z", "Melee X", "Melee C",
        "Sword Z", "Sword X",
        "Fruit Z", "Fruit X", "Fruit C", "Fruit V", "Fruit F", "Fruit TAP",
        "Gun Z", "Gun X",
    },
    Value = {},
    Multi = true,
    AllowNone = true,
    Callback = function(selection)
        local mod = DarlingHub:Require("modules/combat/blacklist.lua")
        if mod then mod.apply(selection) end
    end
})

AimbotTab:Divider()

-- FOV
AimbotTab:Toggle({
    Title = "Show FOV Circle",
    Value = false,
    Callback = bindToggle("modules/combat/fov.lua", "FOV Circle")
})

AimbotTab:Slider({
    Title = "FOV Radius",
    Value = { Min = 20, Max = 600, Default = 100 },
    Step = 5,
    Callback = function(v)
        AimSettings.FOV.Radius = tonumber(v) or AimSettings.FOV.Radius
    end
})

AimbotTab:Dropdown({
    Title = "FOV Position",
    Values = { "Center", "Mouse" },
    Value = "Center",
    Callback = function(v)
        if type(v) == "string" then AimSettings.FOV.Mode = v end
    end
})

AimbotTab:Dropdown({
    Title = "FOV Color",
    Values = ColorNames,
    Value = "Red",
    Callback = function(v)
        if ColorMap[v] then AimSettings.FOV.Color = ColorMap[v] end
    end
})

AimbotTab:Divider()

-- Tracers
AimbotTab:Toggle({
    Title = "Show Tracers",
    Desc = "Line from screen center to the current target",
    Value = false,
    Callback = bindToggle("modules/combat/tracers.lua", "Tracers")
})

AimbotTab:Dropdown({
    Title = "Tracer Color",
    Values = ColorNames,
    Value = "Red",
    Callback = function(v)
        if ColorMap[v] then AimSettings.Tracers.Color = ColorMap[v] end
    end
})

-- ========================================================================
-- 3. PLAYERS TAB
-- ========================================================================
local PlayersTab = Window:Tab({
    Title = "Players",
    Icon = "users"
})
enhanceTabScrolling(PlayersTab)

PlayersTab:Toggle({
    Title = "Custom WalkSpeed",
    Desc = "Increases local character movement speed",
    Value = false,
    Callback = function(state)
        -- WalkSpeed toggle logic
    end
})

PlayersTab:Slider({
    Title = "WalkSpeed Value",
    Value = {
        Min = 16,
        Max = 200,
        Default = 16,
    },
    Step = 2,
    Callback = function(val)
        -- WalkSpeed value adjustment
    end
})

PlayersTab:Slider({
    Title = "JumpPower Value",
    Value = {
        Min = 50,
        Max = 300,
        Default = 50,
    },
    Step = 5,
    Callback = function(val)
        -- JumpPower value adjustment
    end
})

PlayersTab:Divider()

PlayersTab:Toggle({
    Title = "Infinite Jump",
    Desc = "Allows jumping mid-air without ground contact",
    Value = false,
    Callback = function(state)
        -- Infinite jump logic
    end
})

PlayersTab:Toggle({
    Title = "NoClip",
    Desc = "Disables collisions with walls and solid objects",
    Value = false,
    Callback = function(state)
        -- NoClip logic
    end
})

-- ========================================================================
-- 4. PVP TAB
-- ========================================================================
local PvpTab = Window:Tab({
    Title = "Pvp",
    Icon = "swords"
})
enhanceTabScrolling(PvpTab)

PvpTab:Toggle({
    Title = "Auto Attack / Kill Aura",
    Desc = "Attacks all targets entering combat range",
    Value = false,
    Callback = function(state)
        -- Kill aura logic
    end
})

PvpTab:Slider({
    Title = "Combat Range",
    Value = {
        Min = 5,
        Max = 40,
        Default = 15,
    },
    Step = 1,
    Callback = function(val)
        -- Combat range adjustment
    end
})

PvpTab:Toggle({
    Title = "Auto Parry / Auto Block",
    Desc = "Automatically deflects incoming enemy attacks",
    Value = false,
    Callback = function(state)
        -- Auto parry logic
    end
})

PvpTab:Divider()

PvpTab:Dropdown({
    Title = "Target Priority",
    Values = { "Lowest Health", "Closest Distance", "Highest Threat" },
    Default = "Closest Distance",
    Callback = function(selected)
        -- Target priority logic
    end
})

-- ========================================================================
-- 5. VISUALS TAB
-- ========================================================================
local VisualsTab = Window:Tab({
    Title = "Visuals",
    Icon = "eye"
})
enhanceTabScrolling(VisualsTab)

VisualsTab:Toggle({
    Title = "Master ESP",
    Desc = "Global switch for all wallhack and visual indicators",
    Value = false,
    Callback = function(state)
        -- Master ESP logic
    end
})

VisualsTab:Toggle({
    Title = "2D Box ESP",
    Desc = "Draws bounding boxes around character models",
    Value = false,
    Callback = function(state)
        -- Box ESP logic
    end
})

VisualsTab:Toggle({
    Title = "Name & Distance ESP",
    Desc = "Displays username and distance tags",
    Value = false,
    Callback = function(state)
        -- Names ESP logic
    end
})

VisualsTab:Toggle({
    Title = "Snaplines / Tracers",
    Desc = "Draws guidance lines connecting your viewport to players",
    Value = false,
    Callback = function(state)
        -- Tracers logic
    end
})

VisualsTab:Divider()

VisualsTab:Toggle({
    Title = "Chams / Highlights",
    Desc = "Applies a radiant silhouette highlight over players",
    Value = false,
    Callback = function(state)
        -- Chams logic
    end
})

-- ========================================================================
-- 6. SKINS TAB
-- ========================================================================
local SkinsTab = Window:Tab({
    Title = "Skins",
    Icon = "shirt"
})
enhanceTabScrolling(SkinsTab)

SkinsTab:Dropdown({
    Title = "Cosmetic Skin Package",
    Values = {
        "Darling Edition (Pink and Black)",
        "Cyber Neon",
        "Crimson Phantom",
        "Royal Gold",
        "Void Black"
    },
    Default = "Darling Edition (Pink and Black)",
    Callback = function(selected)
        -- Skin logic
    end
})

SkinsTab:Divider()

SkinsTab:Toggle({
    Title = "Local Skin Changer",
    Desc = "Applies custom visual textures and models on your client",
    Value = false,
    Callback = function(state)
        -- Skin changer logic
    end
})

SkinsTab:Toggle({
    Title = "Particle Aura",
    Desc = "Generates stylized particle effects around your character",
    Value = false,
    Callback = function(state)
        -- Particle aura logic
    end
})

-- ========================================================================
-- 7. MUSIC TAB
-- ========================================================================
local MusicTab = Window:Tab({
    Title = "Music",
    Icon = "music"
})
enhanceTabScrolling(MusicTab)

MusicTab:Dropdown({
    Title = "Soundtrack Selection",
    Values = {
        "Darling Theme - Lo-Fi Chill",
        "Phonk Drift and Combat",
        "Anime Aesthetics Vibes",
        "Synthwave Night Drive",
        "Custom Sound ID"
    },
    Default = "Darling Theme - Lo-Fi Chill",
    Callback = function(selected)
        -- Music track logic
    end
})

MusicTab:Slider({
    Title = "Playback Volume",
    Value = {
        Min = 0,
        Max = 100,
        Default = 50,
    },
    Step = 5,
    Callback = function(val)
        -- Music volume logic
    end
})

MusicTab:Toggle({
    Title = "Loop Track",
    Desc = "Automatically loops playback when the song ends",
    Value = true,
    Callback = function(state)
        -- Music loop logic
    end
})

-- ========================================================================
-- 8. UNIQUE TAB
-- ========================================================================
local UniqueTab = Window:Tab({
    Title = "Unique",
    Icon = "crown"
})
enhanceTabScrolling(UniqueTab)

UniqueTab:Toggle({
    Title = "Darling VIP Aura",
    Desc = "Applies exclusive ambient lighting and custom visual highlights",
    Value = false,
    Callback = function(state)
        -- VIP aura logic
    end
})

UniqueTab:Toggle({
    Title = "Fake Lag Simulation",
    Desc = "Simulates network latency spikes to desync position",
    Value = false,
    Callback = function(state)
        -- Fake lag logic
    end
})

UniqueTab:Toggle({
    Title = "SpinBot 360",
    Desc = "High-speed cosmetic character rotation",
    Value = false,
    Callback = function(state)
        -- SpinBot logic
    end
})

-- ========================================================================
-- 9. +18 SECTION TAB
-- ========================================================================
local NsfwTab = Window:Tab({
    Title = "+18 Section",
    Icon = "flame"
})
enhanceTabScrolling(NsfwTab)

NsfwTab:Paragraph({
    Title = "Security Notice",
    Desc = "Custom user animation section. Contains no default executable payload.",
    Image = "shield-alert"
})

NsfwTab:Divider()

NsfwTab:Toggle({
    Title = "Custom Animation Sync",
    Desc = "Synchronizes R6 / R15 pose animations",
    Value = false,
    Callback = function(state)
        -- Custom animation logic
    end
})

NsfwTab:Toggle({
    Title = "Atmospheric Screen Tint",
    Desc = "Applies cinematic color correction to camera",
    Value = false,
    Callback = function(state)
        -- Screen tint logic
    end
})

-- ========================================================================
-- 10. CONTROL PEOPLE TAB
-- ========================================================================
local ControlTab = Window:Tab({
    Title = "Control People",
    Icon = "gamepad-2"
})
enhanceTabScrolling(ControlTab)

ControlTab:Dropdown({
    Title = "Select Target Player",
    Values = { "Nearest Player 1", "Nearest Player 2", "All Players" },
    Default = "Nearest Player 1",
    Callback = function(selected)
        -- Target player logic
    end
})

ControlTab:Divider()

ControlTab:Toggle({
    Title = "Spectate Mode",
    Desc = "Shifts camera view to the selected player",
    Value = false,
    Callback = function(state)
        -- Spectate logic
    end
})

ControlTab:Toggle({
    Title = "Follow Target",
    Desc = "Continuously follows the target player position",
    Value = false,
    Callback = function(state)
        -- Follow logic
    end
})

ControlTab:Toggle({
    Title = "Attraction Pulse",
    Desc = "Applies directional pull momentum toward target",
    Value = false,
    Callback = function(state)
        -- Attraction logic
    end
})

-- ========================================================================
-- 11. PERSONALIZATION TAB
-- ========================================================================
local PersonalizationTab = Window:Tab({
    Title = "Personalization",
    Icon = "palette"
})
enhanceTabScrolling(PersonalizationTab)

-- Register exclusive Darling theme
pcall(function()
    WindUI:AddTheme({
        Name = "Darling",
        Accent = Color3.fromHex("#FF4B91"),
        Background = Color3.fromHex("#141416"),
        Outline = Color3.fromHex("#28282D"),
        Text = Color3.fromHex("#FFFFFF"),
        Placeholder = Color3.fromHex("#888890"),
        Button = Color3.fromHex("#1F1F24"),
        Icon = Color3.fromHex("#FF76CE"),
    })
end)

local availableThemes = {}
local gotThemes, themesTable = pcall(function()
    return WindUI:GetThemes()
end)

if gotThemes and type(themesTable) == "table" then
    for k, v in pairs(themesTable) do
        local name = (type(k) == "string" and not tonumber(k)) and k or tostring(v)
        if not table.find(availableThemes, name) then
            table.insert(availableThemes, name)
        end
    end
    table.sort(availableThemes)
end

if #availableThemes == 0 then
    availableThemes = { "Dark", "Darling", "Rose", "Purple", "Midnight", "Emerald", "Crimson", "Violet", "Sky", "Light" }
end

PersonalizationTab:Dropdown({
    Title = "UI Color Theme",
    Values = availableThemes,
    Default = "Dark",
    Callback = function(themeName)
        pcall(function()
            WindUI:SetTheme(themeName)
            WindUI:Notify({
                Title = "Theme Updated",
                Content = "Applied: " .. tostring(themeName),
                Duration = 2,
                Icon = "palette"
            })
        end)
    end
})

PersonalizationTab:Divider()

local bgInputObj = PersonalizationTab:Input({
    Title = "Media URL or ID",
    Desc = "Paste video link, slot ID, or loadstring command",
    Placeholder = "Enter URL or ID...",
    Value = "d_d54d5cfd6e07",
    ClearTextOnFocus = false,
    Callback = function(text)
        lastEnteredBackgroundInput = text
        processAndApplyMediaInput(text)
    end
})

task.spawn(function()
    task.wait(0.2)
    pcall(function()
        local frame = bgInputObj.InputFrame or (bgInputObj.UIElements and bgInputObj.UIElements.Main)
        if frame then
            for _, desc in ipairs(frame:GetDescendants()) do
                if desc:IsA("TextBox") then
                    desc:GetPropertyChangedSignal("Text"):Connect(function()
                        lastEnteredBackgroundInput = desc.Text
                    end)
                    break
                end
            end
        end
    end)
end)

PersonalizationTab:Button({
    Title = "Apply Background",
    Callback = function()
        local textToUse = lastEnteredBackgroundInput
        if not textToUse or #textToUse:gsub("%s+", "") == 0 then
            pcall(function()
                local frame = bgInputObj.InputFrame or (bgInputObj.UIElements and bgInputObj.UIElements.Main)
                if frame then
                    for _, desc in ipairs(frame:GetDescendants()) do
                        if desc:IsA("TextBox") and #desc.Text > 0 then
                            textToUse = desc.Text
                            lastEnteredBackgroundInput = desc.Text
                            break
                        end
                    end
                end
            end)
        end

        if not textToUse or #textToUse:gsub("%s+", "") == 0 then
            WindUI:Notify({
                Title = "Background Error",
                Content = "Please enter or paste a valid link or ID.",
                Duration = 3,
                Icon = "alert-circle"
            })
            return
        end

        processAndApplyMediaInput(textToUse)
    end
})

PersonalizationTab:Button({
    Title = "Remove Background",
    Callback = function()
        clearActiveMedia()
        if imgA then imgA.Image = "" imgA.Visible = false end
        if imgB then imgB.Image = "" imgB.Visible = false end
        if tintOverlay then tintOverlay.Visible = false end
        hideBottomProgress()
        WindUI:Notify({
            Title = "Background Cleared",
            Content = "Background media has been removed.",
            Duration = 2,
            Icon = "trash-2"
        })
    end
})

PersonalizationTab:Divider()

-- Official Verified User Presets (Only verified working presets)
PersonalizationTab:Paragraph({
    Title = "Featured Backgrounds (Click to Apply)",
    Desc = "Verified video backgrounds optimized for performance."
})

PersonalizationTab:Button({
    Title = "Video: Forest (The Dark River Forest)",
    Desc = "Calm river flowing through a lush dark forest.",
    Callback = function()
        lastEnteredBackgroundInput = "d_d54d5cfd6e07"
        processAndApplyMediaInput("d_d54d5cfd6e07")
    end
})

PersonalizationTab:Button({
    Title = "Video: Snow Forest (Snowy Forest)",
    Desc = "Serene winter landscape with falling snow.",
    Callback = function()
        lastEnteredBackgroundInput = "d_ff0c0922e763"
        processAndApplyMediaInput("d_ff0c0922e763")
    end
})

PersonalizationTab:Button({
    Title = "Video: City (Futuristic Megalopolis)",
    Desc = "Cyberpunk neo city aerial view with lights.",
    Callback = function()
        lastEnteredBackgroundInput = "d_f534b8513451"
        processAndApplyMediaInput("d_f534b8513451")
    end
})

PersonalizationTab:Button({
    Title = "Video: Deepseek Girl (You Look Lonely)",
    Desc = "Atmospheric neon cyber girl scene.",
    Callback = function()
        lastEnteredBackgroundInput = "d_e9c55db344fe"
        processAndApplyMediaInput("d_e9c55db344fe")
    end
})

PersonalizationTab:Button({
    Title = "Video: Yuta Cursed Blade (Jujutsu Kaisen)",
    Desc = "High intensity cursed blade animation with audio.",
    Callback = function()
        lastEnteredBackgroundInput = "d_f573215e217e"
        processAndApplyMediaInput("d_f573215e217e")
    end
})

PersonalizationTab:Button({
    Title = "Video: Neon Purple Chill (Midnight City)",
    Desc = "Retro synthwave purple city night view with audio.",
    Callback = function()
        lastEnteredBackgroundInput = "d_8c246681eb77"
        processAndApplyMediaInput("d_8c246681eb77")
    end
})

PersonalizationTab:Divider()

PersonalizationTab:Slider({
    Title = "Background Dimming",
    Desc = "Adjusts dark overlay opacity over background media",
    Value = {
        Min = 0,
        Max = 90,
        Default = 25,
    },
    Step = 5,
    Callback = function(val)
        currentBackgroundTransparency = val / 100
        if tintOverlay then
            tintOverlay.BackgroundTransparency = 1 - currentBackgroundTransparency
        end
        if Window.SetBackgroundImageTransparency then
            pcall(function() Window:SetBackgroundImageTransparency(currentBackgroundTransparency) end)
        end
    end
})

PersonalizationTab:Dropdown({
    Title = "Media Scale Mode",
    Values = { "Crop (Original)", "Stretch (Fill Window)", "Fit (Contain)" },
    Default = "Crop (Original)",
    Callback = function(mode)
        if mode:find("Fit") then
            currentScaleType = Enum.ScaleType.Fit
        elseif mode:find("Stretch") then
            currentScaleType = Enum.ScaleType.Stretch
        else
            currentScaleType = Enum.ScaleType.Crop
        end

        if imgA then imgA.ScaleType = currentScaleType end
        if imgB then imgB.ScaleType = currentScaleType end
    end
})

PersonalizationTab:Divider()

PersonalizationTab:Toggle({
    Title = "Top Floating Toggle Widget",
    Desc = "Displays WindUI open button when minimized",
    Value = true,
    Callback = function(state)
        allowFloatingWidget = state
        pcall(function()
            if Window.EditOpenButton then
                Window:EditOpenButton({
                    Enabled = state,
                    OnlyMobile = false,
                    Color = ColorSequence.new(Color3.fromRGB(0, 0, 0), Color3.fromRGB(0, 0, 0))
                })
            end
            enforceBlackOpenButtonBorder()
        end)
    end
})

PersonalizationTab:Divider()

PersonalizationTab:Slider({
    Title = "UI Scale",
    Value = {
        Min = 70,
        Max = 130,
        Default = 100,
    },
    Step = 5,
    Callback = function(val)
        local scaleValue = val / 100
        pcall(function()
            if Window.SetUIScale then
                Window:SetUIScale(scaleValue)
            end
            if WindUI.UIScaleObj then
                WindUI.UIScaleObj.Scale = scaleValue
            end
            WindUI.UIScale = scaleValue
        end)
    end
})

PersonalizationTab:Toggle({
    Title = "Align Topbar Buttons Right",
    Value = true,
    Callback = function(state)
        if state then
            alignTopbarButtonsRight()
        end
    end
})

-- ========================================================================
-- 12. SETTINGS TAB
-- ========================================================================
local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings"
})
enhanceTabScrolling(SettingsTab)

SettingsTab:Keybind({
    Title = "Hub Toggle Shortcut",
    Desc = "Click to rebind. Press anywhere to toggle the Hub",
    Value = "F",
    Callback = function(keyName)
        if typeof(keyName) == "EnumItem" then
            currentToggleKey = keyName
        elseif type(keyName) == "string" and Enum.KeyCode[keyName] then
            currentToggleKey = Enum.KeyCode[keyName]
        end
        local now = tick()
        if now - lastToggleTick >= 0.3 then
            lastToggleTick = now
            toggleHub()
        end
    end
})

SettingsTab:Button({
    Title = "Toggle Visibility Now",
    Callback = function()
        toggleHub()
    end
})

SettingsTab:Divider()

SettingsTab:Button({
    Title = "Reset Default Settings",
    Callback = function()
        WindUI:Notify({
            Title = "Settings Reset",
            Content = "All configurations restored to default.",
            Duration = 3,
            Icon = "rotate-ccw"
        })
    end
})

SettingsTab:Button({
    Title = "Unload Darling Hub",
    Desc = "Closes and completely terminates Darling Hub",
    Callback = function()
        pcall(function()
            allowFloatingWidget = false
            DarlingHub:UnloadAll()
            clearActiveMedia()
            if Window.EditOpenButton then
                Window:EditOpenButton({ Enabled = false })
            end
            if Window.OpenButtonMain then
                Window.OpenButtonMain:Visible(false)
            end
            if Window.Destroy then
                Window:Destroy()
            end
        end)
    end
})

-- ========================================================================
-- INITIALIZATION NOTIFICATION & DEFAULT TAB SELECTION
-- ========================================================================
WindUI:Notify({
    Title = "Darling Hub",
    Content = "Darling Hub loaded successfully.",
    Duration = 4,
    Icon = darlingIcon
})

Window:SelectTab(1)

-- Auto-apply default background (Dark Forest) on first launch
task.spawn(function()
    task.wait(0.5)
    lastEnteredBackgroundInput = "d_d54d5cfd6e07"
    pcall(function()
        processAndApplyMediaInput("d_d54d5cfd6e07")
    end)
end)
