--[[
    Warcraft Online — каталог моделей WoW (Mailer, Steam Workshop).

    Источник путей — описания самих аддонов автора Mailer из коллекции
    «[WoW] Playable Races Collection» (id 1911409335), колонка «Path»:
    базовые модели и диапазоны expansion-паков указаны в описаниях каждого пака.

    Принцип работы каталога:
      1) список кандидатов строится из путей-шаблонов ниже;
      2) оставляются только реально существующие файлы (file.Exists, "GAME") —
         если expansion-пак не подписан, его варианты просто не попадают в список;
      3) в конец списка добавляются стоковые запасные модели GMod (fallback).

    Схемы рас используют:  models = WO.Models.GetRace("human")  и т.д.
    Добавить новую расу = новая запись здесь + schemas/races/<id>.lua.

    Обозначения в шаблонах (как в описаниях аддонов):
      humanmale00_00.mdl            — базовая модель (вариант "00");
      humanmale00_[00, 09].mdl      — exp [Skin]:       humanmale00_00..09.mdl;
      humanmale00_[00, 09]_[00, 07] — exp2 [Facial Hair]: humanmale00_XX_YY.mdl.
]]

WO.Models = WO.Models or {}

--[[--------------------------------------------------------------------------]]
--[[ Каталог: race id -> gender -> описание моделей.                          ]]
--[[ workshop — id паков на Steam Workshop (см. README).                      ]]
--[[----------------------------------------------------------------------------

    Как получены пути (проверено по описаниям аддонов):
      human male    base: humanmale00_00.mdl        (1930795899)
                    exp2 : humanmale00_[00,09]_[00,07] (1930805571)
      human female  base: humanfemale00_00.mdl      (1930787430)
                    exp1 : humanfemale00_[01,09]    (1930791858)
      nightelf male base: nightelfmale00_00.mdl     (1944399771)
                    exp1 : nightelfmale00_[00,08]   (1944404675)
                    exp2 : nightelfmale00_[00,08]_[00,04] (1944409769)
      nightelf fem. base: nightelffemale00_00.mdl   (пак «[WoW] Night Elf Female»)
                    exp1 : nightelffemale00_[01,08] (1944390645)
                    exp2 : nightelffemale00_[00,08]_[00,08] (1944395669, [Markings])
      orc male      base: orcmale00_00.mdl          (1950316295)
                    exp1 : orcmale00_[01,08]        (1950319321)
      orc female    base: orcfemale00_00.mdl        (1950310689)
      gnome male    base: gnomemale00_00.mdl        (1907948872)
                    exp1 : gnomemale00_[01,04]      (1907951439)
                    exp2 : gnomemale00_[00,04]_[00,06] (1907954262)
      gnome female  base: gnomefemale00_00.mdl      (1907944015)

    Диапазоны, помеченные как "косвенный", взяты по конвенции соседних паков
    того же автора; file.Exists на сервере/клиенте отсекает несуществующие файлы,
    поэтому ошибочный диапазон не ломает ничего — просто не даёт лишних вариантов.
------------------------------------------------------------------------------]]

