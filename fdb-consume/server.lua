local RSGCore = exports['rsg-core']:GetCoreObject()
local pendingReturnItems = {}

-- Registrar Itens Consumíveis
CreateThread(function()
    print("^3[fdb-consume] INICIANDO REGISTRO DE ITENS...^7")
    local count = 0
    for itemName, data in pairs(Config.Items) do
        count = count + 1
        print("DEBUG fdb-consume: Registrando item: " .. itemName)

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
            
            print("DEBUG fdb-consume: Jogador " .. src .. " tentou usar " .. itemName)

            -- Servidor é quem retira o item (impossível fraudar no cliente)
            if Player.Functions.RemoveItem(item.name, 1, item.slot) then
                print("DEBUG fdb-consume: Item removido com sucesso!")
                -- Opcional: Atualizar o inventário visualmente
                TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[item.name], "remove")

                -- Recuperar Metadatas Atuais
                local currentHunger = Player.PlayerData.metadata['hunger'] or 100
                local currentThirst = Player.PlayerData.metadata['thirst'] or 100
                local currentStress = Player.PlayerData.metadata['stress'] or 0
                local currentAlcohol = Player.PlayerData.metadata['alcohol'] or 0

                -- Matemática Segura
                local newHunger = math.max(0, math.min(100, currentHunger + (data.hunger or 0)))
                local newThirst = math.max(0, math.min(100, currentThirst + (data.thirst or 0)))
                local newStress = math.max(0, math.min(100, currentStress + (data.stress or 0)))
                local newAlcohol = math.max(0, math.min(Config.Alcohol.MaxAlcoholLevel, currentAlcohol + (data.alcohol or 0)))

                -- Autorização para item de retorno
                local returnItem = data.give and data.give.item
                if returnItem then
                    if not pendingReturnItems[src] then pendingReturnItems[src] = {} end
                    pendingReturnItems[src][itemName] = (pendingReturnItems[src][itemName] or 0) + 1
                end

                -- Aplicar Metadatas
                Player.Functions.SetMetaData('hunger', newHunger)
                Player.Functions.SetMetaData('thirst', newThirst)
                Player.Functions.SetMetaData('stress', newStress)
                Player.Functions.SetMetaData('alcohol', newAlcohol)
                
                -- Avisar passivamente o HUD da mudança de dados do consume
                TriggerClientEvent('fdb-survival:client:stateChanged', src, { field = 'food', value = math.floor(newHunger) })
                TriggerClientEvent('fdb-survival:client:stateChanged', src, { field = 'water', value = math.floor(newThirst) })
                TriggerClientEvent('fdb-survival:client:stateChanged', src, { field = 'stress', value = math.floor(newStress) })
                TriggerClientEvent('fdb-survival:client:stateChanged', src, { field = 'drunkenness', value = math.floor(newAlcohol) })

                -- Dar o item de retorno foi movido para o final da animação no cliente
                TriggerClientEvent('fdb-consume:client:playAnim', src, itemName)
            end
        end)
    end
end)

RegisterNetEvent('fdb-consume:server:giveReturnItem', function(itemName)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    if not pendingReturnItems[src] or not pendingReturnItems[src][itemName] or pendingReturnItems[src][itemName] <= 0 then
        print(("[fdb-consume] HACK DETECTADO: Jogador %s tentou forjar item de retorno '%s' sem uso prévio."):format(src, itemName))
        return
    end

    pendingReturnItems[src][itemName] = pendingReturnItems[src][itemName] - 1

    local data = Config.Items[itemName]
    if data and data.give and data.give.item then
        if Player.Functions.AddItem(data.give.item, data.give.count or 1) then
            TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[data.give.item], "add")
        else
            print("^3[fdb-consume] AVISO: Nao foi possivel dar o item de retorno "..data.give.item.." para o jogador "..src.." (inventário cheio?)^7")
        end
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
    if pendingReturnItems[src] then
        pendingReturnItems[src] = nil
    end
end)
