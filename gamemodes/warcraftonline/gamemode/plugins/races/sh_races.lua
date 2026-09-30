--[[
    Warcraft Online — система рас (shared).
    Data-driven: новая раса добавляется файлом в schemas/races/ без изменения ядра.

    WO.Races:Register({
        id = "human",
        name = "Человек",
        description = "...",

        models = {
            male = { "models/player/group01/male_01.mdl", ... },
            female = { "models/player/group01/female_01.mdl", ... },
        },

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
    def.modelScale = def.modelScale or 1

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
            return true
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
