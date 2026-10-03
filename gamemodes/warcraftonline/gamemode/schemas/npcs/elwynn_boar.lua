--[[
    Warcraft Online — кабан из Creatures Megapack.
    Уровень и характеристики задаются явно для каждого map-spawn; случайного
    спавна и подмены другим NPC-классом нет.
]]

WO.NPCs.Register({
    id = "elwynn_boar",
    name = "Элвиннский кабан",
    type = "creature",
    hostile = true,
    workshopClass = WO.Workshop.RequestedNPCClasses.boar,
    level = 1,
    minLevel = 1,
    maxLevel = 5,
    levelStats = {
        [1] = { health = 58,  damage = 5 },
        [2] = { health = 78,  damage = 7 },
        [3] = { health = 102, damage = 9 },
        [4] = { health = 132, damage = 11 },
        [5] = { health = 168, damage = 14 },
    },
    attackRange = 96,
    interactRange = 0,
    spawns = WO.Config.NPCSpawnPoints.elwynn_boar or {},
})
