--[[
    Warcraft Online — класс: Стрелок.
]]

WO.Classes.Register({
    id = "ranger",
    name = "Охотник",
    description = "Охотник и следопыт. Владеет дальним боем и лёгкой бронёй.",

    stats = {
        strength = 1,
        agility = 4,
        intelligence = 1,
        stamina = 2,
        spirit = 1,
    },

    resource = "stamina",

    allowedWeapons = { "ranged", "bow", "melee", "axe", "dagger" },
    allowedArmor = { "leather", "mail", "misc" },

    abilities = {},

    startingItems = {
        { class = "leather_helmet", amount = 1 },
        { class = "wolf_pelt", amount = 2 },
    },

    magicBonuses = { air = 0.05, earth = 0.04, water = 0.04 },
    professionBonuses = { lumberjack = 0.08, fisher = 0.10, herbalist = 0.12 },
    modifiers = {},
})
