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
        end

        ::continue::
    end
end)

-- -------------------------------------------------------
-- Interceptadores de consumíveis (rsg-consume, etc.)
-- -------------------------------------------------------
RegisterNetEvent('hud:client:UpdateThirst', function(newThirst)
    -- Os scripts antigos enviam o valor absoluto (ex: thirst atual + amount).
    -- Nós queremos enviar apenas o 'amount' pro servidor somar de forma segura?
    -- Não, se o rsg-consume envia (thirst + amount), vamos subtrair o thirst atual.
    local currentThirst = PlayerData.metadata and PlayerData.metadata['thirst'] or 100
    local amount = newThirst - currentThirst
    if amount > 0 then
        TriggerServerEvent('fdb-hud:server:UpdateThirstBladder', amount)
    end
end)

RegisterNetEvent('hud:client:UpdateHunger', function(newHunger)
    local currentHunger = PlayerData.metadata and PlayerData.metadata['hunger'] or 100
    local amount = newHunger - currentHunger
    if amount > 0 then
        TriggerServerEvent('fdb-hud:server:UpdateHunger', amount)
    end
end)

RegisterNetEvent('hud:client:RelieveStress', function(amount)
    -- RelieveStress costuma mandar direto a quantidade a ser aliviada.
    if type(amount) == "number" and amount > 0 then
        TriggerServerEvent('fdb-hud:server:RelieveStress', amount)
    end
end)
