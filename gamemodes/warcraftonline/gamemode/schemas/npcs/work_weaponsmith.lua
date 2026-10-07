--[[ Warcraft Online — работодатель ремесла «Оружейник».
     Координаты намеренно не заданы: добавьте их в NPCSpawnPoints на целевой карте. ]]

WO.NPCs.Register({
    id = "work_weaponsmith",
    name = "Оружейник",
    title = "Наставник ремесла",
    type = "talker",
    model = "models/mailer/wow_characters/wowanim_worgen_male.mdl",
    skin = 0,
    scale = 1,
    professionId = "weaponsmith",
    spawns = WO.Config.NPCSpawnPoints.work_weaponsmith or {},
    dialogue = "profession_work",
    quests = {},
    interactRange = WO.Config.InteractDistance,
})
