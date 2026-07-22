-- ============================================================
-- fdb-hudpremium | client/main.lua
-- Inicialização, loop principal, dreno de sobrevivência (Lua-3)
-- ============================================================

local RSGCore = exports['rsg-core']:GetCoreObject()
local PlayerData = {}
local isLoggedIn = false
local nuiReady = false
local KVP_KEY = "fdb-hudpremium:settings"

-- Variáveis Locais de Sobrevivência (Sincronizadas com Metadados)
local survival = {
    food = 100,
    water = 100,
    stress = 0,
    urine = 0,
    hygiene = 100,
    poison = 0,
    illness = 0,
    drunkenness = 0,
    coldResistance = 0, -- Em segundos
    heatResistance = 0  -- Em segundos
}

-- Cache de status para otimização e redução de spam de tráfego NUI
local lastStatus = {
    health = -1, stamina = -1,
    food = -1, water = -1, stress = -1, urine = -1, hygiene = -1,
    poison = -1, illness = -1, drunkenness = -1, temp = -999,
    coldResistance = -1, heatResistance = -1,
    isMounted = false, horseHealth = -1, horseStamina = -1
}

-- Helper para normalizar valores entre 0 e 100
local function GetNormalized(current, max)
    if max == 0 then return 0 end
    return math.max(0, math.min(100, math.floor((current / max) * 100)))
end

-- -------------------------------------------------------
-- Ocultação de Núcleos e HUD Nativo do RDR2
-- -------------------------------------------------------
CreateThread(function()
    while true do
        Wait(1000)
        -- Esconde ícones e núcleos nativos do jogador (Health, Stamina, DeadEye)
        for i = 0, 5 do
            Citizen.InvokeNative(0xC116E6DF68DCE667, i, 2) -- _UITUTORIAL_SET_RPG_ICON_VISIBILITY (2 = Always Hide)
        end
        -- Esconde núcleos nativos do cavalo (Health, Stamina, Courage)
        for i = 6, 11 do
            Citizen.InvokeNative(0xC116E6DF68DCE667, i, 2)
        end
    end
end)

-- -------------------------------------------------------
-- Persistência de Posições (KVP)
-- -------------------------------------------------------
local function LoadSettings()
    local savedSettings = GetResourceKvpString(KVP_KEY)
    if savedSettings then
        local decoded = json.decode(savedSettings)
        if decoded then
            SendNUIMessage({
                action = "loadSettings",
                positions = decoded.positions,
                configs = decoded.configs,
                global = decoded.global,
                colors = decoded.colors, -- Fallback legado
                scales = decoded.scales   -- Fallback legado
            })
            print("[fdb-hudpremium] Configurações de layout carregadas.")
        end
    end
end

-- Sincronizar metadados locais ao carregar o jogador
local function SyncLocalMetadata()
    if PlayerData and PlayerData.metadata then
        survival.food = PlayerData.metadata["hunger"] or 100
        survival.water = PlayerData.metadata["thirst"] or 100
        survival.stress = PlayerData.metadata["stress"] or 0
        survival.urine = PlayerData.metadata["bladder"] or 0
        survival.hygiene = PlayerData.metadata["hygiene"] or 100
        survival.poison = PlayerData.metadata["poison"] or 0
        survival.illness = PlayerData.metadata["illness"] or 0
        survival.drunkenness = PlayerData.metadata["alcohol"] or 0
    end
end

-- -------------------------------------------------------
-- Eventos do Framework (RSGCore)
-- -------------------------------------------------------
AddEventHandler('RSGCore:Client:OnPlayerLoaded', function()
    PlayerData = RSGCore.Functions.GetPlayerData()
    isLoggedIn = true
    SyncLocalMetadata()
    LoadSettings()
    SendNUIMessage({ action = 'setVisibility', value = true })
end)

AddEventHandler('RSGCore:Client:OnPlayerLogout', function()
    PlayerData = {}
    isLoggedIn = false
    SendNUIMessage({ action = 'setVisibility', value = false })
end)

RegisterNetEvent('RSGCore:Client:OnPlayerInfoUpdate', function(data)
    PlayerData = data
    SyncLocalMetadata()
end)

RegisterNetEvent('RSGCore:Player:SetPlayerData', function(val)
    PlayerData = val
    SyncLocalMetadata()
end)

-- -------------------------------------------------------
-- Callbacks NUI
-- -------------------------------------------------------
RegisterNUICallback("uiReady", function(data, cb)
    nuiReady = true
    LoadSettings()
    if isLoggedIn then
        SendNUIMessage({ action = 'setVisibility', value = true })
    end
    cb("ok")
end)

