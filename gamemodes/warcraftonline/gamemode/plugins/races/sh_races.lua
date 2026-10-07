--[[
    Warcraft Online — система рас (shared).
    Data-driven: новая раса добавляется файлом в schemas/races/ без изменения ядра.

    WO.Races:Register({
        id = "human",
        name = "Человек",
        description = "...",

        models = WO.Models.GetRace("human"), -- явные race/gender пути, без citizen fallback

        genders = { "male", "female" },
        modelScale = 1,

        stats = {
            strength = 10, agility = 10, intelligence = 10,
            stamina = 10, spirit = 10,
        },

        modifiers = {},   -- будущие модификаторы

        classes = { "warrior", "mage" },  -- nil = все классы доступны

        customization = {
            bodygroups = {},   -- кастомные ограничения (см. WO.Customization)
        },
    })
]]

WO.Races.Registry = WO.Races.Registry or WO.Registry.New("Races")

--[[
    Регистрирует расу.

    @param def table определение расы
    @return boolean success
]]
function WO.Races.Register(def)
    if not istable(def) or not isstring(def.id) then
        WO.Error("WO.Races.Register: invalid race definition")
        return false
    end

    def.name = def.name or def.id
    def.models = def.models or {}
    def.genders = def.genders or { "male", "female" }
    def.stats = def.stats or {}
    def.professionBonuses = istable(def.professionBonuses) and def.professionBonuses or {}
    def.magicBonuses = istable(def.magicBonuses) and def.magicBonuses or {}
    def.modelScale = def.modelScale or 1

    local configuredFactions = WO.Config and WO.Config.RaceFactions and WO.Config.RaceFactions[def.id]
    if istable(configuredFactions) then def.factions = table.Copy(configuredFactions) end

    local configuredClasses = WO.Config and WO.Config.RaceClassAllowlist and WO.Config.RaceClassAllowlist[def.id]
    if istable(configuredClasses) then def.classes = table.Copy(configuredClasses) end

    def.factions = istable(def.factions) and def.factions or {}

    return WO.Races.Registry:Register(def.id, def)
end

--- Получить расу по id.
function WO.Races.Get(id)
    return WO.Races.Registry:Get(id)
end

--- Все расы.
function WO.Races.GetAll()
    return WO.Races.Registry:GetAll()
end

--- Список id рас.
function WO.Races.GetIDs()
    return WO.Races.Registry:GetIDs()
end

function WO.Races.IsFactionAllowed(raceId, factionId)
    local race = WO.Races.Get(raceId)
    if not race or not isstring(factionId) then return false end

    for _, allowedFaction in ipairs(race.factions or {}) do
        if allowedFaction == factionId then return true end
    end

    return false
end

function WO.Races.GetDefaultFaction(raceId)
    local race = WO.Races.Get(raceId)
    return race and race.factions and race.factions[1] or nil
end

function WO.Races.GetFactionRaces(factionId, player)
    local out = {}
    local order = WO.Config and WO.Config.FactionRaceOrder and WO.Config.FactionRaceOrder[factionId]
    local candidates = istable(order) and order or WO.Races.GetIDs()

    for _, raceId in ipairs(candidates) do
        if WO.Races.IsFactionAllowed(raceId, factionId) and WO.Races.CanCreate(raceId, player) then
            out[#out + 1] = raceId
        end
    end

    return out
end

--- Раса отмечена как особая и требует серверного допуска.
function WO.Races.IsSpecial(raceId)
    local race = WO.Races.Get(raceId)

    return race ~= nil and race.special == true
end

--- Проверяет право создать персонажа выбранной расы; клиентская проверка только для UI.
function WO.Races.CanCreate(raceId, ply)
    local race = WO.Races.Get(raceId)

    if not race then return false end
    if race.special ~= true then return true end

    return WO.Admin and isfunction(WO.Admin.IsAdmin) and WO.Admin.IsAdmin(ply) == true or false
end

--[[
    Доступен ли класс для расы.

    @param raceId string
    @param classId string
    @return boolean
]]
function WO.Races.IsClassAllowed(raceId, classId)
    local race = WO.Races.Get(raceId)

    if not race then return false end

    if not race.classes then
        return true -- без ограничений
    end

    for _, id in ipairs(race.classes) do
        if id == classId then
            return true
        end
    end

    return false
end

--[[
    Доступна ли модель для расы и пола.

    @param raceId string
    @param gender string
    @param model string
    @return boolean
]]
function WO.Races.IsModelAllowed(raceId, gender, model)
    local race = WO.Races.Get(raceId)

    if not race then return false end

    local list = race.models and race.models[gender]

    if not istable(list) then return false end

    for _, path in ipairs(list) do
        if path == model then
            return true
        end
    end

    return false
end

--[[
    Список моделей расы для пола.

    @param raceId string
    @param gender string
    @return table массив путей моделей
]]
function WO.Races.GetModels(raceId, gender)
    local race = WO.Races.Get(raceId)

    if not race then return {} end

    return (race.models and race.models[gender]) or {}
end

--- Полы, для которых у расы настроен хотя бы один явный путь модели.
function WO.Races.GetAvailableGenders(raceId)
    local race = WO.Races.Get(raceId)
    local out = {}

    if not race then return out end

    for _, gender in ipairs(race.genders or {}) do
        if #WO.Races.GetModels(raceId, gender) > 0 then
            out[#out + 1] = gender
        end
    end

    return out
end

--- Проверяет, входит ли путь в явный race/gender allowlist.
function WO.Races.IsPlayableModel(model)
    if not isstring(model) or model == "" then return false end

    for raceId, race in pairs(WO.Races.GetAll()) do
        for _, gender in ipairs(race.genders or {}) do
            if WO.Races.IsModelAllowed(raceId, gender, model) then
                return true
            end
        end
    end

    return false
end

--[[
    Доступен ли пол для расы.

    @param raceId string
    @param gender string
    @return boolean
]]
function WO.Races.IsGenderAllowed(raceId, gender)
    local race = WO.Races.Get(raceId)

    if not race then return false end

    for _, g in ipairs(race.genders or {}) do
        if g == gender then
            return #WO.Races.GetModels(raceId, gender) > 0
        end
    end

    return false
end

--[[
    Базовые характеристики расы.

    @param raceId string
    @return table
]]
function WO.Races.GetStats(raceId)
    local race = WO.Races.Get(raceId)

    return (race and race.stats) or {}
end
