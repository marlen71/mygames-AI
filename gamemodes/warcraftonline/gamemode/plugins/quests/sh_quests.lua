--[[
    Warcraft Online — квесты (shared): реестр, состояния, net.

    Схема квеста (schemas/quests/<id>.lua):
        WO.Quests.Register({
            id = "wolves_of_elwynn",
            name = "Волки Элвинна",
            description = "Серые волки терзают путников...",
            level = 2,
            giver = "marshal_dughal",
            steps = {
                { type = "kill",    target = "black_wolf", amount = 3, text = "Победите волков" },
                { type = "collect", class = "wolf_pelt",   amount = 2, text = "Соберите шкуры" },
            },
            rewards = {
                xp = 250,
                money = 120,
                items = { { class = "health_potion", amount = 2 } },
            },
            prerequisites = {},   -- id других квестов, которые надо завершить
        })

    Состояния квеста у персонажа (char.quests[questId]):
        status   = "active" | "completed"
        progress = { [stepIndex] = count }
        tracked  = boolean (отслеживается в HUD)

    Типы шагов:
        "kill"    — убить N целей (target = id NPC или "player")
        "collect" — иметь N предметов класса class (автопроверка по инвентарю)
        "talk"    — поговорить с NPC target (действие talk:<npcId> в диалоге)

    Навигация задаётся в шаге через waypoint = { map, pos, radius } или waypointNPC.
    Kill/talk-цели без явного waypoint автоматически используют spawn-точки NPC.
]]

WO.Quests = WO.Quests or {}

WO.Quests.List = WO.Quests.List or {}

---------------------------------------------------------------------------
-- Реестр
---------------------------------------------------------------------------

--- Регистрирует квест (duplicate id → ошибка).
function WO.Quests.Register(def)
    if not istable(def) or not isstring(def.id) or def.id == "" then
        WO.Error("WO.Quests.Register: invalid definition")
        return false
    end

    if WO.Quests.List[def.id] then
        WO.Error("WO.Quests.Register: duplicate quest id '" .. def.id .. "'")
        return false
    end

    def.name = def.name or def.id
    def.steps = def.steps or {}
    def.rewards = def.rewards or {}
    def.prerequisites = def.prerequisites or {}
    def.level = def.level or 1
    def.repeatInterval = math.max(0, math.floor(tonumber(def.repeatInterval) or 0))

    if #def.steps == 0 then
        WO.Error("WO.Quests.Register: quest '" .. def.id .. "' has no steps")
        return false
    end

    WO.Quests.List[def.id] = def

    WO.Debug("Quest registered: " .. def.id)

    return true
end

--- Получить квест по id.
function WO.Quests.Get(id)
    return WO.Quests.List[id]
end

--- Все квесты.
function WO.Quests.GetAll()
    return WO.Quests.List
end

---------------------------------------------------------------------------
-- Состояние персонажа (shared-помощники; мутации — только на сервере)
---------------------------------------------------------------------------

--- Состояние квеста персонажа (или nil).
function WO.Quests.GetState(char, questId)
    return istable(char) and istable(char.quests) and char.quests[questId] or nil
end

--- Все состояния квестов персонажа.
function WO.Quests.GetStates(char)
    return (istable(char) and char.quests) or {}
end

--- Выполнены ли все шаги квеста.
function WO.Quests.AreStepsDone(char, questId)
    local def = WO.Quests.Get(questId)
    local state = WO.Quests.GetState(char, questId)

    if not def or not state then return false end

    for index, step in ipairs(def.steps) do
        local need = step.amount or 1
        local have = (state.progress or {})[index] or 0

        if have < need then
            return false
        end
    end

    return true
end

---------------------------------------------------------------------------
-- Net
---------------------------------------------------------------------------

WO.Net.Register("Quest.Sync", {
    direction = "toclient",
    write = function(states)
        net.WriteTable(states)
    end,
    read = function()
        return net.ReadTable()
    end,
    handler = function(_, states)
        WO.Quests.LocalStates = states or {}
        WO.Hook.Run("QuestsSynced", WO.Quests.LocalStates)
    end,
})

WO.Net.Register("Quest.ActionResult", {
    direction = "toclient",
    write = function(data)
        net.WriteTable(data)
    end,
    read = function()
        return net.ReadTable()
    end,
    handler = function(_, data)
        WO.Hook.Run("QuestActionResult", data)
    end,
})

WO.Net.Register("Quest.Accept", {
    direction = "toserver",
    rate = { max = 10, window = 1 },
    write = function(questId)
        net.WriteString(questId or "")
    end,
    read = function()
        return net.ReadString()
    end,
    validate = function(ply, questId)
        if not IsValid(ply) or not ply:HasCharacter() then return false, "invalid_player" end
        if not isstring(questId) or questId == "" then return false, "invalid_id" end

        return true
    end,
    handler = function(ply, questId)
        local success, reason = WO.Quests.Accept(ply, questId)

        WO.Net.Send("Quest.ActionResult", ply, {
            action = "accept",
            questId = questId,
            success = success == true,
            reason = reason,
        })
    end,
})

WO.Net.Register("Quest.Abandon", {
    direction = "toserver",
    rate = { max = 8, window = 1 },
    write = function(questId)
        net.WriteString(questId or "")
    end,
    read = function()
        return net.ReadString()
    end,
    validate = function(ply, questId)
        if not IsValid(ply) or not ply:HasCharacter() then return false, "invalid_player" end
        if not isstring(questId) or questId == "" then return false, "invalid_id" end

        return true
    end,
    handler = function(ply, questId)
        local success, reason = WO.Quests.Abandon(ply, questId)

        WO.Net.Send("Quest.ActionResult", ply, {
            action = "abandon",
            questId = questId,
            success = success == true,
            reason = reason,
        })
    end,
})

WO.Net.Register("Quest.Track", {
    direction = "toserver",
    rate = { max = 12, window = 1 },
    write = function(questId, tracked)
        net.WriteString(questId or "")
        net.WriteBool(tracked == true)
    end,
    read = function()
        return net.ReadString(), net.ReadBool()
    end,
    validate = function(ply, questId, tracked)
        if not IsValid(ply) or not ply:HasCharacter() then return false, "invalid_player" end
        if not isstring(questId) or questId == "" then return false, "invalid_id" end
        if not isbool(tracked) then return false, "invalid_state" end

        return true
    end,
    handler = function(ply, questId, tracked)
        local success, reason = WO.Quests.Track(ply, questId, tracked)

        WO.Net.Send("Quest.ActionResult", ply, {
            action = "track",
            questId = questId,
            success = success == true,
            reason = reason,
        })
    end,
})

-- Событие для UI/логов: квест завершён (награда уже выдана)
WO.Net.Register("Quest.Event", {
    direction = "toclient",
    write = function(data)
        net.WriteTable(data)
    end,
    read = function()
        return net.ReadTable()
    end,
    handler = function(_, data)
        WO.Hook.Run("QuestEvent", data)
    end,
})
