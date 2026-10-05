--[[ Warcraft Online — работодатель ремесла «Травник».
     Координаты намеренно не заданы: добавьте их в NPCSpawnPoints на целевой карте. ]]

WO.NPCs.Register({
    id = "work_herbalist",
    name = "Травник",
    title = "Наставник ремесла",
    type = "talker",
    model = "models/mailer/character/goblin/male/goblinmale00_06.mdl",
    skin = 59,
    scale = 1,
    professionId = "herbalist",
    spawns = WO.Config.NPCSpawnPoints.work_herbalist or {},
    dialogue = "profession_work",
    quests = {},
    interactRange = WO.Config.InteractDistance,
})
