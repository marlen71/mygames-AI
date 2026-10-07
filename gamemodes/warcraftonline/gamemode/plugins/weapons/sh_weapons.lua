--[[
    Warcraft Online — регистрация оружия (shared).
    WO.Weapons.Register(SWEP, "wo_sword_iron") — с гарантированным наследованием
    от SWEP.Base, защитой от циклических баз и повторной регистрации.
]]

WO.Weapons = WO.Weapons or {}
WO.Weapons.RegistrationCache = WO.Weapons.RegistrationCache or {}

local function CopyDefinition(value, seen)
    if type(value) ~= "table" then return value end

    seen = seen or {}

    if seen[value] then return seen[value] end

    local copy = {}
    seen[value] = copy

    for key, child in pairs(value) do
        copy[CopyDefinition(key, seen)] = CopyDefinition(child, seen)
    end

    return copy
end

-- Functions are closures recreated when GMod or the WO loader includes a SWEP
-- again. Their identity is not useful for duplicate-load detection; the
-- surrounding data shape and every non-function value must still match.
local function SameDefinition(left, right, seen)
    if left == right then return true end
    if type(left) ~= type(right) then return false end
    if type(left) == "function" then return true end
    if type(left) ~= "table" then return false end

    seen = seen or {}

    if seen[left] == right then return true end
    seen[left] = right

    for key, value in pairs(left) do
        if not SameDefinition(value, right[key], seen) then return false end
    end

    for key in pairs(right) do
        if left[key] == nil then return false end
    end

    return true
end

local function MergeBase(sWEP, baseName, visiting, depth)
    if not isstring(baseName) or baseName == "" or baseName == "weapon_base" then
        return sWEP
    end

    visiting = visiting or {}
    depth = depth or 0

    if depth >= 32 then
        return nil, "base chain exceeds 32 classes"
    end

    if visiting[baseName] then
        return nil, "cyclic base chain at '" .. baseName .. "'"
    end

    local base = weapons.GetStored(baseName)

    if not base then
        return nil, "missing base '" .. baseName .. "'"
    end

    visiting[baseName] = true

    local inherited = base

    if isstring(base.Base) and base.Base ~= "" and base.Base ~= "weapon_base" then
        local merged, reason = MergeBase(base, base.Base, visiting, depth + 1)

        if not merged then
            visiting[baseName] = nil
            return nil, reason
        end

        inherited = merged
    end

    visiting[baseName] = nil

    local merged = {}

    -- Сначала поля базы, затем собственные (собственные приоритетнее).
    for key, value in pairs(inherited) do
        merged[key] = value
    end

    for key, value in pairs(sWEP) do
        merged[key] = value
    end

    return merged
end

--[[
    Регистрирует SWEP с наследованием от SWEP.Base.

    @param sWEP table таблица оружия
    @param name string класс оружия
    @return boolean success
]]
function WO.Weapons.Register(sWEP, name)
    if not istable(sWEP) or not isstring(name) or name == "" then
        WO.Error("WO.Weapons.Register: invalid arguments")
        return false
    end

    if isstring(sWEP.Base) and sWEP.Base ~= "" and sWEP.Base ~= "weapon_base" then
        local merged, reason = MergeBase(sWEP, sWEP.Base, { [name] = true })

        if not merged then
            WO.Error("WO.Weapons.Register: cannot register '" .. name .. "': " .. tostring(reason))
            return false
        end

        sWEP = merged
    end

    sWEP.Base = "weapon_base"

    if sWEP.UseHands == nil then
        sWEP.UseHands = true
    end

    sWEP.Spawnable = false
    sWEP.AdminSpawnable = false

    local previous = WO.Weapons.RegistrationCache[name]

    if previous and SameDefinition(previous, sWEP) and weapons.GetStored(name) then
        WO.Debug("Duplicate weapon include ignored: " .. name)
        return true
    end

    if weapons.GetStored(name) then
        WO.Warn("WO.Weapons.Register: replacing changed weapon definition '" .. name .. "'")
    end

    -- Snapshot before weapons.Register: the engine may append runtime metadata
    -- (for example ClassName) to the input table after this call.
    WO.Weapons.RegistrationCache[name] = CopyDefinition(sWEP)
    weapons.Register(sWEP, name)

    WO.Debug("Weapon registered: " .. name)

    return true
end
