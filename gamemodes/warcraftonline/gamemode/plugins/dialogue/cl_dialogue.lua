--[[
    Warcraft Online — диалоги (client): окно диалога.
]]

local dialogueFrame = nil

local function CloseDialogue()
    if IsValid(dialogueFrame) then
        dialogueFrame:Remove()
        dialogueFrame = nil
    end
end

WO.Dialogue.CloseUI = CloseDialogue

--- Открывает окно диалога (вызывается net-обработчиком Dialogue.Open).
function WO.Dialogue.OpenUI(data)
    CloseDialogue()

    if not istable(data) then return end

    local sw, sh = ScrW(), ScrH()
    local w, h = math.min(760, sw * 0.5), math.min(420, sh * 0.5)

    dialogueFrame = vgui.Create("DFrame")
    dialogueFrame:SetSize(w, h)
    dialogueFrame:SetPos((sw - w) / 2, sh * 0.42)
    dialogueFrame:SetTitle("")
    dialogueFrame:ShowCloseButton(false)
    dialogueFrame:SetDraggable(true)
    dialogueFrame:MakePopup()

    dialogueFrame.actionPending = false
    dialogueFrame.actionButtons = {}
    dialogueFrame.Paint = function(_, pw, ph)
        WO.UI.DrawPanelOutlined(0, 0, pw, ph, WO.UI.Colors.bg, WO.UI.Colors.accent)
        WO.UI.DrawTitleBar(0, 0, pw, 38, data.npcName ~= "" and data.npcName or WO.Lang:Get("dialogue.title"))
    end

    local closeBtn = WO.UI.Button(dialogueFrame, "✕", function()
        CloseDialogue()
        WO.Net.SendToServer("Dialogue.Close")
    end)

    closeBtn:SetPos(w - 46, 6)
    closeBtn:SetSize(32, 26)

    -- Текст NPC
    local textBox = WO.UI.Label(dialogueFrame, data.text or "", "WO.Body", WO.UI.Colors.text)

    textBox:SetPos(24, 56)
    textBox:SetSize(w - 48, 90)

    -- Варианты ответа
    local scroll = WO.UI.Scroll(dialogueFrame)

    scroll:SetPos(24, 156)
    scroll:SetSize(w - 48, h - 180)

    for index, option in ipairs(data.options or {}) do
        local optionIndex = index
        local button
        button = WO.UI.Button(scroll, (index) .. ". " .. (option.text or "..."), function()
            local activeFrame = dialogueFrame

            if not IsValid(activeFrame) or activeFrame.actionPending then return end

            activeFrame.actionPending = true

            for _, actionButton in ipairs(activeFrame.actionButtons or {}) do
                if IsValid(actionButton) then
                    actionButton:SetBusy(true, WO.Lang:Get("ui.pending"))
                end
            end

            WO.Net.SendToServer("Dialogue.Choose", data.dialogueId, data.nodeId, optionIndex)

            timer.Simple(2.5, function()
                if IsValid(activeFrame) and dialogueFrame == activeFrame and activeFrame.actionPending then
                    activeFrame.actionPending = false

                    for _, actionButton in ipairs(activeFrame.actionButtons or {}) do
                        if IsValid(actionButton) then actionButton:SetBusy(false) end
                    end

                    WO.Notify.Show("error", WO.Lang:Get("dialogue.request_timeout"))
                end
            end)
        end)

        button:Dock(TOP)
        button:DockMargin(0, 0, 0, 6)
        button:SetTall(34)
        dialogueFrame.actionButtons[#dialogueFrame.actionButtons + 1] = button
    end
end

---------------------------------------------------------------------------
-- События
---------------------------------------------------------------------------

WO.Hook.Add("DialogueOpened", "dialogue_ui", function(data)
    WO.Dialogue.OpenUI(data)
end)

WO.Hook.Add("DialogueClosed", "dialogue_ui", function()
    CloseDialogue()
end)

WO.Hook.Add("CharacterMenuOpening", "dialogue_ui_close", function()
    CloseDialogue()
end)

-- ESC/выход из машины/смерть — закрываем
hook.Add("Think", "wo_dialogue_autoclose", function()
    if IsValid(dialogueFrame) then
        local ply = LocalPlayer()

        if not IsValid(ply) or not ply:HasCharacter() or not ply:Alive() then
            CloseDialogue()
        end
    end
end)
