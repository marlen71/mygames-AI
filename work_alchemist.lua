--[[ Warcraft Online — работодатель ремесла «Алхимик».
     Координаты намеренно не заданы: добавьте их в NPCSpawnPoints на целевой карте. ]]

WO.NPCs.Register({
    id = "work_alchemist",
    name = "Алхимик",
    title = "Наставник ремесла",
    type = "talker",
    model = "models/mailer/wow/character/bloodelf/male/bloodelfmale_02_00_hd.mdl",
    skin = 0,
    scale = 1,
    professionId = "alchemist",
    spawns = WO.Config.NPCSpawnPoints.work_alchemist or {},
    dialogue = "profession_work",
    quests = {},
    interactRange = WO.Config.InteractDistance,
})
