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
            
            -- Se tiver ícone específico, a gente aplica
            if marker.icon and marker.icon ~= "" then
                SetBlipSprite(blip, GetHashKey(marker.icon), true)
            end
            
            SetBlipScale(blip, 0.2)
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

CreateThread(function()
    -- Carrega os marcadores ao entrar no jogo
    Wait(2000)
    LoadPlayerMarkers()
    
    local wasMapOpen = false
    
    while true do
        Wait(500)
        
        -- IS_PAUSE_MENU_ACTIVE
        local isMapOpen = Citizen.InvokeNative(0xA7E95B60ED29B88D)
        
        if isMapOpen and not wasMapOpen then
            wasMapOpen = true
        elseif not isMapOpen and wasMapOpen then
            wasMapOpen = false
            
            -- Aguarda o menu de pausa fechar completamente e a tela voltar ao normal
            -- Isso evita que o NUI Focus do ox_lib trave o menu de pausa aberto
            Wait(1500)
            
            -- Mapa acabou de ser fechado. Vamos verificar se ele deixou um waypoint!
            local waypointBlip = GetFirstBlipInfoId(8) -- 8 é o ID do Waypoint vermelho padrão
            
            if DoesBlipExist(waypointBlip) then
                local coords = Citizen.InvokeNative(0xFA7C7F0AADF25D09, waypointBlip, Citizen.ResultAsVector())
                
                -- Apaga o waypoint vermelho imediatamente para ficar invisível e limpo
                SetWaypointOff()
                
                -- Verifica o item Lápis
                local hasPencil = lib.callback.await('fdb-mapmenu:server:hasPencilItem', false)
                if not hasPencil then
                    lib.notify({ title = 'Você tentou fazer uma marcação, mas não tem um Lápis!', type = 'error' })
                else
                    -- Mostra a caixinha de texto (lib.inputDialog)
                    local input = lib.inputDialog('Nova Anotação no Mapa', {
                        {type = 'input', label = 'Nome da Anotação', description = 'Ex: Árvore Antiga, Ouro, etc.', required = true},
                        {type = 'select', label = 'Símbolo', required = true, options = {
                            {value = 'blip_ambient_camp', label = 'Acampamento'},
                            {value = 'blip_animal_deer', label = 'Caça'},
                            {value = 'blip_shop_grocery', label = 'Provisões'},
                            {value = 'blip_shop_gunsmith', label = 'Armas/Perigo'},
                            {value = 'blip_defend_coach', label = 'Alvo/Destino'}
                        }}
                    })
                    
                    if input then
                        local name = input[1]
                        local icon = input[2]
                        -- Envia pro banco de dados
                        TriggerServerEvent('fdb-mapmenu:server:addMarker', name, icon, coords)
                    end
                end
            end
        end
    end
end)


