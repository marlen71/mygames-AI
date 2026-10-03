--[[
    Warcraft Online — NPC (server): спавн и жизненный цикл.
]]

--- Создаёт одного NPC из схемы.
function WO.NPCs.SpawnOne(def, pos, ang)
    local ent = ents.Create("wo_npc")

    if not IsValid(ent) then
        WO.Error("WO.NPCs.SpawnOne: cannot create wo_npc for '" .. tostring(def.id) .. "'")
        return nil
    end

    ent:SetPos(pos)
    ent:SetAngles(ang or Angle(0, 0, 0))
    ent:Spawn()

    ent:SetupNPC(def)

    WO.NPCs.Spawned[#WO.NPCs.Spawned + 1] = ent

    return ent
end

--- Разрешает только явные координаты или явный map entity anchor.
-- Никаких случайных/вычисленных по игрокам точек.
function WO.NPCs.ResolveSpawnPoint(spawn)
    if not istable(spawn) then return nil end

    if isvector(spawn.pos) then
        return spawn.pos, spawn.ang or Angle(0, 0, 0)
    end

    if not isstring(spawn.anchor) or spawn.anchor == "" then
        return nil
    end

    local anchors = ents.FindByClass(spawn.anchor) or {}

    table.sort(anchors, function(a, b)
        local first = IsValid(a) and a:EntIndex() or math.huge
        local second = IsValid(b) and b:EntIndex() or math.huge

        return first < second
    end)

    local index = math.max(1, math.floor(tonumber(spawn.anchorIndex) or 1))
    local anchor = anchors[index]

    if not IsValid(anchor) then return nil end

    local offset = isvector(spawn.offset) and spawn.offset or vector_origin
    local position = anchor:GetPos() + offset
    local angle = spawn.ang or anchor:GetAngles() or Angle(0, 0, 0)

    return position, angle
end

--- Спавнит NPC только по явным координатам/map-anchor из схемы или конфига.
-- Пустой список или отсутствующий anchor означает «не размещать».
function WO.NPCs.SpawnAll()
    -- Убираем остатки (например, после cleanup).
    for _, ent in ipairs(WO.NPCs.Spawned) do
        if IsValid(ent) then
            ent:Remove()
        end
    end

    WO.NPCs.Spawned = {}

    local map = game.GetMap()
    local definitionsPlaced = 0

    for _, def in pairs(WO.NPCs.List) do
        local spawnedForDefinition = false

        for _, spawn in ipairs(def.spawns or {}) do
            if not spawn.map or spawn.map == map then
                local pos, ang = WO.NPCs.ResolveSpawnPoint(spawn)

                if pos then
                    local ent = WO.NPCs.SpawnOne(def, pos, ang)

                    if IsValid(ent) then
                        spawnedForDefinition = true
                    end
                elseif spawn.anchor then
                    WO.Debug("NPC spawn anchor not found: " .. tostring(spawn.anchor) ..
                        " for '" .. tostring(def.id) .. "' on map '" .. tostring(map) .. "'")
                end
            end
        end

        if spawnedForDefinition then
            definitionsPlaced = definitionsPlaced + 1
        else
            WO.Debug("NPC not spawned: no explicit spawn configured for '" ..
                tostring(def.id) .. "' on map '" .. tostring(map) .. "'")
        end
    end

    WO.Log("NPCs spawned: " .. definitionsPlaced .. " definitions, " .. #WO.NPCs.Spawned ..
        " entities (explicit map spawns only)")
end

hook.Add("InitPostEntity", "wo_npcs_spawn", function()
    timer.Simple(1, function()
        WO.NPCs.SpawnAll()
    end)
end)

hook.Add("PostCleanupMap", "wo_npcs_respawn", function()
    WO.NPCs.SpawnAll()
end)

---------------------------------------------------------------------------
-- Агрессия враждебных NPC
---------------------------------------------------------------------------

WO.Hook.Add("NPCAttack", "npcs", function(npcDef, ent, ply)
    if not IsValid(ply) or not ply:HasCharacter() then return end

    if WO.Combat and WO.Combat.Damage then
        WO.Combat.Damage(ent, ply, {
            amount = npcDef.damage or 8,
            damageType = "physical",
            canCrit = false,
        })
    end
end)

-- Переводит общий combat death в доменное событие NPC; Quest-плагин подписан
-- только на NPCKilled и не зависит от конкретных SWEP/Workshop-моделей.
WO.Hook.Add("EntityKilled", "npcs", function(ent, attacker)
    if not IsValid(ent) or not ent.npcDef or not ent.npcDef.hostile then return end
    if not IsValid(attacker) or not attacker:IsPlayer() or not attacker:HasCharacter() then return end

    WO.Hook.Run("NPCKilled", ent.npcDef, attacker)
end)

---------------------------------------------------------------------------
-- Админ-команды
---------------------------------------------------------------------------

concommand.Add("wo_npc_respawn", function(ply)
    if IsValid(ply) and not WO.Admin.Can(ply, "npc.spawn") then
        ply:ChatPrint("[WO] Недостаточно прав.")
        return
    end

    WO.NPCs.SpawnAll()
end)

concommand.Add("wo_npc_list", function(ply)
    if IsValid(ply) and not WO.Admin.Can(ply, "npc.spawn") then
        ply:ChatPrint("[WO] Недостаточно прав.")
        return
    end

    local function out(text)
        if IsValid(ply) then
            ply:ChatPrint(text)
        else
            print(text)
        end
    end

    for id, def in pairs(WO.NPCs.List) do
        out(id .. " [" .. def.type .. "] " .. def.name ..
            " | spawned: " .. (def.spawns and #def.spawns or 0) .. " точек")
    end
end)
