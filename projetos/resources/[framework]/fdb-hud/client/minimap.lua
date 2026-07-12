-- ============================================================
-- fdb-hud | client/minimap.lua
-- Controle do minimapa via Config.Minimap.enabled
-- Leitura EXCLUSIVA de Config.Minimap - nunca exposto via
-- callback, evento ou export ao client/NUI.
-- ============================================================

-- DisplayRadar e a nativa correta para mostrar/ocultar o minimapa
-- no RedM/RDR3. Nao precisa rodar por frame - loop de 1s e
-- suficiente para sobrepor qualquer resource conflitante que
-- tente reativar o radar sem a gente perceber.
-- DisplayRadar(false) nao afeta o mapa cheio nativo (tecla padrao).

CreateThread(function()
    while true do
        Wait(1000)
        DisplayRadar(Config.Minimap.enabled)
    end
end)

