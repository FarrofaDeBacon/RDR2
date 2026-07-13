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

-- Loop de controle de exibição do minimapa
CreateThread(function()
    while true do
        Wait(500)
        if Config.Minimap.enabled and hasMapItem and isMapEquipped then
            SetMinimapType(1) -- Ativa o minimapa circular
            -- Oculta todas as marcas cardinais (N, S, E, W), angulos e a bussola da borda do radar nativo
            Citizen.InvokeNative(0x7E16D1905E59013F, false)
            Citizen.InvokeNative(0x9E2D87B40A5B4C98, false)
            Citizen.InvokeNative(0xE05190B11E73850F, false)
            Citizen.InvokeNative(0x5B53775A884C0F73, false)
            Citizen.InvokeNative(0x4AD55A03FF264104, false) -- Oculta especificamente compass markers
            Citizen.InvokeNative(0x1B86D49132E6A020, false) -- Remove o anel de direcoes
            
            -- Desativa o HUD component compass de forma direta no RDR3
            Citizen.InvokeNative(0x506540306EB30292, 0x63E72166B0D5B574, false) -- Oculta componente da bussola
            Citizen.InvokeNative(0x4CC5F2CE8BE63825, 20, false) -- Oculta componente HUD_COMPASS
        else
            SetMinimapType(0) -- Oculta o minimapa completamente
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
