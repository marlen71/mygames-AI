--[[
    Warcraft Online — Железный меч (пример melee-оружия).
    Модель-плейсхолдер (crowbar) — заменяется на контент-модели через
    конфигурацию предмета и оружия.
]]

SWEP = {}

SWEP.Base = "wo_base_melee"

SWEP.PrintName = "Iron Sword"
SWEP.Category = "Warcraft Online"

SWEP.WorldModel = "models/weapons/w_crowbar.mdl"
SWEP.ViewModel = "models/weapons/c_crowbar.mdl"
SWEP.HoldType = "melee"

SWEP.WODamage = 25
SWEP.WOAttackSpeed = 1.0
SWEP.WORange = 85
SWEP.WOStaminaCost = 5
SWEP.WODurabilityLoss = 1

if WO and WO.Weapons and WO.Weapons.Register then
    WO.Weapons.Register(SWEP, "wo_sword_iron")
else
    weapons.Register(SWEP, "wo_sword_iron")
end
