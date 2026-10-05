--[[ Warcraft Online — работодатель ремесла «Оружейник».
     Координаты намеренно не заданы: добавьте их в NPCSpawnPoints на целевой карте. ]]

WO.NPCs.Register({
    id = "work_weaponsmith",
    name = "Оружейник",
    title = "Наставник ремесла",
    type = "talker",
    model = "models/mailer/wow/character/dwarf/male/dwarfmale_01_00_hd.mdl",
    skin = 7,
    scale = 1,
    professionId = "weaponsmith",
    spawns = WO.Config.NPCSpawnPoints.work_weaponsmith or {},
    dialogue = "profession_work",
    quests = {},
    interactRange = WO.Config.InteractDistance,
})
