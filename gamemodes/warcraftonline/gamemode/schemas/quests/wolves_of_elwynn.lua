--[[
    Warcraft Online — квест: Волки Элвинна.
    Добавление квеста = новый файл в schemas/quests/.
]]

WO.Quests.Register({
    id = "wolves_of_elwynn",
    name = "Волки Элвинна",
    description = "Чёрные волки терзают путников у дорог. Победи трёх тварей.",
    level = 2,
    giver = "marshal_dughal",

    steps = {
        { type = "kill", target = "black_wolf", amount = 3, text = "Победите чёрных волков" },
    },

    rewards = {
        xp = 250,
        money = 120,
        items = {
            { class = "health_potion", amount = 2 },
        },
    },

    prerequisites = {},
})
