--=========================================================
-- QC-ADVANCED MEDIC - SERVER MEDICAL EVENTS
--=========================================================
-- This file handles all server-side medical events and network communication
-- Connects the database layer with client-side medical systems
--=========================================================

local RSGCore = exports['rsg-core']:GetCoreObject()

-- Helper function to check if player has any medic job
local function IsMedicJob(jobName)
    if not jobName then return false end

    -- Check against all jobs in MedicJobLocations
    for _, location in pairs(Config.MedicJobLocations) do
        if location.job == jobName then
            return true
        end
    end

    return false
end

--=========================================================
-- WOUND DATA EVENTS
--=========================================================

-- Update wound data from client
RegisterNetEvent('fdb-medic:server:UpdateWoundData')
AddEventHandler('fdb-medic:server:UpdateWoundData', function(woundData)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    if not citizenid then return end

    -- Save wound data to database
    exports['fdb-medic']:SaveWoundData(citizenid, woundData)

    -- Update server-side cache (internal event to medical_server.lua)
    TriggerEvent('fdb-medic:internal:UpdateWoundCache', src, woundData)

    -- Broadcast wound data to nearby players (for medic inspection)
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    local players = RSGCore.Functions.GetRSGPlayers()

    for _, player in pairs(players) do
        if player.PlayerData.source ~= src then
            local targetCoords = GetEntityCoords(GetPlayerPed(player.PlayerData.source))
            local distance = #(playerCoords - targetCoords)

            if distance <= 10.0 then -- Within 10 meters
                TriggerClientEvent('fdb-medic:client:UpdateNearbyPlayerWounds', player.PlayerData.source, src, woundData)
            end
        end
    end
end)

-- Get wound data for a specific player (for medic inspection)
RegisterNetEvent('fdb-medic:server:RequestWoundData')
AddEventHandler('fdb-medic:server:RequestWoundData', function(targetPlayerId)
    local src = source
    local Medic = RSGCore.Functions.GetPlayer(src)
    local Target = RSGCore.Functions.GetPlayer(targetPlayerId)
    
    if not Medic or not Target then return end
    
    -- Check if requesting player is a medic
    if not IsMedicJob(Medic.PlayerData.job.name) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('sv_access_denied'),
            description = locale('sv_medical_personnel_only'),
            type = 'error',
            duration = 5000
        })
        return
    end
    
    -- Get complete medical profile
    local medicalProfile = exports['fdb-medic']:GetCompleteMedicalProfile(Target.PlayerData.citizenid)
    
    -- Send data to medic
    TriggerClientEvent('fdb-medic:client:ReceiveMedicalProfile', src, targetPlayerId, medicalProfile)
    
    -- Log the inspection
    exports['fdb-medic']:LogMedicalInspection(
        Target.PlayerData.citizenid,
        Medic.PlayerData.citizenid,
        'basic',
        medicalProfile,
        nil
    )
end)

--=========================================================
-- TREATMENT EVENTS
--=========================================================

-- Update treatment data from client
RegisterNetEvent('fdb-medic:server:UpdateTreatmentData')
AddEventHandler('fdb-medic:server:UpdateTreatmentData', function(treatmentData)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    if not citizenid then return end

    -- Save treatment data to database
    exports['fdb-medic']:SaveTreatmentData(citizenid, treatmentData)

    -- Update server-side cache (internal event to medical_server.lua)
    TriggerEvent('fdb-medic:internal:UpdateTreatmentCache', src, treatmentData)
end)

-- Treatment removal event (for NUI and medic interfaces)
RegisterNetEvent('fdb-medic:server:TreatmentRemoved')
AddEventHandler('fdb-medic:server:TreatmentRemoved', function(bodyPart, treatmentType, treatmentData)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    if not citizenid then return end
    
    -- Log treatment removal in medical history
    pcall(function()
        exports['fdb-medic']:LogMedicalEvent(citizenid, 'treatment_removed', bodyPart, {
            treatmentType = treatmentType,
            itemType = treatmentData.itemType,
            appliedBy = treatmentData.appliedBy,
            removedBy = citizenid,
            duration = treatmentData.appliedTime and ((GetGameTimer() - treatmentData.appliedTime) / 1000 / 60) or nil -- Duration in minutes
        })
    end)
    
    -- Broadcast to nearby medics for NUI updates (within 20 meters)
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    local players = RSGCore.Functions.GetRSGPlayers()
    
    for _, nearbyPlayer in pairs(players) do
        if nearbyPlayer.PlayerData.source ~= src and IsMedicJob(nearbyPlayer.PlayerData.job.name) then
            local medicCoords = GetEntityCoords(GetPlayerPed(nearbyPlayer.PlayerData.source))
            local distance = #(playerCoords - medicCoords)
            
            if distance <= 20.0 then
                TriggerClientEvent('fdb-medic:client:TreatmentRemovedNearby', nearbyPlayer.PlayerData.source, {
                    playerId = src,
                    playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                    bodyPart = bodyPart,
                    treatmentType = treatmentType,
                    treatmentData = treatmentData
                })
            end
        end
    end
end)

