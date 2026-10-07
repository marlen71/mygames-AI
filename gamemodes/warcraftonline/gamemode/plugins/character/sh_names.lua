--[[
    Warcraft Online — race-themed character-name generator.

    Name pools live in schemas/names/<race>.lua so adding or adjusting a race's
    vocabulary does not require editing the UI or the registry implementation.
]]

WO.CharacterNames = WO.CharacterNames or {}
WO.CharacterNames.Registry = WO.CharacterNames.Registry or {}
WO.CharacterNames.LastSelection = WO.CharacterNames.LastSelection or {}

local function CopyValidNames(values, label)
    if not istable(values) then return nil end

    local clean = {}

    for _, value in ipairs(values) do
        if isstring(value) and WO.Util.IsValidName(value) then
            clean[#clean + 1] = value
        else
            WO.Warn("CharacterNames: skipped invalid " .. label .. " entry")
        end
    end

    return #clean > 0 and clean or nil
end

--- Register a data-driven pool of given names and surnames for one race.
function WO.CharacterNames.Register(raceID, definition)
    if not isstring(raceID) or raceID == "" or not istable(definition) then
        return false
    end

    local givenNames = istable(definition.givenNames) and definition.givenNames or {}
    local male = CopyValidNames(givenNames.male, raceID .. " male name")
    local female = CopyValidNames(givenNames.female, raceID .. " female name")
    local surnames = CopyValidNames(definition.surnames, raceID .. " surname")

    if not male or not female or not surnames then
        WO.Warn("CharacterNames: incomplete name pools for race '" .. raceID .. "'")
        return false
    end

    WO.CharacterNames.Registry[raceID] = {
        givenNames = { male = male, female = female },
        surnames = surnames,
    }

    return true
end

--- Return a copy of a race's available pools.
function WO.CharacterNames.Get(raceID)
    local entry = WO.CharacterNames.Registry[raceID]
    if not entry then return nil end

    return table.Copy(entry)
end

local function Pick(pool, key)
    if not istable(pool) or #pool == 0 then return nil end

    local index = math.random(#pool)
    local previous = WO.CharacterNames.LastSelection[key]

    -- Avoid repeating the same item on consecutive clicks when there is a choice.
    if #pool > 1 and previous == index then
        index = (index % #pool) + 1
    end

    WO.CharacterNames.LastSelection[key] = index
    return pool[index]
end

--- Generate a first name or surname for a race. Returns nil when no pool exists.
function WO.CharacterNames.Generate(raceID, field, gender)
    local entry = WO.CharacterNames.Registry[raceID]
    if not entry then return nil, "unknown_race" end

    if field == "name" or field == "givenName" or field == "given_name" then
        local normalizedGender = gender == "female" and "female" or "male"
        return Pick(entry.givenNames[normalizedGender], raceID .. ":" .. normalizedGender)
    elseif field == "surname" or field == "familyName" or field == "family_name" then
        return Pick(entry.surnames, raceID .. ":surname")
    end

    return nil, "unknown_field"
end
