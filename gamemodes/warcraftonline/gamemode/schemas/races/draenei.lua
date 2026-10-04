-- Дренеи — выносливый народ, связанный со Светом и шаманскими традициями.
WO.Races.Register({
    id = "draenei",
    name = WO.Lang:Get("race.draenei"),
    description = "Стойкий народ странников, верный Свету и древним традициям.",
    models = WO.Models.GetRace("draenei"),
    genders = { "male", "female" },
    modelScale = 1.06,
    stats = { strength = 11, agility = 8, intelligence = 11, stamina = 12, spirit = 12 },
    modifiers = {},
    classes = { "warrior", "paladin", "priest", "shaman", "mage", "ranger", "deathknight", "monk" },
    customization = { bodygroups = {} },
})
