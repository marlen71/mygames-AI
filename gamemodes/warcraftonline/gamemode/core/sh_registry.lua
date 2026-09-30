--[[
    Warcraft Online — фабрика реестров.
    Каждая data-driven система (предметы, расы, классы, квесты...) получает
    собственный реестр с проверкой дубликатов ID.

    Пример:
        WO.Items.Registry = WO.Registry.New("Items")
        WO.Items.Registry:Register("iron_sword", def)
]]

WO.Registry = WO.Registry or {}

local REGISTRY = {}
REGISTRY.__index = REGISTRY

--[[
    Создаёт новый реестр.

    @param name string отображаемое имя (для логов)
    @return table registry
]]
function WO.Registry.New(name)
    local reg = setmetatable({
        Name = name or "Registry",
        _data = {},
        _count = 0,
    }, REGISTRY)

    return reg
end

--[[
    Регистрирует объект по id.
    Дубликаты ID запрещены (ошибка в консоль, объект не перезаписывается).

    @param id string
    @param obj table
    @return boolean success
]]
function REGISTRY:Register(id, obj)
    if not isstring(id) or id == "" then
        WO.Error(self.Name .. ":Register — invalid id")
        return false
    end

    if not istable(obj) then
        WO.Error(self.Name .. ":Register — invalid object for id '" .. id .. "'")
        return false
    end

    if self._data[id] ~= nil then
        -- Hot-reload: разрешаем перезапись
        if WO.HotReload then
            obj.id = obj.id or id
            self._data[id] = obj
            return true
        end

        WO.Error(self.Name .. ":Register — duplicate id '" .. id .. "'")
        return false
    end

    obj.id = obj.id or id
    self._data[id] = obj
    self._count = self._count + 1

    return true
end

--- Перезаписывает объект (используется при hot-reload контента).
function REGISTRY:Overwrite(id, obj)
    if not isstring(id) or not istable(obj) then return false end

    if self._data[id] == nil then
        self._count = self._count + 1
    end

    obj.id = obj.id or id
    self._data[id] = obj

    return true
end

--- Получает объект по id.
function REGISTRY:Get(id)
    return self._data[id]
end

--- Проверяет существование id.
function REGISTRY:Exists(id)
    return self._data[id] ~= nil
end

--- Удаляет объект.
function REGISTRY:Remove(id)
    if self._data[id] ~= nil then
        self._data[id] = nil
        self._count = self._count - 1
    end
end

--- Все зарегистрированные объекты (таблица id → obj).
function REGISTRY:GetAll()
    return self._data
end

--- Количество объектов.
function REGISTRY:Count()
    return self._count
end

--- Массив всех id (отсортирован).
function REGISTRY:GetIDs()
    local out = {}

    for id in pairs(self._data) do
        out[#out + 1] = id
    end

    table.sort(out)

    return out
end
