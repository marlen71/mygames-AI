--[[
    Warcraft Online — раса: Эльф.
    Ловкие и мудрые, но менее выносливые.
]]

WO.Races.Register({
    id = "elf",
    name = "Эльф",
    description = "Грациозные существа, мастера магии и стрельбы. Слабее в ближнем бою.",

    models = {
        male = {
            "models/player/group03/male_01.mdl",
            "models/player/group03/male_02.mdl",
            "models/player/group03/male_03.mdl",
            "models/player/group03/male_04.mdl",
        },
        female = {
            "models/player/group03/female_01.mdl",
            "models/player/group03/female_02.mdl",
            "models/player/group03/female_03.mdl",
            "models/player/mossman.mdl",
            "models/player/alyx.mdl",
        },
    },

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
