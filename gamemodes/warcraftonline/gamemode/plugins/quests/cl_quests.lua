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

                if distanceSquared <= radiusSquared then
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
-- Журнал квестов (клавиша J)
---------------------------------------------------------------------------

local questFrame = nil
local questRequests = {}
local questRequestSerial = 0

local function QuestRequestKey(action, questId)
    return tostring(action) .. "\0" .. tostring(questId)
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

        if IsValid(questFrame) then
            WO.Quests.OpenLog()
        end
    end)

    return true
end

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

                local trackBtn
                trackBtn = WO.UI.Button(buttonsRow,
                    state.tracked ~= false and WO.Lang:Get("quest.untrack") or WO.Lang:Get("quest.track"),
                    function()
                        RequestQuestAction("track", questId, trackBtn, function()
                            WO.Net.SendToServer("Quest.Track", questId, state.tracked == false)
                        end)
                    end)

                trackBtn:Dock(LEFT)
                trackBtn:SetWide(140)
                if questRequests[QuestRequestKey("track", questId)] then
                    trackBtn:SetBusy(true, WO.Lang:Get("ui.pending"))
                end

                local abandonBtn
                abandonBtn = WO.UI.Button(buttonsRow, WO.Lang:Get("quest.abandon"), function()
                    RequestQuestAction("abandon", questId, abandonBtn, function()
                        WO.Net.SendToServer("Quest.Abandon", questId)
                    end)
                end)

                abandonBtn:Dock(RIGHT)
                abandonBtn:SetWide(120)
                if questRequests[QuestRequestKey("abandon", questId)] then
                    abandonBtn:SetBusy(true, WO.Lang:Get("ui.pending"))
                end
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

WO.Hook.Add("QuestActionResult", "quest_ui_action_result", function(data)
    if not istable(data) or not data.action or not data.questId then return end

    local key = QuestRequestKey(data.action, data.questId)
    if not questRequests[key] then return end

    questRequests[key] = nil

    if data.success ~= true then
        WO.Notify.Show("error", WO.Lang:Get("quest.action_failed",
            tostring(data.reason or "unknown")))
    end

    if IsValid(questFrame) then
        WO.Quests.OpenLog()
    end
end)

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
    dismissedWaypoints = {}
end)
