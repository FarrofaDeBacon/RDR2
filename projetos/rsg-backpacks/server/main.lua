local RSGCore = exports['rsg-core']:GetCoreObject()

-- Gera um UID único de 8 caracteres alfanuméricos com verificação de colisão
local function GenerateUID()
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local length = 8
    local uid
    local isUnique = false
    
    while not isUnique do
        uid = ''
        for i = 1, length do
            local rand = math.random(1, #chars)
            uid = uid .. string.sub(chars, rand, rand)
        end
        local check = GetBackpackByUid(uid)
        if not check then
            isUnique = true
        end
    end
    return uid
end

-- Register usable items for the 4 backpack types
for itemName, bpConfig in pairs(Config.Backpacks) do
    RSGCore.Functions.CreateUseableItem(itemName, function(source, item)
        local src = source
        local Player = RSGCore.Functions.GetPlayer(src)
        if not Player then return end

        -- Seta metadados únicos e persiste no banco se for a primeira vez
        if not item.info or not item.info.uid then
            local uid = GenerateUID()
            local stashId = Utils.GetStashName(uid)
            
            -- Salva metadados da mochila física no banco de dados
            InsertBackpack({
                uid = uid,
                stash = stashId,
                owner = Player.PlayerData.citizenid,
                model = bpConfig.model,
                coords = nil,
                rotation = 0.0,
                durability = 100,
                state = 'item',
                metadata = {}
            })

            item.info = item.info or {}
            item.info.uid = uid
            item.info.stashId = stashId
            
            Player.PlayerData.items[item.slot].info = item.info
            Player.Functions.SetInventory(Player.PlayerData.items)
        end

        -- Trigger client side logic to drop bag on the ground
        TriggerClientEvent("rsg-backpacks:client:placeBackpack", src, itemName, item.info.uid, item.slot)
    end)
end

-- Server event to process removing item and preparing stash
RegisterNetEvent('rsg-backpacks:server:spawnBackpackOnGround', function(itemName, stashId, slot)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local item = Player.Functions.GetItemBySlot(slot)
    if not item or item.name ~= itemName or not item.info or item.info.uid ~= stashId then
        return
    end

    -- Remove item from player pockets
    Player.Functions.RemoveItem(itemName, 1, slot)
    TriggerClientEvent("inventory:client:ItemBox", src, RSGCore.Shared.Items[itemName], "remove")

    -- Initialize stash inside inventory global table
    local bpConfig = Config.Backpacks[itemName]
    exports['rsg-inventory']:CreateInventory(stashId, {
        label = RSGCore.Shared.Items[itemName].label or "Mochila",
        maxweight = bpConfig.weight,
        slots = bpConfig.slots
    })
end)
-- Helper robusto para calcular o peso total de um stash (com fallback do banco de dados e RSGCore.Shared.Items)
local function CalculateStashWeight(stashId)
    if not stashId then return 0 end
    local weight = 0
    local items = nil
    
    -- 1. Tenta buscar da memória do inventário ativo
    local inv = exports['rsg-inventory']:GetInventory(stashId)
    if inv and inv.items then
        items = inv.items
        print(("[rsg-backpacks Debug] CalculateStashWeight - Found in memory for %s. Item count: %s"):format(stashId, #items))
    else
        -- 2. Fallback: Busca direto do banco de dados
        local dbResult = MySQL.query.await('SELECT items FROM inventories WHERE identifier = ?', { stashId })
        if dbResult and dbResult[1] and dbResult[1].items then
            print(("[rsg-backpacks Debug] CalculateStashWeight - Database result for %s: %s"):format(stashId, tostring(dbResult[1].items)))
            items = json.decode(dbResult[1].items)
        else
            print(("[rsg-backpacks Debug] CalculateStashWeight - No database row found for %s"):format(stashId))
        end
    end
    
    if items then
        for _, item in pairs(items) do
            if item and item.amount then
                -- Fallback se o item não tiver a propriedade weight gravada no JSON do banco
                local itemWeight = item.weight
                if not itemWeight and RSGCore.Shared.Items[item.name] then
                    itemWeight = RSGCore.Shared.Items[item.name].weight
                end
                if itemWeight then
                    weight = weight + (itemWeight * item.amount)
                    print(("[rsg-backpacks Debug] Item %s (Amount: %s, Weight: %s) -> Total cumulative: %s"):format(item.name, item.amount, itemWeight, weight))
                end
            end
        end
    end
    
    print(("[rsg-backpacks Debug] CalculateStashWeight - Final calculated weight for %s: %s"):format(stashId, weight))
    return weight
end

-- Register the ground entity on server memory
RegisterNetEvent('rsg-backpacks:server:registerGroundBackpack', function(stashId, itemName, coords, rotation, netId, slot)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local uid = stashId:sub(1, 3) == "bp_" and stashId:sub(4) or stashId

    -- 1. Rate Limiting (Evita spam de requisições de registro de solo)
    local ok, err = Validation.RateLimit(src, "register_" .. uid, 1)
    if not ok then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Mochila', description = err, type = 'error' })
        return
    end

    -- 2. Validação de Distância
    local ok, err = Validation.Distance(src, coords, 5.0)
    if not ok then
        print(("[rsg-backpacks Security] Jogador %s falhou na distancia de registro: %s"):format(Player.PlayerData.citizenid, err))
        return
    end

    -- 3. Validação de Duplicidade (Anti-Duplication exploit)
    local ok, err = Validation.NoDuplication(src, uid)
    if not ok then
        print(("[rsg-backpacks Security] Jogador %s falhou na duplicidade: %s"):format(Player.PlayerData.citizenid, err))
        TriggerClientEvent('ox_lib:notify', src, { title = 'Erro', description = err, type = 'error' })
        return
    end

    -- 4. Validação de Posse (Ownership)
    local actualStashId = Utils.GetStashName(uid)
    local ownsBackpack = false
    local eqBackpack = Player.PlayerData.metadata.equippedBackpack
    if eqBackpack and eqBackpack.stashId == actualStashId then
        ownsBackpack = true
    else
        if slot then
            local item = Player.Functions.GetItemBySlot(slot)
            if item and item.info and item.info.uid == uid then
                ownsBackpack = true
            end
        else
            for _, item in pairs(Player.PlayerData.items) do
                if item and item.info and item.info.uid == uid then
                    ownsBackpack = true
                    slot = item.slot
                    break
                end
            end
        end
    end

    if not ownsBackpack then
        print(("[rsg-backpacks Security] Jogador %s tentou registrar mochila não autorizada %s"):format(Player.PlayerData.citizenid, uid))
        return
    end

    -- Resolve a entidade local do servidor a partir do netId
    local entity = 0
    pcall(function()
        entity = NetworkGetEntityFromNetworkId(netId)
    end)

    -- Grava/atualiza no banco de dados e define state = 'ground'
    UpdateBackpack(uid, {
        coords = coords,
        rotation = rotation,
        state = 'ground'
    })

    -- Remove o item dos bolsos ou o attach das costas
    if slot then
        Player.Functions.RemoveItem(itemName, 1, slot)
        TriggerClientEvent("inventory:client:ItemBox", src, RSGCore.Shared.Items[itemName], "remove")
    else
        Player.Functions.SetMetaData("equippedBackpack", nil)
        TriggerClientEvent('rsg-backpacks:client:detachFromBack', src)
    end

    -- Registra em memória para consulta rápida
    activeGroundBackpacks[uid] = {
        netId = netId,
        entityId = entity,
        stashId = actualStashId,
        itemName = itemName,
        coords = coords,
        rotation = rotation,
        owner = Player.PlayerData.citizenid,
        state = 'ground'
    }

    -- Sincroniza com todos os clientes
    TriggerClientEvent('rsg-backpacks:client:syncGroundBackpacks', -1, activeGroundBackpacks)
end)

-- Wear the backpack from the ground
RegisterNetEvent('rsg-backpacks:server:wearBackpack', function(stashId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local uid = stashId:sub(1, 3) == "bp_" and stashId:sub(4) or stashId

    -- Rate Limit
    local ok, err = Validation.RateLimit(src, "wear_" .. uid, 1)
    if not ok then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Mochila', description = err, type = 'error' })
        return
    end

    -- Validação de Existência
    local ok, err = Validation.Exists(uid)
    if not ok then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Mochila', description = err, type = 'error' })
        return
    end

    local bpData = activeGroundBackpacks[uid]

    -- Validação de Distância (Máx 3.0 metros)
    local entityCoords = bpData.coords
    if bpData.entityId and DoesEntityExist(bpData.entityId) then
        entityCoords = GetEntityCoords(bpData.entityId)
    end
    local ok, err = Validation.Distance(src, entityCoords, 3.0)
    if not ok then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Mochila', description = err, type = 'error' })
        return
    end

    -- Validação de Estado (Deve ser 'ground', não pode ser 'open')
    local ok, err = Validation.State(uid, 'ground')
    if not ok then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Mochila', description = err, type = 'error' })
        return
    end

    -- Validação de Durabilidade (Mochilas rasgadas/ruídas <10% não podem ser vestidas)
    local bp = GetBackpackByUid(uid)
    if bp and bp.durability and bp.durability < 10 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Mochila Danificada',
            description = 'Esta mochila está rasgada e não pode ser vestida!',
            type = 'error'
        })
        return
    end

    -- Validação de Peso (Não pode pesar mais que 35.000g / 35 Kg)
    local weight = CalculateStashWeight(stashId)
    if weight > 35000 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Muito Pesada',
            description = ('Esta mochila pesa %0.2f Kg e excede o limite máximo permitido para carregar nas costas (Max: 35.00 Kg)!'):format(weight / 1000),
            type = 'error',
            duration = 5000
        })
        return
    end

    -- Seta metadados indicando que o jogador está vestindo a mochila
    Player.Functions.SetMetaData("equippedBackpack", {
        stashId = bpData.stashId,
        itemName = bpData.itemName
    })

    -- Remove a mochila do solo na memória e no banco de dados
    activeGroundBackpacks[uid] = nil
    UpdateBackpack(uid, { state = 'equipped', coords = nil, rotation = 0.0 })

    -- Deleta a entidade física no servidor (OneSync)
    local entity = 0
    pcall(function()
        entity = NetworkGetEntityFromNetworkId(bpData.netId)
    end)
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end

    -- Remove a entidade física do solo para todos os clientes
    TriggerClientEvent('rsg-backpacks:client:removeGroundBackpack', -1, stashId, bpData.netId)

    -- Acopla o objeto local nas costas do jogador
    TriggerClientEvent('rsg-backpacks:client:attachToBack', src, stashId, bpData.itemName)
end)

