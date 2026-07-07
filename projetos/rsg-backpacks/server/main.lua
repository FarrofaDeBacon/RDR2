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
for itemName, _ in pairs(Config.Backpacks) do
    RSGCore.Functions.CreateUseableItem(itemName, function(source, item)
        local src = source
        local Player = RSGCore.Functions.GetPlayer(src)
        if not Player then return end

        local usedItemName = itemName  -- usa a variável do closure que é garantidamente correta
        local bpConfig = Config.Backpacks[usedItemName]

        print(("[rsg-backpacks] USAR ITEM: itemName=%s | item.name=%s | isClothing=%s | bpConfig=%s"):format(
            tostring(usedItemName),
            tostring(item and item.name or "nil"),
            tostring(bpConfig and bpConfig.isClothing or "nil"),
            tostring(bpConfig ~= nil)
        ))

        local isSatchel = bpConfig and (bpConfig.isClothing or usedItemName == "doctor_bag")

        -- Validação: Impede de vestir se já tiver outra do mesmo tipo equipada
        if isSatchel then
            if Player.PlayerData.metadata.equipmentSlots and Player.PlayerData.metadata.equipmentSlots.satchel then
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Bolsa',
                    description = 'Você já está usando uma bolsa lateral! Retire a atual primeiro.',
                    type = 'error',
                    duration = 5000
                })
                return
            end
        else
            if Player.PlayerData.metadata.equipmentSlots and Player.PlayerData.metadata.equipmentSlots.backpack then
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Mochila',
                    description = 'Você já está vestindo uma mochila nas costas! Coloque a atual no chão primeiro.',
                    type = 'error',
                    duration = 5000
                })
                return
            end
        end

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

        local stashId = item.info.stashId

        -- ========================================================
        -- FLUXO: Se for bolsa nativa/roupa ou maleta de mão, veste
        -- diretamente do inventário sem precisar jogar no chão.
        -- ========================================================
        if bpConfig.isClothing or usedItemName == "doctor_bag" then
            -- Inicializa o stash no inventário
            exports['rsg-inventory']:CreateInventory(stashId, {
                label = RSGCore.Shared.Items[usedItemName].label or "Mochila",
                maxweight = bpConfig.weight,
                slots = bpConfig.slots
            })

            -- Grava metadados e atualiza estado para equipado
            local eq = Player.PlayerData.metadata.equipmentSlots or {backpack=nil,satchel=nil,wallet=nil,holster=nil}
            local lookup = RSGCore.Shared.Items[usedItemName]
            eq.satchel = {
                name = usedItemName,
                label = lookup and lookup.label or "Satchel",
                amount = 1,
                image = lookup and lookup.image or "satchel.png",
                weight = lookup and lookup.weight or 1000,
                info = { quality = 100, stashId = stashId, uid = item.info and item.info.uid or nil },
                slot = 'satchel',
                stashId = stashId,
                itemName = usedItemName
            }
        Player.Functions.SetMetaData('equipmentSlots', eq)
            UpdateBackpack(item.info.uid, { state = 'equipped', coords = nil, rotation = 0.0 })

            -- Remove dos bolsos (pockets) pois agora está equipada
            Player.Functions.RemoveItem(usedItemName, 1, item.slot)
            TriggerClientEvent("inventory:client:ItemBox", src, RSGCore.Shared.Items[usedItemName], "remove")

            -- Anexa diretamente no corpo do jogador com animação
            TriggerClientEvent('rsg-backpacks:client:attachDirectly', src, stashId, usedItemName)
            
            -- Atualiza a UI do inventário para refletir o slot
            TriggerClientEvent('rsg-inventory:client:updateInventory', src)
        else
            -- Para mochilas de lona grandes, mantém o fluxo físico de colocar no chão primeiro
            TriggerClientEvent("rsg-backpacks:client:placeBackpack", src, usedItemName, item.info.uid, item.slot)
        end
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
    local eqBackpack = Player.PlayerData.metadata.equipmentSlots and Player.PlayerData.metadata.equipmentSlots.backpack
    local eqSatchel = Player.PlayerData.metadata.equipmentSlots and Player.PlayerData.metadata.equipmentSlots.satchel
    if (eqBackpack and eqBackpack.stashId == actualStashId) or (eqSatchel and eqSatchel.stashId == actualStashId) then
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

    -- Remove o item dos bolsos ou o attach das costas/lateral
    if slot then
        Player.Functions.RemoveItem(itemName, 1, slot)
        TriggerClientEvent("inventory:client:ItemBox", src, RSGCore.Shared.Items[itemName], "remove")
    else
        local bpConfig = Config.Backpacks[itemName]
        local isSatchel = bpConfig and (bpConfig.isClothing or itemName == "doctor_bag")
        if isSatchel then
            local eq = Player.PlayerData.metadata.equipmentSlots or {backpack=nil,satchel=nil,wallet=nil,holster=nil}
        eq.satchel = nil
        Player.Functions.SetMetaData('equipmentSlots', eq)
            TriggerClientEvent('rsg-backpacks:client:detachSatchel', src)
        else
            local eq = Player.PlayerData.metadata.equipmentSlots or {backpack=nil,satchel=nil,wallet=nil,holster=nil}
        eq.backpack = nil
        Player.Functions.SetMetaData('equipmentSlots', eq)
            TriggerClientEvent('rsg-backpacks:client:detachFromBack', src)
        end
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
    if not bpData then return end

    local bpConfig = Config.Backpacks[bpData.itemName]
    local isSatchel = bpConfig and (bpConfig.isClothing or bpData.itemName == "doctor_bag")

    if isSatchel then
        if Player.PlayerData.metadata.equipmentSlots and Player.PlayerData.metadata.equipmentSlots.satchel then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Mochila',
                description = 'Você já está usando uma bolsa lateral! Retire a atual primeiro antes de vestir outra.',
                type = 'error',
                duration = 5000
            })
            return
        end
    else
        if Player.PlayerData.metadata.equipmentSlots and Player.PlayerData.metadata.equipmentSlots.backpack then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Mochila',
                description = 'Você já está vestindo uma mochila nas costas! Coloque a atual no chão primeiro.',
                type = 'error',
                duration = 5000
            })
            return
        end
    end

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

    local bpConfig = Config.Backpacks[bpData.itemName]
    local isSatchel = bpConfig and (bpConfig.isClothing or bpData.itemName == "doctor_bag")

    local lookup = RSGCore.Shared.Items[bpData.itemName]
    if isSatchel then
        local eq = Player.PlayerData.metadata.equipmentSlots or {backpack=nil,satchel=nil,wallet=nil,holster=nil}
        eq.satchel = {
            name = bpData.itemName,
            label = lookup and lookup.label or "Satchel",
            amount = 1,
            image = lookup and lookup.image or "satchel.png",
            weight = lookup and lookup.weight or 1000,
            info = { quality = 100, stashId = bpData.stashId, uid = uid },
            slot = 'satchel',
            stashId = bpData.stashId,
            itemName = bpData.itemName
        }
        Player.Functions.SetMetaData('equipmentSlots', eq)
    else
        local eq = Player.PlayerData.metadata.equipmentSlots or {backpack=nil,satchel=nil,wallet=nil,holster=nil}
        eq.backpack = {
            name = bpData.itemName,
            label = lookup and lookup.label or "Mochila",
            amount = 1,
            image = lookup and lookup.image or "backpack.png",
            weight = lookup and lookup.weight or 1000,
            info = { quality = 100, stashId = bpData.stashId, uid = uid },
            slot = 'backpack',
            stashId = bpData.stashId,
            itemName = bpData.itemName
        }
        Player.Functions.SetMetaData('equipmentSlots', eq)
    end

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

    -- Acopla o objeto local no corpo/mão do jogador
    TriggerClientEvent('rsg-backpacks:client:attachToBack', src, stashId, bpData.itemName)

    -- Atualiza a UI do inventário para refletir o slot
    TriggerClientEvent('rsg-inventory:client:updateInventory', src)
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

    -- Allow picking up full stashes as requested by user

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

