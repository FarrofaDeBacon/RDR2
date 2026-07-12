-- ============================================================
-- fdb-hud | s/main.lua
-- Side server: callbacks de layout persistido por jogador
-- ============================================================

local RSGCore = exports['rsg-core']:GetCoreObject()

-- Salva layout customizado do HUD por citizenid
-- (estrutura simples em memória; pode ser persistida em DB futuramente)
local layouts = {}

RSGCore.Functions.CreateCallback('fdb-hud:server:getLayout', function(source, cb)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return cb(nil) end
    local cid = Player.PlayerData.citizenid
    cb(layouts[cid] or nil)
end)

RegisterServerEvent('fdb-hud:server:saveLayout')
AddEventHandler('fdb-hud:server:saveLayout', function(layout)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    if type(layout) ~= 'table' then return end
    local cid = Player.PlayerData.citizenid
    layouts[cid] = layout
end)
