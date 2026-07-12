-- ============================================================
-- fdb-hud | c/compass.lua
-- Calcula heading e envia à NUI
-- ============================================================

local CARDINALS = { 'N', 'NE', 'L', 'SE', 'S', 'SO', 'O', 'NO' }

local function GetCardinal(heading)
    local index = math.floor((heading + 22.5) / 45) % 8
    return CARDINALS[index + 1]
end

local lastHeading = -1

CreateThread(function()
    while true do
        Wait(Config.UpdateInterval)
        if not isLoggedIn or not Config.Compass.enabled then goto continue end

        local heading = math.floor(GetEntityHeading(PlayerPedId()))
        -- Converte heading do jogo (0=Norte no RedM é 0°, aumenta anti-horario)
        -- Normaliza para 0-359 clockwise norte
        heading = (360 - heading) % 360

        if heading ~= lastHeading then
            lastHeading = heading
            SendNUI('updateCompass', {
                degrees  = heading,
                cardinal = Config.Compass.showCardinals and GetCardinal(heading) or nil,
            })
        end

        ::continue::
    end
end)
