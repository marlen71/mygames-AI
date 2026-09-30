--[[
    Warcraft Online — система предметов (shared).

    ОБЯЗАТЕЛЬНЫЙ ПРИНЦИП: Item Definition vs Item Instance.

    ITEM DEFINITION (schemas/items/iron_sword.lua):
        iron_sword — name, model, damage, description, weight, icon...
        Хранится один раз в реестре.

    ITEM INSTANCE (конкретный меч):
        { uid = "uuid", class = "iron_sword", amount = 1, durability = 87, data = {} }
        Iron Sword #1 (100/100) и Iron Sword #2 (54/54) — при ОДНОЙ definition.

    СОХРАНЯЕТСЯ только instance (class + instance data).
    Описание и характеристики берутся из definition при загрузке.
]]

WO.Items.Registry = WO.Items.Registry or WO.Registry.New("Items")

-- Состояния предмета (см. sh_enums.lua)
WO.Items.State = WO.Enums.ItemState

-- Разрешённые переходы состояний (анти-дюп)
local transitions = {
    inventory = { equipped = true, world = true, container = true, destroyed = true },
    equipped = { inventory = true, world = true, destroyed = true },
    world = { inventory = true, container = true, destroyed = true },
    container = { inventory = true, world = true, destroyed = true },
    destroyed = {},
}

--[[
    Регистрирует определение предмета (item definition).

    @param def table { id, name, type, category, model, icon, weight, size,
                       stackable, maxStack, rarity, description, durability,
                       weapon, equipment, stats, requirements, consumable, price }
    @return boolean success
]]
function WO.Items.Register(def)
    if not istable(def) or not isstring(def.id) then
        WO.Error("WO.Items.Register: invalid item definition")
        return false
    end

    def.name = def.name or def.id
    def.type = def.type or "misc"
    def.rarity = def.rarity or "common"
    def.weight = tonumber(def.weight) or 0
    def.size = def.size or { w = 1, h = 1 }
    def.size.w = math.max(1, math.floor(def.size.w or 1))
    def.size.h = math.max(1, math.floor(def.size.h or 1))

    if def.stackable then
        def.maxStack = math.max(1, math.floor(def.maxStack or 99))
    else
        def.maxStack = 1
        def.stackable = false
    end

    return WO.Items.Registry:Register(def.id, def)
end

--- Получить определение предмета по class id.
function WO.Items.Get(id)
    return WO.Items.Registry:Get(id)
end

--- Все определения.
function WO.Items.GetAll()
    return WO.Items.Registry:GetAll()
end

---------------------------------------------------------------------------
-- Item Instances
---------------------------------------------------------------------------

--[[
    Создаёт новый экземпляр предмета.

    @param class string id определения
    @param amount number|nil количество (для стаков)
    @param data table|nil дополнительные данные (customData)
    @return table|nil instance
]]
function WO.Items.CreateInstance(class, amount, data)
    local def = WO.Items.Get(class)

    if not def then
        WO.Error("WO.Items.CreateInstance: unknown item class '" .. tostring(class) .. "'")
        return nil
    end

    amount = math.max(1, math.floor(tonumber(amount) or 1))

    if not def.stackable then
        amount = 1
    end

    local instance = {
        uid = WO.Util.UUID(),
        class = class,
        amount = math.min(amount, def.maxStack),
        durability = def.durability,
        data = istable(data) and data or {},
        state = WO.Items.State.INVENTORY,
    }

    return instance
end

---------------------------------------------------------------------------
-- Сериализация (только чистые данные!)
---------------------------------------------------------------------------

--[[
    Сериализует экземпляр для сохранения (никаких userdata/entity).

    @param instance table
    @return table
]]
function WO.Items.Serialize(instance)
    if not istable(instance) then return nil end

    return {
        uid = instance.uid,
        class = instance.class,
        amount = instance.amount or 1,
        durability = instance.durability,
        data = instance.data or {},
    }
