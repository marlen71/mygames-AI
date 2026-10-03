--[[ Warcraft Online — раса: таурен. ]]
WO.Races.Register({
    id = "tauren",
    name = WO.Lang:Get("race.tauren"),
    description = "Крупный и выносливый народ степей.",
    models = WO.Models.GetRace("tauren"),
    genders = { "male", "female" },
    modelScale = 1.12,
    stats = { strength = 14, agility = 7, intelligence = 8, stamina = 14, spirit = 10 },
    modifiers = {},
    classes = { "warrior", "ranger" },
    customization = { bodygroups = {} },
})
