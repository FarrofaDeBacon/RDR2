local RSGCore = exports['rsg-core']:GetCoreObject()

FDB = FDB or {}
FDB.IsLoggedIn = false
FDB.Survival = {
    bladder = 0,
    cleanliness = 100,
    poison = 0,
    illness = 0,
    coldResistance = 0,
    heatResistance = 0
}

function FDB.BroadcastState(field, value)
    TriggerEvent('fdb-survival:client:stateChanged', { field = field, value = value })
end

local function SyncLocalMetadata(isInit)
    local PlayerData = RSGCore.Functions.GetPlayerData()
    if PlayerData and PlayerData.metadata then
        if isInit then
            FDB.Survival.bladder = PlayerData.metadata["bladder"] or 0
            FDB.Survival.cleanliness = PlayerData.metadata["cleanliness"] or 100
            FDB.Survival.poison = PlayerData.metadata["poison"] or 0
            FDB.Survival.illness = PlayerData.metadata["illness"] or 0
        else
            -- Durante o jogo, não deixamos o server sobrescrever o progresso local (que pode estar até 16s na frente)
            -- Exceto se o server mandar um valor de RESET absoluto (ex: script de banho mandou 100)
            local sClean = PlayerData.metadata["cleanliness"] or 100
            if sClean == 100 and FDB.Survival.cleanliness < 99 then
                FDB.Survival.cleanliness = 100
                FDB.BroadcastState('cleanliness', 100)
            end
            
            local sBladder = PlayerData.metadata["bladder"] or 0
            if sBladder == 0 and FDB.Survival.bladder > 1 then
                FDB.Survival.bladder = 0
                FDB.BroadcastState('bladder', 0)
            end
            
            local sPoison = PlayerData.metadata["poison"] or 0
            if sPoison == 0 and FDB.Survival.poison > 1 then
                FDB.Survival.poison = 0
                FDB.BroadcastState('poison', 0)
            end
            
            local sIllness = PlayerData.metadata["illness"] or 0
            if sIllness == 0 and FDB.Survival.illness > 1 then
                FDB.Survival.illness = 0
                FDB.BroadcastState('illness', 0)
            end
        end
    end
end

RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    FDB.IsLoggedIn = true
    SyncLocalMetadata(true)
    
    local PlayerData = RSGCore.Functions.GetPlayerData()
    if PlayerData and PlayerData.metadata then
        LocalPlayer.state:set('isWet', PlayerData.metadata["isWet"] or false, true)
    end
end)

RegisterNetEvent('fdb-survival:client:ForceClean', function()
    FDB.Survival.cleanliness = 100
    FDB.BroadcastState('cleanliness', 100)
end)

RegisterNetEvent('fdb-survival:client:AddThirst', function(val)
    FDB.Survival.thirst = val
    FDB.BroadcastState('thirst', val)
end)

RegisterNetEvent('RSGCore:Client:OnPlayerLogout', function()
    FDB.IsLoggedIn = false
end)

RegisterNetEvent('RSGCore:Client:OnPlayerInfoUpdate', function(data)
    SyncLocalMetadata()
end)

RegisterNetEvent('RSGCore:Player:SetPlayerData', function(val)
    SyncLocalMetadata()
end)

CreateThread(function()
    Wait(1000)
    if not FDB.IsLoggedIn then
        local data = RSGCore.Functions.GetPlayerData()
        if data and data.citizenid then
            FDB.IsLoggedIn = true
            SyncLocalMetadata(true)
        end
    end
end)

