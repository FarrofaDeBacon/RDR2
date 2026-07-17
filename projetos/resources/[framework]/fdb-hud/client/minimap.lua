-- ============================================================
-- fdb-hud | client/minimap.lua
-- Controle do minimapa via Config.Minimap.enabled + posse + equipado
-- ============================================================

local hasMapItem = not Config.Minimap.requireItem
local isMapEquipped = false

RegisterNetEvent('fdb-hud:client:itemGatedUpdate', function(data)
    hasMapItem = data.map
end)

RegisterNetEvent('fdb-hud:client:equipUpdate', function(data)
    if data.map ~= nil then
        isMapEquipped = data.map
    end
end)

RegisterNetEvent('fdb-hud:client:openMapMenu', function()
    lib.registerContext({
        id = 'map_action_menu',
        title = 'Ações do Mapa',
        options = {
            {
                title = 'Visualizar Mapa',
                description = 'Abre o mapa gigante nativo.',
                icon = 'map',
                onSelect = function()
                    ActivateFrontendMenu(joaat("MAP"), false, 1)
                end
            },
            {
                title = isMapEquipped and 'Guardar Minimapa' or 'Equipar Minimapa',
                description = 'Liga ou desliga a bússola/radar na sua tela.',
                icon = isMapEquipped and 'eye-slash' or 'eye',
                onSelect = function()
                    TriggerServerEvent('fdb-hud:server:toggleMinimap')
                end
            },
            {
                title = 'Mapa de Anotações',
                description = 'Abre o mapa de papel customizado.',
                icon = 'pen',
                onSelect = function()
                    TriggerEvent('fdb-mapmenu:client:OpenMapMenu')
                end
            }
        }
    })
    lib.showContext('map_action_menu')
end)

local function GetMinimapAnchor()
    local safezone = 1.0
    if type(GetSafeZoneSize) == "function" then
        safezone = GetSafeZoneSize()
    end
    
    local safezone_x = 1.0 / 20.0
    local safezone_y = 1.0 / 20.0
    
    local success, aspect_ratio = pcall(GetAspectRatio, false)
    if not success or not aspect_ratio then
        aspect_ratio = 16.0 / 9.0 -- Fallback seguro
    end
    
    local left_x = safezone_x * ((math.abs(safezone - 1.0)) * 10)
    local bottom_y = 1.0 - (safezone_y * ((math.abs(safezone - 1.0)) * 10))
    local width = 1.0 / (4 * aspect_ratio)
    local height = 1.0 / 5.674
    
    -- O RedM tem o radar circular, mas a lógica da Rockstar para o safezone é similar ao GTA 5
    -- O centro do radar é aproximadamente no meio dessa bounding box
    local center_x = left_x + (width / 2)
    local center_y = bottom_y - (height / 2)
    
    -- Convertemos para Viewport Units (vw / vh) para o CSS
    return {
        leftVw = center_x * 100,
        bottomVh = (1.0 - center_y) * 100
    }
end

CreateThread(function()
    while true do
        Wait(500)
        if Config.Minimap.enabled and hasMapItem and isMapEquipped then
            DisplayRadar(true)
            Citizen.InvokeNative(0xDE1A30F38D0DEE5C, true)
            SetMinimapType(1)
            
            local success, anchor = pcall(GetMinimapAnchor)
            if not success then
                print("Erro ao calcular o minimap anchor: " .. tostring(anchor))
                anchor = nil
            end
            
            SendNUIMessage({
                action = 'updateMinimap',
                data = { visible = true, anchor = anchor }
            })
        else
            DisplayRadar(false)
            Citizen.InvokeNative(0xDE1A30F38D0DEE5C, false)
            SetMinimapType(0)
            SendNUIMessage({
                action = 'updateMinimap',
                data = { visible = false }
            })
        end
    end
end)

-- Loop de checagem de estado molhado (2s)
CreateThread(function()
    while true do
        Wait(2000)
        if isLoggedIn and isMapEquipped then
            local ped = PlayerPedId()
            local isSwimming = IsPedSwimming(ped)
            local isRaining = GetRainLevel() > 0.3
            if isSwimming or isRaining then
                TriggerServerEvent('fdb-hud:server:checkWet', isSwimming, isRaining)
            end
        end
    end
end)
