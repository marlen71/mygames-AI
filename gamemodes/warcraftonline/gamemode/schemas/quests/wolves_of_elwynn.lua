--[[
    Warcraft Online — охота на стаю волков.
    Стая появляется только после принятия задания у Охотника.
]]

WO.Quests.Register({
    id = "wolves_of_elwynn",
    name = "Первая охота",
    description = "Победите семерых волков у дороги и получите награду.",
    level = 1,
    giver = "hunter_dyrne",

    steps = {
        { type = "kill", target = "black_wolf", amount = 7,
            text = "Победите волков" },
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