-- Pick up / roll up backpack into pockets
RegisterNetEvent('rsg-backpacks:server:pickupBackpack', function(stashId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local uid = stashId:sub(1, 3) == "bp_" and stashId:sub(4) or stashId

    -- Rate Limit
    local ok, err = Validation.RateLimit(src, "pickup_" .. uid, 1)
    if not ok then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Mochila', description = err, type = 'error' })
        return
    end

    -- Validação de Existência
    local ok, err = Validation.Exists(uid)
    if not ok then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Mochila', description = err, type = 'error' })
        return
    end

    local bpData = activeGroundBackpacks[uid]

    -- Validação de Distância (Máx 3.0 metros)
    local entityCoords = bpData.coords
    if bpData.entityId and DoesEntityExist(bpData.entityId) then
        entityCoords = GetEntityCoords(bpData.entityId)
    end
    local ok, err = Validation.Distance(src, entityCoords, 3.0)
    if not ok then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Mochila', description = err, type = 'error' })
        return
    end

    -- Validação de Estado (Deve ser 'ground', não pode ser 'open')
    local ok, err = Validation.State(uid, 'ground')
    if not ok then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Mochila', description = err, type = 'error' })
        return
    end

    -- Check if stash is empty
    local stashWeight = CalculateStashWeight(stashId)
    if stashWeight > 0 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Mochila Ocupada',
            description = 'Não é possível recolher a mochila com itens dentro!',
            type = 'error',
            duration = 5000
        })
        return
    end

    local info = {
        uid = uid,
        stashId = stashId
    }

    if Player.Functions.AddItem(bpData.itemName, 1, nil, info) then
        TriggerClientEvent("inventory:client:ItemBox", src, RSGCore.Shared.Items[bpData.itemName], "add")
        
        -- Delete ground entity for everyone
        activeGroundBackpacks[uid] = nil
        UpdateBackpack(uid, { state = 'item', coords = nil, rotation = 0.0 })

        -- Deleta a entidade física no servidor (OneSync)
        local entity = 0
        pcall(function()
            entity = NetworkGetEntityFromNetworkId(bpData.netId)
        end)
        if entity and entity ~= 0 and DoesEntityExist(entity) then
            DeleteEntity(entity)
        end

        TriggerClientEvent('rsg-backpacks:client:removeGroundBackpack', -1, stashId, bpData.netId)
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Sem Espaço',
            description = 'Você não tem espaço para recolher a mochila!',
            type = 'error',
            duration = 5000
        })
    end
