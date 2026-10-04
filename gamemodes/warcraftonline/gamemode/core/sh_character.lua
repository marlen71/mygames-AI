--[[
    Warcraft Online — класс персонажа (shared).
    Объект персонажа + серверная валидация данных.

    Структура персонажа (см. также комментарии в sv_characters.lua):
        character = {
            id, steamid, steamid64, name, surname, fullName,
            age, gender, race, class, model,
            customization = { skin, bodygroups, color },
            level, experience, money,
            map, pos, ang,
            createdAt, lastPlayed,
            -- runtime (не сохраняются напрямую):
            player, stats, inventory, equipment
        }
]]

WO.Character = WO.Character or {}

-- Ограничения имён (переопределяются config/).
WO.Config.NameMinLength = WO.Config.NameMinLength or 2
WO.Config.NameMaxLength = WO.Config.NameMaxLength or 24
WO.Config.AgeMin = WO.Config.AgeMin or 16
WO.Config.AgeMax = WO.Config.AgeMax or 100

---------------------------------------------------------------------------
-- Класс
---------------------------------------------------------------------------

local CHARACTER = {}
CHARACTER.__index = CHARACTER

WO.Character.Meta = CHARACTER

--[[
    Создаёт объект персонажа из plain-таблицы (данные из БД или создания).

    @param data table
    @return table character
]]
function WO.Character.New(data)
    local char = setmetatable(data or {}, CHARACTER)

    char.customization = char.customization or {}
    char.customization.bodygroups = char.customization.bodygroups or {}

    return char
end

--- Проверяет, что это объект персонажа.
function WO.Character.IsCharacter(obj)
    return istable(obj) and getmetatable(obj) == CHARACTER
end

function CHARACTER:GetID()
    return self.id
end

function CHARACTER:GetSteamID()
    return self.steamid
end

function CHARACTER:GetName()
    return self.name or ""
end

function CHARACTER:GetSurname()
    return self.surname or ""
end

function CHARACTER:GetFullName()
    return (self.name or "") .. " " .. (self.surname or "")
end

function CHARACTER:GetLevel()
    return self.level or 1
end

function CHARACTER:GetXP()
    return self.experience or 0
end

function CHARACTER:GetRace()
    return self.race
end

function CHARACTER:GetClass()
    return self.class
end

function CHARACTER:GetGender()
    return self.gender
end

function CHARACTER:GetModel()
    return self.model
end

function CHARACTER:GetPlayer()
    return self.player
end

function CHARACTER:GetMoney()
    return self.money or 0
end

---------------------------------------------------------------------------
-- Валидация (server authority: клиенту не доверяем ни одному полю)
---------------------------------------------------------------------------

--[[
    Валидирует данные персонажа при создании/загрузке.

    Проверяет: name, surname, age, race, gender, class, model, customization.

    @param data table
    @param opts table { strict = true } — строгий режим для создания
    @return boolean ok, string|table reasonOrData
]]
function WO.Character.Validate(data, opts)
    opts = opts or {}

    if WO.Models and WO.Models.RefreshRaceLists then
        WO.Models.RefreshRaceLists()
    end

    if not istable(data) then
        return false, "invalid_data"
    end

    -- Имя
    local name = WO.Util.CleanString(WO.Util.StripDangerous(data.name or ""))

    if not WO.Util.IsValidName(name) then
        return false, "invalid_name"
    end

    -- Запрещённые имена
    local banned = WO.Config.BannedNames or {}

    for _, bannedName in ipairs(banned) do
        if string.lower(name) == string.lower(bannedName) then
            return false, "banned_name"
        end
    end

    -- Фамилия
    local surname = WO.Util.CleanString(WO.Util.StripDangerous(data.surname or ""))

    if not WO.Util.IsValidName(surname) then
        return false, "invalid_surname"
    end

    -- Возраст
    local age = WO.Util.ToInt(data.age, -1)

    if age < WO.Config.AgeMin or age > WO.Config.AgeMax then
        return false, "invalid_age"
    end

    -- Раса
    local race = data.race

    if not isstring(race) or not (WO.Races.Registry and WO.Races.Registry:Exists(race)) then
        return false, "invalid_race"
    end

    if opts.strict == true then
        local canCreateRace = WO.Races.CanCreate and WO.Races.CanCreate(race, opts.player)

        if canCreateRace ~= true then
            return false, "race_unavailable"
        end
    end

    -- Пол
    local gender = data.gender
    local genders = WO.Config.Genders or { "male", "female" }
    local genderOk = false

    for _, g in ipairs(genders) do
        if g == gender then
            genderOk = true
            break
        end
    end

    if not genderOk then
        return false, "invalid_gender"
    end

    -- Пол должен быть доступен расе
    if WO.Races.IsGenderAllowed and not WO.Races.IsGenderAllowed(race, gender) then
        return false, "gender_not_allowed"
    end

    -- Класс
    local class = data.class

    if not isstring(class) or not (WO.Classes.Registry and WO.Classes.Registry:Exists(class)) then
        return false, "invalid_class"
    end

    -- Совместимость расы и класса
    if WO.Races.IsClassAllowed and not WO.Races.IsClassAllowed(race, class) then
        return false, "class_not_allowed"
    end

    -- Модель (должна принадлежать расе и полу)
    local model = data.model

    if not isstring(model) or model == "" then
        return false, "invalid_model"
    end

    if WO.Races.IsModelAllowed and not WO.Races.IsModelAllowed(race, gender, model) then
        return false, "invalid_model"
    end

    -- Кастомизация
    local customization = data.customization or {}

    if not istable(customization) then
        return false, "invalid_customization"
    end

    if customization.skin ~= nil and not isnumber(customization.skin) then
        return false, "invalid_customization"
    end

    if customization.bodygroups ~= nil and not istable(customization.bodygroups) then
        return false, "invalid_customization"
    end

    return true, {
        name = name,
        surname = surname,
        age = age,
        race = race,
        gender = gender,
        class = class,
        model = model,
        customization = {
            skin = math.max(0, math.floor(tonumber(customization.skin) or 0)),
            bodygroups = istable(customization.bodygroups) and customization.bodygroups or {},
            color = istable(customization.color) and customization.color or nil,
        },
    }
