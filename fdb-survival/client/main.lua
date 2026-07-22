local RSGCore = exports['rsg-core']:GetCoreObject()
local isLoggedIn = false

local survival = {
    bladder = 0,
    cleanliness = 100,
    poison = 0,
    illness = 0,
    coldResistance = 0,
    heatResistance = 0
}

local isHoldingPee = false

local function SyncLocalMetadata()
    local PlayerData = RSGCore.Functions.GetPlayerData()
    if PlayerData and PlayerData.metadata then
        survival.bladder = PlayerData.metadata["bladder"] or 0
        survival.cleanliness = PlayerData.metadata["cleanliness"] or 100
        survival.poison = PlayerData.metadata["poison"] or 0
        survival.illness = PlayerData.metadata["illness"] or 0
    end
end

RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    isLoggedIn = true
    SyncLocalMetadata()
end)

RegisterNetEvent('RSGCore:Client:OnPlayerLogout', function()
    isLoggedIn = false
end)

RegisterNetEvent('RSGCore:Client:OnPlayerInfoUpdate', function(data)
    SyncLocalMetadata()
end)

RegisterNetEvent('RSGCore:Player:SetPlayerData', function(val)
    SyncLocalMetadata()
end)

CreateThread(function()
    Wait(1000)
    if not isLoggedIn then
        local data = RSGCore.Functions.GetPlayerData()
        if data and data.citizenid then
            isLoggedIn = true
            SyncLocalMetadata()
        end
    end
end)

local function BroadcastState(field, value)
    TriggerEvent('fdb-survival:client:stateChanged', { field = field, value = value })
end

-- =======================================================
-- LOOP PRINCIPAL (4s)
-- =======================================================
CreateThread(function()
    local syncTimer = 0
    while true do
        Wait(Config.DrainRates.TickRate)
        if isLoggedIn then
            local ped = PlayerPedId()
            
            -- Dreno de Higiene Gradual e por Clima/Terreno
            local cleanlinessDrain = Config.DrainRates.Cleanliness
            if GetRainLevel() > 0.1 then
                cleanlinessDrain = cleanlinessDrain * Config.DrainRates.WeatherMultipliers.Rain
            end
            
            local oldCleanliness = survival.cleanliness
            survival.cleanliness = math.max(0, survival.cleanliness - cleanlinessDrain)
            if math.floor(survival.cleanliness) ~= math.floor(oldCleanliness) then
                BroadcastState('cleanliness', math.floor(survival.cleanliness))
            end

            -- Aumento de Bexiga
            local bladderDrain = Config.DrainRates.Bladder
            local oldBladder = survival.bladder
            survival.bladder = math.min(100, survival.bladder + bladderDrain)
            if math.floor(survival.bladder) ~= math.floor(oldBladder) then
                BroadcastState('bladder', math.floor(survival.bladder))
            end

            -- Dano por Veneno de Cobra Contínuo
            local isPoisoned = Citizen.InvokeNative(0x137772C61AEC7E11, ped)
            local oldPoison = survival.poison
            if isPoisoned then
                survival.poison = 100
                if GetEntityHealth(ped) > 0 and not IsEntityDead(ped) then
                    SetEntityHealth(ped, math.max(0, GetEntityHealth(ped) - Config.Hazards.PoisonDamage))
                end
            else
                survival.poison = 0
            end
            if survival.poison ~= oldPoison then
                BroadcastState('poison', survival.poison)
            end

            -- Termorregulação (Dano em Temperatura Extrema)
            local coords = GetEntityCoords(ped)
            Citizen.InvokeNative(0xB98B78C3768AF6E0, true)
            local temp = GetTemperatureAtCoords(coords.x, coords.y, coords.z)
            
            local hasThermalProtection = false
            if temp < Config.Hazards.ExtremeColdThreshold and survival.coldResistance > 0 then
                hasThermalProtection = true
            elseif temp > Config.Hazards.ExtremeHeatThreshold and survival.heatResistance > 0 then
                hasThermalProtection = true
            end
            
            if (temp < Config.Hazards.ExtremeColdThreshold or temp > Config.Hazards.ExtremeHeatThreshold) and not hasThermalProtection then
                if GetEntityHealth(ped) > 0 and not IsEntityDead(ped) then
                    SetEntityHealth(ped, math.max(0, GetEntityHealth(ped) - Config.Hazards.TemperatureDamage))
                end
                
                if temp < Config.Hazards.ExtremeColdThreshold and math.random(1, 100) <= Config.Hazards.IllnessChancePercent then
                    local oldIllness = survival.illness
                    survival.illness = math.min(100, survival.illness + Config.Hazards.IllnessGain)
                    if math.floor(survival.illness) ~= math.floor(oldIllness) then
                        BroadcastState('illness', math.floor(survival.illness))
                    end
                end
            end
            
            -- Doença (Illness)
            if survival.illness > Config.Hazards.IllnessSymptomThreshold then
                if math.random(1, 100) <= Config.Hazards.CoughChancePercent then
                    TaskStartScenarioInPlace(ped, joaat('WORLD_HUMAN_COUGH'), 3000, true, false, false, false)
                end
            end

            -- Salvar no banco a cada 16s (4 ticks)
            syncTimer = syncTimer + (Config.DrainRates.TickRate / 1000)
            if syncTimer >= 16 then
                syncTimer = 0
                -- Em fdb-survival, atualizamos apenas as vars q dominamos
                TriggerServerEvent('fdb-survival:server:SaveMeta', 'cleanliness', math.floor(survival.cleanliness))
                TriggerServerEvent('fdb-survival:server:SaveMeta', 'bladder', math.floor(survival.bladder))
                TriggerServerEvent('fdb-survival:server:SaveMeta', 'poison', math.floor(survival.poison))
                TriggerServerEvent('fdb-survival:server:SaveMeta', 'illness', math.floor(survival.illness))
            end
        end
    end
end)

