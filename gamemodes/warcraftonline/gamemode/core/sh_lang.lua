--[[
    Warcraft Online — локализация.
    WO.Lang:Get("inventory.empty") → строка на текущем языке.

    Словари регистрируются файлами из localization/ (ru.lua, en.lua).
]]

WO.Lang = WO.Lang or {}

WO.Lang.Registered = WO.Lang.Registered or {}
WO.Lang.Current = WO.Lang.Current or "ru"

--[[
    Регистрирует словарь языка.

    @param code string "ru" | "en" | ...
    @param dictionary table ключ → строка
]]
function WO.Lang.Register(code, dictionary)
    if not isstring(code) or not istable(dictionary) then
        WO.Error("WO.Lang.Register: invalid arguments")
        return
    end

    WO.Lang.Registered[code] = WO.Lang.Registered[code] or {}

    for key, value in pairs(dictionary) do
        WO.Lang.Registered[code][key] = value
    end

    WO.Debug("Language registered:", code, "(" .. table.Count(dictionary) .. " keys)")
end

--- Устанавливает активный язык.
function WO.Lang.SetLanguage(code)
    if WO.Lang.Registered[code] then
        WO.Lang.Current = code
    else
        WO.Warn("WO.Lang.SetLanguage: unknown language '" .. tostring(code) .. "'")
    end
end

--[[
    Возвращает локализованную строку.

    @param key string ключ (например "character.create")
    @param ... аргументы string.format (опционально)
    @return string
]]
function WO.Lang:Get(key, ...)
    local dictionary = WO.Lang.Registered[WO.Lang.Current]
    local value = dictionary and dictionary[key]

    if value == nil then
        -- Фолбэк на английский
        local en = WO.Lang.Registered["en"]
        value = en and en[key]
    end

    if value == nil then
        return key
    end

    if select("#", ...) > 0 then
        local ok, formatted = pcall(string.format, value, ...)

        if ok then
            return formatted
        end
    end

    return value
end
