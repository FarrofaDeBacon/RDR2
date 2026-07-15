local RSGCore = exports['rsg-core']:GetCoreObject()
local Selected = true
local playerdatalevel = 1
local targetShop = nil
local playerjob = nil
local playerrank = nil
local playergroup = nil
local Oncrafting = false
local producing = false

local prompts = GetRandomIntInRange(0, 0xffffff)
local openMailbox = nil

Citizen.CreateThread(function()
    Citizen.Wait(2000)
    local str = Config.SubPrompt
    openMailbox = PromptRegisterBegin()
    PromptSetControlAction(openMailbox, Config.PromptKey)
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(openMailbox, str)
    PromptSetEnabled(openMailbox, 1)
    PromptSetVisible(openMailbox, 1)
    PromptSetStandardMode(openMailbox, 1)
    PromptSetHoldMode(openMailbox, 1)
    PromptSetGroup(openMailbox, prompts)
    Citizen.InvokeNative(0xC5F428EE08FA7F2C, openMailbox, true)
    PromptRegisterEnd(openMailbox)
end)

-- Evento disparado quando o personagem do RSG é carregado
RegisterNetEvent("RSGCore:Client:OnPlayerLoaded", function()
    Selected = true
    Citizen.Wait(1000)
    TriggerServerEvent('vln-survivalbook:getjob')
end)

-- Evento de sincronização de informações do personagem
RegisterNetEvent("vln-survivalbook:findjob", function(job, rank, group, level)
    playerjob = job
    playerrank = rank
    playergroup = group
    playerdatalevel = level
end)

-- Thread periódica para atualizar dados do jogador
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.JobCooldown)
        if Selected then
            TriggerServerEvent("vln-survivalbook:getjob")
        end
    end
end)

local function IsStoreClosed(storeConfig)
    local hour = GetClockHours()
    if hour >= storeConfig.StoreClose or hour < storeConfig.StoreOpen then
       return "closed"
    elseif hour >= storeConfig.StoreOpen then
       return "opened"
    end
    return "none"
end

function jobcheck(tbl, element)
    for k, v in pairs(tbl) do
        if v == element then
            return true
        end
    end
    return false
end

-- Thread de proximidade com as mesas de craft
Citizen.CreateThread(function()
    while true do
        local find = false
        local sleep = 1000
        local pedCoords = GetEntityCoords(PlayerPedId())
        
        for k, v in pairs(Config.CraftLocations) do
            local shopCoord = v.coords 
            if #(shopCoord - pedCoords) < Config.Distance then
                targetShop = k
                find = true
                sleep = 0
                break
            end
        end
        if not find then
            targetShop = nil
        end
        Citizen.Wait(sleep)
    end
end)

-- Abre o menu do Livro de Sobrevivência (receitas portáteis)
function OpenMenu(playerLevel)
    if producing then return end
    Oncrafting = true
    
    local options = {}

    for recipeName, recipe in pairs(Config.Recipees) do
        local locked = playerLevel < recipe.requiredlevel
        local descriptionText = locked and "🔒 Nível Necessário: " .. recipe.requiredlevel or "Tempo: " .. recipe.time .. "s | Clique para ver ingredientes"

        table.insert(options, {
            title = recipe.label,
            description = descriptionText,
            disabled = locked,
            icon = Config.ImageLocation .. recipe.image .. ".png",
            arrow = not locked,
            onSelect = function()
                OpenRecipeSubMenu(recipeName, recipe, playerLevel)
            end
        })
    end

    lib.registerContext({
        id = 'survival_book_main',
        title = 'Livro de Sobrevivência',
        options = options,
        onExit = function()
            Oncrafting = false
        end
    })

    lib.showContext('survival_book_main')
end

-- Abre o submenu da receita portátil
function OpenRecipeSubMenu(recipeName, recipe, playerLevel)
    local options = {}

    -- Lista os ingredientes necessários
    for _, ingredient in ipairs(recipe.items) do
        table.insert(options, {
            title = ingredient.name,
            description = "Necessário: x" .. ingredient.amount,
            icon = Config.ImageLocation .. ingredient.name .. ".png",
            disabled = true -- Apenas listagem visual
        })
    end

    -- Botão para fabricar
    table.insert(options, {
        title = "Fabricar: " .. recipe.label,
        description = "Clique para iniciar a fabricação",
        icon = "fa-solid fa-hammer",
        onSelect = function()
            lib.callback('vln-survivalbook:getRequirements', false, function(hasAllItems, missingItems)
                if hasAllItems then
                    -- Toca barra de progresso do ox_lib
                    producing = true
                    Oncrafting = false
                    
                    if lib.progressBar({
                        duration = recipe.time * 1000,
                        label = 'Fabricando ' .. recipe.label .. '...',
                        useWhileDead = false,
                        canCancel = true,
                        anim = {
                            dict = 'amb_work@world_human_farmer_weeding@male_a@idle_a',
                            name = 'idle_b'
                        },
                        disable = {
                            move = true,
                            car = true,
                            combat = true
                        }
                    }) then
                        TriggerServerEvent('vln-survivalbook:giveItem', recipeName, recipe.amount, recipe.catagory)
                    else
                        lib.notify({ title = 'Cancelado', description = 'Fabricação cancelada!', type = 'error' })
                    end
                    producing = false
                else
                    for _, missingItem in ipairs(missingItems) do
                        lib.notify({
                            title = 'Ingredientes Ausentes',
                            description = 'Falta ' .. missingItem.missingCount .. 'x ' .. missingItem.itemName,
                            type = 'error'
                        })
                    end
                    OpenRecipeSubMenu(recipeName, recipe, playerLevel)
                end
            end, recipeName, 1)
        end
    })

    -- Botão Voltar
    table.insert(options, {
        title = "Voltar",
        icon = "fa-solid fa-arrow-left",
        onSelect = function()
            OpenMenu(playerLevel)
        end
    })

    lib.registerContext({
        id = 'survival_book_recipe',
        title = recipe.label .. " (Ingredientes)",
        menu = 'survival_book_main',
        options = options,
        onExit = function()
            Oncrafting = false
        end
    })

    lib.showContext('survival_book_recipe')
