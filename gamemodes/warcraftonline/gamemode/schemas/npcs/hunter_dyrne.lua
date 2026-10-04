--[[
    Warcraft Online — охотник: выдаёт последовательные поручения на кабанов и волков.
    Точная WoW-модель пользователя; без гражданского fallback.
]]

WO.NPCs.Register({
    id = "hunter_dyrne",
    name = "Охотник",
    type = "questgiver",
    model = "models/mailer/wow_characters/wowanim_worgen_male.mdl",
    skin = 0,
    scale = 1,
    spawns = WO.Config.NPCSpawnPoints.hunter_dyrne or {},
    dialogue = "hunter_intro",
    quests = { "boar_hunt", "wolves_of_elwynn" },
    interactRange = WO.Config.InteractDistance,
})
