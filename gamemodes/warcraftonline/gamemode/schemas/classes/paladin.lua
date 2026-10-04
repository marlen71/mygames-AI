-- Класс: паладин.
WO.Classes.Register({
    id = "paladin",
    name = "Паладин",
    description = "Защитник Света, сочетающий тяжёлую броню, оружие и исцеляющую магию.",
    stats = { strength = 3, agility = 0, intelligence = 1, stamina = 3, spirit = 2 },
    resource = "mana",
    allowedWeapons = { "melee", "sword", "axe", "shield", "magic" },
    allowedArmor = { "plate", "mail", "shield", "misc" },
    abilities = {},
    startingItems = { { class = "health_potion", amount = 2 }, { class = "bread", amount = 2 } },
    modifiers = {},
})
