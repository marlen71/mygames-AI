--[[
    Warcraft Online — предмет: Зелье здоровья.
]]

WO.Items.Register({
    id = "health_potion",
    name = "Зелье здоровья",
    type = "consumable",
    category = "potion",

    model = "models/healthvial.mdl",
    iconText = "✚",
    weight = 1,

    size = { w = 1, h = 1 },
    stackable = true,
    maxStack = 10,

    rarity = "common",

    description = "Восстанавливает 50 единиц здоровья.",

    consumable = {
        heal = 50,
    },

    requirements = {},

    price = {
        buy = 25,
        sell = 6,
    },
})
