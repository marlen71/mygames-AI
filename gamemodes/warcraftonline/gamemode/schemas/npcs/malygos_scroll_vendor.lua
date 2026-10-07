--[[ Warcraft Online — Малигос, продавец свитков стихий. ]]

WO.NPCs.Register({
    id = "malygos_scroll_vendor",
    name = "Малигос",
    title = "Хранитель магических свитков",
    type = "vendor",
    model = "models/mailer/wow_characters/wowanim_malygos.mdl",
    skin = 0,
    scale = 1,
    spawns = WO.Config.NPCSpawnPoints.malygos_scroll_vendor or {},
    dialogue = "malygos_scroll_vendor",
    quests = {},
    vendor = {
        -- Stock is populated from the registered spell schemas after they load.
        stock = {},
        sellRate = (WO.Config.MagicScrolls and WO.Config.MagicScrolls.sellRate) or 0.50,
        buybackClasses = {},
    },
    interactRange = WO.Config.InteractDistance,
})