WO.Models.Catalog = {
    human = {
        label = "Человек (WoW Human)",
        male = {
            workshop = { 1930795899, 1930800507, 1930805571 },
            base = "models/mailer/character/human/male/humanmale00_00.mdl",
            anim = "models/mailer/character/human/male/humanmale_anim.mdl",
            variants = {
                -- exp [Skin] (1930800507): диапазон косвенный
                { fmt = "models/mailer/character/human/male/humanmale00_%02d.mdl", ranges = { 0, 9 } },
                -- exp2 [Facial Hair] (1930805571): humanmale00_[00, 09]_[00, 07]
                { fmt = "models/mailer/character/human/male/humanmale00_%02d_%02d.mdl", ranges = { 0, 9, 0, 7 } },
            },
        },
        female = {
            workshop = { 1930787430, 1930791858 },
            base = "models/mailer/character/human/female/humanfemale00_00.mdl",
            anim = "models/mailer/character/human/female/humanfemale_anim.mdl",
            variants = {
                -- exp [Skin] (1930791858): humanfemale00_[01, 09]
                { fmt = "models/mailer/character/human/female/humanfemale00_%02d.mdl", ranges = { 1, 9 } },
            },
        },
    },

    -- Схема "elf" (Эльф) использует модели ночных эльфов WoW.
    elf = {
        label = "Ночной эльф (WoW Night Elf)",
        male = {
            workshop = { 1944399771, 1944404675, 1944409769 },
            base = "models/mailer/character/nightelf/male/nightelfmale00_00.mdl",
            anim = "models/mailer/character/nightelf/male/nightelfmale_anim.mdl",
            variants = {
                -- exp [Skin] (1944404675): nightelfmale00_[00, 08]
                { fmt = "models/mailer/character/nightelf/male/nightelfmale00_%02d.mdl", ranges = { 0, 8 } },
                -- exp2 [Facial Hair] (1944409769): nightelfmale00_[00, 08]_[00, 04]
                { fmt = "models/mailer/character/nightelf/male/nightelfmale00_%02d_%02d.mdl", ranges = { 0, 8, 0, 4 } },
            },
        },
        female = {
            workshop = { 1944390645, 1944395669 },
            base = "models/mailer/character/nightelf/female/nightelffemale00_00.mdl",
            anim = "models/mailer/character/nightelf/female/nightelffemale_anim.mdl",
            variants = {
                -- exp [Skin] (1944390645): nightelffemale00_[01, 08]
                { fmt = "models/mailer/character/nightelf/female/nightelffemale00_%02d.mdl", ranges = { 1, 8 } },
                -- exp2 [Markings] (1944395669): nightelffemale00_[00, 08]_[00, 08]
                { fmt = "models/mailer/character/nightelf/female/nightelffemale00_%02d_%02d.mdl", ranges = { 0, 8, 0, 8 } },
            },
        },
    },

    orc = {
        label = "Орк (WoW Orc)",
        male = {
            workshop = { 1950316295, 1950319321 },
            base = "models/mailer/character/orc/male/orcmale00_00.mdl",
            anim = "models/mailer/character/orc/male/orcmale_anim.mdl",
            variants = {
                -- exp [Skin] (1950319321): orcmale00_[01, 08]
                { fmt = "models/mailer/character/orc/male/orcmale00_%02d.mdl", ranges = { 1, 8 } },
            },
        },
        female = {
            workshop = { 1950310689 },
            base = "models/mailer/character/orc/female/orcfemale00_00.mdl",
            anim = "models/mailer/character/orc/female/orcfemale_anim.mdl",
            variants = {
                -- exp [Skin] (пак «[WoW] Orc Female Expansion Pack [Skin]»): диапазон косвенный
                { fmt = "models/mailer/character/orc/female/orcfemale00_%02d.mdl", ranges = { 1, 8 } },
            },
        },
    },

    -- Схема "dwarf" в игре — Гном (male-only).
    dwarf = {
        label = "Гном (WoW Gnome)",
        male = {
            workshop = { 1907948872, 1907951439, 1907954262 },
            base = "models/mailer/character/gnome/male/gnomemale00_00.mdl",
            anim = "models/mailer/character/gnome/male/gnomemale_anim.mdl",
            variants = {
                -- exp [Skin] (1907951439): gnomemale00_[01, 04]
                { fmt = "models/mailer/character/gnome/male/gnomemale00_%02d.mdl", ranges = { 1, 4 } },
                -- exp2 [Facial Hair] (1907954262): gnomemale00_[00, 04]_[00, 06]
                { fmt = "models/mailer/character/gnome/male/gnomemale00_%02d_%02d.mdl", ranges = { 0, 4, 0, 6 } },
            },
        },
        female = {
            workshop = { 1907944015, 1907946461 },
            base = "models/mailer/character/gnome/female/gnomefemale00_00.mdl",
            anim = "models/mailer/character/gnome/female/gnomefemale_anim.mdl",
            variants = {
                -- exp [Skin] (1907946461): диапазон косвенный
                { fmt = "models/mailer/character/gnome/female/gnomefemale00_%02d.mdl", ranges = { 1, 4 } },
            },
        },
    },
}

