-- Класс: шаман.
WO.Classes.Register({
    id = "shaman",
    name = "Шаман",
    description = "Проводник стихий, который усиливает союзников и поражает врагов магией.",
    stats = { strength = 2, agility = 1, intelligence = 2, stamina = 2, spirit = 3 },
    resource = "mana",
    allowedWeapons = { "melee", "axe", "mace", "staff", "shield", "magic" },
    allowedArmor = { "mail", "leather", "shield", "misc" },
    abilities = {},
    startingItems = { { class = "health_potion", amount = 3 }, { class = "bread", amount = 2 } },
    magicBonuses = { air = 0.08, earth = 0.08, lightning = 0.15, water = 0.08, fire = 0.05 },
    professionBonuses = { brewer = 0.10, miner = 0.08, fisher = 0.08 },
    modifiers = {},
})
