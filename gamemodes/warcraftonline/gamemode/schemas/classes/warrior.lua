--[[
    Warcraft Online — класс: Воин.
    Добавление нового класса = новый файл в schemas/classes/.
]]

WO.Classes.Register({
    id = "warrior",
    name = "Воин",
    description = "Мастер ближнего боя и защиты. Носит тяжёлую броню.",

    stats = {
        strength = 4,
        agility = 1,
        intelligence = -2,
        stamina = 3,
        spirit = 0,
    },

    resource = "stamina",

    allowedWeapons = { "melee", "sword", "axe", "shield" },
    allowedArmor = { "plate", "mail", "leather", "shield", "misc" },

    abilities = {},

    startingItems = {
        { class = "iron_sword", amount = 1 },
        { class = "leather_vest", amount = 1 },
        { class = "bread", amount = 3 },
    },

    modifiers = {},
})
