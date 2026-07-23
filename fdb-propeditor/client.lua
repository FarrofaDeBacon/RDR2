-- ============================================================
-- fdb-propeditor | client.lua
-- Motor do editor de prop (FASE 4.2)
-- Recebe resource e item via fdb-propeditor:client:open
-- Chama exports[resource]:GetPropEditData(item) para os dados
-- ============================================================

local isEditing  = false
local currentStage = 1
local propObj    = 0

local e_x, e_y, e_z     = 0.0, 0.0, 0.0
local e_rx, e_ry, e_rz  = 0.0, 0.0, 0.0
local ped = 0
local isSearching = false

-- Stages são fornecidos pelo resource alvo via GetPropEditData;
-- este é o fallback padrão para itens de fumo (pode ser sobrescrito).
local stages = {}
local currentResource = nil
local currentItem     = nil


local function UpdateNUI()
    SendNUIMessage({
        action     = 'update',
        stageName  = stages[currentStage] and stages[currentStage].name or '—',
        stageIdx   = currentStage,
        stageTotal = #stages,
        x = e_x,  y = e_y,  z = e_z,
        rx = e_rx, ry = e_ry, rz = e_rz,
    })
end

local function PlayStageAnim()
    local stageData = stages[currentStage]
    if not stageData then return end
    local dict = stageData.animDict
    local name = stageData.animName

    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        local t = 0
        while not HasAnimDictLoaded(dict) and t < 100 do Wait(10); t = t + 1 end
    end

    ClearPedTasks(ped)
    TaskPlayAnim(ped, dict, name, 1.0, 1.0, -1, 1, 0.0, false, 0, false, '', false)
end

local function UpdatePropAttach()
    local stageData = stages[currentStage]
    if not stageData or not DoesEntityExist(propObj) then return end
    local boneIndex = GetEntityBoneIndexByName(ped, stageData.bone)
    AttachEntityToEntity(propObj, ped, boneIndex, e_x, e_y, e_z, e_rx, e_ry, e_rz, true, true, false, true, 1, true)
end

local function LoadOffsetsFromStageData(itemData)
    local stageData = stages[currentStage]
    if not stageData or not itemData or not itemData.offsets then
        e_x, e_y, e_z, e_rx, e_ry, e_rz = 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
        return
    end

    local off = itemData.offsets[stageData.name]
    if off then
        e_x,  e_y,  e_z  = off.x  or 0.0, off.y  or 0.0, off.z  or 0.0
        e_rx, e_ry, e_rz = off.rx or 0.0, off.ry or 0.0, off.rz or 0.0
    else
        e_x, e_y, e_z, e_rx, e_ry, e_rz = 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
    end

    -- Override de bone por stage (stages de mão usam bone do dedo)
    if itemData.offsets.bone and (currentStage == 2 or currentStage == 4) then
        stages[currentStage].bone = itemData.offsets.bone
    end
end

local function StopEditor()
    isEditing = false
    isSearching = false
    SetNuiFocus(false, false)
    ClearPedTasks(ped)
    if DoesEntityExist(propObj) then
        DeleteObject(propObj)
        propObj = 0
    end
    currentResource = nil
    currentItem     = nil
    stages          = {}
    print('[fdb-propeditor] Editor fechado.')
end

-- -------------------------------------------------------
-- Menu Inicial Automático
-- -------------------------------------------------------
RegisterNetEvent('fdb-propeditor:client:openMenu', function()
    if isEditing then
        print('[fdb-propeditor] Feche o editor atual antes de abrir o menu.')
        return
    end

    local supportedResources = {}
    local num = GetNumResources()
    for i = 0, num - 1 do
        local res = GetResourceByFindIndex(i)
        if GetResourceState(res) == 'started' then
            local meta = GetResourceMetadata(res, 'fdb_propeditor_supported', 0)
            if meta == 'yes' then
                local ok, items = pcall(function() return exports[res]:GetEditableItems() end)
                if ok and type(items) == 'table' and #items > 0 then
                    supportedResources[res] = items
                end
            end
        end
    end

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openMenu',
        resources = supportedResources
    })
