local items = {
    ['cigar'] = {
        type = "Smoke",
        hunger = 0,
        thirst = -5,
        stress = -20,
        alcohol = 0,
        health = 5,
        stamina = 5,
        prop = "p_cigar01x",
        offsets = {
            bone = "SKEL_R_Finger12",
            mouth_start = { x = 0.0, y = 0.0, z = 0.0, rx = 0.0, ry = 0.0, rz = 0.0 },
            hand_enter = { x = 0.01, y = -0.005, z = 0.0155, rx = 0.024, ry = 300.0, rz = -40.0 },
            mouth_puff = { x = -0.017, y = 0.1, z = -0.01, rx = 0.0, ry = 90.0, rz = -90.0 },
            hand_idle = { x = 0.01, y = -0.005, z = 0.0155, rx = 0.024, ry = 300.0, rz = -40.0 },
            female_hand_idle = { x = 0.01, y = 0.0, z = 0.01, rx = 0.0, ry = -160.0, rz = -130.0 }
        }
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
