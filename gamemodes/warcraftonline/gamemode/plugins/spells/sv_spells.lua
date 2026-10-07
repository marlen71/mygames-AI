--[[ Warcraft Online — server-authoritative spell learning, casting and persistence. ]]

local spellOrder = {
    "healing_wave", "firebolt", "air_burst", "water_bolt",
    "earth_shard", "lightning_strike", "frost_lance",
}

local function EnsureBook(char)
    char.spellbook = istable(char.spellbook) and char.spellbook or {}
    char.spellbook.ranks = istable(char.spellbook.ranks) and char.spellbook.ranks or {}
    char.spellbook.selected = isstring(char.spellbook.selected) and char.spellbook.selected or ""

    for spellId, rank in pairs(char.spellbook.ranks) do
        local def = WO.Spells.Get(spellId)

        if not def then
            char.spellbook.ranks[spellId] = nil
        else
            char.spellbook.ranks[spellId] = math.Clamp(math.floor(tonumber(rank) or 0), 0, def.maxRank)
            if char.spellbook.ranks[spellId] <= 0 then char.spellbook.ranks[spellId] = nil end
        end
    end

    return char.spellbook
end

local function GetInventoryRanks(char)
    local ranks = {}

    if not WO.Character.IsCharacter(char) or not WO.Inventory or
        not isfunction(WO.Inventory.GetContainer) then
        return ranks
    end

    local container = WO.Inventory.GetContainer(char)
    local items = container and container.GetItems and container:GetItems() or {}

    for _, instance in pairs(items) do
        if istable(instance) and isstring(instance.class) and
            (instance.state == nil or instance.state == WO.Items.State.INVENTORY) then
            local itemDef = WO.Items.Get(instance.class)
            local scroll = itemDef and itemDef.spellScroll
            local spell = scroll and WO.Spells.Get(scroll.spellId)
            local targetRank = scroll and math.floor(tonumber(scroll.targetRank) or 0) or 0

            if spell and targetRank >= 1 and targetRank <= spell.maxRank and
                instance.class == WO.Spells.GetScrollClass(scroll.spellId, targetRank) then
                ranks[scroll.spellId] = math.max(ranks[scroll.spellId] or 0, targetRank)
            end
        end
    end

    return ranks
end

local function PointsSpent(ranks)
    local spent = 0

    for _, rank in pairs(ranks or {}) do
        spent = spent + math.max(0, math.floor(tonumber(rank) or 0))
    end

    return spent
end

function WO.Spells.PointsAvailable(char)
    if not WO.Character.IsCharacter(char) then return 0 end

    local level = math.max(1, math.floor(tonumber(char.level) or 1))
    return math.max(0, level - PointsSpent(GetInventoryRanks(char)))
end

-- Spell progression is inventory-owned: the highest matching scroll rank in
-- the character's server-side inventory determines the usable spell rank.
function WO.Spells.GetRank(char, spellId)
    if not WO.Character.IsCharacter(char) or not WO.Spells.Get(spellId) then return 0 end

    return GetInventoryRanks(char)[spellId] or 0
end

local function GetSelectedFromRanks(book, ranks)
    local selected = book.selected

    if (ranks[selected] or 0) > 0 then
        return selected
    end

    for _, spellId in ipairs(spellOrder) do
        if (ranks[spellId] or 0) > 0 then
            return spellId
        end
    end

    return nil
end

function WO.Spells.GetSelected(char)
    if not WO.Character.IsCharacter(char) then return nil end

    return GetSelectedFromRanks(EnsureBook(char), GetInventoryRanks(char))
end

function WO.Spells.Sync(ply)
    if not IsValid(ply) or not ply:HasCharacter() then return false end

    local char = ply:GetCharacter()
    local book = EnsureBook(char)
    local ranks = GetInventoryRanks(char)
    local selected = GetSelectedFromRanks(book, ranks)

    -- Keep the persisted payload/cache aligned with the source of truth; it is
    -- never used to grant a rank when the corresponding scroll is absent.
    book.ranks = ranks
    book.selected = selected or ""

    WO.Net.Send("Spell.Sync", ply, {
        ranks = ranks,
        selected = book.selected,
        points = math.max(0, math.floor(tonumber(char.level) or 1) - PointsSpent(ranks)),
        level = math.max(1, math.floor(tonumber(char.level) or 1)),
    })

    return true
end

-- Compatibility API for callers from older revisions. Scrolls now grant their
-- rank passively while present in inventory; this never consumes the item.
function WO.Spells.LearnOrUpgrade(ply, spellId, scrollInstance)
    if not IsValid(ply) or not ply:HasCharacter() then return false, "no_character" end

    local char = ply:GetCharacter()
    local spell = WO.Spells.Get(spellId)

    if not spell then return false, "unknown_spell" end
    if not WO.Spells.CanUseClass(char.class) then return false, "class" end
    if not istable(scrollInstance) or not isstring(scrollInstance.uid) or
        not isstring(scrollInstance.class) then
        return false, "required_scroll"
    end

    local container = WO.Inventory and WO.Inventory.GetContainer and WO.Inventory.GetContainer(char)
    local ownedScroll = container and container:GetItem(scrollInstance.uid)

    if ownedScroll ~= scrollInstance then return false, "required_scroll" end

    local scrollDef = WO.Items.Get(scrollInstance.class)
    local scroll = scrollDef and scrollDef.spellScroll
    local targetRank = scroll and math.floor(tonumber(scroll.targetRank) or 0) or 0

    if not scroll or scroll.spellId ~= spellId or targetRank < 1 or
        targetRank > spell.maxRank or
        scrollInstance.class ~= WO.Spells.GetScrollClass(spellId, targetRank) then
        return false, "wrong_scroll"
    end

    local rank = WO.Spells.GetRank(char, spellId)

    if rank < targetRank then return false, "required_scroll" end

    WO.Spells.Sync(ply)
    return true, rank
