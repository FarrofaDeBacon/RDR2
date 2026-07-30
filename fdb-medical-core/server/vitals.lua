-- ============================================================
-- fdb-medical | server/vitals.lua
-- Tabela de estado de vitais server-authoritative por jogador
-- ============================================================

PlayerVitals = {}

--- Retorna a tabela de vitais de um jogador (ou inicializa se não existir)
--- @param src number Player ID
--- @return table
function GetPlayerVitals(src)
    if not PlayerVitals[src] then
        PlayerVitals[src] = {
            health = Config.Vitals.MaxHealth,
            pulse = Config.Vitals.DefaultPulse,
            pain = Config.Vitals.DefaultPain,
            bleeding = Config.Vitals.DefaultBleeding,
            consciousness = Config.Vitals.DefaultConsciousness,
            wounds = {}
        }
    end
    return PlayerVitals[src]
end

--- Atualiza a Statebag `medical` do ped do jogador e a metadata oficial
--- @param src number
function SyncVitalsToStatebag(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end

    local vitals = GetPlayerVitals(src)
    Entity(ped).state:set('medical', {
        health = vitals.health,
        pulse = vitals.pulse,
        pain = vitals.pain,
        bleeding = vitals.bleeding,
        consciousness = vitals.consciousness
    }, true)
    
    -- Sincroniza metadata oficial do framework para compatibilidade com rsg-spawn, HUDs, etc.
    local Player = RSGCore.Functions.GetPlayer(src)
    if Player then
        Player.Functions.SetMetaData('health', vitals.health)
    end
end

--- Limpeza ao desconectar
AddEventHandler('playerDropped', function()
    local src = source
    PlayerVitals[src] = nil
end)