-- Apply treatment to a player (from medic)
RegisterNetEvent('fdb-medic:server:ApplyTreatment')
AddEventHandler('fdb-medic:server:ApplyTreatment', function(targetPlayerId, treatmentType, itemType, bodyPart)
    local src = source
    local Medic = RSGCore.Functions.GetPlayer(src)
    local Target = RSGCore.Functions.GetPlayer(targetPlayerId)
    
    if not Medic or not Target then return end
    
    -- Check if requesting player is a medic
    if not IsMedicJob(Medic.PlayerData.job.name) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('sv_access_denied'),
            description = locale('sv_medical_personnel_only_treatment'),
            type = 'error',
            duration = 5000
        })
        return
    end
    
    -- Check if medic has the required item
    local hasItem = false
    if treatmentType == 'bandage' then
        hasItem = Medic.Functions.GetItemByName(itemType) ~= nil
    elseif treatmentType == 'tourniquet' then
        hasItem = Medic.Functions.GetItemByName('tourniquet') ~= nil
    elseif treatmentType == 'medicine' then
        hasItem = Medic.Functions.GetItemByName(itemType) ~= nil
    elseif treatmentType == 'injection' then
        hasItem = Medic.Functions.GetItemByName('syringe') ~= nil and Medic.Functions.GetItemByName(itemType) ~= nil
    end
    
    if not hasItem then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('sv_missing_supplies'),
            description = locale('sv_no_required_supplies'),
            type = 'error',
            duration = 5000
        })
        return
    end
    
    -- Remove item from medic inventory
    if treatmentType == 'bandage' then
        Medic.Functions.RemoveItem(itemType, 1)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[itemType], 'remove', 1)
    elseif treatmentType == 'tourniquet' then
        Medic.Functions.RemoveItem('tourniquet', 1)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items['tourniquet'], 'remove', 1)
    elseif treatmentType == 'medicine' then
        Medic.Functions.RemoveItem(itemType, 1)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[itemType], 'remove', 1)
    elseif treatmentType == 'injection' then
        Medic.Functions.RemoveItem('syringe', 1)
        Medic.Functions.RemoveItem(itemType, 1)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items['syringe'], 'remove', 1)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[itemType], 'remove', 1)
    end
    
    -- Apply treatment to target player
    if treatmentType == 'bandage' then
        TriggerClientEvent('fdb-medic:client:ApplyBandage', Target.PlayerData.source, bodyPart, itemType, Medic.PlayerData.citizenid)
    elseif treatmentType == 'tourniquet' then
        TriggerClientEvent('fdb-medic:client:ApplyTourniquet', Target.PlayerData.source, bodyPart, itemType, Medic.PlayerData.citizenid)
    elseif treatmentType == 'medicine' then
        TriggerClientEvent('fdb-medic:client:AdministreMedicine', Target.PlayerData.source, itemType, Medic.PlayerData.citizenid)
    elseif treatmentType == 'injection' then
        TriggerClientEvent('fdb-medic:client:GiveInjection', Target.PlayerData.source, itemType, Medic.PlayerData.citizenid)
    end
    
    -- Notify both players
    TriggerClientEvent('ox_lib:notify', src, {
        title = locale('sv_treatment_applied'),
        description = string.format(locale('sv_applied_treatment_to'), itemType, Target.PlayerData.charinfo.firstname),
        type = 'success',
        duration = 5000
    })
    
    TriggerClientEvent('ox_lib:notify', Target.PlayerData.source, {
        title = locale('sv_medical_treatment'),
        description = string.format(locale('sv_doctor_applied_treatment'), Medic.PlayerData.charinfo.lastname, itemType),
        type = 'inform',
        duration = 8000
    })
end)

--=========================================================
-- MEDICAL DATA PERSISTENCE
--=========================================================

