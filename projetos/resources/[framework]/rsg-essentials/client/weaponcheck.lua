local RSGCore = exports['rsg-core']:GetCoreObject()

RegisterNetEvent('rsg-core:client:RemoveWeaponFromTab', function(weaponName)
    local ped = PlayerPedId()
    local weaponHash = GetHashKey(weaponName)
    local weapon = GetPedCurrentHeldWeapon(PlayerPedId())
    local serial = exports['fdb-weapons']:weaponInHands()
    local weaponTypeSlot = Citizen.InvokeNative(0x46F032B8DDF46CDE, weaponHash)

    local weaponInSlot = Citizen.InvokeNative(0xDBC4B552B2AE9A83, ped, weaponTypeSlot)

    if weaponInSlot then
        exports['fdb-weapons']:RemoveWeaponFromPeds(weaponName, serial[weaponHash])
    end

    if weaponHash == weapon then 
        SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
    end
end)

-- Loop anti-cheat removido: o fdb-weapons agora valida a posse síncronamente
-- no servidor (no RemoveItem). Este loop antigo verificava apenas os bolsos
-- do jogador (PlayerData.items) e causava falsos positivos, deletando armas
-- que estavam legitimamente guardadas em mochilas, coldres e carteiras.
