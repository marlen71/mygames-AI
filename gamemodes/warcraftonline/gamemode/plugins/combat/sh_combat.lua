--[[
    Warcraft Online — боевая система (shared).
    Структура урона и pipeline-хуки.

    Damage info:
        {
            attacker = entity,
            target = entity,
            amount = 25,
            type = "physical",     -- WO.Enums.DamageType
            critical = false,
            canCrit = true,        -- false отключает критический roll для данного удара
            ability = nil,         -- id способности (будущее)
            weapon = nil,          -- item class / SWEP
        }

    Pipeline (хуки WO.Hook):
        CombatPreDamage     (info)                → можно отменить (return false)
        CombatCalculate     (info)                → изменить info.amount
        CombatResistance    (info, resistance)    → сопротивление
        CombatCritical      (info)                → критический удар
        CombatModifiers     (info)                → модификаторы (баффы)
        CombatFinalDamage   (info)                → финальное значение
        CombatPostDamage    (info)                → после применения
]]

WO.Combat = WO.Combat or {}

WO.Net.Register("Combat.DamageNumber", {
    direction = "toclient",
    write = function(data)
        net.WriteTable(data or {})
    end,
    read = function()
        return net.ReadTable()
    end,
    handler = function(_, data)
        if CLIENT and WO.HUD and WO.HUD.AddDamageNumber then
            WO.HUD.AddDamageNumber(data)
        end
    end,
})

---------------------------------------------------------------------------
-- Сопротивления
---------------------------------------------------------------------------

-- Статы сопротивления по типам урона
local RESIST_STATS = {
    physical = "armor",
    fire = "magicResistance",
    frost = "magicResistance",
    arcane = "magicResistance",
    nature = "magicResistance",
    shadow = "magicResistance",
    holy = "magicResistance",
    poison = "magicResistance",
}

--[[
    Рассчитывает снижение урона сопротивлением (базовая броня).

    @param target Entity
    @param damageType string
    @return number множитель (0.5 = урон уменьшен вдвое)
]]
function WO.Combat.GetResistanceMultiplier(target, damageType)
    if not IsValid(target) or not target:IsPlayer() then
        return 1
    end

    local statName = RESIST_STATS[damageType] or "armor"
    local resist = target:GetStat(statName) or 0

    -- Формула: reduction = resist / (resist + K)
    local K = damageType == "physical" and 400 or 500
    local reduction = resist / (resist + K)

    return math.max(0.1, 1 - reduction)
end

---------------------------------------------------------------------------
-- Критический удар
---------------------------------------------------------------------------

--[[
    Определяет критический удар атакующего.

    @param attacker Entity
    @return boolean
]]
function WO.Combat.RollCritical(attacker)
    if not IsValid(attacker) or not attacker:IsPlayer() then
        return false
    end

    local chance = attacker:GetStat("critChance") or 5

    return math.Rand(0, 100) <= chance
end

---------------------------------------------------------------------------
-- Damage pipeline (выполняется на сервере)
---------------------------------------------------------------------------

