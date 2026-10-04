--[[
    Warcraft Online — предмет: Посох ученика.
]]

WO.Items.Register({
    id = "apprentice_staff",
    name = "Посох ученика",
    type = "weapon",
    category = "staff",

    model = "models/weapons/w_physics.mdl",
    weight = 4,

    size = { w = 1, h = 1 },
    stackable = false,

    rarity = "uncommon",
    durability = 80,

    description = "Посох начинающего мага. Усиливает заклинания.",

    weapon = {
        class = "wo_staff_apprentice",
        damage = 10,
        range = 95,
        attackSpeed = 0.9,
    },

    equipment = {
        slot = "main_hand",
    },

    stats = {
        intelligence = 3,
    },

    requirements = {
        level = 1,
        class = { "mage" },
    },

    price = {
        buy = 180,
        sell = 45,
    },
})
