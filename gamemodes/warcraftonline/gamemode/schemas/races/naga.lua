-- Нага — народ глубин, владеющий магией и оружием.
WO.Races.Register({
    id = "naga",
    name = WO.Lang:Get("race.naga"),
    description = "Древние жители глубин, сильные в магии и ближнем бою.",
    models = WO.Models.GetRace("naga"),
    genders = { "male", "female" },
    modelScale = 1.02,
    stats = { strength = 10, agility = 10, intelligence = 12, stamina = 9, spirit = 11 },
    modifiers = {},
    classes = { "warrior", "mage", "rogue", "ranger", "priest", "warlock", "shaman", "druid" },
    customization = { bodygroups = {} },
})
