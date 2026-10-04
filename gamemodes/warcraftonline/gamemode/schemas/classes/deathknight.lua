-- Класс: рыцарь смерти.
WO.Classes.Register({
    id = "deathknight",
    name = "Рыцарь смерти",
    description = "Тяжёлый боец, использующий силу рун и стойкость нежити.",
    stats = { strength = 4, agility = 0, intelligence = 1, stamina = 4, spirit = -1 },
    resource = "stamina",
    allowedWeapons = { "melee", "sword", "axe", "shield" },
    allowedArmor = { "plate", "mail", "shield", "misc" },
    abilities = {},
    startingItems = { { class = "health_potion", amount = 3 }, { class = "bread", amount = 2 } },
    modifiers = {},
})
