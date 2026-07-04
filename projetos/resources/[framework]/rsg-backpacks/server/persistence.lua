local RSGCore = exports['rsg-core']:GetCoreObject()
activeGroundBackpacks = {}

-- Obtém o nome do item a partir do nome do modelo configurado
local function GetItemNameFromModel(modelName)
    for itemName, bpConfig in pairs(Config.Backpacks) do
        if bpConfig.model == modelName then
            return itemName
        end
    end
    return 'backpack_medium'
end

-- Carrega e respawna todas as mochilas no chão na inicialização do servidor
CreateThread(function()
    Wait(2000) -- Aguarda a conexão do banco de dados estar estável

    local query = "SELECT * FROM backpacks WHERE state = 'ground'"
    MySQL.query(query, {}, function(results)
        if not results then return end

        for _, row in ipairs(results) do
            local uid = row.uid
            local stashId = row.stash
            local model = row.model
            local coords = row.coords and json.decode(row.coords) or nil
            local rotation = row.rotation or 0.0

            if coords then
                local modelHash = GetHashKey(model)
                -- Spawna a entidade networked no lado do servidor
                local backpackEntity = CreateObjectNoOffset(modelHash, coords.x, coords.y, coords.z, true, true, false)

                -- Aguarda a criação física da entidade
                local timeout = 100
                while not DoesEntityExist(backpackEntity) and timeout > 0 do
                    Wait(10)
                    timeout = timeout - 1
                end

                if DoesEntityExist(backpackEntity) then
                    SetEntityHeading(backpackEntity, rotation)
                    FreezeEntityPosition(backpackEntity, true)

                    local netId = NetworkGetNetworkIdFromEntity(backpackEntity)
                    local itemName = GetItemNameFromModel(model)

                    activeGroundBackpacks[uid] = {
                        netId = netId,
                        entityId = backpackEntity,
                        stashId = stashId,
                        itemName = itemName,
                        coords = coords,
                        rotation = rotation,
                        owner = row.owner
                    }
                    print(("[rsg-backpacks] Respawned ground backpack UID: %s (Entity ID: %s, Net ID: %s)"):format(uid, backpackEntity, netId))
                else
                    print(("[rsg-backpacks] Failed to respawn ground backpack UID: %s (Entity creation failed)"):format(uid))
                end
            end
        end

        -- Atualiza sincronização para todos os clientes conectados
        TriggerClientEvent('rsg-backpacks:client:syncGroundBackpacks', -1, activeGroundBackpacks)
    end)
end)

-- Envia sincronização quando um novo jogador conectar
RegisterNetEvent('rsg-backpacks:server:requestSync', function()
    local src = source
    TriggerClientEvent('rsg-backpacks:client:syncGroundBackpacks', src, activeGroundBackpacks)
end)

-- Comando administrativo para limpar todas as mochilas do solo e retornar ao bolso
RegisterCommand('limparmochilas', function(source, args, rawCommand)
    local isAllowed = false
    if source == 0 then
        isAllowed = true
    else
        local Player = RSGCore.Functions.GetPlayer(source)
        if Player then
            if RSGCore.Functions.HasPermission(source, 'admin') or RSGCore.Functions.HasPermission(source, 'god') then
                isAllowed = true
            end
        end
    end

    if isAllowed then
        print("[rsg-backpacks] Iniciando limpeza de todas as mochilas no solo...")
        
        -- 1. Deleta as entidades físicas do mundo no servidor
        for uid, data in pairs(activeGroundBackpacks) do
            if data.entityId and DoesEntityExist(data.entityId) then
                DeleteEntity(data.entityId)
            end
            -- Remove da sincronização do cliente
            TriggerClientEvent('rsg-backpacks:client:removeGroundBackpack', -1, data.stashId, data.netId)
        end
        
        -- 2. Limpa a tabela de memória
        activeGroundBackpacks = {}
        
        -- 3. Atualiza o banco de dados para retornar as mochilas ao bolso dos donos
        MySQL.query("UPDATE backpacks SET state = 'item', coords = NULL, rotation = 0.0 WHERE state = 'ground'", {}, function(affectedRows)
            local count = affectedRows and (affectedRows.affectedRows or affectedRows.changedRows) or 0
            print(("[rsg-backpacks] Limpeza concluida! %s mochilas retornadas ao estado de item."):format(count))
        end)
        
        -- 4. Sincroniza a tabela limpa com todos os clientes
        TriggerClientEvent('rsg-backpacks:client:syncGroundBackpacks', -1, activeGroundBackpacks)
        TriggerClientEvent('rsg-backpacks:client:cleanupAllAttachedBackpacks', -1)
        
        if source > 0 then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Limpeza Concluída',
                description = 'Todas as mochilas do solo foram removidas e salvas como item!',
                type = 'success'
            })
        end
    else
        if source > 0 then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Sem Permissão',
                description = 'Você não tem permissão para usar este comando.',
                type = 'error'
            })
        end
    end
end)
