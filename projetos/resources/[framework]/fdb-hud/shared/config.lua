-- ============================================================
-- fdb-hud | shared/config.lua
-- Configuracao compartilhada entre client e server
-- ============================================================

Config = {}

-- -------------------------------------------------------
-- Bloco 1: decisao do SERVIDOR - o que existe no servidor
-- Apenas elementos com enabled=true serao enviados ao client
-- e exibidos na interface.
-- -------------------------------------------------------
Config.Elements = {
    health  = { enabled = true },
    stamina = { enabled = true },
    deadEye = { enabled = true },
    hunger  = { enabled = true },
    thirst  = { enabled = true },
    stress  = { enabled = false }, -- ainda nao implementado
    compass = { enabled = true },
    money   = { enabled = true },
    vehicle = { enabled = true },
}

-- -------------------------------------------------------
-- Bloco 2: minimapa - controle EXCLUSIVO do servidor
-- NUNCA exposto via callback ou evento ao client/NUI.
-- So e lido diretamente por client/minimap.lua.
-- -------------------------------------------------------
Config.Minimap = {
    enabled = true,
}

-- -------------------------------------------------------
-- Configuracoes gerais (usadas internamente pelo client)
-- -------------------------------------------------------

-- Intervalo (ms) entre cada update de status enviado para a NUI
Config.UpdateInterval = 500

-- Unidade de velocidade para o velocimetro
Config.SpeedUnit = 'kmh' -- 'kmh' ou 'mph'

-- Tecla para abrir o menu de configuracao do HUD (padrao: F5)
Config.MenuKey = 'F5'

-- Posicoes padrao dos elementos (podem ser ajustadas pelo jogador via menu)
Config.DefaultLayout = {
    status  = { x = 0.02, y = 0.80 }, -- canto inferior esquerdo
    vehicle = { x = 0.78, y = 0.80 }, -- canto inferior direito
    compass = { x = 0.35, y = 0.02 }, -- topo central
    money   = { x = 0.78, y = 0.02 }, -- topo direito
}

