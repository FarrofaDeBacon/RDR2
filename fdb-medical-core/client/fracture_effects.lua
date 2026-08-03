FDB = FDB or {}
FDB.MedicalCore = FDB.MedicalCore or {}

RegisterNetEvent('fdb-medical-core:client:SetStaminaPenalty', function(active)
    FDB.MedicalCore.HasTorsoFracture = active
end)

RegisterNetEvent('fdb-medical-core:client:SetAimPenalty', function(active)
    local ped = PlayerPedId()
    -- 0xD52D6A71CB0A8450 = SetPedAccuracy
    if active then
        Citizen.InvokeNative(0xD52D6A71CB0A8450, ped, 0)
    else
        Citizen.InvokeNative(0xD52D6A71CB0A8450, ped, 100)
    end
end)

-- Reset de segurança
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        FDB.MedicalCore.HasTorsoFracture = false
        Citizen.InvokeNative(0xD52D6A71CB0A8450, PlayerPedId(), 100)
    end
end)
