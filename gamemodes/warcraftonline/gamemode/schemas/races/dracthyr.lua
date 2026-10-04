-- Драктиры — особая раса; оба заданных образа доступны для обоих гендеров.
WO.Races.Register({
    id = "dracthyr",
    name = WO.Lang:Get("race.dracthyr"),
    description = "Древний драконид, владеющий силой драконьих аспектов.",
    models = WO.Models.GetRace("dracthyr"),
    genders = { "male", "female" },
    special = true,
    modelScale = 1.05,
    stats = { strength = 10, agility = 10, intelligence = 14, stamina = 10, spirit = 12 },
    modifiers = {},
    classes = { "evoker", "warrior", "mage", "priest", "ranger", "rogue", "warlock" },
    customization = { bodygroups = {} },
})
