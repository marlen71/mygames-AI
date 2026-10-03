--[[
    Warcraft Online — Маршал Дугхал, стартовый квестодатель.
    Модель берётся из смонтированной расы человека, без гражданского fallback.
]]

local humanModels = WO.Models.GetRace("human")

WO.NPCs.Register({
    id = "marshal_dughal",
    name = "Маршал Дугхал",
    type = "questgiver",

    model = WO.Workshop.NPCModelOr("wow_questgiver",
        humanModels.male and humanModels.male[1]),
    skin = 0,
    scale = 1,

    spawns = WO.Config.NPCSpawnPoints.marshal_dughal or {},

    dialogue = "marshal_intro",
    quests = { "wolves_of_elwynn", "supplies_for_the_road" },

    interactRange = WO.Config.InteractDistance,
})
