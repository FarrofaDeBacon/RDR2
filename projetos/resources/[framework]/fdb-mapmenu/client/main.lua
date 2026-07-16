local RSGCore = exports['rsg-core']:GetCoreObject()

-- Abre o mapa nativo do jogo
local function OpenNativeMapWithAnimation()
    print("[fdb-mapmenu] Abrindo mapa nativo...")
    -- Usa a hash correta para o menu de pausa/mapa
    Citizen.InvokeNative(0xEF01D36B9C9D0C7B, GetHashKey("FE_MENU_VERSION_MP_PAUSE"), true, -1)
end

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

-- Menu Principal do Mapa
local function OpenMapMenu()
    lib.registerContext({
        id = 'map_main_menu',
        title = 'Mapa e Anotações',
        options = {
            {
                title = 'Abrir Mapa',
                description = 'Desdobrar e olhar o mapa nativo',
                icon = 'map',
                onSelect = function()
                    OpenNativeMapWithAnimation()
                end,
            },
            {
                title = 'Nova Anotação',
                description = 'Marcar sua localização atual no mapa',
                icon = 'pencil',
                onSelect = function()
                    -- Verifica se tem o lápis
                    local hasPencil = lib.callback.await('fdb-mapmenu:server:hasPencilItem', false)
                    if not hasPencil then
                        lib.notify({ title = 'Você não tem um lápis para anotar!', type = 'error' })
                        return
                    end
                    
                    -- Abre formulário de anotação
                    local input = lib.inputDialog('Nova Anotação', {
                        {type = 'input', label = 'Nome do Local', description = 'Ex: Ponto de Caça, Esconderijo', required = true},
                        {type = 'select', label = 'Ícone', required = true, options = {
                            {value = 'blip_ambient_camp', label = 'Acampamento'},
                            {value = 'blip_animal_deer', label = 'Caça'},
                            {value = 'blip_shop_grocery', label = 'Provisões'},
                            {value = 'blip_shop_gunsmith', label = 'Armas/Perigo'},
                            {value = 'blip_defend_coach', label = 'Alvo/Destino'}
                        }}
                    })
                    
                    if not input then return end
                    
                    local name = input[1]
                    local icon = input[2]
                    local coords = GetEntityCoords(PlayerPedId())
                    
                    TriggerServerEvent('fdb-mapmenu:server:addMarker', name, icon, coords)
                end,
            },
            {
                title = 'Minhas Anotações',
                description = 'Gerenciar as anotações feitas',
                icon = 'list',
                onSelect = function()
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
                        menu = 'map_main_menu',
                        options = menuOptions
                    })
                    
                    lib.showContext('map_markers_list')
                end,
            }
        }
    })
    
    lib.showContext('map_main_menu')
end

-- =======================================================
-- INICIALIZAÇÃO E COMANDOS
-- =======================================================

-- Permite abrir através de um item do servidor ou export (ex: se o server usar o item 'map')
RegisterNetEvent('fdb-mapmenu:client:OpenMapMenu', function()
    OpenMapMenu()
end)

-- Thread de Interceptação da Tecla M (INPUT_MAP)
CreateThread(function()
    -- Carrega os marcadores ao entrar no jogo
    Wait(2000)
    LoadPlayerMarkers()
    
    while true do
        Wait(0)
        DisableControlAction(0, 0xE31C6A41, true) -- INPUT_MAP (M)

        if IsDisabledControlJustReleased(0, 0xE31C6A41) then
            local hasMap = lib.callback.await('fdb-mapmenu:server:hasMapItem', false)
            if hasMap then
                OpenMapMenu()
            else
                lib.notify({ title = 'Você não possui um mapa equipado.', type = 'error' })
            end
        end
    end
end)


