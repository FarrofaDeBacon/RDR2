-- ============================================================
-- fdb-hud | c/nui.lua
-- Callbacks NUI e tecla de menu
-- ============================================================

-- Fecha o menu de config ao pressionar ESC
RegisterNUICallback('closeMenu', function(_, cb)
    SetNuiFocus(false, false)
    SendNUI('setEditMode', false)
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

-- Modo edição para reposicionar a bússola/radar
RegisterCommand('hudedit', function()
    SetNuiFocus(true, true)
    SendNUI('setEditMode', true)
end, false)

RegisterNUICallback('saveMaskSettings', function(data, cb)
    local msg = string.format('Size: %s | Left: %s | Bottom: %s | Thickness: %s', data.size, data.left, data.bottom, data.thickness)
    print('[HUD Edit] Novos valores para config.lua: ' .. msg)
    TriggerEvent('chat:addMessage', {
        color = {255, 255, 255},
        multiline = true,
        args = {"Sistema", "Copiado para o F8: " .. msg}
    })
    cb('ok')
end)
