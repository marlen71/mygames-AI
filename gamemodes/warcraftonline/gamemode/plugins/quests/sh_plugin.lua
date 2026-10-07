--[[
    Warcraft Online — плагин квестов.
    Data-driven квесты (schemas/quests/): шаги kill/collect/talk, награды,
    персистентность (wo_quests), трекер в HUD, журнал на клавише J.
]]

return {
    name = "Quests",
    id = "quests",
    author = "Warcraft Online Team",
    version = "1.0.0",
    dependencies = { "character", "items", "inventory", "leveling", "currency" },
    priority = 60,
}
