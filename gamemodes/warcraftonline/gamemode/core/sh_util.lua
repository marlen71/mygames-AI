--[[
    Warcraft Online — утилиты.
    UUID, санитизация строк, валидация, работа с таблицами.
]]

WO.Util = WO.Util or {}

---------------------------------------------------------------------------
-- UUID
---------------------------------------------------------------------------

local uuidCounter = 0

--[[
    Генерирует уникальный идентификатор (UUID-подобный).
    Используется для Character ID, Item UID и т.д.
    Никогда не используйте SteamID как UID предмета.

    @return string uuid
]]
function WO.Util.UUID()
    uuidCounter = uuidCounter + 1

    -- UUID is shared/server-authoritative; LocalPlayer() is client-only and
    -- must never be referenced here (character creation runs on the server).
    local seed = table.concat({
        tostring(SysTime()),
        tostring(RealTime()),
        tostring(math.random(0, 0x7FFFFFFF)),
        tostring(uuidCounter),
        tostring(game and game.GetMap and game.GetMap() or "unknown_map"),
        SERVER and "server" or "client",
    }, ":")

    local h1 = util.CRC(seed)
    local h2 = util.CRC(h1 .. seed .. "a")
    local h3 = util.CRC(h2 .. seed .. "b")
    local h4 = util.CRC(h3 .. seed .. "c")
    local h5 = util.CRC(h4 .. seed .. "d")

    return string.format(
        "%08x-%04x-%04x-%04x-%012x",
        tonumber(h1, 16) or 0,
        (tonumber(h2, 16) or 0) % 0xFFFF,
        bit.bor(0x4000, (tonumber(h3, 16) or 0) % 0x0FFF), -- версия 4
        bit.bor(0x8000, (tonumber(h4, 16) or 0) % 0x3FFF), -- вариант RFC4122
        (tonumber(h5, 16) or 0) % 0xFFFFFFFFFF
    )
end

--- Проверяет, что строка похожа на UUID.
function WO.Util.IsUUID(str)
    return isstring(str) and string.match(str, "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") ~= nil
end

---------------------------------------------------------------------------
-- Строки / санитизация
---------------------------------------------------------------------------

--- Удаляет HTML/Lua-опасные символы и управляющие символы.
function WO.Util.StripDangerous(str)
    if not isstring(str) then return "" end

    str = string.gsub(str, "[%c%z]", "")
    str = string.gsub(str, "[<>\"`\\]", "")
    str = string.gsub(str, "%%", "")

    return str
end

--- Схлопывает повторяющиеся пробелы, обрезает края.
function WO.Util.CleanString(str)
    if not isstring(str) then return "" end

    str = string.gsub(str, "%s+", " ")

    return string.Trim(str)
end

--- Считает количество символов UTF-8 (не байт).
function WO.Util.UTF8Length(str)
    if not isstring(str) then return 0 end

    local ok, len = pcall(utf8.len, str)

    if ok and isnumber(len) then
        return len
    end

    -- Некорректный UTF-8 — считаем байты (заведомо больше символов)
    return #str
end

--- Проверяет допустимость имени/фамилии (латиница + кириллица, пробел, дефис, апостроф).
function WO.Util.IsValidName(str)
    if not isstring(str) or str == "" then return false end

    local minLen = (WO.Config and WO.Config.NameMinLength) or 2
    local maxLen = (WO.Config and WO.Config.NameMaxLength) or 24

    local len = WO.Util.UTF8Length(str)
    if len < minLen or len > maxLen then return false end

    -- Проверяем посимвольно через utf8.codes (корректно для кириллицы)
    local ok, valid = pcall(function()
        for _, code in utf8.codes(str) do
            local isLatin = (code >= 65 and code <= 90) or (code >= 97 and code <= 122)
            local isCyr = (code >= 0x0410 and code <= 0x044F) or code == 0x0401 or code == 0x0451
            local isSpace = code == 32
            local isHyphen = code == 45
            local isApostrophe = code == 39

            if not (isLatin or isCyr or isSpace or isHyphen or isApostrophe) then
                return false
            end
        end

        return true
    end)

    return ok and valid == true
end

---------------------------------------------------------------------------
-- Таблицы
---------------------------------------------------------------------------

--- Глубокая копия таблицы.
function WO.Util.CopyTable(tbl)
    if type(tbl) ~= "table" then return tbl end

    local out = {}

    for k, v in pairs(tbl) do
        out[k] = type(v) == "table" and WO.Util.CopyTable(v) or v
    end

    return out
end

--- Слияние таблиц (source поверх target, рекурсивно).
function WO.Util.MergeTable(target, source)
    for k, v in pairs(source or {}) do
        if type(v) == "table" and type(target[k]) == "table" then
            WO.Util.MergeTable(target[k], v)
        else
            target[k] = type(v) == "table" and WO.Util.CopyTable(v) or v
        end
    end

    return target
end

--- Число с ограничением диапазона.
function WO.Util.ClampNumber(value, min, max)
    value = tonumber(value) or min

    return math.Clamp(value, min, max)
end

--- Безопасное преображение в целое.
function WO.Util.ToInt(value, default)
    local n = tonumber(value)

    if n == nil then return default or 0 end

    return math.floor(n)
end

---------------------------------------------------------------------------
-- Позиции / Angle ↔ таблицы (для сериализации)
---------------------------------------------------------------------------

--- Vector → {x,y,z}
function WO.Util.VectorToTable(vec)
    return { x = vec.x, y = vec.y, z = vec.z }
end

--- {x,y,z} → Vector
function WO.Util.TableToVector(tbl)
    if not istable(tbl) then return vector_origin end

    return Vector(tonumber(tbl.x) or 0, tonumber(tbl.y) or 0, tonumber(tbl.z) or 0)
end

--- Angle → {p,y,r}
function WO.Util.AngleToTable(ang)
    return { p = ang.p, y = ang.y, r = ang.r }
end

--- {p,y,r} → Angle
function WO.Util.TableToAngle(tbl)
    if not istable(tbl) then return angle_zero end

    return Angle(tonumber(tbl.p) or 0, tonumber(tbl.y) or 0, tonumber(tbl.r) or 0)
end

---------------------------------------------------------------------------
-- Время
---------------------------------------------------------------------------

--- Unix-время (UTC).
function WO.Util.Time()
    return os.time()
end

--- Форматированное локальное время для логов.
function WO.Util.TimeString()
    return os.date("%Y-%m-%d %H:%M:%S")
end