RegisterNUICallback("saveSettings", function(data, cb)
    if data then
        local encoded = json.encode(data)
        SetResourceKvp(KVP_KEY, encoded)
        print("[fdb-hudpremium] Configurações de layout salvas com sucesso.")
    end
    cb("ok")
end)

RegisterNUICallback("closeEditor", function(data, cb)
    SetNuiFocus(false, false)
    cb("ok")
end)

-- -------------------------------------------------------
-- Loop de Coleta de Ticks Básicos (500ms)
-- -------------------------------------------------------
CreateThread(function()
    while true do
        Wait(500)
        
        if isLoggedIn and nuiReady then
            local ped = PlayerPedId()
            
            -- Saúde do jogador
            local currentHealth = GetEntityHealth(ped)
            local maxHealth = GetEntityMaxHealth(ped)
            local health = GetNormalized(currentHealth - 100, maxHealth - 100)
            
            -- Fôlego (Stamina) do jogador
            local rawStamina = GetPlayerStamina(PlayerId())
            local stamina = math.max(0, math.min(100, math.floor(rawStamina)))
            
            -- Cavalo (Mount)
            local mount = GetMount(ped)
            local isMounted = false
            local horseHealth = 0
            local horseStamina = 0
            
            if mount and mount ~= 0 then
                isMounted = true
                horseHealth = GetNormalized(GetEntityHealth(mount), GetEntityMaxHealth(mount))
                local rawHorseStamina = Citizen.InvokeNative(0x0FF421E467373FCF, mount, Citizen.ResultAsFloat())
                horseStamina = math.max(0, math.min(100, math.floor(rawHorseStamina)))
            end
            
            -- Envia apenas atualizações reativas de alta prioridade se algum valor mudou
            if health ~= lastStatus.health then
                lastStatus.health = health
                SendNUIMessage({ action = 'health', value = health })
            end
            if stamina ~= lastStatus.stamina then
                lastStatus.stamina = stamina
                SendNUIMessage({ action = 'stamina', value = stamina })
            end
            
            -- Sincronização da Montaria (Reset Explícito ao desmontar)
            if isMounted ~= lastStatus.isMounted or horseHealth ~= lastStatus.horseHealth or horseStamina ~= lastStatus.horseStamina then
                lastStatus.isMounted = isMounted
                lastStatus.horseHealth = horseHealth
                lastStatus.horseStamina = horseStamina
                
                if isMounted then
                    SendNUIMessage({ action = 'horseHealth', value = horseHealth })
                    SendNUIMessage({ action = 'horseStamina', value = horseStamina })
                else
                    -- Reset explícito a 0 para esconder da UI
                    SendNUIMessage({ action = 'horseHealth', value = 0 })
                    SendNUIMessage({ action = 'horseStamina', value = 0 })
                end
            end
        end
    end
end)

-- -------------------------------------------------------
-- Efeitos de Câmera de Bebidas Alcoólicas
-- -------------------------------------------------------
-- -------------------------------------------------------
-- Loop de Consumo removido (Domínio do fdb-consume e fdb-survival)
-- -------------------------------------------------------
RegisterNetEvent('fdb-survival:client:stateChanged', function(data)
    if not nuiReady then return end
    local actionMap = {
        cleanliness = 'hygiene',
        bladder = 'urine',
        poison = 'poison',
        illness = 'illness',
        coldResistance = 'coldResistance',
        heatResistance = 'heatResistance'
    }
    local nuiAction = actionMap[data.field] or data.field
    SendNUIMessage({ action = nuiAction, value = data.value })
end)

-- Todos os interceptadores legados (hud:client:*) foram removidos.
-- O HUD agora escuta exclusivamente 'fdb-survival:client:stateChanged' para atualizações.

-- -------------------------------------------------------
-- Comandos movidos para fdb-survival

-- -------------------------------------------------------
-- Recurso reiniciado com jogador já na sessão (Restart)
-- -------------------------------------------------------
CreateThread(function()
    Wait(1000)
    if not isLoggedIn then
        local data = RSGCore.Functions.GetPlayerData()
        if data and data.citizenid then
            PlayerData = data
            isLoggedIn = true
            SyncLocalMetadata()
            LoadSettings()
            SendNUIMessage({ action = 'setVisibility', value = true })
        end
    end
end)

AddEventHandler("onResourceStart", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        local data = RSGCore.Functions.GetPlayerData()
        if data and data.citizenid then
            PlayerData = data
            isLoggedIn = true
            SyncLocalMetadata()
            LoadSettings()
            SendNUIMessage({ action = 'setVisibility', value = true })
        end
    end
end)

-- Comando de teste para abrir o Painel Editor
RegisterCommand("hud", function()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "toggleEditor",
        value = true
    })
end, false)
