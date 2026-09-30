--[[
    Warcraft Online — квесты (server): принятие, прогресс, награды, персистентность.
    Сервер — единственный авторитет прогресса и наград.
]]

---------------------------------------------------------------------------
-- Синхронизация клиенту
---------------------------------------------------------------------------

local function Sync(ply)
    if not IsValid(ply) then return end

    local char = ply:GetCharacter()

    if not char then return end

    WO.Net.Send("Quest.Sync", ply, char.quests or {})
end

local function SendEvent(ply, data)
    WO.Net.Send("Quest.Event", ply, data)
end

---------------------------------------------------------------------------
-- Проверки доступности
---------------------------------------------------------------------------

local function PrerequisitesDone(char, def)
    for _, prereqId in ipairs(def.prerequisites or {}) do
        local state = WO.Quests.GetState(char, prereqId)

        if not state or state.status ~= "completed" then
            return false
        end
    end

    return true
end

---------------------------------------------------------------------------
-- Принятие / отказ / отслеживание
---------------------------------------------------------------------------

--- Принимает квест (с проверкой уровня, требований и повторов).
function WO.Quests.Accept(ply, questId)
    if not IsValid(ply) or not ply:HasCharacter() then return false, "invalid_player" end

    local char = ply:GetCharacter()
    local def = WO.Quests.Get(questId)

    if not def then return false, "unknown_quest" end

    local state = WO.Quests.GetState(char, questId)

    if state then
        return false, state.status == "completed" and "already_completed" or "already_active"
    end

    if (char:GetLevel() or 1) < (def.level or 1) then
        return false, "level_too_low"
    end

    if not PrerequisitesDone(char, def) then
        return false, "prerequisites"
    end

    char.quests = char.quests or {}
    char.quests[questId] = {
        status = "active",
        progress = {},
        tracked = true,
        acceptedAt = WO.Util.Time(),
    }

    -- collect-шаги могли быть уже выполнены (предметы уже в инвентаре)
    WO.Quests.RecheckCollect(ply, questId)

    WO.SaveQueue.MarkDirty(char)
    Sync(ply)
    SendEvent(ply, { type = "accepted", questId = questId, name = def.name })

    WO.Log("Quest accepted: " .. questId .. " by " .. char:GetFullName())

    -- Возможно, квест сразу готов к сдаче
    WO.Quests.TryComplete(ply, questId)

    return true
end

--- Отказывается от квеста (только активного, не завершённого).
function WO.Quests.Abandon(ply, questId)
    if not IsValid(ply) or not ply:HasCharacter() then return false, "invalid_player" end

    local char = ply:GetCharacter()
    local state = WO.Quests.GetState(char, questId)

    if not state or state.status ~= "active" then
        return false, "not_active"
    end

    char.quests[questId] = nil

    WO.SaveQueue.MarkDirty(char)
    Sync(ply)
    SendEvent(ply, { type = "abandoned", questId = questId })

    return true
end

--- Включает/выключает отслеживание в HUD.
function WO.Quests.Track(ply, questId, tracked)
    if not IsValid(ply) or not ply:HasCharacter() then return end

    local char = ply:GetCharacter()
    local state = WO.Quests.GetState(char, questId)

    if not state then return end

    state.tracked = tracked == true

    WO.SaveQueue.MarkDirty(char)
    Sync(ply)
end

---------------------------------------------------------------------------
-- Прогресс шагов
---------------------------------------------------------------------------

local function StepProgress(char, state, def, stepIndex, value)
    local step = def.steps[stepIndex]

    if not step then return false end

    local need = step.amount or 1
    local have = math.min(value, need)

    if (state.progress or {})[stepIndex] == have then
        return false
    end

    state.progress = state.progress or {}
    state.progress[stepIndex] = have

    return true
end

--- Пересчитывает collect-шаги по содержимому инвентаря.
function WO.Quests.RecheckCollect(ply, questId)
    if not IsValid(ply) or not ply:HasCharacter() then return false end

    local char = ply:GetCharacter()
    local def = WO.Quests.Get(questId)
    local state = WO.Quests.GetState(char, questId)

    if not def or not state or state.status ~= "active" then return false end

    local container = WO.Inventory and WO.Inventory.GetContainer(char)
    local changed = false

    if not container then return false end

    for index, step in ipairs(def.steps) do
        if step.type == "collect" and step.class then
            local have = container:CountItem(step.class)

            if StepProgress(char, state, def, index, have) then
                changed = true
            end
        end
    end

    if changed then
        WO.SaveQueue.MarkDirty(char)
        Sync(ply)
    end

    return changed
