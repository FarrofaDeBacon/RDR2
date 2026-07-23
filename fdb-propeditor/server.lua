-- ============================================================
-- fdb-propeditor | server.lua
-- Controle de acesso ao editor de props (staff only)
-- ============================================================

RegisterCommand('propedit', function(source, args)
    -- source == 0 significa console do servidor (sempre permitido)
    if source ~= 0 and not IsPlayerAceAllowed(source, 'command.propedit') then
        TriggerClientEvent('chat:addMessage', source, {
            args = { 'Sistema', '[fdb-propeditor] Sem permissão para usar este comando.' }
        })
        return
    end

    local resource = args[1]
    local item     = args[2]

    if not resource or not item then
        if source == 0 then
            print('[fdb-propeditor] O console não pode abrir o menu UI. Use: /propedit <resource> <item>')
            return
        end
        -- Abre o menu de seleção no cliente do staff
        TriggerClientEvent('fdb-propeditor:client:openMenu', source)
        return
    end

    -- Valida que o resource alvo existe e está rodando
    if GetResourceState(resource) ~= 'started' then
        local msg = ('[fdb-propeditor] Resource "%s" não encontrado ou não está rodando.'):format(resource)
        if source == 0 then print(msg) else TriggerClientEvent('chat:addMessage', source, { args = { 'Sistema', msg } }) end
        return
    end

    -- Abre o editor diretamente
    TriggerClientEvent('fdb-propeditor:client:open', source, resource, item)

end, false)
