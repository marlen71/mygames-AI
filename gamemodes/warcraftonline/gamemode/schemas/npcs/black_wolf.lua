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
    xpReward = 44,
    xpPerLevel = 5,
    loot = {
        currency = { min = 2, max = 5, chance = 0.80, levelScale = 0.05 },
        themed = {
            chance = 0.82,
            levelScale = 0.015,
            items = {
                { class = "wolf_pelt", weight = 60 },
                { class = "wolf_fang", weight = 40 },
            },
        },
        rareItems = {
            { class = "health_potion", chance = 0.02, levelScale = 0.004 },
            { class = "iron_sword", chance = 0.003, levelScale = 0.001 },
            { class = "leather_helmet", chance = 0.002, levelScale = 0.001 },
            { class = "spell_scroll_firebolt_learn", chance = 0.001, levelScale = 0.0005 },
        },
    },
    spawns = WO.Config.NPCSpawnPoints.black_wolf or {},
})
