--[[
    Warcraft Online — стартовый тестовый квест.
    Цикл: принять задание у маршала → победить волка уровня 1 → получить награду.
]]

WO.Quests.Register({
    id = "wolves_of_elwynn",
    name = "Первая охота",
    description = "Победите одного волка первого уровня у дороги и получите награду.",
    level = 1,
    giver = "marshal_dughal",

    steps = {
        { type = "kill", target = "black_wolf", amount = 1,
            text = "Победите волка первого уровня" },
    },

    rewards = {
        xp = 80,
        money = 25,
        items = {
            { class = "wolf_pelt", amount = 1 },
        },
    },

    prerequisites = {},
})
