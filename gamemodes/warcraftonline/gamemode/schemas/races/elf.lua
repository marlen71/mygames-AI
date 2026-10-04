--[[
    Warcraft Online — раса: Эльф.
    Ловкие и мудрые, но менее выносливые.
]]

WO.Races.Register({
    id = "elf",
    name = WO.Lang:Get("race.elf"),
    description = "Грациозные существа, мастера магии и стрельбы. Слабее в ближнем бою.",

    -- Только локально доступные модели ночных эльфов из config/sh_models.lua.
    models = WO.Models.GetRace("elf"),

    genders = { "male", "female" },
    modelScale = 1,

    stats = {
        strength = 7,
        agility = 12,
        intelligence = 12,
        stamina = 8,
        spirit = 11,
    },

    modifiers = {},

    classes = { "mage", "rogue", "ranger" },

    customization = {
        bodygroups = {},
    },
})
