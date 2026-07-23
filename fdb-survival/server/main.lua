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
-- Sincronização de Metadados via Tick (com validação server-side)
-- -------------------------------------------------------
local allowedMetas = {
    cleanliness = true,
    bladder = true,
    poison = true,
    illness = true
}

local lastSaveTime = {} -- [src][meta] = timestamp

RegisterNetEvent('fdb-survival:server:SaveMeta', function(meta, value)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    if not allowedMetas[meta] then
        print(("[fdb-survival] SaveMeta rejeitado: meta inválido '%s' de src %s"):format(tostring(meta), src))
        return
    end

    if type(value) ~= 'number' then
        print(("[fdb-survival] SaveMeta rejeitado: value não-numérico de src %s"):format(src))
        return
    end

    -- Rate limit per meta (cliente envia os 4 ao mesmo tempo a cada 16s)
    local now = os.time()
    if not lastSaveTime[src] then lastSaveTime[src] = {} end
    
    if lastSaveTime[src][meta] and (now - lastSaveTime[src][meta]) < 10 then
        print(("[fdb-survival] SaveMeta rejeitado: rate limit de src %s para meta %s"):format(src, meta))
        return
    end

    local safeValue = math.floor(math.max(0, math.min(100, value)))

    local maxDeltaPerSync = {
        cleanliness = 40, -- cobre o pior caso plausível de sangue+lama dentro da janela de 16s
        bladder = 5
    }
    if maxDeltaPerSync[meta] then
        local current = Player.PlayerData.metadata[meta] or 0
        local delta = math.abs(safeValue - current)
        if delta > maxDeltaPerSync[meta] then
            print(("[fdb-survival] SaveMeta limitado: delta de %d (acima do max de %d) em '%s' de src %s (citizenid: %s)"):format(delta, maxDeltaPerSync[meta], meta, src, Player.PlayerData.citizenid))
            safeValue = math.floor(math.max(0, math.min(100, current + (safeValue > current and maxDeltaPerSync[meta] or -maxDeltaPerSync[meta]))))
        end
    end

    lastSaveTime[src][meta] = now
    Player.Functions.SetMetaData(meta, safeValue)
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    lastSaveTime[src] = nil
end)

-- -------------------------------------------------------
-- EXPORTS DE MANIPULAÇÃO DIRETA
-- -------------------------------------------------------
RegisterNetEvent('fdb-survival:server:ForceClean', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    Player.Functions.SetMetaData("cleanliness", 100)
end)
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
