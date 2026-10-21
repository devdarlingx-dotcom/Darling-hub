--[[
    Darling Hub - Official Universal Loader
    Supports remote raw execution with local fallback for testing.
]]--

local remoteUrl = "https://raw.githubusercontent.com/devdarlingx-dotcom/Darling-hub/main/main.lua"
local localPath = "darling-hub/main.lua"

local function fetchScript()
    if isfile and isfile(localPath) then
        return readfile(localPath)
    end
    local requestFn = (syn and syn.request) or http_request or request
    if requestFn then
        local ok, res = pcall(requestFn, { Url = remoteUrl, Method = "GET" })
        if ok and res and (res.StatusCode == 200 or res.Status == 200) and #res.Body > 0 then
            return res.Body
        end
    end
    return game:HttpGet(remoteUrl, true)
end

local content = fetchScript()
if content and #content > 0 then
    local fn, err = loadstring(content)
    if fn then
        fn()
    else
        warn("[Darling Hub Loader] Compilation error: " .. tostring(err))
    end
else
    warn("[Darling Hub Loader] Failed to fetch main script.")
end
