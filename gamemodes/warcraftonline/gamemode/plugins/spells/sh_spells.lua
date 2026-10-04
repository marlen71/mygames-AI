--[[
    Warcraft Online — общая часть книги заклинаний.
    Данные живут в schemas/spells; серверная прогрессия автоматически считается
    по находящимся в инвентаре свиткам и повторно валидируется перед cast/select.
]]

WO.Spells = WO.Spells or {}
WO.Spells.Registry = WO.Spells.Registry or {}
WO.Spells.LocalBook = WO.Spells.LocalBook or nil
WO.Spells.WeaponClass = "wo_magic_grimoire"

function WO.Spells.Register(def)
    if not istable(def) or not isstring(def.id) or def.id == "" then
        WO.Error("WO.Spells.Register: invalid spell definition")
        return false
    end

    if WO.Spells.Registry[def.id] then
        WO.Error("WO.Spells.Register: duplicate spell '" .. def.id .. "'")
        return false
    end

    if def.type ~= "damage" and def.type ~= "heal" then
        WO.Error("WO.Spells.Register: invalid type for '" .. def.id .. "'")
        return false
    end

    def.name = def.name or def.id
    def.maxRank = math.max(1, math.floor(tonumber(def.maxRank) or 5))
    def.requiredLevel = math.max(1, math.floor(tonumber(def.requiredLevel) or 1))
    def.manaCost = math.max(0, math.floor(tonumber(def.manaCost) or 0))
    def.range = math.Clamp(tonumber(def.range) or 700, 64, 4096)
    def.cooldown = math.Clamp(tonumber(def.cooldown) or 1, 0.2, 60)
    def.basePower = math.max(0, tonumber(def.basePower) or 0)
    def.powerPerRank = math.max(0, tonumber(def.powerPerRank) or 0)
    def.spellPowerScale = math.max(0, tonumber(def.spellPowerScale) or 0)
    def.elementType = isstring(def.elementType) and def.elementType or "life"
    def.scrollPrice = math.max(1, math.floor(tonumber(def.scrollPrice) or
        (WO.Config.MagicScrolls and WO.Config.MagicScrolls.learningPrice) or 40))

    WO.Spells.Registry[def.id] = def
    return true
end

function WO.Spells.Get(id)
    return WO.Spells.Registry[id]
end

function WO.Spells.GetAll()
    return WO.Spells.Registry
end

function WO.Spells.GetScrollClass(spellId, targetRank)
    local rank = math.max(1, math.floor(tonumber(targetRank) or 1))

    if rank == 1 then
        return "spell_scroll_" .. tostring(spellId) .. "_learn"
    end

    return "spell_scroll_" .. tostring(spellId) .. "_rank_" .. rank
end

