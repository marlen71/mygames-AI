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
    modifiers = {},
})
