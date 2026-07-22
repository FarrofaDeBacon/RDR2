local RSGCore = exports['rsg-core']:GetCoreObject()

-- -------------------------------------------------------
-- Registro de Itens Utilizáveis (Consumíveis de Sobrevivência)
-- -------------------------------------------------------

-- 1. Sopas/Alimentos Quentes (Dão coldResistance)
RSGCore.Functions.CreateUseableItem('hot_soup', function(source, item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[item.name], "remove")
        TriggerClientEvent('fdb-survival:client:EatThermalItem', src, 'cold', Config.Buffs.ThermalDuration)
    end
end)

-- 2. Bebidas Geladas (Dão heatResistance)
RSGCore.Functions.CreateUseableItem('cold_drink', function(source, item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[item.name], "remove")
        TriggerClientEvent('fdb-survival:client:EatThermalItem', src, 'heat', Config.Buffs.ThermalDuration)
        
        -- Aumenta a bexiga
        local currentBladder = Player.PlayerData.metadata["bladder"] or 0
        Player.Functions.SetMetaData("bladder", math.min(100, currentBladder + 40))
    end
end)

-- 3. Antídoto contra Veneno
RSGCore.Functions.CreateUseableItem('antidote', function(source, item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[item.name], "remove")
        TriggerClientEvent('fdb-survival:client:CurePoison', src)
        Player.Functions.SetMetaData("poison", 0)
    end
end)

-- 4. Remédio para Gripe/Resfriado
RSGCore.Functions.CreateUseableItem('medicine', function(source, item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[item.name], "remove")
        TriggerClientEvent('fdb-survival:client:CureIllness', src)
        Player.Functions.SetMetaData("illness", 0)
    end
end)

-- -------------------------------------------------------
-- Sincronização de Metadados via Tick
-- -------------------------------------------------------
RegisterNetEvent('fdb-survival:server:SaveMeta', function(meta, value)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    if meta == 'cleanliness' or meta == 'bladder' or meta == 'poison' or meta == 'illness' then
        Player.Functions.SetMetaData(meta, value)
    end
end)

-- -------------------------------------------------------
-- EXPORTS DE MANIPULAÇÃO DIRETA
-- -------------------------------------------------------
exports('AddBladder', function(src, amount)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local current = Player.PlayerData.metadata["bladder"] or 0
    Player.Functions.SetMetaData("bladder", math.max(0, math.min(100, current + amount)))
end)

exports('AddCleanliness', function(src, amount)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local current = Player.PlayerData.metadata["cleanliness"] or 100
    Player.Functions.SetMetaData("cleanliness", math.max(0, math.min(100, current + amount)))
end)

exports('CurePoison', function(src)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    Player.Functions.SetMetaData("poison", 0)
    TriggerClientEvent('fdb-survival:client:CurePoison', src)
end)

exports('CureIllness', function(src)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    Player.Functions.SetMetaData("illness", 0)
    TriggerClientEvent('fdb-survival:client:CureIllness', src)
end)

exports('AddColdResistance', function(src, seconds)
    TriggerClientEvent('fdb-survival:client:EatThermalItem', src, 'cold', seconds)
end)

exports('AddHeatResistance', function(src, seconds)
    TriggerClientEvent('fdb-survival:client:EatThermalItem', src, 'heat', seconds)
end)
