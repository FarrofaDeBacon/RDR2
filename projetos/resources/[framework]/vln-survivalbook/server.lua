local RSGCore = exports['rsg-core']:GetCoreObject()

-- -------------------------------------------------------
-- Callbacks para verificar se o jogador tem os ingredientes
-- -------------------------------------------------------

-- Callback para receitas normais
lib.callback.register('vln-survivalbook:getRequirements', function(source, recipeName, amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return false, {} end

    local recipe = Config.Recipees[recipeName]
    if not recipe then return false, {} end

    local hasAllItems = true
    local missingItems = {}

    for _, ingredient in ipairs(recipe.items) do
        local requiredAmount = ingredient.amount * amount
        local itemData = Player.Functions.GetItemByName(ingredient.name)
        local playerAmount = itemData and itemData.amount or 0

        if playerAmount < requiredAmount then
            hasAllItems = false
            table.insert(missingItems, {
                itemName = ingredient.name,
                missingCount = requiredAmount - playerAmount
            })
        end
    end

    return hasAllItems, missingItems
end)

-- Callback para receitas de workshops/NPCs
lib.callback.register('vln-survivalbook:getRequirementsWeapon', function(source, recipeName, amount, shopId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return false, {} end

    local shop = Config.CraftLocations[shopId]
    if not shop or not shop.Craftables then return false, {} end

    local recipe = shop.Craftables[recipeName]
    if not recipe then return false, {} end

    local hasAllItems = true
    local missingItems = {}

    for _, ingredient in ipairs(recipe.items) do
        local requiredAmount = ingredient.amount * amount
        local itemData = Player.Functions.GetItemByName(ingredient.name)
        local playerAmount = itemData and itemData.amount or 0

        if playerAmount < requiredAmount then
            hasAllItems = false
            table.insert(missingItems, {
                itemName = ingredient.name,
                missingCount = requiredAmount - playerAmount
            })
        end
    end

    return hasAllItems, missingItems
end)

-- -------------------------------------------------------
-- Eventos
-- -------------------------------------------------------

-- Evento para obter o cargo/trabalho e nível de crafting do jogador
RegisterNetEvent('vln-survivalbook:getjob', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local jobName = Player.PlayerData.job.name
    local jobGrade = Player.PlayerData.job.grade.level
    local jobGroup = Player.PlayerData.job.group or "none"
    -- Obtém o nível de crafting salvo no metadado do jogador no RSG-Core (padrão level 1)
    local craftLevel = Player.Functions.GetMetaData("crafting_level") or 1

    TriggerClientEvent('vln-survivalbook:findjob', src, jobName, jobGrade, jobGroup, craftLevel)
end)

-- Evento de entrega do item craftado (com remoção dos ingredientes)
RegisterNetEvent('vln-survivalbook:giveItem', function(recipeItem, amount, category, shopId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local recipe = nil

    -- Busca a receita na config global ou na config do Workshop
    if shopId then
        local shop = Config.CraftLocations[shopId]
        if shop and shop.Craftables then
            recipe = shop.Craftables[recipeItem]
        end
    else
        recipe = Config.Recipees[recipeItem]
    end

    if not recipe then return end

    -- 1. Validação final de segurança: Verifica se o jogador ainda tem os itens
    for _, ingredient in ipairs(recipe.items) do
        local requiredAmount = ingredient.amount * amount
        local itemData = Player.Functions.GetItemByName(ingredient.name)
        local playerAmount = itemData and itemData.amount or 0

        if playerAmount < requiredAmount then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Erro de Crafting',
                description = 'Você não tem mais os ingredientes necessários!',
                type = 'error'
            })
            return
        end
    end

    -- 2. Remove os ingredientes do inventário
    for _, ingredient in ipairs(recipe.items) do
        local requiredAmount = ingredient.amount * amount
        Player.Functions.RemoveItem(ingredient.name, requiredAmount)
        TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[ingredient.name], 'remove')
    end

    -- 3. Entrega o item fabricado
    if category == "weapon" then
        -- Se for arma, adiciona com os dados da arma
        Player.Functions.AddItem(recipe.item, amount)
        TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[recipe.item], 'add')
    else
        -- Se for item comum
        Player.Functions.AddItem(recipe.item, amount)
        TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[recipe.item], 'add')
    end

    -- Opcional: Adiciona experiência/ganho de nível de crafting
    local currentExp = Player.Functions.GetMetaData("crafting_xp") or 0
    local currentLevel = Player.Functions.GetMetaData("crafting_level") or 1
    local expGained = 15 -- XP fixa por craft

    currentExp = currentExp + expGained
    local nextLevelExp = currentLevel * 100 -- Exemplo de curva de nível simples

    if currentExp >= nextLevelExp then
        currentLevel = currentLevel + 1
        currentExp = currentExp - nextLevelExp
        Player.Functions.SetMetaData("crafting_level", currentLevel)
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Subiu de Nível!',
            description = 'Seu nível de sobrevivência/crafting subiu para ' .. currentLevel .. '!',
            type = 'success',
            duration = 8000
        })
    end
    Player.Functions.SetMetaData("crafting_xp", currentExp)

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Sucesso',
        description = 'Você fabricou ' .. recipe.label .. ' x' .. amount,
        type = 'success'
    })
end)

-- Usar o item "survival_book" para abrir o menu do livro (se configurado como item usável)
RSGCore.Functions.CreateUseableItem("survival_book", function(source, item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if Player then
        local craftLevel = Player.Functions.GetMetaData("crafting_level") or 1
        TriggerClientEvent('vln-survivalbook:openBook', src, craftLevel)
    end
end)
