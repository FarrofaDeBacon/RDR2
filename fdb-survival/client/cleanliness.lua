local isSmelly = false
local flyParticle = nil

-- DEBUFF DE SUJEIRA EXTREMA E MOSCAS
CreateThread(function()
    while true do
        Wait(1000)
        if FDB.IsLoggedIn then
            local ped = PlayerPedId()
            if FDB.Survival.cleanliness < 20 and not isSmelly then
                isSmelly = true
                exports['ox_lib']:notify({
                    title = 'Você está fedendo!',
                    description = 'As moscas começaram a te rodear. Vá se lavar (/lavar).',
                    type = 'warning',
                    duration = 5000
                })

                -- Efeito de moscas rodeando
                local assetName = "core"
                local ptfxName = "ent_anim_fly_swarm"
                
                RequestNamedPtfxAsset(assetName)
                local timeout = 0
                while not HasNamedPtfxAssetLoaded(assetName) and timeout < 50 do
                    Wait(10)
                    timeout = timeout + 1
                end
                
                if HasNamedPtfxAssetLoaded(assetName) then
                    UseParticleFxAssetNextCall(assetName)
                    local boneIndex = GetEntityBoneIndexByName(ped, "SKEL_Spine2")
                    flyParticle = StartNetworkedParticleFxLoopedOnEntityBone(
                        ptfxName, ped,
                        0.0, 0.0, 0.0, -- Offset
                        0.0, 0.0, 0.0, -- Rotação
                        boneIndex,
                        1.5, -- Escala
                        false, false, false
                    )
                end

            elseif FDB.Survival.cleanliness >= 20 and isSmelly then
                isSmelly = false
                if flyParticle then
                    StopParticleFxLooped(flyParticle, false)
                    flyParticle = nil
                end
                RemoveNamedPtfxAsset("core")
            end
        end
    end
end)

RegisterCommand("lavar", function()
    local ped = PlayerPedId()
    if IsPedOnMount(ped) or IsPedInAnyVehicle(ped, false) then
        exports['ox_lib']:notify({ title = 'Erro', description = 'Desça antes de se lavar!', type = 'error' })
        return
    end
    
    ClearPedTasks(ped)
    TaskStartScenarioInPlace(ped, joaat('WORLD_HUMAN_CLEAN_TABLE'), -1, true, false, false, false)
    exports['ox_lib']:progressBar({
        duration = 5000,
        label = 'Limpando sujeira...',
        useActiveKey = false,
        canCancel = false,
    })
    ClearPedTasks(ped)
    -- Limpeza visual completa (Lama/Ambiente, Sangue e Danos Visuais)
    Citizen.InvokeNative(0xE314AC4AD713061A, ped) -- ClearPedEnvDirt
    Citizen.InvokeNative(0x8FE22675A5A45817, ped) -- ClearPedBloodDamage
    Citizen.InvokeNative(0x523C79AEEFCC4A2A, ped, 10, "ALL") -- ClearPedDamageDecalByZone
    
    FDB.Survival.cleanliness = 100
    FDB.BroadcastState('cleanliness', 100)
    TriggerServerEvent('fdb-survival:server:SaveMeta', 'cleanliness', 100)
end, false)
