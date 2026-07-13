local RSGCore = exports['rsg-core']:GetCoreObject()
local isMapOpen = false

-- -------------------------------------------------------
-- Helpers
-- -------------------------------------------------------
local function SetMapActive(active)
    isMapOpen = active
    SetNuiFocus(active, active)
    
    if active then
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        -- Envia a posicao fixa de abertura do jogador para a NUI
        SendNUIMessage({
            action = "openMap",
            coords = { x = coords.x, y = coords.y }
        })
    else
        SendNUIMessage({
            action = "closeMap"
        })
    end
end


-- -------------------------------------------------------
-- Callbacks NUI
-- -------------------------------------------------------
RegisterNUICallback('closeMap', function(_, cb)
    SetMapActive(false)
    cb('ok')
end)
