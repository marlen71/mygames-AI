--[[
    Warcraft Online — предмет: Золотое кольцо.
]]

WO.Items.Register({
    id = "gold_ring",
    name = "Золотое кольцо",
    type = "ring",
    category = "misc",

    model = "models/props_junk/watermelon01.mdl",
    weight = 0,

    size = { w = 1, h = 1 },
    stackable = false,

    rarity = "rare",
    durability = 50,

    description = "Блестящее золотое кольцо. Усиливает владельца.",

    equipment = {
        slot = "ring",
    },

    stats = {
        strength = 2,
        agility = 2,
    },

    requirements = {
        level = 5,
    },

    price = {
        buy = 50000,
        sell = 12500,
    },
})
