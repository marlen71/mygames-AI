-- Драктиры — особая раса; оба заданных образа доступны для обоих гендеров.
WO.Races.Register({
    id = "dracthyr",
    name = WO.Lang:Get("race.dracthyr"),
    special = true,
    description = "Древний драконид, владеющий силой драконьих аспектов.",
    models = WO.Models.GetRace("dracthyr"),
    genders = { "male", "female" },
    modelScale = 1.05,
    stats = { strength = 10, agility = 10, intelligence = 14, stamina = 10, spirit = 12 },
    modifiers = {},
    magicBonuses = { fire = 0.08, air = 0.06 },
    professionBonuses = { builder = 0.12, blacksmith = 0.10, miner = 0.08 },
    classes = {"evoker", "warrior", "mage", "priest", "ranger", "rogue", "warlock", "assassin", "runeknight", "alchemist"},
    customization = { bodygroups = {} },
})
