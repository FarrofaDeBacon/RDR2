-- ============================================================
-- fdb-hud | c/nui.lua
-- Callbacks NUI e tecla de menu
-- ============================================================

-- Fecha o menu de config ao pressionar ESC
RegisterNUICallback('closeMenu', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Abre o menu de config com a tecla configurada
CreateThread(function()
    while true do
        Wait(0)
        if isLoggedIn and IsControlJustReleased(0, joaat(Config.MenuKey)) then
            SetNuiFocus(true, true)
            SendNUI('openMenu', {})
        end
    end
end)
