--[[
    Warcraft Online — квест: Знакомство с торговкой (talk).
]]

WO.Quests.Register({
    id = "meet_the_trader",
    name = "Знакомство с торговкой",
    description = "Навестите торговку Марлу и расспросите её о работе.",
    level = 1,
    giver = "trader_marla",

    steps = {
        { type = "talk", target = "trader_marla", amount = 1, text = "Поговорите с Марлой" },
    },

    rewards = {
        xp = 50,
        money = 2500,
        items = {},
    },

    prerequisites = {},
})
