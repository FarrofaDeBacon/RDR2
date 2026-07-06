local RSGCore = exports['rsg-core']:GetCoreObject()
-- Player Disconnect Handler
AddEventHandler('playerDropped', function()
    for invId, inv in pairs(Inventories) do
        if inv.isOpen == source then
            inv.isOpen = false
            MySQL.prepare('INSERT INTO inventories (identifier, items) VALUES (?, ?) ON DUPLICATE KEY UPDATE items = ?',
                { invId, json.encode(inv.items), json.encode(inv.items) })
        end
    end
end)

-- Server Shutdown Handler
AddEventHandler('txAdmin:events:serverShuttingDown', function()
    for inventory, data in pairs(Inventories) do
        if data.isOpen then
            MySQL.prepare(
                'INSERT INTO inventories (identifier, items) VALUES (?, ?) ON DUPLICATE KEY UPDATE items = ?',
                { inventory, json.encode(data.items), json.encode(data.items) }
            )
        end
    end
end)


AddEventHandler('RSGCore:Server:PlayerLoaded', function(Player)
    local src = Player.PlayerData.source

    -- Migrate legacy metadata
    local metadata = Player.PlayerData.metadata
    local changed = false
    if not metadata.equipmentSlots then
        metadata.equipmentSlots = { backpack = nil, satchel = nil, wallet = nil, holster = nil }
        changed = true
    end

    local backpackItemsLookup = {
        backpack_tiny = { label = 'Mochila de Lona Mini', image = 'p_ambpack01x.png' },
        backpack_small = { label = 'Mochila de Lona Pequena', image = 'p_ambpack05x.png' },
        backpack_medium = { label = 'Mochila de Lona Média', image = 'p_ambpack02x.png' },
        backpack_large = { label = 'Mochila de Lona Grande', image = 'p_ambpack04x.png' }
    }
    local satchelItemsLookup = {
        satchel_small = { label = 'Bolsa de Couro Pequena', image = 'backpack_small.png' },
        satchel_medium = { label = 'Bolsa de Couro Média', image = 'backpack_medium.png' },
        satchel_large = { label = 'Bolsa de Couro Grande', image = 'backpack_large.png' }
    }

    if metadata.equippedBackpack then
        if type(metadata.equippedBackpack) == 'table' and metadata.equippedBackpack.itemName then
            local bpName = metadata.equippedBackpack.itemName
            local lookup = backpackItemsLookup[bpName] or { label = 'Mochila', image = 'p_ambpack02x.png' }
            metadata.equipmentSlots.backpack = {
                name = bpName,
                label = lookup.label,
                amount = 1,
                image = lookup.image,
                weight = 1000,
                info = { quality = 100, stashId = metadata.equippedBackpack.stashId },
                slot = 'backpack'
            }
        else
            metadata.equipmentSlots.backpack = nil
        end
        metadata.equippedBackpack = nil
        changed = true
    end

    if metadata.equippedSatchel then
        if type(metadata.equippedSatchel) == 'table' and metadata.equippedSatchel.itemName then
            local satName = metadata.equippedSatchel.itemName
            local lookup = satchelItemsLookup[satName] or { label = 'Bolsa', image = 'backpack_medium.png' }
            metadata.equipmentSlots.satchel = {
                name = satName,
                label = lookup.label,
                amount = 1,
                image = lookup.image,
                weight = 1000,
                info = { quality = 100, stashId = metadata.equippedSatchel.stashId },
                slot = 'satchel'
            }
        else
            metadata.equipmentSlots.satchel = nil
        end
        metadata.equippedSatchel = nil
        changed = true
    end

    -- Robust post-migration check for players who already have equipmentSlots but with incomplete objects
    if metadata.equipmentSlots then
        if metadata.equipmentSlots.backpack and not metadata.equipmentSlots.backpack.name and metadata.equipmentSlots.backpack.itemName then
            local bpName = metadata.equipmentSlots.backpack.itemName
            local lookup = backpackItemsLookup[bpName] or { label = 'Mochila', image = 'p_ambpack02x.png' }
            metadata.equipmentSlots.backpack = {
                name = bpName,
                label = lookup.label,
                amount = 1,
                image = lookup.image,
                weight = 1000,
                info = { quality = 100, stashId = metadata.equipmentSlots.backpack.stashId },
                slot = 'backpack'
            }
            changed = true
        end
        if metadata.equipmentSlots.satchel and not metadata.equipmentSlots.satchel.name and metadata.equipmentSlots.satchel.itemName then
            local satName = metadata.equipmentSlots.satchel.itemName
            local lookup = satchelItemsLookup[satName] or { label = 'Bolsa', image = 'backpack_medium.png' }
            metadata.equipmentSlots.satchel = {
                name = satName,
                label = lookup.label,
                amount = 1,
                image = lookup.image,
                weight = 1000,
                info = { quality = 100, stashId = metadata.equipmentSlots.satchel.stashId },
                slot = 'satchel'
            }
            changed = true
        end
    end

    if changed then
        Player.Functions.SetMetaData('equipmentSlots', metadata.equipmentSlots)
        Player.Functions.SetMetaData('equippedBackpack', nil)
        Player.Functions.SetMetaData('equippedSatchel', nil)
    end

    -- Force slots count to 10 to clean up legacy character configurations
    Player.Functions.SetPlayerData('slots', 10)

    -- Voeg inventaris functies toe aan de speler
    local methods = {
        AddItem = function(item, amount, slot, info, reason)
            return Inventory.AddItem(src, item, amount, slot, info, reason)
        end,
        RemoveItem = function(item, amount, slot, reason)
            return Inventory.RemoveItem(src, item, amount, slot, reason)
        end,
        GetItemBySlot = function(slot)
            return Inventory.GetItemBySlot(src, slot)
        end,
        GetItemByName = function(item)
            return Inventory.GetItemByName(src, item)
        end,
        GetItemsByName = function(item)
            return Inventory.GetItemsByName(src, item)
        end,
        ClearInventory = function(filterItems)
            Inventory.ClearInventory(src, filterItems)
        end,
        SetInventory = function(items)
            Inventory.SetInventory(src, items)
        end
    }

    for methodName, methodFunc in pairs(methods) do
        RSGCore.Functions.AddPlayerMethod(src, methodName, methodFunc)
    end
end)

-- Resource Start Event
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    local Players = RSGCore.Functions.GetRSGPlayers()
    for k in pairs(Players) do
        local methods = {
            AddItem = function(item, amount, slot, info)
                return Inventory.AddItem(k, item, amount, slot, info)
            end,
            RemoveItem = function(item, amount, slot)
                return Inventory.RemoveItem(k, item, amount, slot)
            end,
            GetItemBySlot = function(slot)
                return Inventory.GetItemBySlot(k, slot)
            end,
            GetItemByName = function(item)
                return Inventory.GetItemByName(k, item)
            end,
            GetItemsByName = function(item)
                return Inventory.GetItemsByName(k, item)
            end,
            ClearInventory = function(filterItems)
                Inventory.ClearInventory(k, filterItems)
            end,
            SetInventory = function(items)
                Inventory.SetInventory(k, items)
            end
        }

        for methodName, methodFunc in pairs(methods) do
            RSGCore.Functions.AddPlayerMethod(k, methodName, methodFunc)
        end

        -- Reset inventory busy state
        Player(k).state.inv_busy = false
    end
end)
