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
    magicBonuses = { water = 0.06, life = 0.04 },
    professionBonuses = { baker = 0.10, brewer = 0.10, farmer = 0.08 },
    classes = {"warrior", "monk", "ranger", "rogue", "mage", "priest", "shaman", "druid", "assassin", "alchemist"},
    customization = { bodygroups = {} },
})
