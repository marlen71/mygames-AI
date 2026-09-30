--[[
    Warcraft Online — раса: Человек.
    Добавление новой расы = новый файл в schemas/races/ (без изменения ядра).
]]

WO.Races.Register({
    id = "human",
    name = "Человек",
    description = "Универсальная раса: сильные воины, мудрые маги и ловкие разбойники.",

    -- Модели WoW (Mailer, Steam Workshop) + стоковый fallback.
    -- Список строится в config/sh_models.lua (WO.Models.GetRace).
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
