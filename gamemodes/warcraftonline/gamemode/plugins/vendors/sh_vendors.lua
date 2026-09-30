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

    if not def or not def.price then return nil end

    local base = tonumber(def.price.sell) or math.floor((tonumber(def.price.buy) or 0) * 0.4)
    local rate = (npcDef and npcDef.vendor and npcDef.vendor.sellRate) or 0.35

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
    rate = { max = 6, window = 5 },
    write = function(npcId, class, amount)
        net.WriteString(npcId or "")
        net.WriteString(class or "")
        net.WriteUInt(amount or 1, 16)
    end,
    read = function()
        return net.ReadString(), net.ReadString(), net.ReadUInt(16)
    end,
    validate = function(ply, npcId, class, amount)
        if not IsValid(ply) or not ply:HasCharacter() then return false, "invalid_player" end
        if not isstring(npcId) or npcId == "" then return false, "invalid_npc" end
        if not isstring(class) or class == "" then return false, "invalid_class" end
        if not isnumber(amount) or amount < 1 or amount > 100 then return false, "invalid_amount" end

        return true
    end,
    handler = function(ply, npcId, class, amount)
        WO.Vendors.Buy(ply, npcId, class, math.floor(amount))
    end,
})

WO.Net.Register("Vendor.Sell", {
    direction = "toserver",
    rate = { max = 6, window = 5 },
    write = function(npcId, uid, amount)
        net.WriteString(npcId or "")
        net.WriteString(uid or "")
        net.WriteUInt(amount or 1, 16)
    end,
    read = function()
        return net.ReadString(), net.ReadString(), net.ReadUInt(16)
    end,
    validate = function(ply, npcId, uid, amount)
        if not IsValid(ply) or not ply:HasCharacter() then return false, "invalid_player" end
        if not isstring(npcId) or npcId == "" then return false, "invalid_npc" end
        if not isstring(uid) or uid == "" then return false, "invalid_uid" end
        if not isnumber(amount) or amount < 1 or amount > 100 then return false, "invalid_amount" end

        return true
    end,
    handler = function(ply, npcId, uid, amount)
        WO.Vendors.Sell(ply, npcId, uid, math.floor(amount))
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
