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
    startingEquipment = { main_hand = "starter_knife" },

    allowedWeapons = { "melee", "sword", "dagger" },
    allowedArmor = { "leather", "misc" },

    abilities = {},

    startingItems = {
        { class = "starter_knife", amount = 1 },
        { class = "leather_helmet", amount = 1 },
        { class = "health_potion", amount = 2 },
    },

    modifiers = {},
})