--[[--------------------------------------------------------------------------]]
--[[ Стоковые запасные модели (используются всегда — и когда аддонов нет,     ]]
--[[ и как вариант «без паков» в конце списка).                               ]]
--[[----------------------------------------------------------------------------
    Списки соответствуют прежним моделям из schemas/races/*.lua, чтобы поведение
    без установленных аддонов Mailer не изменилось.
------------------------------------------------------------------------------]]

WO.Models.Fallbacks = {
    human = {
        male = {
            "models/player/group01/male_01.mdl",
            "models/player/group01/male_02.mdl",
            "models/player/group01/male_03.mdl",
            "models/player/group01/male_04.mdl",
            "models/player/group01/male_05.mdl",
            "models/player/group01/male_06.mdl",
            "models/player/group01/male_07.mdl",
        },
        female = {
            "models/player/group01/female_01.mdl",
            "models/player/group01/female_02.mdl",
            "models/player/group01/female_03.mdl",
            "models/player/group01/female_04.mdl",
        },
    },
    elf = {
        male = {
            "models/player/group03/male_01.mdl",
            "models/player/group03/male_02.mdl",
            "models/player/group03/male_03.mdl",
            "models/player/group03/male_04.mdl",
        },
        female = {
            "models/player/group03/female_01.mdl",
            "models/player/group03/female_02.mdl",
            "models/player/group03/female_03.mdl",
            "models/player/mossman.mdl",
            "models/player/alyx.mdl",
        },
    },
    orc = {
        male = {
            "models/player/Combine_Soldier.mdl",
            "models/player/Combine_Super_Soldier.mdl",
            "models/player/group03/male_07.mdl",
        },
        female = {
            "models/player/Combine_Soldier.mdl",
            "models/player/group03/female_04.mdl",
        },
    },
    dwarf = {
        male = {
            "models/player/barney.mdl",
            "models/player/group03/male_05.mdl",
            "models/player/group03/male_06.mdl",
        },
        female = {
            "models/player/group03/female_01.mdl",
            "models/player/group03/female_02.mdl",
        },
    },
}

--[[--------------------------------------------------------------------------]]
--[[ API                                                                       ]]
--[[----------------------------------------------------------------------------]]

--- Существует ли файл модели (через виртуальную ФС GMod: обычные папки + .gma + Workshop).
function WO.Models.Exists(path)
    if not isstring(path) or path == "" then return false end

    return file.Exists(path, "GAME") == true
end

--- Разворачивает шаблон варианта в список путей.
-- fmt = "...%02d.mdl", ranges = { from, to }
-- fmt = "...%02d_%02d.mdl", ranges = { from, to, from2, to2 }
function WO.Models.ExpandVariant(variant)
    local out = {}
    local r = variant.ranges

    if not istable(r) or #r == 0 then
        out[1] = variant.fmt
        return out
    end

    if #r == 2 then
        for i = r[1], r[2] do
            out[#out + 1] = string.format(variant.fmt, i)
        end
    elseif #r >= 4 then
        for i = r[1], r[2] do
            for j = r[3], r[4] do
                out[#out + 1] = string.format(variant.fmt, i, j)
            end
        end
    end

    return out
end

--- Все существующие воркшоп-модели расы/пола (базовая первой), без fallback.
function WO.Models.GetWorkshopModels(raceId, gender)
    local out, seen = {}, {}
    local entry = WO.Models.Catalog[raceId] and WO.Models.Catalog[raceId][gender]

    if not entry then return out end

    local function add(path)
        if not seen[path] and WO.Models.Exists(path) then
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

--- Итоговый список моделей для схемы расы: воркшоп-модели + стоковый fallback.
-- Возвращает { male = {...}, female = {...} } в формате race.models.
function WO.Models.GetRace(raceId)
    local result = {}
    local fallbacks = WO.Models.Fallbacks[raceId] or {}

    for _, gender in ipairs({ "male", "female" }) do
        local list, seen = {}, {}

        for _, path in ipairs(WO.Models.GetWorkshopModels(raceId, gender)) do
            seen[path] = true
            list[#list + 1] = path
        end

        for _, path in ipairs(fallbacks[gender] or {}) do
            if not seen[path] then
                seen[path] = true
                list[#list + 1] = path
            end
        end

        result[gender] = list
    end

    return result
end

--- Путь анимационной модели (если пак установлен), иначе nil.
function WO.Models.GetAnim(raceId, gender)
    local entry = WO.Models.Catalog[raceId] and WO.Models.Catalog[raceId][gender]

    if entry and WO.Models.Exists(entry.anim) then
        return entry.anim
    end

    return nil
end

--- Отладочная сводка для консоли (команда wo_models).
function WO.Models.DebugDump(raceId, gender)
    local lines = {}
    local entry = WO.Models.Catalog[raceId] and WO.Models.Catalog[raceId][gender]

    lines[#lines + 1] = ("Модели %s / %s:"):format(tostring(raceId), tostring(gender))

    if entry then
        lines[#lines + 1] = ("  паки Workshop: %s"):format(table.concat(entry.workshop or {}, ", "))
        lines[#lines + 1] = ("  базовая: %s [%s]"):format(entry.base, WO.Models.Exists(entry.base) and "есть" or "нет")
        lines[#lines + 1] = ("  анимации: %s [%s]"):format(entry.anim or "-", (entry.anim and WO.Models.Exists(entry.anim)) and "есть" or "нет")
    else
        lines[#lines + 1] = "  запись в каталоге отсутствует"
    end

    local ws = WO.Models.GetWorkshopModels(raceId, gender)
    lines[#lines + 1] = ("  воркшоп-вариантов установлено: %d"):format(#ws)

    for _, path in ipairs(WO.Models.GetRace(raceId)[gender] or {}) do
        lines[#lines + 1] = ("    %s"):format(path)
    end

    return lines
end

WO.Log("Models", "Каталог моделей Mailer загружен")
