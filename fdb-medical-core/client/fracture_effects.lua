FDB = FDB or {}
FDB.MedicalCore = FDB.MedicalCore or {}

RegisterNetEvent('fdb-medical-core:client:SetStaminaPenalty', function(active)
    FDB.MedicalCore.HasTorsoFracture = active
end)

RegisterNetEvent('fdb-medical-core:client:SetAimPenalty', function(active)
    FDB.MedicalCore.HasArmFracture = active
end)

CreateThread(function()
    while true do
        Wait(0)
        if FDB.MedicalCore.HasArmFracture then
            -- 0x2E623EBE is IsPlayerFreeAiming
            local isAiming = Citizen.InvokeNative(0x2E623EBE, PlayerId())
            if isAiming then
                if not IsGameplayCamShaking() then
                    ShakeGameplayCam("DRUNK_SHAKE", 2.0)
                end
            else
                if IsGameplayCamShaking() then
                    StopGameplayCamShaking(true)
                end
            end
        else
            Wait(1000)
        end
    end
end)

-- Reset de segurança
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        FDB.MedicalCore.HasTorsoFracture = false
        Citizen.InvokeNative(0x7AEFB85C1D49DEB6, PlayerPedId(), 100)
    end
end)