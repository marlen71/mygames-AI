--[[
    Warcraft Online — внутренняя система хуков.
    Не используем глобальные GMod-хуки для игровых событий —
    у WO свои события, чтобы плагины не мешали друг другу.

    Пример:
        WO.Hook.Add("CharacterLoaded", "my_plugin", function(char) ... end)
        WO.Hook.Run("CharacterLoaded", char)
]]

WO.Hook = WO.Hook or {}

local hooks = {}

--[[
    Регистрирует обработчик внутреннего события.

    @param event string имя события (например "CharacterLoaded")
    @param id string уникальный id обработчика (обычно имя плагина)
    @param fn function
]]
function WO.Hook.Add(event, id, fn)
    if not isstring(event) or not isstring(id) or not isfunction(fn) then
        WO.Error("WO.Hook.Add: invalid arguments", event, id)
        return
    end

    hooks[event] = hooks[event] or {}
    hooks[event][id] = fn
end

--- Удаляет обработчик.
function WO.Hook.Remove(event, id)
    if hooks[event] then
        hooks[event][id] = nil
    end
end

--[[
    Запускает событие. Ошибки в обработчиках не роняют остальные.

    @param event string
    @param ... любые аргументы
    @return table массив результатов обработчиков
]]
function WO.Hook.Run(event, ...)
    local list = hooks[event]
    if not list then return {} end

    local results = {}

    for id, fn in pairs(list) do
        local ok, a, b, c = pcall(fn, ...)

        if not ok then
            WO.Error("Hook '" .. tostring(event) .. "' handler '" .. tostring(id) .. "' failed: " .. tostring(a))
        else
            if a ~= nil then
                results[#results + 1] = a
            end

            if b ~= nil then
                results[#results + 1] = b
            end

            if c ~= nil then
                results[#results + 1] = c
            end
        end
    end

    return results
end

--- Проверяет, есть ли обработчики события.
function WO.Hook.Has(event)
    return hooks[event] ~= nil and next(hooks[event]) ~= nil
end
