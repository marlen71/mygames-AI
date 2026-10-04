--[[ Warcraft Online — раса: тролль. ]]
WO.Races.Register({
    id = "troll",
    name = WO.Lang:Get("race.troll"),
    description = "Проворные охотники и могучие воины.",
    models = WO.Models.GetRace("troll"),
    genders = { "male", "female" },
    modelScale = 1.04,
    stats = { strength = 10, agility = 13, intelligence = 9, stamina = 10, spirit = 10 },
    modifiers = {},
    classes = { "warrior", "mage", "rogue", "ranger", "priest", "druid", "shaman", "warlock", "deathknight", "monk" },
    customization = { bodygroups = {} },
})
