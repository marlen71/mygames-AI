--[[
    Warcraft Online — NPC (server): спавн и жизненный цикл.
]]

WO.NPCs.SuppressedSpawnKeys = WO.NPCs.SuppressedSpawnKeys or {}

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
        ent:SetNW2String("wo_name", def.name or def.id)
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

local function SpawnKey(def, spawn, index)
    return tostring(def.id) .. ":" .. tostring(spawn and (spawn.spawnKey or index) or index)
end

function WO.NPCs.HasActiveQuest(questId)
    if not isstring(questId) or questId == "" then return false end

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:HasCharacter() then
            local char = ply:GetCharacter()
            local state = char and char.quests and char.quests[questId]

            if state and state.status == "active" then
                local questDef = WO.Quests and WO.Quests.Get and WO.Quests.Get(questId)
                local prerequisitesMet = true

                for _, prerequisite in ipairs(questDef and questDef.prerequisites or {}) do
                    local prerequisiteState = char.quests[prerequisite]

                    if not prerequisiteState or prerequisiteState.status ~= "completed" then
                        prerequisitesMet = false
                        break
                    end
                end

                local waitingForTurnIn = prerequisitesMet and questDef and
                    questDef.turnInRequired == true and WO.Quests.AreStepsDone and
                    WO.Quests.AreStepsDone(char, questId)

                if prerequisitesMet and not waitingForTurnIn then return true end
            end
        end
    end

    return false
end

--- Создаёт одного NPC из схемы и конкретной явной spawn-записи.
function WO.NPCs.SpawnOne(def, pos, ang, spawn, spawnIndex)
    if not istable(def) or not isvector(pos) then return nil end

    local workshopClass = def.workshopClass
    local entityClass = workshopClass or def.entityClass or "wo_npc"

    if workshopClass then
        if not (WO.Workshop and WO.Workshop.HasNPCClass and
            WO.Workshop.HasNPCClass(workshopClass)) then
            WO.Warn("NPC class is not registered; skipping '" .. tostring(def.id) ..
                "' (required " .. tostring(workshopClass) .. ")")
            return nil
        end
    else
        if def.entityClass and not (scripted_ents and scripted_ents.GetStored and
            scripted_ents.GetStored(def.entityClass)) then
            WO.Warn("Custom NPC entity is not registered; skipping '" .. tostring(def.id) ..
                "' (required " .. tostring(def.entityClass) .. ")")
            return nil
        end

        if not isstring(def.model) or def.model == "" or
            (WO.Models and WO.Models.Exists and not WO.Models.Exists(def.model)) or
            (util.IsValidModel and not util.IsValidModel(def.model)) then
            WO.Warn("NPC model is unavailable; skipping '" .. tostring(def.id) .. "'")
            return nil
        end
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

    ent.WO_NPCSpawnQuestId = spawn and spawn.questId or nil
    ent.WO_NPCSpawnKey = SpawnKey(def, spawn, spawnIndex)

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
        local gatedByQuest = false

        for index, spawn in ipairs(def.spawns or {}) do
            if not spawn.map or spawn.map == map then
                if spawn.questId and not WO.NPCs.HasActiveQuest(spawn.questId) then
                    gatedByQuest = true
                else
                    local pos, ang = WO.NPCs.ResolveSpawnPoint(spawn)

                    if pos then
                        local ent = WO.NPCs.SpawnOne(def, pos, ang, spawn, index)

                        if IsValid(ent) then
                            spawnedForDefinition = true
                        end
                    elseif spawn.anchor then
                        WO.Debug("NPC spawn anchor not found: " .. tostring(spawn.anchor) ..
                            " for '" .. tostring(def.id) .. "' on map '" .. tostring(map) .. "'")
                    end
                end
            end
        end

        if spawnedForDefinition then
            definitionsPlaced = definitionsPlaced + 1
        elseif gatedByQuest then
            WO.Debug("NPC spawn gated by quest for '" .. tostring(def.id) .. "' on map '" ..
                tostring(map) .. "'")
        else
            WO.Debug("NPC not spawned: no explicit spawn configured for '" ..
                tostring(def.id) .. "' on map '" .. tostring(map) .. "'")
        end
    end

    WO.Log("NPCs spawned: " .. definitionsPlaced .. " definitions, " .. #WO.NPCs.Spawned ..
        " entities (explicit map spawns only)")