end

-- Abre o menu de craft no Workshop/NPC
function OpenCraftMenu(shopId)
    if producing then return end
    Oncrafting = true
    
    local shopData = Config.CraftLocations[shopId]
    if not shopData then return end

    local options = {}

    for recipeName, recipe in pairs(shopData.Craftables or {}) do
        local locked = playerdatalevel < recipe.requiredlevel
        local descriptionText = locked and "🔒 Nível Necessário: " .. recipe.requiredlevel or "Tempo: " .. recipe.time .. "s | Clique para ver ingredientes"

        table.insert(options, {
            title = recipe.label,
            description = descriptionText,
            disabled = locked,
            icon = Config.ImageLocation .. (recipe.image or "default") .. ".png",
            arrow = not locked,
            onSelect = function()
                OpenCraftSubMenu(recipeName, recipe, playerdatalevel, shopId)
            end
        })
    end

    lib.registerContext({
        id = 'survival_shop_main',
        title = shopData.title or "Mesa de Trabalho",
        options = options,
        onExit = function()
            Oncrafting = false
        end
    })

    lib.showContext('survival_shop_main')
end

-- Abre o submenu de ingredientes da mesa de trabalho
function OpenCraftSubMenu(recipeName, recipe, playerLevel, shopId)
    local options = {}

    for _, ingredient in ipairs(recipe.items) do
        table.insert(options, {
            title = ingredient.name,
            description = "Necessário: x" .. ingredient.amount,
            icon = Config.ImageLocation .. ingredient.name .. ".png",
            disabled = true
        })
    end

    -- Botão para fabricar
    table.insert(options, {
        title = "Fabricar: " .. recipe.label,
        description = "Clique para iniciar a fabricação",
        icon = "fa-solid fa-hammer",
        onSelect = function()
            lib.callback('vln-survivalbook:getRequirementsWeapon', false, function(hasAllItems, missingItems)
                if hasAllItems then
                    producing = true
                    Oncrafting = false
                    
                    if lib.progressBar({
                        duration = recipe.time * 1000,
                        label = 'Fabricando ' .. recipe.label .. '...',
                        useWhileDead = false,
                        canCancel = true,
                        anim = {
                            dict = 'amb_work@world_human_farmer_weeding@male_a@idle_a',
                            name = 'idle_b'
                        },
                        disable = {
                            move = true,
                            car = true,
                            combat = true
                        }
                    }) then
                        TriggerServerEvent('vln-survivalbook:giveItem', recipeName, recipe.amount, recipe.catagory, shopId)
                    else
                        lib.notify({ title = 'Cancelado', description = 'Fabricação cancelada!', type = 'error' })
                    end
                    producing = false
                else
                    for _, missingItem in ipairs(missingItems) do
                        lib.notify({
                            title = 'Ingredientes Ausentes',
                            description = 'Falta ' .. missingItem.missingCount .. 'x ' .. missingItem.itemName,
                            type = 'error'
                        })
                    end
                    OpenCraftSubMenu(recipeName, recipe, playerLevel, shopId)
                end
            end, recipeName, 1, shopId)
        end
    })

    -- Botão Voltar
    table.insert(options, {
        title = "Voltar",
        icon = "fa-solid fa-arrow-left",
        onSelect = function()
            OpenCraftMenu(shopId)
        end
    })

    lib.registerContext({
        id = 'survival_shop_recipe',
        title = recipe.label .. " (Ingredientes)",
        menu = 'survival_shop_main',
        options = options,
        onExit = function()
            Oncrafting = false
        end
    })

    lib.showContext('survival_shop_recipe')
end

-- Thread de controle de prompts para interação no jogo
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0) 
        
        if targetShop and Selected then
            local store = Config.CraftLocations[targetShop]
            local jobSpecific = store.jobonly
            local canAccess = true
            
            if jobSpecific then
                if not (playerjob and jobcheck(store.job, playerjob)) then
                    canAccess = false
                end
            end
            
            if canAccess then
                if store.StoreHoursAllowed and IsStoreClosed(store) == 'closed' then
                    if not Oncrafting then
                        local label = CreateVarString(10, 'LITERAL_STRING', Config.Closed .. store.StoreOpen .. Config.Am .. store.StoreClose .. Config.Pm )
                        PromptSetActiveGroupThisFrame(prompts, label)
                    end
                elseif not Oncrafting and not producing then
                    local label = CreateVarString(10, 'LITERAL_STRING', Config.OpenPrompt)
                    PromptSetActiveGroupThisFrame(prompts, label)
                    
                    if Citizen.InvokeNative(0xC92AC953F0A982AE, openMailbox) then
                        OpenCraftMenu(targetShop)
                    end
                end
            end
        else
            Citizen.Wait(500)
        end
    end
end)

-- Evento para abrir o livro de sobrevivência externamente
RegisterNetEvent("vln-survivalbook:openBook", function(level)
    OpenMenu(level or playerdatalevel)
end)
