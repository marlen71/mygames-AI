--[[ Warcraft Online — клык волка, низкоуровневый материал для продажи/крафта. ]]

WO.Items.Register({
    id = "wolf_fang",
    name = "Волчий клык",
    type = "material",
    category = "junk",
    model = "models/props_junk/rock001a.mdl",
    weight = 0.2,
    size = { w = 1, h = 1 },
    stackable = true,
    maxStack = 20,
    rarity = "common",
    description = "Острый клык. Торговка покупает такие трофеи.",
    price = { buy = 300, sell = 200 },
})
