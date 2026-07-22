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

-- Auxiliares Nativos do RedM
local function attachProp(ped, model, boneId, x, y, z, pitch, roll, yaw)
    local hash = (type(model) == "string") and GetHashKey(model) or model
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 50 do 
        Wait(10)
        timeout = timeout + 1
    end
    if timeout >= 50 then return nil end
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
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 50 do 
        Wait(10)
        timeout = timeout + 1
    end
    if timeout >= 50 then return nil end
    local coords = GetEntityCoords(ped)
    return CreateObject(hash, coords.x, coords.y, coords.z, true, true, false, false, true)
end

-- SISTEMA DE AUTO-LIMPEZA E PROTEÇÃO
-- Se você der restart no script enquanto estava com tela preta ou bugado, isso limpa tudo.
Citizen.CreateThread(function()
    Wait(1000)
    DoScreenFadeIn(1000) -- Força a tela a voltar ao normal se tiver ficado presa preta!
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    AnimpostfxStopAll()
    Citizen.InvokeNative(0x406CCF555B097893, ped, false)
    Citizen.InvokeNative(0x06D26A96CA1BCA75, ped) -- ResetPedMovementClipset
end)

-- Evento de Consumir (Vem Seguro do Servidor)
RegisterNetEvent('fdb-consume:client:playAnim', function(itemName)
    
    if isBusy then 
        lib.notify({ title = 'Aviso', description = 'Você já está fazendo algo!', type = 'error' })
        return 
    end
    
    local itemData = Config.Items[itemName]
    if not itemData then 
        return 
    end

    local animType = itemData.type
    local baseAnim = Config.Animations[animType]


    isBusy = true
    LocalPlayer.state:set("inv_busy", true, true)
    
    local ped = PlayerPedId()
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`)

    local propModel = itemData.prop or baseAnim.prop
    local maxUses = itemData.uses or baseAnim.uses or 3

    local stressChange = itemData.stress or 0
    local hungerChange = itemData.hunger or 0
    local thirstChange = itemData.thirst or 0
    
    -- Computa os status e remove item imediatamente para comidas e bebidas (pois agora são roleplay contínuo)
    TriggerServerEvent('fdb-consume:server:UpdateStatus', stressChange, hungerChange, thirstChange)
    if Config.RemoveItemOnConsume then
        TriggerServerEvent('fdb-consume:server:RemoveItem', itemName)
    end

    -- Roteador de Animações
    if animType == "Smoke" then
        TriggerEvent('fdb-consume:prop:cigaret', propModel, maxUses)
    elseif animType == "Cigar" then
        TriggerEvent('fdb-consume:prop:cigar', maxUses)
    elseif animType == "Stew" or animType == "Eat" or animType == "Canned" then
        TriggerEvent('fdb-consume:client:ConsumeFood', propModel, animType, maxUses)
    elseif animType == "Drink" or animType == "Coffee" then
        TriggerEvent('fdb-consume:client:ConsumeDrink', propModel, animType, maxUses)
    elseif animType == "Medical" or animType == "Drug" then
        TriggerEvent('fdb-consume:client:ConsumeMedical', propModel)
    else
    end
    
    LocalPlayer.state:set("inv_busy", false, true)
    isBusy = false
end)

-- Efeitos do Álcool (Controlados pelo Servidor)
RegisterNetEvent('fdb-consume:client:checkAlcohol', function(alcoholLevel)
    local ped = PlayerPedId()

    if alcoholLevel > Config.Alcohol.PassOutThreshold and not IsPassedOut then
        IsPassedOut = true
        lib.notify({title = '💥 Desmaio', description = 'Você bebeu demais e apagou!', type = 'error'})
        
        -- Desmaio
        PlayAnimation(ped, 'amb_rest@world_human_sleep_ground@arm@male_b@idle_b', 'idle_f', 1, Config.Alcohol.SleepDuration)
        DoScreenFadeOut(5000)
        Wait(Config.Alcohol.SleepDuration)

        -- Acordar
        ClearPedTasks(ped)
        DoScreenFadeIn(5000)
        IsPassedOut = false

    elseif alcoholLevel > Config.Alcohol.DrunkThreshold and not IsPassedOut then
        -- BÊBADO
        if not IsDrunk then
            IsDrunk = true
            lib.notify({title = '🍻 Bêbado', description = 'Você está começando a ver as coisas girando...', type = 'inform'})
            
            -- Câmera Bêbada Nativa
            ShakeGameplayCam("DRUNK_SHAKE", 0.5)
            
            -- SetPedDrunkness (Aplica instabilidade de mira e stumble)
            Citizen.InvokeNative(0x406CCF555B04FAD3, ped, true, 1.0) 
            
            -- Carrega e aplica o andar bêbado perfeitamente
            local clipset = "mp_style_drunk"
            Citizen.InvokeNative(0xB28BBFAAE059B169, clipset) -- RequestClipSet
            local timer = 0
            while not Citizen.InvokeNative(0x61A53D9BA33F49A6, clipset) and timer < 100 do
                Wait(10)
                timer = timer + 1
            end
            if Citizen.InvokeNative(0x61A53D9BA33F49A6, clipset) then -- HasClipSetLoaded
                Citizen.InvokeNative(0x89F5E7ADECCCB49C, ped, clipset, 1.0) -- SetPedMovementClipset
            end
            
            -- Loop para tropeçar se tentar correr
            Citizen.CreateThread(function()
                while IsDrunk do
                    Wait(500)
                    local p = PlayerPedId()
                    -- Se estiver correndo ou sprintando
                    if IsPedSprinting(p) or IsPedRunning(p) then
                        -- 35% de chance de tropeçar a cada meio segundo correndo
                        if math.random(1, 100) <= 35 then
                            SetPedToRagdoll(p, 3000, 3000, 0, false, false, false)
                            lib.notify({title = '😵 Oops!', description = 'Você tentou correr bêbado e tropeçou!', type = 'error'})
                            Wait(4000) -- Tempo no chão antes de poder tropeçar de novo
                        end
                    end
                end
            end)
        end
    else
        -- SÓBRIO
        if IsDrunk and not IsPassedOut then
            IsDrunk = false
            
            -- Remove Efeito Drunkness
            Citizen.InvokeNative(0x406CCF555B04FAD3, ped, false, 0.0)
            
            -- Remove Andar Bêbado (ResetPedMovementClipset)
            Citizen.InvokeNative(0x06D26A96CA1BCA75, ped) 
            
            -- Para câmera
            ShakeGameplayCam("DRUNK_SHAKE", 0.0)
            
            lib.notify({title = '💧 Sóbrio', description = 'O efeito do álcool passou.', type = 'success'})
        end
    end
end)
