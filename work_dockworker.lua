--[[ Warcraft Online — работодатель ремесла «Портовый рабочий».
     Координаты намеренно не заданы: добавьте их в NPCSpawnPoints на целевой карте. ]]

WO.NPCs.Register({
    id = "work_dockworker",
    name = "Портовый рабочий",
    title = "Наставник ремесла",
    type = "talker",
    model = "models/mailer/character/human/male/humanmale00_02_07.mdl",
    skin = 121,
    scale = 1,
    professionId = "dockworker",
    spawns = WO.Config.NPCSpawnPoints.work_dockworker or {},
    dialogue = "profession_work",
    quests = {},
    interactRange = WO.Config.InteractDistance,
})
