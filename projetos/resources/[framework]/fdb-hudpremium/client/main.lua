local KVP_KEY = "fdb-hudpremium:settings"

-- Load Settings from KVP and send to NUI
local function LoadSettings()
    local savedSettings = GetResourceKvpString(KVP_KEY)
    if savedSettings then
        local decoded = json.decode(savedSettings)
        if decoded then
            SendNUIMessage({
                action = "loadSettings",
                settings = decoded
            })
            print("[fdb-hudpremium] Settings loaded.")
        end
    end
end

-- Wait for UI to be ready, this might be triggered by the UI if we add it, but for now we also load on start
RegisterNUICallback("uiReady", function(data, cb)
    LoadSettings()
    cb("ok")
end)

-- Callback to save settings
RegisterNUICallback("saveSettings", function(data, cb)
    if data then
        local encoded = json.encode(data)
        SetResourceKvp(KVP_KEY, encoded)
        print("[fdb-hudpremium] Settings saved successfully.")
    end
    cb("ok")
end)

-- Callback to close editor
RegisterNUICallback("closeEditor", function(data, cb)
    SetNuiFocus(false, false)
    cb("ok")
end)

-- Optional: Initial load on resource start
AddEventHandler("onResourceStart", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        LoadSettings()
    end
end)

-- Command to open the HUD Editor for testing
RegisterCommand("hud", function()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openEditor"
    })
end, false)
