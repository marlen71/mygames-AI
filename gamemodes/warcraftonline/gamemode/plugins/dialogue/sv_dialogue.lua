--[[
    Warcraft Online — диалоги (server): сессии, валидация, действия.
    Клиент НИКОГДА не выбирает «текст» — только индекс валидного варианта.
]]

---------------------------------------------------------------------------
-- Сессии
---------------------------------------------------------------------------

local function GetSession(ply)
    return ply.wo_dialogue
end

local function ClearSession(ply)
    ply.wo_dialogue = nil
end

--- Проверяет, что сессия жива (NPC существует, игрок рядом).
local function SessionValid(ply)
    local session = GetSession(ply)

    if not session or not IsValid(ply) or not ply:HasCharacter() then return false end

    local ent = session.ent

    if not IsValid(ent) or ent:GetClass() ~= "wo_npc" or
        ent.npcDef ~= session.npcDef or
        not WO.NPCs or WO.NPCs.Get(ent:GetNPCID()) ~= session.npcDef then
        ClearSession(ply)
        return false
    end

    local range = WO.Interaction.GetRange(ent)

    if ply:GetPos():Distance(ent:GetPos()) > range then
        ClearSession(ply)
        return false
    end

    return true
end

local function QuestPrerequisitesMet(char, questDef)
    for _, prerequisite in ipairs(questDef.prerequisites or {}) do
        local state = char.quests and char.quests[prerequisite]
        if not state or state.status ~= "completed" then return false end
    end

    return true
end

local function QuestProgressLabel(char, questDef, state)
    for index, step in ipairs(questDef.steps or {}) do
        local need = math.max(1, tonumber(step.amount) or 1)
        local have = math.min(need, tonumber(state.progress and state.progress[index]) or 0)

        if have < need then
            return (step.text or step.target or questDef.name) .. " (" .. have .. "/" .. need .. ")"
        end
    end

    return "Цели выполнены — можно сдать задание"
end

