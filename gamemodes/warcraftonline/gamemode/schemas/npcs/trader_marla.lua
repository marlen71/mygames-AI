--[[
    Warcraft Online — NPC: торговка Марла.
]]

WO.NPCs.Register({
    id = "trader_marla",
    name = "Торговка Марла",
    type = "vendor",

    model = "models/player/Group01/female_02.mdl",
    skin = 0,
    scale = 1,

    spawns = {},

    dialogue = "trader_marla",
    quests = { "meet_the_trader" },

    vendor = {
        stock = {
            { class = "bread",         price = 4,  amount = 20 },
            { class = "health_potion", price = 25, amount = 10 },
            { class = "wolf_pelt",     price = 12, amount = 5 },
            { class = "leather_helmet", price = 60, amount = 2 },
            { class = "wooden_shield", price = 45, amount = 2 },
        },
        sellRate = 0.35,
    },

    interactRange = 140,
})
