--[[
    Warcraft Online — торговля (server): покупка/продажа, авторитет денег.
    Любая операция проверяется на сервере: товар, цена, дистанция, деньги.
]]

---------------------------------------------------------------------------
-- Сессия торговца
---------------------------------------------------------------------------

local function SessionValid(ply)
    local session = ply.wo_vendor

    if not session or not IsValid(ply) or not ply:HasCharacter() then return false end

    local ent = session.ent

    if not IsValid(ent) or ent:GetClass() ~= "wo_npc" or
        ent.npcDef ~= session.npcDef or ent.npcDef.type ~= "vendor" or
        not WO.NPCs or WO.NPCs.Get(ent:GetNPCID()) ~= session.npcDef then
        ply.wo_vendor = nil
        return false
    end

    local range = WO.Interaction.GetRange(ent)

    if ply:GetPos():Distance(ent:GetPos()) > range then
        ply.wo_vendor = nil
        return false
    end

    return true
end

local function SendSync(ply)
    if not IsValid(ply) then return end

    local session = ply.wo_vendor

    if not session then return end

    local def = session.npcDef
    local stock = {}

    for _, entry in ipairs((def.vendor and def.vendor.stock) or {}) do
        local itemDef = WO.Items.Get(entry.class)

        stock[#stock + 1] = {
            class = entry.class,
            name = itemDef and itemDef.name or entry.class,
            price = tonumber(entry.price) or 0,
            amount = tonumber(entry.amount) or 0,
            rarity = itemDef and itemDef.rarity or "common",
            description = itemDef and itemDef.description or "",
        }
    end

    WO.Net.Send("Vendor.Sync", ply, {
        npcId = def.id or "",
        npcName = def.name or "",
        money = WO.Currency.Get(ply),
        sellRate = (def.vendor and def.vendor.sellRate) or 0.35,
        stock = stock,
    })
end

---------------------------------------------------------------------------
-- API
---------------------------------------------------------------------------

--- Открывает торговлю NPC (вызывается из WO.NPCs.OnInteract).
function WO.Vendors.Open(ply, npcDef, ent)
    if not IsValid(ply) or not ply:HasCharacter() or not istable(npcDef) then return end

    if npcDef.type ~= "vendor" or not istable(npcDef.vendor) then
        WO.Error("WO.Vendors.Open: NPC '" .. tostring(npcDef.id) .. "' is not a vendor")
        return
    end

    if not IsValid(ent) or ent:GetClass() ~= "wo_npc" or ent.npcDef ~= npcDef or
        WO.NPCs.Get(ent:GetNPCID()) ~= npcDef or
        not WO.Interaction.CanInteract(ent, ply) or
        ply:GetPos():Distance(ent:GetPos()) > WO.Interaction.GetRange(ent) then
        return
    end

    ply.wo_vendor = {
        ent = ent,
        npcDef = npcDef,
    }

    WO.Net.Send("Vendor.Open", ply, {
        npcId = npcDef.id or "",
        npcName = npcDef.name or "",
    })

    SendSync(ply)
end

--- Покупка товара (сервер валидирует всё).
function WO.Vendors.Buy(ply, npcId, class, amount)
    if not IsValid(ply) or not ply:HasCharacter() then return false, "invalid_player" end

    local session = ply.wo_vendor

    if not SessionValid(ply) or session.npcDef.id ~= npcId then
        return false, "no_session"
    end

    local def = session.npcDef

    if not WO.Vendors.HasStock(def, class) then
        return false, "not_in_stock"
    end

    if not WO.Items.Get(class) then
        return false, "unknown_item"
    end

    local price = WO.Vendors.GetBuyPrice(def, class)

    if not price then return false, "no_price" end

    local total = price * amount

    if not WO.Currency.CanAfford(ply, total) then
        WO.Notify(ply, "error", WO.Lang:Get("vendor.not_enough_money"))
        return false, "not_enough_money"
    end

    -- Деньги списываем ТОЛЬКО после успешной выдачи
    local given = WO.Inventory.GiveItem(ply, class, amount)

    if given == false then
        WO.Notify(ply, "error", WO.Lang:Get("vendor.inventory_full"))
        return false, "inventory_full"
    end

    WO.Currency.Take(ply, total, "vendor_buy:" .. class)

    SendSync(ply)

    WO.Log("Vendor buy: " .. ply:Nick() .. " " .. class .. " x" .. amount .. " for " .. total)

    return true
end

--- Продажа предмета (сервер валидирует всё).
function WO.Vendors.Sell(ply, npcId, uid, amount)
    if not IsValid(ply) or not ply:HasCharacter() then return false, "invalid_player" end

    local session = ply.wo_vendor

    if not SessionValid(ply) or session.npcDef.id ~= npcId then
        return false, "no_session"
    end

    local char = ply:GetCharacter()
    local container = WO.Inventory.GetContainer(char)
    local instance = container and container:GetItem(uid)

    if not instance then
        return false, "no_item"
    end

    if not WO.Items.IsInventoryAllowed(instance.class) then
        return false, "not_inventory_item"
    end

    local sellPrice = WO.Vendors.GetSellPrice(session.npcDef, instance.class)

    if not sellPrice then
        return false, "cannot_sell"
    end

    amount = math.min(amount, instance.amount or 1)

    local total = sellPrice * amount

    -- Удаляем предмет, затем начисляем деньги (обратный порядок → дюп невозможен)
    local removed = WO.Inventory.RemoveItem(ply, uid, amount)

    if removed == false then
        return false, "remove_failed"
    end

    WO.Currency.Add(ply, total, "vendor_sell:" .. instance.class)

    SendSync(ply)

    WO.Log("Vendor sell: " .. ply:Nick() .. " " .. instance.class .. " x" .. amount .. " for " .. total)

    return true
end
