--[[
    Warcraft Online — боевая система (server): GMod-хуки.
]]

-- Use a predictable, non-zero fall-damage curve (speed / 8, Source units).
-- The resulting engine damage is still routed through WO.Combat below.
hook.Add("GetFallDamage", "wo_realistic_fall_damage", function(ply, speed)
    if not IsValid(ply) or not isfunction(ply.IsPlayer) or not ply:IsPlayer() then
        return 0
    end

    return math.max(0, (tonumber(speed) or 0) / 8)
end)

-- Маршрутизация стандартного урона через наш pipeline
hook.Add("EntityTakeDamage", "wo_combat_damage", function(target, dmginfo)
    if not IsValid(target) or not target:IsPlayer() then return end

    WO.Combat.ApplyEngineDamage(target, dmginfo)
end)

---------------------------------------------------------------------------
-- Уведомления о критах (опционально)
---------------------------------------------------------------------------

local function IsDamageNumberTarget(target)
    if not IsValid(target) then return false end
    if isfunction(target.IsPlayer) and target:IsPlayer() then return true end
    if isfunction(target.IsNPC) and target:IsNPC() then return true end
    if target.WO_NPCDefinition ~= nil then return true end

    return isfunction(target.GetNW2String) and
        target:GetNW2String("wo_npc_id", "") ~= ""
end

local function GetDamageNumberPosition(target)
    local position = target:GetPos()
    local height = 52

    if isfunction(target.OBBMaxs) then
        local maximum = target:OBBMaxs()

        if isvector(maximum) then
            height = math.max(height, maximum.z + 10)
        end
    elseif isfunction(target.GetModelBounds) then
        local _, maximum = target:GetModelBounds()

        if isvector(maximum) then
            height = math.max(height, maximum.z + 10)
        end
    end

    return position + Vector(0, 0, math.Clamp(height, 52, 512))
end

local function SendDamageNumber(attacker, target, amount, critical)
    if not IsDamageNumberTarget(target) or not isfunction(target.GetPos) then return end

    amount = tonumber(amount) or 0
    if amount <= 0 then return end

    local data = {
        position = GetDamageNumberPosition(target),
        amount = amount,
        critical = critical == true,
    }
    local recipients = {}

    if IsValid(attacker) and isfunction(attacker.IsPlayer) and attacker:IsPlayer() then
        recipients[attacker] = true
    end

    if IsValid(target) and isfunction(target.IsPlayer) and target:IsPlayer() then
        recipients[target] = true
    end

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
