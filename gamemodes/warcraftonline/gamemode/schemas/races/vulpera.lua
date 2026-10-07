-- Вульперы — особая раса; доступ к её созданию проверяется сервером.
WO.Races.Register({
    id = "vulpera",
    name = WO.Lang:Get("race.vulpera"),
    special = true,
    description = "Находчивый народ пустынных странников и опытных торговцев.",
    models = WO.Models.GetRace("vulpera"),
    genders = { "male", "female" },
    modelScale = 0.92,
    stats = { strength = 8, agility = 13, intelligence = 11, stamina = 8, spirit = 10 },
    modifiers = {},
    magicBonuses = { fire = 0.04, earth = 0.05 },
    professionBonuses = { merchant = 0.12, porter = 0.10, cleaner = 0.08 },
    classes = {"warrior", "rogue", "ranger", "mage", "priest", "shaman", "warlock", "monk", "assassin", "alchemist"},
    customization = { bodygroups = {} },
})
