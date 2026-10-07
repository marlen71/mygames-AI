--[[ Warcraft Online — раса: нежить (Forsaken). ]]
WO.Races.Register({
    id = "undead",
    name = WO.Lang:Get("race.undead"),
    description = "Воля нежити помогает ей выстоять в самых тяжёлых испытаниях.",
    models = WO.Models.GetRace("undead"),
    genders = { "male", "female" },
    modelScale = 1,
    stats = { strength = 9, agility = 10, intelligence = 12, stamina = 9, spirit = 13 },
    modifiers = {},
    magicBonuses = { frost = 0.05, water = 0.04 },
    professionBonuses = { cleaner = 0.12, tailor = 0.08, alchemist = 0.08 },
    classes = {"warrior", "mage", "rogue", "ranger", "priest", "warlock", "deathknight", "monk", "assassin", "runeknight", "alchemist"},
    customization = { bodygroups = {} },
})
