local isEditing = false
local currentStage = 1
local itemName = "cigar"
local propObj = 0

local e_x, e_y, e_z = 0.0, 0.0, 0.0
local e_rx, e_ry, e_rz = 0.0, 0.0, 0.0
local e_bone = "skel_head"
local ped = 0

local stages = {
    { name = "mouth_start", animDict = "amb_rest@world_human_smoking@male_c@idle_a", animName = "idle_a", bone = "skel_head" },
    { name = "hand_enter", animDict = "amb_rest@world_human_smoking@male_c@base", animName = "base", bone = "SKEL_R_Finger13" },
    { name = "mouth_puff", animDict = "amb_rest@world_human_smoking@male_c@idle_a", animName = "idle_a", bone = "skel_head" },
    { name = "hand_idle", animDict = "amb_rest@world_human_smoking@male_c@base", animName = "base", bone = "SKEL_R_Finger13" }
}

local function DrawTxt(text, x, y)
    SetTextScale(0.25, 0.25)
    SetTextColor(255, 255, 255, 255)
    SetTextDropshadow(2, 0, 0, 0, 255)
    SetTextFontForCurrentCommand(0)
    DisplayText(CreateVarString(10, "LITERAL_STRING", text), x, y)
end

local function PlayStageAnim()
    local stageData = stages[currentStage]
    local dict = stageData.animDict
    local name = stageData.animName
    
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do Wait(10) end
    end
    
    ClearPedTasks(ped)
    TaskPlayAnim(ped, dict, name, 1.0, 1.0, -1, 1, 0.0, false, 0, false, "", false)
end

local function UpdatePropAttach()
    local stageData = stages[currentStage]
    local boneIndex = GetEntityBoneIndexByName(ped, stageData.bone)
    AttachEntityToEntity(propObj, ped, boneIndex, e_x, e_y, e_z, e_rx, e_ry, e_rz, true, true, false, true, 1, true)
end

local function LoadOffsetsFromConfig()
    local itemData = Config.Items[itemName]
    if itemData and itemData.offsets then
        local stageName = stages[currentStage].name
        local off = itemData.offsets[stageName]
        if off then
            e_x, e_y, e_z = off.x or 0.0, off.y or 0.0, off.z or 0.0
            e_rx, e_ry, e_rz = off.rx or 0.0, off.ry or 0.0, off.rz or 0.0
        else
            e_x, e_y, e_z, e_rx, e_ry, e_rz = 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
        end
        if itemData.offsets.bone and (currentStage == 2 or currentStage == 4) then
            stages[currentStage].bone = itemData.offsets.bone
        end
    end
end

RegisterCommand('propedit', function(source, args)
    if isEditing then return end
    
    itemName = args[1] or "cigar"
    local itemData = Config.Items[itemName]
    
    if not itemData or not itemData.prop then
        print("^1[fdb-consume] Item nao encontrado ou sem prop configurado: " .. tostring(itemName) .. "^7")
        return
    end
    
    isEditing = true
    currentStage = 1
    ped = PlayerPedId()
    
    local hash = GetHashKey(itemData.prop)
    if not HasModelLoaded(hash) then
        RequestModel(hash)
        while not HasModelLoaded(hash) do Wait(10) end
    end
    
    local coords = GetEntityCoords(ped)
    propObj = CreateObject(hash, coords.x, coords.y, coords.z, true, true, false)
    
    LoadOffsetsFromConfig()
    PlayStageAnim()
    UpdatePropAttach()
    
    Citizen.CreateThread(function()
        while isEditing do
            Wait(0)
            
            -- Render HUD Vertical
            DrawTxt("MODO DE EDICAO: " .. string.upper(itemName), 0.02, 0.30)
            DrawTxt("ESTAGIO: " .. stages[currentStage].name .. " (" .. currentStage .. "/4)", 0.02, 0.33)
            DrawTxt("[ESPAÇO] - Trocar Estagio", 0.02, 0.36)
            DrawTxt("[W][S][A][D] - Mover Horizontal", 0.02, 0.39)
            DrawTxt("[PgUp][PgDn] - Mover Vertical", 0.02, 0.42)
            DrawTxt("Segurar [SHIFT] - Girar Prop (Rotacao)", 0.02, 0.45)
            DrawTxt("[ENTER] - Salvar no console F8", 0.02, 0.48)
            DrawTxt("[BACKSPACE] - Sair do Editor", 0.02, 0.51)
            
            DrawTxt(string.format("X: %.3f | Y: %.3f | Z: %.3f", e_x, e_y, e_z), 0.02, 0.56)
            DrawTxt(string.format("RX: %.1f | RY: %.1f | RZ: %.1f", e_rx, e_ry, e_rz), 0.02, 0.59)
            
            local speed = 0.005
            local rspeed = 2.0
            local changed = false
            
            DisableControlAction(0, 0x8FD015D8, true) -- W
            DisableControlAction(0, 0xD27782E3, true) -- S
            DisableControlAction(0, 0x7065027D, true) -- A
            DisableControlAction(0, 0xB4E465B4, true) -- D
            
            local shift = IsControlPressed(0, 0x8FFC75D6) -- Shift
            
            if shift then
                if IsDisabledControlPressed(0, 0x8FD015D8) then e_rx = e_rx + rspeed; changed = true; end -- W
                if IsDisabledControlPressed(0, 0xD27782E3) then e_rx = e_rx - rspeed; changed = true; end -- S
                if IsDisabledControlPressed(0, 0x7065027D) then e_ry = e_ry + rspeed; changed = true; end -- A
                if IsDisabledControlPressed(0, 0xB4E465B4) then e_ry = e_ry - rspeed; changed = true; end -- D
                if IsControlPressed(0, 0x4403F97F) then e_rz = e_rz + rspeed; changed = true; end -- PgUp
                if IsControlPressed(0, 0x3C3DD371) then e_rz = e_rz - rspeed; changed = true; end -- PgDn
            else
                if IsDisabledControlPressed(0, 0x8FD015D8) then e_y = e_y + speed; changed = true; end -- W
                if IsDisabledControlPressed(0, 0xD27782E3) then e_y = e_y - speed; changed = true; end -- S
                if IsDisabledControlPressed(0, 0x7065027D) then e_x = e_x - speed; changed = true; end -- A
                if IsDisabledControlPressed(0, 0xB4E465B4) then e_x = e_x + speed; changed = true; end -- D
                if IsControlPressed(0, 0x4403F97F) then e_z = e_z + speed; changed = true; end -- PgUp
                if IsControlPressed(0, 0x3C3DD371) then e_z = e_z - speed; changed = true; end -- PgDn
            end
            
            if changed then
                UpdatePropAttach()
                Wait(50) 
            end
            
            if IsControlJustPressed(0, 0xD9D0E1C0) then -- ESPACO
                currentStage = currentStage + 1
                if currentStage > 4 then currentStage = 1 end
                LoadOffsetsFromConfig()
                PlayStageAnim()
                UpdatePropAttach()
            end
            
            if IsControlJustPressed(0, 0xC7B5340A) then -- ENTER
                local sn = stages[currentStage].name
                print(string.format("%s = { x = %.3f, y = %.3f, z = %.3f, rx = %.1f, ry = %.1f, rz = %.1f },", sn, e_x, e_y, e_z, e_rx, e_ry, e_rz))
            end
            
            if IsControlJustPressed(0, 0x156F7119) then -- BACKSPACE
                isEditing = false
                ClearPedTasks(ped)
                DeleteObject(propObj)
                print("Editor fechado.")
            end
        end
    end)
end)
