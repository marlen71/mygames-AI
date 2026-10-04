--[[
    Warcraft Online — предмет: Железный меч.
    Item Definition. Конкретные мечи — Item Instances (uid, durability...).
]]

WO.Items.Register({
    id = "iron_sword",
    name = "Железный меч",
    type = "weapon",
    category = "sword",

    model = "models/weapons/w_crowbar.mdl",
    weight = 3,

    size = { w = 1, h = 1 },
    stackable = false,
    maxStack = 1,

    rarity = "common",
    durability = 100,

    description = "Обычный железный меч. Надёжен и прост.",

    weapon = {
        class = "wo_sword_iron",
        damage = 25,
        range = 85,
        attackSpeed = 1.0,
    },

    equipment = {
        slot = "main_hand",
    },

    stats = {},

    requirements = {
        level = 1,
    },

    price = {
        buy = 100,
        sell = 25,
    },
})
