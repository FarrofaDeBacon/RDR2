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
            print('[fdb-propeditor] Uso: /propedit <resource> <item> — ex: /propedit fdb-consume cigar')
        else
            TriggerClientEvent('chat:addMessage', source, {
                args = { 'Sistema', '[fdb-propeditor] Uso: /propedit <resource> <item>' }
            })
        end
        return
    end

    -- Valida que o resource alvo existe e está rodando
    if GetResourceState(resource) ~= 'started' then
        local msg = ('[fdb-propeditor] Resource "%s" não encontrado ou não está rodando.'):format(resource)
        if source == 0 then
            print(msg)
        else
            TriggerClientEvent('chat:addMessage', source, { args = { 'Sistema', msg } })
        end
        return
    end

    -- Abre o editor no cliente do staff (lógica de mover entra no item 4.2)
    TriggerClientEvent('fdb-propeditor:client:open', source, resource, item)

end, false)
