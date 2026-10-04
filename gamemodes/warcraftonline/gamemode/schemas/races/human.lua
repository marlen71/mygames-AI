--[[
    Warcraft Online — раса: Человек.
    Добавление новой расы = новый файл в schemas/races/ (без изменения ядра).
]]

WO.Races.Register({
    id = "human",
    name = WO.Lang:Get("race.human"),
    description = "Универсальная раса: сильные воины, мудрые маги и ловкие разбойники.",

    -- Только локально доступные WoW-модели; гражданского fallback нет.
    models = WO.Models.GetRace("human"),

    genders = { "male", "female" },
    modelScale = 1,

    stats = {
        strength = 10,
        agility = 9,
        intelligence = 10,
        stamina = 10,
        spirit = 10,
    },

    modifiers = {},

    -- Доступные классы
    classes = { "warrior", "mage", "rogue", "ranger" },

    customization = {
        bodygroups = {},
    },
})
