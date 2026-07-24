local RSGCore = exports['rsg-core']:GetCoreObject()
local isLoggedIn = false

local DRYING_TIME_MS = 120000 -- 2 minutes out of water to dry
local TICK_RATE = 4000 -- Matches Config.DrainRates.TickRate from fdb-survival
local timeOutWater = 0

local function ResetDryingTimer()
    timeOutWater = 0
end

local function StartDryingTimer()
    if LocalPlayer.state.isWet then
        timeOutWater = timeOutWater + TICK_RATE
        if timeOutWater >= DRYING_TIME_MS then
            TriggerServerEvent('fdb-water:server:dryPlayer')
            timeOutWater = 0
        end
    else
        timeOutWater = 0
    end
end

RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    isLoggedIn = true
    timeOutWater = 0
end)

RegisterNetEvent('RSGCore:Client:OnPlayerUnload', function()
    isLoggedIn = false
end)

CreateThread(function()
    while true do
        Wait(TICK_RATE)
        if isLoggedIn then
            local ped = cache.ped
            
            if IsEntityInWater(ped) and GetEntitySubmergedLevel(ped) > 0.3 then
                ResetDryingTimer()
                
                -- Anti-spam for cleanliness
                local pData = RSGCore.Functions.GetPlayerData()
                if pData and pData.metadata then
                    local currentCleanliness = pData.metadata['cleanliness'] or 100
                    if currentCleanliness < 100 then
                        TriggerServerEvent('fdb-water:server:WashInRiver')
                    end
                end
                
                -- Anti-spam for isWet
                if not LocalPlayer.state.isWet then
                    TriggerServerEvent('fdb-water:server:makeWet')
                end
            else
                StartDryingTimer()
            end
        end
    end
end)
