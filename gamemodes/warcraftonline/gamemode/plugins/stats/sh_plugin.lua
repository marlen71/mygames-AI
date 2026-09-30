--[[
    Warcraft Online — плагин характеристик.
    Статы собираются из: раса + класс + уровень + экипировка + баффы.
    НЕ хранить finalStats как единственный источник истины —
    финальные значения всегда пересчитываются из модификаторов.
]]

PLUGIN.name = "Stats"
PLUGIN.id = "stats"
PLUGIN.author = "Warcraft Online Team"
PLUGIN.version = "1.0.0"
PLUGIN.dependencies = { "races", "classes" }
PLUGIN.priority = 20
