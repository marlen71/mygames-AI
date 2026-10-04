--[[
    Warcraft Online — независимый хлебный квест маршала.
    Его можно принять и выполнить в любой момент; припасы физически сдаются NPC.
]]

WO.Quests.Register({
    id = "supplies_for_the_road",
    name = "Припасы в дорогу",
    description = "Соберите три буханки хлеба и передайте их маршалу.",
    level = 1,
    giver = "marshal_dughal",
    turnInGiver = "marshal_dughal",
    turnInRequired = true,

    steps = {
        { type = "collect", class = "bread", amount = 3, consume = true,
            text = "Соберите хлеб" },
    },

    rewards = {
        xp = 100,
        money = 60,
        items = {},
    },

    prerequisites = {},
})
