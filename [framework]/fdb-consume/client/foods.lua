-- client/foods.lua
-- Lógica interativa para comidas e Ensopado (Stew)

local activeProp = nil
local activeProp2 = nil -- Usado para a colher do ensopado
local isHoldingFood = false
local consumePrompt = nil
local dropPrompt = nil

local function CreateFoodPrompts()
    Citizen.CreateThread(function()
        consumePrompt = nil
        dropPrompt = nil

        consumePrompt = PromptRegisterBegin()
        PromptSetControlAction(consumePrompt, Config.Prompts.SmokeKey) -- Botão Esquerdo
        PromptSetText(consumePrompt, CreateVarString(10, 'LITERAL_STRING', "Dar Mordida"))
        PromptSetEnabled(consumePrompt, true)
        PromptSetVisible(consumePrompt, true)
        PromptSetHoldMode(consumePrompt, false)
        PromptRegisterEnd(consumePrompt)

        dropPrompt = PromptRegisterBegin()
        PromptSetControlAction(dropPrompt, Config.Prompts.DropKey) -- R
        PromptSetText(dropPrompt, CreateVarString(10, 'LITERAL_STRING', "Jogar Fora"))
        PromptSetEnabled(dropPrompt, true)
        PromptSetVisible(dropPrompt, true)
        PromptSetHoldMode(dropPrompt, false)
        PromptRegisterEnd(dropPrompt)
    end)
end

local function DeleteFoodPrompts()
    if consumePrompt then
        PromptDelete(consumePrompt)
        consumePrompt = nil
    end
    if dropPrompt then
        PromptDelete(dropPrompt)
        dropPrompt = nil
    end
end

RegisterNetEvent('fdb-consume:client:ConsumeFood', function(propModel, animType, maxUses)
    local ped = PlayerPedId()

    if isHoldingFood then
        TriggerEvent('fdb-consume:client:StopFood')
    end

    isHoldingFood = true
    maxUses = maxUses or 3 -- Fallback de segurança

    -- Lógica do Ensopado (Stew)
    if animType == "Stew" then
        RequestModel(`p_bowl04x_stew`)
        RequestModel(`p_spoon01x`)
        while not HasModelLoaded(`p_bowl04x_stew`) or not HasModelLoaded(`p_spoon01x`) do Wait(10) end
        
        local coords = GetEntityCoords(ped)
        activeProp = CreateObject(`p_bowl04x_stew`, coords.x, coords.y, coords.z, true, true, false)
        activeProp2 = CreateObject(`p_spoon01x`, coords.x, coords.y, coords.z, true, true, false)
        
        Citizen.InvokeNative(0x669655FFB29EF1A9, activeProp, 0, "Stew_Fill", 1.0)
        Citizen.InvokeNative(0xCAAF2BCCFEF37F77, activeProp, 20)
        Citizen.InvokeNative(0xCAAF2BCCFEF37F77, activeProp2, 82)
        TaskItemInteraction_2(ped, 599184882, activeProp, `p_bowl04x_stew_ph_l_hand`, -583731576, 1, 0, 0.0)
        TaskItemInteraction_2(ped, 599184882, activeProp2, `p_spoon01x_ph_r_hand`, -583731576, 1, 0, 0.0)
        Citizen.InvokeNative(0xB35370D5353995CB, ped, -583731576, 1.0)
        
        -- O Ensopado tem sua própria animação que finaliza sozinha.
        Wait(8000)
        TriggerEvent('fdb-consume:client:StopFood')
        return
    end

    -- Comidas Normais (Pão, Maçã, etc)
    local modelHash = GetHashKey(propModel)
    RequestModel(modelHash)
    
    local attempts = 0
    while not HasModelLoaded(modelHash) and attempts < 100 do
        Wait(10)
        attempts = attempts + 1
    end

    if not HasModelLoaded(modelHash) then
        isHoldingFood = false
        return
    end

    local coords = GetEntityCoords(ped)
    activeProp = CreateObject(modelHash, coords.x, coords.y, coords.z, true, true, false)
    
    local boneIndex = GetEntityBoneIndexByName(ped, 'SKEL_R_HAND')
    
    -- Offsets básicos para comidas (Mão Direita)
    local x, y, z = 0.1, -0.01, -0.07
    local rx, ry, rz = -90.0, 100.0, 0.0

    if animType == "Canned" then
        x, y, z = 0.10, -0.01, -0.07
        rx, ry, rz = -90.0, 10.0, 0.0
    elseif animType == "Eat" then
        x, y, z = 0.10, -0.01, -0.07
        rx, ry, rz = -90.0, 100.0, 0.0
    end

    AttachEntityToEntity(activeProp, ped, boneIndex, x, y, z, rx, ry, rz, true, true, false, true, 1, true)

    CreateFoodPrompts()

    local bitesTaken = 0

    Citizen.CreateThread(function()
        while isHoldingFood do
            Wait(0)
            
            -- Bloqueia o soco enquanto segura a comida para não bugar a animação
            DisableControlAction(0, Config.Prompts.SmokeKey, true)

            if IsControlJustReleased(0, Config.Prompts.DropKey) then
                TriggerEvent('fdb-consume:client:StopFood')
            end

            -- Verifica IsDisabledControlJustReleased pois o controle está desativado acima
            if IsDisabledControlJustReleased(0, Config.Prompts.SmokeKey) then
                bitesTaken = bitesTaken + 1
                local dict = "mech_inventory@eating@multi_bite@sphere_d8-2_sandwich"
                local clip = "quick_right_hand"
                
                if animType == "Canned" then
                    dict = "mech_inventory@eating@canned_food@cylinder@d8-2_h10-5"
                    clip = "left_hand"
                end

                RequestAnimDict(dict)
                while not HasAnimDictLoaded(dict) do Wait(10) end
                
                TaskPlayAnim(ped, dict, clip, 1.0, 1.0, 2000, 31, 0.0, false, false, false)
                Wait(2000)
                ClearPedTasks(ped)

                -- Se já deu X mordidas, o pão acaba automaticamente
                if bitesTaken >= maxUses then
                    TriggerEvent('fdb-consume:client:StopFood')
                end
            end
        end
    end)
end)

RegisterNetEvent('fdb-consume:client:StopFood', function()
    if isHoldingFood then
        isHoldingFood = false
        
        if consumePrompt then
            PromptSetEnabled(consumePrompt, false)
            PromptSetVisible(consumePrompt, false)
            PromptDelete(consumePrompt)
            consumePrompt = nil
        end
        if dropPrompt then
            PromptSetEnabled(dropPrompt, false)
            PromptSetVisible(dropPrompt, false)
            PromptDelete(dropPrompt)
            dropPrompt = nil
        end
        
        if activeProp and DoesEntityExist(activeProp) then
            DetachEntity(activeProp, true, true)
            DeleteObject(activeProp)
            activeProp = nil
        end
        if activeProp2 and DoesEntityExist(activeProp2) then
            DetachEntity(activeProp2, true, true)
            DeleteObject(activeProp2)
            activeProp2 = nil
        end
        ClearPedTasks(PlayerPedId())
    end
end)
