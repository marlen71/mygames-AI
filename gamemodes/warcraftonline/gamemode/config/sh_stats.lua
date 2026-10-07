--[[
    Warcraft Online — конфигурация характеристик и производных формул.
    Финальные статы собираются из: base (раса+класс) + level + equipment + buffs.
]]

---------------------------------------------------------------------------
-- Базовые характеристики
---------------------------------------------------------------------------

WO.Config.BaseStats = {
    strength = 8,
    agility = 8,
    intelligence = 8,
    stamina = 8,
    spirit = 8,
}

-- Прирост статов за уровень (базовый; классы могут переопределять)
WO.Config.StatsPerLevel = {
    strength = 1,
    agility = 1,
    intelligence = 1,
    stamina = 1,
    spirit = 1,
}

---------------------------------------------------------------------------
-- Производные характеристики (формулы)
---------------------------------------------------------------------------

WO.Config.StatFormulas = {
    -- Здоровье: база + стамина * множитель + уровень * рост
    maxHealth = function(stats)
        return math.floor(50 + stats.stamina * 10 + (stats.level or 1) * 5)
    end,

    -- Мана: интеллект + дух
    maxMana = function(stats)
        return math.floor(30 + stats.intelligence * 8 + (stats.level or 1) * 3)
    end,

    -- Выносливость
    maxStamina = function(stats)
        return math.floor(50 + stats.stamina * 6 + (stats.level or 1) * 2)
    end,

    -- Сила атаки (физический урон)
    attackPower = function(stats)
        return math.floor(stats.strength * 2 + stats.agility * 0.5 + (stats.level or 1))
    end,

    -- Сила заклинаний
    spellPower = function(stats)
        return math.floor(stats.intelligence * 2 + (stats.level or 1))
    end,

    -- Броня (снижение физического урона)
    armor = function(stats)
        return math.floor(stats.agility * 1.5 + stats.strength * 0.5)
    end,

    -- Сопротивление магии
    magicResistance = function(stats)
        return math.floor(stats.spirit * 1.2 + (stats.level or 1) * 0.5)
    end,

    -- Шанс крита (%) — 5% база + ловкость
    critChance = function(stats)
        return 5 + stats.agility * 0.1
    end,

    -- Множитель крита
    critMultiplier = function(stats)
        return 1.5
    end,

    -- Скорость атаки (множитель)
    attackSpeed = function(stats)
        return 1 + stats.agility * 0.005
    end,

    -- Скорость передвижения (не используется напрямую; см. движение)
    movementSpeed = function(stats)
        return (WO.Config.DefaultRunSpeed or 250) + stats.agility * 0.3
    end,
}

---------------------------------------------------------------------------
-- Регенерация (тик раз в секунду)
---------------------------------------------------------------------------

WO.Config.HealthRegen = function(stats)
    return math.max(1, math.floor(stats.spirit * 0.2))
end

WO.Config.ManaRegen = function(stats)
    return math.max(1, math.floor(stats.spirit * 0.3 + stats.intelligence * 0.1))
end

WO.Config.StaminaRegen = function(stats)
    return math.max(2, math.floor(stats.stamina * 0.3))
end

---------------------------------------------------------------------------
-- Редкость (id → отображаемое имя; цвета в sh_enums.lua)
---------------------------------------------------------------------------

WO.Config.RarityOrder = {
    "poor", "common", "uncommon", "rare", "epic", "legendary", "artifact", "quest",
}
