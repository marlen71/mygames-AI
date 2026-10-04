--[[
    Warcraft Online — явный каталог моделей персонажей Mailer.

    Превью и allowlist рас используют только пути из каталога ниже: без
    file.Exists/util.IsValidModel, player_manager-сканирования и Workshop
    discovery. Путь передаётся DModelPanel / Player:SetModel напрямую.

    Гражданские модели намеренно не используются как fallback.
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

    Пути Mailer передаются как обычные модельные пути без проверки локального
    наличия: смонтированный контент может быть доступен DModelPanel даже если
    file.Exists/util.IsValidModel не распознаёт его.
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
    goblin = {
        label = "Гоблин (WoW Goblin)",
        male = {
            base = "models/mailer/character/goblin/male/goblinmale00_00.mdl",
            anim = "models/mailer/character/goblin/male/goblinmale_anim.mdl",
        },
        female = {
            base = "models/mailer/character/goblin/female/goblinfemale00_00.mdl",
            anim = "models/mailer/character/goblin/female/goblinfemale_anim.mdl",
        },
    },
    tauren = {
        label = "Таурен (WoW Tauren)",
        male = {
            base = "models/mailer/character/tauren/male/taurenmale00_00.mdl",
            anim = "models/mailer/character/tauren/male/taurenmale_anim.mdl",
        },
        female = {
            base = "models/mailer/character/tauren/female/taurenfemale00_00.mdl",
            anim = "models/mailer/character/tauren/female/taurenfemale_anim.mdl",
        },
    },
    troll = {
        label = "Тролль (WoW Troll)",
        male = {
            base = "models/mailer/character/troll/male/trollmale00_00.mdl",
            anim = "models/mailer/character/troll/male/trollmale_anim.mdl",
        },
        female = {
            base = "models/mailer/character/troll/female/trollfemale00_00.mdl",
            anim = "models/mailer/character/troll/female/trollfemale_anim.mdl",
        },
    },
    undead = {
        label = "Нежить (WoW Scourge)",
        male = {
            base = "models/mailer/character/scourge/male/scourgemale00_00.mdl",
            anim = "models/mailer/character/scourge/male/scourgemale_anim.mdl",
        },
        female = {
            base = "models/mailer/character/scourge/female/scourgefemale00_00.mdl",
            anim = "models/mailer/character/scourge/female/scourgefemale_anim.mdl",
        },
    },
    dwarf = {
        label = "Дворф",
        male = {
            base = "models/mailer/wow/character/dwarf/male/dwarfmale_00_00_hd.mdl",
        },
        female = {
            base = "models/mailer/wow/character/dwarf/female/dwarffemale_00_00_hd.mdl",
        },
    },
    bloodelf = {
        label = "Кровавый эльф",
        special = true,
        male = {
            base = "models/mailer/wow/character/bloodelf/male/bloodelfmale_00_00_hd.mdl",
        },
        female = {
            base = "models/mailer/wow/character/bloodelf/female/bloodelffemale_00_00_hd.mdl",
        },
    },
    dracthyr = {
        label = "Драктир",
        special = true,
        male = {
            base = "models/mailer/wow/character/dracthyr/dracthyrdragon_00_00_hd_l.mdl",
            paths = { "models/mailer/wow/character/dracthyr/dracthyrdragon_00_00_c_l.mdl" },
        },
        female = {
            base = "models/mailer/wow/character/dracthyr/dracthyrdragon_00_00_hd_l.mdl",
            paths = { "models/mailer/wow/character/dracthyr/dracthyrdragon_00_00_c_l.mdl" },
        },
    },
    draenei = {
        label = "Дреней",
        male = {
            base = "models/mailer/wow/character/draenei/male/draeneimale_00_00_hd.mdl",
        },
        female = {
            base = "models/mailer/wow/character/draenei/female/draeneifemale_00_00_hd.mdl",
        },
    },
    pandaren = {
        label = "Пандарен",
        male = {
            base = "models/mailer/character/pandaren/male/pandarenmale00_00.mdl",
            variants = {
                { fmt = "models/mailer/character/pandaren/male/pandarenmale%02d_%02d.mdl", ranges = { 0, 5, 0, 2 } },
            },
        },
        female = {
            base = "models/mailer/character/pandaren/female/pandarenfemale00_00.mdl",
            variants = {
                { fmt = "models/mailer/character/pandaren/female/pandarenfemale%02d_%02d.mdl", ranges = { 0, 3, 0, 4 } },
            },
        },
    },
    worgen = {
        label = "Ворген",
        male = {
            base = "models/mailer/character/worgen/male/worgenmale00_00.mdl",
        },
        female = {
            base = "models/mailer/character/worgen/female/worgenfemale00_00.mdl",
        },
    },
    vulpera = {
        label = "Вульпера",
        special = true,
        male = {
            base = "models/mailer/wow_characters/wowanim_vulpera_male.mdl",
        },
        female = {
            base = "models/mailer/wow_characters/wowanim_vulpera_female.mdl",
        },
    },
    sethrak = {
        label = "Сетрак",
        male = {
            base = "models/mailer/wow_characters/wowanim_sethrak.mdl",
        },
        female = {
            base = "models/mailer/wow_characters/wowanim_sethrak.mdl",
        },
    },
    naga = {
        label = "Нага",
        male = {
            base = "models/mailer/wow_characters/wowanim_naga_male.mdl",
        },
        female = {
            base = "models/mailer/wow_characters/wowanim_naga_female.mdl",
        },
    },
}

---------------------------------------------------------------------------
-- API
---------------------------------------------------------------------------

--- Optional diagnostics only; this result never gates character selection or preview.
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

--- Explicitly configured Mailer model paths, base model first; no disk or registry scan.
function WO.Models.GetConfiguredModels(raceId, gender)
    local out, seen = {}, {}
    local entry = WO.Models.Catalog[raceId] and WO.Models.Catalog[raceId][gender]

    if not entry then return out end

    local function add(path)
        if isstring(path) and path ~= "" and not seen[path] then
            seen[path] = true
            out[#out + 1] = path
        end
    end

    add(entry.base)

    for _, path in ipairs(entry.paths or {}) do
        add(path)
    end

    for _, variant in ipairs(entry.variants or {}) do
        for _, path in ipairs(WO.Models.ExpandVariant(variant)) do
            add(path)
        end
    end

    return out
end

--- Deprecated compatibility API. Race choices are deliberately not discovered.
function WO.Models.GetLocalPlayerModels()
    return {}
end

--- The race allowlist comes only from explicit paths in the data-driven catalog.
function WO.Models.GetRace(raceId)
    local result = {}

    for _, gender in ipairs({ "male", "female" }) do
        result[gender] = WO.Models.GetConfiguredModels(raceId, gender)
    end

    return result
end

--- Rebuild race model allowlists from the static catalog after schema/config updates.
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

    return entry and entry.anim or nil
end

--- Diagnostics for `wo_models`; local presence never affects character model choices.
function WO.Models.DebugDump(raceId, gender)
    local lines = {}
    local entry = WO.Models.Catalog[raceId] and WO.Models.Catalog[raceId][gender]
    local configured = WO.Models.GetConfiguredModels(raceId, gender)

    lines[#lines + 1] = ("Настроенные модели %s / %s:"):format(tostring(raceId), tostring(gender))

    if entry then
        lines[#lines + 1] = ("  базовая: %s"):format(entry.base)
        lines[#lines + 1] = ("  анимации: %s"):format(entry.anim or "-")
    else
        lines[#lines + 1] = "  пути для этой расы/пола не заданы в каталоге"
    end

    lines[#lines + 1] = ("  записей в каталоге=%d; локальный статус не ограничивает выбор"):format(#configured)

    for _, path in ipairs(configured) do
        lines[#lines + 1] = ("    %s"):format(path)
    end

    return lines
end

WO.Log("Models", "Локальный каталог моделей персонажей загружен")