end)

-- -------------------------------------------------------
-- Entrada: disparado pelo server ou pelo menu UI
-- -------------------------------------------------------
RegisterNetEvent('fdb-propeditor:client:open', function(resource, item)
    if isEditing then
        print('[fdb-propeditor] Já existe uma sessão de edição ativa. Feche com BACKSPACE antes de abrir outra.')
        return
    end

    -- Busca os dados do item no resource alvo via export
    local ok, itemData = pcall(function()
        return exports[resource]:GetPropEditData(item)
    end)

    if not ok or not itemData then
        print(('[fdb-propeditor] Falha ao obter dados do item "%s" do resource "%s". Verifique se o export GetPropEditData está registrado.'):format(item, resource))
        return
    end

    if not itemData.prop then
        print(('[fdb-propeditor] Item "%s" não possui prop configurado.'):format(item))
        return
    end

    -- Stages fornecidos pelo resource ou fallback padrão de fumo
    stages = itemData.stages or {
        { name = 'mouth_start', animDict = 'amb_rest@world_human_smoking@male_c@idle_a', animName = 'idle_a', bone = 'skel_head' },
        { name = 'hand_enter',  animDict = 'amb_rest@world_human_smoking@male_c@base',   animName = 'base',   bone = 'SKEL_R_Finger13' },
        { name = 'mouth_puff',  animDict = 'amb_rest@world_human_smoking@male_c@idle_a', animName = 'idle_a', bone = 'skel_head' },
        { name = 'hand_idle',   animDict = 'amb_rest@world_human_smoking@male_c@base',   animName = 'base',   bone = 'SKEL_R_Finger13' },
    }

    isEditing       = true
    currentStage    = 1
    currentResource = resource
    currentItem     = item
    ped             = PlayerPedId()

    -- Carrega o prop
    local hash = GetHashKey(itemData.prop)
    if not HasModelLoaded(hash) then
        RequestModel(hash)
        local t = 0
        while not HasModelLoaded(hash) and t < 100 do Wait(10); t = t + 1 end
    end

    if not HasModelLoaded(hash) then
        print(('[fdb-propeditor] Timeout ao carregar modelo "%s". Verifique se o hash é válido.'):format(itemData.prop))
        isEditing = false
        return
    end

    local coords = GetEntityCoords(ped)
    propObj = CreateObject(hash, coords.x, coords.y, coords.z, true, true, false)

    LoadOffsetsFromStageData(itemData)
    PlayStageAnim()
    UpdatePropAttach()

    -- Envia a lista global Objects do data/objects.lua (17k)
    SendNUIMessage({ action = 'initObjects', objects = Objects or {} })

    -- Mostra a NUI
    SendNUIMessage({ action = 'show', resource = resource, item = item })
    UpdateNUI()

    -- -------------------------------------------------------
    -- Loop principal do editor
    -- -------------------------------------------------------
    Citizen.CreateThread(function()
        while isEditing do
            Wait(0)

            -- HUD via NUI (substitui DrawTxt)
            UpdateNUI()

            local speed  = 0.005
            local rspeed = 2.0
            local changed = false

            -- Bloqueia WASD para o jogo enquanto edita
            DisableControlAction(0, 0x8FD015D8, true) -- W
            DisableControlAction(0, 0xD27782E3, true) -- S
            DisableControlAction(0, 0x7065027D, true) -- A
            DisableControlAction(0, 0xB4E465B4, true) -- D

            local shift = IsControlPressed(0, 0x8FFC75D6) -- Shift

            if shift then
                if IsDisabledControlPressed(0, 0x8FD015D8) then e_rx = e_rx + rspeed; changed = true end
                if IsDisabledControlPressed(0, 0xD27782E3) then e_rx = e_rx - rspeed; changed = true end
                if IsDisabledControlPressed(0, 0x7065027D) then e_ry = e_ry + rspeed; changed = true end
                if IsDisabledControlPressed(0, 0xB4E465B4) then e_ry = e_ry - rspeed; changed = true end
                if IsControlPressed(0, 0x4403F97F)         then e_rz = e_rz + rspeed; changed = true end
                if IsControlPressed(0, 0x3C3DD371)         then e_rz = e_rz - rspeed; changed = true end
            else
                if IsDisabledControlPressed(0, 0x8FD015D8) then e_y = e_y + speed; changed = true end
                if IsDisabledControlPressed(0, 0xD27782E3) then e_y = e_y - speed; changed = true end
                if IsDisabledControlPressed(0, 0x7065027D) then e_x = e_x - speed; changed = true end
                if IsDisabledControlPressed(0, 0xB4E465B4) then e_x = e_x + speed; changed = true end
                if IsControlPressed(0, 0x4403F97F)         then e_z = e_z + speed; changed = true end
                if IsControlPressed(0, 0x3C3DD371)         then e_z = e_z - speed; changed = true end
            end

            if changed then
                UpdatePropAttach()
                Wait(50)
            end

            -- Trocar estágio
            if IsControlJustPressed(0, 0xD9D0E1C0) then -- ESPAÇO
                currentStage = currentStage + 1
                if currentStage > #stages then currentStage = 1 end
                LoadOffsetsFromStageData(itemData)
                PlayStageAnim()
                UpdatePropAttach()
                UpdateNUI()
            end

            -- Imprimir offset atual no F8
            if IsControlJustPressed(0, 0xC7B5340A) then -- ENTER
                local sn = stages[currentStage].name
                print(string.format(
                    '[fdb-propeditor] %s > %s > %s = { x = %.3f, y = %.3f, z = %.3f, rx = %.1f, ry = %.1f, rz = %.1f },',
                    resource, item, sn, e_x, e_y, e_z, e_rx, e_ry, e_rz
                ))
            end

            -- Busca Prop
            if IsControlJustPressed(0, 0xB2F377E8) then -- F
                isSearching = not isSearching
                SetNuiFocus(isSearching, isSearching)
                SendNUIMessage({ action = 'toggleSearch', state = isSearching })
            end

            -- Fechar editor
            if IsControlJustPressed(0, 0x156F7119) then -- BACKSPACE
                SendNUIMessage({ action = 'hide' })
                StopEditor()
            end
        end
    end)
end)

