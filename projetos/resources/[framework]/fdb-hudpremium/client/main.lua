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
                colors = decoded.colors,
                scales = decoded.scales
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
local shakeCamActive = false

local function UpdateDrunkEffects(value)
    if value == 0 then
        if shakeCamActive then
            shakeCamActive = false
            ShakeGameplayCam("DRUNK_SHAKE", 0.0)
            ShakeGameplayCam("DEATH_FAIL_IN_EFFECT_SHAKE", 0.0)
            AnimpostfxStop("OJDominoBlur")
        end
    else
        if not shakeCamActive then
            shakeCamActive = true
            ShakeGameplayCam("DRUNK_SHAKE", 0.3)
            ShakeGameplayCam("DEATH_FAIL_IN_EFFECT_SHAKE", 0.2)
            AnimpostfxPlay("OJDominoBlur")
        end
        local intensity = math.max(0.1, math.min(1.0, value / 100))
        Citizen.InvokeNative(0xCAB4DD2D5B2B7246, "OJDominoBlur", intensity) -- Define intensidade do blur
    end
end

-- -------------------------------------------------------
-- Loop de Consumo e Sobrevivência (Dreno Dinâmico de 4s)
-- -------------------------------------------------------
CreateThread(function()
    local syncTimer = 0
    while true do
        Wait(4000)
        
        if isLoggedIn and nuiReady then
            local ped = PlayerPedId()
            
            -- 1. Fome/Sede com Dreno Dinâmico por Ação
            local hungerDrain = 0.08
            local thirstDrain = 0.12
            
            if IsPedSwimming(ped) then
                hungerDrain = hungerDrain * 3.0
                thirstDrain = thirstDrain * 3.0
            elseif IsPedSprinting(ped) or IsPedRunning(ped) then
                hungerDrain = hungerDrain * 2.0
                thirstDrain = thirstDrain * 2.0
            elseif IsPedWalking(ped) then
                hungerDrain = hungerDrain * 1.2
                thirstDrain = thirstDrain * 1.2
            end
            
            survival.food = math.max(0, survival.food - hungerDrain)
            survival.water = math.max(0, survival.water - thirstDrain)
            
            -- 2. Dreno de Higiene Gradual e por Clima/Terreno
            local hygieneDrain = 0.1
            if GetRainLevel() > 0.1 then
                hygieneDrain = hygieneDrain * 2.0 -- Mais sujeira na chuva/lama
            end
            survival.hygiene = math.max(0, survival.hygiene - hygieneDrain)
            
            -- 3. Decaimento de Álcool (Drunkenness)
            if survival.drunkenness > 0 then
                survival.drunkenness = math.max(0, survival.drunkenness - 0.5)
                UpdateDrunkEffects(survival.drunkenness)
            end
            
            -- 4. Dano por Veneno de Cobra Contínuo
            -- RDR2 Nativo: verifica se está envenenado
            local isPoisoned = Citizen.InvokeNative(0x137772C61AEC7E11, ped)
            if isPoisoned then
                survival.poison = 100
                SetEntityHealth(ped, GetEntityHealth(ped) - 2) -- Dano de veneno
            else
                survival.poison = 0
            end
            
            -- 5. Termorregulação (Dano em Temperatura Extrema)
            local coords = GetEntityCoords(ped)
            Citizen.InvokeNative(0xB98B78C3768AF6E0, true) -- Ativa leitura climática
            local temp = GetTemperatureAtCoords(coords.x, coords.y, coords.z)
            
            local hasThermalProtection = false
            if temp < -2.0 and survival.coldResistance > 0 then
                hasThermalProtection = true
            elseif temp > 37.0 and survival.heatResistance > 0 then
                hasThermalProtection = true
            end
            
            if (temp < -2.0 or temp > 37.0) and not hasThermalProtection then
                SetEntityHealth(ped, GetEntityHealth(ped) - 3) -- Dano climático
                -- Chance de contrair Doença (Illness) no frio extremo
                if temp < -2.0 and math.random(1, 100) <= 8 then
                    survival.illness = math.min(100, survival.illness + 10)
                end
            end
            
            -- Doença (Illness) drena fôlego e faz ped tossir
            if survival.illness > 5 then
                if math.random(1, 100) <= 12 then
                    -- Animação de tosse
                    TaskStartScenarioInPlace(ped, joaat('WORLD_HUMAN_COUGH'), 3000, true, false, false, false)
                end
            end
            
            -- 6. Atualização reativa de interface (NUI)
            if math.floor(survival.food) ~= lastStatus.food then
                lastStatus.food = math.floor(survival.food)
                SendNUIMessage({ action = 'food', value = lastStatus.food })
            end
            if math.floor(survival.water) ~= lastStatus.water then
                lastStatus.water = math.floor(survival.water)
                SendNUIMessage({ action = 'water', value = lastStatus.water })
            end
            if math.floor(survival.hygiene) ~= lastStatus.hygiene then
                lastStatus.hygiene = math.floor(survival.hygiene)
                SendNUIMessage({ action = 'hygiene', value = lastStatus.hygiene })
            end
            if math.floor(survival.urine) ~= lastStatus.urine then
                lastStatus.urine = math.floor(survival.urine)
                SendNUIMessage({ action = 'urine', value = lastStatus.urine })
            end
            if math.floor(survival.drunkenness) ~= lastStatus.drunkenness then
                lastStatus.drunkenness = math.floor(survival.drunkenness)
                SendNUIMessage({ action = 'drunkenness', value = lastStatus.drunkenness })
            end
            if math.floor(survival.poison) ~= lastStatus.poison then
                lastStatus.poison = math.floor(survival.poison)
                SendNUIMessage({ action = 'poison', value = lastStatus.poison })
            end
            if math.floor(survival.illness) ~= lastStatus.illness then
                lastStatus.illness = math.floor(survival.illness)
                SendNUIMessage({ action = 'illness', value = lastStatus.illness })
            end
            if math.floor(temp) ~= lastStatus.temp then
                lastStatus.temp = math.floor(temp)
                SendNUIMessage({ action = 'temp', value = lastStatus.temp })
            end
            
            -- Timer de Sincronização com o Banco do Servidor (a cada 16s)
            syncTimer = syncTimer + 4
            if syncTimer >= 16 then
                syncTimer = 0
                TriggerServerEvent('fdb-hudpremium:server:updateMetas', 
                    math.floor(survival.food), 
                    math.floor(survival.water), 
                    math.floor(survival.stress), 
                    math.floor(survival.urine),
                    math.floor(survival.drunkenness),
                    math.floor(survival.hygiene),
                    math.floor(survival.poison),
                    math.floor(survival.illness)
                )
            end
        end
    end
end)

