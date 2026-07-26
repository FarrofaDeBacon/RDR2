
RegisterCommand("dirtyme", function()
    FDB.Survival.cleanliness = 10
    FDB.BroadcastState('cleanliness', 10)
    exports['ox_lib']:notify({ title = 'Sujeira', description = 'Higiene definida para 10.', type = 'inform' })
end, false)