-- Shared unequip backpack logic (mochila de costas)
local function unequipBackpack(src)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local eqBackpack = Player.PlayerData.metadata.equipmentSlots and Player.PlayerData.metadata.equipmentSlots.backpack
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
    
    -- Fecha o inventário para que o alt-target funcione imediatamente
    TriggerClientEvent('rsg-inventory:client:closeInv', src)
    
    -- Atualiza a UI do inventário para refletir o slot vazio
    TriggerClientEvent('rsg-inventory:client:updateInventory', src)

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Mochila',
        description = 'Mochila colocada no chão!',
        type = 'warning',
        duration = 5000
    })
end

local function unequipSatchelToGround(src)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local eqSatchel = Player.PlayerData.metadata.equipmentSlots and Player.PlayerData.metadata.equipmentSlots.satchel
    if not eqSatchel or not eqSatchel.stashId then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Bolsa',
            description = 'Você não está usando nenhuma bolsa lateral ou de mão!',
            type = 'error',
            duration = 5000
        })
        return
    end

    local stashId = eqSatchel.stashId
    local itemName = eqSatchel.itemName

    -- Remove a bolsa e anexa ao solo (o metadado é limpo no registro seguro)
    TriggerClientEvent('rsg-backpacks:client:doffAndPlaceOnGround', src, stashId, itemName)
    
    -- Fecha o inventário para que o alt-target funcione imediatamente
    TriggerClientEvent('rsg-inventory:client:closeInv', src)
    
    -- Atualiza a UI do inventário para refletir o slot vazio
    TriggerClientEvent('rsg-inventory:client:updateInventory', src)

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Bolsa',
        description = 'Bolsa colocada no chão!',
        type = 'warning',
        duration = 5000
    })
