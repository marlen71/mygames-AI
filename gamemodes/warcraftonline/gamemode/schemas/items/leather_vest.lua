--[[
    Warcraft Online — предмет: Кожаный жилет.
]]

WO.Items.Register({
    id = "leather_vest",
    name = "Кожаный жилет",
    type = "armor",
    category = "leather",

    -- Плейсхолдер (заменяется на контент-модель брони)
    model = "models/props_junk/cardboard_box002a.mdl",
    weight = 4,

    size = { w = 1, h = 1 },
    stackable = false,

    rarity = "common",
    durability = 70,

    description = "Жилет из толстой кожи. Защищает от царапин и стрел.",

    equipment = {
        slot = "chest",
    },

    stats = {
        armor = 8,
        stamina = 3,
    },

    requirements = {
        level = 1,
    },

    price = {
        buy = 120,
        sell = 30,
    },
})
