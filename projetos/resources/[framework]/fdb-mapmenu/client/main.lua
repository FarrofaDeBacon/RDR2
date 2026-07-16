local RSGCore = exports['rsg-core']:GetCoreObject()

-- Configurações de Animação e Props
local MAP_PROP_MODEL = `p_treasuremap01x`
local ANIM_DICT_UNFOLD = "mech_inspection@generic@map@unfold"
local ANIM_DICT_BASE = "mech_inspection@generic@map@base"
local ANIM_DICT_FOLD = "mech_inspection@generic@map@fold"
local MAP_BONE = 57005 -- SKEL_R_Hand

-- Helper para carregar AnimDicts
local function LoadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end
    print("[fdb-mapmenu] AnimDict carregado:", dict, "Status:", HasAnimDictLoaded(dict))
    return HasAnimDictLoaded(dict)
end

-- Helper para carregar Modelos
local function LoadModel(model)
    if HasModelLoaded(model) then return true end
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end
    print("[fdb-mapmenu] Model carregado:", model, "Status:", HasModelLoaded(model))
    return HasModelLoaded(model)
end

-- Abre o mapa com animação em três partes
local function OpenNativeMapWithAnimation()
    print("[fdb-mapmenu] Iniciando OpenNativeMapWithAnimation...")
    local ped = PlayerPedId()
    
    -- Tenta carregar o modelo. Se falhar, usa outro
    if not LoadModel(MAP_PROP_MODEL) then
        MAP_PROP_MODEL = `p_map01x`
        LoadModel(MAP_PROP_MODEL)
    end
    
    -- Tenta carregar os dicionários, se falhar tenta o dicionário base unificado
    local useUnifiedDict = false
    if not LoadAnimDict(ANIM_DICT_UNFOLD) then
        print("[fdb-mapmenu] Falha ao carregar @unfold, tentando dicionario unificado mech_inspection@generic@map")
        useUnifiedDict = true
        ANIM_DICT_UNFOLD = "mech_inspection@generic@map"
        ANIM_DICT_BASE = "mech_inspection@generic@map"
        ANIM_DICT_FOLD = "mech_inspection@generic@map"
        LoadAnimDict(ANIM_DICT_UNFOLD)
    else
        LoadAnimDict(ANIM_DICT_BASE)
    end

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
    Citizen.InvokeNative(0xEF01D36B9C9D0C7B, GetHashKey("FE_MENU_VERSION_MP_PAUSE"), false, -1)

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

-- [MANTÉM AS FUNÇÕES DE ANIMAÇÃO INTACTAS AQUI EM CIMA]
-- (A animação de OpenNativeMapWithAnimation continua igual)

-- =======================================================
-- SISTEMA DE MARCAÇÕES E BLIPS
-- =======================================================

local activeBlips = {} -- Guarda os blips criados { [id] = blipHandle }

local function RemoveAllBlips()
    for _, blip in pairs(activeBlips) do
        RemoveBlip(blip)
    end
    activeBlips = {}
end

local function LoadPlayerMarkers()
    RemoveAllBlips()
    local markers = lib.callback.await('fdb-mapmenu:server:getMarkers', false)
    
    if markers then
        for _, marker in pairs(markers) do
            -- Cria o blip nativo do RDR2
            local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, marker.x, marker.y, marker.z)
            
            -- Se tiver ícone específico, a gente aplica
            if marker.icon and marker.icon ~= "" then
                SetBlipSprite(blip, GetHashKey(marker.icon), true)
            end
            
            SetBlipScale(blip, 0.2)
            Citizen.InvokeNative(0x9CB1A1623062F402, blip, marker.name) -- Seta o nome
            
            activeBlips[marker.id] = blip
        end
    end
end

-- Evento para atualizar os blips quando algo é adicionado/removido
RegisterNetEvent('fdb-mapmenu:client:refreshMarkers', function()
    LoadPlayerMarkers()
end)

-- =======================================================
-- MENUS UI (ox_lib)
-- =======================================================

