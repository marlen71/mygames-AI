--[[
    Warcraft Online — класс: Маг.
]]

WO.Classes.Register({
    id = "mage",
    name = "Маг",
    description = "Повелитель стихий. Силен на расстоянии, слаб в ближнем бою.",

    stats = {
        strength = -2,
        agility = 0,
        intelligence = 5,
        stamina = -1,
        spirit = 3,
    },

    resource = "mana",

    allowedWeapons = { "staff", "magic", "dagger" },
    allowedArmor = { "cloth", "misc" },

    abilities = {},

    startingItems = {
        { class = "health_potion", amount = 3 },
        { class = "bread", amount = 2 },
    },

    modifiers = {},
})
