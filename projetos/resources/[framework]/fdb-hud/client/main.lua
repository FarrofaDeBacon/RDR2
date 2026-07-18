-- ============================================================
-- fdb-hud | client/main.lua
-- Inicializacao e loop principal do client
-- ============================================================

local RSGCore = exports['rsg-core']:GetCoreObject()
PlayerData = {}
isLoggedIn = false
local nuiReady   = false


-- -------------------------------------------------------
-- Helpers
-- -------------------------------------------------------
function SendNUI(action, data)
    if not nuiReady then return end
    SendNUIMessage({ action = action, data = data })
end

local function InitNUI()
    if not nuiReady then return end

    -- Busca do servidor: elementos permitidos e layout salvo
    local allowedElements = lib.callback.await('fdb-hud:server:getConfig', false)
    local savedLayout     = lib.callback.await('fdb-hud:server:getLayout', false)

    -- Envia tudo ao NUI numa unica mensagem init
    -- Config.Minimap nunca e incluido aqui
    SendNUIMessage({ action = 'init', data = {
        allowed    = allowedElements,
        visibility = savedLayout and savedLayout.visibility or nil,
        job        = PlayerData.job,
    }})
end

-- -------------------------------------------------------
-- Player loaded / logout
-- -------------------------------------------------------
AddEventHandler('RSGCore:Client:OnPlayerLoaded', function()
    PlayerData = RSGCore.Functions.GetPlayerData()
    isLoggedIn = true
    InitNUI()
    SendNUI('showHud', true)
end)

AddEventHandler('RSGCore:Client:OnPlayerLogout', function()
    PlayerData  = {}
    isLoggedIn  = false
    SendNUI('showHud', false)
end)

AddEventHandler('RSGCore:Client:OnJobUpdate', function(job)
    PlayerData.job = job
end)

RegisterNetEvent('RSGCore:Player:SetPlayerData', function(val)
    PlayerData = val
end)

-- -------------------------------------------------------
-- NUI ready callback (enviado pela UI ao montar)
-- -------------------------------------------------------
RegisterNUICallback('hudReady', function(_, cb)
    nuiReady = true
    InitNUI()
    if isLoggedIn then
        SendNUI('showHud', true)
    end
    cb('ok')
end)

-- -------------------------------------------------------
-- Recurso inicia com jogador ja logado (restart)
-- -------------------------------------------------------
AddEventHandler('onResourceStart', function(res)
    if GetCurrentResourceName() ~= res then return end
    if LocalPlayer.state.isLoggedIn then
        PlayerData = RSGCore.Functions.GetPlayerData()
        isLoggedIn = true
        InitNUI()
        SendNUI('showHud', true)
    end
end)
local inEditMode = false

RegisterCommand('hudedit', function()
    inEditMode = not inEditMode
    SetNuiFocus(inEditMode, inEditMode)
    SendNUI('setEditMode', inEditMode)
end)

RegisterNUICallback('closeEditMode', function(data, cb)
    inEditMode = false
    SetNuiFocus(false, false)
    SendNUI('setEditMode', false)
    cb(1)
end)
