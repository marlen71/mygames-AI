-- Класс: жрец.
WO.Classes.Register({
    id = "priest",
    name = "Жрец",
    description = "Служитель веры, поддерживающий союзников исцелением и магией.",
    stats = { strength = -2, agility = 0, intelligence = 4, stamina = 1, spirit = 5 },
    resource = "mana",
    allowedWeapons = { "staff", "magic", "dagger" },
    allowedArmor = { "cloth", "misc" },
    abilities = {},
    startingItems = { { class = "health_potion", amount = 3 }, { class = "bread", amount = 2 } },
    modifiers = {},
})
