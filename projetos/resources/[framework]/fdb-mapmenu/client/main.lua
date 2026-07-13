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
        
        -- INPUT_FRONTEND_MAP = 0xE31C6B06 (comum no RDR3/RedM)
        -- Desativa o menu de mapa nativo a cada frame
        DisableControlAction(0, 0xE31C6B06, true)
        
        if IsDisabledControlJustReleased(0, 0xE31C6B06) then
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
