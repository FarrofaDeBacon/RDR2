local RSGCore = exports['rsg-core']:GetCoreObject()

FDB = FDB or {}
FDB.HorseSurvival = {
    hunger     = 100,
    thirst     = 100,
    dirt       = 0,
    illness    = 0,
    poison     = 0,
    agitation  = 0
}

local activeHorsePed = 0

-- ============================================================
-- ÚNICO LISTENER QUE ESCREVE EM FDB.HorseSurvival
-- Disparado exclusivamente pelo servidor via TriggerClientEvent
-- Nenhum outro arquivo escreve aqui.
-- ============================================================
RegisterNetEvent('fdb-horses:client:stateChanged', function(data)
    if not data then return end
    for field, value in pairs(data) do
        if FDB.HorseSurvival[field] ~= nil then
            FDB.HorseSurvival[field] = value
        end
    end
end)

-- ============================================================
-- Vincula / desvincula o cavalo ativo ao receber spawn/despawn
-- ============================================================
RegisterNetEvent('fdb-horses:client:ApplySurvivalData', function(horse, metadata)
    activeHorsePed = horse
    if metadata then
        for field, _ in pairs(FDB.HorseSurvival) do
            FDB.HorseSurvival[field] = metadata[field] or FDB.HorseSurvival[field]
        end
    else
        FDB.HorseSurvival = { hunger = 100, thirst = 100, dirt = 0, illness = 0, poison = 0, agitation = 0 }
    end
    -- Aplica sujeira visual do valor salvo
    if activeHorsePed and activeHorsePed ~= 0 then
        Citizen.InvokeNative(0x5DA12E025D47D4E5, activeHorsePed, 16, math.floor(FDB.HorseSurvival.dirt))
    end
end)

RegisterNetEvent('fdb-horses:client:ClearSurvivalData', function()
    activeHorsePed = 0
end)

-- ============================================================
-- Funções de leitura pública (somente leitura — sem escrita)
-- Outros arquivos chamam isso em vez de acessar FDB.HorseSurvival diretamente
-- ============================================================
function GetHorseSurvival(field)
    if field then return FDB.HorseSurvival[field] end
    return FDB.HorseSurvival
end

function GetActiveHorsePed()
    return activeHorsePed
end

-- ============================================================
-- Loop mestre de metabolismo (Dono Único — só esse loop drena)
-- ============================================================
CreateThread(function()
    while true do
        Wait(Config.Metabolism.DrainInterval)
        if activeHorsePed ~= 0 and DoesEntityExist(activeHorsePed) and not IsEntityDead(activeHorsePed) then

            -- Dreno passivo de fome e sede (client calcula, servidor persiste)
            local hungerDelta = -Config.Metabolism.HungerDrain
            local thirstDelta = -Config.Metabolism.ThirstDrain

            local newHunger = math.max(0, FDB.HorseSurvival.hunger + hungerDelta)
            local newThirst = math.max(0, FDB.HorseSurvival.thirst + thirstDelta)

            FDB.HorseSurvival.hunger = newHunger
            FDB.HorseSurvival.thirst = newThirst

            -- Sujeira nativa + acúmulo passivo
            local nativeDirt = tonumber(Citizen.InvokeNative(0x147149F2E909323C, activeHorsePed, 16, Citizen.ResultAsInteger())) or FDB.HorseSurvival.dirt
            local newDirt = math.min(100, nativeDirt + Config.Metabolism.DirtAccumulation)
            if newDirt ~= FDB.HorseSurvival.dirt then
                Citizen.InvokeNative(0x5DA12E025D47D4E5, activeHorsePed, 16, math.floor(newDirt))
                FDB.HorseSurvival.dirt = math.floor(newDirt)
            end

            -- Doença por sujeira extrema: chance aleatória server-side
            -- (dispara evento pro servidor decidir; o client não escreve illness diretamente)
            if FDB.HorseSurvival.dirt >= 90 and FDB.HorseSurvival.illness == 0 then
                TriggerServerEvent('fdb-horses:server:CheckDirtIllness')
            end

            -- Efeitos físicos (cliente aplica consequências visuais, não valores numéricos)
            if FDB.HorseSurvival.hunger == 0 or FDB.HorseSurvival.thirst == 0 then
                local health = GetEntityHealth(activeHorsePed)
                if health > 0 then SetEntityHealth(activeHorsePed, health - 1) end
            end

            if FDB.HorseSurvival.illness > 0 then
                local stamina = tonumber(Citizen.InvokeNative(0x36731AC041289BB1, activeHorsePed, 1)) or 0
                if stamina > 5.0 then
                    Citizen.InvokeNative(0xC6258F41D86676E0, activeHorsePed, 1, stamina - 5.0)
                end
            end
        end
    end
end)

-- ============================================================
-- Sincronização periódica com o servidor (a cada 30s)
-- O servidor persiste o snapshot atual no metadata do banco
-- ============================================================
CreateThread(function()
    while true do
        Wait(30000)
        if activeHorsePed ~= 0 then
            TriggerServerEvent('fdb-horses:server:PersistMetadata', FDB.HorseSurvival)
        end
    end
end)
