Config = {}

-- Configurações Globais do Álcool
Config.Alcohol = {
    DrunkThreshold = 50,      -- Nível para começar a ficar tonto
    PassOutThreshold = 200,   -- Nível para desmaiar de bêbado
    DecreaseAmount = 1,       -- Quantidade que diminui por ciclo
    DecreaseInterval = 5000,  -- Tempo do ciclo em ms
    MaxAlcoholLevel = 500,    -- Limite máximo (não morre, mas passa mal)
    
    -- Efeitos
    VomitDuration = 10000,
    SleepDuration = 20000,
}

-- Animações Padrão
Config.Animations = {
    Eat = { dict = "mech_inventory@eating@multi_bite@sphere_d8_2", name = "quick_inv_eat_sphere_d8_2", prop = "p_bread_14_ab_s_a", time = 5000 },
    Drink = { dict = "mech_inventory@drinking@bottle_cylinder_d1-5_h30_a", name = "quick_inv_drink_bottle_cyl_d1-5_h30_a", prop = "p_bottlebeer01a", time = 5000 },
    Stew = { dict = "mech_inventory@eating@multi_bite@stew", name = "quick_inv_eat_stew", prop = "p_bowl04x_stew", time = 8000 },
    Coffee = { dict = "mech_inventory@drinking@mug_cylinder_d5_h10", name = "quick_inv_drink_mug_cyl_d5_h10", prop = "p_mug01_coffee", time = 5000 },
    Canned = { dict = "mech_inventory@eating@multi_bite@canned_food", name = "quick_inv_eat_canned_food", prop = "s_canrigapricots01x", time = 8000 }
}

-- Itens Consumíveis e seus Efeitos
Config.Items = {
    -- === COMIDAS ===
    ['bread'] = {
        type = "Eat",
        hunger = 25,
        thirst = 0,
        stress = 5,
        alcohol = 0
    },
    ['stew'] = {
        type = "Stew",
        hunger = 50,
        thirst = 25,
        stress = 20,
        alcohol = -10
    },
    ['canned_apricots'] = {
        type = "Canned",
        hunger = 50,
        thirst = 20,
        stress = 10,
        alcohol = -3
    },
    
    -- === BEBIDAS ===
    ['water'] = {
        type = "Drink",
        hunger = 0,
        thirst = 25,
        stress = 5,
        alcohol = -5,
    },
    ['beer'] = {
        type = "Drink",
        hunger = -3,
        thirst = 0,
        stress = -10,
        alcohol = 25,
    },
    ['coffee'] = {
        type = "Coffee",
        hunger = 0,
        thirst = 25,
        stress = 20,
        alcohol = -15,
    },
}
