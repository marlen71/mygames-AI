--[[
    Warcraft Online — рабочая связка брёвен лесоруба.
    Выдаётся только сервером после мини-игры у лесного штабеля.
]]

local worksite = WO.Config.ProfessionWorksites.lumberjack

SWEP = {}
SWEP.Base = "weapon_base"
SWEP.PrintName = "Связка брёвен"
SWEP.Category = "Warcraft Online"
SWEP.Spawnable = false
SWEP.AdminSpawnable = false
SWEP.UseHands = true
SWEP.ViewModel = ""
SWEP.WorldModel = worksite.carryModel
SWEP.HoldType = "shotgun"
SWEP.WOLumberCarryForwardOffset = 18
SWEP.WOLumberCarryHeightOffset = -8
SWEP.WOLumberCarryYawOffset = 90
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
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

function SWEP:Initialize()
    self:SetHoldType("shotgun")
end

function SWEP:Deploy()
    self:SetHoldType("shotgun")
    return true
end

function SWEP:DrawWorldModel()
    local owner = self:GetOwner()
    if not IsValid(owner) then
        self:DrawModel()
        return
    end

    local origin
    if isfunction(owner.LookupBone) and isfunction(owner.GetBonePosition) then
        local spineBone = owner:LookupBone("ValveBiped.Bip01_Spine2")
        if isnumber(spineBone) and spineBone >= 0 then
            local spinePosition = owner:GetBonePosition(spineBone)
            if isvector(spinePosition) and spinePosition ~= vector_origin then
                origin = spinePosition
            end
        end
    end

    if not isvector(origin) and isfunction(owner.WorldSpaceCenter) then
        origin = owner:WorldSpaceCenter()
    end
    if not isvector(origin) then
        origin = owner:GetPos() + Vector(0, 0, 48)
    end

    local ownerAngles = isfunction(owner.EyeAngles) and owner:EyeAngles() or owner:GetAngles()
    local yaw = tonumber(ownerAngles and ownerAngles.y) or 0
    local facing = Angle(0, yaw, 0)
    origin = origin + facing:Forward() * (self.WOLumberCarryForwardOffset or 18) +
        Vector(0, 0, self.WOLumberCarryHeightOffset or -8)

    self:SetRenderOrigin(origin)
    self:SetRenderAngles(Angle(0, yaw + (self.WOLumberCarryYawOffset or 90), 0))
    self:DrawModel()
    self:SetRenderOrigin()
    self:SetRenderAngles()
end

function SWEP:PrimaryAttack() end
function SWEP:SecondaryAttack() end
function SWEP:Reload() end
function SWEP:CanDrop() return false end
function SWEP:ShouldDropOnDie() return false end

function SWEP:CanHolster()
    if SERVER and WO.Professions and isfunction(WO.Professions.IsCarryingLumber) then
        local owner = self:GetOwner()
        if IsValid(owner) and WO.Professions.IsCarryingLumber(owner) then
            return false
        end
    end

    return true
end

if WO and WO.Weapons and WO.Weapons.Register then
    WO.Weapons.Register(SWEP, worksite.carryWeaponClass)
else
    weapons.Register(SWEP, worksite.carryWeaponClass)
end
