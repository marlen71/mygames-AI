--[[
    Warcraft Online — раса: Человек.
    Добавление новой расы = новый файл в schemas/races/ (без изменения ядра).
]]

WO.Races.Register({
    id = "human",
    name = WO.Lang:Get("race.human"),
    description = "Универсальная раса: сильные воины, мудрые маги и ловкие разбойники.",

    -- Явные пути WoW-моделей; не зависят от локального file.Exists.
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
    magicBonuses = { life = 0.03, fire = 0.02 },
    professionBonuses = { merchant = 0.12, baker = 0.05 },

    -- Доступные классы
    classes = {"warrior", "paladin", "priest", "mage", "warlock", "rogue", "ranger", "deathknight", "monk", "assassin", "runeknight", "alchemist"},

    customization = {
        bodygroups = {},
    },
})
