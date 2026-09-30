--[[
    Warcraft Online — физический предмет в мире (SENT).

    wo_item_world — НЕ просто моделька на земле: у неё настоящая физика,
    она падает/катится/летит, ею можно толкать.

    Хранит:
        - Item UID (instance data — ТОЛЬКО на сервере, клиент не получает);
        - Item Class + имя (NW2 — для UI взаимодействия);
        - pickup cooldown (защита от мгновенного перехвата).

    Реализует единый Interaction-интерфейс:
        Entity:CanInteract(ply)
        Entity:GetInteractionText(ply)
        Entity:Interact(ply)
]]

-- Файл загружается и WO-загрузчиком, и движком — всегда начинаем с чистой таблицы.
ENT = {}

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "World Item"
ENT.Category = "Warcraft Online"
ENT.Author = "Warcraft Online Team"

ENT.Spawnable = false
ENT.AdminSpawnable = false

ENT.AutomaticFrameAdvance = true

---------------------------------------------------------------------------
-- Interaction-интерфейс
---------------------------------------------------------------------------

function ENT:CanInteract(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end

    -- Дистанция
    if ply:GetPos():Distance(self:GetPos()) > (WO.Config.InteractDistance or 100) then
        return false
    end

    -- Кулдаун подбора (после выбрасывания)
    if self.PickupCooldown and CurTime() < self.PickupCooldown then
        return false
    end

    -- Предмет должен существовать на сервере
    if SERVER and not istable(self.ItemInstance) then
        return false
    end

    return true
end

function ENT:GetInteractionText(ply)
    local itemName = self:GetNW2String("wo_item_name", "Item")

    return WO.Lang:Get("interact.pickup") .. ": " .. itemName
end

function ENT:Interact(ply)
    if SERVER then
        return WO.World.PickupItem(ply, self)
    end
end

---------------------------------------------------------------------------
-- Использование (E)
---------------------------------------------------------------------------

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    if not self:CanInteract(activator) then return end

    self:Interact(activator)
end

---------------------------------------------------------------------------
-- Инициализация
---------------------------------------------------------------------------

function ENT:Initialize()
    self:SetModel("models/props_junk/PopCan01a.mdl")

    if SERVER then
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)

        local phys = self:GetPhysicsObject()

        if IsValid(phys) then
            phys:Wake()
            phys:SetMass(5)
        end

        -- Автоматическое засыпание физики (оптимизация)
        self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

        self.CreatedAt = CurTime()
    end
end

---------------------------------------------------------------------------
-- Установка предмета (server)
---------------------------------------------------------------------------

--[[
    Привязывает item instance к entity. Вызывается только сервером.
]]
function ENT:SetItem(instance)
    if not istable(instance) then return false end

    self.ItemInstance = instance
    self.ItemUID = instance.uid

    local def = WO.Items.Get(instance.class)

    if def then
        if isstring(def.model) and def.model ~= "" then
            self:SetModel(def.model)
        end

        -- NW2: имя/класс — для UI клиента (instance data НЕ сетьуется!)
        self:SetNW2String("wo_item_class", instance.class)
        self:SetNW2String("wo_item_name", def.name or instance.class)
        self:SetNW2Int("wo_item_amount", instance.amount or 1)

        if SERVER then
            self:PhysicsInit(SOLID_VPHYSICS)
            self:SetMoveType(MOVETYPE_VPHYSICS)
            self:SetSolid(SOLID_VPHYSICS)

            local phys = self:GetPhysicsObject()

            if IsValid(phys) then
                phys:Wake()
            end
        end
    end

    -- Кулдаун подбора
    self.PickupCooldown = CurTime() + (WO.Config.ItemPickupCooldown or 1)

    return true
end

---------------------------------------------------------------------------
-- Физика: брошенный предмет должен реально лететь/падать
---------------------------------------------------------------------------

--[[
    Применяет импульс броска.
]]
function ENT:ApplyThrow(velocity)
    if SERVER then
        local phys = self:GetPhysicsObject()

        if IsValid(phys) then
            phys:Wake()
            phys:SetVelocity(velocity or vector_origin)
            phys:AddAngleVelocity(VectorRand() * 180)
        end
    end
end

---------------------------------------------------------------------------
-- Время жизни (очистка)
---------------------------------------------------------------------------

function ENT:Think()
    if SERVER then
        local lifetime = WO.Config.WorldItemLifetime or 0

        if lifetime > 0 and self.CreatedAt and (CurTime() - self.CreatedAt) > lifetime then
            -- Предмет истёк — удаляем (instance уходит в DESTROYED)
            if istable(self.ItemInstance) then
                WO.Items.SetState(self.ItemInstance, WO.Items.State.DESTROYED)
            end

            self:Remove()
            return
        end
    end

    -- Медленный think — физика сама засыпает
    self:NextThink(CurTime() + 5)

    return true
end

---------------------------------------------------------------------------
-- Регистрация сущности
---------------------------------------------------------------------------

scripted_ents.Register(ENT, "wo_item_world")
