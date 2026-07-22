RegisterNetEvent('fdb-consume:client:ConsumeMedical', function(propModel, animDict, animName)
    local ped = PlayerPedId()
    
    local dict = animDict or "mech_inventory@drinking@bottle_cylinder_d1-3_h30-5_neck_a13_b2-5"
    local clip = animName or "chug_a"

    local modelHash = GetHashKey(propModel)
    RequestModel(modelHash)
    local attempts = 0
    while not HasModelLoaded(modelHash) and attempts < 100 do Wait(10); attempts = attempts + 1 end

    local coords = GetEntityCoords(ped)
    local prop = CreateObject(modelHash, coords.x, coords.y, coords.z, true, true, false)
    local boneIndex = GetEntityBoneIndexByName(ped, 'SKEL_R_HAND')
    
    AttachEntityToEntity(prop, ped, boneIndex, 0.0, 0.0, 0.04, 0.0, 0.0, 0.0, true, true, false, true, 1, true)

    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 50 do Wait(10); timeout = timeout + 1 end
    
    if timeout < 50 then
        TaskPlayAnim(ped, dict, clip, 1.0, 1.0, 2000, 31, 0.0, false, false, false)
        Wait(2000)
    end

    ClearPedTasks(ped)
    if DoesEntityExist(prop) then
        DetachEntity(prop, true, true)
        DeleteObject(prop)
    end
end)
