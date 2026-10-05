--[[ Warcraft Online — работодатель ремесла «Уборщик».
     Координаты намеренно не заданы: добавьте их в NPCSpawnPoints на целевой карте. ]]

WO.NPCs.Register({
    id = "work_cleaner",
    name = "Уборщик",
    title = "Наставник ремесла",
    type = "talker",
    model = "models/mailer/character/nightelf/male/nightelfmale00_06.mdl",
    skin = 0,
    scale = 1,
    professionId = "cleaner",
    spawns = WO.Config.NPCSpawnPoints.work_cleaner or {},
    dialogue = "profession_work",
    quests = {},
    interactRange = WO.Config.InteractDistance,
})
