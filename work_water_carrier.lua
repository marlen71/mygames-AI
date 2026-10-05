--[[ Warcraft Online — работодатель ремесла «Водонос».
     Координаты намеренно не заданы: добавьте их в NPCSpawnPoints на целевой карте. ]]

WO.NPCs.Register({
    id = "work_water_carrier",
    name = "Водонос",
    title = "Наставник ремесла",
    type = "talker",
    model = "models/mailer/character/goblin/male/goblinmale00_02.mdl",
    skin = 41,
    scale = 1,
    professionId = "water_carrier",
    spawns = WO.Config.NPCSpawnPoints.work_water_carrier or {},
    dialogue = "profession_work",
    quests = {},
    interactRange = WO.Config.InteractDistance,
})
