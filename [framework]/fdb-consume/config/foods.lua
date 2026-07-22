local items = {
    ['bread'] = {
        type = "Eat",
        hunger = 25,
        thirst = 0,
        stress = 5,
        alcohol = 0,
        health = 5,
        stamina = 0,
        uses = 5 -- Quantas mordidas o pão vai durar
    },
    ['stew'] = {
        type = "Stew",
        hunger = 50,
        thirst = 25,
        stress = 20,
        alcohol = -10,
        health = 20,
        stamina = 20,
        uses = 1 -- Ensopado é 1 uso só (pois a animação é única e longa)
    },
    ['canned_apricots'] = {
        type = "Canned",
        hunger = 50,
        thirst = 20,
        stress = 10,
        alcohol = -3,
        health = 10,
        uses = 4 -- Quantas mordidas a lata vai durar
    },
    ['canned_beans'] = {
        type = "Canned",
        hunger = 60,
        thirst = 10,
        stress = 5,
        health = 15,
        uses = 4 -- Quantas mordidas a lata vai durar
    },
    ['apple'] = {
        type = "Eat",
        hunger = 15,
        thirst = 10,
        health = 5,
        prop = "p_apple01x",
        uses = 2 -- Maçã acaba rápido
    },
    ['cheese'] = {
        type = "Eat",
        hunger = 30,
        thirst = -5,
        health = 5,
        prop = "p_baitcheese01x",
        uses = 3 -- Pedaço de queijo
    }
}

Config.AddItems(items)