local function BuildNodeOptions(ply, npcDef, node)
    local char = ply:GetCharacter()
    local options = {}

    for _, option in ipairs(node.options or {}) do
        local questId = string.match(option.action or "", "^quest:([%w_]+)$")

        if not questId then
            options[#options + 1] = option
        else
            local questDef = WO.Quests and WO.Quests.Get and WO.Quests.Get(questId)
            local offeredHere = false

            for _, offeredId in ipairs(npcDef.quests or {}) do
                if offeredId == questId then offeredHere = true break end
            end

            local isGiver = questDef and questDef.giver == npcDef.id
            local isTurnIn = questDef and (questDef.turnInGiver or questDef.giver) == npcDef.id
            local state = char and char.quests and char.quests[questId]

            if questDef and offeredHere and (isGiver or isTurnIn) then
                if state and state.status == "active" then
                    local ready = WO.Quests.AreStepsDone(char, questId)
                    local label

                    if isTurnIn and questDef.turnInRequired and ready then
                        label = "Сдать задание: " .. questDef.name
                    else
                        label = "Проверить задание: " .. QuestProgressLabel(char, questDef, state)
                    end

                    options[#options + 1] = { text = label, action = option.action }
                    options[#options + 1] = {
                        text = "Отказаться от задания: " .. questDef.name,
                        action = "abandon:" .. questId,
                    }
                elseif isGiver and (not state or state.status == "failed") and
                    QuestPrerequisitesMet(char, questDef) and
                    (char:GetLevel() or 1) >= (questDef.level or 1) then
                    options[#options + 1] = {
                        text = (state and "Повторить задание: " or "Взять задание: ") .. questDef.name,
                        action = option.action,
                    }
                end
            end
        end
    end

    return options
end

--- Отправляет узел диалога клиенту с серверно вычисленными quest options.
local function SendNode(ply, dialogueId, nodeId)
    local def = WO.Dialogue.Get(dialogueId)
    local node = def and def.nodes[nodeId]

    if not node then
        WO.Error("WO.Dialogue: unknown node '" .. tostring(dialogueId) .. "/" .. tostring(nodeId) .. "'")
        return
    end

    local session = GetSession(ply)

    if not session then return end

    session.nodeId = nodeId
    session.options = BuildNodeOptions(ply, session.npcDef, node)

    WO.Net.Send("Dialogue.Open", ply, {
        dialogueId = dialogueId,
        nodeId = nodeId,
        npcId = session.npcDef and session.npcDef.id or "",
        npcName = session.npcDef and session.npcDef.name or "",
        text = node.text or "",
        options = session.options,
    })
end

---------------------------------------------------------------------------
-- API (вызывается из WO.NPCs.OnInteract)
---------------------------------------------------------------------------

--- Открыть диалог NPC для игрока.
function WO.Dialogue.Open(ply, npcDef, ent)
    if not IsValid(ply) or not ply:HasCharacter() or not istable(npcDef) then return end

    local dialogueId = npcDef.dialogue

    if not dialogueId or not WO.Dialogue.Get(dialogueId) then
        WO.Error("WO.Dialogue.Open: NPC '" .. tostring(npcDef.id) .. "' has no dialogue '" .. tostring(dialogueId) .. "'")
        return
    end

    if not IsValid(ent) or ent:GetClass() ~= "wo_npc" or ent.npcDef ~= npcDef or
        WO.NPCs.Get(ent:GetNPCID()) ~= npcDef or
        not WO.Interaction.CanInteract(ent, ply) or
        ply:GetPos():Distance(ent:GetPos()) > WO.Interaction.GetRange(ent) then
        return
    end

    ply.wo_dialogue = {
        ent = ent,
        npcDef = npcDef,
        dialogueId = dialogueId,
    }

    SendNode(ply, dialogueId, "start")
end

---------------------------------------------------------------------------
-- Выполнение действия
---------------------------------------------------------------------------

local function RunAction(ply, action)
    action = action or "close"

    local verb, arg = string.match(action, "^([%w_]+):?(.*)$")

    if action == "close" then
        ClearSession(ply)
        WO.Net.Send("Dialogue.Finish", ply)
        return
    end

    if verb == "next" and arg ~= "" then
        local session = GetSession(ply)

        if session then
            SendNode(ply, session.dialogueId, arg)
        end

        return
    end

    if verb == "quest" and arg ~= "" then
        local session = GetSession(ply)

        if session and WO.Quests and WO.Quests.OfferFromDialogue then
            WO.Quests.OfferFromDialogue(ply, arg, session.npcDef, session.ent)
            if SessionValid(ply) then SendNode(ply, session.dialogueId, session.nodeId) end
        end

        return
    end

    if verb == "abandon" and arg ~= "" then
        local session = GetSession(ply)
        local questDef = WO.Quests and WO.Quests.Get and WO.Quests.Get(arg)
        local npcId = session and session.npcDef and session.npcDef.id
        local listed = false

        for _, offeredId in ipairs(session and session.npcDef and session.npcDef.quests or {}) do
            if offeredId == arg then listed = true break end
        end

        if session and questDef and listed and
            (questDef.giver == npcId or (questDef.turnInGiver or questDef.giver) == npcId) then
            WO.Quests.Abandon(ply, arg)
            if SessionValid(ply) then SendNode(ply, session.dialogueId, session.nodeId) end
        end

        return
    end

    if verb == "talk" and arg ~= "" then
        -- Шаг квеста "talk" — разговор с указанным NPC
        if WO.Quests and WO.Quests.OnTalk then
            WO.Quests.OnTalk(ply, arg)
        end

        ClearSession(ply)
        WO.Net.Send("Dialogue.Finish", ply)

        return
    end

    if action == "vendor" or verb == "vendor" then
        local session = GetSession(ply)

        if session and WO.Vendors and WO.Vendors.Open then
            local opened = WO.Vendors.Open(ply, session.npcDef, session.ent)

            if opened then
                ClearSession(ply)
                WO.Net.Send("Dialogue.Finish", ply)
            elseif SessionValid(ply) then
                SendNode(ply, session.dialogueId, session.nodeId)
            end
        end

        return
    end

    -- Неизвестное действие — закрываем
    ClearSession(ply)
    WO.Net.Send("Dialogue.Finish", ply)
end

---------------------------------------------------------------------------
-- Обработчики net (вызываются из shared-регистрации в sh_dialogue.lua)
---------------------------------------------------------------------------

--- Выбор варианта ответа (клиент прислал ТОЛЬКО индекс).
function WO.Dialogue.OnChoose(ply, dialogueId, nodeId, optionIndex)
    if not SessionValid(ply) then
        WO.Net.Send("Dialogue.Finish", ply)
        return false, "invalid_session"
    end

    local session = GetSession(ply)

    if session.dialogueId ~= dialogueId or session.nodeId ~= nodeId then
        SendNode(ply, session.dialogueId, session.nodeId)
        return false, "stale_node"
    end

    local option = (session.options or {})[math.floor(optionIndex)]

    if not option then
        SendNode(ply, session.dialogueId, session.nodeId)
        return false, "invalid_option"
    end

    -- Действие выбирает СЕРВЕР из схемы — клиент прислал только индекс
    RunAction(ply, option.action)
    return true
end

--- Закрытие диалога клиентом.
function WO.Dialogue.OnClose(ply)
    ClearSession(ply)
end

--- Отправляет клиенту сигнал закрытия.
function WO.Dialogue.Close(ply)
    ClearSession(ply)
    WO.Net.Send("Dialogue.Finish", ply)
end