end)

-- Helper to check if a backpack stash is empty
local function isBackpackEmpty(stashId)
    local inv = exports['rsg-inventory']:GetInventory(stashId)
    if not inv or not inv.items then return true end
    for _, item in pairs(inv.items) do
        if item then return false end
    end
    return true
end

-- Shared unequip backpack logic (sempre coloca no chão)
local function unequipBackpack(src)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local eqBackpack = Player.PlayerData.metadata.equippedBackpack
    if not eqBackpack or not eqBackpack.stashId then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Mochila',
            description = 'Você não está vestindo nenhuma mochila nas costas!',
            type = 'error',
            duration = 5000
        })
        return
    end

    local stashId = eqBackpack.stashId
    local itemName = eqBackpack.itemName

    -- Remove a mochila e anexa ao solo (o metadado é limpo no registro seguro)
    TriggerClientEvent('rsg-backpacks:client:doffAndPlaceOnGround', src, stashId, itemName)
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Mochila',
        description = 'Mochila colocada no chão!',
        type = 'warning',
        duration = 5000
    })
end

RegisterNetEvent('rsg-backpacks:server:unequipBackpack', function()
    unequipBackpack(source)
end)

-- Command to drop / unequip backpack
RegisterCommand("mochila", function(source, args, rawCommand)
    local src = source
    if src > 0 then
        unequipBackpack(src)
    end
end)

