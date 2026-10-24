--[[
    Darling Hub - Auto Haki / Auto Buso Module
    Blox Fruits Buso Haki (Armament Haki / Enhancement) Automation.

    Logic (cokeboys pattern):
    - Checks if LocalPlayer owns Buso Haki (Data.Buso or HasBuso attribute).
    - Detects if Buso is currently active via character attribute "HasBuso",
      character child "HasBuso", or Buso body parts.
    - Activates Buso by firing BDI or CommF_("Buso") remote (with VirtualInputManager
      fallback) when unequipped/inactive during combat or normal gameplay.

    Provides:
        - AutoHaki.enable()
        - AutoHaki.disable()
        - AutoHaki.destroy()
        - AutoHaki.toggle()
        - AutoHaki.isEnabled()
        - AutoHaki.hasBuso()
        - AutoHaki.isBusoActive(character)
        - AutoHaki.activateBuso()
        - AutoHaki.setCombatOnly(state)
]]--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local VirtualInputManager = nil
pcall(function()
    VirtualInputManager = game:GetService("VirtualInputManager")
end)

local LocalPlayer = Players.LocalPlayer

local AutoHaki = {
    Enabled = false,
    CombatOnly = false,            -- If true, only activate when holding a tool or in combat
    CheckInterval = 0.4,           -- Polling loop interval in seconds
    Cooldown = 1.0,                -- Cooldown between activation calls to prevent server spam
    LastActivation = 0,
    LoopThread = nil,
    CharAddedConn = nil,
    ChildAddedConn = nil,
    AttributeConn = nil,
}

-- ============================================================================
-- BUSO OWNERSHIP & STATUS DETECTION
-- ============================================================================

-- Checks if player has unlocked/purchased Buso Haki
function AutoHaki.hasBuso()
    if not LocalPlayer then return false end

    -- Check Blox Fruits Data folder
    local data = LocalPlayer:FindFirstChild("Data")
    if data then
        local buso = data:FindFirstChild("Buso")
            or data:FindFirstChild("HasBuso")
            or data:FindFirstChild("BusoHaki")
            or data:FindFirstChild("Enhancement")
        if buso then
            if buso:IsA("BoolValue") then
                return buso.Value
            elseif buso:IsA("NumberValue") or buso:IsA("IntValue") then
                return buso.Value > 0
            end
        end
    end

    -- Check LocalPlayer attributes
    local attr = LocalPlayer:GetAttribute("HasBuso") or LocalPlayer:GetAttribute("Buso")
    if attr ~= nil then
        return attr == true
    end

    -- If Data folder or attribute is not explicitly false, fallback to true so
    -- activation attempts are not blocked when data structures differ across versions
    return true
end

-- Detects if Buso Haki is currently active on the character
function AutoHaki.isBusoActive(character)
    character = character or (LocalPlayer and LocalPlayer.Character)
    if not character then return false end

    -- 1. Check Character Attribute "HasBuso" (Standard modern Blox Fruits flag)
    if character:GetAttribute("HasBuso") == true then
        return true
    end

    -- 2. Check Character Child "HasBuso" (Standard classic Blox Fruits value/object)
    local childHasBuso = character:FindFirstChild("HasBuso")
    if childHasBuso then
        if childHasBuso:IsA("BoolValue") then
            return childHasBuso.Value
        end
        return true
    end

    -- 3. Check for Buso aura parts or folder
    if character:FindFirstChild("Buso") then
        return true
    end

    return false
end

-- ============================================================================
-- REMOTE RESOLUTION & ACTIVATION
-- ============================================================================

local function resolveRemotes()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local bdi = nil
    local commF = nil

    if remotes then
        bdi = remotes:FindFirstChild("BDI")
        commF = remotes:FindFirstChild("CommF_")
    end

    if not bdi then
        bdi = ReplicatedStorage:FindFirstChild("BDI")
    end
    if not commF then
        commF = ReplicatedStorage:FindFirstChild("CommF_")
    end

    return bdi, commF
end

-- Fires BDI, CommF_("Buso"), or simulates KeyCode.J to activate Buso
function AutoHaki.activateBuso()
    local now = os.clock()
    if now - AutoHaki.LastActivation < AutoHaki.Cooldown then
        return false
    end
    AutoHaki.LastActivation = now

    local triggered = false
    local bdi, commF = resolveRemotes()

    -- 1. Try BDI remote
    if bdi then
        pcall(function()
            if bdi:IsA("RemoteFunction") then
                bdi:InvokeServer("Buso")
                triggered = true
            elseif bdi:IsA("RemoteEvent") then
                bdi:FireServer("Buso")
                triggered = true
            end
        end)
    end

    -- 2. Try CommF_ remote ("Buso")
    if commF and commF:IsA("RemoteFunction") then
        pcall(function()
            commF:InvokeServer("Buso")
            triggered = true
        end)
    end

    -- 3. Fallback: VirtualInputManager KeyCode.J
    if not triggered and VirtualInputManager then
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.J, false, game)
            task.delay(0.05, function()
                pcall(function()
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.J, false, game)
                end)
            end)
            triggered = true
        end)
    end

    return triggered
