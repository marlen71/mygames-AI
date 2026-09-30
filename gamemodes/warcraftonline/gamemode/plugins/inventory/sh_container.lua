--[[
    Warcraft Online — универсальный контейнер (shared).
    Grid-контейнер: инвентарь, банк, сундук, лут-мешок, виртуальный контейнер
    торговца — всё это контейнеры с единым API.

        local container = WO.Container.New("inventory", 10, 6)
        container:AddItem(instance)            -- авто-размещение
        container:AddItem(instance, x, y)      -- в позицию
        container:MoveItem(uid, x, y)
        container:RemoveItem(uid)
        container:HasSpace(instance)
        container:FindSpace(instance) → x, y

    Каждый предмет может занимать 1x1, 1x2, 2x2 и т.д. (def.size).
]]

WO.Container = WO.Container or {}

local CONTAINER = {}
CONTAINER.__index = CONTAINER

--[[
    Создаёт новый контейнер.

    @param id string идентификатор ("inventory", "bank", "chest:uuid"...)
    @param width number ширина в слотах
    @param height number высота в слотах
    @return table container
]]
function WO.Container.New(id, width, height)
    local container = setmetatable({
        id = id or "container",
        width = math.max(1, math.floor(tonumber(width) or 10)),
        height = math.max(1, math.floor(tonumber(height) or 6)),
        items = {},
        grid = {},
        count = 0,
    }, CONTAINER)

    return container
end

--- Является ли объект контейнером.
function WO.Container.IsContainer(obj)
    return istable(obj) and getmetatable(obj) == CONTAINER
end

---------------------------------------------------------------------------
-- Внутренняя работа с сеткой
---------------------------------------------------------------------------

local function ItemSize(instance)
    local def = WO.Items.Get(instance.class)

    if def and def.size then
        return def.size.w or 1, def.size.h or 1
    end

    return 1, 1
end

local function MarkGrid(self, instance)
    local w, h = ItemSize(instance)

    for dy = 0, h - 1 do
        for dx = 0, w - 1 do
            local gx = instance.x + dx
            local gy = instance.y + dy

            self.grid[gy] = self.grid[gy] or {}
            self.grid[gy][gx] = instance.uid
        end
    end
end

local function UnmarkGrid(self, instance)
    local w, h = ItemSize(instance)

    for dy = 0, h - 1 do
        for dx = 0, w - 1 do
            local gx = instance.x + dx
            local gy = instance.y + dy

            if self.grid[gy] then
                self.grid[gy][gx] = nil
            end
        end
    end
end

---------------------------------------------------------------------------
-- Размещение
---------------------------------------------------------------------------

--[[
    Помещается ли предмет в позицию (x, y).

    @param instance table
    @param x number
    @param y number
    @return boolean
]]
function CONTAINER:CanFit(instance, x, y)
    if not istable(instance) then return false end

    local w, h = ItemSize(instance)

    if x < 1 or y < 1 or x + w - 1 > self.width or y + h - 1 > self.height then
        return false
    end

    for dy = 0, h - 1 do
        for dx = 0, w - 1 do
            local gy = y + dy
            local gx = x + dx

            if self.grid[gy] and self.grid[gy][gx] then
                -- Занятая ячейка: разрешено, если это сам предмет (перемещение)
                if self.grid[gy][gx] ~= instance.uid then
                    return false
                end
            end
        end
    end

    return true
end

--[[
    Ищет свободное место для предмета.

    @param instance table
    @return number|nil x, number|nil y
]]
function CONTAINER:FindSpace(instance)
    if not istable(instance) then return nil end

    local w, h = ItemSize(instance)

    for y = 1, self.height - h + 1 do
        for x = 1, self.width - w + 1 do
            if self:CanFit(instance, x, y) then
                return x, y
            end
        end
    end

    return nil
end

--[[
    Есть ли место для предмета.
]]
function CONTAINER:HasSpace(instance)
    local x = self:FindSpace(instance)

    return x ~= nil
end

--[[
    Добавляет предмет в контейнер.

    @param instance table экземпляр предмета
    @param x number|nil позиция (или авто-размещение)
    @param y number|nil
    @return boolean success, string|nil reason
]]
function CONTAINER:AddItem(instance, x, y)
    if not istable(instance) or not isstring(instance.uid) then
        return false, "invalid_instance"
    end

    if self.items[instance.uid] then
        return false, "already_exists"
    end

    if x == nil or y == nil then
        local fx, fy = self:FindSpace(instance)

        if not fx then
            return false, "no_space"
        end

        x, y = fx, fy
    end

    if not self:CanFit(instance, x, y) then
        return false, "occupied"
    end

    instance.x = x
    instance.y = y

    self.items[instance.uid] = instance
    self.count = self.count + 1

    MarkGrid(self, instance)

    return true
end

--[[
    Удаляет предмет из контейнера (не уничтожая данные).

    @param uid string
    @return table|nil instance
]]
function CONTAINER:RemoveItem(uid)
    local instance = self.items[uid]

    if not instance then return nil end

    UnmarkGrid(self, instance)

    self.items[uid] = nil
    self.count = self.count - 1

    instance.x = nil
    instance.y = nil

    return instance
end

--[[
    Перемещает предмет внутри контейнера.

    @param uid string
    @param x number
    @param y number
    @return boolean success, string|nil reason
]]
function CONTAINER:MoveItem(uid, x, y)
    local instance = self.items[uid]

    if not instance then
        return false, "not_found"
    end

    x = math.floor(tonumber(x) or 0)
    y = math.floor(tonumber(y) or 0)

    if not self:CanFit(instance, x, y) then
        return false, "occupied"
    end

    UnmarkGrid(self, instance)

    instance.x = x
    instance.y = y

    MarkGrid(self, instance)

    return true
