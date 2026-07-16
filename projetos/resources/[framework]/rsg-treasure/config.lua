Config = {}

-- treasure blip settings
Config.TreasureBlip = {
    blipName = 'Tresure Chest', -- Config.Blip.blipName
    blipSprite = 'blip_chest', -- Config.Blip.blipSprite
    blipScale = 0.2 -- Config.Blip.blipScale
}

-- settings
Config.DetectorVolume = 0.2

-- list of common items / add more as required (must be in your shared inventory items)
Config.CommonItems = {
    "bread", -- example
    "water", -- example
    "carrot" -- example
}

-- list of rare items / add more as required (must be in your shared inventory items)
Config.RareItems = {
    "bread", -- example
    "water", -- example
    "carrot" -- example
}

-- treasure locations name must be unique and defined in the database table "treasure"
Config.Locations = {
    {name = 'treasure1', coords = vector3(-48.93, 909.70, 209.02)}, -- example
    {name = 'treasure2', coords = vector3(-814.46, 331.10, 95.90)}, -- example
    {name = 'treasure3', coords = vector3(-355.69, -148.64, 48.27)}, -- example
    {name = 'treasure4', coords = vector3(-1703.63, -332.84, 176.43)} -- example
}
