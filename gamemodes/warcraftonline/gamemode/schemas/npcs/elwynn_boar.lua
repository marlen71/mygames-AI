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
    loot = {
        currency = { min = 1, max = 4, chance = 0.72, levelScale = 0.05 },
        items = {
            { class = "boar_meat", chance = 0.50, levelScale = 0.04, amount = 1 },
            { class = "boar_tusk", chance = 0.30, levelScale = 0.03 },
            { class = "health_potion", chance = 0.02, levelScale = 0.008 },
            { class = "iron_sword", chance = 0.002, levelScale = 0.001 },
        },
    },
    spawns = WO.Config.NPCSpawnPoints.elwynn_boar or {},
})
