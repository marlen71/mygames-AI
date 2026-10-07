--[[
    Warcraft Online — предмет: Хлеб.
]]

WO.Items.Register({
    id = "bread",
    name = "Хлеб",
    type = "food",
    category = "food",

    model = "models/props_junk/garbage_bag001a.mdl",
    weight = 1,

    size = { w = 1, h = 1 },
    stackable = true,
    maxStack = 20,

    rarity = "common",

    description = "Свежий хлеб. Восстанавливает немного здоровья.",

    consumable = {
        heal = 15,
    },

    requirements = {},

    price = {
        buy = 500,
        sell = 100,
    },
})
