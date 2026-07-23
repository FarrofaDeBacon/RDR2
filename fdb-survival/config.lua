Config = {}

-- ==========================================
-- TAXAS DE DRENAGEM BÁSICAS (Por Tick de 4s)
-- ==========================================
Config.DrainRates = {
    TickRate = 4000,           -- Frequência do loop de sobrevivência em milissegundos
    Cleanliness = 0.1,         -- Higiene perdida por tick (clima limpo)
    Bladder = 0.2,             -- Aumento da vontade de urinar por tick
    
    -- Multiplicadores de Clima (aplicados sobre Cleanliness)
    WeatherMultipliers = {
        Rain = 2.0             -- Mais sujeira se estiver chovendo (GetRainLevel > 0.1)
    },
    
    -- Ganhos de Sujeira Imediata
    DirtinessActions = {
        BloodDamage = 15.0,     -- Sujeira ganha ao tomar dano na vida (Sangue)
        FallMud = 10.0,         -- Sujeira ganha ao cair no chão/rolar (Lama)
        WashInWater = 25.0      -- Quantidade limpa por tick ao entrar na água
    }
}

-- ==========================================
-- DANOS CONTÍNUOS E DOENÇAS
-- ==========================================
Config.Hazards = {
    PoisonDamage = 2,          -- Dano à vida por tick se envenenado (piso 0)
    TemperatureDamage = 3,     -- Dano à vida por tick em clima extremo (piso 0)
    
    ExtremeColdThreshold = -2.0, -- Temperatura em Celsius para considerar muito frio
    ExtremeHeatThreshold = 37.0, -- Temperatura em Celsius para considerar muito calor

    -- Chance de contrair doença (Illness) no frio extremo
    IllnessChancePercent = 8,  -- 8% de chance a cada tick de frio
    IllnessGain = 10,          -- Quanto de Illness ganha quando a chance acerta

    -- Efeitos da Doença
    IllnessSymptomThreshold = 5, -- A partir de quanto de Illness o jogador tosse
    CoughChancePercent = 12      -- 12% de chance de tossir por tick
}

-- ==========================================
-- EFEITOS DE BUFFS DE CONSUMÍVEIS
-- ==========================================
Config.Buffs = {
    ThermalDuration = 180      -- Duração padrão em segundos para proteção contra frio/calor (ex: hot_soup)
}
