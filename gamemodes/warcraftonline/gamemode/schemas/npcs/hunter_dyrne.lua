--[[
    Warcraft Online — Охотник, последовательный quest giver охоты.
    Модель берётся из смонтированной расы человека; гражданского fallback нет.
]]

local humanModels = WO.Models.GetRace("human")

WO.NPCs.Register({
    id = "hunter_dyrne",
    name = "Охотник",
    type = "questgiver",

    model = WO.Workshop.NPCModelOr("wow_questgiver",
        humanModels.male and humanModels.male[1]),
    skin = 0,
    scale = 1,

    spawns = WO.Config.NPCSpawnPoints.hunter_dyrne or {},
    quests = { "wolves_of_elwynn", "boar_hunt" },
    interactRange = WO.Config.InteractDistance,
})
