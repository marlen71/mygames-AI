--[[
    Warcraft Online — торговка Марла.
    Экономика data-driven; модель должна быть смонтированной WoW-моделью.
]]

local humanModels = WO.Models.GetRace("human")

WO.NPCs.Register({
    id = "trader_marla",
    name = "Торговка Марла",
    type = "vendor",

    model = WO.Workshop.NPCModelOr("wow_vendor",
        humanModels.female and humanModels.female[1]),
    skin = 0,
    scale = 1,

    spawns = WO.Config.NPCSpawnPoints.trader_marla or {},

    dialogue = "trader_marla",
    quests = { "meet_the_trader" },

    vendor = {
        stock = {
            { class = "bread",          price = 4,  amount = 20 },
            { class = "health_potion",  price = 25, amount = 10 },
            { class = "wolf_pelt",      price = 12, amount = 5 },
            { class = "leather_helmet", price = 60, amount = 2 },
            { class = "wooden_shield",  price = 45, amount = 2 },
        },
        sellRate = 0.35,
    },

    interactRange = WO.Config.InteractDistance,
})
