--[[ Warcraft Online — работодатель ремесла «Пивовар».
     Координаты намеренно не заданы: добавьте их в NPCSpawnPoints на целевой карте. ]]

WO.NPCs.Register({
    id = "work_brewer",
    name = "Пивовар",
    title = "Наставник ремесла",
    type = "talker",
    model = "models/mailer/character/gnome/male/gnomemale00_02_01.mdl",
    skin = 0,
    scale = 1,
    professionId = "brewer",
    spawns = WO.Config.NPCSpawnPoints.work_brewer or {},
    dialogue = "profession_work",
    quests = {},
    interactRange = WO.Config.InteractDistance,
})
