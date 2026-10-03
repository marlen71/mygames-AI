--[[
    Warcraft Online — NPC (server): спавн и жизненный цикл.
]]

local function SpawnLevel(def, spawn)
    local level = WO.NPCs.ClampLevel(def, spawn and spawn.level or def.level)

    return level, WO.NPCs.GetLevelStats(def, level)
end

local function SetExternalNPCData(ent, def, level, stats)
    ent.WO_NPCDefinition = def
    ent.npcDef = def
    ent.WO_NPCLevel = level
    ent.WO_NPCLevelStats = stats

    if isfunction(ent.SetNW2String) then
        ent:SetNW2String("wo_npc_id", def.id or "")
        ent:SetNW2String("wo_name", (def.name or def.id) .. " · ур. " .. level)
        ent:SetNW2String("wo_role", def.type or "creature")
    end

    if isfunction(ent.SetNW2Int) then
        ent:SetNW2Int("wo_level", level)
    end

    if stats then
        if isfunction(ent.SetMaxHealth) then ent:SetMaxHealth(stats.health) end
        if isfunction(ent.SetHealth) then ent:SetHealth(stats.health) end
    end
end

--- Создаёт одного NPC из схемы и конкретной явной spawn-записи.
function WO.NPCs.SpawnOne(def, pos, ang, spawn)
    if not istable(def) or not isvector(pos) then return nil end

    local workshopClass = def.workshopClass
    local entityClass = workshopClass or "wo_npc"

    if workshopClass then
        if not (WO.Workshop and WO.Workshop.HasNPCClass and
            WO.Workshop.HasNPCClass(workshopClass)) then
            WO.Warn("NPC class is not registered; skipping '" .. tostring(def.id) ..
                "' (required " .. tostring(workshopClass) .. ")")
            return nil
        end
    elseif not isstring(def.model) or def.model == "" or
        (WO.Models and WO.Models.Exists and not WO.Models.Exists(def.model)) or
        (util.IsValidModel and not util.IsValidModel(def.model)) then
        WO.Warn("NPC model is unavailable; skipping '" .. tostring(def.id) .. "'")
        return nil
    end

    local ent = ents.Create(entityClass)

    if not IsValid(ent) then
        WO.Warn("Cannot create NPC class '" .. tostring(entityClass) ..
            "' for definition '" .. tostring(def.id) .. "'")
        return nil
    end

    local level, stats = SpawnLevel(def, spawn)
    ent:SetPos(pos)
    ent:SetAngles(ang or Angle(0, 0, 0))
    ent:Spawn()

    if workshopClass then
        SetExternalNPCData(ent, def, level, stats)
    else
        if not isfunction(ent.SetupNPC) or ent:SetupNPC(def, level, stats) == false then
            ent:Remove()
            return nil
        end

        ent.WO_NPCDefinition = def
        ent.WO_NPCLevel = level
        ent.WO_NPCLevelStats = stats
    end

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
                    local ent = WO.NPCs.SpawnOne(def, pos, ang, spawn)

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

    local stats = IsValid(ent) and ent.WO_NPCLevelStats or nil
    local amount = stats and stats.damage or npcDef.damage or 8

    if WO.Combat and WO.Combat.Damage then
        WO.Combat.Damage(ent, ply, {
            amount = amount,
            damageType = "physical",
            canCrit = false,
        })
    end
end)

local function ResolveDefinition(ent)
    if not IsValid(ent) then return nil end

    return ent.WO_NPCDefinition or ent.npcDef
end

function WO.NPCs.HandleKilled(ent, attacker)
    local def = ResolveDefinition(ent)

    if not def or not def.hostile or ent.WO_NPCKillEventSent then return false end
    if not IsValid(attacker) or not attacker:IsPlayer() or not attacker:HasCharacter() then return false end

    ent.WO_NPCKillEventSent = true
    WO.Hook.Run("NPCKilled", def, attacker, ent.WO_NPCLevel or def.level or 1)

    return true
end

-- Level-specific damage is applied to damage delivered by registered external
-- Workshop NPC classes; level-one values are the explicitly configured baseline.
hook.Add("EntityTakeDamage", "wo_npc_level_damage", function(target, damageInfo)
    if not damageInfo or not isfunction(damageInfo.GetAttacker) or
        not isfunction(damageInfo.ScaleDamage) then return end

    local attacker = damageInfo:GetAttacker()
    local def = ResolveDefinition(attacker)

    if not def then
        attacker = isfunction(damageInfo.GetInflictor) and damageInfo:GetInflictor() or nil
        def = ResolveDefinition(attacker)
    end

    if not def or not def.hostile or not def.workshopClass then return end

    local stats = attacker.WO_NPCLevelStats
    local baseline = WO.NPCs.GetLevelStats(def, def.minLevel or 1)

    if not stats or not baseline or not baseline.damage or baseline.damage <= 0 or
        not stats.damage then return end

    damageInfo:ScaleDamage(stats.damage / baseline.damage)
end)

-- Engine death hooks for external Workshop NPC/SENT classes. The WO entity
-- calls HandleKilled from OnTakeDamage directly; the sent flag deduplicates it
-- against either engine hook when both are emitted.
local function HandleExternalNPCDeath(ent, attacker)
    if not IsValid(ent) or not ResolveDefinition(ent) then return end

    WO.NPCs.HandleKilled(ent, attacker)
end

hook.Add("OnNPCKilled", "wo_external_npc_killed", HandleExternalNPCDeath)

hook.Add("PostEntityTakeDamage", "wo_external_npc_damage_killed", function(ent, damageInfo, wasDamageTaken)
    if wasDamageTaken ~= true or not IsValid(ent) or not damageInfo or
        not isfunction(ent.Health) or ent:Health() > 0 then
        return
    end

    local attacker = isfunction(damageInfo.GetAttacker) and damageInfo:GetAttacker() or nil
    HandleExternalNPCDeath(ent, attacker)
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
