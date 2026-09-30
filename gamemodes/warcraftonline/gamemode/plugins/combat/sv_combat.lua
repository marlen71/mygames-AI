--[[
    Warcraft Online — боевая система (server): GMod-хуки.
]]

-- Маршрутизация стандартного урона через наш pipeline
hook.Add("EntityTakeDamage", "wo_combat_damage", function(target, dmginfo)
    if not IsValid(target) or not target:IsPlayer() then return end

    WO.Combat.ApplyEngineDamage(target, dmginfo)
end)

---------------------------------------------------------------------------
-- Уведомления о критах (опционально)
---------------------------------------------------------------------------

WO.Hook.Add("CombatPostDamage", "combat", function(info)
    if info.critical and IsValid(info.attacker) and info.attacker:IsPlayer() then
        WO.Notify(info.attacker, "combat", "CRIT " .. math.floor(info.amount))
    end
end)
