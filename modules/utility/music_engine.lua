-- music engine
local DarlingMusic = {}
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

DarlingMusic.SoundInstance = nil
DarlingMusic.CurrentTrackName = "None"
DarlingMusic.CurrentTrackId = ""
DarlingMusic.Volume = 0.5
DarlingMusic.PlaybackSpeed = 1.0
DarlingMusic.Looped = true

DarlingMusic.PresetTracks = {
    { Name = "phonk", Id = "1843588265", File = "MONTAGEM BAILÃO.mp3" },
    { Name = "Darling Theme - Lo-Fi Chill", Id = "90089940136467" },
    { Name = "Anime Vibes - Aesthetic Chill", Id = "6825487739" },
    { Name = "Synthwave Night Drive", Id = "7024220379" },
    { Name = "Combat Anthem", Id = "1843588265" }
}

DarlingMusic.Favorites = {}
local FAVORITES_FILE = "darling_hub/favorites.json"

-- sound instance helper
function DarlingMusic.getSound()
    if DarlingMusic.SoundInstance and DarlingMusic.SoundInstance.Parent then
        return DarlingMusic.SoundInstance
    end
    local existing = SoundService:FindFirstChild("DarlingMusicPlayer")
    if existing and existing:IsA("Sound") then
        DarlingMusic.SoundInstance = existing
        return existing
    end
    local snd = Instance.new("Sound")
    snd.Name = "DarlingMusicPlayer"
    snd.Volume = DarlingMusic.Volume
    snd.PlaybackSpeed = DarlingMusic.PlaybackSpeed
    snd.Looped = DarlingMusic.Looped
    snd.Parent = SoundService
    DarlingMusic.SoundInstance = snd
    return snd
end

-- resolve sound asset or executor file bypass
local function resolveSoundSource(identifier)
    if not identifier or identifier == "" then return nil end
    local str = tostring(identifier)

    -- check custom asset bypass
    if type(isfile) == "function" and type(getcustomasset) == "function" then
        local candidates = {
            str,
            "darling_hub/" .. str,
            str .. ".mp3",
            "darling_hub/" .. str .. ".mp3"
        }
        for _, path in ipairs(candidates) do
            local okCheck, exists = pcall(function() return isfile(path) end)
            if okCheck and exists then
                local okAsset, asset = pcall(function() return getcustomasset(path) end)
                if okAsset and asset then
                    return asset
                end
            end
        end
    end

    if str:find("rbxassetid://") or str:find("rbxasset://") or str:find("http://") or str:find("https://") then
        return str
    end

    local clean = str:gsub("%D+", "")
    if clean ~= "" then
        return "rbxassetid://" .. clean
    end

    return str
end

-- play track
function DarlingMusic.play(trackInput, trackName)
    local source = resolveSoundSource(trackInput)
    if not source or source == "" then
        return false, "Invalid sound source or asset ID"
    end

    local snd = DarlingMusic.getSound()
    pcall(function() snd:Stop() end)
    snd.SoundId = source
    snd.Volume = DarlingMusic.Volume
    snd.PlaybackSpeed = DarlingMusic.PlaybackSpeed
    snd.Looped = DarlingMusic.Looped
    pcall(function() snd:Play() end)

    DarlingMusic.CurrentTrackName = trackName or tostring(trackInput)
    DarlingMusic.CurrentTrackId = tostring(trackInput)
    return true, "Now playing: " .. DarlingMusic.CurrentTrackName
end

-- pause or resume
function DarlingMusic.pauseResume()
    local snd = DarlingMusic.getSound()
    if snd.IsPlaying then
        pcall(function() snd:Pause() end)
        return false, "Playback paused"
    else
        pcall(function() snd:Resume() end)
        return true, "Playback resumed"
    end
end

-- stop track
function DarlingMusic.stop()
    local snd = DarlingMusic.getSound()
    pcall(function() snd:Stop() end)
    DarlingMusic.CurrentTrackName = "None"
    return true, "Playback stopped"
end

-- volume control
function DarlingMusic.setVolume(volPercent)
    local v = math.clamp(tonumber(volPercent or 50) / 100, 0, 1)
    DarlingMusic.Volume = v
    local snd = DarlingMusic.getSound()
    snd.Volume = v
end

-- playback speed and pitch
function DarlingMusic.setSpeed(speedVal)
    local s = tonumber(speedVal) or 1.0
    DarlingMusic.PlaybackSpeed = s
    local snd = DarlingMusic.getSound()
    snd.PlaybackSpeed = s