-- Load all medical data from database (wounds, infections, treatments)
RegisterNetEvent('fdb-medic:server:LoadMedicalData')
AddEventHandler('fdb-medic:server:LoadMedicalData', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    if not citizenid then return end
    
    -- Load essential medical data safely (only from tables that exist)
    local wounds = {}
    local infections = {}
    local treatments = {}
    
    -- Safely load wounds
    pcall(function()
        wounds = exports['fdb-medic']:LoadWoundData(citizenid) or {}
    end)
    
    -- Safely load infections  
    pcall(function()
        infections = exports['fdb-medic']:LoadInfectionData(citizenid) or {}
    end)
    
    -- Safely load treatments
    pcall(function()
        treatments = exports['fdb-medic']:LoadTreatmentData(citizenid) or {}
    end)
    
    -- Send data to client systems
    if next(wounds) then
        TriggerClientEvent('fdb-medic:client:LoadWounds', src, wounds)
    end
    
    if next(infections) then
        TriggerClientEvent('fdb-medic:client:LoadInfections', src, infections)
    end
    
    if next(treatments) then
        TriggerClientEvent('fdb-medic:client:LoadTreatments', src, treatments)
    end
    
    if Config.InfectionSystem.debugging.enabled then
        local woundCount = 0
        local infectionCount = 0
        local treatmentCount = 0
        
        for _ in pairs(wounds) do woundCount = woundCount + 1 end
        for _ in pairs(infections) do infectionCount = infectionCount + 1 end
        for _ in pairs(treatments) do treatmentCount = treatmentCount + 1 end
        
        print(string.format("[PERSISTENCE] Loaded medical data for %s: %d wounds, %d infections, %d treatments", 
            citizenid, woundCount, infectionCount, treatmentCount))
    end
end)

--=========================================================
-- INFECTION EVENTS
--=========================================================

-- Update infection data from client
RegisterNetEvent('fdb-medic:server:UpdateInfectionData')
AddEventHandler('fdb-medic:server:UpdateInfectionData', function(infectionData)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local citizenid = Player.PlayerData.citizenid
    if not citizenid then return end

    -- Save infection data to database
    exports['fdb-medic']:SaveInfectionData(citizenid, infectionData)

    -- Update server-side cache (internal event to medical_server.lua)
    TriggerEvent('fdb-medic:internal:UpdateInfectionCache', src, infectionData)
end)

-- Log infection cure
RegisterNetEvent('fdb-medic:server:LogInfectionCure')
AddEventHandler('fdb-medic:server:LogInfectionCure', function(bodyPart, treatmentItem)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    if not citizenid then return end
    
    -- Log infection cure in medical history
    pcall(function()
        exports['fdb-medic']:LogMedicalEvent(citizenid, 'infection_cured', bodyPart, {
            treatmentUsed = treatmentItem,
            curedBy = citizenid
        })
    end)
end)

-- Treat infection
RegisterNetEvent('fdb-medic:server:TreatInfection')
AddEventHandler('fdb-medic:server:TreatInfection', function(targetPlayerId, bodyPart, treatmentItem)
    local src = source
    local Medic = RSGCore.Functions.GetPlayer(src)
    local Target = targetPlayerId and RSGCore.Functions.GetPlayer(targetPlayerId) or Medic
    
    if not Medic or not Target then return end
    
    -- Check if medic has the required treatment item
    if not Medic.Functions.GetItemByName(treatmentItem) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('sv_missing_supplies'),
            description = locale('sv_no_required_treatment'),
            type = 'error',
            duration = 5000
        })
        return
    end
    
    -- Remove treatment item
    Medic.Functions.RemoveItem(treatmentItem, 1)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[treatmentItem], 'remove', 1)
    
    -- Apply treatment
    TriggerClientEvent('fdb-medic:client:TreatInfection', Target.PlayerData.source, bodyPart, treatmentItem)
end)

--=========================================================
-- MEDICAL BAG USAGE TRACKING
--=========================================================

-- Track medical bag usage for crafting
RegisterNetEvent('fdb-medic:server:UseMedicalBag')
AddEventHandler('fdb-medic:server:UseMedicalBag', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Log medical bag usage
    exports['fdb-medic']:LogMedicalEvent(
        Player.PlayerData.citizenid,
        'medical_bag_used',
        nil,
        {
            location = GetEntityCoords(GetPlayerPed(src)),
            timestamp = os.time()
        }
    )
end)

--=========================================================
-- MEDICAL INSPECTION SYSTEM
--=========================================================

