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

    if not istable(instance) then
        return false, "no_instance"
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
    local def = WO.Items.Get(instance.class)
    local placed = false

    if def and def.stackable then
        local stack = container:FindStack(def.id, def.maxStack)

        if stack then
            stack.amount = (stack.amount or 1) + (instance.amount or 1)

            WO.Inventory.SendDelta(ply, "update", stack)

            WO.Items.SetState(instance, WO.Items.State.DESTROYED) -- стек поглощён

            placed = true
        end
    end

    if not placed then
        if not container:HasSpace(instance) then
            ent.PickupLock = nil

            WO.Notify(ply, "error", WO.Lang:Get("inventory.no_space"))

            return false, "no_space"
        end

        WO.Items.SetState(instance, WO.Items.State.INVENTORY)

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
