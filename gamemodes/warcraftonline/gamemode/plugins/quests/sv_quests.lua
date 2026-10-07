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

local function ProgressReady(ply, questId)
    local char = IsValid(ply) and ply:GetCharacter()
    local def = WO.Quests.Get(questId)
    local state = char and WO.Quests.GetState(char, questId)

    if not def or not state or state.status ~= "active" or
        not WO.Quests.AreStepsDone(char, questId) then
        return false
    end

    if def.turnInRequired then
        if state.turnInNotified then return true end

        state.turnInNotified = true
        local turnInNPC = WO.NPCs and WO.NPCs.Get and
            WO.NPCs.Get(def.turnInGiver or def.giver)
        local turnInName = turnInNPC and turnInNPC.name or (def.turnInGiver or def.giver)

        WO.SaveQueue.MarkDirty(char)
        Sync(ply)
        SendEvent(ply, { type = "ready", questId = questId, name = def.name,
            turnInGiver = def.turnInGiver or def.giver, turnInName = turnInName })
        return true
    end

    return WO.Quests.TryComplete(ply, questId)
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

--- Availability and remaining cooldown for a completed repeatable quest.
function WO.Quests.GetRepeatAvailability(char, questId, now)
    local def = WO.Quests.Get(questId)
    local state = WO.Quests.GetState(char, questId)
    local interval = tonumber(def and def.repeatInterval) or 0

    if interval <= 0 or not state or state.status ~= "completed" then
        return false, 0
    end

    local availableAt = (tonumber(state.completedAt) or 0) + interval
    local remaining = math.max(0, availableAt - (tonumber(now) or WO.Util.Time()))

    return remaining <= 0, remaining
end

local function IsQuestgiverInteractionValid(ply, npcDef, ent, questId, interaction)
    if not IsValid(ply) or not ply:HasCharacter() or not istable(npcDef) or
        not IsValid(ent) or ent:GetClass() ~= "wo_npc" or not isfunction(ent.GetNPCID) or
        ent.npcDef ~= npcDef or not WO.NPCs or WO.NPCs.Get(ent:GetNPCID()) ~= npcDef or
        not WO.Interaction or not WO.Interaction.CanInteract or
        not WO.Interaction.GetRange or not WO.Interaction.CanInteract(ent, ply) or
        ply:GetPos():Distance(ent:GetPos()) > WO.Interaction.GetRange(ent) then
        return false
    end

    if questId then
        local questDef = WO.Quests.Get(questId)

        if not questDef then return false end

        local isGiver = questDef.giver == npcDef.id
        local isTurnIn = (questDef.turnInGiver or questDef.giver) == npcDef.id

        if interaction == "giver" and not isGiver then return false end
        if interaction == "turnin" and not isTurnIn then return false end
        if interaction == "either" and not (isGiver or isTurnIn) then return false end
        if not interaction and not isGiver then return false end

        for _, offeredId in ipairs(npcDef.quests or {}) do
            if offeredId == questId then return true end
        end

        return false
    end

    return true
end

---------------------------------------------------------------------------
-- Принятие / отказ / отслеживание
---------------------------------------------------------------------------

