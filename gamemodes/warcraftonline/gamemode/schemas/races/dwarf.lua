--[[ Warcraft Online — раса: дворф. ]]
WO.Races.Register({
    id = "dwarf",
    name = WO.Lang:Get("race.dwarf"),
    description = "Стойкие мастера горного дела.",
    models = WO.Models.GetRace("dwarf"),
    genders = { "male", "female" },
    modelScale = 0.94,
    stats = { strength = 12, agility = 7, intelligence = 9, stamina = 13, spirit = 9 },
    modifiers = {},
    classes = { "warrior", "paladin", "priest", "shaman", "rogue", "ranger", "mage", "deathknight", "monk" },
    customization = { bodygroups = {} },
})
