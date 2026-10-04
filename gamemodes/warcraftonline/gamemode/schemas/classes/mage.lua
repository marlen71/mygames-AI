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

    magicBonuses = { air = 0.10, earth = 0.05, fire = 0.12, frost = 0.10, lightning = 0.12, water = 0.08, life = 0.04 },
    professionBonuses = { alchemist = 0.12, brewer = 0.08, jeweler = 0.08 },
    modifiers = {},
})