--- Принимает квест (с проверкой уровня, требований и повторов).
function WO.Quests.Accept(ply, questId, npcDef, ent)
    if not IsValid(ply) or not ply:HasCharacter() then return false, "invalid_player" end

    local def = WO.Quests.Get(questId)

    if not def then return false, "unknown_quest" end
    if not IsQuestgiverInteractionValid(ply, npcDef, ent, questId, "giver") then
        return false, "invalid_giver"
    end

    local char = ply:GetCharacter()
    local state = WO.Quests.GetState(char, questId)

    if state and state.status == "failed" then
        char.quests[questId] = nil
        state = nil
    elseif state and state.status == "completed" then
        if (tonumber(def.repeatInterval) or 0) <= 0 then
            return false, "already_completed"
        end

        local repeatReady = WO.Quests.GetRepeatAvailability(char, questId)

        if not repeatReady then return false, "cooldown" end

        char.quests[questId] = nil
        state = nil
    end

    if state then
        return false, "already_active"
    end

    if (char:GetLevel() or 1) < (def.level or 1) then
        return false, "level_too_low"
    end

    if not PrerequisitesDone(char, def) then
        return false, "prerequisites"
    end

    -- Quest-given equipment is schema-driven, server-owned, and granted before
    -- the quest is committed. If inventory placement fails, no quest is accepted.
    local container = WO.Inventory and WO.Inventory.GetContainer and WO.Inventory.GetContainer(char)

    for _, entry in ipairs(def.acceptItems or {}) do
        if not istable(entry) or not isstring(entry.class) or not WO.Items.Get(entry.class) then
            return false, "invalid_accept_item"
        end

        local alreadyOwned = false
        local itemDef = WO.Items.Get(entry.class)

        if itemDef.uniquePerCharacter == true then
            alreadyOwned = container and container:CountItem(entry.class) > 0 or false
            local equipment = WO.Equipment and WO.Equipment.Get and WO.Equipment.Get(char)

            for _, instance in pairs(equipment and equipment.slots or {}) do
                if instance and instance.class == entry.class then
                    alreadyOwned = true
                    break
                end
            end
        end

        if not alreadyOwned then
            local granted, reason = WO.Inventory.GiveItem(ply, entry.class, entry.amount or 1)

            if not granted then
                WO.Notify(ply, "error", reason == "no_space" and
                    "Освободите место в инвентаре, чтобы принять задание и получить предмет." or
                    "Не удалось выдать предмет задания: " .. tostring(reason))
                return false, reason or "accept_item_failed"
            end
        end
    end

    char.quests = char.quests or {}
    char.quests[questId] = {
        status = "active",
        progress = {},
        tracked = true,
        acceptedAt = WO.Util.Time(),
    }

    WO.SaveQueue.MarkDirty(char)
    Sync(ply)
    SendEvent(ply, { type = "accepted", questId = questId, name = def.name })
    WO.Hook.Run("QuestStateChanged", ply, questId, "active")

    WO.Log("Quest accepted: " .. questId .. " by " .. char:GetFullName())

    -- Предметы/экипировка могли быть подготовлены до принятия квеста.
    WO.Quests.RecheckCollect(ply, questId)
    if WO.Quests.RecheckEquipped then WO.Quests.RecheckEquipped(ply, questId) end
    ProgressReady(ply, questId)

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
    WO.Hook.Run("QuestStateChanged", ply, questId, "abandoned")

    return true
end

--- Отмечает активное задание проваленным (server API, например для будущих таймеров).
function WO.Quests.Fail(ply, questId, reason)
    if not IsValid(ply) or not ply:HasCharacter() then return false, "invalid_player" end

    local char = ply:GetCharacter()
    local state = WO.Quests.GetState(char, questId)

    if not state or state.status ~= "active" then return false, "not_active" end

    local def = WO.Quests.Get(questId)
    state.status = "failed"
    state.failedAt = WO.Util.Time()
    state.failReason = tostring(reason or "failed")

    WO.SaveQueue.MarkDirty(char)
    Sync(ply)
    SendEvent(ply, { type = "failed", questId = questId,
        name = def and def.name or questId, reason = state.failReason })
    WO.Hook.Run("QuestStateChanged", ply, questId, "failed")
    return true
end

--- Включает/выключает отслеживание в HUD.
function WO.Quests.Track(ply, questId, tracked)
    if not IsValid(ply) or not ply:HasCharacter() then return false, "invalid_player" end

    local char = ply:GetCharacter()
    local state = WO.Quests.GetState(char, questId)

    if not state or state.status ~= "active" then return false, "not_active" end

    state.tracked = tracked == true

    WO.SaveQueue.MarkDirty(char)
    Sync(ply)
    return true
end

