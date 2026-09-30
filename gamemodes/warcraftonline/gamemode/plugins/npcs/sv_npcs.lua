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

--- Спавнит всех зарегистрированных NPC на текущей карте.
function WO.NPCs.SpawnAll()
    -- Убираем остатки (например, после cleanup)
    for _, ent in ipairs(WO.NPCs.Spawned) do
        if IsValid(ent) then
            ent:Remove()
        end
    end

    WO.NPCs.Spawned = {}

    local spawns = ents.FindByClass("info_player_start")
    local anchor = (#spawns > 0) and spawns[1]:GetPos() or Vector(0, 0, 16)

    local count = 0

    for _, def in pairs(WO.NPCs.List) do
        local placed = false

        for _, spawn in ipairs(def.spawns or {}) do
            if not spawn.map or spawn.map == game.GetMap() then
                if spawn.pos then
                    WO.NPCs.SpawnOne(def, spawn.pos, spawn.ang)
                    placed = true
                end
            end
        end

        -- Без явных точек: рядом с точкой спавна игроков (детерминированный отступ)
        if not placed and not def.noAutoSpawn then
            local offsetId = 0

            for i = 1, #def.id do
                offsetId = offsetId + string.byte(def.id, i)
            end

            local angle = (offsetId % 360) * math.pi / 180
            local dist = 180 + (offsetId % 5) * 70
            local pos = anchor + Vector(math.cos(angle) * dist, math.sin(angle) * dist, 8)

            WO.NPCs.SpawnOne(def, pos, Angle(0, (offsetId * 7) % 360, 0))
            placed = true
        end

        if placed then
            count = count + 1
        end
    end

    WO.Log("NPCs spawned: " .. count .. " definitions, " .. #WO.NPCs.Spawned .. " entities")
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

---------------------------------------------------------------------------
-- Админ-команды
---------------------------------------------------------------------------

concommand.Add("wo_npc_respawn", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end

    WO.NPCs.SpawnAll()
end)

concommand.Add("wo_npc_list", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end

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
