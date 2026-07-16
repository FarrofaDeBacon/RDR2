local RSGCore = exports['rsg-core']:GetCoreObject()

-- =======================================================
-- SISTEMA DE MARCAÇÕES E BLIPS
-- =======================================================

local activeBlips = {} -- Guarda os blips criados { [id] = blipHandle }

local function RemoveAllBlips()
    for _, blip in pairs(activeBlips) do
        RemoveBlip(blip)
    end
    activeBlips = {}
end

local function LoadPlayerMarkers()
    RemoveAllBlips()
    local markers = lib.callback.await('fdb-mapmenu:server:getMarkers', false)
    
    if markers then
        for _, marker in pairs(markers) do
            -- Cria o blip nativo do RDR2
            local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, marker.x, marker.y, marker.z)
            
            -- Se tiver ícone específico, a gente aplica usando a nativa exata do RedM
            if marker.icon and marker.icon ~= "" then
                Citizen.InvokeNative(0x74F74DB120614488, blip, GetHashKey(marker.icon)) -- SET_BLIP_SPRITE
            end
            
            -- Removemos a escala de 0.2 porque no RedM isso deixa o ícone invisível a olho nu!
            Citizen.InvokeNative(0x9CB1A1623062F402, blip, marker.name) -- Seta o nome
            
            activeBlips[marker.id] = blip
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
local function OpenMapMenu()
    local markers = lib.callback.await('fdb-mapmenu:server:getMarkers', false)
    local menuOptions = {}
    
    if markers and #markers > 0 then
        for _, marker in pairs(markers) do
            table.insert(menuOptions, {
                title = marker.name,
                description = 'Clique para deletar esta marcação.',
                icon = 'map-pin',
                onSelect = function()
                    local confirm = lib.alertDialog({
                        header = 'Deletar Marcação?',
                        content = 'Tem certeza que deseja rasgar esta anotação do seu mapa?',
                        centered = true,
                        cancel = true
                    })
                    if confirm == 'confirm' then
                        TriggerServerEvent('fdb-mapmenu:server:removeMarker', marker.id)
                    else
                        lib.showContext('map_markers_list')
                    end
                end
            })
        end
    else
        table.insert(menuOptions, {
            title = 'Nenhuma anotação feita',
            disabled = true
        })
    end
    
    lib.registerContext({
        id = 'map_markers_list',
        title = 'Minhas Anotações',
        options = menuOptions
    })
    
    lib.showContext('map_markers_list')
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

RegisterCommand('checkwaypoint', function()
    local hasWaypoint = Citizen.InvokeNative(0x202B1BBFC6AB5EE4)
    print("[DEBUG] IsWaypointActive:", tostring(hasWaypoint))
    
    local blip8 = GetFirstBlipInfoId(8)
    print("[DEBUG] GetFirstBlipInfoId(8):", tostring(blip8))
    
    local coords = GetWaypointCoords()
    print("[DEBUG] GetWaypointCoords:", tostring(coords))
    
    local natCoord = Citizen.InvokeNative(0x29B30D07C3F7873B, Citizen.ResultAsVector())
    print("[DEBUG] Native Coords:", tostring(natCoord))
end)

CreateThread(function()
    -- Carrega os marcadores ao entrar no jogo
    Wait(2000)
    LoadPlayerMarkers()
    
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
                -- Mostra a caixinha diretamente (ela vai aparecer por cima do mapa)
                local input = lib.inputDialog('Nova Anotação no Mapa', {
                    {type = 'input', label = 'Nome da Anotação', description = 'Ex: Ponto de Caça, Esconderijo', required = true},
                    {type = 'select', label = 'Símbolo', required = true, options = {
                        {value = 'blip_ambient_camp', label = 'Acampamento'},
                        {value = 'blip_animal_deer', label = 'Caça'},
                        {value = 'blip_shop_grocery', label = 'Provisões'},
                        {value = 'blip_shop_gunsmith', label = 'Armas/Perigo'},
                        {value = 'blip_defend_coach', label = 'Alvo/Destino'}
                    }}
                })
                
                if input then
                    TriggerServerEvent('fdb-mapmenu:server:addMarker', input[1], input[2], safeCoords)
                end
            end
        end
    end
end)


