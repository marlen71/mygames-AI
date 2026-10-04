--[[
    Warcraft Online — класс: Алхимик.
    Маг-практик, который изучает зелья и поддерживает союзников стихийной магией.
]]

WO.Classes.Register({
    id = "alchemist",
    name = "Алхимик",
    description = "Искусный зельевар, способный пользоваться гримуаром и получать больше пользы от редких ингредиентов.",

    stats = {
        strength = -2,
        agility = 0,
        intelligence = 4,
        stamina = -1,
        spirit = 3,
    },

    resource = "mana",
    allowedWeapons = { "staff", "magic", "dagger", "mace" },
    allowedArmor = { "cloth", "leather", "misc" },
    abilities = {},
    canUseGrimoire = true,

    startingItems = {
        { class = "health_potion", amount = 4 },
        { class = "bread", amount = 3 },
    },

    magicBonuses = { earth = 0.08, water = 0.10, life = 0.10, fire = 0.06 },
    professionBonuses = { alchemist = 0.15, herbalist = 0.10, jeweler = 0.08 },
    modifiers = {},
})
