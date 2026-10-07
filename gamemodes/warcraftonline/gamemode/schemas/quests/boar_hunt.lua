--[[
    Warcraft Online — охота на кабанов от Охотника.
    При принятии сервер выдаёт нож; после экипировки и победы над четырьмя
    кабанами игрок сдаёт задание Охотнику. После сдачи Маршал открывает
    отдельное поручение на волков. География группы задана в sh_settings.lua.
]]

WO.Quests.Register({
    id = "boar_hunt",
    name = "Кабаны у фермы",
    description = "Получите у охотника нож, экипируйте его и победите четырёх кабанов. Вернитесь к охотнику за наградой.",
    level = 1,
    giver = "hunter_dyrne",
    turnInGiver = "hunter_dyrne",
    turnInRequired = true,
    sequential = true,
    acceptItems = {
        { class = "starter_knife", amount = 1 },
    },

    steps = {
        { type = "equip", class = "starter_knife", amount = 1,
            text = "Экипируйте стартовый нож" },
        { type = "kill", target = "elwynn_boar", amount = 4,
            text = "Победите кабанов" },
    },

    rewards = {
        xp = 100,
        money = 3500,
    },

    prerequisites = {},
})