---------------------------------------------------------------------------
-- Прогресс шагов
---------------------------------------------------------------------------

local function PreviousStepsDone(state, def, stepIndex)
    if not def.sequential then return true end

    for index = 1, stepIndex - 1 do
        local need = def.steps[index].amount or 1
        local have = (state.progress or {})[index] or 0

        if have < need then return false end
    end

    return true
end

local function StepProgress(char, state, def, stepIndex, value)
    local step = def.steps[stepIndex]

    if not step or not PreviousStepsDone(state, def, stepIndex) then return false end

    local need = step.amount or 1
    local have = math.max(0, math.min(tonumber(value) or 0, need))

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

    if not def or not state or state.status ~= "active" or state.turningIn or
        not PrerequisitesDone(char, def) then return false end

    local container = WO.Inventory and WO.Inventory.GetContainer(char)
    local changed = false

    if not container then return false end

    for index, step in ipairs(def.steps) do
        if step.type == "collect" and step.class then
            local have = container:CountItem(step.class)

            if not PreviousStepsDone(state, def, index) then
                have = 0
            end

            if StepProgress(char, state, def, index, have) then
                changed = true
                SendEvent(ply, { type = "progress", questId = questId, name = def.name,
                    text = step.text or step.class,
                    have = math.min(have, step.amount or 1), need = step.amount or 1 })
            end
        end
    end

    if changed then
        if not WO.Quests.AreStepsDone(char, questId) then state.turnInNotified = nil end
        WO.SaveQueue.MarkDirty(char)
        Sync(ply)
        ProgressReady(ply, questId)
    end

    return changed
end

--- Обновляет kill/talk-шаги; sequential quests принимают только текущий этап.
local function ProgressStep(ply, stepType, targetId, targetLevel)
    if not IsValid(ply) or not ply:HasCharacter() then return end

    local char = ply:GetCharacter()
    local changedQuests = {}
    local progressEvents = {}

    for questId, state in pairs(char.quests or {}) do
        local def = WO.Quests.Get(questId)

        if def and state.status == "active" and PrerequisitesDone(char, def) then
            for index, step in ipairs(def.steps) do
                if step.type == stepType and step.target == targetId and
                    (not step.level or tonumber(step.level) == tonumber(targetLevel)) then
                    local have = ((state.progress or {})[index] or 0) + 1

                    if StepProgress(char, state, def, index, have) then
                        changedQuests[questId] = true
                        progressEvents[#progressEvents + 1] = {
                            type = "progress", questId = questId, name = def.name,
                            text = step.text or step.target or step.type,
                            have = math.min(have, step.amount or 1), need = step.amount or 1,
                        }
                    end
                end
            end
        end
    end

    if next(changedQuests) then
        WO.SaveQueue.MarkDirty(char)
        Sync(ply)

        for _, event in ipairs(progressEvents) do SendEvent(ply, event) end

        for questId in pairs(changedQuests) do
            -- A newly unlocked sequential step may already be satisfied by the
            -- current inventory/equipment; re-evaluate it on the server.
            WO.Quests.RecheckCollect(ply, questId)
            WO.Quests.RecheckEquipped(ply, questId)
            ProgressReady(ply, questId)
        end
    end
end

function WO.Quests.RecheckEquipped(ply, questId)
    if not IsValid(ply) or not ply:HasCharacter() then return false end

    local char = ply:GetCharacter()
    local container = WO.Inventory and WO.Inventory.GetContainer(char)
    local def = WO.Quests.Get(questId)
    local state = WO.Quests.GetState(char, questId)
    local equipment = WO.Equipment and WO.Equipment.Get and WO.Equipment.Get(char)

    if not def or not state or state.status ~= "active" or state.turningIn or
        not equipment or not PrerequisitesDone(char, def) then
        return false
    end

    local changed = false

    for index, step in ipairs(def.steps) do
        if step.type == "equip" and step.class then
            local have = 0

            for _, instance in pairs(equipment.slots or {}) do
                if instance and instance.class == step.class then
                    have = have + (instance.amount or 1)
                end
            end

            if not PreviousStepsDone(state, def, index) then
                have = 0
            else
                -- Equip is an action step: once the player has equipped the
                -- required item, later unequipping must not erase that progress.
                have = math.max(have, (state.progress or {})[index] or 0)
            end

            if StepProgress(char, state, def, index, have) then
                changed = true
                SendEvent(ply, { type = "progress", questId = questId, name = def.name,
                    text = step.text or step.class, have = math.min(have, step.amount or 1),
                    need = step.amount or 1 })
            end
        end
    end

    if changed then
        WO.SaveQueue.MarkDirty(char)
        Sync(ply)
        ProgressReady(ply, questId)
    end

    return changed
