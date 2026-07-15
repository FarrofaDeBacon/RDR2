local RSGCore = exports['rsg-core']:GetCoreObject()
local mapProp = nil

-- Configurações de Animação e Props
local MAP_PROP_MODEL = `p_map01x`
local MAP_ANIM_DICT = "script_re@player_item@tablet@land_use"
local MAP_ANIM_OPEN = "player_read"
local MAP_BONE = 57005 -- SKEL_R_Hand

-- Helper para carregar AnimDicts
local function LoadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return end
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 500 do
        Wait(10)
        timeout = timeout + 1
    end
end

-- Helper para carregar Modelos
local function LoadModel(model)
    if HasModelLoaded(model) then return end
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 500 do
        Wait(10)
        timeout = timeout + 1
    end
end

-- Spawna o prop do mapa e prende na mão do jogador
local function AttachMapProp(ped)
    if mapProp and DoesEntityExist(mapProp) then return end

    LoadModel(MAP_PROP_MODEL)

    local coords = GetEntityCoords(ped)
    mapProp = CreateObject(MAP_PROP_MODEL, coords.x, coords.y, coords.z, true, true, true)

    local boneIndex = GetPedBoneIndex(ped, MAP_BONE)
    AttachEntityToEntity(
        mapProp,    -- prop
        ped,        -- ped
        boneIndex,  -- bone
        0.1, 0.0, 0.05,  -- offsets de posição (ajustado para p_map01x na mão)
        -10.0, 10.0, 5.0, -- offsets de rotação (ajustado para alinhar com a mão)
        true, true, false, true, 1, true
    )
end

-- Remove o prop do mapa da mão
local function DetachMapProp()
    if mapProp and DoesEntityExist(mapProp) then
        DetachEntity(mapProp, true, true)
        DeleteObject(mapProp)
        SetObjectAsNoLongerNeeded(mapProp)
    end
    mapProp = nil
end

-- Abre o mapa com animação física do personagem segurando o papel
local function OpenNativeMapWithAnimation()
    local ped = PlayerPedId()
    
    -- 1. Carrega animação e prop
    LoadAnimDict(MAP_ANIM_DICT)

    -- 2. Toca a animação de abrir o mapa
    TaskPlayAnim(ped, MAP_ANIM_DICT, MAP_ANIM_OPEN, 8.0, -8.0, -1, 49, 0, false, false, false)

    -- 3. Prende o prop do mapa na mão (p_map01x)
    AttachMapProp(ped)

    -- 4. Espera a animação rodar um pouco antes de abrir o menu de pausa nativo
    Wait(1200)

    -- 5. Abre o mapa nativo do jogo via hash nativo (ACTIVATE_FRONTEND_MENU = 0xEF01D36B9C9D0C7B)
    local menuHash = GetHashKey("FE_MENU_VERSION_MP_PAUSE")
    Citizen.InvokeNative(0xEF01D36B9C9D0C7B, menuHash, false, -1)

    -- 6. Monitora o fechamento do mapa nativo em segundo plano (IS_PAUSE_MENU_ACTIVE = 0xA7E95B60ED29B88D)
    CreateThread(function()
        -- Aguarda o menu de pausa registrar como ativo
        Wait(500)
        while Citizen.InvokeNative(0xA7E95B60ED29B88D) do
            Wait(100)
        end
        -- Quando fechar o menu de pausa/mapa:
        ClearPedTasks(ped)
        DetachMapProp()
    end)
end

-- -------------------------------------------------------
-- Thread de Interceptação da Tecla M (INPUT_MAP)
-- -------------------------------------------------------
CreateThread(function()
    while true do
        Wait(0)
        DisableControlAction(0, 0xE31C6A41, true) -- INPUT_MAP (M)

        if IsDisabledControlJustReleased(0, 0xE31C6A41) then
            -- Verifica posse do mapa no servidor
            local hasMap = lib.callback.await('fdb-mapmenu:server:hasMapItem', false)
            if hasMap then
                OpenNativeMapWithAnimation()
            else
                lib.notify({ title = 'Você precisa equipar um mapa para ver isso', type = 'error' })
            end
        end
    end
end)

-- Comando de Teste de Modelos de Prop de Mapa no F8
RegisterCommand("testmapprops", function()
    local testModels = {
        "p_treasuremap01x",
        "p_treasuremap_01x",
        "p_map01x",
        "p_map_01x",
        "p_letter01x",
        "p_letter_01x",
        "p_newspaper01x",
        "p_cs_newspaper01x",
        "p_paper01x"
    }

    print("--- INICIANDO TESTE DE MODELOS ---")
    for _, modelName in ipairs(testModels) do
        local hash = GetHashKey(modelName)
        RequestModel(hash)
        local timer = 0
        while not HasModelLoaded(hash) and timer < 100 do
            Wait(10)
            timer = timer + 1
        end
        if HasModelLoaded(hash) then
            print("SUCESSO: Modelo " .. modelName .. " carregou perfeitamente!")
            SetModelAsNoLongerNeeded(hash)
        else
            print("FALHA: Modelo " .. modelName .. " nao existe ou nao carregou.")
        end
    end
    print("--- FIM DO TESTE ---")
end, false)

-- Comando de Teste de AnimDicts no F8
RegisterCommand("testmapanims", function()
    local testDicts = {
        "script_re@player_item@tablet@land_use",
        "script_re@player_item@tablet@land_use_map",
        "script_re@player_item@tablet@map",
        "amb_rest@world_human_read_map@male_a@idle_a",
        "amb_work@world_human_read_map@male_a@idle_a",
        "mech_inventory@map",
        "mech_inventory@treasure_map",
        "script_re@treasure_map",
        "script_common@item_inspect@paper_map",
        "script_common@item_inspect@paper_map@base",
        "script_story@player_item",
        "script_re@player_item",
        "script_re@player_item@gold_map"
    }

    print("--- INICIANDO TESTE DE ANIMACOES ---")
    for _, dictName in ipairs(testDicts) do
        RequestAnimDict(dictName)
        local timer = 0
        while not HasAnimDictLoaded(dictName) and timer < 100 do
            Wait(10)
            timer = timer + 1
        end
        if HasAnimDictLoaded(dictName) then
            print("SUCESSO: AnimDict " .. dictName .. " carregou perfeitamente!")
            RemoveAnimDict(dictName)
        else
            print("FALHA: AnimDict " .. dictName .. " nao existe ou nao carregou.")
        end
    end
    print("--- FIM DO TESTE DE ANIMACOES ---")
end, false)

-- Comando de Teste Visual de Scenarios no F8/Chat
RegisterCommand("testscenario", function(source, args)
    local scenarioName = args[1]
    if not scenarioName then
        print("Uso: /testscenario [NOME_DO_SCENARIO]")
        return
    end

    local ped = PlayerPedId()
    ClearPedTasksImmediately(ped)
    Wait(500)

    print("Tentando rodar o scenario: " .. scenarioName)
    local hash = GetHashKey(scenarioName)
    
    -- TaskStartScenarioInPlace(ped, scenarioHash, unkDelay, playEnterAnim, unk, unk, unk)
    Citizen.InvokeNative(0x524B5436C2243679, ped, hash, 0, true, false, false, false)
    
    lib.notify({
        title = 'Iniciando Scenario',
        description = 'Iniciando: ' .. scenarioName,
        type = 'info'
    })
end, false)



