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
        
        -- Desativa o menu de mapa nativo e a tecla M (INPUT_FRONTEND_MAP e INPUT_MAP)
        DisableControlAction(0, 0xE31C6B06, true) -- INPUT_FRONTEND_MAP
        DisableControlAction(0, 0x3B3A5A2B, true) -- INPUT_MAP
        
        -- Trava a ativacao do menu de pausa nativo/mapa nativo
        SetPauseMenuActive(false)
        
        -- Se o jogo por algum motivo abrir o menu de pausa nativo, força fechar
        if IsPauseMenuActive() then
            SetFrontendActive(false)
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
