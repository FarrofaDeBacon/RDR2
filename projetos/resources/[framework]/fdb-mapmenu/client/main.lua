local RSGCore = exports['rsg-core']:GetCoreObject()

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

-- Abre o mapa com animação física do personagem segurando o papel (Lógica do treasuremaps)
local function OpenNativeMapWithAnimation()
    local ped = PlayerPedId()
    LoadAnimDict(MAP_ANIM_DICT)
    LoadModel(MAP_PROP_MODEL)

    -- Toca animação
    TaskPlayAnim(ped, MAP_ANIM_DICT, MAP_ANIM_OPEN, 8.0, -8.0, -1, 49, 0, false, false, false)

    -- Spawna e anexa o prop na mão
    local coords = GetEntityCoords(ped)
    local prop = CreateObject(MAP_PROP_MODEL, coords.x, coords.y, coords.z, true, true, true)
    local boneIndex = GetPedBoneIndex(ped, MAP_BONE)
    AttachEntityToEntity(prop, ped, boneIndex, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)

    -- Tempo da animação rodar antes de abrir o mapa do pause
    Wait(1500)

    -- Abre o mapa nativo do jogo
    ActivateFrontendMenu(GetHashKey("FE_MENU_VERSION_MP_PAUSE"), false, -1)

    -- Monitora o fechamento do mapa nativo em segundo plano
    CreateThread(function()
        -- Aguarda o menu de pausa registrar como ativo
        Wait(500)
        while Citizen.InvokeNative(0xA7E95B60ED29B88D) do -- IS_PAUSE_MENU_ACTIVE
            Wait(100)
        end
        -- Quando fechar o menu de pausa/mapa:
        ClearPedTasks(ped)
        DetachEntity(prop, true, true)
        DeleteObject(prop)
        SetObjectAsNoLongerNeeded(prop)
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


