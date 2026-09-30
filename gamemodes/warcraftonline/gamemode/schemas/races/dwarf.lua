--[[
    Warcraft Online — раса: Гном.
    Крепкие, выносливые, но медленные и только мужского пола (расширяется).
]]

WO.Races.Register({
    id = "dwarf",
    name = "Гном",
    description = "Крепкие горняки и кузнецы. Высокая выносливость, низкий рост.",

    -- Модели гномов WoW (Mailer, Steam Workshop) + стоковый fallback.
    -- Список строится в config/sh_models.lua (WO.Models.GetRace).
    models = WO.Models.GetRace("dwarf"),

    genders = { "male" },
    modelScale = 0.85,

    stats = {
        strength = 12,
        agility = 7,
        intelligence = 9,
        stamina = 13,
        spirit = 9,
    },

    modifiers = {},

    classes = { "warrior", "rogue" },

    customization = {
        bodygroups = {},
    },
})
