--[[ Warcraft Online — работодатель ремесла «Плотник».
     Координаты намеренно не заданы: добавьте их в NPCSpawnPoints на целевой карте. ]]

WO.NPCs.Register({
    id = "work_carpenter",
    name = "Плотник",
    title = "Наставник ремесла",
    type = "talker",
    model = "models/mailer/character/human/male/humanmale00_01_03.mdl",
    skin = 5,
    scale = 1,
    professionId = "carpenter",
    spawns = WO.Config.NPCSpawnPoints.work_carpenter or {},
    dialogue = "profession_work",
    quests = {},
    interactRange = WO.Config.InteractDistance,
})
