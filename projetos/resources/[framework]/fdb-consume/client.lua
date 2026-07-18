local RSGCore = exports['rsg-core']:GetCoreObject()
local IsDrunk = false
local IsPassedOut = false

-- Helper para Animações
local function PlayAnimation(ped, dict, name, flag, duration)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
    TaskPlayAnim(ped, dict, name, 8.0, -8.0, duration, flag, 0, false, false, false)
end

-- Evento de Consumir (Vem Seguro do Servidor)
RegisterNetEvent('fdb-consume:client:playAnim', function(animType)
    print("DEBUG fdb-consume: Recebeu playAnim com tipo: " .. tostring(animType))
    local ped = PlayerPedId()
    local anim = Config.Animations[animType]
    
    if not anim then 
        print("DEBUG fdb-consume: ERRO! Animação não encontrada para: " .. tostring(animType))
        return 
    end

    -- Cria o Prop na mão
    local propObj = nil
    if anim.prop then
        local x,y,z = table.unpack(GetEntityCoords(ped))
        local hash = GetHashKey(anim.prop)
        RequestModel(hash)
        while not HasModelLoaded(hash) do Wait(10) end
        propObj = CreateObject(hash, x, y, z, true, true, false)
        local boneIndex = GetEntityBoneIndexByName(ped, "SKEL_R_Hand")
        AttachEntityToEntity(propObj, ped, boneIndex, 0.02, 0.028, 0.001, 15.0, 175.0, 0.0, true, true, false, true, 1, true)
    end

    -- Toca Animação
    PlayAnimation(ped, anim.dict, anim.name, 31, anim.time)
    
    -- Barra de Progresso
    RSGCore.Functions.Progressbar("consume_item", "Consumindo...", anim.time, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        ClearPedTasks(ped)
        if propObj then DeleteObject(propObj) end
    end, function() -- Cancel
        ClearPedTasks(ped)
        if propObj then DeleteObject(propObj) end
    end)
end)

-- Efeitos do Álcool (Controlados pelo Servidor)
RegisterNetEvent('fdb-consume:client:checkAlcohol', function(alcoholLevel)
    local ped = PlayerPedId()

    if alcoholLevel > Config.Alcohol.PassOutThreshold and not IsPassedOut then
        -- DESMAIAR (PASS OUT)
        IsPassedOut = true
        IsDrunk = true
        
        lib.notify({title = '💀 Passando Mal', description = 'Você bebeu demais...', type = 'error'})

        -- Vômito
        PlayAnimation(ped, 'amb_misc@world_human_vomit@male_a@base', 'base', 31, Config.Alcohol.VomitDuration)
        Wait(Config.Alcohol.VomitDuration)
        ClearPedTasks(ped)

        -- Desmaio
        PlayAnimation(ped, 'amb_rest@world_human_sleep_ground@arm@male_b@idle_b', 'idle_f', 1, Config.Alcohol.SleepDuration)
        DoScreenFadeOut(5000)
        Wait(Config.Alcohol.SleepDuration)

        -- Acordar
        ClearPedTasks(ped)
        DoScreenFadeIn(5000)
        AnimpostfxStop("PlayerDrunk01_PassOut")
        IsPassedOut = false

    elseif alcoholLevel > Config.Alcohol.DrunkThreshold and not IsPassedOut then
        -- BÊBADO
        if not IsDrunk then
            IsDrunk = true
            lib.notify({title = '🍻 Bêbado', description = 'Você está começando a ver as coisas girando...', type = 'inform'})
            AnimpostfxPlay("PlayerDrunk01")
            SetPedIsDrunk(ped, true)
            RequestAnimSet("move_m@drunk@verydrunk")
            while not HasAnimSetLoaded("move_m@drunk@verydrunk") do Wait(10) end
            SetPedMovementClipset(ped, "move_m@drunk@verydrunk", 1.0)
        end
    else
        -- SÓBRIO
        if IsDrunk and not IsPassedOut then
            IsDrunk = false
            AnimpostfxStopAll()
            SetPedIsDrunk(ped, false)
            ResetPedMovementClipset(ped, 1.0)
            lib.notify({title = '💧 Sóbrio', description = 'O efeito do álcool passou.', type = 'success'})
        end
    end
end)
