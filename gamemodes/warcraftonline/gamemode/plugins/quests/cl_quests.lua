--[[
    Warcraft Online — квесты (client): журнал (клавиша J), трекер HUD, события.
]]

WO.Quests.LocalStates = WO.Quests.LocalStates or {}

---------------------------------------------------------------------------
-- Трекер HUD (используется hud-плагином)
---------------------------------------------------------------------------

--- Строки для HUD-трекера: активные отслеживаемые квесты с прогрессом.
function WO.Quests.GetTrackerLines()
    local lines = {}

    -- Источник: синхронизированное состояние (Quest.Sync), fallback — кэш персонажа
    local states = WO.Quests.LocalStates or {}

    if next(states) == nil then
        local char = WO.Character.GetLocal()

        states = (char and char.quests) or {}
    end

    for questId, state in pairs(states) do
        if state.status == "active" and state.tracked ~= false then
            local def = WO.Quests.Get(questId)

            if def then
                lines[#lines + 1] = { text = def.name, header = true }

                for index, step in ipairs(def.steps) do
                    local need = step.amount or 1
                    local have = math.min((state.progress or {})[index] or 0, need)

                    lines[#lines + 1] = {
                        text = (step.text or step.type) .. "  " .. have .. "/" .. need,
                        done = have >= need,
                    }
                end
            end
        end
    end

    return lines
end

---------------------------------------------------------------------------
-- Журнал квестов (клавиша J)
---------------------------------------------------------------------------

local questFrame = nil

local function CloseLog()
    if IsValid(questFrame) then
        questFrame:Remove()
        questFrame = nil
    end
end

function WO.Quests.OpenLog()
    CloseLog()

    local sw, sh = ScrW(), ScrH()
    local w, h = math.min(680, sw * 0.55), math.min(520, sh * 0.7)

    questFrame = vgui.Create("DFrame")
    questFrame:SetSize(w, h)
    questFrame:SetPos((sw - w) / 2, (sh - h) / 2)
    questFrame:SetTitle("")
    questFrame:ShowCloseButton(true)
    questFrame:MakePopup()

    questFrame.Paint = function(_, pw, ph)
        WO.UI.DrawPanelOutlined(0, 0, pw, ph, WO.UI.Colors.bg, WO.UI.Colors.accent)
        WO.UI.DrawTitleBar(0, 0, pw, 38, WO.Lang:Get("quest.log_title"))
    end

    local scroll = WO.UI.Scroll(questFrame)

    scroll:Dock(FILL)
    scroll:DockMargin(16, 50, 16, 16)

    local states = WO.Quests.LocalStates or {}
    local shown = 0

    for questId, state in pairs(states) do
        local def = WO.Quests.Get(questId)

        if def then
            shown = shown + 1

            local statusKey = state.status == "completed" and "quest.status_completed" or "quest.status_active"

            local header = WO.UI.Label(scroll,
                (state.status == "completed" and "✔ " or "• ") .. def.name ..
                "  (" .. WO.Lang:Get(statusKey) .. ")",
                "WO.Subtitle",
                state.status == "completed" and WO.UI.Colors.good or WO.UI.Colors.accent)

            header:Dock(TOP)
            header:DockMargin(0, 8, 0, 2)
            header:SetTall(22)

            local desc = WO.UI.Label(scroll, def.description or "", "WO.Small", WO.UI.Colors.textDim)

            desc:Dock(TOP)
            desc:DockMargin(12, 0, 12, 2)
            desc:SetTall(16)

            for index, step in ipairs(def.steps) do
                local need = step.amount or 1
                local have = math.min((state.progress or {})[index] or 0, need)

                local stepLabel = WO.UI.Label(scroll,
                    "   " .. (step.text or step.type) .. "  " .. have .. "/" .. need,
                    "WO.Small",
                    have >= need and WO.UI.Colors.good or WO.UI.Colors.text)

                stepLabel:Dock(TOP)
                stepLabel:DockMargin(12, 0, 12, 0)
                stepLabel:SetTall(16)
            end

            if state.status == "active" then
                local buttonsRow = vgui.Create("DPanel", scroll)

                buttonsRow:Dock(TOP)
                buttonsRow:DockMargin(12, 6, 12, 0)
                buttonsRow:SetTall(28)
                buttonsRow:SetPaintBackground(false)

                local trackBtn = WO.UI.Button(buttonsRow,
                    state.tracked ~= false and WO.Lang:Get("quest.untrack") or WO.Lang:Get("quest.track"),
                    function()
                        WO.Net.SendToServer("Quest.Track", questId, state.tracked == false)
                    end)

                trackBtn:Dock(LEFT)
                trackBtn:SetWide(140)

                local abandonBtn = WO.UI.Button(buttonsRow, WO.Lang:Get("quest.abandon"), function()
                    WO.Net.SendToServer("Quest.Abandon", questId)
                    CloseLog()
                end)

                abandonBtn:Dock(RIGHT)
                abandonBtn:SetWide(120)
            end
        end
    end

    if shown == 0 then
        local empty = WO.UI.Label(scroll, WO.Lang:Get("quest.log_empty"), "WO.Body", WO.UI.Colors.textDim)

        empty:Dock(TOP)
        empty:DockMargin(0, 20, 0, 0)
        empty:SetTall(24)
    end
end

---------------------------------------------------------------------------
-- События
---------------------------------------------------------------------------

WO.Hook.Add("QuestsSynced", "quest_ui", function()
    -- HUD читает трекер сам; журнал обновится при следующем открытии
end)

WO.Hook.Add("QuestEvent", "quest_ui", function(data)
    if not istable(data) then return end

    if data.type == "accepted" then
        WO.Notify.Show("success", WO.Lang:Get("quest.accepted") .. ": " .. tostring(data.name or data.questId))
    elseif data.type == "completed" then
        local rewardText = ""

        if istable(data.rewards) then
            local parts = {}

            if (data.rewards.xp or 0) > 0 then
                parts[#parts + 1] = data.rewards.xp .. " XP"
            end

            if (data.rewards.money or 0) > 0 then
                parts[#parts + 1] = data.rewards.money .. " " .. WO.Lang:Get("currency.coins")
            end

            rewardText = table.concat(parts, ", ")
        end

        WO.Notify.Show("success", WO.Lang:Get("quest.completed") .. ": " ..
            tostring(data.name or data.questId) .. (rewardText ~= "" and (" (" .. rewardText .. ")") or ""))
    elseif data.type == "abandoned" then
        WO.Notify.Show("info", WO.Lang:Get("quest.abandoned"))
    elseif data.type == "info" then
        WO.Notify.Show("info", tostring(data.text or ""))
    end
end)

-- Клавиша J — журнал квестов
if WO.UI and WO.UI.BindKey then
WO.UI.BindKey(KEY_J, function()
    if IsValid(questFrame) then
        CloseLog()
    else
        WO.Quests.OpenLog()
    end
end, "quests_log")
end

WO.Hook.Add("CharacterMenuOpening", "quest_ui_close", function()
    CloseLog()
    WO.Quests.LocalStates = {}
end)
