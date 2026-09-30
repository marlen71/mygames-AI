--[[
    Warcraft Online — экипировка: сетевые сообщения (shared).
]]

---------------------------------------------------------------------------
-- Сервер → клиент
---------------------------------------------------------------------------

WO.Net.Register("Equipment.Sync", {
    direction = "toclient",
    write = function(slots)
        net.WriteTable(slots)
    end,
    read = function()
        return net.ReadTable()
    end,
    handler = function(_, slots)
        WO.Equipment.ClientData = slots

        WO.Hook.Run("EquipmentSynced", slots)
    end,
})

---------------------------------------------------------------------------
-- Клиент → сервер
---------------------------------------------------------------------------

-- Экипировать предмет из инвентаря
WO.Net.Register("Equipment.Equip", {
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
        local ok, reason = WO.Equipment.Equip(ply, uid)

        if not ok then
            WO.Notify(ply, "error", tostring(reason))
            WO.Inventory.Sync(ply)
        end
    end,
})

-- Снять предмет из слота
WO.Net.Register("Equipment.Unequip", {
    direction = "toserver",
    rate = { max = 10, window = 1 },
    write = function(slotId)
        net.WriteString(slotId or "")
    end,
    read = function()
        return net.ReadString()
    end,
    validate = function(ply, slotId)
        if not IsValid(ply) or not ply:HasCharacter() then return false, "no_character" end
        if not isstring(slotId) or slotId == "" then return false, "invalid_slot" end

        return true
    end,
    handler = function(ply, slotId)
        local ok, reason = WO.Equipment.Unequip(ply, slotId)

        if not ok then
            WO.Notify(ply, "error", tostring(reason))
        end
    end,
})