-- Start medical inspection
RegisterNetEvent('fdb-medic:server:StartMedicalInspection')
AddEventHandler('fdb-medic:server:StartMedicalInspection', function(targetPlayerId)
    local src = source
    local Medic = RSGCore.Functions.GetPlayer(src)
    local Target = RSGCore.Functions.GetPlayer(targetPlayerId)
    
    if not Medic or not Target then return end
    
    -- Check if requesting player is a medic
    if not IsMedicJob(Medic.PlayerData.job.name) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('sv_access_denied'),
            description = locale('sv_medical_personnel_only_inspect'),
            type = 'error',
            duration = 5000
        })
        return
    end
    
    -- Check distance
    local medicCoords = GetEntityCoords(GetPlayerPed(src))
    local targetCoords = GetEntityCoords(GetPlayerPed(Target.PlayerData.source))
    local distance = #(medicCoords - targetCoords)
    
    if distance > 3.0 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('sv_too_far_away'),
            description = locale('sv_need_closer_patient'),
            type = 'error',
            duration = 5000
        })
        return
    end
    
    -- Get complete medical profile
    local medicalProfile = exports['fdb-medic']:GetCompleteMedicalProfile(Target.PlayerData.citizenid)
    
    -- Add patient character info
    medicalProfile.patientInfo = {
        name = Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname,
        citizenid = Target.PlayerData.citizenid,
        serverId = Target.PlayerData.source
    }
    
    -- Send inspection data to medic
    TriggerClientEvent('fdb-medic:client:StartMedicalInspection', src, medicalProfile)
    
    -- Notify patient
    TriggerClientEvent('ox_lib:notify', Target.PlayerData.source, {
        title = locale('sv_medical_inspection'),
        description = string.format(locale('sv_doctor_examining'), Medic.PlayerData.charinfo.lastname),
        type = 'inform',
        duration = 8000
    })
    
    -- Log the inspection
    exports['fdb-medic']:LogMedicalInspection(
        Target.PlayerData.citizenid,
        Medic.PlayerData.citizenid,
        'detailed',
        medicalProfile,
        nil
    )
end)

-- Complete medical inspection with treatments
RegisterNetEvent('fdb-medic:server:CompleteMedicalInspection')
AddEventHandler('fdb-medic:server:CompleteMedicalInspection', function(targetPlayerId, findings, treatments, notes)
    local src = source
    local Medic = RSGCore.Functions.GetPlayer(src)
    local Target = RSGCore.Functions.GetPlayer(targetPlayerId)
    
    if not Medic or not Target then return end
    
    -- Log the completed inspection
    exports['fdb-medic']:LogMedicalInspection(
        Target.PlayerData.citizenid,
        Medic.PlayerData.citizenid,
        'detailed',
        findings,
        treatments
    )
    
    -- Log in medical history
    exports['fdb-medic']:LogMedicalEvent(
        Target.PlayerData.citizenid,
        'medical_inspection',
        nil,
        {
            medicName = Medic.PlayerData.charinfo.firstname .. ' ' .. Medic.PlayerData.charinfo.lastname,
            findings = findings,
            treatments = treatments,
            notes = notes
        },
        Medic.PlayerData.citizenid
    )
end)

--=========================================================
-- PLAYER DATA SYNCHRONIZATION
--=========================================================

-- Load medical data on player connect
RegisterNetEvent('RSGCore:Server:PlayerLoaded')
AddEventHandler('RSGCore:Server:PlayerLoaded', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
 
    local citizenid = Player.PlayerData.citizenid
    if not citizenid then return end
    
    -- Load complete medical profile
    local medicalProfile = exports['fdb-medic']:GetCompleteMedicalProfile(citizenid)
    
    -- Send data to client
    TriggerClientEvent('fdb-medic:client:LoadMedicalData', src, medicalProfile)
end)

-- Save medical data on disconnect
RegisterNetEvent('fdb-medic:server:SaveMedicalDataOnDisconnect')
AddEventHandler('fdb-medic:server:SaveMedicalDataOnDisconnect', function(woundData, treatmentData, infectionData)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    if not citizenid then return end
    
    -- Save all medical data
    if woundData then
        exports['fdb-medic']:SaveWoundData(citizenid, woundData)
    end
    
    if treatmentData then
        exports['fdb-medic']:SaveTreatmentData(citizenid, treatmentData)
    end
    
    if infectionData then
        exports['fdb-medic']:SaveInfectionData(citizenid, infectionData)
    end
end)

