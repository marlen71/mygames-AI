-- Кровавый эльф — особая раса с серверным ограничением доступа.
WO.Races.Register({
    id = "bloodelf",
    name = WO.Lang:Get("race.bloodelf"),
    special = true,
    description = "Изысканный народ, сочетающий магическое мастерство и боевую выучку.",
    models = WO.Models.GetRace("bloodelf"),
    genders = { "male", "female" },
    modelScale = 1,
    stats = { strength = 7, agility = 11, intelligence = 14, stamina = 8, spirit = 10 },
    modifiers = {},
    magicBonuses = { fire = 0.05, lightning = 0.05 },
    professionBonuses = { tailor = 0.10, jeweler = 0.12, merchant = 0.08 },
    classes = {"warrior", "paladin", "mage", "rogue", "priest", "warlock", "ranger", "deathknight", "demonhunter", "monk", "assassin", "runeknight", "alchemist"},
    customization = { bodygroups = {} },
})
