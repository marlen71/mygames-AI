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

local function SendDamageNumber(attacker, target, amount, critical)
    if not IsValid(target) or not isfunction(target.GetPos) then return end

    local position = target:GetPos() + Vector(0, 0, 52)
    local data = {
        position = position,
        amount = math.max(0, tonumber(amount) or 0),
        critical = critical == true,
    }
    local recipients = {}

    if IsValid(attacker) and attacker:IsPlayer() then recipients[attacker] = true end
    if IsValid(target) and target:IsPlayer() then recipients[target] = true end

    for recipient in pairs(recipients) do
        WO.Net.Send("Combat.DamageNumber", recipient, data)
    end
end

WO.Hook.Add("CombatPostDamage", "combat", function(info)
    if info.critical and IsValid(info.attacker) and info.attacker:IsPlayer() then
        WO.Notify(info.attacker, "combat", "CRIT " .. math.floor(info.amount))
    end

    SendDamageNumber(info.attacker, info.target, info.amount, info.critical)
end)

-- External SWEPs may apply engine damage directly to Workshop NPCs instead of
-- calling WO.Combat.Damage. Report only damage that the engine really applied;
-- our WO pipeline routes player damage separately and is not double-counted here.
hook.Add("PostEntityTakeDamage", "wo_combat_engine_damage_feedback", function(target, damageInfo, wasDamageTaken)
    if wasDamageTaken ~= true or not IsValid(target) or not damageInfo or
        not isfunction(damageInfo.GetDamage) then return end

    local amount = tonumber(damageInfo:GetDamage()) or 0
    if amount <= 0 then return end

    local inflictor = isfunction(damageInfo.GetInflictor) and damageInfo:GetInflictor() or nil
    if IsValid(inflictor) and inflictor.WODamage then return end

    local attacker = isfunction(damageInfo.GetAttacker) and damageInfo:GetAttacker() or nil
    SendDamageNumber(attacker, target, amount, false)
end)
