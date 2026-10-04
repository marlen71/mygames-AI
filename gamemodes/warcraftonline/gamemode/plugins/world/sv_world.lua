--[[
    Warcraft Online — мир (server): физические предметы, drop/pickup транзакции.

    Drop (Inventory → World) — транзакция:
        Player → Item Entity → physics impulse.

    Pickup (World → Inventory) — транзакция:
        сервер проверяет дистанцию, существование, доступность, место;
        при неудаче — "Недостаточно места".
]]

WO.World = WO.World or {}

---------------------------------------------------------------------------
-- Выброс предмета в мир
---------------------------------------------------------------------------

--[[
    Создаёт физический предмет в мире из item instance.

    @param ply Player кто выбрасывает
    @param instance table item instance (state уже должен стать WORLD после успеха)
    @return boolean success, string|nil reason
]]
function WO.World.DropItem(ply, instance)
    if not IsValid(ply) then return false, "invalid_player" end

    if not istable(instance) or not isstring(instance.uid) then
        return false, "invalid_instance"
    end

    local def = WO.Items.Get(instance.class)

    if not def then return false, "unknown_class" end

    -- Позиция: перед игроком (по направлению взгляда)
    local eyePos = ply:GetShootPos()
    local aim = ply:GetAimVector()
    local dropPos = eyePos + aim * 48

    -- Не роняем внутрь геометрии
    local tr = util.TraceLine({
        start = eyePos,
        endpos = dropPos,
        filter = ply,
        mask = MASK_SOLID,
    })

    dropPos = tr.HitPos - aim * 8

    -- Создаём entity
    local ent = ents.Create("wo_item_world")

    if not IsValid(ent) then
        WO.Error("WO.World.DropItem: failed to create wo_item_world")
        return false, "spawn_failed"
    end

    ent:SetPos(dropPos)
    ent:SetAngles(AngleRand())
    ent:Spawn()
    ent:Activate()

    if not ent:SetItem(instance) then
        ent:Remove()
        return false, "set_item_failed"
    end

    -- Физический импульс броска
    local velocity = aim * 220 + Vector(0, 0, 60)

    ent:ApplyThrow(velocity)

    WO.Debug("World item spawned: " .. instance.class .. " [" .. instance.uid .. "]")

    -- Персистентность (опционально)
    if WO.Config.WorldItemsPersist then
        WO.World.SaveWorldItem(ent, instance)
    end

    return true
end

--- Спавнит свежесозданный loot-item с физикой в заданной точке смерти NPC.
function WO.World.SpawnLootItem(instance, position, velocity)
    if not istable(instance) or not isstring(instance.uid) or not isvector(position) then
        return false, "invalid_loot"
    end

    local def = WO.Items.Get(instance.class)

    if not def or not WO.Items.IsInventoryAllowed(instance.class) then
        return false, "invalid_item"
    end

    local ent = ents.Create("wo_item_world")

    if not IsValid(ent) then return false, "spawn_failed" end

    ent:SetPos(position)
    ent:SetAngles(AngleRand())
    ent:Spawn()
    ent:Activate()

    if not ent:SetItem(instance) then
        ent:Remove()
        return false, "set_item_failed"
    end

    if not WO.Items.SetState(instance, WO.Items.State.WORLD) then
        ent:Remove()
        return false, "state_failed"
    end

    ent:ApplyThrow(velocity or VectorRand() * 90 + Vector(0, 0, 100))

    if WO.Config.WorldItemsPersist then
        WO.World.SaveWorldItem(ent, instance)
    end

    return true, ent
end

