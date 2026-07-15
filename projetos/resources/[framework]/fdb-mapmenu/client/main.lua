local RSGCore = exports['rsg-core']:GetCoreObject()
local isMapOpen = false
local mapProp = nil

-- -------------------------------------------------------
-- Prop e Animação do Mapa
-- -------------------------------------------------------
local MAP_PROP_MODEL = `p_treasuremap01x`
local MAP_ANIM_DICT = "script@mech@treasure_map"
local MAP_ANIM_OPEN = "open"
local MAP_BONE = 57005 -- SKEL_R_Hand

-- Carrega um AnimDict e espera até estar pronto
local function LoadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return end
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 500 do
        Wait(10)
        timeout = timeout + 1
    end
end

-- Carrega um modelo e espera até estar pronto
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

-- -------------------------------------------------------
-- Abrir / Fechar o Mapa
-- -------------------------------------------------------
local function SetMapActive(active, playerMarkers)
    local ped = PlayerPedId()

    if active then
        isMapOpen = true

        -- 1. Carrega animação e prop
        LoadAnimDict(MAP_ANIM_DICT)

        -- 2. Toca a animação de abrir o mapa
        TaskPlayAnim(ped, MAP_ANIM_DICT, MAP_ANIM_OPEN, 8.0, -8.0, -1, 49, 0, false, false, false)

        -- 3. Prende o prop do mapa na mão
        AttachMapProp(ped)

        -- 4. Espera a animação começar e estabilizar antes de mostrar a NUI
        Wait(1200)

        -- 5. Agora sim, ativa o NUI por cima
        SetNuiFocus(true, true)

        local coords = GetEntityCoords(ped)
        SendNUIMessage({
            action = "openMap",
            coords = { x = coords.x, y = coords.y },
            markers = playerMarkers or {}
        })
    else
        -- 1. Fecha o NUI imediatamente
        SendNUIMessage({
            action = "closeMap"
        })
        SetNuiFocus(false, false)

        -- 2. Para a animação e remove o prop
        ClearPedTasks(ped)
        DetachMapProp()

        isMapOpen = false
    end
end

-- -------------------------------------------------------
-- Eventos do Cliente
-- -------------------------------------------------------
RegisterNetEvent('fdb-mapmenu:client:openMap', function()
    if not isMapOpen then
        local playerMarkers = lib.callback.await('fdb-mapmenu:server:getMarkers', false)
        SetMapActive(true, playerMarkers)
    end
end)

-- -------------------------------------------------------
-- Callbacks NUI
-- -------------------------------------------------------
RegisterNUICallback('closeMap', function(_, cb)
    SetMapActive(false)
    cb('ok')
end)

RegisterNUICallback('addMarker', function(data, cb)
    TriggerServerEvent('fdb-mapmenu:server:addMarker', data.x, data.y, data.label)
    cb('ok')
end)

RegisterNUICallback('removeMarker', function(data, cb)
    TriggerServerEvent('fdb-mapmenu:server:removeMarker', data.index)
    cb('ok')
end)

-- -------------------------------------------------------
-- Thread de Interceptação da Tecla M (INPUT_MAP)
-- -------------------------------------------------------
CreateThread(function()
    while true do
        Wait(0)
        DisableControlAction(0, 0xE31C6A41, true) -- INPUT_MAP (M)

        if IsDisabledControlJustReleased(0, 0xE31C6A41) then
            if not isMapOpen then
                -- Verifica posse do mapa no servidor
                local hasMap = lib.callback.await('fdb-mapmenu:server:hasMapItem', false)
                if hasMap then
                    local playerMarkers = lib.callback.await('fdb-mapmenu:server:getMarkers', false)
                    SetMapActive(true, playerMarkers)
                else
                    lib.notify({ title = 'Você precisa equipar um mapa para ver isso', type = 'error' })
                end
            end
        end

        if isMapOpen then
            DisableControlAction(0, 0x3C0A40F2, true) -- ESC pra fechar

            -- Desativa o controle de rotação de câmera do mouse do jogo para evitar roubo de foco do drag no NUI
            DisableControlAction(0, 0x3900BA13, true) -- INPUT_LOOK_LR (Olhar Lados)
            DisableControlAction(0, 0x0877C683, true) -- INPUT_LOOK_UD (Olhar Cima/Baixo)

            -- Desativa o scroll de trocar de arma do jogo para liberar o wheel zoom no CEF
            DisableControlAction(0, 0xCC14EB5C, true) -- INPUT_WEAPON_WHEEL_NEXT
            DisableControlAction(0, 0x307E4424, true) -- INPUT_WEAPON_WHEEL_PREV

            if IsDisabledControlJustReleased(0, 0x3C0A40F2) then
                SetMapActive(false)
            end
        end
    end
end)
