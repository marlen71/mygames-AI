--[[
    Warcraft Online — общая часть книги заклинаний.
    Данные заклинаний живут в schemas/spells; изучение, выбор и применение
    проходят через серверную валидацию.
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

    WO.Spells.Registry[def.id] = def
    return true
end

function WO.Spells.Get(id)
    return WO.Spells.Registry[id]
end

function WO.Spells.GetAll()
    return WO.Spells.Registry
end

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
    handler = function(ply, spellId)
        if SERVER and WO.Spells.LearnOrUpgrade then WO.Spells.LearnOrUpgrade(ply, spellId) end
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
