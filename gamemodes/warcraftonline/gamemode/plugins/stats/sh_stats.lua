--[[
    Warcraft Online — система характеристик (shared).

    Статы НЕ хранятся как единственный источник истины:
    финальные значения всегда собираются из модификаторов:

        base (раса + класс + уровень)
        + flat-модификаторы (экипировка, баффы)
        → умножаются на (1 + mult-модификаторы)
        → производные статы (формулы из config/sh_stats.lua)

    Пример:
        Base Strength = 10, Race = +2, Level = +5, Armor = +3, Buff = +4 → Final = 24
]]

local STATS = {}
STATS.__index = STATS

WO.Stats.Meta = STATS

-- Известные базовые характеристики
WO.Stats.PrimaryStats = {
    "strength", "agility", "intelligence", "stamina", "spirit",
}

-- Известные производные характеристики
WO.Stats.DerivedStats = {
    "maxHealth", "maxMana", "maxStamina",
    "attackPower", "spellPower", "armor", "magicResistance",
    "critChance", "critMultiplier", "attackSpeed", "movementSpeed",
}

--[[
    Создаёт объект статов для персонажа.

    @param char table персонаж
    @return table stats
]]
function WO.Stats.New(char)
    local stats = setmetatable({
        char = char,
        base = {},
        modifiers = {},
        final = {},
    }, STATS)

    return stats
end

--- Является ли объектом статов.
function WO.Stats.IsStats(obj)
    return istable(obj) and getmetatable(obj) == STATS
end

---------------------------------------------------------------------------
-- Модификаторы
---------------------------------------------------------------------------

--[[
    Устанавливает базовое значение стата.
]]
function STATS:SetBase(stat, value)
    self.base[stat] = tonumber(value) or 0
    self.dirty = true
end

--[[
    Добавляет модификатор стата.

    @param source string уникальный источник ("equipment:uid", "buff:poison", "level")
    @param stat string имя стата
    @param flat number|nil плоское прибавление
    @param mult number|nil множитель (0.1 = +10%)
]]
function STATS:AddModifier(source, stat, flat, mult)
    if not isstring(source) or not isstring(stat) then return end

    self.modifiers[source] = self.modifiers[source] or {}
    self.modifiers[source][stat] = {
        flat = tonumber(flat) or 0,
        mult = tonumber(mult) or 0,
    }

    self.dirty = true
end

--[[
    Удаляет все модификаторы источника.
]]
function STATS:RemoveModifiers(source)
    self.modifiers[source] = nil
    self.dirty = true
end

