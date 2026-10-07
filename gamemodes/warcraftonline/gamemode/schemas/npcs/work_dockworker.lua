--[[ Warcraft Online — работодатель ремесла «Портовый рабочий».
     Координаты намеренно не заданы: добавьте их в NPCSpawnPoints на целевой карте. ]]

WO.NPCs.Register({
    id = "work_dockworker",
    name = "Портовый рабочий",
    title = "Наставник ремесла",
    type = "talker",
    model = "models/mailer/wow_characters/wowanim_worgen_male.mdl",
    skin = 0,
    scale = 1,
    professionId = "dockworker",
    spawns = WO.Config.NPCSpawnPoints.work_dockworker or {},
    dialogue = "profession_work",
    quests = {},
    interactRange = WO.Config.InteractDistance,
})
