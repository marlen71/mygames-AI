--[[
    Warcraft Online — базовый магический импульс для первого уровня мага.
    На экране отображаются обычные c_arms, а атака создаёт тайный импульс.
]]

local config = WO.Config.ArcaneHands or {}

SWEP = {}
SWEP.Base = "wo_base_magic"
SWEP.PrintName = "Магические руки"
SWEP.Category = "Warcraft Online"
SWEP.Spawnable = false
SWEP.AdminSpawnable = false
SWEP.UseHands = true
SWEP.ViewModel = config.fallbackViewModel or WO.Config.DefaultHandsModel or "models/weapons/c_arms.mdl"
SWEP.WorldModel = ""
SWEP.HoldType = "fist"

SWEP.WODamage = config.damage or 7
SWEP.WORange = config.range or 480
SWEP.WOManaCost = config.manaCost or 5
SWEP.WOCooldown = config.cooldown or 1.15
SWEP.WOSpellPowerScale = config.spellPowerScale or 0.2
SWEP.WODamageType = WO.Enums.DamageType.ARCANE

if CLIENT and Material and render then
    local glowMaterial = Material("sprites/light_glow02_add")

    function SWEP:ViewModelDrawn(viewModel)
        if not IsValid(viewModel) then return end

        local handBone = viewModel:LookupBone("ValveBiped.Bip01_R_Hand")

        if not isnumber(handBone) or handBone < 0 then return end

        local handPosition = viewModel:GetBonePosition(handBone)

        if not isvector(handPosition) or handPosition == vector_origin then return end

        render.SetMaterial(glowMaterial)
        render.DrawSprite(handPosition, 13, 13, Color(110, 180, 255, 155))
    end
end

if WO and WO.Weapons and WO.Weapons.Register then
    WO.Weapons.Register(SWEP, "wo_arcane_hands")
else
    weapons.Register(SWEP, "wo_arcane_hands")
end