end

local function unequipBackpackToPocket(src)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local eqBackpack = Player.PlayerData.metadata.equipmentSlots and Player.PlayerData.metadata.equipmentSlots.backpack
    if not eqBackpack or not eqBackpack.stashId then
        return
    end

    local stashId = eqBackpack.stashId
    local itemName = eqBackpack.itemName
    local uid = stashId:sub(1, 3) == "bp_" and stashId:sub(4) or stashId

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

    if Player.Functions.AddItem(itemName, 1, nil, info) then
        TriggerClientEvent("inventory:client:ItemBox", src, RSGCore.Shared.Items[itemName], "add")
        local eq = Player.PlayerData.metadata.equipmentSlots or {backpack=nil,satchel=nil,wallet=nil,holster=nil}
        eq.backpack = nil
        Player.Functions.SetMetaData('equipmentSlots', eq)
        UpdateBackpack(uid, { state = 'item', coords = nil, rotation = 0.0 })
        
        TriggerClientEvent('rsg-backpacks:client:detachBackpack', src)
        
        -- Atualiza a UI do inventário para refletir o slot vazio
        TriggerClientEvent('rsg-inventory:client:updateInventory', src)

        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Mochila',
            description = 'Mochila guardada nos seus bolsos!',
            type = 'success',
            duration = 5000
        })
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Sem Espaço',
            description = 'Você não tem espaço nos bolsos para guardar a mochila!',
            type = 'error',
            duration = 5000
        })
    end
end

-- Shared unequip satchel logic (bolsa lateral/mão - guarda nos bolsos)
local function unequipSatchel(src)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local eqSatchel = Player.PlayerData.metadata.equipmentSlots and Player.PlayerData.metadata.equipmentSlots.satchel
    if not eqSatchel or not eqSatchel.stashId then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Bolsa',
            description = 'Você não está usando nenhuma bolsa lateral ou de mão!',
            type = 'error',
            duration = 5000
        })
        return
    end

    local stashId = eqSatchel.stashId
    local itemName = eqSatchel.itemName
    local uid = stashId:sub(1, 3) == "bp_" and stashId:sub(4) or stashId

    -- Bloqueia desequipar bolsa com itens dentro
    -- Tenta os dois identificadores possiveis: stashId completo e uid sem prefixo
    print(('[rsg-backpacks] unequipSatchel - stashId=%s uid=%s'):format(tostring(stashId), tostring(uid)))
    local stashWeight = CalculateStashWeight(stashId)
    if stashWeight <= 0 and stashId ~= uid then
        stashWeight = CalculateStashWeight(uid)
    end
    print(('[rsg-backpacks] unequipSatchel - peso calculado: %s'):format(tostring(stashWeight)))
    if stashWeight > 0 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Bolsa com Itens',
            description = 'Nao e possivel guardar a bolsa com itens dentro!',
            type = 'error',
            duration = 5000
        })
        return
    end

    local info = {
        uid = uid,
        stashId = stashId
    }

    if Player.Functions.AddItem(itemName, 1, nil, info) then
        TriggerClientEvent("inventory:client:ItemBox", src, RSGCore.Shared.Items[itemName], "add")
        local eq = Player.PlayerData.metadata.equipmentSlots or {backpack=nil,satchel=nil,wallet=nil,holster=nil}
        eq.satchel = nil
        Player.Functions.SetMetaData('equipmentSlots', eq)
        UpdateBackpack(uid, { state = 'item', coords = nil, rotation = 0.0 })
        
        -- Detacha a bolsa visualmente no cliente e fecha o inventário
        TriggerClientEvent('rsg-backpacks:client:detachSatchel', src)
        TriggerClientEvent('rsg-inventory:client:closeInv', src)
        
        -- Atualiza a UI do inventário para refletir o slot vazio
        TriggerClientEvent('rsg-inventory:client:updateInventory', src)

        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Bolsa',
            description = 'Bolsa guardada nos seus bolsos!',
            type = 'success',
            duration = 5000
        })
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Bolsa',
            description = 'Você não tem espaço nos bolsos para guardar a bolsa!',
            type = 'error',
            duration = 5000
        })
    end
end

-- UI Doff Button for Backpack (mochila de costas) -> Para o chao
RegisterNetEvent('rsg-backpacks:server:unequipBackpack', function(playerSrc)
    local src = playerSrc or source
    unequipBackpack(src)
end)

RegisterNetEvent('rsg-backpacks:server:unequipSatchelToGround', function(playerSrc)
    local src = playerSrc or source
    unequipSatchelToGround(src)
end)

