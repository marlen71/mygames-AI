--[[
    Warcraft Online — торговка Марла: скупщица низкоуровневого хлама.
    Точная WoW-модель пользователя; ассортимент и buyback проверяются сервером.
]]

WO.NPCs.Register({
    id = "trader_marla",
    name = "Торговка Марла",
    type = "vendor",
    model = "models/mailer/wow_characters/wowanim_gnome_male.mdl",
    skin = 0,
    scale = 1,
    spawns = WO.Config.NPCSpawnPoints.trader_marla or {},
    dialogue = "trader_marla",
    quests = {}, -- торговка не выдаёт задания; отправляет к охотнику и маршалу
    vendor = {
        stock = {
            { class = "bread", price = 4, amount = 20 },
            { class = "health_potion", price = 25, amount = 10 },
            { class = "wolf_pelt", price = 12, amount = 5 },
            { class = "leather_helmet", price = 60, amount = 2 },
            { class = "wooden_shield", price = 45, amount = 2 },
        },
        sellRate = 0.65,
        buybackClasses = { "wolf_pelt", "wolf_fang", "boar_tusk", "boar_meat" },
    },
    interactRange = WO.Config.InteractDistance,
})
