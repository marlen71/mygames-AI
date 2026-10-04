--[[
    Warcraft Online — предмет: Волчья шкура (материал).
]]

WO.Items.Register({
    id = "wolf_pelt",
    name = "Волчья шкура",
    type = "material",
    category = "material",

    model = "models/props_junk/garbage_bag001a.mdl",
    weight = 2,

    size = { w = 1, h = 1 },
    stackable = true,
    maxStack = 10,

    rarity = "common",

    description = "Тёплая шкура волка. Используется для крафта.",

    requirements = {},

    price = {
        buy = 20,
        sell = 5,
    },
})
