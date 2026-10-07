-- Класс: монах.
WO.Classes.Register({
    id = "monk",
    name = "Монах",
    description = "Быстрый боец, полагающийся на дисциплину, стойкость и точные удары.",
    stats = { strength = 2, agility = 3, intelligence = 0, stamina = 3, spirit = 2 },
    resource = "stamina",
    allowedWeapons = { "melee", "staff", "axe", "sword" },
    allowedArmor = { "leather", "mail", "misc" },
    abilities = {},
    startingItems = { { class = "health_potion", amount = 2 }, { class = "bread", amount = 3 } },
    magicBonuses = { life = 0.08, air = 0.06, water = 0.04 },
    professionBonuses = { baker = 0.10, herbalist = 0.08, fisher = 0.08 },
    modifiers = {},
})
