-- ============================================================
-- fdb-hudpremium | server/main.lua
-- Callbacks, sincronização de metadados e lógica de itens (Lua-3)
-- ============================================================

local RSGCore = exports['rsg-core']:GetCoreObject()

-- -------------------------------------------------------
-- Sincronização de Metadados de Metabolismo
-- -------------------------------------------------------
RegisterServerEvent('fdb-hudpremium:server:updateMetas')
AddEventHandler('fdb-hudpremium:server:updateMetas', function(hunger, thirst, stress, urine, alcohol, hygiene, poison, illness)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    if hunger then Player.Functions.SetMetaData("hunger", hunger) end
    if thirst then Player.Functions.SetMetaData("thirst", thirst) end
    if stress then Player.Functions.SetMetaData("stress", stress) end
    if urine then Player.Functions.SetMetaData("bladder", urine) end
    if alcohol then Player.Functions.SetMetaData("alcohol", alcohol) end
    
    -- Metadados customizados adicionais para persistência
    if hygiene then Player.Functions.SetMetaData("hygiene", hygiene) end
    if poison then Player.Functions.SetMetaData("poison", poison) end
    if illness then Player.Functions.SetMetaData("illness", illness) end
end)

-- -------------------------------------------------------
-- Callbacks de Consumíveis da UI/Client
-- -------------------------------------------------------
RegisterServerEvent('fdb-hudpremium:server:UpdateThirstBladder')
AddEventHandler('fdb-hudpremium:server:UpdateThirstBladder', function(amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local currentThirst = Player.PlayerData.metadata["thirst"] or 100
    local newThirst = math.min(100, currentThirst + amount)
    Player.Functions.SetMetaData("thirst", newThirst)

    -- Consumo de líquido aumenta a bexiga
    local currentBladder = Player.PlayerData.metadata["bladder"] or 0
    local newBladder = math.min(100, currentBladder + (amount * 1.25))
    Player.Functions.SetMetaData("bladder", newBladder)
end)

RegisterServerEvent('fdb-hudpremium:server:UpdateHunger')
AddEventHandler('fdb-hudpremium:server:UpdateHunger', function(amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local currentHunger = Player.PlayerData.metadata["hunger"] or 100
    local newHunger = math.min(100, currentHunger + amount)
    Player.Functions.SetMetaData("hunger", newHunger)
end)

RegisterServerEvent('fdb-hudpremium:server:UpdateAlcohol')
AddEventHandler('fdb-hudpremium:server:UpdateAlcohol', function(amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local currentAlcohol = Player.PlayerData.metadata["alcohol"] or 0
    local newAlcohol = math.max(0, math.min(100, currentAlcohol + amount))
    Player.Functions.SetMetaData("alcohol", newAlcohol)
end)

RegisterServerEvent('fdb-hudpremium:server:RelieveStress')
AddEventHandler('fdb-hudpremium:server:RelieveStress', function(amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local currentStress = Player.PlayerData.metadata["stress"] or 0
    local newStress = math.max(0, currentStress - amount)
    Player.Functions.SetMetaData("stress", newStress)
end)

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
        TriggerClientEvent('fdb-hudpremium:client:EatThermalItem', src, 'cold', 180) -- 180 segundos de Cold Resistance
        
        -- Alimenta
        local currentHunger = Player.PlayerData.metadata["hunger"] or 100
        Player.Functions.SetMetaData("hunger", math.min(100, currentHunger + 35))
    end
end)

-- 2. Bebidas Geladas (Dão heatResistance)
RSGCore.Functions.CreateUseableItem('cold_drink', function(source, item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[item.name], "remove")
        TriggerClientEvent('fdb-hudpremium:client:EatThermalItem', src, 'heat', 180) -- 180 segundos de Heat Resistance
        
        -- Mata a sede e aumenta a bexiga
        local currentThirst = Player.PlayerData.metadata["thirst"] or 100
        local currentBladder = Player.PlayerData.metadata["bladder"] or 0
        Player.Functions.SetMetaData("thirst", math.min(100, currentThirst + 30))
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
        TriggerClientEvent('fdb-hudpremium:client:CurePoison', src)
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
        TriggerClientEvent('fdb-hudpremium:client:CureIllness', src)
        Player.Functions.SetMetaData("illness", 0)
    end
end)

-- 5. Bebidas Alcoólicas (Uísque / Whiskey)
RSGCore.Functions.CreateUseableItem('whiskey', function(source, item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    if Player.Functions.RemoveItem(item.name, 1, item.slot) then
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[item.name], "remove")
        
        local currentAlcohol = Player.PlayerData.metadata["alcohol"] or 0
        local currentThirst = Player.PlayerData.metadata["thirst"] or 100
        local currentBladder = Player.PlayerData.metadata["bladder"] or 0

        Player.Functions.SetMetaData("alcohol", math.min(100, currentAlcohol + 25))
        Player.Functions.SetMetaData("thirst", math.min(100, currentThirst + 15))
        Player.Functions.SetMetaData("bladder", math.min(100, currentBladder + 30))
        
        TriggerClientEvent('fdb-hudpremium:client:DrinkAlcohol', src, 25)
    end
end)