--=========================================================
-- MEDICAL ITEM USAGE
--=========================================================

-- Enhanced bandage usage
RSGCore.Functions.CreateUseableItem('bandage', function(source, item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Check if player is injured
    TriggerClientEvent('fdb-medic:client:CheckForSelfTreatment', src, 'bandage', item.info.type or 'cotton')
end)

-- Tourniquet usage
RSGCore.Functions.CreateUseableItem('tourniquet', function(source, item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    TriggerClientEvent('fdb-medic:client:CheckForSelfTreatment', src, 'tourniquet', item.info.type or 'cloth')
end)

-- Medicine usage
for medicineType, _ in pairs(Config.MedicineTypes) do
    RSGCore.Functions.CreateUseableItem(medicineType, function(source, item)
        local src = source
        -- Fixed: src is already the player's source ID on server
        TriggerClientEvent('fdb-medic:client:AdministreMedicine', src, medicineType, src)

        -- Remove item
        local Player = RSGCore.Functions.GetPlayer(src)
        if Player then
            Player.Functions.RemoveItem(medicineType, 1)
            TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[medicineType], 'remove', 1)
        end
    end)
end

--=========================================================
-- CALLBACK FUNCTIONS
--=========================================================

-- Get nearby injured players
RSGCore.Functions.CreateCallback('fdb-medic:server:GetNearbyInjuredPlayers', function(source, cb, maxDistance)
    local src = source
    local medicCoords = GetEntityCoords(GetPlayerPed(src))
    maxDistance = maxDistance or 10.0
    
    local injuredPlayers = {}
    local players = RSGCore.Functions.GetRSGPlayers()
    
    for _, player in pairs(players) do
        if player.PlayerData.source ~= src then
            local targetCoords = GetEntityCoords(GetPlayerPed(player.PlayerData.source))
            local distance = #(medicCoords - targetCoords)
            
            if distance <= maxDistance then
                -- Check if player has injuries
                local medicalProfile = exports['fdb-medic']:GetCompleteMedicalProfile(player.PlayerData.citizenid)
                
                if next(medicalProfile.wounds) or next(medicalProfile.infections) then
                    table.insert(injuredPlayers, {
                        serverId = player.PlayerData.source,
                        name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
                        distance = distance,
                        wounds = medicalProfile.wounds,
                        infections = medicalProfile.infections
                    })
                end
            end
        end
    end
    
    cb(injuredPlayers)
end)

-- Get player medical profile
RSGCore.Functions.CreateCallback('fdb-medic:server:GetPlayerMedicalProfile', function(source, cb, targetPlayerId)
    local Target = RSGCore.Functions.GetPlayer(targetPlayerId) 
    if not Target then
        cb({})
        return
    end
    
    local medicalProfile = exports['fdb-medic']:GetCompleteMedicalProfile(Target.PlayerData.citizenid)
    cb(medicalProfile)
end)

--=========================================================
-- FRACTURE SYSTEM EVENTS
--=========================================================

-- Save fracture data from client
RegisterNetEvent('fdb-medic:server:SaveFracture')
AddEventHandler('fdb-medic:server:SaveFracture', function(bodyPart, fractureData)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local success = SaveFracture(citizenid, bodyPart, fractureData)
    
    if success then
        print(string.format('[fdb-medic] Saved fracture for %s: %s %s', citizenid, bodyPart, fractureData.type or 'fracture'))
    end
end)

-- Load fractures for player
RegisterNetEvent('fdb-medic:server:LoadFractures')
AddEventHandler('fdb-medic:server:LoadFractures', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local fractures = LoadFractures(citizenid)
    
    TriggerClientEvent('fdb-medic:client:LoadFractures', src, fractures)
    print(string.format('[fdb-medic] Loaded %d fractures for %s', #fractures, citizenid))
end)

-- Heal fracture
RegisterNetEvent('fdb-medic:server:HealFracture')
AddEventHandler('fdb-medic:server:HealFracture', function(bodyPart)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local success = HealFracture(citizenid, bodyPart)
    
    if success then
        TriggerClientEvent('fdb-medic:client:FractureHealed', src, bodyPart)
        print(string.format('[fdb-medic] Healed fracture for %s: %s', citizenid, bodyPart))
    end
end)

-- Get fracture status callback
RSGCore.Functions.CreateCallback('fdb-medic:server:GetFractures', function(source, cb)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then
        cb({})
        return
    end
    
    local fractures = LoadFractures(Player.PlayerData.citizenid)
    cb(fractures)
end)
