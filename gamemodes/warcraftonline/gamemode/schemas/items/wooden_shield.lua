--[[
    Warcraft Online — предмет: Деревянный щит.
]]

WO.Items.Register({
    id = "wooden_shield",
    name = "Деревянный щит",
    type = "armor",
    category = "shield",

    model = "models/props_junk/wood_pallet001a.mdl",
    weight = 6,

    size = { w = 1, h = 1 },
    stackable = false,

    rarity = "common",
    durability = 80,

    description = "Простой щит из досок. Лучше, чем ничего.",

    equipment = {
        slot = "off_hand",
    },

    stats = {
        armor = 10,
        stamina = 1,
    },

    requirements = {
        level = 1,
    },

    price = {
        buy = 8000,
        sell = 2000,
    },
})
