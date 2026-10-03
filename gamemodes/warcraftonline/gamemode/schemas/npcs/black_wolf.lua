--[[
    Warcraft Online — Fang (Клык), цель стартового kill-квеста.

    Используется только точный класс Creatures Megapack. Без регистрации класса
    сущность не спавнится: никакой подмены зомби/стоковой моделью.
]]

WO.NPCs.Register({
    id = "black_wolf",
    name = "Клык",
    type = "creature",
    hostile = true,
    workshopClass = WO.Workshop.RequestedNPCClasses.fang,
    level = 1,
    minLevel = 1,
    maxLevel = 5,
    levelStats = {
        [1] = { health = 45,  damage = 4 },
        [2] = { health = 62,  damage = 5 },
        [3] = { health = 82,  damage = 6 },
        [4] = { health = 106, damage = 8 },
        [5] = { health = 134, damage = 10 },
    },
    attackRange = 110,
    interactRange = 0,
    spawns = WO.Config.NPCSpawnPoints.black_wolf or {},
})
