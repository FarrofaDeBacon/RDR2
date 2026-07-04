local blend = 1.0

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        for _, v in pairs(tempBackPacks) do
            if DoesEntityExist(v) then
                DeleteEntity(v)
            end
        end
    end
end)

RegisterNetEvent("qadr_backpack:check")
AddEventHandler("qadr_backpack:check", function(isExist, item)
    if isExist then
        local model = "p_ambpack02x"
        if item and item.meta and item.meta.model then
            model = item.meta.model
        end
        createBackPack(model)
        stashWweight = item.weight or 0
    else
        deleteAllBackPack()
    end
end)

-- Main thread to sync inventory backpack state with server
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2000)
        if LocalPlayer.state.isLoggedIn then
            TriggerServerEvent("qadr_backpack:check")
        else
            deleteAllBackPack()
        end

        if qadr_backpacks and qadr_backpacks.config and qadr_backpacks.config.useWeight and tempBackPack then
            local maxWeight = qadr_backpacks[tempBackPack].weight or 5000
            local currentWeight = stashWweight
            blend = calculateBlend(currentWeight, maxWeight)
        end
    end
end)

-- Speed modifier thread based on backpack weight
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
        if qadr_backpacks and qadr_backpacks.config and qadr_backpacks.config.useWeight then
            if tempBackPack and blend < 3.0 then
                SetPedMaxMoveBlendRatio(PlayerPedId(), blend)
            else
                Citizen.Wait(500) -- Sleep longer if no backpack is equipped
            end
        else
            Citizen.Wait(2000) -- Sleep longer if config has weight disabled
        end
    end
end)

-- Hook to open the backpack drawer in rsg-inventory
RegisterNetEvent("qadr_backpack:client:openBackpackDrawer")
AddEventHandler("qadr_backpack:client:openBackpackDrawer", function(backpackUid, backpackModel)
    TriggerEvent("rsg-inventory:client:openBackpackDrawer", backpackUid, backpackModel)
end)