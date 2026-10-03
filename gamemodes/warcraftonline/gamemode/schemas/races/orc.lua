--[[
    Warcraft Online — раса: Орк.
    Мощные бойцы ближнего боя.
]]

WO.Races.Register({
    id = "orc",
    name = WO.Lang:Get("race.orc"),
    description = "Воинственная раса с огромной силой. Магия даётся тяжело.",

    -- Только смонтированные WoW-модели; гражданского fallback нет.
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
