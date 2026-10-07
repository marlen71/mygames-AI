--[[
    Warcraft Online — раса: Эльф.
    Ловкие и мудрые, но менее выносливые.
]]

WO.Races.Register({
    id = "elf",
    name = WO.Lang:Get("race.elf"),
    description = "Грациозные существа, мастера магии и стрельбы. Слабее в ближнем бою.",

    -- Явные пути ночных эльфов из config/sh_models.lua.
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
    magicBonuses = { air = 0.06, water = 0.05 },
    professionBonuses = { herbalist = 0.12, fisher = 0.08 },

    classes = {"warrior", "ranger", "rogue", "priest", "druid", "mage", "monk", "deathknight", "demonhunter", "assassin", "alchemist"},

    customization = {
        bodygroups = {},
    },
})
