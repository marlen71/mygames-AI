--[[ Warcraft Online — одноразовый тренировочный набор для прокачки лошади. ]]

WO.Items.Register({
    id = "mount_training_kit",
    name = "Набор обучения маунта",
    type = "consumable",
    category = "mount",
    model = "models/props_lab/box01a.mdl",
    weight = 1,
    size = { w = 1, h = 1 },
    stackable = true,
    maxStack = 10,
    rarity = "uncommon",
    description = "Используйте при наличии лошади. Для повышения уровня нужен уровень персонажа.",
    consumeOnUse = true,
    useHandler = function(ply, instance)
        if not (WO.Mounts and WO.Mounts.Upgrade) then return false, "mounts_unavailable" end
        return WO.Mounts.Upgrade(ply, instance)
    end,
    price = { buy = 15000, sell = 0 },
})