--- Builds the scroll item definitions and Malygos stock from registered spell schemas.
-- Called only after schemas/spells have been included; repeated calls are idempotent.
function WO.Spells.BuildScrollCatalog()
    if not (WO.Items and WO.Items.Register and WO.Items.Get) then return false end

    local config = WO.Config.MagicScrolls or {}
    local spellIDs, stock, buyback = {}, {}, {}

    for spellId in pairs(WO.Spells.Registry) do
        spellIDs[#spellIDs + 1] = spellId
    end

    table.sort(spellIDs)

    for _, spellId in ipairs(spellIDs) do
        local spell = WO.Spells.Get(spellId)

        for targetRank = 1, spell.maxRank do
            local class = WO.Spells.GetScrollClass(spellId, targetRank)
            local priceMultiplier = targetRank == 1 and 1 or
                ((tonumber(config.rankPriceMultiplier) or 1.5) +
                    (targetRank - 2) * (tonumber(config.rankPriceStep) or 0.5))
            local price = math.max(1, math.floor(spell.scrollPrice * priceMultiplier))
            local isLearning = targetRank == 1
            local label = isLearning and "Свиток: " .. spell.name or
                "Свиток ранга " .. targetRank .. ": " .. spell.name
            local description = isLearning and
                ("Пока находится в инвентаре, автоматически открывает «" .. spell.name .. "».") or
                ("Пока находится в инвентаре, автоматически устанавливает ранг " .. targetRank ..
                    " заклинания «" .. spell.name .. "».")

            if not WO.Items.Get(class) then
                WO.Items.Register({
                    id = class,
                    name = label,
                    type = "scroll",
                    category = "magic",
                    model = "models/props_lab/clipboard.mdl",
                    weight = 0.1,
                    stackable = true,
                    maxStack = math.max(1, math.floor(tonumber(config.stackSize) or 20)),
                    rarity = targetRank >= 4 and "rare" or "uncommon",
                    description = description,
                    requirements = { class = "mage" },
                    spellScroll = {
                        spellId = spellId,
                        targetRank = targetRank,
                    },
                    iconText = "✦",
                    price = { buy = price, sell = math.max(1, math.floor(price * 0.4)) },
                })
            end

            stock[#stock + 1] = {
                class = class,
                price = price,
                amount = math.max(1, math.floor(tonumber(config.vendorStockAmount) or 20)),
            }
            buyback[#buyback + 1] = class
        end
    end

    local vendor = WO.NPCs and WO.NPCs.Get and WO.NPCs.Get("malygos_scroll_vendor")

    if vendor and istable(vendor.vendor) then
        vendor.vendor.stock = stock
        vendor.vendor.buybackClasses = buyback
        vendor.vendor.sellRate = math.Clamp(tonumber(config.sellRate) or 0.25, 0, 1)
    end

    WO.Spells.ScrollCatalogReady = true

    return true
end

WO.Hook.Add("SchemasLoaded", "spells_scroll_catalog", function()
    WO.Spells.BuildScrollCatalog()
end)

WO.Net.Register("Spell.Sync", {
    direction = "toclient",
    write = function(data) net.WriteTable(data) end,
    read = function() return net.ReadTable() end,
    handler = function(_, data)
        if not CLIENT then return end
        WO.Spells.LocalBook = istable(data) and data or { ranks = {}, selected = "", points = 0, level = 1 }
        WO.Hook.Run("SpellbookSynced", WO.Spells.LocalBook)
    end,
})

-- Legacy packet is deliberately not sufficient to grant a spell. The server
-- rejects direct learning; possession of the matching server-side scroll is passive.
WO.Net.Register("Spell.Learn", {
    direction = "toserver",
    rate = { max = 4, window = 5 },
    write = function(spellId) net.WriteString(spellId or "") end,
    read = function() return net.ReadString() end,
    validate = function(ply, spellId)
        if not IsValid(ply) or not ply:HasCharacter() then return false, "invalid_player" end
        if not isstring(spellId) or #spellId > 64 or spellId == "" then return false, "invalid_spell" end
        local weapon = isfunction(ply.GetActiveWeapon) and ply:GetActiveWeapon()
        if not IsValid(weapon) or weapon:GetClass() ~= WO.Spells.WeaponClass then return false, "book_not_active" end
        return true
    end,
    handler = function(ply)
        -- Compatibility packet only: inventory changes passively update spell ranks.
        if SERVER then WO.Notify(ply, "error", "Ранг задаётся свитком, который находится в инвентаре.") end
    end,
})

WO.Net.Register("Spell.Select", {
    direction = "toserver",
    rate = { max = 8, window = 5 },
    write = function(spellId) net.WriteString(spellId or "") end,
    read = function() return net.ReadString() end,
    validate = function(ply, spellId)
        if not IsValid(ply) or not ply:HasCharacter() then return false, "invalid_player" end
        if not isstring(spellId) or #spellId > 64 or spellId == "" then return false, "invalid_spell" end
        local weapon = isfunction(ply.GetActiveWeapon) and ply:GetActiveWeapon()
        if not IsValid(weapon) or weapon:GetClass() ~= WO.Spells.WeaponClass then return false, "book_not_active" end
        return true
    end,
    handler = function(ply, spellId)
        if SERVER and WO.Spells.Select then WO.Spells.Select(ply, spellId) end
    end,
})

WO.Net.Register("Spell.SyncRequest", {
    direction = "toserver",
    rate = { max = 3, window = 5 },
    validate = function(ply)
        if not IsValid(ply) or not ply:HasCharacter() then return false, "invalid_player" end
        local weapon = isfunction(ply.GetActiveWeapon) and ply:GetActiveWeapon()
        if not IsValid(weapon) or weapon:GetClass() ~= WO.Spells.WeaponClass then return false, "book_not_active" end
        return true
    end,
    handler = function(ply)
        if SERVER and WO.Spells.Sync then WO.Spells.Sync(ply) end
    end,
})
