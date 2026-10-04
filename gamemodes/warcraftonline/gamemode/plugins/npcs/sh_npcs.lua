--[[
    Warcraft Online — NPC (shared): реестр и API.

    Схема NPC (schemas/npcs/<id>.lua):
        WO.NPCs.Register({
            id = "marshal_dughal",
            name = "Маршал Дугхал",
            model = WO.Models.GetRace("human").male[1], -- явный race path; без citizen fallback
            type = "questgiver",            -- questgiver | vendor | talker
            spawns = { { pos = Vector(200, 0, 16), ang = Angle(0, 180, 0) } },
            dialogue = "marshal_intro",     -- id диалога
            quests = { "wolves_of_elwynn" },-- квесты NPC
            vendor = { ... },               -- для type = "vendor" (см. vendors plugin)
            health = 200, hostile = false,  -- враждебный моб
        })
]]

WO.NPCs = WO.NPCs or {}

WO.NPCs.List = WO.NPCs.List or {}
WO.NPCs.Spawned = WO.NPCs.Spawned or {}

---------------------------------------------------------------------------
-- Реестр
---------------------------------------------------------------------------

--- Регистрирует NPC (duplicate id → ошибка, как в остальных реестрах WO).
function WO.NPCs.Register(def)
    if not istable(def) or not isstring(def.id) or def.id == "" then
        WO.Error("WO.NPCs.Register: invalid definition")
        return false
    end

    if WO.NPCs.List[def.id] then
        WO.Error("WO.NPCs.Register: duplicate NPC id '" .. def.id .. "'")
        return false
    end

    def.name = def.name or def.id
    def.type = def.type or "talker"
    def.level = math.max(1, math.floor(tonumber(def.level) or 1))
    def.minLevel = math.max(1, math.floor(tonumber(def.minLevel) or def.level))
    def.maxLevel = math.max(def.minLevel, math.floor(tonumber(def.maxLevel) or def.level))
    def.interactRange = tonumber(def.interactRange) or tonumber(WO.Config.InteractDistance) or 100
    def.spawns = istable(def.spawns) and def.spawns or {}

    if def.workshopClass ~= nil and not isstring(def.workshopClass) then
        WO.Error("WO.NPCs.Register: invalid workshopClass for '" .. def.id .. "'")
        return false
    end

    if def.entityClass ~= nil and (not isstring(def.entityClass) or def.entityClass == "") then
        WO.Error("WO.NPCs.Register: invalid entityClass for '" .. def.id .. "'")
        return false
    end

    WO.NPCs.List[def.id] = def

    WO.Debug("NPC registered: " .. def.id)

    return true
end

--- Получить NPC по id.
function WO.NPCs.Get(id)
    return WO.NPCs.List[id]
end

--- Все NPC.
function WO.NPCs.GetAll()
    return WO.NPCs.List
end

--- Уровень, ограниченный диапазоном конкретной схемы NPC.
function WO.NPCs.ClampLevel(def, level)
    if not istable(def) then return 1 end

    return math.Clamp(math.floor(tonumber(level) or def.level or 1),
        def.minLevel or 1, def.maxLevel or def.level or 1)
end

--- Серверные характеристики уровня, полностью заданные схемой NPC.
function WO.NPCs.GetLevelStats(def, level)
    if not istable(def) then return nil end

    level = WO.NPCs.ClampLevel(def, level)
    local configured = istable(def.levelStats) and def.levelStats[level] or nil

    if not istable(configured) then return nil end

    return {
        health = math.max(1, tonumber(configured.health) or 1),
        damage = math.max(0, tonumber(configured.damage) or 0),
    }
end

--- Все NPC-квестодатели указанного квеста.
function WO.NPCs.GetQuestGivers(questId)
    local out = {}

    for _, def in pairs(WO.NPCs.List) do
        for _, qid in ipairs(def.quests or {}) do
            if qid == questId then
                out[#out + 1] = def
                break
            end
        end
    end

    return out
end

---------------------------------------------------------------------------
-- Интеракция (вызывается из entities/npc/wo_npc.lua)
---------------------------------------------------------------------------

--- Открыть окно NPC: диалог / квесты / торговля.
function WO.NPCs.OnInteract(ent, ply)
    if not IsValid(ent) or not IsValid(ply) or not ply:HasCharacter() then return end
    if ent:GetClass() ~= "wo_npc" then return end

    local def = ent.npcDef

    if not def or WO.NPCs.Get(ent:GetNPCID()) ~= def or def.hostile then return end
    if not WO.Interaction.CanInteract(ent, ply) or
        ply:GetPos():Distance(ent:GetPos()) > WO.Interaction.GetRange(ent) then return end

    -- Диалог содержит data-driven переходы к выдаче задания и торговле.
    if def.dialogue and WO.Dialogue and WO.Dialogue.Open then
        WO.Dialogue.Open(ply, def, ent)
        return
    end

    if def.type == "vendor" and WO.Vendors and WO.Vendors.Open then
        WO.Vendors.Open(ply, def, ent)
        return
    end

    if WO.Quests and WO.Quests.OpenNPC then
        WO.Quests.OpenNPC(ply, def, ent)
    end
end
