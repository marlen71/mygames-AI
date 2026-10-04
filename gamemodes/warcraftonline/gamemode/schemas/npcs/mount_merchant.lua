--[[
    Warcraft Online — торговец маунтами.
    Класс лошади wow_npc_8883 проверяется при покупке/вызове; неизвестный класс
    не подменяется другим NPC. Точка выбрана явно, но геометрию нужно проверить live.
]]

WO.NPCs.Register({
    id = "mount_merchant",
    name = "Хранитель камней",
    type = "vendor",
    model = "models/mailer/wow_characters/wowanim_c_stoneconstruct.mdl",
    skin = 0,
    scale = 1,
    spawns = WO.Config.NPCSpawnPoints.mount_merchant or {},
    dialogue = "mount_vendor",
    quests = {},
    vendor = {
        stock = {
            { class = "mount_stone", price = 500, amount = 1 },
            { class = "mount_oats", price = 12, amount = 30 },
            { class = "mount_training_kit", price = 150, amount = 10 },
            { class = "mount_healing_salve", price = 35, amount = 10 },
            { class = "mount_barding", price = 180, amount = 5 },
        },
        sellRate = 0,
        buybackClasses = {},
    },
    interactRange = WO.Config.InteractDistance,
})
