-- ============================================================
-- fdb-medical | server/damage.lua
-- ÚNICO ponto de escrita para dano e saúde no servidor
-- ============================================================

local RSGCore = exports['rsg-core']:GetCoreObject()

--- Aplica dano ou alteração de vida server-side no ped de um jogador
--- @param src number ID do jogador
--- @param damageType string Tipo de dano (DamageType enum)
--- @param bodyPart string|nil Parte do corpo atingida (BodyPart enum)
--- @param amount number Quantidade de dano (positivo para dano, negativo para cura)
--- @param originResource string|nil Nome do recurso que originou o dano
function ProcessDamage(src, damageType, bodyPart, amount, originResource)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end

    local vitals = GetPlayerVitals(src)
    originResource = originResource or GetInvokingResource() or 'unknown'
    bodyPart = bodyPart or BodyPart.Torso

    -- Log de auditoria server-side
    print(string.format(
        locale('log_damage_applied'),
        tostring(src), tostring(originResource), tostring(damageType), tostring(bodyPart), tostring(amount)
    ))

    -- Ajuste de Saúde
    local currentHp = GetEntityHealth(ped)
    local maxHp = GetEntityMaxHealth(ped)
    local newHp = math.max(0, math.min(maxHp, math.floor(currentHp - amount)))

    -- Aplica nativamente via Server (Único local do projeto!)
    SetEntityHealth(ped, newHp)

    -- Atualiza os vitais fisiológicos
    vitals.health = newHp
    if amount > 0 then
        -- Dano aumenta dor e pulso
        vitals.pain = math.min(100, vitals.pain + math.floor(amount * 0.5))
        vitals.pulse = math.min(Config.Vitals.MaxPulse, vitals.pulse + math.floor(amount * 0.3))
        if damageType == DamageType.Gunshot or damageType == DamageType.Melee or damageType == DamageType.Animal then
            vitals.bleeding = math.min(100, vitals.bleeding + math.floor(amount * 0.4))
            RegisterWound(src, bodyPart, damageType, amount)
        end
    else
        -- Cura reduz dor
        vitals.pain = math.max(0, vitals.pain + math.floor(amount * 0.5))
        vitals.bleeding = math.max(0, vitals.bleeding + math.floor(amount * 0.8))
    end

    SyncVitalsToStatebag(src)
end

--- Aplica um tratamento a um ferimento do jogador
--- @param src number ID do jogador
--- @param woundId string|nil ID ou tipo do ferimento
--- @param treatmentType string Tipo do tratamento (bandagem, antídoto, cirurgia)
--- @param itemUsed string Nome do item usado
function ProcessTreatment(src, woundId, treatmentType, itemUsed)
    local vitals = GetPlayerVitals(src)
    print(string.format(
        locale('log_treatment_applied'),
        tostring(src), tostring(itemUsed or 'none'), tostring(treatmentType)
    ))

    if treatmentType == 'bandage' or treatmentType == 'heal' then
        vitals.bleeding = 0
        vitals.pain = math.max(0, vitals.pain - 30)
    elseif treatmentType == 'antidote' then
        vitals.pain = math.max(0, vitals.pain - 20)
    end

    SyncVitalsToStatebag(src)
end
