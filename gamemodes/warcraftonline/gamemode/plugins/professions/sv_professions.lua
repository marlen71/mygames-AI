--[[
    Warcraft Online — сервер ремёсел.
    Смена, прогресс мини-игры, перенос груза, опыт и выплаты авторитетны
    только на сервере. Активная смена намеренно не сохраняется в БД.
]]

local ORDERS_PER_SHIFT = 3
local DELIVERY_PICKUP_RADIUS = 120
local PROGRESS_SYNC_INTERVAL = 0.25
local MAX_SAVED_XP = 10000000

local function EnsureState(char)
    char.professions = istable(char.professions) and char.professions or {}
    char.professions.skills = istable(char.professions.skills) and char.professions.skills or {}
    return char.professions
end

local function MarkRevision(char)
    char.professionRevision = math.max(0, math.floor(tonumber(char.professionRevision) or 0)) + 1
end

local function GetActiveShift(ply, shiftId)
    if not IsValid(ply) or not ply:HasCharacter() then return nil end

    local char = ply:GetCharacter()
    local shift = char and char.activeProfessionShift

    if not istable(shift) or (shiftId and shift.id ~= shiftId) then return nil end

    return char, shift
end

local function GetProfessionSession(ply, professionId)
    local session = IsValid(ply) and ply.wo_dialogue or nil
    local npcDef = session and session.npcDef
    local ent = session and session.ent

    if not istable(npcDef) or npcDef.professionId ~= professionId or
        not IsValid(ent) or ent:GetClass() ~= "wo_npc" or ent.npcDef ~= npcDef or
        not WO.NPCs or WO.NPCs.Get(npcDef.id) ~= npcDef or
        not WO.Interaction or not WO.Interaction.CanInteract(ent, ply) or
        ply:GetPos():Distance(ent:GetPos()) > WO.Interaction.GetRange(ent) then
        return nil
    end

    return session
end

function WO.Professions.CanWorkAtNPC(ply, professionId)
    return GetProfessionSession(ply, professionId) ~= nil
end

local function CursorPosition(task, now)
    local elapsed = math.max(0, now - (task.startedAt or now))
    return 0.5 + 0.44 * math.sin(elapsed * (task.speed or 1) + (task.phaseOffset or 0))
end

local function IsCursorInZone(task, now)
    local position = CursorPosition(task, now)
    return math.abs(position - (task.zoneCenter or 0.5)) <= (task.zoneWidth or 0.2) * 0.5
end

local function GetRankData(def, rank)
    return def and def.ranks[math.Clamp(math.floor(tonumber(rank) or 1), 1, 3)] or nil
end

local function ResetChoiceTarget(task)
    local optionCount = #((task and task.choiceOptions) or {})
    if optionCount < 1 then return end

    if task.engine == "identify" then
        task.correctChoice = math.random(1, optionCount)
        task.choiceTarget = "Найдите заказанное растение: " .. tostring(task.choiceOptions[task.correctChoice])
        return
    end

    task.targetPrice = math.random(10, 90)
    local bestDistance = math.huge
    task.correctChoice = 1

    for index, option in ipairs(task.choiceValues or {}) do
        local distance = math.abs(option - task.targetPrice)
        if distance < bestDistance then
            task.correctChoice = index
            bestDistance = distance
        end
    end

    task.choiceTarget = "Цель сделки — " .. task.targetPrice .. " монет. Выберите ближайшую цену."
end

