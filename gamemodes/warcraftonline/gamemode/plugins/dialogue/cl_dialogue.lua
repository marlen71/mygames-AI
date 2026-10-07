--[[
    Warcraft Online — диалоги (client): компактный WoW-подобный разговор и карточка задания.
]]

local dialogueFrame = nil

local function CloseDialogue()
    if IsValid(dialogueFrame) then
        dialogueFrame:Remove()
    end

    dialogueFrame = nil
end

WO.Dialogue.CloseUI = CloseDialogue

local function GetFrameSize()
    local sw, sh = ScrW(), ScrH()
    local w = math.min(520, math.max(360, math.floor(sw * 0.38)))
    local h = math.min(660, math.max(420, math.floor(sh * 0.82)))

    w = math.min(w, math.max(280, sw - 24))
    h = math.min(h, math.max(320, sh - 24))

    return sw, sh, w, h
end

local function CreateDialogueFrame(data)
    local sw, sh, w, h = GetFrameSize()
    local frame = vgui.Create("DFrame")
    local npcName = tostring(data.npcName or WO.Lang:Get("dialogue.title"))
    local npcTitle = tostring(data.npcTitle or "")
    local header = npcTitle ~= "" and (npcName .. " — " .. npcTitle) or npcName
    local initial = string.upper(string.sub(tostring(data.npcId or "n"), 1, 1))

    frame:SetSize(w, h)
    frame:SetPos(sw - w - 18, math.floor((sh - h) / 2))
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:MakePopup()

    frame.actionPending = false
    frame.actionToken = 0
    frame.actionButtons = {}
    frame.dialogueData = data
    frame.Paint = function(_, pw, ph)
        WO.UI.DrawPanelOutlined(0, 0, pw, ph, WO.UI.Colors.bg, WO.UI.Colors.accent,
            WO.UI.Metrics.radius)
        WO.UI.DrawTitleBar(0, 0, pw, 48, "")
        draw.RoundedBox(18, 16, 7, 34, 34, WO.UI.Colors.accentDark)
        draw.SimpleText(initial, "WO.Title", 33, 24, WO.UI.Colors.text,
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        WO.UI.DrawTextFit(header, "WO.Subtitle", 60, 24, WO.UI.Colors.text,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, pw - 116, 32)
    end

    local closeButton = WO.UI.Button(frame, "✕", function()
        CloseDialogue()
        WO.Net.SendToServer("Dialogue.Close")
    end)
    closeButton:SetPos(w - 44, 10)
    closeButton:SetSize(30, 28)

    return frame, w, h
end

local function SetActionButtonsBusy(frame, busy)
    for _, button in ipairs(frame.actionButtons or {}) do
        if IsValid(button) then
            button:SetBusy(busy, WO.Lang:Get("ui.pending"))
        end
    end
end

local function BeginDialogueRequest(frame, send)
    if not IsValid(frame) or frame.actionPending then return false end

    frame.actionPending = true
    frame.actionToken = (frame.actionToken or 0) + 1
    local token = frame.actionToken
    SetActionButtonsBusy(frame, true)
    send()

    timer.Simple(4, function()
        if IsValid(frame) and dialogueFrame == frame and frame.actionPending and
            frame.actionToken == token then
            frame.actionPending = false
            SetActionButtonsBusy(frame, false)
            WO.Notify.Show("error", WO.Lang:Get("dialogue.request_timeout"))
        end
    end)

    return true
end

local function AddDialogueOptions(frame, data, parent)
    for index, option in ipairs(data.options or {}) do
        local optionIndex = index
        local button = WO.UI.Button(parent, option.text or "...", function()
            BeginDialogueRequest(frame, function()
                WO.Net.SendToServer("Dialogue.Choose", data.dialogueId, data.nodeId, optionIndex)
            end)
        end)

        button:SetAccent(true)
        button:Dock(TOP)
        button:DockMargin(0, 0, 0, 8)
        button:SetTall(42)
        frame.actionButtons[#frame.actionButtons + 1] = button
    end
end

--- Открывает узел разговора, полученный от сервера.
function WO.Dialogue.OpenUI(data)
    CloseDialogue()

    if not istable(data) then return end

    local frame, w, h = CreateDialogueFrame(data)
    dialogueFrame = frame

    local content = WO.UI.Scroll(frame)
    content:SetPos(20, 62)
    content:SetSize(w - 40, h - 82)

    local textBox = WO.UI.Label(content, data.text or "", "WO.Body", WO.UI.Colors.text)
    textBox:Dock(TOP)
    textBox:DockMargin(8, 8, 8, 16)
    textBox:SetTall(156)

    AddDialogueOptions(frame, data, content)
end

local function AddOfferLabel(parent, text, font, color, height)
    local label = WO.UI.Label(parent, text or "", font or "WO.Body", color or WO.UI.Colors.text)
    label:Dock(TOP)
    label:DockMargin(8, 4, 8, 4)
    label:SetTall(height or 30)
    return label
end

local function BuildRewardText(rewards)
    rewards = istable(rewards) and rewards or {}
    local parts = {}

    if (tonumber(rewards.xp) or 0) > 0 then
        parts[#parts + 1] = "Опыт: " .. tostring(rewards.xp)
    end

    if (tonumber(rewards.money) or 0) > 0 then
        local money = WO.Currency and WO.Currency.Format and WO.Currency.Format(rewards.money) or
            (tostring(rewards.money) .. "c")
        parts[#parts + 1] = "Монеты: " .. money
    end

    for _, item in ipairs(rewards.items or {}) do
        parts[#parts + 1] = tostring(item.name or "Предмет") .. " ×" ..
            tostring(math.max(1, tonumber(item.amount) or 1))
    end

    if #parts == 0 then return "Награда не указана" end
    return table.concat(parts, "\n")
end

--- Показывает подробности задания до его принятия; решение всё равно подтверждает сервер.
function WO.Dialogue.OpenQuestOfferUI(data)
    CloseDialogue()

    if not istable(data) or not isstring(data.questId) or data.questId == "" then return end

    local frame, w, h = CreateDialogueFrame(data)
    dialogueFrame = frame
    frame.questOfferData = data

    local content = WO.UI.Scroll(frame)
    content:SetPos(20, 60)
    content:SetSize(w - 40, h - 134)

    AddOfferLabel(content, data.name or "Задание", "WO.Title", WO.UI.Colors.accent, 34)
    AddOfferLabel(content, data.description or "", "WO.Body", WO.UI.Colors.text, 108)
    AddOfferLabel(content, "ЦЕЛИ", "WO.Subtitle", WO.UI.Colors.accent, 26)

    local objectives = istable(data.objectives) and data.objectives or {}

    if #objectives == 0 then
        AddOfferLabel(content, "Цели не указаны", "WO.Small", WO.UI.Colors.textDim, 24)
    else
        for _, objective in ipairs(objectives) do
            local objectiveText = tostring(objective.text or "Цель задания") .. "  ×" ..
                tostring(math.max(1, tonumber(objective.amount) or 1))
            AddOfferLabel(content, "• " .. objectiveText, "WO.Small", WO.UI.Colors.text, 28)
        end
    end

    AddOfferLabel(content, "НАГРАДА", "WO.Subtitle", WO.UI.Colors.accent, 26)
    AddOfferLabel(content, BuildRewardText(data.rewards), "WO.Small", WO.UI.Colors.good, 78)

    local acceptItems = istable(data.acceptItems) and data.acceptItems or {}

    if #acceptItems > 0 then
        local granted = {}

        for _, item in ipairs(acceptItems) do
            granted[#granted + 1] = tostring(item.name or "Предмет") .. " ×" ..
                tostring(math.max(1, tonumber(item.amount) or 1))
        end

        AddOfferLabel(content, "СРАЗУ ПРИ ПРИНЯТИИ", "WO.Subtitle", WO.UI.Colors.accent, 26)
        AddOfferLabel(content, table.concat(granted, "\n"), "WO.Small", WO.UI.Colors.good,
            math.max(28, #granted * 24))
    end

    local acceptButton = WO.UI.Button(frame, "Принять", function()
        BeginDialogueRequest(frame, function()
            WO.Net.SendToServer("Dialogue.QuestResponse", data.questId, true)
        end)
    end)
    acceptButton:SetAccent(true)
    acceptButton:SetPos(20, h - 58)
    acceptButton:SetSize(math.floor((w - 48) / 2), 38)

    local declineButton = WO.UI.Button(frame, "Не сейчас", function()
        BeginDialogueRequest(frame, function()
            WO.Net.SendToServer("Dialogue.QuestResponse", data.questId, false)
        end)
    end)
    declineButton:SetPos(28 + math.floor((w - 48) / 2), h - 58)
    declineButton:SetSize(math.floor((w - 48) / 2), 38)

    frame.actionButtons = { acceptButton, declineButton }
end

---------------------------------------------------------------------------
-- События
---------------------------------------------------------------------------

WO.Hook.Add("DialogueOpened", "dialogue_ui", function(data)
    WO.Dialogue.OpenUI(data)
end)

WO.Hook.Add("DialogueQuestOffered", "dialogue_ui_quest_offer", function(data)
    WO.Dialogue.OpenQuestOfferUI(data)
end)

WO.Hook.Add("DialogueClosed", "dialogue_ui", function()
    CloseDialogue()
end)

WO.Hook.Add("CharacterMenuOpening", "dialogue_ui_close", function()
    CloseDialogue()
end)

-- ESC/выход из машины/смерть — закрываем.
hook.Add("Think", "wo_dialogue_autoclose", function()
    if IsValid(dialogueFrame) then
        local ply = LocalPlayer()

        if not IsValid(ply) or not ply:HasCharacter() or not ply:Alive() then
            CloseDialogue()
        end
    end
end)
