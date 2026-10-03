--[[
    Warcraft Online — NPC (SENT).

    wo_npc — data-driven NPC (см. schemas/npcs/):
        - модель/масштаб/skin/bodygroups из схемы;
        - единый Interaction-интерфейс (как у wo_item_world);
        - имена/роли синхронизируются NW2 для клиентских подсказок;
        - враждебные NPC (hostile) атакуют и могут быть целью квестов.

    Сущность создаётся ТОЛЬКО сервером (WO.NPCs.SpawnAll).
]]

ENT = {}

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "WO NPC"
ENT.Category = "Warcraft Online"
ENT.Author = "Warcraft Online Team"
ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "NPCID")
end

if SERVER then
    --- Инициализация из схемы NPC (вызывает WO.NPCs).
    function ENT:SetupNPC(npcDef)
        self.npcDef = npcDef

        self:SetNPCID(npcDef.id or "")
        self:SetNW2String("wo_name", npcDef.name or "NPC")
        self:SetNW2String("wo_role", npcDef.type or "talker")
        self:SetNW2Int("wo_level", math.max(1, tonumber(npcDef.level) or 1))

        local model = npcDef.model or "models/player/Group01/male_01.mdl"

        self:SetModel(model)
        self:SetSkin(npcDef.skin or 0)

        if istable(npcDef.bodygroups) then
            for bgId, value in pairs(npcDef.bodygroups) do
                self:SetBodygroup(tonumber(bgId) or 0, tonumber(value) or 0)
            end
        end

        if npcDef.scale and npcDef.scale ~= 1 then
            self:SetModelScale(npcDef.scale, 0)
        end

        self:SetMoveType(MOVETYPE_NONE)
        self:SetSolid(SOLID_BBOX)
        self:SetCollisionGroup(COLLISION_GROUP_PLAYER)
        self:SetNoDraw(false)

        self:DropToFloor()

        if npcDef.health then
            self:SetMaxHealth(npcDef.health)
            self:SetHealth(npcDef.health)
        end

        -- Анимация: стоять смотря вперёд
        self:SetSequence(self:LookupSequence("Idle01") ~= -1 and self:LookupSequence("Idle01") or 0)
    end

    function ENT:OnTakeDamage(dmg)
        if not self.npcDef or not self.npcDef.hostile then
            return -- дружелюбные NPC не получают урон
        end

        self:SetHealth(self:Health() - dmg:GetDamage())

        local attacker = dmg:GetAttacker()

        if self:Health() <= 0 then
            local ply = (IsValid(attacker) and attacker:IsPlayer()) and attacker or nil

            if ply then
                WO.Hook.Run("NPCKilled", self.npcDef, ply)
            end

            self:Remove()
        end
    end

    function ENT:Think()
        -- Враждебные NPC: простая агрессия на ближайшего игрока с персонажем
        if self.npcDef and self.npcDef.hostile and (self.nextAttack or 0) <= CurTime() then
            self.nextAttack = CurTime() + 1.5

            for _, ply in ipairs(player.GetHumans()) do
                if IsValid(ply) and ply:HasCharacter() and ply:Alive() then
                    if self:GetPos():Distance(ply:GetPos()) <= (self.npcDef.attackRange or 120) then
                        WO.Hook.Run("NPCAttack", self.npcDef, self, ply)
                    end
                end
            end
        end

        self:NextThink(CurTime() + 0.5)

        return true
    end

    -----------------------------------------------------------------------
    -- Interaction-интерфейс (общий для всех интерактивных сущностей)
    -----------------------------------------------------------------------

    function ENT:CanInteract(ply)
        if not IsValid(ply) or not ply:HasCharacter() then return false end
        if not self.npcDef then return false end
        if self.npcDef.hostile then return false end

        return ply:GetPos():Distance(self:GetPos()) <= (self.npcDef.interactRange or 140)
    end

    function ENT:GetInteractionText(ply)
        local def = self.npcDef

        if not def then return "" end

        if def.type == "vendor" then
            return "[E] Торговля: " .. (def.name or "Торговец")
        end

        if def.type == "questgiver" then
            return "[E] Поговорить: " .. (def.name or "NPC")
        end

        return "[E] " .. (def.name or "NPC")
    end

    function ENT:Interact(ply)
        if not self:CanInteract(ply) then return end

        WO.NPCs.OnInteract(self, ply)
    end
end

if CLIENT then
    function ENT:Draw()
        self:DrawModel()
    end

    -- Имя над головой
    function ENT:DrawTranslucent()
        local name = self:GetNW2String("wo_name", "")

        if name == "" then return end

        local pos = self:GetPos() + Vector(0, 0, 82)
        local ang = LocalPlayer():EyeAngles()

        ang:RotateAroundAxis(ang:Forward(), 90)
        ang:RotateAroundAxis(ang:Right(), 90)

        cam.Start3D2D(pos, ang, 0.12)
            draw.SimpleText(name, "WO.HUDName", 0, 0, Color(255, 220, 120, 230), TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end
end

scripted_ents.Register(ENT, "wo_npc")
