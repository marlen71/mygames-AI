--[[
    Warcraft Online — волк первого уровня, цель стартового kill-квеста.

    WO.Workshop ищет зарегистрированного NPC уровня 1 из Creature Megapack и
    принимает только реально смонтированную модель. При отсутствии аддона
    используется проверенный GMod fallback; права/урон/XP остаются в WO.
]]

WO.NPCs.Register({
    id = "black_wolf",
    name = "Волк (уровень 1)",
    type = "creature",
    hostile = true,
    level = 1,

    model = WO.Workshop.NPCModelOr("wow_wolf", "models/zombie/fast.mdl"),
    scale = 0.85,

    -- gm_construct имеет явную точку info_player_start; другие карты пусты,
    -- пока администратор не добавит map-specific spawn в конфигурацию.
    spawns = WO.Config.NPCSpawnPoints.black_wolf or {},

    health = 45,
    damage = 4,
    attackRange = 110,
    interactRange = 0,
})
