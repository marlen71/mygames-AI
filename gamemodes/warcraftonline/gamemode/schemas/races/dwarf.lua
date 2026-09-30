--[[
    Warcraft Online — раса: Гном.
    Крепкие, выносливые, но медленные и только мужского пола (расширяется).
]]

WO.Races.Register({
    id = "dwarf",
    name = "Гном",
    description = "Крепкие горняки и кузнецы. Высокая выносливость, низкий рост.",

    models = {
        male = {
            "models/player/barney.mdl",
            "models/player/group03/male_05.mdl",
            "models/player/group03/male_06.mdl",
        },
    },

    genders = { "male" },
    modelScale = 0.85,

    stats = {
        strength = 12,
        agility = 7,
        intelligence = 9,
        stamina = 13,
        spirit = 9,
    },

    modifiers = {},

    classes = { "warrior", "rogue" },

    customization = {
        bodygroups = {},
    },
})
