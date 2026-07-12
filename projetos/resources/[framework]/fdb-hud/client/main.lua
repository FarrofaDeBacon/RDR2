-- ============================================================
-- fdb-hud | c/main.lua
-- Inicializacao e loop principal do client
-- ============================================================

local RSGCore = exports['rsg-core']:GetCoreObject()
local PlayerData = {}
local isLoggedIn = false
local nuiReady = false

-- -------------------------------------------------------
-- Helpers
-- -------------------------------------------------------
local function SendNUI(action, data)
    if not nuiReady then return end
    SendNUIMessage({ action = action, data = data })
end

-- -------------------------------------------------------
-- Player loaded / logout
-- -------------------------------------------------------
AddEventHandler('RSGCore:Client:OnPlayerLoaded', function()
    PlayerData = RSGCore.Functions.GetPlayerData()
    isLoggedIn = true
    SendNUI('setVisible', true)
end)

AddEventHandler('RSGCore:Client:OnPlayerLogout', function()
    PlayerData = {}
    isLoggedIn = false
    SendNUI('setVisible', false)
end)

AddEventHandler('RSGCore:Client:OnJobUpdate', function(job)
    PlayerData.job = job
end)

-- -------------------------------------------------------
-- NUI ready callback (enviado pela UI ao montar)
-- -------------------------------------------------------
RegisterNUICallback('hudReady', function(_, cb)
    nuiReady = true
    -- Envia configuracao inicial
    SendNUIMessage({ action = 'init', data = {
        config = Config,
        job    = PlayerData.job,
    }})
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
    end
end)