-- =======================================================
-- THREAD DE BUFFS TEMPORÁRIOS DE CLIMA (1s)
-- =======================================================
CreateThread(function()
    while true do
        Wait(1000)
        if isLoggedIn then
            if survival.coldResistance > 0 then
                survival.coldResistance = survival.coldResistance - 1
                BroadcastState('coldResistance', survival.coldResistance)
            end
            
            if survival.heatResistance > 0 then
                survival.heatResistance = survival.heatResistance - 1
                BroadcastState('heatResistance', survival.heatResistance)
            end
        end
    end
end)

-- =======================================================
-- DEBUFF DE BEXIGA CHEIA
-- =======================================================
CreateThread(function()
    while true do
        Wait(1000)
        if isLoggedIn then
            local ped = PlayerPedId()
            if survival.bladder >= 80 and not isHoldingPee then
                isHoldingPee = true
                Citizen.InvokeNative(0x923583741DC87BCE, ped, 'war_veteran')
                exports['ox_lib']:notify({
                    title = 'Bexiga Cheia!',
                    description = 'Você precisa se aliviar urgente (/mijar).',
                    type = 'warning',
                    duration = 5000
                })
            elseif survival.bladder < 80 and isHoldingPee then
                isHoldingPee = false
                Citizen.InvokeNative(0x923583741DC87BCE, ped, 'default')
            end
        end
    end
end)

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

-- =======================================================
-- DEBUFF DE SUJEIRA EXTREMA E MOSCAS
-- =======================================================
local isSmelly = false
local flyParticle = nil

