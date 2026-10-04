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
-- Автоматическая метка маршрута для активного задания
---------------------------------------------------------------------------

local dismissedWaypoints = {}

local function GetNPCSpawnPositions(npcId, map)
    local npcDef = WO.NPCs and WO.NPCs.Get and WO.NPCs.Get(npcId)
    local positions = {}

    for _, spawn in ipairs(npcDef and npcDef.spawns or {}) do
        if (not spawn.map or spawn.map == map) and isvector(spawn.pos) then
            positions[#positions + 1] = spawn.pos
        end
    end

    return positions
end

local function ResolveNPCWaypoint(npcId, map, spawnIndex)
    local positions = GetNPCSpawnPositions(npcId, map)
    if #positions == 0 then return nil end

    if spawnIndex then
        local index = math.Clamp(math.floor(tonumber(spawnIndex) or 1), 1, #positions)
        return positions[index]
    end

    return positions[1]
end

local function ResolveStepWaypoint(step, state, stepIndex, map)
    local explicit = step.waypoint

    if istable(explicit) then
        if (not explicit.map or explicit.map == map) and isvector(explicit.pos) then
            return explicit.pos, explicit.radius
        end

        return nil
    end

    if isstring(step.waypointNPC) then
        return ResolveNPCWaypoint(step.waypointNPC, map), step.waypointRadius
    end

    if step.type == "talk" and isstring(step.target) then
        return ResolveNPCWaypoint(step.target, map), step.waypointRadius
    end

    if step.type == "kill" and isstring(step.target) then
        local progress = tonumber((state.progress or {})[stepIndex]) or 0
        return ResolveNPCWaypoint(step.target, map, progress + 1), step.waypointRadius
    end

    return nil
end

local function BuildWaypoint(questId, def, state, step, stepIndex, position, radius, turnIn)
    local progress = tonumber((state.progress or {})[stepIndex]) or 0
    local acceptedAt = tostring(state.acceptedAt or "")
    local char = WO.Character and WO.Character.GetLocal and WO.Character.GetLocal()
    local characterId = tostring(char and char.id or "")
    local key = characterId .. ":" .. tostring(questId) .. ":" .. acceptedAt
    key = key .. (turnIn and ":turnin" or
        (":" .. tostring(stepIndex) .. ":" .. tostring(progress)))
    local text = step and (step.text or step.target or step.class) or nil
    local npcId = turnIn and (def.turnInGiver or def.giver) or nil
    local npcDef = npcId and WO.NPCs and WO.NPCs.Get and WO.NPCs.Get(npcId)

    if turnIn then
        text = WO.Lang:Get("quest.return_to", npcDef and npcDef.name or npcId or "")
    end

    return {
        key = key,
        questId = questId,
        questName = def.name or questId,
        text = text or def.description or def.name or questId,
        position = position,
        radius = math.max(1, tonumber(radius) or 180),
        turnIn = turnIn == true,
    }
end

--- Returns the next tracked objective/turn-in destination on the current map.
--- Reaching its radius dismisses that marker until the objective progress changes.
function WO.Quests.GetTrackedWaypoint()
    local ply = LocalPlayer()
    if not IsValid(ply) or not isfunction(ply.GetPos) then return nil end

    local playerPosition = ply:GetPos()
    local map = game.GetMap()
    local states = GetStateSnapshot()
    local questIds = {}

    for questId in pairs(states or {}) do
        questIds[#questIds + 1] = questId
    end

    table.sort(questIds, function(a, b) return tostring(a) < tostring(b) end)

    for _, questId in ipairs(questIds) do
        local state = states[questId]
        local def = WO.Quests.Get(questId)

        if def and state and state.status == "active" and state.tracked ~= false then
            local allStepsDone = true
            local candidate
            local candidateCanBeDismissed = true

            for stepIndex, step in ipairs(def.steps or {}) do
                local need = math.max(1, tonumber(step.amount) or 1)
                local progress = math.max(0, tonumber((state.progress or {})[stepIndex]) or 0)

                if progress < need then
                    allStepsDone = false
                    local position, radius = ResolveStepWaypoint(step, state, stepIndex, map)

                    if isvector(position) then
                        candidate = BuildWaypoint(questId, def, state, step,
                            stepIndex, position, radius, false)
                        break
                    end
                    -- Non-spatial prerequisites (for example, equipping the
                    -- starter knife) must not hide the next objective in the world.
                    candidateCanBeDismissed = false
                end
            end

            if not candidate and allStepsDone and def.turnInRequired == true then
                local npcId = def.turnInGiver or def.giver
                local position = ResolveNPCWaypoint(npcId, map)

                if isvector(position) then
                    candidate = BuildWaypoint(questId, def, state, nil,
                        0, position, def.turnInWaypointRadius, true)
                end
            end

            if candidate then
                local key = candidate.key
                local distanceSquared = playerPosition:DistToSqr(candidate.position)
                local radiusSquared = candidate.radius * candidate.radius

                if distanceSquared <= radiusSquared and candidateCanBeDismissed then
                    dismissedWaypoints[key] = true
                end

                if not dismissedWaypoints[key] then
                    return candidate
                end
            end
        end
    end

    return nil
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
-- Журнал заданий (встроенная страница игрового меню)
---------------------------------------------------------------------------

local questRequests = {}
local questRequestSerial = 0

local function QuestRequestKey(action, questId)
    return tostring(action) .. "\0" .. tostring(questId)
end

local function IsJournalPageOpen()
    return WO.MenuUI and WO.MenuUI.IsOpen and WO.MenuUI.IsOpen() and
        WO.MenuUI.GetPage and WO.MenuUI.GetPage() == "quests"
end

local function RefreshJournal()
    if IsJournalPageOpen() and WO.MenuUI.RefreshPage then
        return WO.MenuUI.RefreshPage("quests")
    end

    return false
end

local function RequestQuestAction(action, questId, button, send)
    local key = QuestRequestKey(action, questId)
    if questRequests[key] then return false end

    questRequestSerial = questRequestSerial + 1
    local token = questRequestSerial
    questRequests[key] = token

    if IsValid(button) and isfunction(button.SetBusy) then
        button:SetBusy(true, WO.Lang:Get("ui.pending"))
    elseif IsValid(button) then
        button:SetEnabled(false)
    end

    send()

    timer.Simple(3, function()
        if questRequests[key] ~= token then return end

        questRequests[key] = nil
        WO.Notify.Show("error", WO.Lang:Get("quest.request_timeout"))
        RefreshJournal()
    end)

    return true
end

local function GetQuestStatus(state)
    if state.status == "completed" then
        return WO.Lang:Get("quest.status_completed"), WO.UI.Colors.good
    elseif state.status == "failed" then
        return WO.Lang:Get("quest.status_failed"), WO.UI.Colors.bad
    end

    return WO.Lang:Get("quest.status_active"), WO.UI.Colors.accent
end

local function GetQuestProgress(def, state)
    local completed = true
    local lines = {}

    for index, step in ipairs(def.steps or {}) do
        local needed = math.max(1, tonumber(step.amount) or 1)
        local amount = math.min(needed,
            math.max(0, tonumber((state.progress or {})[index]) or 0))
        local done = amount >= needed
        completed = completed and done
        lines[#lines + 1] = {
            text = step.text or step.target or step.type or "Цель",
            amount = amount,
            needed = needed,
            done = done,
        }
    end

    return lines, completed
end

local function BuildQuestCard(parent, questId, state, def, index)
    local objectives, allObjectivesDone = GetQuestProgress(def, state)
    local isActive = state.status == "active"
    local showTurnIn = isActive and allObjectivesDone and def.turnInRequired == true
    local objectiveHeight = 38
    local cardHeight = 56 + 44 + #objectives * objectiveHeight +
        (showTurnIn and 28 or 0) + (isActive and 48 or 0)
    local card = vgui.Create("DPanel", parent)
    card:Dock(TOP)
    card:SetTall(cardHeight)
    card:DockMargin(0, 0, 0, 10)
    card.woQuestId = questId
    card.Paint = function(_, w, h)
        WO.UI.DrawPanelOutlined(0, 0, w, h, WO.UI.Colors.panel,
            WO.UI.Colors.border, WO.UI.Metrics.radius)

        local statusText, statusColor = GetQuestStatus(state)
        WO.UI.DrawTextFit(def.name or questId, "WO.Subtitle", 14, 22,
            WO.UI.Colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER,
            math.max(80, w - 180), 28)
        WO.UI.DrawPanelOutlined(w - 154, 9, 140, 26,
            WO.UI.Colors.panelDark, statusColor, WO.UI.Metrics.radiusSmall)
        WO.UI.DrawTextFit(statusText, "WO.Tiny", w - 84, 22,
            statusColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 126, 20)
    end

    local description = WO.UI.Label(card, def.description or "", "WO.Small",
        WO.UI.Colors.textDim)
    description:SetPos(14, 46)
    description:SetSize(math.max(1, parent:GetWide() - 36), 40)
    description:SetTall(40)

    local objectivesTop = 88

    for objectiveIndex, objective in ipairs(objectives) do
        local row = vgui.Create("DPanel", card)
        row:SetPos(12, objectivesTop + (objectiveIndex - 1) * objectiveHeight)
        row:SetSize(math.max(1, parent:GetWide() - 24), objectiveHeight - 4)
        row.Paint = function(_, w, h)
            local color = objective.done and WO.UI.Colors.good or WO.UI.Colors.textDim
            WO.UI.DrawPanelOutlined(0, 0, w, h, WO.UI.Colors.panelDark,
                WO.UI.Colors.border, WO.UI.Metrics.radiusSmall)
            WO.UI.DrawTextFit((objective.done and "✓ " or "• ") .. objective.text,
                "WO.Tiny", 10, h / 2, color, TEXT_ALIGN_LEFT,
                TEXT_ALIGN_CENTER, math.max(40, w - 86), h - 4)
            WO.UI.DrawTextFit(tostring(objective.amount) .. "/" .. tostring(objective.needed),
                "WO.Small", w - 10, h / 2, color, TEXT_ALIGN_RIGHT,
                TEXT_ALIGN_CENTER, 64, h - 4)
            WO.UI.DrawBar(10, h - 4, math.max(1, w - 20), 2,
                objective.amount / objective.needed, color,
                WO.UI.Colors.panel, nil)
        end
    end

    local actionsTop = objectivesTop + #objectives * objectiveHeight

    if showTurnIn then
        local npc = WO.NPCs and WO.NPCs.Get and
            WO.NPCs.Get(def.turnInGiver or def.giver)
        local turnIn = WO.UI.Label(card,
            WO.Lang:Get("quest.return_to", tostring(npc and npc.name or
                def.turnInGiver or def.giver or "")), "WO.Small", WO.UI.Colors.good)
        turnIn:SetPos(14, actionsTop)
        turnIn:SetSize(math.max(1, parent:GetWide() - 28), 24)
        turnIn:SetTall(24)
        actionsTop = actionsTop + 28
    end

    if isActive then
        local buttonsRow = vgui.Create("DPanel", card)
        buttonsRow:SetPos(12, actionsTop)
        buttonsRow:SetSize(math.max(1, parent:GetWide() - 24), 38)
        buttonsRow:SetPaintBackground(false)
        local trackBtn
        local abandonBtn
        local function LayoutButtons(w)
            if not IsValid(trackBtn) or not IsValid(abandonBtn) then return end
            local buttonGap = 8
            local buttonWidth = math.max(96, math.floor((w - buttonGap) / 2))
            trackBtn:SetPos(0, 0)
            trackBtn:SetSize(buttonWidth, 34)
            abandonBtn:SetPos(buttonWidth + buttonGap, 0)
            abandonBtn:SetSize(math.max(96, w - buttonWidth - buttonGap), 34)
        end
        buttonsRow.PerformLayout = function(self, w)
            LayoutButtons(w)
        end

        trackBtn = WO.UI.Button(buttonsRow,
            state.tracked ~= false and WO.Lang:Get("quest.untrack") or
                WO.Lang:Get("quest.track"), function()
            RequestQuestAction("track", questId, trackBtn, function()
                WO.Net.SendToServer("Quest.Track", questId, state.tracked == false)
            end)
        end)
        trackBtn:SetSize(140, 34)
        trackBtn:SetAccent(state.tracked ~= false)

        abandonBtn = WO.UI.Button(buttonsRow, WO.Lang:Get("quest.abandon"), function()
            RequestQuestAction("abandon", questId, abandonBtn, function()
                WO.Net.SendToServer("Quest.Abandon", questId)
            end)
        end)
        abandonBtn:SetSize(120, 34)
        LayoutButtons(buttonsRow:GetWide())

        if questRequests[QuestRequestKey("track", questId)] then
            trackBtn:SetBusy(true, WO.Lang:Get("ui.pending"))
        end
        if questRequests[QuestRequestKey("abandon", questId)] then
            abandonBtn:SetBusy(true, WO.Lang:Get("ui.pending"))
        end
    end

    return card
end

function WO.Quests.BuildJournal(parent)
    if not IsValid(parent) then return nil end

    local header = vgui.Create("DPanel", parent)
    header.woQuestJournalHeader = true
    header:Dock(TOP)
    header:SetTall(58)
    header:DockMargin(0, 0, 0, 10)
    header:SetPaintBackground(false)
    header.Paint = function(_, w, h)
        WO.UI.DrawTextFit(WO.Lang:Get("quest.log_title"), "WO.Title",
            0, 20, WO.UI.Colors.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, w - 8, 30)
        WO.UI.DrawTextFit(WO.Lang:Get("quest.journal_hint"), "WO.Small",
            2, 44, WO.UI.Colors.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, w - 12, 18)
    end

    local scroll = WO.UI.Scroll(parent)
    scroll:Dock(FILL)
    scroll:SetSize(parent:GetWide(), math.max(1, parent:GetTall() - 68))

    local states = GetStateSnapshot()
    local questIds = {}

    for questId, state in pairs(states or {}) do
        if WO.Quests.Get(questId) and istable(state) then
            questIds[#questIds + 1] = questId
        end
    end

    table.sort(questIds, function(a, b)
        local stateA, stateB = states[a], states[b]
        local rank = { active = 1, completed = 2, failed = 3 }
        local statusA = rank[stateA.status] or 4
        local statusB = rank[stateB.status] or 4
        if statusA ~= statusB then return statusA < statusB end
        return string.lower(tostring(WO.Quests.Get(a).name or a)) <
            string.lower(tostring(WO.Quests.Get(b).name or b))
    end)

    for index, questId in ipairs(questIds) do
        BuildQuestCard(scroll, questId, states[questId], WO.Quests.Get(questId), index)
    end

    if #questIds == 0 then
        local empty = vgui.Create("DPanel", scroll)
        empty:Dock(TOP)
        empty:SetTall(92)
        empty:DockMargin(0, 4, 0, 8)
        empty.Paint = function(_, w, h)
            WO.UI.DrawPanelOutlined(0, 0, w, h, WO.UI.Colors.panel,
                WO.UI.Colors.border, WO.UI.Metrics.radius)
            WO.UI.DrawTextFit(WO.Lang:Get("quest.log_empty"), "WO.Body",
                18, h / 2, WO.UI.Colors.textDim,
                TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, w - 36, 30)
        end
    end

    return scroll
end

function WO.Quests.OpenLog()
    if not (WO.MenuUI and WO.MenuUI.Show and WO.MenuUI.ActivatePage) then
        return false
    end

    if WO.MenuUI.IsOpen and WO.MenuUI.IsOpen() then
        return WO.MenuUI.ActivatePage("quests")
    end

    return WO.MenuUI.Show("quests")
end

function WO.Quests.ToggleLog()
    if not (WO.MenuUI and WO.MenuUI.Show and WO.MenuUI.ActivatePage) then
        return false
    end

    if WO.MenuUI.IsOpen and WO.MenuUI.IsOpen() then
        local page = WO.MenuUI.GetPage and WO.MenuUI.GetPage() or nil
        return WO.MenuUI.ActivatePage(page == "quests" and "overview" or "quests")
    end

    return WO.MenuUI.Show("quests")
end

WO.Hook.Add("QuestActionResult", "quest_ui_action_result", function(data)
    if not istable(data) or not data.action or not data.questId then return end

    local key = QuestRequestKey(data.action, data.questId)
    if not questRequests[key] then return end

    questRequests[key] = nil

    if data.success ~= true then
        WO.Notify.Show("error", WO.Lang:Get("quest.action_failed",
            tostring(data.reason or "unknown")))
    end

    RefreshJournal()
end)

---------------------------------------------------------------------------
-- События
---------------------------------------------------------------------------

WO.Hook.Add("QuestsSynced", "quest_ui", function()
    RefreshJournal()
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

    RefreshJournal()
end)

-- J switches to the journal inside the existing game menu.
if WO.UI and WO.UI.BindKey then
    WO.UI.BindKey(KEY_J, function()
        if WO.Character and WO.Character.GetLocal and WO.Character.GetLocal() then
            WO.Quests.ToggleLog()
        end
    end, "quests_log", { allowWhenMenuOpen = true })
end

WO.Hook.Add("CharacterMenuOpening", "quest_ui_reset", function()
    WO.Quests.LocalStates = {}
    dismissedWaypoints = {}
end)
