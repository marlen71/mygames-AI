--[[ Warcraft Online — мясо кабана, съедобный трофей и товар торговки. ]]

WO.Items.Register({
    id = "boar_meat",
    name = "Мясо кабана",
    type = "food",
    category = "junk",
    model = "models/props_junk/watermelon01.mdl",
    weight = 1,
    size = { w = 1, h = 1 },
    stackable = true,
    maxStack = 10,
    rarity = "common",
    description = "Сырое мясо с охотничьего трофея. Торговка покупает его.",
    consumable = { heal = 8 },
    price = { buy = 400, sell = 300 },
})
