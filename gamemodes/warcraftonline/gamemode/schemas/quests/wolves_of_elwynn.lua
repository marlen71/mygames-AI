--[[
    Warcraft Online — помощь маршалу против волков.
    Охотник выдаёт задание только после отчёта о кабанах; завершённую охоту
    необходимо сдать маршалу. Ровно четыре волка создаются в фиксированных точках.
]]

WO.Quests.Register({
    id = "wolves_of_elwynn",
    name = "Волки у дороги",
    description = "По поручению охотника победите четырёх волков и вернитесь к маршалу.",
    level = 1,
    giver = "hunter_dyrne",
    turnInGiver = "marshal_dughal",
    turnInRequired = true,

    steps = {
        { type = "kill", target = "black_wolf", amount = 4,
            text = "Победите волков" },
    },

    rewards = {
        xp = 80,
        money = 25,
        items = {
            { class = "wolf_pelt", amount = 1 },
        },
    },

    prerequisites = { "boar_hunt" },
})
