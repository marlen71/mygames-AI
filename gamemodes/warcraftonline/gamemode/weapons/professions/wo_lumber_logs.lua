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
SWEP.HoldType = "physgun"
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
    self:SetHoldType("physgun")
end

function SWEP:Deploy()
    self:SetHoldType("physgun")
    return true
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
