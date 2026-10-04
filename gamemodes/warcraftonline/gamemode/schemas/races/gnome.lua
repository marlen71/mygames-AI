--[[ Warcraft Online — раса: гном. Статические пути взяты из Mailer-каталога. ]]
WO.Races.Register({
    id = "gnome",
    name = WO.Lang:Get("race.gnome"),
    description = "Изобретательные исследователи и умелые маги.",
    models = WO.Models.GetRace("gnome"),
    genders = { "male", "female" },
    modelScale = 0.82,
    stats = { strength = 7, agility = 10, intelligence = 13, stamina = 8, spirit = 12 },
    modifiers = {},
    classes = { "warrior", "mage", "rogue", "warlock", "priest", "deathknight", "monk" },
    customization = { bodygroups = {} },
})
