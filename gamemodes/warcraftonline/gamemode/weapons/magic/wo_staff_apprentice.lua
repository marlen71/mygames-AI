--[[
    Warcraft Online — Посох ученика (magic-оружие, урон arcane).
]]

SWEP = {}

SWEP.Base = "wo_base_melee"

SWEP.PrintName = "Apprentice Staff"
SWEP.Category = "Warcraft Online"

SWEP.WorldModel = "models/weapons/w_physics.mdl"
SWEP.ViewModel = "models/weapons/c_physics.mdl"
SWEP.HoldType = "melee"

SWEP.WODamage = 10
SWEP.WOAttackSpeed = 0.9
SWEP.WORange = 95
SWEP.WOStaminaCost = 3
SWEP.WODurabilityLoss = 0

-- Урон стафом — arcane
function SWEP:ApplyDamage(owner, target)
    local damage = self:CalculateDamage(owner)

    -- Сила заклинаний усиливает стаф
    damage = damage + (owner:GetStat("spellPower") or 0) * 0.3

    WO.Combat.Damage(owner, target, {
        amount = damage,
        type = WO.Enums.DamageType.ARCANE,
        weapon = self:GetClass(),
    })
end

if WO and WO.Weapons and WO.Weapons.Register then
    WO.Weapons.Register(SWEP, "wo_staff_apprentice")
else
    weapons.Register(SWEP, "wo_staff_apprentice")
end
