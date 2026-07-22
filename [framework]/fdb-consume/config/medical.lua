local items = {
    ['horse_stimulant'] = {
        type = "Medical",
        hunger = 0,
        thirst = 0,
        stress = -10,
        alcohol = 0,
        health = 50,
        stamina = 50
    },
    ['horse_reviver'] = {
        type = "Medical",
        hunger = 0,
        thirst = 0,
        stress = -20,
        alcohol = 0,
        health = 100,
        stamina = 100
    }
}

Config.AddItems(items)
