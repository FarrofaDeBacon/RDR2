-- ============================================================
-- fdb-hud | client/minimap.lua
-- Controle do minimapa via Config.Minimap.enabled + posse de item
-- Leitura EXCLUSIVA de Config.Minimap - nunca exposto via
-- callback, evento ou export ao client/NUI.
-- ============================================================

local hasMapItem = not Config.Minimap.requireItem

RegisterNetEvent('fdb-hud:client:itemGatedUpdate', function(data)
    hasMapItem = data.map
end)

CreateThread(function()
    while true do
        Wait(500)
        if Config.Minimap.enabled and hasMapItem then
            SetMinimapType(1) -- mapa circular, NUNCA modo 3 (bussola nativa)
        else
            SetMinimapType(0)
        end
    end
end)