local function BuildTask(ply, shift, orderIndex)
    local char = ply:GetCharacter()
    local def = WO.Professions.Get(shift.professionId)
    local rank = GetRankData(def, shift.rank)
    local activity = rank and rank.activities[orderIndex]
    local gameMode = activity and WO.Professions.GetMiniGame(activity.mode)

    if not (def and rank and activity and gameMode) then return nil end

    local now = CurTime()
    local bonus = WO.Professions.GetBonus(char, def.id)
    local task = {
        orderIndex = orderIndex,
        mode = activity.mode,
        engine = gameMode.engine,
        title = activity.name,
        instruction = activity.instruction,
        phase = "working",
        progress = 0,
        startedAt = now,
        lastTick = now,
        nextSync = now + PROGRESS_SYNC_INTERVAL,
        heldTime = 0,
        goodTime = 0,
        badTime = 0,
        holding = false,
        inputs = {},
        lastActionAt = now - 1,
        progressRate = math.Clamp(tonumber(activity.progressRate) or 0.72, 0.45, 1.15) *
            (1 + bonus * 0.25),
        zoneWidth = math.Clamp((tonumber(activity.zoneWidth) or 0.22) * (1 + bonus * 0.4), 0.12, 0.38),
        speed = math.Clamp(tonumber(activity.speed) or (1.05 + shift.rank * 0.12), 0.65, 2.1),
        phaseOffset = math.random() * math.pi * 2,
    }

    if gameMode.engine == "delivery" then
        task.phase = "pickup"
        task.pickupPos = ply:GetPos()
        task.carryStartPos = nil
        task.requiredDistance = math.floor((tonumber(activity.deliveryDistance) or 520) *
            (1 - math.min(0.12, bonus * 0.3)))
        task.carriedDistance = 0
        return task
    end

    task.zoneCenter = 0.34 + math.random() * 0.32

    if gameMode.engine == "tap" then
        task.requiredHits = 5 + shift.rank * 2
    elseif gameMode.engine == "sequence" then
        task.sequence = {}
        task.sequenceIndex = 1
        local sequenceLength = 4 + math.min(2, shift.rank - 1)

        for index = 1, sequenceLength do
            task.sequence[index] = "choice" .. math.random(1, 4)
        end
    elseif gameMode.engine == "identify" or gameMode.engine == "choice" then
        task.choiceOptions = {}
        task.choiceValues = {}

        for index, label in ipairs(gameMode.choiceOptions or {}) do
            task.choiceOptions[index] = tostring(label)
            task.choiceValues[index] = tonumber(string.match(tostring(label), "%d+"))
        end

        if #task.choiceOptions < 2 then return nil end
        ResetChoiceTarget(task)
        task.requiredChoices = 3 + shift.rank
        task.choiceCount = 0
    elseif gameMode.engine == "alternate" then
        task.expectedInput = math.random(1, 2) == 1 and "left" or "right"
        task.requiredActions = 6 + shift.rank * 2
        task.actionCount = 0
    elseif gameMode.engine == "steer" or gameMode.engine == "adjust" or
        gameMode.engine == "balance" or gameMode.engine == "sweep" then
        task.axis = gameMode.axis or "horizontal"
        task.cursorPosition = 0.5
        task.cursorSpeed = 0.72 + shift.rank * 0.12
        task.targetWidth = task.zoneWidth
        task.targetPhase = math.random() * math.pi * 2
        task.targetCenter = 0.5
    elseif gameMode.engine == "precision" then
        task.cursorPosition = 0.5
        task.cursorSpeed = 0.38
        task.requiredCuts = 3 + shift.rank
        task.cutCount = 0
    elseif gameMode.engine == "dodge" then
        task.playerX, task.playerY = 0.2, 0.5
        task.hazardX, task.hazardY = 0.8, 0.25
        task.targetX, task.targetY = 0.72, 0.72
        task.dodgePhase = math.random() * math.pi * 2
    elseif gameMode.engine == "hold" or gameMode.engine == "strike" or
        gameMode.engine == "rhythm" or gameMode.engine == "stack" then
        -- The target oscillates in a profession-themed station; only the server
        -- decides whether a strike/hold landed in the valid work window.
    else
        return nil
    end

    return task
end

local function CopySequence(sequence)
    local copy = {}
    for index, value in ipairs(sequence or {}) do copy[index] = value end
    return copy
end

