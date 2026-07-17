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

CreateThread(function()
    while true do
        Wait(500)
        if Config.Minimap.enabled and hasMapItem and isMapEquipped then
            DisplayRadar(true)
            Citizen.InvokeNative(0xDE1A30F38D0DEE5C, true)
            SetMinimapType(1)
        else
            DisplayRadar(false)
            Citizen.InvokeNative(0xDE1A30F38D0DEE5C, false)
            SetMinimapType(0)
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
    end
end)

RegisterCommand('testradar', function(source, args)
    local mode = tonumber(args[1]) or 0
    print("TESTANDO MINIMAP TYPE:", mode)
    SetMinimapType(mode)
    
    if mode == 1 then
        Citizen.InvokeNative(0xDE1A30F38D0DEE5C, true)
    else
        Citizen.InvokeNative(0xDE1A30F38D0DEE5C, false)
    end
end)

RegisterCommand('testcompass', function()
    print("Escondendo HUD_CTX_COMPASS e hud component 15...")
    Citizen.InvokeNative(0x4CC5F2FC1332577F, GetHashKey("HUD_CTX_COMPASS"))
end)
