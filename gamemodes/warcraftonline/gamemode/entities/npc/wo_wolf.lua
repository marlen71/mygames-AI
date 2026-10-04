--[[
    Warcraft Online — собственный боевой NPC-волк.
    Модель строго models/wow_monsters/direwolf.mdl; внешний wow_npc_14892 не нужен.
    AI: поиск персонажей в радиусе, преследование по schedule, ближняя атака и
    реакция на урон. Никаких случайных спавнов: точками управляют NPC schemas.
]]

ENT = {}
ENT.Type = "ai"
ENT.Base = "base_ai"
ENT.PrintName = "WO Direwolf"
ENT.Category = "Warcraft Online"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.AutomaticFrameAdvance = true
ENT.Model = "models/wow_monsters/direwolf.mdl"

ENT.WORequestedSequences = {
    "attackunarmed", "combatcritical", "combatwound", "death", "fall",
    "jump", "jumpend", "jumpstart", "mountspecial", "run", "shuffleleft",
    "shuffleright", "stand", "stand_v1", "stand_v2", "swim", "swimidle",
    "walk", "walkbackwards",
}

local function SetWolfSequence(ent, name)
    if not IsValid(ent) or not isfunction(ent.LookupSequence) then return false end

    local sequence = ent:LookupSequence(name)

    if not isnumber(sequence) or sequence < 0 then return false end

    if isfunction(ent.ResetSequence) then
        ent:ResetSequence(sequence)
    elseif isfunction(ent.SetSequence) then
        ent:SetSequence(sequence)
    end

    if isfunction(ent.SetPlaybackRate) then ent:SetPlaybackRate(1) end
    ent.WO_WolfSequence = name
    return true
end

local function SetWolfSchedule(ent, schedule)
    if isnumber(schedule) and isfunction(ent.SetSchedule) and ent.WO_WolfSchedule ~= schedule then
        ent:SetSchedule(schedule)
        ent.WO_WolfSchedule = schedule
    end
end

function ENT:Initialize()
    self:SetModel(ENT.Model)
    self:SetUseType(SIMPLE_USE)

    if SERVER then
        self:SetHullType(HULL_HUMAN)
        self:SetHullSizeNormal()
        self:SetSolid(SOLID_BBOX)
        self:SetMoveType(MOVETYPE_STEP)
        self:SetCollisionGroup(COLLISION_GROUP_NPC)
        self:SetMaxYawSpeed(500)

        local capabilities = (CAP_MOVE_GROUND or 0) + (CAP_OPEN_DOORS or 0)
        if isfunction(self.CapabilitiesAdd) then self:CapabilitiesAdd(capabilities) end
        if isfunction(self.SetNPCState) and NPC_STATE_IDLE then self:SetNPCState(NPC_STATE_IDLE) end

        self:SetMaxHealth(45)
        self:SetHealth(45)
        self:DropToFloor()
        self.WO_NextAITick = 0
        self.WO_NextAttack = 0
        self.WO_Dead = false
        self.WO_WolfSequences = {}

        for _, name in ipairs(ENT.WORequestedSequences) do
            local sequence = isfunction(self.LookupSequence) and self:LookupSequence(name) or -1
            if isnumber(sequence) and sequence >= 0 then self.WO_WolfSequences[name] = sequence end
        end

        SetWolfSequence(self, "stand")
    end
end

function ENT:SetupNPC(npcDef, level, levelStats)
    if not istable(npcDef) or npcDef.entityClass ~= "wo_wolf" or
        npcDef.model ~= "models/wow_monsters/direwolf.mdl" then
        return false
    end

    level = math.max(1, math.floor(tonumber(level) or npcDef.level or 1))
    self.npcDef = npcDef
    self.WO_NPCDefinition = npcDef
    self.WO_NPCLevel = level
    self.WO_NPCLevelStats = levelStats
    self:SetModel(npcDef.model)
    self:SetNW2String("wo_npc_id", npcDef.id)
    self:SetNW2String("wo_name", (npcDef.name or "Волк") .. " · ур. " .. level)
    self:SetNW2String("wo_role", "creature")
    self:SetNW2Int("wo_level", level)
    self:SetMaxHealth(levelStats and levelStats.health or 45)
    self:SetHealth(levelStats and levelStats.health or 45)
    self:SetUseType(SIMPLE_USE)
    self:SetSolid(SOLID_BBOX)
    self:SetMoveType(MOVETYPE_STEP)
    self:SetCollisionGroup(COLLISION_GROUP_NPC)
    self:DropToFloor()

    if isfunction(self.SetNPCState) and NPC_STATE_IDLE then self:SetNPCState(NPC_STATE_IDLE) end
    SetWolfSequence(self, "stand")
    return true
end

local function CanSee(ent, ply)
    if not isfunction(ent.Visible) then return true end

    local ok, visible = pcall(ent.Visible, ent, ply)
    return ok and visible == true
