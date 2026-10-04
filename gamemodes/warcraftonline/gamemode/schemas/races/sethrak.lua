-- Сетраки: обе записи пола используют единственную подтверждённую модель.
WO.Races.Register({
    id = "sethrak",
    name = WO.Lang:Get("race.sethrak"),
    description = "Змееподобный народ, привыкший к жаре и суровым пустыням.",
    models = WO.Models.GetRace("sethrak"),
    genders = { "male", "female" },
    modelScale = 1,
    stats = { strength = 11, agility = 11, intelligence = 9, stamina = 11, spirit = 9 },
    modifiers = {},
    classes = { "warrior", "ranger", "rogue", "shaman", "druid", "priest" },
    customization = { bodygroups = {} },
})
