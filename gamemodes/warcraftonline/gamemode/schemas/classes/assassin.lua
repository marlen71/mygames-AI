--[[
    Warcraft Online — класс: Ассасин.
    Быстрый боец, специализирующийся на кинжалах, точечных ударах и торговле редкими ресурсами.
]]

WO.Classes.Register({
    id = "assassin",
    name = "Ассасин",
    description = "Ловкий дуэлянт с кинжалами; особенно искусен в сборе трав, оценке товара и оружейном деле.",

    stats = {
        strength = 0,
        agility = 5,
        intelligence = 1,
        stamina = 0,
        spirit = 0,
    },

    resource = "stamina",
    allowedWeapons = { "melee", "dagger", "sword" },
    allowedArmor = { "leather", "misc" },
    abilities = {},

    startingItems = {
        { class = "health_potion", amount = 3 },
        { class = "bread", amount = 2 },
    },

    magicBonuses = {},
    professionBonuses = { merchant = 0.10, herbalist = 0.10, weaponsmith = 0.08 },
    modifiers = {},
})
