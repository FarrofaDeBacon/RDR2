local RSGCore = exports['rsg-core']:GetCoreObject()

local fliesPtfx = nil

-- Efeitos Biológicos (Doenças e Mau Cheiro)
CreateThread(function()
    while true do
        Wait(3000)
        
        if FDB.IsLoggedIn then
            local ped = PlayerPedId()
            local cleanliness = FDB.Survival.cleanliness or 100
            local illness = FDB.Survival.illness or 0
            
            -- 1. MAU CHEIRO (cleanliness < 20)
            if cleanliness < 20 then
                if not fliesPtfx then
                    RequestNamedPtfxAsset("core")
                    while not HasNamedPtfxAssetLoaded("core") do Wait(10) end
                    UseParticleFxAsset("core")
                    fliesPtfx = Citizen.InvokeNative(0x6C38AF3693A69A91, "env_animal_flies_a", ped, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, false, false, false) -- StartNetworkedParticleFxLoopedOnEntity
                end
            else
                if fliesPtfx then
                    Citizen.InvokeNative(0x459598F579C98929, fliesPtfx, false) -- StopParticleFxLooped
                    fliesPtfx = nil
                end
            end
            
            -- 2. DOENÇA (illness > 0)
            if illness > 0 then
                if math.random(1, 100) <= (10 + (illness / 10)) then -- Chance de tossir
                    RequestAnimDict("mech_loco_m@generic@reaction@coughing@unarmed@stand")
                    while not HasAnimDictLoaded("mech_loco_m@generic@reaction@coughing@unarmed@stand") do Wait(10) end
                    TaskPlayAnim(ped, "mech_loco_m@generic@reaction@coughing@unarmed@stand", "cough_a", 8.0, -8.0, 2000, 48, 0, false, false, false)
                end
            end
            
        end
    end
end)

-- Limpeza ao deslogar
RegisterNetEvent('RSGCore:Client:OnPlayerUnload', function()
    if fliesPtfx then
        Citizen.InvokeNative(0x459598F579C98929, fliesPtfx, false)
        fliesPtfx = nil
    end
end)
