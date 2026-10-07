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
    magicBonuses = { frost = 0.14, life = 0.04, earth = 0.04 },
    professionBonuses = { blacksmith = 0.12, miner = 0.08, builder = 0.08 },
    modifiers = {},
})
