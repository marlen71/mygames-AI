-- Кровавый эльф — особая раса с серверным ограничением доступа.
WO.Races.Register({
    id = "bloodelf",
    name = WO.Lang:Get("race.bloodelf"),
    description = "Изысканный народ, сочетающий магическое мастерство и боевую выучку.",
    models = WO.Models.GetRace("bloodelf"),
    genders = { "male", "female" },
    special = true,
    modelScale = 1,
    stats = { strength = 7, agility = 11, intelligence = 14, stamina = 8, spirit = 10 },
    modifiers = {},
    classes = { "warrior", "paladin", "mage", "rogue", "priest", "warlock", "ranger", "deathknight", "demonhunter", "monk" },
    customization = { bodygroups = {} },
})
