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
    repeatInterval = 900, -- simple job returns about 15 minutes after turn-in

    steps = {
        { type = "collect", class = "bread", amount = 3, consume = true,
            waypointNPC = "trader_marla", waypointRadius = 180,
            text = "Купите хлеб у торговки" },
    },

    rewards = {
        xp = 100,
        money = 6000,
        items = {},
    },

    prerequisites = {},
})