end

--[[
    Проверяет данные, загруженные из БД. Повреждённые поля заменяются
    безопасными значениями (сервер не должен падать на битых данных).

    @param data table
    @return table cleanData, table warnings
]]
function WO.Character.SanitizeLoaded(data)
    local warnings = {}

    if WO.Models and WO.Models.RefreshRaceLists then
        WO.Models.RefreshRaceLists()
    end

    if not istable(data) then
        return nil, { "empty_data" }
    end

    data.name = WO.Util.CleanString(WO.Util.StripDangerous(tostring(data.name or "")))
    data.surname = WO.Util.CleanString(WO.Util.StripDangerous(tostring(data.surname or "")))

    if not WO.Util.IsValidName(data.name) then
        data.name = "Unknown"
        warnings[#warnings + 1] = "name_restored"
    end

    if not WO.Util.IsValidName(data.surname) then
        data.surname = "Hero"
        warnings[#warnings + 1] = "surname_restored"
    end

    data.age = WO.Util.ClampNumber(data.age, WO.Config.AgeMin, WO.Config.AgeMax)

    if not isstring(data.race) or not (WO.Races.Registry and WO.Races.Registry:Exists(data.race)) then
        warnings[#warnings + 1] = "race_unavailable"
        return nil, warnings
    end

    local genders = WO.Config.Genders or { "male", "female" }
    local genderOk = false

    for _, g in ipairs(genders) do
        if g == data.gender then
            genderOk = true
            break
        end
    end

    if not genderOk or not WO.Races.IsGenderAllowed(data.race, data.gender) then
        warnings[#warnings + 1] = "gender_unavailable"
        return nil, warnings
    end

    if not isstring(data.model) or data.model == "" or
        not WO.Races.IsModelAllowed(data.race, data.gender, data.model) then
        warnings[#warnings + 1] = "model_unavailable"
        return nil, warnings
    end

    if WO.Classes.Registry and not WO.Classes.Registry:Exists(data.class) then
        local first = WO.Classes.Registry and WO.Classes.Registry:GetIDs()[1]

        data.class = first or "warrior"
        warnings[#warnings + 1] = "class_restored"
    end

    data.level = math.max(1, WO.Util.ToInt(data.level, 1))
    data.experience = math.max(0, WO.Util.ToInt(data.experience, 0))
    data.money = math.max(0, WO.Util.ToInt(data.money, 0))

    if not istable(data.customization) then
        data.customization = {}
        warnings[#warnings + 1] = "customization_restored"
    end

    data.customization.skin = math.max(0, WO.Util.ToInt(data.customization.skin, 0))
    data.customization.bodygroups = istable(data.customization.bodygroups) and data.customization.bodygroups or {}

    return data, warnings
end