-- -------------------------------------------------------
-- Callbacks NUI
-- -------------------------------------------------------
RegisterNUICallback('changeProp', function(data, cb)
    local newProp = data.propName
    if newProp then
        local hash = GetHashKey(newProp)
        if not HasModelLoaded(hash) then
            RequestModel(hash)
            local t = 0
            while not HasModelLoaded(hash) and t < 100 do Wait(10); t = t + 1 end
        end

        if HasModelLoaded(hash) then
            if DoesEntityExist(propObj) then
                DeleteObject(propObj)
            end
            local coords = GetEntityCoords(ped)
            propObj = CreateObject(hash, coords.x, coords.y, coords.z, true, true, false)
            UpdatePropAttach()
            print('[fdb-propeditor] Prop alterado para: ' .. newProp)
        else
            print('[fdb-propeditor] Falha ao carregar modelo: ' .. newProp)
        end
    end

    isSearching = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'toggleSearch', state = false })
    cb('ok')
end)

RegisterNUICallback('closeSearch', function(data, cb)
    isSearching = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'toggleSearch', state = false })
    cb('ok')
end)

RegisterNUICallback('startEdit', function(data, cb)
    SetNuiFocus(false, false)
    TriggerEvent('fdb-propeditor:client:open', data.resource, data.item)
    cb('ok')
end)

RegisterNUICallback('closeMenu', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)