-- Command to debug backpack state
RegisterCommand("debugmochila", function(source, args, rawCommand)
    local src = source
    if src == 0 or RSGCore.Functions.HasPermission(src, 'admin') or RSGCore.Functions.HasPermission(src, 'god') then
        print("[rsg-backpacks Debug] Active Ground Backpacks:")
        print(json.encode(activeGroundBackpacks, {indent = true}))
        
        if src > 0 then
            local Player = RSGCore.Functions.GetPlayer(src)
            if Player then
                print("[rsg-backpacks Debug] Player Metadata:")
                print(json.encode(Player.PlayerData.metadata.equippedBackpack, {indent = true}))
            end
        end
    end
end)

-- Spawn attachment on login if already wearing one
RegisterNetEvent('RSGCore:Server:OnPlayerLoaded', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if Player then
        local eqBackpack = Player.PlayerData.metadata.equippedBackpack
        if eqBackpack and eqBackpack.stashId then
            TriggerClientEvent('rsg-backpacks:client:attachToBack', src, eqBackpack.stashId, eqBackpack.itemName)
        end
    end
end)

-- Command to query inventories table
RegisterCommand("testdb", function(source, args, rawCommand)
    local src = source
    if src == 0 or RSGCore.Functions.HasPermission(src, 'admin') or RSGCore.Functions.HasPermission(src, 'god') then
        local results = MySQL.query.await("SELECT identifier, SUBSTRING(items, 1, 100) as items_preview FROM inventories LIMIT 10")
        print("[rsg-backpacks Debug] Inventories Table Contents:")
        print(json.encode(results, {indent = true}))
    end
end)

lib.callback.register('rsg-backpacks:server:getStashWeight', function(source, stashId)
    local weight = CalculateStashWeight(stashId)
    print(("[rsg-backpacks Debug] Server getStashWeight callback called for %s. Weight: %s"):format(stashId, weight))
    return weight
end)
