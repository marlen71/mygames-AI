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
    magicBonuses = { water = 0.08, life = 0.04 },
    professionBonuses = { fisher = 0.12, lumberjack = 0.08, herbalist = 0.08 },
    classes = {"warrior", "mage", "rogue", "ranger", "priest", "druid", "shaman", "warlock", "deathknight", "monk", "assassin", "runeknight", "alchemist"},
    customization = { bodygroups = {} },
})
