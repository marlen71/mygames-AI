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
    classes = { "warrior", "mage", "rogue", "ranger" },
    customization = { bodygroups = {} },
})