RegisterNetEvent('rsg-backpacks:server:unequipBackpackToPocket', function(playerSrc)
    local src = playerSrc or source
    unequipBackpackToPocket(src)
end)

-- UI Doff Button for Satchel (bolsa lateral/mão)
RegisterNetEvent('rsg-backpacks:server:unequipSatchel', function(playerSrc)
    local src = playerSrc or source
    unequipSatchel(src)
end)

-- Command to drop / unequip backpack (costas)
RegisterCommand("mochila", function(source, args, rawCommand)
    local src = source
    if src > 0 then
        unequipBackpack(src)
    end
end)

-- Command to drop / unequip satchel (lateral)
RegisterCommand("tirarbolsa", function(source, args, rawCommand)
    local src = source
    if src > 0 then
        unequipSatchel(src)
    end
end)

-- Command to debug backpack state
RegisterCommand("debugmochila", function(source, args, rawCommand)
    local src = source
    if src == 0 or RSGCore.Functions.HasPermission(src, 'admin') or RSGCore.Functions.HasPermission(src, 'god') then
        print("[rsg-backpacks Debug] Active Ground Backpacks:")
        for uid, data in pairs(activeGroundBackpacks) do
            print(("- UID: %s | Item: %s | Owner: %s | State: %s"):format(uid, data.itemName, data.owner, data.state))
        end
        
        if src > 0 then
            local Player = RSGCore.Functions.GetPlayer(src)
            if Player then
                local msg = ("Backpack: %s\nSatchel: %s"):format(
                    json.encode(Player.PlayerData.metadata.equipmentSlots and Player.PlayerData.metadata.equipmentSlots.backpack),
                    json.encode(Player.PlayerData.metadata.equipmentSlots and Player.PlayerData.metadata.equipmentSlots.satchel)
                )
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Debug Mochila',
                    description = msg,
                    type = 'info',
                    duration = 10000
                })
                print("[rsg-backpacks Debug] Player Metadata:")
                print("equippedBackpack: " .. json.encode(Player.PlayerData.metadata.equipmentSlots and Player.PlayerData.metadata.equipmentSlots.backpack, {indent = true}))
                print("equippedSatchel: " .. json.encode(Player.PlayerData.metadata.equipmentSlots and Player.PlayerData.metadata.equipmentSlots.satchel, {indent = true}))
            end
        end
    end
end)

-- Spawn attachment on login if already wearing one
RegisterNetEvent('RSGCore:Server:OnPlayerLoaded', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if Player then
        local eqBackpack = Player.PlayerData.metadata.equipmentSlots and Player.PlayerData.metadata.equipmentSlots.backpack
        if eqBackpack and eqBackpack.stashId then
            TriggerClientEvent('rsg-backpacks:client:attachToBack', src, eqBackpack.stashId, eqBackpack.itemName)
        end
        local eqSatchel = Player.PlayerData.metadata.equipmentSlots and Player.PlayerData.metadata.equipmentSlots.satchel
        if eqSatchel and eqSatchel.stashId then
            TriggerClientEvent('rsg-backpacks:client:attachToBack', src, eqSatchel.stashId, eqSatchel.itemName)
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

-- Evento para limpar metadados de mochila e bolsa do jogador do banco/memória
RegisterNetEvent('rsg-backpacks:server:clearBackpackMetadata', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if Player then
        local eq = Player.PlayerData.metadata.equipmentSlots or {backpack=nil,satchel=nil,wallet=nil,holster=nil}
        eq.backpack = nil
        Player.Functions.SetMetaData('equipmentSlots', eq)
        local eq = Player.PlayerData.metadata.equipmentSlots or {backpack=nil,satchel=nil,wallet=nil,holster=nil}
        eq.satchel = nil
        Player.Functions.SetMetaData('equipmentSlots', eq)
        
        -- Deleta do banco de dados qualquer mochila física do jogador que estava no solo
        MySQL.query.await('DELETE FROM backpacks WHERE owner = ?', { Player.PlayerData.citizenid })
        
        -- Limpa em memória e deleta entidades ativas no jogo
        for uid, data in pairs(activeGroundBackpacks) do
            if data.owner == Player.PlayerData.citizenid then
                activeGroundBackpacks[uid] = nil
                local entity = 0
                pcall(function()
                    entity = NetworkGetEntityFromNetworkId(data.netId)
                end)
                if entity and entity ~= 0 and DoesEntityExist(entity) then
                    DeleteEntity(entity)
                end
                TriggerClientEvent('rsg-backpacks:client:removeGroundBackpack', -1, uid, data.netId)
            end
        end
        
        print(("[rsg-backpacks] Limpeza completa de metadados e solo executada por citizenid: %s"):format(Player.PlayerData.citizenid))
    end
end)
