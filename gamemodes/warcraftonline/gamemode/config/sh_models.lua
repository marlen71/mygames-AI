--[[
    Warcraft Online — каталог локально доступных моделей персонажей Mailer.

    Список берётся из проверенных model paths в каталоге ниже и из GMod's
    player_manager.AllValidModels(). Никакие Workshop API, Workshop ID или
    Workshop discovery-плагины для регистрации/превью персонажей не требуются:
    путь добавляется только если сам .mdl доступен в локальной виртуальной ФС.

    GMod-гражданские модели намеренно не используются как fallback.
    Схемы рас используют: models = WO.Models.GetRace("human") и т.д.

    Обозначения в шаблонах:
      humanmale00_00.mdl            — базовая модель (вариант "00");
      humanmale00_[00, 09].mdl      — варианты с разными скинами;
      humanmale00_[00, 09]_[00, 07] — дополнительные варианты лица/волос.
]]

WO.Models = WO.Models or {}

--[[--------------------------------------------------------------------------]]
--[[ Каталог: race id -> gender -> описания моделей.                          ]]
--[[----------------------------------------------------------------------------

    Пути Mailer сохранены как обычные модельные пути. В рантайме ничего не
    скачивается и не запрашивается у Workshop: локальное наличие проверяется
    отдельно через file.Exists/util.IsValidModel.
------------------------------------------------------------------------------]]

WO.Models.Catalog = {
    human = {
        label = "Человек (WoW Human)",
        male = {
            base = "models/mailer/character/human/male/humanmale00_00.mdl",
            anim = "models/mailer/character/human/male/humanmale_anim.mdl",
            variants = {
                { fmt = "models/mailer/character/human/male/humanmale00_%02d.mdl", ranges = { 0, 9 } },
                { fmt = "models/mailer/character/human/male/humanmale00_%02d_%02d.mdl", ranges = { 0, 9, 0, 7 } },
            },
        },
        female = {
            base = "models/mailer/character/human/female/humanfemale00_00.mdl",
            anim = "models/mailer/character/human/female/humanfemale_anim.mdl",
            variants = {
                { fmt = "models/mailer/character/human/female/humanfemale00_%02d.mdl", ranges = { 1, 9 } },
            },
        },
    },
    elf = {
        label = "Ночной эльф (WoW Night Elf)",
        male = {
            base = "models/mailer/character/nightelf/male/nightelfmale00_00.mdl",
            anim = "models/mailer/character/nightelf/male/nightelfmale_anim.mdl",
            variants = {
                { fmt = "models/mailer/character/nightelf/male/nightelfmale00_%02d.mdl", ranges = { 0, 8 } },
                { fmt = "models/mailer/character/nightelf/male/nightelfmale00_%02d_%02d.mdl", ranges = { 0, 8, 0, 4 } },
            },
        },
        female = {
            base = "models/mailer/character/nightelf/female/nightelffemale00_00.mdl",
            anim = "models/mailer/character/nightelf/female/nightelffemale_anim.mdl",
            variants = {
                { fmt = "models/mailer/character/nightelf/female/nightelffemale00_%02d.mdl", ranges = { 1, 8 } },
                { fmt = "models/mailer/character/nightelf/female/nightelffemale00_%02d_%02d.mdl", ranges = { 0, 8, 0, 8 } },
            },
        },
    },
    orc = {
        label = "Орк (WoW Orc)",
        male = {
            base = "models/mailer/character/orc/male/orcmale00_00.mdl",
            anim = "models/mailer/character/orc/male/orcmale_anim.mdl",
            variants = {
                { fmt = "models/mailer/character/orc/male/orcmale00_%02d.mdl", ranges = { 1, 8 } },
            },
        },
        female = {
            base = "models/mailer/character/orc/female/orcfemale00_00.mdl",
            anim = "models/mailer/character/orc/female/orcfemale_anim.mdl",
            variants = {
                { fmt = "models/mailer/character/orc/female/orcfemale00_%02d.mdl", ranges = { 1, 8 } },
            },
        },
    },
    gnome = {
        label = "Гном (WoW Gnome)",
        male = {
            base = "models/mailer/character/gnome/male/gnomemale00_00.mdl",
            anim = "models/mailer/character/gnome/male/gnomemale_anim.mdl",
            variants = {
                { fmt = "models/mailer/character/gnome/male/gnomemale00_%02d.mdl", ranges = { 1, 4 } },
                { fmt = "models/mailer/character/gnome/male/gnomemale00_%02d_%02d.mdl", ranges = { 0, 4, 0, 6 } },
            },
        },
        female = {
            base = "models/mailer/character/gnome/female/gnomefemale00_00.mdl",
            anim = "models/mailer/character/gnome/female/gnomefemale_anim.mdl",
            variants = {
                { fmt = "models/mailer/character/gnome/female/gnomefemale00_%02d.mdl", ranges = { 1, 4 } },
            },
        },
    },
}

-- Names used only to match race/gender identifiers already present in the local
-- player_manager registry. This does not initiate Workshop downloads or queries.
WO.Models.LocalSearchTerms = {
    human = { "human" },
    elf = { "night elf", "nightelf", "night_elf" },
    orc = { "orc" },
    dwarf = { "dwarf" },
    gnome = { "gnome" },
    undead = { "undead", "scourge", "forsaken" },
    tauren = { "tauren" },
    troll = { "troll" },
    goblin = { "goblin" },
}

-- Compatibility alias for integrations that read the older search-term name.
WO.Models.PlayerSearchTerms = WO.Models.LocalSearchTerms