end

--- Поддерживает quest-linked spawn group в соответствии с активными персонажами.
function WO.NPCs.SyncQuestSpawns(questId)
    if not isstring(questId) or questId == "" then return end

    local active = WO.NPCs.HasActiveQuest(questId)
    local existing = {}

    for index = #WO.NPCs.Spawned, 1, -1 do
        local ent = WO.NPCs.Spawned[index]

        if not IsValid(ent) then
            table.remove(WO.NPCs.Spawned, index)
        elseif ent.WO_NPCSpawnQuestId == questId then
            local dead = isfunction(ent.Health) and ent:Health() <= 0

            if active and not dead then
                existing[ent.WO_NPCSpawnKey] = ent
            else
                ent:Remove()
                table.remove(WO.NPCs.Spawned, index)
            end
        end
    end

    if not active then
        for key in pairs(WO.NPCs.SuppressedSpawnKeys or {}) do
            if string.StartWith(key, tostring(questId) .. ":") then
                WO.NPCs.SuppressedSpawnKeys[key] = nil
            end
        end
        return
    end

    local map = game.GetMap()

    for _, def in pairs(WO.NPCs.List) do
        for index, spawn in ipairs(def.spawns or {}) do
            if spawn.questId == questId and (not spawn.map or spawn.map == map) then
                local key = SpawnKey(def, spawn, index)

                if not IsValid(existing[key]) and
                    not (WO.NPCs.SuppressedSpawnKeys and WO.NPCs.SuppressedSpawnKeys[key]) then
                    local pos, ang = WO.NPCs.ResolveSpawnPoint(spawn)

                    if pos then
                        local ent = WO.NPCs.SpawnOne(def, pos, ang, spawn, index)

                        if IsValid(ent) then
                            existing[key] = ent
                        end
                    end
                end
            end
        end
    end
end

hook.Add("InitPostEntity", "wo_npcs_spawn", function()
    timer.Simple(1, function()
        WO.NPCs.SpawnAll()
    end)
end)

hook.Add("PostCleanupMap", "wo_npcs_respawn", function()
    WO.NPCs.SpawnAll()
end)

WO.Hook.Add("QuestStateChanged", "npcs_quest_spawn_state", function(_, questId)
    WO.NPCs.SyncQuestSpawns(questId)
end)

WO.Hook.Add("CharacterLoaded", "npcs_quest_spawn_load", function(char)
    for questId, state in pairs(char.quests or {}) do
        if state.status == "active" then
            WO.NPCs.SyncQuestSpawns(questId)
        end
    end
end)

WO.Hook.Add("CharacterUnloaded", "npcs_quest_spawn_unload", function(char)
    for questId in pairs(char.quests or {}) do
        WO.NPCs.SyncQuestSpawns(questId)
    end
end)