end

local function ProgressEquippedItem(char, instance)
    local ply = char and char.player

    if not IsValid(ply) or not instance or not instance.class then return end

    for questId, state in pairs(char.quests or {}) do
        local def = WO.Quests.Get(questId)

        if def and state.status == "active" and PrerequisitesDone(char, def) then
            for index, step in ipairs(def.steps) do
                if step.type == "equip" and step.class == instance.class and
                    PreviousStepsDone(state, def, index) then
                    if StepProgress(char, state, def, index,
                        ((state.progress or {})[index] or 0) + 1) then
                        WO.SaveQueue.MarkDirty(char)
                        Sync(ply)
                        SendEvent(ply, { type = "progress", questId = questId,
                            name = def.name, text = step.text or step.class,
                            have = step.amount or 1, need = step.amount or 1 })
                        ProgressReady(ply, questId)
                    end
                end
            end
        end
    end
end

WO.Hook.Add("ItemEquipped", "quests_equip_progress", ProgressEquippedItem)

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

local function ConsumeTurnInItems(ply, def)
    local char = ply:GetCharacter()
    local container = WO.Inventory and WO.Inventory.GetContainer(char)

    if not container then return false, "no_container" end

    local required = {}

    for _, step in ipairs(def.steps or {}) do
        if step.type == "collect" and step.consume == true and step.class then
            required[step.class] = (required[step.class] or 0) + math.max(1, math.floor(tonumber(step.amount) or 1))
        end
    end

    for class, amount in pairs(required) do
        if container:CountItem(class) < amount then return false, "missing_items" end
    end

    local uids = {}

    for uid in pairs(container:GetItems() or {}) do uids[#uids + 1] = uid end
    table.sort(uids)

    for class, remaining in pairs(required) do
        for _, uid in ipairs(uids) do
            if remaining <= 0 then break end

            local instance = container:GetItem(uid)

            if instance and instance.class == class then
                local amount = math.min(remaining, instance.amount or 1)

                if not WO.Inventory.RemoveItem(ply, uid, amount) then
                    return false, "consume_failed"
                end

                remaining = remaining - amount
            end
        end

        if remaining > 0 then return false, "missing_items" end
    end

    return true
end

--- Проверяет готовность; обычные квесты закрываются автоматически, turn-in квесты — у NPC.
function WO.Quests.TryComplete(ply, questId, turnInContext)
    if not IsValid(ply) or not ply:HasCharacter() then return false end

    local char = ply:GetCharacter()
    local def = WO.Quests.Get(questId)
    local state = WO.Quests.GetState(char, questId)

    if not def or not state or state.status ~= "active" or state.turningIn then return false end

    if not PrerequisitesDone(char, def) then
        WO.Notify(ply, "error", "Сначала завершите предыдущие задания в цепочке.")
        return false
    end

    if not WO.Quests.AreStepsDone(char, questId) then return false end

    if def.turnInRequired == true then
        if not istable(turnInContext) or
            not IsQuestgiverInteractionValid(ply, turnInContext.npcDef,
                turnInContext.ent, questId, "turnin") then
            ProgressReady(ply, questId)
            return false
        end

        state.turningIn = true
        local consumed, consumeReason = ConsumeTurnInItems(ply, def)
        state.turningIn = nil

        if not consumed then
            WO.Notify(ply, "error", "Не удалось сдать предметы: " .. tostring(consumeReason))
            return false
        end
    end

    state.status = "completed"
    state.completedAt = WO.Util.Time()
    state.turnInNotified = nil

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

    WO.Hook.Run("QuestStateChanged", ply, questId, "completed")
    WO.Log("Quest completed: " .. questId .. " by " .. char:GetFullName())

    return true
end

function WO.Quests.TurnIn(ply, questId, npcDef, ent)
    if not IsQuestgiverInteractionValid(ply, npcDef, ent, questId, "turnin") then
        return false, "invalid_turnin"
    end

    local char = ply:GetCharacter()
    local def = WO.Quests.Get(questId)
    local state = WO.Quests.GetState(char, questId)

    if not def or not state or state.status ~= "active" then return false, "not_active" end

    if not def.turnInRequired then
        return WO.Quests.TryComplete(ply, questId)
    end

    WO.Quests.RecheckCollect(ply, questId)
    if WO.Quests.RecheckEquipped then WO.Quests.RecheckEquipped(ply, questId) end

    if not WO.Quests.AreStepsDone(char, questId) then
        SendEvent(ply, { type = "info", questId = questId, text = WO.Lang:Get("quest.in_progress") })
        return false, "incomplete"
    end

    return WO.Quests.TryComplete(ply, questId, { npcDef = npcDef, ent = ent })
end

---------------------------------------------------------------------------
-- События прогресса
---------------------------------------------------------------------------

-- Сбор предметов
local function RecheckChangedCollectItem(char, instance)
    local ply = char and char.player

    if not IsValid(ply) or not instance then return end

    for questId, state in pairs(char.quests or {}) do
        local def = WO.Quests.Get(questId)

        if def and state.status == "active" then
            for _, step in ipairs(def.steps) do
                if step.type == "collect" and step.class == instance.class then
                    WO.Quests.RecheckCollect(ply, questId)
                    break
                end
            end
        end
    end
end

WO.Hook.Add("ItemAdded", "quests", RecheckChangedCollectItem)
WO.Hook.Add("ItemRemoved", "quests", RecheckChangedCollectItem)

-- Убийства NPC
WO.Hook.Add("NPCKilled", "quests", function(npcDef, ply, level)
    if npcDef and npcDef.id then
        ProgressStep(ply, "kill", npcDef.id, level)
    end
end)

-- Разговоры (действие talk:<npcId> в диалогах)
function WO.Quests.OnTalk(ply, npcId)
    ProgressStep(ply, "talk", npcId)
end

---------------------------------------------------------------------------
-- Предложение квеста из диалога
---------------------------------------------------------------------------

--- Действие "quest:<id>" принимает задание у giver или сдаёт его у turnInGiver.
function WO.Quests.OfferFromDialogue(ply, questId, npcDef, ent)
    if not IsQuestgiverInteractionValid(ply, npcDef, ent, questId, "either") then return false end

    local def = WO.Quests.Get(questId)

    if not def then
        WO.Error("WO.Quests.OfferFromDialogue: unknown quest '" .. tostring(questId) .. "'")
        return false
    end

    local char = ply:GetCharacter()
    local state = WO.Quests.GetState(char, questId)

    if state and state.status == "completed" then
        local repeatReady = WO.Quests.GetRepeatAvailability(char, questId)

        if not repeatReady then
            local message = (tonumber(def.repeatInterval) or 0) > 0 and
                "Это поручение можно будет повторить примерно через 15 минут." or
                WO.Lang:Get("quest.already_completed")
            SendEvent(ply, { type = "info", questId = questId, text = message })
            return false
        end

        char.quests[questId] = nil
        state = nil
    elseif state and state.status == "failed" then
        char.quests[questId] = nil
        state = nil
    end

    if state and state.status == "active" then
        if (def.turnInGiver or def.giver) == npcDef.id and def.turnInRequired then
            return WO.Quests.TurnIn(ply, questId, npcDef, ent)
        end

        if def.giver == npcDef.id and not def.turnInRequired and
            WO.Quests.AreStepsDone(char, questId) then
            return WO.Quests.TryComplete(ply, questId)
        end

        local turnInNPC = WO.NPCs.Get(def.turnInGiver or def.giver)
        local message = WO.Lang:Get("quest.in_progress")

        if def.turnInRequired and WO.Quests.AreStepsDone(char, questId) and turnInNPC then
            message = "Готово. Вернитесь к " .. turnInNPC.name .. "."
        end

        SendEvent(ply, { type = "info", questId = questId, text = message })
        return false
    end

    if def.giver ~= npcDef.id then
        local giver = WO.NPCs.Get(def.giver)
        local giverName = giver and giver.name or def.giver
        SendEvent(ply, { type = "info", questId = questId,
            text = "Это задание выдаёт " .. tostring(giverName) .. "." })
        return false
    end

    local ok, reason = WO.Quests.Accept(ply, questId, npcDef, ent)

    if not ok then
        local message

        if reason == "prerequisites" then
            message = "Сначала завершите предыдущее задание в цепочке."
        elseif reason == "level_too_low" then
            message = "Ваш уровень пока слишком низок для этого задания."
        else
            message = WO.Lang:Get("quest.not_available") .. " (" .. tostring(reason) .. ")"
        end

        SendEvent(ply, { type = "info", questId = questId, text = message })
        return false
    end

    -- Разговор с этим NPC уже состоялся — засчитываем talk-шаги.
    for _, step in ipairs(def.steps or {}) do
        if step.type == "talk" and step.target == npcDef.id then
            WO.Quests.OnTalk(ply, npcDef.id)
            break
        end
    end

    return true
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
                failedAt = state.failedAt,
                failReason = state.failReason,
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
            failedAt = data.failedAt,
            failReason = data.failReason,
        }
    end
