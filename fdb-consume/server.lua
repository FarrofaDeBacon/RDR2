local RSGCore = exports['rsg-core']:GetCoreObject()
local activeConsumptions = {}

-- Registrar Itens Consumíveis
CreateThread(function()
    local count = 0
    for itemName, data in pairs(Config.Items) do
        count = count + 1

        -- Validação no boot
        if data.give and data.give.item then
            if not RSGCore.Shared.Items[data.give.item] then
                print("^1[fdb-consume] ERRO: O item de retorno '"..data.give.item.."' configurado para '"..itemName.."' nao existe no RSGCore.^7")
            end
        end

        RSGCore.Functions.CreateUseableItem(itemName, function(source, item)
            local src = source
            local Player = RSGCore.Functions.GetPlayer(src)
            if not Player then return end
            
            -- Servidor é quem retira o item (impossível fraudar no cliente)
            if Player.Functions.RemoveItem(item.name, 1, item.slot) then
                -- Atualizar o inventário visualmente
                TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[item.name], "remove")

                local uses = data.uses or 3 -- Se não tiver uses definido, padrão 3 mordidas
                if Config.Animations[data.type] and Config.Animations[data.type].uses then
                    uses = data.uses or Config.Animations[data.type].uses
                end

                activeConsumptions[src] = {
                    itemName = itemName,
                    totalUses = uses,
                    currentUses = uses,
                    stats = {
                        hunger = (data.hunger or 0) / uses,
                        thirst = (data.thirst or 0) / uses,
                        stress = (data.stress or 0) / uses,
                        alcohol = (data.alcohol or 0) / uses,
                        health = (data.health or 0) / uses,
                        stamina = (data.stamina or 0) / uses,
                    },
                    returnItem = data.give and data.give.item or nil
                }

                -- Avisa o cliente para segurar o prop (e começar a animação/loop de botão)
                TriggerClientEvent('fdb-consume:client:playAnim', src, itemName)
            end
        end)
    end
end)

RegisterNetEvent('fdb-consume:server:takeBite', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local consume = activeConsumptions[src]
    if not consume or consume.currentUses <= 0 then
        TriggerClientEvent('fdb-consume:client:StopInteractiveConsumable', src)
        return
    end

    consume.currentUses = consume.currentUses - 1

    local currentHunger = Player.PlayerData.metadata['hunger'] or 100
    local currentThirst = Player.PlayerData.metadata['thirst'] or 100
    local currentStress = Player.PlayerData.metadata['stress'] or 0
    local currentAlcohol = Player.PlayerData.metadata['alcohol'] or 0

    local newHunger = math.max(0, math.min(100, currentHunger + consume.stats.hunger))
    local newThirst = math.max(0, math.min(100, currentThirst + consume.stats.thirst))
    local newStress = math.max(0, math.min(100, currentStress + consume.stats.stress))
    local newAlcohol = math.max(0, math.min(Config.Alcohol.MaxAlcoholLevel, currentAlcohol + consume.stats.alcohol))

    Player.Functions.SetMetaData('hunger', newHunger)
    Player.Functions.SetMetaData('thirst', newThirst)
    Player.Functions.SetMetaData('stress', newStress)
    Player.Functions.SetMetaData('alcohol', newAlcohol)
    
    TriggerClientEvent('fdb-survival:client:stateChanged', src, { field = 'food', value = math.floor(newHunger) })
    TriggerClientEvent('fdb-survival:client:stateChanged', src, { field = 'water', value = math.floor(newThirst) })
    TriggerClientEvent('fdb-survival:client:stateChanged', src, { field = 'stress', value = math.floor(newStress) })
    TriggerClientEvent('fdb-survival:client:stateChanged', src, { field = 'drunkenness', value = math.floor(newAlcohol) })
    TriggerClientEvent('fdb-consume:client:checkAlcohol', src, newAlcohol)

    if consume.stats.health ~= 0 or consume.stats.stamina ~= 0 then
        TriggerClientEvent('fdb-consume:client:applyHealthStamina', src, consume.stats.health, consume.stats.stamina)
    end

    if consume.currentUses <= 0 then
        if consume.returnItem then
            if Player.Functions.AddItem(consume.returnItem, 1) then
                TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[consume.returnItem], "add")
            end
        end
        activeConsumptions[src] = nil
        TriggerClientEvent('fdb-consume:client:StopInteractiveConsumable', src)
    end
end)

RegisterNetEvent('fdb-consume:server:cancelConsume', function()
    local src = source
    if activeConsumptions[src] then
        activeConsumptions[src] = nil
    end
end)

-- Loop de Decaimento do Álcool (Server-Side)
CreateThread(function()
    while true do
        Wait(Config.Alcohol.DecreaseInterval)
        for _, player in ipairs(RSGCore.Functions.GetPlayers()) do
            local Player = RSGCore.Functions.GetPlayer(player)
            if Player then
                local currentAlcohol = Player.PlayerData.metadata['alcohol'] or 0
                if currentAlcohol > 0 then
                    local newAlcohol = math.max(0, math.min(Config.Alcohol.MaxAlcoholLevel, currentAlcohol - Config.Alcohol.DecreaseAmount))
                    Player.Functions.SetMetaData('alcohol', newAlcohol)
                    -- Sincronizar HUD passivo
                    TriggerClientEvent('fdb-survival:client:stateChanged', player, { field = 'drunkenness', value = math.floor(newAlcohol) })
                    -- Trigger para verificar efeitos no cliente baseado no novo valor
                    TriggerClientEvent('fdb-consume:client:checkAlcohol', player, newAlcohol)
                end
            end
        end
    end
end)

-- Loop Passivo de Fome e Sede (Server-Side)
CreateThread(function()
    while true do
        Wait(Config.Metabolism.DrainInterval)
        for _, player in ipairs(RSGCore.Functions.GetPlayers()) do
            local Player = RSGCore.Functions.GetPlayer(player)
            if Player then
                local currentHunger = Player.PlayerData.metadata['hunger'] or 100
                local currentThirst = Player.PlayerData.metadata['thirst'] or 100
                
                if currentHunger > 0 or currentThirst > 0 then
                    local newHunger = math.max(0, currentHunger - Config.Metabolism.HungerDrain)
                    local newThirst = math.max(0, currentThirst - Config.Metabolism.ThirstDrain)
                    
                    Player.Functions.SetMetaData('hunger', newHunger)
                    Player.Functions.SetMetaData('thirst', newThirst)
                    
                    local floorHunger = math.floor(newHunger)
                    local floorThirst = math.floor(newThirst)
                    local oldFloorHunger = math.floor(currentHunger)
                    local oldFloorThirst = math.floor(currentThirst)
                    
                    if floorHunger ~= oldFloorHunger then
                        TriggerClientEvent('fdb-survival:client:stateChanged', player, { field = 'food', value = floorHunger })
                    end
                    if floorThirst ~= oldFloorThirst then
                        TriggerClientEvent('fdb-survival:client:stateChanged', player, { field = 'water', value = floorThirst })
                    end
                end
            end
        end
    end
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    if activeConsumptions[src] then
        activeConsumptions[src] = nil
    end
end)
