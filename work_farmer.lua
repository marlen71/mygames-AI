--[[ Warcraft Online — работодатель ремесла «Земледелец».
     Координаты намеренно не заданы: добавьте их в NPCSpawnPoints на целевой карте. ]]

WO.NPCs.Register({
    id = "work_farmer",
    name = "Земледелец",
    title = "Наставник ремесла",
    type = "talker",
    model = "models/mailer/character/human/male/humanmale00_08.mdl",
    skin = 13,
    scale = 1,
    professionId = "farmer",
    spawns = WO.Config.NPCSpawnPoints.work_farmer or {},
    dialogue = "profession_work",
    quests = {},
    interactRange = WO.Config.InteractDistance,
})