-- -------------------------------------------------------
-- Thread de Buffs Temporários de Clima (1s)
-- -------------------------------------------------------
CreateThread(function()
    while true do
        Wait(1000)
        if isLoggedIn and nuiReady then
            -- Redução do tempo restante do buff de frio
            if survival.coldResistance > 0 then
                survival.coldResistance = survival.coldResistance - 1
                SendNUIMessage({ action = 'coldResistance', value = survival.coldResistance })
                if survival.coldResistance == 0 then
                    -- Reset explícito na expiração do buff
                    SendNUIMessage({ action = 'coldResistance', value = 0 })
                end
            end
            
            -- Redução do tempo restante do buff de calor
            if survival.heatResistance > 0 then
                survival.heatResistance = survival.heatResistance - 1
                SendNUIMessage({ action = 'heatResistance', value = survival.heatResistance })
                if survival.heatResistance == 0 then
                    -- Reset explícito na expiração do buff
                    SendNUIMessage({ action = 'heatResistance', value = 0 })
                end
            end
        end
    end
end)

-- -------------------------------------------------------
-- Debuff de Bexiga Cheia (Urina >= 80)
-- -------------------------------------------------------
local isHoldingPee = false

CreateThread(function()
    while true do
        Wait(1000)
        if isLoggedIn and PlayerData then
            local ped = PlayerPedId()
            if survival.urine >= 80 and not isHoldingPee then
                isHoldingPee = true
                Citizen.InvokeNative(0x923583741DC87BCE, ped, 'war_veteran') -- Estilo de andar manco
                exports['ox_lib']:notify({
                    title = 'Bexiga Cheia!',
                    description = 'Você precisa se aliviar urgende (/mijar).',
                    type = 'warning',
                    duration = 5000
                })
            elseif survival.urine < 80 and isHoldingPee then
                isHoldingPee = false
                Citizen.InvokeNative(0x923583741DC87BCE, ped, 'default') -- Restaura andar normal
            end
        end
    end
end)

