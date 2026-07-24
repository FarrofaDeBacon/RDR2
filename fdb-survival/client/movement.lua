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
            local staminaRate = 1.0
            local disableSprintStamina = false
            local disableRunStamina = false
            
            if stamina then
                if stamina < 30 then
                    staminaRate = 0.6 + (stamina / 75.0) -- 30 = 1.0, 0 = 0.6
                end
                if stamina < 5 then
                    disableSprintStamina = true
                    disableRunStamina = true
                end
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
            if blendRatio then
                SetPedMaxMoveBlendRatio(ped, blendRatio)
            end
            
            -- 5. RESOLVER VELOCIDADE DE MOVIMENTO (SetPedMoveRateOverride)
            -- Menor taxa vence (Stamina ou Mochila)
            local finalRate = math.min(staminaRate, backpackRate)
            if finalRate < 1.0 then
                Citizen.InvokeNative(0x082B1D45D8C4EEBD, ped, finalRate) -- SetPedMoveRateOverride
            end
        end
        Wait(sleep)
    end
end)

-- Reset ao trocar de personagem / respawnar
RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    currentClipset = nil
end)
