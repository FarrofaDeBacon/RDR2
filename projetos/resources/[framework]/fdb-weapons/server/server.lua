local RSGCore = exports['rsg-core']:GetCoreObject()

lib.locale()
------------------------------------
-- callback to get weapon info
-----------------------------------
RSGCore.Functions.CreateCallback('fdb-weapons:server:getweaponinfo', function(source, cb, weaponserial)
-- lib.callback.register('fdb-weapons:server:getweaponinfo', function(source, cb, weaponserial)
    local weaponinfo = MySQL.query.await('SELECT * FROM player_weapons WHERE serial=@weaponserial', { ['@weaponserial'] = weaponserial })
    if weaponinfo[1] == nil then return end
    cb(weaponinfo)
end)

-----------------------------------
-- Degrade Weapon
-----------------------------------
local cooldowns = {}

local function isRateLimited(src)
    local now = GetGameTimer()
    if cooldowns[src] and now - cooldowns[src] < 100 then
        return true
    end
    cooldowns[src] = now
    return false
end

RegisterNetEvent('fdb-weapons:server:degradeWeapon', function(degradationQueue) 
    local src = source
    if isRateLimited(src) then return end

    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then 
        return 
    end
    local items = Player.PlayerData.items
    local hasChanged = false
    for serial, shotCount in pairs(degradationQueue) do
        if type(serial) ~= 'string' or #serial > 32 then return end
        local capped = math.min(shotCount or 0, 10)
        if capped <= 0 then return end

        local svslot = nil
        for _, v in pairs(items) do
            if v.type == 'weapon' and v.info.serie == serial then
                svslot = v.slot
                break 
            end
        end
        if svslot and items[svslot] then
            local totalDegradation = (Config.DegradeRate * capped)
            local currentQuality = items[svslot].info.quality
            local newQuality = currentQuality - totalDegradation

            if newQuality <= 0 then
                newQuality = 0
                items[svslot].info.quality = newQuality
                TriggerClientEvent('fdb-weapons:client:UseWeapon', src, items[svslot])
            else
                items[svslot].info.quality = newQuality
            end
            
            hasChanged = true
        end
    end
    if hasChanged then
        Player.Functions.SetInventory(items)
    end
end)
------------------------------------------
-- use weapon repair kit
------------------------------------------
RSGCore.Functions.CreateUseableItem('weapon_repair_kit', function(source, item)
    TriggerClientEvent('fdb-weapons:client:repairweapon', source)
end)

-----------------------------------
-- repair weapon
-----------------------------------
RegisterNetEvent('fdb-weapons:server:repairweapon', function(serie)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local kitCount = 0
    for _, v in pairs(Player.PlayerData.items) do
        if v.name == 'weapon_repair_kit' then
            kitCount = kitCount + (v.amount or 1)
        end
    end
    if kitCount < 1 then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('cl_item_need'), type = 'error', duration = 5000 })
        return
    end
    Player.Functions.RemoveItem('weapon_repair_kit', 1)

    local svslot = nil
    for _, v in pairs(Player.PlayerData.items) do
        if v.type == 'weapon' and v.info.serie == serie then
            svslot = v.slot
            break
        end
    end
    if not svslot then
        Player.Functions.AddItem('weapon_repair_kit', 1)
        return
    end

    Player.PlayerData.items[svslot].info.quality = 100
    Player.Functions.SetInventory(Player.PlayerData.items)
    TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_weapon_repaired'), type = 'success', duration = 5000 })
end)

