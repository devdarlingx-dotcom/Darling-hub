-- fruits_m1

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

_G.FruitsM1Enable = false
_G.FruitsM1DelayValue = 0.15

local FruitsM1 = {
    Enabled = false,
    DelayValue = 0.15,
}

local isAlive = true
local workerThread = nil

local function GetFruitRemote()
    local char = LocalPlayer.Character
    if not char then return nil end

    local fruit = nil

    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") and item:GetAttribute("WeaponType") == "Demon Fruit" then
            fruit = item
            break
        end
    end

    if not fruit then
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            for _, item in ipairs(backpack:GetChildren()) do
                if item:IsA("Tool") and item:GetAttribute("WeaponType") == "Demon Fruit" then
                    fruit = item
                    break
                end
            end
            if fruit then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:EquipTool(fruit)
                    task.wait(0.1)
                    for _, item in ipairs(char:GetChildren()) do
                        if item:IsA("Tool") and item:GetAttribute("WeaponType") == "Demon Fruit" then
                            fruit = item
                            break
                        end
                    end
                end
            end
        end
    end

    if not fruit then return nil end

    local remote = fruit:FindFirstChild("LeftClickRemote")
        or fruit:FindFirstChild("ClickRemote")
        or fruit:FindFirstChild("M1Remote")

    if not remote then
        for _, v in ipairs(fruit:GetChildren()) do
            if v:IsA("RemoteEvent") and v.Name:lower():find("click") then
                remote = v
                break
            end
        end
    end

    return remote
end

FruitsM1.GetFruitRemote = GetFruitRemote

local function ensureWorker()
    if workerThread and coroutine.status(workerThread) ~= "dead" then
        return
    end
    isAlive = true
    workerThread = task.spawn(function()
        while isAlive do
            if _G.FruitsM1Enable or FruitsM1.Enabled then
                local char = LocalPlayer.Character
                local curHRP = char and char:FindFirstChild("HumanoidRootPart")
                local remote = GetFruitRemote()

                if curHRP and remote then
                    local enemiesFolder = Workspace:FindFirstChild("Enemies")
                    if enemiesFolder then
                        for _, npc in ipairs(enemiesFolder:GetChildren()) do
                            if npc.Name ~= "Player" then
                                local targetHRP = npc:FindFirstChild("HumanoidRootPart")
                                local hum = npc:FindFirstChild("Humanoid")

                                if targetHRP and hum and hum.Health > 0 then
                                    if (targetHRP.Position - curHRP.Position).Magnitude < 500 then
                                        pcall(function()
                                            remote:FireServer(Vector3.new(9e30, 9e30, 9e30), 5, false)
                                        end)
                                    end
                                end
                            end
                        end
                    end
                end
            end
            local delayTime = _G.FruitsM1DelayValue or FruitsM1.DelayValue or 0.15
            task.wait(delayTime)
        end
        workerThread = nil
    end)
end

function FruitsM1.enable()
    FruitsM1.Enabled = true
    _G.FruitsM1Enable = true
    ensureWorker()
end

function FruitsM1.disable()
    FruitsM1.Enabled = false
    _G.FruitsM1Enable = false
end

function FruitsM1.toggle()
    if FruitsM1.Enabled or _G.FruitsM1Enable then
        FruitsM1.disable()
    else
        FruitsM1.enable()
    end
    return FruitsM1.Enabled
end

function FruitsM1.setDelay(val)
    local n = tonumber(val)
    if n and n >= 0 then
        FruitsM1.DelayValue = n
        _G.FruitsM1DelayValue = n
    end
end

function FruitsM1.destroy()
    isAlive = false
    FruitsM1.Enabled = false
    _G.FruitsM1Enable = false
    if workerThread then
        pcall(function()
            task.cancel(workerThread)
        end)
        workerThread = nil
    end
end

ensureWorker()

_G.FruitsM1 = FruitsM1

return FruitsM1
