-- ============================================================
-- fdb-medical | client/sync.lua
-- Listener de Statebags para sincronizar vitais no client
-- ============================================================

local RSGCore = exports['rsg-core']:GetCoreObject()

-- Handler para ouvir atualizações de vitais na Statebag do ped do jogador
AddStateBagChangeHandler('medical', nil, function(bagName, key, value, _unused, replicated)
    if not value then return end

    local playerPed = PlayerPedId()
    local entity = GetEntityFromStateBagName(bagName)

    if entity == playerPed then
        -- Repassa o evento localmente para listeners como o HUD (fdb-hudpremium)
        TriggerEvent('fdb-medical-core:client:vitalsUpdated', value)
    end
end)
-- Limpeza e encerramento de threads ao parar o recurso
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print("[fdb-medical-core] Recurso finalizado de forma limpa.")
    end
end)

RegisterNetEvent('fdb-medical-core:client:setHealth', function(newHp)
    local ped = PlayerPedId()
    SetEntityHealth(ped, math.floor(newHp))
end)
