--[[
    Warcraft Online — инвентарь: сетевые сообщения (shared).
    Клиент отправляет ЗАПРОЗЫ; сервер валидирует и отвечает дельтами.

    Инвентарь целиком НЕ отправляется каждый кадр — только изменения.
]]

---------------------------------------------------------------------------
-- Сервер → клиент
---------------------------------------------------------------------------

-- Полная синхронизация инвентаря (при входе/открытии)
WO.Net.Register("Inventory.Sync", {
    direction = "toclient",
    write = function(data)
        net.WriteUInt(data.width or 10, 8)
        net.WriteUInt(data.height or 6, 8)
        net.WriteUInt(#data.items, 16)

        for _, item in ipairs(data.items) do
            net.WriteString(item.uid or "")
            net.WriteString(item.class or "")
            net.WriteUInt(item.amount or 1, 16)
            net.WriteInt(item.durability or -1, 16)
            net.WriteUInt(item.x or 0, 8)
            net.WriteUInt(item.y or 0, 8)
            net.WriteTable(item.data or {})
        end
    end,
    read = function()
        local data = {
            width = net.ReadUInt(8),
            height = net.ReadUInt(8),
            items = {},
        }

        local count = net.ReadUInt(16)

        for i = 1, count do
            local durability = net.ReadInt(16)

            data.items[i] = {
                uid = net.ReadString(),
                class = net.ReadString(),
                amount = net.ReadUInt(16),
                durability = durability >= 0 and durability or nil,
                x = net.ReadUInt(8),
                y = net.ReadUInt(8),
                data = net.ReadTable(),
            }
        end

        return data
    end,
    handler = function(_, data)
        WO.Inventory.ClientData = data

        WO.Hook.Run("InventorySynced", data)
    end,
})

-- Дельта: одно изменение (add/remove/update/move)
WO.Net.Register("Inventory.Delta", {
    direction = "toclient",
    write = function(delta)
        net.WriteString(delta.action or "")

        if delta.item then
            net.WriteBool(true)
            net.WriteString(delta.item.uid or "")
            net.WriteString(delta.item.class or "")
            net.WriteUInt(delta.item.amount or 1, 16)
            net.WriteInt(delta.item.durability or -1, 16)
            net.WriteUInt(delta.item.x or 0, 8)
            net.WriteUInt(delta.item.y or 0, 8)
            net.WriteTable(delta.item.data or {})
        else
            net.WriteBool(false)
        end

        net.WriteBool(delta.x ~= nil)
        if delta.x ~= nil then
            net.WriteUInt(delta.x, 8)
            net.WriteUInt(delta.y or 0, 8)
        end
    end,
    read = function()
        local delta = {
            action = net.ReadString(),
        }

        if net.ReadBool() then
            local durability = net.ReadInt(16)

            delta.item = {
                uid = net.ReadString(),
                class = net.ReadString(),
                amount = net.ReadUInt(16),
                durability = durability >= 0 and durability or nil,
                x = net.ReadUInt(8),
                y = net.ReadUInt(8),
                data = net.ReadTable(),
            }
        end

        if net.ReadBool() then
            delta.x = net.ReadUInt(8)
            delta.y = net.ReadUInt(8)
        end

        return delta
    end,
    handler = function(_, delta)
        -- Обновляем клиентский кэш
        local data = WO.Inventory.ClientData

        if not data then return end

        if delta.action == "remove" and delta.item then
            for i, item in ipairs(data.items) do
                if item.uid == delta.item.uid then
                    table.remove(data.items, i)
                    break
                end
            end
        elseif delta.item then
            local found = false

            for i, item in ipairs(data.items) do
                if item.uid == delta.item.uid then
                    data.items[i] = delta.item
                    found = true
                    break
                end
            end

            if not found then
                data.items[#data.items + 1] = delta.item
            end
        end

        WO.Hook.Run("InventoryChanged", delta)
    end,
})

---------------------------------------------------------------------------
-- Клиент → сервер
---------------------------------------------------------------------------

-- Перемещение предмета (drag & drop). Позиция проверяется сервером.
WO.Net.Register("Inventory.Move", {
    direction = "toserver",
    rate = { max = 30, window = 1 },
    write = function(uid, x, y)
        net.WriteString(uid or "")
        net.WriteUInt(x or 0, 8)
        net.WriteUInt(y or 0, 8)
    end,
    read = function()
        return net.ReadString(), net.ReadUInt(8), net.ReadUInt(8)
    end,
    validate = function(ply, uid, x, y)
        if not IsValid(ply) or not ply:HasCharacter() then return false, "no_character" end
        if not isstring(uid) or uid == "" then return false, "invalid_uid" end
        if not isnumber(x) or not isnumber(y) then return false, "invalid_position" end

        return true
    end,
    handler = function(ply, uid, x, y)
        local ok, reason = WO.Inventory.MoveItem(ply, uid, x, y)

        if not ok then
            WO.Debug("Inventory.Move rejected: " .. tostring(reason))
            -- Возвращаем актуальное состояние
            WO.Inventory.Sync(ply)
        end
    end,
})

-- Выброс предмета
WO.Net.Register("Inventory.Drop", {
    direction = "toserver",
    rate = { max = 10, window = 1 },
    write = function(uid, amount)
        net.WriteString(uid or "")
        net.WriteUInt(amount or 0, 16)
    end,
    read = function()
        return net.ReadString(), net.ReadUInt(16)
    end,
    validate = function(ply, uid)
        if not IsValid(ply) or not ply:HasCharacter() then return false, "no_character" end
        if not isstring(uid) or uid == "" then return false, "invalid_uid" end

        return true
    end,
    handler = function(ply, uid, amount)
        WO.Inventory.DropItem(ply, uid, amount)
    end,
})

-- Использование предмета
WO.Net.Register("Inventory.Use", {
    direction = "toserver",
    rate = { max = 10, window = 1 },
    write = function(uid)
        net.WriteString(uid or "")
    end,
    read = function()
        return net.ReadString()
    end,
    validate = function(ply, uid)
        if not IsValid(ply) or not ply:HasCharacter() then return false, "no_character" end
        if not isstring(uid) or uid == "" then return false, "invalid_uid" end

        return true
    end,
    handler = function(ply, uid)
        local ok, reason = WO.Inventory.UseItem(ply, uid)

        if not ok then
            WO.Notify(ply, "error", tostring(reason))
        end
    end,
})

-- Разделение стака
WO.Net.Register("Inventory.Split", {
    direction = "toserver",
    rate = { max = 10, window = 1 },
    write = function(uid, amount)
        net.WriteString(uid or "")
        net.WriteUInt(amount or 0, 16)
    end,
    read = function()
        return net.ReadString(), net.ReadUInt(16)
    end,
    validate = function(ply, uid, amount)
        if not IsValid(ply) or not ply:HasCharacter() then return false, "no_character" end
        if not isstring(uid) or uid == "" then return false, "invalid_uid" end
        if not isnumber(amount) or amount < 1 then return false, "invalid_amount" end

        return true
    end,
    handler = function(ply, uid, amount)
        WO.Inventory.SplitItem(ply, uid, amount)
    end,
})

-- Уничтожение предмета
WO.Net.Register("Inventory.Destroy", {
    direction = "toserver",
    rate = { max = 5, window = 1 },
    write = function(uid)
        net.WriteString(uid or "")
    end,
    read = function()
        return net.ReadString()
    end,
    validate = function(ply, uid)
        if not IsValid(ply) or not ply:HasCharacter() then return false, "no_character" end
        if not isstring(uid) or uid == "" then return false, "invalid_uid" end

        return true
    end,
    handler = function(ply, uid)
        WO.Inventory.DestroyItem(ply, uid)
    end,
})

-- Сортировка
WO.Net.Register("Inventory.Sort", {
    direction = "toserver",
    rate = { max = 3, window = 2 },
    handler = function(ply)
        if not IsValid(ply) or not ply:HasCharacter() then return end

        WO.Inventory.Sort(ply)
    end,
})

-- Передача предмета другому игроку
WO.Net.Register("Inventory.Give", {
    direction = "toserver",
    rate = { max = 5, window = 1 },
    write = function(targetUserId, uid, amount)
        net.WriteUInt(targetUserId or 0, 16)
        net.WriteString(uid or "")
        net.WriteUInt(amount or 0, 16)
    end,
    read = function()
        return net.ReadUInt(16), net.ReadString(), net.ReadUInt(16)
    end,
    validate = function(ply, targetUserId, uid)
        if not IsValid(ply) or not ply:HasCharacter() then return false, "no_character" end
        if not isnumber(targetUserId) or not isstring(uid) or uid == "" then return false, "invalid_args" end

        return true
    end,
    handler = function(ply, targetUserId, uid, amount)
        local target = Player(targetUserId)

        if not IsValid(target) then return end

        local ok, reason = WO.Inventory.GiveToPlayer(ply, target, uid, amount)

        if not ok then
            WO.Notify(ply, "error", tostring(reason))
        end
    end,
})

-- Запрос полной синхронизации (например, при открытии UI)
WO.Net.Register("Inventory.RequestSync", {
    direction = "toserver",
    rate = { max = 5, window = 1 },
    handler = function(ply)
        if not IsValid(ply) or not ply:HasCharacter() then return end

        WO.Inventory.Sync(ply)
    end,
})