end

--[[
    Десериализует экземпляр из сохранённых данных.
    Повреждённые данные не роняют сервер.

    @param data table
    @return table|nil instance
]]
function WO.Items.Deserialize(data)
    if not istable(data) then return nil end

    local def = WO.Items.Get(data.class)

    if not def then
        WO.Warn("WO.Items.Deserialize: unknown item class '" .. tostring(data.class) .. "', skipping")
        return nil
    end

    if not isstring(data.uid) or data.uid == "" then
        WO.Warn("WO.Items.Deserialize: item without uid, generating new")
        data.uid = WO.Util.UUID()
    end

    local instance = {
        uid = data.uid,
        class = data.class,
        amount = math.Clamp(WO.Util.ToInt(data.amount, 1), 1, def.maxStack),
        data = istable(data.data) and data.data or {},
        state = WO.Items.State.INVENTORY,
    }

    -- Прочность: только если определение её поддерживает
    if def.durability then
        instance.durability = math.Clamp(tonumber(data.durability) or def.durability, 0, def.durability)
    end

    return instance
end

---------------------------------------------------------------------------
-- Машина состояний (анти-дюп)
---------------------------------------------------------------------------

--[[
    Можно ли перевести предмет из одного состояния в другое.
    INVENTORY + WORLD одновременно существовать НЕ МОГУТ.

    @param from string
    @param to string
    @return boolean
]]
function WO.Items.CanTransition(from, to)
    local allowed = transitions[from]

    return allowed ~= nil and allowed[to] == true
end

--[[
    Переводит экземпляр в новое состояние (с проверкой перехода).
    Вызывается ТОЛЬКО сервером, внутри транзакций операций.

    @param instance table
    @param to string новое состояние
    @return boolean success
]]
function WO.Items.SetState(instance, to)
    if not istable(instance) then return false end

    local from = instance.state or WO.Items.State.INVENTORY

    -- Повторная установка того же состояния — no-op (идемпотентность)
    if from == to then
        return true
    end

    if not WO.Items.CanTransition(from, to) then
        WO.Error("WO.Items.SetState: illegal transition " .. tostring(from) .. " -> " .. tostring(to) ..
            " for item " .. tostring(instance.uid))
        return false
    end

    instance.state = to

    WO.Debug("Item " .. tostring(instance.uid) .. " (" .. tostring(instance.class) .. "): " .. from .. " -> " .. to)

    return true
end

---------------------------------------------------------------------------
-- Требования (Requirements)
---------------------------------------------------------------------------

WO.Requirements = WO.Requirements or {}

--[[
    Проверяет требования предмета/способности для игрока.

    @param ply Player
    @param requirements table { level, class, race, stats = { strength = 10 } }
    @return boolean success, string|nil reason
]]
function WO.Requirements.Check(ply, requirements)
    if not IsValid(ply) then return false, "invalid_player" end
    if not istable(requirements) then return true end

    local char = ply:GetCharacter()

    if not char then return false, "no_character" end

    -- Уровень
    if requirements.level and char:GetLevel() < requirements.level then
        return false, "level"
    end

    -- Класс
    if requirements.class then
        local allowed = false

        for _, classId in ipairs(istable(requirements.class) and requirements.class or { requirements.class }) do
            if char.class == classId then
                allowed = true
                break
            end
        end

        if not allowed then
            return false, "class"
        end
    end

    -- Раса
    if requirements.race then
        local allowed = false

        for _, raceId in ipairs(istable(requirements.race) and requirements.race or { requirements.race }) do
            if char.race == raceId then
                allowed = true
                break
            end
        end

        if not allowed then
            return false, "race"
        end
    end

    -- Характеристики
    if istable(requirements.stats) then
        for stat, needed in pairs(requirements.stats) do
            local value = ply:GetStat(stat)

            if value < needed then
                return false, "stat:" .. stat
            end
        end
    end

    return true
end

