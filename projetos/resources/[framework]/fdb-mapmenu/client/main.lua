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

-- -------------------------------------------------------
-- Thread de Interceptação da Tecla M (INPUT_MAP)
-- -------------------------------------------------------
CreateThread(function()
    while true do
        Wait(0)
        DisableControlAction(0, 0xE31C6A41, true) -- INPUT_MAP (M)

        if IsDisabledControlJustReleased(0, 0xE31C6A41) then
            if not isMapOpen then
                -- Verifica posse do mapa no servidor
                local hasMap = lib.callback.await('fdb-mapmenu:server:hasMapItem', false)
                if hasMap then
                    local playerMarkers = lib.callback.await('fdb-mapmenu:server:getMarkers', false)
                    SetMapActive(true, playerMarkers)
                else
                    lib.notify({ title = 'Você precisa equipar um mapa para ver isso', type = 'error' })
                end
            end
        end

        if isMapOpen then
            DisableControlAction(0, 0x3C0A40F2, true) -- ESC pra fechar
            
            -- Desativa o controle de rotação de câmera do mouse do jogo para evitar roubo de foco do drag no NUI
            DisableControlAction(0, 0x3900BA13, true) -- INPUT_LOOK_LR (Olhar Lados)
            DisableControlAction(0, 0x0877C683, true) -- INPUT_LOOK_UD (Olhar Cima/Baixo)
            
            -- Desativa o scroll de trocar de arma do jogo para liberar o wheel zoom no CEF
            DisableControlAction(0, 0xCC14EB5C, true) -- INPUT_WEAPON_WHEEL_NEXT
            DisableControlAction(0, 0x307E4424, true) -- INPUT_WEAPON_WHEEL_PREV

            if IsDisabledControlJustReleased(0, 0x3C0A40F2) then
                SetMapActive(false)
            end
        end
    end
end)
