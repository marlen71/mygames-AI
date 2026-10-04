-- Класс: друид.
WO.Classes.Register({
    id = "druid",
    name = "Друид",
    description = "Хранитель природы, способный сражаться, исцелять и управлять стихиями.",
    stats = { strength = 1, agility = 2, intelligence = 3, stamina = 1, spirit = 3 },
    resource = "mana",
    allowedWeapons = { "staff", "magic", "dagger", "melee", "mace" },
    allowedArmor = { "leather", "cloth", "misc" },
    abilities = {},
    startingItems = { { class = "health_potion", amount = 2 }, { class = "bread", amount = 2 } },
    modifiers = {},
})
