-- Вульперы — особая раса; доступ к её созданию проверяется сервером.
WO.Races.Register({
    id = "vulpera",
    name = WO.Lang:Get("race.vulpera"),
    description = "Находчивый народ пустынных странников и опытных торговцев.",
    models = WO.Models.GetRace("vulpera"),
    genders = { "male", "female" },
    special = true,
    modelScale = 0.92,
    stats = { strength = 8, agility = 13, intelligence = 11, stamina = 8, spirit = 10 },
    modifiers = {},
    classes = { "warrior", "rogue", "ranger", "mage", "priest", "shaman", "warlock", "monk" },
    customization = { bodygroups = {} },
})
