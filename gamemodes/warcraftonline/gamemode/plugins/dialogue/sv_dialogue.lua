--[[
    Warcraft Online — диалоги (server): сессии, валидация, действия.
    Клиент НИКОГДА не выбирает текст или quest id — только индекс серверного варианта.
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

local function IsListedByNPC(npcDef, questId)
    for _, offeredId in ipairs(npcDef and npcDef.quests or {}) do
        if offeredId == questId then return true end
    end

    return false
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

local function QuestOfferAvailable(char, npcDef, questId, questDef, state)
    if not char or not istable(npcDef) or not questDef or questDef.giver ~= npcDef.id or
        not IsListedByNPC(npcDef, questId) or
        not QuestPrerequisitesMet(char, questDef) or
        (char:GetLevel() or 1) < (questDef.level or 1) then
        return false
    end

    if not state or state.status == "failed" then return true end

    if state.status == "completed" and
        (tonumber(questDef.repeatInterval) or 0) > 0 and
        WO.Quests.GetRepeatAvailability then
        local repeatReady = WO.Quests.GetRepeatAvailability(char, questId)
        return repeatReady == true
    end

    return false
end

local function BuildQuestActionOption(char, npcDef, questId, fallbackText)
    local questDef = WO.Quests and WO.Quests.Get and WO.Quests.Get(questId)
    local state = char and char.quests and char.quests[questId]

    if not questDef or not istable(npcDef) or not IsListedByNPC(npcDef, questId) then return nil end

    local isGiver = questDef.giver == npcDef.id
    local isTurnIn = (questDef.turnInGiver or questDef.giver) == npcDef.id

    if state and state.status == "active" and (isGiver or isTurnIn) then
        local ready = WO.Quests.AreStepsDone(char, questId)
        local label

        if isTurnIn and questDef.turnInRequired and ready then
            label = "Сдать задание: " .. questDef.name
        else
            label = "Моё задание: " .. QuestProgressLabel(char, questDef, state)
        end

        return { text = label, action = "quest:" .. questId }
    end

    if QuestOfferAvailable(char, npcDef, questId, questDef, state) then
        local repeatOffer = state and
            (state.status == "completed" or state.status == "failed")
        local verb = repeatOffer and "Повторить: " or "Взять задание: "
        return { text = verb .. (questDef.name or fallbackText or questId), action = "offer:" .. questId }
    end

    return nil
end

local function BuildNodeOptions(ply, npcDef, node)
    local char = ply:GetCharacter()
    local options = {}

    for _, option in ipairs(node.options or {}) do
        local questId = string.match(option.action or "", "^quest:([%w_]+)$") or
            string.match(option.action or "", "^offer:([%w_]+)$")

        if not questId then
            options[#options + 1] = option
        else
            local resolved = BuildQuestActionOption(char, npcDef, questId, option.text)

            if resolved then
                options[#options + 1] = resolved
            end
        end
    end

    return options
end

--- Work-узел показывает максимум одно актуальное поручение: цепочку не нужно искать в списке.
local function BuildWorkOptions(ply, npcDef, node)
    local char = ply:GetCharacter()

    for _, questId in ipairs(npcDef.quests or {}) do
        local option = BuildQuestActionOption(char, npcDef, questId)

        if option then
            local questDef = WO.Quests.Get(questId)
            local state = char.quests and char.quests[questId]
            local ready = state and state.status == "active" and
                WO.Quests.AreStepsDone(char, questId)
            local message

            if ready and questDef and questDef.turnInRequired then
                message = "Хорошая работа. Можешь сдать поручение."
            elseif state and state.status == "active" then
                message = "Сначала выполни текущее поручение."
            else
                message = node.availableText or "Вот одно поручение, с которого можно начать."
            end

            return {
                option,
                { text = node.backText or "Назад", action = "next:" .. (node.backNode or "start") },
            }, message
        end
    end

    return {
        { text = node.emptyCloseText or "До встречи!", action = "close" },
        { text = node.backText or "Назад", action = "next:" .. (node.backNode or "start") },
    }, node.emptyText or "Пока подходящих поручений нет. Загляни позже."
end

local function BuildProfessionOptions(ply, npcDef)
    local char = ply:GetCharacter()
    local professionId = npcDef and npcDef.professionId
    local profession = professionId and WO.Professions and WO.Professions.Get(professionId)

    if not profession then
        return { { text = "До встречи", action = "close" } },
            "У этого работодателя пока нет настроенной профессии."
    end

    local activeShift = char and char.activeProfessionShift

    if istable(activeShift) then
        if activeShift.npcId == npcDef.id and activeShift.professionId == "lumberjack" then
            local delivered = math.max(0, math.floor(tonumber(activeShift.completedOrders) or 0))
            local settleText = delivered > 0 and
                ("Сдать смену · " .. delivered .. " связок доставлено") or
                "Завершить смену без доставок"

            return {
                { text = settleText, action = "profession_finish" },
                { text = "Продолжить переноску", action = "close" },
            }, "Расчёт добровольный: оплачиваются только уже доставленные связки. Незаконченная переноска не засчитывается."
        end

        if activeShift.npcId == npcDef.id and activeShift.status == "ready" then
            return {
                { text = "Сдать смену и получить зарплату", action = "profession_finish" },
                { text = "Остаться в мире", action = "close" },
            }, "Все заказы выполнены. Сдайте смену работодателю, чтобы получить оплату и опыт."
        end

        if activeShift.npcId == npcDef.id then
            return { { text = "Продолжить смену", action = "close" } },
                "Вы уже работаете. Продолжайте задания прямо в мире; расчёт будет доступен после всех заказов."
        end

        local employer = WO.NPCs and WO.NPCs.Get and WO.NPCs.Get(activeShift.npcId)
        return { { text = "До встречи", action = "close" } },
            "Сначала завершите смену у работодателя «" ..
                tostring(employer and employer.name or activeShift.npcId or "работы") .. "»."
    end

    local skill = WO.Professions.GetSkillData(char, professionId)
    local options = {}

    local maxRank = WO.Professions.GetMaxRank and WO.Professions.GetMaxRank(professionId) or 3

    for rankIndex, rank in ipairs(profession.ranks or {}) do
        if rankIndex <= maxRank then
            local amount = professionId == "lumberjack" and rank.basePay or
                WO.Professions.GetBasePay(professionId, rankIndex, 3)
            local formatted = WO.Currency and WO.Currency.Format and WO.Currency.Format(amount) or
                (tostring(amount) .. "c")

            if rankIndex <= skill.level then
                local rateText = professionId == "lumberjack" and
                    (formatted .. " за доставленную связку") or (formatted .. " за смену")
                options[#options + 1] = {
                    text = "Работать: " .. rank.name .. " · " .. rateText,
                    action = "profession_rank:" .. rankIndex,
                }
            else
                local missingXP = math.max(0, (rank.requiredXP or 0) - skill.xp)
                options[#options + 1] = {
                    text = "Закрыто: " .. rank.name .. " · ещё " .. missingXP .. " опыта",
                    action = "profession_locked:" .. rankIndex,
                }
            end
        end
    end

    options[#options + 1] = { text = "Пока не работать", action = "close" }
    local nextRank = skill.level < maxRank and profession.ranks[skill.level + 1] or nil
    local nextText = nextRank and
        (" До следующей ступени «" .. nextRank.name .. "» нужно ещё " ..
            math.max(0, nextRank.requiredXP - skill.xp) .. " опыта.") or " Максимальная доступная ступень открыта."

    return options, "Опыт ремесла: " .. skill.xp .. ". Открыты ступени 1–" ..
        skill.level .. "/" .. maxRank .. ". Выберите, за кого работать." .. nextText
end

--- Отправляет узел диалога с вариантами, вычисленными на сервере.
local function SendNode(ply, dialogueId, nodeId)
    local def = WO.Dialogue.Get(dialogueId)
    local node = def and def.nodes[nodeId]

    if not node then
        WO.Error("WO.Dialogue: unknown node '" .. tostring(dialogueId) .. "/" .. tostring(nodeId) .. "'")
        return
    end

    local session = GetSession(ply)

    if not session then return end

    local text = node.text or ""
    local options

    if node.profession == true then
        options, text = BuildProfessionOptions(ply, session.npcDef)
    elseif node.work == true then
        options, text = BuildWorkOptions(ply, session.npcDef, node)
    else
        options = BuildNodeOptions(ply, session.npcDef, node)
    end

    session.nodeId = nodeId
    session.options = options
    session.pendingQuestOffer = nil
    session.pendingQuestNodeId = nil

    WO.Net.Send("Dialogue.Open", ply, {
        dialogueId = dialogueId,
        nodeId = nodeId,
        npcId = session.npcDef and session.npcDef.id or "",
        npcName = session.npcDef and session.npcDef.name or "",
        npcTitle = session.npcDef and session.npcDef.title or "",
        text = text,
        options = session.options,
    })
end

---------------------------------------------------------------------------
-- Предложение задания с отдельным подтверждением игрока
---------------------------------------------------------------------------

local function BuildQuestOffer(questDef)
    local objectives = {}

    for _, step in ipairs(questDef.steps or {}) do
        objectives[#objectives + 1] = {
            text = step.text or step.target or step.class or "Цель задания",
            amount = math.max(1, tonumber(step.amount) or 1),
        }
    end

    local rewardItems = {}

    for _, entry in ipairs(questDef.rewards and questDef.rewards.items or {}) do
        local itemDef = WO.Items and WO.Items.Get and WO.Items.Get(entry.class)
        rewardItems[#rewardItems + 1] = {
            name = itemDef and itemDef.name or entry.class,
            amount = math.max(1, tonumber(entry.amount) or 1),
        }
    end

    local acceptItems = {}

    for _, entry in ipairs(questDef.acceptItems or {}) do
        local itemDef = WO.Items and WO.Items.Get and WO.Items.Get(entry.class)
        acceptItems[#acceptItems + 1] = {
            name = itemDef and itemDef.name or entry.class,
            amount = math.max(1, tonumber(entry.amount) or 1),
        }
    end

    return {
        questId = questDef.id,
        name = questDef.name or questDef.id,
        description = questDef.description or "",
        objectives = objectives,
        rewards = {
            xp = math.max(0, tonumber(questDef.rewards and questDef.rewards.xp) or 0),
            money = math.max(0, tonumber(questDef.rewards and questDef.rewards.money) or 0),
            items = rewardItems,
        },
        acceptItems = acceptItems,
    }
end

local function SendQuestOffer(ply, questId)
    if not SessionValid(ply) then
        WO.Net.Send("Dialogue.Finish", ply)
        return false
    end

    local session = GetSession(ply)
    local questDef = WO.Quests and WO.Quests.Get and WO.Quests.Get(questId)
    local char = ply:GetCharacter()
    local state = char and char.quests and char.quests[questId]

    if not questDef or not QuestOfferAvailable(char, session.npcDef, questId, questDef, state) then
        SendNode(ply, session.dialogueId, session.nodeId)
        return false
    end

    session.pendingQuestOffer = questId
    session.pendingQuestNodeId = session.nodeId

    local offer = BuildQuestOffer(questDef)
    offer.dialogueId = session.dialogueId
    offer.nodeId = session.nodeId
    offer.npcId = session.npcDef and session.npcDef.id or ""
    offer.npcName = session.npcDef and session.npcDef.name or ""
    offer.npcTitle = session.npcDef and session.npcDef.title or ""

    WO.Net.Send("Dialogue.QuestOffer", ply, offer)
    return true
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

    -- Simply speaking with this NPC counts for an already-active talk objective.
    -- This also lets existing characters finish legacy talk quests after dialogue cleanup.
    if WO.Quests and WO.Quests.OnTalk then
        WO.Quests.OnTalk(ply, npcDef.id)
    end

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

    if action == "work" or verb == "work" then
        local session = GetSession(ply)

        if session then
            SendNode(ply, session.dialogueId, "work")
        end

        return
    end

    if verb == "profession_rank" and arg ~= "" then
        local session = GetSession(ply)
        local professionId = session and session.npcDef and session.npcDef.professionId
        local started, reason = false, "invalid_profession"

        if WO.Professions and WO.Professions.StartShift then
            started, reason = WO.Professions.StartShift(ply, professionId, tonumber(arg))
        end

        if started then
            WO.Dialogue.Close(ply)
        else
            local message = reason == "rank_locked" and "Эта ступень ещё закрыта: сначала заработайте нужный опыт." or
                reason == "shift_already_active" and "У вас уже есть активная смена." or
                "Не удалось начать смену. Подойдите к своему работодателю и попробуйте ещё раз."
            WO.Notify(ply, "error", message)
            if SessionValid(ply) then SendNode(ply, session.dialogueId, session.nodeId) end
        end

        return
    end

    if verb == "profession_locked" and arg ~= "" then
        WO.Notify(ply, "info", "Эта работа откроется после получения указанного опыта ремесла.")
        local session = GetSession(ply)
        if session and SessionValid(ply) then SendNode(ply, session.dialogueId, session.nodeId) end
        return
    end

    if action == "profession_finish" then
        local session = GetSession(ply)
        local char = ply:GetCharacter()
        local shift = char and char.activeProfessionShift
        local finished, reason = false, "orders_incomplete"

        if shift and WO.Professions and WO.Professions.FinishShift then
            finished, reason = WO.Professions.FinishShift(ply, shift.id)
        end

        if finished then
            WO.Dialogue.Close(ply)
        else
            WO.Notify(ply, "error", reason == "wrong_employer" and
                "Сдать смену можно только у работодателя, который её выдал." or
                "Смена ещё не готова к сдаче.")
            if session and SessionValid(ply) then SendNode(ply, session.dialogueId, session.nodeId) end
        end

        return
    end

    if verb == "offer" and arg ~= "" then
        SendQuestOffer(ply, arg)
        return
    end

    if verb == "quest" and arg ~= "" then
        local session = GetSession(ply)
        local char = ply:GetCharacter()
        local state = char and char.quests and char.quests[arg]

        if session and state and state.status == "active" and
            WO.Quests and WO.Quests.OfferFromDialogue then
            WO.Quests.OfferFromDialogue(ply, arg, session.npcDef, session.ent)
            if SessionValid(ply) then SendNode(ply, session.dialogueId, session.nodeId) end
        elseif session then
            SendNode(ply, session.dialogueId, session.nodeId)
        end

        return
    end

    if verb == "abandon" and arg ~= "" then
        local session = GetSession(ply)
        local questDef = WO.Quests and WO.Quests.Get and WO.Quests.Get(arg)
        local npcId = session and session.npcDef and session.npcDef.id

        if session and questDef and IsListedByNPC(session.npcDef, arg) and
            (questDef.giver == npcId or (questDef.turnInGiver or questDef.giver) == npcId) then
            WO.Quests.Abandon(ply, arg)
            if SessionValid(ply) then SendNode(ply, session.dialogueId, session.nodeId) end
        end

        return
    end

    if verb == "talk" and arg ~= "" then
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

    if session.pendingQuestOffer then
        SendQuestOffer(ply, session.pendingQuestOffer)
        return false, "offer_pending"
    end

    if session.dialogueId ~= dialogueId or session.nodeId ~= nodeId then
        SendNode(ply, session.dialogueId, session.nodeId)
        return false, "stale_node"
    end

    local option = (session.options or {})[math.floor(optionIndex)]

    if not option then
        SendNode(ply, session.dialogueId, session.nodeId)
        return false, "invalid_option"
    end

    -- Действие выбирает СЕРВЕР из схемы — клиент прислал только индекс.
    RunAction(ply, option.action)
    return true
end

--- Подтверждает или отклоняет только ту заявку, которую сервер показал в активной сессии.
function WO.Dialogue.OnQuestResponse(ply, questId, accepted)
    if not SessionValid(ply) then
        WO.Net.Send("Dialogue.Finish", ply)
        return false, "invalid_session"
    end

    local session = GetSession(ply)

    if not session.pendingQuestOffer or session.pendingQuestOffer ~= questId then
        if session.pendingQuestOffer then SendQuestOffer(ply, session.pendingQuestOffer) end
        return false, "stale_offer"
    end

    local offeredQuestId = session.pendingQuestOffer
    session.pendingQuestOffer = nil
    session.pendingQuestNodeId = nil

    if accepted and WO.Quests and WO.Quests.OfferFromDialogue then
        WO.Quests.OfferFromDialogue(ply, offeredQuestId, session.npcDef, session.ent)
    end

    if SessionValid(ply) then
        SendNode(ply, session.dialogueId, session.nodeId)
    end

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
