--[[
    Warcraft Online — Железный меч (пример melee-оружия).
    Модель-плейсхолдер (crowbar) — заменяется на контент-модели через
    конфигурацию предмета и оружия.
]]

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

WO.Weapons.Register(SWEP, "wo_sword_iron")
