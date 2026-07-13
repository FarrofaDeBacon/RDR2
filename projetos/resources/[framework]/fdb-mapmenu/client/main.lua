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
-- Thread de Interceptacao de Tecla / Pause Map
-- -------------------------------------------------------
CreateThread(function()
    while true do
        Wait(0)
        
        -- Desativa agressivamente o menu de mapa nativo e tecla M (INPUT_FRONTEND_MAP, INPUT_MAP e PAUSE)
        DisableControlAction(0, 0xE31C6B06, true) -- INPUT_FRONTEND_MAP
        DisableControlAction(0, 0x3B3A5A2B, true) -- INPUT_MAP
        DisableControlAction(0, 0x4AD55A03FF264104, true) -- INPUT_PAUSE_MENU
        DisableControlAction(0, 0xD2616428, true) -- INPUT_FRONTEND_PAUSE
        DisableControlAction(0, 0x0FDF7156, true) -- INPUT_FRONTEND_PAUSE_ALTERNATE
        
        -- Se o menu de pausa nativo abrir, força o fechamento imediato no mesmo frame
        if IsPauseMenuActive() or IsPauseMenuRestarting() then
            SetFrontendActive(false)
        end
        
        -- Fecha a UIApp nativa de mapa e pausa do RedM imediatamente caso tentem abrir
        if Citizen.InvokeNative(0x25B7A0206BDFAC76, `map`) then
            Citizen.InvokeNative(0x2FF10C9C3F92277E, `map`)
        end
        if Citizen.InvokeNative(0x25B7A0206BDFAC76, `pause_menu`) then
            Citizen.InvokeNative(0x2FF10C9C3F92277E, `pause_menu`)
        end
        if Citizen.InvokeNative(0x25B7A0206BDFAC76, `map_menu`) then
            Citizen.InvokeNative(0x2FF10C9C3F92277E, `map_menu`)
        end
        
        if IsDisabledControlJustReleased(0, 0xE31C6B06) or IsDisabledControlJustReleased(0, 0x3B3A5A2B) then
            if not isMapOpen then
                SetMapActive(true)
            end
        end
        
        -- Se o mapa ja estiver aberto, permite fechar usando ESC / BACKSPACE
        if isMapOpen then
            DisableControlAction(0, 0x3C0A40F2, true) -- INPUT_CELLPHONE_CANCEL (ESC)
            if IsDisabledControlJustReleased(0, 0x3C0A40F2) then
                SetMapActive(false)
            end
        end
    end
end)

-- -------------------------------------------------------
-- Callbacks NUI
-- -------------------------------------------------------
RegisterNUICallback('closeMap', function(_, cb)
    SetMapActive(false)
    cb('ok')
end)