-- Menu Principal do Mapa
local function OpenMapMenu()
    lib.registerContext({
        id = 'map_main_menu',
        title = 'Mapa e Anotações',
        options = {
            {
                title = 'Abrir Mapa',
                description = 'Desdobrar e olhar o mapa nativo',
                icon = 'map',
                onSelect = function()
                    OpenNativeMapWithAnimation()
                end,
            },
            {
                title = 'Nova Anotação',
                description = 'Marcar sua localização atual no mapa',
                icon = 'pencil',
                onSelect = function()
                    -- Verifica se tem o lápis
                    local hasPencil = lib.callback.await('fdb-mapmenu:server:hasPencilItem', false)
                    if not hasPencil then
                        lib.notify({ title = 'Você não tem um lápis para anotar!', type = 'error' })
                        return
                    end
                    
                    -- Abre formulário de anotação
                    local input = lib.inputDialog('Nova Anotação', {
                        {type = 'input', label = 'Nome do Local', description = 'Ex: Ponto de Caça, Esconderijo', required = true},
                        {type = 'select', label = 'Ícone', required = true, options = {
                            {value = 'blip_ambient_camp', label = 'Acampamento'},
                            {value = 'blip_animal_deer', label = 'Caça'},
                            {value = 'blip_shop_grocery', label = 'Provisões'},
                            {value = 'blip_shop_gunsmith', label = 'Armas/Perigo'},
                            {value = 'blip_defend_coach', label = 'Alvo/Destino'}
                        }}
                    })
                    
                    if not input then return end
                    
                    local name = input[1]
                    local icon = input[2]
                    local coords = GetEntityCoords(PlayerPedId())
                    
                    TriggerServerEvent('fdb-mapmenu:server:addMarker', name, icon, coords)
                end,
            },
            {
                title = 'Minhas Anotações',
                description = 'Gerenciar as anotações feitas',
                icon = 'list',
                onSelect = function()
                    local markers = lib.callback.await('fdb-mapmenu:server:getMarkers', false)
                    local menuOptions = {}
                    
                    if markers and #markers > 0 then
                        for _, marker in pairs(markers) do
                            table.insert(menuOptions, {
                                title = marker.name,
                                description = 'Clique para deletar esta marcação.',
                                icon = 'map-pin',
                                onSelect = function()
                                    local confirm = lib.alertDialog({
                                        header = 'Deletar Marcação?',
                                        content = 'Tem certeza que deseja rasgar esta anotação do seu mapa?',
                                        centered = true,
                                        cancel = true
                                    })
                                    if confirm == 'confirm' then
                                        TriggerServerEvent('fdb-mapmenu:server:removeMarker', marker.id)
                                    else
                                        lib.showContext('map_markers_list')
                                    end
                                end
                            })
                        end
                    else
                        table.insert(menuOptions, {
                            title = 'Nenhuma anotação feita',
                            disabled = true
                        })
                    end
                    
                    lib.registerContext({
                        id = 'map_markers_list',
                        title = 'Minhas Anotações',
                        menu = 'map_main_menu',
                        options = menuOptions
                    })
                    
                    lib.showContext('map_markers_list')
                end,
            }
        }
    })
    
    lib.showContext('map_main_menu')
end

-- =======================================================
-- INICIALIZAÇÃO E COMANDOS
-- =======================================================

-- Permite abrir através de um item do servidor ou export (ex: se o server usar o item 'map')
RegisterNetEvent('fdb-mapmenu:client:OpenMapMenu', function()
    OpenMapMenu()
end)

-- Thread de Interceptação da Tecla M (INPUT_MAP)
CreateThread(function()
    -- Carrega os marcadores ao entrar no jogo
    Wait(2000)
    LoadPlayerMarkers()
    
    while true do
        Wait(0)
        DisableControlAction(0, 0xE31C6A41, true) -- INPUT_MAP (M)

        if IsDisabledControlJustReleased(0, 0xE31C6A41) then
            local hasMap = lib.callback.await('fdb-mapmenu:server:hasMapItem', false)
            if hasMap then
                OpenMapMenu()
            else
                lib.notify({ title = 'Você não possui um mapa equipado.', type = 'error' })
            end
        end
    end
end)


