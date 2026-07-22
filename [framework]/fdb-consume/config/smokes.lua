local items = {
    ['cigar'] = {
        type = "Smoke",
        hunger = 0,
        thirst = -5,
        stress = -20,
        alcohol = 0,
        health = 5,
        stamina = 5,
        prop = "p_cigar01x"
    },
    ['cigarette'] = {
        type = "Smoke",
        hunger = 0,
        thirst = -2,
        stress = -10,
        alcohol = 0,
        health = 2,
        stamina = 2,
        prop = "p_cigarette01x"
    },
    ['chewing_tobacco'] = {
        type = "Smoke", -- Usa a mesma lógica base
        hunger = 0,
        thirst = -5,
        stress = -15,
        alcohol = 0,
        health = 0,
        stamina = 20,
        dict = "mech_inventory@eating@multi_bite@sphere_d8-2_sandwich", -- Sobrescreve para animação de mastigar
        name = "quick_left_hand",
        prop = "p_package_chewing_tobacco"
    }
}

Config.AddItems(items)
