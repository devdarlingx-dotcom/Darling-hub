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

-- Duplicate instance protection: cleanly unload any previously running hub
if _G.DarlingHub and type(_G.DarlingHub.UnloadAll) == "function" then
    pcall(function() _G.DarlingHub:UnloadAll() end)
elseif SharedEnv.DarlingHub and type(SharedEnv.DarlingHub.UnloadAll) == "function" then
    pcall(function() SharedEnv.DarlingHub:UnloadAll() end)
end

local DarlingHub = {
    Modules = {},
    Overlay = nil,
    Window = nil,
    InputBeganConn = nil,
    DiagnosticThread = nil,
    -- Shared settings: UI writes here, modules read here (no module load needed)
    Settings = {
        Aim = {
            Mode = "360",            -- "360", "FOV", "180"
            Priority = "Nearest",    -- "Nearest", "Low HP", "Looking At Me"
            Hitbox = "HumanoidRootPart",
            MaxRange = 1000,
            Prediction = true,
            PredictionAmount = 0.12,
        },
        FOV = {
            Radius = 100,
            Mode = "Center",         -- "Center", "Mouse"
            Color = Color3.fromRGB(255, 255, 255),
            Thickness = 1.5,
        },
        Tracers = {
            Color = Color3.fromRGB(255, 255, 255),
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
    if self.DiagnosticThread then
        pcall(function() task.cancel(self.DiagnosticThread) end)
        self.DiagnosticThread = nil
    end
    for _, mod in pairs(self.Modules) do
        if type(mod) == "table" then
            if mod.destroy then
                pcall(mod.destroy)
            elseif mod.dismiss then
                pcall(mod.dismiss)
            elseif mod.stop then
                pcall(mod.stop)
            elseif mod.disable then
                pcall(mod.disable)
            end
        end
    end
    self.Modules = {}
    if self.Overlay then
        pcall(function() self.Overlay:Destroy() end)
        self.Overlay = nil
    end
    if self.InputBeganConn then
        pcall(function() self.InputBeganConn:Disconnect() end)
        self.InputBeganConn = nil
    end
    if _G.DarlingDeltaUI and type(_G.DarlingDeltaUI.destroy) == "function" then
        pcall(function() _G.DarlingDeltaUI.destroy() end)
    end
    if gethui then
        local d = gethui():FindFirstChild("Delta")
        if d then pcall(function() d:Destroy() end) end
        local di = gethui():FindFirstChild("DeltaIcon")
        if di then pcall(function() di:Destroy() end) end
    end
    if self.Window then
        pcall(function() self.Window:Destroy() end)
        self.Window = nil
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
    -- Fix 1: Slider disconnect on any mouse/touch release (never stuck to cursor)
    winduiRaw = winduiRaw:gsub("%)and aB==f", ")")

    -- Fix 2: Window drag release unconditionality (never gets stuck to cursor)
    winduiRaw = winduiRaw:gsub("e%.InputEnded:Connect%(function%(M%)\nif not F or p%.CurrentInput~=B then", "e.InputEnded:Connect(function(M)\nif not F then")

    -- Fix 3: Slider Value table fallback (prevents arithmetic crash on nil Min/Max)
    winduiRaw = winduiRaw:gsub(",\nLockedTitle=ak%.LockedTitle,\nValue=ak%.Value or{},", ",\nLockedTitle=ak.LockedTitle,\nValue=(typeof(ak.Value)==\"table\" and ak.Value) or {Min=ak.Min or 0, Max=ak.Max or 100, Default=ak.Default or ak.Min or 0},")

    -- Fix 4: Slider Container hitbox (32px, active, invisible catch layer with BackgroundTransparency=0.999)
    winduiRaw = winduiRaw:gsub('al%.UIElements%.SliderContainer=af%("Frame",{\nSize=UDim2%.new%(al%.Title==nil and 1 or 0,al%.Title==nil and 0 or al%.Width,0,0%),\nAutomaticSize="Y",\nPosition=UDim2%.new%(1,al%.IsTextbox and%(ak%.Window%.NewElements and%-16 or 0%)or 0,0%.5,0%),\nAnchorPoint=Vector2%.new%(1,0%.5%),\nBackgroundTransparency=1,', 'al.UIElements.SliderContainer=af("Frame",{\nSize=UDim2.new(al.Title==nil and 1 or 0,al.Title==nil and 0 or al.Width,0,32),\nActive=true,\nAutomaticSize="Y",\nPosition=UDim2.new(1,al.IsTextbox and(ak.Window.NewElements and-16 or 0)or 0,0.5,0),\nAnchorPoint=Vector2.new(1,0.5),\nBackgroundTransparency=0.999,')

    -- Fix 5: Touch / Mobile Drag Tracking (continuous finger tracking on TouchMoved/InputChanged)
    winduiRaw = winduiRaw:gsub("am=%(aB%.UserInputType==Enum%.UserInputType%.Touch%)", "am=(aB.UserInputType==Enum.UserInputType.Touch) local aTouchPos=aB.Position.X local aTouchConn if am then aTouchConn=ac.InputChanged:Connect(function(ti) if ti.UserInputType==Enum.UserInputType.Touch then aTouchPos=ti.Position.X end end) end")
    winduiRaw = winduiRaw:gsub("local f=am and aB%.Position%.X or ac:GetMouseLocation%(%)%.X", "local f=am and aTouchPos or ac:GetMouseLocation().X")
    winduiRaw = winduiRaw:gsub("an:Disconnect%(%)\nao:Disconnect%(%)", "an:Disconnect()\nao:Disconnect()\nif aTouchConn then aTouchConn:Disconnect() end")

    -- Fix 6: Slider lockout recovery (recovers leaked ai flag and clears CurrentInput lock)
    winduiRaw = winduiRaw:gsub("if al%.Locked or ai then\nreturn\nend\nif\naA%.UserInputType==Enum%.UserInputType%.MouseButton1\nor aA%.UserInputType==Enum%.UserInputType%.Touch\nthen\nif ak%.WindUI%.CurrentInput and ak%.WindUI%.CurrentInput~=az then\nreturn\nend", "if al.Locked then return end\nif ai and not (ac:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)) then ai=false end\nif ai then return end\nif\naA.UserInputType==Enum.UserInputType.MouseButton1\nor aA.UserInputType==Enum.UserInputType.Touch\nthen\nak.WindUI.CurrentInput=az")
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
DarlingHub.Window = Window

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
            local waitStep = math.clamp(1 / math.max(fps, 1), 0.033, 0.1)
            while true do
                local isUIVisible = true
                pcall(function()
                    if Window and Window.UIElements and Window.UIElements.Main then
                        isUIVisible = Window.UIElements.Main.Visible
                    end
                end)

                if not isUIVisible then
                    task.wait(0.5)
                else
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

                    task.wait(waitStep)
                end
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
                    local isUIVisible = true
                    pcall(function()
                        if Window and Window.UIElements and Window.UIElements.Main then
                            isUIVisible = Window.UIElements.Main.Visible
                        end
                    end)

                    if not isUIVisible then
                        task.wait(0.5)
                    else
                        back.ZIndex = 6
                        cur.ZIndex = 5
                        cur, back = back, cur

                        local nextIdx = (i % n) + 1
                        local nextAsset = assets[nextIdx]
                        if nextAsset and type(nextAsset) == "string" and #nextAsset > 0 then
                            back.Image = nextAsset
                        end
                        task.wait(delays[i] or 0.08)
                    end
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
        DarlingHub:UnloadAll()
    end)
end

-- Global Keyboard Shortcut Listener with 0.3s Debounce
local lastToggleTick = 0
DarlingHub.InputBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
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
    Desc = "360 = all directions, FOV = circle, 180 = forward only",
    Values = { "360", "FOV", "180" },
    Value = "360",
    Callback = function(v)
        if type(v) == "string" then
            AimSettings.Aim.Mode = v
            local core = (_G.DarlingCombatCore) or (getgenv and getgenv().DarlingCombatCore)
            if core then core.AimMode = v end
        end
    end
})

