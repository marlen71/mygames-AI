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
    magicBonuses = { earth = 0.06, lightning = 0.05 },
    professionBonuses = { alchemist = 0.12, tailor = 0.08, weaponsmith = 0.08 },
    classes = {"warrior", "mage", "rogue", "warlock", "priest", "deathknight", "monk", "assassin", "alchemist"},
    customization = { bodygroups = {} },
})
