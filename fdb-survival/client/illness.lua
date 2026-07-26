local RSGCore = exports['rsg-core']:GetCoreObject()

local fliesPtfx = nil
local isScreenEffectActive = false

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
                        fliesPtfx = CreateObject(modelHash, coords.x, coords.y, coords.z, true, true, false)
                        local boneIndex = GetEntityBoneIndexByName(ped, "SKEL_Spine2")
                        AttachEntityToEntity(fliesPtfx, ped, boneIndex, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
                    end
                end
                
                -- Escanear NPCs próximos para reagir ao fedor
                local coords = GetEntityCoords(ped)
                local peds = GetGamePool('CPed')
                for _, npc in ipairs(peds) do
                    if npc ~= ped and not IsPedInAnyVehicle(npc, false) and not IsPedDeadOrDying(npc, true) then
                        local dist = #(coords - GetEntityCoords(npc))
                        if dist < 4.0 then
                            if cleanliness < 10 then
                                -- Fuga
                                ClearPedTasks(npc)
                                TaskSmartFleePed(npc, ped, 100.0, -1, 0, 0)
                            else
                                -- Nojo (apenas animação)
                                if not IsEntityPlayingAnim(npc, "mech_loco_m@generic@reaction@disgust@unarmed@stand", "disgust_a", 3) then
                                    RequestAnimDict("mech_loco_m@generic@reaction@disgust@unarmed@stand")
                                    if HasAnimDictLoaded("mech_loco_m@generic@reaction@disgust@unarmed@stand") then
                                        TaskPlayAnim(npc, "mech_loco_m@generic@reaction@disgust@unarmed@stand", "disgust_a", 8.0, -8.0, 2000, 48, 0, false, false, false)
                                    end
                                end
                            end
                        end
                    end
                end
            else
                if fliesPtfx and DoesEntityExist(fliesPtfx) then
                    DeleteObject(fliesPtfx)
                    fliesPtfx = nil
                end
            end
            
            -- 2. DOENÇA (illness > 0)
            if illness > 0 then
                if not isScreenEffectActive then
                    AnimpostfxPlay("Poisoned", 0, true)
                    isScreenEffectActive = true
                end
                
                if math.random(1, 100) <= (10 + (illness / 10)) then -- Chance de tossir
                    RequestAnimDict("mech_loco_m@generic@reaction@coughing@unarmed@stand")
                    while not HasAnimDictLoaded("mech_loco_m@generic@reaction@coughing@unarmed@stand") do Wait(10) end
                    TaskPlayAnim(ped, "mech_loco_m@generic@reaction@coughing@unarmed@stand", "cough_a", 8.0, -8.0, 2000, 48, 0, false, false, false)
                end
                
                -- Dreno contínuo de Vida (Core/Anel) devido à doença
                local currentHealth = GetEntityHealth(ped)
                SetEntityHealth(ped, math.max(0, currentHealth - 2))
            else
                if isScreenEffectActive then
                    AnimpostfxStop("Poisoned")
                    isScreenEffectActive = false
                end
            end
            
        end
    end
end)

-- Limpeza ao deslogar
RegisterNetEvent('RSGCore:Client:OnPlayerUnload', function()
    if fliesPtfx and DoesEntityExist(fliesPtfx) then
        DeleteObject(fliesPtfx)
        fliesPtfx = nil
    end
    if isScreenEffectActive then
        AnimpostfxStop("Poisoned")
        isScreenEffectActive = false
    end
end)


