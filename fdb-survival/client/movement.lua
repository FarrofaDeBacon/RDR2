-- fdb-survival/client/movement.lua
-- ÚNICO responsável por clipset de movimento e por SetPedMoveRateOverride.
-- Nenhum outro arquivo deve chamar esses natives diretamente.

local currentClipset = nil

-- ==========================================
-- THREAD 1: CLIPSET (Executa a cada 500ms)
-- ==========================================
local function ResolveClipset()
    local drunkenness = FDB.Survival.drunkenness or 0
    if drunkenness >= Config.Alcohol.DrunkThreshold then
        return 'mp_style_drunk'
    elseif FDB.Survival.inMud then
        return 'move_m@mud_wade'
    end
    return nil -- volta ao padrão do jogo
end

CreateThread(function()
    while true do
        Wait(500)

        if FDB.IsLoggedIn then
            local ped = PlayerPedId()
            local targetClipset = ResolveClipset()
            
            if targetClipset ~= currentClipset then
                if targetClipset then
                    Citizen.InvokeNative(0xB28BBFAAE059B169, targetClipset) -- RequestClipSet
                    
                    local timer = 0
                    while not Citizen.InvokeNative(0x61A53D9BA33F49A6, targetClipset) and timer < 100 do
                        Wait(10)
                        timer = timer + 1
                    end
                    
                    if Citizen.InvokeNative(0x61A53D9BA33F49A6, targetClipset) then
                        Citizen.InvokeNative(0x89F5E7ADECCCB49C, ped, targetClipset, 1.0) -- SetPedMovementClipset
                    end
                else
                    Citizen.InvokeNative(0x06D26A96CA1BCA75, ped) -- ResetPedMovementClipset
                end
                currentClipset = targetClipset
            end
        end
    end
end)

-- ==========================================
-- THREAD 2: VELOCIDADE E CONTROLES (Wait 0)
-- ==========================================
CreateThread(function()
    while true do
        local sleep = 500
        if FDB.IsLoggedIn then
            sleep = 0
            local ped = PlayerPedId()
            
            -- 1. STAMINA
            local stamina = Citizen.InvokeNative(0x36731AC041289BB1, ped, 1) -- GetAttributeCoreValue for Stamina
            local staminaPercent = 100
            if stamina then
                staminaPercent = (stamina <= 1.0) and (stamina * 100) or stamina
            end
            
            -- [DEBUG TEMPORÁRIO] 
            -- Apenas imprimir a cada 100 frames (aprox 1.5s) para não floodar
            if not debugCounter then debugCounter = 0 end
            debugCounter = debugCounter + 1
            if debugCounter > 100 then
                print(("[MAESTRO DEBUG] Stamina Raw: %s | Stamina Percent: %s"):format(tostring(stamina), tostring(staminaPercent)))
            end
            
            local staminaRate = 1.0
            local disableSprintStamina = false
            local disableRunStamina = false
            
            if staminaPercent < 30 then
                staminaRate = 0.6 + (staminaPercent / 75.0) -- 30 = 1.0, 0 = 0.6
            end
            if staminaPercent < 5 then
                disableSprintStamina = true
                disableRunStamina = true
            end
            
            -- 2. BACKPACK WEIGHT
            local backpackRate = 1.0
            local disableSprintBackpack = false
            local disableRunBackpack = false
            local blendRatio = nil
            
            if GetResourceState('fdb-backpacks') == 'started' then
                local mod = exports['fdb-backpacks']:GetBackpackWeightModifier()
                if mod == 0.70 then -- Peso > 20kg
                    disableSprintBackpack = true
                    disableRunBackpack = true
                    blendRatio = 1.0
                    backpackRate = 0.75
                elseif mod == 0.85 then -- Peso entre 10kg e 20kg
                    disableSprintBackpack = true
                    blendRatio = 2.0
                    backpackRate = 0.85
                end
            end
            
            -- 3. RESOLVER CONTROLES
            if disableSprintStamina or disableSprintBackpack then
                DisableControlAction(0, 0x8FFC75D6, true) -- INPUT_SPRINT
            end
            if disableRunStamina or disableRunBackpack then
                DisableControlAction(0, 0xE30CD707, true) -- INPUT_RUN
            end
            
            -- 4. RESOLVER ANIMAÇÃO BASE (Blend Ratio)
            -- 3.0 é o padrão (Sprint). 2.0 = Trot, 1.0 = Walk.
            SetPedMaxMoveBlendRatio(ped, blendRatio or 3.0)
            
            -- 5. RESOLVER VELOCIDADE DE MOVIMENTO (SetPedMoveRateOverride)
            -- Menor taxa vence (Stamina ou Mochila)
            local finalRate = math.min(staminaRate, backpackRate)
            
            if debugCounter > 100 then
                print(("[MAESTRO DEBUG] finalRate: %s | blendRatio: %s | disableSprint: %s"):format(
                    tostring(finalRate), 
                    tostring(blendRatio or 3.0),
                    tostring(disableSprintStamina or disableSprintBackpack)
                ))
                debugCounter = 0 -- reseta contador
            end
            
            Citizen.InvokeNative(0x082B1D45D8C4EEBD, ped, finalRate) -- SetPedMoveRateOverride (Sempre aplica para garantir reset)
        end
        Wait(sleep)
    end
end)

-- Reset ao trocar de personagem / respawnar
RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    currentClipset = nil
end)
