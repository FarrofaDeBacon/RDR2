local RSGCore = exports['rsg-core']:GetCoreObject()
local isMapOpen = false

-- -------------------------------------------------------
-- Helpers
-- -------------------------------------------------------
local function SetMapActive(active, playerMarkers)
    isMapOpen = active
    SetNuiFocus(active, active)
    
    local ped = PlayerPedId()
    if active then
        local coords = GetEntityCoords(ped)
        -- Tocar animação de ler papel
        TaskStartScenarioInPlace(ped, GetHashKey("WORLD_HUMAN_WRITE_NOTEBOOK"), -1, true)
        
        SendNUIMessage({
            action = "openMap",
            coords = { x = coords.x, y = coords.y },
            markers = playerMarkers or {}
        })
    else
        SendNUIMessage({
            action = "closeMap"
        })
        ClearPedTasks(ped)
    end
end

-- -------------------------------------------------------
-- Eventos do Cliente
-- -------------------------------------------------------
RegisterNetEvent('fdb-mapmenu:client:openMap', function()
    if not isMapOpen then
        local playerMarkers = lib.callback.await('fdb-mapmenu:server:getMarkers', false)
        SetMapActive(true, playerMarkers)
    end
end)

-- -------------------------------------------------------
-- Callbacks NUI
-- -------------------------------------------------------
RegisterNUICallback('closeMap', function(_, cb)
    SetMapActive(false)
    cb('ok')
end)

RegisterNUICallback('addMarker', function(data, cb)
    TriggerServerEvent('fdb-mapmenu:server:addMarker', data.x, data.y, data.label)
    cb('ok')
end)

RegisterNUICallback('removeMarker', function(data, cb)
    TriggerServerEvent('fdb-mapmenu:server:removeMarker', data.index)
    cb('ok')
end)