--- Создаёт физическую кучку валюты, подбираемую через E.
function WO.World.SpawnLootCoins(amount, position, velocity)
    amount = math.floor(tonumber(amount) or 0)

    if amount <= 0 or not isvector(position) then return false, "invalid_amount" end

    local ent = ents.Create("wo_coin_pile")

    if not IsValid(ent) then return false, "spawn_failed" end

    ent:SetPos(position)
    ent:SetAngles(AngleRand())
    ent:Spawn()
    ent:Activate()

    if not ent:SetCoinAmount(amount) then
        ent:Remove()
        return false, "set_amount_failed"
    end

    ent:ApplyThrow(velocity or VectorRand() * 100 + Vector(0, 0, 120))
    return true, ent
end

--- Поднимает только серверную сумму монет; блокировка закрывает двойное начисление.
function WO.World.PickupCoins(ply, ent)
    if not IsValid(ply) or not ply:HasCharacter() or not IsValid(ent) or
        ent:GetClass() ~= "wo_coin_pile" or not ent:CanInteract(ply) then
        return false, "cannot_interact"
    end

    if ent.PickupLock then return false, "busy" end

    ent.PickupLock = true
    local amount = math.floor(tonumber(ent.WOCoinAmount) or 0)

    if amount <= 0 then
        ent.PickupLock = nil
        return false, "empty"
    end

    if not WO.Currency.Add(ply, amount, "npc_loot") then
        ent.PickupLock = nil
        return false, "currency_failed"
    end

    ent.WOCoinAmount = 0
    ent:SetNW2Int("wo_coin_amount", 0)
    ent:Remove()
    WO.Notify(ply, "item", "Подобраны монеты: " .. amount .. ".")
    return true
end

---------------------------------------------------------------------------
-- Серверный автосбор важных ресурсов
---------------------------------------------------------------------------

local AUTO_COLLECT_RARITIES = {
    rare = true,
    epic = true,
    legendary = true,
    artifact = true,
    quest = true,
}

--- Проверяет, требуется ли предмет активному collect-шагу персонажа.
function WO.World.IsRequiredForActiveQuest(ply, itemClass)
    if not IsValid(ply) or not ply:HasCharacter() or not isstring(itemClass) then
        return false
    end

    local char = ply:GetCharacter()
    local container = char and WO.Inventory.GetContainer(char)
    local owned = container and container:CountItem(itemClass) or 0

    for questId, state in pairs(char and char.quests or {}) do
        if state.status == "active" then
            local questDef = WO.Quests and WO.Quests.Get and WO.Quests.Get(questId)

            for _, step in ipairs(questDef and questDef.steps or {}) do
                if step.type == "collect" and step.class == itemClass and
                    owned < math.max(1, math.floor(tonumber(step.amount) or 1)) then
                    return true
                end
            end
        end
    end

    return false
end

--- Data-driven predicate for valuable/quest resources; no client claim is used.
function WO.World.IsAutoCollectEligible(ply, itemClass)
    if not isstring(itemClass) then return false end

    local def = WO.Items.Get(itemClass)

    if not def or not WO.Items.IsInventoryAllowed(def) or def.autoCollect == false then
        return false
    end

    if def.autoCollect == true or def.questItem == true or def.type == "quest" or
        AUTO_COLLECT_RARITIES[def.rarity] then
        return true
    end

    if WO.World.IsRequiredForActiveQuest(ply, itemClass) then
        return true
    end

    local price = istable(def.price) and def.price or {}
    local value = math.max(tonumber(price.buy) or 0, tonumber(price.sell) or 0)
    local threshold = math.max(0, tonumber(WO.Config.AutoCollectValueThreshold) or 15)

    return threshold > 0 and value >= threshold
end

local function HasAutoCollectSpace(ply, ent, instance, def)
    local char = ply:GetCharacter()
    local container = char and WO.Inventory.GetContainer(char)

    if not container then return false end

    if def.uniquePerCharacter == true then
        if container:CountItem(instance.class) > 0 then return false end

        local equipment = WO.Equipment and WO.Equipment.Get and WO.Equipment.Get(char)

        for _, equipped in pairs(equipment and equipment.slots or {}) do
            if equipped and equipped.class == instance.class then
                return false
            end
        end
    end

    if def.stackable then
        local stack = container:FindStack(def.id, def.maxStack)

        if stack and (stack.amount or 1) + (instance.amount or 1) <= def.maxStack then
            return true
        end
    end

    return container:HasSpace(instance)
