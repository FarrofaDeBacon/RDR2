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

-- Loop de controle de exibição do minimapa e ocultação das direções a cada frame
CreateThread(function()
    while true do
        if Config.Minimap.enabled and hasMapItem and isMapEquipped then
            SetMinimapType(1) -- Ativa o minimapa circular
            
            -- Oculta os cardinais nativos da borda do radar rodando continuamente (Wait(0))
            Citizen.InvokeNative(0xF80671CB9B7B280F, false) -- Remove a rosa dos ventos
            Citizen.InvokeNative(0x4AD55A03FF264104, false) -- Esconde as marcas cardinais da borda
            Citizen.InvokeNative(0x1B86D49132E6A020, false) -- Remove direções adicionais
            Wait(0)
        else
            SetMinimapType(0) -- Oculta o minimapa completamente
            Wait(500)
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
