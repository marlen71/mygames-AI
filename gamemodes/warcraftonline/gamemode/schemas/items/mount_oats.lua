--[[ Warcraft Online — овёс для кормления своего mount stone. ]]

WO.Items.Register({
    id = "mount_oats",
    name = "Овёс для лошади",
    type = "food",
    category = "mount",
    model = "models/props_junk/garbage_bag001a.mdl",
    weight = 1,
    size = { w = 1, h = 1 },
    stackable = true,
    maxStack = 20,
    rarity = "common",
    description = "Используйте при наличии камня призыва, чтобы накормить лошадь.",
    consumeOnUse = true,
    useHandler = function(ply, instance)
        if not (WO.Mounts and WO.Mounts.Feed) then return false, "mounts_unavailable" end
        return WO.Mounts.Feed(ply, instance)
    end,
    price = { buy = 12, sell = 0 },
})
