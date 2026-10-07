--[[ Warcraft Online — работодатель ремесла «Скотник».
     Координаты намеренно не заданы: добавьте их в NPCSpawnPoints на целевой карте. ]]

WO.NPCs.Register({
    id = "work_herder",
    name = "Скотник",
    title = "Наставник ремесла",
    type = "talker",
    model = "models/mailer/wow_characters/wowanim_worgen_male.mdl",
    skin = 0,
    scale = 1,
    professionId = "herder",
    spawns = WO.Config.NPCSpawnPoints.work_herder or {},
    dialogue = "profession_work",
    quests = {},
    interactRange = WO.Config.InteractDistance,
})
