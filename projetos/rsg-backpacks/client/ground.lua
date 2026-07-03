local RSGCore = exports['rsg-core']:GetCoreObject()

-- Coloca a mochila no chão a partir de um item do inventário
RegisterNetEvent('rsg-backpacks:client:placeBackpack', function(itemName, stashId, slot)
    PlayDoffAndPlaceAnimation(function()
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)

        local bpConfig = Config.Backpacks[itemName]
        local modelHash = GetHashKey(bpConfig.model)
        
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do Wait(0) end

        local forwardVector = GetEntityForwardVector(ped)
        local spawnPos = coords + (forwardVector * 0.8)
        local backpackEntity = CreateObject(modelHash, spawnPos.x, spawnPos.y, spawnPos.z, true, true, true)
        
        PlaceObjectOnGroundProperly(backpackEntity)
        if bpConfig.groundZOffset then
            local currentCoords = GetEntityCoords(backpackEntity)
            SetEntityCoords(backpackEntity, currentCoords.x, currentCoords.y, currentCoords.z + bpConfig.groundZOffset, false, false, false, false)
        end
        SetEntityHeading(backpackEntity, heading)
        FreezeEntityPosition(backpackEntity, true)
        SetEntityAsMissionEntity(backpackEntity, true, true)

        local netId = NetworkGetNetworkIdFromEntity(backpackEntity)
        SetNetworkIdExistsOnAllMachines(netId, true)
        
        -- Registra no banco de dados e no servidor
        TriggerServerEvent('rsg-backpacks:server:registerGroundBackpack', stashId, itemName, GetEntityCoords(backpackEntity), heading, netId, slot)
    end)
end)

-- Coloca a mochila vestida no chão
RegisterNetEvent('rsg-backpacks:client:doffAndPlaceOnGround', function(stashId, itemName)
    PlayDoffAndPlaceAnimation(function()
        local ped = PlayerPedId()
        if currentBackpackObject and DoesEntityExist(currentBackpackObject) then
            DeleteEntity(currentBackpackObject)
            currentBackpackObject = nil
        end
        
        currentBackpackStashId = nil
        LocalPlayer.state:set("currentBackpackStashId", nil, false)
        currentBackpackModel = nil
        currentBackpackWeightLimit = 0
        currentBackpackWeight = 0
        speedBlendRatio = 3.0

        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        local bpConfig = Config.Backpacks[itemName]
        local modelHash = GetHashKey(bpConfig.model)

        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do Wait(0) end

        local forwardVector = GetEntityForwardVector(ped)
        local spawnPos = coords + (forwardVector * 0.8)
        local backpackEntity = CreateObject(modelHash, spawnPos.x, spawnPos.y, spawnPos.z, true, true, true)
        
        PlaceObjectOnGroundProperly(backpackEntity)
        if bpConfig.groundZOffset then
            local currentCoords = GetEntityCoords(backpackEntity)
            SetEntityCoords(backpackEntity, currentCoords.x, currentCoords.y, currentCoords.z + bpConfig.groundZOffset, false, false, false, false)
        end
        SetEntityHeading(backpackEntity, heading)
        FreezeEntityPosition(backpackEntity, true)
        SetEntityAsMissionEntity(backpackEntity, true, true)

        local netId = NetworkGetNetworkIdFromEntity(backpackEntity)
        SetNetworkIdExistsOnAllMachines(netId, true)

        -- Registra no banco de dados e no servidor
        TriggerServerEvent('rsg-backpacks:server:registerGroundBackpack', stashId, itemName, GetEntityCoords(backpackEntity), heading, netId, nil)
    end)
end)
