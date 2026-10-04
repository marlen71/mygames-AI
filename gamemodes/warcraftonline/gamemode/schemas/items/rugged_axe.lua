--[[
    Warcraft Online — предмет: Грубый топор.
]]

WO.Items.Register({
    id = "rugged_axe",
    name = "Грубый топор",
    type = "weapon",
    category = "axe",

    model = "models/weapons/w_stunbaton.mdl",
    weight = 5,

    size = { w = 1, h = 1 },
    stackable = false,

    rarity = "uncommon",
    durability = 120,

    description = "Тяжёлый топор. Бьёт медленно, но больно.",

    weapon = {
        class = "wo_axe_rugged",
        damage = 38,
        range = 85,
        attackSpeed = 0.7,
    },

    equipment = {
        slot = "main_hand",
    },

    stats = {},

    requirements = {
        level = 3,
    },

    price = {
        buy = 250,
        sell = 60,
    },
})
