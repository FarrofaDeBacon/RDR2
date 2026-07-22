local activeProp = nil
local isHoldingDrink = false
local consumePrompt = nil
local dropPrompt = nil

local function CreateDrinkPrompts()
    Citizen.CreateThread(function()
        consumePrompt = nil
        dropPrompt = nil

        consumePrompt = PromptRegisterBegin()
        PromptSetControlAction(consumePrompt, Config.Prompts.SmokeKey) -- Botão Esquerdo
        PromptSetText(consumePrompt, CreateVarString(10, 'LITERAL_STRING', "Beber"))
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

RegisterNetEvent('fdb-consume:client:ConsumeDrink', function(propModel, animType, maxUses, animDict, animName, itemName)
    local ped = PlayerPedId()

    if isHoldingDrink then
        TriggerEvent('fdb-consume:client:StopDrink')
    end

    isHoldingDrink = true
    maxUses = maxUses or 3

    if animType == "Coffee" then
        RequestModel(`p_mug01_coffee`)
        while not HasModelLoaded(`p_mug01_coffee`) do Wait(10) end
        
        local coords = GetEntityCoords(ped)
        activeProp = CreateObject(`p_mug01_coffee`, coords.x, coords.y, coords.z, true, true, false)
        TaskItemInteraction_2(ped, 599184882, activeProp, GetHashKey('p_cs_coffee_mug01x_ph_r_hand'), -583731576, 1, 0, 0.0)
        
        Wait(5000)
        TriggerEvent('fdb-consume:client:StopDrink')
        return
    end

    local modelHash = GetHashKey(propModel)
    RequestModel(modelHash)
    local attempts = 0
    while not HasModelLoaded(modelHash) and attempts < 100 do Wait(10); attempts = attempts + 1 end
    if not HasModelLoaded(modelHash) then isHoldingDrink = false; return end

    local coords = GetEntityCoords(ped)
    activeProp = CreateObject(modelHash, coords.x, coords.y, coords.z, true, true, false)
    
    local boneIndex = GetEntityBoneIndexByName(ped, 'SKEL_R_HAND')
    local x, y, z = 0.05, -0.07, -0.05
    local rx, ry, rz = -75.0, 60.0, 0.0

    AttachEntityToEntity(activeProp, ped, boneIndex, x, y, z, rx, ry, rz, true, true, false, true, 1, true)
    CreateDrinkPrompts()

    local sipsTaken = 0

    Citizen.CreateThread(function()
        while isHoldingDrink do
            Wait(0)
            DisableControlAction(0, Config.Prompts.SmokeKey, true)
            
            if IsControlJustReleased(0, Config.Prompts.DropKey) then
                TriggerEvent('fdb-consume:client:StopDrink')
            end

            if IsDisabledControlJustReleased(0, Config.Prompts.SmokeKey) then
                sipsTaken = sipsTaken + 1
                
                local dict = animDict or "mech_inventory@drinking@bottle_cylinder_d1-3_h30-5_neck_a13_b2-5"
                local clip = animName or "chug_a"

                RequestAnimDict(dict)
                while not HasAnimDictLoaded(dict) do Wait(10) end
                
                TaskPlayAnim(ped, dict, clip, 8.0, -8.0, 2000, 31, 0.0, false, false, false)
                Wait(2000)
                ClearPedSecondaryTask(ped)

                if sipsTaken >= maxUses then
                    if itemName then
                        TriggerServerEvent('fdb-consume:server:giveReturnItem', itemName)
                    end
                    TriggerEvent('fdb-consume:client:StopDrink')
                end
            end
        end
    end)
end)

RegisterNetEvent('fdb-consume:client:StopDrink', function()
    if isHoldingDrink then
        isHoldingDrink = false
        if consumePrompt then PromptDelete(consumePrompt); consumePrompt = nil end
        if dropPrompt then PromptDelete(dropPrompt); dropPrompt = nil end
        if activeProp and DoesEntityExist(activeProp) then DeleteObject(activeProp); activeProp = nil end
        ClearPedTasks(PlayerPedId())
    end
end)
