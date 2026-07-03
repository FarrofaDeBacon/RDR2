local RSGCore = exports['rsg-core']:GetCoreObject()
registeredEntities = {}

--- Configura as interações de mira para uma mochila física no chão
--- @param entity number
--- @param stashId string
--- @param itemName string
function SetupTarget(entity, stashId, itemName)
    print(("[Backpack Debug] SetupTarget called. Entity: %s, StashId: %s, ItemName: %s"):format(entity, stashId, itemName))
    if registeredEntities[stashId] then
        print("[Backpack Debug] StashId already registered in target list. Skipping.")
        return
    end
    registeredEntities[stashId] = true
    print("[Backpack Debug] Registering ox_target options for Entity.")

    exports.ox_target:addLocalEntity(entity, {
        {
            name     = 'open_backpack_' .. stashId,
            icon     = 'fas fa-basket-shopping',
            label    = 'Vasculhar Mochila',
            distance = 2.0,
            onSelect = function()
                -- Solicita abertura e lock ao servidor
                lib.callback('rsg-backpacks:server:requestOpenStash', false, function(success, message)
                    if success then
                        local model = 'p_ambpack02x'
                        local bpConfig = Config.Backpacks[itemName]
                        if bpConfig then model = bpConfig.model end
                        -- Abre a aba deslizante do inventário (drawer)
                        TriggerEvent("rsg-inventory:client:openBackpackDrawer", stashId, model)
                    else
                        lib.notify({
                            title = 'Mochila',
                            description = message or 'Não foi possível vasculhar a mochila.',
                            type = 'error',
                            duration = 5000
                        })
                    end
                end, stashId)
            end,
        },
        {
            name     = 'wear_backpack_' .. stashId,
            icon     = 'fas fa-shirt',
            label    = 'Vestir Mochila',
            distance = 2.0,
            canInteract = function(entity, distance, data)
                local uid = stashId:sub(1, 3) == "bp_" and stashId:sub(4) or stashId
                local bp = groundBackpacks[uid]
                return bp and bp.state ~= 'open'
            end,
            onSelect = function()
                TriggerServerEvent("rsg-backpacks:server:wearBackpack", stashId)
            end,
        },
        {
            name     = 'pickup_backpack_' .. stashId,
            icon     = 'fas fa-hand-holding',
            label    = 'Recolher Mochila',
            distance = 2.0,
            canInteract = function(entity, distance, data)
                local uid = stashId:sub(1, 3) == "bp_" and stashId:sub(4) or stashId
                local bp = groundBackpacks[uid]
                return bp and bp.state ~= 'open'
            end,
            onSelect = function()
                TriggerServerEvent("rsg-backpacks:server:pickupBackpack", stashId)
            end,
        }
    })
end
