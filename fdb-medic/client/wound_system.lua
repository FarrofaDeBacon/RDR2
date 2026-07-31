-- =========================================================
-- FDB-MEDIC - WOUND SYSTEM (Phase C refactor)
-- =========================================================
-- This file handles core wound detection.
-- All progression, ballistics, and health logic have been moved
-- to the server (fdb-medical-core).
-- =========================================================

local RSGCore = exports['rsg-core']:GetCoreObject()
local LastDamageTime = 0
local DAMAGE_COOLDOWN = 1000
local PlayerHealth = nil
local LastKnownWeaponHash = nil

AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkEntityDamage' then
        local victim = args[1]
        if victim == PlayerPedId() then
            print('[DEBUG CEventNetworkEntityDamage] args completos:')
            for i, v in ipairs(args) do
                print(('  [%d] = %s'):format(i, tostring(v)))
            end
            -- Still capture it for now so testing works if it is 7, but we are primarily debugging
            LastKnownWeaponHash = args[7] 
        end
    end
end)

local function GetBodyPartFromBone(boneId)
    local boneMap = {
        [0] = 'NONE',
        [21030] = 'HEAD', [21031] = 'HEAD',
        [14283] = 'NECK',
        [14411] = 'Torso', [11569] = 'Torso', [23553] = 'Torso', [14410] = 'Torso',
        [14412] = 'Torso', [14413] = 'Torso', [14414] = 'Torso', [54802] = 'Torso',
        [64729] = 'Torso', [30226] = 'Torso', [56200] = 'Torso',
        [37873] = 'Arms', [53675] = 'Arms', [34606] = 'Arms', [41404] = 'Arms',
        [41405] = 'Arms', [41356] = 'Arms', [41357] = 'Arms', [41340] = 'Arms',
        [41341] = 'Arms', [41324] = 'Arms', [41325] = 'Arms', [41308] = 'Arms',
        [41309] = 'Arms', [41403] = 'Arms', [41323] = 'Arms', [41307] = 'Arms',
        [41355] = 'Arms', [41339] = 'Arms', [46065] = 'Arms', [54187] = 'Arms',
        [22798] = 'Arms', [16731] = 'Arms', [16732] = 'Arms', [16733] = 'Arms',
        [16747] = 'Arms', [16748] = 'Arms', [16749] = 'Arms', [16763] = 'Arms',
        [16764] = 'Arms', [16765] = 'Arms', [16779] = 'Arms', [16780] = 'Arms',
        [16781] = 'Arms', [16827] = 'Arms', [16828] = 'Arms', [16829] = 'Arms',
        [65478] = 'Legs', [55120] = 'Legs', [53081] = 'Legs', [45454] = 'Legs',
        [6884]  = 'Legs', [43312] = 'Legs', [41273] = 'Legs', [33646] = 'Legs'
    }
    
    local bodyPart = boneMap[boneId]
    if not bodyPart or bodyPart == 'NONE' then
        return 'Torso'
    end
    return bodyPart
end

local function GetWeaponDamageTypeEnum(weaponHash)
    -- This uses the native GetWeaponDamageType
    local typeInt = GetWeaponDamageType(weaponHash)
    if typeInt == 3 then
        return 'gunshot'
    elseif typeInt == 2 or typeInt == 1 then
        return 'melee'
    elseif typeInt == 5 or typeInt == 4 or typeInt == 11 then
        return 'fire'
    elseif typeInt == 6 or typeInt == 10 then
        return 'fall'
    end
    
    -- Fallback for animal attacks/claws which sometimes register as melee or unarmed
    return 'animal'
end

CreateThread(function()
    repeat Wait(1000) until LocalPlayer.state['isLoggedIn']
    
    print("^2[fdb-medic] Wound detection loop running^7")
    
    while true do
        local ped = PlayerPedId()
        local currentTime = GetGameTimer()
        
        if not PlayerHealth then
            PlayerHealth = GetEntityHealth(ped)
        end
        
        local currentHealth = GetEntityHealth(ped)
        
        if currentHealth < PlayerHealth and (currentTime - LastDamageTime > DAMAGE_COOLDOWN) then
            LastDamageTime = currentTime
            
            local hit, boneId = GetPedLastDamageBone(ped)
            if hit then
                local weaponHash = LastKnownWeaponHash or GetHashKey("WEAPON_UNARMED")
                LastKnownWeaponHash = nil -- Consome e limpa, evita vazar para dano futuro
                
                local bodyPart = GetBodyPartFromBone(boneId)
                local damageType = GetWeaponDamageTypeEnum(weaponHash)
                local amount = PlayerHealth - currentHealth
                
                print(string.format("[fdb-medic] Detected damage: %d on %s (Type: %s)", amount, bodyPart, damageType))
                
                TriggerServerEvent('fdb-medical-core:server:ReportDamage', bodyPart, damageType, amount)
            end
            
            PlayerHealth = currentHealth
        elseif currentHealth > PlayerHealth then
            -- Healed via other means
            PlayerHealth = currentHealth
        end
        
        Wait(200)
    end
end)
