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

    exports['fdb-survival']:AddHunger(src, consume.stats.hunger)
    exports['fdb-survival']:AddThirst(src, consume.stats.thirst)
    exports['fdb-survival']:AddStress(src, consume.stats.stress)
    exports['fdb-survival']:AddAlcohol(src, consume.stats.alcohol)

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



AddEventHandler('playerDropped', function(reason)
    local src = source
    if activeConsumptions[src] then
        activeConsumptions[src] = nil
    end
end)