AimbotTab:Slider({
    Title = "Max Range",
    Width = 200,
    Value = { Min = 100, Max = 3000, Default = 1000 },
    Step = 50,
    Callback = function(v)
        local val = tonumber(v) or 1000
        AimSettings.Aim.MaxRange = val
        local core = (_G.DarlingCombatCore) or (getgenv and getgenv().DarlingCombatCore)
        if core then
            core.MaxRange = val
        end
        local npcAim = DarlingHub:Require("modules/combat/npc_aimbot.lua")
        if npcAim and npcAim.setMaxRange then npcAim.setMaxRange(val) end
        local playerAim = DarlingHub:Require("modules/combat/player_aimbot.lua")
        if playerAim and playerAim.setMaxRange then playerAim.setMaxRange(val) end
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
    Width = 200,
    Value = { Min = 20, Max = 600, Default = 100 },
    Step = 5,
    Callback = function(v)
        local val = tonumber(v) or 100
        AimSettings.FOV.Radius = val
        local core = (_G.DarlingCombatCore) or (getgenv and getgenv().DarlingCombatCore)
        if core and core.FOV then
            core.FOV.Radius = val
        end
        local fovMod = DarlingHub:Require("modules/combat/fov.lua")
        if fovMod and fovMod.setRadius then
            fovMod.setRadius(val)
        end
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
    Value = "White",
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
    Value = "White",
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

PlayersTab:Paragraph({
    Title = "Server Players",
    Desc = "View player skins, monitor live health, blacklist from aimbot, or spectate",
})

local isPlayerListMounted = false
local function mountPlayerListOnce()
    if isPlayerListMounted then return end
    isPlayerListMounted = true
    pcall(function()
        local PlayerList = DarlingHub:Require("modules/players/player_list.lua")
        if PlayerList and PlayerList.mount then
            local cf = (PlayersTab.UIElements and PlayersTab.UIElements.ContainerFrame)
                or PlayersTab.ContainerFrame
                or (PlayersTab.UIElements and PlayersTab.UIElements.Main)
            if cf then
                PlayerList.mount(cf)
            else
                PlayerList.mount(PlayersTab)
            end
        end
    end)
end

task.spawn(function()
    task.wait(0.2)
    pcall(function()
        local cf = (PlayersTab.UIElements and PlayersTab.UIElements.ContainerFrame)
            or PlayersTab.ContainerFrame
            or (PlayersTab.UIElements and PlayersTab.UIElements.Main)
        if cf then
            cf:GetPropertyChangedSignal("Visible"):Connect(function()
                if cf.Visible then
                    mountPlayerListOnce()
                end
            end)
            if cf.Visible then
                mountPlayerListOnce()
            end
        end
        local btn = (PlayersTab.UIElements and (PlayersTab.UIElements.TabButton or PlayersTab.UIElements.Button))
            or PlayersTab.TabButton or PlayersTab.Button
        if btn and btn.Activated then
            btn.Activated:Connect(mountPlayerListOnce)
        end
    end)
end)

-- ========================================================================
-- 4. PVP TAB
-- ========================================================================
local PvpTab = Window:Tab({
    Title = "Pvp",
    Icon = "swords"
})
enhanceTabScrolling(PvpTab)

local function getPvpMod(path)
    return DarlingHub:Require(path)
end

-- --- Combat Assistance ---
PvpTab:Toggle({
    Title = "Fast Attack (Weapons & Fruits)",
    Desc = "Rapid-fire attack bursts for Swords, Melee, and Demon Fruits",
    Value = false,
    Callback = function(state)
        local mod = getPvpMod("modules/pvp/fast_attack.lua")
        if mod then
            if state then mod.enable() else mod.disable() end
        end
    end
})

PvpTab:Slider({
    Title = "Fast Attack Delay",
    Desc = "Delay between burst hits in seconds",
    Width = 200,
    Value = { Min = 0.01, Max = 0.20, Default = 0.08 },
    Step = 0.01,
    Callback = function(val)
        local mod = getPvpMod("modules/pvp/fast_attack.lua")
        if mod then mod.AttackDelay = tonumber(val) or 0.08 end
    end
})

PvpTab:Toggle({
    Title = "Dragon Storm Aura (Gun M1)",
    Desc = "High-speed Gun M1 auto burst targeting Players, Mobs, and Sea Events [Key: G]",
    Value = false,
    Callback = function(state)
        local mod = getPvpMod("modules/pvp/dragon_gun.lua")
        if mod then
            if state then mod.enable() else mod.disable() end
        end
    end
})

PvpTab:Slider({
    Title = "Dragon Gun Burst Rate",
    Desc = "Number of gun shots fired per frame",
    Width = 200,
    Value = { Min = 1, Max = 8, Default = 3 },
    Step = 1,
    Callback = function(val)
        local mod = getPvpMod("modules/pvp/dragon_gun.lua")
        if mod then mod.ShotsPerFrame = math.floor(tonumber(val) or 3) end
    end
})

PvpTab:Toggle({
    Title = "One Shot Kitsune (Fruit M1)",
    Desc = "High-vector projectile M1 burst for Demon Fruits within 500 studs",
    Value = false,
    Callback = function(state)
        local mod = getPvpMod("modules/pvp/fruits_m1.lua")
        if mod then
            if state then mod.enable() else mod.disable() end
        end
    end
})

PvpTab:Divider()

-- --- Defense & Awakening ---
PvpTab:Toggle({
    Title = "Auto Race V3",
    Desc = "Automatically activates Race V3 ability in combat when health drops",
    Value = false,
    Callback = function(state)
        local mod = getPvpMod("modules/pvp/race_awakening.lua")
        if mod then mod.setAutoV3(state) end
    end
})

PvpTab:Slider({
    Title = "Race V3 Health Threshold",
    Desc = "Health percentage trigger for Race V3 activation",
    Width = 200,
    Value = { Min = 10, Max = 95, Default = 75 },
    Step = 5,
    Callback = function(val)
        local mod = getPvpMod("modules/pvp/race_awakening.lua")
        if mod then mod.V3HealthThreshold = tonumber(val) or 75 end
    end
})

PvpTab:Toggle({
    Title = "Auto Race V4",
    Desc = "Automatically triggers Race V4 awakening as soon as awakening meter is full",
    Value = false,
    Callback = function(state)
        local mod = getPvpMod("modules/pvp/race_awakening.lua")
        if mod then mod.setAutoV4(state) end
    end
})

PvpTab:Toggle({
    Title = "Anti Stun Hitbox",
    Desc = "Clears enemy stun values and removes hostile body movers that freeze character",
    Value = false,
    Callback = function(state)
        local mod = getPvpMod("modules/pvp/race_awakening.lua")
        if mod then mod.setAntiStun(state) end
    end
})

PvpTab:Divider()

-- --- Mobility & Movement Tech ---
PvpTab:Toggle({
    Title = "Sanguine Z Boost",
    Desc = "High-velocity directional launch in camera look direction [Key: Z]",
    Value = false,
    Callback = function(state)
        local mod = getPvpMod("modules/pvp/sanguine_boost.lua")
        if mod then
            if state then mod.enable() else mod.disable() end
        end
    end
})

PvpTab:Slider({
    Title = "Sanguine Velocity Power",
    Desc = "Linear velocity power multiplier",
    Width = 200,
    Value = { Min = 100, Max = 800, Default = 400 },
    Step = 25,
    Callback = function(val)
        local mod = getPvpMod("modules/pvp/sanguine_boost.lua")
        if mod then mod.VelocityPower = tonumber(val) or 400 end
    end
})

PvpTab:Toggle({
    Title = "Ninja Dash (0 Cooldown)",
    Desc = "Zero-cooldown tactical zigzag dash with camera punch and physics boost [Key: Q]",
    Value = false,
    Callback = function(state)
        local mod = getPvpMod("modules/pvp/ninja_dash.lua")
        if mod then
            if state then mod.enable() else mod.disable() end
        end
    end
})

PvpTab:Slider({
    Title = "Ninja Dash Speed",
    Desc = "Impulse velocity of the ninja dash",
    Width = 200,
    Value = { Min = 100, Max = 500, Default = 220 },
    Step = 20,
    Callback = function(val)
        local mod = getPvpMod("modules/pvp/ninja_dash.lua")
        if mod then mod.DashSpeed = tonumber(val) or 220 end
    end
})

PvpTab:Toggle({
    Title = "Infinite Flashstep",
    Desc = "Sets Flashstep cooldown to zero for unlimited instant teleports",
    Value = false,
    Callback = function(state)
        local mod = getPvpMod("modules/pvp/flashstep.lua")
        if mod then mod.setInfinite(state) end
    end
})

PvpTab:Toggle({
    Title = "Soru TP Aimbot",
    Desc = "Teleports directly onto target enemy player upon using Flashstep [Key: R]",
    Value = false,
    Callback = function(state)
        local mod = getPvpMod("modules/pvp/flashstep.lua")
        if mod then mod.setAimbot(state) end
    end
})

PvpTab:Dropdown({
    Title = "Soru Target Mode",
    Values = { "Nearest Player", "Selected Player" },
    Value = "Nearest Player",
    Callback = function(selected)
        local mod = getPvpMod("modules/pvp/flashstep.lua")
        if mod then mod.TargetMode = selected end
    end
})

PvpTab:Slider({
    Title = "Soru Max Distance",
    Desc = "Maximum distance in studs for Soru TP aimbot",
    Width = 200,
    Value = { Min = 200, Max = 3000, Default = 2000 },
    Step = 100,
    Callback = function(val)
        local mod = getPvpMod("modules/pvp/flashstep.lua")
        if mod then mod.MaxDistance = tonumber(val) or 2000 end
    end
})

PvpTab:Toggle({
    Title = "Flight Mode",
    Desc = "Smooth 3D camera-directed flight [Key: X, Controls: WASD, Space, Shift]",
    Value = false,
    Callback = function(state)
        local mod = getPvpMod("modules/movement/movement_engine.lua")
        if mod then
            if state then mod.startFly() else mod.stopFly() end
        end
    end
})

PvpTab:Slider({
    Title = "Flight Speed",
    Desc = "Flight propulsion velocity",
    Width = 200,
    Value = { Min = 20, Max = 350, Default = 70 },
    Step = 5,
    Callback = function(val)
        local mod = getPvpMod("modules/movement/movement_engine.lua")
        if mod then mod.FlySpeed = tonumber(val) or 70 end
    end
})

PvpTab:Toggle({
    Title = "Walk Speed Boost",
    Desc = "Bypasses Blox Fruits speed clamp for rapid ground movement",
    Value = false,
    Callback = function(state)
        local mod = getPvpMod("modules/movement/movement_engine.lua")
        if mod then mod.setWalkSpeed(state) end
    end
})

PvpTab:Slider({
    Title = "Walk Speed Value",
    Desc = "Target movement speed",
    Width = 200,
    Value = { Min = 16, Max = 350, Default = 32 },
    Step = 4,
    Callback = function(val)
        local mod = getPvpMod("modules/movement/movement_engine.lua")
        if mod then mod.setWalkSpeed(mod.WalkSpeedEnabled, tonumber(val) or 32) end
    end
})

PvpTab:Toggle({
    Title = "Dash Distance Boost",
    Desc = "Extends the distance of normal character dashes",
    Value = false,
    Callback = function(state)
        local mod = getPvpMod("modules/movement/movement_engine.lua")
        if mod then mod.setDashDistance(state) end
    end
})

PvpTab:Slider({
    Title = "Dash Distance Length",
    Desc = "Dash length attribute value",
    Width = 200,
    Value = { Min = 1, Max = 300, Default = 50 },
    Step = 5,
    Callback = function(val)
        local mod = getPvpMod("modules/movement/movement_engine.lua")
        if mod then mod.setDashDistance(mod.DashDistanceEnabled, tonumber(val) or 50) end
    end
})

PvpTab:Toggle({
    Title = "Super Jump",
    Desc = "Instant direct vertical velocity impulse on Space or widget",
    Value = false,
    Callback = function(state)
        local mod = getPvpMod("modules/movement/movement_engine.lua")
        if mod then mod.setSuperJump(state) end
    end
})

PvpTab:Slider({
    Title = "Super Jump Power",
    Desc = "Upward vertical impulse velocity",
    Width = 200,
    Value = { Min = 100, Max = 1000, Default = 500 },
    Step = 50,
    Callback = function(val)
        local mod = getPvpMod("modules/movement/movement_engine.lua")
        if mod then mod.SuperJumpPower = tonumber(val) or 500 end
    end
})

PvpTab:Toggle({
    Title = "Infinite Air Jump",
    Desc = "Resets jump counter allowing unlimited jumps in mid-air",
    Value = false,
    Callback = function(state)
        local mod = getPvpMod("modules/movement/movement_engine.lua")
        if mod then mod.setInfiniteJump(state) end
    end
})

PvpTab:Toggle({
    Title = "Walk on Water",
    Desc = "Enables water walking attribute and dynamic surface platform",
    Value = false,
    Callback = function(state)
        local mod = getPvpMod("modules/movement/movement_engine.lua")
        if mod then mod.setWalkOnWater(state) end
    end
})

PvpTab:Toggle({
    Title = "Noclip",
    Desc = "Disables character collision allowing you to walk through walls",
    Value = false,
    Callback = function(state)
        local mod = getPvpMod("modules/movement/movement_engine.lua")
        if mod then mod.setNoclip(state) end
    end
})

PvpTab:Divider()

-- --- Performance & Client Tweaks ---
PvpTab:Toggle({
    Title = "FFlags 1 (FPS Booster)",
    Desc = "120 FPS cap, smooth plastic textures, removes atmosphere fog, hides debris",
    Value = false,
    Callback = function(state)
        local mod = getPvpMod("modules/utility/client_tweaks.lua")
        if mod then mod.setFFlags1(state) end
    end
})

PvpTab:Toggle({
    Title = "No Animations",
    Desc = "Stops non-attack animations to fix sideways bug and character freezes",
    Value = false,
    Callback = function(state)
        local mod = getPvpMod("modules/utility/client_tweaks.lua")
        if mod then mod.setNoAnimations(state) end
    end
})

PvpTab:Toggle({
    Title = "Anti Lava",
    Desc = "Disables limb touch detection for complete lava damage immunity",
    Value = false,
    Callback = function(state)
        local mod = getPvpMod("modules/utility/client_tweaks.lua")
        if mod then mod.setAntiLava(state) end
    end
})

PvpTab:Toggle({
    Title = "Camera Skew (Rare View)",
    Desc = "Stretches and shears camera projection for wide competitive perspective",
    Value = false,
    Callback = function(state)
        local mod = getPvpMod("modules/utility/client_tweaks.lua")
        if mod then mod.setCameraSkew(state) end
    end
})

PvpTab:Slider({
    Title = "Skew Resolution",
    Desc = "Vertical projection factor (lower is more stretched/skewed)",
    Width = 200,
    Value = { Min = 0.05, Max = 1.0, Default = 0.2 },
    Step = 0.05,
    Callback = function(val)
        local mod = getPvpMod("modules/utility/client_tweaks.lua")
        if mod then mod.setCameraSkew(mod.CameraSkewEnabled, tonumber(val) or 0.2) end
    end
})

PvpTab:Divider()

-- --- Floating Widgets Display ---
PvpTab:Toggle({
    Title = "Show Floating Widgets",
    Desc = "Shows or hides all draggable quick-toggle floating widgets on screen",
    Value = true,
    Callback = function(state)
        local sang = getPvpMod("modules/pvp/sanguine_boost.lua")
        if sang then sang.setFloatingVisible(state) end
        local gun = getPvpMod("modules/pvp/dragon_gun.lua")
        if gun then gun.setFloatingVisible(state) end
        local fast = getPvpMod("modules/pvp/fast_attack.lua")
        if fast then fast.setFloatingVisible(state) end
        local ninja = getPvpMod("modules/pvp/ninja_dash.lua")
        if ninja then ninja.setFloatingVisible(state) end
        local flash = getPvpMod("modules/pvp/flashstep.lua")
        if flash then flash.setFloatingVisible(state) end
        local fruits = getPvpMod("modules/pvp/fruits_m1.lua")
        if fruits then fruits.setFloatingVisible(state) end
        local mov = getPvpMod("modules/movement/movement_engine.lua")
        if mov then
            if mov.FlyWidget then mov.FlyWidget:SetVisible(state) end
            if mov.SuperJumpWidget then mov.SuperJumpWidget:SetVisible(state) end
        end
    end
})

PvpTab:Toggle({
    Title = "Lock Widgets Position",
    Desc = "Locks all floating action and toggle widgets in place to prevent accidental dragging",
    Value = false,
    Callback = function(state)
        local fw = getPvpMod("modules/pvp/floating_widget.lua")
        if fw and fw.LockAll then fw.LockAll(state) end
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

local function getVisualsMod(path)
    return DarlingHub:Require(path)
end

-- --- Player ESP & Multi-Tracers ---
VisualsTab:Toggle({
    Title = "2D Quad Boxes",
    Desc = "Renders cornered 2D bounding boxes around all enemy players",
    Value = false,
    Callback = function(state)
        local mod = getVisualsMod("modules/visuals/esp.lua")
        if mod then mod.setBoxes(state) end
    end
})

VisualsTab:Toggle({
    Title = "Player Names",
    Desc = "Displays formatted usernames directly above player heads",
    Value = false,
    Callback = function(state)
        local mod = getVisualsMod("modules/visuals/esp.lua")
        if mod then mod.setNames(state) end
    end
})

VisualsTab:Toggle({
    Title = "Health Bars",
    Desc = "Dynamic color-coded health status bar on the side of character bounding boxes",
    Value = false,
    Callback = function(state)
        local mod = getVisualsMod("modules/visuals/esp.lua")
        if mod then mod.setHealth(state) end
    end
})

VisualsTab:Toggle({
    Title = "Distance Indicator",
    Desc = "Displays live distance measurement in studs below player feet",
    Value = false,
    Callback = function(state)
        local mod = getVisualsMod("modules/visuals/esp.lua")
        if mod then mod.setDistance(state) end
    end
})

VisualsTab:Toggle({
    Title = "Equipped Tool / Weapon",
    Desc = "Shows current weapon, fruit, melee, or gun held by the player",
    Value = false,
    Callback = function(state)
        local mod = getVisualsMod("modules/visuals/esp.lua")
        if mod then mod.setTool(state) end
    end
})

VisualsTab:Toggle({
    Title = "Chams / Highlights",
    Desc = "Applies radiant silhouette highlights through walls over enemy models",
    Value = false,
    Callback = function(state)
        local mod = getVisualsMod("modules/visuals/esp.lua")
        if mod then mod.setChams(state) end
    end
})

VisualsTab:Toggle({
    Title = "Multi-Tracers (All Players)",
    Desc = "Draws dynamic snaplines connecting viewport origin to every player on the map",
    Value = false,
    Callback = function(state)
        local mod = getVisualsMod("modules/visuals/esp.lua")
        if mod then mod.setTracers(state) end
    end
})

VisualsTab:Dropdown({
    Title = "Tracer Line Color",
    Values = { "White", "Cyan", "Purple", "Green", "Yellow", "Orange", "Red", "Pink" },
    Value = "White",
    Callback = function(selected)
        local mod = getVisualsMod("modules/visuals/esp.lua")
        if mod then
            local colors = {
                ["White"] = Color3.fromRGB(255, 255, 255),
                ["Cyan"] = Color3.fromRGB(56, 189, 248),
                ["Purple"] = Color3.fromRGB(192, 132, 252),
                ["Green"] = Color3.fromRGB(34, 197, 94),
                ["Yellow"] = Color3.fromRGB(250, 204, 21),
                ["Orange"] = Color3.fromRGB(251, 146, 60),
                ["Red"] = Color3.fromRGB(244, 63, 94),
                ["Pink"] = Color3.fromRGB(244, 114, 182),
            }
            mod.setTracerColor(colors[selected] or Color3.fromRGB(255, 255, 255))
        end
    end
})

VisualsTab:Divider()

-- --- Sacred Ship Painter ---
VisualsTab:Button({
    Title = "Detect Player Ship",
    Desc = "Scans within 500 studs for your vehicle seat or pirate ship",
    Callback = function()
        local mod = getVisualsMod("modules/visuals/ship_painter.lua")
        if mod then
            local ship = mod.findPlayerShip()
            if ship then
                WindUI:Notify({
                    Title = "Ship Painter",
                    Content = "Ship detected successfully: " .. tostring(ship.Name),
                    Duration = 3,
                    Icon = darlingIcon
                })
            else
                WindUI:Notify({
                    Title = "Ship Painter",
                    Content = "No ship found within 500 studs. Sit in a vehicle seat first.",
                    Duration = 4,
                    Icon = darlingIcon
                })
            end
        end
    end
})

VisualsTab:Dropdown({
    Title = "Ship Color",
    Values = { "Red", "Blue", "Green", "Purple", "White", "Yellow", "Void (Black)", "Orange" },
    Value = "Purple",
    Callback = function(selected)
        local mod = getVisualsMod("modules/visuals/ship_painter.lua")
        if mod then
            local colors = {
                ["Red"] = Color3.fromRGB(244, 63, 94),
                ["Blue"] = Color3.fromRGB(59, 130, 246),
                ["Green"] = Color3.fromRGB(34, 197, 94),
                ["Purple"] = Color3.fromRGB(192, 132, 252),
                ["White"] = Color3.fromRGB(255, 255, 255),
                ["Yellow"] = Color3.fromRGB(250, 204, 21),
                ["Void (Black)"] = Color3.fromRGB(15, 15, 18),
                ["Orange"] = Color3.fromRGB(251, 146, 60),
            }
            local c = colors[selected] or Color3.fromRGB(192, 132, 252)
            mod.paintShip(c)
        end
    end
})

VisualsTab:Toggle({
    Title = "Rainbow Ship Mode",
    Desc = "Continuously cycles ship material hue across full RGB spectrum",
    Value = false,
    Callback = function(state)
        local mod = getVisualsMod("modules/visuals/ship_painter.lua")
        if mod then mod.setRainbow(state) end
    end
})

VisualsTab:Button({
    Title = "Reset Original Ship Colors",
    Desc = "Restores all ship part materials and original default colors",
    Callback = function()
        local mod = getVisualsMod("modules/visuals/ship_painter.lua")
        if mod then
            local ok = mod.resetShip()
            if ok then
                WindUI:Notify({
                    Title = "Ship Painter",
                    Content = "Ship colors restored to original.",
                    Duration = 3,
                    Icon = darlingIcon
                })
            end
        end
    end
})

VisualsTab:Divider()

-- --- Sacred Ship Resizer ---
VisualsTab:Slider({
    Title = "Ship Scale Multiplier",
    Desc = "Scales your ship size up to 20x with heartbeat anti-reversion",
    Width = 200,
    Value = { Min = 1, Max = 20, Default = 1 },
    Step = 1,
    Callback = function(val)
        local mod = getVisualsMod("modules/visuals/ship_resizer.lua")
        if mod then mod.setShipSize(tonumber(val) or 1) end
    end
})

VisualsTab:Button({
    Title = "Reset Ship Size (1x)",
    Desc = "Returns ship scale back to default dimensions",
    Callback = function()
        local mod = getVisualsMod("modules/visuals/ship_resizer.lua")
        if mod then
            mod.resetShipSize()
            WindUI:Notify({
                Title = "Ship Resizer",
                Content = "Ship size restored to default (1x).",
                Duration = 3,
                Icon = darlingIcon
            })
        end
    end
})

VisualsTab:Divider()

-- --- Shaders & Skybox Environment ---
VisualsTab:Toggle({
    Title = "RTX Shaders",
    Desc = "High-fidelity Bloom, ColorCorrection, and atmospheric lighting filters",
    Value = false,
    Callback = function(state)
        local mod = getVisualsMod("modules/visuals/shaders_skybox.lua")
        if mod then mod.setShaders(state) end
    end
})

VisualsTab:Dropdown({
    Title = "RTX Preset",
    Values = { "RTX ULTRA", "RTX REFLECT", "REALISTIC", "CINEMATIC", "VIBRANT", "SUNSET", "NIGHT", "GOLDEN" },
    Value = "RTX ULTRA",
    Callback = function(selected)
        local mod = getVisualsMod("modules/visuals/shaders_skybox.lua")
        if mod then mod.setShaders(mod.ShadersEnabled, selected) end
    end
})

VisualsTab:Toggle({
    Title = "Custom Skybox",
    Desc = "Replaces default sky with high-resolution space, nebula, or fantasy skybox",
    Value = false,
    Callback = function(state)
        local mod = getVisualsMod("modules/visuals/shaders_skybox.lua")
        if mod then mod.setSkybox(state) end
    end
})

VisualsTab:Dropdown({
    Title = "Skybox Selection",
    Values = {
        "Galaxy", "Purple Night", "Blue Space", "Flaming Sunset", "Nebula",
        "Evening Glow", "Sci-Fi Stars", "Pink Cloud", "Space Nebula",
        "Red Planet", "Arctic Dawn", "Deep Void", "Cloudscape", "Dark Space"
    },
    Value = "Galaxy",
    Callback = function(selected)
        local mod = getVisualsMod("modules/visuals/shaders_skybox.lua")
        if mod then mod.setSkybox(mod.SkyboxEnabled, selected) end
    end
})

VisualsTab:Divider()

-- --- External & Special Mod Engines ---
VisualsTab:Button({
    Title = "Launch Delta UI",
    Desc = "Executes the embedded Delta Android touch executor interface",
    Callback = function()
        pcall(function()
            local code = readLocalModule("modules/special/delta_ui.lua")
            if not code then
                code = universalHttpGet(RepoBase .. "modules/special/delta_ui.lua")
            end
            if code then
                local fn, err = loadstring(code)
                if fn then
                    task.spawn(fn)
                    WindUI:Notify({
                        Title = "Delta UI",
                        Content = "Delta touch executor interface launched successfully.",
                        Duration = 4,
                        Icon = darlingIcon
                    })
                else
                    warn("[Darling Hub] Failed to parse Delta UI: " .. tostring(err))
                end
            end
        end)
    end
})

VisualsTab:Divider()


-- ========================================================================
-- 6. SKINS TAB
-- ========================================================================
local SkinsTab = Window:Tab({
    Title = "Skins",
    Icon = "shirt"
})
enhanceTabScrolling(SkinsTab)

local SkinsMod = nil
local function getSkinsMod()
    if not SkinsMod then
        SkinsMod = DarlingHub:Require("modules/visuals/skins_system.lua")
    end
    return SkinsMod
end

-- ------------------------------------------------------------------------
-- SECTION 1: VFX & SKILL COLORS
-- ------------------------------------------------------------------------
SkinsTab:Paragraph({
    Title = "VFX & Skill Colors",
    Desc = "Recolor Blox Fruits combat effects, sword slashes, aura highlights, and ground particles",
    Image = "sparkles"
})

SkinsTab:Toggle({
    Title = "Darling VFX Engine",
    Desc = "Master switch to dynamically recolor combat particles",
    Value = false,
    Callback = function(state)
        local mod = getSkinsMod()
        if mod then
            mod.setVFXEnabled(state)
            WindUI:Notify({
                Title = "VFX Engine",
                Content = state and "Darling VFX Enabled" or "Darling VFX Disabled",
                Duration = 2,
                Icon = darlingIcon
            })
        end
    end
})

SkinsTab:Dropdown({
    Title = "VFX Color Preset",
    Values = {
        "Purple", "Red", "Blue", "Cyan", "Green", "Gold",
        "Pink", "Magenta", "White", "Black", "Midnight", "Orange",
        "Crimson", "Lime", "Silver", "Teal", "Ice Blue"
    },
    Default = "Purple",
    Callback = function(preset)
        local mod = getSkinsMod()
        if mod then
            local col = mod.Presets[preset] or Color3.fromRGB(165, 80, 235)
            mod.setVFXColor(col)
            WindUI:Notify({
                Title = "VFX Color",
                Content = "VFX color set to " .. preset,
                Duration = 2,
                Icon = darlingIcon
            })
        end
    end
})

SkinsTab:Toggle({
    Title = "Affect Skills",
    Desc = "Recolors fruit and fighting style particle emitters",
    Value = true,
    Callback = function(state)
        local mod = getSkinsMod()
        if mod then
            mod.VFX.AffectSkills = state
            if mod.VFX.Enabled then mod.refreshAllVFX() end
        end
    end
})

SkinsTab:Toggle({
    Title = "Affect Swords",
    Desc = "Recolors sword slash highlights and trails",
    Value = true,
    Callback = function(state)
        local mod = getSkinsMod()
        if mod then
            mod.VFX.AffectSwords = state
            if mod.VFX.Enabled then mod.refreshAllVFX() end
        end
    end
})

SkinsTab:Toggle({
    Title = "Affect Transform",
    Desc = "Recolors Buddha, Dragon, and V4 aura highlights",
    Value = true,
    Callback = function(state)
        local mod = getSkinsMod()
        if mod then
            mod.VFX.AffectTransform = state
            if mod.VFX.Enabled then mod.refreshAllVFX() end
        end
    end
})

SkinsTab:Toggle({
    Title = "Affect Environment",
    Desc = "Recolors world origin ground effects",
    Value = false,
    Callback = function(state)
        local mod = getSkinsMod()
        if mod then
            mod.VFX.AffectEnvironment = state
            if mod.VFX.Enabled then mod.refreshAllVFX() end
        end
    end
})

SkinsTab:Button({
    Title = "Reset Original VFX",
    Desc = "Restores all skill and combat particles back to default colors",
    Callback = function()
        local mod = getSkinsMod()
        if mod then
            mod.setVFXEnabled(false)
            WindUI:Notify({
                Title = "VFX Reset",
                Content = "All particles restored to original colors",
                Duration = 2,
                Icon = darlingIcon
            })
        end
    end
})

SkinsTab:Divider()

-- ------------------------------------------------------------------------
-- SECTION 2: TOOL SKINS & HOTBAR
-- ------------------------------------------------------------------------
SkinsTab:Paragraph({
    Title = "Tool Skins & Hotbar",
    Desc = "Custom cosmetics for Fruits, Swords, Guns, Melee and Hotbar icons",
    Image = "swords"
})

local selectedCategory = "Fruits"
local selectedSkinPreset = "Purple"

SkinsTab:Dropdown({
    Title = "Equipment Category",
    Values = { "Fruits", "Swords", "Guns", "Melee" },
    Default = "Fruits",
    Callback = function(cat)
        selectedCategory = cat
        local mod = getSkinsMod()
        if mod then mod.Tools.SelectedCategory = cat end
    end
})

SkinsTab:Dropdown({
    Title = "Skin Preset Catalog",
    Values = {
        "White", "Black", "Purple", "Red", "Blue", "Cyan",
        "Green", "Gold", "Pink", "Orange", "Crimson", "Lime",
        "Magenta", "Midnight", "Silver"
    },
    Default = "Purple",
    Callback = function(preset)
        selectedSkinPreset = preset
    end
})

SkinsTab:Input({
    Title = "Custom Asset ID (Optional)",
    Desc = "Override tool or hotbar icon with custom asset",
    Placeholder = "e.g. rbxassetid://106579555405966",
    Value = "",
    Callback = function(val)
        local mod = getSkinsMod()
        if mod then mod.Tools.CustomAssetId = val or "" end
    end
})

SkinsTab:Button({
    Title = "Apply Skin to Category",
    Desc = "Applies chosen skin to hotbar icon and held weapon mesh",
    Callback = function()
        local mod = getSkinsMod()
        if mod then
            mod.applyToolSkin(selectedCategory, selectedSkinPreset)
            WindUI:Notify({
                Title = selectedCategory .. " Skin",
                Content = selectedSkinPreset .. " applied to " .. selectedCategory .. " and hotbar!",
                Duration = 2.5,
                Icon = darlingIcon
            })
        end
    end
})

SkinsTab:Button({
    Title = "Apply Skin to All Hotbar Slots & Tools",
    Desc = "Recolors every slot in your hotbar and all weapons in inventory",
    Callback = function()
        local mod = getSkinsMod()
        if mod then
            local count = mod.recolorAllHotbarSlots(selectedSkinPreset)
            WindUI:Notify({
                Title = "Hotbar & Tools Skin",
                Content = selectedSkinPreset .. " applied to " .. tostring(count) .. " slots and inventory!",
                Duration = 2.5,
                Icon = darlingIcon
            })
        end
    end
})

SkinsTab:Button({
    Title = "Reset Category Skin",
    Desc = "Removes custom skin and restores default hotbar icon for selected category",
    Callback = function()
        local mod = getSkinsMod()
        if mod then
            mod.resetCategoryToolSkin(selectedCategory)
            WindUI:Notify({
                Title = selectedCategory .. " Skin",
                Content = selectedCategory .. " skin reset to default",
                Duration = 2,
                Icon = darlingIcon
            })
        end
    end
})

SkinsTab:Button({
    Title = "Reset All Tool Skins",
    Desc = "Restores all weapon skins and hotbar slots back to default",
    Callback = function()
        local mod = getSkinsMod()
        if mod then
            mod.resetAllToolSkins()
            WindUI:Notify({
                Title = "Skins Reset",
                Content = "All categories and hotbar slots reset",
                Duration = 2,
                Icon = darlingIcon
            })
        end
    end
})

SkinsTab:Divider()

-- ------------------------------------------------------------------------
-- SECTION 3: CHARACTER SKIN CHANGER
-- ------------------------------------------------------------------------
SkinsTab:Paragraph({
    Title = "Character Skin Changer",
    Desc = "Recolor character body parts, limb materials, and glowing particle auras",
    Image = "user"
})

local selectedCharPreset = "Darling Pink"

SkinsTab:Toggle({
    Title = "Enable Character Skin Changer",
    Desc = "Overrides character body parts with chosen skin color and styling",
    Value = false,
    Callback = function(state)
        local mod = getSkinsMod()
        if mod then
            if state then
                mod.applyCharacterSkin(selectedCharPreset)
                WindUI:Notify({
                    Title = "Character Skin",
                    Content = "Character skin applied (" .. selectedCharPreset .. ")",
                    Duration = 2,
                    Icon = darlingIcon
                })
            else
                mod.resetCharacterSkin()
                WindUI:Notify({
                    Title = "Character Skin",
                    Content = "Character appearance restored",
                    Duration = 2,
                    Icon = darlingIcon
                })
            end
        end
    end
})

SkinsTab:Dropdown({
    Title = "Character Tone Preset",
    Values = {
        "Darling Pink", "White", "Black", "Gold", "Cyan",
        "Crimson", "Green", "Purple", "Silver", "Orange"
    },
    Default = "Darling Pink",
    Callback = function(preset)
        selectedCharPreset = preset
        local mod = getSkinsMod()
        if mod and mod.Character.Enabled then
            mod.applyCharacterSkin(preset)
        end
    end
})

SkinsTab:Dropdown({
    Title = "Character Material",
    Values = { "SmoothPlastic", "Neon", "ForceField", "Glass" },
    Default = "SmoothPlastic",
    Callback = function(matName)
        local mod = getSkinsMod()
        if mod then
            mod.Character.Material = Enum.Material[matName] or Enum.Material.SmoothPlastic
            if mod.Character.Enabled then
                mod.applyCharacterSkin(selectedCharPreset)
            end
        end
    end
})

SkinsTab:Toggle({
    Title = "Character Particle Aura",
    Desc = "Generates a glowing aura highlight matching your active character skin",
    Value = false,
    Callback = function(state)
        local mod = getSkinsMod()
        if mod then
            mod.setAuraEnabled(state)
        end
    end
})

SkinsTab:Button({
    Title = "Reset Character Appearance",
    Desc = "Restores your original character appearance and limb colors",
    Callback = function()
        local mod = getSkinsMod()
        if mod then
            mod.resetCharacterSkin()
            WindUI:Notify({
                Title = "Character Skin",
                Content = "Character restored to original appearance",
                Duration = 2,
                Icon = darlingIcon
            })
        end
    end
})

SkinsTab:Divider()

SkinsTab:Paragraph({
    Title = "Player Skin Cloner",
    Desc = "Clone the avatar appearance, accessories, and clothes of nearby players or by User ID",
    Image = "users"
})

SkinsTab:Button({
    Title = "Clone Nearest Player Skin",
    Desc = "Finds the closest player in the server and clones their avatar appearance",
    Callback = function()
        local mod = getSkinsMod()
        if mod then
            local ok, msg = mod.cloneNearestPlayer()
            WindUI:Notify({
                Title = "Skin Cloner",
                Content = msg or (ok and "Cloned nearest player skin!" or "Failed to clone skin"),
                Duration = 3,
                Icon = darlingIcon
            })
        end
    end
})

local cloneTargetInput = ""
SkinsTab:Input({
    Title = "Target Username or User ID",
    Desc = "Enter Roblox username or numeric User ID to clone",
    Placeholder = "e.g. 12345678 or PlayerName",
    Value = "",
    Callback = function(val)
        cloneTargetInput = val or ""
    end
})

SkinsTab:Button({
    Title = "Clone Player Appearance by ID",
    Desc = "Fetches and applies HumanoidDescription for the specified User ID or Name",
    Callback = function()
        if cloneTargetInput == "" then
            WindUI:Notify({
                Title = "Skin Cloner",
                Content = "Please enter a valid Username or User ID first.",
                Duration = 2.5,
                Icon = darlingIcon
            })
            return
        end
        local mod = getSkinsMod()
        if mod then
            local ok, msg = mod.cloneByUserId(cloneTargetInput)
            WindUI:Notify({
                Title = "Skin Cloner",
                Content = msg or (ok and "Applied target appearance!" or "Failed to load appearance"),
                Duration = 3,
                Icon = darlingIcon
            })
        end
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

local MusicMod = nil
local function getMusicMod()
    if not MusicMod then
        MusicMod = DarlingHub:Require("modules/utility/music_engine.lua")
    end
    return MusicMod
end

local customMusicId = ""
local customMusicName = ""

MusicTab:Paragraph({
    Title = "Cloud DevMP3 Soundtracks",
    Desc = "Permanent bypass audio streamer with custom phonk & montagem tracks",
    Image = "music"
})

MusicTab:Button({
    Title = "Montagem Ceita (d_2fb943edb8ef)",
    Desc = "Plays Montagem Ceita directly in background",
    Callback = function()
        WindUI:Notify({
            Title = "Music Player",
            Content = "Playing Montagem Ceita...",
            Duration = 2.5,
            Icon = darlingIcon
        })
        local mod = getMusicMod()
        if mod then
            mod.playStream("d_2fb943edb8ef", "Montagem Ceita")
        end
    end
})

MusicTab:Button({
    Title = "Montagem Fearless (d_afb0b4b1f348)",
    Desc = "Plays Montagem Fearless directly in background",
    Callback = function()
        WindUI:Notify({
            Title = "Music Player",
            Content = "Playing Montagem Fearless...",
            Duration = 2.5,
            Icon = darlingIcon
        })
        local mod = getMusicMod()
        if mod then
            mod.playStream("d_afb0b4b1f348", "Montagem Fearless")
        end
    end
})

MusicTab:Button({
    Title = "Montagem Topaz (d_def47db76206)",
    Desc = "Plays Montagem Topaz directly in background",
    Callback = function()
        WindUI:Notify({
            Title = "Music Player",
            Content = "Playing Montagem Topaz...",
            Duration = 2.5,
            Icon = darlingIcon
        })
        local mod = getMusicMod()
        if mod then
            mod.playStream("d_def47db76206", "Montagem Topaz")
        end
    end
})

MusicTab:Button({
    Title = "Spooky 3 (d_dbdeeddfb5e1)",
    Desc = "Plays Spooky 3 directly in background",
    Callback = function()
        WindUI:Notify({
            Title = "Music Player",
            Content = "Playing Spooky 3...",
            Duration = 2.5,
            Icon = darlingIcon
        })
        local mod = getMusicMod()
        if mod then
            mod.playStream("d_dbdeeddfb5e1", "Spooky 3")
        end
    end
})

MusicTab:Divider()

MusicTab:Paragraph({
    Title = "Playback Controls",
    Desc = "Master volume, pitch, and playback toggle",
    Image = "play"
})

MusicTab:Button({
    Title = "Pause / Resume",
    Desc = "Toggles playback between pause and resume",
    Callback = function()
        local mod = getMusicMod()
        if mod then
            local isPlaying, msg = mod.pauseResume()
            WindUI:Notify({
                Title = "Music Player",
                Content = msg,
                Duration = 2,
                Icon = darlingIcon
            })
        end
    end
})

MusicTab:Button({
    Title = "Stop Track",
    Desc = "Completely stops audio playback",
    Callback = function()
        local mod = getMusicMod()
        if mod then
            mod.stop()
            WindUI:Notify({
                Title = "Music Player",
                Content = "Playback stopped",
                Duration = 2,
                Icon = darlingIcon
            })
        end
    end
})

MusicTab:Slider({
    Title = "Playback Volume",
    Width = 200,
    Value = {
        Min = 0,
        Max = 100,
        Default = 50,
    },
    Step = 5,
    Callback = function(val)
        local mod = getMusicMod()
        if mod then
            mod.setVolume(val)
        end
    end
})

MusicTab:Dropdown({
    Title = "Playback Speed & Pitch",
    Values = {
        "Slow (0.8x)",
        "Normal (1.0x)",
        "Fast (1.25x)",
        "Nightcore (1.5x)"
    },
    Default = "Normal (1.0x)",
    Callback = function(sel)
        local mod = getMusicMod()
        if mod then
            local speedMap = {
                ["Slow (0.8x)"] = 0.8,
                ["Normal (1.0x)"] = 1.0,
                ["Fast (1.25x)"] = 1.25,
                ["Nightcore (1.5x)"] = 1.5
            }
            local s = speedMap[sel] or 1.0
            mod.setSpeed(s)
            WindUI:Notify({
                Title = "Playback Speed",
                Content = "Speed set to " .. sel,
                Duration = 2,
                Icon = darlingIcon
            })
        end
    end
})

MusicTab:Toggle({
    Title = "Loop Track",
    Desc = "Automatically loops playback when the song ends",
    Value = true,
    Callback = function(state)
        local mod = getMusicMod()
        if mod then
            mod.setLooped(state)
        end
    end
})

MusicTab:Divider()

MusicTab:Paragraph({
    Title = "Custom Sound ID & Favorites",
    Desc = "Enter any numeric Sound ID or file name and save to favorites",
    Image = "bookmark"
})

MusicTab:Input({
    Title = "Custom Sound ID / File",
    Desc = "Numeric Roblox Asset ID or local MP3 file",
    Placeholder = "e.g. 1843588265 or song.mp3",
    Value = "",
    Callback = function(val)
        customMusicId = val or ""
    end
})

MusicTab:Input({
    Title = "Track Name (For Favorites)",
    Desc = "Display name for your custom track",
    Placeholder = "e.g. My Favorite Phonk",
    Value = "",
    Callback = function(val)
        customMusicName = val or ""
    end
})

MusicTab:Button({
    Title = "Play Custom ID",
    Desc = "Plays the entered Sound ID or asset immediately",
    Callback = function()
        if customMusicId == "" then
            WindUI:Notify({
                Title = "Music Player",
                Content = "Please enter a valid Sound ID first.",
                Duration = 2.5,
                Icon = darlingIcon
            })
            return
        end
        local mod = getMusicMod()
        if mod then
            local name = (customMusicName ~= "") and customMusicName or ("Track #" .. customMusicId)
            local ok, msg = mod.play(customMusicId, name)
            WindUI:Notify({
                Title = "Music Player",
                Content = msg or "Playing custom track",
                Duration = 2.5,
                Icon = darlingIcon
            })
        end
    end
})

MusicTab:Button({
    Title = "Save to Favorites",
    Desc = "Saves the entered track to your persistent favorites list",
    Callback = function()
        if customMusicId == "" then
            WindUI:Notify({
                Title = "Favorites",
                Content = "Enter a Sound ID before saving.",
                Duration = 2.5,
                Icon = darlingIcon
            })
            return
        end
        local mod = getMusicMod()
        if mod then
            local name = (customMusicName ~= "") and customMusicName or ("Track #" .. customMusicId)
            local ok, msg = mod.addFavorite(name, customMusicId)
            WindUI:Notify({
                Title = "Favorites",
                Content = msg or "Saved to favorites!",
                Duration = 2.5,
                Icon = darlingIcon
            })
        end
    end
})

MusicTab:Divider()

MusicTab:Paragraph({
    Title = "External Players",
    Desc = "Universal YouTube Player integration",
    Image = "sparkles"
})

MusicTab:Button({
    Title = "Launch Universal YouTube Player",
    Desc = "Opens the external floating YouTube Music Player GUI",
    Callback = function()
        local mod = getMusicMod()
        if mod then
            WindUI:Notify({
                Title = "YouTube Player",
                Content = "Launching Universal YouTube Music Player...",
                Duration = 3,
                Icon = darlingIcon
            })
            mod.launchYoutubePlayer()
        end
    end
})


local currentLanguage = "English"
local Translations
local function tr(key)
    if not Translations then return key end
    local l = Translations[currentLanguage] or Translations["English"]
    return (l and l[key]) or (Translations["English"] and Translations["English"][key]) or key
end

-- ========================================================================
-- 8. SUMMON DRAGON TAB
-- ========================================================================
local SummonDragonTab = Window:Tab({
    Title = "Summon Dragon",
    Icon = "flame"
})
enhanceTabScrolling(SummonDragonTab)

SummonDragonTab:Paragraph({
    Title = "Celestial Titan Dragon",
    Desc = "Summon, ride, and steer the 34-second cinematic Transcendence Titan dragon",
    Image = "flame"
})

SummonDragonTab:Button({
    Title = "Summon Celestial Titan (Transcendence 1000X)",
    Desc = "Triggers the full 34-second cinematic masterpiece cutscene and permanent companion",
    Callback = function()
        local mod = DarlingHub:Require("modules/special/transcendence_dragon.lua")
        if mod then
            WindUI:Notify({
                Title = "Transcendence",
                Content = "Summoning Celestial Titan Dragon...",
                Duration = 4,
                Icon = darlingIcon
            })
            mod.play()
        end
    end
})

SummonDragonTab:Button({
    Title = "Mount / Ride Celestial Dragon",
    Desc = "Mounts the Celestial Titan Dragon with full 3D flight controls (WASD / Mobile thumbstick)",
    Callback = function()
        local mod = DarlingHub:Require("modules/special/transcendence_dragon.lua")
        if mod then
            local ok = mod.mount()
            if ok then
                WindUI:Notify({
                    Title = "Dragon Mount",
                    Content = "Mounted Celestial Dragon! Steer with WASD / Mobile thumbstick.",
                    Duration = 4,
                    Icon = darlingIcon
                })
            else
                WindUI:Notify({
                    Title = "Dragon Mount",
                    Content = "Failed to mount dragon. Summon or spawn it first.",
                    Duration = 4,
                    Icon = darlingIcon
                })
            end
        end
    end
})

SummonDragonTab:Button({
    Title = "Dismount Celestial Dragon",
    Desc = "Safely jumps off the dragon back onto the ground",
    Callback = function()
        local mod = DarlingHub:Require("modules/special/transcendence_dragon.lua")
        if mod then
            mod.dismount()
            WindUI:Notify({
                Title = "Dragon Mount",
                Content = "Dismounted dragon successfully.",
                Duration = 3,
                Icon = darlingIcon
            })
        end
    end
})

SummonDragonTab:Toggle({
    Title = "Hide Dragon Companion",
    Desc = "Hides dragon model, lights, and effects without dismissing",
    Default = false,
    Callback = function(state)
        local mod = DarlingHub:Require("modules/special/transcendence_dragon.lua")
        if mod then
            mod.setHidden(state)
            WindUI:Notify({
                Title = "Celestial Dragon",
                Content = state and "Dragon companion hidden." or "Dragon companion visible.",
                Duration = 2.5,
                Icon = darlingIcon
            })
        end
    end
})

SummonDragonTab:Button({
    Title = "Dismiss Dragon Companion",
    Desc = "Completely removes and despawns the Celestial Titan Dragon",
    Callback = function()
        local mod = DarlingHub:Require("modules/special/transcendence_dragon.lua")
        if mod then
            mod.dismiss()
            WindUI:Notify({
                Title = "Celestial Dragon",
                Content = "Dragon dismissed successfully.",
                Duration = 3,
                Icon = darlingIcon
            })
        end
    end
})

SummonDragonTab:Divider()

-- --- King's Throne (Cosmic Sovereign Chariot & Montagem Topaz) ---
SummonDragonTab:Paragraph({
    Title = "King's Throne",
    Desc = "Summon, mount, and fly the cosmic Sovereign Throne with Montagem Topaz",
    Image = "crown"
})

SummonDragonTab:Button({
    Title = "Mount King's Throne (Cosmic Chariot)",
    Desc = "Spawns and seats you on the King's Throne with 3D flight controls and Montagem Topaz",
    Callback = function()
        local mod = DarlingHub:Require("modules/special/kings_throne.lua")
        if mod then
            local ok = mod.mount()
            if ok then
                WindUI:Notify({
                    Title = tr("KingsThrone"),
                    Content = tr("ThroneMounted"),
                    Duration = 4,
                    Icon = darlingIcon
                })
            else
                WindUI:Notify({
                    Title = tr("KingsThrone"),
                    Content = tr("ThroneMountFailed"),
                    Duration = 3,
                    Icon = "alert-triangle"
                })
            end
        end
    end
})

SummonDragonTab:Button({
    Title = "Dismount King's Throne",
    Desc = "Safely steps down from the King's Throne back onto the ground",
    Callback = function()
        local mod = DarlingHub:Require("modules/special/kings_throne.lua")
        if mod then
            mod.dismount()
            WindUI:Notify({
                Title = tr("KingsThrone"),
                Content = tr("ThroneDismounted"),
                Duration = 3,
                Icon = darlingIcon
            })
        end
    end
})

SummonDragonTab:Button({
    Title = "Dismiss King's Throne",
    Desc = "Completely removes and despawns the King's Throne and stops music",
    Callback = function()
        local mod = DarlingHub:Require("modules/special/kings_throne.lua")
        if mod then
            mod.dismiss()
            WindUI:Notify({
                Title = tr("KingsThrone"),
                Content = tr("ThroneDismissed"),
                Duration = 3,
                Icon = darlingIcon
            })
        end
    end
})

SummonDragonTab:Button({
    Title = "King's Throne Cinematic Arrival",
    Desc = "Spawns the King's Throne with the dramatic Heaven-Splitter ray and Montagem Topaz",
    Callback = function()
        local mod = DarlingHub:Require("modules/special/kings_throne.lua")
        if mod then
            WindUI:Notify({
                Title = tr("KingsThrone"),
                Content = tr("ThroneSummoning"),
                Duration = 4,
                Icon = darlingIcon
            })
            mod.playCinematic()
        end
    end
})

-- ========================================================================
-- 9. PERSONALIZATION TAB
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

local currentSelectedTheme = "Dark"
local ThemeDropdown = nil

ThemeDropdown = PersonalizationTab:Dropdown({
    Title = "UI Color Theme",
    Values = availableThemes,
    Default = "Dark",
    Callback = function(themeName)
        currentSelectedTheme = themeName
        pcall(function()
            WindUI:SetTheme(themeName)
            WindUI:Notify({
                Title = "Theme Updated",
                Content = "Applied: " .. tostring(themeName),
                Duration = 2,
                Icon = "palette"
            })
        end)
        if autoSaveConfig and saveHubConfig then
            saveHubConfig()
        end
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
    Width = 200,
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
    Width = 200,
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
-- 10. SETTINGS TAB (SAVE CONFIG & MULTI-LANGUAGE)
-- ========================================================================
local SupportedLanguages = { "English", "Español", "Français", "Tiếng Việt", "Português" }
currentLanguage = currentLanguage or "English"

Translations = {
    ["English"] = {
        ConfigSaved = "Configuration saved successfully to darling_hub/config.json",
        ConfigLoaded = "Configuration loaded successfully.",
        ConfigReset = "All configurations restored to default.",
        ConfigFailed = "Failed to access configuration file.",
        LanguageChanged = "Interface language set to English.",
        HubLoaded = "Darling Hub loaded successfully.",
        Settings = "Settings",
        SaveConfig = "Save Configuration",
        LoadConfig = "Load Configuration",
        AutoSave = "Auto-Save Configuration",
        Language = "Interface Language",
        KingsThrone = "King's Throne",
        KingsThroneDesc = "Summon, mount, and fly the cosmic Sovereign Throne with Montagem Topaz",
        MountKingsThrone = "Mount King's Throne (Cosmic Chariot)",
        MountKingsThroneDesc = "Spawns and seats you on the King's Throne with 3D flight controls and Montagem Topaz",
        DismountKingsThrone = "Dismount King's Throne",
        DismountKingsThroneDesc = "Safely steps down from the King's Throne back onto the ground",
        DismissKingsThrone = "Dismiss King's Throne",
        DismissKingsThroneDesc = "Completely removes and despawns the King's Throne and stops music",
        KingsThroneCinematic = "King's Throne Cinematic Arrival",
        KingsThroneCinematicDesc = "Spawns the King's Throne with the dramatic Heaven-Splitter ray and Montagem Topaz",
        ThroneMounted = "Mounted King's Throne! Flying with Montagem Topaz.",
        ThroneMountFailed = "Failed to mount King's Throne. Try again.",
        ThroneDismounted = "Dismounted King's Throne successfully.",
        ThroneDismissed = "King's Throne dismissed successfully.",
        ThroneSummoning = "Summoning King's Throne with Heaven-Splitter Ray...",
    },
    ["Español"] = {
        ConfigSaved = "Configuracion guardada correctamente en darling_hub/config.json",
        ConfigLoaded = "Configuracion cargada correctamente.",
        ConfigReset = "Todas las configuraciones restauradas por defecto.",
        ConfigFailed = "Error al acceder al archivo de configuracion.",
        LanguageChanged = "Idioma de la interfaz establecido a Espanol.",
        HubLoaded = "Darling Hub cargado correctamente.",
        Settings = "Ajustes",
        SaveConfig = "Guardar Configuracion",
        LoadConfig = "Cargar Configuracion",
        AutoSave = "Autoguardar Configuracion",
        Language = "Idioma de la interfaz",
        KingsThrone = "Trono del Rey",
        KingsThroneDesc = "Invoca, montate y vuela en el Trono Soberano cosmico con Montagem Topaz",
        MountKingsThrone = "Montar Trono del Rey (Carruaje Cosmico)",
        MountKingsThroneDesc = "Te sienta en el Trono del Rey con controles de vuelo 3D y Montagem Topaz",
        DismountKingsThrone = "Bajarse del Trono del Rey",
        DismountKingsThroneDesc = "Desciende de forma segura del Trono del Rey al suelo",
        DismissKingsThrone = "Quitar Trono del Rey",
        DismissKingsThroneDesc = "Elimina por completo el Trono del Rey y detiene la musica",
        KingsThroneCinematic = "Llegada Cinematica del Trono",
        KingsThroneCinematicDesc = "Invoca el Trono del Rey con el rayo Heaven-Splitter y Montagem Topaz",
        ThroneMounted = "Trono del Rey montado! Volando con Montagem Topaz.",
        ThroneMountFailed = "Error al montar el Trono del Rey. Intentalo de nuevo.",
        ThroneDismounted = "Te has bajado del Trono del Rey correctamente.",
        ThroneDismissed = "Trono del Rey quitado correctamente.",
        ThroneSummoning = "Invocando Trono del Rey con el rayo Heaven-Splitter...",
    },
    ["Français"] = {
        ConfigSaved = "Configuration enregistree avec succes dans darling_hub/config.json",
        ConfigLoaded = "Configuration chargee avec succes.",
        ConfigReset = "Toutes les configurations restaurees par defaut.",
        ConfigFailed = "Echec d'acces au fichier de configuration.",
        LanguageChanged = "Langue de l'interface definie en Francais.",
        HubLoaded = "Darling Hub charge avec succes.",
        Settings = "Parametres",
        SaveConfig = "Enregistrer la configuration",
        LoadConfig = "Charger la configuration",
        AutoSave = "Sauvegarde automatique",
        Language = "Langue de l'interface",
        KingsThrone = "Trone du Roi",
        KingsThroneDesc = "Invoquez, montez et volez sur le Trone Souverain cosmique avec Montagem Topaz",
        MountKingsThrone = "Monter sur le Trone du Roi (Char Cosmique)",
        MountKingsThroneDesc = "Vous installe sur le Trone du Roi avec commandes de vol 3D et Montagem Topaz",
        DismountKingsThrone = "Descendre du Trone du Roi",
        DismountKingsThroneDesc = "Descend en toute securite du Trone du Roi sur le sol",
        DismissKingsThrone = "Renvoyer le Trone du Roi",
        DismissKingsThroneDesc = "Supprime completement le Trone du Roi et arrete la musique",
        KingsThroneCinematic = "Arrivee Cinematique du Trone",
        KingsThroneCinematicDesc = "Invoque le Trone du Roi avec le rayon Heaven-Splitter et Montagem Topaz",
        ThroneMounted = "Monte sur le Trone du Roi! En vol avec Montagem Topaz.",
        ThroneMountFailed = "Impossible de monter sur le Trone du Roi. Reessayez.",
        ThroneDismounted = "Descendu du Trone du Roi avec succes.",
        ThroneDismissed = "Trone du Roi renvoye avec succes.",
        ThroneSummoning = "Invocation du Trone du Roi avec le rayon Heaven-Splitter...",
    },
    ["Tiếng Việt"] = {
        ConfigSaved = "Cau hinh da luu thanh cong vao darling_hub/config.json",
        ConfigLoaded = "Cau hinh da duoc tai thanh cong.",
        ConfigReset = "Tat ca cau hinh da duoc khoi phuc ve mac dinh.",
        ConfigFailed = "Khong the truy cap tep cau hinh.",
        LanguageChanged = "Ngon ngu giao dien da doi sang Tieng Viet.",
        HubLoaded = "Darling Hub da tai thanh cong.",
        Settings = "Cai dat",
        SaveConfig = "Luu cau hinh",
        LoadConfig = "Tai cau hinh",
        AutoSave = "Tu dong luu cau hinh",
        Language = "Ngon ngu giao dien",
        KingsThrone = "Ngoi Bau Cua Vua",
        KingsThroneDesc = "Trieu hoi, ngoi len va bay tren Ngoi Bau Vu Tru cung Montagem Topaz",
        MountKingsThrone = "Ngoi Len Ngoi Bau (Co Xe Vu Tru)",
        MountKingsThroneDesc = "Trieu hoi va dua ban len Ngoi Bau voi he thong bay 3D va Montagem Topaz",
        DismountKingsThrone = "Roi Khoi Ngoi Bau",
        DismountKingsThroneDesc = "Buoc xuong an toan tu Ngoi Bau tro ve mat dat",
        DismissKingsThrone = "Xoa Ngoi Bau",
        DismissKingsThroneDesc = "Xoa hoan toan Ngoi Bau Cua Vua va dung am nhac",
        KingsThroneCinematic = "Trieu Hoi Dien Anh Ngoi Bau",
        KingsThroneCinematicDesc = "Trieu hoi Ngoi Bau cung tia sang Heaven-Splitter va Montagem Topaz",
        ThroneMounted = "Da len Ngoi Bau Cua Vua! Bay cung Montagem Topaz.",
        ThroneMountFailed = "Khong the len Ngoi Bau. Vui long thu lai.",
        ThroneDismounted = "Roi khoi Ngoi Bau thanh cong.",
        ThroneDismissed = "Da xoa Ngoi Bau Cua Vua thanh cong.",
        ThroneSummoning = "Dang trieu hoi Ngoi Bau voi tia Heaven-Splitter...",
    },
    ["Português"] = {
        ConfigSaved = "Configuracao salva com sucesso em darling_hub/config.json",
        ConfigLoaded = "Configuracao carregada com sucesso.",
        ConfigReset = "Todas as configuracoes restauradas para o padrao.",
        ConfigFailed = "Falha ao acessar o arquivo de configuracao.",
        LanguageChanged = "Idioma da interface definido para Portugues.",
        HubLoaded = "Darling Hub carregado com sucesso.",
        Settings = "Configuracoes",
        SaveConfig = "Salvar Configuracao",
        LoadConfig = "Carregar Configuracao",
        AutoSave = "Salvar Automaticamente",
        Language = "Idioma da interface",
        KingsThrone = "Trono do Rei",
        KingsThroneDesc = "Invoque, monte e voe no Trono Soberano cosmico com Montagem Topaz",
        MountKingsThrone = "Montar no Trono do Rei (Carruagem Cosmica)",
        MountKingsThroneDesc = "Coloca voce no Trono do Rei com controles de voo 3D e Montagem Topaz",
        DismountKingsThrone = "Descer do Trono do Rei",
        DismountKingsThroneDesc = "Desce em seguranca do Trono do Rei de volta ao chao",
        DismissKingsThrone = "Remover Trono do Rei",
        DismissKingsThroneDesc = "Remove completamente o Trono do Rei e para a musica",
        KingsThroneCinematic = "Chegada Cinematica do Trono",
        KingsThroneCinematicDesc = "Invoca o Trono do Rei com o raio Heaven-Splitter e Montagem Topaz",
        ThroneMounted = "Montado no Trono do Rei! Voando com Montagem Topaz.",
        ThroneMountFailed = "Falha ao montar no Trono do Rei. Tente novamente.",
        ThroneDismounted = "Desceu do Trono do Rei com sucesso.",
        ThroneDismissed = "Trono do Rei removido com sucesso.",
        ThroneSummoning = "Invocando Trono do Rei com o raio Heaven-Splitter...",
    }
}

local TabTranslations = {
    ["English"] = {
        Home = "Home",
        Aimbot = "Aimbot",
        Players = "Players",
        Pvp = "PVP & Combat",
        Visuals = "Visuals",
        Skins = "Skins Suite",
        Music = "Music Player",
        Dragon = "Summon Dragon",
        Personalization = "Personalization",
        Settings = "Settings",
    },
    ["Español"] = {
        Home = "Inicio",
        Aimbot = "Aimbot",
        Players = "Jugadores",
        Pvp = "PVP y Combate",
        Visuals = "Visuales",
        Skins = "Aspectos",
        Music = "Reproductor",
        Dragon = "Invocar Dragon",
        Personalization = "Personalizar",
        Settings = "Ajustes",
    },
    ["Français"] = {
        Home = "Accueil",
        Aimbot = "Aimbot",
        Players = "Joueurs",
        Pvp = "JcJ et Combat",
        Visuals = "Visuels",
        Skins = "Apparences",
        Music = "Musique",
        Dragon = "Invoquer Dragon",
        Personalization = "Personnalisation",
        Settings = "Parametres",
    },
    ["Tiếng Việt"] = {
        Home = "Trang Chu",
        Aimbot = "Aimbot",
        Players = "Nguoi Choi",
        Pvp = "PVP Chien Dau",
        Visuals = "Hinh Anh",
        Skins = "Giao Dien",
        Music = "Am Nhac",
        Dragon = "Trieu Hoi Rong",
        Personalization = "Tuy Chinh",
        Settings = "Cai Dat",
    },
    ["Português"] = {
        Home = "Inicio",
        Aimbot = "Aimbot",
        Players = "Jogadores",
        Pvp = "PVP e Combate",
        Visuals = "Visuais",
        Skins = "Trajes",
        Music = "Musica",
        Dragon = "Invocar Dragao",
        Personalization = "Personalizacao",
        Settings = "Configuracoes",
    }
}

local function setTabLabel(tab, newTitle)
    if not tab then return end
    tab.Title = newTitle
    pcall(function()
        if tab.UIElements and tab.UIElements.Main then
            for _, desc in ipairs(tab.UIElements.Main:GetDescendants()) do
                if desc:IsA("TextLabel") then
                    desc.Text = newTitle
                    break
                end
            end
        end
    end)
end

local LanguageDropdown = nil

local function applyLanguage(lang)
    if not Translations[lang] then return end
    currentLanguage = lang
    if getgenv then pcall(function() getgenv().DarlingLanguage = lang end) end
    if _G then pcall(function() _G.DarlingLanguage = lang end) end
    local tabTexts = TabTranslations[lang] or TabTranslations["English"]

    setTabLabel(HomeTab, tabTexts.Home)
    setTabLabel(AimbotTab, tabTexts.Aimbot)
    setTabLabel(PlayersTab, tabTexts.Players)
    setTabLabel(PvpTab, tabTexts.Pvp)
    setTabLabel(VisualsTab, tabTexts.Visuals)
    setTabLabel(SkinsTab, tabTexts.Skins)
    setTabLabel(MusicTab, tabTexts.Music)
    setTabLabel(SummonDragonTab, tabTexts.Dragon)
    setTabLabel(PersonalizationTab, tabTexts.Personalization)
    setTabLabel(SettingsTab, tabTexts.Settings)
end

local CONFIG_FOLDER = "darling_hub"
local PRIMARY_CONFIG = "darling_hub/config.json"
local FALLBACK_CONFIG = "darling_config.json"
local autoSaveConfig = true

local function ensureConfigFolder()
    pcall(function()
        if makefolder and isfolder and not isfolder(CONFIG_FOLDER) then
            makefolder(CONFIG_FOLDER)
        end
    end)
end

local function saveHubConfig()
    ensureConfigFolder()
    local cfg = {
        Language = currentLanguage,
        Keybind = currentToggleKey and currentToggleKey.Name or "F",
        AutoSave = autoSaveConfig,
        Theme = currentSelectedTheme or "Dark",
        BackgroundMedia = lastEnteredBackgroundInput or "",
        BackgroundBlur = currentBgBlur or 0,
        BackgroundTransparency = currentBgTransparency or 0.15,
        Skins = {
            SelectedCategory = selectedCategory or "Fruits",
            SelectedPreset = selectedSkinPreset or "Purple",
        }
    }
    pcall(function()
        local sMod = DarlingHub.Modules["modules/visuals/skins_system.lua"]
        if sMod then
            cfg.Skins.VFXEnabled = sMod.VFX and sMod.VFX.Enabled
            cfg.Skins.CharacterSkin = sMod.Character and sMod.Character.ActivePreset
            cfg.Skins.AuraEnabled = sMod.Character and sMod.Character.AuraEnabled
        end
    end)
    pcall(function()
        local mMod = DarlingHub.Modules["modules/utility/music_engine.lua"]
        if mMod and mMod.Favorites then
            cfg.MusicFavorites = mMod.Favorites
        end
    end)

    if writefile then
        local json = HttpService:JSONEncode(cfg)
        local ok, err = pcall(function()
            writefile(PRIMARY_CONFIG, json)
        end)
        if not ok then
            ok, err = pcall(function()
                writefile(FALLBACK_CONFIG, json)
            end)
        end
        return ok, err
    end
    return false, "writefile not supported on this executor"
end

local function loadHubConfig()
    if not (readfile and isfile) then
        return false, "readfile not supported on this executor"
    end

    local candidatePath = nil
    pcall(function()
        if isfile(PRIMARY_CONFIG) then
            candidatePath = PRIMARY_CONFIG
        elseif isfile(FALLBACK_CONFIG) then
            candidatePath = FALLBACK_CONFIG
        end
    end)

    if not candidatePath then
        return false, "No saved config found"
    end

    local ok, data = pcall(function()
        local raw = readfile(candidatePath)
        return HttpService:JSONDecode(raw)
    end)
    if not ok or type(data) ~= "table" then
        return false, "Invalid config data"
    end

    pcall(function()
        if data.Language and Translations[data.Language] then
            applyLanguage(data.Language)
            if LanguageDropdown and LanguageDropdown.Select then
                pcall(function() LanguageDropdown:Select(data.Language) end)
            end
        end
        if data.Keybind and Enum.KeyCode[data.Keybind] then
            currentToggleKey = Enum.KeyCode[data.Keybind]
        end
        if data.AutoSave ~= nil then
            autoSaveConfig = data.AutoSave
        end
        if data.Theme and WindUI then
            currentSelectedTheme = data.Theme
            pcall(function() WindUI:SetTheme(data.Theme) end)
            if ThemeDropdown and ThemeDropdown.Select then
                pcall(function() ThemeDropdown:Select(data.Theme) end)
            end
        end
        if data.BackgroundMedia and data.BackgroundMedia ~= "" then
            lastEnteredBackgroundInput = data.BackgroundMedia
            task.spawn(function()
                processAndApplyMediaInput(data.BackgroundMedia)
            end)
        end
        if data.Skins and type(data.Skins) == "table" then
            if data.Skins.SelectedCategory then
                selectedCategory = data.Skins.SelectedCategory
            end
            if data.Skins.SelectedPreset then
                selectedSkinPreset = data.Skins.SelectedPreset
            end
        end
    end)
    return true, data
end

local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings"
})
enhanceTabScrolling(SettingsTab)

SettingsTab:Paragraph({
    Title = "Configuration & Localization",
    Desc = "Save all settings across sessions and change the interface language",
    Image = "settings"
})

LanguageDropdown = SettingsTab:Dropdown({
    Title = "Interface Language",
    Desc = "Select language: English, Español, Français, Tiếng Việt, Português",
    Values = SupportedLanguages,
    Default = "English",
    Callback = function(lang)
        if Translations[lang] then
            applyLanguage(lang)
            WindUI:Notify({
                Title = tr("Language"),
                Content = tr("LanguageChanged"),
                Duration = 2.5,
                Icon = darlingIcon
            })
            if autoSaveConfig then
                saveHubConfig()
            end
        end
    end
})

SettingsTab:Button({
    Title = "Save Configuration",
    Desc = "Saves all Darling Hub settings, themes, skins, and binds to darling_hub/config.json",
    Callback = function()
        local ok, err = saveHubConfig()
        if ok then
            WindUI:Notify({
                Title = tr("SaveConfig"),
                Content = tr("ConfigSaved"),
                Duration = 3,
                Icon = "check"
            })
        else
            WindUI:Notify({
                Title = tr("SaveConfig"),
                Content = "Failed to save: " .. tostring(err),
                Duration = 3,
                Icon = "alert-triangle"
            })
        end
    end
})

SettingsTab:Button({
    Title = "Load Configuration",
    Desc = "Loads previously saved configuration from disk",
    Callback = function()
        local ok, data = loadHubConfig()
        if ok then
            WindUI:Notify({
                Title = tr("LoadConfig"),
                Content = tr("ConfigLoaded"),
                Duration = 3,
                Icon = "check"
            })
        else
            WindUI:Notify({
                Title = tr("LoadConfig"),
                Content = tostring(data or tr("ConfigFailed")),
                Duration = 3,
                Icon = "alert-triangle"
            })
        end
    end
})

SettingsTab:Toggle({
    Title = "Auto-Save Configuration",
    Desc = "Automatically saves your configuration on changes",
    Value = true,
    Callback = function(state)
        autoSaveConfig = state
        if state then
            saveHubConfig()
        end
    end
})

SettingsTab:Divider()

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
        if autoSaveConfig then
            saveHubConfig()
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
        currentLanguage = "English"
        currentToggleKey = Enum.KeyCode.F
        autoSaveConfig = true
        currentSelectedTheme = "Dark"
        pcall(function() WindUI:SetTheme("Dark") end)
        if ThemeDropdown and ThemeDropdown.Select then
            pcall(function() ThemeDropdown:Select("Dark") end)
        end
        pcall(function()
            if isfile and delfile then
                if isfile(PRIMARY_CONFIG) then delfile(PRIMARY_CONFIG) end
                if isfile(FALLBACK_CONFIG) then delfile(FALLBACK_CONFIG) end
            end
        end)
        applyLanguage("English")
        if LanguageDropdown and LanguageDropdown.Select then
            pcall(function() LanguageDropdown:Select("English") end)
        end
        WindUI:Notify({
            Title = "Settings Reset",
            Content = tr("ConfigReset"),
            Duration = 3,
            Icon = "rotate-ccw"
        })
    end
})

SettingsTab:Divider()

local diagParagraph = SettingsTab:Paragraph({
    Title = "Performance Diagnostics",
    Desc = "Diagnostic mode disabled. Toggle on to view live resource usage.",
})

local function updateDiagnosticsView()
    local totalConns = 0
    local totalThreads = 0
    local loadedCount = 0
    local activeModules = {}

    for path, mod in pairs(DarlingHub.Modules) do
        loadedCount = loadedCount + 1
        if type(mod) == "table" and type(mod.getDiagnostics) == "function" then
            local ok, diag = pcall(mod.getDiagnostics)
            if ok and type(diag) == "table" then
                totalConns = totalConns + (diag.Connections or 0)
                totalThreads = totalThreads + (diag.Threads or 0)
                if diag.Active then
                    table.insert(activeModules, diag.Name or path)
                end
            end
        end
    end

    if DarlingHub.InputBeganConn then
        totalConns = totalConns + 1
    end

    local activeStr = #activeModules > 0 and table.concat(activeModules, ", ") or "None"
    local desc = string.format("Loaded Modules: %d\nActive Modules: %s\nTracked Connections: %d\nActive Background Threads: %d",
        loadedCount, activeStr, totalConns, totalThreads)

    pcall(function()
        if diagParagraph and diagParagraph.SetDesc then
            diagParagraph:SetDesc(desc)
        end
    end)
end

SettingsTab:Toggle({
    Title = "Performance Diagnostics",
    Desc = "Live tracking of active modules, background threads, and connections",
    Value = false,
    Callback = function(state)
        if state then
            if not DarlingHub.DiagnosticThread then
                DarlingHub.DiagnosticThread = task.spawn(function()
                    while true do
                        updateDiagnosticsView()
                        task.wait(1.5)
                    end
                end)
            end
        else
            if DarlingHub.DiagnosticThread then
                pcall(function() task.cancel(DarlingHub.DiagnosticThread) end)
                DarlingHub.DiagnosticThread = nil
            end
            pcall(function()
                if diagParagraph and diagParagraph.SetDesc then
                    diagParagraph:SetDesc("Diagnostic mode disabled. Toggle on to view live resource usage.")
                end
            end)
        end
    end
})

SettingsTab:Divider()

SettingsTab:Button({
    Title = "Unload Darling Hub",
    Desc = "Closes and completely terminates Darling Hub",
    Callback = function()
        if autoSaveConfig then
            saveHubConfig()
        end
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

-- Auto-load saved configuration on startup if available
task.spawn(function()
    task.wait(0.2)
    loadHubConfig()
end)

-- Apply saved background if available
task.spawn(function()
    task.wait(0.5)
    if lastEnteredBackgroundInput and lastEnteredBackgroundInput ~= "" and lastEnteredBackgroundInput ~= "d_d54d5cfd6e07" then
        pcall(function()
            processAndApplyMediaInput(lastEnteredBackgroundInput)
        end)
    end
end)
