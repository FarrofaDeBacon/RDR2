local RSGCore = exports['rsg-core']:GetCoreObject()

-- =======================================================
-- SISTEMA DE MARCAÇÕES E BLIPS
-- =======================================================

local activeBlips = {} -- Guarda os blips criados { [id] = blipHandle }

local function CreateMapMarker(marker)
    -- blip genérico base do RDR2 (1664425300)
    local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, marker.x, marker.y, marker.z)
    
    -- Muda a sprite e o nome do blip
    if type(blip) == "number" then
        if marker.icon and marker.icon ~= "" then
            local hash = joaat(marker.icon)
            SetBlipSprite(blip, hash, true)
            Citizen.InvokeNative(0x74F74DB120614488, blip, hash, true) -- Fallback
        end
        
        Citizen.InvokeNative(0x9CB1A1623062F402, blip, marker.name)
    end
    
    return blip
end

local function RemoveAllBlips()
    for _, blip in pairs(activeBlips) do
        RemoveBlip(blip)
    end
    activeBlips = {}
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        RemoveAllBlips()
    end
end)

local function LoadPlayerMarkers()
    RemoveAllBlips()
    local markers = lib.callback.await('fdb-mapmenu:server:getMarkers', false)
    
    if markers then
        for _, marker in pairs(markers) do
            local blip = CreateMapMarker(marker)
            if blip then
                Citizen.InvokeNative(0xD38744167B2FA257, blip, 0.4) -- SetBlipScale
                activeBlips[marker.id] = blip
            end
        end
    end
end

-- Evento para atualizar os blips quando algo é adicionado/removido
RegisterNetEvent('fdb-mapmenu:client:refreshMarkers', function()
    LoadPlayerMarkers()
end)

-- =======================================================
-- MENUS UI (ox_lib)
-- =======================================================

-- Menu Principal do Mapa (Gerenciamento)
-- Menu Principal do Mapa (Gerenciamento)
local function OpenMapMenu()
    local markers = lib.callback.await('fdb-mapmenu:server:getMarkers', false)
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openNotebook",
        markers = markers or {}
    })
end

-- =======================================================
-- INICIALIZAÇÃO E COMANDOS
-- =======================================================

-- Permite abrir através de um item do servidor ou export (ex: se o server usar o item 'map')
RegisterNetEvent('fdb-mapmenu:client:OpenMapMenu', function()
    OpenMapMenu()
end)

-- Comando alternativo caso o item do inventário falhe
RegisterCommand('anotacoes', function()
    local hasMap = lib.callback.await('fdb-mapmenu:server:hasMapItem', false)
    if hasMap then
        OpenMapMenu()
    else
        lib.notify({ title = 'Você não possui um mapa equipado.', type = 'error' })
    end
end)



RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    Wait(1000)
    LoadPlayerMarkers()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Wait(1000)
        LoadPlayerMarkers()
    end
end)

CreateThread(function()
    local wasWaypointActive = false
    
    while true do
        Wait(100)
        
        local isWaypointActive = Citizen.InvokeNative(0x202B1BBFC6AB5EE4) -- IS_WAYPOINT_ACTIVE
        
        if isWaypointActive and not wasWaypointActive then
            wasWaypointActive = true
            
            -- O jogador acabou de colocar um Waypoint!
            local coords = GetWaypointCoords()
            if type(coords) ~= "vector3" then
                coords = Citizen.InvokeNative(0x29B30D07C3F7873B, Citizen.ResultAsVector())
            end
            
            -- Extrai coordenadas com segurança para evitar crash no server ou no ox_lib
            local cx, cy, cz = 0.0, 0.0, 0.0
            if type(coords) == "vector3" then
                cx, cy, cz = coords.x, coords.y, coords.z
            elseif type(coords) == "table" and coords.x then
                cx, cy, cz = coords.x, coords.y, coords.z
            end
            
            -- Se por acaso a nativa retornar 0, usa a coord do player como fallback temporario
            if cx == 0.0 and cy == 0.0 then
                local pCoords = GetEntityCoords(PlayerPedId())
                cx, cy, cz = pCoords.x, pCoords.y, pCoords.z
            end
            
            local safeCoords = { x = cx, y = cy, z = cz }
            
            -- Apaga o waypoint imediatamente
            SetWaypointOff()
            wasWaypointActive = false
            
            -- Verifica se ele tem lápis
            local hasPencil = lib.callback.await('fdb-mapmenu:server:hasPencilItem', false)
            
            if not hasPencil then
                lib.notify({ title = 'Você marcou o mapa, mas não tem um Lápis para anotar!', type = 'error' })
            else
                -- Mostra a nova UI de Pergaminho
                SetNuiFocus(true, true)
                SendNUIMessage({
                    action = "openMenu",
                    coords = safeCoords
                })
            end
        end
    end
end)

-- =======================================================
-- NUI CALLBACKS
-- =======================================================

-- NUI Callbacks
RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('saveMarker', function(data, cb)
    TriggerServerEvent('fdb-mapmenu:server:addMarker', data.name, data.icon, data.coords)
    cb('ok')
end)

RegisterNUICallback('deleteMarker', function(data, cb)
    TriggerServerEvent('fdb-mapmenu:server:removeMarker', data.id)
    cb('ok')
end)

RegisterNUICallback('editMarker', function(data, cb)
    TriggerServerEvent('fdb-mapmenu:server:editMarker', data.id, data.name, data.icon)
    cb('ok')
end)

RegisterNUICallback('requestMarkers', function(data, cb)
    local markers = lib.callback.await('fdb-mapmenu:server:getMarkers', false)
    cb(markers or {})
end)
