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
-- Estado por jogador (equipado ou nao) - server-side
-- -------------------------------------------------------
local equipped = {} -- [citizenid] = { map = bool }

-- -------------------------------------------------------
-- Helper: Verifica posse real do item (bolso ou satchel)
-- e se o mesmo nao esta arruinado (metadata.ruined)
-- -------------------------------------------------------
local function HasValidItem(Player, itemName)
    -- 1. Procura no inventario principal (bolso)
    for _, item in pairs(Player.PlayerData.items) do
        if item and item.name == itemName then
            if itemName == 'map' and item.info and item.info.ruined then
                -- ignora item arruinado
            else
                return true, 'pocket', item
            end
        end
    end

    -- 2. Procura no satchel equipado
    local equip = Player.PlayerData.metadata.equipmentSlots or {}
    if equip.satchel then
        local stashId = equip.satchel.stashId or (equip.satchel.info and equip.satchel.info.stashId)
        if stashId then
            local stashInventory = exports['rsg-inventory']:GetInventory(stashId)
            local stashItems = stashInventory and stashInventory.items or {}
            for _, item in pairs(stashItems) do
                if item and item.name == itemName then
                    if itemName == 'map' and item.info and item.info.ruined then
                        -- ignora item arruinado
                    else
                        return true, 'satchel', item
                    end
                end
            end
        end
    end

    return false, nil, nil
end

-- -------------------------------------------------------
-- Registrar os useable items (toggle de equipar)
-- -------------------------------------------------------
RSGCore.Functions.CreateUseableItem(Config.Minimap.itemName, function(source, item)
    TriggerClientEvent('fdb-hud:client:openMapMenu', source)
end)

RegisterServerEvent('fdb-hud:server:toggleMinimap')
AddEventHandler('fdb-hud:server:toggleMinimap', function()
    local source = source
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return end
    local cid = Player.PlayerData.citizenid
    
    equipped[cid] = equipped[cid] or { map = false }
    
    local hasMap = HasValidItem(Player, Config.Minimap.itemName)
    if not hasMap then
        equipped[cid].map = false
        TriggerClientEvent('fdb-hud:client:equipUpdate', source, { map = false })
        TriggerClientEvent('ox_lib:notify', source, {title = 'Você não possui um mapa válido.', type = 'error'})
        return
    end

    equipped[cid].map = not equipped[cid].map
    TriggerClientEvent('fdb-hud:client:equipUpdate', source, { map = equipped[cid].map })
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
                local cid = Player.PlayerData.citizenid
                equipped[cid] = equipped[cid] or { map = false }

                local hasMap = HasValidItem(Player, Config.Minimap.itemName)

                if not hasMap then equipped[cid].map = false end

                TriggerClientEvent('fdb-hud:client:itemGatedUpdate', src, {
                    map = hasMap
                })
            end
        end
    end
end)

-- -------------------------------------------------------
-- Mecanica de Molhar o Mapa (checkWet)
-- -------------------------------------------------------
RegisterServerEvent('fdb-hud:server:checkWet')
AddEventHandler('fdb-hud:server:checkWet', function(isSwimming, isRaining)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local cid = Player.PlayerData.citizenid

    equipped[cid] = equipped[cid] or { map = false }
    if not equipped[cid].map then return end -- mapa nao esta de fora (equipado)

    local hasMap, mapLoc, mapItem = HasValidItem(Player, 'map')
    if not hasMap then return end

    -- Se o mapa esta no bolso (pocket), ele fica molhado e estraga.
    -- Se estiver no satchel, esta protegido.
    if mapLoc == 'pocket' then
        mapItem.info = mapItem.info or {}
        mapItem.info.ruined = true
        mapItem.info.label = "Mapa Encharcado"

        -- Salva a alteracao no inventario do player de forma persistente
        exports['rsg-inventory']:SaveInventory(src)

        -- Desequipa o mapa
        equipped[cid].map = false

        -- Notifica cliente e UI
        TriggerClientEvent('rsg-inventory:client:updateInventory', src)
        TriggerClientEvent('fdb-hud:client:equipUpdate', src, { map = false })
        
        -- Atualiza gated status imediatamente
        TriggerClientEvent('fdb-hud:client:itemGatedUpdate', src, {
            map = false
        })

        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Seu mapa ficou encharcado e inutilizavel!',
            type = 'error',
            duration = 5000
        })
    end
end)

-- ============================================================
-- Status & Consumables (Metadata Segura)
-- ============================================================

-- Atualização de Sede e Bexiga (quando o player bebe algo)
RegisterServerEvent('fdb-hud:server:UpdateThirstBladder')
AddEventHandler('fdb-hud:server:UpdateThirstBladder', function(amount)
    local src = source
    print("DEBUG HUD SERVER: Recebido UpdateThirstBladder do ID", src, "amount=", amount)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local newThirst = (Player.PlayerData.metadata['thirst'] or 0) + amount
    if newThirst > 100 then newThirst = 100 end
    Player.Functions.SetMetaData('thirst', newThirst)
    print("DEBUG HUD SERVER: Sede atualizada para", newThirst)

    local newBladder = (Player.PlayerData.metadata['bladder'] or 0) + amount
    if newBladder > 100 then newBladder = 100 end
    Player.Functions.SetMetaData('bladder', newBladder)
    print("DEBUG HUD SERVER: Bexiga atualizada para", newBladder)
end)

-- Atualização de Fome (quando o player come algo)
RegisterServerEvent('fdb-hud:server:UpdateHunger')
AddEventHandler('fdb-hud:server:UpdateHunger', function(amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local newHunger = (Player.PlayerData.metadata['hunger'] or 0) + amount
    if newHunger > 100 then newHunger = 100 end
    Player.Functions.SetMetaData('hunger', newHunger)
end)

-- Alívio de Estresse
RegisterServerEvent('fdb-hud:server:RelieveStress')
AddEventHandler('fdb-hud:server:RelieveStress', function(amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local newStress = (Player.PlayerData.metadata['stress'] or 0) - amount
    if newStress < 0 then newStress = 0 end
    Player.Functions.SetMetaData('stress', newStress)
end)

-- Atualização de Álcool
RegisterServerEvent('fdb-hud:server:UpdateAlcohol')
AddEventHandler('fdb-hud:server:UpdateAlcohol', function(amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local newAlcohol = (Player.PlayerData.metadata['alcohol'] or 0) + amount
    if newAlcohol > 100 then newAlcohol = 100 end
    if newAlcohol < 0 then newAlcohol = 0 end
    Player.Functions.SetMetaData('alcohol', newAlcohol)
end)

-- Comando /mijar
RSGCore.Commands.Add('mijar', 'Aliviar a bexiga', {}, false, function(source, args)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local currentBladder = Player.PlayerData.metadata['bladder'] or 0
    if currentBladder <= 0 then
        TriggerClientEvent('RSGCore:Notify', src, 'Sua bexiga ja esta vazia!', 'error')
        return
    end

    Player.Functions.SetMetaData('bladder', 0)
    TriggerClientEvent('fdb-hud:client:DoPee', src)
    TriggerClientEvent('RSGCore:Notify', src, 'Voce aliviou sua bexiga.', 'success')
end)
