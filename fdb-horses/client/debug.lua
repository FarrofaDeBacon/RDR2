-- ============================================================
-- FASE D — Handler client de teste isolado de natives
-- ============================================================

RegisterNetEvent('fdb-horses:client:debug:TestAgitation', function(action)
    local horsePed = GetActiveHorsePed()

    if not horsePed or horsePed == 0 or not DoesEntityExist(horsePed) then
        lib.notify({ title = '[Fase D] Nenhum cavalo ativo no client.', type = 'error', duration = 5000 })
        return
    end

    if not IsPedOnMount(cache.ped) then
        lib.notify({ title = '[Fase D] Jogador não está montado.', description = 'Monte no cavalo antes de testar.', type = 'error', duration = 5000 })
        return
    end

    -- --------------------------------------------------------
    -- MÉTODOS DE TESTE PARA EMPINAR (REAR)
    -- --------------------------------------------------------

    if action == 'rear' or action == 'rear1' then
        -- Método 1: TASK_HORSE_ACTION (Action 1 / 7 = REAR)
        lib.notify({ title = '[Fase D] Testando rear1: TaskHorseAction', type = 'inform', duration = 4000 })
        Citizen.InvokeNative(0xAE2BBE83822640B6, horsePed, 1, 0, 0) -- TASK_HORSE_ACTION rear
        Wait(2500)
        lib.notify({ title = '[Fase D] rear1 concluído. Empinou?', type = 'success', duration = 5000 })

    elseif action == 'rear2' then
        -- Método 2: TaskPlayAnim direta no cavalo
        lib.notify({ title = '[Fase D] Testando rear2: TaskPlayAnim', type = 'inform', duration = 4000 })
        local dict = "amb_creature_mammal@horse@agitated@base"
        local anim = "rearing_b"
        lib.requestAnimDict(dict, 5000)
        TaskPlayAnim(horsePed, dict, anim, 8.0, -8.0, 3000, 31, 0, false, false, false)
        Wait(3000)
        RemoveAnimDict(dict)
        lib.notify({ title = '[Fase D] rear2 concluído. Empinou?', type = 'success', duration = 5000 })

    elseif action == 'rear3' then
        -- Método 3: TaskSmartFleePed / Agitação Nativa
        lib.notify({ title = '[Fase D] Testando rear3: TaskAgitated', type = 'inform', duration = 4000 })
        Citizen.InvokeNative(0x028F76B6E78246E9, horsePed, cache.ped, 1, 1)
        Wait(2000)
        lib.notify({ title = '[Fase D] rear3 concluído.', type = 'success', duration = 5000 })

    -- --------------------------------------------------------
    -- TESTE DE EJECT (DERRUBAR JOGADOR)
    -- --------------------------------------------------------
    elseif action == 'eject' then
        lib.notify({ title = '[Fase D] Testando: eject (Derrubar jogador)', type = 'inform', duration = 4000 })
        -- Eject / Ragdoll no player ped enquanto montado
        SetPedToRagdoll(cache.ped, 3000, 3000, 0, true, true, false)
        Wait(2000)
        if not IsPedOnMount(cache.ped) then
            lib.notify({ title = '[Fase D] eject: OK — jogador ejetado com sucesso!', type = 'success', duration = 5000 })
        else
            lib.notify({ title = '[Fase D] eject: falhou.', type = 'error', duration = 5000 })
        end
    end
end)
