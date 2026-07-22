local isHoldingPee = false

CreateThread(function()
    while true do
        Wait(1000)
        if FDB.IsLoggedIn then
            local ped = PlayerPedId()
            if FDB.Survival.bladder >= 80 and not isHoldingPee then
                isHoldingPee = true
                Citizen.InvokeNative(0x923583741DC87BCE, ped, 'war_veteran')
                exports['ox_lib']:notify({
                    title = 'Bexiga Cheia!',
                    description = 'Você precisa se aliviar urgente (/mijar).',
                    type = 'warning',
                    duration = 5000
                })
            elseif FDB.Survival.bladder < 80 and isHoldingPee then
                isHoldingPee = false
                Citizen.InvokeNative(0x923583741DC87BCE, ped, 'default')
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if isHoldingPee then
            DisableControlAction(0, 0x8FFC75D6, true) -- INPUT_SPRINT
            DisableControlAction(0, 0xD9D0E16C, true) -- INPUT_JUMP
        else
            Wait(1000)
        end
    end
end)

RegisterCommand("mijar", function()
    local ped = PlayerPedId()
    if IsPedOnMount(ped) or IsPedInAnyVehicle(ped, false) then
        exports['ox_lib']:notify({ title = 'Erro', description = 'Desça antes de se aliviar!', type = 'error' })
        return
    end
    
    ClearPedTasks(ped)
    TaskStartScenarioInPlace(ped, joaat('WORLD_HUMAN_PEE'), -1, true, false, false, false)
    Wait(4000)

    local assetName = "core"
    local ptfxName = "ent_anim_dog_peeing"
    
    RequestNamedPtfxAsset(assetName)
    while not HasNamedPtfxAssetLoaded(assetName) do
        Wait(10)
    end
    
    UseParticleFxAsset(assetName)
    local boneIndex = GetEntityBoneIndexByName(ped, "SKEL_Pelvis")
    local peeParticle = StartNetworkedParticleFxLoopedOnEntityBone(
        ptfxName, ped,
        0.0, 0.15, -0.1,
        -90.0, 0.0, 0.0,
        boneIndex,
        5.0,
        false, false, false
    )
    SetParticleFxLoopedColour(peeParticle, 1.0, 1.0, 0.0, 0)

    Wait(6000)
    StopParticleFxLooped(peeParticle, false)
    RemoveNamedPtfxAsset(assetName)
    Wait(3500)
    ClearPedTasks(ped)
    
    FDB.Survival.bladder = 0
    FDB.BroadcastState('bladder', 0)
    TriggerServerEvent('fdb-survival:server:SaveMeta', 'bladder', 0)
end, false)

CreateThread(function()
    exports.ox_target:addGlobalObject({
        {
            name = 'pee_action_object',
            label = 'Mijar',
            icon = 'fa-solid fa-droplet',
            onSelect = function() ExecuteCommand('mijar') end,
            distance = 2.0
        }
    })
    
    exports.ox_target:addGlobalVehicle({
        {
            name = 'pee_action_vehicle',
            label = 'Mijar',
            icon = 'fa-solid fa-droplet',
            onSelect = function() ExecuteCommand('mijar') end,
            distance = 2.0
        }
    })
end)
