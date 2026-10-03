--[[
    Warcraft Online — Маршал Дугхал, стартовый квестодатель.
    Workshop-модель используется только после проверки смонтированного NPC-ассета.
]]

WO.NPCs.Register({
    id = "marshal_dughal",
    name = "Маршал Дугхал",
    type = "questgiver",

    model = WO.Workshop.NPCModelOr("wow_questgiver", "models/player/Group01/male_02.mdl"),
    skin = 0,
    scale = 1,

    spawns = WO.Config.NPCSpawnPoints.marshal_dughal or {},

    dialogue = "marshal_intro",
    quests = { "wolves_of_elwynn", "supplies_for_the_road" },

    interactRange = 140,
})
