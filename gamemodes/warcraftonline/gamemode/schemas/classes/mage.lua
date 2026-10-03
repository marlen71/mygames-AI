--[[
    Warcraft Online — класс: Маг.
]]

WO.Classes.Register({
    id = "mage",
    name = "Маг",
    description = "Повелитель стихий. Силен на расстоянии, слаб в ближнем бою.",

    stats = {
        strength = -2,
        agility = 0,
        intelligence = 5,
        stamina = -1,
        spirit = 3,
    },

    resource = "mana",
    startingEquipment = { main_hand = "arcane_hands" },

    allowedWeapons = { "staff", "magic" },
    allowedArmor = { "cloth", "misc" },

    abilities = {},

    startingItems = {
        { class = "arcane_hands", amount = 1 },
        { class = "health_potion", amount = 3 },
        { class = "bread", amount = 2 },
    },

    modifiers = {},
})