-- Bloqueia corrida e pulo se estiver segurando o xixi
CreateThread(function()
    while true do
        Wait(0)
        if isHoldingPee then
            DisableControlAction(0, 0x8FFC75D6, true) -- INPUT_SPRINT
            DisableControlAction(0, 0xD9D0E16C, true) -- INPUT_JUMP
        else
            Wait(1000)
        end
    end
end)

-- -------------------------------------------------------
-- Eventos Clientes e Antídotos
-- -------------------------------------------------------
RegisterNetEvent('fdb-hudpremium:client:EatThermalItem', function(buffType, duration)
    if buffType == 'cold' then
        survival.coldResistance = duration
        SendNUIMessage({ action = 'coldResistance', value = duration })
    elseif buffType == 'heat' then
        survival.heatResistance = duration
        SendNUIMessage({ action = 'heatResistance', value = duration })
    end
end)

RegisterNetEvent('fdb-hudpremium:client:CurePoison', function()
    local ped = PlayerPedId()
    Citizen.InvokeNative(0x9E9762207289BA64, ped, false) -- Remove veneno nativo (_SET_PED_POISONED)
    survival.poison = 0
    SendNUIMessage({ action = 'poison', value = 0 })
end)

RegisterNetEvent('fdb-hudpremium:client:CureIllness', function()
    survival.illness = 0
    SendNUIMessage({ action = 'illness', value = 0 })
end)

RegisterNetEvent('fdb-hudpremium:client:DrinkAlcohol', function(amount)
    survival.drunkenness = math.min(100, survival.drunkenness + amount)
    SendNUIMessage({ action = 'drunkenness', value = survival.drunkenness })
    UpdateDrunkEffects(survival.drunkenness)
end)

-- Interceptadores de consumíveis legados para compatibilidade
RegisterNetEvent('hud:client:UpdateThirst', function(newThirst)
    local currentThirst = survival.water
    local diff = newThirst - currentThirst
    if diff > 0 then
        TriggerServerEvent('fdb-hudpremium:server:UpdateThirstBladder', diff)
        survival.water = newThirst
    end
end)

RegisterNetEvent('hud:client:UpdateHunger', function(newHunger)
    local currentHunger = survival.food
    local diff = newHunger - currentHunger
    if diff > 0 then
        TriggerServerEvent('fdb-hudpremium:server:UpdateHunger', diff)
        survival.food = newHunger
    end
end)

RegisterNetEvent('hud:client:UpdateAlcohol', function(newAlcohol)
    local currentAlcohol = survival.drunkenness
    local diff = newAlcohol - currentAlcohol
    if diff ~= 0 then
        TriggerServerEvent('fdb-hudpremium:server:UpdateAlcohol', diff)
        survival.drunkenness = newAlcohol
        UpdateDrunkEffects(survival.drunkenness)
    end
end)

RegisterNetEvent('hud:client:RelieveStress', function(amount)
    if type(amount) == "number" and amount > 0 then
        TriggerServerEvent('fdb-hudpremium:server:RelieveStress', amount)
        survival.stress = math.max(0, survival.stress - amount)
    end
end)

-- -------------------------------------------------------
-- Comandos de Sobrevivência
-- -------------------------------------------------------

