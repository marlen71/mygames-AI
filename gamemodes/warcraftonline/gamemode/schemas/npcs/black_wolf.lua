--[[
    Warcraft Online — NPC: чёрный волк (враждебное существо, цель квестов).

    Если подписан аддон «Black Wolf PlayerModel» (2080218553) из коллекции
    сервера и его .mdl указан в config/sh_workshop.lua — используется он.
    Иначе — временная стоковая модель (зомби-быстрый, HL2-контент GMod).
]]

WO.NPCs.Register({
    id = "black_wolf",
    name = "Чёрный волк",
    type = "creature",
    hostile = true,

    model = WO.Workshop.ModelOr("black_wolf", "models/zombie/fast.mdl"),
    scale = 0.85,

    spawns = {},

    health = 120,
    damage = 8,
    attackRange = 140,
    interactRange = 0,

    noAutoSpawn = false,
})