-- =======================================================
-- LOOP PRINCIPAL (4s)
-- =======================================================
CreateThread(function()
    local syncTimer = 0
    while true do
        Wait(Config.DrainRates.TickRate)
        if FDB.IsLoggedIn then
            local ped = PlayerPedId()
            
            -- Dreno de Higiene Gradual e por Clima/Terreno
            local cleanlinessDrain = Config.DrainRates.Cleanliness
            if GetRainLevel() > 0.1 then
                cleanlinessDrain = cleanlinessDrain * Config.DrainRates.WeatherMultipliers.Rain
            end
            
            local currentHealth = GetEntityHealth(ped)
            if not FDB.Survival.lastHealth then FDB.Survival.lastHealth = currentHealth end
            
            if currentHealth < FDB.Survival.lastHealth then
                cleanlinessDrain = cleanlinessDrain + Config.DrainRates.DirtinessActions.BloodDamage
            end
            FDB.Survival.lastHealth = currentHealth
            
            if IsPedRagdoll(ped) or IsPedFalling(ped) then
                cleanlinessDrain = cleanlinessDrain + Config.DrainRates.DirtinessActions.FallMud
            end
            
            

            local oldCleanliness = FDB.Survival.cleanliness
            FDB.Survival.cleanliness = math.max(0, math.min(100, FDB.Survival.cleanliness - cleanlinessDrain))
            if math.floor(FDB.Survival.cleanliness) ~= math.floor(oldCleanliness) then
                FDB.BroadcastState('cleanliness', math.floor(FDB.Survival.cleanliness))
            end

            -- Aumento de Bexiga
            local bladderDrain = Config.DrainRates.Bladder
            local oldBladder = FDB.Survival.bladder
            FDB.Survival.bladder = math.min(100, FDB.Survival.bladder + bladderDrain)
            if math.floor(FDB.Survival.bladder) ~= math.floor(oldBladder) then
                FDB.BroadcastState('bladder', math.floor(FDB.Survival.bladder))
            end

            -- Dano por Veneno de Cobra Contínuo
            local isPoisoned = Citizen.InvokeNative(0x137772C61AEC7E11, ped)
            local oldPoison = FDB.Survival.poison
            if isPoisoned then
                FDB.Survival.poison = 100
                if GetEntityHealth(ped) > 0 and not IsEntityDead(ped) then
                    SetEntityHealth(ped, math.max(0, GetEntityHealth(ped) - Config.Hazards.PoisonDamage))
                end
            else
                FDB.Survival.poison = 0
            end
            if FDB.Survival.poison ~= oldPoison then
                FDB.BroadcastState('poison', FDB.Survival.poison)
            end

            -- Termorregulação (Dano em Temperatura Extrema)
            local coords = GetEntityCoords(ped)
            Citizen.InvokeNative(0xB98B78C3768AF6E0, true)
            local temp = GetTemperatureAtCoords(coords.x, coords.y, coords.z)
            
            -- Envia temp para o HUD
            FDB.BroadcastState('temp', math.floor(temp))
            
            local hasThermalProtection = false
            if temp < Config.Hazards.ExtremeColdThreshold and (FDB.Survival.coldResistance > 0 and not LocalPlayer.state.isWet) then
                hasThermalProtection = true
            elseif temp > Config.Hazards.ExtremeHeatThreshold and FDB.Survival.heatResistance > 0 then
                hasThermalProtection = true
            end
            
            if (temp < Config.Hazards.ExtremeColdThreshold or temp > Config.Hazards.ExtremeHeatThreshold) and not hasThermalProtection then
                -- No health damage purely for being wet, only temperature damage
                if GetEntityHealth(ped) > 0 and not IsEntityDead(ped) then
                    SetEntityHealth(ped, math.max(0, GetEntityHealth(ped) - Config.Hazards.TemperatureDamage))
                end
                
                local illnessMultiplier = LocalPlayer.state.isWet and 3 or 1
                if temp < Config.Hazards.ExtremeColdThreshold and math.random(1, 100) <= (Config.Hazards.IllnessChancePercent * illnessMultiplier) then
                    local oldIllness = FDB.Survival.illness
                    FDB.Survival.illness = math.min(100, FDB.Survival.illness + Config.Hazards.IllnessGain)
                    if math.floor(FDB.Survival.illness) ~= math.floor(oldIllness) then
                        FDB.BroadcastState('illness', math.floor(FDB.Survival.illness))
                    end
                end
            end
            
            -- Doença (Illness)
            if FDB.Survival.illness > Config.Hazards.IllnessSymptomThreshold then
                if math.random(1, 100) <= Config.Hazards.CoughChancePercent then
                    TaskStartScenarioInPlace(ped, joaat('WORLD_HUMAN_COUGH'), 3000, true, false, false, false)
                end
            end

            -- Salvar no banco a cada 16s (4 ticks)
            syncTimer = syncTimer + (Config.DrainRates.TickRate / 1000)
            if syncTimer >= 16 then
                syncTimer = 0
                -- Em fdb-survival, atualizamos apenas as vars q dominamos
                TriggerServerEvent('fdb-survival:server:SaveMeta', 'cleanliness', math.floor(FDB.Survival.cleanliness))
                TriggerServerEvent('fdb-survival:server:SaveMeta', 'bladder', math.floor(FDB.Survival.bladder))
                TriggerServerEvent('fdb-survival:server:SaveMeta', 'poison', math.floor(FDB.Survival.poison))
                TriggerServerEvent('fdb-survival:server:SaveMeta', 'illness', math.floor(FDB.Survival.illness))
            end
        end
    end
end)

-- =======================================================
-- LOOP DE STAMINA (Velocidade e Movimento)
-- =======================================================
local wasStaminaLow = false

CreateThread(function()
    while true do
        local sleep = 0
        if FDB.IsLoggedIn then
            local ped = PlayerPedId()
            local stamina = Citizen.InvokeNative(0x36731AC041289BB1, ped, 1) -- GetAttributeCoreValue for Stamina
            
            if stamina and stamina < 30 then
                wasStaminaLow = true
                -- Reduz a velocidade gradualmente
                local moveRate = 0.6 + (stamina / 75.0) -- 30 = 1.0, 0 = 0.6
                Citizen.InvokeNative(0x082B1D45D8C4EEBD, ped, moveRate) -- SetPedMoveRateOverride
                
                -- Se chegar quase a zero, bloqueia o sprint completamente
                if stamina < 5 then
                    DisableControlAction(0, 0x8FFC75D6, true) -- INPUT_SPRINT
                    DisableControlAction(0, 0xE30CD707, true) -- INPUT_RUN
                    SetPedMaxMoveBlendRatio(ped, 2.0) -- SetPedMaxMoveBlendRatio (trote no max)
                else
                    SetPedMaxMoveBlendRatio(ped, 3.0)
                end
            else
                if wasStaminaLow then
                    wasStaminaLow = false
                    Citizen.InvokeNative(0x082B1D45D8C4EEBD, ped, 1.0)
                    SetPedMaxMoveBlendRatio(ped, 3.0)
                end
                sleep = 500
            end
        else
            sleep = 1000
        end
        Wait(sleep)
    end
end)