-- Убийство владельцем активного квеста не заменяется. Убийства посторонним
-- игроком или NPC восстанавливают точку, чтобы не лишить участника цели.
WO.Hook.Add("NPCDeath", "npcs_quest_spawn_replenish", function(npcDef, ent, attacker)
    local questIds = {}

    if IsValid(ent) and ent.WO_NPCSpawnQuestId then
        questIds[ent.WO_NPCSpawnQuestId] = true
    else
        for _, spawn in ipairs(npcDef and npcDef.spawns or {}) do
            if spawn.questId then questIds[spawn.questId] = true end
        end
    end

    for questId in pairs(questIds) do
        if WO.NPCs.HasActiveQuest(questId) then
            local killedByParticipant = false

            if IsValid(attacker) and attacker:IsPlayer() and attacker:HasCharacter() then
                local char = attacker:GetCharacter()
                local state = char and char.quests and char.quests[questId]
                killedByParticipant = state and state.status == "active" or false
            end

            local spawnKey = IsValid(ent) and ent.WO_NPCSpawnKey

            if killedByParticipant and spawnKey then
                WO.NPCs.SuppressedSpawnKeys[spawnKey] = true
            elseif spawnKey then
                WO.NPCs.SuppressedSpawnKeys[spawnKey] = nil
                timer.Simple(0.9, function() WO.NPCs.SyncQuestSpawns(questId) end)
            end
        end
    end
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

local function LootPosition(origin)
    return origin + Vector(math.random(-48, 48), math.random(-48, 48), math.random(12, 32))
end

local function LootVelocity()
    return Vector(math.random(-120, 120), math.random(-120, 120), math.random(70, 170))
end

local function ScaledChance(entry, level)
    local chance = tonumber(entry.chance) or 0
    chance = chance + math.max(0, level - 1) * (tonumber(entry.levelScale) or 0)
    return math.Clamp(chance, 0, 1)
end

local function DropNPCLoot(ent, def)
    if ent.WO_NPCLootDropped then return end

    ent.WO_NPCLootDropped = true

    local loot = def and def.loot
    if not istable(loot) or not WO.World then return end

    local level = WO.NPCs.ClampLevel(def, ent.WO_NPCLevel or def.level or 1)
    local origin = isfunction(ent.GetPos) and ent:GetPos() or vector_origin
    local currency = loot.currency

    if istable(currency) and math.random() <= ScaledChance(currency, level) then
        local minimum = math.max(1, math.floor((tonumber(currency.min) or 1) * level))
        local maximum = math.max(minimum, math.floor((tonumber(currency.max) or minimum) * level))
        local amount = math.random(minimum, maximum)
        local ok, reason = WO.World.SpawnLootCoins(amount, LootPosition(origin), LootVelocity())

        if not ok then WO.Warn("NPC coin loot failed for '" .. def.id .. "': " .. tostring(reason)) end
    end

    for _, entry in ipairs(loot.items or {}) do
        if istable(entry) and isstring(entry.class) and
            math.random() <= ScaledChance(entry, level) then
            local amount = math.max(1, math.floor(tonumber(entry.amount) or 1))

            if entry.minAmount or entry.maxAmount then
                local minimum = math.max(1, math.floor(tonumber(entry.minAmount) or 1))
                local maximum = math.max(minimum, math.floor(tonumber(entry.maxAmount) or minimum))
                amount = math.random(minimum, maximum)
            end

            local instance = WO.Items.CreateInstance(entry.class, amount)

            if instance then
                local ok, reason = WO.World.SpawnLootItem(instance,
                    LootPosition(origin), LootVelocity())

                if not ok then
                    WO.Items.SetState(instance, WO.Items.State.DESTROYED)
                    WO.Warn("NPC item loot failed for '" .. def.id .. "/" .. entry.class ..
                        "': " .. tostring(reason))
                end
            end
        end
    end
end

function WO.NPCs.HandleKilled(ent, attacker)
    local def = ResolveDefinition(ent)

    if not def then return false end

    DropNPCLoot(ent, def)

    local level = ent.WO_NPCLevel or def.level or 1

    if not ent.WO_NPCDeathEventSent then
        ent.WO_NPCDeathEventSent = true
        WO.Hook.Run("NPCDeath", def, ent, attacker, level)
    end

    if IsValid(attacker) and attacker:IsPlayer() and attacker:HasCharacter() and
        not ent.WO_NPCKillEventSent then
        ent.WO_NPCKillEventSent = true
        WO.Hook.Run("NPCKilled", def, attacker, level)
    end

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

-- Combat pipeline, native NPC death and SENT damage all converge here; the
-- per-entity event flags prevent duplicate loot or quest progress.
local function HandleRegisteredNPCDeath(ent, attacker)
    if not IsValid(ent) or not ResolveDefinition(ent) then return end
    WO.NPCs.HandleKilled(ent, attacker)
end

WO.Hook.Add("EntityKilled", "wo_combat_npc_killed", HandleRegisteredNPCDeath)
hook.Add("OnNPCKilled", "wo_external_npc_killed", HandleRegisteredNPCDeath)

hook.Add("PostEntityTakeDamage", "wo_external_npc_damage_killed", function(ent, damageInfo, wasDamageTaken)
    if wasDamageTaken ~= true or not IsValid(ent) or not damageInfo or
        not isfunction(ent.Health) or ent:Health() > 0 then
        return
    end

    local attacker = isfunction(damageInfo.GetAttacker) and damageInfo:GetAttacker() or nil
    HandleRegisteredNPCDeath(ent, attacker)
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
