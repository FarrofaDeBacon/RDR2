-- ============================================================
-- fdb-medical-core | server/wounds.lua
-- Rastreamento de ferimentos por parte do corpo
-- ============================================================

local function GetSeverityTier(value)
    local tiers = Config.Wounds.Severity
    for _, tier in ipairs(tiers) do
        if value >= tier.min and value <= tier.max then
            return tier
        end
    end
    return nil
end

--- Aplica dano físico a uma parte do corpo específica, atualizando severity/bleeding
--- Chamado pelo damage.lua DEPOIS de já ter processado a saúde — nunca escreve vida.
--- @param src number
--- @param bodyPart string Enum BodyPart
--- @param damageType string Enum DamageType
--- @param amount number Intensidade do golpe
function RegisterWound(src, bodyPart, damageType, amount)
    local causesWound = Config.Wounds.WoundCausingTypes[damageType]
    if not causesWound or amount <= 0 then return end

    local vitals = GetPlayerVitals(src)
    vitals.wounds = vitals.wounds or {}
    vitals.wounds[bodyPart] = vitals.wounds[bodyPart] or { severity = 0, bleeding = 0, infected = false, infectionStage = 0, treated = false }

    local wound = vitals.wounds[bodyPart]

    -- Acumula severidade (0-100), golpes repetidos na mesma parte agravam o ferimento
    wound.severity = math.max(0, math.min(100, wound.severity + amount))
    wound.treated = false -- novo golpe reabre um ferimento que já tinha sido tratado

    local tier = GetSeverityTier(wound.severity)
    wound.bleeding = tier and tier.bleeding or 0

    print(string.format(
        '[fdb-medical-core] WOUND: src %s | %s | severity=%d (%s) | bleeding=%d',
        tostring(src), tostring(bodyPart), wound.severity, tier and tier.name or 'none', wound.bleeding
    ))

    SyncVitalsToStatebag(src)
end

--- Retorna a soma do bleeding de todos os ferimentos ativos do jogador
--- Usado pelo bleedout.lua e pela fórmula de pulso
function GetTotalBleeding(src)
    local vitals = GetPlayerVitals(src)
    local total = 0
    if not vitals.wounds then return 0 end
    for _, wound in pairs(vitals.wounds) do
        total = total + (wound.bleeding or 0)
    end
    return total
end

--- Retorna a tabela de tier (name, requiresMedic, etc) de um wound específico
function GetWoundTier(src, bodyPart)
    local vitals = GetPlayerVitals(src)
    local wound = vitals.wounds and vitals.wounds[bodyPart]
    if not wound or wound.severity <= 0 then return nil end
    return GetSeverityTier(wound.severity)
end

exports('RegisterWound', RegisterWound)
exports('GetTotalBleeding', GetTotalBleeding)
exports('GetWoundTier', GetWoundTier)
