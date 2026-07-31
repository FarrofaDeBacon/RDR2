local ConfigStore = {}

-- Load from KVP on startup
CreateThread(function()
    local saved = GetResourceKvpString('fdb_global_config')
    if saved then
        local decoded = json.decode(saved)
        if type(decoded) == 'table' then
            ConfigStore = decoded
        end
    end
    
    -- Inicializar hud theme se não existir
    if not ConfigStore.hud then ConfigStore.hud = {} end
    if not ConfigStore.hud.theme then ConfigStore.hud.theme = 'light' end
end)

local function SaveConfig()
    SetResourceKvp('fdb_global_config', json.encode(ConfigStore))
end

local function setNestedValue(tbl, path, value)
    local keys = {}
    for key in string.gmatch(path, "([^%.]+)") do
        table.insert(keys, key)
    end
    
    local current = tbl
    for i = 1, #keys - 1 do
        local k = keys[i]
        if type(current[k]) ~= 'table' then
            return false -- Rejeita chave intermediária inexistente/inválida
        end
        current = current[k]
    end
    
    local lastKey = keys[#keys]
    
    current[lastKey] = value
    return true
end

exports('SetConfig', function(path, value)
    if setNestedValue(ConfigStore, path, value) then
        SaveConfig()
        TriggerClientEvent('fdb-configui:client:configChanged', -1, path, value)
        return true
    end
    return false
end)
exports('SetRuntimeConfig', exports.SetConfig)

exports('GetConfig', function(path)
    if not path then return ConfigStore end
    
    local keys = {}
    for key in string.gmatch(path, "([^%.]+)") do
        table.insert(keys, key)
    end
    
    local current = ConfigStore
    for i = 1, #keys do
        if type(current) ~= 'table' then return nil end
        current = current[keys[i]]
    end
    return current
end)
exports('GetRuntimeConfig', exports.GetConfig)

lib.callback.register('fdb-configui:server:getGlobalConfig', function(source)
    return ConfigStore
end)
