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
            SetMinimapType(0) -- mapa circular sem as direcoes cardinais na borda
        else
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
end)
