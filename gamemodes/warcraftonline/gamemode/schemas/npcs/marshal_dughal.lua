--[[
    Warcraft Online — маршал Дугхал: провизия, маршрут охоты и приём отчётов.
    Точная WoW-модель пользователя; без гражданского fallback.
]]

WO.NPCs.Register({
    id = "marshal_dughal",
    name = "Маршал Дугхал",
    type = "questgiver",
    model = "models/mailer/wow_characters/wowanim_skyhunterNL.mdl",
    skin = 0,
    scale = 1,
    spawns = WO.Config.NPCSpawnPoints.marshal_dughal or {},
    dialogue = "marshal_intro",
    -- Story chain first; the repeatable bread delivery is offered when no main
    -- task is available (or after the story sequence has finished).
    quests = { "boar_hunt", "wolves_of_elwynn", "supplies_for_the_road" },
    interactRange = WO.Config.InteractDistance,
})
