local RSGCore = exports['rsg-core']:GetCoreObject()
local mapProp = nil

-- Configurações de Animação e Props
local MAP_PROP_MODEL = `p_treasuremap01x`
local MAP_ANIM_DICT = "script@mech@treasure_map"
local MAP_ANIM_OPEN = "open"
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
        0.0, 0.0, 0.0,   -- offsets de posição (ajustar se necessário)
        0.0, 0.0, 0.0,   -- offsets de rotação (ajustar se necessário)
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

    -- 3. Prende o prop do mapa na mão
    AttachMapProp(ped)

    -- 4. Espera a animação rodar um pouco antes de abrir o menu de pausa nativo
    Wait(1200)

    -- 5. Abre o mapa nativo do jogo
    ActivateFrontendMenu(GetHashKey("FE_MENU_VERSION_MP_PAUSE"), false, -1)

    -- 6. Monitora o fechamento do mapa nativo em segundo plano
    CreateThread(function()
        -- Aguarda o menu de pausa registrar como ativo
        Wait(500)
        while IsPauseMenuActive() do
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
