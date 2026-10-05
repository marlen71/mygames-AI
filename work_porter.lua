--[[ Warcraft Online — работодатель ремесла «Грузчик».
     Координаты намеренно не заданы: добавьте их в NPCSpawnPoints на целевой карте. ]]

WO.NPCs.Register({
    id = "work_porter",
    name = "Грузчик",
    title = "Наставник ремесла",
    type = "talker",
    model = "models/mailer/character/tauren/male/taurenmale00_04.mdl",
    skin = 14,
    scale = 1,
    professionId = "porter",
    spawns = WO.Config.NPCSpawnPoints.work_porter or {},
    dialogue = "profession_work",
    quests = {},
    interactRange = WO.Config.InteractDistance,
})
