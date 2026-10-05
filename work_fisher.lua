--[[ Warcraft Online — работодатель ремесла «Рыбак».
     Координаты намеренно не заданы: добавьте их в NPCSpawnPoints на целевой карте. ]]

WO.NPCs.Register({
    id = "work_fisher",
    name = "Рыбак",
    title = "Наставник ремесла",
    type = "talker",
    model = "models/mailer/character/human/male/humanmale00_03.mdl",
    skin = 155,
    scale = 1,
    professionId = "fisher",
    spawns = WO.Config.NPCSpawnPoints.work_fisher or {},
    dialogue = "profession_work",
    quests = {},
    interactRange = WO.Config.InteractDistance,
})