end

function WO.Spells.UseScroll(ply, instance)
    if not istable(instance) then return false, "invalid_scroll" end

    local def = WO.Items.Get(instance.class)
    local scroll = def and def.spellScroll

    if not istable(scroll) then return false, "invalid_scroll" end
    return WO.Spells.LearnOrUpgrade(ply, scroll.spellId, instance)
end

function WO.Spells.Select(ply, spellId)
    if not IsValid(ply) or not ply:HasCharacter() then return false, "no_character" end

    local char = ply:GetCharacter()
    local spell = WO.Spells.Get(spellId)

    if not WO.Spells.CanUseClass(char.class) then return false, "class" end

    if not spell or WO.Spells.GetRank(char, spellId) <= 0 then
        return false, "not_learned"
    end

    local book = EnsureBook(char)
    book.selected = spellId

    if WO.SaveQueue then WO.SaveQueue.MarkDirty(char) end
    WO.Spells.Sync(ply)
    WO.Notify(ply, "info", "Выбрано заклинание: " .. spell.name)
    return true
end

function WO.Spells.CanCast(ply, spellId)
    if not IsValid(ply) or not ply:HasCharacter() then return false, "no_character" end

    local char = ply:GetCharacter()
    local spell = WO.Spells.Get(spellId)

    if not spell then return false, "unknown_spell" end
    if not WO.Spells.CanUseClass(char.class) then return false, "class" end

    local rank = WO.Spells.GetRank(char, spellId)

    if rank <= 0 then return false, "not_learned" end

    return true, spell, rank
end

function WO.Spells.Apply(ply, spellId, target)
    local canCast, spell, rank = WO.Spells.CanCast(ply, spellId)

    if not canCast then return false, spell end

    local char = ply:GetCharacter()
    local spellPower = ply:GetStat("spellPower") or 0
    local rawPower = spell.basePower + math.max(0, rank - 1) * spell.powerPerRank +
        spellPower * spell.spellPowerScale
    local affinity = WO.Spells.GetMagicBonus(char, spell.elementType)
    local power = rawPower * (1 + affinity)

    if spell.type == "heal" then
        if not IsValid(target) or not target:IsPlayer() or
            not target:HasCharacter() or target:GetPos():Distance(ply:GetPos()) > spell.range then
            target = ply
        end

        local maxHealth = math.max(1, target:GetMaxHealth())
        local before = target:Health()
        local after = math.min(maxHealth, before + math.max(1, math.floor(power)))
        local actual = after - before

        target:SetHealth(after)

        if actual > 0 then
            WO.Notify(ply, "success", "Исцеление: +" .. actual .. " HP" ..
                (target ~= ply and (" — " .. target:Nick()) or ""))
            if target ~= ply then WO.Notify(target, "success", "Вас исцелил " .. ply:Nick() .. ".") end
        else
            WO.Notify(ply, "info", "Здоровье уже полностью восстановлено.")
        end

        WO.Hook.Run("SpellCast", ply, spell, target, rank, actual)
        return true, target, actual
    end

    if not IsValid(target) or not isfunction(target.Health) or target:Health() <= 0 then
        return false, "no_target"
    end

    local applied, amount = WO.Combat.Damage(ply, target, {
        amount = math.max(1, math.floor(power)),
        type = spell.damageType or WO.Enums.DamageType.ARCANE,
        weapon = WO.Spells.WeaponClass,
        ability = spellId,
        canCrit = false,
    })

    if applied then WO.Hook.Run("SpellCast", ply, spell, target, rank, amount) end
    return applied, target, amount
end

WO.Hook.Add("CharacterLoad", "spells", function(char)
    char.spellbook = { ranks = {}, selected = "" }

    local rows = WO.Database:Fetch(
        "SELECT data FROM wo_abilities WHERE owner_id = ? AND ability_id = ?",
        char.id, "spellbook")
    local data = rows[1] and util.JSONToTable(rows[1].data or "") or nil

    if istable(data) then
        char.spellbook.ranks = istable(data.ranks) and data.ranks or {}
        char.spellbook.selected = isstring(data.selected) and data.selected or ""
    end

    EnsureBook(char)
end)

WO.Hook.Add("CharacterSave", "spells", function(char)
    if not char.id then return end

    local book = EnsureBook(char)
    book.ranks = GetInventoryRanks(char)
    WO.Database:Delete("wo_abilities", "owner_id = ? AND ability_id = ?", char.id, "spellbook")
    WO.Database:Insert("wo_abilities", {
        owner_id = char.id,
        ability_id = "spellbook",
        data = util.TableToJSON({ ranks = book.ranks, selected = book.selected }),
    })
end)

-- Spell data has its own wire payload and persistence lifecycle; it does not
-- depend on the generic CharacterSync bundle (which intentionally omits plugins).
WO.Hook.Add("CharacterSelected", "spells", function(_, ply)
    WO.Spells.Sync(ply)
end)

-- Keep the client spellbook and selected spell in step with scroll pickup,
-- purchase, sale, drop, use, and every other authoritative inventory mutation.
WO.Hook.Add("InventoryChanged", "spells_scroll_ranks", function(char)
    local ply = char and char.player

    if IsValid(ply) and ply:HasCharacter() and ply:GetCharacter() == char then
        WO.Spells.Sync(ply)
    end
end)

WO.Hook.Add("CharacterLevelUp", "spells", function(char)
    local ply = char and char.player

    if IsValid(ply) then
        WO.Spells.Sync(ply)
        WO.Notify(ply, "info", "Уровень повышен: ранги заклинаний из инвентарных свитков пересчитаны.")
    end
end)
