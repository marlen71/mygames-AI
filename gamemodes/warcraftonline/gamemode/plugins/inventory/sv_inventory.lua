--[[
    Warcraft Online — инвентарь (server).
    ВСЕ операции с предметами выполняются здесь и только на сервере.
    Клиент отправляет запрос; сервер проверяет владение, место, кулдауны.

    Транзакционный подход (анти-дюп):
        1. заблокировать item (locked);
        2. проверить;
        3. выполнить операцию;
        4. при неудаче — откатить;
        5. разблокировать.
]]

---------------------------------------------------------------------------
-- Контейнер персонажа
---------------------------------------------------------------------------

--[[
    Возвращает инвентарь-контейнер персонажа (создаёт при необходимости).
]]
function WO.Inventory.GetContainer(char)
    if not WO.Character.IsCharacter(char) then return nil end

    local width = math.max(1, math.floor(tonumber(WO.Config.InventoryWidth) or 10))
    local height = math.max(1, math.floor(tonumber(WO.Config.InventoryHeight) or 6))

    if not WO.Container.IsContainer(char.inventory) then
        char.inventory = WO.Container.New("inventory", width, height)
    elseif char.inventory.width ~= width or char.inventory.height ~= height then
        -- Migrate legacy saved dimensions without dropping items. RebuildGrid
        -- packs in-bounds entries into the fixed 10x6 inventory; overflow stays
        -- in the item table for recovery rather than being silently destroyed.
        char.inventory.width = width
        char.inventory.height = height
        char.inventory:RebuildGrid()
    end

    return char.inventory
end

---------------------------------------------------------------------------
-- Синхронизация клиенту
---------------------------------------------------------------------------

local function SerializeItem(instance)
    return {
        uid = instance.uid,
        class = instance.class,
        amount = instance.amount or 1,
        durability = instance.durability,
        data = instance.data or {},
        x = instance.x,
        y = instance.y,
    }
end

