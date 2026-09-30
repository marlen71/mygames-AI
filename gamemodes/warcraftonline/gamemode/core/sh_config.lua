--[[
    Warcraft Online — загрузчик конфигурации.
    Сами значения лежат в config/*.lua; здесь — общий каркас.

    Пример в config/sh_config.lua:
        WO.Config.MaxCharacters = 5
]]

WO.Config = WO.Config or {}

--[[
    Возвращает значение конфига с фолбэком.

    @param key string
    @param default any
    @return any
]]
function WO.Config.Get(key, default)
    local value = WO.Config[key]

    if value == nil then
        return default
    end

    return value
end

-- Метаданные-заглушки по умолчанию (переопределяются config/).
WO.Config.Debug = WO.Config.Debug ~= false
WO.Config.DebugTracebackOnError = WO.Config.DebugTracebackOnError or false
