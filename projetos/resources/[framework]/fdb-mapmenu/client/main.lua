local RSGCore = exports['rsg-core']:GetCoreObject()

-- Configurações de Animação e Props (Novas)
local MAP_PROP_MODEL = `p_map_treasure_01x`
local ANIM_DICT_UNFOLD = "mech_inspection@generic@map@unfold"
local ANIM_DICT_BASE = "mech_inspection@generic@map@base"
local ANIM_DICT_FOLD = "mech_inspection@generic@map@fold"
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
    print("[fdb-mapmenu] AnimDict carregado:", dict, "Status:", HasAnimDictLoaded(dict))
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
    print("[fdb-mapmenu] Model carregado:", model, "Status:", HasModelLoaded(model))
end

-- Abre o mapa com animação em três partes (Desenrolar -> Ler -> Guardar)
local function OpenNativeMapWithAnimation()
    print("[fdb-mapmenu] Iniciando OpenNativeMapWithAnimation...")
    local ped = PlayerPedId()
    
    LoadModel(MAP_PROP_MODEL)
    LoadAnimDict(ANIM_DICT_UNFOLD)
    LoadAnimDict(ANIM_DICT_BASE)

    -- Spawna e anexa o prop na mão (SKEL_R_Hand)
    local coords = GetEntityCoords(ped)
    local prop = CreateObject(MAP_PROP_MODEL, coords.x, coords.y, coords.z, true, true, true)
    local boneIndex = GetPedBoneIndex(ped, MAP_BONE)
    AttachEntityToEntity(prop, ped, boneIndex, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    print("[fdb-mapmenu] Prop anexado na mão.")

    -- 1. Animação de puxar/desenrolar
    print("[fdb-mapmenu] Tocando animação enter...")
    TaskPlayAnim(ped, ANIM_DICT_UNFOLD, "enter", 8.0, -8.0, -1, 0, 0, false, false, false)
    
    -- Calcula a duração da animação de entrada
    local unfoldDuration = GetAnimDuration(ANIM_DICT_UNFOLD, "enter")
    print("[fdb-mapmenu] unfoldDuration:", unfoldDuration)
    if unfoldDuration > 0.0 then
        Wait(math.floor(unfoldDuration * 1000) - 200)
    else
        Wait(1500)
    end

    -- 2. Animação de segurar/ler (Loop)
    print("[fdb-mapmenu] Tocando animação hold...")
    TaskPlayAnim(ped, ANIM_DICT_BASE, "hold", 8.0, -8.0, -1, 49, 0, false, false, false)

    -- Pequena pausa para a animação estabilizar
    Wait(500)

    -- Abre o mapa nativo do jogo
    print("[fdb-mapmenu] Abrindo mapa nativo...")
    ActivateFrontendMenu(GetHashKey("FE_MENU_VERSION_MP_PAUSE"), false, -1)

    -- Monitora o fechamento do mapa nativo em segundo plano
    CreateThread(function()
        -- Aguarda o menu de pausa registrar como ativo
        Wait(500)
        print("[fdb-mapmenu] Aguardando o jogador fechar o menu de pausa...")
        while Citizen.InvokeNative(0xA7E95B60ED29B88D) do -- IS_PAUSE_MENU_ACTIVE
            Wait(100)
        end
        print("[fdb-mapmenu] Jogador fechou o menu de pausa.")
        
        -- Quando fechar o menu de pausa/mapa:
        -- 3. Carrega e toca a animação de dobrar/guardar o mapa
        LoadAnimDict(ANIM_DICT_FOLD)
        print("[fdb-mapmenu] Tocando animação exit...")
        TaskPlayAnim(ped, ANIM_DICT_FOLD, "exit", 8.0, -8.0, -1, 0, 0, false, false, false)
        
        -- Calcula a duração da animação de saída
        local foldDuration = GetAnimDuration(ANIM_DICT_FOLD, "exit")
        if foldDuration > 0.0 then
            Wait(math.floor(foldDuration * 1000))
        else
            Wait(1500)
        end

        -- Finaliza, limpa o prop e limpa as memórias
        print("[fdb-mapmenu] Limpando tasks e prop...")
        ClearPedTasks(ped)
        DetachEntity(prop, true, true)
        DeleteObject(prop)
        SetObjectAsNoLongerNeeded(prop)
        
        RemoveAnimDict(ANIM_DICT_UNFOLD)
        RemoveAnimDict(ANIM_DICT_BASE)
        RemoveAnimDict(ANIM_DICT_FOLD)
        print("[fdb-mapmenu] Finalizado.")
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
            print("[fdb-mapmenu] Tecla M pressionada. Verificando item de mapa no server...")
            -- Verifica posse do mapa no servidor
            local hasMap = lib.callback.await('fdb-mapmenu:server:hasMapItem', false)
            print("[fdb-mapmenu] Retorno do server hasMapItem:", tostring(hasMap))
            
            if hasMap then
                OpenNativeMapWithAnimation()
            else
                lib.notify({ title = 'Você precisa equipar um mapa para ver isso', type = 'error' })
            end
        end
    end
end)


