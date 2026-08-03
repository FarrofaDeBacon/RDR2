FDB = FDB or {}
FDB.MedicalCore = FDB.MedicalCore or {}

-- Intensidade do sway (ajustável via /testsway)
local swayIntensity = 0.8

RegisterNetEvent('fdb-medical-core:client:SetStaminaPenalty', function(active)
    FDB.MedicalCore.HasTorsoFracture = active
end)

RegisterNetEvent('fdb-medical-core:client:SetAimPenalty', function(active)
    FDB.MedicalCore.HasArmFracture = active
end)

-- Sway suave na mira: aplica um offset sinusoidal no heading/pitch da câmera
-- enquanto o jogador está mirando com o braço fraturado.
-- Diferente do DRUNK_SHAKE, isso não treme a tela — apenas faz a mira
-- "escorregar" lentamente, como se o braço não conseguisse segurar firme.
CreateThread(function()
    local timer = 0.0
    while true do
        Wait(0)
        if FDB.MedicalCore.HasArmFracture then
            -- 0x2E623EBE = IsPlayerFreeAiming (RDR3)
            local isAiming = Citizen.InvokeNative(0x2E623EBE, PlayerId())
            if isAiming then
                timer = timer + 0.016  -- ~1 frame a 60fps

                -- Duas ondas senoidais com frequências diferentes para parecer orgânico
                local swayH = math.sin(timer * 1.7) * swayIntensity
                    + math.sin(timer * 3.1) * (swayIntensity * 0.4)
                local swayV = math.cos(timer * 1.3) * (swayIntensity * 0.6)
                    + math.cos(timer * 2.7) * (swayIntensity * 0.3)

                -- 0x5D1EB123EAC5D071 = SET_GAMEPLAY_CAM_RELATIVE_HEADING
                -- 0xFB760AF4F537B8BF = SET_GAMEPLAY_CAM_RELATIVE_PITCH
                local currentH = Citizen.InvokeNative(0xC4ABF536048998AA) -- GET heading
                local currentV = Citizen.InvokeNative(0x99AADEBBA803F827) -- GET pitch

                Citizen.InvokeNative(0x5D1EB123EAC5D071, currentH + swayH)
                Citizen.InvokeNative(0xFB760AF4F537B8BF, currentV + swayV, 1.0)
            else
                timer = 0.0
            end
        else
            Wait(1000)
        end
    end
end)

-- Exporta a intensidade para o /testsway poder ajustar
RegisterNetEvent('fdb-medical-core:client:SetSwayIntensity', function(val)
    swayIntensity = val
end)

-- Reset de segurança
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        FDB.MedicalCore.HasTorsoFracture = false
        FDB.MedicalCore.HasArmFracture = false
    end
end)