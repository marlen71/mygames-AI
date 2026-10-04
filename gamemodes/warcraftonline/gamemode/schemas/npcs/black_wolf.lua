--[[
    Warcraft Online — враждебный волк из подтверждённого Workshop NPC-пака.
    Используется только точный runtime-класс wow_npc_14892; fallback-классов нет.
]]

WO.NPCs.Register({
    id = "black_wolf",
    name = "Волк",
    type = "creature",
    workshopClass = "wow_npc_14892",
    hostile = true,
    level = 1,
    minLevel = 1,
    maxLevel = 4,
    levelStats = {
        [1] = { health = 45, damage = 4 },
        [2] = { health = 62, damage = 5 },
        [3] = { health = 82, damage = 7 },
        [4] = { health = 106, damage = 9 },
    },
    attackRange = 96,
    sightRange = 900,
    interactRange = 0,
    loot = {
        currency = { min = 2, max = 5, chance = 0.80, levelScale = 0.05 },
        items = {
            { class = "wolf_pelt", chance = 0.42, levelScale = 0.035 },
            { class = "wolf_fang", chance = 0.28, levelScale = 0.025 },
            { class = "bread", chance = 0.07, levelScale = 0.01 },
            { class = "health_potion", chance = 0.025, levelScale = 0.008 },
            { class = "iron_sword", chance = 0.003, levelScale = 0.001 },
        },
    },
    spawns = WO.Config.NPCSpawnPoints.black_wolf or {},
})
