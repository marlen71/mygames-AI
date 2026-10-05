--[[ Warcraft Online — работодатель ремесла «Лесоруб».
     Координаты намеренно не заданы: добавьте их в NPCSpawnPoints на целевой карте. ]]

WO.NPCs.Register({
    id = "work_lumberjack",
    name = "Лесоруб",
    title = "Наставник ремесла",
    type = "talker",
    model = "models/mailer/character/human/male/humanmale00_03_04.mdl",
    skin = 101,
    scale = 1,
    professionId = "lumberjack",
    spawns = WO.Config.NPCSpawnPoints.work_lumberjack or {},
    dialogue = "profession_work",
    quests = {},
    interactRange = WO.Config.InteractDistance,
})
