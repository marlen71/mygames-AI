-- Класс: чернокнижник.
WO.Classes.Register({
    id = "warlock",
    name = "Чернокнижник",
    description = "Изучает запретную магию и поражает противников на расстоянии.",
    stats = { strength = -2, agility = 0, intelligence = 5, stamina = 0, spirit = 3 },
    resource = "mana",
    allowedWeapons = { "staff", "magic", "dagger" },
    allowedArmor = { "cloth", "misc" },
    abilities = {},
    startingItems = { { class = "health_potion", amount = 3 }, { class = "bread", amount = 2 } },
    magicBonuses = { fire = 0.15, earth = 0.05, lightning = 0.05, life = 0.02 },
    professionBonuses = { alchemist = 0.12, merchant = 0.08, cleaner = 0.06 },
    modifiers = {},
})
