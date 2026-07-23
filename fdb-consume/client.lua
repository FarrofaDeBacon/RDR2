local RSGCore = exports['rsg-core']:GetCoreObject()
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

local isBusy = false

-- SISTEMA DE AUTO-LIMPEZA E PROTEÇÃO
Citizen.CreateThread(function()
    Wait(1000)
    DoScreenFadeIn(1000)
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    AnimpostfxStopAll()
    Citizen.InvokeNative(0x406CCF555B097893, ped, false)
    Citizen.InvokeNative(0x06D26A96CA1BCA75, ped) -- ResetPedMovementClipset
end)

-- Evento de Consumir
RegisterNetEvent('fdb-consume:client:playAnim', function(itemName)
    if isBusy then 
        lib.notify({ title = 'Aviso', description = 'Você já está fazendo algo!', type = 'error' })
        return 
    end
    
    local itemData = Config.Items[itemName]
    if not itemData then return end

    local animType = itemData.type
    local baseAnim = Config.Animations[animType] or {}

    isBusy = true
    LocalPlayer.state:set("inv_busy", true, true)
    
    local ped = PlayerPedId()
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`)

    local propModel = itemData.prop or baseAnim.prop
    local maxUses = itemData.uses or baseAnim.uses or 3
    local animDict = itemData.dict or baseAnim.dict
    local animName = itemData.name or baseAnim.name

    -- Remoção dos Triggers Fantasmas (Fase 2)
    -- O fdb-consume/server.lua já removeu o item e atualizou o banco ANTES de chamar essa animação.

    -- Roteador de Animações
    if animType == "Drink" or animType == "Coffee" then
        TriggerEvent('fdb-consume:client:ConsumeDrink', propModel, animType, maxUses, animDict, animName, itemName)
    elseif animType == "Stew" or animType == "Eat" or animType == "Canned" then
        TriggerEvent('fdb-consume:client:ConsumeFood', propModel, animType, maxUses, animDict, animName, itemName)
    elseif animType == "Medical" or animType == "Drug" then
        TriggerEvent('fdb-consume:client:ConsumeMedical', propModel, animType, maxUses, animDict, animName, itemName)
    elseif animType == "Chew" then
        TriggerEvent('fdb-consume:client:Chew', propModel, animDict, animName, itemName)
    elseif animType == "Smoke" then
        TriggerEvent('fdb-consume:prop:cigaret', propModel, maxUses, animDict, animName, itemName)
    elseif animType == "Cigar" then
        TriggerEvent('fdb-consume:prop:cigar', maxUses, animDict, animName)
    else
        print("^1[fdb-consume] ERRO: Tipo de animacao desconhecido: " .. tostring(animType) .. "^7")
    end
    
    LocalPlayer.state:set("inv_busy", false, true)
    isBusy = false
end)

-- Efeitos do Álcool
RegisterNetEvent('fdb-consume:client:checkAlcohol', function(alcoholLevel)
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
            
            local clipset = "mp_style_drunk"
            Citizen.InvokeNative(0xB28BBFAAE059B169, clipset)
            local timer = 0
            while not Citizen.InvokeNative(0x61A53D9BA33F49A6, clipset) and timer < 100 do
                Wait(10)
                timer = timer + 1
            end
            if Citizen.InvokeNative(0x61A53D9BA33F49A6, clipset) then
                Citizen.InvokeNative(0x89F5E7ADECCCB49C, ped, clipset, 1.0)
            end
            
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
            Citizen.InvokeNative(0x06D26A96CA1BCA75, ped) 
            ShakeGameplayCam("DRUNK_SHAKE", 0.0)
            lib.notify({title = '💧 Sóbrio', description = 'O efeito do álcool passou.', type = 'success'})
        end
    end
end)

-- Aplicar Health e Stamina do item consumível
-- health: valor relativo (-100 a +100) — soma sobre a saúde atual do ped
-- stamina: valor relativo — restaura fôlego do jogador (0 a 100)
RegisterNetEvent('fdb-consume:client:applyHealthStamina', function(healthDelta, staminaDelta)
    local ped = PlayerPedId()

    if healthDelta ~= 0 then
        local maxHp = GetEntityMaxHealth(ped)
        local currentHp = GetEntityHealth(ped)
        -- GetEntityHealth em RDR2 usa escala 0-maxHp; 100 = morto, maxHp = cheio
        local delta = math.floor((healthDelta / 100) * (maxHp - 100))
        local newHp = math.max(101, math.min(maxHp, currentHp + delta))
        SetEntityHealth(ped, newHp)
    end

    if staminaDelta ~= 0 then
        local currentStamina = GetPlayerStamina(PlayerId())
        local targetPct = math.max(0, math.min(100, currentStamina + staminaDelta))
        -- Restaura o stamina do cavalo ou do player usando native
        Citizen.InvokeNative(0xC6258F41D86676E0, PlayerPedId(), 1, staminaDelta)
    end
end)
