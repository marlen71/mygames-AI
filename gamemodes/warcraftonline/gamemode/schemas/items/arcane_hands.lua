--[[
    Warcraft Online — «Магические руки», слабое стартовое оружие мага.
    Использует стандартные GMod c_arms; визуальный импульс создаёт WO-SWEP.
]]

local config = WO.Config.ArcaneHands or {}

WO.Items.Register({
    id = "arcane_hands",
    name = "Магические руки",
    type = "weapon",
    category = "magic",

    model = config.fallbackWorldModel or "models/weapons/w_physics.mdl",
    weight = 0,
    size = { w = 1, h = 2 },
    stackable = false,
    rarity = "common",

    description = "Слабый дальний импульс тайной магии. Расходует ману; урон проверяется сервером.",

    weapon = {
        class = "wo_arcane_hands",
        damage = config.damage or 7,
        range = config.range or 480,
        attackSpeed = config.cooldown or 1.15,
    },

    equipment = { slot = "main_hand" },
    stats = {},
    requirements = { level = 1, class = { "mage" } },
    price = { buy = 20, sell = 5 },
})
