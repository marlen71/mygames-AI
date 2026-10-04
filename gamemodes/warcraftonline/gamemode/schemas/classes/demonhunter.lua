-- Класс: охотник на демонов.
WO.Classes.Register({
    id = "demonhunter",
    name = "Охотник на демонов",
    description = "Подвижный боец, использующий ловкость и опасную демоническую силу.",
    stats = { strength = 1, agility = 5, intelligence = 1, stamina = 1, spirit = 0 },
    resource = "stamina",
    allowedWeapons = { "melee", "sword", "dagger", "axe" },
    allowedArmor = { "leather", "misc" },
    abilities = {},
    startingItems = { { class = "health_potion", amount = 3 }, { class = "bread", amount = 2 } },
    magicBonuses = { fire = 0.08, air = 0.08, lightning = 0.04 },
    professionBonuses = { weaponsmith = 0.10, porter = 0.08, dockworker = 0.06 },
    modifiers = {},
})