end

--- Attempts one pickup using only the server entity/instance and normal pickup checks.
function WO.World.TryAutoCollect(ply, ent)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:HasCharacter() or
        not ply:Alive() or not IsValid(ent) or ent.PickupLock or
        not WO.Settings or not WO.Settings.IsAutoCollectEnabled or
        not WO.Settings.IsAutoCollectEnabled(ply) then
        return false, "disabled_or_invalid"
    end

    local class = ent:GetClass()

    if class == "wo_coin_pile" then
        if not isfunction(ent.CanInteract) or not ent:CanInteract(ply) then
            return false, "cannot_interact"
        end

        return WO.World.PickupCoins(ply, ent)
    end

    if class ~= "wo_item_world" or not isfunction(ent.CanInteract) or
        not ent:CanInteract(ply) then
        return false, "cannot_interact"
    end

    local instance = ent.ItemInstance

    if not istable(instance) or instance.state ~= WO.Items.State.WORLD or
        not WO.World.IsAutoCollectEligible(ply, instance.class) then
        return false, "not_eligible"
    end

    local def = WO.Items.Get(instance.class)

    if not def or not HasAutoCollectSpace(ply, ent, instance, def) then
        return false, "no_space"
    end

    -- PickupItem repeats distance, entity class, state, lock and inventory checks.
    return WO.World.PickupItem(ply, ent)
end

--- One item per nearby opted-in player per tick avoids bursts and notification spam.
function WO.World.AutoCollectTick()
    if not player or not isfunction(player.GetAll) or not ents or
        not isfunction(ents.FindInSphere) then return end

    local radius = math.max(1, tonumber(WO.Config.InteractDistance) or 100)

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsPlayer() and ply:HasCharacter() and ply:Alive() and
            WO.Settings and WO.Settings.IsAutoCollectEnabled and
            WO.Settings.IsAutoCollectEnabled(ply) then
            for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), radius)) do
                local picked = WO.World.TryAutoCollect(ply, ent)

                if picked then break end
            end
        end
    end
end

timer.Create("wo_world_auto_collect", 0.25, 0, function()
    WO.World.AutoCollectTick()
end)

---------------------------------------------------------------------------
-- Подбор предмета (World → Inventory)
---------------------------------------------------------------------------

