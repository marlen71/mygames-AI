--[[
    Warcraft Online — тренировочный стартовый нож.
    Это собственный WO-SWEP: TFA/CS:O передаёт только проверенную модель, не урон.
]]

local config = WO.Config.StarterKnife or {}
local viewModel, worldModel = WO.Workshop.WeaponModelPair(
    "cso_part1",
    config.fallbackViewModel or "models/weapons/c_crowbar.mdl",
    config.fallbackWorldModel or "models/weapons/w_crowbar.mdl"
)

SWEP = {}
SWEP.Base = "wo_base_melee"
SWEP.PrintName = "Тренировочный нож"
SWEP.Category = "Warcraft Online"
SWEP.Spawnable = false
SWEP.AdminSpawnable = false
SWEP.UseHands = true
SWEP.ViewModel = viewModel
SWEP.WorldModel = worldModel
SWEP.HoldType = "knife"

SWEP.WODamage = config.damage or 6
SWEP.WOAttackSpeed = config.attackSpeed or 1.1
SWEP.WORange = config.range or 62
SWEP.WOStaminaCost = config.staminaCost or 2
SWEP.WODurabilityLoss = config.durabilityLoss or 1

SWEP.Primary = {
    ClipSize = -1,
    DefaultClip = -1,
    Automatic = false,
    Ammo = "none",
}

SWEP.Secondary = {
    ClipSize = -1,
    DefaultClip = -1,
    Automatic = false,
    Ammo = "none",
}

if WO and WO.Weapons and WO.Weapons.Register then
    WO.Weapons.Register(SWEP, "wo_knife_starter")
else
    weapons.Register(SWEP, "wo_knife_starter")
end
