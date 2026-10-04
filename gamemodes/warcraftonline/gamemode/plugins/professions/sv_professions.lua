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

local function BuildTask(ply, shift, orderIndex)
    local char = ply:GetCharacter()
    local def = WO.Professions.Get(shift.professionId)
    local rank = GetRankData(def, shift.rank)
    local activity = rank and rank.activities[orderIndex]

    if not (def and rank and activity) then return nil end

    local now = CurTime()
    local bonus = WO.Professions.GetBonus(char, def.id)
    local task = {
        orderIndex = orderIndex,
        mode = activity.mode,
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
    }

    if activity.mode == "timing" then
        task.zoneCenter = 0.34 + math.random() * 0.32
        task.zoneWidth = math.Clamp((tonumber(activity.zoneWidth) or 0.22) * (1 + bonus * 0.4), 0.12, 0.34)
        task.speed = math.Clamp(tonumber(activity.speed) or (1.05 + shift.rank * 0.12), 0.65, 2.1)
        task.phaseOffset = math.random() * math.pi * 2
        task.progressRate = math.Clamp(tonumber(activity.progressRate) or 0.72, 0.45, 1.15) *
            (1 + bonus * 0.25)
    else
        task.phase = "pickup"
        task.pickupPos = ply:GetPos()
        task.carryStartPos = nil
        task.requiredDistance = math.floor((tonumber(activity.deliveryDistance) or 520) *
            (1 - math.min(0.12, bonus * 0.3)))
        task.carriedDistance = 0
    end

    return task
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
        shiftPayload = {
            id = shift.id,
            professionId = shift.professionId,
            rank = shift.rank,
            completedOrders = shift.completedOrders,
            requiredOrders = shift.requiredOrders,
            status = shift.status,
            basePay = shift.basePay,
            bonus = shift.bonus,
        }

        if istable(task) then
            shiftPayload.task = {
                orderIndex = task.orderIndex,
                mode = task.mode,
                title = task.title,
                instruction = task.instruction,
                phase = task.phase,
                progress = task.progress or 0,
                elapsed = task.mode == "timing" and math.max(0, CurTime() - task.startedAt) or 0,
                zoneCenter = task.zoneCenter,
                zoneWidth = task.zoneWidth,
                speed = task.speed,
                phaseOffset = task.mode == "timing" and task.phaseOffset or nil,
                requiredDistance = task.requiredDistance,
                carriedDistance = task.carriedDistance or 0,
                holding = task.holding == true,
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

function WO.Professions.StartShift(ply, professionId)
    if not IsValid(ply) or not ply:HasCharacter() then return false, "no_character" end

    local def = WO.Professions.Get(professionId)
    if not def then return false, "unknown_profession" end

    local char = ply:GetCharacter()
    if istable(char.activeProfessionShift) then return false, "shift_already_active" end

    local state = EnsureState(char)
    local skill = state.skills[professionId] or { xp = 0, completedShifts = 0 }
    state.skills[professionId] = skill

    local level = WO.Professions.GetLevelForXP(professionId, skill.xp)
    local rank = GetRankData(def, level)
    local shift = {
        id = WO.Util.UUID(),
        professionId = professionId,
        rank = level,
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
    WO.Hook.Run("ProfessionShiftStarted", char, def, level)

    return true, shift
end

function WO.Professions.HandleInput(ply, shiftId, action, value)
    local char, shift = GetActiveShift(ply, shiftId)
    if not char or shift.status ~= "working" or not istable(shift.task) then
        return false, "no_active_shift"
    end

    local task = shift.task

    if action == "hold" then
        if task.mode ~= "timing" then return false, "wrong_task" end
        task.holding = value == true
        task.lastTick = CurTime()
        WO.Professions.Sync(ply)
        return true
    end

    if action == "pickup" then
        if task.mode ~= "delivery" or task.phase ~= "pickup" then return false, "wrong_task" end

        local pickupPosition = task.pickupPos
        if not pickupPosition or ply:GetPos():Distance(pickupPosition) > DELIVERY_PICKUP_RADIUS then
            return false, "too_far_from_pickup"
        end

        task.phase = "carry"
        task.carryStartPos = ply:GetPos()
        task.carriedDistance = 0
        task.nextSync = CurTime() + PROGRESS_SYNC_INTERVAL
        MarkRevision(char)
        WO.Professions.Sync(ply)
        WO.Notify(ply, "info", "Груз взят. Доставьте его, пройдя нужное расстояние.")
        return true
    end

    return false, "invalid_action"
end

local function CompleteOrder(ply, char, shift, quality)
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
        WO.Notify(ply, "info", "Все заказы выполнены. Завершите смену, чтобы получить зарплату.")
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

    if task.mode == "timing" then
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
    elseif task.mode == "delivery" and task.phase == "carry" and task.carryStartPos then
        task.carriedDistance = ply:GetPos():Distance(task.carryStartPos)

        if task.carriedDistance >= task.requiredDistance then
            return CompleteOrder(ply, char, shift, 1)
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
