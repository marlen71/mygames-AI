--[[
    Warcraft Online — первая охота по просьбе маршала.
    Охотник выдаёт поручение; нож должен быть экипирован до начала охоты.
    После четырёх кабанов игрок докладывает маршалу, и только затем открывается
    отдельное задание на волков. География группы задана в sh_settings.lua.
]]

WO.Quests.Register({
    id = "boar_hunt",
    name = "Кабаны у фермы",
    description = "Экипируйте стартовый нож и победите четырёх кабанов. Затем доложите маршалу.",
    level = 1,
    giver = "hunter_dyrne",
    turnInGiver = "marshal_dughal",
    turnInRequired = true,
    sequential = true,

    steps = {
        { type = "equip", class = "starter_knife", amount = 1,
            text = "Экипируйте стартовый нож" },
        { type = "kill", target = "elwynn_boar", amount = 4,
            text = "Победите кабанов" },
    },

    rewards = {
        xp = 100,
        money = 35,
    },

    prerequisites = {},
})
