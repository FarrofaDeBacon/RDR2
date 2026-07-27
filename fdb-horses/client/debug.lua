-- ============================================================
-- FASE D — Handler client de teste isolado de natives
-- Registrado APENAS neste arquivo. Não interfere com client.lua,
-- survival.lua, nem com o loop de agitação oficial.
-- Este arquivo será REMOVIDO quando a Fase D for integrada.
-- ============================================================

RegisterNetEvent('fdb-horses:client:debug:TestAgitation', function(action)
    local horsePed = GetActiveHorsePed()  -- leitura via função pública de survival.lua

    if not horsePed or horsePed == 0 or not DoesEntityExist(horsePed) then
        lib.notify({ title = '[Fase D] Nenhum cavalo ativo no client.', type = 'error', duration = 5000 })
        return
    end

    if not IsPedOnMount(cache.ped) then
        lib.notify({ title = '[Fase D] Jogador não está montado.', description = 'Monte no cavalo antes de testar.', type = 'error', duration = 5000 })
        return
    end

    -- --------------------------------------------------------
    -- TESTE: rear — cavalo empina
    -- Native candidata: TASK_PLAY_ANIM_ON_MOUNT (hash 0xEB8886E1065654CD)
    -- Parâmetros: ped, animTag, animHash, blend, unk
    -- animTag "ACTION_REAR" é o empinar nativo do jogo
    -- --------------------------------------------------------
    if action == 'rear' then
        lib.notify({
            title = '[Fase D] Testando: rear',
            description = 'Native: 0xEB8886E1065654CD (TASK_PLAY_ANIM_ON_MOUNT)',
            type = 'inform', duration = 4000
        })

        -- Candidata 1: TASK_PLAY_ANIM_ON_MOUNT — animação de empinar
        Citizen.InvokeNative(0xEB8886E1065654CD, horsePed, 10, "ALL", 0)

        Wait(3000)

        -- Verifica se o jogador ainda está montado (se caiu = native causou eject)
        if IsPedOnMount(cache.ped) then
            lib.notify({
                title = '[Fase D] rear: OK — jogador permaneceu montado',
                description = 'Animação de empinar executada sem eject acidental.',
                type = 'success', duration = 6000
            })
        else
            lib.notify({
                title = '[Fase D] rear: ATENÇÃO — jogador foi ejetado pela animação',
                description = 'Ajustar parâmetros antes de integrar no loop.',
                type = 'warning', duration = 6000
            })
        end

    -- --------------------------------------------------------
    -- TESTE: eject — ejecta o jogador do cavalo intencionalmente
    -- Verifica se o jogador recupera controle normalmente (sem ragdoll travado)
    -- --------------------------------------------------------
    elseif action == 'eject' then
        lib.notify({
            title = '[Fase D] Testando: eject',
            description = 'Native: TaskMountAnimal com flag de despawn',
            type = 'inform', duration = 4000
        })

        -- Desmonta de forma forçada (não suave)
        Citizen.InvokeNative(0xA3DB37EDF9A74635, cache.ped, horsePed, 50, 1, true) -- HORSE_FEED tipo eject

        Wait(2000)

        -- Verifica se o player recuperou controle (não está travado em animação)
        if not IsPedOnMount(cache.ped) and not IsPedInAnyVehicle(cache.ped, false) then
            lib.notify({
                title = '[Fase D] eject: OK — jogador desmontado e livre',
                description = 'Controle recuperado normalmente. Sem ragdoll travado.',
                type = 'success', duration = 6000
            })
        else
            lib.notify({
                title = '[Fase D] eject: ATENÇÃO — estado inesperado',
                description = 'Verificar se controle foi recuperado corretamente.',
                type = 'warning', duration = 6000
            })
        end
    end
end)
