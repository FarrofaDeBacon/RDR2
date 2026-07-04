local RSGCore = exports['rsg-core']:GetCoreObject()

-- Register backpack as a useable item
RSGCore.Functions.CreateUseableItem("backpack", function(source, item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    if not item.info or not item.info.uid then
        item.info = item.info or {}
        item.info.uid = "backpack_"..math.random(100000, 999999)
        item.info.model = item.info.model or "p_ambpack02x" -- Default model
        Player.Functions.UpdateItemMetadata(item.slot, item.info)
    end

    -- Trigger client event to open backpack drawer inside rsg-inventory
    TriggerClientEvent("qadr_backpack:client:openBackpackDrawer", src, item.info.uid, item.info.model)
end)

-- Query backpack item and its items total weight
RegisterServerEvent("qadr_backpack:check")
AddEventHandler("qadr_backpack:check", function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local items = Player.PlayerData.items
    for slot, item in pairs(items) do
        if item and item.name == "backpack" and item.amount > 0 then
            local uid = item.info and item.info.uid
            local model = item.info and item.info.model or "p_ambpack02x"
            
            -- Call safe export in rsg-inventory to get stash weight (in grams)
            local stashWeight = exports["rsg-inventory"]:GetStashWeight(uid) or 0
            
            TriggerClientEvent("qadr_backpack:check", src, true, {
                name = "backpack",
                weight = stashWeight,
                meta = {
                    model = model,
                    uid = uid
                }
            })
            return
        end
    end
    TriggerClientEvent("qadr_backpack:check", src, false)
end)

-- Developer command to give a backpack with custom model metadata
RegisterCommand("qadr_backpack_addBag", function(source, args, rawCommand)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local model = args[1] or "p_ambpack02x"
    local info = {
        model = model,
        uid = "backpack_"..math.random(100000, 999999)
    }
    
    Player.Functions.AddItem("backpack", 1, nil, info)
    TriggerClientEvent("inventory:client:ItemBox", src, RSGCore.Shared.Items["backpack"], "add")
end)