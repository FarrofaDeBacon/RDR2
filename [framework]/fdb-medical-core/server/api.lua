-- ============================================================
-- fdb-medical | server/api.lua
-- Exports públicas para consumo por outros recursos
-- ============================================================

--- Único ponto de entrada para QUALQUER dano no servidor.
--- @param source number ID do jogador que recebeu o dano
--- @param damageType string Enum DamageType (Gunshot, Melee, Fall, Poison, Illness, Cold, Heat...)
--- @param bodyPart string|nil Enum BodyPart (Head, Torso, Arms, Legs) ou nil para sistêmico
--- @param amount number Intensidade do dano (positivo = dano, negativo = cura)
exports('ApplyDamage', function(source, damageType, bodyPart, amount)
    local caller = GetInvokingResource() or 'unknown'
    ProcessDamage(source, damageType, bodyPart, amount, caller)
end)

--- Aplica tratamento a um ferimento ou estado do jogador
--- @param source number ID do jogador
--- @param woundId string|nil ID do ferimento
--- @param treatmentType string Tipo de tratamento ('bandage', 'antidote', 'medicine')
--- @param itemUsed string|nil Nome do item consumível
exports('TreatWound', function(source, woundId, treatmentType, itemUsed)
    ProcessTreatment(source, woundId, treatmentType, itemUsed)
end)

--- Consulta somente-leitura dos vitais fisiológicos atuais do jogador
--- @param source number ID do jogador
--- @return table Tabela contendo health, pulse, pain, bleeding, consciousness
exports('GetVitals', function(source)
    return GetPlayerVitals(source)
end)
