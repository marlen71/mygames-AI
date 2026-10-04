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
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "NPCID")
end

local function GetNPCDefinition(ent)
    if istable(ent.npcDef) then return ent.npcDef end

    if isfunction(ent.GetNPCID) and WO.NPCs and isfunction(WO.NPCs.Get) then
        return WO.NPCs.Get(ent:GetNPCID())
    end

    return nil
end

-- Shared client/server interface keeps the HUD prompt and server Use checks
-- aligned. The client resolves only a registered schema id from the NetworkVar.
function ENT:CanInteract(ply)
    if not IsValid(ply) or not ply:HasCharacter() then return false end

    local npcDef = GetNPCDefinition(self)

    if not npcDef or npcDef.hostile then return false end

    local range = WO.Interaction and WO.Interaction.GetRange
        and WO.Interaction.GetRange(self) or tonumber(npcDef.interactRange) or 100

    return ply:GetPos():Distance(self:GetPos()) <= range
end

function ENT:GetInteractionText(ply)
    local def = GetNPCDefinition(self)

    if not def then return "" end

    if def.type == "vendor" then
        return WO.Lang:Get("interact.npc_vendor") .. ": " .. (def.name or "")
    end

    if def.type == "questgiver" then
        return WO.Lang:Get("interact.npc_quest") .. ": " .. (def.name or "")
    end

    return WO.Lang:Get("interact.npc_talk") .. ": " .. (def.name or "")
end

if SERVER then
    function ENT:Initialize()
        self:SetUseType(SIMPLE_USE)
    end

    --- Инициализация из схемы NPC (вызывает WO.NPCs).
    function ENT:SetupNPC(npcDef, level, levelStats)
        if not istable(npcDef) or not isstring(npcDef.model) or npcDef.model == "" then
            return false
        end

        level = math.max(1, math.floor(tonumber(level) or npcDef.level or 1))
        self.npcDef = npcDef
        self.WO_NPCDefinition = npcDef
        self.WO_NPCLevel = level
        self.WO_NPCLevelStats = levelStats
        self:SetUseType(SIMPLE_USE)
        self:SetNPCID(npcDef.id or "")
        local displayName = npcDef.name or "NPC"

        if npcDef.hostile then
            displayName = displayName .. " · ур. " .. level
        end

        self:SetNW2String("wo_name", displayName)
        self:SetNW2String("wo_role", npcDef.type or "talker")
        self:SetNW2Int("wo_level", level)

        local model = npcDef.model

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

        local health = levelStats and levelStats.health or npcDef.health

        if health then
            self:SetMaxHealth(health)
            self:SetHealth(health)
        end

        -- Анимация: стоять смотря вперёд
        self:SetSequence(self:LookupSequence("Idle01") ~= -1 and self:LookupSequence("Idle01") or 0)

        return true
    end

    function ENT:OnTakeDamage(dmg)
        if not self.npcDef or not self.npcDef.hostile then
            return -- дружелюбные NPC не получают урон
        end

        self:SetHealth(self:Health() - dmg:GetDamage())

        local attacker = dmg:GetAttacker()

        if self:Health() <= 0 then
            if WO.NPCs and WO.NPCs.HandleKilled then
                WO.NPCs.HandleKilled(self, attacker)
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

    function ENT:Interact(ply)
        if not self:CanInteract(ply) then return end

        WO.NPCs.OnInteract(self, ply)
    end

    function ENT:Use(activator, caller)
        if not IsValid(activator) or not WO.Interaction or
            not isfunction(WO.Interaction.TryInteract) then return end

        WO.Interaction.TryInteract(activator, self)
    end
end

if CLIENT then
    function ENT:Draw()
        self:DrawModel()
    end

    local function QuestMarker(npcDef)
        if not npcDef or not istable(npcDef.quests) or
            not WO.Quests or not WO.Quests.Get then return nil end

        local char = WO.Character and WO.Character.GetLocal and WO.Character.GetLocal()
        if not char then return nil end

        local states = WO.Quests.LocalStates or char.quests or {}

        if table.IsEmpty and table.IsEmpty(states) and istable(char.quests) then
            states = char.quests
        end

        local stateView = { quests = states }
        local level = isfunction(char.GetLevel) and char:GetLevel() or char.level or 1

        for _, questId in ipairs(npcDef.quests) do
            local quest = WO.Quests.Get(questId)

            if quest then
                local state = states[questId]

                if state and state.status == "active" and WO.Quests.AreStepsDone and
                    WO.Quests.AreStepsDone(stateView, questId) then
                    return "ready"
                end

                if not state and level >= (quest.level or 1) then
                    local prerequisitesMet = true

                    for _, prerequisite in ipairs(quest.prerequisites or {}) do
                        local prerequisiteState = states[prerequisite]

                        if not prerequisiteState or prerequisiteState.status ~= "completed" then
                            prerequisitesMet = false
                            break
                        end
                    end

                    if prerequisitesMet then
                        return "available"
                    end
                end
            end
        end

        return nil
    end

    -- WoW-style quest / vendor markers and a compact nameplate.
    function ENT:DrawTranslucent()
        local name = self:GetNW2String("wo_name", "")
        if name == "" then return end

        local player = LocalPlayer()
        if not IsValid(player) then return end

        local bounds = self:OBBMaxs()
        local pos = self:GetPos() + Vector(0, 0, math.max(64, bounds.z + 12))
        local ang = player:EyeAngles()

        ang:RotateAroundAxis(ang:Forward(), 90)
        ang:RotateAroundAxis(ang:Right(), 90)

        local npcDef = WO.NPCs and WO.NPCs.Get and WO.NPCs.Get(self:GetNPCID()) or nil
        local role = npcDef and npcDef.type or self:GetNW2String("wo_role", "")
        local questMarker = QuestMarker(npcDef)
        local markerText, markerColor

        if questMarker == "available" then
            markerText = "!"
            markerColor = Color(255, 210, 35)
        elseif questMarker == "ready" then
            markerText = "?"
            markerColor = Color(255, 210, 35)
        elseif role == "vendor" then
            markerText = "$"
            markerColor = Color(255, 205, 55)
        end

        cam.Start3D2D(pos, ang, 0.12)
            if markerText then
                draw.SimpleTextOutlined(markerText, "WO.Title", 0, -25,
                    markerColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
                    2, Color(22, 17, 8, 245))
            end

            if role == "vendor" and markerText ~= "$" then
                draw.SimpleTextOutlined("$", "WO.Subtitle", 18, -24,
                    Color(255, 205, 55), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
                    2, Color(22, 17, 8, 245))
            end

            surface.SetFont("WO.HUDName")
            local nameWidth = surface.GetTextSize(name)
            draw.RoundedBox(6, -nameWidth / 2 - 10, 2, nameWidth + 20, 24,
                Color(16, 18, 26, 210))
            WO.UI.DrawTextFit(name, "WO.HUDName", 0, 5,
                Color(255, 230, 170, 245), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 290, 18)
        cam.End3D2D()
    end
end

scripted_ents.Register(ENT, "wo_npc")
