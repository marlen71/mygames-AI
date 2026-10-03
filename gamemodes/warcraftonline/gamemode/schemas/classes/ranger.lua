--[[
    Warcraft Online — класс: Стрелок.
]]

WO.Classes.Register({
    id = "ranger",
    name = "Стрелок",
    description = "Охотник и следопыт. Владеет дальним боем и лёгкой бронёй.",

    stats = {
        strength = 1,
        agility = 4,
        intelligence = 1,
        stamina = 2,
        spirit = 1,
    },

    resource = "stamina",
    startingEquipment = { main_hand = "starter_knife" },

    allowedWeapons = { "ranged", "bow", "melee", "axe", "dagger" },
    allowedArmor = { "leather", "mail", "misc" },

    abilities = {},

    startingItems = {
        { class = "starter_knife", amount = 1 },
        { class = "leather_helmet", amount = 1 },
        { class = "wolf_pelt", amount = 2 },
    },

    modifiers = {},
})
