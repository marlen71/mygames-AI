--[[
    Warcraft Online — охота на кабанов.
    Кабаны появляются только после принятия задания у Охотника.
]]

WO.Quests.Register({
    id = "boar_hunt",
    name = "Кабаны у фермы",
    description = "Помогите Охотнику и победите семерых кабанов.",
    level = 1,
    giver = "hunter_dyrne",

    steps = {
        { type = "kill", target = "elwynn_boar", amount = 7,
            text = "Победите кабанов" },
    },

    rewards = {
        xp = 100,
        money = 35,
    },

    prerequisites = { "wolves_of_elwynn" },
})
