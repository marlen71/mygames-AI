--[[ Warcraft Online — работодатель ремесла «Строитель».
     Координаты намеренно не заданы: добавьте их в NPCSpawnPoints на целевой карте. ]]

WO.NPCs.Register({
    id = "work_builder",
    name = "Строитель",
    title = "Наставник ремесла",
    type = "talker",
    model = "models/mailer/wow_characters/wowanim_worgen_male.mdl",
    skin = 0,
    scale = 1,
    professionId = "builder",
    spawns = WO.Config.NPCSpawnPoints.work_builder or {},
    dialogue = "profession_work",
    quests = {},
    interactRange = WO.Config.InteractDistance,
})
