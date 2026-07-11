local RSGCore = exports['rsg-core']:GetCoreObject()

for _itemName, _ammoType in pairs(Config.BoxAmmo) do
    RSGCore.Functions.CreateUseableItem(_itemName, function(source, item)
        local src = source
        local Player = RSGCore.Functions.GetPlayer(src)
        if not Player then return end
        TriggerClientEvent('fdb-ammo:client:openAmmoBox', src, item.name, _ammoType, Config.AmmoTypes[_ammoType].refill, item.slot)
    end)
end

------------------------------------------
-- use arrow ammo
------------------------------------------
local function useArrowItem(source, item, ammoType)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local amount = Config.AmmoTypes[ammoType].refill
    local canAddAmmo = lib.callback.await('fdb-ammo:client:CanAddAmmo', src, ammoType, amount)
    if canAddAmmo then
        -- Only give ammo if item removal actually succeeded (prevents exploit)
        if not Player.Functions.RemoveItem(item.name, 1, item.slot) then return end
        TriggerClientEvent('fdb-ammo:client:AddAmmo', src, ammoType, amount)
    end
end

local arrowTypes = {
    ammo_arrow = 'AMMO_ARROW',
    ammo_arrow_small = 'AMMO_ARROW_SMALL_GAME',
    ammo_arrow_fire = 'AMMO_ARROW_FIRE',
    ammo_arrow_poison = 'AMMO_ARROW_POISON',
    ammo_arrow_dynamite = 'AMMO_ARROW_DYNAMITE'
}

for itemName, ammoType in pairs(arrowTypes) do
    RSGCore.Functions.CreateUseableItem(itemName, function(source, item)
        useArrowItem(source, item, ammoType)
    end)
end

---------------------------------------------
-- remove item
---------------------------------------------
RegisterServerEvent('fdb-ammo:server:removeitem')
AddEventHandler('fdb-ammo:server:removeitem', function(item, amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    -- Only notify client if removal actually succeeded
    if not Player.Functions.RemoveItem(item, amount) then return end
    TriggerClientEvent('fdb-inventory:client:ItemBox', src, RSGCore.Shared.Items[item], 'remove', amount)
end)

---------------------------------------------
-- open ammo box
-- SECURITY: ammoType validated server-side against Config.AmmoTypes.
-- Client-supplied `amount` is ignored; only Config.AmmoTypes[ammoType].refill is used.
-- Ammo is only granted if RemoveItem succeeds (item must exist in inventory).
---------------------------------------------
RegisterServerEvent('fdb-ammo:server:openAmmoBox')
AddEventHandler('fdb-ammo:server:openAmmoBox', function(ammoBoxItem, ammoType, amount, slot)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Validate ammoType against server config (never trust client-supplied values)
    local ammoConfig = Config.AmmoTypes[ammoType]
    if not ammoConfig then return end
    local realAmount = ammoConfig.refill  -- ignore client-supplied amount entirely

    -- Only grant ammo if item removal actually succeeded
    if not Player.Functions.RemoveItem(ammoBoxItem, 1, slot) then return end

    TriggerClientEvent('fdb-inventory:client:ItemBox', src, RSGCore.Shared.Items[ammoBoxItem], 'remove', 1)
    TriggerClientEvent('fdb-ammo:client:AddAmmo', src, ammoType, realAmount)
end)

RSGCore.Functions.CreateCallback('fdb-ammo:server:initializeDb', function(source, cb)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    if not citizenid then return end
    MySQL.single('SELECT * FROM player_ammo WHERE citizenid = ? LIMIT 1', {
        citizenid
    }, function(row)
        if not row then
            MySQL.insert.await('INSERT INTO player_ammo (citizenid) VALUES (?)', {
                citizenid
            })
            row = MySQL.single.await('SELECT * FROM player_ammo WHERE citizenid = ? LIMIT 1', {
                citizenid
            })
        end
     
        cb(row)
    end)
end)

RegisterServerEvent('fdb-ammo:server:updateDb')
AddEventHandler('fdb-ammo:server:updateDb', function(update)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    if next(update) then 
        local setClauses = {}
        local params = {}
        for column, value in pairs(update) do
            table.insert(setClauses, column .. " = @" .. column)
            params["@" .. column] = value
        end
    
        local sql = "UPDATE player_ammo SET " .. table.concat(setClauses, ", ") .. " WHERE citizenid = @citizenid"
        params["@citizenid"] = Player.PlayerData.citizenid
    
        MySQL.Sync.execute(sql, params)
    end
end)
