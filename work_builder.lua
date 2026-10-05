--[[ Warcraft Online — работодатель ремесла «Строитель».
     Координаты намеренно не заданы: добавьте их в NPCSpawnPoints на целевой карте. ]]

WO.NPCs.Register({
    id = "work_builder",
    name = "Строитель",
    title = "Наставник ремесла",
    type = "talker",
    model = "models/mailer/character/human/male/humanmale00_07_02.mdl",
    skin = 7,
    scale = 1,
    professionId = "builder",
    spawns = WO.Config.NPCSpawnPoints.work_builder or {},
    dialogue = "profession_work",
    quests = {},
    interactRange = WO.Config.InteractDistance,
})
