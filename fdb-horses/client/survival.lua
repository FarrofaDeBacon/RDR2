local RSGCore = exports['rsg-core']:GetCoreObject()

FDB = FDB or {}
FDB.HorseSurvival = {
    hunger = 100,
    thirst = 100,
    dirt = 0,
    illness = 0,
    poison = 0,
    agitation = 0
}

local activeHorsePed = 0

-- Inicializa/Sincroniza do banco de dados (metadata) quando um cavalo Ã© spawnado
RegisterNetEvent('fdb-horses:client:ApplySurvivalData', function(horse, metadata)
    activeHorsePed = horse
    if metadata then
        FDB.HorseSurvival.hunger = metadata.hunger or 100
        FDB.HorseSurvival.thirst = metadata.thirst or 100
        FDB.HorseSurvival.dirt = metadata.dirt or 0
        FDB.HorseSurvival.illness = metadata.illness or 0
        FDB.HorseSurvival.poison = metadata.poison or 0
        FDB.HorseSurvival.agitation = metadata.agitation or 0
    else
        -- Defaults
        FDB.HorseSurvival = { hunger = 100, thirst = 100, dirt = 0, illness = 0, poison = 0, agitation = 0 }
    end
    
    -- Inicializa o visual de sujeira baseado no salvo
    if activeHorsePed and activeHorsePed ~= 0 then
        Citizen.InvokeNative(0x5DA12E025D47D4E5, activeHorsePed, 16, FDB.HorseSurvival.dirt)
        Entity(activeHorsePed).state:set('survivalData', FDB.HorseSurvival, true)
    end
end)

-- Desvincula o cavalo quando estabulado/morto
RegisterNetEvent('fdb-horses:client:ClearSurvivalData', function()
    activeHorsePed = 0
end)

-- Loop Mestre de Metabolismo (Dono Ãšnico)
CreateThread(function()
    while true do
        Wait(Config.Metabolism.DrainInterval)
        
        if activeHorsePed ~= 0 and DoesEntityExist(activeHorsePed) and not IsEntityDead(activeHorsePed) then
            local changed = false
            
            -- Dreno de Fome e Sede
            if FDB.HorseSurvival.hunger > 0 then
                FDB.HorseSurvival.hunger = FDB.HorseSurvival.hunger - Config.Metabolism.HungerDrain
                if FDB.HorseSurvival.hunger < 0 then FDB.HorseSurvival.hunger = 0 end
                changed = true
            end
            
            if FDB.HorseSurvival.thirst > 0 then
                FDB.HorseSurvival.thirst = FDB.HorseSurvival.thirst - Config.Metabolism.ThirstDrain
                if FDB.HorseSurvival.thirst < 0 then FDB.HorseSurvival.thirst = 0 end
                changed = true
            end
            
            -- Sujeira (Dirt) Nativa
            local nativeDirt = Citizen.InvokeNative(0x147149F2E909323C, activeHorsePed, 16, Citizen.ResultAsInteger())
            if not nativeDirt then nativeDirt = 0 end
            
            -- Sujeira passiva
            local newDirt = math.min(100, nativeDirt + Config.Metabolism.DirtAccumulation)
            if newDirt ~= nativeDirt then
                Citizen.InvokeNative(0x5DA12E025D47D4E5, activeHorsePed, 16, math.floor(newDirt))
            end
            
            if FDB.HorseSurvival.dirt ~= math.floor(newDirt) then
                FDB.HorseSurvival.dirt = math.floor(newDirt)
                changed = true
            end
            
            -- LÃ³gica de DoenÃ§a por Sujeira Extrema
            if FDB.HorseSurvival.dirt >= 90 then
                if math.random(1, 100) <= 2 then -- 2% de chance a cada tick de pegar doenÃ§a se muito sujo
                    if FDB.HorseSurvival.illness < 100 then
                        FDB.HorseSurvival.illness = FDB.HorseSurvival.illness + 10
                        changed = true
                        RSGCore.Functions.Notify("Seu cavalo parece doente por falta de higiene.", "error")
                    end
                end
            end
            
            -- Decaimento de AgitaÃ§Ã£o
            if FDB.HorseSurvival.agitation > 0 then
                FDB.HorseSurvival.agitation = math.max(0, FDB.HorseSurvival.agitation - Config.Metabolism.AgitationDecay)
                changed = true
            end
            
            -- Atualiza Statebag
            if changed then
                Entity(activeHorsePed).state:set('survivalData', FDB.HorseSurvival, true)
            end
            
            -- Efeitos FÃ­sicos da Fome/Sede/DoenÃ§a/Veneno
            local health = GetEntityHealth(activeHorsePed)
            local maxHealth = GetEntityMaxHealth(activeHorsePed)
            
            if FDB.HorseSurvival.hunger == 0 or FDB.HorseSurvival.thirst == 0 or FDB.HorseSurvival.poison > 0 then
                -- Dreno de vida
                if health > 0 then
                    SetEntityHealth(activeHorsePed, health - 1)
                end
            end
            
            if FDB.HorseSurvival.illness > 0 then
                -- Dreno de Stamina Core (aqui consumimos o core nativamente se ele estiver doente)
                local currentStaminaCore = Citizen.InvokeNative(0x36731AC041289BB1, activeHorsePed, 1)
                if tonumber(currentStaminaCore) and currentStaminaCore > 5.0 then
                    Citizen.InvokeNative(0xC6258F41D86676E0, activeHorsePed, 1, currentStaminaCore - 5.0)
                end
            end
        end
    end
end)

