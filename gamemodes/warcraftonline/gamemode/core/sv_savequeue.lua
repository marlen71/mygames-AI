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

--[[
    Помечает персонажа как изменённого (будет сохранён при следующем flush).
]]
function WO.SaveQueue.MarkDirty(char)
    if not WO.Character.IsCharacter(char) then return end

    dirtyChars[char] = true
end

--- Убирает персонажа из очереди.
function WO.SaveQueue.Clear(char)
    dirtyChars[char] = nil
end

--- Есть ли несохранённые изменения.
function WO.SaveQueue.IsDirty(char)
    return dirtyChars[char] == true
end

--[[
    Сохраняет персонажа немедленно (через WO.Character.Save).
    Вызывается при disconnect / смене персонажа / уровне.
]]
function WO.SaveQueue.SaveNow(char)
    if not WO.Character.IsCharacter(char) then return false end

    dirtyChars[char] = nil

    return WO.Character.Save(char)
end

--- Сохраняет всех «грязных» персонажей.
function WO.SaveQueue.FlushAll()
    local count = 0

    for char in pairs(dirtyChars) do
        if WO.Character.IsCharacter(char) then
            if WO.Character.Save(char) then
                count = count + 1
            end
        end

        dirtyChars[char] = nil
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
