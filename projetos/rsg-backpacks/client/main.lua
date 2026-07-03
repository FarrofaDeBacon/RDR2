local RSGCore = exports['rsg-core']:GetCoreObject()
currentBackpackObject = nil
currentBackpackStashId = nil
currentBackpackModel = nil
currentBackpackWeightLimit = 0
currentBackpackWeight = 0
speedBlendRatio = 3.0
registeredEntities = {}
groundBackpacks = {}

-- Clean up attachment on resource stop
AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        if currentBackpackObject and DoesEntityExist(currentBackpackObject) then
            DeleteEntity(currentBackpackObject)
        end
        for entity, _ in pairs(registeredEntities) do
            if DoesEntityExist(entity) then
                exports['ox_target']:removeLocalEntity(entity)
            end
        end
    end
end)

-- Wearing backpack logic

-- Wear / Attach backpack to player's back
local isAttaching = false
RegisterNetEvent('rsg-backpacks:client:attachToBack', function(stashId, itemName)
    if isAttaching then return end
    local bpConfig = Config.Backpacks[itemName]
    if not bpConfig then return end

    isAttaching = true

    if currentBackpackObject and DoesEntityExist(currentBackpackObject) then
        DeleteEntity(currentBackpackObject)
        currentBackpackObject = nil
    end

    local ped = PlayerPedId()
    local modelHash = GetHashKey(bpConfig.model)
    
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do Wait(0) end

    -- Local client-only object (prevents ghost/floating network issues)
    local bag = CreateObject(modelHash, 0, 0, 0, false, false, false)
    SetEntityRotation(bag, bpConfig.rot.x, bpConfig.rot.y, bpConfig.rot.z, 2)
    SetEntityAsMissionEntity(bag, true, true)
    
    local boneIndex = GetEntityBoneIndexByName(ped, bpConfig.bone or 'CP_Back')
    AttachEntityToEntity(bag, ped, boneIndex, 
        bpConfig.pos.x, bpConfig.pos.y, bpConfig.pos.z, 
        bpConfig.rot.x, bpConfig.rot.y, bpConfig.rot.z, 
        false, 
        bpConfig.softping ~= nil and bpConfig.softping or true, 
        bpConfig.collision ~= nil and bpConfig.collision or true, 
        false, 
        bpConfig.vertex or 2, 
        bpConfig.fixedRot ~= nil and bpConfig.fixedRot or true, 
        false, false)

    currentBackpackObject = bag
    currentBackpackStashId = stashId
    LocalPlayer.state:set("currentBackpackStashId", stashId, false)
    currentBackpackModel = bpConfig.model
    currentBackpackWeightLimit = bpConfig.weight
    isAttaching = false
end)

-- Detach backpack from player's back
RegisterNetEvent('rsg-backpacks:client:detachFromBack', function()
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
end)

-- Target interactions hookup imported from client/target.lua

-- Synchronize ground entities
RegisterNetEvent('rsg-backpacks:client:syncGroundBackpacks', function(syncList)
    print("[Backpack Debug] syncGroundBackpacks event received. List: " .. json.encode(syncList))
    groundBackpacks = syncList
    for uid, data in pairs(syncList) do
        CreateThread(function()
            local entity = 0
            local timeout = 100
            print(("[Backpack Debug] Resolving NetID %s for UID %s (Stash: %s)"):format(data.netId, uid, data.stashId))
            while entity == 0 and timeout > 0 do
                if NetworkDoesNetworkIdExist(data.netId) then
                    entity = NetworkGetEntityFromNetworkId(data.netId)
                end
                Wait(10)
                timeout = timeout - 1
            end
            if entity ~= 0 and DoesEntityExist(entity) then
                print(("[Backpack Debug] NetID resolved successfully to Entity: %s"):format(entity))
                SetupTarget(entity, data.stashId, data.itemName)
            else
                print(("[Backpack Debug] Failed to resolve NetID %s to a client entity within timeout."):format(data.netId))
            end
        end)
    end
end)

-- Remove ground entity target registration
RegisterNetEvent('rsg-backpacks:client:removeGroundBackpack', function(stashId, netId)
    local uid = stashId:sub(1, 3) == "bp_" and stashId:sub(4) or stashId
    if groundBackpacks then
        groundBackpacks[uid] = nil
    end

    -- Limpa a chave do stashId da tabela de registrados
    registeredEntities[stashId] = nil

    if NetworkDoesNetworkIdExist(netId) then
        local entity = NetworkGetEntityFromNetworkId(netId)
        if DoesEntityExist(entity) then
            exports['ox_target']:removeLocalEntity(entity)
            registeredEntities[entity] = nil
            
            -- Força a deleção do objeto no cliente para sincronizar na rede
            SetEntityAsMissionEntity(entity, true, true)
            DeleteEntity(entity)
        end
    end
end)

-- Auto-detect equipped backpack on player load or script start
local function checkEquippedBackpack()
    local PlayerData = RSGCore.Functions.GetPlayerData()
    if PlayerData and PlayerData.metadata and PlayerData.metadata.equippedBackpack then
        local eq = PlayerData.metadata.equippedBackpack
        if eq.stashId then
            currentBackpackStashId = eq.stashId
            LocalPlayer.state:set("currentBackpackStashId", eq.stashId, false)
            local bpConfig = Config.Backpacks[eq.itemName]
            if bpConfig then
                currentBackpackModel = bpConfig.model
                currentBackpackWeightLimit = bpConfig.weight
                
                -- Se o objeto físico não existir, recria o attach
                if not currentBackpackObject or not DoesEntityExist(currentBackpackObject) then
                    TriggerEvent('rsg-backpacks:client:attachToBack', eq.stashId, eq.itemName)
                end
            end
            print(("[rsg-backpacks] Auto-detected equipped backpack: %s"):format(eq.stashId))
            return
        end
    end
    LocalPlayer.state:set("currentBackpackStashId", nil, false)
end

AddEventHandler('RSGCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('rsg-backpacks:server:requestSync')
    Wait(1000)
    checkEquippedBackpack()
end)

CreateThread(function()
    Wait(2000)
    if LocalPlayer.state.isLoggedIn then
        TriggerServerEvent('rsg-backpacks:server:requestSync')
        checkEquippedBackpack()
    end
end)

RegisterNetEvent('rsg-backpacks:client:forceRuinDoff', function(stashId, itemName)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local rotation = GetEntityHeading(ped)
    TriggerServerEvent('rsg-backpacks:server:doffBackpack', stashId, itemName, coords, rotation)
end)

-- Função para limpar mochilas atachadas do corpo
local function cleanupAttachedObjects()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    if currentBackpackObject and DoesEntityExist(currentBackpackObject) then
        DeleteEntity(currentBackpackObject)
        currentBackpackObject = nil
    end

    local models = {
        `p_ambpack04x`,
        `p_ambpack05x`,
        `p_ambpack02x`,
        `p_ambpack01x`
    }
    
    for _, model in ipairs(models) do
        local obj = GetClosestObjectOfType(coords.x, coords.y, coords.z, 2.0, model, false, false, false)
        if obj and DoesEntityExist(obj) and IsEntityAttachedToEntity(obj, ped) then
            DeleteEntity(obj)
        end
    end
end

RegisterNetEvent('rsg-backpacks:client:cleanupAllAttachedBackpacks', function()
    cleanupAttachedObjects()
end)

RegisterCommand('limparmochilacorpo', function()
    cleanupAttachedObjects()
    TriggerEvent('ox_lib:notify', { title = 'Mochila', description = 'Mochilas fantasmas removidas do seu corpo!', type = 'success' })
end)


