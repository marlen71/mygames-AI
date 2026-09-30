--[[
    Warcraft Online — раса: Орк.
    Мощные бойцы ближнего боя.
]]

WO.Races.Register({
    id = "orc",
    name = "Орк",
    description = "Воинственная раса с огромной силой. Магия даётся тяжело.",

    models = {
        male = {
            "models/player/Combine_Soldier.mdl",
            "models/player/Combine_Super_Soldier.mdl",
            "models/player/group03/male_07.mdl",
        },
        female = {
            "models/player/Combine_Soldier.mdl",
            "models/player/Group03/female_04.mdl",
        },
    },

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