local function Snapshot(char)
    local state = EnsureState(char)
    local skills = {}

    for professionId in pairs(WO.Professions.GetAll()) do
        local skill = state.skills[professionId] or {}
        local xp = math.max(0, math.floor(tonumber(skill.xp) or 0))
        skills[professionId] = {
            xp = xp,
            level = WO.Professions.GetLevelForXP(professionId, xp),
            completedShifts = math.max(0, math.floor(tonumber(skill.completedShifts) or 0)),
        }
    end

    local shift = char.activeProfessionShift
    local shiftPayload

    if istable(shift) then
        local task = shift.task
        local profession = WO.Professions.Get(shift.professionId)
        local employer = WO.NPCs and WO.NPCs.Get and WO.NPCs.Get(shift.npcId)
        shiftPayload = {
            id = shift.id,
            professionId = shift.professionId,
            professionName = profession and profession.name or tostring(shift.professionId),
            npcId = shift.npcId,
            npcName = employer and employer.name or "работодатель",
            rank = shift.rank,
            completedOrders = shift.completedOrders,
            requiredOrders = shift.requiredOrders,
            status = shift.status,
            basePay = shift.basePay,
            bonus = shift.bonus,
        }

        if istable(task) then
            local gameMode = WO.Professions.GetMiniGame(task.mode)
            shiftPayload.task = {
                orderIndex = task.orderIndex,
                mode = task.mode,
                engine = gameMode and gameMode.engine or "",
                title = task.title,
                instruction = task.instruction,
                phase = task.phase,
                progress = task.progress or 0,
                elapsed = math.max(0, CurTime() - task.startedAt),
                zoneCenter = task.zoneCenter,
                zoneWidth = task.zoneWidth,
                speed = task.speed,
                phaseOffset = task.phaseOffset,
                requiredDistance = task.requiredDistance,
                carriedDistance = task.carriedDistance or 0,
                holding = task.holding == true,
                cursorPosition = task.cursorPosition,
                targetCenter = task.targetCenter,
                targetWidth = task.targetWidth,
                axis = task.axis,
                sequence = CopySequence(task.sequence),
                sequenceIndex = task.sequenceIndex,
                expectedInput = task.expectedInput,
                actionCount = task.actionCount,
                requiredActions = task.requiredActions,
                choiceOptions = task.choiceOptions,
                choiceTarget = task.choiceTarget,
                choiceCount = task.choiceCount,
                requiredChoices = task.requiredChoices,
                cutCount = task.cutCount,
                requiredCuts = task.requiredCuts,
                playerX = task.playerX,
                playerY = task.playerY,
                hazardX = task.hazardX,
                hazardY = task.hazardY,
                targetX = task.targetX,
                targetY = task.targetY,
            }
        end
    end

    return {
        characterId = char.id,
        revision = math.max(0, math.floor(tonumber(char.professionRevision) or 0)),
        skills = skills,
        shift = shiftPayload,
    }
end

function WO.Professions.Sync(ply)
    if not IsValid(ply) or not ply:HasCharacter() then return false end
    return WO.Net.Send("Profession.Sync", ply, Snapshot(ply:GetCharacter()))
end

function WO.Professions.StartShift(ply, professionId, requestedRank)
    if not IsValid(ply) or not ply:HasCharacter() then return false, "no_character" end

    local def = WO.Professions.Get(professionId)
    if not def then return false, "unknown_profession" end

    local session = GetProfessionSession(ply, professionId)
    if not session then return false, "wrong_employer" end

    local char = ply:GetCharacter()
    if istable(char.activeProfessionShift) then return false, "shift_already_active" end

    local state = EnsureState(char)
    local skill = state.skills[professionId] or { xp = 0, completedShifts = 0 }
    state.skills[professionId] = skill

    local unlockedRank = WO.Professions.GetLevelForXP(professionId, skill.xp)
    local rankIndex = requestedRank == nil and unlockedRank or tonumber(requestedRank)
    if not rankIndex or rankIndex ~= math.floor(rankIndex) or rankIndex < 1 or rankIndex > 3 then
        return false, "invalid_rank"
    end
    rankIndex = math.floor(rankIndex)
    if rankIndex > unlockedRank then return false, "rank_locked" end

    local rank = GetRankData(def, rankIndex)
    if not rank then return false, "invalid_profession_data" end
    local shift = {
        id = WO.Util.UUID(),
        professionId = professionId,
        npcId = session.npcDef.id,
        rank = rankIndex,
        completedOrders = 0,
        requiredOrders = ORDERS_PER_SHIFT,
        qualityTotal = 0,
        status = "working",
        basePay = rank.basePay,
        bonus = WO.Professions.GetBonus(char, professionId),
    }

    shift.task = BuildTask(ply, shift, 1)
    if not shift.task then return false, "invalid_profession_data" end

    char.activeProfessionShift = shift
    MarkRevision(char)
    WO.Professions.Sync(ply)
    WO.Notify(ply, "info", "Вы начали смену: " .. def.name .. " — " .. rank.name .. ".")
    WO.Hook.Run("ProfessionShiftStarted", char, def, rankIndex)

    return true, shift
