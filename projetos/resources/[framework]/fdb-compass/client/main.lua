-- ============================================================
-- fdb-hud | client/compass.lua
-- Calcula heading e envia à NUI
-- ============================================================

local CARDINALS = { 'N', 'NE', 'L', 'SE', 'S', 'SO', 'O', 'NO' }

local function GetCardinal(heading)
    local index = math.floor((heading + 22.5) / 45) % 8
    return CARDINALS[index + 1]
end

local lastHeading = -1

local hasCompassItem = not Config.Compass.requireItem
local isCompassEquipped = false
local compassVisible = false
local isLoggedIn = false

RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    isLoggedIn = true
end)

RegisterNetEvent('RSGCore:Client:OnPlayerUnload', function()
    isLoggedIn = false
end)

RegisterNetEvent('fdb-compass:client:itemGatedUpdate', function(hasItem)
    hasCompassItem = hasItem
    -- Se perdeu o item da bussola, avisa a NUI imediatamente
    if not hasCompassItem and compassVisible then
        compassVisible = false
        SendNUIMessage({ action = 'updateCompass', degrees = 0, cardinal = 'N', visible = false })
    end
end)

RegisterNetEvent('fdb-compass:client:equipUpdate', function(isEquipped)
    isCompassEquipped = isEquipped
    -- Se desequipou a bussola, avisa a NUI imediatamente
    if not isCompassEquipped and compassVisible then
        compassVisible = false
        SendNUIMessage({ action = 'updateCompass', degrees = 0, cardinal = 'N', visible = false })
    end
end)

CreateThread(function()
    while true do
        Wait(100)
        local canShow = isLoggedIn and Config.Compass.enabled
        
        if Config.Compass.requireItem then
            canShow = canShow and hasCompassItem and isCompassEquipped
        end

        if not canShow then
            if compassVisible then
                compassVisible = false
                SendNUIMessage({ action = 'updateCompass', degrees = 0, cardinal = 'N', visible = false })
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
            SendNUIMessage({
                action = 'updateCompass',
                degrees  = heading,
                cardinal = Config.Compass.showCardinals and GetCardinal(heading) or nil,
                visible  = true,
            })
        end

        ::continue::
    end
end)

