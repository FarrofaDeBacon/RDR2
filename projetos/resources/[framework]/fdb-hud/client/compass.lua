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

local hasCompassItem = not Config.Elements.compass.requireItem
local compassVisible = false

RegisterNetEvent('fdb-hud:client:itemGatedUpdate', function(data)
    hasCompassItem = data.compass
    -- Se perdeu o item da bussola, avisa a NUI imediatamente
    if not hasCompassItem and compassVisible then
        compassVisible = false
        SendNUI('updateCompass', { degrees = 0, cardinal = 'N', visible = false })
    end
end)

CreateThread(function()
    while true do
        Wait(Config.UpdateInterval)
        local canShow = isLoggedIn and Config.Elements.compass.enabled and hasCompassItem

        if not canShow then
            if compassVisible then
                compassVisible = false
                SendNUI('updateCompass', { degrees = 0, cardinal = 'N', visible = false })
            end
            goto continue
        end

        local heading = math.floor(GetEntityHeading(PlayerPedId()))
        -- Converte heading do jogo (0=Norte no RedM é 0°, aumenta anti-horario)
        -- Normaliza para 0-359 clockwise norte
        heading = (360 - heading) % 360

        if heading ~= lastHeading or not compassVisible then
            lastHeading = heading
            compassVisible = true
            SendNUI('updateCompass', {
                degrees  = heading,
                cardinal = Config.Elements.compass.showCardinals and GetCardinal(heading) or nil,
                visible  = true,
            })
        end

        ::continue::
    end
end)

