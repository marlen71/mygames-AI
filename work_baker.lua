--[[ Warcraft Online — работодатель ремесла «Пекарь».
     Координаты намеренно не заданы: добавьте их в NPCSpawnPoints на целевой карте. ]]

WO.NPCs.Register({
    id = "work_baker",
    name = "Пекарь",
    title = "Наставник ремесла",
    type = "talker",
    model = "models/mailer/character/gnome/male/gnomemale00_04_03.mdl",
    skin = 0,
    scale = 1,
    professionId = "baker",
    spawns = WO.Config.NPCSpawnPoints.work_baker or {},
    dialogue = "profession_work",
    quests = {},
    interactRange = WO.Config.InteractDistance,
})