--[[
    Подбирает физический предмет в инвентарь игрока.
    Сервер САМ определяет предмет по entity — клиент не может сказать
    "я поднял item UID".

    @param ply Player
    @param ent Entity wo_item_world
    @return boolean success, string|nil reason
]]
function WO.World.PickupItem(ply, ent)
    if not IsValid(ply) or not IsValid(ent) then return false, "invalid" end

    if ent:GetClass() ~= "wo_item_world" then
        return false, "invalid_class"
    end

    if not ent:CanInteract(ply) then
        return false, "cannot_interact"
    end

    local instance = ent.ItemInstance

    if not istable(instance) or not isstring(instance.uid) or
        not isstring(instance.class) or ent.ItemUID ~= instance.uid then
        return false, "no_instance"
    end

    local def = WO.Items.Get(instance.class)

    if not def or not WO.Items.IsInventoryAllowed(def) then
        return false, "invalid_item"
    end

    -- Состояние должно быть WORLD
    if instance.state ~= WO.Items.State.WORLD then
        return false, "invalid_state"
    end

    -- Предмет должен быть уникален: entity не может исчезнуть без изменения инвентаря
    if ent.PickupLock then
        return false, "busy"
    end

    ent.PickupLock = true

    local char = ply:GetCharacter()

    if not char then
        ent.PickupLock = nil
        return false, "no_character"
    end

    local container = WO.Inventory.GetContainer(char)

    if not container then
        ent.PickupLock = nil
        return false, "no_container"
    end

    -- Пытаемся положить (стекуем если возможно)
    local placed = false

    if def.stackable then
        local stack = container:FindStack(def.id, def.maxStack)

        if stack and (stack.amount or 1) + (instance.amount or 1) <= def.maxStack then
            if not WO.Items.SetState(instance, WO.Items.State.DESTROYED) then
                ent.PickupLock = nil
                return false, "state_transition_failed"
            end

            stack.amount = (stack.amount or 1) + (instance.amount or 1)
            WO.Inventory.SendDelta(ply, "update", stack)
            placed = true
        end
    end

    if not placed then
        if not container:HasSpace(instance) then
            ent.PickupLock = nil

            WO.Notify(ply, "error", WO.Lang:Get("inventory.no_space"))

            return false, "no_space"
        end

        if not WO.Items.SetState(instance, WO.Items.State.INVENTORY) then
            ent.PickupLock = nil
            return false, "state_transition_failed"
        end

        local ok, reason = container:AddItem(instance)

        if not ok then
            -- Откат состояния
            WO.Items.SetState(instance, WO.Items.State.WORLD)
            ent.PickupLock = nil

            return false, reason
        end

        WO.Inventory.SendDelta(ply, "add", instance)
    end

    -- Успех: удаляем entity
    ent.ItemInstance = nil

    if WO.Config.WorldItemsPersist then
        WO.World.DeleteWorldItem(instance.uid)
    end

    ent:Remove()

    WO.SaveQueue.MarkDirty(char)
    WO.Hook.Run("InventoryChanged", char)
    WO.Hook.Run("ItemPickedUp", char, instance)

    local itemName = (def and def.name) or instance.class

    WO.Notify(ply, "item", string.format(WO.Lang:Get("inventory.item_received"), itemName))

    return true
end

---------------------------------------------------------------------------
-- Персистентность мировых предметов (опционально)
---------------------------------------------------------------------------

function WO.World.SaveWorldItem(ent, instance)
    if not IsValid(ent) then return end

    local pos = ent:GetPos()

    WO.Database:Query(
        "INSERT OR REPLACE INTO wo_world_items (uid, data, map, pos_x, pos_y, pos_z, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
        instance.uid,
        util.TableToJSON(WO.Items.Serialize(instance)),
        game.GetMap(),
        pos.x, pos.y, pos.z,
        WO.Util.Time()
    )
end

function WO.World.DeleteWorldItem(uid)
    WO.Database:Delete("wo_world_items", "uid = ?", uid)
end

-- Восстановление мировых предметов при старте (если включена персистентность)
-- Выполняется ТОЛЬКО после готовности БД (DatabaseReady)
WO.Hook.Add("DatabaseReady", "world_restore", function()
    if not WO.Config.WorldItemsPersist then return end

    local rows = WO.Database:Fetch("SELECT * FROM wo_world_items WHERE map = ?", game.GetMap())

    for _, row in ipairs(rows or {}) do
        local data = util.JSONToTable(row.data or "")
        local instance = data and WO.Items.Deserialize(data)

        if instance then
            local ent = ents.Create("wo_item_world")

            if IsValid(ent) then
                ent:SetPos(Vector(tonumber(row.pos_x) or 0, tonumber(row.pos_y) or 0, tonumber(row.pos_z) or 0))
                ent:Spawn()
                ent:Activate()
                ent:SetItem(instance)

                WO.Items.SetState(instance, WO.Items.State.WORLD)
            end
        end
    end

    WO.Log("World items restored: " .. tostring(rows and #rows or 0))
end)

-- Очистка при выключении, если предметы не персистентны
hook.Add("ShutDown", "wo_world_cleanup", function()
    if WO.Config.WorldItemsPersist then return end

    WO.Database:Delete("wo_world_items", "map = ?", game.GetMap())
end)