---------------------------------------------------------------------------
-- Использование предмета (consumable)
---------------------------------------------------------------------------

--[[
    Может ли игрок использовать предмет (проверка требований и состояния).
]]
function WO.Items.CanUse(ply, instance)
    if not IsValid(ply) or not istable(instance) then return false, "invalid" end

    local def = WO.Items.Get(instance.class)

    if not def then return false, "unknown_class" end

    if instance.durability ~= nil and instance.durability <= 0 and def.durability then
        return false, "broken"
    end

    return WO.Requirements.Check(ply, def.requirements)
end

--[[
    Использует предмет (consumable: еда, зелья).
    Серверная логика — эффект применяется на сервере.

    @param ply Player
    @param instance table
    @return boolean success, string|nil reason
]]
function WO.Items.Use(ply, instance)
    local canUse, reason = WO.Items.CanUse(ply, instance)

    if not canUse then
        return false, reason
    end

    local def = WO.Items.Get(instance.class)

    if not def.consumable then
        return false, "not_consumable"
    end

    local effect = def.consumable

    -- Лечение
    if effect.heal then
        ply:SetHealth(math.min(ply:GetMaxHealth(), ply:Health() + effect.heal))
    end

    -- Мана
    if effect.mana then
        local maxMana = ply:GetNW2Int("wo_maxmana", 0)

        ply:SetNW2Int("wo_mana", math.min(maxMana, ply:GetMana() + effect.mana))
    end

    -- Выносливость
    if effect.stamina then
        local maxStamina = ply:GetNW2Int("wo_maxstamina", 0)

        ply:SetNW2Int("wo_stamina", math.min(maxStamina, ply:GetStamina() + effect.stamina))
    end

    -- Произвольный эффект (расширение)
    if isfunction(effect.onUse) then
        local ok, err = pcall(effect.onUse, ply, instance, def)

        if not ok then
            WO.Error("Item onUse failed (" .. instance.class .. "): " .. tostring(err))
        end
    end

    WO.Hook.Run("ItemUsed", ply, instance, def)

    return true
end

---------------------------------------------------------------------------
-- Стартовые предметы класса
---------------------------------------------------------------------------

--[[
    Выдаёт стартовые предметы класса в инвентарь персонажа (server).
    Вызывается ОДИН раз при создании персонажа (CharacterCreate).
    Работает с контейнером напрямую (без Player).
]]
function WO.Items.GiveStartingItems(char)
    if not WO.Character.IsCharacter(char) then return end

    local items = WO.Classes.GetStartingItems(char.class)

    if #items == 0 then return end

    local container = WO.Inventory.GetContainer(char)

    if not container then return end

    for _, entry in ipairs(items) do
        local def = WO.Items.Get(entry.class)

        if def then
            local remaining = math.max(1, entry.amount or 1)

            while remaining > 0 do
                local toGive = def.stackable and math.min(remaining, def.maxStack) or 1
                local instance = WO.Items.CreateInstance(entry.class, toGive)

                if not instance then break end

                WO.Items.SetState(instance, WO.Items.State.INVENTORY)

                -- Стекуем, если возможно
                local stacked = false

                if def.stackable then
                    local stack = container:FindStack(def.id, def.maxStack)

                    if stack then
                        stack.amount = (stack.amount or 1) + toGive
                        stacked = true
                    end
                end

                if not stacked then
                    local ok = container:AddItem(instance)

                    if not ok then
                        WO.Warn("Starting item skipped (no space): " .. entry.class)
                        break
                    end
                end

                remaining = remaining - toGive
            end

            WO.Debug("Starting item given: " .. entry.class .. " x" .. (entry.amount or 1))
        else
            WO.Warn("Starting item unknown: " .. tostring(entry.class))
        end
    end
end

-- Выдача стартовых предметов при создании персонажа
WO.Hook.Add("CharacterCreate", "items", function(char)
    WO.Items.GiveStartingItems(char)
end)
