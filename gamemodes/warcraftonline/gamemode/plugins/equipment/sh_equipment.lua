--[[
    Warcraft Online — система экипировки (shared).

    Персонаж ссылается на equipment-объект:
        char.equipment.slots = { head = instance, chest = instance, ... }

    Слоты расширяются через WO.Config.EquipSlots.
]]

WO.Equipment.Slots = WO.Equipment.Slots or {}

-- Список слотов из конфига (id → nameKey)
local function GetSlotIds()
    local out = {}

    for _, slot in ipairs(WO.Config.EquipSlots or {}) do
        out[#out + 1] = slot.id
    end

    return out
end

---------------------------------------------------------------------------
-- Equipment object
---------------------------------------------------------------------------

local EQUIPMENT = {}
EQUIPMENT.__index = EQUIPMENT

WO.Equipment.Meta = EQUIPMENT

--[[
    Создаёт equipment-объект.
]]
function WO.Equipment.New()
    return setmetatable({
        slots = {},
        startingEquipmentApplied = false,
        starterKnifeMigrationApplied = false,
    }, EQUIPMENT)
end

function WO.Equipment.IsEquipment(obj)
    return istable(obj) and getmetatable(obj) == EQUIPMENT
end

--- Возвращает предмет в слоте.
function EQUIPMENT:Get(slotId)
    return self.slots[slotId]
end

--- Устанавливает предмет в слот (или очищает).
function EQUIPMENT:Set(slotId, instance)
    self.slots[slotId] = instance
end

--- Проверяет, существует ли слот.
function EQUIPMENT:HasSlot(slotId)
    for _, id in ipairs(GetSlotIds()) do
        if id == slotId then
            return true
        end
    end

    return false
end

--[[
    Собирает бонусы статов всех экипированных предметов.

    @return table { ["equipment:uid"] = { stat = value, ... }, ... }
]]
function EQUIPMENT:GetStats()
    local out = {}

    for slotId, instance in pairs(self.slots) do
        if istable(instance) then
            local def = WO.Items.Get(instance.class)

            if def and istable(def.stats) then
                out["equipment:" .. instance.uid] = WO.Util.CopyTable(def.stats)
            end
        end
    end

    return out
end

---------------------------------------------------------------------------
-- Сериализация
---------------------------------------------------------------------------

--- Сериализует экипировку (слот → item instance data).
function EQUIPMENT:Serialize()
    local out = {
        __startingEquipmentApplied = self.startingEquipmentApplied == true,
        __starterKnifeMigrationApplied = self.starterKnifeMigrationApplied == true,
    }

    for slotId, instance in pairs(self.slots) do
        out[slotId] = WO.Items.Serialize(instance)
    end

    return out
end

--[[
    Десериализует экипировку.
]]
function WO.Equipment.Deserialize(data)
    local equipment = WO.Equipment.New()

    if not istable(data) then return equipment end

    equipment.startingEquipmentApplied = data.__startingEquipmentApplied == true
    equipment.starterKnifeMigrationApplied = data.__starterKnifeMigrationApplied == true

    for slotId, itemData in pairs(data) do
        if equipment:HasSlot(slotId) then
            local instance = WO.Items.Deserialize(itemData)

            if instance then
                instance.state = WO.Items.State.EQUIPPED
                equipment:Set(slotId, instance)
            end
        end
    end

    return equipment
end

---------------------------------------------------------------------------
-- Вспомогательные проверки
---------------------------------------------------------------------------

--[[
    Подходит ли предмет для слота.
]]
function WO.Equipment.ItemFitsSlot(instance, slotId)
    local def = instance and WO.Items.Get(instance.class)

    if not def or not def.equipment then return false end

    -- Оружие/щит: main_hand / off_hand
    if def.equipment.slot == slotId then
        return true
    end

    -- Кольца: ring_1 / ring_2
    if def.equipment.slot == "ring" and (slotId == "ring_1" or slotId == "ring_2") then
        return true
    end

    return false
end

--- Класс предмета (для проверки допуска классом).
function WO.Equipment.ItemCategory(def)
    return def.category or def.type or "misc"
end
