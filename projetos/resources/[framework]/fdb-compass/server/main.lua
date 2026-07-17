local RSGCore = exports['rsg-core']:GetCoreObject()

local equipped = {} -- [citizenid] = { compass = bool }

-- -------------------------------------------------------
-- Helper: Verifica posse real do item (bolso ou satchel)
-- -------------------------------------------------------
local function HasValidItem(Player, itemName)
    -- 1. Procura no inventario principal (bolso)
    for _, item in pairs(Player.PlayerData.items) do
        if item and item.name == itemName then
            return true
        end
    end

    -- 2. Procura no satchel equipado
    local equip = Player.PlayerData.metadata.equipmentSlots or {}
    if equip.satchel then
        local stashId = equip.satchel.stashId or (equip.satchel.info and equip.satchel.info.stashId)
        if stashId then
            local stashInventory = exports['rsg-inventory']:GetInventory(stashId)
            local stashItems = stashInventory and stashInventory.items or {}
            for _, item in pairs(stashItems) do
                if item and item.name == itemName then
                    return true
                end
            end
        end
    end

    return false
end

-- -------------------------------------------------------
-- Registrar os useable items (toggle de equipar)
-- -------------------------------------------------------
RSGCore.Functions.CreateUseableItem(Config.Compass.itemName, function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    
    equipped[cid] = equipped[cid] or { compass = false }
    
    -- Só permite equipar se possuir o item válido
    local hasCompass = HasValidItem(Player, Config.Compass.itemName)
    if not hasCompass then
        equipped[cid].compass = false
        TriggerClientEvent('fdb-compass:client:equipUpdate', source, false)
        return
    end

    equipped[cid].compass = not equipped[cid].compass
    TriggerClientEvent('fdb-compass:client:equipUpdate', source, equipped[cid].compass)
end)

-- -------------------------------------------------------
-- Checagem periodica de posse de itens (7s)
-- -------------------------------------------------------
CreateThread(function()
    while true do
        Wait(7000)
        for _, playerId in ipairs(GetPlayers()) do
            local src = tonumber(playerId)
            local Player = RSGCore.Functions.GetPlayer(src)
            if Player then
                local cid = Player.PlayerData.citizenid
                equipped[cid] = equipped[cid] or { compass = false }

                local hasCompass = HasValidItem(Player, Config.Compass.itemName)

                if not hasCompass then equipped[cid].compass = false end

                TriggerClientEvent('fdb-compass:client:itemGatedUpdate', src, hasCompass)
            end
        end
    end
end)
