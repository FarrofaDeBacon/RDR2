-- ============================================================
-- fdb-hud | client/hidenatives.lua
-- Oculta os cores/icones de status nativos do RedM
-- ============================================================

CreateThread(function()
    if Config.Elements.health and Config.Elements.health.enabled then
        Citizen.InvokeNative(0xC116E6DF68DCE667, 4, 2) -- ICON_HEALTH
        Citizen.InvokeNative(0xC116E6DF68DCE667, 5, 2) -- ICON_HEALTH_CORE
    end
    if Config.Elements.stamina and Config.Elements.stamina.enabled then
        Citizen.InvokeNative(0xC116E6DF68DCE667, 0, 2) -- ICON_STAMINA
        Citizen.InvokeNative(0xC116E6DF68DCE667, 1, 2) -- ICON_STAMINA_CORE
    end
    if Config.Elements.deadEye and Config.Elements.deadEye.enabled then
        Citizen.InvokeNative(0xC116E6DF68DCE667, 2, 2) -- ICON_DEADEYE
        Citizen.InvokeNative(0xC116E6DF68DCE667, 3, 2) -- ICON_DEADEYE_CORE
    end
    -- cavalo: sempre escondido por enquanto (sem toggle individual ainda)
    Citizen.InvokeNative(0xC116E6DF68DCE667, 6, 2)  -- ICON_HORSE_HEALTH
    Citizen.InvokeNative(0xC116E6DF68DCE667, 7, 2)  -- ICON_HORSE_HEALTH_CORE
    Citizen.InvokeNative(0xC116E6DF68DCE667, 8, 2)  -- ICON_HORSE_STAMINA
    Citizen.InvokeNative(0xC116E6DF68DCE667, 9, 2)  -- ICON_HORSE_STAMINA_CORE
    Citizen.InvokeNative(0xC116E6DF68DCE667, 10, 2) -- ICON_HORSE_COURAGE
    Citizen.InvokeNative(0xC116E6DF68DCE667, 11, 2) -- ICON_HORSE_COURAGE_CORE
end)
