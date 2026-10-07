--[[
    Warcraft Online — раса: Орк.
    Мощные бойцы ближнего боя.
]]

WO.Races.Register({
    id = "orc",
    name = WO.Lang:Get("race.orc"),
    description = "Воинственная раса с огромной силой. Магия даётся тяжело.",

    -- Явные пути WoW-моделей; не зависят от локального file.Exists.
    models = WO.Models.GetRace("orc"),

    genders = { "male", "female" },
    modelScale = 1.05,

    stats = {
        strength = 14,
        agility = 8,
        intelligence = 6,
        stamina = 12,
        spirit = 8,
    },

    modifiers = {},
    magicBonuses = { fire = 0.08, earth = 0.05 },
    professionBonuses = { lumberjack = 0.12, builder = 0.08, weaponsmith = 0.08 },

    classes = {"warrior", "rogue", "ranger", "shaman", "warlock", "mage", "deathknight", "monk", "assassin", "runeknight", "alchemist"},

    customization = {
        bodygroups = {},
    },
})
