local RSGCore = exports['rsg-core']:GetCoreObject()

local markers = {} -- [citizenid] = { {x=.., y=.., label=..}, ... }

lib.callback.register('fdb-mapmenu:server:getMarkers', function(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return {} end
    return markers[Player.PlayerData.citizenid] or {}
end)

RegisterNetEvent('fdb-mapmenu:server:addMarker', function(x, y, label)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    markers[cid] = markers[cid] or {}
    table.insert(markers[cid], { x = x, y = y, label = label })
end)

RegisterNetEvent('fdb-mapmenu:server:removeMarker', function(index)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    if markers[cid] and markers[cid][index + 1] then
        table.remove(markers[cid], index + 1)
    end
end)

-- Server log info
print('^2[fdb-mapmenu]^7 Inicializado com sucesso.')
