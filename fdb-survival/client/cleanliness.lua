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
                local propName = "p_horseflies"
                local modelHash = GetHashKey(propName)
                RequestModel(modelHash)
                local timeout = 0
                while not HasModelLoaded(modelHash) and timeout < 50 do
                    Wait(10)
                    timeout = timeout + 1
                end
                
                if HasModelLoaded(modelHash) then
                    local coords = GetEntityCoords(ped)
                    flyParticle = CreateObject(modelHash, coords.x, coords.y, coords.z, true, true, false)
                    local boneIndex = GetEntityBoneIndexByName(ped, "SKEL_Spine2")
                    AttachEntityToEntity(flyParticle, ped, boneIndex, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
                end

            elseif FDB.Survival.cleanliness >= 20 and isSmelly then
                isSmelly = false
                if flyParticle and DoesEntityExist(flyParticle) then
                    DeleteObject(flyParticle)
                    flyParticle = nil
                end
            end
        end
    end
end)
RegisterCommand("dirtyme", function()
    FDB.Survival.cleanliness = 10
    FDB.BroadcastState('cleanliness', 10)
    exports['ox_lib']:notify({ title = 'Sujeira', description = 'Higiene definida para 10.', type = 'inform' })
end, false)

RegisterCommand("lavar", function()
    local ped = PlayerPedId()
    if IsPedOnMount(ped) or IsPedInAnyVehicle(ped, false) then
        exports['ox_lib']:notify({ title = 'Erro', description = 'Desça antes de se lavar!', type = 'error' })
        return
    end
    
    if not IsEntityInWater(ped) then
        exports['ox_lib']:notify({ title = 'Erro', description = 'Você precisa estar na água ou no banho para se lavar!', type = 'error' })
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
    TriggerServerEvent('fdb-survival:server:ForceClean')
end, false)