end

-- ============================================================================
-- CONDITIONAL CHECK & BINDINGS
-- ============================================================================

local function shouldActivate()
    if not AutoHaki.Enabled then return false end
    if not LocalPlayer then return false end

    local char = LocalPlayer.Character
    if not char then return false end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end

    -- Verify player ownership
    if not AutoHaki.hasBuso() then return false end

    -- Verify if already active
    if AutoHaki.isBusoActive(char) then return false end

    -- If CombatOnly is enabled, check if a weapon is equipped or player is in combat
    if AutoHaki.CombatOnly then
        local hasTool = char:FindFirstChildOfClass("Tool") ~= nil
        local inCombat = char:GetAttribute("InCombat") == true
            or char:GetAttribute("Busy") == true
            or char:FindFirstChild("InCombat") ~= nil
        if not (hasTool or inCombat) then
            return false
        end
    end

    return true
end

local function checkAndActivate()
    if shouldActivate() then
        AutoHaki.activateBuso()
    end
end

local function bindCharacter(char)
    if not char then return end

    if AutoHaki.ChildAddedConn then
        pcall(function() AutoHaki.ChildAddedConn:Disconnect() end)
        AutoHaki.ChildAddedConn = nil
    end
    if AutoHaki.AttributeConn then
        pcall(function() AutoHaki.AttributeConn:Disconnect() end)
        AutoHaki.AttributeConn = nil
    end

    -- When a tool is equipped, reactivate Buso if unequipped/inactive
    AutoHaki.ChildAddedConn = char.ChildAdded:Connect(function(child)
        if not AutoHaki.Enabled then return end
        if child:IsA("Tool") then
            task.wait(0.1)
            checkAndActivate()
        end
    end)

    -- When "HasBuso" attribute drops or changes to false, reactivate
    AutoHaki.AttributeConn = char:GetAttributeChangedSignal("HasBuso"):Connect(function()
        if not AutoHaki.Enabled then return end
        if char:GetAttribute("HasBuso") ~= true then
            task.wait(0.1)
            checkAndActivate()
        end
    end)

    task.defer(checkAndActivate)
end

-- ============================================================================
-- PUBLIC LIFECYCLE API
-- ============================================================================

function AutoHaki.enable()
    if AutoHaki.Enabled then return true end
    AutoHaki.Enabled = true

    -- Bind currently active character
    if LocalPlayer and LocalPlayer.Character then
        bindCharacter(LocalPlayer.Character)
    end

    -- Bind future character spawns
    if LocalPlayer and not AutoHaki.CharAddedConn then
        AutoHaki.CharAddedConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
            if not AutoHaki.Enabled then return end
            -- Wait for humanoid to exist
            newChar:WaitForChild("Humanoid", 5)
            task.wait(0.5)
            bindCharacter(newChar)
        end)
    end

    -- Background polling loop
    if not AutoHaki.LoopThread then
        AutoHaki.LoopThread = task.spawn(function()
            while AutoHaki.Enabled do
                task.wait(AutoHaki.CheckInterval)
                pcall(checkAndActivate)
            end
            AutoHaki.LoopThread = nil
        end)
    end

    task.defer(checkAndActivate)
    return true
end

function AutoHaki.disable()
    AutoHaki.Enabled = false

    if AutoHaki.CharAddedConn then
        pcall(function() AutoHaki.CharAddedConn:Disconnect() end)
        AutoHaki.CharAddedConn = nil
    end
    if AutoHaki.ChildAddedConn then
        pcall(function() AutoHaki.ChildAddedConn:Disconnect() end)
        AutoHaki.ChildAddedConn = nil
    end
    if AutoHaki.AttributeConn then
        pcall(function() AutoHaki.AttributeConn:Disconnect() end)
        AutoHaki.AttributeConn = nil
    end

    AutoHaki.LoopThread = nil
end

function AutoHaki.destroy()
    AutoHaki.disable()
    AutoHaki.LastActivation = 0
    AutoHaki.CombatOnly = false
end

function AutoHaki.toggle(state)
    if state == nil then
        state = not AutoHaki.Enabled
    end
    if state then
        AutoHaki.enable()
    else
        AutoHaki.disable()
    end
    return AutoHaki.Enabled
end

function AutoHaki.isEnabled()
    return AutoHaki.Enabled
end

function AutoHaki.setCombatOnly(state)
    AutoHaki.CombatOnly = (state == true)
end

return AutoHaki