--[[
    Наносит урон цели через полный pipeline.

    @param attacker Entity|nil
    @param target Entity
    @param info table { amount, type, critical, canCrit, ability, weapon }
    @return boolean applied, number finalDamage
]]
function WO.Combat.Damage(attacker, target, info)
    if not IsValid(target) then return false, 0 end

    info = info or {}
    info.attacker = attacker
    info.target = target
    info.amount = tonumber(info.amount) or 0
    info.type = info.type or WO.Enums.DamageType.PHYSICAL

    if info.amount <= 0 then return false, 0 end

    -- Защита от чрезмерного урона (анти-эксплойт)
    if info.amount > 1000000 then
        WO.Warn("Suspicious damage amount: " .. info.amount)
        return false, 0
    end

    -- 1. PreDamage — можно отменить
    local preResults = WO.Hook.Run("CombatPreDamage", info)

    for _, result in ipairs(preResults) do
        if result == false then
            return false, 0
        end
    end

    -- PvP-правила
    if IsValid(attacker) and attacker:IsPlayer() and target:IsPlayer() then
        if WO.Config.PvPEnabled == false then
            return false, 0
        end
    end

    -- Цель должна быть живой
    if target:Health() <= 0 then
        return false, 0
    end

    -- 2. Calculate — базовый расчёт
    WO.Hook.Run("CombatCalculate", info)

    -- 3. Resistance
    local multiplier = WO.Combat.GetResistanceMultiplier(target, info.type)

    WO.Hook.Run("CombatResistance", info, multiplier)

    info.amount = info.amount * multiplier

    -- 4. Critical. canCrit=false is authoritative for magic/NPC hits; an explicit
    -- critical=false must not be re-rolled into a critical strike.
    if info.canCrit == false then
        info.critical = false
    elseif info.critical == nil then
        info.critical = IsValid(attacker) and WO.Combat.RollCritical(attacker) or false
    else
        info.critical = info.critical == true
    end

    if info.critical then
        local critMult = 1.5

        if IsValid(attacker) and attacker:IsPlayer() then
            critMult = tonumber(attacker:GetStat("critMultiplier")) or critMult
        end

        info.amount = info.amount * critMult

        WO.Hook.Run("CombatCritical", info)
    end

    -- 5. Modifiers (баффы/дебаффы)
    WO.Hook.Run("CombatModifiers", info)

    -- 6. Final
    info.amount = math.max(1, math.floor(info.amount))

    WO.Hook.Run("CombatFinalDamage", info)

    -- Применяем урон
    local currentHealth = target:Health()
    local newHealth = math.max(0, currentHealth - info.amount)

    target:SetHealth(newHealth)

    -- Отметка боя (задержка регенерации)
    if target:IsPlayer() and target.MarkCombat then
        target:MarkCombat()
    end

    if IsValid(attacker) and attacker:IsPlayer() and attacker.MarkCombat then
        attacker:MarkCombat()
    end

    -- 7. PostDamage
    WO.Hook.Run("CombatPostDamage", info)

    -- Смерть
    if newHealth <= 0 then
        if target:IsPlayer() then
            target:Kill() -- вызовет PlayerDeath
        else
            -- Сущность может взять на себя визуальную/отложенную смерть (например,
            -- собственная анимация NPC). Lifecycle-hook остаётся общим и не связан
            -- с конкретным плагином.
            local deathHandled = false

            if isfunction(target.OnWOCombatKilled) then
                local ok, handled = pcall(target.OnWOCombatKilled, target, attacker, info)
                deathHandled = ok and handled == true
            end

            WO.Hook.Run("EntityKilled", target, attacker, info)

            if IsValid(target) and not deathHandled then
                target:Remove()
            end
        end
    end

    return true, info.amount
end

---------------------------------------------------------------------------
-- Смерть от падения и прочего (маршрутизируем через pipeline)
---------------------------------------------------------------------------

function WO.Combat.ApplyEngineDamage(target, dmginfo)
    if not IsValid(target) or not target:IsPlayer() then return end

    local amount = dmginfo:GetDamage()
    local attacker = dmginfo:GetAttacker()
    local inflictor = dmginfo:GetInflictor()

    if amount <= 0 then return end

    -- SWEP-урон обрабатывается нашим pipeline напрямую — пропускаем
    if IsValid(inflictor) and inflictor.WODamage then
        dmginfo:SetDamage(0)
        return
    end

    dmginfo:SetDamage(0)

    local damageType = WO.Enums.DamageType.PHYSICAL

    if dmginfo:IsDamageType(DMG_FALL) then
        damageType = WO.Enums.DamageType.PHYSICAL
    elseif dmginfo:IsDamageType(DMG_BURN) then
        damageType = WO.Enums.DamageType.FIRE
    elseif dmginfo:IsDamageType(DMG_SHOCK) then
        damageType = WO.Enums.DamageType.NATURE
    end

    WO.Combat.Damage(IsValid(attacker) and attacker or nil, target, {
        amount = amount,
        type = damageType,
    })
end