--[[
    Удаляет модификаторы всех источников с префиксом (например "equipment:").
]]
function STATS:RemoveModifiersByPrefix(prefix)
    for source in pairs(self.modifiers) do
        if string.sub(source, 1, #prefix) == prefix then
            self.modifiers[source] = nil
        end
    end

    self.dirty = true
end

---------------------------------------------------------------------------
-- Пересчёт
---------------------------------------------------------------------------

--- Пересчитывает финальные значения из базы + модификаторов + формул.
function STATS:Recalculate()
    local char = self.char
    local level = (char and char:GetLevel()) or 1

    -- Множество базовых статов для быстрого поиска
    local primarySet = {}

    for _, stat in ipairs(WO.Stats.PrimaryStats) do
        primarySet[stat] = true
    end

    -- Шаг 1: базовые статы + плоские модификаторы
    local totals = {}

    for _, stat in ipairs(WO.Stats.PrimaryStats) do
        totals[stat] = tonumber(self.base[stat]) or 0
    end

    for _, mods in pairs(self.modifiers) do
        for stat, mod in pairs(mods) do
            if primarySet[stat] then
                totals[stat] = (totals[stat] or 0) + (mod.flat or 0)
            end
        end
    end

    -- Шаг 2: множители (только базовые статы; derived — после формул)
    for _, mods in pairs(self.modifiers) do
        for stat, mod in pairs(mods) do
            if primarySet[stat] and mod.mult and mod.mult ~= 0 and totals[stat] then
                totals[stat] = totals[stat] * (1 + mod.mult)
            end
        end
    end

    -- Шаг 3: округление базовых
    for stat, value in pairs(totals) do
        totals[stat] = math.floor(value + 0.5)
    end

    totals.level = level

    -- Шаг 4: производные статы (формулы)
    for stat, formula in pairs(WO.Config.StatFormulas or {}) do
        local ok, value = pcall(formula, totals)

        if ok and isnumber(value) then
            totals[stat] = value
        else
            totals[stat] = totals[stat] or 0
            WO.Error("Stats formula failed for '" .. stat .. "': " .. tostring(value))
        end
    end

    -- Шаг 5: flat-модификаторы производных статов (после формул)
    for _, mods in pairs(self.modifiers) do
        for stat, mod in pairs(mods) do
            if not primarySet[stat] and totals[stat] ~= nil and (mod.flat or 0) ~= 0 then
                totals[stat] = totals[stat] + mod.flat
            end
        end
    end

    self.final = totals
    self.dirty = false

    return self.final
end

--- Возвращает финальное значение стата (пересчитывает при необходимости).
function STATS:Get(stat)
    if self.dirty then
        self:Recalculate()
    end

    return self.final[stat] or 0
end

--- Все финальные значения.
function STATS:GetAll()
    if self.dirty then
        self:Recalculate()
    end

    return self.final
end

--- Таблица для сетевой синхронизации.
function STATS:GetNetworkTable()
    local out = {}
    local all = self:GetAll()

    for stat, value in pairs(all) do
        out[stat] = value
    end

    return out
end

---------------------------------------------------------------------------
-- Сборка базы: раса + класс + уровень
---------------------------------------------------------------------------

--[[
    Пересобирает базовые статы из расы/класса/уровня (без экипировки).
]]
function STATS:RebuildBase()
    local char = self.char

    if not char then return end

    local level = char:GetLevel()
    local raceStats = WO.Races.GetStats(char.race)
    local classStats = WO.Classes.GetStats(char.class)
    local perLevel = WO.Config.StatsPerLevel or {}

    for _, stat in ipairs(WO.Stats.PrimaryStats) do
        local base = tonumber(raceStats[stat]) or (WO.Config.BaseStats and WO.Config.BaseStats[stat]) or 8
        local classBonus = tonumber(classStats[stat]) or 0
        local levelBonus = (tonumber(perLevel[stat]) or 0) * math.max(0, level - 1)

        self.base[stat] = base + classBonus + levelBonus
    end

    self.base.level = level
    self.dirty = true
end

---------------------------------------------------------------------------
-- API уровня модуля
---------------------------------------------------------------------------

--[[
    Полный пересчёт статов персонажа (база + экипировка + баффы).
    Вызывается после смены экипировки, уровня, баффов.
]]
function WO.Stats.Recalculate(char)
    if not WO.Character.IsCharacter(char) then return end

    if not WO.Stats.IsStats(char.stats) then
        char.stats = WO.Stats.New(char)
    end

    local stats = char.stats

    stats:RebuildBase()

    -- Экипировка: бонусы предметов
    if char.equipment and char.equipment.GetStats then
        stats:RemoveModifiersByPrefix("equipment:")

        local equipStats = char.equipment:GetStats()

        for source, values in pairs(equipStats) do
            for stat, value in pairs(values) do
                stats:AddModifier(source, stat, value, 0)
            end
        end
    end

    stats:Recalculate()

    return stats
end

---------------------------------------------------------------------------
-- Player helpers
---------------------------------------------------------------------------

local PLAYER = FindMetaTable("Player")

--- Возвращает финальный стат персонажа.
function PLAYER:GetStat(stat)
    local char = self:GetCharacter()

    if char and WO.Stats.IsStats(char.stats) then
        return char.stats:Get(stat)
    end

    return 0
end

--- Последний бой (для задержки регенерации).
function PLAYER:MarkCombat()
    self._woLastCombat = SysTime()
end

function PLAYER:InCombat()
    return self._woLastCombat ~= nil and (SysTime() - self._woLastCombat) < (WO.Config.CombatRegenDelay or 5)
end