---------------------------------------------
-- remove item
---------------------------------------------
RegisterServerEvent('fdb-weapons:server:removeitem')
AddEventHandler('fdb-weapons:server:removeitem', function(item, amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    if not RSGCore.Shared.Items[item] then return end
    local count = 0
    for _, v in pairs(Player.PlayerData.items) do
        if v.name == item then
            count = count + (v.amount or 1)
        end
    end
    if count < (amount or 1) then return end
    Player.Functions.RemoveItem(item, amount)
    TriggerClientEvent('fdb-inventory:client:ItemBox', src, RSGCore.Shared.Items[item], 'remove', amount)
end)

---------------------------------------------
-- Force remove weapon (called when server-side ownership validation fails,
-- or by fdb-inventory when a weapon item leaves the player's possession
-- while it is still equipped in-hand)
---------------------------------------------
local function ForceRemoveWeapon(source, serial)
    if not serial then return end
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player then
        local equippedWeapons = Player.PlayerData.metadata.equippedweapons or {}
        equippedWeapons[serial] = nil
        Player.Functions.SetMetaData('equippedweapons', equippedWeapons)
    end
    TriggerClientEvent('fdb-weapons:client:forceRemoveWeapon', source, serial)
end
exports('ForceRemoveWeapon', ForceRemoveWeapon)

-- Allows fdb-inventory (or any other resource) to request a forced removal
-- without needing a direct export dependency
RegisterServerEvent('fdb-weapons:server:forceRemoveWeapon')
AddEventHandler('fdb-weapons:server:forceRemoveWeapon', function(serial)
    ForceRemoveWeapon(source, serial)
end)

RegisterNetEvent('fdb-weapons:server:saveEquippedWeapon', function(weaponData, isEquipped)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    if type(weaponData) ~= 'table' or type(weaponData.info) ~= 'table' then return end

    if isEquipped then
        local found = false
        for _, v in pairs(Player.PlayerData.items) do
            if v.type == 'weapon' and v.info and v.info.serie == weaponData.info.serie then
                found = true
                break
            end
        end
        if not found then
            local metadata = Player.PlayerData.metadata
            local equip = metadata.equipmentSlots or {}
            local stashesToCheck = {}
            if equip.satchel then table.insert(stashesToCheck, equip.satchel.stashId) end
            if equip.holster then table.insert(stashesToCheck, equip.holster.stashId) end
            if metadata.equippedBackpack then table.insert(stashesToCheck, metadata.equippedBackpack.stashId) end
            
            for _, stashId in ipairs(stashesToCheck) do
                local inv = exports['fdb-inventory']:GetInventory(stashId)
                if inv and inv.items then
                    for _, v in pairs(inv.items) do
                        if v.type == 'weapon' and v.info and v.info.serie == weaponData.info.serie then
                            found = true
                            break
                        end
                    end
                end
                if found then break end
            end
        end
        if not found then
            -- SECURITY FIX: previously this just returned, leaving the weapon
            -- equipped client-side even though the server could not verify
            -- ownership. Now we actively force it out of the player's hand.
            ForceRemoveWeapon(src, weaponData.info.serie)
            return
        end
    end

    local equippedWeapons = Player.PlayerData.metadata.equippedweapons or {}
    if isEquipped then
        equippedWeapons[weaponData.info.serie] = {
            name = weaponData.name,
            serie = weaponData.info.serie,
            slot = weaponData.slot
        }
    else
        equippedWeapons[weaponData.info.serie] = nil
    end
    Player.Functions.SetMetaData('equippedweapons', equippedWeapons)
end)

RegisterNetEvent('fdb-weapons:server:saveEquippedKnife', function(knifeName, equipped)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    if type(knifeName) ~= 'string' then return end

    if equipped then
        local found = false
        for _, v in pairs(Player.PlayerData.items) do
            if v.name == knifeName then
                found = true
                break
            end
        end
        if not found then return end
    end

    local equippedKnives = Player.PlayerData.metadata.equippedknives or {}
    if equipped then
        equippedKnives[knifeName] = true
    else
        equippedKnives[knifeName] = nil
    end
    Player.Functions.SetMetaData('equippedknives', equippedKnives)
end)

RSGCore.Functions.CreateCallback('fdb-weapons:server:getEquippedWeapons', function(source, cb)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then cb(nil) return end
    cb(Player.PlayerData.metadata.equippedweapons or {})
end)

RSGCore.Functions.CreateCallback('fdb-weapons:server:getEquippedKnives', function(source, cb)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then cb({}) return end
    cb(Player.PlayerData.metadata.equippedknives or {})
end)

-- FIX: this used to only check the player's pocket items. A near-identical,
-- more complete version (also checking satchel/holster/backpack stashes)
-- existed in fdb-inventory, but was registered under the dead 'rsg-weapons:'
-- prefix and never actually reached by the client. Merged here as the single
-- source of truth.
RSGCore.Functions.CreateCallback('fdb-weapons:server:getWeaponBySerial', function(source, cb, serial)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then cb(nil) return end

    for _, item in pairs(Player.PlayerData.items) do
        if item and item.name and item.info and item.info.serie == serial then
            cb(item)
            return
        end
    end

    local metadata = Player.PlayerData.metadata
    local equip = metadata.equipmentSlots or {}
    local stashesToCheck = {}
    if equip.satchel then table.insert(stashesToCheck, equip.satchel.stashId) end
    if equip.holster then table.insert(stashesToCheck, equip.holster.stashId) end
    if metadata.equippedBackpack then table.insert(stashesToCheck, metadata.equippedBackpack.stashId) end

    for _, stashId in ipairs(stashesToCheck) do
        local inv = exports['fdb-inventory']:GetInventory(stashId)
        if inv and inv.items then
            for _, item in pairs(inv.items) do
                if item and item.name and item.info and item.info.serie == serial then
                    cb(item)
                    return
                end
            end
        end
    end

    cb(nil)
end)

---------------------------------------------
-- Infinityammo for admin
---------------------------------------------
RegisterNetEvent('fdb-weapons:requestToggle', function()
    local src = source
    if RSGCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('fdb-weapons:toggle', src)
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Infinity Ammo',
            description = 'You do not have permission to use this command.',
            type = 'error'
        })
    end
end)