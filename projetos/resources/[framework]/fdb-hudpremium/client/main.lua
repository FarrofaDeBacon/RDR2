-- ============================================================
-- fdb-hudpremium | client/main.lua
-- Inicialização, controle de HUD nativo e loop principal (Lua-2)
-- ============================================================

local RSGCore = exports['rsg-core']:GetCoreObject()
local PlayerData = {}
local isLoggedIn = false
local nuiReady = false
local KVP_KEY = "fdb-hudpremium:settings"

-- Cache de status para otimização e redução de spam de tráfego NUI
local lastStatus = {
    health = -1, stamina = -1,
    food = -1, water = -1, stress = -1, urine = -1, drunkenness = -1,
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
                colors = decoded.colors,
                scales = decoded.scales
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

RegisterNetEvent('RSGCore:Client:OnPlayerInfoUpdate', function(data)
    PlayerData = data
end)

RegisterNetEvent('RSGCore:Player:SetPlayerData', function(val)
    PlayerData = val
end)

-- -------------------------------------------------------
-- Callbacks NUI
-- -------------------------------------------------------
RegisterNUICallback("uiReady", function(data, cb)
    nuiReady = true
    LoadSettings()
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
-- Loop de Coleta de Ticks (500ms)
-- -------------------------------------------------------
CreateThread(function()
    while true do
        Wait(500)
        
        -- Garante que só roda se o player estiver logado no framework e UI pronta
        if isLoggedIn and nuiReady then
            local ped = PlayerPedId()
            
            -- Saúde do jogador (RDR2 usa 100 como base morta, max geralmente 200)
            local currentHealth = GetEntityHealth(ped)
            local maxHealth = GetEntityMaxHealth(ped)
            local health = GetNormalized(currentHealth - 100, maxHealth - 100)
            
            -- Fôlego (Stamina) do jogador
            local rawStamina = GetPlayerStamina(PlayerId())
            local stamina = math.max(0, math.min(100, math.floor(rawStamina)))
            
            -- Dados de Metabolismo (Metadados do RSGCore)
            local food = 100
            local water = 100
            local stress = 0
            local urine = 0
            local drunkenness = 0
            
            if PlayerData and PlayerData.metadata then
                food = PlayerData.metadata["hunger"] or 100
                water = PlayerData.metadata["thirst"] or 100
                stress = PlayerData.metadata["stress"] or 0
                urine = PlayerData.metadata["bladder"] or 0
                drunkenness = PlayerData.metadata["alcohol"] or 0
            end
            
            -- Cavalo (Mount)
            local mount = GetMount(ped)
            local isMounted = false
            local horseHealth = 100
            local horseStamina = 100
            
            if mount and mount ~= 0 then
                isMounted = true
                horseHealth = GetNormalized(GetEntityHealth(mount), GetEntityMaxHealth(mount))
                
                -- Stamina do cavalo nativo
                local rawHorseStamina = Citizen.InvokeNative(0x0FF421E467373FCF, mount, Citizen.ResultAsFloat())
                horseStamina = math.max(0, math.min(100, math.floor(rawHorseStamina)))
            end
            
            -- Envia apenas atualizações se algum valor mudou (reduz overhead no CEF)
            if health ~= lastStatus.health then
                lastStatus.health = health
                SendNUIMessage({ action = 'health', value = health })
            end
            if stamina ~= lastStatus.stamina then
                lastStatus.stamina = stamina
                SendNUIMessage({ action = 'stamina', value = stamina })
            end
            if food ~= lastStatus.food then
                lastStatus.food = food
                SendNUIMessage({ action = 'food', value = food })
            end
            if water ~= lastStatus.water then
                lastStatus.water = water
                SendNUIMessage({ action = 'water', value = water })
            end
            if stress ~= lastStatus.stress then
                lastStatus.stress = stress
                SendNUIMessage({ action = 'stress', value = stress })
            end
            if urine ~= lastStatus.urine then
                lastStatus.urine = urine
                SendNUIMessage({ action = 'urine', value = urine })
            end
            if drunkenness ~= lastStatus.drunkenness then
                lastStatus.drunkenness = drunkenness
                SendNUIMessage({ action = 'drunkenness', value = drunkenness })
            end
            
            -- Cavalo
            if isMounted ~= lastStatus.isMounted or horseHealth ~= lastStatus.horseHealth or horseStamina ~= lastStatus.horseStamina then
                lastStatus.isMounted = isMounted
                lastStatus.horseHealth = horseHealth
                lastStatus.horseStamina = horseStamina
                
                if isMounted then
                    SendNUIMessage({ action = 'horseHealth', value = horseHealth })
                    SendNUIMessage({ action = 'horseStamina', value = horseStamina })
                else
                    -- Se desmontar, limpa zerando para a UI esconder
                    SendNUIMessage({ action = 'horseHealth', value = 0 })
                    SendNUIMessage({ action = 'horseStamina', value = 0 })
                end
            end
        end
    end
end)

-- -------------------------------------------------------
-- Recurso reiniciado com jogador já na sessão (Restart)
-- -------------------------------------------------------
AddEventHandler("onResourceStart", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if LocalPlayer.state.isLoggedIn then
            PlayerData = RSGCore.Functions.GetPlayerData()
            isLoggedIn = true
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