--[[
    Отправляет клиенту полное состояние инвентаря.
]]
function WO.Inventory.Sync(ply)
    if not IsValid(ply) then return end

    local char = ply:GetCharacter()

    if not char then return end

    local container = WO.Inventory.GetContainer(char)

    if not container then return end

    -- Re-pack preserved overflow into any slots freed since the previous sync.
    container:RebuildGrid()
    local items = {}

    for _, instance in pairs(container:GetItems()) do
        items[#items + 1] = SerializeItem(instance)
    end

    WO.Net.Send("Inventory.Sync", ply, {
        width = container.width,
        height = container.height,
        items = items,
    })
end

--[[
    Отправляет дельту (одно изменение) — не весь инвентарь.

    @param ply Player
    @param action string "add" | "remove" | "update" | "move"
    @param instance table|nil
    @param extra table|nil { x, y }
]]
function WO.Inventory.SendDelta(ply, action, instance, extra)
    if not IsValid(ply) then return end

    WO.Net.Send("Inventory.Delta", ply, {
        action = action,
        item = instance and SerializeItem(instance) or nil,
        x = extra and extra.x or nil,
        y = extra and extra.y or nil,
    })
end

local function MarkDirty(char)
    if WO.SaveQueue then
        WO.SaveQueue.MarkDirty(char)
    end

    WO.Hook.Run("InventoryChanged", char)
end

---------------------------------------------------------------------------
-- Выдача предметов
---------------------------------------------------------------------------

--[[
    Выдаёт предмет персонажу (с поддержкой стаков и разбиения на несколько стаков).

    @param ply Player
    @param class string класс предмета (item definition id)
    @param amount number|nil количество
    @return boolean success, string|nil reason
]]
function WO.Inventory.GiveItem(ply, class, amount, customData)
    if not IsValid(ply) then return false, "invalid_player" end

    local char = ply:GetCharacter()

    if not char then return false, "no_character" end

    local def = WO.Items.Get(class)

    if not def then return false, "unknown_class" end
    if not WO.Items.IsInventoryAllowed(def) then return false, "not_inventory_item" end

    amount = math.max(1, math.floor(tonumber(amount) or 1))

    local container = WO.Inventory.GetContainer(char)

    if not container then return false, "no_container" end

    if def.uniquePerCharacter == true then
        if amount ~= 1 or container:CountItem(class) > 0 then
            return false, "already_owned"
        end
    end

    -- Защита от спама выдачей: ограничение суммарного количества за раз
    if amount > 1000 then
        WO.Warn("Suspicious GiveItem amount from " .. ply:Nick() .. ": " .. amount)
        return false, "invalid_amount"
    end

    local remaining = amount
    local given = 0

    while remaining > 0 do
        local toGive = def.stackable and math.min(remaining, def.maxStack) or 1
        local stacked = false

        -- Стекуем в существующий стак, если возможно
        if def.stackable then
            local stack = container:FindStack(class, def.maxStack)

            if stack then
                local free = def.maxStack - (stack.amount or 1)
                local add = math.min(free, toGive)

                if add > 0 then
                    stack.amount = (stack.amount or 1) + add
                    remaining = remaining - add
                    given = given + add

                    WO.Inventory.SendDelta(ply, "update", stack)
                    stacked = true
                end
            end
        end

        if not stacked then
            local instance = WO.Items.CreateInstance(class, toGive, customData)

            if not instance then
                return false, "create_failed"
            end

            WO.Items.SetState(instance, WO.Items.State.INVENTORY)

            local ok, reason = container:AddItem(instance)

            if not ok then
                if given > 0 then
                    break -- частично выдано
                end

                return false, reason or "no_space"
            end

            remaining = remaining - toGive
            given = given + toGive

            WO.Inventory.SendDelta(ply, "add", instance)

            WO.Hook.Run("ItemAdded", char, instance, toGive)
        end
    end

    if given > 0 then
        MarkDirty(char)

        local itemDef = WO.Items.Get(class)

        WO.Notify(ply, "item", string.format(WO.Lang:Get("inventory.item_received"), (itemDef and itemDef.name) or class))

        return true
    end

    return false, "no_space"
end

---------------------------------------------------------------------------
-- Удаление предметов
---------------------------------------------------------------------------

--[[
    Удаляет предмет (или часть стака) из инвентаря.

    @param ply Player
    @param uid string
    @param amount number|nil количество (по умолчанию всё)
    @return boolean success, string|nil reason
]]
function WO.Inventory.RemoveItem(ply, uid, amount)
    if not IsValid(ply) then return false, "invalid_player" end

    local char = ply:GetCharacter()

    if not char then return false, "no_character" end

    local container = WO.Inventory.GetContainer(char)
    local instance = container and container:GetItem(uid)

    if not instance then return false, "not_found" end

    if instance.locked then return false, "locked" end

    instance.locked = true

    local total = instance.amount or 1
    amount = math.floor(tonumber(amount) or total)
    amount = math.Clamp(amount, 1, total)

    if amount < total then
        -- Частичное удаление (уменьшаем стак)
        instance.amount = total - amount
        instance.locked = nil

        WO.Inventory.SendDelta(ply, "update", instance)
        MarkDirty(char)

        return true
    end

    -- Полное удаление
    local hadOverflow = container:CountUnplacedItems() > 0
    container:RemoveItem(uid)

    instance.locked = nil

    WO.Items.SetState(instance, WO.Items.State.DESTROYED)

    WO.Inventory.SendDelta(ply, "remove", instance)
    MarkDirty(char)

    if hadOverflow then WO.Inventory.Sync(ply) end

    WO.Hook.Run("ItemRemoved", char, instance)

    return true
end

---------------------------------------------------------------------------
-- Перемещение (drag & drop)
---------------------------------------------------------------------------

--[[
    Перемещает предмет в инвентаре. Проверяет владение и место.
    НИКОГДА не доверяем позиции от клиента без проверки.

    @param ply Player
    @param uid string
    @param x number
    @param y number
    @return boolean success, string|nil reason
]]
function WO.Inventory.MoveItem(ply, uid, x, y)
    if not IsValid(ply) then return false, "invalid_player" end

    local char = ply:GetCharacter()

    if not char then return false, "no_character" end

    -- Валидация координат
    x = math.floor(tonumber(x) or -1)
    y = math.floor(tonumber(y) or -1)

    if x < 1 or y < 1 or x > 255 or y > 255 then
        return false, "invalid_position"
    end

    local container = WO.Inventory.GetContainer(char)
    local instance = container and container:GetItem(uid)

    if not instance then return false, "not_found" end

    if instance.locked then return false, "locked" end

    if instance.x == x and instance.y == y then
        return true -- уже там
    end

    instance.locked = true

    local ok, reason = container:MoveItem(uid, x, y)

    instance.locked = nil

    if not ok then
        return false, reason
    end

    WO.Inventory.SendDelta(ply, "move", instance, { x = x, y = y })
    MarkDirty(char)

    return true
end

---------------------------------------------------------------------------
-- Использование
---------------------------------------------------------------------------

--[[
    Использует предмет (зелье, еда) — сервер применяет эффект.
]]
function WO.Inventory.UseItem(ply, uid)
    if not IsValid(ply) then return false, "invalid_player" end

    local char = ply:GetCharacter()

    if not char then return false, "no_character" end

    local container = WO.Inventory.GetContainer(char)
    local instance = container and container:GetItem(uid)

    if not instance then return false, "not_found" end

    if instance.locked then return false, "locked" end

    local def = WO.Items.Get(instance.class)

    if not def then return false, "unknown_class" end
    if not WO.Items.IsInventoryAllowed(def) then return false, "not_inventory_item" end

    -- Оружие/броня экипируются, а не «используются».
    if def.equipment then
        return WO.Equipment.Equip(ply, uid)
    end

    -- Utility callbacks run on the server and can be persistent (mount stone)
    -- or explicitly consumable (feed/training kit). Client packets contain only UID.
    if isfunction(def.useHandler) then
        local canUse, requirement = WO.Items.CanUse(ply, instance)

        if not canUse then return false, requirement end

        instance.locked = true
        local called, result, reason = pcall(def.useHandler, ply, instance, def)
        instance.locked = nil

        if not called then
            WO.Error("Item useHandler failed (" .. instance.class .. "): " .. tostring(result))
            return false, "use_failed"
        end

        if result == false then
            return false, reason or "use_failed"
        end

        if def.consumeOnUse == true then
            if not WO.Inventory.RemoveItem(ply, uid, 1) then
                return false, "consume_failed"
            end
        else
            WO.Inventory.SendDelta(ply, "update", instance)
            MarkDirty(char)
        end

        return true
    end

    if not def.consumable then
        return false, "not_consumable"
    end

    instance.locked = true

    local ok, reason = WO.Items.Use(ply, instance)

    instance.locked = nil

    if not ok then
        return false, reason
    end

    -- Расходуем предмет
    local consumed = WO.Inventory.RemoveItem(ply, uid, 1)

    if not consumed then
        return false, "consume_failed"
    end

    return true
end

---------------------------------------------------------------------------
-- Разделение стака
---------------------------------------------------------------------------

--[[
    Разделяет стак на два.
]]
function WO.Inventory.SplitItem(ply, uid, amount)
    if not IsValid(ply) then return false, "invalid_player" end

    local char = ply:GetCharacter()

    if not char then return false, "no_character" end

    local container = WO.Inventory.GetContainer(char)
    local instance = container and container:GetItem(uid)

    if not instance then return false, "not_found" end

    if instance.locked then return false, "locked" end

    local total = instance.amount or 1

    amount = math.floor(tonumber(amount) or 0)

    if amount < 1 or amount >= total then
        return false, "invalid_amount"
    end

    local newInstance = WO.Items.CreateInstance(instance.class, amount)

    if not newInstance then
        return false, "create_failed"
    end

    if not container:HasSpace(newInstance) then
        return false, "no_space"
    end

    instance.locked = true

    instance.amount = total - amount

    WO.Items.SetState(newInstance, WO.Items.State.INVENTORY)

    local ok, reason = container:AddItem(newInstance)

    instance.locked = nil

    if not ok then
        instance.amount = total -- откат
        return false, reason
    end

    WO.Inventory.SendDelta(ply, "update", instance)
    WO.Inventory.SendDelta(ply, "add", newInstance)
    MarkDirty(char)

    return true
end

---------------------------------------------------------------------------
-- Сортировка
---------------------------------------------------------------------------

function WO.Inventory.Sort(ply)
    if not IsValid(ply) then return false, "invalid_player" end

    local char = ply:GetCharacter()

    if not char then return false, "no_character" end

    local container = WO.Inventory.GetContainer(char)

    if not container then return false, "no_container" end

    -- Сортировка только если ничего не заблокировано
    for _, instance in pairs(container:GetItems()) do
        if instance.locked then
            return false, "busy"
        end
    end

    container:MergeStacks()

    WO.Inventory.Sync(ply)
    MarkDirty(char)

    return true
end

---------------------------------------------------------------------------
-- Уничтожение
---------------------------------------------------------------------------

function WO.Inventory.DestroyItem(ply, uid)
    if not IsValid(ply) then return false, "invalid_player" end

    local char = ply:GetCharacter()

    if not char then return false, "no_character" end

    local container = WO.Inventory.GetContainer(char)
    local instance = container and container:GetItem(uid)

    if not instance then return false, "not_found" end

    if instance.locked then return false, "locked" end

    -- Квестовые предметы нельзя уничтожать
    local def = WO.Items.Get(instance.class)

    if def and (def.type == "quest" or def.rarity == "quest") then
        return false, "quest_item"
    end

    return WO.Inventory.RemoveItem(ply, uid)
end

---------------------------------------------------------------------------
-- Выброс предмета (транзакция: inventory → world)
---------------------------------------------------------------------------

--[[
    Выбрасывает предмет из инвентаря в мир (физический предмет).

    Транзакция:
        1. lock item;
        2. validate;
        3. remove from inventory (не уничтожая);
        4. создать entity (WO.World.DropItem);
        5. если создание провалилось — вернуть item в inventory (rollback);
        6. unlock.

    @param ply Player
    @param uid string
    @param amount number|nil
    @return boolean success, string|nil reason
]]
function WO.Inventory.DropItem(ply, uid, amount)
    if not IsValid(ply) then return false, "invalid_player" end

    local char = ply:GetCharacter()

    if not char then return false, "no_character" end

    local container = WO.Inventory.GetContainer(char)
    local instance = container and container:GetItem(uid)

    if not instance then return false, "not_found" end

    if instance.locked then return false, "locked" end

    local itemDef = WO.Items.Get(instance.class)

    if itemDef and (itemDef.noDrop == true or itemDef.bound == true) then
        return false, "bound_item"
    end

    if not WO.World or not WO.World.DropItem then
        return false, "world_unavailable"
    end

    instance.locked = true

    local total = instance.amount or 1
    amount = math.floor(tonumber(amount) or total)
    amount = math.Clamp(amount, 1, total)

    local dropInstance = instance
    local hadOverflow = false

    -- Частичный выброс: отделяем стак
    if amount < total then
        dropInstance = WO.Items.CreateInstance(instance.class, amount)

        if not dropInstance then
            instance.locked = nil
            return false, "create_failed"
        end

        -- Сохраняем данные исходного стака
        dropInstance.data = WO.Util.CopyTable(instance.data or {})
        dropInstance.durability = instance.durability

        instance.amount = total - amount

        WO.Inventory.SendDelta(ply, "update", instance)
    else
        -- Полный выброс: убираем из контейнера
        hadOverflow = container:CountUnplacedItems() > 0
        container:RemoveItem(uid)

        WO.Inventory.SendDelta(ply, "remove", instance)
    end

    -- Создаём физический предмет в мире
    local ok, err = WO.World.DropItem(ply, dropInstance)

    if not ok then
        -- ОТКАТ: возвращаем предмет в инвентарь
        WO.Warn("DropItem failed, rolling back: " .. tostring(err))

        if amount < total then
            instance.amount = (instance.amount or 1) + amount
            instance.locked = nil

            WO.Inventory.SendDelta(ply, "update", instance)
        else
            WO.Items.SetState(dropInstance, WO.Items.State.WORLD) -- временное состояние для обратного перехода
            WO.Items.SetState(dropInstance, WO.Items.State.INVENTORY)

            local reAdd = container:AddItem(dropInstance)

            if not reAdd and hadOverflow then
                -- Full containers may have older items waiting outside the grid;
                -- rollback must preserve the dropped instance rather than lose it.
                reAdd = container:RestoreItem(dropInstance)
            end

            if not reAdd then
                -- Катастрофа: инвентарь изменился — логируем и сохраняем предмет в БД мира
                WO.Error("CRITICAL: rollback failed for item " .. tostring(dropInstance.uid))
            else
                WO.Inventory.SendDelta(ply, "add", dropInstance)
            end

            dropInstance.locked = nil
        end

        MarkDirty(char)
        if hadOverflow then WO.Inventory.Sync(ply) end

        return false, err or "drop_failed"
    end

    -- Переход состояния: INVENTORY → WORLD
    WO.Items.SetState(dropInstance, WO.Items.State.WORLD)

    dropInstance.locked = nil

    if amount < total then
        instance.locked = nil
    end

    MarkDirty(char)

    if hadOverflow then WO.Inventory.Sync(ply) end

    WO.Hook.Run("ItemDropped", char, dropInstance)

    return true
end

---------------------------------------------------------------------------
-- Передача предмета другому игроку
---------------------------------------------------------------------------

--[[
    Передаёт предмет другому игроку (дистанция проверяется сервером).
]]
function WO.Inventory.GiveToPlayer(ply, target, uid, amount)
    if not IsValid(ply) or not IsValid(target) then return false, "invalid_player" end

    if ply == target then return false, "same_player" end

    if not ply:HasCharacter() or not target:HasCharacter() then
        return false, "no_character"
    end

    -- Дистанция
    if ply:GetPos():Distance(target:GetPos()) > (WO.Config.InteractDistance or 100) * 1.5 then
        return false, "too_far"
    end

    local char = ply:GetCharacter()
    local container = WO.Inventory.GetContainer(char)
    local instance = container and container:GetItem(uid)

    if not instance then return false, "not_found" end

    if instance.locked then return false, "locked" end

    local def = WO.Items.Get(instance.class)

    if def and (def.type == "quest" or def.rarity == "quest") then
        return false, "quest_item"
    end

    local total = instance.amount or 1
    amount = math.Clamp(math.floor(tonumber(amount) or total), 1, total)

    -- Проверяем место у получателя
    local targetChar = target:GetCharacter()
    local targetContainer = WO.Inventory.GetContainer(targetChar)

    if not targetContainer then return false, "no_container" end

    instance.locked = true

    local transferInstance = instance
    local partial = amount < total

    if partial then
        transferInstance = WO.Items.CreateInstance(instance.class, amount)

        if not transferInstance then
            instance.locked = nil
            return false, "create_failed"
        end

        transferInstance.data = WO.Util.CopyTable(instance.data or {})
        transferInstance.durability = instance.durability
    end

    -- Пытаемся положить получателю
    local targetOk, targetReason

    if def and def.stackable then
        local stack = targetContainer:FindStack(def.id, def.maxStack)

        if stack then
            stack.amount = (stack.amount or 1) + (transferInstance.amount or 1)
            targetOk = true

            WO.Inventory.SendDelta(target, "update", stack)
        end
    end

    if not targetOk then
        targetOk, targetReason = targetContainer:AddItem(transferInstance)

        if targetOk then
            WO.Inventory.SendDelta(target, "add", transferInstance)
        end
    end

    if not targetOk then
        instance.locked = nil
        return false, targetReason or "no_space"
    end

    -- Убираем у отправителя
    local hadOverflow = not partial and container:CountUnplacedItems() > 0

    if partial then
        instance.amount = total - amount
        instance.locked = nil

        WO.Inventory.SendDelta(ply, "update", instance)
    else
        container:RemoveItem(uid)
        instance.locked = nil

        WO.Inventory.SendDelta(ply, "remove", instance)
    end

    WO.Items.SetState(transferInstance, WO.Items.State.INVENTORY)

    MarkDirty(char)
    MarkDirty(targetChar)

    if hadOverflow then WO.Inventory.Sync(ply) end

    WO.Notify(target, "item", string.format(WO.Lang:Get("inventory.item_received"), (def and def.name) or transferInstance.class))

    WO.Hook.Run("ItemTransferred", char, targetChar, transferInstance)

    return true
end

---------------------------------------------------------------------------
-- Сохранение / загрузка (через хуки персонажа)
---------------------------------------------------------------------------

WO.Hook.Add("CharacterCreate", "inventory", function(char)
    WO.Inventory.GetContainer(char)
end)

WO.Hook.Add("CharacterLoad", "inventory", function(char)
    local rows = WO.Database:Fetch(
        "SELECT * FROM wo_inventories WHERE owner_id = ? AND container = ?",
        char.id, "inventory"
    )

    if rows and rows[1] then
        local data = util.JSONToTable(rows[1].items or "")

        if istable(data) then
            -- Character inventories always load at the configured 10x6 size;
            -- persisted legacy width/height values are intentionally ignored.
            char.inventory = WO.Container.Deserialize({
                id = "inventory",
                width = WO.Config.InventoryWidth or 10,
                height = WO.Config.InventoryHeight or 6,
                items = data,
            }) or WO.Container.New("inventory", WO.Config.InventoryWidth or 10, WO.Config.InventoryHeight or 6)
        else
            char.inventory = WO.Container.New("inventory", WO.Config.InventoryWidth or 10, WO.Config.InventoryHeight or 6)
        end
    else
        char.inventory = WO.Container.New("inventory", WO.Config.InventoryWidth or 10, WO.Config.InventoryHeight or 6)
    end

    -- Состояние всех предметов в инвентаре
    for _, instance in pairs(char.inventory:GetItems()) do
        instance.state = WO.Items.State.INVENTORY
    end
end)

WO.Hook.Add("CharacterSave", "inventory", function(char)
    local container = WO.Inventory.GetContainer(char)

    if not container then return end

    local serialized = container:Serialize()
    local json = util.TableToJSON(serialized.items)

    -- DELETE + INSERT — атомарно внутри транзакции сохранения персонажа
    WO.Database:Delete("wo_inventories", "owner_id = ? AND container = ?", char.id, "inventory")

    WO.Database:Insert("wo_inventories", {
        owner_id = char.id,
        container = "inventory",
        width = container.width,
        height = container.height,
        items = json,
    })
end)

WO.Hook.Add("CharacterSync", "inventory", function(char, ply)
    WO.Inventory.Sync(ply)
end)
