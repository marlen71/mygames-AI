--[[
    Warcraft Online — очередь сохранений (server).
    Не пишем в БД после каждого клика UI: персонаж помечается «грязным»
    (dirty state) и сохраняется пачкой по таймеру / при критических событиях.

    WO.SaveQueue:MarkDirty(char)   — отметить персонажа
    WO.SaveQueue:SaveNow(char)     — сохранить немедленно (disconnect, смена персонажа)
    WO.SaveQueue:FlushAll()        — сохранить всех (shutdown)
]]

WO.SaveQueue = WO.SaveQueue or {}

local dirtyChars = {}
local flushCount = 0

local function QueueKey(char)
    return isstring(char.id) and char.id ~= "" and char.id or char
end

local function IsActiveCharacter(char)
    if not WO.Character.IsCharacter(char) then return false end

    local ply = char.player

    return IsValid(ply) and isfunction(ply.GetCharacter) and ply:GetCharacter() == char
end

local function FindActiveCharacter(id)
    if not isstring(id) or not player or not isfunction(player.GetAll) then return nil end

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and isfunction(ply.GetCharacter) then
            local char = ply:GetCharacter()

            if WO.Character.IsCharacter(char) and char.id == id then
                return char
            end
        end
    end

    return nil
end

--[[
    Помечает персонажа как изменённого (будет сохранён при следующем flush).
    Очередь индексируется по ID, чтобы повторная загрузка не оставляла
    несколько устаревших объектов, которые могли бы перезаписать прогресс.
]]
function WO.SaveQueue.MarkDirty(char)
    if not WO.Character.IsCharacter(char) then return end

    local key = QueueKey(char)
    local pending = dirtyChars[key]

    if (pending ~= nil and pending ~= char) or not IsActiveCharacter(char) then
        local active = FindActiveCharacter(isstring(key) and key or nil)

        if active then char = active end
        pending = dirtyChars[key]
    end

    -- Не даём отложенному старому объекту заменить активную версию персонажа.
    if pending ~= char and IsActiveCharacter(pending) and not IsActiveCharacter(char) then
        return
    end

    dirtyChars[key] = char
end

--- Убирает персонажа из очереди, если там всё ещё именно этот объект.
function WO.SaveQueue.Clear(char)
    if not WO.Character.IsCharacter(char) then return end

    local key = QueueKey(char)

    if dirtyChars[key] == char then
        dirtyChars[key] = nil
    end
end

--- Есть ли несохранённые изменения для этого персонажа.
function WO.SaveQueue.IsDirty(char)
    if not WO.Character.IsCharacter(char) then return false end

    return dirtyChars[QueueKey(char)] ~= nil
end

--- Перед загрузкой записи синхронизирует возможный failed-save из этой очереди.
function WO.SaveQueue.SavePendingByID(charId)
    if not isstring(charId) or charId == "" then return true, false end

    local char = dirtyChars[charId]

    if not char then return true, false end

    return WO.SaveQueue.SaveNow(char), true
end

--[[
    Сохраняет персонажа немедленно (через WO.Character.Save).
    Вызывается при disconnect / смене персонажа / уровне.
]]
function WO.SaveQueue.SaveNow(char)
    if not WO.Character.IsCharacter(char) then return false end

    local key = QueueKey(char)
    local pending = dirtyChars[key]

    if (pending ~= nil and pending ~= char) or not IsActiveCharacter(char) then
        local active = FindActiveCharacter(isstring(key) and key or nil)

        if active then char = active end
        pending = dirtyChars[key]
    end

    -- Do not let an older disconnected snapshot overwrite a newer loaded object.
    if pending and pending ~= char and not IsActiveCharacter(char) then
        return false
    end

    local ok = WO.Character.Save(char)
    pending = dirtyChars[key]

    if ok then
        -- A successful current-object write supersedes a stale queued snapshot.
        if pending == char or not IsActiveCharacter(pending) then
            dirtyChars[key] = nil
        end
    else
        -- Keep retries by stable character ID; prefer any active newer object.
        if pending == nil or pending == char or not IsActiveCharacter(pending) then
            dirtyChars[key] = char
        end
    end

    return ok
end

--- Сохраняет всех «грязных» персонажей.
function WO.SaveQueue.FlushAll()
    local count = 0

    for key, char in pairs(dirtyChars) do
        if not WO.Character.IsCharacter(char) then
            if dirtyChars[key] == char then dirtyChars[key] = nil end
        else
            -- Prefer the live object if an older snapshot remained queued through reload.
            if not IsActiveCharacter(char) then
                local active = FindActiveCharacter(isstring(key) and key or nil)

                if active then
                    char = active
                    dirtyChars[key] = char
                end
            end

            if WO.Character.Save(char) then
                count = count + 1

                -- A newer object can replace this entry from a save hook.
                if dirtyChars[key] == char then dirtyChars[key] = nil end
            end -- Failed writes stay queued for the next flush.
        end
    end

    flushCount = flushCount + 1

    if count > 0 then
        WO.Debug("SaveQueue flush #" .. flushCount .. ": saved " .. count .. " character(s)")
    end

    return count
end

---------------------------------------------------------------------------
-- Периодический flush
---------------------------------------------------------------------------

local function StartFlushTimer()
    local interval = WO.Config.AutosaveInterval or 60

    timer.Create("wo_savequeue_flush", interval, 0, function()
        WO.SaveQueue.FlushAll()
    end)
end

hook.Add("Initialize", "wo_savequeue_init", StartFlushTimer)

-- Принудительный flush при выключении сервера
hook.Add("ShutDown", "wo_savequeue_shutdown", function()
    WO.Log("Shutting down — flushing save queue...")
    WO.SaveQueue.FlushAll()
end)

-- Сохранение при дисконнекте — в sv_players/sv_characters (PlayerDisconnected)
