-- Sistema de Mijar
RegisterNetEvent('fdb-consume:client:pee', function()
    local ped = PlayerPedId()
    local dict = "mech_loco_m@generic@reaction@pee@unarmed@stand"
    
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
    
    -- Inicia
    TaskPlayAnim(ped, dict, "pee_fwd_intro", 8.0, -8.0, -1, 31, 0, false, false, false)
    Wait(2000)
    -- Loop
    TaskPlayAnim(ped, dict, "pee_fwd_loop", 8.0, -8.0, -1, 31, 0, false, false, false)
    
    -- Efeito de partícula (opcional, se funcionar no RedM)
    local coords = GetEntityCoords(ped)
    
    Wait(5000)
    -- Finaliza
    TaskPlayAnim(ped, dict, "pee_fwd_outro", 8.0, -8.0, -1, 31, 0, false, false, false)
    Wait(2000)
    ClearPedTasks(ped)
end)

Citizen.CreateThread(function()
    -- Mijar em qualquer objeto/parede/arvore
    exports.ox_target:addGlobalObject({
        {
            name = 'pee_action_object',
            label = 'Mijar',
            icon = 'fa-solid fa-droplet',
            onSelect = function()
                TriggerEvent('fdb-consume:client:pee')
            end,
            distance = 2.0
        }
    })
    
    -- Mijar em cavalos/veiculos
    exports.ox_target:addGlobalVehicle({
        {
            name = 'pee_action_vehicle',
            label = 'Mijar',
            icon = 'fa-solid fa-droplet',
            onSelect = function()
                TriggerEvent('fdb-consume:client:pee')
            end,
            distance = 2.0
        }
    })
end)
