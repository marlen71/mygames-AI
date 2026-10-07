--[[
    Warcraft Online — сетевой менеджер.
    Единый API регистрации и обмена net-сообщениями с rate-limit и валидацией.

    Пример регистрации:
        WO.Net.Register("Inventory.Move", {
            direction = "toserver",           -- "toserver" | "toclient" | "both"
            rate = { max = 30, window = 1 },  -- 30 сообщений в секунду на игрока
            write = function(uid, x, y)
                net.WriteString(uid)
                net.WriteUInt(x, 8)
                net.WriteUInt(y, 8)
            end,
            read = function()
                return net.ReadString(), net.ReadUInt(8), net.ReadUInt(8)
            end,
            validate = function(ply, uid, x, y)   -- только для toserver
                return isstring(uid)
            end,
            handler = function(ply, uid, x, y)    -- клиент: первым аргументом придёт nil
                ...
            end,
        })

    Отправка:
        WO.Net.SendToServer("Inventory.Move", uid, x, y)   -- клиент
        WO.Net.Send("Inventory.Sync", ply, ...)             -- сервер → игрок
        WO.Net.Broadcast("Notify.Show", ...)                -- сервер → все
]]

WO.Net = WO.Net or {}
WO.Net.Messages = WO.Net.Messages or {}

local DEFAULT_RATE = { max = 20, window = 1 }

-- Слабые счётчики rate-limit: Player → msgName → { count, windowStart }
local rateData = setmetatable({}, { __mode = "k" })

local function PackArgs(...)
    return { n = select("#", ...), ... }
end

---------------------------------------------------------------------------
-- Регистрация
---------------------------------------------------------------------------

--[[
    Регистрирует net-сообщение.

    @param name string уникальное имя (рекомендуется "Module.Action")
    @param def table описание: direction, rate, write, read, validate, handler
    @return boolean success
]]
function WO.Net.Register(name, def)
    if not isstring(name) or name == "" then
        WO.Error("WO.Net.Register: invalid name")
        return false
    end

    if not istable(def) then
        WO.Error("WO.Net.Register: invalid definition for '" .. name .. "'")
        return false
    end

    if WO.Net.Messages[name] then
        WO.Error("WO.Net.Register: duplicate message '" .. name .. "'")
        return false
    end

    def.direction = def.direction or "toserver"

    if def.direction ~= "toserver" and def.direction ~= "toclient" and def.direction ~= "both" then
        WO.Error("WO.Net.Register: invalid direction for '" .. name .. "'")
        return false
    end

    if not isfunction(def.handler) then
        WO.Error("WO.Net.Register: missing handler for '" .. name .. "'")
        return false
    end

    WO.Net.Messages[name] = def

    if SERVER then
        util.AddNetworkString(name)
    end

    net.Receive(name, function(len, ply)
        -- Запрещаем принимать сообщения противоположного направления: определения
        -- shared регистрируются в обоих realm, но это не делает toclient/toserver
        -- двусторонними протоколами.
        if SERVER and def.direction == "toclient" then return end
        if CLIENT and def.direction == "toserver" then return end

        -- На клиенте ply = nil
        if SERVER then
            if not IsValid(ply) then return end

            if not WO.Net.CheckRate(ply, name) then
                WO.Warn("Net rate limit exceeded: " .. ply:Nick() .. " -> " .. name)
                return
            end

            local maxLen = (WO.Config and WO.Config.MaxNetMessageLength) or 65536

            if len and len > maxLen then
                WO.Warn("Oversized net message " .. name .. " (" .. tostring(len) .. " bytes) from " .. ply:Nick())
                return
            end
        end

        -- Чтение аргументов (поддержка множественных return из read)
        local args = PackArgs()

        if isfunction(def.read) then
            local readResult = PackArgs(pcall(def.read))

            if not readResult[1] then
                WO.Error("Net read failed for '" .. name .. "': " .. tostring(readResult[2]))
                return
            end

            args = PackArgs(unpack(readResult, 2, readResult.n))
        end

        -- Валидация (только сервер: клиенту не доверяем)
        if SERVER and isfunction(def.validate) then
            local vResult = PackArgs(pcall(def.validate, ply, unpack(args, 1, args.n)))

            if not vResult[1] then
                WO.Error("Net validate failed for '" .. name .. "': " .. tostring(vResult[2]))
                return
            end

            if vResult[2] == false then
                WO.Debug("Net rejected: " .. name .. " from " .. ply:Nick() ..
                    (vResult[3] and (" — " .. tostring(vResult[3])) or ""))
                return
            end
        end

        local ok, err = pcall(def.handler, ply, unpack(args, 1, args.n))

        if not ok then
            WO.Error("Net handler failed for '" .. name .. "': " .. tostring(err))
        end
    end)

    WO.Debug("Net registered:", name, "(" .. def.direction .. ")")

    return true
end

---------------------------------------------------------------------------
-- Rate limit
---------------------------------------------------------------------------

--[[
    Проверяет rate limit игрока на сообщение.

    @param ply Player
    @param name string
    @return boolean false = лимит превышен
]]
function WO.Net.CheckRate(ply, name)
    local def = WO.Net.Messages[name]
    local rate = (def and def.rate) or DEFAULT_RATE
    local maxPerWindow = rate.max or DEFAULT_RATE.max
    local window = rate.window or DEFAULT_RATE.window

    local now = SysTime()
    local perPlayer = rateData[ply]

    if not perPlayer then
        perPlayer = {}
        rateData[ply] = perPlayer
    end

    local entry = perPlayer[name]

    if not entry or (now - entry.windowStart) >= window then
        perPlayer[name] = { count = 1, windowStart = now }
        return true
    end

    entry.count = entry.count + 1

    return entry.count <= maxPerWindow
end

---------------------------------------------------------------------------
-- Отправка
---------------------------------------------------------------------------

local function WriteAndSend(name, target, ...)
    local def = WO.Net.Messages[name]

    if not def then
        WO.Error("WO.Net.Send: unregistered message '" .. tostring(name) .. "'")
        return
    end

    net.Start(name)

    if isfunction(def.write) then
        local ok, err = pcall(def.write, ...)

        if not ok then
            WO.Error("Net write failed for '" .. name .. "': " .. tostring(err))
            return
        end
    end

    if target == nil then
        net.SendToServer()
    elseif target == true then
        net.Broadcast()
    else
        net.Send(target)
    end
end

--[[
    Клиент → сервер.

    @param name string
    @param ... аргументы для def.write
]]
function WO.Net.SendToServer(name, ...)
    if SERVER then
        WO.Error("WO.Net.SendToServer called on server: " .. tostring(name))
        return
    end

    WriteAndSend(name, nil, ...)
end

--[[
    Сервер → один игрок.

    @param name string
    @param target Player
    @param ... аргументы для def.write
]]
function WO.Net.Send(name, target, ...)
    if CLIENT then
        WO.Error("WO.Net.Send called on client: " .. tostring(name))
        return
    end

    if not IsValid(target) then return end

    WriteAndSend(name, target, ...)
end

--[[
    Сервер → все игроки.

    @param name string
    @param ... аргументы для def.write
]]
function WO.Net.Broadcast(name, ...)
    if CLIENT then
        WO.Error("WO.Net.Broadcast called on client: " .. tostring(name))
        return
    end

    WriteAndSend(name, true, ...)
end
