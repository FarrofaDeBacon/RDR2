local RSGCore = exports['rsg-core']:GetCoreObject()
local chestObject = nil

----------------------------------------------
-- text to screen
----------------------------------------------
local DrawText3Ds = function(x, y, z, text)
    local _, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)
    local str = CreateVarString(10, "LITERAL_STRING", text, Citizen.ResultAsLong())

    SetTextScale(0.35, 0.35)
    SetTextFontForCurrentCommand(1)
    SetTextColor(255, 255, 255, 215)
    SetTextCentre(true)
    DisplayText(str, _x, _y)
end

----------------------------------------------
-- use treasure map (one time use)
----------------------------------------------
RegisterNetEvent('rsg-treasure:client:usetreasuremap', function(item)
    for k,v in pairs(Config.Locations) do
        local TreasureBlip = Citizen.InvokeNative(0x554D9D53F696D002, `BLIP_STYLE_GOLDEN_HAT`, v.coords)
        SetBlipSprite(TreasureBlip,  joaat(Config.TreasureBlip.blipSprite), true)
        SetBlipScale(Config.TreasureBlip.blipScale, 0.2)
        Citizen.InvokeNative(0x9CB1A1623062F402, TreasureBlip, Config.TreasureBlip.blipName)
    end
end)

----------------------------------------------
-- dig up chest animation
----------------------------------------------
local StartAnimation = function(animDict, flags, playbackListName, groundZ, time)
    CreateThread(function()
        local player = PlayerPedId()
        local aCoord = GetEntityCoords(player)
        local pCoord = GetOffsetFromEntityInWorldCoords(player, -10.0, 0.0, 0.0)
        local pRot = GetEntityRotation(player)

        if groundZ then
            local _, ground = GetGroundZAndNormalFor_3dCoord(aCoord.x, aCoord.y, aCoord.z + 10)
            aCoord = {x = aCoord.x, y = aCoord.y, z = ground}
        end

        local animScene = Citizen.InvokeNative(0x1FCA98E33C1437B3, animDict, flags, playbackListName, 0, 1)

        Citizen.InvokeNative(0x020894BF17A02EF2, animScene, aCoord.x, aCoord.y, aCoord.z, pRot.x, pRot.y, pRot.z, 2)
        Citizen.InvokeNative(0x8B720AD451CA2AB3, animScene, "player", player, 0)

        local modelhash = `p_strongbox_muddy_01x`

        RequestModel(modelhash)

        while not HasModelLoaded(modelhash) do
            Wait(10)
        end

        chestObject = CreateObjectNoOffset(modelhash, pCoord.x, pCoord.y, pCoord.z, true, true, true)

        Citizen.InvokeNative(0x8B720AD451CA2AB3, animScene, "CHEST", chestObject, 0)
        Citizen.InvokeNative(0xAF068580194D9DC7, animScene)

        Wait(1000)

        Citizen.InvokeNative(0xF4D94AF761768700, animScene)

        if time then
            Wait(time)
        else
            Wait(10000)
        end

        Citizen.InvokeNative(0x84EEDB2C6E650000, animScene)

        DeleteObject(chestObject)
        SetObjectAsNoLongerNeeded(chestObject)
    end)
end