end

function ENT:FindTarget()
    local range = math.max(128, tonumber(self.npcDef and self.npcDef.sightRange) or 900)
    local best, bestDistance

    for _, ply in ipairs(player.GetHumans()) do
        if IsValid(ply) and ply:HasCharacter() and ply:Alive() then
            local distance = self:GetPos():DistToSqr(ply:GetPos())

            if distance <= range * range and (not bestDistance or distance < bestDistance) and CanSee(self, ply) then
                best = ply
                bestDistance = distance
            end
        end
    end

    return best, bestDistance and math.sqrt(bestDistance) or nil
end

function ENT:PerformWolfAttack(target)
    if not IsValid(self) or self.WO_Dead or not IsValid(target) or
        not target:IsPlayer() or not target:HasCharacter() or not target:Alive() then return end

    local range = tonumber(self.npcDef and self.npcDef.attackRange) or 96

    if self:GetPos():Distance(target:GetPos()) > range + 24 then return end

    if self.AddEntityRelationship and D_HT then
        self:AddEntityRelationship(target, D_HT, 99)
    end

    WO.Hook.Run("NPCAttack", self.npcDef, self, target)
end

function ENT:Think()
    if SERVER and not self.WO_Dead and (self.WO_NextAITick or 0) <= CurTime() then
        self.WO_NextAITick = CurTime() + 0.25
        local target, distance = self:FindTarget()

        if IsValid(target) then
            if self.AddEntityRelationship and D_HT then
                self:AddEntityRelationship(target, D_HT, 99)
            end
            if isfunction(self.SetEnemy) then self:SetEnemy(target) end
            if isfunction(self.UpdateEnemyMemory) then self:UpdateEnemyMemory(target, target:GetPos()) end
            if isfunction(self.SetNPCState) and NPC_STATE_ALERT then self:SetNPCState(NPC_STATE_ALERT) end

            local attackRange = tonumber(self.npcDef and self.npcDef.attackRange) or 96

            if distance and distance <= attackRange then
                SetWolfSchedule(self, SCHED_NONE)

                if (self.WO_NextAttack or 0) <= CurTime() then
                    self.WO_NextAttack = CurTime() + 1.35
                    SetWolfSequence(self, "attackunarmed")
                    local attackedTarget = target
                    timer.Simple(0.32, function()
                        if IsValid(self) then self:PerformWolfAttack(attackedTarget) end
                    end)
                end
            else
                SetWolfSchedule(self, SCHED_CHASE_ENEMY)
            end
        else
            if isfunction(self.SetEnemy) and NULL then self:SetEnemy(NULL) end
            if isfunction(self.SetNPCState) and NPC_STATE_IDLE then self:SetNPCState(NPC_STATE_IDLE) end
            SetWolfSchedule(self, SCHED_IDLE_STAND)

            if not self.WO_WolfSequence or self.WO_WolfSequence == "attackunarmed" or
                self.WO_WolfSequence == "combatwound" then
                SetWolfSequence(self, "stand_v1")
            end
        end
    end

    if isfunction(self.NextThink) then self:NextThink(CurTime() + 0.2) end
    return true
end

function ENT:BeginDeath(attacker)
    if not SERVER or self.WO_Dead then return false end

    self.WO_Dead = true
    self:SetHealth(0)

    if WO.NPCs and WO.NPCs.HandleKilled then
        WO.NPCs.HandleKilled(self, attacker)
    end

    SetWolfSequence(self, "death")
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_NONE)
    timer.Simple(0.8, function()
        if IsValid(self) then self:Remove() end
    end)

    return true
end

-- Combat.Damage uses the WO pipeline directly for NPC entities instead of the
-- engine damage hook; this opt-in preserves the wolf's death animation.
function ENT:OnWOCombatKilled(attacker)
    return self:BeginDeath(attacker)
end

function ENT:OnTakeDamage(damageInfo)
    if not SERVER or self.WO_Dead or not damageInfo then return 0 end

    local amount = isfunction(damageInfo.GetDamage) and math.max(0, damageInfo:GetDamage()) or 0
    if amount <= 0 then return 0 end

    local attacker = isfunction(damageInfo.GetAttacker) and damageInfo:GetAttacker() or nil
    self:SetHealth(math.max(0, self:Health() - amount))

    if IsValid(attacker) and attacker:IsPlayer() then
        if isfunction(self.SetEnemy) then self:SetEnemy(attacker) end
        if isfunction(self.UpdateEnemyMemory) then self:UpdateEnemyMemory(attacker, attacker:GetPos()) end
    end

    if self:Health() <= 0 then
        self:BeginDeath(attacker)
    else
        SetWolfSequence(self, "combatwound")
    end

    return amount
end

function ENT:OnKilled(attacker)
    self:BeginDeath(attacker)
end

function ENT:Draw()
    self:DrawModel()
end

scripted_ents.Register(ENT, "wo_wolf")
