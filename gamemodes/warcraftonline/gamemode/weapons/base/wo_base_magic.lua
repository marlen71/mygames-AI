--[[
    Warcraft Online — server-authoritative ranged magic SWEP base.

    Spell definitions set damage/range/cost in data/config. This base owns only
    input timing, mana validation, a server trace and the shared WO damage API.
]]

SWEP = {}
SWEP.Base = "weapon_base"
SWEP.PrintName = "WO Magic Base"
SWEP.Category = "Warcraft Online"
SWEP.Spawnable = false
SWEP.AdminSpawnable = false
SWEP.UseHands = true
SWEP.ViewModel = WO.Config.DefaultHandsModel or "models/weapons/c_arms.mdl"
SWEP.WorldModel = ""
SWEP.HoldType = "fist"

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

SWEP.WODamage = 7
SWEP.WORange = 480
SWEP.WOManaCost = 5
SWEP.WOCooldown = 1.15
SWEP.WOSpellPowerScale = 0.2
SWEP.WODamageType = WO.Enums.DamageType.ARCANE

function SWEP:Initialize()
    self:SetHoldType(self.HoldType or "fist")
end

function SWEP:CanCast(owner)
    if not IsValid(owner) or not owner:IsPlayer() or not owner:HasCharacter() then
        return false
    end

    local character = owner:GetCharacter()

    if not character or character.class ~= "mage" then
        return false
    end

    return owner:GetMana() >= (self.WOManaCost or 0)
end

function SWEP:PrimaryAttack()
    local owner = self:GetOwner()

    if not IsValid(owner) then return end

    local cooldown = math.max(0.1, tonumber(self.WOCooldown) or 1.15)
    self:SetNextPrimaryFire(CurTime() + cooldown)
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK or ACT_VM_HITCENTER)

    if owner.SetAnimation then
        owner:SetAnimation(PLAYER_ATTACK1)
    end

    if CLIENT then return end

    if not self:CanCast(owner) then
        owner:EmitSound("buttons/button10.wav", 65, 95)
        return
    end

    local manaCost = math.max(0, math.floor(tonumber(self.WOManaCost) or 0))
    local manaAfterCast = math.max(0, owner:GetMana() - manaCost)
    owner:SetNW2Int("wo_mana", manaAfterCast)

    owner:LagCompensation(true)

    local startPos = owner:GetShootPos()
    local endPos = startPos + owner:GetAimVector() * math.max(32, tonumber(self.WORange) or 480)
    local trace = util.TraceLine({
        start = startPos,
        endpos = endPos,
        filter = owner,
        mask = MASK_SHOT,
    })

    owner:LagCompensation(false)
    self:EmitSound("ambient/energy/zap1.wav", 70, 115)

    if not trace or not IsValid(trace.Entity) then return end

    local spellPower = owner:GetStat("spellPower") or 0
    local damage = math.max(1, (tonumber(self.WODamage) or 7) +
        spellPower * (tonumber(self.WOSpellPowerScale) or 0.2))

    WO.Combat.Damage(owner, trace.Entity, {
        amount = damage,
        type = self.WODamageType or WO.Enums.DamageType.ARCANE,
        weapon = self:GetClass(),
        canCrit = false,
    })

    if EffectData and util.Effect then
        local effect = EffectData()
        effect:SetOrigin(trace.HitPos or trace.Entity:GetPos())
        util.Effect("cball_bounce", effect, true, true)
    end
end

function SWEP:SecondaryAttack()
    -- Зарезервировано под будущие заклинания; серверных изменений нет.
end

function SWEP:Reload()
    -- У магического импульса нет перезарядки боеприпасов.
end

if WO and WO.Weapons and WO.Weapons.Register then
    WO.Weapons.Register(SWEP, "wo_base_magic")
else
    weapons.Register(SWEP, "wo_base_magic")
end
