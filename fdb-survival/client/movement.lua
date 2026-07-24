-- fdb-survival/client/movement.lua
-- ÚNICO responsável por clipset de movimento e por SetPedMoveRateOverride.
-- Nenhum outro arquivo deve chamar esses natives diretamente.

local currentClipset = nil
local currentRateOverride = nil

-- Ordem de prioridade de CLIPSET
local function ResolveClipset()
    if FDB.Survival.drunkenness >= Config.Alcohol.DrunkThreshold then
        return 'mp_style_drunk'
    elseif FDB.Survival.inMud then
        return 'move_m@mud_wade'
    end
    return nil -- volta ao padrão do jogo
end

-- Velocidade é uma escala independente do clipset
local function ResolveMoveRate()
    local ped = PlayerPedId()
    local stamina = Citizen.InvokeNative(0x36731AC041289BB1, ped, 1) -- GetAttributeCoreValue for Stamina
    
    if stamina and stamina < 30 then
        return 0.6 + (stamina / 75.0) -- 30 = 1.0, 0 = 0.6
    end
    return 1.0
end

CreateThread(function()
    while true do
        Wait(500)

        if FDB.IsLoggedIn then
            local ped = PlayerPedId()

            -- CLIPSET
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

            -- VELOCIDADE
            local targetRate = ResolveMoveRate()
            if targetRate ~= currentRateOverride then
                Citizen.InvokeNative(0x082B1D45D8C4EEBD, ped, targetRate) -- SetPedMoveRateOverride
                currentRateOverride = targetRate
            end
        end
    end
end)

-- Reset ao trocar de personagem / respawnar
RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    currentClipset = nil
    currentRateOverride = nil
end)
