--[[
    Warcraft Online — NPC (shared): реестр и API.

    Схема NPC (schemas/npcs/<id>.lua):
        WO.NPCs.Register({
            id = "marshal_dughal",
            name = "Маршал Дугхал",
            model = "models/player/Group01/male_02.mdl",
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
    def.model = def.model or "models/player/Group01/male_01.mdl"
    def.interactRange = def.interactRange or 140
    def.spawns = def.spawns or {}

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
    if not IsValid(ent) or not IsValid(ply) then return end

    local def = ent.npcDef

    if not def then return end

    -- Дистанция — финальная проверка (серверный авторитет)
    if ply:GetPos():Distance(ent:GetPos()) > (def.interactRange or 140) + 24 then
        return
    end

    -- Приоритет: диалог (из него доступны квесты и торговля) → торговля → квесты
    if def.dialogue and WO.Dialogue and WO.Dialogue.Open then
        WO.Dialogue.Open(ply, def)

        return
    end

    if def.type == "vendor" and WO.Vendors and WO.Vendors.Open then
        WO.Vendors.Open(ply, def)

        return
    end

    if WO.Quests and WO.Quests.OpenNPC then
        WO.Quests.OpenNPC(ply, def)
    end
end
