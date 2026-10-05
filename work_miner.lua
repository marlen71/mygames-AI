--[[ Warcraft Online — работодатель ремесла «Шахтёр».
     Координаты намеренно не заданы: добавьте их в NPCSpawnPoints на целевой карте. ]]

WO.NPCs.Register({
    id = "work_miner",
    name = "Шахтёр",
    title = "Наставник ремесла",
    type = "talker",
    model = "models/mailer/character/human/male/humanmale00_09_02.mdl",
    skin = 46,
    scale = 1,
    professionId = "miner",
    spawns = WO.Config.NPCSpawnPoints.work_miner or {},
    dialogue = "profession_work",
    quests = {},
    interactRange = WO.Config.InteractDistance,
})
