--[[ Warcraft Online — работодатель ремесла «Скотник».
     Координаты намеренно не заданы: добавьте их в NPCSpawnPoints на целевой карте. ]]

WO.NPCs.Register({
    id = "work_herder",
    name = "Скотник",
    title = "Наставник ремесла",
    type = "talker",
    model = "models/mailer/character/human/male/humanmale00_07_00.mdl",
    skin = 53,
    scale = 1,
    professionId = "herder",
    spawns = WO.Config.NPCSpawnPoints.work_herder or {},
    dialogue = "profession_work",
    quests = {},
    interactRange = WO.Config.InteractDistance,
})
