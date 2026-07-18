-- ============================================================
-- fdb-hud | c/status.lua
-- Coleta e envia barras de status (saude, stamina) para a NUI
-- ============================================================

local ped = nil

-- Cache para evitar updates desnecessários
local lastStatus = { 
    health = -1, stamina = -1, dead = false, 
    hunger = -1, thirst = -1, stress = -1, bladder = -1, 
    isMounted = false, horseHealth = -1, horseStamina = -1 
}

local function GetNormalized(current, max)
    if max == 0 then return 0 end
    return math.max(0, math.min(100, math.floor((current / max) * 100)))
end

CreateThread(function()
    while true do
        Wait(Config.UpdateInterval)
        if not isLoggedIn then goto continue end

        ped = PlayerPedId()

        -- Player Basics
        local maxHealth = GetEntityMaxHealth(ped)
        local health  = GetNormalized(GetEntityHealth(ped), maxHealth)
        
        local rawStamina = Citizen.InvokeNative(0x0FF421E467373FCF, PlayerId(), Citizen.ResultAsFloat())
        print("DEBUG STAMINA NATIVE:", rawStamina)
        
        local stamina = GetNormalized(tonumber(string.format("%.2f", rawStamina)), 100)
        local dead    = IsEntityDead(ped)

        -- RSG Core Metadata
        local hunger = 100
        local thirst = 100
        local stress = 0
        local bladder = 0

        if PlayerData and PlayerData.metadata then
            hunger = PlayerData.metadata["hunger"] or 100
            thirst = PlayerData.metadata["thirst"] or 100
            stress = PlayerData.metadata["stress"] or 0
            bladder = PlayerData.metadata["bladder"] or 0
        end

        -- Horse Status
        local mount = GetMount(ped)
        local isMounted = false
        local horseHealth = 100
        local horseStamina = 100

        if mount and mount ~= 0 then
            isMounted = true
            horseHealth = GetNormalized(GetEntityHealth(mount), GetEntityMaxHealth(mount))
            
            local rawHorseStamina = Citizen.InvokeNative(0x0FF421E467373FCF, mount, Citizen.ResultAsFloat())
            print("DEBUG HORSE STAMINA NATIVE:", rawHorseStamina)
            
            horseStamina = GetNormalized(tonumber(string.format("%.2f", rawHorseStamina)), 100)
        end

        -- Check if anything changed
        local changed = false
        if health ~= lastStatus.health or stamina ~= lastStatus.stamina or dead ~= lastStatus.dead 
           or hunger ~= lastStatus.hunger or thirst ~= lastStatus.thirst 
           or stress ~= lastStatus.stress or bladder ~= lastStatus.bladder 
           or isMounted ~= lastStatus.isMounted 
           or horseHealth ~= lastStatus.horseHealth or horseStamina ~= lastStatus.horseStamina then
            changed = true
        end

        if changed then
            lastStatus = { 
                health = health, stamina = stamina, dead = dead,
                hunger = hunger, thirst = thirst, stress = stress, bladder = bladder,
                isMounted = isMounted, horseHealth = horseHealth, horseStamina = horseStamina
            }
            SendNUI('updateStatus', lastStatus)

            -- Sincroniza com o StateBag para scripts antigos que dependem disso (ex: rsg-consume)
            LocalPlayer.state:set("hunger", hunger, false)
            LocalPlayer.state:set("thirst", thirst, false)
            LocalPlayer.state:set("stress", stress, false)
            LocalPlayer.state:set("bladder", bladder, false)
        end

        ::continue::
    end
end)

-- -------------------------------------------------------
-- Interceptadores de consumíveis (rsg-consume, etc.)
-- -------------------------------------------------------
RegisterNetEvent('hud:client:UpdateThirst', function(newThirst)
    print("DEBUG HUD: Recebido hud:client:UpdateThirst! newThirst=", newThirst)
    local currentThirst = PlayerData.metadata and PlayerData.metadata['thirst'] or 100
    local amount = newThirst - currentThirst
    print("DEBUG HUD: amount a enviar=", amount, "currentThirst=", currentThirst)
    if amount > 0 then
        TriggerServerEvent('fdb-hud:server:UpdateThirstBladder', amount)
    end
end)

