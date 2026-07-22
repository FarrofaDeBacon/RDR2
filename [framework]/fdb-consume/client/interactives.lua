-- client/interactives.lua
-- Sistema Interativo para Comidas e Bebidas

local activeProp = nil
local activeType = nil
local consumePrompt = nil
local dropPrompt = nil
local isHoldingConsumable = false

function CreateConsumablePrompts(animType)
    Citizen.CreateThread(function()
        consumePrompt = nil
        dropPrompt = nil

        local consumeText = (animType == "drink" or animType == "medical" or animType == "drug") and "Dar Gole" or "Dar Mordida"
        
        consumePrompt = PromptRegisterBegin()
        PromptSetControlAction(consumePrompt, Config.Prompts.SmokeKey) -- Usa o botão esquerdo (mesmo do trago)
        PromptSetText(consumePrompt, CreateVarString(10, 'LITERAL_STRING', consumeText))
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

function DeleteConsumablePrompts()
    if consumePrompt then
        PromptDelete(consumePrompt)
        consumePrompt = nil
    end
    if dropPrompt then
        PromptDelete(dropPrompt)
        dropPrompt = nil
    end
end

RegisterNetEvent('fdb-consume:client:StartInteractiveConsumable', function(animType, propHash, attachDef)
    local ped = PlayerPedId()
    
    if isHoldingConsumable then
        -- Já está segurando, joga fora o antigo
        TriggerEvent('fdb-consume:client:StopInteractiveConsumable')
    end

    isHoldingConsumable = true
    activeType = animType
    
    local coords = GetEntityCoords(ped)
    activeProp = CreateObject(propHash, coords.x, coords.y, coords.z, true, true, false)
    
    local boneIndex = GetEntityBoneIndexByName(ped, 'SKEL_R_HAND')
    AttachEntityToEntity(activeProp, ped, boneIndex, attachDef.x, attachDef.y, attachDef.z, attachDef.rx, attachDef.ry, attachDef.rz, true, true, false, true, 1, true)

    CreateConsumablePrompts(animType)

    -- Loop de Interação
    Citizen.CreateThread(function()
        while isHoldingConsumable do
            Wait(0)
            if IsControlJustReleased(0, Config.Prompts.DropKey) then
                TriggerEvent('fdb-consume:client:StopInteractiveConsumable')
            end

            if IsControlJustReleased(0, Config.Prompts.SmokeKey) then
                -- Toca a animação de morder/beber dependendo do tipo
                if activeType == "drink" or activeType == "medical" or activeType == "drug" then
                    RequestAnimDict("amb_rest_drunk@world_human_drinking@male_a@idle_a")
                    while not HasAnimDictLoaded("amb_rest_drunk@world_human_drinking@male_a@idle_a") do Wait(10) end
                    TaskPlayAnim(ped, "amb_rest_drunk@world_human_drinking@male_a@idle_a", "idle_a", 1.0, 1.0, 3000, 31, 0.0, false, false, false)
                elseif activeType == "eat" then
                    RequestAnimDict("mech_inventory@eating@multi_bite@sphere_d8-2_sandwich")
                    while not HasAnimDictLoaded("mech_inventory@eating@multi_bite@sphere_d8-2_sandwich") do Wait(10) end
                    TaskPlayAnim(ped, "mech_inventory@eating@multi_bite@sphere_d8-2_sandwich", "quick_right_hand", 1.0, 1.0, 2000, 31, 0.0, false, false, false)
                elseif activeType == "canned" then
                    RequestAnimDict("mech_inventory@eating@canned_food@cylinder@d8-2_h10-5")
                    while not HasAnimDictLoaded("mech_inventory@eating@canned_food@cylinder@d8-2_h10-5") do Wait(10) end
                    TaskPlayAnim(ped, "mech_inventory@eating@canned_food@cylinder@d8-2_h10-5", "left_hand", 1.0, 1.0, 2000, 31, 0.0, false, false, false)
                else
                    RequestAnimDict("mech_inventory@eating@multi_bite@sphere_d8-2_sandwich")
                    while not HasAnimDictLoaded("mech_inventory@eating@multi_bite@sphere_d8-2_sandwich") do Wait(10) end
                    TaskPlayAnim(ped, "mech_inventory@eating@multi_bite@sphere_d8-2_sandwich", "quick_right_hand", 1.0, 1.0, 2000, 31, 0.0, false, false, false)
                end
                
                Wait(2000)
                ClearPedTasks(ped)
            end
        end
    end)
end)

RegisterNetEvent('fdb-consume:client:StopInteractiveConsumable', function()
    if isHoldingConsumable then
        isHoldingConsumable = false
        DeleteConsumablePrompts()
        
        if activeProp and DoesEntityExist(activeProp) then
            DetachEntity(activeProp, true, true)
            DeleteObject(activeProp)
            activeProp = nil
        end
        activeType = nil
        ClearPedTasks(PlayerPedId())
    end
end)
