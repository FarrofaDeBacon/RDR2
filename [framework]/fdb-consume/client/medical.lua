-- client/medical.lua
-- Lógica para consumo único de drogas e remédios (Animação Direta, sem segurar o prop)

local activeProp = nil

local function cleanupProp()
    if activeProp and DoesEntityExist(activeProp) then
        DetachEntity(activeProp, true, true)
        DeleteObject(activeProp)
        activeProp = nil
    end
end

RegisterNetEvent('fdb-consume:client:ConsumeMedical', function(propModel)
    local ped = PlayerPedId()

    cleanupProp()

    local modelHash = GetHashKey(propModel)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do Wait(10) end

    local coords = GetEntityCoords(ped)
    activeProp = CreateObject(modelHash, coords.x, coords.y, coords.z, true, true, false)
    
    local boneIndex = GetEntityBoneIndexByName(ped, 'SKEL_R_HAND')
    
    -- Offsets básicos para frascos
    local x, y, z = 0.0, 0.0, 0.04
    local rx, ry, rz = 0.0, 0.0, 0.0

    AttachEntityToEntity(activeProp, ped, boneIndex, x, y, z, rx, ry, rz, true, true, false, true, 1, true)

    local dict = "mech_inventory@drinking@bottle_cylinder_d1-3_h30-5_neck_a13_b2-5"
    local clip = "chug_a"

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
    
    TaskPlayAnim(ped, dict, clip, 1.0, 1.0, 2000, 31, 0.0, false, false, false)
    Wait(2000)
    
    ClearPedTasks(ped)
    cleanupProp()
end)