end

-- loop audio
function DarlingMusic.setLooped(looped)
    DarlingMusic.Looped = (looped == true)
    local snd = DarlingMusic.getSound()
    snd.Looped = DarlingMusic.Looped
end

-- favorites persistence
function DarlingMusic.loadFavorites()
    DarlingMusic.Favorites = {}
    if type(isfile) == "function" and type(readfile) == "function" then
        local ok, exists = pcall(function() return isfile(FAVORITES_FILE) end)
        if ok and exists then
            pcall(function()
                local content = readfile(FAVORITES_FILE)
                local data = HttpService:JSONDecode(content)
                if type(data) == "table" then
                    for _, item in ipairs(data) do
                        if item.Name and item.Id then
                            table.insert(DarlingMusic.Favorites, {
                                Name = tostring(item.Name),
                                Id = tostring(item.Id)
                            })
                        end
                    end
                end
            end)
        end
    end
    return DarlingMusic.Favorites
end

function DarlingMusic.saveFavorites()
    if type(writefile) == "function" and type(makefolder) == "function" then
        pcall(function()
            makefolder("darling_hub")
            local raw = HttpService:JSONEncode(DarlingMusic.Favorites)
            writefile(FAVORITES_FILE, raw)
        end)
    end
end

function DarlingMusic.addFavorite(name, id)
    if not id or id == "" then return false, "Invalid ID" end
    local cleanName = (name and name ~= "") and name or ("Track #" .. tostring(id))
    for _, item in ipairs(DarlingMusic.Favorites) do
        if item.Id == tostring(id) then
            item.Name = cleanName
            DarlingMusic.saveFavorites()
            return true, "Updated favorite: " .. cleanName
        end
    end
    table.insert(DarlingMusic.Favorites, { Name = cleanName, Id = tostring(id) })
    DarlingMusic.saveFavorites()
    return true, "Saved to favorites: " .. cleanName
end

function DarlingMusic.removeFavorite(id)
    for i, item in ipairs(DarlingMusic.Favorites) do
        if item.Id == tostring(id) or item.Name == tostring(id) then
            table.remove(DarlingMusic.Favorites, i)
            DarlingMusic.saveFavorites()
            return true, "Removed from favorites"
        end
    end
    return false, "Track not found in favorites"
end

-- launch universal youtube player
function DarlingMusic.launchYoutubePlayer()
    return pcall(function()
        loadstring(game:HttpGet(('https://raw.githubusercontent.com/Dan41/Roblox-Scripts/refs/heads/main/Youtube%20Music%20Player/YoutubeMusicPlayer.lua'), true))()
    end)
end

-- play stream directly without opening external GUI
function DarlingMusic.playStream(trackId, title)
    title = title or ("Track #" .. tostring(trackId))
    local BASE_URL = "https://darling-media-api.onrender.com"
    local READ_KEY = "darling_secret_key"
    local fname = "devmp3_" .. tostring(trackId) .. ".mp3"

    local exIsFile = isfile or is_file
    local exWriteFile = writefile
    local exGetCustomAsset = getcustomasset

    task.spawn(function()
        if type(exIsFile) == "function" and type(exWriteFile) == "function" and not exIsFile(fname) then
            local url = BASE_URL .. "/stream/" .. tostring(trackId) .. "?k=" .. READ_KEY
            local ok, data = pcall(function() return game:HttpGet(url) end)
            if ok and data and #data > 0 then
                pcall(exWriteFile, fname, data)
            end
        end

        if type(exGetCustomAsset) == "function" and type(exIsFile) == "function" and exIsFile(fname) then
            local okAsset, asset = pcall(exGetCustomAsset, fname)
            if okAsset and asset then
                DarlingMusic.play(asset, title)
                return
            end
        end

        -- Direct fallback
        DarlingMusic.play(BASE_URL .. "/stream/" .. tostring(trackId) .. "?k=" .. READ_KEY, title)
    end)
    return true, "Buffering: " .. title
end

-- launch devmp3 bypass loader
function DarlingMusic.launchDevMp3()
    return pcall(function()
        loadstring(game:HttpGet("https://darling-media-api.onrender.com/scripts/devmp3.lua"))()
    end)
end

-- initialize favorites
pcall(function() DarlingMusic.loadFavorites() end)

return DarlingMusic
