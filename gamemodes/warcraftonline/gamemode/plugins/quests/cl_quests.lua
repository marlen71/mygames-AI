--[[
    Warcraft Online — квесты (client): журнал (клавиша J), трекер HUD, события.
]]

WO.Quests.LocalStates = WO.Quests.LocalStates or {}

local function GetStateSnapshot()
    local states = WO.Quests.LocalStates or {}

    if next(states) ~= nil then return states end

    local char = WO.Character and WO.Character.GetLocal and WO.Character.GetLocal()
    return (char and char.quests) or states
end

---------------------------------------------------------------------------
-- Трекер HUD (используется hud-плагином)
---------------------------------------------------------------------------

--- Строки для HUD-трекера: активные отслеживаемые квесты с прогрессом.
function WO.Quests.GetTrackerLines()
    local lines = {}

    -- Источник: синхронизированное состояние (Quest.Sync), fallback — кэш персонажа.
    local states = GetStateSnapshot()

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

    local states = GetStateSnapshot()
    local shown = 0

    for questId, state in pairs(states) do
        local def = WO.Quests.Get(questId)

        if def then
            shown = shown + 1

            local statusText = state.status == "completed" and WO.Lang:Get("quest.status_completed") or
                state.status == "failed" and "Провалено" or WO.Lang:Get("quest.status_active")
            local statusColor = state.status == "completed" and WO.UI.Colors.good or
                state.status == "failed" and WO.UI.Colors.bad or WO.UI.Colors.accent
            local statusIcon = state.status == "completed" and "✔ " or
                state.status == "failed" and "✖ " or "• "

            local header = WO.UI.Label(scroll,
                statusIcon .. def.name .. "  (" .. statusText .. ")",
                "WO.Subtitle", statusColor)

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

            if state.status == "active" and def.turnInRequired then
                local complete = true

                for index, step in ipairs(def.steps or {}) do
                    if ((state.progress or {})[index] or 0) < (step.amount or 1) then
                        complete = false
                        break
                    end
                end

                if complete then
                    local npc = WO.NPCs and WO.NPCs.Get and
                        WO.NPCs.Get(def.turnInGiver or def.giver)
                    local turnInLabel = WO.UI.Label(scroll,
                        "Готово — сдайте задание у " .. tostring(npc and npc.name or def.turnInGiver or def.giver),
                        "WO.Small", WO.UI.Colors.good)
                    turnInLabel:Dock(TOP)
                    turnInLabel:DockMargin(12, 2, 12, 2)
                    turnInLabel:SetTall(18)
                end
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
    if IsValid(questFrame) then WO.Quests.OpenLog() end
end)

WO.Hook.Add("QuestEvent", "quest_ui", function(data)
    if not istable(data) then return end

    if data.type == "accepted" then
        WO.Notify.Show("success", WO.Lang:Get("quest.accepted") .. ": " .. tostring(data.name or data.questId))
    elseif data.type == "progress" then
        WO.Notify.Show("info", tostring(data.name or data.questId) .. ": " ..
            tostring(data.text or "Прогресс") .. "  " .. tostring(data.have or 0) .. "/" ..
            tostring(data.need or 1))
    elseif data.type == "ready" then
        WO.Notify.Show("success", "Задание выполнено. Вернитесь к " ..
            tostring(data.turnInName or data.turnInGiver or "заказчику") .. ".")
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
    elseif data.type == "failed" then
        WO.Notify.Show("error", "Задание провалено: " .. tostring(data.name or data.questId))
    elseif data.type == "abandoned" then
        WO.Notify.Show("info", WO.Lang:Get("quest.abandoned"))
    elseif data.type == "info" then
        WO.Notify.Show("info", tostring(data.text or ""))
    end

    if IsValid(questFrame) then WO.Quests.OpenLog() end
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
