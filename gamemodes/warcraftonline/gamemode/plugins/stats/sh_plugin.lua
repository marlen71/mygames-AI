--[[
    Warcraft Online — плагин характеристик.
    Статы собираются из: раса + класс + уровень + экипировка + баффы.
    НЕ хранить finalStats как единственный источник истины —
    финальные значения всегда пересчитываются из модификаторов.
]]

return {
    name = "Stats",
    id = "stats",
    author = "Warcraft Online Team",
    version = "1.0.0",
    dependencies = { "races", "classes" },
    priority = 20,
}
