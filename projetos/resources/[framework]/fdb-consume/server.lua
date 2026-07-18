local RSGCore = exports['rsg-core']:GetCoreObject()

-- Registrar Itens Consumíveis
CreateThread(function()
    for itemName, data in pairs(Config.Items) do
        RSGCore.Functions.CreateUseableItem(itemName, function(source, item)
            local src = source
            local Player = RSGCore.Functions.GetPlayer(src)
            if not Player then return end

            -- Servidor é quem retira o item (impossível fraudar no cliente)
            if Player.Functions.RemoveItem(item.name, 1, item.slot) then
                -- Opcional: Atualizar o inventário visualmente
                TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[item.name], "remove")

                -- Recuperar Metadatas Atuais
                local currentHunger = Player.PlayerData.metadata['hunger'] or 100
                local currentThirst = Player.PlayerData.metadata['thirst'] or 100
                local currentStress = Player.PlayerData.metadata['stress'] or 0
                local currentAlcohol = Player.PlayerData.metadata['alcohol'] or 0

                -- Matemática Segura
                local newHunger = lib.math.clamp(currentHunger + (data.hunger or 0), 0, 100)
                local newThirst = lib.math.clamp(currentThirst + (data.thirst or 0), 0, 100)
                local newStress = lib.math.clamp(currentStress + (data.stress or 0), 0, 100)
                local newAlcohol = lib.math.clamp(currentAlcohol + (data.alcohol or 0), 0, Config.Alcohol.MaxAlcoholLevel)

                -- Aplicar Metadatas (O Servidor que manda!)
                Player.Functions.SetMetaData('hunger', newHunger)
                Player.Functions.SetMetaData('thirst', newThirst)
                Player.Functions.SetMetaData('stress', newStress)
                Player.Functions.SetMetaData('alcohol', newAlcohol)

                -- Disparar a Animação no Cliente (visual apenas)
                TriggerClientEvent('fdb-consume:client:playAnim', src, data.type)
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
                    local newAlcohol = lib.math.clamp(currentAlcohol - Config.Alcohol.DecreaseAmount, 0, Config.Alcohol.MaxAlcoholLevel)
                    Player.Functions.SetMetaData('alcohol', newAlcohol)
                    -- Trigger para verificar efeitos no cliente baseado no novo valor
                    TriggerClientEvent('fdb-consume:client:checkAlcohol', player, newAlcohol)
                end
            end
        end
    end
end)