end

--- Получить экземпляр по uid.
function CONTAINER:GetItem(uid)
    return self.items[uid]
end

--- Получить предмет в ячейке сетки.
function CONTAINER:GetAt(x, y)
    if self.grid[y] then
        local uid = self.grid[y][x]

        if uid then
            return self.items[uid]
        end
    end

    return nil
end

---------------------------------------------------------------------------
-- Поиск / подсчёт
---------------------------------------------------------------------------

--[[
    Находит первый экземпляр предмета класса.

    @param class string
    @return table|nil instance
]]
function CONTAINER:FindItem(class)
    for _, instance in pairs(self.items) do
        if instance.class == class then
            return instance
        end
    end

    return nil
end

--[[
    Считает количество предметов класса (сумма стаков).

    @param class string
    @return number
]]
function CONTAINER:CountItem(class)
    local total = 0

    for _, instance in pairs(self.items) do
        if instance.class == class then
            total = total + (instance.amount or 1)
        end
    end

    return total
end

--- Возвращает true, если предмет есть в нужном количестве.
function CONTAINER:HasItem(class, amount)
    return self:CountItem(class) >= (amount or 1)
end

--- Все предметы (uid → instance).
function CONTAINER:GetItems()
    return self.items
end

--- Количество различных предметов.
function CONTAINER:ItemCount()
    return self.count
end

---------------------------------------------------------------------------
-- Стаки
---------------------------------------------------------------------------

--[[
    Ищет стак того же класса с местом.

    @param class string
    @param maxStack number
    @return table|nil instance
]]
function CONTAINER:FindStack(class, maxStack)
    for _, instance in pairs(self.items) do
        if instance.class == class and (instance.amount or 1) < maxStack then
            return instance
        end
    end

    return nil
end

--[[
    Объединяет стаки и сортирует предметы (по классу, потом редкости).
    Переразмещает все предметы — используйте после массовых операций.
]]
function CONTAINER:MergeStacks()
    -- Собираем всё в массив
    local list = {}

    for uid, instance in pairs(self.items) do
        list[#list + 1] = instance
    end

    -- Объединяем стаки
    local byClass = {}

    for _, instance in ipairs(list) do
        local def = WO.Items.Get(instance.class)

        if def and def.stackable then
            if byClass[instance.class] then
                local target = byClass[instance.class]

                target.amount = (target.amount or 1) + (instance.amount or 1)
                instance.amount = 0 -- удалим ниже
            else
                byClass[instance.class] = instance
            end
        end
    end

    -- Удаляем пустые стаки
    for i = #list, 1, -1 do
        if (list[i].amount or 1) <= 0 then
            self:RemoveItem(list[i].uid)
            table.remove(list, i)
        end
    end

    -- Ограничение maxStack: разбиваем переполненные
    local overflow = {}

    for _, instance in ipairs(list) do
        local def = WO.Items.Get(instance.class)

        if def and def.stackable and (instance.amount or 1) > def.maxStack then
            local extra = instance.amount - def.maxStack

            instance.amount = def.maxStack

            while extra > 0 do
                local part = WO.Items.CreateInstance(instance.class, math.min(extra, def.maxStack))

                if not part then break end

                overflow[#overflow + 1] = part
                extra = extra - part.amount
            end
        end
    end

    for _, instance in ipairs(overflow) do
        list[#list + 1] = instance
    end

    -- Сортировка: тип → редкость → имя
    table.sort(list, function(a, b)
        local defA = WO.Items.Get(a.class) or {}
        local defB = WO.Items.Get(b.class) or {}

        if defA.type ~= defB.type then
            return tostring(defA.type) < tostring(defB.type)
        end

        local orderA = WO.Config.RarityOrder and table.KeyFromValue(WO.Config.RarityOrder, defA.rarity) or 0
        local orderB = WO.Config.RarityOrder and table.KeyFromValue(WO.Config.RarityOrder, defB.rarity) or 0

        if orderA ~= orderB then
            return orderA < orderB
        end

        return tostring(defA.name) < tostring(defB.name)
    end)

    -- Полная перестройка сетки
    self.grid = {}
    self.items = {}
    self.count = 0

    for _, instance in ipairs(list) do
        instance.uid = instance.uid -- сохраняем uid

        local ok = self:AddItem(instance)

        if not ok then
            WO.Warn("Container:MergeStacks — item lost (no space): " .. tostring(instance.class))
        end
    end
end

---------------------------------------------------------------------------
-- Сериализация
---------------------------------------------------------------------------

--[[
    Сериализует контейнер для сохранения (только чистые данные).
]]
function CONTAINER:Serialize()
    local items = {}

    for _, instance in pairs(self.items) do
        items[#items + 1] = {
            uid = instance.uid,
            class = instance.class,
            amount = instance.amount or 1,
            durability = instance.durability,
            data = instance.data or {},
            x = instance.x,
            y = instance.y,
        }
    end

    return {
        id = self.id,
        width = self.width,
        height = self.height,
        items = items,
    }
end

--[[
    Десериализует контейнер из сохранённых данных.

    @param data table
    @return table|nil container
]]
function WO.Container.Deserialize(data)
    if not istable(data) then return nil end

    local container = WO.Container.New(data.id or "container", data.width, data.height)

    for _, itemData in ipairs(data.items or {}) do
        local instance = WO.Items.Deserialize(itemData)

        if instance then
            local ok, reason = container:AddItem(instance, itemData.x, itemData.y)

            if not ok then
                -- Позиция занята/невалидна — ищем свободное место
                ok = container:AddItem(instance)

                if not ok then
                    WO.Warn("Container deserialize: item skipped (" .. tostring(itemData.class) .. "): " .. tostring(reason))
                end
            end
        end
    end

    return container
end
