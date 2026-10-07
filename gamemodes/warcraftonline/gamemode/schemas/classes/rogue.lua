--[[
    Warcraft Online — класс: Разбойник.
]]

WO.Classes.Register({
    id = "rogue",
    name = "Разбойник",
    description = "Быстрые удары, скрытность, критические атаки.",

    stats = {
        strength = 1,
        agility = 5,
        intelligence = 0,
        stamina = 0,
        spirit = 1,
    },

    resource = "stamina",

    allowedWeapons = { "melee", "sword", "dagger" },
    allowedArmor = { "leather", "misc" },

    abilities = {},

    startingItems = {
        { class = "leather_helmet", amount = 1 },
        { class = "health_potion", amount = 2 },
    },

    magicBonuses = { air = 0.03, earth = 0.02 },
    professionBonuses = { merchant = 0.08, cleaner = 0.10, herbalist = 0.06 },
    modifiers = {},
})
