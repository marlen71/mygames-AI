--[[
    Warcraft Online — раса: Эльф.
    Ловкие и мудрые, но менее выносливые.
]]

WO.Races.Register({
    id = "elf",
    name = "Эльф",
    description = "Грациозные существа, мастера магии и стрельбы. Слабее в ближнем бою.",

    -- Модели ночных эльфов WoW (Mailer, Steam Workshop) + стоковый fallback.
    -- Список строится в config/sh_models.lua (WO.Models.GetRace).
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