----------------------------------------------
-- detector sound and animation
----------------------------------------------
CreateThread(function()
    while true do
        Wait(1)
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        local isonmount = IsPedOnMount(ped)
        local weaponhash = Citizen.InvokeNative(0x8425C5F057012DAB, ped)
        
        if weaponhash == joaat('weapon_kit_metal_detector') and not isonmount then
            for _, v in pairs(Config.Locations) do
                local dist = #(pos - v.coords)
                if dist < 1 then
                    Citizen.InvokeNative(0x437C08DB4FEBE2BD, ped, "MetalDetectorDetectionValue", 1.0, -1)
                    TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 10, 'metaldetector', Config.DetectorVolume)
                    Wait(500)
                elseif dist < 2 then
                    Citizen.InvokeNative(0x437C08DB4FEBE2BD, ped, "MetalDetectorDetectionValue", 0.9, -1)
                    TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 10, 'metaldetector', Config.DetectorVolume)
                    Wait(600)
                elseif dist < 3 then
                    Citizen.InvokeNative(0x437C08DB4FEBE2BD, ped, "MetalDetectorDetectionValue", 0.8, -1)
                    TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 10, 'metaldetector', Config.DetectorVolume)
                    Wait(700)
                elseif dist < 4 then
                    Citizen.InvokeNative(0x437C08DB4FEBE2BD, ped, "MetalDetectorDetectionValue", 0.7, -1)
                    TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 10, 'metaldetector', Config.DetectorVolume)
                    Wait(800)
                elseif dist < 5 then
                    Citizen.InvokeNative(0x437C08DB4FEBE2BD, ped, "MetalDetectorDetectionValue", 0.6, -1)
                    TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 10, 'metaldetector', Config.DetectorVolume)
                    Wait(900)
                elseif dist < 6 then
                    Citizen.InvokeNative(0x437C08DB4FEBE2BD, ped, "MetalDetectorDetectionValue", 0.5, -1)
                    TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 10, 'metaldetector', Config.DetectorVolume)
                    Wait(1100)
                elseif dist < 7 then
                    Citizen.InvokeNative(0x437C08DB4FEBE2BD, ped, "MetalDetectorDetectionValue", 0.4, -1)
                    TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 10, 'metaldetector', Config.DetectorVolume)
                    Wait(1200)
                elseif dist < 8 then
                    Citizen.InvokeNative(0x437C08DB4FEBE2BD, ped, "MetalDetectorDetectionValue", 0.3, -1)
                    TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 10, 'metaldetector', Config.DetectorVolume)
                    Wait(1300)
                elseif dist < 9 then
                    Citizen.InvokeNative(0x437C08DB4FEBE2BD, ped, "MetalDetectorDetectionValue", 0.2, -1)
                    TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 10, 'metaldetector', Config.DetectorVolume)
                    Wait(1400)
                elseif dist < 10 then
                    Citizen.InvokeNative(0x437C08DB4FEBE2BD, ped, "MetalDetectorDetectionValue", 0.1, -1)
                    TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 10, 'metaldetector', Config.DetectorVolume)
                    Wait(1500)
                end
                
            end
        end
        
    end
end)

----------------------------------------------
-- show dig message
----------------------------------------------
CreateThread(function()
    while true do
        Wait(1)
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        local isonmount = IsPedOnMount(ped)
        local weaponhash = Citizen.InvokeNative(0x8425C5F057012DAB, ped)
        if weaponhash == joaat('weapon_kit_metal_detector') and not isonmount then
            for _, v in pairs(Config.Locations) do
                local dist = #(pos - v.coords)
                if dist < 1 then
                    DrawText3Ds(v.coords.x, v.coords.y, v.coords.z + 1.0, "[J] Dig for Treasure")
                    if IsControlJustReleased(0, RSGCore.Shared.Keybinds['J']) then
                        SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
                        Citizen.InvokeNative(0x437C08DB4FEBE2BD, ped, "MetalDetectorDetectionValue", 0.0, -1)
                        TriggerEvent('rsg-treasure:clent:digging', v.coords, v.name)
                    end  
                end
            end
        end
    end
end)

----------------------------------------------
-- dig for treasure
----------------------------------------------
RegisterNetEvent('rsg-treasure:clent:digging', function(coords, name)
    local treasure = name
    local hasItem = RSGCore.Functions.HasItem('shovel', 1)
    if hasItem then
        local randomNumber = math.random(1, 100)
        if randomNumber > 90 then
            TriggerServerEvent('rsg-treasure:server:removeitem', 'shovel', 1)
            TriggerEvent('inventory:client:ItemBox', RSGCore.Shared.Items['shovel'], 'remove')
            lib.notify({ title = 'Shovel Broken', description = 'your shovel is broken', type = 'error', duration = 5000 })
        else
            RSGCore.Functions.TriggerCallback('rsg-treasure:server:gettreasurestate', function(result)
                if result == 0 then
                    -- veg modifiy
                    local veg_modifier_sphere = 0
                    if veg_modifier_sphere == nil or veg_modifier_sphere == 0 then
                        local veg_radius = 2.0
                        local veg_Flags =  1 + 2 + 4 + 8 + 16 + 32 + 64 + 128 + 256
                        local veg_ModType = 1
                        veg_modifier_sphere = Citizen.InvokeNative(0xFA50F79257745E74, coords.x, coords.y, coords.z, veg_radius, veg_ModType, veg_Flags, 0)
                    else
                        Citizen.InvokeNative(0x9CF1836C03FB67A2, Citizen.PointerValueIntInitialized(veg_modifier_sphere), 0)
                        veg_modifier_sphere = 0
                    end
                    StartAnimation('script@mech@treasure_hunting@chest', 0, 'PBL_CHEST_01', true, 10000)
                    Wait(10000)
                    TriggerServerEvent('rsg-treasure:server:givereward', treasure)
                    TriggerServerEvent('rsg-treasure:server:setlooted', treasure)
                else
                    lib.notify({ title = 'Already Looted', description = 'treasure chest has already been looted', type = 'error', duration = 7000 })
                end
            end, treasure)
        end
    else
        lib.notify({ title = 'No Shovel', description = 'you don\'t have a shovel!', type = 'error', duration = 5000 })
    end
end)
