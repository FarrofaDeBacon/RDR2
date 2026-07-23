local RSGCore = exports['rsg-core']:GetCoreObject()

----------------------------------------------------------------------
-- WATER CANTEEN LOGIC
----------------------------------------------------------------------

RSGCore.Functions.CreateUseableItem('canteen100', function(source, item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    TriggerClientEvent('fdb-water:client:drink', src, Config.DrinkAmount, 'canteen100')
end)

RSGCore.Functions.CreateUseableItem('canteen75', function(source, item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    TriggerClientEvent('fdb-water:client:drink', src, Config.DrinkAmount, 'canteen75')
end)

RSGCore.Functions.CreateUseableItem('canteen50', function(source, item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    TriggerClientEvent('fdb-water:client:drink', src, Config.DrinkAmount, 'canteen50')
end)

RSGCore.Functions.CreateUseableItem('canteen25', function(source, item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    TriggerClientEvent('fdb-water:client:drink', src, Config.DrinkAmount, 'canteen25')
end)

RSGCore.Functions.CreateUseableItem('canteen0', function(source, item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
	TriggerClientEvent('fdb-water:client:fillupcanteen', src)
    if not Player then return end
    TriggerClientEvent('fdb-water:client:drink', src, Config.DrinkAmount, 'canteen0')
end)

local function RefillCanteen(src, fromItem)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    Player.Functions.RemoveItem(fromItem, 1)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[fromItem], 'remove', 1)
    Player.Functions.AddItem('canteen100', 1)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items['canteen100'], 'add', 1)
end

RegisterServerEvent('fdb-water:server:givefullcanteen')
AddEventHandler('fdb-water:server:givefullcanteen', function()
    RefillCanteen(source, 'canteen0')
end)

RegisterServerEvent('fdb-water:server:givefullcanteen25')
AddEventHandler('fdb-water:server:givefullcanteen25', function()
    RefillCanteen(source, 'canteen25')
end)

RegisterServerEvent('fdb-water:server:givefullcanteen50')
AddEventHandler('fdb-water:server:givefullcanteen50', function()
    RefillCanteen(source, 'canteen50')
end)

RegisterServerEvent('fdb-water:server:givefullcanteen75')
AddEventHandler('fdb-water:server:givefullcanteen75', function()
    RefillCanteen(source, 'canteen75')
end)

RegisterServerEvent('fdb-water:server:degradecanteen')
AddEventHandler('fdb-water:server:degradecanteen', function(item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local downgradeMap = {
        canteen100 = 'canteen75',
        canteen75 = 'canteen50',
        canteen50 = 'canteen25',
        canteen25 = 'canteen0'
    }

    local nextItem = downgradeMap[item]
    if not nextItem then return end

    Player.Functions.RemoveItem(item, 1)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[item], 'remove', 1)
    Player.Functions.AddItem(nextItem, 1)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[nextItem], 'add', 1)
end)

RegisterServerEvent('fdb-water:server:refillcanteen')
AddEventHandler('fdb-water:server:refillcanteen', function(fromItem)
    local src = source
    local valid = {
        canteen0 = true,
        canteen25 = true,
        canteen50 = true,
        canteen75 = true
    }

    if not valid[fromItem] then
        print(('[fdb-water] Invalid refill attempt from item: %s'):format(fromItem))
        return
    end

    RefillCanteen(src, fromItem)
end)


----------------------------------------------------------------------
-- BATHING LOGIC
----------------------------------------------------------------------

BathingSessions = {}

RegisterServerEvent('fdb-water:server:canEnterBath')
AddEventHandler('fdb-water:server:canEnterBath', function(town)
    local src = source
    if not Config.BathingZones[town] then return end

    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local currentMoney = Player.PlayerData.money['cash']

    if not BathingSessions[town] then
        if currentMoney >= Config.NormalBathPrice then
            Player.Functions.RemoveMoney('cash', Config.NormalBathPrice)
            BathingSessions[town] = src
            TriggerClientEvent('fdb-water:client:ToggleInvincibility', src, true)
            TriggerClientEvent('fdb-water:client:StartBath', src, town)
        else
            TriggerClientEvent('ox_lib:notify', src, { title = locale('notify_not_enough_money'), type = 'error', duration = 5000 })
        end
    else
        TriggerClientEvent('ox_lib:notify', src, { title = locale('notify_occupied'), type = 'error', duration = 5000 })
    end
end)

RegisterServerEvent('fdb-water:server:canEnterDeluxeBath')
AddEventHandler('fdb-water:server:canEnterDeluxeBath', function(town)
    local src = source
    if not Config.BathingZones[town] then return end
    if BathingSessions[town] == src then

        local Player = RSGCore.Functions.GetPlayer(src)
        if not Player then return end
        local currentMoney = Player.PlayerData.money['cash']

        if currentMoney >= Config.DeluxeBathPrice then
            Player.Functions.RemoveMoney('cash', Config.DeluxeBathPrice)
            TriggerClientEvent('fdb-water:client:StartDeluxeBath', src, town)
        else
            TriggerClientEvent('ox_lib:notify', src, { title = locale('notify_not_enough_money'), type = 'error', duration = 5000 })
            TriggerClientEvent('fdb-water:client:HideDeluxePrompt', src)
        end
    end
end)

RegisterServerEvent('fdb-water:server:setBathAsFree')
AddEventHandler('fdb-water:server:setBathAsFree', function(town)
    if BathingSessions[town] == source then
        BathingSessions[town] = nil
        TriggerClientEvent('fdb-water:client:ToggleInvincibility', source, false)
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    for town, player in pairs(BathingSessions) do
        if player == src then
            BathingSessions[town] = nil
        end
    end
end)

RegisterServerEvent('fdb-water:server:undressPlayer')
AddEventHandler('fdb-water:server:undressPlayer', function()
    exports['rsg-wardrobe']:RemovePlayerClothing(source)
end)

RegisterServerEvent('fdb-water:server:dressPlayer')
AddEventHandler('fdb-water:server:dressPlayer', function()
    exports['rsg-wardrobe']:DressPlayer(source)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for town, player in pairs(BathingSessions) do
            TriggerClientEvent('fdb-water:client:ToggleInvincibility', player, false)
        end
        BathingSessions = {}
    end
end)
