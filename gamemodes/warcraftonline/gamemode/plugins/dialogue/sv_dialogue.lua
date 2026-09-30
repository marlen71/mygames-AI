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

    if not session then return false end

    local ent = session.ent

    if not IsValid(ent) then
        ClearSession(ply)
        return false
    end

    if ply:GetPos():Distance(ent:GetPos()) > 220 then
        ClearSession(ply)
        return false
    end

    return true
end

--- Отправляет узел диалога клиенту.
local function SendNode(ply, dialogueId, nodeId)
    local def = WO.Dialogue.Get(dialogueId)
    local node = def and def.nodes[nodeId]

    if not node then
        WO.Error("WO.Dialogue: unknown node '" .. tostring(dialogueId) .. "/" .. tostring(nodeId) .. "'")
        return
    end

    local session = GetSession(ply)

    WO.Net.Send("Dialogue.Open", ply, {
        dialogueId = dialogueId,
        nodeId = nodeId,
        npcId = session and session.npcDef and session.npcDef.id or "",
        npcName = session and session.npcDef and session.npcDef.name or "",
        text = node.text or "",
        options = node.options or {},
    })
end

---------------------------------------------------------------------------
-- API (вызывается из WO.NPCs.OnInteract)
---------------------------------------------------------------------------

--- Открыть диалог NPC для игрока.
function WO.Dialogue.Open(ply, npcDef)
    if not IsValid(ply) or not ply:HasCharacter() then return end

    local dialogueId = npcDef.dialogue

    if not dialogueId or not WO.Dialogue.Get(dialogueId) then
        WO.Error("WO.Dialogue.Open: NPC '" .. tostring(npcDef.id) .. "' has no dialogue '" .. tostring(dialogueId) .. "'")
        return
    end

    -- Находим ближайший живой wo_npc этого NPC для контроля дистанции
    local ent = nil

    for _, candidate in ipairs(ents.FindByClass("wo_npc")) do
        if IsValid(candidate) and candidate.npcDef == npcDef then
            if ply:GetPos():Distance(candidate:GetPos()) <= (npcDef.interactRange or 140) + 64 then
                ent = candidate
                break
            end
        end
    end

    if not IsValid(ent) then return end

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

        if WO.Quests and WO.Quests.OfferFromDialogue then
            WO.Quests.OfferFromDialogue(ply, arg, session and session.npcDef or nil)
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
            WO.Vendors.Open(ply, session.npcDef)
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
    if not SessionValid(ply) then return end

    local session = GetSession(ply)

    if session.dialogueId ~= dialogueId then return end

    local node = WO.Dialogue.GetNode(dialogueId, nodeId)

    if not node then return end

    local option = (node.options or {})[math.floor(optionIndex)]

    if not option then return end

    -- Действие выбирает СЕРВЕР из схемы — клиент прислал только индекс
    RunAction(ply, option.action)
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
