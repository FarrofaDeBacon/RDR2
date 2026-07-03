Config = {}

Config.Backpacks = {
    ['backpack_large'] = {
        model = 'p_ambpack01x',
        weight = 40000, -- 40 Kg Capacity (can trigger all weight tiers)
        pos = vector3(-0.5, 0.0, 0.08),
        rot = vector3(-80.0, 0.0, -90.0),
        boneIndex = 278, -- CP_Back
        slots = 25
    },
    ['backpack_medium'] = {
        model = 'p_ambpack02x',
        weight = 25000,  -- 25 Kg Capacity (can trigger walk reduction and sprint disable)
        pos = vector3(-0.3, -0.0, 0.08),
        rot = vector3(-80.0, 0.0, -90.0),
        boneIndex = 278, -- CP_Back
        slots = 20
    },
    ['backpack_small'] = {
        model = 'p_ambpack05x',
        weight = 15000,  -- 15 Kg Capacity (can trigger walk reduction)
        pos = vector3(-0.5, 0.0, 0.08),
        rot = vector3(-80.0, 0.0, -90.0),
        boneIndex = 278, -- CP_Back
        slots = 15
    },
    ['backpack_tiny'] = {
        model = 'p_ambpack04x',
        weight = 7500,  -- 7.5 Kg Capacity
        pos = vector3(-0.2, -0.1, 0.10),
        rot = vector3(14, 0.0, -90.0),
        boneIndex = 278, -- CP_Back
        slots = 10
    }
}
