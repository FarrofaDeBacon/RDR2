-- ============================================================
-- fdb-hud | client/minimap.lua
-- Controle do minimapa nativo via Config.Minimap
-- Leitura EXCLUSIVA de Config.Minimap - nunca exposto via
-- callback, evento ou export ao client/NUI.
-- ============================================================

-- HideHudComponentThisFrame NAO e permanente: precisa rodar
-- todo frame (Wait(0)) para manter o minimapa escondido.
-- Quando enabled=true simplesmente nao interfere (Wait longo).
-- O mapa cheio nativo (tecla padrão) nao e afetado por esta
-- nativa - ela oculta apenas o widget de canto da tela.

CreateThread(function()
    while true do
        if not Config.Minimap.enabled then
            HideHudComponentThisFrame(1) -- 1 = HUD_MINIMAP
            Wait(0)
        else
            Wait(1000)
        end
    end
end)
