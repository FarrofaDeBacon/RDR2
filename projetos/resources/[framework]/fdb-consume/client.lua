local RSGCore = exports['rsg-core']:GetCoreObject()
local IsDrunk = false
local IsPassedOut = false

-- Helper para Animações
local function PlayAnimation(ped, dict, name, flag, duration)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
    TaskPlayAnim(ped, dict, name, 8.0, -8.0, duration, flag, 0, false, false, false)
end

-- Auxiliares Nativos do RedM
local function attachProp(ped, model, boneId, x, y, z, pitch, roll, yaw)
    local hash = (type(model) == "string") and GetHashKey(model) or model
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end
    local prop = CreateObject(hash, GetEntityCoords(ped), true, true, false, false, true)
    local boneIndex = GetEntityBoneIndexByName(ped, boneId)
    AttachEntityToEntity(prop, ped, boneIndex, x, y, z, pitch, roll, yaw, true, true, false, true, 1, true)
    return prop
end

local function safeDelete(entity)
    if entity and DoesEntityExist(entity) then 
        DetachEntity(entity, true, true)
        SetEntityAsMissionEntity(entity, true, true)
        DeleteObject(entity)
        DeleteEntity(entity)
    end
end

local isBusy = false

local function createProp(model, ped)
    local hash = (type(model) == "string") and GetHashKey(model) or model
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end
    return CreateObject(hash, GetEntityCoords(ped), true, true, false, false, true)
end

-- Evento de Consumir (Vem Seguro do Servidor)
RegisterNetEvent('fdb-consume:client:playAnim', function(animType)
    if isBusy then return end
    isBusy = true

    print("DEBUG fdb-consume: Recebeu playAnim com tipo: " .. tostring(animType))
    local ped = PlayerPedId()
    local anim = Config.Animations[animType]
    
    if not anim then 
        print("DEBUG fdb-consume: ERRO! Animação não encontrada para: " .. tostring(animType))
        isBusy = false
        return 
    end

    LocalPlayer.state:set("inv_busy", true, true)
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`)

    local prop, prop2
    local taskDuration = anim.time or 4000

    if animType == "Eat" then
        prop = attachProp(ped, anim.prop, "SKEL_L_Finger01", 0.04, -0.03, -0.01, 0.0, 19.0, 46.0)
        PlayAnimation(ped, 'mech_inventory@eating@multi_bite@sphere_d8-2_sandwich', 'quick_left_hand', 31, -1)
        taskDuration = 5000

    elseif animType == "Drink" then
        prop = attachProp(ped, anim.prop, "PH_R_HAND", 0.0, 0.0, 0.04, 0.0, 0.0, 0.0)
        if not IsPedOnMount(ped) and not IsPedInAnyVehicle(ped) then
            PlayAnimation(ped, 'mech_inventory@drinking@bottle_cylinder_d1-3_h30-5_neck_a13_b2-5', 'uncork', 31, 500)
            PlayAnimation(ped, 'mech_inventory@drinking@bottle_cylinder_d1-3_h30-5_neck_a13_b2-5', 'chug_a', 31, -1)
            taskDuration = 5000
        else
            Citizen.InvokeNative(0x5E8C96BA532298F2, ped, 1737033966, prop, `p_bottleJD01x_ph_r_hand`, `DRINK_Bottle_Cylinder_d1-55_H18_Neck_A8_B1-8_QUICK_RIGHT_HAND`, true, 0, 0)
            taskDuration = 4000
        end

    elseif animType == "Stew" then
        prop = createProp(`p_bowl04x_stew`, ped)
        prop2 = createProp(`p_spoon01x`, ped)
        Citizen.InvokeNative(0x669655FFB29EF1A9, prop, 0, "Stew_Fill", 1.0)
        Citizen.InvokeNative(0xCAAF2BCCFEF37F77, prop, 20)
        Citizen.InvokeNative(0xCAAF2BCCFEF37F77, prop2, 82)
        Citizen.InvokeNative(0x5E8C96BA532298F2, ped, 599184882, prop, `p_bowl04x_stew_ph_l_hand`, -583731576, 1, 0, 0.0)
        Citizen.InvokeNative(0x5E8C96BA532298F2, ped, 599184882, prop2, `p_spoon01x_ph_r_hand`, -583731576, 1, 0, 0.0)
        Citizen.InvokeNative(0xB35370D5353995CB, ped, -583731576, 1.0)
        taskDuration = 5000

    elseif animType == "Coffee" then
        prop = createProp(`P_MUGCOFFEE01X`, ped)
        Citizen.InvokeNative(0x669655FFB29EF1A9, prop, 0, "CTRL_cupFill", 1.0)
        Citizen.InvokeNative(0x5E8C96BA532298F2, ped, `CONSUMABLE_COFFEE`, prop, `P_MUGCOFFEE01X_PH_R_HAND`, `DRINK_COFFEE_HOLD`, 1, 0, -1)
        taskDuration = 5000

    elseif animType == "Canned" then
        prop = attachProp(ped, anim.prop, "SKEL_L_Finger00", 0.10, -0.03, 0.02, 20.0, -70.0, -20.0)
        if not IsPedOnMount(ped) and not IsPedInAnyVehicle(ped) and not IsPedUsingAnyScenario(ped) then
            PlayAnimation(ped, 'mech_inventory@eating@canned_food@cylinder@d8-2_h10-5', 'left_hand', 31, -1)
            taskDuration = 2750
        else
            Citizen.InvokeNative(0x5E8C96BA532298F2, ped, nil, `EAT_CANNED_FOOD_CYLINDER@D8-2_H10-5_QUICK_LEFT`, true, 0, 0)
            taskDuration = 2750
        end
    end
    
    -- Barra de Progresso visual (Assíncrona para não quebrar a Task)
    CreateThread(function()
        RSGCore.Functions.Progressbar("consume_item", "Consumindo...", taskDuration, false, true, {
            disableMovement = false,
            disableCarMovement = false,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function() end, function() end)
    end)

    -- Aguarda o tempo da animação
    Wait(taskDuration)
    
    -- Finaliza e Limpa
    ClearPedTasks(ped)
    safeDelete(prop)
    safeDelete(prop2)
    LocalPlayer.state:set("inv_busy", false, true)
    isBusy = false
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
