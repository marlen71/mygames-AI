--[[ Warcraft Online — серверная логика взаимного знакомства. ]]

local TABLE_NAME = "wo_social_known"
WO.Social.ServerCache = WO.Social.ServerCache or {}

if WO.Database and WO.Database.RegisterMigration then
    WO.Database:RegisterMigration(3, function()
        WO.Database:Query([[CREATE TABLE IF NOT EXISTS wo_social_known (
            owner_id TEXT NOT NULL,
            known_id TEXT NOT NULL,
            name TEXT NOT NULL,
            race_id TEXT NOT NULL,
            class_id TEXT NOT NULL,
            level INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            PRIMARY KEY (owner_id, known_id)
        )]])
        WO.Database:Query("CREATE INDEX IF NOT EXISTS idx_wo_social_known_id ON wo_social_known (known_id)")
    end)
end

local function IdentitySnapshot(char)
    return {
        characterId = tostring(char.id or ""),
        name = char:GetFullName(),
        raceId = tostring(char.race or ""),
        classId = tostring(char.class or ""),
        level = math.max(1, tonumber(char:GetLevel()) or tonumber(char.level) or 1),
    }
end

local function SaveIdentity(ownerId, identity)
    if ownerId == "" or identity.characterId == "" then return false end

    WO.Social.ServerCache[ownerId] = WO.Social.ServerCache[ownerId] or {}
    WO.Social.ServerCache[ownerId][identity.characterId] = identity

    if not (WO.Database and WO.Database.Initialized) then return true end

    local ok = WO.Database:Transaction(function()
        if not WO.Database:Delete(TABLE_NAME, "owner_id = ? AND known_id = ?",
            ownerId, identity.characterId) then
            error("could not replace acquaintance row")
        end

        if not WO.Database:Insert(TABLE_NAME, {
            owner_id = ownerId,
            known_id = identity.characterId,
            name = identity.name,
            race_id = identity.raceId,
            class_id = identity.classId,
            level = identity.level,
            updated_at = os.time(),
        }) then
            error("could not insert acquaintance row")
        end
    end)

    return ok
end

local function GetKnown(ownerId)
    if ownerId == "" then return {} end

    local entries = {}
    local seen = {}

    if WO.Database and WO.Database.Initialized then
        for _, row in ipairs(WO.Database:Fetch(
            "SELECT known_id, name, race_id, class_id, level FROM " .. TABLE_NAME ..
            " WHERE owner_id = ? ORDER BY name", ownerId)) do
            local identity = {
                characterId = tostring(row.known_id or ""),
                name = tostring(row.name or ""),
                raceId = tostring(row.race_id or ""),
                classId = tostring(row.class_id or ""),
                level = math.max(1, tonumber(row.level) or 1),
            }

            if identity.characterId ~= "" then
                entries[#entries + 1] = identity
                seen[identity.characterId] = true
            end
        end
    end

    for characterId, identity in pairs(WO.Social.ServerCache[ownerId] or {}) do
        if not seen[characterId] then entries[#entries + 1] = identity end
    end

    table.sort(entries, function(a, b)
        if a.name ~= b.name then return a.name < b.name end
        return a.characterId < b.characterId
    end)

    return entries
end

function WO.Social.Sync(ply)
    if not IsValid(ply) then return end

    local char = ply:GetCharacter()
    local entries = char and GetKnown(tostring(char.id or "")) or {}
    WO.Net.Send("Social.Sync", ply, entries)
end

function WO.Social.Introduce(ply, mode)
    if not IsValid(ply) or not ply:HasCharacter() then return false end

    local modeDef = WO.Social.IntroductionModes[mode]
    if not istable(modeDef) then return false end

    local speakerChar = ply:GetCharacter()
    local speaker = IdentitySnapshot(speakerChar)
    if speaker.characterId == "" then return false end

    local introduced = 0

    for _, target in ipairs(player.GetAll()) do
        if target ~= ply and IsValid(target) and target:HasCharacter() and
            ply:GetPos():Distance(target:GetPos()) <= modeDef.range then
            local targetChar = target:GetCharacter()
            local targetIdentity = targetChar and IdentitySnapshot(targetChar)

            if targetIdentity and targetIdentity.characterId ~= "" then
                SaveIdentity(targetIdentity.characterId, speaker)
                SaveIdentity(speaker.characterId, targetIdentity)
                WO.Social.Sync(target)
                WO.Social.Sync(ply)

                WO.Notify(target, "info", speaker.name .. " представился вам (" .. modeDef.label .. ").")
                WO.Notify(ply, "success", "Вы познакомились с " .. targetIdentity.name ..
                    " (" .. modeDef.label .. ").")
                introduced = introduced + 1
                WO.Hook.Run("SocialIntroduction", ply, target, mode, modeDef.range)
            end
        end
    end

    if introduced == 0 then
        WO.Notify(ply, "info", "В радиусе " .. modeDef.label:lower() .. " никого нет.")
    end

    return true, introduced
end

WO.Hook.Add("DatabaseReady", "social_sync_database", function()
    for _, ply in ipairs(player.GetAll()) do WO.Social.Sync(ply) end
end)

WO.Hook.Add("CharacterLoaded", "social_sync_character", function(_, ply)
    if IsValid(ply) then WO.Social.Sync(ply) end
end)

WO.Hook.Add("CharacterSelected", "social_sync_selected", function(_, ply)
    if IsValid(ply) then WO.Social.Sync(ply) end
end)

WO.Hook.Add("CharacterUnloaded", "social_clear_character", function(_, ply)
    if IsValid(ply) then WO.Net.Send("Social.Sync", ply, {}) end
end)

WO.Hook.Add("CharacterDeleted", "social_delete_character", function(characterId)
    characterId = tostring(characterId or "")
    if characterId == "" then return end

    WO.Social.ServerCache[characterId] = nil
    for _, identities in pairs(WO.Social.ServerCache) do identities[characterId] = nil end

    if WO.Database and WO.Database.Initialized then
        WO.Database:Delete(TABLE_NAME, "owner_id = ?", characterId)
        WO.Database:Delete(TABLE_NAME, "known_id = ?", characterId)
    end
end)
