local RSGCore = exports['rsg-core']:GetCoreObject()

-- Auto-cria a tabela no banco de dados se não existir
MySQL.query.await([[
    CREATE TABLE IF NOT EXISTS `player_markers` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `citizenid` varchar(50) NOT NULL,
        `name` varchar(255) NOT NULL,
        `icon` varchar(50) DEFAULT NULL,
        `x` float NOT NULL,
        `y` float NOT NULL,
        `z` float NOT NULL,
        PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]])

-- Busca os marcadores de um jogador específico
lib.callback.register('fdb-mapmenu:server:getMarkers', function(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return {} end
    
    local citizenid = Player.PlayerData.citizenid
    local result = MySQL.query.await('SELECT * FROM player_markers WHERE citizenid = ?', {citizenid})
    return result or {}
end)

-- Verifica se o jogador tem o item mapa
lib.callback.register('fdb-mapmenu:server:hasMapItem', function(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    -- Procura no inventário
    for _, item in pairs(Player.PlayerData.items) do
        if item and item.name == 'map' then
            if not (item.info and item.info.ruined) then
                return true
            end
        end
    end
    
    -- Procura no satchel
    local equip = Player.PlayerData.metadata.equipmentSlots or {}
    if equip.satchel then
        local stashId = equip.satchel.stashId or (equip.satchel.info and equip.satchel.info.stashId)
        if stashId then
            local stashInventory = exports['rsg-inventory']:GetInventory(stashId)
            local stashItems = stashInventory and stashInventory.items or {}
            for _, item in pairs(stashItems) do
                if item and item.name == 'map' then
                    if not (item.info and item.info.ruined) then
                        return true
                    end
                end
            end
        end
    end
    
    return false
end)

-- Verifica se o jogador tem o item lápis
lib.callback.register('fdb-mapmenu:server:hasPencilItem', function(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    for _, item in pairs(Player.PlayerData.items) do
        if item and item.name == 'pencil' then
            return true
        end
    end
    
    return false
end)

-- Adiciona um novo marcador no banco de dados
RegisterNetEvent('fdb-mapmenu:server:addMarker', function(name, icon, coords)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    
    local id = MySQL.insert.await('INSERT INTO player_markers (citizenid, name, icon, x, y, z) VALUES (?, ?, ?, ?, ?, ?)', {
        citizenid, name, icon, coords.x, coords.y, coords.z
    })
    
    if id then
        TriggerClientEvent('ox_lib:notify', src, {title = 'Marcação Adicionada', type = 'success'})
        -- Opcional: Acionar um client event para forçar o recarregamento dos blips
        TriggerClientEvent('fdb-mapmenu:client:refreshMarkers', src)
    end
end)

-- Remove um marcador pelo ID
RegisterNetEvent('fdb-mapmenu:server:removeMarker', function(id)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    
    -- Verifica se o marcador pertence ao jogador para evitar exploit
    local rows = MySQL.update.await('DELETE FROM player_markers WHERE id = ? AND citizenid = ?', {
        id, citizenid
    })
    
    if rows > 0 then
        TriggerClientEvent('ox_lib:notify', src, {title = 'Marcação Removida', type = 'success'})
        TriggerClientEvent('fdb-mapmenu:client:refreshMarkers', src)
    end
end)

-- Adiciona o item mapa como utilizável
RSGCore.Functions.CreateUseableItem('map', function(source, item)
    TriggerClientEvent('fdb-mapmenu:client:OpenMapMenu', source)
end)

print('^2[fdb-mapmenu]^7 Persistência de marcações ativada via DB.')
