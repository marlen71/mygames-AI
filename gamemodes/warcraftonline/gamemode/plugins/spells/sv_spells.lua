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

local function PointsSpent(book)
    local spent = 0

    for _, rank in pairs(book.ranks or {}) do
        spent = spent + math.max(0, math.floor(tonumber(rank) or 0))
    end

    return spent
end

function WO.Spells.PointsAvailable(char)
    if not WO.Character.IsCharacter(char) then return 0 end

    local book = EnsureBook(char)
    local level = math.max(1, math.floor(tonumber(char.level) or 1))

    return math.max(0, level - PointsSpent(book))
end

function WO.Spells.GetRank(char, spellId)
    if not WO.Character.IsCharacter(char) then return 0 end

    local book = EnsureBook(char)
    return math.max(0, math.floor(tonumber(book.ranks[spellId]) or 0))
end

function WO.Spells.GetSelected(char)
    if not WO.Character.IsCharacter(char) then return nil end

    local book = EnsureBook(char)
    local selected = book.selected

    if WO.Spells.GetRank(char, selected) > 0 then
        return selected
    end

    for _, spellId in ipairs(spellOrder) do
        if WO.Spells.GetRank(char, spellId) > 0 then
            return spellId
        end
    end

    return nil
end

function WO.Spells.Sync(ply)
    if not IsValid(ply) or not ply:HasCharacter() then return false end

    local char = ply:GetCharacter()
    local book = EnsureBook(char)
    local ranks = {}

    for spellId, rank in pairs(book.ranks) do
        ranks[spellId] = rank
    end

    WO.Net.Send("Spell.Sync", ply, {
        ranks = ranks,
        selected = WO.Spells.GetSelected(char) or "",
        points = WO.Spells.PointsAvailable(char),
        level = math.max(1, math.floor(tonumber(char.level) or 1)),
    })

    return true
end

function WO.Spells.LearnOrUpgrade(ply, spellId, scrollInstance)
    if not IsValid(ply) or not ply:HasCharacter() then return false, "no_character" end

    local char = ply:GetCharacter()

    if not istable(scrollInstance) or not isstring(scrollInstance.uid) or
        not isstring(scrollInstance.class) then
        return false, "required_scroll"
    end

    local container = WO.Inventory and WO.Inventory.GetContainer and WO.Inventory.GetContainer(char)
    local ownedScroll = container and container:GetItem(scrollInstance.uid)

    if ownedScroll ~= scrollInstance then return false, "required_scroll" end

    local spell = WO.Spells.Get(spellId)

    if not spell then return false, "unknown_spell" end
    if char.class ~= "mage" then
        WO.Notify(ply, "error", "Изучать заклинания может только маг.")
        return false, "class"
    end

    local scrollDef = WO.Items.Get(scrollInstance.class)
    local scrollData = scrollDef and scrollDef.spellScroll
    local targetRank = scrollData and math.floor(tonumber(scrollData.targetRank) or 0) or 0

    if not scrollData or scrollData.spellId ~= spellId or targetRank < 1 or
        targetRank > spell.maxRank or
        scrollInstance.class ~= WO.Spells.GetScrollClass(spellId, targetRank) then
        return false, "wrong_scroll"
    end

    local book = EnsureBook(char)
    local currentRank = WO.Spells.GetRank(char, spellId)

    if targetRank <= currentRank then
        WO.Notify(ply, "error", "У вас уже изучен этот ранг или более высокий.")
        return false, "rank_already_known"
    end

    local requiredLevel = spell.requiredLevel + targetRank - 1
    local level = math.max(1, math.floor(tonumber(char.level) or 1))

    if level < requiredLevel then
        WO.Notify(ply, "error", "Для этого свитка нужен уровень " .. requiredLevel .. ".")
        return false, "level"
    end

    local pointsNeeded = targetRank - currentRank

    if WO.Spells.PointsAvailable(char) < pointsNeeded then
        WO.Notify(ply, "error", "Недостаточно очков заклинаний для этого ранга.")
        return false, "no_points"
    end

    book.ranks[spellId] = targetRank

    if not book.selected or book.selected == "" then
        book.selected = spellId
    end

    if WO.SaveQueue then WO.SaveQueue.MarkDirty(char) end
    WO.Spells.Sync(ply)
    WO.Notify(ply, "success", (currentRank == 0 and "Изучено: " or "Уровень повышен: ") ..
        spell.name .. " (" .. targetRank .. "/" .. spell.maxRank .. ")")
    WO.Hook.Run("SpellRankChanged", char, spellId, targetRank)

    return true, targetRank
end

function WO.Spells.UseScroll(ply, instance)
    if not IsValid(ply) or not ply:HasCharacter() then return false, "no_character" end
    if not istable(instance) or not isstring(instance.class) then return false, "invalid_scroll" end

    local def = WO.Items.Get(instance.class)
    local scroll = def and def.spellScroll

    if not istable(scroll) then return false, "invalid_scroll" end

    local spell = WO.Spells.Get(scroll.spellId)

    if not spell or instance.class ~= WO.Spells.GetScrollClass(scroll.spellId, scroll.targetRank) then
        return false, "invalid_scroll"
    end

    local rank = math.floor(tonumber(scroll.targetRank) or 0)
    local requiredLevel = spell.requiredLevel + rank - 1
    local char = ply:GetCharacter()

    if char.class ~= "mage" then
        WO.Notify(ply, "error", "Магические свитки может использовать только маг.")
        return false, "class"
    end

    if math.floor(tonumber(char.level) or 1) < requiredLevel then
        WO.Notify(ply, "error", "Для этого свитка нужен уровень " .. requiredLevel .. ".")
        return false, "level"
    end

    return WO.Spells.LearnOrUpgrade(ply, scroll.spellId, instance)
end

function WO.Spells.Select(ply, spellId)
    if not IsValid(ply) or not ply:HasCharacter() then return false, "no_character" end

    local char = ply:GetCharacter()
    local spell = WO.Spells.Get(spellId)

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
    if char.class ~= "mage" then return false, "class" end

    local rank = WO.Spells.GetRank(char, spellId)

    if rank <= 0 then return false, "not_learned" end

    return true, spell, rank
end

function WO.Spells.Apply(ply, spellId, target)
    local canCast, spell, rank = WO.Spells.CanCast(ply, spellId)

    if not canCast then return false, spell end

    local char = ply:GetCharacter()
    local spellPower = ply:GetStat("spellPower") or 0
    local power = spell.basePower + math.max(0, rank - 1) * spell.powerPerRank +
        spellPower * spell.spellPowerScale

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

WO.Hook.Add("CharacterLevelUp", "spells", function(char)
    local ply = char and char.player

    if IsValid(ply) then
        WO.Spells.Sync(ply)
        WO.Notify(ply, "info", "Получено очко заклинаний. Откройте книгу ПКМ.")
    end
end)
