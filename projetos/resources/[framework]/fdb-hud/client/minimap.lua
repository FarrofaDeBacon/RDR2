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

local mapVisible = false
-- Loop de controle de exibição do minimapa e ocultação das direções a cada frame
CreateThread(function()
    while true do
        local canShowMap = Config.Minimap.enabled and hasMapItem and isMapEquipped
        
        if canShowMap then
            SetMinimapType(1) -- Ativa o minimapa circular no tamanho correto
            
            -- Oculta os cardinais nativos adicionais da borda do radar
            Citizen.InvokeNative(0xF80671CB9B7B280F, false)
            Citizen.InvokeNative(0x4AD55A03FF264104, false)
            Citizen.InvokeNative(0x1B86D49132E6A020, false)
            
            if not mapVisible then
                mapVisible = true
                SendNUI('updateMinimap', { visible = true })
            end
            Wait(0)
        else
            SetMinimapType(0) -- Oculta o minimapa completamente
            if mapVisible then
                mapVisible = false
                SendNUI('updateMinimap', { visible = false })
            end
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
