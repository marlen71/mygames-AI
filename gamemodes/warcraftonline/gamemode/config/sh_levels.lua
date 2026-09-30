--[[
    Warcraft Online — таблица уровней и опыта.
]]

WO.Config.MaxLevel = 60

--[[
    Опыт, необходимый для перехода с level на level + 1.
    Можно задать таблицей: WO.Config.XPTable = { [2] = 400, [3] = 900, ... }
    Если таблицы нет — используется формула ниже.
]]

WO.Config.XPFormula = function(level)
    -- Опыта до следующего уровня: растёт с уровнем
    return math.floor(200 + (level - 1) * 150 + (level - 1) ^ 2 * 25)
end

--[[
    Возвращает количество опыта, необходимое для получения level + 1.

    @param level number текущий уровень
    @return number
]]
function WO.Config.GetXPForLevel(level)
    if WO.Config.XPTable and WO.Config.XPTable[level] then
        return WO.Config.XPTable[level]
    end

    return WO.Config.XPFormula(level)
end

-- Очки характеристик за уровень (в будущем — распределение игроком)
WO.Config.StatPointsPerLevel = 0