RegisterNetEvent('hud:client:UpdateHunger', function(newHunger)
    print("DEBUG HUD: Recebido hud:client:UpdateHunger! newHunger=", newHunger)
    local currentHunger = PlayerData.metadata and PlayerData.metadata['hunger'] or 100
    local amount = newHunger - currentHunger
    if amount > 0 then
        TriggerServerEvent('fdb-hud:server:UpdateHunger', amount)
    end
end)

-- ============================================================
-- Animação de Mijar e Efeito da Bexiga Cheia
-- ============================================================
local isHoldingPee = false

RegisterNetEvent('fdb-hud:client:DoPee', function()
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    
    -- Inicia o cenário completo (com abrir e fechar a calça)
    TaskStartScenarioInPlace(ped, joaat('WORLD_HUMAN_PEE'), -1, true, false, false, false)

    -- Espera a parte de abrir a calça terminar (aprox 4 segundos)
    Wait(4000)

    -- Configuração da Partícula (PTFX)
    local assetName = "core" 
    local ptfxName = "ent_anim_dog_peeing" 

    RequestNamedPtfxAsset(assetName)
    while not HasNamedPtfxAssetLoaded(assetName) do
        Wait(10)
    end

    UseParticleFxAsset(assetName)

    local boneIndex = GetEntityBoneIndexByName(ped, "SKEL_Pelvis")
    local offsetX, offsetY, offsetZ = 0.0, 0.15, -0.1
    local rotX, rotY, rotZ = -90.0, 0.0, 0.0

    -- Jato mais grosso (escala aumentada para 2.5)
    local peeParticle = StartNetworkedParticleFxLoopedOnEntityBone(
        ptfxName, ped,
        offsetX, offsetY, offsetZ,
        rotX, rotY, rotZ,
        boneIndex,
        2.5, -- <== ESCALA (Grossura do jato)
        false, false, false
    )

    -- Tempo de duração do jato de água
    Wait(6000)

    -- Desliga o jato, mas deixa o personagem terminar de fechar a calça!
    StopParticleFxLooped(peeParticle, false)
    RemoveNamedPtfxAsset(assetName)

    -- Espera o cenário terminar naturalmente (aprox 3 a 4 segundos)
    Wait(3500)
    ClearPedTasks(ped)
end)

-- Thread para bloquear corrida/pulo quando estiver apertado
CreateThread(function()
    while true do
        Wait(0)
        if isHoldingPee then
            DisableControlAction(0, joaat('INPUT_SPRINT'), true)
            DisableControlAction(0, joaat('INPUT_JUMP'), true)
            DisableControlAction(0, joaat('INPUT_HORSE_SPRINT'), true)
        else
            Wait(1000)
        end
    end
end)

CreateThread(function()
    while true do
        Wait(2000)
        if LocalPlayer.state.isLoggedIn and PlayerData and PlayerData.metadata then
            local ped = PlayerPedId()
            local bladder = PlayerData.metadata["bladder"] or 0
            
            if bladder >= 80 and not isHoldingPee then
                isHoldingPee = true
                -- Usa o estilo war_veteran que o faz mancar/andar esquisito
                Citizen.InvokeNative(0x923583741DC87BCE, ped, 'war_veteran')
                lib.notify({title = 'Sua bexiga está muito cheia!', description = 'Você está apertado! Encontre um lugar para se aliviar (/mijar).', type = 'warning', duration = 5000})
            elseif bladder < 80 and isHoldingPee then
                isHoldingPee = false
                -- Restaura o andar padrão
                Citizen.InvokeNative(0x923583741DC87BCE, ped, 'default')
                Citizen.InvokeNative(0x89F5E7ADECCCB49C, ped, 'normal')
            end
        end
    end
end)

RegisterNetEvent('hud:client:RelieveStress', function(amount)
    -- RelieveStress costuma mandar direto a quantidade a ser aliviada.
    if type(amount) == "number" and amount > 0 then
        TriggerServerEvent('fdb-hud:server:RelieveStress', amount)
    end
end)
