--[[
    Warcraft Online — server-authoritative spellbook SWEP.
    ПКМ открывает UI изучения/выбора, ЛКМ применяет серверно выбранное заклинание.
]]

SWEP = {}
SWEP.Base = "weapon_base"
SWEP.PrintName = "Книга стихий"
SWEP.Category = "Warcraft Online"
SWEP.Spawnable = false
SWEP.AdminSpawnable = false
SWEP.UseHands = true
SWEP.ViewModel = WO.Config.DefaultHandsModel or "models/weapons/c_arms.mdl"
SWEP.WorldModel = ""
SWEP.HoldType = "fist"
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.WOStarterLoadout = true
SWEP.Primary = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }
SWEP.Secondary = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }

function SWEP:Initialize()
    self:SetHoldType(self.HoldType or "fist")
end

function SWEP:Deploy()
    local owner = self:GetOwner()

    if SERVER and IsValid(owner) and WO.Spells and WO.Spells.Sync then
        WO.Spells.Sync(owner)
    end

    return true
end

local function PlayCastEffects(caster, spell, startPos, hitPos, target)
    if not spell then return end

    local element = WO.Config.SpellEffects and WO.Config.SpellEffects[spell.elementType]
    element = element or (WO.Config.SpellEffects and WO.Config.SpellEffects.life) or {}

    if IsValid(caster) and isstring(element.castSound) and element.castSound ~= "" then
        caster:EmitSound(element.castSound, 70, 100)
    end

    if IsValid(target) and isstring(element.impactSound) and element.impactSound ~= "" then
        target:EmitSound(element.impactSound, 68, 100)
    elseif IsValid(caster) and isstring(element.impactSound) and element.impactSound ~= "" then
        caster:EmitSound(element.impactSound, 60, 100)
    end

    if util and isfunction(util.Effect) and isfunction(EffectData) then
        local effectData = EffectData()
        effectData:SetOrigin(hitPos)

        if isfunction(effectData.SetScale) then
            effectData:SetScale(math.Clamp(tonumber(element.effectScale) or 1, 0.1, 2))
        end

        if isfunction(effectData.SetStart) then effectData:SetStart(startPos) end
        if IsValid(target) and isfunction(effectData.SetEntity) then effectData:SetEntity(target) end

        util.Effect(element.effect or "cball_explode", effectData, true, true)
    end
end

function SWEP:PrimaryAttack()
    local owner = self:GetOwner()

    if not IsValid(owner) or not owner:IsPlayer() then return end

    local now = CurTime()
    self:SetNextPrimaryFire(now + 0.35)

    if CLIENT then
        if owner == LocalPlayer() and isfunction(owner.SetAnimation) then
            owner:SetAnimation(PLAYER_ATTACK1)
        end
        return
    end

    if not WO.Spells or not WO.Spells.GetSelected then return end

    local character = owner:GetCharacter()
    local spellId = character and WO.Spells.GetSelected(character)

    if not spellId then
        WO.Notify(owner, "error", "Сначала изучите заклинание и выберите его ПКМ.")
        owner:EmitSound("buttons/button10.wav", 65, 95)
        return
    end

    local allowed, spell, rank = WO.Spells.CanCast(owner, spellId)

    if not allowed then
        WO.Notify(owner, "error", "Это заклинание ещё не изучено.")
        return
    end

    local cooldown = math.max(0.35, spell.cooldown - math.floor((rank - 1) / 4) * 0.1)

    if self._woNextSpellCast and self._woNextSpellCast > now then return end
    self._woNextSpellCast = now + cooldown
    self:SetNextPrimaryFire(now + cooldown)

    local manaCost = math.max(1, spell.manaCost - math.floor((rank - 1) / 4))

    if owner:GetMana() < manaCost then
        WO.Notify(owner, "error", "Недостаточно маны.")
        owner:EmitSound("buttons/button10.wav", 65, 95)
        return
    end

    if isfunction(owner.SetAnimation) then owner:SetAnimation(PLAYER_ATTACK1) end

    owner:LagCompensation(true)
    local startPos = owner:GetShootPos()
    local endPos = startPos + owner:GetAimVector() * spell.range
    local trace = util.TraceLine({
        start = startPos,
        endpos = endPos,
        filter = owner,
        mask = MASK_SHOT or MASK_SOLID,
    })
    owner:LagCompensation(false)

    local target = trace and trace.Entity or nil
    local hitPos = trace and trace.HitPos or endPos

    if spell.type == "heal" then
        if not IsValid(target) or not target:IsPlayer() or
            target:GetPos():Distance(owner:GetPos()) > spell.range then
            target = owner
        end
    elseif not IsValid(target) or (isfunction(target.IsWorld) and target:IsWorld()) then
        WO.Notify(owner, "info", "Заклинание не задело цель.")
        PlayCastEffects(owner, spell, startPos, hitPos, nil)
        return
    end

    owner:SetNW2Int("wo_mana", math.max(0, owner:GetMana() - manaCost))

    local applied, affected = WO.Spells.Apply(owner, spellId, target)

    if applied then
        PlayCastEffects(owner, spell, startPos, hitPos, affected)
    end
end

function SWEP:SecondaryAttack()
    local owner = self:GetOwner()

    if not IsValid(owner) then return end

    self:SetNextSecondaryFire(CurTime() + 0.4)

    if SERVER then
        if WO.Spells and WO.Spells.Sync then WO.Spells.Sync(owner) end
        return
    end

    if owner == LocalPlayer() and WO.Spells and isfunction(WO.Spells.OpenBook) then
        WO.Spells.OpenBook()
    end
end

function SWEP:Reload()
    -- Заклинания не расходуют боеприпасы.
end

WO.Weapons.Register(SWEP, "wo_magic_grimoire")
