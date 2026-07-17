-- ============================================================
-- fdb-hud | client/minimap.lua
-- Controle do minimapa via Config.Minimap.enabled + posse + equipado
-- ============================================================

local hasMapItem = not Config.Minimap.requireItem
local isMapEquipped = false

RegisterNetEvent('fdb-hud:client:itemGatedUpdate', function(data)
    hasMapItem = data.map
end)

RegisterNetEvent('fdb-hud:client:equipUpdate', function(data)
    if data.map ~= nil then
        isMapEquipped = data.map
    end
end)

RegisterNetEvent('fdb-hud:client:openMapMenu', function()
    lib.registerContext({
        id = 'map_action_menu',
        title = 'Ações do Mapa',
        options = {
            {
                title = 'Visualizar Mapa',
                description = 'Abre o mapa gigante nativo.',
                icon = 'map',
                onSelect = function()
                    ActivateFrontendMenu(joaat("MAP"), false, 1)
                end
            },
            {
                title = isMapEquipped and 'Guardar Minimapa' or 'Equipar Minimapa',
                description = 'Liga ou desliga a bússola/radar na sua tela.',
                icon = isMapEquipped and 'eye-slash' or 'eye',
                onSelect = function()
                    TriggerServerEvent('fdb-hud:server:toggleMinimap')
                end
            },
            {
                title = 'Mapa de Anotações',
                description = 'Abre o mapa de papel customizado.',
                icon = 'pen',
                onSelect = function()
                    TriggerEvent('fdb-mapmenu:client:OpenMapMenu')
                end
            }
        }
    })
    lib.showContext('map_action_menu')
end)

local isRadarEnabled = false
local maskVisible = false

local function UpdateRadarState()
    if Config.Minimap.enabled and hasMapItem and isMapEquipped then
        if not isRadarEnabled then
            isRadarEnabled = true
            DisplayRadar(true)
            Citizen.InvokeNative(0xDE1A30F38D0DEE5C, true)
            local minimapType = Config.Minimap.type or 1
            SetMinimapType(minimapType)
        end
    else
        if isRadarEnabled then
            isRadarEnabled = false
            DisplayRadar(false)
            Citizen.InvokeNative(0xDE1A30F38D0DEE5C, false)
            SetMinimapType(0)
        end
    end
end

CreateThread(function()
    while true do
        Wait(200)
        
        -- Garante que o radar nativo está no estado correto
        UpdateRadarState()
        
        -- Controla a visibilidade da máscara dourada (Svelte)
        local shouldShowMask = false
        if isRadarEnabled then
            shouldShowMask = true
            
            -- Esconde a máscara se estiver no pause menu (ESC), tela preta, etc.
            if IsPauseMenuActive() or IsScreenFadedOut() then
                shouldShowMask = false
            end
            
            -- Esconde a máscara no MAPA GRANDE (M)
            if IsAppActive(joaat("MAP")) == 1 then
                shouldShowMask = false
            end
            
            -- Esconde a máscara se qualquer NUI estiver aberto (ex: Inventário, Lojas), exceto se estivermos editando o HUD
            if IsNuiFocused() and not InEditMode then
                shouldShowMask = false
            end
            
            -- Se o radar nativo foi ocultado por outro script nativo
            if IsHudHidden() then
                shouldShowMask = false
            end
        end
        
        if maskVisible ~= shouldShowMask then
            maskVisible = shouldShowMask
            SendNUIMessage({ action = 'updateMinimap', data = { visible = shouldShowMask } })
        end
    end
end)

-- Loop de checagem de estado molhado (2s)
CreateThread(function()
    while true do
        Wait(2000)
        if isLoggedIn and isMapEquipped then
            local ped = PlayerPedId()
            local isSwimming = IsPedSwimming(ped)
            local isRaining = GetRainLevel() > 0.3
            if isSwimming or isRaining then
                TriggerServerEvent('fdb-hud:server:checkWet', isSwimming, isRaining)
            end
        end
    end
end)


