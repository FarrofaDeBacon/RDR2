-- ============================================================
-- fdb-medical-core | server/runtime_config.lua
-- Gerenciador de configurações em tempo de execução
-- ============================================================

local RuntimeConfig = {}

-- Inicializa o RuntimeConfig a partir do KVP ou do padrão
Citizen.CreateThread(function()
    local saved = GetResourceKvpString("fdb_medical_runtime_config")
    if saved then
        local decoded = json.decode(saved)
        if decoded then
            RuntimeConfig = decoded
        else
            RuntimeConfig = json.decode(json.encode(Config))
        end
    else
        RuntimeConfig = json.decode(json.encode(Config))
    end
end)

-- Helper para navegar em paths (ex: "Wounds.Bleeding.DrainRate")
local function setNestedValue(t, path, value)
    local keys = {}
    for key in string.gmatch(path, "([^%.]+)") do
        table.insert(keys, key)
    end

    local current = t
    for i = 1, #keys - 1 do
        local k = keys[i]
        if tonumber(k) then k = tonumber(k) end
        if not current[k] then current[k] = {} end
        current = current[k]
    end

    local lastKey = keys[#keys]
    if tonumber(lastKey) then lastKey = tonumber(lastKey) end
    current[lastKey] = value
end

local function SetRuntimeConfig(path, value)
    setNestedValue(RuntimeConfig, path, value)
    SetResourceKvp("fdb_medical_runtime_config", json.encode(RuntimeConfig))
    return true
end

local function GetRuntimeConfig()
    return RuntimeConfig
end

local function ResetRuntimeConfig()
    RuntimeConfig = json.decode(json.encode(Config))
    DeleteResourceKvp("fdb_medical_runtime_config")
    return true
end

exports('GetRuntimeConfig', GetRuntimeConfig)
exports('SetRuntimeConfig', SetRuntimeConfig)
exports('ResetRuntimeConfig', ResetRuntimeConfig)