CreateThread(function()
    while true do
        Wait(1000)
        if isLoggedIn then
            local ped = PlayerPedId()
            if survival.cleanliness < 20 and not isSmelly then
                isSmelly = true
                exports['ox_lib']:notify({
                    title = 'Você está fedendo!',
                    description = 'As moscas começaram a te rodear. Vá se lavar (/lavar).',
                    type = 'warning',
                    duration = 5000
                })

                -- Efeito de moscas rodeando
                local assetName = "core"
                local ptfxName = "ent_anim_fly_swarm"
                
                RequestNamedPtfxAsset(assetName)
                local timeout = 0
                while not HasNamedPtfxAssetLoaded(assetName) and timeout < 50 do
                    Wait(10)
                    timeout = timeout + 1
                end
                
                if HasNamedPtfxAssetLoaded(assetName) then
                    UseParticleFxAsset(assetName)
                    flyParticle = StartNetworkedParticleFxLoopedOnEntity(
                        ptfxName, ped,
                        0.0, 0.0, 0.0, -- Offset
                        0.0, 0.0, 0.0, -- Rotação
                        1.0, -- Escala
                        false, false, false
                    )
                end

            elseif survival.cleanliness >= 20 and isSmelly then
                isSmelly = false
                if flyParticle then
                    StopParticleFxLooped(flyParticle, false)
                    flyParticle = nil
                end
                RemoveNamedPtfxAsset("core")
            end
        end
    end
end)

-- =======================================================
-- EVENTOS CLIENTES (Curas e Buffs)
-- =======================================================
RegisterNetEvent('fdb-survival:client:EatThermalItem', function(buffType, duration)
    if buffType == 'cold' then
        survival.coldResistance = duration
        BroadcastState('coldResistance', duration)
    elseif buffType == 'heat' then
        survival.heatResistance = duration
        BroadcastState('heatResistance', duration)
    end
end)

RegisterNetEvent('fdb-survival:client:CurePoison', function()
    local ped = PlayerPedId()
    Citizen.InvokeNative(0x9E9762207289BA64, ped, false)
    survival.poison = 0
    BroadcastState('poison', 0)
end)

RegisterNetEvent('fdb-survival:client:CureIllness', function()
    survival.illness = 0
    BroadcastState('illness', 0)
end)

-- =======================================================
-- COMANDOS
-- =======================================================
RegisterCommand("mijar", function()
    local ped = PlayerPedId()
    if IsPedOnMount(ped) or IsPedInAnyVehicle(ped, false) then
        exports['ox_lib']:notify({ title = 'Erro', description = 'Desça antes de se aliviar!', type = 'error' })
        return
    end
    
    ClearPedTasks(ped)
    TaskStartScenarioInPlace(ped, joaat('WORLD_HUMAN_PEE'), -1, true, false, false, false)
    Wait(4000)

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
        5.0,
        false, false, false
    )
    SetParticleFxLoopedColour(peeParticle, 1.0, 1.0, 0.0, 0)

    Wait(6000)
    StopParticleFxLooped(peeParticle, false)
    RemoveNamedPtfxAsset(assetName)
    Wait(3500)
    ClearPedTasks(ped)
    
    survival.bladder = 0
    BroadcastState('bladder', 0)
    TriggerServerEvent('fdb-survival:server:SaveMeta', 'bladder', 0)
end, false)

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
    Citizen.InvokeNative(0xE314AC4AD713061A, ped)
    
    survival.cleanliness = 100
    BroadcastState('cleanliness', 100)
    TriggerServerEvent('fdb-survival:server:SaveMeta', 'cleanliness', 100)
end, false)

CreateThread(function()
    exports.ox_target:addGlobalObject({
        {
            name = 'pee_action_object',
            label = 'Mijar',
            icon = 'fa-solid fa-droplet',
            onSelect = function() ExecuteCommand('mijar') end,
            distance = 2.0
        }
    })
    
    exports.ox_target:addGlobalVehicle({
        {
            name = 'pee_action_vehicle',
            label = 'Mijar',
            icon = 'fa-solid fa-droplet',
            onSelect = function() ExecuteCommand('mijar') end,
            distance = 2.0
        }
    })
end)
