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
    magicBonuses = { earth = 0.10, lightning = 0.03 },
    professionBonuses = { miner = 0.12, blacksmith = 0.12, jeweler = 0.06 },
    classes = {"warrior", "paladin", "priest", "shaman", "rogue", "ranger", "mage", "deathknight", "monk", "assassin", "runeknight", "alchemist"},
    customization = { bodygroups = {} },
})
