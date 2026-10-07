--[[ Warcraft Online — раса: гоблин. ]]
WO.Races.Register({
    id = "goblin",
    name = WO.Lang:Get("race.goblin"),
    description = "Ловкие механики и торговцы с особым чутьём на выгоду.",
    models = WO.Models.GetRace("goblin"),
    genders = { "male", "female" },
    modelScale = 0.9,
    stats = { strength = 8, agility = 12, intelligence = 12, stamina = 8, spirit = 10 },
    modifiers = {},
    magicBonuses = { fire = 0.06, lightning = 0.04 },
    professionBonuses = { merchant = 0.12, weaponsmith = 0.08, porter = 0.08 },
    classes = {"warrior", "mage", "rogue", "ranger", "priest", "shaman", "warlock", "monk", "assassin", "runeknight", "alchemist"},
    customization = { bodygroups = {} },
})
