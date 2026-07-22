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


