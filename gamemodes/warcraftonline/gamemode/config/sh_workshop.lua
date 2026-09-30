--[[
    Warcraft Online — каталог Steam Workshop (общие ассеты сервера).

    Коллекция игрока: «World of Warcraft» (3801728890)
    https://steamcommunity.com/sharedfiles/filedetails/?id=3801728890
      - Basic Swords (Swords + Abilities)        3605762684 — 18 мечей с абилками (SWEP)
      - Black Wolf PlayerModel [ANIMS FIXED]     2080218553 — модель чёрного волка
      - Dark Messiah - Kha-Beleth                2326822966 — модель/NPC демона

    Коллекция моделей WoW-рас (Mailer):
      https://steamcommunity.com/sharedfiles/filedetails/?id=1911409335
      (пути моделей — в config/sh_models.lua)

    Как это работает:
      - у каждого ассета есть список КАНДИДАТОВ путей моделей/классов SWEP;
      - WO.Workshop возвращает только реально установленные (file.Exists);
      - если аддон не подписан — схемы (NPC/предметы) используют стоковые
        модели/классы, ничего не ломается;
      - чтобы подключить свой ассет: добавьте его путь в `models` ниже
        (проверить наличие можно командой `wo_models`).

    Пути моделей у этих трёх аддонов авторами не опубликованы, поэтому
    кандидаты пустые и NPC/предметы используют рабочие стоковые модели.
    После установки аддона добавьте его .mdl-путь в нужный пункт —
    схемы подхватят его автоматически.
]]

WO.Workshop = WO.Workshop or {}

WO.Workshop.Catalog = {
    -- Мечи (Basic Swords) — SWEP-классы; поле classes заполняется после
    -- установки аддона (см. список классов в spawnmenu → Weapons).
    basic_swords = {
        id = 3605762684,
        title = "Basic Swords (Swords + Abilities)",
        type = "weapons",
        url = "https://steamcommunity.com/sharedfiles/filedetails/?id=3605762684",
        classes = {
            -- Пример: "sword_fire", "sword_ice", ...
        },
    },

    -- Чёрный волк — сущность/моб для квестов и атмосферы.
    black_wolf = {
        id = 2080218553,
        title = "Black Wolf PlayerModel [ANIMS FIXED]",
        type = "model",
        url = "https://steamcommunity.com/sharedfiles/filedetails/?id=2080218553",
        models = {
            -- Добавьте путь .mdl из установленного аддона, например:
            -- "models/blackwolf/blackwolf.mdl",
        },
    },

    -- Ха-Белет — босс/NPC (дружелюдный и враждебный NPC в аддоне).
    kha_beleth = {
        id = 2326822966,
        title = "Dark Messiah of Might and Magic - Kha-Beleth",
        type = "model",
        url = "https://steamcommunity.com/sharedfiles/filedetails/?id=2326822966",
        models = {
            -- Добавьте путь .mdl из установленного аддона
        },
    },
}

---------------------------------------------------------------------------
-- API
---------------------------------------------------------------------------

--- Все существующие пути моделей ассета (в порядке кандидатов).
function WO.Workshop.Models(assetId)
    local entry = WO.Workshop.Catalog[assetId]
    local out = {}

    if not entry then return out end

    for _, path in ipairs(entry.models or {}) do
        if file.Exists(path, "GAME") then
            out[#out + 1] = path
        end
    end

    return out
end

--- Первая существующая модель ассета или fallback (стоковая модель).
function WO.Workshop.ModelOr(assetId, fallback)
    local models = WO.Workshop.Models(assetId)

    return models[1] or fallback
end

--- Зарегистрирован ли SWEP-класс из ассета.
function WO.Workshop.HasClass(assetId, class)
    local entry = WO.Workshop.Catalog[assetId]

    if not entry then return false end

    for _, cls in ipairs(entry.classes or {}) do
        if cls == class then
            return weapons.GetStored(class) ~= nil
        end
    end

    return false
end

--- Первая существующая модель для NPC (кандидаты ассета + свои кандидаты + fallback).
function WO.Workshop.ModelFor(assetId, extraCandidates, fallback)
    for _, path in ipairs(WO.Workshop.Models(assetId)) do
        return path
    end

    for _, path in ipairs(extraCandidates or {}) do
        if file.Exists(path, "GAME") then
            return path
        end
    end

    return fallback
end

WO.Log("Workshop catalog: " .. table.Count(WO.Workshop.Catalog) .. " assets")