end

--- Обновляет kill/talk-шаги.
local function ProgressStep(ply, stepType, targetId)
    if not IsValid(ply) or not ply:HasCharacter() then return end

    local char = ply:GetCharacter()
    local changedQuests = false

    for questId, state in pairs(char.quests or {}) do
        local def = WO.Quests.Get(questId)

        if def and state.status == "active" then
            for index, step in ipairs(def.steps) do
                if step.type == stepType and step.target == targetId then
                    local have = ((state.progress or {})[index] or 0) + 1

                    if StepProgress(char, state, def, index, have) then
                        changedQuests = true
                    end
                end
            end
        end
    end

    if changedQuests then
        WO.SaveQueue.MarkDirty(char)
        Sync(ply)

        for questId in pairs(char.quests or {}) do
            WO.Quests.TryComplete(ply, questId)
        end
    end
end

---------------------------------------------------------------------------
-- Завершение и награды
---------------------------------------------------------------------------

--- Выдаёт награды за квест (только сервер).
local function GrantRewards(ply, def)
    local char = ply:GetCharacter()
    local rewards = def.rewards or {}

    if rewards.xp and WO.Leveling and WO.Leveling.AddXP then
        WO.Leveling.AddXP(ply, rewards.xp, "quest:" .. def.id)
    end

    if rewards.money and WO.Currency and WO.Currency.Add then
        WO.Currency.Add(ply, rewards.money, "quest:" .. def.id)
    end

    local itemsGiven = {}

    for _, entry in ipairs(rewards.items or {}) do
        if WO.Inventory and WO.Inventory.GiveItem then
            if WO.Inventory.GiveItem(ply, entry.class, entry.amount or 1) ~= false then
                itemsGiven[#itemsGiven + 1] = { class = entry.class, amount = entry.amount or 1 }
            end
        end
    end

    WO.Log("Quest rewards granted: " .. def.id .. " -> " .. char:GetFullName() ..
        " (xp " .. tostring(rewards.xp or 0) .. ", money " .. tostring(rewards.money or 0) .. ")")

    return itemsGiven
end

--- Проверяет готовность и завершает квест (автоматически).
function WO.Quests.TryComplete(ply, questId)
    if not IsValid(ply) or not ply:HasCharacter() then return false end

    local char = ply:GetCharacter()
    local def = WO.Quests.Get(questId)
    local state = WO.Quests.GetState(char, questId)

    if not def or not state or state.status ~= "active" then return false end

    if not WO.Quests.AreStepsDone(char, questId) then
        return false
    end

    state.status = "completed"
    state.completedAt = WO.Util.Time()

    local itemsGiven = GrantRewards(ply, def)

    WO.SaveQueue.MarkDirty(char)
    Sync(ply)
    SendEvent(ply, {
        type = "completed",
        questId = questId,
        name = def.name,
        rewards = {
            xp = def.rewards and def.rewards.xp or 0,
            money = def.rewards and def.rewards.money or 0,
            items = itemsGiven,
        },
    })

    WO.Log("Quest completed: " .. questId .. " by " .. char:GetFullName())

    return true
end

---------------------------------------------------------------------------
-- События прогресса
---------------------------------------------------------------------------

-- Сбор предметов
WO.Hook.Add("ItemAdded", "quests", function(char, instance, amount)
    local ply = char and char.player

    if not IsValid(ply) then return end

    for questId, state in pairs(char.quests or {}) do
        local def = WO.Quests.Get(questId)

        if def and state.status == "active" then
            for _, step in ipairs(def.steps) do
                if step.type == "collect" and step.class == (instance and instance.class) then
                    WO.Quests.RecheckCollect(ply, questId)
                    break
                end
            end
        end
    end
end)

-- Убийства NPC
WO.Hook.Add("NPCKilled", "quests", function(npcDef, ply)
    if npcDef and npcDef.id then
        ProgressStep(ply, "kill", npcDef.id)
    end
end)

-- Разговоры (действие talk:<npcId> в диалогах)
function WO.Quests.OnTalk(ply, npcId)
    ProgressStep(ply, "talk", npcId)
end

---------------------------------------------------------------------------
-- Предложение квеста из диалога
---------------------------------------------------------------------------

--- Действие "quest:<id>" в диалоге: принять/показать состояние.
function WO.Quests.OfferFromDialogue(ply, questId, npcDef)
    if not IsValid(ply) or not ply:HasCharacter() then return end

    local def = WO.Quests.Get(questId)

    if not def then
        WO.Error("WO.Quests.OfferFromDialogue: unknown quest '" .. tostring(questId) .. "'")
        return
    end

    local state = WO.Quests.GetState(ply:GetCharacter(), questId)

    if state and state.status == "completed" then
        SendEvent(ply, { type = "info", questId = questId, text = WO.Lang:Get("quest.already_completed") })
        return
    end

    if state and state.status == "active" then
        SendEvent(ply, { type = "info", questId = questId, text = WO.Lang:Get("quest.in_progress") })
        WO.Quests.TryComplete(ply, questId)
        return
    end

    local ok, reason = WO.Quests.Accept(ply, questId)

    if not ok then
        SendEvent(ply, {
            type = "info",
            questId = questId,
            text = WO.Lang:Get("quest.not_available") .. " (" .. tostring(reason) .. ")",
        })

        return
    end

    -- Разговор с этим NPC уже состоялся — засчитываем talk-шаги
    if npcDef and npcDef.id then
        for index, step in ipairs(def.steps or {}) do
            if step.type == "talk" and step.target == npcDef.id then
                WO.Quests.OnTalk(ply, npcDef.id)
                break
            end
        end
    end
end

---------------------------------------------------------------------------
-- Персистентность (wo_quests)
---------------------------------------------------------------------------

WO.Hook.Add("CharacterSave", "quests", function(char)
    if not char.id then return end

    WO.Database:Delete("wo_quests", "owner_id = ?", char.id)

    for questId, state in pairs(char.quests or {}) do
        WO.Database:Insert("wo_quests", {
            owner_id = char.id,
            quest_id = questId,
            data = util.TableToJSON({
                status = state.status,
                progress = state.progress or {},
                tracked = state.tracked == true,
                acceptedAt = state.acceptedAt,
                completedAt = state.completedAt,
            }),
            completed = (state.status == "completed") and 1 or 0,
        })
    end
end)

WO.Hook.Add("CharacterLoad", "quests", function(char)
    char.quests = {}

    local rows = WO.Database:Fetch("SELECT * FROM wo_quests WHERE owner_id = ?", char.id)

    for _, row in ipairs(rows or {}) do
        local data = util.JSONToTable(row.data or "") or {}
        local progress = {}

        if istable(data.progress) then
            for k, v in pairs(data.progress) do
                progress[tonumber(k) or k] = tonumber(v) or 0
            end
        end

        char.quests[row.quest_id] = {
            status = (tonumber(row.completed) == 1) and "completed" or (data.status or "active"),
            progress = progress,
            tracked = data.tracked == true,
            acceptedAt = data.acceptedAt,
            completedAt = data.completedAt,
        }
    end
end)

WO.Hook.Add("CharacterLoaded", "quests", function(char, ply)
    Sync(ply)
end)

---------------------------------------------------------------------------
-- Открытие списка квестов NPC (без диалога)
---------------------------------------------------------------------------

--- Показывает доступные квесты NPC (используется из WO.NPCs.OnInteract).
function WO.Quests.OpenNPC(ply, npcDef)
    if not IsValid(ply) then return end

    local char = ply:GetCharacter()

    if not char then return end

    for _, questId in ipairs(npcDef.quests or {}) do
        local state = WO.Quests.GetState(char, questId)

        if not state then
            WO.Quests.OfferFromDialogue(ply, questId, npcDef)
            return
        elseif state.status == "active" then
            WO.Quests.TryComplete(ply, questId)
            SendEvent(ply, { type = "info", questId = questId, text = WO.Lang:Get("quest.in_progress") })
            return
        end
    end

    SendEvent(ply, { type = "info", text = WO.Lang:Get("quest.no_quests") })
end
