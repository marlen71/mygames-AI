--[[
    Warcraft Online — физическая кучка монет из NPC-добычи.
    Сумма хранится только на сервере; E подбирает её по общей дальности.
]]

ENT = {}
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "WO Loot Coins"
ENT.Category = "Warcraft Online"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:CanInteract(ply)
    return IsValid(ply) and ply:IsPlayer() and ply:HasCharacter() and
        ply:GetPos():Distance(self:GetPos()) <= WO.Interaction.GetRange(self) and
        (not self.PickupCooldown or CurTime() >= self.PickupCooldown) and
        (SERVER and (tonumber(self.WOCoinAmount) or 0) > 0 or CLIENT)
end

function ENT:GetInteractionText()
    return "Подобрать монеты: " .. tostring(self:GetNW2Int("wo_coin_amount", 0))
end

function ENT:Interact(ply)
    if SERVER and WO.World and WO.World.PickupCoins then
        return WO.World.PickupCoins(ply, self)
    end
end

function ENT:Use(activator)
    if not IsValid(activator) or not WO.Interaction or
        not isfunction(WO.Interaction.TryInteract) then return end

    WO.Interaction.TryInteract(activator, self)
end

function ENT:Initialize()
    self:SetModel("models/props_junk/metal_paintcan001a.mdl")

    if SERVER then
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        self:SetColor(Color(226, 184, 54, 255))
        self:SetModelScale(0.38, 0)
        self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    end
end

function ENT:SetCoinAmount(amount)
    if not SERVER then return false end

    amount = math.Clamp(math.floor(tonumber(amount) or 0), 0, 1000000)

    if amount <= 0 then return false end

    self.WOCoinAmount = amount
    self:SetNW2Int("wo_coin_amount", amount)
    self.PickupCooldown = CurTime() + 0.4

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end

    return true
end

function ENT:ApplyThrow(velocity)
    if not SERVER then return end

    local phys = self:GetPhysicsObject()

    if IsValid(phys) then
        phys:Wake()
        phys:SetVelocity(velocity or Vector(0, 0, 40))
        phys:AddAngleVelocity(VectorRand() * 160)
    end
end

if CLIENT then
    function ENT:Draw()
        self:DrawModel()
    end
end

scripted_ents.Register(ENT, "wo_coin_pile")
