-- Воргены — быстрые и стойкие бойцы Гилнеаса.
WO.Races.Register({
    id = "worgen",
    name = WO.Lang:Get("race.worgen"),
    description = "Воины Гилнеаса, соединяющие волю человека и силу зверя.",
    models = WO.Models.GetRace("worgen"),
    genders = { "male", "female" },
    modelScale = 1.05,
    stats = { strength = 12, agility = 12, intelligence = 8, stamina = 11, spirit = 8 },
    modifiers = {},
    classes = { "warrior", "rogue", "ranger", "mage", "warlock", "druid", "priest", "deathknight" },
    customization = { bodygroups = {} },
})
