-- Пандарены — спокойный и гибкий народ, мастера боевых искусств.
WO.Races.Register({
    id = "pandaren",
    name = WO.Lang:Get("race.pandaren"),
    description = "Уравновешенный народ странников, ценящий мастерство и гармонию.",
    models = WO.Models.GetRace("pandaren"),
    genders = { "male", "female" },
    modelScale = 1.04,
    stats = { strength = 10, agility = 10, intelligence = 10, stamina = 11, spirit = 12 },
    modifiers = {},
    classes = { "warrior", "monk", "ranger", "rogue", "mage", "priest", "shaman", "druid" },
    customization = { bodygroups = {} },
})