end

local CompleteOrder

local function AddTaskProgress(ply, char, shift, task, amount, successful)
    task.totalActions = (task.totalActions or 0) + 1

    if successful then
        task.goodActions = (task.goodActions or 0) + 1
        task.progress = math.min(1, (task.progress or 0) + amount)
    else
        task.badActions = (task.badActions or 0) + 1
        task.progress = math.max(0, (task.progress or 0) - 0.04)
    end

    if task.progress >= 1 then
        local total = math.max(1, task.totalActions or 1)
        local quality = math.Clamp((task.goodActions or 0) / total, 0.5, 1)
        return CompleteOrder(ply, char, shift, quality)
    end

    return true
end

local function ActionChoice(action)
    local choice = string.match(action or "", "^choice([1-4])$")
    return tonumber(choice)
end

function WO.Professions.HandleInput(ply, shiftId, action, value)
    local char, shift = GetActiveShift(ply, shiftId)
    if not char or shift.status ~= "working" or not istable(shift.task) then
        return false, "no_active_shift"
    end

    local task = shift.task
    local gameMode = WO.Professions.GetMiniGame(task.mode)
    local engine = gameMode and gameMode.engine
    local now = CurTime()

    if action == "pickup" then
        if engine ~= "delivery" or task.phase ~= "pickup" then return false, "wrong_task" end

        local pickupPosition = task.pickupPos
        if not pickupPosition or ply:GetPos():Distance(pickupPosition) > DELIVERY_PICKUP_RADIUS then
            return false, "too_far_from_pickup"
        end

        task.phase = "carry"
        task.carryStartPos = ply:GetPos()
        task.carriedDistance = 0
        task.nextSync = now + PROGRESS_SYNC_INTERVAL
        MarkRevision(char)
        WO.Professions.Sync(ply)
        WO.Notify(ply, "info", "Груз взят. Доставьте его, пройдя нужное расстояние.")
        return true
    end

    if action == "hold" then
        if engine ~= "hold" then return false, "wrong_task" end
        task.holding = value == true
        task.lastTick = now
        WO.Professions.Sync(ply)
        return true
    end

    if not value then
        if task.inputs and task.inputs[action] ~= nil then
            task.inputs[action] = false
            task.lastTick = now
            return true
        end
        return false, "input_released"
    end

    local choice = ActionChoice(action)
    local isDirection = action == "left" or action == "right" or action == "up" or action == "down"

    if isDirection and task.inputs then
        if engine == "steer" or engine == "adjust" or engine == "balance" or
            engine == "sweep" or engine == "dodge" then
            task.inputs[action] = true
            task.lastTick = now
            return true
        end
    end

    if choice and engine == "sequence" then
        local expected = task.sequence and task.sequence[task.sequenceIndex or 1]

        if action == expected then
            task.sequenceIndex = (task.sequenceIndex or 1) + 1
            task.progress = math.min(1, ((task.sequenceIndex - 1) / #task.sequence))
            task.goodActions = (task.goodActions or 0) + 1
            task.totalActions = (task.totalActions or 0) + 1

            if task.sequenceIndex > #task.sequence then
                return CompleteOrder(ply, char, shift, 1)
            end
        else
            task.totalActions = (task.totalActions or 0) + 1
            task.badActions = (task.badActions or 0) + 1
            task.sequenceIndex = action == task.sequence[1] and 2 or 1
            task.progress = (task.sequenceIndex - 1) / #task.sequence
        end

        task.nextSync = now
        WO.Professions.Sync(ply)
        return true
    end

    if isDirection and value and engine == "alternate" then
        if now - (task.lastActionAt or 0) < 0.16 then return false, "too_fast" end
        task.lastActionAt = now
        local successful = action == task.expectedInput

        if successful then
            task.actionCount = (task.actionCount or 0) + 1
            task.expectedInput = action == "left" and "right" or "left"
        end

        task.progress = math.Clamp((task.actionCount or 0) / (task.requiredActions or 1), 0, 1)
        return AddTaskProgress(ply, char, shift, task, 0, successful)
    end

    if choice and (engine == "choice" or engine == "identify") then
        if now - (task.lastActionAt or 0) < 0.20 then return false, "too_fast" end
        task.lastActionAt = now
        task.choiceAttempts = (task.choiceAttempts or 0) + 1
        task.totalActions = (task.totalActions or 0) + 1
        local successful = choice == task.correctChoice

        if successful then
            task.choiceCount = (task.choiceCount or 0) + 1
            task.progress = math.min(1, task.choiceCount / task.requiredChoices)
            task.goodActions = (task.goodActions or 0) + 1
            if task.progress >= 1 then
                local quality = math.Clamp((task.goodActions or 0) / math.max(1, task.totalActions), 0.5, 1)
                return CompleteOrder(ply, char, shift, quality)
            end
            ResetChoiceTarget(task)
        else
            task.progress = math.max(0, (task.progress or 0) - 0.08)
            task.badActions = (task.badActions or 0) + 1
        end

        task.nextSync = now
        WO.Professions.Sync(ply)
        return true
    end

    if engine == "precision" and isDirection then
        local direction = (action == "left" or action == "down") and -1 or 1
        task.cursorPosition = math.Clamp((task.cursorPosition or 0.5) + direction * 0.07, 0.02, 0.98)
        task.nextSync = now
        WO.Professions.Sync(ply)
        return true
    end

    if action == "confirm" and engine == "precision" then
        if now - (task.lastActionAt or 0) < 0.25 then return false, "too_fast" end
        task.lastActionAt = now
        local target = task.targetCenter or 0.5
        local successful = math.abs((task.cursorPosition or 0.5) - target) <= task.zoneWidth * 0.5

        if successful then
            task.cutCount = (task.cutCount or 0) + 1
            task.progress = task.cutCount / task.requiredCuts
        end

        if task.progress >= 1 then return CompleteOrder(ply, char, shift, 1) end
        return AddTaskProgress(ply, char, shift, task, 0, successful)
    end

    if (action == "strike" and (engine == "strike" or engine == "rhythm" or engine == "stack")) or
        (action == "tap" and engine == "tap") then
        if now - (task.lastActionAt or 0) < 0.16 then return false, "too_fast" end
        task.lastActionAt = now
        local successful = engine == "tap" or IsCursorInZone(task, now)
        local amount = engine == "tap" and (1 / task.requiredHits) or
            math.max(0.12, math.min(0.36, task.progressRate * 0.36))
        return AddTaskProgress(ply, char, shift, task, amount, successful)
    end

    return false, "wrong_task"
end

CompleteOrder = function(ply, char, shift, quality)
    local def = WO.Professions.Get(shift.professionId)
    if not def then return false end

    shift.qualityTotal = shift.qualityTotal + math.Clamp(tonumber(quality) or 0.8, 0.5, 1)
    shift.completedOrders = shift.completedOrders + 1

    if shift.completedOrders >= shift.requiredOrders then
        shift.completedOrders = shift.requiredOrders
        shift.status = "ready"
        shift.task = nil
        shift.qualityTotal = math.Clamp(shift.qualityTotal, 0, shift.requiredOrders)
        MarkRevision(char)
        WO.Professions.Sync(ply)
        local employer = WO.NPCs and WO.NPCs.Get and WO.NPCs.Get(shift.npcId)
        WO.Notify(ply, "info", "Все заказы выполнены. Вернитесь к работодателю «" ..
            tostring(employer and employer.name or "") .. "» и сдайте смену.")
        WO.Hook.Run("ProfessionShiftReady", char, def, shift)
        return true
    end

    shift.task = BuildTask(ply, shift, shift.completedOrders + 1)
    if not shift.task then
        char.activeProfessionShift = nil
        MarkRevision(char)
        WO.Professions.Sync(ply)
        return false
    end

    MarkRevision(char)
    WO.Professions.Sync(ply)
    WO.Notify(ply, "info", "Заказ сдан: " .. shift.completedOrders .. "/" .. shift.requiredOrders .. ".")
    WO.Hook.Run("ProfessionOrderCompleted", char, def, shift.completedOrders)
    return true
end

function WO.Professions.TickPlayer(ply, now)
    if not IsValid(ply) or not ply:HasCharacter() then return false end

    local char = ply:GetCharacter()
    local shift = char and char.activeProfessionShift
    if not istable(shift) or shift.status ~= "working" or not istable(shift.task) then return false end

    now = tonumber(now) or CurTime()
    local task = shift.task
    local gameMode = WO.Professions.GetMiniGame(task.mode)
    local engine = gameMode and gameMode.engine

    if engine == "hold" then
        local dt = math.Clamp(now - (task.lastTick or now), 0, 0.20)
        task.lastTick = now

        if task.holding and dt > 0 then
            task.heldTime = task.heldTime + dt

            if IsCursorInZone(task, now) then
                task.goodTime = task.goodTime + dt
                task.progress = math.min(1, (task.progress or 0) + dt * task.progressRate)
            else
                task.badTime = task.badTime + dt
                task.progress = math.max(0, (task.progress or 0) - dt * 0.34)
            end
        end

        if (task.progress or 0) >= 1 then
            local quality = task.heldTime > 0 and task.goodTime / task.heldTime or 0.8
            return CompleteOrder(ply, char, shift, quality)
        end
    elseif engine == "delivery" and task.phase == "carry" and task.carryStartPos then
        task.carriedDistance = ply:GetPos():Distance(task.carryStartPos)

        if task.carriedDistance >= task.requiredDistance then
            return CompleteOrder(ply, char, shift, 1)
        end
    elseif engine == "steer" or engine == "adjust" or engine == "balance" or engine == "sweep" then
        local dt = math.Clamp(now - (task.lastTick or now), 0, 0.20)
        task.lastTick = now
        task.heldTime = (task.heldTime or 0) + dt
        task.targetCenter = 0.5 + 0.28 * math.sin(now * (task.speed or 1) + (task.targetPhase or 0))

        local negative = task.axis == "vertical" and "down" or "left"
        local positive = task.axis == "vertical" and "up" or "right"
        local direction = (task.inputs[positive] and 1 or 0) - (task.inputs[negative] and 1 or 0)
        local sway = engine == "balance" and math.sin(now * 2.6 + (task.targetPhase or 0)) * 0.18 or 0
        task.cursorPosition = math.Clamp((task.cursorPosition or 0.5) +
            (direction * 0.9 + sway) * dt, 0.02, 0.98)

        local aligned = math.abs(task.cursorPosition - task.targetCenter) <=
            (task.targetWidth or task.zoneWidth) * 0.5
        local activelyWorking = direction ~= 0 or engine == "balance"

        if aligned and activelyWorking then
            task.goodTime = (task.goodTime or 0) + dt
            task.progress = math.min(1, (task.progress or 0) + dt * task.progressRate)
        else
            task.badTime = (task.badTime or 0) + dt
            task.progress = math.max(0, (task.progress or 0) - dt * 0.16)
        end

        if task.progress >= 1 then
            local quality = task.heldTime > 0 and (task.goodTime or 0) / task.heldTime or 0.8
            return CompleteOrder(ply, char, shift, quality)
        end
    elseif engine == "precision" then
        task.targetCenter = 0.5 + 0.18 * math.sin(now * (task.speed or 1) + (task.phaseOffset or 0))
    elseif engine == "dodge" then
        local dt = math.Clamp(now - (task.lastTick or now), 0, 0.20)
        task.lastTick = now
        local speed = 0.75 * dt
        task.playerX = math.Clamp((task.playerX or 0.2) +
            ((task.inputs.right and 1 or 0) - (task.inputs.left and 1 or 0)) * speed, 0.04, 0.96)
        task.playerY = math.Clamp((task.playerY or 0.5) +
            ((task.inputs.down and 1 or 0) - (task.inputs.up and 1 or 0)) * speed, 0.04, 0.96)
        task.hazardX = 0.5 + 0.34 * math.sin(now * 1.3 + (task.dodgePhase or 0))
        task.hazardY = 0.5 + 0.30 * math.cos(now * 1.7 + (task.dodgePhase or 0))
        task.heldTime = (task.heldTime or 0) + dt

        local hazardDistance = math.sqrt((task.playerX - task.hazardX) ^ 2 +
            (task.playerY - task.hazardY) ^ 2)
        local targetDistance = math.sqrt((task.playerX - task.targetX) ^ 2 +
            (task.playerY - task.targetY) ^ 2)

        if hazardDistance < 0.14 then
            task.progress = math.max(0, (task.progress or 0) - dt * 0.5)
            task.badTime = (task.badTime or 0) + dt
        elseif targetDistance < 0.16 then
            task.progress = math.min(1, (task.progress or 0) + 0.22)
            task.goodTime = (task.goodTime or 0) + 0.22
            task.targetX = math.random(15, 85) / 100
            task.targetY = math.random(15, 85) / 100
        end

        if task.progress >= 1 then
            return CompleteOrder(ply, char, shift, 0.9)
        end
    end

    if now >= (task.nextSync or 0) then
        task.nextSync = now + PROGRESS_SYNC_INTERVAL
        WO.Professions.Sync(ply)
    end

    return true
end

function WO.Professions.FinishShift(ply, shiftId)
    local char, shift = GetActiveShift(ply, shiftId)
    if not char then return false, "no_active_shift" end

    local session = GetProfessionSession(ply, shift.professionId)
    if not session or session.npcDef.id ~= shift.npcId then return false, "wrong_employer" end
    if shift.status ~= "ready" or shift.completedOrders ~= shift.requiredOrders then
        return false, "orders_incomplete"
    end

    local def = WO.Professions.Get(shift.professionId)
    local rank = GetRankData(def, shift.rank)
    if not (def and rank) then return false, "invalid_profession_data" end

    local averageQuality = math.Clamp(shift.qualityTotal / shift.requiredOrders, 0.5, 1)
    local qualityMultiplier = 0.75 + averageQuality * 0.5
    local currentBonus = WO.Professions.GetBonus(char, def.id)
    local payout = math.max(1, math.floor(rank.basePay * shift.requiredOrders *
        qualityMultiplier * (1 + currentBonus)))

    -- Currency.Add is the only payout path. Never grant it on an order packet or
    -- on a client-provided amount; the active shift is consumed after payment.
    if not WO.Currency.Add(ply, payout, "profession_shift:" .. def.id) then
        return false, "payment_failed"
    end

    local state = EnsureState(char)
    local skill = state.skills[def.id] or { xp = 0, completedShifts = 0 }
    local oldLevel = WO.Professions.GetLevelForXP(def.id, skill.xp)
    skill.xp = math.min(MAX_SAVED_XP, math.max(0, math.floor(tonumber(skill.xp) or 0)) +
        def.xpPerOrder * shift.requiredOrders)
    skill.completedShifts = math.max(0, math.floor(tonumber(skill.completedShifts) or 0)) + 1
    state.skills[def.id] = skill

    local newLevel = WO.Professions.GetLevelForXP(def.id, skill.xp)
    char.activeProfessionShift = nil
    MarkRevision(char)

    if WO.SaveQueue then WO.SaveQueue.MarkDirty(char) end
    WO.Professions.Sync(ply)
    WO.Notify(ply, "success", "Смена завершена: зарплата " .. payout .. " монет, опыт ремесла +" ..
        (def.xpPerOrder * ORDERS_PER_SHIFT) .. ".")

    if newLevel > oldLevel then
        local newRank = GetRankData(def, newLevel)
        WO.Notify(ply, "success", "Повышение: " .. def.name .. " — " .. newRank.name ..
            ". Зарплата за следующую смену выше.")
        WO.Hook.Run("ProfessionRankUp", char, def, oldLevel, newLevel)
    end

    WO.Hook.Run("ProfessionShiftFinished", char, def, shift.rank, payout)
    return true, payout, newLevel
end

function WO.Professions.CancelShift(ply, shiftId)
    local char, shift = GetActiveShift(ply, shiftId)
    if not char then return false, "no_active_shift" end

    char.activeProfessionShift = nil
    MarkRevision(char)
    WO.Professions.Sync(ply)
    WO.Notify(ply, "info", "Смена отменена. Зарплата и опыт выдаются только после полного завершения смены.")
    WO.Hook.Run("ProfessionShiftCancelled", char, shift)
    return true
end

---------------------------------------------------------------------------
-- Character persistence: one compact row in the existing wo_skills table.
---------------------------------------------------------------------------

WO.Hook.Add("CharacterLoad", "professions", function(char)
    char.professions = { skills = {} }
    char.activeProfessionShift = nil
    char.professionRevision = 0

    local rows = WO.Database:Fetch(
        "SELECT data FROM wo_skills WHERE owner_id = ? AND skill_id = ?",
        char.id, "professions")
    local saved = rows[1] and util.JSONToTable(rows[1].data or "") or nil

    if not istable(saved) or not istable(saved.skills) then return end

    for professionId, value in pairs(saved.skills) do
        if WO.Professions.Get(professionId) and istable(value) then
            char.professions.skills[professionId] = {
                xp = math.Clamp(math.floor(tonumber(value.xp) or 0), 0, MAX_SAVED_XP),
                completedShifts = math.max(0, math.floor(tonumber(value.completedShifts) or 0)),
            }
        end
    end
end)

WO.Hook.Add("CharacterSave", "professions", function(char)
    if not char.id then return end

    local state = EnsureState(char)
    local savedSkills = {}
    local highestLevel = 0

    for professionId in pairs(WO.Professions.GetAll()) do
        local skill = state.skills[professionId]
        if istable(skill) then
            local xp = math.Clamp(math.floor(tonumber(skill.xp) or 0), 0, MAX_SAVED_XP)
            savedSkills[professionId] = {
                xp = xp,
                completedShifts = math.max(0, math.floor(tonumber(skill.completedShifts) or 0)),
            }
            highestLevel = math.max(highestLevel, WO.Professions.GetLevelForXP(professionId, xp))
        end
    end

    WO.Database:Delete("wo_skills", "owner_id = ? AND skill_id = ?", char.id, "professions")
    WO.Database:Insert("wo_skills", {
        owner_id = char.id,
        skill_id = "professions",
        level = highestLevel,
        data = util.TableToJSON({ skills = savedSkills }),
    })
end)

WO.Hook.Add("CharacterSelected", "professions", function(_, ply)
    WO.Professions.Sync(ply)
end)

WO.Hook.Add("CharacterUnloaded", "professions_cancel_on_unload", function(char)
    if char then char.activeProfessionShift = nil end
end)

hook.Add("Think", "wo_professions_tick", function()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:HasCharacter() then
            WO.Professions.TickPlayer(ply, CurTime())
        end
    end
end)
