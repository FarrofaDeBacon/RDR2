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

local function SyncLocalMetadata()
    local PlayerData = RSGCore.Functions.GetPlayerData()
    if PlayerData and PlayerData.metadata then
        FDB.Survival.bladder = PlayerData.metadata["bladder"] or 0
        FDB.Survival.cleanliness = PlayerData.metadata["cleanliness"] or 100
        FDB.Survival.poison = PlayerData.metadata["poison"] or 0
        FDB.Survival.illness = PlayerData.metadata["illness"] or 0
    end
end

RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    FDB.IsLoggedIn = true
    SyncLocalMetadata()
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
            SyncLocalMetadata()
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
            
            local oldCleanliness = FDB.Survival.cleanliness
            FDB.Survival.cleanliness = math.max(0, FDB.Survival.cleanliness - cleanlinessDrain)
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
            
            local hasThermalProtection = false
            if temp < Config.Hazards.ExtremeColdThreshold and FDB.Survival.coldResistance > 0 then
                hasThermalProtection = true
            elseif temp > Config.Hazards.ExtremeHeatThreshold and FDB.Survival.heatResistance > 0 then
                hasThermalProtection = true
            end
            
            if (temp < Config.Hazards.ExtremeColdThreshold or temp > Config.Hazards.ExtremeHeatThreshold) and not hasThermalProtection then
                if GetEntityHealth(ped) > 0 and not IsEntityDead(ped) then
                    SetEntityHealth(ped, math.max(0, GetEntityHealth(ped) - Config.Hazards.TemperatureDamage))
                end
                
                if temp < Config.Hazards.ExtremeColdThreshold and math.random(1, 100) <= Config.Hazards.IllnessChancePercent then
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
