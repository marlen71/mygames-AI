--[[
    Warcraft Online — раса: Орк.
    Мощные бойцы ближнего боя.
]]

WO.Races.Register({
    id = "orc",
    name = "Орк",
    description = "Воинственная раса с огромной силой. Магия даётся тяжело.",

    -- Модели орков WoW (Mailer, Steam Workshop) + стоковый fallback.
    -- Список строится в config/sh_models.lua (WO.Models.GetRace).
    models = WO.Models.GetRace("orc"),

    genders = { "male", "female" },
    modelScale = 1.05,

    stats = {
        strength = 14,
        agility = 8,
        intelligence = 6,
        stamina = 12,
        spirit = 8,
    },

    modifiers = {},

    classes = { "warrior", "rogue" },

    customization = {
        bodygroups = {},
    },
})
