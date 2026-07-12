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
lib.callback.register('fdb-hud:server:getConfig', function(source)
    local allowedElements = {}
    for name, data in pairs(Config.Elements) do
        if data.enabled then
            allowedElements[name] = true
        end
    end
    return allowedElements
end)

-- -------------------------------------------------------
-- Callback: getLayout
-- Retorna o layout salvo do jogador (ou nil se nao houver).
-- -------------------------------------------------------
lib.callback.register('fdb-hud:server:getLayout', function(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return nil end
    local cid = Player.PlayerData.citizenid
    return layouts[cid] or nil
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

-- -------------------------------------------------------
-- Checagem periodica de posse de itens (7s)
-- -------------------------------------------------------
CreateThread(function()
    while true do
        Wait(7000)
        for _, playerId in ipairs(GetPlayers()) do
            local src = tonumber(playerId)
            local Player = RSGCore.Functions.GetPlayer(src)
            if Player then
                local hasMap = not Config.Minimap.requireItem or
                    RSGCore.Functions.HasItem(src, Config.Minimap.itemName)
                local hasCompass = not Config.Elements.compass.requireItem or
                    RSGCore.Functions.HasItem(src, Config.Elements.compass.itemName)
                TriggerClientEvent('fdb-hud:client:itemGatedUpdate', src, {
                    map = hasMap,
                    compass = hasCompass,
                })
            end
        end
    end
end)


