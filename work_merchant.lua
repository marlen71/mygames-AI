--[[ Warcraft Online — работодатель ремесла «Рыночный торговец».
     Координаты намеренно не заданы: добавьте их в NPCSpawnPoints на целевой карте. ]]

WO.NPCs.Register({
    id = "work_merchant",
    name = "Рыночный торговец",
    title = "Наставник ремесла",
    type = "talker",
    model = "models/mailer/character/gnome/male/gnomemale00_03.mdl",
    skin = 44,
    scale = 1,
    professionId = "merchant",
    spawns = WO.Config.NPCSpawnPoints.work_merchant or {},
    dialogue = "profession_work",
    quests = {},
    interactRange = WO.Config.InteractDistance,
})
