-- ============================================================
-- fdb-hud | sh/config.lua
-- Configuracao compartilhada entre client e server
-- ============================================================

Config = {}

-- Intervalo (ms) entre cada update de status enviado para a NUI
Config.UpdateInterval = 500

-- Compass
Config.Compass = {
    enabled = true,
    showCardinals = true,   -- N, S, L, O
    showDegrees   = true,
}

-- Status bars visíveis
Config.StatusBars = {
    health   = true,
    stamina  = true,
    dead     = true,    -- Exibe overlay de morte
}

-- HUD de veículo (velocimetro, nitro, etc.)
Config.VehicleHud = {
    enabled     = true,
    speedUnit   = 'kmh',  -- 'kmh' ou 'mph'
}

-- Money HUD
Config.MoneyHud = {
    enabled  = true,
    showCash = true,
    showGold = true,
}

-- Tecla para abrir o menu de configuracao do HUD (padrao: F5)
Config.MenuKey = 'F5'

-- Posicoes padrao dos elementos (podem ser ajustadas pelo jogador via menu)
Config.DefaultLayout = {
    status  = { x = 0.02, y = 0.80 },  -- canto inferior esquerdo
    vehicle = { x = 0.78, y = 0.80 },  -- canto inferior direito
    compass = { x = 0.35, y = 0.02 },  -- topo central
    money   = { x = 0.78, y = 0.02 },  -- topo direito
}
