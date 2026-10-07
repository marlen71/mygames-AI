--[[
    Warcraft Online — знакомства (shared API и сетевые схемы).
    Клиент показывает только публичную расу и «Неизвестный», пока персонажи
    взаимно не познакомились. Права на изменение состояния проверяет сервер.
]]

WO.Social = WO.Social or {}
WO.Social.IntroductionModes = WO.Config.IntroductionRanges or {
    whisper = { label = "Шёпотом", range = 180 },
    talk = { label = "Разговором", range = 560 },
    shout = { label = "Криком", range = 1400 },
}

WO.Social.KnownByCharacter = WO.Social.KnownByCharacter or {}

function WO.Social.SetKnown(entries)
    WO.Social.KnownByCharacter = {}

    for _, identity in ipairs(entries or {}) do
        if istable(identity) and isstring(identity.characterId) and identity.characterId ~= "" then
            WO.Social.KnownByCharacter[identity.characterId] = identity
        end
    end
end

function WO.Social.GetKnownIdentity(ply)
    if not IsValid(ply) or not isfunction(ply.GetNW2String) then return nil end

    local characterId = ply:GetNW2String("wo_character_id", "")
    if characterId == "" then return nil end

    return WO.Social.KnownByCharacter[characterId]
end

function WO.Social.GetVisibleIdentity(ply)
    if not IsValid(ply) then return nil end

    local raceId = ply:GetNW2String("wo_race", "")
    local race = WO.Races and WO.Races.Get and WO.Races.Get(raceId)
    local known = WO.Social.GetKnownIdentity(ply)

    if not known then
        return {
            known = false,
            name = "Неизвестный",
            race = race and race.name or (raceId ~= "" and raceId or "Неизвестная раса"),
        }
    end

    local class = WO.Classes and WO.Classes.Get and WO.Classes.Get(known.classId)
    local knownRace = WO.Races and WO.Races.Get and WO.Races.Get(known.raceId)

    return {
        known = true,
        name = known.name or "Неизвестный",
        race = knownRace and knownRace.name or (known.raceId or "Неизвестная раса"),
        class = class and class.name or (known.classId or ""),
        level = math.max(1, tonumber(known.level) or 1),
    }
end

WO.Net.Register("Social.Introduce", {
    direction = "toserver",
    rate = { max = 2, window = 5 },
    write = function(mode)
        net.WriteString(mode or "")
    end,
    read = function()
        return net.ReadString()
    end,
    validate = function(ply, mode)
        if not IsValid(ply) or not ply:HasCharacter() then return false, "no_character" end
        if not istable(WO.Social.IntroductionModes[mode]) then return false, "invalid_introduction" end
        return true
    end,
    handler = function(ply, mode)
        if SERVER then WO.Social.Introduce(ply, mode) end
    end,
})

WO.Net.Register("Social.Sync", {
    direction = "toclient",
    write = function(entries)
        net.WriteTable(entries or {})
    end,
    read = function()
        return net.ReadTable()
    end,
    handler = function(_, entries)
        if CLIENT then
            WO.Social.SetKnown(entries)
            WO.Hook.Run("SocialKnownUpdated", WO.Social.KnownByCharacter)
        end
    end,
})