-- FunÃ§Ãµes Auxiliares para Consumo de Itens
RegisterNetEvent('fdb-horses:client:Feed', function(amount)
    if activeHorsePed == 0 then return end
    FDB.HorseSurvival.hunger = math.min(100, FDB.HorseSurvival.hunger + amount)
    FDB.HorseSurvival.agitation = math.max(0, FDB.HorseSurvival.agitation - 20)
    Entity(activeHorsePed).state:set('survivalData', FDB.HorseSurvival, true)
    RSGCore.Functions.Notify("O cavalo parece mais satisfeito.", "success")
end)

RegisterNetEvent('fdb-horses:client:Drink', function(amount)
    if activeHorsePed == 0 then return end
    FDB.HorseSurvival.thirst = math.min(100, FDB.HorseSurvival.thirst + amount)
    FDB.HorseSurvival.agitation = math.max(0, FDB.HorseSurvival.agitation - 20)
    Entity(activeHorsePed).state:set('survivalData', FDB.HorseSurvival, true)
    RSGCore.Functions.Notify("O cavalo bebeu Ã¡gua.", "success")
end)

RegisterNetEvent('fdb-horses:client:Cure', function(type)
    if activeHorsePed == 0 then return end
    if type == "illness" then
        FDB.HorseSurvival.illness = 0
        RSGCore.Functions.Notify("O cavalo se recuperou da doenÃ§a.", "success")
    elseif type == "poison" then
        FDB.HorseSurvival.poison = 0
        RSGCore.Functions.Notify("O veneno foi neutralizado.", "success")
    end
    Entity(activeHorsePed).state:set('survivalData', FDB.HorseSurvival, true)
end)

RegisterNetEvent('fdb-horses:client:Clean', function()
    if activeHorsePed == 0 then return end
    FDB.HorseSurvival.dirt = 0
    Citizen.InvokeNative(0x5DA12E025D47D4E5, activeHorsePed, 16, 0)
    ClearPedEnvDirt(activeHorsePed)
    Entity(activeHorsePed).state:set('survivalData', FDB.HorseSurvival, true)
    RSGCore.Functions.Notify("O cavalo estÃ¡ limpo.", "success")
end)

-- Sincroniza periodicamente com o Servidor (a cada 30 segundos)
CreateThread(function()
    while true do
        Wait(30000)
        if activeHorsePed ~= 0 then
            TriggerServerEvent('fdb-horses:server:UpdateMetadata', FDB.HorseSurvival)
        end
    end
end)
