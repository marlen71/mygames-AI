--[[
    Warcraft Online — класс: Рунный Рыцарь.
    Тяжёлый боец, сочетающий сталь, руническую магию и ремесленную подготовку.
]]

WO.Classes.Register({
    id = "runeknight",
    name = "Рунный Рыцарь",
    description = "Воин в тяжёлой броне, владеющий рунической книгой; силён в кузнечном и оружейном деле.",

    stats = {
        strength = 3,
        agility = -1,
        intelligence = 2,
        stamina = 3,
        spirit = 1,
    },

    resource = "mana",
    allowedWeapons = { "melee", "sword", "axe", "shield", "magic" },
    allowedArmor = { "plate", "mail", "shield", "misc" },
    abilities = {},
    canUseGrimoire = true,

    startingItems = {
        { class = "health_potion", amount = 3 },
        { class = "bread", amount = 2 },
    },

    magicBonuses = { earth = 0.08, frost = 0.12, lightning = 0.06 },
    professionBonuses = { blacksmith = 0.12, weaponsmith = 0.12, miner = 0.10 },
    modifiers = {},
})
