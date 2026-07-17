-- ============================================================
-- fdb-hud | c/nui.lua
-- Callbacks NUI e tecla de menu
-- ============================================================

InEditMode = false

-- Fecha o menu de config ao pressionar ESC
RegisterNUICallback('closeMenu', function(_, cb)
    InEditMode = false
    SetNuiFocus(false, false)
    SendNUI('setEditMode', false)
    cb('ok')
end)

-- Abre o menu de config com a tecla configurada
CreateThread(function()
    while true do
        Wait(0)
        if isLoggedIn and IsControlJustReleased(0, joaat(Config.MenuKey)) then
            InEditMode = true
            SetNuiFocus(true, true)
            SendNUI('openMenu', {})
        end
    end
end)

-- Modo edição para reposicionar a bússola/radar
RegisterCommand('hudedit', function()
    InEditMode = true
    SetNuiFocus(true, true)
    SendNUI('setEditMode', true)
end, false)

RegisterNUICallback('saveMaskPosition', function(data, cb)
    print(string.format('[HUD Edit] Nova posição do anel: left: %s, bottom: %s', data.left, data.bottom))
    TriggerEvent('chat:addMessage', {
        color = {255, 255, 255},
        multiline = true,
        args = {"Sistema", "Copiado para o F8: left: " .. data.left .. " | bottom: " .. data.bottom}
    })
    cb('ok')
end)