end)

WO.Hook.Add("CharacterLoaded", "quests", function(char, ply)
    Sync(ply)

    if not IsValid(ply) and char then ply = char.player end
    if not IsValid(ply) or not ply:HasCharacter() then return end

    for questId, state in pairs(char.quests or {}) do
        if state.status == "active" then
            local def = WO.Quests.Get(questId)

            if def and not PrerequisitesDone(char, def) then
                WO.Quests.Fail(ply, questId, "prerequisite_migration")
            else
                WO.Quests.RecheckCollect(ply, questId)
                WO.Quests.RecheckEquipped(ply, questId)
                ProgressReady(ply, questId)
            end
        end
    end
end)

---------------------------------------------------------------------------
-- Открытие списка квестов NPC (без диалога)
---------------------------------------------------------------------------

--- Показывает доступные квесты NPC (используется из WO.NPCs.OnInteract).
function WO.Quests.OpenNPC(ply, npcDef, ent)
    if not IsQuestgiverInteractionValid(ply, npcDef, ent) then return end

    local char = ply:GetCharacter()

    for _, questId in ipairs(npcDef.quests or {}) do
        local def = WO.Quests.Get(questId)
        local state = WO.Quests.GetState(char, questId)

        if state and state.status == "failed" then
            state = nil
        end

        if state and state.status == "active" and
            (def.turnInGiver or def.giver) == npcDef.id then
            if def.turnInRequired and WO.Quests.AreStepsDone(char, questId) then
                WO.Quests.TurnIn(ply, questId, npcDef, ent)
            else
                SendEvent(ply, { type = "info", questId = questId,
                    text = WO.Lang:Get("quest.in_progress") })
            end
            return
        end

        if not state and def and def.giver == npcDef.id then
            WO.Quests.OfferFromDialogue(ply, questId, npcDef, ent)
            return
        end
    end

    SendEvent(ply, { type = "info", text = WO.Lang:Get("quest.no_quests") })
end
