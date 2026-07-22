local items = {
    ['water'] = {
        type = "Drink",
        hunger = 0,
        thirst = 25,
        stress = 5,
        alcohol = -5,
        health = 0,
        stamina = 5,
        uses = 3, -- Configure quantos goles a água vai durar
        give = { item = "empty_bottle", count = 1 }
    },
    ['beer'] = {
        type = "Drink",
        hunger = -3,
        thirst = 0,
        stress = -10,
        alcohol = 25,
        health = 5,
        uses = 5, -- Configure quantos goles a cerveja vai durar
        give = { item = "empty_bottle", count = 1 }
    },
    ['coffee'] = {
        type = "Coffee",
        hunger = 5,
        thirst = 15,
        stress = -20,
        alcohol = 0,
        health = 5,
        stamina = 15,
        uses = 4, -- Configure quantos goles o café vai durar
        give = { item = "empty_mug", count = 1 }
    },
    ['whiskey'] = {
        type = "Drink",
        hunger = 0,
        thirst = 10,
        stress = -30,
        alcohol = 20,
        health = -5,
        stamina = 0,
        uses = 3,
        prop = "p_bottle01x",
        give = { item = "empty_bottle", count = 1 }
    },
    ['guarma_rum'] = {
        type = "Drink",
        hunger = 0,
        thirst = 10,
        stress = -25,
        alcohol = 25,
        health = -10,
        stamina = 30,
        give = { item = "empty_bottle", count = 1 }
    },
    ['milk'] = {
        type = "Drink",
        hunger = 10,
        stress = -5,
        alcohol = -10, -- Leite corta o álcool
        health = 10,
        stamina = 5,
        uses = 5, -- <<< EXATAMENTE AQUI! Você pode colocar diferente para cada um.
        prop = "p_bottle01x",
        give = { item = "empty_bottle", count = 1 }
    }
}

Config.AddItems(items)
