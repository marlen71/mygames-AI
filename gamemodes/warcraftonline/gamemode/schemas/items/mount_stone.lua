--[[
    Warcraft Online — именной камень призыва лошади.
    Это уникальный, привязанный к персонажу utility-item; его useHandler только
    переключает серверный mount state и не расходует сам камень.
]]

WO.Items.Register({
    id = "mount_stone",
    name = "Камень призыва лошади",
    type = "mount",
    category = "utility",
    model = "models/props_junk/rock001a.mdl",
    weight = 0.5,
    size = { w = 1, h = 1 },
    stackable = false,
    rarity = "rare",
    description = "Используйте, чтобы вызвать лошадь или вернуть её в камень.",
    uniquePerCharacter = true,
    bound = true,
    noDrop = true,
    noSell = true,
    mountClass = "wow_npc_8883",
    useHandler = function(ply, instance)
        if not (WO.Mounts and WO.Mounts.Toggle) then return false, "mounts_unavailable" end
        return WO.Mounts.Toggle(ply, instance)
    end,
    price = { buy = 50000, sell = 0 },
})
