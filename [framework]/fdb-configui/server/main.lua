local RSGCore = exports['rsg-core']:GetCoreObject()

RegisterCommand('configui', function(source, args, rawCommand)
    local src = source
    if not RSGCore.Functions.HasPermission(src, 'admin') then return end
    
    if #args < 1 then
        TriggerClientEvent('ox_lib:notify', src, {title = 'Erro', description = 'Uso: /configui [resource]', type = 'error'})
        return
    end
    
    local resource = args[1]
    if GetResourceState(resource) ~= 'started' then
        TriggerClientEvent('ox_lib:notify', src, {title = 'Erro', description = 'Resource não encontrado ou não iniciado.', type = 'error'})
        return
    end
    
    -- Busca as confs
    local status, config = pcall(function()
        return exports[resource]:GetRuntimeConfig()
    end)
    
    if not status or not config then
        TriggerClientEvent('ox_lib:notify', src, {title = 'Erro', description = 'Resource alvo não suporta GetRuntimeConfig.', type = 'error'})
        return
    end

    TriggerClientEvent('fdb-configui:client:openPanel', src, resource, config)
end, false)

lib.callback.register('fdb-configui:server:saveConfig', function(source, resource, path, value)
    if not RSGCore.Functions.HasPermission(source, 'admin') then return false end
    
    local status, result = pcall(function()
        return exports[resource]:SetRuntimeConfig(path, value)
    end)
    
    if not status or not result then
        return false
    end
    return true
end)

lib.callback.register('fdb-configui:server:resetConfig', function(source, resource)
    if not RSGCore.Functions.HasPermission(source, 'admin') then return false end
    
    local status, result = pcall(function()
        return exports[resource]:ResetRuntimeConfig()
    end)
    
    if not status or not result then
        return false
    end
    return true
end)
