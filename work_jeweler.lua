--[[ Warcraft Online — работодатель ремесла «Ювелир».
     Координаты намеренно не заданы: добавьте их в NPCSpawnPoints на целевой карте. ]]

WO.NPCs.Register({
    id = "work_jeweler",
    name = "Ювелир",
    title = "Наставник ремесла",
    type = "talker",
    model = "models/mailer/character/gnome/male/gnomemale00_02_02.mdl",
    skin = 47,
    scale = 1,
    professionId = "jeweler",
    spawns = WO.Config.NPCSpawnPoints.work_jeweler or {},
    dialogue = "profession_work",
    quests = {},
    interactRange = WO.Config.InteractDistance,
})