---------------------------------------------------------------------------
-- API
---------------------------------------------------------------------------

--- Checks the local GMod virtual filesystem; no Workshop lookup is performed.
function WO.Models.Exists(path)
    if not isstring(path) or path == "" then return false end

    if file and isfunction(file.Exists) and file.Exists(path, "GAME") == true then
        return true
    end

    return util and isfunction(util.IsValidModel) and util.IsValidModel(path) == true or false
end

function WO.Models.ExpandVariant(variant)
    local out = {}
    local ranges = variant and variant.ranges

    if not istable(ranges) or #ranges == 0 then
        if isstring(variant and variant.fmt) then out[1] = variant.fmt end
        return out
    end

    if #ranges == 2 then
        for index = ranges[1], ranges[2] do
            out[#out + 1] = string.format(variant.fmt, index)
        end
    elseif #ranges >= 4 then
        for first = ranges[1], ranges[2] do
            for second = ranges[3], ranges[4] do
                out[#out + 1] = string.format(variant.fmt, first, second)
            end
        end
    end

    return out
end

--- Configured Mailer model paths that are present locally, base model first.
function WO.Models.GetConfiguredModels(raceId, gender)
    local out, seen = {}, {}
    local entry = WO.Models.Catalog[raceId] and WO.Models.Catalog[raceId][gender]

    if not entry then return out end

    local function add(path)
        if isstring(path) and not seen[path] and WO.Models.Exists(path) then
            seen[path] = true
            out[#out + 1] = path
        end
    end

    add(entry.base)

    for _, variant in ipairs(entry.variants or {}) do
        for _, path in ipairs(WO.Models.ExpandVariant(variant)) do
            add(path)
        end
    end

    return out
end

local function ContainsAny(text, terms)
    if not istable(terms) or #terms == 0 then return false end

    text = string.lower(tostring(text or ""))

    for _, term in ipairs(terms) do
        local value = string.lower(tostring(term or ""))

        if value ~= "" and string.find(text, value, 1, true) then
            return true
        end
    end

    return false
end

--- Match race/gender names in the local player_manager list.
function WO.Models.GetLocalPlayerModels(raceId, gender)
    local out, seen = {}, {}

    if not player_manager or not isfunction(player_manager.AllValidModels) then
        return out
    end

    local ok, models = pcall(player_manager.AllValidModels)

    if not ok or not istable(models) then return out end

    local raceTerms = WO.Models.LocalSearchTerms[raceId] or {}
    local genderTerms = gender == "female" and { "female", "woman", "fem" } or { "male", "man" }
    local excludedTerms = gender == "female" and {} or { "female", "woman", "fem" }

    for name, path in pairs(models) do
        local identity = tostring(name or "") .. " " .. tostring(path or "")

        if isstring(path) and ContainsAny(identity, raceTerms) and
            ContainsAny(identity, genderTerms) and not ContainsAny(identity, excludedTerms) and
            not seen[path] and WO.Models.Exists(path) then
            seen[path] = true
            out[#out + 1] = path
        end
    end

    table.sort(out)

    return out
end

--- Locally available race/gender models, without generic/civilian substitution.
function WO.Models.GetRace(raceId)
    local result = {}

    for _, gender in ipairs({ "male", "female" }) do
        local list, seen = {}, {}

        local function append(path)
            if isstring(path) and not seen[path] and WO.Models.Exists(path) then
                seen[path] = true
                list[#list + 1] = path
            end
        end

        for _, path in ipairs(WO.Models.GetConfiguredModels(raceId, gender)) do
            append(path)
        end

        for _, path in ipairs(WO.Models.GetLocalPlayerModels(raceId, gender)) do
            append(path)
        end

        result[gender] = list
    end

    return result
end

--- Refresh race model lists after locally available models are registered.
function WO.Models.RefreshRaceLists()
    if not (WO.Races and WO.Races.GetAll) then return false end

    for _, race in pairs(WO.Races.GetAll()) do
        if istable(race) and isstring(race.id) then
            race.models = WO.Models.GetRace(race.id)
        end
    end

    return true
end

function WO.Models.GetAnim(raceId, gender)
    local entry = WO.Models.Catalog[raceId] and WO.Models.Catalog[raceId][gender]

    if entry and WO.Models.Exists(entry.anim) then
        return entry.anim
    end

    return nil
end

--- Diagnostics for `wo_models` (all paths are already local).
function WO.Models.DebugDump(raceId, gender)
    local lines = {}
    local entry = WO.Models.Catalog[raceId] and WO.Models.Catalog[raceId][gender]

    lines[#lines + 1] = ("Локальные модели %s / %s:"):format(tostring(raceId), tostring(gender))

    if entry then
        lines[#lines + 1] = ("  базовая: %s [%s]"):format(entry.base,
            WO.Models.Exists(entry.base) and "есть" or "нет")
        lines[#lines + 1] = ("  анимации: %s [%s]"):format(entry.anim or "-",
            (entry.anim and WO.Models.Exists(entry.anim)) and "есть" or "нет")
    else
        lines[#lines + 1] = "  статический путь не задан; проверяется только local player_manager"
    end

    local configured = WO.Models.GetConfiguredModels(raceId, gender)
    local discovered = WO.Models.GetLocalPlayerModels(raceId, gender)
    lines[#lines + 1] = ("  каталог=%d, player_manager=%d"):format(#configured, #discovered)

    for _, path in ipairs(WO.Models.GetRace(raceId)[gender] or {}) do
        lines[#lines + 1] = ("    %s"):format(path)
    end

    return lines
end

WO.Log("Models", "Локальный каталог моделей персонажей загружен")
