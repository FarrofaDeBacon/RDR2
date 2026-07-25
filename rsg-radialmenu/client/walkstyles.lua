-- https://github.com/femga/rdr3_discoveries/blob/a4b4bcd5a3006b0c1434b03e4095d038164932f7/discoveredNatives/discovered_natives_by_community

local RSGCore = exports['rsg-core']:GetCoreObject()

local function setWalkstyle(clipset, style)
    TriggerEvent('fdb-survival:client:setWalkstyle', clipset)
    TriggerServerEvent('walkstyles:server:sync', clipset, style)
end

-- normal walkstyle
RegisterNetEvent('walkstyles:client:normal')
AddEventHandler('walkstyles:client:normal', function()
    setWalkstyle('default', 'normal')
end)

-- angry walkstyle
RegisterNetEvent('walkstyles:client:angry')
AddEventHandler('walkstyles:client:angry', function()
    setWalkstyle('angry', 'angry')
end)

-- war_veteran walkstyle
RegisterNetEvent('walkstyles:client:war_veteran')
AddEventHandler('walkstyles:client:war_veteran', function()
    setWalkstyle('war_veteran', 'normal')
end)

-- gold_panner walkstyle
RegisterNetEvent('walkstyles:client:gold_panner')
AddEventHandler('walkstyles:client:gold_panner', function()
    setWalkstyle('gold_panner', 'normal')
end)

-- lost_Man walkstyle
RegisterNetEvent('walkstyles:client:lost_Man')
AddEventHandler('walkstyles:client:lost_Man', function()
    setWalkstyle('lost_Man', 'normal')
end)

-- murfree walkstyle
RegisterNetEvent('walkstyles:client:murfree')
AddEventHandler('walkstyles:client:murfree', function()
    setWalkstyle('murfree', 'normal')
end)

-- primate walkstyle
RegisterNetEvent('walkstyles:client:primate')
AddEventHandler('walkstyles:client:primate', function()
    setWalkstyle('primate', 'normal')
end)

-- receive networked walkstyle from other players
RegisterNetEvent('walkstyles:client:syncRemote')
AddEventHandler('walkstyles:client:syncRemote', function(playerSrc, clipset, style)
    local player = GetPlayerFromServerId(playerSrc)
    if player ~= -1 then
        local ped = GetPlayerPed(player)
        if ped ~= PlayerPedId() then
            Citizen.InvokeNative(0x923583741DC87BCE, ped, 'default')
            Citizen.InvokeNative(0x89F5E7ADECCCB49C, ped, style)
        end
    end
end)
