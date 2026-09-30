--[[
    Warcraft Online — раса: Человек.
    Добавление новой расы = новый файл в schemas/races/ (без изменения ядра).
]]

WO.Races.Register({
    id = "human",
    name = "Человек",
    description = "Универсальная раса: сильные воины, мудрые маги и ловкие разбойники.",

    models = {
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