-- 1. Comando de Mijar (/mijar)
RegisterCommand("mijar", function()
    local ped = PlayerPedId()
    if IsPedOnMount(ped) or IsPedInAnyVehicle(ped, false) then
        exports['ox_lib']:notify({ title = 'Erro', description = 'Desça antes de se aliviar!', type = 'error' })
        return
    end
    
    ClearPedTasks(ped)
    TaskStartScenarioInPlace(ped, joaat('WORLD_HUMAN_PEE'), -1, true, false, false, false)
    Wait(4000) -- Aguarda abrir a calça

    -- Efeito de Partícula
    local assetName = "core"
    local ptfxName = "ent_anim_dog_peeing"
    
    RequestNamedPtfxAsset(assetName)
    while not HasNamedPtfxAssetLoaded(assetName) do
        Wait(10)
    end
    
    UseParticleFxAsset(assetName)
    local boneIndex = GetEntityBoneIndexByName(ped, "SKEL_Pelvis")
    local peeParticle = StartNetworkedParticleFxLoopedOnEntityBone(
        ptfxName, ped,
        0.0, 0.15, -0.1,
        -90.0, 0.0, 0.0,
        boneIndex,
        5.0, -- Grossura do jato
        false, false, false
    )
    SetParticleFxLoopedColour(peeParticle, 1.0, 1.0, 0.0, 0) -- Cor amarela do jato

    Wait(6000) -- Duração do jato
    StopParticleFxLooped(peeParticle, false)
    RemoveNamedPtfxAsset(assetName)
    Wait(3500) -- Fechar a calça
    ClearPedTasks(ped)
    
    -- Reseta Urina local e envia explicitamente 0 para a UI
    survival.urine = 0
    SendNUIMessage({ action = 'urine', value = 0 })
    TriggerServerEvent('fdb-hudpremium:server:updateMetas', nil, nil, nil, 0)
end, false)

-- 2. Comando de Lavar-se (/lavar)
RegisterCommand("lavar", function()
    local ped = PlayerPedId()
    if IsPedOnMount(ped) or IsPedInAnyVehicle(ped, false) then
        exports['ox_lib']:notify({ title = 'Erro', description = 'Desça antes de se lavar!', type = 'error' })
        return
    end
    
    ClearPedTasks(ped)
    TaskStartScenarioInPlace(ped, joaat('WORLD_HUMAN_CLEAN_TABLE'), -1, true, false, false, false)
    exports['ox_lib']:progressBar({
        duration = 5000,
        label = 'Limpando sujeira...',
        useActiveKey = false,
        canCancel = false,
    })
    ClearPedTasks(ped)
    Citizen.InvokeNative(0xE314AC4AD713061A, ped) -- Remove lama visual nativa do ped
    
    -- Reseta Higiene local e envia explicitamente 100 para a UI
    survival.hygiene = 100
    SendNUIMessage({ action = 'hygiene', value = 100 })
    TriggerServerEvent('fdb-hudpremium:server:updateMetas', nil, nil, nil, nil, nil, 100)
end, false)

-- -------------------------------------------------------
-- Recurso reiniciado com jogador já na sessão (Restart)
-- -------------------------------------------------------
CreateThread(function()
    Wait(1000)
    print("[fdb-hudpremium] STARTUP: Verificando status de login...")
    local data = RSGCore.Functions.GetPlayerData()
    print("[fdb-hudpremium] STARTUP: PlayerData retornado: ", json.encode(data))
    if not isLoggedIn then
        if data and data.citizenid then
            PlayerData = data
            isLoggedIn = true
            SyncLocalMetadata()
            LoadSettings()
            SendNUIMessage({ action = 'setVisibility', value = true })
            print("[fdb-hudpremium] Inicializado com sucesso via login ativo (Startup Fallback).")
        else
            print("[fdb-hudpremium] STARTUP: citizenid ausente ou nulo.")
        end
    end
end)

AddEventHandler("onResourceStart", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print("[fdb-hudpremium] onResourceStart disparado.")
        local data = RSGCore.Functions.GetPlayerData()
        if data and data.citizenid then
            PlayerData = data
            isLoggedIn = true
            SyncLocalMetadata()
            LoadSettings()
            SendNUIMessage({ action = 'setVisibility', value = true })
            print("[fdb-hudpremium] Inicializado com sucesso via onResourceStart.")
        else
            print("[fdb-hudpremium] onResourceStart: jogador não está logado ainda.")
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
