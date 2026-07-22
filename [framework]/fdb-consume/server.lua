local RSGCore = exports['rsg-core']:GetCoreObject()

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

                -- Aplicar Metadatas
                Player.Functions.SetMetaData('hunger', newHunger)
                Player.Functions.SetMetaData('thirst', newThirst)
                Player.Functions.SetMetaData('stress', newStress)
                Player.Functions.SetMetaData('alcohol', newAlcohol)

                -- Dar o item de retorno (se houver)
                if data.give and data.give.item then
                    if Player.Functions.AddItem(data.give.item, data.give.count or 1) then
                        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[data.give.item], "add")
                    else
                        print("^3[fdb-consume] AVISO: Nao foi possivel dar o item de retorno "..data.give.item.." para o jogador "..src.." (inventário cheio?)^7")
                    end
                end

                -- Disparar a Animação no Cliente passando o NOME DO ITEM para maior segurança
                TriggerClientEvent('fdb-consume:client:playAnim', src, itemName)
            end
        end)
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
                    -- Trigger para verificar efeitos no cliente baseado no novo valor
                    TriggerClientEvent('fdb-consume:client:checkAlcohol', player, newAlcohol)
                end
            end
        end
    end
end)
