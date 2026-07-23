-- ============================================================
-- fdb-hudpremium | client/main.lua
-- Inicialização, loop principal (Lua-3)
-- ============================================================

local RSGCore = exports['rsg-core']:GetCoreObject()
local PlayerData = {}
local isLoggedIn = false
local nuiReady = false
local KVP_KEY = "fdb-hudpremium:settings"

-- Cache de status para otimização e redução de spam de tráfego NUI
local lastStatus = {
    health = -1, stamina = -1,
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

-- -------------------------------------------------------
-- Eventos do Framework (RSGCore)
-- -------------------------------------------------------
AddEventHandler('RSGCore:Client:OnPlayerLoaded', function()
    PlayerData = RSGCore.Functions.GetPlayerData()
    isLoggedIn = true
    LoadSettings()
    SendNUIMessage({ action = 'setVisibility', value = true })
end)

AddEventHandler('RSGCore:Client:OnPlayerLogout', function()
    PlayerData = {}
    isLoggedIn = false
    SendNUIMessage({ action = 'setVisibility', value = false })
end)

local function SyncMetadata()
    if not PlayerData or not PlayerData.metadata then return end
    if nuiReady then
        local hunger = PlayerData.metadata["hunger"] or 100
        local thirst = PlayerData.metadata["thirst"] or 100
        local stress = PlayerData.metadata["stress"] or 0
        
        SendNUIMessage({ action = 'food', value = hunger })
        SendNUIMessage({ action = 'water', value = thirst })
        SendNUIMessage({ action = 'stress', value = stress })
    end
end

RegisterNetEvent('RSGCore:Client:OnPlayerInfoUpdate', function(data)
    PlayerData = RSGCore.Functions.GetPlayerData()
    SyncMetadata()
end)

RegisterNetEvent('RSGCore:Player:SetPlayerData', function(val)
    PlayerData = RSGCore.Functions.GetPlayerData()
    SyncMetadata()
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
-- Loop de Coleta de Ticks Básicos (500ms) - Vida e Fôlego
-- -------------------------------------------------------
CreateThread(function()
    while true do
        Wait(500)
        
        if isLoggedIn and nuiReady then
            local ped = PlayerPedId()
            
            -- Saúde do jogador (Tank + Core combinados em 0-100 para a UI)
            local currentHealth = GetEntityHealth(ped)
            local maxHealth = GetEntityMaxHealth(ped)
            local healthTank = GetNormalized(currentHealth - 100, maxHealth - 100)
            local healthCore = Citizen.InvokeNative(0x36731AC041289BB1, ped, 0)
            if not tonumber(healthCore) then healthCore = 0 end
            local health = math.floor((healthTank / 2) + (healthCore / 2))
            
            -- Fôlego (Stamina) do jogador
            local rawStamina = GetPlayerStamina(PlayerId())
            local staminaTank = math.max(0, math.min(100, math.floor(rawStamina)))
            local staminaCore = Citizen.InvokeNative(0x36731AC041289BB1, ped, 1)
            if not tonumber(staminaCore) then staminaCore = 0 end
            local stamina = math.floor((staminaTank / 2) + (staminaCore / 2))
            
            -- Cavalo (Mount)
            local mount = GetMount(ped)
            local isMounted = false
            local horseHealth = 0
            local horseStamina = 0
            
            if mount and mount ~= 0 then
                isMounted = true
                local hHealthTank = GetNormalized(GetEntityHealth(mount), GetEntityMaxHealth(mount))
                local hHealthCore = Citizen.InvokeNative(0x36731AC041289BB1, mount, 0)
                if not tonumber(hHealthCore) then hHealthCore = 0 end
                horseHealth = math.floor((hHealthTank / 2) + (hHealthCore / 2))

                local rawHorseStamina = Citizen.InvokeNative(0x0FF421E467373FCF, mount, Citizen.ResultAsFloat())
                local hStaminaTank = math.max(0, math.min(100, math.floor(rawHorseStamina)))
                local hStaminaCore = Citizen.InvokeNative(0x36731AC041289BB1, mount, 1)
                if not tonumber(hStaminaCore) then hStaminaCore = 0 end
                horseStamina = math.floor((hStaminaTank / 2) + (hStaminaCore / 2))
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
-- Receptor de Alterações de Estado (Consume / Survival)
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
            LoadSettings()
            SendNUIMessage({ action = 'setVisibility', value = true })
            SyncMetadata()
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
