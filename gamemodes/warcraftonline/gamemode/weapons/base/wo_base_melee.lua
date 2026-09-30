--[[
    Warcraft Online — базовый класс ближнего оружия (SWEP).
    Все melee-оружие наследуется от него.

    Поддерживает:
        damage, attackSpeed, range, crit (через Stats),
        staminaCost, durability, требования, анимации, звуки.
]]

-- Файл загружается и WO-загрузчиком, и движком — всегда начинаем с чистой таблицы.
SWEP = {}

SWEP.Base = "weapon_base"

SWEP.PrintName = "WO Melee Base"
SWEP.Category = "Warcraft Online"
SWEP.Author = "Warcraft Online Team"
SWEP.Purpose = "Base class for Warcraft Online melee weapons"

SWEP.Spawnable = false
SWEP.AdminSpawnable = false

SWEP.WorldModel = "models/weapons/w_crowbar.mdl"
SWEP.HoldType = "melee"

SWEP.AutoSwitchTo = true
SWEP.AutoSwitchFrom = false

SWEP.Primary = {}
SWEP.Secondary = {}

-- Боевые параметры (переопределяются потомками)
SWEP.WODamage = 15               -- базовый урон
SWEP.WOAttackSpeed = 1.0         -- множитель скорости атаки
SWEP.WORange = 80                -- дальность удара
SWEP.WOStaminaCost = 5           -- расход выносливости за удар
SWEP.WODurabilityLoss = 1        -- потеря прочности за удар (0 = не ломается)

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

---------------------------------------------------------------------------
-- Инициализация
---------------------------------------------------------------------------

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

---------------------------------------------------------------------------
-- Проверки возможности атаки
---------------------------------------------------------------------------

function SWEP:CanAttack()
    local owner = self:GetOwner()

    if not IsValid(owner) or not owner:IsPlayer() then
        return false
    end

    if not owner:HasCharacter() then
        return false
    end

    -- Выносливость
    if self.WOStaminaCost > 0 and owner:GetStamina() < self.WOStaminaCost then
        return false
    end

    -- Прочность: сломанное оружие не атакует
    if self.WODurability and self.WODurability <= 0 then
        return false
    end

    return true
end

---------------------------------------------------------------------------
-- Расчёт урона
---------------------------------------------------------------------------

function SWEP:CalculateDamage(owner)
    local damage = self.WODamage or 15

    -- Сила атаки усиливает урон
    local attackPower = owner:GetStat("attackPower") or 0

    damage = damage + attackPower * 0.35

    -- Множитель скорости атаки не влияет на урон — влияет на темп

    return damage
end

---------------------------------------------------------------------------
-- Применение урона
---------------------------------------------------------------------------

function SWEP:ApplyDamage(owner, target)
    local damage = self:CalculateDamage(owner)

    WO.Combat.Damage(owner, target, {
        amount = damage,
        type = WO.Enums.DamageType.PHYSICAL,
        weapon = self:GetClass(),
    })

    -- Потеря прочности оружия
    if self.WODurabilityLoss > 0 then
        self:ConsumeDurability(self.WODurabilityLoss)
    end
end

---------------------------------------------------------------------------
-- Прочность
---------------------------------------------------------------------------

function SWEP:ConsumeDurability(amount)
    local owner = self:GetOwner()

    if not IsValid(owner) then return end

    -- Прочность хранится в item instance (equipment), не в SWEP
    local char = owner:GetCharacter()
    local equipment = char and WO.Equipment.Get and WO.Equipment.Get(char)

    if not equipment then return end

    for _, slotId in ipairs({ "main_hand", "off_hand" }) do
        local instance = equipment:Get(slotId)

        if instance and instance.uid == self.WOItemUID then
            if instance.durability ~= nil then
                WO.Equipment.ReduceDurability(owner, slotId, amount)
                self.WODurability = instance.durability
            end

            break
        end
    end
end

---------------------------------------------------------------------------
-- Атака
---------------------------------------------------------------------------

function SWEP:PrimaryAttack()
    local owner = self:GetOwner()

    if not self:CanAttack() then return end

    -- Кулдаун = базовая скорость атаки (0.6-1.2 сек)
    local delay = 0.8 / math.max(0.1, (self.WOAttackSpeed or 1) * (1 + ((owner:GetStat("attackSpeed") or 1) - 1)))

    self:SetNextPrimaryFire(CurTime() + delay)

    -- Расход выносливости
    if self.WOStaminaCost > 0 then
        owner:SetNW2Int("wo_stamina", math.max(0, owner:GetStamina() - self.WOStaminaCost))
    end

    -- Анимация и звук
    self:SendWeaponAnim(ACT_VM_HITCENTER)

    if owner.SetAnimation then
        owner:SetAnimation(PLAYER_ATTACK1)
    end

    self:EmitSound("weapons/crowbar/crowbar_swing" .. math.random(1, 2) .. ".wav", 75, 100)

    -- Melee-trace
    owner:LagCompensation(true)

    local startPos = owner:GetShootPos()
    local trace = {
        start = startPos,
        endpos = startPos + owner:GetAimVector() * (self.WORange or 80),
        filter = owner,
        mask = MASK_SHOT_HULL,
    }

    local tr = util.TraceLine(trace)

    if not IsValid(tr.Entity) then
        -- Расширенный hull-trace (проще попасть)
        tr = util.TraceHull({
            start = startPos,
            endpos = startPos + owner:GetAimVector() * (self.WORange or 80),
            filter = owner,
            mins = Vector(-8, -8, -8),
            maxs = Vector(8, 8, 8),
            mask = MASK_SHOT_HULL,
        })
    end

    owner:LagCompensation(false)

    if IsValid(tr.Entity) then
        self:EmitSound("weapons/crowbar/crowbar_hit" .. math.random(1, 2) .. ".wav", 75, 100)

        if tr.Entity.TakeDamage then
            self:ApplyDamage(owner, tr.Entity)
        end
    end
end

function SWEP:SecondaryAttack()
    -- Заглушка: блок/парирование — будущее
end

function SWEP:Reload()
    -- Нет перезарядки
end

-- Регистрация (загрузчик WO или движок — файл самодостаточен)
if WO and WO.Weapons and WO.Weapons.Register then
    WO.Weapons.Register(SWEP, "wo_base_melee")
else
    weapons.Register(SWEP, "wo_base_melee")
end
