-- Класс: пробудитель.
WO.Classes.Register({
    id = "evoker",
    name = "Пробудитель",
    description = "Драконий заклинатель, направляющий магию пяти драконьих аспектов.",
    stats = { strength = 0, agility = 1, intelligence = 5, stamina = 1, spirit = 2 },
    resource = "mana",
    allowedWeapons = { "staff", "magic", "dagger" },
    allowedArmor = { "mail", "cloth", "misc" },
    abilities = {},
    startingItems = { { class = "health_potion", amount = 3 }, { class = "bread", amount = 2 } },
    magicBonuses = { air = 0.10, fire = 0.10, lightning = 0.10, water = 0.06, earth = 0.04 },
    professionBonuses = { alchemist = 0.10, jeweler = 0.10, builder = 0.08 },
    modifiers = {},
})
