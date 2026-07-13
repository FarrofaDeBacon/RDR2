-- ============================================================
-- fdb-hud | c/status.lua
-- Coleta e envia barras de status (saude, stamina) para a NUI
-- ============================================================

local ped = nil

-- Cache para evitar updates desnecessários
local lastStatus = { health = -1, stamina = -1, dead = false }

local function GetNormalized(current, max)
    if max == 0 then return 0.0 end
    return math.max(0.0, math.min(1.0, current / max))
end

CreateThread(function()
    while true do
        Wait(Config.UpdateInterval)
        if not isLoggedIn then goto continue end

        ped = PlayerPedId()

        local health  = GetNormalized(GetEntityHealth(ped) - 100, 200)
        local stamina = GetNormalized(
            tonumber(string.format("%.2f", Citizen.InvokeNative(0x0FF421E467373FCF, PlayerId(), Citizen.ResultAsFloat()))),
            100
        )
        local dead    = IsEntityDead(ped)

        -- So envia se algo mudou
        if health ~= lastStatus.health or stamina ~= lastStatus.stamina or dead ~= lastStatus.dead then
            lastStatus = { health = health, stamina = stamina, dead = dead }
            SendNUI('updateStatus', lastStatus)
        end

        ::continue::
    end
end)
