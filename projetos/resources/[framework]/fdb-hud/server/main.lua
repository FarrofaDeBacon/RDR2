-- ============================================================
-- fdb-hud | server/main.lua
-- Callbacks de config e layout persistido por jogador
-- ============================================================

local RSGCore = exports['rsg-core']:GetCoreObject()

-- Layouts em memória por citizenid
-- (pode ser persistido em DB futuramente)
local layouts = {}

-- -------------------------------------------------------
-- Callback: getConfig
-- Retorna SOMENTE os elementos com enabled=true.
-- Nunca envia elementos desabilitados ao client.
-- Config.Minimap NAO e incluido aqui - e controle exclusivo
-- do servidor, nunca exposto via callback.
-- -------------------------------------------------------
RSGCore.Functions.CreateCallback('fdb-hud:server:getConfig', function(source, cb)
    local allowedElements = {}
    for name, data in pairs(Config.Elements) do
        if data.enabled then
            allowedElements[name] = true
        end
    end
    cb(allowedElements)
end)

-- -------------------------------------------------------
-- Callback: getLayout
-- Retorna o layout salvo do jogador (ou nil se nao houver).
-- -------------------------------------------------------
RSGCore.Functions.CreateCallback('fdb-hud:server:getLayout', function(source, cb)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return cb(nil) end
    local cid = Player.PlayerData.citizenid
    cb(layouts[cid] or nil)
end)

-- -------------------------------------------------------
-- Evento: saveLayout
-- Revalida server-side: remove do payload qualquer item
-- que nao esteja habilitado em Config.Elements, mesmo que
-- o client tenha mandado.
-- -------------------------------------------------------
RegisterServerEvent('fdb-hud:server:saveLayout')
AddEventHandler('fdb-hud:server:saveLayout', function(layout)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    if type(layout) ~= 'table' then return end

    -- Strip de itens nao permitidos
    for item, _ in pairs(layout.visibility or {}) do
        if not (Config.Elements[item] and Config.Elements[item].enabled) then
            layout.visibility[item] = nil
        end
    end

    local cid = Player.PlayerData.citizenid
    layouts[cid] = layout
end)

