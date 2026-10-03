--[[
    Warcraft Online — стартовый нож.
    Хранится как обычный инвентарный экземпляр; точный SWEP выдаётся только
    после экипировки предмета в main_hand.
]]

WO.Items.Register({
    id = "starter_knife",
    name = "Стартовый нож",
    type = "weapon",
    category = "dagger",
    iconText = "Н",
    weight = 1,
    size = { w = 1, h = 2 },
    stackable = false,
    rarity = "common",
    durability = 100,
    description = "Лёгкий нож. Экипируйте его, чтобы использовать в бою.",

    -- Узкое исключение: только этот предмет представляет нож из starter
    -- config. Руки и магический посох по-прежнему не являются предметами.
    allowStarterKnifeItem = true,

    weapon = {
        class = "tfa_cso_coldsteelblade",
    },

    equipment = {
        slot = "main_hand",
    },

    stats = {},
    requirements = {
        level = 1,
    },
})
