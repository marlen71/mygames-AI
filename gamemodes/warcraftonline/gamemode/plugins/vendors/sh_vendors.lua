--[[
    Warcraft Online — торговля (shared): API и net.

    Торговец описывается в схеме NPC:
        WO.NPCs.Register({
            ...
            type = "vendor",
            vendor = {
                stock = {
                    { class = "bread",          price = 4,  amount = 20 },
                    { class = "health_potion",  price = 25, amount = 10 },
                },
                sellRate = 0.35,   -- цена продажи = sell цены предмета * sellRate
            },
        })

    Все цены — в медных монетах (единая валюта WO.Currency).
]]

WO.Vendors = WO.Vendors or {}

---------------------------------------------------------------------------
-- Цены
---------------------------------------------------------------------------

--- Цена покупки у этого торговца (или базовая цена предмета).
function WO.Vendors.GetBuyPrice(npcDef, class)
    if istable(npcDef and npcDef.vendor) then
        for _, entry in ipairs(npcDef.vendor.stock or {}) do
            if entry.class == class then
                return tonumber(entry.price) or nil
            end
        end
    end

    local def = WO.Items.Get(class)

    return def and def.price and def.price.buy or nil
end

--- Цена продажи этому торговцу.
function WO.Vendors.GetSellPrice(npcDef, class)
    local def = WO.Items.Get(class)

    if not def or not def.price or def.noSell == true or def.bound == true then return nil end

    local vendor = npcDef and npcDef.vendor
    local allowed = vendor and vendor.buybackClasses

    if istable(allowed) then
        local accepted = false

        for _, allowedClass in ipairs(allowed) do
            if allowedClass == class then
                accepted = true
                break
            end
        end

        -- A merchant should also buy back items that belong to its own stock;
        -- explicit buyback classes continue to permit quest/loot materials and
        -- scroll vendors can list all generated ranks separately.
        if not accepted then
            for _, entry in ipairs(vendor.stock or {}) do
                if entry.class == class then
                    accepted = true
                    break
                end
            end
        end

        if not accepted then return nil end
    end

    local base = tonumber(def.price.sell) or math.floor((tonumber(def.price.buy) or 0) * 0.4)
    local rate = tonumber(npcDef and npcDef.vendor and npcDef.vendor.sellRate) or 0.35

    return math.max(1, math.floor(base * rate))
end

--- Товар есть в наличии у торговца?
function WO.Vendors.HasStock(npcDef, class)
    if not istable(npcDef and npcDef.vendor) then return false end

    for _, entry in ipairs(npcDef.vendor.stock or {}) do
        if entry.class == class then
            return true
        end
    end

    return false
end

---------------------------------------------------------------------------
-- Net
---------------------------------------------------------------------------

WO.Net.Register("Vendor.Open", {
    direction = "toclient",
    write = function(data)
        net.WriteTable(data)
    end,
    read = function()
        return net.ReadTable()
    end,
    handler = function(_, data)
        WO.Hook.Run("VendorOpened", data)
    end,
})

WO.Net.Register("Vendor.Buy", {
    direction = "toserver",
    rate = { max = 12, window = 1 },
    write = function(npcId, class, amount, requestId)
        net.WriteString(npcId or "")
        net.WriteString(class or "")
        net.WriteUInt(amount or 1, 16)
        net.WriteUInt(requestId or 0, 32)
    end,
    read = function()
        return net.ReadString(), net.ReadString(), net.ReadUInt(16), net.ReadUInt(32)
    end,
    validate = function(ply, npcId, class, amount, requestId)
        if not IsValid(ply) or not ply:HasCharacter() then return false, "invalid_player" end
        if not isstring(npcId) or npcId == "" then return false, "invalid_npc" end
        if not isstring(class) or class == "" then return false, "invalid_class" end
        if not isnumber(amount) or amount < 1 or amount > 100 then return false, "invalid_amount" end
        if not isnumber(requestId) or requestId < 1 or requestId > 2147483647 then
            return false, "invalid_request"
        end

        return true
    end,
    handler = function(ply, npcId, class, amount, requestId)
        local success, reason = WO.Vendors.Buy(ply, npcId, class, math.floor(amount), true)

        WO.Net.Send("Vendor.ActionResult", ply, {
            action = "buy",
            npcId = npcId,
            requestId = requestId,
            money = WO.Currency.Get(ply),
            success = success == true,
            reason = reason,
        })

        if success == true and WO.Vendors.Sync then
            WO.Vendors.Sync(ply)
        end
    end,
})

WO.Net.Register("Vendor.Sell", {
    direction = "toserver",
    rate = { max = 12, window = 1 },
    write = function(npcId, uid, amount, requestId)
        net.WriteString(npcId or "")
        net.WriteString(uid or "")
        net.WriteUInt(amount or 1, 16)
        net.WriteUInt(requestId or 0, 32)
    end,
    read = function()
        return net.ReadString(), net.ReadString(), net.ReadUInt(16), net.ReadUInt(32)
    end,
    validate = function(ply, npcId, uid, amount, requestId)
        if not IsValid(ply) or not ply:HasCharacter() then return false, "invalid_player" end
        if not isstring(npcId) or npcId == "" then return false, "invalid_npc" end
        if not isstring(uid) or uid == "" then return false, "invalid_uid" end
        if not isnumber(amount) or amount < 1 or amount > 100 then return false, "invalid_amount" end
        if not isnumber(requestId) or requestId < 1 or requestId > 2147483647 then
            return false, "invalid_request"
        end

        return true
    end,
    handler = function(ply, npcId, uid, amount, requestId)
        local success, reason = WO.Vendors.Sell(ply, npcId, uid, math.floor(amount), true)

        WO.Net.Send("Vendor.ActionResult", ply, {
            action = "sell",
            npcId = npcId,
            requestId = requestId,
            money = WO.Currency.Get(ply),
            success = success == true,
            reason = reason,
        })

        if success == true and WO.Vendors.Sync then
            WO.Vendors.Sync(ply)
        end
    end,
})

WO.Net.Register("Vendor.Sync", {
    direction = "toclient",
    write = function(data)
        net.WriteTable(data)
    end,
    read = function()
        return net.ReadTable()
    end,
    handler = function(_, data)
        WO.Hook.Run("VendorSynced", data)
    end,
})

WO.Net.Register("Vendor.ActionResult", {
    direction = "toclient",
    write = function(data)
        net.WriteTable(data)
    end,
    read = function()
        return net.ReadTable()
    end,
    handler = function(_, data)
        WO.Hook.Run("VendorActionResult", data)
    end,
})
