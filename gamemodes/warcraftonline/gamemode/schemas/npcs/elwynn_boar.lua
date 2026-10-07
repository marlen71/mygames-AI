--[[
    Warcraft Online — кабан из Creatures Megapack.
    Точный внешний класс wow_npc_2809 обязателен; при его отсутствии замены нет.
]]

WO.NPCs.Register({
    id = "elwynn_boar",
    name = "Элвиннский кабан",
    type = "creature",
    hostile = true,
    workshopClass = "wow_npc_2809",
    level = 1,
    minLevel = 1,
    maxLevel = 4,
    levelStats = {
        [1] = { health = 58, damage = 5 },
        [2] = { health = 78, damage = 7 },
        [3] = { health = 102, damage = 9 },
        [4] = { health = 132, damage = 11 },
    },
    attackRange = 96,
    interactRange = 0,
    xpReward = 44,
    xpPerLevel = 5,
    loot = {
        currency = { min = 100, max = 400, chance = 0.72, levelScale = 0.05 },
        themed = {
            chance = 0.86,
            levelScale = 0.012,
            items = {
                { class = "boar_meat", weight = 65, amount = 1 },
                { class = "boar_tusk", weight = 35 },
            },
        },
        rareItems = {
            { class = "health_potion", chance = 0.018, levelScale = 0.004 },
            { class = "iron_sword", chance = 0.002, levelScale = 0.001 },
            { class = "wooden_shield", chance = 0.0015, levelScale = 0.0005 },
            { class = "spell_scroll_water_bolt_learn", chance = 0.001, levelScale = 0.0005 },
        },
    },
    spawns = WO.Config.NPCSpawnPoints.elwynn_boar or {},
})
