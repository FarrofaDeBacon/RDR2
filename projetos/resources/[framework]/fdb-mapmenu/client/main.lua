local RSGCore = exports['rsg-core']:GetCoreObject()

-- -------------------------------------------------------
-- Thread de Interceptação da Tecla M (INPUT_MAP)
-- Abre o mapa nativo do jogo (menu de pausa na aba do mapa)
-- -------------------------------------------------------
CreateThread(function()
    while true do
        Wait(0)
        DisableControlAction(0, 0xE31C6A41, true) -- INPUT_MAP (M)

        if IsDisabledControlJustReleased(0, 0xE31C6A41) then
            -- Verifica posse do mapa no servidor
            local hasMap = lib.callback.await('fdb-mapmenu:server:hasMapItem', false)
            if hasMap then
                -- Abre o mapa nativo do jogo (pause menu multiplayer)
                ActivateFrontendMenu(GetHashKey("FE_MENU_VERSION_MP_PAUSE"), false, -1)
            else
                lib.notify({ title = 'Você precisa equipar um mapa para ver isso', type = 'error' })
            end
        end
    end
end)
