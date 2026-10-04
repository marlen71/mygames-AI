--[[
    Warcraft Online — помощь маршалу против волков.
    Маршал выдаёт задание после отчёта об охоте на кабанов и принимает его сам.
    Ровно четыре волка создаются в фиксированных точках.
]]

WO.Quests.Register({
    id = "wolves_of_elwynn",
    name = "Волки у дороги",
    description = "По поручению маршала победите четырёх волков и вернитесь к нему за наградой.",
    level = 1,
    giver = "marshal_dughal",
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
