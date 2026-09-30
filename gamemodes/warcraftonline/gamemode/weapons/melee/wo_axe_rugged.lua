--[[
    Warcraft Online — Грубый топор (пример melee-оружия, медленнее и сильнее).
]]

SWEP = {}

SWEP.Base = "wo_base_melee"

SWEP.PrintName = "Rugged Axe"
SWEP.Category = "Warcraft Online"

SWEP.WorldModel = "models/weapons/w_stunbaton.mdl"
SWEP.ViewModel = "models/weapons/c_stunbaton.mdl"
SWEP.HoldType = "melee"

SWEP.WODamage = 38
SWEP.WOAttackSpeed = 0.7
SWEP.WORange = 85
SWEP.WOStaminaCost = 8
SWEP.WODurabilityLoss = 1

if WO and WO.Weapons and WO.Weapons.Register then
    WO.Weapons.Register(SWEP, "wo_axe_rugged")
else
    weapons.Register(SWEP, "wo_axe_rugged")
end
