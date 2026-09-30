--[[
    Warcraft Online — квест: Припасы в дорогу (collect).
]]

WO.Quests.Register({
    id = "supplies_for_the_road",
    name = "Припасы в дорогу",
    description = "Обозам нужен хлеб. Соберите три буханки.",
    level = 1,
    giver = "marshal_dughal",

    steps = {
        { type = "collect", class = "bread", amount = 3, text = "Соберите хлеб" },
    },

    rewards = {
        xp = 100,
        money = 60,
        items = {},
    },

    prerequisites = {},
})
