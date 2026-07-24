local IsDrunk = false
local IsPassedOut = false

-- Helper para Animações
local function PlayAnimation(ped, dict, name, flag, duration)
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 50 do 
        Wait(10)
        timeout = timeout + 1
    end
    if timeout >= 50 then 
        return 
    end
    TaskPlayAnim(ped, dict, name, 8.0, -8.0, duration, flag, 0, false, false, false)
end

-- Efeitos do Álcool
RegisterNetEvent('fdb-survival:client:stateChanged', function(data)
    if data.field ~= 'drunkenness' then return end
    local alcoholLevel = data.value
    local ped = PlayerPedId()
    
    if alcoholLevel > Config.Alcohol.PassOutThreshold and not IsPassedOut then
        IsPassedOut = true
        lib.notify({title = '💥 Desmaio', description = 'Você bebeu demais e apagou!', type = 'error'})
        
        PlayAnimation(ped, 'amb_rest@world_human_sleep_ground@arm@male_b@idle_b', 'idle_f', 1, Config.Alcohol.SleepDuration)
        Wait(Config.Alcohol.SleepDuration)

        ClearPedTasks(ped)
        IsPassedOut = false

    elseif alcoholLevel > Config.Alcohol.DrunkThreshold and not IsPassedOut then
        if not IsDrunk then
            IsDrunk = true
            lib.notify({title = '🍻 Bêbado', description = 'Você está começando a ver as coisas girando...', type = 'inform'})
            
            ShakeGameplayCam("DRUNK_SHAKE", 0.5)
            Citizen.InvokeNative(0x406CCF555B04FAD3, ped, true, 1.0) 
            
            -- Aplica walkstyle "drunk" usando as nativas de RedM (igual ao rsg-radialmenu)
            Citizen.InvokeNative(0x923583741DC87BCE, ped, 'drunk')
            Citizen.InvokeNative(0x89F5E7ADECCCB49C, ped, 'normal')
            
            Citizen.CreateThread(function()
                while IsDrunk do
                    Wait(500)
                    local p = PlayerPedId()
                    if IsPedSprinting(p) or IsPedRunning(p) then
                        if math.random(1, 100) <= 35 then
                            SetPedToRagdoll(p, 3000, 3000, 0, false, false, false)
                            lib.notify({title = '😵 Oops!', description = 'Você tentou correr bêbado e tropeçou!', type = 'error'})
                            Wait(4000)
                        end
                    end
                end
            end)
        end
    else
        if IsDrunk and not IsPassedOut then
            IsDrunk = false
            Citizen.InvokeNative(0x406CCF555B04FAD3, ped, false, 0.0)
            -- Remove o walkstyle "drunk" voltando pro "default"
            Citizen.InvokeNative(0x923583741DC87BCE, ped, 'default')
            Citizen.InvokeNative(0x89F5E7ADECCCB49C, ped, 'normal')
            
            ShakeGameplayCam("DRUNK_SHAKE", 0.0)
            lib.notify({title = '💧 Sóbrio', description = 'O efeito do álcool passou.', type = 'success'})
        end
    end
end)

-- COMANDOS DE DEPURAÇÃO PARA TESTAR A ANIMAÇÃO
RegisterCommand("testdrunk", function()
    local ped = PlayerPedId()
    lib.notify({title = 'Debug', description = 'Testando clipset de bêbado...', type = 'inform'})
    
    ShakeGameplayCam("DRUNK_SHAKE", 0.5)
    Citizen.InvokeNative(0x406CCF555B04FAD3, ped, true, 1.0) 
    
    local clipset = "mp_style_drunk"
    
    -- Tenta aplicar pelo modo RedM
    Citizen.InvokeNative(0x923583741DC87BCE, ped, 'drunk')
    Citizen.InvokeNative(0x89F5E7ADECCCB49C, ped, 'normal')
    lib.notify({title = 'Debug', description = 'Animação forçada via nativas RedM!', type = 'success'})
end, false)

RegisterCommand("testsober", function()
    local ped = PlayerPedId()
    Citizen.InvokeNative(0x406CCF555B04FAD3, ped, false, 0.0)
    Citizen.InvokeNative(0x923583741DC87BCE, ped, 'default')
    Citizen.InvokeNative(0x89F5E7ADECCCB49C, ped, 'normal')
    ShakeGameplayCam("DRUNK_SHAKE", 0.0)
    lib.notify({title = 'Debug', description = 'Clipset removido.', type = 'success'})
end, false)
