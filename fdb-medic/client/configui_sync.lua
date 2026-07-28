-- fdb-medic/client/configui_sync.lua

RegisterNetEvent('fdb-medic:client:syncConfig')
AddEventHandler('fdb-medic:client:syncConfig', function(newConfig)
    -- Atualiza a tabela Config global
    Config = newConfig
end)
