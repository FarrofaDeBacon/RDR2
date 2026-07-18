-- ============================================================
-- fdb-hud | server/status.lua
-- Gerencia atualizações seguras de metadata (Fome, Sede, Bexiga)
-- ============================================================

local RSGCore = exports['rsg-core']:GetCoreObject()

-- -------------------------------------------------------
-- Atualização de Sede e Bexiga (quando o player bebe algo)
-- -------------------------------------------------------
RegisterNetEvent('fdb-hud:server:UpdateThirstBladder', function(amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Atualiza Thirst
    local newThirst = (Player.PlayerData.metadata['thirst'] or 0) + amount
    if newThirst > 100 then newThirst = 100 end
    Player.Functions.SetMetaData('thirst', newThirst)

    -- Atualiza Bladder (proporção 1:1, configurável se necessário)
    local newBladder = (Player.PlayerData.metadata['bladder'] or 0) + amount
    if newBladder > 100 then newBladder = 100 end
    Player.Functions.SetMetaData('bladder', newBladder)
end)

-- -------------------------------------------------------
-- Atualização de Fome (quando o player come algo)
-- -------------------------------------------------------
RegisterNetEvent('fdb-hud:server:UpdateHunger', function(amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local newHunger = (Player.PlayerData.metadata['hunger'] or 0) + amount
    if newHunger > 100 then newHunger = 100 end
    Player.Functions.SetMetaData('hunger', newHunger)
end)

-- -------------------------------------------------------
-- Alívio de Estresse
-- -------------------------------------------------------
RegisterNetEvent('fdb-hud:server:RelieveStress', function(amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local newStress = (Player.PlayerData.metadata['stress'] or 0) - amount
    if newStress < 0 then newStress = 0 end
    Player.Functions.SetMetaData('stress', newStress)
end)

-- -------------------------------------------------------
-- Comando /mijar (Alivia a bexiga para 0)
-- -------------------------------------------------------
RSGCore.Commands.Add('mijar', 'Aliviar a bexiga', {}, false, function(source, args)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local currentBladder = Player.PlayerData.metadata['bladder'] or 0
    if currentBladder <= 0 then
        TriggerClientEvent('RSGCore:Notify', src, 'Sua bexiga ja esta vazia!', 'error')
        return
    end

    -- Opcional: Aqui poderíamos dar um trigger num evento client para tocar animação
    -- TriggerClientEvent('fdb-hud:client:PlayPeeAnimation', src)

    Player.Functions.SetMetaData('bladder', 0)
    TriggerClientEvent('RSGCore:Notify', src, 'Voce aliviou sua bexiga.', 'success')
end)
