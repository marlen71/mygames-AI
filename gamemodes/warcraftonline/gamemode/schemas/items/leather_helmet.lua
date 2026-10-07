--[[
    Warcraft Online — предмет: Кожаный шлем.
]]

WO.Items.Register({
    id = "leather_helmet",
    name = "Кожаный шлем",
    type = "helmet",
    category = "leather",

    -- Плейсхолдер (заменяется на контент-модель шлема)
    model = "models/props_junk/trafficcone001a.mdl",
    weight = 2,

    size = { w = 1, h = 1 },
    stackable = false,

    rarity = "common",
    durability = 60,

    description = "Кожаный шлем. Пусть и простой, но головубережёт.",

    equipment = {
        slot = "head",
    },

    stats = {
        armor = 4,
        stamina = 2,
    },

    requirements = {
        level = 1,
    },

    price = {
        buy = 7000,
        sell = 1800,
    },
})
